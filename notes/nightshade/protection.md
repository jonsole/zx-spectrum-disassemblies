# The tape and its protection

**Question this answers:** how the tape loads the game, how the game checks
that it was loaded that way, and what else in the code acts as a guard --
including the slow stack leak that crashes the game after 156 games.

**Short answer:** the tape loads the game scrambled, and three small blocks
set things the game later checks: FRAMES' middle byte must be $63 (`START`,
$BDFE), every table of routines is reached through the `JP (HL)` the tape
put in `NMIADD` ($5CB0), and bit 7 of R, which only the loader sets, is
tested at every new game (`STOCK_BUILDINGS`, $C1DB). A fourth check, in
`NEW_LIFE` ($CBAC), resets the machine if the instruction that takes a life
has been poked, and the number of lives is read from an opcode. Separately,
every game over leaves two bytes on the stack; after 156 of them the stack
reaches `NMIADD` and the next game crashes.

## How it works

**The tape** (`tapes/Nightshade (1985)(Ultimate).tzx`, six files): a BASIC
loader, the loading screen, the game block `0` (CODE 24576,34816, scrambled),
and three small blocks -- `1` (43 bytes into the printer buffer at $5B80),
`2` (one byte, $E9, into `NMIADD`) and `3` (two bytes into `FRAMES`, $5C78).
The BASIC then runs `PRINT USR 23424`.

**The loader** (`LOADER`, $5B80): `DI` (for good -- nothing in the game has
an `EI`), bit 7 of R set with `LD A,R : OR $80 : LD R,A`, the game block
unscrambled a pair of bytes at a time (an `RLD` swaps a nibble between the
two), moved from $6000-$E7FF down to $5E00 with `LDIR`, and a jump to
`ENTRY` ($5E00). The build redoes the unscrambling on the tape's own block
and checks it against the snapshot (`check_loader()` in
`scripts/build_nightshade.py`).

| Check | Where | What the tape set | What happens if it fails |
|---|---|---|---|
| 1. FRAMES | `START` $BDFE | block `3`: FRAMES, middle byte (`FRAMES_MIDDLE`, $5C79) $63 | `RET` back to BASIC, before anything is set up |
| 2. NMIADD | `DISPATCH` $D593 ends `JP $5CB0` | block `2`: `JP (HL)` in `NMIADD` | the ROM leaves 0 there; the jump would run the system variables as code and crash at the first update |
| 3. R bit 7 | `STOCK_BUILDINGS` $C1DB, at every new game | the loader's `LD R,A` | falls into `RESET` ($C1F9): `JP (HL)` with HL 0, the Spectrum restarts |
| 4. the lives poke | `NEW_LIFE` $CBAC (at $CBB1) | -- | `JP RESET` unless the byte at $CBDD is still $35, the `DEC (HL)` that takes a life |

- **FRAMES never counts.** With interrupts off from the loader on, FRAMES
  keeps the tape's value all session. Check 1 therefore also stops a copy
  that lets the interrupts run a few seconds before starting the code.
  `NEW_GAME` ($BE0F) starts the turn counter `TURNS` from it at every game;
  but `MENU` then calls `NEXT_TURN` at every pass ($C93C), about 42 a
  second, so the count at the first turn -- and with it the start cell and
  where the villains go -- depends on how long the menu ran: 1 to 6 passes
  gave six different start cells and placements (*measured*, stage 3; stage
  2 had said every game starts from the same value).
- **R's bit 7.** The refresh counter only counts R's low seven bits; bit 7
  changes only when a program loads R. A copy started without the loader has
  it clear (R is 0 after a reset) and resets as the first game begins. The
  build's first simulator run did exactly that until its `Machine` took R
  from the snapshot (*measured*, stage 1).
- **NMIADD** is also where every table of routines goes: `UPDATES`,
  `DEPTH_TABLE`, `MONSTER_HIT_TABLE`, `COAST_TABLE`, `TURN_TO_KNIGHT_TABLE`,
  `MOVE_TABLE` ([`main-loop.md`](main-loop.md)).
