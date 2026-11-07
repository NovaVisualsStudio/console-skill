# Nova Ancient Warrior — Six-tool production integration plan

Status: research-backed integration plan only. No external account has been authenticated, no desktop application has been installed, and no third-party asset/plugin has been copied into the game. This document deliberately separates verified product facts from project-specific compatibility gates.

Target project: Godot 4.7.2, Compatibility renderer, Android ARM64 first. Keep the current native Godot audio path as fallback. Do not change the renderer or introduce native runtime dependencies without a device benchmark.

## Executive decision

Adopt a staged content-production pipeline, not six runtime dependencies:

1. AccuRIG — prepare humanoid skeletons.
2. Mixamo — prototype humanoid animation clips.
3. Cascadeur — optional animation polish only if a paid export licence is justified; the Free plan is not suitable for shipping FBX/DAE or commercial production.
4. Material Maker — first-choice procedural PBR authoring tool.
5. FMOD Studio + Godot FMOD GDExtension — optional audio middleware, behind a separate integration branch and Android build gate.
6. Substance 3D Painter — optional paid texture-authoring upgrade; do not make it a project requirement.

The first production pass should use AccuRIG + Mixamo + Material Maker. Continue using Godot's built-in animation and audio systems until an asset or profiling result proves an external runtime dependency is needed.

## Tool register

| Tool | Intended use | Verified facts | Gate before production |
|---|---|---|---|
| AccuRIG | Rig the hero, humanoid enemies and humanoid bosses; export FBX/USD | Reallusion advertises a free AccuRIG workflow and FBX/USD export. It is a humanoid rigging workflow. | Verify the exact AccuRIG software EULA and any ActorCore motion-content licence separately. Test exported skeleton hierarchy, rest pose, bone names, root motion and skin weights in Godot 4.7.2. Do not assume a free tool licence grants rights to every bundled/downloaded content asset. |
| Mixamo | Rapidly prototype locomotion, attack, hit, dodge, jump and death clips | Adobe says Mixamo is free with an Adobe ID and permits use of its characters/animations in personal, commercial and non-profit projects. It is intended for biped humanoids. | Do not redistribute raw Mixamo animation/character files as a standalone asset pack. Import FBX into a throwaway test scene first; inspect scale, skeleton retargeting, animation names, root motion, foot sliding and clip timing. |
| Cascadeur | Polish weight, anticipation, impact, falls and boss attacks | Current Free plan is non-commercial and exports only .casc; FBX/DAE export is listed for Indie and above. | Do not use the Free plan's output in a commercial shipped build. Only consider paid Indie after cost/benefit review; test round-trip FBX and retargeting. It is not required for the first milestone. |
| Material Maker | Generate tiling stone, dirt, metal, leather and wall PBR maps | Official site describes node-based PBR generation/export for Godot, Unity and Unreal. Repository identifies MIT for the application source. | MIT applies to the application source, not automatically to community materials, brushes or downloaded packs. Record the licence for every source asset. Export maps at mobile resolutions and test roughness/normal strength in Compatibility renderer. |
| FMOD Studio + FMOD GDExtension | Event-based combat SFX, spatial audio, adaptive music and audio profiling | FMOD's official licensing page lists a free Indie licence only under its stated budget/revenue conditions. The Godot FMOD GDExtension setup guide documents Android plugin/Gradle setup and arm64-v8a support. | Integration is unofficial/community-maintained, not a Godot core feature. Confirm exact release supports Godot 4.7.2, Android 12/ARM64, current NDK/Gradle and export templates. Build and run a minimal Android audio test before adding it. Keep Godot audio fallback. Register project and comply with FMOD EULA/attribution if used commercially. |
| Substance 3D Painter | High-quality armour, weapon and character texture painting | Adobe provides a 30-day app trial; Substance 3D plans are paid. Adobe's asset terms allow assets to be embedded in a larger work such as a game, not redistributed standalone. | Not required for the prototype. Review current local-country pricing and applicable Painter/Assets terms before purchase. Do not confuse Painter software licence with rights for each downloaded asset. |

## Official sources and terms

- AccuRIG product: https://www.reallusion.com/auto-rig/accurig/default.html
- Reallusion Content EULA: https://www.reallusion.com/Content/EULA/EULA.htm
- Mixamo FAQ: https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html
- Cascadeur plans: https://cascadeur.com/plans
- Material Maker official site: https://www.materialmaker.org/
- Material Maker repository and MIT notice: https://github.com/RodZill4/material-maker
- FMOD Studio: https://www.fmod.com/studio
- FMOD licensing: https://www.fmod.com/licensing
- Godot FMOD GDExtension setup: https://fmod-gdextension.readthedocs.io/en/latest/user-guide/1-install/
- Substance 3D FAQ: https://helpx.adobe.com/substance-3d/substance-3d-faq.html
- Substance 3D Painter activation/licensing: https://experienceleague.adobe.com/en/docs/substance-3d-painter/using/getting-started/activation-and-licenses
- Godot 4.7 Android export: https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html
- Godot 4.7 GDExtension: https://docs.godotengine.org/en/4.7/engine_details/engine_api/gdextension/index.html

