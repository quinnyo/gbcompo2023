include "app/ball.inc"
include "common.inc"
include "maths.inc"
include "gfxmap.inc"
include "core/sprite.inc"


def BALL_DEFAULT_GRAVITY equ 3

; Number of motion/physics substeps per frame
def BALL_MOTION_STEPS equ 2

; default ball aiming X position
def BALL_AIMING_XPOS equ 12
; default ball aiming Y position
def BALL_AIMING_YPOS equ 96

; Impulse to apply to ball to move it away from a wall/slope.
def SlideNudgeX equ 4
; Pretend friction: amount to reduce xvel by during ground contact
def SlideFrictions equ 3

; How long ball must be stationary before considering it 'stopped', in frames.
def StoppedStationaryCount equ 90


/*
*	Ball Graphics
*/

section "Ball_Sprites", romx

sprite_Ball_B_f0:
	SpritePart tBall_B_cy, tBall_B_cx, tBall_B
	db SPRITE_PARTS_END

; Rolling Ballder animated (2x2) sprite
; 16 frames (8 unique, 8 symmetry)
sprite_Ballder_rolling:
	for I, tBallder_rolling_framecount * 2
		def _SRC_FRAME equ I % tBallder_rolling_framecount
		def _OAM_ATTR = 0
		if I >= tBallder_rolling_framecount
			def _OAM_ATTR |= QUARTET_FLIP_BOTH
		endc

		.frame_{X:I}:
			QUARTET tBallder_rolling_q0t{X:_SRC_FRAME}, tBallder_rolling_columns, _OAM_ATTR
			db SPRITE_PARTS_END

		purge _SRC_FRAME, _OAM_ATTR
	endr


/*
AnimSequence {
	frame_count: byte,
	// array of frames -- pointers to SpritesPart
	frames: word[frame_count],
}
*/

def anim_Ballder_rolling_frames equ tBallder_rolling_framecount * 2
anim_Ballder_rolling:
	db anim_Ballder_rolling_frames
	for FRAME, anim_Ballder_rolling_frames
		dw sprite_Ballder_rolling.frame_{X:FRAME}
	endr

anim_Ballder_up:
	db 1
	dw sprite_Ball_B_f0


;*********************************************************************
;* Ball State (WRAM)
;*********************************************************************

section "Ball_State", wram0

	st Ball, wBall

wMotionX: dw
wMotionY: dw

	st BallSprite, wBallSprite


;*********************************************************************
;* Ball Impl (ROM)
;*********************************************************************

section "Ball_Impl", rom0

/*
*	INIT
*	Initialise ball systems
*/
Ball_init::
	; fallthrough

; Reset ball state -- on tee, ready for launch.
Ball_reset::
	ld hl, wBallSprite
	call sprite_init

	ld hl, wBall
	ld bc, Ball_sz
	ld d, 0
	call mem_fill

	ld hl, wBall.status
	ld [hl], fBallStatFreeze

	call Ball_get_start_position
	ld a, b
	ld [wBall.x + 1], a
	ld a, c
	ld [wBall.y + 1], a

	xor a
	ld hl, wMotionX
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a

	ret


/*
*	PROCESS
*	Main update procedure for Ball.
*/
Ball_process::
	call Ball_motion

	; check OOB
	ld a, [wBall.status]
	bit bBallStatOOB, a
	jr nz, .skip_oob
	ld a, [wBall.x + 1]
	ld b, a
	ld a, [wBall.y + 1]
	ld c, a

	; if off screen top, don't check BOTTOM bound
	ld d, SIDEF_LEFT | SIDEF_RIGHT
	bit bBallStatOffScrTop, a
	jr nz, :+
	ld d, SIDEF_LEFT | SIDEF_RIGHT | SIDEF_BOTTOM
:

	call world_point_collide_bounds
	ld a, d
	and e
	jr z, .skip_oob
	ld a, [wBall.status]
	set bBallStatOOB, a
	ld [wBall.status], a
.skip_oob

	ret


; @mut: AF, C, DE, HL
Ball_launch::
	; clear freeze status
	ld hl, wBall.status
	res bBallStatFreeze, [hl]

	; change to 'going up' sprite
	ld de, anim_Ballder_up
	call Ball_set_anim

	ld hl, snd_ball_hit
	call sound_play

	ret


; @param DE: pointer to sprite anim
; @mut: AF, DE, HL
Ball_set_anim::
	ld hl, wBallSprite
	PushRomb bank("Ball_Sprites")
	call sprite_init_anim
	PopRomb
	ret


