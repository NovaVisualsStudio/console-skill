# Advanced Game-Development Skills Adoption - Nova Ancient Warrior

Reviewed: 2026-11-08  
Target: Godot 4.7, Android ARM64, medium/high device tiers  
Status: curated integration plan; upstream skills are references, not installed runtimes.

## Decision

Adopt a small, version-aware skill set instead of importing dozens of overlapping instructions. Keep Godot 4.7 and the existing project architecture. Do not change the renderer, migrate engines, add runtime dependencies, or activate the unfinished C++ GDExtension as a side effect of adopting skills.

The skill packs below are independent instructions. They can improve task decomposition and review consistency, but do not themselves create assets, run Blender/Godot, or prove game quality.

## Selected upstream skills

| Priority | Source | Useful capabilities | License / compatibility | Project decision |
|---|---|---|---|---|
| P0 | [awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) | 77 routed skills; Godot 4.7 GDScript, scenes, physics, animation, shaders, 3D, audio, export and headless tests; cross-discipline AI, procedural generation, level design, game feel and input | Apache-2.0 repository license; inspect NOTICE and per-file provenance before vendoring | Primary router/catalog. Select only Godot 4.7 and directly relevant discipline skills. Do not bulk-copy all engines. |
| P0 | [vl4dt/godot-skills](https://github.com/vl4dt/godot-skills) | Godot performance profiling, memory/resource management, pooling, LOD, instancing, draw calls, Android Perfetto | MIT; explicitly lists Godot 4.7 compatibility | Performance specialist reference. Apply only after profiling; independently verify code examples against this project. |
| P0 | [setcodes/gamedev-skills](https://github.com/setcodes/gamedev-skills) | Game design/GDD, Godot gameplay engineering, scene/resource handling, debugging and verification | MIT, version 1.0.0; Blender skill requires Blender 5.1+ and Blender Lab MCP | Use game-designer and godot-gamedev as focused review references. Blender skill remains conditional on an actual Blender runtime. |
| P1 | [EL4CTEO/blender-skills](https://github.com/EL4CTEO/blender-skills) | 22 Blender workflows: retopology/UV, PBR, baking, rigging, facial shape keys, animation/root motion, LOD, export and asset QA | MIT; Blender 5.2 LTS+; upstream says scripts are tested in real Blender | Preferred 3D-art pipeline reference for a future production hero, bosses and environment kits. Not executable in this GitHub-only session. |

## Project-specific skill routing

1. **Game Director / Combat Designer** - use the game-design and game-feel disciplines to define readable sword-combat loops, enemy roles, encounter pacing, upgrade economy and measurable playtest criteria. Preserve the original warrior identity.
2. **Godot Gameplay Engineer** - use Godot 4.7 GDScript, nodes/scenes, physics, animation, input and headless-test skills. Trace player input through state, animation, hit detection and feedback; avoid parallel systems.
3. **Combat & Enemy AI Engineer** - use AI, physics, navigation and game-feel disciplines. Specify enemy state machines, telegraphs, recovery windows, stagger, guard/parry and boss phases. Keep damage authority in the existing Godot gameplay layer.
4. **Character / Rigging / Animation Artist** - use Blender core, retopology/UV, PBR baking, character rigging, animation, game optimization and asset-QA skills. Validate skeleton mapping, skin weights, root motion, clip naming, scale, materials and GLB import before replacing any placeholder.
5. **Environment / Technical Artist** - use Godot 3D, shaders, lighting, procedural generation and Blender asset skills. Build modular, explorable chapter spaces rather than dressing one arena repeatedly; enforce texture, mesh, draw-call and memory budgets.
6. **QA / Performance Engineer** - use Godot headless testing, performance profiling and Android Perfetto. Test exported release builds on representative physical Android devices; record average FPS, 1% low, frame-time percentiles, memory, load time and thermal behavior.

## Execution gates

### Gate A - skill quality and provenance
- Pin each upstream repository to a commit SHA before copying any file.
- Preserve the upstream license, copyright notices and NOTICE file where applicable.
- Record the exact source path and commit SHA for each vendored skill.
- Reject skills with unclear provenance, conflicting Godot API guidance, or instructions requiring unavailable runtimes.
- Prefer links and project-authored checklists over copying entire repositories.

### Gate B - implementation
- Every task must name the player-visible behavior, affected project paths, acceptance criteria, regression tests and rollback point.
- Make one bounded change per branch/commit; keep existing scenes and assets intact.
- Do not import Unity/Unreal skills into the Godot runtime workflow except as design references.
- Do not introduce C++ until a repeatable profile identifies a CPU bottleneck and GDScript parity tests exist.

### Gate C - validation
- Static/script checks and headless tests are necessary but not sufficient.
- Validate scene boot, animation transitions, combat edge cases, save compatibility, resource loading and Android export.
- Compare before/after measurements on the same device, renderer, resolution and thermal conditions.
- Do not report a mobile FPS target as achieved without physical-device evidence.

## Immediate work order

1. Close the existing C++ GDExtension Linux load/smoke-test failure before considering activation. Android ARM64 compilation alone is not runtime validation.
2. Build a dedicated combat regression suite around sword attack arcs, target removal, hit-once behavior, interrupted attacks, dodge/guard windows, enemy death and scene restart.
3. Replace the current procedural/stylized hero only after a production-quality rigged character passes visual review and Godot import/animation tests.
4. Split the current shared arena dressing into genuinely distinct, traversable chapter levels with unique landmarks, encounter spaces and progression gates.
5. Add an asset validation pipeline for GLB skeletons, animation clips, texture dimensions/compression, missing materials, polygon budgets and duplicate resources.
6. Add Android profiling evidence and scalable Medium/High presets only after baseline measurements exist.

## Environment and connection limits

- GitHub repository changes and GitHub Actions checks can be performed through the connected GitHub integration.
- This does not provide a running Blender 5.2 desktop process, Blender Lab MCP, Godot Editor MCP, Android device, or physical-device profiler.
- No external skill pack is claimed to be installed or actively connected by this documentation change.
- The current C++ extension remains isolated until its native runtime tests pass.
- This file does not authorize merging PR #28 or changing the main branch.

## Source links

- https://github.com/gamedev-skills/awesome-gamedev-agent-skills
- https://github.com/vl4dt/godot-skills
- https://github.com/setcodes/gamedev-skills
- https://github.com/EL4CTEO/blender-skills
- https://docs.godotengine.org/en/4.7/tutorials/performance/index.html
- https://docs.godotengine.org/en/4.7/tutorials/performance/general_optimization.html
