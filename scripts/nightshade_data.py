"""Nightshade's level data and graphics, laid out a record per line from the game.

The town map, the order the town is drawn in, the buildings, the boxes that
stop the knight walking through walls, the tiles buildings are drawn from,
the graphic table, the sprites, the fonts, the tunes and the game's own text
are the game's design. Described record by record they are that design again
in other words, so -- like Alien 8's in alien8_data.py -- they are not
written into a committed file: build_nightshade.py calls data_blocks() on the
snapshot at every build, and puts what it returns into the control file in
place of what sna2ctl guessed for the same bytes. What each table *is* -- its
label, its description, its format -- is prose, and stays in
scripts/nightshade_annotations.ctl, which is laid over the top.

Every layout below is the one the game's own code reads (the routines are
named in the comments), and each walk checks itself: a table that does not
tile its range, or a pointer into the middle of a record, stops the build
rather than quietly describing something else.

The snapshot is taken at $5E00, before the game has run: the game turns
sprites round in place (#R$E353), so what is described here is the tape's
image of them.
"""
from __future__ import annotations

NEWLINE = "\n"

# Each address is where the code named beside it reads the table.
MAP = 0x5E04                # 32 rows of 32 cells (#R$D564, #R$E051)
MAP_SIZE = 32
DRAW_ORDER = 0x6204         # 32 records of 5 steps, by which neighbours are built on (#R$CF08)
DRAW_ORDER_COUNT = 32
BUILDINGS = 0x62A4          # 72 words: cell type * 2 + the view (#R$D372, #R$D19D)
CELL_TYPES = 36
BOX_TABLE = 0x6334          # 36 words: cell type -> its boxes (#R$E063, #R$E0A0)
BOXES = 0x637C              # the box lists, 4 bytes a box, each list ended by a zero
TILE_EDGES = 0x6542         # a byte per tile: which edge picture goes under it (#R$D273)
TILE_COUNT = 52
BUILDING_DEFS = 0x6576      # 32 bytes each: two faces of eight columns of two tiles
BUILDING_SIZE = 32
PANEL_CHARS = 0x6CB6        # 5 characters: the panel's frame (#R$C83F)
PANEL_CHAR_COUNT = 5
FONT = 0x6CDE               # 43 characters, codes $30-$5A (#R$C9FC, from the base $6B5E)
FONT_CHARS = 43
FONT_FIRST = 0x30
TILE_TABLE = 0x6E36         # 52 words: tile number -> tile (#R$D425)
GRAPHICS = 0x6E9E           # 158 words: graphic number -> sprite (#R$E353)
GRAPHIC_COUNT = 158
EMPTY_SPRITE = 0x6FDA       # graphics 0 and 1: no width, no height
EDGE_TABLE = 0x6FDC         # 4 words: the edge pictures (#R$D273)
EDGE_COUNT = 4
EDGES = 0x6FE4              # the edge pictures, in the tiles' format
SPRITES_1 = 0x7017
ICONS = 0x7571              # 36 characters: the carried things, four to a picture (#R$C489)
ICON_CHARS = 36
SPRITES_2 = 0x7691
PANEL_ICONS = 0x7A6F        # 24 characters: the compass, the two headings, the lives (#R$C2C8)
PANEL_ICON_CHARS = 24
SPRITES_3 = 0x7B2F
TILES = 0xA257              # the tiles, end to end
BORDER_CHARS = 0xBB0A       # 20 characters: the menu's and the panel's border (#R$CA55)
BORDER_CHAR_COUNT = 20
VARIABLES = 0xBBAA

# In the code: the tunes and their note table (#R$C656), the game's text,
# the update table and the records the game copies from.
NOTES = 0xC6B9              # 61 notes of 3 bytes: two loop counts and a length (#R$C661)
NOTE_COUNT = 61
TUNES = [(0xC770, "the menu's tune", "TUNE_MENU"),
         (0xC7F4, "a control method chosen", "TUNE_CONTROL_CHOSEN"),
         (0xC7F8, "a game starting", "TUNE_GAME_START"),
         (0xC803, "game over", "TUNE_GAME_OVER"),
         (0xC81A, "the end of the ending", "TUNE_ENDING"),
         (0xC839, "a new life", "TUNE_NEW_LIFE")]
