SECTION "Chip8 RAM", WRAM0, ALIGN[8]

; 4 kBs of Chip8 program memory
Chip8RAM::
    ds $1000

SECTION "Chip8 VRAM", WRAM0, ALIGN[8]

; 512 Bs of Chip8 VRAM, enough to hold 8 x 4 tiles
Chip8VRAM::
    ds $0200

SECTION "Chip8 Registers", WRAM0

; 16 General Purpose Registers
ALIGN 8
Chip8GPR::
    ds $0010

; 16 bit Program Counter
Chip8ProgramCounter::
    ds $0002

; 16 bit Index Register
Chip8IndexReg:
    ds $0002
