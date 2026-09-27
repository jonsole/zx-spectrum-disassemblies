# Valves, sockets and the places

**Question this answers:** where the valves come from, how they are kept
from room to room, what a socket and its sparkle do, and how many valves of
each kind a game has to spare.

**Short answer:** 36 places (`PLACES`, $76E3, nine bytes each) are dealt at
every new game: the four kinds of valve (graphics 96-99) in rotation from a
random start, and every sixteenth place by a second count an extra life
instead -- two or three a game. What lies in the robot's room comes into
records 2 and 3 as the room is built and goes back to its place as he
leaves, so a valve stays where it was put. A valve in a chamber whose socket
is its kind steers itself onto the socket ([`chambers-and-summary.md`](chambers-and-summary.md)).
The socket's sparkle shows the valve it wants while nothing from the places
lies in the room. Because the extra lives fall sixteen places apart and the
kinds repeat every four, all of a game's extra lives replace valves of one
kind: in a game with three, that kind has exactly the six its sockets need
(*read*, worked from the code; not played).

## How it works

- **A place** (*read*): +0 the graphic (0 when empty), +1-+4 where it
  starts (U, V, Z, room), +5-+8 where it is now. The 36 start in 36
  different rooms (*read* from the data).
- **Dealing** (`INIT_SPECIAL_OBJECTS` $AF3F, every new game): E = `SEED` +
  R is the kind to deal next; D = `RANDOM` is counted down once per place,
  and when its low four bits reach 0 the place gets graphic 12, an extra
  life ([`lives-and-starting.md`](lives-and-starting.md)); E goes up by one
  either way, so that place's kind is skipped. +1-+4 are copied to +5-+8.
- **The arithmetic of the kinds** (*read*, the consequence worked out for
  these notes). The extra lives fall at the places k (1-36) where k equals
  `RANDOM` modulo 16 -- two places, or three when that is 1 to 4. The kind at
  place k is (E + k - 1) AND 3, the same at k, k + 16 and k + 32. So every
  extra life takes a valve of the same kind: each kind is dealt nine times
  in 36, and that kind loses two or three. There are six sockets of each
  kind. With three extra lives -- about one game in four, if `RANDOM`'s low
  bits are even (*inferred*) -- one kind has exactly six valves, and a valve
  of that kind lost (see below) leaves the game unwinnable. Not played or
  staged.
- **Into the room** (`FIND_SPECIAL_OBJS_HERE` $AE99, after the builder): each
  place in use whose room is the robot's becomes a record from record 2 up:
  its graphic, U, V, Z, half-sizes 5, 5 and height 12, flags $14 (pushable
  and carried, to be drawn), and +$10/+$11 the place's address. Knight
  Lore's `find_special_objs_here` instruction for instruction -- including
  having no limit of two records.
