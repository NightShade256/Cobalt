# Cobalt

Cobalt is a Chip-8 interpreter written in assembly for the Game Boy.

<img src="./README/img/Snake.png" width="300" /> &nbsp;
<img src="./README/img/Corax Test ROM.png" width="300" /> &nbsp;
<img src="./README/img/Breakout.png" width="300" /> &nbsp;
<img src="./README/img/Trip8.png" width="300" /> &nbsp;

## Build Instructions

The `RGBDS` toolchain and `GNU Make` is required to build Cobalt from source.

```bash
make all
```

This will produce the ROM file in the `bin/` subdirectory along with some additional
debugging aids.

The `Snake` ROM from [chip8Archive](https://github.com/JohnEarnest/chip8Archive) (under the CC0 license) is embedded into Cobalt by default, and the key mappings are like so,

| GB    | Chip-8 |
| ----- | ------ |
| Right | 0x9    |
| Left  | 0x7    |
| Up    | 0x5    |
| Down  | 0x8    |

To change the ROM file and key mappings, you need to edit the `src/rom.s` file manually.

## Note

The `Makefile` (with `project.mk`) is adapted from the [GB Boilerplate](https://github.com/ISSOtm/gb-boilerplate/) repository, which is licensed under the Zlib license. A copy of the license may be found in the `README/` subdirectory.

## License

Cobalt is licensed under the terms of the Apache-2.0 license.
