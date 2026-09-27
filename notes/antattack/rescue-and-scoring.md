# Rescue and scoring

**Question this answers:** how the person waiting in the city is found, how
they follow, what counts as leading them out, and where the score comes
from.

**Short answer:** the waiting person is not moved at all; each frame only
their grid distance to the player is taken, to colour the scanner green
(closer than last frame) or red. Within three cells at the same height they
are found, and from then on they walk towards the player whenever two to
five cells away. When both are outside the walls -- either coordinate below
$80 -- the level is won. BASIC scores the time left times the number of
people rescued so far; ten rescues win the game.

## How it works

```
MOVE_RESCUEE $8F80          IX = the rescued person, IY = the player
  +$0D = 0, waiting:        DISTANCE to the player -> SCANNER (green if less than
                            last frame's, kept at +$0E); distance <= 3 and the
                            same height: +$0D = 1, scanner red, script 12
  +$0D = 1, following:      SHARE_CELL, FOLLOW_PLAYER, MOVE_OR_RESPAWN, CHOOSE_FRAME
CHECK_RESCUED $8EA0         (after the frame) both outside and +$0D not yet 2:
                            +$0D = 2, script 13, FRAMES_LEFT = 1
```

(*read*; all *played*.)

**Waiting.** Nothing moves the waiting person: no gravity, no stun count, no
animation. BASIC gives them animation frame 3, so they are drawn lying down
where the level's DATA put them (*read*, and *measured*: a staged frame drew
frame $78, the girl lying down, 2026-09-27). Their stun of 4 only starts to
count once they are found.

**The scanner** (`SCANNER` $87D0, *read*): the attribute bytes of the SCAN
box on the panel -- rows 18-20, columns 26-29 -- set to green ink (4) when the
distance is smaller than last frame's and red (2) otherwise; the box holds
solid block characters printed by BASIC, so the ink colour fills it. It
only says warmer or colder: nothing on the screen gives a direction or a
distance. It is last set, to red, when the person is found, and not touched
while they follow.

**Distance** is `DISTANCE` ($8A80): |dx| + |dy| on the grid, ignoring
height, each difference taken as a signed byte -- the short way round the
wrapping 256-cell world. The sum is a byte too, so two cells exactly 128
apart in both x and y come out at 256, which is 0. The agent testing pokes
found level 1's person (waiting at $B6, $F3, height 1) by jumping at
($36, $73), outside the walls on the far side of the world (*watched* live,
2026-09-27; *read*: 128 + 128 wraps). What the person does after being found
from there was not followed.

**Being found** needs the same height as well as the distance: someone
waiting on a walkway five blocks up has to be reached up there (*read*).

**Following** (`FOLLOW_PLAYER` $8AB6, *read*): not while stunned. At a
distance of 2-5 they walk; at 1 (beside the player) or 6 and more they stand.
The facing is kept if one more step along it would end beside the player,
otherwise they turn towards the player (`DIRECTION_TO`). At distance 0 --
the same cell, one on the other's head -- `ON_TOP` gives them the player's
facing, and they walk on if they are the higher of the two and stop if lower.
They move with `MOVE_OR_RESPAWN` like the player, but with flag bit 4 they
step up one-block rises by themselves, so they can follow the player up steps
the player had to jump. They cannot jump, so anything the player climbed by
standing on something else, or two blocks at once, they cannot follow
(*read*). Left more than five cells behind they wait, and follow again when
the player comes back.

**Sharing a cell** (`SHARE_CELL` $84D0, *read*, *played*): while following,
if the two are in one cell no more than a block apart, both stuns and the
player's fall count are cleared -- so neither dropping onto the other nor
being dropped on is ever a landing ([`falling.md`](falling.md)).

**Leading them out** (`CHECK_RESCUED`, *read*, *played*): the test is only
that both the player's and the person's position have x or y below $80 --
outside the walls, anywhere, at any height. There is no check that they came
through the gate, or together. It sets the person's +$0D to 2 (`w` in the
BASIC), plays script 13 (the congratulations, with the play area flashing
through colours), and makes this the last frame.

**The score** (BASIC line 90, *read*): rescues + 1; the time left (the
big-endian `TIME`, $B436) times the rescues so far, this one included, is
added to the total. So later rescues are worth more for the same time left,
and a slow rescue on a late level can still beat a quick one early. The
time is 1001 at the start of each level and falls by one every three
frames; retries do not reset it. With `sp` rising from the fourth rescue
the ants get faster as the score multiplier grows
([`basic-and-levels.md`](basic-and-levels.md)).

**The end** (*read*; *played* with `fin` poked to 1): at ten rescues BASIC
runs the ending -- script 17 through `FINAL_SCRIPT` (USR 36594), a medal and
the total score -- then waits for a key and starts again from the title. The
only other end is the clock reaching 0 with no rescue: the out-of-time
screen with the rescues and the score. Lives do not exist; energy running
out only costs the time the attempt took.

## How this was found

Read `MOVE_RESCUEE`, `FOLLOW_PLAYER`, `ON_TOP`, `SHARE_CELL`, `SCANNER`,
`DISTANCE` and `CHECK_RESCUED`, and the BASIC around them. The build's
rescue session (put the player beside the person, walk a little, put both
outside) and its staged `_on_the_players_head` and `_on_the_rescuees_head`
scenes *played* the finding, the following, the head-sharing and the rescue.
The waiting pose was drawn with the scratch simulator harness on 2026-09-27.

## Confidence

*Read* and *played*; the far-side find *watched* live. The following
behaviour beyond the staged scenes -- how well the person keeps up in real
streets -- has not been watched.

## Also found for the how-it-works pages (2026-09-27)

- Level 1 played from its first frame by a scripted player: found, followed, rescued on frame 55; score 982, time left times one; r = 2, so level 2 used its third place (*measured*, the Rescue page).
- Energy at 0 only restarts the level; the clock keeps its count, four more frames run after the fatal bite, and the preview behind the start prompt takes one tick (*measured*).
- Memory is tight: at a level's start SP - STKEND is 149 bytes, which is why the build's ending session, with level 1's long story card still in c$, runs out of memory at line 3610 (*measured*).

## Open questions

- What the person does when found from 128 cells away: `FOLLOW_PLAYER` sees
  a distance of 0 and treats them as sharing a cell.
- Whether leading the person out anywhere other than the gate is possible in
  practice (they cannot climb the two-high outer wall; the player can only
  get over it by standing on something).
