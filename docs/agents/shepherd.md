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
`gh pr view <url> --json state,mergedAt,mergeStateStatus,headRefName`:

- **merged** (`state` is `MERGED`) → `save_issue` state `"Done"`; comment
  `Merged: <url>`; remove the PR's worktree. If a dispatched session left it
  dirty, inspect the uncommitted work (`git -C <path> status --short`) and keep
  what's useful before removing with `--force`; if you can't preserve it, stop
  and comment rather than delete. Then, from outside the removed worktree,
  delete the PR's local branch. Name it from the PR's `headRefName`
  (`gh pr view <url> --json headRefName`), falling back to the worktree
  directory name. Skip when no such local branch exists (`git show-ref --verify
  --quiet refs/heads/<name>`); otherwise compare the merged head
  (`gh pr view <url> --json headRefOid --jq .headRefOid`) with the local tip
  (`git rev-parse refs/heads/<name>`) and run `git branch -D -- "<name>"` only
  when they match — a tip that has advanced past the merge means someone kept
  working there, so leave it. Squash merges leave the branch tip outside
  `main`'s ancestry, so `-d` refuses, and `-D` is safe once the tips match.
  Leave remote branches untouched.
- **closed, not merged** → comment why; `addLabels ["needs-info"]`,
  `assignee null`, state `"Todo"`.
- **still open** (checks running, awaiting review, conflict) → leave it; the
  next run reaps it.

## 1. Respond to change requests

The human reviewer (`amin3mej`, via the required code-owner approval) and the AI
reviewer each signal "something must change" with a **`Request changes`** review.
That sets the PR's review decision to `CHANGES_REQUESTED`; address the PR while
that is the state.

Reuse Reap's scan:

```
list_issues: team "JOG", assignee "me", state "In Review"
```

For each ticket, read the PR's review decision:

```sh
gh pr view <url> --json reviewDecision --jq .reviewDecision
```

- **`CHANGES_REQUESTED`** → a reviewer is blocking; that ticket is your target.
- **anything else** (`APPROVED`, `REVIEW_REQUIRED`, `null`) → skip it.

This is the deliberate signal — a reviewer, **human or AI**, asks for a change and
the worker makes it. AI reviewers are not excluded: `coderabbitai` submits
`Request changes` reviews exactly like the human does, and its findings are
addressed the same way. It ignores only approvals and dismissed reviews (and the
worker's own output). No per-author filtering is needed, since GitHub forbids the
PR author from reviewing its own PR.

`reviewDecision` stays `CHANGES_REQUESTED` until the reviewer re-reviews, so after
pushing a fix **re-request review** from the requester — that is what clears the
request (or re-opens it with new feedback). If the first ticket's request is
already handled (you have replied to or 👍-ed its comments), re-request review and
**keep scanning** the remaining tickets for an unanswered request — but do not
make a second fix in the same run.

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
- Re-requests review from the human code owner: `gh pr edit <url> --add-reviewer
  amin3mej`.
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
- **Address each change request once** — `reviewDecision` stays
  `CHANGES_REQUESTED` until the reviewer re-reviews, so don't re-fix a request
  you've already answered.
- **React, don't reply** — a 👍 marks a comment the commit resolved; reply only
  to answer a question, disagree, or add context.
- **Merge only via auto-merge.** Never force-merge a PR whose checks or review
  haven't passed.
- **Never delete** tickets or comments to "clean up"; only comment.
