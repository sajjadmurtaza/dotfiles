# Jobs, mailers, and Action Cable

## Active Job

- Pass stable identifiers and primitive arguments; reload current records inside `perform`.
- Make side effects idempotent or record an idempotency key before retryable delivery.
- Choose retry/discard behavior from the failure semantics. Preserve useful context without sensitive payloads.
- Account for transaction timing before a job reads just-written data.
- Bound fan-out and batch large collections.
- Use Rails 8.1 continuations only after confirming the locked version and when resumable steps materially reduce repeated work.

## Mailers

- Keep recipient selection and delivery timing visible at the call site.
- Test recipient, subject, relevant body content, and enqueue/delivery boundary.
- Avoid secrets or sensitive personal data in subjects and logs.

## Action Cable / Solid Cable

- Authenticate the connection and authorize every stream.
- Use stable, scoped stream names; do not expose tenant or record data through guessable global broadcasts.
- Keep cable messages small and treat them as untrusted client input on receipt.
- Confirm whether the app uses Solid Cable, Redis, or another adapter before changing topology.

Primary sources: [Active Job Basics](https://guides.rubyonrails.org/active_job_basics.html), [Action Mailer Basics](https://guides.rubyonrails.org/action_mailer_basics.html), [Action Cable Overview](https://guides.rubyonrails.org/action_cable_overview.html), [Rails 8.1 Release Notes](https://guides.rubyonrails.org/8_1_release_notes.html).
