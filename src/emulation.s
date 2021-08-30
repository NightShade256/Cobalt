INCLUDE "include/hardware.inc/hardware.inc"

SECTION "Chip8 Main Loop", ROM0

MainLoop::
    ; Check if instruction count for current frame is complete, and if yes
    ; wait for VBlank
    ldh a, [hInstructionsDone]
    cp $0A
    jr nc, .haltUntilVBlank
    inc a
    ldh [hInstructionsDone], a

    ; Load BC with the Chip-8 instruction
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

    ; Pre-increment the Chip-8 PC
    ld a, h
    ld [wChip8ProgramCounter + 0], a
    ld a, l
    ld [wChip8ProgramCounter + 1], a

    ; Load address of the main jump table into HL
    ld hl, MainJumpTable
    
    ; Multiply top nibble by two, add to `L`
    ld a, b
    and $F0
    swap a
    sla a
    add l
    ld l, a

    ; Read the address of the handler
    ld a, [hl+]
    ld d, a
    ld a, [hl+]
    ld e, a
    
    ; Little Endian - so reverse the order
    ld h, e
    ld l, d

    ; Jump to the handler
    jp hl

.haltUntilVBlank
    ; Halt till HBlank or VBlank is hit
    halt

    ; Check if it was VBlank, if not halt again
    ldh a, [rLY]
    cp $90
    jr c, .haltUntilVBlank

    ; Jump to main loop
    jp MainLoop


SECTION "Chip8 Instruction Jump Table", ROM0

ALIGN 4
MainJumpTable:
    dw ChipOp_0Top
    dw ChipOp_1NNN
    dw ChipOp_2NNN
    dw ChipOp_3XNN
    dw ChipOp_4XNN
    dw ChipOp_5XY0
    dw ChipOp_6XNN
    dw ChipOp_7XNN
    dw ChipOp_8Top
    dw ChipOp_9XY0
    dw ChipOp_ANNN
    dw ChipOp_BNNN
    dw ChipOp_Undefined
    dw ChipOp_DXYN
    dw ChipOp_Undefined
    dw ChipOp_FTop

ALIGN 4
ArithmeticJumpTable:
    dw ChipOp_8XY0
    dw ChipOp_8XY1
    dw ChipOp_8XY2
    dw ChipOp_8XY3
    dw ChipOp_8XY4
    dw ChipOp_8XY5
    dw ChipOp_8XY6
    dw ChipOp_8XY7
    dw ChipOp_Undefined
    dw ChipOp_Undefined
    dw ChipOp_Undefined
    dw ChipOp_Undefined
    dw ChipOp_Undefined
    dw ChipOp_Undefined
    dw ChipOp_8XYE
    dw ChipOp_Undefined

SECTION "Chip8 Instructions", ROM0

; $XXXX - Undefined Instruction
ChipOp_Undefined:
    jp MainLoop

ChipOp_0Top:
    ld a, c

    cp $E0
    jp z, ChipOp_00E0
    cp $EE
    jp z, ChipOp_00EE

    jp MainLoop

ChipOp_8Top:
    ; Load address of the arithmetic jump table into HL
    ld hl, ArithmeticJumpTable
    
    ; Multiply top nibble by two, add to `L`
    ld a, c
    and $0F
    sla a
    add l
    ld l, a

    ; Read the address of the handler
    ld a, [hl+]
    ld d, a
    ld a, [hl+]
    ld e, a
    
    ; Little Endian - so reverse the order
    ld h, e
    ld l, d

    ; Jump to the handler
    jp hl

ChipOp_FTop:
    ld a, c

    cp $07
    jp z, ChipOp_FX07

    jp MainLoop

; $00E0 - Clear the screen.
ChipOp_00E0:
    ; Zero-fill the shadow VRAM
    ld bc, wChip8VRAMEnd - wChip8VRAM
    ld hl, wChip8VRAM

    call MemZero

    ; Set HBlank Transfer flag
    xor a
    ldh [hTransferTicksDone], a

    jp MainLoop

; $00EE - Return from a subroutine.
ChipOp_00EE:
    ; Subtract 1 from the stack pointer
    ld a, [wChip8StackPointer]
    dec a
    ld [wChip8StackPointer], a

    ; Pop a word off the stack and assign it to PC
    sla a
    ld h, HIGH(wChip8Stack)
    ld l, a

    ld a, [hl+]
    ld [wChip8ProgramCounter + 0], a
    ld a, [hl+]
    ld [wChip8ProgramCounter + 1], a

    jp MainLoop

