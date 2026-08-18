# Hotwire, Turbo, and Stimulus

Use Hotwire when the repository is server-rendered or already Hotwire-based. Preserve an established client-side architecture instead of forcing a rewrite.

## Turbo

- Start with normal links and forms; add frames when a page region has an independent navigation boundary.
- Use streams for targeted updates that genuinely improve the interaction.
- Keep stable DOM IDs and render the same partial for initial HTML and stream updates.
- Return validation errors with the status expected by the application's Rails/Turbo version.
- Treat broadcast callbacks carefully: they hide work, can multiply queries, and may publish before surrounding workflows are understood.

## Stimulus

- Give each controller one small browser behavior.
- Declare targets, values, classes, and outlets rather than querying broad document state.
- Keep domain rules on the server; JavaScript may improve interaction but must not become the only authorization or validation layer.
- Disconnect observers and listeners created outside Stimulus lifecycle management.

## Progressive enhancement

- Preserve usable links/forms without JavaScript where practical.
- Keep focus, keyboard operation, loading state, and error announcements accessible.
- Use system tests for critical JavaScript behavior and lower-level tests for server responses.

Primary sources: [Turbo Handbook](https://turbo.hotwired.dev/handbook/introduction), [Stimulus Handbook](https://stimulus.hotwired.dev/handbook/introduction), [Working with JavaScript in Rails](https://guides.rubyonrails.org/working_with_javascript_in_rails.html).
