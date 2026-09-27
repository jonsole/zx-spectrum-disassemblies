"""Pentagram's "How it works" pages: drawing, movement, doorways, the quest,
and the bolts, the things from the sky and the monsters.

build() returns each page's HTML for the build's generated ref file and
writes the pictures into html_dir/images/howitworks/. Nothing here is a
transcription of the game: every table is read from the game's memory as the
page is built, and every worked example is the game's own code, run in
SkoolKit's simulator -- the build's own Machine (build_pentagram.py), started
from the snapshot at $5E00 and driven the way the build's sessions drive it,
by keys and by the game's own restart. Where a scene is staged by writing to
memory, the page says what was written.

The prose is written from the listing's annotations and the stage 2 notes
(notes/pentagram/); where Pentagram does what Knight Lore does, the page says
so and links Knight Lore's page, and puts its depth on what is Pentagram's
own. Numbers quoted in the prose that the game's code produces are read back
from the runs below, and the build stops if a run does not come out the way
the code says it must.
"""
from __future__ import annotations

import re
from pathlib import Path

import build_pentagram as bp
import pentagram_data as pd

IMAGE_URL = "images/howitworks"
KNIGHT_LORE = "../knightlore"
TSTATES = 3500000

# --------------------------------------------------------------------------
# Addresses read or run here (see their entries in the listing).
# --------------------------------------------------------------------------

OBJECTS = 0xA76F            # 54 records of 32 bytes
RECORD = 32
RECORD_COUNT = 54
ROOM_OBJECTS = 0xA82F       # the room's 48, record 6 on
PLAYER = OBJECTS
BODY = OBJECTS + RECORD
BOLTS = 0xA7AF              # records 2 and 3
FLYERS = 0xA7EF             # records 4 and 5
UPDATES = 0xAE2F            # a word per graphic

MAIN_LOOP = 0xAFDA
TURN_OVER = 0xB038          # in OBJECT_DONE: every object updated
LISTED = 0xB03B             # ...and the draw list made
WIPED = 0xB252              # in RENDER_DYNAMIC_OBJECTS: the wipes done, the sort next
SORTED = 0xB255             # ...everything drawn into the buffer
COPIED = 0xB275             # ...the rectangles copied to the screen
DRAW_OBJECT = 0xB3D3
DRAW_AND_NEXT_PASS = 0xB6B6
DRAW_LIST = 0xB55A
DRAW_LIST_SIZE = 48
SORT_AND_DRAW = 0xB58A
CANDIDATE_CHAIN = 0xB6CD
CANDIDATE_CHAIN_SIZE = 16
DEPTH_ORDER = 0xB638
CALC_PIXEL_XY = 0xB2C5

WIPE_COUNT = 0xA710
NEW_ROOM = 0xA711
DRAW_WORK = 0xA714
TURNS = 0xA715
ROOM_EXTENT = 0xA71D
LIVES = 0xA721
ROOM_ATTR = 0xA738
BUFFER = 0xD88F

ROOM = 8                    # offsets into a record
FLAGS = 7
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


# --------------------------------------------------------------------------
# The listing: which addresses are entries, for #R links.
# --------------------------------------------------------------------------

class Listing:
    """The entries of pentagram.skool and every label in it, read at build
    time, so a link is only made to an address that starts an entry."""

    def __init__(self, skool: Path):
        self.entries: dict[int, str] = {}
        self.labels: dict[int, str] = {}
        self.containing: list[int] = []
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
    """The game on the build's simulated Spectrum (build_pentagram.Machine),
    started from the menu with the keyboard and driven turn by turn."""

    def __init__(self, snapshot: Path):
        self.machine = bp.Machine(snapshot)
        self.play(bp._start("1"))

    @property
    def memory(self):
        return self.machine.memory

    @property
    def registers(self):
        return self.machine.simulator.registers

    def play(self, steps) -> None:
        self.machine.play(steps, "how it works")

    def run_to(self, stop: int, seconds: float = 10.0, keys=()) -> None:
        """Run until PC reaches `stop` -- at least one instruction first, so
        stopping at the same place again catches the next time round -- or
        fail, naming where it was, after `seconds` of the game's time."""
        from skoolkit.simutils import PC, T

        simulator = self.machine.simulator
        self.machine.tracer.keys = set(keys)
        limit = simulator.registers[T] + int(seconds * TSTATES)
        simulator.trace(self.machine.pc, stop, 0, limit, False, None, None, None, None, None)
        self.machine.pc = simulator.registers[PC]
        if self.machine.pc != stop:
            raise RuntimeError(f"the game never reached ${stop:04X} in {seconds} s "
                               f"(PC ${self.machine.pc:04X})")

    def turns(self, count: int = 1, keys=()) -> None:
        """Play whole turns, each from the start of the main loop."""
        for _ in range(count):
            self.run_to(MAIN_LOOP, 10.0, keys)

    def go(self, room: int) -> None:
        """Into a room by the game's own restart (build_pentagram._go), then
        to the start of a turn."""
        self.play(bp._go(room))
        self.turns(1)

    def ix(self) -> int:
        from skoolkit.simutils import IXh, IXl

        return self.registers[IXh] << 8 | self.registers[IXl]

    def record(self, index: int) -> int:
        return OBJECTS + RECORD * index

    def find(self, graphics) -> int | None:
        for index in range(RECORD_COUNT):
            if self.memory[self.record(index)] in graphics:
                return self.record(index)
        return None


def call(memory, address: int, registers: dict | None = None, seconds: float = 2.0):
    """Run one routine on a fresh simulator over `memory` until it returns;
    the simulator afterwards. A return address nothing else uses is pushed
    first: $5DFE, below the game's own stack, holding $5D00."""
    from skoolkit import CSimulator
    from skoolkit.simulator import Simulator
    from skoolkit.simutils import PC, SP, T

    memory = list(memory)
    trap = 0x5D00
    memory[0x5DFE:0x5E00] = [trap & 0xFF, trap >> 8]
    simulator = (CSimulator or Simulator)(memory, state={"iff": 0, "im": 1, "tstates": 0})
    for index, value in (registers or {}).items():
        simulator.registers[index] = value
    simulator.registers[SP] = 0x5DFE
    simulator.registers[PC] = address
    # trace() wants a tracer; the build's, with no keys held.
    simulator.set_tracer(bp._key_tracer_class()(simulator))
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


