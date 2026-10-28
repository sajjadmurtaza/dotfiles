# Agent skills

Portable product and engineering workflows for Codex, Claude Code, and Cursor. The Build entry is `dev`; specialized language and framework skills load only when relevant. Vocabulary: [`CONTEXT.md`](CONTEXT.md).

## Install

```sh
npx skills add ./agents/skills \
  -g --copy \
  -a codex -a claude-code -a cursor \
  -y
```

Run from the dotfiles repository root. Requires Node.js. Verify with `npx skills list -g`; browse with `npx skills add ./agents/skills --list`. Install globally once per machine. Open a new agent session after installation.

## Domain map

| Domain       | Job                     | Skill(s)                                                                                                                                                                                                                    | Primary branches                                                                                                                              |
| ------------ | ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| **Intent**   | Fuzzy need → work       | [`triage`](triage/), [`jira-ticket`](jira-ticket/), [`pr-sweep`](pr-sweep/)                                                                                                                                                  | `triage` `intake` (+ playbooks); `pr-sweep` `report`                                                                                          |
| **Operate**  | Service health review   | [`ops-chore`](ops-chore/)                                                                                                                                                                                                    | `quick` \| `post-deploy` \| `full`; read-only by default                                                                                      |
| **Product**  | Admit/defer scope       | [`product-owner`](product-owner/)                                                                                                                                                                                           | `gate` (default); `story-slice`; `rebaseline`; `groom`; stubs: `prioritize`, `experiment`                                                     |
| **Solution** | How the system works    | [`architecture`](architecture/); [`docs`](docs/) `architecture` (verify-only) · `evidence`; `dev` `plan`                                                                                                                    | `philosophy` \| `deep-modules` \| `refactor-types` \| `refactor-boundaries` \| `performance` \| `design-patterns`; survey: `structure-survey` |
| **Build**    | Change the codebase     | [`dev`](dev/); adapters [`ruby-dev`](ruby-dev/), [`rust-dev`](rust-dev/), [`swift-dev`](swift-dev/), [`typescript-dev`](typescript-dev/); overlays [`ruby-on-rails-dev`](ruby-on-rails-dev/), [`swiftui-dev`](swiftui-dev/) | `plan` \| `implement`; classify: surgical \| design \| review-hand-off                                                                        |
| **Assure**   | Safe to merge?          | [`code-review`](code-review/)                                                                                                                                                                                                 | `findings`, `publish`, `quality` (lenses: tests, perf, security, legacy)                                                                      |
| **Ship**     | Land on mainline        | [`pull-request`](pull-request/), [`dependabot`](dependabot/), [`release`](release/)                                                                                                                                         | PR: open, slice, retitle, comment, reply, resolve, fix-ci, conflicts (+ unblock); Dependabot: configure \| triage; release: `notes`           |
| **Explain**  | Humans understand state | [`communication`](communication/), [`docs`](docs/)                                                                                                                                                                          | see skill branches                                                                                                                            |
| **Decide**   | Stress-test choices     | `grilling` (third-party); `product-owner` Forced Challenge                                                                                                                                                                  | —                                                                                                                                             |
| **Harvest**  | Learning & debt loop    | [`harvest`](harvest/)                                                                                                                                                                                                       | `distill` (default); `debt`                                                                                                                   |

## Optional packs (not OS SoT)

Third-party; not in the store install.

```sh
npx skills add https://github.com/mattpocock/skills --skill grilling -g -a cursor -a codex -y && \
npx skills add https://github.com/twostraws/swiftui-agent-skill --skill swiftui-pro -g -a cursor -a codex -y && \
npx skills add https://github.com/twostraws/swift-testing-agent-skill --skill swift-testing-pro -g -a cursor -a codex -y && \
npx skills add https://github.com/arjitj2/swiftui-design-principles --skill swiftui-design-principles -g -a cursor -a codex -y
```

| Pack                        | Role                                                      |
| --------------------------- | --------------------------------------------------------- |
| `grilling`                  | Decide stress-test                                        |
| `swiftui-pro`               | SwiftUI review depth — compose via `$dev` + `swiftui-dev` |
| `swift-testing-pro`         | Swift Testing depth — compose via `$dev` + `swift-dev`    |
| `swiftui-design-principles` | Spacing/typography/materials — via `$dev` + `swiftui-dev` |

