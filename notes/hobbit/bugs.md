# Bugs and traps

**Question this answers:** what in the game does not work as it evidently
should, and which of its traps kill or strand a player with no fair warning
-- each argued from the code and, where it could be, run.

**Short answer:** the known bugs are the unreachable 100% score, a fight's
wear-down that uses a rotate for a shift, a wound table read one entry late,
a FILL that can never work, a JUMP ONTO that jumps into text, a hidden
road that a LOAD can lose, and a fight's jostle that turns every downward
step into zero. The traps are the forest road (every way out
kills), the deep bog (death on arrival), the closed barrel (dark inside, and
OPEN needs light), and BREAK held at the end of a tape block (the machine
restarts). Five of the 59 sentence patterns have no handler anywhere.

## The list

| # | What | Evidence | Where |
|---|---|---|---|
| 1 | **The score stops at 75%.** Only first arrivals score, and the fourteen scoring places total 750 of the 1000 `SHOW_SCORE` is written for. | read, watched, searched | [`scoring.md`](scoring.md) |
| 2 | **A wound wears the target down erratically.** The margin is halved with `RRCA`, which rotates bit 0 into bit 7: an odd margin takes nothing from a weak target and 129 or more from a strong one. | read; measured in four fights with Thorin | [`fighting-and-dying.md`](fighting-and-dying.md) |
| 3 | **`WOUNDS` is read one entry late.** The index is 2 x margin for margins 1-16, so entry 0 (the "seem tired" message) is never used and a margin of exactly 16 takes the first two bytes of `ONE_PLACE`'s code, $2ADD, as a message address -- in the ROM. | read; the ROM "message" run and printed garbled words | [`fighting-and-dying.md`](fighting-and-dying.md) |
| 4 | **FILL can never work.** `DO_FILL` fetches a fresh water and puts it in the barrel through `DO_PUT_IN`, which begins by refusing a liquid. | read; measured: at the long lake with the barrel empty and open, FILL BARREL WITH WATER was refused | [`objects.md`](objects.md) |
| 5 | **JUMP ONTO jumps into a message.** `JUMP_ONTO_BARREL` has `JP NZ,$B301` where the message at $B301 was surely to be printed (`LD HL,$B301` and a jump to `RUN_MESSAGE`). | read; not reached in a quick test | the listing at $AA3A |
| 6 | **A LOAD can lose the hidden road.** The shut road's record lives in an instruction operand ($A7D1) that SAVE does not write; after a new game or a reload, Elrond reopens the new game's road, not the loaded one's. | read | [`save-load.md`](save-load.md) |
| 7 | **The "already put back" flag is never set.** `ROAD_OPEN` ($B6F1) is cleared and tested but never set, so Elrond rewrites the road each time he reads the map. Harmless. | read, watched, searched | [`hidden-roads.md`](hidden-roads.md) |
| 8 | **Five sentence shapes do nothing.** PUT ON, TAKE FROM, THROW, CUT and CLIMB have patterns but no handler in `ACTION_TABLE` or any object; `DO_PUT_IN`'s PUT ON branch is unreachable. | read; measured for four | [`actions.md`](actions.md) |
| 9 | **A fight's jostle only goes up -- or to zero.** `JOSTLE` ($9213) adds `RANDOM`'s -10 to +10 with `ADD A,B` and treats a carry as overflow, but a negative number always carries when the result is fine: every downward jostle of 10 or more returns 0 (below 10 an underflow wraps to 246+). `RANDOM` gives a negative only about one call in 25, so blows and guards are +0 to +10, or 0 -- and a guard of 0 loses to any blow over 16. | read; measured (2000 jostles of 104: 104-114 or 0, never below); watched live: the warg killed the player through a guard of 0, and Thorin's 104 came out 0 | [`fighting-and-dying.md`](fighting-and-dying.md) |

## The traps

| What | Evidence | Where |
|---|---|---|
| **The forest road.** Stepping onto the forest road or into the forest (2, 3) starts the eyes: leave for anywhere else and the next warning stings; stay four turns and the last one does. Only pacing between the two keeps the player alive. Whether `EYES_WARNING`'s test was meant the other way round cannot be told. | read; measured four ways | [`time-and-timers.md`](time-and-timers.md) |
| **The deep bog** kills at the end of the turn the player arrives; there is no way to act first. | read; measured | [`fighting-and-dying.md`](fighting-and-dying.md) |
| **The closed barrel.** Shut inside, the player is in the dark whatever the room, and OPEN needs light; without the sword, only the butler or the ride down the river gets them out. | read; measured in Bag End | [`light-and-dark.md`](light-and-dark.md) |
| **BREAK at the end of a tape block.** SAVE and LOAD call the ROM with the game's own IY; the ROM's BREAK check at the end of a block takes its error exit, and the machine restarts. | measured (SAVE, SPACE held) | [`save-load.md`](save-load.md) |
| **Attacking a friend** takes the friend off the player's side for good; Thorin, attacked barehanded, kills the player in the same turn. | read; measured | [`fighting-and-dying.md`](fighting-and-dying.md) |
| **Thorin's death** shatters the small curious key, which locks the side door for good. | read | [`characters.md`](characters.md) |
| **State a new game does not reset.** Bard keeps his last order, and Thorin's remark about the key, once made, is never made again, until the game is reloaded. | read; measured for Thorin | [`save-load.md`](save-load.md) |

## How this was found

9 was found on 2026-09-27 writing the Pokes page: a logpoint on
`DO_ATTACK`'s blow and guard showed Thorin's blow of 104 come out 0, which
the code then explained; it was measured in the simulator and watched
killing the player live. The Pokes page has an eight-byte fix.

1, 5 and the unreached code were on the site's Bugs page already, and 4 as
"not confirmed in play"; 7 came from the 2026-09-25 playthrough. The rest
were found writing these notes on 2026-09-27: 2 and 3 by working
`DO_ATTACK`'s arithmetic through by hand, 4 confirmed by running it, 6 and
the reset-state items by comparing
where the game writes with what its copies cover, and the traps by reading
the timers and `TOO_DARK` and then running each in the simulator.

## Confidence

As tagged in each row. The FILL test is one case (the barrel, the long
lake's water); the reading says every case fails the same way.

## Open questions

- 5: whether any player position reaches the bad jump.
- The forest and the barrel: design or mistake. The book has both a warning
  about leaving the path and dwarves in closed barrels, so either could be
  intended.
