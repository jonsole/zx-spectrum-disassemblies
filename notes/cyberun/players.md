# Players

**Question this answers:** how one or two players are kept -- what is
remembered for each, how the turns change hands, how each keeps their own
state of a shared world, and how the score is counted and shown.

**Short answer:** everything that belongs to a player is in one 105-byte
record. The current player's is always at `score` ($F5E7) and the waiting
player's at `other_player_record` ($F650); at a change of turn
`swap_players` ($F591) swaps the two records byte for byte, and the two
score lines of the panel with them, so no other code ever asks which player
is playing. The one thing the players share -- the table of the 290
objects lying in the world -- keeps a "gone" bit for each (bit 7 player 1,
bit 6 player 2), and `play` patches the one BIT and two SET instructions
that use it at the start of every life. Scores are three BCD bytes, shown
as six digits.

## How it works

### The record

105 ($69) bytes. The current player's at $F5E7-$F64F, the other's at
$F650-$F6B8, laid out the same. Every field the code names has an entry of
its own in the listing.

| Offset | Address | Label | Field |
|---|---|---|---|
| +0-+2 | $F5E7 | `score` | the score, BCD, least significant byte first |
| +3-+5 | $F5EA | `player_flag_bits` | 24 bits, one for each of twelve page rows and two halves of the map across (columns below $30, and from $30): a beam maker there has been destroyed, so `draw_beams` draws no beam there. Set by `beam_hits_ground_object` (ground objects of kinds 6 and 7) through `map_square_bit` ($AC08); cleared at a level's end (`level_done`) |
| +6 | $F5ED | `lives` | 5 at a new game; one taken by `lose_life`, one given by `contact_extra_life` (at most 9) |
| +7 | $F5EE | `addon_slots` | add-on 1; with +8 to +15, nine slots, add-on n's slot holding n or 0. `draw_ship_image` fills a slot when the add-on is fitted; `build_ship_sprite` builds the ship from them. Add-on 1 is needed to pick up a rocket part |
| +8 | $F5EF | `addon_two` | add-on 2, written by `build_ship_sprite` as twice add-on 1's slot: the two always come together |
| +9 | $F5F0 | (in `addon_two`) | add-on 3; not read by name |
| +10 | $F5F1 | `addon_four` | the side jet: top speed across 4 instead of 2. With +11 set too, `start_attacker` adds two more kinds of attacker |
| +11 | $F5F2 | `addon_five` | the lift jet: top climb 4, and the ceiling moves from page row 5 to row 0 |
| +12 | $F5F3 | `addon_six` | halves the fuel burn |
| +13 | $F5F4 | `addon_seven` | the special beam (the special key, bit 5 of the controls) |
| +14 | $F5F5 | `addon_eight` | every other shot a homing missile |
| +15 | $F5F6 | `addon_nine` | the ship 11 rows taller; the two-piece part (kind 9) can be picked up |
| +16 | $F5F7 | `player_count_nine` | 9 while the ship carries the two-piece part (`collect_pickup`); cleared by `start_landscape` for a start below ground |
| +17 | $F5F8 | (in `player_count_nine`) | nothing refers to it |
| +18 | $F5F9 | `level` | the planet, 0-4 (`planet_secured`) |
| +19, +20 | $F5FA | `restart_scroll` | where the next life starts: `view_column` and the map row (the fly-in starts a row lower and scrolls up to it) |
| +21, +22 | $F5FC | `restart_view` | `view_x` and `view_y` there; bit 0 of x set for a start in the sky |
| +23, +24 | $F5FE | `restart_fine` | `origin_x` and `origin_y`, the fine scroll |
| +25 | $F600 | `ore_kept` | the ore aboard at the last life's loss, put back by `play` |
| +26 | $F601 | `rocket_part_carried` | the rocket part hanging from the ship, $FF none |
| +27 | $F602 | `parts_built` | rocket parts delivered: the number of the part due next |
| +28 | $F603 | `control_method` | 0 keyboard, 1 Kempston, 2 cursor, 3 Interface II ([`input.md`](input.md)) |
| +29-+104 | $F604 | `player_places` | 19 places of 4 bytes (below) |

