# 01: Authored graph, independent variants, and route rules
Spec: [Campaign spec](../spec.md)
Status: done
Blocked by: none

## Outcome
Implement the eleven-node definition and pure progress model. Validate routes and derive available, locked, skipped, and completed states; commitment and victory are explicit and idempotent.

## Acceptance criteria
- [x] Implement the eleven-node definition and pure progress model. Validate routes and derive available, locked, skipped, and completed states; commitment and victory are explicit and idempotent. (AC2, AC3, AC4, AC5, AC7, AC9, AC11)

## Verification
Run graph, all-route, invalid-save, merge, commitment, and variant immutability tests.

## Completion notes

Implemented CampaignDefinition and CampaignProgress, reviewed graph traversal, validation, idempotency, and resource duplication. Godot 4.7.2: 228 campaign assertions pass; full suite 534/535, with pre-existing TEAM HEART copy assertion failing (also reproduced before implementation). No campaign model failures.
