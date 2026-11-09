# NOVA - Ancient Warrior (cinematic vertical slice)

An original Godot 4 action-adventure prototype for Android ARM64, built as a separate project from the PS2SDK homebrew target in `ps2-game/`.

## Playable slice

- Third-person shoulder camera with smoothing, cinematic opening move, target lock-on and impact shake.
- Skinned Quaternius humanoid hero with a 65-joint skeleton, PBR material setup, a hand-bone-attached war axe and retargeted CC0 combat/locomotion animation clips.
- Rigged humanoid enemy and boss variants using the same reusable character pipeline, with tint/scale variations and state-driven idle, chase, attack, hit and death animation requests.
- Three-hit light combo and stamina-cost heavy attack with distinct startup/active/recovery windows, one hit per target per swing, cancelable pending hits, dodge i-frames, guard and timed perfect parry.
- Two guardian enemies with visible pre-attack telegraphs.
- Ashen Warden boss with a 50% health phase transition and three distinct patterns: frontal melee, lateral sweep and radial slam. Warning rings change size and colour to signal the danger area; phase two cycles all three faster.
- Original temple arena with portal architecture, pillars, ritual rings, emissive braziers, fog and floating ash.
- Cinematic letterbox/title handoff, original procedural ambient drone and combat sounds, hit sparks, player/boss health UI, stamina and mobile touch controls.
- Android landscape export preset and reproducible CI-built debug APK.

The player and enemy bodies now use a real skinned humanoid mesh and a reusable 65-joint skeleton. The free Quaternius Universal Animation Library 2 Standard pack is retargeted to the base rig at runtime. The GLB is fetched automatically in CI; local development can run `python3 tools/fetch_cc0_animations.py` from this folder. The imported character mesh has no original texture maps in this redistribution copy, so NOVA applies custom PBR materials. The result is a stronger production foundation, but it is not a claim of AAA realism: bespoke high-resolution face/armor textures, additional distinct enemy meshes, animation polish, and real-device visual review remain required.

## Controls

Desktop: WASD movement, J light combo, K heavy attack, Space dodge, L guard/parry, Tab lock target.

Android: left directional pad; right LIGHT, HEAVY, DODGE, GUARD and LOCK controls. Tab locks onto the next live target on desktop. Landscape orientation is required.

## Open in Godot

Open this folder in Godot 4.7.2 or newer and run the project. The CI pipeline runs editor import, combat tests, cinematic integration tests, procedural audio checks, headless runtime tests, six repeat stability passes (combat, cinematic, audio and 300-frame runtime each time) and Android ARM64 debug export.

## Android APK

The workflow uploads `nova-ancient-warrior-android-debug` as a 14-day artifact after a successful build. It is a debug APK, not a store-signed release. Each CI run uses a temporary debug signing key, so uninstall an older debug build before installing a newer artifact; in-place upgrades require a persistent private signing key configured outside Git. Keep production signing keys outside Git. Physical-device install, touch ergonomics, thermal behaviour, sustained FPS and battery use still require a real Android acceptance test.

## Performance baseline

Compatibility renderer; aim for 30 FPS on entry-level Android and 60 FPS on capable devices after physical testing. Particle counts, shadows, lights and draw calls are intentionally restrained. Headless CI success is not a performance benchmark.

## Licences and asset setup

See `assets/ASSET_MANIFEST.md` for the CC0 character and animation sources, provenance, and reproducible setup. No paid asset service is required. Do not include God of War assets, models, animations, audio, logos or level layouts.
