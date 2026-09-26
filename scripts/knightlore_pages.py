"""Knight Lore's graphics and castle pages, drawn from the game at build time.

build_knightlore.py --html calls build(), which writes the pictures into the
HTML directory and the pages' content into game_disassembly/knightlore/
knightlore-pages.ref; scripts/knightlore.ref names the pages and #INCLUDEs
each section from that file. Nothing here is committed output: the pictures
are the game's, and so are the room lists.

Two ways of drawing, each the game's own:

- Sprites are decoded from their bytes, exactly as print_sprite reads them: a
  header of the width (bits 0-3) and height, then a mask byte and an image
  byte per cell, bottom row first. A set mask bit is opaque; a clear one lets
  the background through. The header's bits 7 and 6 say the stored data is
  currently upside down or mirrored -- the game flips sprites in place -- and
  the picture here undoes that, to show each the way it was drawn.
- Rooms, scenery and templates are drawn by the game's own code, run in
  SkoolKit's simulator: the set-up routines main would call, then
  build_screen_objects for the room and one pass of the frame loop, which on
  a new room ends by drawing the panel into the room's buffer and copying it
  all to the display (update_screen). The picture is read out of the buffer
  just before the panel goes in, in the colours fill_attr has just given the
  screen. A background or a block type on its
  own is drawn the same way, by writing a one-off room record at the start of
  the room table, where find_screen looks first.
"""
from __future__ import annotations

import html
import re
from pathlib import Path

import knightlore_data as kd

ROM = Path(__file__).resolve().parent.parent / "roms" / "48.rom"

SPRITE_TABLE = 0x7112     # a word per object type
TYPE_COUNT = 188
HANDLER_TABLE = 0xB096    # a word per object type
BLOCK_TYPES = 0x6BD1      # 29 words
BLOCK_TYPE_COUNT = 29
SIZES = 0x6248            # three rooms sizes, three bytes each

# Routines the pictures are drawn with (see their entries).
BUILD_LOOKUP_TBLS = 0xD69E
SHUFFLE_OBJECTS_REQUIRED = 0xB544
INIT_START_LOCATION = 0xD1B1
INIT_SUN = 0xC46D
INIT_SPECIAL_OBJECTS = 0xC47E
LOSE_LIFE = 0xD12A
BUILD_SCREEN_OBJECTS = 0xD1E6
ONSCREEN_LOOP = 0xAFBD
ROOM_DRAWN = 0xB04F        # in no_delay on a new room: the room is in the
                           # buffer and fill_attr has coloured the screen, and
                           # the panel has not yet been drawn into the buffer
SCREEN_BUFFER = 0xD8F3     # 192 rows of 32 bytes, the bottom line first
TRAP = 0xF0F3             # thirteen bytes nothing uses: a call returns here
PLAYER = 0x5C08           # object records 0 and 1: the player's legs and top
PLAYER_TOP = 0x5C28
ROOM_OFFSET = 8
OBJECT_STACK = 0x5BA0     # SP for each object, as update_sprite_loop sets it

SPECTRUM = [(0, 0, 0), (0, 0, 0xD7), (0xD7, 0, 0), (0xD7, 0, 0xD7),
            (0, 0xD7, 0), (0, 0xD7, 0xD7), (0xD7, 0xD7, 0), (0xD7, 0xD7, 0xD7)]
SPECTRUM_BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF),
                   (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0), (0xFF, 0xFF, 0xFF)]
# The rows of the screen kept: all of them, since some rooms reach every edge.
ROOM_ROWS = (0, 192)
COLOUR_NAMES = {3: "magenta", 4: "green", 5: "cyan", 6: "yellow", 7: "white"}


def _word(memory, address: int) -> int:
    return memory[address] | (memory[address + 1] << 8)


def _esc(text: str) -> str:
    return html.escape(text, quote=False)


# --------------------------------------------------------------------------
# What the listing says, for titles and names.
# --------------------------------------------------------------------------

def read_listing(skool: Path) -> tuple[dict[int, str], dict[int, str], dict[int, str]]:
    """Entry labels and titles by address, and each instruction's comment."""
    labels, titles, comments = {}, {}, {}
    comment, label, last = [], None, None
    for line in skool.read_text(encoding="utf-8").splitlines():
        if line.startswith("@label="):
            label = line[7:].strip()
            continue
        if line.startswith("; ") or line == ";":
            comment.append(line[2:])
            continue
        if line.startswith("@"):
            continue
        m = re.match(r"^([bcgistuw* ])\$([0-9A-F]{4}) [^;]*(?:; ?(.*))?$", line)
        if m:
            address = int(m.group(2), 16)
            if m.group(1) in "bcgistuw":
                titles[address] = comment[0] if comment else ""
            if label:
                labels[address] = label
                label = None
            comments[address] = (m.group(3) or "").strip()
            last = address
        elif line.strip().startswith(";") and last is not None:
            # a comment carried on to the next line
            comments[last] += " " + line.strip()[1:].strip()
        comment = []
    return labels, titles, comments


