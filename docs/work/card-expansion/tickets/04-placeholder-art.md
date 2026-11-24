# 04: Placeholder art for 38 new cards
Spec: [Card Expansion](../spec.md)
Status: done
Blocked by: none

## Outcome
Each new card has a 1024×1024 PNG at `cards/definitions/<id>/<id>.png`, generated from `tools/card_art/cards/<id>.py`. Five parallel art subagents produce them, and the result is reviewed on contact sheets.

## Acceptance criteria
- [x] All 38 PNGs exist at 1024×1024 and are reproducible with `python tools/card_art/build.py` (AC9).
- [x] A contact sheet has been reviewed, and unreadable art has been reworked (AC9).

## Verification
Render the contact sheet and review it by eye.

## Completion notes
Five parallel subagents wrote `tools/card_art/cards/<id>.py` using the shared `art_lib.py` and `build.py` (resvg-py). All 38 cards were reviewed on combined contact sheets. Weaker but readable: Tripod Tiger (the three legs aren't obvious), Tablet-Talking Tapir (the snout reads as a trunk), Flexible Deadline (abstract). A re-render of all 38 is pixel-identical to the shipped PNGs. Added `tools/.gdignore` so Godot doesn't import the SVG sources.
