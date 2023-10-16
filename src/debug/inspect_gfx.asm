INCLUDE "common.inc"
INCLUDE "input.inc"


SECTION "Debug_InspectGFX", ROMX
Debug_InspectGFX::

.init::
	xor a

	ldh [rSCX], a
	ldh [rSCY], a

	; palettes
	ld a, %11100100
	ldh [rBGP], a
	ldh [rOBP0], a
	ldh [rOBP1], a

	ld de, BGMap
	ld hl, $9800
	ld bc, BGMap.end - BGMap
	call mem_copy

	call print_tiles

	ret


.main_iter::
	ld a, [wInput.released]
	bit PADB_B, a
	jp nz, $100

	ret


print_tiles:
	ld hl, $9820
	ld b, $80

.line:
	ld a, "$"
	ld [hl+], a

	ld a, b
	swap a
	call hexit_lookup
	ld [hl+], a

	ld a, b
	call hexit_lookup
	ld [hl+], a

	ld a, ":"
	ld [hl+], a

	ld c, $10
:
	ld a, b
	ld [hl+], a
	inc b
	jr z, :+
	dec c
	jr nz, :-
	ld de, 12
	add hl, de
	jr .line
:
	ret
.end


BGMap:
	;  "|---_---|---_---|---^---|---_---"
	db "         inspect_gfx"
.end
