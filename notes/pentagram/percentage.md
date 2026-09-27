# The percentage

**Question this answers:** how the game-over screen's percentage is worked
out, and whether 100 is reachable.

**Short answer:** rooms seen divided by two (at most 54), plus 4 for each
quest item done, plus 6 for each collectable placed: 54 + 16 + 30 = 100. A
completed game with 108 or more of the 139 rooms seen shows 100. The sum is
counted into BCD by a DJNZ loop, so a sum of 0 shows 56.

## How it works

- `MARK_ROOM_SEEN` ($C6CC, from `ENTER_ROOM`): the room's bit in `ROOMS_SEEN`
  ($A74F): byte room / 8, bit 7 - room mod 8, so room 0 is bit 7 of the first
  byte.
- `PERCENTAGE` ($C6EA, from `GAME_OVER`): count the set bits in all 31 bytes
  of `ROOMS_SEEN` (rooms go no higher than 149, so only the first 19 bytes can
  hold one), halve, cap at 54; add `QUEST_DONE` x 4 and `PLACED` x 6; then B =
  that, A = 0, and B times `ADD A,1 / DAA`: `PERCENT` + 1 = A, `PERCENT` = the
  last carry (the hundreds). Printed at buffer row 95, column 144, after the
  game-over screen's third line: three digits at 100, else two with a leading
  zero.
- One room seen counts nothing, since the rooms are halved first; two count 1.
- **The 56 per cent bug.** With a sum of 0 the DJNZ runs 256 times, and 256
  in BCD, less the hundreds, is 56. A player who loses all five lives without
  leaving the room he started in (one room seen) is told 56 per cent.

## How this was found

*Measured* in SkoolKit's simulator by setting `ROOMS_SEEN`, `QUEST_DONE` and
`PLACED` and calling `PERCENTAGE` (stage 2, range 4): rooms / quest items /
collectables 1/0/0 and 0/0/0 gave 56; 2/0/0 and 3/0/0 gave 01; 108/4/5 and
139/4/5 gave 100; 107/4/5 gave 99; 20/1/1 gave 20. Room bits: room 0 went to
byte 0 bit 7, 7 to byte 0 bit 0, 82 to byte 10 bit 5, 138 to byte 17 bit 5.
Agent 1 confirmed the 56 by losing the last life in the start room. The
stage 1 quest session ended with 36.

## Confidence

*Measured*.

## Knight Lore

Knight Lore keeps the same kind of visited map (a bit per room, set on
entering) but works its percentage out differently: (rooms + 2 x charms) x
100 / 156 by a fixed-point multiply ([`../knightlore/winning.md`](../knightlore/winning.md)).
Pentagram weights its three parts to add up to 100 and counts in BCD with a
loop; `PERCENTAGE` matches nothing in Knight Lore above 0.40.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `MARK_ROOM_SEEN` | `SUBC6CC` | $C6CC | set the room's bit |

## Open questions

None.
