; Display/LCDC management utility guy a.k.a. 'fancy LCDC'

include "common.inc"


section "Display", rom0
; Disable the LCD (waits for vblank)
; @mut: AF
Display_lcd_off::
:
	ldh a, [rLY]
	cp SCRN_Y
	jr c, :-
	xor a
	ldh [rLCDC], a
	ret


; Enable the LCD
; @mut: AF
Display_lcd_on::
	; Turn the LCD on, enable BG, enable OBJ
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_WINON | LCDCF_WIN9C00
	ldh [rLCDC], a
	ret
