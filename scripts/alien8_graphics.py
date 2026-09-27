"""Alien 8's graphics pages -- the backgrounds, the object templates, every
graphic and every sprite -- drawn from the game at build time.

build_alien8.py --html calls build(), which draws the pictures into
html_dir/images/graphics/ and returns four ref sections: Scenery, Templates,
Objects and Sprites. Nothing here is committed output: the pictures are the
game's, and so are the lists of what each room uses. What is committed is the
prose, the addresses, and short names for what the pictures show, each given
after looking at the picture.

Three ways of drawing, each the game's own:

- The backgrounds and the object templates are drawn by the game's own code,
  run in SkoolKit's simulator. A game is started the way build_alien8.py's
  sessions start one (its Machine, the keyboard, through the start tune into
  the first room), so the drawing tables are built and the variables are a
  real game's. Then a one-off room record is written first in the room
  directory (#R$6469), where the room builder (#R$CCA7) looks first, the game
  enters the room (#R$CAA2), and its first turn is run from the top of the
  main loop (#R$A68E) to the point where every object has been drawn into the
  buffer and the panel has not (#R$A715 in #R$A6C0). The picture is read out
  of the buffer at $D200, bottom line first. The robot's two records are
  emptied first, so he is not in the pictures, and the room's number is one
  no room has, so nothing from the table of places (#R$76E3) comes into it.
- The panel and the border are drawn the same way: the panel by letting that
  first turn run on through the clock, #R$CB0F and #R$A749, the border by
  #R$CB8A on a cleared buffer. Both are read with the attributes the game
  gave them.
- Sprites and the font are decoded from their bytes as the drawing code
  (#R$D013) and the printer (#R$BBEB) read them, with
  build_alien8.sprite_image -- the same pictures the listing's sprite entries
  show.
"""
from __future__ import annotations

import html
import re
from pathlib import Path

import alien8_data as ad

# Where the game keeps what the pictures need (see their entries).
LEGS = 0x5B88               # the robot's legs; his top is the next record
TOP = 0x5BA8
LEGS_ROOM = 0x5B90          # +8 of the legs' record: the room to build
PLAYED = 0x5B12             # a turn played: entering a room writes the valves back
ENTER_ROOM = 0xCAA2         # build the room the legs' record names
MAIN_TURN = 0xA68E          # the top of a turn
ROOM_DRAWN = 0xA715         # every object drawn into the buffer; the clock and
                            # the panel not yet
PANEL_DRAWN = 0xA724        # the clock, the panel and its colours done
CLEAR_BUFFER = 0xCE7B
PRINT_BORDER = 0xCB8A
BUFFER = 0xD200             # 192 rows of 32 bytes, the bottom line first
ATTRIBUTES = 0x5800
STACK = 0xF100              # the main loop's stack pointer (#R$A692)
TRAP = 0x0000               # a return address nothing in the game reaches
PANEL_ROWS = 64             # the panel's lines at the foot of the screen
PANEL_ROOM_WALL = 4         # the back left wall: the room the panel is drawn under

PANEL_DATA = 0xCB5A         # 12 entries of 4 bytes: graphic, flags, x, y
PANEL_ENTRIES = 12
BORDER_DATA = 0xCBC3        # 8 entries of 4 bytes
BORDER_ENTRIES = 8
SCENE_LOST = 0xB82A         # 5-byte entries (graphic, flags, colour, x, line) to a 0
SCENE_WON = 0xB853
TURN_VIEWS = 0xC1D2         # right turn's four then left turn's four: graphic, flags
TURN_ENDS = 0xC22D
PANEL_ICON = 131            # the one graphic with no update routine

# The update routines, by address, as the listing names them.
NO_UPDATE = 0xA8F0
LEAPER = 0xA8F9
SCENE_ROBOT_TOP = 0xA95A
OILED_ROBOT = 0xA971
FRAGILE = 0xA9B1
REMOTE_ROBOT = 0xA9C7
REMOTE_PAD = 0xAA4D
REMOTE_BUTTON = 0xAA63
SLOW_CHASER = 0xAA89
CLOCKWORK_MOUSE = 0xAAA1
SCENE_TOOL = 0xAB61
SCENE_SPARKS = 0xABF5
COLOUR_SCENE_OBJECT = 0xAC21
CEILING_DROP = 0xAD13
WANTED_VALVE = 0xAE17
SOCKET_SPARKLE = 0xAE33
SEATED_VALVE = 0xAE5D
SOCKET = 0xAE68
CRYONAUT = 0xAE96
LOOSE_VALVE = 0xAF79
LOWER_HALF = 0xB055
WANDERER = 0xB06B
PACER = 0xB110
SPARK_CHASER = 0xB19C
SHUTTLE_V = 0xB21C
SHUTTLE_U = 0xB224
CONVEYORS = (0xB267, 0xB27A, 0xB280, 0xB286)
COLLAPSING_BLOCK = 0xB28C
STILL_DEADLY = 0xB29F
SPIKES = 0xB2A4
DROPPING_BLOCK = 0xB2B6
PUSHABLE = 0xB2FF
PUSHABLE_INVERTED = 0xB31A
LIFT = 0xB31F
BOBBER = 0xB33F
SPARKLE_STEP = 0xB3A4
SPARKLE_END_PLACE = 0xB3B0
SPARKLE_END = 0xB3B8
APPEARING = 0xBC70
APPEARED = 0xBC83
EXTRA_LIFE = 0xBEE0
NUDGES = (0xBF3D, 0xBF51, 0xBF65, 0xBF74)       # whole update routines of 30, 13, 15, 14
SECOND_PILLAR = 0xBFD8
FIRST_PILLAR = 0xBFEA
PLAYER_LEGS = 0xC0BE
TURNING_LEGS = 0xC1E2
TOP_FOLLOWS_LEGS = 0xC6E4

# The room sizes: which walls stand where. A room's walls are its half-size
# from its middle at 128 (#R$6460); the projection (#R$CFD2) puts low U at the
# back left of the picture, high V at the back right, high U at the front
# right and low V at the front left.
SIDE_NAMES = {("U", "low"): "back left", ("V", "high"): "back right",
              ("U", "high"): "front right", ("V", "low"): "front left"}
# Which way walking out through each wall moves the room number (#R$C397,
# #R$C3F0, #R$C40B, #R$C426): along the row, wrapping within it, or a row on
# or back, wrapping round the 256.
EXITS = {"back left": ("the room before it in the row", 0xC397),
         "front right": ("the room after it in the row", 0xC3F0),
         "back right": ("the room 16 on, in the next row", 0xC40B),
         "front left": ("the room 16 back, in the row before", 0xC426)}

# Short names for what each sprite shows, by its address: given after
# drawing each one (a name is a claim, and only the picture backs it). Where
# a name says more than the picture -- which view of the robot -- the code
# that picks the sprite is the evidence, and the Objects page says which.
SPRITE_NAMES = {
    0x7931: "a small domed pod on a round base",
    0x79AB: "a tub of oil, on feet",
    0x7B0B: "a spiky ball",
    0x7BC5: "a round thing with prongs",
    0x7C5D: "a little domed robot with feelers",
    0x7CEF: "a little domed robot with feelers",
    0x7D81: "a little domed robot with feelers",
    0x7E13: "a little domed robot with feelers",
    0x7EA5: "a box with an arrow on its lid",
    0x7F8F: "a box with an arrow on its lid, the other way",
    0x8079: "a clockwork mouse",
    0x8117: "a clockwork mouse",
    0x81B5: "a clockwork mouse",
    0x8253: "a clockwork mouse",
    0x82F1: "a domed column of rings",
    0x83A7: "a domed column of rings",
    0x845D: "a hammer",
    0x84DF: "a glove",
    0x8571: "sparks",
    0x85B5: "a hook",
    0x8661: "a piece of the robot's stand",
    0x8693: "a piece of the robot's stand",
    0x86C5: "half of the frame round the light years",
    0x874B: "a creature's lower half",
    0x87AD: "a spiked dome",
    0x8821: "a crown of spikes on a base",
    0x88B3: "a sloping slab",
    0x897D: "a frozen spaceman",
    0x8A3F: "a bug-eyed creature",
    0x8AD7: "a block with a raised round top",
    0x8BC1: "a block tapering to the bottom",
    0x8C9B: "a plain block",
    0x8D85: "a bug-eyed creature, the other view",
    0x8E1D: "three cylinders on a plate",
    0x8EE7: "a doorway's pillar",
    0x8FE1: "a doorway's other pillar, with the top of the frame",
    0x9103: "a long panel of a hexagon-tiled wall",
    0x9255: "a short panel of the wall",
    0x9327: "a corner of the border",
    0x9429: "a length of the border's top and bottom",
    0x945B: "a length of the border's sides, one pixel high",
    0x9463: "a small square: the panel's edge",
    0x9475: "a piece of the panel's scroll-work",
    0x94A7: "a piece of the panel's scroll-work",
    0x94E9: "a slanting line: the panel's slope",
    0x950B: "a pyramid",
    0x95CD: "a little robot",
    0x9613: "the robot's legs, from the front",
    0x969D: "the robot's top, from the front",
    0x971F: "the robot's legs, from behind",
    0x97A9: "the robot's top, from behind",
    0x982B: "the robot's legs, side-on",
    0x98B5: "the robot's top, side-on",
    0x993F: "the robot's legs",
    0x99C9: "the robot's top",
    0x9A53: "the robot's legs",
    0x9ADD: "the robot's top",
    0x9B67: "the robot's legs",
    0x9BF1: "the robot's top",
    0x9C7B: "the robot's legs",
    0x9D05: "the robot's top",
    0x9D8F: "the robot's legs",
    0x9E19: "the robot's top",
    0x9EA3: "the robot's legs",
    0x9F2D: "the robot's top",
    0x9FB7: "the narrow end of the wall",
    0xA019: "a sparkle, smallest",
    0xA093: "a sparkle",
    0xA113: "a sparkle",
    0xA19F: "a sparkle",
    0xA231: "a sparkle",
    0xA2C3: "a sparkle, largest",
    0xA355: "a domed socket on a plinth",
    0xA41F: "a valve: a drum on feet",
    0xA4B1: "a valve: a cube on feet",
    0xA53D: "a valve: a point on feet",
    0xA5B1: "a valve: a ball on feet",
}

