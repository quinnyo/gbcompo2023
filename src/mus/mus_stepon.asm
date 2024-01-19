include "hUGE.inc"

SECTION "mus_stepon Song Data", ROMX

mus_stepon::
db 5
dw order_cnt
dw order1, order2, order3, order4
dw duty_instruments, wave_instruments, noise_instruments
dw routines
dw waves

order_cnt: db 28
order1: dw P0,P11,P11,P12,P15,P16,P11,P11,P12,P17,P17,P17,P0,P0
order2: dw P14,P13,P13,P13,P13,P13,P13,P13,P13,P13,P13,P21,P0,P0
order3: dw P0,P0,P0,P0,P0,P0,P0,P0,P0,P0,P0,P0,P0,P0
order4: dw P0,P3,P3,P2,P2,P4,P2,P4,P4,P4,P4,P20,P0,P0

P0:
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
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

P2:
 dn F_4,1,$C05
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G#4,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn F_4,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G#4,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn F_4,1,$C05
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G#4,2,$C1F
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn F_4,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G#4,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn F_4,1,$C05
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G#4,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn F_4,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn F_4,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn F_4,1,$000
 dn ___,0,$000
 dn F_4,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G#4,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

P3:
 dn ___,0,$000
 dn ___,0,$000
 dn E_4,1,$000
 dn ___,0,$000
 dn C_5,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn C_5,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn E_4,1,$000
 dn ___,0,$000
 dn C_5,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn C_5,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn E_4,1,$000
 dn ___,0,$000
 dn C_5,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn C_5,1,$000
 dn ___,0,$000
 dn C_5,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn C_5,1,$000
 dn ___,0,$000
 dn E_4,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn E_4,1,$000
 dn ___,0,$000
 dn C_5,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

P4:
 dn F_4,1,$C05
 dn ___,0,$000
 dn F_4,1,$E02
 dn ___,0,$000
 dn G#4,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn F_4,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G#4,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn F_4,1,$C05
 dn ___,0,$000
 dn F_4,1,$E02
 dn ___,0,$000
 dn G#4,2,$C1F
 dn ___,0,$000
 dn F_4,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G#4,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn F_4,1,$C05
 dn ___,0,$000
 dn F_4,1,$E02
 dn ___,0,$000
 dn G#4,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn F_4,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G#4,2,$E03
 dn ___,0,$000
 dn F_4,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G#4,2,$C18
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn F_4,1,$000
 dn ___,0,$000
 dn F_4,1,$000
 dn ___,0,$000
 dn G#4,2,$C1F
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

P11:
 dn A_6,1,$8BA
 dn ___,0,$000
 dn A_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn B_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn A_6,1,$000
 dn ___,0,$000
 dn A_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn C_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn A_6,1,$000
 dn ___,0,$000
 dn A_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn A_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn A_6,1,$000
 dn ___,0,$000
 dn A_6,1,$000
 dn ___,0,$000
 dn A_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn A_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

P12:
 dn A_6,1,$000
 dn ___,0,$000
 dn A_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn B_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn A_6,1,$000
 dn ___,0,$000
 dn A_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn C_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn A_6,1,$000
 dn ___,0,$000
 dn A_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn A_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn A_6,1,$000
 dn ___,0,$000
 dn A_6,1,$000
 dn ___,0,$000
 dn A_7,1,$000
 dn ___,0,$000
 dn G_7,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn E_7,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_7,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

P13:
 dn G_3,3,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_4,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_4,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_5,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_4,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_4,2,$000
 dn ___,0,$000
 dn E_3,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_3,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_3,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_4,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_4,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_3,3,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn E_4,2,$000
 dn ___,0,$000
 dn G_4,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_3,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

P14:
 dn G_3,3,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_4,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_4,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_5,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_4,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_4,2,$000
 dn ___,0,$000
 dn E_3,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_3,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_3,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_4,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_4,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_3,3,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn E_4,2,$000
 dn ___,0,$000
 dn G_4,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_3,2,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

P15:
 dn G_6,1,$8AB
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn E_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn E_7,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

P16:
 dn G_6,1,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn E_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn E_6,1,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn E_5,1,$000
 dn ___,0,$000
 dn D_6,1,$000
 dn ___,0,$000
 dn E_6,1,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000

