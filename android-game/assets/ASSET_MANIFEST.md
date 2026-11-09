# NOVA Ancient Warrior - 3D asset manifest

All third-party assets below are free to use and released under CC0 1.0. No paid tier, paid API, or subscription is used. Poly Haven's public API is free and its requested in-game credit is shown in the HUD.

| Asset | Creator | Source | Licence | Use |
|---|---|---|---|---|
| CharacterCreator generated male base body | kblood/CharacterCreator | https://github.com/kblood/CharacterCreator | CC0 1.0 generated output | Realistic 2K-textured skin/face mesh and 53-joint humanoid skeleton |
| CharacterCreator generated outfit: T-shirt, jeans, boots, trenchcoat and short hair | kblood/CharacterCreator | https://github.com/kblood/CharacterCreator | CC0 1.0 generated output | Skinned clothing and hair meshes fitted to the same 53-joint rig |
| Quaternius Universal Base Characters - Superhero Male FullBody | Quaternius | https://quaternius.itch.io/universal-base-characters | CC0 1.0 | Fallback humanoid mesh and 65-joint skeleton |
| Quaternius Universal Animation Library 2 - Standard | Quaternius | https://quaternius.itch.io/universal-animation-library-2 | CC0 1.0 | Retargetable locomotion, melee combos, reactions, parkour and death clips |
| Stone Wall 2K/4K PBR material | Charlotte Baglioni (photography), Dario Barresi (processing) | https://polyhaven.com/a/stone_wall | CC0 1.0 | Arena walls and ancient portal masonry: diffuse, OpenGL normal and roughness maps |
| Rock Tile Floor 2K/4K PBR material | Charlotte Baglioni | https://polyhaven.com/a/rock_tile_floor | CC0 1.0 | Arena floor: diffuse, OpenGL normal and roughness maps |
| Metal Plate 2K/4K PBR material | Rob Tuytel | https://polyhaven.com/a/metal_plate | CC0 1.0 | Warrior armor plates: diffuse, OpenGL normal, roughness and metalness maps |
| Leather Red 02 2K/4K PBR material | Rob Tuytel | https://polyhaven.com/a/leather_red_02 | CC0 1.0 | Armor belt and leather trim: diffuse, OpenGL normal and roughness maps |

## Provenance

- The primary hero is fetched into `assets/characters/charactercreator-base-body.glb` with separate CC0 skinned T-shirt, jeans, boots, trenchcoat and hair meshes. The setup script pins the CharacterCreator generated-output commit `852e48f316b90a0937234886630e4fb4cdfd1f78`. The generated GLBs are CC0, as documented in [CharacterCreator LICENSE-NOTES.md](https://github.com/kblood/CharacterCreator/blob/master/LICENSE-NOTES.md) and `output/asset_licenses.json`; the generator source is GPL-3.0 and is not bundled or executed by the game.
- The Quaternius humanoid remains as a fallback asset. Its source images/materials were omitted in the redistribution copy; NOVA applies its own PBR materials at runtime.
- The Standard animation library is fetched by `tools/fetch_cc0_animations.py` from a pinned public source commit. The script verifies the GLB header and length and stores the upstream CC0 notice alongside the asset.
- Animation import/retargeting maps the Quaternius UAL2 humanoid bone names to the Quaternius base-character skeleton. Only mapped bone tracks are copied into the runtime AnimationLibrary.
- The UAL2 Standard set has no dedicated death clip, so NOVA includes an original skeletal death-fall animation authored in GDScript and adds it to the runtime library.
- The humanoid material pass preserves source face/skin and hair textures, tunes non-metallic skin and hair roughness per surface, and keeps the separate CC0 short-hair mesh skin-bound to the same skeleton. Cinematic lighting uses a cool key, low-energy face fill, chapter-tinted armor rim and restrained soft glow, with two unshadowed fill lights to limit mobile shadow-map cost.
- Weapon wind-up and follow-through durations now match the configured attack startup and active windows; an attack-impact event is emitted at the exact start of the damage window and checked in the combat smoke test.
- Mobile runtime hot paths cache humanoid action, locomotion and combo animation selection instead of rescanning the imported clip library every physics frame. Missing dedicated run clips safely fall back to a faster walk cadence. Stamina HUD notifications are throttled to 10 Hz during passive regeneration while attack/dodge spending remains immediately signalled. Identical humanoid skeletons also share one cached retargeted CC0 animation library, keyed by the exact skeleton path, bone hierarchy and rest transforms; each character retains its own AnimationPlayer and playback state.
- The arena stone/floor and character metal/leather texture sets are fetched from Poly Haven's free public API at 2K by default for Android devices, with an optional 4K high-detail profile. Every JPG is verified against the API-provided MD5 hash. Diffuse, OpenGL normal and roughness maps use mipmaps and GPU texture compression. Select 4K with `NOVA_TEXTURE_TIER=4k`; the balanced Android profile uses `NOVA_TEXTURE_TIER=2k` (default). Poly Haven is credited in the in-game HUD as requested by its API terms.
- The assets are used as game content, not resold as a standalone asset pack.

## Reproducible setup

From the `android-game` directory:

```sh
python3 tools/fetch_cc0_animations.py
NOVA_TEXTURE_TIER=2k python3 tools/fetch_cc0_textures.py
# Optional high-detail profile for higher-memory Android devices:
NOVA_TEXTURE_TIER=4k python3 tools/fetch_cc0_textures.py
```

Then open the project once in Godot 4.7.2 or newer so the GLB is imported. The Android CI workflow runs this setup automatically before import and export.

## Licence note

CC0 does not waive third-party trademark, privacy, publicity or other rights outside copyright. The game uses original NOVA naming, story, levels, UI, audio and gameplay; no assets from commercial franchises are included.
