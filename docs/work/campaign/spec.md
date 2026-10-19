# Zoo Campaign
Status: done

## Problem and intended outcome

Access Allies currently offers standalone battles against randomly selected enemies. Add a Campaign entry to the main menu that lets players choose a connected route through an illustrated zoo, win five encounters, and defeat a final boss. Preserve the forgiving tone through retries, fresh battle state, and editable decks.

Current evidence: [menu](../../../main/main.gd), [battle entry and results](../../../battle/battle_ui.gd), [profile storage](../../../autoload/profile_store.gd), [profile migration](../../../autoload/profile_migrator.gd), and [scene navigation](../../../autoload/scene_navigator.gd). Campaign behavior below is new, not current functionality.

## Scope and non-goals

Include a fixed eleven-node map, encounter preview, route commitment, tier-scaled existing enemies, campaign battle/result navigation, one automatically saved campaign, and explicit campaign restart. Provide illustrated zoo scenery with habitats, greenery, paths, and a bottom entrance; overlay readable enemy icons and connection lines leading to the boss at the top.

Exclude procedural maps, multiple save slots, new enemy artwork or attack mechanics, habitat modifiers, shops, currency, card rewards, persistent battle damage, turn-by-turn saves, and changes to standalone battle balance. Existing BATTLE!, collection, and deck management remain available.

## Intended behavior

### Entry and map

Campaign opens the saved map, or initializes a fresh map on first use. Browsing is allowed with an invalid deck; starting an encounter requires a valid selected deck and explains validation errors. Provide access to the existing Deck Builder and a way back to the map without losing progress; returning through the main menu is acceptable.

The whole map and enemy lineup are visible from the start, with five tiers arranged bottom to top. Scenery is decorative. All nodes can be inspected, but only available encounters can start. Preview shows enemy name, maximum Heart, and the ordered repeating damage pattern, using the actual campaign variant values. A separate Start Battle button commits the choice; hovering, focusing, or selecting an icon does not.

Use labels and distinct symbols alongside color for Available, Locked, Completed, and Skipped. Mark the committed available node as Retry when returning from defeat, retreat, or interruption. Highlight the chosen route and distinguish the boss with a prominent frame. Controls and connections must remain legible when resizing; keyboard focus must allow node inspection and activation without relying on hover.

### Authored graph and encounters

The following assignments, connections, and initial tuning are implementation assumptions chosen to make the agreed scope concrete. They are not additional user-approved balance requirements. Keep them data-driven and tune if playtesting shows an unreasonable difficulty jump, documenting any changes.

Node IDs are stable save identifiers; A/B/C indicate left-to-right positions within a tier. Every edge goes to the next tier. Both tier-one nodes start available.

| Node | Enemy ID / display name | Next nodes |
| --- | --- | --- |
| t1_a | barrier_blob / Barrier Blob | t2_a, t2_b |
| t1_b | assumption_golem / Assumption Golem | t2_b, t2_c |
| t2_a | assumption_golem / Assumption Golem | t3_a, t3_b |
| t2_b | siege_core / Gatekeeping Gremlin | t3_a, t3_b, t3_c |
| t2_c | barrier_blob / Barrier Blob | t3_b, t3_c |
| t3_a | siege_core / Gatekeeping Gremlin | t4_a |
| t3_b | barrier_blob / Barrier Blob | t4_a, t4_b |
| t3_c | assumption_golem / Assumption Golem | t4_b |
| t4_a | assumption_golem / Assumption Golem | t5_boss |
| t4_b | barrier_blob / Barrier Blob | t5_boss |
| t5_boss | siege_core / Gatekeeping Gremlin (boss) | none |

For normal encounters, add `2 * (tier - 1)` to the base enemy's maximum Heart and `tier - 1` to each damage value in its repeating attack pattern. The boss starts at 42 Heart with pattern `[7, 8, 10]`. Preserve existing enemy artwork, descriptions, and attack behavior. Current base values are Blob: 26 / `[2, 4, 8]`; Golem: 34 / `[3, 6, 5]`; Gremlin: 30 / `[4, 5, 7]`.

Create independent campaign variants without mutating shared enemy resources or expanding the standalone random enemy pool. Keep normal enemy IDs separate from encounter IDs.

