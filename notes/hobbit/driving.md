# Driving The Hobbit

**Question this answers:** how to play the game from a script -- in the
emulator over MCP, or in SkoolKit's simulator -- without timing anything.

**Short answer:** stop at the places the game waits, never sleep. Five
breakpoints cover a whole game: the title's key wait, the key wait after each
picture, the line reader ready for a command, the line handed back, and the
restart after a win or a death. A command goes straight into the input
buffer.

## Snapshots

The build writes `game_disassembly/hobbit/hobbit.sna` (the original) and, with
`--fast-draw`, `hobbit_fast.sna`. Load the one you mean and check before
drawing conclusions: the fast one has code at $5D00, the original has BASIC
there. For repeated experiments, run to the first prompt once and
`save_snapshot` a `.z80` there (a `.sna` pushes PC onto the game's stack).
`hobbit.z80` is the machine as the tape leaves it, stopped at `START` --
what `scripts/hobbit_drive.py` and the page builders load in the simulator.

**The Hobbit Inspector** (`hobbit-vscode/`, see its README) shows the
running game's objects, characters, timers and map beside a debug session,
and logs every sentence the game composes -- including those about
characters out of sight -- from a logpoint on `PRINT_CHAR`.

## The breakpoints

| Address | Label | Stopped here means | Do |
|---|---|---|---|
| $6C6D | (in NEW_GAME) | the title screen is waiting for a key | hold a key (not N: N held means no pictures); let go at $6C76 |
| $969A | `WAIT_FOR_ANY_KEY` | a picture is finished -- after **every** new picture, not just the first | hold a key; let go at $96A3, just past where it is seen |
| $6DF3 | `READ_LINE_0` | ready for a command: HL = `INPUT_LINE`, B = $80, nothing typed | inject the command (below) |
| $6D20 | after `CALL READ_LINE` | the line has been taken | let go of ENTER |
| $90DF | `WAIT_AND_RESTART` | won, or dead | stop; a key here starts a new game |

**Injecting a command** at $6DF3: write the text into `INPUT_LINE` ($6FF9),
set HL = $6FF9 + length and B = $80 - length, run, let one keyboard scan see
no key held, then hold ENTER until $6D20. The line is filed exactly as if
typed. It is not echoed, so the screen shows an empty prompt.
`scripts/hobbit_drive.py` does the same in the simulator.

**Reading what the game says.** Stop at $858F, just past `PRINT_GATE` in
`PRINT_CHAR`, with the character in A: that is only what is really printed.
$858B itself is also reached while an action is merely being tested, and for
characters out of sight, so a capture there fills with sentences nobody sees
(the Inspector wants those, and marks them). `INPUT_STYLE` ($B701) says
which window it goes to. The prompt's ">" (called from $6DE6, inside
`READ_LINE`) marks the end of a turn. The notes' simulator checks of
2026-09-27 used a harness around `hobbit_drive.Hobbit` that held ENTER while
capturing at $858F from the moment the line was handed over -- a refused
command answers inside the first 0.05 s, before a capture that starts later
sees anything.

## Traps

- **Keys survive a snapshot load.** Release everything first; a stale ENTER
  held into the story's end-of-line wait hangs the game.
- **Never hold a key across story output.** `STORY_CHAR` waits at $86F8 until
  every key is let go at the end of each printed line, so a key held until
  the *next* breakpoint deadlocks. Let go at $6D20 / $96A3.
- **Breakpoint-driven input repeats exactly,** so the random choices repeat
  too (the hidden road, what Gandalf does). To vary a run, vary the input --
  an extra WAIT -- not the restart.
- **Screenshots at a breakpoint** from `get_screen` show the CRT mid-frame;
  draw them from screen memory ($4000, 6912 bytes) instead.
- **Gandalf takes things back.** In the Lonelands he takes the map every time
  on the scripted route above; WAIT with him and he gives it back within a few
  turns (his scripts cycle through RUN, TAKE, GIVE TO and DROP).
- **The trolls** only speak on the turn the player enters their clearing (5)
  and eat the player on later turns if still there: go straight through, E
  then SE, to Rivendell.
