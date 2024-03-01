include "common.inc"
include "core/sprite.inc"


def SPRITE_BUFFER_SIZE equ 256


section "wSprite", wramx, align[8]
; Sprite buffer, aligned for single-byte addressing
wSprites: ds SPRITE_BUFFER_SIZE
; Pointer to the end (excl.) of the sprite buffer (wSprites)
wSprites_end: dw

wBuilder:
	; Address of sprite under construction
	.sprite: dw
	.sprite_end: dw
	.chr_offset: db


section "Sprite", rom0
Sprite_init::
	; fill sprite buffer with sprite terminator
	ld d, SPRITE_PARTS_END
	ld hl, wSprites
	ld bc, SPRITE_BUFFER_SIZE
	call mem_fill

	ld a, low(wSprites)
	ld [wSprites_end + 0], a
	ld a, high(wSprites)
	ld [wSprites_end + 1], a

	ld a, 0
	ld [wBuilder.sprite + 0], a
	ld [wBuilder.sprite + 1], a
	ld [wBuilder.sprite_end + 0], a
	ld [wBuilder.sprite_end + 1], a
	ld [wBuilder.chr_offset], a
	ret


; Draw sprite from sprite buffer.
; @param B,C: X,Y position (sprite origin)
; @param E: Sprite handle
; @mut: AF, DE, HL
Sprite_draw::
	ld d, high(wSprites)

	; FALLTHROUGH

; Draw sprite from somewhere
; @param B,C: Y,X position (sprite origin)
; @param DE: Sprite address
; @mut: AF, DE, HL
Sprite_draw_direct::
	call oam_next_ok
	ret nz
	PushWramb bank(wSprites)
:
	; read command code
	ld a, [de]
	inc de
	call _switch_part_code
	ld a, e
	and d
	cp $FF ; if DE == $FFFF: SPRITE_END
	jr nz, :-
	PopWramb
	ret


_switch_part_code:
	cp SPRITE_END
	jr z, _draw_part_end
	cp SPRITE_PART_OBJ
	jr z, _draw_part_obj

	ld b, b
	rst panic


; @return DE: $FFFF
; @mut: DE
_draw_part_end:
	ld de, $FFFF
	ret


; @param B,C: Y,X position (sprite origin)
; @param DE: Address of sprite part data
; @return DE: address of next part
; @mut: AF, DE, HL
_draw_part_obj:
	ld hl, wOAM_end
	ld a, [hl+]
	ld h, [hl]
	ld l, a

	ld a, [de] ; Y
	inc de
	add b
	ld [hl+], a
	ld a, [de] ; X
	inc de
	add c
	ld [hl+], a
	ld a, [de] ; TILE
	inc de
	ld [hl+], a
	ld a, [de] ; ATTR
	inc de
	ld [hl+], a

	ld a, l
	ld [wOAM_end + 0], a
	ld a, h
	ld [wOAM_end + 1], a
	ret


; Draw sprite parts repeatedly until reaching a `SPRITE_PARTS_END`.
; @param B,C: X,Y position (sprite origin)
; @param DE: Address of first sprite part
; @param HL: Destination address -- OAM entries will be written starting here.
; @mut: AF, DE, HL
Sprite_draw_parts::
:
	call _draw_sprite_obj
	jr nz, :-
	ret


; Draw a single sprite part.
; @param B,C: X,Y position (sprite origin)
; @param DE: Address of sprite part
; @param HL: Destination address -- OAM entry will be written here.
; @return F.Z: set if reached SPRITE_PARTS_END
; @mut: AF, DE, HL
_draw_sprite_obj:
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


section "SpriteBuilder", rom0
; Set the offset to be applied to any CHR passed to builder.
; @param B: offset
; @mut: AF
SpriteBuilder_chr_offset::
	PushWramb bank("wSprite")
	ld a, b
	ld [wBuilder.chr_offset], a
	PopWramb
	ret


