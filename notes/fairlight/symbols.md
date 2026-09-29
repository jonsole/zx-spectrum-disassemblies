# The author's names

**Question this answers:** what names Bo Jangeborg gave his routines, and
how we know.

**Short answer:** the tape carries part of the development assembler's
symbol table, at $DD39-$DFF1 (and scraps at $E026 and $E09A): 64 whole
symbols and the tail of another, each a name and a value. Every value is
the address of an instruction in Release 2's code that ran in the build's
sessions, 20 of them the first instruction of a routine in this listing.
They are this very build's symbols, so they are the original names of those
routines, and the listing uses them (stage 2). The leftover source text
gives about forty more, matched to the code by their instructions (below).

## How it works

A symbol is a node of a binary tree (*read*, from the bytes, and checked by
the links pointing at other nodes):

| Offset | What |
|---|---|
| +0, +1 | Link to the node for names that sort before this one ($0000: none) |
| +2, +3 | Link to the node for names after |
| +4 | 1 |
| +5 ... | The name, bit 7 set on its last letter |
| then 2 bytes | The value |

The links are addresses in the development machine's memory, and they are
addresses in this same region: the table was in memory at the place the
tape's image has it, and the game's code, assembled over the rest of it,
cut it off at $DFF2 (a routine begins there). The loader's own bytes,
$DAC0-$DD38, are not loaded from the tape, which is why the table starts
mid-node: the first thing at $DD39 is the last letter (G) and the value
($F065, the title routine) of a symbol whose start is lost.

`fairlight_data.symbols()` walks the nodes; the listing lays each out as a
line with its name and a link to its value.

## The names

Value, and whether it is the start of a routine in this listing (R) or an
instruction inside one. Names are as the table spells them.

| Name | Value | | Name | Value | |
|---|---|---|---|---|---|
| ATTRI | $F0FB | R | I0 | $F21D | |
| PAUS | $F0D8 | | NOPROP | $F67E | |
| TELE | $F09B | | I3 | $F258 | |
| ROOMST | $FD20 | R | I00 | $F22C | |
| EEN | $F906 | R | I01 | $F245 | |
| WAIT | $F0D2 | R | I02 | $F24D | |
| INPUT | $F0DF | R | I30 | $F267 | |
| IN31 | $F0E6 | R | I8 | $F3CD | |
| RESTOR | $F10B | R | I4 | $F275 | |
| MIMAN | $F117 | R | I31 | $F272 | |
| MIRROR | $F12D | | KON6 | $F67D | |
| MIWRAI | $F11F | R | I5 | $F29F | |
| MITRO | $F127 | R | BUT | $F7B0 | R |
| MW1 | $F13A | | BUT2 | $F7BA | R |
| MW2 | $F143 | | BB2 | $FCF2 | |
| MW | $F157 | R | ANIM | $F645 | |
| MW0 | $F160 | | I9 | $F2BE | |
| MIR0 | $F164 | | I50 | $F2B5 | |
| MIR1 | $F167 | | INP5 | $F5D7 | |
| MIR2 | $F169 | | I6 | $F309 | R |
| MIR3 | $F18D | | I91 | $F2F2 | |
| FACING | $F199 | R | I92 | $F2EE | |
| FA0 | $F1AC | | I95 | $F2EB | |
| DECLI1 | $F1B4 | R | INPE | $F677 | |
| DECLIF | $F1B6 | | ZZ1 | $F2F7 | R |
| DE1 | $F1C8 | R | I600 | $F33C | |
| DE2 | $F1D7 | | ZOOMIN | $FC48 | R |
| CHE3D | $F1E0 | R | I601 | $F311 | |
| NOG | $F68C | | I11 | $F35A | |
| | | | I602 | $F335 | |
| | | | I60 | $F346 | |
| | | | I61 | $F34D | |
| | | | I62 | $F354 | |
| | | | I12 | $F36F | |
| | | | I1110 | $F35E | |

What each names, now that every routine is described (stage 2, *read*):

| Name | Label in the listing | What |
|---|---|---|
| ATTRI, WAIT, PAUS, INPUT, IN31, RESTOR | the same | Colour the screen; wait for no key then a key (PAUS the second half); read a key row; read the Kempston port ($1F = 31); copy the screen to the clean copy ([`game-cycle.md`](game-cycle.md)) |
| TELE | `TELE` | A new game's entry into its room, which the thing of kind 9 uses too |
| ROOMST | `ROOMST` | Enter a room, or end the quest ([`entering-rooms.md`](entering-rooms.md)) |
| EEN | `SAVE_OBJECT_POSITIONS` | Save the room's things' places into the object table |
| MIMAN, MIWRAI, MITRO, MIRROR, MW, MW0-MW2, MIR0-MIR3 | the same | Mirror the knight's, the wraith's and the troll's frames ([`turning-sprites.md`](turning-sprites.md)) |
| FACING, FA0 | the same | Facing bits back to a direction and a view |
| DECLI1, DECLIF, DE1, DE2 | the same | Take from LIFE |
| CHE3D, I0-I95 | the same | The per-object update and its states ([`object-states.md`](object-states.md)) |
| ZZ1 | `STEER` | A chaser's course and count ([`chasing.md`](chasing.md)) |
| ZOOMIN | `ZOOMIN` | Aim a chaser |
| I6; I601, I600, I1110; I602, I60-I62, I11, I12 | `CREATURE_UPDATE`; `GUARD_MOVES`, `GUARD_FRAMES`, `WRAITH_MOVES`; the rest inside | States 6-15 |
| I8 | `KNIGHT_UPDATE` | The knight's update ([`knight.md`](knight.md)) |
| INP5 | `KNIGHT_TURN` | Turn him and choose walk, jump or fight |
| ANIM | `ANIM` | A frame from a run ([`movement.md`](movement.md)) |
| INPE, KON6, NOPROP, NOG | `SET_SPRITE_AND_MOVE`, `MOVE_IN_DIRECTION`, `ADD_GRAVITY`, `SKIP_GRAVITY` | The shared movement tail |
| BUT, BUT2 | `WORKING_POSITION`, `WORKING_SIZES` | The mover's place and lengths |
| BB2 | `BOX_OVERLAP` | The box test ([`collision.md`](collision.md)) |
| (...G) | `TITLE_SCREEN` | The title routine, whose name is cut off at $DD39 but for its last letter |

