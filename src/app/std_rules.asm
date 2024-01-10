include "app/things.inc"

section "std_rules", rom0

; @param C: dataLen
; @param DE: &data
; @mut: AF, BC, DE, HL
rule_multithing::
	ld a, 1
	cp c
	ret nc
	; first param is parent (thing tag)
	ld a, [de]
	; read parent status
	ld b, a
	call TagThings_query_tag
	ret c ; not found
	ld a, [hl]
	and fThingStatus_HITS
	ret nz ; parent is alive, nothing to do
	ld a, ThingTag_UNSET ; Stop rule by setting parent to ThingTag_UNSET
	ld [de], a
	inc de
	dec c
.loop_subthings
	ld a, [de]
	inc de
	ld b, a
	call TagThings_destroy
	dec c
	jr nz, .loop_subthings

	ret
