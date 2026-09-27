"""Pentagram's graphics pages -- scenery, templates, objects, sprites -- drawn
from the game at build time.

build_pentagram.py --html calls build(), which draws the pictures into
html_dir/images/graphics/ and returns four ref sections: Scenery, Templates,
Objects and Sprites. Nothing here is committed output: the pictures are the
game's, and so are the lists of what each room uses. What is committed is the
prose, the addresses, and short names for what the pictures show, each given
after looking at the picture.

Two ways of drawing, each the game's own:

- Scenery and object templates are drawn by the game's own code, run in
  SkoolKit's simulator. The game is started the way build_pentagram.py's
  sessions start it (its Machine, keyboard, through the start tune into the
  first room), so the drawing tables are built and the variables are a real
  game's. Then a one-off room record is written first in the room directory
  (#R$5E10), where the room finder (#R$C92C) looks first, and the game enters
  it (#R$C6B6) and runs its first turn from the top of the main loop (#R$AF87)
  to the point where the room is in the buffer and the attributes have been
  filled, just before the panel is drawn over it (#R$B00C). The picture is
  read out of the buffer at #R$D88F, bottom line first. The player's two
  records are emptied first so that he is not in the pictures, and the quest
  things are never put in, since the routine that does that (#R$B097) is not
  called.
- Sprites are decoded from their bytes as the drawing code (#R$B3D3) reads
  them, with build_pentagram.sprite_image, the same pictures the listing's
  sprite entries show.
"""
from __future__ import annotations

import html
import re
from pathlib import Path

import pentagram_data as pd

# Where the game keeps what the pictures need (see their entries).
PLAYER = 0xA76F             # the legs' record; the body's is the next
PLAYER_BODY = 0xA78F
PLAYER_ROOM = 0xA777        # +8 of the legs' record
DROP_BAN = 0xA742           # 1: nothing falls from the sky in this room
ROOM_ATTR = 0xA738          # the room's ink, BRIGHT, on black
ENTER_ROOM = 0xC6B6         # build the room the legs' record names
MAIN_LOOP = 0xAFDA          # the top of a turn
ROOM_DRAWN = 0xB06C         # first turn in a room: attributes filled, the
                            # panel not yet drawn into the buffer
SCREEN_BUFFER = 0xD88F      # 192 rows of 32 bytes, the bottom line first
STACK = 0x5E00              # the game's own stack pointer (#R$5E00)
TRAP = 0x0000               # a return address nothing in the game reaches

DROP_GRAPHICS = 0xCC09      # eight graphics that may fall from the sky
DROP_COUNT = 8
PANEL_DATA = 0xBD31         # the panel's scroll-work: 10 entries of 4 bytes
BORDER_DATA = 0xBD98        # the text screens' border: 10 entries of 4 bytes
PIECE_ENTRIES = 10
LIVES_ICON = 0xC2A1         # the operand of the LD (IX+$00),n at $C29E

# The update routines, by address, as the listing names them.
NOTHING = 0xC43F
PLAYER_LEGS = 0xC440
PLAYER_TOP = 0xC5D3
FIRST_PILLAR = 0xC7AD
SECOND_PILLAR = 0xC789
BOLT = 0xC1C5
PUFF = 0xC111
END_PUFF = 0xC11D
STILL_DEADLY = 0xC285
SPIKES = 0xCD70
PUSHABLE = 0xCD81
HEAVY_BLOCK = 0xCD75
SLIDING_TABLE = 0xCD7C
SINKING_BLOCK = 0xCDA0
LIFT = 0xCDBB
BOBBER = 0xCE31
DEADLY_BOBBER = 0xCE9A
DEADLY_PACER_U = 0xCEA0
PACER_U = 0xCEA3
DEADLY_PACER_V = 0xCEDA
PACER_V = 0xCEDD
SPIDER = 0xCF22
ROAMER = 0xD1F5
SKY_ROAMER = 0xD1FD
SKY_WALKER = 0xD251
HOMER = 0xCC4B
CRUMBLING_BLOCK = 0xD2AD
CONVEYORS = (0xD2DE, 0xD2E9, 0xD2F4, 0xD2FF)
WELL = 0xCFD2
BUCKET = 0xD0AC
QUEST_ITEM = 0xCF68
COLLECTABLE = 0xCD16
PENTAGRAM_PIECE = 0xCF14
JUMP_L16_D8 = 0xCB4E
JUMP_L16_D12 = 0xCB51
OFFSET_ROUTINES = (0xC784, 0xC77F, 0xC74B)      # the walls' drawing offsets

# The room sizes: which walls stand where. A room's walls are ROOM_EXTENT
# from its middle at 128 (#R$5E07); the projection (#R$B2C5) puts low U at the
# back left of the picture, high V at the back right, high U at the front
# right and low V at the front left.
SIDE_NAMES = {("U", "low"): "back left", ("V", "high"): "back right",
              ("U", "high"): "front right", ("V", "low"): "front left"}

