SECTION "Interrupt Vectors", ROM0[$0000]

_Vector:
    ; Allocate zero-filled space for the interrupt vectors
    ds $0048, 0

StatVec:
    ; This is to mainly avoid the HALT bug
    reti 

    ; Allocate the rest of the space
    ds $0100 - @, 0
