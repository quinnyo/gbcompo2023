include "common.inc"
include "mus.inc"

/*
/------------------\
[< Level    #     >]
["Title of the Map"]
[ par:XX   best:YY ]
\------------------/
*/

def HEADING_LINES equ 3
def HEADING_WIDTH equ 18
def HEADING_LEN equ HEADING_LINES * HEADING_WIDTH
def TITLE_MAX_LEN equ HEADING_WIDTH - 2
def BORDER_TOP equ 1
def BORDER_SIDES equ 1
def DISPLAY_ROW equ 13
def DISPLAY_ORIGIN equ 32 * DISPLAY_ROW

for i, HEADING_LINES
	def DISPLAY_HEADING{u:i} equ DISPLAY_ORIGIN + (i + BORDER_TOP) * 32 + BORDER_SIDES
endr

def TXT_LEVEL equs "<^L> Level "
def TXT_LEVEL_LEN equ charlen("{TXT_LEVEL}")
def TXT_PAR equs " par:"
def TXT_PAR_LEN equ charlen("{TXT_PAR}")
def TXT_BEST equs "   best:"
def TXT_BEST_LEN equ charlen("{TXT_BEST}")


section "LevelSelect State", wram0

for i, HEADING_LINES
	wHeading{u:i}: ds HEADING_WIDTH
endr

section "LevelSelect Mode", rom0

txt_level: db "{TXT_LEVEL}"
txt_par:   db "{TXT_PAR}"
txt_best:  db "{TXT_BEST}"

LevelSelect::

LevelSelect.init::
	ld a, MAPIDX_bg_level_select
	call Maps_data_access
	ld e, l
	ld d, h
	call world_load_map
	call world_display_tilemap

	ld a, [wSettings.level]
	cp COURSE_COUNT
	jr c, :+
	ld a, COURSE_COUNT - 1
	ld [wSettings.level], a
:

	call Texto_init
	call LevelSelect_refresh0
	call LevelSelect_refresh1
	call LevelSelect_refresh2
	call LevelSelect_draw

	ld b, MUSIC_TRACK_MUS99_INDEX
	call musctl_play_next

	ret


LevelSelect.main_iter::
	ld a, [wInput.pressed]
	ld b, a

	and PADF_A | PADF_START
	jr z, :+ ; if OK pressed
	ld a, [wSettings.level]
	call Courses_index_locked
	jr z, :+ ; if level unlocked
	ld a, ModeGame
	jp Main_mode_change
:

	bit PADB_B, b
	jr z, :+
	ld a, ModeSplash
	jp Main_mode_change
:

	ld a, [wSettings.level]
	ld d, a
	call _input_try_change_level
	ld a, [wSettings.level]
	cp d ; check index changed
	jr z, :+
	ld a, d
	ld [wSettings.level], a
	ld hl, snd_ui_move
	call sound_play
	call LevelSelect_refresh0
	call LevelSelect_refresh1
	call LevelSelect_refresh2
	call LevelSelect_draw
:

	ret


; @param B: input pressed
; @param D: current level
; @return D: new level
; @mut: AF, D, HL
_input_try_change_level:
	bit PADB_RIGHT, b
	jr z, :+
	cp COURSE_COUNT - 1
	ret nc
	call Courses_index_score
	ret z
	inc d
	ret
:
	bit PADB_LEFT, b
	ret z
	ld a, d
	and a
	ret z
	dec d
	ret


macro PutChar
	assert _NARG == 1
	ld a, \1
	ld [hl+], a
endm


LevelSelect_refresh0:
	ld hl, wHeading0
	ld de, txt_level
	ld bc, TXT_LEVEL_LEN
	call mem_copy
	ld a, [wSettings.level]
	call digi_print_u8
	ld bc, wHeading0 + HEADING_WIDTH - 1
	ld d, " "
	call mem_fill_to

	ld d, " "
	ld a, [wSettings.level]
	cp COURSE_COUNT - 1
	jr nc, :+
	call Courses_index_score
	ld d, "<^R>"
	jr nz, :+
	ld d, "!"
:
	ld a, d
	ld [bc], a

	ret


LevelSelect_refresh1:
	ld a, [wSettings.level]
	call Courses_index_title
	push hl

	; "Title"
	ld hl, wHeading1
	PutChar "\""
	pop de ; map title structure (first byte is title length)
	ld a, [de]
	inc de
	ld c, a
	cp TITLE_MAX_LEN
	jr c, :+
	ld c, TITLE_MAX_LEN
:
	ld a, [de]
	inc de
	ld [hl+], a
	inc a
	dec c
	jr nz, :-
	PutChar "\""
	ld bc, wHeading1 + HEADING_WIDTH
	ld d, " "
	call mem_fill_to

	ret


LevelSelect_refresh2:
	ld hl, wHeading2
	ld de, txt_par
	ld c, TXT_PAR_LEN
	call mem_copy_short

	ld a, [wSettings.level]
	call Courses_index_info
	ld hl, wHeading2 + TXT_PAR_LEN
	call digi_print_u8_99

	ld de, txt_best
	ld c, TXT_BEST_LEN
	call mem_copy_short

	ld a, [wSettings.level]
	call Courses_index_score
	ld hl, wHeading2 + TXT_PAR_LEN + TXT_BEST_LEN + 2
	and a
	jr nz, .print_score
	PutChar "*"
	PutChar "*"
	jr :+
.print_score
	call digi_print_u8_99
:

	ld bc, wHeading2 + HEADING_WIDTH
	ld d, " "
	call mem_fill_to

	ret


; @param DE: src text
; @param HL: dest
LevelSelect_draw_row:
	WaitVRAM
	PutChar "<V>"
	ld bc, HEADING_WIDTH
	call vmem_copy
	WaitVRAM
	PutChar "<V>"
	ret


LevelSelect_draw:
for i, HEADING_LINES
	ld hl, $9800 + DISPLAY_HEADING{u:i} - 1
	ld de, wHeading{u:i}
	call LevelSelect_draw_row
endr

	; top border
	ld hl, $9800 + DISPLAY_ORIGIN
	WaitVRAM
	PutChar "<TL>"
	ld d, "<H>"
	ld c, HEADING_WIDTH
	call vmem_fill_byte
	WaitVRAM
	PutChar "<TR>"

	; bottom border
	ld hl, $9800 + DISPLAY_ORIGIN + (BORDER_TOP + HEADING_LINES) * 32
	WaitVRAM
	PutChar "<BL>"
	ld d, "<H>"
	ld c, HEADING_WIDTH
	call vmem_fill_byte
	WaitVRAM
	PutChar "<BR>"

	ret