; $1NNN - Jump to address `NNN`.
ChipOp_1NNN:        
    ; Discard top four bits of B, leaving the 0N part in A
    ; and then add the Chip-8 RAM address offset
    ld a, b
    and $0F
    add HIGH(wChip8RAM)

    ; Load the top byte in PC
    ld [wChip8ProgramCounter + 0], a

    ; Load the bottom byte in PC
    ; Since Chip8 RAM is aligned we don't need to touch the bottom
    ; byte at all
    ld a, c
    ld [wChip8ProgramCounter + 1], a

    jp MainLoop

; $2NNN - Execute subroutine starting at address `NNN`.
ChipOp_2NNN:
    ; Discard top four bits of B and leave NNN in BC
    ld a, b
    and $0F
    add HIGH(wChip8RAM)
    ld b, a

    ; Load the stack pointer to A, pre-inc it and put it back
    ld a, [wChip8StackPointer]
    inc a
    ld [wChip8StackPointer], a
    dec a

    ; Construct pointer to the stack
    sla a
    ld h, HIGH(wChip8Stack)
    ld l, a

    ; Push PC onto the stack
    ld a, [wChip8ProgramCounter + 0]
    ld [hl+], a
    ld a, [wChip8ProgramCounter + 1]
    ld [hl+], a

    ; Jump to NNN
    ld a, b
    ld [wChip8ProgramCounter + 0], a
    ld a, c
    ld [wChip8ProgramCounter + 1], a

    jp MainLoop

; $3XNN - Skip the following instruction if the value of register `VX` equals `NN`.
ChipOp_3XNN:
    ; Discard top four bits of B, leaving the 0N part in A
    ld a, b
    and $0F

    ; Construct pointer to the register location
    ld h, HIGH(wChip8GPR)
    ld l, a

    ; Load the value of the register in A
    ld a, [hl]

    ; Skip the next instruction if A == C
    cp c
    jr nz, .dontSkipInstruction_3X

    ; Load PC into HL
    ld a, [wChip8ProgramCounter + 0]
    ld h, a
    ld a, [wChip8ProgramCounter + 1]
    ld l, a

    ; Add two to HL
    inc hl
    inc hl

    ; Write-back HL into PC
    ld a, h
    ld [wChip8ProgramCounter + 0], a
    ld a, l
    ld [wChip8ProgramCounter + 1], a

.dontSkipInstruction_3X
    jp MainLoop

; $4XNN - Skip the following instruction if the value of register `VX` is not equal to `NN`.
ChipOp_4XNN:
    ; Discard top four bits of B, leaving the 0N part in A
    ld a, b
    and $0F

    ; Construct pointer to the register location
    ld h, HIGH(wChip8GPR)
    ld l, a

    ; Load the value of the register in A
    ld a, [hl]

    ; Skip the next instruction if A != C
    cp c
    jr z, .dontSkipInstruction_4X

    ; Load PC into HL
    ld a, [wChip8ProgramCounter + 0]
    ld h, a
    ld a, [wChip8ProgramCounter + 1]
    ld l, a

    ; Add two to HL
    inc hl
    inc hl

    ; Write-back HL into PC
    ld a, h
    ld [wChip8ProgramCounter + 0], a
    ld a, l
    ld [wChip8ProgramCounter + 1], a

.dontSkipInstruction_4X
    jp MainLoop

; $5XY0 - Skip the following instruction if the value of register `VX` is equal to the value of register `VY`.
ChipOp_5XY0:
    ; Discard top four bits of B, leaving the 0X part in A
    ld a, b
    and $0F

    ; Construct pointer to the register location X
    ld h, HIGH(wChip8GPR)
    ld l, a

    ; Load the value of the register in B
    ld b, [hl]

    ; Construct pointer to the register location Y
    ld a, c
    and $F0
    swap a
    ld l, a

    ; Load the value of the register in A
    ld a, [hl]

    ; Skip the next instruction if A == B
    cp b
    jr nz, .dontSkipInstruction_5X

    ; Load PC into HL
    ld a, [wChip8ProgramCounter + 0]
    ld h, a
    ld a, [wChip8ProgramCounter + 1]
    ld l, a

    ; Add two to HL
    inc hl
    inc hl

    ; Write-back HL into PC
    ld a, h
    ld [wChip8ProgramCounter + 0], a
    ld a, l
    ld [wChip8ProgramCounter + 1], a

.dontSkipInstruction_5X
    jp MainLoop

