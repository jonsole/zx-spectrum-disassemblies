# Time: WAIT, the turn clock and the timers

**Question this answers:** how time passes in the game -- when the player does
nothing, and in the countdowns that make places and things deadly after a
few turns.

**Short answer:** there is no clock but the turn. Real time comes in only
through `GET_KEY`: if no key comes for about 23 seconds it clears the line,
types WAIT and presses ENTER itself, and that WAIT is a turn. Within a turn,
ten timers in `TIMERS` count down; each can warn in its last few turns and
act at zero, and only one may act per turn. Most are started by arriving
somewhere (`ARRIVAL_HOOKS`) or by an object's own handler.

## How it works

### The game types WAIT

`READ_LINE` ($6DD6) sets `PATIENCE` ($B714) to 3000 at the start of every
line. `GET_KEY` ($7249) counts it down by one for every keyboard scan with no
new key; each scan costs about 7.8 ms, most of it `DEBOUNCE_DELAY`'s busy
loop. A key sets the patience for the next key to what was left plus 500,
at most 3000. If it reaches zero, `GET_KEY` rubs the line out, copies the four
letters of `WAIT_TEXT` into it with their echo, and returns a carriage
return (*read*).

*Measured* 2026-09-27, in the simulator from the first prompt with no key
held: 23.4 s of emulated time from `READ_LINE_READY` to the W of WAIT --
3000 scans at 7.8 ms. So:

- the player has about 23 s to start typing;
- each key buys about 3.9 s more, but never more than 23 s in hand;
- a pause longer than what is in hand throws the half-typed line away, and
  the WAIT goes in its place.

The ref's "the time allowed adapts to how fast the player types" is this
rule; it resets to 23 s at every prompt.

A driver stopped at a breakpoint does not trip it -- emulation is stopped --
but a game left at its prompt under realtime emulation does, every 23 s.

### The timers

`TIMERS` ($CA84) is ten 7-byte entries ending at $FF (*read*):

| Offset | Field |
|---|---|
| 0 | length in turns; starting a timer copies it into the count |
| 1 | count; 0 = not running |
| 2-3 | routine to run when the count reaches 0 |
| 4 | warning span: warn while the count is at most this |
| 5-6 | warning routine |

After the characters' turn, `END_OF_TURN` walks them: a running count goes
down by one; at zero its routine runs, through `RUN_ROUTINE`; otherwise, if
the count is within the warning span, the warning routine runs. `TIMER_FIRED`
($B6F0) allows one firing per turn: a second timer reaching zero in the same
turn is put back to a count of 1 and fires next turn -- and, if it has a
warning span, runs its warning this turn instead (*read*, $96E5-$96FE).
`BARREL_REACHES_LAKE` begins by clearing `TIMER_FIRED` again, so the
barrel's arrival does not use up the turn's firing (*read*; the annotation's
comment there, "Only one timer fires in a turn", describes the rule rather
than what the two instructions do).

The ten, as the tape has them (*read*, from the table and the routines):

