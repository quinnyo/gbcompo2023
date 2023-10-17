/**********************************************************
*                                               SoundCode *
**********************************************************/
if !def(CORE_SOUNDCODE_INC)
def CORE_SOUNDCODE_INC equ 1

include "common.inc"

def SCSTAT_SND  equ 1 ; sound definition started
def SCSTAT_PART equ 2 ; part started
def SCSTAT_LAST_PART equ 4
def SND_COUNT = 0 ; number of sounds defined
def _SC = 0

; ScPart CHANNELS, DURATION, [NEXT]
; CHANNELS: CH* bitmask -- Channels used by this part
; DURATION: byte -- Durtation of the part, in frames.
; NEXT: word -- [optional] Address of sound part to play after this one
macro ScPart
	if _SC & SCSTAT_PART != 0
		warn "ScPart started within another. Use ScEnd to close parts."
	endc

	if _SC & SCSTAT_SND == 0
		; starting new sound
	_snd_{u:SND_COUNT}:
		def SND_COUNT += 1
		def _SC = SCSTAT_SND
	endc

	def _SC |= SCSTAT_PART

	if _NARG == 2
		def _NEXT equs "0"
		def _SC |= SCSTAT_LAST_PART
	elif _NARG == 3
		def _NEXT equs "\3"
	else
		fail "ScPart requires 2 or 3 args"
	endc

	db (\1), (\2)
	dw {_NEXT}

	purge _NEXT
endm

; ScReg REG, VALUE
; REG -- an audio register
; VALUE -- value to load into the register
macro ScReg
	if _SC & SCSTAT_PART == 0
		warn "ScReg outside of ScPart definition"
	endc
	if _NARG == 2
		db low(\1), (\2)
	else
		fail "ScReg requires 2 args"
	endc
endm

macro ScEnd
	if _SC & SCSTAT_LAST_PART != 0
		def _SC = 0
	else
		def _SC &= ~SCSTAT_PART
	endc
	db 0
endm

/***********************************************************
*                                      Sound Table Builder *
************************************************************
Usage:
{{{
snd_boop:
	; [snip sound definition]

	; Start a new sound table (optional)
	SoundTableBegin

snd_plink:
	; [snip sound definition]

snd_drong:
	; [snip sound definition]

sndtab2:
	SoundTableEnd
	; effective SoundTableEnd output:
	db 2
	dw snd_plink
	dw snd_drong
}}}

Table data structure is very simple:
{{{
	byte COUNT ; the number of sounds in the table
	word[COUNT] ; array of sounds -- address of each sound in the table.
}}}
***********************************************************/

def SOUND_TABLE_MAX_SIZE equ 127

; Start a new sound table. All sounds following this will be included, until SoundTableEnd.
macro SoundTableBegin
	def _SNDTAB_FIRST equ SND_COUNT
endm

; SoundTableEnd [LABEL_SIZE]
; SoundTableEnd [LABEL_SIZE, LABEL_DATA]
; Close the sound table and write the data out.
; Sounds defined before this (and after the last SoundTableBegin) will be included.
macro SoundTableEnd
	if !def(_SNDTAB_FIRST)
		def _SNDTAB_FIRST equ 0
	endc
	def _SNDTAB_SIZE equ SND_COUNT -_SNDTAB_FIRST

	if _SNDTAB_SIZE > SOUND_TABLE_MAX_SIZE
		fail fatal, "Sound table max size exceeded ({u:_SNDTAB_SIZE} > {u:SOUND_TABLE_MAX_SIZE})"
	endc

if _NARG >= 1
\1
endc
	db {_SNDTAB_SIZE}
if _NARG >= 2
\2
endc
	for I, _SNDTAB_SIZE
		dw _snd_{u:I}
	endr

	purge _SNDTAB_FIRST, _SNDTAB_SIZE
endm

endc ; CORE_SOUNDCODE_INC