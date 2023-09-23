
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


gfx_load_default_palettes::
	; DMG
	ld a, %11100100
	ldh [rBGP], a
	ldh [rOBP0], a
	ld a, %01101100
	ldh [rOBP1], a

	; CGB
	xor a
	ldh [rBCPS], a
	ld hl, bcp_start
	ld c, BCP_COUNT * 4
	call gfx_bcp_load
	xor a
	ldh [rOCPS], a
	ld hl, ocp_start
	ld c, OCP_COUNT * 4
	call gfx_ocp_load

	ret


; Load a number of colours from somewhere to the BG colour palette.
; @param HL: address of colour data (2 bytes per colour)
; @param C: number of colours to load
; @mut: A, C, HL, [rBCPS]
; @note: sets BCPSF_AUTOINC
gfx_bcp_load::
	ldh a, [rBCPS]
	or BCPSF_AUTOINC
	ldh [rBCPS], a
:
	ld a, [hl+]
	ldh [rBCPD], a
	ld a, [hl+]
	ldh [rBCPD], a
	dec c
	jr nz, :-
	ret


; Load a number of colours from somewhere to the OBJ colour palette.
; @param HL: address of colour data (2 bytes per colour)
; @param C: number of colours to load
; @mut: A, C, HL, [rOCPS]
; @note: sets OCPSF_AUTOINC
gfx_ocp_load::
	ldh a, [rOCPS]
	or OCPSF_AUTOINC
	ldh [rOCPS], a
:
	ld a, [hl+]
	ldh [rOCPD], a
	ld a, [hl+]
	ldh [rOCPD], a
	dec c
	jr nz, :-
	ret


default_font:
	INCBIN "res/onebit-mono.1bpp", 0, ONEBIT_MONO_RES_SIZE
.end


; ColorW R, G, B
; Define a color, stored in a 2 byte word, encoded as RGB555 for CGB.
macro ColorW
	dw (($1F & (\3)) << 10) | (($1F & (\2)) << 5) | ($1F & (\1))
endm

def OCP_GREY equ 0      ; Index of OBJ colour palette 'grey'
def OCP_EGGPLANT equ 1  ; Index of OBJ colour palette 'eggplant'
def OCP_PINKLI equ 2    ; Index of OBJ colour palette 'pinkli'
def OCP_BLUEN equ 3     ; Index of OBJ colour palette 'bluen'

def BCP_EGGPLANT equ 0  ; Index of BG colour palette 'eggplant'
def BCP_PINKLI equ 1    ; Index of BG colour palette 'pinkli'
def BCP_BLUEN equ 2     ; Index of BG colour palette 'bluen'

def OCP_COUNT equ 4
def BCP_COUNT equ 3

ocp_start:
cpal_grey:
	ColorW 28, 28, 28
	ColorW 18, 18, 18
	ColorW 9, 9, 9
	ColorW 2, 2, 2

bcp_start:
cpal_eggplant:
	ColorW 27, 28, 26
	ColorW 21, 20, 18
	ColorW 12, 10, 11
	ColorW 4, 4, 5

cpal_pinkli:
	ColorW 27, 28, 26
	ColorW 25, 23, 24
	ColorW 13, 9, 12
	ColorW 7, 5, 7

cpal_bluen:
	ColorW 27, 28, 26
	ColorW 19, 22, 22
	ColorW 13, 14, 19
	ColorW 4, 4, 5


SECTION "GFXDATA", ROMX

BGTiles_data:
	INCBIN "res/map/terrain.2bpp"
BGTiles_data_end:


OBJTiles_data:
	INCBIN "res/shapes.2bpp"
	INCBIN "res/ball.2bpp"
	INCBIN "res/map/buildings.2bpp"
OBJTiles_data_end:
