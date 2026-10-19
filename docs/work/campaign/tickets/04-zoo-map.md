# 04: Illustrated accessible map and integrated verification
Spec: [Campaign spec](../spec.md)
Status: done
Blocked by: [03](03-battle-lifecycle.md)

## Outcome
Add Campaign menu entry, illustrated zoo map, keyboard-accessible previews, labeled node states, highlighted route, deck navigation, save retry, and confirmed reset. Verify the integrated campaign.

## Acceptance criteria
- [x] Add Campaign menu entry, illustrated zoo map, keyboard-accessible previews, labeled node states, highlighted route, deck navigation, save retry, and confirmed reset. Verify the integrated campaign. (AC1, AC2, AC3, AC4, AC5, AC8, AC10, AC11, AC12, AC13)

## Verification
Run full domain and screen smoke suites; inspect 1920x1080 and 1280x720 layouts, keyboard controls, all states, full campaign and edited-deck retries, interruption/resume, and standalone mode.

## Completion notes

Implementation and integrated automated/visual verification are complete. Full suite: 851 assertions; screen smoke and three separate-process resume stages pass. Reviewed the complete feature and fixed in-scope findings. See [evidence](../verification.md), including documented balance tuning. Final verification is complete using the automated alternative explicitly accepted by the user on 2026-10-19.

Resolved verification blocker (2026-10-19): native interactive app control was unavailable for the hands-on playtest. The user explicitly accepted the completed automated full campaign, edited-deck tests, process-resume checks, and rendered inspection, answering: "Accept this verification and mark the spec done". No remaining blocker.
