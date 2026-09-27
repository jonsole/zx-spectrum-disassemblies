# Creatures and dangers

**Question this answers:** what the room's living and deadly things do --
the two-record creatures, the chasers, the clockwork mice, the leapers, the
things that drop from the ceiling, the fragile things, the spikes.

**Short answer:** a thing is deadly by two bits of its +$0D (bit 7 kills what
it moves into, bit 5 kills what touches it), which `MAKE_DEADLY` ($B2A7)
sets every turn for most of them. The movers: creatures built of two records
(an upper half and, under it, graphic 11) that wander or pace; a deadly
thing that homes on the robot one unit a turn and a harmless crackle of
sparks that comes at four; clockwork mice that run and turn at random;
leapers that jump 48 units, one at a time; things that drop from the
ceiling, Knight Lore's spiked balls; fragile deadly things that break when
anything pushes them. Everything that moves by itself is Alien 8's own
except the drop.

## How it works

| Graphics | Template | Routine | Rooms (*read* from the data) | What it does |
|---|---|---|---|---|
| 94, 95 + 11 | 17 | `WANDERER` $B06B, `LOWER_HALF` $B055 | ($2F among them) | two units a turn one of four ways; stopped, a thud and a random quarter turn (by `RANDOM` bit 0); deadly both ways |
| 86, 87 + 11 | 18, 19 | `PACER` $B110, `LOWER_HALF` | ($A6 among them) | two units a turn; stopped, turns round; deadly both ways |
| 76-79 | 16 | `SPARK_CHASER` $B19C | ($9C, $20, $57 among them) | four units a turn at the robot in U and in V (`MOVE_TOWARDS_PLAYER` $B165), falls, four frames every turn (`NEXT_FRAME_MOD4` $B18C), a note by its position; **not deadly** -- it pushes |
| 120, 121 | 29 | `SLOW_CHASER` $AA89 | $5E, $D8 | one unit a turn at the robot in U and V, falls, two frames (`TOGGLE_FRAME` $B185), a sound; deadly both ways |
| 116-119 | 28 | `CLOCKWORK_MOUSE` $AAA1 | $3F, $42, $45, $4D, $72, $A9, $D8 | speed (`TURNS` AND 3) + 2 along U (mirror clear) or V (mirror set), the way by bit 1 of the graphic; walks (`TURNS_HIGH` XOR `RANDOM`) AND 15 turns (+$10); stopped, blocked or done: a beep, the mirror flag flipped (always a quarter turn), bit 1 flipped by `RANDOM` bit 0; deadly |
| 130 | 39 | `LEAPER` $A8F9 | $97, $A9, $B7 | deadly; one in the air at a time (`LEAPING` $5B43); a chance of 1 in 4 a turn; +$10 bit 0 airborne, bit 1 falling, +$11 = Z + 48; rises 2 a turn (a Z step of 3 less gravity) to +$11 or a ceiling, then falls; a sound pitched by height |
| 73 | 20 | `CEILING_DROP` $AD13 | $0C, $1C, $58, $84 | deadly; lets go (+$0D bit 2) when `DROP_LATCH` is clear, none other is falling (`DROPPING` $5B3A) and `RANDOM` < 16; falls with a sound pitched by height; `THUD_ON_LANDING` ($AD54) crashes once as +$0F turns to standing |
| 129 | 38 | `FRAGILE` $A9B1 | $44, $56, $6A, $72, $74, $8B, $D9 | deadly both ways; pushable, and any step turns it into graphic 54, the death sparkle's last frames, and it is gone |
| 46 | 7 | `SPIKES` $B2A4 | | deadly both ways, still |
| 72, 75 | 15, 23 | `STILL_DEADLY` $B29F | | deadly both ways, still, never redrawn |

- **Two records, one creature** (*read*). Templates 17-19 put two pieces at
  one place: the creature and, under it, graphic 11. The upper half's routine
  makes the pair one box for its move (`JOIN_HALVES` $B1FA: Z down 12, the
  height doubled, the lower half out of the tests by bit 1 of its flags)
  and parts it after (`PART_HALVES` $B20B). The lower half, next in record
  order, puts itself under the upper (`PUT_UNDER_UPPER` $B1E5) and is
  redrawn if the upper had a step. The direction is two bits, bit 0 of the
  graphic and the mirror bit: `FACING_STEPS` ($B108) maps them to -U, +U,
  +V, -V (`STEP_FROM_FACING` $B0E7); `TURN_QUARTER` ($B0AD) and
  `TURN_QUARTER_BACK` ($B0DD) step them round; `FACE_ALONG_STEP` ($B1AE)
  sets them from a step.
- **The drop latch.** `ENTER_ROOM` sets `DROP_LATCH` in every even-numbered
  room, and all four rooms with ceiling drops are even-numbered, so nothing
  drops until something is picked up (`PICK_UP_VALVE`) or an extra life
  taken (`EXTRA_LIFE`), which clear it. `DROPPING` makes them fall one at a
  time.
- **The fragile things and the mice** (*measured*): in room $72 (no robot)
  the two clockwork mice broke the fragile things -- 24 built, then 20, 16,
  12, 11, 11, 10 left at 5-second intervals. The remote-controlled robots
  push them too ([`remote-robots.md`](remote-robots.md)).

