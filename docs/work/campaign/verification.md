# Campaign implementation verification

Date: 2026-10-19
Engine: Godot 4.7.2 stable, official ed1daf0bf. The configured executable works with access outside the workspace. No project renderer or engine settings were changed.

## Automated results

- Domain and acceptance suite: `TESTS_OK: 851 assertions`, exit 0.
- Screen suite: `SCENE_SMOKE_OK`, exit 0; includes campaign map and committed battle entry as well as collection, decks, and standalone battle.
- Separate engine processes: `CAMPAIGN_PROCESS_INTERRUPT_OK`, `CAMPAIGN_PROCESS_WIN_OK`, `CAMPAIGN_PROCESS_RESUME_OK`, each exit 0. Exiting a damaged round-nine battle resumes the same commitment at full Heart/round one; exiting after saved victory resumes only its connected choices.
- Editor import/class registration completed without script errors. New `.uid` and SVG `.import` sidecars retained.
- `git diff --check` passed (only a line-ending normalization notice for README).
- A complete five-battle starter campaign runs through the real BattleController and battle result UI, with fresh seeded retries. Additional scene tests cover an edited selected deck, defeat, boss completion, unsaved victory/retry, confirmed/canceled reset, invalid-deck browsing, and standalone isolation.
- Persistence checks use disposable profiles and an injected writer failure. They cover initialization, commitment, victory, reset, profile migration, invalid campaign preservation, and actual atomic file replacement.

## Acceptance evidence

| Criteria | Evidence |
| --- | --- |
| AC1 | Menu entry, campaign screen smoke, invalid-deck preview/start checks |
| AC2 | Authored graph inspected against spec; tier counts, references, adjacent-tier edges, all routes to boss tested |
| AC3 | Every node receives keyboard focus and displays preview; inspection leaves memory and disk unchanged |
| AC4?AC5 | Exclusive commitment, next-neighbor unlocks, merged reachability, skipped descendants, replay rejection, all-route traversal |
| AC6?AC8 | Real battle scene setup, selected edited deck, full Heart, independent variants, result navigation, standalone isolation |
| AC9?AC10 | Save round trips, separate-process interruption/resume, idempotent wins, schema boundaries, invalid routes and disk errors |
| AC11 | Boss result and retained completed map; confirmed reset preserves selected deck; cancel preserves route |
| AC12 | Rendered map inspection at both requested sizes; all node states and focused retry inspected; keyboard focus checks |
| AC13 | Campaign only changes its route; deck snapshots and catalog pool remain intact; no rewards or habitat effects introduced |

## Rendered inspection

Rendered with the project's Mobile renderer on Vulkan, using `tests/campaign_visual_check.gd`. Inspected 1920?1080 and 1280?720 captures, fresh and partially completed routes. The map shows all eleven portraits, zoo habitats/pond/greenhouse/hut, greenery, paths, bottom entrance, boss frame, connections, previews, and distinct state labels. A pale focused-label defect was found and corrected; focused text now stays dark. Larger encounter labels remain readable at 1280?720. No overlapping encounter controls or clipped sidebar actions were observed.

Reproducible captures are generated under `.godot/campaign_*.png` rather than committed screenshots. The SVG illustration is local code-native art; it introduces no external asset dependency.

## Balance adjustment

The spec explicitly allows documented tuning after gameplay evidence. With the original values and a deterministic strategy that prioritizes useful draws, avoids healing at full Heart, and plays affordable allies, 50 starter-deck seeds produced only 1/50 tier-four Golem wins and 0/50 boss wins. This was a sharp jump from 49/50 tier-three Blob wins.

Final values: normal Heart remains base + 2 ? (tier ? 1); normal damage bonuses are `[0, 1, 2, 2]`; boss remains 42 Heart with `[5, 7, 8]`. Existing enemy art, descriptions, actions, and standalone values are unchanged.

| Encounter on tested route | Starter wins / 50 seeds |
| --- | ---: |
| t1_a | 50 |
| t2_b | 50 |
| t3_b | 49 |
| t4_a | 36 |
| t5_boss | 27 |

These are automated strategy results, not estimates of human win rates. Retries and deck editing remain available.

## Integrated code review

Reviewed tracked changes and new campaign/tests files against the specification and local conventions. Checked save rollback/atomic replacement, migration version boundaries, route validation, context isolation, duplicate win handling, UI save gates, reset behavior, and resource immutability. Fixed the focused-label contrast, stale portrait after reset, and nonnumeric map-version validation. Restored the established TEAM HEART label, resolving a test failure reproduced before campaign implementation. No outstanding code defects identified by this review; review is not proof of correctness.

Existing project/editor settings and pre-existing import metadata changes were preserved. Work remains uncommitted.

## Accepted verification alternative

The spec requests a hands-on full campaign and edited-deck retry playtest. Native interactive app control is unavailable in this session. A real-controller automated full playthrough, edited-deck scene tests, 250 seeded battles, separate-process resume checks, and human-readable rendered inspection were completed instead. These alternatives are not being silently represented as a hands-on playtest. On 2026-10-19, the user explicitly accepted this alternative under the shared workflow contract: "Accept this verification and mark the spec done". Ticket 04 and the campaign spec are now done. A hands-on playtest was not performed; the accepted alternative provides final sign-off.
