# Journal

What was done, how, and what came of it. Newest last.

## 2026-09-27 -- stage 1: the pipeline

The first of four stages (the pipeline; every routine described; the pages;
the notes). Done by one agent, with the user away; the decisions below were
its own, and are recorded so they can be revisited.

- **The tape.** `tapes/Pentagram.tzx`, the user's original. Its BASIC is one
  line: CLEAR 24064, `LOAD ""SCREEN$`, `LOAD ""CODE 24064`, `PRINT USR
  24064`. The loading screen's header says CODE 24576,6912, but `LOAD
  ""SCREEN$` puts 6912 bytes at 16384 whatever the header says (tap2sna's
  simulated load confirms: "16384,6912"). `scripts/build_pentagram.py` runs
  `tap2sna --start 24064` on the tape's URI, which stops at $5E00 before the
  game's first instruction: `game_disassembly/pentagram/pentagram.z80`, in
  about a second. $5E00 is DI, LD SP,$5E00, JP $AF87.
- **Why the snapshot has to be taken there.** The game turns sprites round
  in place -- `FIND_SPRITE` ($B2EE) toggles bit 7 (rows reversed, upside
  down) and bit 6 (mirrored, through the table at $F100) in a sprite's width
  byte and rewrites its bytes when an object's flags disagree with them. On
  the tape every sprite's flags are clear.
- **The code map by playing.** SkoolKit's C simulator, from $5E00, with a
  tracer that holds keys and a Kempston stick. Sessions (all in the build's
  `sessions()`): each of the four control methods from the menu, with play
  rounds that walk, turn both ways, jump, fire, pick up and put down, and
  pause; every one of the 139 rooms in turn, by the game's own restart
  (the room poked into the player template, then the player killed); game
  over; things falling from the sky in room 30; the whole quest and the
  ending, staged; and the joystick's directional mode, which no menu choice
  selects (bit 3 of `CONTROL`, poked). Each step waits on the game's state
  (`Until`, `Repeat`) and the build stops, naming what never came, rather
  than trusting a time. The first cut, without the quest, left 836 bytes of
  code unrun; with it, 196. Then recursive descent (`scripts/codemap.py`)
  from what ran and from the 172 words of the update-routine table at $AE2F
  (a jump table is a list of edges); 96 instructions come only from that.
  The build takes about 30 seconds, the sessions about 25 of them.
- **The quest, run in the simulator.** Worked out by reading the code and
  then running it, room by room (*measured*): in room 71 (a well with no
  monsters, ringed by still hazards) the player, placed inside the ring,
  fires; after enough bolts touch the well it puts out the bucket
  (`BUCKET_OUT` $A70E goes to 1, and a record with graphic 90 appears). Each
  press of the pick-up key passes what he carries one place along the four
  slots at $A722 (the panel's items shuffle); from the last slot, $A72E, it
  is put down. Put down in room 122, the bucket rose and flew to the quest
  item there, the quest-item tune played, the item's graphic went from 112
  to 116, `QUEST_DONE` went to 1 and a life was added. The fourth item done
  sets `PENTAGRAM_ON` ($A70F). With the five collectables' quest records
  moved into room 82 near their places, they flew to them, `PLACED`
  reached 5, and the game ran the win and then the game-over screen with
  the percentage (36 in the staged run) and went back to the menu.
- **Control files.** sna2ctl's map over $5E00-$FFFF. The level data comes
  from `scripts/pentagram_data.py`, which walks each table the way the code
  reads it and stops the build if a record does not end where its length
  says or a table does not tile its range; the build drops whatever sna2ctl
  said inside those ranges (`take_over`) and the annotations' declared spans.
  `check_structure` checks the generated ranges and spans do not overlap and
  every generated block's sub-blocks run on from one another;
  `check_annotations` stops on an instruction comment that splits an
  instruction. The annotations are layered last.
- **The round trip.** sjasmplus reassembles all 41472 bytes byte for byte,
  with no warnings; the build then writes the snapshot back from the
  reassembled bytes, with the header of the one it read, and it is that file
  again, all 31805 bytes. sna2skool and skool2asm give no warnings; the build
  fails if they do.
- **The HTML.** `--html`: skool2html with `scripts/pentagram.ref` (the
  Ultimate family's style sheets and a small `pentagram.css`), labels in
  every memory map, every sprite's entry showing its picture (drawn by the
  build from its bytes the way the drawing code reads them: set image bits
  ink, mask alone black, neither clear) and the font's entry the font. Page
  modules (`PAGE_MODULES`) are skipped until written.
- **Knight Lore cross-match.** A scratch script compared every Pentagram
  routine entry with every Knight Lore routine by instruction pattern, 16-bit
  numbers and jump targets ignored
  (`game_disassembly/pentagram/kl_matches.txt`, not committed). Of 140
  entries of five instructions or more, 37 match a Knight Lore routine at
  0.80 or better and 62 at 0.60 or better: the screen and buffer address
  arithmetic, the sprite row drawing, the intersection tests, the menu's
  text and flashing, the pick-up test, the tune player and more. Hints for
  stage 2 only.

### Decisions

- The disassembly runs to $FFFF, as Knight Lore's does: the buffer and the
  tables are part of the map, their bytes whatever the machine held.
- Every room record is its own entry, labelled `ROOM<number>`, the first also
  `ROOMS`; scenery templates `SCENERY<n>`, object templates `OBJECT<n>`,
  sprites `SPRITE<first graphic number>`, sprites no graphic reaches
  `SPARE_SPRITEA` to `C`. Placeholder labels for what is not yet named are
  `SUB`, `DATA`, `TEXT` and so on followed by the address, with no underscore
  before it (skool2asm's own `NAME_0` labels could otherwise collide); a
  variable read but not yet understood is `UNKNOWN_<address>`.
- The quest sessions stage positions only -- the player beside the well and
  the bucket, the collectables already in room 82 -- and let the game do the
  rest. Driving there by walking would take the simulator a long route
  through rooms full of things that kill.
- The build fails on any warning, but only after writing everything, so the
  warnings can be read in place (`pentagram-warnings.txt`).

### Corrections to what was known

The remake's notes (the emulator repo's memory and
`examples/filmation/pentagram/driving.md`) were the starting hypotheses.
Checked against the code:

- The loading screen does not load to $6000: its header says so, but the
  loader reads it as SCREEN$.
- "$6C54-$6CE4 unaccounted": scenery templates 20 and 21 start at $6C53 and
  $6C9C; the scenery templates run without a gap from $69AD to $6CE4.
- "$84AD-$8546 is something else": $84AD is a sprite, the one graphics 16,
  17 and 89 draw; after it, $853F-$8546 is eight bytes that are no sprite
  and nothing reaches, and $8547 and $8A17 are sprites no graphic number
  reaches.
- "$A709-$ADFF free": the game's variables ($A709-$A76E) and the 54 object
  records ($A76F-$AE2E), all zero on the tape; the update-routine table
  follows at $AE2F, and the code starts at $AF87.
- "Mirroring toggles bit 7 of the sprite's width byte": bit 7 is the rows
  reversed (upside down), bit 6 the mirror, as in Knight Lore (`FIND_SPRITE`,
  $B2EE).
- "All 139 records consume their length exactly": they do, but in two rooms
  (13 and 108) the last object group's header asks for more copies than the
  bytes left, and the builder stops when the count runs out, partway through
  the group.
- The start rooms (51, 92, 100, 12 at $C2E8), the persistent quest records
  ($D312 copied to $D432, bucket at $D542), the drop timer ($A73D) and the
  pause ($B4E0) are as the notes said.

## 2026-09-27 -- stage 2: every routine described

Five agents in parallel, one address range each, working from the listing,
Knight Lore's annotations and `kl_matches.txt`, and running routines in
SkoolKit's simulator where that settled a question; each wrote a
control-file fragment (checked with `scripts/ctl_tools.py`) and a notes
draft. The user was away; decisions were the lead's, and are below.

- **The ranges.** 1: $A709-$B3D2 -- the variables, the object records, the
  main loop, the quest things entering and leaving rooms, the projection and
  the sprite turning. 2: $B3D3-$BBD7 -- drawing a sprite, the depth sort, the
  collision code, the redraw marking, the panel's carried things, printing,
  the score, the pause. 3: $BBD8-$C4C7 -- the menu and the text printer, the
  border and the panel, the controls, picking up and putting down, firing,
  bolts, puffs and scoring, lives and the start, the end screens. 4:
  $C4C8-$CCE8 -- the player's turning, walking and jumping, the drawing
  offsets, the arches and leaving a room, building a room and arriving, the
  percentage, the things from the sky and the homers. 5: $CCE9-$D88E -- the
  movers, the quest (well, bucket, items, pentagram, collectables) and its
  tables, and the sound.
- **The merge.** `pg_merge.py` (scratchpad) replaced each range's entries in
  `scripts/pentagram_annotations.ctl` with its fragment. After it, the build
  reported 0 warnings, the round trip held, and no entry kept a placeholder
  title or label: 592 entries, all described and labelled.
- **The lead's fixes at the merge:**
  - Two agents had each named a lone RET `STRAY_RET` ($C4A2 in range 3,
    $C74A in range 4); they became `STRAY_RET_LEGS` and `STRAY_RET_OFFSETS`.
  - $A734: range 1 proposed `FRAME_DRAWN`, range 3 `SCREEN_SHOWN`;
    `FRAME_DRAWN` was taken, and range 3's prose using `UNKNOWN_A734` fixed.
  - `SLOWDOWN` renamed `DRAW_WORK` everywhere (range 2 still used the old
    name).
  - `ROOM_EXTENT` and `ROOM_SIZES`: "the room's extent in U, V and Z" became
    the U half-size, the V half-size (about the room's middle at 128) and the
    floor's height, 128 in all three sizes -- ranges 1, 2 and 4 agreed.
  - The object record's header in the annotations gathered every field the
    five found (+$07 bits 0-3 and 5, +$0C, +$0D bit 0, +$0E/+$0F, +$10 bit 0,
    +$14-+$16, +$17, and +$08 as a doorway's destination for scenery).
  - The `; span` lines the merge had dropped (a span inside an entry is lost
    when the entry is rewritten) were put back together at the head of the
    annotations: $C3EF,16, $C3FF,64, $C8F7,16, the quest records at $D432,
    the note table and the six tunes.
- **Findings worth the notes** (each in its topic file): the drop timer's
  bug, 80 or 8 turns (*measured*); 56 per cent for a sum of 0 (*measured*);
  the doorways as a table of bytes; the conveyors, the lift and the "stood
  on" mark in the collision code (*measured* in staged scenes); homers do not
  kill; the draw list still 48 bytes for 54 records; the stray OUT and the
  128K; a trail of Knight Lore's cut features with their code left in.

### Corrections

What earlier stages, or the remake's notes, said, and what showed it wrong:

- `SLOWDOWN` "the main loop pauses 6 minus this many times": it counts work
  done; the wait is six less it (read). Renamed `DRAW_WORK`.
- `ROOM_EXTENT` "the room's extents": half-sizes and the floor (read, three
  agents).
- `PRINT_ATTR` "the attribute the print routine colours with": `PRINT_CHAR`
  never reads it; the text printer does (read).
- `ROOM_ATTR` linked $C953 and `SAVED_SP` $B3E7, neither an entry start:
  now $C92C and $B3D3.
- The object record's +$08 is not the room for scenery (read; measured in
  room 100).
- `CHOOSE_START` copies 16 bytes, not a record; `PLAYER_START`'s room byte is
  never used; `PLAYER_TEMPLATE` is rewritten at every doorway (read; the
  last measured).
- `RESET_DROP_TIMER` "by the quest items still to do": it tests the first
  quest record eighteen times (read, measured). Stage 1 had counted the drop
  timer among what the remake's notes had right; its address was, its
  behaviour ("starts 0 -> 255", "(2 + items left) x 4") was not.
- `STEP_SOUND` "a count $D635 keeps for a sound": it counts his steps.
- The remake's "$CE31 hopper (86)": 86 goes to $CE9A, deadly, then $CE31;
  $CE31 is 85's, and no room has 85. "$CDBB lift?": a lift (measured).
- Blocks sna2ctl left as data that are code: $CCFB (`BOUNCE_Z`), $D56C
  (`BLIP_BY_TURN`), $C74A and $C750 now code; $CA7C, $C28B, $BC7A and $D665
  unreached code kept as data with descriptions (declared as code they split
  an instruction or make skool2asm warn). `CARRIED_COLOURS` ($BAC2) was taken
  for text.
- Stage 1's memory map listed $A70B, $A710, $A719, $A71B, $A734, $A735 and
  $A76E as not understood: all are now named or shown unused.
- Stage 1's entry-point label `NEXT_PIECE` ($C9AB) was not carried by range
  4's fragment and is gone from the listing; harmless (the jump target is
  named automatically), noted in case it is wanted back.
- Where two drafts disagreed, the code decided: the stray OUT pages RAM 7
  ($7F, keyboard) or RAM 6 ($7E, joysticks and the pause) -- both drafts were
  half right; graphic 91 throws pushes away (not "pushed by $CD75"); the
  sixth menu line bit 3 flashes is the start line.

## 2026-09-27 -- stage 3: the notes and the pages

The notes were written up to the standard from stage 2's five drafts: a
topic file per question, this journal, the memory map rebuilt from the
drafts' variable tables, an overview and an index. The page modules and the
live test of the pokes are being done in parallel by other agents.

From the world page's module (reported by the lead, who checked the counts):
290 doorways, every one answered by one back, all walked through at build
time and arriving where they say (two floor-level ones need a jump); every
doorway among its room's first four scenery entries, settling what
`FIND_ENTRY_ARCH` assumes; a layout of 19 by 18 with three overlapping
groups; three wells (29, 71, 123), not one; 92 rooms with something deadly.
Now in [`world.md`](world.md) and [`doorways-and-rooms.md`](doorways-and-rooms.md).

### Corrections

- "288 of 289 doorways reciprocated" (the remake's survey, and stage 2's
  generator): both took a destination of 0 for "no doorway" and so missed room
  147's south doorway, which leads to room 0. Tested by template, all 290 are
  answered; the lead fixed the generator.
- The notes had "the well" in room 71: there are three.

## 2026-09-27 -- stage 3 integrated, and published

- The six page modules (world, graphics, how-it-works, animations, sounds, reference) wired in through `PAGE_MODULES` and the index; the build runs from the tape to the whole site in about a minute, byte-for-byte, 0 warnings.
- Corrections the page agents found, each checked and applied: the generator treated destination 0 as "no doorway" (room 147's south doorway leads to room 0), so it now tests the template -- 290 of 290 doorways reciprocated; room titles gave half-sizes as sizes; object +$06 is the whole height, not a half-size; the bobbing head rises one a turn from the first; `CLICK`'s wave timings made exact per caller; the draw list's overflow and the 128K crash, both now watched live, written into `DRAW_LIST` and `READ_KEYS`; the well's 7 shots against 32; the candidate chain's longest real length, 9; `PLAYER_TEMPLATE` keeping the exit marker.
- Found on the way, outside the game: loading a 128K `.z80` on a zx_server whose paging is locked keeps the lock (an emulator bug, recorded for the emulator side).
