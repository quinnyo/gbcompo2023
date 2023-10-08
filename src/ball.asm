include "ball.inc"
include "defines.asm"
include "maths.inc"
include "gfxmap.inc"


; jrlez R, N
; JR to N if (signed 16 bit) value in R is less than or equal to zero.
macro jrlez
	bit 7, HIGH(\1)
	jr nz, \2
	ld a, HIGH(\1)
	or LOW(\1)
	jr z, \2
endm


def BALL_DEFAULT_GRAVITY equ 2

; Number of motion/physics substeps per frame
def BALL_MOTION_STEPS equ 2

; default ball aiming X position
def BALL_AIMING_XPOS equ 12
; default ball aiming Y position
def BALL_AIMING_YPOS equ 96

def MAX_SHOTS equ 99

; Impulse to apply to ball to move it away from a wall/slope.
def SlideNudgeX equ 2

; How long ball must be stationary before considering it 'stopped', in frames.
def StoppedStationaryCount equ $80

def bInputAimUp equ PADB_UP
def bInputAimDown equ PADB_DOWN
def bInputAimLeft equ PADB_LEFT
def bInputAimRight equ PADB_RIGHT
def bInputMod equ PADB_SELECT
def bInputAccept equ PADB_A

/*
	Collision Point Status
	bits for wBall.collide
*/

def bCollideTerrainLeft   equ 2 ; colliding with the heightmap at the Left collide point
def bCollideTerrainDown   equ 1 ; colliding with the heightmap at the Down collide point
def bCollideTerrainRight  equ 0 ; colliding with the heightmap at the Right collide point
def fCollideTerrainLeft   equ 1 << bCollideTerrainLeft
def fCollideTerrainDown   equ 1 << bCollideTerrainDown
def fCollideTerrainRight  equ 1 << bCollideTerrainRight

def CollidePointsCount equ 3

def CollideDownY equ 6 ; Y offset for Down-Centre collision point
def CollideSideX equ 6 ; X offset for Down-Side (L/R) collision points
def CollideSideY equ 5 ; Y offset for Down-Side (L/R) collision points

/*
*	Ball Graphics
*/

section "Ball_Sprites", romx

; SpritePart YCENTRE, XCENTRE, TILE_ID, OAM_ATTR
; Y-, X- CENTRE is the location of the origin *in the tile*:
; 	The tile will be moved such that its point (Y, X) will be at the origin.
; 	e.g. `4, 4` will display the tile centered at the object's position.
macro SpritePart
	db OAM_Y_OFS - (\1), OAM_X_OFS - (\2), (\3), (\4)
endm

def SPRITE_PARTS_END equ $80

sprite_Ball_A_f0:
	SpritePart tBall_A_cy, tBall_A_cx, tBall_A, OAMF_PAL0
	db SPRITE_PARTS_END

sprite_Ball_B_f0:
	SpritePart tBall_B_cy, tBall_B_cx, tBall_B, OAMF_PAL0
	db SPRITE_PARTS_END

sprite_Ball_C_f0:
	SpritePart tBall_C0_cy, tBall_C0_cx, tBall_C0, OAMF_PAL0
	SpritePart tBall_C1_cy, tBall_C1_cx, tBall_C1, OAMF_PAL0
	SpritePart tBall_C2_cy, tBall_C2_cx, tBall_C2, OAMF_PAL0
	SpritePart tBall_C3_cy, tBall_C3_cx, tBall_C3, OAMF_PAL0
	db SPRITE_PARTS_END

sprite_Ball_D_f0:
	SpritePart tBall_C0_cy - 3, tBall_C0_cx + 3, tBall_C0, OAMF_PAL0
	SpritePart tBall_C1_cy - 5, tBall_C1_cx - 2, tBall_C1, OAMF_PAL0
	SpritePart tBall_C2_cy - 2, tBall_C2_cx + 1, tBall_C2, OAMF_PAL0
	SpritePart tBall_C3_cy - 4, tBall_C3_cx - 1, tBall_C3, OAMF_PAL0
	db SPRITE_PARTS_END