# Short names for what each sprite shows, by its address: given after
# drawing each one (a name is a claim, and only the picture backs it).
SPRITE_NAMES = {
    0x73BF: "a dark patch on the ground",
    0x7441: "a hand reaching out of a dark patch",
    0x74C3: "the stone block crumbling, first stage",
    0x759D: "the stone block crumbling, second stage",
    0x7677: "the stone block crumbling, last stage",
    0x7751: "a horned head",
    0x7813: "a lumbering figure, walking",
    0x78AB: "a lumbering figure, walking",
    0x7943: "a lumbering figure from behind, walking",
    0x79F3: "a lumbering figure from behind, walking",
    0x7A9D: "a witch on a broomstick",
    0x7B5F: "a witch on a broomstick, from behind",
    0x7C21: "a pointed blob",
    0x7CA1: "a pointed blob",
    0x7D33: "a pointed blob",
    0x7DD1: "a clawed, winged beast",
    0x7E8B: "a clawed, winged beast",
    0x7F45: "a clawed, winged beast",
    0x7FFF: "a ghost",
    0x809D: "a ghost",
    0x813B: "a puff of smoke",
    0x8175: "a puff of smoke",
    0x81C5: "a puff of smoke",
    0x822D: "a puff breaking up",
    0x828F: "a bolt",
    0x82D1: "a bolt",
    0x8313: "a bolt",
    0x84AD: "a spider",
    0x8547: "a tree stump with roots",
    0x8609: "a smooth block",
    0x86EB: "a toothed trap",
    0x8795: "a bed of spikes",
    0x8877: "a little Sabreman",
    0x88BD: "a stone block",
    0x89A7: "a piece of the panel's scroll-work",
    0x89E9: "a piece of the panel's scroll-work",
    0x8A17: "a piece of scroll-work",
    0x8A59: "a piece of the panel's scroll-work",
    0x8A9B: "a piece of the panel's scroll-work",
    0x8ABD: "a table",
    0x8C13: "the well",
    0x8D55: "a rough stone",
    0x8E8F: "a finished pillar",
    0x9029: "the bucket",
    0x90BB: "a rune stone",
    0x914D: "a rune stone",
    0x91DF: "a rune stone",
    0x9271: "a rune stone",
    0x9303: "a rune stone",
    0x9395: "nothing: width and height zero",
    0x9397: "his body",
    0x943B: "his body",
    0x94DF: "his body",
    0x9583: "his body, the other view",
    0x9651: "his body, the other view",
    0x971F: "his body, the other view",
    0x97ED: "his legs",
    0x9849: "his legs",
    0x98A5: "his legs",
    0x9901: "his legs, the other view",
    0x996F: "his legs, the other view",
    0x99DD: "his legs, the other view",
    0x9A4B: "a side of the text screens' border",
    0x9ADD: "the short piece closing the border's top and bottom",
    0x9B3F: "a length of the border's top and bottom",
    0x9BD1: "a corner of the border",
    0x9C63: "a tree: the first pillar of a doorway in the trees",
    0x9DAF: "a tree: the second pillar of a doorway in the trees",
    0x9E51: "a tree stump",
    0x9F1B: "a tree in a line of trees",
    0x9FC9: "a tree in a line of trees",
    0xA09F: "a tree in a line of trees",
    0xA175: "a tree in a line of trees",
    0xA23F: "a piece of ruined stone wall",
    0xA2A9: "a piece of ruined stone wall",
    0xA327: "a column in a stone wall",
    0xA3AD: "a piece of ruined stone wall",
    0xA40F: "a piece of ruined stone wall",
    0xA47D: "the second half of a stone arch",
    0xA557: "the first half of a stone arch",
    0xA67F: "the end of a stone wall",
}
PENTAGRAM_SPRITES = range(0x6F2F, 0x73BF)      # the eight pieces, $92 bytes each

# Graphics the code gives an object itself, rather than a table: each read
# from the routine named (the listing has the instruction).
CODE_MADE = [
    (range(32, 40), "his legs: the facing and the walking frame (#R$C440)"),
    (range(40, 48), "his body: the legs' graphic plus 8 (#R$C5D3)"),
    ([1], "an object on its way out: rubbed out and emptied when next drawn (#R$B3D3)"),
    ([150], "a bolt, as it is fired (#R$C126)"),
    ([149, 151], "a bolt in flight: the frames go 151, 150, 149 (#R$C1C5)"),
    ([64], "the first frame of a puff (#R$C107)"),
    (range(65, 72), "a puff's later frames (#R$C111)"),
    (list(range(49, 52)) + list(range(161, 164)) + list(range(165, 168)),
     "a homer's other frames: the low two bits of the graphic (#R$CC4B)"),
    ([17], "the spider's other frame, every other turn (#R$D1F5)"),
    ([81], "the witch's other view (#R$D1F5)"),
    (range(169, 172), "the walker's other frames (#R$D251)"),
    (range(137, 140), "the crumbling block's stages (#R$D2AD)"),
    ([90], "the bucket, which the well makes (#R$CFD2)"),
    (range(116, 120), "a quest item once the bucket reaches it: its graphic plus 4 (#R$CF68)"),
    (range(152, 157), "a collectable once it is in its place: its graphic plus 8 (#R$CD16)"),
]

# The quest's records (#R$D312) by number, as pentagram_data.py names them.
QUEST_KINDS = pd.QUEST_KINDS

INK_WHITE = 7
SPRITE_SCALE = 2
PIECE_SCALE = 2
FONT_SCALE = 3
BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF),
          (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0), (0xFF, 0xFF, 0xFF)]


def _word(memory, address: int) -> int:
    return memory[address] | memory[address + 1] << 8


def _esc(text: str) -> str:
    return html.escape(text, quote=False)


def _plural(count: int, word: str, words: str | None = None) -> str:
    return f"{count} {word if count == 1 else (words or word + 's')}"


# --------------------------------------------------------------------------
# The listing: which addresses are entries, and what they are called.
# --------------------------------------------------------------------------