TUNES_END = 0xC83F
SCORE_TEXT = 0xC2E7         # the panel's heading (#R$BE15 prints it)
MENU_COLOURS = 0xC962       # 8 attributes, then 8 screen positions, then 8 strings (#R$CA2B)
MENU_ITEMS = 8
MENU_END = 0xC9EF
START_RECORDS = 0xCC36      # the knight's two records at a new life (#R$CBAC)
ENDING_RECORDS = 0xCCE4     # the ending's ten records: graphic and screen x and y (#R$CC56)
ENDING_COUNT = 10
END_TEXT = 0xCDAF           # game over, the percentage and the score (#R$CC56)
END_TEXT_END = 0xCDDF
MONSTER_RECORD = 0xCE79     # what a monster starts as (#R$CDE8)
OBJECT_RECORD = 0xD8D7      # what each of the four objects starts as (#R$D88E)
VILLAIN_RECORD = 0xD932     # what each of the four villains starts as (#R$D8E7)
UPDATES = 0xD599            # 158 words: graphic number -> update routine (#R$BE15)

INKS = ["black", "blue", "red", "magenta", "green", "cyan", "yellow", "white"]


def _word(memory, address: int) -> int:
    return memory[address] | memory[address + 1] << 8


def _plural(count: int, word: str) -> str:
    return f"{count} {word}{'' if count == 1 else 's'}"


def _numbers(values: list[int]) -> str:
    """1, 2, 3, 5 as '1-3, 5'."""
    runs, start = [], None
    for index, value in enumerate(values):
        if start is None:
            start = value
        if index + 1 == len(values) or values[index + 1] != value + 1:
            runs.append(str(start) if start == value else f"{start}-{value}")
            start = None
    return ", ".join(runs)


def sprite_picture_name(address: int) -> str:
    """By address, so this file can name a picture before there is a listing
    to take a label from; build_nightshade.py draws it under that name."""
    return f"sprite{address:04x}.png"


def tile_picture_name(address: int) -> str:
    return f"tile{address:04x}.png"


# --------------------------------------------------------------------------
# The town.
# --------------------------------------------------------------------------

def cell(memory, u: int, v: int) -> int:
    """The type of the cell at column U, row V (#R$D564 in the usual view)."""
    return memory[MAP + MAP_SIZE * v + u]


def _map_lines(memory) -> list[str]:
    out = []
    for v in range(MAP_SIZE):
        row = [cell(memory, u, v) for u in range(MAP_SIZE)]
        open_cells = sum(1 for t in row if t == 0)
        built = sum(1 for t in row if t > 2)
        out.append(f"B ${MAP + MAP_SIZE * v:04X},{MAP_SIZE},8 Row {v}: "
                   f"{open_cells} open, {built} built")
    return out


# A draw-order step: bits 4-5 the cell's U from the knight's (bit 5: the
# same; bit 4: one more; neither: one less), bits 6-7 its V the same way,
# bits 0-1 what is drawn there.
STEP_ACTIONS = {0: "the things in it", 1: "its walls (#R$D372)",
                2: "its outline on the ground (#R$D19D)", 3: "nothing"}


def _offset(byte: int, same: int, more: int) -> int:
    if byte & same:
        return 0
    return 1 if byte & more else -1


def draw_steps(memory, pattern: int) -> list[tuple[int, int, int]]:
    """(dU, dV, action) for each of a pattern's five steps."""
    steps = []
    for index in range(5):
        byte = memory[DRAW_ORDER + 5 * pattern + index]
        steps.append((_offset(byte, 0x20, 0x10), _offset(byte, 0x80, 0x40), byte & 3))
    return steps


def _draw_order_lines(memory) -> list[str]:
    """#R$CF08 looks at five cells round the knight's -- U-1 V+1, U-1, V+1,
    U-1 V-1 and U+1 V+1, bits 0 to 4 -- and picks the record for which of
    them are built on."""
    out = []
    for pattern in range(DRAW_ORDER_COUNT):
        steps = []
        for du, dv, action in draw_steps(memory, pattern):
            steps.append(f"({du:+d},{dv:+d}) {STEP_ACTIONS[action]}")
        out.append(f"B ${DRAW_ORDER + 5 * pattern:04X},5 Neighbours {pattern:05b}: "
                   + "; ".join(steps))
    return out


def building_starts(memory) -> dict[int, list[int]]:
    """Each building definition's address, and the table indices (cell type
    times two, plus one for the turned-round view) that reach it."""
    starts: dict[int, list[int]] = {}
    for index in range(2 * CELL_TYPES):
        target = _word(memory, BUILDINGS + 2 * index)
        if target:
            starts.setdefault(target, []).append(index)
    return starts


def _which(index: int) -> str:
    return f"type {index >> 1}{' turned round' if index & 1 else ''}"


def _building_table_lines(memory) -> list[str]:
    out = []
    for index in range(2 * CELL_TYPES):
        target = _word(memory, BUILDINGS + 2 * index)
        text = f"Cell {_which(index)}" + ("" if target else ": nothing to build")
        out.append(f"W ${BUILDINGS + 2 * index:04X},2 {text}")
    return out


