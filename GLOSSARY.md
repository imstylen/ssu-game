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

## Guard

A keyword on an ally. Board damage spreads only across Guard allies while any remain. Leftover damage then reaches other allies, and only after that spills to Team Heart. Example: Walker Wombat soaks the barrier's damage so a fragile Racing-Chair Cheetah stays safe. See [Card Expansion](docs/work/card-expansion/spec.md).

## Shield

An ally status (`Shield N`) that absorbs the next N damage to that ally before its Heart drops. Multiple grants add together. Shield lasts while the ally stays in the Ally Circle and clears when the card is redrawn.

## Quick

A keyword on an ally: it is ready to help (clickable) on the round it is played instead of resting first. It does not help automatically on entry, so the player can set up Exposed first.

## Calm

An enemy status (`Calm N`) that reduces the damage of the enemy's next damaging action by N. Calm stacks, and that action uses up the whole stack. Example: Quiet Room's Calm 5 cancels most of Barrier Blob's 8-damage spike.

## Exposed

An enemy status (`Exposed N`) that adds N to the next instance of damage the enemy takes, whether from ally help or a one-shot. Exposed stacks, and that instance uses up the whole stack. Small pings, such as Tablet-Talking Tapir's, use it up too, so burst decks prefer a few big hits.
