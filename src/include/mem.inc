include "hardware.inc"

; Copy bytes from one area to another
; @param de: source
; @param hl: destination
; @param bc: length
mem_copy::
:
	ld a, [de]
	ld [hl+], a
	inc de
	dec bc
	ld a, b
	or a, c
	jr nz, :-
	ret


; Copies and expands a block of bytes, writing each byte twice.
; Can be used to load (2bpp) tile data from a 1bpp source.
; Note that this will write `length * 2` bytes at the destination.
; @param de: source
; @param hl: destination
; @param bc: length (of the source block)
mem_copy_double::
:
	ld a, [de]
	ld [hl+], a
	ld [hl+], a
	inc de
	dec bc
	ld a, b
	or a, c
	jr nz, :-
	ret


; Fill every byte in a block with a single value.
; @warning: If block size is zero, bad things will happen.
; @param  D: value to write to the block
; @param HL: destination start
; @param BC: size of block in bytes
mem_fill::
:
	ld a, d
	ld [hl+], a
	dec bc
	ld a, b
	or a, c
	jr nz, :-
	ret


; Fill every byte in a block with a single value.
; @warning: If block size is zero, bad things will happen.
; @param  A: value to write to the block
; @param HL: destination start
; @param  C: size of block in bytes
mem_fill_byte::
:
	ld [hl+], a
	dec c
	jr nz, :-
	ret


; Fill every byte in a range with a single value.
; @param D: value
; @param HL: start
; @param BC: end (excl)
mem_fill_to::
	jr .cmp
.loop
	ld [hl], d
	inc hl
.cmp
	ld a, h
	cp b
	jr c, .loop
	ld a, l
	cp c
	jr c, .loop

	ret


; VRAM safe mem_copy -- checks for safe VRAM access before every write.
; @param de: source
; @param hl: destination
; @param bc: length
vmem_copy::
:
	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, :-
	ld a, [de]
	ld [hl+], a
	inc de
	dec bc
	ld a, b
	or a, c
	jr nz, :-
	ret


; @param de: source
; @param hl: destination
; @param c: length
vmem_copy_short::
:
	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, :-
	ld a, [de]
	ld [hl+], a
	inc de
	dec c
	jr nz, :-
	ret


; VRAM safe mem_copy_double -- checks for safe VRAM access before every write.
; @param de: source
; @param hl: destination
; @param bc: length (of the source block)
vmem_copy_double::
:
	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, :-
	ld a, [de]
	ld [hl+], a
	ld [hl+], a
	inc de
	dec bc
	ld a, b
	or a, c
	jr nz, :-
	ret


; VRAM safe mem_fill -- checks for safe VRAM access before every write.
; @warning: If block size is zero, bad things will happen.
; @param  D: value to write to the block
; @param HL: destination start
; @param BC: size of block in bytes
vmem_fill::
:
	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, :-
	ld [hl], d
	inc hl
	dec bc
	ld a, b
	or a, c
	jr nz, :-
	ret


; VRAM safe mem_fill_byte -- checks for safe VRAM access before every write.
; @warning: If block size is zero, bad things will happen.
; @param  D: value to write to the block
; @param HL: destination start
; @param  C: size of block in bytes
vmem_fill_byte::
:
	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, :-
	ld [hl], d
	inc hl
	dec c
	jr nz, :-
	ret


; Copy tilemap rect (row-major array) to BG VRAM.
; @param DE: WHERE FROM
; @param HL: WHERE TO
; @param B: WIDTH
; @param C: HEIGHT
vmem_copy_rect::
.loopy
	push bc
.loopx
	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, .loopx
	ld a, [de]
	ld [hl+], a
	inc de
	dec b
	jr nz, .loopx

	pop bc

	; offset from end of row to start of next
	ld a, 32
	sub b
	add l
	ld l, a
	adc h
	sub l
	ld h, a

	dec c
	jr nz, .loopy

	ret
