# BASIC and the levels

**Question this answers:** what the game's BASIC does -- the flow of a game
from the title to the end, how a level is set up, what the ten levels are,
and what happens when an attempt fails.

**Short answer:** the BASIC (8463 bytes at $5CCB-$7DD9) runs everything but
the city. It asks girl or boy, sets up each level by POKEing the object
records at $B480 and the variables at $B420 from DATA, calls `PLAY`
(USR 32768) twice -- two frames to put the city behind the ready message,
then the real run -- and afterwards reads one byte, the rescued person's
state at $B49D, to see whether they got out. A rescue moves on a level; a
failure with time left is another go at the same level with the clock still
running; the clock reaching zero is the only game over. Ten rescues win.

## How it works

The line numbers are the game's; the addresses are where BASIC POKEs and
PEEKs (*read*, from the listing the build prints into each BASIC line's
entry).

```
10   set up: colours, w = 46237 ($B49D), r = 0, sp = 2, fin = 10, score and
     rescues 0; POKE w,0; GO SUB 600 (title, girl or boy)
20   GO SUB 750 (time = 1001), 800 (the level), 900 (story or score card,
     which also runs 100 and 200), 300 (the play screen), 700 (play)
60   after PLAY: time 0 and not rescued -> the out-of-time screen, a key, RUN
70   not rescued -> the retry message: 400, 800, 100, 200, 300, 700, GO TO 60
90   rescued: rescues + 1; score += time left x rescues; ants' speed
95   rescues = fin -> the ending (3600), PAUSE, a key, RUN
99   GO TO 20
```

**The title and the choice (600-630, 3100-3120).** A framed screen, the
publisher's and author's names, the game's logo in block graphics printed
eight times over in each ink with a BEEP, five times; a rising run of BEEPs;
then the girl-or-boy prompt. `GET_KEY` (USR 32912) returns the ROM's
KEY-SCAN code, which is 0 for B and 6 for G (the ROM's key table order);
anything else asks again. B pokes the player's first sprite frame as the
boy's ($DC into $B483) and the rescued person's as the girl's ($6C into
$B493); G the other way round, and the panel's two names swap (*read*;
both *played* in the build's boy and girl sessions).

**A level (800-870, 1000-1091).** Level n is data at line 1000 + 10(n - 1):
that line sets the story card's text and the next line holds places where the
person to be rescued waits -- x, y and height, one for level 1 and four for
each of the others. Line 800 RESTOREs to the level's line, calls it for the
text, skips `r` triples (line 850-860) and POKEs the next into $B490-$B492.
`r` is recomputed only after a rescue (line 850 checks `PEEK w = 2`): it is
the time left MOD 4. So which of the four places is used depends on how fast
the last person was led out, and a failed attempt replays the same place
(*read*). The places themselves are listed, and ringed on the city map, by the
Levels and City pages, which the build generates from the BASIC.

**The records (100-190).** Lines 110-180 are sixteen DATA values per record
for the eight objects at $B480, a value of -1 meaning "leave it". What they
set (*read*; field meanings in [`objects.md`](objects.md)):

- the player: facing 2, may stand on the other person, explosion countdown 1
  -- so on the first frame `MOVE_OR_RESPAWN` puts them at their home, the
  city gate, outside the walls (x $B9, y $04); position zeroed; first frame
  left as line 610 set it;
- the person to be rescued: position left as line 800 set it, stunned for 4,
  may stand on the player and step up, animation frame 3 (lying down), state
  0 (waiting);
- the grenade: first frame $68, steps up, countdown 1, home at x 0, y $40,
  height 0 -- outside the walls and normally out of sight;
- the five ants: position *left alone*, first frame $F8, moving, countdown 1,
  homes five cells two apart on the row y = $A8 (x $B2 to $BA), speed 20 for
  the first and 2 for the others, speed counts staggered 1, 4, 3, 2, 1.

