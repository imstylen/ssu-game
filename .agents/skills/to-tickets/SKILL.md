---
name: to-tickets
description: Decompose a local specification into verifiable Markdown tickets with explicit blocking dependencies.
---

# To Tickets

Read [the local workflow and ticket template](../workflow.md), the intended spec, and existing tickets. If only conversation context exists, use [to-spec](../to-spec/SKILL.md) to persist the source first. Do not invent material product requirements.

Write one file per ticket in the feature's `tickets/` directory. Prefer small end-to-end slices, each independently verifiable, with concrete acceptance criteria referencing spec AC IDs, verification, and only genuine blockers. Include prerequisite refactoring only when necessary. Broad migrations may use compatible expansion, migration batches, and final removal.

Check all spec acceptance criteria are covered, with no unrelated scope. Validate dependency targets and cycles. Link tickets from the spec. Preserve existing IDs and completed work; avoid duplicates.

Write the breakdown directly when scope is clear. Ask about consequential ambiguity, not routine sizing approval. Report paths, dependency order, and unresolved blockers. Do not implement unless requested.
