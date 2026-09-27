# The world

**Question this answers:** what the game's world is like as a whole -- how
many rooms, what shapes, how they fit together, and where the things that
matter are.

**Short answer:** 139 rooms, numbered 0-149 with eleven numbers unused, in
three sizes; linked by 290 doorways, every one answered by a doorway back.
Laid out by their doorways they make one grid of 19 columns by 18 rows, with
three small groups overlapping others -- a map that could not be built in
real space. The game starts in one of four rooms; three rooms have a well,
four the quest items, one the pentagram; 92 rooms have something deadly in
them from their first turn.

## How it works

Everything here is *read* from the level data at build time, by the world
page's module (`scripts/pentagram_world.py`, stage 3), the counts checked by
the lead, unless it says otherwise.

- **Rooms**: 139 records in the directory ([`room-building.md`](room-building.md)).
  Sizes: 116 are 128 by 128 units, 13 and 10 are narrow (64 by 128, 128 by
  64); all 23 narrow rooms are corridors with a doorway at each end.
- **Doorways**: 290, from the scenery templates 0-7 and 24-27 (the wall is
  the template number AND 3), each with its destination byte; every one has a
  partner in the opposite wall of the room it leads to, and every one is
  among its room's first four scenery entries. 20 are raised, each with a
  partner at floor level. All 290 were walked through with the game's own
  code (*measured*): see [`doorways-and-rooms.md`](doorways-and-rooms.md).
- **The layout**: placing each room one square from the room its doorway
  leads to gives a grid of 19 columns by 18 rows in which every loop closes --
  except that rooms 139-144 fall on the same squares as 39-41 and 55-57,
  145-146 on those of 87-88, and 148 on that of 3. Those groups are reached
  only through their own doorways, so the world is consistent room to room
  but not as a single plan (*inferred* from the overlaps).
- **Where things are**: the start rooms 51, 92, 100 and 12 (`START_ROOMS`
  $C2E8, [`lives-and-starting.md`](lives-and-starting.md)); wells in 29, 71
  and 123; the quest items in 122, 128, 17 and 33; the pentagram in 82
  ([`quest.md`](quest.md)); the collectables start in five neighbouring
  places of `SPOTS` ($D1A5), chosen at random each game.
- **Dangers**: the graphics deadly after a room's first turn -- set so by their
  update routines through `MAKE_DEADLY` -- are 16-17 (the straight-running
  spider), 23, 30, 74-75 (still hazards), 28 (spikes), 86 (the bobbing
  head), 89 (the scuttling spider) and 92-93 (the pacing heads); 92 rooms
  have at least one (*measured* at build time: each room run for a turn and
  its records' kill bits read). The creatures that fall from the sky (80-81, 168-171) are
  deadly too, but are never in a room's data; homers are not
  ([`bolts-and-sky.md`](bolts-and-sky.md), [`movers.md`](movers.md)).
- **Where nothing falls**: rooms with a well, a quest item or a piece of the
  pentagram (`BAN_DROPS`).

## How this was found

The world page's module reads the directory and templates from the snapshot
at build time, places the rooms by their doorways, draws each with the
game's own drawing code, and runs the doorway walk in the simulator; the
lead checked its counts and reported them for these notes (stage 3). The
dangers are the graphics whose update routines call `MAKE_DEADLY`
([`graphic-numbers.md`](graphic-numbers.md)), found in the rooms after one
turn of each.

## Confidence

*Read* from the data at build time; the doorway walk and the dangers
*measured*. The layout's
three overlaps are a fact of the data; that the designers meant them is
*inferred*.

## Knight Lore

Knight Lore's 128 rooms sit on a 16 by 16 grid by their numbers, and its
exits are arithmetic on the number; Pentagram's numbers say nothing about
position, and its map is the doorway bytes
([`../knightlore/room-format.md`](../knightlore/room-format.md)).

## Open questions

- Why room 38's north doorway and room 78's west need a jump.