Leaving the ants' positions alone is what keeps the map right: an ant's
position is also a bit in the city map, and `MOVE_ANT` XORs it out of the old
place before sending it home ([`ants.md`](ants.md)). Overwriting the record
would strand a phantom block. Line 190 then POKEs `sp` into the speed of
ants 2-5 (*read*).

**The variables (200-230).** 25 values into $B420-$B438: the view origin
($B9, $ED) and view 0; five bytes of 1 at $B423-$B427 that the machine code
never reads; the random generator's four bytes ($B428-$B42B) all 1;
the border colour for the sound routines 0; no grenade events, nothing in
flight; 20 grenades, 20 energy each; the clock's frame count 1; the time
itself left alone (-1); `FRAMES_LEFT` 1. The random generator starting from
the same state every level and every retry means the same keys pressed on
the same frames give the same game (*read*; the generator was 01 01 01 01 at
`PLAY` on every retry, *watched* live, 2026-09-27; see [`ants.md`](ants.md)).

**The time (750).** 1001, big-endian in $B436-$B437, set only on the way into
a new level (line 20). Retries (line 70) do not reset it (*read*). One tick
every three frames, so 3003 frames a level, about 7.7 minutes at the measured
6.5 frames a second before any time spent in scripts (*read*, and worked out
from [`performance.md`](performance.md)).

**Play (700-720).** `POKE 46136,2` ($B438) and USR 32768: `PLAY` runs two
frames and returns, which moves everything to its home and draws the city;
the ready message; `WAIT_KEY` (USR 32919); then USR 32768 again, which runs
until the game stops it ([`main-loop.md`](main-loop.md)).

**After play.** BASIC PEEKs $B49D (`w`): 2 is a rescue. Otherwise, if the time
at $B436-$B437 is zero, the game is over (line 60): the out-of-time screen
with the lives saved and the score, the new-game prompt, RUN. With
time left -- energy ran out, a grenade went off in someone's cell, or 1 was
pressed -- line 70 flashes the retry message, puts the person back in the same
place, resets every record and variable except the time, and plays again
(*read*; out of time and a rescue *played*). So a failed attempt costs only
the time it took: energy running out put the game back at the ready message
with the same clock, and key 1 is a free refill of grenades and energy for
the one clock tick of the two ready frames (*watched* live, 2026-09-27, by the
agent testing pokes).

**A rescue (90).** Rescues + 1; the score for it is the time left times the
number of rescues so far, this one included, added to the total; from the
fourth rescue on, `sp` = 2 + INT(rescues / 4). Then the score card
(910-960): lives saved, time left, the total in a flashing box; and the next
level's story card. At ten rescues (`fin`) line 3600 runs the ending instead:
a framed screen, `POKE 46124,5` so the sound routines keep the border
cyan, `FINAL_SCRIPT` (USR 36594, script 17), a medal drawn with CIRCLE, the
total score (*read*; *played* in the build with `fin` set to 1).

**The ants' speed by level** (*read*): `sp` is how many frames in which an ant
misses one step. Levels 1-4 (0-3 rescues so far): 2, half speed; levels
5-8: 3, two steps in three; levels 9-10: 4, three in four. The first ant is
always 20, nineteen steps in twenty.

## How this was found

The listing was read line by line from the build's BASIC blocks (SkoolKit's
`BasicLister`, 2026-09-27), and each POKE and PEEK address matched to the
annotations' labels. The build's sessions *played* the boy and girl starts,
two rescues, running out of time, and the ending with `fin` poked to 1 (the
variable found by its long-name encoding in the VARS area, see
`_one_rescue_to_win` in the build).

## Confidence

The flow and the numbers are *read* from the BASIC. The rescue path, the
out-of-time path, the retry path (key 1, in the random play's `RETREAT`
steps) and the ending all ran in the build's playthrough (*played*). The
time-left MOD 4 choice of place was not checked by a run.

## Open questions

- Whether the five bytes of 1 at $B423-$B427 were once read by the machine
  code (see [`leftovers.md`](leftovers.md)).
- The ending's `PAUSE 500` runs after `FINAL_SCRIPT` re-enables interrupts;
  not traced.
