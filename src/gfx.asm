
include "defines.asm"
include "core/loado.inc"
include "res/onebit-mono.inc"
include "gfxmap.inc"

section "OBJ Tiles", vram[$8000]
vOBJTiles::

section "BG Tiles", vram[$8800]
vBGTiles::

section "UI Tiles", vram[$9000]
vFontTiles::


section "GFXLOADER", rom0

gfx_load_default_font::
	ld hl, vFontTiles
	ld de, default_font
	ld bc, default_font.end - default_font
	call vmem_copy_double
	ret


; load tile data for game objects
gfx_load_game_obj::
	ld de, LoadoPrg_LoadGameObj
	call loado_load_program
	call loado_exec
	ret


gfx_load_bg_tiles::
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
	incbin "res/onebit-mono.1bpp", 0, ONEBIT_MONO_RES_SIZE
.end


	ShrimpIncbin "res/shapes.2bpp"
	ShrimpIncbin "res/ball.2bpp"
	ShrimpIncbin "res/map/buildings.2bpp"
	ShrimpIncbin "res/map/terrain.2bpp"
	ShrimpIncbin "res/map/warships.2bpp"


LoadoPrg_LoadGameObj:
	db LOADOCODE_CHRB_0
	db LOADOCODE_SRC
	dw res_shapes_2bpp
	db LOADOCODE_DEST_CHR, tShapes
	db LOADOCODE_CHRCOPY, tShapes_count
	db LOADOCODE_SRC
	dw res_ball_2bpp
	db LOADOCODE_SRC_CHR, 0
	db LOADOCODE_DEST_CHR, tBall
	db LOADOCODE_CHRCOPY, tBall_count
	db LOADOCODE_STOP


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