# --------------------------------------------------------------------------
# Sprites, from their bytes.
# --------------------------------------------------------------------------

def _reverse_bits(byte: int) -> int:
    return int(f"{byte:08b}"[::-1], 2)


def sprite_image(memory, address: int, scale: int = 2):
    """The sprite at `address`, the way it was drawn, on a clear background."""
    from PIL import Image

    head, height = memory[address], memory[address + 1]
    width = head & 0x0F
    if not width or not height:
        return None
    rows = []
    for row in range(height):
        base = address + 2 + row * width * 2
        rows.append([(memory[base + 2 * c], memory[base + 2 * c + 1]) for c in range(width)])
    if head & 0x80:                    # stored upside down at the moment
        rows.reverse()
    if head & 0x40:                    # stored mirrored at the moment
        rows = [[(_reverse_bits(m), _reverse_bits(i)) for m, i in reversed(row)]
                for row in rows]
    image = Image.new("RGBA", (width * 8, height), (0, 0, 0, 0))
    pixels = image.load()
    for row, cells in enumerate(rows):
        y = height - 1 - row           # the bottom row is stored first
        for column, (mask, bits) in enumerate(cells):
            for bit in range(8):
                if mask & (0x80 >> bit):
                    pixels[column * 8 + bit, y] = ((255, 255, 255, 255) if bits & (0x80 >> bit)
                                                   else (0, 0, 0, 255))
    return image.resize((width * 8 * scale, height * scale), Image.NEAREST)


# --------------------------------------------------------------------------
# Scenes, drawn by the game.
# --------------------------------------------------------------------------

class Castle:
    """The game, set up as main sets it up but without the menu, ready to
    draw any room."""

    def __init__(self, memory):
        from skoolkit import read_bin_file

        memory = list(memory)
        memory[:0x4000] = read_bin_file(str(ROM))
        self.memory = memory
        # The registers carry over from one call to the next, as they do in
        # the game: build_screen_objects finds the room through IX, which
        # lose_life leaves on the player's record.
        self.registers = None
        for routine in (BUILD_LOOKUP_TBLS, SHUFFLE_OBJECTS_REQUIRED, INIT_START_LOCATION,
                        INIT_SUN, INIT_SPECIAL_OBJECTS, LOSE_LIFE):
            self.memory, self.registers = self._call(self.memory, routine, self.registers)
        # No player in the pictures: an empty type is not drawn.
        self.memory[PLAYER] = 0
        self.memory[PLAYER_TOP] = 0
        # A one-off room needs a number no charm lies in, or the room builder
        # puts the charm in too (find_special_objs_here goes by room number).
        charm_rooms = {self.memory[kd.CHARM_PLACES + kd.CHARM_PLACE_SIZE * i + 8]
                       for i in range(kd.CHARM_PLACE_COUNT)}
        self.empty_room = min(n for n in range(0, 256, 2) if n not in charm_rooms)

    @staticmethod
    def _machine(memory):
        from skoolkit import CSimulator
        from skoolkit.simulator import Simulator

        return (CSimulator or Simulator)(memory, state={"iff": 0, "im": 1, "tstates": 0})

    def _call(self, memory, address: int, registers=None):
        """Run a routine until it returns; the memory and registers after."""
        from skoolkit.simutils import SP

        memory = list(memory)
        memory[OBJECT_STACK - 2:OBJECT_STACK] = [TRAP & 0xFF, TRAP >> 8]
        simulator = self._machine(memory)
        if registers is not None:
            for index, value in enumerate(registers):
                simulator.registers[index] = value
        simulator.registers[SP] = OBJECT_STACK - 2
        simulator.run(address, TRAP)
        return list(simulator.memory), list(simulator.registers)

    def draw(self, room: int, record: list[int] | None = None):
        """Room `room` as the game draws it on entering, one frame in. With
        `record`, that record is written first in the room table, so it is the
        one found."""
        from PIL import Image
        from skoolkit.simutils import SP

        memory = list(self.memory)
        memory[PLAYER + ROOM_OFFSET] = room
        memory[PLAYER_TOP + ROOM_OFFSET] = room
        if record is not None:
            memory[kd.ROOMS:kd.ROOMS + len(record)] = record
        memory, registers = self._call(memory, BUILD_SCREEN_OBJECTS, self.registers)
        simulator = self._machine(memory)
        for index, value in enumerate(registers):
            simulator.registers[index] = value
        simulator.registers[SP] = OBJECT_STACK
        # On a new room the frame ends by drawing the panel into the buffer
        # and copying the whole buffer to the display (update_screen). Stop
        # before the panel, and read the room out of the buffer itself.
        simulator.run(ONSCREEN_LOOP, ROOM_DRAWN)
        screen = simulator.memory
        top, bottom = ROOM_ROWS
        image = Image.new("RGB", (256, bottom - top))
        pixels = image.load()
        for y in range(top, bottom):
            row = SCREEN_BUFFER + (191 - y) * 32
            for column in range(32):
                byte = screen[row + column]
                attr = screen[0x5800 + (y >> 3) * 32 + column]
                palette = SPECTRUM_BRIGHT if attr & 0x40 else SPECTRUM
                ink, paper = palette[attr & 7], palette[(attr >> 3) & 7]
                for bit in range(8):
                    pixels[column * 8 + bit, y - top] = ink if byte & (0x80 >> bit) else paper
        return image