def _building_lines(memory) -> list[str]:
    """Two faces of eight columns, each column a tile on the ground and the
    tile above it (#R$D3C2 draws one, then the other 64 lines up); the first
    face is drawn with #R$D250 stepping along it, the second with #R$D22D."""
    starts = building_starts(memory)
    out = []
    address = BUILDING_DEFS
    while address < PANEL_CHARS:
        if address not in starts:
            raise ValueError(f"nothing points at the building at ${address:04X}")
        indices = starts[address]
        out.append(f"@ ${address:04X} label=BUILDING{indices[0]}")
        out.append(f"b ${address:04X} Building for cell "
                   + ", ".join(_which(i) for i in indices))
        for face in range(2):
            base = address + 16 * face
            pairs = [f"{memory[base + 2 * c]}/{memory[base + 2 * c + 1]}" for c in range(8)]
            out.append(f"B ${base:04X},16,2 {'First' if face == 0 else 'Second'} face, "
                       f"tiles ground/upper: " + " ".join(pairs))
        address += BUILDING_SIZE
    if address != PANEL_CHARS:
        raise ValueError("the buildings do not end at the panel's characters")
    return out


def box_starts(memory) -> dict[int, list[int]]:
    starts: dict[int, list[int]] = {}
    for kind in range(CELL_TYPES):
        starts.setdefault(_word(memory, BOX_TABLE + 2 * kind), []).append(kind)
    return starts


def _box_lines(memory) -> list[str]:
    """Four bytes a box -- the centre's U and V in the cell, and the
    half-sizes in U and V (#R$E087, #R$E0C4) -- until a zero."""
    out = [f"W ${BOX_TABLE + 2 * kind:04X},2 Cell type {kind}" for kind in range(CELL_TYPES)]
    starts = box_starts(memory)
    address = BOXES
    while address < TILE_EDGES:
        if address not in starts:
            raise ValueError(f"nothing points at the boxes at ${address:04X}")
        kinds = starts[address]
        out.append(f"@ ${address:04X} label=BOXES{kinds[0]}")
        count = 0
        lines = []
        while memory[address + 4 * count]:
            box = address + 4 * count
            u, v, su, sv = memory[box:box + 4]
            lines.append(f"B ${box:04X},4 Centre U {u}, V {v}; half-sizes {su}, {sv}")
            count += 1
        out.append(f"b ${address:04X} Boxes for cell type{'s' if len(kinds) > 1 else ''} "
                   f"{_numbers(kinds)}")
        out.append(f"D ${address:04X} {count} box{'' if count == 1 else 'es'}.")
        out += lines
        out.append(f"B ${address + 4 * count:04X},1 End of the list")
        address += 4 * count + 1
    if address != TILE_EDGES:
        raise ValueError("the box lists do not end at the tiles' edge bytes")
    return out


def _tile_edge_lines(memory) -> list[str]:
    return [f"B ${TILE_EDGES + tile:04X},1 Tile {tile}: {memory[TILE_EDGES + tile]}"
            for tile in range(TILE_COUNT)]


# --------------------------------------------------------------------------
# Characters.
# --------------------------------------------------------------------------

def _chars(address: int, count: int, first: int, what: str) -> list[str]:
    out = []
    for index in range(count):
        out.append(f"B ${address + 8 * index:04X},8,1 {what} {first + index}")
    return out


FONT_ATTR = 0x47            # bright white on black


def _font_lines(memory) -> list[str]:
    # #FONT counts characters from a space, so its base is the address a
    # space would have: 16 characters before '0'.
    base = FONT - 8 * (FONT_FIRST - 0x20)
    text = "".join(chr(FONT_FIRST + i) for i in range(FONT_CHARS))
    out = [f"D ${FONT:04X} #HTML(#FONT${base:04X},0,{FONT_ATTR},3({text})(font))",
           f"D ${FONT:04X} The printer finds a character at a base plus eight times its "
           f"code, and the base it is given for this font lies $30 characters below it, "
           f"so these are codes $30-$5A. It prints the semicolon's code as "
           f"the copyright sign, the colon's as a full stop, and a space as the character "
           f"code $3C."]
    for index in range(FONT_CHARS):
        code = FONT_FIRST + index
        name = chr(code) if chr(code).isalnum() else f"${code:02X}"
        out.append(f"B ${FONT + 8 * index:04X},8,1 Character {name}")
    return out


def _udg(address: int, name: str, width: int, count: int, order: list[int] | None = None,
         attr: int = FONT_ATTR) -> str:
    order = order if order is not None else list(range(count))
    cells = ";".join(f"${address + 8 * i:04X}" for i in order)
    return f"#HTML(#UDGARRAY{width},{attr},3({cells})({name}))"