The places, dealt at random from a pool at every new game (`deal_places`,
$6113, once for each record): each four bytes, the map column, the map
row, x and y within the cell; bit 7 of the first byte set once its
pick-up is taken. Places 0-10 are where the add-ons lie (place k for
add-on k+1; `load_map_window` puts them into the pick-up slots as kind
$0C), places 11-18 the eight rocket parts (kind $1E, part p at place
11+p). Places 1 and 2 are never dealt (add-ons 2 and 3 are not found
lying about), place 10 is dealt as a companion of place 9 (16 pixels to
its right and 35 up: the two pieces of the big part), and the labels
`place_nine` ($F628), `place_ten` ($F62C), `place_eleven` ($F630) and
`place_last` ($F64C) are the ones the code names. Because the pool is
freed before each call, the two players can be dealt the same places.

`clear_player_record` ($F39E) zeroes +0 to +27, sets +26 to $FF and copies
`start_position` ($F3B7) into +19 to +24; `new_game` then writes the
lives, the control method (+28) and the places (+29), the second player's
by address ($F656, $F66C, $F66D).

### Taking turns

```
new_game $F3BD       both records cleared; lives 5 and 5 (0 for player 2
                     with one player); player_in_play $CA1C = 0
lose_life $F4C6      ore kept; a life less; none left -> game_over;
                     two players -> swap_players
game_over $F4FC      ... two players -> swap_players
swap_players $F591   the other has no lives: return
                     swap the 105-byte records (swap_bytes $F5C4)
                     swap the two 16-byte score lines on the panel
                     player_in_play = $99? return (new_game's reordering)
                     player_in_play XOR 1; show_player; a pause;
                     clear_play_area
```

The turn passes at each life lost, not at a level's end: `level_done`
goes straight back to `play` with the same record. With one player the
other record's lives are 0, so `swap_players` never swaps it in.

What lives outside the record is per life and reset by `reset_for_life`
(the hits, the shield, the shots, the objects), or the ore aboard (`ore`,
$C905), which `lose_life` saves into +25 and `play` puts back. The high
score is shared.

### The gone bits

`map_object_kinds` ($5C94) has a byte for each of the 290 objects that lie
in the world: bits 0-5 the kind, bit 7 set once player 1 has taken or
destroyed it, bit 6 the same for player 2. At the start of every life
(`play_0`, $F44C) the current player's bit is written into three
instructions:

| Address | In | Instruction | Player 1 | Player 2 |
|---|---|---|---|---|
| $E118 | `spawn_objects_from_list` | the test: is it gone? | BIT 7,(HL) ($7E) | BIT 6,(HL) ($76) |
| $A9B8 | `ship_hits_ground_objects` | a refuel pad used up | SET 7,(HL) ($FE) | SET 6,(HL) ($F6) |
| $ABDE | `beam_hits_ground_object` | an object destroyed | SET 7,(HL) ($FE) | SET 6,(HL) ($F6) |

The patched byte is the second of each CB-prefixed instruction; `play`
works out $7E or $76 from `player_in_play` and ORs in $F0 for the SETs.
`mask_world_objects` ($9A8A) ANDs the whole table with a mask: $3F at a
new game (both bits off: everything back for both), and at a level's end
`planet_secured` builds $7F or $BF from `player_in_play`, clearing only the
current player's bit. *read*

So the technique for a two-player game with a persistent world: keep the
world shared, give each player a bit per object, and patch the bit number
into the instructions once a turn rather than test the player everywhere.

### The score

