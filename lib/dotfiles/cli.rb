# frozen_string_literal: true

require "optparse"

module Dotfiles
  class CLI
    def self.run(argv, root: File.expand_path("../..", __dir__), home: ENV.fetch("HOME"), shell: Shell.new,
                 input: $stdin, output: $stdout, error: $stderr)
      new(argv, root: root, home: home, shell: shell, input: input, output: output).run
    rescue Error, OptionParser::ParseError => e
      error.puts("dotfiles: #{e.message}")
      1
    end

    def initialize(argv, root:, home:, shell:, input:, output:)
      @argv = argv.dup
      @root = root
      @home = home
      @shell = shell
      @input = input
      @output = output
    end

    def run
      command = @argv.shift || "help"
      case command
      when "install" then install
      when "doctor" then Doctor.new(root: @root, home: @home, shell: @shell, output: @output).run
      when "verify" then Verifier.new(root: @root, shell: @shell, output: @output).run
      when "update" then update
      when "benchmark" then benchmark
      when "help", "-h", "--help" then help
      else raise Error, "unknown command: #{command}"
      end
    end

    private

    def install
      options = parse_install_options
      return 0 if options.delete(:help)

      Installer.new(root: @root, home: @home, profiles: Profiles.new(options[:profiles]), shell: @shell,
                    dry_run: options[:dry_run], yes: options[:yes], skip_packages: options[:skip_packages],
                    input: @input, output: @output).run
    end

    def parse_install_options
      options = { profiles: [], dry_run: false, yes: false, skip_packages: false }
      parser = OptionParser.new do |opts|
        opts.on("--profile NAME", "core, rails, frontend, docker, ai, or extras") { |name| options[:profiles].concat(name.split(",")) }
        opts.on("--dry-run", "show every action without changing files") { options[:dry_run] = true }
        opts.on("--yes", "skip prompts; conflict backups still run") { options[:yes] = true }
        opts.on("--skip-packages", "link configuration without installing packages") { options[:skip_packages] = true }
        opts.on("-h", "--help") { @output.puts(opts); options[:help] = true }
      end
      parser.parse!(@argv)
      raise Error, "unexpected arguments: #{@argv.join(' ')}" unless @argv.empty?
      options
    end

    def update
      yes = @argv.delete("--yes")
      raise Error, "unexpected arguments: #{@argv.join(' ')}" unless @argv.empty?
      @shell.run("git", "-C", @root, "fetch", "--prune")
      pending = @shell.capture("git", "-C", @root, "log", "--oneline", "HEAD..@{upstream}")
      return @output.puts("Already up to date.") || 0 if pending.empty?

      @output.puts(pending)
      confirm_update! unless yes
      @shell.run("git", "-C", @root, "pull", "--ff-only")
      Installer.new(root: @root, home: @home, profiles: Profiles.new(["core"]), shell: @shell,
                    dry_run: false, yes: true, skip_packages: true, input: @input, output: @output).run
    end

    def confirm_update!
      @output.print("Fast-forward and refresh links? [y/N] ")
      answer = @input.gets
      raise Error, "cancelled" unless answer && answer.strip.match?(/\Ay(?:es)?\z/i)
    end

    def benchmark
      count = Integer(@argv.shift || "5")
      raise Error, "benchmark count must be between 1 and 20" unless count.between?(1, 20) && @argv.empty?
      times = count.times.map do
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @shell.capture("zsh", "-i", "-c", "exit", env: { "HOME" => @home })
        Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
      end.sort
      @output.puts(format("zsh interactive startup median: %.3fs (%d runs)", times[times.length / 2], count))
      0
    rescue ArgumentError
      raise Error, "benchmark count must be an integer between 1 and 20"
    end

    def help
      @output.puts <<~HELP
        Usage: dotfiles <command> [options]

          install     preview, back up conflicts, and apply a profile
          doctor      inspect prerequisites, local overrides, and links
          verify      run repository syntax and consistency checks
          update      preview upstream commits, fast-forward, and refresh links
          benchmark   measure interactive Zsh startup (default: 5 runs)

        Quick start: ./install --dry-run --profile rails
      HELP
      0
    end
  end
end
