INCLUDE "include/hardware.inc/hardware.inc"

SECTION "ROM Header", ROM0[$0100]

Init:
    ; Jump to main ROM code
    nop
    jp Main

    ; Allocate zero-filled space for the ROM header
    ds $0150 - @, 0

SECTION "Main", ROM0

Main:
    ; Disable all interrupts for now
    di

    ; Setup stack pointer to end of WRAM bank 1
    ld sp, $E000

    ; Turn off the audio system
    ld a, AUDENA_OFF
    ldh [rNR52], a

    ; Turn off the PPU
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

    ; Zero initialize Chip-8 VRAM
    ld bc, wChip8VRAMEnd - wChip8VRAM
    ld hl, wChip8VRAM

    call MemZero

    ; Zero initialize Chip-8 Stack
    ld bc, wChip8StackEnd - wChip8Stack
    ld hl, wChip8Stack

    call MemZero

    ; Zero initialize GB VRAM
    ld bc, $A000 - $8000
    ld hl, $8000

    call MemZero

    ; Copy the tile map to VRAM
    ld bc, TileMapEnd - TileMapStart
    ld de, TileMapStart
    ld hl, _SCRN0

    call MemCpy

    ; Set Chip-8 PC to start of the program ROM
    ld a, HIGH(wChip8RAM) + $02
    ld [wChip8ProgramCounter + 0], a
    xor a
    ld [wChip8ProgramCounter + 1], a

    ; Set stack pointer to 0
    ld a, $00
    ld [wChip8StackPointer], a

    ; Setup background palette
    ld a, %11110011
    ldh [rBGP], a

    ; Setup STAT mode 0 interrupt (HBlank)
    ld a, IEF_STAT
    ldh [rIE], a
    ld a, STATF_MODE00
    ldh [rSTAT], a

    ; Setup LCDC and turn on PPU
    ld a, LCDCF_ON | LCDCF_BG8000 | LCDCF_BGON
    ldh [rLCDC], a

    ; Turn on interrupts to prevent the HALT bug
    ei

    ; Jump to the main loop
    jp MainLoop
