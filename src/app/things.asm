include "common.inc"
include "app/world.inc"
include "gfxmap.inc"


section "ThingsState", wram0
wThings::
	.just_hit::  db ; number of things that were hit in the most recent update
	.just_died:: db ; number of things that died in the most recent update
	.alive::  db ; number of things that are alive


section "ThingsImpl", rom0
; Initialise Things manager. Call this after loading the map.
things_init::
	xor a
	ld hl, wThings.just_hit
	ld [hl+], a       ; just_hit
	ld [hl+], a       ; just_died
	ld a, [wMap.things_count]
	ld [hl+], a       ; alive

	ret


things_init_colliders::
	ld hl, wWorld.things
	ld e, ThingsMax
.loop_things
	ld a, [hl+]       ; ThingInstance.status
	ld d, a
	ld a, [hl+]       ; ThingInstance.y
	ld c, a
	ld a, [hl+]       ; ThingInstance.x
	ld b, a
	inc hl            ; ThingInstance.t
	inc hl            ; ThingInstance.attr

	bit bThingStatus_VOID, d
	jr nz, .loop_things_continue

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

.loop_things_continue
	inc hl            ; ThingInstance.collider
	dec e
	jr nz, .loop_things

	ret


; Main Thing per-tick process routine.
; @mut: AF, BC, DE, HL
things_think::
	call _things_process_collisions

	ld bc, 0
	ld hl, wWorld.things
	ld e, ThingsMax
.loop_things
	bit bThingStatus_VOID, [hl]
	jr nz, .loop_things_continue

	bit bThingStatus_EV_DIE, [hl]
	jr z, .ev_die_done
	inc b             ; just_died++
.ev_die_done

	bit bThingStatus_EV_HIT, [hl]
	jr z, .ev_hit_done
	inc c             ; just_hit++
.ev_hit_done

.loop_things_continue
	ld a, ThingInstance_sz
	add l
	ld l, a
	adc h
	sub l
	ld h, a

	dec e
	jr nz, .loop_things

	ld hl, wThings.just_hit
	ld a, c
	ld [hl+], a
	ld a, b
	ld [hl+], a
	ld a, [hl]
	sub b
	ld [hl], a

	ret


; Draw all the things
; @mut: A, B, DE, HL
things_draw::
	ld bc, wWorld.things
	ld e, ThingsMax
.loop_things
	ld a, [bc] ; ThingInstance.status
	bit bThingStatus_VOID, a
	jr z, .draw
	ld a, ThingInstance_sz
	add c
	ld c, a
	adc b
	sub c
	ld b, a
	jr .loop_things_continue

.draw
	call oam_next_recall

	inc bc ; status
	ld a, [bc] ; ThingInstance.y
	inc bc
	add OAM_Y_OFS
	ld [hl+], a
	ld a, [bc] ; ThingInstance.x
	inc bc
	add OAM_X_OFS
	ld [hl+], a
	ld a, [bc] ; ThingInstance.t
	inc bc
	add tThings
	ld [hl+], a
	ld a, [bc] ; ThingInstance.attr
	inc bc
	ld [hl+], a
	inc bc     ; ThingInstance.collider

	call oam_next_store

.loop_things_continue
	dec e
	jr nz, .loop_things

	ret


; Check each thing's collision status.
; Apply hits and raise relevant event status flags.
; @mut: AF, BC, DE, HL
_things_process_collisions::
	ld bc, wWorld.things
	ld e, ThingsMax
.loop_things
	ld a, [bc]       ; ThingInstance.status
	bit bThingStatus_VOID, a
	jr z, :+
	ld a, ThingInstance_sz
	add c
	ld c, a
	adc b
	sub c
	ld b, a
	jr .loop_things_continue
:
	; clear event flags and store status
	and ~fThingStatus_EV
	ld [bc], a

	push bc                  ; LAZY

	; --> collider
	ld a, ThingInstance_collider - ThingInstance_status
	add c
	ld c, a
	adc b
	sub c
	ld b, a

	ld a, [bc]        ; ThingInstance.collider
	inc bc            ; next thing

	; check most recent result (bit 0)
	call Collide_get_status
	pop hl                  ; LAZY
	bit 0, a
	jr z, .loop_things_continue   ; no collide
	bit 1, a
	jr nz, .loop_things_continue  ; already colliding

.stat_update
	; keep non-hits status in D
	ld a, [hl]
	and ~fThingStatus_HITS
	ld d, a
	set bThingStatus_EV_HIT, d

	; get status again, isolate hits
	ld a, [hl]
	and fThingStatus_HITS
	jr z, .stat_done
	dec a
	jr nz, .stat_done
	; Thing has been destroyed
	set bThingStatus_EV_DIE, d
.stat_done
	; store recombined hits (A) with non-hits status (D)
	or d
	ld [hl], a

.loop_things_continue
	dec e
	jr nz, .loop_things

	ret
