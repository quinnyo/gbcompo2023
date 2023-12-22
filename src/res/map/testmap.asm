include "app/world.inc"
include "core/loado.inc"
include "gfxmap.inc"
include "core/sprite.inc"


def CHRSRC_A0_0     equ 0
def CHRSRC_A0_1     equ 1
def CHRSRC_A0_2     equ 2
def CHRSRC_A1_0     equ 3
def CHRSRC_A1_1     equ 4
def CHRSRC_A1_2     equ 5
def CHRSRC_A2_0     equ 6
def CHRSRC_A2_1     equ 7
def CHRSRC_A2_2     equ 8
def CHRSRC_B1_0_F1  equ 18 ; (2, 1)
def CHRSRC_B1_1_F0  equ 19 ; (3, 1)
def CHRSRC_B1_0_F0  equ 34 ; (2, 2)
def CHRSRC_B1_2_F0  equ 35 ; (3, 2)

rsset tThings
def CHR_A0_0     rb 1
def CHR_A0_1     rb 1
def CHR_A0_2     rb 1
def CHR_A1_0     rb 1
def CHR_A1_1     rb 1
def CHR_A1_2     rb 1
def CHR_A2_0     rb 1
def CHR_A2_1     rb 1
def CHR_A2_2     rb 1
def CHR_B1_0_F1  rb 1
def CHR_B1_1_F0  rb 1
def CHR_B1_0_F0  rb 1
def CHR_B1_2_F0  rb 1


section "map_testmap", romx

sprite_B1_0:
	SpritePart 0, 0, CHR_B1_0_F0, 0
	SpritePart 8, 0, CHR_B1_0_F1, 0
	SpriteEnd
sprite_B1_1:
	SpritePart 0, 0, CHR_B1_1_F0, 0
	SpriteEnd
sprite_B1_2:
	SpritePart 0, 0, CHR_B1_2_F0, 0
	SpriteEnd


thing_A0:
	DefThingLegacy CHR_A0_0, 0

thing_A1:
	DefThingLegacy CHR_A1_0, 32

thing_A2:
	DefThingLegacy CHR_A2_0, 0

thing_B1_0:
	ThingcNew
	ThingcDrawSprite sprite_B1_0
	ThingcPosition 32, 32
	ThingcCollideTile
	ThingcDieGoto thing_B1_F0_1
	ThingcSave
	ThingcStop
thing_B1_F0_1:
	ThingcDrawSprite sprite_B1_1
	ThingcHits 1
	ThingcDieGoto thing_B1_F0_2
	ThingcSave
	ThingcStop
thing_B1_F0_2:
	ThingcDrawSprite sprite_B1_2
	ThingcDieGoto 0
	ThingcSave
	ThingcStop

map_testmap::

.chunk0:
	dw .chunk1 ; next chunk
	db MapChunk_Info
	.columns: db 22
	.rows: db 18
	.tee_x: db 12
	.tee_y: db 96

.chunk1:
	dw .chunk2 ; next chunk
	db MapChunk_Loado
	db LOADOCODE_CHRB_1
	LoadocodeROMB "res/map/terrain.2bpp"
	db LOADOCODE_SRC
	dw res_map_terrain_2bpp
	db LOADOCODE_SRC_CHR, 2
	db LOADOCODE_CHRCOPY, 5
	db LOADOCODE_SRC_CHR, 8
	db LOADOCODE_CHRCOPY, 1
	db LOADOCODE_SRC_CHR, 10
	db LOADOCODE_CHRCOPY, 4
	db LOADOCODE_SRC_CHR, 15
	db LOADOCODE_CHRCOPY, 1
	db LOADOCODE_SRC_CHR, 24
	db LOADOCODE_CHRCOPY, 1
	db LOADOCODE_SRC_CHR, 26
	db LOADOCODE_CHRCOPY, 2
	db LOADOCODE_SRC_CHR, 57
	db LOADOCODE_CHRCOPY, 1
	db LOADOCODE_SRC_CHR, 60
	db LOADOCODE_CHRCOPY, 1
	db LOADOCODE_SRC_CHR, 68
	db LOADOCODE_CHRCOPY, 1
	db LOADOCODE_SRC_CHR, 74
	db LOADOCODE_CHRCOPY, 1
	db LOADOCODE_SRC_CHR, 81
	db LOADOCODE_CHRCOPY, 1
	db LOADOCODE_SRC_CHR, 84
	db LOADOCODE_CHRCOPY, 1
	db LOADOCODE_SRC_CHR, 125
	db LOADOCODE_CHRCOPY, 3
	db LOADOCODE_STOP
