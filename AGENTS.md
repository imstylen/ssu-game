# Repository guidance

## Purpose and architecture

Access Allies is an existing local, single-player Godot card adventure about disabled and neurodivergent animal allies overcoming ableist barriers. See [README.md](README.md) for gameplay and visual editing guidance.

- `project.godot` defines the application, autoloads, rendering, and startup scene (`main/main.tscn`).
- `main/`, `collection/`, `decks/`, and `battle/battle_scene.tscn` provide the menu, album, deck builder, and battle screens. `autoload/scene_navigator.gd` holds scene paths.
- `battle/model/` owns mutable battle state. `battle/action_resolver.gd` resolves actions independently of UI; `battle/battle_controller.gd` coordinates presentation through `battle/events/`. Rules and effects live in `battle/rules/` and `battle/effects/`.
- `cards/definitions/` and `enemies/definitions/` contain immutable `.tres` definitions and artwork. Behavior resources live under `cards/behaviors/` and `enemies/behaviors/` / `enemies/actions/`. `autoload/card_catalog.gd` discovers and validates content recursively.
- `decks/deck_rules.gd` validates decks; `decks/deck_record.gd` handles deck records. `autoload/profile_store.gd` persists `user://profile.json`, with migrations in `autoload/profile_migrator.gd`.
- `ui/card_base.tscn` is the shared card layout with editor previews. `CardVisualStyle` resources under `cards/styles/` supply optional overrides. `ui/app_theme.gd` supplies shared theme behavior.
- `tests/test_runner.gd` is the custom domain and acceptance suite; `main/main.gd` implements the screen smoke test.

## Setup and commands

There is no package manager, dependency manifest, lockfile, CI workflow, or dedicated lint/typecheck configuration in the repository. Open `project.godot` in a compatible Godot editor; no package installation step is documented. Let the editor import resources and register script classes before testing a fresh checkout.

The README specifies Godot 4.4 or newer, while the current working-tree `project.godot` declares 4.7 with the Mobile renderer. Resolve the intended engine version before changing version or renderer settings. `.vscode/settings.json` supplies a machine-specific editor executable path; do not copy that path into portable commands.

Existing README commands (run from the repository root, with a compatible Godot executable available as `godot`):

```powershell
# Run the game
godot --path .

# Domain and acceptance tests
godot --headless --path . --script res://tests/test_runner.gd

# Instantiate screens and exercise their _ready paths
godot --headless --path . -- --smoke-test
```

These application commands remain **unverified during initial setup**. On 2026-10-19, `godot4console.exe --version` returned `4.3.stable.official.77dcf97d8`; no executable named `godot` was found on PATH. Access to the configured VS Code editor path was denied, so its availability/version could not be verified. The available 4.3 executable is below the documented minimum; tests were not run with it.

`export_presets.cfg` contains a Web preset with output `../SSU_GAME_EXPORT/Index.html`. No build/export CLI command is documented or verified. Check engine, renderer, and export-template compatibility before exporting. No standalone lint or typecheck command is established; use Godot diagnostics and the existing tests when a suitable engine is available. Headless checks do not verify visual layout; inspect affected scenes in the editor or running game for UI changes.

## Conventions

- Follow existing typed GDScript, tab indentation, snake_case files/functions, and PascalCase class names. `.editorconfig` requires UTF-8.
- Keep mutable battle state out of shared definition resources and keep game rules independent of UI presentation.
- Preserve stable card/enemy IDs: display names can differ from IDs, and saved decks and migration logic refer to IDs.
- Edit shared card visuals in `ui/card_base.tscn`; use `CardVisualStyle` for card-specific overrides. Preserve the bundled Fredoka license.
- Retain Godot `.uid` and `.import` sidecars. `.godot/` is ignored generated editor data.
- Extend relevant existing tests for behavior changes. Report actual results and unavailable checks separately. Profile startup can create or migrate `user://profile.json`; account for that when verifying persistence.
- Preserve unrelated working-tree changes, including editor settings, project settings, and asset import metadata.

## Local workflow and skills

Read and follow the [shared workflow contract](.agents/skills/workflow.md) for templates, statuses, dependency checks, and evidence requirements.

Fixed paths:

- Specs: `docs/work/<feature>/spec.md`
- Tickets: `docs/work/<feature>/tickets/NN-<slug>.md`
- Settled terminology: `GLOSSARY.md`
- Consequential decisions: `docs/adr/NNNN-<slug>.md`

Create these files/directories only when there is concrete content. Reuse existing feature directories and preserve IDs and history. A draft spec is not implementation authorization.

Available repository skills (read the relevant `SKILL.md` before use):

- [initial-setup](.agents/skills/initial-setup/SKILL.md): inspect repository and maintain this guidance.
- [grill-me](.agents/skills/grill-me/SKILL.md), [grill-me-with-docs](.agents/skills/grill-me-with-docs/SKILL.md), and [grilling](.agents/skills/grilling/SKILL.md): stress-test plans through structured interviews, optionally recording decisions.
- [domain-modeling](.agents/skills/domain-modeling/SKILL.md): record settled terminology and architecture decisions.
- [to-spec](.agents/skills/to-spec/SKILL.md): synthesize an actionable local specification.
- [to-tickets](.agents/skills/to-tickets/SKILL.md): decompose a specification into tickets with explicit dependencies.
- [implement](.agents/skills/implement/SKILL.md): complete and verify one bounded task.
- [implement-spec](.agents/skills/implement-spec/SKILL.md): execute a specification's ticket graph sequentially.
- [tdd](.agents/skills/tdd/SKILL.md): focused test-first implementation where automated tests are useful.
- [code-review](.agents/skills/code-review/SKILL.md): review a bounded change for defects and requirements coverage.

Default to sequential work in the current checkout. Branches, worktrees, parallel agents, commits, pushes, and PRs require an explicit request. Infer routine implementation choices from repository evidence; clarify material scope or correctness decisions. Keep spec/ticket statuses aligned with verified progress and never mark unavailable checks as passing.
