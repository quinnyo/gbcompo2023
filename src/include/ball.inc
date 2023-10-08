if !def(BALL_INC)
def BALL_INC equ 1

include "defines.asm"

	stdecl Ball
		stfield mode ; Overall state/mode (see bMode* constants)
		stfield status
		stfield collide
		stfield shot
		stfield stationary ; count consecutive frames with no motion
		stfield x, w ; X position
		stfield y, w ; Y position
		stfield vx, w ; X velocity
		stfield vy, w ; Y velocity
		stfield sprite, w ; active sprite address
	stclose

	stdecl Aim
		stfield x
		stfield y
	stclose


def BallAimStepsX equ 128
def BallAimStepsY equ 96
def BallAimDefaultX equ BallAimStepsX / 2
def BallAimDefaultY equ BallAimStepsY / 2
; def BallAimDisplayX equ 8
; def BallAimDisplayY equ -8

def BallMinLaunchVelX equ 128 ; Minimum power launch velocity, X axis
def BallMinLaunchVelY equ $FF00 ; Minimum power launch velocity, Y axis


def BallCollideThingRadius equ 6

/*
*	Ball Status Flags
*/

def bBallStatPeaked     equ 0 ; set if ball has had a positive (down) velocity.
def bBallStatFreeze     equ 1 ; if set, motion won't be simulated
def bBallStatStopped    equ 2 ; ball has come to a stop
def bBallStatOOB        equ 3 ; ball has gone out of bounds
def bBallStatOffScrTop  equ 5 ; set if ball is off screen (top)
def bBallStatHeadingX   equ 6 ; set if velocity X < 0
def bBallStatHeadingY   equ 7 ; set if velocity Y < 0

def fBallStatStopped    equ 1 << bBallStatStopped
def fBallStatOOB        equ 1 << bBallStatOOB
def fBallStatShotEnded  equ fBallStatStopped | fBallStatOOB
def fBallStatHeading    equ $C0 ; mask heading bits


/*
*	Ball Mode: primary behaviour states
*/

def bBallModeAiming    equ 0 ; 'Aiming' state
def bBallModeMotion    equ 1 ; 'Motion' state
def bBallModeTransOut  equ 6 ; mode ending/exiting
def bBallModeTransIn   equ 7 ; mode starting/entering

; Ball Mode Bitmask

def fBallModeAiming    equ 1 << bBallModeAiming
def fBallModeMotion    equ 1 << bBallModeMotion
def fBallModeTransOut  equ 1 << bBallModeTransOut
def fBallModeTransIn   equ 1 << bBallModeTransIn
def fBallModeDefault   equ fBallModeAiming | fBallModeTransIn

endc ; BALL_INC
