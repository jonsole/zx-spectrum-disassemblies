# Falling

**Question this answers:** how falls work -- when one starts, how fast it
goes, what makes a bad fall, and which landings the game never notices.

**Short answer:** with nothing underneath, an object gets one frame of grace
(it can still walk) and then drops a block a frame. The fall count at landing
is one more than the blocks dropped. A count of 5 or more -- a drop of four
blocks or more -- is a bad fall: stunned for eight frames per count and the
bad-fall message, but no energy lost. Shorter falls stun briefly and just
click. A fall that ends while the object is stunned is never landed at all,
and neither is dropping onto the other person's head.

## How it works

```
MOVE_OBJECT $8800   nothing below (TEST_BELOW at height - 1)?
  FALL $8880          bit 3 of the flags: never falls (set by nothing: never runs)
                      fall count + 1; if it was 0: walk on as if standing
                      else: height - 1
  ... support found, not stunned, fall count >= 2:
  LANDED $8860        count < 5: stun = count, event 1 (a click)
                      count >= 5: stun = 8 x count, event 2 (bad fall), count = 0
                      now at height 1: PARALYSE_ANT (an ant underneath?)
  next frames:
  STUNNED $88B0       stun - 1, and clear the fall count
```

(*read*.)

**Measured** in the simulator (2026-09-27): the player placed over open
ground at heights 3, 4 and 5 and left alone, the height, fall count and stun
read after each frame:

| Drop | Frames falling | Fall count at landing | Stun | Event | Energy |
|---|---|---|---|---|---|
| 3 blocks | 1 of grace + 3 | 4 | 4 | a step (click) | 20 -> 20 |
| 4 blocks | 1 + 4 | 5 | 40 | bad fall | 20 -> 20 |
| 5 blocks | 1 + 5 | 6 | 48 | bad fall | 20 -> 20 |

The five-block case matches the annotation (48). At about 6.5 frames a second
a 40-frame stun is some six seconds on the ground. A bad fall costs no energy:
`HANDLE_EVENTS` only plays the message for event 2 (*read*, and *measured*
above).

**The grace frame** is what makes both stepping off a ledge and jumping work:
on the first frame with nothing below, `FALL` jumps back into `MOVE_OBJECT`'s
walk, so a walking object takes one more step before it drops, and a jumping
player can walk forward onto a block one high
([`movement-and-collision.md`](movement-and-collision.md)).

**Falls that are never landed** (*read*, both *played* in the build's staged
scenes):

- **While stunned.** `STUNNED` clears the fall count every frame it runs, so a
  fall that reaches the ground while the object is still stunned lands with a
  count of 0: no stun, no event, no bad fall. The rescued person starts every
  level stunned for 4 frames (line 120's DATA) -- but since the waiting person
  is not moved at all ([`rescue-and-scoring.md`](rescue-and-scoring.md)),
  that stun only counts down once they have been found. The build's
  `_their_fall` scene has to clear that stun for the fall to land.
- **Onto each other.** While the rescued person is following, `SHARE_CELL`
  (run before they move, after the player has) clears the player's fall
  count and both stuns whenever the two are in one cell and at most one
  block apart. So the player dropped three blocks onto the rescued person's
  head makes no bad fall and no search for an ant underneath.

**Landing on an ant.** A landing at height 1 means the object came down on
something at ground level, so `LANDED` asks `PARALYSE_ANT` whether one of the
five ants is in that cell ([`ants.md`](ants.md)). `LANDED` runs for anyone
who falls -- the player, the rescued person, a grenade dropping off a ledge
in flight -- so any of them can paralyse an ant (*read*; only the player's
landing was *played*).

**No acceleration, no damage by height** beyond the stun: a block a frame
however far, and the stun grows linearly with the count (*read*).

## How this was found

Read `MOVE_OBJECT`, `FALL`, `LANDED`, `STUNNED` and `SHARE_CELL`. The
thresholds were then measured with the scratch harness on 2026-09-27
(`_open_ground` from the build to find a clear square). The build's staged
scenes `_nasty_fall`, `_their_fall`, `_on_the_rescuees_head`,
`_drop_on_ant` and `_drop_on_a_block` had already run each branch.

## Confidence

The rules are *read*; the thresholds and stuns *measured* in the simulator;
the unlanded falls *played*, and a fall that starts stunned keeping its stun
and never landing was *watched* live (private `zx_server`, 2026-09-27, by the
agent testing pokes).

## Open questions

- Whether the "never falls" flag (bit 3) was meant for the grenade in flight
  or for something removed; nothing sets it ([`leftovers.md`](leftovers.md)).
