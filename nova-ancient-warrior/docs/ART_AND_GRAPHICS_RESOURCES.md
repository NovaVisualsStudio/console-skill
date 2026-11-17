# External Art & Graphics Resources for Nova Ancient Warrior

This file records external reference repositories for the project's art-production workflow. These are **reference resources**, not dependencies and not proof that assets have already been generated or integrated.

## Verified public repositories

| Resource | Intended use | Integration policy |
|---|---|---|
| [EL4CTEO/blender-skills](https://github.com/EL4CTEO/blender-skills) | Blender-oriented agent guidance for 3D asset workflows | Select only relevant modeling, materials, rigging, animation, and export instructions after inspecting the current upstream files and license. |
| [jammyfu/open-game-skills](https://github.com/jammyfu/open-game-skills) | Game-development skills with art direction and production workflows | Use as a cross-discipline reference; adapt only workflows compatible with Godot and this project's pipeline. |
| [majidmanzarpour/blender-game-skills](https://github.com/majidmanzarpour/blender-game-skills) | Blender/game-asset workflow reference | Evaluate its actual scope and license before relying on or copying any content. |

## Additional discovery lead

- [Game Art Pipeline Skills directory](https://skilldb.dev/skills/game-art-pipeline-skills) - a discovery/catalog page for art-pipeline skills. Treat it as a discovery lead; verify the original publisher, source repository, version, and license before adding any of its content to this repository.

## How these resources should be applied

1. **Art direction:** establish a consistent original visual identity for the hero, enemies, environments, props, UI, and effects.
2. **Character art:** prioritize a production-ready hero and enemy pipeline: reference/concept, high/low-poly modeling, topology, UVs, PBR materials, rigging, animation, and Godot import validation.
3. **Environment art:** build modular ruins, terrain, architecture, foliage, props, and readable combat spaces.
4. **Materials and lighting:** use physically based materials, coherent texel density, baked or economical lighting where appropriate, and mobile-friendly shaders.
5. **VFX and feedback:** create original impact, dust, sparks, fire, hit reactions, and readable boss telegraphs.
6. **Technical art:** profile GPU/CPU/memory on target Android tiers; use LODs, sensible texture sizes/compression, mesh budgets, batching/instancing, and scalable quality settings.

## Safety, licensing, and compatibility gates

- Do not copy upstream skill files, models, textures, animations, sounds, or other assets into this project until their license and attribution requirements have been checked.
- Prefer linking to upstream sources and writing project-specific implementation notes. Preserve upstream copyright and license notices when reuse is permitted.
- Treat generated or downloaded assets as untrusted until inspected for provenance, license, file integrity, malware risk, topology, scale, skeleton compatibility, and visual quality.
- Do not assume a Blender skill can execute in the current cloud/GitHub environment. Blender automation requires an available Blender runtime; a skill description alone does not provide one.
- Target the project's supported Godot version and Android mid/high device profiles. Do not add desktop-only steps as mandatory user actions.
- Keep the existing game files intact. Integrate changes on the dedicated development branch and validate each asset in Godot before it is considered production-ready.

## Status

- Resource links recorded and repository existence checked on 2026-11-08.
- Upstream contents, individual skill quality, and exact licenses still require per-resource review before reuse.
- No upstream code or assets have been vendored by this documentation-only change.
- No claim is made that these resources have been installed, executed, or used to produce new game assets.