P17:
 dn G_6,1,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_5,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn E_5,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_5,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn G_6,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_5,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

P20:
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn C_5,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn C_5,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn C_5,1,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn C_5,1,$000
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
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

P21:
 dn C_5,13,$000
 dn ___,0,$000
 dn C_5,13,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn C_5,13,$000
 dn ___,0,$000
 dn C_5,13,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn C_5,13,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn C_5,13,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn C_5,13,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn C_5,13,$000
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
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

itSquareSP2:
 dn 43,0,$000
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
 dn ___,0,$000
 dn ___,1,$000

itSquareSP3:
 dn ___,0,$107
 dn ___,0,$207
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
 dn ___,0,$000
 dn ___,1,$000

itSquareSP13:
 dn 30,0,$000
 dn 19,0,$000
 dn 17,0,$980
 dn 16,0,$000
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

itNoiseSP1:
 dn 52,0,$000
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
 dn ___,0,$000
 dn ___,0,$000
 dn ___,1,$000

itNoiseSP2:
 dn 57,0,$000
 dn 49,0,$000
 dn 61,0,$000
 dn 63,0,$000
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
db 128
db 177
dw 0
db 128

itSquareinst2:
db 8
db 20
db 197
dw itSquareSP2
db 192

itSquareinst3:
db 0
db 0
db 197
dw itSquareSP3
db 128

itSquareinst4:
db 8
db 128
db 240
dw 0
db 128

itSquareinst5:
db 8
db 128
db 240
dw 0
db 128

itSquareinst6:
db 8
db 128
db 240
dw 0
db 128

itSquareinst7:
db 8
db 128
db 240
dw 0
db 128

itSquareinst8:
db 8
db 128
db 240
dw 0
db 128

itSquareinst9:
db 8
db 128
db 240
dw 0
db 128

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
db 27
db 51
db 145
dw itSquareSP13
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
db 0
db 0
dw 0
db 128

itWaveinst2:
db 0
db 0
db 0
dw 0
db 128

itWaveinst3:
db 0
db 0
db 0
dw 0
db 128

itWaveinst4:
db 0
db 0
db 0
dw 0
db 128

itWaveinst5:
db 0
db 0
db 0
dw 0
db 128

itWaveinst6:
db 0
db 0
db 0
dw 0
db 128

itWaveinst7:
db 0
db 0
db 0
dw 0
db 128

itWaveinst8:
db 0
db 0
db 0
dw 0
db 128

itWaveinst9:
db 0
db 0
db 0
dw 0
db 128

itWaveinst10:
db 0
db 0
db 0
dw 0
db 128

itWaveinst11:
db 0
db 0
db 0
dw 0
db 128

itWaveinst12:
db 0
db 0
db 0
dw 0
db 128

itWaveinst13:
db 0
db 0
db 0
dw 0
db 128

itWaveinst14:
db 0
db 0
db 0
dw 0
db 128

itWaveinst15:
db 0
db 0
db 0
dw 0
db 128



noise_instruments:
itNoiseinst1:
db 177
dw itNoiseSP1
db 231
ds 2

itNoiseinst2:
db 177
dw itNoiseSP2
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
wave0: db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
wave1: db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
wave2: db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
wave3: db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
wave4: db 0,1,18,35,52,69,86,103,120,137,154,171,188,205,222,239
wave5: db 254,220,186,152,118,84,50,16,18,52,86,120,154,188,222,255
wave6: db 122,205,219,117,33,19,104,189,220,151,65,1,71,156,221,184
wave7: db 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
wave8: db 254,252,250,248,246,244,242,240,242,244,246,248,250,252,254,255
wave9: db 254,221,204,187,170,153,136,119,138,189,241,36,87,138,189,238
wave10: db 132,17,97,237,87,71,90,173,206,163,23,121,221,32,3,71
wave11: db 146,183,94,138,217,135,14,216,227,94,228,134,231,150,0,35
wave12: db 36,146,124,18,5,108,32,43,49,225,7,14,171,107,51,169
wave13: db 2,142,62,1,68,76,131,186,60,103,216,76,38,212,100,169
wave14: db 227,44,34,125,52,91,90,236,6,172,131,200,185,148,140,208
wave15: db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
