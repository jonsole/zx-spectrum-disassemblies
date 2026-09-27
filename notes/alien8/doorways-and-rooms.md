# Doorways and rooms

**Question this answers:** what a doorway is, how the robot walks out of a
room, what the next room is, and where he is put in it.

**Short answer:** Knight Lore's exits. A doorway is a background of two
pillars (graphics 2 and 3). The first pillar marks the legs as "in a
doorway" (bit 0 of +$07: walls off, the exit armed) when he is close, and
nudges him towards the doorway's middle while he faces through it. After his
move is cut, `HANDLE_EXIT_SCREEN` ($C36D) asks, by his facing, whether the
move takes him wholly past that wall; if so the room number moves by 1
within its row or by 16, the arrival wall is marked in U or V, and both his
records are saved as the start records. The rooms are a 16 by 16 grid. In
the new room `ADJUST_PLYR_UVZ_FOR_ROOM_SIZE` ($CC01) puts him just inside
the opposite wall and `ADJUST_PLYR_Z_FOR_ARCH` ($CC6D) stands him at the
height of the doorway he came through.

## How it works

**The doorways** (*read* from the backgrounds' pieces). Six backgrounds are
a doorway, each two pillars 26 apart along a wall, their middle at 128:

| Background | Wall | Pillars (graphic 2 first) | Z | Flags |
|---|---|---|---|---|
| 0 | high V (V 197) | U 141, 115 | 64 | mirrored |
| 1 | high U (U 197) | V 115, 141 | 64 | |
| 2 | low V (V 59) | U 141, 115 | 64 | mirrored |
| 3 | low U (U 59) | V 115, 141 | 64 | |
| 10 | high U | as 1 | 112 | |
| 11 | low V | as 2 | 112 | mirrored |

Backgrounds 10 and 11 are raised doorways, 48 above the floor.

**The pillars.** `SECOND_PILLAR` ($BFD8, graphic 3) only sets its nudge
(`SECOND_PILLAR_MIRRORED` $BFE4 for a mirrored one). `FIRST_PILLAR`
($BFEA, graphic 2) keeps the doorway's middle, 13 along the wall from
itself, in its own step fields (+$09-+$0B), and every turn:

- `CHK_PLYR_NEAR_ARCH` ($C082): with the legs within 15 of the middle
  across the wall and 6 along it, sets bit 0 of their +$07 --
  in the doorway, which lets them past the wall's line and arms the exit.
- `ARCH_NUDGE_TO_CENTRE` ($C02C): with the legs in use, bit 3 of their +$07
  (may use doorways) and `IS_NEAR_TO` ($C099) within 15, 15, 4, a routine
  from `NUDGE_ROUTINES` ($C048) by the pillar's facing: `NUDGE_ALONG_V`
  ($C050, into +$0F) or `NUDGE_ALONG_U` ($C069, into +$0E) -- one unit a
  turn towards the middle line, and only while he faces along the doorway.
  `CALC_PLYR_DUV` adds the nudge to his next step and clears it. The pillar
  is always graphic 2, so only entries 0 and 2 of the table are used.

**Leaving** (`HANDLE_EXIT_SCREEN` $C36D, inside `MOVE_PLAYER` after the cut):
not during the walk into a room (bits 4-7 of +$0C), and only with bit 0 of
+$07 set, which it clears; the room's half-sizes are pushed and
`DISPATCH_ON_FACING` jumps through `SCREEN_MOVE_TBL` ($C38F) to
`EXIT_LOW_U` ($C397), `EXIT_HIGH_U` ($C3F0), `EXIT_HIGH_V` ($C40B) or
`EXIT_LOW_V` ($C426). Each compares his far edge after the move with the
wall at 128 less (or plus) the half-size. Out: U or V becomes the marker 0
or $FF -- the wall he will arrive at -- and the room becomes room - 1 or
room + 1 within its row (`EXIT_WITHIN_ROW` $C3B0: the column in the low
four bits changed on its own, so it wraps within the row), or room + 16 or
room - 16. `EXIT_SCREEN` ($C3B7): the new room into +$08; 4 in bits 4-7 of
+$0C (four turns of walking straight on with the controls and the walls
off); and, for the robot, the two return addresses dropped, both records
copied to `START_LEGS`/`START_TOP` ($CA1D, $CA3D) with the graphic moved to
+$10 and replaced by 56, the first of the appearing robot's, and a jump to
`MAIN_NEW_ROOM` ($A68B) to build the room
([`lives-and-starting.md`](lives-and-starting.md)).

**Arriving** (`ENTER_ROOM` $CAA2 builds, clears the buffer, fills the valve
records, then `ADJUST_PLYR_UVZ_FOR_ROOM_SIZE` with IX on the legs; L and H
are `ROOM_HALF_U` and `ROOM_HALF_V` less 2):

| Marker | Comes in at | New coordinate | The arch's U + V |
|---|---|---|---|
| U = 0 | high U | U = 128 + L + his U half-size | $38 |
| U = $FF | low U | U = 128 - L - his U half-size | $AE |
| V = 0 | high V | V = 128 + H + his V half-size | $52 |
| V = $FF | low V | V = 128 - H - his V half-size | $C8 |

U is tested first; with no marker nothing changes. Bit 4 (to be drawn) is
set in both records and the top gets the legs' U and V.
`ADJUST_PLYR_Z_FOR_ARCH` then looks at records 4, 6, 8 and 10 -- the first
pieces of the room's first four backgrounds -- for a first pillar whose U +
V (mod 256) is the arrival wall's, stopping at a graphic of 4 or more; the
match gives the legs its Z and the top Z + 12. The four values are the
pillars' own (141 + 197 = $52, 197 + 115 = $38, 141 + 59 = $C8, 59 + 115 =
$AE), and a raised doorway has the same U + V as the floor-level one in its
wall, so he arrives at its height.

