if !def(DEFINES_INC)
def DEFINES_INC equ 1


include "hardware.inc"
	rev_Check_hardware_inc 4.8


; Size of the tilemap in bytes.
def BGMAP_LEN equ $0400


include "res/onebit-mono.inc"


def SIDEB_LEFT    equ 0
def SIDEB_RIGHT   equ 1
def SIDEB_TOP     equ 2
def SIDEB_BOTTOM  equ 3

def SIDEF_LEFT    equ 1 << SIDEB_LEFT
def SIDEF_RIGHT   equ 1 << SIDEB_RIGHT
def SIDEF_TOP     equ 1 << SIDEB_TOP
def SIDEF_BOTTOM  equ 1 << SIDEB_BOTTOM


; Wait until safe to access VRAM (Mode 0-1)
; @mut A
macro WaitVRAM
	ldh a, [rSTAT]	;+2
	and STATF_BUSY	;+1
	jr nz, @ - 4 	;+1=4
endm


macro WaitVBL
	ldh a, [rSTAT]
	and STATF_VBL
	jr nz, @ - 4
endm


; LoadAt X:a16, Q
; Write `Q` to the address stored in `X`, low byte first.
; @mut A
macro LoadAt
	ld a, LOW(\2)
	ld [\1], a
	ld a, HIGH(\2)
	ld [(\1) + 1], a
endm


macro ZeroSection
	ld hl, startof(\1)
if sizeof(\1) < 256
	ld c, sizeof(\1)
	xor a
	call mem_fill_byte
else
	ld bc, sizeof(\1)
	ld d, 0
	call mem_fill
endc
endm


/**********************************************************
MODES
ModeDef
**********************************************************/
def MODES_COUNT = 0 ; Number of defined Modes

; ModeDef NAME, INIT, MAIN_ITER
macro ModeDef
	assert _NARG == 3
	def _INIT equs "\2"
	def _MAIN_ITER equs "\3"
	def _IPFX equs "Mode{u:MODES_COUNT}"
	def {_IPFX}_name equs \1
	def {_IPFX}_init equs "{_INIT}"
	def {_IPFX}_main_iter equs "{_MAIN_ITER}"
	export {_IPFX}_name, {_IPFX}_init, {_IPFX}_main_iter
	def _PFX equs strcat("Mode", \1)
	def {_PFX} equ MODES_COUNT
	def {_PFX}_init equs "{_INIT}"
	def {_PFX}_main_iter equs "{_MAIN_ITER}"
	export {_PFX}, {_PFX}_init, {_PFX}_main_iter
	def MODES_COUNT += 1
	purge _PFX, _IPFX, _INIT, _MAIN_ITER
endm


/*
st struct thing usage example:
{{{
	stdecl Robot
		stfield status             ; byte by default
		stfield love, l            ; l for long (`dl`), and longing
		stfield memories, w, 32    ; array of 32 words (`dw`)
		stfield dreams, 0          ; 0 byte field ...
	stclose

	section "RobotState", wram0
		; a Robot for everyone to enjoy
		st Robot, aRobot
		; a squad of Robots ...
		for i, 8
			st Robot, squadbot_{u:i}
		endr

	; meanwhile, back in the ROM...
	ld bc, Robot_love ; offset to the `love` field
	ld hl, aRobot.memories

	ld hl, squadbot_0 + Robot_memories
	ld bc, Robot_sz                     ; size of robot struct in bytes
	add hl, bc                          ; HL = squadbot_1.memories
}}}

THINGS
	# Struct root
	{STRUCT}_sz
		size of STRUCT in bytes
	{STRUCT}_len
		number of fields in STRUCT

	# Fields
	^^ {FIELD} can be field name or field index ^^
	{STRUCT}_{FIELD}
		field offset in struct
	{STRUCT}_{FIELD}_type
		field type, stored as the size of the type in bytes
		(rather than 'b|w|l' char passed to stfield)
	{STRUCT}_{FIELD}_len
		field entry count | array length
	{STRUCT}_{FIELD_NAME}_i (field by name only)
		field index
	{STRUCT}_{FIELD_IDX}_name (field by index only)
		field name
*/


