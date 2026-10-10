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

- **merged** → `save_issue` state `"Done"`; comment `Merged: <url>`; remove the
  PR's worktree (`git worktree remove <path>`).
- **closed, not merged** → comment why; `addLabels ["needs-info"]`,
  `assignee null`, state `"Todo"`.
- **still open** (checks running, awaiting review, conflict) → leave it; the
  next run reaps it.

## 1. Respond to change requests

The human reviewer (`amin3mej`, via the required code-owner approval) and the AI
reviewer each signal "something must change" with a **`Request changes`**
review. Address the open request whenever there is one.

Reuse Reap's scan:

```
list_issues: team "JOG", assignee "me", state "In Review"
```

For each ticket, a PR needs work when it has a `CHANGES_REQUESTED` review **on
its current head commit**:

```sh
gh pr view <url> --json reviews,headRefOid --jq '
  . as $p
  | [ $p.reviews[] | select(.state == "CHANGES_REQUESTED" and .commit.oid == $p.headRefOid) ] | length
'
```

- **`> 0`** → a reviewer requested changes and nothing has been pushed since →
  that ticket is your target.
- **`0`** → no open change request; skip it.

A review is pinned to the commit it was submitted against. Once the worker pushes
a fix, the head moves past it and the request reads as addressed; a fresh
`Request changes` on the new head re-opens it. Checking against the head commit
(rather than `reviewDecision` alone) is what stops the loop — `reviewDecision`
stays `CHANGES_REQUESTED` until the reviewer re-reviews, so the plain flag would
re-fire every run.

Because this keys on review state, it ignores everything that is not a change
request: plain comments, approvals, dismissed reviews, and non-actionable bot
chatter (CodeRabbit's summary, Linear's linkback). No author filtering is needed
either — GitHub forbids the PR author from reviewing its own PR, so the worker
cannot trigger itself.

**First open request wins.** No target → report "no change requests" and stop.

### Address the feedback

Dispatch a fresh session (`returnResult`: true) that:

- Checks out the PR's branch — `gh pr checkout <url>` — in a worktree. Do not
  start a new branch from `main`.
- Reads the requested changes — submitted reviews and top-level comments via
  `gh pr view <url> --json reviews,comments`, inline comments via
  `gh api repos/{owner}/{repo}/pulls/<n>/comments` — and the issue, plus
  `docs/agents/domain.md`, `../GLOSSARY.md`, and any relevant `../docs/adr/`.
- Implements the changes with `/implement` (drives `/tdd`, closes with
  `/code-review`).
- Pushes to the same branch.
- Signals each reviewer comment. **Default: react with 👍** when the commit
  resolves it and no written answer is needed — do not reply:
  - inline comment → `gh api -X POST repos/{owner}/{repo}/pulls/comments/<comment_id>/reactions -f content=+1`
  - top-level comment → `gh api -X POST repos/{owner}/{repo}/issues/comments/<comment_id>/reactions -f content=+1`
- **Reply only** when you are answering a question, disagreeing, or adding
  context the reviewer needs. Keep it short and name the commit
  (`Fixed in <sha> — …`, `Disagree: …`).
- Do **not** resolve the reviewer's threads — resolving their feedback hides it;
  they resolve it themselves.
- Re-requests review (`gh pr ready <url>` or re-request the reviewer).
- Re-enables auto-merge: `gh pr merge <url> --auto --squash`.
- Returns the PR URL and a one-line summary, or a precise error.

Do **not** approve the PR yourself — that's the reviewer's job, and the bot
cannot approve its own work anyway. Leave the ticket `In Review`.

## Failure

If anything in steps 0–1 fails:

- `save_comment` on the ticket: what broke, what you tried, the exact error.
- **Notify the human**: `@`-mention `@amin3mej` in that comment so they are
  pinged to investigate and fix it.
- **Open a failure ticket** in team `JOG`, titled `Worker failure: <issue-id>`,
  so the failure is tracked and triaged rather than buried in a comment.
  Describe what broke, what you tried, and the exact error; `addLabels
  ["ready-for-human"]`. Link it from the comment on the stuck ticket.
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
- **Address each change request once** — a `CHANGES_REQUESTED` review on the
  current head is open; once you push, it reads as addressed.
- **React, don't reply** — a 👍 marks a comment the commit resolved; reply only
  to answer a question, disagree, or add context.
- **Merge only via auto-merge.** Never force-merge a PR whose checks or review
  haven't passed.
- **Never delete** tickets or comments to "clean up"; only comment.
