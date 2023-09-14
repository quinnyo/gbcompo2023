IF !DEF(INPUT_INC)
DEF INPUT_INC EQU 1


;******************************************************************************
;* Macros to define Input system
;******************************************************************************

;; DefInputRead W_STATE, W_PRESSED, W_RELEASED
;; Create the 'read' routine
;; USAGE:
;; 	MyInput.Read::
;; 		DefInputRead wMyInput.state[, wMyInput.pressed[, wMyInput.released]]
MACRO DefInputRead
	ASSERT !DEF(_ARG_W_STATE) && !DEF(_ARG_W_PRESSED) && !DEF(_ARG_W_RELEASED)
	ASSERT _NARG >= 1
	DEF _ARG_W_STATE EQUS \1
	IF _NARG >= 2
		DEF _ARG_W_PRESSED EQUS \2
	ENDC
	IF _NARG >= 3
		DEF _ARG_W_RELEASED EQUS \3
	ENDC

;; input 'read' impl
	di

	; BUTTONS
	ld a, P1F_GET_BTN
	ldh [rP1], a
REPT 6 ; ~18 cycles
	ldh a, [rP1]
ENDR
REPT 2
	ld b, a
	ldh a, [rP1]
	or b
ENDR
	or $F0
	ld b, a ; B = buttons (0 == CLOSED)

	; DPAD
	ld a, P1F_GET_DPAD
	ldh [rP1], a
REPT 2 ; ~twice
	ldh a, [rP1]
ENDR
	or $F0
	swap a
	xor b ; combine dpad with buttons (also inverts, so 1 == CLOSED)

IF DEF(_ARG_W_PRESSED) || DEF(_ARG_W_RELEASED)
	; update pressed / released buttons
	ld b, a ; (B) = new state
	ld a, [_ARG_W_STATE] ; (A) = previous state
	xor b
	ld c, a ; (C) = keys that changed

IF DEF(_ARG_W_PRESSED)
	and b ; (A) = keys that changed to pressed
	ld [_ARG_W_PRESSED], a
ENDC ; DEF(_W_PRESSED)

	ld a, b ; (A) = new state
ENDC ; DEF(_W_PRESSED) || DEF(_W_RELEASED)

	ld [_ARG_W_STATE], a

IF DEF(_ARG_W_RELEASED)
	cpl
	and c
	ld [_ARG_W_RELEASED], a
ENDC ; DEF(_W_RELEASED)

	ld a, P1F_GET_NONE
	ldh [rP1], a

	ei

	ret
;; end input 'read impl

	PURGE _ARG_W_STATE, _ARG_W_PRESSED, _ARG_W_RELEASED
ENDM ; DefInputRead


ENDC ; INPUT_INC
