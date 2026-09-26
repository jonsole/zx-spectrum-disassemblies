# Editing Knight Lore's rooms

The Knight Lore room editor is one HTML page. Open it in a browser and give
it a snapshot of your own copy of the game, a 48K `.sna` or `.z80` taken at the
menu. You can then rearrange the castle in the Filmation room designer and
**Download .sna**: Ultimate's own game, with your rooms in it. There is no
server and nothing to install, and nothing leaves the page.

Write the page once, from the checkout of
[zx-spectrum-emulator](https://github.com/jonsole/zx-spectrum-emulator) this
repository is a submodule of -- the designer lives there, in
`examples/filmation/vscode/`:

```
python scripts/knightlore_rooms.py page       # -> game_disassembly/knightlore/knightlore_room_editor.html
```

The page carries the designer and `knightlore_rooms.js`, which reads the
snapshot, paints the sprite sheet out of it, decodes the castle and packs it
back. It also carries the remake's `sprites.json` and `graphics.json`. Those
two are names, rectangles, boxes and pixel nudges, not bytes of the game.
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

It edits what the two editors edit:

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
other byte of the game here. `knightlore_rooms.js` follows the Python function
for function, and `node scripts/knightlore_rooms_test.js` holds the two to
agreeing (it needs the extracted castle, and skips without it).

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
- The templates editor in the page: raising the first piece of
  `scenery_arch_n` by 8 marked the castle unsaved; Undo took it back and
  cleared the mark, and Redo put it back. "$B3" in its list of rooms
  switched to that room, drawn with the arch raised. Download gave a `.sna`
  differing from the original in that piece's height alone ($6D15, $80 to
  $88), and the edit survived Save and a reload.
- `knightlore_rooms_test.js`: the JavaScript decodes the castle to exactly what
  `extract` writes, packs it back byte for byte, paints all 103 sprites pixel
  for pixel as `sprites.png` has them, and reads `.z80` files, compressed or
  not. The edit that was played in the emulator, packed by the JavaScript,
  matches the Python's output to the byte.

Not done: it writes a `.sna` only, not a tape; the VS Code editor for `rooms.json` is registered only for
`examples/filmation/*/`; and nothing stops you building a room the game cannot
reach or leave. Knight Lore's exits are arithmetic on the room number, and
the designer's map and checks show which doorways lead nowhere.
