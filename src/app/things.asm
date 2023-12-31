include "common.inc"
include "app/world.inc"
include "gfxmap.inc"

def THINGS_BUFFER_SIZE equ Thing_sz * ThingsMax

section "ThingsState", wram0
wThingsInfo::
	.just_hit::  db ; number of things that were hit in the most recent update
	.just_died:: db ; number of things that died in the most recent update
	.targets::   db ; number of things that are targets
	.count:      db
	.next:       dw ; pointer to end of wThings array

wThings: ds THINGS_BUFFER_SIZE

section "ThingCache", hram
hThingCache:
	.x: db
	.y: db
	.drawable: dw

section "ThingsImpl", rom0

; (Re-)initialise Thing and set its new status.
; @param A: status
; @param HL: this
; @ret HL: this + Thing_sz
; @mut: AF, HL
Thing_init::
	ld [hl+], a ; status
	ld c, Thing_drawable - (Thing_status + 1)
	ld a, $FF
	call mem_fill_byte
	ld c, Thing_sz - Thing_drawable
	xor a
	call mem_fill_byte
	ret


; Initialise Things manager.
things_init::
	xor a
	ld hl, wThingsInfo.just_hit
	ld [hl+], a       ; just_hit
	ld [hl+], a       ; just_died
	ld [hl+], a       ; targets
	ld [hl+], a       ; count
	ld a, low(wThings)
	ld [hl+], a       ; next.0
	ld a, high(wThings)
	ld [hl+], a       ; next.1

	ld hl, wThings
	ld bc, THINGS_BUFFER_SIZE
	ld d, fThingStatus_VOID
	call mem_fill

	ret


; @param D: status
; @ret DE: pointer to initialised Thing
; @mut: AF, DE, HL
things_init_next::
	ld hl, wThingsInfo.count
	inc [hl]

	ld hl, wThingsInfo.next
	ld a, [hl+]
	ld h, [hl]
	ld l, a

	ld a, d ; A = status
	ld d, h
	ld e, l
	call Thing_init

	ld a, l
	ld [wThingsInfo.next], a
	ld a, h
	ld [wThingsInfo.next + 1], a

	ret


things_start::
	ld a, [wThingsInfo.count]
	and a
	ret z
	ld e, a
	ld d, 0 ; targets
	ld hl, wThings
.loop_things
	bit bThingStatus_TARGET, [hl]
	jr z, .continue
	inc d
.continue
	ld a, Thing_sz
	add l
	ld l, a
	adc h
	sub l
	ld h, a

	dec e
	jr nz, .loop_things

	ld a, d
	ld [wThingsInfo.targets], a

	ret


; Build up to date colliders from current Thing state.
; @mut: AF, BC, DE, HL
things_update_colliders::
	ld a, [wThingsInfo.count]
	and a
	ret z
	ld hl, wThings
.loop_things
	ld a, [hl]
	bit bThingStatus_VOID, a
	jr nz, .next
	and fThingStatus_HITS
	jr z, .next
	push hl
rept 1 + Thing_collider - Thing_status
	ld a, [hl+]
endr
	cp $FF
	jr z, .no_collider
	ld d, a     ; collider
	ld a, [hl+] ; pos.x
	ld b, a
	ld a, [hl+] ; pos.y
	ld c, a
	ld a, d
	call Collide_set_box_position
.no_collider
	pop hl
.next
	ld a, Thing_sz
	add l
	ld l, a
	adc h
	sub l
	ld h, a
	cp high(wThings + THINGS_BUFFER_SIZE)
	jr c, .loop_things
	ld a, l
	cp low(wThings + THINGS_BUFFER_SIZE)
	jr c, .loop_things
	ret


; Main Thing per-tick process routine.
; @mut: AF, BC, DE, HL
things_think::
	ld a, [wThingsInfo.count]
	and a
	ret z

	call _things_process_collisions

	ld bc, 0 ; count things died (B), things hit (C)
	ld d, 0 ; count targets destroyed
	ld hl, wThings
	ld a, [wThingsInfo.count]
	ld e, a
.loop_things
	ld a, [hl]        ; status
	bit bThingStatus_VOID, a
	jr nz, .loop_things_continue

	bit bThingStatus_EV_DIE, a
	jr z, .ev_die_done

	bit bThingStatus_TARGET, a
	jr z, .target_done
	inc d
	res bThingStatus_TARGET, a
.target_done

	inc b             ; just_died++
	push af
	push bc
	push de
	push hl
	call _Thing_die
	pop hl
	pop de
	pop bc
	pop af
.ev_die_done

	bit bThingStatus_EV_HIT, a
	jr z, .ev_hit_done
	inc c             ; just_hit++
.ev_hit_done

	; clear event flags and write status back out
	and ~fThingStatus_EV
	ld [hl], a