## How this was found

Read, against Knight Lore's movers where `matches.txt` had a match (stage 2,
ranges 1 and 2); which graphics use which routine from `UPDATES`, the rooms
from the level data. *Measured* in the simulator, the robot put in the room
by `_go` and the records read turn by turn: room $2F, a wanderer went two a
turn in V, stopped, turned a quarter and went two a turn in U, its lower
half following; room $A6, a pacer went from U 180 down to 168, back up to
184, down again; room $9C, the spark chaser came at him four a turn and
pushed him along U until both stopped (in rooms $20 and $57 it was boxed in
and only cycled its frames); room $97, one leaper rose from 64 to 112 and
fell, then the next. The drop was staged by the build's session (the latch
cleared, `RANDOM` poked to 0 at $AD2A, [`driving.md`](driving.md)).

## Confidence

*Read*; *measured* for the wanderer, the pacer, the spark chaser, the
leapers, the drop and the fragile things. The mice's speed and turns and the
slow chaser *read* only. What the creatures are meant to be is not claimed:
the listing names them by their motion.

## Knight Lore and Pentagram

`CEILING_DROP` is Knight Lore's `upd_63` (0.83), with `DROP_LATCH` for
Knight Lore's $5BC0 and `DROPPING` for its $5BBF
([`../knightlore/object-behaviours.md`](../knightlore/object-behaviours.md)).
`MOVE_TOWARDS_PLAYER`, `TOGGLE_FRAME`, `NEXT_FRAME_MOD4`, `FACE_ALONG_STEP`
and `MAKE_DEADLY` are Knight Lore's `move_towards_plyr`,
`toggle_next_prev_sprite`, `next_graphic_no_mod_4`,
`set_guard_wizard_sprite` and `set_both_deadly_flags`. The two-record
creatures, the chasers as written, the mice, the leapers and the fragile
things are Alien 8's own.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `LOWER_HALF` | `SUBB055` | $B055 | graphic 11 |
| `WANDERER` | `SUBB06B` | $B06B | graphics 94, 95 |
| `TURN_QUARTER`, `TURN_QUARTER_BACK`, `STEP_FROM_FACING`, `FACING_STEPS` | `SUBB0AD`, `SUBB0DD`, `SUBB0E7`, `DATAB108` | $B0AD-$B108 | direction bits |
| `PACER` | `SUBB110` | $B110 | graphics 86, 87 |
| `MOVE_TOWARDS_PLAYER`, `TOGGLE_FRAME`, `NEXT_FRAME_MOD4` | `SUBB165`, `SUBB185`, `SUBB18C` | $B165-$B18C | helpers |
| `SPARK_CHASER` | `SUBB19C` (range 2's `CHASER`) | $B19C | graphics 76-79 |
| `FACE_ALONG_STEP`, `PUT_UNDER_UPPER`, `JOIN_HALVES`, `PART_HALVES` | `SUBB1AE` ... `SUBB20B` | $B1AE-$B20B | the two halves |
| `STILL_DEADLY`, `SPIKES` (`MAKE_DEADLY`), `DEADLY_AND_DRAW` | `SUBB29F`, `SUBB2A4`, `SUBB2B0` | $B29F-$B2B0 | deadly things |
| `SLOW_CHASER` | `SUBAA89` (range 1's `CHASER`) | $AA89 | graphics 120, 121 |
| `CLOCKWORK_MOUSE` | `SUBAAA1` | $AAA1 | graphics 116-119 |
| `LEAPER` | `SUBA8F9` | $A8F9 | graphic 130 |
| `LEAPING` | `UNKNOWN_5B43` | $5B43 | a leaper is in the air |
| `CEILING_DROP`, `THUD_ON_LANDING` | `SUBAD13`, `SUBAD54` | $AD13, $AD54 | graphic 73 |
| `FRAGILE` | `SUBA9B1` | $A9B1 | graphic 129 |

## Disassembly corrections

- Ranges 1 and 2 each named their homing thing `CHASER` ($AA89 and $B19C).
  The lead renamed them at the merge: `SLOW_CHASER` (one unit a turn,
  deadly) and `SPARK_CHASER` (four a turn, harmless, the crackle of sparks).
- `$5B43`, stage 1's `UNKNOWN_5B43`, is `LEAPING` (range 1, *measured* in
  room $97).

## Also found for the stage 3 pages (2026-09-28)

- `FRAGILE` things in room $72: 28 in the room's record and on its first turn; the mice break some while the robot is still appearing, so 24 were counted once he was playing (*measured*; the annotation said 24, corrected).
- Open question: in room $58 nothing dropped in 600 turns even with the latch cleared by a poke (the how-it-works agent's exploration), though the pokes agent saw all 16 fall there within 300 -- the conditions differed; not settled.

## Open questions

- `LOWER_HALF`'s footstep (`LOWER_HALF_STEP` $B6C0) never sounds: it tests
  for an even graphic and graphic 11 is odd. A slip, or silence meant?
  Knight Lore's walkers change graphic as they walk.
- What the fragile things (graphic 129) are for, beyond being in the way.
