IF !DEF(ONEBIT_MONO_INC)
DEF ONEBIT_MONO_INC EQU 1

DEF ONEBIT_MONO_GLYPH_COUNT EQU 128
DEF ONEBIT_MONO_RES_BPP EQU 1
DEF ONEBIT_MONO_RES_GLYPH_SIZE EQU 8
DEF ONEBIT_MONO_RES_SIZE EQU ONEBIT_MONO_GLYPH_COUNT * ONEBIT_MONO_RES_GLYPH_SIZE

NEWCHARMAP onebit

CHARMAP "!", 1
CHARMAP "\"", 2
CHARMAP "#", 3
CHARMAP "$", 4
CHARMAP "%", 5
CHARMAP "&", 6
CHARMAP "'", 7
CHARMAP "(", 8
CHARMAP ")", 9
CHARMAP "*", 10
CHARMAP "+", 11
CHARMAP ",", 12
CHARMAP "-", 13
CHARMAP ".", 14
CHARMAP "/", 15
CHARMAP "0", 16
CHARMAP "1", 17
CHARMAP "2", 18
CHARMAP "3", 19
CHARMAP "4", 20
CHARMAP "5", 21
CHARMAP "6", 22
CHARMAP "7", 23
CHARMAP "8", 24
CHARMAP "9", 25
CHARMAP ":", 26
CHARMAP ";", 27
CHARMAP "<", 28
CHARMAP "=", 29
CHARMAP ">", 30
CHARMAP "?", 31
CHARMAP "@", 32
CHARMAP "A", 33
CHARMAP "B", 34
CHARMAP "C", 35
CHARMAP "D", 36
CHARMAP "E", 37
CHARMAP "F", 38
CHARMAP "G", 39
CHARMAP "H", 40
CHARMAP "I", 41
CHARMAP "J", 42
CHARMAP "K", 43
CHARMAP "L", 44
CHARMAP "M", 45
CHARMAP "N", 46
CHARMAP "O", 47
CHARMAP "P", 48
CHARMAP "Q", 49
CHARMAP "R", 50
CHARMAP "S", 51
CHARMAP "T", 52
CHARMAP "U", 53
CHARMAP "V", 54
CHARMAP "W", 55
CHARMAP "X", 56
CHARMAP "Y", 57
CHARMAP "Z", 58
CHARMAP "[", 59
CHARMAP "\\", 60
CHARMAP "]", 61
CHARMAP "^", 62
CHARMAP "_", 63
CHARMAP "`", 64
CHARMAP "a", 65
CHARMAP "b", 66
CHARMAP "c", 67
CHARMAP "d", 68
CHARMAP "e", 69
CHARMAP "f", 70
CHARMAP "g", 71
CHARMAP "h", 72
CHARMAP "i", 73
CHARMAP "j", 74
CHARMAP "k", 75
CHARMAP "l", 76
CHARMAP "m", 77
CHARMAP "n", 78
CHARMAP "o", 79
CHARMAP "p", 80
CHARMAP "q", 81
CHARMAP "r", 82
CHARMAP "s", 83
CHARMAP "t", 84
CHARMAP "u", 85
CHARMAP "v", 86
CHARMAP "w", 87
CHARMAP "x", 88
CHARMAP "y", 89
CHARMAP "z", 90
CHARMAP "\{", 91
CHARMAP "|", 92
CHARMAP "\}", 93
CHARMAP "~", 94
CHARMAP " ", 95

; GB BUTTONS

CHARMAP "<^A>", 96
CHARMAP "<^B>", 97
CHARMAP "<^Sel>", 98
CHARMAP "<^Sta>", 99
CHARMAP "<^R>", 100
CHARMAP "<^L>", 101
CHARMAP "<^U>", 102
CHARMAP "<^D>", 103

; BOX

CHARMAP "<TL>", 104
CHARMAP "<H>", 105
CHARMAP "<TR>", 106
CHARMAP "<BL>", 107
CHARMAP "<V>", 108
CHARMAP "<BR>", 109


; APPLICATION

CHARMAP "<Sh>", 112
CHARMAP "<ot:>", 113
CHARMAP "<Hut>", 114

ENDC
