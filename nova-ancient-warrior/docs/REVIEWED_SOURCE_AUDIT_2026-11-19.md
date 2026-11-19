# Nova Ancient Warrior - reviewed source audit (2026-11-19)

## Scope and decision

This audit covers the 12 allowlisted GDScript candidates staged by GitHub Actions from two pinned upstream commits. The artifact is a review cache only. No third-party file was copied into the game, executed, or merged.

- Staging workflow: https://github.com/NovaVisualsStudio/console-skill/actions/runs/44543291010
- Artifact: https://github.com/NovaVisualsStudio/console-skill/actions/runs/44543291010/artifacts/14539313103
- Artifact SHA-256: `a3db7016e57e966905760ed33b376c642892c42dc658992fa547beeb81d7ad23`
- Adventure Mode upstream: `EasterEggProductions/adventure-mode-godot` at `57d337f425af3b679de6c14eacc312872d07d007`
- GOAT upstream: `miskatonicstudio/goat` at `6c0d0905f8ff3eab06f6dff9a185544d5eef4c44`

## File-level provenance

Every listed file's SHA-256 was recomputed from the downloaded artifact and matched its `SOURCE_PROVENANCE.json` entry.

### Adventure Mode - MIT code (7 files)

The upstream license file was included in the artifact. Its code grant is MIT; the repository's art/assets are separately marked CC-BY-4.0 and were not staged or approved by this code-only audit.

| Candidate | SHA-256 |
|---|---|
| `Modular Mobility/MovementPackage.gd` | `a7caf6775528463e23150331f864814f9a7f867e816fb0f122933511d7e2f30f` |
| `Modular Mobility/mvpk_walk.gd` | `03fcd9885413ef9a5bea505388e3d695f89fc88efbd657e82b5f3806b46b4146` |
| `Modular Mobility/mvpk_climb.gd` | `95d5d57617d1ceae911ac6b668103581a8d30eb6ba13ba4b7ab6b965c3cf77c7` |
| `Modular Mobility/mvpk_combat.gd` | `5471742b4f83234177d3a5396202976459a97bc33da847e9643357b847b87a74` |
| `scripts/camera_control.gd` | `e7b5dd3e526f25b8cfe6879159e64cc756ff27e796222ec1ccf0ff6566cc5ec1` |
| `scripts/actor.gd` | `19246c915a0e3c143d94e6acedb64eb9737a5b2a098942017ed8b2a6802b43dd` |
| `scripts/armament.gd` | `7765deb653853a6ed41c97fa855a37862eba91ecabc650fe123f58c9fa7a2789` |

**Dependency and fit findings**

- `MovementPackage.gd` is a base Resource; the walk/climb/combat packages depend on the upstream `Actor` API and animation-tree conventions.
- `actor.gd` is not a standalone player controller. It references upstream-only types and systems including `Character`, `DresserUpper`, `Garment`, `Accessory`, `MgrMultiplayer`, `MgrTransition`, `Level`, `Spawnpoint3D`, `MgrPlayerSocket`, multiplayer synchronizers, and a specific scene-node hierarchy.
- `camera_control.gd` calls the upstream `MgrPlayerSocket` singleton and expects its player-camera contract.
- `armament.gd` expects specific child nodes (`hitbox`, `hitbox_vis`, `trail_weapon`) and the upstream `Actor` combat API.
- The movement scripts are not drop-in replacements for Nova's current CharacterBody3D controller, touch InputMap, target-lock, combat rules, or save/progression flow.
- The catalog's Godot 4.7 label is not proof of Nova's exact Godot 4.7.2 runtime compatibility. No independent Godot parse/import test of these external scripts was run.

**Decision:** do not integrate any of these seven files. Their movement concepts may inform a separately authored Nova traversal controller, but wholesale copying would introduce missing project dependencies and likely duplicate existing combat/input systems.

### GOAT - MIT code (5 files)

The upstream MIT license was included. The staged set contains code only; GOAT demo assets have mixed licenses, including CC0 and CC-BY-NC-4.0, and are not approved for commercial reuse by this audit.