def _icon_lines(memory) -> list[str]:
    """Each carried thing is four characters, drawn two by two (#R$C4A4):
    things 1-8 are characters 4-35; 0-3 are never drawn."""
    out = [f"D ${ICONS:04X} " + " ".join(
        _udg(ICONS + 32 * thing, f"icon{thing}", 2, 4) for thing in range(1, 9))]
    out += _chars(ICONS, ICON_CHARS, 0, "Character")
    return out


def _panel_icon_lines(memory) -> list[str]:
    """Eight characters of the compass, drawn four by two (#R$C2C8); two sets
    of four for the heading, one for each view (#R$C29A); and eight for a
    life, two by four (#R$CBAC)."""
    base = PANEL_ICONS
    out = [f"@ ${base + 64:04X} label=HEADING_CHARS", f"@ ${base + 96:04X} label=HEADING_TURNED_CHARS",
           f"@ ${base + 128:04X} label=LIFE_CHARS"]
    pictures = [_udg(base, "compass", 4, 8, [0, 1, 2, 3, 4, 5, 6, 7]),
                _udg(base + 64, "heading0", 4, 4),
                _udg(base + 96, "heading1", 4, 4),
                _udg(base + 128, "life", 2, 8)]
    out = [f"D ${base:04X} " + " ".join(pictures)] + out
    out += _chars(base, PANEL_ICON_CHARS, 0, "Character")
    return out


# --------------------------------------------------------------------------
# Graphics: sprites and tiles.
# --------------------------------------------------------------------------

def _sprite_length(memory, address: int) -> int:
    """A width byte (bits 0-3; bits 6 and 7 are the mirrored and upside-down
    flags #R$E353 toggles), a height byte, then a mask byte and an image byte
    for each cell of each row, the bottom row first."""
    return 2 + (memory[address] & 0x0F) * memory[address + 1] * 2


SPRITE_RANGES = [(SPRITES_1, ICONS), (SPRITES_2, PANEL_ICONS), (SPRITES_3, TILES)]


def sprite_users(memory) -> dict[int, list[int]]:
    users: dict[int, list[int]] = {}
    for graphic in range(GRAPHIC_COUNT):
        users.setdefault(_word(memory, GRAPHICS + 2 * graphic), []).append(graphic)
    return users


def sprite_entries(memory) -> list[tuple[int, int, list[int]]]:
    """(address, length, graphic numbers) for every sprite in the three runs
    of sprites; each run is checked to tile its range exactly, and every
    graphic to point at the start of a sprite."""
    users = sprite_users(memory)
    entries = [(EMPTY_SPRITE, 2, users.get(EMPTY_SPRITE, []))]
    for start, end in SPRITE_RANGES:
        address = start
        while address < end:
            length = _sprite_length(memory, address)
            entries.append((address, length, users.get(address, [])))
            address += length
        if address != end:
            raise ValueError(f"the sprites from ${start:04X} run to ${address:04X}, "
                             f"not ${end:04X}")
    missing = set(users) - {a for a, _, _ in entries}
    if missing:
        raise ValueError(f"graphics point inside a sprite: {sorted(missing)}")
    return entries


def picture_sprites(memory) -> list[int]:
    return [address for address, _, _ in sprite_entries(memory)
            if memory[address] & 0x0F and memory[address + 1]]


def _sprite_lines(memory, entries) -> list[str]:
    out = []
    spare = 0
    for address, length, graphics in entries:
        width, height = memory[address] & 0x0F, memory[address + 1]
        if graphics:
            label = f"SPRITE{graphics[0]}"
            what = (f"graphic {graphics[0]}" if len(graphics) == 1
                    else f"graphics {_numbers(graphics)}")
            title = f"Sprite for {what}"
        else:
            spare += 1
            label = f"SPARE_SPRITE{'ABCDEFGH'[spare - 1]}"
            title = "Sprite no graphic number reaches"
        out.append(f"@ ${address:04X} label={label}")
        out.append(f"b ${address:04X} {title}")
        if width and height:
            out.append(f'D ${address:04X} #HTML(<img class="ns-sprite" '
                       f'src="../images/sprites/{sprite_picture_name(address)}" '
                       f'alt="The sprite at ${address:04X}">)')
            out.append(f"D ${address:04X} {width * 8} by {height} pixels.")
            out.append(f"B ${address:04X},2 Width in bytes, and height in rows")
            out.append(f"B ${address + 2:04X},{length - 2},{2 * width} Mask and image "
                       f"bytes, a pair per cell, the bottom row first")
        else:
            out.append(f"D ${address:04X} Width and height both zero: the drawing code "
                       f"draws nothing.")
            out.append(f"B ${address:04X},2 Width and height")
    return out


