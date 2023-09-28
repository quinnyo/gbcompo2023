include "hUGE.inc"

SECTION "mus99 Song Data", ROMX

mus99::
db 8
dw order_cnt
dw order1, order2, order3, order4
dw duty_instruments, wave_instruments, noise_instruments
dw routines
dw waves

order_cnt: db 2
order1: dw P0
order2: dw P1
order3: dw P2
order4: dw P3

P0:
 dn A_3,7,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn E_4,7,$000
 dn ___,0,$000
 dn C#4,7,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G#4,7,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn A_3,7,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn E_4,7,$000
 dn ___,0,$000
 dn C#4,7,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G#4,7,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn B_3,7,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn F#4,7,$000
 dn ___,0,$000
 dn D#4,7,$000
 dn ___,0,$000
 dn A#4,7,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn B_3,7,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn F#4,7,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D#4,7,$000
 dn ___,0,$000
 dn A#4,7,$000
 dn ___,0,$000
 dn B_4,7,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

P1:
 dn C#6,9,$000
 dn ___,0,$000
 dn E_6,9,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn C#6,9,$000
 dn ___,0,$000
 dn E_6,9,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn F#6,9,$000
 dn ___,0,$000
 dn G#6,9,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D#6,9,$000
 dn ___,0,$000
 dn F#6,9,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D#6,9,$000
 dn ___,0,$000
 dn F#6,9,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G#6,9,$000
 dn ___,0,$000
 dn A#6,9,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

P2:
 dn C#4,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn E_4,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn C#4,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$105
 dn F#4,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn F#4,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn B_4,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

P3:
 dn F#6,1,$000
 dn ___,0,$000
 dn C#6,1,$000
 dn ___,0,$000
 dn C_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn F#6,1,$000
 dn ___,0,$000
 dn C#6,1,$000
 dn ___,0,$000
 dn C_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn F#6,1,$000
 dn ___,0,$000
 dn C#6,1,$000
 dn ___,0,$000
 dn C_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn F#6,1,$000
 dn ___,0,$000
 dn C#6,1,$000
 dn ___,0,$000
 dn C_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn C#6,1,$000
 dn ___,0,$000
 dn C_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn F#6,1,$000
 dn ___,0,$000
 dn C#6,1,$000
 dn ___,0,$000
 dn C_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn C#6,1,$000
 dn ___,0,$000
 dn C#6,1,$000
 dn ___,0,$000
 dn C_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn F#6,1,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn F#6,1,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn ___,0,$000

itSquareSP9:
 dn 41,0,$000
 dn ___,0,$000
 dn 36,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,1,$000

itWaveSP1:
 dn 24,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn 36,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn 24,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn 36,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,1,$000

itWaveSP2:
 dn 36,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn 24,0,$000
 dn ___,0,$000
 dn 36,0,$000
 dn ___,0,$000
 dn 36,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,1,$000

itNoiseSP1:
 dn 67,0,$000
 dn 55,0,$000
 dn 60,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,1,$000

duty_instruments:
itSquareinst1:
db 8
db 0
db 240
dw 0
db 128

itSquareinst2:
db 8
db 64
db 240
dw 0
db 128

itSquareinst3:
db 8
db 128
db 240
dw 0
db 128

itSquareinst4:
db 8
db 192
db 240
dw 0
db 128

itSquareinst5:
db 8
db 0
db 241
dw 0
db 128

itSquareinst6:
db 8
db 64
db 241
dw 0
db 128

itSquareinst7:
db 8
db 128
db 241
dw 0
db 128

itSquareinst8:
db 8
db 192
db 241
dw 0
db 128

itSquareinst9:
db 8
db 152
db 242
dw itSquareSP9
db 192

itSquareinst10:
db 8
db 128
db 240
dw 0
db 128

itSquareinst11:
db 8
db 128
db 240
dw 0
db 128

itSquareinst12:
db 8
db 128
db 240
dw 0
db 128

itSquareinst13:
db 8
db 128
db 240
dw 0
db 128

itSquareinst14:
db 8
db 128
db 240
dw 0
db 128

itSquareinst15:
db 8
db 128
db 240
dw 0
db 128



wave_instruments:
itWaveinst1:
db 0
db 32
db 11
dw itWaveSP1
db 128

itWaveinst2:
db 114
db 32
db 11
dw itWaveSP2
db 192

itWaveinst3:
db 0
db 32
db 2
dw 0
db 128

itWaveinst4:
db 0
db 32
db 3
dw 0
db 128

itWaveinst5:
db 0
db 32
db 4
dw 0
db 128

