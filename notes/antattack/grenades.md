# Grenades

**Question this answers:** how a grenade is thrown, how far it goes, what its
blast does, and how it can hurt the player and the rescued person.

**Short answer:** S, D, F and G throw, for 2, 4, 8 or 16 frames of flight --
and since the grenade moves a cell a frame like anything else, that is also
how many cells it goes. When the time runs out it explodes where it is: ants
at its height within four cells are blown up, within seven stunned. People
are never hurt by the blast, only by the grenade being in their own cell --
which, because the player moves before the grenade each frame, is exactly
what happens to a player who walks forward behind their own throw.

## How it works

```
MOVE_GRENADE $83E0      IX = the grenade, IY = the player
  THROW_GRENADE $8D00   in flight: time - 1; at 0 the bang; then the people check
                        else exploding: nothing
                        else S/D/F/G down and grenades left: launch
  MOVE_OR_RESPAWN $89D0 moves it a cell (or counts the blast, then home)
  BLAST_FRAME $82E0     the blast's frames $F4-$F7
  GRENADE_BLAST $8D9A   while exploding: BLAST_ANT for each ant
```

(*read*; all *played*.)

**Throwing** (*read*). The four keys are bits 1-4 of the A-G half-row, and
the flight time is simply their value: S 2, D 4, F 8, G 16 -- several held
together add up. A throw needs a grenade (`AMMO_LOW` $B430, 20 per attempt,
BASIC line 220) and takes one. It sets `THROW_TIME` ($B42E), gives the
player the arms-out pose for that frame, sets the grenade's move bit, puts it
on the player's cell facing the player's way (`COPY_POSITION`), draws it as
frame $F4, and flags `GRENADE_EVENTS` bit 0 so script 4 reprints the count
with a beep. Then, in the same frame, it moves one cell.

**Flight.** Each later frame the time drops by one and, while it lasts, the
grenade moves on a cell. It is an ordinary object with flag bit 4, so it
falls off ledges (a frame of grace, then a block a frame), steps up one-block
rises and hops onto ants, and stops against anything higher (*read*). With S
the bang came two cells ahead of the player (*measured*, simulator).

**The bang** (*read*): at zero `GRENADE_EVENTS` bit 1 (script 5, a burst of
noise), +$09 = 5, the move bit cleared. The countdown then runs 4, 3, 2, 1,
drawn as the blast, and on reaching 0 the grenade goes home to (0, $40, 0)
outside the walls. `GRENADE_BLAST` runs `BLAST_ANT` for every ant on each
frame the countdown is still non-zero after its decrement -- the bang frame
and the three after -- so an ant that walks into range during the blast is
caught too. Ranges are grid distance (|dx| + |dy|) at the grenade's own
height only: 0-4 blown up (+$09 = 5, stun cleared, bit 2 of
`GRENADE_EVENTS`, the good-shot script), 5-7 stunned for 24 frames, 8 or
more nothing. A stunned or paralysed ant is not spared: its stun is
overwritten ([`ants.md`](ants.md)).

**People** (*read*): on every frame of flight after the launch, and on the
bang frame, the grenade's cell and height are compared with the player's and
then the rescued person's. A match, if that person is not already exploding,
sets their explosion countdown to 5 and their event to 8 -- blown up, energy
to 0 ([`energy-and-events.md`](energy-and-events.md)). The blast radius does
not apply to people at all: standing one cell from the bang is safe.

**Walking into your own grenade** (*read*, then *measured* in the simulator,
2026-09-27). The player moves before the grenade in every frame. Throw while
walking and on frame 1 the player steps, the grenade is launched from the new
cell and moves one ahead; on frame 2 the player steps into that cell, and the
check runs before the grenade moves on. Staged on open ground, V and S held
together then V: the player was blown up on the second frame and energy went
from 20 to 0; S alone, standing: no harm, the bang two cells away. The
agent testing pokes saw the same live in a private `zx_server` (*watched*,
2026-09-27). So
throwing on the move is suicide unless the player stops or turns at once.
The rescued person, following one or more cells behind, is only at risk if
the grenade comes back through their cell -- a grenade that falls, or one
thrown towards them.

**The grenade's own frames.** At home +$08 is 0, so it would be drawn as its
first frame, $68-$6B, and not the in-flight $F4. Its home is outside the walls
and far from the city, so normally it is out of view; but nothing stops the
player walking out there, and with the player placed a few cells from
(0, $40) the next frame drew the grenade as frame $68 (*measured*, simulator,
2026-09-27; also *watched* live the same day). So those frames can be seen, if only by someone who walks a
long way out of the city to look.

## How this was found

Read `THROW_GRENADE`, `GRENADE_BLAST` and `BLAST_ANT`; the order of the
calls in `GAME_FRAME` suggested the self-hit, which the scratch harness then
confirmed (the player on open ground facing x up, one frame of V + S, then
V). The build's scenes `_good_shot`, `_near_miss` and `_grenade_the_rescuee` had
already played the ant hit, the stun and a grenade blowing up the rescued
person.

## Confidence

*Read*, with the self-hit, the throw distance for S and the home frames
*measured* in the simulator; the self-hit and the home frames also
*watched* live (2026-09-27).

## Disassembly corrections

- `SPRITES` ($9A00) and the build's sprite table say frames $68-$6B are not
  seen in play because the grenade at home is out of view. They are drawn
  whenever the player is near (0, $40); seen by staging the player there.
  Reaching it by walking was not tried, but nothing prevents it. The lead is
  correcting the annotation (2026-09-27).

## Also found for the how-it-works pages (2026-09-27)

- Range by key: 2, 4, 8 and 16 cells for S, D, F and G, and 18 for S and G together; holding a key throws again when the grenade is home (*measured*).
- There is no arc: the grenade climbs one-block rises, is stunned when it drops off a ledge, and a two-block wall stops it. Thrown into a three-block wall in the next cell, it climbs in the player's cell and falls back on them (*measured*).

## Open questions

- Whether a grenade can hit the rescued person's cell while they follow at a
  distance of one (they stop beside the player), for example when the player
  turns and throws back: not tried.