def _tile_length(memory, address: int) -> int:
    """A height byte, then two bytes for each row, the bottom row first."""
    return 1 + 2 * memory[address]


def tile_users(memory) -> dict[int, list[int]]:
    users: dict[int, list[int]] = {}
    for tile in range(TILE_COUNT):
        users.setdefault(_word(memory, TILE_TABLE + 2 * tile), []).append(tile)
    return users


def tile_entries(memory) -> list[tuple[int, int, list[int]]]:
    users = tile_users(memory)
    entries = []
    address = TILES
    while address < BORDER_CHARS:
        length = _tile_length(memory, address)
        entries.append((address, length, users.get(address, [])))
        address += length
    if address != BORDER_CHARS:
        raise ValueError(f"the tiles run to ${address:04X}, not ${BORDER_CHARS:04X}")
    missing = set(users) - {a for a, _, _ in entries}
    if missing:
        raise ValueError(f"tile numbers point inside a tile: {sorted(missing)}")
    return entries


def edge_entries(memory) -> list[tuple[int, int, list[int]]]:
    users: dict[int, list[int]] = {}
    for index in range(EDGE_COUNT):
        users.setdefault(_word(memory, EDGE_TABLE + 2 * index), []).append(index)
    entries = []
    address = EDGES
    while address < SPRITES_1:
        length = _tile_length(memory, address)
        entries.append((address, length, users.get(address, [])))
        address += length
    if address != SPRITES_1:
        raise ValueError(f"the edge pictures run to ${address:04X}, not ${SPRITES_1:04X}")
    if set(users) - {a for a, _, _ in entries}:
        raise ValueError("an edge number points inside an edge picture")
    return entries


def picture_tiles(memory) -> list[int]:
    return [a for a, _, _ in tile_entries(memory) + edge_entries(memory) if memory[a]]


def _tile_lines(memory, entries, kind: str, label: str) -> list[str]:
    out = []
    for address, length, numbers in entries:
        if not numbers:
            raise ValueError(f"no {kind} number reaches ${address:04X}")
        out.append(f"@ ${address:04X} label={label}{numbers[0]}")
        what = (f"{kind} {numbers[0]}" if len(numbers) == 1
                else f"{kind}s {_numbers(numbers)}")
        out.append(f"b ${address:04X} {what[0].upper()}{what[1:]}")
        out.append(f'D ${address:04X} #HTML(<img class="ns-tile" '
                   f'src="../images/tiles/{tile_picture_name(address)}" '
                   f'alt="The {kind} at ${address:04X}">)')
        out.append(f"D ${address:04X} 16 by {memory[address]} pixels.")
        out.append(f"B ${address:04X},1 Height in rows")
        if length > 1:
            out.append(f"B ${address + 1:04X},{length - 1},2 Two bytes a row, the bottom "
                       f"row first")
    return out


# --------------------------------------------------------------------------
# In the code: tunes, text, tables and record templates.
# --------------------------------------------------------------------------

def tune_lengths(memory) -> list[tuple[int, str, int]]:
    out = []
    for address, what, _ in TUNES:
        end = address
        while memory[end] != 0xFF:
            end += 1
        out.append((address, what, end + 1 - address))
    ends = [address + length for address, _, length in out]
    if ends[-1] != TUNES_END or any(e != s for e, (s, _, _) in zip(ends, out[1:])):
        raise ValueError("the tunes do not run end to end")
    return out


def _tune_lines(memory) -> list[str]:
    """A byte a note: bits 0-5 the note in #R$C6B9 (0 a rest), bits 6-7 its
    length less one, in the note's own units (#R$C661); $FF ends the tune."""
    out = []
    labels = {address: label for address, _, label in TUNES}
    for address, what, length in tune_lengths(memory):
        out.append(f"@ ${address:04X} label={labels[address]}")
        out.append(f"b ${address:04X} Tune: {what}")
        out.append(f"D ${address:04X} {_plural(length - 1, 'note')}.")
        if length > 1:
            out.append(f"B ${address:04X},{length - 1},8 Notes")
        out.append(f"B ${address + length - 1:04X},1 End of the tune")
    return out


def _note_lines(memory) -> list[str]:
    out = []
    for note in range(NOTE_COUNT):
        base = NOTES + 3 * note
        b, c, length = memory[base:base + 3]
        if note == 0:
            text = "Note 0: a rest, which #R$C661 does not look up"
        else:
            text = f"Note {note}: loop counts {b} and {c}; {length} cycles a unit"
        out.append(f"B ${base:04X},3 {text}")
    return out


