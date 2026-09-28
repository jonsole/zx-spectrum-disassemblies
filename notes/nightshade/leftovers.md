# Leftovers

**Question this answers:** what in the game is never used -- code that
never runs, tables never read, memory never touched -- and why each is
known to be so.

**Short answer:** ten runs of code (156 bytes) never ran in the build's
sessions, and two more the coverage file does not list; each is explained
below, and seven of the twelve are dead. Four
pitch tables are never read because of a bug; two cell types and their
four buildings are on no map cell; two actions of the drawing order are in
no record; and above the code, one byte, a page and a bit are never
touched, while the tape leaves a copy of the game's last 512 bytes and the
ROM's debris where the buffers go.

## How it works

**Code that never ran** (`game_disassembly/nightshade/nightshade-coverage.txt`):

| Run | In | Why it did not run | Dead? |
|---|---|---|---|
| $5B80-$5BAA | `LOADER` | ran in the simulated load, not the sessions | no |
| $C019-$C01D | `CREATURE_UPDATE` | the creature left more than two cells behind; no session left it (run in stage 2) | no |
| $C121-$C128 | `HIT_SPLITS` | the split finding no empty record; no session had them all busy (run in stage 2) | no |
| $C1F9-$C1FC | `RESET` | protection checks 3 and 4 failing | no, but only for a copy or a cheat |
| $C6A3-$C6B8 | `NOTE_REST` | a rest in a tune; no tune has one | yes |
| $CF88-$CF8C | `DRAW_CELLS` | drawing-order actions 2 and 3; no record uses them | yes |
| $DC8E | `COAST_TO_GRID` | a final step of 1 into the grid; the knight's position is always even ([`knight.md`](knight.md)) | yes (*inferred*) |
| $E0EE-$E0FA | `HL_EQUALS_DE_X_A` | only the upside-down flip uses it | yes |
| $E366-$E399 | `TURN_SPRITE` | the upside-down flip; nothing sets bit 7 of a record's flags | yes |
| $E3D6-$E3D8 | `MIRROR_SPRITE` | the panel's villains with a sprite stored mirrored; did not happen in the sessions | no |

Two more runs never ran and are not in the coverage file, which lists only
the instructions the code map found: the first unit of each unrolled
sprite run, `SPRITE_ALIGNED_RUN` ($E49F-$E4A6) and `SPRITE_SHIFTED_RUN`
($E4CD-$E4DE). A patched `JR` could enter them, but only for a sprite five
bytes wide, and none is ([`drawing-sprites.md`](drawing-sprites.md)); the
code map took them for data and the annotations retype them as code
(*measured*: neither address is in the executed map). Dead.

**Data never read**:
- `VILLAIN_PITCHES` ($C35D-$C39C): four tables of sixteen, lost to the
  hum's bug ([`sound.md`](sound.md)).
- Cell types 11 and 26: on no map cell (*measured*, counted), so their
  buildings `BUILDING22`, `BUILDING23`, `BUILDING52`, `BUILDING53` are
  never drawn, and their box lists (shared with other types) and stock are
  never used for them. The single type-2 cell's stock is never used either.
- `NOTES`' note 0: never looked up.
- Graphics 23 and 31: no picture, no routine, never set.

**Slips that waste a little**: the stray monster in cell (0,0)
([`monsters.md`](monsters.md)); bonuses placed four columns over, gone the
next turn ([`finds-and-bonuses.md`](finds-and-bonuses.md)).

**Memory outside the code** (*measured*, stage 1: the simulator recording
the first access to every address of $5B00-$5DFF and $E5C4-$FFFF through
the menu, play, a new cell and more play):
- Below $5E00 only `FRAMES`' two bytes and `NMIADD` are read; the printer
  buffer (`PRINTER_BUFFER`, `PRINTER_BUFFER_END`) around the loader is
  unused; the stack reached $5DE8 in play.
- `LOADER_LEFTOVER` ($E600-$E7FF, inside `BUFFER`): the source side of the
  loader's move, a byte-for-byte copy of $E400-$E5FF (*compared*), until
  the buffer is first cleared.
- `ATTR_SPILL` ($F194): written one byte past the attribute buffer by
  `COLOUR_STRIP`, never read, never cleared.
- `UNUSED_F195` ($F195-$F1FF): never touched.
- `UNUSED_F800` ($F800-$F8FF): the slot the plain tables would have for a
  shift of 0, never built or read.
- `SHIFT_TABLES` ($FA00-$FFFF) in the snapshot: zeros, then from $FF18 the
  ROM's machine stack below RAMTOP (`ERR_SP`'s return and the GOSUB end
  marker), then the ROM's UDGs in the last 168 bytes -- overwritten by
  `MAKE_TABLES` at the first new game.

## How this was found

The coverage report of the build (every instruction the sessions ran),
each run then read (stage 2) and the explanations above checked against
the listing for these notes; the two "never ran" branches of range 1 run
by calling the routines with staged state. The map's cell types counted on
the snapshot. The first-access run is stage 1's.

## Confidence

As in each line. "Dead" means no input the game can meet reaches it, by
reading; $DC8E's rests on the knight's position staying even, which is
*inferred* from every step being even.

## Filmation (Knight Lore, Alien 8, Pentagram)

Alien 8 and Pentagram have the same ROM debris under their tables.
Pentagram carries Nightshade's blip and beep routines unused
([`knight-lore-alien8-pentagram.md`](knight-lore-alien8-pentagram.md)).

## Disassembly corrections

- Stage 1's journal listed `$C019` as a strike on the creature and `$E3D6`
  with the upside-down flip; see [`creature.md`](creature.md) and
  [`drawing-sprites.md`](drawing-sprites.md).

## Open questions

- Why cell types 11 and 26 were left in the tables.