; Get ball starting position (on the tee)
; @return B,C: tee position X,Y
; @mut: AF, BC
Ball_get_start_position::
	ld a, [wMap.tee_x]
	and a
	jr nz, :+
	ld a, BALL_AIMING_XPOS
:
	inc a
	ld b, a

	ld a, [wMap.tee_y]
	and a
	jr nz, :+
	ld a, BALL_AIMING_YPOS
:
	sub 2
	ld c, a

	ret


; @return B,C: ball's position (X,Y) on screen
; @mut: AF, BC
Ball_get_screen_position::
	ld a, [wBall.x + 1]
	ld b, a
	ld a, [wBall.y + 1]
	ld c, a
	ret


; @param B,C: ball's new position (X,Y) on screen
; @mut: AF, BC
Ball_set_screen_position::
	xor a
	ld [wBall.x + 0], a
	ld [wBall.y + 0], a
	ld a, b
	ld [wBall.x + 1], a
	ld a, c
	ld [wBall.y + 1], a
	ret


/*
*	MOTION
*/

; Check collision with terrain heightmap and update collision status bits.
; @param B,C: pX,pY
; @ret D: CollideTerrain flags
; @mut: A, H, L
collide_terrain:
	ld d, 0
	ld a, b
	call world_get_terrain_column
	sub CollideDownY
	cp c ; colliding = pY > (terrainY - R)
	jr nc, :+
	set bCollideTerrainDown, d
:

	ld a, b
	sub CollideSideX
	call world_get_terrain_column
	sub CollideSideY
	cp c
	jr nc, :+
	set bCollideTerrainLeft, d
:

	ld a, b
	add CollideSideX
	call world_get_terrain_column
	sub CollideSideY
	cp c
	jr nc, :+
	set bCollideTerrainRight, d
:

	ret


; @param E: status flags
;
update_offscreen:
	bit bBallStatOffScrTop, e
	jr z, .onscr
.offscr
	; check if still off screen
	ld a, [wBall.y + 1]
	cp 144
	ret nc ; !(pY < 144)
	res bBallStatOffScrTop, e
	ret
.onscr
	; Check if going off screen top -- going up && !(pY < 144)
	bit bBallStatHeadingY, e
	ret z ; not going up
	ld a, [wBall.y + 1]
	cp 144
	ret c ; pY < 144
	set bBallStatOffScrTop, e
	ret


motion_step:
	ld a, [wBall.status]
	bit bBallStatFreeze, a
	ret nz

	and 255 - fBallStatHeading ; Clear heading X/Y status
	ld e, a

.update_vel_x
	ld hl, wBall + Ball_vx
	ld a, [hl+]
	ld c, a
	ld b, [hl]

	; Side/wall collision velocity adjustments
	ld a, [wBall.collide]
	ld d, a
	; 'nudge' away from colliding wall
	xor a
	bit bCollideTerrainLeft, d
	jr z, :+
	add SlideNudgeX
:
	bit bCollideTerrainRight, d
	jr z, :+
	sub SlideNudgeX
:
	and a
	jr z, :+
	addrrsa bc
:

	; only do drag and move if velocity is non-zero
	ld a, b
	or c
	jr z, .save_vel_x

	; some dodgy drag-like thing
	ld a, b
	subrrsa bc

.accum_motion_x
	ld hl, wMotionX
	ld a, [hl]
	add c
	ld [hl+], a
	ld a, [hl]
	adc b
	ld [hl], a

.save_vel_x
	; update heading X status
	bit 7, b
	jr z, :+
	set bBallStatHeadingX, e
:

	ld hl, wBall + Ball_vx
	ld a, c
	ld [hl+], a
	ld [hl], b


.update_vel_y
	ld hl, wBall + Ball_vy
	ld a, [hl+]
	ld c, a
	ld b, [hl]

	; gravity, if not colliding floor
	bit bCollideTerrainDown, d
	jr nz, .gravity_done

	ld a, BALL_DEFAULT_GRAVITY
	addrrsa bc
.gravity_done

	; only do drag and move if velocity is non-zero
	ld a, b
	or c
	jr z, .save_vel_y

	; some dodgy drag-like thing
	ld a, b
	subrrsa bc

.accum_motion_y
	ld hl, wMotionY
	ld a, [hl]
	add c
	ld [hl+], a
	ld a, [hl]
	adc b
	ld [hl], a

