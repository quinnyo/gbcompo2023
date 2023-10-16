include "core/sprite.inc"

section "sprite impl", rom0

; Draw sprite parts repeatedly until reaching a `SPRITE_PARTS_END`.
; @reg BC: Position (origin) of sprite
; @reg DE(+4): Address of first sprite part
; @reg HL(+4): Destination address -- four byte OAM entry will be written starting here.
sprite_draw_parts::
:
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
	jr :-

	ret