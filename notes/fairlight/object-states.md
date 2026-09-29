# Object states: what each object does in a pass

**Question this answers:** what the author's CHE3D ($F1E0) does for each
object every pass, what the states in +14 are and who has them -- and what
the freeze, the decoy and Release 1's lock-up are.

**Short answer:** `CHE3D` skips what has nothing to do (no sprite, doors,
carried or vanished things, still things), copies the rest into the working
variables at $FFE4 and dispatches on the low nibble of +14, the state. Each
state's case picks a direction and a sprite and hands over to the shared
movement code ([`movement.md`](movement.md)). The states: 0 lying, 3
bouncing about, 4 a creature that strikes, 5 the knight's jump, 6 and 10
patrolling guards, 7 the troll, 8 the knight, 9 guards that rise out of the
floor, 11 the wraith, 12-14 floating and wandering things, 15 the figure of
room 61. Using the thing of kind 5 freezes every state but the knight's
until the next room -- and in Release 1, which forgot the jump, a jump
during the freeze locked the knight for good.

## How it works

`CHE3D` is called by `MAIN_LOOP` ($FF53) for each record from the knight's
(7) to the last, and again by the movement code ($F793) for an object that
was in the air and could not move at all. In order:

1. **Return** for: no sprite (+4, +5 zero); a door (kind 1); +16 bit 5
   (carried, or vanished -- set by the pick-up $F563 and by the meeting code
   $F982, $F9E6, $FA4B, $FA79); +16 bits 0-4 clear (still).
