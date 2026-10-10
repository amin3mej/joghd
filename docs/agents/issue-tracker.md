# Issue tracker: Linear

Issues and specs for this repo live in the **Joghd** Linear workspace
(https://linear.app/joghd), team **Joghd** (key `JOG`). Issue identifiers look
like `JOG-123`.

Operate Linear through its MCP tools (the `tools.linear.*` namespace). Use them
for every operation below.

## Epics are Projects

Epics in this repo are Linear **Projects**, not parent issues. This matches
Linear's own Jira mapping, where a Jira Epic maps to a Linear Project
(`Project > Issue > Sub-issue` ≈ `Epic > Story > Sub-task`).

- One project per epic; individual work items are issues assigned to that
  project via `project` on `save_issue`.
- Use **parent issues / sub-issues** only to decompose a *single* issue, and for
  `/wayfinder` maps — not to group an epic.
- A group of epics (e.g. a release) is an **Initiative**, not a grandparent
  issue.

Create an epic: `tools.linear.save_project` with `name`, `description`, and
`setTeams: ["JOG"]` plus `leadTeam: "JOG"` (a team is required on create).

Current epics: **Shared core** (`P-JOG-2`), **Import** (`P-JOG-3`),
**Library** (`P-JOG-4`), **Reader** (`P-JOG-1`), **CI/CD** (`P-JOG-5`).

## Conventions

- **Create an issue**: `tools.linear.save_issue` with `team: "JOG"` and `title`.
  Pass `description` as Markdown with literal newlines (no escape sequences).
- **Update an issue**: `tools.linear.save_issue` with `id: "JOG-123"` plus only
  the fields to change.
- **Read an issue**: `tools.linear.get_issue` with `id: "JOG-123"`.
- **List issues**: `tools.linear.list_issues` with filters (`team`, `state`,
  `label`, `assignee`, `project`, `parentId`, `query`).
- **Make a sub-issue**: `tools.linear.save_issue` with `parentId: "JOG-123"`.
- **Comment**: `tools.linear.save_comment` with `issueId` + `body`; reply to a
  thread with `parentId` + `body`.
- **Apply / remove labels**: `addLabels` / `removeLabels` on `save_issue`
  (update path). Create labels with `tools.linear.save_issue_label`.
- **Set state**: `state` on `save_issue` — `Todo`, `Backlog`, `In Progress`,
  `Done`, `Canceled`, or `Duplicate`.
- **Relations**: `blockedBy`, `blocks`, `relatedTo` on `save_issue` (all
  append-only; use `removeBlockedBy` / `removeBlocks` / `removeRelatedTo` to
  clear edges).

## When a skill says "publish to the issue tracker"

Create a Linear issue with `tools.linear.save_issue` (team `JOG`).

## When a skill says "fetch the relevant ticket"

Read it with `tools.linear.get_issue` by its `JOG-<n>` identifier.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a single issue with **child** issues as
tickets.

- **Map**: a single issue in team `JOG` labelled `wayfinder:map`, holding the
  Notes / Decisions-so-far / Fog body.
- **Child ticket**: an issue with `parentId` set to the map, labelled
  `wayfinder:<type>` (`research` / `prototype` / `grilling` / `task`). Once
  claimed, the ticket is assigned to the driving dev.
- **Blocking**: `blockedBy` on the child (list the blocker identifiers). A
  ticket is unblocked when every blocker is `Done`.
- **Frontier query**: `tools.linear.list_issues` with `parentId: "<map>"`; drop
  any with an open blocker or an assignee; first in map order wins.
- **Claim**: `tools.linear.save_issue` with `id` and `assignee: "me"`, the
  session's first write.
- **Resolve**: comment the answer, then set `state: "Done"`.
