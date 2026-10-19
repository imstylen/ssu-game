# 03: Explicit campaign battle entry and results
Spec: [Campaign spec](../spec.md)
Status: done
Blocked by: [02](02-profile-persistence.md)

## Outcome
Start fresh battles with the selected deck and exact committed variant. Save victory once; provide retry, retreat, and campaign results while isolating standalone battles.

## Acceptance criteria
- [x] Start fresh battles with the selected deck and exact committed variant. Save victory once; provide retry, retreat, and campaign results while isolating standalone battles. (AC4, AC6, AC8, AC9, AC11, AC13)

## Verification
Run battle setup, deck switching, save failure, duplicate victory, and standalone isolation tests.

## Completion notes

Reviewed explicit context, standalone clearing, save gating, and duplicate notifications. Godot 4.7.2 lifecycle tests pass, including actual battle scene setup, edited deck, defeat, save retry, and standalone isolation. Full suite 564/565; only pre-existing TEAM HEART copy assertion remains.
