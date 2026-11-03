# frozen_string_literal: true

require "json"
require "optparse"

module PrSweep
  class CLI
    DEFAULT_INTERVAL = 180
    QUIET_INTERVAL = 600

    def self.run(argv = ARGV, stdout: $stdout, stderr: $stderr, runner: nil, sleep_fn: nil)
      new(argv, stdout: stdout, stderr: stderr, runner: runner, sleep_fn: sleep_fn).run
    end

    def initialize(argv, stdout:, stderr:, runner:, sleep_fn:)
      @argv = argv.dup
      @stdout = stdout
      @stderr = stderr
      @runner = runner
      @sleep_fn = sleep_fn || ->(seconds) { sleep(seconds) }
    end

    def run
      command = @argv.shift
      case command
      when "setup" then setup
      when "doctor" then doctor
      when "tick" then emit(scanner.tick)
      when "decide" then decide
      when "summary" then summary
      when "watch" then watch
      else raise Error, usage
      end
      0
    rescue Error, OptionParser::ParseError => e
      @stderr.puts("pr-sweep: #{e.message}")
      1
    end

    private

    def setup
      options = { owners: [], repositories: [] }
      parser = common_parser(options)
      parser.on("--login LOGIN") { |value| options[:login] = value }
      parser.on("--owner OWNER") { |value| options[:owners] << value }
      parser.on("--repository OWNER/REPO") { |value| options[:repositories] << value }
      parser.on("--gh-config-dir DIR") { |value| options[:gh_config_dir] = value }
      parser.parse!(@argv)
      store = build_store(options)
      emit(store.configure(
             expected_login: options[:login], owners: options[:owners],
             repositories: options[:repositories], gh_config_dir: options[:gh_config_dir]
           ))
    end

    def doctor
      options = parse_common
      configuration = build_store(options).configuration
      login = GithubClient.new(configuration, runner: @runner).verify_login!
      emit("status" => "ok", "profile" => options.fetch(:profile), "login" => login)
    end

    def decide
      options = {}
      parser = common_parser(options)
      parser.on("--id ID") { |value| options[:id] = value }
      parser.on("--status STATUS") { |value| options[:status] = value }
      parser.parse!(@argv)
      emit(build_store(options).decide(options[:id], options[:status]))
    end

    def summary
      options = parse_common
      ledger = build_store(options).summary
      items = ledger.fetch("items", {}).values.map do |item|
        item.reject { |key, _value| key == "fingerprint" }
      end
      emit("profile" => options.fetch(:profile), "last_scan_at" => ledger["last_scan_at"], "items" => items)
    end

    def watch
      options = { interval: DEFAULT_INTERVAL, quiet_interval: QUIET_INTERVAL, max_cycles: nil }
      parser = common_parser(options)
      parser.on("--interval SECONDS", Integer) { |value| options[:interval] = value }
      parser.on("--quiet-interval SECONDS", Integer) { |value| options[:quiet_interval] = value }
      parser.on("--max-cycles COUNT", Integer) { |value| options[:max_cycles] = value }
      parser.parse!(@argv)
      raise Error, "intervals must be positive" if options[:interval] <= 0 || options[:quiet_interval] <= 0

      target = build_scanner(options)
      cycles = 0
      quiet = 0
      loop do
        result = target.tick
        cycles += 1
        if result["status"] == "attention"
          quiet = 0
          @stdout.puts("PR_SWEEP_WAKE #{JSON.generate(result)}")
          @stdout.flush
        else
          quiet += 1
        end
        break if options[:max_cycles] && cycles >= options[:max_cycles]

        @sleep_fn.call(quiet >= 2 ? options[:quiet_interval] : options[:interval])
      end
    end

    def scanner
      build_scanner(parse_common)
    end

    def build_scanner(options)
      store = build_store(options)
      client = GithubClient.new(store.configuration, runner: @runner)
      Scanner.new(client: client, store: store)
    end

    def parse_common
      options = {}
      common_parser(options).parse!(@argv)
      options
    end

    def common_parser(options)
      OptionParser.new do |parser|
        parser.on("--profile NAME") { |value| options[:profile] = value }
        parser.on("--config-home DIR") { |value| options[:config_home] = value }
        parser.on("--state-home DIR") { |value| options[:state_home] = value }
      end
    end

    def build_store(options)
      profile = options[:profile]
      raise Error, "--profile is required" if profile.to_s.empty?

      Store.new(profile: profile, config_home: options[:config_home], state_home: options[:state_home])
    end

    def emit(payload)
      @stdout.puts(JSON.pretty_generate(payload))
    end

    def usage
      "usage: attention setup|doctor|tick|decide|summary|watch --profile NAME"
    end
  end
end
