include "app/things.inc"
include "app/rules.inc"

section "std_rules/subthings", rom0

; Propagate destruction to subthings.
; @param C: dataLen
; @param DE: &data
; @mut: AF, BC, DE, HL
rule_subthings::
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


section "std_rules/multithing", rom0

rsreset
def MULTITHING_SCRATCH_DATA0    rb 1
def MULTITHING_SCRATCH_DATA1    rb 1
def MULTITHING_SCRATCH_DATALEN  rb 1
def MULTITHING_SCRATCH_STATUS0  rb 1
def MULTITHING_SCRATCH_STATUS1  rb 1
assert _RS < RULES_SCRATCH_BUFFER_SIZE

; Share any multithing member's destruction/damage with other members.
; All members receive any (OR) event flags + the lowest (AND) hits value.
; @param C: dataLen
; @param DE: &data -- a list of member thing tags.
; @mut: AF, BC, DE, HL
rule_multithing::
	ld hl, wRulesScratch
	ld a, e
	ld [hl+], a ; [wRulesScratch + 0] = &data.0
	ld a, d
	ld [hl+], a ; [wRulesScratch + 1] = &data.1
	ld a, c
	ld [hl+], a ; [wRulesScratch + 2] = dataLen
	xor a
	ld [hl+], a ; [wRulesScratch + 3] = status buffer
	ld a, fThingStatus_HITS
	ld [hl+], a ; [wRulesScratch + 4] = hits buffer

	; iter members, check for any events
.loop_a
	ld a, [de]
	inc de
	ld b, a
	call TagThings_query_tag
	ret c ; not found
	ld b, [hl] ; status
	ld hl, wRulesScratch + MULTITHING_SCRATCH_STATUS0
	bit bThingStatus_VOID, [hl]
	jr nz, .continue_a
	ld a, [hl]
	or b  ; OR flags
	ld [hl+], a
	ld a, [hl]
	and b ; AND hits
	ld [hl], a
.continue_a
	dec c
	jr nz, .loop_a

	; mask & combine collected status values
	ld hl, wRulesScratch + MULTITHING_SCRATCH_STATUS0
	ld a, [hl]
	and fThingStatus_EV_DIE
	ld b, a
	ld [hl+], a
	ld a, [hl]
	and fThingStatus_HITS
	or b
	ld [hl], a

	; iter members, apply combined status to all
	ld hl, wRulesScratch
	ld a, [hl+] ; [wRulesScratch + 0] = &data.0
	ld e, a
	ld a, [hl+] ; [wRulesScratch + 1] = &data.1
	ld d, a
	ld a, [hl+] ; [wRulesScratch + 2] = dataLen
	ld c, a
:
	ld a, [de]
	inc de
	ld b, a
	call TagThings_query_tag
	ret c ; not found
	ld a, [hl]  ; Thing.status
	and ~fThingStatus_HITS
	ld b, a
	ld a, [wRulesScratch + MULTITHING_SCRATCH_STATUS1]
	or b
	ld [hl], a
	dec c
	jr nz, :-

	ret
