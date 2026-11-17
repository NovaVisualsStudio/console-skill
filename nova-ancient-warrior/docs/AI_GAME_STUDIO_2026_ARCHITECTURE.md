# Nova Ancient Warrior - 2026 AI Game Studio Architecture

Status: architecture and integration specification. This document does not claim that external desktop applications or MCP servers are already installed or connected.

## Executive decision

Keep the existing Godot 4.7 project and its Android-first production target. Do not migrate to Unreal or Unity merely to add AI tooling. Build a modular production system around the repository, with Godot as the runtime authority, Blender as the DCC authority, C++ GDExtension only for measured CPU-heavy work, and CI as the reproducible verification layer.

The earlier label "OpenAIGamesDesigner" is not an approved dependency: do not build the pipeline around an unverified project identity. Prefer independently verifiable tools and keep every integration replaceable.

## The six-layer studio

1. **Project brain and orchestration - GitHub**
   - Issues define one bounded production task, acceptance criteria, owner/agent role, affected paths, dependencies, and rollback plan.
   - Branch-per-task, pull-request review, CODEOWNERS-style ownership, protected main, immutable build artifacts.
   - Keep design decisions, asset provenance, test evidence, and benchmark history versioned beside the game.

2. **Godot live-editor bridge - Godot Editor MCP / Godot MCP**
   - Candidate: https://github.com/tugcantopaloglu/godot-mcp
   - Candidate product/package reference: https://pypi.org/project/godot-editor-mcp/
   - Use only after validating compatibility with the exact Godot 4.7 project and pinning a release/commit.
   - Allow scene-tree inspection, script diagnostics, headless run, controlled play input, screenshots, profiler and export.
   - Require a read-only first phase and explicit allow-list for mutations. Never expose arbitrary shell or secrets to an untrusted agent.

3. **Blender asset factory - Blender MCP**
   - Candidate: https://github.com/ahujasid/mcp-for-blender
   - Candidate skill pack: https://github.com/EL4CTEO/blender-skills
   - Use Blender headless/background jobs for deterministic generation, retopology helpers, UV checks, PBR baking, rig validation, animation export and GLB validation.
   - Require a human-approved reference and visual review for hero characters, bosses and key environments.
   - Do not assume that AI-generated meshes are production-ready: enforce topology, scale, UV, material, skeleton, animation and polygon/texture budgets.

4. **Specialist agent skills - portable skill packs**
   - Candidate: https://github.com/gamedev-skills/awesome-gamedev-agent-skills
   - Candidate: https://github.com/setcodes/gamedev-skills
   - Candidate: https://github.com/EL4CTEO/blender-skills
   - Curate six roles: Game Director/Designer, Godot Gameplay Engineer, Combat & AI Engineer, Character/Rigging Animator, Environment/Technical Artist, QA/Performance Engineer.
   - Vendor only reviewed skill files with license and provenance records. Skills are instructions, not executable proof or autonomous expertise. Resolve conflicting instructions centrally in this document.

5. **Native performance module - C++ GDExtension**
   - Official API reference: https://docs.godotengine.org/en/4.7/engine_details/engine_api/gdextension/index.html
   - Keep physics, animation, damage authority and gameplay state in Godot unless profiling demonstrates a bottleneck.
   - Candidates for native code: batched spatial filtering, large crowd steering, deterministic procedural data transforms and other measured CPU hotspots.
   - Require Linux host binary + Android arm64 binary, runtime smoke tests, GDScript parity tests and representative benchmark evidence before enabling in gameplay.
   - Current C++ state: Android arm64 library build succeeded in CI; Linux library compilation succeeded but Linux GDExtension load/smoke test failed in run 42526213242. The extension remains isolated and must not be enabled in the game until the failure is diagnosed and the smoke test passes.

6. **Quality, performance and release factory - GitHub Actions**
   - Static checks, GDScript parse, import validation, scene boot, unit/regression tests, resource/license validation, asset budgets, Android export and artifact retention.
   - Separate CI green status from real-device evidence. Record device model, OS, renderer, resolution, thermal state, average FPS, 1% low, frame-time percentiles, memory, load time and battery/thermal behavior.
   - Target profiles: Medium (stable 30 FPS) and High (stable 60 FPS where hardware allows); do not promise either without device measurements.
   - Android release work must separately validate target API requirements, AAB, signing and Play checks. Debug APK is not a production release.

## Production data flow

Reference / brief
-> task specification + acceptance criteria
-> specialist agent proposes changes
-> Blender or code tool creates candidate assets / implementation
-> automated validation (format, import, scene, gameplay, license, size)
-> independent reviewer checks diff and visual output
-> CI build + benchmark artifacts
-> human approval for merge and release.

No agent may silently overwrite the main branch, change renderer, replace existing assets, alter signing configuration, or add a dependency without a reviewable diff.

