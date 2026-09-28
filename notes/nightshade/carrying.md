# Carrying

**Question this answers:** what the knight carries, in what order he
throws it, and how the panel shows it.

**Short answer:** eleven places (`CARRIED`, $BC03), filled in the order
things are taken up: objects as things 1-4, antibodies as 5-8. Fire throws
the last thing taken up. The panel shows each place as an icon in a column
at the left, coloured every turn -- and an object's icon flashes when its
villain is within four cells: the game's only hint where a villain is.

## How it works

- **Taking up** (`PICK_UP_THING`, $C489, from `OBJECT_LYING` and
  `FIND_WANDER`): the first empty place of the eleven; an object as graphic
  - 3, a find via `PICK_UP_FIND` ($C481) as 5 + bits 2-3 of its graphic.
  Full: nothing taken (an object stays; a find is lost,
  [`finds-and-bonuses.md`](finds-and-bonuses.md)).
- **Throwing** takes from `CARRIED_LAST` ($BC0D) backwards: the last thing
  taken up goes first ([`knight.md`](knight.md)). Its place is emptied, so
  the places are a stack with holes: the next thing taken up fills the
  lowest hole.
- **The icons** (`DRAW_CARRIED`, $C4A4): four characters of `ICONS`
  ($7571: nine icons of four characters, the first blank for an empty
  place), place *k* at 16 pixels in and 16*k* up from the bottom, inside
  the panel's frame (`DRAW_PANEL_FRAME`, [`menu-and-panel.md`](menu-and-panel.md)).
- **The colours** (`COLOUR_CARRIED`, $C4DC, every turn): each icon two by
  two cells from `THING_COLOURS` ($C52F) up to the first empty place --
  objects red, magenta, green, cyan (things 1-4), antibodies magenta,
  green, cyan, yellow (5-8). The panel's destroyed villains use the same
  bytes, so an object and its villain share a colour. An object whose
  villain (record 4 - thing) is less than five cells from the knight in
  column and row cycles through the antibody colours instead.

## How this was found

Read (stage 2, range 1); the colour pairing checked against
`DRAW_VILLAINS`' index. The build's "finds and antibodies" session filled
all eleven places.

## Confidence

*Read*.

## Filmation (Knight Lore, Alien 8, Pentagram)

The earlier games carry a few things, shown on the panel as sprites; the column of eleven character icons, last-in first-out, and the
flashing hint are Nightshade's own.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `PICK_UP_THING`, `DRAW_CARRIED` | `SUBC489` | $C489, $C4A4 | take a thing up; its icon |
| `PICK_UP_FIND` | `SUBC481` | $C481 | a find's antibody kind |
| `COLOUR_CARRIED` | `SUBC4DC` | $C4DC | colour the icons |
| `THING_COLOURS` | `SPACEC52F`, `TEXTC530` | $C52F | the colours |

## Disassembly corrections

- Stage 1's memory map called `ICONS` "36 characters: the carried things,
  four each (things 1-8)": the first four are the blank icon of an empty
  place, so nine icons, things 0-8.
- `THING_COLOURS` was two sna2ctl blocks, a byte of "space" and text.

## Open questions

- None.
