# Publish

Review end to end: retrieve → fresh ledger → reconcile → recheck SHA → publish
one `COMMENT` review → verify URLs. Draft with
[`conventional-comments.md`](conventional-comments.md); mutate through
[`github-state.md`](github-state.md).

## Hard rules

- Submit only `event: "COMMENT"`; reject `REQUEST_CHANGES` or `APPROVE`.
- Build a **fresh** head ledger; pending drafts are input, not truth.
- Never edit or resolve others' comments, publish against stale/guessed locations,
  or change application code.

## 1. Retrieve

Use the Shared-prep `pr-context.sh --publish` snapshot, or run it once. Read the
head patch/code, record its SHA, and apply target-repo `AGENTS.md`.

## 2. Ledger

Apply `finish` plus selected lenses. Publish high-confidence Critical/Important
and only useful Nice-to-Have findings. Drop soft, speculative, duplicate, or
answered items. Prefer substantive existing-thread replies. Seek 0–2 earned
`praise`.

| Field      | Values                                                            |
| ---------- | ----------------------------------------------------------------- |
| Severity   | Critical / Important / Nice-to-Have                               |
| Confidence | High / Medium / Low + concrete impact                             |
| Evidence   | path + RIGHT-side diff line on verified head SHA                  |
| Coverage   | new thread / current-user draft / existing human or bot thread    |
| Action     | `publish-inline` / `reply-existing` / `review-body-only` / `drop` |
| Wording    | Conventional Comments body                                        |

Regex-validate every inline comment and labeled reply before posting.

## 3. Reconcile → stale guard → publish → verify

Fail-closed procedure: [`github-state.md`](github-state.md) — keep verified drafts; re-fetch head SHA before first mutation (stale → abort/re-anchor); submit `COMMENT` only; draft-only → stop at PENDING; verify URLs; state no code changed.

## Review body

- `## Review findings`, one outcome sentence, severity-ordered findings with impact (don't paste inline bodies), optional short "What looks solid".
- Never "Request changes" / "blocking review". Conventional Comments only for inline comments and replies.
- Do not append a canned courtesy line, sign-off, or invitation to re-request review.
  End after the last useful finding unless a concrete next action would help the
  author. When follow-up is useful, name the specific missing evidence or change;
  do not rotate generic synonyms merely to make templated language look varied.
