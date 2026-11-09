# Nova Ancient Warrior - Third-Person Action Prototype

Nova Ancient Warrior is an original third-person 3D action game prototype built with Godot 4.7.2 and GDScript. The current branch contains a nine-encounter combat campaign across three dedicated chapter PackedScenes, three bosses, local progression, save data, Arabic/English UI, touch controls, generated audio and an imported rigged humanoid hero. It is not yet a finished commercial game or a device-certified release.

## Current campaign

- Chapter I: The Sunken Ruins, ending with The Ash Titan.
- Chapter II: The Ember Causeway, ending with The Ember Warlord.
- Chapter III: The Obsidian Throne, ending with The Obsidian Sovereign.
- Nine encounters total, with boss encounters at waves 3, 6 and 9.
- Each chapter has a distinct procedural visual theme and hazards with warning windows and safe routes.
- Important limitation: all three chapters currently reuse one arena scene with different chapter dressing. They are not yet three separately authored exploration levels with traversal, puzzles and authored collision layouts.

## Implemented gameplay

- Three-hit sword combo, heavy attack, directional dodge with invulnerability frames, guard, timed perfect parry and target lock.
- Enemy approach, telegraph, strike and recovery states, with three enemy stat archetypes and three boss attack profiles.
- Versioned offline save data, wave resume, checkpoints, campaign progression and permanent Soul Forge upgrades.
- Touch controls for movement, attack, heavy attack, jump, lock-on, dodge and block.
- Title screen with a live 3D hero preview, new campaign, save-aware continue/replay, settings, tutorial and credits.\n- Arabic/English language selection persists in the offline save profile; title screen, pause menu, HUD, touch captions, mission prompts, chapter cards, upgrades and dialogue support both languages.\n- Pause overlay with resume control, persistent music / sound-effect volume sliders and in-game language switching; pause input remains active while the game simulation is frozen.
- Keyboard controls: WASD or arrows to move, J or Enter to attack, H for heavy attack, I to block, Tab to lock on, Shift or K to dodge, Space to jump, and R to restart.
- Original ambient music baked to a looping WAV at build time, plus 13 generated WAV sound effects; runtime playback uses an imported stream rather than a per-frame audio generator.
- Right-side touch dragging rotates the third-person camera; the separate lower-right action cluster remains reserved for combat controls.
- Campaign architecture and the arena floor use shared procedural albedo, roughness and normal maps generated at runtime by a small noise-texture library.
- Mid profile uses cached 128x128 procedural PBR maps; the opt-in High profile uses 256x256 maps for stronger surface detail. This is a source-resolution tier, not a measured FPS or memory guarantee.
- Chapter dressing now adds extra masonry piers, carved bands, rubble, basalt fractures and throne rune shards. Collision-backed layouts also add optional flank steps, side walks and cover blocks while keeping the central combat lane open.

## Character and animation status

The runtime player now uses a generated humanoid GLB produced by the reproducible Ara 3D Gen pipeline, with MakeHuman CC0 character data and a curated CMU Graphics Lab motion-capture set. The currently committed asset is approximately 16.86 MB, 1.857 m tall, with 46,032 triangles, a 69-bone game rig, 22 material definitions (8 textured PBR surfaces in Godot), and 16 curated locomotion/combat clips. The determined facial expression is baked into the mesh; unused facial and speech blend shapes are omitted for mobile memory efficiency. Godot CI imports the GLB and checks its skeleton, material slots and required locomotion/combat animation clips. A procedural visual remains as a fallback if the GLB cannot be loaded.

The asset is a significant upgrade over the original low-poly placeholder, but it is not yet approved as a photorealistic, final-quality human. Final visual sign-off must inspect face anatomy, skin/cloth response, armour detail, deformation under every combat animation, weapon grip/socket alignment and the quality of the retargeted motion. Facial blend shapes, facial performance capture and professional voice/performance capture are not yet part of the shipped game.

## Rendering and Android compatibility

