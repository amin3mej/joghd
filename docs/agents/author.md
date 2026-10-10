# Author (sow)

A scheduled task runs this file. Each run drains **at most one**
`ready-for-agent` ticket end to end: claim it, implement it in a worktree, open
a PR, post an AI review, and enable auto-merge. The queue is Linear team `JOG`.

## 1. Find

```
list_issues: team "JOG", label "ready-for-agent", assignee "null"
```

Walk the results oldest-first. For each candidate, confirm it has no open
blockers (`get_issue` with `includeRelations: true`; skip if `blockedBy` lists
anything not `Done`). The first unblocked, unassigned issue is your target.

No target → report "queue empty" and stop. Do not invent work.

## 2. Claim (the lock)

Before writing any code:

```
save_issue: id, assignee "me", state "In Progress", removeLabels ["ready-for-agent"]
```

The assignee write is the lock — it stops any concurrent run from taking the
same ticket. Removing the label takes it out of the queue. Never work a ticket
you haven't claimed.

## 3. Implement in a worktree

Dispatch a fresh session in a new worktree (OpenChamber `session.create`):

- `worktree`: `<issue-id>-<kebab-case-title>`
- `returnResult`: true
- model: `opencode-go/deepseek-v4-pro`

The dispatched prompt must carry the issue identifier, title, description, and
acceptance criteria, plus these instructions:

- Read `docs/agents/domain.md`, `../GLOSSARY.md`, and any relevant `../docs/adr/`
  before starting.
- Implement with the `/implement` skill (it drives `/tdd` and closes with
  `/code-review`).
- Open a pull request — do **not** merge. Use `/pr` for the body.
- Return the PR URL and a one-line summary, or a precise error if you fail.

If the dispatch tool is not available, do the same yourself: `git worktree add
<path> main`, implement there, then `git worktree remove` once the PR is open.

## 4. AI review

Run `/code-review` (Standards + Spec axes) on the PR. Post the findings as a
comment on the PR. Fix any Spec failures; for Standards findings you choose not
to fix, say so explicitly.

Then **resolve every review thread you opened**. The repo requires all review
threads resolved before merge, so an unresolved AI-review thread blocks your own
auto-merge.

## 5. Auto-merge

- `save_comment` on the ticket with the PR URL and a one-line summary.
- Enable auto-merge so the PR merges the moment it can:
  `gh pr merge <url> --auto --squash`.
- `save_issue`: state `"In Review"`.

Auto-merge waits on whatever the repo requires — green required checks, the
required code-owner approval, no conflicts — then merges on its own. If enabling
it fails (e.g. the required approval is still pending), leave the PR open and
say so on the ticket.

## Failure

If anything in steps 2–5 fails:

- `save_comment` on the ticket: what broke, what you tried, the exact error.
- Then mark it so it isn't silently re-picked:
  - **Permanent** (you can't solve it): `addLabels ["needs-info"]`,
    `assignee null`, state `"Todo"`.
  - **Transient** (environment, flaky CI, tool error): `addLabels
    ["ready-for-agent"]`, `assignee null`, state `"Todo"` to retry.
- Never leave a ticket stuck in `In Progress` with no comment.

## Guardrails

- **One ticket per run**, even if the queue is long.
- **Claim before work** — the assignee write is the lock.
- **Merge only via auto-merge.** Never force-merge a PR whose checks or review
  haven't passed.
- **Never delete** tickets or comments to "clean up"; only comment.