class Listing:
    """Entry starts, labels and titles from pentagram.skool, so that a #R
    link is made only to an entry that exists."""

    def __init__(self, skool: Path):
        self.labels: dict[int, str] = {}      # entries' and entry points' labels
        self.titles: dict[int, str] = {}      # entries only
        self.missing = set()                  # #R links dropped for want of an entry
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
    game's own code reads them (see pentagram_data.py for each walk)."""

    def __init__(self, memory):
        self.memory = memory
        self.rooms = pd.room_records(memory)
        self.sizes = [pd.room_size(memory, i) for i in range(3)]
        # Scenery: each index's address and pieces, up to the zero after one.
        self.scenery = []
        for index in range(pd.SCENERY_COUNT):
            address = _word(memory, pd.SCENERY_TABLE + 2 * index)
            pieces = []
            if address != pd.SCENERY_TABLE:
                piece = address
                while True:
                    pieces.append(list(memory[piece:piece + 8]))
                    piece += 8
                    if memory[piece] == 0:
                        break
            self.scenery.append((address, pieces))
        # Object templates: graphic, half-sizes, flags, then the zero.
        self.objects = []
        for index in range(pd.OBJECT_COUNT):
            address = _word(memory, pd.OBJECT_TABLE + 2 * index)
            self.objects.append((address, list(memory[address:address + 5])))
        self.sprite_of = [_word(memory, pd.GRAPHICS + 2 * g) for g in range(pd.GRAPHIC_COUNT)]
        self.handler_of = [_word(memory, pd.HANDLERS + 2 * g) for g in range(pd.GRAPHIC_COUNT)]
        self.sprites = pd.sprite_entries(memory)
        # Who uses what.
        self.scenery_rooms: dict[int, list[tuple[int, int]]] = {}
        self.object_rooms: dict[int, list[tuple[int, int]]] = {}
        for room in self.rooms:
            for _, template, destination in room["scenery"]:
                self.scenery_rooms.setdefault(template, []).append((room["number"], destination))
            for _, template, _, positions in room["groups"]:
                self.object_rooms.setdefault(template, []).append((room["number"], len(positions)))
        self.quest = []
        for number in range(pd.QUEST_COUNT):
            record = pd.QUEST_START + pd.QUEST_SIZE * number
            self.quest.append((number, memory[record], memory[record + 8]))
        self.drops = list(memory[DROP_GRAPHICS:DROP_GRAPHICS + DROP_COUNT])
        self.panel = [memory[PANEL_DATA + 4 * i] for i in range(PIECE_ENTRIES)]
        self.border = [memory[BORDER_DATA + 4 * i] for i in range(PIECE_ENTRIES)]
        self.lives_icon = memory[LIVES_ICON]

    def room_size_for_scenery(self, index: int) -> int:
        """The size of room a scenery template is made for: the one most of
        its rooms have, or for one no room uses, the size whose walls its
        pieces stand on."""
        counts: dict[int, int] = {}
        for number, _ in self.scenery_rooms.get(index, []):
            size = next(r["size"] for r in self.rooms if r["number"] == number)
            counts[size] = counts.get(size, 0) + 1
        if counts:
            return max(counts, key=lambda s: (counts[s], -s))
        for size, (half_u, half_v, _) in enumerate(self.sizes):
            walls_u = {128 - half_u, 128 + half_u}
            walls_v = {128 - half_v, 128 + half_v}
            pieces = self.scenery[index][1]
            if pieces and all(p[1] in walls_u or p[2] in walls_v for p in pieces):
                return size
        return 0

    def uses_of(self, graphic: int, listing: Listing) -> list[str]:
        """Where a graphic appears: the tables that name it, and the code
        that gives it to an object."""
        out = []
        scenery = sorted({index for index, (_, pieces) in enumerate(self.scenery)
                          if any(p[0] == graphic for p in pieces)})
        if scenery:
            out.append("scenery " + ", ".join(
                f'<a href="Scenery.html#scenery{i}">{i}</a>'
                + ("" if i in self.scenery_rooms else " (no room)") for i in scenery))
        templates = [i for i, (_, fields) in enumerate(self.objects) if fields[0] == graphic]
        if templates:
            out.append("object template " + ", ".join(
                f'<a href="Templates.html#object{i}">{i}</a>'
                + (f" ({_plural(len({r for r, _ in self.object_rooms[i]}), 'room')})" if i in self.object_rooms
                   else " (no room)") for i in templates))
        quest = [(n, room) for n, g, room in self.quest if g == graphic and graphic]
        for number, room in quest:
            out.append(f"quest record {number} in {listing.ref(pd.QUEST_START)}, "
                       f"{_esc(QUEST_KINDS[number])}")
        if graphic in self.drops:
            out.append(f"falls from the sky ({listing.ref(DROP_GRAPHICS)}, "
                       f"{self.drops.count(graphic)} of its 8)")
        if graphic in self.panel:
            out.append(f"the panel's scroll-work ({listing.ref(PANEL_DATA)})")
        if graphic in self.border:
            out.append(f"the text screens' border ({listing.ref(BORDER_DATA)})")
        if graphic == self.lives_icon:
            out.append("the lives icon on the panel (#R$C29A)")
        for graphics, what in CODE_MADE:
            if graphic in graphics and not (graphic == self.lives_icon):
                out.append(what)
        return out


# --------------------------------------------------------------------------
# Drawing with the game's own code.
# --------------------------------------------------------------------------

class Stage:
    """A game started as a player starts one, ready to build and draw a
    one-off room with the game's own room builder and drawing code."""

    def __init__(self, snapshot: Path, data: Data):
        import build_pentagram as bp

        machine = bp.Machine(snapshot)
        machine.play(bp._start("1"), "the graphics pages")
        self.memory = list(machine.memory)
        self.tracer_class = type(machine.tracer)
        numbers = {room["number"] for room in data.rooms}
        # A number no room has, so the one-off record is the only match.
        self.room = min(n for n in range(256) if n not in numbers)

    def record(self, size: int, scenery: list[int], groups: list[tuple[int, list[int]]]) -> list[int]:
        """A room record: number, the count, ink and size, the scenery
        entries (template, then 0), and -- if there are any -- $FF and the
        groups of objects. The count is of the bytes after it, less one, as
        the builder reads it (pentagram_data.room_records)."""
        body = [(size << 3) | INK_WHITE]
        for template in scenery:
            body += [template, 0]
        if groups:
            body.append(0xFF)
            for template, positions in groups:
                body += [(template << 3) | (len(positions) - 1)] + positions
        return [self.room, len(body) + 1] + body

    def draw(self, record: list[int]):
        """The room the record describes, as the game draws it on its first
        turn there, before the panel goes in."""
        from PIL import Image
        from skoolkit import CSimulator
        from skoolkit.simulator import Simulator
        from skoolkit.simutils import SP

        memory = list(self.memory)
        memory[PLAYER] = memory[PLAYER_BODY] = 0      # no player in the picture
        memory[PLAYER_ROOM] = record[0]
        memory[pd.ROOMS:pd.ROOMS + len(record)] = record
        memory[DROP_BAN] = 1                          # and nothing from the sky
        memory[STACK - 2:STACK] = [TRAP & 0xFF, TRAP >> 8]
        simulator = (CSimulator or Simulator)(memory, state={"iff": 0, "im": 1, "tstates": 0})
        simulator.set_tracer(self.tracer_class(simulator))
        simulator.registers[SP] = STACK - 2
        simulator.run(ENTER_ROOM, TRAP)
        simulator.registers[SP] = STACK
        simulator.run(MAIN_LOOP, ROOM_DRAWN)
        screen = simulator.memory
        ink = BRIGHT[screen[ROOM_ATTR] & 7]
        image = Image.new("RGB", (256, 192))
        pixels = image.load()
        for y in range(192):
            row = SCREEN_BUFFER + (191 - y) * 32
            for column in range(32):
                byte = screen[row + column]
                for bit in range(8):
                    if byte & (0x80 >> bit):
                        pixels[column * 8 + bit, y] = ink
        return _cropped(image)


def _cropped(image, margin: int = 8):
    """A one-off scene cut down to what was drawn in it, with a margin."""
    box = image.convert("L").point(lambda v: 255 if v else 0).getbbox()
    if not box:
        return image
    left, top, right, bottom = box
    return image.crop((max(0, left - margin), max(0, top - margin),
                       min(image.width, right + margin), min(image.height, bottom + margin)))


def _piece_img(path: str, image, alt: str) -> str:
    return (f'<img class="kl-piece" src="{path}" alt="{_esc(alt)}" '
            f'width="{image.width * PIECE_SCALE}" height="{image.height * PIECE_SCALE}">')


def _room_link(number: int) -> str:
    return f'<a href="RoomStructure.html#room{number}">{number}</a>'


def _flags(flags: int) -> str:
    """An object's flags (+$07) as a template sets them."""
    bits = []
    if flags & 0x04:
        bits.append("pushable")
    if flags & 0x10:
        bits.append("to be drawn")
    if flags & 0x40:
        bits.append("mirrored")
    other = flags & ~0x54
    if other:
        bits.append(f"other bits ${other:02X}")
    return f"${flags:02X}" + (f" ({', '.join(bits)})" if bits else "")


# --------------------------------------------------------------------------
# Scenery.
# --------------------------------------------------------------------------

