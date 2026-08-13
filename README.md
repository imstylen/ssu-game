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

The battle model is UI-independent. Card and enemy definitions are immutable `.tres` resources, while each battle owns its mutable session and emits presentation events through `BattleController`.
