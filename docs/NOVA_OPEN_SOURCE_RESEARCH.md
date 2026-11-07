# Nova Ancient Warrior - open-source research register

Date: 2026-11-07  
Engine: Godot 4.7.2 · target: Android ARM64 · renderer: Compatibility  
Secondary PS2SDK target remains separate from the APK.

## Research scope

GitHub discovery returned **300 unique repositories** across MIT-, Apache-2.0-, and BSD-3-Clause-filtered Godot repository searches. This register lists 110 candidates. These are discovery candidates, not a claim that every code file, bundled model, texture, sound, or dependency is legally cleared. The curated shortlist below was inspected more closely. Check the exact LICENSE, release tag, engine compatibility, asset provenance and dependencies before copying anything.

## Shortlist assessed for Nova

| Resource | Practical relevance / decision |
|---|---|
| [Godot Engine](https://github.com/godotengine/godot) | Engine and exact-version baseline. |
| [Official demo projects](https://github.com/godotengine/godot-demo-projects) | Reference scenes and official practices. |
| [Third-person controller](https://github.com/sarimoly/Godot-Third-Person-Controller) | Camera, acceleration, FSM, jump buffering; check 4.7 compatibility and asset license. |
| [Steering AI Framework](https://github.com/GDQuest/godot-steering-ai-framework) | Seek/arrive/avoidance and blended enemy movement. |
| [Beehave](https://github.com/bitbrain/beehave) | Behavior trees, debug monitor and test automation. |
| [State Charts](https://github.com/derkork/godot-statecharts) | Hierarchical player/enemy/boss states and guarded transitions. |
| [GUT 9.7.1 for Godot 4.7](https://github.com/bitwes/Gut/tree/godot_4_7) | Godot-native unit tests for combat and gameplay rules. |
| [Virtual Joystick](https://github.com/MarcoFazioRandom/Virtual-Joystick-Godot) | Mobile analog controls; README states MIT. |
| [Touch Input Manager](https://github.com/Federico-Ciuffardi/GodotTouchInputManager) | Gesture input reference, only if swipe/lock-on is added. |
| [Godot Open RPG](https://github.com/gdquest-demos/godot-open-rpg) | Code organization and GDScript practices; turn-based, not action-combat. |
| [Godot shaders](https://github.com/gdquest-demos/godot-shaders) | Shader concepts only; README notes Godot 4 port still in progress. |
| [Godot Jolt](https://github.com/godot-jolt/godot-jolt) | Alternative physics candidate; do not switch without device benchmark. |
| [GDScript Toolkit](https://github.com/Scony/godot-gdscript-toolkit) | Formatting/lint candidate; validate parser against GDScript 4.7. |
| [Godot CI](https://github.com/abarichello/godot-ci) | CI patterns; compare with current pinned 4.7.2 workflow. |
| [Kenney](https://kenney.nl/assets) | CC0 game assets; record exact pack. |
| [Quaternius](https://quaternius.com) | CC0 rigged characters, creatures, environments and animations. |
| [Poly Haven](https://polyhaven.com) | CC0 PBR textures, HDRIs and props; use mobile-sized textures. |
| [ambientCG](https://ambientcg.com) | CC0 PBR material library. |
| [Meta Open Sound](https://github.com/facebookincubator/Meta-open-sound) | Instrument samples CC0; game/VR SFX CC-BY 4.0, credit required. |
| [Sonniss GDC audio](https://sonniss.com/gameaudiogdc) | Large SFX packs; read the exact bundle terms. |
| [OpenGameArt](https://opengameart.org) | Mixed license catalog; inspect each asset. |
| [Blender](https://www.blender.org) | Open modelling, rigging and animation pipeline. |
| [Khronos glTF](https://github.com/KhronosGroup/glTF) | Interchange format for meshes, materials, skins and animation. |
| [meshoptimizer](https://github.com/zeux/meshoptimizer) | Mesh simplification/cache optimization; Godot uses it for mesh LOD. |
| [Android GPU Inspector](https://github.com/google/agi) | GPU/frame profiling on supported Android devices. |
| [Perfetto](https://perfetto.dev/) | CPU scheduling, frame pacing, memory and thermal traces. |
| [RenderDoc](https://renderdoc.org/) | GPU frame capture where Android driver support permits. |
| [gdUnit4](https://github.com/MikeSchulze/gdUnit4) | Alternative Godot testing framework; compare with GUT. |
| [Godot Asset Library](https://godotengine.org/asset-library/) | Editor addons; verify exact engine version and license. |

## 110 GitHub repository candidates

Search filter indicates the repository-license metadata query used. It does not replace reading the actual license and checking bundled assets.

| # | Repository | Search filter | Default branch |
|---:|---|---|---|
| 1 | [godotengine/godot](https://github.com/godotengine/godot) | MIT-filtered | master |
| 2 | [nodejitsu/godot](https://github.com/nodejitsu/godot) | MIT-filtered | patch-branch |
| 3 | [NVIDIA-RTX/godot](https://github.com/NVIDIA-RTX/godot) | MIT-filtered | nvidia-pt-dlss |
| 4 | [TaloDev/godot](https://github.com/TaloDev/godot) | MIT-filtered | develop |
| 5 | [godotengine/godot-demo-projects](https://github.com/godotengine/godot-demo-projects) | MIT-filtered | master |
| 6 | [Stary2001/godot](https://github.com/Stary2001/godot) | MIT-filtered | 3.5.2-stable_switch |
| 7 | [joho/godotenv](https://github.com/joho/godotenv) | MIT-filtered | main |
| 8 | [2Retr0/GodotOceanWaves](https://github.com/2Retr0/GodotOceanWaves) | MIT-filtered | main |
| 9 | [godotengine/godot-cpp](https://github.com/godotengine/godot-cpp) | MIT-filtered | master |
| 10 | [Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp) | MIT-filtered | main |
| 11 | [gdquest-demos/godot-3-demos](https://github.com/gdquest-demos/godot-3-demos) | MIT-filtered | master |
| 12 | [catppuccin/godot](https://github.com/catppuccin/godot) | MIT-filtered | main |
| 13 | [hi-godot/godot-ai](https://github.com/hi-godot/godot-ai) | MIT-filtered | main |
| 14 | [Zylann/godot_voxel](https://github.com/Zylann/godot_voxel) | MIT-filtered | master |
| 15 | [godot-fun/godot-start](https://github.com/godot-fun/godot-start) | MIT-filtered | main |
| 16 | [sanikoyes/godot](https://github.com/sanikoyes/godot) | MIT-filtered | master |
| 17 | [gdquest-demos/godot-open-rpg](https://github.com/gdquest-demos/godot-open-rpg) | MIT-filtered | main |
| 18 | [nathanhoad/godot_dialogue_manager](https://github.com/nathanhoad/godot_dialogue_manager) | MIT-filtered | main |
| 19 | [godot-jolt/godot-jolt](https://github.com/godot-jolt/godot-jolt) | MIT-filtered | master |
| 20 | [GodotNuts/GodotFirebase](https://github.com/GodotNuts/GodotFirebase) | MIT-filtered | main |
| 21 | [tetafro/godot](https://github.com/tetafro/godot) | MIT-filtered | master |
| 22 | [godotengine/godot-vscode-plugin](https://github.com/godotengine/godot-vscode-plugin) | MIT-filtered | master |
| 23 | [jame581/GodotPrompter](https://github.com/jame581/GodotPrompter) | MIT-filtered | master |
| 24 | [bukkbeek/GodotPixelRenderer](https://github.com/bukkbeek/GodotPixelRenderer) | MIT-filtered | main |
| 25 | [dracula/godot](https://github.com/dracula/godot) | MIT-filtered | master |
| 26 | [dialogic-godot/dialogic](https://github.com/dialogic-godot/dialogic) | MIT-filtered | main |
| 27 | [abarichello/godot-ci](https://github.com/abarichello/godot-ci) | MIT-filtered | master |
| 28 | [DmitriySalnikov/GodotPCKExplorer](https://github.com/DmitriySalnikov/GodotPCKExplorer) | MIT-filtered | master |
| 29 | [godotjs/GodotJS](https://github.com/godotjs/GodotJS) | MIT-filtered | main |
| 30 | [RykoTheDev/GodotHub](https://github.com/RykoTheDev/GodotHub) | MIT-filtered | main |
| 31 | [godotengine/godot-website](https://github.com/godotengine/godot-website) | MIT-filtered | master |
| 32 | [2shady4u/godot-sqlite](https://github.com/2shady4u/godot-sqlite) | MIT-filtered | master |
| 33 | [migueldeicaza/SwiftGodot](https://github.com/migueldeicaza/SwiftGodot) | MIT-filtered | main |
| 34 | [borndotcom/react-native-godot](https://github.com/borndotcom/react-native-godot) | MIT-filtered | master |
| 35 | [lampe-games/godot-open-rts](https://github.com/lampe-games/godot-open-rts) | MIT-filtered | main |
| 36 | [2Retr0/GodotGrass](https://github.com/2Retr0/GodotGrass) | MIT-filtered | main |
| 37 | [godot64/GoDot](https://github.com/godot64/GoDot) | MIT-filtered | master |
| 38 | [hhyyrylainen/GodotPckTool](https://github.com/hhyyrylainen/GodotPckTool) | MIT-filtered | master |
| 39 | [godotengine/godot-proposals](https://github.com/godotengine/godot-proposals) | MIT-filtered | master |
| 40 | [edbeeching/godot_rl_agents](https://github.com/edbeeching/godot_rl_agents) | MIT-filtered | main |
| 41 | [godot-rust/gdnative](https://github.com/godot-rust/gdnative) | MIT-filtered | master |
| 42 | [gdquest-demos/godot-kickstarter-2019](https://github.com/gdquest-demos/godot-kickstarter-2019) | MIT-filtered | master |
| 43 | [Scony/godot-gdscript-toolkit](https://github.com/Scony/godot-gdscript-toolkit) | MIT-filtered | master |
| 44 | [Maaack/Godot-Game-Template](https://github.com/Maaack/Godot-Game-Template) | MIT-filtered | main |
| 45 | [tessarakkt/godot4-oceanfft](https://github.com/tessarakkt/godot4-oceanfft) | MIT-filtered | devel |
| 46 | [derkork/godot-statecharts](https://github.com/derkork/godot-statecharts) | MIT-filtered | main |
| 47 | [nezvers/Godot-GameTemplate](https://github.com/nezvers/Godot-GameTemplate) | MIT-filtered | master |
| 48 | [chickensoft-games/GodotEnv](https://github.com/chickensoft-games/GodotEnv) | MIT-filtered | main |
| 49 | [func-godot/func_godot_plugin](https://github.com/func-godot/func_godot_plugin) | MIT-filtered | main |
| 50 | [ramaureirac/godot-tactical-rpg](https://github.com/ramaureirac/godot-tactical-rpg) | MIT-filtered | development |
| 51 | [MakovWait/godots](https://github.com/MakovWait/godots) | MIT-filtered | main |
| 52 | [MrEliptik/godot_experiments](https://github.com/MrEliptik/godot_experiments) | MIT-filtered | master |
| 53 | [mirror-engine/godot](https://github.com/mirror-engine/godot) | MIT-filtered | themirror |
| 54 | [kdada/godot](https://github.com/kdada/godot) | MIT-filtered | openharmony |
| 55 | [uno1982/godot](https://github.com/uno1982/godot) | MIT-filtered | master |
| 56 | [HaxeGodot/godot](https://github.com/HaxeGodot/godot) | MIT-filtered | main |
| 57 | [Federico-Ciuffardi/GodotTouchInputManager](https://github.com/Federico-Ciuffardi/GodotTouchInputManager) | MIT-filtered | master |
| 58 | [firebelley/godot-export](https://github.com/firebelley/godot-export) | MIT-filtered | master |
| 59 | [chickensoft-games/GodotGame](https://github.com/chickensoft-games/GodotGame) | MIT-filtered | main |
| 60 | [passivestar/godot-minimal-theme](https://github.com/passivestar/godot-minimal-theme) | MIT-filtered | main |
| 61 | [GodotVR/godot-xr-tools](https://github.com/GodotVR/godot-xr-tools) | MIT-filtered | master |
| 62 | [godotengine/godot-git-plugin](https://github.com/godotengine/godot-git-plugin) | MIT-filtered | master |
| 63 | [MarcoFazioRandom/Virtual-Joystick-Godot](https://github.com/MarcoFazioRandom/Virtual-Joystick-Godot) | MIT-filtered | Main |
| 64 | [godotengine/godot-headers](https://github.com/godotengine/godot-headers) | MIT-filtered | 3.x |
| 65 | [godot-extended-libraries/godot-next](https://github.com/godot-extended-libraries/godot-next) | MIT-filtered | master |
| 66 | [Open-Industry-Project/Open-Industry-Project-Godot](https://github.com/Open-Industry-Project/Open-Industry-Project-Godot) | MIT-filtered | master |
| 67 | [vnen/godot-tiled-importer](https://github.com/vnen/godot-tiled-importer) | MIT-filtered | master |
| 68 | [utopia-rise/godot-jvm](https://github.com/utopia-rise/godot-jvm) | MIT-filtered | master |
| 69 | [TheDuckCow/godot-road-generator](https://github.com/TheDuckCow/godot-road-generator) | MIT-filtered | main |
| 70 | [appsinacup/godot-rapier-physics](https://github.com/appsinacup/godot-rapier-physics) | MIT-filtered | main |
| 71 | [Homebrodot/Godot](https://github.com/Homebrodot/Godot) | MIT-filtered | main/3.5 |
| 72 | [Cat-Lips/GodotSharp.SourceGenerators](https://github.com/Cat-Lips/GodotSharp.SourceGenerators) | MIT-filtered | main |
| 73 | [GDQuest/godot-steering-ai-framework](https://github.com/GDQuest/godot-steering-ai-framework) | MIT-filtered | master |
| 74 | [baconandgames/godot4-game-template](https://github.com/baconandgames/godot4-game-template) | MIT-filtered | main |
| 75 | [tugcantopaloglu/godot-mcp](https://github.com/tugcantopaloglu/godot-mcp) | MIT-filtered | main |
| 76 | [dreadpon/godot_spatial_gardener](https://github.com/dreadpon/godot_spatial_gardener) | MIT-filtered | master |
| 77 | [Miziziziz/MizGodotTools](https://github.com/Miziziziz/MizGodotTools) | MIT-filtered | main |
| 78 | [pkdawson/imgui-godot](https://github.com/pkdawson/imgui-godot) | MIT-filtered | master |
| 79 | [viniciusgerevini/godot-aseprite-wizard](https://github.com/viniciusgerevini/godot-aseprite-wizard) | MIT-filtered | godot_4 |
| 80 | [ee0pdt/Godot-MCP](https://github.com/ee0pdt/Godot-MCP) | MIT-filtered | main |
| 81 | [yurineko73/Godot-MCP-Native](https://github.com/yurineko73/Godot-MCP-Native) | MIT-filtered | main |
| 82 | [godot-go/godot-go](https://github.com/godot-go/godot-go) | MIT-filtered | main |
| 83 | [godotengine/godot-asset-library](https://github.com/godotengine/godot-asset-library) | MIT-filtered | master |
| 84 | [crystal-bit/godot-game-template](https://github.com/crystal-bit/godot-game-template) | MIT-filtered | main |
| 85 | [barcoderdev/unitypackage_godot](https://github.com/barcoderdev/unitypackage_godot) | MIT-filtered | main |
| 86 | [gdquest-demos/godot-platformer-2d](https://github.com/gdquest-demos/godot-platformer-2d) | MIT-filtered | master |
| 87 | [bitbrain/godot-gamejam](https://github.com/bitbrain/godot-gamejam) | MIT-filtered | main |
| 88 | [lupoglaz/GodotAIGym](https://github.com/lupoglaz/GodotAIGym) | MIT-filtered | master |
| 89 | [GodotVR/godot_openxr_for_godot_3.x](https://github.com/GodotVR/godot_openxr_for_godot_3.x) | MIT-filtered | master |
| 90 | [gdquest-demos/godot-make-pro-2d-games](https://github.com/gdquest-demos/godot-make-pro-2d-games) | MIT-filtered | master |
| 91 | [quentincaffeino/godot-console](https://github.com/quentincaffeino/godot-console) | MIT-filtered | develop |
| 92 | [mohsenph69/Godot-MTerrain-plugin](https://github.com/mohsenph69/Godot-MTerrain-plugin) | MIT-filtered | master |
| 93 | [kidscancode/godot3_procgen_demos](https://github.com/kidscancode/godot3_procgen_demos) | MIT-filtered | master |
| 94 | [paulloz/godot-ink](https://github.com/paulloz/godot-ink) | MIT-filtered | main |
| 95 | [MrEliptik/godot_ui_components](https://github.com/MrEliptik/godot_ui_components) | MIT-filtered | main |
| 96 | [gaea-godot/gaea](https://github.com/gaea-godot/gaea) | MIT-filtered | 2.0 |
| 97 | [KnifeXRage/Godot-Secure](https://github.com/KnifeXRage/Godot-Secure) | MIT-filtered | main |
| 98 | [PacktPublishing/Godot-Game-Engine-Projects](https://github.com/PacktPublishing/Godot-Game-Engine-Projects) | MIT-filtered | master |
| 99 | [henriquelalves/GodotTIE](https://github.com/henriquelalves/GodotTIE) | MIT-filtered | master |
| 100 | [tomyud1/godot-mcp](https://github.com/tomyud1/godot-mcp) | MIT-filtered | main |
| 101 | [CraterCrash/godot-orchestrator](https://github.com/CraterCrash/godot-orchestrator) | Apache-2.0-filtered | main |
| 102 | [hannesstruss/godot](https://github.com/hannesstruss/godot) | Apache-2.0-filtered | master |
| 103 | [heroiclabs/nakama-godot](https://github.com/heroiclabs/nakama-godot) | Apache-2.0-filtered | master |
| 104 | [FrogSquare/GodotFireBase](https://github.com/FrogSquare/GodotFireBase) | Apache-2.0-filtered | master |
| 105 | [bytemeadow/godot-bevy](https://github.com/bytemeadow/godot-bevy) | Apache-2.0-filtered | main |
| 106 | [heroiclabs/fishgame-godot](https://github.com/heroiclabs/fishgame-godot) | Apache-2.0-filtered | main |
| 107 | [JetBrains/godot-support](https://github.com/JetBrains/godot-support) | Apache-2.0-filtered | master |
| 108 | [FrogSquare/GodotAds](https://github.com/FrogSquare/GodotAds) | Apache-2.0-filtered | master |
| 109 | [IvanMurzak/Godot-MCP](https://github.com/IvanMurzak/Godot-MCP) | Apache-2.0-filtered | main |
| 110 | [FrogSquare/GodotGoogleService](https://github.com/FrogSquare/GodotGoogleService) | Apache-2.0-filtered | master |

## Findings from Godot 4.7 documentation and source review

1. **Keep Compatibility for the initial low-end Android target.** Godot documents Compatibility as intended for older/lower-end mobile GPUs. Switching to Mobile/Forward+ without handset profiling risks losing compatibility or performance.
2. **Lighting is the first likely GPU cost.** Compatibility uses a multi-pass path for shadowed lights. Keep one shadow-casting directional light; do not add multiple shadowed OmniLights. Current brazier lights are unshadowed, which is the correct direction.
3. **Glow is supported in Compatibility**, but uses a different, simpler implementation. Keep it as a quality setting and benchmark it rather than assuming it is free or unsupported.
4. **LOD/HLOD and occlusion are tools for larger levels.** The current arena is compact; prioritize material/light count, model complexity, texture sizes and animation before implementing elaborate occlusion.
5. **Move enemy simulation to the fixed physics tick.** Player motion is already fixed-step, while enemy chase and cooldown/damage currently update in _process. Consolidate gameplay state into fixed-step simulation for stable behaviour and repeatability.
6. **Remove per-frame temporary arrays.** The current enemy loop allocates a temporary copy every rendered frame. Use stable iteration and prune invalid nodes without that recurring allocation.
7. **Decompose the monolithic script incrementally.** Extract Player, Enemy, Combat, HUD, Audio, Camera and Arena into scenes/scripts, preserving a working baseline at each commit.
8. **Add gameplay tests.** GUT 9.7.1 has a Godot 4.7 branch. Cover attack cone/range, damage, enemy cooldown, arena bounds, restart and victory. The existing 570 Python tests validate repository/skill structure, not gameplay rules.
9. **Improve mobile controls.** Current touch buttons work as actions but lack an analog stick and safe-area-aware layout. Evaluate the MIT Virtual Joystick, or build responsive controls with viewport anchors.
10. **Replace primitive actor meshes.** Use a coherent CC0 rigged character/creature pack from Quaternius or Kenney. Validate skeleton, animation names, triangle counts and texture dimensions before inclusion.
11. **Replace placeholder sine tones over time.** Use authored weapon/impact/footstep/UI SFX. Meta Open Sound has CC0 instrument samples and CC-BY 4.0 game/VR SFX; retain attribution for CC-BY assets.
12. **Benchmark the physical device.** Capture average FPS, 1% lows, frame time, memory/PSS, battery temperature, device/GPU, renderer, resolution and duration. CI export success is not a performance result.

## Prioritized implementation plan

- P0: fixed-step enemy simulation; remove per-frame duplicate array; gameplay unit tests.
- P1: scene/component split with no behavioural regression; structured debug counters and error-free CI.
- P2: CC0 rigged GLB player/enemy assets; animation state machine; asset provenance manifest.
- P3: attack windows, hit reactions, hit-stop, invulnerability frames, telegraphs, combo buffer and lock-on.
- P4: art pass, LOD/visibility ranges where justified, and low/medium/high quality presets.
- P5: reproducible asset import pipeline; maintain separate Android APK and PS2SDK outputs.

## Primary technical references

- Renderer matrix: https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html
- Android/system requirements: https://docs.godotengine.org/en/4.7/about/system_requirements.html
- Android export: https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html
- 3D optimization: https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html
- Internal renderer architecture: https://docs.godotengine.org/en/4.7/engine_details/architecture/internal_rendering_architecture.html
- Visibility ranges: https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html
- Mesh LOD: https://docs.godotengine.org/en/stable/tutorials/3d/mesh_lod.html
- GUT 9.7.1 / Godot 4.7: https://github.com/bitwes/Gut/tree/godot_4_7
- Android GPU Inspector: https://github.com/google/agi
- Perfetto: https://perfetto.dev/
- RenderDoc: https://renderdoc.org/

## Integration guardrails

- Public repository does not mean unrestricted reuse. Check repository and per-asset licenses.
- Preserve notices for CC-BY and other attribution licenses. Avoid GPL code in the shipped game unless compatibility is reviewed.
- Pin plugin releases/commits, check Godot 4.7.2 support, inspect dependencies, and run tests before adoption.
- Do not add copyrighted game assets, extracted PS2 game files, proprietary binaries or Sony assets.
- Do not change renderer, physics engine or asset pack without reproducible builds and target-device benchmarks.

## Code-specific audit summary

The current main.gd is a monolithic prototype using procedural primitive meshes. The highest-value safe optimizations are fixed-step enemy simulation and removing the per-frame duplicate array. The next architecture step is script/scene decomposition plus GUT tests. Current CI verifies headless import/script parsing, Python repository tests, APK export, APK signature and package ID; it does not prove device frame rate, touch ergonomics, audio quality or thermal stability.
