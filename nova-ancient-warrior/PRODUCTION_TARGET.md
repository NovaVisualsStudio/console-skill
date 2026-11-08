# Nova Ancient Warrior - Mid/High Android Production Target

Status: production specification only. This document does not claim that the listed features have been implemented or device-tested.

## Visual reference and scope

The two user-provided screenshots are visual direction references for a polished third-person mobile shooter: readable outdoor combat spaces, detailed human characters and equipment, strong material definition, clear weapon silhouettes, parachute/vehicle/world dressing, and touch-first HUD controls. They are references for quality and camera/UI language, not assets to copy.

The game remains an original IP. Do not copy PUBG/BGMI names, logos, maps, character designs, UI artwork, weapon skins, sounds, or proprietary assets. Build original environments, characters, UI and audio.

Target only supported mid-range and high-end Android phones. Do not spend production time maintaining a low-end/legacy visual preset. Still expose sensible Medium / High / Ultra settings within the supported device class so heat and battery can be managed.

## Product direction

Keep Nova Ancient Warrior as the original third-person action-adventure built around its warrior, melee combat, bosses and campaign progression. The supplied shooter screenshots define the desired mobile visual fidelity, environmental richness, character/material finish, camera readability and touch-HUD polish; they do not by themselves authorize changing the game's genre or replacing its sword-combat identity.

Preserve and deepen the current combat loop: exploration, sword combos, heavy attacks, dodge, guard, perfect parry, target lock, enemy telegraphs, elite encounters and multi-phase bosses. Add ranged weapons or shooter mechanics only if they serve the warrior campaign and fit its world; do not pivot the whole game into a battle-royale/shooter without a separate explicit decision.

Campaign structure remains the three original chapters: Sunken Ruins, Ember Causeway and Obsidian Throne. Each must become a separately authored playable level rather than a recoloured copy of one arena. The screenshots' urban density, varied elevation, props, distant landmarks and readable combat spaces are visual benchmarks, not level-layout templates.

## Rendering and materials

### Renderer decision gate

The current project uses the Godot GL Compatibility renderer on Android. Before changing the production renderer, create a representative visual/performance benchmark scene and compare Godot 4.7.2 Mobile (Vulkan) against Compatibility on actual mid-range and high-end devices. The Mobile renderer is the preferred candidate for richer mobile lighting/material features, but do not switch the shipping project until device coverage, stability and frame pacing are measured.

Do not use Forward+ as the Android shipping renderer. Keep it for desktop/editor previews only if useful.

### Material standard

Hero, enemies, weapons and major environment assets should use authored PBR materials with:
- Albedo/base colour.
- Normal map for surface relief.
- Roughness and metallic response, preferably packed into ORM where the pipeline supports it.
- Ambient occlusion baked or supplied where appropriate.
- Correct UV scale and texel density; avoid obvious stretching and repeated high-contrast tiling.
- Mipmaps and mobile-appropriate GPU texture compression.
- LODs and distance-based detail reduction for scenery.

Target texture budgets:
- Hero body/gear: 2K for the main atlas on High/Ultra; 1K on Medium.
- Hero face/head: dedicated 1K-2K atlas where needed.
- Weapons and hero-critical props: 1K-2K.
- Large environment modular surfaces: reusable 1K-2K tiling materials with variation decals.
- Small clutter: 256-512 px atlases or trim sheets.
These are ceilings to validate against memory, not a requirement to maximize every texture.

### Lighting and effects

- One carefully art-directed sun/key light with controlled shadow distance and resolution.
- Baked lighting or light probes for static environment contribution where practical.
- Dynamic shadows reserved for player, nearby enemies and selected high-value objects.
- Screen-space/post effects must be individually profiled and adjustable: ambient occlusion, bloom, tone mapping, anti-aliasing and resolution scaling.
- Use GPU particles sparingly for muzzle flash, dust, smoke, sparks and explosions; pool/reuse effects.
- Avoid many overlapping shadow-casting point lights and expensive transparent layers.

## Character and animation

Replace the current low-poly placeholder with an original production-ready humanoid:
- Credible human proportions and facial anatomy.
- Layered tactical clothing, boots, gloves, helmet/optional headgear, vest, backpack and readable equipment attachments.
- PBR skin/cloth/leather/metal/plastic materials with consistent roughness response.
- Deformation-tested humanoid skeleton, clean skin weights, weapon sockets and hand IK.
- Animation library: idle, walk/run, start/stop, turns, crouch, sprint, jump/land, aim idle/move, hip-fire, ADS, reload, weapon swap, recoil, hit reaction, stagger, death, vault and cover entry/exit.
- Animation state transitions must not pop; feet must not visibly slide during locomotion; hands must remain aligned to weapon grips.

