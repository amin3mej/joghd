# Autonomous worker

This project's autonomous work runs as two scheduled tasks, draining disjoint
queues so they can run concurrently without contending over the same ticket:

| Task | File | Queue | Responsibility |
| ---- | ---- | ----- | -------------- |
| **Author** | [`author.md`](author.md) | `ready-for-agent` | Claim one ticket, implement it in a worktree, open a PR, post an AI review, enable auto-merge. |
| **Shepherd** | [`shepherd.md`](shepherd.md) | `In Review` | Reap merged PRs, and address one round of review feedback on an open PR. |

They touch different ticket states — `ready-for-agent` vs `In Review` — so they
never fight over the same ticket. Tune their cadences independently: the author
controls throughput (how fast new work starts), the shepherd controls latency
(how fast review feedback turns around).

Bot identity (`joghd-bot`) is configured by the environment; neither task sets
it up itself.
