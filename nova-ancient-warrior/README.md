# Nova Ancient Warrior - Third-Person Action Prototype

Nova Ancient Warrior is an original third-person 3D action game prototype built with Godot 4.7.2 and GDScript. The current build contains a nine-encounter combat campaign across three themed chapters, three bosses, local progression, save data, touch controls, generated audio and an original rigged hero. It is not yet a finished commercial game.

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
- Keyboard controls: WASD or arrows to move, J or Enter to attack, H for heavy attack, I to block, Tab to lock on, Shift or K to dodge, Space to jump, and R to restart.
- Procedurally generated original ambient music and 13 WAV sound effects.

## Character and animation status

Blender generates an original stylized low-poly armoured hero with a weighted humanoid skeleton, attached sword and shield, and twelve animation clips: Idle, Walk, Run, LightAttack, LightAttack2, LightAttack3, HeavyAttack, Dodge, Block, Parry, HitReact and Death. Godot CI imports this generated GLB and runs character and animation smoke tests.

This is a functional prototype character, not a photorealistic human. It does not yet have production facial anatomy, facial blend shapes, realistic skin and cloth materials, detailed armour sculpting, or a professionally authored motion-capture animation library. The separate markerless motion-capture workflow is experimental research output and is not yet the final player animation source.

## Rendering and Android compatibility

- Desktop renderer: Godot Forward+.
- Android renderer: Godot GL Compatibility, using the OpenGL ES 3 path for broader device coverage than a Vulkan-only requirement.
- Desktop master viewport: 1920 x 1080.
- Android viewport: 1280 x 720, with quality scaling still requiring physical-device profiling.
- Android export preset enables ARMv7 and ARM64 architectures.
- Initial frame-rate target: 60 FPS. This is a cap/target, not a measured performance guarantee.
- Glow and key-light shadows are enabled in the current visual profile. Actual GPU support, frame pacing, memory use and thermal behaviour must be tested on physical devices.

Compatibility mode improves the range of devices that may run the game, but it does not guarantee support on every Android phone or tablet. The published debug APK is a sideloading test build, not a Play Store release.

## Build and run

1. Install Godot 4.7.2 from https://godotengine.org/download/.
2. Open this folder as a Godot project.
3. Run `scenes/main.tscn`.

The Android GitHub Actions workflow generates the hero and sound assets, imports the project, exports a signed debug APK and validates the archive, signature and package identifier. The resulting workflow artifact is named `nova-ancient-warrior-android-debug`.

## Automated quality checks

The six-pass QA workflow currently checks source integrity, regenerated hero/audio assets, clean Godot import, character/animation/audio integrity, combat/campaign/save/hazard regression, Android renderer settings and a headless main-scene boot. A separate Godot validation workflow also runs focused smoke tests. Green CI runs prove these automated checks passed in the hosted runner; they do not prove visual quality, real-time performance or successful play on a physical Android device.

The repository-wide Python test suite is separate from the Godot QA workflow. Run it against the current branch head before release; a green Godot QA run does not imply that the separate Python suite passed.

## Cinematics, story and world status

Current presentation includes chapter title cards, boss introduction camera moves and combat feedback. Authored dialogue scenes, voice acting, subtitles, a complete narrative soundtrack and final story cinematics remain outstanding. The chapter environments are procedural combat arenas rather than complete authored exploration spaces.

## Asset provenance

The hero and audio generator code is original to this repository and generates its assets during CI. Record third-party asset sources, author, license and attribution requirements in `ASSET_PROVENANCE.csv` before adding external content. Do not assume a downloadable asset permits commercial use.

## Important platform note

This is a Godot Android game, not a PlayStation 2 executable. A real PS2 port would require a separate PS2SDK implementation and a different rendering, memory and controller design.
