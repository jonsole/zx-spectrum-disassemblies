# Lives and starting

**Question this answers:** where a game and a life start, how lives and
hits are counted, and what happens between one life and the next.

**Short answer:** a new game starts the knight in a random standable cell,
facing +U; a life after a death starts in the cell he died in, facing the
way he was. Six lives, one taken as each life starts (the first included),
so the panel shows five at the start; three hits a life. `NEW_LIFE` also
holds the check against the infinite-lives poke.

## How it works

- **The start cell** (`RANDOM_START_CELL`, $CB7B, at every new game): the
  stirred random number, 10 bits, is a cell; solid cells (types 1, 2) are
  skipped forwards, wrapping at the map's end. Column and row go into the
  start records, `START_U_CELL` ($CC38) and `START_V_CELL` ($CC3A); the low
  bytes `START_U_LOW` and `START_V_LOW` hold 128, the cell's middle, and
  nothing writes them. Because of the skip, a cell right after a run of
  solid cells in map order is chosen for every cell of that run as well:
  the start is not uniform (*read*). The time spent on the menu stirs the
  random number (`MENU_LOOP` counts turns), which is what varies it.
- **A new game** sets `START_FACING` ($CC3C) to $40 and enters `NEW_LIFE`
  at `FIRST_LIFE` ($CBC5), skipping the check and the tune. `LIVES` comes
  from `LIVES_BYTE` ([`protection.md`](protection.md)).
- **A death**: `KNIGHT_KILLED` ($CEC4) writes his cell, facing and flags
  into the start records and turns both his records into the vanishing
  cloud (12). Four turns later the legs' record is empty.
- **`NEW_LIFE`** ($CBAC, every turn from the main loop):
  1. returns while `KNIGHT` is not empty;
  2. the check: the byte at `TAKE_LIFE` ($CBDD) must be $35, `DEC (HL)`,
     or `JP RESET`;
  3. with lives left, `TUNE_NEW_LIFE`;
  4. `FIRST_LIFE`: `START_RECORDS` ($CC36) over `KNIGHT` and `KNIGHT_TOP`,
     `ARRIVING` = 40, `HITS` = 3;
  5. `TAKE_LIFE`: `DEC (HL)` on `LIVES`; below zero, `GAME_OVER`;
  6. `CLEAR_MONSTERS` ($C057), `ENTER_CELL` ($BF56, his cell visited), and
     the five life places on the panel at row 18 from column 5: a bright
     white knight for each life left, a blue one for each lost
     (`PRINT_LIFE_ICON` $CC1D, `LIFE_ICON_CODES` $CC2E).
- **Arriving**: 18 turns in which he rises from the ground, cannot move and
  cannot be touched ([`knight.md`](knight.md)).
- **Hits**: three a life; a monster's or the creature's touch takes one,
  the last ends the life; a villain's touch ends it outright; the flask
  bonus gives all three back ([`finds-and-bonuses.md`](finds-and-bonuses.md)).
  His colour shows them: white, yellow, green.
- **Carried over from the last game**: a new game resets `START_FACING` but
  not `START_FLAGS`, so the first life starts with the flags he died with.
  Harmless (*read*): bit 0 is cleared at his every update, bits 6-7 are set
  from his facing while he appears (`SET_KNIGHT_LOOK`), bit 1 is only the
  drawn flag, and nothing sets bit 5 in his record.

## How this was found

Read (stage 2, range 2). The lives' row and column from the screen
address, and the five knights seen on a rendered screen (*measured*). The
start-flags question settled for these notes by reading `SET_KNIGHT_LOOK`
($DC14) and `UPDATE_KNIGHT`'s first instruction.

## Confidence

*Read*; the lives display *measured*. The check's reset is *read* only; it
never ran (no session poked $CBDD).

## Filmation (Knight Lore, Alien 8, Pentagram)

The earlier games also start a life from start records, and Knight Lore
(like Alien 8 and Pentagram) picks the first room from four at random
([`../knightlore/lives-and-starting.md`](../knightlore/lives-and-starting.md));
Nightshade picks from all 625 standable cells, and restarts a life where
the last one ended. None of the earlier games checks its own code.
`matches.txt` finds no counterpart above 0.30.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `RANDOM_START_CELL` | `SUBCB7B` | $CB7B | the start cell of a new game |
| `FIRST_LIFE` | (new label) | $CBC5 | `NEW_LIFE` without the check and the tune |
| `PRINT_LIFE_ICON`, `LIFE_ICON_CODES` | `SUBCC1D`, `DATACC2E` | | a life's picture on the panel |
| `CLEAR_MONSTERS` | `SUBC057` | $C057 | the monster records emptied |
| `START_U_LOW`, `START_U_CELL`, `START_V_LOW`, `START_V_CELL` | `START_U`, `START_V` (the build script's) | $CC37-$CC3A | see below |

## Disassembly corrections

- The start records' labels. The generator labelled $CC37 and $CC39 (the
  low bytes) `START_U` and `START_V` and the cells `START_U_CELL`,
  `START_V_CELL`, while `build_nightshade.py` called the cells `START_U`
  and `START_V`: one name, two bytes. Now the low bytes are `START_U_LOW`
  and `START_V_LOW` (the generator adds `_LOW` to a two-byte field's
  label) and the build script's constants are `START_U_CELL` and
  `START_V_CELL`.
- Stage 1's `NEW_LIFE` description linked `#R$C1F9` and `#R$CBDD`, neither
  an entry; it now names `RESET` and `TAKE_LIFE` in prose. The label
  `TAKE_LIFE` itself was lost in the stage 2 merge (reported to the lead).
- The generator's description of `START_RECORDS` linked `#R$CEBB` (inside
  `WANDERING_MONSTER`); it now links `#R$CE89`.

## Also found for the stage 3 pages (2026-09-28)

- Cell 1,1 is the likeliest start: 67 of the 1024 random values land on it, since it follows the longest run of solid cells, wrapping round the end of the map (*measured*: RANDOM_START_CELL run for all 1024).
- The start is not the same every game: the menu counts the turn counter on at every pass (about 42 a second), so the start cell and the villains' places depend on how long the menu ran (*measured*, the reference build).
- The objects' and villains' places come from ROM byte pairs: 557 of the 625 standable cells can receive one; the furthest byte read is $100B (*measured*: PLACE_VILLAINS and PLACE_OBJECTS run for all 4096 values).

## Open questions

- An infinite-lives poke that survives the check: stage 3's pokes work.
