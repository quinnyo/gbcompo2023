/*******************************************************************************
*                                                                     Collide! *
*******************************************************************************/

include "core/collide.inc"

section "wColliders", wram0, align[8]

; Collider box storage
wColliders:: ds COLLIDERS_POOL_SIZE

; Stores collision test results for each collider
wColliderStatus:: ds COLLIDE_RESULTS_SIZE

; The 'subject': collisions can be detected between the subject and other colliders.
wCollideSubject:: ds ColliderBox_sz

; Number of colliders in wColliders
wColliderCount:: db


section "Colliders", rom0
Collide_init::
	xor a
	ld c, ColliderBox_sz
	ld hl, wCollideSubject
	call mem_fill_byte

	; FALLTHROUGH

; Remove all colliders, clear results & status.
Collide_clear::
	ld a, $FF
	ld c, COLLIDERS_POOL_SIZE
	ld hl, wColliders
	call mem_fill_byte
	xor a
	ld [wColliderCount], a
	ld c, COLLIDE_RESULTS_SIZE
	ld hl, wColliderStatus
	call mem_fill_byte
	ret


; @param A: index
; @return A: result value
; @return HL: collider status address
Collide_get_status::
	ld hl, wColliderStatus
	add l
	ld l, a
	adc h
	sub l
	ld h, a
	ld a, [hl]
	ret


; Add a new collider to the pool.
; Caller's responsibility to initialising it.
; @return HL: new ColliderBox*
; @return A: new box index
; @mut: AF, HL
Collide_add_box::
	ld hl, wColliderCount
	ld a, [hl]
	cp COLLIDER_CAPACITY
	ret nc
	inc [hl]
	ld l, a

	; FALLTHROUGH

; Look up a box address by index.
; @param L: index
; @return HL: box address
; @mut: HL
Collide_get_box_at::
	sla l
	sla l
	ld h, high(wColliders)
	ret


; @param B,C: min X,Y
; @param A: index
; @mut: AF, HL
Collide_set_box_min::
	ld l, a
	call Collide_get_box_at
	ld a, b
	ld [hl+], a
	inc hl ; skip right
	ld [hl], c
	ret


; @param B,C: max X,Y
; @param A: index
; @mut: AF, HL
Collide_set_box_max::
	ld l, a
	call Collide_get_box_at
	inc hl ; skip left
	ld a, b
	ld [hl+], a
	inc hl ; skip top
	ld [hl], c
	ret


; @param B,C: new position X,Y (Left,Top)
; @param A: index
; @mut: AF, BC, HL
Collide_set_box_position::
	ld l, a
	call Collide_get_box_at

	; FALLTHROUGH

; Set box position
; @param B,C: new position X,Y (Left,Top)
; @param HL: this
; @mut: AF, BC, HL
Box_set_position::
	; dx = px - L
	ld a, b
	sub [hl]
	ld b, a
	; L' = L + dx
	ld a, [hl]
	add b
	ld [hl+], a
	; R' = R + dx
	ld a, [hl]
	add b
	ld [hl+], a
	; dy = py - T
	ld a, c
	sub [hl]
	ld c, a
	; T' = T + dy
	ld a, [hl]
	add c
	ld [hl+], a
	; B' = B + dy
	ld a, [hl]
	add c
	ld [hl+], a
	ret


; Set the subject collider as a 'missile'
; @param B,C: pX,pY missile centre
; @param E: missile radius
Collide_set_subject_missile::
	ld hl, wCollideSubject
	; left
	ld a, b
	sub e
	jr nc, :+
	xor a             ; >= 0
:
	ld [hl+], a       ; left
	; right
	ld a, b
	add e
	jr nc, :+
	ld a, 255         ; <= 255
:
	ld [hl+], a       ; right
	; top
	ld a, c
	sub e
	jr nc, :+
	xor a             ; >= 0
:
	ld [hl+], a       ; top
	; bottom
	ld a, c
	add e
	jr nc, :+
	ld a, 255         ; <= 255
:
	ld [hl+], a       ; bottom

	ret


; Load collider as 'subject' (cache collider data)
; @param DE: box
; @mut: AF, C, DE, HL
Collide_set_subject::
	ld hl, wCollideSubject
	ld c, ColliderBox_sz
	jp mem_copy_short


; Run collision test between each collider and 'subject'
; Pushes result (1 if collision detected, 0 if not) into
; bit 0 of each collider's wColliderStatus value.
Collide_all_subject::
assert low(wColliders) == 0, "Unexpected wColliders alignment."
assert COLLIDERS_POOL_SIZE <= 128
	ld a, [wColliderCount]
	and a
	ret z

	ld bc, wColliderStatus
	ld de, wColliders
:
	call Collide_box_subject
	ld a, [bc]
	rla                 ; rotate F.CY into A.0
	ld [bc], a
	inc bc
	ld a, e
	cp low(wColliders) + COLLIDERS_POOL_SIZE
	jr c, :-

	ret


; @param DE: box0
; @return DE: box0 end
; @return F.CY: set if collision detected
; @mut: AF, DE, HL
Collide_box_subject::
	; left0 >= right1
	ld hl, wCollideSubject + ColliderBox_right
	ld a, [de]   ; A = left0
	inc de
	cp [hl]
	jr nc, .nope

	; right0 <= left1
	dec hl ; wCollideSubject.left
	ld a, [de]   ; A = right0
	inc de
	dec a        ; A = right0 - 1
	cp [hl]
	jr c, .nope  ; [hl] > A // left1 > (right0 - 1)

	; top0 >= bottom1
	ld hl, wCollideSubject + ColliderBox_bottom
	ld a, [de]   ; A = top0
	inc de
	cp [hl]
	jr nc, .nope ; top0 <= bottom1

	; bottom0 <= top1
	dec hl ; wCollideSubject.top
	ld a, [de]
	inc de
	dec a        ; A = bottom0 - 1
	cp [hl]
	jr c, .nope  ; top1 > (bottom0 - 1)

	scf
	ret

.nope:
	; adjust DE to start of next element
	assert ColliderBox_sz == 4
	ld a, e
	add ColliderBox_sz
	and %11111100
	ld e, a

	scf
	ccf
	ret