def _string(memory, address: int) -> tuple[str, int]:
    """Characters until one with bit 7 set, which is the last (#R$C9FC)."""
    text = ""
    while True:
        code = memory[address]
        text += chr(code & 0x7F)
        address += 1
        if code & 0x80:
            return text, address


def _shown(text: str) -> str:
    """As the font draws it: ';' is the copyright sign and ':' a full stop."""
    return text.replace(";", "(c)").replace(":", ".")


def _string_lines(memory, address: int, with_attr: bool) -> tuple[list[str], int]:
    out = []
    if with_attr:
        out.append(f"B ${address:04X},1 Attribute")
        address += 1
    text, end = _string(memory, address)
    length = end - address
    # The last character has bit 7 set; SkoolKit shows it as a byte.
    out.append(f"T ${address:04X},{length} \"{_shown(text)}\"")
    return out, end


def _score_text_lines(memory) -> list[str]:
    lines, end = _string_lines(memory, SCORE_TEXT, True)
    if end != SCORE_TEXT + 6:
        raise ValueError("the panel's heading is not six bytes")
    return [f"@ ${SCORE_TEXT:04X} label=SCORE_TEXT",
            f"t ${SCORE_TEXT:04X} The panel's heading, an attribute and then the text"] + lines


def _menu_lines(memory) -> list[str]:
    out = [f"@ ${MENU_COLOURS:04X} label=MENU_COLOURS",
           f"b ${MENU_COLOURS:04X} The menu: colours, places and text",
           f"D ${MENU_COLOURS:04X} #R$CA2B prints the menu's eight lines from three lists: "
           f"an attribute each (bit 7, the flash, is set on the lines chosen, #R$C949), "
           f"where each goes on the screen, and the text."]
    for item in range(MENU_ITEMS):
        if item == 1:
            # #R$C949 flashes the control methods' lines from here.
            out.append(f"@ ${MENU_COLOURS + item:04X} label=MENU_CONTROL_COLOURS")
        out.append(f"B ${MENU_COLOURS + item:04X},1 Line {item}: "
                   f"{INKS[memory[MENU_COLOURS + item] & 7]}")
    places = MENU_COLOURS + MENU_ITEMS
    out.append(f"@ ${places:04X} label=MENU_PLACES")
    for item in range(MENU_ITEMS):
        where = _word(memory, places + 2 * item)
        out.append(f"B ${places + 2 * item:04X},2,1 Line {item}: x {where & 0xFF}, "
                   f"y {where >> 8}")
    address = places + 2 * MENU_ITEMS
    out.append(f"@ ${address:04X} label=MENU_TEXT")
    out.append(f"t ${address:04X} The menu's text")
    for _ in range(MENU_ITEMS):
        lines, address = _string_lines(memory, address, False)
        out += lines
    if address != MENU_END:
        raise ValueError(f"the menu's text ends at ${address:04X}, not ${MENU_END:04X}")
    return out


def _end_text_lines(memory) -> list[str]:
    out = [f"@ ${END_TEXT:04X} label=END_TEXT",
           f"t ${END_TEXT:04X} The text after a game",
           f"D ${END_TEXT:04X} Each an attribute and then the text, printed in turn by "
           f"#R$CC56."]
    address = END_TEXT
    while address < END_TEXT_END:
        lines, address = _string_lines(memory, address, True)
        out += lines
    if address != END_TEXT_END:
        raise ValueError("the text after a game runs on")
    return out


# The fields of an object record, as the update routines use them (16
# bytes; stage 2 of the disassembly describes each where it is used).
FIELDS = [(0, 1, "graphic"), (1, 2, "U"), (3, 2, "V"), (5, 1, "speed"),
          (6, 1, "facing and turn count"), (7, 1, "flags"), (8, 1, "half-size in U"),
          (9, 1, "half-size in V"), (10, 1, "step in U"), (11, 1, "step in V"),
          (12, 1, "drawing offset x"), (13, 1, "drawing offset y"),
          (14, 1, "screen x"), (15, 1, "screen y")]


def _record_lines(memory, address: int, what: str, labels: dict | None = None) -> list[str]:
    out = []
    for offset, length, name in FIELDS:
        if labels and offset in labels:
            # A two-byte position's label names each byte, so that START_U
            # alone cannot be read as either the low byte or the cell.
            suffix = "_LOW" if length == 2 else ""
            out.append(f"@ ${address + offset:04X} label={labels[offset]}{suffix}")
        value = (memory[address + offset] if length == 1
                 else _word(memory, address + offset))
        if length == 2:
            # The high byte is the cell, which the game writes on its own.
            out.append(f"B ${address + offset:04X},1 {what}+{offset:X} {name}, low byte: "
                       f"{value & 0xFF}")
            if labels and offset in labels:
                out.append(f"@ ${address + offset + 1:04X} label={labels[offset]}_CELL")
            out.append(f"B ${address + offset + 1:04X},1 {what}+{offset + 1:X} {name}, "
                       f"high byte (the cell): {value >> 8}")
        else:
            out.append(f"B ${address + offset:04X},1 {what}+{offset:X} {name}: {value}")
    return out


