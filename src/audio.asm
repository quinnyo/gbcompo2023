/******************************************************************************
* AUDIO
*
* Music code based on hUGETracker/hUGEDriver:
*   https://github.com/SuperDisk/hUGETracker
*
* Sound effects system originally based on sfx_driver.asm by Evie M:
*   https://github.com/eievui5/esprit/blob/main/src/sfx_driver.asm
******************************************************************************/

include "defines.asm"

def CH1           equ %0001
def CH2           equ %0010
def CH3           equ %0100
def CH4           equ %1000
def CH_ALL        equ %1111


section "audio", rom0

; Starts the hUGE track at HL
music_play::
	di

	call music_stop

	call hUGE_init

	ldh a, [hAudioStatus]
	set AUDIO_STATB_MUSIC, a
	ldh [hAudioStatus], a

	xor a
	ldh [hMusic.mute], a

	reti


; Stop music playback (if any).
music_stop::
	ldh a, [hAudioStatus]
	bit AUDIO_STATB_MUSIC, a
	ret z

	res AUDIO_STATB_MUSIC, a
	ldh [hAudioStatus], a

	; cut channels that are not in use by sound
	ld c, CH_ALL
	bit AUDIO_STATB_SOUND, a
	jr z, :+
	ldh a, [hSound.channels]
	xor c
	ld c, a
:
	call audio_channels_cut

	ret


; Initialise audio system.
; Must be called once before any other audio routine.
audio_init::
	xor a
	ldh [rNR52], a
	ldh [hAudioStatus], a
	ldh [hMusic.mute], a
	ld a, $FF
	ld [wAudioMixer], a
	ld a, $77
	ld [wAudioVolume], a
	call sound_init

	call musctl_init

	ret


; Turn on the APU and enable audio processing. If the APU is already on, do nothing.
audio_on::
	ldh a, [rNR52]
	bit 7, a
	ret nz

	ld a, $80
	ldh [rNR52], a

	ret


; Stop all playback and disable audio processing.
audio_off::
	xor a
	ldh [rNR52], a
	ldh [hAudioStatus], a
	call sound_init
	ret


; per-frame audio system tick
audio_update::
	ldh a, [rNR52]
	bit 7, a
	ret z

	call musctl_update

	ld a, [wAudioVolume]
	ldh [rNR50], a
	ld a, [wAudioMixer]
	ldh [rNR51], a

	ldh a, [hAudioStatus]
	bit AUDIO_STATB_MUSIC, a
	jr z, .no_music

	; mute music channels that are muted or used by sound player
	ldh a, [hMusic.mute]
	ld c, a
	ldh a, [hSound.channels]
	or c
	ld c, a
	call hUGE_set_mute

	call hUGE_dosound
.no_music

	call sound_update

	ret


; Silence selected channels, leaving configuration as is.
; @param C: channels to cut (bitmask)
; @mut: AF, DE
audio_channels_cut::
	ld d, $08 ; Ch volume, avoid DAC off by setting env = 1
	ld e, $80 ; Ch trigger
	ld a, d

	bit 0, c
	jr z, :+
	; CH1
	ldh [rNR12], a
	ld a, e
	ldh [rNR14], a
	ld a, d
:
	bit 1, c
	jr z, :+
	; CH2
	ldh [rNR22], a
	ld a, e
	ldh [rNR24], a
	ld a, d
:
	bit 2, c
	jr z, :+
	; CH3
	ld a, 255
	ldh [rNR31], a
	ld a, $C0
	ldh [rNR34], a
	ld a, d
:
	bit 3, c
	jr z, :+
	; CH4
	ldh [rNR42], a
	ld a, e
	ldh [rNR44], a
	ld a, d
:
	ret


; Stop playback, clear state and unmute music
sound_stop::
	; clear sound active flag
	ldh a, [hAudioStatus]
	res AUDIO_STATB_SOUND, a
	ldh [hAudioStatus], a

	ldh a, [hSound.channels]
	and a
	jr z, :+
	ld c, a
	call audio_channels_cut
:
sound_init::
	xor a
	ldh [hSound.channels], a
	ldh [hSound.timer], a
	ldh [hSound.next + 0], a
	ldh [hSound.next + 1], a

	ret


; Start sound playback if there is no active sound.
; @param HL: address of Sound Data
sound_try_play::
	ldh a, [hSound.timer]
	and a
	ret nz

; Start sound playback, interrupting active sound (if any)
; @param HL: address of Sound Data
sound_play::
	call sound_stop
