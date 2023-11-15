if !def(APP_WORLD_INC)
def APP_WORLD_INC equ 1

include "common.inc"


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

def bThingStatus_HITS0     equ 0
def bThingStatus_HITS1     equ 1
def bThingStatus_EV_HIT    equ 5 ; Thing has been hit
def bThingStatus_EV_DIE    equ 6 ; Thing has died...
def bThingStatus_VOID      equ 7 ; Set to indicate Thing doesn't exist or is otherwise inactive.
def fThingStatus_HITS    equ $03 ; Mask 'HITS' part of Thing status.
def fThingStatus_EV_HIT  equ $20 ; Thing has been hit
def fThingStatus_EV_DIE  equ $40 ; Thing has died...
def fThingStatus_EV      equ $60 ; Mask all event bits
def fThingStatus_VOID    equ $80 ; Mask 'VOID' bit of Thing status.

	stdecl ThingInstance
		stfield status    ; status, hitpoints
		stfield y         ; Y position (screen pixels)
		stfield x         ; X position (screen pixels)
		stfield t         ; thing type / (initial) tile
		stfield attr      ; OAM attribute flags
		stfield collider  ; index/ID of Thing's Collider
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

	stdecl LoadedMapCache
		stfield source, w ; Address of loaded map.
		stfield columns ; The horizontal size of the loaded map, in tiles.
		stfield rows ; The vertical size of the loaded map, in tiles.
		stfield tee_x ; Tee-off X position
		stfield tee_y ; Tee-off Y position
		stfield terrain_size ; The resolution of the terrain heightmap.
		stfield things_count ; The number of Things in the scene.
	stclose

endc ; APP_WORLD_INC
