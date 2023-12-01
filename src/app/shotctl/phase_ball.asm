include "common.inc"
include "app/shotctl.inc"
include "app/ball.inc"


section "phase_ball_state", wram0
wBallStat: db ; last ball status


section "phase_ball", rom0
	ShotPhaseFuncDef ball, init
_phase_init:
	xor a
	ld [wBallStat], a
	ret


; Launch ball
_ball_phase_entered:
	; just entered action/ball phase
	call Ball_reset

	; setup ball from ShotConfig
	ld de, wShotCfg_vx
	ld hl, wBall.vx
	ld c, 4 ; 2 words (X,Y)
	call mem_copy_short

	call Ball_launch
	ld a, ShotPhaseStatus_OK
	ld [wShot_phase_status], a
	ret


	ShotPhaseFuncDef ball
_ball_phase_update:
	ld a, b
	cp ShotPhaseStatus_ENTER
	jr z, _ball_phase_entered

	; Check if ball stuck / stopped
	ld hl, wBallStat
	ld a, [hl]
	and fBallStatShotEnded
	ret nz

	; save ball status before Ball_process
	ld a, [wBall.status]
	ld [hl], a
	call Ball_process

	; check ball status changed
	ld a, [wBallStat]
	ld e, a
	ld a, [wBall.status]
	ld d, a
	xor e
	and d
	ret z ; no change

	and fBallStatShotEnded
	ret z

	; ball stopped, shot ended...
	ld a, ShotPhaseStatus_NEXT
	ld [wShot_phase_status], a

	; TODO: ball stopped sound / notification?

	; trigger out of bounds feedback/effects
	bit bBallStatOOB, a
	ret z
	ld hl, snd_ball_oob
	call sound_play
	; TODO: show 'out of bounds' message
	ret