sound_force_play:
	; TODO: ? swap ROM bank (push bank("Sounds"))

	ldh a, [hAudioStatus]
	set AUDIO_STATB_SOUND, a
	ldh [hAudioStatus], a

	ld a, [hl+] ; Part.channels
	ldh [hSound.channels], a
	ld a, [hl+] ; Part.duration
	ldh [hSound.timer], a
	ld a, [hl+] ; Part.next
	ldh [hSound.next + 0], a
	ld a, [hl+]
	ldh [hSound.next + 1], a
.setRegs:
	ld a, [hl+]
	and a
	; TODO: ? swap ROM bank back (pop) if done
	ret z
	ld c, a
	ld a, [hl+]
	ldh [c], a
	jr .setRegs


sound_update::
	; check if a sound is playing
	ldh a, [hSound.timer]
	and a
	ret z
	; then decrement it and wait for it to finish
	dec a
	ldh [hSound.timer], a
	ret nz ; the first time 0 is reached, mute channels and check for a new segment.

	; release channels
	ldh a, [hSound.channels]
	and a
	jr z, :+
	ld c, a
	call audio_channels_cut
:

	ldh a, [hSound.next + 0]
	ld l, a
	ldh a, [hSound.next + 1]
	ld h, a
	or l
	jp nz, sound_force_play
	jp sound_stop


/**********************************************************
***************************** musctl | Music Controller ***
**********************************************************/

musctl_init::
	ld a, MUSCTLF_DEFAULT
	ld [wMusctlCtl], a
	ld a, $FF
	ld [wMusctlCurrent], a
	ld [wMusctlQueue], a

	ret


; Play or queue a track from the music table.
; @param B: music table index
; @mut: AF, HL
musctl_play_next::
	ld a, [wMusctlCurrent]
	cp $FF
	jr z, musctl_load ; load new track immediately if nothing loaded
	cp b
	ret z ; already playing that ...

	ld a, b
	ld [wMusctlQueue], a

	ld hl, wMusctlCtl
	set MUSCTLB_QUEUE_FEED, [hl]

	ret


; All stop immediately -- stop playback, unload, reset queue.
musctl_stop::
	call music_stop
	ld a, MUSCTLF_DEFAULT
	ld [wMusctlCtl], a
	ld a, $FF
	ld [wMusctlCurrent], a
	ld [wMusctlQueue], a

	ret


; Load and play a track from the music table.
; @param B: music table index
; @mut: AF, D
musctl_load::
	ld a, b
	ld [wMusctlCurrent], a
	call music_table_lookup
	ld a, d
	cp $FF
	jp c, music_play
; Stop playback and unload the loaded track
musctl_unload::
	call music_stop
	ld a, $FF
	ld [wMusctlCurrent], a
	ret


musctl_update::
	ld a, [wMusctlCtl]
	bit MUSCTLB_QUEUE_FEED, a
	jr nz, _musctl_queue_update
	ret


_musctl_queue_update:
	ld a, [wMusctlQueue]
	ld b, a
	ld a, [wMusctlCurrent]
	cp b
	jr nz, :+
	ld a, $FF
	ld [wMusctlQueue], a
	ld hl, wMusctlCtl
	res MUSCTLB_QUEUE_FEED, [hl]
	ret
:

	ld a, [wMusctlCurrent]
	cp $FF
	jr c, musctl_unload

	ld a, [wMusctlQueue]
	ld b, a
	cp $FF
	jr c, musctl_load
	ret


section "wAudio", wram0
wAudioVolume:: db ; Master volume & balance as in NR50
wAudioMixer:: db ; Channel mixer as in NR51

wMusctlCtl:: db      ; Music Player control flags
wMusctlCurrent:: db  ; music table index of active/playing track
wMusctlQueue:: db    ; music table index of track to play next (if any)


section "hAudio", hram

hAudioStatus:: db

hMusic::
	.mute:: db

hSound::
	.next:: dw
	.channels:: db ; channels in use by sound playback
	.timer:: db


section "Sounds", romx

/**********************************************************
******************** SoundCode | Sound Definition Thing ***
**********************************************************/

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


