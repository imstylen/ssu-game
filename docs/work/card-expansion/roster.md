# Card Expansion Roster
Status: approved (2026-11-24, with review edits A-D applied)

Proposal for 38 new cards (23 allies, 15 one-shots), bringing the collection to 50. All effects auto-target; no player targeting is introduced. Grounded in `battle/action_resolver.gd`, `battle/rules/battle_rules.tres`, `battle/rules/spread_board_damage_policy.gd`, `battle/effects/effect_context.gd`, the 12 cards in `cards/definitions/`, and the three enemies in `enemies/definitions/`.

## 1. Archetypes overview

Design reality check: each round brings 5 Spark but only 1 new card (hand starts at 3). **Cards, not Spark, are the scarce resource**, so card draw is valued highly and Spark gain is a light secondary resource. Battles last roughly 4-6 rounds against 26-34 Heart enemies dealing about 5 board damage per round, so round-based engines get about 3-4 triggers.

| Archetype | Plan | Key new cards | Bridges to |
| --- | --- | --- | --- |
| **Protectors** (Guard / Shield) | Guard allies soak the 1-point-at-a-time board damage; Shield makes them last. Keeps fragile high-Power allies alive. | Walker Wombat, Tripod Tiger, Deaf Elephant, Worry-Wise Pangolin, Forearm-Crutch Flamingo, Build a Ramp, Service Dog Help | Pass It On (Guard allies with knock-out effects fall first by design), Slow & Steady |
| **One-Shot Engine** (`on_card_played`) | Cheap one-shots trigger allies already in the Ally Circle: pings, Exposed, Calm, growing Power. | Tablet-Talking Tapir, Cane-Tapping Kiwi, Noise-Cancelling Narwhal, Stuttering Starling, Stim Toy, Captions On | Spoons (draw keeps the engine fed), Setup & Burst (Kiwi), Slow & Steady (Narwhal) |
| **Setup & Burst** (Exposed) | Stack Exposed, then cash it with one big damage instance (Accessibility Audit, Pride March, Team-Captain Otter, Quick Cheetah, or the first auto-helper). Signal Boost doubles the stack. | Call It Out, Signal Boost, Captions On, Magnifier Meerkat, Racing-Chair Cheetah, Accessibility Audit | Together (Pride March / Otter are single big instances), One-Shot Engine |
| **Slow & Steady** (Calm + sustain) | Blunt the enemy's spike rounds (Blob's 8, Gremlin's 7) with Calm timed to the visible pattern; heal what gets through. | Quiet Room, Flexible Deadline, Weighted Blanket, Safety-Plan Seal, Buddy-Bird Capybara, Sun-Seeking Lemur, Insulin-Pump Iguana | Protectors, One-Shot Engine (Narwhal) |
| **Pass It On** (`on_knocked_out`) | Allies that leave a gift when the barrier knocks them out: cards, Power, Shield, Exposed, or a fresh copy. | Brace-Wearing Badger, Dyspraxic Dolphin, Hearing-Aid Hedgehog, Tripod Tiger, Invite a Friend | Protectors (Guard decides who falls first), Together |
| **Spoons** (draw / Spark / cheap cards) | Refill the hand and smooth Spark so two or three cards land in one round, including the 5-cost allies. | Calculator Crow, Spoon-Saving Squirrel, Spoon Theory, Stim Toy | Everything; especially One-Shot Engine |
| **Together** (go-wide) | Fill the Ally Circle, then scale with ally count and Power buffs. | Team-Captain Otter, Tourette's Toucan, Pride March, Celebrate Wins, Pass the Mic, Invite a Friend | Setup & Burst, Protectors (a wide circle needs protecting) |

Key interactions and tensions:

- **Exposed is consumed by any damage instance**, including Tapir's 1-damage pings and the first auto-helper. Burst decks want few, large instances; engine decks that ping lose Exposed value. This is a deliberate deck-building tension.
- **Guard vs. Pass It On**: putting Guard on knock-out allies (Hedgehog, Tiger) makes their gift arrive sooner; Shield on them delays it. Players choose which they want.
- **Calm is timing play**: enemy patterns are visible and repeat, so Calm 5 before Barrier Blob's 8 is strong, while Calm before its 2 is mostly wasted.
- **Quick + Exposed**: setting up Exposed and then playing Racing-Chair Cheetah (or reworked ADHD Red Panda) cashes it in the same round.

## 2. New primitives requested

Three small additions; everything else uses the agreed hooks, primitives, and keywords.

1. **Scaled amount (X)**: an effect's amount may be `N × X`, where X is read once at resolution and is one of:
   - `allies_in_circle`: allies currently in the Ally Circle. An ally's own `on_played` resolves before it joins (matches `play_card` in `action_resolver.gd`), so it counts only *other* allies.
   - `enemy_exposed`: the enemy's current Exposed stack.
   Used by: Team-Captain Otter, Pride March (ally count); Signal Boost (enemy Exposed).
2. **Bank Spark N** ("Next round, gain N Spark"): adds N to a battle-scoped pending counter. At the start of the next player round, after Spark resets to `energy_per_turn`, gain the pending amount and clear it. Cleared when the battle ends; never persists across battles. Used by: Spoon Theory.
3. **`on_card_played` card-type filter** (hook parameter, not a new effect): `any` (default), `one_shot`, or `ally`. The hook never fires for the card itself and fires *after* the played card fully resolves (a played ally is already in the Ally Circle and is the newest ally; a played one-shot is already discarded). Used by: Tapir, Kiwi, Narwhal (one-shot), Toucan (ally), Starling (any).

