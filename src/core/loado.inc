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


************************************************************
*                                                LOADOCODE *
************************************************************
STOP
	Ends the program. A valid program must include this.

SRC n:word
	Set data source address to `n`.

DEST n:word
	Set data destination address to `n`.

MEMCOPY n:word
	Copy `n` bytes to destination. Src persists.

VMEMCOPY n:word
	Copy `n` bytes to destination in VRAM. Src persists.

ROMB0 i:byte
	Set ROMB0 to `i`

SRC_CHR i:byte
	Set data source address `i` tiles 

DEST_CHR i:byte
	Set data destination to tile index `i` in active block.

SRC_CHROFF x:byte
	offset source pointer by `x` tiles

DEST_CHROFF x:byte
	offset dest pointer by `x` tiles

CHRCOPY n:byte
	Copy `n` tiles to CHR block, updates the block pointer.

CHRB_{0,1,2}
	Set the active CHR block to `{0,1,2}` and
	sets the destination to the block pointer.

CHRPICK i:byte
	Copy a single tile to CHR block
***********************************************************/

if !def(LOADO_INC)
def LOADO_INC equ 1

include "defines.asm"

	stdecl Loado
		stfield prg, w
		stfield stat

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


endc ; LOADO_INC