Implemented tuning adjustment (2026-10-19): normal Heart scaling is unchanged; normal damage bonuses by tier are now `[0, 1, 2, 2]`. Boss Heart remains 42 and its pattern is `[5, 7, 8]`. Seeded starter-deck play found an unreasonable late difficulty jump at the original values. Evidence and limitations are recorded in [verification](verification.md).

### Progression and battle lifecycle

1. Preview an available encounter and press Start Battle with a valid deck.
2. Save the encounter commitment before entering battle. Other choices on that tier become skipped. A committed encounter remains the only playable encounter until won, including after retreat or restart of the application.
3. Start a new session against that exact enemy variant with full Team Heart (currently 30), a freshly shuffled currently selected deck, and normal opening resources. No battle damage, hand, turn, or pile state carries over.
4. On victory, record completion once and save before allowing further progression. Unlock only the defeated node's outgoing neighbors on the next tier. Completed nodes cannot be replayed in the same campaign.
5. On defeat, allow Retry Encounter or Return to Campaign. Retreat also returns to the map. Neither action clears the commitment or unlocks another encounter. Deck editing/switching is allowed before retry.
6. On non-boss victory, provide Return to Campaign; do not offer the standalone random-monster retry action. On boss victory, show a campaign victory message and retain the completed map. No encounters remain playable.

Future nodes that are still reachable but not yet available are locked. Nodes excluded by a commitment, including descendants that can no longer be reached by any remaining route, are skipped. Merged nodes remain reachable if at least one valid route remains. Statuses are derived from the graph and saved route, not saved independently.

Standalone battles must neither read campaign commitment as their opponent selection nor advance campaign progress. Returning to standalone mode clears transient campaign battle context.

### Saving and restart

Store one campaign in the existing local profile, preserving decks and selected deck. Persist a campaign/map version, ordered completed node IDs, and an optional committed node ID; derive completion from boss victory. Do not persist preview selection or individual turns.

Migrate existing profiles without replacing customized decks or rerunning historical starter-deck changes on already migrated profiles. A profile without campaign data starts with no progress. Validate saved node IDs, route connections, tier order, and commitment consistency. If campaign data is invalid or unsupported, show a clear message and offer an explicit campaign reset while preserving deck data; do not silently reinterpret the route.

Save on initialization, encounter commitment, victory, and confirmed new campaign. On write failure, show a visible error and allow retry; do not enter an unsaved committed battle or advance beyond an unsaved victory. Do not present unsaved progress as safely resumable.

Closing during a battle resumes the map with that encounter committed and available for a fresh retry. Closing after a successfully saved victory resumes with its connected next choices available. Repeated victory notifications must not advance multiple tiers.

Start New Campaign is available for an active or completed campaign. Confirmation explicitly states that campaign progress will reset; cancel changes nothing. Confirmation resets only campaign progress and preserves decks/collection. The same authored map is used for each campaign.

## Acceptance criteria

- [x] AC1: Campaign appears alongside BATTLE! and opens a fresh or saved map. Invalid decks can browse but cannot start an encounter.
- [x] AC2: The zoo map contains exactly 2/3/3/2/1 nodes across five tiers, with the boss at the top, visible enemy icons, and edges matching the authored graph. Every start reaches the boss in five encounters.
- [x] AC3: All encounters are inspectable from the outset; previews show actual enemy name, Heart, and attack pattern. Inspection does not commit or save a route choice.
- [x] AC4: Start Battle saves commitment and launches only an available node. Other same-tier choices become skipped, and defeat, retreat, or application interruption cannot reopen them.
- [x] AC5: Victory completes exactly one encounter and unlocks only its next-tier neighbors. Locked, skipped, and completed encounters cannot start; merged paths retain correct reachability.
- [x] AC6: Every encounter and retry begins with full Team Heart and a freshly shuffled currently selected valid deck. Editing or switching decks between encounters preserves the route.
- [x] AC7: Later-tier variants and the boss use the specified initial tuning or documented playtest adjustments, preserve enemy artwork/attack identity, and do not modify standalone definitions or their random-selection pool.
- [x] AC8: Campaign results and retreat provide the specified campaign navigation; standalone battles retain their existing behavior and never modify campaign progress.
- [x] AC9: Save/load preserves completed nodes, committed encounter, and completed-campaign state. Interrupted encounters restart fresh; repeated victory handling is idempotent.
- [x] AC10: Existing profiles migrate without losing decks or selected deck. Invalid campaign data and failed saves produce actionable messages without silently resetting progress or allowing unsaved progression.
- [x] AC11: Boss victory displays campaign completion and retains the map. Confirmed Start New Campaign resets only campaign progress; cancellation preserves all state.
- [x] AC12: Available/locked/completed/skipped states have symbols and labels, node controls support keyboard interaction, and scenery, connections, previews, and boss framing remain readable at supported window sizes.
- [x] AC13: Victories grant no cards, currency, or shop access; habitats have no battle effects. Existing collection and deck behavior remain intact.

