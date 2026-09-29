# Journal

What was done, how, and what came of it. Newest last.

## 2026-09-28 -- stage 1: the pipeline

The first of four stages (the pipeline; every routine described; the pages;
the notes), done by one agent with the user away; the decisions below were
its own, and are recorded so they can be revisited. Nightshade's build was
the model, copied and adapted rather than shared.

- **The tapes.** Both 48K releases from ZXDB, `Fairlight (1985)(The
  Edge)(Release 1).tzx` and `(Release 2).tzx`, kept in `tapes/` at the
  user's request. `tapinfo` gives a BASIC loader of 1373 bytes and two turbo
  blocks (3092 and 48538 bytes); Release 2 has a short copyright-warning
  BASIC program first. The BASIC's REM names the Alkatraz Protection System
  (June 1985); it checks PROG for an Interface 1's maps and runs `RANDOMIZE
  USR 24194`.
- **Finding the entry.** tap2sna's plain simulated load stopped at the end
  of the tape, PC $DBF6, still in the loader. Running on from there in the
  Python simulator, logging each change of page, showed the loader return
  to $C47C and a loop at $C000 calling the ROM's KEY-SCAN: the loading
  tune, waiting for a key. $C47C sets SP, calls $C000 and (Release 2) sets
  IY, copies the tables into place and jumps to $F065. `tap2sna --start
  50300` gives the snapshot, before the game has run. Krumlinde's $F065
  entry, SP $6392 and IY $FF80 were reconstructions; the real entry is
  $C47C, SP $639A (Release 2; $6392 in Release 1) and IY set by the
  start-up.
- **The loader, decrypted by hand.** From a tap2sna trace with IX in each
  line, every execution of the store at $DB66 gave the address of each
  loaded byte: header $DADD, the screen's 216 lines in the order the loader
  pushes them, then pieces from a table at $DAC3 that its first piece
  extends -- $5B00-$DABF, $DD39-$FFFF, and 3 bytes of checksum. The byte
  formula (key, count, address, tape byte) was read from $DB41-$DB89 and
  reimplemented; with the key and table from a second tap2sna stopped at
  $DADF, it reproduces the snapshot exactly (bar the countdown's digits on
  the screen). `check_loader()` does this every build.
- **Which release.** Krumlinde's `fairlight.asm` assembled (scratchpad) and
  compared with both: Release 2, every code byte; Release 1's code is laid
  out differently from $F065 up. What differs is in
  [`versions.md`](versions.md): Release 1's joystick routine is `XOR A :
  RET` -- switched off; Release 2 adds the 9 key and "9-JOY".
- **Decision: Release 2**, as the brief asked if Krumlinde's matched one.
  The build refuses any tape whose $C47C is not Release 2's.
- **The start-up's copies.** Release 2's $C47C copies $C4E0 to $A924 (3420
  bytes) and $D2F0 to $B734 (932), then the master copy to $639C. Found by
  stepping the simulator until $A924, $B734 and $639C changed. The tape's
  bytes at those three places are leftover source text.
- **Leftovers.** Plain assembler source text at $617C, $A8FC-$B685,
  $BCA4-$BFFF, $C4BA, $D135-$D2EF, $D694-$DABF, and at $639C-$689C and
  $B734-$BAD7 under the copies. At $DD39 a binary tree of the assembler's
  symbols: 64 whole nodes, names and values, every value an instruction of
  Release 2 that ran ([`symbols.md`](symbols.md)). 99 of the 101 DEFB lines
  in the text are records of the object table, byte for byte.
- **The code map by playing.** SkoolKit's C simulator from $C47C with
  interrupts on (so it was believed: the simulator offers them, but the game
  turns them off at $C487 and takes none -- corrected on 2026-09-29) and a
  tracer holding keys and a Kempston stick. Sessions
  ([`driving.md`](driving.md)): the keyboard; the joystick (9 to turn it
  on); every room 2-80 but the title's, entered the way a new game enters
  its first ($FFB4, then $F09B with SP $639A), each with a round of play,
  every thing picked up, used and dropped, and a wait; every door of every
  room; game over; the end of the quest, failed and (with thing 5 fetched
  from room 33) succeeded; too heavy; and every other object put where the
  knight stands. 3476 of 3542 instructions ran; descent added 66. About 40
  seconds.
- **Traps.** The first room tour died in room 7 and sat at GAME OVER: LIFE
  is two digits at $FF95/$FF96, and the sessions now top it up before every
  step. Picking up: a thing placed just in front of the knight was not
  taken; trying offsets round him showed the pick-up wants the thing where
  he stands. The simulator's register dict needs `^AF`, not `A'`/`F'` at
  indices 8 and 9 (those are IXh and IXl).
- **Strings after CALLs.** The printer at $EBFE reads its string from its
  return address ($C8 x y moves, $A4 ends). `fairlight_data.inline_strings()`
  finds each CALL and its string; descent is forbidden to decode them, the
  build fails if any string byte ever ran, and the listing shows each as
  its text, generated from the glyph numbers (0 space, 1-26 letters, 27-36
  digits, 37 full stop, 38 dash).
- **Rooms.** 81 at $68B0, each a length word, a colour byte and commands to
  $E5; 56 parts at $758C with no colour byte. The interpreter's operand
  lengths were read from $E5E8 onwards; codes $00-$BF are points (row,
  column), not tiles. All 137 streams parse to exactly their lengths. Then
  measured: every room drawn in the simulator with a stop at the fetch
  ($E5A6) -- 2348 command addresses, all command starts in the parse; the
  55 never fetched are the five parts no room draws (9, 11, 12, 33, 52).
- **Sprites.** Image then mask, (width/8) x height each; which there are
  is in no one table. The templates name 49; the build notes the sprite of
  every object in use after every step of every session, which adds 40. No
  two overlap, and no gap between seen frames needed filling. Three
  stretches between sprites are left for stage 2.
- **Control files.** sna2ctl's map over $5B00-$FFFF; generated
  (`fairlight_data.py`): rooms, parts, sprites, the font, the object table,
  the templates and patches, the symbol table, the textures and the
  strings. The annotations (thin): 25 spans over the leftovers, regions and
  titles, the variables split into named fields, labels for the few
  addresses the code or the prose names, `isub` for the tune's `LD IXH`
  instructions (sjasmplus rejects `IXh`) and for two `LD HL,$C000`, and
  `nowarn` on the instructions that store into operands.
- **Round trip**: 42240 bytes byte for byte; the snapshot written back is
  the one read (47269 bytes); 0 warnings. Getting there: long DEFM lines
  split at 16, comments that named addresses rewritten as `#R` links or
  without the address, and labels clashing between the tape copy and the
  runtime home of the same table renamed (`OBJECTS_TAPE`, `OBJECTS`).
