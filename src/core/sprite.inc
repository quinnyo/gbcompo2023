/***********************************************************
*                                               sprite.asm *
************************************************************
Multi-part sprite thingers...

SPRITE PARTS
A sprite part is essentially a single OAM object
***********************************************************/
if !def(CORE_SPRITE_INC)
def CORE_SPRITE_INC equ 1


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


; Mark the end of the sprite definition.
def SPRITE_PARTS_END equ $80

endc ; CORE_SPRITE_INC