include "common.inc"
include "app/ball.inc"
include "app/shotctl.inc"

def bStatusUpdate    equ 0 ; status needs update
def bStatusClear     equ 5 ; stage cleared
def bStatusPaused    equ 6 ; game paused
def bStatusFailed    equ 7 ; game over

def fStatusUpdate    equ 1 << bStatusUpdate
def fStatusClear     equ 1 << bStatusClear
def fStatusPaused    equ 1 << bStatusPaused
def fStatusFailed    equ 1 << bStatusFailed


section "GameImpl", rom0

Game::

.init::
	xor a
	ldh [rSCX], a
	ldh [rSCY], a
	ld [wGame.status], a
	ld [wGame.tick1], a
	ld [wGame.tick2], a
	ld [wMsgBoxX], a
	ld [wMsgBoxY], a
	ld [wMsgBoxWidth], a
	ld [wMsgBoxHeight], a

	ld a, fStatusUpdate
	ld [wGame.status], a

	ld hl, wMsgBoxBuffer
	ld bc, MSG_BOX_BUFFER_SIZE
	ld d, 0
	call mem_fill
	ld hl, wStatusLine
	ld bc, STATUS_BUFFER_SIZE
	ld d, 0
	call mem_fill

	call gfx_load_game_obj
	call gfx_load_bg_tiles
	call Rules_clear
	call stats_init
	call Effects_init
	call Collide_init
	call things_init
	call tcm_init
	call world_init
	ld a, [wSettings.level]
	cp COURSE_COUNT
	jr c, :+
	rst panic
:
	call Courses_index_mapid
	call Maps_data_access
	ld e, l
	ld d, h
	call world_load_map
	call world_display_tilemap

	call things_start
	call Ball_init

	call shotctl_init
	ld a, [wSettings.level]
	call Courses_index_info
	inc hl ; skip par score
	ld a, [hl]
	ld [wShot_max_shots], a
	call shotctl_start_next_shot
	ld hl, wShot_event_callback
	ld a, low(_Game_on_shot_event)
	ld [hl+], a
	ld [hl], high(_Game_on_shot_event)

	call shotctl_get_shot_count
	ld d, a
	call BallPile_setup

	call musctl_stop

	ret


.main_iter::
	call _Game_update
	call BallPile_draw
.do_status_update
	; update status line
	ld a, [wGame.status]
	bit bStatusUpdate, a
	call nz, status_update

	ret


_Game_on_shot_event:
	ld a, b
	cp ShotEvent_PHASE_CHANGE
	jr z, _Game_on_shot_phase_changed
	cp ShotEvent_START_SHOT
	jr z, _Game_on_start_next_shot
	cp ShotEvent_SHOT_LIMIT
	jr z, _Game_on_shot_limit
	ret


_Game_on_shot_phase_changed:
	ld a, [wShot_phase]
	cp ShotPhase__SETUP
	call z, things_update_colliders

	; show status line
	call build_status_stats
	call status_update
	ret


_Game_on_start_next_shot:
	call shotctl_get_shot_count
	ld d, a
	call BallPile_set
	ret


_Game_on_shot_limit:
	ld hl, wGame.status
	bit bStatusClear, [hl]
	ret nz
	set bStatusFailed, [hl]
	ld de, msgGameOver
	call draw_msg_box
	ret


_Game_update:
	; update active modal prompt (if any)
	ld a, [wInput.pressed]
	ld b, a

	ld a, [wGame.status]
	bit bStatusClear, a
	jr nz, _Game_update_stage_cleared
	bit bStatusFailed, a
	jr nz, _Game_update_game_over
	bit bStatusPaused, a
	jr nz, _Game_update_paused

	bit PADB_START, b
	jp nz, pause_toggle

	call _Game_update_timers
	call oam_clear
	call shotctl_update

	; collide things
	ld a, [wBall + Ball_x + 1]
	ld b, a
	ld a, [wBall + Ball_y + 1]
	ld c, a
	ld e, BallCollideThingRadius
	call Collide_set_subject_missile
	call Collide_all_subject
	; update things
	call things_think_prepare
	call Rules_tick
	call things_think_finalise
	ld a, [wThingsInfo.just_died]
	and a
	jr z, .things_done
	call _things_smashed
	call build_status_stats
	ld a, [wThingsInfo.targets]
	cp 0
	jr nz, .things_done
	ld de, msgAllDestroyed
	call draw_msg_box
	ld a, [wGame.status]
	set bStatusClear, a
	ld [wGame.status], a
