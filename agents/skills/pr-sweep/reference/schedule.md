# Schedule

Use in Codex Desktop after **report**. The task wakes the agent with one `tick`;
the ledger keeps unchanged results quiet. Never schedule long-lived `watch`.

Create one task per profile and IANA time zone. A ten-minute work heartbeat
catches changes; fixed times are snapshots.

Use this prompt:

```text
Use $pr-sweep for profile PROFILE. Run doctor and exactly one read-only tick.
If quiet, do not notify me. If attention changed, write a short private brief:
one natural line per PR with link, verified reason, and exact route. Avoid raw
JSON and canned wording. Never execute a route or edit code, rerun CI, deploy,
push, comment, reply, resolve, approve, or merge.
If authentication, network access, or the profile is unavailable, report the
specific blocker once and stop.
```

Verify profile, time zone, cadence, project, and first run. Call it automatic
only after quiet and changed-fingerprint runs reach Scheduled.
