# Card Expansion
Status: done

## Problem and intended outcome

Access Allies has 12 cards (7 allies, 5 one-shots) whose behavior runs only when played, using five primitive effects. Deck building has few meaningful choices. Expand the collection to **50 cards** (38 new) with interesting, synergistic mechanics, while keeping the game's warm, respectful portrayal of disabled and neurodivergent animal allies.

Current evidence: [card definition](../../../cards/card_definition.gd), [card behaviors](../../../cards/behaviors/), [action resolver](../../../battle/action_resolver.gd), [effect context](../../../battle/effects/effect_context.gd), [spread board damage](../../../battle/rules/spread_board_damage_policy.gd), [battle rules](../../../battle/rules/battle_rules.tres), [card catalog](../../../autoload/card_catalog.gd), [content tests](../../../tests/test_runner.gd). Everything below except the existing 12 cards and five effects is new behavior.

## Scope and non-goals

Include:
- 38 new collectible cards, roughly 60% allies and 40% one-shots. The roster is defined in [roster.md](roster.md) and needs user approval.
- Battle trigger hooks: round start, knocked out, another card played, and round end, alongside the existing on-play hook.
- Five keywords: Guard, Shield N, Quick, Calm N, Exposed N.
- New primitive effects needed by the approved roster.
- A Calm/Exposed status badge on the enemy panel.
- Light rebalancing or reworks of existing cards, keeping their IDs.
- Placeholder 1024×1024 PNG art generated from Python-authored SVG, with the generator sources kept in `tools/card_art/`.

Exclude:
- Player targeting UI. Every effect targets automatically.
- Multiple enemies.
- Non-collectible tokens or generated cards that aren't in the album.
- Unlocks or rewards. Every card is available immediately.
- Starter deck changes.
- Changes to enemies or their patterns.
- Keyword icons.
- Balance simulators.
- Final art.

## Intended behavior

### Trigger hooks

`CardBehavior` gains overridable hooks that receive an `EffectContext` and the card's `CardInstance`:

| Hook | Fires for | When |
| --- | --- | --- |
| `on_played` (existing) | the played card | during play, before an ally enters the Ally Circle |
| `on_round_start` | each ally in the Ally Circle | at the start of the player round, after the draw and before automatic ally help |
| `on_card_played` | each *other* ally in the Ally Circle | after another card finishes resolving its play, including entering the circle |
| `on_round_end` | each ally in the Ally Circle | when the player ends the round, before the enemy acts |
| `on_knocked_out` | the knocked-out ally | after it leaves the Ally Circle |

Allies trigger in Ally Circle order, left to right. Iterate over a snapshot of the circle, skipping allies that have left it. Stop resolving as soon as the battle ends. Triggered effects never play cards, so a trigger cannot cascade into another `on_card_played`.

### Keywords

Keywords and statuses live in battle state (`CardInstance`, `EnemyInstance`), never in shared definitions.

- **Guard** (ally property): board damage spreads only across Guard allies while any remain. Leftover damage then spreads across the other allies, and only after that spills to the player under the existing overflow rule.
- **Shield N** (ally status): absorbs up to N damage to that ally before its Heart is reduced, and is used up as it absorbs. It persists while the ally stays in the circle and clears when the card is redrawn. Multiple grants add together.
- **Quick** (ally property): the ally can help (attack) on the round it is played.
- **Calm N** (enemy status): reduces the damage of the enemy's next damaging action by N, to a minimum of 0. Grants stack, and the whole stack is used up by that action.
- **Exposed N** (enemy status): the next instance of damage to the enemy deals +N. Grants stack, and the whole stack is used up by that instance. This applies to ally help and to one-shot damage.

### Primitive effects

Existing: damage enemy, heal enemy, damage unit, damage board, heal all allies, damage player, heal player, draw, gain Spark, modify ally Power, copy a card already in the battle into hand.

New, as required by the approved roster:
- grant Shield
- apply Calm
- apply Exposed
- heal one ally
- bank Spark for the next round
- scaled amounts (× allies in the circle, × enemy Exposed)
- a one-shot/ally filter on `on_card_played`

Each effect auto-selects its target (for example this ally, the lowest-Heart ally, the newest ally, or all allies). Any further primitives must be declared in roster.md before implementation.

### Presentation

The enemy panel shows active statuses as a text badge, such as `Calm 2 · Exposed 3`, and hides it when both are 0. Card descriptions put rules first (keywords, then effect), followed by at most one short flavor sentence, up to 110 characters. Battle events are emitted for new state changes so that the existing UI refresh and popup code can show them.

### Content and art

Each new card has:
- a stable snake_case ID
- a `.tres` file in `cards/definitions/<id>/`
- an existing `CardVisualStyle` (berry, lavender, mint, peach or sky)
- a 1024×1024 PNG placeholder

Art is flat-vector SVG generated by Python scripts in `tools/card_art/` and rendered to PNG with `resvg-py`. If that's unavailable, it's rendered with Godot's `Image.load_svg_from_string`. Placeholder quality is acceptable, but each image must clearly read as its subject.

## Acceptance criteria

