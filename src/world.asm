include "defines.asm"
include "world.inc"

/*
	world.asm

	- The (current) scene
	- Tools to query the scene
	- Collision detection bits?
*/


section "World State", wram0

	st World, wWorld
	st MapInfo, wMap

wNextChunk: dw

section "World Impl", rom0


world_init::
	ZeroSection "World State"

	ld de, World_default
	ld hl, wWorld
	ld bc, World_default.end - World_default
	call mem_copy

	ld hl, wWorld.things
	ld c, World_things_sz
	ld a, 255 ; thing.hits == 255 is inactive
	call mem_fill_byte

	ret


; Look up terrain height in column containing `pX`.
; @param A: pX
; @return A: Terrain height
; @return HL: address of terrain column that contains `pX`
world_get_terrain_column::
rept Map_TerrainSubdiv
	srl a
endr

	; clamp to terrain buffer range
	def _CLAMP_MARGIN equ (256 - Map_TerrainBufferSize) >>> 1
	cp 255 - _CLAMP_MARGIN ; clamp to start (zero) if closer to start than end
	jr c, :+
	xor a
:
	cp Map_TerrainBufferSize ; clamp to end
	jr c, :+
	ld a, Map_TerrainBufferSize - 1
:

	ld hl, wWorld.terrain
	add l
	ld l, a
	adc h
	sub l
	ld h, a

	ld a, [hl]

	ret


; Convert a pixel position (pX,pY) to a tilemap address.
; HL = $9800 + cX + cY * 32
; @param B,C: pX,pY (pixels)
; @return HL: Tile address
; @mut: A
world_point_to_tile::
	; `cY = pY / 8`
	; we need `cY * 32`, so do `pY * 2 * 2` instead of `(pY / 2 / 2 / 2) * 2 * 2 * 2`.
	ld a, c
	and a, %11111000 ; Mask to snap down to multiple of 8
	ld l, a
	ld h, 0 ; (HL = cY * 8)
	add hl, hl ; = cY * 16
	add hl, hl ; = cY * 32
	; `cX = pX / 8`
	ld a, b
	srl a ; = cX / 2
	srl a ; = cX / 4
	srl a ; = cX / 8
	; Add the two offsets together.
	add a, l
	ld l, a
	adc a, h
	sub a, l
	; Add tilemap start address
	add $98
	ld h, a
	ret


; Find collisions with each side of the world/scene bounds.
; @param B,C: pX,pY
; @return E: bitmask with SIDEB_* set if colliding that side.
; @mut: A
world_point_collide_bounds::
	ld e, 0 ; result

	ld a, [wWorld.xmax]
	cp b
	jr nc, :+
	set SIDEB_RIGHT, e
:
	ld a, [wWorld.xmin]
	cp b
	jr c, :+
	set SIDEB_LEFT, e
:
	ld a, [wWorld.ymax]
	cp c
	jr nc, :+
	set SIDEB_BOTTOM, e
:
	ld a, [wWorld.ymin]
	cp c
	jr c, :+
	set SIDEB_TOP, e
:

	ret


; @mut: A, C, HL
world_clear_terrain::
	ld hl, wWorld.terrain
	ld c, Map_TerrainBufferSize
	xor a
:
	ld [hl+], a
	dec c
	jr nz, :-

	ret


; @param DE: source address
world_load_map::
	ld hl, wMap
	; store map address
	ld a, e
	ld [hl+], a
	ld a, d
	ld [hl+], a

	; initial "next" chunk address
	ld hl, wNextChunk
	ld a, e
	ld [hl+], a
	ld a, d
	ld [hl+], a


.loop
	; get chunk address
	ld hl, wNextChunk
	ld a, [hl+]
	ld d, [hl]
	ld e, a ; DE = next chunk

	or d
	ret z ; next chunk == 0 => end of map data

	; get new next chunk address
	ld hl, wNextChunk
	ld a, [de]
	inc de
	ld [hl+], a
	ld a, [de]
	inc de
	ld [hl+], a

	; chunk type
	ld a, [de]
	inc de
	cp MapChunk_End
	ret z
	cp MapChunk_Info
	jr z, .load_info
	cp MapChunk_Tiles
	jr z, .load_tiles
	cp MapChunk_Terrain
	jr z, .load_terrain
	cp MapChunk_Things
	jr z, .load_things
	cp MapChunk_Loado
	jr z, .load_loado

	jr .loop