**The grid.** Rooms are numbered row x 16 + column, 128 of the 256 numbers
used; the listing titles each room with its row and column.

## How this was found

Read against Knight Lore's `upd_3_5`, `adj_2_4_hflip`,
`chk_plyr_spec_near_arch`, `is_near_to`, `adj_ew`/`adj_ns`,
`handle_exit_screen`, `screen_east`/`north`/`south` (1.00), `exit_screen`
(0.67) and the arrival routines, and Pentagram's `SECOND_PILLAR`,
`FIRST_PILLAR`, `IS_NEAR_TO` (1.00), `NUDGE_ALONG_V`/`_U` (0.88/0.80)
(stage 2, ranges 3, 4 and 5). The backgrounds' pieces read from the
snapshot. *Measured* in stage 1: walking out of the start room $4E reached
$4F, $5E and $3E; stage 1's tour built every room.

## Confidence

*Read*, and run by every doorway the build's sessions walked. That a room's
doorways are always among its first four backgrounds is the code's
assumption; not checked room by room here (the world page's generator is
the place). `ADJUST_PLYR_Z_FOR_ARCH`'s RET after four misses ($CC89) never
ran.

## Knight Lore and Pentagram

Knight Lore's code throughout
([`../knightlore/arches.md`](../knightlore/arches.md),
[`../knightlore/leaving-a-room.md`](../knightlore/leaving-a-room.md)) --
the arrival's placement in the form Pentagram also has
(`ADJUST_PLYR_UVZ_FOR_ROOM_SIZE` matches Pentagram's at 1.00, Knight Lore's
at 0.58), the arch found Knight Lore's way (`check_next_arch`, 0.62) -- with
the walk into a room one turn longer (4 against 3), graphic 56 for Knight
Lore's appearing graphic, and the same four U + V constants but $52 for
Knight Lore's $51. Knight Lore's pillars are graphics 2 to 5 (its test is
"6 or more"), Alien 8's 2 and 3 ("4 or more"). Knight Lore checks and
nudges records 0 to 3; Alien 8 only the legs, and only while he faces
through. Pentagram decides the exit at the pillar and reads the next room
from a byte in the doorway's scenery entry, not from a grid
([`../pentagram/doorways-and-rooms.md`](../pentagram/doorways-and-rooms.md)).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `SECOND_PILLAR` (`SECOND_PILLAR_MIRRORED`) | `SUBBFD8` | $BFD8 | graphic 3 |
| `FIRST_PILLAR` (`ARCH_CHECK_DOORWAY`, `ARCH_ALONG_V`) | `SUBBFEA` | $BFEA | graphic 2 |
| `ARCH_NUDGE_TO_CENTRE`, `NUDGE_ROUTINES`, `NUDGE_ALONG_V`, `NUDGE_ALONG_U` (`NUDGE_DONE`) | `SUBC02C`, `DATAC048`, `SUBC050`, `SUBC069` | $C02C-$C069 | the nudge |
| `CHK_PLYR_NEAR_ARCH`, `IS_NEAR_TO` | `SUBC082`, `SUBC099` | $C082, $C099 | in the doorway; near a point |
| `HANDLE_EXIT_SCREEN`, `SCREEN_MOVE_TBL` | `SUBC36D`, `DATAC38F` | $C36D, $C38F | has he walked out? |
| `EXIT_LOW_U` (`EXIT_WITHIN_ROW`, `EXIT_SCREEN`), `EXIT_HIGH_U`, `EXIT_HIGH_V`, `EXIT_LOW_V` | `SUBC397`, `SUBC3F0`, `SUBC40B`, `SUBC426` | $C397-$C426 | the four exits |
| `ADJUST_PLYR_UVZ_FOR_ROOM_SIZE`, `ADJUST_PLYR_Z_FOR_ARCH` | `SUBCC01`, `SUBCC6D` | $CC01, $CC6D | arriving |

## Also found for the stage 3 pages (2026-09-28)

- The new life after a death walks in again: the start records are copied during the walk-in, so after appearing at the doorway he walks in by himself for about four turns (*measured*).
- Raised doorways (backgrounds 10 and 11, Z 112 -- 48 above the floor) stand only in the high-U and low-V walls, and always lead to a floor-level doorway; taking only floor-level doorways the station splits into 13 regions, every crossing a climb one way (*measured*, all 300 doorways walked).

## Open questions

- None of behaviour. The world page's generator can check every doorway for
  a partner and every room's doorways against the first-four assumption.