def _template_lines(memory) -> list[str]:
    out = [f"@ ${START_RECORDS:04X} label=START_RECORDS",
           f"b ${START_RECORDS:04X} The knight's two records at a new life",
           f"D ${START_RECORDS:04X} Copied over the first two object records by #R$CBAC. "
           f"The game writes his cell here: a random one at a new game (#R$CB7B), "
           f"and the one he died in at a death (#R$CE89)."]
    out += _record_lines(memory, START_RECORDS, "Legs",
                         {1: "START_U", 3: "START_V", 6: "START_FACING", 7: "START_FLAGS"})
    out += _record_lines(memory, START_RECORDS + 16, "Top")
    out.append(f"@ ${ENDING_RECORDS:04X} label=ENDING_RECORDS")
    out.append(f"b ${ENDING_RECORDS:04X} The ending's ten records")
    out.append(f"D ${ENDING_RECORDS:04X} A graphic and the screen x and y for each, "
               f"copied into the object records by #R$CC56 when the four villains are gone.")
    for index in range(ENDING_COUNT):
        base = ENDING_RECORDS + 3 * index
        graphic, x, y = memory[base:base + 3]
        out.append(f"B ${base:04X},3,1 Record {index}: graphic {graphic} at x {x}, y {y}")
    for address, label, title, what in (
            (MONSTER_RECORD, "MONSTER_RECORD", "What a monster starts as", "Monster"),
            (OBJECT_RECORD, "OBJECT_RECORD", "What each of the four objects starts as",
             "Object"),
            (VILLAIN_RECORD, "VILLAIN_RECORD", "What each of the four villains starts as",
             "Villain")):
        out.append(f"@ ${address:04X} label={label}")
        out.append(f"b ${address:04X} {title}")
        out += _record_lines(memory, address, what)
    return out


def _update_lines(memory) -> list[str]:
    return [f"W ${UPDATES + 2 * graphic:04X},2 Graphic {graphic}"
            for graphic in range(GRAPHIC_COUNT)]


# --------------------------------------------------------------------------
# Together.
# --------------------------------------------------------------------------

# The ranges the generated lines describe completely: build_nightshade.py
# drops whatever sna2ctl put inside them. (start, end), end exclusive.
OWNED = [(MAP, DRAW_ORDER), (DRAW_ORDER, BUILDINGS), (BUILDINGS, BOX_TABLE),
         (BOX_TABLE, TILE_EDGES), (TILE_EDGES, BUILDING_DEFS), (BUILDING_DEFS, PANEL_CHARS),
         (PANEL_CHARS, FONT), (FONT, TILE_TABLE), (TILE_TABLE, GRAPHICS),
         (GRAPHICS, EMPTY_SPRITE), (EMPTY_SPRITE, EDGE_TABLE), (EDGE_TABLE, EDGES),
         (EDGES, SPRITES_1), (SPRITES_1, ICONS), (ICONS, SPRITES_2),
         (SPRITES_2, PANEL_ICONS), (PANEL_ICONS, SPRITES_3), (SPRITES_3, TILES),
         (TILES, BORDER_CHARS), (BORDER_CHARS, VARIABLES),
         (SCORE_TEXT, SCORE_TEXT + 6), (NOTES, NOTES + 3 * NOTE_COUNT),
         (NOTES + 3 * NOTE_COUNT, TUNES_END), (MENU_COLOURS, MENU_END),
         (START_RECORDS, START_RECORDS + 32), (ENDING_RECORDS, ENDING_RECORDS + 3 * ENDING_COUNT),
         (END_TEXT, END_TEXT_END), (MONSTER_RECORD, MONSTER_RECORD + 16),
         (UPDATES, UPDATES + 2 * GRAPHIC_COUNT),
         (OBJECT_RECORD, OBJECT_RECORD + 16), (VILLAIN_RECORD, VILLAIN_RECORD + 16)]


