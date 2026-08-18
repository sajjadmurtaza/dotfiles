# Rails review checklist

Use after focused tests pass. Report only relevant items; do not turn the checklist into boilerplate.

## Behavior and design

- The change follows nearby Rails conventions and adds no unearned layer, gem, callback, or metaprogramming.
- Controller, model, job, view, and integration ownership is clear.
- HTML/API compatibility and error behavior are deliberate.

## Data and operations

- Constraints, indexes, transactions, query count, and migration locks were considered where touched.
- Backfills are bounded, restartable, and compatible across the deploy window.
- Jobs are retry-safe; cache keys have explicit invalidation; broadcasts are scoped.
- Deployment order and rollback/forward-fix constraints are stated.

## Security

- Authentication, object/action authorization, and tenant scope cover every entry path.
- Input, redirects, SQL, uploads, external fetches, webhooks, logs, and secrets were checked where applicable.
- Denied and cross-boundary behavior has executable coverage.

## Validation

- Focused regression tests pass.
- Repository-native lint, security, dependency audit, and full test/`bin/ci` gate pass or have honest skip reasons.
- Generated schema/API/assets changed only through their source-of-truth command.
- The final handoff names user-visible behavior, touched Rails layers, data/job/cache/auth effects, commands run, and remaining risk.