- **The game types WAIT itself** after about 23 s with no key at the prompt
  (realtime emulation; a stopped emulator does not count). Leave a game
  running at its prompt and turns go by.
- **A refused command with an object drops the rest of the line**: TAKE
  MAP. EAST does not go east if the map is already held. Send one command
  at a time ([`parser.md`](parser.md)).
- **Deadly places to stage in**: the forest road and forest (2, 3) kill
  whatever the player does next unless they pace between the two; the deep
  bog (29) kills at the end of the arrival turn; the forest river (33)
  without the barrel kills on arrival. A teleport skips the arrival hooks
  that start these ([`time-and-timers.md`](time-and-timers.md)).
- **Closing the barrel over the player** without the sword leaves them in the
  dark and unable to open it ([`light-and-dark.md`](light-and-dark.md)).
- **SPACE held when a SAVE or LOAD block ends** is BREAK: the machine
  restarts ([`save-load.md`](save-load.md)).
- **A new game does not reset the scripts**: Thorin's key remark, once made,
  and Bard's last order carry over until the snapshot is reloaded. Reload,
  don't QUIT, between experiments that touch them.

## Over MCP, in detail

*Watched* 2026-09-27 on a private `zx_server` (ports 14711/18000,
`--no-audio`), `hobbit.z80` loaded and driven by the breakpoints above; the
scratch driver was `hb_reference_live.py` in that session's scratchpad (not
kept).

- **Typing the injected line.** After writing the command at $6DF3, set a
  one-off breakpoint at **$7250** -- in `GET_KEY`, just after `CALL
  SCAN_KEYBOARD` -- and run to it: that is one scan with no key held. Clear
  it, press ENTER, run to $6D20 and let go. Every command so injected was
  taken first time.
- **The text.** A logpoint on $858F with `{A:d}` logs every character
  really printed; `get_log` returns them in each line's `text`, 13 for a new
  line. What `PRINT_CHAR` adds after its gate goes straight to `STORY_CHAR`
  and is not seen there -- the wine's extra H -- so log at **$86A1** for
  exactly what reaches the story window. `read_memory` answers `{"hex": ...}`.
- **An emulated clock.** `get_state`'s `frame_count` keeps counting with the
  game's interrupts off (50 a second), so a wait can be bounded in emulated
  time: run with `wait: false`, poll, pause past a limit. It is not reset
  by `load_snapshot`: take differences. The game typed its WAIT 1171 frames
  (23.4 s) after the first prompt.
