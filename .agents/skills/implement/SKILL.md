---
name: implement
description: Complete one local ticket or bounded development task, verify its behavior, and review the changes.
---

# Implement

Read [the local workflow](../workflow.md). Identify the exact task, repo instructions, and baseline working-tree state. For a ticket, read the linked spec and verify dependencies are complete. Do not start a blocked ticket. Small direct tasks need no spec or ticket ceremony.

Set a started ticket and its parent spec to `in-progress`. Work within scope using [tdd](../tdd/SKILL.md) where useful. Preserve user changes. Record actual obstacles as `blocked`, with the reason and needed next action.

Run relevant checks and use [code-review](../code-review/SKILL.md) on actual changes, including uncommitted files. Fix in-scope findings and repeat affected verification. Do not silently expand scope to unrelated problems.

Mark ticket criteria and status `done` only with verification and review evidence. Record limitations. Completing one ticket does not mark the entire spec done; that requires integrated verification under [implement-spec](../implement-spec/SKILL.md).

Report changes, checks and results, and remaining concerns. Leave work uncommitted unless explicitly requested.