def _scenery_kind(data: Data, index: int) -> tuple[str, str]:
    """(group, name) for a scenery template, from its pieces: which graphics,
    which wall they stand on, and how high."""
    pieces = data.scenery[index][1]
    if not pieces:
        return "unused", "Not a template"
    graphics = {p[0] for p in pieces}
    size = data.room_size_for_scenery(index)
    half_u, half_v, floor = data.sizes[size]
    sides = []
    for p in pieces:
        # A wall piece is flat across the wall (a half-size of 0); a pillar
        # or a block stands on whichever axis it is further out along.
        if p[4] == 0 or (p[5] != 0 and abs(p[1] - 128) > abs(p[2] - 128)):
            axis, value = "U", p[1]
        else:
            axis, value = "V", p[2]
        sides.append(SIDE_NAMES[(axis, "low" if value < 128 else "high")])
    side = max(set(sides), key=sides.count)
    corner = len(set(sides)) > 1
    if graphics <= {6, 7}:
        return "doorways", f"A doorway between two trees, in the {side} wall"
    if graphics <= {8, 9}:
        raised = pieces[0][3] > floor
        return "doorways", (f"A stone arch{' raised to a height of ' + str(pieces[0][3]) if raised else ''}"
                            f", in the {side} wall")
    if graphics <= {11}:
        return "ledges", f"Two stone blocks at a height of {pieces[0][3]}, against the {side} wall"
    wall = "trees" if graphics <= {12, 13, 14, 15} else "ruined stone wall"
    middle = any(p[1] in (120, 136) or p[2] in (120, 136) for p in pieces
                 if sides[pieces.index(p)] == side)
    name = f"A line of {wall}" if wall == "trees" else f"A {wall}"
    name += f" along the {side} side"
    if not middle:
        name += ", with a gap in the middle for a doorway"
    if corner:
        name += ", and a piece round the corner"
    return "walls", name


def _scenery_page(data: Data, stage: Stage, listing: Listing, image_dir: Path) -> str:
    starts = {}
    for index, (address, _) in enumerate(data.scenery):
        starts.setdefault(address, []).append(index)
    templates = sorted(a for a in starts if a != pd.SCENERY_TABLE)
    # A template whose start falls inside another's pieces is that one's
    # tail: the same bytes, read from further in.
    tail_of = {}
    for address in templates:
        for other in templates:
            length = 8 * len(data.scenery[starts[other][0]][1])
            if other < address < other + length:
                tail_of[address] = other
    groups = {"doorways": [], "walls": [], "ledges": [], "unused": []}
    for index in range(pd.SCENERY_COUNT):
        group, name = _scenery_kind(data, index)
        groups[group].append((index, name))

    def item(index: int, name: str) -> list[str]:
        address, pieces = data.scenery[index]
        size = data.room_size_for_scenery(index)
        record = stage.record(size, [index], [])
        image = stage.draw(record)
        picture = f"scenery{index:02d}.png"
        image.save(image_dir / picture)
        rows = "".join(
            f'<tr><td><a href="Objects.html#graphic{p[0]}">{p[0]}</a></td><td>{p[1]}</td>'
            f"<td>{p[2]}</td><td>{p[3]}</td><td>{p[4]}, {p[5]}, {p[6]}</td>"
            f"<td>{_flags(p[7])}</td></tr>" for p in pieces)
        users = data.scenery_rooms.get(index, [])
        lines = [f'<div class="kl-item" id="scenery{index}">',
                 _piece_img(f"images/graphics/{picture}", image, f"Scenery template {index}"),
                 f"<p><b>{index}: {_esc(name)}</b> -- {listing.ref(address)}; "
                 f"drawn in a room of size {size} ({data.sizes[size][0]} by "
                 f"{data.sizes[size][1]} about the middle).</p>"]
        others = [i for i in starts[address] if i != index]
        notes = []
        if others:
            notes.append("The table gives the same address for "
                         + ", ".join(f'<a href="#scenery{i}">{i}</a>' for i in others) + ".")
        if address in tail_of:
            host = starts[tail_of[address]][0]
            skipped = (address - tail_of[address]) // 8
            notes.append(f"Its bytes are the last {_plural(len(pieces), 'piece')} of "
                         f'<a href="#scenery{host}">template {host}</a>\'s: the table points '
                         f"{_plural(skipped, 'piece')} further in, and the same wall is built "
                         "without them.")
        working = [p[0] for p in pieces if data.handler_of[p[0]] == FIRST_PILLAR]
        drawing = [p[0] for p in pieces if data.handler_of[p[0]] == SECOND_PILLAR]
        if working and drawing:
            notes.append(f"Graphic {working[0]} is the doorway's working pillar "
                         f"({listing.ref(FIRST_PILLAR)}): the room it leads to is the "
                         f"second byte of the room's scenery entry, which the builder puts in "
                         f"every piece's +$08. Graphic {drawing[0]} only draws "
                         f"({listing.ref(SECOND_PILLAR)}).")
        rooms_here = sorted({r for r, _ in users})
        if name.startswith("Two stone blocks") and rooms_here:
            for other, (_, other_pieces) in enumerate(data.scenery):
                other_rooms = sorted({r for r, _ in data.scenery_rooms.get(other, [])})
                if (other != index and other_rooms == rooms_here and other_pieces
                        and data.handler_of[other_pieces[0][0]] in (FIRST_PILLAR, SECOND_PILLAR)):
                    notes.append(f'It is in exactly the rooms that have <a href="#scenery{other}">'
                                 f"template {other}</a>, the raised stone arch in the same wall, "
                                 f"whose pillars stand at a height of {other_pieces[0][3]}, the "
                                 f"top of these blocks: they are what that doorway stands on.")
        if notes:
            lines.append("<p>" + " ".join(notes) + "</p>")
        lines.append('<table class="kl-table"><tr><th>Graphic</th><th>U</th><th>V</th>'
                     "<th>Z</th><th>Half U, V; height</th><th>Flags</th></tr>" + rows + "</table>")
        if users:
            if name.startswith(("A doorway", "A stone arch")):
                listed = ", ".join(f"{_room_link(r)} to {_room_link(d)}"
                                   for r, d in sorted(users))
                lines.append(f"<p>In {_plural(len(users), 'room')}, each with where it "
                             f"leads: {listed}.</p>")
            else:
                listed = ", ".join(_room_link(r) for r in sorted({r for r, _ in users}))
                lines.append(f"<p>In {_plural(len({r for r, _ in users}), 'room')}: {listed}.</p>")
        else:
            lines.append("<p>No room uses it.</p>")
        lines.append("</div>")
        return lines

    counts = {key: len(value) for key, value in groups.items()}
    lines = ['<div class="kl-list">',
             f"<p>The scenery is what a room lists first in its record: the doorways "
             f"and the walls, and the ledges the raised doorways stand on. A room names "
             f"each piece of scenery by a template number, an index into the "
             f"{pd.SCENERY_COUNT} words of {listing.ref(pd.SCENERY_TABLE)}, followed by one "
             f"more byte; the builder ({listing.ref(0xC92C)}) copies each 8-byte piece of the "
             f"template into an object record as it is -- graphic, U, V, Z, the "
             f"half-sizes in U and V, the height and the flags -- and gives every piece the entry's second byte as "
             f"its +$08. For a doorway that byte is the room it leads to; for everything "
             f"else it is 0. So a doorway's destination is in the room's record, not worked "
             f"out from where the room lies, and rooms are joined any way the designer "
             f"liked.</p>",
             "<p>Unlike an object template, a scenery template carries its own position, "
             "so it always stands in the same place: a template is made for a wall of a "
             f"room of one size. The {counts['doorways']} doorway templates come in two "
             "kinds -- a pair of trees and a stone arch -- for each of the four walls, and "
             "the stone arch again raised to the height of the ledges. The walls are lines "
             "of trees or ruined stone walls, whole or with a gap in the middle where a "
             "doorway goes; a gapped wall is the whole one's bytes read from two pieces "
             "further in, so the two share their bytes. "
             f"{counts['unused']} of the table's words point back at the table itself, and "
             "no room uses those numbers.</p>",
             "<p>Each template is drawn here by the game, on its own: a one-off room record "
             "naming just that template, in a room of the size it is made for, is written "
             f"first in the room directory ({listing.ref(pd.ROOMS)}), and the game builds the "
             f"room ({listing.ref(ENTER_ROOM)}) and draws its first turn "
             f"({listing.ref(0xAF87)}), in SkoolKit's simulator. The pictures are white "
             "whatever the rooms' own colours. On the screen low U is at the back left, "
             "high V at the back right, high U at the front right and low V at the front "
             "left; a room's walls stand the room's half-size from its middle at 128 "
             f"({listing.ref(pd.SIZES)}).</p>",
             '<p>Knight Lore builds its rooms the same way from its own backgrounds (see '
             '<a href="../knightlore/Scenery.html">Knight Lore\'s scenery</a>), but a '
             "background there is one byte in the room's record, and a room's neighbours "
             "follow from its number. Pentagram's two-byte entry is what lets its map be "
             "joined up by hand.</p>"]
    for key, title in (("doorways", "Doorways"), ("walls", "Walls"),
                       ("ledges", "Ledges under the raised doorways")):
        lines.append(f"<h3>{title}</h3>")
        for index, name in groups[key]:
            lines += item(index, name)
    lines.append("<h3>Numbers with no template</h3>")
    lines.append("<p>" + ", ".join(str(i) for i, _ in groups["unused"])
                 + f": their words in {listing.ref(pd.SCENERY_TABLE)} hold the table's own "
                 "address. A room naming one would have its bytes read as pieces; none "
                 "does.</p>")
    for index, _ in groups["unused"]:
        lines.append(f'<span id="scenery{index}"></span>')
    lines.append("</div>")
    return "\n".join(lines)


