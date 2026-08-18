# Database changes and queries

## Migrations

- Never edit a migration that may have run in a shared environment.
- Prefer additive expand-and-contract changes: add, dual-read/write if needed, backfill, switch, then remove later.
- Classify locks, table rewrites, and index cost before deployment.
- Follow the repository's migration-safety tooling; use concurrent indexes and phased constraint validation when the adapter requires them.
- Keep backfills restartable, observable, bounded, and compatible with old and new application versions.
- Avoid application callbacks in historical backfills; use explicit data logic whose behavior cannot drift unnoticed.

## Queries

- Bind values. Allowlist dynamic identifiers, ordering, and direction.
- Use `includes`, `preload`, or `eager_load` based on the actual query shape; verify query count afterward.
- Inspect an execution plan for important changed queries.
- Index foreign keys, frequent joins/filters, and uniqueness invariants when evidence supports it.
- Paginate user-facing collections and batch maintenance work.

## Transactions and locks

- Keep transactions short and free of external calls.
- Choose pessimistic or optimistic locking from the conflict model, not by default.
- Protect uniqueness in the database even when the model validates it.
- Document intentionally irreversible data changes and the forward-fix path.

Primary sources: [Active Record Migrations](https://guides.rubyonrails.org/active_record_migrations.html), [Active Record Query Interface](https://guides.rubyonrails.org/active_record_querying.html).
