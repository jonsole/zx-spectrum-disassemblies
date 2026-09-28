# Journal

What was done, how, and what came of it. Newest last.

## 2026-09-28 -- stage 1: the pipeline

The first of four stages (the pipeline; every routine described; the pages;
the notes), done by one agent with the user away; the decisions below were
its own, and are recorded so they can be revisited. Alien 8's build was the
model, copied and adapted rather than shared.

- **The tape.** The user's upload, a zip holding `Nightshade (1985)(Ultimate
  Play The Game).tzx` (Ramsoft MakeTZX, 42355 bytes), copied to
  `tapes/Nightshade (1985)(Ultimate).tzx` beside the other originals. Six
  files, each a header and a data block: `NIGHT` (BASIC, LINE 0), `SP` CODE 16384,6912, `0` CODE
  24576,34816, `1` CODE 23424,43, `2` CODE 23728,1, `3` CODE 23672,2. The
  BASIC (listed with `tapinfo -b 3`) beeps five times, clears to black,
  prints that the game is loading, then `LOAD ""SCREEN$` and four `LOAD
  ""CODE`s, and `PRINT USR 23424`.
- **The protection** (*read*, from the three small blocks and the game):
  block `1` is a routine in the printer buffer ($5B80) that does `LD A,R :
  OR $80 : LD R,A`, unscrambles the game block in place a pair of bytes at
  a time (`LD A,(DE) : RLD : LD (DE),A` with DE and HL on the two bytes),
  moves $6000-$E7FF down to $5E00 with LDIR, and jumps to $5E00. Block `2`
  puts $E9, `JP (HL)`, into NMIADD ($5CB0); block `3` puts $6334 into
  FRAMES ($5C78). The game checks all three: `START` ($BDFE) returns to
  BASIC unless FRAMES' middle byte is $63; the object dispatcher `DISPATCH`
  ($D593) ends `JP $5CB0`; and `$C1F4`, at every new game, jumps to 0
  unless R's bit 7 is set. And `NEW_LIFE` ($CBAC) resets unless the `DEC
  (HL)` at $CBDD that takes a life is intact -- a guard against the obvious
  infinite-lives poke.
- **The snapshot.** `tap2sna --start 24064` runs the ROM's LOAD and the
  loader and stops at $5E00: `game_disassembly/nightshade/nightshade.z80`,
  in a fifth of a second. `check_loader()` in the build does the loader's
  unscrambling and move on the tape's own block and checks the result is the
  snapshot's $5E00-$E7FF, and that block `1` is in the printer buffer: the
  loader's description is checked every build.
- **The first run failed** -- the menu came up, and starting a game showed
  the ROM's copyright message: the simulator started with R at 0, and the
  R check reset the machine. The `Machine` now takes R from the snapshot.
- **What is disassembled: $5B00-$FFFF**, as for Alien 8. Below $5E00: the
  printer buffer (zeros), the loader's routine (marked code by following it
  from its first instruction; it ran in tap2sna's load, not in the
  sessions), the system variables (with `FRAMES` and `NMIADD` labelled and
  `NMIADD` a one-instruction code entry), and the BASIC program, into which
  the game's stack grows. Above the code: the screen buffer and attributes,
  and the tables `$E0FB` builds. The tape's own tail at $E600-$E7FF is a
  second copy of $E400-$E5FF, left by the move.
- **Leftovers, measured.** The Python simulator with a memory recording the
  first access to each address of $5B00-$5DFF and $E5C4-$FFFF, from the
  start through the menu, play, a new cell and more play: below $5E00 the
  only first reads are FRAMES' two bytes and NMIADD, and the stack reached
  $5DE8; above the code nothing is read before it is written; $F195-$F1FF
  and $F800-$F8FF are never touched; $F194 is written one byte past the
  attribute buffer by `$C889` (a watch on it stopped there).
- **The code map by playing.** SkoolKit's C simulator from $5E00 with a
  tracer holding keys and a Kempston stick. Sessions (the build's
  `sessions()`, recipes in [`driving.md`](driving.md)): each control method
  and directional control (both views), keyboard rounds that walk, turn,
  throw, turn the town round and pause; every one of the 625 cells a knight
  can start in, by the game's own restart; game over; the two bonuses and
  the faster walk wearing off; each kind of find picked up and thrown, eleven
  carried, both antibody records busy; each kind of antibody at a monster of
  graphics 112-127, one at 64-79 and one at the creature of 136-139; and the
  four objects, each picked up, thrown at nothing, picked up again and thrown
  at its villain, the percentage at 100, the ending and back to the menu.
  4705 of 4806 instructions ran; descent from what ran and from the six
  tables of routines added 101. The build takes about two minutes, the cell
  tour 98 s of it.
- **Two session traps.** A poke made mid-turn landed inside the knight's
  own update, which then wrote his walking frame's bit back over the
  vanishing graphic and left graphic 4 in his record: no new life, and a
  hang. Pokes now wait for `MAIN_LOOP` ($BE71). And a villain standing in a
  cell kills the knight the moment he appears there, as often as he comes
  back, so the waits keep the lives topped up.
- **Staging a strike.** A thrown thing moves twice a turn by twice its step,
  so a villain put *on* it was already 48 units behind when the test ran;
  it is put four steps ahead. An antibody facing a close wall dies in the
  turn it is thrown, unseen; the session turns and retries. A strike on a
  monster of 112-127 may kill, change or split it (`$C0D1`), so the session
  knows it happened by the score, which every outcome adds to.
- **The percentage** (*read*, then *measured*): 10288 per visited cell and
  three per villain, the carries out of 16 bits counted in BCD; 637 gives
  exactly 100, and the town has 625 standable cells. The BCD count wraps
  past 99 without a carry, so setting every visited bit (1024) gave 62%;
  setting the 625 gave 100.
- **The pairs** (*read*, from `$D88E`, `$D8E7`, `$DB43` and `$C554`): the
  object in record n (graphics 7, 6, 5, 4) kills the villain in record n
  (graphics 108, 104, 100, 96). Drawn by the build, the objects are a
  hammer, an hourglass, a cross-shaped thing and a book, and the villains a
  skeleton, a figure with a scythe, a hooded figure and a white figure; the
  game's text does not name them.
- **Control files.** sna2ctl's map over $5B00-$FFFF. The level data from
  `scripts/nightshade_data.py`, which walks each table the way the code reads
  it and stops the build if one does not tile its range: the map (32 rows),
  the drawing order (32 records of 5), the building table (72 words) and the
  58 buildings, the box table and lists, the tiles' edge bytes, the tile
  table and 51 tiles, the 3 edge pictures, the graphic table and the 94
  sprites in three runs around two sets of icon characters, the panel's
  frame, the font and the border's characters, the note table and 6 tunes,
  the menu's colours, places and text, the start, ending, monster, object
  and villain records, the text after a game, and the update table. The
  annotations: the areas outside the game, the variables and records, the
  main entry points, 16 spans, and `nowarn` on 16 instructions whose
  operands only look like addresses.
- **Round trip**: 42240 bytes byte for byte; the snapshot written back is
  the one read (38635 bytes); 0 warnings. Getting there: labels for every
  variable the code names (splitting the variables into fields), sub-labels
  in generated tables (`START_U_CELL`, `HEADING_CHARS`,
  `MENU_CONTROL_COLOURS`), `nowarn`, and no numbers in prose that fall in
  the listing's range.
- **HTML**: `--html` works, with `scripts/nightshade.ref` (the family's
  style sheets and `nightshade.css`), labels in every memory map, each
  sprite's and tile's picture, the font and the icon characters drawn by
  `#FONT` and `#UDGARRAY`, and a provenance page. Looked at in headless
  Edge: the index, a sprite, a tile, the font, the menu, the map, the icons,
  the compass. The six page modules are skipped until written.
