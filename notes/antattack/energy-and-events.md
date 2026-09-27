# Energy and events

**Question this answers:** how a bite, a blast, a bad fall or a step becomes
lost energy, a message or a sound -- and what happens when both people have
something happen in the same frame.

**Short answer:** the movers only record what happened, as a bit in each
object's event byte (+$0F): 1 a step, 2 a bad fall, 4 bitten, 8 blown up.
Once a frame, after drawing, `HANDLE_EVENTS` ($8F00) reads and clears the
player's and the rescued person's and acts: a click for a step, a message for
a bad fall, a point of energy and a message for a bite, all the energy for a
blast. Each person has 20 energy per attempt; either reaching 0 ends the
attempt. But a bad fall by either person in the same frame as any event of
the other's loses the other's event entirely: a bite that costs nothing.

## How it works

**Who writes the events** (*read*):

| Event | Written by | When |
|---|---|---|
| 1 a step | `MOVE_OBJECT` $8852; `LANDED` $8872 | a successful step; a landing from a short fall |
| 2 a bad fall | `LANDED` $8872 | a fall count of 5 or more ([`falling.md`](falling.md)) |
| 4 bitten | `BITTEN` $88A0 | a block (an ant) in the object's own cell |
| 8 blown up | `THROW_GRENADE` $8D6C, $8D8F | the grenade in the person's cell |

`MOVE_OBJECT` writes them for every object, but only the two people's are
read.

**`HANDLE_EVENTS`** (*read*): E = the player's event, D = the rescued
person's, both bytes cleared. Then:

```
D OR E = 0        nothing
D OR E = 1        a step: NOISE for 5 bits (a click); return
E = 2             script 1, the player's bad-fall message (which leaves D = 0)
D = 2             script 2, theirs; return
E = 8             player's energy = 0; script 6
E = 4             player's energy - 1 (if not already 0); script 7, or 14 at 0
                  (then, for either, script 8 reprints the player's energy)
D = 8, D = 4      the same for the rescued person: scripts 9, 10 or 15, and 11
```

Energy is `PLAYER_ENERGY_LOW` ($B432) and `RESCUEE_ENERGY_LOW` ($B434); the
high bytes are always 0, there only because the ROM's number printer
(OUT-NUM-2) takes two bytes big-endian. BASIC sets both to 20 at every
attempt. `CHECK_GAME_OVER` ends the attempt four frames after either reaches
0, and BASIC then offers another go at the same level with the clock
unchanged ([`basic-and-levels.md`](basic-and-levels.md)). A bad fall costs
no energy, only the stun and the message (*measured*, simulator:
[`falling.md`](falling.md)).

**Two events in one frame -- the lost event** (*read*, then *measured*,
simulator, 2026-09-27; also *watched* live the same day by the agent testing
pokes). Two things go wrong in the bad-fall branch:

- when the rescued person had the bad fall (D = 2), the branch plays script 2
  and returns, so the player's event, already cleared, is never looked at;
- when the player had it (E = 2), script 1 is played through
  `PLAY_SCRIPT_ONE`, which loads the script number into D (`PLAY_SCRIPT`'s
  `LD D,A`), and `RUN_SCRIPT` counts D down to 0 -- so the rescued person's
  event is gone by the time it is tested. That includes their own bad fall:
  with both falling badly in one frame, only the player's message plays.

Staged by writing the two event bytes just before a frame and reading the
energies after:

| Player's event | Rescued person's | Energies before | After |
|---|---|---|---|
| 4 bitten | 0 | 20, 20 | 19, 20 |
| 0 | 4 bitten | 20, 20 | 20, 19 |
| 4 bitten | 2 bad fall | 20, 20 | 20, 20 -- the bite lost |
| 8 blown up | 2 bad fall | 20, 20 | 20, 20 -- the blast lost |
| 2 bad fall | 4 bitten | 20, 20 | 20, 20 -- the bite lost |

In play this needs a bad landing on exactly the frame of a bite or a blast,
so it will be rare (*assumed*); when it happens it is in the player's favour.
A step alongside any other event also loses its click, which nobody would
notice.

**Bites repeat** only as often as an ant re-enters the cell: the bitten
person rises a block onto the ant, so the next move finds the cell clear
(*read*; see [`movement-and-collision.md`](movement-and-collision.md)).

## How this was found

Reading `HANDLE_EVENTS` for this note, the early `RET` after script 2 stood
out, and following `PLAY_SCRIPT_ONE` into `PLAY_SCRIPT` showed D being
reused. The table above was run with the scratch simulator harness on
2026-09-27; the (2, 4) row, found by the run rather than by reading, is what
showed the second half of the bug.

## Confidence

*Measured* in the simulator for five combinations and *watched* live. Not
checked: both bad falls in one frame (read: only script 1 plays).

## Open questions

- None about the mechanism. A pokes page could offer the fix (return D after
  script 1, and fall through after script 2), but that is a patch, not a
  poke.