- **HTML**: `--html` with `fairlight.ref` (the family's style sheets and
  `fairlight.css`), a Provenance page crediting Krumlinde, labels in every
  memory map, the logo cut from the loading screen (the scroll: its yellow,
  red and black in character columns 4-27 of the top seven rows, the one
  big piece and the pieces of "a prelude" below row 40), each sprite's and
  texture's picture, and the font drawn with `#UDGARRAY`. Looked at in
  headless Edge: the index, a sprite, the font, the symbol table, the
  title routine, the memory map, the provenance page. No page modules yet.
- **Krumlinde's map beside this one** (`krumlinde.txt`, every build): 3388
  of this listing's 3545 instructions are his too; 79 of 86 routines start
  at his labels. Corrections to his notes are in
  [`krumlinde.md`](krumlinde.md).
- **The old build.** `scripts/build_fairlight.py` used to assemble
  Krumlinde's source for the emulator's "ZX Spectrum: Fairlight" launch.
  It is now `scripts/build_fairlight_krumlinde.py`, writing to
  `game_disassembly/fairlight_krumlinde/`, and the emulator's
  `.vscode/tasks.json` and `launch.json` point at it; its old output's
  `fairlight.sna` in `game_disassembly/fairlight/` was deleted, as the new
  build writes `fairlight.asm` and `.sld` there.

### For stage 2

- The author's 64 names ([`symbols.md`](symbols.md)) should be the
  starting labels, beside Krumlinde's (`krumlinde.txt`).
- Unrun code, 22 runs and 149 bytes, is listed in
  `fairlight-coverage.txt`: branches of the tune player, a few room-drawing
  mode cases, the knight being touched ($F28B), three kinds' cases in the
  meeting code at $F959, two cases of the door code ($F85D, $F8DD).
