# 0004: Visible zoo map with preview before route commitment

Date: 2026-10-19
Status: accepted

## Context

The campaign has a fixed five-tier route with exclusive choices and saved progress. Players need to understand future choices and inspect encounters without accidentally committing to a branch. The zoo setting should be recognizable while keeping progression readable.

## Decision

- Present an illustrated zoo backdrop with recognizable habitats, paths, greenery, and an entrance at the bottom. Enemy icons and connecting lines are clearly overlaid, leading upward to the boss.
- Scenery is decorative in this version; habitats do not modify battle rules.
- Show the entire map and enemy lineup from the beginning.
- Distinguish available, locked, completed, and skipped encounters through symbols and labels, not color alone. Only currently available encounters are playable.
- Selecting a node previews its enemy name, Heart, and attack pattern without committing the route.
- A separate Start Battle action commits and saves the encounter choice. Retreating or quitting preserves that commitment and allows retrying the same encounter.

This clarifies the selection language in [0001](0001-campaign-route-progression.md): inspecting a node is not route commitment; starting its battle is.

## Alternatives

- Immediate commitment on node click would reduce interaction steps but make inspection risky.
- Hidden future encounters would provide surprise but reduce route planning.
- Color-only states would be less accessible and harder to distinguish.
- Habitat modifiers would make scenery mechanically significant but expand battle rules beyond this version's scope.

## Consequences

Preview selection and committed encounter state must be distinct. Campaign progress must be saved when starting an encounter as well as when recording victory. Retreat cannot reopen an alternative on the committed tier. Map layout and artwork must keep encounter controls and connections legible.
