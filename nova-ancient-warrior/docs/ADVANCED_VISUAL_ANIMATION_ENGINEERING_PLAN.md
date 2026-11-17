# Nova Ancient Warrior - Advanced Visual, Animation & Runtime Engineering Plan

Status: implementation roadmap for the existing Godot 4.7 Android project. This document does not claim that the systems below are already implemented.

## Production objective

Raise perceived visual fidelity, motion quality, combat readability, and Android stability without turning the project into an untestable collection of expensive effects. The target is the medium-to-high Android device tier. Every quality feature must have a measurable cost and a fallback.

## 1. Technology stack and responsibility boundaries

| Layer | Preferred technology | Responsibility |
|---|---|---|
| Game orchestration | GDScript | State, quests, UI, save data, encounter flow, gameplay tuning |
| Native hot paths | C++ via Godot GDExtension | Only profiled CPU-heavy batches: target scoring, crowd steering, procedural data processing |
| Rendering | Godot 4.7 Mobile / Compatibility evaluation | Mobile-first lighting and material budgets; retain Compatibility fallback |
| Materials and effects | Godot spatial shaders | Character skin/cloth/metal response, dissolve, impact flash, stylized-realistic VFX |
| Character/prop authoring | Blender | Retopology, UVs, LODs, rigging, animation cleanup, collision proxies |
| Animation runtime | AnimationPlayer + AnimationTree | State transitions, blend spaces, one-shots, additive layers and synchronized locomotion |
| Asset interchange | glTF 2.0 | Consistent skeletal mesh, material and animation import |
| Validation | Godot headless + GitHub Actions | Import, parse, smoke, regression, Android export and artifact checks |

Do not add C# or another engine layer unless a concrete feature justifies the extra runtime and build complexity. C++ is not a graphics-quality switch: it is reserved for measured CPU bottlenecks. Keep authoritative collision, damage, animation playback and scene ownership in Godot until profiling proves otherwise.

## 2. Character realism and animation pipeline

### Character asset standards
- Replace placeholder/procedural hero geometry progressively with licensed, production-quality humanoid assets; preserve the established warrior identity and silhouette.
- Use a clean deformation topology, consistent scale, named skeleton bones, sensible bone weights and a documented humanoid retarget map.
- Separate body, armor, cloth, hair and weapon where this improves deformation or material control.
- Author at least three LODs for hero/enemy meshes and test silhouette quality at actual mobile screen size.
- Use physically plausible roughness/metalness ranges; avoid making all armor uniformly shiny.
- Pack ORM data where appropriate and provide ETC2/ASTC variants according to device support.

### Animation graph
Build an AnimationTree state machine with explicit locomotion, combat, reaction and traversal subgraphs:
- Idle / walk / jog / sprint with 2D directional blend space.
- Start, stop, pivot and turn-in-place clips to prevent skating and abrupt rotation.
- Sword light/heavy attacks, combo windows, recovery, guard, parry, dodge and stagger.
- Hit reactions selected by hit direction and severity.
- Additive upper-body aim/guard/weapon layers where the rig supports them.
- Animation events (call-method tracks or a controlled event layer) synchronize weapon trails, sound, hit windows and camera impulse. Damage must still be confirmed by gameplay hitboxes/physics, not by a visual effect alone.
- Root motion is opt-in per clip and must be reconciled with CharacterBody3D movement to avoid double motion.

### Procedural motion
- Add foot-contact/foot-plant correction only after a stable locomotion graph exists.
- Use raycasts for ground adaptation and bounded pelvis/foot offsets; clamp correction to avoid snapping on stairs.
- Use hand/weapon IK for grip alignment and two-hand weapon poses.
- Add secondary motion for cloth, straps and hair with lightweight bones or spring logic; disable or reduce it for distant characters.
- Use animation LOD: full-rate hero animation nearby, reduced update rate for distant enemies, no unnecessary updates for hidden characters.

### Combat feel
- Separate attack intent, active hit window, recovery and cancel windows.
- Use swept weapon traces or sampled blade segments between animation frames to reduce tunneling at high swing speed.
- Add hit-stop, recoil, enemy stagger and camera impulse with strict duration/intensity caps.
- Keep dodge invulnerability and parry timing data-driven and regression-tested.
- Validate attack arcs and target selection against the same deterministic test cases in GDScript and C++.

## 3. Rendering and technical art

### Mobile rendering strategy
- Do not switch the project renderer globally without an A/B benchmark. Compare Mobile (Vulkan) and Compatibility (OpenGL) on representative devices/builds; keep a supported fallback.
- Prefer baked lighting for static architecture, controlled dynamic key lights for combat, and a small number of shadow-casting lights.
- Use reflection probes selectively; avoid expensive real-time reflections on mobile.
- Use fog/atmosphere through inexpensive distance fog and layered art direction before considering costly volumetric effects.
- Keep transparent particles and overdraw under control; use GPU particles only where supported and beneficial.

