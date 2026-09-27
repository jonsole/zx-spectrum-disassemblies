# Quest records: how the quest's things remember where they are

**Question this answers:** how the 18 quest things -- four quest items, five
collectables, eight pieces of the pentagram and the bucket -- which are not in
the room directory, get into a room, and how they are found again where they
were left.

**Short answer:** they live in 18 records of 16 bytes at `QUEST_RECORDS`
($D432), each the first half of an object record with its room at +8. On
entering a room, `QUEST_OUT_OF_ROOM` ($B115) first copies each one in the old
room's object records back to its quest record, matched by graphic; after the
new room is built, `QUEST_INTO_ROOM` ($B097) copies each one whose room
matches into the lowest free object record, lifting it 12 at a time until it
overlaps nothing.

## How it works

| Record | Address | Graphic | What |
|---|---|---|---|
| 0-3 | $D432 | 112-115, then 116-119 | the quest items, rough then done, in rooms 122, 128, 17, 33 |
| 4-8 | $D472 (`QUEST_COLLECTABLES`) | 148-144, then 156-152 | the collectables, placed at random from `SPOTS` |
| 9-16 | $D4C2 | 128-135 | the pentagram's pieces, room 82, Z 127, height 0 |
| 17 | $D542 (`QUEST_BUCKET`) | 90 or 0 | the bucket, while it exists |

A record with graphic 0 is in no room. The block is 304 bytes, nineteen
records; the last 16 bytes nothing reads or writes. `QUEST_START` ($D312) is
the same eighteen as a game starts; `NEW_QUEST` ($D16F) copies it over and
places the collectables, so the rooms and positions of records 4-8 in
`QUEST_START` are never used (*read*; the rooms of 0-3 and 9-16 *read* from
the data).

- **Out** (`QUEST_OUT_OF_ROOM`, the first thing `GAME_LOOP` does, before the
  new room overwrites the records -- on a death too): for each of the room's
  48 records, its graphic is looked for among the quest records' (+0); on a
  match, the object's first 16 bytes -- where it is, its sizes, its flags, its
  room -- go over the quest record. So a quest thing pushed or dropped in a room
  is found there again.
- **The match is by graphic**, not by the link at +$10: each quest thing's
  graphic is unique, and `CHANGE_GRAPHIC` ($CF9E) changes the quest record's
  graphic with the object's when an item is done or a collectable placed. A
  carried thing's quest record has graphic 0 (`PICK_UP`), so an empty object
  record matches it and its leftovers are copied over it. Harmless: the
  graphic stays 0, `QUEST_INTO_ROOM` skips graphic 0, and putting the thing
  down writes the graphic back through the link (*read*, not run).
- **In** (`QUEST_INTO_ROOM`): IY starts 16 bytes before the records (the loop
  adds first); for each of the 18 with a graphic and +8 equal to his room:
  the lowest empty record from `ROOM_OBJECTS` ($A82F) (none: give up on all
  the rest); pieces (graphic AND $F8 = $80) skipped until `PENTAGRAM_ON`; bit
  4 set in the quest record; 16 bytes copied; +$10/+$11 = the quest record's
  address; +$12 to +$1F zeroed. Then, except for a piece,
  `DO_ANY_OBJS_INTERSECT` tests it against all 54 records and it is raised by
  12 in Z until clear, so it stands on whatever it was left on top of.
- The room builder fills from the top down and the quest things go in from
  the bottom up, so they share the 48 records; nothing checks the total.

## How this was found

Read (stage 2, range 1), then run in SkoolKit's simulator (the build's
`Machine`, keyboard start): quest record 0 (graphic 112) was poked into room
100 at U 184, V 152, Z 128, where a hazard stands, and the game restarted
into room 100. It came in at record 6 ($A82F, the lowest free) with Z 140 and
its link at +$10 = $D432; the lift at $B107-$B110 ran, which it never had in
the build's sessions. Its V was then poked to 150 and the game restarted into
room 51: quest record 0 read back U 184, V 150, Z 140, room 100, flags 0 (bit
4 cleared by being drawn).

## Confidence

*Measured* for the lift and the copy back; *read* for the carried-thing
match.

## Knight Lore

No close match (0.21 for `QUEST_OUT_OF_ROOM`, none above 0.40 for
`QUEST_INTO_ROOM`). Knight Lore's charms are placed by a per-room table and
two special-object records ([`../knightlore/special-objects.md`](../knightlore/special-objects.md));
persistent records with a room byte are Pentagram's own.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `QUEST_OUT_OF_ROOM` | `SUBB115` | $B115 | copy the room's quest things back |

## Open questions

- Why nineteen record slots at $D432 when eighteen are used.
