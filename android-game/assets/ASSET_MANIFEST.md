# NOVA Ancient Warrior - 3D asset manifest

All third-party assets below are free to use and released under CC0 1.0. No paid tier, API credit, or subscription is used by the asset pipeline.

| Asset | Creator | Source | Licence | Use |
|---|---|---|---|---|
| Quaternius Universal Base Characters - Superhero Male FullBody | Quaternius | https://quaternius.itch.io/universal-base-characters | CC0 1.0 | Main humanoid mesh, UVs, skin and 65-joint humanoid skeleton |
| Quaternius Universal Animation Library 2 - Standard | Quaternius | https://quaternius.itch.io/universal-animation-library-2 | CC0 1.0 | Retargetable locomotion, melee combos, reactions, parkour and death clips |

## Provenance

- The hero GLB is fetched into `assets/characters/quaternius-standard-male.glb` by the setup script. It was sourced from the free Standard model and retains the skinned mesh and 65-joint skeleton. The source images/materials were omitted in the redistribution copy; NOVA applies its own PBR materials at runtime.
- The Standard animation library is fetched by `tools/fetch_cc0_animations.py` from a pinned public source commit. The script verifies the GLB header and length and stores the upstream CC0 notice alongside the asset.
- Animation import/retargeting maps the Quaternius UAL2 humanoid bone names to the Quaternius base-character skeleton. Only mapped bone tracks are copied into the runtime AnimationLibrary.
- The UAL2 Standard set has no dedicated death clip, so NOVA includes an original skeletal death-fall animation authored in GDScript and adds it to the runtime library.
- The assets are used as game content, not resold as a standalone asset pack.

## Reproducible setup

From the `android-game` directory:

```sh
python3 tools/fetch_cc0_animations.py
```

Then open the project once in Godot 4.7.2 or newer so the GLB is imported. The Android CI workflow runs this setup automatically before import and export.

## Licence note

CC0 does not waive third-party trademark, privacy, publicity or other rights outside copyright. The game uses original NOVA naming, story, levels, UI, audio and gameplay; no assets from commercial franchises are included.
