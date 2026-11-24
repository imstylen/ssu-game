# 05: Card content and reworks
Spec: [Card Expansion](../spec.md)
Status: done
Blocked by: [02](02-keywords-and-statuses.md), [04](04-placeholder-art.md)

## Outcome
Adds 38 new `.tres` definitions matching [roster.md](../roster.md) and applies the approved reworks to existing cards. The content tests are updated to cover all 50 cards, and every card is played in scripted battles.

## Acceptance criteria
- [x] The catalog has 50 validating cards with art, styles, and descriptions up to 110 characters (AC1).
- [x] Existing IDs are unchanged, and the starter deck and saved decks validate (AC2).
- [x] Each new card behavior is tested (AC5), and an acceptance test plays every card against each enemy (AC6).
- [x] The cards appear in the album and deck builder (AC8).

## Verification
Test runner and smoke test.

## Completion notes
Godot's ResourceSaver generated 38 `.tres` files from the approved roster. Reworks applied: Deer 3/4 with Exposed 2 (hidden 10 damage removed; uid kept), Guard on Rabbit and Puppy, Calm 1 at round end on Alpaca, Red Panda 2/1 with Quick, rules-first text on the five one-shots. `tests/card_content_tests.gd` covers the definitions, a scenario for each card (all 38 plus the reworks), every card played against each enemy, and whole-collection battles with invariant checks. The album and deck builder captures show the new cards. TESTS_OK 2184. Limitation: the starter-deck campaign simulation's win rates dropped (boss 27/50 → 6/50), mainly because Deer lost its hidden damage. Only `wins > 0` is asserted, and that still passes.
