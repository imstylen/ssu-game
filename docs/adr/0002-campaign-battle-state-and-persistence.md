# 0002: Independent campaign battles with saved map progress

Date: 2026-10-19
Status: accepted

## Context

Campaign routes and forgiving retries are defined in [0001](0001-campaign-route-progression.md). The existing game provides standalone battles and an editable collection of saved decks. Campaign needs explicit boundaries for battle state, deck selection, rewards, and persistence.

## Decision

- Every encounter starts with full Team Heart and a freshly shuffled deck. Battle damage does not carry between encounters.
- Players may edit or switch decks between encounters using the existing Deck Builder, including before retrying a defeated encounter.
- Automatically save campaign map progress and committed route choices. Closing the game during a battle allows resuming the campaign by restarting that encounter; individual turns are not persisted.
- For the first version, victory rewards consist only of map progression. Card rewards, currency, and shops are outside this version's scope.

These are intended behaviors. Save representation, map size, encounter roster, and campaign completion/restart presentation remain to be designed.

## Alternatives

- Carrying damage between encounters would require healing opportunities and additional balancing.
- Locking the starting deck would strengthen run-level commitment but prevent adaptation through the existing Deck Builder.
- Saving individual turns would preserve interrupted battles exactly but require serializing battle state in addition to campaign progress.
- Card rewards, currency, and shops would introduce deck growth but expand the progression system beyond the initial map feature.

## Consequences

Campaign persistence must track the selected encounter as well as completed encounters so interruption cannot undo route commitment. Resuming an interrupted encounter initializes a fresh battle rather than restoring its previous health, hand, or turn. Battle entry must validate the currently selected deck. Campaign progression does not mutate the player's card collection or award currency.
