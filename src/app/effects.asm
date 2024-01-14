include "common.inc"
include "gfxmap.inc"
include "core/sprite.inc"


section "wEffects", wram0
wEffect:
	.timer: db
	.x: db
	.y: db
	.sprite_romb0: db
	.sprite: dw


section "effects manager", rom0
Effects_init::
	ZeroSection "wEffects"
	ret


Effects_update::
	ldh a, [hTick]
	and 7
	jr nz, :+
	ld hl, wEffect
	call Effects_update_flicker_out
:
	ld hl, wEffect
	call Effects_draw_flicker_out
	ret


; @param A: sprite romb0
; @param B,C: X,Y position
; @param DE: sprite parts
Effects_spawn_flicker_out::
	; TODO: get next available effect instance?
	ld [wEffect.sprite_romb0], a
	ld hl, wEffect
	ld a, 8
	ld [hl+], a
	ld a, b
	ld [hl+], a
	ld a, c
	ld [hl+], a
	inc hl ; already wrote romb0
	ld a, e
	ld [hl+], a
	ld a, d
	ld [hl+], a
	ret


; @param HL: effect instance
Effects_update_flicker_out:
	ld a, [hl] ; timer
	and a
	ret z
	dec a
	ld [hl+], a
	ret


; @param HL: effect instance
Effects_draw_flicker_out:
	ld a, [hl+] ; timer
	and a
	ret z
	ldh a, [hTick]
	and 2
	ret z
	ld a, [hl+] ; x
	ld b, a
	ld a, [hl+] ; y
	ld c, a
	PushRomb [hl+] ; sprite_romb0
	ld a, [hl+] ; sprite.0
	ld e, a
	ld a, [hl+] ; sprite.1
	ld d, a
	call oam_next_recall
	call Sprite_draw
	call oam_next_store
	PopRomb
	ret
