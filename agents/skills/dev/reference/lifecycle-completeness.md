# Lifecycle completeness

Load when persisted data is added, renamed, copied, retained, exported, archived,
redacted, anonymized, restored, migrated, or deleted; or when one fact crosses
multiple phases or workers.

## Before implementation

1. Find the policy owner and canonical schema. Search all writers, readers,
   serializers, jobs, callbacks, exports, audit/log paths, and cleanup stages.
2. Build a compact matrix for every affected field or data class:

   | Data | Phase | Required action | Owner/path | Proof |
   | --- | --- | --- | --- | --- |
   | field/class | create, cleanup, restore, export | keep, redact, null, delete, reject | exact owner | test/evidence |

3. Classify unknown cells before coding. A blank cell is an unresolved policy,
   not permission to preserve or delete data.
4. Include associations, JSON/blob payloads, derived copies, search indexes,
   caches, files, analytics, notifications, logs, backups, and external systems
   when the repository or ticket puts them in scope.
5. Record historical rows, nullability, partial progress, retry/idempotency,
   ordering, rollback/containment, and legal/audit retention constraints.

## Design posture

- One policy fact has one owner. Phase executors consume that policy instead of
  maintaining accidental twin field lists.
- Consolidate only when it creates clear ownership. Do not invent a framework
  for one local branch or hide materially different phase rules.
- Characterize current behavior before refactoring. Separate policy changes
  from structural cleanup when that keeps review and rollback safer.
- Treat irreversible deletion and privacy-sensitive retention as design work;
  co-load the security lens and repository-specific compliance guidance.

## Verification

- Add phase-specific positive and negative behavior tests.
- Add a schema/contract tripwire when feasible: a relevant new field must fail a
  test until it is explicitly classified. Avoid fragile inventories of every
  database column; scope the tripwire to the owned sensitive-data contract.
- Prove retries and repeated execution are safe, including partial failure
  between phases.
- Verify both removal and intentional retention. A passing happy path does not
  prove that sensitive copies disappeared or required evidence survived.
- Re-run the matrix against the final diff and report every unverified external
  surface or policy decision as a residual risk.

## Handoff

Include the matrix (or its durable repository source), changed policy owner,
phase tests, completeness-tripwire result, and unresolved lifecycle surfaces in
the Delivery Ledger. Do not claim lifecycle completeness from green unit tests
alone.