- **The lives poke.** The usual infinite-lives poke, a NOP over the
  `DEC (HL)` at $CBDD, makes the machine reset at the first death. It is the
  only check aimed at a player rather than a copier.
- **The lives byte.** `NEW_GAME` sets `LIVES` from the opcode of the `JR` that
  closes the main loop, at `LIVES_BYTE` ($BEDD): $18 shifted right twice is
  six. There is no "load six" to search for, and a poke to that byte breaks
  the loop. Whether it was meant as a guard is not known; it works as one.
- **The stack leak.** `START` is the only place SP is set (to $5E00).
  `GAME_OVER` ($CC56) is jumped into from routines the main loop calls
  (`NEW_LIFE`, `CHECK_QUEST_DONE`) and leaves by `JP NEW_GAME` or
  `JP MAIN_LOOP`, and `ENDING_PIT_FRONT` jumps to `NEW_GAME` from inside an
  update: two bytes are lost at every game over, four at every ending. The
  stack creeps down through `BASIC_PROGRAM` towards the system variables;
  after the 156th game over it has overwritten `NMIADD` with part of a
  return address, and the 157th game's first update jumps into the screen.
  The arithmetic agrees: from $5DFE down to $5CB0 is 334 bytes; play takes
  the stack 24 bytes deeper (*measured*, stage 1), and (334 - 24) / 2 is 155.

## How this was found

The tape's structure from `tapinfo`, the loader read from block `1`, and
the four checks read from the game (stage 1). The stack leak was noticed in
stage 2 by range 2 reading `GAME_OVER`, and measured twice: range 2 watched
SP at `MENU_LOOP` fall $5DFE, $5DFC, $5DFA, $5DF8, $5DF6 over four game
overs and to $5DF2 after an ending; range 1 then ran 156 quick games in one
simulated session (the build's `_start("1")` and `_game_over` helpers) --
SP two bytes lower at the menu each time, `NMIADD` holding a return
address's byte after the 156th, and the 157th game running from the screen
into the printer buffer (the loader's routine ran again, scrambling memory)
and hanging at $5ED8.

## Confidence

- The four checks and the lives byte: *read*; check 3 *measured* (the reset
  with R at 0). Check 4's reset is not in the build's code-map sessions (the
  reset at $C1F9 is in the coverage file's list), but the reference page's
  build runs it: the NOP poke resets the machine at the first death
  (*measured*, stage 3).
- Check 2's crash without the byte: *inferred* from the system variables'
  bytes after `NMIADD`, not run.
- The 156-game crash: *measured* in SkoolKit's simulator, with games that
  ended at once, and *watched* on a private zx_server driven by breakpoints
  (stage 3): the same hang at $5ED8 in game 157. The reference page's build
  re-runs it every time. The count depends on how deep play takes the stack; a
  game that ends at a deeper point could crash one or two games earlier.

## Filmation (Knight Lore, Alien 8, Pentagram)

Knight Lore, Alien 8 and Pentagram load plainly and have no checks of this
kind. The loader in the printer buffer, the scrambled block and the system
variable tricks are new with Nightshade. Their `START`s set SP once too, but
their game-over paths return properly; the leak is Nightshade's.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| (none) | | | stage 1's names here -- `START`, `STOCK_BUILDINGS`, `RESET`, `LIVES_BYTE`, `NMIADD`, `FRAMES`, `FRAMES_MIDDLE` -- all stand |

## Disassembly corrections

- Stage 1's `NMIADD` description said that without the tape's byte "no
  object would ever move". The jump would run the system variables as code:
  a crash at the first update (stage 2, range 3).
- Stage 1 called FRAMES "the first random number"; it is where the turn
  counter starts at every game (range 1).

## Open questions

- Settled in stage 3: the crash was watched live (above); an infinite-lives
  poke that survives check 4 points the `LD HL` before `TAKE_LIFE` at the
  ROM ([`bugs-and-pokes.md`](bugs-and-pokes.md)); the `TAKE_LIFE` label lost
  in the merge is restored.
- None open. Each real game lasts minutes, so the crash is a curiosity
  rather than something a player would meet.
