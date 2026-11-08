# Nova Ancient Warrior — Professional High-Fidelity Game Standard

**Decision date:** 2026-11-08  
**Branch:** `nova-full-campaign-polish`  
**Priority:** visual fidelity, believable presentation, responsive gameplay and complete content first. Android size and broad backward compatibility are secondary.

This is the production standard for Nova Ancient Warrior. The current project is a playable systems prototype, not yet a commercially polished game. All new work must move it toward a coherent third-person action-adventure experience with the production feel of well-made console/mobile titles. References such as GTA: San Andreas, PES and Need for Speed are quality references for camera, input response, animation, UI feedback, world readability and presentation; they are not a claim that this small project already matches the scope, content volume or proprietary assets of those games.

## 1. Platform and rendering decision

### Master presentation target
- Author and review the game at **1920×1080 Full HD** as the baseline master presentation.
- Use a desktop/high-end visual profile as the primary art-review target.
- Target a stable 60 FPS as a quality goal on a suitable desktop GPU; this is an acceptance target, not a measured result.
- Do not remove shadows, glow, materials, animation or world detail merely to preserve support for old phones.
- Keep source assets at high quality and create platform-specific exports later.

### Current engine configuration
The current Godot project has been moved away from the old Compatibility-only configuration:
- Desktop: Godot **Forward+** renderer.
- Android: Godot **Mobile** renderer on Vulkan-capable devices.
- Web: Compatibility renderer override.
- Runtime render profile now preserves glow and key-light shadows on Android instead of disabling them unconditionally.
- Both desktop and Android use a 60 FPS cap as an initial target. Actual frame pacing must be measured; do not present the cap as proof of 60 FPS performance.

The Mobile renderer does not expose every Forward+ feature. For example, volumetric fog, SDFGI and VoxelGI are Forward+-only; the Android visual plan should use baked LightmapGI, reflection probes, carefully authored materials, particles and shader-based atmosphere where the Mobile renderer requires alternatives.

### Unreal Engine evaluation
Unreal Engine 5.8 is a legitimate high-fidelity comparison candidate, not an automatic migration decision:
- Evaluate one controlled vertical slice: the same hero, one arena/temple environment, one enemy, one boss reveal, the same camera framing and the same animation set.
- Compare the result with Godot Forward+ on visual quality, animation workflow, build reproducibility, source-control footprint and the ability to produce a testable Android build.
- Unreal's Lumen support on Android is documented as experimental and limited to high-end Android Vulkan SM5 device profiles. Do not assume it works on every Android phone.
- If Unreal is materially better and can be built and tested reproducibly with the available free toolchain, create a migration proposal before porting the gameplay code. Do not discard the working Godot prototype until the Unreal slice passes the same acceptance checklist.
- Unreal Engine is free to start for game developers under Epic's current licensing terms, but it is not the same as an OSI open-source engine and royalties may apply after the stated revenue threshold. Re-check the licence at release time.

## 2. Quality bar: character and animation

The current generated hero is explicitly a placeholder-quality, primitive-built prototype. It must not be presented as a realistic final character.

Final hero requirements:
1. A designed human face with readable facial planes, eyes, eyelids, mouth, ears, nose, brows, facial hair/scars only if they serve the character design.
2. Anatomically coherent proportions, hands, feet, shoulders, elbows, hips, knees and neck.
3. Separate PBR materials for skin, eyes, hair, cloth, leather, metal, stone and weapon materials. Use base colour, normal, roughness, metallic and occlusion maps where appropriate.
4. Proper UVs, clean retopology, skin weights and deformation checks. No visible mesh intersections through armour during core movement.
5. A face rig or blend-shape set for blinking, brows, mouth shapes and emotional acting. Preserve facial morph targets in final exports.
6. A consistent humanoid skeleton and animation retarget map shared by hero and humanoid enemies.
7. High-detail hero source mesh plus real-time mesh/texture LODs. LODs must preserve silhouette and animation readability.

Required animation coverage:
- Idle variants, breathing, turn-in-place, start/stop, walk, jog, sprint, pivots, strafing, jump, fall and landing.
- Three or more sword attacks with clear anticipation, contact and recovery; heavy attacks; directional attacks; guard; parry; dodge; hit reactions; stagger; knockdown; get-up; finisher; victory; death.
- Root motion or carefully synchronized in-place locomotion; eliminate foot sliding, weapon grip drift, joint snapping and abrupt blend pops.
- Face and body performance remain separately testable.

Use Blender, Rigify, MPFB2/MakeHuman or other reviewed open tools for original character production. Capture real performers only with informed consent and cleared recording rights. Clean mocap in Blender and retarget to the project's canonical skeleton. The existing 61-bone sample capture is research input only; it is not the final player animation set.

## 3. Quality bar: world and level design

Replace the reused combat-arena presentation with separately authored spaces. Each chapter must have:
- A distinct visual identity, silhouette, architecture, lighting, colour script, environmental storytelling and soundtrack variation.
- Traversal spaces, combat spaces, quiet story spaces, landmarks, side paths, gates, elevation changes and authored transitions.
- Correct collision, navmesh/navigation regions, occlusion opportunities, readable hazards, checkpoints and recovery routes.
- Hero-scale set dressing, material variation, decals, debris, foliage where suitable, weather/atmosphere and layered ambience.
- A final boss area that feels designed for that boss, rather than reusing the same arena with a palette swap.

