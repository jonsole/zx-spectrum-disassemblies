# Doors

**Question this answers:** how doors are stored, what kinds there are, what
happens when the player walks through one, and which doors open and shut on
their own.

**Short answer:** a door is one sixteen-byte record whose two eight-byte halves
sit in the two rooms it joins; walking through means reading the other half,
found by flipping bit 3 of the address. The record's type byte picks a
handler: plain doors, big staircase doors, locked doors in four colours, the
clock, bookcase and barrel that only one character can use, trapdoors, the
A.C.G. door -- and, chosen at random when a game starts, about half the plain
doors become timed doors that slam shut and open again by themselves.

## How it works

**The record** (*read*): each half has the eight-byte header
([`records.md`](records.md)): type, the room this half is in, a packed
arrival offset (+$02), the door's x and y (its bottom-left corner), +$05
(orientation in bits 7-5, which also gives the wall: 0 north, 4 south, 3
east, 7 west; bit 3 shut; bit 2 solid), and a walk box in +$06/+$07. 274
records: 205 doors and 69 pairs of furniture, which are stored the same way
though nothing passes between their halves (the build's count).

**Types and handlers** (*read*, `ACTOR_HANDLERS` from $802A; the picture is
furniture graphic t, `SPRITE_TABLE` code $A1 + t):

| Type | Handler | What |
|---|---|---|
| $01, $02 | `DOOR` $91F2 | cave door, door -- always open |
| $03 | `BIG_DOOR` $91ED | the big door frame at a staircase's top; a wider doorway ($2020) |
| $08-$0B | `DOOR_LOCKED_A` $9244 | red, green, cyan, yellow door ([`keys-and-locked-doors.md`](keys-and-locked-doors.md)) |
| $0C-$0F | `DOOR_LOCKED_B` $9252 | the same as cave doors (no yellow one is used) |
| $10 | `DOOR_KNIGHT` $942F | a grandfather clock: a door for the knight only |
| $17 | `DOOR_WIZARD` $9428 | a bookcase: for the wizard only |
| $1A | `DOOR_SERF` $9421 | a barrel: for the serf only |
| $18 | `TRAPDOOR_CLOSED` $91BC | a closed trapdoor, which opens by itself |
| $19 | `TRAPDOOR` $91C5 | an open trapdoor |
| $20, $22 | `TIMED_DOOR_SHUT` $917D | a timed door, cave door, shut |
| $21, $23 | `TIMED_DOOR_OPEN` $915F | the same, open |
| $24 | `ACG_DOOR` $961B | the way out ([`acg-key-and-winning.md`](acg-key-and-winning.md)) |
| $11, $12, $15, $16, $1B-$1E, $25-$27 | `DRAW_DOOR` $91FE | furniture that only draws itself: the ghost picture, table, antlers, trophy, rug, shields, suit of armour, pumpkin picture, skeleton, barrel stack |
| $00, $04-$07, $13, $14, $1F | `INERT_SPRITE` | nothing |

Types $18 and $20-$23 never appear in the template: the game makes them at
run time.

**Walking through** (*read*): `DOOR` calls `PLAYER_AT_DOOR` ($90CC) with a
tolerance of 17 x 17 pixels ($1111), halved across the door: a door in the
top or bottom wall catches the player in a box 17 wide and 8 high, one in a
side wall 8 wide and 17 high, anchored at the door's corner. It also needs
the player in play and the low nibble of the player's +$02 clear. Then
`ENTER_ROOM` ($9117):

1. `DOOR_OTHER_SIDE`: IX to the other half.
2. The player's room is that half's +$01; x is the half's x plus twice the low
   nibble of +$02, y its y minus twice the high nibble (the usual $34 gives 8
   right and 6 up).
3. `SET_ARRIVAL_HEADING` ($986A) gives the player a heading of 32 pointing away from
   the arrival door's wall (from `ARRIVAL_HEADINGS` $9883: north wall down, south
   up, west right, east left), and the low nibble of +$02 is set to 15.
4. `ARRIVE_IN_ROOM`: mark seen, clear the play area, draw the room, colour the
   panel, draw the inventory, start sound $65, back to `MAIN_LOOP`.

While that nibble counts down -- once a frame in `MOVE_PLAYER` -- `STEER`
ignores the controls and keeps the player moving two pixels a frame along
the heading, and no door can fire: the player walks fifteen frames into the
room on their own (*read*). Creatures left behind stay in the old room
([`monsters.md`](monsters.md)); a weapon in flight vanishes, because it is
no longer in the player's room.

**Timed doors** (*read*, then *measured*). Once, at `START_GAME`, `CHOOSE_TIMED_DOORS`
($94F5) walks every record: where both halves are type $01 or $02 and a byte
read from the ROM (a pointer made of TICKS and FRAMES, stepped a byte per
record) is below $70, both halves become $22 or $20 -- a shut timed cave door
or door -- and are marked shut. In the first game after loading that
converted 47 of the 82 plain doors and 21 of the 43 cave doors (counted by
halves in the simulator). A timed door's handler, on every other pass (TICKS
even), counts down one shared counter, `DOOR_WAIT` ($5E2E); the door that
finds it at zero reloads it with 94, erases its picture, flips type bit 0 on
both halves ($20 and $21, $22 and $23), opens or shuts them to match, redraws
and makes the rasp (`TOGGLE_TIMED_DOOR` $9193). An open one ($21/$23) is a normal
doorway meanwhile, and will not shut while the player is outside the room's
walk area -- that is, standing in a doorway (`IN_DOORWAY` $5E2D). With
several timed doors in a room they share the counter, so the toggles come
faster and take turns.

