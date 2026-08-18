---
name: ruby-on-rails-dev
description: >-
  Always load $dev first with $ruby-dev. Rails overlay for models, controllers,
  routes, views, Hotwire, APIs, jobs, mailers, policies, migrations, caching,
  security, performance, and tests. Use for changes inside a Rails application.
---

# Ruby on Rails Dev

**Stop:** read `$dev` Shared prep and load `$ruby-dev` before applying this overlay.

## Route the change

Read only the references required by the touched surface:

| Surface | Reference |
| --- | --- |
| boundaries and KISS design | [`reference/architecture.md`](reference/architecture.md) |
| Active Record behavior | [`reference/models.md`](reference/models.md) |
| controllers, routes, APIs | [`reference/controllers.md`](reference/controllers.md) |
| Turbo and Stimulus | [`reference/hotwire.md`](reference/hotwire.md) |
| Active Job and Action Cable | [`reference/jobs.md`](reference/jobs.md) |
| migrations, queries, constraints | [`reference/database.md`](reference/database.md) |
| test selection and Rails 8.1 CI | [`reference/testing.md`](reference/testing.md) |
| auth, authorization, untrusted input | [`reference/security.md`](reference/security.md) |
| queries, caching, assets | [`reference/performance.md`](reference/performance.md) |
| Kamal, Thruster, Solid adapters | [`reference/deployment.md`](reference/deployment.md); for Solid Queue deployments also read [`reference/jobs.md`](reference/jobs.md) and [`reference/database.md`](reference/database.md) |
| final assurance | [`reference/review-checklist.md`](reference/review-checklist.md) |

## Establish repository truth

- Read `AGENTS.md`, `Gemfile.lock`, `config/application.rb`, `config.load_defaults`, routes, nearby code, tests, `bin/`, and CI.
- Match the locked Rails and Ruby versions. New Rails 8/8.1 capabilities are conditional, not upgrade assumptions.
- Preserve the repository's test stack, frontend strategy, authorization, queue/cache/cable adapters, schema format, and deployment path unless the request changes them.

## Apply Rails-shaped KISS

- Prefer Rails conventions and the framework's integrated defaults. Add a gem, layer, callback, concern, or abstraction only when concrete repetition or a boundary earns it.
- Prefer RESTful resources and conventional routes. Version an API only when the repository already does or compatibility requirements demand it.
- Put behavior at its closest cohesive owner. A model or ordinary Ruby method is often enough; a service object is not a default layer.
- Keep controllers about HTTP, jobs about asynchronous orchestration, and Stimulus controllers about browser behavior.
- Prefer explicit calls over callback chains and ordinary Ruby over metaprogramming.
- Preserve an established React/Vue client; otherwise prefer server-rendered HTML, Turbo, and small Stimulus controllers.

## Testing and validation

- Add focused behavioral coverage, including authorization/tenant boundaries when touched.
- Run focused tests first, then the repository's native full gate; prefer `bin/ci` when present.
- Do not claim a Rails API exists until the locked version or primary Rails documentation confirms it.
- Request `$code-review` with the security lens for auth, tenancy, secrets, exports, webhooks, raw SQL, uploads, external fetches, or privileged operations.

## Completion

Report:

- Rails layers and user-visible behavior changed.
- Database, background-job, cache, authorization, tenancy, and API compatibility effects.
- Commands run with honest pass/fail/skip results.
- Deployment order, rollback constraints, or unverified paths when relevant.