.chunk2:
	dw .chunk3 ; next chunk
	db MapChunk_Loado
	db LOADOCODE_CHRB_0
	db LOADOCODE_DEST_CHR, CHR_A0_0
	LoadocodeROMB "res/map/buildings.2bpp"
	db LOADOCODE_SRC
	dw res_map_buildings_2bpp
	db LOADOCODE_SRC_CHR, CHRSRC_A0_0
	db LOADOCODE_CHRCOPY, 3
	db LOADOCODE_SRC_CHR, CHRSRC_A1_0
	db LOADOCODE_CHRCOPY, 3
	db LOADOCODE_SRC_CHR, CHRSRC_A2_0
	db LOADOCODE_CHRCOPY, 3
	db LOADOCODE_SRC_CHR, CHRSRC_B1_0_F1
	db LOADOCODE_CHRCOPY, 2
	db LOADOCODE_SRC_CHR, CHRSRC_B1_0_F0
	db LOADOCODE_CHRCOPY, 2
	db LOADOCODE_STOP
.chunk3:
	dw .chunk4 ; next chunk
	db MapChunk_Tiles
	.tiles:
		db $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94
		db $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94, $94
		db $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95
		db $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95
		db $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95
		db $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96
		db $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96
		db $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96
		db $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $91, $8A, $96, $96, $96, $96, $96, $96, $96, $96, $96
		db $96, $96, $96, $96, $96, $96, $96, $96, $96, $96, $83, $95, $86, $96, $96, $96, $96, $96, $96, $96, $96, $96
		db $96, $90, $96, $96, $96, $96, $96, $96, $96, $85, $95, $95, $8F, $96, $96, $96, $96, $96, $96, $96, $96, $96
		db $96, $93, $96, $96, $96, $96, $96, $96, $96, $8B, $95, $95, $8C, $96, $96, $96, $96, $96, $96, $96, $96, $96
		db $92, $92, $92, $92, $92, $92, $92, $92, $83, $95, $95, $95, $88, $92, $92, $92, $92, $92, $92, $92, $92, $92
		db $96, $96, $96, $96, $96, $96, $96, $85, $95, $95, $95, $95, $80, $80, $87, $96, $96, $96, $96, $96, $96, $96
		db $96, $96, $96, $96, $96, $96, $96, $8B, $95, $95, $95, $95, $95, $95, $8D, $96, $96, $96, $96, $96, $96, $96
		db $96, $96, $96, $96, $96, $96, $83, $95, $95, $95, $95, $95, $95, $95, $95, $80, $81, $89, $82, $96, $96, $96
		db $96, $96, $96, $96, $96, $85, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $81, $82, $96
		db $96, $96, $96, $96, $96, $8E, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $84

.chunk4:
	dw .chunk5 ; next chunk
	db MapChunk_Terrain
	.heightmap_size: db 176
	.heightmap:
		db 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255
		db 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255
		db 255, 255, 255, 255, 255, 255, 255, 255, 144, 142, 140, 138, 136, 133, 131, 129
		db 127, 126, 125, 124, 123, 122, 121, 120, 119, 117, 115, 113, 111, 109, 107, 105
		db 103, 102, 101, 100,  99,  98,  97,  96,  95,  93,  91,  89,  87,  85,  83,  81
		db  80,  78,  77,  76,  75,  74,  73,  72,  71,  70,  69,  69,  68,  68,  68,  68
		db  68,  68,  68,  69,  80,  82,  84,  87,  95, 104, 104, 104, 104, 104, 104, 104
		db 105, 106, 108, 110, 112, 114, 116, 118, 120, 120, 120, 120, 120, 120, 120, 120
		db 120, 120, 121, 121, 122, 122, 123, 123, 124, 124, 124, 124, 124, 124, 124, 124
		db 124, 124, 125, 125, 126, 126, 127, 127, 128, 128, 129, 129, 130, 130, 131, 131
		db 132, 132, 133, 133, 134, 134, 135, 135, 136, 136, 137, 138, 139, 139, 140, 141

.chunk5:
	dw .chunkEnd ; next chunk
	db MapChunk_Things
	ThingcInstance thing_A0
	ThingcPosition 119, 112
	ThingcSave
	ThingcInstance thing_A1
	ThingcPosition 92, 61
	ThingcSave
	ThingcInstance thing_A2
	ThingcPosition 106, 96
	ThingcSave
	ThingcInstance thing_B1_0
	ThingcPosition 137, 116
	ThingcSave
	ThingcStop

.chunkEnd:
	dw 0 ; next chunk
	db MapChunk_End
