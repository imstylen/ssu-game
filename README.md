# Access Allies

Access Allies is a local, single-player Godot 4 card adventure about disabled and neurodivergent animal allies sharing support and busting ableist barriers. Build and save multiple decks, meet every unlocked ally, and face one of three randomly selected barrier monsters.

## Run

Open `project.godot` in Godot 4.4 or newer and run the project, or run:

```powershell
godot --path .
```

The window follows the project settings and remains resizable; the game does not force a 1280×720 override.

## Automated verification

Run the headless domain and acceptance suite:

```powershell
godot --headless --path . --script res://tests/test_runner.gd
```

Instantiate every screen and exercise its `_ready` path:

```powershell
godot --headless --path . -- --smoke-test
```

## How an adventure works

For a player-facing walkthrough with worked gameplay examples, see the [Player Guide](docs/player-guide.md).

- Choose a card in your hand to play it.
- Ally cards join the Ally Circle. After their first rest, each ally automatically helps for its Power at the start of the player's round.
- One-shots are intentionally non-animal items and activities: Speak Up! deals 4 damage, Cup of Tea heals 5 Team Heart, and Meditate & Plan draws 2 cards.
- Ending the round resolves the monster's visible barrier action, refills Spark, readies allies, draws a card, and resolves automatic ally help.
- A large red damage number appears over the affected artwork or Team Heart display. The active ally card or monster portrait briefly grows to make the source of an attack obvious.
- Allies that reach zero Heart need a rest. Resting allies and played one-shots enter the rest pile, which becomes a fresh deck when needed.
- Card abilities trigger when a card is played, at the start or end of a round, when an ally is knocked out, or when you play another card. All targets are chosen automatically.
- Keywords (see [GLOSSARY.md](GLOSSARY.md)):
  - **Guard** allies soak board damage first.
  - **Shield N** absorbs damage.
  - **Quick** allies can help on the round they are played.
  - **Calm N** softens the monster's next barrier.
  - **Exposed N** adds to the next hit on the monster.

  The monster panel shows active Calm and Exposed.
- The Cozy Deck Builder saves to `user://profile.json`. Decks that need help remain editable but cannot start an adventure until valid.

## Zoo campaign

Choose **CAMPAIGN** from the Cozy Corner to explore the zoo map. It opens on your current position; scroll with the mouse wheel or trackpad, drag, or Tab between encounters, and use **Recenter Map** to return. Available encounters are in color and unavailable ones in black and white, each with a status badge. Click or focus an encounter to inspect it; **Start Battle** saves your choice. Each victory unlocks only that encounter's connections, leading to the boss. Retreat, defeat, or closing the game keeps that encounter committed for a fresh retry.

Every battle uses full Team Heart and your currently selected deck. You can visit Deck Builder and return through the Cozy Corner without losing your route. **Start New Campaign** asks before resetting campaign progress and preserves decks and collection. A failed save offers a retry; an unsaved victory must be saved before leaving its result screen.

Progression lives in `campaign/campaign_progress.gd`, and campaign variants never enter the standalone enemy pool. Profile schema 4 stores the versioned route (campaign version 2) beside existing decks; older tiered campaign progress restarts automatically.

### Editing the campaign map

Open `res://campaign/maps/zoo_trail.tscn` in the Godot editor. The root `CampaignMapCanvas` sets the **Background** texture, the logical **Canvas Size** that node positions use, and **Show Connections**. Its children are:

- one `CampaignEntrance`, whose **Next Encounters** are the starting choices;
- `CampaignEncounter` nodes, dragged into position. Set **Encounter Id** (a stable save identifier; don't rename it after release), **Display Name**, **Enemy**, optional **Maximum Health Override** and **Attack Pattern Override**, optional **Map Art** (the habitat illustration, shown in color or black and white), and **Next Encounters**. Mark exactly one encounter **Is Final**.

To add an encounter, duplicate an existing one as a direct child of the root and give it a new ID. Arrows update as you edit. The root node's warning icon lists problems such as duplicate IDs, loops, unreachable encounters, or dead ends; the test suite fails on the same problems. Placeholder art is in `campaign/art/placeholder/`. Keep background images under 8192 px on the longest side for the Web export.

For reproducible rendered map captures at both supported sizes, run `godot --path . --script res://tests/campaign_visual_check.gd`; images go to `.godot/campaign_*.png`. The domain suite and smoke test include campaign coverage using disposable profiles. Cross-process resume checks run sequentially:

```powershell
godot --headless --path . --script res://tests/campaign_resume_check.gd -- interrupt
godot --headless --path . --script res://tests/campaign_resume_check.gd -- win
godot --headless --path . --script res://tests/campaign_resume_check.gd -- resume
```

## Editing card visuals

Open `res://ui/card_base.tscn` in the Godot editor to change the shared card layout, palette, Fredoka typography, square artwork frame, background texture, and decorative overlay. The scene shows Cup of Tea as a live preview; select another **Editor Preview Definition** or toggle **Editor Preview Compact** to inspect the smaller layout.

Every card shows `CardDefinition.artwork` in a 1:1 aspect-preserving cover frame. Cards without artwork use `res://icon.svg` as a fallback. Compact cards on every screen open a full readable preview on hover.

For card-specific styling, assign a reusable `CardVisualStyle`. Disabled overrides inherit from `card_base.tscn`, keeping the base scene the single source of shared styling. The bundled Fredoka font license is at `res://assets/fonts/OFL-Fredoka.txt`.

The battle model is UI-independent. Card and monster definitions are immutable `.tres` resources, while each battle owns mutable session state and emits presentation events through `BattleController`.

## Adding or changing cards

Card definitions live in `cards/definitions/<id>/<id>.tres`. Most abilities use `TriggeredCardBehavior` (`cards/behaviors/triggered_card_behavior.gd`), which holds a list of `CardEffect` lines (`cards/effects/card_effect.gd`) for each hook: played, round start, round end, knocked out, and another card played (with a one-shot or ally filter). Set **Guard** and **Quick** on the `CardDefinition`. Keep rules text first and the description within 110 characters. The design roster is in `docs/work/card-expansion/roster.md`.

Placeholder card art is generated from Python-authored SVG in `tools/card_art/`; see [its README](tools/card_art/README.md).
