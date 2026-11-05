# Report

Run `doctor`, then one `tick` with the explicit profile:

```sh
ruby <skill-dir>/scripts/attention doctor --profile PROFILE
ruby <skill-dir>/scripts/attention tick --profile PROFILE
```

Turn returned `items` into a short private operator brief—never raw JSON. For
each item use one natural line: linked repository/PR, verified reason, and exact
route. Avoid canned openings, repeated closings, urgency theatre, and claims of
work not performed. Do not fetch bodies, comments, diffs, or CI logs. `quiet`
means no fingerprint changed; use `summary` only for recorded items.

Engine order is deterministic: conflicts, failing CI, and review feedback are
`now`; review requests are `soon`; Dependabot reviews are `batch`.

End with one recommended next item. Do not invoke its route automatically.