### Scene scalability
- Frustum culling, baked occlusion culling where scene geometry benefits, visibility ranges, LOD/HLOD and instancing for repeated props.
- Stream large chapters by zones rather than keeping every environment and enemy resident.
- Use simplified collision meshes, not render meshes, for gameplay physics.
- Pool short-lived VFX and frequently spawned projectiles where profiling shows allocation spikes.
- Keep draw-call, visible-triangle, shadow-caster, material and texture-memory budgets per chapter.

### Shader and VFX library
Create reusable, parameterized shaders/effects for:
- PBR skin/cloth/metal with controlled roughness and edge response.
- Wetness/dust accumulation only where visible and affordable.
- Sword trails, sparks, impact decals, dust bursts, embers and environment hit feedback.
- Dissolve/fade transitions for enemy death and chapter events.
- Distance fog, heat shimmer or screen distortion only as optional quality-tier effects.

Every shader needs a Compatibility-safe fallback or a documented device restriction. Avoid per-pixel loops and unnecessary screen-texture reads on mobile.

## 4. Camera, audio and presentation

- Camera collision, shoulder offset, target lock, soft follow, acceleration/deceleration and combat framing must be tuned together.
- Use camera shake as short, low-amplitude feedback; never obscure enemy telegraphs.
- Spatialize combat audio where supported; layer blade whoosh, contact, armor impact, footsteps, ambience and music with distance/priority limits.
- Use authored audio variations and random pitch/volume ranges to reduce repetition without changing important cues.
- Cinematic camera cuts must preserve player orientation and return control without snapping.

## 5. Android quality tiers

Create three runtime profiles, selected from conservative capability checks and user settings:

| Feature | Medium | High |
|---|---|---|
| Internal render scale | Dynamic, conservative | Higher target, dynamic fallback |
| Shadows | One key shadow light, reduced map size | Higher map size, still limited casters |
| LOD | Earlier transitions | Later transitions |
| Effects | Reduced particles, no costly screen effects | More particles and selected post effects |
| Animation | Full hero, reduced distant actors | Higher update rate for more actors |
| Texture variant | ETC2 baseline | ASTC where device supports it |

Do not promise a fixed FPS before device profiling. Target frame-time budgets are 33.3 ms for 30 FPS and 16.7 ms for 60 FPS. Measure sustained performance after thermal warm-up, not only a short cold run.

## 6. Automated quality gates

Each change should pass:
1. Static GDScript/C++ checks and project file integrity.
2. Clean Godot import with no missing resources.
3. Character skeleton, animation names, clip duration and event validation.
4. Combat regression: attack arc, hit window, dodge, guard, parry, stagger and enemy death.
5. Scene/campaign/save regression.
6. Headless main-scene boot and Android export validation.
7. Native extension load test on desktop and ABI/build validation for Android ARM64.
8. Performance capture on representative Android devices: CPU frame time, GPU frame time, memory, thermal state, draw calls and frame pacing.

A successful CI run is not a substitute for testing on a physical phone. Keep measured device results separate from CI results.

## 7. Delivery order

### Phase A - Establish a reliable baseline
Record current build size, renderer, frame times, memory, scene boot, animation coverage and known visual gaps. Preserve the current stable renderer until comparisons exist.

### Phase B - Make the warrior feel alive
Complete the humanoid rig/retarget map, AnimationTree locomotion, combat state machine, hit reactions, foot planting and weapon/hand IK. This has higher player-visible value than adding many post-processing effects.

### Phase C - Raise material and lighting quality
Build the reusable PBR material library, lighting presets, fog, VFX and LODs. Validate on medium-tier hardware at native play scale.

### Phase D - Complete production content
Build distinct explorable chapters, enemy archetypes, boss behaviors, traversal, checkpoints, cinematics, subtitles, soundscape and progression. Avoid disguising one repeated arena as several independent levels.

### Phase E - Optimize and ship
Profile, tune quality tiers, verify Android ARM64 native packaging, export signed release AAB, and complete Android/Play requirements before any release claim.

## 8. Acceptance criteria

A feature is not complete because its script exists. It is complete only when:
- It is integrated into the actual main game flow.
- It has a reproducible test or content validation.
- It has no missing dependencies or licensing ambiguity.
- It has a documented medium/high device fallback.
- Its visual/gameplay improvement is observable in a playable build.
- Performance claims are supported by recorded measurements.

## References
- Godot 4.7 AnimationTree: https://docs.godotengine.org/en/4.7/tutorials/animation/animation_tree.html
- Godot 4.7 rendering architecture: https://docs.godotengine.org/en/4.7/engine_details/architecture/internal_rendering_architecture.html
- Godot 3D performance optimization: https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html
- Godot 4.7 release notes: https://godotengine.org/releases/4.7/
- Official godot-cpp bindings: https://github.com/godotengine/godot-cpp
