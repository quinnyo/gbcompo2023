
include "defines.asm"
include "world.inc"
include "gfxmap.inc"


section "ThingsState", wram0
wThings::
	.alive:: db ; number of things that haven't been hit
	.dead:: db ; number of things that have been hit


section "ThingsImpl", rom0

; Initialise Things manager. Call this after loading the map.
things_init::
	xor a
	ld [wThings.alive], a
	ld [wThings.dead], a
	call things_count
	ret


; Count all the things (as hit or not) and update the values in wThings.
; @ret B: Number of things that haven't been hit
; @ret C: Number of things that have been hit
; @ret D: Number of things that have been hit since last count
; @mut: A, HL
things_count::
	ld hl, wWorld.things
	ld b, 0
	ld c, 0
.loop_things
	ld a, [hl+] ; ThingInstance.hits
	cp 255 ; hits == 255 == inactive/empty
	jr z, .continue

	cp 1
	jr c, .zero
	; > 0
	inc c
	jr .continue
.zero
	inc b

.continue
	inc hl ; ThingInstance.y
	inc hl ; ThingInstance.x
	inc hl ; ThingInstance.t
	inc hl ; ThingInstance.attr

	ld a, h
	cp high(wWorld.things + World_things_sz)
	jr nz, .loop_things
	ld a, l
	cp low(wWorld.things + World_things_sz)
	jr nz, .loop_things

	ld a, [wThings.alive]
	sub b
	ld d, a
	ld a, b
	ld [wThings.alive], a
	ld a, c
	ld [wThings.dead], a

	ret



; Draw all the things
; @mut: A, B, DE, HL
things_draw::
	ld de, wWorld.things
	call oam_next_recall
.loop_things
	ld a, [de] ; ThingInstance.hits
	cp 255 ; hits == 255 == inactive/empty
	jr nz, .draw
	ld a, ThingInstance_sz
	add e
	ld e, a
	adc d
	sub e
	ld d, a
	jr .continue

.draw
	inc de
	ld b, a

	ld a, [de] ; ThingInstance.y
	inc de
	add OAM_Y_OFS
	ld [hl+], a
	ld a, [de] ; ThingInstance.x
	inc de
	add OAM_X_OFS
	ld [hl+], a
	ld a, [de] ; ThingInstance.t
	inc de
	add tThings
	add b
	ld [hl+], a
	ld a, [de] ; ThingInstance.attr
	inc de
	ld [hl+], a

.continue
	ld a, d
	cp high(wWorld.things + World_things_sz)
	jr nz, .loop_things
	ld a, e
	cp low(wWorld.things + World_things_sz)
	jr nz, .loop_things

	call oam_next_store

	ret
; @param B,C: Missile X,Y position
; @param   E: Missile radius
; @mut: A, HL
things_collide_ball::
	ld a, b
	cp 168
	ret nc
	ld a, c
	cp 152
	ret nc
	ld hl, wWorld.things + World_things_sz - 1
.loop_things
	dec hl ; attr
	dec hl ; t

	ld a, [hl-] ; ThingInstance.x
	sub e
	cp b
	jr nc, .nope_2
	add e
	add e
	add 8
	cp b
	jr c, .nope_2

	ld a, [hl-] ; ThingInstance.y
	sub e
	cp c
	jr nc, .nope_1
	add e
	add e
	add 8
	cp c
	jr c, .nope_1

	ld a, [hl] ; ThingInstance.hits
	and a
	jr nz, .nope_1
	inc a
	ld [hl-], a

	jr .continue

.nope_2
	dec hl ; y
.nope_1
	dec hl ; hits

.continue
	ld a, h
	cp high(wWorld.things)
	jr nc, .loop_things
	ld a, l
	cp low(wWorld.things)
	jr nc, .loop_things

	ret
