# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "time"

module PrSweep
  class Error < StandardError; end

  class Store
    PROFILE = /\A[a-z0-9][a-z0-9_-]{0,31}\z/.freeze
    OWNER = /\A[a-zA-Z0-9][a-zA-Z0-9-]{0,38}\z/.freeze
    REPOSITORY = %r{\A[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+\z}.freeze
    STATUSES = %w[acknowledged deferred done ignored].freeze

    attr_reader :profile

    def initialize(profile:, config_home: nil, state_home: nil, now: nil)
      raise Error, "invalid profile name" unless PROFILE.match?(profile.to_s)

      @profile = profile
      @config_home = config_home || default_home("PR_SWEEP_CONFIG_HOME", ".config")
      @state_home = state_home || default_home("PR_SWEEP_STATE_HOME", File.join(".local", "state"))
      @now = now || -> { Time.now.utc }
    end

    def configure(expected_login:, owners:, repositories: [], gh_config_dir:)
      owners = Array(owners).uniq
      repositories = Array(repositories).uniq
      raise Error, "expected login is required" if expected_login.to_s.empty?
      raise Error, "at least one owner is required" if owners.empty?
      raise Error, "invalid owner" unless owners.all? { |owner| OWNER.match?(owner) }
      raise Error, "invalid repository" unless repositories.all? { |repo| REPOSITORY.match?(repo) }
      raise Error, "GitHub CLI config directory is required" if gh_config_dir.to_s.empty?

      github_directory = File.expand_path(gh_config_dir)
      prepare_private_directory(github_directory, "GitHub CLI configuration")
      payload = {
        "profile" => profile,
        "expected_login" => expected_login,
        "owners" => owners,
        "repositories" => repositories,
        "gh_config_dir" => github_directory
      }
      write_json(config_path, payload)
      payload
    end

    def configuration
      read_private_json(config_path, "profile configuration")
    end

    def reconcile(items)
      ledger = load_ledger
      current_ids = []
      changed = []

      items.each do |item|
        id = item.fetch("id")
        current_ids << id
        previous = ledger["items"][id]
        changed << item if previous.nil? || previous["fingerprint"] != item["fingerprint"]
        ledger["items"][id] = item.merge(
          "status" => previous && previous["fingerprint"] == item["fingerprint"] ? previous["status"] : "new",
          "last_seen_at" => timestamp
        )
      end

      ledger["items"].delete_if { |id, _item| !current_ids.include?(id) }
      ledger["last_scan_at"] = timestamp
      write_json(ledger_path, ledger)
      changed
    end

    def decide(id, status)
      raise Error, "unknown decision status" unless STATUSES.include?(status)

      ledger = load_ledger
      item = ledger["items"][id]
      raise Error, "unknown attention item: #{id}" unless item

      item["status"] = status
      item["decided_at"] = timestamp
      write_json(ledger_path, ledger)
      item
    end

    def summary
      load_ledger
    end

    private

    def default_home(env_name, fallback)
      explicit = ENV[env_name]
      return File.expand_path(explicit) if explicit && !explicit.empty?

      xdg_name = env_name.include?("CONFIG") ? "XDG_CONFIG_HOME" : "XDG_STATE_HOME"
      xdg = ENV[xdg_name]
      base = xdg && !xdg.empty? ? xdg : File.join(Dir.home, fallback)
      File.join(base, "pr-sweep")
    end

    def profile_dir(root)
      File.join(root, profile)
    end

    def config_path
      File.join(profile_dir(@config_home), "profile.json")
    end

    def ledger_path
      File.join(profile_dir(@state_home), "ledger.json")
    end

    def load_ledger
      return { "profile" => profile, "last_scan_at" => nil, "items" => {} } unless File.file?(ledger_path)

      read_private_json(ledger_path, "attention ledger")
    end

    def read_private_json(path, label)
      raise Error, "missing #{label}: #{path}" unless File.file?(path)
      raise Error, "refusing symlinked #{label}: #{path}" if File.symlink?(path)
      raise Error, "unsafe profile directory: #{File.dirname(path)}" unless private_directory?(File.dirname(path))
      raise Error, "unsafe permissions on #{label}: #{path}" unless private_file?(path)

      JSON.parse(File.read(path))
    rescue JSON::ParserError => e
      raise Error, "invalid #{label}: #{e.message}"
    end

    def write_json(path, payload)
      directory = File.dirname(path)
      raise Error, "refusing symlinked profile directory: #{directory}" if File.symlink?(directory)

      FileUtils.mkdir_p(directory, mode: 0o700)
      raise Error, "profile path is not a directory: #{directory}" unless File.directory?(directory)

      File.chmod(0o700, directory)
      temporary = "#{path}.tmp.#{Process.pid}"
      File.open(temporary, File::WRONLY | File::CREAT | File::EXCL, 0o600) do |file|
        file.write(JSON.pretty_generate(payload))
        file.write("\n")
      end
      File.rename(temporary, path)
      File.chmod(0o600, path)
    ensure
      File.delete(temporary) if temporary && File.exist?(temporary)
    end

    def private_file?(path)
      (File.stat(path).mode & 0o077).zero?
    end

    def prepare_private_directory(path, label)
      raise Error, "refusing symlinked #{label}: #{path}" if File.symlink?(path)

      FileUtils.mkdir_p(path, mode: 0o700)
      raise Error, "#{label} is not a directory: #{path}" unless File.directory?(path)
      raise Error, "unsafe permissions on #{label}: #{path}" unless private_directory?(path)
    end

    def private_directory?(path)
      File.directory?(path) && !File.symlink?(path) && (File.stat(path).mode & 0o077).zero?
    end

    def timestamp
      @now.call.iso8601
    end
  end
end