- [x] AC1: The catalog contains exactly 50 unique, validating cards: the 12 existing cards plus the 38 new ones from the approved roster. Each has a name, rules text up to 110 characters, a style, and 1024×1024 artwork.
- [x] AC2: Existing card IDs are unchanged. Saved decks and the starter deck still load and validate.
- [x] AC3: `on_round_start`, `on_card_played`, `on_round_end` and `on_knocked_out` fire at the times, for the cards, and in the order defined above. Tests cover each hook.
- [x] AC4: Guard, Shield, Quick, Calm and Exposed behave as defined, including stacking, consumption, spill-over and reset on redraw. Each is covered by tests.
- [x] AC5: Every new primitive and every new card behavior has a test showing its effect.
- [x] AC6: A scripted acceptance test plays every one of the 50 cards against each enemy, and each battle resolves without errors or invalid state.
- [x] AC7: The enemy panel shows the Calm/Exposed badge and updates it during battle.
- [x] AC8: The new cards appear in the album and deck builder and can be added to decks under the existing deck rules.
- [x] AC9: The art generator sources live in `tools/card_art/` and reproduce every placeholder PNG. A contact sheet of all new art has been reviewed.
- [x] AC10: The longest descriptions and the enemy badge were checked visually in the running game with no text overflow.
- [x] AC11: Keywords are recorded in `GLOSSARY.md`.

## Decisions and constraints

- Decisions were settled in the design interview on 2026-11-24:
  - 50 cards in total, so 38 new
  - the hook set and keyword rules above
  - no targeting UI
  - light reworks of existing cards allowed, keeping their IDs
  - all cards available immediately, with the starter deck unchanged
  - representation guidance
  - parallel art subagents, while mechanics are implemented sequentially
- Representation: allies are disabled or neurodivergent animals portrayed as capable and supported, with no "cure", pity or "overcoming disability" framing. One-shots are accommodations, assistive technology, support, self-care and allyship.
- The battle rules stay unchanged: 5 Spark per round, a 20-card deck, 2 copies per card, 5 allies in the circle.
- Game rules stay independent of the UI, as in `AGENTS.md`. Statuses are mutable battle state.
- Art subagents write only to `tools/card_art/` and to new card art folders. Mechanics and `.tres` integration happen sequentially in the main checkout.
- Signing Deer currently deals an undisclosed 10 damage on play. Fix or disclose it as part of the existing-card reworks.

## Verification

Run headless with the Godot 4.7.2 console binary:
- `--headless --import`, then the test runner (`res://tests/test_runner.gd`), then `-- --smoke-test`.

Update `_test_content_resources` to the 50-card roster. Check AC7 and AC10 visually in the running game or with captures. Check the art by rendering a contact sheet and reviewing it.

### Results (2026-11-24)

- Headless (Godot 4.7.2): TESTS_OK with 2184 assertions, up from a baseline of 916. SCENE_SMOKE_OK.
- Non-headless captures covered the battle status badge and Shield footers, a hover preview of the longest description, the album and the deck builder. There was no overflow.
- `python tools/card_art/build.py` reproduces all 38 PNGs pixel-identically.
- Starter-deck campaign simulation (50 seeds per node):

  | Node | Before | After |
  | --- | --- | --- |
  | petting_meadow | 50/50 | 50/50 |
  | goat_paddock | 50/50 | 36/50 |
  | llama_pen | 49/50 | 38/50 |
  | eagle_aviary | 36/50 | 6/50 |
  | gremlin_gate | 27/50 | 6/50 |

  The drop is mainly the approved Signing Deer rework, which removed its hidden 10 damage. The simulated player also never clicks Quick allies or plans around Exposed. Starter-deck tuning is out of scope and is noted for follow-up.

### Follow-up: starter deck refresh (2026-11-24, user request)

The user asked for a better starter after the results above, which supersedes the "starter deck unchanged" scope line. The new `ACCESS_ALLIES_STARTER_IDS` replaces Autistic Axolotl, Prosthetic-Paw Puppy and Cup of Tea with Tablet-Talking Tapir, Walker Wombat and Quiet Room. Schema 5 migration refreshes only an untouched previous starter.

Candidates were compared on the sample route with two simulated players: the test-suite player, which only plays cards, and a realistic player, which also clicks ready allies. The chosen deck wins 50/50/48/26/27 with the test-suite player (boss back at the original 27/50). With the realistic player it wins 50/50/49/37/35.

Decks with Brace-Wearing Badger won 50/50 at every node, because cards are the scarce resource. Badger looks overtuned (consider draw 1); it was left unchanged pending a decision. TESTS_OK 2190, SCENE_SMOKE_OK. A player guide is at [docs/player-guide.md](../../player-guide.md).

## Open questions

None. The roster was approved on 2026-11-24 with review edits A–D. Quick means "ready to help (clickable) the round it is played". The three primitives in roster.md §2 (scaled amounts, banked Spark, the `on_card_played` filter) were accepted.

## Tickets

1. [01 Trigger hooks and data-driven card effects](tickets/01-triggers-and-effects.md)
2. [02 Keywords and statuses](tickets/02-keywords-and-statuses.md), blocked by 01
3. [03 Status presentation](tickets/03-status-presentation.md), blocked by 02
4. [04 Placeholder art](tickets/04-placeholder-art.md), run by parallel subagents
5. [05 Card content and reworks](tickets/05-card-content.md), blocked by 02 and 04
6. [06 Glossary and visual check](tickets/06-glossary-and-visual-check.md), blocked by 03 and 05
