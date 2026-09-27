# Journal

What was done, how, and what came of it. Newest last. The entries before
2026-09-27 are reconstructed from the commits (in this repository and, before
2026-09-01, in the emulator repository, which carried the scripts then), the
build script's comments and `docs/game-examples.md`; these notes did not
exist yet.

## 2026-08-28 -- the first build (emulator repo f909273)

- `scripts/build_aticatac.py` arrived with the emulator's tape work. It loads
  the `.tap` with `tap2sna --start $6000`, so the tape's own BASIC loader and
  RRD decryptor run in the simulator; the FRAMES check and the poked
  `JP (HL)` were worked out and written into its docstring.
- The code map came from *playing* the game in the simulator -- random key
  mashing through the menu and around the castle, once per character and
  control method -- recording every address executed; unreached bytes stay
  data. The `.asm` reassembles with sjasmplus to the same 30208 bytes, and the
  build fails otherwise.
- The first annotations were checked against a running emulator by breaking on
  routines (the annotations' "watched live" remarks date from here): the
  record layout, the handler table, the key map, the score and clock.

## 2026-08-30 -- every byte, and the mistakes on the way (d8eaca1 and after)

- **100%** (d8eaca1): 30208 of 30208 bytes, 631 named entries. The big tables
  generated from the snapshot: 194 sprite graphics, 150 room lists, 20 outline
  tables. Extents measured by logging the drawing code's reads. Found: the
  template at $600D is the whole runtime area; doors are sixteen bytes, two
  halves; shapes $06 and $07 unused; the CONGRATULATIONT typo. A span bug
  ((start, length) for (start, end)) had silently cost 7% of the coverage.
- **`check_structure`** (e53ca8b): the round trip is blind to structure, so the
  build now fails on overlapping or short blocks. It found sprites $54 and $58
  sharing four bytes.
- **151, not 149** (542914c): `ROOM_TABLE` has 151 entries; the last is the
  trapdoor fall's shape, which had been written up as unused artwork.
- **Sprites from the game's bytes** (636a0a8), after comparing with
  pobtastic's disassembly: `#UDGARRAY` pictures, the rows bottom-up, and the
  furniture ($A2 upwards) in a format of its own with a width -- so there were
  no "556 bytes of unreferenced artwork", only furniture read in the wrong
  format; four furniture names corrected, thirty taken from pobtastic with
  credit.
- **Animations, colours, the graphics page** (ac85204, 1785cb3, 7cb3a7f,
  b347ce4, ee682cb, d1fc21c): walks by heading; the three sprite tables end to
  end; the "title screen font" was the status scroll with its dimensions
  transposed; the real title screen is a screen$ block on the tape; colours
  from the colour tables and the template.
- **Sounds page**: each effect recorded from its routine on a fresh machine
  (an earlier shared-machine capture had turned an 8 ms rasp into "a second of
  sweep").

## 2026-09-01 -- standing alone (9e0c177)

- The scripts moved into this repository (the emulator repo's f292734 removed
  its copies); the snapshot writer was vendored.

## 2026-09-24 -- published, the map, the rooms, the labels

- Published beside The Hobbit (5f38cf4); page styling (8ce8d8b, 592de8e,
  57d283b).
- **The map** (bf1b4f5): floors worked out from the doors -- five floors, six
  doors that fit none.
- **Every room drawn** (c676833) by the game itself, with its contents, from
  a game started in the simulator.
- **Room lists decoded** (588ce3d): each entry as the label of the record it
  names; 205 doors and 69 furniture pairs.
- **Every address a label** (139a150): 73 equates for the variables and
  runtime records; four routines renamed for what they do -- `PLACE_KEYS`,
  `TRAPDOOR_FALL`, `ACG_DOOR`, `SCAN_COLLECTABLES`.

## 2026-09-25 and 2026-09-26 -- changes shared by all the games

- Callers listed on every entry (75eefc4), names in the routines list
  (6ea1ac6), a label column in every memory map (c894718), new fonts
  (869d274); Knight Lore took Atic Atac's colours (a23bde9).

## 2026-09-27 -- these notes

- **Written** from the listing, read afresh routine by routine, the build and
  the ref; claims checked against the code, and where the code left a doubt,
  measured in SkoolKit's simulator with a scratch harness that starts a game
  from the build's snapshot, stops at `FRAME_TICK` or `MAIN_LOOP`, holds keys
  and stages records (`aticatac_sim.py` and `aticatac_t*.py` in the session
  scratchpad). No emulator was used.
- **New findings** (each in its topic file):
  - `POPULATE_ROOM` is the player's collision test against doorway and table
    boxes, run twice a frame; +$05 bit 3 (shut) and bit 2 (solid) are read
    only there.
  - The characters differ in coasting -- wizard 0, knight 5, serf 16 pixels
    (measured) -- through the decay value each passes; the HL each passes is
    discarded.
  - Touching a small creature destroys it for 155 points; dying or rising
    destroys every small creature in the room, with the points (measured).
  - A life force of exactly zero wraps to 255 on the next drain (measured).
  - Eaten food regrows (`ADVANCE_CURSOR`, measured); `CHECK_KEY_HELD` is the
    pause (measured); SYMBOL SHIFT is the pick-up key and the inventory is a
    queue (measured); the drop key is a record at $EE58 (measured).
  - `ROTATING_INDEX` hides the A.C.G. pieces; the A.C.G. door is in room $00
    and wants the pieces newest-first $8C, $8D, $8E (measured both ways).
  - Interrupts are off on the title screen, so the first game after loading
    has a fixed layout (measured: rooms listed in `loading.md`).
  - About half the plain doors become timed doors at the start of a game
    (`SCAN_DOORS`, from ROM bytes), sharing one countdown; trapdoors open and
    close by themselves.
  - Furniture drawing modes 2, 3, 6, 7 transpose: eight symmetries, not four
    orientations twice.
  - `CLIP_ROWS` interleaves the erase of the old position with the draw of
    the new; nothing is clipped.
  - Locked doors become plain doors once walked through; the key is kept.
  - Dracula teleports between rooms of shapes $00-$02 while unseen; the
    humpback eats the eight purposeless collectables; big monsters flee a
    rising player; weapons cannot hurt them.
  - The end-of-game third figure is a percentage ("$" draws %).
  - A pass takes about 1.7 frames in room $00; its costs (measured).
- **Corrections** reported to the lead (not applied here): about thirty, each
  under "Disassembly corrections" in its topic note -- `POPULATE_ROOM`,
  `ROTATING_INDEX`, `ADVANCE_CURSOR`/`EAT_FOOD`, `CHECK_KEY_HELD`,
  `READ_FIRE_ROW`, `SCAN_DOORS`, `FLASH_AND_RASP`, `DRIFT_OFFSETS`/
  `MODE_TO_INDEX`, `MONSTER_CAUGHT_PLAYER`/`DRAW_MONSTER`, `DYING`'s speed,
  `GAME_OVER`'s caller and length, `LOSE_LIFE`'s branch, `SPIN_SWORD`,
  `SOUND_SPELL`/`SOUND_SPELL_2`/`SOUND_FROM_HEADING`, `SWEEP_PITCHES`,
  `SCALE_SIGNED`, `MULTIPLY_2`, `MULTIPLY`, `RANDOM_CHANCE`, `RANDOM_VERTICAL`,
  `TRY_FIRE*`'s characters, `DOOR_LOCKED_A/B`, `TIME_LABEL`, the food kinds,
  the doors "eight bytes from $EEE0", the eight drawing modes, the ref's
  Data page on artwork, the build's heading-order comment.
- **Looked for, not found**: there is no `docs/aticatac-*.md`. (The tape is
  not in `tapes/`; it was found later the same day in the user's Downloads.)

## 2026-09-27, later -- the corrections applied

- **Applied** to `scripts/aticatac_annotations.ctl`, `scripts/aticatac.ref`
  and the page text in `scripts/build_aticatac.py`, each re-checked against the
  code first: every correction in the topic notes' "Disassembly corrections".
  One was softened rather than applied as written: `PLAYER_AT_DOOR`'s "from
  behind" claim is now simply a description of the box. One ref sentence was
  left alone: the Data page's "fourteen graphics below $AD2E", not re-checked.
- **Renamed** (tables in each note): `POPULATE_ROOM` -> `TEST_ROOM_BOXES`,
  `STEP_AND_TEST`/`_2` -> `TEST_STEP_IN_ROOM`/`TEST_STEP_BOXES`,
  `ADVANCE_CURSOR` -> `REGROW_FOOD`, `CHECK_KEY_HELD` -> `PAUSE`,
  `READ_FIRE_ROW` -> `READ_PICKUP_KEY`, `DRAW_MONSTER` -> `KILL_MONSTER`,
  `TRY_FIRE_THIRD`/`_ALT`/`TRY_FIRE` -> `KNIGHT_FIRE`/`WIZARD_FIRE`/`SERF_FIRE`,
  `SPIN_SWORD` -> `AIM_SWORD`, `MULTIPLY_2` -> `DIVIDE_SLOPE`, `SOUND_SPELL`/`_2`
  -> `SOUND_WEAPON_GONE`/`SOUND_BOUNCE`, `SOUND_FROM_HEADING` ->
  `SOUND_RISE_SINK`, `ROTATING_INDEX` -> `PLACE_ACG_KEY`, `FLASH_AND_RASP` ->
  `TRAPDOOR_CLOSED`, `DRIFT_OFFSETS`/`MODE_TO_INDEX` ->
  `ARRIVAL_HEADINGS`/`SET_ARRIVAL_HEADING`, `TIME_LABEL` -> `PERCENT_LABEL`,
  `SCAN_DOORS` -> `CHOOSE_TIMED_DOORS`, the timed doors, the erase-and-draw
  loop, the random helpers, the movers, and -- so that no code label ends in
  an underscore and a digit -- the sixteen furniture drawers (now named for
  the rotation each gives, worked out from the loops), the nine attribute
  fillers (named for the direction of movement), `LOSE_FOOD_8/16/32`,
  `SOUND_64/65`, `SHIFT_CHAIN_2`, `PLOT_XOR_2`. New equates `WEAPON_LIFE`
  ($EAA7); `CARRYING`, `CURSOR`, `FIRE_BLOCKED`, `CLIP_COUNT`/`CLIP_LIMIT`,
  `MOVE_ROOM` renamed. Generated data labels ending in hex digits
  (`ROOM_LIST_00`, `GFX_54`, `SHAPE_VERTI_00` ...) were left as the build makes
  them.
- **Byte dumps** of the game removed from four annotations while there
  (`MONSTER_TEMPLATE`, `PLAYER_TEMPLATE`, `LOSE_LIFE`, `GRAVESTONE`).
- **The tape** was found at `C:/Users/jonso/Downloads/Atic Atac (1983)(Ultimate).tap`;
  `tapinfo` confirmed the loader's block order (the FRAMES block is last).
- **Rebuilt** with `--html`: 30208 bytes verified byte for byte; 3 SkoolKit
  warnings against 11 before the edits, all 3 old (a graphic's shared bytes and
  two addresses in `DRAW_FOOD`'s note). The Sounds page now names the
  effects by what plays them; pages checked in headless Edge.

## 2026-09-27, evening -- bugs, pokes and facts, checked live

- **The reference module** `scripts/aticatac_reference.py` (new; the build
  imports it through `PAGE_MODULES`): eight bugs, ten pokes and eleven facts
  for SkoolKit's Bugs, Pokes and Facts pages, beside the ref's own
  CONGRATULATIONT, its poke and seven facts. Every poke was tried live
  against the same trial without it; every bug and fact says whether it was
  read or watched. The one picture, the devil's and Frankenstein's caves on
  arrival, is drawn by the game's own code in the simulator at build time.
- **Driven live for the first time**, on a private zx_server
  ([`driving.md`](driving.md), "Driven live"): the simulator's recipes held,
  and the first game's rooms came out the same.
- **New bugs, watched:** the first game is fixed (FRAMES frozen at $256F on
  the title screen for 300 turns); fewer castles than it seems -- the green
  and red keys, the mummy and the A.C.G. pieces share FRAMES AND 7, and the
  cyan key, chosen from FRAMES' middle byte, stays in $91 unless a game over
  caused in the main loop leaves interrupts on through the delay and the
  title ([`loading.md`](loading.md), [`main-loop.md`](main-loop.md)); the
  zero wrap, now caught with a watchpoint; one death costing two lives to a
  mushroom; the first food record never regrowing (fix: POKE 39260,80);
  two gravestones cancelling out ([`food-and-health.md`](food-and-health.md));
  the devil and Frankenstein standing in their caves' rock, because the
  hunters retreat to 52 pixels while the player rises or sinks and a cave's
  floor stops at 40; Dracula heading for $8A, $46 off-screen
  ([`monsters.md`](monsters.md)).
- **Pokes, tested:** infinite life force (the four below together), no
  hunger, harmless creatures, no creatures, the big five harmless, harmless
  mushrooms, infinite lives, every locked door open, the A.C.G. door always
  open, every secret passage for every character. The ref's own POKE
  38687,211 was tried too: the end screen read CONGRATULATIONS.
- **Corrected:** the comment at $8C4F and main-loop.md (GAME_OVER's delay
  has interrupts off only after a hunger death); loading.md ("later games
  differ" -- mostly they do not); monsters.md's "slightly smaller walk
  rectangle" (52 or 56 pixels: 12 more than a cave's floor); the positions at
  the first frame of play recorded in monsters.md and records.md (hunters at
  $26, $36; Dracula already in $68); driving.md's win recipe (x $9C, y $7B
  works only by being dropped into the door; walking in needs y $5C-$73);
  a blank line before the ref poke's POKE; three sprite names in the
  annotations -- the sword does not spin, the collectables kill only
  Frankenstein's monster, and $94-$97 (a hooded figure in a robe with a cross)
  had no name, so the Sprites page used its mover's.
- **Answered:** Dracula's lost target is a slip (the mummy loads DE from the
  same bytes; Dracula does not); walking through a locked door and a
  character's secret passage, now watched; the humpback's loose limits never
  bite (read).
- **Open:** room $43's picture on the Map shows no devil, though he is there
  live and in a simulated arrival; `render_rooms`' own run was repeated and
  left his record in $43 at $25, $35. Not found why ([`monsters.md`](monsters.md)).
- **Renamed (the lead):** the diagonal drawers, after the how-it-works build matched modes 3 and 6 pixel for pixel: mode 3 is `DRAW_FLIP_ANTIDIAGONAL` / `COLOURS_FLIP_ANTIDIAGONAL` / `DRAW_FLIP_ANTIDIAGONAL_OP` (were `DRAW_TRANSPOSED`...), mode 6 `DRAW_FLIP_DIAGONAL` / `COLOURS_FLIP_DIAGONAL` / `DRAW_FLIP_DIAGONAL_OP` (were `DRAW_ANTI_TRANSPOSED`...) -- the old names had the diagonals the other way round. The same build found no spawn grace in room $00, trapdoors closing far oftener than once in 256 passes, a rise of 77 frames not 72, and a colour block a cell short for an 18-row sprite; each is in its topic note.
