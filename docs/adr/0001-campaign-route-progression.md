# 0001: Fixed campaign map with committed routes and retries

Date: 2026-10-19
Status: accepted

## Context

The planned Campaign menu option introduces a zoo map of enemy icons connected by lines, progressing upward to a final boss. Existing battles are standalone random encounters. The map needs meaningful connections and a progression model consistent with the game's cozy tone.

## Decision

- Use a fixed, authored zoo map rather than generated routes for the first version.
- Victory unlocks only connected encounter nodes on the next tier.
- Choose one encounter per tier; selecting a route closes off other encounters on that tier. Branches may merge on the way to the boss.
- Defeat preserves campaign progress and allows retrying the encounter rather than restarting the campaign.

These decisions describe intended campaign behavior, not existing functionality. Battle-to-battle state, save/resume details, encounter roster, and rewards remain unresolved.

## Alternatives

- Unlocking the entire next tier would reduce the significance of connecting lines.
- Allowing every branch to be cleared would create a completion map rather than a committed route.
- Generated maps would increase variation but require additional generation and balancing work.
- Resetting the campaign on defeat would increase stakes but make retries less forgiving.

## Consequences

Encounter selection must respect connections and previously committed route choices. The authored graph must provide valid routes to the boss. Defeat must not erase completed encounters or reopen discarded alternatives. Future procedural generation or branch-clearing behavior would require revisiting this progression model.
