include "common.inc"


section "wChrTool", wram0
_block:
	.page: db
	.start: db
	.index: db


section "ChrTool", rom0
Chrly_init::
	xor a
	ld b, a
	call Chrly_block_init
	ret


; Set the location of the active block. Resets the block.
; @param A: page
; @param B: start
Chrly_block_init::
	ld [_block.page], a
	ld a, b
	ld [_block.start], a
	ld [_block.index], a
	ret


; Set the block index.
; @param A: index
Chrly_seek::
	ld [_block.index], a
	ret


; Copy CHR data to active block.
; @param DE: source addr
; @param C: count
; @return B: chrid of first copied tile
; @mut: AF, BC, DE, HL
Chrly_load::
	ld a, [_block.index]
	ld b, a
	push bc
	call Chrly_chr_addr

	xor a
	sla c :: rla
	sla c :: rla
	sla c :: rla
	sla c :: rla
	ld b, a
	call vmem_copy

	pop bc ; B,C: _block.index (start of new block), count
	ld a, b
	add c
	ld [_block.index], a
	ret


; Convert CHRID to address in active block
; @param A: chrid
; @return HL: address
; @mut: AF, HL
Chrly_chr_addr::
	ld h, 0
	ld l, a
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl

	ld a, [_block.page]
	and $03
	; Convert page ID to page base address (high byte)
	; %1000_0000  <-  %0000
	; %1000_1000  <-  %0001
	; %1001_0000  <-  %0010
	swap a
	scf
	rra

	add h
	ld h, a
	ret
