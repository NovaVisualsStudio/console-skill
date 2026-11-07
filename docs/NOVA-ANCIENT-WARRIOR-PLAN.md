# NOVA - Ancient Warrior: technical production plan

## Product target

Build an original third-person mythic action game. The design may take broad genre inspiration from console action-adventure games, but all characters, story, code, models, animations, audio and level layouts must be original or correctly licensed.

Platform order:
1. Android APK: primary playable product.
2. PlayStation 2: separate native homebrew adaptation, not a Godot export.

The Godot project in `android-game/` is the first mechanics vertical slice. The existing `ps2-game/` folder remains a separate PS2SDK C project and is not the Android game.

## Three engineering levels

### Senior engineering
- Godot 4, GDScript, typed gameplay APIs and scene-based composition.
- Separate player, enemy, combat, camera, UI, audio, save and progression modules.
- Explicit state machines; avoid putting all gameplay in one scene script.
- Profile on physical Android hardware and keep a stable low-end preset.

### Master game design
- Combat readability before content quantity.
- Every enemy attack needs anticipation, active frames, recovery and clear hit feedback.
- Encounters combine pressure, spacing, guard, dodge and punish windows.
- Boss phases change patterns and arena pressure, not only health values.
- Progression should unlock meaningful moves and weapon properties, not only inflate damage.

### Scientific validation
- Establish a reproducible baseline build and a device test matrix.
- Record FPS, frame-time spikes, memory, thermal behaviour, battery drain and APK size.
- Use deterministic combat test cases for damage, invulnerability, hit range, cooldowns and boss states.
- Keep CI gates separate from physical-device acceptance tests; headless success does not prove touch usability or real-device performance.

## Technology choices

| Area | Recommended tool | Reason |
| --- | --- | --- |
| Android game | Godot 4 + GDScript | Open-source, scene-based 3D engine, practical Android export |
| 3D modelling and rigging | Blender | Free/open-source full 3D pipeline |
| 2D/UI/texture editing | Krita or GIMP | Open-source image editing |
| Audio editing | Audacity | Open-source audio editing |
| Version control | Git + GitHub | History, reviews, automated builds |
| PS2 homebrew | PS2SDK + C/C++ | Native PS2 toolchain |
| PS2 comparison | PCSX2 and/or Play! | Emulator-based functional checks; test each target separately |

For a no-code beginner, GDevelop can help build 2D or simple prototypes quickly, but it is not the recommended production foundation for a 3D melee game with a shoulder camera, animation state machines and boss encounters. Godot is the better long-term choice. Unity is a viable alternative when the team already knows C# and accepts its different licensing and tooling model.

## Architecture

Recommended production folders after the vertical slice:

- `scenes/`: arena, player, enemy variants, boss, menus and checkpoints.
- `scripts/player/`: locomotion, targeting, health and animation state.
- `scripts/combat/`: hitboxes, hurtboxes, damage rules, combo windows, guard and dodge.
- `scripts/ai/`: perception, navigation, telegraphs, attack selection and boss phases.
- `scripts/camera/`: follow, shoulder offset, lock-on, collision and camera shake.
- `scripts/ui/`: HUD, touch controls, pause, accessibility and equipment screens.
- `scripts/progression/`: inventory, upgrades, unlocks and checkpoints.
- `scripts/save/`: versioned save schema and safe writes.
- `audio/`: music, ambience, weapon impacts, enemy tells and UI feedback.
- `assets/`: original or licensed assets, each listed in an asset manifest.

Combat should be data-driven: attack definitions specify startup, active duration, recovery, range, damage, stamina cost, hit-stop and animation identifier. Use a small number of reusable attack resources rather than hard-coded per-enemy logic.

## Vertical slice acceptance scope

The first slice should contain one arena, one playable warrior, two basic enemy types and one boss encounter. It should prove:
- Movement, acceleration, facing and camera follow.
- Light/heavy attack chain, attack recovery and hit confirmation.
- Dodge with a short invulnerability window.
- Guard with directional or timed damage reduction.
- Enemy telegraph, attack, stagger, death and reset.
- Boss with at least two distinguishable attack patterns.
- Health UI, pause/retry and one checkpoint.
- Touch controls usable in landscape without blocking the combat view.
- A stable Android debug APK and a physical-device test report.

The current cinematic slice now includes an original procedural warrior/axe model, shoulder follow camera with cinematic intro, lock-on and impact shake, three-hit light combo, stamina heavy attack, dodge i-frames, timed parry/guard, two telegraphing guardians, an Ashen Warden two-phase boss, a fog-lit temple arena, generated ambience/combat sound effects, touch HUD and retry flow. Lock-on now turns the warrior toward the target even while stationary; automated integration checks verify this and the nine Android touch controls. Its models and attack animations are still procedural primitives and tweens; it does not yet meet full production art/animation quality or full-game scope.

## Full game feature roadmap

1. Foundation: input, locomotion, camera, health, damage and test harness.
2. Combat: combo graph, heavy attacks, guard/parry, dodge, stagger, finishers and hit reactions.
3. AI: enemy archetypes, group coordination, navigation and readable telegraphs.
4. Bosses: multi-phase behaviour, arena hazards, camera framing and checkpoint retry.
5. Content: original story, hub, 3-5 compact regions, encounters, secrets and progression.
6. Presentation: authored animation, facial/body posing, soundscape, music, VFX, lighting and cutscenes.
7. Product: accessibility, remapping, save migration, settings, localization, credits and QA.
8. Android release: device matrix, thermal and battery tests, memory budgets, crash reporting and store packaging.
9. PS2 adaptation: a distinct low-level renderer/gameplay port in C/C++ using PS2SDK; no direct Godot-to-ELF conversion.

