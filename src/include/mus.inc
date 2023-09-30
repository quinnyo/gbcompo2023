if !def(MUS_INC)
def MUS_INC EQU 1

def _MUSIC_TRACK_COUNT = 0

; MusicReg LABEL0, [LABEL1, [...]]
macro MusicReg
	rept _NARG
		def _TRK_ID equs strupr("\1")
		def MUSIC_TRACK_{_TRK_ID}_INDEX equ _MUSIC_TRACK_COUNT
		def MUSIC_TRACK_{u:_MUSIC_TRACK_COUNT} equs "\1"
		def _MUSIC_TRACK_COUNT += 1
		purge _TRK_ID
		shift
	endr
endm


macro MusicTableBuild
	for IDX, _MUSIC_TRACK_COUNT
		db bank(MUSIC_TRACK_{u:IDX})
		dw MUSIC_TRACK_{u:IDX}
	endr
	.size:: db _MUSIC_TRACK_COUNT
endm


def MUSIC_TABLE_STRIDE equ 3


	MusicReg mus01, mus99


endc ; MUS_INC