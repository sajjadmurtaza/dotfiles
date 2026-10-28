# Security

Apply for authn/authz, sessions, secrets, permissions; confidential, regulated, or multi-tenant data; external interfaces, webhooks, workers; logs, audits, exports; dependencies; agent skills, MCP servers, retrieved content, tool permissions; or compliance posture. Otherwise skip. Project security guidance layers on top.

For agent/tool surfaces, load [`security-agent-tools.md`](security-agent-tools.md).

## Method

1. Establish actors, assets, sensitivity, exposure, assumptions, and trust boundaries.
2. Trace entry points and changed controls: policies, validation, authorization, queries, logs, rate limits, retries, configuration, and tests.
3. Test abuse paths with STRIDE. Prefer least privilege, deny-by-default, object/tenant authorization, safe inputs and queries, data minimization/redaction, auditability, timeouts, and replay/rate controls.
4. Use only owned or authorized targets and test accounts. Prefer repository-native unit, request, policy, contract, and local integration checks. Do not install scanners or actively probe merely to finish review.
5. Make no exploitability or control claim without evidence. Record missing context as lower-confidence `Assumptions / Gaps`. Do not edit unless fixes are requested.

## Severity

- `Critical`: likely breach, auth bypass, secret leak, cross-tenant exposure, or regulated-data integrity loss.
- `Important`: evidenced exploitation/control gap, PII leak, replayable webhook, or ambiguous tenant boundary.
- `Nice-to-Have`: defense-in-depth without a concrete current failure.

## Control mapping (not legal advice)

Map only clearly applicable controls: `ISO 27001`, `BSI C5`; `NIS2`, `DORA`, `KRITIS`; `EU MDR`, `IEC 62304`, `ISO 13485`. Insufficient evidence → `Assessed: No` plus reason. State non-EU scope.

## Output

Fold severity-ordered findings into `finish`: `Severity`, `Category`, path:line `Evidence`, `Abuse path`, `Risk`, `Recommended fix`, applicable `Control tags`, `Confidence`.

Always report no-findings status plus 1–3 residual risks; `Assumptions / Gaps`; checks run versus not run; one-line relevant-framework coverage.

Compact path (≤2 files and no sensitive surface): threat context plus the always items only.
