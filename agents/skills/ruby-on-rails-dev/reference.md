# Rails implementation reference

Load only the sections relevant to the change. Repository conventions and locked framework versions take precedence.

## First inspection

- `Gemfile`, `Gemfile.lock`, `.ruby-version`, `mise.toml`, or `.tool-versions`
- `config/application.rb` and `config.load_defaults`
- `config/routes.rb`, relevant engines, and route constraints
- Nearby models, controllers, views/components, jobs, policies, serializers, and tests
- `bin/ci`, `bin/rails`, `bin/rubocop`, `Makefile`, container files, and CI workflows
- Schema format, migration-safety gems, database extensions, and deployment docs

## KISS decision checks

Before adding structure, ask:

1. Can a conventional Rails resource and ordinary Ruby method solve this clearly?
2. Is the new object owning a real concept or only moving lines out of a model/controller?
3. Does the repository already have a suitable boundary?
4. Can a callback be replaced by an explicit call in the workflow that owns the behavior?
5. Is a gem solving a maintained, difficult problem, or replacing a few clear lines of application code?
6. Will a future reader find the behavior where Rails convention suggests looking?

## Data-change checklist

- Decide whether the change is metadata-only, blocking, or likely to rewrite a large table.
- Add indexes concurrently and constraints in validation phases when the database/tooling requires it.
- Use an expand-and-contract sequence for renames, type changes, and destructive schema work.
- Make backfills restartable, observable, bounded, and safe alongside both old and new application versions.
- Keep model callbacks out of historical backfills when application behavior could drift; prefer explicit data logic.
- Verify rollback semantics. Some data changes are intentionally irreversible and need a forward-fix plan instead.

## Query and performance checklist

- Confirm the query count and shape before changing eager loading.
- Choose `includes`, `preload`, or `eager_load` based on whether joined conditions are required.
- Inspect query plans for important or changed queries.
- Index foreign keys, frequent filters, joins, and uniqueness invariants where evidence supports them.
- Avoid unbounded loads and Ruby-side filtering of database-sized collections.
- Paginate user-facing collections and batch maintenance work.
- Measure cache hit rate, invalidation complexity, memory, and serialization cost before retaining a cache.

## Security checklist

- Authentication and session/cookie settings
- Object-level and action-level authorization
- Tenant/account scoping and cross-boundary tests
- CSRF, CORS, redirects, and return URLs
- SQL, search, ordering, and filter inputs
- File uploads, content types, filenames, archive extraction, and download authorization
- Server-side requests, webhooks, signatures, replay protection, and timeouts
- Secrets, log filtering, error payloads, exports, and data retention
- Admin/impersonation/audit paths and background-job authorization context

## Test selection

| Change | Useful coverage |
| --- | --- |
| Model rule or query | Model/unit test plus database constraint/query evidence |
| HTML flow | Integration/request test; system test for critical JavaScript interaction |
| JSON/API endpoint | Request/integration contract, auth failures, invalid input, and compatibility |
| Policy or scope | Allowed, denied, and cross-account/tenant examples |
| Job | Retry/idempotency, missing record, side effects, and enqueue timing |
| Mailer | Recipient, headers, relevant body content, and enqueue/delivery boundary |
| Migration/backfill | Migration safety checks and representative data verification |
| Cache | Key composition, invalidation, and uncached/cached behavior |

## Version-aware Rails capabilities

Use these only after confirming the application supports and wants them:

- Rails 8 defaults may include Propshaft, import maps, Solid Queue, Solid Cache, Solid Cable, and Kamal-oriented deployment.
- Rails 8 authentication generators provide a foundation, not a complete authorization or identity product.
- Rails 8.1 adds Active Job continuations, structured application events through `Rails.event`, and a generated local `bin/ci` workflow.
- An upgraded application does not automatically adopt every new default. Check configuration and generated files instead of assuming.

## Common validation commands

Choose repository-native commands; do not run every example blindly.

```sh
bin/ci
bin/rails test
bin/rails test:system
bundle exec rspec
bin/rubocop
bin/brakeman --no-pager
bundle exec bundler-audit check --update
```

## Primary sources

- [Rails Doctrine](https://rubyonrails.org/doctrine)
- [Ruby on Rails Guides](https://guides.rubyonrails.org/)
- [Getting Started with Rails](https://guides.rubyonrails.org/getting_started.html)
- [Testing Rails Applications](https://guides.rubyonrails.org/testing.html)
- [Active Record Query Interface](https://guides.rubyonrails.org/active_record_querying.html)
- [Securing Rails Applications](https://guides.rubyonrails.org/security.html)
- [Rails 8.1 Release Notes](https://guides.rubyonrails.org/8_1_release_notes.html)
- [RuboCop Rails](https://github.com/rubocop/rubocop-rails)
- [Ruby Style Guide](https://github.com/rubocop/ruby-style-guide)