- **The cross-match.** `ns_match.py` (scratchpad, from `a8_match.py`)
  compared every routine entry with Knight Lore's, Alien 8's and
  Pentagram's by instruction pattern:
  `game_disassembly/nightshade/matches.txt`. Of 164 entries of five
  instructions or more, 24 match one of the three at 0.80 or better and 40
  at 0.60; 124 match none. What matches: the tune player (`PLAY_TUNE`,
  `PLAY_NOTE`, `PLAY_TUNE_ONCE` 1.00), the menu (0.96) and its flashing and
  toggling (1.00), the pause (0.91), the key reading (`READ_KEYS` 1.00,
  `READ_CONTROLS` 0.86), Pentagram's sound effects (`EFFECT_NOTE`,
  `FIRE_SOUND`, `PAUSE_BEEP` 1.00), the sprite row drawing and turning
  (`SPRITE_ROW` 1.00, `VFLIP_SPRITE_DATA` 0.93), the small helpers. The
  town, its drawing, the movement, collision, the objects' routines and the
  quest are new.

### Decisions

- The disassembly runs from $5B00 to $FFFF, the loader and the system
  variables included, since the game reads two of them and runs one.
- The loader's routine is code (it ran in the simulated load); it is
  followed from its first instruction by the same recursive descent, kept to
  its 43 bytes.
