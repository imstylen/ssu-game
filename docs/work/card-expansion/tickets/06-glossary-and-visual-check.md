# 06: Glossary and visual check
Spec: [Card Expansion](../spec.md)
Status: done
Blocked by: [03](03-status-presentation.md), [05](05-card-content.md)

## Outcome
`GLOSSARY.md` defines the keywords and hooks. The longest card texts and the enemy badge have been checked visually.

## Acceptance criteria
- [x] Glossary entries exist for Guard, Shield, Quick, Calm, Exposed (AC11).
- [x] There's no text overflow on the longest descriptions or on the badge (AC10).

## Verification
Captures from a non-headless run.

## Completion notes
`GLOSSARY.md` has entries for Guard, Shield, Quick, Calm and Exposed, and the README documents the keywords and card authoring. Visual captures (battle with statuses, a hover preview of the longest 108-character description, the album, the deck builder) showed no text overflow. Long card names are truncated with an ellipsis in the compact view, which matches existing behavior.
