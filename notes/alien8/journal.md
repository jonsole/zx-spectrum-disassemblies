# Journal

What was done, how, and what came of it. Newest last.

## 2026-09-27 -- stage 1: the pipeline

The first of four stages (the pipeline; every routine described; the pages;
the notes), done by one agent with the user away; the decisions below were
its own, and are recorded so they can be revisited. Pentagram's build,
finished the same day, was the model, copied and adapted rather than shared.

- **The tape.** `tapes/Alien 8 (1985)(Ultimate).tap`, the user's original.
  Six blocks: the BASIC loader `Alien8.1` (LINE 1), `Alien8.2` CODE
  16384,6912 and `Alien8.3` CODE 25341,40195. The loader (listed with
  SkoolKit's `tapinfo -b`) sets black border, paper and ink, does `CLEAR VAL
  "25340"`, `LOAD "Alien8.2"SCREEN$`, prints at row 20 to move the cursor,
  `LOAD "Alien8.3"CODE`, and on line 30 `RANDOMIZE USR 25344` -- the brief's
  reading was right. The game block runs from $62FD to $FFFF, the whole top
  of memory, and is entered three bytes in, at $6300: DI, LD SP,$F100, NOP,
  JP $A631. No protection, nothing encrypted.
- **The snapshot.** `tap2sna --start 25344` on the tape's URI stops at $6300
  before the game's first instruction:
  `game_disassembly/alien8/alien8.z80`, in about a second. Taken there
  because the game changes itself as it runs: sprites turned in place (as in
  Knight Lore and Pentagram), the rooms' colour bits copied at every new
  game (`$CAD2`), and the table of places given graphics and positions at
  every new game (`$AF3F`).
- **What is disassembled: $5B00-$FFFF.** The game's variables ($5B00-$5B87)
  and its 56 object records ($5B88-$6287) lie below the block, where the
  loader's CLEAR left the printer buffer, the system variables and the BASIC
  program; the game clears them before use (`START`, $A631). They are in the
  listing so that every variable the code names has a label; the bytes shown
  are the snapshot's (system variables and the loader), and the entries say
  so. Knight Lore's build leaves its equivalent area out; Pentagram's
  variables were inside its block.
- **The leftovers at the top.** Because the block runs to $FFFF it carries
  whatever the mastering machine had there. From $D1EB: a line of text naming
  1984 and A.C.G. (nothing refers to it, *searched*); zeros; stack debris
  (words that look like return addresses into the ROM); the Spectrum ROM's
  capital letters A to U; code that uses the system variables the way the
  Interface 1 ROM does; the Interface 1's error messages, each followed by
  its number; more of the code; zeros up to $FF17; more stack debris; and a
  font's capital letters A to U, of some other program, at $FF58-$FFFF. The
  game's screen buffer is $D200-$E9FF (`$D120` adds $D200), its stack goes
  down from $F100, and its lookup tables fill $F100-$FFFF (`$CFA7`, before
  the menu), so every leftover but the copyright line lies in space the game
  writes. *Measured*: the loaded game run in SkoolKit's pure-Python
  simulator from $6300 through the menu into the first room and a few
  seconds of play, with a memory that records the first access to each
  address of $6288-$62FF and $D1EB-$FFFF: no first access was a read; 10018
  addresses were first written, and 1899 were never touched (the copyright
  line, the bytes below the block, and stack space never reached). The
  claim that the code is Interface 1's rests on the text and on the code's
  use of system variables; the Interface 1 ROM was not compared (*inferred*).
- **The code map by playing.** SkoolKit's C simulator, from $6300, with a
  tracer that holds keys and a Kempston stick (Pentagram's). Sessions (all in
  the build's `sessions()`, recipes in [`driving.md`](driving.md)): each of
  the four control methods and directional control from the menu, with
  rounds that walk, turn, jump, pick up and put down, and pause; every one of
  the 128 rooms in turn, three seconds each, by the game's own restart (the
  room poked into the start records at $CA1D, the player's death started);
  game over; a valve picked up and put down; an extra life touched; the
  four kinds of chamber activated, one revisited, the twenty-fourth (the
  count staged at 23) and the ending, back to the menu; the clock run out;
  the remote-controlled robots driven from each of their buttons and pad;
  and a thing dropping from the ceiling. Each step waits on the game's
  state (`Until`, `Repeat`, and a new `At`, which runs to an address) and the
  build stops, naming what never came, rather than trusting a time. The
  first cut (menu, play and the room tour at one second a room) left 776
  bytes of code unrun; the staged scenes and a longer tour brought it to 117
  bytes in 14 runs. Then recursive descent (`scripts/codemap.py`) from what
  ran and from the 131 words of the update table at $A7EA: 52 instructions
  come only from that. The build takes about 50 seconds, the sessions about
  45 of them.
- **What the staged scenes showed** (*measured*): a valve of a chamber's kind
  anywhere in the chamber's room steers itself towards the socket (graphic
  112-115), and activates the chamber when it sits exactly on it -- the
  valve's graphic goes up by 4, the screen's colours cycle, the room's ink
  becomes white, `CHAMBERS` ($5B40) counts one up in BCD, and 24 sets `WON`
  ($5B23) and ends the game with the arrival text and then the summary. In
  one room (`$1D`) the valve steering itself arrived under the socket; the
  session holds it over the socket to fall. A place given graphic 12 is an
  extra life: touching it gives a life and empties the place. The clock is
  four bytes at `CLOCK` ($5B36), each a digit in bits 4-7 and a count in bits
  0-2; poked to all but zero anywhere in the turn it can wrap round to 9s,
  so the session pokes it at `$AD66`, where the turn's count starts. The
  things that drop from the ceiling (graphic 73) stay put in an
  even-numbered room until something is picked up (`DROP_LATCH`, $5B3B), and
  then drop only on a turn the random number is under 16.
- **The doorways** move the room number by 1 and 16: walking out of the
  start room $4E four ways reached $4F, $5E and $3E (*measured*). The rooms
  are a 16 by 16 grid, as in Knight Lore, and the listing titles each room
  with its row and column.
- **Control files.** sna2ctl's map over $5B00-$FFFF. The level data comes
  from `scripts/alien8_data.py`, which walks each table the way the code
  reads it -- the room directory as `$CCA7` builds a room (the byte count
  running out ends a record, a template-0 header sets the placement nudge,
  template 31 moves to the second page of templates), the templates and
  backgrounds to their zero ends, the sprites end to end -- and stops the
  build if a record does not end where its length says or a table does not
  tile its range. All 128 rooms, 37 templates, 14 backgrounds and 78
  sprites tile exactly. `take_over` drops sna2ctl's lines inside the
  generated ranges and the annotations' declared spans; `check_structure`
  and `check_annotations` as in Pentagram's build.
- **The round trip.** sjasmplus reassembles all 42240 bytes byte for byte,
  with no warnings, and the snapshot written back is the one read, all 34645
  bytes. sna2skool and skool2asm give no warnings; the build fails if they
  do. Getting there took labels for every variable and every table the code
  names, entries for the second halves of two tables of pairs ($C1DA,
  $C235), `nowarn` on the instructions that load constants looking like
  addresses (the drawing nudges, -32, a buffer address), and links to
  entries rather than to the middle of routines.
- **The HTML.** `--html` works: skool2html with `scripts/alien8.ref` (the
  Ultimate family's style sheets and a small `alien8.css`), labels in every
  memory map, every sprite's entry showing its picture (drawn from its bytes
  the way `$D013` draws: set image bits white, mask alone black, neither
  clear) and the font's entry the font, and a provenance page. The six page
  modules are skipped until written. Looked at in headless Edge: the index,
  the memory map, a room, a sprite, the buffer.
- **The cross-match.** A scratch script (`a8_match.py`, from Pentagram's
  `pg_klmatch.py`) compared every Alien 8 routine entry with every Knight Lore
  and every Pentagram routine by instruction pattern, 16-bit numbers and jump
  targets ignored: `game_disassembly/alien8/matches.txt`, not committed. Of
  168 entries of five instructions or more, 56 match a Knight Lore routine at
  0.80 or better (93 at 0.60), 65 a Pentagram routine at 0.80 (87 at 0.60),
  and 89 one or the other at 0.80 (122 at 0.60); of those at 0.60, 45 are
  closer to Knight Lore by more than 0.05, 54 closer to Pentagram, the rest
  level; 46 match neither. What matches: the renderer (`$D013` Pentagram's
  `DRAW_OBJECT` at 1.00, the sprite runs, the address arithmetic, the lookup
  tables, `FIND_SPRITE` 0.85), the depth sort (`$C785` `SORT_AND_DRAW` 1.00),
  the collision tests (0.94-1.00), the player's movement (`HANDLE_JUMP`,
  `MOVE_PLAYER`, `CALC_PLYR_DUV`), the doorway nudges, `READ_KEYS` and the
  pause, the menu and the text printer, the tune player (`PLAY_NOTE` 1.00),
  Knight Lore's sound effects, the room builder (`BUILD_ROOM` 0.90) and the
  arrival (`ADJUST_PLYR_UVZ_FOR_ROOM_SIZE` 1.00). Knight Lore alone: the
  special objects (`find_spec_obj_loop` 0.83 -- Alien 8's places), the
  update routines of its movers, the room-visited flags, the exits by room
  arithmetic, the completion message. Alien 8's own (no match): the valves
  and chambers, the remote-controlled robots, the clock, the summary after a
  game and its scene. A match is a hint for stage 2, not a claim.

### Decisions

- The disassembly runs from $5B00, so the variables and the object records
  are labelled, and to $FFFF, as Knight Lore's and Pentagram's do: the
  buffer and the tables are part of the map, their bytes whatever the
  snapshot held -- here the leftovers, described entry by entry.
- Rooms are labelled `ROOM<number in hex>` (`ROOM4E`), since the numbers are
  a 16 by 16 grid; object templates `OBJECT<table index>` (the second page's
  are `OBJECT33` to `OBJECT39`); backgrounds `BACKGROUND<n>`; sprites
  `SPRITE<first graphic number>`, and the one sprite no graphic number
  reaches (at $88B3, a wedge-shaped block) `SPARE_SPRITEA`. Placeholder
  labels for what is not yet named are `SUB`, `DATA`, `TEXT` and so on
  followed by the address; a variable read but not yet understood is
  `UNKNOWN_<address>` ($5B25, $5B43).
- The table at $76E3 is called the places (`PLACES`), and the graphics
  96-99 valves: a valve is what a chamber's socket takes (*measured*). The
  game's own word for them is on its pages to come; the notes use "valve"
  until then.
- Variables are named after Knight Lore's at the same offset only where the
  Alien 8 code was read to do the same (the header of the annotations says
  so); the rest are named from what the code does with them, or left
  `UNKNOWN_`.
- The staged scenes stage positions and state only -- a valve put in a room
  and held over a socket, a count at 23, the clock at its last tick, the
  player on a button -- and let the game do the rest.
- The build fails on any warning, but only after writing everything, so the
  warnings can be read in place (`alien8-warnings.txt`).
- `game-disassemblies/README.md`'s table of games and `docs/game-examples.md`
  are not touched in this stage (the brief limits it to new Alien 8 files):
  both need an Alien 8 line when the game is finished.

### What stage 2 should know

- The variables are Knight Lore's layout 160 bytes lower, with Alien 8's own
  from $5B36 on (the clock, the drop latch, the summary, the chambers, the
  remote-control orders). `TEMPLATES_AT` ($5B20) is a word whose high byte
  ($5B21) is also the player's Z step during play: two uses of one byte.
- The object record is Knight Lore's; 56 records: legs, top, two for the
  places, 52 for the room.
- Update routines are reached only through `UPDATES` ($A7EA); each has no
  "Used by" line and needs the table named in its heading. Graphic 131 has a
  sprite but no update entry; what draws it is open.
- Routines still to be reached in the simulator are in
  `alien8-coverage.txt`: parts of the remote-controlled robots ($A9C7), the
  socket's sparkle when no valve is in the room ($AE68), a valve of the wrong
  kind on a socket ($AFF1, which the kind test before it looks to make
  unreachable), graphic 44's and 47's handlers, a tune player branch
  ($B507), a pick-up with every slot full ($BEA1), and a few more.
- Suggested split into five ranges of similar listing length (about 1300
  lines each), with what each holds by the cross-match and stage 1's reading:
  1. $A631-$B054: the start and the main loop, the panel's lives and clock,
     the update routines of the valves, the chambers and the remote-control
     robots and their buttons, the dropping things, the summary after a
     game and its scene, the clock, the places (dealt, filled, saved).
  2. $B055-$B94E: more update routines (Knight Lore's movers), the death
     sparkle, the tune player and the sound effects, the any-object
     intersection test, `READ_KEYS`, the rooms seen, game over and the
     arrival screen, and their text lists.
  3. $B94F-$C1D1: the text lists, the menu, the printer, the panel's carried
     things, picking up and putting down, the extra life, the drawing nudges,
     the doorway pillars and nudges, the player's legs.
  4. $C1D2-$CB05: the player's turning, jumping, walking and moving, leaving
     a room, the per-axis collision, the projection, the draw list and the
     depth sort, reading the controls, a new life, the start records and
     rooms, entering a room.
  5. $CB06-$D1EA: the panel and the border, arriving in a room, the room
     builder, memory helpers, the pause, clearing and showing the buffer,
     wiping what moved, the blit, the lookup tables, drawing a sprite, the
     address arithmetic, turning sprites round; and the leftovers above.
  The variables, the object records and the level data's formats are in
  the annotations already; whoever takes range 1 should check them.

## 2026-09-27 -- stage 2: every routine described

Five agents in parallel, one address range each, working from the listing,
Knight Lore's and Pentagram's annotations and `matches.txt`, and running
routines in SkoolKit's simulator where that settled a question; each wrote
a control-file fragment (`a8_part_1.ctl` to `a8_part_5.ctl`, checked with
`scripts/ctl_tools.py`) and a notes draft (`a8_notes_1.md` to
`a8_notes_5.md`, in the session's scratchpad). The user was away; the
decisions were the lead's, and are below.

- **The ranges** (stage 1's suggested split). 1: $5B00-$62FC and
  $A631-$B054 -- the variables, the object records, the main loop, the panel
  and the clock, the remote-controlled robots, the leapers, the mice and the
  slow chaser, the scenes after a game, the summary's counts, the places,
  the valves, the sockets and activating a chamber. 2: $B055-$B94E -- the
  movers and creatures, the sparkles, the tune player and the effects, the
  overlap test, `READ_KEYS`, the end of a game, the rooms seen, the arrival
  screen. 3: $B94F-$C1D1 -- the summary and menu texts, the menu, the
  printer, the panel's carried things, picking up and putting down, the
  extra life, the drawing nudges, the doorway pillars, the legs, turning.
  4: $C1D2-$CB05 -- ending a turn, jumping, walking and moving, leaving a
  room, the collision code, the screen rectangle, the draw list and the
  depth sort, the controls, a new life, the start records, entering a room.
  5: $CB06-$FFFF -- the panel's pieces and the border, arriving in a room,
  the room builder, the helpers and the pause, drawing, the lookup tables,
  and what lies above the code.
- **The merge.** `a8_merge.py` (scratchpad) replaced each range's entries
  in `scripts/alien8_annotations.ctl` with its fragment; the fourteen
  `; span` lines, which a rewritten entry loses, were put back together at
  the head of the annotations (`a8_restore_spans.py`). After it the build
  reported 0 warnings, the round trip held (42240 bytes byte for byte, the
  snapshot written back the one read), and no entry kept a placeholder
  title or label: 622 entries (358 b, 222 c, 34 t, 3 s, 2 u, 2 w, 1 g), all
  described and labelled.
- **The lead's fixes at the merge:**
  - Ranges 1 and 2 had each named their homing thing `CHASER` ($AA89,
    graphics 120-121; $B19C, graphics 76-79). Renamed `SLOW_CHASER` (one
    unit a turn, deadly) and `SPARK_CHASER` (four a turn, harmless, a
    crackle of sparks).
  - The object record's header in the annotations rewritten from all five
    agents' readings (`a8_header_fix.py`): +$0C bit 2 set whenever a move in
    Z is stopped, either way; +$0D bits 0, 2 and 3; +$10's many uses;
    +$12/+$13, +$18-+$1F; +$14-+$17 never used.
  - `UNKNOWN_5B25` became `LIFT_TOP` and `UNKNOWN_5B43` `LEAPING` (ranges 1
    and 2, measured), and the prose using the old names fixed.
  - The comment on `LEGS` in `scripts/build_alien8.py` corrected: graphics
    16-23 are two views of four step frames, the facings from bit 2 of the
    graphic and the mirror flag.
- **Findings worth the notes** (each in its topic file): the turn bug --
  `TURNING_LEGS` loses the controls in the turn's sound, so a walking robot
  stands still three turns at every quarter turn (*measured*); the depth
  sort destroys a valve that shares space with anything (*measured*); the
  draw list is 64 bytes, enough for 56 records (the longest *measured* 51),
  unlike Pentagram's; the lifts share one top per room; conveyors carry by
  lending their step; the rating is Knight Lore's exactly; the summary's
  counts (24 chambers, 132 crew, *measured*); the clock's rolling digits, a
  light year every 7 turns (*measured*); the remote robots' orders
  (*measured* in room $0B); the placement nudge live, where it is dead in
  Pentagram; Knight Lore's `colour_panel`, werewolf sound and copyright
  line left in; the leftover at $D348 the first 1464 bytes of the Interface
  1 ROM by its structure.

### Corrections

What stage 1 said, and what showed it wrong:

- `UNKNOWN_5B25`, `UNKNOWN_5B43`: the lifts' top and "a leaper is in the
  air" (read; measured in rooms $23, $1D, $36 and $97).
- The object record's header: +$0C bit 2 was "standing on something"; it is
  a Z move stopped either way (read at $C54F; a ridden lift relies on it).
- `CLOCK_BOX_COLOURS` ($A7CA) was text: it is attributes.
  `LIGHT_YEARS_TEXT`'s first byte is a colour written at run time.
- `LIVES` "BCD": binary, printed as BCD. `TUNE_HEARD` "once after loading":
  once per menu, cleared after every game. `PANEL_DUE` is set on every
  accepted press. `INPUT` lacked bit 5.
- `$C745` ("unused") is `DRAW_LIST`; `$BD38` is `PANEL_RECORD`; `$B862`
  ("unused") ends the won scene's list; the tunes and scene lists were text
  guesses and are bytes.
- $AB1F (`FACE_BY_STEP_UNUSED`) and $B65F (`TRANSFORM_SOUND`) were data:
  both are unused code.
- "What draws graphic 131": the panel, its chambers icon (measured).
- The leftovers at $D348-$D8FF: not code, messages and more code, but one
  piece of the Interface 1 ROM, offsets 0 to $05B7 (measured by its
  structure; not compared with a ROM image).
- "Not referred to by name ... stage 2 to rule out": ruled out, and each
  byte matched to the Knight Lore variable it was.

## 2026-09-27 -- stage 3: the notes

The notes brought up to the standard from stage 2's five drafts: a topic
file per question (23 of them), this journal's stage 2 entry, the memory map
rebuilt from the drafts' variable tables, an overview, the README's index,
and `driving.md` extended with the drafts' simulator recipes and a "Live
driving" section for the pokes agent. The page modules and the live test of
the pokes are being done in parallel by other agents. Labels were checked
against the current `alien8.skool`.

Worked out while writing, from the code:

- A game with three extra lives -- about one in four -- deals exactly six
  valves of one kind, the number that kind's sockets need: the extra lives
  fall sixteen places apart and the kinds repeat every four, so all of them
  replace the same kind. A valve of that kind lost to the depth sort would
  leave the game unwinnable. *Read*; not staged
  ([`valves-and-sockets.md`](valves-and-sockets.md)).
- Ten lives cannot happen (at most 7 on the panel), so `LIVES`' binary count
  printed as BCD never shows wrong.
- Every turn's `READ_LETTER_KEYS` writes $7E to port $7EFD, so on a 128K in
  128 mode the game should page its code out in its first turn (*inferred*,
  as Pentagram's was before it was watched).

### Corrections

- Where two drafts disagreed, the code decided: who sets "landed on" (bit
  3 of +$0D) -- range 2's "the robot and the movable blocks" is right, range
  4's "the robot's legs" too narrow (the test is bit 2 of +$07 and graphics
  16-47, which the templates give the pushable and bobbing blocks and the
  lift); `PLAYER_LEGS`' order has the pick-up before the turn (range 3;
  range 4 left it out); the Z step handed on in the Z test is read at $C57B,
  not inferred from Pentagram (range 4 over range 1); `MOVE_PLAYER`'s
  hold-still for the scene after a game never runs (range 4 had it live).
- Stage 1's `driving.md` had the simulator with interrupts on; `Machine`
  starts it with `iff` 0, and the game never enables them.
- For the lead, not changed here (the annotations are not the notes'):
  `HANDLE_PAUSE`'s description names only the SPACE half-row, though $7E
  reads CAPS SHIFT's too; the comment at $C577 says only the robot sets
  "landed on".

## 2026-09-28 -- stage 3 integrated

- The six page modules (world, graphics, how-it-works, animations, sounds, reference) wired in; the build runs from the tape to the whole site. The build now counts its structure pass's warnings too (Pentagram's as well), which found the ratings table read as words from its first byte; it is a data block with word lines now.
- Corrections from the page agents, each checked: the $B5D4 fragment and the arrival tune are Knight Lore's (compared against its snapshot); `MATERIALISE_SOUND` rises, not falls; the collapsing block shows 45, 65, gone; `FRAGILE` things in $72 are 28 in the record; the pause's keys include CAPS SHIFT; the landed-on bit covers every mover of graphics 16-47 with flags bit 2; the deal gives 9/9/9/7 or 9/9/9/6, so one game in four can be left unwinnable by one lost valve.
