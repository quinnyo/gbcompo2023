include "common.inc"


section "rst_panic", rom0[$00]
panic::
	di
	ld b, b
	stop
	jr panic ; shouldn't reach here, but...

	StaticReserve $08 - @
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

	StaticReserve $18 - @
section "rst_rom_sel", rom0[$18]
; Select ROMX bank.
; @param A: bank number to swap to
rom_sel::
if def(MBC)
	ldh [hActiveROM], a
	ld [rROMB0], a
endc
	ret


	StaticReserve $40 - @
section "IRQ_VBlank", rom0[$0040]
IRQ_VBlank: jp ISR_VBlank

; section "IRQ_LCDC", rom0[$0048]
; IRQ_LCDC: reti

; section "IRQ_Timer", rom0[$0050]
; IRQ_Timer: reti

; section "IRQ_Serial", rom0[$0058]
; IRQ_Serial: reti

; section "IRQ_P1", rom0[$0060]
; IRQ_P1: reti


	StaticReserve $0100 - @
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
	call gfx_update
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
	ldh [hTick], a
	ld a, 1
	ldh [hActiveROM], a

	ld a, IEF_VBLANK
	ldh [rIE], a

	ld a, ModeSplash
	ld [wMode.current], a

	ld sp, $FFFE

	call audio_init
	call audio_on
	call Display_init
	call Display_lcd_off
	call oam_init
	call input_init
	call loado_init
	call gfx_init
	call gfx_load_default_font
	call gfx_load_default_palettes
	call Texto_init
	call CourseScores_unpack
	call settings_init
	call world_init
	call Mode_init

	call Display_lcd_on

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
	ldh a, [hVBlankF]
	and a
	jr z, .vblank_wait
	xor a
	ldh [hVBlankF], a

	jr MainLoop


; @param A: mode ID
Main_mode_change::
	ld [wMode.current], a
	ld a, 1
	call gfx_fade_out
	call gfx_fade_complete

	di
	xor a
	ldh [rIF], a

	call oam_clear
	call Mode_init

	ei
	ld a, 1
	call gfx_fade_in

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
	ModeDef "Debug_BallDrop", Debug_BallDrop.init, Debug_BallDrop.main_iter
	ModeDef "Debug_Collidoscope", Debug_Collidoscope.init, Debug_Collidoscope.main_iter
	ModeDef "Debug_InspectGFX", Debug_InspectGFX.init, Debug_InspectGFX.main_iter
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
