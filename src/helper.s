;;; Copy memory the size of BC from DE to HL.
MemCpy::
    ld a, [de]
    inc de
    ld [hl+], a
    dec bc
    ld a, b
    or c
    jr nz, MemCpy
    ret

;;; Set memory the size of BC to the value E, at the location HL.
MemSet::
    ld a, e
    ld [hl+], a
    dec bc
    ld a, b
    or c
    jr nz, MemSet
    ret

;;; Set memory the size of BC to the value 0, at the location HL.
;;; Same as MemSet but doesn't require the use of register E.
MemZero::
    xor a
    ld [hl+], a
    dec bc
    ld a, b
    or c
    jr nz, MemZero
    ret
