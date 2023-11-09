if !def(CORE_COLLIDE_INC)
def CORE_COLLIDE_INC equ 1

include "common.inc"

	stdecl ColliderBox
		stfield left
		stfield right
		stfield top
		stfield bottom
	stclose

def COLLIDER_BOX_CAPACITY equ 32
def COLLIDERS_POOL_SIZE equ COLLIDER_BOX_CAPACITY * ColliderBox_sz
def COLLIDE_RESULTS_SIZE equ COLLIDER_BOX_CAPACITY

endc ; CORE_COLLIDE_INC
