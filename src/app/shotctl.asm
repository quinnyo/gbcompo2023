include "common.inc"
include "app/shotctl.inc"


section "wShot", wram0

wShot_phase:: db
wShot_phase_status:: db


section "shotctl", rom0

shotctl_init::
	ld a, ShotPhaseStatus_INIT
	ld [wShot_phase_status], a

for I, ShotPhase__COUNT
	ld b, ShotPhaseStatus_INIT
	call shot_phase_{ShotPhase__KEY{u:I}}_update
endr

	ret


shotctl_start_next_shot::
	xor a
	call shotctl_phase_change

	ret


shotctl_update::
	ld a, [wShot_phase_status]
	ld b, a
	ld a, [wShot_phase]

	call _phase_update

	; handle phase status code
	ld a, [wShot_phase_status]
	cp ShotPhaseStatus_NEXT
	jr z, shotctl_phase_next
	cp ShotPhaseStatus_BACK
	jr z, shotctl_phase_back

	ret


; @param A: phase
; @param B: phase status
_phase_update:
	cp ShotPhase__COUNT
	jr nc, _error_bad_phase
	sla a
	rst jump_switch
for I, ShotPhase__COUNT
	dw shot_phase_{ShotPhase__KEY{u:I}}_update
endr

_error_bad_phase:
	ld b, b
	ret


; @mut: AF
shotctl_phase_next::
	ld a, [wShot_phase]
	inc a
	jr shotctl_phase_change


; @mut: AF
shotctl_phase_back::
	ld a, [wShot_phase]
	dec a
	jr shotctl_phase_change


; @param A: phase
; @mut: AF
shotctl_phase_change::
	ld [wShot_phase], a
	ld a, ShotPhaseStatus_ENTER
	ld [wShot_phase_status], a

	ret


	ShotPhaseFuncDef swing
_shotctl_dummy_update:
	ld a, b
	cp ShotPhaseStatus_INIT
	ret z
	ld a, ShotPhaseStatus_NEXT
	ld [wShot_phase_status], a

	ShotPhaseFuncDef done

	ret
