# Objects: records, containers, reach, size and weight

**Question this answers:** how an object is stored, how one thing holds
another, what can be reached, and how size, weight and the flags decide what
can be carried, put in or gone through.

**Short answer:** everything -- the player, the characters, the doors, the
rivers and the keys -- is one of 61 object records: a 16-byte head, the
places it is in (a door or river is in two or more), and a list of its own
action handlers. One object holds another through byte 1 of the held one's
head, which is how carrying, containers, riding in the barrel and being tied
to the rope all work. Size and weight decide the rest.

## How it works

**`OBJECT_INDEX`** ($C063) is a `FIND_RECORD` table of number and record
address. Numbers run $00-$2B (the player is $00, then 43 things) and
$3C-$4C (the 17 characters); `GET_OBJECT` ($9BCA) finds a record by number
(*read*). The records, $C11B-$C72F, end where the next begins and the last
at `ACTION_TABLE`, which is the build's proof of the grammar.

**The head** (*read*; each field in words beside its bytes in the listing):

| Offset | Field |
|---|---|
| 0 | how many places follow the head |
| 1 | what holds it, or $FF for nothing ($00: the player) |
| 2 | size -- for a container, how much it holds |
| 3 | weight -- for a character, how much it can carry |
| 4 | bits 0-3 how things sit with it: in, on, behind, under, tied to; bits 4-6 its sides; bit 7 the window's "not for the player" |
| 5, 6 | strength and defence ([`fighting-and-dying.md`](fighting-and-dying.md)) |
| 7 | flags, below |
| 8-13 | its name: a noun and two adjectives, word references |
| 14-15 | its own description (a message), or 0 |
| 16- | the places it is in, then its handlers ([`actions.md`](actions.md)) |

**The flags**, byte 7 (*read*; bit 4 named after Wilderland's):

| Bit | Meaning | Notes |
|---|---|---|
| 7 | there: can be seen and reached | clear only on the mountains' side door (until the hole appears) and the butler (until Beorn's house); cleared by the ring |
| 6 | a character | the player and $3C-$4C, nothing else |
| 5 | open, or can be seen into | set by OPEN, cleared by CLOSE; on the characters, the goblins' cache, the boat, the rope and the wall from the start |
| 4 | gives light | the sword and the torch only |
| 3 | dead, or broken | set by KILL and by breaking; also lets anyone through a broken door |
| 2 | full (a container); part of the glow (the sword, the torch) | DRINK and EMPTY clear it |
| 1 | a liquid | the wine, the four waters, the two rivers |
| 0 | locked | the rock door, the red door, the side door and the trap door on the tape |

**Holding** (*read*). Byte 1 is the whole containment model: the map held by
the player, the key held by the goblins' cache, the cache held by the trap
door, the trap door held by the sand, the player held by the barrel. What
moves with a holder is found by walking the index for everything whose byte
1 is that holder (`MOVE_HELD`, recursive), and every held thing's location
is kept equal to its holder's. The holder's byte 4 says how things sit with
it (`PLACED_WORD`): in the chest or the sand, behind the curtain (the wall
is), under the trap door (the goblins' cache is), tied to the rope; nothing
on the tape uses "on".

**Seeing in and reaching** (*read*):

- `SHUT_IN` ($9E7A) climbs the holders while they can be seen into (flags
  $28: bit 5 open, or bit 3 broken) and returns the first that cannot, or
  $FF. The player's own record has bit 5, so carrying a thing does not shut
  it in.
- `IN_REACH_OF` ($9E40): nothing is in reach without flag bit 7; otherwise a
  thing is in reach if the character is shut inside it, if both are shut in
  the same thing, or if neither is shut in anything and the character's
  location is any of the thing's places -- which is how a door is in reach
  from both sides.
- Being shut inside something also shuts the player in the dark, whatever
  the room ([`light-and-dark.md`](light-and-dark.md)).

**Size and weight** (*read*):

- **Lifting** (`CAN_LIFT` $8CF1): the thing's weight plus everything in it
  (`WEIGHT_HELD`, at any depth) must not exceed the actor's byte 3, nor what
  is left of it after the actor's present load; a liquid cannot be lifted.
  Doors, walls and fixtures have weight 255. The player carries up to 64;
  Gandalf 96, Thorin 80, the trolls 144.
- **Containers** (`DO_PUT_IN` $924F): open (except PUT ON), and its size less
  the sizes of what it directly holds must exceed the thing's size. The
  chest holds 64, the barrel and the treasure are 32 each.
- **Ways through** (`CAN_PASS`): the actor's size plus its load against the
  object's size ([`locations.md`](locations.md)).
- **Climbing in** (`DO_CLIMB_INTO`): the barrel, the chest and the boat, if
  open and big enough for the actor and its load.

**The rope** (*read*): TIE X TO ROPE makes X held by the rope (TIE ROPE TO X
is swapped round first); a tied thing is taken and dropped by taking and
dropping the rope; THROW ROPE ACROSS a river can catch the boat, and PULL
brings it over ([`bugs.md`](bugs.md) has the trouble with the barrel's
FILL).

**Liquids** (*read*): dropped, a liquid is not dropped but lost ("...
evaporates.", location 0); emptied out of a container it is poured away
(`EMPTY_OUT`). The rivers are liquids in several places: something put in
one comes out downstream (`INTO_THE_RIVER`). FILL from a river takes a fresh
water kept nowhere for the purpose (objects $15, $16).

**Objects in several places** are fixtures: the doors between two rooms, the
spider web in five, the rivers, the water in eight. `LIST_HELD` leaves loose
multi-place things out of "you see", since `EXITS_THROUGH` has already named
them as ways through. Only something in one place can be a weapon or be
put anywhere.

**Two pairs share a name**: two waters and two black waters (the drinkable
ones in the rivers, and the fresh ones FILL fetches); the build labels the
second of each with its number.

## How this was found

The index and the record grammar on 2026-09-23 (`74bd54f`, `ae608ea`):
`FIND_OBJECT_HANDLER` adds byte 0 and 16 to the record and searches the rest
as a keyed table, and every record then ends exactly where the next starts.
Byte 1 was watched: the map held by Gandalf on the tape and by the player at
the first prompt. The player's location was watched going 1, 4, 1 on EAST
and WEST. The flags were read from every routine that tests them, and bit 4
named when Wilderland's names for the fields turned out to agree with these.
The capacity and carrying figures are from the records (the object table
dumped from the snapshot for these notes).

## Confidence

The layout is *read* and proved by the build. The flag meanings are *read*
from their uses; bit 5 was *measured* changing with OPEN and CLOSE on the
barrel, and bit 2 cleared by EMPTY (2026-09-27, simulator). Carrying limits
are *read* only.

## Open questions

- Nothing in the tape is *on* anything (placing word 1 is never used), and
  no object handles PUT ON, so the "on" code in `DO_PUT_IN` and `PLACED_WORD`
  has no use in this version.
