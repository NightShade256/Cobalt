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

    ld bc, wChip8VRAMEnd - wChip8VRAM
    ld hl, wChip8VRAM

    call MemZero

    ld bc, $A000 - $8000
    ld hl, $8000

    call MemZero

    ld bc, TileMapEnd - TileMapStart
    ld de, TileMapStart
    ld hl, _SCRN0

    call MemCpy

    ld a, HIGH(wChip8RAM) + $02
    ld [wChip8ProgramCounter + 0], a
    xor a
    ld [wChip8ProgramCounter + 1], a

    ld a, %11110011
    ldh [rBGP], a

    ld a, IEF_STAT
    ldh [rIE], a

    ld a, STATF_MODE00
    ldh [rSTAT], a

    ld a, LCDCF_ON | LCDCF_BG8000 | LCDCF_BG9800 | LCDCF_BGON |LCDCF_OBJOFF
    ldh [rLCDC], a

    ei
    jp MainLoop
