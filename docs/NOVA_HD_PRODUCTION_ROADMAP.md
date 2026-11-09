# Nova Ancient Warrior - HD Realism Production Roadmap

**Status:** production roadmap. The detailed CI figures below are a historical snapshot from 2026-11-08 on `nova-full-campaign-polish`, not a claim about the current integration head. The active PR branch is `release/nova-ancient-warrior-integration-20261108`; always use its latest Actions runs and project README for current verification.

**Primary production standard:** [NOVA_PROFESSIONAL_GAME_STANDARD.md](NOVA_PROFESSIONAL_GAME_STANDARD.md) now defines the visual-first platform strategy, gameplay feel, character, animation, world, writing and release bar. [NOVA_ASSET_ECOSYSTEM_POLICY.md](NOVA_ASSET_ECOSYSTEM_POLICY.md) defines source discovery, asset scoring, licence checks and provenance. This roadmap is subordinate to both documents.

## 1. Verified baseline

Historical source branch: `nova-full-campaign-polish`  
Historical inspected commit: `4d9045e68866a7ddeebdf7e16fd5f9e679db1b98`  
Engine: Godot 4.7.2, GDScript. The active integration branch keeps Forward+ for desktop and GL Compatibility/OpenGL ES 3.0 for Android, with ARMv7 and ARM64 export targets. Its current mobile runtime profile caps Android at 30 FPS and disables glow and real-time key-light shadows; this is a conservative baseline, not a measured performance result.

Verified in GitHub Actions on the inspected commit:

- Godot validation run 140: success.
- Android debug APK run 124: success.
- Character/motion-capture run 32: success.
- The Android artifact contains a 28,704,968-byte ARM64 debug APK, package ID `com.novavisualsstudio.novaancientwarrior`, version `0.1.0-debug`. The pipeline verified its archive, package ID and APK v2/v3 signatures.
- The current Blender hero generator produced a skinned GLB of about 238 KB. The rig smoke test reported 20 bones and 10 animation clips.
- The separate motion-capture artifact contains a 3,008,128-byte humanoid GLB with a 61-bone skeleton, but only one body-motion clip. It was generated from the upstream CC0 sample video (149 frames at about 29.97 FPS), not from a custom performance capture, and is not wired into the player runtime. Its optimizer removed 52 morph targets; this is unsuitable as the final facial-animation asset unless the needed facial shapes are preserved in a revised export.
- The README correctly identifies this as a production prototype, not a finished commercial release.

### Current limits that matter most

1. The runtime hero is a stylized, primitive-built prototype, not a photoreal human with detailed face, hair, skin, clothing and deformation.
2. Three chapters are represented by themed arena layouts. The game still reuses one combat arena; it does not yet contain three authored exploration levels.
3. The game has combat, bosses, upgrades, saves, mobile controls, generated SFX and a procedural music layer. It does not yet have authored dialogue scenes, voice acting, subtitles, a finished narrative arc or complete cinematic staging.
4. CI proves import, headless gameplay checks and cloud APK export. It does not prove visual quality, real-device frame rate, thermal stability, battery use, touch comfort or memory behaviour.

## 2. Visual target and renderer strategy

The current visual-first but broad-compatibility target is defined in [NOVA_PROFESSIONAL_GAME_STANDARD.md](NOVA_PROFESSIONAL_GAME_STANDARD.md):

- Full HD 1920×1080 is the master art-review target.
- Desktop uses Godot Forward+ for the highest feature set available in the current engine.
- Android uses Godot Compatibility with OpenGL ES 3.0 as the broad device baseline. The APK includes ARMv7 and ARM64. A Vulkan Mobile profile may be added later as an optional high-end renderer after device testing.
- The active integration baseline uses a 30 FPS Android cap. A 60 FPS Android cap is a future target only, not an implemented or measured result; raise it only after sustained physical-device profiling.
- Older GLES-only devices are not the primary quality target. A compatibility fallback may be added later only if it does not compromise the master build.

Godot Compatibility has a smaller feature set than Forward+ and uses the OpenGL renderer. Preserve high-quality source models and textures, then use baked lighting, authored materials, reflection approximations, particles and shader atmosphere on Android. Do not claim desktop/Android visual parity without captured comparisons.

Do not assume visual parity between desktop and Android renderers. Maintain high-quality source assets, then create renderer-specific lighting, effects and material variants. Compare actual captured frames rather than selecting a renderer by name alone.

