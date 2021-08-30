# Cobalt

A work-in-progress Chip-8 interpreter written for the Game Boy.

<img src="./README/IBM Logo.png" width="300" /> &nbsp;
<img src="./README/Corax Test ROM.png" width="300" /> &nbsp;

## Build Instructions

Cobalt requires the `RGBDS` toolchain and `GNU Make` to be present.

```bash
make all
```

This will produce the ROM file in the `bin/` subdirectory along with some additional
debugging aids.

## ToDo

- `EX9E`, `EXA1` and `FX0A` instructions
- Sprite collision detection in DXYN
- Audio

## Note

The `Makefile` is adapted from the [GB Boilerplate](https://github.com/ISSOtm/gb-boilerplate/) repository, which is under the MIT license. A copy of the license may be found in the `README/` subdirectory.

## License

Cobalt is licensed under the terms of the Apache-2.0 license.
