if !def(WORLD_INC)
def WORLD_INC equ 1

include "defines.asm"


; The address being used for displaying the world tilemap.
def World_Tilemap equ $9800

; Maximum width of a map (X), in tiles.
def Map_MaxColumns equ 24
; Maximum height of a map (Y), in tiles.
def Map_MaxRows equ 24
; Size in pixels of a map cell (tile).
def Map_CellSize equ 8

; Terrain subdivision depth.
def Map_TerrainSubdiv equ 0
; Number of terrain heightmap columns.
def Map_TerrainBufferSize equ (Map_MaxColumns * Map_CellSize) >> Map_TerrainSubdiv

def MapChunk_End equ 0
def MapChunk_Info equ 1
/*
BG tilemap chunk:
+ tiles: byte[map_columns * map_rows] // tile IDs (row-major)
*/
def MapChunk_Tiles equ 2
; Terrain heightmap chunk
def MapChunk_Terrain equ 3
/*
Things chunk:
+ thing_count: byte // length of things array
+ things: byte[thing_count] // things array
Each thing (ThingDef) is:
ThingDef {
	meta: byte   // always 0
	y:    byte   // Thing Y position
	x:    byte   // Thing X position
	t: byte   // Thing (initial) TILE ID
}
*/
def MapChunk_Things equ 4
/*
Loado chunk: a Loado program for loading resources required by the map.
*/
def MapChunk_Loado equ 5

def ThingsMax equ 20

	stdecl ThingInstance
		stfield hits ; hit counter / status
		stfield y ; Y position (screen pixels)
		stfield x ; X position (screen pixels)
		stfield t ; thing type / (initial) tile
		stfield attr ; OAM attribute flags
	stclose

	stdecl World
		stfield xmin ; world bound left
		stfield ymin ; world bound top
		stfield xmax ; world bound right
		stfield ymax ; world bound bottom
		stfield tilemap, Map_MaxColumns * Map_MaxRows
		stfield terrain, Map_TerrainBufferSize ; Y offset of the *floor* (terrain)
		stfield things, ThingInstance_sz * ThingsMax
	stclose

	stdecl MapInfo
		stfield source, w ; Address of loaded map.
		stfield columns ; The horizontal size of the loaded map, in tiles.
		stfield rows ; The vertical size of the loaded map, in tiles.
		stfield tee_x ; Tee-off X position
		stfield tee_y ; Tee-off Y position
		stfield terrain_size ; The resolution of the terrain heightmap.
		stfield things_count ; The number of Things in the scene.
	stclose

endc ; WORLD_INC
