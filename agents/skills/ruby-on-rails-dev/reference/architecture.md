# Rails architecture and KISS

Use Rails' conventions as the default architecture. Change the shape only when repository evidence or a real boundary earns it.

## Start with the application

- Confirm the locked Rails/Ruby versions and `config.load_defaults`.
- Trace one nearby feature from route to response and test before proposing a new pattern.
- Preserve the application's established HTML/API, authorization, job, and deployment choices.

## Ownership

- Controllers own HTTP input, authentication/authorization calls, orchestration, and responses.
- Models own cohesive domain state, invariants, relations, and queries.
- Jobs own retryable asynchronous orchestration, not a second copy of domain rules.
- Mailers format and deliver mail; callers decide when mail should happen.
- Policies/scopes own authorization when the repository already uses that boundary.
- Views/components own presentation. Stimulus owns small browser-only behavior.
- Plain Ruby objects are useful for a real workflow, integration boundary, parser, or calculation—not merely to shorten a model.

## KISS checks

1. Can a RESTful resource and an ordinary Ruby method solve this?
2. Is a new object naming a real concept or only moving lines?
3. Does the repository already own a suitable boundary?
4. Can an explicit call replace a hidden callback?
5. Is a gem solving a maintained hard problem rather than a few clear lines?
6. Will the next reader find the behavior where Rails convention suggests?

## Avoid Java-shaped Rails

- Do not create command/handler/factory/repository layers for every action.
- Do not wrap Active Record behind generic repositories without a proven portability boundary.
- Do not mirror every model with DTOs or interfaces inside one Ruby process.
- Do not replace Rails callbacks with event buses unless cross-boundary delivery semantics require them.
- Do not add dependency-injection containers for ordinary object construction.

Primary sources: [Rails Doctrine](https://rubyonrails.org/doctrine), [Rails Guides](https://guides.rubyonrails.org/).
