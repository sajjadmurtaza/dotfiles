# Security Scan Scope and Report

Load after `security-tools.md` for a full repository, Git-history scan, or HTML
report.

## Inputs

| Field | Values |
| --- | --- |
| `REPOSITORY_PATH` | Absolute path or `CURRENT_WORKSPACE` |
| `SECURITY_SCOPE` | `CURRENT_DIFF`, `FULL_REPOSITORY`, or `GIT_HISTORY` |
| `HISTORY_SCAN` | `NO` unless `SECURITY_SCOPE` is `GIT_HISTORY` |
| `OUTPUT` | `CHAT` or `SANITIZED_HTML` |
| `REPORT_DIRECTORY` | `AUTO_PRIVATE_TEMP` unless an approved path is supplied |

`FULL_REPOSITORY` means the current tracked tree, not Git history. Respect
repository ignores and explain excluded generated/vendor surfaces. History
scanning can uncover old live credentials and requires `HISTORY_SCAN: YES` plus
separate explicit approval.

## Approval gate

Before scanning, confirm the Git root, branch, head SHA, dirty state, applicable
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

- repository, branch, head SHA, time, scope, exclusions, and dirty-state note;
- severity cards and counts for scanner alerts versus verified defects;
- coverage matrix, tool versions/commands, network behavior, and checks skipped;
- evidence-backed findings with redacted excerpts, confidence, impact, and next
  action;
- false positives, accepted repository exceptions, residual risks, and unscanned
  surfaces.

Never embed secret values, tokens, patient/customer data, production payloads,
full source files, raw scanner logs, or machine credentials. A detected real
secret requires rotation guidance even when removed from code. Keep the report
untracked and return its absolute path plus a concise chat summary.

## Reusable prompt

```text
REPOSITORY_PATH: PASTE_ABSOLUTE_PATH_OR_CURRENT_WORKSPACE
SECURITY_SCOPE: CURRENT_DIFF
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

For SANITIZED_HTML, create a professional offline report with summary cards,
coverage, verified findings, scanner-only alerts, false positives, skipped
checks, residual risks, and prioritized next actions. Store it outside the
repository in a private temporary directory. Return its absolute path and a
short evidence-based summary.
```
