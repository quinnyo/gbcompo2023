if !def(GFXMAP_INC)
def GFXMAP_INC equ 1

rsreset

;; tShapes
;; input file: shapes.png
def tShapes            equ _RS

def tShapes_Dir8       equ _RS
def tShapes_EE          rb 1
def tShapes_SE          rb 1
def tShapes_SS          rb 1
def tShapes_SW          rb 1
def tShapes_WW          rb 1
def tShapes_NW          rb 1
def tShapes_NN          rb 1
def tShapes_NE          rb 1
def tShapes_Dir8_end   equ _RS

def tShapes_Square3     rb 1
def tShapes_Square2     rb 1
def tShapes_Square1     rb 1
def tShapes_Square0     rb 1
def tShapes_Circle3     rb 1
def tShapes_Circle2     rb 1
def tShapes_Circle1     rb 1
def tShapes_Circle0     rb 1

def tShapes_Ring0       rb 1
def tShapes_Ring1       rb 1
def tShapes_Ring2       rb 1
def tShapes_Ring3       rb 1
def tShapes_Ring4       rb 1
def tShapes_Ring5       rb 1
def tShapes_Ring6       rb 1
def tShapes_Ring7       rb 1

def tShapes_count      equ _RS - tShapes
def tShapes_end        equ _RS
; /tShapes


;; tBall
;; input file: ball.png
def tBall         equ _RS
def tBall_A        rb 1 ; Tiny ballder on the tee
def tBall_B        rb 1 ; Small ballder travelling upwards
def tBall_C0       rb 1 ; Big ballder (FG) quartet part 0
def tBall_C1       rb 1 ; Big ballder (FG) quartet part 1
def tBall_C2       rb 1 ; Big ballder (FG) quartet part 2
def tBall_C3       rb 1 ; Big ballder (FG) quartet part 3

def tBall_count   equ _RS - tBall
def tBall_end     equ _RS

def tBall_A_cx    equ 4
def tBall_A_cy    equ 4
def tBall_B_cx    equ 4
def tBall_B_cy    equ 4

def tBall_C0_cx   equ 8
def tBall_C0_cy   equ 8
def tBall_C1_cx   equ 0
def tBall_C1_cy   equ 8
def tBall_C2_cx   equ 8
def tBall_C2_cy   equ 0
def tBall_C3_cx   equ 0
def tBall_C3_cy   equ 0


def tBallder_rolling_columns      equ $08
def tBallder_rolling_rows         equ $04
def tBallder_rolling_framecount   equ $08
def tBallder_rolling_count        equ tBallder_rolling_columns * tBallder_rolling_rows

def tBallder_rolling              equ _RS

def tBallder_rolling_q0t0 rb 2
def tBallder_rolling_q0t1 rb 2
def tBallder_rolling_q0t2 rb 2
def tBallder_rolling_q0t3 rb 2
def tBallder_rolling_q2t0 rb 2
def tBallder_rolling_q2t1 rb 2
def tBallder_rolling_q2t2 rb 2
def tBallder_rolling_q2t3 rb 2
def tBallder_rolling_q0t4 rb 2
def tBallder_rolling_q0t5 rb 2
def tBallder_rolling_q0t6 rb 2
def tBallder_rolling_q0t7 rb 2
def tBallder_rolling_q2t4 rb 2
def tBallder_rolling_q2t5 rb 2
def tBallder_rolling_q2t6 rb 2
def tBallder_rolling_q2t7 rb 2

; /tBall

; tThings
; input file: buildings.png

def tThings equ _RS ; Start of the Things OBJ tile block.


endc ; GFXMAP_INC
