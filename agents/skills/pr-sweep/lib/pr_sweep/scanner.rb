# frozen_string_literal: true

require "digest"
require "time"

module PrSweep
  class Scanner
    FAILING = %w[FAILURE ERROR TIMED_OUT STARTUP_FAILURE CANCELLED].freeze
    BOT_PREFIXES = %w[dependabot app/dependabot].freeze
    PRIVATE_FIELDS = %w[_rank _updated_at].freeze
    ATTENTION = {
      "conflicts" => {
        "rank" => 0, "urgency" => "now", "reason" => "the branch has merge conflicts"
      }.freeze,
      "red-ci" => {
        "rank" => 1, "urgency" => "now", "reason" => "the latest commit has failing checks"
      }.freeze,
      "review-feedback" => {
        "rank" => 2, "urgency" => "now", "reason" => "review feedback is unresolved"
      }.freeze,
      "review-requested" => {
        "rank" => 3, "urgency" => "soon", "reason" => "your review was requested"
      }.freeze,
      "dependabot" => {
        "rank" => 4, "urgency" => "batch", "reason" => "a dependency update needs review"
      }.freeze
    }.freeze

    def initialize(client:, store:)
      @client = client
      @store = store
    end

    def tick
      login = @client.verify_login!
      items = @client.search.map { |row| classify(row, login) }.compact
      items.sort_by! do |item|
        [
          item.fetch("_rank"), -timestamp(item.fetch("_updated_at")),
          item.fetch("repository"), -item.fetch("number")
        ]
      end
      items.map! { |item| item.reject { |key, _value| PRIVATE_FIELDS.include?(key) } }
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
      return if row["isDraft"]

      role = row.fetch("role")
      if role == "review-requested"
        author = (row["author"] || {})["login"].to_s
        kind = bot?(author) ? "dependabot" : "review-requested"
        return build_item(row, repository, kind)
      end

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
        "_rank" => attention(kind).fetch("rank"),
        "_updated_at" => evidence.fetch("updated_at").to_s,
        "urgency" => attention(kind).fetch("urgency"),
        "reason" => attention(kind).fetch("reason"),
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

    def attention(kind)
      ATTENTION.fetch(kind)
    end

    def timestamp(value)
      Time.parse(value).to_i
    rescue ArgumentError
      0
    end
  end
end
