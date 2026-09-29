# Doors

**Question this answers:** how the knight goes through a door, what locks
one, and where he arrives.

**Short answer:** every eleven-byte record of the object table is a door
(174 of them, kind 1). Walking into one the way its +17 says, holding its
key if +14 names one, and fitting within its span, takes him to the room in
+13, at a place worked out from +15, +16 and +18 -- unless a thing already
stands there in that room (BLOCKED). A door stops anyone but the knight,
like a wall. Twelve doors are holes, gone through by falling or by jumping.

## How it works

A door's record: +13 the room behind, +14 the key (a thing's number in the
object table, 0 for none), +15 the x he arrives at, +16 the top, +17 the
direction bits of the way through, +18 the z. The six bytes come from the
object table ([`object-table.md`](object-table.md)).

`BUMPED` ($F7C4) is reached from `TRY_STEP` when the step meets a record:

1. **Not a door:** `OBJECTS_MEET` ([`meeting.md`](meeting.md)). A door
   stops everything but the knight.
2. **The key:** +14 against the number (+19) of the thing in the place in
   use; no match is LOCKED (message 2). An empty place reads a record at
   address 0, whose +19 is a ROM byte ($FF), which matches nothing. 21 doors
   need a key; the keys are things 1-8 of the object table -- six of type 14
   (things 1-4, 6 and 8), thing 5 (type 15, the one the quest asks for) and
   thing 7 (type 50, kind 11) (*compared*: the table walked).
3. **The way** (`DOOR_WAY`, $F7FF): +17 AND `ASKED_DIRECTION` (IY+$7C, the
   direction asked this pass). Doorways are one of x or z (162 doors: 44 +x,
   45 -x, 36 +z, 37 -z); holes are down (7) or up (5).
4. **Room 61:** its one door (a hole down to room 60) also needs bit 1 of
   `THINGS_NOTED`: the kind-11 thing lying in the room. The door up into 61
   from 60 needs that thing as its key.
5. **The arrival** (`DOOR_ARRIVAL`, $F817): through a doorway along z, he
   must be within the door's width, x is carried across from +15 and z is
   +18 (less his length going -z); along x the same, transposed; doorways
   also need his height within the door's and carry it across relative to
   +16. Holes carry x and z across and set the top to +16 (plus his height
   going up, $F85D).
6. **The far side** (`ARRIVAL_CHECK`, $F89E): each of the first 163 object
   table records lying in that room, made into a box at `ARRIVAL_BOX`
   ($FFCB) from its saved place and its template's lengths, is tested
   against his arrival box; one there is BLOCKED (message 1) unless its +12
   has bit 4 (only the trolls). `ARRIVAL_BOX` points IX so that a record's
   +5 to +11 are `PRINT_X` and the six bytes after it.
7. **Through** (`GO_THROUGH_DOOR`, $F8EC): `ROOM` = +13, the main loop's two
   stacked words dropped, the knight moved to where he arrives, the room's
   things saved (`SAVE_OBJECT_POSITIONS`, $F906), and `ROOMST` ($FD20)
   entered, which goes back to the main loop
   ([`entering-rooms.md`](entering-rooms.md)).

## How this was found

Read (stage 2, range 4). The doors tabulated from the object table in the
simulator (their ways, keys and holes); room 29's door to room 30 walked
through (*measured*: he arrived at 50, 78, 164, as worked out from the
record); room 61 staged with and without the book; a thing staged at an
arrival point.

## Confidence

*Measured* for doorways along z, holes going down, room 61, and BLOCKED on
arrival -- thing 1 moved to room 30 at the arrival point: BLOCKED; with bit
4 set in its +12: through. That exercised $F8DD-$F8E9, which the build's
sessions never reach. Going up through a hole ($F85D) is *read* only.

## Krumlinde

His `RTN_Check_Door_Keys` sits at $F7FF, but the key test is before it
($F7DA-$F7F6); from $F7FF on it checks the way and room 61. At $F803 he has
`DB $FD`, a label, `AND (HL)` and `LD A,H`: the instruction is `AND
(IY+$7C)`. He leaves the second BLOCKED ($F8E3) unresolved ("possibly a
hidden-passage or hint-item check"): it is the arrival spot in the next
room being taken. His `RTN_Trigger_Room_Change`'s "plausibly a door's
destination-room field" is right: +13.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `BUMPED` | `SUBF7C4` | $F7C4 | What is in the way: a door, or a meeting |
| `DOOR_WAY` | (inside) | $F7FF | Krumlinde's `RTN_Check_Door_Keys` |
| `DOOR_ARRIVAL` | (inside) | $F817 | Where he arrives |
| `ARRIVAL_CHECK` | (inside) | $F89E | Is the far side free? |
| `GO_THROUGH_DOOR` | (inside) | $F8EC | Krumlinde's `RTN_Trigger_Room_Change` |
| `ARRIVAL_BOX` | `VARFFCB` | $FFCB | IX base for the far side's boxes |

## Open questions

- Going up through a hole ($F85D) has not been run.
