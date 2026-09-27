# Food, health, dying and lives

**Question this answers:** how the life force (the roast on the scroll)
goes down and up, what kills the player, and how many lives there are.

**Short answer:** the life force is one byte, `FOOD_LEVEL` ($5E28), 240 at
the start of each life. It drains on its own (about three units a second in
the starting room), and faster from creatures (32 a touch), the big monsters
(8 a pass, the humpback 16), and mushrooms (1 a pass); food adds 64 up to
240, and eaten food slowly grows back elsewhere. At zero the player sinks
into the floor, leaves a gravestone and rises again in the same room. There
are four lives: the one in play and three shown on the scroll. One quirk: a
touch that lands the life force on exactly zero does not kill, and the next
drain wraps it to 255.

## How it works

**Drains** (*read*; *measured*):

| Cause | Where | Cost | Death check |
|---|---|---|---|
| time | `PLAYER_TICK` $8E78, each frame while TICKS AND 15 is 0 | 1 | `DEC A` / `JR Z`: death when it reaches 0 |
| a small creature's touch | `LOSE_FOOD_THIRTY_TWO` $8ED7 | 32 | at or below 0: the roast is drawn empty, then death |
| the mummy, Dracula, Frankenstein, the devil, per pass in contact | `LOSE_FOOD_EIGHT` $8A1E | 8 | only on a borrow |
| the humpback, per pass in contact | `LOSE_FOOD_SIXTEEN` $8A15 | 16 | only on a borrow |
| standing on a mushroom, per pass | `MUSHROOM_DRAIN` $98B1 | 1 | `JP Z`: when it reaches 0 |

The time drain's gate is counted in main-loop passes, and holds for every
frame of the pass on which it is true, so it takes one or two units per
sixteen passes. Standing in room $00 at the start, the knight lost about 31
units to time in 500 frames beside 160 to five creatures -- a full 240
lasts roughly 75-80 seconds with nothing else happening (*measured*).

**The zero wrap** (*read*, then *measured*). `LOSE_FOOD_EIGHT` and `LOSE_FOOD_SIXTEEN`
die only when the subtraction borrows; landing on exactly 0 stores 0 and the
player lives. If the next thing to happen is the time drain (or a mushroom),
`DEC A` turns 0 into 255, which is not zero, and stores it: a full roast and
more (the food cap is 240). Staged in the simulator: a devil's touch at 8
left 0; with the devil moved away, the drain at $8E88 took it to 255 and
counting down. Another touch before that drain would kill instead
(0 - 8 borrows). `LOSE_FOOD_THIRTY_TWO` does test for zero, so small creatures cannot
cause it.

**Food** (`EAT_FOOD` $8C63, *read*): eighty records, ten each of eight kinds
($50-$57), each in its room. Standing within 12 pixels: erased, its slot
emptied, sound $A0, +64 capped at 240 (the capping catches the carry too).
**Food grows back** (`REGROW_FOOD` $9924, *read*, then *measured*): once
every 512 passes a cursor steps to the next of the eighty food slots
(wrapping from $EDD8 to $EB58), and if that slot is empty and not in the
player's room, it is refilled with a random kind, $50 + FRAMES AND 7, in its
old place. Staged: an emptied slot in room $27 came back after the cursor
reached it. A whole round of the eighty takes 40960 passes, about half an
hour at 23 passes a second.

**Mushrooms** (`MUSHROOM` $988B, *read*): sixteen, sprite $A1. While the
player is within 12 pixels, one unit a pass and sound $64; when that reaches
zero, the mushroom is erased and removed, and the life is lost. Otherwise its
colour cycles red, magenta, yellow, magenta every fourth pass. There is no
in-play test, so a mushroom drains a rising or sinking player too.

**Dying** (*read*, then *measured*). `LOSE_LIFE` ($8EA0): with no lives left,
`GAME_OVER`; otherwise one fewer, the player's +$07 = the character's sprite,
+$06 = its height in rows, sprite $67. If it was the player's own handler that
found the zero, the player is put back where the frame started (from the
workspace). Then `DYING` ($8D45) lowers the figure one row on three frames in
four (on the fourth it only changes colour), and at the bottom
`DROP_GRAVESTONE` ($95A9) leaves a gravestone ($8F, cyan) in the first free of
four slots at the spot -- none if all four are used -- and `PLACE_PLAYER`
starts a new life in the same room ([`player.md`](player.md)): 104 frames
of the score flashing, then the rise, one row every four frames. Measured
for the knight (18 rows): sinking 25 frames, flashing 105, rising 72 -- about
four seconds from death to control. While sinking and rising, the small
creatures in the room are destroyed ([`monsters.md`](monsters.md)).

