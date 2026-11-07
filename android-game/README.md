# NOVA — Ancient Warrior (Android prototype)

This is the first Godot 4 vertical-slice scaffold for an original third-person mythic action game. It is separate from the PS2SDK homebrew target under `ps2-game/`.

## Current prototype scope

- Procedural low-poly arena and original primitive character/enemy models.
- Third-person follow camera.
- Keyboard movement for desktop smoke tests.
- Touchscreen directional controls, attack, dodge and guard buttons.
- Melee hit detection, enemy pursuit, health, two grunts and one boss-scale enemy.
- Mobile-friendly Compatibility renderer baseline.

This is a playable mechanics prototype, not a finished commercial game. Replace primitive meshes with properly licensed original art, add authored animation sets, sound, checkpoints, save data, level streaming and boss phases before calling it a full game.

## Run

Open this folder in Godot 4.4 or newer and press Play. For desktop testing use WASD, then click/tap HIT, DODGE and GUARD. On Android, use the on-screen controls in landscape orientation.

## Android export

Install the matching Godot export templates and configure Android SDK + OpenJDK 17 in Editor Settings. Export a debug APK first. Keep release signing keys out of Git. See the [official Godot Android export guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html).

## Performance target

Start with a stable 30 FPS on low-end Android, then target 60 FPS on stronger devices. Use Compatibility rendering, simple materials, baked/static lighting where practical, limited real-time shadows, pooled effects and compressed textures. Benchmark on the actual phone; editor FPS is not a mobile benchmark.

## Licences

All scripts in this prototype are original project code. Any later third-party model, animation, texture, music or sound must be checked against its individual licence and recorded in an asset manifest before shipping.
