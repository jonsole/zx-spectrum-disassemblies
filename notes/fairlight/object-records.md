# Object records

**Question this answers:** what an object record is, what each of its
twenty bytes means, and what the first seven records are.

**Short answer:** everything in a room -- the knight, the things he can
carry, creatures, doors, furniture and the invisible boxes that make steps
and raised floors -- is a twenty-byte record from $BC18: where its sprite
goes on the screen, the sprite, where it is in the room (a corner) and how
big it is, its kind (+12), its movement (+13 to +18) and its number in the
object table (+19). Records 1-6 (`FIXED_RECORDS`, $BC18) have no sprite:
they are the room's floor, ceiling and four walls, set per room by a patch
code. Record 7 is the knight (`KNIGHT`, $BC90); the room's own follow from
$BCA4 (`RECORDS`).

## How it works

**Axes.** The listing's convention, used in these notes: x is +6, y is +7
(the height -- +7 is the *top* of the object), z is +8. Y-P walks +x,
H-ENTER -x, Q-T +z, A-G -z. On the screen +x goes up and to the right, +z up
and to the left, +y straight up; greater x and z are further from the viewer
([`projection.md`](projection.md)). (Some of the listing's range-4 entries,
$F2F7, $F595, $F7B0, $F7BA, call +8 "y": the same axis.)

| Offset | What |
|---|---|
| +0, +1 | The sprite's screen x, and the row of its top (rows counted up from the bottom) |
| +2, +3 | The sprite's width in pixels and height in rows |
| +4, +5 | The sprite (image, then mask); 0 for records nothing draws |
| +6, +7, +8 | Where it is: x, the top (y), z |
| +9, +10, +11 | Its lengths from that corner: along x, down from the top, along z. It occupies +6 to +6 plus +9, +7 less +10 to +7, +8 to +8 plus +11 (`FAR_CORNER` $F036, `BOX_OVERLAP` $FCF2) |
| +12 | The kind byte (below) |
| +13 | Its direction (the byte below); a door's: the room behind it |
| +14 | Its state: the low nibble what it does each pass ([`object-states.md`](object-states.md)); bit 4 "moves by +13 this pass" (riding, just dropped, knocked); bits 5 and 6 which way it faces; bit 7 in the air. The listing's variables call the working copy `WORK_BEHAVIOUR`. A door's: the key |
| +15 | A countdown: passes to a change of course, to the end of a rise, a fall, a bounce, a sword's phase. A door's: the x the knight arrives at |
| +16 | 0: still -- never updated, drawn into the room's picture. Otherwise bits 0-4 are 16 plus its weight, and bit 5 is set while it is carried or once it has vanished. A door's: the top he arrives at |
| +17 | Animation: the frame (bits 0-2), the last frame (bits 3-5), bit 7 going back; state 9 counts its rising here. A door's: the way through |
| +18 | Its course: a chaser's chosen direction, the direction kept in the air, the knight's stance timer. A door's: the z he arrives at |
| +19 | Its number in the object table, counted from 1 (0 for the knight and for objects a room's drawing places) |

**The kind byte (+12).** The low nibble is the kind; the bits above are
flags ([`meeting.md`](meeting.md) has what each does when things meet):

| Value | Kind |
|---|---|
| 0 | Plain |
| 1 | A door: every eleven-byte record of the object table, and nothing else ([`doors.md`](doors.md)) |
| 2 | An invisible step climbed along z (twelve rooms: 53-55, 57-60, 64-67, 77) |
| 3 | An invisible step climbed along x (rooms 2, 27, 34) |
| 4 | Used: adds 10 to LIFE |
| 5 | Used: freezes the creatures until the next room |
| 6 | Used: LIFE to 99; also destroys a wraith it runs into |
| 7 | Kills at a touch: the floors of the pits in rooms 9 and 12 |
| 8 | A decoy: the guards of state 9 go after it and take it |
| 9 | Used: carries the knight off to room 30 |
| 10 | Destroys a wraith it runs into (type 21, rooms 48 and 57) |
| 11 | Its presence wakes the creature of room 61 and lets room 61's door work (thing 7, type 50: a book, by its picture) |
| bit 4 | Hurts what it touches (10 LIFE): the troll, the bouncing balls |
| bit 5 | Can be picked up |
| bit 6 | Can be killed by the knight's sword: the guards, the ghosts, the troll |
| bit 7 | A fighter: the knight and nearly every creature |

**The direction byte** (+13, +18, and `WORK_DIRECTION` IY+$71,
`ASKED_DIRECTION` IY+$7C, `RIDE_DIRECTION` IY+$7F while an object is
updated):

| Bit | Means |
|---|---|
| 0 | Turn back when stopped (a collision reverses the way rather than ending it) |
| 1 | Rising: no gravity this pass |
| 2, 3 | -x, +x |
| 4, 5 | Up, down (gravity adds 5) |
| 6, 7 | +z, -z |

**The fixed records** (`FIXED_RECORDS`, $BC18). No sprite (+4, +5 zero),
nothing in +16, huge lengths ($FF along the other two axes); the collision
search (`FIND_OBSTACLE`, $FCA5) tests every record in use down to record 1,
so these box the room in and hold everything up:

| Record | What | Patched field |
|---|---|---|
| 1 | The floor, 10 high | +7, its top: 50 in most rooms, 10 in rooms 9 and 12 (the pits) |
| 2 | The ceiling | +7 (120 to 230; 180 in most rooms) |
| 3, 4 | The walls across x, 10 thick, one at each end | +6 |
| 5, 6 | The walls across z | +8 |

A patch code ($E6-$F9) in a room's object list (or a part's) writes the six
bytes of its entry in `PATCHES` ($BA3E, six bytes a code from $E5) into
those six fields (`PATCH_RECORDS`, $E605). Every room the knight plays in
has one; rooms 1, 79 and 81 have none. Raised floors, steps and furniture
are the invisible boxes a room's drawing places (sprite 0) and are held up
and collided with in the same way ([`collision.md`](collision.md)).

