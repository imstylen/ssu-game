# 02: Transactional campaign persistence and migration
Spec: [Campaign spec](../spec.md)
Status: done
Blocked by: [01](01-route-model.md)

## Outcome
Persist campaign version, completed route, and commitment without replacing decks. Gate changes on successful writes, retain invalid campaign data for explicit reset, and preserve historical migration boundaries.

## Acceptance criteria
- [x] Persist campaign version, completed route, and commitment without replacing decks. Gate changes on successful writes, retain invalid campaign data for explicit reset, and preserve historical migration boundaries. (AC9, AC10, AC11, AC13)

## Verification
Test round trips, legacy/custom decks, unsupported data, initialization, reset, and injected write failures.

## Completion notes

Reviewed transactional replacement, rollback, migration boundaries, and invalid-data retention. Godot 4.7.2: all 250 campaign checks pass; full suite 556/557 with the previously identified copy assertion only. Disk round trips use a disposable profile, including real file replacement.
