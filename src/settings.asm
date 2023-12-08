include "common.inc"

def SETTINGS_FORMAT_VERSION equ 0

rsreset
def SETTING_LEVEL     rb 1
def SETTING__COUNT    rb 0


	stdecl Settings
		stfield level ; selected level index
	stclose

section "Settings State", wram0

	st Settings, wSettings


section "Settings Impl", rom0

settings_init::
	ld hl, wSettings
	ld c, Settings_sz
	xor a
:
	ld [hl+], a
	dec c
	jr nz, :-

	ret


; Write packed settings save data to buffer.
; @param DE: destination address
; @mut: AF, DE
settings_pack::
	ld a, SETTINGS_FORMAT_VERSION
	ld [de], a
	inc de
	ld a, 1
	ld [de], a
	inc de
	ld a, SETTING_LEVEL
	ld [de], a
	inc de
	ld a, [wSettings + Settings_level]
	ld [de], a
	inc de
	ret


; Unpack settings save data block.
; @param DE: block data address
; @mut: AF, C, DE
settings_unpack::
	ld a, [de]
	inc de
	cp SETTINGS_FORMAT_VERSION
	jr nz, .err_unknown_format
	ld a, [de]
	inc de
	and a
	ret z ; no entries
	ld c, a
:
	call _unpack_field
	dec c
	jr nz, :-

	ret

.err_unknown_format
	di
	ld b, b
	halt
	nop
	jr .err_unknown_format


_unpack_field:
	ld a, [de]
	inc de
	cp SETTING_LEVEL
	jr nz, :+
	ld a, [de]
	inc de
	ld [wSettings + Settings_level], a
	ret
:

.err_unknown_field
	di
	ld b, b
	halt
	nop
	jr .err_unknown_field
