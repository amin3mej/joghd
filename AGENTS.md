## Agent skills

### Issue tracker

Issues live in the Joghd Linear workspace (team `JOG`). See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles map one-to-one to their names. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context; `GLOSSARY.md` and `docs/adr/` live one level up, in the project root. See `docs/agents/domain.md`.

### Autonomous worker

A scheduled task (every 30 min) drains the `ready-for-agent` queue: claims one ticket, implements it in a worktree, opens a PR, posts an AI review, and enables auto-merge. See `docs/agents/autonomous-worker.md`.