; $6XNN - Store number `NN` in register `VX`.
ChipOp_6XNN:
    ; Discard top four bits of B, leaving the 0N part in A
    ld a, b
    and $0F

    ; Construct pointer to the register location
    ld h, HIGH(wChip8GPR)
    ld l, a

    ; Load the value in the register
    ld [hl], c

    jp MainLoop

; $7XNN - Add the value `NN` to register `VX`.
ChipOp_7XNN:
    ; Discard top four bits of B, leaving the 0X part in A
    ld a, b
    and $0F

    ; Construct pointer to the register location
    ld h, HIGH(wChip8GPR)
    ld l, a

    ; Load the value in A, add NN to it and put it back
    ; We don't care about overflow here at all
    ld a, [hl]
    add c
    ld [hl], a

    jp MainLoop

; $8XY0 - Store the value of register `VY` in register `VX`.
ChipOp_8XY0:
    ; Discard bottom four bits of C, leaving the Y0 part in A
    ld a, c
    and $F0
    swap a

    ; Construct pointer to the register location Y
    ld h, HIGH(wChip8GPR)
    ld l, a

    ; Load the value of the register in C
    ld c, [hl]

    ; Construct pointer to the register location X
    ld a, b
    and $0F
    ld l, a

    ; Load the value C into [HL]
    ld [hl], c

    jp MainLoop

; $8XY1 - Set `VX` to `VX` OR `VY`.
ChipOp_8XY1:
    ; Discard bottom four bits of C, leaving the Y0 part in A
    ld a, c
    and $F0
    swap a

    ; Construct pointer to the register location Y
    ld h, HIGH(wChip8GPR)
    ld l, a

    ; Load the value of the register in C
    ld c, [hl]

    ; Construct pointer to the register location X
    ld a, b
    and $0F
    ld l, a

    ; Load the value X into register A
    ld a, [hl]

    ; Peform X OR Y
    or c

    ; Store X back into memory
    ld [hl], a

    jp MainLoop

; $8XY2 - Set `VX` to `VX` AND `VY`.
ChipOp_8XY2:
    ; Discard bottom four bits of C, leaving the Y0 part in A
    ld a, c
    and $F0
    swap a

    ; Construct pointer to the register location Y
    ld h, HIGH(wChip8GPR)
    ld l, a

    ; Load the value of the register in C
    ld c, [hl]

    ; Construct pointer to the register location X
    ld a, b
    and $0F
    ld l, a

    ; Load the value X into register A
    ld a, [hl]

    ; Peform X AND Y
    and c

    ; Store X back into memory
    ld [hl], a

    jp MainLoop

; $8XY3 - Set `VX` to `VX` XOR `VY`.
ChipOp_8XY3:
    ; Discard bottom four bits of C, leaving the Y0 part in A
    ld a, c
    and $F0
    swap a

    ; Construct pointer to the register location Y
    ld h, HIGH(wChip8GPR)
    ld l, a

    ; Load the value of the register in C
    ld c, [hl]

    ; Construct pointer to the register location X
    ld a, b
    and $0F
    ld l, a

    ; Load the value X into register A
    ld a, [hl]

    ; Peform X XOR Y
    xor c

    ; Store X back into memory
    ld [hl], a

    jp MainLoop

; $8XY4 - Add the value of register `VY` to register `VX`.
; Set `VF` to 01 if a carry occurs
; Set `VF` to 00 if a carry does not occur
ChipOp_8XY4:
    ; Discard bottom four bits of C, leaving the Y0 part in A
    ld a, c
    and $F0
    swap a

    ; Construct pointer to the register location Y
    ld h, HIGH(wChip8GPR)
    ld l, a

    ; Load the value of the register in C
    ld c, [hl]

    ; Construct pointer to the register location X
    ld a, b
    and $0F
    ld l, a

    ; Load the value of the register in A
    ld a, [hl]

    ; Add the values together
    add c

    ; Store X back into memory
    ld [hl], a

    ; If carry occurs set VF to 1
    jr nc, .noCarry_Y4
    ld l, $0F
    ld [hl], $01

.noCarry_Y4
    jp MainLoop

