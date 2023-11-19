include "app/world.inc"
include "core/loado.inc"
include "gfxmap.inc"

section "map_testmap", romx


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
	db LOADOCODE_DEST_CHR, tThings
	LoadocodeROMB "res/map/buildings.2bpp"
	db LOADOCODE_SRC
	dw res_map_buildings_2bpp
	db LOADOCODE_SRC_CHR, 0
	db LOADOCODE_CHRCOPY, 6
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
	dw .chunk6 ; next chunk
	db MapChunk_Things
	.things:
		PlaceThingLegacy 61, 92, 3, 32
		PlaceThingLegacy 96, 106, 3, 32
		ThingcStop

.chunk6:
	dw .chunkEnd ; next chunk
	db MapChunk_Things
	.things2:
	.c6t0:
		ThingcNew
		ThingcDrawOAM tThings, 0
		ThingcPosition 119, 112
		ThingcCollideTile
		ThingcDieGoto .c6t0_destroyed0
		ThingcSave
		ThingcStop
	.c6t0_destroyed0:
		ThingcDrawOAM tThings + 1, 0
		ThingcHits 1
		ThingcDieGoto .c6t0_destroyed1
		ThingcSave
		ThingcStop
	.c6t0_destroyed1:
		ThingcDrawOAM tThings + 2, 0
		ThingcDieGoto 0
		ThingcSave
		ThingcStop


.chunkEnd:
	dw 0 ; next chunk
	db MapChunk_End



println "Thing_sz: {u:Thing_sz}"
