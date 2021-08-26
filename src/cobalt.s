INCLUDE "include/hardware.inc/hardware.inc"

SECTION "Header", ROM0[$0100]

Init:
    ; Jump to main ROM code
    nop
    jp Main

    ; Allocate zero-filled space for the ROM header
    ds $0150 - @, 0

SECTION "Main", ROM0

Main:
    ; disable all interrupts for now
    di

    ; setup stack pointer to end of WRAM bank 1
    ld sp, $E000

    ; turn off the audio system
    ld a, AUDENA_OFF
    ldh [rNR52], a

    ; turn off the PPU
    call TurnPpuOff

    ; Copy font to Chip-8 main memory
    ld bc, Chip8FontEnd - Chip8FontStart
    ld de, Chip8FontStart
    ld hl, wChip8RAM

    call MemCpy

    ; Copy ROM to Chip-8 main memory
    ld bc, Chip8RomEnd - Chip8RomStart
    ld de, Chip8RomStart
    ld hl, wChip8RAM + $0200

    call MemCpy

    jr @
