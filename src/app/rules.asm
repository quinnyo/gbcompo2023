/* RULESES: A somewhat flexible game rules system. */

include "app/rules.inc"

; The capacity of the rule pool, in bytes.
def POOL_SIZE equ $FF
; Size of a Rule Header.
def RULE_HEADER_SIZE  equ $04

section "RulesBuffer", wram0
; The rule pool
wPOOL:      ds POOL_SIZE
.terminator: db
wPOOL_END: dw

wITER_NEXT: dw

wRulesScratch:: ds RULES_SCRATCH_BUFFER_SIZE

section "RulesManager", rom0
; Clear the rules buffer
; @mut: AF, BC, D, HL
Rules_clear::
	ld d, RULE_NULL
	ld hl, wPOOL
	ld bc, POOL_SIZE + 1 ; +1 for terminator byte
	call mem_fill
	ld hl, wPOOL_END
	ld a, low(wPOOL)
	ld [hl+], a
	ld a, high(wPOOL)
	ld [hl+], a
	jp Rules_iter_begin


; Checks the available space in the rules buffer. If there is enough space to
; add a new rule, returns the maximum allowed data block size.
; If there is not enough space to add a new rule, the carry flag will be set
; and **the result (in A) is not valid**.
; @return F(C): Carry flag is set if there is no space to add a new rule.
; @return A: Max new rule block size. *This value is only valid if F(NC)*.
; @return HL: (internal) 16 bit result == available buffer space minus 3.
; @mut: AF, HL
Rules_check_free::
	ld hl, wPOOL_END
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ld a, low(wPOOL + POOL_SIZE - RULE_HEADER_SIZE)
	sub l
	ld l, a
	ld a, high(wPOOL + POOL_SIZE - RULE_HEADER_SIZE)
	sbc h
	ld h, a

	ret c   ; F(C): negative result
	ld a, l
	ret z   ; F(Z): less than 256, result is value in L
	ld a, $FF
	ret ; F(NC) && F(NZ): there is more than 255 bytes spare


; Begin writing a new rule to the rule pool. This function allocates memory
; for the new rule and its parameters: after calling this function, you have
; to initialise the rule's parameters / data block.
; @param DE: Pointer to rule impl routine
; @param  C: Length of data block to allocate
; @return DE: Pointer to the start of the new rule's data block
; @mut: AF, DE, HL
Rules_create::
	call Rules_check_free
	jr c, .OUT_OF_MEM
	cp c
	jr c, .OUT_OF_MEM ; error if `requested > available`

	ld hl, wPOOL_END
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	; header
	ld a, RULE_STANDARD
	ld [hl+], a
	ld a, c
	ld [hl+], a
	ld a, e
	ld [hl+], a
	ld a, d
	ld [hl+], a
	; return value
	ld e, l
	ld d, h
	; update buffer end address
	ld a, c
	add l
	ld l, a
	ld [wPOOL_END + 0], a
	adc h
	sub l
	ld [wPOOL_END + 1], a
	ret
.OUT_OF_MEM: rst panic


; Add a new rule copied from memory.
; @param DE: pointer to rule dump, incl full header
; @mut: AF, BC, DE, HL
Rules_load::
	ld a, [de]
	inc de
	ld b, a
	ld a, [de]
	inc de
	ld c, a
	call Rules_check_free
	jr c, .OUT_OF_MEM
	cp c
	jr c, .OUT_OF_MEM
	ld hl, wPOOL_END
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	; type/flags
	ld a, b
	ld [hl+], a
	; data len
	ld a, c
	ld [hl+], a
	; rule func
	ld a, [de]
	inc de
	ld [hl+], a
	ld a, [de]
	inc de
	ld [hl+], a
	; copy data block
	call mem_copy_short
	; store pool end pointer
	ld a, l
	ld [wPOOL_END + 0], a
	ld a, h
	ld [wPOOL_END + 1], a
	ret
.OUT_OF_MEM: rst panic


; @return DE: first element pointer
; @return F(C): set if NEXT isn't at or past END
; @mut: AF, DE, HL
Rules_iter_begin:
	ld de, wPOOL
	ld hl, wITER_NEXT
	ld a, e
	ld [hl+], a
	ld [hl], d
	jr Rules_iter_next.check


; @return DE: next element pointer
; @return F(C): set if NEXT isn't at or past END
; @mut: AF, DE, HL
Rules_iter_next:
	ld hl, wITER_NEXT
	ld a, [hl+]
	ld e, a
	ld d, [hl]
.check
	; bounds check
	ld hl, wPOOL + POOL_SIZE - RULE_HEADER_SIZE
	ld a, d
	cp h
	ret c
	ld a, l
	cp e
	ccf
	ret


Rules_tick::
	call Rules_iter_begin
	jr .proc_rule
.loop_rules
	call Rules_iter_next
	ret nc ; at end
.proc_rule
	; type/flags
	ld a, [de]
	inc de
	cp RULE_STANDARD
	ret nz
	; push return address
	ld bc, .loop_rules
	push bc
	; dataLen
	ld a, [de]
	inc de
	ld c, a         ; dataLen
	; func ruleUpdate*
	ld a, [de]
	inc de
	ld l, a
	ld a, [de]
	inc de
	ld h, a
	; update 'iter next'
	ld a, e
	add c
	ld b, a
	ld [wITER_NEXT + 0], a
	adc d
	sub b
	ld [wITER_NEXT + 1], a
	;  C: dataLen
	; DE: &data
	; HL: &update()
	jp hl
