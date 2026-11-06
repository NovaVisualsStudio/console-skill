# Nova Dodge — PS2 homebrew test game

An original, small PS2 game created to validate the PS2SDK build path and provide a first playable test on an Android PS2 emulator.

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
