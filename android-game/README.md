# NOVA - Ancient Warrior (cinematic vertical slice)

An original Godot 4 action-adventure prototype for Android ARM64, built as a separate project from the PS2SDK homebrew target in `ps2-game/`.

## Playable slice

- Third-person shoulder camera with smoothing, cinematic opening move, target lock-on and impact shake.
- Realistic CharacterCreator male human with 2K PBR skin/face textures, a 53-joint skeleton, CC0 skinned T-shirt, jeans, boots, trenchcoat and hair, plus bone-attached armor and a hand-bone war axe. Quaternius 65-joint humanoid remains as a fallback.
- Rigged humanoid enemy and boss variants using the same reusable character pipeline, with tint/scale variations and state-driven idle, chase, attack, hit and death animation requests.
- Three-hit light combo and stamina-cost heavy attack with distinct startup/active/recovery windows, one hit per target per swing, cancelable pending hits, dodge i-frames, guard and timed perfect parry.
- Two guardian enemies with visible pre-attack telegraphs.
- Ashen Warden boss with a 50% health phase transition and three distinct patterns: frontal melee, lateral sweep and radial slam. Warning rings change size and colour to signal the danger area; phase two cycles all three faster.
- Original temple arena with portal architecture, pillars, ritual rings, emissive braziers, fog and floating ash; 1K CC0 stone-wall and rock-tile PBR sets (diffuse, OpenGL normal and roughness) are applied to the floor, walls and portal masonry.
- Cinematic letterbox/title handoff, original procedural ambient drone and combat sounds, hit sparks, player/boss health UI, stamina and mobile touch controls.
- Android landscape export preset and reproducible CI-built debug APK.

The primary character uses the CC0 generated CharacterCreator body and skinned outfit assets, retargeted to the CC0 Quaternius Universal Animation Library 2 Standard pack at runtime. The pack provides 130+ motions; NOVA also adds an original skeletal death-fall clip because the selected pack has no dedicated death animation. The fallback Quaternius base character is retained. All generated binaries are fetched automatically in CI; local development needs Node.js/npm and `npm install --global @gltf-transform/cli@4.5.1`, then can run `python3 tools/fetch_cc0_animations.py` and `python3 tools/fetch_cc0_textures.py` from this folder. The PBR fetcher downloads only 1K JPG maps from Poly Haven, verifies API MD5 hashes, and needs no account, token, paid API or subscription. The setup script dequantizes the generated CC0 GLBs to standard glTF vertex formats for Godot 4.7 compatibility. CharacterCreator source code is GPL-3.0, but only its generated CC0 GLB outputs are used; no generator source code is bundled. This is a much more realistic textured foundation, but final visual polish and real-device review remain required before calling it a finished commercial-quality game.

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

See `assets/ASSET_MANIFEST.md` and `assets/textures/ASSET_LICENSES.md` for the CC0 character, animation and PBR material sources, provenance and reproducible setup. The in-game HUD displays the requested Poly Haven credit. No paid asset service is required. Do not include God of War assets, models, animations, audio, logos or level layouts.
