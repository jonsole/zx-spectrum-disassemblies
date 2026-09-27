# The ants

**Question this answers:** how an ant decides where to go, how fast it goes,
how it bites, and what paralysing, stunning and blowing up do to it.

**Short answer:** each frame an ant takes one step the way it faces and then
compares its distance to the player with what it was: closer, it keeps going
(and within three cells turns to face the player); not closer, it stops and
turns left or right at random. There is no path-finding; the city's walls do
the rest. The first ant nearly always moves; the other four skip one frame in
every `sp` (2 at first, rising to 4). An ant is a bit in the city map, which
makes it solid and makes a bite nothing more than an ant walking into
someone's cell. Blown-up ants go home and come back; a paralysed ant stays
where it is until the next level -- or until a grenade wakes it.

## How it works

```
MOVE_ANTS $80D3        IX = each ant in turn, IY = the player
  ANT_TURN $8A5D       +$06 = $FF: paralysed, do nothing
                       BLAST_FRAME (draw the blast while +$09 runs)
                       +$0E - 1; at zero reload it from +$0D and skip this frame
    MOVE_ANT $8A00     XOR the ant out of the map
                       MOVE_OR_RESPAWN (count the blast down, go home, or MOVE_OBJECT)
                       XOR it back in where it is now
                       distance to the player now (C) and before (B)
                       closer:   animation frame 0/1 alternates; within 3, face the player
                       not:      animation 0; RANDOM -> facing + 1 or - 1
```

(*read*; all *played*.)

**Distance** is `DISTANCE` ($8A80): |dx| + |dy| on the grid, ignoring height.
**Facing the player** is `DIRECTION_TO` ($8A91): straight along the axis if
they share a row or column, otherwise one of the two directions that closes
the gap (*read*). An ant always has its move bit set, so it walks every frame
it moves; blocked, it stays put, its distance does not shrink, and it turns
at random -- that is how ants get round corners, by chance (*read*).

**Speed** (*read*): +$0D is how many frames in which the ant misses one step.
The first ant's is 20 (BASIC line 140), so it moves 19 frames in 20; the
other four get BASIC's `sp` (line 190): 2 on levels 1-4 (half speed), 3 on
levels 5-8, 4 on levels 9-10. The counts at +$0E start staggered (1, 4, 3, 2,
1) so the slow ants do not all pause on the same frame. On level 1 the fast ant
took 57 steps in 60 frames and the others 30 (*watched* live, 2026-09-27) --
19 in 20 and 1 in 2, as the code says.

**The random generator** (`RANDOM` $8360, *read*): a 32-bit shift register at
`RANDOM_BITS` ($B428-$B42B), fed back from two bits of its first byte; the
carry out picks the turn. BASIC resets it to the same value at every level
start and every retry (line 200). It is also stepped by every burst of noise
(`NOISE` takes a random speaker bit each time round): the click for a frame
in which the player or the rescued person took a step steps it five times,
the bang of a grenade 1024 times. So the ants' choices depend on everything that made a
noise since the level began -- including the player's own footsteps -- and
the same keys on the same frames replay a level exactly (*read*; the
replaying is how the build's scripted sessions stay repeatable, *played*).

**Ants are in the map** (`TOGGLE_MAP_BIT`, *read*): each ant is XORed out of
its cell before it moves and back in afterwards, so to everything else an ant
is a block. The player cannot walk into one; the grenade and the rescued
person step up over one; the player can stand on one. And a bite is an ant
walking into the cell of a person (who is not in the map), after which that
person's own move finds a block in their cell ([`movement-and-collision.md`](movement-and-collision.md),
[`energy-and-events.md`](energy-and-events.md)). After a second of play the
map differed from the tape in exactly the five ants' cells (*measured*,
simulator, 2026-09-27).

