---
name: domain-modeling
description: Clarify domain terminology and record settled definitions and consequential architecture decisions in local Markdown.
---

# Domain Modeling

Read existing glossary entries and decisions first. Challenge overloaded terms and contradictions between intent, docs, and code using concrete examples. Distinguish intended behavior from current implementation.

Write settled terms to root `GLOSSARY.md`: term, plain-language definition, and a useful clarifying example. Keep implementation plans out. Preserve established organization and link context-specific glossaries rather than duplicating them.

Create `docs/adr/NNNN-<slug>.md` only for settled decisions with real alternatives, meaningful reversal cost, and context future maintainers would miss. Include title, date, status, context, decision, alternatives, and consequences. Use the next unused number; link superseding decisions instead of silently rewriting history.

Create files lazily. Unresolved proposals are not accepted decisions. Routine implementation details belong in specs or tickets.
