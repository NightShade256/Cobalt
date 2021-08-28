SECTION "Chip8 RAM", WRAM0, ALIGN[8]

; 4 kB of Chip8 program memory
wChip8RAM::
    ds $1000

SECTION "Chip8 VRAM", WRAM0, ALIGN[8]

; 256 B of Chip8 VRAM, enough to hold bit-packed 8 x 4 tiles
wChip8VRAM::
    ds $0100
wChip8VRAMEnd::

SECTION "Chip8 Registers", WRAM0

; 16 General Purpose Registers
ALIGN 4
wChip8GPR::
    ds $0010

; 16 bit Program Counter
wChip8ProgramCounter::
    ds $0002

; 16 bit Index Register
wChip8IndexReg::
    ds $0002

SECTION "Chip8 Other State", HRAM

; The number of HBlank transfer ticks done.
hTransferTicksDone::
    ds $0001

; The size of sprite we are drawing
hSpriteSize::
    ds $0001
