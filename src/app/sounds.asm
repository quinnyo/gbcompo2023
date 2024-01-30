include "core/soundcode.inc"
include "note_table.inc"

section "Sounds", romx

/***********************************************************
*                                                UI Sounds *
***********************************************************/

snd_ui_move::
	ScPart CH2, 1
	ScReg rNR21, $80 | 16
	ScReg rNR22, $81
	ScReg rNR23, low(Fs7)
	ScReg rNR24, high(Fs7) | $C0
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
	ScReg rNR22, $80
	ScReg rNR23, low(C03)
	ScReg rNR24, high(C03) | $C0
	ScEnd


snd_ball_hit::
	ScPart CH4, 60
	ScReg rNR41, 0
	ScReg rNR42, $F2
	ScReg rNR43, $80
	ScReg rNR44, $80
	ScEnd


snd_ball_oob::
	ScPart CH1, 7, :+
	ScReg rNR10, $4B
	ScReg rNR11, 32
	ScReg rNR12, $F1
	ScReg rNR13, low(F05)
	ScReg rNR14, high(F05) | $C0
	ScEnd
:
	ScPart CH1, 14
	ScReg rNR10, $4B
	ScReg rNR11, 32
	ScReg rNR12, $F1
	ScReg rNR13, low(C04)
	ScReg rNR14, high(C04) | $C0
	ScEnd


snd_ball_thump::
	ScPart CH2, 5, :+
	ScReg rNR21, 0
	ScReg rNR22, $A2
	ScReg rNR23, low(C03)
	ScReg rNR24, high(C03) | $F0
	ScEnd
:
	ScPart CH1, 6, :+
	ScReg rNR10, $4B
	ScReg rNR11, $40
	ScReg rNR12, $C2
	ScReg rNR13, low(F03)
	ScReg rNR14, high(F03) | $C0
	ScEnd
:
	ScPart CH2 | CH4, 60
	ScReg rNR21, 0
	ScReg rNR22, $A3
	ScReg rNR23, low(Ds3)
	ScReg rNR24, high(Ds3) | $F0
	ScReg rNR41, 0
	ScReg rNR42, $92
	ScReg rNR43, $80
	ScReg rNR44, $80
	ScEnd


snd_smash_01::
	ScPart CH4, 60
	ScReg rNR41, 0
	ScReg rNR42, $E3
	ScReg rNR43, $88 | 1
	ScReg rNR44, $80
	ScEnd


snd_smash_02::
	ScPart CH4, 60
	ScReg rNR41, 0
	ScReg rNR42, $E4
	ScReg rNR43, $80 | 1
	ScReg rNR44, $80
	ScEnd


snd_smash_03::
	ScPart CH4, 60
	ScReg rNR41, 0
	ScReg rNR42, $D2
	ScReg rNR43, $88 | 2
	ScReg rNR44, $80
	ScEnd


snd_smash_04::
	ScPart CH4, 60
	ScReg rNR41, 0
	ScReg rNR42, $F4
	ScReg rNR43, $80 | 0
	ScReg rNR44, $80
	ScEnd


/***********************************************************
*                                              Sound Table *
***********************************************************/

section "SoundTable", rom0
	SoundTableEnd sound_table_size::, sound_table::
