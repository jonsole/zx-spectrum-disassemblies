# Lives, starting and dying

**Question this answers:** where a game and a life start, how lives are
counted, taken and given, and what the robot does as he dies and appears.

**Short answer:** two 32-byte start records (`START_LEGS` $CA1D, `START_TOP`
$CA3D) hold the robot as a life starts. A new game fills them from
`START_TEMPLATE` ($CA5D) in one of four rooms picked by the seed; every
doorway overwrites them with the robot as he came through; `NEW_LIFE`
($CA07) copies them over his records and takes a life, so a lost life starts
again at the last doorway. Five lives at a new game, shown as 4 once the
first is taken. An extra life -- a place given graphic 12 -- adds one when
touched. He dies in a sparkle (graphics 48-55) and appears through graphics
56-63.

## How it works

- **A new game** (`NEW_GAME_START` $CA6D): `START_TEMPLATE` into +0-+7 of
  both records -- graphic 56, U and V 128, Z 64 and 76, half-sizes 7,
  heights 12 and 11, flags bits 2, 3 and 4 -- +$10 the graphics after
  appearing (22 and 38, facing higher U), and the room from `START_ROOMS`
  ($CA9E: $13, $4E, $88, $D7) by bits 0-1 of `SEED`. In the simulator the
  seed is always the same and the start is always $4E. `MAIN_NEW_GAME`
  clears the start legs' +$0C ($CA29), the walk-in count a doorway leaves
  set.
- **A life** (`NEW_LIFE` $CA07, from `MAIN_NEW_LIFE`): both start records
  over the robot's, `LIVES` less one; below zero the game is over
  (`GAME_ENDED` $B761). The first life of a game takes five to four.
  `LIVES` ($5B1A) counts in binary and is printed as though BCD
  (`PRINT_LIVES` $BA57, at pixel (128, 7)), so ten or more would print
  wrongly -- but they cannot happen: the panel shows 4 in the first life,
  and a game deals at most three extra lives, so it never shows more than 7
  (*read*, worked out for these notes; range 3's draft had left it open).
- **A doorway** (`EXIT_SCREEN` $C3B7) copies both his records into the start
  records, the graphic moved to +$10 and replaced by 56
  ([`doorways-and-rooms.md`](doorways-and-rooms.md)).
- **Appearing** (`PLAYER_APPEARING` $BC70, graphics 56-62): nudge -12, -8;
  on turns with `TURNS` odd the next frame, a sound from the frame
  (`MATERIALISE_SOUND` $B604), a redraw -- about 2.5 s of game time at a new
  game (*measured*, stage 1). `PLAYER_APPEARED` ($BC83, graphic 63): the
  steps zeroed, +$0D bit 6 (killed) cleared, the graphic from +$10, and
  straight on into that graphic's update routine through the main loop's
  dispatch.
- **Dying** (*read*): anything deadly passes bit 6 of +$0D to him in the
  collision code ([`collision.md`](collision.md)). `PLAYER_LEGS` sees it,
  kills the top too, and `START_SPARKLE` ($B39A) turns the record into
  graphic 48 and takes it out of the collision tests. `SPARKLE_STEP` ($B3A4)
  moves a frame a turn with `SPARKLE_SOUND` ($B5EE) -- blips from the ROM
  at $1234 on, as many as the complement of the graphic's low five bits, 15
  at 48 down to 9 at 54 -- and `SPARKLE_END` ($B3B8) at 55 makes it graphic
  1, emptied when next drawn. When both his records are empty the main loop
  starts a new life.
- **The short sparkle**, graphics 64 and 65: an extra life taken, a
  collapsing block, a valve destroyed. At 65 `SPARKLE_END_PLACE` ($B3B0)
  empties the thing's place through +$10/+$11, so a taken extra life is gone
  for good (31 blips at 64).
- **An extra life** (`EXTRA_LIFE` $BEE0, graphic 12, dealt to two or three
  places a game, [`valves-and-sockets.md`](valves-and-sockets.md)): nudge
  -8, -2; the legs' half-sizes one wider in U and V for
  `IS_ON_OR_NEAR_OBJ`, then back. Touched: graphic 64 with the sparkle's
  nudge, the place's graphic zeroed, `DROP_LATCH` cleared, `LIVES` + 1, a
  beep, `PRINT_LIVES` and `BLIT_2X8` at (128, 0). Then it falls like
  anything else (`EXTRA_LIFE_FALL` $BF22): if it moved, its U and V steps
  are cleared and it sounds and is redrawn.
- **Transfer records** (`TRANSFER_SPRITE` $CAF1): four bytes into +0, +7,
  +$1A, +$1B of `PANEL_RECORD` for the panel's and the border's pieces
  ([`menu-and-panel.md`](menu-and-panel.md)).

## How this was found

Read against Knight Lore's `init_start_location` (0.90), `upd_103` (0.78)
and `init_death_sparkles`, and Pentagram's `RESTART_PLAYER` (1.00) (stage 2,
ranges 2, 3 and 4). *Measured* by stage 1's sessions: the start room $4E,
the appearing, every death the room tour staged, an extra life touched and
its place emptied, game over at no lives.

## Confidence

*Read*, and *measured* by the sessions as above.

## Knight Lore and Pentagram

Knight Lore's start-record scheme: the respawn at the last doorway, the real
graphic kept at +$10 while the appearing plays
([`../knightlore/lives-and-starting.md`](../knightlore/lives-and-starting.md)).
The death sparkle is Knight Lore's `init_death_sparkles` and `upd_185_187`
(Pentagram's `START_PUFF`). `EXTRA_LIFE` is Knight Lore's `upd_103`, fed
from the places rather than the special-object table. Pentagram has no
appearing ([`../pentagram/lives-and-starting.md`](../pentagram/lives-and-starting.md)).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `PLAYER_APPEARING`, `PLAYER_APPEARED` | `SUBBC70`, `SUBBC83` | $BC70, $BC83 | graphics 56-62, 63 |
| `EXTRA_LIFE` (`EXTRA_LIFE_FALL`) | `SUBBEE0` | $BEE0 | graphic 12 |
| `START_SPARKLE` (`SPARKLE_SOUND_AND_DRAW`), `SPARKLE_STEP`, `SPARKLE_END_PLACE` (`SPARKLE_END`, `VANISH`, `SOUND_AND_DRAW`) | `SUBB39A`, `SUBB3A4`, `SUBB3B0` | $B39A-$B3BF | the sparkles |
| `ENTER_ROOM`, `TRANSFER_SPRITE` | `SUBCAA2`, `SUBCAF1` | $CAA2, $CAF1 | building the room; four bytes into the panel's record |
| `PRINT_LIVES` (`PRINT_BCD_NUMBER`, `PRINT_BCD_BYTE`, `PRINT_BCD_LSD`) | `SUBBA57` | $BA57 | lives on the panel |

`NEW_LIFE`, `START_LEGS`, `START_TOP`, `START_TEMPLATE`, `NEW_GAME_START`
and `START_ROOMS` keep stage 1's names.

## Disassembly corrections

- `LIVES` is binary, not BCD: INC and DEC, no DAA; only printed as BCD
  (range 1).

## Open questions

- Why `PLAYER_APPEARED` clears the killed bit: perhaps so that something
  deadly touched while appearing does not count. Not tested.
- `$CA29`, the start legs' +$0C that `MAIN_NEW_GAME` clears, has no label of
  its own: the start record's row there is seven bytes, and a label needs
  the row split in the annotations.
