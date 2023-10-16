INCLUDE "defines.asm"


SECTION "OAMBufferState", WRAM0, ALIGN[8]
; The OAM "shadow buffer".
wOAMBuffer::
	ds OAM_COUNT * sizeof_OAM_ATTRS
.end

; Points to next unused OAM entry
wNext: dw


SECTION "OAM setup", ROM0
; Store HL as next available OAM entry address
; @mut: A
oam_next_store::
	ld a, l
	ld [wNext], a
	ld a, h
	ld [wNext + 1], a
	ret

; Load (previously stored) next available OAM entry address into HL
; @ret HL: the 'Next' pointer.
; @mut: A
oam_next_recall::
	ld a, [wNext]
	ld l, a
	ld a, [wNext + 1]
	ld h, a
	ret

; Clear OAM buffer, reset the 'Next' pointer.
oam_clear::
	ld hl, wOAMBuffer
	call oam_next_store
	ld c, wOAMBuffer.end - wOAMBuffer
	xor a
:
	ld [hl+], a
	dec c
	jr nz, :-
	ret

; Initialize the OAM shadow buffer, and setup the OAM copy routine in HRAM.
oam_init::
	call oam_clear

	ld hl, hOAMCopyRoutine
	ld de, oamCopyRoutine
	ld c, hOAMCopyRoutine.end - hOAMCopyRoutine
.copyOAMRoutineLoop
	ld a, [de]
	inc de
	ld [hl+], a
	dec c
	jr nz, .copyOAMRoutineLoop
	; We directly copy to clear the initial OAM memory, which else contains garbage.
	call hOAMCopyRoutine
	ret

oamCopyRoutine:
LOAD "hram", HRAM
; Copy buffered data to OAM (DMA)
hOAMCopyRoutine::
	ld a, HIGH(wOAMBuffer)
	ldh [rDMA], a
	ld a, OAM_COUNT
.wait
	dec a
	jr nz, .wait
	ret
.end:
ENDL
