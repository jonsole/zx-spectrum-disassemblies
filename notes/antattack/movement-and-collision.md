# Movement and collision

**Question this answers:** how anything moves -- walking, turning, jumping,
climbing -- what stops it, and how the people, the ants and the grenade
collide with each other.

**Short answer:** one routine, `MOVE_OBJECT` ($8800), moves everything, a
whole cell or a whole block a frame. The only solid thing is the city map;
the ants make themselves solid by being bits in it. So a wall and an ant
stop you the same way, and an ant arriving in your own cell is a bite. A
jump is one block up for one frame, and a fall does not start until the frame
after there is nothing underneath -- which is what lets a jump carry you
forward onto a block one high.

## How it works

`MOVE_OR_RESPAWN` ($89D0) first: while the explosion countdown (+$09) runs,
count it and do not move; at zero, go home. Otherwise `MOVE_OBJECT`, whose
tests run in this order (*read*):

| Test | Outcome |
|---|---|
| nothing to stand on at height - 1 (`TEST_BELOW`) | `FALL`: the first frame, carry on as if standing (below); after that drop a block ([`falling.md`](falling.md)) |
| a block in the object's own cell at its own height (`TEST_MAP_BIT`) | `BITTEN`: event 4, then `RISE` -- up a block if free, otherwise walk |
| stunned (+$06) | `STUNNED`: count it down, clear the fall count; nothing else |
| fall count 2 or more | `LANDED` ([`falling.md`](falling.md)) |
| jump bit (+$07 bit 1) | `RISE`: up a block if the cell above is free; if not, walk instead |
| move bit (+$07 bit 2) | `STEP` a cell the way it faces, if the cell there at this height is free: event 1 (a step) |
| blocked | `STEP_UP`, only with flag bit 4: up a block if the cell above is free |

**What is solid** (`TEST_MAP_BIT`, `TEST_BELOW`, *read*): a map bit, height -1
(the ground), height 7 and above (a ceiling) -- and, for an object with flag
bit 0, the object IY points at when it is exactly one below in the same cell.
That last rule is only for the two people: the player can stand on the
rescued person and the rescued person on the player. Neither person is in
the map, so to each other they are otherwise not solid: they can share a
cell at the same height (*read*; `SHARE_CELL` and `ON_TOP` handle it,
[`rescue-and-scoring.md`](rescue-and-scoring.md)).

**Who blocks whom** (*read*):

| Mover | walls | ants | the other person | the grenade |
|---|---|---|---|---|
| player | blocked | blocked (an ant is a map bit) | passes through, can stand on | passes through |
| rescued person | blocked, steps up one block | blocked, steps up onto it | passes through, can stand on | passes through |
| grenade | blocked, steps up one block | steps up over it | passes through (and blows them up: [`grenades.md`](grenades.md)) | -- |
| ant | blocked | blocked | walks into their cell: a bite | passes through |

An ant is XORed out of the map while it moves, so it does not collide with
itself; the other four still do.

**Walking and turning.** The player's V key sets the move bit and C the jump
bit, fresh every frame (`READ_CONTROLS`, *read*). SYMBOL SHIFT alone turns
the facing one way (-1) and M alone the other (+1), a quarter turn per frame
held, and not while stunned. The facing is absolute (0 is y up) and the
sprite drawn is turned for the view, so the controls are relative to the
character, not the screen. A step is one cell per frame; the step event
makes a click ([`energy-and-events.md`](energy-and-events.md)).

**Jumping and climbing** (*measured*, simulator, 2026-09-27; the player on
open ground facing a one-block wall):

| Keys | Frame by frame |
|---|---|
| V alone | blocked; stays put (the player has no flag bit 4, so no step up) |
| C alone | up to height 1; a frame hanging there (the fall's first frame); down to 0; landed with a fall count of 2, stunned 2 frames |
| C and V, then V | up to 1; the fall's first frame walks forward onto the wall; on along its top; off the end, hangs a frame, drops, lands stunned 2 |

So the player climbs by jumping with V held, one block at a time; nothing
two or more high can be climbed without something to stand on. A standing
jump costs about five frames and a short stun. The rescued person and a
grenade in flight need no jump: flag bit 4 lets them step up a one-block rise
when they walk into it (*read*; `STEP_UP` ran in the playthrough, *played*,
but which of the two took it was not recorded).

**Bites.** The only way for an object's own cell to hold a block at its own
height is for an ant to walk into it, since the people are not in the map and
the walls do not move (*read*). The bitten object gets event 4 and rises a
block -- onto the ant, which is now under it -- or, with no room above, walks.
The same test runs for everything, so an ant too can be "bitten" if a phantom
block ends up in its cell: moving an ant's record without its map bit, as an
early version of the build's scenes did, leaves a block behind and puts one
in the ant's own cell, and the ant is promptly bitten and pushed up (*played*,
recorded in the annotations at `TOGGLE_MAP_BIT`).

## How this was found

Read `MOVE_OBJECT` and the routines it branches to, with `TEST_MAP_BIT` and
`TEST_BELOW` for what counts as solid. The jump and climb were run in the
simulator for these notes (a scratch harness stepping `GAME_FRAME`,
2026-09-27): the player placed beside the first one-high wall found in the
map, with C, C + V and V held. The bites ran in the build's staged `_bitten`
and `_ant_through_rescuee` scenes.

## Confidence

The rules are *read*; the jump and climb *measured* in the simulator; bites
*played*. Nothing here has been checked live.

## Also found for the how-it-works pages (2026-09-27)

- No carrying: whoever is on the other person's head is left in mid-air when they move, and falls. A one-cell gap can be walked over because of the grace frame, but a jump at it drops you in (*measured*, 17 set pieces on the Movement page).

## Open questions

- Whether the player can be carried: standing on the rescued person while they
  walk, the player is not moved with them (nothing copies a velocity) --
  *read*, not tried; the player would simply be left with nothing underneath
  and fall.
