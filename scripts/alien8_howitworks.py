"""Alien 8's "How it works" pages: drawing, the robot's movement, rooms and
doorways, the valves and the cryogenic chambers, and the clock, the
remote-controlled robots and the dangers.

build() returns each page's HTML for the build's generated ref file and
writes the pictures into html_dir/images/howitworks/. Nothing here is a
transcription of the game: every table is read from the game's memory as the
page is built, and every worked example is the game's own code, run in
SkoolKit's simulator -- the build's own Machine (build_alien8.py), started
from the snapshot at $6300 and driven the way the build's sessions drive it,
by keys and by the game's own restart. Where a scene is staged by writing to
memory, the page says what was written.

Alien 8 sits between Knight Lore and Pentagram on the same engine. Where it
does what one of them does, the page says so briefly and links that game's
page, and puts its depth on what is Alien 8's own. The prose is written from
the listing's annotations and the stage 2 notes (notes/alien8/). Numbers the
prose quotes from the game's code are read back from the runs below, and the
build stops if a run does not come out the way the code says it must.
"""
from __future__ import annotations

import re
from pathlib import Path

import alien8_data as ad
import build_alien8 as ba

IMAGE_URL = "images/howitworks"
KNIGHT_LORE = "../knightlore"
PENTAGRAM = "../pentagram"
TSTATES = 3500000

# --------------------------------------------------------------------------
# Addresses read or run here (see their entries in the listing).
# --------------------------------------------------------------------------

OBJECTS = 0x5B88            # 56 records of 32 bytes
RECORD = 32
RECORD_COUNT = 56
PLAYER = OBJECTS            # the legs
TOP = OBJECTS + RECORD      # the top
VALVES = OBJECTS + 2 * RECORD   # records 2 and 3: what lies in the room from the places
ROOM_OBJECTS = OBJECTS + 4 * RECORD
UPDATES = 0xA7EA            # a word per graphic

MAIN_LOOP = 0xA68E          # MAIN_NEXT_TURN: the start of a turn
TURN_OVER = 0xA6DC          # MAIN_END_OF_TURN: every object updated
LISTED = 0xA6F4             # ...and the draw list made
WIPED = 0xCF5F              # in RENDER_DYNAMIC_OBJECTS: the wipes done, the sort next
SORTED = 0xCF62             # ...everything drawn into the buffer
COPIED = 0xCF82             # ...the rectangles copied to the screen
RUN_CLOCK = 0xAD66
DRAW_OBJECT = 0xD013        # CALC_PIXEL_XY_AND_RENDER
DRAW_AND_NEXT_PASS = 0xC8D8
DRAW_LIST = 0xC745
DRAW_LIST_SIZE = 64
SORT_AND_DRAW = 0xC785
CANDIDATE_CHAIN = 0xC8EF
CANDIDATE_CHAIN_SIZE = 16
DEPTH_ORDER = 0xC833
CALC_PIXEL_XY = 0xCFD2
RENDER = 0xCEAB
LIST_DRAWN = 0xC71C
SET_DRAW_OBJS_OVERLAPPED = 0xC657
SET_WIPE_AND_DRAW_FLAGS = 0xBFAB
DEC_DZ_AND_UPDATE_UVZ = 0xBFB6
ADJ_FOR_OUT_OF_BOUNDS = 0xC442
BOXES_INTERSECT = 0xC8AB
OBJECT_DONE = 0xA6C0
AFTER_GAME = 0xA647

SEED = 0x5B00
TURNS = 0x5B02
CONTROL = 0x5B04
RANDOM = 0x5B05
WIPE_COUNT = 0x5B08
ROOM_HALF = 0x5B0B          # U, then V
ROOM_INK = 0x5B0D
FLOOR = 0x5B0E
NEW_ROOM = 0x5B17
LIVES = 0x5B1A
DRAW_WORK = 0x5B1E
WON = 0x5B23
GAME_OVER = 0x5B24
LIFT_TOP = 0x5B25
CLOCK = 0x5B36
DROPPING = 0x5B3A
DROP_LATCH = 0x5B3B
SUMMARY_LOST = 0x5B3C
SUMMARY_ACTIVE = 0x5B3E
SUMMARY_IDLE = 0x5B3F
CHAMBERS = 0x5B40
REMOTE_ORDERS = 0x5B42
LEAPING = 0x5B43
CARRIED_NEW = 0x5B78
BUFFER = 0xD200
START_LEGS = 0xCA1D
START_TOP = 0xCA3D
PLACES = ad.PLACES
PLACE_SIZE = ad.PLACE_SIZE

# Offsets into a record.
FLAGS = 7
ROOM = 8
BUMPED = 0x0C
CONTACT = 0x0D

SPECTRUM = [(0, 0, 0), (0, 0, 0xD7), (0xD7, 0, 0), (0xD7, 0, 0xD7),
            (0, 0xD7, 0), (0, 0xD7, 0xD7), (0xD7, 0xD7, 0), (0xD7, 0xD7, 0xD7)]
SPECTRUM_BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF),
                   (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0), (0xFF, 0xFF, 0xFF)]
OUTLINE = (255, 64, 64)


def _word(memory, address: int) -> int:
    return memory[address] | memory[address + 1] << 8


def _signed(byte: int) -> int:
    return byte - 256 if byte & 0x80 else byte


def _esc(text: str) -> str:
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def _bcd(value: int) -> int:
    return (value >> 4) * 10 + (value & 15)


# --------------------------------------------------------------------------
# The listing: which addresses are entries, for #R links.
# --------------------------------------------------------------------------

class Listing:
    """The entries of alien8.skool and every label in it, read at build
    time, so a link is only made to an address that starts an entry."""

    def __init__(self, skool: Path):
        self.entries: dict[int, str] = {}
        self.labels: dict[int, str] = {}
        label = None
        for line in skool.read_text(encoding="utf-8").split("\n"):
            if line.startswith("@label="):
                label = line[len("@label="):]
                continue
            match = re.match(r"^([bcgistuw ]|\*)\$([0-9A-F]{4})", line)
            if match:
                address = int(match.group(2), 16)
                if match.group(1) not in (" ", "*"):
                    self.entries[address] = label or ""
                if label:
                    self.labels[address] = label
                label = None
            elif not line.startswith("@"):
                label = None if not line.startswith(";") else label
        self.containing = sorted(self.entries)
        self.unlinked: set[int] = set()

    def entry_of(self, address: int) -> int | None:
        found = None
        for start in self.containing:
            if start > address:
                break
            found = start
        return found

    def r(self, address: int) -> str:
        """A link to an entry; an entry point inside one links its entry
        with the entry point's own label as the text."""
        if address in self.entries:
            return f"#R${address:04X}"
        entry = self.entry_of(address)
        if entry is not None and address in self.labels:
            return f"#R${entry:04X}({self.labels[address]})"
        self.unlinked.add(address)
        return f"${address:04X}"

    def name(self, address: int) -> str:
        return self.labels.get(address) or self.entries.get(address) or f"${address:04X}"


# --------------------------------------------------------------------------
# The game, in the simulator.
# --------------------------------------------------------------------------

class Game:
    """The game on the build's simulated Spectrum (build_alien8.Machine),
    started from the menu with the keyboard and driven turn by turn."""

    def __init__(self, snapshot: Path, start: bool = True):
        self.machine = ba.Machine(snapshot)
        if start:
            self.play(ba._start("1"))

    @property
    def memory(self):
        return self.machine.memory

    @property
    def registers(self):
        return self.machine.simulator.registers

    def play(self, steps) -> None:
        self.machine.play(steps, "how it works")

    def run_to(self, stop: int, seconds: float = 10.0, keys=(), stick: int = 0) -> None:
        """Run until PC reaches `stop` -- at least one instruction first, so
        stopping at the same place again catches the next time round -- or
        fail, naming where it was, after `seconds` of the game's time."""
        from skoolkit.simutils import PC, T

        simulator = self.machine.simulator
        self.machine.tracer.keys = set(keys)
        self.machine.tracer.kempston = stick
        limit = simulator.registers[T] + int(seconds * TSTATES)
        simulator.trace(self.machine.pc, stop, 0, limit, False, None, None, None, None, None)
        self.machine.pc = simulator.registers[PC]
        if self.machine.pc != stop:
            raise RuntimeError(f"the game never reached ${stop:04X} in {seconds} s "
                               f"(PC ${self.machine.pc:04X})")

    def turns(self, count: int = 1, keys=(), stick: int = 0) -> None:
        """Play whole turns, each to the start of the next."""
        for _ in range(count):
            self.run_to(MAIN_LOOP, 10.0, keys, stick)

    def go(self, room: int, spot=None) -> None:
        """Into a room by the game's own restart (build_alien8._go), then to
        the start of a turn."""
        self.play(ba._go(room, spot))
        self.turns(1)

    def ix(self) -> int:
        from skoolkit.simutils import IXh, IXl

        return self.registers[IXh] << 8 | self.registers[IXl]

    def iy(self) -> int:
        from skoolkit.simutils import IYh, IYl

        return self.registers[IYh] << 8 | self.registers[IYl]

    @staticmethod
    def record(index: int) -> int:
        return OBJECTS + RECORD * index

    def find(self, graphics, after: int = 0) -> int | None:
        for index in range(after, RECORD_COUNT):
            if self.memory[self.record(index)] in graphics:
                return self.record(index)
        return None

    def find_all(self, graphics) -> list[int]:
        return [self.record(i) for i in range(RECORD_COUNT)
                if self.memory[self.record(i)] in graphics]


def call(memory, address: int, registers: dict | None = None, seconds: float = 2.0):
    """Run one routine on a fresh simulator over `memory` until it returns;
    the simulator afterwards. A return address nothing else uses is pushed
    first, at $F0FE, the top of the game's own stack space: $62FD, the first
    byte the tape loads, which the game never runs (the simulator stops as
    the routine's RET reaches it)."""
    from skoolkit import CSimulator
    from skoolkit.simulator import Simulator
    from skoolkit.simutils import PC, SP

    memory = list(memory)
    trap = 0x62FD
    stack = 0xF0FE
    memory[stack:stack + 2] = [trap & 0xFF, trap >> 8]
    simulator = (CSimulator or Simulator)(memory, state={"iff": 0, "im": 1, "tstates": 0})
    for index, value in (registers or {}).items():
        simulator.registers[index] = value
    simulator.registers[SP] = stack
    simulator.registers[PC] = address
    simulator.set_tracer(ba._key_tracer_class()(simulator))
    simulator.trace(address, trap, 0, int(seconds * TSTATES), False, None, None, None,
                    None, None)
    if simulator.registers[PC] != trap:
        raise RuntimeError(f"${address:04X} did not return (PC ${simulator.registers[PC]:04X})")
    return simulator


# --------------------------------------------------------------------------
# Pictures.
# --------------------------------------------------------------------------

def screen_image(memory):
    """The display file with its attributes, as a 256 by 192 picture."""
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


def screen_of(screen_bytes):
    """screen_image of the 6912 bytes kept from $4000."""
    return screen_image([0] * 0x4000 + list(screen_bytes))


def buffer_image(memory):
    """The screen buffer at $D200 as a picture: 192 rows of 32 bytes, its
    first row the bottom line of the screen, white on black."""
    from PIL import Image

    image = Image.new("RGB", (256, 192))
    pixels = image.load()
    for y in range(192):
        row = BUFFER + (191 - y) * 32
        for column in range(32):
            byte = memory[row + column]
            for bit in range(8):
                if byte & (0x80 >> bit):
                    pixels[column * 8 + bit, y] = (255, 255, 255)
    return image


def outlined(image, rects, colour=OUTLINE):
    """The picture with rectangles (column, top row, width in bytes, height)
    outlined, at twice the size so the outline sits outside the pixels."""
    from PIL import Image, ImageDraw

    big = image.resize((image.width * 2, image.height * 2), Image.NEAREST)
    draw = ImageDraw.Draw(big)
    for column, top, width, height in rects:
        draw.rectangle([column * 16, top * 2, (column + width) * 16 - 1, (top + height) * 2 - 1],
                       outline=colour, width=2)
    return big


def strip(images, gap: int = 4, background=(20, 20, 60)):
    """Pictures side by side."""
    from PIL import Image

    width = sum(image.width for image in images) + gap * (len(images) - 1)
    height = max(image.height for image in images)
    out = Image.new("RGB", (width, height), background)
    x = 0
    for image in images:
        out.paste(image, (x, 0))
        x += image.width + gap
    return out


