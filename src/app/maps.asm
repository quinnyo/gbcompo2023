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
	MapDefRaw \#
endm


; CourseDef UID
macro CourseDef
	assert !def(_COURSE)
	assert _NARG == 1
	def _COURSE equ COURSE_COUNT
	def COURSE_{u:_COURSE}_UID equ \1
	def COURSE_COUNT += 1
endm

macro CourseMap
	if !def(MAPIDX_\1)
		MapDef \1
	endc
	def COURSE_{u:_COURSE}_MAPID equ MAPIDX_\1
endm

macro CourseAttr
	def COURSE_{u:_COURSE}_\1 equ \2
endm

macro CourseStr
	def COURSE_{u:_COURSE}_\1 equs \2
endm

macro CourseEnd
	purge _COURSE
endm


; if def(DEVMODE)
; 	CourseDef $01
; 		CourseStr TITLE, "Testmap?!"
; 		CourseMap testmap
; 		CourseAttr PAR, 3
; 	CourseEnd
; endc

	CourseDef $11
		CourseStr TITLE, "Emerge'n'see"
		CourseMap e1m1
		CourseAttr PAR, 4
	CourseEnd

	CourseDef $12
		CourseStr TITLE, "Lookout!"
		CourseMap e1m2
		CourseAttr PAR, 2
	CourseEnd

	CourseDef $13
		CourseStr TITLE, "Jangle Gap"
		CourseMap e1m3
		CourseAttr PAR, 2
	CourseEnd

	CourseDef $21
		CourseStr TITLE, "Beach"
		CourseMap e2m1
		CourseAttr PAR, 5
	CourseEnd

	CourseDef $22
		CourseStr TITLE, "Ship battle"
		CourseMap e2m2
		CourseAttr PAR, 6
	CourseEnd

	MapDef win
	MapDef bg_level_select

for i, MAP_COUNT
	pushs
	include "res/map/{MAP_{u:i}}.asm"
	pops
endr


section "wCourseScores", wram0

; Unpacked Course save data
def COURSE_SAVE_DATA_LEN equ COURSE_COUNT
wCourseScores:: ds COURSE_SAVE_DATA_LEN


section "CourseScores", rom0
CourseScores_init::
	ld hl, wCourseScores
	ld bc, COURSE_SAVE_DATA_LEN
	ld d, 0
	call mem_fill
	ret


; Write packed course save data to buffer.
; @param DE: destination address
; @mut: AF, BC, DE, HL
CourseScores_pack::
	ld a, COURSE_COUNT
	ld c, a
	ld [de], a
	inc de
	ld b, 0
:
	ld a, b
	call Courses_index_uid
	ld [de], a
	inc de
	ld a, b
	call Courses_index_score
	ld [de], a
	inc de
	inc b
	dec c
	jr nz, :-

	ret


; Unpack course scores save data block
; @param DE: block data address
CourseScores_unpack::
	; { N, { UID, SCORE }[N] }
	ld a, [de]
	inc de
	ld b, a
:
	call _unpack_one
	dec b
	jr nz, :-

	ret


_unpack_one:
	ld a, [de]
	inc de
	call Courses_uid_to_index
	jr nz, :+
	inc de
	ret
:
	ld a, c
	call Courses_index_score
	ld a, [de]
	inc de
	ld [hl], a

	ret


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
	.course_uid::
for i, {COURSE_COUNT}
	db COURSE_{u:i}_UID
endr

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
	db charlen("{COURSE_{u:i}_TITLE}")
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
	di
	ld b, b
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


; Find the storage index of the course with the given uid.
; @param A: UID
; @ret C: Index
; @ret F.Z: set if UID not found
; @mut: C, HL
Courses_uid_to_index::
	ld hl, Courses.course_uid + COURSE_COUNT - 1
	ld c, COURSE_COUNT
:
	cp [hl]
	jr z, .found
	dec hl
	dec c
	jr nz, :-
.not_found
	ld c, $FF
	ret
.found
	dec c
	or 1 ; reset F.Z
	ret


; Look up a course's uid by index.
; @param A: index
; @ret A: course uid
; @mut: AF, HL
Courses_index_uid::
	CheckIndex COURSE_COUNT
	ld hl, Courses.course_uid
	jr _index_byte


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


; Look up a course's score by index, and check if it has been completed.
; @param A: index
; @ret A: score
; @ret F.Z: set if level is incomplete.
; @ret HL: address of course score structure
; @mut: AF, HL
Courses_index_score::
	CheckIndex COURSE_COUNT
	ld hl, wCourseScores
	call _index_byte
	and a
	ret


; Look up a course by index, and check if it's locked (unable to be played).
; @param A: index
; @ret F.Z: set if level is locked.
; @mut: AF, HL
Courses_index_locked::
	and a
	jr nz, :+
	or 1 ; F.NZ
	ret
:
	dec a
	jr Courses_index_score


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
