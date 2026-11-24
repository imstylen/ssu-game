# Glossary

## Campaign

The planned mode entered through a Campaign option on the main menu, presenting connected enemy encounters on a fixed, authored zoo map and culminating in a final boss at the top. Example: defeating an encounter unlocks only its connected encounters on the next tier.

## Campaign node

An enemy encounter represented by habitat art on the campaign map (a `CampaignEncounter` in the map scene), identified in saves by its stable encounter ID. Available nodes appear in color and unavailable ones in black and white, each with a status badge. Example: selecting an available node previews its enemy encounter.

## Campaign map scene

The editor-authored scene (`campaign/maps/zoo_trail.tscn`) that defines the campaign: background, node positions, connections, tuning, and art. See [ADR 0005](docs/adr/0005-editor-authored-scrolling-campaign-map.md).

## Entrance

The non-battle starting point of the campaign map. Its connections are the encounters available at the start of a campaign.

## Current position

Where the "You are here" pin sits and where the map opens: the committed encounter, else the last victory, else the Entrance.

## Tier

Retired term. The first campaign grouped encounters into five tiers; since [ADR 0005](docs/adr/0005-editor-authored-scrolling-campaign-map.md), authored connections alone define progression. Each victory still makes only that encounter's connections available, closing off the alternatives.

## Campaign route

The player's chosen sequence of connected encounters toward the final boss. Paths can branch and merge. Example: two different encounters on one tier can connect to the same encounter on the next tier.

## Campaign boss

The final encounter at the top of the campaign map, whose defeat completes the campaign. In the first version this is a stronger Gatekeeping Gremlin, distinguished by a prominent boss frame.

## Committed encounter

The encounter chosen for a tier by pressing Start Battle. Previewing a node does not commit it. Example: after starting an encounter and retreating, the player may retry it with a different deck but cannot switch to the alternative encounter on that tier.
