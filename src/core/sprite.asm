include "core/sprite.inc"

section "Sprite", rom0
; Draw sprite parts repeatedly until reaching a `SPRITE_PARTS_END`.
; @param B,C: X,Y position (sprite origin)
; @param DE: Address of first sprite part
; @param HL: Destination address -- OAM entries will be written starting here.
Sprite_draw::
:
	call SpritePart_draw
	jr nz, :-
	ret


; Draw a single sprite part.
; @param B,C: X,Y position (sprite origin)
; @param DE: Address of sprite part
; @param HL: Destination address -- OAM entry will be written here.
; @return F.Z: set if reached SPRITE_PARTS_END
SpritePart_draw::
	ld a, [de] ; Y
	cp SPRITE_PARTS_END
	ret z
	inc de
	add c
	ld [hl+], a
	ld a, [de] ; X
	inc de
	add b
	ld [hl+], a
	ld a, [de] ; TILE
	inc de
	ld [hl+], a
	ld a, [de] ; ATTR
	inc de
	ld [hl+], a
	or 1
	ret
