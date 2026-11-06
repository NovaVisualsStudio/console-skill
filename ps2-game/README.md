# Nova Dodge - PS2 homebrew test game

An original PS2 homebrew game created to validate the PS2SDK build path. The output is a PlayStation 2 ELF executable, not an Android APK.

## Try it on Android

1. Install the official **Play!** PS2 emulator using the [official Android downloads page](https://purei.org/downloads.php).
2. Download the latest successful [PS2 Homebrew First Build](https://github.com/NovaVisualsStudio/console-skill/actions/workflows/ps2-homebrew-first-build.yml) artifact named `nova-dodge-ps2-elf`.
3. Extract `nova_dodge.elf` from the ZIP.
4. Try opening the ELF with the Android emulator build. If its interface does not offer ELF loading, consult the [Android test guide](../docs/ANDROID-PS2-TESTING.md); the documented [RetroArch Play! core](https://docs.libretro.com/library/play/) lists ELF as a supported content type.
5. Report the result (boots, black screen, crash, or playable) with a screenshot/log. A successful ELF build alone does not prove runtime compatibility.

Useful official links:
- [Play! Android downloads](https://purei.org/downloads.php)
- [Play! GitHub project](https://github.com/jpd002/Play-)
- [Play! compatibility tracker](https://github.com/jpd002/Play-Compatibility)

## Controls

- D-pad: move the green player block.
- Avoid the falling red blocks.
- Three lives are shown at the top-right.
- The progress bar grows as you survive.
- START: restart after game over.

## Build

From a PS2DEV / PS2SDK environment:

```sh
make
```

Output: `nova_dodge.elf`.

The game uses the PS2SDK graphics, DMA, packet, and controller libraries. It does not include commercial game data, BIOS files, or third-party game assets.
