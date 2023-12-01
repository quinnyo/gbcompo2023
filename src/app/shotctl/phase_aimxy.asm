include "common.inc"
include "app/shotctl.inc"
include "gfxmap.inc"


def AimStepsX equ 160
def AimStepsY equ 96
def AimMinX equ 0
def AimMaxX equ AimMinX + AimStepsX
def AimMinY equ 5
def AimMaxY equ AimMinY + AimStepsY
def AimDefaultX equ AimStepsX / 2
def AimDefaultY equ AimStepsY / 2
def BaseLaunchVelX equ 128 ; Minimum power launch velocity, X axis
def BaseLaunchVelY equ $FF00 ; Minimum power launch velocity, Y axis


section "aimxy_state", wram0
wAim_X: db
wAim_Y: db


section "aimxy", rom0
_aimxy_init:
	ld a, AimDefaultX
	ld [wAim_X], a
	ld a, AimDefaultY
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

	ld a, [wInput.pressed]
	; accept
	bit PADB_A, a
	jr nz, _aimxy_accept

	call _aimxy_input
	call _aimxy_configure_shot
	call _aimxy_display

	ret


; process XY input
; @param A: pressed input mask
; @mut: AF, BC, DE, HL
_aimxy_input:
	ld b, a

	ld hl, wAim_X
	ld a, [hl+]
	ld d, a
	ld a, [hl]
	cpl
	inc a
	ld e, a
	ld hl, $0101
	call InputXY_read

	ld b, 0
	call _input_held

	ld hl, $0202
	call InputXY_read

	ld a, e
	cpl
	inc a
	ld e, a

	ld hl, wAim_X
	ld a, d
	ld bc, AimMaxX | (AimMinX << 8)
	call _clamp
	ld [hl+], a
	ld bc, AimMaxY | (AimMinY << 8)
	ld a, e
	call _clamp
	ld [hl], a
	ret


_aimxy_configure_shot:
	ld hl, wAim_Y
	ld a, [hl-]
	cpl
	inc a
	ld c, a

	ld e, [hl] ; wAim_X
	ld d, 0
	ld hl, BaseLaunchVelX
	add hl, de
	add hl, de
	ld d, h
	ld a, l
	ld hl, wShotCfg_vx
	ld [hl+], a
	ld [hl], d

	ld e, c
	ld d, $FF
	ld hl, BaseLaunchVelY + 1
	add hl, de
	add hl, de
	ld d, h
	ld a, l
	ld hl, wShotCfg_vy
	ld [hl+], a
	ld [hl], d

	ret


_aimxy_display:
	ld hl, wAim_Y
	ld a, [hl-]
	cpl
	inc a
	ld e, a
	ld d, [hl] ; wAim_X

	call Ball_get_start_position
	ld a, OAM_X_OFS - 4
	add b
	ld b, a
	ld a, OAM_Y_OFS - 4
	add c
	ld c, a
	call oam_next_recall


for i, 3
	ld a, c
	add e
	ld [hl+], a
	ld a, b
	add d
	ld [hl+], a
	ld a, tShapes_Ring7 - i * 2
	ld [hl+], a
	xor a
	ld [hl+], a

	srl d
	sra e
endr

	call oam_next_store

	ret


; clamp to range
_clamp:
	cp b
	jr nc, .min_ok
	ld a, b
	ret
.min_ok
	cp c
	ret c
	ld a, c
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

