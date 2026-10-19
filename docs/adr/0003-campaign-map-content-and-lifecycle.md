# 0003: Five-tier campaign using the existing enemy roster

Date: 2026-10-19
Status: accepted

## Context

The first campaign uses a fixed branching map with independent battles, editable decks, and saved route progress. The existing enemy roster consists of Barrier Blob, Assumption Golem, and Gatekeeping Gremlin. Campaign needs a bounded content scope and a lifecycle alongside standalone battles.

## Decision

- Author five tiers containing 2, 3, 3, 2, and 1 encounters respectively, from bottom to top: eleven map nodes and five battles per completed route.
- Every starting node must have a connected route to the final boss.
- Normal encounters reuse the three existing enemies, preserving their artwork and attack identities, with stronger variants on later tiers. Enemies may repeat along a route.
- The top node is a stronger Gatekeeping Gremlin using its existing artwork and a prominent boss frame.
- Add Campaign alongside the existing BATTLE! menu option.
- Maintain one saved campaign. Provide an explicit Start New Campaign action that resets campaign progress after confirmation.
- Boss victory shows a victory message and retains the completed map until the player starts a new campaign.

Exact encounter assignments, connections, and numerical difficulty tuning are not specified by this decision.

## Alternatives

- A larger map would lengthen campaigns and require more encounter balancing; a smaller map would provide fewer branching opportunities.
- A new roster or bespoke boss would require additional enemy identities, artwork, and behavior.
- Replacing standalone battles would remove the existing quick-play flow.
- Multiple campaign save slots would add selection and save-management complexity.
- Automatically resetting after boss victory would prevent reviewing the completed route.

## Consequences

The map needs eleven stable encounter identities, distinct from the three reusable enemy identities. Campaign difficulty variants must not inadvertently change standalone enemies. Save data represents one campaign's route and completion state. New-campaign confirmation must make the progress reset clear.
