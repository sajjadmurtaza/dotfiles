# Monitor

First run the **report** branch. If the host supports a session-owned background
process whose output returns to the agent, start:

```sh
ruby <skill-dir>/scripts/attention watch --profile PROFILE
```

The watcher checks after three minutes, then uses ten-minute quiet intervals
after two unchanged scans. It emits `PR_SWEEP_WAKE` only for a changed attention
fingerprint. On wake, show the returned items and routes; do not execute them.

Keep the host's process/session identifier so **wrap** can terminate it. If the
host cannot reliably return background output, say so and remain on-demand.
Never detach the process or claim monitoring survives an agent/app restart.
