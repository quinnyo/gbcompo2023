INCLUDE "defines.asm"
INCLUDE "input.inc"


;******************************************************************************
;* wInput
;******************************************************************************

SECTION "Input State", WRAM0
wInput::
	; Current controller state (as of the most recent input.update)
	.state:: db
	; Keys that became pressed in the most recent update.
	.pressed:: db
	; Keys that became unpressed in the most recent update.
	.released:: db
	; Input configuration and status flags
	.flags:: db
	; History of each key's state for the last 8 frames.
	; Each byte is one key/dir -- in the same order as PADB_*
	.hist::
	.hist_a:: db
	.hist_b:: db
	.hist_select:: db
	.hist_start:: db
	.hist_right:: db
	.hist_left:: db
	.hist_up:: db
	.hist_down:: db

	.held::
	.held_a:: db
	.held_b:: db
	.held_select:: db
	.held_start:: db
	.held_right:: db
	.held_left:: db
	.held_up:: db
	.held_down:: db


;******************************************************************************
;* input routines
;******************************************************************************

SECTION "Input", ROM0

;; input.init
;; Initialise/reset input state.
input_init::
	ld hl, startof("Input State")
	xor a
	ld c, sizeof("Input State")
:
	ld [hl+], a
	dec c
	jr nz, :-

	ret


;; input.update
;; Reads controller port, updates wInput.
;; Handles
input_update::
	; abort if LCD is off
	ldh a, [rLCDC]
	bit 7, a
	ret z

	call input_read

	; update hist
	ld a, [wInput.state]
	ld b, a
	ld c, 8
	ld hl, wInput.hist
:
	ld a, [hl]
	sla a
	bit 0, b
	jr z, .continue
	or 1
.continue
	ld [hl+], a
	srl b
	dec c
	jr nz, :-

	; update held timers
	ld a, [wInput.pressed]
	ld b, a
	ld a, [wInput.state]
	xor b
	ld b, a ; B = held (not pressed)
	xor a
	ld c, 8
.held_loop
	bit 0, b
	jr z, .held_cont
	ld a, [hl]
	cp $FF
	jr nc, .held_cont
	inc a
.held_cont
	ld [hl+], a
	xor a
	srl b
	dec c
	jr nz, .held_loop


	ret


; Update XY input state, using directional input
; @param B: input state bitmask
; @param D,E: current X,Y state
; @param H,L: delta X,Y magnitude
; @ret D,E: updated X,Y state
InputXY_read::
	ld a, d
	bit PADB_RIGHT, b
	jr z, :+
	add h
:
	bit PADB_LEFT, b
	jr z, :+
	sub h
:
	ld d, a

	ld a, e
	bit PADB_DOWN, b
	jr z, :+
	add l
:
	bit PADB_UP, b
	jr z, :+
	sub l
:
	ld e, a

	ret


input_read::
	DefInputRead "wInput.state", "wInput.pressed", "wInput.released"
