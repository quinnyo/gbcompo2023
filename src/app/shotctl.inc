if !def(APP_SHOTCTL_INC)
def APP_SHOTCTL_INC equ 1

include "common.inc"

macro ShotPhaseEnumDef
	def ShotPhase__ALL equs "\#"
	def ShotPhase__COUNT = 0
	rept _NARG
		redef _KEY equs strupr("\1")
		assert fatal, strcmp("{_KEY}", "_ALL") != 0, "ShotPhase__ALL is a reserved keyword."
		assert fatal, strcmp("{_KEY}", "_COUNT") != 0, "ShotPhase__COUNT is a reserved keyword."
		assert fatal, strin("{_KEY}", "_KEY") != 1, "ShotPhase__KEY is a reserved keyword."
		def ShotPhase_{_KEY} equ ShotPhase__COUNT
		if strin("\1", "_") != 1 ; start with underscore => tag, not actual state
			def ShotPhase__KEY{u:ShotPhase__COUNT} equs "{_KEY}"
			def ShotPhase__COUNT += 1
		endc
		shift
	endr
	purge _KEY
endm

macro ShotPhaseFuncDef
	def _KEY equs strupr("\1")
	assert def(ShotPhase_{_KEY})
	if _NARG == 2
		def _FUNC equs "\2"
	else
		def _FUNC equs "update"
	endc
	shot_phase_{_KEY}_{_FUNC}::
	purge _KEY, _FUNC
endm

	ShotPhaseEnumDef _start, new, _setup, aimxy, _action, ball, _end, done


/*
ShotPhaseStatus `wShot_phase_status`
Simple communication between phases and shotctl.
*/
rsreset
def ShotPhaseStatus_ENTER    rb 1 ; (CTL ==> PHASE) Set when changing to phase.
def ShotPhaseStatus_OK       rb 1 ; (PHASE ==> CTL)
def ShotPhaseStatus_NEXT     rb 1 ; (PHASE ==> CTL) Phase completed successfully -- move to next phase.
def ShotPhaseStatus_BACK     rb 1 ; (PHASE ==> CTL) Phase ended unsuccessfully -- move to previous phase.


rsreset
; Changing shot phase. Emitted after setting phase, before calling phase ENTER.
def ShotEvent_PHASE_CHANGE  rb 1
; Emitted when starting next shot. Will trigger after PHASE_CHANGE event.
def ShotEvent_START_SHOT    rb 1
; Emitted when starting next shot failed due to reaching shot limit.
def ShotEvent_SHOT_LIMIT    rb 1


endc ; APP_SHOTCTL_INC
