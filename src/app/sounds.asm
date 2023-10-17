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
	ScPart CH2, 2
	ScReg rNR21, 59 ; duty 12.5%, length 57
	ScReg rNR22, $F0
	ScReg rNR23, low(F03)
	ScReg rNR24, high(F03) | $C0
	ScEnd


/***********************************************************
*                                              Sound Table *
***********************************************************/
	SoundTableEnd sound_table_size::, sound_table::
