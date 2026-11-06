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

## Optional EGM design gate

[Elephant-Goldfish Model](https://github.com/google/elephant-goldfish-model)
is an optional design plugin, not a replacement for `dev`, repository rules,
tests, or code review. Use it only when a feature has meaningful competing
designs, unclear ownership, privacy/retention policy, irreversible behavior, or
cross-system rollout. Routine fixes stay in the normal pipeline. Persisted-field
and multi-stage lifecycle work always loads the conditional
`dev/reference/lifecycle-completeness.md` checkpoint, whether or not EGM is used.

Install the upstream plugin separately from this skill store:

```sh
codex plugin marketplace add google/elephant-goldfish-model
codex plugin add egm@egm

claude plugin marketplace add google/elephant-goldfish-model
claude plugin install egm@egm
```

Start a new session afterward. In Codex, select the EGM skill from the skill
picker. In Claude Code, begin with `/egm:egm-brainstorm`, then use
`/egm:egm-draft` and `/egm:egm-review`. Fresh-context review requires a host
that can create isolated subagents; if that cannot be verified, treat the EGM
review as inconclusive and use a separate review session.

Cursor is documentation-only in this setup: design in Codex or Claude, approve
the resulting document, then implement that approved design in Cursor using the
normal repository workflow. Do not copy EGM into this repository or install an
unverified adapter to make the clients look identical.

## Read-only GitHub attention

`pr-sweep` has one shared implementation for all repositories. A named local
profile supplies the expected GitHub login, allowed owners/repositories, and a
dedicated `GH_CONFIG_DIR`; no company or account is hardcoded in the skill.

Use the skill's `setup` branch once per profile. Then choose the operating mode
instead of assuming every agent can wake itself:

| Mode | Use when | Lifecycle |
| --- | --- | --- |
| **Scan now** | You want the current queue | One `doctor` + `tick`, then stop |
| **Session monitor** | Claude Code or another host demonstrably returns background output | Checks at 3 minutes, then 10-minute quiet intervals; ends with the session |
| **Codex heartbeat** | You want unattended notifications | Scheduled task runs one `tick`; ledger suppresses unchanged items |
| **Fixed snapshots** | Morning/afternoon summaries are enough | Scheduled at exact local times; not continuous monitoring |

The Ruby helper is the detector. The active-session monitor or Codex scheduled
task is the wake bridge. Verify both independently: a successful `tick` proves
detection; only a `PR_SWEEP_WAKE` or scheduled run arriving without another user
prompt proves notification.

The sweep is private triage. It never posts generated text to teammates. Its
brief uses one factual line per changed PR and avoids canned greetings,
conclusions, or claims of work not performed. Any external reply goes through
the target repository's review/PR workflow, with the actual thread and evidence
loaded first.

Conflicts, failing CI, and unresolved feedback sort ahead of review requests and
dependency updates; drafts are ignored and recent activity sorts first within a
tier. Fingerprints suppress unchanged items, an owner-only lock protects
overlapping manual/scheduled runs, and a repeated GitHub outage wakes once while
the watcher keeps retrying.

For one scan:

```text
Use $pr-sweep for profile PROFILE. Run doctor and one read-only attention scan.
Show only changed items and exact routes. Do not execute routed actions.
```

### Cursor one-copy start

Open a Cursor Agent chat, choose `/pr-sweep` when it appears, and paste:

```text
Use the pr-sweep skill for profile PROFILE.

Run doctor and one read-only GitHub attention scan. If the profile or dedicated
GitHub authentication is missing, show the exact setup action and stop. If
doctor passes, show only new or changed items with repository, PR number,
reason, urgency, and exact recommended route.

Stay on-demand unless this Agent chat can demonstrably receive background
process output. Do not execute a route, edit code, rerun CI, deploy, push,
comment, resolve, approve, or merge.
```

Run the prompt separately for each profile. Never combine company accounts,
authentication directories, ledgers, owners, or repository rules in one scan.

### Codex automatic heartbeat

First make `doctor` and one manual scan pass. Then invoke `$pr-sweep`'s
**schedule** branch and create one read-only Codex Desktop task per profile. Use
the location's IANA time zone so daylight-saving changes are handled. A
ten-minute work-window cadence monitors changes; exact morning/afternoon times
produce snapshots. The scheduled prompt runs exactly one `tick`, stays silent
when quiet, and reports changed items without executing their routes.

Review the saved profile, project, time zone, cadence, and first runs in Codex
Scheduled. Network access must work without an interactive approval; otherwise
the run reports the blocker and stops. OpenAI documents that scheduled tasks can
invoke skills and use minute-based intervals in a chat: [Scheduled
tasks](https://learn.chatgpt.com/docs/automations).

### Claude Code active-session monitor

Use `$pr-sweep`'s **monitor** branch. It keeps the watcher attached to the active
session and reacts only to `PR_SWEEP_WAKE`. This is the same two-layer pattern:
the Ruby process polls cheaply, while the host waits for its output. Re-arm the
host monitor if it has a time limit; closing the session stops monitoring.

### Fixed-time checks

Create a scheduled task with exact times when two daily summaries are enough.
Do not describe an 08:00/15:00 schedule as continuous CI or review monitoring.

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
