# Controllers, routes, and APIs

## HTTP boundary

- Prefer RESTful resources and shallow routes. Model a state change as a resource when it does not fit CRUD cleanly.
- Authenticate first. Scope protected lookups before `find`, then authorize the loaded record and action before mutation or response.
- Never load a global record and filter it afterward.
- Normalize and permit input explicitly. Keep response selection and status codes visible.
- Redirect only to trusted locations and validate return URLs.

## HTML responses

- Prefer server-rendered HTML when the application is Rails-native.
- Use `respond_to` only when one action genuinely supports multiple maintained representations.
- Keep helpers and presenters focused on formatting; domain decisions remain with their owner.

## JSON APIs

- Preserve the repository's serializer and error-envelope conventions.
- Version only when compatibility requirements demand it.
- Treat response fields, status codes, pagination, and error shapes as contracts.
- Bound page sizes and filters. Allowlist sort columns and directions rather than interpolating input.
- Regenerate OpenAPI artifacts only through the repository's source-of-truth command.

## Tests

- Cover success, invalid input, unauthenticated, unauthorized, and cross-tenant paths as applicable.
- Assert observable response and persistence behavior, not controller internals.

Primary sources: [Action Controller Overview](https://guides.rubyonrails.org/action_controller_overview.html), [Rails Routing](https://guides.rubyonrails.org/routing.html).
