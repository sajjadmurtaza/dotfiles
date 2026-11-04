# Local Security Tools

Use for an explicit local scan or scanner recommendation. Scanners produce
leads, not verified vulnerabilities.

## Admission

1. Read repository instructions and existing CI/config first. Prefer its pinned
   command and ignore policy; do not duplicate a working gate.
2. Start with the changed surface. A full-history, full-tree, image, or active
   endpoint scan needs explicit scope and may expose confidential data.
3. Do not install software, download rules/databases, enable telemetry, upload
   source/results, or probe a service without approval. Never use `curl | sh`.
4. Pin version and provenance. Put reports in a private temporary directory,
   redact secret values, and keep generated reports out of commits.
5. Record tool/version, command, scope, network use, result, triage evidence,
   false positives, and unscanned gaps. Never auto-fix scanner output.

## Choose the smallest missing layer

| Need | Prefer | Boundary |
| --- | --- | --- |
| Rails source risks | Repository-configured Brakeman | Reuse only when employer/project licensing permits it. |
| Ruby gems | Repository-configured `bundler-audit` or `ruby-audit` | Update advisory data only with network approval. |
| Multi-language SAST | Opengrep with reviewed, versioned local rules | Do not fetch an unreviewed remote ruleset. Semgrep CE is an alternative, not a second default scanner. |
| Secrets | Gitleaks CLI | `dir` scans files; `git` scans history. Redact findings and rotate a real exposed secret. The hosted Action has different licensing. |
| Dependencies/SBOM | OSV-Scanner | Skip when the repository already has equivalent ecosystem coverage. Call analysis may execute builds. |
| Images, IaC, filesystem | Trivy | Reuse repository severity, ignore, and database policy. |

Do not stack every tool. SAST, dependency, secret, and image scanners answer
different questions; select only the uncovered risk.

## Output

Fold confirmed findings into the security ledger. Separate scanner alerts from
verified defects, state what existing repository gates already cover, and name
the smallest additional check only when a material gap remains.
