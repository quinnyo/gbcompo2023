include "common.inc"
include "app/shotctl.inc"
include "core/sprite.inc"
include "gfxmap.inc"


def TeeBallStartX              equ  6 ; new ball start position X offset from tee
def TeeBallStartY              equ  -1 ; new ball start position Y offset from tee
def TeeDefaultFrameDuration    equ   1 ; Display frames per sequence frame
def TeeNewBallDelay            equ  30 ; Initial frame duration for new ball sequence


section "TeeData", rom0

sprite_BallTee:
	SpritePart tBall_A_cy, tBall_A_cx, tBall_A
	SpriteEnd

anim_BallTee:
	db 1
	dw sprite_BallTee

stepPattern_5_2:
	.length_mask: db 3
	;  X, Y
	db 1, 0
	db 2, 1
	db 1, 0
	db 1, 1


section "wTee", wram0

wTee::
	.frame_duration::    db
	.frame_ticks::       db
	.frame::             db
	.origin_x:           db ; origin x position
	.origin_y:           db ; origin y position
	.ball_x:             db ; x position of new ball
	.ball_y:             db ; y position of new ball
	.ball_sprite:        dw ; new ball sprite pointer
	.step_pattern:       dw ; pointer to x/y step pattern


section "TeeImpl", rom0
	ShotPhaseFuncDef new, init
_tee_new_init:
	ret


	ShotPhaseFuncDef new
_tee_new_update:
	ld a, b
	cp ShotPhaseStatus_ENTER
	jr z, _tee_new_enter

	call _tee_ball_step
	jr nz, :+
	ld a, ShotPhaseStatus_NEXT
	ld [wShot_phase_status], a
:
	call _sync_ball
	ret


_tee_new_enter:
	ld hl, wTee.frame_duration
	ld a, TeeDefaultFrameDuration
	ld [hl+], a ; frame_duration
	ld a, TeeNewBallDelay
	ld [hl+], a ; frame_ticks
	xor a
	ld [hl+], a ; frame

	ld hl, wTee.origin_x
	call Ball_get_start_position
	ld a, b
	ld [hl+], a ; origin_x
	ld a, c
	ld [hl+], a ; origin_y
	
	ld hl, wTee.ball_x
	ld a, TeeBallStartX
	ld [hl+], a
	ld a, TeeBallStartY
	ld [hl+], a

	; ball_sprite
	ld bc, sprite_BallTee
	ld a, c
	ld [hl+], a
	ld a, b
	ld [hl+], a

	; step_pattern
	ld bc, stepPattern_5_2
	ld a, c
	ld [hl+], a
	ld a, b
	ld [hl+], a

	ld a, ShotPhaseStatus_OK
	ld [wShot_phase_status], a

	ld de, anim_BallTee
	call Ball_set_anim
	call _sync_ball
	ret


; @return B,C: new ball X,Y
; @return F.Z: set if ball at destination
_tee_ball_step:
	ld hl, wTee.frame_duration
	ld a, [hl+]
	ld d, a
	dec [hl]     ; frame_ticks--
	ret nz
	ld [hl], d   ; frame_ticks = frame_duration
	inc hl
	ld e, [hl]   ; frame
	inc e
	ld [hl], e

	; load ball position into B,C
	ld hl, wTee.ball_x
	ld a, [hl+] ; ball_x
	ld b, a
	ld a, [hl+] ; ball_y
	ld c, a

	; deref step pattern address
	ld hl, wTee.step_pattern
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	; mask frame count to get step pattern index
	ld a, [hl+] ; step pattern length mask
	and e
	add a ; double for stride == 2
	add l
	ld l, a
	adc h
	sub l
	ld h, a

	; step x
	ld a, [hl+]
	and a
	jr z, :+
	ld d, a
	ld a, b
	call _do_step
	ld b, a
:

	; step y
	ld a, [hl+]
	and a
	jr z, :+
	ld d, a
	ld a, c
	call _do_step
	ld c, a
:

	ld hl, wTee.ball_x
	ld a, b
	ld [hl+], a
	ld a, c
	ld [hl+], a

	or b
	ret


; Step towards zero
; @param A: current value
; @param D: step size (unsigned)
; @return A: new value
_do_step:
	and a
	ret z

	cp $80
	jr nc, :+
	; positive
	sub d
	ret nc
	jr .clamp
:	; negative
	add d
	ret nc
.clamp:
	xor a               ; clamp to zero
	ret


; @mut: AF, BC, DE, HL
_sync_ball:
	ld hl, wTee.origin_x
	ld a, [hl+] ; origin_x
	ld b, a
	ld a, [hl+] ; origin_y
	ld c, a

	ld a, [hl+] ; ball_x
	add b
	ld b, a
	ld a, [hl+] ; ball_y
	add c
	ld c, a

	jp Ball_set_screen_position