**The knight's record** (`KNIGHT`, $BC90). Record 7. On the tape it is his
record at a new game; `START` copies it to the master copy, and `TELE`
($F09B) copies it back at each new game and when the thing of kind 9 carries
him off -- all but +14 (`KNIGHT_FLAGS`, $BC9E), whose bit 5 says which way
his frames in memory face now ([`turning-sprites.md`](turning-sprites.md)).
His +16 is 18 (weight 2) and +19 is 0.

**Records 8 up** (`RECORDS`, $BCA4, room for 43): the things carried
(copied in by `ROOMST`), then the room's entries in the object table, then
what the room's drawing places ([`entering-rooms.md`](entering-rooms.md),
[`object-table.md`](object-table.md)). `OBJECT_COUNT` ($FF80) counts the
records in use, the fixed seven included; `FREE_RECORD` ($FFB8) points at
the next.

While an object is updated, its first 19 bytes are copied to $FFE4-$FFF6
(the author's `T`, as in `(T+13)`), so IY+$64+n is field n: `WORK_KIND`
($FFF0) is +12, `WORK_DIRECTION` +13, `WORK_BEHAVIOUR` +14, `DRAW_WIDTH`
+15, `WORK_WEIGHT` +16, `WORK_ANIMATION` +17, `WORK_HEADING` +18
([`memory-map.md`](memory-map.md)).

## How this was found

Read across stage 2's five ranges, each from the code that reads the field;
the census -- every room 2-80 but 79 entered in turn in the simulator, every
record listed -- gave which kinds, states and flags exist and where. The
fixed records: read from `PATCH_RECORDS` and the patch table, then
*measured* by entering rooms 3, 45, 80 and 5 and reading $BC18-$BC8F
(record 3's +6: 188, 152, 80, 170; record 4's: 40, 40, 40, 44), and in room
29 (floor 50, ceiling 180, walls at x 40 and 178, z 40 and 174; the knight's
fall stopped with his feet at 50). The census found 19 distinct layouts.

## Confidence

The fields: *read*, and *measured* for +6-+8, +13, +14, +15, +17 and +18.
The corner-and-lengths box: *read* (`BOX_OVERLAP`) and *measured* (the
pick-up search found a thing 8 long from 2 behind to 10 ahead of the
knight's corner, the interval a corner and a length give; a centre and half
sizes would give -10 to 18). The fixed records as the room's box: *read*
and *measured*. The creature names are *inferred* from their pictures and
the author's MIWRAI and MITRO.

## Disassembly corrections

- Stage 1 had +9, +10, +11 as half-width, height, half-depth, and stage 2's
  range 2 said the same of the templates. They are lengths from the corner
  (*read* in `BOX_OVERLAP` and `FAR_CORNER`, *measured* by the pick-up
  search).
- Stage 1's open question -- what the six records at $BC18 are ("perhaps the
  room's walls") -- is answered: floor, ceiling and four walls.
- Stage 1 called +12's kinds 4, 5, 6 and 9 "things that do something when
  used" and said no more; the table above has every kind.

## Krumlinde

His collision notes read the sizes as half-extents about a centre; they are
lengths from a corner. He asks where floor heights come from and says
nothing makes things fall: record 1's +7, set per room by the patch, and
gravity, a direction bit forced on anything not rising
([`movement.md`](movement.md)). His `Room_PatchObjectTemplates` patches the
six fixed records, not six object-table entries.

## Open questions

- What the game calls the things of each kind: the object table has no
  names. The pictures are on the graphics pages.