def C3 equ 44
def C3s equ 156
def D3 equ 262
def D3s equ 363
def E3 equ 457
def F3 equ 547
def F3s equ 631
def G3 equ 710
def G3s equ 786
def A3 equ 854
def A3s equ 923
def B3 equ 986
def C4 equ 1046
def C4s equ 1102
def D4 equ 1155
def D4s equ 1205
def E4 equ 1253
def F4 equ 1297
def F4s equ 1339
def G4 equ 1379
def G4s equ 1417
def A4 equ 1452
def A4s equ 1486
def B4 equ 1517
def C5 equ 1546
def C5s equ 1575
def D5 equ 1602
def D5s equ 1627
def E5 equ 1650
def F5 equ 1673
def F5s equ 1694
def G5 equ 1714
def G5s equ 1732
def A5 equ 1750
def A5s equ 1767
def B5 equ 1783
def C6 equ 1798
def C6s equ 1812
def D6 equ 1825
def D6s equ 1837
def E6 equ 1849
def F6 equ 1860
def F6s equ 1871
def G6 equ 1881
def G6s equ 1890
def A6 equ 1899
def A6s equ 1907
def B6 equ 1915
def C7 equ 1923
def C7s equ 1930
def D7 equ 1936
def D7s equ 1943
def E7 equ 1949
def F7 equ 1954
def F7s equ 1959
def G7 equ 1964
def G7s equ 1969
def A7 equ 1974
def A7s equ 1978
def B7 equ 1982
def C8 equ 1985
def C8s equ 1988
def D8 equ 1992
def D8s equ 1995
def E8 equ 1998
def F8 equ 2001
def F8s equ 2004
def G8 equ 2006
def G8s equ 2009
def A8 equ 2011
def A8s equ 2013
def B8 equ 2015


snd_ui_move::
	ScPart CH2, 2, :+
	ScReg rNR21, $80 | 16
	ScReg rNR22, $A1
	ScReg rNR23, low(E6)
	ScReg rNR24, high(E6) | $C0
	ScEnd
:
	ScPart CH2, 5
	ScReg rNR21, $80 | 16
	ScReg rNR22, $81
	ScReg rNR23, low(F6)
	ScReg rNR24, high(F6) | $C0
	ScEnd

snd_ui_nav_enter::
	ScPart CH2, 2, :+
	ScReg rNR21, $80 | 16
	ScReg rNR22, $A1
	ScReg rNR23, low(F6s)
	ScReg rNR24, high(F6s) | $C0
	ScEnd
:
	ScPart CH2, 6, :+
	ScReg rNR21, $80 | 46
	ScReg rNR22, $81
	ScReg rNR23, low(G6)
	ScReg rNR24, high(G6) | $C0
	ScEnd
:
	ScPart CH2, 2, :+
	ScReg rNR21, $80 | 16
	ScReg rNR22, $A1
	ScReg rNR23, low(G6s)
	ScReg rNR24, high(G6s) | $C0
	ScEnd
:
	ScPart CH2, 9
	ScReg rNR21, $80 | 46
	ScReg rNR22, $81
	ScReg rNR23, low(A6)
	ScReg rNR24, high(A6) | $C0
	ScEnd

snd_ui_nav_exit::
	ScPart CH2, 2, :+
	ScReg rNR21, $80 | 16
	ScReg rNR22, $A1
	ScReg rNR23, low(F6s)
	ScReg rNR24, high(F6s) | $C0
	ScEnd
:
	ScPart CH2, 6, :+
	ScReg rNR21, $80 | 46
	ScReg rNR22, $81
	ScReg rNR23, low(G6)
	ScReg rNR24, high(G6) | $C0
	ScEnd
:
	ScPart CH2, 2, :+
	ScReg rNR21, $80 | 16
	ScReg rNR22, $A1
	ScReg rNR23, low(E6)
	ScReg rNR24, high(E6) | $C0
	ScEnd
:
	ScPart CH2, 9
	ScReg rNR21, $80 | 46
	ScReg rNR22, $81
	ScReg rNR23, low(F6)
	ScReg rNR24, high(F6) | $C0
	ScEnd


section "Audio Resource Tables", rom0

/**********************************************************
******************************************* Sound Table ***
**********************************************************/

; The number of sounds defined in the sound table
sound_table_size:: db SND_COUNT
; The sound table
sound_table::
for I, SND_COUNT
	dw _snd_{u:I}
endr


/**********************************************************
******************************************* Music Table ***
**********************************************************/


include "mus.inc"

music_table::
	MusicTableBuild


; Look up music table record by index.
; @param B: index
; @ret HL: address[index] -- address of record in music table
music_table_at_index::
	ld hl, music_table
	assert MUSIC_TABLE_STRIDE == 3
	; multiply by 3
	ld d, 0
	ld a, b
	sla a
	rl d
	add b
	jr nc, :+
	inc d
:
	ld e, a
	add hl, de
	ret


; Look up music table record by index.
; Does bounds check, will return D==$FF on failure.
; @param B: index
; @ret D: bank[index] -- bank containing music data
; @ret HL: address[index] -- address of music data
music_table_lookup::
	; check out of bounds
	ld d, $FF
	ld a, [music_table.size]
	ld l, a
	ld a, b
	cp l
	ret nc

	call music_table_at_index
	ld a, [hl+]
	ld d, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a

	ret
