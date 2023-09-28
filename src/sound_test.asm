include "defines.asm"


section "SoundTest", rom0

SoundTest_init::
	ld de, TileData
	ld hl, $8800
	ld bc, TileData.end - TileData
	call vmem_copy

	ld hl, $9800
.bgloop
	ld de, BGPattern
.patternloop
	ld a, [de]
	and a
	jr z, .bgloop
	ld b, a
	inc de

	WaitVRAM
	ld [hl], b
	inc hl

	ld a, h
	cp $9C ; end = $9C00
	jr nz, .patternloop

	xor a
	ld [wSelection], a
	ldh [rSCX], a
	ldh [rSCY], a

	call audio_on
	call music_stop

	ret


SoundTest_main_iter::
	ld a, [wInput.state]
	bit PADB_B, a
	jr z, :+
	and $F0
	swap a
	ldh [hMusic.mute], a
	ret
:

	ld a, [wInput.pressed]
	ld b, a

.select_sound
	ld a, [sound_table_size]
	ld l, a
	ld a, [wSelection]
	bit PADB_LEFT, b
	jr z, .select_right
	and a
	jr nz, :+
	ld a, l
:
	dec a
	jr .select_apply
.select_right
	bit PADB_RIGHT, b
	jr z, .select_done
	inc a
	cp l
	jr c, :+
	xor a
:
	jr .select_apply
.select_apply
	ld [wSelection], a
	call trig_sound
.select_done

	bit PADB_A, b
	call nz, trig_sound

	bit PADB_START, b
	call nz, trig_music

	bit PADB_SELECT, b
	call nz, sound_stop

	ret


; Play the selected sound (loads index from [wSelection])
trig_sound:
	ld a, [sound_table_size]
	ld l, a
	ld a, [wSelection]
	cp l
	ret nc

	ld hl, sound_table
	sla a
	jr nc, :+
	inc h
:
	add l
	ld l, a
	adc h
	sub l
	ld h, a

	; read table entry; load address of sound def
	ld a, [hl+]
	ld h, [hl]
	ld l, a

	jp sound_play


trig_music:
	ldh a, [hAudioStatus]
	bit AUDIO_STATB_MUSIC, a
	jr z, :+
	call music_stop
	ret
:

	ld hl, mus99
	call music_play
	ret


section "SoundTest State", wramx
wSelection: db


section "SoundTest Data", romx


TileData:
	dw `12321120
	dw `01232110
	dw `01232321
	dw `12321221
	dw `22011232
	dw `32200123
	dw `23210112
	dw `12321012

	dw `01210010
	dw `01122110
	dw `01231220
	dw `01220221
	dw `12010231
	dw `22100122
	dw `12210112
	dw `01221011

	dw `01210010
	dw `01121011
	dw `01210120
	dw `01210110
	dw `21000121
	dw `21011012
	dw `12100112
	dw `01210121
.end

rsset 128
def t0 rb 1
def t1 rb 1
def t2 rb 1

BGPattern:
	db t1, t0, t1, t2, t0, t0, t1
	db t0, t0, t1, t0, t2, t0, t1
	db t1, t0, t0, t0, t1, t2, t0
	db t0, t0, t1, t0, t1, t0,  0
