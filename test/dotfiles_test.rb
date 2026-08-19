# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "stringio"
require "tmpdir"

require_relative "../lib/dotfiles"

class FakeShell
  attr_reader :runs

  def initialize(commands: [], captures: {}, fail_runs: [])
    @commands = commands
    @captures = captures
    @runs = []
    @fail_runs = fail_runs
  end

  def command?(name)
    @commands.include?(name)
  end

  def capture(*command, env: {})
    _ = env
    @captures.fetch(command.join(" "), "")
  end

  def run(*command, env: {})
    @runs << [command, env]
    raise Dotfiles::Error, "command failed: #{command.join(' ')}" if @fail_runs.include?(command.first)
  end
end

class ProfilesTest < Minitest::Test
  def test_rails_is_the_default_and_includes_its_dependencies
    profiles = Dotfiles::Profiles.new([])

    assert_equal(%w[core frontend rails], profiles.names)
    assert_equal(%w[node ruby], profiles.mise_tools)
  end

  def test_rejects_unknown_profile
    error = assert_raises(Dotfiles::Error) { Dotfiles::Profiles.new(["enterprise"]) }

    assert_match(/unknown profile/, error.message)
  end
end

class BrewfileTest < Minitest::Test
  def test_selects_entries_without_duplicating_profile_data
    Dir.mktmpdir do |dir|
      path = File.join(dir, "Brewfile")
      File.write(path, "# profile: core\nbrew \"git\"\n# profile: docker\ncask \"docker\"\n")

      entries = Dotfiles::Brewfile.new(path).entries(Dotfiles::Profiles.new(["core"]))

      assert_equal(["brew \"git\"\n"], entries)
    end
  end
end

class ShellStartupTest < Minitest::Test
  def test_zshrc_can_use_profile_helpers_during_startup
    Dir.mktmpdir do |home|
      root = File.expand_path("..", __dir__)
      File.symlink(File.join(root, "profile"), File.join(home, ".profile"))
      File.symlink(File.join(root, "zshrc"), File.join(home, ".zshrc"))

      output, status = Open3.capture2e({ "HOME" => home }, "zsh", "-dfc", "source ~/.zshrc")

      assert_predicate(status, :success?)
      refute_match(/command not found: command_exists/, output)
    end
  end
end

class LinkPlanTest < Minitest::Test
  def test_reports_only_non_matching_destinations_as_conflicts
    Dir.mktmpdir do |dir|
      home = File.join(dir, "home")
      source = File.join(dir, "zshrc")
      linked = File.join(home, ".zshrc")
      conflict = File.join(home, ".profile")
      FileUtils.mkdir_p(home)
      File.write(source, "source\n")
      File.symlink(source, linked)
      File.write(conflict, "mine\n")
      output = "#{linked}:#{source}\n#{conflict}:#{File.join(dir, 'profile')}\n"
      shell = FakeShell.new(captures: { "lsrc -d #{dir}" => output })

      conflicts = Dotfiles::LinkPlan.new(root: dir, home: home, shell: shell).conflicts

      assert_equal([conflict], conflicts.map(&:destination))
    end
  end

  def test_rejects_destination_beneath_symlinked_home_directory
    Dir.mktmpdir do |dir|
      home = File.join(dir, "home")
      outside = File.join(dir, "outside")
      FileUtils.mkdir_p([home, outside])
      File.symlink(outside, File.join(home, ".config"))
      destination = File.join(home, ".config", "tool", "config")
      shell = FakeShell.new(captures: { "lsrc -d #{dir}" => "#{destination}:#{File.join(dir, 'config')}\n" })

      error = assert_raises(Dotfiles::Error) do
        Dotfiles::LinkPlan.new(root: dir, home: home, shell: shell).mappings
      end

      assert_match(/symlinked directory/, error.message)
    end
  end
end