;*********************************************************************
;* Ball State (WRAM)
;*********************************************************************

section "Ball_State", wram0

	st Ball, wBall

wShot::
	.count:: db

	st Aim, wAim

;*********************************************************************
;* Ball Data (ROM)
;*********************************************************************

section "Ball_Data", romx


BallDefault:
	.mode: db fBallModeAiming | fBallModeTransIn
	.status: db 0
	.collide: db 0
	.shot: db 0
	.stationary: db 0
	.x: dw BALL_AIMING_XPOS
	.y: dw BALL_AIMING_YPOS
	.vx: dw 0
	.vy: dw 0
	.sprite: dw sprite_Ball_A_f0
.end

assert (BallDefault.end - BallDefault) == Ball_sz


;*********************************************************************
;* Ball Impl (ROM)
;*********************************************************************

section "Ball_Impl", rom0

/*
*	INIT
*	Initialise ball systems
*/
Ball_init::
	xor a
	ld [wShot.count], a

	ld a, BallAimDefaultX
	ld [wAim.x], a
	ld a, BallAimDefaultY
	ld [wAim.y], a

; Reset ball (to tee) and start aiming next shot.
Ball_reset::
	ld de, BallDefault
	ld bc, Ball_sz
	ld hl, wBall
	call mem_copy

	; load aiming (tee) position from map
	ld a, [wMap.tee_x]
	ld b, a
	ld a, [wMap.tee_y]
	ld c, a
	; Assume map tee of (0,0) is unset... Only use map tee if it's not (0,0)
	or b
	jr z, :+
	ld a, b
	ld [wBall.x + 1], a
	ld a, c
	ld [wBall.y + 1], a
:

	ld a, [wShot.count]
	ld [wBall.shot], a

	ret


/*
*	PROCESS
*	Main update procedure for Ball.
*/
Ball_process::
	call .mode_process

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


.mode_process:
	; overall mode switch
	ld a, [wBall.mode]
	bit bBallModeMotion, a
	jr z, :+
	bit bBallModeTransIn, a
	jp nz, mode_motion_in
	bit bBallModeTransOut, a
	jp nz, mode_motion_out
	jp mode_motion
:
	bit bBallModeAiming, a
	jr z, :+
	bit bBallModeTransIn, a
	jp nz, mode_aiming_in
	bit bBallModeTransOut, a
	jp nz, mode_aiming_out
	jp mode_aiming
:
	jp mode_none


/*
*	MODE: AIMING
*/
mode_aiming:
	call aiming_input

	; Aiming done/accepted, don't do another update
	ld a, [wBall.mode]
	bit bBallModeTransOut, a
	ret nz

	call aiming_update
	call aiming_display

	ret


aiming_update:
	ld a, [wAim.x]
	ld e, a
	ld d, 0
	sla e
	rl d
	ld hl, BallMinLaunchVelX
	add hl, de
	ld a, h
	ld [wBall.vx + 1], a
	ld a, l
	ld [wBall.vx], a

	ld a, [wAim.y]
	cpl
	ld e, a
	ld d, $FF
	sla e
	rl d
	ld hl, BallMinLaunchVelY + 1
	add hl, de
	ld a, h
	ld [wBall.vy + 1], a
	ld a, l
	ld [wBall.vy], a


aiming_display:
	call oam_next_recall

	call draw_ball

	ld a, [wAim.x]
	ld d, a
	ld a, [wAim.y]
	ld e, a
	ld a, [wBall.x + 1]
	add OAM_X_OFS - 4
	ld b, a
	ld a, [wBall.y + 1]
	add OAM_Y_OFS - 4
	ld c, a

for i, 3
	ld a, c
	sub e
	ld [hl+], a
	ld a, b
	add d
	ld [hl+], a
	ld a, tShapes_Ring4 - i
	ld [hl+], a
	xor a
	ld [hl+], a

	srl d
	srl e