def _cropped(image, margin: int = 8):
    """A one-off scene cut down to what was drawn in it, with a margin."""
    box = image.convert("L").point(lambda v: 255 if v else 0).getbbox()
    if not box:
        return image
    left, top, right, bottom = box
    return image.crop((max(0, left - margin), max(0, top - margin),
                       min(image.width, right + margin), min(image.height, bottom + margin)))


def _one_off_record(room: int, shape: int, backgrounds: list[int],
                    groups: list[tuple[int, list[int]]]) -> list[int]:
    """A room record: number, length less one, shape and ink, backgrounds,
    and -- if there are any -- $FF and the groups of objects."""
    body = [(shape << 3) | 7] + backgrounds
    if groups:
        body.append(0xFF)
        for block_type, positions in groups:
            body += [(block_type << 3) | (len(positions) - 1)] + positions
    return [room, len(body) + 1] + body


# --------------------------------------------------------------------------
# The tables, read.
# --------------------------------------------------------------------------

def rooms(memory) -> list[dict]:
    """Every room record: its number, address, shape, colour, backgrounds and
    groups of objects (block type, copies)."""
    out = []
    address = kd.ROOMS
    while address < kd.ROOMS_END:
        number, length, attribute = memory[address:address + 3]
        end = address + 1 + length
        part = address + 3
        backgrounds = []
        while part < end and memory[part] != 0xFF:
            backgrounds.append(memory[part])
            part += 1
        if part < end:
            part += 1
        groups = []
        while part < end:
            group = memory[part]
            groups.append((group >> 3, (group & 7) + 1))
            part += 1 + (group & 7) + 1
        out.append({"number": number, "address": address, "shape": attribute >> 3,
                    "ink": attribute & 7, "backgrounds": backgrounds, "groups": groups})
        address = end
    return out


def block_type_parts(memory, index: int) -> tuple[int, list[list[int]]]:
    """A block type's address and its 6-byte parts."""
    address = _word(memory, BLOCK_TYPES + 2 * index)
    parts, part = [], address
    while memory[part]:
        parts.append(list(memory[part:part + 6]))
        part += 6
    return address, parts


def background_pieces(memory, index: int) -> tuple[int, list[list[int]]]:
    address = _word(memory, kd.BACKGROUNDS + 2 * index)
    pieces, piece = [], address
    while memory[piece]:
        pieces.append(list(memory[piece:piece + 8]))
        piece += 8
    return address, pieces


# --------------------------------------------------------------------------
# The pages.
# --------------------------------------------------------------------------

def _room_link(number: int) -> str:
    return f'<a href="RoomStructure.html#room{number:02x}">${number:02X}</a>'


def _sprite_pages(memory, labels, titles, image_dir: Path) -> tuple[str, dict[int, str]]:
    """The Sprites section, and each sprite's picture path by address."""
    by_sprite: dict[int, list[int]] = {}
    for t in range(TYPE_COUNT):
        by_sprite.setdefault(_word(memory, SPRITE_TABLE + 2 * t), []).append(t)
    pictures = {}
    lines = ['<div class="kl-list">',
             "<p>Every sprite in the game, drawn from its own bytes the way #R$D718 "
             "reads them: a header holding the width in bytes (bits 0 to 3) and the "
             "height in rows, then a mask byte and an image byte for each cell, bottom "
             "row first. Where a mask bit is set the sprite is solid, black or white by "
             "its image bit; where it is clear the background shows through, which is "
             "how objects overlap in depth without being drawn in any special order. "
             "The game flips sprites in place when an object faces the other way "
             "(#R$D865), and the header's top two bits say which way the data lies at "
             "the moment; each is shown here the way round it was drawn.</p>",
             "<p>Beside each sprite are the object types that use it: the type is the "
             "object's own first byte, and indexes the table at #R$7112. See the "
             '<a href="Objects.html">objects</a> for what each type is.</p>']
    for address in sorted(by_sprite):
        label = labels.get(address, f"${address:04X}")
        image = sprite_image(memory, address)
        width, height = memory[address] & 0x0F, memory[address + 1]
        types = ", ".join(f"{t} (${t:02X})" for t in by_sprite[address])
        lines.append(f'<div class="kl-item" id="{label}">')
        if image is not None:
            name = f"{label}.png"
            image.save(image_dir / name)
            pictures[address] = f"images/sprites/{name}"
            lines.append(f'<img class="kl-sprite" src="{pictures[address]}" alt="{label}">')
        lines.append(f"<p><b>#R${address:04X}({label})</b>: {_esc(titles.get(address, ''))}<br>")
        lines.append(f"{width * 8} by {height} pixels. Types {types}.</p>")
        lines.append("</div>")
    lines.append("</div>")
    return "\n".join(lines), pictures


