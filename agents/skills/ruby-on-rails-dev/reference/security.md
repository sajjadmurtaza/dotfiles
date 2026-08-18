# Rails security

Request the `$code-review` security lens when changing authentication, authorization, tenancy, sensitive data, sessions, secrets, exports, webhooks, SQL, uploads, external fetches, or privileged operations.

## Identity and access

- The Rails 8 authentication generator is a starting point for sessions/password reset, not a complete identity or authorization product.
- Authorize actions and objects on every path, including jobs, admin tools, exports, and broadcasts.
- Scope protected record lookup by the current account/tenant before loading it.
- Test denied and cross-tenant cases.

## Untrusted input

- Keep strong parameters explicit.
- Preserve CSRF protection for browser sessions; understand the API auth model before skipping it.
- Validate redirects, URLs, filenames, content types, archive paths, webhook signatures/timestamps, and serialized payloads.
- Bind SQL values and allowlist dynamic columns or sort directions.
- Protect server-side fetches from internal networks, redirects, and unbounded responses.

## Secrets and privacy

- Use Rails credentials or the deployment secret store; keep `.kamal/secrets` as references to environment values.
- Filter sensitive parameters and avoid logging tokens, cookies, passwords, personal data, or full third-party payloads.
- Set cookies, session expiry, transport security, CORS, and CSP from the actual threat model.
- Preserve auditability for admin, impersonation, export, and destructive actions.

Primary source: [Securing Rails Applications](https://guides.rubyonrails.org/security.html).
