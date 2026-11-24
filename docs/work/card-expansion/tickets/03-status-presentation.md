# 03: Status presentation
Spec: [Card Expansion](../spec.md)
Status: done
Blocked by: [02](02-keywords-and-statuses.md)

## Outcome
The enemy panel shows a Calm/Exposed badge. Allies in the circle show Shield and keywords. The battle log reports status changes.

## Acceptance criteria
- [x] The badge appears with the current values and is hidden when both are 0 (AC7).
- [x] An ally's Shield value is visible in the circle (AC4 presentation).

## Verification
Smoke test, plus a visual check in the running game or a capture.

## Completion notes
`battle/battle_ui.gd`: a `MonsterStatusBadge` label ("CALM 3 · EXPOSED 4", hidden when both are 0), Shield in the ally footer ("SHIELD 3 • READY TO HELP"), log lines for the new events, and a pulse on status change. The text helpers are unit-tested. A non-headless capture at 1600×900 showed the badge and footers with no overflow. SCENE_SMOKE_OK.