| Candidate | SHA-256 |
|---|---|
| `addons/goat/globals/goat_inventory.gd` | `d39b8d56116f446d31446b56c8d1eec49ebe608a7bd6db9ff8ecab2752f885c4` |
| `addons/goat/globals/goat_interaction.gd` | `81016e7d8994d558e4bb3e2732498b6f19da2a686a85796b6861e91fd7c40173` |
| `addons/goat/globals/goat_voice.gd` | `a54127777907c79f8517441851033035404f3279107049501b2157cd510eebe7` |
| `addons/goat/globals/goat_settings.gd` | `fc99af3f64c07918b0da0f01c7957c0da636c6929e2886128b12bcdbca1358ff` |
| `addons/goat/globals/goat_state.gd` | `baa3e2ba907a3abd197824da64b4ed99d8d9ff988fe7ecbb0c64e07027df1b70` |

**Dependency and fit findings**

- `goat_interaction.gd` is the most portable candidate: it is a signal-driven selection/activation state holder with no explicit external class loads. It still needs a Nova-specific wrapper, lifecycle tests, interaction raycast, UI prompts, and accessibility/touch design before production use.
- `goat_state.gd` is small, but reads project setting `goat/state/variables` and leaves persistence as a TODO. Nova already has a versioned SaveManager; adopting a second state store would risk duplicated save authority.
- `goat_inventory.gd` requires configured item scenes, `res://addons/goat/helper_scenes/IconMaker.tscn`, and project settings. The referenced helper scene was not among the 12 candidates, so this file is incomplete in isolation.
- `goat_voice.gd` requires the separately installed Dialogue Manager singleton, `goat_utils`, GOAT autoloads, dialogue resources, audio assets, and an audio bus named `GoatMusic`. It cannot run from the staged file alone.
- `goat_settings.gd` assumes GOAT audio buses/autoloads (`GoatMusic`, `GoatEffects`) and its own settings configuration. It overlaps with Nova's existing mobile render and settings responsibilities.
- The source project was configured for Godot 4.3. Syntax/API compatibility with Godot 4.7.2 remains unverified; the staging workflow does not import or execute upstream scripts.

**Decision:** do not add the GOAT plugin wholesale. Keep `goat_interaction.gd` as an architectural reference for a future Nova-native interaction layer. Reimplement only the minimal interaction contract in Nova-owned code after the exploration level design and tests are defined. Do not import GOAT inventory, voice, or settings until all missing dependencies, licenses, buses, and overlap are resolved.

## Existing Nova overlap

Nova already contains:
- a CharacterBody3D player controller and touch/keyboard InputMap in `scripts/main.gd`;
- combat, dodge, guard, parry, target lock, enemy state, and boss rules;
- a versioned offline SaveManager and campaign progression;
- a generated rigged hero and animation adapter;
- chapter-specific arena layouts and hazard rules.

The external sources therefore do not fill a missing subsystem without adaptation. The main unfinished product work remains authored exploration spaces, traversal routes and puzzles, story/dialogue/cinematics, a richer animation library, and physical Android performance validation.

## Validation boundaries

- The source staging job and its license-gated Python tests passed.
- The artifact includes 7 Adventure Mode candidates, 5 GOAT candidates, both upstream code-license files, and both provenance manifests.
- Per-file hashes match the manifests.
- This audit did not execute external GDScript, claim Godot 4.7.2 compatibility, approve third-party art/audio, or integrate source.
- The repository-wide Python test suite is not a game test suite.
- Green hosted CI is not a physical Android playtest.

## Next safe implementation step

Build a Nova-owned exploration prototype in a separate reviewable change: one connected route with a checkpoint, one climb/traversal segment, one readable environmental puzzle, a return path, and explicit regression tests for movement bounds, collision, save/resume, touch controls, and Android renderer cost. Keep the existing combat campaign path intact until the new route passes Godot headless and Android export checks.