endr

	call oam_next_store

	ret


conclude_aiming:
	ld a, [wShot.count]
	cp MAX_SHOTS
	jr nc, :+
	inc a
	ld [wShot.count], a
:

	; Move to 'out' sequence
	ld a, [wBall.mode]
	set bBallModeTransOut, a
	ld [wBall.mode], a

	ret


; @param B: initial input bitmask (result is combined with this)
; @ret B: input bitmask set for each PADB that has been held for 8 frames
; @mut: A, HL
input_the_held:
	ld hl, wInput.hist
for i, 8
	ld a, [hl+]
	cp $FF
	jr nz, :+
	set i, b
:
endr
	ret


aiming_input:
	ld a, [wInput.pressed]
	; accept
	bit bInputAccept, a
	jr nz, conclude_aiming

	ld b, a
	ld de, 0
	ld hl, $01FE
	call InputXY_read

	ld b, 0
	call input_the_held

	ld hl, $02FD
	call InputXY_read

	ld hl, wAim.x
	ld a, [hl]
	add d
	cp BallAimStepsX
	jr c, .apply_x
.clamp_x:
	bit 7, d
	jr z, :+
	xor a
	jr .apply_x
:
	ld a, BallAimStepsX
.apply_x
	ld [hl+], a

	ld a, [hl]
	add e
	cp BallAimStepsY
	jr c, .apply_y
.clamp_y:
	bit 7, e
	jr z, :+
	xor a
	jr .apply_y
:
	ld a, BallAimStepsY
.apply_y
	ld [hl+], a

	ret


mode_aiming_in:
	; TODO: EVERYTHING
	; TODO: UPDATE/AWAIT ANIMATIONS

	; 'in' sequence complete, move to aiming mode proper.
	ld a, [wBall.mode]
	res bBallModeTransIn, a
	ld [wBall.mode], a

	ret

mode_aiming_out:
	; TODO: EVERYTHING
	; TODO: UPDATE/AWAIT ANIMATIONS

	; 'out' sequence complete, move to motion mode.
	ld a, fBallModeMotion | fBallModeTransIn
	ld [wBall.mode], a

	ret


/*
*	MODE: MOTION
*/

; Check collision with terrain heightmap and update collision status bits.
; @ret D: CollideTerrain flags
; @mut: A, B, C, H, L
collide_terrain:
	ld d, 0
	ld a, [wBall.x + 1]
	ld b, a
	ld a, [wBall.y + 1]
	ld c, a
	call world_get_terrain_column
	ld a, [hl]
	sub CollideDownY
	cp c ; colliding = pY > (terrainY - R)
	jr nc, :+
	set bCollideTerrainDown, d
:

	ld a, b
	sub CollideSideX
	ld b, a
	call world_get_terrain_column
	ld a, [hl]
	sub CollideSideY
	cp c
	jr nc, :+
	set bCollideTerrainLeft, d
:

	ld a, b
	add CollideSideX * 2
	ld b, a
	call world_get_terrain_column
	ld a, [hl]
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

.update_pos_x
	ld hl, wBall + Ball_x
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

.update_pos_y
	ld hl, wBall + Ball_y
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
.update_peaked
	call update_offscreen

	; check Y velocity peaked
	bit bBallStatOffScrTop, e
	jr nz, :+ ; not peaked until on screen
	jrlez bc, :+
	; positive Y velocity
	bit bBallStatPeaked, e
	jr nz, :+ ; already set
	set bBallStatPeaked, e

	; change to 'going down' sprite
	ld a, LOW(sprite_Ball_C_f0)
	ld [wBall.sprite], a
	ld a, HIGH(sprite_Ball_C_f0)
	ld [wBall.sprite + 1], a
:

	; only collide if ball has peaked
	bit bBallStatPeaked, e
	jr z, .no_collide

