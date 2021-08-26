INCLUDE "include/hardware.inc/hardware.inc"

SECTION "Chip8 Interpreter", ROM0

MainLoop::
    ; check number of transfer ticks done
    ; 0x80 = transfer complete
    ldh a, [hTransferTicksDone]
    cp $80
    jr z, .skipTransfer

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
    jr MainLoop

; All instruction handlers assume that BC contains the instruction
SECTION "Chip8 Instructions", ROM0

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
