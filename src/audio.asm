/******************************************************************************
* AUDIO
*
* Music code based on hUGETracker/hUGEDriver:
*   https://github.com/SuperDisk/hUGETracker
*
* Sound effects system originally based on sfx_driver.asm by Evie M:
*   https://github.com/eievui5/esprit/blob/main/src/sfx_driver.asm
******************************************************************************/

include "common.inc"

section "audio", rom0

; Starts the hUGE track at HL
; @param A: romb0
music_play::
	di
	ld [wMusicRomb], a

	call music_stop

	PushRomb [wMusicRomb]
	call hUGE_init
	PopRomb

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

	PushRomb [wMusicRomb]
	; mute music channels that are muted or used by sound player
	ldh a, [hMusic.mute]
	ld c, a
	ldh a, [hSound.channels]
	or c
	ld c, a
	call hUGE_set_mute
	call hUGE_dosound
	PopRomb
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
; @mut: AF, C, DE
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
	ldh [hSoundQueueNext], a
	ldh [hSoundQueueTimer], a

	ret


; Start sound playback if there is no active sound.
; @param HL: address of Sound Data
; @mut: AF, C, DE, HL
sound_try_play::
	ldh a, [hSound.timer]
	and a
	ret nz

; Start sound playback, interrupting active sound (if any)
; @param HL: address of Sound Data
; @mut: AF, C, DE, HL
sound_play::
	call sound_stop
sound_force_play:
	PushRomb bank("Sounds")
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
	jr z, .end
	ld c, a
	ld a, [hl+]
	ldh [c], a
	jr .setRegs
.end
	PopRomb
	ret


; Play a sound after a delay period.
; @param A: delay ticks
; @param HL: address of sound to play
; @mut: A
sound_play_delayed::
	ldh [hSoundQueueTimer], a
	ld a, l
	ldh [hSoundQueueNext + 0], a
	ld a, h
	ldh [hSoundQueueNext + 1], a

	ret


sound_update::
	; update queue timer
	ldh a, [hSoundQueueTimer]
	and a
	jr z, :+
	dec a
	ldh [hSoundQueueTimer], a
	jr nz, :+
	; timer just hit zero
	ldh a, [hSoundQueueNext + 0]
	ld l, a
	ldh a, [hSoundQueueNext + 1]
	ld h, a
	or l
	jr z, :+ ; no queued sound
	jp sound_play
:
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

wSoundQueueDelay: db ; initial queue_delay value

wMusicRomb: db ; the ROM bank that contains the current song data

section "hAudio", hram

hAudioStatus:: db

hMusic::
	.mute:: db

hSound::
	.next:: dw
	.channels:: db ; channels in use by sound playback
	.timer:: db

hSoundQueueNext: dw
hSoundQueueTimer: db


section "Audio Resource Tables", rom0

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
