
INCLUDE "common.inc"
INCLUDE "input.inc"
INCLUDE "maths.inc"


def CURSOR_TILE equ 10
def CURSOR_SPEED equ 120

def TILE_DIR0 equ 0

; collide side tiles
def C_LEFT equ $9800 + 32 * 9
def C_RIGHT equ $9800 + 32 * 9 + 19
def C_TOP equ $9800 + 32 + 9
def C_BOTTOM equ $9800 + 32 * 17 + 9

def DBG_TEXT equ $9C00

section "Debug_Collidoscope", rom0
Debug_Collidoscope::

.init::
	xor a
	ldh [rSCX], a
	ldh [rSCY], a

	; palettes
	ld a, %11100100
	ldh [rBGP], a
	ldh [rOBP0], a
	ldh [rOBP1], a

	call gfx_load_game_obj
	call gfx_load_bg_tiles

	ld de, map_e1m1
	call world_load_map

	; DON'T ; clear background map
	; ld d, 255
	; ld hl, $9800
	; ld bc, BGMAP_LEN
	; call mem_fill

	ld de, Text.title
	ld bc, Text.title_end - Text.title
	ld hl, $9800
	call mem_copy

	ld d, 0
	ld hl, zero_start
	ld bc, zero_end - zero_start
	call mem_fill

	ld a, 8
	ld [wWorld.xmin], a
	ld a, 16
	ld [wWorld.ymin], a
	ld a, 160 - 8 - 1
	ld [wWorld.xmax], a
	ld a, 144 - 8 - 1
	ld [wWorld.ymax], a

	; init debug info
	ld hl, DBG_TEXT
	ld d, 0
	ld bc, BGMAP_LEN
	call mem_fill

	ld de, dbg_pos
	ld bc, dbg_pos.end - dbg_pos
	ld hl, DBG_POS
	call mem_copy
	ld de, dbg_cpos
	ld bc, dbg_cpos.end - dbg_cpos
	ld hl, DBG_CPOS
	call mem_copy
	ld de, dbg_tile
	ld bc, dbg_tile.end - dbg_tile
	ld hl, DBG_TILE
	call mem_copy

	ret


.main_iter::
	ld a, [wInput.released]
	bit PADB_B, a
	jp nz, $100

	call cursor_move

	ld a, [wCursor.x]
	ld b, a
	ld a, [wCursor.y]
	ld c, a ; B,C = pX,pY
	call world_point_collide_bounds ; E = current collide sides

	ld a, [wCollideSide]
	ld [wCollideSideLast], a
	ld d, a
	ld a, e
	ld [wCollideSide], a

	xor d
	ld h, a
	and e
	ld e, a ; E = set bits
	ld a, h
	and d
	ld d, a ; D = cleared bits

	bit SIDEB_LEFT, d
	jr z, :+
	ld a, "_"
	ld [C_LEFT], a
	jr :++
:
	bit SIDEB_LEFT, e
	jr z, :+
	ld a, "L"
	ld [C_LEFT], a
:

	bit SIDEB_RIGHT, d
	jr z, :+
	ld a, "_"
	ld [C_RIGHT], a
	jr :++
:
	bit SIDEB_RIGHT, e
	jr z, :+
	ld a, "R"
	ld [C_RIGHT], a
:

	bit SIDEB_TOP, d
	jr z, :+
	ld a, "_"
	ld [C_TOP], a
	jr :++
:
	bit SIDEB_TOP, e
	jr z, :+
	ld a, "T"
	ld [C_TOP], a
:

	bit SIDEB_BOTTOM, d
	jr z, :+
	ld a, "_"
	ld [C_BOTTOM], a
	jr :++
:
	bit SIDEB_BOTTOM, e
	jr z, :+
	ld a, "B"
	ld [C_BOTTOM], a
:

	; scene/world/map
	call scene_query

	; print cursor pos
	ld hl, DBG_PX
	ld a, [wCursor.x]
	call hexit_print_byte
	ld hl, DBG_PY
	ld a, [wCursor.y]
	call hexit_print_byte

	; show window
	ld a, 166 - 8 * DBG_WIDTH
	ldh [rWX], a
	ld a, 144 - 8 * DBG_HEIGHT
	ldh [rWY], a


	; world terrain
	call terrain_follower


	; OAM
	ld hl, wOAMBuffer

	ld a, [wCursor.y]
	add 12
	ld [hl+], a
	ld a, [wCursor.x]
	add 4
	ld [hl+], a
	ld a, CURSOR_TILE
	ld [hl+], a
	ld a, OAMF_PAL0
	ld [hl+], a


	ld a, [wTerranier.y]
	add 12
	ld [hl+], a
	ld a, [wTerranier.x]
	add 4
	ld [hl+], a
	srl a
	and 7 ; pX % 8 -- rolling :3
	ld [hl+], a
	ld a, OAMF_PAL0
	ld [hl+], a

	ret