def _objects_page(memory, labels, comments, sprite_pictures) -> str:
    lines = ['<div class="kl-list">',
             "<p>Every object type: the first byte of an object record. It picks the "
             "handler that runs the object each frame, through #R$B096, and the sprite "
             "it is drawn with, through #R$7112 -- there is no separate frame number, so "
             "an object animates by changing its own type. The descriptions are the "
             "handler table's.</p>",
             '<table class="kl-table"><tr><th>Type</th><th>Sprite</th><th>What it is</th>'
             "<th>Handler</th></tr>"]
    for t in range(TYPE_COUNT):
        sprite = _word(memory, SPRITE_TABLE + 2 * t)
        handler = _word(memory, HANDLER_TABLE + 2 * t)
        what = comments.get(HANDLER_TABLE + 2 * t, "")
        what = re.sub(r"^Type \d+:\s*", "", what)
        picture = sprite_pictures.get(sprite)
        cell = (f'<a href="Sprites.html#{labels.get(sprite, "")}"><img class="kl-thumb" '
                f'src="{picture}" alt=""></a>' if picture else "")
        lines.append(f'<tr id="type{t}"><td>{t}<br>${t:02X}</td><td>{cell}</td>'
                     f"<td>{_esc(what)}</td><td>#R${handler:04X}</td></tr>")
    lines += ["</table>", "</div>"]
    return "\n".join(lines)


def _templates_page(memory, castle, titles, all_rooms, image_dir: Path) -> str:
    users: dict[int, list[int]] = {}
    for room in all_rooms:
        for block_type, _ in room["groups"]:
            users.setdefault(block_type, []).append(room["number"])
    lines = ['<div class="kl-list">',
             "<p>The 29 kinds of thing a room record can place -- the templates the "
             "room builder (#R$D46C) makes object records from. A room names one by its "
             "index in #R$6BD1 and gives a grid cell for each copy; every part of the "
             "template becomes one object record, with the type, the half-sizes, the "
             "height and the flags copied from it, and the last byte nudging the "
             "position by half a cell or up by a few levels. Each is drawn here by the "
             "game, on its own in an empty room.</p>"]
    for index in range(BLOCK_TYPE_COUNT):
        address, parts = block_type_parts(memory, index)
        record = _one_off_record(castle.empty_room, 0, [], [(index, [0x1B])])
        castle_image = _cropped(castle.draw(castle.empty_room, record))
        name = f"template{index:02d}.png"
        castle_image.save(image_dir / name)
        rows = "".join(
            f"<tr><td>${p[0]:02X}</td><td>{p[1]}</td><td>{p[2]}</td><td>{p[3]}</td>"
            f"<td>${p[4]:02X}</td><td>${p[5]:02X}</td></tr>" for p in parts)
        used = users.get(index, [])
        lines += [f'<div class="kl-item" id="template{index}">',
                  f'<img class="kl-piece" src="images/rooms/{name}" alt="" '
                  f'width="{castle_image.width * 2}" height="{castle_image.height * 2}">',
                  f"<p><b>{index}: {_esc(kd.BLOCK_NAMES[index])}</b> -- #R${address:04X}: "
                  f"{_esc(titles.get(address, ''))}</p>",
                  '<table class="kl-table"><tr><th>Type</th><th>Half x</th><th>Half y</th>'
                  "<th>Height</th><th>Flags</th><th>Offset</th></tr>" + rows + "</table>",
                  f"<p>In {len(used)} room{'s' if len(used) != 1 else ''}"
                  + (": " + ", ".join(_room_link(r) for r in sorted(set(used))) if used else "")
                  + ".</p>", "</div>"]
    lines.append("</div>")
    return "\n".join(lines)


