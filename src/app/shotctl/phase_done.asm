include "common.inc"
include "app/shotctl.inc"

section "wShotDone", wram0

wShotDone:
	.duration: db
	.timer: db


section "ShotDone", rom0

	ShotPhaseFuncDef done, init
_shot_done_init:
	ld hl, wShotDone.duration
	ld a, 45
	ld [hl+], a
	ld [hl+], a
	ret


	ShotPhaseFuncDef done
_shot_done_update:
	ld a, b
	cp ShotPhaseStatus_ENTER
	jr z, _shot_done_enter

	ld hl, wShotDone.timer
	dec [hl]
	jr nz, :+
	ld a, ShotPhaseStatus_NEXT
	ld [wShot_phase_status], a
:

	ret


_shot_done_enter:
	ld hl, wShotDone.duration
	ld a, [hl+]
	ld [hl+], a ; timer

	ld a, ShotPhaseStatus_OK
	ld [wShot_phase_status], a

	ret