Use Blender and free/open-source tooling. Every external mesh, rig, animation and texture must have a recorded source, version, author and licence in ASSET_PROVENANCE.csv before integration. Reject assets whose redistribution/commercial terms are unclear.

## Combat and enemy gameplay

Required systems:
- Third-person over-shoulder camera with collision handling and adjustable sensitivity.
- Camera-relative movement, sprint, dodge, guard, lock-on and responsive attack controls.
- Melee hit windows, clear startup/active/recovery timing, combo transitions, hit-stop and readable impact feedback.
- Weapon definitions for the warrior's sword and any campaign-approved secondary weapons; deterministic damage, range, arc and cooldown rules.
- Enemy perception, patrol/search/alert/combat states, approach, telegraph, strike, recovery, flanking and retreat.
- Distinct enemy roles (agile, heavy, ranged/magic if lore-appropriate) and authored elite/boss behaviours.
- Multi-phase bosses with distinct tells, arena mechanics and fair punish windows.
- Difficulty and accessibility options; avoid unavoidable off-screen damage.

All combat outcomes must be deterministic under tests: one hit event cannot apply duplicate damage; cooldown/stamina cannot become negative; line-of-sight and arena boundaries must be respected; enemies must not attack through walls.

## World and level design

Each of the three campaign missions must contain:
- A distinct authored layout and navigation graph.
- A clear main route plus optional flank/loot routes.
- At least three encounter spaces with different tactical geometry.
- Cover at multiple heights and materials; destructible cover only if its performance and gameplay value justify it.
- Landmarks visible from the main route.
- Mission objective, checkpoint, extraction/transition and boss/elite encounter where appropriate.
- Collision/navigation validation and no softlocks.

Build each mission in order: blockout -> playable combat routes -> greybox acceptance -> art pass -> lighting/audio pass -> optimization -> regression.

## Mobile UI and accessibility

Landscape-first, touch-first HUD:
- Left movement stick.
- Right look/aim region.
- Fire, ADS, reload, weapon swap, crouch, jump and interact controls.
- Context-aware buttons and configurable placement/scale/opacity.
- Multi-touch tests (move + aim + fire + reload).
- HUD for health/armour, ammo, objective, minimap/compass and mission state.
- Pause, settings, sensitivity, audio sliders, subtitles, language selection and colour/visibility options.
- Safe-area handling for notches and varied aspect ratios.

## Device tiers and acceptance

Supported class: mid-range and high-end Android devices with Vulkan-capable GPUs for the preferred Mobile renderer. Publish a tested compatibility list rather than promising support for every phone.

Provisional performance gates, to be measured on physical devices:
- Mid-range target: stable 30 FPS minimum in the heaviest encounter; aim for 40-45 FPS where thermals permit.
- High-end target: stable 60 FPS; allow 90 FPS only after sustained testing.
- p95 frame time: <= 33.3 ms at 30 FPS or <= 16.7 ms at 60 FPS for the relevant tier.
- 30-minute continuous combat soak without crash, severe thermal throttling, runaway memory or broken input/audio.
- No recurring shader-compilation hitch after warm-up in the same scene.
- Touch controls must support simultaneous movement, camera and firing without dropped input.
- Record device model, SoC/GPU, Android version, renderer, resolution scale, average/p95/p99 frame time, memory, temperature and battery drain.

A build passing CI is not evidence of visual quality or physical-device performance. Do not mark a tier supported until a real device has passed the acceptance run.

## Production gates and order

1. Audit current scenes, scripts, renderer settings, asset pipeline and existing tests.
2. Build one representative outdoor shooter vertical slice before expanding all missions.
3. Prove the renderer/material benchmark on real mid/high phones.
4. Lock the character skeleton and weapon attachment contract.
5. Deliver one complete player weapon loop and one enemy role.
6. Complete one polished vertical-slice district and validate performance.
7. Expand to the remaining two authored missions and enemy roles.
8. Finish narrative, UI, audio, progression, accessibility and localization.
9. Run regression, device matrix, thermal soak, memory and release-signing checks.

Do not merge to main, publish a release, or distribute an installable build until the complete game passes the agreed acceptance criteria and the owner explicitly approves release.

## Zero-cost policy

No paid services, paid asset packs, subscriptions, hosted inference, or APIs that can create charges. Prefer free/open-source tools and assets. Do not use free trials that can convert to paid plans. If a required asset cannot be sourced with clear compatible licensing at zero cost, create an original procedural substitute or leave it out and report the limitation.