- A suggested split of the code into five ranges of similar listing
  length (the 86 routines' 4117 listing lines, cut at routine starts):
  $B686-$E7B1 (862 lines: the start-up, the loading tune, the title page,
  the messages, compositing, entering and drawing a room and the command
  interpreter), $E7B2-$ED46 (819: the fill, lines, repeats and parts,
  placing objects, the printer, the start of sprite culling), $ED47-$F2F6
  (878: culling, sorting and drawing sprites, the fast fills, the title
  routine, the keyboard and joystick, turning sprites round, LIFE, and the
  start of the object dispatcher CHE3D at $F1E0), $F2F7-$F905 (761: the
  objects' states, the knight's controls, picking up and dropping, doors),
  and $F906-$FF69 (797: EEN, meeting objects, collision, movement
  (ZOOMIN), entering a room (ROOMST) and the main loop).

## 2026-09-29 -- stage 2: every routine described

Five agents, one per range of the code (the split above: $5B00-$E7B1,
$E7B2-$ED46, $ED47-$F2F6, $F2F7-$F905, $F906-$FFFF), each wrote a
control-file fragment in instruction ranges and a notes draft; the lead
merged the fragments into `scripts/fairlight_annotations.ctl` (`fl_merge.py`
in the scratchpad: each range's entries replaced whole, the `; span` and
`nowarn` lines kept in one block before the first entry) and built.

- **What was merged.** Every one of the 373 entries titled, described and
  labelled -- no `SUB`, `DATA`, `TEXT` or `VAR` placeholders left; the
  author's names used where the symbol table or the source text gives them
  (CHE3D, ROOMST, ZOOMIN, MIMAN ...); every variable at $FF80 named, the
  names agreed between the ranges (range 5 owned $FF80 and checked the
  others' suggestions against the code). The round trip is still byte for
  byte, the snapshot written back is the one read, and sna2skool, skool2asm
  and sjasmplus give 0 warnings.
- **The lead's fixes at the merge:**
  - range 2's comment `$ECAE,3 print it` gave the `CALL PRINT` at $ECAE a
    length, which made it a sub-block that cut into the string the data
    generator lays out after the call and broke it; it is now a comment on
    the `CALL` alone;
  - the $617C entry still carried stage 1's placeholder label (`TEXT617C`):
    it is `SOURCE_AND_STACK` now, the stack's top staying `STACK_TOP`;
  - `@ keep` directives at $EC7A and $ECF8 (`LD DE,$FFFF`: the constant -1,
    which sna2skool had turned into `RIDE_DIRECTION`) and at $F8B6 (the
    scratch record's +5, $FFD0, not `PRINT_X`), so those operands stay
    numbers (range 5 had one of its own at $FCB4, the minus-20 step);
  - the coverage report (`report_coverage` in the build) now counts every
    instruction of the listing's code entries, not only the code map's, so
    code reached only from code that never ran ($F493, behind a branch in
    an unrun stretch) is listed too: 3580 instructions, 3476 run, 104 not,
    31 runs of 192 bytes (stage 1: 3542, 66, 22 runs of 149 bytes). But see
    stage 3 below: 35 of those are string bytes.
- **Findings**, each in its topic file now: interrupts are off for the game
  ([`start-up.md`](start-up.md)); the loading tune's player and its end
  ([`loading-tune.md`](loading-tune.md)); every room command and the fill's
  texture layout ([`rooms.md`](rooms.md), [`textured-fill.md`](textured-fill.md));
  the compositor's four pages and the depth order, measured
  ([`compositing.md`](compositing.md), [`drawing-objects.md`](drawing-objects.md));
  the record's every field, the six fixed records as the room's box, the
  object table's three parts ([`object-records.md`](object-records.md),
  [`object-table.md`](object-table.md)); the states, the freeze, the decoy
  and Release 1's lock-up, played in both releases
  ([`object-states.md`](object-states.md)); gravity, riding, climbing and
  animation ([`movement.md`](movement.md)); collision and pushing
  ([`collision.md`](collision.md)); meetings, strikes and the stale number
  ([`meeting.md`](meeting.md)); chasing ([`chasing.md`](chasing.md));
  mirroring and why EEN turns frames back ([`turning-sprites.md`](turning-sprites.md));
  the knight's keys, jump, fight and fall damage ([`knight.md`](knight.md));
  carrying and room 19's bug ([`carrying.md`](carrying.md)); doors
  ([`doors.md`](doors.md)); entering a room and EEN's direction
  ([`entering-rooms.md`](entering-rooms.md)); the main loop and using things
  ([`main-loop.md`](main-loop.md)); about forty more of the author's names
  from the source text ([`symbols.md`](symbols.md)); the leftovers
  ([`leftovers.md`](leftovers.md)).
- **Scenes staged** in scratch scripts (not in the build): the winged
  creature's strike, a guard killed, a wraith destroyed, the troll's touch,
  the freeze and the jump in both releases, the decoy, a far side taken,
  room 61, room 19's pick-up, the four pages ([`driving.md`](driving.md)).
  So several of the coverage report's unrun runs have been run, just not by
  the build.
- **What turned out wrong** in stage 1 (each topic file now says so):
  - *Interrupts.* Stage 1 said the game runs with interrupts on, in IM 1,
    turned on by the `EI` at $C018, *measured* by the sessions. `START`
    turns them off at $C487, three instructions after that `EI`, and nothing
    turns them on again; the sessions only offered interrupts, and IFF
    stayed clear (range 1, *read* and *measured*: FRAMES never moves).
    Corrected in `loading.md`, `krumlinde.md`, `driving.md` and above.
  - *`SAVED_SP`* ($FFF8) is SP only in the screen clear; in the object code
    it is the found record's number (the author's `T+20`): `FOUND_RECORD`.
  - *The object table* is 163 six-byte, 174 eleven-byte (the doors) and 44
    six-byte records, not 163 and 218.
  - *+9 to +11* are lengths from the corner, not half-sizes.
  - *The six records at $BC18* are the room's floor, ceiling and walls, set
    by the patch codes.
  - *`DRAW_ROOM_NUMBER`* read as if it drew a number: `DRAW_CURRENT_ROOM`.
  - *Kind 4* adds 10 to LIFE, making 99 at 90 or more; not "only below 90".
  - *The last loaded piece* is the loader's return address and one checksum
    byte, not "3 bytes of checksum".

## 2026-09-29 -- stage 3: the notes

The notes brought to the skill's standard from stage 2's five drafts: a
topic file per question (the README lists them), each checked against the
final listing and, where the drafts disagreed, the code. `README.md`,
`overview.md`, `memory-map.md`, `driving.md`, `krumlinde.md`,
`symbols.md`, `loading.md` and `versions.md` brought up to date.

- **Settled here** (*read* unless said): the axes -- the listing's
  variables use x (+6), y (+7, the height) and z (+8), and the notes follow
  them; the object table's parts *compared* by walking it (163 + 174 + 44);
  the keys are things 1-8 -- six of type 14, thing 5 and thing 7 (range 4
  had "seven of type 14"); the loader's checksum test: the decrypted
  checksum byte must equal the sum of the tape bytes before it, the running
  sum at $DADC and the last byte in H (stage 1 was right about $DADC; range
  1's open question about H is answered); Release 1's `DI` at $F069 and its
  I00 at $F24F (*compared* in its snapshot); carrying one of room 19's
  unnumbered things out of a room would make EEN overwrite door 214's
  destination, key and arrival x (not run).
- **Found wrong elsewhere, reported to the lead** (not fixed: these notes
  touch only `notes/fairlight/`):
  - the coverage report counts the first bytes of the strings after `CALL
    PRINT` (shown in the listing as instructions) as code that never ran:
    9 of its 31 runs, 35 instructions, 38 bytes ($B689, $DFF5, $E058,
    $E076, $E081, $E08F, $EBFB, $F07D, $F0BC). The real figures are 3545
    instructions, 69 unrun, 22 runs of 154 bytes. `krumlinde.txt`'s "ours
    and not his" counts them too;
  - the `JR Z` that the string bytes at $DFF5 decode to gives $E048 a false
    "This entry point is used by the routine at $DFF2";
  - `Machine`'s comments in `build_fairlight.py` still say the game runs
    with the ROM's interrupt routine on, and `_enter`'s docstring says the
    thing of kind 9 enters a room the same way -- it runs EEN first, which
    the shortcut skips;
  - the listing's range-4 entries ($F2F7, $F309's cases, $F595's direction
    table, $F7B0, $F7BA) call +8 "y" where the variables and range 5 call
    it z and y the height; and +14 is "the state" in some entries and "the
    behaviour" in others.

- The listing names the axes two ways: $F2F7-$F905 call +8 "y" (across
  the floor) and +7 the height; $FA83 on and the variables call +7 "y" and
  +8 "z". The annotations' header says so; rewording one side to match is
  still to do (found by the how-it-works agent, stage 3).
