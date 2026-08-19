# frozen_string_literal: true

require "rbconfig"

module Dotfiles
  class Verifier
    def initialize(root:, shell:, output: $stdout)
      @root = root
      @shell = shell
      @output = output
      @failures = []
    end

    def run
      exact_mise_versions
      brewfile_profiles
      forbidden_personalization
      ruby_syntax
      shell_syntax
      skill_shapes
      documentation_links
      optional_tools
      return success if @failures.empty?

      @failures.each { |failure| @output.puts("FAIL  #{failure}") }
      1
    end

    private

    def success
      @output.puts("verify: all checks passed")
      0
    end

    def exact_mise_versions
      body = File.read(File.join(@root, "mise.toml"))
      @failures << "mise.toml contains a floating version" if body.match?(/=\s*["'](?:latest|\d+|\d+\.\d+)["']/)
    rescue Errno::ENOENT
      @failures << "mise.toml is missing"
    end

    def brewfile_profiles
      profiles = Brewfile.new(File.join(@root, "Brewfile")).all_profiles
      missing = Profiles::NAMES - profiles
      @failures << "Brewfile is missing profiles: #{missing.join(', ')}" unless missing.empty?
    rescue Error => e
      @failures << e.message
    end

    def forbidden_personalization
      needles = [
        ["gil", "desmarais"].join,
        ["gil", "barbara"].join,
        ["saj", "jad"].join,
        ["mur", "taza"].join,
        ["gor", "eha"].join,
        ["cas", "par"].join
      ]
      files = Dir.glob(File.join(@root, "**", "*"), File::FNM_DOTMATCH).reject do |path|
        File.directory?(path) || path.include?("/.git/")
      end
      match = files.find do |path|
        body = File.symlink?(path) ? File.readlink(path) : File.binread(path)
        next false unless body.valid_encoding?

        normalized = body.downcase
        needles.any? { |needle| normalized.include?(needle) } || body.match?(%r{/Users/[A-Za-z0-9._-]+/})
      rescue StandardError
        false
      end
      @failures << "tracked personalization remains: #{match.sub("#{@root}/", '')}" if match

      gitconfig = File.join(@root, "gitconfig")
      return unless File.file?(gitconfig) && File.read(gitconfig).match?(/^\[user\]$/)

      @failures << "gitconfig contains a tracked user identity; use ~/.gitconfig.local"
    end

    def ruby_syntax
      Dir[File.join(@root, "{install,lib/**/*.rb,scripts/dotfiles}")].each do |file|
        @shell.capture(RbConfig.ruby, "-c", file)
      rescue Error => e
        @failures << e.message
      end
    end

    def shell_syntax
      tracked_shell_files.each do |file|
        path = File.join(@root, file)
        interpreter = File.open(path, &:readline).include?("bash") ? "bash" : "sh"
        @shell.capture(interpreter, "-n", path)
      rescue Error => e
        @failures << e.message
      end
      @shell.capture("zsh", "-n", File.join(@root, "zshrc")) if @shell.command?("zsh")
    rescue Error => e
      @failures << e.message
    end

    def tracked_shell_files
      @shell.capture("git", "-C", @root, "ls-files").lines.map(&:strip).select do |file|
        path = File.join(@root, file)
        File.file?(path) && File.open(path, &:readline).match?(/^#!.*sh/) rescue false
      end
    end

    def skill_shapes
      Dir[File.join(@root, "agents", "skills", "*")].select { |path| File.directory?(path) }.each do |path|
        @failures << "missing #{path}/SKILL.md" unless File.file?(File.join(path, "SKILL.md"))
      end
    end

    def documentation_links
      documents.each do |document|
        File.read(document).scan(/\[[^\]]+\]\(([^)]+)\)/).flatten.each do |target|
          next if target.start_with?("http://", "https://", "#", "mailto:")

          path = target.split("#", 2).first
          resolved = File.expand_path(path, File.dirname(document))
          unless File.exist?(resolved)
            @failures << "broken documentation link: #{document.sub("#{@root}/", '')} -> #{target}"
          end
        end
      end
    end

    def documents
      [File.join(@root, "README.md"), File.join(@root, "SECURITY.md")] + Dir[File.join(@root, "docs", "**", "*.md")]
    end

    def optional_tools
      run_shellcheck if @shell.command?("shellcheck")
      @shell.capture("gitleaks", "detect", "--source", @root, "--no-git", "--redact") if @shell.command?("gitleaks")
    rescue Error => e
      @failures << e.message
    end

    def run_shellcheck
      scripts = @shell.capture("git", "-C", @root, "ls-files", "scripts").lines.map(&:strip).select do |file|
        path = File.join(@root, file)
        File.file?(path) && File.open(path, &:readline).include?("sh") rescue false
      end
      @shell.capture("shellcheck", *scripts.map { |file| File.join(@root, file) }) unless scripts.empty?
    end
  end
end
