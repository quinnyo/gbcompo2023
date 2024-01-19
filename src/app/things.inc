if !def(APP_THINGS_INC)
def APP_THINGS_INC equ 1

include "common.inc"


/********************************************************************** Things *
Things are the entities (buildings, &c) found in each stage that can be
destroyed by the player (by hitting the Ballder into them).


************************************************************************ Thing *
An instance of a Thing (entity).


***************************************************************** Thing ID Tag *
Thing instances have a one byte ID tag. These can be used as handles/references.
- usage is optional
- user allocates/assigns IDs
- valid ID tags are unique


*********************************************************** Thing.status: bits *
HITS        ( 0, 2 )
	The number of hits the Thing takes before it dies.
	Every time an alive Thing is hit (missile collision rising edge) HITS is
	reduced by one. When HITS is reduced to zero, the Thing 'dies'.
	Things are created with HITS set to 1 by default.
RESERVED    ( 2, 1 )
RESERVED    ( 3, 1 )
TARGET      ( 4, 1 )
	Indicates that the Thing is a game objective.
	When a Thing with TARGET set dies, the TARGET flag is cleared.
	Things are created with TARGET set by default.
EV_HIT      ( 5, 1 )
	A collision event flag, set when a collision (a hit) is detected.
	The flag is otherwise cleared every tick.
	EV_HIT is set regardless of if the Thing is "alive" or not.
EV_DIE      ( 6, 1 )
	A collision event flag, set when a hit is detected and the value of HITS
	was reduced to zero -- HITS was more than 0 when the hit was detected.
	The flag is otherwise cleared every tick.
VOID        ( 7, 1 )
	When set, the Thing is ignored/disabled. Things are stored in a 
	contiguous array and VOID is used to have "empty" slots.


******************************************************************** Thingcode *
A little bytecode language for describing and configuring Things.


***************************************************************** ThingMachine *
A little VM type thing for executing Thingcode.
*/


def ThingsMax equ 16


; Thing instance struct

	stdecl Thing
		stfield status      ; Thing status flags
		stfield tag         ; ID tag
		stfield collider    ; collider index
		stfield pos, 2      ; 2D position vector
		stfield draw_mode
		stfield drawable, 2

		stfield ev_die      ; event vector invoked when Thing destroyed
	stclose


; Thing.status constants

def bThingStatus_HITS0      equ 0 ; Thing.status HITS bit 0
def bThingStatus_HITS1      equ 1 ; Thing.status HITS bit 1
def bThingStatus__2         equ 2
def bThingStatus__3         equ 3
def bThingStatus_TARGET     equ 4 ; Thing.status TARGET flag
def bThingStatus_EV_HIT     equ 5 ; Thing.status EV_HIT event flag
def bThingStatus_EV_DIE     equ 6 ; Thing.status EV_DIE event flag
def bThingStatus_VOID       equ 7 ; Thing.status VOID flag

def fThingStatus_TARGET     equ $10
def fThingStatus_EV_HIT     equ $20
def fThingStatus_EV_DIE     equ $40
def fThingStatus_VOID       equ $80

def fThingStatus_HITS       equ $03 ; Mask 'HITS' part of Thing status.
def fThingStatus_EV         equ $60 ; Mask all event bits
def fThingStatus_DEFAULT    equ fThingStatus_TARGET | 1


; Thing.draw_mode enum
rsreset
def fThingDrawMode_OAM      rb 1 ; Drawable is OAM object { CHR, ATTR }
def fThingDrawMode_Sprite   rb 1 ; Drawable is pointer to Sprite
def fThingDrawMode__COUNT   rb 0


; Thing.tag

; The default tag
def ThingTag_UNSET equ $FF


; ThingEvec: Thing event handlers
rsreset
def ThingEvecEndpoint_THINGCODE rb 1 ; Evec endpoint is thingcode
; def ThingEvecEndpoint_DISABLED  rb 1 ; Evec is unused/disabled
def ThingEvecEndpoint__COUNT    rb 0 ; Number of ThingEvecEndpoint variants

	stdecl ThingEvec
		stfield config         ; Evec endpoint type / config / flags
		stfield endpoint_bank  ; Endpoint bank
		stfield endpoint, w    ; Endpoint address
	stclose


; ThingMachine status flags

; Execution stopped, do not continue.
def bThingMachineStatus_STOP equ 7
; The cached Thing data needs to be refreshed.
def bThingMachineStatus_CACHE_DIRTY equ 6

