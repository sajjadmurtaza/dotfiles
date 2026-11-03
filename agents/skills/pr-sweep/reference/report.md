# Report

Run `doctor`, then one `tick` with the explicit profile:

```sh
ruby <skill-dir>/scripts/attention doctor --profile PROFILE
ruby <skill-dir>/scripts/attention tick --profile PROFILE
```

Render only returned `items`: repository, PR number, kind, URL, and exact route.
Do not fetch PR bodies, comments, diffs, or CI logs in this branch. `quiet` means
no attention fingerprint changed since the previous scan; use `summary` only
when the user asks to see previously recorded items.

The helper classifies one primary attention type per PR:

1. conflicts;
2. failing CI;
3. changes requested;
4. review requested;
5. Dependabot review.

End with one recommended next item. Do not invoke its route automatically.
