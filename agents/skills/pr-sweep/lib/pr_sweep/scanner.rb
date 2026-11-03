# frozen_string_literal: true

require "digest"

module PrSweep
  class Scanner
    FAILING = %w[FAILURE ERROR TIMED_OUT STARTUP_FAILURE CANCELLED].freeze
    BOT_PREFIXES = %w[dependabot app/dependabot].freeze

    def initialize(client:, store:)
      @client = client
      @store = store
    end

    def tick
      login = @client.verify_login!
      items = @client.search.map { |row| classify(row, login) }.compact
      changed = @store.reconcile(items)
      {
        "profile" => @store.profile,
        "login" => login,
        "status" => changed.empty? ? "quiet" : "attention",
        "items" => changed.map { |item| public_item(item) }
      }
    end

    private

    def classify(row, login)
      repository = repository_name(row)
      return unless repository

      role = row.fetch("role")
      if role == "review-requested"
        author = (row["author"] || {})["login"].to_s
        kind = bot?(author) ? "dependabot" : "review-requested"
        return build_item(row, repository, kind)
      end

      return if row["isDraft"]

      details = @client.details(row.fetch("url"))
      kind = authored_kind(details)
      kind ||= "review-feedback" if @client.unresolved_review?(repository, row.fetch("number"), login)
      build_item(row.merge("details" => details), repository, kind) if kind
    end

    def authored_kind(details)
      return "conflicts" if details["mergeable"] == "CONFLICTING" || details["mergeStateStatus"] == "DIRTY"
      return "red-ci" if failing_checks(details).any?
      return "review-feedback" if details["reviewDecision"] == "CHANGES_REQUESTED"

      nil
    end

    def failing_checks(details)
      Array(details["statusCheckRollup"]).select do |check|
        state = (check["conclusion"] || check["state"]).to_s.upcase
        FAILING.include?(state)
      end
    end

    def build_item(row, repository, kind)
      details = row["details"] || {}
      identity = [repository, row.fetch("number"), kind].join("|")
      evidence = {
        "updated_at" => details["updatedAt"] || row["updatedAt"],
        "head_sha" => details["headRefOid"],
        "check_states" => failing_checks(details).map do |check|
          [check["name"] || check["context"], check["conclusion"] || check["state"]]
        end
      }
      {
        "id" => Digest::SHA256.hexdigest(identity)[0, 12],
        "repository" => repository,
        "number" => row.fetch("number"),
        "url" => row.fetch("url"),
        "kind" => kind,
        "route" => route(kind, row.fetch("url")),
        "fingerprint" => Digest::SHA256.hexdigest([identity, evidence].inspect)
      }
    end

    def route(kind, url)
      case kind
      when "conflicts" then "$pull-request conflicts #{url}"
      when "red-ci" then "$pull-request fix-ci #{url}"
      when "review-feedback" then "$pull-request resolve #{url}"
      when "review-requested" then "$code-review #{url}"
      when "dependabot" then "$dependabot triage #{url}"
      else raise Error, "unknown attention kind: #{kind}"
      end
    end

    def public_item(item)
      item.reject { |key, _value| key == "fingerprint" }
    end

    def repository_name(row)
      repository = row["repository"] || {}
      repository["nameWithOwner"] || repository["name"]
    end

    def bot?(login)
      BOT_PREFIXES.any? { |prefix| login.start_with?(prefix) }
    end
  end
end