# --------------------------------------------------------------------------
# Object templates.
# --------------------------------------------------------------------------

def _templates_page(data: Data, stage: Stage, listing: Listing, image_dir: Path,
                    names: dict[int, str]) -> str:
    starts: dict[int, list[int]] = {}
    for index, (address, _) in enumerate(data.objects):
        starts.setdefault(address, []).append(index)
    # One copy near the middle of the room, on the floor: cell (3, 3), level 0.
    middle = 3 | 3 << 3
    lines = ['<div class="kl-list">',
             f"<p>The {pd.OBJECT_COUNT} kinds of thing a room record can place -- the "
             f"templates the builder ({listing.ref(0xC92C)}) makes object records from, "
             "after the scenery. A room gives a group header, bits 3-7 a template number "
             f"(an index into {listing.ref(pd.OBJECT_TABLE)}) and bits 0-2 how many copies "
             "less one, then a position byte for each copy: U = 72 + 16 times bits 0-2, "
             "V = 72 + 16 times bits 3-5, and Z the floor plus 12 times bits 6-7, so a "
             "room is an 8 by 8 grid of cells, four levels high.</p>",
             "<p>A template is a list of 5-byte parts ended by a zero: the graphic, the "
             "half-sizes in U and V, the height (Z is an object's base, not its middle) and the flags, which go to +0 and +4 to +7 of a record, "
             "the position to +1 to +3 and the room to +8. The builder would make a record "
             "of each part at the same place, but every template in the game has just "
             "one. The graphic decides everything else: its update routine and its sprite "
             '(see <a href="Objects.html">every graphic</a>). The flags set here are bit 4, '
             "to be drawn; bit 2, pushable, which the collision code reads when something "
             f"walks into it ({listing.ref(0xB742)}); and bit 6, mirrored.</p>",
             "<p>A template number of 31 is not a template: it moves the builder on to a "
             "second page of templates, 64 bytes further on, and skips a byte; no room uses "
             f"it. Templates {' and '.join(str(i) for i in next(v for v in starts.values() if len(v) > 1))} "
             "share one set of bytes.</p>",
             "<p>Each is drawn here by the game, on its own near the middle of an empty "
             "room (cell 3, 3, on the floor), from a one-off room record the game builds and "
             "draws its first turn of, in SkoolKit's simulator; a thing that moves has had "
             "one turn. Knight Lore's templates are the same idea with a sixth byte, an "
             'offset, and several parts to some (see <a href="../knightlore/Templates.html">'
             "Knight Lore's templates</a>).</p>"]
    for index, (address, (graphic, su, sv, sz, flags)) in enumerate(data.objects):
        record = stage.record(0, [], [(index, [middle])])
        image = stage.draw(record)
        picture = f"object{index:02d}.png"
        image.save(image_dir / picture)
        users = data.object_rooms.get(index, [])
        rooms = sorted({r for r, _ in users})
        copies = sum(n for _, n in users)
        others = [i for i in starts[address] if i != index]
        name = names.get(graphic, f"graphic {graphic}")
        lines += [f'<div class="kl-item" id="object{index}">',
                  _piece_img(f"images/graphics/{picture}", image, f"Object template {index}"),
                  f"<p><b>{index}: {_esc(name[0].upper() + name[1:])}</b> -- "
                  f"{listing.ref(address)}</p>",
                  '<table class="kl-table"><tr><th>Graphic</th><th>Half U, V; height</th>'
                  "<th>Flags</th><th>Update routine</th></tr>"
                  f'<tr><td><a href="Objects.html#graphic{graphic}">{graphic}</a></td>'
                  f"<td>{su}, {sv}, {sz}</td><td>{_flags(flags)}</td>"
                  f"<td>{listing.routine(data.handler_of[graphic])}"
                  "</td></tr></table>"]
        if others:
            lines.append("<p>The same bytes as template "
                         + ", ".join(f'<a href="#object{i}">{i}</a>' for i in others) + ".</p>")
        if users:
            lines.append(f"<p>{_plural(copies, 'copy', 'copies')} in "
                         f"{_plural(len(rooms), 'room')}: "
                         + ", ".join(_room_link(r) for r in rooms) + ".</p>")
        else:
            lines.append("<p>No room places it.</p>")
        lines.append("</div>")
    lines.append("</div>")
    return "\n".join(lines)


