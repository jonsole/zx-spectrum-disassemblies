# Game over and the ending

**Question this answers:** what happens when a game ends, and how the
ending is played when the quest is done.

**Short answer:** `GAME_OVER` shows the percentage and the score on a
bordered screen, plays a tune and goes back to the menu -- unless all four
villains are gone, when it empties every record, fills ten from a table and
lets the main loop play the ending: the four villains are brought in one at
a time from the sides, carried over a pit and sunk into it; then the end
tune and the menu. Every game over leaves two bytes on the stack.

## How it works

- **`GAME_OVER`** ($CC56), from `NEW_LIFE` (no lives left) and
  `CHECK_QUEST_DONE` (the quest done): `PERCENTAGE` ($BEDF), clear the
  screen, `PRINT_BORDER`, the four lines of `END_TEXT` ($CDAF) by
  `PRINT_TEXT`, the percentage after the third line in cyan
  (`PRINT_PERCENTAGE`, [`percentage.md`](percentage.md)), the score after
  the fourth in yellow, `TUNE_GAME_OVER`, and `GAME_OVER_PAUSE` ($CDDF,
  about half a second; `GAME_OVER` sets B to 4 first, which it ignores).
- Any villain record holding 96-111: `JP NEW_GAME`, the menu.
- Otherwise the ending: `CLEAR_OBJECTS` ($CD02, graphic 0 in all 23), ten
  records from `ENDING_RECORDS` ($CCE4) -- graphic into +0, x and y into +A
  and +B (the step bytes, reused as a place in the play area, y up from its
  bottom), flags and offset 0 -- clear the screen, `ENDING` = 1, clear the
  buffer, `JP MAIN_LOOP`, which with `ENDING` set only updates records and
  shows the buffer.

| Records | Graphics | Routine | What |
|---|---|---|---|
| 0-4 | 153-157, in a row at y 96 | `ENDING_PICTURE` ($CD16) | the back of a pit, white |
| 5-8 | 144, 146, 148, 150 at y 128, x 16 or 208 | `ENDING_VILLAIN` ($CD58) | the villains of 96, 100, 104, 108, waiting at the edges |
| 9 | 152 at (96, 72) | `ENDING_PIT_FRONT` ($CD10) | the pit's front, updated last and so drawn over what sinks |

- **`ENDING_VILLAIN`**: toggles its frame each turn; waits, undrawn, while
  the record before it is a villain still under way, so they go one at a
  time; then moves across up to 4 a turn (`STEP_TOWARDS_X`, $CD9E) to 4
  right of the pit front's x (read from record 9's +A, $BD28), then down 4 a
  turn until y is below 48, and empties. Colours red, magenta, green, cyan
  by bits 1-2 of the graphic -- each villain in its object's colour. A note
  rises all the while (`ENDING_BEEP`, $C39D, counting on `EFFECT_TIME`).
- **`ENDING_PIT_FRONT`**: when record 8 is empty, `TUNE_ENDING` and
  `JP NEW_GAME`. `DRAW_ENDING_PICTURE` ($CD1B) is the common drawing: the
  place into +E/+F, the sprite by `DRAW_SPRITE_AT`, and a rectangle of
  attributes (`FILL_ATTR_RECT`, $C8B2) in `ENDING_COLOUR` ($BC00), using
  `SPRITE_WIDTH` and `SPRITE_ROWS` from the drawing.
- **Timing** (*measured*, 0.1 s steps of emulated time): each villain takes
  about 2 seconds to cross and sink; the pit is empty after about 8.5
  seconds, and the menu returns after about 13, the end tune taking the
  rest.
- **The stack**: `GAME_OVER` is jumped into from routines the main loop
  calls, and leaves by `JP`; `ENDING_PIT_FRONT` jumps to `NEW_GAME` from
  inside an update. Two bytes lost a game over, four an ending; after 156
  games the machine crashes ([`protection.md`](protection.md)).

## How this was found

Read (stage 2, range 2); then staged in the simulator: a game started, at
`MAIN_LOOP` the four villain records emptied and the last life ended, the
screen rendered every second through the ending and the ten records logged
every 0.1 s. The pit's six sprites drawn with the build's `sprite_image`.
The build's quest session reaches the ending the real way.

## Confidence

*Read* and *measured* (the order, the colours, the pit, the timing, the
stack).

## Filmation (Knight Lore, Alien 8, Pentagram)

`CLEAR_OBJECTS` is Alien 8's name for the same job. The earlier games'
game-over screens print through their buffered printer; this one prints
straight to the screen. The ending -- object records moved by their own
update routines while the main loop only updates -- is new; Alien 8's
scenes after a game are a similar idea ([`../alien8/scenes.md`](../alien8/scenes.md)).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `CLEAR_OBJECTS` | `SUBCD02` | $CD02 | empty every record |
| `ENDING_PIT_FRONT`, `ENDING_PICTURE`, `DRAW_ENDING_PICTURE`, `ENDING_OVER` | `SUBCD10` and new labels | $CD10, $CD16, $CD1B, $CD4F | the pit, and the end of the ending |
| `ENDING_VILLAIN`, `DRAW_ENDING_VILLAIN`, `SINK_ENDING_VILLAIN` | `SUBCD58` and new labels | $CD58, $CD7C, $CD8A | graphics 144-151 |
| `STEP_TOWARDS_X` | `SUBCD9E` | $CD9E | a move across, at most 4 |
| `GAME_OVER_PAUSE` | `SUBCDDF` | $CDDF | about half a second |
| `ENDING_BEEP` | `SUBC39D` | $C39D | the rising note |
| `FILL_ATTR_RECT` | `SUBC8B2` | $C8B2 | a rectangle of attributes |

`GAME_OVER` is stage 1's and stands, its title reworded.

## Open questions

- **The percentage at 100 prints wrong** -- stage 3 is checking it live
  ([`percentage.md`](percentage.md)).
- `GAME_OVER_PAUSE`'s unused B: a leftover of a loop of four?
