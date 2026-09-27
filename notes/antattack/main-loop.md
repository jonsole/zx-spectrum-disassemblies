# Main loop

**Question this answers:** what happens in one frame of play, in what order,
and how the machine code decides to hand control back to BASIC.

**Short answer:** `PLAY` ($8000, USR 32768) disables interrupts and loops:
test key 1, run one frame (`GAME_FRAME`, $8E80), check for a rescue and for
game over, and count `FRAMES_LEFT` ($B438). A frame moves the player, the
person to be rescued, the grenade and the five ants, reads the view keys,
draws the whole view, then plays any messages and sounds and ticks the
clock. There is no frame pacing: the game runs as fast as it can draw.

## How it works

```
PLAY $8000                 DI; high byte of the sprite list's end marker = $FF;
                           PRINT_COUNTERS (scripts 4, 8, 11: grenades, energies)
  $8009 loop:              key 1 down -> EI, RET (back to BASIC at once)
    GAME_FRAME $8E80
      MOVE_PLAYER $82C0      READ_CONTROLS, MOVE_OR_RESPAWN, CHOOSE_FRAME
      MOVE_RESCUEE $8F80     waiting: the scanner, the find test
                             following: SHARE_CELL, FOLLOW_PLAYER, MOVE_OR_RESPAWN,
                             CHOOSE_FRAME
      MOVE_GRENADE $83E0     THROW_GRENADE, MOVE_OR_RESPAWN, BLAST_FRAME,
                             GRENADE_BLAST
      MOVE_ANTS $80D3        ANT_TURN x 5 (BLAST_FRAME, MOVE_ANT)
      READ_VIEW_KEYS $8400   0, P, ENTER, SPACE
      DRAW_VIEW $84A0        gather, planes, clear, project, scroll, sort, paint, copy
      HANDLE_EVENTS $8F00    bites, blasts, falls, steps -> energy, scripts
      GRENADE_SOUNDS $8FD0   thrown, bang, good shot -> scripts
      COUNT_DOWN_TIME $8DD0  one tick every third frame, printed through the ROM
    CHECK_RESCUED $8EA0      both outside -> state 2, script 13, FRAMES_LEFT = 1
    CHECK_GAME_OVER $8ED0    an energy or the time at 0 -> FRAMES_LEFT = 5 (once)
    FRAMES_LEFT = $FF: loop; else FRAMES_LEFT - 1, loop unless 0
  $802C                      copy RANDOM_BITS' first byte to SEED; EI; RET
```

(*read*; every call *played*.)

**`FRAMES_LEFT` ($B438) is a frame budget and a stop signal at once.** BASIC
POKEs 2 before the first call of a level, so that call runs two frames and
returns -- enough to send everything home and draw the city behind the ready
message. On the second call it is 0; the first frame's decrement makes it $FF,
which means "run until told to stop". `CHECK_RESCUED` stores 1 and
`CHECK_GAME_OVER` 5. The decrement happens at the end of the same frame
that stored the count, so 1 means no more frames at all and 5 means four
more after the one that noticed (*read*). `CHECK_GAME_OVER` only acts while
the count is $FF, so it fires once, and it cannot fire during the two-frame
call. Both also write `TIME_TICKS` ($B435), which only delays the next clock
tick; BASIC resets it before the next call anyway.

**Consequences of the order** (*read*):

- The player moves before the grenade. A thrown grenade is checked against
  the player's cell before it moves on, so a player walking forward behind
  their own grenade walks into it ([`grenades.md`](grenades.md); *measured*).
- The rescued person moves after the player and sees where the player is
  now; the ants likewise chase the player's new position.
- The view keys are read after everything has moved and before drawing, so a
  new view shows this frame. `SCROLL_VIEW` runs inside `DRAW_VIEW` after the
  map has been gathered, so a scroll shows next frame.
- Messages and sounds come after the frame is on the screen, and a script
  plays its notes there and then: the whole game waits. The found-them tune
  (script 12) holds it up for about four seconds, the ending for about nine
  ([`scripts.md`](scripts.md), [`sounds.md`](sounds.md)). Keys pressed meanwhile
  are not seen, since nothing reads them (the build's scenes wait these out).
- The clock is last, and the ROM prints it: every third frame costs about
  9000 T-states more (*measured*, simulator, 2026-09-27 -- the frames went
  540k, 540k, 549k, repeating).

**Interrupts are off for the whole run** (`DI` at $8000, `EI` only at the
two exits). FRAMES does not count, the ROM's keyboard scan does not run, and
every key is read with IN directly: key 1 on port $F7FE bit 0, V and C on
$FEFE, SYMBOL SHIFT and M on $7FFE, S to G on $FDFE, and 0, P, ENTER, SPACE
on their own half-rows (*read*). Nothing waits for the 50 Hz interrupt, so a
frame takes as long as its drawing: about 540,000 T-states, 6.5 frames a
second ([`performance.md`](performance.md)).

**On the way out** `PLAY` copies the random generator's first byte into
SEED ($5C76) "for BASIC's RND" -- but BASIC calls it as RANDOMIZE USR 32768,
and RANDOMIZE then stores the USR's result (BC) in SEED, overwriting it; and
the BASIC never uses RND anyway (*read*: the listing has no RND; the ROM's
RANDOMIZE writes SEED). See [`leftovers.md`](leftovers.md).

## How this was found

Read `PLAY`, `GAME_FRAME` and each routine it calls; the order of the calls
was then set against what the staged scenes did in the build. For these
notes a harness stepped the simulator from one `GAME_FRAME` to the next
(`run(pc, $8E80)` with interrupts on) and read the T-state counter and the
records at each stop (2026-09-27; the scratch script was not kept in the
repository).

## Confidence

The order is *read* and every routine ran in the playthrough (*played*). The
per-frame stop at $8E80 was *measured* in the simulator: each stop is one
frame, the clock advancing once every three. Not yet *watched* live (see
[`driving.md`](driving.md)).

## Disassembly corrections

- `CHECK_RESCUED` ($8EA0) says the game "stops next frame" and
  `CHECK_GAME_OVER` ($8ED0) "five frames later". Counting the decrement at the
  end of the noticing frame: a rescue stops at the end of the same frame, and
  game over after four more. Reported to the lead.
- `PLAY`'s comment at $802C ("for BASIC's RND") describes an intent the BASIC
  never uses and RANDOMIZE immediately undoes. Reported to the lead.

## Open questions

- None about the order. Whether any key but 1 can end `PLAY` early: no, from
  the code (*read*).
