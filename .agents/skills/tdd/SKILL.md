---
name: tdd
description: Implement behavior changes with focused test-first cycles at observable interfaces when automated tests are useful.
---

# Tdd

Choose existing public interfaces and repository test conventions. Explain consequential testing choices; routine test boundaries need no separate permission.

For each useful behavior slice, write a focused failing test, confirm the expected failure, implement enough to pass, then simplify while preserving behavior. Reproduce bugs when feasible. Expected results come from requirements or independent worked examples, not copied implementation logic.

Prefer observable behavior over private methods, internal call counts, or mocks of internal collaborators. Mock external boundaries when necessary. Avoid tests that merely mirror implementation or assert static wording. Documentation and low-impact configuration changes can use direct validation instead of new tests.

Run targeted checks during work and relevant broader checks at completion. Distinguish existing failures from regressions. If tests cannot run, disclose why and use available verification without claiming TDD or passing tests.