# Graphics the code gives an object itself, rather than a table: each read
# from the routine named (the listing has the instruction).
CODE_MADE = [
    ([1], "an object on its way out: picked up (#R$BD6B) or at a sparkle's end (#R$B3B0); "
          "emptied when next drawn (#R$D013)"),
    ([22, 38], "the legs and the top as a game starts (#R$CA6D)"),
    (range(16, 24), "the legs' step frames (#R$C25E) and a turn's end (#R$C22D, #R$C235)"),
    (range(24, 28), "the in-between view of a turn (#R$C1D2, #R$C1DA)"),
    (range(32, 44), "the top: the legs' graphic plus 16 (#R$C6E4)"),
    ([48], "his death: the first frame of the sparkle (#R$B39A)"),
    (range(49, 56), "the sparkle's next frame (#R$B3A4)"),
    ([54], "a thing that breaks, when moved (#R$A9B1)"),
    ([56], "the robot appearing: at a new life (#R$CA07), and through a doorway (the end "
           "of #R$C397)"),
    (range(57, 64), "the appearing's next frame (#R$BC70)"),
    ([64], "an extra life touched (#R$BEE0), or a block landed on (#R$B28C)"),
    ([65], "the vanish's second frame (#R$B3A4)"),
    ([86, 87, 94, 95], "a creature turning: bit 0 of the graphic is half its facing "
                       "(#R$B0AD, #R$B1AE)"),
    (range(77, 80), "the chaser's next frame (#R$B19C)"),
    (range(117, 120), "a mouse's frames and turns (#R$AAA1)"),
    ([121], "the chaser's other frame (#R$AA89)"),
    (range(125, 128), "a remote robot's frames as it walks (#R$A9C7)"),
    ([12] + list(range(96, 100)), "dealt to the places at every new game (#R$AF3F)"),
    (range(100, 104), "a valve seated in its socket: its graphic plus 4 (#R$AF79)"),
    (range(104, 108), "the sparkle showing the valve wanted: its graphic less 4 (#R$AE33)"),
    (range(108, 112), "the sparkle again after the picture (#R$AE17), or brought back "
                      "(#R$AE68)"),
]

INKS = [(0, 0, 0), (0, 0, 0xD7), (0xD7, 0, 0), (0xD7, 0, 0xD7),
        (0, 0xD7, 0), (0, 0xD7, 0xD7), (0xD7, 0xD7, 0), (0xD7, 0xD7, 0xD7)]
BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF),
          (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0), (0xFF, 0xFF, 0xFF)]
WHITE = (0xFF, 0xFF, 0xFF)
INK_WHITE = 7
SPRITE_SCALE = 2
PIECE_SCALE = 2
FONT_SCALE = 3
IMAGES = "images/graphics"


def _word(memory, address: int) -> int:
    return memory[address] | memory[address + 1] << 8


def _esc(text: str) -> str:
    return html.escape(text, quote=False)


def _plural(count: int, word: str, words: str | None = None) -> str:
    return f"{count} {word if count == 1 else (words or word + 's')}"


def _room_link(number: int) -> str:
    return f'<a href="RoomStructure.html#room{number:02x}">${number:02X}</a>'


def _rooms_text(numbers) -> str:
    return ", ".join(_room_link(n) for n in sorted(set(numbers)))


def _template_name(index: int) -> str:
    """Page 1's templates by the header's number; page 2's as the number
    after a template-31 header, written 2:n (as alien8_data.py does)."""
    return str(index) if index < 32 else f"{index} (page 2, number {index - 32})"


# --------------------------------------------------------------------------
# The listing: which addresses are entries, and what they are called.
# --------------------------------------------------------------------------

class Listing:
    """Entry starts, labels and titles from alien8.skool, so that a #R link
    is made only to an entry that exists."""

    def __init__(self, skool: Path):
        self.labels: dict[int, str] = {}      # entries' and entry points' labels
        self.titles: dict[int, str] = {}      # entries only
        self.missing = set()                  # #R links dropped for want of an entry
        self.entries: list[int] = []
        comment, label = [], None
        if not skool.exists():
            return
        for line in skool.read_text(encoding="utf-8").splitlines():
            if line.startswith("@label="):
                label = line[7:].strip()
                continue
            if line.startswith("@"):
                continue
            if line.startswith(";"):
                comment.append(line[2:])
                continue
            match = re.match(r"^([bcgistuw* ])\$([0-9A-F]{4})", line)
            if match:
                address = int(match.group(2), 16)
                if match.group(1) not in "* ":
                    self.titles[address] = comment[0] if comment else ""
                if label:
                    self.labels[address] = label
            comment, label = [], None
        self.entries = sorted(self.titles)

    def entry_of(self, address: int) -> int | None:
        found = None
        for entry in self.entries:
            if entry > address:
                break
            found = entry
        return found

    def ref(self, address: int, text: str | None = None) -> str:
        """#R$ADDR (with its text) for an entry, plain $ADDR otherwise."""
        if address in self.titles:
            return f"#R${address:04X}({text})" if text else f"#R${address:04X}"
        return text or f"${address:04X}"

    def routine(self, address: int) -> str:
        """A routine by its label, linked: an entry point inside an entry is
        named, and its entry linked."""
        name = self.labels.get(address, f"${address:04X}")
        if address in self.titles:
            return f"#R${address:04X}({name})"
        entry = self.entry_of(address)
        if entry is None:
            return name
        return f"{name}, in #R${entry:04X}({self.labels.get(entry, f'${entry:04X}')})"

    def name(self, address: int) -> str:
        return self.labels.get(address, f"${address:04X}")

    def check_links(self, body: str) -> str:
        """Every #R to an address that is not an entry start made plain, and
        noted, so that a page never links to nothing."""
        def fix(match):
            address = int(match.group(1), 16)
            if not self.titles or address in self.titles:
                return match.group(0)
            self.missing.add(address)
            return match.group(2)[1:-1] if match.group(2) else f"${address:04X}"
        return re.sub(r"#R\$([0-9A-F]{4})(\([^()]*\))?", fix, body)


# --------------------------------------------------------------------------
# The game's data, read.
# --------------------------------------------------------------------------