def buffer_image(memory):
    """The screen buffer at $D88F as a picture: 192 rows of 32 bytes, its
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


def crop_box(images, margin: int = 6, floor: int = 0):
    """The smallest box holding everything drawn in any of the pictures."""
    boxes = [image.convert("L").point(lambda v: 255 if v > floor else 0).getbbox()
             for image in images]
    boxes = [box for box in boxes if box]
    if not boxes:
        return (0, 0, images[0].width, images[0].height)
    left = max(0, min(b[0] for b in boxes) - margin)
    top = max(0, min(b[1] for b in boxes) - margin)
    right = min(images[0].width, max(b[2] for b in boxes) + margin)
    bottom = min(images[0].height, max(b[3] for b in boxes) + margin)
    return (left, top, right, bottom)


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


def _check(condition: bool, what: str) -> None:
    """The prose says what the code does; if a run disagrees, the page would
    be wrong, so the build stops instead."""
    if not condition:
        raise RuntimeError(f"pentagram_howitworks: {what}")


def update_routine(memory, graphic: int) -> int:
    return _word(memory, UPDATES + 2 * graphic)


# --------------------------------------------------------------------------
# 1. How a moving object is drawn.
# --------------------------------------------------------------------------

TRACE_ROOM = 29             # two pacing heads and the well
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
            "objects": objects, "listed": listed, "order": order, "rects": list(reversed(rects)),
            "work": work}


def survey_rooms(game: Game, rooms: list[int]) -> dict:
    """Every room's first turn: how many objects the draw list holds, the
    longest chain of candidates the depth sort builds, and the pictures the
    projection would have put left of the screen but for the clamp."""
    memory = game.memory
    out = {}
    for room in rooms:
        bp._lives(memory)
        memory[bp.PLAYER_ROOM] = room
        memory[bp.TEMPLATE_ROOM] = room
        memory[bp.PLAYER_STATE] |= 0x40
        for _ in range(200):
            game.run_to(LISTED)
            if memory[bp.PLAYER_ROOM] == room and memory[NEW_ROOM]:
                break
        else:
            raise RuntimeError(f"room {room} never came")
        listed = 0
        while memory[DRAW_LIST + listed] != 0xFF:
            listed += 1
        clamped, nudges = [], []
        for index in range(RECORD_COUNT):
            base = game.record(index)
            if memory[base]:
                # As CALC_PIXEL_XY does it, in bytes: no carry out of the
                # nudge's ADD is what sends a picture to x 0.
                x = ((memory[base + 1] + memory[base + 2]) & 0xFF) - 128 & 0xFF
                nudge = memory[base + 0x12]
                nudges.append(nudge)
                if x + nudge < 0x100:
                    clamped.append((memory[base], x + nudge - 256))
        longest = 0
        for _ in range(listed):
            game.run_to(DRAW_AND_NEXT_PASS)
            length = 0
            while memory[CANDIDATE_CHAIN + length] != 0xFF and length < CANDIDATE_CHAIN_SIZE:
                length += 1
            longest = max(longest, length)
        out[room] = {"listed": listed, "chain": longest, "clamped": clamped,
                     "nudges": nudges}
    return out


OVERFLOW_ROOM = 87          # 43 records from the directory: the fullest room
OVERFLOW_SPOTS = [(88, 88), (168, 88), (88, 168), (168, 168), (128, 100)]


def overflow(snapshot: Path, things: int) -> dict:
    """Leave `things` of the collectables in the fullest room -- by writing
    their quest records, which is what leaving them there does (#R$B115) --
    and restart into it: the first turn lists every record in use. What the
    list writes past its end, and what the game does next."""
    game = Game(snapshot)
    memory = game.memory
    for k in range(things):
        record = bp.QUEST_RECORDS + bp.QUEST_SIZE * (4 + k)
        u, v = OVERFLOW_SPOTS[k]
        memory[record + 1], memory[record + 2], memory[record + 3] = u, v, 128
        memory[record + ROOM] = OVERFLOW_ROOM
    code_before = list(memory[SORT_AND_DRAW:SORT_AND_DRAW + 4])
    bp._lives(memory)
    memory[bp.PLAYER_ROOM] = OVERFLOW_ROOM
    memory[bp.TEMPLATE_ROOM] = OVERFLOW_ROOM
    memory[bp.PLAYER_STATE] |= 0x40
    for _ in range(200):
        game.run_to(LISTED)
        if memory[bp.PLAYER_ROOM] == OVERFLOW_ROOM and memory[NEW_ROOM]:
            break
    listed = 0
    while memory[DRAW_LIST + listed] != 0xFF and listed < 60:
        listed += 1
    code_after = list(memory[SORT_AND_DRAW:SORT_AND_DRAW + 4])
    # Then as the build's sessions run it: interrupts taken if enabled.
    rates = []
    for _ in range(4):
        before = _word(memory, TURNS)
        game.machine.run(5.0)
        rates.append((_word(memory, TURNS) - before) & 0xFFFF)
    from skoolkit.simutils import IFF

    return {"listed": listed, "before": code_before, "after": code_after, "rates": rates,
            "room": memory[bp.PLAYER_ROOM], "iff": game.registers[IFF],
            "pc": game.machine.pc}


OPCODES = {0x34: "INC (HL)", 0x35: "DEC (HL)", 0xFF: "RST $38", 0xAF: "XOR A",
           0x14: "INC D", 0xA7: "AND A", 0xDD: "(IX prefix)"}


def decode(values: list[int]) -> str:
    """What four bytes at the start of SORT_AND_DRAW now say, for the few
    instructions a record number or $FF can make there."""
    out, i = [], 0
    while i < len(values):
        if values[i] == 0x32 and i + 2 < len(values):
            out.append(f"LD (${values[i + 2]:02X}{values[i + 1]:02X}),A")
            i += 3
            continue
        out.append(OPCODES.get(values[i], f"${values[i]:02X}"))
        i += 1
    return ", ".join(out)


CLAMP_CASES = [(69, 69), (72, 72), (80, 80), (128, 128)]
LEGS_NUDGE = (0xF4, 0xFA)       # -12, -6: DRAW_AT_L12_D6, the legs' routine's first call


def clamp_examples(memory) -> list[list]:
    """CALC_PIXEL_XY on a record at the room's left-hand corner and further
    in: the x it writes, and the x Knight Lore's sum would have given."""
    from skoolkit.simutils import IXh, IXl

    rows = []
    record = 0xBACA             # PANEL_RECORD: a spare record the game draws through
    for u, v in CLAMP_CASES:
        memory = list(memory)
        memory[record:record + 32] = [0] * 32
        memory[record + 1], memory[record + 2], memory[record + 3] = u, v, 128
        memory[record + 0x12], memory[record + 0x13] = LEGS_NUDGE
        simulator = call(memory, CALC_PIXEL_XY, {IXh: record >> 8, IXl: record & 0xFF})
        x = simulator.memory[record + 0x1A]
        base = (u + v - 128) & 0xFF
        sum_ = base + _signed(LEGS_NUDGE[0])
        wrapped = sum_ & 0xFF
        expected = 0 if base + LEGS_NUDGE[0] < 0x100 else wrapped
        _check(x == expected, f"CALC_PIXEL_XY gave x {x} at U {u}, V {v}; the code says {expected}")
        rows.append([u, v, base, sum_, x, wrapped])
    return rows


def _drawing_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    R = listing.r
    memory = bp.game_memory(snapshot)
    game = Game(snapshot)
    game.go(TRACE_ROOM)
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
    images = {}
    for name in ("before", "wiped", "drawn", "after"):
        images[name] = pictures.stage(f"drawing_{name}.png", outlined(frame[name], rects),
                                      f"The {name} stage")

    rows = []
    for position, index in enumerate(frame["order"], 1):
        o = frame["objects"].get(index)
        graphic = o["graphic"] if o else memory[OBJECTS + RECORD * index]
        routine = update_routine(memory, graphic)
        if index == 1 and o and o["wipe"]:
            why = "the body: copies the legs' flags, bits 4 and 5 with them"
        elif index == 0 and o and o["wipe"] and not o["moved"]:
            why = "the legs: marked every turn, moving or not"
        elif o and o["wipe"]:
            why = ("moved" if o["moved"] else "changed picture" if o["graphic"] != o["was"]
                   else "marked by its own update")
        else:
            why = "overlaps a change"
        rows.append([position, index, graphic_ref(graphic), R(routine), why])
    rect_rows = [[c * 8, top, w * 8, h] for c, top, w, h in rects]

    log("  every room's first turn: the draw list and the depth sort's chain...")
    rooms = bp._rooms(snapshot)
    survey = survey_rooms(Game(snapshot), rooms)
    fullest = max(survey.items(), key=lambda kv: kv[1]["listed"])
    longest = max(survey.items(), key=lambda kv: kv[1]["chain"])
    chain_rooms = sorted(r for r, s in survey.items() if s["chain"] == longest[1]["chain"])
    over_kl = sorted(r for r, s in survey.items() if s["chain"] > 7)
    clamped_rooms = sorted(r for r, s in survey.items() if s["clamped"])
    clamped_graphics = sorted({g for s in survey.values() for g, _ in s["clamped"]})
    all_nudges = sorted({n for s in survey.values() for n in s["nudges"]})
    _check(all(n >= 0x80 for n in all_nudges), "a nudge in use is not negative")
    _check(fullest[1]["listed"] < DRAW_LIST_SIZE, "a room's first turn overflows the list")
    _check(longest[1]["chain"] < CANDIDATE_CHAIN_SIZE, "a chain overflows")

    log("  the draw list overflowing...")
    records_87 = survey[OVERFLOW_ROOM]["listed"] - 2
    free_87 = 48 - records_87
    runs = {n: overflow(snapshot, n) for n in (2, 3, 4, 5)}
    _check(runs[2]["after"] == runs[2]["before"], "two things in room 87 overflowed the list")
    _check(runs[3]["listed"] == 48 and runs[3]["after"][0] == 0xFF,
           "three things in room 87 did not put the list's $FF on the sort")
    _check(runs[4]["listed"] == 49 and runs[5]["listed"] == 50, "four or five things listed wrong")

    def code(values):
        return " ".join(f"{v:02X}" for v in values)

    def where(pc):
        if pc < 0x4000:
            return "in the ROM"
        entry = listing.entry_of(pc)
        return f"in {R(entry)}" if entry is not None else f"at ${pc:04X}"

    over_rows = []
    for n, run in runs.items():
        result = []
        if run["after"] == run["before"]:
            result.append("nothing overwritten; the game plays on "
                          f"({', '.join(str(r) for r in run['rates'])} turns in each "
                          "5 seconds)")
        else:
            result.append(f"the first bytes of the sort become <code>{code(run['after'])}"
                          f"</code>: {decode(run['after'])}")
            result.append("turns in successive 5-second spells: "
                          + ", ".join(str(r) for r in run["rates"])
                          + f"; it ended {where(run['pc'])}")
        over_rows.append([n, 2 + records_87 + n, "; ".join(result)])

    rate_normal = f"{min(runs[2]['rates'])} to {max(runs[2]['rates'])}"
    drawn = len(frame["order"])
    pacers = [i for i in moved if frame["objects"][i]["graphic"] in (92, 93)]
    kl_mo = kl("MovingObjects", "Knight Lore's page on the same pipeline")
    clamp = clamp_examples(memory)

    return "\n".join([
        '<div class="kl-list">',
        "<p>Pentagram draws the way Knight Lore does, with the same code nearly "
        f"instruction for instruction (see also {kl_mo}). Nothing on the "
        "screen is ever rubbed out and redrawn in place. Each turn, only the rectangles "
        "that something changed in are rebuilt in a buffer off the screen, in depth order, "
        "and copied across whole. This page follows that pipeline stage by stage, then a "
        "real turn of the game through it, and then measures the places where Pentagram "
        "differs -- one of which can stop the game.</p>",

        "<h3>1. Every object gets a turn</h3>",
        f"<p>The main loop in {R(0xAF87)} walks all 54 object records -- the player's legs "
        "and body, two bolts, two things from the sky and 48 for the room. Before each "
        f"object's update routine runs, {R(0xAFE1)} copies where its picture was last drawn "
        "(+$18 to +$1B: the width in bytes, the height in rows, the pixel x and y) to +$1C "
        "to +$1F: that is what may have to be rubbed out. The routine is found by the "
        f"object's graphic number in {R(UPDATES)} and entered by a jump, with "
        f"{R(0xB00C)} pushed as its return address.</p>",

        "<h3>2. The update routine moves it</h3>",
        f"<p>A thing that falls calls {R(0xB979)}: one off its Z step for gravity, then "
        f"{R(0xB6ED)}, which cuts the step in U, V and Z against the floor, the walls and "
        "the other 53 records, one axis at a time, and adds what is left to the "
        "position (see <a href=\"Movement.html\">how things move</a>). A thing that "
        "animates changes its graphic number, which is its sprite: there is no separate "
        "frame counter in the drawing.</p>",

        "<h3>3. It marks itself, and whatever it touches</h3>",
        f"<p>Most update routines that moved or changed something end in the tail of "
        f"{R(0xCC4B)}, {R(0xCCDE)}: bits 4 (<i>draw me</i>) and 5 (<i>wipe my old "
        f"picture</i>) of +$07, then {R(0xB9A7)}. That works out the new picture's "
        f"rectangle ({R(0xB938)}, projecting the position through {R(CALC_PIXEL_XY)}: "
        "pixel x = U + V - 128 and, counted up from the bottom, pixel y = (V - U + 128)/2 "
        "+ Z - 104, each plus the object's drawing nudge at +$12 and +$13), takes the "
        "rectangle covering it and the old one, and sets bit 4 on every live record whose "
        "own rectangle meets it. Those will have to be drawn again, because the wipe will "
        "take a bite out of them. It is one level deep: what is marked does not mark its "
        "own neighbours.</p>",

        "<h3>4. The list, and the wipe</h3>",
        f"<p>When all 54 have had their turn, {R(0xB531)} writes the number of every record "
        f"with bit 4 into {R(DRAW_LIST)}, and {R(0xB19E)} takes each one that also has bit 5: "
        "it clears the rectangle covering its old and new pictures in the buffer at "
        f"{R(BUFFER)} -- never on the screen -- in whole bytes across and pixel rows up, and "
        "pushes the rectangle on the stack to copy later.</p>",

        "<h3>5. Drawing, back to front</h3>",
        f"<p>{R(SORT_AND_DRAW)} then draws every listed object into the buffer, each "
        "whole, each through its own mask, in an order worked out from their boxes: it "
        "takes a candidate, compares it with every other undrawn object, and swaps to "
        f"any that has to go first, by the 27-entry table at {R(DEPTH_ORDER)}; when a "
        "candidate survives the whole list it is drawn. The table is Knight Lore's entry "
        f"for entry, and {kl('DepthSort', 'Knight Lore&#39;s depth-sort page')} draws "
        f"all 27 cases. {R(DRAW_OBJECT)} draws one: {R(0xB2EE)} finds the sprite and turns "
        "it in place to face the way the object does (mirrored, upside down, or both), "
        f"and an unrolled run of code, {R(0xB44F)} for a picture on a byte boundary or "
        f"{R(0xB47D)} for one that is not, lays it into the buffer with the stack pointer "
        "reading the sprite a mask and an image byte at a time.</p>",

        "<h3>6. Copying the rectangles</h3>",
        f"<p>Last, {R(0xB19E)} pops each rectangle and {R(0xB278)} copies just that part of "
        "the buffer to the display, a row at a time up the screen. Nothing outside the "
        "rectangles changes, so it does not matter what else is lying in the buffer, and "
        "nothing flickers, because nothing is ever drawn on the display piece by piece.</p>",

        "<h3>7. Pacing</h3>",
        "<p>DRAW_WORK ($A714) counts the turn's work -- one for each object drawn, one for each "
        f"rectangle wiped -- and {R(0xB00C)} then waits six units less that, a unit being "
        "1280 turns of a 26 T-state loop, just under half a frame. A quiet turn is padded "
        "out to the same length as one with six things to do; a busier one simply takes "
        "longer. On the first turn in a room nothing is wiped: every object is drawn into "
        "a cleared buffer and the whole of it copied once.</p>",

        f"<h3>A turn in room {TRACE_ROOM}</h3>",
        f"<p>{room_ref(TRACE_ROOM, f'Room {TRACE_ROOM}')} has two heads pacing to and fro "
        f"(graphics {graphic_ref(92)} and {graphic_ref(93)}, "
        f"{R(0xCEA0)} and {R(0xCEDA)}) and the player standing still. This is its turn "
        f"{TRACE_TURNS + 2} -- the room's first turn draws everything, and these are "
        "ordinary ones -- run by the game's own code in a simulator when this page was "
        f"built, stopped at {R(0xB00C)} after the updates, at the sort in {R(0xB19E)}, at "
        f"every call of {R(DRAW_OBJECT)} and after the copy. {len(moved)} objects moved "
        f"or changed, so there are {len(rects)} rectangles, outlined in red; "
        f"{drawn} objects are drawn to fill them, and DRAW_WORK comes to {frame['work']}"
        f" ({drawn} + {len(rects)}), "
        + ("so the turn does not wait at all. The player is in every turn's count: his "
           "legs' routine marks him to be redrawn whether he moves or not, and the body "
           "copies the legs' flags."
           if frame["work"] >= 6 else
           f"so the turn waits {6 - frame['work']} units.")
        + "</p>",
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

        "<h3>Where Pentagram differs from Knight Lore</h3>",
        table(["", "Knight Lore", "Pentagram"], [
            ["Object records", "40", f"54 ({R(OBJECTS)})"],
            ["The draw list", "48 bytes", f"48 bytes, not grown to match ({R(DRAW_LIST)})"],
            ["The chain of candidates", "8 bytes", f"16 bytes ({R(CANDIDATE_CHAIN)})"],
            ["A picture left of the screen", "wraps round to the right-hand side",
             f"drawn from x 0 ({R(CALC_PIXEL_XY)})"],
            ["Turning a sprite", "three routines", f"one ({R(0xB2EE)})"],
            ["The whole-screen copy on entering a room", "clears the buffer as it goes",
             f"leaves it ({R(0xB178)})"],
            ["Boxes that intersect (entry 13)", "destroy a charm caught in them",
             f"nothing ({R(0xB6B0)})"],
            ["The stack", "reset for every object", "one stack; the update routines keep it "
             "straight"],
        ]),

        "<h4>The clamp at the left edge</h4>",
        f"<p>{R(CALC_PIXEL_XY)} adds the drawing nudge to U + V - 128 and, if that does not "
        f"carry, uses 0 instead. Every nudge in use is negative (in the first turns of every "
        f"room, bytes from ${min(all_nudges):02X} to ${max(all_nudges):02X}), so adding "
        "one to an x that stays on the screen always carries: no carry means the picture "
        "would have started left of the screen, and without the clamp its x would wrap "
        "round to about 250 and it would be drawn at the right-hand edge. Knight Lore has "
        "no such check. In the first turns of all "
        f"{len(rooms)} rooms, "
        + (f"the pictures that would have started left of x 0 are graphics "
           f"{', '.join(str(g) for g in clamped_graphics)}, in {len(clamped_rooms)} rooms"
           if clamped_rooms else
           "no picture would have started left of x 0: nothing is built that far into "
           "the left-hand corner")
        + ". It is something moving into that corner that meets the clamp. "
        f"{R(CALC_PIXEL_XY)} run on its own, on a record with the legs' nudge (-12, -6):</p>",
        table(["U", "V", "U + V - 128", "With the nudge", "Pixel x written",
               "Without the clamp"], clamp),
        "<p>So Sabreman pressed into the left-hand corner of a full-sized room, as far as "
        "the walls let him (U and V 69, with his half-size of 5 and the walls at 64), is "
        "drawn at the left edge of the screen instead of reappearing at the right. The price "
        "is that an object with a nudge of 0 would always be drawn at x 0; none has "
        "one.</p>",

        "<h4>The chain of candidates</h4>",
        "<p>The sort keeps every object it has made the candidate since the last draw, so "
        "that meeting one again -- three or more boxes each partly behind the next -- is "
        "caught and broken by drawing it at once. Knight Lore's chain holds seven and "
        "its end marker; Pentagram's fifteen. Run on the first turn of every room, where "
        "the whole room is sorted at once, the longest chain was "
        f"{longest[1]['chain']}, in rooms {', '.join(str(r) for r in chain_rooms)}"
        f"{' -- the four start rooms, which share a layout' if chain_rooms == [12, 51, 92, 100] else ''}"
        f"; {len(over_kl)} rooms made a chain longer than Knight Lore's seven. So "
        "Pentagram needs the bigger chain, and a chain that long in Knight Lore's eight "
        "bytes would have written its end marker over the next routine. That this is why "
        "it was doubled is an inference.</p>",

        "<h4>The draw list</h4>",
        f"<p>{R(DRAW_LIST)} is 48 bytes, Knight Lore's size for its 40 records; Pentagram "
        f"has 54. A list of more than 47 objects writes on into {R(SORT_AND_DRAW)}, the "
        "code that reads it. The list is longest on the first turn in a room, when "
        "everything is drawn. Run on the first turn of every room, the fullest was room "
        f"{fullest[0]}, with {fullest[1]['listed']} -- its {records_87} records from the "
        "room's data and the player's two -- so no room as the game builds it overflows. "
        "But the room's 48 records have space for more: quest things -- the bucket and "
        "the collectables, which the player can carry and put down anywhere -- come into "
        f"a room in the free records ({R(0xB097)}). {room_ref(OVERFLOW_ROOM, f'Room {OVERFLOW_ROOM}')} "
        f"has {free_87} free.</p>",
        "<p>So, in the simulator, collectables were left in room "
        f"{OVERFLOW_ROOM} -- by writing their room into their quest records, which is "
        f"what leaving them there does ({R(0xB115)}) -- and the player restarted in the "
        "room by the game's own restart, running on afterwards as the build's sessions run "
        "the game, interrupts and all:</p>",
        table(["Things left", "Listed", "What happened"], over_rows),
        f"<p>With three or more, the list's last entries and its end marker land on the "
        f"first bytes of {R(SORT_AND_DRAW)}, and nothing ever puts them back. The end "
        "marker, $FF, is RST $38: from then on every turn's sort first calls the ROM's "
        "interrupt routine, which counts the frame and scans the keyboard into the "
        "system variables -- partly through IY, which in the game points wherever the code "
        "last left it -- and ends with EI, so the 50 Hz interrupt, which the game otherwise "
        "allows only while paused, starts running the same routine fifty times a second. "
        "The bytes lost before it clear DRAW_WORK, so the pacing goes wrong as well. In "
        "every case the game ground to a halt within the 20 seconds watched, where "
        f"normally it ran {rate_normal} turns in 5 seconds of the simulated Spectrum's "
        "time.</p>",
        "<p>A player could bring this about with nothing but the pick-up key: carry "
        f"three things into room {OVERFLOW_ROOM}, put them down, and walk out and back in "
        "-- or lose a life there. That was not played through here: the quest records were "
        "written directly, and what the ROM routine does to the game's memory is read from "
        "the code, not traced. The game's other bugs are on "
        '<a href="reference/bugs.html">the bugs page</a>.</p>',

        "<h3>Confirmed and inferred</h3>",
        "<ul>"
        "<li>Run in the simulator when this page was built: the turn above, stage by "
        "stage; the draw list and the chain on every room's first turn; the clamp's "
        "cases; the overflow table.</li>"
        f"<li>Read from the code: the pipeline's order and the flags; that DRAW_WORK counts "
        "objects drawn and rectangles wiped (checked against the turn traced); the "
        "comparisons of the depth sort, which were compared with Knight Lore's entry by "
        "entry.</li>"
        "<li>Inferred: why the chain was doubled; whether any player of the original ever "
        "overflowed the list.</li>"
        "</ul>",
        "</div>"])


# --------------------------------------------------------------------------
# Shared: where the game's data puts each graphic.
# --------------------------------------------------------------------------

def room_graphics(memory) -> dict[int, list[int]]:
    """Each graphic the room data places, and the rooms it is in: objects by
    their template's graphic, scenery by each of its template's pieces."""
    out: dict[int, set] = {}
    for record in pd.room_records(memory):
        for _, template, _ in record["scenery"]:
            piece = _word(memory, pd.SCENERY_TABLE + 2 * template)
            while True:
                out.setdefault(memory[piece], set()).add(record["number"])
                piece += 8
                if memory[piece] == 0:
                    break
        for _, template, _, positions in record["groups"]:
            if template == 31:
                continue
            graphic = memory[_word(memory, pd.OBJECT_TABLE + 2 * template)]
            out.setdefault(graphic, set()).add(record["number"])
    return {graphic: sorted(rooms) for graphic, rooms in out.items()}


def graphics_of(memory, routine: int) -> list[int]:
    return [g for g in range(pd.GRAPHIC_COUNT) if update_routine(memory, g) == routine]


def room_ref(number: int, text: str | None = None) -> str:
    """A link to a room's entry on the room structure page."""
    return f'<a href="RoomStructure.html#room{number}">{text or f"room {number}"}</a>'


def graphic_ref(graphic: int, text: str | None = None) -> str:
    """A link to a graphic on the objects page."""
    return f'<a href="Objects.html#graphic{graphic}">{text if text is not None else graphic}</a>'


def numbers(values) -> str:
    """Graphic numbers as runs, 1, 2, 3, 5 as '1-3, 5', each end linked."""
    values = sorted(values)
    if not values:
        return "none"
    runs, start = [], None
    for index, value in enumerate(values):
        if start is None:
            start = value
        if index + 1 == len(values) or values[index + 1] != value + 1:
            runs.append(graphic_ref(start) if start == value
                        else f"{graphic_ref(start)}-{graphic_ref(value)}")
            start = None
    return ", ".join(runs)


def room_list(rooms, limit: int = 12) -> str:
    if not rooms:
        return "no room"
    linked = [room_ref(r, str(r)) for r in rooms]
    if len(rooms) > limit:
        return f"{len(rooms)} rooms, from {', '.join(linked[:limit])} ..."
    return ("room " if len(rooms) == 1 else "rooms ") + ", ".join(linked)


# --------------------------------------------------------------------------
# 2. How things move and collide.
# --------------------------------------------------------------------------

ADJ_FOR_OUT_OF_BOUNDS = 0xB6ED


def _record(graphic, u, v, z, su, sv, sz, flags=0x10, du=0, dv=0, dz=0,
            bumped=0, contact=0) -> list[int]:
    record = [0] * RECORD
    record[0:14] = [graphic, u, v, z, su, sv, sz, flags, 0, du & 0xFF, dv & 0xFF, dz & 0xFF,
                    bumped, contact]
    return record


LEGS, BLOCK, HEAD, CRUMBLING, HEAVY, CONVEYOR_U, CONVEYOR_V = 34, 11, 92, 136, 91, 140, 142
MOBILE = 0x1C               # the legs' flags in play: bits 2 (mobile), 3 (doorways), 4
# Each case: what it shows, the turn counter's parity, the mover (record 0),
# the others (records 6 on). Gravity has already taken 1 off the mover's dZ,
# as DEC_DZ_AND_UPDATE_UVZ does before the cut; the player's own move takes 2.
COLLISION_CASES = [
    ("Walking diagonally into a block", 0,
     _record(LEGS, 100, 100, 128, 5, 5, 23, MOBILE, du=3, dv=3, dz=-2),
     [("block", _record(BLOCK, 113, 100, 128, 8, 8, 12, 0))]),
    ("Walking into the wall at U 192 (a room 64 either way)", 0,
     _record(LEGS, 185, 128, 128, 5, 5, 23, MOBILE, du=3, dz=-2), []),
    ("Falling onto a block from 3 above it", 0,
     _record(LEGS, 100, 100, 143, 5, 5, 23, MOBILE, dz=-5),
     [("block", _record(BLOCK, 100, 100, 128, 8, 8, 12, 0))]),
    ("Walking into a block that can be pushed (its flags' bit 2)", 0,
     _record(LEGS, 100, 100, 128, 5, 5, 23, MOBILE, du=3, dz=-2),
     [("block", _record(BLOCK, 113, 100, 128, 8, 8, 12, 0x04))]),
    ("Standing on a block moving 2 a turn in U, as a pacing block does", 0,
     _record(LEGS, 100, 100, 140, 5, 5, 23, MOBILE, dz=-2),
     [("block", _record(87, 100, 100, 128, 8, 8, 12, 0, du=2))]),
    ("Standing on a conveyor, graphic 140, on an odd turn", 1,
     _record(LEGS, 100, 100, 140, 5, 5, 23, MOBILE, dz=-2),
     [("conveyor", _record(CONVEYOR_U, 100, 100, 128, 8, 8, 12, 0))]),
    ("The same on an even turn", 0,
     _record(LEGS, 100, 100, 140, 5, 5, 23, MOBILE, dz=-2),
     [("conveyor", _record(CONVEYOR_U, 100, 100, 128, 8, 8, 12, 0))]),
    ("Standing on a conveyor, graphic 142, on an odd turn", 1,
     _record(LEGS, 100, 100, 140, 5, 5, 23, MOBILE, dz=-2),
     [("conveyor", _record(CONVEYOR_V, 100, 100, 128, 8, 8, 12, 0))]),
    ("Landing on a crumbling block", 0,
     _record(LEGS, 100, 100, 141, 5, 5, 23, MOBILE, dz=-2),
     [("block", _record(CRUMBLING, 100, 100, 128, 8, 8, 12, 0))]),
    ("The heavy block, graphic 91, landing on a crumbling block", 0,
     _record(HEAVY, 100, 100, 141, 8, 8, 12, 0x14, dz=-2),
     [("block", _record(CRUMBLING, 100, 100, 128, 8, 8, 12, 0))]),
    ("A block with no bit 2 landing on a crumbling block", 0,
     _record(BLOCK, 100, 100, 141, 8, 8, 12, 0x10, dz=-2),
     [("block", _record(CRUMBLING, 100, 100, 128, 8, 8, 12, 0))]),
    ("Walking into a deadly head (+$0D = $A0)", 0,
     _record(LEGS, 100, 100, 128, 5, 5, 23, MOBILE, du=3, dz=-2),
     [("head", _record(HEAD, 111, 100, 128, 6, 6, 12, 0, contact=0xA0))]),
    ("A deadly head walking into him", 0,
     _record(HEAD, 111, 100, 128, 6, 6, 12, 0, du=-3, dz=-1, contact=0xA0),
     [("player", _record(LEGS, 100, 100, 128, 5, 5, 23, MOBILE))]),
]


def try_collision(memory, mover: list[int], others: list[list[int]], odd: int,
                  sizes=(64, 64, 128)) -> tuple[list[int], list[list[int]]]:
    """Put the mover in record 0 and the others from record 6 in an otherwise
    empty set of records, and run ADJ_FOR_OUT_OF_BOUNDS on the mover. The
    records afterwards."""
    from skoolkit.simutils import IXh, IXl

    memory = list(memory)
    memory[OBJECTS:UPDATES] = [0] * (UPDATES - OBJECTS)
    memory[OBJECTS:OBJECTS + RECORD] = mover
    for i, other in enumerate(others):
        base = ROOM_OBJECTS + RECORD * i
        memory[base:base + RECORD] = other
    memory[ROOM_EXTENT:ROOM_EXTENT + 3] = sizes
    memory[TURNS], memory[TURNS + 1] = odd, 0
    simulator = call(memory, ADJ_FOR_OUT_OF_BOUNDS, {IXh: OBJECTS >> 8, IXl: OBJECTS & 0xFF})
    after = simulator.memory
    return (list(after[OBJECTS:OBJECTS + RECORD]),
            [list(after[ROOM_OBJECTS + RECORD * i:ROOM_OBJECTS + RECORD * (i + 1)])
             for i in range(len(others))])


def _steps(record) -> str:
    return f"({_signed(record[9])}, {_signed(record[10])}, {_signed(record[11])})"


def _collision_rows(memory) -> list[list]:
    rows = []
    for what, odd, mover, others in COLLISION_CASES:
        after, others_after = try_collision(memory, mover, [o for _, o in others], odd)
        notes = []
        cut = after[BUMPED] & 7
        if cut:
            notes.append("stopped in " + ", ".join(a for bit, a in ((1, "U"), (2, "V"), (4, "Z"))
                                                   if cut & bit)
                         + (" (+$0C bit " if cut in (1, 2, 4) else " (+$0C bits ")
                         + ", ".join(str(b) for b in range(3) if cut >> b & 1) + ")")
        if after[CONTACT] & 0x40:
            notes.append("the mover is killed (+$0D bit 6)")
        if after[0x17] & 0x80:
            notes.append("the mover gets +$17 bit 7")
        for (name, before), other in zip(others, others_after):
            changes = []
            if other[9:12] != before[9:12]:
                changes.append(f"its step becomes {_steps(other)}")
            if other[CONTACT] & 0x40 and not before[CONTACT] & 0x40:
                changes.append("killed")
            if other[CONTACT] & 0x08 and not before[CONTACT] & 0x08:
                changes.append("+$0D bit 3")
            if other[0x17] & 0x80 and not before[0x17] & 0x80:
                changes.append("+$17 bit 7")
            if changes:
                notes.append(f"the {name}: " + ", ".join(changes))
        rows.append([what, _steps(mover), _steps(after), "; ".join(notes) or "nothing else"])
    return rows


class Scene:
    """A set piece: the player stood on (or near) an object in a real room,
    and the game run a turn at a time, the object and the player logged and
    the screen kept every turn, to draw whichever turns are wanted."""

    def __init__(self, snapshot: Path, room: int, graphics, on_top: bool = True,
                 above: int = 2):
        self.room = room
        self.game = Game(snapshot)
        self.game.go(room)
        memory = self.game.memory
        self.record = self.game.find(graphics)
        if self.record is None:
            raise RuntimeError(f"no graphic {graphics} in room {room}")
        if on_top:
            for k, record in enumerate((PLAYER, BODY)):
                memory[record + 1] = memory[self.record + 1]
                memory[record + 2] = memory[self.record + 2]
                memory[record + 3] = (memory[self.record + 3] + memory[self.record + 6] + above
                                      + 12 * k)
        self.log = []
        self.screens = {}

    def run(self, turns: int, keys=()) -> list[dict]:
        memory = self.game.memory
        for turn in range(turns + 1):
            r, p = self.record, PLAYER
            self.log.append({"turn": turn, "graphic": memory[r], "u": memory[r + 1],
                             "v": memory[r + 2], "z": memory[r + 3],
                             "pu": memory[p + 1], "pv": memory[p + 2], "pz": memory[p + 3],
                             "killed": bool(memory[p + CONTACT] & 0x40),
                             "rects": [tuple(memory[b + 0x18:b + 0x1C]) for b in (r, PLAYER, BODY)
                                       if memory[b]]})
            self.screens[turn] = bytes(memory[0x4000:0x5B00])
            if turn < turns:
                bp._lives(memory)
                self.game.turns(1, keys)
        return self.log

    def picture(self, pictures: Pictures, name: str, turns, alt: str,
                only_object: bool = False) -> str:
        """The screens at `turns`, each as the turn began, cut to where the
        object and the player were drawn in them, side by side."""
        boxes = []
        for turn in turns:
            rects = self.log[turn]["rects"][:1] if only_object else self.log[turn]["rects"]
            for width, height, x, y in rects:
                if width and height:
                    boxes.append((x, 191 - (y + height), x + 8 * width, 192 - y))
        left = max(0, min(b[0] for b in boxes) - 12)
        top = max(0, min(b[1] for b in boxes) - 12)
        right = min(256, max(b[2] for b in boxes) + 12)
        bottom = min(192, max(b[3] for b in boxes) + 8)
        images = []
        for turn in turns:
            memory = [0] * 0x4000 + list(self.screens[turn])
            images.append(screen_image(memory).crop((left, top, right, bottom)))
        image = strip(images)
        return pictures.piece(name, image, alt, scale=2 if image.width <= 560 else 1)


BOB_ROOM = 107               # a deadly head that bobs clear of what is round it


def _movement_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    R = listing.r
    memory = bp.game_memory(snapshot)
    placed = room_graphics(memory)
    collisions = _collision_rows(memory)

    def where(routine):
        # A graphic whose routine is an entry point inside this one counts
        # too (PACER_U inside DEADLY_PACER_U, SLIDING_TABLE inside HEAVY_BLOCK).
        graphics = [g for g in range(pd.GRAPHIC_COUNT)
                    if listing.entry_of(update_routine(memory, g)) == routine]
        rooms = sorted({r for g in graphics for r in placed.get(g, [])})
        return graphics, rooms

    movers = []
    for routine, what in [
        (0xCD81, "Falls one unit a turn; a push moves it for that turn. The common tail "
                 "of many others: moved at all, clear the steps and redraw; not, return "
                 "without a redraw, so a thing at rest costs nothing to draw."),
        (0xCD70, "The spikes: deadly both ways, otherwise as the pushable things."),
        (0xCD75, "The heavy block (91): its sideways steps are cleared before it moves, so "
                 "pushes are lost and it only falls. With the player, the only thing that "
                 "marks what it lands on (+$17 bit 7). The table (73) enters at "
                 f"{R(0xCD7C)} and keeps a push."),
        (0xCDA0, "Sinks one unit a turn while it is stood on: any Z step it is given "
                 "becomes -1."),
        (0xCDBB, "The lift: waits to be landed on, then rises carrying him."),
        (0xCE31, "Bobs: falls, and on landing rises to Z 176, and falls again."),
        (0xCE9A, f"The deadly head that bobs: deadly both ways, then as {R(0xCE31)}."),
        (0xCEA0, "Paces along U, 2 units a turn, turning round when it bumps into "
                 "anything; never falls. Graphic 92, a head, is deadly; 87, a block, enters "
                 f"at {R(0xCEA3)}, after the call that makes it deadly, and is not."),
        (0xCEDA, f"The same along V: 93, a deadly head; 88, a block ({R(0xCEDD)})."),
        (0xD2AD, "Crumbles a stage for each turn it is stood on; after the fourth it "
                 "vanishes."),
        (0xD2DE, "Conveyor +U: clears +$0D bit 3 so it can push again next turn. The push "
                 f"itself is in the collision code ({R(0xB866)})."),
        (0xD2E9, "Conveyor -U, the same code."),
        (0xD2F4, "Conveyor +V, the same code."),
        (0xD2FF, "Conveyor -V, the same code."),
    ]:
        graphics, rooms = where(routine)
        movers.append([R(routine), numbers(graphics), what, room_list(rooms)])

    log("  set pieces: the lift, the crumbling block, the sinking block, a conveyor, a "
        "pacing block, the bobbing head...")

    def stages(rows):
        """(graphic, turns) for each stage the object went through, up to 0."""
        out = []
        for row in rows:
            if row["graphic"] == 0:
                break
            if out and out[-1][0] == row["graphic"]:
                out[-1] = (row["graphic"], out[-1][1] + 1)
            else:
                out.append((row["graphic"], 1))
        return out

    def zs(rows, key, turns):
        return ", ".join(str(rows[t][key]) for t in turns)

    figures = []

    def show(scene, name, turns, caption, only_object=False):
        _check(not any(row["killed"] for row in scene.log),
               f"the player was killed in the {name} scene")
        figures.append(figure(scene.picture(pictures, f"move_{name}.png", turns, caption,
                                            only_object), caption))

    # The lift.
    lift_scene = Scene(snapshot, 54, (84,))
    lift = lift_scene.run(72)
    rise = next(r["turn"] for r in lift if r["z"] > 128)
    landed = next(r["turn"] for r in lift if r["pz"] == r["z"] + 12)
    _check(landed < rise, "the lift rose before he stood on it")
    top = next((r["turn"] for r in lift if r["z"] == 176), None)
    _check(top is not None, "the lift never reached 176")
    _check(all(lift[t]["z"] == lift[t - 1]["z"] + 1 for t in range(rise + 1, top + 1)),
           "the lift did not rise a unit a turn")
    _check(all(lift[t]["pz"] == lift[t]["z"] + 12 for t in range(rise, top + 1)),
           "he did not ride 12 above the lift")
    floor = next(r["turn"] for r in lift if r["turn"] > top and r["z"] == 128)
    third = (top - rise) // 3
    lift_turns = [rise, rise + third, rise + 2 * third, top, top + (floor - top) // 2, floor]
    show(lift_scene, "lift", lift_turns,
         "The lift in room 54, with him on it, at turns " + ", ".join(map(str, lift_turns))
         + ": rising, at the top, falling with him, back at the floor.")

    # The crumbling block.
    crumble_scene = Scene(snapshot, 4, (136, 137, 138, 139))
    crumble = crumble_scene.run(8)
    _check([g for g, _ in stages(crumble)] == [136, 137, 138, 139]
           and all(n == 1 for _, n in stages(crumble)[1:]),
           f"the block crumbled as {stages(crumble)}")
    show(crumble_scene, "crumble", list(range(1, 8)),
         "The crumbling block in room 4, a turn each from the turn he lands.")

    # The sinking block.
    sink_scene = Scene(snapshot, 15, (78,))
    sink = sink_scene.run(24)
    _check(all(sink[t]["z"] == sink[t - 1]["z"] - 1 for t in range(3, 25)),
           "the sinking block did not sink a unit a turn")
    show(sink_scene, "sink", [1, 8, 16, 24], "The sinking block in room 15, at turns 1, 8, "
         "16 and 24.")

    # A conveyor.
    conveyor_scene = Scene(snapshot, 129, (140,))
    conveyor = conveyor_scene.run(16)
    gains = [conveyor[t]["pu"] - conveyor[t - 1]["pu"] for t in range(2, 17)]
    _check(sorted(set(gains)) == [0, 2] and all(a != b for a, b in zip(gains, gains[1:])),
           f"the conveyor moved him by {gains}")
    show(conveyor_scene, "conveyor", [1, 6, 11, 16],
         "Standing on the conveyor (graphic 140) in room 129, at turns 1, 6, 11 and 16.")

    # A pacing block.
    pacer_scene = Scene(snapshot, 93, (87,))
    pacer = pacer_scene.run(20)
    _check(abs(pacer[12]["pu"] - pacer[2]["pu"]) >= 16, "the pacing block did not carry him")
    show(pacer_scene, "pacer", [1, 7, 14, 20],
         "Riding the pacing block (graphic 87) in room 93, at turns 1, 7, 14 and 20.")

    # The bobbing head, left alone.
    bob_scene = Scene(snapshot, BOB_ROOM, (86,), on_top=False)
    bob = bob_scene.run(48)
    _check(max(r["z"] for r in bob) == 176, "the head did not bob up to 176")
    show(bob_scene, "bob", [0, 6, 12, 18, 24, 30, 36],
         f"The deadly head in room {BOB_ROOM}, every sixth turn, the player well away from it.",
         only_object=True)
    bob_low = min(r["z"] for r in bob)

    scene_rows = [
        ["He stands on the lift (room 54)",
         f"it stays put until he is standing on it (his Z {lift[landed]['pz']}, the lift's "
         f"top, on turn {landed} here), and from the next turn rises one unit a turn with "
         f"him 12 above it, from Z 128 to "
         f"176 at turn {top}; then he drops and pushes it down with him, faster each turn "
         f"(its Z: {zs(lift, 'z', range(top, floor + 1))}), and at the floor, turn "
         f"{floor}, it starts again"],
        ["He stands on a crumbling block (room 4)",
         f"graphics {', '.join(str(g) for g, _ in stages(crumble))} from the turn he lands: "
         f"a stage a turn, then gone, and he falls (his Z: "
         f"{zs(crumble, 'pz', range(4, 9))})"],
        ["He stands on a sinking block (room 15)",
         f"its Z: {zs(sink, 'z', range(0, 25, 4))} at every fourth turn -- a unit a turn "
         "from the turn after he lands"],
        ["He stands on a conveyor, graphic 140 (room 129)",
         f"his U: {zs(conveyor, 'pu', range(0, 17, 2))} at every other turn -- two units "
         "every other turn"],
        ["He stands on a pacing block, graphic 87 (room 93)",
         f"its U: {zs(pacer, 'u', range(0, 21, 2))}; his: {zs(pacer, 'pu', range(0, 21, 2))} "
         "-- carried along with it, a turn behind"],
        [f"The deadly head (room {BOB_ROOM}), left alone",
         f"its Z, every fourth turn: {zs(bob, 'z', range(0, 49, 4))} -- up a unit a turn "
         f"to 176 and down again to {bob_low}, where it lands"],
    ]
    scene_items = figures

    return "\n".join([
        '<div class="kl-list">',
        "<p>Everything in a Pentagram room moves the same way: its update routine sets a "
        f"step in U, V and Z (+$09 to +$0B), the collision code cuts the step down to "
        "what fits, and what is left is added to the position. The collision code is "
        f"Knight Lore's -- {kl('Collision', 'its page')} works through it -- with more "
        "done where two things meet in Z. This page is about that, and about the "
        "Pentagram things built on it: lifts, conveyors, blocks that crumble or sink, "
        "pacers and bobbing heads.</p>",

        "<h3>The step, cut to fit</h3>",
        f"<p>{R(0xB979)} takes one off the Z step, for gravity, and calls "
        f"{R(ADJ_FOR_OUT_OF_BOUNDS)}, which takes the three axes one at a time -- Z, then "
        "U, then V -- each against the floor or the walls and then against every other "
        f"record ({R(0xB7E0)}, {R(0xB742)}, {R(0xB791)}): where the box after the step "
        "would overlap another, the step is shortened a unit at a time until it does not. "
        "Each axis is tried with the steps already accepted, so a move blocked along one "
        "axis keeps the part along the others: walking diagonally into a wall slides along "
        "it. A stopped axis sets a bit of +$0C (0 U, 1 V, 2 Z; bit 2 on a move down is "
        "standing on something). A box is centred in U and V, with half-sizes at +$04 and "
        "+$05, and in Z runs up from +$03 by +$06; touching is not overlapping. The walls "
        f"are the room's half-sizes about 128 ({R(0x5E07)}, copied to ROOM_EXTENT), and the "
        "floor is at 128 in every room; there is no ceiling. Where two things meet, harm "
        "passes both ways: +$0D bit 7 kills what the thing moves into, bit 5 what touches "
        "it, and bit 6 is being killed. A thing whose flags have bit 2 set is pushable: "
        "the mover's whole intended step is given to it, and it moves off in its own "
        "update.</p>",
        f"<p>The player's legs come in differently: {R(0xC61D)} takes 2 off his Z step "
        f"(1 while he rises with jump held), cuts it with the same {R(ADJ_FOR_OUT_OF_BOUNDS)} "
        "and adds it. His body is kept out of every test (bit 1 of its flags): the legs' "
        "box, 23 high, is the whole player.</p>",

        "<h3>What Pentagram adds when things meet in Z</h3>",
        f"<p>Knight Lore's Z test only stops the step. Pentagram's ({R(0xB7E0)}) does four "
        "more things when the mover meets something above or below it:</p>",
        "<ul>"
        f"<li><b>The Z hand-off.</b> A mover with bit 2 in its flags -- the player's legs, "
        "and every pushable thing -- gives the obstacle its own intended Z step, and, on "
        "any axis where its own step is zero, takes the obstacle's step in U or V. So what "
        "he lands on feels his weight (that is what makes a sinking block sink and a lift "
        "start), and what he stands on carries him (a pacing block, a lift).</li>"
        f"<li><b>Stood on.</b> {R(0xB890)} sets bit 7 of the obstacle's +$17 when the "
        "mover is the player's legs (graphics 32 to 39) or the heavy block (91), and bit 7 "
        "of the mover's +$17 when the obstacle is his legs. The lift, the bobbers and the "
        "crumbling block read it.</li>"
        f"<li><b>Conveyors.</b> An obstacle of graphic 140 to 143 carries the mover "
        f"({R(0xB866)}): two units along the direction {R(0xD30A)} gives for the graphic "
        "-- 140 +U, 141 -U, 142 +V, 143 -V -- on every other turn (bit 0 of TURNS), and "
        "only the first mover a turn.</li>"
        "<li><b>Met this turn.</b> As in Knight Lore, the obstacle gets bit 3 of +$0D; the "
        "conveyors use it as \"pushed already\" and the crumbling block as \"something "
        "landed\".</li>"
        "</ul>",

        "<h3>The collision code on its own</h3>",
        f"<p>Each row is {R(ADJ_FOR_OUT_OF_BOUNDS)} run in a simulator when this page was "
        "built, on a mover in record 0 and the other objects from record 6 in an "
        "otherwise empty set of records, in a room 64 either way from its middle. Steps "
        "are (U, V, Z). The player's step already has his fall taken off it.</p>",
        table(["Situation", "Step asked", "Step allowed", "And"], collisions),

        "<h3>The things that move</h3>",
        f"<p>The update routines behind Pentagram's moving scenery, by the graphics that "
        f"{R(UPDATES)} gives them and the rooms that place them (read from the room data "
        "when this page was built). The creatures -- spiders, the things from the sky -- "
        'are on <a href="Creatures.html">their own page</a>.</p>',
        table(["Routine", "Graphics", "What it does", "Where"], movers),

        "<h3>Set pieces, run in the game</h3>",
        "<p>Each of these is a real room, entered by the game's own restart in a simulator "
        "when this page was built, with the player then put on top of the object by "
        "writing his position (both his records, just above it) and the game left to run "
        "a turn at a time. Nothing else was touched but his lives, topped up each "
        "turn.</p>",
        table(["Situation", "What happened"], scene_rows),
        *scene_items,

        "<h3>Confirmed and inferred</h3>",
        "<ul>"
        "<li>Run in the simulator when this page was built: every row of both tables, and "
        "the pictures.</li>"
        f"<li>Read from the code: the order of the axes and the rules for walls, floor, "
        "harm and pushing (Knight Lore's, compared line by line); the list of what reads "
        "+$17 bit 7.</li>"
        "<li>Not tried: the lift carrying anything but him; the bobber's three-a-turn rise "
        "with him standing on it, which only the deadly head could show (read from the "
        f"code of {R(0xCE31)}).</li>"
        "</ul>",
        "</div>"])


# --------------------------------------------------------------------------
# 3. Rooms and doorways.
# --------------------------------------------------------------------------

ENTER_ROOM = 0xC6B6
PLAYER_TEMPLATE = 0xC3FF
FIRST_PILLARS = (6, 8)
MARKERS = {"lowU": ("U", 0), "highU": ("U", 0xFF), "highV": ("V", 0xFF), "lowV": ("V", 0)}
OPPOSITE = {"lowU": "highU", "highU": "lowU", "lowV": "highV", "highV": "lowV"}
WALL_NAMES = {"lowU": "low U", "highU": "high U", "lowV": "low V", "highV": "high V"}
EXAMPLE_ROOM = 100          # a start room
EXAMPLE_FROM = (131, 160)   # facing its doorway at high V, three off its middle line
EXAMPLE_WALK = 30           # turns with walk held
EXAMPLE_KILL = 32           # the turn he is killed, by writing the bit a killer sets
EXAMPLE_TURNS = 60


def build_room(base: list, room: int, u: int = 128, v: int = 128):
    """ENTER_ROOM on its own, the player's legs in `room` at U, V: the
    memory afterwards."""
    from skoolkit.simutils import IXh, IXl

    memory = list(base)
    memory[PLAYER + ROOM], memory[PLAYER + 1], memory[PLAYER + 2] = room, u, v
    return call(memory, ENTER_ROOM, {IXh: PLAYER >> 8, IXl: PLAYER & 0xFF}).memory


def arches(memory) -> list[dict]:
    """The first pillars (graphics 6 and 8) among a built room's records: where
    each stands, the wall it is in, the room it leads to and its middle."""
    out = []
    for index in range(6, RECORD_COUNT):
        base = OBJECTS + RECORD * index
        if memory[base] not in FIRST_PILLARS:
            continue
        u, v, z, flags, dest = (memory[base + 1], memory[base + 2], memory[base + 3],
                                memory[base + FLAGS], memory[base + ROOM])
        if flags & 0x40:
            wall, middle = ("highV" if v > 128 else "lowV"), (u - 13, v)
        else:
            wall, middle = ("highU" if u > 128 else "lowU"), (u, v + 13)
        out.append({"record": index, "graphic": memory[base], "u": u, "v": v, "z": z,
                    "wall": wall, "to": dest, "middle": middle})
    return out


def survey_doorways(snapshot: Path, rooms: list[int]) -> dict:
    """Every doorway of every room, followed with the game's own arrival code:
    the marker its exit writes, ENTER_ROOM on the room it leads to, and where
    that puts him -- lined up with which arch, and does it lead back?"""
    game = Game(snapshot)
    base = list(game.memory)
    built = {room: build_room(base, room) for room in rooms}
    found = {room: arches(memory) for room, memory in built.items()}
    sizes = {room: (memory[ROOM_EXTENT], memory[ROOM_EXTENT + 1]) for room, memory in built.items()}
    results = []
    for room in rooms:
        for arch in found[room]:
            axis, marker = MARKERS[arch["wall"]]
            u, v = (marker, arch["middle"][1]) if axis == "U" else (arch["middle"][0], marker)
            after = build_room(base, arch["to"], u, v)
            au, av, az = after[PLAYER + 1], after[PLAYER + 2], after[PLAYER + 3]
            back = None
            for other in found.get(arch["to"], []):
                if other["wall"] != OPPOSITE[arch["wall"]]:
                    continue
                if (axis == "U" and av == other["middle"][1]) or (axis == "V" and au == other["middle"][0]):
                    back = other
            results.append({"from": room, "arch": arch, "arrive": (au, av, az), "back": back})
    return {"arches": found, "sizes": sizes, "doorways": results}


def _doorways_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    from collections import Counter

    R = listing.r
    memory = bp.game_memory(snapshot)
    rooms = bp._rooms(snapshot)

    log("  every doorway, through the game's arrival code...")
    survey = survey_doorways(snapshot, rooms)
    doorways = survey["doorways"]
    back = [d for d in doorways if d["back"] and d["back"]["to"] == d["from"]]
    elsewhere = [d for d in doorways if d["back"] and d["back"]["to"] != d["from"]]
    lost = [d for d in doorways if not d["back"]]
    _check(not elsewhere and not lost,
           f"{len(elsewhere)} doorways lead on elsewhere and {len(lost)} find no arch: the page "
           "says every doorway is two-way")
    size_counts = Counter(survey["sizes"].values())
    kinds = Counter((a["wall"], a["graphic"], a["z"]) for arches_ in survey["arches"].values()
                    for a in arches_)
    geometry = Counter((a["wall"], a["u"] if a["wall"].endswith("U") else a["v"])
                       for arches_ in survey["arches"].values() for a in arches_)

    size_rows = []
    for index in range(3):
        su, sv, floor = pd.room_size(memory, index)
        size_rows.append([index, su, sv, floor, f"{128 - su} to {128 + su}",
                          f"{128 - sv} to {128 + sv}", size_counts.get((su, sv), 0)])

    # A room's record, as the builder reads it.
    record = next(r for r in pd.room_records(memory) if r["number"] == EXAMPLE_ROOM)
    entry_rows = []
    for _, template, destination in record["scenery"]:
        piece = _word(memory, pd.SCENERY_TABLE + 2 * template)
        graphics = []
        while True:
            graphics.append(memory[piece])
            piece += 8
            if memory[piece] == 0:
                break
        entry_rows.append([f'<a href="Scenery.html#scenery{template}">{template}</a>',
                           room_ref(destination, str(destination)) if destination else "",
                           ", ".join(graphic_ref(g) for g in graphics)])
    group_rows = []
    for _, template, count, positions in record["groups"]:
        graphic = memory[_word(memory, pd.OBJECT_TABLE + 2 * template)]
        places = ", ".join(f"({72 + 16 * (p & 7)}, {72 + 16 * (p >> 3 & 7)}, "
                           f"{128 + 12 * (p >> 6)})" for p in positions)
        group_rows.append([f'<a href="Templates.html#object{template}">{template}</a>',
                           graphic_ref(graphic), R(update_routine(memory, graphic)),
                           len(positions), places])

    # Walking out of the example room.
    log(f"  walking out of room {EXAMPLE_ROOM}...")
    game = Game(snapshot)
    game.go(EXAMPLE_ROOM)
    room_picture = pictures.stage("doorways_room.png", screen_image(game.memory),
                                  f"Room {EXAMPLE_ROOM}")
    m = game.memory
    for record_ in (PLAYER, BODY):
        m[record_ + 1], m[record_ + 2] = EXAMPLE_FROM
    m[PLAYER] = 32                      # graphic bit 2 clear, not mirrored: facing +V
    m[PLAYER + FLAGS] &= 0xBF
    game.turns(1)
    walk = []
    screens = {}
    for turn in range(EXAMPLE_TURNS + 1):
        walk.append({"turn": turn, "room": m[PLAYER + ROOM], "u": m[PLAYER + 1],
                     "v": m[PLAYER + 2], "z": m[PLAYER + 3], "flags": m[PLAYER + FLAGS],
                     "bumped": m[PLAYER + BUMPED], "nudge": (_signed(m[PLAYER + 0x0E]),
                                                              _signed(m[PLAYER + 0x0F])),
                     "graphic": m[PLAYER], "killed": bool(m[PLAYER + CONTACT] & 0x40),
                     "template": (m[PLAYER_TEMPLATE + ROOM], m[PLAYER_TEMPLATE + 1],
                                  m[PLAYER_TEMPLATE + 2]),
                     "puff": 64 <= m[PLAYER] <= 71,
                     "lives": m[LIVES]})
        screens[turn] = bytes(m[0x4000:0x5B00])
        if turn < EXAMPLE_TURNS:
            bp._lives(m)
            if turn == EXAMPLE_KILL:
                m[PLAYER + CONTACT] |= 0x40
            game.turns(1, ["a"] if turn < EXAMPLE_WALK else [])
    out_turn = next(w["turn"] for w in walk if w["room"] != EXAMPLE_ROOM)
    new_room = walk[out_turn]["room"]
    exit_arch = next(a for a in survey["arches"][EXAMPLE_ROOM] if a["wall"] == "highV")
    _check(new_room == exit_arch["to"], f"he came out in room {new_room}, not "
                                        f"{exit_arch['to']}")
    _check(walk[out_turn]["template"] == (new_room, walk[out_turn]["u"], 0xFF),
           f"the template after the exit is {walk[out_turn]['template']}")
    doorway_turns = [w["turn"] for w in walk if w["flags"] & 1 and w["room"] == EXAMPLE_ROOM]
    nudged = [w["turn"] for w in walk if w["nudge"] != (0, 0)]
    _check(not any(w["killed"] for w in walk[:EXAMPLE_KILL + 1]),
           "something killed him before the page kills him")
    died = EXAMPLE_KILL + 1
    restart = next((w["turn"] for w in walk if w["turn"] > died and not w["killed"]
                    and w["graphic"] < 64), None)
    _check(restart is not None, "no new life began")
    _check((walk[restart]["u"], walk[restart]["v"]) == (walk[out_turn]["u"], walk[out_turn]["v"])
           and walk[restart]["room"] == new_room,
           "he did not restart in the doorway he came in by")
    walk_in = [w["turn"] for w in walk if out_turn <= w["turn"] < died and w["bumped"] >> 4]

    def crop_strip(turns, name, caption):
        memories = {t: [0] * 0x4000 + list(screens[t]) for t in turns}
        boxes = []
        for t in turns:
            u, v, z = walk[t]["u"], walk[t]["v"], walk[t]["z"]
            x = u + v - 128 - 12
            y = (v - u + 128) // 2 + z - 104 - 6
            boxes.append((x - 8, 191 - (y + 45), x + 40, 191 - y + 6))
        left = max(0, min(b[0] for b in boxes) - 16)
        top = max(0, min(b[1] for b in boxes) - 12)
        right = min(256, max(b[2] for b in boxes) + 16)
        bottom = min(192, max(b[3] for b in boxes) + 12)
        images = [screen_image(memories[t]).crop((left, top, right, bottom)) for t in turns]
        image = strip(images)
        return figure(pictures.piece(name, image, caption, 2 if image.width <= 560 else 1),
                      caption)

    # A screen is kept as each turn begins, showing the turn before; on the
    # first turn in a room that is still the room left, so arrivals are shown
    # a turn on.
    approach = sorted({0, doorway_turns[0], nudged[-1] + 1 if nudged else doorway_turns[0] + 2,
                       out_turn - 1})
    arrive = [out_turn + 1, out_turn + 4, EXAMPLE_WALK]
    puff = next(w["turn"] for w in walk if w["puff"])
    back_again = [puff + 2, restart + 1]
    walk_rows = []
    shown = sorted(set([0, doorway_turns[0] - 1, *doorway_turns, out_turn, *walk_in,
                        walk_in[-1] + 1, EXAMPLE_WALK, died, restart]))
    for t in shown:
        w = walk[t]
        notes = []
        if w["flags"] & 1:
            notes.append("in the doorway: +$07 bit 0")
        if w["nudge"] != (0, 0):
            notes.append(f"nudge {w['nudge'][1]:+d} in V" if w["nudge"][1] else
                         f"nudge {w['nudge'][0]:+d} in U")
        if w["bumped"] >> 4:
            notes.append(f"walks in by himself: {w['bumped'] >> 4} in +$0C")
        if t == died:
            notes.append("killed: bit 6 of +$0D written")
        elif w["puff"]:
            notes.append("the puff")
        if t == restart:
            notes.append("a life later: the template copied back")
        walk_rows.append([t, w["room"], w["u"], w["v"], w["z"],
                          f"{w['template'][0]}, V {w['template'][2]}", "; ".join(notes)])

    arch_rows = []
    for wall in ("lowU", "highU", "lowV", "highV"):
        at = sorted({pos for (w, pos) in geometry if w == wall})
        count = sum(n for (w, _), n in geometry.items() if w == wall)
        heights = sorted({z for (w, _, z) in kinds if w == wall})
        axis, marker = MARKERS[wall]
        arch_rows.append([WALL_NAMES[wall], f"{axis} = {', '.join(map(str, at))}",
                          "no" if axis == "U" else "yes",
                          "15 in U, 6 in V" if axis == "U" else "6 in U, 15 in V",
                          f"{axis} = ${marker:02X}", WALL_NAMES[OPPOSITE[wall]],
                          ", ".join(map(str, heights)), count])

    return "\n".join([
        '<div class="kl-list">',
        "<p>Pentagram's world is 139 rooms joined by arched doorways. A room is built from "
        "a record in the room directory every time he enters it; a doorway is two pillars, "
        "and the first of them decides when he has gone through and where to. This page "
        "follows both, and a real walk from one room to the next, run in the game's own "
        "code.</p>",

        "<h3>Building a room</h3>",
        f"<p>{R(ENTER_ROOM)} clears the screen buffer and calls {R(0xC92C)}, which clears "
        "every object record but the player's two, finds his room in the directory "
        f"({R(pd.ROOMS)}) by stepping from record to record until the number matches, and "
        "fills the records from the top down. Its third byte gives the room's colour and "
        f"one of three sizes from {R(0x5E07)}, copied to ROOM_EXTENT for the walls:</p>",
        table(["Size", "Half-size in U", "Half-size in V", "Floor", "U runs", "V runs",
               "Rooms"], size_rows),
        "<p>Then the scenery: two bytes an entry, a scenery template and one more byte, up "
        f"to an $FF. A scenery template ({R(pd.SCENERY_TABLE)}) is a list of pieces, each "
        "a whole record's first eight bytes -- graphic, U, V, Z, the half-sizes, the flags "
        "-- and every piece of the entry is given the entry's second byte as its +$08, "
        "which for any other object is its room. For a doorway, that byte is the room the "
        "doorway leads to. Then the objects, in groups: a header (the template and how "
        f"many) and a position byte for each copy; an object template ({R(pd.OBJECT_TABLE)}) "
        "gives the graphic, the half-sizes and the flags, and the position byte the cell: "
        "U = 72 + 16 times bits 0-2, V = 72 + 16 times bits 3-5, Z = the floor + 12 times "
        f"bits 6-7. {R(0xB097)} then adds the quest things lying in the room, and "
        f"{R(0xCA82)} puts the player in the doorway he came in by. The record format has "
        'its own page, <a href="RoomStructure.html">room structure</a>.</p>',
        f"<p>{room_ref(EXAMPLE_ROOM, f'Room {EXAMPLE_ROOM}')}, one of the four a game can "
        "start in, read the way the "
        "builder reads it when this page was built. Its scenery:</p>",
        table(["Template", "The byte after it", "Its pieces' graphics"], entry_rows),
        "<p>Its objects (U, V, Z):</p>",
        table(["Template", "Graphic", "Update routine", "Copies", "At"], group_rows),
        figure(room_picture, f"Room {EXAMPLE_ROOM} as the game draws it on entering, in a "
               "simulator when this page was built."),

        "<h3>The arch</h3>",
        "<p>Every doorway is a pair of pillars from a scenery template: a first pillar, "
        "graphic 6 or 8, and a second, 7 or 9, 13 units along the wall. The second only "
        f"sets its drawing offset ({R(0xC789)}). The first ({R(0xC7AD)}) does the "
        "work, every turn: it works out the point in the middle of the arch and keeps it "
        "in its own +$09 to +$0B, the step bytes a pillar never uses; then "
        f"{R(0xC802)} asks, of the player's legs only -- record 0, graphics 16 to 47 (so "
        "not the puff he becomes when he dies), with bit 3 of the flags -- whether he is "
        f"within the doorway's limits of that point ({R(0xC8AD)}). If he is, bit 0 of his "
        "flags is set, which switches off the walls for his next move, and one of four "
        f"routines picked by the way he faces ({R(0xC83B)}) asks whether he is now wholly "
        f"past the wall. Near the arch, {R(0xC8D2)} also sets a nudge of one unit towards "
        f"its middle line in his +$0E or +$0F, which {R(0xC66A)} adds to his step: he "
        "slides into line with the arch as he walks through it.</p>",
        f"<p>The arches in the rooms as built (the first pillars of all "
        f"{sum(len(a) for a in survey['arches'].values())} doorways, read from the object "
        "records after the game's own builder had run for every room):</p>",
        table(["Wall", "First pillar at", "Mirrored", "Doorway reaches", "Leaving writes",
               "He arrives at", "Pillar heights (Z)", "Doorways"], arch_rows),
        f"<p>Every first pillar stands at 59 or 197, just outside a wall at 64 or 192. "
        f"The {sum(n for s, n in size_counts.items() if s != (64, 64))} narrow rooms have "
        "theirs only at the two ends of their long axis, where the walls are at 64 and 192, "
        "never in the walls at 96 or 160 -- which matters, because the arrival code below "
        "only looks for an arch at U or V of 192 or more, or below 64.</p>",

        "<h3>Going through</h3>",
        f"<p>The four exit routines ({R(0xC843)}, {R(0xC874)}, {R(0xC887)}, "
        f"{R(0xC89A)}) compare his position after this turn's move with the wall he "
        "faces: out at low U when his far edge (U plus his half-size) is below the wall, at "
        "high U when his near edge is at or beyond it, and the same for V. Then "
        f"{R(0xC854)}: his room becomes the pillar's +$08; the coordinate he left by is set "
        "to a marker, 0 or $FF, which is not a position but a note of the wall; the top "
        "four bits of +$0C are set to 3, three turns in which he walks on by himself; both "
        "his records are copied over the player template at "
        f"{R(PLAYER_TEMPLATE)}; and two return addresses are dropped from the stack by hand "
        f"and the game jumps to {R(0xAFC8)} to build the new room.</p>",
        f"<p>There, {R(0xCA82)} sees the marker and puts him in the doorway of the "
        "opposite wall: the coordinate becomes 128 plus or minus (the room's half-size - 2 "
        f"+ his half-size), his inner edge two units inside the wall, and {R(0xCAEE)} lines "
        "him up with the arch in that wall -- the middle of it along the wall, and its "
        "pillar's Z -- by looking at the first pillars of the room's first four scenery "
        "entries. The code takes doorways to be a room's first scenery entries.</p>",
        f"<p>Knight Lore has the same arches, the same switching off of the walls "
        f"({kl('Collision', 'its collision page')}) and the same markers, but its player's "
        "own move decides the exit, from his position plus the step, and the next room is "
        "his room number plus or minus 1 or 16: its castle is a grid "
        f"({kl('RoomStructure', 'its map')}). In Pentagram the move leaves it "
        f"alone ({R(0xC6B5)} is a bare RET where Knight Lore's check was called), the pillar "
        "decides from where he is after the move, and the next room is whatever the "
        "pillar carries: the rooms are not on a grid at all.</p>",

        "<h3>A walk from one room to the next</h3>",
        f"<p>In a simulator when this page was built: a game started, {room_ref(EXAMPLE_ROOM)} "
        "entered by the game's own restart, and the player then put at U "
        f"{EXAMPLE_FROM[0]}, V {EXAMPLE_FROM[1]} facing +V -- his graphic made 32 and his "
        "flags not mirrored, which is how the game stores that facing -- three units off "
        f"the middle line of the arch in the wall at high V. Then walk (A) held for "
        f"{EXAMPLE_WALK} turns; nothing else touched but his lives, topped up each turn, "
        f"until on turn {EXAMPLE_KILL} he was killed by writing bit 6 of his +$0D, as "
        "anything deadly does:</p>",
        table(["Turn", "Room", "U", "V", "Z", "Template: room, V", "What is going on"],
              walk_rows),
        f"<p>He is in the doorway from turn {doorway_turns[0]}, and the arch nudges him "
        f"back onto its middle line, U 128, a unit a turn. On turn {out_turn} he is in "
        f"{room_ref(new_room)}, at V {walk[out_turn]['v']}: his inner edge two units inside that "
        f"room's wall at 64. The template now says room {new_room} with V $FF, the marker, "
        "not a position. He walks in for three turns by himself, and on under the key. "
        "Killed, he becomes a puff; when it is over both his records are empty, the main "
        "loop starts a life, and the life starts from the template: the same room, the "
        "marker again, and so the same arrival code puts him back in the doorway he came "
        f"in by, at U {walk[restart]['u']}, V {walk[restart]['v']}, on turn {restart}.</p>",
        crop_strip(approach, "doorways_out.png",
                   f"Room {EXAMPLE_ROOM}, turns {', '.join(map(str, approach))}: walking to "
                   "the arch, and sliding onto its middle line."),
        crop_strip(arrive, "doorways_in.png",
                   f"Room {new_room}, as turns {', '.join(map(str, arrive))} begin: coming "
                   "in, and walking on."),
        crop_strip(back_again, "doorways_restart.png",
                   f"Room {new_room}, as turns {back_again[0]} and {back_again[1]} begin: "
                   "the puff, and a life later back in the doorway."),

        "<h3>Every doorway, followed</h3>",
        f"<p>For each of the {len(doorways)} doorways, the marker its exit writes was put in "
        f"the player's record with the room it leads to, and {R(ENTER_ROOM)} run on its "
        "own; then his position was compared with the arches of the room he arrived in. "
        f"{len(back)} put him on the middle line of an arch in the opposite wall that "
        f"leads straight back; {len(elsewhere)} on an arch leading somewhere else; and "
        f"{len(lost)} found no arch at all in that wall. So every doorway in the game is "
        "two-way, and the arrival code's own limits -- the first four scenery entries, the "
        "fixed 64 and 192 -- never come into play.</p>",

        "<h3>Confirmed and inferred</h3>",
        "<ul>"
        "<li>Run in the simulator when this page was built: the walk and the restart, the "
        "arches of every room as the builder makes them, and every doorway's arrival.</li>"
        "<li>Read from the code: the exit tests and the markers (the walk shows the high-V "
        "one; the other three are the same code about the other walls); the builder's "
        "reading of the record; the comparison with Knight Lore.</li>"
        "</ul>",
        "</div>"])


# --------------------------------------------------------------------------
# 4. The well, the bucket and the pentagram.
# --------------------------------------------------------------------------

WELL = 120
BUCKET = 90
QUEST_ITEMS = range(112, 116)
PIECES = range(128, 136)
WON = 0xC302
WON_SHOWN = 0xC31D          # the winning screen printed and shown; the tune next
OVER_SHOWN = 0xC347         # the game-over screen shown; its tune next
PERCENTAGE = 0xC6EA
RESET_DROP_TIMER = 0xCC31
QUEST_DONE = 0xA74C
PLACED = 0xA74B
PERCENT = 0xA74D
ROOMS_SEEN = 0xA74F
DROP_TIMER = 0xA73D
KINDS = ["quest item"] * 4 + ["collectable"] * 5 + ["piece of the pentagram"] * 8 + ["the bucket"]


def sprite_of(memory, graphic: int):
    """A graphic's sprite, drawn from its bytes as the listing's sprite
    pictures are (build_pentagram.sprite_image), at its own size."""
    return bp.sprite_image(memory, _word(memory, pd.GRAPHICS + 2 * graphic), scale=1)


class QuestRun:
    """The whole quest played in the simulator the way the build's staged
    session plays it (build_pentagram._quest and _quest_item), with the
    screen and the state kept at the moments the page shows."""

    def __init__(self, snapshot: Path, log):
        self.game = Game(snapshot)
        self.shots = []             # (volley, shot, the well's count, bucket out)
        self.frames = {}            # name -> (screen bytes, a note)
        self.flight = []            # the bucket in room 122, a sample every 0.2 s
        self.glide = []
        self.log = log

    def keep(self, name, note=""):
        def step(memory):
            self.frames[name] = (bytes(memory[0x4000:0x5B00]), note)
        return step

    def well_count(self, memory) -> int | None:
        for index in range(6, RECORD_COUNT):
            base = OBJECTS + RECORD * index
            if memory[base] == WELL:
                return memory[base + 0x14]
        return None

    def shot(self, volley, number):
        def step(memory):
            self.shots.append((volley, number, self.well_count(memory),
                               memory[bp.BUCKET_OUT], _word(memory, TURNS)))
        return step

    def bucket_sample(self, memory):
        record = None
        for index in range(6, RECORD_COUNT):
            base = OBJECTS + RECORD * index
            if memory[base] in (BUCKET, *range(64, 72)):
                record = base
        item = next((OBJECTS + RECORD * i for i in range(6, RECORD_COUNT)
                     if memory[OBJECTS + RECORD * i] in range(112, 120)), None)
        self.flight.append({"turn": _word(memory, TURNS),
                            "bucket": tuple(memory[record:record + 4]) if record else None,
                            "item": tuple(memory[item:item + 4]) if item else None,
                            "rects": [tuple(memory[b + 0x18:b + 0x1C]) for b in (record, item)
                                      if b],
                            "done": memory[QUEST_DONE], "lives": memory[LIVES],
                            "screen": bytes(memory[0x4000:0x5B00])})

    def item(self, room: int, done: int, record: bool) -> None:
        volleys = []
        for volley in range(8):
            steps = []
            for number in range(12):
                steps += [bp._lives, (["w"], 0.15), ([], 0.25)]
                if record:
                    steps.append(self.shot(volley, number))
                    if volley == 0 and number == 2:
                        steps.append(self.keep("firing", "firing at the well"))
            steps += [(["z"], 0.15), ([], 0.3)]
            volleys.append(steps)
        self.game.play(bp._go(bp.WELL_ROOM) + [([], 1.0), bp._place(*bp.WELL_SPOT), ([], 0.5)])
        if record:
            memory = self.game.memory
            well = next(OBJECTS + RECORD * i for i in range(6, RECORD_COUNT)
                        if memory[OBJECTS + RECORD * i] == WELL)
            width, height, x, y = memory[well + 0x18:well + 0x1C]
            self.well_box = (max(0, x - 48), max(0, 191 - (y + height) - 40),
                             min(256, x + 8 * width + 48), min(192, 192 - y + 24))
        for steps in volleys:
            self.game.play(steps)
            if self.game.memory[bp.BUCKET_OUT]:
                break
        _check(self.game.memory[bp.BUCKET_OUT], "the well gave no bucket in eight volleys")
        if record:
            self.game.play([([], 0.3), self.keep("bucket", "the bucket, just out")])
        self.game.play([([], 2.0), bp._beside_bucket, ([], 0.5),
                        bp.Repeat("the bucket carried, next to put down",
                                  [bp._lives, (["1"], 0.2), ([], 0.8)],
                                  lambda memory: memory[bp.CARRIED + 12] == BUCKET, 6)])
        self.game.play(bp._go(room) + [([], 1.0)])
        if record:
            self.game.play([self.keep("item_before", f"room {room}, before")])
        self.game.play([bp.Repeat("the bucket put down", [bp._lives, (["1"], 0.2), ([], 0.8)],
                                  lambda memory: memory[bp.CARRIED + 12] == 0, 3)])
        for _ in range(200):
            if record:
                self.bucket_sample(self.game.memory)
            if self.game.memory[QUEST_DONE] == done:
                break
            bp._lives(self.game.memory)
            self.game.turns(1)
        _check(self.game.memory[QUEST_DONE] == done, f"quest item {done} was never done")
        if record:
            for _ in range(10):
                self.game.turns(1)
                self.bucket_sample(self.game.memory)

    def run(self) -> None:
        memory = self.game.memory
        self.game.play(bp._go(bp.ROOM_PENTAGRAM) + [([], 1.0),
                                                   self.keep("room82_before", "room 82")])
        for done, room in enumerate(bp.QUEST_ROOMS, 1):
            self.log(f"    quest item {done}, in room {room}...")
            self.item(room, done, done == 1)
        _check(memory[bp.PENTAGRAM_ON] == 1, "the pentagram did not appear")
        self.game.play(bp._go(bp.ROOM_PENTAGRAM) + [([], 1.5),
                                                   self.keep("room82_after", "room 82")])
        self.log("    the collectables, in room 82...")
        self.game.play([bp._collectables_in_room_82] + bp._go(bp.ROOM_PENTAGRAM))
        start = _word(memory, TURNS)
        # Several can arrive on the same turn, and the fifth jumps to WON from
        # inside the round of updates; so the turn-by-turn watch stops the
        # turn before any collectable is a unit from its place, and the rest
        # is run to WON.
        def closest():
            out = 255
            for index in range(6, RECORD_COUNT):
                base = OBJECTS + RECORD * index
                if 144 <= memory[base] <= 148:
                    target = pd.TARGETS + 2 * (memory[base] & 7)
                    out = min(out, max(abs(memory[base + 1] - memory[target]),
                                       abs(memory[base + 2] - memory[target + 1])))
            return out

        for _ in range(400):
            if memory[PLACED] >= 3 or closest() <= 1:
                break
            if (_word(memory, TURNS) - start) % 4 == 0:
                self.glide.append({"turn": _word(memory, TURNS) - start,
                                   "placed": memory[PLACED],
                                   "screen": bytes(memory[0x4000:0x5B00])})
            bp._lives(memory)
            self.game.turns(1)
        self.placed_before = memory[PLACED]
        turn_before = _word(memory, TURNS)
        self.game.run_to(WON, 20.0)
        self.placed_turn = _word(memory, TURNS) - start
        self.won_turns = _word(memory, TURNS) - turn_before
        self.won_placed = memory[PLACED]
        self.game.run_to(WON_SHOWN, 10.0)
        self.frames["won"] = (bytes(memory[0x4000:0x5B00]), "the winning screen")
        self.game.run_to(OVER_SHOWN, 60.0)
        self.frames["over"] = (bytes(memory[0x4000:0x5B00]), "the game-over screen")
        self.percent = (memory[PERCENT], memory[PERCENT + 1])
        self.seen = sum(bin(memory[ROOMS_SEEN + i]).count("1") for i in range(31))
        self.done_at_end = memory[QUEST_DONE]


def percentage(memory, rooms: int, done: int, placed: int) -> str:
    """PERCENTAGE run on its own with so many rooms seen, quest items done and
    collectables placed: the number it leaves in PERCENT, as printed."""
    memory = list(memory)
    memory[ROOMS_SEEN:ROOMS_SEEN + 31] = [0] * 31
    for room in range(rooms):
        memory[ROOMS_SEEN + room // 8] |= 0x80 >> (room % 8)
    memory[QUEST_DONE], memory[PLACED] = done, placed
    after = call(memory, PERCENTAGE, {}, 5.0).memory
    hundreds, rest = after[PERCENT], after[PERCENT + 1]
    return f"{hundreds:X}{rest:02X}" if hundreds else f"{rest:02X}"


def drop_timer(memory, done: list[int]) -> int:
    """RESET_DROP_TIMER run on its own, the quest records as a game starts
    with the items in `done` finished (graphic + 4, as QUEST_ITEM does)."""
    memory = list(memory)
    size = pd.QUEST_COUNT * pd.QUEST_SIZE
    memory[bp.QUEST_RECORDS:bp.QUEST_RECORDS + size] = memory[pd.QUEST_START:pd.QUEST_START + size]
    for item in done:
        memory[bp.QUEST_RECORDS + pd.QUEST_SIZE * item] += 4
    return call(memory, RESET_DROP_TIMER, {}).memory[DROP_TIMER]


def _quest_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    R = listing.r
    memory = bp.game_memory(snapshot)

    # The records, as a game starts.
    sprite_names = {}

    def sprite(graphic):
        if graphic not in sprite_names:
            image = sprite_of(memory, graphic)
            sprite_names[graphic] = pictures.piece(f"quest_graphic{graphic}.png", image,
                                                   f"Graphic {graphic}", 2, "pg-sprite")
        return sprite_names[graphic]

    record_rows = []
    for number in range(pd.QUEST_COUNT):
        base = pd.QUEST_START + pd.QUEST_SIZE * number
        graphic, u, v, z, su, sv, sz, flags, room = memory[base:base + 9]
        later = {"quest item": graphic + 4, "collectable": graphic + 8}.get(KINDS[number])
        if graphic:
            where = f"{room_ref(room)} at ({u}, {v}, {z})" if KINDS[number] != "collectable" else \
                    "placed at random at each new game (below)"
            pictures_ = sprite(graphic) + (" &rarr; " + sprite(later) if later else "")
            record_rows.append([number, KINDS[number], graphic_ref(graphic) + (
                                    f" &rarr; {graphic_ref(later)}" if later else ""),
                                pictures_, where])
        else:
            record_rows.append([number, KINDS[number], "0 until the well gives one", "", ""])
    spot_rows = []
    for number in range(pd.SPOT_COUNT):
        room, u, v, z = memory[pd.SPOTS + 4 * number:pd.SPOTS + 4 * number + 4]
        spot_rows.append([number, room_ref(room, str(room)), u, v, z,
                          "first or later" if number < 16 else "only as a later one"])
    target_rows = []
    for index in range(pd.TARGET_COUNT):
        u, v = memory[pd.TARGETS + 2 * index], memory[pd.TARGETS + 2 * index + 1]
        target_rows.append([graphic_ref(144 + index), sprite(144 + index), u, v,
                            graphic_ref(152 + index)])

    log("  the whole quest, as the build's staged session plays it...")
    run = QuestRun(snapshot, log)
    run.run()

    # The well.
    counts = [s for s in run.shots if s[2] is not None]
    out_at = next(i for i, s in enumerate(run.shots) if s[3])
    last_count = run.shots[out_at - 1][2] if out_at else None
    volley_rows = []
    for volley in sorted({s[0] for s in run.shots}):
        shots = [s for s in run.shots if s[0] == volley]
        before = [s[2] for s in shots if not s[3]]
        volley_rows.append([volley + 1, ", ".join(str(c) for c in before) or "-",
                            "yes" if shots[-1][3] else "no", shots[-1][4] - shots[0][4]])
    _check(last_count is not None and 20 <= last_count < 32 and run.shots[out_at][2] < last_count,
           f"the well's count before the bucket was {last_count}")
    gains = [b[2] - a[2] for a, b in zip(run.shots, run.shots[1:out_at]) if b[2] > a[2]]

    def screen(name):
        return screen_image([0] * 0x4000 + list(run.frames[name][0]))

    well_fig = pictures.strip("quest_well.png", [screen("firing").crop(run.well_box),
                                                 screen("bucket").crop(run.well_box)],
                              "Firing at the well, and the bucket")

    # The bucket's flight, room 122.
    flight = run.flight
    first_up = next(i for i, f in enumerate(flight) if f["bucket"])
    done_at = next(i for i, f in enumerate(flight) if f["done"])
    top_at = next(i for i, f in enumerate(flight) if f["bucket"] and f["bucket"][3] >= 176)
    _check(all(flight[i]["bucket"][3] == flight[i - 1]["bucket"][3] + 1
               for i in range(first_up + 2, top_at + 1)), "the bucket did not rise a unit a turn")
    picks = sorted({first_up, (first_up + top_at) // 2, top_at, done_at, done_at + 3,
                    len(flight) - 1})
    boxes = []
    for i in picks:
        for width, height, x, y in flight[i]["rects"]:
            if width and height:
                boxes.append((x, 191 - (y + height), x + 8 * width, 192 - y))
    fbox = (max(0, min(b[0] for b in boxes) - 12), max(0, min(b[1] for b in boxes) - 12),
            min(256, max(b[2] for b in boxes) + 12), min(192, max(b[3] for b in boxes) + 12))
    flight_fig = pictures.strip("quest_bucket.png",
                                [screen_image([0] * 0x4000 + list(flight[i]["screen"])).crop(fbox)
                                 for i in picks], "The bucket flying to the quest item")
    flight_rows = []
    for i in sorted(set(picks) | set(range(first_up, top_at, 8))):
        f = flight[i]
        bucket = f["bucket"]
        what = ("the bucket" if bucket and bucket[0] == BUCKET else
                "a puff" if bucket else "gone")
        flight_rows.append([f["turn"] - flight[0]["turn"],
                            f"{what}" + (f" at ({bucket[1]}, {bucket[2]}, {bucket[3]})"
                                         if bucket else ""),
                            f"graphic {f['item'][0]}" if f["item"] else "",
                            f["done"], f"{f['lives']:X}"])
    before_lives = flight[0]["lives"]
    after_lives = flight[-1]["lives"]

    rooms82 = [screen("room82_before").crop((40, 0, 216, 150)),
               screen("room82_after").crop((40, 0, 216, 150))]
    room82_fig = pictures.strip("quest_room82.png", rooms82,
                                "Room 82 before the quest items are done, and after")
    glide_picks = [0, len(run.glide) // 3, 2 * len(run.glide) // 3, len(run.glide) - 1]
    glide_images = [screen_image([0] * 0x4000 + list(run.glide[i]["screen"])).crop((40, 0, 216, 150))
                    for i in glide_picks]
    glide_images = [glide_images[0], glide_images[len(glide_images) // 2], glide_images[-1]]
    glide_fig = pictures.strip("quest_glide.png", glide_images,
                               "The collectables gliding to their places")
    won_fig = (pictures.stage("quest_won.png", screen("won"), "The winning screen") + " "
               + pictures.stage("quest_over.png", screen("over"), "The game-over screen"))
    _check(run.won_placed == 5 and run.won_turns <= 1, "the collectables did not settle together")
    printed = f"{run.percent[0]:X}{run.percent[1]:02X}" if run.percent[0] else f"{run.percent[1]:02X}"
    expected_percent = min(run.seen // 2, 54) + 4 * run.done_at_end + 6 * 5
    _check(int(printed) == expected_percent,
           f"the game printed {printed}%, the formula gives {expected_percent}")

    # The percentage and the drop timer, run on their own.
    percent_cases = [(0, 0, 0), (1, 0, 0), (2, 0, 0), (3, 0, 0), (20, 1, 1), (60, 2, 0),
                     (107, 4, 5), (108, 4, 5), (139, 4, 5)]
    percent_rows = []
    for rooms, done, placed in percent_cases:
        got = percentage(memory, rooms, done, placed)
        sum_ = min(rooms // 2, 54) + 4 * done + 6 * placed
        percent_rows.append([rooms, done, placed, sum_, got])
    _check(percent_rows[0][4] == "56", "no rooms, no quest: not 56%")
    timer_cases = [[], [0], [1], [1, 2, 3], [0, 1], [0, 1, 2, 3]]
    timer_rows = []
    for done in timer_cases:
        meant = 4 * (2 + 4 - len(done))
        got = drop_timer(memory, done)
        timer_rows.append([", ".join(str(d + 1) for d in done) or "none", meant, got])
    _check([r[2] for r in timer_rows] == [80, 8, 80, 80, 8, 8], "the drop timer changed")

    sprites_row = " ".join(sprite(g) for g in (WELL, BUCKET, 112, 116))

    return "\n".join([
        '<div class="kl-list">',
        "<p>Pentagram's quest is a chain, each link an update routine acting on the next "
        "thing: shoot the well until it gives a bucket; carry the bucket to each of four "
        "rough stones, where it flies to the stone and finishes it; with all four finished "
        "the pentagram appears in room 82; bring the five collectables there, and each "
        "glides to its place on it; the fifth ends the game. This page follows the chain "
        "through the code, and then through the game itself, played in a simulator the "
        "way the build plays it.</p>",
        f"<p>{sprites_row}</p>",
        "<ul>"
        f"<li>{R(0xCFD2)}, the well (graphic {WELL}), counts the turns a bolt touches it; on "
        "the 32nd it makes the bucket.</li>"
        f"<li>{R(0xD0AC)}, the bucket (graphic {BUCKET}), falls and waits to be carried; put "
        "down in a room with a stone still rough, it rises to Z 176 and steers over the "
        "stone, and when it can move no more tells the stone and turns into a puff.</li>"
        f"<li>{R(0xCF68)}, a quest item (112 to 115), when told: one more QUEST_DONE, a "
        f"life added, its graphic up by 4 (116 to 119, finished) through {R(0xCF9E)}, and "
        f"{R(0xD13A)}, which with all four finished sets PENTAGRAM_ON.</li>"
        f"<li>{R(0xB097)} brings the pentagram's eight pieces (128 to 135) into room 82 "
        f"once PENTAGRAM_ON is set, and {R(0xCD16)}, a collectable (144 to 148), in room 82 "
        "with the pentagram showing, glides to its place; there its graphic goes up by 8, "
        f"PLACED counts it, and the fifth jumps to {R(WON)}.</li>"
        "</ul>",

        "<h3>The quest's things</h3>",
        f"<p>None of these is in the room data. They live in 18 records of 16 bytes at "
        f"{R(bp.QUEST_RECORDS)} -- an object record's first half, with its room at +8 -- "
        f"copied from {R(pd.QUEST_START)} at every new game by {R(0xD16F)}. "
        f"{R(0xB115)} copies each one in the room being left back to its record, by "
        f"graphic, and {R(0xB097)} copies those in the room being entered into free object "
        "records, so a thing stays wherever it was left. The records as a game starts:</p>",
        table(["Record", "What", "Graphic", "Its sprite", "Where"], record_rows),
        f"<p>The block holds 19 records' worth, 304 bytes; the last nothing reads or "
        "writes. The collectables start at five neighbouring places of the twenty at "
        f"{R(pd.SPOTS)}, the first picked by the random number (AND $3C, so one of the "
        "first sixteen):</p>",
        table(["Place", "Room", "U", "V", "Z", "Used"], spot_rows),

        "<h3>The well</h3>",
        f"<p>Every turn, {R(0xCFD2)} asks {R(0xCFB2)} whether a bolt is within two units of "
        f"it, with the bolts' own hit test ({R(0xC206)}), and if one is adds one to a count "
        "in its +$14. On the 32nd it makes the bucket: a copy of its own record, graphic "
        f"{BUCKET}, at the well's U and 8 further in V, 141 up, and BUCKET_OUT set -- none "
        "while a bucket is out, or in the room, or with no free record. The count lives in "
        "the well's own record, and the room builder makes that afresh every time the room "
        "is entered, so the 32 must all come in one visit. A bolt touches the well for "
        "several turns as it goes by and puffs against it, so it takes a volley aimed "
        "the right way, not 32 shots. The two bolt records are not tested alike: the first "
        f"is taken into {R(0xC206)}'s test past its check for a puff, so its puff goes on "
        "counting as touching; the second's does not.</p>",
        f"<p>Played in room {bp.WELL_ROOM} (a well with no monsters), standing at "
        f"({bp.WELL_SPOT[0]}, {bp.WELL_SPOT[1]}) inside its ring of hazards, firing twelve "
        "times a volley and turning a quarter between volleys, as the build's session "
        "does. The well's count and the bucket, volley by volley:</p>",
        table(["Volley", "The count after each shot, until the bucket", "Bucket out",
               "Turns it took"], volley_rows),
        f"<p>Each shot that reached the well added {min(gains)} to {max(gains)} turns "
        f"of contact; the count stood at {last_count} at the last shot before the bucket, "
        "and on the turn it reached 32 the bucket came and the count went back to 0. The "
        "volleys that added nothing were fired while he faced away from it.</p>",
        figure(well_fig, "Firing at the well, and the bucket just out. Pictures from the "
               "game's own screen in the simulator."),

        "<h3>The bucket</h3>",
        f"<p>Carried (the pick-up key, {R(0xBF79)}), the bucket goes in the carried slots; "
        "put down, it is an object again. Each turn, until it has a target, it falls a "
        "unit and looks for a stone not yet finished (graphics 112 to 115) among the "
        "room's records; found, it takes the stone's U and V as its target, and from then "
        f"on rises a unit a turn up to Z 176 while {R(0xD085)} steers it a unit a turn "
        "towards the target, without falling. When it can move no more -- over the stone "
        "at the top of its rise -- it sets bit 0 of the stone's +$16, clears BUCKET_OUT so "
        'the well may give another, plays <a href="Sounds.html">the quest tune</a>, empties '
        "its own quest record and "
        "turns into a puff. The stone, on its next update, is finished.</p>",
        f"<p>Room {bp.QUEST_ROOMS[0]}, from the moment the bucket is put down, turn by "
        "turn (some of the turns):</p>",
        table(["Turns after", "The bucket", "The stone", "QUEST_DONE", "Lives"],
              flight_rows),
        figure(flight_fig, "The bucket put down, rising and flying to the stone, over it, "
               f"the puff, and the finished pillar (turns "
               f"{', '.join(str(flight[i]['turn'] - flight[0]['turn']) for i in picks)}). "
               f"Lives went from {before_lives:X} to {after_lives:X}: a quest item gives a "
               "life. Each picture is the screen as a turn began."),
        f"<p>It rose a unit a turn from Z {flight[first_up]['bucket'][3]} to 176 while it "
        f"steered, and was over the stone {flight[top_at]['turn'] - flight[0]['turn']} "
        "turns after it was put down.</p>",

        "<h3>The pentagram</h3>",
        f"<p>With the fourth stone finished, {R(0xD13A)} finds all four quest records at "
        "116 to 119, and sets PENTAGRAM_ON. The pieces' quest records have been in room 82 "
        f"all along; {R(0xB097)} simply leaves them out until then. From then on nothing "
        "falls from the sky in room 82 either, since the pieces are among what bans a drop "
        f"there ({R(0xCB89)}).</p>",
        figure(room82_fig, "Room 82 as the game drew it at the start of this run, and "
               "after the fourth quest item."),
        f"<p>A collectable is otherwise an ordinary thing that falls and can be pushed or "
        f"carried. In room 82 with the pentagram showing, {R(0xCD16)} takes its place from "
        f"{R(pd.TARGETS)} by the low three bits of its graphic and glides there a unit a "
        "turn in U and in V, without falling:</p>",
        table(["Graphic", "Sprite", "U", "V", "Becomes"], target_rows),
        f"<p>The build's session stages this last part: the five collectables are put on "
        "the floor of room 82, sixteen units short of their places, and the room entered "
        "again. Being the same distance from their places, they arrived together: PLACED "
        f"went from {run.placed_before} to {run.won_placed} within one round of updates, "
        "the fifth jumping to the win from inside it.</p>",
        figure(glide_fig, "The collectables gliding to their places on the pentagram."),

        "<h3>Winning</h3>",
        f"<p>When PLACED reaches 5, {R(0xCD16)} jumps straight to {R(WON)}, from inside "
        "the main loop's round of updates: the buffer cleared, the screen's colours bright "
        "cyan, six lines of text each in its own colour (CONGRATULATIONS... YOUR ADVENTURE "
        f"CONTINUES IN MIRE MARE, from {R(0xC38B)}), the border, the screen shown, "
        f"<a href=\"Sounds.html\">the winning tune</a>. Then it runs on "
        f"into the game-over screen, {R(0xC323)}, with the percentage, and "
        "after about four seconds back to the menu. Winning is a game over with a "
        "different first screen.</p>",
        figure(won_fig, "The two screens as the game showed them at the end of this run: "
               f"it printed {printed} per cent."),

        "<h3>The percentage</h3>",
        f"<p>{R(PERCENTAGE)} adds three things: the rooms seen (a bit each in the 31 bytes "
        f"at ROOMS_SEEN, set by {R(0xC6CC)} as each is built) halved, up to 54; 4 for each "
        "quest item done, 16 in all; 6 for each collectable placed, 30 in all. 54, 16 and "
        "30 make 100. The sum is turned into BCD by counting: a DJNZ loop adding 1 with "
        "DAA, B times. With B = 0 a DJNZ loop runs 256 times, and 256 counted in BCD "
        "leaves 56 in the last two digits. So a player who has seen no more than one room "
        "and done nothing else is told 56 per cent -- anyone who loses all five lives in "
        "the room they started in (one of <a href=\"reference/bugs.html\">the bugs</a>). "
        "Run on its own for a few sums:</p>",
        table(["Rooms seen", "Quest items", "Collectables", "The sum", "Printed"],
              percent_rows),
        f"<p>This run printed {printed}: it had seen {run.seen} rooms "
        f"({min(run.seen // 2, 54)}), done {run.done_at_end} quest items and placed 5 "
        "collectables. The staged session reaches rooms by restarting in them, not by "
        "walking, which is why it has seen so few.</p>",

        "<h3>The drop timer</h3>",
        f"<p>Things fall from the sky (see <a href=\"Creatures.html\">the creatures</a>) "
        f"when DROP_TIMER runs out. {R(RESET_DROP_TIMER)}, run at every room's start and "
        "after every drop, is written to count the quest items still to do and allow four "
        "turns for each, plus eight: 24 turns with all four to do, down to 8. But it "
        "loads the record length into DE and never adds it to HL, so it tests the first "
        "record eighteen times: the answer is 80 while the first quest item is to do, and "
        "8 once it is done, whatever the others are (another of "
        '<a href="reference/bugs.html">the bugs</a>). Run on its own:</p>',
        table(["Quest items done (1 is room 122's)", "Meant", "Set"], timer_rows),

        "<h3>Confirmed and inferred</h3>",
        "<ul>"
        "<li>Played in the simulator when this page was built: the whole quest and the "
        "ending, staged as the build's session stages it -- the player put beside the well "
        "and the bucket, restarts to change rooms, the collectables put near their places "
        "-- and everything else the game's own doing. The well's count, the bucket's "
        "flight, the extra life, the pentagram, the glide, the two screens and the "
        "percentage are from that run.</li>"
        "<li>Run on their own: the percentage and the drop timer tables.</li>"
        "<li>Read from the code: that the well's count is lost with the room; that a "
        "bucket stuck short of its stone, unable to move, finishes the stone all the same; "
        "the record layout.</li>"
        "<li>Not played: the quest by walking, room to room, in the original.</li>"
        "</ul>",
        "</div>"])


# --------------------------------------------------------------------------
# 5. Bolts, things from the sky and the monsters.
# --------------------------------------------------------------------------

FIRE = 0xC126
BOLT = 0xC1C5
BOLT_STEPS = 0xC1BD
SHOOT_DOWN = 0xC264
MAKE_DEADLY = 0xC291
SKY_DROP = 0xCBAB
DROP_GRAPHICS = 0xCC09
FLYER_TEMPLATE = 0xCC11
SCORE = 0xA744
FACINGS = {0: (32, 0x40, "-U"), 1: (36, 0x40, "+U"), 2: (32, 0, "+V"), 3: (36, 0, "-V")}
DROP_TEST = 0xCBB7          # in SKY_DROP: the random number read for the one-in-four
STILL_TURNS = 150
RANDOM = 0xA70D


def face(game: Game, facing: int) -> None:
    """Turn the player the way the game stores a facing: bit 2 of the legs'
    graphic and the mirror bit of the flags (GET_SPRITE_DIR)."""
    graphic, mirror, _ = FACINGS[facing]
    memory = game.memory
    memory[PLAYER] = graphic
    memory[PLAYER + FLAGS] = (memory[PLAYER + FLAGS] & 0xBF) | mirror


def _bcd(memory, address: int) -> int:
    return int("".join(f"{memory[address + i]:02X}" for i in range(3)))


def score_for(memory, graphic: int) -> int:
    """SHOOT_DOWN run on its own on a thing of this graphic: the points it
    adds to a score of 0."""
    from skoolkit.simutils import IXh, IXl, IYh, IYl

    memory = list(memory)
    memory[SCORE:SCORE + 3] = [0, 0, 0]
    memory[OBJECTS:UPDATES] = [0] * (UPDATES - OBJECTS)
    memory[BOLTS:BOLTS + RECORD] = [150, 128, 128, 132, 5, 5, 8, 0x14] + [0] * 24
    memory[FLYERS:FLYERS + RECORD] = [graphic, 128, 128, 132, 8, 8, 8, 0x10] + [0] * 24
    after = call(memory, SHOOT_DOWN, {IXh: BOLTS >> 8, IXl: BOLTS & 0xFF,
                                      IYh: FLYERS >> 8, IYl: FLYERS & 0xFF}).memory
    return _bcd(after, SCORE)


def score_by_bits(graphic: int) -> int:
    """The points as the page describes them: hundreds from bits 5-7, tens
    from bits 2-4, units from bits 6, 7 and 0."""
    hundreds = graphic >> 5 & 7
    tens = graphic >> 2 & 7
    units = (graphic >> 6 & 1) | (graphic >> 7 & 1) << 1 | (graphic & 1) << 2
    return 100 * hundreds + 10 * tens + units


class Watch:
    """A room in the simulator with the player, the bolts and the things from
    the sky logged every turn, and the screen kept."""

    def __init__(self, snapshot: Path, room: int):
        self.game = Game(snapshot)
        self.game.go(room)
        self.log = []
        self.screens = []

    def turn(self, keys=()) -> dict:
        memory = self.game.memory
        bp._lives(memory)
        self.game.turns(1, keys)

        def rec(base):
            return {"graphic": memory[base], "u": memory[base + 1], "v": memory[base + 2],
                    "z": memory[base + 3], "bumped": memory[base + BUMPED],
                    "speeds": tuple(_signed(memory[base + k]) for k in (0x14, 0x15, 0x16)),
                    "rect": tuple(memory[base + 0x18:base + 0x1C])}

        entry = {"turn": len(self.log), "player": rec(PLAYER),
                 "killed": bool(memory[PLAYER + CONTACT] & 0x40),
                 "bolts": [rec(b) for b in (BOLTS, BOLTS + RECORD) if memory[b]],
                 "flyers": [rec(f) for f in (FLYERS, FLYERS + RECORD) if memory[f]],
                 "score": _bcd(memory, SCORE), "timer": memory[DROP_TIMER]}
        self.log.append(entry)
        self.screens.append(bytes(memory[0x4000:0x5B00]))
        return entry

    def picture(self, pictures: Pictures, name: str, turns, alt: str, things) -> str:
        """The screens as the given turns began (the display shows the turn
        before), cut round what `things(entry)` returns: (width, height, x, y)
        rectangles."""
        boxes = []
        for t in turns:
            for width, height, x, y in things(self.log[t]):
                if width and height:
                    boxes.append((x, 191 - (y + height), x + 8 * width, 192 - y))
        box = (max(0, min(b[0] for b in boxes) - 12), max(0, min(b[1] for b in boxes) - 12),
               min(256, max(b[2] for b in boxes) + 12), min(192, max(b[3] for b in boxes) + 12))
        images = [screen_image([0] * 0x4000 + list(self.screens[t + 1])).crop(box)
                  for t in turns if t + 1 < len(self.screens)]
        return pictures.strip(name, images, alt)


def _creatures_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    R = listing.r
    memory = bp.game_memory(snapshot)
    placed = room_graphics(memory)

    def sprite(graphic):
        return pictures.piece(f"creature_graphic{graphic}.png", sprite_of(memory, graphic),
                              f"Graphic {graphic}", 2, "pg-sprite")

    # The bolt, fired at a wall in an empty room.
    log("  a bolt, a thing from the sky, a head that bolts cannot touch...")
    bolt = Watch(snapshot, 30)
    face(bolt.game, 0)
    bolt.turn()
    fired = [bolt.turn(["w"])]
    for _ in range(16):
        fired.append(bolt.turn())
    flight = [e for e in fired if e["bolts"]]
    _check(flight[0]["bolts"][0]["u"] == fired[0]["player"]["u"] - 16
           and flight[0]["bolts"][0]["z"] == fired[0]["player"]["z"] + 4,
           "the bolt did not start 16 ahead and 4 up")
    _check(all(b["bolts"][0]["u"] - a["bolts"][0]["u"] == -8
               for a, b in zip(flight, flight[1:]) if b["bolts"][0]["graphic"] >= 149
               and a["bolts"][0]["graphic"] >= 149), "the bolt did not fly 8 a turn")
    puffed = next(e for e in flight if e["bolts"][0]["graphic"] < 149)
    bolt_rows = []
    for e in flight:
        b = e["bolts"][0]
        what = ("the bolt" if b["graphic"] >= 149 else "the puff")
        bolt_rows.append([e["turn"] - fired[0]["turn"], b["graphic"], what, b["u"], b["v"], b["z"],
                          "stopped in U (+$0C bit 0)" if b["bumped"] & 1 else ""])
    first = fired[0]["turn"]
    bolt_fig = bolt.picture(pictures, "creatures_bolt.png",
                            [first, first + 2, first + 4, puffed["turn"], puffed["turn"] + 4],
                            "A bolt fired at the wall",
                            lambda e: [e["player"]["rect"]] + [b["rect"] for b in e["bolts"]])

    # A head that bolts cannot touch: room 6.
    head_watch = Watch(snapshot, 6)
    m = head_watch.game.memory
    head = next(OBJECTS + RECORD * i for i in range(6, RECORD_COUNT)
                if m[OBJECTS + RECORD * i] == 93 and m[OBJECTS + RECORD * i + 1] == 136)
    for record in (PLAYER, BODY):
        m[record + 1], m[record + 2] = 170, m[head + 2] + 4
    face(head_watch.game, 0)
    head_rows = []
    for t in range(12):
        e = head_watch.turn(["w"] if t == 1 else [])
        head_rows.append((e, (m[head], m[head + 1], m[head + 2])))
    _check(not any(e["killed"] for e, _ in head_rows), "the player was killed by the head")
    hit = next(e for e, _ in head_rows if e["bolts"] and e["bolts"][0]["bumped"] & 1)
    _check(all(h[0] == 93 for _, h in head_rows) and head_rows[-1][1][2] > head_rows[0][1][2] + 10,
           "the head did not carry on")
    head_fig = head_watch.picture(pictures, "creatures_head.png", [0, 2, 5, 9],
                                  "A bolt against a pacing head",
                                  lambda e: [e["player"]["rect"]] + [b["rect"] for b in e["bolts"]])

    # A thing from the sky, and shooting it down: room 30 again, the drop
    # timer run out by writing it, the player turning and firing.
    sky = Watch(snapshot, 30)
    sky.game.memory[DROP_TIMER] = 1
    drop_turn = shot_turn = None
    for t in range(1500):
        keys = ["z"] if t % 6 == 0 else ["w"] if t % 6 == 3 and drop_turn is not None else []
        e = sky.turn(keys)
        if e["flyers"] and drop_turn is None:
            drop_turn = t
        if e["score"]:
            shot_turn = t
            break
        _check(not e["killed"], "something killed him in room 30")
    _check(drop_turn is not None and shot_turn is not None, "nothing fell, or nothing was hit")
    dropped = sky.log[drop_turn]["flyers"][0]
    points = sky.log[shot_turn]["score"]
    # The bolts (records 2 and 3) update before the things from the sky (4
    # and 5), so what was hit had the graphic it ended the turn before with.
    candidates = {f["graphic"]: score_by_bits(f["graphic"])
                  for f in sky.log[shot_turn - 1]["flyers"]}
    _check(points in candidates.values(), f"scored {points}, not what its graphic gives")
    hit_graphic = next(g for g, p in candidates.items() if p == points)
    for _ in range(6):
        sky.turn()
    homer_rows = []
    for t in list(range(drop_turn, min(shot_turn, drop_turn + 60), 6)) + [shot_turn - 1, shot_turn]:
        e = sky.log[t]
        for f in e["flyers"][:1]:
            homer_rows.append([t - drop_turn, f["graphic"], f["u"], f["v"], f["z"],
                               ", ".join(str(s) for s in f["speeds"]), e["score"]])
    sky_turns = [drop_turn, drop_turn + 10, drop_turn + 22, shot_turn - 1, shot_turn + 1]
    sky_fig = sky.picture(pictures, "creatures_sky.png", sky_turns,
                          "A thing from the sky, homing, and shot down",
                          lambda e: [e["player"]["rect"]] + [f["rect"] for f in e["flyers"]]
                          + [b["rect"] for b in e["bolts"]])

    # Standing still, the timer run out: the random number at the drop's
    # one-in-four test, turn after turn.
    still = Game(snapshot)
    still.go(30)
    still.memory[DROP_TIMER] = 1
    randoms = []
    for _ in range(STILL_TURNS):
        still.run_to(DROP_TEST)
        randoms.append(still.memory[RANDOM])
    still_fell = any(still.memory[f] for f in (FLYERS, FLYERS + RECORD))
    steps_even = all((b - a) % 2 == 0 for a, b in zip(randoms, randoms[1:]))

    # The tables.
    step_rows = []
    for facing in range(4):
        du, dv = _signed(memory[BOLT_STEPS + 2 * facing]), _signed(memory[BOLT_STEPS + 2 * facing + 1])
        step_rows.append([facing, FACINGS[facing][2], du, dv, 2 * du, 2 * dv])
    template = list(memory[FLYER_TEMPLATE:FLYER_TEMPLATE + 8])
    drop_rows = []
    for slot in range(8):
        graphic = memory[DROP_GRAPHICS + slot]
        routine = update_routine(memory, graphic)
        frames = [g for g in range(pd.GRAPHIC_COUNT) if update_routine(memory, g) == routine
                  and (g & 0xFC) == (graphic & 0xFC)]
        scores = sorted({score_for(memory, g) for g in frames})
        deadly = routine in (0xD1F5, 0xD251) or listing.entry_of(routine) in (0xD1F5, 0xD251)
        drop_rows.append([slot, graphic_ref(graphic), sprite(graphic), R(routine),
                          "yes" if deadly else "no", ", ".join(map(str, scores))])
    for graphic in {memory[DROP_GRAPHICS + s] for s in range(8)}:
        _check(score_for(memory, graphic) == score_by_bits(graphic),
               f"graphic {graphic} scores {score_for(memory, graphic)}")
    quest_rooms = {memory[pd.QUEST_START + pd.QUEST_SIZE * i + ROOM] for i in range(4)}
    banned = sorted(set(placed.get(WELL, [])) | quest_rooms)

    # What makes a thing deadly: every routine that calls MAKE_DEADLY.
    # A graphic is deadly if its update routine starts at or before the call
    # in the same entry: PACER_U, inside DEADLY_PACER_U, starts after it.
    calls = {}
    for address in range(0xAF87, BUFFER - 2):
        if list(memory[address:address + 3]) == [0xCD, MAKE_DEADLY & 0xFF, MAKE_DEADLY >> 8]:
            entry = listing.entry_of(address)
            if entry is not None:
                calls[entry] = address
    deadly_rows = []
    for routine, site in sorted(calls.items()):
        graphics = [g for g in range(pd.GRAPHIC_COUNT)
                    if listing.entry_of(update_routine(memory, g)) == routine
                    and update_routine(memory, g) <= site]
        rooms = sorted({r for g in graphics for r in placed.get(g, [])})
        falls = any(memory[DROP_GRAPHICS + s] in graphics for s in range(8))
        deadly_rows.append([R(routine), numbers(graphics) if graphics else "none (unreached)",
                            (room_list(rooms) + ("; and from the sky" if falls else ""))
                            if graphics else ""])

    score_rows = []
    for routine, what in ((0xCC4B, "homers"), (0xD1FD, "the creature that roams"),
                          (0xD251, "the walker")):
        graphics = [g for g in range(pd.GRAPHIC_COUNT) if update_routine(memory, g) == routine]
        score_rows.append([what, numbers(graphics),
                           ", ".join(f"{g}: {score_for(memory, g)}" for g in graphics)])

    return "\n".join([
        '<div class="kl-list">',
        "<p>Sabreman fights with a bolt he throws, and it can harm only one kind of thing: "
        "what falls from the sky. Everything that lives in a room -- spiders, heads, "
        "spikes, the still hazards that line the paths -- is beyond it, to be walked round "
        "or jumped. This page is the bolt, the things from the sky, the score, and what "
        "makes a thing deadly. Knight Lore has none of it but the puff, its sparkle.</p>",

        "<h3>The bolt</h3>",
        f"<p>{R(FIRE)} runs in the player's turn. A fire key newly pressed (FIRE_HELD makes "
        "it one bolt a press) takes the first free of the two bolt records, copies the "
        "legs' record into it and makes it graphic 150, moving eight units a turn the way "
        f"he faces ({R(BOLT_STEPS)}, by {R(0xC5BD)}), starting two steps -- 16 units -- "
        "ahead of him and 4 higher, with flags $14 and a half-height of 8. A start outside "
        "the room's walls (he is in a doorway, or facing a wall close up) is taken back. "
        f"Then {R(BOLT)} flies it: the fall and the cut ({R(0xB979)}) as for anything, but "
        "never below Z 132, so it flies level; its graphic cycles 151, 150, 149; it tests "
        f"the two things from the sky ({R(0xC206)}) and shoots one down if it touches it; "
        "and if its move was cut short in U or V by anything else it becomes a puff "
        f"({R(0xC107)}), graphics 64 to 71 a turn each ({R(0xC111)}, {R(0xC11D)}; "
        '<a href="Animations.html">the animations page</a> plays it), and then nothing.</p>',
        table(["Facing", "Way", "Step in U", "Step in V", "Starts at U +", "Starts at V +"],
              step_rows),
        f"<p>Fired in {room_ref(30)}, which is empty, facing -U from the middle, in a simulator when "
        "this page was built:</p>",
        table(["Turn", "Graphic", "", "U", "V", "Z", ""], bolt_rows),
        figure(bolt_fig, "The bolt, and its puff against the wall."),

        "<h3>What a bolt can hit</h3>",
        f"<p>{R(0xC206)} tests only records 4 and 5, the things from the sky, and skips "
        "graphics below 8 and the puff: each axis, the distance between them no more than "
        "their half-sizes added, plus 2. Nothing else is a target. Anything else in the "
        "way is only an obstacle to the collision code, which cuts the bolt's move short "
        "and so makes it a puff -- the heads, the spiders and the still hazards carry on as "
        "if nothing happened. In room 6, from a place out of their way, a bolt thrown at one "
        "of the "
        "two pacing heads:</p>",
        table(["Turn", "The bolt", "The head (graphic, U, V)"],
              [[e["turn"], ", ".join(f"graphic {b['graphic']} at U {b['u']}" +
                                     (", stopped" if b["bumped"] & 1 else "")
                                     for b in e["bolts"]) or "", f"{h[0]}, {h[1]}, {h[2]}"]
               for e, h in head_rows[:10]]),
        figure(head_fig, "A bolt against a pacing head: the bolt puffs, the head paces on."),
        f"<p>The bolts' test has one more use: the well counts the turns a bolt touches it "
        f"({R(0xCFB2)}, and see <a href=\"Quest.html\">the quest</a>).</p>",
        table(["What", "Against", "What happens", "Where"], [
            ["A bolt", "a thing from the sky", "shot down: points, and it becomes a puff; "
             "the bolt vanishes", R(0xC264)],
            ["A bolt", "the well", "a turn of contact counted; 32 in one visit give the "
             "bucket", R(0xCFD2)],
            ["A bolt", "anything else, or a wall", "its move is cut short, and it becomes a "
             "puff", R(BOLT)],
            ["Anything deadly (+$0D bit 7)", "what it moves into", "killed (+$0D bit 6)",
             R(0xB742)],
            ["Anything deadly (+$0D bit 5)", "what moves into it", "killed", R(0xB742)],
            ["A thing from the sky that homes", "the player", "nothing: it is not deadly",
             R(0xCC4B)],
        ]),

        "<h3>Things from the sky</h3>",
        f"<p>Every turn {R(SKY_DROP)} counts DROP_TIMER down (it is reset at each room's "
        f"start and after each drop, by {R(0xCC31)} -- 80 turns, or 8 once the first quest "
        'item is done: see <a href="Quest.html">the quest page</a>). When it has run out, '
        "there is a chance of one in four each turn, two bits of the random number, of a "
        "drop: a free one of the two records at FLYERS gets a copy of "
        f"{R(FLYER_TEMPLATE)} -- Z {template[3]}, half-sizes {template[4]}, {template[5]} "
        f"and {template[6]}, flags ${template[7]:02X} -- a U and a V of 104 plus a random "
        "number masked with $2F (104 to 119 or 136 to 151: never on the room's middle "
        f"lines), and one of the eight graphics at {R(DROP_GRAPHICS)} picked by three more "
        "bits of the random number. If it would overlap anything it is taken back. Nothing "
        f"falls at all in a room with the well, a quest item or a piece of the pentagram "
        f"({R(0xCB89)}; {len(banned)} rooms as the game starts, and room 82 once the "
        "pentagram is showing).</p>",
        table(["Slot", "Graphic", "Sprite", "Update routine", "Deadly", "Points, by frame"],
              drop_rows),
        f"<p>{R(0xCC4B)}, the homer, flies at him: a speed in each of U, V and Z kept in "
        "sixteenths, each pulled 3 a turn towards his legs' U and V and his body's Z, up to "
        "56 or down to -72, and a step each turn of the speed plus 8 over 16 -- at most 4 "
        "units either way; bumping into anything in U or V turns that speed round, so it "
        "bounces. It is never deadly: no update routine of a homer sets a kill bit, and "
        f"its record starts with a clear +$0D. {R(0xD1F5)} (graphics 80 and 81, at "
        f"{R(0xD1FD)}) and {R(0xD251)} (168 to 171) are the ones that kill: they fall, then "
        "run straight at 4 a turn, turning at a bump, deadly both ways.</p>",
        f"<p>That chance is less of one than it looks. {R(0xB00C)} stirs the random number "
        "once per object, with R and the turn counter, and with interrupts off nothing else "
        "touches R: a turn in which nothing changes runs exactly the instructions the turn "
        f"before did. In {room_ref(30)}, empty, with the timer run out and the player "
        f"standing still, the random number was read at the test for {STILL_TURNS} turns: "
        + ("it moved by an even amount every turn, so its lowest bit never changed; it was "
           "odd, the test wants both low bits clear, and "
           if steps_even and randoms[0] & 1 else "")
        + ("nothing fell." if not still_fell else "something fell.")
        + " That was in the simulator; the same should hold on a Spectrum, whose R counts "
        "instructions the same way, but that is inferred. Anything that changes the turn's "
        "path -- turning, walking, firing -- stirs it again.</p>",
        "<p>In room 30 again, with the drop timer run out by writing it, the player turning "
        "a quarter every six turns and, once something had fallen, firing between turns: "
        f"a homer, graphic {dropped['graphic']}, fell {drop_turn} turns in, from Z "
        f"{dropped['z']} at ({dropped['u']}, {dropped['v']}). It homed on him and hung "
        f"round him for {shot_turn - drop_turn} turns without harming him, until a "
        f"bolt hit it, at graphic {hit_graphic}, for {points} points:</p>",
        table(["Turns after the drop", "Graphic", "U", "V", "Z", "Speeds U, V, Z", "Score"],
              homer_rows),
        figure(sky_fig, "The thing from the sky: falling, homing, and shot down."),

        "<h3>The score</h3>",
        f"<p>{R(SHOOT_DOWN)} makes the points out of the graphic number of what was hit, "
        "bits into BCD digits: the hundreds from bits 5 to 7, the tens from bits 2 to 4, "
        "the units from bits 6, 7 and 0. No digit can pass 7, so the result is always good "
        f"BCD without a check. {R(0xBB29)} adds them and {R(0xB145)} copies the score "
        "straight to the screen. Things animate by changing their graphic, so the points "
        "depend on the frame the bolt catches. Run on its own for every graphic a thing "
        "from the sky can have:</p>",
        table(["What", "Graphics", "Points"], score_rows),

        "<h3>What makes a thing deadly</h3>",
        f"<p>Two bits of +$0D: bit 7, kills what it moves into, and bit 5, kills what "
        f"touches it. {R(MAKE_DEADLY)} sets both, and the collision code "
        f"({R(0xB742)} and the other two axes) passes the kill -- bit 6 -- to whichever "
        "party the other's bits say. These are all the routines that call it, found by "
        "searching the code for the call, with the graphics the update table gives them "
        "and the rooms that place those:</p>",
        table(["Routine", "Graphics", "Where"], deadly_rows),
        "<p>A killed player's legs become the puff and his body with them; when the puff "
        "is over, both records are empty and the main loop starts a life (see "
        '<a href="Doorways.html">rooms and doorways</a> for where).</p>',

        "<h3>Confirmed and inferred</h3>",
        "<ul>"
        "<li>Run in the simulator when this page was built: the bolt's flight and puff, the "
        "bolt against the head, the drop, the homer's flight and its harmlessness over "
        "those turns, the shot and its points, and the score for every graphic.</li>"
        "<li>Staged: the player's facing and place, written into his record; the drop "
        "timer, written to 1. Everything after is the game's.</li>"
        "<li>Read from the code: the one-in-four chance, the random place and graphic, the "
        "bans; the homer's speeds; that the roamer and the walker kill.</li>"
        "</ul>",
        "</div>"])


# --------------------------------------------------------------------------
# Together.
# --------------------------------------------------------------------------

PAGES = {
    "Drawing": _drawing_page,
    "Movement": _movement_page,
    "Doorways": _doorways_page,
    "Quest": _quest_page,
    "Creatures": _creatures_page,
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
    listing = Listing(snapshot.with_name("pentagram.skool"))
    pictures = Pictures(html_dir)
    sections = {}
    for name, page in PAGES.items():
        if only and name not in only:
            continue
        log(f"Writing the how-it-works page {name}...")
        body = page(snapshot, listing, pictures, log)
        check_html(name, body)
        sections[name] = body
    if listing.unlinked:
        # Not an error -- the address is still printed -- but a link was meant.
        log("  how it works: no entry to link at " + ", ".join(
            f"${a:04X}" for a in sorted(listing.unlinked)))
    return sections
