# Nova Ancient Warrior - Android-first action campaign slice

An original third-person 3D action game prototype built with Godot 4.7.2 and GDScript. It now contains a complete nine-encounter campaign loop across three themed chapters, including three bosses, local progression, and mobile combat controls. It remains a production prototype rather than a finished commercial release.

## Campaign

- **Chapter I - The Sunken Ruins:** two escalating sentinel encounters and **The Ash Titan**.
- **Chapter II - The Ember Causeway:** faster and heavier enemy variants, a lunge-based boss encounter, and **The Ember Warlord**.
- **Chapter III - The Obsidian Throne:** the hardest regular waves, an area-attack boss, and **The Obsidian Sovereign**.
- Nine waves total, with boss encounters at waves 3, 6 and 9.
- Three procedural chapter environments with distinct silhouettes and palettes: Sunken Ruins spike traps, Ember Causeway lava channels with a central safe bridge, and Obsidian Throne runes that telegraph before timed pulses.
- Chapter hazards have deterministic damage windows and tested safe routes; visual indicators are synchronized with the warning/active phases. The campaign currently reuses one arena scene and swaps its chapter dressing; it is not yet three separately authored exploration levels.

## Combat systems

- Three-hit sword combo, heavy attack, directional dodge with invulnerability frames, hold-to-guard, timed perfect parry, and target lock-on.
- Enemies have readable approach, telegraph, strike and recovery phases.
- Three enemy archetypes by speed/health/damage profile; bosses have different attack ranges and health-triggered phases.
- Chapter title cards, boss reveal camera sequence, procedural ambient soundtrack, procedural combat tones and impact feedback.
- Touch buttons: movement pad, Attack, Heavy, Jump, Lock-on, Dodge and Block.
- Keyboard: WASD/arrows move, J/Enter attack, H heavy, I block, Tab lock-on, Shift/K dodge, Space jump, R restart.

## Progression and saves

- Versioned offline save data with wave resume, best score, total souls, checkpointed run currency, boss unlocks and campaign completion.
- Checkpoint accounting stores only the difference in collected souls, avoiding repeated rewards when a checkpoint is saved more than once.
- The Soul Forge offers permanent Blade (+4 damage), Vitality (+15 max HP) and Guard (reduced incoming damage) upgrades, each with three levels.
- Audio preference values are stored in the profile and applied to the procedural soundtrack and effects buses.

## Run in Godot

1. Install Godot 4.7.2 from https://godotengine.org/download/.
2. Import this folder as a Godot project.
3. Run `scenes/main.tscn`.

## Android debug APK

The GitHub Actions workflow **Nova Ancient Warrior Android debug APK** exports an ARM64 debug APK. It validates the APK archive, Android signature and package ID before publishing the `nova-ancient-warrior-android-debug` artifact. This is a sideloading/debug build, not a Play Store release.

A successful cloud export is not device certification. Install on the target phone and test touch reachability, audio, frame pacing, thermal behaviour and memory usage before release.

## Automated validation

CI imports the project, strictly parses the main script, runs combat and visual smoke tests, verifies save/currency/upgrade persistence, validates chapter metadata, checks all nine encounter definitions, builds all three chapter dressings, tests timed hazard windows and safe lanes, and performs a headless main-scene smoke run before exporting Android.

## Character and motion-capture pipeline

See [the character and mocap production pipeline](../docs/NOVA_CHARACTER_MOCAP_PRODUCTION_PIPELINE.md). The GitHub Actions workflow [Nova Warrior Motion Capture and Rigged Character](../.github/workflows/nova-mocap-character.yml) uses a pinned, experimental open-source markerless video-to-rig pipeline and a CC0 demo rig/video by default. It has successfully generated a humanoid GLB with a 61-bone skeleton and a body-motion clip, then imported and validated it in Godot. The pipeline now includes an optimizer that removes unused facial morph-target data to meet an Android asset budget while preserving skinning and skeletal animation; its latest CI check is pending. The capture is a single short kung-fu sequence, not a complete library of separate idle, locomotion, attack, dodge and reaction clips. The candidate is a base human, not the finished armoured hero, and is not yet wired into the runtime character. A custom phone recording can be processed from `mocap/` after performer rights are cleared.

## Known production boundaries

- Stage geometry is procedural set dressing around the combat arena, not a complete traversal/exploration layout with authored collision puzzles.
- The shipped game scene still uses procedural pivot/tween character motion. The separately validated mocap GLB is an asset candidate only; armour, weapon attachment, motion cleanup and AnimationTree integration remain to be completed.
- Cinematic coverage includes chapter title cards and boss introduction camera moves; authored dialogue scenes, character voice acting, subtitles and final narrative audio remain to be produced.
- Android export is checked in CI; physical-device playtesting and performance profiling are still required.
- This Godot Android game is not a PS2 executable. A real PS2 port would require a separate PS2SDK implementation and its own memory, rendering and controller constraints.
