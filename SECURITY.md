# Security policy

## Trust model

These dotfiles run locally. They configure the shell, link files in the current user's home directory, and optionally invoke Homebrew and mise. They contain no telemetry, remote reporting, background owner service, or remote-access mechanism.

Git remotes transfer repository data only when a user runs Git. Cloning or using this repository does not give its owner access to the machine, files, terminal, agent conversations, credentials, or application state.

## Safe installation

- Start with `./install --dry-run --profile rails`.
- The apply path previews `lsrc`, moves conflicts to `~/.dotfiles-backups/<timestamp>/`, then invokes `rcup`.
- Interactive replacement requires typing `replace`; a simple `y` is insufficient.
- `--yes` refuses existing-file replacement unless `--replace-conflicts` is also present.
- Approved conflicts are backed up before `rcup` and restored if link application fails.
- Preserve Oh My Zsh theme/plugins in `~/.zshrc.pre.local`, aliases/functions in `~/.zshrc.local`, and Git customization in `~/.gitconfig.local` or `~/.gitconfig.work` before approving replacement.
- macOS preference and backup scripts require explicit commands; backup scripts default to a dry run.
- Review the selected Brewfile sections before installing system packages or applications.

## Secrets

Keep tokens, private hosts, customer paths, signing keys, and employer identity in untracked local files such as `~/.profile.local`, `~/.zshrc.local`, `~/.gitconfig.local`, and `~/.gitconfig.work`. Agent credentials and MCP connections belong in each product's local settings.

The repository's verification uses Gitleaks when available, and CI scans committed content. Secret scanning reduces risk but does not make committed secrets safe; revoke and rotate any exposed credential immediately.

## Reporting

Report a suspected vulnerability privately through this repository's **Security → Report a vulnerability** flow. Do not include live credentials, customer data, or exploit payloads containing sensitive information in a public issue.
