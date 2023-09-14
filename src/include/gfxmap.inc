if !def(GFXMAP_INC)
def GFXMAP_INC equ 1

rsreset

;; tShapes
;; input file: shapes.png
def tShapes equ _RS

def tShapes_Dir8 equ _RS
def tShapes_EE rb
def tShapes_SE rb
def tShapes_SS rb
def tShapes_SW rb
def tShapes_WW rb
def tShapes_NW rb
def tShapes_NN rb
def tShapes_NE rb
def tShapes_Dir8_end equ _RS

def tShapes_Square3 rb
def tShapes_Square2 rb
def tShapes_Square1 rb
def tShapes_Square0 rb
def tShapes_Circle3 rb
def tShapes_Circle2 rb
def tShapes_Circle1 rb
def tShapes_Circle0 rb

def tShapes_Ring0 rb
def tShapes_Ring1 rb
def tShapes_Ring2 rb
def tShapes_Ring3 rb
def tShapes_Ring4 rb
def tShapes_Ring5 rb
def tShapes_Ring6 rb
def tShapes_Ring7 rb

def tShapes_count equ _RS - tShapes
def tShapes_end equ _RS
; /tShapes


;; tBall
;; input file: ball.png
def tBall equ _RS
def tBall_A rb
def tBall_B rb
def tBall_C0 rb
def tBall_C1 rb
def tBall_C2 rb
def tBall_C3 rb

def tBall_count equ _RS - tBall
def tBall_end equ _RS

def tBall_A_cx equ 4
def tBall_A_cy equ 4

def tBall_B_cx equ 4
def tBall_B_cy equ 4

def tBall_C0_cx equ 8
def tBall_C0_cy equ 8
def tBall_C1_cx equ 0
def tBall_C1_cy equ 8
def tBall_C2_cx equ 8
def tBall_C2_cy equ 0
def tBall_C3_cx equ 0
def tBall_C3_cy equ 0

; /tBall

; tThings
; input file: buildings.png

def tThings equ _RS ; Start of the Things OBJ tile block.


endc
