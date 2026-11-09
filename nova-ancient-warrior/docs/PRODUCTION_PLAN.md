# Nova Ancient Warrior - Production Plan

## Product decision

Build Android-first with scalable visual quality. The default profile must favor stable frame pacing and thermal safety on mid-range devices; higher-end devices may enable richer shadows, lighting, effects and texture quality. Do not promise support for every Android device until the device matrix has been tested.

Godot 4.7.2 remains the current engine baseline. Keep the Compatibility renderer as the broad-coverage Android candidate while benchmarking it against the Mobile renderer on representative hardware. Do not switch renderers based on editor screenshots alone.

## Current verified project baseline

The current project is a playable-systems prototype, not a finished action-adventure game:
- Three chapter themes and nine combat encounters are present.
- All chapters still reuse one arena scene; procedural dressing and collision-backed landmarks do not yet constitute authored exploration levels.
- The current generated hero is stylized low-poly, with a small animation set.
- Combat, enemy state logic, boss profiles, save progression, touch controls and generated audio exist.
- Dialogue, voice acting, subtitles, full narrative cinematics and physical-device performance evidence remain outstanding.

These are production gaps, not claims of completed content.

## Production gates

A gate is passed only when its acceptance checks are recorded in CI or a reproducible test report. A successful export is not proof of good gameplay or device performance.

### Gate 0 - Repository and build integrity

1. Confirm the exact branch head before every change.
2. Run the repository Python tests and the Godot-specific QA workflow independently.
3. Run a clean Godot import, headless main-scene boot, asset-generation checks and Android debug export.
4. Record engine version, SDK/JDK versions, export preset, artifact checksum and workflow run URL.
5. Review the staged Adventure Mode and GOAT source candidates file by file. Keep them in a review cache until API dependencies, license notices, asset licenses, input mappings and tests are understood. Never merge GPL or unlicensed code into the default project.

Exit criteria: all automated checks pass on the same commit; Android APK installs and launches on at least one physical device; remaining limitations are documented.

### Gate 1 - Android performance baseline

Create a repeatable benchmark scene with the player, three ordinary enemies, one boss, representative environment geometry, particles, audio and the real HUD.

Measure on physical devices:
- average FPS and 1% low frame rate / frame-time spikes;
- memory use and loading time;
- thermal behaviour after a 20-minute session;
- input latency and touch responsiveness;
- renderer crashes, visual artifacts and device-specific failures.

Initial targets, to be validated rather than assumed:
- low tier: stable 30 FPS;
- mid tier: stable 45 FPS or better, with a 60 FPS mode where sustained performance allows;
- high tier: stable 60 FPS.
Use quality tiers (Low / Balanced / High) with conservative defaults and allow players to lower quality. Do not force expensive glow or shadow settings on all Android devices.

Exit criteria: at least one tested device per target tier, documented measurements, and no known crash/blocker in the tested matrix.

### Gate 2 - Vertical slice (one complete level)

Build one authored level from entry to exit, not another dressed arena. It must include:
- a navigable exterior/interior route with authored collision;
- traversal and one environmental puzzle;
- checkpoints, pickups and a meaningful reward;
- enemy encounters with distinct tactical roles;
- a boss with readable telegraphs, multiple phases and a complete defeat sequence;
- a short cinematic introduction and conclusion;
- final HUD, pause/settings, save/resume and sound mix.

Exit criteria: a new player can complete the level without developer intervention; progression survives app restart; no soft locks; combat and traversal pass regression tests; performance gate remains green.

### Gate 3 - Character and animation production

Replace placeholder-quality presentation through a repeatable character pipeline:
1. approved concept and silhouette;
2. licensed or original high-quality source mesh;
3. optimized game mesh, UVs, PBR materials and texture atlases;
4. humanoid rig and retargeting validation;
5. locomotion, traversal, attacks, defense, hit reactions, finishers and boss-specific animation;
6. LODs, texture budgets and Android import validation.

Every external model, animation, texture, sound and plugin requires an asset-level license/provenance entry. A pack's general marketing page is not a substitute for checking the exact downloaded version.

Exit criteria: hero and enemy models pass import, rig, animation, material, scale, collision and performance checks in the actual game scene.

### Gate 4 - Combat and enemy depth

Separate combat rules from presentation. Add deterministic tests for hit windows, invulnerability, parry timing, stagger, knockback, target switching, interruption, boss phases and simultaneous enemy attacks. Introduce enemy behaviours only when they produce readable, fair encounters on touch controls.

Exit criteria: each enemy archetype has a documented role and tested counterplay; each boss has distinct phases and no unavoidable attack loop.

### Gate 5 - Full campaign production

Expand only after the vertical slice passes:
- three genuinely different authored levels, not only different materials and props;
- unique traversal, puzzle and encounter beats per chapter;
- campaign pacing, narrative reveals, boss introductions and endings;
- localization-ready dialogue and subtitles;
- checkpoint and save migration tests.

Exit criteria: all chapters are independently navigable and completable, all progression paths work after app restarts, and the complete campaign has been playtested.

### Gate 6 - Release readiness

Run clean builds from a tagged commit; validate APK signing, package ID, permissions, offline behaviour, save compatibility, install/update/uninstall behaviour, device matrix, crash logs, attribution notices, privacy disclosures and store assets. Keep debug and release artifacts separate.

Exit criteria: reproducible release build, no release-blocking defects, approved licenses, and a signed test report.

## Working rules

- Prefer small, reviewable commits with a clear test result.
- Do not remove existing systems until references, scenes, signals and save compatibility have been checked.
- Do not add large third-party frameworks when a small native Godot system is sufficient.
- Do not claim photorealism, AAA quality, 60 FPS, broad device compatibility or a finished campaign without evidence.
- When a gate fails, fix the cause and rerun the affected regression suite before moving on.
