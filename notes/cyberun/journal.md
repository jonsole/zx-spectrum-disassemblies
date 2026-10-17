# Journal

## 2026-10-16 -- first look

- Listed the tape's blocks: all standard-speed, no protection. Decoded the
  BASIC: it loads `PIC` at 24576 and calls it, then loads `CY` at 24192 and
  calls 23424 ($5B80). See [`loading.md`](loading.md).
- Ran the game in a private `zx_server` (ports 14711/18000/18500). Found
  the keyboard routine by searching for `IN A,($FE)` and read the controls
  from it ([`input.md`](input.md)).
- Profiled two seconds of flight, then put a write watchpoint on a pixel
  row along the ground's top edge: the writer was the POP blitter at $E259,
  reached from the landscape routine at $D0BD
  ([`landscape.md`](landscape.md)). Measured the scroll from 16 consecutive
  frames: 2 pixels a pass, a pass every two or three frames.
- Looked for lives by diffing memory across a death. The first candidate,
  $AF02, was a sprite's colour-patch height that happened to go from 3 to 2
  -- a watchpoint showed it written by the attribute code at $AEF6, not by a
  death. The real counter is $F5ED (4 to 3 across the respawn).
- Read back from the lives code to the death byte $8F53 and the hit handler
  at $8F76; a poke there survived a long run but the ship then died of
  empty fuel, which led to the fuel word $CC4B and the burn at $B149
  ([`damage-fuel-lives.md`](damage-fuel-lives.md),
  [`pokes.md`](pokes.md)).
- Snapshotting the load with `tap2sna --start 23424` showed the block on
  tape is not the game as it runs: the entry moves it and rotates every
  byte by a nibble. The build will stop at $5C80, after that.

## 2026-10-16 -- the build and the listing

- Wrote `scripts/build_cyberun.py` from Alien 8's: `tap2sna --start 23680`
  stops the simulated load at $5C80, after the game's own loader has moved
  and decoded the block. The first sessions stalled: the menu plays the
  title tune before its key loop and only a key stops it (now cut short
  with ENTER), and holding SPACE to do that paused the game in a death
  sequence (SPACE is the pause key). First round trip: 42240 bytes,
  10439 instructions.
- Eight agents described the listing by address range. The code map was
  corrected from what they read: the sprite compositor's and landscape's
  tables of entry points, the object-type handler table (except type $1B's
  slot, which points at graphics), and edges out of code no session ran
  -- patched JRs and calls -- are now followed (`READ_EDGES`,
  `SHIFT_TABLES`, `ROW_LOOPS`, `TYPE_HANDLERS` in the build). The branch
  walk follows branches only out of code that ran, by design, so these had
  to be named.
- The annotations now decide where entries are: the build drops sna2ctl's
  block starts inside each annotated entry (`annotated_entries`), and
  `ctl_tools.py check --new-entries` checks a fragment the same way.
- A second pass by the same agents made every variable and table the code
  addresses an entry, and cleared the warnings from 1469 to 30; the last
  ones were fixed by hand. 900 entries, 0 warnings.
- Three agents wrote the topic notes from the listing and found about
  twenty descriptions the code contradicts (floor and ceiling swapped in
  the collision code, a colour table called contact effects, docking said
  to play the death sound, the ship's picture's size), now corrected in the
  annotations.
- Corrections to stage 0, each logged in its topic file: the four work
  areas at $5B80-$5BEF are the on-screen cells' collision-box lists, not
  per-strip areas; $99 turns a tile upside down and $FF mirrors it
  left-right (stage 0 had no names, a first draft had them reversed);
  $968D's death byte of 10 is docking, not a stage's end; $9EE3 is the
  pause key; bit 5 of the controls is the special-beam key.

## 2026-10-16/17 -- coverage, corrections and the pages

- Staged scenes in the build, each a new life put by the game's own
  restart: the launch from inside the finished rocket through the
  planet-secured screen to the next planet, a part and the full ore tank
  delivered, every add-on fitted, tours at five depths. Coverage rose from
  8528 to 10745 instructions run (95%). A tour first staged at map row 24
  ran the game off the bottom of the map into the frame's bitmaps, which
  added a guard: the build now fails if any executed address lies in a data
  entry (`check_executed_in_code`). The tours were then checked for stray
  writes: the only code bytes they change are the game's own patch points.
- Three notes agents wrote the topic files from the listing and found
  about twenty descriptions the code contradicts; a corrections pass applied
  all of them. Then the page agents found more (by recording, drawing and
  running the game), applied in two batches with the stale "never ran"
  claims (112 of them) the new coverage had made wrong.
- Reversed: the missiles' target table is NOT off by one. A corrections
  pass had called it a probable bug, misreading the `INC A` before the `SUB
  $14` (it is the free-record test, and makes the index the type less
  $13). The reference page's trial: 285 targets in 240 s, all the best on
  screen by the points order. Logged in each file it touched.
- Reversed: the stage-0 infinite-lives poke, `POKE 62671,0`, keeps the
  lives but runs the game-over sequence at every death (the `JR Z` after it
  takes the Z flag of `clear_play_area`'s last `DEC C`); stage 0 watched
  only the lives byte. `POKE 62671,183` (OR A) is the working one.
- `scripts/cyberun_data.py` lays out the level data record by record at
  build time and draws a picture into every graphic's entry, by the game's
  own drawing routines.
- Six page modules wrote the HTML pages; built with `--html`, 0 warnings,
  every page looked at in headless Edge.
