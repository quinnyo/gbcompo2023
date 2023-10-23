if !def(APP_SHOTCTL_INC)
def APP_SHOTCTL_INC equ 1

include "common.inc"

macro ShotPhaseEnumDef
	def ShotPhase__ALL equs "\#"
	def ShotPhase__COUNT = 0
	rept _NARG
		redef _KEY equs strupr("\1")
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
	if _NARG == 2
		def _FUNC equs "\2"
	else
		def _FUNC equs "update"
	endc
	shot_phase_{_KEY}_{_FUNC}::
	purge _KEY, _FUNC
endm

	ShotPhaseEnumDef new, aimxy, swing, ball, done


/*
ShotPhaseStatus `wShot_phase_status`
Simple communication between phases and shotctl.
*/
rsreset
def ShotPhaseStatus_INIT     rb 1 ; (CTL ==> PHASE) Phase update is called once with status INIT during program startup.
def ShotPhaseStatus_ENTER    rb 1 ; (CTL ==> PHASE) Set when changing to phase.
def ShotPhaseStatus_OK       rb 1 ; (PHASE ==> CTL)
def ShotPhaseStatus_NEXT     rb 1 ; (PHASE ==> CTL) Phase completed successfully -- move to next phase.
def ShotPhaseStatus_BACK     rb 1 ; (PHASE ==> CTL) Phase ended unsuccessfully -- move to previous phase.


endc ; APP_SHOTCTL_INC
