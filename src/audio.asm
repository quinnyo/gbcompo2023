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
	ldh a, [hAudioStatus]
	res AUDIO_STATB_MUSIC, a
	ldh [hAudioStatus], a

	call hUGE_init

	ldh a, [hAudioStatus]
	set AUDIO_STATB_MUSIC, a
	ldh [hAudioStatus], a

	xor a
	ldh [hMusic.mute], a

	ret


; Stop music playback (if any).
music_stop::
	ldh a, [hAudioStatus]
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

	ret


audio_on::
	xor a
	ldh [hAudioStatus], a
	ldh [hMusic.mute], a
	ld a, $80
	ldh [rNR52], a
	ld a, $FF
	ld [wAudioMixer], a
	ld a, $77
	ld [wAudioVolume], a

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


section "wAudio", wram0
wAudioVolume:: db ; Master volume & balance as in NR50
wAudioMixer:: db ; Channel mixer as in NR51


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
* SoundCode
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


sndA::
	ScPart CH1, 25
	ScReg rNR10, 0
	ScReg rNR11, 24
	ScReg rNR12, $F0
	ScReg rNR13, low(854)
	ScReg rNR14, $C0 | high(854)
	ScEnd

sndB::
	ScPart CH1, 25
	ScReg rNR10, 0
	ScReg rNR11, 24
	ScReg rNR12, $F0
	ScReg rNR13, low(1102)
	ScReg rNR14, $C0 | high(1102)
	ScEnd

sndC::
	ScPart CH1, 25
	ScReg rNR10, 0
	ScReg rNR11, 24
	ScReg rNR12, $F0
	ScReg rNR13, low(1253)
	ScReg rNR14, $C0 | high(1253)
	ScEnd

sndD::
	ScPart CH1 | CH2, 25
	ScReg rNR10, 0
	ScReg rNR11, 0
	ScReg rNR12, $F0
	ScReg rNR13, low(986)
	ScReg rNR14, $80 | high(986)
	ScReg rNR21, 0
	ScReg rNR22, $F0
	ScReg rNR23, low(1899)
	ScReg rNR24, $80 | high(1899)
	ScEnd

sndE::
	ScPart CH1 | CH2, 25
	ScReg rNR10, 0
	ScReg rNR11, 0
	ScReg rNR12, $F0
	ScReg rNR13, low(1205)
	ScReg rNR14, $80 | high(1205)
	ScReg rNR21, 0
	ScReg rNR22, $F0
	ScReg rNR23, low(1930)
	ScReg rNR24, $80 | high(1930)
	ScEnd

sndF::
	ScPart CH1 | CH2, 25
	ScReg rNR10, 0
	ScReg rNR11, 0
	ScReg rNR12, $F0
	ScReg rNR13, low(1297)
	ScReg rNR14, $80 | high(1297)
	ScReg rNR21, 0
	ScReg rNR22, $F0
	ScReg rNR23, low(1949)
	ScReg rNR24, $80 | high(1949)
	ScEnd

sndBlorp::
	ScPart CH1 | CH2, 10
	ScReg rNR11, $C0 | 20
	ScReg rNR12, $F0
	ScReg rNR13, low(1899)
	ScReg rNR14, high(1899) | $80
	ScReg rNR21, $80 | 24
	ScReg rNR22, $F0
	ScReg rNR23, low(1800)
	ScReg rNR24, high(1800) | $80
	ScEnd

sndBok::
	ScPart CH1, 96
	ScReg rNR11, $80
	ScReg rNR12, $F0
	ScReg rNR13, low(427)
	ScReg rNR14, high(427) | $40 | $80
	ScEnd

sndTok::
	ScPart CH1, 44
	ScReg rNR11, $80
	ScReg rNR12, $F0
	ScReg rNR13, low(923)
	ScReg rNR14, high(923) | $40 | $80
	ScEnd


; The number of sounds defined in the sound table
sound_table_size:: db SND_COUNT
; The sound table
sound_table::
for I, SND_COUNT
	dw _snd_{u:I}
endr