References:
- [Godot 4.7 renderer feature matrix](https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html)
- [Godot 4.7 renderer and platform features](https://docs.godotengine.org/en/4.7/about/list_of_features.html)
- [Godot 4.7 system requirements](https://docs.godotengine.org/en/4.7/about/system_requirements.html)
- [NOVA professional high-fidelity standard](NOVA_PROFESSIONAL_GAME_STANDARD.md)

## 3. Realistic human character pipeline

### Recommended free/open-source base

Use **MakeHuman + MPFB2 inside Blender** to create a believable human base, then build the original hero identity and armour on top of it.

- MakeHuman/MPFB2 provides a human basemesh and configurable body proportions, age and phenotype controls.
- MPFB2's source code is GPL-3.0; its bundled character assets are CC0 1.0. Its project states that generated model output is treated as the user's output. Keep the code licence separate from the exported asset's licence.
- Blender and Rigify handle sculpting, retopology, UVs, skin weights, rig cleanup, armour, hair cards, facial shapes and glTF export.
- Khronos glTF 2.0 is the interchange target for the Godot asset pipeline.

Required art stages:

1. Build the hero's face and body at close-up quality. Avoid primitive spheres/cubes as the final head, hands, torso or armour.
2. Create separate, readable materials for skin, eyes, hair, cloth, leather, metal and weapon. Use a controlled PBR palette and author roughness/normal detail; do not rely on flat albedo colours.
3. Create clean topology and verify deformation at shoulders, elbows, wrists, hips, knees, fingers and neck.
4. Use a documented humanoid rest pose and a consistent skeleton map.
5. Preserve facial expression shapes needed for brows, blinks, mouth shapes and lip sync. Do not remove every facial morph target merely to reduce file size.
6. Produce a high-quality hero asset and simpler LODs for enemies and distance views.

Start with 1K–2K textures on the hero and 512–1K on common enemies/props, then profile GPU memory and bandwidth. Use a practical mobile mesh budget and reduce it with LODs rather than pursuing desktop-only geometry density.

Licensing references:
- [MPFB2 licence: GPL-3.0 code, CC0 bundled assets, output policy](https://github.com/makehumancommunity/mpfb2/blob/master/LICENSE.md)
- [MakeHuman CC0 asset licence](https://github.com/makehumancommunity/makehuman/blob/master/LICENSE.ASSETS.md)
- [Khronos glTF Blender importer/exporter](https://github.com/KhronosGroup/glTF-Blender-IO)

## 4. Motion capture and animation

The existing experimental VideoIntoBlenderModel workflow is useful as an intake/retarget experiment, not as a final animation library. The current successful sample has 61 bones but only one short body-motion clip; the sample is an upstream CC0 video. The 52 removed morph targets mean the optimized GLB is a body-motion candidate, not a facial-performance asset.

For production motion:

- Record a consenting performer on a phone with the full body visible, good lighting and minimal occlusion. For more reliable depth, use two or more synchronized camera angles where possible.
- Capture isolated takes instead of one long fight: idle, walk, run, start/stop, turns, jump, land, dodges, three light attacks, heavy attack, block, parry, stagger, hit reactions, knockdown, get-up, death and victory.
- Use Blender to clean foot sliding, root drift, joint flips, weapon grip, timing and clipping. Create separate hand/weapon constraints for sword and shield.
- Retarget using a consistent humanoid bone map and rest pose. Integrate the result through Godot AnimationTree state transitions with tested blends; do not rely on substring matching alone for final production animation states.
- Preserve body motion and facial expressions as separate, testable tracks.

FreeMoCap is another open-source markerless motion-capture option. Its application is AGPL-3.0, which is a licence consideration for distributing modified application code; motion recordings and third-party datasets have their own rights and consent requirements. The user-performed capture can be processed on a desktop/cloud runner; the Android handset need only record the video.

References:
- [VideoIntoBlenderModel pipeline](https://github.com/s0ck3t/VideoIntoBlenderModel)
- [FreeMoCap source and AGPL-3.0 licence](https://github.com/freemocap/freemocap)
- [FreeMoCap documentation](https://freemocap.github.io/documentation/)

## 5. Environments, props and sourced assets

Use **original environment layouts plus carefully licensed assets**. No ripped God of War/PS2 assets or copied character likenesses.

- [Poly Haven](https://polyhaven.com/) is the preferred source for HDRIs, PBR textures and suitable environment models because its assets are CC0.
- [OpenGameArt](https://opengameart.org/) is a useful catalogue for 3D props, dungeon pieces, ambience and combat sounds. Review the exact submission page and attribution notice for every downloaded file. CC0 is simplest; CC-BY requires proper credit; CC-BY-SA can require share-alike treatment and may conflict with some distribution/DRM arrangements. Do not assume that a site's overall policy replaces each asset's individual licence.
- [Material Maker](https://github.com/RodZill4/material-maker) can be used for procedural texture authoring; verify the project's current licence and each imported material before distribution.
- [Dust3D](https://github.com/huxingyi/dust3d) is a quick modelling/auto-rigging aid for rough assets, not the preferred route for the final realistic hero.
- SourceForge is a discovery/hosting site, not a game engine or an asset licence. Always inspect the upstream project's source, release and licence.

The campaign needs three genuinely distinct spaces, not only palette changes:
1. Sunken Ruins: exterior approach, collapsed temple traversal, a puzzle/obstacle space and a boss arena.
2. Ember Causeway: a hazardous bridge route, side platforms and a multi-phase boss encounter.
3. Obsidian Throne: an approach through enemy-held architecture, cover/verticality, rune mechanics and a final arena.

Each level must have its own collision, navigation, landmark composition, enemy entrance, checkpoint and exit. Keep combat arenas connected to short traversal sections so combat rhythm and story progression both exist.

Reference:
- [OpenGameArt FAQ and licence explanations](https://opengameart.org/node/5571)
- [Poly Haven asset licence](https://polyhaven.com/license)

## 6. Story, events and cinematic realism

The current names and chapter titles form a useful combat scaffold, but not yet a complete dramatic story. Build an original, historically grounded fictional narrative rather than claiming invented scenes are literal history. If a real civilisation or event is selected later, verify costumes, weapons, architecture, names, timeline and political details against reliable historical sources.

Minimum story deliverables:

- A short opening scene that establishes the hero's motive, the threat and the immediate stakes.
- A clear goal and consequence in each chapter; every major battle should advance the story.
- Three boss introductions with distinct behaviour, motive and battlefield mechanics.
- Brief in-engine dialogue scenes between battles, subtitles, readable Arabic/English localisation and a skip option.
- Human voice performances or properly licensed voice assets; separate dialogue, music, ambience and combat SFX buses.
- A final scene that resolves the hero's central conflict and the campaign's stakes.

The current boss camera reveal and chapter title cards are a starting point. They need authored camera blocking, character acting, facial animation, sound design and subtitle timing before they can be called finished cinematics.

## 7. Acceptance tests before calling the game complete

### CI / repository gate

- All gameplay smoke tests run with the project Autoloads and imported resources in context.
- The main scene launches headlessly with no script compile/load errors.
- Hero GLB import test verifies skin, skeleton, required animation names and facial-shape retention.
- Stage tests verify collision boundaries, hazards, checkpoints, nav routes and chapter exits.
- APK test verifies package ID, signature, ABI, archive integrity and version.
- Licence and asset-provenance register has a record for every third-party file.

### Human visual gate

- Review front/side/back close-ups and a 360-degree turn.
- Review face, hands, feet, armour intersections and weapon grip.
- Test every required animation in a neutral pose and during actual gameplay transitions.
- No detached vertices, collapsing joints, foot skating, weapon clipping or sudden pose snaps.
- Capture the master art review at 1920×1080 and separately inspect the same scene on a supported high-end Android device; do not use phone preview as the only art-quality reference.

### Real-device gate

- Validate the Android GLES3 baseline on a representative range of Android 7.0+ devices and both ARMv7 and ARM64. Vulkan can be tested as a separate high-end profile.
- Record average and 95th-percentile frame time, FPS, memory use, GPU/CPU load, touch latency, audio glitches and thermal behaviour.
- Run a 20-minute combat/traversal soak test and repeat it after changing render settings.
- Set a 60 FPS cap as the initial Android target, then measure frame times on representative low, mid and high-tier devices. Use quality scaling to avoid crashes or unplayable frame pacing; do not claim 60 FPS until measured.
- Test install, uninstall, reinstall, pause/resume, rotation policy, save persistence and offline startup.

## 8. Prioritised implementation order

1. Keep the existing verified debug APK as the playable engineering baseline.
2. Replace the primitive hero with a MakeHuman/MPFB2-based human, custom armour and retained facial shapes.
3. Build a complete cleaned animation set from recorded human performances; wire a deterministic AnimationTree.
4. Replace the single arena loop with three separate traversable chapters and scripted story beats.
5. Upgrade environment materials, props, lighting and sound using licensed CC0/attributed assets.
6. Add runtime quality tiers and profiling instrumentation for Android GLES3, then validate Vulkan as an optional enhanced profile without removing the broad-compatibility baseline.
7. Add full narrative cinematics, dialogue, subtitles and release-grade audio.
8. Produce a release-signed build only after device QA, licence audit and save migration tests pass.

**Release rule:** a successful APK export is a build milestone, not proof of a finished game. The game is production-ready only after the human-art, level, narrative, device-performance and licence gates above pass.
