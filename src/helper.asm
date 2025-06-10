INCLUDE "hardware.inc"
    rev_Check_hardware_inc 4.12

SECTION "Helpers", ROM0

; Copy memory the size of BC from DE to HL.
MemCpy::
    ld a, [de]
    inc de
    ld [hl+], a
    dec bc
    ld a, b
    or c
    jr nz, MemCpy
    ret

; Set memory the size of BC to the value E, at the location HL.
MemSet::
    ld a, e
    ld [hl+], a
    dec bc
    ld a, b
    or c
    jr nz, MemSet
    ret

; Set memory the size of BC to the value 0, at the location HL.
; Same as MemSet but doesn't require the use of register E.
MemZero::
    xor a
    ld [hl+], a
    dec bc
    ld a, b
    or c
    jr nz, MemZero
    ret

; Copy exactly 2 bytes of memory from DE to HL but skipping every other
; HL byte.
MemCpyTwoBytes::
    REPT 2
        ld a, [de]
        inc de
        ld [hl+], a
        inc hl
    ENDR
    
    ret

; Turn the PPU off. Waits for VBlank before disabling LCDC.
; If the PPU is already off returns.
TurnPpuOff::
    ldh a, [rLCDC]
    and LCDCF_ON
    ret z

.waitForVBlank
    ldh a, [rLY]
    cp $90
    jr c, .waitForVBlank

    ld a, $00
    ldh [rLCDC], a
    ret