def fThingMachineStatus_STOP equ $80
def fThingMachineStatus_OK  equ $00

	stdecl ThingMachine
		stfield status    ; machine status flags
		stfield prg, w    ; current program pointer
		stfield thing, w  ; pointer to Thing
	stclose


; Thingcode instructions

rsreset
def tc0               rb 0
def tc_New            rb 1
def tc_Save           rb 1
def tc_Stop           rb 1
def tc_CollideNone    rb 1
def tc_CollideTile    rb 1
def tc_CollideBox     rb 1
def tc1               rb 0
def tc_Hits           rb 1
def tc_Tag            rb 1
def tc2               rb 0
def tc_Goto           rb 1
def tc_Instance       rb 1
def tc_Position       rb 1
def tc_DrawOAM        rb 1
def tc_DrawSprite     rb 1
; tc_EvecDie ThingEvec
; Set the 'die' event vector.
def tc_EvecDie        rb 1

def tc__COUNT         rb 0 ; Number of instructions
def tc__ALL_NAMES equs "New, Save, Stop, CollideNone, CollideTile, CollideBox, Hits, Tag, Goto, Instance, Position, DrawOAM, DrawSprite, EvecDie"

; BuildJumpTable CODE_PFX, IMPL_PFX, OP_NAMES
; Build jump table mapping {CODE_PFX}OP to {IMPL_PFX}OP.
; Verifies that table is contiguous (no gaps between CODES).
macro _BuildJumpTable
	def _code_pfx equs "\1"
	shift
	def _impl_pfx equs "\1"
	shift
	for i, _NARG
		assert {_code_pfx}\1 == i
		dw {_impl_pfx}\1
		shift
	endr
	purge _code_pfx, _impl_pfx
endm


; Thingcode helper macros

macro ThingcNew
	assert fatal, _NARG == 0
	db tc_New
endm


macro ThingcSave
	assert fatal, _NARG == 0
	db tc_Save
endm


macro ThingcGoto
	assert fatal, _NARG == 1
	db tc_Goto
	dw (\1)
endm


macro ThingcStop
	assert fatal, _NARG == 0
	db tc_Stop
endm


macro ThingcInstance
	assert fatal, _NARG == 1
	db tc_Instance
	dw (\1)
endm


macro ThingcPosition
	assert fatal, _NARG == 2
	db tc_Position, (\1), (\2)
endm


macro ThingcHits
	assert fatal, _NARG == 1
	assert fatal, (\1) <= fThingStatus_HITS
	db tc_Hits, (\1)
endm


macro ThingcTag
	assert fatal, _NARG == 1
	db tc_Tag, (\1)
endm


macro ThingcCollideNone
	assert fatal, _NARG == 0
	db tc_CollideNone
endm


macro ThingcCollideTile
	assert fatal, _NARG == 0
	db tc_CollideTile
endm


macro ThingcCollideBox
	assert fatal, _NARG == 4
	db tc_CollideBox, \#
endm


macro ThingcDrawOAM
	assert fatal, _NARG == 1 || _NARG == 2
	if _NARG == 1
		db tc_DrawOAM, (\1), 0
	elif _NARG == 2
		db tc_DrawOAM, (\1), (\2)
	endc
endm


macro ThingcDrawSprite
	assert fatal, _NARG == 1
	db tc_DrawSprite
	dw (\1)
endm


macro ThingcEvecDie
	assert fatal, _NARG == 1
	db tc_EvecDie
	if strcmp("\1", "0") == 0
		db $FF, 0
	else
		db 0, bank(\1)
	endc
	dw (\1)
endm


; DefThingLegacy CHR, OAM_ATTR
;
; A Thingcode template for creating Things that behave as the original Things
; (pre-Thingcode) did. Uses a single OAM entry and a generated 8x8 collider.
;
; The Thing is a TARGET, and will be destroyed by one hit.
; When hit, the CHR used to draw it is incremented by one. This happens twice,
; so Tile data must be layed out accordingly, with the provided CHR being the
; initial state, followed by two successively more destroyed versions.
macro DefThingLegacy
	ThingcNew
	ThingcDrawOAM (\1), (\2)
	ThingcCollideTile
	ThingcHits 1
	ThingcEvecDie .state1\@
	ThingcSave
	ThingcStop
.state1\@:
	ThingcDrawOAM (\1) + 1, (\2)
	ThingcHits 2
	ThingcEvecDie .state2\@
	ThingcSave
	ThingcStop
.state2\@:
	ThingcDrawOAM (\1) + 2, (\2)
	ThingcSave
	ThingcStop
endm

endc ; APP_THINGS_INC
