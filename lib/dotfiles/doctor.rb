# frozen_string_literal: true

module Dotfiles
  class Doctor
    def initialize(root:, home:, shell:, output: $stdout)
      @root = root
      @home = home
      @shell = shell
      @output = output
      @failures = 0
    end

    def run
      check("supported OS", RUBY_PLATFORM.include?("darwin") || RUBY_PLATFORM.include?("linux"), RUBY_PLATFORM)
      %w[git ruby rcup lsrc mise].each { |command| check("command #{command}", @shell.command?(command), "not found") }
      check("canonical mise config", File.file?(File.join(@root, "mise.toml")), "missing")
      obsolete = Installer::OBSOLETE_FILES.select { |name| File.exist?(File.join(@home, name)) || File.symlink?(File.join(@home, name)) }
      check("obsolete managed files", obsolete.empty?, "run ./install to back up and retire #{obsolete.join(', ')}")
      check("local shell override", File.file?(File.join(@home, ".zshrc.local")), "optional: create ~/.zshrc.local")
      check("local Git identity", git_identity?, "set user.name and user.email in ~/.gitconfig.local")
      check_links if @shell.command?("lsrc")
      detect_rails
      @output.puts(@failures.zero? ? "doctor: healthy" : "doctor: #{@failures} required check(s) failed")
      @failures.zero? ? 0 : 1
    end

    private

    def check(label, ok, detail)
      @output.puts("#{ok ? 'ok' : 'warn'}  #{label}#{ok || detail.empty? ? '' : " — #{detail}"}")
      @failures += 1 unless ok || label.start_with?("local ")
    end

    def git_identity?
      config = File.join(@home, ".gitconfig.local")
      return false unless File.file?(config)

      name = @shell.capture("git", "config", "--file", config, "--get", "user.name").strip
      email = @shell.capture("git", "config", "--file", config, "--get", "user.email").strip
      !name.empty? && !email.empty?
    rescue Error
      false
    end

    def check_links
      plan = LinkPlan.new(root: @root, home: @home, shell: @shell)
      conflicts = plan.conflicts
      check("rcm links", conflicts.empty?, "#{conflicts.length} conflict(s); run ./install --dry-run")
    rescue Error => e
      check("rcm links", false, e.message)
    end

    def detect_rails
      root = @shell.capture("git", "rev-parse", "--show-toplevel").strip
      return unless File.file?(File.join(root, "bin", "rails"))

      @output.puts("info  Rails project detected at #{root}")
    rescue Error
      nil
    end
  end
end
