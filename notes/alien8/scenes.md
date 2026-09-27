# The scenes after a game

**Question this answers:** what the two scenes after a game are, how they
run, and how they end.

**Short answer:** after a loss, the robot is re-programmed: it stands on a
stand with sparks flashing over its head, then a glove, a hammer and a hook
take turns to strike it -- fifteen strikes, or a key once the sparks have
stopped. After the twenty-fourth chamber, the robot is lowered into a can of
oil and rises gleaming white, and a tune plays. Both are object records run
by the main loop with `GAME_OVER` ($5B24) set, their pieces placed in pixels
rather than projected. Both end at `AFTER_GAME` ($A647) and the menu.

## How it works

- **Setting up** (`SET_UP_SCENE` $B804, from `GAME_ENDED`): five-byte
  entries -- graphic, flags, colour, x, line -- into +$00, +$07, +$10, +$1A,
  +$1B of the records from `OBJECTS` up, to a zero. The lost scene
  (`SCENE_LOST`, $B82A) has eight pieces: glove 81 (red, right), hook 83
  (white, left), hammer 82 (green, above), the stand 88 and 89 and the robot
  90 and 91 (cyan), sparks 80. The won scene (`SCENE_WON`, $B853) has three:
  the robot 92 and 93 (white) and the oil can 85 (green). Graphics 90-93
  draw with the robot's own sprites. The lost scene also flashes the text at
  `REPROGRAMMING` ($B7F5).
- **Not projected.** While `GAME_OVER` is set `CALC_PIXEL_XY` returns at
  once and `CALC_2D_INFO` leaves the position alone, so +$1A/+$1B are the
  piece's pixel position, moved by its routine. No controls are read, the
  main loop does not wait or run the clock ([`main-loop.md`](main-loop.md)).
- **Colour** (`COLOUR_SCENE_OBJECT`, the entry point $AC21 inside
  `SCENE_SPARKS`): paints the cells a piece covers with its +$10, bottom row
  up, skipping cells already $44 (green). Graphics 85 and 88-91 use it as
  their whole update.
- **The sparks** (`SCENE_SPARKS` $ABF5, graphic 80): every eighth turn
  yellow or black by bit 3 of `TURNS`, and a beep; after 16 flashes
  `SCENE_STATE` ($5B41) = 1 and the sparks go.
- **The tools** (`SCENE_TOOL` $AB61, graphics 81-83): once `SCENE_STATE` is
  set, keys 1-0 end the scene; otherwise a tool starts with a chance of 1 in
  4 a turn when none other is swinging (bit 7 of `SCENE_STATE`), with a
  thud: six steps of 8 pixels across (the glove and the hook) or 4 down (the
  hammer), a crash, six back. Bits 0-6 of `SCENE_STATE` count the swings;
  at 16 -- fifteen strikes -- the scene ends.
- **The oiling** (`OILED_ROBOT` $A971, graphic 92): waits 64 turns; down 3
  pixels a turn to below 40; waits until +$11 reaches 128; up 3 pixels a
  turn, bright white, back to 128; then `TUNE_WON` ($B3D7) and `AFTER_GAME`.
  `SCENE_ROBOT_TOP` ($A95A, graphic 93) follows 16 pixels above it, copying
  its colour and flags.

## How this was found

Read (stage 2, ranges 1 and 2; the lists decoded by a scratch script), then
*measured*: screenshots of both scenes and of the summary in the simulator
(the game over staged with no lives; the win staged by setting `WON` before
the last death), and `SCENE_STATE`, the robot's y and its +$11 sampled
turn by turn.

## Confidence

*Read*, and *measured* by the screenshots and samples. The robot's head
stays green after the hammer's blows (seen in the screenshots): nothing
restores those cells, since `COLOUR_SCENE_OBJECT` skips cells already green.

## Knight Lore and Pentagram

Nothing like either scene: Knight Lore's and Pentagram's ends are text
screens only.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `SCENE_TOOL` | `SUBAB61` | $AB61 | graphics 81-83 |
| `SCENE_SPARKS` (`COLOUR_SCENE_OBJECT` $AC21) | `SUBABF5` | $ABF5 | graphic 80; the colouring entry |
| `OILED_ROBOT`, `SCENE_ROBOT_TOP` | `SUBA971`, `SUBA95A` | $A971, $A95A | graphics 92, 93 |
| `SET_UP_SCENE` | `SUBB804` | $B804 | the scene's records |
| `REPROGRAMMING` (`_TEXT`, `_END`) | `DATAB7F5`, `TEXTB7F6`, `DATAB803` | $B7F5 | its text |
| `SCENE_LOST` ... `SCENE_WON_END` | `DATAB82A` ... `SPACEB862` | $B82A-$B862 | the two lists, in sna2ctl's pieces |

## Disassembly corrections

- `$B862` was "unused" in stage 1: it is the zero that ends the won scene's
  list, which `SET_UP_SCENE` stops on (range 2).
- The tunes and scene lists at $B3C5-$B436 and $B82A-$B862 were sna2ctl's
  guesses at text: they are bytes.

## Open questions

- Whether the green head is meant.
