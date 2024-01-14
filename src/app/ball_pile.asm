include "common.inc"

def BALL_PILE_CHR_COUNT equ 13
def BALL_PILE_CHR0 equ 256 - BALL_PILE_CHR_COUNT

section "wBallPile", wram0
; first tile location (address in tilemap)
wBallPile_tile0: dw
; tile buffer top row
wBallPile_row0: ds 2
; tile buffer bottom row
wBallPile_row1: ds 2

wBallPile_dirty: db


section "BallPile", rom0
; @param D: Number of spare balls to display initially
; @mut: AF, BC, DE, HL
BallPile_setup::
	xor a
	ld [wBallPile_dirty], a

	call Ball_get_start_position
	ld a, b
	add 8
	ld b, a
	ld a, c
	sub 8
	ld c, a
	call world_point_to_tile
	ld a, l
	ld [wBallPile_tile0 + 0], a
	ld a, h
	ld [wBallPile_tile0 + 1], a

	call BallPile_set

	PushRomb bank("res/ball_pile.2bpp")
	ld hl, $8000 + 16 * BALL_PILE_CHR0
	ld de, res_ball_pile_2bpp
	ld bc, 16 * BALL_PILE_CHR_COUNT
	call vmem_copy
	PopRomb

	; FALLTHROUGH


; Copy tiles to tilemap immediately
BallPile_draw_now:
	ld hl, wBallPile_tile0
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ld de, wBallPile_row0
	ld c, 2
	call vmem_copy_short
	ld bc, 30
	add hl, bc
	ld c, 2
	call vmem_copy_short

	ld a, [wBootA]
	cp BOOTUP_A_CGB
	ret nz

	ld a, 1
	ldh [rVBK], a
	ld hl, wBallPile_tile0
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ld d, 3 ; TODO: not use a hard-coded literal palette id
	ld c, 2
	call vmem_fill_byte
	ld bc, 30
	add hl, bc
	ld c, 2
	call vmem_fill_byte
	xor a
	ldh [rVBK], a
	ret


; Copy tiles to tilemap, if changed
BallPile_draw::
	ld hl, wBallPile_dirty
	ld a, [hl]
	and a
	ret z
	xor a
	ld [hl], a

	di
	call BallPile_draw_now
	reti


; Set number of spare balls to display
; @param D: N
BallPile_set::
	ld a, 1
	ld [wBallPile_dirty], a
	ld hl, wBallPile_row0
	ld a, d
	cp 5
	jr c, :+
	cp 7
	jr c, _x6
	jr _x8
:
	ld a, BALL_PILE_CHR0 + BALL_PILE_CHR_COUNT - 1
	ld [hl+], a
	ld [hl+], a
	ld a, d
	cp 4
	jr z, _x4
	cp 3
	jr z, _x3
	cp 2
	jr z, _x2
	cp 1
	jr z, _x1
	jr _x0


; @param HL: dest buffer
_x8:
	; x8
	; 0, 1
	; 2, 3
	ld a, BALL_PILE_CHR0
	ld [hl+], a
	inc a
	ld [hl+], a
	inc a
	ld [hl+], a
	inc a
	ld [hl+], a
	ret

; @param HL: dest buffer
_x6:
	; x6
	; 4, EMPTY
	; 2, 5
	ld a, BALL_PILE_CHR0 + 4
	ld [hl+], a
	ld a, BALL_PILE_CHR0 + BALL_PILE_CHR_COUNT - 1
	ld [hl+], a
	ld a, BALL_PILE_CHR0 + 2
	ld [hl+], a
	ld a, BALL_PILE_CHR0 + 5
	ld [hl+], a
	ret

; @param HL: dest buffer
_x4:
	; x4
	; -
	; 6, 7
	ld a, BALL_PILE_CHR0 + 6
	ld [hl+], a
	inc a
	ld [hl+], a
	ret

; @param HL: dest buffer
_x3:
	; x3
	; -
	; 6, 8
	ld a, BALL_PILE_CHR0 + 6
	ld [hl+], a
	ld a, BALL_PILE_CHR0 + 8
	ld [hl+], a
	ret

; @param HL: dest buffer
_x2:
	; x2
	; -
	; 6, 9
	ld a, BALL_PILE_CHR0 + 6
	ld [hl+], a
	ld a, BALL_PILE_CHR0 + 9
	ld [hl+], a
	ret

; @param HL: dest buffer
_x1:
	; x1
	; -
	; 10, 11
	ld a, BALL_PILE_CHR0 + 10
	ld [hl+], a
	inc a
	ld [hl+], a
	ret

; @param HL: dest buffer
_x0:
	; x0
	; -
	; -, 11
	ld [hl+], a
	ld a, BALL_PILE_CHR0 + 11
	ld [hl+], a
	ret