class Data:
    """The tables the pages are made from, read from the snapshot as the
    game's own code reads them (see alien8_data.py for each walk)."""

    def __init__(self, memory):
        self.memory = memory
        self.rooms = ad.room_records(memory)
        self.sizes = [ad.room_size(memory, i) for i in range(ad.SIZE_COUNT)]
        self.room_size = {room["number"]: room["size"] for room in self.rooms}
        # Backgrounds: each index's address and 8-byte pieces, up to the zero.
        self.backgrounds = []
        for index in range(ad.BACKGROUND_COUNT):
            address = _word(memory, ad.BACKGROUND_TABLE + 2 * index)
            pieces, piece = [], address
            while memory[piece]:
                pieces.append(list(memory[piece:piece + 8]))
                piece += 8
            self.backgrounds.append((address, pieces))
        # Object templates: 5-byte parts for as long as the byte after one is
        # not zero (#R$CD40); indices 0, 31 and 32 have no template.
        self.templates: dict[int, tuple[int, list[list[int]]]] = {}
        for index in range(ad.OBJECT_COUNT):
            address = _word(memory, ad.OBJECT_TABLE + 2 * index)
            if not address:
                continue
            parts, part = [], address
            while True:
                parts.append(list(memory[part:part + 5]))
                part += 5
                if memory[part] == 0:
                    break
            self.templates[index] = (address, parts)
        self.sprite_of = [_word(memory, ad.GRAPHICS + 2 * g) for g in range(ad.GRAPHIC_COUNT)]
        self.handler_of = [_word(memory, ad.HANDLERS + 2 * g) if g < ad.HANDLER_COUNT else None
                           for g in range(ad.GRAPHIC_COUNT)]
        self.sprites = ad.sprite_entries(memory)
        # Who uses what: rooms by background, and by template with the copies
        # and whether a placement nudge was in force.
        self.background_rooms: dict[int, list[int]] = {}
        self.template_rooms: dict[int, list[tuple[int, int, int]]] = {}
        self.nudges: list[tuple[int, int]] = []
        for room in self.rooms:
            for _, background in room["backgrounds"]:
                self.background_rooms.setdefault(background, []).append(room["number"])
            page, nudge = 0, 0
            for _, template, _, positions in room["groups"]:
                if template == 0:
                    nudge = positions[0]
                    self.nudges.append((room["number"], nudge))
                    continue
                if template == 31:
                    page = 32
                    continue
                self.template_rooms.setdefault(page + template, []).append(
                    (room["number"], len(positions), nudge))
        self.panel = [list(memory[PANEL_DATA + 4 * i:PANEL_DATA + 4 * i + 4])
                      for i in range(PANEL_ENTRIES)]
        self.border = [list(memory[BORDER_DATA + 4 * i:BORDER_DATA + 4 * i + 4])
                       for i in range(BORDER_ENTRIES)]
        self.scene_lost = self._scene(SCENE_LOST)
        self.scene_won = self._scene(SCENE_WON)
        self.turn_views = sorted({memory[TURN_VIEWS + 2 * i] for i in range(8)})
        self.turn_ends = sorted({memory[TURN_ENDS + 2 * i] for i in range(8)})

    def _scene(self, address: int) -> list[list[int]]:
        """A scene's list as #R$B804 reads it: five bytes an entry to a zero."""
        entries = []
        while self.memory[address]:
            entries.append(list(self.memory[address:address + 5]))
            address += 5
        return entries

    def background_side(self, index: int) -> str:
        """The wall a background stands along: the side most of its pieces
        are furthest out on. A thin wall piece is flat across the wall (a
        half-size of 0 across it); a pillar stands on whichever axis it is
        further from the middle along."""
        sides = []
        for p in self.backgrounds[index][1]:
            if p[4] == 0 or (p[5] != 0 and abs(p[1] - 128) > abs(p[2] - 128)):
                sides.append(SIDE_NAMES[("U", "low" if p[1] < 128 else "high")])
            else:
                sides.append(SIDE_NAMES[("V", "low" if p[2] < 128 else "high")])
        return max(set(sides), key=sides.count), sides

    def size_for_background(self, index: int) -> int:
        """The room size a background is drawn in: the one most of its rooms
        have."""
        counts: dict[int, int] = {}
        for number in self.background_rooms.get(index, []):
            size = self.room_size[number]
            counts[size] = counts.get(size, 0) + 1
        return max(counts, key=lambda s: (counts[s], -s)) if counts else 0

    def uses_of(self, graphic: int, listing: Listing) -> list[str]:
        """Where a graphic comes from: the tables that name it, and the code
        that gives it to an object."""
        out = []
        backgrounds = [i for i, (_, pieces) in enumerate(self.backgrounds)
                       if any(p[0] == graphic for p in pieces)]
        if backgrounds:
            out.append("background " + ", ".join(
                f'<a href="Scenery.html#background{i}">{i}</a>' for i in backgrounds))
        templates = [i for i, (_, parts) in self.templates.items()
                     if any(p[0] == graphic for p in parts)]
        if templates:
            out.append("object template " + ", ".join(
                f'<a href="Templates.html#template{i}">{i}</a>'
                + (f" ({_plural(len({r for r, _, _ in self.template_rooms[i]}), 'room')})"
                   if i in self.template_rooms else " (no room)") for i in templates))
        panel = [i for i, entry in enumerate(self.panel) if entry[0] == graphic]
        if panel:
            out.append(f"the panel ({listing.ref(PANEL_DATA)}, "
                       f"{_plural(len(panel), 'entry', 'entries')})")
        if any(entry[0] == graphic for entry in self.border):
            out.append(f"the border of the text screens ({listing.ref(BORDER_DATA)})")
        if any(entry[0] == graphic for entry in self.scene_lost):
            out.append(f"the scene after a lost game ({listing.ref(SCENE_LOST)})")
        if any(entry[0] == graphic for entry in self.scene_won):
            out.append(f"the scene after a won game ({listing.ref(0xB852, 'SCENE_WON')})")
        for graphics, what in CODE_MADE:
            if graphic in graphics:
                out.append(what)
        if 96 <= graphic < 100:
            out.append("drawn on the panel while carried (#R$BC9D)")
        return out


# --------------------------------------------------------------------------
# Drawing with the game's own code.
# --------------------------------------------------------------------------

TIME_LIMIT = 3500000 * 5    # five seconds of the machine's time for any one run


def _run(simulator, start: int, stop: int, what: str) -> None:
    """Run from start to stop, or fail saying where the game went instead: a
    run that never reaches its stop is a staging mistake, not a picture."""
    from skoolkit.simutils import PC, T

    simulator.trace(start, stop, 0, simulator.registers[T] + TIME_LIMIT, False,
                    None, None, None, None, None)
    if simulator.registers[PC] != stop:
        raise RuntimeError(f"graphics: {what} never reached ${stop:04X} "
                           f"(PC ${simulator.registers[PC]:04X})")


class Stage:
    """A game started as a player starts one, ready to build and draw a
    one-off room with the game's own room builder and drawing code."""

    def __init__(self, snapshot: Path, data: Data):
        import build_alien8 as ba

        machine = ba.Machine(snapshot)
        machine.play(ba._start("1"), "the graphics pages")
        self.memory = list(machine.memory)
        self.tracer_class = type(machine.tracer)
        numbers = {room["number"] for room in data.rooms}
        # A number no room has, so the one-off record is the only match and
        # no place (#R$76E3) is in it.
        self.room = min(n for n in range(256) if n not in numbers)

    def record(self, size: int, backgrounds: list[int], groups: list[tuple[int, list[int]]]) -> list[int]:
        """A room record: number, the count, the size and colour byte (white,
        both copies of the colour), the backgrounds, and -- if there are any
        -- $FF and the groups, each a header byte and the bytes after it.
        The count is of the bytes from itself to the end, as #R$CCA7 reads
        it (alien8_data.room_records)."""
        body = [size << 6 | INK_WHITE << 3 | INK_WHITE] + list(backgrounds)
        if groups:
            body.append(0xFF)
            for header, rest in groups:
                body += [header] + list(rest)
        return [self.room, len(body) + 1] + body

    def _simulator(self, record: list[int] | None):
        from skoolkit import CSimulator
        from skoolkit.simulator import Simulator
        from skoolkit.simutils import SP

        memory = list(self.memory)
        memory[LEGS] = memory[TOP] = 0            # no robot in the picture
        memory[PLAYED] = 0                        # nothing to write back
        if record:
            memory[LEGS_ROOM] = record[0]
            memory[ad.ROOMS:ad.ROOMS + len(record)] = record
        memory[STACK - 2:STACK] = [TRAP & 0xFF, TRAP >> 8]
        simulator = (CSimulator or Simulator)(memory, state={"iff": 0, "im": 1, "tstates": 0})
        simulator.set_tracer(self.tracer_class(simulator))
        simulator.registers[SP] = STACK - 2
        # IX on the legs, as the main loop has it when it enters a room.
        simulator.registers[8], simulator.registers[9] = LEGS >> 8, LEGS & 0xFF
        return simulator

    def _enter(self, record: list[int]):
        from skoolkit.simutils import SP

        simulator = self._simulator(record)
        _run(simulator, ENTER_ROOM, TRAP, "entering the room")
        simulator.registers[SP] = STACK
        _run(simulator, MAIN_TURN, ROOM_DRAWN, "the room's first turn")
        return simulator

    def draw(self, record: list[int]):
        """The room the record describes, as the game draws it on its first
        turn there, before the panel goes in: white on black, cut down to
        what was drawn."""
        return _cropped(_buffer_image(self._enter(record).memory, None))

    def panel(self):
        """The panel as the first turn in an empty room leaves it: the
        clock, #R$CB0F's pieces, and #R$A749's colours and numbers."""
        # One background, a back wall, well clear of the panel: a record with
        # none would leave the builder's byte count at zero, and its DJNZ over
        # the backgrounds would take that as 256.
        simulator = self._enter(self.record(0, [PANEL_ROOM_WALL], []))
        _run(simulator, ROOM_DRAWN, PANEL_DRAWN, "the panel")
        image = _buffer_image(simulator.memory, simulator.memory)
        return image.crop((0, 192 - PANEL_ROWS, 256, 192))

    def border(self):
        """The border of the text screens, by #R$CB8A on a cleared buffer,
        in the bright red the menu and the end screens give it."""
        from skoolkit.simutils import SP

        simulator = self._simulator(None)
        _run(simulator, CLEAR_BUFFER, TRAP, "clearing the buffer")
        simulator.registers[SP] = STACK - 2
        _run(simulator, PRINT_BORDER, TRAP, "the border")
        return _buffer_image(simulator.memory, None, BRIGHT[2])