- **Watching a fight.** A logpoint at **$91C1** (`DO_ATTACK`'s `CP B`) with
  `blow {B:d} guard {A:d} actor {(0xB70C):w} target {(0xB708):w} doing
  {(0xB6FA):d}`: B is the blow, A the guard, $B70C the attacker's record,
  $B708 the target's, and $B6FA 1 for a real blow, 0 for a test. It also
  logs the fights nobody can see.
- **Keeping an attacker beside the player.** Characters wander: by the first
  prompt the warg has left the treeless opening. To stage a long fight,
  write the attacker's location (record +16) to the player's before every
  command.

**Traps found this way** (*watched*):

- **Attacking Thorin starts a war out of sight.** He leaves the player's side
  for good and attacks Gandalf; the two exchanged 23 blows each in the
  following turns, off-screen, until Gandalf killed him. Every later
  experiment in that game has no Thorin.
- **A fight can kill whatever the numbers say.** `JOSTLE` makes a blow or a
  guard 0 about one time in 25 ([`bugs.md`](bugs.md)), and a guard of 0 is
  killed by any blow over 16: the warg killed the player on its twelfth
  blow. Poke the defence and the jostle fix from the Pokes page, or keep
  fights short.
- **In the dark, every move is a fall where there is no way out** -- the
  direction typed does not matter, it is thrown away -- and each halves the
  strength; three moves in the trolls' cave took it from 64 to 8.

## Staging a state by poking

Object records are in `OBJECT_INDEX` ($C063); a record's head is 16 bytes:
+1 holder ($FF none, 0 the player, else an object number), +7 flags (bit 7
there, bit 6 character, bit 5 open, bit 4 gives light, bit 3 dead or broken,
bit 2 full, bit 1 liquid, bit 0 locked), +16 its first location.

- **Teleport:** write `PLAYER_WHERE` ($C12B), then LOOK. It skips ARRIVE --
  no visit score, no arrival hooks -- and leaves carried objects behind:
  write each held object's location too.
- **Give the player an object:** holder (+1) = 0 **and** location (+16) = the
  player's; `IN_REACH` checks the location.
- **Light:** only the sword ($0E) lights a dark room (`TOO_DARK`, $95ED); the
  torch does not. It only has to be in reach: lying in the same room will do
  (*measured*), so writing its location alone lights a room. To make a room
  dark for a test, move the sword out of it -- it lies in the trolls' cave on
  the tape.
- **Start a timer:** write its length into its count (`TIMER0_COUNT`
  $CA85, and every 7 bytes on); for the ones an arrival starts, do what the
  hook does ([`time-and-timers.md`](time-and-timers.md)).
- **Put the player in a container:** holder (+1) = the container's number
  and location = the container's; the player's own number is 0.
- **Type the noun alone** -- TAKE SWORD, not TAKE SHORT STRONG SWORD, which
  loses the noun.

## Variables worth watching

| Address | Label | What |
|---|---|---|
| $B6F7 | `SCORE` | tenths of a per cent -- see [`scoring.md`](scoring.md) |
| $C12B | `PLAYER_WHERE` | the player's location |
| $B6EA | `ACTING` | who the current action is by (0 the player) |
| $A7D1 | (operand of `ELROND_READS_MAP`) | this game's hidden road -- see [`hidden-roads.md`](hidden-roads.md) |
| $CACB | `CHARACTERS` | each character's place in its script |
| $CA84 | `TIMERS` | what END_OF_TURN counts down |
| $B6F5 | `PLAYER_AT` | where the player is, as `NOTE_LIGHT` last noted it (each turn) |
| $B70C | `ACTOR` | the record of whoever is acting |
| $B6FA | `DOING_IT` | 0 while an action is only being tested |
| $B707 | `PICTURES_ON` | 0: no pictures (N at the title) |
| $B714 | `PATIENCE` | scans left before the game types WAIT |
| $B6EE | `RIDDLE` | this game's riddle entry in `RIDDLES` |
| $B70E, $B712 | `RANDOM_LAST`, `RANDOM_POINTER` | the random generator's state |
| $C8FB | (Thorin's step) | $23 until he has made his remark about the key, then $00 |
| $C9E2 | (Bard's step) | his current order: opcode $42, action, two objects |

Object numbers used above: map $03, sword $0E, treasure $23, chest $25,
golden key $2B, Gandalf $3E, Thorin $3F, Elrond $41.

## Confidence

The breakpoints, the command injection and the first traps (keys across a
load, keys across story output, torn screenshots, Gandalf and the map, the
trolls) were *watched* live in `zx_server` on 2026-09-25. The additions of
2026-09-27 -- text capture at $858F, the WAIT after 23 s, the dropped rest of
a line, the deadly places, the barrel, BREAK, the scripts surviving a new
game, the sword lighting a room from the floor -- were *measured* in
SkoolKit's simulator with `hobbit_drive.py`, not yet live. The
"Over MCP, in detail" section, including the WAIT after 23.4 s now timed
live, was *watched* on 2026-09-27.

## Also found for the animations page (2026-09-27)

- In `hobbit.z80` the keyboard scan's last-seen table ($8B8B-$8B92) is all zero, which reads as every key held down: the first key typed at the first prompt is lost unless one scan first sees the keyboard empty. `hobbit_drive.say` does that already, though its comment puts it down to a stale ENTER (*measured*).
- `Hobbit().seconds` reads about 63.6 s at the first prompt because `ready()` spins 60 s in `WAIT_FOR_ANY_KEY` before tapping a key -- harmless, but not game time (*measured*).