- Desktop renderer: Godot Forward+.
- Android renderer: Godot GL Compatibility, using the OpenGL ES 3 path for broader device coverage than a Vulkan-only requirement.
- Desktop master viewport: 1920 x 1080.
- Android viewport: 1280 x 720; quality scaling and sustained performance still require physical-device profiling.
- Android export preset targets ARM64 only, matching the mid/high-tier device scope and avoiding the extra ARMv7 native library payload. The APK workflow verifies that the ARM64 library is present and no ARMv7 libraries are packaged.
- Android now exposes a saved MID profile (45 FPS cap, conservative lighting) and an opt-in HIGH profile (60 FPS cap, glow and key-light shadows) with larger environment-detail budgets. These are configurable caps, not measured performance guarantees; high-tier 256px PBR maps, effects and increased geometry still require physical-device memory, thermal and frame-pacing tests.
- Desktop retains a 60 FPS cap, glow and key-light shadows.
- Raising Android frame rate or re-enabling expensive effects requires measurements on representative physical devices.

Compatibility mode improves the range of devices that may run the game, but it does not guarantee support on every Android phone or tablet. Debug APK exports are test artifacts, not Play Store releases.

## Build and run

1. Install Godot 4.7.2 from https://godotengine.org/download/.
2. Open this folder as a Godot project.
3. Run `scenes/title_screen.tscn` (the configured main scene); select New Campaign or Continue to enter `scenes/main.tscn`.

The Android GitHub Actions workflow generates the hero and sound assets, imports the project, exports a signed debug APK and validates the archive, signature, package identifier, target SDK 36 and ARM64-only native payload. The resulting workflow artifact is named `nova-ancient-warrior-android-debug`. This is still a debug artifact, not a signed production AAB.

## Optional local model review

The optional `tools/deepseek_review.py` utility is a read-only development helper.
It accepts only a local HTTP inference server bound to `localhost`, such as a
locally hosted open-weight model. Hosted DeepSeek APIs, remote endpoints, API
keys and paid inference are disabled under the repository's zero-cost policy.
No AI review is required to run or play the game.

See [DEEPSEEK_INTEGRATION.md](DEEPSEEK_INTEGRATION.md) for local-only setup,
security limits and the distinction between model suggestions and deterministic
tests. The hosted DeepSeek Actions workflow has been removed.

## Automated quality checks

The six-pass QA workflow currently checks source integrity, regenerated hero/audio assets, clean Godot import, character/animation/audio integrity, combat/campaign/save/hazard regression, Android renderer settings and a headless main-scene boot. A separate Godot validation workflow also runs focused smoke tests. Green CI runs prove these automated checks passed in the hosted runner; they do not prove visual quality, real-time performance or successful play on a physical Android device.

The repository-wide Python test suite is separate from the Godot QA workflow. Run it against the current branch head before release; a green Godot QA run does not imply that the separate Python suite passed.

## Cinematics, story and world status

Current presentation includes chapter title cards, boss introduction camera moves, original branching-free story dialogue overlays and Arabic/English subtitles for chapter and boss conversations. Voice acting, a complete narrative soundtrack, facial performance and final story cinematics remain outstanding. The chapter environments are separate procedural combat arenas rather than complete authored exploration spaces.

## Asset provenance

The hero and audio generator code is original to this repository and generates its assets during CI. Record third-party asset sources, author, license and attribution requirements in `ASSET_PROVENANCE.csv` before adding external content. Do not assume a downloadable asset permits commercial use.

## Validated mobile hero pipeline

The committed Ara-generated NOVA hero is a 69-bone humanoid with 16 curated locomotion, sword-combat, dodge, hit, death and jump clips, plus eight textured PBR materials. The Android packaging workflow verifies the committed GLB checksum, creates a temporary mobile copy, removes unused facial morph-target data, and keeps the full source GLB unchanged in the repository. The imported mobile hero is then checked by the rig/animation smoke test before APK export. The current ARM64 debug APK measured 41,976,173 bytes; this is a debug build, not a production-signed release.

## Important platform note

This is a Godot Android game, not a PlayStation 2 executable. A real PS2 port would require a separate PS2SDK implementation and a different rendering, memory and controller design.
