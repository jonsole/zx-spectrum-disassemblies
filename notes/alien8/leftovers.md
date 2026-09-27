# Leftovers

**Question this answers:** what in the block is never used -- dead code,
unused data and variables, the code that never ran and why -- and what the
tape carries that is not the game's.

**Short answer:** a handful of dead routines, most of them Knight Lore's
(its werewolf sound, its panel-colouring routine, a check of R that no
longer jumps), one drawing nudge and one sprite nothing reaches, Knight
Lore's variables for things Alien 8 lacks, and Knight Lore's copyright line
from 1984. Above the code, where the game's buffer, stack and tables go, the
tape holds whatever the mastering machine had there: stack debris, the
ROM's letters, another program's font, and the first 1464 bytes of the
Interface 1's ROM.

## How it works

**Dead code** (each *read*, and *searched*: no word in the block points at
it, and the code map's descent never reached it):

| Address | Label | What |
|---|---|---|
| $A8F1 | `R_CHECK_LEFTOVER` | called once by `START`: `LD HL,0`, `LD A,R`, `RLA`, `RET` -- and the next byte, `JP_HL_LEFTOVER` ($A8F8), is a `JP (HL)`. It reads like the remains of a check that jumped to address 0, a reset, when bit 7 of R was set -- which only an `LD R,A` can do, so perhaps a loader's signature -- with the conditional return made a plain RET (*inferred*) |
| $AB1F | `FACE_BY_STEP_UNUSED` | 66 bytes of code, unreferenced and never run: sets bit 1 of the graphic and the mirror flag from the signs of the steps with the mice's convention, but picks the axis of the smaller step. Stage 1 had it as data |
| $B5D4-$B5ED | (in `NOTES`) | 18 bytes of code and an 8-byte pitch table after the note table: four waves at a pitch chosen by the turn counter's low three bits. Knight Lore's moveable-block blip (its $B3E9), byte for byte apart from its three addresses, pitches and all (*compared*, stage 3; stage 2's search missed it because the addresses differ) |
| $B65F | `TRANSFORM_SOUND` | Knight Lore's werewolf-transformation sound (`sound_transform`, found in Knight Lore's snapshot by its bytes); no caller. Stage 1 had it as data |
| $BF42 | `UNUSED_NUDGE_L12_D9` | a drawing nudge (-12, -9) no graphic's routine uses; left as data |
| $CBE3-$CC00 | (in `BORDER_DATA`), `COLOUR_PANEL_RED` $CBF6, `COLOUR_PANEL_TAIL` $CBF9 | Knight Lore's `colour_panel`, byte for byte but for the fill routine's address: XOR A, fill 1 by 3 attributes at $5AB6 and $5ABD, LD A,$42, fill 6 by 4 at $5A97, all through `FILL_BOX`. Never called; `COLOUR_PANEL` does the job. Split over three entries because sna2ctl took its bytes for data and text |

**Code in live routines that never runs** (from `alien8-coverage.txt`: 117
bytes in 14 runs not executed by the build's sessions; what each is):

| Bytes | In | Why |
|---|---|---|
| $A9F8-$A9FD | `REMOTE_ROBOT` | a robot moving without an order -- falling, or pushed: a sound by its height and a redraw |
| $AD43-$AD45 | `CEILING_DROP` | the sound while it falls, not landed; the build's drop session let one go but never reached this -- why is open |
| $ADE4 | `CLOCK_BORROW` | a borrow past the first digit: cannot while the game ends at zero |
| $AE74-$AE80 | `SOCKET` | recreating the sparkle: ran in range 1's staged scene |
| $AFF1-$AFF7 | `LOOSE_VALVE` | a valve of the wrong kind on a socket: cannot happen ([`valves-and-sockets.md`](valves-and-sockets.md)) |
| $B2C2-$B2D8 | `DROPPING_BLOCK` | sinking while stood on: ran in range 2's staged scene |
| $B311-$B313 | `PUSHABLE` | "no step, but moved": cannot by the reading |
| $B37E-$B38B | `LIFT` | the retry at 4 when the rider stops it |
| $B507-$B51C | `PLAY_NOTE` | a rest: no tune has one |
| $B6C6-$B6CD | `LOWER_HALF_STEP` | a lower half's footstep: graphic 11 is odd, so never |
| $BEA1-$BEA6 | `TAKE_OR_LEAVE` | the swap when picking up with `CARRIED_LAST` full |
| $C29C-$C29F | `MOVE_PLAYER` | Knight Lore's hold-still in the scene after a game: the robot's records are cleared before the scene, so never (*inferred*) |
| $C8BF-$C8C4 | `BOXES_INTERSECT` | destroying the candidate valve (the other branch, $C8CE, ran in range 4's scene) |
| $CC89 | `ADJUST_PLYR_Z_FOR_ARCH` | no doorway matched among four: never, if every room keeps its doorways first |

**Slips that run** (*read*; each in its topic): `TURNING_LEGS` loses the
controls in the turn's sound, so the step at the end of a turn never happens
([`robot.md`](robot.md)); `SOCKET` projects the record at IY, not the new
sparkle's ([`valves-and-sockets.md`](valves-and-sockets.md)); the collapsing
block writes a zero to ROM address 0 as it vanishes
([`carrying-and-lifts.md`](carrying-and-lifts.md)); `VFLIP_SPRITE_DATA`
would loop 256 times on a one-row sprite turned upside down, which never
happens ([`drawing.md`](drawing.md)).

**Unused data**: the sprite at $88B3, a wedge-shaped block, reached by no
graphic number (`SPARE_SPRITEA`); the object record's +$14-+$17.

**Unused variables** (*searched* as operands; a block copy could reach them
but none does -- the only indirect accesses are the clears and the carried
list's LDDR, $5B83 to $5B87):

| Address | Knight Lore's use at the same offset |
|---|---|
| $5B01, $5B07 | spare there too |
| $5B0F-$5B11 | portcullis moving, portcullis falls, the transformation |
| $5B1F | a spiked ball falling (Alien 8 keeps its own at `DROPPING`) |
| $5B22 | the bouncing ball's step |
| $5B26 | rooms visited |
| $5B29-$5B2A | the percentage |
| $5B44-$5B57 | (past Knight Lore's layout; nothing) |

Reused differently: $5B1B-$5B1D (`SAVED_UVZ`; Knight Lore's cauldron count,
object phase, bounce height), $5B20 (`TEMPLATES_AT`; its drop latch), $5B24
(`GAME_OVER`; its charm rising), $5B25 (`LIFT_TOP`; its finale spark
height). Moved: the drop latch to $5B3B, the carried slots to $5B78, the
rooms seen to $5B58.

**The copyright line** (`OLD_COPYRIGHT`, $D1EB-$D1FF): a line naming 1984
and A.C.G. -- Knight Lore's text, the same 21 characters, at Knight Lore's
place (after its last routine, before its buffer). Nothing refers to it and
nothing reads it; the menu's own copyright line says 1985.

**Above the code** (what the tape holds where the game writes before it
reads -- *measured* by stage 1: no first access to any of these addresses
was a read):

| From | To | What |
|---|---|---|
| $D200 | $D25F | zeros |
| $D260 | $D29F | stack debris: words such as $0DF3, $0BCE, $50E2, $171E -- ROM and display addresses |
| $D2A0 | $D347 | the Spectrum ROM's capital letters A to U |
| $D348 | $D8FF | the Interface 1 ROM from its offset 0 to $05B7, its 24 error reports at its offset $02B8 ($D600) |
| $D900 | $FF17 | a byte of $0D, then zeros |
| $FF18 | $FF57 | stack debris |
| $FF58 | $FFFF | a bold font's capital letters A to U, of some other program |

## How this was found

- The dead code by the code map's descent and the listing's references
  (stage 1), each piece then read by the stage 2 agent whose range held it;
  the Knight Lore pieces found in Knight Lore's snapshot and listing by
  their bytes (`TRANSFORM_SOUND`, `colour_panel` at Knight Lore's $D2EF).
  $CBE3, $CBF6 and $CBF9 searched as words: the only hits are inside other
  instructions' bytes.
- The copyright line compared with Knight Lore's `copyright_notice` ($D8DE in
  its listing).
- The Interface 1 claim, *measured* as far as the bytes allow (range 5): the
  leftover disassembled as if loaded at address 0 has the restart table in
  place (RST 0 = POP HL, LD (IY+$7C),0, JP $0700; RST 8; RST 16 storing HL
  into SBRT; EI and RET at $38; RETN at $66), uses the Interface 1's system
  variables (FLAGS3 at IY+$7C, SBRT, the stream and name variables around
  $5CD8), and holds its 24 error reports. Of its absolute JP and CALL targets
  that land inside it, 30 of 31 fall on instruction starts at origin 0, 22
  of 30 at origin 1, 8 of 30 at origin 2. No Interface 1 ROM image was to
  hand, so it was not compared byte for byte.

## Confidence

*Read* and *searched* for the dead code and variables; the leftovers above
the code *measured* (write before read) and the Interface 1's identity
*measured* by its structure, *inferred* for its bytes.

## Knight Lore and Pentagram

Knight Lore's block ends the same way: `copyright_notice`, the screen
buffer, 13 spare bytes, the tables at $F100; its buffer's tape contents were
not compared. Pentagram's leftovers are a longer trail of Knight Lore's
features cut out ([`../pentagram/leftovers.md`](../pentagram/leftovers.md));
Alien 8 has fewer, and uses some that Pentagram left dead (`PRINT_TEXT`, the
placement nudge, directional control).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `R_CHECK_LEFTOVER`, `JP_HL_LEFTOVER` | `SUBA8F1`, `DATAA8F8` | $A8F1, $A8F8 | the check that returns |
| `FACE_BY_STEP_UNUSED` | `DATAAB1F` | $AB1F | unused code, now `c` |
| `COLOUR_PANEL_RED`, `COLOUR_PANEL_TAIL` | `TEXTCBF6`, `DATACBF9` | $CBF6, $CBF9 | Knight Lore's `colour_panel`, continued |

## Disassembly corrections

- Stage 1's memory map split $D348-$D8FF into code, messages and more code;
  it is one piece of the Interface 1 ROM (range 5).
- $AB1F and $B65F were data; they are code (ranges 1 and 2).

## Open questions

- Whether `R_CHECK_LEFTOVER` was ever live (another release might have a
  conditional return at $A8F7); only one tape has been looked at.
- A byte-for-byte comparison of $D348-$D8FF with an Interface 1 ROM image
  (edition 1 or 2), which would say which edition was on the mastering
  machine.
- Whether $CBE3-$CC00 should be one entry: it needs a span over the
  generated boundaries (range 5 left it in three).
