---
name: initial-setup
description: Inspect a repository and create or update grounded AGENTS.md guidance for its development workflow.
---

# Initial Setup

Read [the local workflow](../workflow.md).

Inspect root and nested agent instructions, working-tree state, README, manifests, lockfiles, CI, source layout, and tests. Discover facts yourself. Distinguish an empty project from an existing application.

Create or merge root `AGENTS.md` covering purpose, architecture pointers, package manager, existing setup/build/test/lint/typecheck commands, and important conventions. Preserve useful existing guidance and nested scopes. Label inferred commands unverified until run; never invent commands or install dependencies just to document them.

Document available skills, fixed spec/ticket paths, and execution defaults. Link the shared contract from the generated root document as `.agents/skills/workflow.md`. Create supporting docs only when there is concrete content. Do not choose a stack, scaffold an application, replace tooling, or create placeholder ADRs. Suggest missing tooling separately. Report changed files, verified commands, and unresolved setup decisions.
