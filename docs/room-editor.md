# The room editor: Knight Lore, Pentagram and Alien 8

The room editor is one HTML page. Open it in a browser and give it a snapshot
of your own copy of Knight Lore, Pentagram or Alien 8, a 48K `.sna` or `.z80`
taken at the menu; it tells which game it is. You can then rearrange the
castle in the Filmation room designer and **Download .sna**: Ultimate's own
game, with your rooms in it. There is no server and nothing to install, and
nothing leaves the page. Most of what follows is the same for every game,
told for Knight Lore; [Pentagram](#pentagram) and [Alien 8](#alien-8) say
where they differ. How to use it is
[room-editor-guide.md](room-editor-guide.md), which the page shows as its
**Help**; this is how it works.

Write the page once, from the checkout of
[zx-spectrum-emulator](https://github.com/jonsole/zx-spectrum-emulator) this
repository is a submodule of -- the designer lives there, in
`examples/filmation/vscode/`:

```
python scripts/room_editor.py page       # -> game_disassembly/room-editor.html
```

The guide goes in as HTML, made from the Markdown by a small converter in
`room_editor.py` -- headings, paragraphs, bullets, tables, and bold, italic,
code and links -- so the guide and the page's Help are one text. Keep the
guide to those.

The page carries the designer and `room_editor.js`, which tells the games
apart, reads the snapshot, paints the sprite sheet out of it, decodes the
castle and packs it back -- a profile a game, holding where its tables are,
what names them and what a room's record holds. It also carries each game's
`sprites.json` and `graphics.json`: Knight Lore's and Pentagram's from their
Filmation remakes, Alien 8's from `room_editor_art.py` (see
[Alien 8](#alien-8)). Those are names, rectangles, boxes and pixel nudges, not
bytes of the game.
Every pixel and every room comes from the copy you give it, so the page itself
holds nothing of Ultimate's and could be shared or published as it is.

**Using it.**

| | |
|---|---|
| **Rooms** / **Templates** | The two editors, the room designer and the templates editor, as in VS Code. A room number in the templates editor goes to that room. |
| **Undo** / **Redo** | One history for both editors, in the order you made the changes, whichever editor they were in; ctrl+Z and ctrl+shift+Z work in either. |
| **Save** (ctrl+S) | Keeps the whole castle -- rooms, templates and collectables -- in this browser. Next time, the page offers to continue where you left off. |
| **Download .sna** | Packs the castle into the original's tables and downloads the game. It reports the bytes used and free, or says what the original cannot hold and downloads nothing. |
| **Export** / **Import** | Writes the castle to a `.json` file, and reads one back into an open copy. A file exported before templates could be edited has none, and keeps the templates that are open. |

Give it the **original** snapshot every time. A copy it has already changed
can only be reopened if the template tables did not move. If they did, it is
refused: open the original and Import the castle instead.

It edits what the two editors edit -- and the floor shapes, on the designer's
Shapes tab:

- **Rooms:** their scenery and objects, colour and shape, and the
  collectables. You can add a room (click an empty square on the map) or
  delete one.
- **Templates:** what a `block` or an `arch_n` is made of, piece by piece,
  and every room that uses one follows it. A piece costs 8 bytes in a
  scenery template and 6 in an object template, out of the same budget as
  the rooms.

The four rooms a game can start in, from `start_locations` at $D1E2, are
listed under the map to jump to. You can put another room in place of one of
them, but only one with the middle of its floor clear, because Sabreman starts
there whichever room it is. Download refuses a starting room with anything in
the way, and a starting room cannot be deleted. The number of them stays four;
that is two bits of a random number in the game's code.

**From Python instead.** `knightlore_rooms.py` does the same through the
designer's local server, working on JSON files rather than the browser:

```
python scripts/build_knightlore.py --snapshot "Knight Lore.sna"   # once, if you have not
python scripts/knightlore_rooms.py extract
python scripts/knightlore_rooms.py design
python scripts/knightlore_rooms.py build
```

| Command | What it does |
|---|---|
| `extract` | Reads `game_disassembly/knightlore/knightlore.sna` (or `--snapshot FILE`, any format SkoolKit reads) and writes the castle into `game_disassembly/knightlore/rooms/`: `rooms.json`, `templates.json`, `specials.json` and the artwork the designer draws with. It keeps a copy of the snapshot as `original.sna`, which every build starts from. Then it packs the JSON straight back and requires the result to be the game's own tables, byte for byte, before anything is edited. It will not overwrite a castle that is already there without `--force`. |
| `design` | Opens the room designer on that castle in a browser (`--port`, `--no-browser`). Save writes the JSON; **Build rooms** runs `build`. |
| `build` | Packs the castle into the original's tables and writes `game_disassembly/knightlore/rooms/knightlore_rooms.sna`. |

All of that is under `game_disassembly/`, which is gitignored, like every
other byte of the game here. `room_editor.js` follows the Python function
for function, and `node scripts/room_editor_test.js` holds the two to
agreeing (it needs the extracted castle, and skips without it). The Python
route is Knight Lore's only; Pentagram is edited in the page.

The castle is the same one the remake in `examples/filmation/knightlore`
carries, with the same names, and it is edited the same way; see
`examples/filmation/room-designer.md` there. What differs is where it goes:
into Ultimate's code, which has limits the remake's engine does not.

## What the original can hold

**3,498 bytes, and not one spare.** The room sizes, the rooms, and the two
template tables fill $6248-$6FF1 exactly, and the rest of memory is taken
too. So anything that adds bytes has to be paid for by something that takes
bytes away. `build` says how many bytes each part takes and how many are free,
and refuses a castle that does not fit.

Whatever you save can be spent anywhere. Only three instructions name the
template tables -- `LD BC,block_type_tbl` at $D3C9, `LD HL,block_type_tbl` at
$D461 and `LD BC,background_type_tbl` at $D42A -- so `build` moves the tables
and patches the three operands to follow. Rooms and templates therefore share
one budget, not three fixed ones. A duplicated template whose pieces are
unchanged costs only its two-byte pointer, because identical templates share
one body.

What each thing costs:

| | Bytes |
|---|---|
| a room | 3, plus 1 per scenery template it places |
| its objects | 1 for the `$FF` before them (only when there are any), then 1 per group and 1 per position |
| an object template | 2 for its pointer, 6 per piece, 1 to end it |
| a scenery template | 2 for its pointer, 8 per piece, 1 to end it |

**Up to 32 floor shapes.** `room_size_tbl` at $6248 holds each shape's X
and Y half-sizes and floor height, and `found_screen` copies a room's into
$5BAB, $5BAC and $5BAE: the walls you cannot walk through, where you come in
and how far through an arch takes you out all read them. A room names its
shape in bits 3 to 7 of its attribute byte, so the game can have 32; it has
three. The table runs up to the rooms, which only `LD HL,location_tbl` at
$D3CC names, so a castle with more shapes moves the rooms down by three bytes
a shape and patches that operand ($D3CD). A shape changes where a room is
bounded, not the walls and arches drawn round it -- those are scenery -- and
the designer warns about each room whose walls no longer sit on its floor's
edge. A half-size is 1 to 127, so the walls stay inside a byte either side of
$80.

**36 object records per room.** A room is expanded into 32-byte records from
$5C88 up to the font at $6108. The code then clears records until it reaches
the font exactly, so a 37th record would not stop at the font: it would run on
through the room tables. The castle says so in `meta.rules.poolLimit`, so the
designer marks a room over the limit as a fault while you edit, and the header
shows `pool N of 36`. Room $F0 as shipped uses all 36.

The other limits come from the record format, and `build` checks each one: 32
object templates and 8 positions a group (the group byte), 255 bytes a room
(the skip byte), fewer than 255 scenery templates ($FF ends the list), and no
empty room. The room walk counts a room's body down with its skip byte, so a
room with nothing in it would be read from the next room's record.

**The collectables** in `specials.json` go back too: where each of the 32
starts, into bytes 1-4 of its row in `special_objs_tbl`, and the wizard's
list into `objects_required` -- as the file has it, since the page does not
edit it. The rest of each row stays the original's.

## What was checked

- Extracting from the disassembly's snapshot gives files identical to the
  remake's carried `templates.json`, `graphics.json`, `sprites.json`,
  `sprites.png` and `specials.json`. `rooms.json` differs only in its `meta`.
  The castle packs back into the original's 3,498 bytes exactly.
- An edited castle -- one room's objects removed, blocks added elsewhere, a
  duplicated template added -- packs, and decoding the patched game with the
  remake's own `rooms.py`, pointed at the moved tables, gives back exactly the
  edited castle.
- In the emulator, a castle whose four start rooms ($2F, $44, $B3, $8F) were
  recoloured and given a row of objects from a new, 30th template started a
  game in room $B3 drawn with those changes and the template tables moved.
  That covered the moved `block_type_tbl`, at $6BBA, and the moved
  `background_type_tbl`.

- The page, driven in headless Chrome: opening the disassembly's snapshot drew
  the castle; recolouring room $B3 in the designer, then Save, then Download,
  gave a `.sna` differing from the original in that one byte ($692B). Reloading
  offered the castle back with the change. A room pushed to 37 records was
  refused on Download with the reason, and nothing was downloaded.
- A fourth shape, 48 by 48, with room $B3 on it: both packers give the same
  bytes, the rooms start at $6254 and the operand says so, and the game, made
  to start in $B3, built it with half-sizes of 48 and its floor at 128 -- the
  walls still drawn where the square room's are, which is what the designer's
  warning is for.
- The templates editor in the page: raising the first piece of
  `scenery_arch_n` by 8 marked the castle unsaved; Undo took it back and
  cleared the mark, and Redo put it back. "$B3" in its list of rooms
  switched to that room, drawn with the arch raised. Download gave a `.sna`
  differing from the original in that piece's height alone ($6D15, $80 to
  $88), and the edit survived Save and a reload.
- `room_editor_test.js`: the JavaScript decodes the castle to exactly what
  `extract` writes, packs it back byte for byte, paints all 103 sprites pixel
  for pixel as `sprites.png` has them, and reads `.z80` files, compressed or
  not. The edit that was played in the emulator, packed by the JavaScript,
  matches the Python's output to the byte.

Not done: it writes a `.sna` only, not a tape; the VS Code editor for `rooms.json` is registered only for
`examples/filmation/*/`; and nothing stops you building a room the game cannot
reach or leave. Knight Lore's exits are arithmetic on the room number, and
the designer's map and checks show which doorways lead nowhere.

## Pentagram

Pentagram keeps its world the way Knight Lore keeps its castle, and the page
edits it the same way; `room_editor.js`'s profile for it is taken from the
disassembly's `BUILD_ROOM` ($C92C) and
[`notes/pentagram/room-building.md`](../notes/pentagram/room-building.md).
Where it differs:

- **The tables** are at $5E07-$6DD6: `ROOM_SIZES`, the rooms (`ROOMS`), the
  scenery table and its templates, then the object table and its templates
  -- 4,048 bytes, full, with the graphic table straight after. The operands
  naming them are `LD HL,ROOMS` ($C940), `LD BC,SCENERY_TABLE` twice ($C93D,
  $C98E) and `LD HL,OBJECT_TABLE` ($C930); a build moves the tables and
  patches all four, as it does Knight Lore's.
- **A doorway carries the room it leads to**, a byte after the template in
  the room's record, edited under Ways out. The walk that finds a room has no
  end check: a room that is not there sends it on through the rest of memory.
  So Download refuses a doorway to a room that is not there -- and a starting
  room that is not there.
- **48 object records a room**, filled from the top down; the quest things
  go in from the bottom up and give up if none is free, but the builder does
  not stop, and one more record runs down over the bolts and the player's own.
  The fullest room, $57, has 43.
- **Object templates are five bytes**, with no placement nudge, and a group's
  template 31 is the switch to a second page of templates, so there are 31 at
  most. The flags' passable bit is not known, and a piece marked passable is
  refused.
- **Four scenery slots are unused** -- 18, 19, 22 and 23 point at the scenery
  table itself -- and the page shows them as templates with no pieces. A
  build points an empty one at the table again, and refuses a room that
  places one.
- **The starting rooms** are `START_ROOMS` at $C2E8, four picked from by
  `RANDOM`, with the player put in the middle of the floor as in Knight Lore.
- **No collectables tab**: Pentagram's quest things are placed by its own
  code, from tables the page does not edit.
- **The sprites** are in four runs, and the game turns them upside down as
  well as left to right as it draws them; the page turns both back before it
  paints the sheet. Three sprites no graphic draws are left blank.

Two bytes of the castle as shipped do not come back: rooms 13 and 108 end
partway through their last group, whose header asks for three objects where
the record holds two. The game builds the two, and so does the castle; a
header written from it asks for two. An unedited castle downloads with those
two bytes different ($5F67 and $66D3) and nothing else.

**Checked.** Against `game_disassembly/pentagram/pentagram.z80` from
`build_pentagram.py`, in `room_editor_test.js`: the snapshot is told apart
from Knight Lore's; decoding gives the remake's castle
(`examples/filmation/pentagram`) room for room and template for template, but
for the four unused slots; the castle packs back but for the two headers; the
sheet painted from the snapshot is the remake's `sprites.png`, sprite for
sprite; an edited castle -- a fourth shape, a starting room changed, an
object template's box -- packs with its tables moved and decodes back as
edited; and a doorway to a missing room, a 49th record, an unused slot placed
and a nudge are each refused, saying why. In the page, the snapshot opened as
Pentagram's, and a recoloured room downloaded with three bytes different: its
ink and the two headers. In the emulator, a castle with room 100 on a new 48
by 48 shape, recoloured and made every starting slot, started a game in room
100 with half-sizes of 48 and red ink, the rooms moved to $5E13.

## Alien 8

Alien 8 keeps its starship the way Knight Lore keeps its castle -- the same 16
by 16 grid, the exits worked out from the room number, the collectables'
table -- with Pentagram's room builder and three things of its own. Its
profile is the disassembly's `BUILD_ROOM` ($CCA7) and
[`notes/alien8/room-building.md`](../notes/alien8/room-building.md).

- **The tables** are at $6460-$76E2: `ROOM_SIZES`, the rooms, the object
  table and its templates, then the background table and its -- 4,739 bytes,
  full, with `PLACES`, where the valves can lie, straight after. Three
  routines walk the rooms -- `BUILD_ROOM`, `RESET_ROOM_COLOURS` and
  `SUMMARISE_CHAMBERS` -- so the operands a build patches are seven: the rooms'
  at $CCBB, $CAD3 and $AC74, the object table's at $CCA8, $CCB8, $CAD6 and
  $AC81 (the walks stop at it), and the background table's at $CD19.
- **Two pages of object templates.** A group's header names a template in
  five bits, and 0 and 31 are not templates: 0 sets the placement nudge for
  the groups after it (the byte after it is the nudge), and 31 moves on to a
  second page (the byte after it is skipped). The table holds 32 words for the
  first page and as many as the second uses; slots 0 and 31 of each are zero.
  In the castle the templates are named by their slot -- `object_01` to
  `object_30`, then `object_33` on -- and a build puts them back in the order
  the file has them, thirty a page, 60 at most. A room's groups are written
  in page order, each page begun with a switch.
- **A group's nudge.** The rooms use the nudge 42 times, 41 of them $30,
  raising the objects after the header by 48. The castle keeps it on each
  group it applies to, as `nudge`, and the designer draws it and offers it
  as the group's **raise**; a build writes a header wherever the next group's
  nudge differs from the one in force.
- **The ink** is in bits 3-5 of a room's attribute byte, and its size in bits
  6-7, so four shapes at most. Bits 0-2 are zero on the tape:
  `RESET_ROOM_COLOURS` copies 3-5 into them at every new game, because an
  activated chamber turns its room white.
- **52 object records a room**; the loop that clears the rest stops only at
  their end exactly, so a 53rd would never let it stop. The fullest room,
  $74, has 49.
- **The starting rooms** are `START_ROOMS` at $CA9E, and the robot starts on
  a floor at 64, in a box 7 either way and 23 high -- the castle says so in
  its rules (`startSpot`), with the projection's origin (`yOrigin`, 232: the
  game subtracts 40 where Knight Lore subtracts 104, its floors 64 lower).
- **The valves** lie in `PLACES`, 36 nine-byte rows with the place in bytes
  1-4, as Knight Lore's collectables do; the Collectables tab edits them.
  There is no wizard's list.
- **The sprites and graphic table** come from `room_editor_art.py`, since
  Alien 8 has no remake: the layout is each sprite's own rectangle, and each
  graphic's pixel nudge is harvested by running its update routine in
  SkoolKit's simulator, facing each way, until it reaches `SET_PIXEL_ADJ`
  ($BF77). They agree with the table in
  [`notes/alien8/graphic-numbers.md`](../notes/alien8/graphic-numbers.md).
  Its box is the commonest the templates give it.

Every byte comes back: the castle as shipped downloads unchanged.

Not done: `SUMMARISE_CHAMBERS` counts a room as a chamber by its first groups
being object templates 21 and 22, the frozen crew, by slot. Deleting a
template before them in the templates editor renumbers them, and the summary
after a game would count wrongly; nothing warns of it.

**Checked.** Against `game_disassembly/alien8/alien8.z80` from
`build_alien8.py`, in `room_editor_test.js`: the snapshot is told apart from
the other two; the castle decodes to what the notes count -- 128 rooms, 14
backgrounds and 37 object templates on two pages, the inks 3 to 6 in 32, 28,
34 and 34 rooms, 36 valve places -- and packs back byte for byte; every
sprite the graphic table reaches is painted; an edited castle -- a
second-page template with a raise and a first-page one after it, a fourth
shape, a valve moved -- packs with its tables moved and the groups in page
order, and decodes back as edited; a fifth shape and a 53rd record are
refused. In the page, room $12 is drawn as the disassembly's own picture of
it, drawn by the game's code, has it. In the emulator, a castle with room $4E
on a new 48 by 48 shape, red, a raised second-page object in it, and every
starting slot, started a game in $4E with half-sizes of 48, its floor at 64
and its ink 2 -- which `RESET_ROOM_COLOURS`, walking the moved rooms, copied
into place.
