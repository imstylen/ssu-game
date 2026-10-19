---
name: implement-spec
description: Complete an entire local specification by executing its ticket graph sequentially and verifying the integrated result.
---

# Implement Spec

Read [the local workflow](../workflow.md), the selected spec, and linked tickets. Resolve material open questions before execution. If tickets are missing, use [to-tickets](../to-tickets/SKILL.md); implementing the spec authorizes this necessary preparation.

Validate dependencies, missing targets, cycles, and acceptance coverage. Inspect completion evidence when resuming; status labels cannot override contradictory code.

Set the spec `in-progress`. Choose a `todo` ticket whose dependencies are all `done` and follow [implement](../implement/SKILL.md). Recompute eligible work after each ticket and continue sequentially. Record external blockers and continue independent eligible tickets. If none are eligible and unfinished work remains, report blockers and leave the spec incomplete.

Parallel agents require an explicit request. Do not assume integration branches or worktrees are needed. Leave work uncommitted unless requested.

After tickets complete, verify all spec acceptance criteria against the integrated implementation, run relevant broader checks, and apply [code-review](../code-review/SKILL.md) to the complete feature change. Fix in-scope findings and rerun affected checks. Reopen tickets when integration reveals missing work. Mark the spec `done` only after required verification, recording evidence in its verification section.

Report completed tickets, integrated verification, changed files, and limitations. Ticket counts alone do not prove spec completion.
