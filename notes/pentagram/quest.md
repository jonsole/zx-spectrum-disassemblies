# The quest

**Question this answers:** what has to be done to finish the game, and what
the code does between shooting the well and the winning screen.

**Short answer:** shoot a well (there are three, in rooms 29, 71 and 123)
until it puts out a bucket; carry
the bucket to each of the four quest items (rooms 122, 128, 17 and 33) and
put it down there, where it rises, flies over the item and turns it from a
rough stone into a finished pillar, with a life added. When all four are done
the pentagram's eight pieces appear in room 82; the five collectables,
carried there, glide to their places on it, and the fifth ends the game.

## How it works

The chain, by update routine (each run from `UPDATES` by its graphic):

```
WELL $CFD2 (graphic 120)
  BOLT_TOUCHING $CFB2        a bolt within two units? (HIT_TEST, in BOLT_HIT $C206)
  +$14 counts touching turns; on the 32nd -- with BUCKET_OUT clear, no bucket in
  the room and a free record -- a copy of the well's record becomes the bucket:
  graphic 90, Z 141, V + 8, flags $14 (mobile, drawn), linked to QUEST_BUCKET $D542
BUCKET $D0AC (graphic 90)
  +$14 bit 0 clear: fall 1 a turn; look for graphics 112-115 in the room
    (ROOM_OBJECT_LOOP $D071); found: +$15/+$16 = its U, V; set bit 0
  bit 0 set: HEAD_FOR_TARGET $D085 (one unit a turn in U and V), rising 1 a turn
    below Z 176, no fall; when it can move no more: bit 0 of the item's +$16,
    BUCKET_OUT cleared, TUNE_QUEST, its quest record emptied, a puff (START_PUFF)
QUEST_ITEM $CF68 (graphics 112-119)
  bit 0 of +$16: QUEST_DONE + 1, LIVES + 1 (DRAW_LIVES), graphic + 4 in the
  object and the quest record (CHANGE_GRAPHIC $CF9E), then ALL_FOUR_DONE $D13A
ALL_FOUR_DONE $D13A
  four quest records at 116-119? bit 4 on each piece (128-135), PENTAGRAM_ON $A70F;
  QUEST_INTO_ROOM brings the pieces into room 82 from then on
COLLECTABLE $CD16 (graphics 144-148)
  not room 82, or no pentagram: falls and can be pushed and carried (as PUSHABLE)
  room 82 and PENTAGRAM_ON: its place from TARGETS $D562 by graphic AND 7;
  glides one unit a turn without falling (HEAD_FOR_TARGET); there: graphic + 8
  (152-156, a still thing), PLACED + 1; the fifth: JP WON $C302
```

- **The well.** The count is kept in the well's own record, which is rebuilt
  from the room's data each time the room is entered, so the 32 turns must
  come in one visit. The first bolt slot counts a puff as touching (it enters
  the test past the puff check, at `HIT_TEST_Z` $C21E); the second does not
  (*read*). Three rooms have a well, graphic 120: 29, 71 and 123 (*read*
  from the data at build time by the world page's generator); any of them
  gives a bucket, one at a time. The build's session uses room 71's, which
  has no monsters and is ringed by still hazards; in its staged run the
  bucket came after four volleys of twelve shots (*measured*).
- **Carrying the bucket.** It can be picked up ([`carrying.md`](carrying.md))
  and, put down in a room with a quest item not yet done, finds it at once.
  In a well's room there is none, so it falls to the ground and waits. Only
  one bucket at a time: `BUCKET_OUT` ($A70E) stays set until it reaches an
  item, and then the well can give another.
- **The bucket triggers** when it can move no more -- above the item at the
  top of its rise, or stuck against something in every direction short of it
  (*read*; the second case not run).
- **The items** are the only quest things that stay where they are; a done
  item is out of the bucket's reach (it looks for 112-115 only).
- **The pentagram.** Its eight pieces live in room 82 from the start, in the
  quest records, but `QUEST_INTO_ROOM` leaves them out until `PENTAGRAM_ON`
  (*read*). They never move ([`movers.md`](movers.md)).
- **The collectables** start at five consecutive places of the twenty in
  `SPOTS` ($D1A5), the first chosen by `RANDOM` AND $3C from the first
  sixteen (`NEW_QUEST` $D16F), so a game's five are always neighbours in that
  list. They can be carried and dropped anywhere; only in room 82 with the
  pentagram showing do they glide home. `TARGETS` has no height: they glide at
  the height they have.
- **Winning** (`WON` $C302): the winning screen, which names the next game,
  then the game-over screen with the percentage ([`menu-and-panel.md`](menu-and-panel.md),
  [`percentage.md`](percentage.md)).
- Nothing falls from the sky in a room with the well, a quest item or a
  piece ([`bolts-and-sky.md`](bolts-and-sky.md)).

Where the state is kept: `BUCKET_OUT` $A70E, `PENTAGRAM_ON` $A70F, `PLACED`
$A74B, `QUEST_DONE` $A74C, and the 18 quest records ([`quest-records.md`](quest-records.md)).

## How this was found

Worked out in stage 1 by reading the code and then running the whole chain in
the build's staged session (*measured*, [`driving.md`](driving.md)): the
bucket after enough shots in room 71, the quest item in room 122 going from
112 to 116 with a life added, `QUEST_DONE` and `PENTAGRAM_ON`, and with the
collectables moved into room 82 near their places, `PLACED` reaching 5, the
win, the game-over screen (36 per cent in that run) and the menu. Read
routine by routine in stage 2 (range 5). The sprites of graphics 112 (a
rough, pointed stone), 116 (a finished pillar), 90 (the bucket) and 120 (the
well) were looked at in the build's pictures before naming.

## Confidence

The chain: *measured* and *read*. The 32 touching turns and the count lost on
leaving: *read* (the compare with 32 at $CFE7; the builder rebuilds the
record). The bolt slots' difference: *read* (found by two agents
independently).

## Knight Lore

Nothing here matches Knight Lore's code closely (`kl_matches.txt` has no
match above 0.40 for `WELL`, `BUCKET`, `ALL_FOUR_DONE`, `NEW_QUEST`,
`COLLECTABLE`); the cauldron and its wanted charms are Knight Lore's
equivalent, built another way ([`../knightlore/winning.md`](../knightlore/winning.md)).
A quest table carried from room to room is new in Pentagram.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `CHANGE_GRAPHIC` | `SUBCF9E` | $CF9E | a new graphic in the quest record and the object |
| `BOLT_TOUCHING` | `SUBCFB2` | $CFB2 | is a bolt within two units? |
| `ROOM_OBJECT_LOOP` | `SUBD071` | $D071 | set up a walk through the 48 room records |
| `QUEST_RECORD_LOOP` | `SUBD07B` | $D07B | the same for the 18 quest records |
| `HEAD_FOR_TARGET` | `SUBD085` | $D085 | one unit a turn towards +$15/+$16 |

## Open questions

- `ALL_FOUR_DONE` sets bit 0 of +$11 of the quest item that called it -- the
  high byte of its quest-record link, pointing it 256 bytes on. Only a
  carried thing's link is followed, and quest items cannot be picked up, so it
  seems to do nothing. A slip for another offset? Not settled.
