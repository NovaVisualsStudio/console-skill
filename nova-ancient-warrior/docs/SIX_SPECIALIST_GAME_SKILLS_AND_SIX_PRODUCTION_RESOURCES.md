# Six Specialist Game Skills and Six High-Value Production Resources

Reviewed: 2026-11-08
Project: Nova Ancient Warrior (Godot 4.7, Android mid/high tiers)

This is a project-specific specialist playbook and a vetted resource shortlist. It does not claim that external agents, desktop applications, asset packs, or downloaded files have been installed or imported. Each asset must pass the stated review gates before entering the game.

## Six specialist skills to apply

### 1. Character Art Director and Technical Character Artist
Own the hero, enemies and bosses as a coherent visual family. Define silhouette, anatomy, face, hair, cloth, armor layering, weapon proportions, texel density, topology, UVs, material separation and LODs. Replace the current procedural stylized hero only through a reviewed original production character pipeline; preserve the current playable fallback until the replacement passes import and gameplay checks.
**Acceptance:** clean deformation at shoulders/hips/knees, no visible mesh intersections in core combat poses, readable silhouette at gameplay camera distance, mobile-budget meshes and textures, correct GLB import.

### 2. Character Rigging, Retargeting and Combat Animator
Own skeleton design, skin weights, retargeting, AnimationTree state machines, blend spaces, root-motion policy, foot planting, hand/weapon alignment, additive hit reactions and animation LOD. Build a sword-focused library: idle, locomotion, start/stop, turns, light/heavy attacks, combo transitions, guard, parry, dodge, stagger, knockdown, recovery and death.
**Acceptance:** no foot sliding in locomotion, no weapon hand separation, no broken root motion, deterministic animation state transitions, no clipping in attack/guard/dodge tests.

### 3. Combat Systems and Gameplay Feel Designer
Own melee timing, startup/active/recovery windows, buffered input, cancel windows, hit-stop, hit reactions, target selection, lock-on, telegraphs, parry timing, enemy archetypes and boss phases. Keep Godot physics and hurtboxes authoritative; use C++ only for measured batch computations with a GDScript fallback.
**Acceptance:** attacks hit only valid targets in range/arc/line of sight, no duplicate damage per swing, no damage during invalid windows, fair telegraphs, reproducible combat tests.

### 4. Environment and Level-Design Artist
Create three genuinely distinct authored exploration chapters rather than relying on one arena with theme dressing: traversal routes, landmarks, combat pockets, verticality, secrets, puzzle beats, checkpoints, boss approach and narrative staging. Build modular kits with collision and navigation data, and stream large sections as needed.
**Acceptance:** each chapter has a distinct layout and gameplay loop, readable navigation, no collision holes/softlocks, acceptable memory and load times, and its own automated traversal checks.

### 5. PBR Materials, Lighting and VFX Technical Artist
Own consistent physically based materials, surface response, atmosphere, sky, shadows, fog, decals, particles, sword trails, sparks, dust, fire, impacts and boss telegraphs. Use a restrained mobile lighting budget; provide MID and HIGH variants and avoid expensive full-screen effects by default.
**Acceptance:** correct roughness/metalness/normal response, effects remain readable over the environment, no shader compile errors, bounded overdraw/particle counts, stable visuals in both mobile profiles.

### 6. Android Performance, QA and Release Engineer
Own frame-time budgets, profiling, memory, texture compression, draw calls, visibility/occlusion, LOD, asset import validation, touch ergonomics, audio lifecycle, thermal testing and signed release packaging. Keep the existing renderer baseline until controlled tests show a better option.
**Acceptance:** clean CI, repeatable test scenes, no leaks/errors, sustained device measurements (not just FPS caps), Android ARM64 build, API 36 release validation, protected signing and AAB checks before release.

## Six high-value resources

| Resource | Best use in Nova | License / gate | Priority |
|---|---|---|---|
| [Quaternius](https://quaternius.com/) | Rigged humanoid/enemy prototypes, modular props, weapons and environment kits; use as blockout or supporting assets, not as the final unique hero look | CC0 is stated on checked packs; verify the exact pack page and file contents | High |
| [Mixamo](https://www.mixamo.com/) | Fast humanoid auto-rigging and animation coverage for locomotion, reactions and initial combat blocking | Adobe says characters/animations may be used in personal and commercial games; humanoid-only constraints; retain downloaded source and check current terms | High |
| [Poly Haven](https://polyhaven.com/) | High-quality HDRIs, scanned PBR materials and selected environment props for lighting and surfaces | All published assets are CC0 according to its license page | High |
| [ambientCG](https://ambientcg.com/) | Consistent albedo, normal, roughness, height and AO texture sets for stone, metal, leather and terrain | CC0 1.0 according to its official license page | High |
| [Material Maker](https://www.materialmaker.org/) | Original procedural PBR materials, stylized-to-realistic surface variation and shader-driven material authoring | Editor source is MIT; community materials keep their own licenses; desktop authoring tool, not a runtime dependency | High |
| [Sonniss GDC Game Audio Bundle](https://sonniss.com/gameaudiogdc/) | Sword impacts, armor, footsteps, creature layers, ambience and cinematic sound design | Custom EULA permits synchronized use in games; do not resell/distribute raw sounds; AI/ML training is prohibited | High |

## Adoption order

1. Use Mixamo only to validate the rig/retarget pipeline; author and refine signature sword attacks rather than shipping generic motions unchanged.
2. Use Quaternius for temporary enemy/prop coverage and scene blockouts while commissioning or producing a distinct final art direction.
3. Build the three chapters with modular geometry and collision first; then add Poly Haven/ambientCG surface detail and controlled lighting.
4. Create original material variants in Material Maker; export texture maps at tier-specific resolutions and validate them in Godot.
5. Build the soundscape from Sonniss files only after reviewing the exact bundle EULA and recording source/filename/license metadata.
6. Run the six specialist acceptance gates on every integration batch. Keep rejected assets out of the project.

## Six review passes required for each production batch

1. **Architecture pass:** inspect scene ownership, dependencies, Godot version and fallback paths.
2. **Visual pass:** inspect silhouette, scale, materials, camera readability and art consistency.
3. **Animation/combat pass:** inspect rig deformation, weapon alignment, timing windows and state transitions.
4. **Level/interaction pass:** inspect traversal, collisions, navigation, hazards, checkpoints and softlocks.
5. **Mobile/performance pass:** inspect texture memory, draw calls, overdraw, particles, shaders, CPU/GPU frame time and thermal behavior on target devices.
6. **Regression/release pass:** run clean import, headless gameplay tests, Android export checks, leak/error scans and artifact verification.

A pass is only marked complete when there is a commit, a named test or inspection record, and an observed result. CI success does not imply a physical-device test. Do not claim the game is complete or AAA-equivalent until all production gates, content and device acceptance criteria are met.

## Current known blockers

- Current hero is procedural/stylized rather than photorealistic.
- The three chapters still share one arena base; separate authored exploration levels remain necessary.
- Full cinematics, dialogue, voice acting, subtitles/localization and accessibility are incomplete.
- Physical Android mid/high device performance, thermals, battery and touch ergonomics have not been certified.
- Production Android API 36, protected signing and AAB release validation remain required.
- The C++ extension must pass Linux runtime loading and smoke tests as well as Android ARM64 compilation before gameplay integration.
