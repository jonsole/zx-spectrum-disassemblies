# The remote-controlled robots

**Question this answers:** how the buttons on the floor drive the other
robots, and what the robots are for.

**Short answer:** standing on one of four buttons makes the robot in
control step two units a turn in that button's direction; a pad holds it
still. Control passes to the other robot each time the player steps off
(room $0B, the only room with two). The robots are harmless; they push
things, and so can break the deadly fragile things (graphic 129), which lie
in six of their eight rooms -- what they are there for, *inferred*.

## How it works

- **Buttons and pad** (`REMOTE_BUTTON` $AA63, graphics 122 and 123;
  `REMOTE_PAD` $AA4D, graphic 128): a non-zero +$0B -- the Z step the
  collision code hands to what is landed on -- means something stands on it.
  The step is cleared and bits 0-6 of `REMOTE_ORDERS` ($5B42) set: 1 for the
  pad, 2 + 2 x (the graphic AND 1) + the mirror bit for a button (2-5); bit
  7 is kept.
- **The robots** (`REMOTE_ROBOT` $A9C7, graphics 124-127): bit 7 of
  `REMOTE_ORDERS` means a robot has control; on the robot, bit 7 of +$10
  means it has control and is waiting, bit 6 that it is moving. An order is
  taken (the orders become $80) and turned into steps from `REMOTE_STEPS`
  ($AA43: none; -2 U; +2 V; +2 U; -2 V). A turn with no order while it is
  moving gives up control (bit 7 of the orders and bit 6 of +$10 cleared),
  and the next robot to run claims it. With an order it steps to the next of
  its four graphics, moves, and warbles (`WARBLE_SOUND`); without one it
  only falls, with a note by its height if it moves -- falling or pushed
  (that path never ran in the build's sessions).
- **Entering a room** clears `REMOTE_ORDERS` (`ENTER_ROOM` $CAA2).
- **The rooms** (*read* from the data): robots in $0B (two), $44, $56, $6A,
  $6B, $74, $8B and $D9 (one each), all with a pad and four buttons; fragile
  things in $44, $56, $6A, $72, $74, $8B and $D9
  ([`creatures.md`](creatures.md)).

## How this was found

Read (stage 2, range 1), then *measured* in room $0B, the robot dropped onto
each button and the pad in turn with the build's `_onto`, stepping off
between: the claim (bit 7 of +$10) moved from one robot to the other at
every step-off; the orders were $82, $84, $81, $83, $85 for the buttons (122
plain), (123 plain), the pad, (122 mirrored), (123 mirrored); and the robot
in control moved -U, +U, not at all, +V, -V. The build's "remote control"
session does the same.

## Confidence

*Read* and *measured*. That the collision code hands the lander's Z step to
what it lands on is *read* in `ADJ_DZ_FOR_OBJ_INTERSECT`
([`collision.md`](collision.md)); range 1's draft had it as an inference
from Pentagram's notes.

## Knight Lore and Pentagram

Nothing like it in either (no match in `matches.txt`).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `REMOTE_ROBOT` | `SUBA9C7` | $A9C7 | graphics 124-127 |
| `REMOTE_STEPS` | `DATAAA43` | $AA43 | five (U, V) step pairs |
| `REMOTE_PAD` | `SUBAA4D` | $AA4D | graphic 128: order 1 |
| `REMOTE_BUTTON` | `SUBAA63` | $AA63 | graphics 122, 123: orders 2-5 |

## Open questions

- In the one-robot rooms giving up and reclaiming control does nothing
  visible; whether the pad has another use there was not tested.
- What the robots are for in each room -- which fragile things, or which
  doorway, they clear -- is for the world page to show room by room.
