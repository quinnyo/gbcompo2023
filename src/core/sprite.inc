/***********************************************************
*                                               sprite.asm *
************************************************************
Multi-part sprite thingers...

SPRITE PARTS
A sprite part is essentially a single OAM object
***********************************************************/
if !def(CORE_SPRITE_INC)
def CORE_SPRITE_INC equ 1

include "hardware.inc"


; Mark the end of the sprite definition.
def SPRITE_PARTS_END equ $80


; SpritePart YC, XC, CHR, [OAM_ATTR]
; `YC`, `XC` is the location of the origin *in the tile*:
; - The tile will be moved such that its point (YC, XC) will be at the origin.
; - e.g. `4, 4` will display the tile centered at the object's position.
macro SpritePart
	if _NARG == 3
		SpritePartRaw OAM_Y_OFS - (\1), OAM_X_OFS - (\2), (\3), 0
	elif _NARG == 4
		SpritePartRaw OAM_Y_OFS - (\1), OAM_X_OFS - (\2), (\3), (\4)
	else
		fail "SpritePart requires 3 or 4 arguments but got {u:_NARG}."
	endc
endm


; SpritePartRaw Y, X, CHR, OAM_ATTR
; Define an OAM-equivalent sprite part.
macro SpritePartRaw
	if _NARG != 4
		fail "SpritePartRaw requires 4 arguments but got {u:_NARG}."
	else
		assert (\1) != SPRITE_PARTS_END, "Sprite Part Y == SPRITE_PARTS_END"
		db (\1), (\2), (\3), (\4)
	endc
endm


; Marks the end of the sprite.
macro SpriteEnd
	db SPRITE_PARTS_END
endm


/***********************************************************
*                                                  QUARTET *
************************************************************
Utility to help generate 2x2 sprite defs.

Quartet sprite parts are indexed as row-major 2x2 matrix:
	0, 1
	2, 3

Expects tile / sprite sheet layout to follow the pattern:
	; 4 2x2 sprites here: a, b, c, d
	[a0,a1,b0,b1,c0,c1,d0,d1]    ; row of top tiles (0, 1)
	[a2,a3,b2,b3,c2,c3,d2,d3]    ; row of bottom tiles (2, 3)
loaded into VRAM sequentially:
	a0,a1,b0,b1,c0,c1,d0,d1,a2,a3,b2,b3,c2,c3,d2,d3
	^.......................^
	row stride = offset between top (a0) and bottom (a2) rows

***********************************************************/


def QUARTET_FLIP_NONE equ 0
def QUARTET_FLIP_HORI equ OAMF_XFLIP
def QUARTET_FLIP_VERT equ OAMF_YFLIP
def QUARTET_FLIP_BOTH equ QUARTET_FLIP_HORI | QUARTET_FLIP_VERT


; THISMACRO CHR0, ROW_STRIDE, OAM_ATTR, [Y, X]
; @param CHR0: CHR code of first quarter
; @param ROW_STRIDE: CHR code difference between rows
; @param OAM_ATTR: OAM attribute flags
; @param Y, X: offset all parts by this
macro QUARTET
	if _NARG == 5
		def _Y equ (\1)
		def _X equ (\2)
		shift 2
	elif _NARG == 3
		def _Y equ 0
		def _X equ 0
	else
		fail fatal, "bad bad things"
	endc

	def _CHR0 equ $00 + (\1)
	def _CHR1 equ $01 + (\1)
	def _CHR2 equ $00 + (\1) + (\2)
	def _CHR3 equ $01 + (\1) + (\2)

/*
	; To flip a multipart sprite, some (flipped) tiles need to be swapped.
	; Note that the order of the parts (in terms of their position) is kept consistent.
	; We only change where the _CHR* indices land.
	(NONE)   |  (HORIZ)
	[ A  B   |  Bh Ah ]
	[ C  D   |  Dh Ch ]
	[-----------------]
	[ Cv Dv  |  D^ C^ ]
	[ Av Bv  |  B^ A^ ]
	(VERT)   |   (BOTH)
*/
	def _FLIP equ (\3) & (QUARTET_FLIP_BOTH)
	if _FLIP == QUARTET_FLIP_NONE
		SpritePart 8 + _Y, 8 + _X, _CHR0, (\3)
		SpritePart 8 + _Y, 0 + _X, _CHR1, (\3)
		SpritePart 0 + _Y, 8 + _X, _CHR2, (\3)
		SpritePart 0 + _Y, 0 + _X, _CHR3, (\3)
	elif _FLIP == QUARTET_FLIP_HORI
		SpritePart 8 + _Y, 8 + _X, _CHR1, (\3)
		SpritePart 8 + _Y, 0 + _X, _CHR0, (\3)
		SpritePart 0 + _Y, 8 + _X, _CHR3, (\3)
		SpritePart 0 + _Y, 0 + _X, _CHR2, (\3)
	elif _FLIP == QUARTET_FLIP_VERT
		SpritePart 8 + _Y, 8 + _X, _CHR2, (\3)
		SpritePart 8 + _Y, 0 + _X, _CHR3, (\3)
		SpritePart 0 + _Y, 8 + _X, _CHR0, (\3)
		SpritePart 0 + _Y, 0 + _X, _CHR1, (\3)
	else ; flip both
		SpritePart 8 + _Y, 8 + _X, _CHR3, (\3)
		SpritePart 8 + _Y, 0 + _X, _CHR2, (\3)
		SpritePart 0 + _Y, 8 + _X, _CHR1, (\3)
		SpritePart 0 + _Y, 0 + _X, _CHR0, (\3)
	endc

	purge _CHR0, _CHR1, _CHR2, _CHR3, _FLIP, _Y, _X
endm


endc ; CORE_SPRITE_INC