.collide
	call collide_terrain

	ld a, d
	ld [wBall.collide], a

	; slow down if colliding terrain
	bit bCollideTerrainDown, d
	jr z, :+
	ld a, [wBall.vy + 1]
	sra a
	ld [wBall.vy + 1], a
	ld a, [wBall.vy]
	rra
	ld [wBall.vy], a

	; "friction"
	ld a, [wBall.vx + 1]
	sra a
	ld [wBall.vx + 1], a
	ld a, [wBall.vx]
	rra
	ld [wBall.vx], a
:

.no_collide

.done
	; store updated status
	ld a, e
	ld [wBall.status], a
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


mode_motion:
	ld a, [wBall.status]
	and fBallStatShotEnded
	jr nz, mode_motion_draw

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
	set bBallStatFreeze, a
	set bBallStatStopped, a
	ld [wBall.status], a

	; change to 'broken' sprite
	ld a, LOW(sprite_Ball_D_f0)
	ld [wBall.sprite], a
	ld a, HIGH(sprite_Ball_D_f0)
	ld [wBall.sprite + 1], a
:

	jr mode_motion_draw


mode_motion_draw:
	call oam_next_recall
	call draw_ball
	call oam_next_store

	ret


mode_motion_in:
	; TODO: this

	; move to motion proper
	ld a, [wBall.mode]
	res bBallModeTransIn, a
	ld [wBall.mode], a

	; change to 'going up' sprite
	ld a, LOW(sprite_Ball_B_f0)
	ld [wBall.sprite], a
	ld a, HIGH(sprite_Ball_B_f0)
	ld [wBall.sprite + 1], a

	ret


mode_motion_out:
	; TODO: When does this actually happen, anyway?
	; TODO: EVERYTHING

	ret


/*
*	MODE: NONE (FALLBACK)
*/
mode_none:
	ld a, [wBall.mode]
	res bBallModeTransIn, a
	res bBallModeTransOut, a
	ld [wBall.mode], a

	ret


; HL: OAM buffer address
draw_ball:
	ld a, [wBall.x + 1]
	ld b, a
	ld a, [wBall.y + 1]
	ld c, a

	ld a, [wBall.sprite]
	ld e, a
	ld a, [wBall.sprite + 1]
	ld d, a
	jp draw_parts


Ball_debug::
	ret


; Draw sprite parts (one tile) from a SpriteDef.
; Sprite part should be 4 bytes: { Y, X, TILE, OAM_ATTRS }
; Will draw parts until encountering SPRITE_PARTS_END in place of a Y value.
; @reg BC: Position (origin) of sprite
; @reg DE(+4): Address of first sprite part
; @reg HL(+4): Destination address -- four byte OAM entry will be written starting here.
draw_parts:
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


if def(DEBUG_BALL)

def DBGTXT_LEN_XY equ 9 ; 'XX YY &SS'
def DBGTXT_LEN_COLLIDE equ CollidePointsCount
def DBGTXT_LEN_VEL equ 9 ; 'XXxx YYyy'

def DBGTXT_POS equ $9C00
def DBGTXT_POS_XY equ DBGTXT_POS
def DBGTXT_POS_COLLIDE equ DBGTXT_POS_XY + DBGTXT_LEN_XY + 1
def DBGTXT_POS_VEL equ DBGTXT_POS + 32
def DBGTXT_POS_VX equ DBGTXT_POS_VEL

def DBGTXT_WIDTH equ DBGTXT_LEN_XY + 1 + DBGTXT_LEN_COLLIDE
def DBGTXT_HEIGHT equ 2


Ball_dbg_init::
	ld hl, wDbg
	ld c, wDbg.end - wDbg
	xor a
	call mem_fill_byte

	ret


Ball_dbg_update::
	ld a, [wInput.state]
	bit PADB_SELECT, a
	jr z, :+
	ld hl, wBall.vx
	xor a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	call Ball_dbg_move
	ld a, 1
	ld [wDbg.active], a
