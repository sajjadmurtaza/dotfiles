# Debt Reference

Log and maintain architectural friction, structural rot, and technical debt in `.agents/debt-ledger.md`.

## Purpose

When a session uncovers technical debt, leaky boundaries, unmeasured hot paths, or dead compatibility shims that cannot be fixed within the current task's scope, do not bury them in ephemeral chat. Log them into `.agents/debt-ledger.md` so they are visible to `orchestrator`, `triage`, `product-owner`, and `$dev`.

## Ledger Location

- File: `<project>/.agents/debt-ledger.md` (project root)
- If `.agents/` directory does not exist in the project, create it.

## Debt Entry Schema

Each item logged in `.agents/debt-ledger.md` follows this standard shape:

```markdown
### [DEBT-<NUMBER>] <Short Imperative Title>

- **Category:** `boundary` | `types` | `perf` | `legacy` | `test`
- **Friction:** Concise description of the friction, leak, or smell encountered.
- **Affected Files:**
  - `path/to/module.ext`
- **Remediation Route:** matching craft branch (e.g. `architecture deep-modules`, `architecture refactor-types`, `code-review quality`)
- **Golden Path Impact:** How this debt slows down developer velocity, adds runtime latency, or increases defect risk.
- **Status:** `open` | `admitted` | `resolved`
```

## Categories

| Category   | Typical Signal                                                         | Remediation Route                                    |
| :--------- | :--------------------------------------------------------------------- | :--------------------------------------------------- |
| `boundary` | Leaky module seams, circular imports, god objects, multi-table queries | `architecture deep-modules` or `refactor-boundaries` |
| `types`    | Primitive obsession, stringly-typed IDs, unsafe JSON bags              | `architecture refactor-types`                        |
| `perf`     | Unmeasured hot paths, N+1 queries, runaway allocations                 | `architecture performance`                           |
| `legacy`   | Superseded models, deprecated APIs, dead compatibility shims           | `code-review quality` (legacy lens)                   |
| `test`     | Flaky tests, missing integration seams, testing implementation details | `code-review quality` (tests lens)                    |

## Governance Ingress

1. **Emit:** Append new items to `.agents/debt-ledger.md` with status `open`.
2. **Prioritize:** `product-owner` consults this file when reviewing roadmap capacity.
3. **Admit:** Apply the repository's documented prioritization policy. If none exists, ask rather than inventing a capacity budget.
4. **Resolve:** When an admitted tranche is delivered by `$dev` and passes Assure, update status to `resolved` with commit SHA. When a commit or pull request references `Resolves: DEBT-<NUMBER>` or `Fixes [DEBT-<NUMBER>]`, `orchestrator run` and `pull-request resolve` automatically reconcile `<project>/.agents/debt-ledger.md`: find the matching entry, set **Status** to `resolved`, and record the associated commit hash. Halt only if the reference is ambiguous or no matching ledger entry exists; do not ask for a manual ledger edit.
