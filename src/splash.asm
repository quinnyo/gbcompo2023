include "common.inc"
include "input.inc"
include "mus.inc"

section "Splash", rom0
Splash::

.init::
	; load title screen thing
	ld de, title_tiles
	ld hl, $8800
	ld bc, title_tiles_size
	call vmem_copy

	ld de, title_map
	ld b, title_map_width
	ld c, title_map_height
	ld hl, $9800
	call vmem_copy_rect

if def(DEBUG_MODES)
	call debug_menu_init
endc

	ld b, MUSIC_TRACK_MUS01_INDEX
	call musctl_play_next

	call SusMenu_init

	ret


.main_iter::
	call SusMenu_update

	ld b, SUSDIR_SOUNDTEST
	ld c, SUSDIST_SOUNDTEST
	call SusMenu_check
	jr c, :+
	ld a, ModeSoundTest
	jp Main_mode_change
:

	ld a, [wInput.pressed]
	and PADF_A | PADF_START
	jr z, :+
	ld a, ModeLevelSelect
	jp Main_mode_change
:

if def(DEBUG_MODES)
	call debug_menu_update
endc

	ret


def title_map_size equ $0168
def title_map_width equ $14
def title_map_height equ $12
include "res/title.scrn"


/*******************************
*    (``    (``     |\/|       *
*    _)UPER _)ECRET |  |ENU    *
*******************************/

def SUSDIR_SOUNDTEST    equ PADF_UP | PADF_B
def SUSDIST_SOUNDTEST   equ 3

section "SuperSecretMenu", rom0

SusMenu_init:

SusMenu_reset:
	xor a
	ld [wSusMenu.direction], a
	ld [wSusMenu.steps], a
	ret

; @mut: AF, B
SusMenu_update:
	ld a, [wInput.pressed]
	and a
	ret z ; no press event

	ld a, [wInput.state]
	ld b, a

	ld a, [wSusMenu.direction]
	and a
	jr nz, .next_step
.first_step
	ld a, b
	ld [wSusMenu.direction], a
	ret
.next_step
	ld a, [wSusMenu.direction]
	xor b
	jr nz, SusMenu_reset ; reset if different buttons down compared to last press

	ld a, [wSusMenu.steps]
	inc a
	ld [wSusMenu.steps], a

	ret


; Compare current state against a direction and number of steps.
; If the direction matches, returns the result of `(A=steps) cp c`.
; @param B: direction to compare against
; @param C: number of steps required
; Cy: set if the check failed. Either direction doesn't match,
;     or set as the result of `cp (steps), C` (value in C > `steps`)
; Z: set if value in C == `steps`
SusMenu_check::
	ld a, [wSusMenu.direction]
	xor b
	jr nz, :+
	ld a, [wSusMenu.steps]
	cp c
	ret
:
	ccf
	ret


section "SuperSecretMenuState", wram0

; it's super secret
wSusMenu:
	.direction: db
	.steps: db


/*************
* DEBUG TOWN *
*************/
if def(DEBUG_MODES)

section "DebugMenu", romx

def MENUB_DEBUG equ 7
def MENUF_DEBUG equ %10000000

debug_menu_init:
	call Texto_init

	ld a, MENUF_DEBUG
	ld [wMenuFlags], a
	ld de, debug_menu_text
	ld b, debug_menu_text.end - debug_menu_text
	call Texto_writeln
	call Texto_show

debug_menu_update:
	ld a, [wMenuFlags]
	bit MENUB_DEBUG, a
	jr z, .check_show_debug
	call nz, debug_menu
	jr .debug_menu_done

.check_show_debug
	ld a, [wInput.pressed]
	bit PADB_SELECT, a
	jr z, :+
	ld a, [wMenuFlags]
	set MENUB_DEBUG, a
	ld [wMenuFlags], a
	call nz, Texto_show
: ; SEL not pressed
.debug_menu_done

	call Texto_update

	ret

debug_menu:
	ld a, [wInput.pressed]
	bit PADB_LEFT, a
	jr z, :+
	ld a, ModeDebug_InspectGFX
	jp Main_mode_change
:
	bit PADB_DOWN, a
	jr z, :+
	ld a, ModeDebug_BallDrop
	jp Main_mode_change
:
	bit PADB_UP, a
	jr z, :+
	ld a, ModeDebug_Collidoscope
	jp Main_mode_change
:

	bit PADB_SELECT, a
	ret z

	; hide menu
	ld a, [wMenuFlags]
	res MENUB_DEBUG, a
	ld [wMenuFlags], a
	call nz, Texto_show_none

	ret


debug_menu_text:
	db "   <<Debug Town>>   "
	db " collido- U         "
	db "    gfx- L R -_____ "
	db "          D -balls  "
.end


section "DebugMenuState", wram0
wMenuFlags: db

endc