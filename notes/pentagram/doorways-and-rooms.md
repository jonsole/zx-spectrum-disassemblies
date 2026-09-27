# Doorways: leaving one room and arriving in the next

**Question this answers:** how the player leaves a room, how the game knows
which room is next, and where he appears in it.

**Short answer:** through an arch only. The first pillar of each arch
(graphics 6 and 8, `FIRST_PILLAR` $C7AD) works out the arch's middle, lets
the player's legs past the wall line while they are in its doorway, and when
they are wholly past the wall they face, sends him to the room stored in the
pillar's own +$08 -- the byte after the doorway's scenery entry, not a step on
a grid. U or V is set to a 0/$FF marker; once the new room is built
`ADJUST_PLYR_UVZ_FOR_ROOM_SIZE` ($CA82) puts him in the doorway of the
opposite wall, lined up with that arch. His records are copied to
`PLAYER_TEMPLATE` at every exit, so a life lost restarts at that doorway.

## How it works

```
FIRST_PILLAR $C7AD              graphic 6/8: offset; the arch's middle -> its own +$09..+$0B
  HANDLE_EXIT_SCREEN $C802      record 0 only, graphic 16-47, +$07 bit 3
    IS_NEAR_TO $C8AD            |d| < L in U, < H in V, < 4 in Z
    set +$07 bit 0 (in the doorway)     -> the wall tests let him past
    SCREEN_MOVE_TBL $C83B by facing
      EXIT_LOW_U $C843 / EXIT_HIGH_U $C874 / EXIT_HIGH_V $C887 / EXIT_LOW_V $C89A
        wholly past the wall? marker 0/$FF -> EXIT_SCREEN $C854:
          PLAYER_ROOM = the pillar's +$08; +$0C |= $30 (3 turns' walk in)
          legs and body -> PLAYER_TEMPLATE; drop 2 returns; JP GAME_LOOP $AFC8
  ARCH_NUDGE_TO_CENTRE $C8D2    within 15/15/4: +/-1 into +$0E or +$0F
    ROUTINES_BIT3_SET / ROUTINES_BIT3_CLEAR $C8F7 by graphic bit 3 and facing
      NUDGE_ALONG_U $C91A / NUDGE_ALONG_V $C907
SECOND_PILLAR $C789             graphic 7/9: the drawing offset only
```

**The arches** (read from the scenery templates and the code):

| Arch | Pillars | Mirrored | Middle | Doorway reach (U, V) | Nudge |
|---|---|---|---|---|---|
| in a wall of constant U (U 59 or 197) | 13 apart along V | no | U = pillar, V = pillar + 13 | 15, 6 | along V |
| in a wall of constant V (V 59 or 197) | 13 apart along U | yes | U = pillar - 13, V = pillar | 6, 15 | along U |

Graphics 8 and 9 make an arch too, and the raised doorways at Z 176. The
middle is kept in the pillar's step fields because `IS_NEAR_TO` compares
+$09..+$0B of one record with +$01..+$03 of another.

**Leaving.** Only the player's legs (record 0), with a graphic of 16-47 --
which leaves out the puff he becomes when he dies -- and bit 3 of +$07 set.
In the doorway, bit 0 of +$07 is set; while it is, the collision code lets
him past the line of the wall, and `PLAYER_LEGS` clears it at the end of his
next update. Then the exit for the way he faces compares his position after
his move with the wall at 128 +/- the room's half-size (`ROOM_EXTENT`): at low
U his far edge (U + half-size) must be below it, at high U his near edge (U -
half-size) at or past it, and likewise in V. Markers: out at low U, U = 0,
arrive at high U; out at high U, $FF, arrive at low U; high V, V = $FF,
arrive at low V; low V, V = 0, arrive at high V. `EXIT_SCREEN` gives him 3
turns of walking on by himself (the top nibble of +$0C), during which the
controls do nothing and the walls are off.

**Arriving** (`ADJUST_PLYR_UVZ_FOR_ROOM_SIZE`, from `ENTER_ROOM`): the marked
coordinate becomes 128 +/- (the room's half-size + his half-size - 2), his
inner edge 2 inside the wall's line. `FIND_ENTRY_ARCH` ($CAEE) walks the
second record of each of the room's first four scenery entries (from
`ROOM_SECOND`, $ADEF, down 64 at a time) while they are arch pieces (6-9),
and takes the one in the wall he comes in by (U or V of 192 or more for the
high wall, below 64 for the low); `ALIGN_V_TO_ARCH` ($CB15) or
`ALIGN_U_TO_ARCH` ($CB29) set the other coordinate to the arch's middle and Z
to the pillar's base, the body 12 above. With no marker -- a new game, or a
life restarted where it began -- nothing is done.

**The map is a table, not a grid.** Each doorway's destination is the byte
after its scenery entry in the room's record ([`room-building.md`](room-building.md)).
The start rooms' doorways lead 51 to 50, 52, 63; 92 to 91, 93, 107; 100 to
99, 101, 110; 12 to 11, 13, 22 (*measured*): the steps in V differ, so room
numbers are not a fixed grid. The doorways are the scenery templates 0-7 and
24-27, the wall being the template number AND 3; there are 290 of them, and
every one has a partner in the opposite wall of the room it leads to (*read*
from the data at build time by the world page's generator, and the counts
checked by the lead). Every doorway is among its room's first four scenery
entries, which is what `FIND_ENTRY_ARCH` assumes (*read*, all 139 rooms).
Laid out by their doorways the rooms make one grid of 19 columns by 18 rows
in which every loop closes, except three groups that share squares with
others -- rooms 139-144 with 39-41 and 55-57, 145-146 with 87-88, and 148
with 3 ([`world.md`](world.md)).

