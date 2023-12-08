; Savewhip: global save routines
; calls all the specific save routines
include "common.inc"

rsreset
def SAVE_BLOCK_NULL                  rb 1
def SAVE_BLOCK_SETTINGS              rb 1
def SAVE_BLOCK_COURSE_SCORES         rb 1
def SAVE_BLOCK__TYPE_COUNT           rb 0


section "savewhip", rom0

; Save all the things!
; @mut: AF, BC, DE, HL
savewhip_store::
	call Save_write_start
	
	ld b, SAVE_BLOCK_SETTINGS
	call Save_block_start
	call settings_pack
	call Save_block_end

	ld b, SAVE_BLOCK_COURSE_SCORES
	call Save_block_start
	call CourseScores_pack
	call Save_block_end

	call Save_store
	ret


; Load all the things!
; @mut: AF, BC, DE, HL
savewhip_fetch::
	call Save_fetch

	call Save_read_start
	ret z
.loop
	call Save_open_block
	jr c, :+
	ret z
	jr _block_error
:
	call _block_unpack
	jr .loop
	ret

_block_error:
	di
	halt
	nop
	jr _block_error
	ret


_block_unpack:
	ld a, b
	cp SAVE_BLOCK_NULL
	ret z
	cp SAVE_BLOCK_SETTINGS
	jp z, settings_unpack
	cp SAVE_BLOCK_COURSE_SCORES
	jp z, CourseScores_unpack

.err_unexpected_block:
	di
	halt
	nop
	jr .err_unexpected_block