.save_vel_y
	; update heading Y status
	bit 7, b
	jr z, :+
	set bBallStatHeadingY, e
:

	ld hl, wBall + Ball_vy
	ld a, c
	ld [hl+], a
	ld [hl], b


; update 'peaked' status & sprite
	call update_offscreen

	; check Y velocity peaked
	bit bBallStatOffScrTop, e
	jr nz, :+ ; not peaked until on screen

	bit bBallStatPeaked, e
	jr nz, :+ ; already set

	; check Y velocity > 0
	bit 7, b
	jr nz, :+
	ld a, b
	or c
	jr z, :+

	set bBallStatPeaked, e

	; change to 'going down' sprite
	push de
	ld de, anim_Ballder_rolling
	call Ball_set_anim
	ldh a, [hTick] ; "random" initial frame
	ld [wBallSprite.frame], a
	pop de
:

	; store updated status
	ld a, e
	ld [wBall.status], a

	; only collide if ball has peaked
	bit bBallStatPeaked, e
	jr nz, .apply_motion_stepcollide

.apply_motion_nocollide
	; just add velocity to position
	ld hl, wMotionX+1
	ld a, [hl]
	ld [hl], 0
	ld hl, wBall.x+1
	add [hl]
	ld [hl], a

	ld hl, wMotionY+1
	ld a, [hl]
	ld [hl], 0
	ld hl, wBall.y+1
	add [hl]
	ld [hl], a

	ret

.apply_motion_stepcollide
	ld hl, wMotionX+1
	ld d, [hl]
	ld [hl], 0
	ld hl, wMotionY+1
	ld e, [hl]
	ld [hl], 0

	; advance rolling frames if on ground...
	ld a, [wBall.collide]
	bit bCollideTerrainDown, a
	jr z, :+

	ld hl, wBallSprite.frame
	ld a, [hl]
	; TODO: it would be better to use the actual travel distance, as
	;       sometimes the ball spins in place.
	add d ; advance by motion amount ...
	ld [hl], a
:

	ld a, [wBall.x+1]
	ld b, a
	ld a, [wBall.y+1]
	ld c, a

.try_step
	ld a, d
	and a
	jr z, .try_step_y
	bit 7, d
	jr z, .xpos
.xneg ; travelling left
	dec b
	inc d
	ld a, b
	sub CollideSideX
	jr nc, :+ ; if underflow
	ld a, 0
:
	call world_get_terrain_column
	jr nc, .try_step_y ; no collide, continue
	inc b ; revert
	ld d, 0
	jr .try_step_y
.xpos ; travelling right
	inc b
	dec d
	ld a, b
	add CollideSideX
	jr nc, :+ ; if overflow
	ld a, 255
:
	call world_get_terrain_column
	jr nc, .try_step_y ; no collide, continue
	dec b ; revert
	ld d, 0

.try_step_y
	ld a, e
	and a
	jr z, .continue
	bit 7, e
	jr z, .ypos
.yneg ; travelling up
	dec c
	inc e
	ld a, b
	call world_get_terrain_column
	add CollideDownY
	cp c
	jr nc, .continue ; no collide, continue
	inc c ; revert
	ld e, 0
	jr .continue
.ypos ; travelling down
	inc c
	dec e
	ld a, b
	call world_get_terrain_column
	sub CollideDownY
	cp c
	jr nc, .continue ; no collide, continue
	dec c ; revert
	ld e, 0

.continue
	ld a, d
	and a
	jr nz, .try_step
	or e
	jr nz, .try_step_y

.step_commit
	ld a, b
	ld [wBall.x+1], a
	ld a, c
	ld [wBall.y+1], a

.step_done


.collide
	ld a, [wBall.x + 1]
	ld b, a
	ld a, [wBall.y + 1]
	inc a ; must use (pY + 1) as ball should never be below surface from stepped motion
	ld c, a
	call collide_terrain
	ld hl, wBall.collide
	ld a, [hl] ; A = old collide
	ld [hl], d
	; get changed collide bits
	xor d
	and d
	and fCollideTerrainDown
	call nz, _ground_impact

	; handle ground contact
	ld a, [wBall.collide]
	ld d, a
	bit bCollideTerrainDown, d
	jr z, .ground_contact_done
	; sliding "friction"
	ld hl, wBall.vx
	ld a, [hl+]
	ld b, [hl]
	ld c, a
	or b
	jr z, .ground_contact_done ; zero x velocity

	ld a, -SlideFrictions
	bit 7, b
	jr z, :+
	ld a, SlideFrictions
