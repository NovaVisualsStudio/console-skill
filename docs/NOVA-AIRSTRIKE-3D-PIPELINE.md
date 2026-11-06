# Nova Airstrike: PS2 3D renderer and asset pipeline

## Engineering direction

The target is a native PlayStation 2 homebrew game, not a desktop game rendered at a low resolution. The renderer must respect the Emotion Engine, Graphics Synthesizer (GS), VU1, DMA and the PS2 memory budget.

The original Nova Dodge gameplay remains the source of reusable logic: pad input, game state, score/lives, enemy spawning, projectile lifecycle, collision intent and restart flow. The Air Combat branch supplies the first aircraft/gameplay iteration. This branch is the isolated 3D conversion experiment.

## Renderer stages

1. **World space**: meshes and gameplay entities use XYZ coordinates. The player is controlled in a local flight volume; enemies and projectiles have independent depth.
2. **Camera**: a chase camera follows the player with a configurable look-ahead. Camera transforms are kept separate from object transforms.
3. **Projection**: perspective projection maps camera-space geometry to the PS2 display. Near-plane clipping must happen before perspective division.
4. **Visibility**: back-face culling and a real GS Z-buffer are required for reliable overlap. Painter ordering is only a temporary fallback and must not be treated as a final depth solution.
5. **Materials**: PS2-friendly texture formats, small texture atlases, vertex colors and limited material states. Use mip/LOD choices conservatively; the GS has a fixed 4 MiB eDRAM budget.
6. **Submission**: batch triangle lists/strips and minimize state changes and DMA submissions. Profile packet sizes and frame time.
7. **Effects**: engine glow, projectile trails, hit flashes, particle bursts and alpha effects are separate render queues so opaque geometry can be depth-tested first.

## Reference implementation research

- **PS2SDK** supplies the native PS2 libraries and build environment: https://ps2dev.github.io/ps2sdk/
- **gsKit** is the PS2 Graphics Synthesizer C interface. Its upstream cube example demonstrates the intended 3D matrix path using `math3d.h`, `draw3d.h`, local/world/view/screen matrices, transformed vertices, Z testing and Gouraud triangle lists: https://github.com/ps2dev/gsKit
- **PS2SDK cube example**: https://github.com/ps2dev/ps2sdk/blob/master/ee/draw/samples/cube/cube.c (reference for GS Z-buffer allocation, `ZTEST_METHOD_GREATER_EQUAL`, and enabling/disabling pixel tests).
- **gsKit cube example**: https://github.com/ps2dev/gsKit/blob/master/examples/cube/cube.c
- **Demake Engine** is a useful external research reference for a glTF/GLB-to-PS2 asset pipeline, mesh conversion, texture atlasing, skeletal data, collision meshes and a PS2 runtime: https://github.com/snuri00/demake-engine
- **Play! / RetroArch Play! core** lists ELF as a supported content extension, but actual compatibility must be tested on the target Android device: https://docs.libretro.com/library/play/

External projects are references, not copied game assets or unreviewed dependencies. Confirm each dependency's license and build requirements before integrating code or assets.

## Current prototype status

The current `ps2-game/main.c` remains an experimental software world-to-screen renderer, but the latest pass now configures a PS2SDK framebuffer plus a GS Z buffer (`GS_ZBUF_32`, greater-equal depth test), submits per-vertex depth values, seeds the depth buffer at frame start, clips triangles against the near plane, and uses XYZ movement with a fixed particle pool for hit bursts and exhaust. The implementation follows the same PS2SDK draw/depth concepts shown by the official PS2SDK cube sample; it does not yet use gsKit or VU1.

It is **not yet a finished 3D renderer or a proven build**: texture mapping, perspective-correct texture coordinates, back-face culling, VU1 geometry processing, a reproducible GLB asset converter, sound, missions and emulator runtime evidence remain outstanding. CI must confirm the current branch compiles before the ELF can be considered ready.

## Acceptance gates

- [ ] Build the ELF with the PS2SDK toolchain.
- [ ] Validate the actual compiler/linker output, not only source inspection.
- [ ] Add unit/static tests for mesh bounds, projection edge cases, packet limits and asset conversion.
- [x] Add a PS2SDK draw-library GS Z-buffer path and per-vertex depth values (build/runtime validation still required).
- [x] Add near-plane clipping and depth-tested opaque geometry.
- [ ] Add back-face culling and perspective-correct texture mapping.
- [ ] Add original low-poly fighter, enemy, terrain and sky assets with a reproducible conversion pipeline.
- [ ] Run in Play! Android or another PS2 emulator and capture screenshots/logs.
- [ ] Tune performance on the user's actual phone/emulator; do not infer compatibility from a successful build.

## Performance rules for PS2

- Keep geometry compact and prefer indexed source meshes expanded into efficient triangle lists/strips at conversion time.
- Use fixed-size pools for entities, projectiles and particles; avoid per-frame heap allocation.
- Use 16-bit textures and CLUT formats where appropriate; pack textures into atlases to reduce state changes.
- Keep DMA/GIF packet buffers bounded and check capacity before writing.
- Use VU1 for transform/lighting work only after a stable CPU reference renderer exists and measurements show a benefit.
- Use simple collision volumes (sphere/AABB/capsule) for gameplay; do not run mesh collision for every projectile.
- Target stable frame pacing and predictable workloads rather than adding effects without profiling.
