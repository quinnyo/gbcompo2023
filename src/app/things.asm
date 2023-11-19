include "common.inc"
include "app/world.inc"
include "gfxmap.inc"


section "ThingsState", wram0
wThingsInfo::
	.just_hit::  db ; number of things that were hit in the most recent update
	.just_died:: db ; number of things that died in the most recent update
	.targets::   db ; number of things that are targets
	.count::     db
	.next::      dw ; pointer to end of wThings array

wThings:: ds Thing_sz * ThingsMax
def DRAW_LIST_SIZE equ 5 * ThingsMax
wDrawList: ds DRAW_LIST_SIZE

section "ThingsImpl", rom0

; (Re-)initialise Thing and set its new status.
; @param A: status
; @param HL: this
; @ret HL: this + Thing_sz
; @mut: AF, HL
Thing_init::
	ld [hl+], a ; status
	ld a, $FF
	ld [hl+], a ; collider
	ld [hl+], a ; pos.0
	ld [hl+], a ; pos.1
	ld [hl+], a ; draw_mode
	xor a
	ld [hl+], a ; drawable.0
	ld [hl+], a ; drawable.1
	ld [hl+], a ; on_die.0
	ld [hl+], a ; on_die.1

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
	ld bc, Thing_sz * ThingsMax
	ld d, fThingStatus_VOID
	call mem_fill

	jp _clear_draw_list


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
things_info_update::
	ld hl, wThings
	ld a, [wThingsInfo.count]
	ld e, a
	ld d, 0 ; targets
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
	bit bThingStatus_VOID, [hl]
	jr nz, .loop_things_continue

	bit bThingStatus_EV_DIE, [hl]
	jr z, .ev_die_done

	bit bThingStatus_TARGET, [hl]
	jr z, .target_done
	inc d
	res bThingStatus_TARGET, [hl]
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

	bit bThingStatus_EV_HIT, [hl]
	jr z, .ev_hit_done
	inc c             ; just_hit++
.ev_hit_done

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
; @mut: A, B, DE, HL
things_draw::
	call _clear_draw_list
	ld a, [wThingsInfo.count]
	and a
	ret z
	ld e, a
	ld bc, wThings
	ld hl, wDrawList
.loop_things
	ld a, [bc] ; ThingInstance.status
	bit bThingStatus_VOID, a
	jr z, .draw
	ld a, Thing_sz
	add c
	ld c, a
	adc b
	sub c
	ld b, a
	jr .loop_things_continue

.draw
	inc bc ; status
	inc bc ; collider
	; position
	ld a, [bc]
	inc bc
	ld [hl+], a ; X
	ld a, [bc]
	inc bc
	ld [hl+], a ; Y
	; draw_mode
	ld a, [bc]
	inc bc
	ld [hl+], a
	; drawable
	ld a, [bc]
	inc bc
	ld [hl+], a ; drawable.0
	ld a, [bc]
	inc bc
	ld [hl+], a ; drawable.1
	inc bc ; on_die.0
	inc bc ; on_die.1
.loop_things_continue
	dec e
	jr nz, .loop_things

	call oam_next_recall

	ld de, wDrawList
.draw_loop:
	ld a, [de]
	inc de
	ld b, a ; X
	ld a, [de]
	inc de
	ld c, a ; Y

	ld a, [de] ; draw_mode
	inc de
	; TODO: other draw_modes
.draw_oam
	ld a, c
	add OAM_Y_OFS
	ld [hl+], a ; y
	ld a, b
	add OAM_X_OFS
	ld [hl+], a ; x
	ld a, [de]
	inc de
	ld [hl+], a ; chr
	ld a, [de]
	inc de
	ld [hl+], a ; attr

	ld a, d
	cp high(wDrawList + DRAW_LIST_SIZE)
	jr c, .draw_loop
	ld a, e
	cp low(wDrawList + DRAW_LIST_SIZE)
	jr c, .draw_loop

	call oam_next_store

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

	; clear event flags and store status
	and ~fThingStatus_EV
	ld [bc], a
	and ~fThingStatus_HITS
	ld d, a ; stash status flags (not HP)

	inc bc ; to collider
	ld a, [bc]        ; Thing.collider
	dec bc ; back to status
	call Collide_get_status
	; check if collision started (detect leading edge)
	cp %01
	jr nz, .loop_things_continue
.handle_hit ; Thing has been hit
	set bThingStatus_EV_HIT, d
	ld a, [bc]
	and fThingStatus_HITS
	jr z, .handle_hit_done
	dec a
	jr nz, .handle_hit_done
	; Thing has been killed
	set bThingStatus_EV_DIE, d
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


_clear_draw_list:
	ld hl, wDrawList
	ld c, DRAW_LIST_SIZE
	ld a, $FF
	jp mem_fill_byte