def _scenery_page(memory, castle, titles, all_rooms, image_dir: Path) -> str:
    users: dict[int, list[int]] = {}
    for room in all_rooms:
        for background in room["backgrounds"]:
            users.setdefault(background, []).append(room["number"])
    # The walls are made for a room of their own size.
    shape_for = {13: 2, 14: 1}
    lines = ['<div class="kl-list">',
             "<p>The 24 backgrounds: the fixed scenery a room lists before its objects "
             "-- walls, arches, the forest's trees, portcullises, the wizard and his "
             "cauldron. Unlike a template, a background carries its own coordinates, so "
             "it always stands in the same place; #R$D432 copies each of its pieces "
             "into an object record as it is. Each is drawn here by the game, on its "
             "own in an empty room of the size it belongs to.</p>"]
    for index in range(kd.BACKGROUND_COUNT):
        address, pieces = background_pieces(memory, index)
        record = _one_off_record(castle.empty_room, shape_for.get(index, 0), [index], [])
        image = _cropped(castle.draw(castle.empty_room, record))
        name = f"scenery{index:02d}.png"
        image.save(image_dir / name)
        rows = "".join(
            f"<tr><td>{_esc(kd.PIECE_NAMES.get(p[0], f'type ${p[0]:02X}'))}</td>"
            f"<td>${p[1]:02X}</td><td>${p[2]:02X}</td><td>${p[3]:02X}</td>"
            f"<td>{p[4]} by {p[5]}</td><td>{p[6]}</td><td>${p[7]:02X}</td></tr>" for p in pieces)
        used = users.get(index, [])
        lines += [f'<div class="kl-item" id="scenery{index}">',
                  f'<img class="kl-piece" src="images/rooms/{name}" alt="" '
                  f'width="{image.width * 2}" height="{image.height * 2}">',
                  f"<p><b>{index}: {_esc(kd.BACKGROUND_NAMES[index])}</b> -- #R${address:04X}: "
                  f"{_esc(titles.get(address, ''))}</p>",
                  '<table class="kl-table"><tr><th>Piece</th><th>x</th><th>y</th><th>z</th>'
                  "<th>Size</th><th>Height</th><th>Flags</th></tr>" + rows + "</table>",
                  f"<p>In {len(used)} room{'s' if len(used) != 1 else ''}"
                  + (": " + ", ".join(_room_link(r) for r in sorted(set(used))) if used else "")
                  + ".</p>", "</div>"]
    lines.append("</div>")
    return "\n".join(lines)


def _rooms_page(memory, castle, all_rooms, image_dir: Path) -> str:
    sizes = [memory[SIZES + 3 * s:SIZES + 3 * s + 3] for s in range(3)]
    by_number = {room["number"]: room for room in all_rooms}
    lines = ['<div class="kl-list">',
             "<h3>The castle</h3>",
             "<p>The castle is a grid of 16 by 16 squares, and a room's number is its "
             "square's row times 16 plus its column: leaving by the east or west side "
             "changes only the low four bits, and north or south adds or takes 16 "
             "(#R$CA9A to #R$CB29). 128 of the 256 squares are rooms. The map below "
             "shows each where it lies, as the game draws it on entering; click one "
             "for its record.</p>",
             '<table class="kl-map">']
    for row in range(16):
        cells = []
        for column in range(16):
            number = row * 16 + column
            if number in by_number:
                cells.append(f'<td><a href="#room{number:02x}"><img src="images/rooms/'
                             f'room{number:02x}.png" alt="${number:02X}" '
                             f'title="${number:02X}"></a></td>')
            else:
                cells.append("<td></td>")
        lines.append("<tr>" + "".join(cells) + "</tr>")
    lines += ["</table>",
              "<h3>A room record</h3>",
              "<p>A room is a record of a few dozen bytes in #R$6251, and the records "
              "are packed end to end with no index: #R$D3CF finds a room by walking "
              "them from the start. In order:</p>",
              '<table class="kl-table"><tr><th>Byte</th><th>What</th></tr>',
              "<tr><td>0</td><td>The room's number.</td></tr>",
              "<tr><td>1</td><td>The record's length less one: the distance from this "
              "byte to the next record.</td></tr>",
              "<tr><td>2</td><td>Bits 0-2 the ink the whole room is drawn in, always "
              "bright on black; bits 3-7 its size, an index into #R$6248.</td></tr>",
              "<tr><td>3 ...</td><td>Its backgrounds, one byte each: indexes into "
              '#R$6CE2 -- see <a href="Scenery.html">the scenery</a>.</td></tr>',
              "<tr><td>$FF</td><td>The end of the backgrounds, if objects follow. A "
              "room with none just ends.</td></tr>",
              "<tr><td>groups</td><td>A byte whose bits 3-7 are a template, an index "
              'into #R$6BD1 (see <a href="Templates.html">the templates</a>), and bits '
              "0-2 the number of copies less one; then a position byte per copy.</td></tr>",
              "</table>",
              "<p>A position byte is a cell of the room's floor and a level: bits 0-2 "
              "the x cell and bits 3-5 the y cell of an 8 by 8 grid, and bits 6-7 the "
              "level. #R$D46C makes x = $48 + 16 times the x cell, y likewise, and z = "
              "the floor height + 12 times the level, then adds the template's "
              "offset.</p>",
              "<p>The three sizes, as half-widths about the room's centre at 128, and "
              "the floor's height:</p>",
              '<table class="kl-table"><tr><th>Size</th><th>Half x</th><th>Half y</th>'
              "<th>Floor</th></tr>"]
    for index, (half_x, half_y, floor) in enumerate(sizes):
        lines.append(f"<tr><td>{index}</td><td>{half_x}</td><td>{half_y}</td>"
                     f"<td>${floor:02X}</td></tr>")
    lines += ["</table>",
              "<p>A room becomes object records from $5C08 up: the player's two, two "
              "for the room's charms, then everything the record names, background "
              "pieces first. That leaves 36 records, and six rooms need all 36.</p>",
              "<h3>Every room</h3>"]
    for room in all_rooms:
        number = room["number"]
        image = castle.draw(number)
        image.save(image_dir / f"room{number:02x}.png")
        backgrounds = ", ".join(
            f'<a href="Scenery.html#scenery{b}">{_esc(kd.BACKGROUND_NAMES[b])}</a>'
            for b in room["backgrounds"]) or "none"
        objects = ", ".join(
            f'<a href="Templates.html#template{t}">{_esc(kd.BLOCK_NAMES[t])}</a>'
            + (f" x{n}" if n > 1 else "") for t, n in room["groups"]) or "none"
        shape = kd.SHAPES.get(room["shape"], str(room["shape"]))
        colour = COLOUR_NAMES.get(room["ink"], str(room["ink"]))
        lines += [f'<div class="kl-item" id="room{number:02x}">',
                  f'<img class="kl-scene" src="images/rooms/room{number:02x}.png" alt="">',
                  f"<p><b>Room ${number:02X}</b> (row {number >> 4}, column {number & 15}): "
                  f"{shape}, {colour} -- #R${room['address']:04X}(its record)</p>",
                  f"<p>Scenery: {backgrounds}.<br>Objects: {objects}.</p>", "</div>"]
    lines.append("</div>")
    return "\n".join(lines)


