# Setup

Collect four local facts: profile name, expected GitHub login, allowed owner(s),
and a dedicated GitHub CLI configuration directory. An optional repository
allowlist narrows the profile further. Never request or store a token.

```sh
ruby <skill-dir>/scripts/attention setup \
  --profile PROFILE \
  --login EXPECTED_LOGIN \
  --owner OWNER \
  --repository OWNER/REPOSITORY \
  --gh-config-dir "$HOME/.config/gh-PROFILE"
```

Repeat `--owner` and `--repository` as needed. Omit `--repository` to include
authored PRs and review requests across the allowed owner. The helper creates
profile, state, and dedicated GitHub CLI directories as `0700`, and JSON files
as `0600`.

Authenticate that GitHub CLI directory separately outside this skill, then run:

```sh
ruby <skill-dir>/scripts/attention doctor --profile PROFILE
```

Stop on missing authentication, invalid permissions, or login mismatch.
