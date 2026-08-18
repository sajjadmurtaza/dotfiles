# Rails deployment

Load this reference only when deployment or production topology is in scope. Preserve the application's existing platform unless migration is explicitly requested.

## Rails 8 defaults are conditional

- New Rails 8 applications may use Kamal, Thruster, Propshaft, Solid Queue, Solid Cache, and Solid Cable.
- Upgraded applications do not adopt those components automatically. Inspect `Gemfile.lock`, Dockerfile, `config/deploy.yml`, `config/database.yml`, and adapter config.
- A single database-backed Solid stack reduces services but still needs capacity, backup, retention, and failure-mode decisions.

## Kamal

- Keep secrets as environment references; never commit resolved values from `.kamal/secrets`.
- Confirm the locked Kamal major in `Gemfile.lock` and with `bundle exec kamal version`. For Kamal 2, use `proxy` and `proxy.healthcheck`; never copy Kamal 1 `traefik` or root-level `healthcheck` configuration.
- Verify SSH target, registry, builder architecture, roles, volumes, accessories, health check, and rollback path before deploy.
- `kamal setup` can install Docker remotely with root access and changes server state; require explicit operator intent.
- Use `kamal deploy` only after the production image is proven buildable and bootable and the `/up` health path represents readiness.
- Treat database migrations and destructive schema changes as a separate ordered rollout concern.

## Solid Queue, Thruster, and processes

- Choose deliberately between `SOLID_QUEUE_IN_PUMA` and a dedicated worker role running `bin/jobs`; confirm which process supervises web, jobs, and cable.
- Configure and prepare the queue database and schema before workers start, and use durable queue storage with an explicit backup and recovery plan.
- Check forwarded headers, SSL assumptions, asset serving, compression, and health probes at the real proxy boundary.
- Verify worker graceful shutdown and retry behavior during rolling deploys. Give long-running jobs resumable semantics; Rails 8.1 continuations may help when the app supports them.

## Proof

- Build the production image, boot it with production-like configuration, run the health check, and exercise a job plus persistent storage path.
- Record deploy order, rollback constraints, backup/restore expectations, and unverified infrastructure.

Primary sources: [Kamal installation](https://kamal-deploy.org/docs/installation/), [Kamal 2 configuration changes](https://kamal-deploy.org/docs/upgrading/configuration-changes/), [Active Job Basics](https://guides.rubyonrails.org/active_job_basics.html), [Rails 8.0 Release Notes](https://guides.rubyonrails.org/8_0_release_notes.html), [Rails 8.1 Release Notes](https://guides.rubyonrails.org/8_1_release_notes.html).
