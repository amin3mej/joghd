# Domain Docs

How the engineering skills should consume this repo's domain documentation
when exploring the codebase.

This `ios/` repo keeps its domain documentation **one level up**, in the
project root (where the product plan and glossary already live).

## Before exploring, read these

- **`../GLOSSARY.md`** (relative to this repo root): the project glossary.
- **`../docs/adr/`**: read ADRs that touch the area you're about to work in.

If any of these files don't exist, **proceed silently**. Don't flag their
absence; don't suggest creating them upfront. The `/domain-modeling` skill
(reached via `/grill-with-docs` and `/improve-codebase-architecture`) creates
them lazily when terms or decisions actually get resolved.

## File structure

Single-context layout, domain docs kept in the parent project root:

```
..
├── GLOSSARY.md
└── docs/
    ├── adr/
    ├── product-plan.md
    └── backlog.md
```

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor
proposal, a hypothesis, a test name), use the term as defined in
`../GLOSSARY.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal: either
you're inventing language the project doesn't use (reconsider) or there's a
real gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than
silently overriding:

> _Contradicts ADR-0007 (…), but worth reopening because…_