.load_info:
	call world_load_map_info
	jr .loop

.load_tiles:
	ld a, [wMap.columns]
	ld b, a
	ld a, [wMap.rows]
	ld c, a
	call world_load_tilemap
	jr .loop

.load_terrain:
	; Map.terrain_size
	ld a, [de]
	inc de
	ld [wMap.terrain_size], a
	ld c, a
	; Map.terrain
	call world_load_terrain
	jr .loop

.load_things:
	; Map.things_count
	ld a, [de]
	inc de
	ld [wMap.things_count], a
	ld c, a
	call world_load_things
	jr .loop

.load_loado:
	call loado_load_program ; DE is already program entry point
	call loado_exec
	jr .loop

; Load map info chunk
; @param DE: source address
world_load_map_info:
	; Map.columns
	ld a, [de]
	inc de
	ld [wMap.columns], a
	; Map.rows
	ld a, [de]
	inc de
	ld [wMap.rows], a
	; Map.tee_x
	ld a, [de]
	inc de
	ld [wMap.tee_x], a
	; Map.tee_y
	ld a, [de]
	inc de
	ld [wMap.tee_y], a
	ret


; Map Loading: loads heightmap terrain into the world.
; @param DE: source address
; @param  C: resolution of source terrain
world_load_terrain:
	; clamp C and check for C == 0
	ld a, c
	and Map_TerrainBufferSize | (Map_TerrainBufferSize - 1)
	ret z
	ld c, a

	ld hl, wWorld.terrain
:
	ld a, [de]
	ld [hl+], a
	inc de
	dec c
	jr nz, :-

.done
	ret


; load verbatim ("normal") tilemap
; @param DE: source address
; @param  B: columns
; @param  C: rows
; @mut: A, HL
world_load_tilemap:
	ld hl, wWorld.tilemap

.loop_y
	push bc

.loop_x
	ld a, [de]
	inc de
	ld [hl+], a
	dec b
	jr nz, .loop_x

	pop bc
	ld a, Map_MaxColumns
	sub b
	add l
	ld l, a
	adc h
	sub l
	ld h, a

	dec c
	jr nz, .loop_y

	ret


; @param  C: Map.things_count
; @param DE: source address
world_load_things:
	ld hl, wWorld.things
.loop
	xor a
	ld [hl+], a ; ThingInstance.hits
	inc de ; ThingDef.meta
	ld a, [de] ; ThingDef.y
	inc de
	ld [hl+], a ; ThingInstance.y
	ld a, [de] ; ThingDef.x
	inc de
	ld [hl+], a ; ThingInstance.x
	ld a, [de] ; ThingDef.t
	inc de
	ld [hl+], a ; ThingInstance.t
	ld a, [de] ; ThingDef.oam_attr
	inc de
	ld [hl+], a ; ThingInstance.attr

	dec c
	jr nz, .loop

	ret


; Display world tilemap (copy it to VRAM)
; @mut: A, BC, DE, HL
world_display_tilemap::
	ld hl, World_Tilemap
	ld de, wWorld.tilemap
	; copy whole buffer even if we don't need to...
	ld b, Map_MaxColumns
	ld c, Map_MaxRows

; ; Copy a world tilemap rect to a location in VRAM
; ; @param HL: destination address
; ; @param DE: source address
; ; @param B,C: width,height of rect to copy
; world_copy_tilemap:
.loop_y
	push bc

.loop_x
	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, .loop_x
	ld a, [de]
	ld [hl+], a
	inc de
	dec b
	jr nz, .loop_x

	pop bc
	ld a, 32
	sub b
	add l
	ld l, a
	adc h
	sub l
	ld h, a

	dec c
	jr nz, .loop_y

	ret


section "World Data", romx
World_default:
	.xmin: db 4
	.ymin: db 4
	.xmax: db SCRN_X + 4
	.ymax: db SCRN_Y + 4
.end
