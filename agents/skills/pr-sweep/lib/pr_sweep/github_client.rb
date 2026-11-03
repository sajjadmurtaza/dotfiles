# frozen_string_literal: true

require "json"
require "open3"

module PrSweep
  class GithubClient
    SEARCH_FIELDS = "url,repository,number,updatedAt,isDraft,author".freeze
    DETAIL_FIELDS = [
      "url", "headRefOid", "mergeable", "mergeStateStatus", "statusCheckRollup",
      "reviewDecision", "author", "isDraft", "updatedAt"
    ].join(",").freeze
    THREAD_QUERY = <<~GRAPHQL.freeze
      query($owner:String!,$name:String!,$number:Int!){
        repository(owner:$owner,name:$name){
          pullRequest(number:$number){
            reviewThreads(first:100){
              nodes{ isResolved comments(last:1){ nodes{ author{ login } } } }
            }
          }
        }
      }
    GRAPHQL

    def initialize(configuration, runner: nil)
      @configuration = configuration
      @runner = runner || method(:run_command)
    end

    def verify_login!
      verify_config_directory!
      actual = run(%w[api user --jq .login]).strip
      expected = @configuration.fetch("expected_login")
      raise Error, "GitHub account mismatch: expected #{expected}, found #{actual}" unless actual == expected

      actual
    end

    def search
      rows = []
      @configuration.fetch("owners").each do |owner|
        rows.concat(search_set(owner, "authored"))
        rows.concat(search_set(owner, "review-requested"))
      end
      allowed = @configuration.fetch("repositories", [])
      rows.select! { |row| allowed.include?(repository_name(row)) } unless allowed.empty?
      merge_roles(rows)
    end

    def details(url)
      parse_json(run(["pr", "view", url, "--json", DETAIL_FIELDS]))
    end

    def unresolved_review?(repository, number, login)
      owner, name = repository.split("/", 2)
      raise Error, "invalid repository from GitHub: #{repository}" if owner.to_s.empty? || name.to_s.empty?

      raw = run([
                  "api", "graphql", "-f", "query=#{THREAD_QUERY}", "-F", "owner=#{owner}",
                  "-F", "name=#{name}", "-F", "number=#{number}"
                ])
      threads = parse_json(raw).dig("data", "repository", "pullRequest", "reviewThreads", "nodes")
      Array(threads).any? do |thread|
        last_author = thread.dig("comments", "nodes", 0, "author", "login")
        !thread["isResolved"] && !last_author.to_s.empty? && last_author != login
      end
    end

    private

    def search_set(owner, role)
      selector = role == "authored" ? "--author=@me" : "--review-requested=@me"
      raw = run([
                  "search", "prs", selector, "--owner=#{owner}", "--state=open",
                  "--json", SEARCH_FIELDS, "--limit", "50"
                ])
      parse_json(raw).map { |row| row.merge("role" => role) }
    end

    def merge_roles(rows)
      rows.each_with_object({}) do |row, result|
        url = row.fetch("url")
        if result[url]
          result[url]["role"] = "authored" if row["role"] == "authored"
        else
          result[url] = row
        end
      end.values
    end

    def repository_name(row)
      repository = row["repository"] || {}
      repository["nameWithOwner"] || repository["name"]
    end

    def parse_json(raw)
      JSON.parse(raw)
    rescue JSON::ParserError => e
      raise Error, "GitHub CLI returned invalid JSON: #{e.message}"
    end

    def run(arguments)
      @runner.call(arguments, gh_environment)
    end

    def verify_config_directory!
      path = @configuration.fetch("gh_config_dir")
      mode = File.stat(path).mode
      safe = File.directory?(path) && !File.symlink?(path) && (mode & 0o077).zero?
      raise Error, "unsafe GitHub CLI configuration directory: #{path}" unless safe
    rescue Errno::ENOENT
      raise Error, "missing GitHub CLI configuration directory: #{path}"
    end

    def gh_environment
      { "GH_CONFIG_DIR" => @configuration.fetch("gh_config_dir") }
    end

    def run_command(arguments, environment)
      output, error, status = Open3.capture3(environment, "gh", *arguments)
      raise Error, "GitHub CLI failed: #{error.strip}" unless status.success?

      output
    end
  end
end
