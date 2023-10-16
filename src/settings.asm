include "common.inc"

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
