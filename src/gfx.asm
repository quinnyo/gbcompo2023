
INCLUDE "defines.asm"
INCLUDE "res/onebit-mono.inc"


SECTION "OBJ Tiles", VRAM[$8000]
vOBJTiles::

SECTION "BG Tiles", VRAM[$8800]
vBGTiles::

SECTION "UI Tiles", VRAM[$9000]
vFontTiles::


SECTION "GFXLOADER", ROM0

gfx_load_default_font::
	ld hl, vFontTiles
	ld de, default_font
	ld bc, default_font.end - default_font
	call vmem_copy_double

	ret


; load tile data for game objects
gfx_load_game_obj::
	ld hl, vOBJTiles
	ld de, OBJTiles_data
	ld bc, OBJTiles_data_end - OBJTiles_data
	call vmem_copy

	ret


gfx_load_bg_tiles::
	ld hl, vBGTiles
	ld de, BGTiles_data
	ld bc, BGTiles_data_end - BGTiles_data
	call vmem_copy
	ret


default_font:
	INCBIN "res/onebit-mono.1bpp", 0, ONEBIT_MONO_RES_SIZE
.end


SECTION "GFXDATA", ROMX

BGTiles_data:
	INCBIN "res/map/terrain.2bpp"
BGTiles_data_end:


OBJTiles_data:
	INCBIN "res/shapes.2bpp"
	INCBIN "res/ball.2bpp"
	INCBIN "res/map/buildings.2bpp"
OBJTiles_data_end:
