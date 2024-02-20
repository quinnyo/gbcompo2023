include "common.inc"
include "core/loado.inc"
include "res/onebit-mono.inc"
include "gfxmap.inc"


; ColorW R, G, B
; @param R, G, B: 5 bit integer (0..31) for each channel
; Define a color, stored in a 2 byte word, encoded as RGB555 for CGB.
macro ColorW
	assert _NARG == 3
	assert (\1) >= 0 && (\1) < 32
	assert (\2) >= 0 && (\2) < 32
	assert (\3) >= 0 && (\3) < 32
	dw (($1F & (\3)) << 10) | (($1F & (\2)) << 5) | ($1F & (\1))
endm

; ColorRRR R
; @param R: 5 bit integer (R <= 31)
; Equivalent to `ColorW R, R, R`
macro ColorRRR
	assert (\1) >= 0 && (\1) < 32
	ColorW (\1), (\1), (\1)
endm


section "OBJ Tiles", vram[$8000]
vOBJTiles::

section "BG Tiles", vram[$8800]
vBGTiles::

section "UI Tiles", vram[$9000]
vFontTiles::

section "wGfx", wram0

def CPAL_SIZE equ 8           ; size of a palette in bytes
def CPAL_BCP_COUNT equ 8      ; number of managed BG palettes
def CPAL_OCP_COUNT equ 8      ; number of managed OBJ palettes

; colour palettes (source)
wCPal_src:
wBCP_src: ds CPAL_SIZE * CPAL_BCP_COUNT
wOCP_src: ds CPAL_SIZE * CPAL_OCP_COUNT

; colour palettes (effect)
wCPal:
wBCP: ds CPAL_SIZE * CPAL_BCP_COUNT
wOCP: ds CPAL_SIZE * CPAL_OCP_COUNT


wGfx::
	.bcp_changed:: db ; set bit indicates respective BG palette needs to be synced
	.ocp_changed:: db ; set bit indicates respective OBJ palette needs to be synced


def FADEB_DIR        equ 7
def FADEF_INTERVAL   equ $7F

	stdecl Fade
		stfield interval    ; dir out flag (1 bit) | interval (7 bits)
		stfield tick        ; current interval timer
		stfield seq, w      ; fade sequence pointer
	stclose

	st Fade, wFade


section "GFXLOADER", rom0

gfx_init::
	xor a
	ld hl, wGfx.bcp_changed
	ld [hl+], a ; bcp_changed
	ld [hl+], a ; ocp_changed

	ld hl, wCPal_src
	ld bc, (CPAL_BCP_COUNT + CPAL_OCP_COUNT) * CPAL_SIZE * 2
	ld d, a
	call mem_fill

	ld hl, wFade
	ld c, Fade_sz
	xor a
	call mem_fill_byte

	ret


; Configure and start fade
; @param A: dir | interval
; @param BC: seq, fade sequence pointer
; @mut: AF, HL
gfx_fade::
	ld hl, wFade.interval
	ld [hl+], a ; interval
	and FADEF_INTERVAL
	ld [hl+], a ; tick
	ld a, c
	ld [hl+], a ; seq.0
	ld a, b
	ld [hl+], a ; seq.1

	ret


; Start fade in (end at source palettes)
; @param A: fade step interval in frames (will be clamped to max of 127)
; @mut: AF, BC, HL
gfx_fade_in::
	res FADEB_DIR, a
	ld bc, Fade5.t0
	jr gfx_fade


; Start fade out (end at fade colour (black))
; @param A: fade step interval in frames (will be clamped to max of 127)
; @mut: AF, BC, HL
gfx_fade_out::
	set FADEB_DIR, a
	ld bc, Fade5.t5
	jr gfx_fade


; Blocks until active fade is complete.
; Expects `gfx_update` to be called from vblank ISR (interrupting this routine)
; @mut: AF, HL
gfx_fade_complete::
	ld hl, wFade.interval
	ld a, [hl]
	and FADEF_INTERVAL
	ret z
:
	halt
	nop

	ld a, [hl]
	and FADEF_INTERVAL
	jr nz, :-

	ret


; Apply fade mask immediately.
; @param BC: fade mask
; @mut: AF, HL, DE
gfx_fade_apply::
	ld de, wCPal_src
	ld hl, wCPal
	def _TOTAL_SIZE equ CPAL_SIZE * (CPAL_BCP_COUNT + CPAL_OCP_COUNT)
:
	ld a, [de]
	inc de
	and c
	ld [hl+], a
	ld a, [de]
	inc de
	and b
	ld [hl+], a

	ld a, h
	cp high(wCPal + _TOTAL_SIZE)
	jr c, :-
	ld a, l
	cp low(wCPal + _TOTAL_SIZE)
	jr c, :-

	; mark every palette as modified...
	; TODO: not that ^
	ld hl, wGfx.bcp_changed
	ld a, $FF
	ld [hl+], a ; bcp_changed
	ld [hl+], a ; ocp_changed

	ret


