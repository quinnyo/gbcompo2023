include "defines.asm"
include "maths.inc"


section "Texto State", wram0
wTexto:
	; target X window position
	.wx: db
	; target Y window position
	.wy: db

	; .homex: db
	; .homey: db
	.penx: db
	.peny: db


section "Texto", rom0

Texto_init::
	xor a
	ld [wTexto.wx], a
	ld [wTexto.wy], a
	ld [wTexto.penx], a
	ld [wTexto.peny], a

	ld d, "."
	ld hl, $9C00
	ld bc, BGMAP_LEN
	call vmem_fill

	call Texto_hide

	ret


Texto_update::
	ld a, [wTexto.wx]
	ldh [rWX], a

	ld a, 1
	ld c, a ; C = max iters
.update_y
	ldh a, [rWY]
	ld b, a ; B = window Y
	ld a, [wTexto.wy]
	cp b
	ret z
	jr c, .ygt
.ylt ; WY < target
	; going down, just jump directly to target
	ld a, b
	inc a
	ldh [rWY], a

	jr .update_y_loop

.ygt ; WY > target
	; going up, do slidey time
	ld a, b
	dec a
	ldh [rWY], a

.update_y_loop
	dec c
	jp nz, .update_y

	ret


; Shows number of lines written to.
Texto_show::
	ld a, [wTexto.peny]
	jr Texto_show_lines


Texto_show_none::
	xor a
	jr Texto_show_lines


; @param A: number of lines to make visible
Texto_show_lines::
	ld b, a
	ld a, 144
:
	sub 8
	dec b
	jr nz, :-

	ld [wTexto.wy], a

	ld a, 7
	ld [wTexto.wx], a

	ret


Texto_hide::
	ld a, 7
	ld [wTexto.wx], a
	ldh [rWX], a
	ld a, 144
	ld [wTexto.wy], a
	ldh [rWY], a
	ret


Texto_pen_home::
	xor a
	; ld, a, [wTexto.homex]
	ld [wTexto.penx], a
	; ld, a, [wTexto.homey]
	ld [wTexto.peny], a
	ret


; Write text from a block of memory.
; @param de: source
; @param b: length
Texto_writeln::
	call Texto_pen_update

.loop
	ld a, [wTexto.penx]
	cp 20
	call nc, Texto_linefeed

	WaitVRAM
	ld a, [de]
	ld [hl+], a

	ld a, [wTexto.penx]
	inc a
	ld [wTexto.penx], a

	inc de
	dec b
	jr nz, .loop

	call Texto_linefeed

	ret


Texto_linefeed::
	xor a
	ld [wTexto.penx], a
	ld a, [wTexto.peny]
	inc a
	ld [wTexto.peny], a

	jr Texto_pen_update


; Set HL from pen position
Texto_pen_update::
	; pen tilemap offset = peny * 32 + penx
	ld hl, $9C00
	ld a, [wTexto.peny]
	sla a  ; y << 1 = y*2
	swap a ; effectively y << 4 (y*2*2*2*2 = y*16)
	addrrua hl
	ld a, [wTexto.penx]
	addrrua hl
	ret


/**********************************************************
* DECIMAL
**********************************************************/

; Print a (up to) three digit unsigned integer.
; @param  A: value to print
; @param HL: destination address
; @mut: BC
digi_print_u8::
.hundreds
	ld b, 100
	cp b
	jr nc, :+
	ld c, " "
	jr .put_hundreds
:

	ld c, "0"
	call digit_thing
.put_hundreds
	ld [hl], c
	inc hl

.tens
	ld b, 10
	cp b
	jr nc, :+
	ld c, " "
	jr .put_tens
:

	ld c, "0"
	call digit_thing
.put_tens
	ld [hl], c
	inc hl

.ones
	ld c, "0"
	ld b, 1
	call digit_thing
	ld [hl], c
	inc hl
	ret


; Print a 2 digit unsigned integer. Prints "99" if value is over 99.
; @param  A: value to print
; @param HL: destination address
; @mut: BC
digi_print_u8_99::
	cp 100
	jr c, :+
	ld c, "9"
	ld [hl], c
	inc hl
	ld [hl], c
	inc hl
	ret
:

	jr digi_print_u8.tens


; Reduce A by repeatedly subtracting B from it until A < B.
; Increment C for every subtraction performed.
; @param A: value
; @param B: divisor
; @param C: initial value
; @ret C: number of times A reduced
digit_thing:
:
	cp b
	ret c
	sub b
	inc c
	jr :-
	ret


/**********************************************************
* HEXADECIMAL
**********************************************************/

hexit_table:
	db "0123456789ABCDEF"

; print low nybble of A as hexadecimal digit.
; writes the character to HL
; (i)  A: the value to print
; (i) HL: destination
; (o) HL: HL + 1
; (!)  A, DE
hexit_print_nybble::
	and $0F
	ld de, hexit_table
	add e
	ld e, a
	adc d
	sub e
	ld d, a

	; Wait for accessible VRAM before writing each character...
	; TODO: Maybe buffer the formatted characters somewhere?
	;       So they can be copied to VRAM all at once (later)...
	WaitVRAM

	ld a, [de]
	ld [hl+], a

	ret


; Print the value in `A` as a hexadecimal number.
; (i)  A: the value to print
; (i) HL: destination
; (o) HL: HL + 2
; (!)  A, B, DE
hexit_print_byte::
	ld b, a
	swap a
	call hexit_print_nybble
	ld a, b
	jr hexit_print_nybble


; Get the character value to print a hexadecimal number.
; @param A: the number to look up. Only the lower 4 bits will be used.
; @return A: the mapped character ID
; @smashes: DE
hexit_lookup::
	and a, $0F
	ld de, hexit_table
	add e
	ld e, a
	adc d
	sub e
	ld d, a

	ld a, [de]

	ret

