# frozen_string_literal: true

require "fileutils"
require "pathname"
require "tempfile"

module Dotfiles
  class Installer
    Backup = Struct.new(:original, :stored)
    OBSOLETE_FILES = %w[
      .tool-versions
      .default-gems
      .default-npm-packages
      .default-python-packages
      .agents/skills/ruby-on-rails-dev/reference.md
    ].freeze

    def initialize(root:, home:, profiles:, shell:, dry_run:, yes:, skip_packages:, input: $stdin, output: $stdout)
      @root = root
      @home = home
      @profiles = profiles
      @shell = shell
      @dry_run = dry_run
      @yes = yes
      @skip_packages = skip_packages
      @input = input
      @output = output
    end

    def run
      print_plan
      return 0 if @dry_run

      confirm!("Continue with package installation and link preview?") unless @yes
      install_packages unless @skip_packages
      install_mise_tools unless @skip_packages
      install_links
      @output.puts("\nDone. Run 'dotfiles doctor' in a new shell.")
      0
    end

    private

    def print_plan
      @output.puts("Profiles: #{@profiles.names.join(', ')}")
      @output.puts("Home: #{@home}")
      @output.puts("Mode: #{@dry_run ? 'dry run' : 'apply'}")
      print_package_plan unless @skip_packages
      print_link_summary
    end

    def print_package_plan
      entries = Brewfile.new(File.join(@root, "Brewfile")).entries(@profiles)
      @output.puts("\nHomebrew entries (#{entries.length}):")
      entries.each { |entry| @output.puts("  #{entry.strip}") }
      tools = @profiles.mise_tools
      @output.puts("mise tools: #{tools.empty? ? 'none' : tools.join(', ')}")
    end

    def print_link_summary
      unless @shell.command?("lsrc")
        @output.puts("\nrcm link preview will run after the core package installs.")
        return
      end

      plan = LinkPlan.new(root: @root, home: @home, shell: @shell)
      conflicts = plan.conflicts
      obsolete = obsolete_files
      @output.puts("\nrcm mappings (#{plan.mappings.length}); conflicts requiring backup: #{conflicts.length}")
      plan.mappings.each { |mapping| @output.puts("  #{mapping.destination} <- #{mapping.source}") }
      conflicts.each { |mapping| @output.puts("  backup #{mapping.destination}") }
      obsolete.each { |mapping| @output.puts("  retire #{mapping.destination} (backed up)") }
    end

    def install_packages
      unless RUBY_PLATFORM.include?("darwin")
        @output.puts("Skipping Homebrew packages on #{RUBY_PLATFORM}; link installation remains supported.")
        return
      end
      raise Error, "Homebrew is required: install it from https://brew.sh" unless @shell.command?("brew")

      entries = Brewfile.new(File.join(@root, "Brewfile")).entries(@profiles)
      Tempfile.create(["dotfiles-profile", ".Brewfile"]) do |file|
        file.write(entries.join)
        file.flush
        @shell.run("brew", "bundle", "--file=#{file.path}")
      end
    end

    def install_mise_tools
      tools = @profiles.mise_tools
      return if tools.empty?
      raise Error, "mise was not installed by the selected profile" unless @shell.command?("mise")

      config = File.join(@root, "mise.toml")
      @shell.run("mise", "trust", "--yes", config)
      @shell.run("mise", "install", *tools, env: { "MISE_CONFIG_FILE" => config })
    end

    def install_links
      raise Error, "rcm is required; install the core profile first" unless @shell.command?("lsrc") && @shell.command?("rcup")

      plan = LinkPlan.new(root: @root, home: @home, shell: @shell)
      mappings = plan.mappings
      conflicts = plan.conflicts
      obsolete = obsolete_files
      @output.puts("\nLink preview:")
      mappings.each { |mapping| @output.puts("  #{mapping.destination} <- #{mapping.source}") }
      @output.puts("\n#{conflicts.length} conflict(s) will be moved to a timestamped backup.") unless conflicts.empty?
      @output.puts("#{obsolete.length} obsolete managed file(s) will be retired into the same backup.") unless obsolete.empty?
      confirm!("Back up conflicts and apply these links?") unless @yes

      backups = backup(conflicts + obsolete)
      @shell.run("rcup", "-d", @root, "-v", "-i", env: { "HOME" => @home, "RCRC" => File.join(@root, "rcrc") })
    rescue StandardError => e
      rollback(backups, mappings) if backups&.any?
      raise e
    end

    def backup(conflicts)
      return [] if conflicts.empty?

      stamp = ENV.fetch("DOTFILES_TIMESTAMP", Time.now.utc.strftime("%Y%m%dT%H%M%SZ"))
      backup_root = available_backup_root(stamp)
      moved = []
      conflicts.each do |mapping|
        relative = safe_home_relative(mapping.destination)

        target = File.join(backup_root, relative)
        FileUtils.mkdir_p(File.dirname(target))
        FileUtils.mv(mapping.destination, target)
        moved << Backup.new(mapping.destination, target)
        @output.puts("backed up #{mapping.destination} -> #{target}")
      end
      moved
    rescue StandardError => e
      rollback(moved, []) if moved&.any?
      raise Error, "backup failed; no links were applied: #{e.message}"
    end

    def rollback(backups, mappings)
      backups.reverse_each do |entry|
        mapping = mappings.find { |candidate| candidate.destination == entry.original }
        if File.exist?(entry.original) || File.symlink?(entry.original)
          unless mapping && managed_link?(entry.original, mapping.source)
            raise Error, "apply failed and rollback stopped to avoid overwriting: #{entry.original}"
          end
          FileUtils.rm_f(entry.original)
        end
        FileUtils.mkdir_p(File.dirname(entry.original))
        FileUtils.mv(entry.stored, entry.original)
        @output.puts("restored #{entry.original} after failed apply")
      end
    rescue StandardError => rollback_error
      raise Error, "rollback failed: #{rollback_error.message}"
    end

    def managed_link?(destination, source)
      return false unless File.symlink?(destination) && source

      actual = File.expand_path(File.readlink(destination), File.dirname(destination))
      File.expand_path(actual) == File.expand_path(source)
    end

    def safe_home_relative(path)
      home = File.expand_path(@home)
      destination = File.expand_path(path)
      relative = Pathname.new(destination).relative_path_from(Pathname.new(home))
      if relative.absolute? || relative.each_filename.first == ".."
        raise Error, "refusing to back up outside HOME: #{path}"
      end

      ancestor = File.dirname(destination)
      loop do
        raise Error, "refusing to back up beneath symlinked directory: #{path}" if File.symlink?(ancestor)
        break if ancestor == home
        raise Error, "refusing to back up outside HOME: #{path}" if ancestor == File.dirname(ancestor)

        ancestor = File.dirname(ancestor)
      end
      relative.to_s
    end

    def available_backup_root(stamp)
      base = File.join(@home, ".dotfiles-backups", stamp)
      candidate = base
      suffix = 1
      while File.exist?(candidate)
        candidate = "#{base}-#{suffix}"
        suffix += 1
      end
      candidate
    end

    def obsolete_files
      OBSOLETE_FILES.each_with_object([]) do |name, files|
        path = File.join(@home, name)
        files << Mapping.new(path, nil) if File.exist?(path) || File.symlink?(path)
      end
    end

    def confirm!(question)
      @output.print("#{question} [y/N] ")
      answer = @input.gets
      raise Error, "cancelled" unless answer && answer.strip.match?(/\Ay(?:es)?\z/i)
    end
  end
end