# The worked example: a frame of room $01, where the ghost drifts and the
# guard marks time, with the player still materialising by the door. The
# first frame of a room draws everything; frame 3 is an ordinary one.
EXAMPLE_ROOM = 0x01
EXAMPLE_FRAME = 3
MATERIALISING = 0x78        # the type the player is given on arriving (lose_life)
END_OF_FRAME = 0xB000
DRAW_AND_COPY_RECTS = 0xD653
RENDER_OBJ = 0xD003
COPY_NEXT_RECT = 0xD666
COPY_RECTS_DONE = 0xD679
OBJECTS_TO_DRAW = 0xCE8B
RECT_COUNT = 0x5BA8
BUFFER = 0xD8F3


def _screen(memory):
    from PIL import Image

    image = Image.new("RGB", (256, 192))
    pixels = image.load()
    for y in range(192):
        row = 0x4000 | ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
        for column in range(32):
            byte = memory[row + column]
            attr = memory[0x5800 + (y >> 3) * 32 + column]
            palette = SPECTRUM_BRIGHT if attr & 0x40 else SPECTRUM
            ink, paper = palette[attr & 7], palette[(attr >> 3) & 7]
            for bit in range(8):
                pixels[column * 8 + bit, y] = ink if byte & (0x80 >> bit) else paper
    return image


def _buffer(memory):
    """The room buffer as a picture: 192 rows of 32 bytes, bottom line first."""
    from PIL import Image

    image = Image.new("RGB", (256, 192))
    pixels = image.load()
    for y in range(192):
        row = BUFFER + (191 - y) * 32
        for column in range(32):
            byte = memory[row + column]
            for bit in range(8):
                pixels[column * 8 + bit, y] = ((255, 255, 255) if byte & (0x80 >> bit)
                                               else (0, 0, 0))
    return image


def _outlined(image, rects, scale: int = 2):
    """The picture at twice the size, each copied rectangle outlined in red."""
    from PIL import Image, ImageDraw

    big = image.resize((image.width * scale, image.height * scale), Image.NEAREST)
    draw = ImageDraw.Draw(big)
    for column, top, width, height in rects:
        draw.rectangle([column * 8 * scale, top * scale,
                        (column + width) * 8 * scale - 1, (top + height) * scale - 1],
                       outline=(255, 64, 64), width=2)
    return big


