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

- Choose a card in your hand to play it.
- Ally cards join the Ally Circle. After their first rest, each ally automatically helps for its Power at the start of the player's round.
- One-shots are intentionally non-animal items and activities: Speak Up! deals 4 damage, Cup of Tea heals 5 Team Heart, and Meditate & Plan draws 2 cards.
- Ending the round resolves the monster's visible barrier action, refills Spark, readies allies, draws a card, and resolves automatic ally help.
- A large red damage number appears over the affected artwork or Team Heart display. The active ally card or monster portrait briefly grows to make the source of an attack obvious.
- Allies that reach zero Heart need a rest. Resting allies and played one-shots enter the rest pile, which becomes a fresh deck when needed.
- The Cozy Deck Builder saves to `user://profile.json`. Decks that need help remain editable but cannot start an adventure until valid.

## Editing card visuals

Open `res://ui/card_base.tscn` in the Godot editor to change the shared card layout, palette, Fredoka typography, square artwork frame, background texture, and decorative overlay. The scene shows Cup of Tea as a live preview; select another **Editor Preview Definition** or toggle **Editor Preview Compact** to inspect the smaller layout.

Every card shows `CardDefinition.artwork` in a 1:1 aspect-preserving cover frame. Cards without artwork use `res://icon.svg` as a fallback. Compact cards on every screen open a full readable preview on hover.

For card-specific styling, assign a reusable `CardVisualStyle`. Disabled overrides inherit from `card_base.tscn`, keeping the base scene the single source of shared styling. The bundled Fredoka font license is at `res://assets/fonts/OFL-Fredoka.txt`.

The battle model is UI-independent. Card and monster definitions are immutable `.tres` resources, while each battle owns mutable session state and emits presentation events through `BattleController`.