Target a cinematic camera language: controlled third-person follow camera, collision-aware camera boom, smooth acceleration/deceleration, target framing, deliberate boss reveals, scripted cutscene cameras, and reliable return to gameplay camera state.

## 4. Quality bar: combat and player feel

Combat must feel responsive and legible:
- Use a state-driven character controller and animation state machine rather than isolated visual swaps.
- Distinguish input buffering, attack commitment, cancel windows, hit-stop, hit-stun, invulnerability frames, guard/parry timing, recovery, stamina or another balancing resource.
- Use explicit hitboxes/hurtboxes and enemy attack telegraphs with fair timing.
- Enemy archetypes need different tactical behaviours: spacing, aggression, guarding, flanking, ranged pressure or support roles as appropriate.
- Boss encounters need readable multi-phase behaviour, unique attack patterns and consistent telegraphs.
- Add camera shake, impact effects, controller rumble where supported, hit sparks, material-specific impact sounds and combat audio mix. Effects must reinforce contact rather than hide it.
- Support keyboard/mouse, gamepad and touch through one input abstraction. The UI must not cover the active combat space.

## 5. Writing, cinematics and sound

The campaign needs a complete authored narrative package:
- A one-page premise, character bible, chapter summaries, mission beats, antagonist motivations and a resolved ending.
- Every cutscene gets a shot list, camera position/lens intent, blocking, action, dialogue, subtitle timing, sound cue and transition back to player control.
- Dialogue must be character-specific, concise and performable. No generic exposition dumps.
- Record or generate original/appropriately licensed voice assets. Keep dialogue, music, ambience and SFX on separate buses.
- Add subtitle timing, speaker identification, language-ready text resources and audio settings.
- Use original compositions or clearly licensed audio. Do not ship copied game music, film dialogue, voices or unlicensed samples.

## 6. Free tool and asset policy

Use free/open-source sources first and maintain a per-asset provenance ledger. Candidate sources include:
- Code and engine: Godot, GitHub, GitLab, Bitbucket, SourceForge.
- Modelling and animation: Blender, MakeHuman, MPFB2, Rigify, FreeMoCap, Khronos glTF tools.
- Textures, HDRI and models: Poly Haven, ambientCG, OpenGameArt, Kenney, Quaternius, Godot Asset Library, Fab freebies and Unity Asset Store freebies.
- Audio: OpenGameArt, Freesound, Sonniss free bundles, Audacity and Ardour.
- QA and profiling: Godot headless tests, GitHub Actions, RenderDoc, Perfetto and Android GPU Inspector where available.

A source being free to download does not prove that an asset is free for commercial redistribution. Check the exact asset-level licence and record creator, source URL, licence version, attribution text, modifications, file hash and any restrictions. Never copy proprietary assets from GTA, PES, Need for Speed, Unreal sample projects or other commercial titles.

## 7. Six-pass QA and visual acceptance

The repository's six-pass workflow is a baseline regression gate, not a substitute for real visual QA. Keep the six automated passes:
1. Static source and project integrity.
2. Generate character/audio assets and verify outputs.
3. Clean Godot import.
4. Character, skeleton, animation and audio tests.
5. Combat, campaign, save, navigation and hazard regression.
6. Android profile and real main-scene boot.

Add manual/recorded visual review gates before calling a build production-ready:
- Hero: front/side/back close-ups, facial expression, armour deformation, walk/run/attack/dodge/parry.
- World: wide establishing shot, close-up material shot, lighting at multiple times/areas, traversal and combat view.
- Camera: normal follow, lock-on, wall collision, boss reveal, cutscene-to-gameplay handoff.
- Gameplay: full boss fight, enemy crowd, damage/death/restart, checkpoint and chapter transition.
- Audio: dialogue clarity, spatial/ambience balance, hit confirmation, music transitions.
- Device tests: real-device frame-time capture, input latency, memory, temperature and crash logs on target hardware.

A successful headless test proves only the tested code path. It does not prove photorealism, good animation, complete game content, stable mobile performance or player fun. Keep these claims separate in every status report.

## 8. Production order

1. Freeze a known-good playable baseline and maintain build reproducibility.
2. Create a high-fidelity hero and one complete animation set.
3. Build one visually final vertical-slice level with one enemy archetype and one boss.
4. Complete the camera, input, combat and audio feel for that slice.
5. Run a Godot Forward+ versus Unreal 5.8 visual/workflow comparison before any engine migration decision.
6. Only after the vertical slice meets the visual/gameplay bar, build the remaining chapters and campaign content.
7. Package PC/desktop master and high-end Android separately; do not degrade the master assets to make every device run the same settings.

**Release claim rule:** The game is not “AAA”, “photoreal”, “complete” or “console-quality” until the actual playable build and captured footage pass the corresponding visual, gameplay and platform checks.