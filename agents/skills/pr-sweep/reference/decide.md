# Decide

Record a decision only for an ID returned by `tick` or `summary`:

```sh
ruby <skill-dir>/scripts/attention decide \
  --profile PROFILE \
  --id ITEM_ID \
  --status acknowledged
```

Allowed statuses: `acknowledged`, `deferred`, `done`, `ignored`. A decision is
local state, not a GitHub action. If the PR fingerprint changes, the item becomes
new attention again.