## The source text

The other leftovers are pieces of the game's source, as the assembler held
it: numbered lines, tab-separated, each ended by a carriage return
([`leftovers.md`](leftovers.md) lists where and which lines). The DEFB
lines at $A8FC-$B685 and $BCA4-$BFFF are the source of the object table: 99
of the 101 whole DEFB lines there are records of it, byte for byte
(*compared*, stage 1). In stage 2 the code-bearing stretches were matched to
the game instruction by instruction (a byte search of the snapshot for each
line's instruction), which names more of the author's routines and labels.
These are *read* matches, not symbol-table values: the name is placed where
the text's instructions and the game's agree.

| Name | Address | Label in the listing, or where | From the text at |
|---|---|---|---|
| V | $FF80 | The variables' base, IY (`(V+3)` is $FF83, `(V+18)` $FF92) | $617C, $D135 |
| T | $FFE4 | The working copy's base (`(T+20)` is $FFF8, `LD (T),HL` at $FDA5) | $617C, $D135 |
| DATLEN | 20 | An object record's length | $D135 |
| PRINT | $EBFE | `PRINT` (kept) | $D694 |
| INFOR | $EC4C | `SHOW_THING_IN_USE` | $617C, $D694 |
| INFO0 | $EC75 | `CLEAR_THING_BOX` | $D694 |
| SRP | $ECBD | `REDRAW_OBJECT` | $617C |
| MESS2 | $DFF2 | `MESS2` | $D135 |
| DOE | $F4E3 | `KNIGHT_DONE` | $617C |
| ROMM | $F4E6 | `SET_THING_ROOM` | $617C |
| WEI3 | $F555 | `TAKE_THING` | $617C |
| I88 | $F595 | `KNIGHT_CONTROLS` | $617C |
| I89, I82-I85 | $F59A, $F59F, $F5A4, $F5A9, $F5AE | `STICK_DIRECTION` and its four tests | $617C, $639C |
| I80, INP2-INP4 | $F5B3, $F5BC, $F5C5, $F5CE | `WALK_KEYS` and its three tests | $639C |
| INP59 | $F5F3 | `KNIGHT_FIGHT` | $639C |
| ROS | $FD9C | `LOAD_ROOM` | $D135 |
| OBJD, OB2 | $FDA8, $FDD7 | The loop over the carried places, in `LOAD_ROOM` | $D135 |
| STAR2 | $FE8F | Use the thing in the place in use | $D694 |
| USE6, USE5, USE4 | $FEB7, $FEC4, $FECE | Kinds 6, 5 and 4 | $D694 |
| ST21, ST22 | $FEDF, $FEE3 | LIFE 99; the thing used up | $D694 |
| ST20, ST4, ST5 | $FEF1, $FEFC, $FF03 | Choosing a place, 1-5 | $D694 |
| STE3 | $FF0E | `SHOW_IN_USE` | $D694 |
| ST6 | $FF1E | Show the thing (`CALL INFOR`) | $D694 |
| ST3 | $FF21 | `START_PASS` | $D694 |
| ST9 | $FF42 | The message line's call | $D694 |
| BT32, BT33 | -- | Code that stores IY+$71 after an `AND 5`; like `MEET_DECOY` ($FA83) but not line for line, so not placed | $C4BA |

The same text calls EEN, TELE and INPUT, agreeing with the symbol table.

## Confidence

The format: *read*, and consistent for all 64 nodes. That the values are
this release's: *measured* -- every value is an instruction the sessions
executed, and 20 are routine entries; Release 1's table holds different
values, as its code is laid out differently ([`versions.md`](versions.md)).

## Open questions

- The two scraps at $E026 and $E09A: the one at $E026 is a node named I62
  with a value 43 more than the main table's, so from another state of the
  table (an earlier assembly, or an earlier pass); the one at $E09A parses
  uncertainly ([`leftovers.md`](leftovers.md)).
- BT32 and BT33 ($C4BA) match no code in this release line for line: an
  earlier version of the step code?
