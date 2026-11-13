# Nova Ancient Warrior - Asset Ecosystem and Production Policy

**Reviewed:** 2026-11-08  
**Project:** Godot 4.7.2, GDScript, Android ARM64, Compatibility renderer  
**Purpose:** A repeatable source, licensing, quality, integration and QA process for a cinematic HD action game.

This document is a standing policy for future Nova Ancient Warrior tasks. It covers story writing, characters, animation, environments, materials, audio, gameplay code, CI and Android delivery. A source appearing here means it is approved for discovery and evaluation, not that every item on that source is approved, downloaded or integrated.

## 1. Quality target

The target is an original, cinematic third-person action game with believable human characters, expressive faces, credible body movement, detailed PBR materials, distinct authored levels, readable combat, deliberate camera work, compelling sound and a coherent story.

The first Android quality gate is a 1280 x 720 presentation with device-tiered internal render scaling. Do not trade away frame pacing, touch responsiveness, audio reliability or thermal stability just to increase polygon counts or texture resolution.

The quality bar is judged separately in five areas:

1. **Writing and story:** clear character motives, causality, escalating stakes, character-specific dialogue, purposeful scenes, accurate historical context where real events are used, Arabic/English localisation, subtitles and voice direction.
2. **Character and motion:** facial identity, proportions, believable skin and eyes, hair, armour fit, deformation, facial shapes, foot contacts, weapon handling and clean animation transitions.
3. **World and image:** readable silhouettes, authored level composition, material scale, PBR response, lighting, weather/atmosphere, composition, collision, navigation and visual variety.
4. **Sound and presentation:** distinct music, ambience, foley, combat feedback, boss cues, spatial positioning, mix levels, camera blocking and optional skip paths.
5. **Engineering and delivery:** import safety, runtime correctness, test coverage, provenance, licence compliance, APK validity, actual-device performance and repeatable builds.

## 2. Source ecosystem

### A. User-designated marketplaces and code hosts