## Six specialist workstreams

### A. Character and animation
- Replace procedural placeholder hero only after a production-quality rigged hero asset passes visual and technical review.
- Validate skeleton naming, rest pose, scale, root motion, retargeting, foot contact, weapon grip, hit reactions and animation transitions.
- Budget LODs, materials, bones and animation memory for Android.

### B. Combat feel
- Implement attack startup/active/recovery windows, directional attacks, dodge i-frames, guard/parry windows, target selection, hit stop, hit reactions and boss telegraphs.
- Use swept weapon traces or shape queries to avoid tunneling; do not use a broad-phase C++ cone as the authoritative hit test.
- Test edge cases: multiple targets, walls, slopes, moving targets, low frame rate, interruption, death and save/load.

### C. World and level production
- Deliver three independently playable chapters, not one reused arena with cosmetic dressing.
- Each chapter needs traversal, combat spaces, landmarks, secrets, checkpoints, hazards, navigation validation and performance budgets.
- Stream large areas and use occlusion/LOD only where profiling proves value.

### D. Materials, lighting and VFX
- PBR material validation, texture compression, mipmaps, shader variants, light count/shadow budgets, particle caps and overdraw review.
- Separate visual tiers for Medium and High Android profiles.
- Every effect must have a gameplay readability purpose and a low-cost fallback.

### E. Enemy AI and bosses
- Data-driven finite-state/behavior systems with navigation, perception, telegraphs, cooldowns, group coordination and difficulty tuning.
- Add deterministic test scenarios for stuck navigation, unreachable targets, animation interruption and combat loops.

### F. Audio, cinematics and accessibility
- Layered sword, armor, footsteps, impacts, ambience and adaptive music.
- Dialogue/subtitles/camera sequences must be skippable and save-state safe.
- Provide UI scale, subtitle controls, remapping where supported, vibration toggle and performance options.

## Six-pass verification protocol

1. **Integrity pass:** project version, paths, missing resources, license/provenance, dependency and secret scan.
2. **Static pass:** GDScript parse/lint, C++ compiler warnings, shader compile, naming and resource budget checks.
3. **Import/asset pass:** clean import, GLB/skeleton/material/animation checks, texture dimensions and compression.
4. **Gameplay pass:** boot main scene, combat state transitions, AI, boss encounters, checkpoints, save/load and chapter completion.
5. **Visual/performance pass:** deterministic captures at fixed camera/time, render comparison, frame-time and memory budgets on CI plus real Android devices.
6. **Release pass:** Android arm64 export, API/manifest validation, AAB/signing checks, install/launch smoke test, artifact hash and release notes.

A pass is recorded only with its commit SHA, workflow URL, test output and artifact references. A failed pass blocks promotion; retries do not erase the original failure.

## Current verified CI snapshot

On commit 649f007a073aed94bae50556f5e3140cdb7d88ee:
- Six-pass QA: success (run 42526270787).
- Python tests: success (run 42526270695).
- Android debug APK build: success (run 42526265987).
- External resource policy: success (run 42526271058).
- Native C++: Android arm64 compile/upload succeeded, but Linux GDExtension smoke test failed (run 42526213242). Root cause is not yet established; do not claim the native extension is runtime-ready.

These are CI results only. They do not prove the game is complete, photorealistic, performant on a physical phone, or ready for store release.

## Integration gates and security

- Pin every external repository to a commit; record license, source URL, version, hash and modifications in ASSET_PROVENANCE.csv or a tool manifest.
- Prefer MIT/BSD/Apache/CC0-compatible resources where practical; inspect asset-specific terms separately from code licenses.
- Run external agents in a restricted workspace/branch with no production signing keys, API secrets or write access to main.
- Require human approval for new tools, external downloads, large asset replacements, renderer changes and release operations.
- Keep the Android-first pipeline usable without installing desktop tools on the user's phone. Desktop-only MCP services are optional production workers, not user setup requirements.

## Next implementation sequence

1. Diagnose Linux native smoke failure and keep C++ extension disabled until fixed.
2. Add a pinned Godot Editor MCP evaluation branch and a non-mutating compatibility smoke test.
3. Add Blender MCP as a separate optional worker, then validate one small prop end-to-end before hero assets.
4. Import selected skills individually after license and instruction review; do not bulk-install entire repositories.
5. Add artifact/benchmark manifests and visual regression capture.
6. Only then wire approved agent outputs into the main production workflow.

## Definition of done

A feature is done only when its acceptance criteria pass, it has reproducible tests, asset licenses are documented, Android budgets are met, and a reviewer has inspected the diff and visual output. A project is release-ready only after all chapters are completable, save/load is robust, controls and audio work, device testing passes, and the signed release package is validated.
