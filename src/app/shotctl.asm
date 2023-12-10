include "common.inc"
include "app/shotctl.inc"

def MAX_SHOTS equ 99

section "wShot", wram0
wShot_max_shots:: db

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
	ZeroSection "wShot"

for I, ShotPhase__COUNT
	call shot_phase_{ShotPhase__KEY{u:I}}_init
endr

	ret


; Start next shot, if we haven't reached shot limit.
; @return F.C: set on success
; @mut: AF, B(C), (DE), HL
shotctl_start_next_shot::
	ld b, MAX_SHOTS
	ld hl, wShot_max_shots
	ld a, [hl]
	and a
	jr z, :+
	ld b, a
:
	ld hl, wShot_count
	ld a, [hl]
	cp b
	ld b, ShotEvent_SHOT_LIMIT
	jr nc, _shotctl_event
	inc [hl]
	xor a
	call shotctl_phase_change
	ld b, ShotEvent_START_SHOT
	call _shotctl_event
	scf
	ret


; @mut: AF, B(C), (DE), HL
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
; @mut: AF, (BC), (DE), HL
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


; @mut: AF, B(C), (DE), HL
shotctl_phase_next::
	ld a, [wShot_phase]
	inc a
	cp ShotPhase__COUNT
	jr nc, shotctl_start_next_shot
	jr shotctl_phase_change


; @mut: AF, B(C), (DE), HL
shotctl_phase_back::
	ld a, [wShot_phase]
	and a
	ret z
	dec a
	jr shotctl_phase_change


; @param A: phase
; @mut: AF, B(C), (DE), HL
shotctl_phase_change::
	ld [wShot_phase], a
	ld a, ShotPhaseStatus_ENTER
	ld [wShot_phase_status], a
	ld b, ShotEvent_PHASE_CHANGE
	jr _shotctl_event


; Call the event callback if callback != 0
; @param B: event code (ShotEvent enum)
; @mut: AF, (BC), (DE), HL
_shotctl_event:
	ld hl, wShot_event_callback
	ld a, [hl+]
	ld h, [hl]
	ld l, a

	or h
	ret z
	jp hl
