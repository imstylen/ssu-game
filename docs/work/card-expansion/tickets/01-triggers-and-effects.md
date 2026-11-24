# 01: Trigger hooks and data-driven card effects
Spec: [Card Expansion](../spec.md)
Status: done
Blocked by: none

## Outcome
`CardBehavior` exposes `on_round_start`, `on_round_end`, `on_knocked_out` and `on_card_played`. The resolver fires them at the times and in the order the spec defines. A data-driven `TriggeredCardBehavior` holds `CardEffect` lists per hook. It supports the one-shot/ally filter on `on_card_played`, scaled amounts (allies in the circle, enemy Exposed) and banked Spark.

## Acceptance criteria
- [x] Each hook fires for the right cards, in Ally Circle order, and stops when the battle ends (AC3).
- [x] `on_card_played` skips the played card itself, respects its filter, and fires after the played card has resolved (AC3).
- [x] Every effect kind (damage, heal player/ally/all, draw, gain/bank Spark, Power, copy to hand) and both scales have tests (AC5).

## Verification
Domain tests in `tests/test_runner.gd`.

## Completion notes
Added `CardBehavior` hooks, `TriggeredCardBehavior`, `CardEffect` (kinds, auto targets, scales), banked Spark, and resolver hook dispatch (`battle/action_resolver.gd`). Hooks iterate over a snapshot of the circle in order and stop when the battle ends. Tests are in `tests/card_mechanics_tests.gd` (hook order and timing, filters, scales, banked Spark, shared single-ally pick, simple effects). Full suite: TESTS_OK 2184 assertions (Godot 4.7.2 headless).
