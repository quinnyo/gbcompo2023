INCLUDE "defines.asm"
INCLUDE "input.inc"

SECTION "Splash", ROM0
Splash::

.init::
	; palettes
	ld a, %11100100
	ldh [rBGP], a
	ldh [rOBP0], a
	ldh [rOBP1], a

	ld de, TileData
	ld hl, $9000 - (TileData.end - TileData)
	ld bc, TileData.end - TileData
	call vmem_copy

	; load title screen thing
	ld de, title_tiles
	ld hl, $8800
	ld bc, title_tiles_size
	call vmem_copy

	ld de, title_map
	ld b, title_map_width
	ld c, title_map_height
	ld hl, $9800
	call vmem_copy_rect


if def(DEBUG_MODES)
	call debug_menu_init
endc

	ld hl, mus01
	call music_init

	ret


.main_iter::
	ld a, [wInput.pressed]
	and PADF_A | PADF_START
	jr z, :+
	ld a, ModeLevelSelect
	jp Main_mode_change
:

if def(DEBUG_MODES)
	call debug_menu_update
endc

	ret


TileData:
	dw `23321011
	dw `23321011
	dw `33210112
	dw `32101123
	dw `10112332
	dw `11233210
	dw `12332101
	dw `12332101

if !def(DEBUG)
	dw `00001123
	dw `10011223
	dw `11112233
	dw `21122332
	dw `21122332
	dw `11112233
	dw `10011223
	dw `10001123
else
	dw `11300133
	dw `13103133
	dw `13100111
	dw `13103131
	dw `11300111
	dw `22222223
	dw `23332332
	dw `32223332
endc

	dw `00001112
	dw `00111222
	dw `01122223
	dw `11222333
	dw `12223333
	dw `12333322
	dw `11233222
	dw `01122221

	dw `22232101
	dw `22321011
	dw `23210112
	dw `32101123
	dw `20112332
	dw `01223221
	dw `12332210
	dw `12222100

	dw `11111111
	dw `10001000
	dw `10001000
	dw `10001000
	dw `11111111
	dw `10001000
	dw `10001000
	dw `10001000
.end

title_map_size equ $0168
title_map_width equ $14
title_map_height equ $12
include "res/title.scrn"


if def(DEBUG_MODES)

section "DebugMenu", romx

def MENUB_DEBUG equ 7
def MENUF_DEBUG equ %10000000

debug_menu_init:
	call Texto_init

	ld a, MENUF_DEBUG
	ld [wMenuFlags], a
	ld de, debug_menu_text
	ld b, debug_menu_text.end - debug_menu_text
	call Texto_writeln
	call Texto_show

debug_menu_update:
	ld a, [wMenuFlags]
	bit MENUB_DEBUG, a
	jr z, .check_show_debug
	call nz, debug_menu
	jr .debug_menu_done

.check_show_debug
	ld a, [wInput.pressed]
	bit PADB_SELECT, a
	jr z, :+
	ld a, [wMenuFlags]
	set MENUB_DEBUG, a
	ld [wMenuFlags], a
	call nz, Texto_show
: ; SEL not pressed
.debug_menu_done

	call Texto_update

	ret

debug_menu:
	ld a, [wInput.pressed]
	bit PADB_LEFT, a
	jr z, :+
	ld a, ModeDebug_InspectGFX
	jp Main_mode_change
:
	bit PADB_DOWN, a
	jr z, :+
	ld a, ModeDebug_BallDrop
	jp Main_mode_change
:
	bit PADB_UP, a
	jr z, :+
	ld a, ModeDebug_Collidoscope
	jp Main_mode_change
:

	bit PADB_SELECT, a
	ret z

	; hide menu
	ld a, [wMenuFlags]
	res MENUB_DEBUG, a
	ld [wMenuFlags], a
	call nz, Texto_show_none

	ret


debug_menu_text:
	db "   <<Debug Town>>   "
	db " collido- U         "
	db "    gfx- L R -_____ "
	db "          D -balls  "
.end


SECTION "DebugMenuState", WRAM0
wMenuFlags: db

endc