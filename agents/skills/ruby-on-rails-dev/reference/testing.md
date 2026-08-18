# Rails testing

Use the repository's established framework. Minitest with fixtures and RSpec with factories are both valid; converting test stacks is separate scope.

## Select the lowest useful layer

| Change | Coverage |
| --- | --- |
| model rule/query | model test plus constraint/query evidence |
| HTML flow | integration/request; system only for critical browser behavior |
| JSON endpoint | request contract, invalid input, auth, compatibility |
| policy/scope | allowed, denied, and cross-tenant examples |
| job | idempotency/retry, missing record, side effects, enqueue timing |
| mailer | recipient, headers, body, enqueue/delivery boundary |
| migration/backfill | safety check and representative data verification |
| cache | key, invalidation, miss and hit behavior |

## Test quality

- Add a regression test that fails for the original bug.
- Prefer public outcomes, database state, jobs/events, and responses over private-method assertions.
- Do not duplicate Rails framework behavior or pin incidental SQL/order unless it is contractual.
- Keep factories/fixtures small and valid; avoid callback-heavy setup unrelated to the behavior.

## Execution

Run focused tests first, then the native full gate. Rails 8.1 applications may define a local CI DSL in `config/ci.rb` invoked by `bin/ci`; use it when present. Otherwise follow repository scripts.

Common candidates: `bin/rails test`, `bin/rails test:system`, `bundle exec rspec`, `bin/rubocop`, `bin/brakeman --no-pager`, `bundle exec bundler-audit check --update`.

Primary sources: [Testing Rails Applications](https://guides.rubyonrails.org/testing.html), [Rails 8.1 Release Notes](https://guides.rubyonrails.org/8_1_release_notes.html).
