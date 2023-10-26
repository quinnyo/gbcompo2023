include "common.inc"

section "rst_jump_switch", rom0[$08]
; Jump into address table immediately following callsite.
; DOES NOT RETURN
; @param A: offset
; @mut: AF, HL
jump_switch::
	pop hl ; return addr at callsite (jump_table[0])
	; table offset
	add a, l
	jr nc, :+
	inc h
:
	ld l, a
	; jump to stored address
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jp hl


section "rst_rom_sel", rom0[$18]
; Select ROMX bank.
; @param A: bank number to swap to
rom_sel::
if def(MBC)
	ldh [hActiveROM], a
	ld [rROMB0], a
endc
	ret


section "IRQ_VBlank", rom0[$0040]
	jp ISR_VBlank

; section "IRQ_LCDSTAT", rom0[$0048]
; 	jp ISR_audio_update

; section "IRQ_Timer", rom0[$0050]
; 	jp ISR_audio_update

; section "IRQ_Serial", rom0[$0058]
; 	reti

; section "IRQ_P1", rom0[$0060]
; 	reti


section "Header", rom0[$0100]
	nop
	jp EntryPoint
	ds $150 - @, 0


section "ISR", rom0
ISR_VBlank:
	push af
	push bc
	push de
	push hl

	call hOAMCopyRoutine
	call audio_update

	ld a, 1
	ldh [hVBlankF], a

	ldh a, [hTick]
	inc a
	ldh [hTick], a

	pop hl
	pop de
	pop bc
	pop af
	reti


/**********************************************************
* MAIN
**********************************************************/
section "Main", rom0
Reset::
EntryPoint:
	di
	xor a
	ldh [hVBlankF], a
	ld a, 1
	ldh [hActiveROM], a

	ld a, IEF_VBLANK
	ldh [rIE], a

	ld a, ModeSplash
	ld [wMode.current], a

	ld sp, $FFFE

	call audio_init
	call audio_on
	call lcd_off
	call oam_init
	call input_init
	call loado_init
	call gfx_load_default_font
	call gfx_load_default_palettes
	call Texto_init
	call settings_init
	call world_init
	call Mode_init

	call lcd_on

	; enable interrupts
	xor a
	ldh [rIF], a
	ldh a, [rIE]
	or IEF_VBLANK
	ldh [rIE], a

	ei
	xor a
	ld [hVBlankF], a
	jr MainLoop.vblank_wait

MainLoop:
	call input_update
	; Hold all the buttons -- reset
	ld a, [wInput.state]
	and PADF_A | PADF_B | PADF_SELECT | PADF_START
	xor PADF_A | PADF_B | PADF_SELECT | PADF_START
	jr z, Reset
	call Mode_main_iter

	; Skip first HALT -- if already in VBLANK, don't want to wait for another one?
	jr .vblank_wait_entry
.vblank_wait
	halt
	nop
.vblank_wait_entry
	; wait for vblank interrupt
	ld a, [hVBlankF]
	and a
	jr z, .vblank_wait
	xor a
	ld [hVBlankF], a

	jr MainLoop


; @param A: mode ID
Main_mode_change::
	ld [wMode.current], a

	di
	xor a
	ldh [rIF], a

	ld sp, $FFFE
	call oam_clear
	call Mode_init

	ei
	jp MainLoop


; Disable the LCD (waits for vblank)
lcd_off::
:
	ldh a, [rLY]
	cp SCRN_Y
	jr c, :-
	xor a
	ldh [rLCDC], a
	ret


; Enable the LCD
lcd_on::
	; Turn the LCD on, enable BG, enable OBJ
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_WINON | LCDCF_WIN9C00
	ldh [rLCDC], a
	ret


wait_vblank::
	ldh a, [rLY]
	cp SCRN_Y
	jr c, wait_vblank
	ret


include "mem.inc"


section "Main_State", hram
hVBlankF:: db      ; VBlank completion flag
hTick:: db         ; VBlank count
hActiveROM:: db    ; Selected ROMX bank number