def _buffer_image(memory, attributes, colour=WHITE):
    """The screen buffer at $D200 as a picture, the bottom line first in
    memory; coloured by the attribute file if one is given."""
    from PIL import Image

    image = Image.new("RGB", (256, 192))
    pixels = image.load()
    for y in range(192):
        row = BUFFER + (191 - y) * 32
        for column in range(32):
            byte = memory[row + column]
            ink, paper = colour, (0, 0, 0)
            if attributes is not None:
                attr = attributes[ATTRIBUTES + (y // 8) * 32 + column]
                table = BRIGHT if attr & 0x40 else INKS
                ink, paper = table[attr & 7], table[attr >> 3 & 7]
            for bit in range(8):
                pixels[column * 8 + bit, y] = ink if byte & (0x80 >> bit) else paper
    return image


def _cropped(image, margin: int = 8):
    """A one-off scene cut down to what was drawn in it, with a margin."""
    box = image.convert("L").point(lambda v: 255 if v else 0).getbbox()
    if not box:
        return image
    left, top, right, bottom = box
    return image.crop((max(0, left - margin), max(0, top - margin),
                       min(image.width, right + margin), min(image.height, bottom + margin)))


def _piece_img(path: str, image, alt: str, scale: int = PIECE_SCALE) -> str:
    return (f'<img class="kl-piece" src="{path}" alt="{_esc(alt)}" '
            f'width="{image.width * scale}" height="{image.height * scale}">')


def _flags(flags: int) -> str:
    """An object's flags (+$07) as a template or background sets them."""
    names = {0x02: "out of collisions", 0x04: "pushable", 0x10: "to be drawn",
             0x40: "mirrored", 0x80: "upside down"}
    bits = [name for bit, name in names.items() if flags & bit]
    other = flags & ~sum(names)
    if other:
        bits.append(f"other bits ${other:02X}")
    return f"${flags:02X}" + (f" ({', '.join(bits)})" if bits else "")


# --------------------------------------------------------------------------
# Scenery: the backgrounds.
# --------------------------------------------------------------------------

def _background_kind(data: Data, index: int) -> tuple[str, str]:
    """(group, name) for a background, from its pieces: which graphics, which
    wall they stand along, and how high."""
    pieces = data.backgrounds[index][1]
    graphics = {p[0] for p in pieces}
    floor = data.sizes[data.size_for_background(index)][2]
    side, sides = data.background_side(index)
    if graphics <= {2, 3}:
        z = pieces[0][3]
        if z > floor:
            return "raised", f"A doorway in the {side} wall, raised {z - floor} above the floor"
        return "doorways", f"A doorway in the {side} wall"
    if graphics <= {30}:
        return "raised", f"Two blocks at a height of {pieces[0][3] - floor}, against the {side} wall"
    whole = [p for p, s in zip(pieces, sides) if s == side]
    # A wall of constant U runs along V (+2), one of constant V along U (+1).
    axis = 2 if side in ("back left", "front right") else 1
    along = sorted(p[axis] for p in whole)
    gap = any(b - a > 24 for a, b in zip(along, along[1:]))
    name = f"The {side} wall"
    if gap:
        name += ", with a gap in the middle for a doorway"
    others = sorted(set(s for s in sides if s != side))
    if others:
        name += f"; and two short pieces of the {others[0]} wall, either side of its doorway"
    return "walls", name


def _scenery_page(data: Data, stage: Stage, listing: Listing, image_dir: Path) -> str:
    groups = {"doorways": [], "raised": [], "walls": []}
    for index in range(ad.BACKGROUND_COUNT):
        group, name = _background_kind(data, index)
        groups[group].append((index, name))
    # The raised doorways and the blocks they stand on come in pairs, always
    # in the same rooms.
    partner = {}
    for index, _ in groups["raised"]:
        rooms = sorted(set(data.background_rooms.get(index, [])))
        for other, _ in groups["raised"]:
            if other != index and sorted(set(data.background_rooms.get(other, []))) == rooms:
                partner[index] = other

    def item(index: int, name: str) -> list[str]:
        address, pieces = data.backgrounds[index]
        size = data.size_for_background(index)
        half_u, half_v, floor = data.sizes[size]
        image = stage.draw(stage.record(size, [index], []))
        picture = f"background{index:02d}.png"
        image.save(image_dir / picture)
        rows = "".join(
            f'<tr><td><a href="Objects.html#graphic{p[0]}">{p[0]}</a></td><td>{p[1]}</td>'
            f"<td>{p[2]}</td><td>{p[3]}</td><td>{p[4]}, {p[5]}; {p[6]}</td>"
            f"<td>{_flags(p[7])}</td></tr>" for p in pieces)
        rooms = data.background_rooms.get(index, [])
        lines = [f'<div class="kl-item" id="background{index}">',
                 _piece_img(f"{IMAGES}/{picture}", image, f"Background {index}"),
                 f"<p><b>{index}: {_esc(name)}</b> -- {listing.ref(address)}; drawn in a "
                 f"room of size {size} ({2 * half_u} by {2 * half_v}, walls at U "
                 f"{128 - half_u} and {128 + half_u}, V {128 - half_v} and {128 + half_v}).</p>"]
        notes = []
        side, _ = data.background_side(index)
        if {p[0] for p in pieces} <= {2, 3}:
            leads, exit_routine = EXITS[side]
            mirrored = bool(pieces[0][7] & 0x40)
            notes.append(f"Graphic 2 is the working pillar ({listing.ref(FIRST_PILLAR)}), "
                         f"graphic 3 only draws ({listing.ref(SECOND_PILLAR)}); "
                         + ("both are mirrored, as a doorway in a wall of constant V is. "
                            if mirrored else "neither is mirrored, as in a wall of constant U. ")
                         + f"The doorway's middle is at 128 along the wall. Walking out through "
                         f"it takes him to {leads} ({listing.ref(exit_routine)}): where it "
                         "leads comes from the room's number, not from the background.")
            if pieces[0][3] > floor:
                notes.append(f"Coming in through it, he is stood at its height, found from "
                             f"its first pillar ({listing.ref(0xCC6D)}).")
        if index in partner:
            other = partner[index]
            if {p[0] for p in pieces} <= {30}:
                notes.append(f'Always in the same rooms as <a href="#background{other}">'
                             f"background {other}</a>, the raised doorway in the same wall: the "
                             f"blocks' tops, at {pieces[0][3] + pieces[0][6] - floor} above the floor, "
                             "are the step it stands on.")
            else:
                pair = stage.draw(stage.record(size, [index, other], []))
                pair_name = f"background{index:02d}_{other:02d}.png"
                pair.save(image_dir / pair_name)
                notes.append(f'Always with <a href="#background{other}">background {other}</a>, '
                             "the two blocks under it; the two together, as the game draws "
                             "them in one room:</p><p>"
                             + _piece_img(f"{IMAGES}/{pair_name}", pair,
                                          f"Backgrounds {index} and {other} together"))
        if notes:
            lines.append("<p>" + " ".join(notes) + "</p>")
        lines.append('<table class="kl-table"><tr><th>Graphic</th><th>U</th><th>V</th>'
                     "<th>Z</th><th>Half U, V; height</th><th>Flags</th></tr>" + rows + "</table>")
        if rooms:
            sizes = sorted({data.room_size[r] for r in rooms})
            lines.append(f"<p>In {_plural(len(set(rooms)), 'room')}"
                         + (f" (of sizes {' and '.join(str(s) for s in sizes)})" if len(sizes) > 1 else "")
                         + f": {_rooms_text(rooms)}.</p>")
        else:
            lines.append("<p>No room uses it.</p>")
        lines.append("</div>")
        return lines

    counts = {key: len(value) for key, value in groups.items()}
    order = sorted(range(ad.BACKGROUND_COUNT), key=lambda i: data.backgrounds[i][0])
    lines = ['<div class="kl-list">',
             f"<p>A background is what a room lists first in its record, a byte each up to "
             f"an $FF: an index into the {ad.BACKGROUND_COUNT} words of "
             f"{listing.ref(ad.BACKGROUND_TABLE)}. Each is a list of eight-byte pieces -- "
             "graphic, U, V, Z, the half-sizes in U and V, the height and the flags -- ended "
             f"by a zero, and the builder ({listing.ref(0xCCA7)}) copies every piece into an "
             "object record of its own as it is, with the room's number as its +8. So a "
             "background carries its own position, and always stands in the same place: "
             "each is made for a wall of a room of one size. The three sizes at "
             f"{listing.ref(ad.SIZES)} are "
             + ", ".join(f"{2 * h_u} by {2 * h_v} (size {i})" for i, (h_u, h_v, _) in enumerate(data.sizes))
             + ", U by V, about the middle of the room at 128: a room's walls stand its "
             "half-size either side of 128.</p>",
             f"<p>There are {counts['doorways']} doorways, one for each wall; "
             f"{counts['walls']} walls -- the two back walls whole or with a gap for a "
             "doorway, and the long back wall of each narrow room with the stubs of the "
             "short one -- and two doorways raised off the floor with the blocks each stands "
             "on. Only the two back walls are ever drawn: the front of a room is open, as in "
             "Knight Lore. The table's words are not in the order of the bytes: they run "
             + ", ".join(str(i) for i in order)
             + ", so each raised doorway sits next to its blocks.</p>",
             "<p>A doorway is not joined to anything by its data. The rooms are Knight "
             "Lore's grid of 16 by 16 numbers, and walking out through a wall moves the "
             "room number by 1 along the row or by 16 to the next or last row, whichever "
             "doorway it was; the background only puts the pillars in the wall. Every "
             "doorway in the game leads to a room that exists and has the doorway back "
             "(checked from the room directory).</p>",
             "<p>Each background is drawn here by the game, on its own: a one-off room "
             "record naming just that background, in a room of the size most of its rooms "
             f"have, is written first in the room directory ({listing.ref(ad.ROOMS)}), and "
             f"the game builds the room ({listing.ref(ENTER_ROOM)}) and draws its first "
             f"turn ({listing.routine(MAIN_TURN)}), in SkoolKit's simulator. The pictures are white "
             "whatever the rooms' own colours. On the screen low U is at the back left, "
             "high V at the back right, high U at the front right and low V at the front "
             f"left ({listing.ref(0xCFD2)}).</p>",
             '<p>Knight Lore builds its rooms the same way from its own backgrounds, one '
             'byte each in the room\'s record (see <a href="../knightlore/Scenery.html">Knight '
             "Lore's scenery</a>); Pentagram gives each background a second byte, the room "
             'its doorway leads to (see <a href="../pentagram/Scenery.html">Pentagram\'s '
             "scenery</a>). Alien 8 is Knight Lore's way round.</p>"]
    for key, title in (("doorways", "Doorways"), ("raised", "Raised doorways and their steps"),
                       ("walls", "Walls")):
        lines.append(f"<h3>{title}</h3>")
        for index, name in groups[key]:
            lines += item(index, name)
    lines.append("</div>")
    return "\n".join(lines)


# --------------------------------------------------------------------------
# Object templates.
# --------------------------------------------------------------------------

# What a template's first graphic does, for its name: the picture says what
# it looks like, the routine what kind of thing it is.
TEMPLATE_KIND = {
    PUSHABLE: "that can be pushed",
    PUSHABLE_INVERTED: "that can be pushed",
    BOBBER: "that bobs up and down",
    DROPPING_BLOCK: "that sinks while stood on",
    COLLAPSING_BLOCK: "that collapses when landed on",
    SPIKES: ", deadly",
    CONVEYORS[0]: "that carries things forwards in V",
    CONVEYORS[1]: "that carries things forwards in U",
    CONVEYORS[2]: "that carries things back in V",
    CONVEYORS[3]: "that carries things back in U",
    LIFT: "that lifts",
    SHUTTLE_U: "that shuttles in U",
    SHUTTLE_V: "that shuttles in V",
    STILL_DEADLY: ", deadly",
    WANDERER: "that wanders, on a lower half",
    PACER: "that paces to and fro, on a lower half",
    CEILING_DROP: "that drops from the ceiling",
    CRYONAUT: ": a cryonaut",
    CLOCKWORK_MOUSE: "",
    SLOW_CHASER: "that homes in on him",
    REMOTE_ROBOT: ": a remote-controlled robot",
    REMOTE_BUTTON: ": a remote-control button",
    REMOTE_PAD: ": the remote-control pad",
    FRAGILE: "that breaks when moved",
    LEAPER: "that leaps",
}


def template_title(data: Data, names: dict[int, str], parts: list[list[int]]) -> str:
    """A template's name: its first graphic's picture, what its routine makes
    of it, and anything its flags or a second part add."""
    graphic, flags = parts[0][0], parts[0][4]
    handler = data.handler_of[graphic]
    name = names.get(graphic) or f"graphic {graphic}"
    if handler == SOCKET:
        valve = graphic - 16
        shape = names.get(valve, "").replace("a valve: ", "").replace(" on feet", "")
        name = f"{name}, for the valve of graphic {valve} ({shape})"
    elif handler == SPARK_CHASER:
        name = "a crackle of sparks that chases him (the sparkle's sprites)"
    kind = TEMPLATE_KIND.get(handler, "")
    if kind.startswith((":", ",")):
        name += kind
    elif kind:
        name += (", " if "," in name else " ") + kind
    if flags & 0x40:
        name += "; mirrored"
    return name[0].upper() + name[1:]


def _templates_page(data: Data, stage: Stage, listing: Listing, image_dir: Path,
                    names: dict[int, str]) -> str:
    # One copy near the middle of the room, on the floor: cell (3, 3), level 0.
    middle = 3 | 3 << 3
    page_two = [i for i in data.templates if i >= 32]
    nudged = [(r, n) for r, n in data.nudges if n]
    nudge_values = sorted({n for _, n in data.nudges})
    # The nudge drawn: a column of four of template 1 at levels 0 to 3, then
    # the nudge of 48 and the same four again, which stand on top of them.
    column = [middle | level << 6 for level in range(4)]
    nudge_record = stage.record(0, [], [(1 << 3 | 3, column), (0, [0x30]), (1 << 3 | 3, column)])
    nudge_image = stage.draw(nudge_record)
    nudge_image.save(image_dir / "nudge.png")
    lines = ['<div class="kl-list">',
             f"<p>The {len(data.templates)} kinds of thing a room record can place: the "
             f"templates the builder ({listing.ref(0xCCA7)}) makes object records from, after "
             "the backgrounds and the $FF that ends them. A room gives a group header -- bits "
             f"3-7 a template number, an index into {listing.ref(ad.OBJECT_TABLE)}, and bits "
             "0-2 how many copies less one -- then a position byte for each copy: U = 72 + 16 "
             "times bits 0-2, V = 72 + 16 times bits 3-5, and Z the floor plus 12 times bits "
             "6-7, so a room is an 8 by 8 grid of cells, four levels high. The count at +1 of "
             "the record, not the data, ends the build: a group can be cut short by it.</p>",
             "<p>A template is a list of five-byte parts ended by a zero: the graphic, the "
             "half-sizes in U and V, the height (Z is an object's base, not its middle) and "
             "the flags, which go to +0 and +4 to +7 of a record, the position to +1 to +3 "
             f"and the room to +8. Most have one part; {sum(1 for _, p in data.templates.values() if len(p) > 1)} "
             "have two at the same place: the creatures that walk on a separate lower half, "
             "and the chambers' sockets with the sparkle over them. The graphic decides "
             "everything else, its update routine and its sprite (see "
             '<a href="Objects.html">every graphic</a>).</p>',
             f'<h3 id="pages">Two pages of templates</h3>',
             f"<p>A header can name 32 templates, and the game has more. The table at "
             f"{listing.ref(ad.OBJECT_TABLE)} is {ad.OBJECT_COUNT} words: header number 31 is not "
             "a template but moves the builder's TEMPLATES_AT on 64 bytes, to the words from "
             "number 32 on, for the rest of the room, and the byte after it is skipped. So "
             f"templates {page_two[0]} to {page_two[-1]} are header numbers {page_two[0] - 32} to "
             f"{page_two[-1] - 32} after a 31; they are listed here by their place in the "
             "table. Words 0, 31 and 32 are zero: a header number of 0 is the placement nudge, "
             "below, on either page, so neither page's word 0 is ever read, and 31 is the "
             "switch. The "
             f"rooms switch pages {sum(1 for room in data.rooms for g in room['groups'] if g[1] == 31)} "
             "times; the second page holds the remote-control buttons and pad, the things "
             "that break and the leapers.</p>",
             '<h3 id="nudge">The placement nudge</h3>',
             _piece_img(f"{IMAGES}/nudge.png", nudge_image, "Eight blocks in a column"),
             "<p>Header number 0 is not a template either: the byte after it becomes "
             f"PLACE_NUDGE for the groups that follow ({listing.ref(0xCCA7)}): its bit 0 adds 8 "
             "to U, bit 1 adds 8 to V, and the rest of it is added to Z. The rooms set it "
             f"{len(data.nudges)} times, always to "
             + " or ".join(f"${n:02X}" for n in nudge_values)
             + f": {len(nudged)} times $30, which lifts what follows by 48, four levels, so "
             "that a room can stack things eight levels high; the bits that move a thing half "
             "a cell are never used. Pentagram's builder has the same code with no jump "
             'to it (see <a href="../pentagram/Templates.html">Pentagram\'s templates</a>); '
             "here it is live. The picture is the game's: a one-off room with four of "
             "template 1 at levels 0 to 3 of one cell, the nudge of $30, and the same four "
             "again, which land on top of the first.</p>",
             '<h3 id="templates">The templates</h3>',
             "<p>Each is drawn here by the game, on its own near the middle of an empty "
             "room (cell 3, 3, on the floor), from a one-off room record the game builds and "
             "draws its first turn of, in SkoolKit's simulator; a thing that moves has had "
             "one turn, and one that the rooms always raise with the nudge is drawn on the "
             "floor all the same. Knight Lore's templates are the same idea with a sixth "
             'byte, an offset (see <a href="../knightlore/Templates.html">Knight Lore\'s '
             "templates</a>).</p>"]
    for index, (address, parts) in data.templates.items():
        if index >= 32:
            groups = [(31 << 3, [0]), ((index - 32) << 3, [middle])]
        else:
            groups = [(index << 3, [middle])]
        image = stage.draw(stage.record(0, [], groups))
        picture = f"template{index:02d}.png"
        image.save(image_dir / picture)
        users = data.template_rooms.get(index, [])
        rooms = sorted({r for r, _, _ in users})
        copies = sum(n for _, n, _ in users)
        raised = sum(n for _, n, nudge in users if nudge)
        name = template_title(data, names, parts)
        rows = "".join(
            f'<tr><td><a href="Objects.html#graphic{g}">{g}</a></td>'
            f"<td>{su}, {sv}; {sz}</td><td>{_flags(flags)}</td>"
            f"<td>{listing.routine(data.handler_of[g])}</td></tr>"
            for g, su, sv, sz, flags in parts)
        lines += [f'<div class="kl-item" id="template{index}">',
                  _piece_img(f"{IMAGES}/{picture}", image, f"Object template {index}"),
                  f"<p><b>{_esc(_template_name(index))}: {_esc(name)}</b>"
                  f" -- {listing.ref(address)}</p>",
                  '<table class="kl-table"><tr><th>Graphic</th><th>Half U, V; height</th>'
                  "<th>Flags</th><th>Update routine</th></tr>" + rows + "</table>"]
        if users:
            text = (f"<p>{_plural(copies, 'copy', 'copies')} in {_plural(len(rooms), 'room')}"
                    + (f", {raised} of them raised by the nudge" if raised else "")
                    + f": {_rooms_text(rooms)}.</p>")
            lines.append(text)
        else:
            lines.append("<p>No room places it.</p>")
        lines.append("</div>")
    lines.append("</div>")
    return "\n".join(lines)


# --------------------------------------------------------------------------
# Every graphic.
# --------------------------------------------------------------------------

# The groups on the Objects page: (key, title, routines, what they do). A
# graphic goes in the first group whose routines include its own; the panel's
# and the border's pieces, which never run a routine, are sorted out first.
GROUPS = [
    ("special", "Graphics 0 and 1", (),
     "Not things: 0 is an empty record, which the main loop still runs (a RET) and "
     "nothing draws, and 1 an object on its way out -- a valve picked up, the end of a "
     "sparkle -- which the drawing code empties instead of drawing (#R$D013). Both name "
     "the empty sprite."),
    ("robot", "The robot", (PLAYER_LEGS, TURNING_LEGS, TOP_FOLLOWS_LEGS),
     "He is two records, legs and top (#R$5B88). The legs' routine does his whole turn, "
     "and their graphic is his facing and his step: bit 2 picks the view from behind "
     "(facing lower U or V, away from the viewer) or from the front, bits 0-1 the step "
     "frame, and the mirror flag the other two facings (#R$C13C). A quarter turn passes "
     "through an in-between view, 24 to 27, held for two turns -- Alien 8's own. The top "
     "copies the legs every turn, its graphic theirs plus 16. See "
     '<a href="Movement.html">how the robot moves and turns</a>.'),
    ("sparkles", "Appearing and vanishing", (SPARKLE_STEP, SPARKLE_END, SPARKLE_END_PLACE,
                                              APPEARING, APPEARED),
     "A frame a turn: 48 to 55 is the sparkle he dies in, 56 to 63 the same sprites the "
     "other way round as he appears, keeping his real graphic at +$10, and 64 and 65 the "
     "short vanish of a collapsing block or an extra life. The sparkle's sprites are "
     "shared with the sockets' sparkle and the chaser."),
    ("doorways", "Doorways", (FIRST_PILLAR, SECOND_PILLAR),
     "Each doorway is two pillars from one background: the first marks him as in the "
     "doorway and nudges him onto its middle line, the second only draws. See "
     '<a href="Doorways.html">rooms and doorways</a>.'),
    ("walls", "Walls and plain blocks", NUDGES,
     "The whole update routine is to set the nudge that lines the sprite up with the "
     "position (+$12 and +$13); nothing about the thing changes, so it is never redrawn "
     "unless something passes in front of it."),
    ("blocks", "Blocks, lifts and conveyors", (PUSHABLE, PUSHABLE_INVERTED, DROPPING_BLOCK,
                                               COLLAPSING_BLOCK, LIFT, BOBBER, SHUTTLE_U,
                                               SHUTTLE_V) + CONVEYORS,
     "Blocks that can be pushed, that sink or vanish when stood on, that lift a rider or "
     "bob by themselves, that shuttle to and fro, and the conveyors, which never move but "
     "give what stands on them their step (#R$C535). Knight Lore's movers, mostly, with "
     "their names."),
    ("deadly", "Things that kill where they stand", (STILL_DEADLY, SPIKES),
     "Deadly both ways (MAKE_DEADLY, in #R$B2A4): whatever touches them, or whatever they "
     "touch, dies."),
    ("creatures", "Creatures", (WANDERER, PACER, LOWER_HALF, CEILING_DROP, SPARK_CHASER,
                                CLOCKWORK_MOUSE, SLOW_CHASER, FRAGILE, LEAPER),
     "All deadly both ways but the spark chaser, which only pushes. The wanderer and the "
     "pacers walk on a lower half of their own (graphic 11), which follows them 12 "
     "below; the others are one record each. See "
     '<a href="Station.html">the clock, the remote robots and the dangers</a>.'),
    ("remote", "The remote-controlled robots", (REMOTE_BUTTON, REMOTE_ROBOT, REMOTE_PAD),
     "Alien 8's own: four buttons and a pad in a room steer the little robots in it, "
     "which are harmless and push what the robot cannot touch."),
    ("chambers", "Valves, sockets, cryonauts and extra lives", (LOOSE_VALVE, SEATED_VALVE,
                                                                WANTED_VALVE, SOCKET_SPARKLE,
                                                                SOCKET, CRYONAUT, EXTRA_LIFE),
     "The things of the quest: the four kinds of valve, dealt to the 36 places at #R$76E3 "
     "at every new game with two or three extra lives among them; the socket of each "
     "chamber with its sparkle, which now and then shows the valve it wants; a valve once "
     "seated; and the frozen crew. A valve's four graphics each share one sprite: loose, "
     "seated and pictured. The four sockets share one sprite too, so what tells a "
     "chamber's kind is the valve its sparkle shows (#R$AE33). See "
     '<a href="Chambers.html">valves, sockets and the cryogenic chambers</a>.'),
    ("scenes", "The scenes after a game", (SCENE_SPARKS, SCENE_TOOL, COLOUR_SCENE_OBJECT,
                                           OILED_ROBOT, SCENE_ROBOT_TOP),
     "Placed by #R$B804 from the lists at #R$B82A (a lost game: the robot re-programmed by "
     "a glove, a hammer and a hook) and SCENE_WON (a won game: the robot lowered into oil), "
     "at pixel places rather than in the room, and run by the main loop with GAME_OVER "
     "set, which stops the projection. Each paints its own attribute cells."),
    ("screen", "The panel and the border", (),
     "Drawn through the spare record at #R$BD38, never in a room: the panel's scroll-work "
     "and icons at the foot of the screen (#R$CB0F) and the border round the menu and the "
     "end screens (#R$CB8A)."),
    ("unused", "Graphics nothing places", (),
     "No template, background, table or routine gives an object one of these."),
]

# One line on what each update routine does, for the table.
ROUTINE_SAYS = {
    NO_UPDATE: "nothing",
    FIRST_PILLAR: "the doorway: lets him through the wall and steers him to its middle",
    SECOND_PILLAR: "sets its drawing nudge",
    LOWER_HALF: "stays 12 under the creature above it",
    EXTRA_LIFE: "a life when he touches it, gone for good; falls",
    PLAYER_LEGS: "his whole turn: controls, taking, turning, jumping, stepping, moving",
    TURNING_LEGS: "holds the in-between view two turns, then the new facing",
    TOP_FOLLOWS_LEGS: "sits on the legs, their graphic plus 16",
    PUSHABLE: "falls; a push moves it once",
    PUSHABLE_INVERTED: "falls; a push moves it once",
    DROPPING_BLOCK: "sinks a unit a turn while something stands on it",
    COLLAPSING_BLOCK: "vanishes in a sparkle when landed on",
    LIFT: "carries a rider up 48, and back down",
    BOBBER: "falls, then rises two a turn to where it began, over and over",
    SHUTTLE_U: "shuttles 16 units to and fro in U, with the turn counter",
    SHUTTLE_V: "shuttles 16 units to and fro in V, with the turn counter",
    CONVEYORS[0]: "carries what stands on it forwards in V, two a turn",
    CONVEYORS[1]: "carries what stands on it forwards in U, two a turn",
    CONVEYORS[2]: "carries what stands on it back in V, two a turn",
    CONVEYORS[3]: "carries what stands on it back in U, two a turn",
    STILL_DEADLY: "deadly both ways; never moves",
    SPIKES: "deadly both ways; never moves",
    SPARKLE_STEP: "the next frame, with a shorter sound each time",
    SPARKLE_END: "the last frame: emptied when next drawn",
    SPARKLE_END_PLACE: "empties its place for good, then the record",
    APPEARING: "the next frame every other turn",
    APPEARED: "back to his real graphic, and its routine at once",
    CEILING_DROP: "deadly; hangs, then drops at random",
    CRYONAUT: "stands frozen; sets its drawing nudge",
    SPARK_CHASER: "heads for him four a turn, cycling its frames; harmless",
    SCENE_SPARKS: "flashes sixteen times, then lets the tools swing",
    SCENE_TOOL: "swings at the robot at random; fifteen swings end the scene",
    COLOUR_SCENE_OBJECT: "colours the cells it covers",
    OILED_ROBOT: "lowered into the oil and raised again, white",
    SCENE_ROBOT_TOP: "keeps 16 pixels above the legs",
    WANDERER: "deadly; walks, turning a quarter at random when stopped",
    PACER: "deadly; walks to and fro along one axis",
    LOOSE_VALVE: "falls, can be carried; in its chamber seats itself and activates it",
    SEATED_VALVE: "stays put: the chamber is activated",
    WANTED_VALVE: "shows the valve wanted for two turns, then the sparkle",
    SOCKET_SPARKLE: "sparkles over the socket; now and then shows the valve wanted",
    SOCKET: "brings the sparkle back once the room's valves are gone",
    CLOCKWORK_MOUSE: "deadly; runs straight, turns a quarter at random",
    SLOW_CHASER: "deadly; homes in on him a unit a turn",
    REMOTE_BUTTON: "while stood on, orders the robot in control one way",
    REMOTE_PAD: "while stood on, orders the robot in control to stand",
    REMOTE_ROBOT: "walks where the buttons say; harmless, pushes things",
    FRAGILE: "deadly; breaks when anything moves it",
    LEAPER: "deadly; now and then leaps 48 up and falls back",
}
for _address in NUDGES:
    ROUTINE_SAYS[_address] = "sets its drawing nudge"


def graphic_names(data: Data) -> dict[int, str]:
    return {g: SPRITE_NAMES.get(data.sprite_of[g], "") for g in range(ad.GRAPHIC_COUNT)}


def _objects_page(data: Data, listing: Listing, pictures: dict[int, str], names: dict[int, str],
                  panel_image, border_image, image_dir: Path) -> tuple[str, dict[int, str]]:
    uses = {g: data.uses_of(g, listing) for g in range(ad.GRAPHIC_COUNT)}
    screen = ({entry[0] for entry in data.panel} | {entry[0] for entry in data.border}) - {12}
    group_of = {}
    for graphic in range(ad.GRAPHIC_COUNT):
        handler = data.handler_of[graphic]
        if graphic < 2:
            group_of[graphic] = "special"
        elif graphic in screen:
            group_of[graphic] = "screen"
        elif not uses[graphic]:
            group_of[graphic] = "unused"
        else:
            group_of[graphic] = next((key for key, _, routines, _ in GROUPS if handler in routines),
                                     "unused")
    panel_image.save(image_dir / "panel.png")
    border_image.save(image_dir / "border.png")
    unused = [g for g in group_of if group_of[g] == "unused"]
    lines = ['<div class="kl-list">',
             f"<p>Every one of the {ad.GRAPHIC_COUNT} graphic numbers. An object's graphic, "
             "the first byte of its record, is what it is: it picks the sprite it is drawn "
             f"with, through {listing.ref(ad.GRAPHICS)}, and the update routine the main loop "
             f"runs for it every turn, through {listing.ref(ad.HANDLERS)} ({listing.routine(0xA692)}). "
             "There is no separate frame number: a thing animates, turns or becomes something "
             "else by changing its own graphic -- a step frame, a sparkle's next frame, a "
             "valve seated in its socket. Many graphics share a sprite: the 12 kinds of block "
             "are all one picture.</p>",
             f"<p>The update table has {ad.HANDLER_COUNT} words, one fewer than the graphic "
             f"table: graphic {PANEL_ICON}, the icon beside the count of chambers on the panel, "
             "has a sprite and no routine. It is only ever drawn by #R$CB0F through the spare "
             "record at #R$BD38, which the main loop never runs; in a room's records it would "
             "send the main loop to the word made of the next two bytes, the first "
             "instructions of NO_UPDATE.</p>",
             "<p>They are grouped here by what their routines do. Each line gives the sprite "
             "(click it for the sprite), the routine and a line on what it does, and where the "
             "graphic comes from: the backgrounds and templates that name it, the panel, the "
             "border and the scenes' lists, and the routines that give it to an object. "
             + ("Every graphic number is used by something. " if not unused else
                f"{_plural(len(unused), 'graphic')} nothing places. ")
             + "Knight Lore has the same two tables, by object type (see "
             '<a href="../knightlore/Objects.html">Knight Lore\'s objects</a>).</p>',
             "<p>" + " -- ".join(f'<a href="#{key}">{title}</a>' for key, title, _, _ in GROUPS
                                 if any(group_of[g] == key for g in group_of)) + "</p>"]
    for key, title, _, says in GROUPS:
        members = [g for g in range(ad.GRAPHIC_COUNT) if group_of[g] == key]
        if not members:
            continue
        lines += [f'<h3 id="{key}">{title}</h3>', f"<p>{says}</p>"]
        if key == "screen":
            lines += [_piece_img(f"{IMAGES}/panel.png", panel_image, "The panel", 2),
                      "<p>The panel as the game draws it on the first turn in a room -- here "
                      "a room with nothing in it but a back wall -- read from the screen buffer with "
                      "the attributes #R$A749 gives it: the light years a few turns into a game, the "
                      "last digit part way through its roll (#R$AD66); #R$CB0F's scroll-work "
                      "and icons; and the lives and the count of chambers. The label is red "
                      "because the room's ink is white, as an activated chamber's is; in a "
                      "room of any other colour it is yellow, cyan, green or magenta. The "
                      "robot beside the lives is graphic 12, the extra life. Below, the border "
                      "as #R$CB8A draws it on a cleared buffer, in the menu's red.</p>",
                      _piece_img(f"{IMAGES}/border.png", border_image, "The border", 2)]
        lines.append('<table class="kl-table"><tr><th>Graphic</th><th>Sprite</th>'
                     "<th>What it shows</th><th>Update routine</th><th>Where it comes from</th></tr>")
        rows = []
        for graphic in members:
            sprite = data.sprite_of[graphic]
            handler = data.handler_of[graphic]
            picture = pictures.get(sprite)
            cell = (f'<a href="Sprites.html#sprite{sprite:04x}"><img class="kl-thumb" '
                    f'src="{picture}" alt=""></a><br>' if picture else "")
            cell += listing.ref(sprite, f"${sprite:04X}")
            if handler is None:
                routine = "none: the table ends at graphic 130"
            else:
                routine = f"{listing.routine(handler)}: {_esc(ROUTINE_SAYS.get(handler, ''))}"
            where = "; ".join(uses[graphic]) or "nothing places it"
            rows.append([graphic, cell, _esc(names[graphic] or ""), routine, where])
        # A run of graphics with the same sprite, routine or source shares one
        # cell for it.
        spans = {}
        for column in (1, 2, 3, 4):
            start = 0
            while start < len(rows):
                end = start
                while end + 1 < len(rows) and rows[end + 1][column] == rows[start][column]:
                    end += 1
                spans[(start, column)] = end - start + 1
                for skipped in range(start + 1, end + 1):
                    spans[(skipped, column)] = 0
                start = end + 1
        for number, (graphic, cell, shows, routine, where) in enumerate(rows):
            text = f'<tr id="graphic{graphic}"><td>{graphic}</td>'
            for column, value in ((1, cell), (2, shows), (3, routine), (4, where)):
                span = spans[(number, column)]
                if span == 1:
                    text += f"<td>{value}</td>"
                elif span > 1:
                    text += f'<td rowspan="{span}">{value}</td>'
            lines.append(text + "</tr>")
        lines.append("</table>")
    lines.append("</div>")
    return "\n".join(lines), group_of


# --------------------------------------------------------------------------
# Sprites and the font.
# --------------------------------------------------------------------------

def _runs(values: list[int]) -> list[tuple[int, int]]:
    runs, start = [], None
    for index, value in enumerate(values):
        if start is None:
            start = value
        if index + 1 == len(values) or values[index + 1] != value + 1:
            runs.append((start, value))
            start = None
    return runs


def _graphic_links(graphics: list[int]) -> str:
    out = []
    for start, end in _runs(graphics):
        if start == end:
            out.append(f'<a href="Objects.html#graphic{start}">{start}</a>')
        else:
            out.append(f'<a href="Objects.html#graphic{start}">{start}</a>-'
                       f'<a href="Objects.html#graphic{end}">{end}</a>')
    return ", ".join(out)


def _font_picture(memory, start: int, rows: int = 8):
    """Eight rows of the font from `start`, the top row first, as the
    printer (#R$BBEB) copies them."""
    from PIL import Image

    image = Image.new("RGB", (8, rows))
    pixels = image.load()
    for row in range(rows):
        byte = memory[start + row]
        for bit in range(8):
            if byte & (0x80 >> bit):
                pixels[bit, row] = WHITE
    return image.resize((8 * FONT_SCALE, rows * FONT_SCALE), Image.NEAREST)


def draw_sprites(memory, image_dir: Path) -> dict[int, str]:
    """Every sprite with a width and a height, drawn from its bytes: the
    pictures, by address, as page paths."""
    import build_alien8 as ba

    pictures = {}
    for address in ad.picture_sprites(memory):
        name = f"sprite{address:04x}.png"
        ba.sprite_image(memory, address, SPRITE_SCALE).save(image_dir / name)
        pictures[address] = f"{IMAGES}/{name}"
    return pictures


def _sprites_page(data: Data, listing: Listing, pictures: dict[int, str],
                  group_of: dict[int, str], image_dir: Path) -> str:
    memory = data.memory
    unreached = [a for a, _, g in data.sprites if not g]
    lines = ['<div class="kl-list">',
             f"<p>Every sprite record, {len(data.sprites)} of them end to end from "
             f"{listing.ref(ad.SPRITES)} to the first instruction of the game at "
             f"{listing.ref(ad.SPRITES_END)}. Each is drawn from its own bytes the way the "
             f"drawing code ({listing.ref(0xD013)}) reads them: a width byte (bits 0-3 the "
             "width in bytes), a height byte, then a mask byte and an image byte for each byte "
             "of each row, the bottom row first. Where the mask is set the background is "
             "cleared, and the image is laid in wherever it is set -- so an image bit shows "
             "whether or not the mask is set, a mask bit with no image is black, and where "
             "both are clear the background shows through (here, the blue-grey). This is "
             'Knight Lore\'s format (see <a href="../knightlore/Sprites.html">Knight Lore\'s '
             "sprites</a>).</p>",
             f"<p>Bits 6 and 7 of the width byte say whether the bytes are stored mirrored or "
             f"upside down at the moment: {listing.ref(0xD174)} turns a sprite round in place, "
             "rewriting its bytes and toggling the bits, whenever it is drawn for an object "
             "facing the other way. On the tape every sprite is stored the right way round, "
             "with both bits clear, which is how they are drawn here.</p>",
             "<p>Beside each are the graphic numbers that name it (a graphic is an object's "
             f"first byte, looked up in {listing.ref(ad.GRAPHICS)}); see "
             '<a href="Objects.html">every graphic</a> for what each is. '
             + (f"{'One record' if len(unreached) == 1 else _plural(len(unreached), 'record')} "
                "no graphic number reaches: "
                + ", ".join(f'<a href="#sprite{a:04x}">${a:04X}</a>' for a in unreached)
                + ", which the game never draws. " if unreached else "")
             + "The first record, width and height both zero, is the empty sprite graphics 0 "
             "and 1 name; the drawing code sees the zero and draws nothing (#R$CFFE).</p>",
             "<p>" + " -- ".join(f'<a href="#{a}">{t}</a>' for a, t in
                                 (("sprites", "The sprites"), ("font", "The font"))) + "</p>",
             '<h3 id="sprites">The sprites</h3>',
             '<table class="kl-table"><tr><th>Sprite</th><th>Entry</th><th>What it shows</th>'
             "<th>Size</th><th>Width byte</th><th>Graphics</th></tr>"]
    for address, length, graphics in data.sprites:
        head, height = memory[address], memory[address + 1]
        width = head & 0x0F
        label = listing.name(address)
        name = SPRITE_NAMES.get(address, "")
        picture = (f'<img class="kl-sprite" src="{pictures[address]}" alt="{_esc(label)}">'
                   if address in pictures else "")
        if width and height:
            size = f"{width * 8} by {height} pixels; {length} bytes"
        else:
            size, name = "0 by 0: nothing is drawn", "nothing"
        header = f"${head:02X}" + (", turned" if head & 0xC0 else "")
        if graphics:
            used = _graphic_links(graphics)
            if all(group_of.get(g) == "unused" for g in graphics):
                used += "<br><i>Never drawn</i>: nothing places any of them"
        else:
            used = "<i>No graphic number reaches it</i>: never drawn"
        lines.append(f'<tr id="sprite{address:04x}"><td>{picture}</td>'
                     f"<td>{listing.ref(address, label)}<br>${address:04X}</td>"
                     f"<td>{_esc(name)}</td><td>{size}</td><td>{header}</td><td>{used}</td></tr>")
    lines.append("</table>")

    # The font.
    font_dir = image_dir / "font"
    font_dir.mkdir(parents=True, exist_ok=True)
    cells = []
    for index in range(ad.FONT_CHARS):
        code = ad.FONT_FIRST + index
        name = f"char{code:02x}.png"
        _font_picture(memory, ad.FONT + 8 * index).save(font_dir / name)
        shown = chr(code) if chr(code).isalnum() else f"${code:02X}"
        cells.append(f'<td><img class="kl-thumb" src="{IMAGES}/font/{name}" '
                     f'alt="{_esc(shown)}"><br>{_esc(shown)}</td>')
    rows = "".join("<tr>" + "".join(cells[i:i + 11]) + "</tr>" for i in range(0, len(cells), 11))
    blank = [ad.FONT_FIRST + i for i in range(ad.FONT_CHARS)
             if not any(memory[ad.FONT + 8 * i:ad.FONT + 8 * i + 8])]
    nought = memory[ad.FONT:ad.FONT + 8]
    second = [ad.FONT_FIRST + i for i in range(1, ad.FONT_CHARS)
              if memory[ad.FONT + 8 * i:ad.FONT + 8 * i + 8] == nought]
    # The roll of a 9 after a borrow, as #R$ADB0 prints it: the eight bytes
    # from the digit's character plus its count, the count going 7 down to 0.
    roll = []
    nine = ad.FONT + 8 * 9
    for count in range(7, -1, -1):
        name = f"roll9_{count}.png"
        _font_picture(memory, nine + count).save(font_dir / name)
        roll.append(f'<td><img class="kl-thumb" src="{IMAGES}/font/{name}" alt="count {count}">'
                    f"<br>{count}</td>")
    lines += ['<h3 id="font">The font</h3>',
              f"<p>{ad.FONT_CHARS} characters of 8 by 8 pixels at {listing.ref(ad.FONT)}, for "
              f"the codes ${ad.FONT_FIRST:02X} to ${ad.FONT_FIRST + ad.FONT_CHARS - 1:02X}: the "
              "digits, a second nought, a few signs and "
              f"{_plural(len(blank), 'blank character')} ("
              + ", ".join(f"${c:02X}" for c in blank) + "), and the capital letters. Each is "
              f"eight bytes, the top row first, as the printer ({listing.ref(0xBBEB)}) copies "
              "them into the screen buffer. There is no lower case, and a space is printed as "
              "code $3D, the first of the blanks. For text the printer's base is 384 bytes "
              "below the font, so that the codes land on these characters; for numbers it is "
              "the font itself, so that the digits are codes 0 to 9. Drawn here in white; the "
              "game colours text by the attributes it prints with.</p>",
              '<table class="kl-table">' + rows + "</table>",
              '<p id="nought">The character after the 9, code '
              + " and ".join(f"${c:02X}" for c in second)
              + " -- a colon where the codes are ASCII -- is the same eight bytes as the 0 "
              f"(compared at build time). It is there for the light-years clock ({listing.ref(0xAD66)}): "
              "a digit that changes is printed rows out of line, the eight bytes from its "
              f"character plus a count that runs down from 7 to 0 over seven turns "
              f"({listing.ref(0xADB0)}), so it rolls down into place from the digit above it like "
              "a counter's wheel. A 9 comes after a 0 -- a borrow -- and the character above the "
              "9 is this second nought, so the 9 rolls in from a 0. Here is that roll, read "
              "from the font the way the clock reads it, count 7 first:</p>",
              '<table class="kl-table"><tr>' + "".join(roll) + "</tr></table>",
              "</div>"]
    return "\n".join(lines)


# --------------------------------------------------------------------------
# Together.
# --------------------------------------------------------------------------

def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    """Draw the pictures into html_dir/images/graphics and return the
    Scenery, Templates, Objects and Sprites sections."""
    import build_alien8 as ba

    memory = ba.game_memory(snapshot)
    listing = Listing(snapshot.with_name("alien8.skool"))
    data = Data(memory)
    image_dir = html_dir / "images" / "graphics"
    image_dir.mkdir(parents=True, exist_ok=True)
    names = graphic_names(data)

    log("  graphics: drawing the sprites from their bytes...")
    pictures = draw_sprites(memory, image_dir)
    log("  graphics: starting a game to draw the backgrounds and templates with...")
    stage = Stage(snapshot, data)
    scenery = _scenery_page(data, stage, listing, image_dir)
    templates = _templates_page(data, stage, listing, image_dir, names)
    objects, group_of = _objects_page(data, listing, pictures, names, stage.panel(),
                                      stage.border(), image_dir)
    sprites = _sprites_page(data, listing, pictures, group_of, image_dir)
    sections = {"Scenery": scenery, "Templates": templates, "Objects": objects,
                "Sprites": sprites}
    sections = {name: listing.check_links(body) for name, body in sections.items()}
    if listing.missing:
        log("  graphics: no entry at " + ", ".join(f"${a:04X}" for a in sorted(listing.missing))
            + " -- linked as plain text")
    for name, body in sections.items():
        for number, line in enumerate(body.split("\n"), 1):
            if line.startswith((";", "[")):
                raise ValueError(f"{name}, line {number}: a ref line may not start with "
                                 f"{line[0]!r}")
        if re.search(r"#[0-9A-Fa-f]{6}\b", body):
            raise ValueError(f"{name}: a colour written with a bare # would be read as a macro")
    log(f"  graphics: {len(pictures)} sprites, {ad.BACKGROUND_COUNT} backgrounds and "
        f"{len(data.templates)} object templates drawn")
    return sections
