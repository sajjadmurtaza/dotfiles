# Sajjad's Rails-first dotfiles

[![Quality](https://github.com/sajjadmurtaza/dotfiles/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/sajjadmurtaza/dotfiles/actions/workflows/shellcheck.yml)
[![Ruby on Rails](https://img.shields.io/badge/Rails-8.x-ready-CC0000?logo=rubyonrails&logoColor=white)](https://rubyonrails.org/)
[![macOS](https://img.shields.io/badge/macOS-Apple%20Silicon-first-111827?logo=apple)](https://www.apple.com/macos/)
[![Agent skills](https://img.shields.io/badge/skills-Codex%20%7C%20Claude%20%7C%20Cursor-7C3AED)](agents/skills/)

**A safe, fast workstation for Rails and full-stack work—one command, one skill source, no hidden takeover.**

This is a macOS-first developer environment built around Rails conventions, `mise`, Homebrew, `rcm`, Zsh, Git, and portable agent skills. Installation always follows the same transaction:

```text
preview → confirm → back up conflicts → apply → verify
```

[Quick start](#quick-start) · [Profiles](#choose-a-profile) · [Rails workflow](#rails-workflow) · [AI agents](#codex-claude-code-and-cursor) · [Safety](#privacy-and-safety)

## Why this setup

| Goal | Choice |
| --- | --- |
| Safe home-directory changes | `lsrc` preview plus timestamped backups before `rcup` |
| Reproducible runtimes | one exact-pin [`mise.toml`](mise.toml) |
| Selectable tools | one profiled [`Brewfile`](Brewfile), not duplicated manifests |
| Rails-shaped development | small helpers plus a focused Rails 8.x agent skill |
| Portable AI workflows | one canonical [`agents/skills/`](agents/skills/) tree |
| Local privacy | identity, work paths, and secrets stay in untracked override files |

## Quick start

### 1. Prerequisites

- macOS on Apple Silicon or Intel
- [Homebrew](https://brew.sh/)
- Git and the system Ruby (the installer uses only Ruby's standard library)

### 2. Clone and preview

```sh
mkdir -p "$HOME/work"
git clone git@github.com:sajjadmurtaza/dotfiles.git "$HOME/work/dotfiles"
cd "$HOME/work/dotfiles"

./install --dry-run --profile rails
```

Use `git@github-secondary:sajjadmurtaza/dotfiles.git` if your SSH config names that GitHub account `github-secondary`.

The preview prints selected packages and mise tools. When `rcm` is already installed, it also prints every mapping and backup. On a fresh Mac, the installer cannot calculate that link map until the core package step installs `rcm`; it then pauses with the complete preview before changing your home directory. Dry-run changes nothing.

### 3. Apply

```sh
./install --profile rails
```

The installer asks before package changes and again before links. Existing conflicts and obsolete asdf-era runtime files move to:

```text
~/.dotfiles-backups/<UTC timestamp>/
```

For automation, `--yes` skips prompts but still performs backups:

```sh
./install --profile rails --yes
```

Open a new shell and verify:

```sh
exec zsh
dotfiles doctor
```

Success ends with `doctor: healthy`. Optional local files may appear as warnings until you create them.

## Choose a profile

Profiles compose automatically. `rails` is the default and includes `core` and `frontend`; add `ai`, `docker`, or `extras` explicitly when needed.

| Profile | Adds |
| --- | --- |
| `core` | Git, mise, rcm, shell tools, lint/format utilities, Gitleaks |
| `rails` | Ruby, Node LTS, PostgreSQL client, ImageMagick, Overmind |
| `frontend` | Node LTS and Caddy |
| `ai` | Semgrep; shared agent skills are linked for every profile |
| `docker` | Docker Desktop; opt in explicitly |
| `extras` | media, network, backup, publishing, and selected desktop tools |

Examples:

```sh
# Rails plus AI tooling and Docker
./install --profile rails --profile ai --profile docker

# Small shell/tool foundation
./install --profile core

# Refresh links only; install no packages
./install --profile core --skip-packages

# Install everything in the Brewfile after reviewing it
brew bundle --file="$PWD/Brewfile"
```

Linux is supported for linking, tests, verification, and skills. The installer deliberately skips Homebrew provisioning there.

## Rails workflow

The shell stays concise and lets each Rails repository define its own commands.

| Command | Behavior |
| --- | --- |
| `be …` | `bundle exec …` |
| `rt [path]` | use RSpec when `spec/` exists; otherwise `bin/rails test` |
| `rci` | run the app's `bin/ci`; refuse when the app has no native CI entrypoint |
| `rr` | search `rails routes` through `fzf` |
| `fs` | start the Procfile with Overmind |

Runtime defaults are exact in [`mise.toml`](mise.toml). A Rails application's own `mise.toml` takes precedence, so existing projects keep their locked Ruby and Node versions.

The [`ruby-on-rails-dev`](agents/skills/ruby-on-rails-dev/) skill covers version-aware Rails 8/8.1 work, including:

- conventional architecture and KISS boundaries
- Active Record, controllers, Hotwire/Turbo/Stimulus, Active Job, and Action Cable
- safe migrations, constraints, queries, caching, security, and performance
- Propshaft, Solid Queue/Cache/Cable, Thruster, and optional Kamal deployment
- focused tests plus repository-native `bin/ci` assurance

## Codex, Claude Code, and Cursor

The source of truth is [`agents/skills/`](agents/skills/). `rcm` links it to `~/.agents/skills`, and the same skills can be installed project-locally for all three agents.

```sh
npx skills add sajjadmurtaza/dotfiles/agents/skills \
  -a codex -a claude-code -a cursor \
  --skill dev ruby-dev ruby-on-rails-dev code-review \
  -y
```

| Agent | Invoke | Discover |
| --- | --- | --- |
| Codex | `$dev`, `$ruby-on-rails-dev` | `/skills` or type `$` |
| Claude Code | `/dev`, `/ruby-on-rails-dev` | `/skills` |
| Cursor | choose `/dev` or `/ruby-on-rails-dev` | type `/` in Agent chat |

Try this prompt:

```text
Use $dev, $ruby-dev, and $ruby-on-rails-dev to implement this Rails change.
Follow the repository's conventions, keep the design KISS, add focused tests,
run its native CI gate, and finish with $code-review.
```

No tracked Claude setting enables `bypassPermissions`. Agent credentials and MCP connections remain local. See [the cross-agent guide](docs/ai-agents.md) and [skill catalog](agents/skills/README.md).

## Customize locally

Tracked configuration loads optional local files. Copy only the examples you need:

```sh
cp docs/examples/profile.local "$HOME/.profile.local"
cp docs/examples/zshrc.local "$HOME/.zshrc.local"
cp docs/examples/gitconfig.local "$HOME/.gitconfig.local"
cp docs/examples/gitconfig.work "$HOME/.gitconfig.work"
```

| File | Purpose |
| --- | --- |
| `~/.profile.local` | environment shared by login/interactive shells |
| `~/.zshrc.local` | machine-specific aliases and interactive setup |
| `~/.gitconfig.local` | personal Git name, email, signing |
| `~/.gitconfig.work` | identity/settings for repositories under `~/work/company/` |

Keep tokens, customer names, private hosts, and employer-only paths out of this public repository.

Ruby and JavaScript linters belong in each project's `Gemfile` or `package.json`; this setup does not install mutable global copies. Run them through the repository's own `bin/ci`, Bundler, or package-manager scripts.

## Daily commands

| Command | Purpose |
| --- | --- |
| `dothelp` | show the compact command guide |
| `dotfiles doctor` | inspect prerequisites, local overrides, Rails context, and link conflicts |
| `dotfiles verify` | run syntax, profile, identity, skill-shape, ShellCheck, and Gitleaks checks when available |
| `dotfiles benchmark [runs]` | report median interactive Zsh startup time |
| `dotfiles update` | fetch, preview commits, fast-forward, then safely refresh links |
| `skill doctor` | inspect canonical agent skills for local drift |
| `clipcopy` / `clippaste` | portable macOS/Wayland/X11 clipboard pipes |

Git helpers stay conservative. `gnew <branch>` preserves dirty work via a named stash and starts from the remote default branch; `gpf` uses `--force-with-lease`. Worktree creation and deletion remain explicit—see [the worktree guide](docs/git-worktrees.md).

## macOS preferences and backups

macOS defaults are a separate, interactive action:

```sh
./scripts/macos-defaults-apply
```

Backup scripts require an explicit destination and default to a dry run. Example:

```sh
SYSTEM_BACKUP_DIR='/Volumes/MyBackup' ./scripts/backup-system
```

Add `BACKUP_APPLY=1` only after reviewing the exact synchronization output.

## Develop and verify

```sh
make test
make verify
./scripts/dotfiles benchmark 5
```

CI runs ShellCheck, both Ruby test suites, isolated-home installer/idempotency tests, repository consistency checks, and secret scanning.

## Repository map

```text
agents/skills/   canonical cross-agent engineering skills
config/          application configuration linked under ~/.config
docs/            architecture, agent, security-adjacent, and usage guides
lib/dotfiles.rb  safe setup/doctor/update implementation
scripts/         linked command-line helpers
skill/           separate Ruby CLI for skill-store maintenance
test/            setup CLI and installer safety tests
Brewfile         one profile-annotated package source
mise.toml        exact workstation runtime defaults
rcrc             rcm mapping exclusions and rules
```

The design and extension rules are in [docs/architecture.md](docs/architecture.md).

## Privacy and safety

- There is no telemetry, owner-controlled service, or remote reporting.
- A Git remote cannot access your machine; it transfers repository data only when you run Git.
- `--yes` never disables conflict backups.
- Package installation, macOS defaults, repository updates, and backup transfers require explicit commands.
- Run `./install --dry-run` and review diffs before applying updates from any public dotfiles repository.

See [SECURITY.md](SECURITY.md) for the trust model and private reporting path.

This repository does not declare an open-source license. Public visibility allows review, but reuse rights remain reserved unless the owner adds a license deliberately.
