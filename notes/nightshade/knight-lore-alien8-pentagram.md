# Nightshade and the Filmation games

**Question this answers:** what Nightshade shares with Knight Lore, Alien 8
and Pentagram, where it differs, and what is its own.

**Short answer:** little of the engine is shared. The tune player, the menu
and its flashing, the pause, the key reading, Pentagram's sound effects,
the sprite row code and the sprite turner, and small helpers match the
earlier games instruction for instruction; the design ideas -- a graphic
that is both picture and behaviour, a table of update routines, masked
sprites drawn into a buffer that is copied out -- carry over. Everything
about the town is new: the map, drawing it from tiles with column claims
and outlines, the view that follows the knight and turns round, movement
against per-cell boxes, and a quest of throwing things at moving villains.

## How it works

`game_disassembly/nightshade/matches.txt` (from the scratch script
`ns_match.py`, stage 1) compared every Nightshade routine entry with Knight
Lore's, Alien 8's and Pentagram's by instruction pattern. Of 164 entries of
five instructions or more, 24 match one of the three at 0.80 or better, 40
at 0.60, and 124 match none.

| Shared, nearly as is | Nightshade | Counterpart |
|---|---|---|
| the tune player | `PLAY_TUNE`, `PLAY_NOTE`, `PLAY_TUNE_ONCE` | Pentagram's, Alien 8's (1.00) |
| the menu | `MENU`, `FLASH_MENU`, `TOGGLE_SELECTED`, `FLASH_NEXT_ONE` | Alien 8's (0.96-1.00), with a tune for its beep |
| key reading | `READ_KEYS`, `READ_CONTROLS` | all three (1.00); Alien 8's shape (0.86) |
| the pause | `PAUSE` | Alien 8's `HANDLE_PAUSE` (0.91), silent here |
| sound effects | `EFFECT_NOTE`, `FIRE_SOUND`, `FOOTSTEP`, `PUFF_SOUND`, the blips | Pentagram's (1.00), some unused there |
| sprite rows | `SPRITE_ROW`, the runs | Pentagram's (1.00), with plain tables for even shifts |
| turning sprites | `TURN_SPRITE` | Alien 8's `VFLIP_SPRITE_DATA` (0.93), Pentagram's `FIND_SPRITE` |
| helpers | `CLEAR_SCREEN`, `CLEAR_MEMORY`, `TABLE_WORD`, `NEXT_FRAME_MOD4`, `HL_EQUALS_DE_X_A` | their names reused |

| The same idea, new code | Where |
|---|---|
| graphic = picture + update routine | [`graphic-numbers.md`](graphic-numbers.md) |
| a depth sort by candidate and swap | [`depth-order.md`](depth-order.md): two axes, one cell at a time |
| the isometric projection | [`projection.md`](projection.md): half the scale, from the knight, no height |
| a buffer counted up from the bottom, SP-read rows, shift and reverse pages | [`drawing-sprites.md`](drawing-sprites.md), [`drawing-the-town.md`](drawing-the-town.md) |
| legs and top as two records | [`knight.md`](knight.md) (Alien 8's robot too) |
| the ending as object records | [`game-over-and-ending.md`](game-over-and-ending.md) (Alien 8's scenes) |

**Nightshade's own**: the protection ([`protection.md`](protection.md));
the town map, its cell types and boxes ([`town.md`](town.md)); the drawing
order, column claims and outlines; the turned-round view; monsters that
spawn round the player and are forgotten; antibody kinds and strike
outcomes; the creature; finds and bonuses; eleven carried things with the
villain-near hint; the percentage by cells; the stack leak.

**Leftovers passed on**: Pentagram (1986) contains Nightshade's blip and
beep routines unused, and the same 80 bytes of blip pitches -- read, there
as here, only for their first sixteen. The later game keeping code the
earlier one used suggests a shared source (*inferred*).

## How this was found

The cross-match (stage 1), then each matching routine read against its
counterpart's annotation in stage 2, noting where it differs.

## Confidence

The matches *measured* (instruction patterns); the differences *read*. A
close match is a hint; each was read.

## Open questions

- Gunfright (1986) is the other Filmation II game, also a scrolling town:
  comparing it would show how much of this engine carried on. Not
  disassembled here.