; Update palette effects (fade).
; Call this from vblank ISR.
; @mut: AF, HL, BC, DE
gfx_update::
	ld hl, wFade
	call _fade_update

	jr gfx_palette_sync


; @param HL: Fade struct
; @mut: AF, HL, BC, DE
_fade_update:
	assert Fade_interval == 0 && Fade_tick == 1
	ld a, [hl+] ; interval
	ld d, a
	and FADEF_INTERVAL
	ret z ; fade enabled when interval is nonzero
	dec [hl] ; tick
	ret nz
	; reset timer
	ld [hl+], a

	; do fade step
	ld e, [hl]
	bit FADEB_DIR, d ; NZ: OUT, Z: IN
	jr z, :+
	call Fade5_step_out
	jr .seq_step_done
:
	call Fade5_step_in
.seq_step_done
	jr c, .seq_step_changed ; Fade5_step_* sets carry if step applied
	xor a
	ld [wFade.interval], a
	ret
.seq_step_changed
	ld [hl], e ; seq.0
	inc hl
	; read seq into HL
	ld h, [hl]
	ld l, e

	; read seq fade mask
	ld a, [hl+]
	ld c, a
	ld b, [hl]
	call gfx_fade_apply

	ret


; @mut: AF, HL, B, D
gfx_palette_sync::
; BCP sync
	ld hl, wGfx.bcp_changed
	ld a, [hl]
	and a
	jr z, .ocp_sync     ; nothing to do, skip to OCP
	ld d, a             ; D = bcp_changed
	xor a
	ld [hl], a          ; clear bcp_changed
	ld c, CPAL_BCP_COUNT
	ld hl, wBCP
	ld a, BCPSF_AUTOINC
	ldh [rBCPS], a

.sync_bcp_loop
	; check changed status bit for each palette
	srl d
	jr nz, :+           ; if no (more) bits set
	jr nc, .ocp_sync    ; break loop
	ld c, 1             ; make this the last iteration
:
	jr nc, .bcp_not_changed
rept 4 ; 4 colors
	WaitVRAM
	ld a, [hl+]
	ldh [rBCPD], a
	ld a, [hl+]
	ldh [rBCPD], a
endr
	jr .sync_bcp_loop_continue
.bcp_not_changed
	ld a, CPAL_SIZE
	add l
	ld l, a
	adc h
	sub l
	ld h, a

	ldh a, [rBCPS]
	add CPAL_SIZE
	ldh [rBCPS], a

.sync_bcp_loop_continue
	dec c
	jr nz, .sync_bcp_loop

.ocp_sync
	ld hl, wGfx.ocp_changed
	ld a, [hl]
	and a
	ret z               ; EXIT: nothing to do
	ld d, a             ; D = ocp_changed
	xor a
	ld [hl], a          ; clear ocp_changed
	ld c, CPAL_OCP_COUNT
	ld hl, wOCP
	ld a, OCPSF_AUTOINC
	ldh [rOCPS], a

.sync_ocp_loop
	; check changed status bit for each palette
	srl d
	jr nz, :+           ; if no (more) bits set
	ret nc
	ld c, 1             ; make this the last iteration
:
	jr nc, .ocp_not_changed
rept 4 ; 4 colors
	WaitVRAM
	ld a, [hl+]
	ldh [rOCPD], a
	ld a, [hl+]
	ldh [rOCPD], a
endr
	jr .sync_ocp_loop_continue
.ocp_not_changed
	ld a, CPAL_SIZE
	add l
	ld l, a
	adc h
	sub l
	ld h, a

	ldh a, [rOCPS]
	add CPAL_SIZE
	ldh [rOCPS], a

.sync_ocp_loop_continue
	dec c
	jr nz, .sync_ocp_loop

	ret


gfx_load_default_font::
	PushRomb bank(default_font)
	ld hl, vFontTiles
	ld de, default_font
	ld bc, ONEBIT_MONO_RES_SIZE
	call vmem_copy_double
	PopRomb
	ret


; load tile data for game objects
gfx_load_game_obj::
	PushRomb bank(LoadoPrg_LoadGameObj)
	ld de, LoadoPrg_LoadGameObj
	call loado_load_program
	call loado_exec
	PopRomb
	ret


gfx_load_bg_tiles::
	ret


gfx_load_default_palettes::
	; DMG
	ld a, %11100100
	ldh [rBGP], a
	ldh [rOBP0], a
	ld a, %01101100
	ldh [rOBP1], a

	; CGB
	PushRomb bank("Gfx/ColorPalettesDefault")
	ld de, bcp_start
	ld hl, wBCP_src
	ld bc, DEFAULT_BCP_COUNT * 4 * 2
	call mem_copy
	ld de, wBCP_src
	ld hl, wBCP
	ld bc, DEFAULT_BCP_COUNT * 4 * 2
	call mem_copy
	ld de, ocp_start
	ld hl, wOCP_src
	ld bc, DEFAULT_OCP_COUNT * 4 * 2
	call mem_copy
	ld de, wOCP_src
	ld hl, wOCP
	ld bc, DEFAULT_OCP_COUNT * 4 * 2
	call mem_copy
	PopRomb

	ld hl, wGfx.bcp_changed
	ld a, $FF
	ld [hl+], a ; bcp_changed
	ld [hl+], a ; ocp_changed

	call gfx_palette_sync

	ret


