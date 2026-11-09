# Nova native combat kernel (C++)
This directory contains the first isolated C++ GDExtension module for Nova Ancient Warrior.

## Scope
- C++ performs a batch forward-cone and range pre-filter for sword-attack candidate targets.
- GDScript remains responsible for gameplay orchestration, physics queries, hurtbox validation, line of sight, animation timing, damage, hit reactions, UI and save data.
- The native helper must never replace authoritative Godot physics or damage checks.
- Initial targets: Godot 4.7, Linux x86_64 CI and Android arm64.

## Build
CI checks out a pinned official godotengine/godot-cpp revision and invokes SCons for API 4.7. The game does not load the extension until platform binaries are built, packaged and covered by runtime smoke tests.

## Integration gate
1. Linux and Android arm64 release libraries compile.
2. A Godot headless test loads the extension and checks empty input, zero forward vector, range and cone boundaries, and stable source indices.
3. Android export includes the arm64 shared library and starts on a real device.
4. Baseline and native-enabled benchmarks show a measurable improvement at representative enemy counts.

C++ does not improve graphics by itself. Rendering quality remains a separate asset, shader, lighting and renderer task.
