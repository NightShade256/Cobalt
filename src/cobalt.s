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

    jr @