## Mobile constraints and quality targets

- Landscape orientation and large touch targets; keep the left movement region and right combat region separate.
- Start with a 30 FPS minimum target on entry-level devices; target 60 FPS on stronger devices only after measurement.
- Use Godot Compatibility renderer as the initial baseline, low-cost materials, limited dynamic lights and shadows, LODs, compressed textures and pooled VFX.
- Keep arena sightlines controlled and avoid excessive transparent particles.
- Use animation LOD and reduce AI update frequency for distant enemies.
- Test thermal throttling and battery drain in 15-30 minute sessions.
- Measure APK size after each content milestone; do not bundle source textures or unused audio.
- A high-end phone can exceed PS2-era visual features, but mobile must use smaller encounter counts, compact levels and lower sustained rendering load than a large console production.

## Asset and licence policy

Use Blender and other open-source creation tools for original content. Kenney publishes many free assets under CC0; verify the individual pack page and preserve the licence record. OpenGameArt, Freesound and other libraries have mixed licences, so check every asset individually. Never assume a whole website or pack is public domain. Do not use God of War character models, animations, logos, music, textures, voice lines or level layouts.

Maintain `ASSET_MANIFEST.md` with: asset name, creator, source URL, licence, attribution requirement, modifications and included file path.

## Schedule and cost estimate

For a solo developer learning while building:
- 2-4 months: polished mechanics vertical slice, assuming regular weekly work.
- 6-12 months: compact indie game with a few regions and limited enemy variety.
- 12-24+ months: stronger production quality, more original animation/content and QA.
- PS2 adaptation: additional months of low-level graphics, input, memory and performance work; scope must be reduced significantly.

Cash cost can remain near zero with self-made assets and free/open-source tools, but time is the main cost. Paid professional animation, sound, QA or commissioned art would change the budget materially.

## Expanded CI test protocol: ten gates

1. Python source and project integrity (10 tests), including generated build/cache exclusion.
2. Godot 4.7.2 headless editor import and script parsing.
3. Deterministic combat behaviour tests: combo chain, heavy attack, boss threshold/phase, parry, guard reduction, dodge i-frames, enemy telegraph/strike.
4. Cinematic scene integration: arena nodes, player/boss/camera, intro lock, camera lock-on/shake, combat handoff and boss HUD/phase.
5. Procedural audio smoke test: ambience stream, sample data, pooled voices and combat effect playback calls.
6. Scene runtime smoke test.
7. Extended 300-frame scene runtime test.
8. Source hygiene checks.
9. Android ARM64 debug APK export.
10. Six repeated stability passes; each pass re-runs the Python, combat, cinematic, audio and 300-frame runtime checks.

The latest run succeeded across all ten gates. This proves repeatable headless gameplay logic, scene initialisation and APK packaging. It is not a physical-device acceptance test.

## Test protocol: minimum five gates

1. Python integrity tests: expected project files, scripts and licence hygiene.
2. Godot headless editor import: project and script parsing.
3. Short headless runtime smoke test: scene instantiation and initialisation.
4. Extended headless runtime test: 300 frames or longer, checking runtime stability.
5. Physical Android acceptance: install APK, verify landscape, touch controls, combat, boss encounter, thermal behaviour and sustained frame rate.

The first four can run in CI. The fifth requires an actual Android device and must be reported separately. Do not label a build "mobile-tested" until gate five has been performed.

## Immediate next milestones

- Fix all Godot parser/runtime failures from CI.
- Add proper attack state machine, animation tree and target lock.
- Replace primitives with licensed placeholder models, then original rigged characters.
- Add two enemy archetypes and boss wind-up/recovery phases.
- Export debug APK and test on a physical phone.
- Only after Android combat is stable, begin the separate PS2SDK action-game port.

## Open-source resource directory

- Godot Engine and Android export documentation: https://godotengine.org/ and https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html
- Blender (3D modelling, rigging and animation): https://www.blender.org/
- Krita (2D concepts and UI art): https://krita.org/
- GIMP (texture and image editing): https://www.gimp.org/
- Audacity (audio editing): https://www.audacityteam.org/
- Kenney asset library: https://kenney.nl/assets - verify the licence on each pack page; many packs are CC0.
- OpenGameArt: https://opengameart.org/ - licences vary by asset; review each entry.
- PS2SDK: https://github.com/ps2dev/ps2sdk
- PCSX2 emulator: https://github.com/PCSX2/pcsx2

## Current verified delivery state

The current cinematic Android ARM64 debug APK was exported successfully by GitHub Actions run #110 (Godot 4.7.2) and uploaded as `nova-ancient-warrior-android-debug`. The APK passed CI apksigner v2/v3 verification, package metadata validation and ARM64 native-library checks; the downloaded artifact ZIP and APK archives both passed integrity checks. Six consecutive stability passes completed, with no ObjectDB resource-leak warnings or ADB connection failures. One Godot exporter shutdown diagnostic remains: `Orphan StringName: Node` (one unclaimed StringName); it is not accompanied by an ObjectDB instance leak and was not observed in the six gameplay/runtime passes. This verifies export and headless packaging only; physical-device installation, touch ergonomics, sustained performance, thermal behaviour and battery usage remain unverified until tested on an actual phone.