; Start building a new sprite.
; @mut: AF, DE, HL
SpriteBuilder_begin::
	PushWramb bank("wSprite")
	; new sprite starts at sprite buffer end
	ld a, [wSprites_end + 0]
	ld e, a
	ld a, [wSprites_end + 1]
	ld d, a
	ld hl, wBuilder.sprite
	ld a, e
	ld [hl+], a ; sprite.0
	ld a, d
	ld [hl+], a ; sprite.1
	ld a, e
	ld [hl+], a ; sprite_end.0
	ld a, d
	ld [hl+], a ; sprite_end.1
	PopWramb
	ret


; Finalise the sprite being built.
; @return E: Sprite handle
; @mut: AF, DE, HL
SpriteBuilder_end::
	PushWramb bank("wSprite")
	ld a, [wBuilder.sprite_end + 0]
	ld l, a
	ld a, [wBuilder.sprite_end + 1]
	ld h, a

	; add sprite terminator
	ld a, SPRITE_END
	ld [hl+], a

	; update sprite buffer
	ld a, l
	ld [wSprites_end + 0], a
	ld a, h
	ld [wSprites_end + 1], a

	; return sprite address & reset builder
	ld hl, wBuilder.sprite
	ld a, $FF
	ld e, [hl]
	ld [hl+], a ; sprite.0
	ld d, [hl]
	ld [hl+], a ; sprite.1
	ld [hl+], a ; sprite_end.0
	ld [hl+], a ; sprite_end.1

	ld a, [wBuilder.sprite + 0]
	ld l, a
	ld a, [wBuilder.sprite + 1]
	ld h, a
	PopWramb
	ret


; Add an obj to the current sprite.
; @param B,C: Y,X position
; @param D: CHRID local to active CHR source
; @param E: obj attributes
SpriteBuilder_add_obj::
	PushWramb bank("wSprite")
	ld a, [wBuilder.sprite_end + 0]
	ld l, a
	ld a, [wBuilder.sprite_end + 1]
	ld h, a

	ld a, SPRITE_PART_OBJ
	ld [hl+], a
	ld a, b
	ld [hl+], a
	ld a, c
	ld [hl+], a
	ld a, [wBuilder.chr_offset]
	add d
	ld [hl+], a
	ld a, e
	ld [hl+], a

	ld a, l
	ld [wBuilder.sprite_end + 0], a
	ld a, h
	ld [wBuilder.sprite_end + 1], a
	PopWramb
	ret


; Add an obj to the current sprite, read from memory.
; @param DE: source addr
; @mut: AF, B, DE, HL
SpriteBuilder_add_obj_mem::
	PushWramb bank("wSprite")
	ld a, [wBuilder.sprite_end + 0]
	ld l, a
	ld a, [wBuilder.sprite_end + 1]
	ld h, a

	ld a, SPRITE_PART_OBJ
	ld [hl+], a
	ld a, [de] :: inc de
	ld [hl+], a ; Y
	ld a, [de] :: inc de
	ld [hl+], a ; X
	ld a, [wBuilder.chr_offset]
	ld b, a
	ld a, [de] :: inc de
	add b
	ld [hl+], a ; CHR
	ld a, [de] :: inc de
	ld [hl+], a ; ATTR

	ld a, l
	ld [wBuilder.sprite_end + 0], a
	ld a, h
	ld [wBuilder.sprite_end + 1], a
	PopWramb
	ret


; Append a byte to the (under construction) sprite.
; @param B: value
SpriteBuilder_add_byte:
	PushWramb bank("wSprite")
	ld a, [wBuilder.sprite_end + 0]
	ld l, a
	ld a, [wBuilder.sprite_end + 1]
	ld h, a

	ld a, b
	ld [hl+], a

	ld a, l
	ld [wBuilder.sprite_end + 0], a
	ld a, h
	ld [wBuilder.sprite_end + 1], a
	PopWramb
	ret
