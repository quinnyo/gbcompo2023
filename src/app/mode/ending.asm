include "common.inc"
include "gfxmap.inc"

def SKIP_HOLD_TIME equ 70
def SKIP_HOLD_DIAL_X equ 152
def SKIP_HOLD_DIAL_Y equ 135
def STR_SKIP_HINT equs "<^Sta>Exit "
def STR_SKIP_HINT_LEN equ charlen("{STR_SKIP_HINT}")
def SKIP_HINT_X equ 167 - 8 * STR_SKIP_HINT_LEN
def SKIP_HINT_Y equ 143 - 8

section "Ending", rom0

Ending_init::
	xor a
	ldh [rSCX], a
	ldh [rSCY], a

	call gfx_load_game_obj
	call Collide_init
	call things_init
	call tcm_init
	call world_init
	ld a, [wSettings.level]
	cp COURSE_COUNT
	jr c, :+
	rst panic
:
	call Courses_index_mapid
	call Maps_data_access
	ld e, l
	ld d, h
	call world_load_map
	call world_display_tilemap
	call things_start
	call musctl_stop
	call _show_skip_hint
	ret


Ending_main_iter::
	call oam_clear
	call _skip_update
	ret


_skip_update:
	ld a, [wInput.held_start]
	and a
	ret z
	ld b, a
	cp SKIP_HOLD_TIME
	jr c, :+
	ld a, ModeSplash
	jp Main_mode_change
:
	call oam_next_recall
	ld a, SKIP_HOLD_DIAL_Y + OAM_Y_OFS
	ld [hl+], a
	ld a, SKIP_HOLD_DIAL_X + OAM_X_OFS
	ld [hl+], a
	ld a, b
	sla a
	swap a
	and 7
	add tShapes_Dir8
	ld [hl+], a
	ld a, 2
	ld [hl+], a
	call oam_next_store
	ret


_show_skip_hint:
	ld a, SKIP_HINT_X
	ldh [rWX], a
	ld a, SKIP_HINT_Y
	ldh [rWY], a
	ld de, strSkipHint
	ld hl, $9C00
	ld bc, STR_SKIP_HINT_LEN
	call vmem_copy
	ret


strSkipHint: db "{STR_SKIP_HINT}"