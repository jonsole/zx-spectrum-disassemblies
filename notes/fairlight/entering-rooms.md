# Entering and leaving a room

**Question this answers:** what happens between one room and the next --
what is saved on the way out, what is set up on the way in -- and where the
main loop runs.

**Short answer:** on the way out, `SAVE_OBJECT_POSITIONS` ($F906, the
author's EEN) writes each movable thing's place back into the object table
(and turns a troll's or wraith's shared frames back). On the way in,
`ROOMST` ($FD20, the author's name) moves the carried things' records up
behind the knight's, draws the room (which makes its objects' records),
sets the strike counters, draws the still things and doors into the picture
(`DRAW_STILL_THINGS`, $FE15) and falls into the main loop -- which runs
*inside* `ROOMST` until the game ends. Room 81 is the end of the quest.

## How it works

**EEN** (`SAVE_OBJECT_POSITIONS`, $F906): for each record after the
knight's, up to the first door, copy +6 to +8 into bytes 3-5 of the object
table's entry numbered at +19. The records after the knight's are the
things carried and then the table's things for this room in the table's
order, which lists a room's movable things before its doors and its still
ones ("STATIC OBJ" in the author's source) after them, so only what can move
is saved. A troll's or wraith's frames that are turned (+14 bit 5) are
turned back ([`turning-sprites.md`](turning-sprites.md)). Called at a door
($F900), by the kind-9 thing ($FEB0) and after a game ends ($F0AF).

**`ROOMST`** ($FD20):

- **Room 0:** return at once. Nothing gives it: a new game's room comes
  from the master copy, where it is 29.
- **Room 81:** the end of the quest ([`quest.md`](quest.md)): its picture,
  the verdict, `MESS2`'s two lines, a key, and back to GAME OVER.
- **Any other room**, at `LOAD_ROOM` ($FD9C, the author's ROS):
  `OBJECT_COUNT` = 7; for each of the five places (the author's OBJD to OB2,
  with IY stepped by two so that IY+$1F and IY+$20 walk `CARRIED`), the
  place is pointed at its record's new home, from $BCA4 up, and the record
  copied there by way of `BUFFER_D900` (one record may be moved onto
  another still to be copied), through the pointer at `POINT` ($FFE4, the
  author's `(T)`); one more record each. `FREE_RECORD` = the next home. IY
  back; the room drawn (`DRAW_CURRENT_ROOM`, which places the table's
  things, [`object-table.md`](object-table.md)); `STRIKES_LEFT` = 4 each;
  LIFE's label printed; the bare room copied to the clean copy (`RESTOR`).
- **`DRAW_STILL_THINGS`** ($FE15): each door, and each record whose +16 low
  bits are zero (never updated), drawn once with bit 4 of `GAME_FLAGS` set;
  then the screen copied to the clean copy again, so they are background
  ([`drawing-objects.md`](drawing-objects.md)). `THINGS_NOTED` = 0,
  `GAME_FLAGS` = 5 (LIFE to print, the room's first pass; the freeze off);
  into the main loop at its keys ($FE71).

The room is drawn black on black; after its first pass the main loop
colours it all at once ([`main-loop.md`](main-loop.md)). The records end up
in this order: the knight, the things carried, the table's things, the
doors, the table's still things, then what the room's drawing places.

**The stack.** `ROOMST` is called once, from `TELE` ($F0AC). A door
(`GO_THROUGH_DOOR`, $F8EC) drops what the main loop pushed and jumps back
in; the kind-9 thing drops the return to $F0AF and jumps to `TELE`, which
calls it again. The main loop returns from it with a `RET` -- LIFE 0, or
SYMBOL SHIFT and 0 -- to `TITLE_SCREEN` for GAME OVER
([`game-cycle.md`](game-cycle.md)).

## How this was found

Read (stage 2, range 5); the author's source text on the tape ($D135-$D2EF)
is the source of `LOAD_ROOM`'s loop line by line (ROS, OBJD, OB2, `DATLEN`,
`(T)`, `(V)`), and of the heading STATIC OBJ in the object table's source
at $BCA4 ([`symbols.md`](symbols.md)). *Measured*: in room 20 a thing's +6
and +8 changed and LIFE set to 0; after $F906 its table entry held the new
values. The record order seen in rooms 2, 9, 20, 28 and 29.

## Confidence

*Read*, with EEN's direction *measured*. That every room has a door, so the
walk never stops at the last record in use: *measured* by coverage only
($F958 never ran).

## Krumlinde

- `RTN_Refresh_Shape_Data` ($F906) is described as copying three bytes from
  the table into each record's +6 to +8. It copies the other way
  (*measured*). His "sentinel" kind 1 is the first door.
- `RTN_Load_Room_Objects` ($FD9C) is described as walking a linked list of
  room object definitions with a next pointer at +$1F/+$20. It walks the
  five carried places ($FF9F, reached as IY+$1F with IY stepping); the
  room's objects are made by `DRAW_CURRENT_ROOM` and `PLACE_ROOM_OBJECTS`.
- His note that the restart reaches `RTN_Enter_Room_By_Id` with room 0: no
  path does.
- He treats the main loop as having no exit; it returns from `ROOMST`.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `SAVE_OBJECT_POSITIONS` | `SUBF906` | $F906 | The author's EEN |
| `ROOMST` | `SUBFD20` | $FD20 | The author's name kept |
| `LOAD_ROOM` | (inside) | $FD9C | The author's ROS |
| `DRAW_STILL_THINGS` | `SUBFE15` | $FE15 | Still things and doors into the picture |

## Open questions

- EEN would write a wrong entry if it met a record numbered 0 before a
  door (a room-drawn object ahead of the table's). The room codes place the
  table's things first (`$E4 $04`/`$05` set the mode that allows drawn
  objects), so a drawn object lies after the doors and is never reached
  (*inferred*). But a *carried* record comes first, and room 19's two
  things, numbered 0, can be carried: EEN would then count 256 entries on
  from $A921 and write the thing's x, top and z over the destination room,
  the key and the arrival x of the object table's record 214 (the door from
  room 25 to room 21). *Read* from $F919-$F94E, not run
  ([`carrying.md`](carrying.md), [`bugs.md`](bugs.md)).
