# Memory map

**Question this answers:** where everything is -- the BASIC, the machine
code, the scripts, the tables, the variables, the object records, the
buffers, the sprites and the city -- and what is code, what is data and what
is unused.

**Short answer:** the tape block fills $5C00-$FFFF: system variables and the
game's 8K of BASIC below $8000, the machine code at $8000-$8FFF, the scripts
at $9000, the loader's tail and the interrupt table at $9700-$9901, then
sprites, buffers and variables interleaved up to $BFFF, and the city map in
the top 16K. Every byte is in a labelled entry of the listing; code is only
what ran in the playthrough or follows from it.

## Regions

| From | To | Label | What |
|---|---|---|---|
| $4000 | $5AFF | | the screen. Play area: rows 12-127, bytes 1-30 (`COPY_TO_SCREEN`); the panel below is BASIC's; the machine code writes the scanner's and the play area's attributes |
| $5B00 | $5BFF | | printer buffer; the loader's stack at $5BF0 during the load, not loaded over |
| $5C00 | $5CB5 | | system variables, from the tape. Named in the listing: `ERR_NR` $5C3A, `ERR_SP` $5C3D ($7FFC), `E_LINE` $5C59, `SEED` $5C76 |
| $5CB6 | $5CCA | | channel information |
| $5CCB | $7DD9 | | the game's BASIC, 8463 bytes; each line an entry described by its listing ([`basic-and-levels.md`](basic-and-levels.md)) |
| $7DDA | $7FFF | | VARS (empty on the tape), the edit line, workspace, the machine stack (ERR_SP $7FFC); RAMTOP $7FFF |
| $8000 | $8FFF | `PLAY` ... | the machine code: routines mostly on 16-byte boundaries, the gaps filled with $FF as `..._PAD` entries; small tables and leftovers in the gaps (below) |
| $9000 | $93B9 | `SCRIPTS`, `SCRIPT1`-`SCRIPT17` | the seventeen scripts ([`scripts.md`](scripts.md)) |
| $93BA | $96FF | `SCRIPT17_PAD` | $02 filler |
| $9700 | $9711 | `LOADED` | where LD-BYTES returns: the load checks, IM 2, into `RESTART_BASIC` |
| $9712 | $9796 | `LOADED_PAD` | zeros, $02, a stray copy of the IM 2 set-up |
| $9797 | $97BA | `INTERRUPT`, `RESTART_BASIC` | the interrupt routine and the typed RUN ([`loading.md`](loading.md)) |
| $97BB | $97FF | `RESTART_BASIC_PAD` | filler |
| $9800 | $9901 | `INTERRUPT_VECTORS` | $97 throughout, so IM 2 lands on $9797 whatever the bus holds |
| $9902 | $99FF | `INTERRUPT_VECTORS_PAD` | $02 filler |
| $9A00 | $9FFF | `SPRITES`, `FRAME69`... | sprite frames $68-$7F: the grenade's own four, then the girl's twenty |
| $A000 | $B17F | `RENDER_BUFFER` | 140 rows of 32 bytes; the view is painted here |
| $B180 | $B41F | `VIEW_CELLS` | 21 rows of 32 gathered map cells |
| $B420 | $B44F | `VIEW_ORIGIN`... | the game variables (below) |
| $B450 | $B469 | `SPRITE_LIST` | 8 entries of 3 bytes (place, then frame) and an end marker |
| $B46A | $B47F | | unused (zeros) |
| $B480 | $B4FF | `PLAYER`... `ANT5` | the eight object records ([`objects.md`](objects.md)) |
| $B500 | $B6FF | `PLANES` | 512 slots, the height bit to paint in each, or $FF |
| $B700 | $BFFF | `MORE_SPRITES`, `FRAMEDD`... | sprite frames $DC-$FF: the boy $DC-$EF, $F0-$F3 never drawn, the grenade in flight and the blast $F4-$F7, the ants $F8-$FF |
| $C000 | $FFFF | `CITY_MAP`, `CITY_Y81`...`CITY_YFF` | the city, 128 rows of 128 cells ([`city-map.md`](city-map.md)) |

A sprite frame f is at $8000 + 64f, so the frame numbers are fixed by where
the two banks sit; from 2026-09-27 every frame is its own entry,
`FRAMEnn`, the first of each bank keeping the bank's label. Likewise every row
of the city from `CITY_Y81`, the first keeping `CITY_MAP`.

## In the code's gaps

| Address | Label | What |
|---|---|---|
| $8034-$805F | `PLAY_PAD` | the author's signature (twice and a fragment) |
| $8200-$8202, $8700-$8702 | in the pads | `LD DE,31` before each block drawer, never run |
| $8448-$845F | `READ_VIEW_KEYS_PAD` | the signature again |
| $8B60-$8B7F | `NOISE_PAD` | the unused script fragment |
| $8BB1-$8BD0 | `TONES` | the note table: 16 pairs of pitch delay and half-cycle count |
| $8BFF-$8CFF | `PARALYSE_ANT_PAD` | a page of repeated LD C,0 / LD A,($B425), ending in RET; never run |

