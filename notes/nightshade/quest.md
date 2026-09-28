# The quest: objects and villains

**Question this answers:** how the four objects and four villains are
placed, how an object destroys its villain, what a villain does meanwhile,
and what ends the game with the quest done.

**Short answer:** at a new game each object and villain is put in a random
standable cell, read from the ROM at a random address. An object lying in
the street is taken up at a touch; thrown, it flies until a wall (where it
lies down again) or its own villain -- the one 64 bytes on, record *n* to
record *n* -- which dies in a flash of colour, for 250000 points, letting
out four sparkles. Villains wander, never chase, and kill the knight at a
touch. When no villain record is in use and no sparkle is on the screen,
the ending plays.

## How it works

- **Placing** (`PLACE_VILLAINS` $D8E7, then `PLACE_OBJECTS` $D88E, at
  `NEW_GAME`): each advances the turn count and stirs the random number,
  then reads byte pairs from the ROM from `RANDOM` AND $0FFF as a column and
  a row (each masked to 0-31), skipping solid cells. Each record is a copy
  of `OBJECT_RECORD` ($D8D7: the cell's middle, half-size 8) or
  `VILLAIN_RECORD` ($D932: speed 4, facing +V, half-size 16, flags 0), then
  its graphic -- objects 7, 6, 5, 4 and villains 108, 104, 100, 96 for
  records 0-3 -- and cell. Nothing keeps two apart, or a villain out of the
  knight's first cell (he then dies there as he appears, as often as he
  comes back).
- **The pairs** (by record; the pictures as the build draws them):

| Record | Object (lying, thrown) | Thing | Villain | Panel column |
|---|---|---|---|---|
| 0 | 7, 11: a hammer | 4 | 108-111: a skeleton | 15 |
| 1 | 6, 10: an hourglass | 3 | 104-107: a figure with a scythe | 18 |
| 2 | 5, 9: a cross-shaped object | 2 | 100-103: a hooded figure | 21 |
| 3 | 4, 8: a book | 1 | 96-99: a white figure | 24 |

  The game's text names none of them; the names are descriptions, and
  whether they match the inlay's is one of the things stage 3 is checking.
- **Lying** (`OBJECT_LYING` $D942, 4-7): touched, sound effect 3 for four
  turns and `PICK_UP_THING` takes it up as thing graphic - 3; with all
  eleven places full it stays.
- **Thrown** (`OBJECT_FLIGHT` $D80C, 8-11; from `KNIGHT_THROWS`): speed 12,
  half-size 16, twice a turn. `OBJECT_STRIKE` ($C554) tests it against the
  record 64 bytes on only. At a wall its low bits are kept and 4 set: the
  same object, lying. A strike: the villain becomes 132 (dying), the object
  12 (vanishing), 250000 points, `VILLAIN_SPARKLES` ($D6D6) turns the four
  `FINDS` records into sparkles at the villain's place (anything found and
  lying there is lost), and `DRAW_VILLAINS` redraws the panel, the dead
  villain now in its object's colour ([`menu-and-panel.md`](menu-and-panel.md)).
- **A villain** (`VILLAIN_WANDER` $D94F, 96-111): walks at speed 4, turns at
  random at walls and now and then (`STEER`; never towards the knight, since
  it never has flags bit 5 -- [`movement.md`](movement.md)), takes its
  picture from its facing (`FACING_PICTURE`), and hums while on the screen
  -- from the wrong table ([`sound.md`](sound.md)). A touch ends the
  knight's life through `KNIGHT_KILLED` ($CEC4), whatever his hits, and
  keeps his cell for the next life: a villain parked there kills him again
  as each life arrives.
- **Dying** (`VILLAIN_DYING` $D847, 132-135, drawn with the cloud's
  pictures): `FLASH` = (`TURNS` AND 7) x 8 each turn, the play area's paper
  cycling through the colours; a frame every other turn; empty after eight
  turns. `FLASH` is cleared at the end of every turn, so the flashing lasts
  exactly as long as the dying.
- **Sparkles** (`SPARKLE_FLY` $D70A, 140-143, drawn with the finds' first
  frames): each flies one way at speed 12 until a wall, then vanishes.
- **The end** (`CHECK_QUEST_DONE` $D865, every turn): no villain record in
  use (a dying one counts) and no sparkle drawn this turn (bit 1 of +7, set
  by the drawing, cleared by `SPARKLE_FLY` each turn) -> `GAME_OVER`
  ($CC56), which finds no live villain and plays the ending
  ([`game-over-and-ending.md`](game-over-and-ending.md)). A sparkle flying
  off the screen is not waited for.
- **The hint.** While an object is carried, its icon on the panel flashes
  when its villain is less than five cells away ([`carrying.md`](carrying.md)).

## How this was found

Read (stage 1 for the pairs, from `PLACE_OBJECTS`, `PLACE_VILLAINS`,
`DRAW_VILLAINS` and `OBJECT_STRIKE`; stage 2, range 4, for the rest).
*Measured* by the build's quest session: each object laid by the knight,
taken up, thrown once at nothing (it lies down again), taken up and thrown
at its villain placed four steps ahead; the villains destroyed in turn, the
ending, and back to the menu.

## Confidence

*Read* and *measured* (the pairs, the strike, the ending). The score for a
villain: 250000 as printed (`ADD_SCORE` adds $25 to the score's middle
byte; range 1 *measured* that $2500 prints as 0250000).

## Filmation (Knight Lore, Alien 8, Pentagram)

No counterpart: Knight Lore's cauldron and Alien 8's chambers are
place-based quests of carrying things somewhere; Nightshade's is thrown at
moving targets, the pairing given by record order. Random placement from
ROM bytes is new too; Knight Lore picks its objects' rooms from a table.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `PLACE_OBJECTS`, `PLACE_VILLAINS` | `SUBD88E`, `SUBD8E7` | | new game |
| `OBJECT_LYING`, `OBJECT_FLIGHT` | `SUBD942`, `SUBD80C` | | 4-7, 8-11 |
| `VILLAIN_WANDER`, `VILLAIN_DYING` | `SUBD94F`, `SUBD847` | | 96-111, 132-135 |
| `VILLAIN_SPARKLES`, `SPARKLE_FLY` | `SUBD6D6`, `SUBD70A` | | the sparkles |
| `CHECK_QUEST_DONE` | `SUBD865` | $D865 | end the game when the villains are gone |
| `OBJECT_STRIKE` | `SUBC554` | $C554 | a thrown object and its villain |

## Disassembly corrections

- `OBJECT_FLIGHT`'s description and its comment at $D83B say a strike
  scores "2500"; the `LD BC,$2500` puts $25 in the score's middle byte,
  which prints as 250000, as `ADD_SCORE`'s own description says. Reported
  to the lead.

## Open questions

- **The villains' and objects' names** -- stage 3 is checking them against
  the inlay and the pages' drawings; the table above describes pictures.
- Whether a find lying in the street really vanishes when a villain dies
  (stage a find and a strike in the same turn).