:
	ld a, [wDbg.active]
	and a
	ret z
	call Ball_dbg_txt
	ret


Ball_dbg_txt:
	; XX YY
	ld hl, wDbg.xy_str
	ld a, [wBall.x]
	call hexit_print_byte
	inc hl
	ld a, [wBall.y]
	call hexit_print_byte
	inc hl
	ld a, "&"
	ld [hl+], a
	ld a, [wBall.stationary]
	call hexit_print_byte

	; collision status bits string
	ld hl, wDbg.collide_str
	ld a, [wBall.collide]
	ld d, a
	ld b, "-"
	ld c, "#"
for i, CollidePointsCount
	ld a, b
	bit (CollidePointsCount - 1 - i), d
	jr z, :+
	ld a, c
:
	ld [hl+], a
endr

	; vel
	ld hl, wDbg.vel_str
	ld a, [wBall.vx]
	call hexit_print_byte
	ld a, [wBall.vxs]
	call hexit_print_byte
	inc hl
	ld a, [wBall.vy]
	call hexit_print_byte
	ld a, [wBall.vys]
	call hexit_print_byte

	; copy text and show window
	ld hl, DBGTXT_POS_XY
	ld de, wDbg.xy_str
	ld bc, DBGTXT_LEN_XY
	call vmem_copy

	ld a, [wBall.mode]
	bit bBallModeMotion, a
	jr z, :+
	ld a, " "
	WaitVRAM
	ld [hl+], a
	ld hl, DBGTXT_POS_COLLIDE
	ld de, wDbg.collide_str
	ld bc, DBGTXT_LEN_COLLIDE
	call vmem_copy

	ld hl, DBGTXT_POS_VEL
	ld de, wDbg.vel_str
	ld bc, DBGTXT_LEN_VEL
	call vmem_copy

	ld a, 166 - 8 * DBGTXT_WIDTH
	ldh [rWX], a
	ld a, 144 - 8 * DBGTXT_HEIGHT
	ldh [rWY], a
	ret
:

	ld a, 166 - 8 * DBGTXT_LEN_XY
	ldh [rWX], a
	ld a, 144 - 8
	ldh [rWY], a
	ret


Ball_dbg_move:

	/*
		PRESSED: inc/dec by 1
		HELD: inc/dec every frame AFTER N FRAMES
	*/

	ld a, [wInput.pressed]
	ld b, a

	ld a, [wInput.hist + PADB_DOWN]
	cp $FF
	jr nz, :+
	set PADB_DOWN, b
	jr :++ ; skip UP if DOWN
:

	ld a, [wInput.hist + PADB_UP]
	cp $FF
	jr nz, :+
	set PADB_UP, b
:

	ld a, [wInput.hist + PADB_RIGHT]
	cp $FF
	jr nz, :+
	set PADB_RIGHT, b
	jr :++ ; skip LEFT if RIGHT
:

	ld a, [wInput.hist + PADB_LEFT]
	cp $FF
	jr nz, :+
	set PADB_LEFT, b
:

	ld e, 0
	bit PADB_DOWN, b
	jr z, .padup
	inc e
	jr .apply_y
.padup
	bit PADB_UP, b
	jr z, .padright
	dec e
.apply_y
	ld a, [wBall.y]
	add e
	ld [wBall.y], a

.padright
	ld d, 0
	bit PADB_RIGHT, b
	jr z, .padleft
	inc d
	jr .apply_x
.padleft
	bit PADB_LEFT, b
	ret z
	dec d
.apply_x
	ld a, [wBall.x]
	add d
	ld [wBall.x], a

	ret


section "BallDebugState", wram0

wDbg:
	.xy_str: ds DBGTXT_LEN_XY
	.collide_str: ds DBGTXT_LEN_COLLIDE
	.vel_str: ds DBGTXT_LEN_VEL
	.active: db
.end

endc