:
	addrrsa bc
	ld a, b
	ld [hl-], a
	ld [hl], c
.ground_contact_done
	ret


; trigger ground impact effects
; @mut: AF, C, DE, HL
_ground_impact:
	ld hl, snd_ball_thump
	call sound_try_play
	ret


; Check if current position is different to last and return updated stationary counter.
; NOTE: does not write to wBall.
; @param B,C: X,Y position (MSB) from previous frame
; @return  E: new stationary counter
; @mut: A
check_stationary:
	ld e, 0
	ld a, [wBall.x + 1]
	cp b
	ret nz
	ld a, [wBall.y + 1]
	cp c
	ret nz

	ld a, [wBall.stationary]
	ld e, a
	cp StoppedStationaryCount
	ret nc
	inc e
	ret


Ball_motion:
	ld a, [wBall.status]
	and fBallStatShotEnded | fBallStatFreeze
	ret nz

	; push MSB position to the stack before moving
	ld a, [wBall.x + 1]
	ld b, a
	ld a, [wBall.y + 1]
	ld c, a
	push bc

rept BALL_MOTION_STEPS
	call motion_step
endr

	; update stationary/motion status
	pop bc
	call check_stationary
	ld a, e
	ld [wBall.stationary], a
	cp StoppedStationaryCount
	jr c, :+
	; Stopped
	ld a, [wBall.status]
	set bBallStatStopped, a
	ld [wBall.status], a

; 	; clear sprite
; 	ld hl, wBallSprite
; 	call sprite_init
; :

	; rolling sound effect thing
	ld a, [wBall.collide]
	bit bCollideTerrainDown, a
	jr z, :+
	ld hl, snd_ball_tick
	call sound_try_play
:

	ret


; Draw main ball sprite
; @mut: AF, BC, DE, HL
Ball_draw::
	PushRomb bank("Ball_Sprites")
	ld hl, wBallSprite
	call sprite_update
	jr z, .end
	call oam_next_recall
	ld a, [wBall.x + 1]
	ld b, a
	ld a, [wBall.y + 1]
	ld c, a
	call Sprite_draw_parts
	call oam_next_store
.end
	PopRomb
	ret


; @param HL: this
; @mut: AF, C, HL
sprite_init:
	xor a
	ld c, BallSprite_sz
	jp mem_fill_byte


; @param HL: this
; @param DE: anim (pointer to anim struct)
; @mut: AF, DE, HL
sprite_init_anim:
	ld a, [de]
	inc de
	ld [hl+], a ; frame_count
	xor a
	ld [hl+], a ; frame
	ld a, e
	ld [hl+], a ; seq.0
	ld a, d
	ld [hl+], a ; seq.1

	ret


; Limit frame number to range of [0..frame_count].
; @param D: frame
; @param E: frame_count
; @ret   A: frame
_sprite_frame_loop_range:
	; (There are probably much better ways to do this.)
	ld a, e
	and a
	ret z ; early out if frame_count == 0

	ld a, d
	cp e
	ret c ; done! (frame < frame_count)

	cp $80
	jr c, .over ; frame < 128, assume overflow occured and SUB
	; frame >= 128, assume underflow, ADD
.under
	cp e
	ret c ; done!
	add e
	jr .under
.over
	cp e
	ret c ; done!
	sub e
	jr .over


; Update sprite to display current frame.
; @param HL: this
; @return DE: current frame sprite parts
; @return F.Z: set if invalid (do not draw)
; @mut: AF, HL, DE
sprite_update:
	ld a, [hl+] ; frame_count
	and a
	ret z

	ld e, a
	ld d, [hl]  ; frame
	call _sprite_frame_loop_range
	ld [hl+], a ; frame

	ld e, [hl]  ; seq.0
	inc hl
	ld d, [hl]  ; seq.1
	inc hl

	; find frame in sequence
	add a ; double A to get 2 byte offset
	jr nc, :+
	inc d
:
	add e
	ld e, a
	adc d
	sub e
	ld d, a

	; read frame, write sprite
	ld a, [de]
	inc de
	ld [hl+], a ; sprite.0
	ld a, [de]
	; inc de
	ld [hl-], a ; sprite.1

	; return DE <== sprite
	ld d, a
	ld e, [hl]
	; return NZ
	or 1
	ret