.things_done
	call things_draw
	call Ball_draw
	call Effects_update
	ret


; @param B: input state (pressed)
_Game_update_stage_cleared:
	bit PADB_A, b
	ret z ; wait till A pressed

	; save score
	ld a, [wShot_count]
	ld b, a
	ld a, [wSettings.level]
	call Courses_index_score
	and a
	jr z, .save_score ; if old score is zero, always save new score.
	cp b
	jr c, .no_save_score ; save best score
.save_score
	ld [hl], b
.no_save_score

	ld a, [wSettings.level]
	inc a
	ld [wSettings.level], a
	ld a, ModeLevelSelect
	jp Main_mode_change
	ret


; @param B: input state (pressed)
_Game_update_game_over:
	bit PADB_A, b
	ret z ; wait till A pressed
	ld a, ModeLevelSelect
	jp Main_mode_change


; @param B: input state (pressed)
_Game_update_paused:
	bit PADB_SELECT, b
	jr z, :+
	ld a, ModeLevelSelect
	jp Main_mode_change
:

	bit PADB_START, b
	ret z
	jp pause_toggle
	ret


_Game_update_timers:
	ld hl, wGame.tick1
	inc [hl]
	bit 0, [hl]
	ret nz
	ld hl, wGame.tick2
	inc [hl]
	ret


; trigger thing smashed effects
; @mut: AF, C, DE, HL
_things_smashed:
	ld a, [wBall.x + 1]
	ld hl, snd_smash_03
	bit 3, a
	jp nz, sound_play
	ld hl, snd_smash_02
	bit 2, a
	jp nz, sound_play
	ld hl, snd_smash_01
	bit 1, a
	jp nz, sound_play
	ld hl, snd_smash_04
	jp sound_play


pause_toggle:
	ld a, [wGame.status]
	bit bStatusPaused, a
	jr z, .pause
.unpause
	res bStatusPaused, a
	ld [wGame.status], a

	call build_status_stats

	ret
.pause
	set bStatusPaused, a
	ld [wGame.status], a

	ld de, sStatusPaused
	ld bc, sStatusPaused_len
	call status_set_text
	ret


macro PutChar
	assert _NARG == 1
	ld a, \1
	ld [hl+], a
endm


; Set status bar content
; @param DE: string
; @param BC: string length
status_set_text:
	ld hl, wStatusLine
	call mem_copy

	ld d, " "
	ld bc, wStatusLine + STATUS_LINE_LEN
	call mem_fill_to

	ld a, [wGame.status]
	set bStatusUpdate, a
	ld [wGame.status], a

	ret


build_status_stats:
	ld hl, wStatusLine
	PutChar "<Sh>"
	PutChar "<ot:>"
	ld a, [wShot_count]
	call digi_print_u8_99
	PutChar " "
	PutChar "<Hut>"
	ld a, [wThingsInfo.targets]
	call digi_print_u8_99
	ld de, sTipKeys
	ld bc, sTipKeys_len
	call mem_copy
	ld d, " "
	ld bc, wStatusLine + STATUS_LINE_LEN
	call mem_fill_to

	ld a, [wGame.status]
	set bStatusUpdate, a
	ld [wGame.status], a

	ret


; show status line
; @mut: AF, BC, DE, HL
status_update:
	ld a, [wGame.status]
	res bStatusUpdate, a
	ld [wGame.status], a

	ld hl, STATUS_ORIGIN
	ld de, wStatusLine
	ld bc, STATUS_LINE_LEN
	call vmem_copy

	ld a, SCRN_Y - 8
	ldh [rWY], a
	ld a, 7
	ldh [rWX], a

	ret


; @param DE: message
draw_msg_box:
	ld a, [de]
	inc de
	dec a
	ld [wMsgBoxX], a
	ld a, [de]
	inc de
	dec a
	ld [wMsgBoxY], a

	ld a, [de]
	inc de
	ld b, a
	ld a, [de]
	inc de
	ld c, a

	call build_msg_box

	; BG destination
	ld a, [de]
	inc de
	ld l, a
	ld a, [de]
	inc de
	ld h, a

	; copy buffered message
	ld de, wMsgBoxWidth
	ld a, [de]
	inc de
	ld b, a
	ld a, [de]
	inc de
	ld c, a
	call vmem_copy_rect

	ret


