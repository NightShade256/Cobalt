SECTION "Interrupt Vector", ROM0[$0000]

; Allocate zero-filled space for the interrupt vectors.
ds $0048, 0

StatVec:
    reti 

ds $0100 - @, 0