## Integration pipeline

### Phase A — animation content (no runtime plugin)
1. Select one existing hero mesh and one humanoid enemy mesh. Preserve original source files and create copies for export experiments.
2. Prepare neutral A/T pose meshes with applied transforms, clean topology around shoulders/hips/knees/elbows, and sensible scale.
3. Rig the hero in AccuRIG. Export FBX. Keep a source copy and record software version, skeleton name, scale and licence evidence.
4. Upload/import the test mesh into Mixamo and create a minimal clip set: idle, walk, run, light attack, heavy attack, hit reaction, dodge, jump, death.
5. In Godot, test skeleton import and retargeting. Separate root motion from in-place clips; standardize clip names and loop flags. Build AnimationTree state transitions with interruptible attack/hit states. Avoid importing unused clips.
6. Do not add animation files to the shipping project until scale, skeleton mapping, weapon hand socket, foot contact and mobile performance pass.

### Phase B — materials
1. Use Material Maker to create four reusable master materials: stone, worn metal, leather and earth.
2. Export albedo/base colour, normal, roughness and ambient-occlusion maps only when useful. Avoid maps the target shader does not consume.
3. Start at 512 px for small props and 1024 px for hero/boss assets; increase only when a device capture proves a visible benefit.
4. Prefer tiling materials and shared atlases. Avoid unique 2K/4K maps for ordinary environment props.
5. Validate in the existing Compatibility renderer and inspect on the target Android device. Record GPU memory, frame-time and APK-size deltas.

### Phase C — audio decision
1. First implement/verify combat audio with Godot AudioStreamPlayer/AudioStreamPlayer3D, buses, attenuation and pooled one-shots.
2. Create a separate experimental branch for FMOD; never replace the working audio system in-place.
3. Confirm plugin release notes, licence, Godot 4.7.2 compatibility and Android ARM64 binaries. Confirm Gradle build integration and Android plugin packaging.
4. Build a minimal scene with one music event, one 3D positional sword impact and one parameter-controlled combat intensity event.
5. Test install, launch, audio focus, pause/resume, repeated scene transitions, device rotation if supported, and 15-minute playback on a physical Android device.
6. Compare CPU, memory, APK size, latency, crackles and reliability against native Godot audio. Adopt FMOD only if it clearly improves the game.

### Phase D — texture painting
1. Do not buy Painter yet. Use Material Maker and Blender-compatible workflows first.
2. If the art direction later requires hand-painted wear, layered masks or advanced baking, trial Painter on one hero sword and one armour plate.
3. Verify export preset, texture channel packing, colour space and asset terms before importing any Painter/Assets output.

## Acceptance checklist

- [ ] Hero FBX imports with correct scale, orientation and skeleton.
- [ ] Enemy FBX imports with matching retarget profile.
- [ ] Idle/walk/run/attack/hit/dodge/jump/death clips play without broken joints.
- [ ] Root motion and in-place animation are intentionally selected per clip.
- [ ] Weapon socket remains aligned through attack animations.
- [ ] No severe foot sliding, mesh deformation or animation state lock.
- [ ] Four PBR materials render correctly in Godot Compatibility.
- [ ] Mobile texture sizes and memory use are measured, not guessed.
- [ ] FMOD is excluded unless the Android ARM64/Gradle proof scene passes.
- [ ] Every third-party model, motion, material, texture and sound has a recorded source and licence.
- [ ] CI runs project import/headless smoke tests and Android ARM64 export after any integration.
- [ ] A physical-device playtest is completed before claiming Android runtime success.

## Asset provenance record template

For every imported asset, record:
- Asset name and internal path
- Original creator/source URL
- Download date and version
- Exact asset licence/EULA and evidence URL
- Required attribution text
- Whether modification is allowed
- Whether commercial game distribution is allowed
- Whether raw-file redistribution is prohibited
- Texture dimensions, mesh/triangle count, skeleton/bone count
- Import settings and target platform
- Reviewer and approval date

## Explicit non-actions

This plan does not authenticate Adobe, Reallusion, Cascadeur, Material Maker or FMOD accounts. It does not install software on a phone or computer, download proprietary libraries, import third-party assets, replace the current audio implementation, change the renderer, merge a pull request, or claim physical-device validation. Those actions require the appropriate connected environment and, where relevant, the user's account and licence.
