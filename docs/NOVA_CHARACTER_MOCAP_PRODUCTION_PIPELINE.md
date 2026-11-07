# Nova Ancient Warrior — Character, Mocap and Asset Pipeline

This pipeline is designed around the Android-first Godot 4.7.2 game and a low-cost production stack. The project must keep a clear distinction between open-source tools, licensed third-party assets, and original game content.

## Target character specification

The hero asset is not accepted as production-ready merely because it has a mesh. The final character gate requires:

- A clean humanoid armature with a documented rest pose (A-pose or T-pose), consistent scale and forward axis.
- Deformable skin weights with no detached or exploding vertices at shoulders, elbows, hips, knees and wrists.
- Named humanoid bones mapped to Godot's `SkeletonProfileHumanoid` / `BoneMap`.
- Separate material slots for skin, cloth, leather, metal, eyes and weapon; 1K–2K textures are the initial Android budget.
- A coherent animation library: idle, walk, run, start/stop, turn, jump, fall, land, dodge left/right, light attacks 1–3, heavy attack, hit reactions, block, stagger, death and victory.
- Root-motion policy documented per clip; gameplay locomotion remains code-driven until root motion is deliberately enabled.
- No copyrighted character likeness, ripped game assets, unlicensed mocap, or raw asset redistribution.

## Open-source-first toolchain

| Stage | Preferred tool | Role | Licence / caution |
|---|---|---|---|
| Character base | MakeHuman + MPFB2 for Blender | Human mesh, proportions, materials and rig starting point | Check each addon version and generated asset terms; preserve provenance |
| Rigging / animation | Blender + Rigify | Armature, control rig, skinning, animation cleanup and export | Blender/Rigify are GPL software; the character content you create is separately licensed |
| Mocap | FreeMoCap | Markerless capture from synchronized webcams or imported phone videos; export FBX/BVH | FreeMoCap app is AGPL-3.0; obtain consent from performers and review dataset/model notices |
| Retargeting | Godot 4 SkeletonProfileHumanoid / BoneMap | Map compatible humanoid skeletons and AnimationLibraries | Rest pose and bone rest transforms must match, not just bone names |
| Optional fast retarget | Mixamo | Licensed humanoid animation source when the clip licence and project use comply | Proprietary service; Adobe account and current terms apply; do not redistribute raw source files |
| Optional rig helper | AccuRIG | Automatic humanoid rigging for suitable meshes | Reallusion software/content terms differ; review each downloaded asset licence |
| Materials | Material Maker + Blender nodes | Original PBR textures/materials | Verify the licence of each community material separately |
| Engine | Godot 4.7.2 | AnimationPlayer/AnimationTree, gameplay, Android export | MIT engine; game assets remain separately licensed |

## FreeMoCap capture protocol

1. Use two or more synchronized camera views where possible. A single phone video is a lower-confidence source and can lose depth/occluded joints.
2. Record the performer in good light, full body visible, with a neutral calibration pose and slow clean movement.
3. Capture short isolated takes: idle loop, walk cycle, run cycle, dodge, each attack, block, hit reaction and death. Do not record an entire fight as one take.
4. Keep the performer away from occlusion; avoid loose clothing hiding elbows/knees. Capture the weapon separately if hand tracking is unreliable.
5. Process and inspect the skeleton in FreeMoCap. Foot locking and hand range limits are useful cleanup options, not substitutes for manual review.
6. Export FBX for mesh + armature + animation, or BVH for motion-only retargeting. Current FreeMoCap documentation says Blender export is MediaPipe-only; do not assume RTMPose export parity.
7. Clean foot contacts, root drift, joint flips, weapon grip, timing and silhouette in Blender before retargeting.
8. Keep original recordings private; obtain written performer consent and document permitted commercial use before shipping derived animation.

## Godot import and retarget contract

- Import the final character as a scene (GLB preferred for the runtime pipeline).
- In Advanced Import, select the `Skeleton3D`, assign a `BoneMap` and `SkeletonProfileHumanoid`, then inspect every mapped bone.
- Import motion-only clips as AnimationLibraries and apply the same profile/rest-pose mapping.
- Test every clip on the hero and at least one enemy with different proportions.
- Check root scale, forward axis, frame rate, loop flags, foot contact, weapon grip, animation duration and missing tracks.
- Use AnimationTree state transitions with explicit blend times; do not play unrelated clips by hard-switching every frame.
- Preserve a procedural fallback so the project remains runnable if optional external character assets are absent.

## Asset acquisition rules

- Prefer assets with CC0, CC-BY, or clearly compatible commercial terms; record author, source URL, exact licence version, download date and modifications in `ASSET_PROVENANCE.csv`.
- CC-BY requires attribution; CC-BY-SA can impose share-alike obligations on adapted material. Avoid NC/ND assets for commercial game use unless counsel confirms the use.
- A repository's code licence does not automatically license models, textures, sounds or mocap files stored in that repository.
- Do not import assets from game rips, fan ports, random model aggregators, or repositories with missing licence files.
- Do not ship raw Mixamo/ActorCore source libraries as a downloadable asset pack.

## Audio and cinematic direction

- The in-game ambient score is generated procedurally in GDScript, so it is original and does not depend on third-party recordings.
- Keep music, UI, weapon, footsteps, impacts, enemy telegraphs and boss cues on separate buses before final mix.
- Add authored cinematic shots as short camera sequences: establish the arena, reveal the boss silhouette, cut to a close-up, then return control to the player. Never lock the player for long without a skip path.
- Record the source and licence for any future foley or music sample; keep original procedural audio as the fallback.

## Android performance gates

- Start with one hero skeleton and a small enemy count; reuse the same skeleton/animation library.
- Limit active shadow casters, material count, texture size and transparent particles.
- Prefer baked/simple environment lighting, compressed textures and short audio loops.
- Profile on the actual target phone for frame time, memory, thermals, touch latency and audio glitches. CI export success is not device certification.

## Delivery checklist

- [ ] Hero mesh and armature reviewed in Blender.
- [ ] Skin weights checked at all major joints.
- [ ] Every animation clip previewed and named consistently.
- [ ] Performer and asset permissions recorded.
- [ ] Godot humanoid retarget map saved and validated.
- [ ] Hero and enemy AnimationTrees pass transition tests.
- [ ] Save migration, checkpoint and chapter unlock tests pass.
- [ ] Music/SFX mix and boss cinematic can be skipped or interrupted safely.
- [ ] Android APK installed and play-tested on target hardware.
