# Nova Airstrike - PS2 homebrew arcade shooter

An original PlayStation 2 homebrew shooter built with PS2SDK. This is a top-down arcade air-combat game, not a commercial game or an Android APK.

## Gameplay

- Fly a detailed, layered fighter aircraft.
- Move with the controller D-pad.
- Fire repeated cannon shots with **CROSS**, **SQUARE**, **CIRCLE**, or **R1**. These common mappings are supported so the on-screen emulator buttons can be tested.
- Destroy incoming enemy aircraft to earn points.
- Avoid enemy aircraft; the player has three lives.
- START restarts after game over.
- The scene includes a scrolling starfield, atmospheric bands, fighter silhouettes, cockpit highlights, exhaust and projectile effects.

## Try it on Android

1. Install the official [Play! Android emulator](https://purei.org/downloads.php).
2. Download the latest successful [PS2 Homebrew build artifact](https://github.com/NovaVisualsStudio/console-skill/actions/workflows/ps2-homebrew-first-build.yml), named `nova-dodge-ps2-elf`.
3. Extract `nova_dodge.elf` from the ZIP.
4. Try opening the ELF with Play!. If Android's Play! interface does not offer ELF loading, consult [the Android PS2 testing guide](../docs/ANDROID-PS2-TESTING.md). The [RetroArch Play! core documentation](https://docs.libretro.com/library/play/) lists ELF as a supported content type, but core availability and runtime compatibility must be checked on the device.
5. Test movement, firing, enemy hits, lives and restart. A successful build does not prove that the game runs correctly on every emulator/device.

## Build

From a PS2DEV / PS2SDK environment:

```sh
make
```

Output: `nova_dodge.elf`.

The game uses PS2SDK graphics, DMA, packet and controller libraries. It contains original code and primitive-drawn artwork; no commercial game data, BIOS files or third-party game assets are included.
