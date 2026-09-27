# Objects and the inventory

**Question this answers:** what can be picked up, how picking up and dropping
work, and what each object is for.

**Short answer:** eighteen collectables ($80-$8E): four keys, the three pieces
of the A.C.G. key, a crucifix, a spanner, a leaf-like object the mummy
follows, and eight more that nothing in the code asks for. The player carries
three at most, in a queue: SYMBOL SHIFT on an object picks it up and pushes
the oldest out at the player's feet; SYMBOL SHIFT on nothing moves the queue
along one, so three presses with nothing underfoot drop the oldest. The
humpback eats the eight purposeless ones if they are in its room.

## How it works

**The collectables** (*read* from the template and the code; pictures drawn
with the game's own routine in the simulator, 2026-09-27, and described):

| Code | Record | Colour | What | Used by |
|---|---|---|---|---|
| $81 x4 | $EAC0-$EAD8 | green, red, cyan, yellow | keys | `DOOR_NEEDS_KEY` ([`keys-and-locked-doors.md`](keys-and-locked-doors.md)) |
| $8C, $8D, $8E | $EAA8-$EAB8 | yellow | the A.C.G. key in three pieces | `ACG_DOOR` ([`acg-key-and-winning.md`](acg-key-and-winning.md)) |
| $8A | $EB08 | yellow | a crucifix, room $05 | `MOVE_DRACULA`: carrying it makes him flee |
| $8B | $EB10 | cyan | a spanner, room $30 | `MOVE_FRANKENSTEIN`: carrying it, touching him kills him |
| $80 | $EAE0 | red | looks like a leaf; room $09 | `MOVE_MUMMY`: in its room, the mummy walks to it and sends it to room $6B |
| $82-$89 | $EB18-$EB50 | various | a bottle, a round coin-like thing, a quill, a hook, a broken glass, a wheel, a money bag, a skull (the look of 16-pixel pictures) | nothing but `MOVE_HUMPBACK` |

(The eight have no reader but `SCAN_COLLECTABLES` ($8ADB), the humpback's
search, and `FIND_CARRIED`'s three callers ask only for the key, the crucifix
and the spanner -- *read*, every caller listed.)

**Picking up** (`PICK_UP` $92F5, the handler for $80-$8E, *read*, then
*measured*): each pass, if the pick-up key is held (`PICKUP_KEY` $5E20, set
by `READ_PICKUP_KEY` from SYMBOL SHIFT), the key press not yet used (the two
low bits of `PICKUP_USED` $5E1F clear), the player in play and within 12
pixels: mark the press used, then

1. `DROP_CARRIED` ($9358): if the third slot holds something, rebuild its
   record at the player's feet (its sprite and colour, the player's room and
   position) and draw it, with a beep (`SHORT_HIGH_BEEP` $A3C2: 128 cycles of
   half-period $20 -- about 30 ms, an octave above the pick-up's);
2. `SHIFT_CARRIED` ($934C): slots one and two move to two and three;
3. `REMEMBER_CARRIED` ($9326): slot one = the object's record address, its
   sprite, its colour; the object is erased and its record emptied; a beep
   (`BEEP_ENTRIES` $A3BD: 64 cycles of half-period $40, also about 30 ms);
4. `DRAW_INVENTORY` ($A13B) redraws the three slots on the scroll.

The inventory is `CARRIED` ($5E30), three slots of four bytes, newest
first. Staged in the simulator: holding SYMBOL SHIFT on the yellow key put it
in slot one and emptied its record.

**Putting down** (`PUT_DOWN` $93E3, *read*, then *measured*): run every pass
by the drop controller at $EE58 ([`records.md`](records.md)). If the key is
held and the press is unused, it marks it used and does steps 1, 2 and 4
with slot one cleared instead of filled. If the key is up, it clears the
"used" bit, so one press does one thing. A press on nothing therefore shifts
the queue: in the simulator, a second press moved the key to slot two and
dropped nothing; the object falls out only when pushed past the third slot.
Picking up on the same pass sets bit 0 as well, which `PUT_DOWN` sees and
only clears -- so a press on an object is a pick-up, not both.

**Gravestones** (sprite $8F) are not collectable: their handler only draws
them ([`food-and-health.md`](food-and-health.md)).

**The humpback** takes any of $82-$89 lying in its room and empties its
record: the object is gone for the game ([`monsters.md`](monsters.md)).

## How this was found

Read the handlers of $80-$8F, the three inventory routines and every caller
of `FIND_CARRIED`. The pictures were drawn with the build's `render_sprites`
(the game's own `DRAW_TITLE_ICONS` path) into the scratchpad and looked at.
Pick-up and the queue were staged in `aticatac_t16.py`.

## Confidence

The mechanics *read* and *measured*; the objects' uses *read*; the names of
$80 and $82-$89 are descriptions of small pictures, not the game's words.

## Renamed routines

Applied to the annotations on 2026-09-27; the build verified byte for byte.

| New name | Old name | Address | Role |
|---|---|---|---|
| `READ_PICKUP_KEY` | `READ_FIRE_ROW` | $938B | SYMBOL SHIFT into `PICKUP_KEY` |
| `PICKUP_USED` (equate) | `CARRYING` | $5E1F | bit 1: this press has been acted on; bit 0: a pick-up happened this pass |
| `DROP_GRAVESTONE` | `DROP_OBJECT` | $95A9 | the gravestone; `DROP_CARRIED` puts objects down |
| `DROP_CONTROL_ROOM` (equate) | `MOVE_ROOM` | $EE59 | the drop controller's room byte |
## Disassembly corrections

All applied to the annotations, the ref and the build on 2026-09-27 (the old names are used below), except where marked.

- `PICK_UP` at $9312: "Mark that something is being carried". The bits say a
  key press has been used, not that anything is carried; `PUT_DOWN` clears
  them when the key is released.
- `PUT_DOWN`: "the flags at $5E20 and $5E1F have to agree that something is
  being carried" -- they must say the key is held and not yet used. And it
  does not "take one back out of the slots and leave it where the player is
  standing": it clears slot one and shifts the queue; only the third slot's
  object is put down.
- `READ_FIRE_ROW`: the key it reads (bit 1 of the B-SPACE half-row) is SYMBOL
  SHIFT, the pick-up and drop key, not fire.
- `DROP_OBJECT` is the gravestone routine; `DROP_CARRIED` puts objects down.
  (Both descriptions are right; the names invite confusion.)

## Open questions

- Room $6B and object $80: what the mummy's errand achieves, if anything,
  beyond distracting it.
- Whether the original instructions call the pick-up key something the code
  does not show (only SYMBOL SHIFT is read, whatever the control method).
