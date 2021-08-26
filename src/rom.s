SECTION "Chip8 ROM", ROM0

Chip8RomStart::
    INCBIN "roms/IBM_Logo.ch8"
Chip8RomEnd::

SECTION "Chip8 Font", ROM0

Chip8FontStart::
    db $F0, $90, $90, $90, $F0, ; 0
    db $20, $60, $20, $20, $70, ; 1
    db $F0, $10, $F0, $80, $F0, ; 2
    db $F0, $10, $F0, $10, $F0, ; 3
    db $90, $90, $F0, $10, $10, ; 4
    db $F0, $80, $F0, $10, $F0, ; 5
    db $F0, $80, $F0, $90, $F0, ; 6
    db $F0, $10, $20, $40, $40, ; 7
    db $F0, $90, $F0, $90, $F0, ; 8
    db $F0, $90, $F0, $10, $F0, ; 9
    db $F0, $90, $F0, $90, $90, ; A
    db $E0, $90, $E0, $90, $E0, ; B
    db $F0, $80, $80, $80, $F0, ; C
    db $E0, $90, $90, $90, $E0, ; D
    db $F0, $80, $F0, $80, $F0, ; E
    db $F0, $80, $F0, $80, $80, ; F
Chip8FontEnd::