class InstallerTest < Minitest::Test
  def test_dry_run_never_runs_commands
    output = StringIO.new
    shell = FakeShell.new

    status = Dotfiles::Installer.new(root: File.expand_path("..", __dir__), home: Dir.tmpdir,
                                     profiles: Dotfiles::Profiles.new(["core"]), shell: shell,
                                     dry_run: true, yes: true, skip_packages: false,
                                     output: output).run

    assert_equal(0, status)
    assert_empty(shell.runs)
    assert_includes(output.string, "Mode: dry run")
  end

  def test_yes_still_backs_up_conflicts_before_rcup
    Dir.mktmpdir do |dir|
      root = File.join(dir, "repo")
      home = File.join(dir, "home")
      FileUtils.mkdir_p(root)
      FileUtils.mkdir_p(home)
      File.write(File.join(root, "rcrc"), "")
      conflict = File.join(home, ".zshrc")
      source = File.join(root, "zshrc")
      File.write(conflict, "personal\n")
      File.write(source, "managed\n")
      shell = FakeShell.new(commands: %w[lsrc rcup], captures: { "lsrc -d #{root}" => "#{conflict}:#{source}\n" })
      ENV["DOTFILES_TIMESTAMP"] = "test"

      Dotfiles::Installer.new(root: root, home: home, profiles: Dotfiles::Profiles.new(["core"]),
                              shell: shell, dry_run: false, yes: true, skip_packages: true,
                              output: StringIO.new).run

      refute(File.exist?(conflict))
      assert_equal("personal\n", File.read(File.join(home, ".dotfiles-backups", "test", ".zshrc")))
      assert_equal("rcup", shell.runs.last[0].first)
    ensure
      ENV.delete("DOTFILES_TIMESTAMP")
    end
  end

  def test_obsolete_runtime_file_is_retired_into_backup
    Dir.mktmpdir do |dir|
      root = File.join(dir, "repo")
      home = File.join(dir, "home")
      FileUtils.mkdir_p(root)
      FileUtils.mkdir_p(home)
      File.write(File.join(root, "rcrc"), "")
      File.write(File.join(home, ".tool-versions"), "ruby 3.4.9\n")
      shell = FakeShell.new(commands: %w[lsrc rcup], captures: { "lsrc -d #{root}" => "" })
      ENV["DOTFILES_TIMESTAMP"] = "legacy"

      Dotfiles::Installer.new(root: root, home: home, profiles: Dotfiles::Profiles.new(["core"]),
                              shell: shell, dry_run: false, yes: true, skip_packages: true,
                              output: StringIO.new).run

      refute(File.exist?(File.join(home, ".tool-versions")))
      assert_equal("ruby 3.4.9\n", File.read(File.join(home, ".dotfiles-backups", "legacy", ".tool-versions")))
    ensure
      ENV.delete("DOTFILES_TIMESTAMP")
    end
  end

  def test_obsolete_skill_reference_is_retired_into_backup
    Dir.mktmpdir do |dir|
      root = File.join(dir, "repo")
      home = File.join(dir, "home")
      obsolete = File.join(home, ".agents", "skills", "ruby-on-rails-dev", "reference.md")
      FileUtils.mkdir_p([root, File.dirname(obsolete)])
      File.write(File.join(root, "rcrc"), "")
      File.write(obsolete, "old combined reference\n")
      shell = FakeShell.new(commands: %w[lsrc rcup], captures: { "lsrc -d #{root}" => "" })
      ENV["DOTFILES_TIMESTAMP"] = "skill-migration"

      Dotfiles::Installer.new(root: root, home: home, profiles: Dotfiles::Profiles.new(["core"]),
                              shell: shell, dry_run: false, yes: true, skip_packages: true,
                              output: StringIO.new).run

      refute(File.exist?(obsolete))
      stored = File.join(home, ".dotfiles-backups", "skill-migration", ".agents", "skills",
                         "ruby-on-rails-dev", "reference.md")
      assert_equal("old combined reference\n", File.read(stored))
    ensure
      ENV.delete("DOTFILES_TIMESTAMP")
    end
  end

  def test_failed_rcup_restores_backed_up_conflicts
    Dir.mktmpdir do |dir|
      root = File.join(dir, "repo")
      home = File.join(dir, "home")
      FileUtils.mkdir_p([root, home])
      File.write(File.join(root, "rcrc"), "")
      conflict = File.join(home, ".zshrc")
      source = File.join(root, "zshrc")
      File.write(conflict, "personal\n")
      File.write(source, "managed\n")
      shell = FakeShell.new(commands: %w[lsrc rcup], fail_runs: ["rcup"],
                            captures: { "lsrc -d #{root}" => "#{conflict}:#{source}\n" })

      assert_raises(Dotfiles::Error) do
        Dotfiles::Installer.new(root: root, home: home, profiles: Dotfiles::Profiles.new(["core"]),
                                shell: shell, dry_run: false, yes: true, skip_packages: true,
                                output: StringIO.new).run
      end

      assert_equal("personal\n", File.read(conflict))
    end
  end

  def test_existing_backup_timestamp_gets_a_unique_suffix
    Dir.mktmpdir do |dir|
      root = File.join(dir, "repo")
      home = File.join(dir, "home")
      FileUtils.mkdir_p(File.join(home, ".dotfiles-backups", "same"))
      FileUtils.mkdir_p(root)
      File.write(File.join(root, "rcrc"), "")
      File.write(File.join(home, ".tool-versions"), "ruby 3.4.9\n")
      shell = FakeShell.new(commands: %w[lsrc rcup], captures: { "lsrc -d #{root}" => "" })
      ENV["DOTFILES_TIMESTAMP"] = "same"

      Dotfiles::Installer.new(root: root, home: home, profiles: Dotfiles::Profiles.new(["core"]),
                              shell: shell, dry_run: false, yes: true, skip_packages: true,
                              output: StringIO.new).run

      assert_equal("ruby 3.4.9\n", File.read(File.join(home, ".dotfiles-backups", "same-1", ".tool-versions")))
    ensure
      ENV.delete("DOTFILES_TIMESTAMP")
    end
  end

  def test_cancelled_install_does_not_apply
    shell = FakeShell.new(commands: %w[lsrc rcup])
    installer = Dotfiles::Installer.new(root: File.expand_path("..", __dir__), home: Dir.tmpdir,
                                        profiles: Dotfiles::Profiles.new(["core"]), shell: shell,
                                        dry_run: false, yes: false, skip_packages: true,
                                        input: StringIO.new("n\n"), output: StringIO.new)

    assert_raises(Dotfiles::Error) { installer.run }
    assert_empty(shell.runs)
  end

  def test_runtime_install_trusts_the_canonical_mise_config_first
    shell = FakeShell.new(commands: %w[brew mise lsrc rcup])
    root = File.expand_path("..", __dir__)

    Dotfiles::Installer.new(root: root, home: Dir.tmpdir, profiles: Dotfiles::Profiles.new(["frontend"]),
                            shell: shell, dry_run: false, yes: true, skip_packages: false,
                            output: StringIO.new).run

    trust_index = shell.runs.index { |command, _env| command[0, 3] == ["mise", "trust", "--yes"] }
    install_index = shell.runs.index { |command, _env| command[0, 2] == ["mise", "install"] }
    assert_operator(trust_index, :<, install_index)
  end
end

class CLITest < Minitest::Test
  def test_help
    output = StringIO.new

    status = Dotfiles::CLI.run(["help"], output: output, error: StringIO.new)

    assert_equal(0, status)
    assert_includes(output.string, "dotfiles <command>")
  end

  def test_invalid_command_fails_cleanly
    error = StringIO.new

    status = Dotfiles::CLI.run(["explode"], output: StringIO.new, error: error)

    assert_equal(1, status)
    assert_includes(error.string, "unknown command")
  end

  def test_install_help_exits_successfully
    output = StringIO.new

    status = Dotfiles::CLI.run(["install", "--help"], output: output, error: StringIO.new)

    assert_equal(0, status)
    assert_includes(output.string, "--dry-run")
  end
end
