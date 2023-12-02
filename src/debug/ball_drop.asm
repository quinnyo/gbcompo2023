IF DEF(DEBUG_MODES)

INCLUDE "common.inc"
INCLUDE "input.inc"


def DBG_VEL equ $9800 + 32 * 16


SECTION "Debug_BallDrop", ROM0
Debug_BallDrop::

.init::
	xor a

	ldh [rSCX], a
	ldh [rSCY], a

	; palettes
	ld a, %11100100
	ldh [rBGP], a
	ldh [rOBP0], a
	ld a, %00011011
	ldh [rOBP1], a

	; clear background map
	xor a
	ld d, a
	ld hl, $9800
	ld bc, BGMAP_LEN
	call mem_fill

	call gfx_load_game_obj

	; init balls
	call BigBall_init
	call WorldCtl_init
	call Ball_init

	; init debug info
	ld hl, DBG_VEL
	ld de, dbgs_vel
	ld bc, dbgs_vel.end - dbgs_vel
	call mem_copy

	ret


.main_iter::
	call Ball_process

	ld a, [wInput.released]
	bit PADB_B, a
	jp nz, $100

	ld a, [wInput.pressed]
	bit PADB_SELECT, a
	call nz, BigBall_init


	ld hl, wBigBall
	call BigBall_update

	ld a, [wBigBallCtl.tick]
	inc a
	ld [wBigBallCtl.tick], a


	; debug info
	ld hl, DBG_VEL + (dbgs_vel.x - dbgs_vel)
	ld a, [wBigBall.vx]
	call hexit_print_byte
	ld a, [wBigBall.vx+1]
	call hexit_print_byte

	ld hl, DBG_VEL + (dbgs_vel.y - dbgs_vel)
	ld a, [wBigBall.vy]
	call hexit_print_byte
	ld a, [wBigBall.vy+1]
	call hexit_print_byte

	call Ball_debug

	ret

/* Debug Strings */

dbgs_vel:
	db "v:"
	.x: db "%%%%"
	db ","
	.y: db "%%%%"
.end


;****************************************************************
; PROTOBALL WORLD
;****************************************************************

section "WorldCtl", rom0
WorldCtl_init:
	ld a, 10
	ld [wWorld.xmin], a
	ld a, 16
	ld [wWorld.ymin], a
	ld a, 158
	ld [wWorld.xmax], a
	ld a, 144
	ld [wWorld.ymax], a
	ret



;****************************************************************
; PROTOBALL
;****************************************************************

INCLUDE "maths.inc"

DEF BALL_TILE EQU 15

SECTION "BigBall", ROM0

BigBall_init:
	xor a
	ld [wBigBallCtl.tick], a
	ld a, 10
	ld [wBigBallCtl.gravity], a

	; init test big ball
	ld hl, wBigBall.vx
	ld de, 1024;320
	ld bc, $0F00
	ld a, d
	ld [hl+], a
	ld a, e
	ld [hl+], a
	ld a, b
	ld [hl+], a
	ld a, c
	ld [hl+], a
	; YYYYYY
	ld de, -768
	ld bc, $7f00
	ld a, d
	ld [hl+], a
	ld a, e
	ld [hl+], a
	ld a, b
	ld [hl+], a
	ld a, c
	ld [hl+], a


	ld a, 10
	ld [wWorld.xmin], a
	ld a, 16
	ld [wWorld.ymin], a
	ld a, 158
	ld [wWorld.xmax], a
	ld a, 144
	ld [wWorld.ymax], a

	ret


BigBall_update:
	; Vel X
	push hl

	ld a, [hl+]
	ld d, a
	ld a, [hl+]
	ld e, a

	call draglike7652

	; Pos X
	ld a, [hl+]
	ld b, a
	ld a, [hl]
	ld c, a
	add16 bc, de

	; check collisions (and correct velocity & position)
	call collision_x
	pop hl
	ld a, d
	ld [hl+], a
	ld a, e
	ld [hl+], a
	ld a, b
	ld [hl+], a
	ld a, c
	ld [hl+], a

	push bc


	; Vel Y
	ld a, [hl+]
	ld d, a
	ld a, [hl+]
	ld e, a

	ld a, [wBigBallCtl.gravity]
	addrrsa de

	call draglike7652

	; Pos Y
	ld a, [hl+]
	ld b, a
	ld a, [hl]
	ld c, a
	add16 bc, de

	; check collisions (and correct velocity & position)
	call collision_y
	ld a, c
	ld [hl-], a
	ld a, b
	ld [hl-], a
	ld a, e
	ld [hl-], a
	ld a, d
	ld [hl], a


; oam
	ld hl, wOAMBuffer

	ld a, b
	ld [hl+], a ; Y
	pop bc
	ld a, b
	ld [hl+], a ; X
	ld a, BALL_TILE
	ld [hl+], a
	ld a, OAMF_PAL0
	ld [hl+], a

	ret


; Apply a weird hacky "drag" effect to 16 bit velocity component in DE
draglike7652:
	ld a, d
	subrrsa de
	ndz de
	ret


collision_x:
	; left
	ld a, [wWorld.xmin]
	; add 8
	cp b
	jr c, .right
	ld b, a ; limit position
	ld c, $FF
	jr .bounce

.right
	ld a, [wWorld.xmax]
	cp b
	ret nc
	ld b, a ; limit position
	ld c, 0

.bounce
	; early out if no velocity
	ld a, d
	cp 0
	ret z

	; flip velocity
	cpl
	inc a
	ld d, a
	ld a, e
	cpl
	ld e, a

	call draglike7652
.done
	ret


collision_y:
	; bottom
	ld a, [wWorld.ymax]
	cp b
	ret nc ; no collision -- bye!.
	ld b, a ; limit position
	ld c, 0

.bounce
	; early out if no velocity
	ld a, d
	cp 0
	jr z, .zero_vel

	; flip velocity
	cpl
	inc a
	ld d, a
	ld a, e
	cpl
	ld e, a

	ret
.zero_vel ; sliding?
	; TODO: reduce X velocity as 'friction'
.done
	ret


SECTION "wBigBall", WRAMX
wBigBallCtl:
.tick: db
.gravity: db

wBigBall:
.vx: dw
.px: dw
.vy: dw
.py: dw

ENDC ; DEBUG_MODES