; @param DE: text
; @param B,C: internal W,H
build_msg_box:
	ld a, b
	add 2
	ld [wMsgBoxWidth], a
	ld a, c
	add 2
	ld [wMsgBoxHeight], a

	ld hl, wMsgBoxBuffer

	push bc
	PutChar "<TL>"
	ld a, "<H>"
:
	ld [hl+], a
	dec b
	jr nz, :-
	PutChar "<TR>"
	pop bc

.loop_lines
	push bc
	PutChar "<V>"
:
	ld a, [de]
	inc de
	ld [hl+], a
	dec b
	jr nz, :-

	PutChar "<V>"

	pop bc
	dec c
	jr nz, .loop_lines

	PutChar "<BL>"
	ld a, "<H>"
:
	ld [hl+], a
	dec b
	jr nz, :-
	PutChar "<BR>"

	ret


macro MsgThing
	def _LABEL equs "\1"
	shift
	def _TEXT equs \1
	shift

	def {_LABEL}_len equ charlen("{_TEXT}")

	def _FLAGS = 0

	rept _NARG
		if strin("\1", "x:") == 1
			def _S equs strsub("\1", 3)
			def _X equ {_S}
			purge _S
		elif strin("\1", "y:") == 1
			def _S equs strsub("\1", 3)
			def _Y equ {_S}
			purge _S
		elif strcmp("nobox", "\1") == 0
			def _BOX equ 0
		endc
		shift
	endr

	if !def(_X)
		def _X equ 10 - ({_LABEL}_len / 2)
	endc
	if !def(_Y)
		def _Y equ 6
	endc
	if !def(_BOX)
		def _BOX equ 1
	endc

	if _BOX != 0
		def _FLAGS |= 1
	endc

	def {_LABEL}_rel equ _Y * 32 + _X
	def {_LABEL}_width equ {_LABEL}_len

	{_LABEL}:
		.posx: db _X
		.posy: db _Y
		.width: db {_LABEL}_width
		.height: db 1
		.data: db "{_TEXT}"
		.pos: dw $9800 + {_LABEL}_rel - 32 - 1

	purge _LABEL, _TEXT, _FLAGS, _X, _Y, _BOX
endm

	MsgThing msgAllDestroyed, " Clear! "
	MsgThing msgGameOver, " Game Over! "


def MSG_MAX_WIDTH equ 18
def MSG_MAX_LINES equ 2
def MSG_BOX_MAX_WIDTH equ MSG_MAX_WIDTH + 2
def MSG_BOX_MAX_HEIGHT equ MSG_MAX_LINES + 2
def MSG_BOX_BUFFER_SIZE equ MSG_BOX_MAX_WIDTH * MSG_BOX_MAX_HEIGHT

def STATUS_LINE_LEN equ 32
def STATUS_LINE_COUNT equ 1
def STATUS_BUFFER_SIZE equ STATUS_LINE_LEN * STATUS_LINE_COUNT
def STATUS_ORIGIN equ $9C00

macro StrThing
	def \1_str equs \2
	def \1_len equ charlen(\2)
	\1: db \2
endm

	StrThing sStatusPaused, "Paused.  Resume <^Sta>"
	StrThing sTipKeys, " <^U><^D><^L><^R>Aim <^A>Go"


section "GameState", wram0

wGame::
	.status: db
	.tick1:: db
	.tick2:: db

wMsgBoxX: db
wMsgBoxY: db
wMsgBoxWidth: db
wMsgBoxHeight: db
wMsgBoxBuffer: ds MSG_BOX_BUFFER_SIZE

; Status bar content buffer
wStatusLine:
for i, STATUS_LINE_COUNT
	.line{u:i} ds STATUS_LINE_LEN
endr


section "wStats", wram0

; State of ball at end of last shot
wLastBall_status:: db
wLastBall_x::      db
wLastBall_y::      db


section "stats", rom0

stats_init::
	xor a
	ld [wLastBall_status], a
	ld [wLastBall_x], a
	ld [wLastBall_y], a

	ret
