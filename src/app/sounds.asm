include "core/soundcode.inc"
include "note_table.inc"

section "Sounds", romx

/***********************************************************
*                                                UI Sounds *
***********************************************************/

snd_ui_move::
	ScPart CH2, 2, :+
	ScReg rNR21, $80 | 16
	ScReg rNR22, $A1
	ScReg rNR23, low(E06)
	ScReg rNR24, high(E06) | $C0
	ScEnd
:
	ScPart CH2, 5
	ScReg rNR21, $80 | 16
	ScReg rNR22, $81
	ScReg rNR23, low(F06)
	ScReg rNR24, high(F06) | $C0
	ScEnd

snd_ui_nav_enter::
	ScPart CH2, 2, :+
	ScReg rNR21, $80 | 16
	ScReg rNR22, $A1
	ScReg rNR23, low(Fs6)
	ScReg rNR24, high(Fs6) | $C0
	ScEnd
:
	ScPart CH2, 6, :+
	ScReg rNR21, $80 | 46
	ScReg rNR22, $81
	ScReg rNR23, low(G06)
	ScReg rNR24, high(G06) | $C0
	ScEnd
:
	ScPart CH2, 2, :+
	ScReg rNR21, $80 | 16
	ScReg rNR22, $A1
	ScReg rNR23, low(Gs6)
	ScReg rNR24, high(Gs6) | $C0
	ScEnd
:
	ScPart CH2, 9
	ScReg rNR21, $80 | 46
	ScReg rNR22, $81
	ScReg rNR23, low(A06)
	ScReg rNR24, high(A06) | $C0
	ScEnd

snd_ui_nav_exit::
	ScPart CH2, 2, :+
	ScReg rNR21, $80 | 16
	ScReg rNR22, $A1
	ScReg rNR23, low(Fs6)
	ScReg rNR24, high(Fs6) | $C0
	ScEnd
:
	ScPart CH2, 6, :+
	ScReg rNR21, $80 | 46
	ScReg rNR22, $81
	ScReg rNR23, low(G06)
	ScReg rNR24, high(G06) | $C0
	ScEnd
:
	ScPart CH2, 2, :+
	ScReg rNR21, $80 | 16
	ScReg rNR22, $A1
	ScReg rNR23, low(E06)
	ScReg rNR24, high(E06) | $C0
	ScEnd
:
	ScPart CH2, 9
	ScReg rNR21, $80 | 46
	ScReg rNR22, $81
	ScReg rNR23, low(F06)
	ScReg rNR24, high(F06) | $C0
	ScEnd


/***********************************************************
*                                           Ballder Sounds *
***********************************************************/
snd_ball_tick::
	ScPart CH2, 19
	ScReg rNR21, 52
	ScReg rNR22, $F0
	ScReg rNR23, low(C03)
	ScReg rNR24, high(C03) | $C0
	ScEnd


snd_ball_hit::
	ScPart CH4, 60
	ScReg rNR41, 35
	ScReg rNR42, $F2
	ScReg rNR43, $80
	ScReg rNR44, $80
	ScEnd


/***********************************************************
*                                              Sound Table *
***********************************************************/
	SoundTableEnd sound_table_size::, sound_table::
