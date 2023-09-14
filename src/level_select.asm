include "defines.asm"


def HEADING_LINES equ 2
def HEADING_WIDTH equ 18
def HEADING_LEN equ HEADING_LINES * HEADING_WIDTH
def BORDER_TOP equ 1
def BORDER_SIDES equ 1
def DISPLAY_ROW equ 13
def DISPLAY_ORIGIN equ 32 * DISPLAY_ROW

for i, HEADING_LINES
	def DISPLAY_HEADING{u:i} equ DISPLAY_ORIGIN + (i + BORDER_TOP) * 32 + BORDER_SIDES
endr

def TXT_LEVEL equs "Level"
def TXT_LEVEL_LEN equ charlen("{TXT_LEVEL}")

section "LevelSelect State", wram0

for i, HEADING_LINES
	wHeading{u:i}: ds HEADING_WIDTH
endr

section "LevelSelect Mode", rom0


LevelSelect::
	.txt_level: db "{TXT_LEVEL}"


LevelSelect.init::
	call Texto_init
	call LevelSelect_refresh0
	call LevelSelect_refresh1
	call LevelSelect_draw

	ret


LevelSelect.main_iter::
	ld a, [wInput.pressed]
	ld b, a
	and PADF_A | PADF_START
	jr z, :+
	ld a, ModeGame
	jp Main_mode_change
:

	bit PADB_B, b
	jr z, :+
	ld a, ModeSplash
	jp Main_mode_change
:

	; L/R change level -/+
	ld a, [wInput.pressed]
	ld b, a
	ld a, [wSettings.level]
	ld d, a
	cp MAP_COUNT - 1
	jr nc, :+
	bit PADB_RIGHT, b
	jr z, :+
	inc a
	jr :++
:
	cp 0
	jr z, :+
	bit PADB_LEFT, b
	jr z, :+
	dec a
:

	cp d ; check index changed
	jr z, :+
	ld [wSettings.level], a
	call LevelSelect_refresh0
	call LevelSelect_refresh1
	call LevelSelect_draw
:

	ret


macro PutChar
	assert _NARG == 1
	ld a, \1
	ld [hl+], a
endm


LevelSelect_refresh0:
	ld a, [wSettings.level]
	; Level #
	ld hl, wHeading0
	; PutChar " "
	PutChar "<^L>"
	PutChar " "
	ld de, LevelSelect.txt_level
	ld bc, TXT_LEVEL_LEN
	call mem_copy
	PutChar " "
	ld a, [wSettings.level]
	call digi_print_u8
	PutChar " "
	ld bc, wHeading0 + HEADING_WIDTH - 1
	ld d, " "
	call mem_fill_to
	PutChar "<^R>"

	ret


LevelSelect_refresh1:
	ld a, [wSettings.level]
	call map_title_by_index
	push hl

	; "Title"
	ld hl, wHeading1
	PutChar "\""
	pop de ; map title structure (first byte is title length)
	ld a, [de]
	inc de
	ld c, a
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


LevelSelect_draw:
	ld hl, $9800 + DISPLAY_HEADING0 - 1
	WaitVRAM
	PutChar "<V>"
	ld de, wHeading0
	ld bc, HEADING_WIDTH
	call vmem_copy
	WaitVRAM
	PutChar "<V>"

	ld hl, $9800 + DISPLAY_HEADING1 - 1
	WaitVRAM
	PutChar "<V>"
	ld de, wHeading1
	ld bc, HEADING_WIDTH
	call vmem_copy
	WaitVRAM
	PutChar "<V>"

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
