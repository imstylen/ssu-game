# SSU // Frontline

A complete Godot 4 MVP for a local, single-player deck-building card battler. Build and save multiple decks, browse the unlocked card catalog, then fight a scripted Siege Core using units and one-shot actions.

## Run

Open `project.godot` in Godot 4.4 or newer and run the project.

From a terminal with Godot on `PATH`:

```powershell
godot --path .
```

## Automated verification

Run the headless battle and deck-rule suite:

```powershell
godot --headless --path . --script res://tests/test_runner.gd
```

Instantiate every MVP screen and exercise its `_ready` path:

```powershell
godot --headless --path . -- --smoke-test
```

## MVP controls

- In battle, click a hand card to play it.
- Click a ready frontline unit to attack the enemy.
- End the turn to resolve the enemy's telegraphed action, refill energy, ready units, and draw.
- Destroyed and played one-shot cards enter the discard pile and reshuffle when needed.
- The Deck Workshop saves changes to `user://profile.json`; missing-card and otherwise invalid decks remain editable but cannot deploy.

## Editing card visuals

Open `res://ui/card_base.tscn` in the Godot editor to change the shared card layout, colors, fonts, artwork frame, background texture, and decorative overlay. The scene displays Life Drain as a live editor preview; choose another resource in **Editor Preview Definition** to preview a different card, or toggle **Editor Preview Compact** to inspect the battle/deck-builder layout.

Every card displays its `CardDefinition.artwork` with an aspect-preserving cover crop. Cards without assigned artwork display `res://icon.svg` as a fallback.

For card-specific styling, create a `CardVisualStyle` resource and assign it to the card definition's **Visual Style** property. Disabled overrides inherit from `card_base.tscn`, so the base scene remains the single source of shared styling.

The battle model is UI-independent. Card and enemy definitions are immutable `.tres` resources, while each battle owns its mutable session and emits presentation events through `BattleController`.