Settled: **Quick** means the ally is ready to help the round it is played: the player can click it in the Ally Circle ("READY TO HELP") to help immediately, so Exposed can be set up first. It does not attack automatically on entry. Cards relying on this: Racing-Chair Cheetah, reworked ADHD Red Panda.

Effect resolution notes used below: `lowest_heart_ally` / `newest_ally` are chosen once per effect line and reused for every clause on that line (ties: earliest in the Ally Circle). An effect whose target is missing (for example, no allies) does nothing; other clauses still resolve. Shield and Power changes only apply to allies currently in the Ally Circle.

## 3. Proposed reworks of existing cards

IDs, names, art, and styles unchanged.

| id | Name | Change | Proposed description | Reason |
| --- | --- | --- | --- | --- |
| `deaf_deer` | Signing Deer | Remove the hidden `DamageEnemyBehavior` (`damage_amount = 10`). New: 3c **3/4**, `on_played`: Exposed 2. | "When played: Exposed 2. Deer signs the plan so the whole team hits together." (76) | Balance bug: a 3-cost 4/4 that also deals an unlisted 10 damage (a third of an enemy's Heart). The fix keeps a play-time effect but makes it visible, smaller, and part of Setup & Burst. |
| `shield_bot` | Rolling Rabbit | Add **Guard**. Stats unchanged (2c 2/5). | "Guard. A custom chair and a clever route help Rabbit keep the whole crew safe." (78) | Flavor already says "keep the whole crew safe"; gives Protectors an early Guard at 2 cost. |
| `prosthetic_paw_puppy` | Prosthetic-Paw Puppy | Add **Guard**. Stats unchanged (4c 4/7). | "Guard. A springy prosthetic paw makes Puppy a sturdy, playful protector." (72) | Flavor already says "protector"; 4/7 body suits the role. |
| `grounding_alpaca` | Grounding Alpaca | Add `on_round_end`: Calm 1. Stats unchanged (2c 1/6). | "End of round: Calm 1. Alpaca pauses, breathes, and helps the crew feel steady." (78) | A 1-Power vanilla ally is rarely worth a card; makes it the entry point to Slow & Steady. |
| `adhd_red_panda` | ADHD Red Panda | Add **Quick**; Heart 2 -> **1** (1c 2/1). | "Quick. Red Panda turns a burst of ideas into joyful momentum." (61) | Flavor is about momentum; Quick at 1 cost is a cheap Exposed cash-in. Heart trimmed to pay for Quick. |
| `arc_bolt / life_drain / low_vision_lynx / rally / take_a_nap` | Speak Up!, Cup of Tea, Meditate & Plan, Rally, Take a Nap | Text only: move rules text first (e.g. Speak Up!: "Deal 4 damage. A clear, supported voice can crack a stubborn barrier."). Numbers unchanged. | (per card) | Consistency with the new description format. Note: Take a Nap spends a card for Spark, which is rarely the bottleneck; consider "Gain 2 Spark. Draw 1 card." later if playtests show it never gets played. |

Unchanged: `autistic_axolotl` (3/3) and `dyslexic_duckling` (5/3) stay vanilla as legible baselines; the Duckling is the natural beneficiary of Protectors and Calm.

## 4. Summary table

| # | id | Name | Type | Cost | P/H | Keywords | Hooks | Style |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `hearing_aid_hedgehog` | Hearing-Aid Hedgehog | Ally | 1 | 1/3 | Guard | on_knocked_out | sky |
| 2 | `spoon_saving_squirrel` | Spoon-Saving Squirrel | Ally | 1 | 1/2 | - | on_round_start | mint |
| 3 | `forearm_crutch_flamingo` | Forearm-Crutch Flamingo | Ally | 2 | 2/3 | - | on_played | berry |
| 4 | `tablet_talking_tapir` | Tablet-Talking Tapir | Ally | 2 | 1/4 | - | on_card_played | lavender |
| 5 | `stuttering_starling` | Stuttering Starling | Ally | 2 | 1/3 | - | on_card_played | sky |
| 6 | `cane_tapping_kiwi` | Cane-Tapping Kiwi | Ally | 2 | 1/4 | - | on_card_played | peach |
| 7 | `magnifier_meerkat` | Magnifier Meerkat | Ally | 2 | 2/3 | - | on_round_start | sky |
| 8 | `sun_seeking_lemur` | Sun-Seeking Lemur | Ally | 2 | 1/4 | - | on_round_start | peach |
| 9 | `safety_plan_seal` | Safety-Plan Seal | Ally | 2 | 2/3 | - | on_played | mint |
| 10 | `brace_wearing_badger` | Brace-Wearing Badger | Ally | 2 | 2/3 | - | on_knocked_out | lavender |
| 11 | `dyspraxic_dolphin` | Dyspraxic Dolphin | Ally | 2 | 2/2 | - | on_knocked_out | sky |
| 12 | `calculator_crow` | Calculator Crow | Ally | 3 | 1/4 | - | on_played | lavender |
| 13 | `walker_wombat` | Walker Wombat | Ally | 3 | 2/5 | Guard | on_played | peach |
| 14 | `worry_wise_pangolin` | Worry-Wise Pangolin | Ally | 3 | 2/4 | - | on_round_end | mint |
| 15 | `noise_cancelling_narwhal` | Noise-Cancelling Narwhal | Ally | 3 | 2/5 | - | on_card_played | sky |
| 16 | `team_captain_otter` | Team-Captain Otter | Ally | 3 | 2/3 | - | on_played | berry |
| 17 | `tourettes_toucan` | Tourette's Toucan | Ally | 3 | 2/4 | - | on_card_played | peach |
| 18 | `insulin_pump_iguana` | Insulin-Pump Iguana | Ally | 2 | 2/3 | - | on_round_start | mint |
| 19 | `oxygen_owl` | Oxygen Owl | Ally | 3 | 2/4 | - | on_played | lavender |
| 20 | `buddy_bird_capybara` | Buddy-Bird Capybara | Ally | 4 | 2/6 | - | on_round_end | mint |
| 21 | `tripod_tiger` | Tripod Tiger | Ally | 4 | 3/6 | Guard | on_knocked_out | berry |
| 22 | `racing_chair_cheetah` | Racing-Chair Cheetah | Ally | 5 | 5/3 | Quick | none | peach |
| 23 | `deaf_elephant` | Deaf Elephant | Ally | 5 | 4/8 | Guard | on_played | sky |
| 24 | `stim_toy` | Stim Toy | One-shot | 0 | - | - | on_played | lavender |
| 25 | `captions_on` | Captions On | One-shot | 1 | - | - | on_played | sky |
| 26 | `call_it_out` | Call It Out | One-shot | 1 | - | - | on_played | berry |
| 27 | `signal_boost` | Signal Boost | One-shot | 1 | - | - | on_played | peach |
| 28 | `accessibility_audit` | Accessibility Audit | One-shot | 3 | - | - | on_played | mint |
| 29 | `pride_march` | Pride March | One-shot | 3 | - | - | on_played | berry |
| 30 | `celebrate_wins` | Celebrate Wins | One-shot | 3 | - | - | on_played | peach |
| 31 | `pass_the_mic` | Pass the Mic | One-shot | 2 | - | - | on_played | lavender |
| 32 | `invite_a_friend` | Invite a Friend | One-shot | 2 | - | - | on_played | mint |
| 33 | `build_a_ramp` | Build a Ramp | One-shot | 2 | - | - | on_played | peach |
| 34 | `service_dog_help` | Service Dog Help | One-shot | 1 | - | - | on_played | sky |
| 35 | `quiet_room` | Quiet Room | One-shot | 2 | - | - | on_played | lavender |
| 36 | `flexible_deadline` | Flexible Deadline | One-shot | 2 | - | - | on_played | mint |
| 37 | `weighted_blanket` | Weighted Blanket | One-shot | 1 | - | - | on_played | lavender |
| 38 | `spoon_theory` | Spoon Theory | One-shot | 1 | - | - | on_played | mint |

## 5. Card details

### 1. Hearing-Aid Hedgehog (`hearing_aid_hedgehog`)

- **Type / cost / stats:** Ally, 1 Spark, 1 Power / 3 Heart (stat total 4 vs. vanilla baseline 4)
- **Keywords:** Guard
- **Archetype:** Pass It On / Protectors
- **Hooks & effect params:**
  - `on_knocked_out` -> `apply_exposed(target=enemy, amount=2)`
- **Description** (93 chars): "Guard. When knocked out: Exposed 2. Hedgehog's hearing aids catch the barrier's rumble first."
- **Style:** sky
- **Representation:** Hard of hearing; wears behind-the-ear hearing aids as an everyday tool.
- **Art brief:** Small round hedgehog standing alert, one paw raised, bright behind-the-ear hearing aids on both ears; sky blue, warm brown, cream; background of soft concentric sound-wave arcs.

### 2. Spoon-Saving Squirrel (`spoon_saving_squirrel`)

- **Type / cost / stats:** Ally, 1 Spark, 1 Power / 2 Heart (stat total 3 vs. vanilla baseline 4)
- **Keywords:** none
- **Archetype:** Spoons
- **Hooks & effect params:**
  - `on_round_start` -> `gain_spark(amount=1)`
- **Description** (94 chars): "Start of round: gain 1 Spark. Squirrel paces their energy and always tucks away a spare spoon."
- **Style:** mint
- **Representation:** Chronic fatigue (ME/CFS) managed with pacing and spoon theory.
- **Art brief:** Squirrel sitting upright hugging an oversized wooden spoon, small satchel of spoons at its side; rust orange, mint, cream; background of scattered acorns and spoons.

### 3. Forearm-Crutch Flamingo (`forearm_crutch_flamingo`)

- **Type / cost / stats:** Ally, 2 Spark, 2 Power / 3 Heart (stat total 5 vs. vanilla baseline 6)
- **Keywords:** none
- **Archetype:** Protectors
- **Hooks & effect params:**
  - `on_played` -> `give_shield(target=all_allies, amount=1)  # resolves before Flamingo joins, so other allies only`
- **Description** (95 chars): "When played: other allies gain Shield 1. Flamingo's crutches set the pace and the flock keeps it."
- **Style:** berry
- **Representation:** Mobility disability (e.g. cerebral palsy) using forearm crutches.
- **Art brief:** Pink flamingo striding confidently on two purple forearm crutches; berry pink, lavender, white; background of gentle water ripples.

### 4. Tablet-Talking Tapir (`tablet_talking_tapir`)

- **Type / cost / stats:** Ally, 2 Spark, 1 Power / 4 Heart (stat total 5 vs. vanilla baseline 6)
- **Keywords:** none
- **Archetype:** One-Shot Engine
- **Hooks & effect params:**
  - `on_card_played [filter=one_shot]` -> `damage_enemy(amount=1)`
- **Description** (96 chars): "Whenever you play a one-shot, deal 1 damage. Tapir's AAC tablet always has the right word ready."
- **Style:** lavender
- **Representation:** Nonspeaking; communicates fluently with an AAC tablet.
- **Art brief:** Tapir sitting and tapping a tablet showing a picture-symbol grid, a speech bubble popping out; charcoal and white tapir, lavender, sunny yellow; background of floating symbol speech bubbles.

### 5. Stuttering Starling (`stuttering_starling`)

- **Type / cost / stats:** Ally, 2 Spark, 1 Power / 3 Heart (stat total 4 vs. vanilla baseline 6)
- **Keywords:** none
- **Archetype:** One-Shot Engine
- **Hooks & effect params:**
  - `on_card_played [filter=any]` -> `modify_power(target=this_ally, amount=+1)`
- **Description** (93 chars): "Whenever you play another card, this ally gains +1 Power. Friends wait, and every word lands."
- **Style:** sky
- **Representation:** Stutters; friends give time instead of finishing sentences.
- **Art brief:** Speckled starling perched mid-song with a calm smile and a trail of musical dots; iridescent navy, sky blue, gold speckles; background of a wire with other birds leaning in to listen.

### 6. Cane-Tapping Kiwi (`cane_tapping_kiwi`)

- **Type / cost / stats:** Ally, 2 Spark, 1 Power / 4 Heart (stat total 5 vs. vanilla baseline 6)
- **Keywords:** none
- **Archetype:** One-Shot Engine / Setup & Burst
- **Hooks & effect params:**
  - `on_card_played [filter=one_shot]` -> `apply_exposed(target=enemy, amount=1)`
- **Description** (92 chars): "Whenever you play a one-shot: Exposed 1. Kiwi's white cane finds every crack in the barrier."
- **Style:** peach
- **Representation:** Blind; navigates confidently with a long white cane.
- **Art brief:** Round brown kiwi bird walking with a red-and-white long cane sweeping ahead; brown, peach, red and white; background of small tap ripples along a path.

### 7. Magnifier Meerkat (`magnifier_meerkat`)

- **Type / cost / stats:** Ally, 2 Spark, 2 Power / 3 Heart (stat total 5 vs. vanilla baseline 6)
- **Keywords:** none
- **Archetype:** Setup & Burst
- **Hooks & effect params:**
  - `on_round_start` -> `apply_exposed(target=enemy, amount=1)  # before auto-help, so the first helper cashes it`
- **Description** (83 chars): "Start of round: Exposed 1. Meerkat's magnifier spots weak spots before anyone else."
- **Style:** sky
- **Representation:** Low vision; uses a handheld magnifier.
- **Art brief:** Meerkat standing tall on lookout, holding a large handheld magnifier up to one eye; sandy tan, sky blue, white lens glint; background of desert dunes and a round sun.

### 8. Sun-Seeking Lemur (`sun_seeking_lemur`)

- **Type / cost / stats:** Ally, 2 Spark, 1 Power / 4 Heart (stat total 5 vs. vanilla baseline 6)
- **Keywords:** none
- **Archetype:** Slow & Steady
- **Hooks & effect params:**
  - `on_round_start` -> `heal_ally(target=lowest_heart_ally, amount=2)`
- **Description** (92 chars): "Start of round: heal the lowest-Heart ally 2. Lemur's light-lamp routine brightens everyone."
- **Style:** peach
- **Representation:** Depression (seasonal); a light-therapy lamp and daily routine are part of their care.
- **Art brief:** Ring-tailed lemur sitting cross-legged, arms open, basking in front of a glowing light-therapy lamp; grey and black stripes, warm peach, soft yellow; background of gentle sun rays.

### 9. Safety-Plan Seal (`safety_plan_seal`)

- **Type / cost / stats:** Ally, 2 Spark, 2 Power / 3 Heart (stat total 5 vs. vanilla baseline 6)
- **Keywords:** none
- **Archetype:** Slow & Steady
- **Hooks & effect params:**
  - `on_played` -> `apply_calm(target=enemy, amount=3)`
- **Description** (82 chars): "When played: Calm 3. Seal shares their seizure plan, so everyone knows what to do."
- **Style:** mint
- **Representation:** Epilepsy; a shared seizure action plan and medical ID.
- **Art brief:** Grey seal sitting up, proudly holding a clipboard checklist, medical-ID band on one flipper; grey, mint, red accent; background of soft waves and an ice floe.

### 10. Brace-Wearing Badger (`brace_wearing_badger`)

- **Type / cost / stats:** Ally, 2 Spark, 2 Power / 3 Heart (stat total 5 vs. vanilla baseline 6)
- **Keywords:** none
- **Archetype:** Pass It On
- **Hooks & effect params:**
  - `on_knocked_out` -> `draw_cards(amount=2)`
- **Description** (86 chars): "When knocked out: draw 2 cards. Badger knows their limits and hands over a great plan."
- **Style:** lavender
- **Representation:** Chronic pain / hypermobility (EDS); joint braces and pacing. Tapping out is a choice, not a failure.
- **Art brief:** Badger in knee and wrist braces holding out a rolled-up plan scroll; black and white, lavender braces, cream; background of a cozy burrow entrance.

### 11. Dyspraxic Dolphin (`dyspraxic_dolphin`)

- **Type / cost / stats:** Ally, 2 Spark, 2 Power / 2 Heart (stat total 4 vs. vanilla baseline 6)
- **Keywords:** none
- **Archetype:** Pass It On
- **Hooks & effect params:**
  - `on_knocked_out` -> `create_copy_in_hand(card=this_card)  # same definition id, already in battle`
- **Description** (90 chars): "When knocked out: add a copy of Dolphin to your hand. The pod always saves Dolphin a spot."
- **Style:** sky
- **Representation:** Dyspraxia (DCD); the pod adapts its routines so Dolphin is always included.
- **Art brief:** Smiling dolphin mid-leap holding a waterproof step-by-step picture card; sky blue, teal, coral; background of a curling wave and bubbles.

### 12. Calculator Crow (`calculator_crow`)

- **Type / cost / stats:** Ally, 3 Spark, 1 Power / 4 Heart (stat total 5 vs. vanilla baseline 8)
- **Keywords:** none
- **Archetype:** Spoons
- **Hooks & effect params:**
  - `on_played` -> `draw_cards(amount=2)`
- **Description** (79 chars): "When played: draw 2 cards. Crow's trusty calculator keeps every count on track."
- **Style:** lavender
- **Representation:** Dyscalculia; uses a calculator as an everyday tool.
- **Art brief:** Glossy crow perched on a branch, one wing tapping a big chunky calculator; blue-black, lavender, lemon yellow; background of softly floating numbers.

### 13. Walker Wombat (`walker_wombat`)

- **Type / cost / stats:** Ally, 3 Spark, 2 Power / 5 Heart (stat total 7 vs. vanilla baseline 8)
- **Keywords:** Guard
- **Archetype:** Protectors
- **Hooks & effect params:**
  - `on_played` -> `give_shield(target=this_ally, amount=3)  # applied as Wombat joins`
- **Description** (89 chars): "Guard. When played: this ally gains Shield 3. Wombat rolls up front with a sturdy walker."
- **Style:** peach
- **Representation:** Mobility disability; walks with a rollator.
- **Art brief:** Stocky wombat standing behind a rollator walker with a basket, determined grin; earthy brown, peach, teal walker; background of eucalyptus leaves.

### 14. Worry-Wise Pangolin (`worry_wise_pangolin`)

- **Type / cost / stats:** Ally, 3 Spark, 2 Power / 4 Heart (stat total 6 vs. vanilla baseline 8)
- **Keywords:** none
- **Archetype:** Protectors
- **Hooks & effect params:**
  - `on_round_end` -> `give_shield(target=lowest_heart_ally, amount=2)  # before the enemy acts`
- **Description** (97 chars): "End of round: the lowest-Heart ally gains Shield 2. Pangolin manages anxiety with a what-if list."
- **Style:** mint
- **Representation:** Anxiety; manages it with checklists and planning, supported by friends.
- **Art brief:** Pangolin holding a long checklist with ticks, overlapping scales drawn like soft armor plates; olive, mint, cream; background of a tidy checkbox pattern.

### 15. Noise-Cancelling Narwhal (`noise_cancelling_narwhal`)

- **Type / cost / stats:** Ally, 3 Spark, 2 Power / 5 Heart (stat total 7 vs. vanilla baseline 8)
- **Keywords:** none
- **Archetype:** One-Shot Engine / Slow & Steady
- **Hooks & effect params:**
  - `on_card_played [filter=one_shot]` -> `apply_calm(target=enemy, amount=1)`
- **Description** (86 chars): "Whenever you play a one-shot: Calm 1. Headphones on, Narwhal stays focused and steady."
- **Style:** sky
- **Representation:** Autistic; noise-cancelling headphones meet sensory needs.
- **Art brief:** Narwhal floating serenely with big over-ear headphones, tusk pointing up; sky blue, navy, lavender; background of quiet bubbles and muted waves.

### 16. Team-Captain Otter (`team_captain_otter`)

- **Type / cost / stats:** Ally, 3 Spark, 2 Power / 3 Heart (stat total 5 vs. vanilla baseline 8)
- **Keywords:** none
- **Archetype:** Together
- **Hooks & effect params:**
  - `on_played` -> `damage_enemy(amount=2 * X, X=allies_in_circle)  # Otter not yet in circle, so counts other allies; one damage instance`
- **Description** (95 chars): "When played: deal 2 damage for each other ally. Otter, who has Down syndrome, leads the huddle."
- **Style:** berry
- **Representation:** Down syndrome; a confident team captain and leader.
- **Art brief:** Otter with Down syndrome features (almond-shaped eyes, wide warm smile) wearing a captain armband, paws raised in a team cheer; brown, berry, gold; background of a river and pennant flags.

### 17. Tourette's Toucan (`tourettes_toucan`)

- **Type / cost / stats:** Ally, 3 Spark, 2 Power / 4 Heart (stat total 6 vs. vanilla baseline 8)
- **Keywords:** none
- **Archetype:** Together
- **Hooks & effect params:**
  - `on_card_played [filter=ally]` -> `modify_power(target=newest_ally, amount=+1)  # newest = the ally just played`
- **Description** (102 chars): "Whenever you play another ally, it gains +1 Power. Toucan has Tourette's and the warmest welcome in the zoo."
- **Style:** peach
- **Representation:** Tourette's; tics are part of Toucan and the team welcomes them.
- **Art brief:** Toucan with a huge rainbow beak, wings spread wide in welcome; black, peach orange, lime; background of tropical leaves and confetti.

### 18. Insulin-Pump Iguana (`insulin_pump_iguana`)

- **Type / cost / stats:** Ally, 2 Spark, 2 Power / 3 Heart (stat total 5 vs. vanilla baseline 6)
- **Keywords:** none
- **Archetype:** Slow & Steady
- **Hooks & effect params:**
  - `on_round_start` -> `heal_player(amount=2)`
- **Description** (98 chars): "Start of round: heal 2 Heart. Iguana checks levels, shares snacks, and keeps the team fueled."
- **Style:** mint
- **Representation:** Type 1 diabetes; insulin pump and glucose sensor are routine gear.
- **Art brief:** Green iguana basking on a rock with an insulin pump clipped to a belt and a round sensor on its upper arm, holding a snack box; leaf green, mint, orange; background of sun-warmed rocks.

### 19. Oxygen Owl (`oxygen_owl`)

- **Type / cost / stats:** Ally, 3 Spark, 2 Power / 4 Heart (stat total 6 vs. vanilla baseline 8)
- **Keywords:** none
- **Archetype:** Together
- **Hooks & effect params:**
  - `on_played` -> `modify_power(target=all_allies, amount=+1)  # resolves before Owl joins, so other allies only`
- **Description** (86 chars): "When played: all other allies gain +1 Power. Owl's pep talk keeps everyone soaring."
- **Style:** lavender
- **Representation:** Chronic lung condition; uses portable oxygen and a nasal cannula.
- **Art brief:** Wise owl perched with a small portable-oxygen backpack and nasal cannula, one wing raised in a pep talk; brown, lavender, sky; background of a night sky with stars.

### 20. Buddy-Bird Capybara (`buddy_bird_capybara`)

- **Type / cost / stats:** Ally, 4 Spark, 2 Power / 6 Heart (stat total 8 vs. vanilla baseline 10)
- **Keywords:** none
- **Archetype:** Slow & Steady
- **Hooks & effect params:**
  - `on_round_end` -> `apply_calm(target=enemy, amount=2)  # before the enemy acts`
- **Description** (81 chars): "End of round: Calm 2. Capybara's support bird helps them stay grounded with PTSD."
- **Style:** mint
- **Representation:** PTSD; a support animal and grounding routine, shown calmly and matter-of-factly.
- **Art brief:** Relaxed capybara sitting in a warm spring with a small bird perched on its head; tan, mint, soft yellow; background of steam swirls.

### 21. Tripod Tiger (`tripod_tiger`)

- **Type / cost / stats:** Ally, 4 Spark, 3 Power / 6 Heart (stat total 9 vs. vanilla baseline 10)
- **Keywords:** Guard
- **Archetype:** Protectors / Pass It On
- **Hooks & effect params:**
  - `on_knocked_out` -> `give_shield(target=all_allies, amount=2)`
- **Description** (85 chars): "Guard. When knocked out: all allies gain Shield 2. Three strong legs, one huge heart."
- **Style:** berry
- **Representation:** Limb difference (three legs, no prosthetic); nothing needs fixing.
- **Art brief:** Tiger standing proud and steady on three legs in a protective stance; orange, black stripes, berry; background of tall jungle grass.

### 22. Racing-Chair Cheetah (`racing_chair_cheetah`)

- **Type / cost / stats:** Ally, 5 Spark, 5 Power / 3 Heart (stat total 8 vs. vanilla baseline 12)
- **Keywords:** Quick
- **Archetype:** Setup & Burst
- **Hooks & effect params:**
  - `(keyword) Quick` -> `can be clicked to help the round it is played; cashes any Exposed set up earlier this round`
- **Description** (74 chars): "Quick. Cheetah's racing chair hits top speed before the barrier can blink."
- **Style:** peach
- **Representation:** Wheelchair user and wheelchair racer.
- **Art brief:** Cheetah leaning forward in a sleek three-wheeled racing wheelchair with speed lines; spotted gold, peach, charcoal; background of a curved running track.

### 23. Deaf Elephant (`deaf_elephant`)

- **Type / cost / stats:** Ally, 5 Spark, 4 Power / 8 Heart (stat total 12 vs. vanilla baseline 12)
- **Keywords:** Guard
- **Archetype:** Protectors / Slow & Steady
- **Hooks & effect params:**
  - `on_played` -> `apply_calm(target=enemy, amount=2)`
- **Description** (86 chars): "Guard. When played: Calm 2. Elephant feels trouble through the ground and stands firm."
- **Style:** sky
- **Representation:** Deaf; reads vibrations and signs with their trunk.
- **Art brief:** Big gentle elephant planted firmly, one foot stomping with vibration lines, trunk curled in a signing shape; grey, sky blue, cream; background of savanna ground with rumble lines.

### 24. Stim Toy (`stim_toy`)

- **Type / cost:** One-shot, 0 Spark
- **Keywords:** none
- **Archetype:** Spoons / One-Shot Engine
- **Hooks & effect params:**
  - `on_played` -> `draw_cards(amount=1)`
- **Description** (53 chars): "Draw 1 card. A fidget in paw keeps the ideas flowing."
- **Style:** lavender
- **Representation:** Stimming as healthy self-regulation (autism, ADHD).
- **Art brief:** A paw squeezing a rainbow pop-it fidget beside a spinner; lavender, mint, berry; background of swirly doodles.

### 25. Captions On (`captions_on`)

- **Type / cost:** One-shot, 1 Spark
- **Keywords:** none
- **Archetype:** Setup & Burst / One-Shot Engine
- **Hooks & effect params:**
  - `on_played` -> `apply_exposed(target=enemy, amount=2); draw_cards(amount=1)`
- **Description** (65 chars): "Exposed 2. Draw 1 card. With captions on, nobody misses the plan."
- **Style:** sky
- **Representation:** Captions as access for Deaf/HoH folks (and everyone).
- **Art brief:** Video screen with a bold caption bar of text lines and a speech icon; sky blue, white, navy; background of play-button shapes.

### 26. Call It Out (`call_it_out`)

- **Type / cost:** One-shot, 1 Spark
- **Keywords:** none
- **Archetype:** Setup & Burst
- **Hooks & effect params:**
  - `on_played` -> `apply_exposed(target=enemy, amount=3)`
- **Description** (63 chars): "Exposed 3. Naming the barrier is the first step to breaking it."
- **Style:** berry
- **Representation:** Allyship: naming ableism when you see it.
- **Art brief:** Megaphone with an exclamation burst aimed at a cracked brick wall; berry, yellow, grey; background of a brick pattern.

### 27. Signal Boost (`signal_boost`)

- **Type / cost:** One-shot, 1 Spark
- **Keywords:** none
- **Archetype:** Setup & Burst
- **Hooks & effect params:**
  - `on_played` -> `apply_exposed(target=enemy, amount=1); then apply_exposed(target=enemy, amount=X, X=enemy_exposed)  # doubles`
- **Description** (68 chars): "Exposed 1, then double the enemy's Exposed. Amplify disabled voices!"
- **Style:** peach
- **Representation:** Allyship: amplifying disabled creators and advocates.
- **Art brief:** Radio tower broadcasting concentric arcs with a heart at the top; peach, berry, white; background of signal waves.

### 28. Accessibility Audit (`accessibility_audit`)

- **Type / cost:** One-shot, 3 Spark
- **Keywords:** none
- **Archetype:** Setup & Burst
- **Hooks & effect params:**
  - `on_played` -> `damage_enemy(amount=7)  # single instance`
- **Description** (67 chars): "Deal 7 damage. Every barrier gets written down, checked, and fixed."
- **Style:** mint
- **Representation:** Systemic access: auditing and removing barriers.
- **Art brief:** Clipboard with a checklist, an access symbol and a big checkmark, tape measure beside; mint, navy, yellow; background of a blueprint grid.

### 29. Pride March (`pride_march`)

- **Type / cost:** One-shot, 3 Spark
- **Keywords:** none
- **Archetype:** Together / Setup & Burst
- **Hooks & effect params:**
  - `on_played` -> `damage_enemy(amount=2 * X, X=allies_in_circle)  # single instance`
- **Description** (77 chars): "Deal 2 damage for each ally in your Ally Circle. Nothing about us without us!"
- **Style:** berry
- **Representation:** Disability Pride and the disability-rights slogan.
- **Art brief:** Row of tiny animal silhouettes marching under the Disability Pride flag (charcoal with a diagonal band of red, gold, white, blue, green); berry, charcoal; background of confetti.

### 30. Celebrate Wins (`celebrate_wins`)

- **Type / cost:** One-shot, 3 Spark
- **Keywords:** none
- **Archetype:** Together
- **Hooks & effect params:**
  - `on_played` -> `modify_power(target=all_allies, amount=+1)`
- **Description** (57 chars): "All allies gain +1 Power. Every win counts, big or small."
- **Style:** peach
- **Representation:** Celebrating progress on your own terms.
- **Art brief:** Party popper bursting confetti over a star-shaped trophy; peach, gold, berry; background of streamers.

### 31. Pass the Mic (`pass_the_mic`)

- **Type / cost:** One-shot, 2 Spark
- **Keywords:** none
- **Archetype:** Together
- **Hooks & effect params:**
  - `on_played` -> `modify_power(target=newest_ally, amount=+2)`
- **Description** (76 chars): "Your newest ally gains +2 Power. Good allies listen, then hand over the mic."
- **Style:** lavender
- **Representation:** Allyship: centering disabled voices.
- **Art brief:** One paw passing a microphone to another paw; lavender, gold, charcoal; background of a stage spotlight.

### 32. Invite a Friend (`invite_a_friend`)

- **Type / cost:** One-shot, 2 Spark
- **Keywords:** none
- **Archetype:** Together / Pass It On
- **Hooks & effect params:**
  - `on_played` -> `create_copy_in_hand(card=newest_ally)  # no ally: no effect`
- **Description** (78 chars): "Add a copy of your newest ally to your hand. There's always room for one more."
- **Style:** mint
- **Representation:** Inclusion: actively inviting people in.
- **Art brief:** Open envelope invitation with a heart seal and a step-free doorway drawn on the card; mint, berry, cream; background of an open door.

### 33. Build a Ramp (`build_a_ramp`)

- **Type / cost:** One-shot, 2 Spark
- **Keywords:** none
- **Archetype:** Protectors
- **Hooks & effect params:**
  - `on_played` -> `give_shield(target=all_allies, amount=2)`
- **Description** (74 chars): "All allies gain Shield 2. A ramp helps everyone, strollers and wagons too."
- **Style:** peach
- **Representation:** Physical access (curb-cut effect).
- **Art brief:** Wooden ramp leading up to an open door with an access symbol, hammer beside it; peach, wood brown, sky blue; background of stepped blocks.

### 34. Service Dog Help (`service_dog_help`)

- **Type / cost:** One-shot, 1 Spark
- **Keywords:** none
- **Archetype:** Protectors
- **Hooks & effect params:**
  - `on_played` -> `pick lowest_heart_ally once; heal_ally(that, amount=3); give_shield(that, amount=2)`
- **Description** (84 chars): "The lowest-Heart ally heals 3 and gains Shield 2. A trained service dog stays close."
- **Style:** sky
- **Representation:** Service animals as working assistive support.
- **Art brief:** Golden service dog in a sky-blue vest with a handle harness, sitting attentively; gold, sky blue, white; background of a paw-print path.

### 35. Quiet Room (`quiet_room`)

- **Type / cost:** One-shot, 2 Spark
- **Keywords:** none
- **Archetype:** Slow & Steady
- **Hooks & effect params:**
  - `on_played` -> `apply_calm(target=enemy, amount=5)`
- **Description** (49 chars): "Calm 5. A dim, soft space where anyone can reset."
- **Style:** lavender
- **Representation:** Sensory-friendly spaces (autism, anxiety, sensory processing).
- **Art brief:** Cozy nook with a beanbag, dimmed lamp, and a moon-shaped 'quiet' sign; lavender, navy, soft yellow; background of soft stars.

### 36. Flexible Deadline (`flexible_deadline`)

- **Type / cost:** One-shot, 2 Spark
- **Keywords:** none
- **Archetype:** Slow & Steady
- **Hooks & effect params:**
  - `on_played` -> `apply_calm(target=enemy, amount=3); draw_cards(amount=1)`
- **Description** (66 chars): "Calm 3. Draw 1 card. More time means better work, not less effort."
- **Style:** mint
- **Representation:** Workplace/school accommodation: extended time.
- **Art brief:** Calendar page with one date gently stretching like elastic beside a smiling clock; mint, berry, white; background of a calendar grid.

### 37. Weighted Blanket (`weighted_blanket`)

- **Type / cost:** One-shot, 1 Spark
- **Keywords:** none
- **Archetype:** Slow & Steady / Protectors
- **Hooks & effect params:**
  - `on_played` -> `apply_calm(target=enemy, amount=2); give_shield(target=lowest_heart_ally, amount=2)`
- **Description** (73 chars): "Calm 2. The lowest-Heart ally gains Shield 2. Deep pressure, deep breath."
- **Style:** lavender
- **Representation:** Deep-pressure regulation tool (anxiety, autism, PTSD).
- **Art brief:** Chunky quilted blanket draped in a soft heap with a grid of stitched weight pockets; lavender, berry, cream; background of small moons.

### 38. Spoon Theory (`spoon_theory`)

- **Type / cost:** One-shot, 1 Spark
- **Keywords:** none
- **Archetype:** Spoons
- **Hooks & effect params:**
  - `on_played` -> `bank_spark(amount=3)  # NEW: gained at start of next round; draw_cards(amount=1)`
- **Description** (82 chars): "Next round, gain 3 Spark. Draw 1 card. Plan your spoons; rest is part of the plan."
- **Style:** mint
- **Representation:** Spoon theory for chronic illness and fatigue.
- **Art brief:** Jar of spoons with three set aside on an open weekly planner; mint, silver, peach; background of a planner grid.

## 6. Balance notes

### Cost curve

| Cost | Allies | One-shots | Total | Histogram |
| --- | --- | --- | --- | --- |
| 0 | 0 | 1 | 1 | # |
| 1 | 2 | 6 | 8 | ######## |
| 2 | 10 | 5 | 15 | ############### |
| 3 | 7 | 3 | 10 | ########## |
| 4 | 2 | 0 | 2 | ## |
| 5 | 2 | 0 | 2 | ## |
| **Total** | **23** | **15** | **38** | |

Average cost 2.26. Allies 23 (60%), one-shots 15 (39%).

### Cards per archetype

| Archetype | Primary | Including secondary |
| --- | --- | --- |
| Protectors | 7 | 9 |
| One-Shot Engine | 4 | 6 |
| Setup & Burst | 6 | 8 |
| Slow & Steady | 7 | 9 |
| Pass It On | 4 | 6 |
| Spoons | 4 | 4 |
| Together | 6 | 6 |

Reworked existing cards add: Protectors +2 (Rabbit, Puppy), Slow & Steady +1 (Alpaca), Setup & Burst +2 (Deer, Red Panda). Existing Meditate & Plan, Take a Nap, Speak Up!, Cup of Tea, and Rally support Spoons, Burst, and sustain.

### Baselines used

- Vanilla ally stat total ~ 2 x cost + 2; abilities paid for with 1-3 stat points. Guard is treated as roughly neutral (team benefit, self drawback).
- One-shots: ~2 damage or ~2.5 Heart/Calm per Spark (Speak Up!, Cup of Tea), plus a premium for card draw because cards are scarce. Exposed is priced slightly above damage because it is delayed.

### Cards to watch

- **Deaf Elephant** (5c 4/8 Guard + Calm 2) is above the stat baseline on purpose (5-cost premium). Drop to 4/7 if it walls every enemy.
- **Racing-Chair Cheetah** (5c 5/3 Quick): 5 immediate damage plus a 5-Power body. Fragile by design; very strong behind Guard or with stacked Exposed.
- **Team-Captain Otter / Pride March**: up to 8 / 10 damage in one instance with a full circle, more with Signal Boost. Swingy; consider 1 per ally (+ a flat 2) if bursts end fights too fast.
- **Stuttering Starling, Celebrate Wins, Pass the Mic**: permanent Power gains compound over 3-4 rounds. Power resets on redraw, and board damage removes allies, which keeps this in check. Pass the Mic is costed at 2 (not 1) for this reason.
- **Calculator Crow** (draw 2 on a 1/4 body) is the strongest card-advantage card; if decks auto-include two, raise it to 4 cost.
- **Spoon-Saving Squirrel / Spoon Theory**: Spark is rarely the bottleneck, so these may underperform. Spoon Theory is mostly a cantrip; tune Bank to 2 or 4 rather than changing the primitive.
- **Tablet-Talking Tapir** pings consume Exposed (see tensions). Intentional, but the description can't explain it; consider a tooltip on Exposed.
- **Dyspraxic Dolphin** recursion grows the battle deck each time it is knocked out. Hand max 8 burns overflow, so it cannot loop infinitely, but watch long battles.
- **Signal Boost** is dead without setup beyond its own Exposed 1. Making it 0 cost would improve engine play if it feels weak.

### Self-check

- Exactly 38 new cards; 38 unique snake_case ids, none colliding with the 12 existing ids.
- Longest description: 98 chars (limit 110).
- Hooks used: only `on_played`, `on_round_start`, `on_knocked_out`, `on_card_played`, `on_round_end`. Keywords: only Guard, Shield, Quick, Calm, Exposed. Effects: agreed primitives plus the three declared in section 2.
- No player choices: every target is the enemy, the player, this ally, all allies, the lowest-Heart ally, or the newest ally.
- Representation: no ally is cured, pitied, or "overcomes" their disability; disabilities are never linked to being knocked out. New animals avoid red panda, axolotl, deer, duckling, puppy, alpaca, rabbit, and lynx.