**Trapdoors** (*read*). All eleven start open (type $19). An open trapdoor's
handler jumps to `TRAPDOOR_FALL` ($9731) unless the byte `RUNNING_SUM` ($5E05,
a sum of FRAMES and TICKS kept by `MAIN_LOOP`) is zero, in which case it
closes (the flip in `TRAPDOOR_CLOSED`'s tail makes it $18). A closed one opens
again whenever TICKS' low byte is zero -- every 256 passes, about eleven
seconds in room $00. `TRAPDOOR_FALL` first asks `PLAYER_AT_DOOR` with $1818
(24 x 12): not on it, just draw. On it: clear the play area, draw entry $96
(twelve nested rectangles), then 128 frames of a falling tone with the middle
four attribute cells white one frame in eight and black otherwise, spread
outwards by `SPIRAL_FILL`; then `ENTER_ROOM` through the trapdoor's other
half, which is the landing spot in the room below.

**The characters' doors** (*read*): `DOOR_KNIGHT`, `DOOR_WIZARD` and
`DOOR_SERF` subtract the character's first sprite code from the player's and
test for under 16. The right character: `OPEN_DOOR` and act as a door. Anyone
else: `SHUT_DOOR` and just draw it. So the clocks, bookcases and barrels are
secret passages for one character each ([`player.md`](player.md)).
*Watched* live 2026-09-27: the knight, moved to room $0A and walking up into
its bookcase, stopped at y $52; with the JR NC at $9435 NOPped he went
through in 12 frames.

## How this was found

Read the handlers in the table from $802A and `ENTER_ROOM`, `CHOOSE_TIMED_DOORS` and
the timed-door pair. The conversion counts were read from the simulator's
memory after `START_GAME`. The arrival heading was traced from
`SET_ARRIVAL_HEADING`'s one caller.

## Confidence

*Read* throughout; the timed-door counts *measured* for one (fixed) first game.
The walk-in of fifteen frames is from the code (`STEER`'s second path), not
timed.

## Renamed routines

Applied to the annotations on 2026-09-27; the build verified byte for byte.

| New name | Old name | Address | Role |
|---|---|---|---|
| `SET_ARRIVAL_HEADING` | `MODE_TO_INDEX` | $986A | the heading into the room from the arrival door's wall |
| `ARRIVAL_HEADINGS` | `DRIFT_OFFSETS` | $9883 | the four headings |
| `CHOOSE_TIMED_DOORS` | `SCAN_DOORS` | $94F5 | makes about half the plain doors timed |
| `TRAPDOOR_CLOSED` | `FLASH_AND_RASP` | $91BC | the closed trapdoor's handler, and the shared swap-and-rasp tail |
| `TIMED_DOOR_SHUT` | `WAIT_THEN_ACT` | $917D | a timed door, shut |
| `TIMED_DOOR_OPEN` | `WAIT_THEN_DOOR` | $915F | a timed door, open |
| `TOGGLE_TIMED_DOOR` | `RESTART_WAIT` | $9193 | reload the countdown and swap shut and open |
## Disassembly corrections

All applied to the annotations, the ref and the build on 2026-09-27 (the old names are used below), except where marked.

- `SCAN_DOORS`: "tests each sprite against $70". The $70 test is on a byte
  read from the ROM as a random number; the sprites are tested for being 1 or
  2 and equal on both halves.
- `FLASH_AND_RASP`: "Three overlapping draws and a rasp, which is what a thing
  being destroyed looks and sounds like." The first draw XORs the current
  picture off, the second XORs the other state's picture on; it is a closed
  trapdoor opening (and, entered at $91CC, an open one closing).
- `DRIFT_OFFSETS`: "which is what the mushroom's wander looks like on screen".
  Only `ENTER_ROOM` reads it (through $986A): it is the arrival heading.
- `WAIT_THEN_ACT`: "Reached from the handlers for sprites $C2 and $C4" -- those
  are handler-table indices; the records are types $20 and $22, the shut
  timed doors, drawn as graphics $C1 and $C3.
- `TRAPDOOR_FALL` at $975A: "Bit 3 of the counter picks $00 or $47". It is
  `AND $07`: white on one frame in eight.
- `ENTER_ROOM`'s closing note: doors "are 8-byte records in a table above the
  monsters ... Only the ones whose +$01 matches the room the player is in get
  tested". They are sixteen-byte pairs, reached through the room's list.
- `PLAYER_AT_DOOR`: "the player only registers from one side of the doorway --
  walking into a door from behind does nothing". The compares make a box
  anchored at the door's corner and extending right and up, which is the
  door's own cells; nothing about sides follows from it (*read*; not tested).
- The ref's "Doors that know who you are" gives the three doors as sprites
  $B2, $B9 and $BC. Those are handler-table indices; the records' types are
  $10, $17 and $1A and their pictures $B1 (clock), $B8 (bookcase) and $BB
  (barrel), which is how the Graphics page names them.

## Also found for the how-it-works pages (2026-09-27)

- Trapdoors close far more often than once in 256 passes: room $03's closed 8 times in 60 s, reopening each time on the pass after `TICKS`' low byte came round to zero (*measured*).
- `CHOOSE_TIMED_DOORS` at a new game made 47 of the 78 plain doors and 21 of the 42 cave doors timed, reading ROM bytes from $1F00; room $00's two timed doors toggled 94-96 passes apart (*measured*).

## Open questions

- Whether timed doors in rooms the player is not in ever change (their
  handlers only run from the player's room list, so they should be frozen;
  not tested).