; $8XY5 - Subtract the value of register `VY` from register `VX`.
; Set `VF` to 00 if a borrow occurs
; Set `VF` to 01 if a borrow does not occur
ChipOp_8XY5:
    ; Discard bottom four bits of C, leaving the Y0 part in A
    ld a, c
    and $F0
    swap a

    ; Construct pointer to the register location Y
    ld h, HIGH(wChip8GPR)
    ld l, a

    ; Load the value of the register in C
    ld c, [hl]

    ; Construct pointer to the register location X
    ld a, b
    and $0F
    ld l, a

    ; Load the value of the register in A
    ld a, [hl]

    ; Subtract the values
    sub c

    ; Store X back into memory
    ld [hl], a

    ; If carry does not occur set VF to 1
    jr c, .yesCarry_Y5
    ld l, $0F
    ld [hl], $01

.yesCarry_Y5
    jp MainLoop

; $8XY6 - Store the value of register `VY` shifted right one bit in register `VX`.
; Set register `VF` to the least significant bit prior to the shift
; `VY` is unchanged
ChipOp_8XY6:
    ; Discard top four bits of C, leaving the Y0 part in A
    ld a, c
    and $F0
    swap a

    ; Construct pointer to the register location
    ld h, HIGH(wChip8GPR)
    ld l, a

    ; Load value of the register in E
    ld e, [hl]

    ; Construct pointer to V[X]
    ld a, b
    and $0F
    ld l, a

    ; Shift right E by 1 bit
    srl e

    ; Store the value back into V[X]
    ld [hl], e

    ; Set V[F] to the least significant bit before shift
    jr nc, .lsbIsZero_Y6
    ld l, $0F
    ld [hl], $01

.lsbIsZero_Y6
    jp MainLoop

; $8XY7 - Set register VX to the value of `VY` minus `VX`.
; Set `VF` to 00 if a borrow occurs
; Set `VF` to 01 if a borrow does not occur
ChipOp_8XY7:
    ; Discard bottom four bits of C, leaving the Y0 part in A
    ld a, c
    and $F0
    swap a

    ; Construct pointer to the register location Y
    ld h, HIGH(wChip8GPR)
    ld l, a

    ; Load the value of the register in C
    ld c, [hl]

    ; Construct pointer to the register location X
    ld a, b
    and $0F
    ld l, a

    ; Load the value of the register in A
    ld b, [hl]

    ; Subtract the values
    ld a, c
    sub b

    ; Store X back into memory
    ld [hl], a

    ; If carry does not occur set VF to 1
    jr c, .yesCarry_Y7
    ld l, $0F
    ld [hl], $01

.yesCarry_Y7
    jp MainLoop

; $8XYE - Store the value of register `VY` shifted left one bit in register `VX`.
; Set register `VF` to the most significant bit prior to the shift
; `VY` is unchanged
ChipOp_8XYE:
    ; Discard top four bits of C, leaving the Y0 part in A
    ld a, c
    and $F0
    swap a

    ; Construct pointer to the register location
    ld h, HIGH(wChip8GPR)
    ld l, a

    ; Load value of the register in E
    ld e, [hl]

    ; Construct pointer to V[X]
    ld a, b
    and $0F
    ld l, a

    ; Shift right E by 1 bit
    sla e

    ; Store the value back into V[X]
    ld [hl], e

    ; Set V[F] to the least significant bit before shift
    jr nc, .msbIsZero_YE
    ld l, $0F
    ld [hl], $01

.msbIsZero_YE
    jp MainLoop

; $9XY0 - Skip the following instruction if the value of register `VX` is not equal to the value of register `VY`.
ChipOp_9XY0:
    ; Discard top four bits of B, leaving the 0X part in A
    ld a, b
    and $0F

    ; Construct pointer to the register location X
    ld h, HIGH(wChip8GPR)
    ld l, a

    ; Load the value of the register in B
    ld b, [hl]

    ; Construct pointer to the register location Y
    ld a, c
    and $F0
    swap a
    ld l, a

    ; Load the value of the register in A
    ld a, [hl]

    ; Skip the next instruction if A != B
    cp b
    jr z, .dontSkipInstruction_9X

    ; Load PC into HL
    ld a, [wChip8ProgramCounter + 0]
    ld h, a
    ld a, [wChip8ProgramCounter + 1]
    ld l, a

    ; Add two to HL
    inc hl
    inc hl

    ; Write-back HL into PC
    ld a, h
    ld [wChip8ProgramCounter + 0], a
    ld a, l
    ld [wChip8ProgramCounter + 1], a

.dontSkipInstruction_9X
    jp MainLoop

