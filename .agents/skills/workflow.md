# Local development workflow

All paths are relative to the target repository root. Specs and tickets use local Markdown exclusively, never an external tracker.

- Spec: `docs/work/<feature>/spec.md`
- Tickets: `docs/work/<feature>/tickets/NN-<slug>.md`
- Terminology: `GLOSSARY.md`
- Decisions: `docs/adr/NNNN-<slug>.md`

Reuse existing feature directories. Create directories only when writing content. Preserve existing IDs, filenames, history, and unrelated work. Resolve ambiguous feature references before edits.

## Spec template

```markdown
# <Feature>
Status: draft

## Problem and intended outcome
## Scope and non-goals
## Acceptance criteria
- [ ] AC1: <Observable outcome>
## Decisions and constraints
## Verification
## Open questions
## Tickets
```

Use stable acceptance IDs. Link useful source evidence and decisions; distinguish current behavior from requirements. Record assumptions. Status is `draft` while material questions remain, `ready` when actionable, `in-progress` during implementation, and `done` only after integrated acceptance verification. A draft is not implementation authorization.

## Ticket template

```markdown
# 01: <Title>
Spec: [Feature spec](../spec.md)
Status: todo
Blocked by: none

## Outcome
<Independently verifiable behavior and scope>

## Acceptance criteria
- [ ] <Observable outcome and relevant spec AC IDs>

## Verification
<Tests or manual checks>

## Completion notes
```

Use relative Markdown links to sibling tickets for blockers. Statuses: `todo`, `in-progress`, `blocked`, `done`. A `todo` ticket is eligible only when all dependencies are `done`. Use `blocked` for an actual obstacle, documenting why and the needed next action; pending dependencies alone can remain `todo`.

Validate that dependency targets exist and the graph is acyclic before execution. Never ignore missing dependencies or cycles. Use unused numbers for new tickets, preferably in dependency order; never renumber existing tickets.

Mark criteria complete only with evidence. Completion notes record changes, checks and results, and limitations. If a required check cannot run, disclose it and leave affected work incomplete unless the user explicitly accepts an alternative. Reopen work when new evidence invalidates completion.

## Execution defaults

Read repo instructions, relevant glossary entries, and ADRs. Work sequentially in the current checkout and preserve unrelated changes. Branches, worktrees, parallel agents, commits, pushes, and PRs require an explicit request. Infer routine implementation and testing choices from evidence; ask about material scope or correctness decisions. Keep statuses synchronized with verified progress. Never report unavailable checks as passing.
