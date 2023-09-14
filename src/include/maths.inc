IF !DEF(MATHS_INC)
DEF MATHS_INC EQU 1


macro sext
	add a
	sbc a
endm


; addrrua \R
; Add unsigned int in A to \R
macro addrrua
	def _H equs strsub("\1", 1, 1)
	def _L equs strsub("\1", 2, 1)

	add _L
	ld _L, a
	adc _H
	sub _L
	ld _H, a

	purge _H, _L
endm


; Add signed int in A to \R16
macro addrrsa
	def _H equs strsub("\1", 1, 1)
	def _L equs strsub("\1", 2, 1)

	cp $80
	jr c, .pos\@
	dec _H
.pos\@
	; add unsigned
	add _L
	ld _L, a
	adc _H
	sub _L
	ld _H, a

	purge _H, _L
endm


; subrrua \R
; Subtract unsigned int in A from \R.
macro subrrua
	def _H equs strsub("\1", 1, 1)
	def _L equs strsub("\1", 2, 1)

	cpl
	scf
	adc _L
	ld _L, a
	ld a, -1
	adc _H
	ld _H, a

	purge _H, _L
endm


; subrrsa \R16
; Subtract signed int in A from \R16
macro subrrsa
	def _H equs strsub("\1", 1, 1)
	def _L equs strsub("\1", 2, 1)

	cpl
	cp $80
	jr c, .pos\@
	dec _H
.pos\@
	adc _L
	ld _L, a
	adc _H
	sub _L
	ld _H, a

	purge _H, _L
endm


; add16 Ll, Rr
macro add16
	def _L0 equs strsub("\1", 1, 1)
	def _L1 equs strsub("\1", 2, 1)
	def _R0 equs strsub("\2", 1, 1)
	def _R1 equs strsub("\2", 2, 1)

	ld a, {_L1}
	add {_R1}
	ld {_L1}, a
	ld a, {_L0}
	adc {_R0}
	ld {_L0}, a

	purge _L0, _L1, _R0, _R1
endm


; sub16 Ll, Rr
macro sub16
	def _L0 equs strsub("\1", 1, 1)
	def _L1 equs strsub("\1", 2, 1)
	def _R0 equs strsub("\2", 1, 1)
	def _R1 equs strsub("\2", 2, 1)

	ld a, {_L1}
	sub {_R1}
	ld {_L1}, a
	ld a, {_L0}
	sbc {_R0}
	ld {_L0}, a

	purge _L0, _L1, _R0, _R1
endm



; `cp 0` but works with any (8 or 16 bit) register.
; Sets F.Z if value in \R is equal to zero.
macro cp_zero
	assert _NARG == 1 || _NARG == 0

if _NARG == 0 || strcmp(strupr("\1"), "A") == 0
	; A
elif strlen("\1") == 2
	ld a, HIGH(\1)
	or LOW(\1)
elif strlen("\1") == 1
	ld a, \1
endc

	cp 0
endm


; signc R
; Set (C) to the sign bit of R
; R can be 8 or 16 bit
; A: destroyed
macro signc
if strlen("\1") == 2
	ld a, HIGH(\1)
elif strlen("\1") == 1
	ld a, \1
endc
	rla
endm


; ndza
; NuDge value in A toward Zero.
; Increments/decrements A if value in A is below/above zero, respectively.
; Does nothing if A is equal to zero.
macro ndza
	cp 0
	jr z, .end\@
	cp $80
	jr c, .pos\@
	; negative
	inc a
	jr .end\@
.pos\@: ; positive
	dec a
.end\@:
endm


; ndz \R
; NuDge value in \R toward Zero.
; Increments/decrements value in \R if value is below/above zero, respectively.
; \R can be 8 or 16 bit register.
; uses: A
macro ndz
	assert _NARG == 1
if strcmp(strupr("\1"), "A") == 0
	ndza
else
	cp_zero \1
	jr z, .end\@
	signc \1
	jr nc, .pos\@
	; negative
	inc \1
	jr .end\@
.pos\@: ; positive
	dec \1
.end\@:
endc
endm

ENDC
