include "common.inc"

def MAP_COUNT = 0 ; number of maps defined
def COURSE_COUNT = 0
export MAP_COUNT, COURSE_COUNT

; MapDefRaw MAPID
macro MapDefRaw
	assert fatal, _NARG == 1, "MapDefRaw requires 1 argument."
	def MAP_{u:MAP_COUNT} equs "\1"
	def MAPIDX_\1 equ MAP_COUNT
	export MAPIDX_\1

	def MAP_COUNT += 1
endm

; MapDef MAPID
macro MapDef
	assert fatal, _NARG == 1, "MapDef requires 1 argument."
	pushs
	include "res/map/\1.asm"
	pops

	MapDefRaw \#
endm

; Define a new course with a map, title and par score.
; If map is not defined, `MapDef MAPID` will be invoked.
; CourseDef MAPID, "TITLE", PAR
macro CourseDef
	assert fatal, _NARG == 3, "CourseDef requires 3 arguments."
	if !def(MAPIDX_\1)
		MapDef \1
	endc

	def _COURSE equ COURSE_COUNT

	def COURSE_{u:_COURSE}_MAPID equ MAPIDX_\1
	def COURSE_{u:_COURSE}_TITLE equs \2
	def COURSE_{u:_COURSE}_TITLE_LEN equ charlen(\2)
	def COURSE_{u:_COURSE}_PAR equ \3

	def COURSE_COUNT += 1
	purge _COURSE
endm


if def(DEVMODE)
	CourseDef testmap, "Testmap?!", 3
endc

	CourseDef e1m1, "Emerge'n'see", 4
	CourseDef e1m2, "Lookout!", 2
	CourseDef e1m3, "Jangle Gap", 2

	CourseDef e2m1, "Beach", 5
	CourseDef e2m2, "Ship battle", 6

	MapDef win
	MapDef bg_level_select


section "Maps", rom0

Maps::
	.map_data_bank:
for i, {MAP_COUNT}
	db bank(map_{MAP_{u:i}})
endr

	.map_data:
for i, {MAP_COUNT}
	dw map_{MAP_{u:i}}
endr


Courses::
	.course_mapid:
for i, {COURSE_COUNT}
	db COURSE_{u:i}_MAPID
endr

	.course_info:
for i, {COURSE_COUNT}
	db COURSE_{u:i}_PAR
endr

	.course_title:
for i, {COURSE_COUNT}
	dw .course{u:i}_title_data
endr

for i, {COURSE_COUNT}
	.course{u:i}_title_data:
	db COURSE_{u:i}_TITLE_LEN
	db "{COURSE_{u:i}_TITLE}"
endr


; CheckIndex SIZE
macro CheckIndex
if def(DEBUG)
	cp \1
	jr nc, _error_index_out_of_range
endc
endm

if def(DEBUG)
_error_index_out_of_range:
	halt
	nop
	jr _error_index_out_of_range
endc


; Switch to map data ROM bank and return map data pointer.
; @param A: map index
; @ret HL: map data pointer
; @mut: AF, C, HL
Maps_data_access::
	CheckIndex MAP_COUNT
	ld c, a
	ld hl, Maps.map_data_bank
	call _index_byte
	rst rom_sel
	ld a, c
	ld hl, Maps.map_data
	jr _index_word


; Look up a course's mapid by index.
; @param A: index
; @ret A: course mapid
; @mut: AF, HL
Courses_index_mapid::
	CheckIndex COURSE_COUNT
	ld hl, Courses.course_mapid
	jr _index_byte


; Look up a course's info struct by index.
; @param A: index
; @ret A: course par score
; @ret HL: address of course info
; @mut: AF, HL
Courses_index_info::
	CheckIndex COURSE_COUNT
	ld hl, Courses.course_info
	jr _index_byte


; Look up a course's title by course index.
; @param A: index
; @ret HL: address of course title structure
; @mut: AF, HL
Courses_index_title::
	CheckIndex COURSE_COUNT
	ld hl, Courses.course_title
	jr _index_word


; Read a byte from an array.
; @param A: index
; @param HL: array address
; @ret HL: address of byte read
; @mut: AF, HL
_index_byte:
	add l
	ld l, a
	adc h
	sub l
	ld h, a

	ld a, [hl]
	ret


; Read a word from an array
; @param A: index
; @param HL: array address
; @ret HL: word
; @mut: AF, HL
_index_word:
	add a ; double index ==> indexing words
	add l
	ld l, a
	adc h
	sub l
	ld h, a

	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ret