cursor_move:
	ld a, [wInput.state]
	ld b, a

	; movement speed, hold A to slow down
	ld a, CURSOR_SPEED
	bit PADB_A, b
	jr z, :+
	srl a
	srl a
:
	ld c, a

	xor a
	bit PADB_LEFT, b
	jr z, .padright
	sub c
.padright
	bit PADB_RIGHT, b
	jr z, :+
	add c
:
	ld d, a

	xor a
	bit PADB_UP, b
	jr z, .paddown
	sub c
.paddown
	bit PADB_DOWN, b
	jr z, :+
	add c
:
	ld e, a

.apply
	ld hl, wCursor

	ld a, [hl+]
	ld b, a
	ld a, [hl-]
	ld c, a
	ld a, d
	addrrsa bc

	ld a, b
	ld [hl+], a
	ld a, c
	ld [hl+], a

	ld a, [hl+]
	ld b, a
	ld a, [hl-]
	ld c, a
	ld a, e
	addrrsa bc
	ld a, b
	ld [hl+], a
	ld a, c
	ld [hl+], a

	ret


scene_query:
	; Tilemap coord
	ld a, [wCursor.x]
	srl a
	srl a
	srl a
	ld [wCursor.cpx], a
	ld hl, DBG_CPX
	call hexit_print_byte
	ld a, [wCursor.y]
	srl a
	srl a
	srl a
	ld [wCursor.cpy], a
	ld hl, DBG_CPY
	call hexit_print_byte

	ld a, [wCursor.x]
	ld b, a
	ld a, [wCursor.y]
	ld c, a

	call world_point_to_tile
	ld c, l
	ld a, h
	ld hl, DBG_TADDR
	call hexit_print_byte
	ld a, c
	call hexit_print_byte

	ret


terrain_follower:
	ld a, [wInput.state]
	bit PADB_A, a
	jr z, .roll
	; copy cursor X
	ld a, [wCursor.x]
	ld b, a
	ld [wTerranier.x], a

	jr .snap_terrain
.roll
	ld hl, wTerranier.x
	ld a, [hl+]
	ld b, a
	ld a, [hl-]
	ld c, a

	ld a, 120
	addrrsa bc

	ld a, b
	ld [hl+], a
	ld [hl], c

.snap_terrain
	call world_get_terrain_column

	ld a, [hl] ; column y offset
	ld [wTerranier.y], a

	ret


Text:
	.title
	db "        collidoscope"
	.title_end
.end



def DBG_LINE_COUNT = 0

macro dbg_line
	def DBG_LINE_COUNT += 1
dbg_\1:
endm

dbg_text:
	dbg_line pos
		db "P:"
		.x: db "%%,"
		.y: db "%%"
	.end

	dbg_line cpos
		db "C:"
		.x: db "%%,"
		.y: db "%%"
	.end

	dbg_line tile
		db "T:"
		.address: db "%%%%"
	.end
dbg_text_end:


; def DBG_TEXT_LEN equ dbg_text_end - dbg_text
def DBG_POS equ DBG_TEXT
def DBG_PX equ DBG_POS + (dbg_pos.x - dbg_pos)
def DBG_PY equ DBG_POS + (dbg_pos.y - dbg_pos)
def DBG_CPOS equ DBG_POS + 32
def DBG_CPX equ DBG_CPOS + (dbg_cpos.x - dbg_cpos)
def DBG_CPY equ DBG_CPOS + (dbg_cpos.y - dbg_cpos)
def DBG_TILE equ DBG_CPOS + 32
def DBG_TADDR equ DBG_TILE + (dbg_tile.address - dbg_tile)

def DBG_WIDTH equ 8
def DBG_HEIGHT equ DBG_LINE_COUNT


section "Debug_Collidoscope_State", wramx

zero_start:

wCursor:
	.x: dw
	.y: dw
	.cpx: db
	.cpy: db
.end

wCollideSide: db
wCollideSideLast: db

wTerranier:
	.x: db
	.xs: db
	.y: db
zero_end:
