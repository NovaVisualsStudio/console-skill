# NOVA - Ancient Warrior (cinematic vertical slice)

An original Godot 4 action-adventure prototype for Android ARM64, built as a separate project from the PS2SDK homebrew target in `ps2-game/`.

## Playable slice

- Third-person shoulder camera with smoothing, cinematic opening move, target lock-on and impact shake.
- Procedural low-poly warrior model with heavy war axe, armor parts and swing motion.
- Three-hit light combo, stamina-cost heavy attack, dodge i-frames, guard and timed perfect parry.
- Two guardian enemies with visible pre-attack telegraphs.
- Ashen Warden boss with a 50% health phase transition and stronger second-phase attacks.
- Original temple arena with portal architecture, pillars, ritual rings, emissive braziers, fog and floating ash.
- Cinematic letterbox/title handoff, original procedural ambient drone and combat sounds, hit sparks, player/boss health UI, stamina and mobile touch controls.
- Android landscape export preset and reproducible CI-built debug APK.

The models and animation motions are still procedural primitives/tweens. This is a cinematic mechanics slice, not final AAA character art or a finished full game. Replace primitives with original rigged Blender models and authored animation clips before production release.

## Controls

Desktop: WASD movement, J light combo, K heavy attack, Space dodge, L guard/parry, Tab lock target.

Android: left directional pad; right LIGHT, HEAVY, DODGE, GUARD and LOCK controls. Landscape orientation is required.

## Open in Godot

Open this folder in Godot 4.4.1 or newer and run the project. The CI pipeline runs editor import, combat tests, cinematic integration tests, procedural audio checks, headless runtime tests, six repeat stability passes and Android ARM64 debug export.

## Android APK

The workflow uploads `nova-ancient-warrior-android-debug` as a 14-day artifact after a successful build. It is a debug APK, not a store-signed release. Keep production signing keys outside Git. Physical-device install, touch ergonomics, thermal behaviour, sustained FPS and battery use still require a real Android acceptance test.

## Performance baseline

Compatibility renderer; aim for 30 FPS on entry-level Android and 60 FPS on capable devices after physical testing. Particle counts, shadows, lights and draw calls are intentionally restrained. Headless CI success is not a performance benchmark.

## Licences

All current game scripts and procedural geometry are original project content. Third-party assets must be reviewed individually and recorded in an asset manifest with creator, source URL, licence and attribution requirements. Do not include God of War assets, models, animations, audio, logos or level layouts.