`add_score` (an entry inside `test_player_shots`, $925E) adds BC, two BCD
bytes, into `score` with DAA and a carry into the third byte, then turns
the three bytes into six digit codes (the font's $1A-$23) at
`p1_score_digits` ($C9F0) and prints the text record `p1_score_text`
($C9EC). What scores:

| | Points |
|---|---|
| an attacker shot | by type, from `type_points` ($929C): 350, 250, 200, 150, 100, 90; the tough attacker 75 a hit; doubled when destroyed outright (+$17 bit 3) |
| types $0D and $1B (ground objects) | 250 |
| a pick-up taken (`collect_pickup`) | 1000 |
| a rocket part delivered (`update_rocket_part`) | 1500 |
| a planet secured (`planet_secured`) | 10 x 5000 |

The panel's score lines are swapped with the records, not redrawn: each
line is a 16-byte block of two text records (the score with its x, y and
attribute, then the lives), so after a swap the current player's line --
always at $C9EC, where `add_score` writes -- carries the other position on
the screen. `new_game` tells whether the lines are the wrong way round by
the x of `p1_lives_text` ($A0 is player 2's) and swaps them back with
`player_in_play` set to $99, which stops `swap_players` short of changing
the player. `draw_panel` colours the line at $C9EC yellow and the other
red, so the current player's score is always yellow.

`check_high_score` ($F54D), at a game over: compares the six digit codes
of the current line with `hiscore_digits` ($CA16) from the left, and
copies them over if greater. The high score is kept as digit codes only.

## How this was found

Read from the code in the stage 2 description of the listing
(2026-10-16): the record's entries, `new_game`, `clear_player_record`,
`swap_players`, `lose_life`, `game_over`, `play`'s patch, `map_square_bit`,
`collect_pickup`, `deal_places` and `add_score`. Every reference to
$F5E7-$F6B8 was followed in the range-8 draft; the places' meaning comes
from putting `collect_pickup`'s marking (kind k at +29+4k, part p at
+73+4p) beside `load_map_window`'s kinds and the dealing list.

## Confidence

*Read* throughout. Two-player turns, `game_over` and `swap_players` ran in the
build's sessions, and since the staged launch `level_done` too; the rocket-part
and two-piece-part paths of `collect_pickup`, the setting of the beam makers'
bits and `contact_extra_life` did not. The add-ons' names (side jet, lift jet)
come from what the code draws for them; what add-ons 1-3 and 9 are in the game
is not known.

## Corrections

- Range 1's first pass left bit 6 of `map_object_kinds` unknown ("the
  other player's taken bit?"). It is player 2's gone bit (range 8, from
  `play`'s patch). The listing's own description of `map_object_kinds`
  still says bit 6 "is not read anywhere else that was found"; the BIT
  and SETs `play` patches are where it is read and set.
- Range 8 called +3 to +5 "24 flag bits, meaning unknown", and the
  listing's `player_flag_bits` entry says the same. `map_square_bit` and
  `draw_beams` show what they are: a beam maker destroyed, per page row
  and half of the map.
- Range 8 called +16 a count of unknown role; it marks the two-piece part
  being carried (set to 9 by `collect_pickup`, tested by `ship_contact`
  and `carried_part`).
- Range 2 listed +10 and +11 only as the flags that unlock attacker kinds
  6 and 7; they are add-ons 4 and 5, the side and lift jets.
- The ranges disagreed on $F601: it is the one rocket part being carried
  ($FF none), not a count; the count of parts delivered is $F602.
- **Coverage** (2026-10-17): this file said `level_done` never ran in the
  build's sessions; the staged launch runs it.

## Open questions

- What add-ons 1, 2, 3 and 9 are, and what the two-piece part (add-ons 10
  and 11, kinds 9 and $0A) is for: playing with each fitted would show it.
- Why a secured planet leaves `rocket_part_carried` and `parts_built` at 6
  ([`main-loop.md`](main-loop.md) reads it as "the next planet needs only
  the ore and the last part"); nobody has played past a planet.
- +17 is never referred to: padding, or a field dropped?
