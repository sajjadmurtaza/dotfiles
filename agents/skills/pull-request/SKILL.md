---
name: pull-request
description: >
  Pull-request GitHub lifecycle. Use when the user wants to open a pull request,
  slice one branch into smaller pull requests, update PR title or description,
  post an already-verified finding ledger, resolve review feedback, repair failed
  CI, resolve merge conflicts, unblock a PR, or reply on existing review threads.
---

# Pull Request

GitHub pull request lifecycle on a remote PR or branch destined to become one.

## Pick branch

Map the user prompt to exactly one branch:

| User intent                                                  | Branch      |
| ------------------------------------------------------------ | ----------- |
| Commit session work, push, create PR                         | **open**    |
| Split one branch into smaller PRs                            | **slice**   |
| Update PR title and/or description (no code)                 | **retitle** |
| Submit already-verified findings on a PR                     | **comment** |
| Fix review feedback end-to-end (assess, code, push, resolve) | **resolve** |
| Respond on existing threads only — no new findings, no code  | **reply**   |
| Diagnose and fix failing GitHub Actions checks               | **fix-ci**  |
| Resolve merge conflicts without changing feature intent      | **conflicts** |
| Clear all current PR blockers in dependency order            | **unblock** |

Ambiguous routing:

| User says                                                                                                             | Branch                                         |
| --------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| "address PR comments", "fix review feedback", "resolve comments"                                                      | **resolve**                                    |
| "reply to comments", "respond on GitHub", "draft replies" (existing threads only)                                     | **reply**                                      |
| "post these already-verified findings"                                                                                | **comment** (submit `COMMENT`)                 |
| "add these as pending/draft comments" (verified list)                                                                 | **comment** (remain pending)                   |
| "open a PR", "commit and create PR"                                                                                   | **open**                                       |
| "split into PRs", "slice branch"                                                                                      | **slice**                                      |
| "update title", "update description", "update PR title/desc", "refresh PR summary", "/pull-request update title+desc" | **retitle**                                    |
| "update the PR" (no code change and no review-feedback ask)                                                           | **retitle**                                    |
| "fix CI", "repair checks", "red build"                                                                             | **fix-ci**                                     |
| "resolve conflicts", "update branch after conflicts"                                                                | **conflicts**                                  |
| "unblock", "make merge-ready", several blocker types                                                                | **unblock** — conflicts → resolve → fix-ci     |
| "review the PR"                                                                                                       | stop — use the **code-review** skill            |
| "draft a review" (read-only findings)                                                                                 | stop — use **code-review** `findings`           |
| "post review comments", "new findings on PR", "review and post on GitHub"                                             | stop — use **code-review** `publish`            |
| "draft/pending a new review" (no supplied ledger)                                                                     | stop — use **code-review** `publish` draft-only |
| "publish review to PR" / end-to-end review+publish                                                                    | stop — use **code-review** skill `publish`      |

**comment** vs **reply**: **comment** posts already-verified findings supplied by the user or another workflow. End-to-end retrieve → review → reconcile → publish belongs to **`code-review` `publish`**, not this skill. **reply** answers an existing thread and must not add new findings or code changes.

Default ambiguous "address comments" → **resolve**, not **reply**. Ambiguous "update the PR" with no code/feedback → **retitle**, not **open**.

## Shared contract

- Required tools: `git`, `gh`, `jq`.
- Use non-interactive commands and explicit flags.
- Escalate network permissions for `gh` when sandboxing blocks GitHub API calls.
- Resolve bundled script paths relative to this skill directory, not the repo working directory.
- Prefer `./scripts/gh-review-comments --filter unresolved --format json <pr-url>` for structured thread data on **resolve** and **reply**.
- Do not ask the user to manually fetch PR or review-comment data unless automated discovery fails.
- When **comment** submits, use GitHub `event: COMMENT` only; never submit `APPROVE` or `REQUEST_CHANGES`. Pending/draft language means no `event` and no submission.
- Title/body narrative for **open** and **retitle** follows [`reference/pr-narrative.md`](reference/pr-narrative.md).

## Context pointers

Load only the matched branch reference:

- **open** — follow [`reference/open.md`](reference/open.md) until `gh pr view` confirms a PR (or browser flow confirmed created). Prefill title/body per [`reference/pr-narrative.md`](reference/pr-narrative.md).
- **slice** — follow [`reference/slice.md`](reference/slice.md). Do not start open or resolve until the slice ledger marks that PR ready.
- **retitle** — follow [`reference/retitle.md`](reference/retitle.md); load [`reference/pr-narrative.md`](reference/pr-narrative.md) for title/body.
- **comment** — follow [`reference/comment.md`](reference/comment.md). Load [`reference/gh-api.md`](reference/gh-api.md) when posting.
- **resolve** — follow [`reference/resolve.md`](reference/resolve.md). Load [`reference/gh-api.md`](reference/gh-api.md) when resolving threads.
- **reply** — follow [`reference/reply.md`](reference/reply.md). Load [`reference/gh-api.md`](reference/gh-api.md) when posting replies.
- **fix-ci** — follow [`reference/fix-ci.md`](reference/fix-ci.md).
- **conflicts** — follow [`reference/conflicts.md`](reference/conflicts.md).
- **unblock** — refresh live PR state before each step and run only the required branches in this order: **conflicts → resolve → fix-ci**. Never approve or merge automatically.

## Handoff

- Read-only or end-to-end PR review → the `code-review` skill; it asks whether to publish before reviewing.
- Posting a supplied, already-verified ledger stays in **comment**.
- Resolving or replying to existing feedback stays in this skill.
- Narrative-only PR updates stay in **retitle**.
- Multi-blocker requests stay in **unblock**; refresh state between branches instead of applying a stale checklist.

## Completion criteria

| Branch      | Done when                                                                                                                                                            |
| ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **open**    | Session-touched commits pushed; `gh pr view` shows a PR (or browser flow confirmed created); ticket in title when branch encodes one; body matches `pr-narrative.md` |
| **slice**   | Every planned slice has ledger row: branch, commits, validation result, PR URL or explicit deferred; worktrees cleaned only after user ok                            |
| **retitle** | `gh pr edit` applied; `gh pr view` shows updated title + body; narrative rebuilt from full `base...HEAD`; Review map obeys size gates and tests-first ordering       |
| **comment** | Every finding verified against PR head SHA + diff line; pending/submitted state matches user ask; landed comments verified via API                                   |
| **resolve** | Every unresolved thread assessed; valid ones fixed+pushed; resolved threads cite commit hash or left open with reason                                                |
| **reply**   | Every requested thread has a reply; no new inline findings; no code changes                                                                                          |
| **fix-ci**  | Failed checks explained from focused logs; authorized fixes validated and pushed, or the external blocker is reported clearly                                      |
| **conflicts** | Conflicts resolved with feature intent preserved; repository gates pass; updated branch pushed when requested                                                       |
| **unblock** | Current blockers cleared in conflicts → resolve → fix-ci order; final live state reported; no automatic approval or merge                                             |
