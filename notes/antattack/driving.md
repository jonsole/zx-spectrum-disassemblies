# Driving Ant Attack

**Question this answers:** how to run the original game from a script in the
emulator -- get from the load to a level, step it a frame at a time, move
and throw, stage a situation -- without timing anything.

**Short answer:** load `game_disassembly/antattack/antattack.z80`, which
resumes where the tape load ends. Break at `GET_KEY` ($8090) and hold B (or
G) for the girl-or-boy question; break at `WAIT_KEY` ($8097) for every
"press a key" and release at its RET ($809F); then step frames by breaking
at $8014 (`PLAY`'s CALL of `GAME_FRAME`) or $8E80 (`GAME_FRAME` itself), which
stop once a frame. Hold keys from one stop to the next. The records to watch
are the player at $B480 and the rescued person at $B490.

Tried live on 2026-09-27 by the agent testing pokes (private `zx_server`),
unless marked otherwise.

## The snapshot

`game_disassembly/antattack/antattack.z80` -- the build's `tap2sna` output,
the machine as LD-BYTES leaves it: PC $9700 with carry set and DE 0, so
`LOADED`'s checks pass, then IM 2 and RUN (*watched*: loads and starts).
`antattack.sna` beside it is the same state rebuilt from the reassembled
bytes; its PC is pushed on the loader's stack at $5BF0, which is harmless
here (*read*). Load `antattack.sld` and `antattack.asm` with
`load_debug_info` (both paths) for the labels. The tape itself
(`tapes/Ant Attack.tzx`) should load with `load_tape` and a LOAD "" too
(*not tried*).

A private server for checks: ports 14711/18000/18500, `--no-audio
--no-advertise --uncapped` (as used live, 2026-09-27).

## The breakpoints

| Address | Label | Stopped here means |
|---|---|---|
| $8090 | `GET_KEY` (USR 32912) | the girl-or-boy question is up; BASIC calls this in a loop until it gets B or G. Hold B (boy) or G (girl), release at $8093 *(watched)* |
| $8097 | `WAIT_KEY` (USR 32919) | a "press a key" wait: the story card, the ready message, the out-of-time screen, the retry message. Hold SPACE, release at $809F *(watched)* |
| $8000 | `PLAY` (USR 32768) | entered twice a level: first for the two frames that draw the city behind the ready message ($B438 = 2 here), then, after the key, to play ($B438 = 0) *(watched)* |
| $8014 | `PLAY`'s CALL `GAME_FRAME` | a frame is about to run; once a frame *(watched)* |
| $8E80 | `GAME_FRAME` | the same point, inside the call *(measured, simulator)* |
| $8009 | `PLAY`'s loop top | the key-1 test, before each frame *(read)* |
| $8013, $8033 | `PLAY`'s two RETs | back to BASIC: key 1, or the stop count ran out *(read)* |
| $8F00 | `HANDLE_EVENTS` | after drawing; the two event bytes are about to be read -- a place to stage an event *(watched)* |
| $8E02 | `PLAY_SCRIPT` | a message or sound: A is the script number. A logpoint here, "script {A:d}", lists every message *(watched)* |
| $8A00 | `MOVE_ANT` | an ant moves; a logpoint "{IX}" counts moves per ant *(watched)* |
| $8FBF | in `MOVE_RESCUEE` | the person has just been found *(read)* |
| $8EB3 | in `CHECK_RESCUED` | both are out: a rescue *(read)* |
| $8EE9 | in `CHECK_GAME_OVER` | energy or time ran out; four more frames *(read)* |
| $8EF2 | `FINAL_SCRIPT` (USR 36594) | the tenth rescue's ending *(read; played in the build)* |
| $97A0 | `RESTART_BASIC` | BREAK (or any BASIC error) is restarting the program *(watched)* |

**Getting to play:** from the load, run; at $8090 hold B, run to $8093,
release; at $8097 (the story card) hold SPACE, run to $809F, release; at
$8097 again (the ready message) the same; then run to $8014 for the first
frame of play. Save a snapshot there and start every trial from it
*(watched)*.

**Moving:** hold keys and run to $8014 N times. V walks a cell a frame; C
jumps; V and C together climb a one-block step; SYMBOL SHIFT and M turn a
quarter a frame; S, D, F, G throw 2, 4, 8, 16 cells; 0, P, ENTER, SPACE pick
the view; 1 goes back to the gate (a retry). CAPS SHIFT + SPACE is BREAK,
which restarts the whole game from the title once BASIC is running *(keys
watched; the rest read, see [`movement-and-collision.md`](movement-and-collision.md))*.

## Staging

- **From a snapshot, every time.** A failed attempt leaves the game parked
  at `WAIT_KEY` for the retry message, and further frame waits stop there
  instead *(watched)*.
- **Positions** are the first three bytes of each record: the player $B480,
  the rescued person $B490, the grenade $B4A0, the ants $B4B0-$B4F0. Heights
  are block counts; 0 is the ground.
- **Open ground:** the build's `_open_ground` finds the first 11 x 11 empty
  square, at x $8D, y $8B (141, 139) *(watched)*.
- **Ants carry their map bit.** To move an ant, XOR its height bit out of the
  map at its old cell and into the new one ($C000 + 128(y - $80) +
  (x - $80)); moving the record alone leaves a phantom block and the ant
  "bites" itself *(watched; played in the build)*.
- **The view** follows the player only at the edge of its window: after
  placing the player, hold SPACE (or another view key) for one frame to
  re-centre on them *(watched)*.
- **The person to be rescued** on level 1 waits at $B6, $F3, height 1
  *(watched)*; to find them at once, put the player beside them at the same
  height (the build's `_beside_rescuee`). To have them follow, set $B49D to 1.
- **A rescue:** put both outside the walls, any coordinate below $80 (the
  build's `_both_outside` uses $70, $70 and $71, $70).
- **The clock:** $B436-$B437, big-endian; the build's `_nearly_out_of_time`
  writes 0, 20.
- **Energy and grenades:** $B432, $B434, $B430 (low bytes; the high bytes
  are always 0). BASIC resets them at every attempt.
- **Events:** at $8F00, write the player's event at $B48F or the rescued
  person's at $B49F (1 step, 2 bad fall, 4 bitten, 8 blown up) *(watched)*.
- **Winning in one:** BASIC's `fin` (rescues needed, 10) is a long-named
  numeric variable in the VARS area; the build's `_one_rescue_to_win` finds
  and sets it to 1 *(played in the build)*.

## Variables worth watching

| Address | Label | What |
|---|---|---|
| $B480-$B482 | `PLAYER` | the player's x, y, height |
| $B484 | `PLAYER_FACING` | 0 y up, 1 x up, 2 y down, 3 x down |
| $B485, $B486 | `PLAYER_FALL`, +$06 | fall count, stun |
| $B48F | `PLAYER_EVENT` | this frame's event, cleared by `HANDLE_EVENTS` |
| $B490-$B492 | `RESCUEE` | the rescued person's position |
| $B49D | `RESCUEE_STATE` | 0 waiting, 1 following, 2 out (BASIC's `w`) |
| $B42F-$B434 | `AMMO`, energies | grenades, the player's and the rescued person's energy |
| $B436-$B437 | `TIME` | the clock, big-endian, one tick in three frames |
| $B438 | `FRAMES_LEFT` | $FF while playing; a small count when stopping |
| $B420-$B422 | `VIEW_ORIGIN`, `VIEW` | where the view starts and which of the four |
| $B428-$B42B | `RANDOM_BITS` | the ants' random generator; 01 01 01 01 at every attempt's start *(watched)* |

## Traps

- **Keys are not waited off.** `WAIT_KEY` returns as soon as a key is down,
  and the next wait passes straight through if it is still held. Release at
  $809F *(read; the release point watched)*.
- **Scripts freeze the game.** A message's notes play inside the frame; the
  found-them tune is about four seconds. Keys pressed meanwhile are never
  read; the build's scenes wait these out *(read, played)*.
- **Screenshots:** `get_screen` returns the CRT image at the stop; render
  $4000 (6912 bytes) from memory instead for a clean picture *(watched)*.
- **Logs persist.** `get_log` keeps lines across snapshot loads; read it
  with `since` *(watched)*.
- **Interrupts are off during play**, so `set_break_on_interrupt` and
  anything else that relies on the 50 Hz interrupt sees nothing between the
  frames of a level *(read)*.
- No hangs were met live *(watched)*.

## Pokes

Being tested live on 2026-09-27 by another agent; the tested pokes, each with
its trial with and without, go here and on the site's pokes page when done.
