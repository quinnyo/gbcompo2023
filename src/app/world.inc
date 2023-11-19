if !def(APP_WORLD_INC)
def APP_WORLD_INC equ 1

include "common.inc"
include "app/things.inc"


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
; Default (clear value) terrain height value
def Map_TerrainDefaultHeight equ 255

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
Things chunk: a Thingcode program
*/
def MapChunk_Things equ 4
/*
Loado chunk: a Loado program for loading resources required by the map.
*/
def MapChunk_Loado equ 5


	stdecl World
		stfield xmin ; world bound left
		stfield ymin ; world bound top
		stfield xmax ; world bound right
		stfield ymax ; world bound bottom
		stfield tilemap, Map_MaxColumns * Map_MaxRows
		stfield terrain, Map_TerrainBufferSize ; Y offset of the *floor* (terrain)
	stclose

	stdecl LoadedMapCache
		stfield source, w ; Address of loaded map.
		stfield columns ; The horizontal size of the loaded map, in tiles.
		stfield rows ; The vertical size of the loaded map, in tiles.
		stfield tee_x ; Tee-off X position
		stfield tee_y ; Tee-off Y position
		stfield terrain_size ; The resolution of the terrain heightmap.
	stclose

endc ; APP_WORLD_INC
