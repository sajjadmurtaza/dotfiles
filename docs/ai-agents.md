# AI agent skills

The repository keeps one portable skill source in `agents/skills/`. The same `SKILL.md` workflow is consumed by Codex, Claude Code, and Cursor; there are no divergent copies to maintain.

Each entrypoint contains only routing and shared safety rules. Branch-specific procedures live in references that load on demand, so a routine task does not pay the context cost of the entire pipeline.

## Install

### Global — recommended for personal use

From the dotfiles repository root, install once and use the skills from every repository:

```sh
npx skills add ./agents/skills \
  -g \
  --copy \
  -a codex -a claude-code -a cursor \
  -y
```

The global location is `~/.agents/skills/<skill-name>/`. Installing the complete store keeps required dependencies such as `architecture` available to `dev`. Open a new task or agent session after installing so its skill catalog refreshes. Use `npx skills list -g` to inspect the global installation.

> [!IMPORTANT]
> A global installation is available from every repository. Do not repeat the project-local installation unless the repository should carry and maintain its own skill copies.

### Update a global installation

Update all globally installed skills from their recorded source, then confirm what is installed:

```sh
npx skills update -g -y
npx skills list -g
```

Update selected skills only:

```sh
npx skills update code-review dev ruby-dev ruby-on-rails-dev pull-request -g -y
```

> [!TIP]
> `npx skills update` refreshes installed skills. Rerun the full `npx skills add ./agents/skills ... --copy` command after the store adds a new skill or when testing unpublished local edits. Restart the agent or open a new task/session afterward.

For a checked-out copy, the complete refresh sequence is:

```sh
git pull --ff-only
make verify
npx skills add ./agents/skills \
  -g --copy \
  -a codex -a claude-code -a cursor \
  -y
npx skills list -g
```

The `--copy` option makes the global installation independent of the checkout. Repeat the command after local skill edits; open a new task or session so the client reloads its catalog.

### Project-local — optional

Use this only when a team intentionally wants the skills stored with one repository. Run it from that repository, set the source to the published dotfiles repository, and omit `-g`:

```sh
DOTFILES_SKILLS_SOURCE="https://github.com/your-account/dotfiles/tree/main/agents/skills"
npx skills add "$DOTFILES_SKILLS_SOURCE" \
  --copy \
  -a codex -a claude-code -a cursor \
  -y
```

This creates repository-level agent files. Review them like code and commit them only with team agreement. You do not need to repeat this in every repository when the global installation is present.

> [!WARNING]
> Project-local skills become part of that repository's maintenance surface. Commit them only when the team has agreed to review and update them.

## Invoke

| Agent | Explicit use | Discover |
| --- | --- | --- |
| Codex | Mention `$dev` or `$ruby-on-rails-dev` | `/skills` or type `$` |
| Claude Code | Run `/dev` or `/ruby-on-rails-dev` | `/skills` |
| Cursor | Select `/dev` or `/ruby-on-rails-dev` | type `/` in Agent chat |

Agents can also select a skill automatically from its description. Explicit invocation is useful when the workflow must be predictable.

## Pipeline entry points

| Situation | Start with | Next |
| --- | --- | --- |
| Incident or unclear operational problem | `triage` | product decision or `$dev plan` |
| Jira-led work | `jira-ticket` | product gate when needed, then `$dev` |
| Product scope decision | `product-owner` | `$dev` only after Build Now |
| Clear implementation | `dev` | architecture/runtime routing, then code review |
| Implementation plan | `dev` plan | phase execution, then one `code-review` pass |
| Service-health review | `ops-chore` | admitted fixes can enter `$dev` plan |
| PR attention or session watch | `pr-sweep` | exact `pull-request`, `dependabot`, or `code-review` action |

## Read-only GitHub attention

`pr-sweep` has one shared implementation for all repositories. A named local
profile supplies the expected GitHub login, allowed owners/repositories, and a
dedicated `GH_CONFIG_DIR`; no company or account is hardcoded in the skill.

Use the skill's `setup` branch once per profile. Thereafter:

```text
Use $pr-sweep for profile PROFILE. Run doctor and one attention scan. If this
agent can surface background-process output, monitor meaningful changes for the
rest of this session. Stay read-only and do not execute routed actions.
```

The monitor runs an initial scan, polls after three minutes, and backs off to
ten-minute quiet intervals. It ends with the agent session or when explicitly
stopped; it is not a daemon or scheduler. Unsupported hosts remain on-demand.