itWaveinst6:
db 0
db 32
db 5
dw 0
db 128

itWaveinst7:
db 0
db 32
db 6
dw 0
db 128

itWaveinst8:
db 0
db 32
db 7
dw 0
db 128

itWaveinst9:
db 0
db 32
db 8
dw 0
db 128

itWaveinst10:
db 0
db 32
db 9
dw 0
db 128

itWaveinst11:
db 0
db 32
db 10
dw 0
db 128

itWaveinst12:
db 0
db 32
db 11
dw 0
db 128

itWaveinst13:
db 0
db 32
db 12
dw 0
db 128

itWaveinst14:
db 0
db 32
db 13
dw 0
db 128

itWaveinst15:
db 0
db 32
db 14
dw 0
db 128



noise_instruments:
itNoiseinst1:
db 241
dw itNoiseSP1
db 43
ds 2

itNoiseinst2:
db 240
dw 0
db 0
ds 2

itNoiseinst3:
db 240
dw 0
db 0
ds 2

itNoiseinst4:
db 240
dw 0
db 0
ds 2

itNoiseinst5:
db 240
dw 0
db 0
ds 2

itNoiseinst6:
db 240
dw 0
db 0
ds 2

itNoiseinst7:
db 240
dw 0
db 0
ds 2

itNoiseinst8:
db 240
dw 0
db 0
ds 2

itNoiseinst9:
db 240
dw 0
db 0
ds 2

itNoiseinst10:
db 240
dw 0
db 0
ds 2

itNoiseinst11:
db 240
dw 0
db 0
ds 2

itNoiseinst12:
db 240
dw 0
db 0
ds 2

itNoiseinst13:
db 240
dw 0
db 0
ds 2

itNoiseinst14:
db 240
dw 0
db 0
ds 2

itNoiseinst15:
db 240
dw 0
db 0
ds 2



routines:
__hUGE_Routine_0:

__end_hUGE_Routine_0:
ret

__hUGE_Routine_1:

__end_hUGE_Routine_1:
ret

__hUGE_Routine_2:

__end_hUGE_Routine_2:
ret

__hUGE_Routine_3:

__end_hUGE_Routine_3:
ret

__hUGE_Routine_4:

__end_hUGE_Routine_4:
ret

__hUGE_Routine_5:

__end_hUGE_Routine_5:
ret

__hUGE_Routine_6:

__end_hUGE_Routine_6:
ret

__hUGE_Routine_7:

__end_hUGE_Routine_7:
ret

__hUGE_Routine_8:

__end_hUGE_Routine_8:
ret

__hUGE_Routine_9:

__end_hUGE_Routine_9:
ret

__hUGE_Routine_10:

__end_hUGE_Routine_10:
ret

__hUGE_Routine_11:

__end_hUGE_Routine_11:
ret

__hUGE_Routine_12:

__end_hUGE_Routine_12:
ret

__hUGE_Routine_13:

__end_hUGE_Routine_13:
ret

__hUGE_Routine_14:

__end_hUGE_Routine_14:
ret

__hUGE_Routine_15:

__end_hUGE_Routine_15:
ret

waves:
wave0: db 0,0,255,255,255,255,255,255,255,255,255,255,255,255,255,255
wave1: db 0,0,0,0,255,255,255,255,255,255,255,255,255,255,255,255
wave2: db 0,0,0,0,0,0,0,0,255,255,255,255,255,255,255,255
wave3: db 0,0,0,0,0,0,0,0,0,0,0,0,255,255,255,255
wave4: db 0,1,18,35,52,69,86,103,120,137,154,171,188,205,222,239
wave5: db 254,220,186,152,118,84,50,16,18,52,86,120,154,188,222,255
wave6: db 122,205,219,117,33,19,104,189,220,151,65,1,71,156,221,184
wave7: db 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
wave8: db 254,252,250,248,246,244,242,240,242,244,246,248,250,252,254,255
wave9: db 254,221,204,187,170,153,136,119,138,189,241,36,87,138,189,238
wave10: db 132,17,97,237,87,71,90,173,206,163,23,121,221,32,3,71
wave11: db 0,25,153,153,145,0,25,153,153,16,1,93,245,16,1,84
wave12: db 91,41,42,58,68,98,75,67,35,50,227,168,163,145,171,169
wave13: db 58,30,122,137,202,91,86,74,188,101,198,26,9,192,121,26
wave14: db 23,146,214,170,72,68,49,238,220,66,209,64,25,198,134,150
wave15: db 54,3,81,193,216,98,66,105,85,85,183,197,128,38,216,198