- **Out of the room** (`UPDATE_SPECIAL_OBJS` $AF05, from `ENTER_ROOM` when
  `PLAYED` is set, and at the game's end): records 2 and 3 holding graphics
  96-103 write their graphic, U, V, Z and room back to their place. Extra
  lives are not written back (they do not move far; a taken one has emptied
  its own place).
- **A loose valve** (`LOOSE_VALVE` $AF79, graphics 96-99): falls and can be
  pushed; the only thing that can be picked up
  ([`picking-up.md`](picking-up.md)); a sound pitched by its position each
  turn it moves, and once when just put down (bit 0 of +$0D). With a socket
  in the room (`FIND_GRAPHIC_HERE` $AE03, graphics 112-115) whose kind --
  the graphic AND 3 -- is its own, it sets its U and V steps to one unit
  towards the socket every turn, and sitting exactly on it (the same U and
  V, Z 12 above the socket's base) activates the chamber.
- **A seated valve** (`SEATED_VALVE` $AE5D, graphics 100-103) stays put and
  cannot be picked up (`CAN_PICK_UP` takes only 96-99).
- **The socket and its sparkle.** Object templates 24-27 are a socket
  (112-115, `SOCKET` $AE68) and, in the next record, its sparkle (108-111,
  flags $12: out of the tests, to be drawn). `SOCKET_SPARKLE` ($AE33) hovers
  13 above the socket and runs through four frames (sprites shared with the
  death sparkle); when the frame equals the socket's kind it shows the
  wanted valve's picture instead (`WANTED_VALVE` $AE17, graphics 104-107,
  sprites shared with 96-99) for two turns. Both the sparkle and the picture
  vanish (graphic 1, `VANISH` $B3BB) whenever `ANY_SPECIAL_HERE` ($AE81)
  finds record 2 or 3 in use -- a valve loose or seated, or an extra life.
  `SOCKET` recreates the sparkle in the record after it when the room has
  nothing from the places and that record is empty.
- **How a valve is lost.** Two ways in the code: the depth sort destroys a
  loose valve it finds sharing space with anything
  ([`depth-order.md`](depth-order.md)), emptying its place for good; and
  `LOOSE_VALVE`'s second test of the kinds at $AFE7, which would turn a
  valve of the wrong kind on a socket into the sparkle, cannot fail -- the
  valve steers only to a socket of its own kind -- and never ran (*read*).
- **The chambers by kind** (*read* from the data): six sockets of each kind
  -- 112 in rooms $0C, $28, $7A, $99, $A5, $B6; 113 in $41, $62, $6E, $96,
  $AA, $D6; 114 in $1D, $31, $4B, $84, $8D, $94; 115 in $0A, $4F, $65, $8C,
  $BA, $F8.

## How this was found

Read (stage 2, range 1); the dealing's consequence for the kinds worked out
from `INIT_SPECIAL_OBJECTS` for these notes. *Measured*: stage 1's chamber
sessions (a valve of the socket's kind in the room steers itself towards the
socket and activates the chamber on it; in room $1D it arrived under the
socket and had to be held over it); range 1's staged return of the sparkle
(a valve of the wrong kind put in room $0C, the room built, record 2
emptied: `$AE7E` was reached, the sparkle record came back as graphic 108
over the socket and cycled); range 4's valve destroyed in the start room.

## Confidence

The flow *read*; the steering, the activation and the sparkle's return
*measured*. The three-extra-lives game with exactly six valves of a kind:
*read* and worked out, not staged; how often it happens *inferred*.

## Knight Lore and Pentagram

`INIT_SPECIAL_OBJECTS`, `FIND_SPECIAL_OBJS_HERE` and `UPDATE_SPECIAL_OBJS`
keep Knight Lore's names
([`../knightlore/special-objects.md`](../knightlore/special-objects.md)).
The second is identical; the first deals four kinds and the extra lives by
a count of their own, where Knight Lore deals eight kinds in turn, the
eighth its extra life; the third writes back only valves, Knight Lore's
anything in the records. The sockets, the steering, the sparkle and the
wanted valve's picture are Alien 8's own. Pentagram keeps its quest things
in records of their own instead ([`../pentagram/quest-records.md`](../pentagram/quest-records.md)).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `INIT_SPECIAL_OBJECTS` | `SUBAF3F` | $AF3F | deal the places |
| `FIND_SPECIAL_OBJS_HERE` | `SUBAE99` | $AE99 | the room's places into records 2, 3 |
| `UPDATE_SPECIAL_OBJS` | `SUBAF05` | $AF05 | the valves back to their places |
| `LOOSE_VALVE` | `SUBAF79` | $AF79 | graphics 96-99; activating a chamber |
| `SEATED_VALVE`, `WANTED_VALVE`, `SOCKET_SPARKLE`, `SOCKET` | `SUBAE5D`, `SUBAE17`, `SUBAE33`, `SUBAE68` | $AE5D, $AE17, $AE33, $AE68 | graphics 100-103, 104-107, 108-111, 112-115 |
| `ANY_SPECIAL_HERE`, `FIND_GRAPHIC_HERE` | `SUBAE81`, `SUBAE03` | $AE81, $AE03 | records 2, 3 in use?; the first room record with a graphic in a range |

## Also found for the stage 3 pages (2026-09-28)

- Every extra life replaces a valve of the same kind: lives fall 16 places apart and the kinds repeat every 4, so a deal gives 9/9/9/7, or 9/9/9/6 in a game with three extra lives (one in four, from the 64 deals that matter). In those games one kind has exactly its six sockets' worth, and one valve lost to the depth sort's rule leaves the game unwinnable (*measured* counts; the consequence *inferred*, not played).
- Carried valves survive a lost life (*measured*).
- A loose valve in its own chamber crawls towards the socket but cannot climb it: it seats itself only when put down on the socket's top (*measured*).
- The build's `_chamber` staging holds the valve 30 above the socket, which in chambers $AA, $B6 and $D6 is inside a block, so the depth sort destroys it; it works only for the four rooms the build's session uses. Put the valve on the socket's top instead.

## Open questions

- `SOCKET` projects the record at IY, not the new sparkle's: a slip,
  harmless because the emptied record keeps its old position (IY was the
  legs' record when measured). Whether IY can point anywhere harmful there
  was not searched exhaustively.
- That no room ever gets three things from the places is *inferred* (36
  places in 36 rooms; a put-down needs a free record of the two; things do
  not cross doorways).
- Whether a player can in fact lose a valve to the depth sort in play, and
  so make a three-extra-life game unwinnable: stage a game dealt with three
  and look for a way to push a valve into something.
