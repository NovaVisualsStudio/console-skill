# Nova Ancient Warrior — High-Fidelity Third-Person Action Prototype

An original third-person 3D action game prototype built with Godot 4.7.2 and GDScript. It contains a nine-encounter campaign loop across three themed chapters, including three bosses, local progression and mobile combat controls. It remains a production prototype rather than a finished commercial release. The current production target is a high-fidelity desktop master using Forward+ and a high-end Android profile using Mobile/Vulkan. See the [professional high-fidelity production standard](../docs/NOVA_PROFESSIONAL_GAME_STANDARD.md) before changing rendering, art or platform priorities.

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
- Chapter title cards, boss reveal camera sequence and original procedural ambient soundtrack. A deterministic Python generator creates 13 original WAV effects for sword swings, impacts, parries, footsteps, dodges, jumps, boss roars, hazard alerts, victory and upgrades; CI generates and imports them before APK export.
- Touch buttons: movement pad, Attack, Heavy, Jump, Lock-on, Dodge and Block.
- Keyboard: WASD/arrows move, J/Enter attack, H heavy, I block, Tab lock-on, Shift/K dodge, Space jump, R restart.

## Progression and saves

- Versioned offline save data with wave resume, best score, total souls, checkpointed run currency, boss unlocks and campaign completion.
- Checkpoint accounting stores only the difference in collected souls, avoiding repeated rewards when a checkpoint is saved more than once.
- The Soul Forge offers permanent Blade (+4 damage), Vitality (+15 max HP) and Guard (reduced incoming damage) upgrades, each with three levels.
- Audio preference values are stored in the profile and applied to the procedural soundtrack and effects buses.

## Generate the original skinned hero

With Blender 4.2 or newer installed, run:

```bash
blender --background --python tools/blender/generate_nova_hero.py -- --output assets/characters/nova_hero.glb
```

The Android and Godot CI workflows run this generator automatically before importing the project. The generated model is a stylized original prototype; final art direction, animation polish and device playtesting remain necessary.

## Run in Godot

1. Install Godot 4.7.2 from https://godotengine.org/download/.
2. Import this folder as a Godot project.
3. Run `scenes/main.tscn`.

## Android debug APK

The GitHub Actions workflow **Nova Ancient Warrior Android debug APK** exports an ARM64 debug APK. It validates the APK archive, Android signature and package ID before publishing the `nova-ancient-warrior-android-debug` artifact. This is a sideloading/debug build, not a Play Store release.

A successful cloud export is not device certification. The current project targets desktop Forward+ and Android Mobile/Vulkan, preserves glow and key-light shadows on Android, and uses a 60 FPS cap as an initial target. Install on a compatible target phone and test touch reachability, audio, frame pacing, thermal behaviour and memory usage before release.

## Automated validation

CI generates and imports the 13 original sound effects and skinned hero, runs combat, animation, save, campaign, hazard and Android-profile smoke tests, and launches the actual main scene with project Autoloads enabled while rejecting script-load errors before exporting Android. A standalone `--check-only --script main.gd` call is intentionally not used because it runs outside the scene's Autoload context.

## Character and motion-capture pipeline

See [the character and mocap production pipeline](../docs/NOVA_CHARACTER_MOCAP_PRODUCTION_PIPELINE.md). The GitHub Actions workflow [Nova Warrior Motion Capture and Rigged Character](../.github/workflows/nova-mocap-character.yml) uses a pinned, experimental open-source markerless video-to-rig pipeline and a CC0 demo rig/video by default. It has successfully generated a humanoid GLB with a 61-bone skeleton and a body-motion clip, then imported and validated it in Godot. The pipeline includes an optimizer that removes unused facial morph-target data while preserving skinning and skeletal animation. A successful CI run on 2026-11-07 generated and imported a 61-bone skinned humanoid with one body-motion clip; the optimized GLB is 3,008,128 bytes (down from 44,953,644 bytes). The artifact is a motion-capture candidate, not the final armoured player model. The capture is a single short kung-fu sequence, not a complete library of separate idle, locomotion, attack, dodge and reaction clips. The candidate is a base human, not the finished armoured hero, and is not yet wired into the runtime character. A custom phone recording can be processed from `mocap/` after performer rights are cleared.

## Known production boundaries

- Stage geometry is procedural set dressing around the combat arena, not a complete traversal/exploration layout with authored collision puzzles.
- CI now procedurally generates an original skinned low-poly armoured hero in Blender, including a weighted humanoid rig, hand-attached sword and shield, and Idle/Walk/Run/LightAttack/HeavyAttack/Dodge/Block/Parry/HitReact/Death clips. The runtime adapter selects this rigged GLB when present and preserves the procedural character as a fallback. The markerless mocap candidate remains separate research input, not the hero's final animation source. The 2026-11-08 Godot validation run 140 and Android export run 124 on commit `4d9045e` both completed successfully; the generated GLB imported and passed the rigged-warrior smoke test (20 bones, 10 animation clips).
- Cinematic coverage includes chapter title cards and boss introduction camera moves; authored dialogue scenes, character voice acting, subtitles and final narrative audio remain to be produced.
- Rendering now uses Forward+ on desktop and Mobile/Vulkan on Android. The runtime quality profile preserves glow and key-light shadows on Android with an initial 60 FPS cap. This is a quality-oriented configuration, not proof that all Android devices support it or achieve 60 FPS; physical-device validation remains required.
- This Godot Android game is not a PS2 executable. A real PS2 port would require a separate PS2SDK implementation and its own memory, rendering and controller constraints.