| Source | Intended role | Project policy |
|---|---|---|
| [OpenGameArt](https://opengameart.org/) | Community models, props, textures, music and sound effects | Inspect the exact submission page and exact licence. Prefer CC0; retain attribution for CC-BY. Avoid NC/ND and copyleft assets unless the whole distribution model is explicitly reviewed. |
| [SourceForge](https://sourceforge.net/) | Discover hosted applications, utilities and legacy/open-source tools | Treat it as a host and discovery index, not a licence or trust guarantee. Follow the upstream source, verify release integrity, project activity, dependencies and licence before using software. |
| [GitLab](https://about.gitlab.com/) | Code repositories, issue tracking, reviews and optional CI/CD mirrors | Use for upstream discovery or a deliberate mirror/secondary pipeline. Current canonical project history remains on GitHub unless a migration is explicitly planned. |
| [Bitbucket](https://bitbucket.org/) | Repository collaboration, Pipelines and Git LFS for large files | Use as an optional mirror or CI alternative when it adds a measurable benefit. Do not create duplicate competing sources of truth. |
| [Unity Asset Store](https://assetstore.unity.com/) | Animation packs, FBX models, environments, tools and reference material | Review the Unity Asset Store EULA and any provider-specific or restricted-asset terms. Confirm that the exact files and intended use are allowed outside Unity before importing into Godot. Embed licensed assets in the original game; never redistribute source packages as standalone downloads. |
| [Fab / Unreal Engine Marketplace](https://www.fab.com/) | High-quality human characters, props, environments, animations and materials | Check the exact product licence tier and file formats. Fab Standard permits use in compatible tools and distribution embedded in a larger project, but not standalone redistribution. CC-BY requires attribution. Prefer explicit GLB/glTF/FBX/Blender source files for Godot. |
| [Godot Asset Library](https://godotengine.org/asset-library/) | Godot addons, scripts, editor tools, shaders and project helpers | Check the exact Godot version, release status, dependencies and licence. This is primarily an addon/code catalogue, not a photoreal 3D asset marketplace. |

Git hosting services do not confer a licence on the files stored in a repository. A permissive code licence does not automatically cover bundled models, textures, audio, fonts, datasets or sample videos.

### B. Preferred open content and production tools

| Source | Best use for Nova | Licence / import note |
|---|---|---|
| [Poly Haven](https://polyhaven.com/) | Real-world HDRIs, PBR textures and environment props | The site states its assets are CC0. Strong first-choice source for photoreal surface and lighting references. |
| [ambientCG](https://ambientcg.com/) | PBR surfaces, decals, material scans and HDRIs | The site states its assets are CC0. Check each downloaded archive's included metadata and choose Android-appropriate texture sizes. |
| [Kenney](https://kenney.nl/assets) | UI, placeholders, icons, simple props and prototyping packs | Game assets are stated to be CC0. Useful for prototypes and interface assets, not a substitute for the realistic hero or cinematic environment art direction. |
| [Quaternius](https://quaternius.com/) | Modular characters, creatures, props and environment blockouts | Existing project research lists CC0 packs; verify the exact pack and included licence before use. Some content is stylised and may not meet the final realism target. |
| [MakeHuman Community](https://www.makehumancommunity.org/) and [MPFB2](https://github.com/makehumancommunity/mpfb2) | Human base meshes, proportions, body shapes and Blender character assembly | The project describes a split licence: MPFB2 source code GPL-3.0 and bundled graphical assets CC0. Preserve this distinction and re-check the version's licence files. |
| [Blender](https://www.blender.org/) and [Rigify](https://docs.blender.org/manual/en/latest/addons/animation/rigify/index.html) | Sculpting, retopology, UVs, materials, rigging, animation cleanup and GLB export | Blender software is GPL; artwork made with Blender is the creator's own. Tool licence and exported asset licence are separate. |
| [Khronos glTF](https://github.com/KhronosGroup/glTF) | Interchange format for models, PBR materials, skinning and animation | Preferred delivery format for Godot import. Validate export settings and extension use. |
| [FreeMoCap](https://github.com/freemocap/freemocap) | Markerless capture from phone/webcam video and motion processing | Application code is AGPL-3.0. Review the licence before redistributing modified software. Performer consent and source video rights are separate requirements. |
| [PoseCap](https://github.com/CorridorTech/PoseCap) | Experimental real-time markerless pose capture into Blender | Discovery candidate only. Verify current maintenance, licence, model/data terms and hardware requirements before adoption. |
| [Mixamo](https://www.mixamo.com/) | Fast humanoid animation and auto-rigging reference/source | Proprietary Adobe service. Confirm current Adobe terms for the exact use. Keep source libraries private and ship only the permitted integrated result. |
| [Meta Open Sound](https://github.com/facebookincubator/Meta-open-sound) | Recorded instruments and game/VR effects | The repository states instrument collections are CC0 and the Oculus Audio Pack is CC-BY 4.0. Check the collection directory's LICENSE and ATTRIBUTION file per sample. |
| [Sonniss GDC Game Audio](https://gdc.sonniss.com/) | High-quality ambience, impacts, weapons, foley and cinematic SFX | The 2026 bundle page states royalty-free commercial use with no attribution; archive the versioned licence that accompanies the exact download. |
| [Freesound](https://freesound.org/) | Specific one-off real-world sound recordings | Licences vary per sound (including CC0, CC-BY and CC-BY-NC). Reject NC files for commercial release; store the creator and attribution text for BY files. |
| [Godot Dialogue Manager](https://github.com/nathanhoad/godot_dialogue_manager) | Branching dialogue, dialogue tooling, validation and translations | MIT project. The current v4 line targets Godot 4.6+; the Asset Library result marked the reviewed 4.1.0 release unstable, so pin and smoke-test before runtime adoption. |
| [Material Maker](https://github.com/RodZill4/material-maker) | Procedural materials and texture authoring | Review the software licence and the licence of every imported graph, image or material. |
| [Dust3D](https://github.com/huxingyi/dust3d) | Fast rough modelling and automatic rigging experiments | Modelling aid for blockout or secondary assets, not the preferred final photoreal hero pipeline. |

### C. Further source discovery

Search beyond the named platforms when a relevant production gap appears. Candidate pools include:

- [GitHub](https://github.com/) for source code, plugins, exporters, test frameworks and CI actions.
- [Sketchfab](https://sketchfab.com/) for individually licensed downloadable models. Check creator, download rights, commercial rights, attribution and redistribution terms for each model.
- [itch.io game assets](https://itch.io/game-assets) for small art, SFX, UI and game-ready packs. Every seller's terms must be checked separately.
- [Blender Extensions](https://extensions.blender.org/) for current Blender tools and addon discovery. An extension listing is not proof that its bundled content has a compatible game licence.
- [OpenUSD](https://openusd.org/) and [Khronos glTF](https://www.khronos.org/gltf/) documentation for interchange and scene pipelines where needed.
- [Android GPU Inspector](https://github.com/google/agi), [Perfetto](https://perfetto.dev/) and [RenderDoc](https://renderdoc.org/) for device profiling and GPU diagnosis.

New sources are added to this document only after their relevance, current availability and licensing model are checked.

## 3. Current asset and tool candidates

These are research candidates, not integrated assets:

| Candidate | Why it is worth testing | Gate before adoption |
|---|---|---|
| [Classic Medieval Knight Warrior - Rigged (Fab)](https://www.fab.com/listings/d1bc23e5-22d2-4e2d-9616-c4e3a62c8439) | Free listing describes a game-ready rigged human and provides FBX, GLB, OBJ and Blender formats. Could be useful for an enemy/NPC test or a reference for armour construction. | Inspect actual GLB/FBX, textures, skeleton, polygon density and facial detail. Listing tags include low-poly and its exact licence terms must be resolved. Not accepted as final photoreal hero based on listing text alone. |
| [Ancient Ruins Environment (Fab)](https://www.fab.com/listings/09c87885-6bea-4433-8eba-be6f48c727c8) | FBX/OBJ modular ancient architecture described with 4K textures and real-life references. | Confirm exact price/licence and download contents; inspect texel density, material sets, scale, collisions and Android cost. |
| [Ancient Ruins - Free Asset Pack (Fab)](https://www.fab.com/listings/c6bd4209-8420-499f-99b7-f47b8492b2d1) | 26 modular pieces with FBX/GLB/GLTF formats. | Listing describes a stylised and AI-generated set; suitable only as a blockout or if final art direction accepts the style. Verify Standard/CC-BY terms. |
| [Human Basic Motions FREE (Unity Asset Store)](https://assetstore.unity.com/packages/3d/animations/human-basic-motions-free-154271) | Listing describes locomotion and interaction animations and says Blender files are included. | Check exact package licence and files; test retargeting in Blender/Godot, foot contacts and root-motion handling. |
| [Creative Characters FREE (Unity Asset Store)](https://assetstore.unity.com/packages/3d/characters/humanoids/creative-characters-modular-animated-pack-304838) | Listing describes FBX/OBJ/GLTF/Blender support and mobile-focused optimisation. | Inspect actual visual style and source files; verify current licence and all included sub-assets. May be too stylised for final realism. |
| [Dialogue Manager 4](https://github.com/nathanhoad/godot_dialogue_manager) | Branching dialogue and translation support for Godot 4.6+. | Install in a disposable branch, pin a release, run import/syntax/translation smoke tests and measure runtime impact before adding to the main project. |
| [Meta Open Sound](https://github.com/facebookincubator/Meta-open-sound) | Real recordings and sound effects complement the current procedural audio. | Select only individually licensed sounds; add required CC-BY credits and check format, loudness, loop quality and file size. |
| [Sonniss 2026 GDC bundle](https://gdc.sonniss.com/) | Large professionally recorded sound-effects source. | Read and archive the included EULA; audition, trim, normalise and compress chosen files; never copy the entire bundle into the game repo. |

## 4. Story and cinematic writing workflow

Writing is treated as a production discipline, not a late-stage text pass.

For each chapter, create:
- A one-page chapter objective, protagonist need, antagonist pressure and irreversible consequence.
- A beat sheet with opening image, inciting event, escalation, reversal, boss setup, payoff and transition.
- A scene list with location, character objective, conflict, emotional turn, gameplay transition, camera plan, sound cue and estimated duration.
- Dialogue passes for natural spoken Arabic and English localisation. Dialogue must fit character identity and scene action rather than read like exposition.
- A historical fact sheet whenever real periods, cultures, sites, weapons or actual events are depicted. Distinguish documented facts from fictional characters and invented events; do not market invented story beats as real history.
- Subtitle and voice records with stable speaker IDs, timing, translation status, recording rights and retake state.

Evaluate each cutscene for clear staging, visible emotion, readable framing, continuity, lip-sync feasibility, audio mix and the ability to skip or resume without breaking gameplay state.

## 5. Asset clearance and provenance

No third-party asset enters the production branch until all hard gates pass:

1. **Source identity:** exact product or submission page, creator/publisher, original download location and version are captured.
2. **Rights:** exact licence version and any provider-specific terms are saved. Confirm commercial use, modification, embedding, attribution, redistribution limits, AI/data restrictions and any copyleft obligations.
3. **File contents:** list archives before extraction; inspect embedded licence notices, dependencies, scripts, shaders, fonts, audio samples and nested model/texture files.
4. **Security:** do not run unknown executables, installers, macros or scripts from asset archives. Prefer source code and signed/release checksums from the original project.
5. **Format:** inspect GLB/glTF/FBX/OBJ/BLEND, texture maps, skeleton, animation clips, units, axis, collision, LOD and material dependencies.
6. **Visual quality:** inspect neutral lighting, reference scale, face close-up, material response, UVs, normals, joints, silhouette and defects.
7. **Mobile quality:** measure mesh/texture memory, material count, alpha overdraw, skeleton cost, draw calls and import size on the Android target.
8. **Record:** add a row to nova-ancient-warrior/ASSET_PROVENANCE.csv with the source, asset title, creator, exact licence/version, download date, modifications and commercial-use decision.
9. **Attribution:** add required attribution to the in-game credits and a shipped THIRD_PARTY_NOTICES file. CC-BY assets need credit and change notices; CC0 items may still be listed voluntarily.
10. **Approval:** unresolved rights or missing source files mean reject or keep as reference-only. Never add an unclear asset to the release build.

### Licence handling

- **CC0:** preferred for reusable game assets, subject to confirming that the exact file is actually CC0.
- **CC-BY:** acceptable when the creator, title, source, licence and modification notice are preserved in the game credits/notices.
- **CC-BY-SA / GPL / AGPL:** escalate before use. Share-alike and source-distribution conditions can affect the intended game distribution or modified tools. Do not assume the rest of the game must be relicensed without analysing the exact licence and manner of use.
- **NC / non-commercial:** reject for a commercial or potentially monetised release.
- **ND / no-derivatives:** reject when asset modification, conversion, editing or adaptation is needed, unless the licence explicitly permits the planned acts.
- **Marketplace standard licences:** assets may generally be embedded in a larger game under their terms, but source-package redistribution is prohibited. Confirm platform, account, seat, tier, project and provider-specific conditions.
- **Unknown or missing licence:** reject until clarified in writing by the rights holder.

## 6. Technical asset pipeline for Godot 4.7.2

Preferred interchange is GLB/glTF for runtime character and environment assets, with Blender as the controlled conversion and authoring stage.

### Character pipeline

1. Create or source a believable human base. MakeHuman/MPFB2 is a practical free base-mesh route, not an automatic photoreal result.
2. Sculpt/retopologise the hero's face and body. Author skin, eye, hair, cloth, leather, metal and weapon materials separately.
3. Build clean UVs, tangent-space normal maps, roughness/metallic maps, facial shapes and hair geometry.
4. Rig and test weights at shoulders, wrists, fingers, hips, knees, neck and face.
5. Keep a high-detail source mesh for authoring and create mobile LODs.
6. Create a consistent humanoid bone map and rest pose for Godot retargeting.
7. Retarget motion clips individually. Review root drift, foot sliding, joint flips, contact poses, weapon grip, clipping and blend transitions.
8. Preserve facial blendshapes required for blinking, expressions and dialogue. Do not remove all morph targets merely to reduce the GLB size.
9. Import into Godot and verify the rig, animation names, material maps, skeleton bounds and runtime state transitions.
10. Capture review screenshots at 720p and inspect the character in actual gameplay lighting.

### Environment pipeline

- Build three distinct traversable levels, not only palette swaps around one arena.
- Use original blockouts and collision first. Then integrate curated modular pieces, terrain, rocks, props, decals and PBR surfaces.
- Use real-world scale and consistent texel density. Bake static lighting when practical.
- Create collision proxies, navigation, checkpoints, traversal gates, combat spaces, landmarks and authored camera routes.
- Use LOD, occlusion and visibility ranges where beneficial. Avoid unbounded high-resolution texture imports.
- Check that materials survive Blender-to-GLB-to-Godot conversion. Replace unsupported or expensive shaders with mobile-compatible equivalents.

### Audio pipeline

- Keep dialogue, ambience, music, UI, footsteps, weapons, impacts, enemy vocals and boss cues on separate buses.
- Maintain a dry/source WAV and a compressed in-game OGG/Opus version as appropriate.
- Record sample rate, channel count, loudness treatment, loop points and licence per sound.
- Avoid clipping and inconsistent loudness; audition in the game mix, not only in a DAW.
- Retain the original procedural audio fallback until sourced replacements pass quality and legal review.

## 7. Source-control and build strategy

GitHub remains the canonical repository because the active game branch and tested CI workflows already live there.

- **GitHub Actions:** primary tests, Godot headless validation, Blender generation, Android export, artefact upload and failure logs.
- **GitLab CI/CD:** optional independent mirror or second CI provider if it gives a needed runner, pipeline or review advantage.
- **Bitbucket Pipelines:** optional mirror or alternate deployment path if it gives a needed repository integration or pipeline feature.
- **SourceForge:** source discovery and distribution of suitable open-source utilities; not a replacement for the canonical game repository.
- **Git LFS or release artefacts:** store large source art, video takes and non-runtime working files outside ordinary Git blobs. Keep the main repository lightweight and preserve deterministic asset versioning.
- Never mirror private performer video, access tokens, paid marketplace archives or confidential credentials into a public repository.
- Pin tool versions, Blender scripts, CI actions and downloaded project revisions. Avoid floating dependencies for release builds.

Do not make GitLab and Bitbucket competing canonical repos merely to claim that all platforms are used. Each extra host must have a defined purpose and a tested sync strategy.

## 8. Android quality and acceptance gates

The project is currently Android-first and uses Godot Compatibility rendering. Keep Compatibility as the broad-support baseline. Benchmark Mobile/Vulkan as a separate tier only on devices that meet the current Godot system requirements.

Initial target tiers are acceptance goals, not current benchmark claims:

| Device tier | Target | Strategy |
|---|---:|---|
| Low / older compatible | 30 FPS stable | Compatibility renderer, dynamic internal scale, restrained shadows/particles |
| Balanced | 40-45 FPS stable | Compatibility baseline, selective effects only after profiling |
| High-end | 60 FPS where sustained | Compare Mobile/Vulkan and Compatibility with real-device captures |

Required measurements:
- average and 95th percentile frame time;
- CPU/GPU use, draw calls, triangles, texture memory and total memory;
- thermals and frame pacing over a 20-minute combat/traversal run;
- input-to-action latency and touch reachability;
- audio underruns, crackles and pause/resume recovery;
- install, offline start, save persistence, upgrade and uninstall/reinstall behaviour.

A passing GitHub Actions build proves the APK was exported and passed configured automated checks. It does not prove visual fidelity, real-device performance, thermal stability or release readiness.

## 9. Repeatable selection score

Score each candidate from 0 to 5 in these categories, then compare it with other candidates in the same role:

| Criterion | Weight |
|---|---:|
| Visual quality and originality | 25% |
| Licence clarity and distribution rights | 20% |
| Godot / GLB / Blender compatibility | 15% |
| Mobile performance and memory cost | 15% |
| Rig, animation or material quality | 10% |
| Documentation, source integrity and maintainability | 10% |
| Integration effort | 5% |

**Hard gates override the score:** unclear rights, unsafe source files, missing provenance or impossible mobile budgets mean reject, irrespective of visual score.

## 10. Current integration status

As of 2026-11-08:
- The project uses Godot 4.7.2 and an Android Compatibility rendering profile.
- The hero asset generator produces an original skinned stylised prototype, not a photoreal final hero.
- The markerless mocap workflow is experimental and its current sample motion is not the final combat animation library.
- The procedural soundtrack and generated effects are original project content.
- The repository's ASSET_PROVENANCE.csv records the existing procedural ambient score. No external asset listed in this policy is claimed to have been downloaded or integrated.
- GitHub Actions runs 300 (repository tests), 146 (Godot validation), 130 (Android debug APK) and 36 (mocap character workflow) all completed successfully on commit fc36db5291bdffb2b637c21c17cfbae356defcec. The APK artifact was produced and archived by CI. This is not a physical-device QA result.

## 11. Operating rule for future tasks

For every relevant future task, start by identifying the actual production gap and search the source ecosystem sections above plus additional current sources. Select only resources that fit the task. Compare at least one open/free option and one higher-quality marketplace option when that comparison can materially improve the result. Verify current licence and technical compatibility before download. Integrate one controlled asset or tool at a time, record provenance, run import and project tests, inspect the visual result and measure Android impact. Report clearly what was researched, downloaded, changed, tested, blocked or left as a candidate.

**The quality goal is ambitious; the release claims must stay evidence-based.**
