# Monitor

After **report**, choose wake bridge:

| Host | Reliable mode |
| --- | --- |
| Claude Code | Attached `watch`; re-arm on expiry |
| Codex Desktop | **schedule**; terminal cannot wake chat |
| Cursor | **report** unless wake is proven |

For a proven session wake bridge:

```sh
ruby <skill-dir>/scripts/attention watch --profile PROFILE
```

It checks after three minutes and backs off to ten. Changed attention or the
first distinct error emits `PR_SWEEP_WAKE`; retries recover. Never execute
routes. Keep the session ID for **wrap**; never detach. Claim automatic only
after an unprompted wake.