**Paralysis** (`PARALYSE_ANT` $8BD1, *read*; *played* in the build's
`_drop_on_ant` scene). Anyone landing at height 1 on a cell holding an ant that is not
exploding and not already paralysed sets its +$06 to $FF and plays script 16.
`ANT_TURN` then returns at once every frame: no move, no animation, but it
stays in the map, a block to stand on. BASIC clears it at the next attempt
(line 140's DATA sets +$06 to 0).

**Grenades and ants** (`BLAST_ANT` $87A0, *read*): for each of the four
frames the blast lasts, every ant at the grenade's height and not already
exploding is checked: within four cells it is blown up (+$09 = 5, stun
cleared, the good-shot script); five to seven, stunned for 24 frames. A
blown-up ant shows the blast for five frames, then `MOVE_OR_RESPAWN` sends it
home and it chases again: ants are never killed for good.

**A blast wakes a paralysed ant** (*read*, then *measured* in the simulator,
2026-09-27). `BLAST_ANT` does not check for paralysis: it overwrites +$06.
With a paralysed ant staged eight cells ahead of the player and a grenade
thrown with S (so the blast is six away), the ant's +$06 went from $FF to 24
and counted down; staged three ahead (blast one away), it was blown up, went
home five frames later and walked on. So a near miss turns paralysis into a
24-frame stun, and a hit into a respawn. The near miss was also *watched*
live (private `zx_server`, 2026-09-27, by the agent testing pokes): the
paralysed ant walked again.

**Homes** (*read*, BASIC line 140-180): x $B2, $B4, $B6, $B8, $BA on row y
$A8, height 0 -- a row roofed by blocks at height 1. Every attempt starts with
the ants' explosion countdown at 1, so the first frame sends them all home.
The fast ant's home cell, ($BA, $A8), also has a ground block in the map. Sent
home, that ant XORs its bit in there and so *clears* the block while it
stands on it; on its next move it XORs out, the block reappears in its own
cell, and it walks off; the cell was back to normal a frame later (*measured*,
simulator, sending each ant home in turn). Harmless; perhaps an ant baked
into the map when the tape was made (*assumed*).

**Frames $F0-$F3** sit just before the ants' walking frames and are drawn on
the Sprites page as an ant on its back. No code can produce them: an ant's
frame is $F8 + 4 x (0 or 1) + facing, a person's first frame + 4 x 0-4 +
facing, and the blast $F4-$F7 (*read*). A paralysed ant keeps its last
walking frame. That they were meant for paralysed ants is a guess
(*assumed*).

## How this was found

Read `MOVE_ANTS` through `MOVE_ANT`, `DISTANCE`, `DIRECTION_TO`, `RANDOM` and
`NOISE`; the speeds from BASIC lines 90, 140-190. The waking and the home cell
were found while checking `BLAST_ANT` and the ants' DATA for these notes, and
confirmed with the scratch simulator harness on 2026-09-27.

## Confidence

The chase, speeds, paralysis and blast are *read* and ran in the build's
scenes (*played*); the waking and the home cell *measured* in the simulator;
the speeds, the waking and the random generator's reset *watched* live
(2026-09-27).

## Disassembly corrections

- The annotation at `MORE_SPRITES` ($B700) says what $F0-$F3 are "has not been
  checked", while the build's sprite page and the How-it-works leftovers call
  them an ant on its back. They should agree; which is right needs someone
  to look at the drawn frames (the build draws them). The agent testing pokes
  confirmed live that nothing writes them to +$08. The lead is correcting the
  annotation (2026-09-27).

## Also found for the how-it-works pages (2026-09-27)

- An ant turns to face the player when the distance is under 4 -- three cells or fewer (`CP 4 / RET NC` at $8A3B; the annotation said four and is corrected).
- `DIRECTION_TO`'s answers round a player form a pinwheel (the Ants page tables them); speeds measured match 60 - 60/+$0D moves a second exactly (*measured*).
- `BLAST_ANT`'s stun is 24 of the ant's turns, not frames: it counts down only on turns the ant takes, so a half-speed ant is stunned for about 48 frames. A stunned ant spins, turning at random every turn (*measured*).
- Ant 1's home cell ($BA,$A8) holds a pillar block at height 0 on the tape; arriving there XORs it out, and for its first frames the ant counts as bitten in its own cell while ant 2 walks into the same cell. Nothing visible comes of it (*measured*).
- A waiting person cannot be bitten: `MOVE_OBJECT` never runs for them, and an ant walked through her cell with her energy staying at 20 (*measured*, staged).

## Open questions

- What the ants do outside the walls, where nothing blocks them and the
  player may lead them (not observed).
- How often in real play an ant ends up stuck: the random turn is the only
  way round an obstacle.
