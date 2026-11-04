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

`FULL_REPOSITORY` means the tracked tree, not Git history. Respect ignores and explain
excluded generated/vendor surfaces. History requires separate approval. `STANDARD`
reuses repository checks; `DEEP_SAST` adds an approved engine and reviewed rules.

## Approval gate

Before scanning, confirm Git root/SHA/state, instructions, existing gates, tool
versions, commands, network behavior, exclusions, and report path. Stop
for `APPROVE SECURITY SCAN`; use `APPROVE SECURITY HISTORY SCAN` for history.

Approval covers only the stated read-only commands. It does not authorize tool
installation, database/rule updates, active endpoint probing, uploads, ignore
changes, fixes, commits, or external publication.

## Sanitized HTML

Create one offline `report.html` in a private temporary directory with embedded
CSS only. Repository evidence links are allowed. Include:

- repository, head SHA, time, scope, exclusions, and dirty-state note;
- severity cards and counts for scanner alerts versus verified defects; name a
  secret-like alert's evidence origin and never imply an unscanned source;
- coverage, tool versions/commands, network behavior, and skipped checks;
- findings with redacted evidence, confidence, impact, and next action;
- for each verified finding: rule, path and line, CWE/OWASP mapping when valid,
  source-to-sink or control reasoning, exploit conditions, affected boundary,
  remediation, and verification status;
- every repository path must be clickable, including parser gaps, skipped files,
  false positives, risks, and action items; pin links to the scanned head SHA;
- scan statistics, parser failures, timeouts, skipped files, and the reason each
  material alert was confirmed, grouped, or dismissed;
- false positives, accepted exceptions, residual risks, and unscanned
  surfaces.

For `FULL_REPOSITORY`, show the repository and short linked SHA. Omit branch,
ticket, and diff comparisons unless requested. Present
each finding as labeled bullets. Render scanner-alert triage as responsive
cards with a count, short status, and
evidence bullets; do not use a wide table, a `Disposition` column, or long pill
badges. Reserve tables for compact comparisons, wrap long content, and verify
that the report has no horizontal overflow at desktop or narrow widths.

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

After approval, run only approved installed/pinned checks. Do not install,
download, upload, probe, change ignores, fix, commit, or publish. Verify alerts
against code; redact secrets and confidential data. For DEEP_SAST, use installed
Semgrep CE with `--metrics off` and reviewed language rules. Scan the tracked
repository, save private JSON/SARIF, explain gaps, and verify data flow and controls.
For SANITIZED_HTML, create an offline report with summary cards, coverage,
verified findings, scanner alerts, false-positive reasons, gaps, risks, and next
actions. For a full-repository scan, show only the repository and short linked
SHA—not branch, ticket, or diff status. Make every repository path clickable at
the exact scanned SHA. Use short labeled bullets for findings. Show alert triage
as responsive cards with count, short status, and evidence bullets; never use a
Disposition table or long badges. Wrap paths and verify no horizontal overflow.
End with a natural note about local artifacts and whether source changed.
```
