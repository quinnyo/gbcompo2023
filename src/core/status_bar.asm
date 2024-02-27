include "common.inc"

def bStatuslineVisible    equ 0 ; set to enable statusline
def bStatuslineNeedSync  equ 1 ; status needs update
def fStatuslineVisible    equ 1 << bStatuslineVisible
def fStatuslineNeedSync  equ 1 << bStatuslineNeedSync

def STATUS_POS_X equ 7
def STATUS_SHOW_DX equ 23

def STATUS_LINE_LEN equ 32
export STATUS_LINE_LEN
def STATUS_LINE_COUNT equ 1
def STATUS_BUFFER_SIZE equ STATUS_LINE_LEN * STATUS_LINE_COUNT
def STATUS_ORIGIN equ $9C00


section "wStatusBar", wram0
; Status bar content buffer
wStatusLine::
for i, STATUS_LINE_COUNT
	.line{u:i} ds STATUS_LINE_LEN
endr

; Status bar status flags
wStatusFlags: db

section "StatusBar", rom0
; Set status bar content
; @param DE: string
; @param BC: string length
StatusBar_set_text::
	ld hl, wStatusLine
	call mem_copy

	ld d, " "
	ld bc, wStatusLine + STATUS_LINE_LEN
	call mem_fill_to

	ld a, [wStatusFlags]
	set bStatuslineNeedSync, a
	ld [wStatusFlags], a
	ret


; show status line
; @mut: AF, BC, DE, HL
StatusBar_sync::
	ld a, [wStatusFlags]
	res bStatuslineNeedSync, a
	ld [wStatusFlags], a

	ld hl, STATUS_ORIGIN
	ld de, wStatusLine
	ld bc, STATUS_LINE_LEN
	jp vmem_copy


; Statusline per-frame update routine.
; @mut: AF
StatusBar_update::
	ld a, [wStatusFlags]
	bit bStatuslineVisible, a
	; ret z
	jr nz, .trans_in
	ldh a, [rWY]
	cp SCRN_Y
	jr nc, .trans_out_end
	ldh a, [rWX]
	cp 165
	jr nc, .trans_out_end
	add STATUS_SHOW_DX
	ldh [rWX], a
	ret
.trans_out_end
	ld a, 165
	ldh [rWX], a
	ld a, SCRN_Y
	ldh [rWY], a
	ret
.trans_in
	; update status line contents if needed
	bit bStatuslineNeedSync, a
	call nz, StatusBar_sync

	; move into place
	ld a, SCRN_Y - 8
	ldh [rWY], a
	ldh a, [rWX]
	sub STATUS_POS_X + STATUS_SHOW_DX
	jr nc, :+
	xor a
:
	add STATUS_POS_X
	ldh [rWX], a
	ret


; Make statusline visible (start transition). Also sets the dirty flag.
; @mut: AF, B
StatusBar_show::
	ld a, [wStatusFlags]
	ld b, a
	bit bStatuslineVisible, a
	jr nz, :+
	; showing window, start off-screen
	ld a, SCRN_Y - 8
	ldh [rWY], a
	ld a, 165
	ldh [rWX], a
:
	ld a, fStatuslineVisible | fStatuslineNeedSync
	or b
	ld [wStatusFlags], a
	ret


StatusBar_hide::
	ld a, [wStatusFlags]
	res bStatuslineVisible, a
	ld [wStatusFlags], a
	ret


; initialise status line (starts off-screen)
StatusBar_init::
	xor a
	ld [wStatusFlags], a

	; clear buffer
	ld hl, wStatusLine
	ld bc, STATUS_BUFFER_SIZE
	ld d, " "
	call mem_fill

	ld a, SCRN_Y
	ldh [rWY], a
	ld a, 165
	ldh [rWX], a
	ret