The helper stores only minimal PR identity, classification, route, fingerprint,
decision, and timestamps. It excludes titles, bodies, comments, CI logs, and
credentials. Profiles and ledgers are local `0700`/`0600` data. Account mismatch
is a hard stop, and no command in this skill mutates GitHub.

When an item needs action, enter the target repository and follow its live rules
before invoking the returned specialist skill. Do not load every skill during a
scan. Automatic flaky-CI retries remain deferred until read-only monitoring has
been validated with real use and separately approved.

## Rails example

```text
Use $dev, $ruby-dev, and $ruby-on-rails-dev to add account suspension.
Follow repository conventions, keep the design KISS, test authorization and
tenant boundaries, run the native CI gate, then use $code-review.
```

The Rails overlay stays intentionally small and loads alongside `dev` and `ruby-dev`. Repository-local `AGENTS.md` and project skills remain authoritative for application-specific commands, architecture, and security rules.

## Safe agent configuration

- Skills contain instructions and optional local scripts; read their diffs like code.
- No tracked Claude configuration enables `bypassPermissions` or broad command allowlists.
- Agent-specific credentials and MCP connections stay in each agent's local settings, not this public repository.
- Project rules remain authoritative. A skill should adapt to the repository rather than replace its architecture.

Before adding a third-party skill or MCP server:

1. Verify the repository, maintainer, license, revision, recent maintenance, and the exact files that will be installed. Stars and install counts indicate popularity, not safety.
2. Read `SKILL.md`, scripts, package manifests, install hooks, network calls, telemetry, and requested filesystem, credential, and tool permissions.
3. Prefer a pinned revision and the smallest capability set. Do not use download-and-execute commands such as `curl ... | sh`.
4. Keep credentials in the agent's approved local secret store. Never commit MCP tokens or copy them into prompts, logs, examples, or reports.
5. Test in a disposable or least-privileged environment. Require explicit approval before active endpoint probing, dependency installation, or external writes.
6. Re-review source changes before updating. Remove access that is no longer needed.

Use `$code-review` with its `security` lens for security-sensitive code and for changes to skills, MCP servers, retrieved-content pipelines, or agent tool permissions. The review is defensive and read-only by default; it does not authorize penetration testing or installation of scanners.

Before installing a new integration, the short reusable prompt is enough:

```text
Use $code-review to audit this skill or MCP before installation: [SOURCE]
```

`$code-review` automatically selects the security lens, loads the saved
agent/tool supply-chain checklist, stays read-only, and returns an
install/adapt/reject recommendation. Add special scope only when needed; do not
copy the full checklist into every prompt.

For a local code security check, prefer the repository's configured scanners
and run only the smallest check that covers the changed risk:

```text
Use $code-review with the security lens on the current diff. Read repository
instructions and inventory existing security gates first. Prefer installed,
pinned repository-native commands. Stay read-only: do not install tools,
download rules or advisory data, enable telemetry, upload source or results,
probe endpoints, or fix findings without my explicit approval. Separate scanner
alerts from verified defects and report coverage gaps.
```

The saved tool-selection reference distinguishes SAST, dependency, secret, and
image/IaC coverage. It does not run every scanner by default. For full-tree,
Git-history, or sanitized HTML output, set `REPOSITORY_PATH`, `SECURITY_SCOPE`,
`ANALYSIS_DEPTH`, `SAST_ENGINE`, `HISTORY_SCAN`, and `OUTPUT`; the skill presents
an exact read-only scan plan and stops for approval before execution.

### Optional Semgrep CE setup

The default `rails` profile does not install Semgrep. Opt into the dotfiles
`ai` profile when the Homebrew formula is sufficient:

```sh
./install --profile rails --profile ai
semgrep --version
```

For a reproducible standalone version, review the official release and install
a pinned Semgrep CE tool with the existing Python tool manager instead:

```sh
uv tool install 'semgrep==APPROVED_VERSION'
semgrep --version
```

Use one installation path and confirm the resolved executable with
`command -v semgrep`. Neither path downloads registry rules until a scan selects
them.

Use `--metrics off` for local scans. Registry packs such as `p/ruby` and
`p/ruby-on-rails-xss` download rules but keep the scanned source local; obtain
network/rule-download approval first. Save JSON and SARIF in a private temporary
directory, keep reports untracked, and manually verify alerts. To upgrade,
review the official release notes, repin the approved version with
`uv tool install --force 'semgrep==NEW_APPROVED_VERSION'`, and rerun a known
scan before relying on it.

Codex officially scans user skills in `~/.agents/skills`. See [OpenAI's skill documentation](https://developers.openai.com/codex/skills). The complete catalog and authoring rules live in [`../agents/skills/README.md`](../agents/skills/README.md).
