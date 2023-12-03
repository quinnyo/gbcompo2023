include "common.inc"
include "gfxmap.inc"
include "core/sprite.inc"


section "effects manager", rom0

sprite_BallStopped:
	SpritePart tBall_C0_cy - 3, tBall_C0_cx + 3, tBall_C0, OAMF_PRI
	SpritePart tBall_C1_cy - 5, tBall_C1_cx - 2, tBall_C1, OAMF_PRI
	SpritePart tBall_C2_cy - 2, tBall_C2_cx + 1, tBall_C2, OAMF_PRI
	SpritePart tBall_C3_cy - 4, tBall_C3_cx - 1, tBall_C3, OAMF_PRI
	db SPRITE_PARTS_END


; Draw 'stopped' ball sprite at given position
; @param B,C: X,Y position
Effects_draw_ball_stopped::
	call oam_next_recall
	ld de, sprite_BallStopped
	call sprite_draw_parts
	call oam_next_store
	ret