See [`leftovers.md`](leftovers.md).

## Variables ($B420-$B44F)

BASIC sets these at every attempt (lines 200-230) except the time, which is
set per level (line 750). The two-byte counts are big-endian, for the ROM's
number printer, and the machine code only touches their low bytes.

| Address | Label | Meaning | Set by / used by |
|---|---|---|---|
| $B420-$B421 | `VIEW_ORIGIN` | x and y the view is gathered from | BASIC; `READ_VIEW_KEYS`, `SCROLL_VIEW`; `GATHER_VIEW`, `PROJECT_SPRITES` |
| $B422 | `VIEW` | which of the four views | BASIC; `READ_VIEW_KEYS`; the gather, the projection, the block drawer |
| $B423-$B427 | | set to 1 by BASIC, never read | |
| $B428-$B42A | `RANDOM_BITS` | the random generator, 32 bits big-endian... | BASIC (all 1); `RANDOM` |
| $B42B | `RANDOM_LOW` | ...its last byte, where the new bit goes in | `RANDOM` |
| $B42C | `BORDER` | the border colour for the sound routines' OUTs | BASIC (0 in play, 5 for the ending); `TONE`, `NOISE` |
| $B42D | `GRENADE_EVENTS` | bit 0 thrown, 1 exploded, 2 hit an ant | `THROW_GRENADE`, `BLAST_ANT`; `GRENADE_SOUNDS` |
| $B42E | `THROW_TIME` | frames of flight left | `THROW_GRENADE` |
| $B42F-$B430 | `AMMO`, `AMMO_LOW` | grenades left, 20 | BASIC; `THROW_GRENADE`; script 4 |
| $B431-$B432 | `PLAYER_ENERGY`... | the player's energy, 20 | BASIC; `HANDLE_EVENTS`, `CHECK_GAME_OVER`; script 8 |
| $B433-$B434 | `RESCUEE_ENERGY`... | the rescued person's energy, 20 | the same; script 11 |
| $B435 | `TIME_TICKS` | frames to the next clock tick (3) | `COUNT_DOWN_TIME`, `CHECK_RESCUED`, `CHECK_GAME_OVER` |
| $B436-$B437 | `TIME` | the clock, 1001 at a level's start | BASIC line 750; `COUNT_DOWN_TIME`; BASIC reads it for the score |
| $B438 | `FRAMES_LEFT` | frames to run; $FF while playing | BASIC (2 before the first call); `PLAY`, `CHECK_RESCUED`, `CHECK_GAME_OVER` |
| $B439-$B44E | | unused (zeros) | |
| $B44F | `CLEAR_PHASE` | which quarter of the buffer's rows is cleared next | `CLEAR_BUFFER_ROWS` |

The sprite list ($B450, *read*): three bytes per object in the order
`PROJECT_SPRITES` meets them (the fifth ant first, the player last):
a place in `PLANES` (a gap once `SPRITE_DISTANCES` has run) and a frame.
`RESCUEE_SPRITE` $B462 and `PLAYER_SPRITE` $B465 are named because
`SCROLL_VIEW` reads the player's place before the sort. $B468-$B469 is a
count to a ninth sprite that is never reached: `PLAY` sets its high byte to
$FF.

Outside this area, BASIC's own variables (`w`, `sg`, `sp`, `fin`, `r`, `se`
...) live in the VARS area above the program; `w` is 46237, the address of
`RESCUEE_STATE`.

## Code, data, unused

- **Code:** $8000-$8FFF less the pads, plus $9700-$9711 and $9797-$97BA --
  1872 instruction starts in the code map, all but three run in the
  playthrough (the three in `FALL`). The listing also shows one unreachable
  NOP at $852A inside `DRAW_SCENE` that is not in the code map (*read*,
  2026-09-27).
- **Data:** everything else, each table as an entry; nothing is data
  dressed as code (the code map came from running it).
- **Unused:** the pads and fillers, $B423-$B427, $B439-$B44E, $B46A-$B47F,
  the frames $F0-$F3, note 15, the $8B60 fragment ([`leftovers.md`](leftovers.md)).

## How this was found

The regions are the listing's entries (the skool file as of 2026-09-27,
mid-way through the lead's splitting); the system variables' values were
read from the snapshot; the uses of each variable come from searching the
code for its address and from the BASIC's POKEs.

## Open questions

- None about the layout. What the five unused variables were for is open
  ([`leftovers.md`](leftovers.md)).
