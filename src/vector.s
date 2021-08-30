SECTION "Interrupt Vectors", ROM0[$0000]

_Vector_0:
    ; Allocate zero-filled space for the interrupt vectors
    ds $0040, 0

SECTION "VBLANK Interrupt Vector", ROM0[$0040]

; Call VBlank Interrupt Handler
VBlankVector:
    call VBlankHandler
    reti

_Vector_1:
    ; Allocate zero-filled space for the interrupt vectors
    ds $0048 - @, 0

SECTION "STAT Interrupt Vector", ROM0[$0048]

; Call STAT Interrupt Handler
StatVector:
    call StatHandler
    reti

_Vector_2:
    ; Allocate zero-filled space for the interrupt vectors
    ds $0100 - @, 0

SECTION "Interrupt Handlers", ROM0

VBlankHandler:
    push af

    ; Zero fill `hInstructionsDone` to signify start of new frame
    xor a
    ldh [hInstructionsDone], a

    ; Decrement sound and delay timers
    ld a, [wChip8DelayTimer]
    and a
    jr z, .skipDelayTimer
    dec a
    ld [wChip8DelayTimer], a

.skipDelayTimer:
    ld a, [wChip8SoundTimer]
    and a
    jr z, .skipSoundTimer
    dec a
    ld [wChip8SoundTimer], a

.skipSoundTimer:
    pop af
    ret

StatHandler:
    ; Preserve register state
    push af
    push de
    push hl

    ; Check number of HBlank transfers done
    ldh a, [hTransferTicksDone]
    cp $80 ; 2
    
    ; If transfer is complete return
    jr nc, .returnFromHandler

    ; Construct pointer to Chip8 VRAM
    sla a
    ld d, HIGH(wChip8VRAM)
    ld e, a

    ; Construct pointer to GB VRAM
    sla a
    ld l, a
    ld a, $00
    adc $80
    ld h, a

    ; Transfer two bytes of data
    REPT 2
        ld a, [de]
        inc de
        ld [hl+], a
        inc hl
    ENDR

    ; Increment the number of transfers done
    ldh a, [hTransferTicksDone]
    inc a
    ldh [hTransferTicksDone], a
    
.returnFromHandler:
    ; Restore register state
    pop hl
    pop de
    pop af
    
    ret