# --------------------------------------------------------------------------
# Every graphic.
# --------------------------------------------------------------------------

# The groups on the Objects page: (key, title, what the group's routines do).
# A graphic goes in the first group whose routines include its own, except
# for the screen's pieces and the graphics nothing places, sorted out first.
GROUPS = [
    ("special", "Graphics 0 and 1", (),
     "Not things: 0 is an empty record, which the main loop still runs (a RET) and "
     "nothing draws, and 1 an object on its way out -- what is picked up, a puff at "
     "its end, a crumbled block -- which the drawing code empties instead of drawing "
     "(#R$B3D3)."),
    ("player", "The player", (PLAYER_LEGS, PLAYER_TOP),
     "He is two records, legs and body (#R$A76F). The legs' routine does his whole "
     "turn -- controls, turning, walking, jumping, picking up, the move and firing -- "
     "and its graphic says which way he faces and his walking frame; the body follows "
     "the legs, its graphic theirs plus 8, and keeps out of the collisions."),
    ("shots", "Bolts and puffs", (BOLT, PUFF, END_PUFF),
     "A bolt flies level at 8 units a turn and shoots down what fell from the sky; "
     "stopped by anything else it goes up in a puff. A puff is also what he, the "
     "bucket and a shot-down flyer become: a frame a turn, then gone."),
    ("doorways", "Doorways", (FIRST_PILLAR, SECOND_PILLAR),
     "Each doorway is two pillars: the first works out where the doorway is and "
     "sends him through it, the second only draws."),
    ("walls", "Walls and still things", OFFSET_ROUTINES + (JUMP_L16_D8, JUMP_L16_D12),
     "A still thing's whole update routine is to set the nudge that lines its sprite "
     "up with its position (+$12 and +$13); nothing else about it changes, so it is "
     "never redrawn unless something passes in front of it."),
    ("deadly", "Things that kill where they stand", (STILL_DEADLY, SPIKES),
     "Deadly both ways (#R$C291): whatever touches them dies. The spikes can also "
     "be pushed and fall."),
    ("blocks", "Blocks that fall and can be pushed", (PUSHABLE, HEAVY_BLOCK, SLIDING_TABLE),
     "They fall a unit a turn, and walking into one pushes it (the collision code "
     "gives it the pusher's step) -- except the heavy block, which throws its pushes "
     "away."),
    ("platforms", "Blocks that move", (SINKING_BLOCK, LIFT, BOBBER, PACER_U, PACER_V,
                                        CRUMBLING_BLOCK) + CONVEYORS,
     "Stone blocks that do something when he stands on them, or that move by "
     "themselves and carry him: the collision code gives him, standing on a thing, "
     "its step when he has none of his own (#R$B7E0)."),
    ("creatures", "Creatures", (ROAMER, SPIDER, DEADLY_BOBBER, DEADLY_PACER_U, DEADLY_PACER_V),
     "Deadly both ways (#R$C291). The heads move as the blocks do, pacing or bobbing; "
     "the spiders run about."),
    ("sky", "Things from the sky", (HOMER, SKY_ROAMER, SKY_WALKER),
     "What #R$CBAB drops into a room from a height of 216, one of the eight graphics "
     "at #R$CC09 at random. Homers fly at him and bounce off what they hit, and their "
     "routine sets no kill bits; the witch and the walker run straight, turn when they "
     "bump into something, and are deadly both ways (#R$C291). A bolt that touches any "
     "of them shoots it down, for points from its graphic number (#R$C264)."),
    ("quest", "The quest", (WELL, BUCKET, QUEST_ITEM, COLLECTABLE, PENTAGRAM_PIECE),
     'The well, the bucket it gives, the four stones, the five rune stones and the '
     'pentagram\'s eight pieces (see <a href="Quest.html">the quest</a>). Their '
     "records live in #R$D432 between rooms, and they come into a room after it is "
     "built (#R$B097)."),
    ("screen", "The panel and the border", (),
     "Drawn by the panel and the text screens, never in a room: the scroll-work at "
     "the foot of the screen (#R$BCE5), the lives icon (#R$C29A), and the border "
     "round the menu and the end screens (#R$BD59)."),
    ("unused", "Graphics nothing places", (),
     "No room, template, table or routine gives an object one of these, so the game "
     "never shows them. Most name the empty sprite; a few name a real one and have a "
     "routine that would run it."),
]

# One line on what each update routine does, for the table.
ROUTINE_SAYS = {
    NOTHING: "nothing",
    PLAYER_LEGS: "his whole turn: controls, turning, walking, jumping, taking, moving, firing",
    PLAYER_TOP: "follows the legs, 12 or 8 above them",
    FIRST_PILLAR: "the doorway: steers him to its middle and sends him through",
    SECOND_PILLAR: "sets its drawing nudge",
    BOLT: "flies, shoots down flyers, puffs when stopped",
    PUFF: "the next frame, with a burst of noise",
    END_PUFF: "vanishes",
    STILL_DEADLY: "deadly both ways; never moves",
    SPIKES: "deadly both ways; falls and can be pushed",
    PUSHABLE: "falls, and moves when pushed",
    HEAVY_BLOCK: "falls; pushes have no effect",
    SLIDING_TABLE: "falls, and moves when pushed",
    SINKING_BLOCK: "sinks a unit a turn while stood on",
    LIFT: "rises to 176 carrying him, then sinks back",
    BOBBER: "falls, then rises to 176, over and over",
    DEADLY_BOBBER: "deadly; falls, then rises to 176, over and over",
    PACER_U: "paces along U, 2 a turn, turning at a bump",
    PACER_V: "paces along V, 2 a turn, turning at a bump",
    DEADLY_PACER_U: "deadly; paces along U, turning at a bump",
    DEADLY_PACER_V: "deadly; paces along V, turning at a bump",
    SPIDER: "deadly; scuttles diagonally at random",
    ROAMER: "deadly; runs straight, turns at a bump",
    SKY_ROAMER: "deadly; runs straight, turns at a bump",
    SKY_WALKER: "deadly; walks straight, turns at a bump",
    HOMER: "flies at him, bouncing off what it hits",
    CRUMBLING_BLOCK: "crumbles a stage a turn while stood on",
    CONVEYORS[0]: "carries what stands on it forwards in U",
    CONVEYORS[1]: "carries what stands on it backwards in U",
    CONVEYORS[2]: "carries what stands on it forwards in V",
    CONVEYORS[3]: "carries what stands on it backwards in V",
    WELL: "gives the bucket after 32 turns of being shot",
    BUCKET: "put down in a quest item's room, flies to it",
    QUEST_ITEM: "is finished when the bucket reaches it",
    COLLECTABLE: "can be carried; in room 82 glides to its place",
    PENTAGRAM_PIECE: "lies still",
    JUMP_L16_D8: "sets its drawing nudge",
    JUMP_L16_D12: "sets its drawing nudge",
    0xC784: "sets its drawing nudge",
    0xC77F: "sets its drawing nudge",
    0xC74B: "sets its drawing nudge",
}


