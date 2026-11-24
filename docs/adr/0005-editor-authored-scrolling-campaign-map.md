# 0005: Editor-authored campaign map with scrolling view and grayscale states

Date: 2026-11-23
Status: accepted

## Context

The first campaign ([0003](0003-campaign-map-content-and-lifecycle.md), [0004](0004-campaign-map-presentation-and-commitment.md)) hardcoded an eleven-node, five-tier graph in `campaign_definition.gd`, positioned nodes with a tier/column formula over one fixed backdrop, and derived difficulty from tier. Designers need to build the campaign in the Godot editor: paint a map background, place encounter nodes on it, and wire which encounters each victory unlocks. A rough sketch shows a landscape zoo with habitats as encounters and suggests a map larger than one screen.

## Decision

- **The map scene is the source of truth.** `campaign/maps/zoo_trail.tscn` has a `CampaignMapCanvas` root (background texture, logical `canvas_size`, `show_connections`), one `CampaignEntrance`, and `CampaignEncounter` children. All are `@tool` scripts: nodes are dragged into place, `next_encounters` are picked in the Inspector, and arrows redraw live in the editor. The canvas turns the scene into a UI-independent `CampaignDefinition` graph for `CampaignProgress`.
- **Start and end are explicit.** The Entrance's `next_encounters` are the starting choices. Exactly one encounter is marked `is_final`. Tiers no longer exist; the available encounters are the `next_encounters` of the last victory.
- **Authoring is validated.** Unique, non-empty IDs; no loops; every encounter reachable from the Entrance and leading to the final encounter; no dead ends; enemies assigned. Errors appear as editor configuration warnings, fail the test suite, and disable starting battles in game.
- **Encounters carry their own tuning and art.** Each has a stable `encounter_id` (save identifier, independent of the node name), `display_name`, `enemy`, optional Heart and attack-pattern overrides, and optional `map_art` falling back to the enemy artwork. Variants never enter the standalone enemy pool.
- **State is shown in color versus black and white, plus a symbol.** Available: color, glow, play badge. Completed: color, check badge. Locked: grayscale, lock badge. Skipped: dimmed grayscale, cross badge. Grayscale is a per-node shader, so node art must be separate from the background. Tooltips and the preview panel keep text labels.
- **The map scrolls at 1:1.** It opens centered on the current position (committed encounter, else last victory, else the Entrance) with a "You are here" pin. Mouse wheel, trackpad, click-and-drag (with a threshold so drags are not clicks), and touch drag pan it, clamped to the canvas. Keyboard focus scrolls the focused node into view. A Recenter button returns to the current position. No zoom.
- **Old progress restarts quietly.** Campaign saves move to version 2. Profile schema 4 discards version 1 campaign progress (old tiered IDs), keeping decks and collection. Later graph edits that invalidate a save use the existing Start New Campaign error.
- **Placeholder content.** Generated SVG art (a 2560×2880 background and 256×256 habitat discs) replaces the old backdrop. The placeholder graph keeps the previous eleven-encounter shape and its exact Heart and damage values as explicit overrides. The hand-drawn sketch is not used in game.

This supersedes the tier structure and tier-scaled difficulty in 0003, and the whole-map-visible and symbol/label presentation details in 0004. Preview before commitment, retries, and single-save lifecycle remain as decided in 0001–0004.

## Alternatives

- A `.tres` resource with typed positions would be cleaner data but requires typing coordinates instead of dragging nodes.
- Clickable hotspots over habitats painted into the background cannot be desaturated individually.
- Fitting the whole map on one screen limits campaign size and detail; the scrolling map was preferred.
- Keeping tier-derived difficulty would hide tuning in a formula instead of the encounter being edited.
- Migrating old route IDs to new ones would preserve progress, but the placeholder map has no meaningful correspondence to the old IDs.

## Consequences

Content changes no longer require code changes, but encounter IDs must stay stable once players have saves. Final art should be split into a terrain background and per-encounter habitat art. Background textures should stay under 8192 px on the longest side for the Web export; much larger campaigns would need a stacked-section background. `next_encounters` on encounters is typed `Array[TextureButton]` (typing it with its own class leaks the script at exit), so validation, not the Inspector filter, rejects links to non-encounters.