def trace_frame(castle):
    """Run the example room to its example frame, and follow that frame
    through the renderer: what each stage leaves, and in what order things
    are drawn."""
    from skoolkit.simutils import IXh, IXl, PC, SP

    memory = list(castle.memory)
    # The player alive this time: next_frame_or_die takes empty types in
    # records 0 and 1 for a death and would start the life again elsewhere.
    memory[PLAYER] = memory[PLAYER_TOP] = MATERIALISING
    memory[PLAYER + ROOM_OFFSET] = memory[PLAYER_TOP + ROOM_OFFSET] = EXAMPLE_ROOM
    memory, registers = castle._call(memory, BUILD_SCREEN_OBJECTS, castle.registers)
    sim = castle._machine(memory)
    for index, value in enumerate(registers):
        sim.registers[index] = value
    sim.registers[SP] = OBJECT_STACK
    sim.run(ONSCREEN_LOOP, ONSCREEN_LOOP)          # the room's first frame
    for _ in range(EXAMPLE_FRAME - 2):
        sim.run(ONSCREEN_LOOP, ONSCREEN_LOOP)

    def record(i):
        return PLAYER + 32 * i

    before = _screen(sim.memory)
    start = {i: list(sim.memory[record(i):record(i) + 4]) for i in range(40)
             if sim.memory[record(i)]}
    sim.run(ONSCREEN_LOOP, END_OF_FRAME)
    objects = []
    for i in range(40):
        flags = sim.memory[record(i) + 7]
        if sim.memory[record(i)] and flags & 0x30:
            now = list(sim.memory[record(i):record(i) + 4])
            objects.append({"record": i, "type": now[0], "was": start.get(i, [0])[0],
                            "moved": now[1:] != start.get(i, now)[1:],
                            "wipe": bool(flags & 0x20)})
    sim.run(END_OF_FRAME, DRAW_AND_COPY_RECTS)
    rects = []
    stack = sim.registers[SP]
    for k in range(sim.memory[RECT_COUNT]):
        base = stack + 6 * k
        buffer_address = sim.memory[base] | (sim.memory[base + 1] << 8)
        size = sim.memory[base + 4] | (sim.memory[base + 5] << 8)
        width, height = size >> 8, size & 0xFF
        offset = buffer_address - BUFFER
        bottom = 191 - offset // 32
        rects.append((offset % 32, bottom - height + 1, width, height))
    wiped = _buffer(sim.memory)
    listed = []
    address = OBJECTS_TO_DRAW
    while sim.memory[address] != 0xFF:
        listed.append(sim.memory[address])
        address += 1
    order = []
    for _ in listed:
        sim.run(sim.registers[PC], RENDER_OBJ)
        ix = (sim.registers[IXh] << 8) | sim.registers[IXl]
        order.append((ix - PLAYER) // 32)
    sim.run(sim.registers[PC], COPY_NEXT_RECT)
    drawn = _buffer(sim.memory)
    sim.run(COPY_NEXT_RECT, COPY_RECTS_DONE)
    after = _screen(sim.memory)
    return {"before": before, "wiped": wiped, "drawn": drawn, "after": after,
            "objects": objects, "rects": rects, "order": order}


def _moving_page(castle, comments, image_dir: Path) -> str:
    frame = trace_frame(castle)
    rects = frame["rects"]
    for name in ("before", "wiped", "drawn", "after"):
        _outlined(frame[name], rects).save(image_dir / f"moving_{name}.png")

    def what(t):
        return _esc(re.sub(r"^Type \d+:\s*", "", comments.get(HANDLER_TABLE + 2 * t, "")))

    by_record = {o["record"]: o for o in frame["objects"]}
    moved = [o for o in frame["objects"] if o["wipe"]]
    rows = []
    for position, i in enumerate(frame["order"], 1):
        o = by_record.get(i, {"type": 0, "wipe": False, "moved": False, "was": 0})
        why = ("moved" if o["moved"] else "changed picture" if o["type"] != o["was"]
               else "changed") if o["wipe"] else "overlaps a change"
        rows.append(f"<tr><td>{position}</td><td>{i}</td><td>{o['type']}</td>"
                    f"<td>{what(o['type'])}</td><td>{why}</td></tr>")
    rect_rows = "".join(f"<tr><td>{c * 8}</td><td>{top}</td><td>{w * 8}</td><td>{h}</td></tr>"
                        for c, top, w, h in rects)
    figure = ('<div class="kl-item"><img class="kl-stage" src="images/rooms/moving_{0}.png" '
              'alt=""><p>{1}</p></div>')
    return "\n".join([
        '<div class="kl-list">',
        "<p>Knight Lore never redraws the room. Everything on the screen stays as it "
        "is until something changes, and then only the rectangle the change covers "
        "is rebuilt -- off screen, in depth order -- and copied across. This page "
        "follows one moving object through a frame, from its handler moving it to "
        "the pixels reaching the display, and then shows a real frame of the game "
        "doing it, traced in the game's own code.</p>",
        "<h3>1. Every object gets a turn</h3>",
        "<p>Each frame #R$AFBD walks the forty object records. Before an object's "
        "handler runs, #R$CE49 keeps a copy of where its picture was on the screen "
        "(bytes $18-$1B, the width and height and the pixel position, go to "
        "$1C-$1F): that is the image that may have to be wiped. The handler is "
        "chosen by the object's type, through #R$B096.</p>",
        "<h3>2. The handler moves it</h3>",
        "<p>An object's velocity is in bytes $09-$0B. Gravity is one "
        "<code>DEC</code> of dZ (#R$C700); #R$CB45 then shortens the move against "
        "the room's walls and every other object, one axis at a time -- Z, then X, "
        "then Y -- a unit at a time, so a blocked move slides along what blocks it; "
        "and #R$C706 adds what is left to the position. An object that animates "
        "changes its own type, which is also its sprite: there is no frame number.</p>",
        "<h3>3. It marks itself, and everything it touches</h3>",
        "<p>A handler whose object moved or changed calls #R$C692. That sets two "
        "flags in byte $07 -- bit 5, <i>wipe my old picture</i>, and bit 4, "
        "<i>draw me</i> -- and calls #R$CD4D, which projects the new position "
        "(#R$CD33, through #R$D6C9: pixel x = X + Y - 128, pixel y = (Y - X + 128)/2 "
        "+ Z - 104, counted up from the bottom) and takes the rectangle covering "
        "both the old picture and the new one. Every live object whose picture "
        "overlaps that rectangle gets bit 4 too: it will have to be drawn again, "
        "because the wipe is going to take a bite out of it.</p>",
        "<h3>4. The wipe</h3>",
        "<p>At the end of the frame, #R$CE62 lists every object with bit 4, and "
        "#R$D59F takes each one with bit 5: it clears the rectangle of its old and "
        "new pictures, in whole bytes across and pixel rows up, in the room's "
        "buffer at #R$D8F3 -- never on the screen -- and pushes the rectangle on "
        "the stack to copy later.</p>",
        "<h3>5. Drawing in depth order</h3>",
        "<p>#R$CEBB then draws every listed object into the buffer, back to front. "
        "It picks a candidate, and compares it with each other undrawn object: each "
        "axis is classified as clear one way, overlapping, or clear the other way, "
        "and the 27 combinations are looked up in the table at #R$CF69, which says "
        "whether the other one must go first. If it must, it becomes the candidate; "
        "when a candidate survives the whole list it is drawn. The projection hides "
        "a step of (+1, -1, +1), so further back means smaller X, larger Y and lower "
        "Z. Each object is drawn whole by #R$D718, through its own mask -- the "
        "background is cleared under the mask and the image laid in -- and turned "
        "the way it faces by flipping the sprite's own bytes in place (#R$D865).</p>",
        "<h3>6. Copying the rectangles</h3>",
        "<p>Finally #R$D666 pops each rectangle and #R$D67C copies just that part of "
        "the buffer to the display. Nothing is erased on the display and nothing is "
        "drawn there piece by piece, so nothing flickers; and nothing outside the "
        "rectangles changes. The objects were drawn whole into the buffer, but only "
        "the rectangles are copied, so what lies outside them in the buffer does "
        "not matter -- which is also why marking only the objects that overlap the "
        "rectangle is enough: anything else could not put a pixel inside it.</p>",
        "<h3>7. Pacing</h3>",
        "<p>$5BBE counts the frame's work, objects drawn plus rectangles copied, and "
        "#R$B000 waits six units less that, so a room with little changing runs at "
        "an even speed and a busy one slows down. On entering a room (#R$D1E6) "
        "there is no wipe: every object is drawn into a cleared buffer and the whole "
        "of it is copied, once.</p>",
        f"<h3>A frame of room ${EXAMPLE_ROOM:02X}</h3>",
        f"<p>Frame {EXAMPLE_FRAME} after entering room ${EXAMPLE_ROOM:02X}, run by the "
        "game's own code in a simulator when this page was built. The ghost drifts, "
        "the guard marks time, and the player is still materialising by the door. "
        f"{len(moved)} objects changed, so there are {len(rects)} rectangles, outlined "
        f"in red; {len(frame['order'])} objects are drawn to fill them.</p>",
        figure.format("before", "The screen as the frame begins."),
        figure.format("wiped", "The buffer after the wipe: the rectangles are "
                      "cleared. Around them are leftovers of earlier frames, which "
                      "are never copied."),
        figure.format("drawn", "The buffer after drawing: every flagged object, "
                      "drawn whole, back to front."),
        figure.format("after", "The screen after the rectangles are copied."),
        "<p>The objects drawn, in the order the depth sort chose:</p>",
        '<table class="kl-table"><tr><th>Order</th><th>Record</th><th>Type</th>'
        "<th>What</th><th>Why it is drawn</th></tr>" + "".join(rows) + "</table>",
        "<p>The rectangles copied, in pixels:</p>",
        '<table class="kl-table"><tr><th>x</th><th>y from the top</th><th>Width</th>'
        "<th>Height</th></tr>" + rect_rows + "</table>",
        "</div>"])


def build(memory, skool: Path, html_dir: Path, out_ref: Path, log=print) -> None:
    """Draw the pictures into html_dir/images and write the pages' sections."""
    labels, titles, comments = read_listing(skool)
    sprite_dir = html_dir / "images" / "sprites"
    room_dir = html_dir / "images" / "rooms"
    sprite_dir.mkdir(parents=True, exist_ok=True)
    room_dir.mkdir(parents=True, exist_ok=True)

    log("Drawing the sprites...")
    sprites, pictures = _sprite_pages(memory, labels, titles, sprite_dir)
    log("Drawing the rooms, the scenery and the templates with the game's own code...")
    castle = Castle(memory)
    all_rooms = rooms(memory)
    sections = {
        "Sprites": sprites,
        "Objects": _objects_page(memory, labels, comments, pictures),
        "Templates": _templates_page(memory, castle, titles, all_rooms, room_dir),
        "Scenery": _scenery_page(memory, castle, titles, all_rooms, room_dir),
        "RoomStructure": _rooms_page(memory, castle, all_rooms, room_dir),
        "MovingObjects": _moving_page(castle, comments, room_dir),
    }
    out_ref.write_text("\n\n".join(f"[{name}]\n{body}" for name, body in sections.items())
                       + "\n", encoding="utf-8")
