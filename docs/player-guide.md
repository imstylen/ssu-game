# Access Allies: Player Guide

Access Allies is a cozy card adventure. Disabled and neurodivergent animal allies team up to bust ableist barriers, which appear as "ableism monsters" such as the Gatekeeping Gremlin. Each card shows a capable friend, an accommodation, or a kind act. Win by bringing the monster's Heart to 0 before your Team Heart runs out.

## Contents

1. [The basics](#the-basics)
2. [How a round works](#how-a-round-works)
3. [Keywords](#keywords)
4. [When abilities trigger](#when-abilities-trigger)
5. [Worked examples](#worked-examples)
6. [Building decks](#building-decks)
7. [The zoo campaign](#the-zoo-campaign)
8. [Tips](#tips)
9. [Card reference](#card-reference)

## The basics

| Thing | What it means |
| --- | --- |
| **Team Heart** | Your health. It starts at 30. If it reaches 0, the team needs a rest and you lose. |
| **Monster Heart** | The barrier's health. Bring it to 0 to win. |
| **Spark** ⭐ | What you spend to play cards. You get 5 Spark every round. Spark you don't use does not carry over. |
| **Ally** | An animal friend with **Power** (how hard it helps) and **Heart** (how much it can take). Allies stay in your **Ally Circle**, which holds up to 5. |
| **One-shot** | An accommodation or action. It does its effect once, then goes to the rest pile. |
| **Rest pile** | Played one-shots and knocked-out allies go here. When your deck runs out, the rest pile is shuffled into a fresh deck. |
| **Hand** | You start with 3 cards and draw 1 each round. You can hold up to 8. A card drawn into a full hand goes to the rest pile. |

The monster panel always shows the **next barrier**, so you know what's coming. For example, "Next barrier: 4 damage across the Ally Circle".

### The screens

- **BATTLE!** fights a random monster with your selected deck.
- **CAMPAIGN** walks a route through the zoo map to the boss.
- **Ally Album** shows every card. Everyone is unlocked from the start.
- **Cozy Deck Builder** is where you make decks of 1 to 20 cards, with up to 2 copies of each card.

## How a round works

1. **Your round.** Spend your 5 Spark on cards from your hand, in any order. Click a card to play it.
   - A new ally rests on the round it joins, so it can't help yet, unless it has **Quick**.
   - An ally marked **READY TO HELP** can be clicked to help right away.
2. **End the round** with **END ROUND →**.
   - Your allies' **end of round** abilities trigger.
   - Then the monster acts. Its barrier damage spreads across your Ally Circle **1 point at a time**, ally by ally from left to right, like dealing cards. Damage only reaches Team Heart when no allies are left to take it. If your circle is empty, it all hits Team Heart.
3. **A new round starts.**
   - Spark refills to 5, plus any Spark you saved.
   - You draw 1 card.
   - **Start of round** abilities trigger.
   - Then every ready ally **helps automatically**, hitting the monster for its Power.

> **Why spreading matters:** 6 damage against three allies is only 2 each, so a wide Ally Circle shares the load. A 1-Heart ally still gets knocked out by the very first point aimed at it.

## Keywords

Keywords appear at the start of a card's text. The monster's statuses show as a badge under its name (for example `CALM 3 • EXPOSED 4`). An ally's Shield shows on its card footer (for example `SHIELD 3 • READY TO HELP`).

| Keyword | On | Rule |
| --- | --- | --- |
| **Guard** | Ally | Barrier damage goes to Guard allies first. Other allies are only hit once no Guard ally is left. |
| **Shield N** | Ally | Blocks the next N damage to this ally before its Heart drops. Shields add together and last until used. |
| **Quick** | Ally | Can help (click it) on the round it joins, instead of resting. |
| **Calm N** | Monster | The monster's next barrier deals N less damage. Calm adds up, and that barrier uses up all of it. |
| **Exposed N** | Monster | The next hit on the monster deals N more damage. Exposed adds up, and that hit uses up all of it. Any hit counts, even a 1-damage ping. |

## When abilities trigger

| Text on the card | When it happens |
| --- | --- |
| *When played:* (or no prefix on a one-shot) | As you play the card. For an ally, this happens just *before* it joins the circle. So "other allies" or "each other ally" doesn't count the card itself. |
| *Start of round:* | Each round, after you draw and before your allies help. |
| *End of round:* | When you press END ROUND, before the monster acts. |
| *When knocked out:* | Right after the ally reaches 0 Heart and leaves the circle. This can happen in the middle of the monster's attack. |
| *Whenever you play a (one-shot / ally / card):* | After *another* card you play has fully resolved. |

All targets are picked for you. "Lowest-Heart ally" means the ally with the least Heart right now. "Newest ally" means the one that joined most recently.

## Worked examples

### Example 1: The starter deck's first two rounds

You face the **Gatekeeping Gremlin** (30 Heart; barriers of 4, 5, 7, repeating). Your opening hand is **Rolling Rabbit**, **Signing Deer** and **Speak Up!**.

**Round 1** (5 Spark)
- Play **Rolling Rabbit** (2 Spark; Guard, 2/5).
- Play **Signing Deer** (3 Spark; 3/4). *When played: Exposed 2.* The badge now shows `EXPOSED 2`.
- Press END ROUND. The Gremlin's 4 damage all goes to Rabbit, because Rabbit has **Guard**. Rabbit is at 1/5, and Deer is untouched.

**Round 2** (5 Spark; you draw **Quiet Room**)
- Your allies help automatically:
  - Rabbit hits for 2, +2 from Exposed = **4**.
  - Deer hits for **3**.
  - The Gremlin is at 23.
- Play **Speak Up!** (2 Spark): deal 4. The Gremlin is at 19.
- Rabbit is fragile now and the next barrier is 5, so play **Quiet Room** (2 Spark): **Calm 5**.
- Press END ROUND. The barrier's 5 damage is reduced by Calm 5 to **0**. Everyone is safe.

### Example 2: Quick cashes in Exposed the same round

With 4 Spark, play **Signing Deer** (Exposed 2), then **ADHD Red Panda** (1 Spark; Quick, 2/1). Panda is **READY TO HELP** right away. Click it and it hits for 2 + 2 = **4** this round, instead of waiting a round. The big version is **Racing-Chair Cheetah** (5 Spark, 5 Power, Quick).

### Example 3: Guard and Shield stop a big barrier

**Barrier Blob**'s pattern is 2, 4, **8**. Your Ally Circle holds:
- **Walker Wombat**: Guard, 2/5, played with Shield 3.
- **Rolling Rabbit**: Guard, 2/5.
- **Dyslexic Duckling**: 5/3. It hits hard but is fragile.

The 8 damage spreads only across the two Guard allies, 4 each:
- **Wombat** absorbs 3 with its Shield and loses 1 Heart, ending at 4/5.
- **Rabbit** loses 4 Heart, ending at 1/5.
- **Duckling** takes nothing, and it keeps hitting for 5 every round.

Add **Quiet Room** first (Calm 5) and the 8 becomes 3. Wombat's Shield blocks 2 of those points and Rabbit loses only 1.

### Example 4: Set up a burst

With 5 Spark and an empty Exposed badge:

| Play | Spark | Exposed after | Damage |
| --- | --- | --- | --- |
| **Call It Out** | 1 | 3 | 0 |
| **Signal Boost**: Exposed 1, then double | 1 | (3 + 1) × 2 = **8** | 0 |
| **Accessibility Audit**: deal 7 | 3 | 0 (used up) | 7 + 8 = **15** |

That's half a Gremlin in one round.

> **Watch the order.** Exposed is used up by the *next* hit of any size. If **Tablet-Talking Tapir** is in your circle, it deals 1 damage after each one-shot you play. That 1-damage ping would use up your Exposed before the Audit lands. Burst decks like a few big hits. Ping decks like many small ones.

### Example 5: The Tapir engine (from the starter deck)

**Tablet-Talking Tapir** is in your circle: *Whenever you play a one-shot, deal 1 damage.*
- Play **Meditate & Plan** (1 Spark): draw 2 cards, then Tapir pings for **1**.
- Play **Speak Up!** (2 Spark): deal **4**, then Tapir pings for **1**.

Cheap one-shots now deal extra damage, and draw cards keep the engine going. **Cane-Tapping Kiwi** (Exposed 1 per one-shot) and **Noise-Cancelling Narwhal** (Calm 1 per one-shot) work the same way.

### Example 6: Pass it on

**Tripod Tiger** (Guard, 3/6) reads *When knocked out: all allies gain Shield 2.*

Say a 7-damage barrier hits a circle of Tiger at 3 Heart plus two other allies:
- Tiger soaks the first 3 points and is knocked out.
- Its ability fires straight away, so the other two allies each gain Shield 2.
- The remaining 4 points are fully absorbed by those fresh Shields.

**Brace-Wearing Badger** (draw 2 when knocked out) and **Dyspraxic Dolphin** (returns a copy of itself to your hand) also reward allies who step back.

### Example 7: Go wide

**Pride March** deals 2 damage for each ally in your circle, so a full circle of 5 deals **10**. **Team-Captain Otter** deals 2 for each *other* ally as it joins, so with 4 friends already there it deals **8**. Pair these with **Oxygen Owl** or **Celebrate Wins** (+1 Power to every ally) and **Tourette's Toucan** (+1 Power to each ally you play after it).

### Example 8: Save your spoons

**Spoon Theory** (1 Spark): *Next round, gain 3 Spark. Draw 1 card.* Next round you have **8 Spark**. That's enough for **Deaf Elephant** (5; Guard, 4/8, Calm 2) plus **Safety-Plan Seal** (2; Calm 3), with 1 Spark left over.

## Building decks

A deck holds 1 to 20 cards, with up to 2 copies of each card. Because you only draw 1 card a round, **cards run out before Spark does**. Draw cards like Meditate & Plan, Calculator Crow and Captions On are worth more than they look.

### The starter deck: Access Allies

| Card (×2) | Teaches |
| --- | --- |
| Rolling Rabbit | Guard |
| Walker Wombat | Guard + Shield |
| ADHD Red Panda | Quick |
| Signing Deer | Exposed |
| Grounding Alpaca | Calm and end-of-round abilities |
| Tablet-Talking Tapir | "Whenever you play a one-shot" engines |
| Dyslexic Duckling | A hard hitter worth protecting |
| Speak Up! | Direct damage |
| Quiet Room | Big Calm for spike barriers |
| Meditate & Plan | Card draw |

### Starting points for your own decks

These are suggestions to try and tweak. They haven't been balance-tested.

- **Unbreakable Wall** (protect and outlast): Rolling Rabbit, Walker Wombat, Tripod Tiger, Worry-Wise Pangolin, Forearm-Crutch Flamingo, Dyslexic Duckling, Racing-Chair Cheetah, Build a Ramp, Service Dog Help, Meditate & Plan.
- **Speak Up Squad** (Exposed burst): Signing Deer, Magnifier Meerkat, Cane-Tapping Kiwi, ADHD Red Panda, Racing-Chair Cheetah, Call It Out, Signal Boost, Captions On, Accessibility Audit, Meditate & Plan.
- **Quiet Strength** (Calm and healing): Grounding Alpaca, Safety-Plan Seal, Buddy-Bird Capybara, Noise-Cancelling Narwhal, Sun-Seeking Lemur, Insulin-Pump Iguana, Quiet Room, Flexible Deadline, Weighted Blanket, Stim Toy.
- **Better Together** (go wide): Hearing-Aid Hedgehog, ADHD Red Panda, Stuttering Starling, Tourette's Toucan, Oxygen Owl, Team-Captain Otter, Pride March, Celebrate Wins, Invite a Friend, Stim Toy.

## The zoo campaign

- Choose **CAMPAIGN** to open the zoo map. Encounters you can start are in color.
- Pick one and press **Start Battle** to commit to it. Each win opens only that encounter's paths, leading up to the boss at the **Gremlin Gate**.
- Campaign monsters are tougher variants of the regular ones (the boss has more Heart).
- If you retreat or lose, the encounter stays committed for a fresh retry. Every battle starts with full Team Heart.
- Between fights you can visit the Deck Builder and come back without losing your route.

## Tips

- **Read the next barrier.** Play Calm before the big number in the pattern (Blob's 8, Gremlin's 7). Calm spent on a 2-damage barrier is mostly wasted.
- **Guard decides who gets hit.** Put Guard in front of fragile hard hitters like Dyslexic Duckling or Racing-Chair Cheetah.
- **Set up, then hit.** Apply Exposed just before your biggest single hit, whether that's a Quick ally, Accessibility Audit, or your strongest ally helping at round start.
- **Mind your hand size.** With 8 cards in hand, extra draws are lost to the rest pile.
- **Short on Spark?** Take a Nap, Spoon-Saving Squirrel and Spoon Theory help you land a 5-Spark ally plus something else.

## Card reference

All 50 cards, grouped by type and sorted by Spark cost.

### Allies

| Card | Spark | Power / Heart | What it does |
| --- | --- | --- | --- |
| ADHD Red Panda | 1 | 2 / 1 | Quick. Red Panda turns a burst of ideas into joyful momentum. |
| Hearing-Aid Hedgehog | 1 | 1 / 3 | Guard. When knocked out: Exposed 2. Hedgehog's hearing aids catch the barrier's rumble first. |
| Spoon-Saving Squirrel | 1 | 1 / 2 | Start of round: gain 1 Spark. Squirrel paces their energy and always tucks away a spare spoon. |
| Autistic Axolotl | 2 | 3 / 3 | Clear plans, soft light, and respectful friends help Axolotl feel at home. |
| Brace-Wearing Badger | 2 | 2 / 3 | When knocked out: draw 2 cards. Badger knows their limits and hands over a great plan. |
| Cane-Tapping Kiwi | 2 | 1 / 4 | Whenever you play a one-shot: Exposed 1. Kiwi's white cane finds every crack in the barrier. |
| Dyspraxic Dolphin | 2 | 2 / 2 | When knocked out: add a copy of Dolphin to your hand. The pod always saves Dolphin a spot. |
| Forearm-Crutch Flamingo | 2 | 2 / 3 | When played: other allies gain Shield 1. Flamingo's crutches set the pace and the flock keeps it. |
| Grounding Alpaca | 2 | 1 / 6 | End of round: Calm 1. Alpaca pauses, breathes, and helps the crew feel steady. |
| Insulin-Pump Iguana | 2 | 2 / 3 | Start of round: heal 2 Heart. Iguana checks levels, shares snacks, and keeps the team fueled. |
| Magnifier Meerkat | 2 | 2 / 3 | Start of round: Exposed 1. Meerkat's magnifier spots weak spots before anyone else. |
| Rolling Rabbit | 2 | 2 / 5 | Guard. A custom chair and a clever route help Rabbit keep the whole crew safe. |
| Safety-Plan Seal | 2 | 2 / 3 | When played: Calm 3. Seal shares their seizure plan, so everyone knows what to do. |
| Stuttering Starling | 2 | 1 / 3 | Whenever you play another card, this ally gains +1 Power. Friends wait, and every word lands. |
| Sun-Seeking Lemur | 2 | 1 / 4 | Start of round: heal the lowest-Heart ally 2. Lemur's light-lamp routine brightens everyone. |
| Tablet-Talking Tapir | 2 | 1 / 4 | Whenever you play a one-shot, deal 1 damage. Tapir's AAC tablet always has the right word ready. |
| Calculator Crow | 3 | 1 / 4 | When played: draw 2 cards. Crow's trusty calculator keeps every count on track. |
| Dyslexic Duckling | 3 | 5 / 3 | Duckling reads in their own way and spots a path others skipped. |
| Noise-Cancelling Narwhal | 3 | 2 / 5 | Whenever you play a one-shot: Calm 1. Headphones on, Narwhal stays focused and steady. |
| Oxygen Owl | 3 | 2 / 4 | When played: all other allies gain +1 Power. Owl's pep talk keeps everyone soaring. |
| Signing Deer | 3 | 3 / 4 | When played: Exposed 2. Deer signs the plan so the whole team hits together. |
| Team-Captain Otter | 3 | 2 / 3 | When played: deal 2 damage for each other ally. Otter, who has Down syndrome, leads the huddle. |
| Tourette's Toucan | 3 | 2 / 4 | Whenever you play another ally, it gains +1 Power. Toucan has Tourette's and the warmest welcome in the zoo. |
| Walker Wombat | 3 | 2 / 5 | Guard. When played: this ally gains Shield 3. Wombat rolls up front with a sturdy walker. |
| Worry-Wise Pangolin | 3 | 2 / 4 | End of round: the lowest-Heart ally gains Shield 2. Pangolin manages anxiety with a what-if list. |
| Buddy-Bird Capybara | 4 | 2 / 6 | End of round: Calm 2. Capybara's support bird helps them stay grounded with PTSD. |
| Prosthetic-Paw Puppy | 4 | 4 / 7 | Guard. A springy prosthetic paw makes Puppy a sturdy, playful protector. |
| Tripod Tiger | 4 | 3 / 6 | Guard. When knocked out: all allies gain Shield 2. Three strong legs, one huge heart. |
| Deaf Elephant | 5 | 4 / 8 | Guard. When played: Calm 2. Elephant feels trouble through the ground and stands firm. |
| Racing-Chair Cheetah | 5 | 5 / 3 | Quick. Cheetah's racing chair hits top speed before the barrier can blink. |

### One-shots

| Card | Spark | What it does |
| --- | --- | --- |
| Stim Toy | 0 | Draw 1 card. A fidget in paw keeps the ideas flowing. |
| Take a Nap | 0 | Gain 2 Spark this round. A little rest can bring back your Spark. |
| Call It Out | 1 | Exposed 3. Naming the barrier is the first step to breaking it. |
| Captions On | 1 | Exposed 2. Draw 1 card. With captions on, nobody misses the plan. |
| Meditate & Plan | 1 | Draw 2 cards. Pause, breathe, and make space for new choices. |
| Service Dog Help | 1 | The lowest-Heart ally heals 3 and gains Shield 2. A trained service dog stays close. |
| Signal Boost | 1 | Exposed 1, then double the enemy's Exposed. Amplify disabled voices! |
| Spoon Theory | 1 | Next round, gain 3 Spark. Draw 1 card. Plan your spoons; rest is part of the plan. |
| Weighted Blanket | 1 | Calm 2. The lowest-Heart ally gains Shield 2. Deep pressure, deep breath. |
| Build a Ramp | 2 | All allies gain Shield 2. A ramp helps everyone, strollers and wagons too. |
| Cup of Tea | 2 | Heal 5 Heart. A warm cup and a quiet pause help the team recharge. |
| Flexible Deadline | 2 | Calm 3. Draw 1 card. More time means better work, not less effort. |
| Invite a Friend | 2 | Add a copy of your newest ally to your hand. There's always room for one more. |
| Pass the Mic | 2 | Your newest ally gains +2 Power. Good allies listen, then hand over the mic. |
| Quiet Room | 2 | Calm 5. A dim, soft space where anyone can reset. |
| Rally | 2 | Heal every ally for 2 Heart. A shared cheer restores the whole Ally Circle. |
| Speak Up! | 2 | Deal 4 damage. A clear, supported voice can crack a stubborn barrier. |
| Accessibility Audit | 3 | Deal 7 damage. Every barrier gets written down, checked, and fixed. |
| Celebrate Wins | 3 | All allies gain +1 Power. Every win counts, big or small. |
| Pride March | 3 | Deal 2 damage for each ally in your Ally Circle. Nothing about us without us! |