.loop_things_continue
	ld a, Thing_sz
	add l
	ld l, a
	adc h
	sub l
	ld h, a

	dec e
	jr nz, .loop_things

	; store info/counts
	ld hl, wThingsInfo.just_hit
	ld a, c
	ld [hl+], a         ; just_hit
	ld a, b
	ld [hl+], a         ; just_died
	ld a, [hl]
	sub d
	ld [hl], a          ; targets

	ret


; @param HL: this
; @mut: AF, BC, DE, HL
_Thing_die:
	ld e, l
	ld d, h

	ld a, Thing_on_die
	add l
	ld l, a
	adc h
	sub l
	ld h, a

	ld a, [hl+]
	ld c, a
	ld a, [hl+]
	ld b, a

	or c
	ret z

	call tcm_load_program

	call tcm_set_thing_de
	call tcm_update_cache

	call tcm_run

	ret


; Draw all the things
; @mut: AF, BC, DE, HL
things_draw::
	ld a, [wThingsInfo.count]
	and a
	ret z
	ld hl, wThings
.loop_things
	bit bThingStatus_VOID, [hl]
	jr nz, .skip
	push hl
rept Thing_pos - Thing_status
	ld a, [hl+]
endr
	ld a, [hl+]    ; .pos.x
	ld b, a
	ld a, [hl+]    ; .pos.y
	ld c, a
	ld a, [hl+]    ; .draw_mode
	cp fThingDrawMode_Sprite
	; NOTE: preserving flags from CP above -- LD only
	ld a, [hl+]
	ld e, a
	ld a, [hl+]
	ld d, a
	call oam_next_recall
	jr nz, .draw_mode_oam
.draw_mode_sprite
	call Sprite_draw
	jr .draw_end
.draw_mode_oam
	ld a, c
	add OAM_Y_OFS
	ld [hl+], a ; y
	ld a, b
	add OAM_X_OFS
	ld [hl+], a ; x
	ld a, e
	ld [hl+], a ; chr
	ld a, d
	ld [hl+], a ; attr
.draw_end
	call oam_next_store
	pop hl         ; HL <= Thing*
.skip
	ld a, Thing_sz
	add l
	ld l, a
	adc h
	sub l
	ld h, a
.loop_things_continue
	ld a, h
	cp high(wThings + THINGS_BUFFER_SIZE)
	jr c, .loop_things
	ld a, l
	cp low(wThings + THINGS_BUFFER_SIZE)
	jr c, .loop_things
	ret


; Check each thing's collision status.
; Apply hits and raise relevant event status flags.
; @mut: AF, BC, DE, HL
_things_process_collisions::
	ld a, [wThingsInfo.count]
	and a
	ret z
	ld e, a
	ld bc, wThings
.loop_things
	ld a, [bc]       ; ThingInstance.status
	bit bThingStatus_VOID, a
	jr nz, .loop_things_continue
	; D <= status, preserve status flags (not HP)
	and ~fThingStatus_HITS
	ld d, a
	; to collider
rept Thing_collider - Thing_status
	inc bc
endr
	ld a, [bc]                    ; collider
	; back to status
rept Thing_collider - Thing_status
	dec bc
endr
	call Collide_get_status
	; check if collision started (detect leading edge)
	cp %01
	jr nz, .loop_things_continue
.handle_hit ; Thing has been hit
	ld a, [bc]                    ; status
	set bThingStatus_EV_HIT, a
	and fThingStatus_HITS ; just hits
	jr z, .handle_hit_done
	dec a                 ; hits--
	jr nz, .handle_hit_done
	; Thing has been killed
	set bThingStatus_EV_DIE, a
.handle_hit_done
	; recombine HP (A) with status flags (D)
	or d
	ld [bc], a
.loop_things_continue
	; move to next Thing
	ld a, Thing_sz
	add c
	ld c, a
	adc b
	sub c
	ld b, a
	dec e
	jr nz, .loop_things
	ret


; Find the first Thing with a tag matching the provided value.
; @param B: query tag
; @mut: AF, C, HL
; @return F.C: set if no match found
; @return HL: found Thing*
TagThings_query_tag::
	ld a, [wThingsInfo.count]
	and a
	jr z, .not_found
	ld c, a
	ld hl, wThings
.loop
	bit bThingStatus_VOID, [hl]
	jr nz, .continue
	inc hl      ; .status
	ld a, [hl-] ; .tag
	cp b
	ret z ; return NC (CP set Z so must be)
.continue
	ld a, Thing_sz
	add l
	ld l, a
	adc h
	sub l
	ld h, a
	dec c
	jr nz, .loop
.not_found
	ld hl, 0
	scf
	ret


; Mark the Thing with tag as destroyed (if found).
; @param B: query tag
; @mut: AF, C, HL
TagThings_kill::
	call TagThings_query_tag
	ret c
	set bThingStatus_EV_DIE, [hl]
	ret