| # | Length | Warn | At zero | Started by |
|---|---|---|---|---|
| 0 | 2 | - | `BARREL_REACHES_LAKE`: whoever is in the barrel to the long lake; the barrel back to the cellar | `BARREL_THROWN` (the trap door's key-0 record) |
| 1 | 2 | - | `WEB_CHANGES`: the broken web mended | `WEB_BROKEN` (the web's key-0 record) |
| 2 | 5 | - | `WEB_SMOTHERS`: dead if still in the spider threads place (26) | `AT_SPIDER_THREADS` (arrival) |
| 3 | 2 | - | `GOBLINS_DOOR_SHUTS` | `GOBLINS_DOOR_OPENED` |
| 4 | 2 | 2 | `SINKING_IN_BOG` (same routine to warn) | `AT_DEEP_BOG` (arrival) |
| 5 | 4 | 1 | `MAGIC_DOOR_CLOSES`; warns with `MAGIC_DOOR_OPENS` | `MAGIC_DOOR_EXAMINED` by an invisible actor |
| 6 | 0 | - | `RING_CHECK`: the ring slips off | `WEAR_RING`, count set directly to 2-10 |
| 7 | 5 | - | `WINE_WEARS_OFF` | `WINE_DRUNK` |
| 8 | 4 | 3 | `EYES_STING`; warns with `EYES_WARNING` | `IN_THE_FOREST` (arrival at 2 or 3) |
| 9 | 5 | 1 | `SIDE_DOOR_VANISHES` (restarts itself); warns with `SIDE_DOOR_APPEARS` | `AT_ELVENKINGS_CELLAR` at 3, `SIDE_DOOR_CLOSED` |

**`ARRIVAL_HOOKS`** ($C78E) is the other half: a `FIND_RECORD` table of
routines `MOVE` runs when the *player* arrives in a location, before the
description (*read*): Beorn's house (22) brings the butler in; the spider
threads place (26) starts timer 2; the deep bog (29) timer 4; the forest
river (33) kills a player who is not in the barrel; the forest road and the
forest (2, 3) timer 8; the elvenking's cellar (32) starts timer 9 and brings
the dragon and Bard in. A teleport by poking skips them.

### The forest: a trap with no way out

Timer 8 is the one worth knowing. `IN_THE_FOREST` ($C7DD) stores the
location just arrived at -- `DESTINATION` ($8D9B), so 2 or 3 -- in
`FOREST_ENTRY` ($B6F3) and restarts the count at 4. Then (*read*):

- at the end of the arriving turn and of the two after it (counts 3, 2, 1),
  `EYES_WARNING` says the eyes are watching, and if the player is at
  neither 2 nor 3, jumps to `STUNG_DEAD`;
- at the end of the fourth (count 0), `EYES_STING` kills a player still at
  2 or 3.

So a player who steps onto the forest road dies whatever they do next, unless
they keep walking between 2 and 3 (each arrival restarts the count).
*Measured* 2026-09-27 in the simulator, the player placed at 46 (the other
forest road) and walked by command:

- EAST to 2, then WEST back to 46: stung and dead on arriving;
- EAST to 2, then three WAITs: stung and dead on the third;
- EAST, EAST, EAST (46, 2, 3, then the waterfall, 45): dead at the waterfall;
- in from the waterfall and back and forth between 3 and 2 five times: alive
  throughout, eyes every turn; then three WAITs, dead.

Whether that was the design (the book's warning not to leave the path) or a
mistake in `EYES_WARNING`'s test cannot be told from the code: see
[`bugs.md`](bugs.md).

### The barrel's ride

Timer 0 is the barrels-out-of-bond episode. The butler's script throws the
barrel through the large trap door; the trap door's key-0 record
(`BARREL_THROWN`) starts the timer if the barrel landed in the forest river
(33); two turns later `BARREL_REACHES_LAKE` puts whatever is in the barrel
at the long lake (34) -- a player inside is told they are thrown onto the
bank -- and then puts the barrel itself **back in the elvenking's cellar**
(32), closed and full, empties it with printing off, and puts the wine back
in it: the barrel is reset for another ride. *Measured* 2026-09-27: player
in the barrel at the forest river, timer 0 at 2, two WAITs -- the player on
the long lake's bank held by nothing; the barrel at 32, closed, full, the
wine inside.

### Other time in the game

- The trolls' dawn is not a timer but their script's own count of turns:
  they turn to stone at the end of the fourth turn after the one in which
  the player enters their clearing ([`characters.md`](characters.md)).
- The wine's five turns, the ring's 2-10, the magic door's four and the side
  door's hole every five are the only other clocks.

## How this was found

`GET_KEY`, `END_OF_TURN`, the timer table and every routine in it were read
line by line. The 23.4 s was timed in SkoolKit's simulator by T-states (the
harness in the scratchpad was not kept). The forest was first read as
backwards -- a warning that kills whoever has *left* seemed unlikely -- so it
was tried four ways in the simulator before being written down.

## Confidence

The timer mechanism and table are *read*. The patience time and the forest
are *measured*. The one-firing-per-turn rule is *read* only; no case of two
timers reaching zero together was staged.

## Disassembly corrections

- `IN_THE_FOREST`'s description says $B6F3 keeps "the place the player came
  into the forest by", and `FOREST_ENTRY`'s says "Where the player came into
  the forest". It is the forest location just arrived at (`DESTINATION`,
  2 or 3), not the place left. `EYES_WARNING`'s "What sets #R$B6F3 is not yet
  traced" is out of date. Corrected in the annotations 2026-09-27.
- The ref's "adapts to how fast the player types" is right but loose; the
  rule above is what the code does.
- `BARREL_REACHES_LAKE`'s comment at $A615 says "The barrel: at the lake";
  the instruction there, `LD (IX+$10),$20`, puts it at location 32, the
  cellar. Only its contents stay at the lake. *Measured*; corrected 2026-09-27.

## Also found for the animations page (2026-09-27)

- The game typed WAIT after 23.40 s at the prompt, and each WAIT turn of the 50 filmed took 24.3 s of game time (*measured*).

## Open questions

- Whether the forest's every-way-out death was intended.
- Two timers firing in the same turn has not been staged, so the held
  timer's extra warning is read, not seen.
