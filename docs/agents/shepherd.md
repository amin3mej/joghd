# Shepherd (reap + respond)

A scheduled task runs this file. Each run tends the open PRs on `In Review`
tickets: reap any that merged, then address **at most one** round of review
feedback. The queue is Linear team `JOG`.

## 0. Reap merged PRs

```
list_issues: team "JOG", assignee "me", state "In Review"
```

These are tickets whose PR is open with auto-merge enabled. For each, read the
PR URL from your earlier comment and check it with
`gh pr view <url> --json state,mergedAt,mergeStateStatus`:

- **merged** → `save_issue` state `"Done"`; comment `Merged: <url>`.
- **closed, not merged** → comment why; `addLabels ["needs-info"]`,
  `assignee null`, state `"Todo"`.
- **still open** (checks running, awaiting review, conflict) → leave it; the
  next run reaps it.

## 1. Respond to review feedback

The required code-owner approval means the reviewer (`amin3mej`) will request
changes on open PRs, and those changes must be addressed before the PR can
merge. This step picks up that feedback.

Reuse Reap's scan:

```
list_issues: team "JOG", assignee "me", state "In Review"
```

For each ticket, decide whether its PR has **new human feedback** since the bot
last pushed. A reviewer can block the PR with a submitted `CHANGES_REQUESTED`
review, or just leave a comment — top-level or inline — without submitting a
review. Watch all three:

```sh
gh pr view <url> --json reviews,comments,reviewThreads --jq '
  [
    .reviews[]? | select(.state == "CHANGES_REQUESTED") | .submittedAt,
    .comments[]? | select(.author.login != "joghd-bot") | .createdAt,
    .reviewThreads[]?.comments[]? | select(.author.login != "joghd-bot") | .createdAt
  ] | sort | last
'
gh pr view <url> --json commits --jq '.commits[-1].committedDate'
```

- If the newest of those timestamps is **after** the head commit's
  `committedDate`, the reviewer left feedback the bot hasn't addressed yet →
  that ticket is your target.
- If it's **before** (or empty — no feedback yet), the bot already pushed for
  the latest round; leave it for the reviewer to re-review.

Filter out `joghd-bot`'s own comments and reviews, or the bot's own
`Fixed in <sha>` replies and AI-review threads will retrigger the loop forever.
Compare timestamps, never `reviewDecision` alone: `CHANGES_REQUESTED` stays set
from the moment changes are requested until the reviewer re-reviews, which
includes the whole window where the fix is already pushed and waiting. The
timestamp is what stops the loop re-fixing the same round forever.

**First unaddressed target wins.** No target → report "no review feedback to
address" and stop.

### Address the feedback

Dispatch a fresh session (`returnResult`: true, model
`opencode-go/deepseek-v4-pro`) that:

- Checks out the PR's branch — `gh pr checkout <url>` — in a worktree. Do not
  start a new branch from `main`.
- Reads the requested changes (`gh pr view <url> --json reviews,comments`) and
  the issue, plus `docs/agents/domain.md`, `../GLOSSARY.md`, and any relevant
  `../docs/adr/`.
- Implements the changes with `/implement` (drives `/tdd`, closes with
  `/code-review`).
- Pushes to the same branch; reply to each reviewer thread with `Fixed in
  <sha>`. Do **not** resolve the reviewer's threads — resolving their feedback
  hides it; they resolve it themselves.
- Re-requests review (`gh pr ready <url>` or re-request the reviewer).
- Re-enables auto-merge: `gh pr merge <url> --auto --squash`.
- Returns the PR URL and a one-line summary, or a precise error.

Do **not** approve the PR yourself — that's the reviewer's job, and the bot
cannot approve its own work anyway. Leave the ticket `In Review`.

## Failure

If anything in steps 0–1 fails:

- `save_comment` on the ticket: what broke, what you tried, the exact error.
- The ticket already has an open PR, so do not put it back on `ready-for-agent`
  (that re-sows it as new work):
  - **Transient** (environment, flaky CI, tool error) → leave it `In Review`;
    the next run tries again.
  - **Permanent** (the reviewer asked for something the bot can't do) → comment
    what's blocked, `addLabels ["ready-for-human"]`, `assignee null`, state
    `"Todo"`.
- Never leave a ticket stuck with no comment.

## Guardrails

- **One response per run** — address at most one PR's feedback, even if several
  have new feedback.
- **Address each review round once** — use the head-commit timestamp to tell a
  new round of feedback from one you already pushed for.
- **Merge only via auto-merge.** Never force-merge a PR whose checks or review
  haven't passed.
- **Never delete** tickets or comments to "clean up"; only comment.