; Fill BG attribute map
; @param D: attr value
; @mut: AF, BC, HL
gfx_bg_attr_fill::
	ld a, [wBootA]
	cp BOOTUP_A_CGB
	ret nz

	ld a, 1
	ldh [rVBK], a
	ld hl, $9800
	ld bc, 32 * 32
	call vmem_fill
	xor a
	ldh [rVBK], a
	ret


section "GfxData", romx

default_font: incbin "res/onebit-mono.1bpp", 0, ONEBIT_MONO_RES_SIZE


	ShrimpIncbin "res/shapes.2bpp"
	ShrimpIncbin "res/ball.2bpp"
	ShrimpIncbin "res/ballder_rolling.2bpp"
	ShrimpIncbin "res/map/buildings.2bpp"
	ShrimpIncbin "res/map/terrain.2bpp"
	ShrimpIncbin "res/map/warships/patrol.2bpp"
	ShrimpIncbin "res/map/warships/cruiser.2bpp"
	ShrimpIncbin "res/map/warships/submarine.2bpp"
	ShrimpIncbin "res/ball_pile.2bpp"


LoadoPrg_LoadGameObj:
	db LOADOCODE_CHRB_0

	LoadocodeROMB "res/shapes.2bpp"
	db LOADOCODE_SRC
	dw res_shapes_2bpp
	db LOADOCODE_DEST_CHR, tShapes
	db LOADOCODE_CHRCOPY, tShapes_count

	LoadocodeROMB "res/ball.2bpp"
	db LOADOCODE_SRC
	dw res_ball_2bpp
	db LOADOCODE_SRC_CHR, 0
	db LOADOCODE_DEST_CHR, tBall
	db LOADOCODE_CHRCOPY, tBall_count

	LoadocodeROMB "res/ballder_rolling.2bpp"
	db LOADOCODE_SRC
	dw res_ballder_rolling_2bpp
	db LOADOCODE_SRC_CHR, 0
	db LOADOCODE_DEST_CHR, tBallder_rolling
	db LOADOCODE_CHRCOPY, tBallder_rolling_count

	db LOADOCODE_STOP


section "Gfx/ColorPalettesDefault", romx

def DEFAULT_OCP_COUNT equ 4
def DEFAULT_BCP_COUNT equ 4

ocp_start:
cpal_grey:
	ColorW 28, 28, 28
	ColorW 18, 18, 18
	ColorW 9, 9, 9
	ColorW 2, 2, 2

bcp_start:
cpal_eggplant:
	ColorW 27, 28, 26
	ColorW 21, 20, 18
	ColorW 12, 10, 11
	ColorW 7, 4, 6

cpal_pinkli:
	ColorW 29, 26, 29
	ColorW 25, 23, 24
	ColorW 13, 9, 12
	ColorW 8, 5, 8

cpal_bluen:
	ColorW 27, 28, 29
	ColorW 19, 22, 24
	ColorW 13, 14, 19
	ColorW 6, 7, 9

cpal_greybg:
	ColorW 27, 28, 26
	ColorW 18, 18, 18
	ColorW 9, 9, 9
	ColorW 2, 2, 2


section "Gfx/Fade5", rom0, align[4]
; Fade5
; 6 colours * 2 = 12 bytes ==> align to %----0000
; Aligned so each stage (t0, .. t5) can be accessed using a 4 bit offset with no overflow
Fade5:
	.t0 ; 0 src
	ColorRRR %00000
	.t1
	ColorRRR %00001
	.t2
	ColorRRR %00011
	.t3
	ColorRRR %00111
	.t4
	ColorRRR %01111
	.t5 ; full src
	ColorRRR %11111


; Step Fade5 sequence 'in'
; @param E: low byte of fade sequence stage pointer
; @return E: updated low byte of fade sequence stage pointer
; @return F.C: set if changed
; @mut: AF, E
Fade5_step_in:
	ld a, e
	ld e, low(Fade5.t5)
	cp e
	ret nc ; NC: (A >= END) ==> (return E = END)
	; C: (A < END) ==> (return E = A + 2)
	add 2
	ld e, a
	scf
	ret


; Step Fade5 sequence 'out'
; @param E: low byte of fade sequence stage pointer
; @return E: updated low byte of fade sequence stage pointer
; @return F.C: set if changed
; @mut: AF, E
Fade5_step_out:
	ld a, low(Fade5.t0)
	cp e
	jr nc, .done ; NC: (END >= E) ==> (return E = END)
	; C: (E > END) ==> (return E -= 2)
	ld a, e
	sub 2
	scf
.done
	ld e, a
	ret