def data_blocks(memory) -> str:
    """The control-file lines for every table above, in address order."""
    sprites = sprite_entries(memory)
    lines = ["; Generated by scripts/nightshade_data.py from the snapshot -- do not edit.", ""]
    lines += [f"@ ${MAP:04X} label=TOWN", f"b ${MAP:04X} The town map",
              f"D ${MAP:04X} A byte a cell, 32 rows of 32: the row is the high byte of V, "
              f"the column the high byte of U. 0 is open ground, 1 and 2 are solid, and "
              f"3 up are the cell types that are built on (#R$62A4)."]
    lines += _map_lines(memory) + [""]
    lines += [f"@ ${DRAW_ORDER:04X} label=DRAW_ORDER", f"b ${DRAW_ORDER:04X} The drawing order"]
    lines += _draw_order_lines(memory) + [""]
    lines += [f"@ ${BUILDINGS:04X} label=BUILDING_TABLE",
              f"b ${BUILDINGS:04X} Building table"]
    lines += _building_table_lines(memory) + [""]
    lines += [f"@ ${BOX_TABLE:04X} label=BOX_TABLE", f"b ${BOX_TABLE:04X} Box table"]
    lines += _box_lines(memory) + [""]
    lines += [f"@ ${TILE_EDGES:04X} label=TILE_EDGES",
              f"b ${TILE_EDGES:04X} The edge picture under each tile"]
    lines += _tile_edge_lines(memory) + [""]
    lines += _building_lines(memory) + [""]
    lines += [f"@ ${PANEL_CHARS:04X} label=PANEL_CHARS",
              f"b ${PANEL_CHARS:04X} The panel's frame",
              f"D ${PANEL_CHARS:04X} "
              + _udg(PANEL_CHARS, "panelframe", PANEL_CHAR_COUNT, PANEL_CHAR_COUNT)]
    lines += _chars(PANEL_CHARS, PANEL_CHAR_COUNT, 0, "Character") + [""]
    lines += [f"@ ${FONT:04X} label=FONT", f"b ${FONT:04X} The font"]
    lines += _font_lines(memory) + [""]
    lines += [f"@ ${TILE_TABLE:04X} label=TILE_TABLE", f"b ${TILE_TABLE:04X} Tile table"]
    lines += [f"W ${TILE_TABLE + 2 * tile:04X},2 Tile {tile}" for tile in range(TILE_COUNT)]
    lines += [""]
    lines += [f"@ ${GRAPHICS:04X} label=GRAPHICS", f"b ${GRAPHICS:04X} Graphic table"]
    lines += [f"W ${GRAPHICS + 2 * g:04X},2 Graphic {g}" for g in range(GRAPHIC_COUNT)]
    lines += [""]
    lines += _sprite_lines(memory, sprites[:1]) + [""]
    lines += [f"@ ${EDGE_TABLE:04X} label=EDGE_TABLE", f"b ${EDGE_TABLE:04X} Edge table"]
    lines += [f"W ${EDGE_TABLE + 2 * i:04X},2 Edge {i}" for i in range(EDGE_COUNT)]
    lines += [""]
    lines += _tile_lines(memory, edge_entries(memory), "edge", "EDGE") + [""]
    runs = {start: [e for e in sprites[1:] if start <= e[0] < end] for start, end in SPRITE_RANGES}
    lines += _sprite_lines(memory, runs[SPRITES_1]) + [""]
    lines += [f"@ ${ICONS:04X} label=ICONS", f"b ${ICONS:04X} The carried things' pictures"]
    lines += _icon_lines(memory) + [""]
    lines += _sprite_lines(memory, runs[SPRITES_2]) + [""]
    lines += [f"@ ${PANEL_ICONS:04X} label=PANEL_ICONS",
              f"b ${PANEL_ICONS:04X} The compass, the headings and a life"]
    lines += _panel_icon_lines(memory) + [""]
    lines += _sprite_lines(memory, runs[SPRITES_3]) + [""]
    lines += _tile_lines(memory, tile_entries(memory), "tile", "TILE") + [""]
    lines += [f"@ ${BORDER_CHARS:04X} label=BORDER_CHARS",
              f"b ${BORDER_CHARS:04X} The border's characters",
              f"D ${BORDER_CHARS:04X} "
              + _udg(BORDER_CHARS, "border", 10, BORDER_CHAR_COUNT, attr=0x16)]
    lines += _chars(BORDER_CHARS, BORDER_CHAR_COUNT, 0, "Character") + [""]
    lines += _score_text_lines(memory) + [""]
    lines += [f"@ ${NOTES:04X} label=NOTES", f"b ${NOTES:04X} The notes"]
    lines += _note_lines(memory) + [""]
    lines += _tune_lines(memory) + [""]
    lines += _menu_lines(memory) + [""]
    lines += _template_lines(memory) + [""]
    lines += _end_text_lines(memory) + [""]
    lines += [f"@ ${UPDATES:04X} label=UPDATES", f"w ${UPDATES:04X} Update routines, by graphic"]
    lines += _update_lines(memory) + [""]
    return NEWLINE.join(lines) + NEWLINE
