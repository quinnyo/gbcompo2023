include "common.inc"
include "app/shotctl.inc"

def MAX_SHOTS equ 99

section "wShot", wram0

wShot_phase:: db
wShot_phase_status:: db
wShot_count:: db

; Pointer to shotctl event listener. Set to 0 to disable.
; shot phase changed: Listener will be called when shot phase changes.
wShot_event_callback:: dw

wShotCfg_vx:: dw
wShotCfg_vy:: dw


section "shotctl", rom0

shotctl_init::
	ld hl, wShot_phase
	xor a
	ld [hl+], a ; wShot_phase
	ld a, ShotPhaseStatus_INIT
	ld [hl+], a ; wShot_phase_status
	xor a
	ld [hl+], a ; wShot_count
	ld [hl+], a ; wShot_event_callback.0
	ld [hl+], a ; wShot_event_callback.1
	ld [hl+], a ; wShotCfg_vx.0
	ld [hl+], a ; wShotCfg_vx.1
	ld [hl+], a ; wShotCfg_vy.0
	ld [hl+], a ; wShotCfg_vy.1

for I, ShotPhase__COUNT
	ld b, ShotPhaseStatus_INIT
	call shot_phase_{ShotPhase__KEY{u:I}}_update
endr

	ret


shotctl_start_next_shot::
	xor a
	call shotctl_phase_change

	ld hl, wShot_count
	ld a, MAX_SHOTS - 1
	cp [hl]
	jr c, :+
	inc [hl]
:

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
	rst panic


; @mut: AF
shotctl_phase_next::
	ld a, [wShot_phase]
	inc a
	cp ShotPhase__COUNT
	jr nc, shotctl_start_next_shot
	jr shotctl_phase_change


; @mut: AF
shotctl_phase_back::
	ld a, [wShot_phase]
	and a
	ret z
	dec a
	jr shotctl_phase_change


; @param A: phase
; @mut: AF, HL
shotctl_phase_change::
	ld [wShot_phase], a
	ld a, ShotPhaseStatus_ENTER
	ld [wShot_phase_status], a

	jr _shotctl_event


; Call the event callback if callback != 0
; @mut: AF, HL
_shotctl_event:
	ld hl, wShot_event_callback
	ld a, [hl+]
	ld h, [hl]
	ld l, a

	or h
	ret z
	jp hl