2. **Copy** +0 to +18 to $FFE4-$FFF6 (IY+$64 on, the author's `T`), the
   record's address to `WORK_RECORD` ($FFFD), and +14 also to $FFE7, read
   at $F781 as "the state when the pass began".
3. **The room's first pass** (bit 2 of `GAME_FLAGS`): only the offset box
   test and the drawing (`SKIP_GRAVITY`, the author's NOG, $F68C;
   [`movement.md`](movement.md)).
4. **In the air or coasting** (bit 7 of +14): no case runs; it goes on in
   the direction +18 holds (`ADD_GRAVITY`, the author's NOPROP, $F67E).
5. **The state**, +14 AND $0F, tested in turn (the author's labels I0 to
   I95 inside `CHE3D`; from state 6 on `CREATURE_UPDATE`, $F309, the author's
   I6):

| State | Who (type) | Case | What it does |
|---|---|---|---|
| 0 | A thing lying | I00, I02 | Only falls. With bit 4 of +14 (set by a drop, $F4D2, and by a knock, $F976) it moves by +13 once more; the bit is cleared in the copy |
| 3 | Room-placed things (type 2) | I30 | Keeps moving along +13, or $45 (diagonal, turning back) if it has none; bounces off what it meets |
| 4 | A winged creature (type 48) | I4 | If the knight overlaps its box moved 12 towards lower x (`BOX_OVERLAP`, $FCF2): 3 from LIFE and a frame of its strike (from $5C84, 144 bytes a frame), without moving; else nothing |
| 5 | The knight, jumping | I5, I50 | Set by `KNIGHT_JUMP` ($F629) with +15 = 8: each pass up, without gravity, the way he walked, through his poses (INP5); at 0, state 8, and he falls |
| 6, 10 | Guards (types 26, 33) | `GUARD_MOVES` $F311 | Chase the knight within 30; otherwise patrol along x (6) or z (10), turning back when stopped |
| 7 | The troll (type 13) | $F3B1 | Chases; clears bit 4 of its own +12 (hurts at a touch) on its first pass |
| 8 | The knight | `KNIGHT_UPDATE` $F3CD (I8) | The controls ([`knight.md`](knight.md)) |
| 9 | Guards (type 27) | I9, I95, I92, I91 | Rise out of the floor: +17 counts up from its template's $10 through four frames ($A4B8, $A41C, $A380, $A2E4); then +17 = $51 (bit 6: risen) and it chases for good (`STEER`, `ZOOMIN`) with the guards' walking frames ($F33C), following a decoy if one lies in the room |
| 11 | The wraith (type 45) | `WRAITH_MOVES` $F35E (I1110) | Chases; one frame each way |
| 12 | Type 51 | $F36F (I12) | Hangs in the air and flickers (three 8 by 8 frames) |
| 13 | The ghost (type 52, $5B30) | $F382 | Wanders diagonally, bouncing, animated; takes things it runs into ([`meeting.md`](meeting.md)) |
| 14 | Type 40 | $F395 | Hangs in the air and flickers |
| 15 | The figure of room 61 (type 56) | $F3A1 | Still until the thing of kind 11 lies in the room; then a wraith (state 11) for good |

Chasers (6, 7, 9, 10, 11, and 15 once woken) steer through `STEER` ($F2F7,
the author's ZZ1): the course in +18 is kept until the count in +15 runs
out, and then `ZOOMIN` aims again ([`chasing.md`](chasing.md)).

**Noting the decoy and the book.** In state 0's code (I00-I01), the first
thing of kind 8 the pass meets is kept in `DECOY` ($FF8F) and bit 0 of
`THINGS_NOTED` ($FF91) set; `ZOOMIN` then aims state-9 guards at it instead
of the knight, and one that reaches it takes it out of the game (`MEET_DECOY`,
$FA83), clearing `THINGS_NOTED` so the guard goes back to the knight. A thing
of kind 11 sets bit 1, which wakes the state-15 figure (as state 11, $F3A1)
and lets room 61's door work ([`doors.md`](doors.md)). `THINGS_NOTED` is
cleared on entering a room ($FE3D), after a pick-up ($F590) and when the
decoy is taken ($FA95).

**The freeze.** Using a thing of kind 5 sets bit 7 of `GAME_FLAGS` ($FEC8);
only entering a room clears it (`DRAW_STILL_THINGS` sets the flags to 5).
While it is set, I3 ($F258) sends state 8 on to the controls, lets state 5
go on (Release 2) and treats every other state as 0: the creatures stop and
only fall.

**Release 1's lock.** Where Release 2 has `CP 5 : JR NZ,I00` ($F263),
Release 1 has `JR I00`. Under the freeze Release 1 therefore treats the
knight's jump (state 5) as state 0: nothing counts it down, and state 8 --
his controls -- never comes back. That is surely why Release 2 made the
change ([`versions.md`](versions.md)).

## How this was found

Read (stage 2, ranges 3 and 4) from $F1E0 to $F3CD, following each exit far
enough to know what it means. A census of every object in every room (each
room entered in the simulator, every record dumped) gave which states and
types exist and where. Then staged in the simulator:

- **The jump and the freeze**, both releases: room 24, its kind-5 thing
  picked up and used (`GAME_FLAGS` became $80), SPACE, then Q for ten passes.
  Release 2: state 8 for a pass, 5 for eight, then 8, and he walked 20
  units. Release 1 (its own snapshot, and Release 2 patched at $F263): 8,
  then 5 for every one of the next 19 passes, and he did not move. Room 2's
  state-7 creature moved 44 units in 40 passes free, none frozen.
- **The decoy**, room 20: the guard went to the thing, the thing's
  object-table room became 254 and its +16 bit 5 set, and `THINGS_NOTED`
  went back to 0; with the thing's kind changed, the guard went for the
  knight.
- **State 4's strike**, room 45: the knight put 12 below a state-4
  creature's x -- $F28B reached every pass, LIFE from 99 to 63 in 12 passes,
  the sprite pointer at $5D14. The build's sessions never reached it
  (`fairlight-coverage.txt`'s $F28B-$F29E).
- **State 3's bouncing** in rooms 15, 64 and 80: the direction bits flip at
  each block. **State 9** rising in room 20. **Room 61** with the book
  staged there by writing 61 into its object-table room.

To enter a room in Release 1 by jumping to its TELE ($F0C3), B must be 0:
Release 1 has `LD C,$14` there, not `LD BC,$0014`, relying on the `LDIR`
before it (and on $FEAB's `LD B,0` on the kind-9 path). Release 2 made it
`LD BC`.

## Confidence

The dispatch and the freeze: *read*. The lock: *played* in both releases in
the simulator. The decoy and the strike: *measured* once each. What the
creatures are (guard, troll, wraith, ghost) is *inferred* from their
pictures and from the author's MITRO and MIWRAI.

## Krumlinde

- **State 8 "gated behind bit 7 of IY+$17"**: without bit 7, state 8 reaches
  the controls by the chain of compares ($F267 ... $F3CD); bit 7 is the
  freeze, which *removes* the other states.
- **State 9's reference object at $FF8F**: he found the switch; it is the
  first kind-8 thing, a decoy the guard takes.
- **$F1C8 `RTN_Update_Energy_Display`** subtracts from LIFE; nothing is
  displayed there (the main loop prints LIFE when bit 0 of `GAME_FLAGS` is
  set).
- **The type-9 item "teleports to room 30" via `RTN_Reset_And_Enter_Room1`**:
  room 30 is right, but $F09B is TELE, which enters `ROOM`, not room 1; room
  1 is only GAME OVER's backdrop.
- The object code is his `Sub_...` throughout; the author's names (CHE3D,
  I0-I95, ZZ1, I6, I8 ...) come from the symbol table
  ([`symbols.md`](symbols.md)).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `CHE3D` | `SUBF1E0` | $F1E0 | The author's name; I0-I95 inside |
| `DECLI1` | `SUBF1B4` | $F1B4 | Take ten from LIFE; `DECLIF` ($F1B6) takes A |
| `DE1` | `SUBF1C8` | $F1C8 | The two-digit subtraction (`DE2` inside) |
| `STEER` | `SUBF2F7` | $F2F7 | The author's ZZ1 |
| `CREATURE_UPDATE` | `SUBF309` | $F309 | The author's I6: states 6-15 |
| `GUARD_MOVES` | (inside) | $F311 | The author's I601 |
| `GUARD_FRAMES` | (inside) | $F33C | The author's I600 |
| `WRAITH_MOVES` | (inside) | $F35E | The author's I1110 |
| `KNIGHT_UPDATE` | (inside) | $F3CD | The author's I8 |

## Open questions

- **A quirk at I01** (*read*, not tried): the compare there is with A, which
  holds the *kind* only while no decoy is known; once one is, A holds the
  *state*, so a kind-11 thing met later in the pass is missed and a state-11
  creature counts as one. The census has kind 8 only in rooms 7, 20 and 75
  and kind 11 only in room 14, so it matters only once things are carried
  between rooms.
- Why the troll clears its own "hurts at a touch" bit on its first pass,
  when its object-table records set it.
- What the $45 given to a state-3 thing with no direction means beyond
  "diagonal, and turn back" (bits 0, 2 and 6).
- What the things of kinds 5, 8 and 11 are called in the game (their
  sprites are $87C0/$9B3C, $829A and $5E34).
