include "common.inc"

; ascii mode
pushc
setcharmap main

def SAVE_FILE_FORMAT_VERSION equ 1
def SAVE_FILE_SIZE equ $200
def SAVE_FILE_IDENT equs "GigantGolfSave"
def SAVE_FILE_IDENT_LEN equ charlen("{SAVE_FILE_IDENT}")

	stdecl SaveHeader
		stfield ident, SAVE_FILE_IDENT_LEN
		stfield version
		stfield data_size, w
	stclose


section "NewSave", rom0
NewSaveIdent::    db "{SAVE_FILE_IDENT}"
NewSaveVersion::  db SAVE_FILE_FORMAT_VERSION
NewSaveDataSize:: dw 0

popc

section "wSave", wramx
wSaveIdent:    ds SAVE_FILE_IDENT_LEN
wSaveVersion:  db
wSaveDataSize: dw
wSaveData:     ds SAVE_FILE_SIZE - SaveHeader_sz - 1
wSaveChecksum: db


section "sSave", sram[$A000]
sSave0: ds SAVE_FILE_SIZE


section "SaveManager", wram0
wSaveBlockStart:: dw
wSaveDataEnd:     dw


section "Save", rom0
Save_init::
	ZeroSection "wSave"
	ret


; Read external save data into cache (wSave).
; If external data is not initialised, loads a clean save instead.
; Probably disable interrupts when you call this.
; NOTE: switches wram to bank containing wSave.
Save_fetch::
	ld a, bank("wSave")
	ldh [rSVBK], a
	ld a, bank("sSave")
	ld [rRAMB], a
	ld a, CART_SRAM_ENABLE
	ld [rRAMG], a
	ld bc, SAVE_FILE_SIZE
	ld de, startof("sSave")
	ld hl, startof("wSave")
	call mem_copy
	ld a, CART_SRAM_DISABLE
	ld [rRAMG], a
	call _Save_check
	ret


_Save_check:
	; compare ident
	ld de, wSaveIdent
	ld hl, NewSaveIdent
	ld c, SAVE_FILE_IDENT_LEN
:
	ld a, [de]
	inc de
	cp [hl]
	jp nz, _Save_clear
	inc hl
	dec c
	jr nz, :-

	; check version...
	ld a, [wSaveVersion]
	and a
	jr z, :+
	; version != 0, do checksum
	ld d, 0
	ld hl, startof("wSave")
	ld bc, SAVE_FILE_SIZE - 1
	call sum_range
	ld a, [wSaveChecksum]
	cp d
	jp nz, _Save_clear
:
	ret


; Write cached save data to external storage.
; Probably disable interrupts when you call this.
; NOTE: switches wram to bank containing wSave.
Save_store::
	ld a, bank("wSave")
	ldh [rSVBK], a
	ld a, SAVE_FILE_FORMAT_VERSION
	ld [wSaveVersion], a
	call _Save_update_checksum
	ld a, bank("sSave")
	ld [rRAMB], a
	ld a, CART_SRAM_ENABLE
	ld [rRAMG], a
	ld bc, SAVE_FILE_SIZE
	ld de, startof("wSave")
	ld hl, startof("sSave")
	call mem_copy
	ld a, CART_SRAM_DISABLE
	ld [rRAMG], a
	ret


; Reset save data
; @mut: AF, BC, DE, HL
_Save_clear:
	ld bc, sizeof("NewSave")
	ld de, startof("NewSave")
	ld hl, startof("wSave")
	call mem_copy
	ld d, $FF
	ld bc, SAVE_FILE_SIZE - sizeof("NewSave")
	call mem_fill
	ret


; Calculate and store wSave checksum.
; @mut: AF, BC, D, HL
_Save_update_checksum:
	ld d, 0
	ld hl, startof("wSave")
	ld bc, SAVE_FILE_SIZE - 1
	call sum_range
	ld a, d
	ld [wSaveChecksum], a
	ret


; Start reading save data. Checks if there is data to read.
; NOTE: does not open the first data block.
; NOTE: switches wram to bank containing wSave.
; @return DE: address of first block (do not access this if F.Z is set)
; @return F.Z: set if there is no data to read.
Save_read_start::
	ld a, bank("wSave")
	ldh [rSVBK], a
	call _get_data_end
	ld hl, wSaveDataEnd
	ld a, e
	ld [hl+], a
	ld [hl], d

	ld hl, wSaveDataSize
	ld a, [hl+]
	or [hl]
	ret z
	ld de, wSaveData
	ret


; Access a data block (and process the block header).
; IMPORTANT: Save_read_start must have been called prior.
; NOTE: Assumes wSave bank is selected.
; @param DE: block address (start of block header)
; @return B: block type
; @return DE: block data start (address after block header)
; @return F.C: set on success
; @return F.Z: set if reached the end (ptr == end)
Save_open_block::
	; check pointer in range
	; NOTE: doesn't check lower bound...
	ld hl, wSaveDataEnd
	ld a, [hl+]
	ld h, [hl]
	ld l, a

	ld a, d
	cp h
	jr c, .range_ok
	ret nz ; out of range
	ld a, e
	cp l
	jr c, .range_ok
	ret ; Z: at end | NZ: out of range

.range_ok
	ld hl, wSaveBlockStart
	ld a, e
	ld [hl+], a
	ld a, d
	ld [hl+], a

	ld a, [de]
	ld b, a
	inc de
	or 1 ; clear F.Z
	scf
	ret


; Prepare the save data buffer for (re)writing.
; Reset the save data buffer size and 'end' pointer.
; NOTE: Assumes wSave bank is selected.
; @return DE: save data buffer 'end' pointer
; @mut: AF, DE
Save_write_start::
	xor a
	ld de, wSaveDataSize
	ld [de], a
	inc de
	ld [de], a
	inc de
	ret


; Prepare to write a data block.
; NOTE: Assumes wSave bank is selected.
; @param B: block type/ID
; @return DE: block data address
; @mut: AF, DE
Save_block_start::
	call _get_data_end
	ld a, e
	ld [wSaveBlockStart + 0], a
	ld a, d
	ld [wSaveBlockStart + 1], a
	ld a, b
	ld [de], a
	inc de
	ret


; Update the save data buffer 'end' pointer and wSaveDataSize.
; NOTE: Assumes wSave bank is selected.
; @param DE: block end address (excl.)
; @mut: AF, DE
Save_block_end::
	; Update total save data size
	ld a, e
	sub low(wSaveData)
	ld [wSaveDataSize + 0], a
	ld a, d
	sbc high(wSaveData)
	ld [wSaveDataSize + 1], a
	ret


; Get the save data buffer 'end' pointer.
; NOTE: Assumes wSave bank is selected.
; @return DE: Pointer to end of save data (excl.)
; @mut: AF, DE
_get_data_end:
	ld a, [wSaveDataSize + 0]
	add low(wSaveData)
	ld e, a
	ld a, [wSaveDataSize + 1]
	adc high(wSaveData)
	ld d, a
	ret


; @param D: sum
; @param HL: input data address
; @param BC: input data length
; @return D: sum
; @mut: AF, BC, D, HL
sum_range:
	ld a, b
	or c
	ret z

	ld a, d
	sub [hl]
	dec a
	ld d, a
	inc hl
	dec bc
	jr sum_range