def graphic_names(data: Data) -> dict[int, str]:
    return {g: SPRITE_NAMES.get(data.sprite_of[g], "a piece of the pentagram"
                                if data.sprite_of[g] in PENTAGRAM_SPRITES else "")
            for g in range(pd.GRAPHIC_COUNT)}


def _objects_page(data: Data, listing: Listing, pictures: dict[int, str],
                  names: dict[int, str]) -> tuple[str, dict[int, str]]:
    uses = {g: data.uses_of(g, listing) for g in range(pd.GRAPHIC_COUNT)}
    screen = set(data.panel) | set(data.border) | {data.lives_icon}
    group_of = {}
    for graphic in range(pd.GRAPHIC_COUNT):
        handler = data.handler_of[graphic]
        if graphic < 2:
            group_of[graphic] = "special"
            continue
        if graphic in screen:
            group_of[graphic] = "screen"
            continue
        if graphic > 1 and not uses[graphic] and handler in (NOTHING, PENTAGRAM_PIECE,
                                                            JUMP_L16_D8, JUMP_L16_D12):
            group_of[graphic] = "unused"
            continue
        for key, _, routines, _ in GROUPS:
            if handler in routines:
                group_of[graphic] = key
                break
        else:
            group_of[graphic] = "unused"
    # The placed collectables run a still thing's routine, but belong with the quest.
    for graphic in range(152, 157):
        if uses[graphic]:
            group_of[graphic] = "quest"
    lines = ['<div class="kl-list">',
             f"<p>Every one of the {pd.GRAPHIC_COUNT} graphic numbers. An object's graphic, "
             "the first byte of its record, is all it is: it picks the sprite it is drawn "
             f"with, through {listing.ref(pd.GRAPHICS)}, and the update routine the main "
             f"loop runs for it every turn, through {listing.ref(pd.HANDLERS)}. There is no "
             "separate frame number: a thing animates, or turns into something else, by "
             "changing its own graphic -- a walking frame, a puff's next frame, a stone "
             "finished by the bucket.</p>",
             "<p>They are grouped here by what their routines do. Each line gives the "
             "sprite (click it for the sprite, or the address for its entry in the "
             "listing), the routine and a line on what it does, and where the graphic "
             "comes from: the scenery and object templates that name it, the quest's "
             "records, the tables the panel, the border and the sky are drawn from, and "
             "the routines that give it to an object. Knight Lore has the same two tables, "
             'by object type (see <a href="../knightlore/Objects.html">Knight Lore\'s '
             "objects</a>).</p>",
             "<p>Graphic 0 is an empty record and 1 one about to be emptied; neither is "
             "drawn. Graphic numbers run to "
             f"{pd.GRAPHIC_COUNT - 1}, and {sum(1 for g in group_of if group_of[g] == 'unused')} "
             "of them are never placed.</p>",
             "<p>" + " -- ".join(f'<a href="#{key}">{title}</a>' for key, title, _, _ in GROUPS)
             + "</p>"]
    for key, title, _, says in GROUPS:
        members = [g for g in range(pd.GRAPHIC_COUNT) if group_of[g] == key]
        if not members:
            continue
        lines += [f'<h3 id="{key}">{title}</h3>', f"<p>{says}</p>",
                  '<table class="kl-table"><tr><th>Graphic</th><th>Sprite</th>'
                  "<th>What it shows</th><th>Update routine</th><th>Where it comes from</th></tr>"]
        rows = []
        for graphic in members:
            sprite = data.sprite_of[graphic]
            handler = data.handler_of[graphic]
            picture = pictures.get(sprite)
            cell = (f'<a href="Sprites.html#sprite{sprite:04x}"><img class="kl-thumb" '
                    f'src="{picture}" alt=""></a><br>' if picture else "")
            cell += listing.ref(sprite, f"${sprite:04X}")
            routine = f"{listing.routine(handler)}: {_esc(ROUTINE_SAYS.get(handler, ''))}"
            where = "; ".join(uses[graphic]) or "nothing places it"
            rows.append([graphic, cell, _esc(names[graphic] or ""), routine, where])
        # A run of graphics with the same routine, or from the same place,
        # shares one cell for it.
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

def _numbers(values: list[int]) -> str:
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
    for start, end in _numbers(graphics):
        if start == end:
            out.append(f'<a href="Objects.html#graphic{start}">{start}</a>')
        else:
            out.append(f'<a href="Objects.html#graphic{start}">{start}</a>-'
                       f'<a href="Objects.html#graphic{end}">{end}</a>')
    return ", ".join(out)


def _font_picture(memory, code: int):
    """A character as the print routine (#R$BAEA) reads it: eight bytes, the
    top row first."""
    from PIL import Image

    base = pd.FONT + 8 * (code - pd.FONT_FIRST)
    image = Image.new("RGB", (8, 8))
    pixels = image.load()
    for row in range(8):
        byte = memory[base + row]
        for bit in range(8):
            if byte & (0x80 >> bit):
                pixels[bit, row] = (255, 255, 255)
    return image.resize((8 * FONT_SCALE, 8 * FONT_SCALE), Image.NEAREST)


def draw_sprites(memory, image_dir: Path) -> dict[int, str]:
    """Every sprite with a width and a height, drawn from its bytes: the
    pictures, by address, as page paths."""
    import build_pentagram as bp

    pictures = {}
    for address, _, _ in pd.sprite_entries(memory):
        if memory[address] & 0x0F and memory[address + 1]:
            name = f"sprite{address:04x}.png"
            bp.sprite_image(memory, address, SPRITE_SCALE).save(image_dir / name)
            pictures[address] = f"images/graphics/{name}"
    return pictures


