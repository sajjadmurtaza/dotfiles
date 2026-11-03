# Wrap

Terminate the session-owned watcher using the host process/session mechanism;
do not read a stale PID and kill an unrelated process. Then run:

```sh
ruby <skill-dir>/scripts/attention summary --profile PROFILE
```

Report open, deferred, and completed items concisely. Confirm the watcher is no
longer active. Local configuration and ledger remain for the next session.
