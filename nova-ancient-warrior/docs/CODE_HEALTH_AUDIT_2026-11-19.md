# Nova Ancient Warrior - Code Health and Cleanup Audit

Date: 2026-11-19
Branch: `nova-full-campaign-polish`
Audited source HEAD: `4f014bee47a3cf1e91e57a7a54ee82d60e07fe5c`
Engine baseline: Godot 4.7.2

## Executive result

The game source is not ready for a destructive cleanup pass. The main gameplay coordinator is approximately 1151 lines and contains 39 functions. A first-pass declaration/reference scan did not establish any safe-to-delete gameplay script or symbol. This is not proof that every line is necessary: GDScript can use dynamic calls, node paths, resource paths, signals, and reflection, so text-only reference counts are insufficient grounds for deletion.

No gameplay source files, scenes, assets, or save data were deleted or replaced during this audit.

## Keep - these systems are active

- `main.gd`: current gameplay coordinator for player movement, combat flow, enemies, HUD, wave progression, audio, and stage setup. It is oversized and should be decomposed incrementally, not replaced wholesale.
- `combat_rules.gd`: deterministic combat and campaign rules used by gameplay and smoke tests.
- `save_manager.gd`: the single versioned save authority and progression/economy store. Avoid a second save system.
- `level_catalog.gd`: data-driven chapter themes and wave metadata.
- `stage_builder.gd`: decorative procedural chapter dressing. It creates visuals without adding physics bodies.
- `campaign_layout.gd`: collision-backed structural geometry. It is not a duplicate of decorative dressing.
- `stage_hazard_rules.gd`: deterministic hazard timing and damage rules.
- `rigged_warrior_visual.gd`: runtime adapter for the generated skinned hero and animation clips.
- `warrior_visual.gd`: still required as the procedural fallback and as the visual implementation used by enemies.
- `music_director.gd` and generated WAV assets: active procedural music and SFX path.
- `cinematic_director.gd`: current camera-reveal helper.
- `mobile_render_profile.gd`: active Android/desktop renderer baseline, but not yet a complete player-selectable quality system.

## Confirmed production debt

1. `main.gd` combines too many responsibilities. It should be split behind stable interfaces into player controller, combat controller, enemy director, campaign/level flow, HUD, and audio services.
2. Chapters are still arena layouts. The decorative meshes and collision-backed landmarks do not yet form authored exploration levels with connected routes, traversal, puzzles, secrets, and story progression.
3. The generated hero is a useful rigged prototype, not final production character art or a full animation library.
4. Cinematic camera reveals exist, but authored story sequences, dialogue, subtitles, voice performances, and final sound mix are not complete.
5. Android frame rate, thermal behavior, memory, and touch latency have not been measured on physical devices.
6. The current Android APK is a debug build. A production release requires a protected release keystore and a non-debug export.

## Safe cleanup protocol

For each candidate deletion or replacement:

1. Search all project scripts, scenes, resources, project settings, autoloads, input actions, animation tracks, and build workflows for references.
2. Classify the candidate as active, fallback, test-only, generated, obsolete, or uncertain.
3. If replacing it, add the replacement first and preserve the old implementation behind a fallback until parity tests pass.
4. Add or update tests for behavior, persistence, scene boot, Android import/export, and resource references.
5. Run the full Godot validation and six-pass QA on the same commit.
6. Delete only after the new implementation passes and a repository-wide reference scan shows no runtime or build-time dependency.

Never delete a fallback, generated source, provenance record, or asset merely because it is not referenced by a direct GDScript call.

## Fastest low-risk refactoring order

### R1 - Stabilize interfaces
Define narrow APIs for movement, combat, enemy lifecycle, campaign progression, HUD, and audio. Keep `main.gd` as the composition root during extraction.

### R2 - Extract one system at a time
Extract the audio service and HUD first, then campaign flow and enemy director, then player/combat logic. Each extraction must preserve current controls and gameplay behavior and add focused smoke tests.

### R3 - Build a real exploration vertical slice
Replace the first chapter arena loop with one authored route from entry to exit, including a checkpoint, traversal section, environmental puzzle, optional secret/reward, encounter spaces, and a boss arena. Keep existing combat and save APIs.

### R4 - Reuse the validated level framework
Build distinct chapter-two and chapter-three routes using chapter-specific traversal and puzzle mechanics, not only material and prop changes.

### R5 - Complete presentation and release gates
Finish hero/enemy art and animation, story cinematics, dialogue, subtitles, voice/audio, quality tiers, physical-device profiling, and signed production packaging.

## Validation status recorded during this audit

- Python test matrix: passed on Python 3.8, 3.11, and 3.13 for HEAD `4f014bee47a3cf1e91e57a7a54ee82d60e07fe5c`.
- Six-pass quality gate: passed on that HEAD.
- Android debug export: completed successfully; artifact ID `14540160991`.
- Godot-specific validation workflow: still running at the time of this audit. Do not report it as passed until its final conclusion is successful.
- Physical Android play/performance test: not performed by hosted CI.

## Explicit non-goals

- Do not upgrade the project to a beta engine release during production hardening.
- Do not import the reviewed Adventure Mode or GOAT source candidates wholesale; their dependencies and asset licenses do not match the current game architecture.
- Do not merge the open draft pull request or change repository settings as part of cleanup.
