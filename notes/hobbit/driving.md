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
  torch does not. Give the sword as above.
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

Object numbers used above: map $03, sword $0E, treasure $23, chest $25,
golden key $2B, Gandalf $3E, Thorin $3F, Elrond $41.
