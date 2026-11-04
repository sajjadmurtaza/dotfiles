# Security Scan Scope and Report

Load after `security-tools.md` for a full repository, Git-history scan, or HTML
report.

## Inputs

| Field | Values |
| --- | --- |
| `REPOSITORY_PATH` | Absolute path or `CURRENT_WORKSPACE` |
| `SECURITY_SCOPE` | `FULL_REPOSITORY` or `GIT_HISTORY` |
| `ANALYSIS_DEPTH` | `STANDARD` or `DEEP_SAST` |
| `SAST_ENGINE` | `AUTO`, `SEMGREP_CE`, or a repository-approved equivalent |
| `HISTORY_SCAN` | `NO` unless `SECURITY_SCOPE` is `GIT_HISTORY` |
| `OUTPUT` | `CHAT` or `SANITIZED_HTML` |
| `REPORT_DIRECTORY` | `AUTO_PRIVATE_TEMP` unless an approved path is supplied |

`FULL_REPOSITORY` means the current tracked tree, not Git history. Respect
repository ignores and explain excluded generated/vendor surfaces. History
scanning can uncover old live credentials and requires `HISTORY_SCAN: YES` plus
separate explicit approval.

`STANDARD` reuses existing repository checks. `DEEP_SAST` adds code-aware SAST
and requires an approved installed engine plus reviewed rules. Do not call a
report comprehensive when it contains only framework or secret scans.

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
CSS only: no CDN, remote font, script, tracker, or network asset. Include:

- repository, head SHA, time, scope, exclusions, and dirty-state note;
- severity cards and counts for scanner alerts versus verified defects;
- coverage matrix, tool versions/commands, network behavior, and checks skipped;
- evidence-backed findings with redacted excerpts, confidence, impact, and next
  action;
- for each verified finding: rule, path and line, CWE/OWASP mapping when valid,
  source-to-sink or control reasoning, exploit conditions, affected boundary,
  remediation, and verification status;
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
SECURITY_SCOPE: FULL_REPOSITORY
ANALYSIS_DEPTH: DEEP_SAST
SAST_ENGINE: SEMGREP_CE
HISTORY_SCAN: NO
OUTPUT: SANITIZED_HTML
REPORT_DIRECTORY: AUTO_PRIVATE_TEMP

Use $code-review with the security lens. Treat REPOSITORY_PATH as the single
repository target. Read its instructions and existing security configuration,
then inventory repository-native scanners before proposing anything additional.

First stay read-only: confirm the Git root and state, propose the exact tools,
versions, commands, scope, exclusions, network/download/telemetry behavior,
runtime, and report path. Stop for APPROVE SECURITY SCAN. For GIT_HISTORY,
require HISTORY_SCAN: YES and stop for APPROVE SECURITY HISTORY SCAN instead.

After approval, run only the approved installed/pinned checks. Do not install,
download rules or advisory data, upload source/results, probe endpoints, change
ignores, fix findings, commit, or publish. Verify important alerts against code.
Redact secrets and confidential data.

For DEEP_SAST, scan the complete tracked repository. Treat tool output as leads,
not vulnerabilities. Explain parse gaps and verify data flow, trust boundaries,
and existing controls in code.

For SANITIZED_HTML, create a professional offline report with summary cards,
coverage, verified findings with path/line and remediation, scanner-only alerts,
false-positive reasons, verification status, parse/skipped gaps, residual risks, and
prioritized next actions. Store it outside the repository in a private temporary
directory. Return its absolute path and a short evidence-based summary.
```