## Decisions and constraints

Terminology: [glossary](../../../GLOSSARY.md). Accepted decisions:

- [Fixed routes and retries](../../adr/0001-campaign-route-progression.md)
- [Independent battles and persistence](../../adr/0002-campaign-battle-state-and-persistence.md)
- [Map content and lifecycle](../../adr/0003-campaign-map-content-and-lifecycle.md)
- [Presentation and commitment](../../adr/0004-campaign-map-presentation-and-commitment.md)

Keep campaign progression independent of UI, following the existing battle model separation. Use an authored campaign definition plus a mutable progress model; adapt battle entry to accept explicit campaign context instead of choosing a random enemy. Reuse the existing battle controller and deck validation. Extend profile migration with explicit version boundaries rather than applying all historical migrations whenever the schema number increases.

Minor assumptions: first entry initializes the campaign without a reset confirmation; future unreachable nodes are marked skipped immediately; retries may use a new shuffle; a completed campaign cannot replay nodes. Exact habitat composition and artwork technique are implementation choices provided the illustrated zoo requirement is met.

## Verification

Extend the existing [test runner](../../../tests/test_runner.gd) at observable interfaces:

- Validate graph counts, unique IDs, valid references, adjacent-tier edges, acyclicity, and boss reachability (AC2).
- Exercise preview, commitment, branch exclusion, merges, retries, and all valid routes through boss completion; reject attempts to start unavailable nodes (AC3–AC5, AC11).
- Verify battle initialization, deck switching, actual variant values, base-resource immutability, and campaign/standalone isolation (AC6–AC8, AC13).
- Round-trip fresh, committed, partially completed, and completed saves; test legacy profiles, customized decks, invalid route data, repeated victory handling, save failures, and reset cancellation (AC9–AC11).
- Extend screen smoke coverage to include the campaign screen and campaign battle entry (AC1, AC8).

Run with a compatible Godot executable from repository root:

```powershell
godot --headless --path . --script res://tests/test_runner.gd
godot --headless --path . -- --smoke-test
```

Manually inspect the illustrated map at 1920×1080 and a resized 1280×720 window, checking label readability, connection alignment, preview controls, keyboard navigation, and all node states (AC12). Play a complete campaign with the starter deck and retry with an edited deck; assess later-tier/boss difficulty and record any tuning. Close and reopen during a battle and after victory; verify the expected committed or advanced map. Exercise standalone BATTLE! afterward.

Implementation verification (2026-10-19): Godot 4.7.2 was located at the configured editor path and runs with access outside the workspace. See [verification evidence](verification.md) for automated checks, rendered inspection, balance adjustment, and the accepted hands-on playtest alternative. Project engine and renderer settings were preserved.

## Open questions

No material product decisions remain open. Initial tuning has been adjusted from seeded gameplay evidence, and Godot 4.7.2 verification is available. On 2026-10-19, the user explicitly accepted the completed automated full campaign, edited-deck tests, process-resume checks, and rendered inspection in place of the hands-on playtest and requested that the spec be marked done. No verification sign-off remains open; see [verification](verification.md).

## Tickets

- [Authored graph, independent variants, and route rules](tickets/01-route-model.md)
- [Transactional campaign persistence and migration](tickets/02-profile-persistence.md)
- [Explicit campaign battle entry and results](tickets/03-battle-lifecycle.md)
- [Illustrated accessible map and integrated verification](tickets/04-zoo-map.md)
