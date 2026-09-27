# Locations and the map

**Question this answers:** how a place is stored, how its exits work, how
moving and describing a place work, and what the map as a whole is like.

**Short answer:** 79 locations (1-79; 0 is a placeholder), each a 10-byte
head -- lit or dark, visited, how the player stands there, capacity, a
name of up to three words, a description -- followed by three-byte exits:
a direction, an object the way goes through (a door, a river, a web) or 0,
and a destination. `MOVE` walks anybody along them. The map is not a grid:
42 of its 205 exits are one-way, and a few places send every direction to
the same room.

## How it works

**`ROOM_POINTERS`** ($B9E0) holds a pointer per location 0-79; `GET_ROOM`
($9BB1) indexes it directly (no search), and anything from $50 up is not a
location (*read*). The records are `ROOM0`-`ROOM79`, $BA8A-$C062, each
ending where the next begins, the last at `OBJECT_INDEX` (the build checks
this).

The record (*read*; the build's `room_records` and `check_rooms`):

| Offset | Field |
|---|---|
| 0 | bit 7 lit; bit 6 visited (`MOVE` sets it); bits 1-3 how the player is placed there (`ROOM_PREPOSITIONS`) |
| 1 | capacity: how much it holds; $FF no limit |
| 2-7 | the name: a noun and two adjectives, word references, as an object's name is |
| 8-9 | a longer description (a message), or 0 |
| 10- | exits, three bytes each, to $FF |

**How the player stands there** (`ROOM_PREPOSITIONS` $BA80): IN for 48
rooms, ON for 20, AT for 9, INSIDE and OUTSIDE for the two sides of the
goblins' gate (19, 20) (*read*, counted from the records). `DESCRIBE_ROOM`
writes the word into the opening message (`MSG_IN_SLOT`) before printing it.

**Exits** (*read*):

- **Direction** 1-10 is north, south, east, west, northeast, northwest,
  southeast, southwest, up, down -- the order of `DIRECTION_WORDS` ($A210),
  and the same numbers as the action codes, so a direction command's code is
  its exit direction.
- **Through**: 0 for an open way, or an object: 38 exits go through one.
  `CAN_PASS` ($8E85) lets an actor through only if the object is open (flag
  bit 5) or broken (bit 3), the actor with all it carries fits the object's
  size, and -- for any exit -- the room beyond has room (`ROOM_LEFT`:
  capacity less the sizes of what is only there). The window never lets
  the player through (bit 7 of its byte 4).
- **Destination** 0 means "nowhere yet": `FIND_EXIT` passes over it. Three
  exits are like that on the tape: south from the bewitched gloomy place
  through the black river, and up (through the trap door) and south (through
  the fast river) from the forest river. They exist so that the door or river
  is described as being that way. A hidden road is different: its exit is
  zeroed whole, direction and all ([`hidden-roads.md`](hidden-roads.md)).

**Moving** (`MOVE` $8D9D, for whoever is `ACTOR`; *read*): in the dark the
direction is thrown away for a random one, and a way that is not there makes
the player fall ([`light-and-dark.md`](light-and-dark.md)); a character held
by another lets go; `FIND_EXIT`, `CAN_PASS`; the actor's location and
everything it holds move (`MOVE_HELD`). For the player only: the arrival hook
(`ARRIVAL_HOOKS`, [`time-and-timers.md`](time-and-timers.md)); in the dark,
nothing more; otherwise, if not visited, mark it, score it
([`scoring.md`](scoring.md)) and `DESCRIBE_ROOM` in full, else
`DESCRIBE_BRIEFLY`.

**Describing** (*read*): in full (`DESCRIBE_LOCATION`) is the opening
("you are in ..."), the description or else the name, the picture and a key
wait ([`pictures.md`](pictures.md)), each way through a visible object
("to the east there is the round green door"; `EXITS_THROUGH`), the open ways
out ("visible exits are:"; `VISIBLE_EXITS`, which prints nothing if there are
none), and what is there (`YOU_SEE`, `LIST_HELD`: loose things and what they
hold, indented; fixtures in two places left out). Briefly -- a place already
visited -- is the name, the open exits and what is there; no picture, no
doors. LOOK always gives the full form.

**ENTER and GO INTO** name a place, not a thing: `ROOM_BY_NAME` matches the
phrase against the names of the rooms this one's exits lead to, so ENTER
CAVE finds the trolls' cave.

**The map as a whole** (*read*, computed from the records for these notes):

- 79 rooms, 53 lit and 26 dark, 205 exits; every room reachable from Bag End
  if doors are ignored, and every room has a way in.
- 42 exits are one-way. Some are cliffs and rivers (down the steep path, down
  into the forest river through the trap door); some are tangles: from
  inside the goblins' gate (19) eight of the ten directions lead back to the
  big goblins' cavern, and all four directions from lake town lead to the
  long lake.
- Fifteen rooms share the name "dark stuffy passage" (15 and 52-65), the
  goblins' maze; eight share "narrow path" (68-74) and three "steep path".
- Three rooms have a capacity other than no limit: Bag End (160), the
  smooth straight passage (176) and the empty place at 47 (254). The last is
  sealed: the stone, its only content, is 254 big, so `ROOM_LEFT` is 0 and
  nobody fits. *Measured* 2026-09-27: from the other empty place (51) NORTH,
  and from the mountains (48) EAST, both answered that the place is too full
  to enter.
- Location 0 is 13 bytes: an empty head and a lone exit list, never walked.
  Objects "nowhere" (the lunch, the fresh waters) have location 0.

The site's Map page lays the rooms out by walking the exits from Bag End,
each a step in its direction, with collisions pushed to the nearest free
cell (`hobbit_pages.map_layout`); the Inspector's map
(`hobbit-vscode/map_flow.js`) re-flows it around the player so every exit of
the current place points its own way.

## How this was found

The room table was decoded on 2026-09-23 (`1ccc4e1`): the pointer table's
records ending exactly where the next begins proved the exit grammar, and
every exit's destination being a room and every "through" an object checked
it. Direction codes 1-4 and 9-10 were watched in `MOVE`; 5-8 were read off
descriptions and then off `DIRECTION_WORDS`. The one-way count, the sealed
room and the capacity figures were computed from the snapshot for these
notes.

## Confidence

*Read*, with the build's all-or-nothing checks behind the format. The sealed
room is *measured* from both of its ways in.

## Disassembly corrections

- `MOVE`'s description says the four diagonals' codes "will be among 4 to 8,
  but which is which has not been watched". `DIRECTION_WORDS`, which
  `DIRECTION_WORD` indexes by code, gives the order: 5 northeast, 6
  northwest, 7 southeast, 8 southwest. Corrected in the annotations 2026-09-27.

## Open questions

- Whether the sealed empty place was meant to be sealed (a stone blocking the
  way) or is a room left unfinished. No instruction names location 47 or
  the stone (searched for `$2F` and `$28` as operands, and for the stone's
  record address); only the two exits and the stone's own record do.
