# Security Scan Scope and Report

Load after `security-tools.md` for a full repository, Git-history scan, or HTML
report.

## Inputs

| Field | Values |
| --- | --- |
| `REPOSITORY_PATH` | Absolute path or `CURRENT_WORKSPACE` |
| `REPOSITORY_WEB_URL` | GitHub repository home URL, without an extra path |
| `SECURITY_SCOPE` | `FULL_REPOSITORY` or `GIT_HISTORY` |
| `ANALYSIS_DEPTH` | `STANDARD` or `DEEP_SAST` |
| `SAST_ENGINE` | `AUTO`, `SEMGREP_CE`, or a repository-approved equivalent |
| `HISTORY_SCAN` | `NO` unless `SECURITY_SCOPE` is `GIT_HISTORY` |
| `OUTPUT` | `CHAT` or `SANITIZED_HTML` |
| `REPORT_DIRECTORY` | `AUTO_PRIVATE_TEMP` unless an approved path is supplied |

`FULL_REPOSITORY` means the tracked tree, not Git history. Respect ignores and
explain excluded generated/vendor surfaces. History scanning can uncover old
live credentials and requires `HISTORY_SCAN: YES` plus separate approval.

`STANDARD` reuses repository checks. `DEEP_SAST` adds an approved code-aware
engine and reviewed rules. Framework or secret scans alone are not comprehensive.

## Approval gate

Before scanning, confirm the Git root, head SHA, dirty state, applicable
instructions, existing security gates, installed tool versions, exact commands,
network/download/telemetry behavior, expected runtime, exclusions, and report
path. Stop for `APPROVE SECURITY SCAN`; use `APPROVE SECURITY HISTORY SCAN` for
history.

Approval covers only the stated read-only commands. It does not authorize tool
installation, database/rule updates, active endpoint probing, uploads, ignore
changes, fixes, commits, or external publication.

## Sanitized HTML

Create one offline `report.html` in a private temporary directory. Use embedded
CSS only: no CDN, remote font, script, tracker, or network asset. Ordinary
evidence links to the repository are allowed. Include:

- repository, head SHA, time, scope, exclusions, and dirty-state note;
- severity cards and counts for scanner alerts versus verified defects; name a
  secret-like alert's evidence origin and never imply an unscanned source;
- coverage matrix, tool versions/commands, network behavior, and checks skipped;
- evidence-backed findings with redacted excerpts, confidence, impact, and next action;
- for each verified finding: rule, path and line, CWE/OWASP mapping when valid,
  source-to-sink or control reasoning, exploit conditions, affected boundary,
  remediation, and verification status;
- every repository path must be clickable, including parser gaps, skipped files,
  false positives, risks, and action items; pin links to the scanned head SHA;
- scan statistics, parser failures, timeouts, skipped files, and the reason each
  material alert was confirmed, grouped, or dismissed;
- false positives, accepted repository exceptions, residual risks, and unscanned
  surfaces.

Never embed secret values, tokens, patient/customer data, production payloads,
full source files, raw scanner logs, or machine credentials. A detected real
secret requires rotation guidance even when removed from code. Keep the report
untracked and return its absolute path plus a concise chat summary.

## Reusable prompt

```text
REPOSITORY_PATH: PASTE_ABSOLUTE_PATH_OR_CURRENT_WORKSPACE
REPOSITORY_WEB_URL: PASTE_GITHUB_REPOSITORY_URL
SECURITY_SCOPE: FULL_REPOSITORY
ANALYSIS_DEPTH: DEEP_SAST
SAST_ENGINE: SEMGREP_CE
HISTORY_SCAN: NO
OUTPUT: SANITIZED_HTML
REPORT_DIRECTORY: AUTO_PRIVATE_TEMP
Run a read-only security review of the complete tracked repository. Use
$code-review with the security lens. Treat REPOSITORY_PATH as the single target
and REPOSITORY_WEB_URL as the base for evidence links. Read the repository's
instructions and existing security configuration, then inventory its native
scanners before proposing anything additional.
First stay read-only: confirm Git state, then propose exact tools, versions,
commands, scope, exclusions, network/download/telemetry behavior,
runtime, and report path. Stop for APPROVE SECURITY SCAN. For GIT_HISTORY,
require HISTORY_SCAN: YES and stop for APPROVE SECURITY HISTORY SCAN instead.

After approval, run only the approved installed/pinned checks. Do not install,
download rules or advisory data, upload source/results, probe endpoints, change
ignores, fix findings, commit, or publish. Verify important alerts against code.
Redact secrets and confidential data.
For DEEP_SAST, use the installed Semgrep CE command with `--metrics off` and
reviewed rules appropriate to the detected languages. Scan the complete tracked
repository and save private JSON/SARIF evidence. Treat tool output as leads, not
vulnerabilities. Explain parse gaps and verify data flow, trust boundaries, and
existing controls in code.
For SANITIZED_HTML, create an offline report with summary cards, coverage,
verified findings, scanner alerts, false-positive reasons, gaps, risks, and next
actions. Make every repository path clickable at the exact scanned SHA; use line
anchors when known and a file link otherwise. Use direct headings: finding,
evidence, why it matters, and fix. End with a short natural note about local raw
artifacts and whether source changed. Avoid praise and unsupported conclusions.
```
