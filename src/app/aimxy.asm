include "common.inc"
include "app/shotctl.inc"
include "gfxmap.inc"


def BallAimStepsX equ 128
def BallAimStepsY equ 96
def BallAimDefaultX equ BallAimStepsX / 2
def BallAimDefaultY equ BallAimStepsY / 2

def BallMinLaunchVelX equ 128 ; Minimum power launch velocity, X axis
def BallMinLaunchVelY equ $FF00 ; Minimum power launch velocity, Y axis


section "aimxy_state", wram0
wAim_X: db
wAim_Y: db


section "aimxy", rom0
_aimxy_init:
	ld a, BallAimDefaultX
	ld [wAim_X], a
	ld a, BallAimDefaultY
	ld [wAim_Y], a

	ret


_aimxy_accept:
	; change to next phase
	ld a, ShotPhaseStatus_NEXT
	ld [wShot_phase_status], a

	ret


_aimxy_enter:
	ld a, ShotPhaseStatus_OK
	ld [wShot_phase_status], a

	ret


; @param B: shot phase status
	ShotPhaseFuncDef aimxy
_aimxy_update:
	ld a, b
	cp ShotPhaseStatus_INIT
	jr z, _aimxy_init

	cp ShotPhaseStatus_ENTER
	jr z, _aimxy_enter

_input:
	ld a, [wInput.pressed]
	; accept
	bit PADB_A, a
	jr nz, _aimxy_accept

	ld b, a
	ld de, 0
	ld hl, $01FE
	call InputXY_read

	ld b, 0
	call _input_held

	ld hl, $02FD
	call InputXY_read

	ld hl, wAim_X
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


_update_ball:
	ld a, [wAim_X]
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

	ld a, [wAim_Y]
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


_aimxy_display:
	call oam_next_recall

	ld a, [wAim_X]
	ld d, a
	ld a, [wAim_Y]
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


; @param B: initial input bitmask (result is combined with this)
; @ret B: input bitmask set for each PADB that has been held for 8 frames
; @mut: A, HL
_input_held:
	ld hl, wInput.hist
for i, 8
	ld a, [hl+]
	cp $FF
	jr nz, :+
	set i, b
:
endr
	ret

