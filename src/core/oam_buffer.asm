INCLUDE "common.inc"

def OAM_BUFFER_SIZE equ OAM_COUNT * sizeof_OAM_ATTRS

SECTION "OAMBufferState", WRAM0, ALIGN[8]
; The OAM "shadow buffer".
wOAMBuffer:: ds OAM_BUFFER_SIZE

; Points to next unused OAM entry
wOAM_end:: dw

SECTION "OAM setup", ROM0
; Store HL as next available OAM entry address
; @mut: A
oam_next_store::
	ld a, l
	ld [wOAM_end + 0], a
	ld a, h
	ld [wOAM_end + 1], a
	ret

; Load (previously stored) next available OAM entry address into HL
; @ret HL: the 'Next' pointer.
; @mut: A
oam_next_recall::
	ld hl, wOAM_end
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ret

; Check if the 'next' pointer (wOAM_end) is valid.
; (valid = within bounds && aligned to entry[0])
; @return F.Z: address is valid
; @mut: AF
oam_next_ok::
	ld a, [wOAM_end + 1]
	cp high(wOAMBuffer)
	ret nz
	ld a, [wOAM_end + 0]
	cp OAM_BUFFER_SIZE
	jr c, :+
	; overrun
	or 1 ; clear F.Z
	ret
:
	and 3 ; F.Z if end % 4 == 0
	ret

; Clear OAM buffer, reset the 'Next' pointer.
oam_clear::
	ld hl, wOAMBuffer
	call oam_next_store
	ld c, OAM_BUFFER_SIZE
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
