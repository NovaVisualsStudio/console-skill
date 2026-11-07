# Nova Ancient Warrior - Android-first prototype

An original third-person 3D action prototype using Godot 4.7.2 and GDScript. Procedural meshes and materials keep the first playable slice free of paid assets.

## Included
- Third-person arena camera and movement.
- Keyboard and on-screen touch controls.
- Jump and melee sword attack.
- Four pursuing enemies, vitality, score and victory/defeat states.
- Procedural stone arena, pillars, braziers, lighting and sky.
- Procedural one-shot audio cues.
- OpenGL Compatibility renderer for broader Android support.

## Controls
Keyboard: WASD or arrows to move, J or Enter to attack, Space to jump.
Touch: directional buttons lower-left; Attack and Jump lower-right. A Restart button appears after victory or defeat.

## Run
1. Install Godot 4.7.2 from https://godotengine.org/download/
2. Import this folder as a Godot project.
3. Run scenes/main.tscn.

## Verification status
This is a prototype source scaffold, not a finished game or a verified APK. It still needs a real Godot import/parse, Android export and device playtest. The PS2 port is a separate PS2SDK implementation; this Godot project is not a PS2 ELF.

## Production milestones
1. Validate import and scene execution in Godot 4.7.2.
2. Replace procedural placeholders with licensed CC0 characters, animations and environment assets.
3. Add combat state machine, hitboxes, enemy telegraphs, lock-on camera and feedback.
4. Build authored levels, checkpoints, save data, settings and accessibility.
5. Profile on the target Android phone and tune draw calls, shadows, resolution and memory.
6. Create a separate PS2SDK codebase with a deliberately reduced PS2 asset budget.