/**********************************************************
* MODE
* Pluggable main program modes.
**********************************************************/
section "Mode", rom0

	ModeDef "Splash", Splash.init, Splash.main_iter
	ModeDef "Game", Game.init, Game.main_iter
	ModeDef "LevelSelect", LevelSelect.init, LevelSelect.main_iter
	ModeDef "SoundTest", SoundTest_init, SoundTest_main_iter

if def(DEBUG_MODES)
	pushs
	include "debug/ball_drop.asm"
	include "debug/collidoscope.asm"
	include "debug/inspect_gfx.asm"

	ModeDef "Debug_BallDrop", Debug_BallDrop.init, Debug_BallDrop.main_iter
	ModeDef "Debug_Collidoscope", Debug_Collidoscope.init, Debug_Collidoscope.main_iter
	ModeDef "Debug_InspectGFX", Debug_InspectGFX.init, Debug_InspectGFX.main_iter
	pops
endc


; Jump to the `init` routine of the current mode
Mode_init::
	ld a, [wMode.current]
	add a
	rst jump_switch
	for i, MODES_COUNT
		dw {Mode{u:i}_init}
	endr


; Jump to the `main_iter` routine of the current mode
Mode_main_iter::
	ld a, [wMode.current]
	add a
	rst jump_switch
	for i, MODES_COUNT
		dw {Mode{u:i}_main_iter}
	endr


section "Mode State", wram0
wMode::
	.current:: db ; current mode ID


/**********************************************************
* MAPS
**********************************************************/


def MAP_TITLE_MAX_LENGTH equ 15

rsreset
def MAP_INFO_DATA       rw 1
def MAP_INFO_TITLE_LEN  rb 1
def MAP_INFO_TITLE      rb MAP_TITLE_MAX_LENGTH
def MAP_INFO_SIZE       rb 0

def MAP_COUNT = 0 ; number of levels defined

export MAP_COUNT, MAP_INFO_SIZE, MAP_TITLE_MAX_LENGTH

; MapDef ID, TITLE
macro MapDef
	assert charlen(\2) <= MAP_TITLE_MAX_LENGTH

	def _LABEL equs "map_\1"
	def _SRC equs "res/map/\1.asm"
	pushs
	include "{_SRC}"
	pops

	def MAP_{u:MAP_COUNT} equs "\1"
	def MAP_{u:MAP_COUNT}_TITLE equs \2

	def MAP_COUNT += 1

	purge _LABEL, _SRC
endm


	MapDef e1m1, "Emerge'n'see"
	MapDef e1m2, "Lookout!"
	MapDef e1m3, "Jangle Gap"

	MapDef e2m1, "Beach"
	MapDef e2m2, "Ship battle"

	MapDef win, "The End"

section "Maps", rom0

Maps::
	.count: db {MAP_COUNT}

	.map_info_start:
for i, {MAP_COUNT}
	def _TITLE equs "{MAP_{u:i}_TITLE}"
	def _TITLE_LEN equ charlen("{_TITLE}")
	def _TITLE_PADDING equ MAP_TITLE_MAX_LENGTH - _TITLE_LEN
	println "MapInfo({u:i}) \"{_TITLE}\" ({_TITLE_LEN}+{u:_TITLE_PADDING})"

	.map{u:i}_data: dw map_{MAP_{u:i}}
	.map{u:i}_title_len: db _TITLE_LEN
	.map{u:i}_title: db "{_TITLE}"
	rept _TITLE_PADDING
		db "~"
	endr

	purge _TITLE, _TITLE_LEN, _TITLE_PADDING
endr


; @param A: index
; @ret HL: address of map info for map with given index
; @mut: BC
map_info_by_index::
	ld hl, Maps.map_info_start
	ld bc, MAP_INFO_SIZE
	jr _offset_by_index


; @param A: index
; @ret HL: address of map title structure for map with given index
; @mut: BC
map_title_by_index::
	ld hl, Maps.map_info_start + MAP_INFO_TITLE_LEN
	ld bc, MAP_INFO_SIZE
	jr _offset_by_index


; @param A: index
; @param HL: address of index 0
; @param BC: stride
; @ret HL: address of map title structure for map with given index
; @mut: BC
_offset_by_index:
	cp 0
	ret z ; A == 0
:
	add hl, bc
	dec a
	jr nz, :-
	ret