**Lives** (*read*; *measured*): `START_GAME` sets `LIVES` ($5E21) to 3 and
`DRAW_LIVES` shows that many figures. A death with `LIVES` at 0 is game over:
four lives in all. `GAME_OVER` ($8C35) blanks the play area, prints GAME OVER
and the summary ([`status-panel.md`](status-panel.md)), waits about ten
seconds and returns to the title. Staged with `LIVES` 0 and one unit of food,
`GAME_OVER` was reached and the title 9.8 seconds later.

## How this was found

Read every writer of $5E28 (searched as an operand) and the death chain.
Measured with the scratch harness: the drain and hits (`aticatac_t4.py`,
`t5.py`), dying and rising (`t6.py`), lives and game over (`t7.py`), the
regrowth (`t9.py`), and the zero wrap (`t18.py`, then `t19.py`, which stepped
the Python simulator and printed the PC of each change to $5E28).

## Confidence

Costs *read*; rates, timings, regrowth and the wrap *measured*. The wrap was
staged by setting 8 and placing the devil; how often it happens in play
depends on the life force being a multiple of 8 when a big monster touches,
which is common (240, 64 and 8 are all multiples of 8) but was not counted.

## Renamed routines

Applied to the annotations on 2026-09-27; the build verified byte for byte.

| New name | Old name | Address | Role |
|---|---|---|---|
| `REGROW_FOOD` | `ADVANCE_CURSOR` | $9924 | refills an eaten food slot |
| `REGROW_CURSOR` (equate) | `CURSOR` | $5E55 | its place |
| `LOSE_FOOD_EIGHT` | `LOSE_FOOD_8` | $8A1E | the big four's touch |
| `LOSE_FOOD_SIXTEEN` | `LOSE_FOOD_16` | $8A15 | the humpback's |
| `LOSE_FOOD_THIRTY_TWO` | `LOSE_FOOD_32` | $8ED7 | a small creature's |
| `DROP_GRAVESTONE` | `DROP_OBJECT` | $95A9 | the gravestone |
| `SOUND_RISE_SINK` | `SOUND_FROM_HEADING` | $A45F | the note of sinking and rising |

## Disassembly corrections

All applied to the annotations, the ref and the build on 2026-09-27 (the old names are used below), except where marked.

- `DYING`: "Every fourth frame it counts +$06 down" and "One step in four
  frames". It steps down on three frames in four (`AND $03` / `JR Z` to the
  colour-only path); measured, 19 steps in 25 frames.
- `EAT_FOOD`: "eaten food does not come back". It does, through
  `ADVANCE_CURSOR` -- whose description ("Step a cursor on by one record ...
  creeps through a table") misses that it refills food.
- `LOSE_LIFE` at $8EC6: "A non-player dies where the workspace says it was,
  not where the player is". The branch is the other way round: when the
  handler that found the zero is the player's own (sprite $01-$30), the
  player's position is restored from the workspace; otherwise it is left.
- `MUSHROOM`'s "four attribute bytes at MUSHROOM_COLOURS": right; but
  `DRIFT_OFFSETS` is not the mushroom's ([`doors.md`](doors.md)).
- `INITIAL_STATE` and the Data page: eight kinds of food, not six
  ([`records.md`](records.md)).
- `MATERIALISING`: "A bonus flashing on the scroll takes priority over
  rising" -- the flash is the start of every life (`PLACE_PLAYER` sets
  `FLASH_COUNT` $5E3C to 104), not a bonus.

## Open questions

- The zero wrap is a bug by any reading; a poke to test would make
  `LOSE_FOOD_EIGHT`'s `JR C` a `JR Z`-and-`JR C` pair, which needs more bytes than
  are there. Not tried.
- Whether the gravestones (at most four) ever block or matter: their handler
  only draws them.
