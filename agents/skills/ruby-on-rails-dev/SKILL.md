---
name: ruby-on-rails-dev
description: >-
  Always load $dev first with $ruby-dev. Rails overlay for models, controllers,
  routes, views, Hotwire, APIs, jobs, mailers, policies, migrations, caching,
  security, performance, and tests. Use for changes inside a Rails application.
---

# Ruby on Rails Dev

**Stop:** read `$dev` Shared prep and load `$ruby-dev` before applying this overlay.

## Start with repository truth

- Read `AGENTS.md` and local instructions first.
- Inspect `Gemfile.lock`, `config/application.rb`, `config.load_defaults`, routes, nearby code, tests, `bin/`, and CI before proposing commands or framework APIs.
- Match the Rails and Ruby versions actually locked by the repository. Do not assume the newest Rails feature exists in an older application.
- Preserve the established test stack, frontend strategy, authorization library, job backend, serializer approach, and deployment workflow unless the user explicitly asks to change them.
- Load [`reference.md`](reference.md) for the relevant implementation, data, security, performance, or validation checklist.

## Rails-shaped KISS

- Prefer Rails conventions and the framework's integrated defaults. Add a gem, layer, callback, concern, or abstraction only when concrete repetition or a boundary earns it.
- Keep controllers focused on HTTP work: normalize permitted input, authenticate/authorize, invoke domain behavior, and choose a response.
- Put domain behavior at its closest cohesive owner. That may be an Active Record model, a small plain Ruby object, or an existing application layer; do not create service objects by reflex.
- Prefer RESTful resources and conventional routes. Version an API only when the repository already does or compatibility requirements demand it.
- Keep models cohesive. Avoid both controller-heavy logic and giant models that mix unrelated workflows.
- For HTML applications, prefer server-rendered Rails with Turbo and small Stimulus controllers when that matches the repository. Preserve React, Vue, or another established client instead of forcing a rewrite.
- Make public behavior easy to discover through clear names, small methods, and executable tests. Avoid metaprogramming when ordinary Ruby is clearer.

## Data and persistence

- Use database constraints and indexes for invariants that must survive every write path; pair them with useful model validation messages when appropriate.
- Keep migrations deployable: make additive changes first, backfill safely, switch readers/writers, then remove old structure in a later deploy when needed.
- Never edit a migration that may already have run in a shared environment. Use the repository's established migration-safety and backfill tools when present.
- Wrap multi-record invariants in transactions, while keeping external network calls outside long-running transactions.
- Prevent N+1 queries with evidence-led `includes`, `preload`, or `eager_load`; use `strict_loading` only where the repository can support it. Measure before adding caches or complex SQL.
- Bind SQL parameters. Avoid interpolating user-controlled values, dynamic column names, or sort clauses.

## Security and privacy

- Authenticate and authorize every access path, including jobs, admin endpoints, exports, webhooks, and indirect object lookups.
- Scope queries before loading records so unauthorized rows are not fetched and filtered afterward.
- Keep strong parameters explicit. Treat cookies, sessions, redirects, uploads, filenames, URLs, serialized payloads, and inbound webhook data as untrusted input.
- Preserve CSRF protection for browser flows and verify the repository's API authentication model before skipping it.
- Keep secrets in credentials or the deployment secret store. Do not log tokens, credentials, sensitive personal data, or full third-party payloads.
- Request a `$code-review` security lens when changes touch authentication, authorization, tenancy, sensitive data, secrets, exports, webhooks, raw SQL, file handling, external fetches, or privileged operations.

## Jobs, mailers, caching, and integrations

- Make jobs safe to retry. Use stable identifiers as arguments, re-load records inside the job, and design side effects to be idempotent.
- Account for transaction timing before enqueueing work that reads just-written data.
- Set retry/discard behavior deliberately and preserve useful failure context without leaking secrets.
- Give cache entries explicit identity and invalidation rules. Avoid caching before measurement shows value.
- Keep external APIs behind a narrow boundary with explicit timeouts, error mapping, and test seams. Follow existing adapters before adding a new pattern.

## Testing and validation

- Use the repository's framework: Minitest/fixtures are valid Rails defaults; RSpec/FactoryBot are equally valid when already established.
- Test behavior at the lowest level that gives confidence, then cover critical boundaries with request, integration, system, job, or mailer tests.
- Add regression coverage for bug fixes. Include authorization failures and tenant/account isolation whenever those boundaries can change.
- Avoid asserting private methods or duplicating framework behavior. Prefer observable outcomes, database state, emitted jobs/events, and rendered responses.
- Run focused tests first, then the repository's broader gate. Prefer `bin/ci` when the app defines it; otherwise use the existing test, lint, security, and dependency-audit commands.
- Use Docker only when the repository's documented workflow requires it. Do not force host-local or container execution against project convention.
- Regenerate OpenAPI or other API artifacts only when the repository owns them and through its documented source-of-truth command.

## Completion

Report:

- Rails layers and user-visible behavior changed.
- Database, background-job, cache, authorization, tenancy, and API compatibility effects.
- Commands run with honest pass/fail/skip results.
- Deployment order, rollback constraints, or unverified paths when relevant.
