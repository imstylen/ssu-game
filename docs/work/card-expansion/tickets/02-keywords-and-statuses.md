# 02: Keywords and statuses
Spec: [Card Expansion](../spec.md)
Status: done
Blocked by: [01](01-triggers-and-effects.md)

## Outcome
Adds the Guard and Quick definition flags, Shield as an ally status, and Calm and Exposed as enemy statuses, along with Shield, Calm and Exposed effects, with the behavior the spec defines.

## Acceptance criteria
- [x] Guard: board damage spreads across Guard allies first, then the others, then the player (AC4).
- [x] Shield: absorbs damage, stacks, and resets on redraw (AC4).
- [x] Quick: the ally is ready to help the round it is played (AC4).
- [x] Calm: reduces only the enemy's next damaging action, stacks, and is used up (AC4).
- [x] Exposed: adds to the next instance of enemy damage, stacks, and is used up (AC4).

## Verification
Domain tests in `tests/test_runner.gd`.

## Completion notes
Guard (`cards/card_definition.gd`, `battle/rules/spread_board_damage_policy.gd`), Shield (`CardInstance.shield`, absorbed in `apply_unit_damage`, reset on draw and knock-out), Quick (play readiness), Calm (`EnemyInstance.calm`, spent in `DamageBoardAction` and `DamagePlayerAction` through `reduce_enemy_damage_by_calm`), and Exposed (`EnemyInstance.exposed`, spent in `apply_enemy_damage`). Covered by keyword tests in `tests/card_mechanics_tests.gd`. TESTS_OK 2184.
