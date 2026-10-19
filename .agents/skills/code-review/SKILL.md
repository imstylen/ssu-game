---
name: code-review
description: Review a bounded code change for defects, local requirements coverage, and documented repository conventions.
---

# Code Review

Read [the local workflow](../workflow.md). Establish scope from the request, implementation context, or Git state. Include staged, unstaged, and relevant untracked files for checkout work. For branch review, verify the comparison base and inspect the full diff. Do not assume commits are the entire scope. Report an empty scope honestly.

Read surrounding code, tests, repo instructions, standards, and relevant local spec/tickets. Without a spec, review against the stated task and disclose the coverage limitation. Ask only if scope cannot be determined safely.

Review correctness, regressions, error handling, relevant security risks, and test gaps. Assess requirements and documented conventions separately. Prioritize demonstrated issues over speculative abstractions or taste. Repository conventions take precedence; avoid duplicating lint output as substantive review.

Report actionable findings by severity, with file/line evidence, triggering scenario, impact, and suggested direction. Identify correctness, requirements, or convention concerns. State when no findings were found and disclose checks not run and coverage gaps. A clean review does not prove correctness.

Standalone review is read-only unless fixes are requested. When called by implementation, return findings to that workflow for correction. No subagents, commits, or publishing are required.