def grid(images, columns: int, gap: int = 4, background=(20, 20, 60)):
    """Pictures in rows of `columns`."""
    from PIL import Image

    width = max(image.width for image in images)
    height = max(image.height for image in images)
    rows = (len(images) + columns - 1) // columns
    out = Image.new("RGB", (columns * width + (columns - 1) * gap,
                            rows * height + (rows - 1) * gap), background)
    for k, image in enumerate(images):
        out.paste(image, ((k % columns) * (width + gap), (k // columns) * (height + gap)))
    return out


class Pictures:
    """Saves pictures under html_dir/images/howitworks and writes the <img>
    tags for them."""

    def __init__(self, html_dir: Path):
        self.dir = Path(html_dir) / "images" / "howitworks"
        self.dir.mkdir(parents=True, exist_ok=True)

    def save(self, name: str, image) -> str:
        image.save(self.dir / name)
        return name

    def stage(self, name: str, image, alt: str = "") -> str:
        """A whole screen (or a picture twice a screen's size): 512 wide."""
        self.save(name, image)
        return f'<img class="kl-stage" src="{IMAGE_URL}/{name}" alt="{_esc(alt)}">'

    def piece(self, name: str, image, alt: str = "", scale: int = 2,
              css: str = "kl-piece") -> str:
        self.save(name, image)
        return (f'<img class="{css}" src="{IMAGE_URL}/{name}" alt="{_esc(alt)}" '
                f'width="{image.width * scale}" height="{image.height * scale}">')

    def strip(self, name: str, images, alt: str = "") -> str:
        """Pictures side by side, twice their size unless that is too wide."""
        image = strip(images)
        return self.piece(name, image, alt, 2 if image.width <= 560 else 1)


def figure(img: str, caption: str) -> str:
    return f'<div class="kl-item">{img}<p>{caption}</p></div>'


def table(headings: list[str], rows: list[list]) -> str:
    head = "".join(f"<th>{h}</th>" for h in headings)
    body = "".join("<tr>" + "".join(f"<td>{cell}</td>" for cell in row) + "</tr>"
                   for row in rows)
    return f'<table class="kl-table"><tr>{head}</tr>{body}</table>'


def kl(page: str, text: str) -> str:
    return f'<a href="{KNIGHT_LORE}/{page}.html">{text}</a>'


def pg(page: str, text: str) -> str:
    return f'<a href="{PENTAGRAM}/{page}.html">{text}</a>'


def _check(condition: bool, what: str) -> None:
    """The prose says what the code does; if a run disagrees, the page would
    be wrong, so the build stops instead."""
    if not condition:
        raise RuntimeError(f"alien8_howitworks: {what}")


def update_routine(memory, graphic: int) -> int:
    return _word(memory, UPDATES + 2 * graphic)


def sprite_of(memory, graphic: int):
    """A graphic's sprite, drawn from its bytes as the listing's sprite
    pictures are (build_alien8.sprite_image), at its own size."""
    return ba.sprite_image(memory, _word(memory, ad.GRAPHICS + 2 * graphic), scale=1)


# --------------------------------------------------------------------------
# Shared: where the game's data puts each graphic, and links to the other
# pages: the room structure page anchors rooms by their number in hex, as
# Knight Lore's does (room4e); the graphics pages anchor graphics, object
# templates (the table's index, 32 on for the second page) and backgrounds
# by number (graphic96, template24, background3).
# --------------------------------------------------------------------------

def room_ref(number: int, text: str | None = None) -> str:
    return f'<a href="RoomStructure.html#room{number:02x}">{text or f"room ${number:02X}"}</a>'


def graphic_ref(graphic: int, text: str | None = None) -> str:
    return f'<a href="Objects.html#graphic{graphic}">{text if text is not None else graphic}</a>'


def template_ref(template: int, text: str | None = None) -> str:
    return (f'<a href="Templates.html#template{template}">'
            f'{text if text is not None else template}</a>')


def background_ref(index: int, text: str | None = None) -> str:
    return (f'<a href="Scenery.html#background{index}">'
            f'{text if text is not None else index}</a>')


def numbers(values, link=graphic_ref) -> str:
    """Numbers as runs, 1, 2, 3, 5 as '1-3, 5', each end linked."""
    values = sorted(values)
    if not values:
        return "none"
    runs, start = [], None
    for index, value in enumerate(values):
        if start is None:
            start = value
        if index + 1 == len(values) or values[index + 1] != value + 1:
            runs.append(link(start) if start == value else f"{link(start)}-{link(value)}")
            start = None
    return ", ".join(runs)


def room_list(rooms, limit: int = 14) -> str:
    if not rooms:
        return "no room"
    linked = [room_ref(r, f"${r:02X}") for r in rooms]
    if len(rooms) > limit:
        return f"{len(rooms)} rooms, from {', '.join(linked[:limit])} ..."
    return ("room " if len(rooms) == 1 else "rooms ") + ", ".join(linked)


def template_pieces(memory, template: int) -> list[tuple]:
    """An object template's pieces: (graphic, half U, half V, height, flags)."""
    address = _word(memory, ad.OBJECT_TABLE + 2 * template)
    pieces = []
    if not address:
        return pieces
    while True:
        pieces.append(tuple(memory[address:address + 5]))
        address += 5
        if memory[address] == 0:
            return pieces


def background_pieces(memory, index: int) -> list[tuple]:
    """A background's pieces: (graphic, U, V, Z, half U, half V, height, flags)."""
    address = _word(memory, ad.BACKGROUND_TABLE + 2 * index)
    pieces = []
    while memory[address]:
        pieces.append(tuple(memory[address:address + 8]))
        address += 8
    return pieces


def room_templates(record) -> list[tuple[int, list[int]]]:
    """A room record's object groups as (template, positions), with the
    second page's templates numbered 32 on, as the builder reaches them
    (a template-31 header moves it on by 32 entries)."""
    page = 0
    out = []
    for _, template, _, positions in record["groups"]:
        if template == 31:
            page += 32
            continue
        if template == 0:
            continue
        out.append((page + template, positions))
    return out


def room_graphics(memory) -> dict[int, list[int]]:
    """Each graphic the room data places, and the rooms it is in: objects by
    each piece of their template, backgrounds by each of their pieces."""
    out: dict[int, set] = {}
    for record in ad.room_records(memory):
        for _, background in record["backgrounds"]:
            for piece in background_pieces(memory, background):
                out.setdefault(piece[0], set()).add(record["number"])
        for template, _ in room_templates(record):
            for piece in template_pieces(memory, template):
                out.setdefault(piece[0], set()).add(record["number"])
    return {graphic: sorted(rooms) for graphic, rooms in out.items()}


def rooms_with_templates(memory, templates) -> list[int]:
    return sorted(record["number"] for record in ad.room_records(memory)
                  if any(t in templates for t, _ in room_templates(record)))


# --------------------------------------------------------------------------
# 1. How a moving object is drawn.
# --------------------------------------------------------------------------

TRACE_ROOM = 0xA6           # a pacer on a platform of lifts
TRACE_TURNS = 3             # turns played in the room before the one traced


def trace_turn(game: Game) -> dict:
    """Follow one turn through the drawing: the screen before, what each
    update flagged, the rectangles wiped, the order things are drawn in, the
    buffer after the wipe and after the drawing, and the screen after."""
    from skoolkit.simutils import SP

    memory = game.memory
    before = screen_image(memory)
    start = {}
    for index in range(RECORD_COUNT):
        base = game.record(index)
        start[index] = (memory[base], bytes(memory[base + 1:base + 4]))
    game.run_to(TURN_OVER)
    objects = {}
    for index in range(RECORD_COUNT):
        base = game.record(index)
        flags = memory[base + FLAGS]
        if memory[base] and flags & 0x30:
            graphic, place = memory[base], bytes(memory[base + 1:base + 4])
            objects[index] = {"graphic": graphic, "was": start[index][0],
                              "moved": place != start[index][1],
                              "wipe": bool(flags & 0x20), "place": tuple(place)}
    game.run_to(LISTED)
    listed = []
    address = DRAW_LIST
    while memory[address] != 0xFF:
        listed.append(memory[address])
        address += 1
    game.run_to(WIPED)
    rects = []
    stack = game.registers[SP]
    for k in range(memory[WIPE_COUNT]):
        base = stack + 6 * k
        offset = _word(memory, base) - BUFFER
        height, width = memory[base + 4], memory[base + 5]
        bottom = 191 - offset // 32
        rects.append((offset % 32, bottom - height + 1, width, height))
    wiped = buffer_image(memory)
    order = []
    for _ in listed:
        game.run_to(DRAW_OBJECT)
        order.append((game.ix() - OBJECTS) // RECORD)
    game.run_to(SORTED)
    drawn = buffer_image(memory)
    game.run_to(COPIED)
    work = memory[DRAW_WORK]
    after = screen_image(memory)
    game.run_to(MAIN_LOOP)
    return {"before": before, "wiped": wiped, "drawn": drawn, "after": after,
            "objects": objects, "listed": listed, "order": order,
            "rects": list(reversed(rects)), "work": work}


SURVEY_TURNS = 24           # turns watched in each room, from its first


def survey_rooms(game: Game, rooms: list[int], turns: int = SURVEY_TURNS) -> dict:
    """Each room from its first turn: the longest draw list and the longest
    chain of candidates the depth sort builds in `turns` turns, the robot
    standing where he appears; and, on the first turn, every picture whose
    projected x is left of the screen and has wrapped round."""
    memory = game.memory
    out = {}
    for room in rooms:
        ba._lives(memory)
        for record in (START_LEGS, START_TOP):
            memory[record + ROOM] = room
            memory[record + 1], memory[record + 2] = ba.CLEAR_SPOT
        ba._kill(memory)
        for _ in range(400):
            game.run_to(LISTED)
            if memory[PLAYER + ROOM] == room and memory[NEW_ROOM]:
                break
        else:
            raise RuntimeError(f"room ${room:02X} never came")
        wrapped = []
        for index in range(RECORD_COUNT):
            base = game.record(index)
            if memory[base] > 1:
                x = memory[base + 1] + memory[base + 2] - 128 + _signed(memory[base + 0x12])
                if x < 0:
                    wrapped.append((memory[base], x))
        longest_list, longest_chain, first_list = 0, 0, None
        for turn in range(turns):
            if turn:
                ba._lives(memory)
                game.run_to(LISTED)
            listed = 0
            while memory[DRAW_LIST + listed] != 0xFF:
                listed += 1
            if first_list is None:
                first_list = listed
            longest_list = max(longest_list, listed)
            for _ in range(listed):
                game.run_to(DRAW_AND_NEXT_PASS)
                length = 0
                while memory[CANDIDATE_CHAIN + length] != 0xFF and length < CANDIDATE_CHAIN_SIZE:
                    length += 1
                longest_chain = max(longest_chain, length)
        records = sum(1 for index in range(RECORD_COUNT) if memory[game.record(index)])
        out[room] = {"first": first_list, "list": longest_list, "chain": longest_chain,
                     "wrapped": wrapped, "records": records}
    return out


CORNER_ROOM = 0x4E          # the start room: its corner at low U and low V is clear
CORNER_FROM = (84, 84)


def walk_into_corner(snapshot: Path) -> dict:
    """The robot walked as far as the walls let him towards low U, then
    towards low V, in a full-sized room: where he stops, and the pixel x his
    legs are drawn at there."""
    game = Game(snapshot)
    game.go(CORNER_ROOM, CORNER_FROM)
    memory = game.memory
    out = {}
    for facing, graphic, mirror in (("low U", 17, 0), ("low V", 21, 0x40)):
        memory[PLAYER] = graphic
        memory[PLAYER + FLAGS] = memory[PLAYER + FLAGS] & 0xBF | mirror
        for _ in range(12):
            ba._lives(memory)
            game.turns(1, ["a"])
        game.turns(2)
        out[facing] = (memory[PLAYER + 1], memory[PLAYER + 2])
    out["x"] = memory[PLAYER + 0x1A]
    out["top x"] = memory[TOP + 0x1A]
    out["half"] = memory[PLAYER + 4]
    out["wall"] = 128 - memory[ROOM_HALF]
    out["screen"] = screen_image(memory)
    out["rect"] = tuple(memory[PLAYER + 0x18:PLAYER + 0x1C])
    return out


def _drawing_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    R = listing.r
    memory = ba.game_memory(snapshot)
    game = Game(snapshot)
    game.go(TRACE_ROOM, ba.CLEAR_SPOT)
    game.turns(TRACE_TURNS)
    frame = trace_turn(game)
    rects = frame["rects"]
    moved = [i for i, o in frame["objects"].items() if o["wipe"]]
    _check(len(rects) == len(moved), f"{len(moved)} objects moved but {len(rects)} "
                                     f"rectangles were wiped")
    _check(sorted(frame["order"]) == sorted(frame["listed"]),
           "the objects drawn are not the objects listed")
    _check(frame["work"] == len(frame["order"]) + len(rects),
           f"DRAW_WORK is {frame['work']}, not objects drawn plus areas wiped")
    _check(0 in moved and 1 in moved, "the robot's two records were not both marked to wipe")
    images = {}
    for name in ("before", "wiped", "drawn", "after"):
        images[name] = pictures.stage(f"drawing_{name}.png", outlined(frame[name], rects),
                                      f"The {name} stage")

    rows = []
    for position, index in enumerate(frame["order"], 1):
        o = frame["objects"].get(index)
        graphic = o["graphic"] if o else game.memory[OBJECTS + RECORD * index]
        routine = update_routine(memory, graphic)
        if index == 1 and o and o["wipe"]:
            why = "the top: marks itself every turn, following the legs"
        elif index == 0 and o and o["wipe"] and not o["moved"]:
            why = "the legs: marked every turn, moving or not"
        elif o and o["wipe"]:
            why = ("moved" if o["moved"] else "changed picture" if o["graphic"] != o["was"]
                   else "marked by its own update")
        else:
            why = "overlaps a change"
        rows.append([position, index, graphic_ref(graphic), R(routine), why])
    rect_rows = [[c * 8, top, w * 8, h] for c, top, w, h in rects]
    upper = [i for i in moved if frame["objects"][i]["graphic"] in (86, 87, 94, 95)]
    _check(bool(upper), f"nothing two-part moved in room ${TRACE_ROOM:02X}")

    log("  every room's first turns: the draw list and the depth sort's chain...")
    rooms = ba._rooms(snapshot)
    survey = survey_rooms(Game(snapshot), rooms)
    fullest = max(survey.items(), key=lambda kv: (kv[1]["list"], -kv[0]))
    longest = max(survey.items(), key=lambda kv: (kv[1]["chain"], -kv[0]))
    chain_rooms = sorted(r for r, s in survey.items() if s["chain"] == longest[1]["chain"])
    over_kl = sorted(r for r, s in survey.items() if s["chain"] > 7)
    wrapped_rooms = sorted(r for r, s in survey.items() if s["wrapped"])
    _check(fullest[1]["list"] < DRAW_LIST_SIZE, "a list overflowed")
    _check(longest[1]["chain"] < CANDIDATE_CHAIN_SIZE, "a chain overflowed")
    _check(all(s["first"] == s["list"] for s in survey.values()),
           "a room's list was longer after its first turn than on it")
    _check(not wrapped_rooms, "a picture wrapped round on some room's first turn")

    log("  the robot walked into a corner...")
    corner = walk_into_corner(snapshot)
    cu, cv = corner["low V"]
    _check(corner["x"] == cu + cv - 128 - 16, "the legs' x in the corner is not U + V - 144")
    _check(cu == corner["wall"] + corner["half"] + 1 and cv == cu,
           f"the corner is at {cu}, {cv}; the walls say {corner['wall'] + corner['half'] + 1}")
    width, height, cx, cy = corner["rect"]
    corner_img = corner["screen"].crop((0, max(0, 191 - cy - height - 40), 96,
                                        min(192, 191 - cy + 16)))
    corner_fig = figure(pictures.piece("drawing_corner.png", corner_img,
                                       "The robot in the corner", 3),
                        f"The robot in the corner of {room_ref(CORNER_ROOM)} at U and V "
                        f"{cu}: his legs drawn at pixel x {corner['x']}.")

    drawn = len(frame["order"])
    kl_mo = kl("MovingObjects", "Knight Lore's page on the pipeline")
    kl_ds = kl("DepthSort", "Knight Lore's depth-sort page")
    pg_dr = pg("Drawing", "Pentagram's drawing page")

    return "\n".join([
        '<div class="kl-list">',
        "<p>Alien 8 draws the way Knight Lore and Pentagram do, with Pentagram's code nearly "
        f"instruction for instruction ({kl_mo}; {pg_dr}). Nothing on the screen is rubbed "
        "out and redrawn in place. Each turn only the rectangles that something changed in "
        "are rebuilt, in a buffer off the screen, in depth order, and copied across whole. "
        "This page follows the pipeline stage by stage, then a real turn of the game "
        "through it, and then measures where Alien 8 differs from its neighbours.</p>",

        "<h3>1. Every object gets a turn</h3>",
        f"<p>The main loop ({R(AFTER_GAME)}) walks all 56 object records -- the robot's legs "
        "and top, two for the valves (and extra lives) lying in the room, and 52 for the "
        "room itself. Before each object's update routine runs, the stack is reset to "
        f"$F100, the top of {R(0xEA00)}; the address of {R(OBJECT_DONE)} is pushed for "
        "the routine to return to, and where the object's picture was last drawn (+$18 to "
        "+$1B: the width in bytes, the height in rows, the pixel x and y) is copied to +$1C "
        "to +$1F: that is "
        f"what may have to be rubbed out. The routine is found by the graphic number in "
        f"{R(UPDATES)}. A fresh stack for every object is Knight Lore's way; Pentagram "
        "keeps one stack all turn.</p>",

        "<h3>2. The update routine moves it</h3>",
        f"<p>A thing that falls calls {R(DEC_DZ_AND_UPDATE_UVZ)}: one off its Z step for "
        f"gravity, then {R(ADJ_FOR_OUT_OF_BOUNDS)}, which cuts the step in U, V and Z "
        "against the floor, the walls and the other 55 records, one axis at a time, and "
        "adds what is left (see <a href=\"Movement.html\">how the robot moves</a>). A thing "
        "that animates changes its graphic number, which is its sprite; there is no frame "
        "counter in the drawing.</p>",

        "<h3>3. It marks itself, and whatever it touches</h3>",
        f"<p>Most update routines that moved or changed something end in "
        f"{R(SET_WIPE_AND_DRAW_FLAGS)}: bits 4 (<i>draw me</i>) and 5 (<i>wipe my old "
        f"picture</i>) of +$07, then {R(SET_DRAW_OBJS_OVERLAPPED)}. That works out the new "
        f"picture's rectangle ({R(0xC63D)}, projecting the position through "
        f"{R(CALC_PIXEL_XY)}: pixel x = U + V - 128 and, counted up from the bottom, pixel "
        "y = (V - U + 128)/2 + Z - 40, each plus the object's drawing nudge at +$12 and "
        "+$13), takes the rectangle covering it and the old one, and sets bit 4 on every "
        "live record whose own rectangle meets it: those will be drawn again, because the "
        "wipe takes a bite out of them. It is one level deep: what is marked does not mark "
        "its own neighbours. The robot's legs end their update this way every turn, moving "
        f"or not, and his top ({R(0xC6E4)}) copies the legs' place and graphic and marks "
        "itself the same way, so the robot is two wipes and two draws every turn.</p>",

        "<h3>4. The list, and the wipe</h3>",
        f"<p>When all 56 have had their turn, {R(LIST_DRAWN)} writes the number of every "
        f"record with bit 4 into {R(DRAW_LIST)}, and {R(RENDER)} takes each one that also "
        "has bit 5: it clears the rectangle covering its old and new pictures in the buffer "
        f"at {R(BUFFER)} -- never on the screen -- in whole bytes across and pixel rows up, "
        f"with {R(0xBF83)}, and pushes the rectangle on the stack to copy later.</p>",

        "<h3>5. Drawing, back to front</h3>",
        f"<p>{R(SORT_AND_DRAW)} then draws every listed object into the buffer, each whole "
        "and through its own mask, in an order worked out from their boxes: it takes a "
        "candidate, compares it with every other undrawn object, and swaps to any that has "
        f"to go first, by the 27-entry table at {R(DEPTH_ORDER)}; a candidate that survives "
        f"the whole list is drawn. The table is Knight Lore's entry for entry, and {kl_ds} "
        f"draws all 27 cases. {R(DRAW_OBJECT)} draws one: {R(0xCFFE)} finds the sprite and "
        "turns it in place to face the way the object does, and an unrolled run of code, "
        f"{R(0xD08F)} for a picture on a byte boundary or {R(0xD0BD)} for one that is not, "
        "lays it into the buffer with the stack pointer reading the sprite a mask and an "
        "image byte at a time.</p>",

        "<h3>6. Copying the rectangles</h3>",
        f"<p>Last, {R(RENDER)} pops each rectangle and {R(0xCF85)} copies just that part of "
        "the buffer to the display. Nothing outside the rectangles changes, so it does not "
        "matter what else lies in the buffer, and nothing flickers, because nothing is "
        "drawn on the display piece by piece.</p>",

        "<h3>7. Pacing</h3>",
        "<p>DRAW_WORK counts the turn's work -- one for each object drawn, one for each "
        f"rectangle wiped -- and {R(OBJECT_DONE)} then waits six units less that, a unit "
        "being 768 turns of a 26 T-state loop, about 20,000 T-states or two-thirds of a "
        "television frame (Knight Lore's and Pentagram's unit is 1280 turns). A quiet turn "
        "is padded out to the length of one with six things to do; a busier one takes "
        "longer. Then the light-years clock is counted and printed "
        f"({R(RUN_CLOCK)}; see <a href=\"Station.html\">the clock</a>). On the first turn "
        f"in a room nothing is wiped: the panel is drawn ({R(0xCB0F)}), the screen coloured "
        f"({R(0xA749)}) and the whole buffer copied once ({R(0xCE85)}).</p>",

        f"<h3>A turn in room ${TRACE_ROOM:02X}</h3>",
        f"<p>{room_ref(TRACE_ROOM, f'Room ${TRACE_ROOM:02X}')} has a pacer "
        f"({graphic_ref(86)}, {R(update_routine(memory, 86))}) walking to and fro on a "
        f"platform: a creature in two records, its lower half graphic {graphic_ref(11)} "
        f"({R(update_routine(memory, 11))}) put under it each turn. The robot stands at "
        f"the back. This is its turn {TRACE_TURNS + 2} in the room -- the first turn "
        "draws everything, and these are ordinary ones -- run by the game's own code in a "
        f"simulator when this page was built, stopped at {R(TURN_OVER)} after the updates, "
        f"at the sort in {R(RENDER)}, at every call of {R(DRAW_OBJECT)} and after the "
        f"copy. {len(moved)} records moved or changed, so there are {len(rects)} rectangles, "
        f"outlined in red; {drawn} objects are drawn to fill them, and DRAW_WORK comes to "
        f"{frame['work']} ({drawn} + {len(rects)}), "
        + ("so the turn does not wait at all." if frame["work"] >= 6 else
           f"so the turn waits {6 - frame['work']} units.")
        + " Two of the rectangles are the robot's, standing still.</p>",
        figure(images["before"], "The screen as the turn begins."),
        figure(images["wiped"], "The buffer after the wipe: each rectangle is cleared. "
               "Round them are the leftovers of earlier turns, which are never copied."),
        figure(images["drawn"], "The buffer after drawing: every listed object drawn whole, "
               "back to front, so parts of them spill outside the rectangles."),
        figure(images["after"], "The screen after the rectangles are copied."),
        "<p>The objects drawn, in the order the depth sort chose:</p>",
        table(["Order", "Record", "Graphic", "Update routine", "Why it is drawn"], rows),
        "<p>The rectangles wiped and copied, in pixels from the top left:</p>",
        table(["x", "y", "Width", "Height"], rect_rows),

        "<h3>Where Alien 8 differs</h3>",
        table(["", "Knight Lore", "Pentagram", "Alien 8"], [
            ["Object records", "40", "54", f"56 ({R(OBJECTS)})"],
            ["The draw list", "48 bytes", "48 bytes, which can overflow",
             f"64 bytes ({R(DRAW_LIST)})"],
            ["The chain of candidates", "8 bytes", "16 bytes", f"16 bytes ({R(CANDIDATE_CHAIN)})"],
            ["A picture left of the screen", "wraps round", "drawn from x 0",
             f"would wrap round, but the walls keep everything clear of it "
             f"({R(CALC_PIXEL_XY)})"],
            ["The stack", "reset for every object", "one stack all turn",
             "reset for every object"],
            ["Boxes that intersect (entry 13)", "destroy a collectable caught in them",
             "nothing", f"destroy a loose valve caught in them ({R(BOXES_INTERSECT)})"],
            ["After a game", "--", "--", f"nothing projected: the scenes place their "
                                         f"pictures by pixel ({R(CALC_PIXEL_XY)})"],
            ["A unit of waiting", "1280 loops", "1280 loops", "768 loops"],
        ]),

        "<h4>The draw list</h4>",
        f"<p>{R(DRAW_LIST)} is 64 bytes: all 56 records and the $FF after them fit with "
        "seven to spare, so unlike Pentagram's 48-byte list, which a player can overflow "
        f"into the sort's own code ({pg('Drawing', 'on its drawing page')}), it cannot "
        "overflow however full a room gets. The list is longest on the first turn in a "
        f"room, when everything is drawn. Run in every one of the {len(rooms)} rooms for "
        f"{SURVEY_TURNS} turns from the first, the robot standing where he appears, the "
        f"longest was {fullest[1]['list']}, in {room_ref(fullest[0])} -- every record in "
        "use there -- and in no room was a later turn's list longer than the first's.</p>",

        "<h4>The chain of candidates</h4>",
        "<p>The sort keeps every object it has made the candidate since the last draw, so "
        "that meeting one again -- three or more boxes each partly behind the next -- is "
        "caught and broken by drawing it at once. Knight Lore's chain holds seven and its "
        "end marker; Alien 8's, like Pentagram's, fifteen. Over the same turns the longest "
        f"chain was {longest[1]['chain']}, in {room_list(chain_rooms)}"
        + (f"; {len(over_kl)} room{'s' if len(over_kl) != 1 else ''} made a chain longer "
           "than Knight Lore's seven, which in Knight Lore's eight bytes would have "
           "written its end marker over the code after it" if over_kl else "")
        + ". Nothing checks the chain's length; fifteen is well clear of what the rooms "
        "need.</p>",

        "<h4>The left edge</h4>",
        f"<p>{R(CALC_PIXEL_XY)} does not stop a pixel x below 0, as Pentagram's does: "
        "U + V - 128 plus a negative nudge that goes below zero wraps round to about 250, "
        "as in Knight Lore. It never needs to. The walls stop a thing whose half-size "
        "plus its distance from the middle would reach them, so in a full-sized room, walls "
        f"at {corner['wall']}, the robot, half-size {corner['half']}, gets no nearer the "
        f"left-hand corner than U and V {cu} -- and his nudge of -16 puts his legs at "
        f"exactly x {corner['x']}. Walked into that corner in the simulator (towards low "
        f"U, then low V, in {room_ref(CORNER_ROOM)}), he stopped at U {corner['low U'][0]}"
        f", then V {cv}, and was drawn from x {corner['x']}. On the first turn of all "
        f"{len(rooms)} rooms no picture's x went below 0.</p>",
        corner_fig,

        "<h4>Entry 13: two boxes in one place</h4>",
        f"<p>When two boxes overlap on all three axes, {R(BOXES_INTERSECT)} turns a loose "
        "valve (graphics 96-99) caught in either into graphic 64, the start of a sparkle "
        "that empties its place in the table of places: the valve is lost for the game. "
        "Knight Lore does the same to its collectables; Pentagram does nothing there. "
        "It is measured on <a href=\"Chambers.html\">the chambers page</a>.</p>",

        "<h3>Confirmed and inferred</h3>",
        "<ul>"
        "<li>Run in the simulator when this page was built: the turn above, stage by "
        "stage; the draw list and the chain in every room; the walk into the corner.</li>"
        "<li>Read from the code: the pipeline's order and the flags; that DRAW_WORK counts "
        "objects drawn and rectangles wiped (checked against the turn traced); the depth "
        "sort's comparisons, which are Pentagram's instruction for instruction and Knight "
        "Lore's table entry for entry.</li>"
        "<li>Inferred: that the list was made 64 bytes because the records grew to 56; "
        "that the walls were meant to keep pictures on the screen.</li>"
        "</ul>",
        "</div>"])


# --------------------------------------------------------------------------
# 2. How the robot moves and turns.
# --------------------------------------------------------------------------

HANDLE_LEFT_RIGHT = 0xC13C
TURNING_LEGS = 0xC1E2
TURN_SOUND_CALL = 0xC217        # CALL $B6D4 in TURNING_LEGS: the call that loses C
TURN_RIGHT_VIEWS = 0xC1D2
TURN_LEFT_VIEWS = 0xC1DA
TURN_RIGHT_ENDS = 0xC22D
TURN_LEFT_ENDS = 0xC235
PLAYER_LEGS = 0xC0BE
MOVE_PLAYER = 0xC296
LEGS_MOVE = 0xC0EA              # PLAYER_LEGS_MOVE: the top out of the tests, then the move
WALK_ROOM = 0xA8                # a narrow room with nothing in it
WALK_FROM = (116, 80)
TURN_AT = 4                     # the turn of the walk on which the turn key is held
FACING_NAMES = ["lower U", "higher U", "higher V", "lower V"]
FACING_GRAPHICS = {0: (17, 0), 1: (21, 0), 2: (17, 0x40), 3: (21, 0x40)}


def face(memory, record: int, facing: int) -> None:
    """Give the legs the standing graphic and mirror bit of a facing, the
    two bits #R$C319 reads it from."""
    graphic, mirror = FACING_GRAPHICS[facing]
    memory[record] = graphic
    memory[record + FLAGS] = memory[record + FLAGS] & 0xBF | mirror


def facing_of(graphic: int, flags: int) -> int:
    return (flags >> 5 & 2) | (graphic >> 2 & 1)


def walk_through_a_turn(snapshot: Path, fixed: bool) -> list[dict]:
    """The robot walking towards higher V in an empty room, with the turn-right
    key held with walk for one turn: the legs' graphic and his place at the
    end of every turn. With `fixed`, the call of the turn's sound in
    TURNING_LEGS is taken out (three NOPs), which leaves C as the controls."""
    game = Game(snapshot)
    game.go(WALK_ROOM, WALK_FROM)
    memory = game.memory
    if fixed:
        memory[TURN_SOUND_CALL:TURN_SOUND_CALL + 3] = [0, 0, 0]
    face(memory, PLAYER, 2)
    game.turns(1)
    rows = []
    for turn in range(TURN_AT + 10):
        ba._lives(memory)
        game.turns(1, ["a", "x"] if turn == TURN_AT else ["a"])
        rows.append({"turn": turn, "graphic": memory[PLAYER],
                     "facing": facing_of(memory[PLAYER], memory[PLAYER + FLAGS]),
                     "u": memory[PLAYER + 1], "v": memory[PLAYER + 2],
                     "count": memory[PLAYER + CONTACT] >> 1 & 3})
    return rows


def turning_round(snapshot: Path) -> tuple[list[dict], list]:
    """The robot standing in the empty room with turn-left held for four
    quarter turns: each turn's graphic, facing and a picture of him."""
    game = Game(snapshot)
    game.go(WALK_ROOM, (128, 128))
    memory = game.memory
    face(memory, PLAYER, 1)
    game.turns(2)
    rows, screens = [], []
    for turn in range(13):
        if turn:
            ba._lives(memory)
            game.turns(1, ["z"])
        rows.append({"turn": turn, "graphic": memory[PLAYER], "top": memory[TOP],
                     "mirror": memory[PLAYER + FLAGS] >> 6 & 1,
                     "count": memory[PLAYER + CONTACT] >> 1 & 3,
                     "rect": [tuple(memory[b + 0x18:b + 0x1C]) for b in (PLAYER, TOP)]})
        screens.append(bytes(memory[0x4000:0x5B00]))
    # The screen shows a turn's drawing at its end; one more for the last.
    return rows, screens


def crop_to(screens, rects_list, pad: int = 6):
    """The screens cut to the box round every (width, height, x, y) rectangle."""
    boxes = []
    for rects in rects_list:
        for width, height, x, y in rects:
            if width and height:
                boxes.append((x, 191 - (y + height), x + 8 * width, 192 - y))
    box = (max(0, min(b[0] for b in boxes) - pad), max(0, min(b[1] for b in boxes) - pad),
           min(256, max(b[2] for b in boxes) + pad), min(192, max(b[3] for b in boxes) + pad))
    return [screen_of(s).crop(box) for s in screens]


def _record(graphic, u, v, z, su, sv, sz, flags=0x10, du=0, dv=0, dz=0,
            bumped=0, contact=0) -> list[int]:
    record = [0] * RECORD
    record[0:14] = [graphic, u, v, z, su, sv, sz, flags, 0, du & 0xFF, dv & 0xFF, dz & 0xFF,
                    bumped, contact]
    return record


LEGS_ = 21
ROBOT = 0x1C                # the legs' flags in play: bits 2 (carried), 3 (doorways), 4
# Each case: what it shows, the mover (record 0), the others (records 4 on).
# The robot's box while he moves is the legs', 23 high. Gravity has already
# taken its share off the mover's dZ, as MOVE_PLAYER and DEC_DZ_AND_UPDATE_UVZ
# do before the cut.
COLLISION_CASES = [
    ("Walking diagonally into a block",
     _record(LEGS_, 100, 100, 64, 7, 7, 23, ROBOT, du=3, dv=3, dz=-2),
     [("block", _record(30, 115, 100, 64, 8, 8, 12, 0x10))]),
    ("Walking into the wall at U 192 (a full-sized room)",
     _record(LEGS_, 182, 128, 64, 7, 7, 23, ROBOT, du=3, dz=-2), []),
    ("Falling onto a block from 3 above it",
     _record(LEGS_, 100, 100, 79, 7, 7, 23, ROBOT, dz=-5),
     [("block", _record(30, 100, 100, 64, 8, 8, 12, 0x10))]),
    ("Walking into a block that can be pushed (graphic 28, flags bit 2)",
     _record(LEGS_, 100, 100, 64, 7, 7, 23, ROBOT, du=3, dz=-2),
     [("block", _record(28, 115, 100, 64, 7, 7, 12, 0x14))]),
    ("Standing on a conveyor (graphic 68, its step 2 in V)",
     _record(LEGS_, 100, 100, 76, 7, 7, 23, ROBOT, dz=-2),
     [("conveyor", _record(68, 100, 100, 64, 8, 8, 12, 0x10, dv=2))]),
    ("Walking along a conveyor, the other way",
     _record(LEGS_, 100, 100, 76, 7, 7, 23, ROBOT, dv=-3, dz=-2),
     [("conveyor", _record(68, 100, 100, 64, 8, 8, 12, 0x10, dv=2))]),
    ("Landing on a collapsing block (graphic 45)",
     _record(LEGS_, 100, 100, 77, 7, 7, 23, ROBOT, dz=-2),
     [("block", _record(45, 100, 100, 64, 8, 8, 12, 0x10))]),
    ("A pushable block (graphic 28) landing on a collapsing block",
     _record(28, 100, 100, 77, 7, 7, 12, 0x14, dz=-2),
     [("block", _record(45, 100, 100, 64, 8, 8, 12, 0x10))]),
    ("A valve (graphic 96) landing on a collapsing block",
     _record(96, 100, 100, 77, 5, 5, 12, 0x14, dz=-2),
     [("block", _record(45, 100, 100, 64, 8, 8, 12, 0x10))]),
    ("A lift (graphic 47) rising 2 into him from below",
     _record(47, 100, 100, 64, 8, 8, 12, 0x14, dz=2),
     [("robot", _record(LEGS_, 100, 100, 77, 7, 7, 23, ROBOT))]),
    ("Walking into something deadly (+$0D = $A0)",
     _record(LEGS_, 100, 100, 64, 7, 7, 23, ROBOT, du=3, dz=-2),
     [("thing", _record(116, 114, 100, 64, 7, 7, 12, 0x10, contact=0xA0))]),
    ("Something deadly walking into him",
     _record(116, 114, 100, 64, 7, 7, 12, 0x10, du=-3, dz=-1, contact=0xA0),
     [("robot", _record(LEGS_, 100, 100, 64, 7, 7, 23, ROBOT))]),
]


def try_collision(memory, mover: list[int], others: list[list[int]],
                  sizes=(64, 64, 64)) -> tuple[list[int], list[list[int]]]:
    """Put the mover in record 0 and the others from record 4 in an otherwise
    empty set of records, and run ADJ_FOR_OUT_OF_BOUNDS on the mover. The
    records afterwards."""
    from skoolkit.simutils import IXh, IXl

    memory = list(memory)
    memory[OBJECTS:OBJECTS + RECORD * RECORD_COUNT] = [0] * (RECORD * RECORD_COUNT)
    memory[OBJECTS:OBJECTS + RECORD] = mover
    for i, other in enumerate(others):
        base = ROOM_OBJECTS + RECORD * i
        memory[base:base + RECORD] = other
    memory[ROOM_HALF], memory[ROOM_HALF + 1], memory[FLOOR] = sizes
    simulator = call(memory, ADJ_FOR_OUT_OF_BOUNDS, {IXh: OBJECTS >> 8, IXl: OBJECTS & 0xFF})
    after = simulator.memory
    return (list(after[OBJECTS:OBJECTS + RECORD]),
            [list(after[ROOM_OBJECTS + RECORD * i:ROOM_OBJECTS + RECORD * (i + 1)])
             for i in range(len(others))])


def _steps(record) -> str:
    return f"({_signed(record[9])}, {_signed(record[10])}, {_signed(record[11])})"


def collision_rows(memory) -> list[list]:
    rows = []
    for what, mover, others in COLLISION_CASES:
        after, others_after = try_collision(memory, mover, [o for _, o in others])
        notes = []
        cut = after[BUMPED] & 7
        if cut:
            notes.append("stopped in " + ", ".join(a for bit, a in ((1, "U"), (2, "V"), (4, "Z"))
                                                   if cut & bit)
                         + (" (+$0C bit " if cut in (1, 2, 4) else " (+$0C bits ")
                         + ", ".join(str(b) for b in range(3) if cut >> b & 1) + ")")
        if after[CONTACT] & 0x40:
            notes.append("the mover is killed (+$0D bit 6)")
        for (name, before), other in zip(others, others_after):
            changes = []
            if other[9:12] != before[9:12]:
                changes.append(f"its step becomes {_steps(other)}")
            if other[CONTACT] & 0x40 and not before[CONTACT] & 0x40:
                changes.append("killed")
            if other[CONTACT] & 0x08 and not before[CONTACT] & 0x08:
                changes.append("+$0D bit 3: landed on")
            if changes:
                notes.append(f"the {name}: " + ", ".join(changes))
        rows.append([what, _steps(mover), _steps(after), "; ".join(notes) or "nothing else"])
    return rows


class Scene:
    """A set piece: the robot stood on (or next to) an object in a real room,
    and the game run a turn at a time, the object and the robot logged and
    the screen kept every turn."""

    def __init__(self, snapshot: Path, room: int, graphics, on_top: bool = True,
                 spot=None, which: int = 0):
        self.room = room
        self.game = Game(snapshot)
        self.game.go(room, spot or ba.CLEAR_SPOT)
        memory = self.game.memory
        found = self.game.find_all(graphics)
        if len(found) <= which:
            raise RuntimeError(f"no graphic {graphics} number {which} in room ${room:02X}")
        self.record = found[which]
        if on_top:
            r = self.record
            for k, part in enumerate((PLAYER, TOP)):
                memory[part + 1], memory[part + 2] = memory[r + 1], memory[r + 2]
                memory[part + 3] = memory[r + 3] + memory[r + 6] + 2 + 12 * k
        self.log = []
        self.screens = []

    def run(self, turns: int, keys=(), when=None) -> list[dict]:
        memory = self.game.memory
        for turn in range(turns + 1):
            r, p = self.record, PLAYER
            self.log.append({"turn": turn, "graphic": memory[r], "u": memory[r + 1],
                             "v": memory[r + 2], "z": memory[r + 3],
                             "pu": memory[p + 1], "pv": memory[p + 2], "pz": memory[p + 3],
                             "pgraphic": memory[p], "lift_top": memory[LIFT_TOP],
                             "killed": memory[p] in range(48, 64),
                             "rects": [tuple(memory[b + 0x18:b + 0x1C]) for b in (r, PLAYER, TOP)
                                       if memory[b] > 1]})
            self.screens.append(bytes(memory[0x4000:0x5B00]))
            if turn < turns:
                ba._lives(memory)
                self.game.turns(1, keys(turn) if callable(keys) else keys)
        return self.log

    def picture(self, pictures: Pictures, name: str, turns, alt: str) -> str:
        """The screens at the given entries of the log, cut to where the object
        and the robot were drawn in them, side by side. Entry t is read after
        t turns in the room: its screen is the drawing the t-th turn ended
        with, and entry 0's is the room before the robot was put in place."""
        images = crop_to([self.screens[t] for t in turns],
                         [self.log[t]["rects"] for t in turns], 10)
        return pictures.strip(name, images, alt)


def _movement_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    R = listing.r
    memory = ba.game_memory(snapshot)
    placed = room_graphics(memory)

    # The turning tables, read from the game.
    turn_rows = []
    for facing in range(4):
        cells = [f"{facing}: {FACING_NAMES[facing]}"]
        for views, ends in ((TURN_LEFT_VIEWS, TURN_LEFT_ENDS), (TURN_RIGHT_VIEWS, TURN_RIGHT_ENDS)):
            view, view_mirror = memory[views + 2 * facing], memory[views + 2 * facing + 1]
            end, end_mirror = memory[ends + 2 * (view & 3)], memory[ends + 2 * (view & 3) + 1]
            new = facing_of(end, end_mirror)
            cells.append(f"{graphic_ref(view)}{' mirrored' if view_mirror else ''}, then "
                         f"{graphic_ref(end)}{' mirrored' if end_mirror else ''}: facing {new}")
        turn_rows.append(cells)
    left_order = [0]
    for _ in range(4):
        facing = left_order[-1]
        view = memory[TURN_LEFT_VIEWS + 2 * facing]
        end = memory[TURN_LEFT_ENDS + 2 * (view & 3)]
        mirror = memory[TURN_LEFT_ENDS + 2 * (view & 3) + 1]
        left_order.append(facing_of(end, mirror))
    _check(left_order == [0, 3, 1, 2, 0], f"a left turn goes {left_order}")

    log("  the robot turning round, and walking through a turn...")
    round_rows, round_screens = turning_round(snapshot)
    _check(all(round_rows[t]["top"] == round_rows[t]["graphic"] + 16 for t in range(13)),
           "the top's graphic was not the legs' + 16")
    views = [r["graphic"] for r in round_rows[1:] if 24 <= r["graphic"] <= 27]
    _check(len(views) == 8 and all(views[k] == views[k + 1] for k in range(0, 8, 2)),
           f"the in-between views were {views}: not two turns each")
    round_images = crop_to(round_screens, [r["rect"] for r in round_rows])
    round_fig = figure(pictures.strip("move_turning.png", round_images,
                                      "The robot turning round"),
                       "Turn left held from a standstill, the screen at the end of each turn "
                       "from the one before the key: graphics "
                       + ", ".join(f"{r['graphic']}{'m' if r['mirror'] else ''}"
                                   for r in round_rows)
                       + " (m: mirrored). A quarter turn every three turns.")

    walk = walk_through_a_turn(snapshot, False)
    fixed = walk_through_a_turn(snapshot, True)

    def still(rows):
        return [r["turn"] for k, r in enumerate(rows)
                if k and (r["u"], r["v"]) == (rows[k - 1]["u"], rows[k - 1]["v"])]

    lost, lost_fixed = still(walk), still(fixed)
    _check(lost == [TURN_AT, TURN_AT + 1, TURN_AT + 2],
           f"walking through a turn he stood still on turns {lost}")
    _check(lost_fixed == [TURN_AT, TURN_AT + 1],
           f"with the sound taken out he stood still on turns {lost_fixed}")
    gap = (walk[-1]["u"] - walk[TURN_AT]["u"], fixed[-1]["u"] - fixed[TURN_AT]["u"])
    _check(gap[1] - gap[0] == 3, f"the fix gained {gap[1] - gap[0]} units, not one step")
    walk_rows = []
    for a, b in zip(walk, fixed):
        walk_rows.append([a["turn"], f"{a['graphic']}", f"{a['u']}, {a['v']}",
                          f"{b['graphic']}", f"{b['u']}, {b['v']}"])

    log("  the collision code on its own...")
    collisions = collision_rows(memory)

    log("  the top as a landing place...")
    game = Game(snapshot)
    game.go(WALK_ROOM, (128, 128))
    m = game.memory
    m[VALVES:VALVES + RECORD] = _record(97, 128, 128, 120, 5, 5, 12, 0x14)
    m[VALVES + ROOM] = WALK_ROOM
    m[VALVES + 0x10], m[VALVES + 0x11] = PLACES & 0xFF, PLACES >> 8
    landed = []
    for _ in range(30):
        ba._lives(m)
        game.turns(1)
        landed.append(m[VALVES + 3])
    rest = landed[-1]
    _check(rest == m[PLAYER + 3] + 23, f"the valve came to rest at {rest}, not on his top")
    top_heights = (m[PLAYER + 6], m[TOP + 6])

    log("  set pieces: the lift, the bobbing blocks, a conveyor, the collapsing and "
        "dropping blocks, a pushable block, a shuttle...")
    figures = []

    def show(scene, name, turns, caption):
        _check(not any(row["killed"] for row in scene.log),
               f"the robot was killed in the {name} scene")
        figures.append(figure(scene.picture(pictures, f"move_{name}.png", turns, caption),
                              caption))

    def zs(rows, key, turns):
        return ", ".join(str(rows[t][key]) for t in turns if t < len(rows))

    def stages(rows):
        out = []
        for row in rows:
            if out and out[-1][0] == row["graphic"]:
                out[-1] = (row["graphic"], out[-1][1] + 1)
            else:
                out.append((row["graphic"], 1))
            if row["graphic"] == 0:
                break
        return out

    # The lift.
    lift_scene = Scene(snapshot, 0x23, (47,))
    other_lifts = [r for r in lift_scene.game.find_all((47,)) if r != lift_scene.record]
    other_zs = [lift_scene.game.memory[r + 3] for r in other_lifts]
    lift = lift_scene.run(110)
    _check(other_lifts and [lift_scene.game.memory[r + 3] for r in other_lifts] == other_zs,
           "another lift in room $23 moved")
    rise = next(r["turn"] for r in lift if r["z"] > lift[0]["z"])
    top_at = max(r["z"] for r in lift)
    peak = next(r["turn"] for r in lift if r["z"] == top_at)
    floor_again = next((r["turn"] for r in lift if r["turn"] > peak and r["z"] == lift[0]["z"]),
                       None)
    _check(floor_again is not None, "the lift did not come back down")
    lift_top = lift[-1]["lift_top"]
    _check(lift_top == lift[0]["z"] + 48, f"LIFT_TOP is {lift_top}, not the lift's Z + 48")
    rises = sorted({lift[t]["z"] - lift[t - 1]["z"] for t in range(rise + 1, peak + 1)})
    falls = sorted({lift[t - 1]["z"] - lift[t]["z"] for t in range(peak + 3, floor_again + 1)})
    _check(all(lift[t]["pz"] == lift[t]["z"] + 12 for t in range(rise + 1, peak + 1)),
           "he did not ride on top of the lift")
    third = (peak - rise) // 3
    lift_turns = [max(1, rise - 1), rise + third, rise + 2 * third, peak, (peak + floor_again) // 2,
                  floor_again]
    show(lift_scene, "lift", lift_turns,
         f"The lift in room $23 with him on it, at turns {', '.join(map(str, lift_turns))}: "
         "rising, at the top, coming down.")

    # The bobbing blocks.
    bob_scene = Scene(snapshot, 0x36, (31,), on_top=False)
    bob = bob_scene.run(48)
    bob_top = bob[-1]["lift_top"]
    bob_low = min(r["z"] for r in bob)
    bob_high = max(r["z"] for r in bob)
    show(bob_scene, "bob", [0, 6, 12, 18, 24, 30, 36],
         "A bobbing block in room $36, every sixth turn, the robot out of the way.")

    # A conveyor.
    conveyor_scene = Scene(snapshot, 0x0D, (68,))
    conveyor = conveyor_scene.run(10)
    gains = sorted({conveyor[t]["pv"] - conveyor[t - 1]["pv"] for t in range(3, 11)})
    _check(gains == [2], f"the conveyor moved him by {gains}")
    show(conveyor_scene, "conveyor", [1, 4, 7, 10],
         "Standing on the conveyor (graphic 68) in room $0D, at turns 1, 4, 7 and 10.")

    # The collapsing block.
    # Two collapsing blocks stand one on the other there: the upper one.
    collapse_scene = Scene(snapshot, 0x12, (45,), which=1)
    collapse = collapse_scene.run(8)
    collapse_stages = stages(collapse)
    _check([g for g, _ in collapse_stages][:4] == [45, 65, 1, 0] or
           [g for g, _ in collapse_stages][:3] == [45, 65, 0],
           f"the block collapsed as {collapse_stages}")
    show(collapse_scene, "collapse", list(range(1, 7)),
         "The collapsing block in room $12, a turn each from the turn he is put on it.")

    # The dropping block.
    drop_scene = Scene(snapshot, 0x82, (44,))
    drop = drop_scene.run(24)
    sinking = [drop[t]["z"] - drop[t - 1]["z"] for t in range(2, 25)]
    _check(set(sinking) <= {-1, 0} and sinking.count(-1) >= 8,
           f"the dropping block moved by {sinking}")
    show(drop_scene, "drop", [1, 8, 16, 24],
         "The dropping block in room $82 with him on it, at turns 1, 8, 16 and 24.")

    # A pushable block, walked into.
    push_room = 0x28
    push_scene = Scene(snapshot, push_room, (28,), on_top=False)
    pm = push_scene.game.memory
    block = push_scene.record
    for part in (PLAYER, TOP):
        pm[part + 1] = pm[block + 1] - 16
        pm[part + 2] = pm[block + 2]
    pm[PLAYER + 3], pm[TOP + 3] = pm[block + 3], pm[block + 3] + 12
    face(pm, PLAYER, 1)
    push = push_scene.run(14, ["a"])
    pushed = push[-1]["u"] - push[0]["u"]
    _check(pushed > 0, "the block did not move when pushed")
    show(push_scene, "push", [1, 5, 10, 14],
         f"Walking into the pushable block (graphic 28) in room ${push_room:02X}, at turns "
         "1, 5, 10 and 14.")

    # A shuttle, ridden.
    shuttle_scene = Scene(snapshot, 0x30, (67,))
    shuttle = shuttle_scene.run(32)
    shuttle_vs = [r["v"] for r in shuttle]
    _check(max(shuttle_vs) - min(shuttle_vs) >= 12, "the shuttle did not shuttle")
    _check(all(abs(r["pv"] - r["v"]) <= 2 for r in shuttle), "he fell off the shuttle")
    show(shuttle_scene, "shuttle", [1, 8, 16, 24, 32],
         "Riding a shuttling block (graphic 67) in room $30, every eighth turn.")

    scene_rows = [
        ["He is put on a lift (room $23)",
         f"it rises from turn {rise}, {'/'.join(map(str, rises))} a turn with him on top, to Z "
         f"{top_at}, one past LIFT_TOP ({lift_top}, its first Z + 48), then comes back down "
         f"{'/'.join(map(str, falls))} a turn with him to the floor, reached on turn "
         f"{floor_again}, and starts again; the room's other lift, left alone, never moves"],
        ["The bobbing blocks (room $36), left alone",
         f"LIFT_TOP {bob_top}, the first one's own Z: each falls a unit a turn to Z "
         f"{bob_low}, where it lands, and rises to {bob_high}; its Z every sixth turn: "
         f"{zs(bob, 'z', range(0, 49, 6))}"],
        ["He is put on a conveyor, graphic 68 (room $0D)",
         f"his V every other turn: {zs(conveyor, 'pv', range(0, 11, 2))} -- two units a turn "
         "in V, the conveyor's own step, which he takes because he has none"],
        ["He is put on a collapsing block (room $12)",
         f"graphics {', '.join(str(g) for g, _ in collapse_stages)} from the turn he lands, a "
         f"turn each, and he falls: his Z {zs(collapse, 'pz', range(0, 7))}"],
        ["He is put on a dropping block (room $82)",
         f"its Z every fourth turn: {zs(drop, 'z', range(0, 25, 4))} -- a unit a turn while he "
         "is on it"],
        [f"He walks into a pushable block (room ${push_room:02X})",
         f"its U: {zs(push, 'u', range(0, 15))}; his: {zs(push, 'pu', range(0, 15))} -- "
         "the turn he walks into it he is stopped and it is given his step, which it moves "
         "by in its own update; then he has room to walk again"],
        ["He is put on a shuttling block, graphic 67 (room $30)",
         f"its V every fourth turn: {zs(shuttle, 'v', range(0, 33, 4))}; his: "
         f"{zs(shuttle, 'pv', range(0, 33, 4))} -- carried, a turn behind"],
    ]

    lift_rooms = set(placed.get(47, []))
    bob_rooms = set(placed.get(31, []))
    _check(lift_rooms and bob_rooms and not lift_rooms & bob_rooms,
           "a room has both lifts and bobbing blocks")

    def where(routine):
        graphics = [g for g in range(ad.HANDLER_COUNT)
                    if listing.entry_of(update_routine(memory, g)) == routine]
        rooms = sorted({r for g in graphics for r in placed.get(g, [])})
        return graphics, rooms

    movers = []
    for routine, what in [
        (0xB31F, "The lift: waits until the robot (or a moving block) lands on it, rises to "
                 "LIFT_TOP -- two a turn by its code, but it hands its step to what it lifts, "
                 "which then rises by that less its own fall -- comes down a unit a turn, and "
                 f"waits again. The bobbing block enters at {R(0xB33F)} and never waits."),
        (0xB267, "The conveyors, one routine for all four directions: set their own step, "
                 "two units a turn, and never move; what lands on them takes the step."),
        (0xB28C, "Collapses when the robot or a moving block lands on it (+$0D bit 3): "
                 "graphics 64 and 65 and gone. Rebuilding the room brings it back."),
        (0xB2B6, "Sinks a unit a turn while the robot or a moving block stands on it."),
        (0xB2FF, "Takes the step of whatever pushes it, moves once by it, falls."),
        (0xB31A, f"As {R(0xB2FF)}, drawn upside down."),
        (0xB224, "Shuttles along U, a unit a turn over 16 units, by the turn counter. "
                 "Knight Lore's."),
        (0xB21C, f"The same along V, through the same code ({R(0xB22A)})."),
    ]:
        graphics, rooms = where(routine)
        movers.append([R(routine), numbers(graphics), what, room_list(rooms)])

    walk_table = table(["Turn", "Graphic", "U, V", "Graphic, the sound taken out",
                        "U, V, the sound taken out"], walk_rows)

    return "\n".join([
        '<div class="kl-list">',
        "<p>The robot is Knight Lore's player in a new body: the same controls, the same "
        "jump and gravity, the same way of leaving a room, and the collision code of "
        f"both elder games ({kl('Collision', 'Knight Lore&#39;s collision page')}; "
        f"{pg('Movement', 'Pentagram&#39;s movement page')}). What is his own is how he "
        "turns -- slowly, through a view in between -- and a slip in the code of that turn "
        "which costs him a step every time. This page is about those, about the robot as "
        "one box, and about the things in the rooms that carry him.</p>",

        "<h3>Two records, one box</h3>",
        f"<p>The robot is records 0 and 1, legs and top. The legs' update routine "
        f"({R(PLAYER_LEGS)}) reads the controls, picks up or puts down, turns, jumps, steps "
        f"and moves; the top's ({R(0xC6E4)}) copies the legs' place, size and flags every "
        "turn, sits 12 above them and takes the legs' graphic plus 16. While the legs "
        "update, they are made 23 high -- the whole robot -- and the top 0 high, and the "
        f"top is taken out of the collision tests for the move ({R(LEGS_MOVE)}); after it "
        f"the heights go back to {top_heights[0]} and {top_heights[1]}. So he moves as one "
        "box, but between moves his top is a box of its own that things can land on. "
        f"Measured: a valve put 56 above him in {room_ref(WALK_ROOM)} fell and came to rest "
        f"at Z {rest}, the top of a robot 23 high standing on the floor at "
        f"{m[PLAYER + 3]}.</p>",

        "<h3>Turning</h3>",
        f"<p>He faces one of four ways, kept in two bits: bit 2 of the legs' graphic and "
        f"the mirror bit of their flags ({R(0xC319)}). Knight Lore and Pentagram turn a "
        f"quarter at once. Alien 8's {R(HANDLE_LEFT_RIGHT)} instead gives the legs one of "
        "four in-between views, graphics 24-27, a count of one in bits 1-2 of +$0D, and "
        f"the turn's direction in bit 0; while they have one, their update routine is "
        f"{R(TURNING_LEGS)}, which counts down for a turn and then gives them the standing "
        "graphic of the new facing. So a quarter turn takes three turns: the one it starts "
        "on, one counting down, and one ending it. The tables, read from the game:</p>",
        table(["Facing", f"Turning left ({R(TURN_LEFT_VIEWS)}, {R(TURN_LEFT_ENDS)})",
               f"Turning right ({R(TURN_RIGHT_VIEWS)}, {R(TURN_RIGHT_ENDS)})"], turn_rows),
        "<p>Facing 0 walks towards lower U, 1 higher U, 2 higher V and 3 lower V "
        f"({R(0xC32F)}). A left turn goes {', '.join(map(str, left_order))} round. The "
        "same view serves both directions between a pair of facings; 27 is 26's drawing, "
        "mirrored. The top turns with the legs, 16 graphics up (40-43).</p>",
        round_fig,

        "<h3>A step lost at every turn</h3>",
        f"<p>{R(TURNING_LEGS)}'s last turn means to let him walk on: it enters "
        f"{R(MOVE_PLAYER)} at MOVE_IF_WALKING, which steps if bit 2 of C -- walk -- is "
        f"set. But just before, it calls the footstep sound at {R(0xB6D4)}, which counts "
        "its waves down in C and leaves it zero, and nothing kept BC around the call "
        f"(the ordinary step, {R(0xC25E)}, does keep it). So the step is never taken: a "
        "robot walking through a turn stands still for three turns, not the two the code "
        "was written for, and gravity ignores a held jump that turn.</p>",
        f"<p>Measured in the simulator: the robot walking towards higher V in "
        f"{room_ref(WALK_ROOM)} (walk held throughout), and turn right held with it for turn "
        f"{TURN_AT} only. Then the same with the call taken out -- three NOPs at "
        f"${TURN_SOUND_CALL:04X}, so C keeps the controls. U and V at the end of each "
        "turn:</p>",
        walk_table,
        f"<p>As played, he stands on turns {', '.join(map(str, lost))}; without the call, on "
        f"{', '.join(map(str, lost_fixed))}, and on turn {TURN_AT + 2} he is already a step "
        f"along. Every quarter turn made while walking costs one step, 3 units. The fix "
        "would be to keep BC around the call, as the ordinary step does; there is no room "
        "for it in place. The bug is on <a href=\"reference/bugs.html\">the bugs page</a>.</p>",

        "<h3>Collision</h3>",
        f"<p>{R(ADJ_FOR_OUT_OF_BOUNDS)} is Knight Lore's and Pentagram's: the step in Z, "
        "then U, then V, each shortened a unit at a time against the floor (64 in every "
        "room), the walls (the room's half-sizes about 128, off while he walks in through "
        "a doorway or stands in one), and all 56 records; a blocked axis sets a bit of +$0C "
        "and the others keep their part, so a move slides along what it meets. Harm passes "
        "both ways through bits 5-7 of +$0D, and an obstacle with bit 2 of its flags takes "
        "the mover's step, to move by it in its own update. The Z test "
        f"({R(0xC535)}) is where the three games differ. A mover with bit 2 in its "
        "flags -- the legs, the pushable and moving blocks, the valves -- gives the "
        "obstacle its own Z step and, on any axis where its own step is zero, takes the "
        "obstacle's: that is how everything that carries him works. And if the mover is one "
        "of graphics 16 to 47 -- the robot, the pushable blocks, the lifts -- the obstacle "
        "gets bit 3 of +$0D, <i>landed on</i>, which the lift and the collapsing and "
        "dropping blocks read. Knight Lore marks everything met and passes no Z step; "
        "Pentagram passes it and marks everything. Something standing on the floor is "
        "stopped in Z every turn: that is what standing is.</p>",
        f"<p>Each row below is {R(ADJ_FOR_OUT_OF_BOUNDS)} run in a simulator when this page "
        "was built, on a mover in record 0 and the others from record 4, every other "
        "record empty, in a room 64 either way from its middle. Steps are (U, V, Z), with "
        "gravity already taken off.</p>",
        table(["Situation", "Step asked", "Step allowed", "And"], collisions),

        "<h3>What carries him</h3>",
        f"<p>The update routines of the room's moving blocks, by the graphics {R(UPDATES)} "
        "gives them and the rooms that place them (read from the room data when this page "
        "was built). The creatures, the mice and the things that drop are on "
        '<a href="Station.html">the page about the dangers</a>.</p>',
        table(["Routine", "Graphics", "What it does", "Where"], movers),
        "<p>A lift and a bobbing block share one top, LIFT_TOP: the room builder clears it "
        "and the first of them updated sets it -- a lift to its own Z plus 48, a bobbing "
        "block to its own Z -- and every other in the room turns back there. No room "
        "has both kinds.</p>",

        "<h3>Set pieces, run in the game</h3>",
        "<p>Each is a real room, entered by the game's own restart in a simulator when this "
        "page was built, with the robot then put on top of the object (or beside it) by "
        "writing his position into both his records, and the game left to run a turn at a "
        "time. Nothing else was touched but his lives, topped up each turn.</p>",
        table(["Situation", "What happened"], scene_rows),
        *figures,

        "<h3>Confirmed and inferred</h3>",
        "<ul>"
        "<li>Run in the simulator when this page was built: the turning round, the walk "
        "through a turn with and without the sound, every row of the collision table, the "
        "valve landing on his top, and every set piece.</li>"
        "<li>Read from the code: that the lost C is the cause (the NOPs show the step comes "
        "back; they are a test, not a patch the game could take in place); the rules of the "
        "Z test and who marks what.</li>"
        "<li>Inferred: that the step at the end of a turn was meant to be taken -- the code "
        "goes to the trouble of entering the move at the walking test.</li>"
        "</ul>",
        "</div>"])


# --------------------------------------------------------------------------
# 3. Rooms and doorways.
# --------------------------------------------------------------------------

ENTER_ROOM = 0xCAA2
BUILD_ROOM = 0xCCA7
PLAYED = 0x5B12
PLACE_NUDGE = 0x5B19
DOORWAY_BACKGROUNDS = (0, 1, 2, 3, 10, 11)
MARKERS = {"lowU": ("U", 0), "highU": ("U", 0xFF), "highV": ("V", 0xFF), "lowV": ("V", 0)}
OPPOSITE = {"lowU": "highU", "highU": "lowU", "lowV": "highV", "highV": "lowV"}
WALL_NAMES = {"lowU": "low U", "highU": "high U", "lowV": "low V", "highV": "high V"}
EXAMPLE_ROOM = 0x0D         # a ring of conveyors, placed with the nudge
DOOR_ROOM = 0x4E            # a start room
DOOR_WALK = 34              # turns with walk held
DOOR_KILL = 36              # the turn his death is started
DOOR_TURNS = 70


def next_room(room: int, wall: str) -> int:
    """The room a doorway in `wall` leads to, as the four exit routines work
    it out: the column changes within the row for U, the row for V."""
    if wall == "lowU":
        return room & 0xF0 | (room - 1) & 0x0F
    if wall == "highU":
        return room & 0xF0 | (room + 1) & 0x0F
    if wall == "highV":
        return (room + 16) & 0xFF
    return (room - 16) & 0xFF


def enter_room(base: list, room: int, u: int = 128, v: int = 128):
    """ENTER_ROOM on its own, the robot's legs in `room` at U, V: the memory
    afterwards."""
    from skoolkit.simutils import IXh, IXl

    memory = list(base)
    memory[PLAYED] = 0
    memory[PLAYER + ROOM], memory[PLAYER + 1], memory[PLAYER + 2] = room, u, v
    return call(memory, ENTER_ROOM, {IXh: PLAYER >> 8, IXl: PLAYER & 0xFF}).memory


def arches(memory) -> list[dict]:
    """The first pillars (graphic 2) among a built room's records: where each
    stands, the wall it is in and the middle of its doorway."""
    out = []
    for index in range(4, RECORD_COUNT):
        base = OBJECTS + RECORD * index
        if memory[base] != 2:
            continue
        u, v, z, flags = memory[base + 1], memory[base + 2], memory[base + 3], memory[base + FLAGS]
        if flags & 0x40:
            wall, middle = ("highV" if v > 128 else "lowV"), (u - 13, v)
        else:
            wall, middle = ("highU" if u > 128 else "lowU"), (u, v + 13)
        out.append({"record": index, "u": u, "v": v, "z": z, "wall": wall, "middle": middle})
    return out


def survey_doorways(base: list, rooms: list[int]) -> dict:
    """Every doorway of every room, followed with the game's own arrival code:
    the marker its exit writes, ENTER_ROOM on the room it leads to, and where
    that puts him -- lined up with which arch, at its height?"""
    built = {room: enter_room(base, room) for room in rooms}
    found = {room: arches(memory) for room, memory in built.items()}
    sizes = {room: (memory[ROOM_HALF], memory[ROOM_HALF + 1]) for room, memory in built.items()}
    results = []
    for room in rooms:
        for arch in found[room]:
            to = next_room(room, arch["wall"])
            axis, marker = MARKERS[arch["wall"]]
            u, v = (marker, arch["middle"][1]) if axis == "U" else (arch["middle"][0], marker)
            back = None
            if to in built:
                after = enter_room(base, to, u, v)
                au, av, az = after[PLAYER + 1], after[PLAYER + 2], after[PLAYER + 3]
                along = 1 if axis == "U" else 0
                for other in found[to]:
                    if other["wall"] == OPPOSITE[arch["wall"]] and az == other["z"] and \
                            (au, av)[along] == other["middle"][along]:
                        back = other
            else:
                au = av = az = None
            results.append({"from": room, "arch": arch, "to": to, "arrive": (au, av, az),
                            "back": back})
    return {"arches": found, "sizes": sizes, "doorways": results}


def _doorways_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    from collections import Counter

    R = listing.r
    memory = ba.game_memory(snapshot)
    records = {record["number"]: record for record in ad.room_records(memory)}
    rooms = sorted(records)

    # The grid.
    grid_rows = []
    for row in range(16):
        cells = [f"{row:X}"]
        for column in range(16):
            number = row << 4 | column
            cells.append(room_ref(number, f"{number:02X}") if number in records else "")
        grid_rows.append(cells)
    grid_table = table([""] + [f"{c:X}" for c in range(16)], grid_rows)
    size_counts = Counter(record["size"] for record in records.values())
    size_rows = []
    for index in range(ad.SIZE_COUNT):
        su, sv, floor = ad.room_size(memory, index)
        size_rows.append([index, su, sv, floor, f"{128 - su} to {128 + su}",
                          f"{128 - sv} to {128 + sv}", size_counts.get(index, 0)])

    # The placement nudge, counted in the level data.
    nudges = [(record["number"], positions[0]) for record in records.values()
              for _, template, _, positions in record["groups"] if template == 0]
    nudge_values = Counter(value for _, value in nudges)
    nudge_rooms = sorted({room for room, _ in nudges})
    pages = sum(1 for record in records.values()
                for _, template, _, _ in record["groups"] if template == 31)

    # The example room, read as the builder reads it and then built.
    log("  the rooms built, and every doorway followed...")
    start = Game(snapshot)
    base = list(start.memory)
    example = records[EXAMPLE_ROOM]
    built = enter_room(base, EXAMPLE_ROOM)
    background_rows = []
    index = 4
    for _, background in example["backgrounds"]:
        pieces = background_pieces(memory, background)
        background_rows.append([background_ref(background),
                                ", ".join(f"{graphic_ref(p[0])} at ({p[1]}, {p[2]}, {p[3]})"
                                          for p in pieces),
                                f"{index}-{index + len(pieces) - 1}" if len(pieces) > 1 else index])
        index += len(pieces)
    group_rows = []
    nudge, page = 0, 0
    floor = ad.room_size(memory, example["size"])[2]
    mismatches = 0
    for _, template, count, positions in example["groups"]:
        if template == 0:
            nudge = positions[0]
            group_rows.append(["0", "", "", f"the nudge becomes ${nudge:02X}", ""])
            continue
        if template == 31:
            page = 32
            group_rows.append(["31", "", "", "the second page of templates", ""])
            continue
        pieces = template_pieces(memory, page + template)
        places = []
        for p in positions:
            u = 72 + 16 * (p & 7) + (8 if nudge & 1 else 0)
            v = 72 + 16 * (p >> 3 & 7) + (8 if nudge & 2 else 0)
            z = floor + 12 * (p >> 6) + (nudge & 0xFC)
            places.append((u, v, z))
            for _ in pieces:
                base_ = OBJECTS + RECORD * index
                if tuple(built[base_ + 1:base_ + 4]) != (u, v, z):
                    mismatches += 1
                index += 1
        group_rows.append([template_ref(page + template, str(page + template)),
                           ", ".join(graphic_ref(p[0]) for p in pieces),
                           R(update_routine(memory, pieces[0][0])),
                           ", ".join(f"({u}, {v}, {z})" for u, v, z in places),
                           f"${nudge:02X}" if nudge else ""])
    _check(mismatches == 0, f"{mismatches} of room ${EXAMPLE_ROOM:02X}'s objects were built "
                            f"somewhere other than the page works out")
    raised = sum(1 for _, template, _, positions in example["groups"]
                 if template == 0 and positions[0])
    _check(raised > 0, f"room ${EXAMPLE_ROOM:02X} has no nudge")
    example_game = Game(snapshot)
    example_game.go(EXAMPLE_ROOM, ba.CLEAR_SPOT)
    example_picture = pictures.stage("doorways_room.png", screen_image(example_game.memory),
                                     f"Room ${EXAMPLE_ROOM:02X}")

    # Every doorway.
    survey = survey_doorways(base, rooms)
    doorways = survey["doorways"]
    two_way = [d for d in doorways if d["back"]]
    _check(len(two_way) == len(doorways),
           f"{len(doorways) - len(two_way)} doorways do not arrive in line with an arch back")
    raised_doors = [d for d in doorways if d["arch"]["z"] > 64]
    _check(raised_doors and all(d["arrive"][2] == 64 for d in raised_doors),
           "a raised doorway leads to another raised one")
    arch_counts = Counter((a["wall"], a["z"]) for found in survey["arches"].values() for a in found)
    arch_rows = []
    for wall in ("lowU", "highU", "lowV", "highV"):
        axis, marker = MARKERS[wall]
        backgrounds = [b for b in DOORWAY_BACKGROUNDS
                       if (lambda p: (("highV" if p[2] > 128 else "lowV") if p[7] & 0x40 else
                                      ("highU" if p[1] > 128 else "lowU")) == wall)
                       (background_pieces(memory, b)[0])]
        heights = sorted({z for (w, z) in arch_counts if w == wall})
        count = sum(n for (w, _), n in arch_counts.items() if w == wall)
        step = {"lowU": "room - 1, in the row", "highU": "room + 1, in the row",
                "highV": "room + 16", "lowV": "room - 16"}[wall]
        arch_rows.append([WALL_NAMES[wall], ", ".join(background_ref(b) for b in backgrounds),
                          ", ".join(map(str, heights)), step, f"{axis} = ${marker:02X}",
                          WALL_NAMES[OPPOSITE[wall]], count])

    # A walk out of a room and a new life.
    log(f"  walking out of room ${DOOR_ROOM:02X}...")
    game = Game(snapshot)
    game.go(DOOR_ROOM, (131, 170))
    m = game.memory
    door = next(a for a in arches(m) if a["wall"] == "highU")
    for part in (PLAYER, TOP):
        m[part + 1], m[part + 2] = 160, door["middle"][1] + 3
    face(m, PLAYER, 1)
    game.turns(1)
    walk, screens = [], {}
    for turn in range(DOOR_TURNS + 1):
        walk.append({"turn": turn, "room": m[PLAYER + ROOM], "u": m[PLAYER + 1],
                     "v": m[PLAYER + 2], "z": m[PLAYER + 3], "flags": m[PLAYER + FLAGS],
                     "bumped": m[PLAYER + BUMPED],
                     "nudge": (_signed(m[PLAYER + 0x0E]), _signed(m[PLAYER + 0x0F])),
                     "graphic": m[PLAYER],
                     "start": (m[START_LEGS + ROOM], m[START_LEGS + 1], m[START_LEGS + 2]),
                     "sparkle": 48 <= m[PLAYER] <= 55, "appearing": 56 <= m[PLAYER] <= 63,
                     "rects": [tuple(m[b + 0x18:b + 0x1C]) for b in (PLAYER, TOP) if m[b] > 1]})
        screens[turn] = bytes(m[0x4000:0x5B00])
        if turn < DOOR_TURNS:
            ba._lives(m)
            if turn == DOOR_KILL:
                ba._kill(m)
            game.turns(1, ["a"] if turn < DOOR_WALK else [])
    out_turn = next(w["turn"] for w in walk if w["room"] != DOOR_ROOM)
    new_room = walk[out_turn]["room"]
    _check(new_room == next_room(DOOR_ROOM, "highU"),
           f"he came out in room ${new_room:02X}, not ${next_room(DOOR_ROOM, 'highU'):02X}")
    _check(not any(w["sparkle"] or w["appearing"] for w in walk[:DOOR_KILL + 1]),
           "something killed him before the page does")
    _check(walk[out_turn]["start"] == (new_room, 0xFF, walk[out_turn]["v"]),
           f"the start record after the exit is {walk[out_turn]['start']}")
    in_doorway = [w["turn"] for w in walk if w["flags"] & 1 and w["room"] == DOOR_ROOM]
    nudged = [w["turn"] for w in walk if w["nudge"] != (0, 0) and w["room"] == DOOR_ROOM]
    _check(bool(in_doorway) and bool(nudged), "he was never in the doorway, or never nudged")
    walk_in = [w["turn"] for w in walk if out_turn <= w["turn"] < DOOR_KILL and w["bumped"] >> 4]
    _check(len(walk_in) == 4, f"he walked in by himself on {len(walk_in)} turns, not 4")
    appear = next((w["turn"] for w in walk if w["turn"] > DOOR_KILL + 1 and w["appearing"]),
                  None)
    restart = next((w["turn"] for w in walk if appear is not None and w["turn"] > appear
                    and 16 <= w["graphic"] <= 23), None)
    _check(restart is not None, "no new life began")
    _check((walk[appear]["u"], walk[appear]["v"], walk[appear]["room"])
           == (walk[out_turn]["u"], walk[out_turn]["v"], new_room),
           "he did not appear in the doorway he came in by")
    walk_in_again = [w["turn"] for w in walk if w["turn"] >= restart and w["bumped"] >> 4]
    _check(len(walk_in_again) == 3 and walk[appear]["bumped"] >> 4 == 4,
           f"after the new life he walked in on turns {walk_in_again}")
    lined = walk[out_turn]["v"]
    walk_rows = []
    shown = sorted(set([0, in_doorway[0] - 1, *in_doorway, *nudged, out_turn, *walk_in,
                        walk_in[-1] + 1, DOOR_WALK, DOOR_KILL + 1, appear, restart,
                        *walk_in_again, walk_in_again[-1] + 1]))
    for t in shown:
        w = walk[t]
        notes = []
        if w["flags"] & 1:
            notes.append("in the doorway: +$07 bit 0")
        if w["nudge"] != (0, 0):
            notes.append(f"nudge {w['nudge'][0]:+d} in U" if w["nudge"][0] else
                         f"nudge {w['nudge'][1]:+d} in V")
        if w["bumped"] >> 4 and w["room"] != DOOR_ROOM and not w["appearing"]:
            notes.append(f"walks in by himself: {w['bumped'] >> 4} in +$0C")
        if w["sparkle"]:
            notes.append(f"the sparkle, graphic {w['graphic']}")
        elif w["appearing"]:
            notes.append(f"appearing, graphic {w['graphic']}")
        if t == appear:
            notes.append("a life later, from the start records")
        walk_rows.append([t, f"${w['room']:02X}", w["u"], w["v"], w["z"],
                          f"${w['start'][0]:02X}, {w['start'][1]}, {w['start'][2]}",
                          "; ".join(notes)])

    def crop_strip(turns, name, caption):
        images = crop_to([screens[t] for t in turns], [walk[t]["rects"] for t in turns], 24)
        return figure(pictures.strip(name, images, caption), caption)

    approach = sorted({1, in_doorway[0], nudged[-1] + 1, out_turn - 1})
    arrive = [out_turn + 1, out_turn + 3, out_turn + 6]
    sparkle = next(w["turn"] for w in walk if w["sparkle"])
    back_again = [sparkle + 1, appear + 4, restart + 1, walk_in_again[-1] + 2]

    return "\n".join([
        '<div class="kl-list">',
        "<p>Alien 8's ship is Knight Lore's castle again: rooms numbered on a 16 by 16 "
        "grid, a row in the high four bits and a column in the low four, so that a doorway "
        "does not say where it leads -- the robot's move does the arithmetic. A room is "
        "built from its record every time he enters it, a doorway is two pillars, and a "
        "life starts where he last came in. This page follows each, and a real walk from "
        "one room into the next, run in the game's own code. The map itself is on "
        '<a href="RoomStructure.html">the room structure page</a>.</p>',

        "<h3>The grid</h3>",
        f"<p>The {len(rooms)} rooms of the room directory ({R(ad.ROOMS)} on), by row (the "
        "number's high digit) and column (its low one):</p>",
        grid_table,
        f"<p>Three sizes, from {R(ad.SIZES)} by bits 6-7 of a room's third byte; the floor "
        "is 64 in all of them, and there is no ceiling:</p>",
        table(["Size", "Half-size in U", "Half-size in V", "Floor", "U runs", "V runs",
               "Rooms"], size_rows),

        "<h3>Building a room</h3>",
        f"<p>{R(ENTER_ROOM)} puts the valves of the room being left back in their places "
        f"(see <a href=\"Chambers.html\">the chambers page</a>) and calls {R(BUILD_ROOM)}, "
        "which steps through the directory by each record's byte count until the number "
        "matches his room, takes the room's colour and size, and fills the records from "
        "record 4 up: first the backgrounds, a byte each up to an $FF -- a background "
        f"({R(ad.BACKGROUND_TABLE)}) is a list of eight-byte pieces, graphic, U, V, Z, the "
        "half-sizes, the height and the flags, each copied whole into a record -- and then "
        "the objects, in groups: a header (bits 3-7 the template, bits 0-2 how many less "
        "one) and a position byte for each copy. An object template "
        f"({R(ad.OBJECT_TABLE)}) is a list of five-byte pieces, graphic, half-sizes, height "
        "and flags, all put at the object's place: U = 72 + 16 times bits 0-2, V = 72 + 16 "
        "times bits 3-5, Z = the floor + 12 times bits 6-7. The record's byte count, not a "
        "marker, ends it. Then the valves lying in the room come into records 2 and 3, and "
        f"{R(0xCC01)} puts him in the doorway he came in by. It is Pentagram's builder, "
        "filling upwards where Pentagram's fills down.</p>",
        f"<p>Two template numbers are not templates. Template 31 moves on to a second page "
        f"of the table, for templates 32 to 39 ({pages} rooms use it). And template 0 sets "
        f"the <i>placement nudge</i> (PLACE_NUDGE) from the byte after it: bit 0 adds 8 to "
        "U, bit 1 adds 8 to V, and the rest is added to Z, for every object after it in "
        "the record. Pentagram's builder has the same store in bytes nothing reaches; in "
        f"Alien 8 it is live. Counted in the level data: {len(nudges)} nudges in "
        f"{len(nudge_rooms)} rooms, "
        + ", ".join(f"{n} of ${v:02X}" for v, n in sorted(nudge_values.items(), reverse=True))
        + " -- $30 lifting the objects after it 48, four levels, onto what the first groups "
        "built; a nudge of 0 puts them back on the floor. Nothing uses the half-cell "
        "steps.</p>",
        f"<p>{room_ref(EXAMPLE_ROOM, f'Room ${EXAMPLE_ROOM:02X}')}, read the way the builder "
        "reads it when this page was built, and checked against the records "
        f"{R(ENTER_ROOM)} made from it (run on its own in the simulator): every object "
        "stood where the table below puts it. Its backgrounds:</p>",
        table(["Background", "Its pieces (U, V, Z)", "Records"], background_rows),
        "<p>Its objects, in record order:</p>",
        table(["Template", "Graphics", "Update routine", "At (U, V, Z)", "Nudge"], group_rows),
        figure(example_picture, f"Room ${EXAMPLE_ROOM:02X} as the game draws it, in a "
               "simulator when this page was built."),

        "<h3>The doorway</h3>",
        "<p>Every doorway is one of six backgrounds, two pillars each: a first pillar, "
        "graphic 2, and a second, graphic 3, 26 units along the wall. The second only sets "
        f"its drawing nudge ({R(0xBFD8)}). The first ({R(0xBFEA)}) does the work, every "
        "turn: it works out the middle of the doorway, 13 from itself along the wall, and "
        f"keeps it in its own +$09 to +$0B, the step bytes a pillar never uses; "
        f"{R(0xC082)} then asks whether the robot's legs -- record 0 only -- are within 15 "
        "of that point across the doorway and 6 along it, and 4 in Z "
        f"({R(0xC099)}). If they are, bit 0 of his flags is set: the walls are off for his "
        f"next move, and the move's own exit check ({R(0xC36D)}) looks to see whether he "
        "has gone through. Near the doorway the pillar also puts a nudge of one unit "
        f"towards the middle line in his +$0E or +$0F ({R(0xC050)}, {R(0xC069)}), which "
        f"the walk ({R(0xC2F6)}) adds to his next step, so he slides into line as he goes "
        "through. Unlike Knight Lore's and Pentagram's, the nudge is only given while he "
        "faces through the doorway.</p>",
        f"<p>The doorways in the rooms as built (the first pillars of all "
        f"{sum(len(a) for a in survey['arches'].values())}, read from the records after "
        "the game's own builder had run for every room):</p>",
        table(["Wall", "Backgrounds", "Pillar Z", "Leads to", "Leaving writes",
               "He arrives by", "Doorways"], arch_rows),
        "<p>Two of the backgrounds, 10 and 11, are raised doorways, their floor at Z 112, "
        "reached by what the room builds under them. Their walls, high U and low V, are the "
        "only ones with raised doorways, so the doorway each leads to, in the opposite wall "
        "of the next room, is on the floor: he goes out 48 up and comes in at floor "
        "level.</p>",

        "<h3>Going through</h3>",
        f"<p>{R(0xC36D)} runs inside the robot's move, after the move has been cut short "
        "and before it is made: not while he walks in, only with bit 0 set, which it "
        f"clears. By the way he faces it jumps through {R(0xC38F)} to one of four routines "
        f"({R(0xC397)}, {R(0xC3F0)}, {R(0xC40B)}, {R(0xC426)}), each asking whether this "
        "turn's move takes him wholly past the wall he faces. If it does, the coordinate he "
        "left by becomes a marker, 0 or $FF -- not a position but a note of the wall -- and "
        "his room goes down or up by 1 within the row (the column wraps round, the row "
        "stays) or by 16. The top four bits of +$0C get 4: four turns of walking on by "
        "himself, the walls and the controls off (Knight Lore's is three). Both his records "
        f"are copied to the start records ({R(START_LEGS)}) with their graphics kept at "
        "+$10 and replaced by 56, the appearing robot's first; two return addresses are "
        f"dropped from the stack, and the game jumps back to {R(0xA68B)} to build the "
        "room. There, "
        f"{R(0xCC01)} sees the marker and puts him in the doorway of the opposite wall, his "
        f"inner edge 2 inside the wall's line, and {R(0xCC6D)} gives him the arch's Z, "
        "finding it among records 4, 6, 8 and 10 by its U + V, $52, $38, $C8 or $AE: the "
        "code takes a room's doorways to be its first four backgrounds, which in every room "
        "they are. The code is Knight Lore's, instruction for instruction, and so are the "
        f"four constants but one ({kl('RoomStructure', 'Knight Lore&#39;s rooms')}); "
        f"Pentagram decides the exit in the pillar instead "
        f"({pg('Doorways', 'its doorways page')}).</p>",

        f"<h3>A walk out of room ${DOOR_ROOM:02X}, and a life lost</h3>",
        f"<p>In a simulator when this page was built: a game started, "
        f"{room_ref(DOOR_ROOM)} (one of the four start rooms) entered by the game's own "
        f"restart, and the robot then put three units off the middle line of its doorway at "
        f"high U, facing it -- his legs given graphic 21 without the mirror bit, facing 1. Walk "
        f"(A) was held for {DOOR_WALK} turns, and on turn {DOOR_KILL} his death was started "
        "the way the game starts it (both records made graphic 48, the sparkle, and taken "
        "out of the collision tests). Nothing else was touched but his lives, topped up each "
        "turn. The start records begin with the room and place the page's restart gave "
        "them:</p>",
        table(["Turn", "Room", "U", "V", "Z", "Start record: room, U, V", "What is going on"],
              walk_rows),
        f"<p>He is in the doorway from turn {in_doorway[0]}, and the pillar nudges him onto "
        f"its middle line, V {lined}, a unit a turn. On turn {out_turn} he is in "
        f"{room_ref(new_room)} (${DOOR_ROOM:02X} + 1, a chamber), at U "
        f"{walk[out_turn]['u']}: his inner "
        "edge two units inside that room's wall. The start records now hold him as he "
        "left: room $%02X, U $FF -- the marker, not a position -- and the V of the middle "
        "line. He walks in for four turns by himself before the controls come back. His "
        "death runs the sparkle; when it is over both his records are empty, the main loop "
        f"starts a life ({R(0xCA07)}) from the start records, and the same arrival code "
        f"sees the same marker: on turn {appear} he appears (graphics 56 to 63, "
        f"{R(0xBC70)}) in the doorway he came in by, at U {walk[appear]['u']}, V "
        f"{walk[appear]['v']}. And since the start records were copied as he came in, "
        "they hold the walk in too: when he has appeared, on turn "
        f"{restart}, he walks in by himself again for the four turns.</p>" % new_room,
        crop_strip(approach, "doorways_out.png",
                   f"Room ${DOOR_ROOM:02X}, turns {', '.join(map(str, approach))}: walking to "
                   "the doorway, and sliding onto its middle line."),
        crop_strip(arrive, "doorways_in.png",
                   f"Room ${new_room:02X}, turns {', '.join(map(str, arrive))}: coming in, "
                   "and walking on by himself."),
        crop_strip(back_again, "doorways_restart.png",
                   f"Room ${new_room:02X}, turns {', '.join(map(str, back_again))}: the "
                   "sparkle, the robot appearing in the doorway, and walking in again."),

        "<h3>Every doorway, followed</h3>",
        f"<p>For each of the {len(doorways)} doorways, the room it leads to was worked out "
        "by the exit routines' arithmetic, the marker its exit writes put in the robot's "
        f"record with that room, and {R(ENTER_ROOM)} run on its own; then where it put him "
        f"was compared with the arches of the room he arrived in. All {len(two_way)} put "
        "him on the middle line of a doorway in the opposite wall, at its height -- a "
        "doorway that leads straight back. So every doorway in the game goes both ways and "
        "leads to a room that exists, and the arrival code's assumption, that the doorways "
        "are a room's first four backgrounds, always holds.</p>",

        "<h3>Confirmed and inferred</h3>",
        "<ul>"
        "<li>Run in the simulator when this page was built: the example room's build; the "
        "walk, the exit, the walk in and the new life; every room's doorways, and every "
        "doorway's arrival.</li>"
        "<li>Read from the code: the exit tests and markers (the walk shows the high-U "
        "one; the other three are the same code about the other walls); the builder's "
        "reading of a record and the nudge; the comparison with Knight Lore.</li>"
        "<li>Counted in the level data: the nudges and the second-page headers.</li>"
        "</ul>",
        "</div>"])


# --------------------------------------------------------------------------
# 4. Valves, sockets and the cryogenic chambers.
# --------------------------------------------------------------------------

INIT_SPECIAL_OBJECTS = 0xAF3F
FIND_SPECIAL_OBJS_HERE = 0xAE99
UPDATE_SPECIAL_OBJS = 0xAF05
LOOSE_VALVE = 0xAF79
SEATED_VALVE = 0xAE5D
SOCKET = 0xAE68
SOCKET_SPARKLE = 0xAE33
WANTED_VALVE = 0xAE17
SUMMARISE_CHAMBERS = 0xAC6B
TAKE_OR_LEAVE = 0xBD6B
INK_PASS = 0xB01B           # in LOOSE_VALVE: one pass of the inks done, the sparkle sound next
ARRIVAL_SHOWN = 0xB8C2      # in ARRIVAL_SCREEN: the text shown, the tune next
SUMMARY_SHOWN = 0xB7AE      # in GAME_ENDED: the summary shown
CARRIED_LAST = 0x5B84
NO_HEADROOM = 0x5B33
VALVE_KINDS = ["red", "magenta", "cyan", "white"]   # CARRIED_COLOURS, by the low bits
CARRY_FROM = 0xA8           # an empty room to pick a valve up in
CARRY_TO = 0x28             # a chamber for kind 0, clear to stand on its socket
SPARKLE_ROOM = 0x28
REBUILD_ROOM = 0x12         # two collapsing blocks, one on the other


def deal(memory, seed: int, random: int) -> list[int]:
    """INIT_SPECIAL_OBJECTS run on its own with SEED and RANDOM given: the
    graphic it gives each of the 36 places."""
    memory = list(memory)
    memory[SEED], memory[RANDOM] = seed, random
    after = call(memory, INIT_SPECIAL_OBJECTS).memory
    return [after[PLACES + PLACE_SIZE * k] for k in range(ad.PLACE_COUNT)]


def crew_by_room(memory) -> dict[int, int]:
    """The chambers as SUMMARISE_CHAMBERS finds them -- a room whose first
    object groups are templates 21 or 22 -- and the crew in each: the counts
    of those groups in a row."""
    out = {}
    for record in ad.room_records(memory):
        groups = [(t, c, p) for _, t, c, p in record["groups"]]
        crew = 0
        for template, count, positions in groups:
            if template in (21, 22):
                crew += len(positions)
            else:
                break
        if crew:
            out[record["number"]] = crew
    return out


def sockets_by_room(memory) -> dict[int, int]:
    """Each chamber room and the kind of valve its socket takes: the room
    data's object templates 24-27, graphics 112-115."""
    out = {}
    for record in ad.room_records(memory):
        for template, _ in room_templates(record):
            if 24 <= template <= 27:
                out[record["number"]] = template - 24
    return out


def panel_carried(memory):
    """The three boxes of carried things on the panel, from the screen."""
    return screen_image(memory).crop((8, 168, 80, 192))


def summary_counts(memory) -> tuple[int, int, int]:
    """SUMMARY_ACTIVE, SUMMARY_IDLE and SUMMARY_LOST as numbers: BCD, the
    last a word with its high byte first."""
    return (_bcd(memory[SUMMARY_ACTIVE]), _bcd(memory[SUMMARY_IDLE]),
            100 * _bcd(memory[SUMMARY_LOST]) + _bcd(memory[SUMMARY_LOST + 1]))


def valve_record(memory, place: int) -> int | None:
    """Which of records 2 and 3 holds the thing from a place (its +$10 and
    +$11 point at the place)."""
    address = PLACES + PLACE_SIZE * place
    for record in (VALVES, VALVES + RECORD):
        if memory[record] and _word(memory, record + 0x10) == address:
            return record
    return None


def seat_valve(game: Game, place: int, room: int, kind: int, last: bool = False) -> int:
    """A valve of the chamber's kind brought to it the way the robot would
    bring it -- lying on the socket's top, a unit off its middle each way --
    by writing a place to hold it in the room and the robot sent there by the
    game's own restart; then the valve moved onto the socket, and the game run
    until the chamber counts it. The turns that took. The last chamber ends
    the game inside the valve's update: that one is run to the arrival
    screen instead."""
    memory = game.memory
    ba._put(place, 96 + kind, room, 128, 128, 64)(memory)
    ba._lives(memory)
    for record in (START_LEGS, START_TOP):
        memory[record + ROOM] = room
        memory[record + 1], memory[record + 2] = ba.CLEAR_SPOT
    ba._kill(memory)
    for _ in range(400):
        game.turns(1)
        if memory[PLAYER + ROOM] == room and valve_record(memory, place):
            break
    else:
        raise RuntimeError(f"room ${room:02X} never came with the valve in it")
    record = valve_record(memory, place)
    socket = game.find(range(112, 116))
    memory[record + 1] = memory[socket + 1] + 1
    memory[record + 2] = memory[socket + 2] + 1
    memory[record + 3] = memory[socket + 3] + memory[socket + 6]
    memory[record + 9:record + 12] = [0, 0, 0]
    before = memory[CHAMBERS]
    if last:
        game.run_to(ARRIVAL_SHOWN, 60.0)
        return 0
    for turn in range(1, 40):
        ba._lives(memory)
        game.run_to(MAIN_LOOP, 30.0)
        if memory[CHAMBERS] != before:
            return turn
    raise RuntimeError(f"the valve never seated itself in room ${room:02X}")


class QuestRun:
    """The quest played in the simulator: a valve of each chamber's kind put
    high in the chamber and held over its socket (build_alien8._chamber), all
    24 in turn, the chamber pictured as each is activated, the summary counted
    along the way, and the ending kept."""

    def __init__(self, snapshot: Path, log):
        self.game = Game(snapshot)
        memory = self.game.memory
        sockets = sockets_by_room(ba.game_memory(snapshot))
        self.rooms = sorted(sockets)
        self.shots = {}
        self.counts = {}
        self.turns = []
        for number, room in enumerate(self.rooms, 1):
            if number == len(self.rooms):
                break
            self.turns.append(seat_valve(self.game, number - 1, room, sockets[room]))
            _check(memory[CHAMBERS] == int(str(number), 16),
                   f"chamber ${room:02X} made the count {memory[CHAMBERS]:02X}")
            self.game.turns(3)
            self.shots[room] = screen_image(memory)
            if number in (4, 12):
                probe = list(memory)
                probe = call(probe, UPDATE_SPECIAL_OBJS).memory
                probe = call(probe, SUMMARISE_CHAMBERS).memory
                self.counts[number] = summary_counts(probe)
        log("  the twenty-fourth chamber, and the ending...")
        room = self.rooms[-1]
        seat_valve(self.game, len(self.rooms) - 1, room, sockets[room], last=True)
        _check(memory[WON] == 1 and memory[CHAMBERS] == 0x24,
               "the twenty-fourth chamber did not win the game")
        self.last_room = room
        self.arrival = screen_image(memory)
        self.game.run_to(SUMMARY_SHOWN, 60.0)
        self.summary = screen_image(memory)
        self.final = summary_counts(memory)
        self.game.play([ba.Until("the scene after the ending", ba._in_game_over, 90.0)])
        self.scene_screens = []
        self.scene_log = []
        for turn in range(320):
            try:
                self.game.run_to(MAIN_LOOP, 10.0)
            except RuntimeError:
                # The scene's end: a tune, and then the menu, which waits for a key.
                break
            if memory[GAME_OVER] == 0:
                break
            robot = next((OBJECTS + RECORD * k for k in range(RECORD_COUNT)
                          if memory[OBJECTS + RECORD * k] == 92), None)
            if robot is not None:
                self.scene_log.append((turn, memory[robot + 0x1B], memory[robot + 0x11]))
                self.scene_screens.append(bytes(memory[0x4000:0x5B00]))

    def scene_frames(self) -> list:
        """The oiling scene: waiting, going down, in the oil, coming up white."""
        log = self.scene_log
        down = next(k for k, (_, y, count) in enumerate(log) if 64 <= count < 128 and y < 100)
        bottom = next(k for k, (_, y, count) in enumerate(log) if y < 40)
        up = next(k for k, (_, y, count) in enumerate(log) if count >= 128 and y > 80)
        picks = [8, down, bottom + 20, up]
        return [screen_of(self.scene_screens[k]) for k in picks]


def _chambers_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    from collections import Counter

    R = listing.r
    memory = ba.game_memory(snapshot)
    sockets = sockets_by_room(memory)
    crew = crew_by_room(memory)
    _check(sorted(crew) == sorted(sockets), "the crew's rooms are not the socket rooms")
    per_kind = Counter(sockets.values())
    _check(len(sockets) == 24 and all(per_kind[k] == 6 for k in range(4)),
           f"the sockets are {per_kind}")
    total_crew = sum(crew.values())

    # The places, and the deal.
    places = []
    for k in range(ad.PLACE_COUNT):
        base = PLACES + PLACE_SIZE * k
        places.append({"u": memory[base + 1], "v": memory[base + 2], "z": memory[base + 3],
                       "room": memory[base + 4]})
    place_rooms = [p["room"] for p in places]
    _check(len(set(place_rooms)) == len(place_rooms), "two places start in one room")
    in_chambers = [p["room"] for p in places if p["room"] in sockets]

    log("  dealing the places...")
    started = Game(snapshot)
    dealt = [started.memory[PLACES + PLACE_SIZE * k] for k in range(ad.PLACE_COUNT)]
    lives_counts, fewest = Counter(), 99
    for random in range(16):
        for seed in range(4):
            graphics = deal(started.memory, seed, random)
            lives = graphics.count(12)
            lives_counts[(random, lives)] += 1
            kinds = sorted(Counter(g for g in graphics if g != 12).values())
            _check(kinds == [9 - lives, 9, 9, 9],
                   f"the deal for {seed}, {random} gave the kinds {kinds}")
            fewest = min(fewest, kinds[0])
    three = sorted(r for (r, n) in lives_counts if n == 3)
    _check(set(n for (_, n) in lives_counts) == {2, 3}, "a deal gave other than 2 or 3 lives")
    place_rows = []
    for k, p in enumerate(places):
        g = dealt[k]
        what = "an extra life" if g == 12 else f"valve {g} ({VALVE_KINDS[g & 3]})"
        chamber = (f"a chamber for {VALVE_KINDS[sockets[p['room']]]}" if p["room"] in sockets
                   else "")
        place_rows.append([k, room_ref(p["room"]), p["u"], p["v"], p["z"],
                           graphic_ref(g, what), chamber])
    socket_rows = []
    for kind in range(4):
        rooms = sorted(r for r, k in sockets.items() if k == kind)
        socket_rows.append([graphic_ref(96 + kind), VALVE_KINDS[kind], graphic_ref(112 + kind),
                            room_list(rooms), sum(crew[r] for r in rooms)])

    # Carrying a valve into a chamber and putting it down on the socket.
    log("  a valve carried to a socket and put down...")
    game = Game(snapshot)
    m = game.memory
    ba._put(0, 96, CARRY_FROM, 128, 142, 64)(m)
    game.go(CARRY_FROM, (128, 128))
    carry_rows, panels = [], []
    presses = 0
    while not m[CARRIED_LAST] and presses < 5:
        ba._lives(m)
        game.turns(1, ["1"])
        game.turns(2)
        presses += 1
        slots = f"{m[CARRIED_NEW + 4]}, {m[CARRIED_NEW + 8]}, {m[CARRIED_LAST]}"
        carry_rows.append([presses, slots,
                           m[VALVES], m[PLACES]])
        panels.append(panel_carried(m))
    _check(presses == 3 and m[PLACES] == 0, f"the valve took {presses} presses to reach the "
                                            f"last slot")
    game.go(CARRY_TO, ba.CLEAR_SPOT)
    _check(m[CARRIED_LAST] == 96, "the carried valve did not survive the lost life")
    socket = game.find((112,))
    su, sv, sz = m[socket + 1], m[socket + 2], m[socket + 3]
    for part, dz in ((PLAYER, 0), (TOP, 12)):
        m[part + 1], m[part + 2], m[part + 3] = su - 1, sv - 2, sz + 12 + dz
    game.turns(3)
    before_put = screen_image(m)
    ink_before = m[ROOM_INK]
    ba._lives(m)
    game.turns(1, ["1"])
    put = (m[VALVES], m[VALVES + 1], m[VALVES + 2], m[VALVES + 3], m[PLAYER + 3])
    _check(put[0] == 96 and put[1:4] == (su, sv - 1, sz + 12) and put[4] == sz + 24,
           f"the valve went down as {put}")
    # The activation's passes over the inks, caught as they happen.
    inks = []
    for _ in range(8):
        game.run_to(INK_PASS, 10.0)
        inks.append(screen_image(m).crop((32, 16, 224, 160)))
    game.turns(2)
    seated = (m[VALVES], m[VALVES + 1], m[VALVES + 2], m[VALVES + 3])
    _check(seated == (100, su, sv, sz + 12) and m[CHAMBERS] == 1 and m[ROOM_INK] == 7,
           f"the valve did not seat itself: {seated}, chambers {m[CHAMBERS]}")
    after_put = screen_image(m)
    carry_fig = figure(pictures.strip("chambers_panel.png", panels,
                                      "The carried things on the panel"),
                       "The panel's three boxes after each press: the valve picked up, "
                       "passed along, and in the last box.")
    socket_fig = figure(pictures.strip("chambers_socket.png",
                                       [before_put.crop((88, 40, 232, 176)),
                                        after_put.crop((88, 40, 232, 176))],
                                       "Before and after"),
                        f"In {room_ref(CARRY_TO)}: standing on the socket with the valve, "
                        "and a few turns after it went down -- seated, and the room white.")
    ink_fig = figure(pictures.strip("chambers_inks.png", inks[:6], "The inks cycling"),
                     "The first six passes over the attributes as the chamber is activated, "
                     "each caught in the simulator at the sparkle's sound between passes: the "
                     f"room's {ad.INKS[ink_before]} stepped on to "
                     + ", ".join(ad.INKS[(ink_before + k) & 7]
                                 + (" (the room vanishes into the paper)"
                                    if (ink_before + k) & 7 == 0 else "")
                                 for k in range(1, 7)) + ".")

    # The sparkle over a socket.
    log("  the sparkle over a socket...")
    sparkle_game = Game(snapshot)
    sparkle_game.go(SPARKLE_ROOM, ba.CLEAR_SPOT)
    sm = sparkle_game.memory
    sock = sparkle_game.find((112,))
    sparkle = sock + RECORD
    frames, sparkle_graphics = [], []
    for _ in range(8):
        sparkle_game.turns(1)
        sparkle_graphics.append(sm[sparkle])
        x, y = sm[sparkle + 0x1A], sm[sparkle + 0x1B]
        frames.append(screen_image(sm).crop((max(0, x - 8), max(0, 191 - y - 40),
                                             min(256, x + 40), min(192, 191 - y + 24))))
    _check(set(sparkle_graphics) >= {108, 104}, f"the sparkle went {sparkle_graphics}")
    sparkle_fig = figure(pictures.strip("chambers_sparkle.png", frames,
                                        "The sparkle over a socket"),
                         f"Over the socket in {room_ref(SPARKLE_ROOM)}, eight turns: graphics "
                         + ", ".join(map(str, sparkle_graphics)) + ".")

    # A valve lost where a collapsing block is rebuilt.
    log("  a valve lost in a rebuilt block...")
    lost_game = Game(snapshot)
    lm = lost_game.memory
    lost_game.go(REBUILD_ROOM, ba.CLEAR_SPOT)
    block = lost_game.find_all((45,))[-1]
    bu, bv, bz = lm[block + 1], lm[block + 2], lm[block + 3]
    ba._put(0, 97, REBUILD_ROOM, bu, bv, bz)(lm)
    ba._lives(lm)
    for record in (START_LEGS, START_TOP):
        lm[record + ROOM] = REBUILD_ROOM
        lm[record + 1], lm[record + 2] = ba.CLEAR_SPOT
    ba._kill(lm)
    for _ in range(400):
        lost_game.run_to(LISTED)
        if lm[PLAYER + ROOM] == REBUILD_ROOM and lm[NEW_ROOM]:
            break
    lost_rows = [["built", lm[VALVES], lm[PLACES]]]
    for _ in range(60):
        lost_game.run_to(BOXES_INTERSECT + 0x27, 5.0)     # its common exit
        if lm[VALVES] == 64:
            break
    lost_rows.append(["the first depth sort", lm[VALVES], lm[PLACES]])
    for turn in range(3):
        lost_game.turns(1)
        lost_rows.append([f"turn {turn + 1} after", lm[VALVES], lm[PLACES]])
    _check([row[1] for row in lost_rows][:2] == [97, 64] and lost_rows[-1][1:] == [0, 0],
           f"the valve in the block went {lost_rows}")

    # The quest.
    log("  the quest: all 24 chambers...")
    quest = QuestRun(snapshot, log)
    active4, idle4, lost4 = quest.counts[4]
    first4 = quest.rooms[:4]
    _check((active4, idle4, lost4) == (4, 20, total_crew - sum(crew[r] for r in first4)),
           f"after four chambers the summary counted {quest.counts[4]}")
    active12, idle12, lost12 = quest.counts[12]
    lost_after12 = total_crew - sum(crew[r] for r in quest.rooms[:12])
    _check((active12, idle12, lost12) == (12, 12, lost_after12),
           f"after twelve chambers the summary counted {quest.counts[12]}")
    _check(quest.final == (24, 0, 0), f"the summary after the ending counted {quest.final}")
    lowest = min(y for _, y, _ in quest.scene_log)
    scene_frames = quest.scene_frames()
    thumbs = [quest.shots[r].crop((0, 0, 256, 160)).resize((128, 80)) for r in quest.rooms[:-1]]
    sheet = grid(thumbs, 6)
    quest_fig = figure(pictures.piece("chambers_quest.png", sheet, "The chambers activated", 1),
                       "Each chamber a few turns after its valve seated itself, in the order the "
                       "quest went (the room directory's), the twenty-fourth ending the game: "
                       + ", ".join(f"${r:02X}" for r in quest.rooms) + ".")
    ending_fig = figure(pictures.piece("chambers_ending.png",
                                       grid([quest.arrival, quest.summary] + scene_frames, 3),
                                       "The ending", 1),
                        "After the twenty-fourth: the arrival screen, the summary, and the "
                        "scene that follows -- the robot waiting, going down into the oil, in "
                        "it, and coming up bright.")

    kinds_rows = []
    for kind in range(4):
        count = Counter(g for g in dealt if g == 96 + kind)[96 + kind]
        kinds_rows.append([graphic_ref(96 + kind), VALVE_KINDS[kind], count, per_kind[kind]])

    return "\n".join([
        '<div class="kl-list">',
        "<p>The robot's job is to bring the frozen crew's chambers back to life: 24 "
        "cryogenic chambers, each with a socket that takes one kind of valve, and 36 places "
        "about the ship where valves lie. A valve seated on a socket of its kind activates "
        "its chamber; the twenty-fourth ends the game. The places are Knight Lore's "
        f"special objects under another name ({kl('Charms', 'Knight Lore&#39;s charms')}); "
        "the sockets, the chambers, the valves' own behaviour and the count at the end are "
        "Alien 8's own.</p>",

        "<h3>The places</h3>",
        f"<p>{R(PLACES)} is 36 records of nine bytes: +0 what lies there, a graphic, dealt "
        "at every new game; +1 to +4 where it starts, U, V, Z and the room, from the tape; "
        "+5 to +8 where it is now. The 36 places start in 36 different rooms"
        + (f", {len(in_chambers)} of them chambers" if in_chambers else ", none of them a "
           "chamber")
        + f". {R(INIT_SPECIAL_OBJECTS)} deals them at every new game: the kinds of valve, "
        "graphics 96 to 99, go round in turn from a start taken from the seed and the "
        "refresh register, and every sixteenth place by a second count, started from the "
        "random number, is an extra life (graphic 12) instead -- the kind it would have "
        "had is skipped. Run on its own in the simulator for all 64 combinations that "
        f"matter (the kind to start at, and the second count's low four bits), a game has "
        f"{min(n for (_, n) in lives_counts)} or {max(n for (_, n) in lives_counts)} extra "
        f"lives -- three when those four bits are {', '.join(map(str, three))}, one time "
        "in four. And since the extra lives are sixteen places apart and the kinds come "
        "round every four, every extra life of a game takes the place of the same kind: "
        "three kinds always have nine valves and the fourth has seven, or, in a game with "
        f"three extra lives, {fewest} -- exactly as many as its {per_kind[0]} sockets. In "
        "such a game every valve of that kind is needed, and one lost (see below) leaves a "
        "chamber that can never be activated (the counts are measured; that game was not "
        "played to its end). The places as this page's game dealt them (the simulator's "
        "first game, whose seed is always the same):</p>",
        table(["Place", "Starts in", "U", "V", "Z", "Dealt"] + (["The room"] if in_chambers
                                                                  else []),
              [row if in_chambers else row[:6] for row in place_rows]),
        "<p>The kinds, the valves this game dealt of each, and the chambers that take "
        "them, read from the room data (the crew are the frozen cryonauts in them):</p>",
        table(["Valve", "Kind", "Dealt this game", "Socket", "Chambers", "Crew"],
              [row[:2] + [kinds_rows[k][2]] + row[2:] for k, row in enumerate(socket_rows)]),
        f"<p>When he enters a room, {R(FIND_SPECIAL_OBJS_HERE)} makes a record in 2 or 3 for "
        "each place lying there -- Knight Lore's routine instruction for instruction, the "
        "record's +$10 and +$11 pointing back at the place -- and before the next room is "
        f"built {R(UPDATE_SPECIAL_OBJS)} writes a valve's graphic and position back through "
        "that pointer. That is how a valve stays where it is left. An extra life is not "
        f"written back: touched, it becomes a sparkle whose end ({R(0xB3B0)}) empties its "
        "place for good.</p>",

        "<h3>Carrying</h3>",
        f"<p>The pick-up key ({R(TAKE_OR_LEAVE)}) picks up a valve he is on or beside; "
        "failing that, puts down the oldest thing he carries, under himself, lifting him "
        "12 onto it; failing that, moves what he carries one slot along. He carries three, "
        "first in, first out, shown in the panel's three boxes, coloured by kind. Only the "
        "two records at VALVES are searched, for a valve to take and for a free record to "
        "put one in: so only valves can be carried, and <i>a room holds at most two</i> -- "
        "a third cannot be put down there. Picking one up zeroes its place's graphic, and "
        "empties the record; putting it down fills a record with the valve at his feet and "
        "the place's address, which is written into the place when he leaves.</p>",
        f"<p>In the simulator: a kind-0 (red) valve put beside him in {room_ref(CARRY_FROM)}, "
        f"then the pick-up key pressed until it was in the last slot -- {presses} presses:</p>",
        table(["Press", "Slots (graphics)", "The valve's record", "Its place's graphic"],
              carry_rows),
        carry_fig,

        "<h3>Seating a valve</h3>",
        f"<p>A valve's update routine ({R(LOOSE_VALVE)}) looks for the room's socket "
        "(graphics 112-115) and, if it takes the valve's kind (the socket's graphic less 16), "
        "steers the valve a unit a turn in U and in V towards it. When the valve is exactly "
        "over the socket -- the same U and V, and 12 above its base, which is to say resting "
        "on it -- it activates the chamber. So a valve of the right kind lying anywhere in a "
        "chamber creeps across the floor towards the socket, but it cannot climb: it ends "
        "against the socket's side. The robot has to carry it up: stand on the socket and "
        "put it down there, and the valve, now resting on the socket, slides onto its middle "
        "and seats itself.</p>",
        f"<p>Carried on in the simulator: his life was lost and a new one started in "
        f"{room_ref(CARRY_TO)}, a chamber for red valves -- the valve was still in his last "
        "slot: what he carries survives a death -- and he was put standing on the socket, "
        f"one unit and two off its middle, at ({su - 1}, {sv - 2}). One press put the valve "
        f"down where he stood, on the socket's top at Z {sz + 12}, and lifted him onto it; "
        "later in the same turn the valve's own update had already steered it a unit each "
        f"way, to ({put[1]}, {put[2]}), and in the next it reached ({su}, {sv}) and seated "
        f"itself: graphic 100, the chamber count 1, the room's ink {ink_before} become 7, "
        "white.</p>",
        socket_fig,
        "<p>Activating: the valve becomes a seated valve, graphic plus 4 "
        f"({R(SEATED_VALVE)}), which never falls and cannot be picked up; every attribute's "
        "ink is stepped on by one, sixteen times, with a sparkle's sound and a pause each -- "
        "the room runs twice through all eight colours; the room's ink becomes white for the "
        "rest of the game, written into its record in the room directory (and put back at "
        f"the next game, {R(0xCAD2)}); the panel is recoloured, and CHAMBERS goes up by one, "
        "in BCD. The twenty-fourth sets WON and ends the game.</p>",
        ink_fig,
        f"<p>The socket's other record is its sparkle ({R(SOCKET_SPARKLE)}), hovering 13 "
        "above it and stepping through four frames; when the frame comes round to the "
        f"socket's kind it shows the valve wanted ({R(WANTED_VALVE)}, graphics 104-107, the "
        "valves' own pictures) for two turns. Both go the moment anything from the places "
        f"lies in the room -- even a seated valve -- and {R(SOCKET)} brings the sparkle back "
        "when the room is clear again.</p>",
        sparkle_fig,

        "<h3>The count at the end</h3>",
        f"<p>At the end of a game {R(SUMMARISE_CHAMBERS)} walks the room directory and "
        "takes as a chamber any room whose first object groups after the backgrounds are the "
        "frozen crew, templates 21 and 22 (graphic 74). Exactly the 24 rooms with a socket "
        f"are that. A chamber is activated if a place in that room holds a seated valve "
        "(graphics 100-103); otherwise it is unactivated, and its crew -- the counts of "
        "those first groups -- are added to those lost. The three counts are BCD. From the "
        f"room data: {len(crew)} chambers, {total_crew} crew. The routine run on its own in "
        "the simulator part way through the quest below counted "
        f"{active4} activated, {idle4} unactivated and {lost4} lost after four chambers, "
        f"and {active12}, {idle12} and {lost12} after twelve -- the room data's crew less "
        "those of the chambers done.</p>",

        "<h3>Lost in the depth sort</h3>",
        f"<p>Two boxes in one place meet at entry 13 of the depth sort ({R(BOXES_INTERSECT)},"
        " see <a href=\"Drawing.html\">the drawing page</a>), where a loose valve caught in "
        "either is turned into graphic 64, the start of the sparkle whose end empties its "
        "place: that valve is gone for the game. Nothing in normal play puts a valve inside "
        "something, but a room is rebuilt every time he enters it, from its record, while a "
        "valve lies wherever it was left: a valve put down where a collapsing block used to "
        "be, or on a lift that had risen, is inside that block when the room is next built "
        "(inferred: those two were not played through). In the simulator a valve was put "
        f"into a place at the U, V and Z of a collapsing block in {room_ref(REBUILD_ROOM)}, "
        "and the room entered:</p>",
        table(["When", "The valve's record (graphic)", "Its place (graphic)"], lost_rows),

        "<h3>The quest, run through</h3>",
        "<p>All 24 chambers activated in the simulator, one after another: for each, a place "
        "given a valve of the socket's kind in the chamber, the robot sent there by the "
        "game's own restart, and the valve then moved to where he would have put it down -- "
        "on the socket's top, a unit off its middle each way -- from where it does the rest "
        "itself, in "
        + (f"{min(quest.turns)} or {max(quest.turns)}" if min(quest.turns) != max(quest.turns)
           else f"{quest.turns[0]}")
        + " turns. The twenty-fourth sets WON and the game ends.</p>",
        quest_fig,
        f"<p>The summary after the ending counted {quest.final[0]} activated, "
        f"{quest.final[1]} unactivated and {quest.final[2]} lost. The ending is Knight Lore's "
        f"shape ({R(0xB8A9)}: a screen of text, a tune and a wait, then the summary with "
        "Knight Lore's rating, a step up for every 32 rooms seen and the four best for a win) "
        f"and then Alien 8's own scene, run by the main loop with GAME_OVER set: the robot "
        f"({R(0xA971)}) lowered three pixels a turn into a can of oil, to y {lowest}, and "
        "raised again bright white; a tune, and the menu.</p>",
        ending_fig,

        "<h3>Confirmed and inferred</h3>",
        "<ul>"
        "<li>Run in the simulator when this page was built: the deals; the pick-up and the "
        "slots; the valve carried through a lost life and put down on a socket, seating "
        "itself; the inks; the sparkle; the valve lost in a rebuilt block; all 24 chambers, "
        "the summary's counts part way and at the end, the ending.</li>"
        "<li>Staged: the valves' places, written; the robot's position on the socket; the "
        "quest's valves moved onto the sockets' tops. Everything after each is the "
        "game's.</li>"
        "<li>Read from the code: the kind test, the steering and the exact seat; that the "
        "kind test after the seat cannot fail; that a room holds two.</li>"
        "<li>Inferred: how a player would come to lose a valve in a rebuilt block.</li>"
        "</ul>",
        "</div>"])


# --------------------------------------------------------------------------
# 5. The clock, the remote-controlled robots and the dangers.
# --------------------------------------------------------------------------

CLOCK_DONE = 0xA718             # in MAIN_END_OF_TURN: just after the clock's call
CLOCK_BOX = (200, 160, 248, 184)
REMOTE_ROBOT = 0xA9C7
REMOTE_PAD = 0xAA4D
REMOTE_BUTTON = 0xAA63
REMOTE_STEPS = 0xAA43
FRAGILE = 0xA9B1
CEILING_DROP = 0xAD13
LEAPER = 0xA8F9
SLOW_CHASER = 0xAA89
CLOCKWORK_MOUSE = 0xAAA1
MAKE_DEADLY = 0xB2A7
DEADLY_AND_DRAW = 0xB2B0
REMOTE_ROOM = 0x0B              # the one room with two remote-controlled robots
BREAK_ROOM = 0xD9               # a robot among things that break
DROP_ROOM = 0x84
LEAP_ROOM = 0x97
CHASE_ROOM = 0x5E
MOUSE_ROOM = 0x4D
CHASE_ROBOT = (104, 168)
CHASE_FROM = (152, 88)
QUIET_ROOM = 0xA8
ORDER_NAMES = {1: "stand", 2: "-U", 3: "+V", 4: "+U", 5: "-V"}


def clock_value(memory) -> int:
    return int("".join(str(memory[CLOCK + k] >> 4) for k in range(4)))


class Watch:
    """A room in the simulator: the robot put somewhere, the game run a turn
    at a time with whatever keys or pokes a step asks for, the records of
    interest logged and the screen kept."""

    def __init__(self, snapshot: Path, room: int, spot=None, ready=None):
        self.game = Game(snapshot)
        # build_alien8._go, with a chance to stage something the moment the
        # robot is playing in the room, before anything in it has had time
        # to reach him.
        steps = ba._go(room, spot or ba.CLEAR_SPOT)
        self.game.play(steps[:3])
        if ready:
            ready(self.game.memory, self.game)
        self.game.turns(1)
        self.log = []
        self.screens = []

    @property
    def memory(self):
        return self.game.memory

    def turn(self, keys=(), lives: bool = True) -> None:
        if lives:
            ba._lives(self.memory)
        self.game.turns(1, keys)
        self.screens.append(bytes(self.memory[0x4000:0x5B00]))

    def picture(self, pictures: Pictures, name: str, turns, rects, alt: str, pad: int = 12,
                scale: int | None = None) -> str:
        images = crop_to([self.screens[t] for t in turns], [rects[t] for t in turns], pad)
        if scale:
            return pictures.piece(name, strip(images), alt, scale)
        return pictures.strip(name, images, alt)


def _station_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    from skoolkit.simutils import T

    R = listing.r
    memory = ba.game_memory(snapshot)
    placed = room_graphics(memory)

    # ----- The clock from the first turn of a game.
    log("  the light-years clock...")
    game = Game(snapshot, start=False)
    game.play([([], 1.0), (["1"], 0.3), ([], 0.5), (["0"], 0.3)])
    m = game.memory
    clock_rows, clock_images = [], []
    for turn in range(1, 17):
        game.run_to(CLOCK_DONE, 30.0)
        clock_rows.append([turn] + [f"{m[CLOCK + k] >> 4} ({m[CLOCK + k] & 7})" for k in range(4)])
        # The screen once the turn is over: the first turn in a room shows the
        # whole buffer only after the clock.
        game.run_to(MAIN_LOOP, 10.0)
        clock_images.append(screen_image(m).crop(CLOCK_BOX))
    _check(clock_rows[0][1:] == ["5 (6)", "9 (6)", "9 (6)", "9 (6)"],
           f"the clock's first turn was {clock_rows[0]}")
    clock_fig = figure(pictures.strip("station_clock.png", clock_images[:10], "The clock"),
                       "The light years on the panel at the end of each of a game's first ten "
                       "turns: 6000 rolling down to 5999, then the last digit rolling on to 8.")
    # The rate, over a long run in an empty room.
    game.play([ba.Until("a live player", ba._playing, 30.0)])
    game.go(QUIET_ROOM, (128, 128))
    start_value, start_turns, start_t = clock_value(m), _word(m, TURNS), game.registers[T]
    for _ in range(700):
        ba._lives(m)
        game.turns(1)
    years = start_value - clock_value(m)
    turns = (_word(m, TURNS) - start_turns) & 0xFFFF
    tstates = (game.registers[T] - start_t) / turns
    _check(turns == 700 and years == 100, f"{years} light years went in {turns} turns")
    minutes = 42000 * tstates / TSTATES / 60

    # ----- The clock running out.
    log("  the clock running out...")
    out_game = Game(snapshot)
    out_game.go(QUIET_ROOM, (128, 128))
    om = out_game.memory
    out_game.run_to(RUN_CLOCK, 10.0)
    om[CLOCK:CLOCK + 4] = [0, 0, 0, 1]
    out_game.run_to(0xB7AE, 60.0)
    out_summary = screen_image(om)
    out_counts = summary_counts(om)
    _check(out_counts == (0, 24, 132), f"the summary after the clock ran out was {out_counts}")
    out_game.play([ba.Until("the scene after the game", ba._in_game_over, 90.0)])
    scene_screens = []
    ended = False
    for turn in range(2000):
        try:
            out_game.run_to(MAIN_LOOP, 10.0)
        except RuntimeError:
            ended = True            # back at the menu, which waits for a key
            break
        if om[GAME_OVER] == 0:
            ended = True
            break
        scene_screens.append((om[0x5B41], bytes(om[0x4000:0x5B00])))
    counted = max(state & 0x7F for state, _ in scene_screens)
    _check(ended and counted == 15, f"the scene counted to {counted} (ended: {ended})")
    sparks = next(k for k, (st, _) in enumerate(scene_screens) if k > 4)
    swings = [k for k, (st, _) in enumerate(scene_screens) if st & 0x80]
    picks = [sparks, swings[3], swings[len(swings) // 2]]
    out_fig = figure(pictures.piece("station_out.png",
                                    grid([out_summary] + [screen_of(scene_screens[k][1])
                                                          for k in picks], 2),
                                    "The clock run out", 1),
                     "The clock run out: the summary, and the scene after a lost game -- the "
                     "robot on its stand under the sparks, and the tools taking turns to "
                     "strike it.")

    # ----- The remote-controlled robots.
    log("  the remote-controlled robots...")
    robot_rooms = placed.get(124, [])
    fragile_rooms = placed.get(129, [])
    no_robot = [r for r in fragile_rooms if r not in robot_rooms]
    _check(len(no_robot) == 1 and 116 in [g for g, rooms in placed.items() if no_robot[0] in rooms],
           f"the rooms of things that break without a robot are {no_robot}")
    placed_counts_72 = [0] * sum(len(positions)
                                 for record in ad.room_records(memory)
                                 if record["number"] == no_robot[0]
                                 for template, positions in room_templates(record)
                                 if template_pieces(memory, template)[0][0] == 129)
    buttons = []
    remote = Watch(snapshot, REMOTE_ROOM)
    rm = remote.memory
    robots = remote.game.find_all(range(124, 128))
    _check(len(robots) == 2, f"room ${REMOTE_ROOM:02X} has {len(robots)} robots")
    for graphic in (128, 122, 123):
        for record in remote.game.find_all((graphic,)):
            mirrored = rm[record + FLAGS] >> 6 & 1
            order = 1 if graphic == 128 else 2 + 2 * (graphic & 1) + mirrored
            du = _signed(memory[REMOTE_STEPS + 2 * (order - 1)])
            dv = _signed(memory[REMOTE_STEPS + 2 * (order - 1) + 1])
            buttons.append({"graphic": graphic, "mirrored": mirrored, "order": order,
                            "at": (rm[record + 1], rm[record + 2]), "step": (du, dv),
                            "record": record})
    buttons.sort(key=lambda b: b["order"])
    button_rows = [[graphic_ref(b["graphic"]) + (" mirrored" if b["mirrored"] else ""),
                    f"({b['at'][0]}, {b['at'][1]})", b["order"],
                    f"{b['step'][0]:+d} in U, {b['step'][1]:+d} in V" if b["order"] > 1
                    else "none: it stands"] for b in buttons]
    sequence = [buttons[1], buttons[3], buttons[0], buttons[2], buttons[4]]
    control_rows, control_turns, rects = [], [], []

    def robot_state():
        return [(rm[r + 1], rm[r + 2], rm[r + 0x10] >> 6) for r in robots]

    for b in sequence:
        start = robot_state()
        record = b["record"]
        for part, dz in ((PLAYER, 0), (TOP, 12)):
            rm[part + 1], rm[part + 2] = rm[record + 1], rm[record + 2]
            rm[part + 3] = rm[record + 3] + rm[record + 6] + 8 + dz
        orders = set()
        for _ in range(12):
            remote.turn()
            orders.add(rm[REMOTE_ORDERS] & 0x7F)
            rects.append([tuple(rm[r + 0x18:r + 0x1C]) for r in robots + [PLAYER, TOP]])
        on = robot_state()
        control_turns.append(len(remote.screens) - 1)
        for part, dz in ((PLAYER, 0), (TOP, 12)):
            rm[part + 1], rm[part + 2], rm[part + 3] = 104, 152, 64 + dz
        for _ in range(4):
            remote.turn()
            rects.append([tuple(rm[r + 0x18:r + 0x1C]) for r in robots + [PLAYER, TOP]])
        moved = [k for k in range(2) if on[k][:2] != start[k][:2]]
        who = [k for k in range(2) if on[k][2] & 1]
        control_rows.append([graphic_ref(b["graphic"]) + (" mirrored" if b["mirrored"] else ""),
                             ", ".join(f"${o:02X}" for o in sorted(orders) if o),
                             ", ".join(f"robot {k + 1}" for k in who) or "--",
                             "; ".join(f"robot {k + 1} from ({start[k][0]}, {start[k][1]}) "
                                       f"to ({on[k][0]}, {on[k][1]})" for k in moved)
                             or "neither moves"])
    movers = [row[2] for row in control_rows]
    _check(len(set(movers)) == 2, f"control did not pass between the robots: {movers}")
    remote_fig = figure(remote.picture(pictures, "station_remote.png", control_turns[:4], rects,
                                       "The remote-controlled robots", 16),
                        f"Room ${REMOTE_ROOM:02X} at the end of the first four buttons' twelve "
                        "turns.")

    # A robot breaking the things that break.
    log("  a robot among the things that break...")
    breaker = Watch(snapshot, BREAK_ROOM)
    bm = breaker.memory
    robot = breaker.game.find(range(124, 128))
    push_button = next(r for r in breaker.game.find_all((123,)) if not bm[r + FLAGS] & 0x40)
    fragile_start = len(breaker.game.find_all((129,)))
    for part, dz in ((PLAYER, 0), (TOP, 12)):
        bm[part + 1], bm[part + 2] = bm[push_button + 1], bm[push_button + 2]
        bm[part + 3] = bm[push_button + 3] + bm[push_button + 6] + 8 + dz
    break_log, break_rects = [], []
    broke_at = None
    for turn in range(40):
        breaker.turn()
        count = len(breaker.game.find_all((129,)))
        fragile_now = breaker.game.find_all((129, 54))
        break_log.append((turn, bm[robot + 1], bm[robot + 2], count))
        break_rects.append([tuple(bm[r + 0x18:r + 0x1C]) for r in [robot] + fragile_now][:4])
        if broke_at is None and count < fragile_start:
            broke_at = turn
    _check(broke_at is not None, f"the robot in room ${BREAK_ROOM:02X} broke nothing")
    break_turns = [max(0, broke_at - 8), broke_at - 1, broke_at, min(39, broke_at + 3)]
    break_fig = figure(breaker.picture(pictures, "station_break.png", break_turns, break_rects,
                                       "A robot breaking a thing", 20),
                       f"Room ${BREAK_ROOM:02X}, the remote-controlled robot driven along +U, at "
                       f"turns {', '.join(map(str, break_turns))}: it pushes a thing that breaks, "
                       "which vanishes.")

    # ----- Things that drop from the ceiling.
    log("  things that drop from the ceiling...")
    drops = Watch(snapshot, DROP_ROOM, (96, 160))
    dm = drops.memory
    drop_records = drops.game.find_all((73,))
    tops = {r: dm[r + 3] for r in drop_records}
    latched_turns = 0
    for _ in range(150):
        drops.turn()
        if any(dm[r + 3] != tops[r] for r in drop_records):
            break
        latched_turns += 1
    _check(latched_turns == 150 and dm[DROP_LATCH] == 1,
           "something dropped in an even room before anything was picked up")
    # A real pick-up: a valve beside him, and the key.
    place = VALVES
    dm[place:place + RECORD] = [0] * RECORD
    dm[place + 0], dm[place + 1], dm[place + 2], dm[place + 3] = 98, dm[PLAYER + 1], \
        dm[PLAYER + 2] - 14, dm[PLAYER + 3]
    dm[place + 4], dm[place + 5], dm[place + 6], dm[place + FLAGS] = 5, 5, 12, 0x14
    dm[place + ROOM] = DROP_ROOM
    dm[place + 0x10], dm[place + 0x11] = (PLACES + PLACE_SIZE * 35) & 0xFF, \
        (PLACES + PLACE_SIZE * 35) >> 8
    drops.turn(["1"])
    _check(dm[DROP_LATCH] == 0 and dm[CARRIED_NEW + 4] == 98,
           "the pick-up did not clear the drop latch")
    fall_log, fall_rects = [[tops[r] for r in drop_records]], []
    first_fall = fell = None
    for turn in range(400):
        drops.turn()
        falling = [k for k, r in enumerate(drop_records) if dm[r + 3] != tops[r]]
        fall_log.append([dm[r + 3] for r in drop_records])
        if falling and first_fall is None:
            first_fall, fell = turn, falling[0]
        fall_rects.append([tuple(dm[r + 0x18:r + 0x1C])
                           for r in (drop_records[fell:fell + 1] if fell is not None else [])])
        if first_fall is not None and turn > first_fall + 3 and \
                fall_log[-1][fell] == fall_log[-2][fell] == fall_log[-3][fell]:
            break
    _check(first_fall is not None, "nothing dropped after the pick-up")
    fall_zs = [z[fell] for z in fall_log[first_fall:]]
    fall_zs = fall_zs[:fall_zs.index(fall_zs[-1]) + 1]
    _check(len(fall_zs) > 4 and fall_zs[-1] < fall_zs[0], f"the drop went {fall_zs}")
    landed_at = first_fall - 1 + len(fall_zs) - 1
    fall_turns = [first_fall - 1, first_fall + (landed_at - first_fall) // 2, landed_at]
    drop_fig = figure(drops.picture(pictures, "station_drop.png",
                                    [t + 151 for t in fall_turns],
                                    [[]] * 151 + fall_rects, "A thing dropping", 24, 3),
                      f"Room ${DROP_ROOM:02X}: the first thing to drop once a valve had been "
                      f"picked up, at turns {', '.join(str(t + 1) for t in fall_turns)} after "
                      "the pick-up: hanging, falling, landed.")

    # ----- The dangers, from the code.
    deadly_entries = {0xB29F: "never moves", 0xB2A4: "never moves"}
    starts = listing.containing
    for index, entry in enumerate(starts):
        end = starts[index + 1] if index + 1 < len(starts) else 0x10000
        if not 0xA631 <= entry < 0xD200 or entry in (MAKE_DEADLY, DEADLY_AND_DRAW, 0xB2A4):
            continue
        for address in range(entry, end - 2):
            if memory[address] in (0xCD, 0xC3) and \
                    _word(memory, address + 1) in (MAKE_DEADLY, DEADLY_AND_DRAW):
                deadly_entries.setdefault(entry, "")
                break
    what = {
        LEAPER: "leaps 48 up now and then, one at a time in a room",
        FRAGILE: "never moves; breaks when anything moves it",
        SLOW_CHASER: "homes on the robot a unit a turn in U and V",
        CLOCKWORK_MOUSE: "runs two to five a turn along U or V, turning at random",
        CEILING_DROP: "hangs until let go, then falls",
        0xB06B: "walks two a turn, turning a quarter when stopped (two records)",
        0xB110: "paces two a turn, turning round when stopped (two records)",
        0xB29F: "never moves",
        0xB2A4: "never moves (the spikes)",
    }
    danger_rows = []
    for entry in sorted(deadly_entries):
        graphics = [g for g in range(ad.HANDLER_COUNT)
                    if listing.entry_of(update_routine(memory, g)) == entry]
        rooms = sorted({r for g in graphics for r in placed.get(g, [])})
        danger_rows.append([R(entry), numbers(graphics), what.get(entry, ""), room_list(rooms)])
    _check(len(danger_rows) == 9, f"{len(danger_rows)} routines make things deadly")

    # ----- Worked examples: a leaper, a chaser, a mouse.
    log("  a leaper, a chaser and a mouse...")
    leap = Watch(snapshot, LEAP_ROOM)
    lm = leap.memory
    leapers = leap.game.find_all((130,))
    leap_log, leap_rects = [], []
    for _ in range(120):
        leap.turn()
        leap_log.append([lm[r + 3] for r in leapers])
        leap_rects.append([tuple(lm[r + 0x18:r + 0x1C]) for r in leapers])
    # Where each stands: the lowest it was seen (one may be in the air as the
    # room is entered).
    base_z = {r: min(z[k] for z in leap_log) for k, r in enumerate(leapers)}
    leapt = [k for k, r in enumerate(leapers) if any(z[k] != base_z[r] for z in leap_log)]
    _check(bool(leapt), "no leaper leapt")
    together = sum(1 for z in leap_log
                   if sum(1 for k, r in enumerate(leapers) if z[k] != base_z[r]) > 1)
    _check(together == 0, "two leapers were in the air at once")
    first = next(t for t in range(1, len(leap_log))
                 if any(leap_log[t][k] != base_z[r] and leap_log[t - 1][k] == base_z[r]
                        for k, r in enumerate(leapers)))
    jumper = next(k for k, r in enumerate(leapers)
                  if leap_log[first][k] != base_z[r] and leap_log[first - 1][k] == base_z[r])
    jump = [leap_log[t][jumper] for t in range(first - 1, min(len(leap_log), first + 60))]
    landed = next(k for k in range(2, len(jump)) if jump[k] == jump[0])
    jump = jump[:landed + 1]
    _check(max(jump) - jump[0] in (48, 49) and all(b - a == 2 for a, b in
                                                   zip(jump, jump[1:jump.index(max(jump))])),
           f"the first leap went {jump}")
    leap_turns = [first, first + 8, first + 16, first + 24, first + 32]
    leap_fig = figure(leap.picture(pictures, "station_leap.png", leap_turns, leap_rects,
                                   "A leaper", 12),
                      f"Room ${LEAP_ROOM:02X}: a leaper's jump, every eighth turn from its "
                      "start.")

    def move_chaser(memory, game):
        found = game.find_all((120, 121))
        _check(len(found) == 1, f"room ${CHASE_ROOM:02X} has {len(found)} chasers")
        memory[found[0] + 1], memory[found[0] + 2] = CHASE_FROM

    chase = Watch(snapshot, CHASE_ROOM, CHASE_ROBOT, move_chaser)
    cm = chase.memory
    chasers = chase.game.find_all((120, 121))
    chase_log, chase_rects = [], []
    caught = None
    for turn in range(150):
        chase.turn(lives=False)
        ba._lives(cm)
        if caught is None and cm[PLAYER] in range(48, 56):
            caught = turn
        chase_log.append([(cm[r + 1], cm[r + 2]) for r in chasers])
        chase_rects.append([tuple(cm[r + 0x18:r + 0x1C]) for r in chasers + [PLAYER]])
        if caught is not None and turn > caught + 2:
            break
    _check(caught is not None and caught > 20, f"the chaser caught him on turn {caught}")
    steps = sorted({(abs(b[0][0] - a[0][0]), abs(b[0][1] - a[0][1]))
                    for a, b in zip(chase_log, chase_log[1:caught])})
    chase_turns = [0, caught // 3, 2 * caught // 3, caught - 1, caught + 2]
    chase_fig = figure(chase.picture(pictures, "station_chase.png", chase_turns, chase_rects,
                                     "A chaser", 12),
                       f"Room ${CHASE_ROOM:02X}: the robot standing still, and the chaser "
                       f"coming, at turns {', '.join(map(str, chase_turns))}.")

    mouse = Watch(snapshot, MOUSE_ROOM, (96, 160))
    mm = mouse.memory
    mice = mouse.game.find_all(range(116, 120))
    mouse_log = []
    for _ in range(64):
        mouse.turn()
        r = mice[0]
        mouse_log.append((mm[r + 1], mm[r + 2], _signed(mm[r + 9]), _signed(mm[r + 10]),
                          mm[r] & 2, mm[r + FLAGS] >> 6 & 1))
    turns_made = sum(1 for a, b in zip(mouse_log, mouse_log[1:]) if a[5] != b[5])
    speeds = sorted({abs(s[2]) + abs(s[3]) for s in mouse_log if s[2] or s[3]})

    return "\n".join([
        '<div class="kl-list">',
        "<p>Three things set Alien 8 apart from Knight Lore's rooms: a clock that counts "
        "down the light years to the ship's arrival, robots the player drives from a panel "
        "of buttons, and a set of dangers of its own beside Knight Lore's. This page takes "
        "each in turn.</p>",

        "<h3>The light-years clock</h3>",
        f"<p>The clock ({R(CLOCK)}) is four bytes, the highest digit first; each holds a digit in "
        "bits 4-7 and, in bits 0-2, how far it still has to roll. A new game sets 6000, none "
        f"rolling. Every turn the main loop calls {R(RUN_CLOCK)}: when the last digit has "
        f"finished rolling, {R(0xADC9)} takes a light year off, borrowing up the digits (a 0 "
        "becomes a 9) and giving each digit it changes a count of 7; then "
        f"{R(0xADE5)} takes one off the count of every digit still rolling. Each digit is "
        f"printed by {R(0xADB0)} starting that many rows into its character, so a digit "
        "just changed shows mostly the one before it and slides down into place over seven "
        "turns, like the wheel of a mechanical counter -- the character after 9 in the font "
        "is a second 0, so a 9 comes in from a 0. The last digit is printed inverted, and the "
        "32 by 8 pixels are copied to the screen. When all four bytes are zero the game is "
        f"over ({R(0xB761)}). Nothing in Knight Lore or Pentagram is like it.</p>",
        f"<p>A game's first turns, stopped in the simulator just after {R(RUN_CLOCK)} each "
        "turn -- each digit, and in brackets its count:</p>",
        table(["Turn", "Thousands", "Hundreds", "Tens", "Units"], clock_rows[:10]),
        clock_fig,
        f"<p>So a light year goes every seven turns: measured over 700 turns in "
        f"{room_ref(QUIET_ROOM)}, an empty room, with the robot standing, the clock went down "
        f"by {years}. The game's 6000 light years are then 42,000 turns. A turn there took "
        f"{tstates:,.0f} T-states on average -- the main loop pads a quiet turn out to six "
        "units of about 20,000 -- so the clock runs out after at least "
        f"{minutes:.0f} minutes of play; busy rooms, whose turns take longer, stretch "
        "it.</p>",
        f"<p>Run out in the simulator -- the clock written as 0001 as {R(RUN_CLOCK)} began a "
        "turn, which it then counted down to nothing -- the game ended as a lost one: the "
        f"summary counted {out_counts[0]} chambers activated, {out_counts[1]} unactivated and "
        f"{out_counts[2]} crew lost, and the scene after a lost game followed, the robot "
        f"being re-programmed: a glove, a hammer and a hook ({R(0xAB61)}) taking turns to "
        f"strike it, one swing at a time, over {len(scene_screens)} turns: the count in "
        "SCENE_STATE went up from 1 with each swing, was 15 on the last turn watched, and "
        "the fifteenth swing's end took it to 16 and the game back to the menu.</p>",
        out_fig,

        "<h3>The remote-controlled robots</h3>",
        f"<p>Remote-controlled robots ({R(REMOTE_ROBOT)}, graphics 124-127) stand in "
        f"{len(robot_rooms)} rooms, one in each but two in room ${REMOTE_ROOM:02X}: "
        f"{room_list(robot_rooms)}. Each of those rooms has a panel on the floor: a pad "
        f"({R(REMOTE_PAD)}, graphic 128) with four buttons round it ({R(REMOTE_BUTTON)}, "
        "graphics 122 and 123, plain or mirrored), for him to stand on. The collision code "
        "gives what he lands on his own Z step, so a pad or a "
        "button with a step knows it is stood on; it clears the step and puts an order in "
        "REMOTE_ORDERS: 1 for the pad, 2 to 5 for the buttons, by graphic and mirror bit. "
        f"The robot in control takes the order and moves by a pair of steps from "
        f"{R(REMOTE_STEPS)} each turn, two units along one axis, animating as it goes; the "
        "pad's order is to stand. A turn with no order gives control up, and the next "
        "robot to run takes it: in a room with two, each time the player steps off, "
        "control passes to the other. The buttons of room "
        f"${REMOTE_ROOM:02X}, read from its built records and the step table:</p>",
        table(["Button", "At (U, V)", "Order", "The robot's step"], button_rows),
        f"<p>Run in room ${REMOTE_ROOM:02X}: the player put on each button in turn for twelve "
        "turns, and on the floor for four between them:</p>",
        table(["Stood on", "Orders seen", "In control, moving", "What moved"], control_rows),
        remote_fig,
        f"<p>They are harmless -- nothing in their routine makes them deadly -- and they are "
        f"there to push. The things that break when moved ({R(FRAGILE)}, graphic 129) are "
        "deadly both ways, and pushable, and turn into the last frame of the sparkle the "
        "moment anything gives them a step. The player cannot push one and live; a "
        f"remote-controlled robot can. They are in {room_list(fragile_rooms)}: every room "
        "with a robot but "
        + " and ".join(f"${r:02X}" for r in robot_rooms if r not in fragile_rooms)
        + ", and "
        + ", ".join(room_ref(r, f"${r:02X}") for r in fragile_rooms if r not in robot_rooms)
        + f", which has {len(placed_counts_72)} of them and clockwork mice to run into them "
        "instead. In "
        f"{room_ref(BREAK_ROOM)}, the player on the +U button, the robot moved from "
        f"U {break_log[0][1]} along +U and broke its first on turn {broke_at}, leaving "
        f"{break_log[-1][3]} of {fragile_start}:</p>",
        break_fig,

        "<h3>Things that drop from the ceiling</h3>",
        f"<p>{R(CEILING_DROP)} (graphic 73) is Knight Lore's spiked ball: deadly both ways, "
        "hanging until a turn when the random number is under 16, no other is falling "
        "(DROPPING) and the drop latch is clear, then falling with a note pitched by its "
        f"height and a thud when it lands ({R(0xAD54)}). {R(ENTER_ROOM)} sets the latch "
        "on entering any even-numbered room, and only picking a valve up (or touching an "
        "extra life) clears it -- and the four rooms that have these, "
        f"{room_list(placed.get(73, []))}, are all even. So nothing drops there until the "
        "robot takes something. In the simulator, in "
        f"{room_ref(DROP_ROOM)}: {latched_turns} turns with nothing dropping, the latch "
        f"set; then a valve put beside him and picked up with the key, which cleared the "
        f"latch; on turn {first_fall + 1} after that one let go, and fell: its Z "
        f"{', '.join(map(str, fall_zs))}.</p>",
        drop_fig,

        "<h3>What kills</h3>",
        "<p>Harm is two bits of +$0D: bit 7 kills what the thing moves into, bit 5 kills "
        "whatever touches it, and the collision code passes bit 6, <i>killed</i>, to "
        "whichever of two meeting things the other's bits say "
        f"(see <a href=\"Movement.html\">the movement page</a>). {R(MAKE_DEADLY)} sets both "
        f"bits; {R(DEADLY_AND_DRAW)} does that and marks the thing for redrawing. These are "
        "all the update routines that reach one of them -- found by searching the code for "
        f"the calls and jumps, with {R(0xB29F)} and {R(0xB2A4)}, which run into "
        f"{R(MAKE_DEADLY)} -- with the graphics {R(UPDATES)} gives them and the rooms that "
        "place those. A killed robot's legs and top both turn into the sparkle, and when "
        "it is over the main loop starts a life at the last doorway (see "
        '<a href="Doorways.html">rooms and doorways</a>). Nothing else hurts him: a fall '
        "only makes a sound. The two-record creatures' lower halves (graphic 11) are not "
        "made deadly themselves; while the pair moves it is one box with the upper half, "
        "which is.</p>",
        table(["Routine", "Graphics", "What it does", "Where"], danger_rows),

        "<h4>Worked examples</h4>",
        f"<p>The leapers ({R(LEAPER)}) in {room_ref(LEAP_ROOM)}, left alone for 120 turns: "
        f"{len(leapt)} of the room's {len(leapers)} leapt, never two in the air at once "
        "(LEAPING). One of them, its Z from the turn before it went until it was down "
        f"again: {', '.join(map(str, jump))} -- two a turn up to 48 above where it started "
        "(the height it keeps in +$11), one more as the rising step runs out, and then "
        "falling faster and faster.</p>",
        leap_fig,
        f"<p>The chaser ({R(SLOW_CHASER)}) in {room_ref(CHASE_ROOM)}: the robot put at "
        f"({CHASE_ROBOT[0]}, {CHASE_ROBOT[1]}) and left standing, the chaser moved to "
        f"({CHASE_FROM[0]}, {CHASE_FROM[1]}) by writing its record. It stepped at him "
        + " or ".join(f"({du}, {dv})" for du, dv in steps)
        + f" in U and V a turn -- a unit on each axis until level on one -- and reached "
        f"him on turn {caught}, which killed him.</p>",
        chase_fig,
        f"<p>A clockwork mouse ({R(CLOCKWORK_MOUSE)}) in {room_ref(MOUSE_ROOM)}, watched for "
        f"64 turns: it ran at {', '.join(map(str, speeds))} units a turn and turned "
        f"{turns_made} times, always onto the other axis.</p>",

        "<h3>Confirmed and inferred</h3>",
        "<ul>"
        "<li>Run in the simulator when this page was built: the clock's first turns, its "
        "rate over 700 turns and a turn's length in T-states, the clock run out and the scene "
        "after; the buttons and the passing of control; a robot breaking a thing; the "
        "latch and a drop; the leaper, the chaser and the mouse.</li>"
        "<li>Staged: the clock written to 0001; the player's position on the buttons and in "
        "the rooms; a valve's record written beside him to pick up.</li>"
        "<li>Read from the code: the clock's digits and counts; the orders and the passing "
        "of control; what makes things deadly (searched).</li>"
        "<li>Inferred: that the rooms of things that break were laid out for the robots to "
        "clear.</li>"
        "</ul>",
        "</div>"])


# --------------------------------------------------------------------------
# Together.
# --------------------------------------------------------------------------

PAGES = {
    "Drawing": "_drawing_page",
    "Movement": "_movement_page",
    "Doorways": "_doorways_page",
    "Chambers": "_chambers_page",
    "Station": "_station_page",
}


def check_html(name: str, body: str) -> None:
    """A ref section's body: no line may start with ; or [ (a comment, a new
    section), and a # in front of a colour would be read as a macro."""
    for number, line in enumerate(body.split("\n"), 1):
        if line.startswith(";") or line.startswith("["):
            raise ValueError(f"{name}: line {number} starts with {line[0]!r}")
    if re.search(r"#[0-9A-Fa-f]{6}\b", body):
        raise ValueError(f"{name}: a colour written with # (use &#35;)")


def build(snapshot: Path, html_dir: Path, log=print, only=None) -> dict[str, str]:
    """Run the worked examples, draw the pictures into
    html_dir/images/howitworks and return the pages' HTML by section name."""
    snapshot = Path(snapshot)
    listing = Listing(snapshot.with_name("alien8.skool"))
    pictures = Pictures(html_dir)
    sections = {}
    for name, page in PAGES.items():
        if only and name not in only:
            continue
        if page not in globals():
            continue
        log(f"Writing the how-it-works page {name}...")
        body = globals()[page](snapshot, listing, pictures, log)
        check_html(name, body)
        sections[name] = body
    if listing.unlinked:
        # Not an error -- the address is still printed -- but a link was meant.
        log("  how it works: no entry to link at " + ", ".join(
            f"${a:04X}" for a in sorted(listing.unlinked)))
    return sections
