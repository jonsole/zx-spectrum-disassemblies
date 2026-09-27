# Journal

What was done, how, and what came of it. Newest last. The first entry is
reconstructed from the build script, the commit that added it and the
session's own notes; these notes did not exist yet.

## 2026-09-24 -- the disassembly, built and published

- **The tape.** The original Quicksilva TZX (ZXDB 0000210), downloaded into
  `tapes/`. `scripts/build_antattack.py` loads it with `tap2sna --start
  $9700`, which runs the one-line BASIC loader and its machine code in the
  simulator and stops where LD-BYTES returns: the snapshot is the machine as
  the load leaves it. The loader, the load over the system variables and the
  typed RUN were worked out and written into the build's docstring.
- **The code map by playing.** The build plays the game in SkoolKit's
  simulator from $9708 (past the load checks, whose flags only a real load
  sets) with a tracer that holds keys, and records every address run:
  random play as the boy and as the girl, two rescues, running out of time,
  the ending (BASIC's `fin` poked to 1), and staged scenes -- a bite, a bite
  through the rescued person, a grenade hit, a near miss, a grenade on the
  rescued person, drops onto an ant, a wall, each other's heads, a bad fall
  for each person. Each scene only places things; the game's own code does
  the rest. Then recursive descent from what ran. Every instruction in the
  map but three ran; the three are `FALL`'s branch for flag bit 3, which
  nothing sets.
- **The whole block.** The listing covers $5C00-$FFFF: the system variables
  (four named: `ERR_NR`, `ERR_SP`, `E_LINE`, `SEED`), each BASIC line an entry
  described by its listing, the seventeen scripts as labelled entries whose
  titles are generated from the game. All 41984 bytes reassemble with
  sjasmplus byte for byte, and the build fails otherwise.
- **Annotations.** `scripts/antattack_annotations.ctl`: every routine named,
  described and commented (281 comments), every variable and record field
  the code touches labelled, `@isub` for the offsets into buffers, and no
  skool2asm warnings.
- **Pages.** `scripts/antattack.ref`: How the game works, the City (the map
  from above, and the whole city in the game's projection with the block
  `DRAW_BLOCK` itself paints, captured by running it twice on a cleared and a
  filled buffer), and generated Levels (from the BASIC), Sprites (masked,
  with PNGAlpha 0) and Scripts (each run in the simulator on a game in
  progress and screenshotted). Published with `publish_pages.py --game
  antattack`; committed as 6d891b0.
- **Findings recorded in the annotations:** the ants XOR themselves into the
  map, so collision and bites are map lookups; `SHARE_CELL` cancels falls onto
  each other; a fall ending while stunned is never landed; the grenade is
  checked against both people on every flight frame; frames $F0-$F3 are never
  drawn; an unused script at $8B60; flag bit 3 set by nothing.
- **What went wrong on the way.** An early staged scene moved an ant's record
  without its map bit: it left a phantom block and the ant "bit" itself and
  was pushed up a block -- which is how the XOR was confirmed (now
  `_move_ant` in the build). `call_routine` has to write its return address
  into memory before creating the simulator, which copies the memory it is
  given. Throws in the scenes have to wait out the found-them tune, since keys
  pressed while a script plays are not seen.
- **Looked at, not used:** an earlier SkoolKit listing of the game (dbolli,
  2015) turned out to be a raw generated control file at the wrong origin.
- **Measured** in a throwaway `zx_server` with its profiler, 118 frames of
  walking at each of four places: 498k-585k T-states a frame (6-7 fps);
  `MARK_PLANE` 110k (constant), `COPY_TO_SCREEN` 82k, `DRAW_SCENE`'s CPIR scan
  81-85k, the gather 80-93k, `CLEAR_BUFFER_ROWS` 44k, `DRAW_BLOCK` 48k-123k
  (76-188 blocks), `PLANE_TO_BUFFER` 7-17k. No frame pacing, so faster
  drawing is a faster game; three speed-ups priced, none applied
  ([`performance.md`](performance.md)).
- **Not done:** sound for the scripts.

## 2026-09-25 and 2026-09-26 -- changes shared by all the games

- Every routine lists its callers (`ListRefs=2`; 75eefc4), the routines list
  shows each routine's name after its address (6ea1ac6), every memory map
  has a label column (c894718), and the pages use a sans-serif with a
  clearer monospace for the listings (869d274).

## 2026-09-27 -- to the Knight Lore standard, and these notes

- **The work.** Five agents with a shared brief: page modules for how-it-works
  pages, animations, sounds and the reference pages (bugs, pokes, facts),
  a live test of pokes in a private `zx_server`, and these notes. The lead is
  splitting the listing's big entries meanwhile: every sprite frame its own
  entry at $8000 + 64 x frame, every row of the city at $C000 + 128 x row, and
  the filler blocks labelled `..._PAD`.
- **These notes** were written from the listing, the BASIC, the build and the
  annotations, each claim checked against the code; where the code alone left
  a doubt, a scratch harness stepped the simulator from one `GAME_FRAME` to
  the next with staged state. The sounds agent wrote [`sounds.md`](sounds.md);
  the agent testing pokes supplied what it watched live, merged into
  [`driving.md`](driving.md) and the topic files.
- **New findings** (each in its topic file):
  - Walking while throwing blows the player up on the second frame: the
    player moves before the grenade, which is checked against the player's
    cell before it moves on (*measured* in the simulator; *watched* live).
  - A bad fall by either person loses the other's event in the same frame --
    an early return, and `PLAY_SCRIPT` reusing D (*measured*, five
    combinations; *watched* live).
  - A grenade's blast overwrites a paralysed ant's $FF: a near miss turns
    paralysis into a 24-frame stun, a hit into a respawn (*measured*;
    *watched*).
  - The grenade's own frames $68-$6B are drawn when the player is near its
    home outside the walls (*measured*; *watched*).
  - The world wraps: the player's home by the gate is five cells past the
    y = $FF edge, and
    `DISTANCE` wraps too -- a player 128 cells away in both x and y finds the
    person (*watched* live, by the pokes agent).
  - A bad fall is a drop of four blocks or more (fall count 5), and costs no
    energy (*measured*).
  - The random generator is reset to the same value at every attempt, and is
    stepped by every noise, footsteps included (*read*; the reset *watched*).
  - The fast ant's home cell has a ground block, which it XORs away while it
    stands there (*measured*).
  - The only gap in the outer wall is fourteen cells at x $AE-$BB on the
    y = $FF edge (*read* from the map).
- **Corrections to what had been written** (reported to the lead, who is
  changing the annotations and the ref):
  - The tape's program header does auto-run (line 1, the loader); it is the
    game's BASIC, loaded headerless, that nothing would run
    ([`loading.md`](loading.md)).
  - The unused script at $8B60 has no stream byte and an end marker after
    its third letter ([`scripts.md`](scripts.md)).
  - The grenade's frames are not unseeable ([`grenades.md`](grenades.md)).
  - `CHECK_RESCUED` stops at the end of the same frame, not the next, and
    `CHECK_GAME_OVER` after four more frames, not five
    ([`main-loop.md`](main-loop.md)).
  - `PLAY`'s copy of the random byte to SEED is undone by the RANDOMIZE that
    called it, and the BASIC has no RND ([`main-loop.md`](main-loop.md)).
  - A sixth NOP, at $852A, is unreachable ([`leftovers.md`](leftovers.md)).
  - The annotation at $B700 and the build's sprite table disagree about
    frames $F0-$F3 ([`ants.md`](ants.md)).
- **Not found:** the brief pointed at an Ant Attack section in
  `docs/game-examples.md`; there is none (that file has Manic Miner,
  Fairlight, Atic Atac and Knight Lore). This journal's first entry comes
  from the build script, the commit and the session's notes instead.
- **Applied** (the lead, the same day): every correction above is now in the
  annotations, the ref or the build, each checked first -- the header's LINE 1
  with `tapinfo`, the unused script's bytes, the frame counts from `PLAY`'s
  loop. Also corrected from the other agents' reports: `RANDOM` hands
  `NOISE` bit 4 of A, not the carry (checked for every first byte and both
  carries), and `NOISE` leaves the speaker on; a blown-up ant shows its blast
  only on frames it skips its move, a stunned ant spins at random, and the
  grenade's first blast frame is $F4 (measured, animations); the build's
  "ending" session runs the final script, but its BASIC stops with out of
  memory at line 3610 because c$ still holds level 1's long story card -- a
  real tenth rescue runs the whole ending, staged on the animations page;
  frames $F0-$F3 are drawn by nothing, shown from the code and from the runs,
  and "an ant on its back" was a guess, now gone. `HANDLE_EVENTS` now
  describes the lost-event bug.
- **The listing** has no placeholder titles and no unlabelled entries: 446
  entries, the 216 sna2ctl had split out of the sprite, buffer and city tables
  folded back by declared spans, each sprite frame and city row an entry of
  its own, the BASIC lines `LINE10` onwards, filler `..._PAD`. The city page
  gained layers: where the player starts, the gate, the ants' homes, and the
  waiting places by level.
