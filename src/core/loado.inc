/***********************************************************
*                                                    LOADO *
*                        Loado has state. Loado remembers. *
************************************************************
Loado is a bytecode thing for loading required resources in
a somewhat data-driven way.
The primary use case is to allow Maps to select which tiles
to load (to VRAM) -- to *only* load tiles that are required
at any time.

CHR Blocks: a simplified way to address VRAM CHR data
- There are three 2048 byte (128 tile) CHR blocks
- see: https://gbdev.io/pandocs/Tile_Data.html

Blocks can be indexed by tiles (0..127), which fits in one
byte instead of the two required for a complete address.
Setting the 'Active CHR Block' effectively sets a "base
address" which is used to calculate actual addresses from
tile index numbers.

OPCODES are grouped based on the number of parameters they
expect. The value is the number of bytes required by the
opcode -- and tells the loadomachine how many bytes to read.

************************************************************
*                                                LOADOCODE *
************************************************************
/OPCODE        /PARAMS    /SIZE
	/DESCRIPTION

STOP                     (1)
	Ends the program. A valid program must include this.

CHRB_{0,1,2}             (1)
	Set the active CHR block to `{0,1,2}` and
	sets the destination to the block pointer.

ROMB0          i:byte    (2)
	Set ROMB0 to `i`

SRC_CHR        i:byte    (2)
	Set data source address `i` tiles 

DEST_CHR       i:byte    (2)
	Set data destination to tile index `i` in active block.

SRC_CHROFF     x:byte    (2)
	offset source pointer by `x` tiles

DEST_CHROFF    x:byte    (2)
	offset dest pointer by `x` tiles

CHRCOPY        n:byte    (2)
	Copy `n` tiles to CHR block, updates the block pointer.

CHRPICK        i:byte    (2)
	Copy a single tile to CHR block

SRC            n:word    (3)
	Set data source address to `n`.

DEST           n:word    (3)
	Set data destination address to `n`.

MEMCOPY        n:word    (3)
	Copy `n` bytes to destination. Src persists.

VMEMCOPY       n:word    (3)
	Copy `n` bytes to destination in VRAM. Src persists.
***********************************************************/

if !def(CORE_LOADO_INC)
def CORE_LOADO_INC equ 1

include "common.inc"

	; Loadocode machine state
	stdecl Loadomachine
		stfield prg, w
		stfield stat

		stfield msrc_romb0
		stfield msrc, w ; source address
		stfield mdest, w ; destination address
		stfield chrsrc, w ; CHR source address offset
		stfield chrdest, w ; CHR destination address offset
	stclose


def LOADO_CHRBLOCK0_MIN equ $8000
def LOADO_CHRBLOCK1_MIN equ $8800
def LOADO_CHRBLOCK2_MIN equ $9000

/***********************************************************
*                                          Loado "opcodes" *
***********************************************************/

rsreset
def LOADOCODE1                         rb 0
def LOADOCODE_ROMB0                    rb 1
def LOADOCODE_SRC_CHR                  rb 1
def LOADOCODE_DEST_CHR                 rb 1
def LOADOCODE_SRC_CHROFF               rb 1
def LOADOCODE_DEST_CHROFF              rb 1
def LOADOCODE_CHRCOPY                  rb 1
def LOADOCODE_CHRPICK                  rb 1
def LOADOCODE1__MAX                    rb 0
def LOADOCODE2                         rb 0
def LOADOCODE_SRC                      rb 1
def LOADOCODE_DEST                     rb 1
def LOADOCODE_MEMCOPY                  rb 1
def LOADOCODE_VMEMCOPY                 rb 1
def LOADOCODE2__MAX                    rb 0
def LOADOCODE0                         rb 0
def LOADOCODE_STOP                     rb 1
def LOADOCODE_CHRB_0                   rb 1
def LOADOCODE_CHRB_1                   rb 1
def LOADOCODE_CHRB_2                   rb 1
def LOADOCODE0__MAX                    rb 0

/* NOTE: the ordering of the groups (LOADOCODE1, *2, *0) is
important. The machine implementation makes the assumption:
`LOADOCODE1 < LOADOCODE2 < LOADOCODE0`. */
assert LOADOCODE1 < LOADOCODE2 && LOADOCODE2 < LOADOCODE0


/***********************************************************
*                                 Loado.stat bitmask/flags *
***********************************************************/

def LOADO_STATB_STOP equ 0

def LOADO_STATF_READY equ 0



; LoadocodeROMB 
macro LoadocodeROMB
	if def(MBC)
		assert bank(\1) < 256
		db LOADOCODE_ROMB0, bank(\1)
	endc
endm


endc ; CORE_LOADO_INC