; $ANNN - Store memory address `NNN` in register `I`.
ChipOp_ANNN:
    ; Discard top four bits of B, leaving the 0N part in A
    ld a, b
    and $0F
    add HIGH(wChip8RAM)

    ; Load the top byte in ID
    ld [wChip8IndexReg + 0], a

    ; Load the bottom byte in ID
    ; Since Chip8 RAM is aligned we don't need to touch the bottom
    ; byte at all
    ld a, c
    ld [wChip8IndexReg + 1], a

    jp MainLoop

; $BNNN - Jump to address `NNN` + `V0`.
ChipOp_BNNN:
    ; Discard top four bits of B, leaving NNN in B
    ld a, b
    and $0F
    ld b, a

    ; Construct pointer to V0
    ld hl, wChip8GPR

    ; Load value of V0 in A
    ld a, [hl]

    ; Add A to the address stored in BC
    add c
    ld c, a
    ld a, $00
    adc b
    ld b, a

    ; Set PC to BC
    ld a, b
    ld [wChip8ProgramCounter + 0], a
    ld a, c
    ld [wChip8ProgramCounter + 1], a

    jp MainLoop

; $ DXYN - Draw a sprite at position `VX`, `VY` with `N` bytes of sprite data,
; starting at the address stored in `I`.
; Set `VF` to `01` if any set pixels are changed to unset, and `00` otherwise.
ChipOp_DXYN:
    ; Extract N into the sprite size register
    ld a, c
    and $0F
    ldh [hSpriteSize], a

    ; Extract X coordinate into the B register and perform
    ; X mod 64
    ld a, b
    and $0F
    ld h, HIGH(wChip8GPR)
    ld l, a
    ld a, [hl]
    and $3F
    ld b, a

    ; Extract Y coordinate into the C register and perform
    ; Y mod 32
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
    ; Preserve the X and Y coordinates
    push bc

    ; Load the sprite data into D register
    ld a, [hl+]
    ld d, a

    ; Preserve the sprite pointer
    push hl

    ; Compute the index of the tile where the coordinates lie
    ; Formula: Tile Index = (X / 8) + (Y & !(7))
    ld a, b

    REPT 3
        srl a
    ENDR

    ld e, c

    REPT 3
        srl c
    ENDR

    REPT 3
        sla c
    ENDR

    add c
    ld c, e

    ; Compute the address of the tile
    REPT 3
        sla a
    ENDR
    
    ld l, a
    ld a, $00
    adc HIGH(wChip8VRAM)
    ld h, a

    ; Add the Y offset to the address
    ld a, c
    and $07
    add l
    ld l, a
    ld a, h
    adc $00
    ld h, a

    ; Check if the X coordinate is aligned to 8 pixel boundary
    ; if no, render the case specially
    ld a, b
    and $07
    jr z, .noNextTile
    ld c, $00

.yesNextTile:
    ; Shift sprite data to the right by (X mod 8) and put the
    ; bytes that are shifted back into the C register
    srl d
    rr c
    dec a
    jr nz, .yesNextTile

    ; Load the byte from VRAM, XOR sprite data and then put it back
    ld a, [hl]
    xor d
    ld [hl], a

    ; The rest of the data is to be XORed to the same row but of the *next* tile
    ; Each tile is 8 bytes long, so we can just add 8 to the current tile address
    ; and get the next tile address
    ld a, l
    add $08
    ld l, a
    ld a, $00
    adc h
    ld h, a

    ; Load the byte from VRAM, XOR sprite data and then put it back
    ld a, [hl]
    xor c
    ld [hl], a

    ; Do not execute the non-special case and jump to the loop
    ; condition check directly
    jr .isDone

.noNextTile:
    ; Just load the VRAM byte into A, XOR sprite data and then put the
    ; result back in
    ld a, [hl]
    xor d
    ld [hl], a

.isDone:
    ; Restore the sprite data pointer
    pop hl

    ; Restore the original X and Y coordinate
    pop bc

    ; Increment the Y coordinate in sync with the for N loop
    inc c

    ; Decrement N
    ldh a, [hSpriteSize]
    dec a
    ldh [hSpriteSize], a

    ; Check if N is zero and jump back if not
    cp $00
    jr nz, .forNLoop

    ; Set HBlank transfer flag
    xor a
    ldh [hTransferTicksDone], a

    jp MainLoop

ChipOp_FX07:
    ; Discard top four bits of B leaving 0X in A
    ld a, b
    and $F0

    ; Construct pointer to register location
    ld h, HIGH(wChip8GPR)
    ld l, a

    ; Read the value of the delay timer
    ld a, [wChip8DelayTimer]

    ; Store the value in VX
    ld [hl], a

    jp MainLoop
