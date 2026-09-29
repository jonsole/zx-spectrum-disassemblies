# Krumlinde's disassembly beside this one

**Question this answers:** how far Ville Krumlinde's disassembly of
Fairlight ([FairlightZ80](https://github.com/VilleKrumlinde/FairlightZ80))
agrees with this one, and where his reading differs -- and how each
difference was checked.

**Short answer:** closely on the map of the code: of this listing's 3545
real instructions, 3388 are instructions in his too, and 79 of the 86
routines here begin at one of his labels. Nearly all the differences come
from what he could not see in a mid-game snapshot -- the start-up, the
loader -- and from bytes the game rewrites as it runs. His analysis is a
good guide, and several names here are his (credited where used). Where it
goes wrong it is mostly for one of three reasons: IY holds $FF80, so a
variable reached as IY+n and one reached by its address can be the same
byte; bytes the code rewrites held other values in his snapshot, hiding the
compositor's use of pages $DA and $DB; and without the author's symbol
table and source text (left on the tape) much of the object code stayed
`Sub_...`. The main differences: the entry point, interrupts, the
compositor's four pages, the texture format, the direction of EEN, the room
box records, gravity, and a dozen smaller readings.

His repository has no licence: only facts, addresses and names are taken
from it, each credited, and none of his prose; every word here is this
project's own. It is a hint, never proof.

The build writes `game_disassembly/fairlight/krumlinde.txt`: each entry of
this listing with his label at its address and his labels inside it, and at
the top the instruction counts and the ranges where the two maps differ.

## Where the maps differ

From `krumlinde.txt` (*compared*: his source listed by sjasmplus, an
instruction being a listing line that is not DB, DW or DEFS; ours, the
instructions in this listing's code entries). Since stage 2 the report
counts 3580 instructions of ours, but 35 of them are the first bytes of
strings after `CALL PRINT`, shown as instructions: he, rightly, has them as
data, so they appear in "ours and not his" without being a disagreement
(reported to the lead; [`printing.md`](printing.md)). The real differences:

| Here, not his | Why |
|---|---|
| $C000-$C0AF, $C47C-$C4B7 | The loading tune and the start-up. In his snapshot these bytes are the clean copy of the screen, overwritten long before -- so his listing has no sound at all; nor has the game, beyond the tune ([`sounds.md`](sounds.md)) |
| $B686, $B733 | The routine that prints the title page: a `CALL`, a string, a `RET`. He has the whole thing as data (his text identifies the string correctly) |
| $E46D-$E46E, $E488-$E494, $E4BE-$E4CA, $EFD2-$EFD6 | Instructions whose operands the code rewrites; his snapshot holds rewritten operands, which decode differently ([`compositing.md`](compositing.md)) |
| $E038 | A routine's first instruction; see below |
| $F803, $F9E2, $FECC | Instructions he split into a DB and a label: `AND (IY+$7C)` at $F803, `CP $0A` at $F9E2, `JR $FEE3` at $FECC |

| His, not here | Why |
|---|---|
| $DCD2-$DD1C | The loader's failure routine, which he describes as a font-copying routine of the game. It never runs on a good load; here it is data, described as the loader's |
| $E037-$E03A | He starts an instruction at $E037; the processor starts one at $E038 (it ran in the sessions), and $E037 is the last byte of a scrap of the symbol table |
| $F804-$F805, $F9E3, $FECD | The other halves of the three splits above |

## Where his reading differs

Each was checked against the code, and where marked in the simulator. The
topic files have the detail.

**Start-up and loading** ([`start-up.md`](start-up.md), [`loading.md`](loading.md)):

- **The entry point and the stack.** He takes $F065 as the entry, and
  reconstructs SP and IY for his build. The loader returns to $C47C, which
  sets SP ($639A), plays the loading tune, sets IY, turns interrupts off,
  copies the tables into place and jumps to $F065 (*measured*). His open
  question -- where the first launch into the main loop comes from -- is
  answered by the title routine: `TELE` calls `ROOMST`, inside which the
  main loop runs.
- **Interrupts.** He reads his snapshot's IM 1 as a 50 Hz interrupt serviced
  by the ROM throughout. The game runs with interrupts off: `DI` at $C487
  (*read*; *measured*: IFF clear, FRAMES still). Stage 1 of these notes got
  this wrong too, saying the `EI` at $C018 left them on.
- **$DC00-$E025**, his "debug-menu table": the loader's cleared bytes, its
  failure routine and the assembler's symbol table, which gives the author's
  own names for 64 routines ([`symbols.md`](symbols.md)). His $617C text
  "artifact" is one of several stretches of the game's own source
  ([`leftovers.md`](leftovers.md)).

**Rooms** ([`rooms.md`](rooms.md), [`textured-fill.md`](textured-fill.md)):

- **The room table**: he counts 57 entries at ($FFB5) = $758C, the parts;
  there are 56 (the 57th "record" is the bytes after the last). The rooms
  are the separate table at $68B0, 81 of them.
- **Codes $00-$BF** are points (row, column), not tiles: a room is a vector
  drawing.
- **One mode byte, one repeat count**: the codes $C1-$CE set bits of $FFEB,
  which he says nothing reads -- it is IY+$6B, the mode read before every
  command; $D5's $FFEC and $D6's IY+$6C are one byte.
- **$E4 $05's bytes** are the origin added to placed objects (IY+$5F-$61),
  not orphaned writes; **$E0 is not a tail call**; the guard bit at IY+$3C
  keeps a room with several `$E4 $04`/`$05` from placing the table's things
  twice; the pen's bit 0 draws paper, not a second XOR.
- **$FFE8**, his room ID, is not the room (that is $FFB4, IY+$34): it is
  the attribute byte for the clear, always 0.
- **The texture format**: bytes 8-15 are the right-hand 8 pixels of the
  same rows, not rows 8-15, and the pair is chosen by bit 3 of the screen
  line; his "solid $55" ($E8) is vertical stripes. His fill algorithm is
  right.

**Objects** ([`object-records.md`](object-records.md), [`object-table.md`](object-table.md)):

- **Sizes** are lengths from a corner, not half-extents about a centre
  (*measured* with the pick-up's search).
- **The six records at $BC18** are the room's floor, ceiling and walls,
  patched per room; his `Room_PatchObjectTemplates` "patches a shared byte
  across six object-table records" -- it writes six different bytes of those
  six records. That, and gravity, answer his open question of how floors
  hold things up.
- **"Decorations"** ($EB1A) are all of a room's objects; `FREE_RECORD` is a
  pointer, not a free list; the four bytes his `Room_PlaceObjectRef` did not
  trace are +12, x, top, z; the shape table at $A91E/$A921 is the object
  table less six and three, laid there only by the start-up.
- **Decoration type 40**, which he renders as noise, is a 16 by 10 sprite
  the game draws; the sprite format is image then mask at each sprite's own
  width (stage 1).

**Drawing** ([`compositing.md`](compositing.md), [`drawing-objects.md`](drawing-objects.md)):

- **Pages $DA and $DB reach the screen**: the compositor steps `INC B`
  through all four pages; the steps for $DA/$DB are the bytes whose `JR`s
  it rewrites, which in his snapshot skipped them. *Measured*: the four
  pages rendered with the knight in front of and behind a creature.
- **Which plane each mode draws**: mode 8 the image, modes $80, 0 and 4 the
  mask (he has 4 and 8 the other way); mode $80 is whichever object is
  redrawn, not "most likely the player"; page $D8 is the cover of objects in
  front, not a repurposed room buffer; `IS_IN_FRONT` has no special case;
  IY+$72 is the copy of +14 that `MIRROR` writes; $D800 is cleared before
  every redraw; `RTN_Cull_Sprites` is one step of the whole redraw
  (`REDRAW_OBJECT`, the author's SRP); `RTN_Init_Sprite_Sort` ($EC75) is the
  panel box's clear.

**Behaviour** ([`object-states.md`](object-states.md), [`movement.md`](movement.md),
[`collision.md`](collision.md), [`meeting.md`](meeting.md), [`chasing.md`](chasing.md)):

- **State 8 is not "gated behind bit 7 of IY+$17"**: bit 7 is the freeze
  (a kind-5 thing used), which removes the other states. His reference
  object at $FF8F is the decoy (kind 8) that state-9 guards chase and take.
- **Gravity exists**: his "no per-tick Z decrement" misses the down bit that
  `ADD_GRAVITY` ($F67E) ORs into every direction not rising.
- **$F959** (left as `Sub_F959`, "plausibly push or slide") settles
  meetings: hurting, fighting, stealing, a wraith's destruction, the pits.
  The dead bytes at $FA74 he noted too.
- **$FC48** is called only from the chasers' timer (`STEER`), not from the
  shared movement code; its other target is the decoy.
- **$F1C8** subtracts from LIFE; it displays nothing.
- **$FFF8**, his `VAR_Saved_SP`: SP only in the screen clear; in the
  object code it is the found record's number (the author's T+20).
  `Sub_FF98`/`Sub_FF9B` are one array of six strike counters.

**The knight and the rooms' traffic** ([`knight.md`](knight.md), [`carrying.md`](carrying.md),
[`doors.md`](doors.md), [`entering-rooms.md`](entering-rooms.md), [`main-loop.md`](main-loop.md)):

- **EEN's direction.** His `RTN_Refresh_Shape_Data` ($F906) copies from the
  table into the records; it copies each record's place *into* the table
  (*measured* in room 20).
- **$FD9C** walks the five carried places (IY stepped so IY+$1F walks
  `CARRIED`), not a linked list of room objects; no path reaches room 0;
  the main loop returns from `ROOMST` rather than having no exit.
- **Keys**: 0 is not the use key -- use is 6 or 7, SPACE with SYMBOL SHIFT
  pauses, SYMBOL SHIFT with 0 quits (*measured*); kind 4 adds 10 (to at
  most 99), kind 5 freezes.
- **Doors**: the key test is before his `RTN_Check_Door_Keys` ($F7DA-$F7F6);
  the second BLOCKED ($F8E3), which he leaves unresolved, is the far side
  being taken; his reading of +13 as the destination is right.
- **Carrying**: the drop spot is the knight's own length on the sides the
  axis grows, the thing's on the other two; $F4F4 is the pick-up; the weight
  limit is a load of 8.
- **$F09B** enters `ROOM` (29 for a new game, 30 for the kind-9 thing), not
  room 1; room 1 is GAME OVER's backdrop.
- He has no reading of the knight's keys, jump, fight or fall damage.

## Confidence

The counts are *compared* at every build. Each difference is *read* from
the code, the ones marked *measured* also seen in the simulator.

## Open questions

- None about his map. His later analysis files (`render_pipeline.md`,
  `sprite_graphics.md`, `buffers.md`, `game_text.md`) were read only where a
  topic needed them.