**All 290 walked** (*measured*, at build time by the world page's module):
the player was put in front of each doorway and walked through with the
game's own code, and arrived in the named room every time. 268 of the 270 at
floor level go straight through; the other two -- room 38's north doorway and
room 78's west -- need a jump. All 20 raised doorways work from the ledge,
and each raised doorway's partner is at floor level.

## How this was found

Read against Knight Lore's arches, exits and arrival (its $C73C-$C822,
$CA70-$CB44 and $D320), stage 2, range 4. Run in SkoolKit's simulator
(*measured*):

- `ENTER_ROOM` for each start room (51, 92, 100, 12) with each marker: he
  arrived at U 195 or 61, or V 195 or 61 (room half-size 64, his 5), lined up
  at 128 and Z 128, the body at Z 140.
- Room 51's pillar at U 197, V 115 (not mirrored), the legs at U 198, V 128,
  Z 128: facing 1 (graphic 36, mirrored) left for room 52 with U = $FF, +$0C =
  $30, and `PLAYER_TEMPLATE` holding room 52 and U $FF; facing 0 or 3, or U
  190, stayed, with bit 0 of +$07 set.

## Confidence

Exit and arrival *measured* for the cases above, and every doorway in the
game walked through at build time (*measured*). That a room's doorways are
among its first four scenery entries is the code's assumption, and the data
bears it out in all 139 rooms (*read*).

## Knight Lore

([`../knightlore/leaving-a-room.md`](../knightlore/leaving-a-room.md),
[`../knightlore/arches.md`](../knightlore/arches.md))

- Knight Lore's arch marks the player as in the doorway and nudges him; his
  own move decides the exit (`handle_exit_screen`), from his position plus
  the step, and the new room is the old one plus or minus 1 or 16 on a 16 by
  16 grid. Pentagram's pillar decides the exit itself, from the position after
  the move, and the new room is the pillar's +$08.
- Knight Lore checks the player's records 0-3; Pentagram only record 0, and
  only graphics 16-47.
- Knight Lore turns the respawn copies into a materialising sparkle;
  Pentagram copies the records as they are.
- The nudge tables: Knight Lore indexes by the arch's facing; Pentagram has
  two tables because its two first-pillar graphics differ in bits 2 and 3, and
  only half of each table is ever used (`ROUTINES_BIT3_SET`).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `SECOND_PILLAR` | `SUBC789` | $C789 | graphics 7, 9: offset only |
| `FIRST_PILLAR_EIGHT` | `SUBC7A8` | $C7A8 | graphic 8's offset, then on |
| `FIRST_PILLAR` | `SUBC7AD` | $C7AD | graphics 6, 8: the doorway |
| `ARCH_ALONG_U`, `ARCH_CHECK_DOORWAY`, `ARCH_ALONG_V` | (entry points) | $C7BD, $C7D1, $C7E7 | its parts |
| `HANDLE_EXIT_SCREEN` | `SUBC802` | $C802 | in the doorway? out? |
| `SCREEN_MOVE_TBL` | `DATAC83B` | $C83B | the four exits (now words) |
| `EXIT_LOW_U` ... `EXIT_LOW_V` | `SUBC843` ... `SUBC89A` | $C843-$C89A | the four walls |
| `EXIT_SCREEN` | (entry point) | $C854 | go to the next room |
| `IS_NEAR_TO` | `SUBC8AD` | $C8AD | as Knight Lore's |
| `ARCH_NUDGE_TO_CENTRE` | `SUBC8D2` | $C8D2 | the nudge |
| `NUDGE_ALONG_V`, `NUDGE_ALONG_U` | `SUBC907`, `SUBC91A` | | |
| `ADJUST_PLYR_UVZ_FOR_ROOM_SIZE` | `SUBCA82` | $CA82 | arrive in the doorway |
| `FIND_ENTRY_ARCH` | `SUBCAEE` | $CAEE | find the arch he comes in by |
| `ARCH_AT_LOW_V`, `NEXT_ARCH` | (entry points) | $CB09, $CB10 | |
| `ALIGN_V_TO_ARCH`, `ALIGN_Z_TO_ARCH`, `ALIGN_U_TO_ARCH` | `SUBCB15`, (entry), `SUBCB29` | $CB15, $CB1D, $CB29 | |
| `ARCH_AT_HIGH_U`, `ARCH_AT_LOW_U`, `ARCH_AT_HIGH_V` | `SUBCB33`, `SUBCB3C`, `SUBCB45` | | |

`ROUTINES_BIT3_SET` and `ROUTINES_BIT3_CLEAR` ($C8F7, $C8FF) kept their stage
1 names.

## Disassembly corrections

- `PLAYER_TEMPLATE` was "the player, as a life starts": it is rewritten at
  every doorway, which is why a life restarts where he came in.

## Also found for the stage 3 pages (2026-09-27)

- Every doorway is two-way and lines up with an arch straight back; arches stand only at 59 or 197, and narrow rooms have them only at the ends of their long axis (*measured*, all 290 followed through `ENTER_ROOM`).
- `PLAYER_TEMPLATE` keeps the exit marker, not a position: after an exit it held room 110 with V $FF, so a restart re-runs the arrival code (*measured*).

## Open questions

- What graphics 6/7 and 8/9 look like -- two kinds of arch; draw them (the
  Scenery page) before naming them further.
- Why room 38's north doorway and room 78's west need a jump to get through
  (*measured*; not yet explained from what stands in them).

Settled at stage 3: one-way doorways. The remake's survey, and stage 2's
generator, had 288 of 289 doorways answered by one back; both treated a
destination of 0 as "no doorway", missing room 147's south doorway, which
leads to room 0. Tested by template instead, all 290 are answered (the lead
fixed the generator).
