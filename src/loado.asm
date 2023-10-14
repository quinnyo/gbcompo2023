/***********************************************************
*                                  Loado Loado Loado Loado *
***********************************************************/

include "defines.asm"
include "loado.inc"


section "wLoado", wram0
	st Loado, wLoado


section "Loado", rom0


loado_init::
	xor a
	ld hl, wLoado
	ld c, Loado_sz
:
	ld [hl+], a
	dec c
	jr nz, :-

	ret


; @param DE: program start address
loado_load_program::
	call loado_init
	ld hl, wLoado.prg
	ld a, e
	ld [hl+], a
	ld a, d
	ld [hl+], a
	; wLoado.stat
	ld a, LOADO_STATF_READY
	ld [hl+], a
	ret


; Run the program until it stops
loado_exec::
:
	ld hl, wLoado.stat
	bit LOADO_STATB_STOP, [hl]
	ret nz
	call loado_tick
	jr :-

	ret


; advance the program, read and execute the next opcode
loado_tick:
	ld hl, wLoado.prg
	ld a, [hl+]
	ld h, [hl]
	ld l, a

	; get opcode, read correct number of args
	ld a, [hl+]
	ld d, a
	cp LOADOCODE1__MAX
	jr c, .read1
	cp LOADOCODE2__MAX
	jr c, .read2
	cp LOADOCODE0__MAX
	jr c, .read0
	jr prg_panic
.read2
	ld a, [hl+]
	ld c, a
.read1
	ld a, [hl+]
	ld b, a
.read0

	ld a, l
	ld [wLoado.prg], a
	ld a, h
	ld [wLoado.prg+1], a

	; double opcode for use as jump offset
	ld a, d
	rlca
	rst jump_switch
	; op1
	dw op1_romb0
	dw op1_src_chr
	dw op1_dest_chr
	dw op1_src_chroff
	dw op1_dest_chroff
	dw op1_chrcopy
	dw op1_chrpick
	; op2
	dw op2_src
	dw op2_dest
	dw op2_memcopy
	dw op2_vmemcopy
	; op0
	dw op0_stop
	dw op0_chrb_0
	dw op0_chrb_1
	dw op0_chrb_2

:
	ld b, b
	jr :-


prg_panic:
	ld hl, wLoado.stat
	set LOADO_STATB_STOP, [hl]
	ret


op1_romb0:
	ld a, b
	rst rom_sel
	ret

op1_src_chr:
	ld c, b
	call _tiles_byte_length
	ld hl, wLoado.chrsrc
	ld a, c
	ld [hl+], a
	ld [hl], b
	ret

op1_dest_chr:
	ld c, b
	call _tiles_byte_length
	ld hl, wLoado.chrdest
	ld a, c
	ld [hl+], a
	ld [hl], b
	ret

op1_src_chroff:
	ld c, b
	call _tiles_byte_length
	ld hl, wLoado.chrsrc
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	add hl, bc
	ld a, l
	ld b, h
	ld hl, wLoado.chrsrc
	ld [hl+], a
	ld [hl], b
	ret

op1_dest_chroff:
	ld c, b
	call _tiles_byte_length
	ld hl, wLoado.chrdest
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	add hl, bc
	ld a, l
	ld b, h
	ld hl, wLoado.chrdest
	ld [hl+], a
	ld [hl], b
	ret

op1_chrcopy:
	ld hl, wLoado.msrc
	ld a, [hl+]
	ld d, [hl]
	ld e, a
	ld hl, wLoado.chrsrc
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	add hl, de
	push hl ; SRC

	ld hl, wLoado.mdest
	ld a, [hl+]
	ld d, [hl]
	ld e, a
	ld hl, wLoado.chrdest
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	add hl, de ; HL = DEST
	pop de ; DE = SRC

	ld c, b
	call _tiles_byte_length
	push bc ; LENGTH
	call vmem_copy

	; update CHRSRC & CHRDEST
	pop bc ; LENGTH
	ld hl, wLoado.chrsrc
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	add hl, bc
	ld a, l
	ld [wLoado.chrsrc], a
	ld a, h
	ld [wLoado.chrsrc + 1], a

	ld hl, wLoado.chrdest
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	add hl, bc
	ld a, l
	ld [wLoado.chrdest], a
	ld a, h
	ld [wLoado.chrdest + 1], a

	ret

op1_chrpick:
	ret

op2_src:
	ld hl, wLoado.msrc
	ld a, c
	ld [hl+], a
	ld [hl], b
	ret

op2_dest:
	ld hl, wLoado.mdest
	ld a, c
	ld [hl+], a
	ld [hl], b
	ret

op2_memcopy:
	ld hl, wLoado.msrc
	ld a, [hl+]
	ld e, a
	ld a, [hl+]
	ld d, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	call mem_copy
	ld a, l
	ld b, h
	ld hl, wLoado.msrc
	ld [hl+], a
	ld [hl], b
	ret

op2_vmemcopy:
	ld hl, wLoado.msrc
	ld a, [hl+]
	ld e, a
	ld a, [hl+]
	ld d, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	call vmem_copy
	ld a, l
	ld b, h
	ld hl, wLoado.msrc
	ld [hl+], a
	ld [hl], b
	ret

op0_stop:
	ld hl, wLoado.stat
	set LOADO_STATB_STOP, [hl]
	ret

op0_chrb_0:
	ld bc, LOADO_CHRBLOCK0_MIN
	jr _set_chrb

op0_chrb_1:
	ld bc, LOADO_CHRBLOCK1_MIN
	jr _set_chrb

op0_chrb_2:
	ld bc, LOADO_CHRBLOCK2_MIN
	jr _set_chrb


; @param BC: CHRB base address
_set_chrb:
	xor a
	ld hl, wLoado.chrdest
	ld [hl+], a
	ld [hl+], a
	jr op2_dest


; @param C: tile count
; @return BC: byte length
_tiles_byte_length:
	xor a
rept 4 ; byte length = tile count * 16
	sla c
	rla
endr
	ld b, a
	ret