def _sprites_page(data: Data, listing: Listing, pictures: dict[int, str],
                  group_of: dict[int, str], image_dir: Path) -> str:
    memory = data.memory
    users: dict[int, list[int]] = {}
    for graphic, sprite in enumerate(data.sprite_of):
        users.setdefault(sprite, []).append(graphic)
    unreached = [a for a, _, g in data.sprites if not g]
    lines = ['<div class="kl-list">',
             f"<p>Every sprite record, {sum(1 for _, n, _ in data.sprites if n != 8)} of them end to end from "
             f"{listing.ref(pd.SPRITES)} to the variables at {listing.ref(0xA709)}, with the "
             f"font among them at {listing.ref(pd.FONT)}. Each is drawn from its own bytes "
             f"the way the drawing code ({listing.ref(0xB3D3)}) reads them: a width byte "
             "(bits 0-3 the width in bytes), a height byte, then a mask byte and an image "
             "byte for each byte of each row, the bottom row first. Where the mask is set "
             "the background is cleared, and the image is laid in wherever it is set -- so "
             "an image bit shows whether or not the mask is set, a mask bit with no image "
             "is black, and where both are clear the background shows through (here, the "
             "blue-grey). This is Knight Lore's format "
             '(see <a href="../knightlore/Sprites.html">Knight Lore\'s sprites</a>).</p>',
             f"<p>Bits 6 and 7 of the width byte say whether the bytes are stored mirrored "
             f"or upside down at the moment: {listing.ref(0xB2EE)} turns a sprite round in "
             "place, rewriting its bytes and toggling the bits, whenever it is drawn for an "
             "object facing the other way. On the tape every sprite is stored the right way "
             "round, with both bits clear, which is how they are drawn here.</p>",
             "<p>Beside each are the graphic numbers that name it (a graphic is an object's "
             f"first byte, looked up in {listing.ref(pd.GRAPHICS)}); see "
             '<a href="Objects.html">every graphic</a> for what each is. Sprites marked '
             "<i>never drawn</i> are named only by graphics nothing places, and "
             f"{_plural(len(unreached), 'record')} no graphic number reaches at all.</p>",
             "<p>" + " -- ".join(f'<a href="#{a}">{t}</a>' for a, t in
                                 (("sprites", "The sprites"), ("font", "The font"))) + "</p>",
             '<h3 id="sprites">The sprites</h3>']
    lines.append('<table class="kl-table"><tr><th>Sprite</th><th>Entry</th><th>What it shows</th>'
                 "<th>Size</th><th>Width byte</th><th>Graphics</th></tr>")
    for address, length, graphics in data.sprites:
        head, height = memory[address], memory[address + 1]
        width = head & 0x0F
        label = listing.name(address)
        name = SPRITE_NAMES.get(address) or ("a piece of the pentagram"
                                             if address in PENTAGRAM_SPRITES else "")
        picture = (f'<img class="kl-sprite" src="{pictures[address]}" alt="{label}">'
                   if address in pictures else "")
        if width and height:
            size = f"{width * 8} by {height} pixels; {length} bytes"
            header = f"${head:02X}" + (", flipped" if head & 0xC0 else "")
        elif length == 2:
            size, header = "0 by 0: nothing is drawn", f"${head:02X}"
            name = ""
        else:
            size, header = f"{length} bytes that are not a sprite", ""
        if graphics:
            used = _graphic_links(graphics)
            if all(group_of.get(g) == "unused" for g in graphics):
                used += "<br><i>Never drawn</i>: nothing places any of them"
        else:
            used = "<i>No graphic number reaches it</i>: never drawn"
        lines.append(f'<tr id="sprite{address:04x}"><td>{picture}</td>'
                     f"<td>{listing.ref(address, label)}<br>${address:04X}</td><td>{_esc(name)}</td>"
                     f"<td>{size}</td><td>{header}</td><td>{used}</td></tr>")
    lines.append("</table>")

    # The font.
    font_dir = image_dir / "font"
    font_dir.mkdir(parents=True, exist_ok=True)
    cells = []
    for index in range(pd.FONT_CHARS):
        code = pd.FONT_FIRST + index
        name = f"char{code:02x}.png"
        _font_picture(memory, code).save(font_dir / name)
        shown = chr(code) if chr(code).isalnum() else f"${code:02X}"
        cells.append(f'<td><img class="kl-thumb" src="images/graphics/font/{name}" '
                     f'alt="{_esc(shown)}"><br>{_esc(shown)}</td>')
    rows = "".join("<tr>" + "".join(cells[i:i + 11]) + "</tr>" for i in range(0, len(cells), 11))
    blank = [pd.FONT_FIRST + i for i in range(pd.FONT_CHARS)
             if not any(memory[pd.FONT + 8 * i:pd.FONT + 8 * i + 8])]
    lines += ['<h3 id="font">The font</h3>',
              f"<p>{pd.FONT_CHARS} characters of 8 by 8 pixels at {listing.ref(pd.FONT)}, "
              f"for the codes ${pd.FONT_FIRST:02X} to ${pd.FONT_FIRST + pd.FONT_CHARS - 1:02X}: "
              "the digits; a full stop, a percent sign and a copyright sign; "
              f"{_plural(len(blank), 'blank character')} ("
              + ", ".join(f"${c:02X}" for c in blank) + "); and the capital letters. "
              "Each is eight bytes, the "
              f"top row first, as the print routine ({listing.ref(0xBAEA)}) copies them into "
              "the screen buffer. There is no lower case, and a space is printed as code $3D, "
              "the first of the blanks. For text, the print routine's base is 384 bytes below the font, "
              "so that the codes land on these characters; for the score and the lives it is "
              "the font itself, so that the digits are codes 0 to 9. Drawn here in white; "
              "the game colours text by the attributes it prints with.</p>",
              '<table class="kl-table">' + rows + "</table>",
              "</div>"]
    return "\n".join(lines)


# --------------------------------------------------------------------------
# Together.
# --------------------------------------------------------------------------

def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    """Draw the pictures into html_dir/images/graphics and return the
    Scenery, Templates, Objects and Sprites sections."""
    import build_pentagram as bp

    memory = bp.game_memory(snapshot)
    listing = Listing(snapshot.with_name("pentagram.skool"))
    data = Data(memory)
    image_dir = html_dir / "images" / "graphics"
    image_dir.mkdir(parents=True, exist_ok=True)
    names = graphic_names(data)

    log("  graphics: drawing the sprites from their bytes...")
    pictures = draw_sprites(memory, image_dir)
    log("  graphics: starting a game to draw the scenery and templates with...")
    stage = Stage(snapshot, data)
    scenery = _scenery_page(data, stage, listing, image_dir)
    templates = _templates_page(data, stage, listing, image_dir, names)
    objects, group_of = _objects_page(data, listing, pictures, names)
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
    log(f"  graphics: {len(pictures)} sprites, {pd.SCENERY_COUNT} scenery and "
        f"{pd.OBJECT_COUNT} object templates drawn")
    return sections