; stdecl NAME
; Create a new struct called NAME and enter the struct declaration scope.
; Must be followed (after any struct fields) by a matching `stclose`.
macro stdecl
	if def(_STRUCTNAME)
		fail "struct {_STRUCTNAME} already open. Nested stdecl unsupported."
	endc
	def _STRUCTNAME equs "\1"
	def _STRUCT_SIZE = 0
	def _STRUCT_FIELD_COUNT = 0
endm


; stclose
; Required to end a struct declaration.
macro stclose
	; assert fatal, def(_STRUCTNAME), "struct_close outside of struct declaration"
	if !def(_STRUCTNAME)
		fail "stclose outside of struct declaration"
	else
		def {_STRUCTNAME}_sz equ _STRUCT_SIZE
		def {_STRUCTNAME}_len equ _STRUCT_FIELD_COUNT
		purge _STRUCTNAME, _STRUCT_SIZE, _STRUCT_FIELD_COUNT
	endc
endm


; stfield NAME, [N]
; stfield NAME, TYPE, [N]
; Declare a named struct field, with configurable type and size.
; NAME: the name of the field, used verbatim (so be nice)
; TYPE: one of {b,w,l} -- byte, word, long respectively.
; N: count (or array length)
; If no TYPE is specified, byte is assumed.
macro stfield
	if !def(_STRUCTNAME)
		fail "stfield outside of struct declaration"
	else
		def _NAME equs "\1"
		shift
		if _NARG > 0
			if strcmp("b", strlwr("\1")) == 0
				def _TYPE equ 1
			elif strcmp("w", strlwr("\1")) == 0
				def _TYPE equ 2
			elif strcmp("l", strlwr("\1")) == 0
				def _TYPE equ 4
			else
				def _TYPE equ 1
				def _LEN equ (\1)
			endc
			shift
		else
			def _TYPE equ 1
		endc

		if _NARG == 0 && !def(_LEN)
			def _LEN equ 1
		elif _NARG > 0 && !def(_LEN)
			def _LEN equ (\1)
			shift
		elif _NARG > 0
			fail "stfield: bad args"
		endc

		def _IPFX equs "{_STRUCTNAME}_{u:_STRUCT_FIELD_COUNT}"
		def {_IPFX} equ _STRUCT_SIZE
		def {_IPFX}_type equ _TYPE
		def {_IPFX}_len equ _LEN
		def {_IPFX}_sz equ _TYPE * _LEN
		def {_IPFX}_name equs "{_NAME}"
		def _PFX equs "{_STRUCTNAME}_{_NAME}"
		def {_PFX} equ _STRUCT_SIZE
		def {_PFX}_type equ _TYPE
		def {_PFX}_len equ _LEN
		def {_PFX}_sz equ _TYPE * _LEN
		def {_PFX}_i equ _STRUCT_FIELD_COUNT
		redef _STRUCT_SIZE = _STRUCT_SIZE + _TYPE * _LEN
		redef _STRUCT_FIELD_COUNT = _STRUCT_FIELD_COUNT + 1

		purge _NAME, _TYPE, _LEN, _IPFX, _PFX
	endc
endm


; st STRUCT, INSTANCE
; Create an instance of a struct thing. For use in e.g. a wram section.
; Creates labeled structure layout with statically allocated memory.
; STRUCT is the name of a struct declared with stdecl.
; INSTANCE is the name of the instance root label.
macro st
	\2::
	for i, \1_len
		def _FNAME equs "{\1_{u:i}_name}"
		def _FTYPE equ \1_{u:i}_type
		def _FLEN equ \1_{u:i}_len
		.{_FNAME}::
		if _FLEN > 1
			ds _FTYPE * _FLEN
		elif _FTYPE == 1
			db
		elif _FTYPE == 2
			dw
		elif _FTYPE == 4
			dl
		endc
		purge _FNAME, _FTYPE, _FLEN
	endr
endm


macro struct_dump
	println "struct '\1' (sz: {u:\1_sz}, len: {u:\1_len}):"
	for i, \1_len
		def _FNAME equs "{\1_{u:i}_name}"
		println "\t({u:i}) {\1_{u:i}} {_FNAME}:{u:\1_{u:i}_type}[{u:\1_{u:i}_len}]"
		purge _FNAME
	endr
endm


endc ; DEFINES_INC
