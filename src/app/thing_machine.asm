include "app/things.inc"


section "wThingMachine", wram0
wThingMachine::
	stalloc ThingMachine, ., ::

wThingCache::
	stalloc Thing, ., :


section "ThingMachine", rom0

; Clear machine context.
; @mut: AF, C, HL
tcm_init::
	xor a
	ld c, ThingMachine_sz
	ld hl, wThingMachine
	call mem_fill_byte
	ld c, Thing_sz
	ld hl, wThingCache
	jp mem_fill_byte


; Load a Thing program and prepare to start.
; @param BC: program to load
; @mut: AF, BC, HL
tcm_load_program::
	ld hl, wThingMachine.status
	; clear STOP flag
	res bThingMachineStatus_STOP, [hl]
	inc hl
	ld a, c
	ld [hl+], a ; prg.0
	ld a, b
	ld [hl+], a ; prg.1

	ret


; Set the machine's thing pointer from HL, but don't flush the working data.
; @param HL: Thing*
; @mut: AF
tcm_set_thing::
	ld a, [wThingMachine.status]
	set bThingMachineStatus_CACHE_DIRTY, a
	ld [wThingMachine.status], a

	ld a, l
	ld [wThingMachine.thing + 0], a
	ld a, h
	ld [wThingMachine.thing + 1], a

	ret


; Set the machine's thing pointer from DE, but don't flush the working data.
; @param DE: Thing*
; @mut: AF, DE, HL
tcm_set_thing_de::
	ld hl, wThingMachine.status
	set bThingMachineStatus_CACHE_DIRTY, [hl]

	ld hl, wThingMachine.thing
	ld a, e
	ld [hl+], a
	ld [hl], d

	ret


; copy thing data to cache
; @param DE: Thing*
; @mut: AF, C, DE, HL
tcm_update_cache::
	ld hl, wThingMachine.status
	res bThingMachineStatus_CACHE_DIRTY, [hl]
	ld hl, wThingCache
	ld c, Thing_sz
	jp mem_copy_short


; Store cached changes to actual Thing instance.
; @mut: AF, C, DE, HL
tcm_finalise::
	ld hl, wThingMachine.thing
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ld de, wThingCache
	ld c, Thing_sz
	jp mem_copy_short


; Run machine until program stops.
tcm_run::
	jr .continue
.loop
	call tcm_step
.continue
	ld hl, wThingMachine.status
	ld a, [hl]
	and fThingMachineStatus_STOP
	jr z, .loop

	ret


; Step machine forward once -- read and execute the next instruction.
; @mut: AF, BC, DE, HL
tcm_step::
	ld hl, wThingMachine.status
	bit bThingMachineStatus_STOP, [hl]
	ret nz
	bit bThingMachineStatus_CACHE_DIRTY, [hl]
	jr z, :+
	res bThingMachineStatus_CACHE_DIRTY, [hl]
	ld hl, wThingMachine.thing
	ld a, [hl+]
	ld d, [hl]
	ld e, a
	ld hl, wThingCache
	ld c, Thing_sz
	call mem_copy_short
:

	ld hl, wThingMachine.prg
	ld a, [hl+]
	ld h, [hl]
	ld l, a

	; get next instruction
	ld a, [hl+]
	cp tc__COUNT
	jr nc, .err

	ld b, a

	; load instruction param/s (up to 2 bytes) into DE
	cp tc1
	jr c, .read0
	cp tc2
	jr c, .read1
.read2
	ld e, [hl]
	inc hl
.read1
	ld d, [hl]
	inc hl
.read0
	; store updated prg pointer
	ld a, l
	ld [wThingMachine.prg + 0], a
	ld a, h
	ld [wThingMachine.prg + 1], a

	ld a, b
	add a ; double instruction -> table offset
	rst jump_switch
	; tc0
	dw _tcx_New
	dw _tcx_Save
	dw _tcx_Stop
	dw _tcx_CollideTile
	; tc1
	dw _tcx_Hits
	; tc2
	dw _tcx_Goto
	dw _tcx_Instance
	dw _tcx_Position
	dw _tcx_DrawOAM
	dw _tcx_DieGoto

.err
	di
	ld b, b
	halt
	jr .err


_tcx_New::
	; create a new Thing instance and load it as the current context
	ld d, fThingStatus_DEFAULT
	call things_init_next
	jp tcm_set_thing_de


_tcx_Save::
	; save current changes
	jp tcm_finalise


_tcx_Stop::
	ld hl, wThingMachine.status
	set bThingMachineStatus_STOP, [hl]
	ret


_tcx_CollideTile::
	call Collide_add_box
	ld d, a           ; D = collider index...
	ld a, [wThingCache.pos + 0]
	ld [hl+], a       ; left
	add 8
	jr nc, :+
	ld a, 255
:
	ld [hl+], a       ; right
	ld a, [wThingCache.pos + 1]
	ld [hl+], a       ; top
	add 8
	jr nc, :+
	ld a, 255
:
	ld [hl+], a       ; bottom

	ld hl, wThingCache.collider
	ld [hl], d

	ret


; @param D: new HITS value
_tcx_Hits::
	ld hl, wThingCache.status
	ld a, [hl]
	and ~fThingStatus_HITS
	or d
	ld [hl], a
	ret


; @param DE: destination address
_tcx_Goto::
	ld hl, wThingMachine.prg
	ld a, e
	ld [hl+], a
	ld a, d
	ld [hl+], a
	ret


; run another program in this context
; @param DE: address of subprogram
_tcx_Instance::
	; push machine state to stack
	ld hl, wThingMachine.status
	ld a, [hl+]
	push af           ; push status
	ld a, [hl+]
	ld c, a
	ld b, [hl]
	push bc           ; push prg

	; setup machine for subprogram
	ld a, fThingMachineStatus_OK
	ld [hl+], a
	ld a, e
	ld [hl+], a       ; prg.0
	ld a, d
	ld [hl+], a       ; prg.0

	call tcm_run

	; restore machine state from stack -- in reverse
	ld hl, wThingMachine.prg + 1
	pop bc            ; pop prg
	ld a, b
	ld [hl-], a
	ld a, c
	ld [hl-], a
	pop af            ; pop status
	ld [hl], a

	ret


; @param D: Y
; @param E: X
_tcx_Position::
	ld hl, wThingCache.pos
	ld a, e
	ld [hl+], a
	ld [hl], d
	ret


; @param D: OAM_ATTR
; @param E: OAM_CHR
_tcx_DrawOAM::
	ld hl, wThingCache.draw_mode
	ld a, fThingDrawMode_OAM
	ld [hl+], a       ; draw_mode
	ld a, e
	ld [hl+], a       ; drawable.0 (OAM_CHR)
	ld a, d
	ld [hl+], a       ; drawable.1 (OAM_ATTR)
	ret


; @param DE: address of program
_tcx_DieGoto::
	ld hl, wThingCache.on_die
	ld a, e
	ld [hl+], a
	ld [hl], d
	ret