More: [skills.sh](https://skills.sh/), [Swift-Agent-Skills](https://github.com/twostraws/Swift-Agent-Skills).

> [!WARNING]
> A directory listing, star count, or install count is discovery evidence—not a
> security review. Before adding any third-party skill or MCP server, inspect its
> source, scripts, install hooks, permissions, network behavior, credential access,
> license, revision, and update path. Prefer a pinned, narrow capability and test it
> with least privilege. Never bulk-install a collection merely because it is popular.

## Compose / handoffs

Build path: `$dev` ⇄ `architecture` → `code-review` → `pull-request`. `$dev` is the only Build entry. Runtime contracts live in skills and [`CONTEXT.md`](CONTEXT.md).

1. **Product before non-trivial scope** — feature / `jira-ticket` → `product-owner` `gate` → `$dev plan`. Multi-slice / UX-mandated AC → `story-slice` → `$dev plan`. Skip gate for bug fix / refactor / infra. Incident without Jira → `triage` first.
2. **Craft ≠ product** — `architecture` / `dev` / `*-dev` / `code-review` never answer "should we build X?".
3. **Build entry is `$dev`** — classify / route there; axioms on every `implement`; `{lang}-dev` from touched-file evidence.
4. **Plans → `$dev` `plan`** — each todo names files, one gate, Conventional Commit message; execute via [`dev/reference/phase-commits.md`](dev/reference/phase-commits.md).
5. **Assure → Ship** — `findings` never posts; `publish` in `code-review`; verified ledger → `pull-request` `comment`. Delivery Ledger: `dev/SKILL.md` Handoff.
6. **Explain → docs** — `communication` → `docs` `editor`; never reverse.
7. **Overlays via `$dev`** — `ruby-on-rails-dev` with `ruby-dev`; `swiftui-dev` with `swift-dev`.
8. **Decide** — `grilling` stress-tests; scope doctrine with `product-owner`.
9. **Sweep never fixes** — `pr-sweep` rows → `pull-request` / `dependabot` / `code-review`.
10. **Unblock chain** — `pull-request`: conflicts → resolve → fix-ci; never approve/merge.
11. **Harvest loop** — `code-review` / `pull-request` → `harvest` → rules or `.agents/debt-ledger.md` → `product-owner` Health Capacity Budget.

## Authoring laws

- **One router per domain**; branches are verb-paths with progressive load.
- **Freeze the router** — harvest via staging → sparse-promote into `reference/<branch>.md`; edit `SKILL.md` only when the contract is wrong.
- **Thin `*-dev`** — craft in `architecture`; classify / validation / phase commits in `$dev`; overlays are deltas only.
- **Proliferation guard** — new top-level skill only if it cannot be a branch of an existing router. Runtime route table stays in `dev/SKILL.md`.
- **Zero backward compat** — delete superseded aliases, old execution names, and dual shims on cutover.
- **Tokens are the currency** — single ownership, bounded Markdown DTOs for handoffs, no intermediate prompt layers.
- **Invocation** — new skills default to `disable-model-invocation: true` unless they are an ambient router.

Router shape: `## Pick branch` → `## Shared prep` (omit when empty) → `## Branch reference` → `## Handoff` → `## Completion criteria`; relative `reference/*.md` links; unnumbered `##` headers. Spec: [agentskills.io](https://agentskills.io/). Repo-only notes: [`skill/authoring/`](../../skill/authoring/) — never cite from installed skill routers.

## Operate the store

Git-tracked `agents/skills/<name>/` is the source of truth. Reinstall the complete store after local edits or when a new skill is added:

```sh
npx skills add ./agents/skills -g --copy -a codex -a claude-code -a cursor -y
```

| Command                    | Role                                                                  |
| -------------------------- | --------------------------------------------------------------------- |
| `skill list`               | List non-hidden store skills                                          |
| `skill doctor`             | Report `ok` / `drift` / `home-only` / `broken` / `orphan`             |
| `skill lint`               | Word ratchet, 100-line cap, router shape, link graph, duplicates      |
| `skill prune`              | Remove orphan store links whose source is gone                        |
| `skill backfill <name>`    | Copy drifted real files from `~/.agents/skills/<name>` into the store |
| `skill promote <name>`     | Move `<project>/.agents/skills/<name>` into the store                 |
| `skill rename <old> <new>` | Rename in the store                                                   |
| `npx skills add …`         | Install store skills into `~/.agents/skills`                          |

`drift` → decide which copy is authoritative before backfill or reinstall. `orphan` → `skill prune`. Project drafts live at `<repo>/.agents/skills/<name>/`.
