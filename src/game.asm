include "defines.asm"
include "ball.inc"

def bStatusUpdate equ 0
def bStatusClear equ 5
def bStatusPaused equ 6
def bStatusShotEnded equ 7

def fStatusUpdate equ 1 << bStatusUpdate
def fStatusClear equ 1 << bStatusClear
def fStatusPaused equ 1 << bStatusPaused
def fStatusShotEnded equ 1 << bStatusShotEnded

def fStatusPromptActive equ fStatusClear | fStatusPaused | fStatusShotEnded

section "GameImpl", rom0

Game::

.init::
	xor a
	ldh [rSCX], a
	ldh [rSCY], a
	ld [wGame.status], a
	ld [wGame.shot_count], a
	ld [wGame.tick1], a
	ld [wGame.tick2], a
	ld [wMsgBoxX], a
	ld [wMsgBoxY], a
	ld [wMsgBoxWidth], a
	ld [wMsgBoxHeight], a

	ld hl, wMsgBoxBuffer
	ld bc, MSG_BOX_BUFFER_SIZE
	ld d, 0
	call mem_fill
	ld hl, wStatusLine
	ld bc, STATUS_BUFFER_SIZE
	ld d, 0
	call mem_fill

	ld a, %11100100
	ldh [rBGP], a
	ldh [rOBP0], a
	ld a, %01101100
	ldh [rOBP1], a

	call gfx_load_game_obj
	call gfx_load_bg_tiles

	call world_init
	ld a, [wSettings.level]
	call map_info_by_index
	ld a, [hl+]
	ld e, a
	ld d, [hl]
	call world_load_map

	call world_display_tilemap

	call things_init
	call Ball_init

if def(DEBUG_BALL)
	call Ball_dbg_init
endc

	call start_next_shot

	ret


.main_iter::
	call modal_update

if def(DEBUG_BALL)
	call Ball_dbg_update
endc

.do_status_update
	; update status line
	ld a, [wGame.status]
	bit bStatusUpdate, a
	call nz, status_update

	ret


modal_update:
	; update active modal prompt (if any)
	ld a, [wInput.pressed]
	ld b, a
	ld a, [wGame.status]
	bit bStatusClear, a
	jr nz, .modal_clear
	bit bStatusShotEnded, a
	jr nz, .modal_shot_ended
	bit bStatusPaused, a
	jr nz, .modal_paused
	jr .modal_default

.modal_clear
	bit PADB_A, b
	ld a, [wSettings.level]
	inc a
	ld [wSettings.level], a
	ld a, ModeLevelSelect
	jp Main_mode_change

.modal_shot_ended
	bit PADB_A, b
	call nz, start_next_shot
	ret

.modal_paused
	bit PADB_SELECT, b
	jr z, :+
	ld a, ModeLevelSelect
	jp Main_mode_change
:

.modal_default
	bit PADB_START, b
	jp nz, pause_toggle

	; game timers
	ld a, [wGame.tick1]
	inc a
	ld [wGame.tick1], a
	bit 0, a
	jr nz, :+
	ld a, [wGame.tick2]
	inc a
	ld [wGame.tick2], a
:

	call oam_clear

	; save ball status before Ball_process
	ld a, [wBall.status]
	ld [wGame.ballstat], a

	call Ball_process

	; get changed ball status
	ld a, [wBall.mode]
	bit bBallModeMotion, a
	jr z, :+
	ld a, [wGame.ballstat]
	ld e, a
	ld a, [wBall.status]
	ld d, a
	xor e
	and d

	and fBallStatShotEnded
	jr z, :+
	call .show_shot_end_prompt
:

	ld a, [wBall.mode]
	bit bBallModeMotion, a
	call nz, .ball_in_play

	call things_draw

	; If ball's shot count (wShot.count) differs from game score, shot just taken
	ld a, [wGame.shot_count]
	ld d, a
	ld a, [wShot.count]
	cp d
	jr z, :+
	ld [wGame.shot_count], a
	call build_status_stats
:

	ret

; to run only if ball has been hit
.ball_in_play:
	; Check if ball stuck / stopped / shot ended
	ld a, [wBall.status]
	and fBallStatShotEnded
	ret nz

	; collide things
	ld a, [wBall.x]
	inc a
	ld b, a
	ld a, [wBall.y]
	inc a
	ld c, a
	ld e, BallCollideThingRadius
	call things_collide_ball

	call things_count
	ld a, d
	and a
	jr z, :+
	; hit things!
	call build_status_stats

	ld a, [wThings.alive]
	cp 0
	jr nz, :+
	ld de, msgAllDestroyed
	call draw_msg_box
	ld a, [wGame.status]
	set bStatusClear, a
	ld [wGame.status], a

: ; /hit things!

	ret


.show_shot_end_prompt:
	ld a, [wGame.status]
	set bStatusShotEnded, a
	ld [wGame.status], a

	ld a, [wBall.status]
	bit bBallStatOOB, a
	jr z, :+
	; show OOB statusline
	ld de, sStatusOOB
	ld bc, sStatusOOB_len
	call build_status_text
	ret
:
	ld de, sStatusNextShot
	ld bc, sStatusNextShot_len
	call build_status_text
	ret


start_next_shot:
	call Ball_reset

	ld a, [wGame.status]
	res bStatusShotEnded, a
	ld [wGame.status], a

	call build_status_stats

	ret


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
	call build_status_text
	ret


macro PutChar
	assert _NARG == 1
	ld a, \1
	ld [hl+], a
endm

; @param DE: string
; @param BC: string length
build_status_text:
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
	ld a, [wGame.shot_count]
	call digi_print_u8_99
	PutChar " "
	PutChar "<Hut>"
	ld a, [wThings.alive]
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
status_update:
	ld hl, STATUS_ORIGIN
	ld de, wStatusLine
	ld bc, STATUS_LINE_LEN
	call vmem_copy

	ld a, [wGame.status]
	res bStatusUpdate, a
	ld [wGame.status], a

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

	StrThing sStatusOOB, "Out of Bounds! <^A>"
	StrThing sStatusNextShot, "Continue <^A>"
	StrThing sStatusPaused, "Paused.  Resume <^Sta>"
	StrThing sTipKeys, " <^U><^D><^L><^R>Aim <^A>Go"


section "GameState", wram0

wGame::
	.status: db
	.shot_count: db ; number of shots taken this stage
	.ballstat: db ; last ball status
	.tick1:: db
	.tick2:: db

wMsgBoxX: db
wMsgBoxY: db
wMsgBoxWidth: db
wMsgBoxHeight: db
wMsgBoxBuffer: ds MSG_BOX_BUFFER_SIZE

wStatusLine:
for i, STATUS_LINE_COUNT
	.line{u:i} ds STATUS_LINE_LEN
endr
