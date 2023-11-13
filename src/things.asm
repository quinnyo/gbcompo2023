include "common.inc"
include "app/world.inc"
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


things_init_colliders::
	ld hl, wWorld.things
	ld e, ThingsMax
.loop_things
	ld a, [hl+]       ; ThingInstance.hits
	ld d, a
	ld a, [hl+]       ; ThingInstance.y
	ld c, a
	ld a, [hl+]       ; ThingInstance.x
	ld b, a
	inc hl            ; ThingInstance.t
	inc hl            ; ThingInstance.attr

	bit 7, d
	jr nz, .continue

	push hl           ; TODO: not this
	call Collide_add_box
	ld d, a           ; D = collider index...
	ld a, b
	ld [hl+], a       ; left
	add 8
	jr nc, :+
	ld a, 255
:
	ld [hl+], a       ; right
	ld a, c
	ld [hl+], a       ; top
	add 8
	jr nc, :+
	ld a, 255
:
	ld [hl+], a       ; bottom

	pop hl            ; TODO: not this

	ld [hl], d        ; store collider index

.continue
	inc hl            ; ThingInstance.collider
	dec e
	jr nz, .loop_things

	ret


things_think::
	ld bc, wWorld.things
	ld e, ThingsMax
.loop_things
	ld a, [bc]       ; ThingInstance.hits
	ld d, a
	bit 7, d
	jr z, :+
	ld a, ThingInstance_sz
	add c
	ld c, a
	adc b
	sub c
	ld b, a
	jr .continue
:

	push bc                  ; LAZY

	; --> collider
	ld a, ThingInstance_collider - ThingInstance_hits
	add c
	ld c, a
	adc b
	sub c
	ld b, a

	ld a, [bc]        ; ThingInstance.collider
	inc bc ; next thing

	; check most recent result (bit 0)
	call Collide_get_status
	pop hl                  ; LAZY
	bit 0, a
	jr z, .continue   ; no collide
	bit 1, a
	jr nz, .continue  ; already colliding
	ld a, [hl]
	cp 2
	jr nc, .continue
	inc a
	ld [hl], a

.continue
	dec e
	jr nz, .loop_things

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
	ld a, [hl]
	bit 7, a
	jr nz, .continue  ; inactive/empty

	cp 1
	jr c, .zero
	; > 0
	inc c
	jr .continue
.zero
	inc b

.continue
	ld a, ThingInstance_sz
	add l
	ld l, a
	adc h
	sub l
	ld h, a

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
	bit 7, a
	jr z, .draw
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
	inc de     ; ThingInstance.collider

.continue
	ld a, d
	cp high(wWorld.things + World_things_sz)
	jr nz, .loop_things
	ld a, e
	cp low(wWorld.things + World_things_sz)
	jr nz, .loop_things

	call oam_next_store

	ret