- Labels: the map `TOWN`; buildings `BUILDING<index>` by the first building
  table entry that reaches them (cell type times two, plus one for the
  turned view); box lists `BOXES<type>`; tiles `TILE<n>`, edges `EDGE<n>`;
  sprites `SPRITE<first graphic>`; tunes `TUNE<address>`; placeholders
  `SUB`, `DATA` and so on plus the address. Game text is laid out by the
  generator (the menu, the panel's heading, the text after a game), never
  typed into a committed file.
- The turned-round tour was dropped: every third cell with the town turned
  round added nothing the keyboard sessions' own turning had not.
- The build fails on any warning, after writing everything.
- The game-disassemblies README and `docs/game-examples.md` are not touched
  in this stage (the brief limits it to new Nightshade files).

### What stage 2 should know

- Most routines are new: only the menu, the printer, the tune player, the
  sound effects, the key reading, the pause and the sprite row code are the
  earlier games'. `matches.txt` names the counterpart where there is one;
  short entries matching at 1.00 (`$D593` against Knight Lore's `upd_23`)
  are coincidences of two-instruction routines.
- Update routines are reached only through `UPDATES` ($D599); five smaller
  tables of routines are declared as `w` entries (`MONSTER_HIT_TABLE`,
  `DEPTH_TABLE`, `WALK_TABLE`, `STEP_TABLE`, `MOVE_TABLE`), and code inside
  them that never ran is in the coverage file. `$C554` is a small routine
  that sna2ctl first took for data; it is code (reached from `$D81E`).
- Self-modifying code: the visited-bit instructions at `$BF85`/`$BF87`, the
  column test in `$D3C2`, the masks in `$D425`, the jump and the row step in
  the sprite drawer (`$E423`, `$E42A`).
- Code that never ran (`nightshade-coverage.txt`): the loader (ran in the
  load), a strike on the creature of 136-139 that the session's stage did
  not reach (`$C019`), one outcome's full-records branch (`$C121`), the
  reset (`$C1F9`), a rest in a tune (`$C6A3`, no tune has one), the drawing
  order's action 2 (`$CF88`, no record uses it), the upside-down flip of a
  sprite (`$E366`, `$E0EE`, `$E3D6` -- nothing seen sets the bit).
- Suggested split into five ranges of similar listing length (about 1000-
  1100 instruction lines each):
  1. $BDFE-$C6B8 (1105 lines, 48 routines): the start and the main loop,
     the percentage, the visited cells, the creature of 136-139 and the
     monsters of 112-127 with their strike outcomes, the panel (score,
     heading, compass, villains), the sound effects and footsteps, the
     carried things, the touching tests, the random number, the finds, the
     tune player.
  2. $C6B9-$CFAE (1022, 32): the notes and tunes (generated), the menu, the
     panel's frame and the printer, the start cell, the new life and its
     checks, game over and the ending, the monsters' spawning, the monsters
     of 64-79, the drawing order walk and the draw list.
  3. $CFAF-$D709 (1044, 30): the depth sort, the town's drawing (walls,
     their ends, tiles, the building colours), the projection, the map
     look-up, the dispatcher, the update table (generated), the villains'
     sparkles.
  4. $D70A-$DF96 (1082, 40): the update routines -- bonuses, the objects,
     the villains, the finds, the knight's top and legs, his controls,
     turning, walking and throwing -- and movement.
  5. $DF97-$E5C3 (997, 34): movement against the cell boxes, the lookup
     tables' building, the buffer copies, the key reading, the pause, the
     sprite turning and drawing, the screen address arithmetic.

## 2026-09-28 -- stage 2: every routine described

Five agents in parallel, one address range each (stage 1's suggested
split), working from the listing, the earlier games' annotations and
`matches.txt`, and running routines in SkoolKit's simulator where that
settled a question. Each wrote a control-file fragment (`ns_part_1.ctl` to
`ns_part_5.ctl`) and a notes draft (`ns_notes_1.md` to `ns_notes_5.md`, in
the session's scratchpad). The user was away; the decisions were the
lead's.

- **The ranges.** 1: $5B00-$C6B8 (outside the game, the variables, the
  start and the main loop, the percentage, the creature and the walkers,
  the panel, the sounds, carrying, touching, the tune player). 2:
  $C6B9-$CFAE (the tunes, the menu and the printer, lives, game over and the
  ending, spawning and the wanderers, the drawing order). 3: $CFAF-$D709
  (the depth sort, the town's drawing, the projection, the dispatcher, the
  sparkles). 4: $D70A-$DF96 (the update routines, the knight, movement and
  steering). 5: $DF97-$FFFF (clipping at the boxes, the keys, the sprites,
  the buffers and what lies above the code).
- **The merge.** `ns_merge.py` (scratchpad) replaced each range's entries in
  `scripts/nightshade_annotations.ctl` with its fragment, keeping every
  `; span` and `@ $ADDR nowarn` line in a block before the first entry (a
  nowarn line otherwise rides with whichever entry precedes it and is lost
  when that range is merged -- learned from Alien 8). Then
  `ns_fix_generator.py`: the tunes labelled by what they are for
  (`TUNE_MENU` ... `TUNE_NEW_LIFE`, in `nightshade_data.py`), the start
  records' link moved from `#R$CEBB` (inside an entry) to `#R$CE89`, and the
  build script's start-record constants renamed. After it: 0 warnings,
  42240 bytes byte for byte, the snapshot written back the one read, and no
  placeholder title or label left: 476 entries (272 b, 189 c, 1 g, 1 s, 3 t,
  4 u, 6 w).
- **The code map moved a little**: the finds session now adds 78 addresses
  and the quest 300 (they were 66 and 298); 4705 instruction starts ran, and
  the coverage file lists 10 runs never run, $DC8E new among them.
- **Findings worth the notes** (each now in its topic file): the 100%
  percentage prints three garbage characters (*measured*); every game over
  leaks two bytes of stack and the 157th game crashes (*measured*); the
  split copies over the first monster record (*measured*); only the first
  antibody record can strike (*measured*); the villains' hum reads ROM bytes
  instead of its four tables (*measured*); a rejected monster spawn leaves a
  stray in cell (0,0) (*measured*); half the bonuses placed vanish the next
  turn, yet one is nearly always about (*measured*); the knight never quite
  reaches his top speed and always stops on an eight-unit grid
  (*measured*); the villains never chase; the town is drawn without any
  sorting of walls -- column claims behind the knight, outlines in front;
  the play area is a buffer drawn upside down and copied whole by PUSHes;
  the lives come from an opcode; the monsters take their kind from the
  nearest villain, so each villain's walkers die to one kind of antibody.

### Corrections

What stage 1 said, and what showed it wrong:

- **`$C019`** was listed as "a strike on the creature ... that the session's
  stage did not reach". It is the creature left behind, more than two cells
  from the knight -- not a strike (range 1: run in the simulator with the
  creature five columns away).
- **`$E3D6`** was listed with "the upside-down flip of a sprite" as code
  nothing reaches. It is `MIRROR_SPRITE`, the mirroring entry, used by the
  panel's villains (`DRAW_VILLAINS`) when a villain's sprite is stored
  mirrored; that simply did not happen in the sessions (range 5, agreed by
  range 1). The upside-down flip is $E366-$E399 with `HL_EQUALS_DE_X_A`,
  and is dead.
- **The split.** "A strike on a monster of 112-127 may kill, change or
  split it (`$C0D1`)": there are four outcomes, the fourth turning it into a
  wanderer, and the split does not split -- its search tests IY but reads
  IX, so the struck monster is copied over the first monster record,
  whatever it holds, unless that record is beside the knight and the five
  records after the antibody's are all busy ($C121, the branch no session
  ran; range 1, *measured*).
- **`WALK_TABLE` -> `COAST_TABLE`** ($DC71): its routines run when the
  knight is *not* walking, bringing him to a stop on the grid.
  **`STEP_TABLE` -> `TURN_TO_KNIGHT_TABLE`** ($DD6A): its routines turn a
  chaser towards the knight (range 4).
- **Record +8 and +9 are half-sizes**, centre to edge, not sizes (range 4
  from the clip routines, range 1 from the touch test). +6's count is bits
  0-2 only for the knight; walkers and finds use bits 0-5. +5 in a find is
  its cell type.
- **`START_U` -> `START_U_LOW` / `START_U_CELL`.** The generator labelled
  the low bytes of the start records' U and V `START_U` and `START_V`,
  while the build script used the same names for the cells: one name, two
  bytes. The low bytes are now `START_U_LOW` and `START_V_LOW`, the cells
  `START_U_CELL` and `START_V_CELL`, in the listing and the build script
  alike (range 2).
- **`NMIADD`**: "without the tape's byte no object would ever move" -- the
  jump would run the system variables as code and crash at the first
  update (range 3).
- **FRAMES** sets the turn counter at every new game (frozen, since
  interrupts stay off); it is not "the first random number", and `TURNS`
  does not carry over between games (range 1).
- **`RANDOM`** is stirred after every record's update and before most
  random choices, not "once a turn" (range 1).
- **`$D15D`** was an sna2ctl "unused" block: it is `DRAW_LIST` (range 3).
- **$E49F and $E4CD** were data: the first units of the unrolled sprite
  runs, code no sprite reaches (range 5).
- **`ATTR_SPILL`** is written at the top right-hand corner of the play
  area, not "when a building's colour runs down to the bottom" (range 3,
  *measured*).
- **Drawing-order action 2** is `DRAW_OUTLINE`, a building's outline on
  the ground, not "its wall's ends"; no record uses it (ranges 2 and 3).
- **`UNKNOWN_BBCC`** is `SCORE_ZEROS`, the score's last two digits, never
  written.
- **`ICONS`** holds nine icons, the first the blank one of an empty place,
  not eight.

## 2026-09-28 -- stage 3: the notes

The notes brought to the standard from stage 2's five drafts, each claim
checked against the final listing (`nightshade.skool`) and, where the
drafts disagreed, the code. A topic file per subject (the README lists
them); `overview.md`, `driving.md` and `memory-map.md` rewritten for the
final labels.

- **Settled here** (*read* unless said): a new game's leftover
  `START_FLAGS` are harmless (bits 6-7 rewritten from the facing while he
  appears, bit 0 cleared each update, bit 5 never set on him); the knight's
  position is always even, so the final step of 1 into the grid ($DC8E) is
  never taken (*inferred* from every step being even); cell types 11 and 26
  are on no map cell, so four building definitions are never drawn, and
  type 2 is a single cell, column 28, row 16 (*measured*, counted on the
  map); the coverage file misses two runs that never ran, the heads of the
  unrolled sprite runs (*measured*: neither is in the executed map); a
  villain's destruction scores 250000 as printed.
- **Found wrong elsewhere, reported to the lead** (not fixed here: these
  notes touch only `notes/nightshade/`): the labels `TAKE_LIFE` ($CBDD) and
  `DRAW_STEP_DONE` ($CF8D), stage 1's, were lost in the stage 2 merge
  (range 2's fragment did not carry them), so `LD A,($CBDD)` and
  `LD DE,$CF8D` show bare addresses; `OBJECT_FLIGHT`'s description and its
  comment at $D83B say a villain scores 2500 (it is 250000, as
  `ADD_SCORE`'s description says); the generator's record lines still call
  +8/+9 "size in U/V"; the build script's docstrings still cite `#R$CEBB`
  and call the creature "the ghost"; the coverage report lists only the
  code map's instructions.
- **Stage 3 is checking** (live in a private `zx_server`, or on the
  pages): the 100% garbage, the 156-game crash, and the villains' and
  objects' names.

## 2026-09-28 -- stage 3: the pages, and what they corrected

Six page modules (`nightshade_howitworks`, `_world`, `_graphics`,
`_animations`, `_sounds`, `_reference`) and the notes, each written by its own
agent from the finished listing and checked against the game in the
simulator; the lead wired them into `nightshade.ref` and checked each
correction against the code before applying it.

Corrections to the listing:

- The knight's views were the wrong way round: bit 3 of his graphic (24-29,
  40-45, 30, 46-47) is the view from the front, face showing, not from
  behind -- the graphics page drew his four facings with the game's own code
  ($D9EB, $DA53, $DB89, $DC35, $DCD3, $DCDC).
- A villain scores 250000 as shown ($2500), not 2500 ($D80C, $D83B); the
  dead villain is drawn on the panel in its killer's colour, not blanked.
- `TAKE_LIFE` and `DRAW_STEP_DONE` restored (lost in the merge).
- `ATTR_SPILL` is reached at the top-right of the play area, not the bottom.
- The dying villain: seven or six turns, not eight ($D847).
- `SPAWN_MONSTER`: the stray at 0,0 is harmless only away from the top-left
  corner; and monsters often land inside buildings ($CDE8).
- The sound annotations: "rising" counts are falling pitches; effect 3's
  squeak is before three ordinary notes, not low ones; FIRE_SOUND's count is
  11 less the place, from the bottom.
- The drawing order's action 2 is the outline on the ground ($CF88 and the
  generator), the panel frame's five pieces in their real order ($C83F), the
  start record's labels `START_U_LOW`/`START_U_CELL` (generator and build).

Confirmed live on a private zx_server: the 100% garbage, the 157th game's
crash, and the 128K paging lock. Pokes tested: [`bugs-and-pokes.md`](bugs-and-pokes.md).
