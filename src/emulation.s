INCLUDE "include/hardware.inc/hardware.inc"

SECTION "Chip8 Interpreter", ROM0

MainLoop::
    ; check number of transfer ticks done
    ; 0x80 = transfer complete
    ldh a, [hTransferTicksDone]
    cp $80
    jr nc, .skipTransfer

    ; load DE with the source ptr
    sla a
    ld d, HIGH(wChip8VRAM)
    ld e, a

    ; load HL with the destination ptr
    sla a
    ld l, a
    ld a, $00
    adc HIGH(_VRAM8000)
    ld h, a

    ; pre-increment transfer ticks
    ldh a, [hTransferTicksDone]
    inc a
    ldh [hTransferTicksDone], a

    ; wait till hblank is hit
    halt

    ; transfer 2 bytes of data
    ; will take roughly around 16 M-cycles
    ; we have 51 M-cycles at our hand, excluding additional
    ; 20 M-cycles of OAM search period
    call MemCpyTwoBytes

.skipTransfer:
    ld hl, wChip8ProgramCounter
    ld a, [hl+]
    ld b, a
    ld a, [hl+]
    ld c, a

    ld h, b
    ld l, c
    ld a, [hl+]
    ld b, a
    ld a, [hl+]
    ld c, a

    ld a, h
    ld [wChip8ProgramCounter + 0], a
    ld a, l
    ld [wChip8ProgramCounter + 1], a

    ld a, b
    and $F0

    cp $00
    jp z, ChipOp_00E0
    cp $10
    jp z, ChipOp_1NNN
    cp $60
    jp z, ChipOp_6XNN
    cp $70
    jp z, ChipOp_7XNN
    cp $A0
    jp z, ChipOp_ANNN
    cp $D0
    jp z, ChipOp_DXYN

    jp MainLoop

; All instruction handlers assume that BC contains the instruction
SECTION "Chip8 Instructions", ROM0

;;; CLS
ChipOp_00E0:
    ; Zero-fill the shadow VRAM
    ld bc, wChip8VRAMEnd - wChip8VRAM
    ld hl, wChip8VRAM

    call MemZero

    ; Set HBlank Transfer flag
    xor a
    ldh [hTransferTicksDone], a

    jp MainLoop

;;; PC = NNN
ChipOp_1NNN:        
    ; discard top four bits of B, leaving the 0N part in A
    ld a, b
    and $0F
    add HIGH(wChip8RAM)

    ; load the top byte in PC
    ld [wChip8ProgramCounter + 0], a

    ; load the bottom byte in PC
    ; since Chip8 RAM is aligned we don't need to touch the bottom
    ; byte at all
    ld a, c
    ld [wChip8ProgramCounter + 1], a

    jp MainLoop

;;; V[X] = NN
ChipOp_6XNN:
    ; discard top four bits of B, leaving the 0N part in A
    ld a, b
    and $0F

    ; construct ptr to the location
    ld h, HIGH(wChip8GPR)
    ld l, a

    ; load the value in (HL)
    ld [hl], c

    jp MainLoop

;;; V[X] += NN
ChipOp_7XNN:
    ; discard top four bits of B, leaving the 0N part in A
    ld a, b
    and $0F

    ; construct ptr to the location
    ld h, HIGH(wChip8GPR)
    ld l, a

    ; load the (HL) value in A, add NN to it and put it back
    ; we don't care about overflow here at all
    ld a, [hl]
    add c
    ld [hl], a

    jp MainLoop

;;; I = NN
ChipOp_ANNN:
    ; discard top four bits of B, leaving the 0N part in A
    ld a, b
    and $0F
    add HIGH(wChip8RAM)

    ; load the top byte in ID
    ld [wChip8IndexReg + 0], a

    ; load the bottom byte in ID
    ; since Chip8 RAM is aligned we don't need to touch the bottom
    ; byte at all
    ld a, c
    ld [wChip8IndexReg + 1], a

    jp MainLoop

;;;; DXYN
ChipOp_DXYN:
    ; Extract N into its register
    ld a, c
    and $0F
    ldh [hSpriteSize], a

    ; Extract X into B
    ld a, b
    and $0F
    ld h, HIGH(wChip8GPR)
    ld l, a
    ld a, [hl]
    and $3F
    ld b, a

    ; Extract Y into C
    ld a, c
    and $F0
    swap a
    ld l, a
    ld a, [hl]
    and $1F
    ld c, a

    ; Set V[F] to 0
    ld l, $0F
    ld [hl], $00

    ; Setup HL to point to the Chip8 sprite
    ld a, [wChip8IndexReg + 0]
    ld h, a
    ld a, [wChip8IndexReg + 1]
    ld l, a

.forNLoop:
    ; Compute Y effective, essentially it is Y coordinate + N
    inc c

    ; preserve X and Y coordinates
    push bc

    ; load the sprite data into D
    ld a, [hl+]
    ld d, a

    push hl

    ; compute the tile index where we are rendering
    ld a, b
    srl a
    srl a
    srl a
    add c

    ; compute address of the tile we are rendering
    sla a
    sla a
    sla a
    ld l, a
    ld a, $00
    adc HIGH(wChip8VRAM)
    ld h, a

    ; add Y offset
    ld a, c
    and $07
    sla a
    add l
    ld l, a
    ld a, h
    adc $00
    ld h, a


    ld a, [hl]
    xor d
    ld [hl], a

    pop hl

    ; restore X and Y coordinates
    pop bc

    ; decrement N
    ldh a, [hSpriteSize]
    dec a
    ldh [hSpriteSize], a

    ; check if N is zero and jump back if not
    cp $00
    jr nz, .forNLoop

    xor a
    ldh [hTransferTicksDone], a

    jp MainLoop
