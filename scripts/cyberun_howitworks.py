"""Cyberun's "How it works" pages: the architecture, the landscape and how it
is drawn and scrolled, collision with it, how moving things are drawn, the
ship and its add-ons, the objects, the rocket and the ore, and damage, fuel
and dying.

build() returns each page's HTML for the build's generated ref file and
writes the pictures into html_dir/images/howitworks/. Nothing here is a
transcription of the game: every table is read from the game's memory as the
page is built, and every worked example is the game's own code, run in
SkoolKit's simulator -- the build's own Machine (build_cyberun.py), started
from the snapshot at $5C80, through the start-up (which builds the shift
tables and the shifted landscape pieces) and the menu, and driven the way the
build's sessions drive it: by keys, and by the game's own restart. Where a
scene is staged by writing to memory, the page says what was written. Where a
picture is drawn from the data rather than by the game's code, the page says
so.

The prose is written from the listing's annotations and the stage 2 notes
(notes/cyberun/). Numbers the prose quotes from the game's code are read back
from the runs below, and the build stops if a run does not come out the way
the code says it must.
"""
from __future__ import annotations

import re
from pathlib import Path

import build_cyberun as bc

IMAGE_URL = "images/howitworks"
TSTATES = bc.TSTATES_PER_SECOND
FRAME = 69888                   # T-states in a 48K Spectrum's frame

SPECTRUM = [(0, 0, 0), (0, 0, 0xD7), (0xD7, 0, 0), (0xD7, 0, 0xD7),
            (0, 0xD7, 0), (0, 0xD7, 0xD7), (0xD7, 0xD7, 0), (0xD7, 0xD7, 0xD7)]
SPECTRUM_BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF),
                   (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0), (0xFF, 0xFF, 0xFF)]
OUTLINE = (255, 64, 64)
CHANGED = (255, 60, 60)

# The play area: 28 bytes across from x 8 (columns 1-28), lines $18-$B7.
PLAY_LEFT, PLAY_RIGHT = 8, 0xE8
PLAY_TOP, PLAY_BOTTOM = 0x18, 0xB7


def _word(memory, address: int) -> int:
    return memory[address] | memory[address + 1] << 8


def _signed(byte: int) -> int:
    return byte - 256 if byte & 0x80 else byte


def _signed16(word: int) -> int:
    return word - 65536 if word & 0x8000 else word


def _esc(text: str) -> str:
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")


def _check(condition: bool, what: str) -> None:
    """The prose says what the code does; if a run disagrees, the page would
    be wrong, so the build stops instead."""
    if not condition:
        raise RuntimeError(f"cyberun_howitworks: {what}")


def screen_address(x: int, y: int) -> int:
    """The display byte holding pixel (x, y)."""
    return 0x4000 | (y & 0xC0) << 5 | (y & 7) << 8 | (y & 0x38) << 2 | x >> 3


# --------------------------------------------------------------------------
# The listing: link only to the starts of entries.
# --------------------------------------------------------------------------

class Listing:
    """The entries of cyberun.skool and every label in it, read at build
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
        self.by_name = {name: address for address, name in self.labels.items()}
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
        if entry is not None and address < entry + 0x400:
            # An address inside an entry with no label of its own: link the
            # entry, showing the address.
            return f"#R${entry:04X}(${address:04X})"
        self.unlinked.add(address)
        return f"${address:04X}"

    def name(self, address: int) -> str:
        return self.labels.get(address) or self.entries.get(address) or f"${address:04X}"

    def at(self, name: str) -> int:
        """A label's address, so that the prose and the runs use the
        listing's addresses and a renamed label stops the build."""
        _check(name in self.by_name, f"no label {name} in the listing")
        return self.by_name[name]


# --------------------------------------------------------------------------
# The game, in the simulator.
# --------------------------------------------------------------------------

class Game:
    """The game on the build's simulated Spectrum (build_cyberun.Machine),
    from the snapshot through the start-up and the menu, driven pass by
    pass. fork() copies it, so one start serves many examples."""

    def __init__(self, snapshot: Path | None = None, machine=None):
        self.machine = machine or bc.Machine(snapshot)

    @classmethod
    def at_menu(cls, snapshot: Path) -> "Game":
        game = cls(snapshot)
        game.play([bc.At("the menu", bc.MENU_LOOP, 600.0, bc.TUNE_KEYS)])
        return game

    @classmethod
    def in_play(cls, snapshot: Path, control: int = 0) -> "Game":
        game = cls(snapshot)
        game.play(bc._start(control))
        return game

    def fork(self) -> "Game":
        from skoolkit import CSimulator
        from skoolkit.simulator import Simulator

        old = self.machine.simulator
        machine = bc.Machine.__new__(bc.Machine)
        simulator = (CSimulator or Simulator)(list(old.memory),
                                              state={"iff": 0, "im": 1, "tstates": 0})
        for index in range(len(old.registers)):
            simulator.registers[index] = old.registers[index]
        machine.simulator = simulator
        machine.tracer = bc._key_tracer_class()(simulator)
        simulator.set_tracer(machine.tracer)
        machine.pc = self.machine.pc
        machine.executed = None
        return Game(machine=machine)

    @property
    def memory(self):
        return self.machine.memory

    @property
    def registers(self):
        return self.machine.simulator.registers

    @property
    def t(self) -> int:
        from skoolkit.simutils import T

        return self.registers[T]

    @property
    def pc(self) -> int:
        return self.machine.pc

    def reg(self, name: str) -> int:
        from skoolkit import simutils

        if len(name) == 2 and name not in ("SP", "PC"):
            return (self.registers[getattr(simutils, name[0])] << 8
                    | self.registers[getattr(simutils, name[1])])
        if name in ("IX", "IY"):
            return (self.registers[getattr(simutils, name + "h")] << 8
                    | self.registers[getattr(simutils, name + "l")])
        return self.registers[getattr(simutils, name)]

    def play(self, steps) -> None:
        self.machine.play(steps, "how it works")

    def run_to(self, stops, seconds: float = 10.0, keys=(), stick: int = 0) -> int:
        """Run until PC reaches one of `stops` -- at least one instruction
        first, so stopping at the same place again catches the next time
        round -- or fail, naming where it was, after `seconds` of the game's
        time. Returns the address stopped at."""
        from skoolkit.simutils import PC, T

        if isinstance(stops, int):
            stops = (stops,)
        simulator = self.machine.simulator
        registers = simulator.registers
        self.machine.tracer.keys = set(keys)
        self.machine.tracer.kempston = stick
        limit = registers[T] + int(seconds * TSTATES)
        if len(stops) == 1:
            simulator.trace(self.machine.pc, stops[0], 0, limit, False, None, None, None,
                            None, None)
        else:
            # Several stops: one instruction at a time (only ever for a
            # stretch inside one pass, so the cost does not matter).
            wanted = set(stops)
            simulator.trace(self.machine.pc, 0, 1, limit, False, None, None, None, None, None)
            while registers[PC] not in wanted and registers[T] < limit:
                simulator.trace(registers[PC], 0, 1, limit, False, None, None, None, None,
                                None)
        self.machine.pc = registers[PC]
        if self.machine.pc not in stops:
            raise RuntimeError(f"the game never reached "
                               f"{', '.join(f'${s:04X}' for s in stops)} in {seconds} s "
                               f"(PC ${self.machine.pc:04X})")
        return self.machine.pc

    def passes(self, count: int = 1, keys=(), stick: int = 0) -> None:
        """Play whole passes of the play loop, each to the start of the next."""
        for _ in range(count):
            self.run_to(bc.PLAY_LOOP, 10.0, keys, stick)

    def call(self, address: int, registers: dict | None = None, seconds: float = 2.0) -> None:
        """Run one routine of the game's from here until it returns, on this
        machine's memory: a return address nothing else uses is pushed first
        -- $5C41, in the system variables the game leaves unused
        (basic_leftovers) -- on a stack at $5B70, inside the game's own."""
        from skoolkit import simutils
        from skoolkit.simutils import PC, SP

        trap, stack = 0x5C41, 0x5B70
        memory = self.memory
        memory[stack] = trap & 0xFF
        memory[stack + 1] = trap >> 8
        for name, value in (registers or {}).items():
            if len(name) == 2 and name not in ("SP", "PC", "IX", "IY"):
                self.registers[getattr(simutils, name[0])] = value >> 8
                self.registers[getattr(simutils, name[1])] = value & 0xFF
            elif name in ("IX", "IY"):
                self.registers[getattr(simutils, name + "h")] = value >> 8
                self.registers[getattr(simutils, name + "l")] = value & 0xFF
            else:
                self.registers[getattr(simutils, name)] = value
        self.registers[SP] = stack
        self.registers[PC] = address
        self.machine.pc = address
        self.run_to(trap, seconds)


# --------------------------------------------------------------------------
# Pictures.
# --------------------------------------------------------------------------

def screen_image(memory, attributes: bool = True):
    """The display file with its attributes, as a 256 by 192 picture."""
    from PIL import Image

    image = Image.new("RGB", (256, 192))
    pixels = image.load()
    for y in range(192):
        row = 0x4000 | ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
        for column in range(32):
            byte = memory[row + column]
            if attributes:
                attr = memory[0x5800 + (y >> 3) * 32 + column]
                palette = SPECTRUM_BRIGHT if attr & 0x40 else SPECTRUM
                ink, paper = palette[attr & 7], palette[(attr >> 3) & 7]
            else:
                ink, paper = (255, 255, 255), (0, 0, 0)
            for bit in range(8):
                pixels[column * 8 + bit, y] = ink if byte & (0x80 >> bit) else paper
    return image


def screen_bytes(memory) -> bytes:
    return bytes(memory[0x4000:0x5B00])


def screen_of(kept: bytes, attributes: bool = True):
    return screen_image([0] * 0x4000 + list(kept), attributes)


def changed_image(before: bytes, after: bytes, colour=CHANGED):
    """`after` in its colours, dimmed, with every pixel that differs from
    `before` painted bright."""
    from PIL import Image

    image = screen_of(after)
    dim = Image.eval(image, lambda v: v // 3)
    pixels = dim.load()
    for y in range(192):
        row = ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
        for column in range(32):
            diff = before[row + column] ^ after[row + column]
            if diff:
                for bit in range(8):
                    if diff & (0x80 >> bit):
                        pixels[column * 8 + bit, y] = colour
    return dim


def play_area(image):
    """The play area of a screen picture (with the frame's column each side)."""
    return image.crop((0, PLAY_TOP - 8, 256, PLAY_BOTTOM + 9))


def bitmap_image(rows, width_bytes: int, ink=(255, 255, 255), paper=(0, 0, 0)):
    """Rows of bytes (top row first) as a picture."""
    from PIL import Image

    image = Image.new("RGB", (width_bytes * 8, max(1, len(rows))), paper)
    pixels = image.load()
    for y, row in enumerate(rows):
        for column in range(width_bytes):
            byte = row[column]
            for bit in range(8):
                if byte & (0x80 >> bit):
                    pixels[column * 8 + bit, y] = ink
    return image


def scaled(image, scale: int):
    from PIL import Image

    return image.resize((image.width * scale, image.height * scale), Image.NEAREST)


def strip(images, gap: int = 4, background=(20, 20, 60)):
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
        self.written: list[str] = []

    def save(self, name: str, image) -> str:
        image.save(self.dir / name)
        self.written.append(name)
        return name

    def stage(self, name: str, image, alt: str = "") -> str:
        """A whole screen (or a picture twice a screen's size): 512 wide."""
        self.save(name, image)
        return f'<img class="kl-stage" src="{IMAGE_URL}/{name}" alt="{_esc(alt)}">'

    def piece(self, name: str, image, alt: str = "", scale: int = 2) -> str:
        self.save(name, image)
        return (f'<img class="kl-piece" src="{IMAGE_URL}/{name}" alt="{_esc(alt)}" '
                f'width="{image.width * scale}" height="{image.height * scale}">')

    def gif(self, name: str, frames, duration: int, alt: str = "", scale: int = 2) -> str:
        frames[0].save(self.dir / name, save_all=True, append_images=frames[1:],
                       duration=duration, loop=0)
        self.written.append(name)
        return (f'<img class="kl-piece" src="{IMAGE_URL}/{name}" alt="{_esc(alt)}" '
                f'width="{frames[0].width * scale}" height="{frames[0].height * scale}">')


def figure(img: str, caption: str) -> str:
    return f'<div class="kl-item">{img}<p>{caption}</p></div>'


def table(headings: list[str], rows: list[list]) -> str:
    head = "".join(f"<th>{h}</th>" for h in headings)
    body = "".join("<tr>" + "".join(f"<td>{cell}</td>" for cell in row) + "</tr>"
                   for row in rows)
    return f'<table class="kl-table"><tr>{head}</tr>{body}</table>'


def confirmed(items: list[str]) -> str:
    return ("<h3>Confirmed and inferred</h3><ul>"
            + "".join(f"<li>{item}</li>" for item in items) + "</ul>")


# --------------------------------------------------------------------------
# Shared: the game's addresses the pages run to and read, and the scenes.
# Each is the listing's; Listing.at() checks the labels the pages name in
# their prose, so a renamed or moved label stops the build.
# --------------------------------------------------------------------------

# The play loop and one pass of it (main-loop.md).
SHIP_PASS = 0xC374
TO_SCROLL = 0xC3E0              # ship_pass's JP scroll_landscape: the ship has moved
DRAW_LANDSCAPE_CALL = 0xDEB3    # scroll_landscape's CALL draw_landscape
LANDSCAPE_DRAWN = 0xDEB6        # ...and where it returns
BEAMS_AND_STARS = 0xDEBE        # the ground objects drawn either side; beams and stars next
SPRITES_DRAWN = 0xDEC4          # beams and stars drawn; then draw_ship
AFTER_SHIP_PASS = 0xF46F        # back in the play loop: CALL update_fuel_gauge
AFTER_GAUGE = 0xF472            # CALL spawn_tick
AFTER_SPAWN = 0xF475            # CALL update_objects
AFTER_OBJECTS = 0xF478          # CALL random

# The landscape (landscape.md).
LANDSCAPE_MAP = 0x61BC
MAP_COLUMNS, MAP_ROWS = 96, 28
TILE_TABLE = 0x6C3C
TILE_COUNT = 171
TILE_RECORDS = 0x6D92
PIECE_SHAPES = 0xE3BD
PIECE_CLASSES = 0xD0AC
SHIFT_TABLES = {0: 0xE37D, 2: 0xE2BD, 4: 0xE2FD, 6: 0xE33D}
PIECE_START = 0xD15C            # draw_landscape: each piece begins here (HL its record)
STEPS_DONE = 0xD72C             # after_step_drawn: the piece's last step drawn
PIECE_DONE = 0xD80A             # ...its lip, fills and colour done; the next piece
STEP_DRAWN = (0xD711, 0xD714)   # after_step_drawn: a step drawn (sloped, flat)
GROUND_CELL = 0x5C1D
PIECES_LEFT = 0x5C20
PIECE_STEPS_DONE = 0x5C2F
CURRENT_PIECE = 0xDEDC
SCROLL_DOWN, SCROLL_ACROSS = 0xCCBA, 0xCCBB
SHIFT_TABLE = 0xCCBD
ORIGIN_X, ORIGIN_Y = 0xCE41, 0xCE42
VIEW_X, VIEW_Y = 0xCE45, 0xCE46
VIEW_COLUMN, VIEW_ROW = 0xCE57, 0xCE58
MAP_WINDOW_TILES = 0xDC89
MAP_WINDOW_TILE_BYTES = 0xDC91
PLANET_COLOURS = 0xDC97
PLANETS = 5
MAP_REBUILD = 0x5C3C
RECORD_GROUND = 0x5C3D
BOX_LISTS = (0x5B80, 0x5BA5, 0x5BCA, 0x5BEF)  # the view's cell, below, right, below-right
CELL_NAMES = ("the view's cell", "the cell below", "the cell to the right",
              "the cell below and right")

DIRECTION_NAMES = {
    0: "flat floor", 1: "gentle slope, climbing right", 2: "45 degrees, climbing right",
    3: "steep, climbing right", 4: "gentle slope, climbing left",
    5: "45 degrees, climbing left", 6: "steep, climbing left", 7: "flat ceiling",
    8: "gentle ceiling, climbing right", 9: "45-degree ceiling, climbing right",
    10: "steep ceiling, climbing right", 11: "gentle ceiling, climbing left",
    12: "45-degree ceiling, climbing left", 13: "steep ceiling, climbing left",
    14: "wall, stepping right", 15: "wall, stepping left"}


def map_tile(memory, column: int, row: int) -> int:
    """The tile number of a map cell, as read_map_cell ($E235) reads it: row 0
    is the sky, tile 0."""
    if row == 0:
        return 0
    return memory[LANDSCAPE_MAP + (row - 1) * MAP_COLUMNS + column % MAP_COLUMNS]


def tile_record(memory, tile: int) -> dict:
    """A tile's record decoded the way draw_landscape ($D132-$D1A7) reads it:
    $99 upside down, $FF mirrored, a byte from $95 up skipped, the count, and
    per piece x, y, direction and steps, and two end codes for a flat one."""
    address = _word(memory, TILE_TABLE + 2 * tile)
    record = {"address": address, "upside_down": False, "mirrored": False, "pieces": []}
    if memory[address] == 0:
        return record
    if memory[address] == 0x99:
        record["upside_down"] = True
        address += 1
    if memory[address] == 0xFF:
        record["mirrored"] = True
        address += 1
    if memory[address] >= 0x95:
        address += 1
    count = memory[address]
    address += 1
    for _ in range(count):
        x, y, byte = memory[address], memory[address + 1], memory[address + 2]
        address += 3
        direction, steps = byte >> 4, (byte & 15) or 16
        ends = None
        if direction in (0, 7):
            ends = (memory[address], memory[address + 1])
            address += 2
        record["pieces"].append({"x": x, "y": y, "direction": direction, "steps": steps,
                                 "ends": ends})
    return record


def piece_shape(memory, direction: int) -> tuple[int, int, int]:
    """Run in pixels, run in bytes, rise in rows (set_piece_shape $E3D8)."""
    index = direction if direction < 7 else direction - 7
    address = PIECE_SHAPES + 3 * index
    return _signed(memory[address]), _signed(memory[address + 1]), memory[address + 2]


_BASE: dict[str, "Game"] = {}


def base_game(snapshot: Path) -> "Game":
    """The game started once (menu, keyboard, key 0, the first pass of
    play), kept, and forked for every example."""
    key = str(snapshot)
    if key not in _BASE:
        _BASE[key] = Game.in_play(snapshot)
    return _BASE[key].fork()


def fly(game: "Game", plan, alive: bool = True) -> None:
    """Play passes holding keys: plan is [(keys, passes)], the damage and
    fuel undone before each pass when `alive` (the sessions' _keep_alive)."""
    for keys, count in plan:
        for _ in range(count):
            if alive:
                bc._keep_alive(game.memory)
            game.passes(1, keys=keys)


# The scene most examples use: from the start of a game, flown left and up
# into the hills west of the start until the ship rests against a long slope
# (map column $0C, row 6), then right a little. Played by keys, so the view
# is one the game reaches by itself.
HILL_FLIGHT = [(["a", "z"], 40), (["z"], 40), (["a", "z"], 20), (["x"], 6)]


def clear_play_area(memory) -> None:
    """Every pixel of the play area to 0 (28 bytes by 160 lines from x 8)."""
    for y in range(PLAY_TOP, PLAY_BOTTOM + 1):
        address = screen_address(PLAY_LEFT, y)
        for column in range(28):
            memory[address + column] = 0


# The terrace scene: from the start, right along the plain, up over the first
# ground object and on until the ship is over the drop east of the start (map
# column $10, row 7): a flat run ending in a cap, a steep step and a long
# 45-degree slope, across three map cells.
TERRACE_FLIGHT = [(["x"], 190), (["a"], 30), (["a", "x"], 30), (["x"], 60)]
FLY_IN_PASS = 0xDD72            # start_landscape: one pass of the fly-in


def window_cells(memory) -> list[dict]:
    """The four map cells on the screen, as load_map_window left them, with
    where each one's page origin is on the screen (landscape.md: x + origin_x,
    and $E0 more for the right-hand cells; y + origin_y, $A0 less for the
    upper ones)."""
    cells = []
    for cell in range(4):
        lower, right = cell & 1, cell >> 1
        tile = memory[MAP_WINDOW_TILE_BYTES + cell]
        cells.append({
            "cell": cell, "tile": tile, "record": tile_record(memory, tile),
            "column": (memory[VIEW_COLUMN] + right) % MAP_COLUMNS,
            "row": memory[VIEW_ROW] + lower,
            "dx": (memory[ORIGIN_X] + 0xE0 * right) & 0xFF,
            "dy": (memory[ORIGIN_Y] - 0xA0 * (1 - lower)) & 0xFF})
    return cells


def cell_outlines(image, memory, scale: int = 2, colour=(80, 160, 255)):
    """The screen, `scale` times, with the edges between the window's four
    cells drawn across the play area."""
    from PIL import ImageDraw

    big = scaled(image, scale)
    draw = ImageDraw.Draw(big)
    split_x = (0xE8 + memory[ORIGIN_X]) & 0xFF      # the left cells' right edge
    split_y = (0x18 + memory[ORIGIN_Y]) & 0xFF      # the lower cells' top line
    if PLAY_LEFT < split_x < PLAY_RIGHT:
        draw.line([(split_x * scale, PLAY_TOP * scale),
                   (split_x * scale, (PLAY_BOTTOM + 1) * scale - 1)], fill=colour, width=1)
    if PLAY_TOP < split_y <= PLAY_BOTTOM:
        draw.line([(PLAY_LEFT * scale, split_y * scale),
                   (PLAY_RIGHT * scale - 1, split_y * scale)], fill=colour, width=1)
    return big, split_x, split_y


def byte_grid(image, x0: int, scale: int, colour=(80, 160, 255)):
    """Lines down a crop (already `scale` times) at the screen's byte
    boundaries, the crop's left edge being screen x `x0`."""
    from PIL import ImageDraw

    draw = ImageDraw.Draw(image)
    for x in range(0, image.width // scale + 1):
        if (x0 + x) % 8 == 0:
            draw.line([(x * scale, 0), (x * scale, image.height - 1)], fill=colour, width=1)
    return image


def changed_box(before: bytes, after: bytes):
    """The smallest box (left, top, right, bottom) round the pixels that
    differ, inside the play area; None if none do."""
    box = None
    for y in range(PLAY_TOP, PLAY_BOTTOM + 1):
        row = ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
        for column in range(1, 29):
            diff = before[row + column] ^ after[row + column]
            if diff:
                x0 = column * 8 + (8 - diff.bit_length())
                x1 = column * 8 + 8 - ((diff & -diff).bit_length() - 1)
                box = (x0, y, x1, y + 1) if box is None else (
                    min(box[0], x0), min(box[1], y), max(box[2], x1), max(box[3], y + 1))
    return box


def highlight(before: bytes, after: bytes, new=(255, 255, 255), old=(110, 40, 110)):
    """`after` without attributes: pixels already set in `before` dim, the
    ones set since bright."""
    from PIL import Image

    image = Image.new("RGB", (256, 192))
    pixels = image.load()
    for y in range(192):
        row = ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
        for column in range(32):
            a, b = before[row + column], after[row + column]
            for bit in range(8):
                mask = 0x80 >> bit
                if b & mask:
                    pixels[column * 8 + bit, y] = old if a & mask else new
    return image


def bits_set(kept: bytes) -> int:
    return sum(bin(byte).count("1") for byte in kept[:0x1800])


def bits_changed(before: bytes, after: bytes) -> int:
    return sum(bin(a ^ b).count("1") for a, b in zip(before[:0x1800], after[:0x1800]))


def attr_name(attr: int) -> str:
    names = ["black", "blue", "red", "magenta", "green", "cyan", "yellow", "white"]
    return (("bright " if attr & 0x40 else "") + names[attr & 7]
            + (f" on {names[(attr >> 3) & 7]}" if attr & 0x38 else ""))


def landscape_pass(game: "Game", keys) -> dict:
    """Run on to a pass that scrolls both ways and stop at its JP
    scroll_landscape: the ship has moved and nothing is drawn yet."""
    m = game.memory
    for _ in range(60):
        game.run_to(TO_SCROLL, 2, keys)
        if m[SCROLL_ACROSS] and m[SCROLL_DOWN]:
            return {"across": _signed(m[SCROLL_ACROSS]), "down": _signed(m[SCROLL_DOWN])}
        bc._keep_alive(m)
        game.passes(1, keys)
    raise RuntimeError("cyberun_howitworks: no pass scrolled both ways")


def draw_alone(game: "Game", keys) -> dict:
    """From scroll_landscape's CALL draw_landscape, with the play area
    cleared, to its return: every piece begun and finished and every step
    drawn, with the screen after each."""
    game.run_to(DRAW_LANDSCAPE_CALL, 2, keys)
    clear_play_area(game.memory)
    pieces = []
    last = None
    while True:
        pc = game.run_to((PIECE_START, PIECE_DONE, LANDSCAPE_DRAWN) + STEP_DRAWN, 2, keys)
        m = game.memory
        # $D711 runs on into $D714, where the flat blitter returns: one step.
        stepped, last = pc == STEP_DRAWN[1] and last == STEP_DRAWN[0], pc
        if stepped:
            continue
        if pc == LANDSCAPE_DRAWN:
            break
        if pc == PIECE_START:
            hl = game.reg("HL")
            pieces.append({"cell": m[GROUND_CELL], "x": m[hl], "y": m[hl + 1],
                           "direction": m[hl + 2] >> 4, "steps": (m[hl + 2] & 15) or 16,
                           "screens": [], "drawn": 0})
        elif pc in STEP_DRAWN:
            pieces[-1]["screens"].append(screen_bytes(m))
        else:
            pieces[-1]["done"] = screen_bytes(m)
            pieces[-1]["drawn"] = m[PIECE_STEPS_DONE]
    return {"pieces": pieces, "screen": screen_bytes(game.memory)}


def _landscape_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    R = listing.r
    memory = bc.game_memory(snapshot)

    # ------------------------------------------------------------------
    # The terrace scene, and one pass of it stage by stage.
    log("  the terrace scene, one pass in stages...")
    game = base_game(snapshot)
    fly(game, TERRACE_FLIGHT)
    keys = ["x"]
    steps_now = landscape_pass(game, keys)
    m = game.memory
    cells = window_cells(m)
    origin = (m[ORIGIN_X], m[ORIGIN_Y])
    stage_game = game.fork()
    stops = [(DRAW_LANDSCAPE_CALL, "the ground objects, drawn first only when the "
                                   "landscape moves up"),
             (LANDSCAPE_DRAWN, "draw_landscape"),
             (SPRITES_DRAWN, "the ground objects, the beams and the stars"),
             (AFTER_SHIP_PASS, "draw_ship: the ship, its trail and its jets"),
             (AFTER_OBJECTS, "the fuel gauge, the spawner and the nine sky objects")]
    shots = [screen_bytes(stage_game.memory)]
    for address, _ in stops:
        stage_game.run_to(address, 2, keys)
        shots.append(screen_bytes(stage_game.memory))
    landscape_changed = bits_changed(shots[1], shots[2])
    play_pixels = 28 * 8 * 160
    _check(0 < landscape_changed < play_pixels // 4,
           f"draw_landscape changed {landscape_changed} pixels of {play_pixels}")
    stage_figs = []
    for (address, what), before, after in zip(stops, shots, shots[1:]):
        changed = bits_changed(before, after)
        stage_figs.append(figure(
            pictures.stage(f"landscape_stage_{address:04X}.png",
                           scaled(changed_image(before, after), 2), what),
            f"Stopped at {R(address)}: {what} -- {changed} pixels changed."))
    view_img, split_x, split_y = cell_outlines(screen_of(shots[0]), m)
    window_rows = []
    for cell in cells:
        record = cell["record"]
        marks = ", ".join(t for t, on in (("upside down", record["upside_down"]),
                                         ("mirrored", record["mirrored"])) if on) or "none"
        window_rows.append([CELL_NAMES[cell["cell"]], f"${cell['column']:02X}",
                            f"${cell['row']:02X}", f"${cell['tile']:02X}",
                            R(record["address"]), marks, len(record["pieces"])])

    # ------------------------------------------------------------------
    # What draw_landscape draws on its own.
    log("  draw_landscape on a cleared play area, piece by piece...")
    alone = draw_alone(game.fork(), keys)
    pieces = alone["pieces"]
    drawn_pieces = [p for p in pieces if p["drawn"]]
    _check(len(drawn_pieces) >= 3, f"only {len(drawn_pieces)} pieces drawn in the terrace scene")
    in_records = sum(len(c["record"]["pieces"]) for c in cells)
    _check(len(pieces) == in_records,
           f"draw_landscape began {len(pieces)} pieces; the window's records hold {in_records}")
    for piece in pieces:
        record = cells[piece["cell"]]["record"]["pieces"]
        _check(any(p["x"] == piece["x"] and p["y"] == piece["y"] for p in record),
               f"a piece at {piece['x']}, {piece['y']} is not in its cell's record")
    piece_rows = []
    for number, piece in enumerate(pieces, 1):
        cell = cells[piece["cell"]]
        piece_rows.append([number, CELL_NAMES[piece["cell"]], f"${cell['tile']:02X}",
                           f"${piece['x']:02X}", f"${piece['y']:02X}",
                           f"{piece['direction']} ({DIRECTION_NAMES[piece['direction']]})",
                           piece["steps"], piece["drawn"]])
    piece_grid = grid([play_area(screen_of(p["done"])) for p in pieces], 3)

    # One piece step by step: the sloped one with the most steps drawn,
    # what the pieces before it drew dimmed.
    sloped = [p for p in drawn_pieces if p["direction"] not in (0, 7)]
    longest = max(sloped or drawn_pieces, key=lambda p: len(p["screens"]))
    frames = longest["screens"]
    index = pieces.index(longest)
    before_piece = pieces[index - 1]["done"] if index else None
    if before_piece is None:
        before_piece = bytes(len(alone["screen"]))
    union = changed_box(before_piece, longest["done"])
    left = max(PLAY_LEFT, (union[0] - 4) & ~7)
    right = min(PLAY_RIGHT, (union[2] + 11) & ~7)
    top = max(PLAY_TOP, union[1] - 4)
    bottom = min(PLAY_BOTTOM + 1, union[3] + 4)
    step_strip = strip([byte_grid(scaled(highlight(before_piece, f).crop(
        (left, top, right, bottom)), 3), left, 3) for f in frames], gap=6)

    # ------------------------------------------------------------------
    # The four fine-scroll positions.
    log("  the four shifts...")
    shifts = {}
    shift_game = game.fork()
    target = longest
    tcell = cells[target["cell"]]
    for _ in range(80):
        shift_game.run_to(LANDSCAPE_DRAWN, 2, keys)
        sm = shift_game.memory
        fine = sm[ORIGIN_X] & 7
        if fine not in shifts:
            for w in window_cells(sm):
                if (w["column"], w["row"]) == (tcell["column"], tcell["row"]):
                    shifts[fine] = (screen_bytes(sm), w["dx"], w["dy"], _word(sm, SHIFT_TABLE))
        if len(shifts) == 4:
            break
        bc._keep_alive(sm)
        shift_game.passes(1, keys)
    _check(len(shifts) == 4, f"the flight right saw shifts {sorted(shifts)} only")
    shift_images, shift_rows = [], []
    for fine in (0, 2, 4, 6):
        kept, dx, dy, table_used = shifts[fine]
        _check(table_used == SHIFT_TABLES[fine],
               f"at fine scroll {fine} draw_landscape used ${table_used:04X}")
        # The piece's box in the cleared pass, moved by how far the cell's
        # origin has moved since.
        mx, my = _signed((dx - tcell["dx"]) & 0xFF), _signed((dy - tcell["dy"]) & 0xFF)
        sx = (target["x"] + dx) & 0xFF
        box = (union[0] - 6 + mx, union[1] - 4 + my, union[2] + 6 + mx, union[3] + 4 + my)
        shift_images.append(byte_grid(scaled(screen_of(kept).crop(box), 3), box[0], 3))
        shift_rows.append([fine, R(table_used), f"${sx:02X}", sx % 8])
    shift_strip = strip(shift_images, gap=8)

    # ------------------------------------------------------------------
    # The fly-in at a life's start.
    log("  a life's fly-in...")
    flyin = game.fork()
    flyin.play([(["a"], 0.3), bc._kill_by_fuel,
                bc.Until("a death from empty fuel", lambda mem: mem[bc.DYING] != 0, 10.0),
                bc.Until("the end of the death sequence", lambda mem: mem[bc.DYING] >= 0x50,
                         30.0)])
    fly_frames = []
    while True:
        pc = flyin.run_to((FLY_IN_PASS, bc.PLAY_LOOP), 30)
        if pc == bc.PLAY_LOOP:
            break
        fly_frames.append(screen_bytes(flyin.memory))
    fly_frames.append(screen_bytes(flyin.memory))
    _check(len(fly_frames) > 8, f"the fly-in took {len(fly_frames)} passes")
    restart = (flyin.memory[VIEW_COLUMN], flyin.memory[VIEW_ROW])
    # Without the attributes: the play area stays black on black until the
    # fly-in's last pass colours it.
    gif_frames = [play_area(screen_of(f, False)) for f in fly_frames]
    fly_gif = pictures.gif("landscape_fly_in.gif", gif_frames + [gif_frames[-1]] * 12, 100,
                           "The fly-in at the start of a life")
    pick = [0, len(fly_frames) // 4, len(fly_frames) // 2, 3 * len(fly_frames) // 4,
            len(fly_frames) - 1]

    # ------------------------------------------------------------------
    # The cost: draw_landscape's T-states over the flight.
    log("  the landscape's cost over a flight...")
    cost_game = base_game(snapshot)
    costs = []
    for flight_keys, count in TERRACE_FLIGHT:
        for _ in range(count):
            bc._keep_alive(cost_game.memory)
            cost_game.run_to(DRAW_LANDSCAPE_CALL, 2, flight_keys)
            t0 = cost_game.t
            cost_game.run_to(LANDSCAPE_DRAWN, 2, flight_keys)
            costs.append(cost_game.t - t0)
    costs.sort()
    mean_cost = sum(costs) // len(costs)

    # ------------------------------------------------------------------
    # Tables read from the game.
    direction_rows = []
    for direction in range(16):
        run, run_bytes, rise = piece_shape(memory, direction)
        if direction in (14, 15):
            run, run_bytes, rise = piece_shape(memory, direction)
        blitters = [R(_word(memory, SHIFT_TABLES[fine] + 4 * direction)) for fine in (0, 2, 4, 6)]
        direction_rows.append([direction, DIRECTION_NAMES[direction], run, run_bytes, rise,
                               f"${memory[PIECE_CLASSES + direction]:02X}"] + blitters)
    _check(piece_shape(memory, 14) == (0, 1, 16) and piece_shape(memory, 15) == (0, -1, 16),
           "the walls' shapes are not a run of 0 and a rise of 16")
    planet_rows = [[n + 1, attr_name(memory[PLANET_COLOURS + 2 * n]),
                    attr_name(memory[PLANET_COLOURS + 2 * n + 1])] for n in range(PLANETS)]
    records = [tile_record(memory, t) for t in range(TILE_COUNT)]
    empty = sum(1 for r in records if not r["pieces"])
    upside = sum(1 for r in records if r["upside_down"])
    mirrored = sum(1 for r in records if r["mirrored"])
    most = max(len(r["pieces"]) for r in records)
    _check(most <= 7, f"a tile has {most} pieces, more than a box list holds")

    images = {
        "view": pictures.stage("landscape_window.png", view_img, "The window's four cells"),
        "alone": pictures.stage("landscape_alone.png", scaled(screen_of(alone["screen"]), 2),
                                "What draw_landscape draws on a cleared play area"),
        "full": pictures.stage("landscape_full.png", scaled(screen_of(shots[2]), 2),
                               "The same pass on the real screen"),
        "pieces": pictures.piece("landscape_pieces.png", piece_grid,
                                 "draw_landscape piece by piece", 1),
        "steps": pictures.piece("landscape_steps.png", step_strip, "One piece step by step", 1),
        "shifts": pictures.piece("landscape_shifts.png", shift_strip,
                                 "One slope at the four fine-scroll positions", 1),
        "fly": pictures.piece("landscape_fly_in.png",
                              grid([gif_frames[i] for i in pick], 5),
                              "The fly-in", 1),
    }
    longest_number = pieces.index(longest) + 1
    target_number = pieces.index(target) + 1
    fill_v, fill_slope, fill_flat = R(0xD9A8), R(0xE41C), R(0xD8DA)

    return "\n".join([
        '<div class="kl-list">',
        "<p>Cyberun never scrolls the screen. Every pass of the game, the landscape of the "
        "up to four map cells the view straddles is drawn again straight onto the screen, "
        "from tile records -- each a short list of straight runs of identical steps -- by "
        "POP blitters, with graphics shifted at start-up for 0, 2, 4 and 6 pixels. Nothing "
        "is ever cleared: black sky and the ground's checker look the same after a 2-pixel "
        "move, so only the thin strips a moving edge uncovers are painted. This page takes "
        "that apart, then follows a real pass through it in the simulator.</p>",

        "<h3>The world, the map and the window</h3>",
        f"<p>The world is a ring of {MAP_COLUMNS} by {MAP_ROWS} map cells, each a page exactly "
        "the size of the play area: 224 pixels across (x 8 to $E7) and 160 lines down "
        f"(lines $18 to $B7). {R(LANDSCAPE_MAP)} holds a tile number for each, a row after "
        f"another; {R(0xE216)} finds a cell's byte and wraps the column, and {R(0xE235)} "
        "gives tile 0 for row 0, the sky, which is not stored. Map rows 0-2 hold no "
        "landscape at all.</p>",
        "<p>The view straddles at most four cells: its own (the upper left), the one below, "
        "the one to the right and the one below that. Whenever it crosses into a new cell, "
        f"{R(0xDF08)} rebuilds the <i>window</i>: the four tile records' addresses in "
        f"{R(MAP_WINDOW_TILES)}, their tile numbers in {R(MAP_WINDOW_TILE_BYTES)} (which the "
        "collision, spawning and beam code read too), and the cells' collision-box lists "
        f"({R(0x5B80)}, {R(0x5BA5)}, {R(0x5BCA)}, {R(0x5BEF)}; see "
        '<a href="LandscapeCollision.html">collision with the landscape</a>). A position on '
        f"the screen is a position in a page plus {R(ORIGIN_X)} and {R(ORIGIN_Y)}: x + "
        "origin_x for the left cells and $E0 more for the right ones (an 8-bit sum), y + "
        "origin_y for the lower cells and $A0 less for the upper.</p>",
        "<p>The scene on this page was flown to by keys from the start of a game: right "
        "along the plain, up over the first thing standing on it, and on over the drop to "
        f"the east, to map column ${cells[0]['column']:02X}, row ${cells[0]['row']:02X}. "
        f"Its window, read from the game's memory, with origin_x ${origin[0]:02X} and "
        f"origin_y ${origin[1]:02X}; the blue lines are the cells' edges on the screen "
        f"(x {split_x}, line {split_y}):</p>",
        table(["Cell", "Map column", "Map row", "Tile", "Record", "Markers", "Pieces"],
              window_rows),
        figure(images["view"], "The terrace scene, with the edges between its four map "
               "cells in blue."),

        "<h3>Tiles, pieces and steps</h3>",
        f"<p>{R(TILE_TABLE)} holds {TILE_COUNT} words, tile n's record at word n; the records "
        f"are in {R(TILE_RECORDS)}. A record is a count of <i>pieces</i> and, for each piece, "
        "its start in the page (x, and y counting down from the page's top: the piece's "
        "lowest point), a byte whose high nibble is the direction and low nibble the number "
        "of steps (0 meaning 16), and for a flat piece two end codes. Before the count "
        "there may be markers: $99 turns the tile upside down (floors become ceilings), $FF "
        "mirrors it left to right, and a byte from $95 up is skipped. That rule lets four "
        "tiles share one record -- the plain one at A, upside down at A-1 ($99), mirrored "
        "at A-2 ($FF, then the $99 skipped), and both at A-3. Decoded here the way "
        f"{R(0xD0BD)} reads them, {empty} of the {TILE_COUNT} tiles are empty (sky, rock and "
        f"the inside of a hill are all an empty tile), {upside} are upside down and "
        f"{mirrored} mirrored, and no tile has more than {most} pieces -- the seven boxes a "
        "cell's collision list holds.</p>",
        f"<p>Each of the 16 directions has a step shape, from {R(PIECE_SHAPES)} by "
        f"{R(0xE3D8)} -- a run across in pixels and in screen bytes and a rise in rows -- and "
        "a blitter and a graphic for each fine-scroll position, from four tables of 16 "
        f"four-byte entries ({R(SHIFT_TABLES[0])}, {R(SHIFT_TABLES[2])}, {R(SHIFT_TABLES[4])}, "
        f"{R(SHIFT_TABLES[6])}). Directions 7 to 13 use the shape seven lower and set "
        f"{R(0x5C35)}, and the walls the last two shapes; {R(PIECE_CLASSES)} gives the class "
        "the collision code reads. Read from the game:</p>",
        table(["Direction", "What", "Run (pixels)", "Run (bytes)", "Rise", "Class",
               "Blitter at shift 0", "2", "4", "6"], direction_rows),
        "<p>A piece is a chained line: the pieces of a tile meet end to end, and tiles meet "
        "at their edges.</p>",

        "<h3>The graphics: nine stored, four shifts, three variants</h3>",
        "<ul>"
        "<li><b>Bottom row first, zig-zag.</b> The blitters climb the screen with DEC H and "
        "each POP fetches two bytes, so a graphic is stored exactly as it is drawn: the "
        "bottom row left to right, the row above right to left, and so on up.</li>"
        "<li><b>Three variants.</b> Each graphic holds three versions of its step one above "
        f"the other. {R(0xCE24)} is a fixed jumble of 0, 1 and 2, walked one a step, and "
        f"{R(0xCCBF)} turns the variety into an offset into the graphic: a long flat run "
        "shows three stretches of texture in no visible order.</li>"
        "<li><b>Only nine graphics stored</b> (the two flat pieces, slopes 1-3, their "
        f"ceilings, and the wall, from {R(0xE581)}). A step climbing left is its partner's "
        "graphic started one row later and drawn by a blitter that turns every byte round "
        f"through {R(0xF900)}: because of the zig-zag, starting a row later makes every "
        "row's bytes arrive in the opposite order, and reversing each byte's bits finishes "
        "the mirror. Flat steps also carry four end caps, drawn instead of a variant at a "
        "run's ends.</li>"
        f"<li><b>Shifted at start-up.</b> {R(0xF86B)} makes six pages of shift tables at "
        f"$FA00-$FFFF over the loader's leftovers; then {R(0xF7EB)} makes each graphic's "
        f"copies shifted by 2, 4 and 6 ({R(0xE74A)} on, zeros on the tape): {R(0xF939)} "
        "makes a slope one byte wider and pads the open side of each row with the checker's "
        f"bits, and {R(0xF8E2)} rotates the flat rows instead, since the flat ground "
        f"repeats every 24 pixels. Last, {R(0xF856)} writes the bit-reversal table over the "
        "start-up code, which is dead by then. Every picture on this page comes from a game "
        "that has run that start-up in the simulator.</li>"
        "</ul>",

        "<h3>One pass of drawing</h3>",
        f"<p>{R(0xDDF8)} is jumped to at the end of {R(SHIP_PASS)} with this pass's steps "
        f"in {R(SCROLL_DOWN)} (signed, up positive) and {R(SCROLL_ACROSS)}. It moves the "
        "origins and the view, wraps into new cells (rebuilding the window and setting "
        f"{R(RECORD_GROUND)} so that the new pages' collision boxes are written), draws the "
        f"ground objects ({R(0xAC60)}) first if the landscape moves up, then the landscape "
        f"({R(0xD0BD)}), then the ground objects if they were not drawn first, the beams "
        f"({R(0x9BDA)}) and the stars ({R(0xBFE3)}), and jumps on to {R(0xC3E3)}. "
        f"{R(0xD0BD)} picks the blitter table for the fine scroll ({R(ORIGIN_X)} AND 7) "
        f"into {R(SHIFT_TABLE)} and works through the four cells' pieces. For each piece "
        f"{R(0xCD08)} and {R(0xCD6B)} load its shape and ends, a piece wholly off the view "
        f"is skipped by its box, and {R(0xD319)} walks its steps: advance, cull, read the "
        f"variant, pick the blitter, and draw ({R(0xD672)}, {R(0xD703)}). After the last "
        f"step SP is put back to {R(0x5B7A)}, the lip of a flat run is drawn ({R(0xD86A)}), "
        f"the strips the move uncovered are filled ({fill_v}, {fill_slope}, {fill_flat}) and "
        f"the piece is coloured ({R(0xCF38)}).</p>",
        "<p><b>The stack.</b> Interrupts are off for the whole game, so the blitters borrow "
        "SP to read their graphics with POP; instead of saving it, the renderer reloads SP "
        f"from the fixed {R(0x5B7A)} after each piece. That works only because the "
        f"landscape is always reached at the same depth -- the play loop's CALL to "
        f"{R(SHIP_PASS)}, its PUSH IY, and the CALL to {R(0xD0BD)} -- and the fly-in "
        "reaches it at the same depth too.</p>",
        f"<p>Here is one pass of the terrace scene, the ship flying right and falling (the "
        f"pass's steps: {steps_now['across']} across, {steps_now['down']} up), stopped in "
        "the simulator after each kind of drawing. Each picture is the screen after that "
        "stage, dimmed, with the pixels the stage changed in red:</p>",
        "\n".join(stage_figs),
        f"<p>{R(0xD0BD)} changed {landscape_changed} of the play area's {play_pixels} "
        "pixels: the landscape is redrawn every pass, but almost all of it exactly as it "
        "was.</p>",

        "<h3>What the renderer draws, piece by piece</h3>",
        "<p>The same pass again, but with the play area cleared to black at "
        f"{R(DRAW_LANDSCAPE_CALL)}, just before {R(0xD0BD)} is called, and the simulator "
        f"stopped at the start of each piece ({R(PIECE_START)}), after each step a blitter "
        f"drew ({R(0xD711)}) and when each piece was finished ({R(PIECE_DONE)}). What is "
        "left is exactly what the renderer writes in a pass: the steps along the surface and "
        "the strips the scroll uncovered -- and none of the inside of the hill, which is "
        "only ever painted by those strips as it comes into view.</p>",
        figure(images["alone"], "What one pass of draw_landscape writes on a cleared play "
               "area."),
        figure(images["full"], "The same pass on the screen as the game had it."),
        f"<p>The pieces in the order drawn, read from each tile's record as {R(PIECE_START)} "
        f"reached it (a mirrored tile's directions are turned round later, by {R(0xCD6B)}):</p>",
        table(["Piece", "Cell", "Tile", "x", "y", "Direction (as stored)", "Steps",
               "Steps drawn (piece_steps_done)"], piece_rows),
        figure(images["pieces"], "The play area after each piece in turn. A piece with no "
               "step on the view draws no step, though a step exactly on an edge is still "
               "counted, and the fill behind it can paint."),
        f"<p>Piece {longest_number}, step by step: each picture is the screen after "
        f"{R(0xD711)} counted another step, magnified three times, with the screen's byte "
        "boundaries in blue and what the pieces before it drew dimmed. Each step is one run of a blitter, and the next starts where "
        "the last left HL.</p>",
        figure(images["steps"], f"Piece {longest_number}'s {len(frames)} drawn steps."),

        "<h3>The blitters, and clipping by patched jumps</h3>",
        "<p>Every blitter is entered with A = the step's row pairs, HL = its screen address "
        f"less its byte advance and SP = its graphic, and ends JP {R(0xD711)} with HL where "
        "the next step starts. Each row pair is POP, write, sideways, write; up a line; POP, "
        "write back the other way; up a line with the character-row fix-up.</p>",
        table(["Blitter", "Width", "Used for", "T-states a row pair (counted)"], [
            [R(0xE24D), 3, "flat floor and ceiling at every shift", "about 170"],
            [R(0xE48B), 1, "slopes 2, 3, 9, 10 at shift 0; wall 14", "about 75"],
            [R(0xE4CF), 2, "slope 1/8 at shift 0; one-byte slopes shifted; wall shifted",
             "about 105"],
            [R(0xE4A7), 3, "slope 1/8 shifted", "about 125"],
            [R(0xE55B), 1, "5, 6, 12, 13 at shift 0; wall 15", ""],
            [R(0xE52C), 2, "4/11 at shift 0; 5, 6, 12, 13 shifted; wall 15 shifted",
             "about 150"],
            [R(0xE4F1), 3, "4/11 shifted", ""],
        ]),
        "<p><b>Clipping</b> at the sides is done by patching jump displacements, never by "
        f"testing bytes. {R(0xD588)} resets the flat blitter's three patchable JRs and "
        "patches them by the step's start column, sending the loop to cut paths "
        f"({R(0xE28E)}, {R(0xE289)}, {R(0xE283)}) that still POP the bytes they do not "
        "write, so SP stays in step. A sloped step goes through a JR at the end of "
        f"{R(0xD672)} whose displacement picks its own blitter or one of four clipping "
        f"blitters ({R(0xDB89)}, {R(0xDC47)}, {R(0xDBB7)}, {R(0xDBFD)}). Rows below line "
        "$B7 are popped away and rows above $18 dropped from the count before the dispatch; "
        "a piece wholly outside the view is skipped by its box, and a step exactly on an "
        f"edge goes to {R(0xCE5B)} or {R(0xCEDB)}, which count it without drawing.</p>",

        "<h3>The four fine-scroll positions</h3>",
        f"<p>The scroll moves 2 pixels at a time, so {R(ORIGIN_X)} AND 7 is 0, 2, 4 or 6 and "
        f"{R(0xD0BD)} picks one of the four tables. Below, the terrace scene flown right a "
        "pass at a time: the first pass seen at each fine position, each cropped to follow "
        f"piece {target_number} (so each crop shows the same piece of the world), magnified "
        "three times, with the screen's byte boundaries in blue. The picture is the same; "
        "what changes is where the bytes fall, and so which pre-shifted graphic and which "
        "blitter draw it.</p>",
        figure(images["shifts"], "The same slope at fine scroll 0, 2, 4 and 6."),
        table(["Fine scroll", "Table used", "The piece's screen x", "x within its byte"],
              shift_rows),

        "<h3>Why the screen is never cleared, and what is filled</h3>",
        "<p>Nothing clears the play area. The sky is black and the inside of the ground is "
        "the checker $55/$AA, and both are unchanged by a move of 2 pixels across or 2 rows "
        "up or down: that is why every scroll step is 2 pixels (or 4, two steps at once). "
        "Only the strips a moving edge uncovers are painted, at the end of each piece:</p>",
        "<ul>"
        f"<li><b>Up or down</b> ({R(SCROLL_DOWN)}, its size in {R(0xCE3F)}): {fill_v} walks "
        "the piece's drawn steps and paints the 2 or 4 rows just below each step (the "
        "landscape moving up) or just above (moving down), with the checker or black by the "
        "scroll's sign and whether the piece is a ceiling.</li>"
        f"<li><b>Across</b> ({R(SCROLL_ACROSS)}): a shifted step is drawn one byte wider "
        "than its run, so it covers its own old place -- except when the fine position comes "
        "back to a byte boundary. Only then is the column left behind filled: by "
        f"{fill_slope} for a slope, one byte-wide column a step, and by {fill_flat} for the "
        "drop at an end of a flat run.</li>"
        "<li><b>End caps</b> on flat runs come from the end codes: a cap graphic, a drop at "
        f"an end, or a one-byte lip ({R(0xD851)}, {R(0xD85E)}, drawn by {R(0xD86A)}).</li>"
        "</ul>",
        "<p>Because only the edges repair what lies behind them, the play area has to start "
        "in a known state, and the fly-in is what gets it there.</p>",

        "<h3>Colour</h3>",
        f"<p>{R(0xCF38)} colours a column of attribute cells per step (one to three cells "
        "wide), only inside the play area. The colour is the planet's: the first of its "
        f"pair above map row 12, the second from row 12 down -- the caverns. "
        f"{R(PLANET_COLOURS)} holds the five planets' pairs, copied by {R(0xDCA1)} and "
        f"chosen by {R(0xDEE1)}; read from the game:</p>",
        table(["Planet", "Surface", "Caverns"], planet_rows),

        "<h3>A life starts: the fly-in</h3>",
        f"<p>Every fourth pass {R(0xC33C)} saves the view's place as the next life's start, "
        "but only at a safe place: the bottom pixel row of the play area all checker (over "
        f"flat ground), or all four cells sky or cloud. At a life's start {R(0xDCA1)} puts "
        "the view one map row below that place, fills the play area with the checker if the "
        f"place was over ground, and with {R(MAP_REBUILD)} at $FF lets the view rise 4 lines "
        "a pass, the moving edges' fills painting the landscape in; "
        f"{R(0xDD79)} ends it when the ship's place on the screen is clear, or after 40 "
        "passes. Below, the life after a death in the terrace scene (the tank emptied there "
        f"in the simulator), stopped at each pass of the fly-in ({R(FLY_IN_PASS)}): "
        f"{len(fly_frames) - 1} passes, ending at map column ${restart[0]:02X}, row "
        f"${restart[1]:02X}, the last safe place the game had saved.</p>",
        figure(fly_gif, "The fly-in, a pass a frame, drawn without the attributes: the "
               "play area is black on black until its last pass colours it."),
        figure(images["fly"], "The first pass, a quarter, half and three-quarters of the way "
               "through, and the first pass of play."),

        "<h3>What it costs</h3>",
        f"<p>Measured in the simulator over the {len(costs)} passes of the flight to the "
        f"terrace scene, from {R(DRAW_LANDSCAPE_CALL)} to {R(LANDSCAPE_DRAWN)}: {R(0xD0BD)} "
        f"took {costs[0]:,} to {costs[-1]:,} T-states a pass, {mean_cost:,} on average -- "
        f"{100 * mean_cost / FRAME:.0f} per cent of a television frame. A whole flat step "
        "is about 400 T-states to blit (counted from the instruction timings), less than "
        f"the deciding done for it in {R(0xD319)} and {R(0xD588)}.</p>",

        "<h3>For a game of your own</h3>",
        "<ul>"
        "<li>The world is a byte per page, a tile list of pieces, and nine small graphics.</li>"
        "<li>Draw everything visible every pass, straight to the screen, on a background "
        "that is the same after a scroll step (black and a 2-pixel checker here), so "
        "nothing needs clearing; repair only the strips moving edges uncover.</li>"
        "<li>Pre-shift at start-up into memory that held the start-up code, and keep one "
        "256-byte bit-reversal page: with zig-zag storage it halves the slope art.</li>"
        "<li>Clip with jump displacements patched once per step, and let the cut paths POP "
        "the bytes they skip.</li>"
        "</ul>",

        confirmed([
            "Run in the simulator when this page was built: the flight to the terrace scene; "
            "one pass stopped after each kind of drawing; the same pass on a cleared play "
            "area, piece by piece and step by step; the four fine-scroll positions; a "
            "life's fly-in; the cost of draw_landscape over the flight.",
            "Read from the game's memory: the window, the tile records, the directions' "
            "shapes, classes and blitters, the planets' colours.",
            "Read from the code: the blitters' entry and exit, the clipping by patched "
            "jumps, the fills and the colouring. The blitters' costs are counted from the "
            "instruction timings, not measured.",
            "Inferred: that the background's sameness under a 2-pixel move is why the "
            "scroll steps by 2. Never seen run in this build: upside-down tiles and walls, "
            "so their rows in the tables are read only.",
        ]),
        "</div>"])


# --------------------------------------------------------------------------
# Collision with the landscape.
# --------------------------------------------------------------------------

COLLIDE_CALL = 0xC3C5           # ship_pass: CALL collide_with_landscape
AFTER_COLLIDE = 0xC3C8          # ...and after it
SHIP_ACROSS_SPEED = 0xC8FE      # 8.8, high byte first; a push right is negative
SHIP_DOWN_SPEED = 0xC900        # the climb speed: thrust positive
EVENTS = 0x5C35                 # piece_ceiling, in the collision code: this pass's events
SHIP_ON_SLOPE = 0xBC12
BOX_COLOURS = {"floor": (255, 230, 0), "ceiling": (0, 230, 255), "wall": (60, 255, 60),
               "slope": (255, 70, 70)}


def speed(memory, address: int) -> float:
    """An 8.8 speed stored high byte first, in units of 2 pixels a pass."""
    return _signed16(memory[address] << 8 | memory[address + 1]) / 256


def box_kind(cls: int) -> str:
    if cls & 0x04:
        return "floor"
    if cls & 0x08:
        return "ceiling"
    if cls & 0x30:
        return "wall"
    return "slope"


def read_boxes(memory) -> list[dict]:
    """The four cells' collision-box lists, each box with its corners on the
    screen worked out from the view (8 - view_x across, $E0 more for the
    right-hand cells; $B7 - view_y down, $A0 less for the upper ones)."""
    boxes = []
    across = 8 - memory[VIEW_X]
    down = 0xB7 - memory[VIEW_Y]
    for cell, base in enumerate(BOX_LISTS):
        dx = across + (0xE0 if cell & 2 else 0)
        dy = down - (0 if cell & 1 else 0xA0)
        count = memory[base]
        for n in range(count):
            a = base + 1 + 5 * n
            x, y, w, h, cls = memory[a:a + 5]
            box = {"cell": cell, "address": a, "bytes": (x, y, w, h, cls),
                   "kind": box_kind(cls), "class": cls}
            if box["kind"] == "slope":
                box["line"] = (x + dx, y + dy, w + dx, h + dy)
            else:
                box["rect"] = (x + dx, y + dy - h + 1, x + dx + w, y + dy + 1)
            boxes.append(box)
    return boxes


def draw_boxes(image, boxes, scale: int = 2):
    """The boxes over a screen picture `scale` times its size, clipped to
    the play area: blocks outlined, slopes as their lines."""
    from PIL import Image, ImageDraw

    big = scaled(image, scale)
    layer = Image.new("RGB", big.size)
    draw = ImageDraw.Draw(layer)
    for box in boxes:
        colour = BOX_COLOURS[box["kind"]]
        if "line" in box:
            x0, y0, x1, y1 = box["line"]
            draw.line([(x0 * scale, y0 * scale), (x1 * scale, y1 * scale)], fill=colour,
                      width=3)
        else:
            x0, y0, x1, y1 = box["rect"]
            draw.rectangle([x0 * scale, y0 * scale, x1 * scale - 1, y1 * scale - 1],
                           outline=colour, width=2)
    mask = Image.new("L", big.size, 0)
    ImageDraw.Draw(mask).rectangle([PLAY_LEFT * scale, PLAY_TOP * scale,
                                    PLAY_RIGHT * scale - 1, (PLAY_BOTTOM + 1) * scale - 1],
                                   fill=255)
    lit = Image.eval(layer.convert("L"), lambda v: 255 if v else 0)
    from PIL import ImageChops
    big.paste(layer, (0, 0), ImageChops.multiply(lit, mask))
    return big


def log_collisions(game: "Game", plan, alive: bool = True) -> list[dict]:
    """Each pass of `plan`, the ship's speeds just before and just after
    collide_with_landscape, and what the test did."""
    rows = []
    m = game.memory
    for keys, count in plan:
        for _ in range(count):
            if alive:
                bc._keep_alive(m)
            game.run_to(COLLIDE_CALL, 2, keys)
            before = (speed(m, SHIP_ACROSS_SPEED), speed(m, SHIP_DOWN_SPEED))
            game.run_to(AFTER_COLLIDE, 2, keys)
            # ship_pass copies the record's steps into the two speeds at $C3CB.
            after = (speed(m, 0xC8EC), speed(m, 0xC8EE))
            rows.append({"keys": keys, "before": before, "after": after,
                         "events": m[EVENTS], "slope": m[SHIP_ON_SLOPE],
                         "view_y": m[VIEW_Y]})
            game.passes(1, keys)
    return rows


def _collision_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    R = listing.r
    memory = bc.game_memory(snapshot)

    # The terrace scene's boxes over its screen.
    log("  the terrace scene's collision boxes...")
    game = base_game(snapshot)
    fly(game, TERRACE_FLIGHT)
    game.run_to(LANDSCAPE_DRAWN, 2, ["x"])
    m = game.memory
    boxes = read_boxes(m)
    cells = window_cells(m)
    for cell, base in enumerate(BOX_LISTS):
        _check(m[base] == len(cells[cell]["record"]["pieces"]),
               f"cell {cell}'s list holds {m[base]} boxes for "
               f"{len(cells[cell]['record']['pieces'])} pieces")
    _check(any(b["kind"] == "floor" for b in boxes) and any(b["kind"] == "slope" for b in boxes),
           "the terrace scene has no floor box or no slope box")
    screen = screen_bytes(m)
    boxed = draw_boxes(screen_of(screen), boxes)
    box_rows = []
    for box in boxes:
        x, y, w, h, cls = box["bytes"]
        box_rows.append([CELL_NAMES[box["cell"]], R(box["address"]),
                         " ".join(f"${v:02X}" for v in box["bytes"]), box["kind"],
                         (f"x ${x:02X} to ${w:02X}, line ${y:02X} to ${h:02X}"
                          if box["kind"] == "slope" else
                          f"x ${x:02X}, {w} wide; {h} lines up from line ${y:02X}")])

    # A second scene: the long slope west of the start.
    hill = base_game(snapshot)
    fly(hill, HILL_FLIGHT)
    hill.run_to(LANDSCAPE_DRAWN, 2, ["x"])
    hill_boxes = read_boxes(hill.memory)
    hill_img = draw_boxes(screen_of(screen_bytes(hill.memory)), hill_boxes)

    # A fall onto the plain at the start, and the bounces.
    log("  a fall onto flat ground...")
    fall = base_game(snapshot)
    fly(fall, [(["a"], 12)])
    fall_rows = log_collisions(fall, [([], 70)])
    bounces = [i for i, r in enumerate(fall_rows) if r["events"] & 0x40]
    _check(bounces, "the ship fell onto the plain and never bounced")
    first = fall_rows[bounces[0]]
    _check(abs(first["after"][1] + first["before"][1] / 2) < 0.02,
           f"a floor bounce took the climb speed from {first['before'][1]} to "
           f"{first['after'][1]}, not minus half")
    stopped = next((i for i, r in enumerate(fall_rows)
                    if r["events"] & 0x80 and not r["events"] & 0x40), None)
    _check(stopped is not None, "the ship never came to rest on the plain")
    show = sorted(set(range(max(0, bounces[0] - 2), bounces[0] + 2))
                  | set(range(max(0, stopped - 2), stopped + 2)))
    fall_table = [[n, f"{fall_rows[n]['before'][1]:+.3f}", f"{fall_rows[n]['after'][1]:+.3f}",
                   f"${fall_rows[n]['events']:02X}",
                   "bounce" if fall_rows[n]["events"] & 0x40 else
                   "a block hit, the speed in the dead band: stopped"
                   if fall_rows[n]["events"] & 0x80 else ""] for n in show]

    # Into the long slope.
    log("  into a slope...")
    slope = base_game(snapshot)
    fly(slope, HILL_FLIGHT[:-1])
    slope_rows = log_collisions(slope, [(["z"], 24)])
    slope_hits = [i for i, r in enumerate(slope_rows) if r["events"] & 0x10]
    _check(slope_hits, "flying into the slope never touched it")
    hit = slope_rows[slope_hits[0]]
    _check(hit["after"] == (hit["before"][1], hit["before"][0]),
           f"the slope bounce took {hit['before']} to {hit['after']}, not swapped")
    slope_box = next(b for b in hill_boxes if b["kind"] == "slope" and b["class"] & 0x43 == 0x42)
    slope_table = [[n, f"{r['before'][0]:+.3f}", f"{r['before'][1]:+.3f}",
                    f"{r['after'][0]:+.3f}", f"{r['after'][1]:+.3f}", f"${r['events']:02X}",
                    "yes" if r["slope"] & 0x80 else ""]
                   for n, r in enumerate(slope_rows[:16])]

    class_rows = [[d, DIRECTION_NAMES[d], f"${memory[PIECE_CLASSES + d]:02X}",
                   box_kind(memory[PIECE_CLASSES + d])] for d in range(16)]
    images = {
        "boxes": pictures.stage("collision_boxes.png", boxed, "The terrace scene's boxes"),
        "hill": pictures.stage("collision_boxes_hill.png", hill_img, "The hill's boxes"),
    }
    key = ", ".join(f'<span style="color:rgb{c}">{k}</span>' for k, c in BOX_COLOURS.items())

    return "\n".join([
        '<div class="kl-list">',
        "<p>The ship bounces off hillsides, the attackers slide down slopes and the lasers "
        "stop at the ground, and all of it comes from boxes. While a cell is first drawn, "
        "each piece also writes a 5-byte box into that cell's list; a moving thing's box is "
        "placed where its speed would take it, cut into the parts that lie in each cell, and "
        "tested against those cells' boxes. Floors, ceilings and walls reverse and halve the "
        "speed into them; slopes reflect it.</p>",

        "<h3>The boxes, made while drawing</h3>",
        f"<p>Each of the four cells on the screen has a list of 37 bytes: a count, then up "
        f"to seven boxes, one per piece of the cell's tile -- {R(0x5B80)} for the view's "
        f"cell (over the loader's entry, dead once the game runs), {R(0x5BA5)} below it, "
        f"{R(0x5BCA)} to its right and {R(0x5BEF)} below and right; {R(0xB944)} is an "
        f"empty list for a cell off the screen. {R(0xD0BD)} writes the count every pass, "
        f"but the boxes only while {R(RECORD_GROUND)} is set: when {R(0xDDF8)} has wrapped "
        "into a new cell this pass, or while the screen is built after a restart. A box, "
        "in the page's coordinates (y counting down, a block spanning its height upwards "
        "from its bottom line):</p>",
        table(["Offset", "Flat piece", "Wall", "Slope"], [
            ["+0", "x", "x (16 less for direction 15)",
             "x of one end (a slope running left starts a step further right)"],
            ["+1", "bottom line: y + 16 for a floor, y for a ceiling", "y", "that end's y"],
            ["+2", "width: 24 a step", "$18", "x of the far end"],
            ["+3", "height: 20", "16 a step", "y of the far end"],
            ["+4", "class", "class", "class"],
        ]),
        f"<p>The class is {R(PIECE_CLASSES)}'s byte for the piece's direction: bits 0-1 the "
        "slope's steepness (1 gentle, 2 45 degrees, 3 steep), bit 2 a flat floor, bit 3 a "
        "flat ceiling, bits 4 and 5 the two walls, bit 6 a slope climbing left, bit 7 a "
        "ceiling slope. Any of bits 2-5 makes a <i>block</i>; none, a <i>slope</i>. Read "
        "from the game:</p>",
        table(["Direction", "Piece", "Class", "Tested as"], class_rows),

        "<h3>A screen's boxes</h3>",
        f"<p>The terrace scene from <a href=\"Landscape.html\">the landscape page</a>, "
        f"stopped after {R(0xD0BD)} has run, and the four lists read out of the game's "
        "memory; each box is drawn where the view puts it on the screen (" + key +
        "), clipped to the play area:</p>",
        figure(images["boxes"], "The terrace scene with its collision boxes."),
        table(["Cell", "Box at", "Bytes", "Kind", "In the page"], box_rows),
        "<p>A floor's box is a 20-line slab whose top is the surface's top line, and a "
        "slope's is the line from one end of its run of steps to the other, which the test "
        "turns into a staircase by the slope's steepness. The long slope west of the start, "
        "flown to the same way:</p>",
        figure(images["hill"], "The long slope west of the start, with its boxes."),

        "<h3>Testing a move</h3>",
        f"<p>{R(0xBA21)} is given a record in IX, a width in C, a height in B and who is "
        f"testing in {R(0x5C25)} ($FF the ship, $80 a shot's probe or an object that "
        f"explodes, 0 an object that bounces). {R(0xBE8F)} places the record's box where "
        f"this pass's speed would take it ({R(0xB980)}, {R(0xB9BB)}, without storing it), "
        f"finds the cell's list ({R(0xB946)}), and cuts the box into the parts inside each "
        "cell: placed by its bottom-left corner, it can stick out only to the right and "
        f"above, so there are 1, 2 or 4 parts. Each part is tested against its own cell's "
        f"boxes ({R(0xBA2E)}, {R(0xBA4D)}, {R(0xBE43)}): a block by {R(0xBA8F)}, a slope by "
        f"{R(0xBC13)}. Every overlap test, here and for every sprite contact in the game, is "
        f"{R(0x9DB1)}: a handful of 8-bit compares, at most seven boxes a cell and four "
        f"parts, 28 a pass. {R(EVENTS)} keeps what has happened this pass: bit 7 a block hit "
        "(no more blocks tested), bit 6 a bounce (no more boxes at all), bit 4 a slope hit "
        "(no more slopes).</p>",
        "<p>The ship's box is 48 pixels wide and its picture's height plus 4; the shots' "
        "probes are 24 by 12 (24 by 16 for the special beam); the objects' boxes go by "
        "type (34 by 35 for an attacker, 48 by 32 for a cloud).</p>",

        "<h3>Blocks: floors, ceilings, walls</h3>",
        f"<p>{R(0xBA8F)} tests a block only if the record is moving into it or still: a floor "
        "while it falls, a ceiling while it rises, a wall by the way it moves across. On a "
        f"hit the speed into it is negated, halved ({R(0xBE03)}), clamped to whole parts "
        f"-3 to +2 ({R(0xC880)}) and put through a dead band ({R(0xBA0B)}: anything from "
        "-$A8 to +$63 in 256ths becomes 0). Still moving, it is a bounce; the ship's new "
        f"speed sets this pass's step at once ({R(0xB234)}) with a bump "
        f"({R(0x7293)}).</p>",
        f"<p>Worked example: at the start of a game the ship thrust up for 12 passes and "
        f"then left to fall onto the plain, the simulator stopped at {R(COLLIDE_CALL)} and "
        f"{R(AFTER_COLLIDE)} in {R(SHIP_PASS)} every pass. The climb speed (up positive, in "
        "units of 2 pixels a pass) gains a quarter downwards a pass from gravity until the "
        "ship meets the floor's box; then it comes back up at half the speed, and the "
        "bounces die away until one falls inside the dead band and the ship sits still:</p>",
        table(["Pass", "Climb speed before", "After", "Events", ""], fall_table),
        f"<p>Pass {bounces[0]}: {first['before'][1]:+.3f} became {first['after'][1]:+.3f}, "
        "minus half. Between the bounces other things nudged the ship (a touch from an "
        "attacker pushes it), which is why the later bounces are not neat halves.</p>",

        "<h3>Slopes</h3>",
        f"<p>One slope a pass. {R(0x9E35)} tests the part against the slope's shape by class "
        f"bits 6 and 7 -- as stored, mirrored ({R(0x9EA5)}, {R(0x9E7A)}), upside down "
        f"({R(0x9EC0)}) or both ({R(0x9ED9)}) -- and {R(0x9DEE)} finds how far the part "
        "reaches under the slope's edge, scaled by the steepness, into "
        f"{R(0x5C1A)}. Then, with U the speed across (left positive) and V up and down (up "
        "positive), the speeds are reflected:</p>",
        table(["Slope", "Routine", "New U", "New V"], [
            ["45 degrees, climbing right", R(0xBD04), "-V", "-U"],
            ["45 degrees, climbing left", R(0xBD3B), "V", "U"],
            ["gentle, climbing right", R(0xBD44), "3/8 U - 3/8 V", "-3/4 V - 3/4 U"],
            ["gentle, climbing left", R(0xBDBD), "3/8 U + 3/8 V", "-3/4 V + 3/4 U"],
            ["steep", "the same two", "the gentle rule with U and V swapped before and "
             f"after ({R(0xBDD8)})", ""],
        ]),
        "<p>The 45-degree rows are exact reflections off the lines y = x and y = -x; the "
        f"others' cross terms go through {R(0xBDC8)}, which negates the whole word for a "
        "ceiling or steep slope and only the whole part otherwise, so they are approximate. "
        "Every factor is under 1: every slope bounce loses speed. The negations are switched "
        "on and off by two JRs whose displacements each routine patches. After a slope "
        f"({R(0xBC5B)}) an object is pushed out by the depth and may slide downhill "
        f"({R(0xBCBF)}); the ship ({R(0xBCD1)}) stops scrolling for the pass, and on its "
        f"second pass in a row on a slope ({R(SHIP_ON_SLOPE)}) slides 2 pixels downhill.</p>",
        "<p>Worked example: the flight to the long slope west of the start, then 24 passes "
        "holding left into it, the speeds read either side of the test (the speed across "
        "is kept in the scroll's sense, so steering left is positive):</p>",
        table(["Pass", "Across before", "Up before", "Across after", "Up after", "Events",
               "On the slope"], slope_table),
        f"<p>Pass {slope_hits[0]}: the ship touched the slope, a 45-degree one climbing "
        f"left (class ${slope_box['class']:02X}), and the two speeds were swapped, "
        f"{hit['before'][0]:+.3f} across and {hit['before'][1]:+.3f} up becoming "
        f"{hit['after'][0]:+.3f} and {hit['after'][1]:+.3f}, as {R(0xBD3B)} says; "
        "steering left builds the speed across up again until the next touch. (The listing's "
        "sessions never ran this rule; it ran here.)</p>",
        "<p>A bounce off the landscape changes the speeds before anything is drawn: "
        f"{R(SHIP_PASS)} works out the scroll from them, so the ship never visibly enters "
        "the ground.</p>",

        "<h3>For a game of your own</h3>",
        "<ul>"
        "<li>Make the collision shapes as a by-product of the drawing data, one box per "
        "piece, and only when the set of cells on the screen changes.</li>"
        "<li>Keep shapes per cell and cut a moving box at cell edges into at most four "
        "parts, so every comparison is 8-bit.</li>"
        "<li>Test only the faces a thing moves into, reverse and halve, and zero anything in "
        "a small dead band so that bounces die away instead of jittering.</li>"
        "</ul>",
        confirmed([
            "Run in the simulator when this page was built: the two scenes' boxes, read from "
            "the lists after draw_landscape, each list's count checked against its tile's "
            "pieces; the fall onto the plain and the flight into the slope, with the speeds "
            "either side of the test.",
            "Read from the code: the box format, the classes' meaning, the parts, the block "
            "and slope rules. The signs of the gentle and steep slopes' cross terms are as "
            "the listing reads the routines, not measured.",
            "Never seen run in this build: ceilings, walls and upside-down slopes, so their "
            "rules are read only.",
        ]),
        "</div>"])


# --------------------------------------------------------------------------
# Drawing: the compositor and the direct drawer.
# --------------------------------------------------------------------------

DRAW_SPRITE_PAIR = 0xA303
COPIED_IN = 0xA43E              # erase_old_draw_new: the box is in the buffer
ERASED = 0xA469                 # ...the old image rubbed out
DRAWN = 0xA498                  # dissolve_sprite: the new image drawn in
DISSOLVED = 0xA4CB              # ...the copy back begins
SPRITE_BUFFER = 0xF800
CURRENT_OBJECT = 0xAD46
OBJECT_RECORDS = 0x9974
OBJECT_RECORD_SIZE = 24
OBJECT_RECORD_COUNT = 9
ATTACKER_TYPES = (0x14, 0x16, 0x17, 0x18, 0x1A)
OLD_X, OLD_Y, NEW_X, NEW_Y, OLD_ROWS, NEW_ROWS = 0xA1D3, 0xA1D4, 0xA1D5, 0xA1D6, 0xA1D7, 0xA1D8
OLD_WIDTH, NEW_WIDTH = 0xA2F8, 0xA2F9
BOX_LEFT, BOX_BOTTOM, BOX_WIDTH, BOX_RISE = 0x5C2C, 0x5C2D, 0xCE35, 0xCE37
ROW_ROUTINES = 0xA294           # erase_row_routines; draw_row_routines follows at $A2AA
DRAW_DIRECT_PAIR = 0xA59F
DIRECT_ROWS = (0xA61C, 0xA66F)  # direct_next_pair, direct_then_new_row
DRAW_SHIP_IMAGE = 0xC421
SHIP_FACING = 0xC8FD


def buffer_rows(buffer: bytes, width: int, rows: int) -> list[bytes]:
    """The compositor's buffer (the 256 bytes from $F800) as rows, top row
    first (it is filled bottom row first)."""
    return [bytes(buffer[r * width:(r + 1) * width]) for r in range(rows - 1, -1, -1)]


def screen_rows(memory, left: int, bottom: int, width: int, rows: int) -> list[bytes]:
    """A rectangle of the display, top row first."""
    out = []
    for y in range(bottom - rows + 1, bottom + 1):
        a = screen_address(left, y)
        out.append(bytes(memory[a:a + width]))
    return out


def outline_images(image, scale: int, rects):
    """Rectangles (x, top, width, height in pixels, colour) over a picture
    already `scale` times its size."""
    from PIL import ImageDraw

    draw = ImageDraw.Draw(image)
    for x, top, width, height, colour in rects:
        draw.rectangle([x * scale, top * scale, (x + width) * scale - 1,
                        (top + height) * scale - 1], outline=colour, width=1)
    return image


def _drawing_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    R = listing.r
    memory = bc.game_memory(snapshot)

    # ------------------------------------------------------------------
    # One object through the compositor.
    log("  an attacker through the compositor...")
    game = base_game(snapshot)
    fly(game, [(["x"], 100)])
    m = game.memory
    found = None
    for _ in range(2000):
        game.run_to(DRAW_SPRITE_PAIR, 5, ["x"])
        obj = _word(m, CURRENT_OBJECT)
        if (OBJECT_RECORDS <= obj < OBJECT_RECORDS + OBJECT_RECORD_SIZE * OBJECT_RECORD_COUNT
                and m[obj] in ATTACKER_TYPES and m[OLD_ROWS] and m[NEW_ROWS]
                and m[NEW_X] & 7 and m[OLD_X] != m[NEW_X] and not m[0xA2FA]):
            found = obj
            break
        bc._keep_alive(m)
    _check(found is not None, "no attacker moved through the compositor")
    index = (found - OBJECT_RECORDS) // OBJECT_RECORD_SIZE
    old = (m[OLD_X], m[OLD_Y], m[OLD_ROWS])
    new = (m[NEW_X], m[NEW_Y], m[NEW_ROWS])
    record = bytes(m[found:found + OBJECT_RECORD_SIZE])
    returns = _word(m, game.reg("SP"))
    t0 = game.t
    before = screen_bytes(m)
    stages = {}
    for stop in (COPIED_IN, ERASED, DRAWN, DISSOLVED):
        game.run_to(stop, 1, ["x"])
        stages[stop] = bytes(m[SPRITE_BUFFER:SPRITE_BUFFER + 256])
        if stop == COPIED_IN:
            # The box as draw_sprite_pair worked it out (the variables are
            # borrowed, so read them now).
            left, bottom, width, rows = (m[BOX_LEFT], m[BOX_BOTTOM], m[BOX_WIDTH],
                                         m[BOX_RISE] - 1)
            widths = (m[OLD_WIDTH], m[NEW_WIDTH])
    game.run_to(returns, 1, ["x"])
    cost = game.t - t0
    after = screen_bytes(m)
    _check(width <= 7 and rows * width <= 256, f"a box of {width} bytes by {rows} rows")
    full_before = [0] * 0x4000 + list(before)
    full_after = [0] * 0x4000 + list(after)
    copied = buffer_rows(stages[COPIED_IN], width, rows)
    _check(copied == screen_rows(full_before, left, bottom, width, rows),
           "the buffer after the copy in is not the screen's rectangle")
    final = buffer_rows(stages[DISSOLVED], width, rows)
    _check(final == screen_rows(full_after, left, bottom, width, rows),
           "the screen's rectangle after the copy back is not the buffer")
    top = bottom - rows + 1
    scale = 4

    def boxed(rows_top_first):
        image = scaled(bitmap_image(rows_top_first, width), scale)
        rects = []
        # The old image in red and the new in green, at their places in the
        # box (a shifted image spans one byte more).
        for (x, y, n), w, colour in ((old, widths[0], (255, 70, 70)),
                                     (new, widths[1], (70, 255, 70))):
            span = w * 8 + (8 if x & 7 else 0)
            rects.append((x - left, y - n + 1 - top, min(span, width * 8 - (x - left)), n,
                          colour))
        return outline_images(image, scale, rects)

    stage_images = [
        boxed(screen_rows(full_before, left, bottom, width, rows)),
        boxed(copied), boxed(buffer_rows(stages[ERASED], width, rows)),
        boxed(buffer_rows(stages[DRAWN], width, rows)),
        boxed(screen_rows(full_after, left, bottom, width, rows))]
    context = screen_of(after)
    context_img = outline_images(scaled(context, 2), 2, [(left, top, width * 8, rows,
                                                          (255, 255, 0))])
    row_words = [_word(memory, ROW_ROUTINES + 2 * n) for n in range(22)]

    # ------------------------------------------------------------------
    # The ship turning: the direct drawer.
    log("  the ship turning, row by row...")
    ship = base_game(snapshot)
    fly(ship, [(["a", "x"], 30)])
    sm = ship.memory
    facing_before = sm[SHIP_FACING]
    _check(not facing_before & 0x80, "the ship was not facing right before the turn")
    turned = None
    for _ in range(80):
        ship.run_to(DRAW_DIRECT_PAIR, 5, ["z"])
        back = _word(sm, ship.reg("SP"))
        if DRAW_SHIP_IMAGE <= back < 0xC4ED and sm[0x5C1C] and sm[0x5C1D]:
            turned = back
            break
    _check(turned is not None, "the ship never turned")
    _check(sm[SHIP_FACING] & 0x80, "the ship turned but does not face left")
    ship_rows = (sm[0x5C1C], sm[0x5C1D])
    t0 = ship.t
    frames = [screen_bytes(sm)]
    row_stops = 0
    while True:
        pc = ship.run_to(DIRECT_ROWS + (turned,), 1, ["z"])
        frames.append(screen_bytes(sm))
        if pc == turned:
            break
        row_stops += 1
    ship_cost = ship.t - t0
    box = changed_box(frames[0], frames[-1])
    crop = (box[0] - 4, box[1] - 3, box[2] + 4, box[3] + 3)
    ship_frames = [scaled(screen_of(f, False).crop(crop), 3) for f in frames]
    picks = sorted(set(round(i * (len(frames) - 1) / 7) for i in range(8)))
    ship_strip = strip([ship_frames[i] for i in picks], gap=6)

    images = {
        "context": pictures.stage("drawing_context.png", context_img,
                                  "Where the compositor's box lies"),
        "stages": pictures.piece("drawing_compositor.png", strip(stage_images, gap=10),
                                 "The compositor's five stages", 1),
        "ship": pictures.piece("drawing_ship_turn.png", ship_strip,
                               "The ship turning, row by row", 1),
        "ship_gif": pictures.gif("drawing_ship_turn.gif", ship_frames + [ship_frames[-1]] * 8,
                                 80, "The ship turning, a stop a frame", 1),
    }
    pass_frames = round(cost / FRAME * 100)

    return "\n".join([
        '<div class="kl-list">',
        "<p>Nothing in Cyberun has a mask, and there is no screen buffer. Two drawers put "
        f"moving things on the screen. The <i>compositor</i>, {R(DRAW_SPRITE_PAIR)}, handles "
        "every object and star: it copies the screen rectangle covering an object's old and "
        "new images into a small buffer, rubs the old image out there, draws the new one in "
        "and copies the rectangle back -- one write to the screen per object, so nothing "
        f"flickers. The <i>direct drawer</i>, {R(DRAW_DIRECT_PAIR)}, handles the ship, its "
        "trail, its jets and the part it carries: no buffer, but a row of the old image "
        "rubbed out and a row of the new drawn in turn, straight on the screen. This page "
        "follows one attacker and one turn of the ship through them in the simulator.</p>",

        "<h3>Graphics</h3>",
        "<p>A sprite is a byte of width in bytes, a byte of height in lines, then the lines "
        "<b>bottom line first</b>, with no mask: everything is drawn upwards from its bottom "
        f"line ({R(0xA1C3)}, {R(0xA1B3)}), so a position's y is its bottom line. Which "
        f"picture an object shows comes from {R(0xAF3D)} -- a word per graphic number "
        "pointing at a list of frames -- and the frame in bits 0-3 of the record's +$13 "
        f"({R(0xADBE)}). Colour is never part of a sprite: {R(0xAE98)} paints the cells an "
        "image covers from the record's +$0D, which holds two colours, one shown on odd "
        "passes and one on even ones, so two different nibbles flash for nothing.</p>",

        "<h3>The compositor</h3>",
        "<p>Every object goes through the same sequence each pass:</p>",
        "<ul>"
        f"<li>{R(0xA2EA)}: no old image, no new image.</li>"
        f"<li>{R(0xAD27)}: if it was drawn last pass, the old image is its graphic as it still "
        f"is, at the place kept in +$11/+$12, cut to the play area by {R(0xA1FB)}.</li>"
        "<li>The object's update moves it.</li>"
        f"<li>{R(0xAD48)}: {R(0xADD8)} decides whether and where it shows; the new image "
        "is set up, with its colour and any dissolve step.</li>"
        f"<li>{R(0xAD1B)} jumps to {R(DRAW_SPRITE_PAIR)} if either image exists; then "
        f"{R(0xAE98)} paints the colour.</li>"
        "</ul>",
        f"<p>Inside {R(DRAW_SPRITE_PAIR)}:</p>",
        "<ol>"
        "<li><b>The box</b>: the smallest rectangle, whole bytes wide, covering both images "
        f"-- left edge in {R(BOX_LEFT)}, bottom line in {R(BOX_BOTTOM)}, width in bytes (at "
        f"most 7) in {R(BOX_WIDTH)} and rows + 1 in {R(BOX_RISE)}, landscape variables "
        "borrowed.</li>"
        f"<li><b>Copy in</b> ({R(0xA3F6)}): rows bottom-up into the buffer at "
        f"{R(SPRITE_BUFFER)}, packed at the box's width. The loop is PUSH HL, a DJNZ whose "
        "displacement is patched to land the right number of LDIs from the end of a chain "
        "of seven, POP HL, up a line: a copy of any width with no counter per byte.</li>"
        f"<li><b>Rub out the old image</b> ({R(0xA43E)}): an unrolled row loop entered "
        f"through IY at the step for the width, from {R(0xA294)}. Aligned ({R(0xA6B2)}): "
        f"LD A,(DE) / CPL / AND (HL) / LD (HL),A. Shifted ({R(0xA6E1)}): each graphic "
        "byte looked up twice in the shift tables -- the part staying in this byte and the "
        "part spilling into the next -- each complemented and ANDed in.</li>"
        f"<li><b>Draw the new image</b> the same way with OR ({R(0xA733)}, {R(0xA75C)}), "
        f"through IX and {R(0xA2AA)}.</li>"
        f"<li><b>Dissolve</b> ({R(0xA498)}), only for a destroyed object: its new image ANDed "
        "with a mask that loses a bit a pass.</li>"
        f"<li><b>Copy back</b> ({R(0xA54B)}), the same PUSH, patched DJNZ and LDI chain; "
        "column 0 and everything right of x $E8 (the fuel gauge's columns) are never "
        "written.</li>"
        "</ol>",
        "<p><b>Shifting.</b> x is always even, so there are four positions; "
        f"{R(0xA25D)} picks the shift tables {R(0xF86B)} made at start-up (page n the byte "
        "shifted right, page n+1 the bits that fall into the next byte). An aligned image "
        "never uses them; a shifted one covers its width + 1 bytes.</p>",
        "<p><b>Erase is not restore.</b> AND NOT clears every pixel the graphic sets, "
        "including the background and any other sprite under it: overlapping sprites punch "
        "holes in each other, and the landscape survives only because it is redrawn every "
        "pass.</p>",

        "<h4>One attacker, stage by stage</h4>",
        f"<p>Flying right from the start of a game, the simulator was stopped at every call "
        f"of {R(DRAW_SPRITE_PAIR)} until it came to an attacker (record {index}, type "
        f"${record[0]:02X}) that had moved to a shifted position. Its old image was at x "
        f"${old[0]:02X}, bottom line ${old[1]:02X}, {old[2]} rows; its new one at x "
        f"${new[0]:02X}, line ${new[1]:02X}, {new[2]} rows, {widths[1]} bytes wide. The box "
        f"is {width} bytes by {rows} rows from x ${left:02X}, line ${bottom:02X} (yellow "
        "below). The simulator was then stopped after each stage and the buffer read out; "
        "the old image is outlined in red, the new in green:</p>",
        figure(images["context"], "The screen after the attacker's turn, its box in yellow."),
        figure(images["stages"], "Left to right: the screen's rectangle before; the buffer "
               f"after the copy in ({R(COPIED_IN)}); after the old image is rubbed out "
               f"({R(ERASED)}); after the new one is drawn ({R(DRAWN)}); and the screen's "
               "rectangle after the copy back. Magnified four times."),
        "<p>Checked as the page was built: the buffer after the copy in is exactly the "
        "screen's rectangle, and the rectangle after the copy back exactly the buffer. Over "
        "black sky the rubbing out leaves the box empty; over anything else it would leave a "
        f"hole. The whole call took {cost:,} T-states, about {pass_frames} per cent of a "
        "frame.</p>",
        "<p>The row loops' entry points, read from the game (the first eleven words rub out, "
        "the second eleven draw, one for each width and alignment):</p>",
        "<p>" + ", ".join(R(w) for w in row_words[:11]) + "</p>",
        "<p>" + ", ".join(R(w) for w in row_words[11:]) + "</p>",

        "<h3>The direct drawer</h3>",
        f"<p>For the ship ({R(DRAW_SHIP_IMAGE)}), its trail ({R(0xC4ED)}), the side jet "
        f"({R(0xC5FF)}), the lift jet ({R(0xC6D2)}) and the pieces of a carried part "
        f"({R(0xC27F)}). The old image's registers are in the alternate set (HL' its screen "
        "address, DE' its graphic, IY its erase routine), the new image's in the main set "
        f"(HL, DE, IX its draw routine). {R(DIRECT_ROWS[0])} rubs out a row of the old image "
        f"and moves up a line; {R(DIRECT_ROWS[1])} draws a row of the new one; when one runs "
        "out the other finishes alone. Since a row is rubbed out just before the same row of "
        "the new image is drawn, only a line or two is ever missing: no flicker without a "
        "buffer.</p>",
        f"<p><b>Mirroring.</b> Facing left (bit 7 of {R(SHIP_FACING)}), {R(0xBF85)} and "
        f"{R(0xBFB8)} start each row at its last byte, pick the mirrored row routine, and "
        f"turn each byte round through {R(0xF900)}: one stored picture serves both "
        "facings.</p>",
        f"<p><b>Drawn over itself.</b> The ship never moves on the screen, so {R(0xC3E3)} "
        "usually just draws its image over itself with OR on odd passes, which puts back any "
        "pixels an object's rubbing out took. The old image is rubbed out only when the "
        "picture changes: a turn, a part being fitted, or docking with the finished "
        "rocket.</p>",
        f"<p>Worked example: the ship flown up and right from the start for 30 passes, then "
        f"left held. On the first pass of the turn {R(DRAW_SHIP_IMAGE)} called "
        f"{R(DRAW_DIRECT_PAIR)} with {ship_rows[0]} old rows and {ship_rows[1]} new ones; the "
        f"simulator was stopped at each of its {row_stops} row steps. A selection of them, "
        "magnified three times, the facing-right picture giving way to the mirrored one from "
        f"the bottom up; the call took {ship_cost:,} T-states:</p>",
        figure(images["ship"], "The ship turning, row by row."),
        figure(images["ship_gif"], "The same, a row step a frame."),

        "<h3>For a game of your own</h3>",
        "<ul>"
        "<li>Rubbing out and drawing in a scratch rectangle, then one copy to the screen, "
        "buys flicker-free sprites without masks or a screen buffer -- at the price of holes "
        "where sprites overlap.</li>"
        "<li>For a sprite that stays put on the screen, draw it over itself each pass and "
        "rub it out only when its picture changes, a row at a time.</li>"
        "<li>One 256-byte bit-reversal page and right-to-left row routines mirror any "
        "byte-aligned sprite for free.</li>"
        "</ul>",
        confirmed([
            "Run in the simulator when this page was built: an attacker's call of the "
            "compositor, stopped after each stage, with the buffer checked against the "
            "screen at both copies; the ship's turn through the direct drawer, stopped at "
            "each row step; both calls' T-states.",
            "Read from the game's memory: the row loops' entry points.",
            "Read from the code: the box, the patched loops, the shift tables, the "
            "mirroring, the colour rules. Never seen run in this build: the six-byte "
            "aligned rows and the left-clipped copies.",
        ]),
        "</div>"])


# --------------------------------------------------------------------------
# The ship.
# --------------------------------------------------------------------------

SHIP_CONSTANTS = [(0xB312, "gravity", "added to the climb speed each pass when not thrusting"),
                  (0xB314, "thrust", "added instead while thrusting"),
                  (0xB316, "push_right", "steering right (the speed is kept in the scroll's "
                                         "sense, so negative)"),
                  (0xB318, "push_left", "steering left"),
                  (0xB31A, "no_push", "not steering"),
                  (0xB31C, "drag_going_left", "against a ship going left"),
                  (0xB31E, "drag_going_right", "against a ship going right")]
TOP_SPEED, TOP_CLIMB = 0x5C3E, 0x5C3F
BUILD_SHIP_SPRITE = 0xAFE9
ADDON_GRAPHICS = 0xAF95
ADDON_PLACES = 0xAFD7
SHIP_PICTURE = 0xF6B9
SHIP_HEIGHT, SHIP_GRAPHIC = 0xC1A9, 0xC1AA
SHIP_ROW_BYTES = 6
ADDON_EFFECTS = {
    1: "the hook: needed to pick up a rocket part",
    2: "never lies anywhere: fitted with add-on 1 (its slot is set to twice add-on 1's); "
       "stops a floor box below hiding the lift jet",
    3: "never fitted: its place is never dealt (the ore tank comes as rocket part 6)",
    4: "the side jet; top speed across 4",
    5: "the lift jet; top climb 4; the ceiling moves from map row 5 to row 0",
    6: "fuel burnt at half the rate",
    7: "the special beam",
    8: "every other shot a homing missile",
    9: "stands on top, 11 more rows; lifts the two-piece load; no extra 4 lines in the "
       "landscape box",
}


def ship_picture(memory) -> list[bytes]:
    """The ship's picture as build_ship_sprite left it: ship_height rows of 6
    bytes from ship_graphic, bottom row first; returned top row first."""
    start, height = _word(memory, SHIP_GRAPHIC), memory[SHIP_HEIGHT]
    rows = [bytes(memory[start + SHIP_ROW_BYTES * r:start + SHIP_ROW_BYTES * (r + 1)])
            for r in range(height)]
    return rows[::-1]


def _ship_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    R = listing.r
    memory = bc.game_memory(snapshot)

    constant_rows = []
    values = {}
    for address, name, what in SHIP_CONSTANTS:
        value = _signed16(_word(memory, address))
        values[name] = value
        constant_rows.append([R(address), f"{'-' if value < 0 else '+'}${abs(value):02X}",
                              f"{value / 256:+.4f}", what])
    _check(values["thrust"] + values["gravity"] > 0 and abs(values["thrust"]) > abs(values["gravity"]),
           "thrust does not beat gravity")

    # Thrust from the plain, then steering right, then letting go.
    log("  the ship's physics...")
    game = base_game(snapshot)
    m = game.memory
    top = (m[TOP_SPEED], m[TOP_CLIMB])

    def run(keys, count):
        rows = []
        for _ in range(count):
            bc._keep_alive(m)
            game.run_to(TO_SCROLL, 2, keys)
            rows.append((speed(m, SHIP_ACROSS_SPEED), speed(m, SHIP_DOWN_SPEED),
                         _signed(m[SCROLL_ACROSS]), _signed(m[SCROLL_DOWN])))
            game.passes(1, keys)
        return rows

    climb = run(["a"], 12)
    right = run(["a", "x"], 12)
    coast = run([], 12)
    _check(climb[1][1] - climb[0][1] == values["thrust"] / 256 or climb[0][1] > 0,
           "thrust did not add its constant")
    _check(all(r[3] in (0, 2, 4, -2, -4) and r[2] in (0, 2, 4, -2, -4)
               for r in climb + right + coast), "a scroll step that is not 0, 2 or 4")
    physics_rows = []
    for label, rows in (("thrust (A held)", climb), ("thrust and right (A, X)", right),
                        ("nothing held", coast)):
        for n, (across, up, step_across, step_up) in enumerate(rows):
            physics_rows.append([label if n == 0 else "", n + 1, f"{up:+.3f}", step_up,
                                 f"{across:+.3f}", step_across])
    climb_max = max(r[1] for r in climb + right)

    # The ship's picture with each add-on, built by the game's own routine.
    log("  the ship's picture with each add-on...")
    base = base_game(snapshot)
    pictures_built = []
    addon_rows = []
    for n in [1] + list(range(3, 10)) + [None]:
        # Add-on 2 cannot be shown alone: build_ship_sprite sets its slot
        # from add-on 1's, so it comes and goes with the hook.
        g = base.fork()
        for k in range(1, 10):
            g.memory[bc.ADDON_SLOTS + k - 1] = 0
        if n is None:
            bc.all_addons(g.memory)
        else:
            g.memory[bc.ADDON_SLOTS + n - 1] = n
        g.call(BUILD_SHIP_SPRITE, seconds=1)
        rows = ship_picture(g.memory)
        image = scaled(bitmap_image(rows, SHIP_ROW_BYTES), 2)
        pictures_built.append((n, image, g.memory[SHIP_HEIGHT], g.memory[TOP_SPEED],
                               g.memory[TOP_CLIMB]))
        if n is not None:
            place = _word(memory, ADDON_PLACES + 2 * (n - 1))
            if n == 3:
                place2 = _word(memory, ADDON_PLACES + 2)
                addon_rows.append([2, R(bc.ADDON_SLOTS + 1), R(_word(memory, ADDON_GRAPHICS + 2)),
                                   f"row {(place2 - SHIP_PICTURE) // SHIP_ROW_BYTES}, byte "
                                   f"{(place2 - SHIP_PICTURE) % SHIP_ROW_BYTES}",
                                   "with add-on 1", "", ADDON_EFFECTS[2]])
            addon_rows.append([n, R(bc.ADDON_SLOTS + n - 1), R(_word(memory, ADDON_GRAPHICS
                                                                        + 2 * (n - 1))),
                               f"row {(place - SHIP_PICTURE) // SHIP_ROW_BYTES}, byte "
                               f"{(place - SHIP_PICTURE) % SHIP_ROW_BYTES}",
                               g.memory[SHIP_HEIGHT], f"{g.memory[TOP_SPEED]}, "
                               f"{g.memory[TOP_CLIMB]}", ADDON_EFFECTS[n]])
    bare = base.fork()
    for k in range(1, 10):
        bare.memory[bc.ADDON_SLOTS + k - 1] = 0
    bare.call(BUILD_SHIP_SPRITE, seconds=1)
    bare_height = bare.memory[SHIP_HEIGHT]
    _check(bare_height == 14, f"the bare ship is {bare_height} rows")
    _check(pictures_built[2][3] == 4 and pictures_built[3][4] == 4,
           "add-ons 4 and 5 did not raise the top speeds")
    tallest = max(h for _, _, h, _, _ in pictures_built)
    from PIL import Image
    tiles = []
    for n, image, height, _, _ in pictures_built:
        tile = Image.new("RGB", (image.width, tallest * 2), (0, 0, 0))
        tile.paste(image, (0, tallest * 2 - image.height))
        tiles.append(tile)
    bare_img = scaled(bitmap_image(ship_picture(bare.memory), SHIP_ROW_BYTES), 2)
    addons_img = grid(tiles, 5, gap=6)

    images = {
        "addons": pictures.piece("ship_addons.png", addons_img,
                                 "The ship's picture with each add-on", 2),
        "bare": pictures.piece("ship_bare.png", bare_img, "The bare ship", 2),
    }

    return "\n".join([
        '<div class="kl-list">',
        "<p>The ship never moves on the screen. Steering and thrust become this pass's "
        "scroll, 2 or 4 pixels, and the world moves the other way. Its picture is rebuilt "
        "in RAM from the add-ons it carries whenever one is fitted.</p>",

        "<h3>The record</h3>",
        f"<p>{R(0xC8E5)} is 32 bytes in the objects' layout (see <a href=\"Objects.html\">"
        f"the objects</a>), reset each life from {R(0xC906)}. Because the ship stays put on "
        "the screen, its world position is the view's: +1 to +3 the map column and x in the "
        f"page, +4 to +6 the row and y; {R(0xC8FD)} its facing (bit 7 left); "
        f"{R(SHIP_ACROSS_SPEED)} and {R(SHIP_DOWN_SPEED)} its two speeds, 8.8 numbers high "
        f"byte first, in units of 2 pixels a pass; {R(0xC902)} and {R(0xC903)} its place on "
        f"the screen; {R(0xC904)} an add-on or rocket part being fitted. The byte after it, "
        f"{R(0xC905)}, is the ore aboard.</p>",

        "<h3>One pass</h3>",
        f"<p>{R(SHIP_PASS)} counts the pass, saves a restart point every fourth, and unless "
        f"the ship is dying calls {R(0xB234)}: {R(0xB115)} reads the controls (and burns "
        f"fuel), the speed across goes through {R(0xC7FC)} and {R(0xC81F)} into "
        f"{R(SCROLL_ACROSS)}, and the climb through {R(0xB322)} and {R(0xB320)} into "
        f"{R(SCROLL_DOWN)}. Then the record is moved against the scroll ({R(0xB9EC)}), "
        f"tested against the landscape ({R(0xBA21)}, see <a href=\"LandscapeCollision.html\">"
        f"collision</a>) and the ground objects ({R(0xA8F4)}), and the landscape scrolls.</p>",

        "<h3>The constants</h3>",
        "<p>Read from the game, in 256ths of a speed unit a pass (a unit being 2 pixels a "
        "pass):</p>",
        table(["Label", "Value", "Units a pass", "What"], constant_rows),
        f"<p>Thrust replaces gravity rather than adding to it, so thrust beats gravity by "
        f"only ${values['thrust'] + values['gravity']:02X} a pass. Across, the drag is "
        "ignored when steering the way the ship already goes and added when steering against "
        f"it, so reversing is quicker than speeding up; with nothing held the drag alone "
        f"slows the ship, and {R(0xC7FC)} turns a speed that would change sign into 0. "
        f"{R(0xC868)} keeps the speed across to half the top speed ({R(TOP_SPEED)}: "
        f"{top[0]}, or 4 with add-on 4) one way and one more the other; {R(0xB322)} keeps "
        f"the climb to -3 down and half the top climb ({R(TOP_CLIMB)}: {top[1]}, or 4 with "
        f"add-on 5) up. {R(0xC81F)} adds the speed to {R(0xC7FA)} and the step is twice "
        "the change in its high byte: the screen moves in 2-pixel steps, and a 4-pixel step "
        "only from a fine scroll of 0 or 4, so that it stays even.</p>",
        "<p>The keyboard never sets <i>down</i>: the ship comes down by gravity alone. No "
        "thrust is read while the view is on map row 5 (row 0 with add-on 5) and its line "
        "in the page is above $60, so without the lift jet the ship cannot climb into the "
        "top of the sky; while the special beam is out the ship hangs still; docked with "
        "the finished rocket, nothing is read at all.</p>",
        f"<p>Worked example: from the start of a game, the simulator stopped at "
        f"{R(TO_SCROLL)} each pass (the speeds after the landscape test, the steps this pass "
        "scrolls), first with thrust held, then thrust and right, then nothing:</p>",
        table(["Keys", "Pass", "Climb speed", "Step up", "Speed across", "Step across"],
              physics_rows),
        f"<p>The climb speed grows by ${values['thrust']:02X}/256 a pass, but "
        f"{R(0xB322)} holds only its whole part, to 1 (half the top climb of {top[1]}), and "
        f"leaves the fraction alone, so held thrust saws between 1 and {climb_max:+.3f}; the "
        "speed across does the same under its own clamp. With nothing held, gravity takes "
        "the climb down past -2 and the drag wears the speed across away a little each "
        "pass -- but the drag goes by last pass's step, so once the step is 0 a small "
        "speed is left over. The steps are always 0, 2 or 4 pixels, never the speed itself. "
        "Where a speed jumps in the last run, the change came between the ship's passes "
        "(the landscape test changed nothing then), which points to a touch by an object: "
        f"{R(0x8FCA)} adds an object's speed to the ship's. That is inferred, not traced.</p>",

        "<h3>The picture and the add-ons</h3>",
        f"<p>The ship is drawn from {R(SHIP_PICTURE)}, a buffer of 6-byte rows, built by "
        f"{R(BUILD_SHIP_SPRITE)}: the bare ship ({R(0xC891)}, {bare_height} rows) goes into "
        f"the buffer's last 14 rows, and each fitted add-on is drawn in by {R(0xB09C)} at its "
        f"place from {R(ADDON_PLACES)}, its mask ANDed on first and its picture ORed on "
        f"({R(0xB0E4)}). Each add-on's graphic in {R(ADDON_GRAPHICS)} is preceded by the "
        f"picture height it needs; the highest wins, into {R(SHIP_HEIGHT)}, and "
        f"{R(SHIP_GRAPHIC)} is where drawing starts. Since the buffer is drawn bottom row "
        "first, its last rows are the top of the picture: the bare ship sits at the top and "
        "the add-ons hang below, the ship's top staying where it was on the screen.</p>",
        f"<p>Each picture below was made by setting one add-on's slot in the player record "
        f"(add-on n's slot holds n), calling {R(BUILD_SHIP_SPRITE)} in the simulator, and "
        "reading the rows it left; the last has all nine. The add-ons' names are by "
        "appearance; their effects are read from the code:</p>",
        figure(images["bare"], "The bare ship."),
        figure(images["addons"], "Add-on 1 (with add-on 2, which always comes with it), "
               "add-ons 3 to 9 one at a time, then all nine."),
        table(["Add-on", "Slot", "Graphic", "Place in the buffer", "Picture height",
               "Top speed, climb", "Effect"], addon_rows),
        "<p>Add-on 9 is the one that grows upwards: it adds 11 rows above the bare ship, and "
        "the picture runs past the end of the buffer into the bytes after it.</p>",

        "<h3>The jets and the trail</h3>",
        "<p>Drawn by the direct drawer like the ship (see <a href=\"Drawing.html\">drawing"
        f"</a>), on alternate passes: the <b>side jet</b> ({R(0xC5FF)}, add-on 4) flickers "
        f"behind the ship while it steers; the <b>lift jet</b> ({R(0xC6D2)}, add-on 5) hangs "
        "under it, mirrored every other draw so that it seems to spin; the <b>trail</b> "
        f"({R(0xC4ED)}) is a one-byte-wide line behind the ship whose bend follows the "
        f"speed across, from {R(0xC7C8)}.</p>",

        confirmed([
            "Run in the simulator when this page was built: the thrust, steering and coasting "
            "from the start of a game; build_ship_sprite with each add-on and with all nine.",
            "Read from the game's memory: the constants, the add-ons' graphics and places.",
            "Read from the code: the add-ons' effects, the ceiling, the clamps. The add-ons' "
            "names are by appearance.",
        ]),
        "</div>"])


# --------------------------------------------------------------------------
# The objects.
# --------------------------------------------------------------------------

OBJECT_HANDLERS = 0xAF25
FIRST_TYPE = 0x13
TYPE_COUNT = 12
OBJECT_GRAPHIC_LISTS = 0xAF3D
SMALL_OBJECT_EFFECTS = 0x944C
SMALL_OBJECT_FRAMES = 11
OBJECT_LOAD = 0x8E2B
TYPE_NAMES = {0x13: "cloud", 0x14: "attacker", 0x15: "debris", 0x16: "attacker",
              0x17: "attacker", 0x18: "attacker", 0x19: "the tough attacker",
              0x1A: "attacker", 0x1B: "(ground objects only)",
              0x1C: "small things: bullets, pick-ups, wreck pieces",
              0x1D: "rocks and comets of a meteor shower", 0x1E: "a rocket part falling into place"}
EFFECT_BITS = [(7, 0x8F1E, "slow the ship: halve each of its speeds that agrees in sign with "
                           "the object's"),
               (6, 0x8F54, "damage, at most once every 16 passes per object"),
               (5, 0x8FC4, "refuel: 28 of the gauge's 124 steps"),
               (4, 0x8FCA, "push: the object's speed halved and reversed, the same added to "
                           "the ship's"),
               (3, 0x900B, "collect: the object freed next pass, with a sound"),
               (2, 0x9015, "drain fuel: 16 steps"),
               (1, 0x9020, "an extra life, at most 9"),
               (0, 0x9030, "destroy: the object counts as shot")]
SMALL_FRAME_NAMES = ["bullet", "bullet", "bullet", "the refuel pick-up", "pellet", "pellet",
                     "the fuel thief", "pellet", "the ship icon (an extra life)",
                     "the shield ring", "the attackers' dash"]
RECORD_COLOURS = [(255, 80, 80), (255, 160, 60), (255, 255, 80), (120, 255, 120),
                  (80, 220, 255), (120, 140, 255), (220, 120, 255), (255, 255, 255),
                  (200, 200, 200)]


def effect_bits(value: int) -> str:
    if value == 0xFF:
        return "the shield"
    names = {7: "slow", 6: "damage", 5: "refuel", 4: "push", 3: "collect", 2: "drain fuel",
             1: "extra life", 0: "destroy"}
    return ", ".join(names[b] for b in range(7, -1, -1) if value & (1 << b)) or "nothing"


def drawn_box(memory, record: int):
    """Where an object's picture was drawn this pass (+$11 x, +$12 bottom
    line) and its size, from its graphic's frame; None if not drawn."""
    if memory[record] == 0xFF or not memory[record + 0x10] & 0x80:
        return None
    frames = _word(memory, OBJECT_GRAPHIC_LISTS + 2 * memory[record])
    graphic = _word(memory, frames + 2 * (memory[record + 0x13] & 15))
    width, height = memory[graphic], memory[graphic + 1]
    x, bottom = memory[record + 0x11], memory[record + 0x12]
    return x, bottom - height + 1, width * 8 + (8 if x & 7 else 0), height


def _objects_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    R = listing.r
    memory = bc.game_memory(snapshot)

    handler_rows = []
    for n in range(TYPE_COUNT):
        kind = FIRST_TYPE + n
        handler = _word(memory, OBJECT_HANDLERS + 2 * n)
        frames = _word(memory, OBJECT_GRAPHIC_LISTS + 2 * kind)
        handler_rows.append([f"${kind:02X}", R(handler), R(frames), TYPE_NAMES[kind]])
    _check(_word(memory, OBJECT_HANDLERS + 2 * (0x1B - FIRST_TYPE)) == 0xAFCB,
           "type $1B's word is not the graphic list it was read as")
    small_rows = [[n, SMALL_FRAME_NAMES[n], f"${memory[SMALL_OBJECT_EFFECTS + n]:02X}",
                   effect_bits(memory[SMALL_OBJECT_EFFECTS + n])]
                  for n in range(SMALL_OBJECT_FRAMES)]
    effect_rows = [[b, R(address), what] for b, address, what in EFFECT_BITS]

    # The sky over the plain: the ship sitting still, the objects watched.
    log("  the objects over the plain...")
    game = base_game(snapshot)
    m = game.memory
    spawned: dict[int, int] = {}
    by_record: dict[int, set] = {}
    loads = []
    tracks: dict[int, list] = {}
    previous = [m[OBJECT_RECORDS + OBJECT_RECORD_SIZE * i] for i in range(9)]
    passes = 600
    shot = None
    for n in range(passes):
        bc._keep_alive(m)
        game.passes(1)
        loads.append(m[OBJECT_LOAD])
        for i in range(9):
            record = OBJECT_RECORDS + OBJECT_RECORD_SIZE * i
            kind = m[record]
            if kind != 0xFF and previous[i] == 0xFF:
                spawned[kind] = spawned.get(kind, 0) + 1
                by_record.setdefault(kind, set()).add(i)
            previous[i] = kind
            box = drawn_box(m, record)
            if box and kind in ATTACKER_TYPES:
                tracks.setdefault(i, []).append((n, box))
        busy = sum(1 for i in range(9) if drawn_box(m, OBJECT_RECORDS + OBJECT_RECORD_SIZE * i))
        if shot is None and n > 100 and busy >= 4:
            shot = (screen_bytes(m), [(i, drawn_box(m, OBJECT_RECORDS + OBJECT_RECORD_SIZE * i),
                                       m[OBJECT_RECORDS + OBJECT_RECORD_SIZE * i],
                                       bytes(m[OBJECT_RECORDS + OBJECT_RECORD_SIZE * i:
                                               OBJECT_RECORDS + OBJECT_RECORD_SIZE * (i + 1)]))
                                      for i in range(9)])
    _check(shot is not None, "never four objects on the screen at once")
    _check(spawned, "nothing spawned in 600 passes")
    for kind, records in by_record.items():
        if kind in ATTACKER_TYPES:
            _check(records <= {0, 1, 2, 3}, f"an attacker started in records {sorted(records)}")
        if kind == 0x13:
            _check(records <= {0, 1, 2, 3, 7, 8}, f"a cloud started in records {sorted(records)}")
    screen, objects = shot
    rects = [(box[0], box[1], box[2], box[3], RECORD_COLOURS[i]) for i, box, _, _ in objects if box]
    shot_img = outline_images(scaled(screen_of(screen), 2), 2, rects)
    record_rows = []
    for i, box, kind, raw in objects:
        if kind == 0xFF:
            record_rows.append([i, "free", "", "", "", "", ""])
            continue
        record_rows.append([
            f'<span style="color:rgb{RECORD_COLOURS[i]}">{i}</span>', f"${kind:02X}",
            f"${raw[1]:02X} ${raw[2]:02X}", f"${raw[4]:02X} ${raw[5]:02X}",
            f"{_signed16(raw[7] << 8 | raw[8]) / 256:+.2f}, "
            f"{_signed16(raw[9] << 8 | raw[10]) / 256:+.2f}",
            f"${raw[0x13]:02X}", "drawn" if box else "not drawn"])
    spawn_rows = [[f"${k:02X}", TYPE_NAMES.get(k, ""), spawned[k],
                   ", ".join(str(r) for r in sorted(by_record[k]))] for k in sorted(spawned)]
    # The longest attacker track, over the last screen.
    record, track = max(tracks.items(), key=lambda kv: len(kv[1]))
    from PIL import ImageDraw
    track_img = scaled(screen_of(screen), 2)
    draw = ImageDraw.Draw(track_img)
    points = [((b[0] + b[2] // 2) * 2, (b[1] + b[3] // 2) * 2) for _, b in track]
    for a, b in zip(points, points[1:]):
        if abs(a[0] - b[0]) < 40 and abs(a[1] - b[1]) < 40:
            draw.line([a, b], fill=(255, 80, 80), width=2)
    images = {
        "records": pictures.stage("objects_records.png", shot_img, "The sky objects' records"),
        "track": pictures.stage("objects_track.png", track_img, "An attacker's path"),
    }

    return "\n".join([
        '<div class="kl-list">',
        "<p>Everything that flies -- attackers, clouds, bullets, pick-ups, debris -- is one of "
        f"nine 24-byte records at {R(OBJECT_RECORDS)}, each with a type byte that picks an "
        "update routine and a list of frames. Once a pass the nine are rubbed out, updated, "
        "redrawn, and tested against the ship and the player's shots. What touching one does "
        "is a byte of effect bits.</p>",

        "<h3>The record</h3>",
        "<p>The same layout serves the nine sky records, the ship's record, the four shot "
        f"records ({R(0xB37A)}), the rocket's drawing record ({R(0x9A4C)}) and the first 24 "
        f"bytes of the six ground-object records ({R(0xA80B)}), so one set of routines moves, "
        "places and draws them all.</p>",
        table(["Offset", "Field"], [
            ["+0", "type: $FF free, $13-$1E for the sky objects"],
            ["+1 +2 +3", "x: map column, pixel in the page, fraction"],
            ["+4 +5 +6", "y: map row, pixel (the bottom line), fraction; y grows downwards"],
            ["+7 +8", "speed across, signed 8.8 pixels a pass, high byte first"],
            ["+9 +A", "speed down, the same"],
            ["+B +C", "acceleration across"],
            ["+D", "two colours: ink and BRIGHT for odd passes in bits 0-3, for even passes "
                   "in bits 4-7"],
            ["+E +F", "acceleration down"],
            ["+10", "flags: bits 0-2 top speed less one; 3 skip a placing; 4 free next pass; "
                    "5 shot; 6 straddles the left edge; 7 drawn"],
            ["+11 +12", "where it was drawn: screen x, bottom line"],
            ["+13", "frame: bits 0-3 the frame, 4-5 a count, 6-7 the count's reload"],
            ["+14", "frame range: first frame in the high nibble, last in the low"],
            ["+15 +16", "the type's own: a timer, a path step, a hit count, a target"],
            ["+17", "contact cool-down or a missile's target in the high nibble; bit 3 "
                    "exploding; bits 0-2 the explosion's step"],
        ]),
        "<p>Records 0-3 are for attackers, 4-6 for what attackers and ground objects throw, "
        "7-8 for clouds; all nine become the ship's wreck when it dies.</p>",

        "<h3>The types and their update routines</h3>",
        f"<p>{R(OBJECT_HANDLERS)} has a word for each type from ${FIRST_TYPE:02X}, and "
        f"{R(OBJECT_GRAPHIC_LISTS)} a word for each graphic number pointing at its frames; "
        f"{R(0xA18D)} jumps to the type's routine. Read from the game:</p>",
        table(["Type", "Update routine", "Frames", "What (by appearance and behaviour)"],
              handler_rows),
        f"<p>Type $1B's word points at a graphic list ({R(0xAFCB)}), not code. It does no "
        "harm: type $1B is used only by ground objects, which never go through the table.</p>",
        f"<p>The update routines end in the shared tail of {R(0x9507)}: {R(0x9035)} (shot? "
        f"then score it and become debris), {R(0x97DF)} (the type's steering now and then), "
        f"{R(0x8C05)} (speed += acceleration, held to the top speed by {R(0x8C3F)}), "
        f"{R(0x910A)} (the animation: a count in bits 4-5 of +$13 steps the frame through "
        f"the range in +$14), {R(0x909A)} or {R(0x90A7)} (the landscape test, then "
        f"{R(0xBF66)}), {R(0x90EC)} (placed on the screen, steered back to the view by "
        f"{R(0x8C58)}), and the drawing ({R(0xAD1B)}, {R(0xAE98)}; see "
        "<a href=\"Drawing.html\">drawing</a>). Steering never sets a speed, only an "
        "acceleration, so every attacker swings smoothly and the clamp keeps it from running "
        "away.</p>",

        "<h3>The contact effect</h3>",
        f"<p>Each update routine leaves a byte in {R(0x8E2C)}. {R(0x8E2D)} tests the "
        "object's drawn box against the ship's fixed box -- 40 pixels wide from x 100, 16 "
        f"lines high -- with {R(0x9DB1)}, and on a touch acts on the bits from bit 7 down:</p>",
        table(["Bit", "Routine", "Effect"], effect_rows),
        "<p>Every attacker leaves $50 (damage and push), a cloud $80, the rocks $51, debris "
        f"0, a falling rocket part $10. Type $1C's effect goes by its frame, from "
        f"{R(SMALL_OBJECT_EFFECTS)}, read from the game:</p>",
        table(["Frame", "What", "Effect", "Bits"], small_rows),
        f"<p>$FF is the shield: {R(0x8E2D)} starts the shield timer and frees the ring.</p>",

        "<h3>Spawning, and the load</h3>",
        f"<p>{R(0x8E2B)} is recounted every pass: one for each record in use, one more for "
        "each drawn last pass, one more for a big cloud, plus half the rocket parts while the "
        f"rocket is drawn. {R(0x8D42)} spawns below 4 -- half the time a cloud "
        f"({R(0x8792)}), otherwise an attacker ({R(0x87E7)}) -- {R(0x87AF)} not at 8 or more, "
        f"and {R(0x87F6)} gives up at 7: a cheap stand-in for how busy the pass is, things on "
        "the screen weighing double because drawing is what costs. Attackers start out of "
        f"sight at fixed points ({R(0x8605)}, allowed by the kind of cell, {R(0x855C)}) and "
        f"come in the order of {R(0x990A)}.</p>",
        f"<p>Worked example: the ship left sitting on the plain at the start of a game "
        f"(undamaged and refuelled between passes) for {passes} passes, the nine records "
        "read after each. The load averaged "
        f"{sum(loads) / len(loads):.1f} and reached {max(loads)}. The records that started, "
        "by type:</p>",
        table(["Type", "What", "Started", "In records"], spawn_rows),
        "<p>The first pass after the hundredth with four or more things drawn: each record's "
        "drawn picture outlined in its colour, and the records as the game held them:</p>",
        figure(images["records"], "The sky objects over the plain."),
        table(["Record", "Type", "x (column, pixel)", "y (row, pixel)", "Speed (across, down)",
               "Frame byte", ""], record_rows),
        f"<p>The path of the attacker in record {record} over the {len(track)} passes it was "
        "drawn, the middle of its picture each pass, over the same screen: in from the edge "
        "of the view and down onto the ship, where it stays, pushing it about (the damage "
        "was undone between passes, so the ship lived on). The screen positions include the "
        "small scrolls those pushes caused.</p>",
        figure(images["track"], f"Record {record}'s path."),

        confirmed([
            "Run in the simulator when this page was built: 600 passes with the ship on the "
            "plain, the records read every pass, the spawns counted, one attacker followed.",
            "Read from the game's memory: the types' routines and frame lists, type $1C's "
            "effects.",
            "Read from the code: the record's fields, the shared tail, the contact bits, the "
            "load. The names of the types are by appearance and behaviour.",
        ]),
        "</div>"])


# --------------------------------------------------------------------------
# The rocket and the ore.
# --------------------------------------------------------------------------

ROCKET_PART_TABLE = 0x96B0
ROCKET_PARTS = 8
ROCKET_X, ROCKET_Y = 0x96AC, 0x96AE
LEVEL_DONE = 0xF52A
AFTER_PLANET_SECURED = 0xF530   # level_done: planet_secured has printed its screen
PLAYER_PLACES = 0xF604
PLACE_COUNT = 19
DEALING_LIST = 0x61A9
MAP_OBJECT_KINDS = 0x5C94
MAP_OBJECT_COUNT = 290
ORE_KINDS = {8: 1, 9: 1, 0x0A: 2}   # load_ore: units mined from each kind of deposit
LEVEL = 0xF5F9
PLACE_NAMES = (["add-on 1, the hook", "add-on 2", "add-on 3", "add-on 4", "add-on 5",
                "add-on 6", "add-on 7", "add-on 8", "add-on 9", "the slab (kind 9)",
                "the spire (kind 10)"]
               + [f"rocket part {n}" for n in range(8)])
PART_NAMES = ["a section of bars", "a checked section", "a crate-like section",
              "a crate-like section", "a fin", "a fin", "the ore tank", "the nose cone"]


def _rocket_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    R = listing.r
    memory = bc.game_memory(snapshot)

    part_rows = []
    for n in range(ROCKET_PARTS):
        entry = ROCKET_PART_TABLE + 5 * n
        part_rows.append([n, PART_NAMES[n], R(entry), _signed(memory[entry + 3]),
                          _signed(memory[entry + 4])])
    base_x = (memory[ROCKET_X + 1], memory[ROCKET_X])
    base_y = (memory[ROCKET_Y + 1], memory[ROCKET_Y])
    _check(base_x == (0x52, 0x68), f"the rocket's base is at column ${base_x[0]:02X}, x "
                                   f"${base_x[1]:02X}")

    # The places dealt to player 1 in a new game.
    game = base_game(snapshot)
    m = game.memory
    place_rows = []
    for n in range(PLACE_COUNT):
        a = PLAYER_PLACES + 4 * n
        column, row, x, y = m[a:a + 4]
        group = memory[DEALING_LIST + n]
        where = ("none ($FF)" if column == 0xFF else
                 f"column ${column & 0x7F:02X}, row ${row:02X}, x ${x:02X}, y ${y:02X}")
        place_rows.append([n, PLACE_NAMES[n], group, where])
    kinds = [memory[MAP_OBJECT_KINDS + n] & 0x3F for n in range(MAP_OBJECT_COUNT)]
    deposits = {k: kinds.count(k) for k in ORE_KINDS}
    ore_total = sum(deposits[k] * ORE_KINDS[k] for k in ORE_KINDS)
    _check(ore_total >= 18, f"the world holds only {ore_total} units of ore")

    # The launch, staged: the next life put inside the rocket with all
    # eight parts built.
    log("  the launch...")
    launch = base_game(snapshot)
    lm = launch.memory
    launch.play(bc.new_life_at(bc.restart_at(*bc.ROCKET_VIEW,
                                             pokes={bc.PARTS_BUILT: ROCKET_PARTS})))
    frames, passes, docked = [], 0, None
    while True:
        launch.run_to(AFTER_OBJECTS, 10)
        if docked is None and lm[bc.LAUNCH]:
            docked = passes + 1
        if lm[bc.LAUNCH] == 0xFF:
            frames.append(screen_bytes(lm))
            launch.run_to(LEVEL_DONE, 10)
            break
        frames.append(screen_bytes(lm))
        passes += 1
        _check(passes < 1000, "the rocket never left")
        launch.run_to(bc.PLAY_LOOP, 10)
    _check(len(frames) > 20, f"the launch took {len(frames)} passes")
    launch.run_to(AFTER_PLANET_SECURED, 120)
    secured = screen_bytes(lm)
    after = {"level": lm[LEVEL], "carried": lm[bc.PART_CARRIED], "built": lm[bc.PARTS_BUILT]}
    _check(after["carried"] == 6 and after["built"] == 6,
           f"after the planet: part carried {after['carried']}, built {after['built']}")
    picks = [0, 1, 2] + [round(len(frames) * f) for f in (0.15, 0.3, 0.5, 0.7, 0.85)] \
        + [len(frames) - 6, len(frames) - 3, len(frames) - 1]
    picks = sorted(set(min(p, len(frames) - 1) for p in picks))
    strip_img = grid([play_area(screen_of(frames[i])) for i in picks], 4)
    gif_frames = [play_area(screen_of(f)) for f in frames[::3]]
    images = {
        "launch": pictures.piece("rocket_launch.png", strip_img, "The launch", 1),
        "gif": pictures.gif("rocket_launch.gif", gif_frames + [gif_frames[-1]] * 10, 80,
                            "The launch, every third pass", 2),
        "secured": pictures.stage("rocket_secured.png", scaled(screen_of(secured), 2),
                                  "The planet-secured screen"),
    }

    return "\n".join([
        '<div class="kl-list">',
        f"<p>The goal: build a rocket of eight parts at a fixed place, map column "
        f"${base_x[0]:02X}, row ${base_y[0]:02X}. The parts lie at places dealt at random to "
        "each player; with the hook fitted the ship picks up only the part due next, carries "
        "it hanging below, and lets it go over the rocket, where it falls into its slot. "
        "Part 6 is an ore tank, to be filled with 18 units of ore mined with the special "
        "beam first. With all eight built the ship docks, the rocket lifts off, and the "
        "planet is secured.</p>",

        "<h3>The parts</h3>",
        f"<p>{R(ROCKET_PART_TABLE)} holds five bytes a part in delivery order: the flags and "
        f"drawn place that {R(0x9572)} keeps between passes, then the part's offset from the "
        f"base ({R(ROCKET_X)}: pixel ${base_x[1]:02X} of column ${base_x[0]:02X}; "
        f"{R(ROCKET_Y)}: line ${base_y[1]:02X} of row ${base_y[0]:02X}). Read from the game "
        "(the names by appearance, the frames being type $1E's list, "
        f"{R(0xAF7B)}):</p>",
        table(["Part", "What", "Entry", "x offset", "y offset"], part_rows),
        "<p>A stack, with a fin either side.</p>",

        "<h3>Where they are: the dealing</h3>",
        f"<p>At a new game {R(0xF3BD)} calls {R(0x6113)} for each player. It walks "
        f"{R(DEALING_LIST)} and writes 19 four-byte places into the player's record from "
        f"{R(PLAYER_PLACES)}: map column, row, and x and y in the cell. A value of 1 to 5 "
        "deals a place at random from that group of the pool (retrying while it is taken); "
        "0 deals none -- unless the next value is 3, when it copies the place before, 16 "
        "to the right and 35 up. The pool is freed for each player, so the two players' "
        "worlds are dealt independently. As the view moves, "
        f"{R(0xDF08)} puts any of the current player's places in the window's four cells, "
        f"not yet taken, into the two pick-up records ({R(0xA873)}, {R(0xA88D)}): at most two "
        "pick-ups show at once. Player 1's places in the game this page played, read from "
        "the record:</p>",
        table(["Place", "What lies there", "Group dealt from", "Place dealt"], place_rows),

        "<h3>Picking a part up, and delivering it</h3>",
        f"<p>{R(0xAAD7)} tests each pick-up record every pass against a box 16 pixels wide "
        "under the middle of the ship -- the hook's reach. A rocket part is taken only with "
        f"add-on 1 fitted and only if it is the part due next ({R(bc.PARTS_BUILT)}): 1000 "
        f"points, its place marked taken, and the part hung under the hook "
        f"({R(0xAA37)}, which XORs the part's graphic into the ship's picture, so the same "
        f"call puts it on and takes it off). {R(0x9724)}, each pass while carrying, lets it go "
        f"when the ship is at column $52, x exactly $5C, row 10 or above -- part 6 only with "
        f"18 ore aboard. The part becomes a type $1E object ({R(0x97BD)} finds it a record) "
        f"that falls without testing the landscape; {R(0x9524)} frees it at its place, adds "
        "one to the parts built and scores 1500.</p>",

        "<h3>Ore</h3>",
        f"<p>Ore lies in ground objects of kinds 8, 9 and $0A. Counted from "
        f"{R(MAP_OBJECT_KINDS)} (bits 0-5 of each of the {MAP_OBJECT_COUNT} bytes): "
        + ", ".join(f"{deposits[k]} of kind ${k:02X} ({ORE_KINDS[k]} unit"
                    f"{'s' if ORE_KINDS[k] > 1 else ''} each)" for k in ORE_KINDS)
        + f", {ore_total} units in all, for a tank of 18. Only the special beam (add-on 7) "
        f"touches ground objects: {R(0xABA8)} dissolves a deposit it hits and marks it gone "
        f"for this player, and when the beam has gone {R(0xA8A5)} adds the units -- only "
        "while the part carried is the tank. The ore is drawn into the tank under the ship, "
        f"a row of {R(0x7721)} a unit, and {R(0xF1BD)} turns the ship yellow at 18. A death "
        f"keeps the ore ({R(0xF600)}).</p>",

        "<h3>Docking and the launch</h3>",
        f"<p>With all eight built, {R(0x9572)} waits for the ship at column $52, x $5C, row "
        f"10, line $63 or lower -- inside the rocket. Then {R(bc.LAUNCH)} is set; the death "
        "byte is set to 10 for two calls, so that the ship's picture and trail are rubbed "
        "out, and put back to 0 at once (a docking, not a death); nothing is read from the "
        f"controls, and {R(0xB234)} holds thrust on at the fast climb until the view reaches "
        "map row 0. The rocket rises at the view's scroll with the lift jet under it and "
        f"{R(0x7303)}; when part 0 is no longer drawn, {R(bc.LAUNCH)} becomes $FF and the play "
        f"loop goes to {R(LEVEL_DONE)}.</p>",
        f"<p>Worked example, staged: a new life put by the game's own restart at map column "
        f"${bc.ROCKET_VIEW[0]:02X}, row ${bc.ROCKET_VIEW[1]:02X}, x ${bc.ROCKET_VIEW[2]:02X} -- "
        f"the ship inside the rocket's place -- with {R(bc.PARTS_BUILT)} written as 8 at the "
        f"same moment. The ship docked on pass {docked} of play and the launch ran "
        f"{len(frames)} passes before {R(bc.LAUNCH)} reached $FF; a selection, the "
        "landscape falling away below as the view climbs with the rocket, and the rocket "
        "leaving the top of the screen once the view has reached the top of the sky:</p>",
        figure(images["launch"], "The launch: the first passes, then on through the climb."),
        figure(images["gif"], "The launch, every third pass."),

        "<h3>The end of a planet</h3>",
        f"<p>{R(LEVEL_DONE)} clears the play area and calls {R(0x83D6)}: the planet-secured "
        "screen with the finished planet's name and the next one's; ten times 5000 points, "
        f"each with a zap; the level counted on ({R(LEVEL)}, the fifth coming round to the "
        "first); the rocket's base reset; the part carried and the parts built set to 6; the "
        "last place dealt again, so the nose cone lies somewhere new; and the current "
        f"player's gone bit cleared in all {MAP_OBJECT_COUNT} world objects "
        f"({R(0x9A8A)}), so every deposit, pad and beam maker is back. The level is read "
        "only for the planet's colours and its name: every planet is the same map. The same "
        f"staged game, run on into {R(0x83D6)}:</p>",
        figure(images["secured"], "The planet-secured screen, as the game printed it."),
        f"<p>After it, read from memory: the level {after['level']}, the part carried "
        f"{after['carried']} (the tank) and the parts built {after['built']}: the next planet "
        "starts with six parts standing and the empty tank aboard.</p>",

        confirmed([
            "Run in the simulator when this page was built: a new game's dealing (player "
            "1's places read from the record); the docking, the launch and planet_secured, "
            "staged by the game's restart with the parts built written as 8.",
            "Read from the game's memory: the parts' offsets, the dealing list, the ore "
            "deposits.",
            "Read from the code, never run in this build: picking a part up, dropping it, the "
            "part falling into place, and mining ore. The parts' names are by appearance.",
        ]),
        "</div>"])


# --------------------------------------------------------------------------
# Damage, fuel and dying.
# --------------------------------------------------------------------------

DAMAGE_SHIP = 0x8F76
SHIELD_TIMER = 0x896F
DEATH_SEQUENCE_PASS = 0xF49E
DEATH_SEQUENCE_TEST = 0xF4B0    # ...its test of the death byte, at the end of each pass
ADDON_SIX = 0xF5F3
ICON_CROP = (0x30, 0, 0x50, 16)     # player 1's ship icon in the panel (damage_ship: $0F30)
DISSOLVE_PLAY_AREA = 0x9EFE
FUEL_SHOWN = 0xCC62


def _damage_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    R = listing.r
    base = base_game(snapshot)
    lives_at_start = base.memory[bc.LIVES]

    # Hits: damage_ship called three times, then the refuel pad's repair.
    log("  hits and the repair...")
    hits = base.fork()
    hm = hits.memory
    icons, hit_rows = [screen_bytes(hm)], [[0, "", hm[bc.HITS], hm[bc.DYING],
                                            attr_name(hm[0x5800 + 6])]]
    for n in range(1, 4):
        hits.call(DAMAGE_SHIP)
        icons.append(screen_bytes(hm))
        hit_rows.append([n, f"{R(DAMAGE_SHIP)}", hm[bc.HITS], hm[bc.DYING],
                         attr_name(hm[0x5800 + 6])])
    _check(hm[bc.HITS] == 3 and hm[bc.DYING] == 1, "the third hit did not set the death byte")
    repair = base.fork()
    repair.call(DAMAGE_SHIP)
    repair.memory[bc.HITS] = 0xFF
    repair.call(DAMAGE_SHIP)
    _check(repair.memory[bc.HITS] == 0, "a count of $FF did not wrap to 0")
    icons.append(screen_bytes(repair.memory))
    hit_rows.append(["a hit, then the pad's $FF", f"{R(DAMAGE_SHIP)}", repair.memory[bc.HITS],
                     repair.memory[bc.DYING], attr_name(repair.memory[0x5800 + 6])])
    icon_strip = strip([scaled(screen_of(s).crop(ICON_CROP), 4) for s in icons], gap=8)

    # Fuel: the burn a pass, by what is held.
    log("  the fuel burn...")
    burn_rows = []
    burns = {}
    for label, keys, saver in (("nothing", [], False), ("thrust (A)", ["a"], False),
                               ("steering (Z)", ["z"], False), ("both", ["a", "z"], False),
                               ("both, with add-on 6", ["a", "z"], True)):
        g = base.fork()
        gm = g.memory
        if saver:
            gm[ADDON_SIX] = 6
        g.passes(2, keys)
        start = _word(gm, bc.FUEL)
        count = 32
        for _ in range(count):
            gm[bc.HITS] = 0
            g.passes(1, keys)
        per_pass = (_word(gm, bc.FUEL) - start) / count
        burns[label] = per_pass
        burn_rows.append([label, f"{per_pass:g}",
                          f"{124 * 256 / per_pass:,.0f}" if per_pass else "never"])
    _check(burns["nothing"] == 0, f"coasting burnt {burns['nothing']} a pass")
    _check(burns["both"] == 2 * burns["thrust (A)"], "both at once is not twice thrust alone")
    _check(burns["both, with add-on 6"] * 2 == burns["both"], "add-on 6 did not halve the burn")

    # An empty tank, and the death that follows.
    log("  a death from an empty tank...")
    death = base_game(snapshot)
    fly(death, TERRACE_FLIGHT)
    dm = death.memory
    dm[bc.FUEL], dm[bc.FUEL + 1] = bc.FUEL_EMPTY & 0xFF, bc.FUEL_EMPTY >> 8
    gauge_passes = grace = 0
    while dm[bc.DYING] == 0:
        dm[bc.HITS] = 0             # so that only the fuel can kill
        death.passes(1)
        if dm[FUEL_SHOWN] < 0xBE:
            gauge_passes += 1
        else:
            grace += 1
        _check(gauge_passes + grace < 400, "the empty tank never killed the ship")
    frames = {}
    passes_dying = 0
    while dm[bc.DYING] < 12:
        frames.setdefault(dm[bc.DYING], screen_bytes(dm))
        # To the end of the pass's objects: at 12 the play loop leaves for
        # the death sequence and does not come round again.
        death.run_to(AFTER_OBJECTS, 10)
        passes_dying += 1
    sequence = 0
    while dm[bc.DYING] < 0x50:
        frames.setdefault(dm[bc.DYING], screen_bytes(dm))
        death.run_to(DEATH_SEQUENCE_TEST, 10)
        sequence += 1
    death.run_to(DISSOLVE_PLAY_AREA, 30)
    death.machine.run(0.6)
    dissolving = screen_bytes(dm)
    lives_before = dm[bc.LIVES]
    death.run_to(bc.PLAY_LOOP, 60)
    _check(dm[bc.LIVES] == lives_before - 1, "the death did not take a life")
    reborn = screen_bytes(dm)
    first_seen = min(frames)
    picks = [k for k in (first_seen, 3, 10, 11, 12, 0x20, 0x40) if k in frames]
    death_strip = grid([play_area(screen_of(frames[k])) for k in picks]
                       + [play_area(screen_of(dissolving)), play_area(screen_of(reborn))], 3)
    images = {
        "icons": pictures.piece("damage_icons.png", icon_strip, "The panel's ship icon", 1),
        "death": pictures.piece("damage_death.png", death_strip, "A death from an empty tank", 1),
    }
    pick_names = ", ".join(f"${k:02X}" for k in picks)

    return "\n".join([
        '<div class="kl-list">',
        f"<p>Two things kill the ship: a third hit, and an empty tank. Either sets the death "
        f"byte, {R(bc.DYING)}, which then counts up a pass at a time through the wreck, the "
        "death sequence and the wipe of the screen, and a life is taken.</p>",

        "<h3>Hits</h3>",
        f"<p>A touch with contact bit 6 -- every attacker, the rocks, bullets, pellets -- goes "
        f"to {R(0x8F54)}, at most once every 16 passes per object; the flickering beams go "
        f"through {R(0x9D0E)}. Both reach {R(DAMAGE_SHIP)}, which does nothing while the "
        f"shield runs ({R(SHIELD_TIMER)}) or the ship is already dying; otherwise a zap, "
        f"{R(bc.HITS)} up by one, and the panel's ship icon recoloured by the new count, the "
        "third hit setting the death byte to 1. Ground objects never damage the ship: they "
        "are solid, and it bounces off them.</p>",
        f"<p><b>Repair.</b> A refuel pad ({R(0xA8F4)}) sets {R(bc.HITS)} to $FF and calls the "
        "same routine, which wraps the count to 0 and colours the icon white: one routine "
        "both damages and repairs.</p>",
        f"<p>Worked example: {R(DAMAGE_SHIP)} called three times in the simulator at the "
        "start of a game, then, on a fresh copy, once more and again with the count written "
        "as $FF, as the pad does; the icon read from the screen each time:</p>",
        table(["Hits", "Called", "Hit count", "Death byte", "Icon's colour"], hit_rows),
        figure(images["icons"], "Player 1's ship icon: before, after each hit, and after the "
               "repair."),

        "<h3>The shield</h3>",
        f"<p>The shield ring, thrown up one throw in eight by the mounds that throw bullets, "
        f"sets {R(SHIELD_TIMER)} to $FF when touched; {R(SHIP_PASS)} counts it down on odd "
        "passes, so it lasts 510 passes. While it runs no damage is taken, an attacker that "
        f"touches the ship dies instead, and {R(0xF1BD)} paints the ship cyan, flashing in "
        "its last 32 counts.</p>",

        "<h3>Fuel</h3>",
        f"<p>{R(bc.FUEL)} is a word whose high byte is the gauge's level as a screen line: "
        f"$42 full, $BE empty, 124 steps. Only {R(0xCC4D)} changes it. {R(0xB115)} burns it "
        "while steering or thrusting -- coasting and falling are free -- halved with add-on 6 "
        f"and halved again while {R(0x5C40)} is set. The refuel pick-up gives 28 steps back "
        f"({R(0x8FC4)}), the fuel thief takes 16 ({R(0x9015)}), a refuel pad fills the tank, "
        "and a new life starts full.</p>",
        f"<p>Worked example: from the start of a game, 32 passes with each of these held, "
        f"the fuel word read before and after (the gauge has {124 * 256:,} 256ths of a step "
        "to burn):</p>",
        table(["Held", "Fuel word a pass", "Passes from full to empty"], burn_rows),
        f"<p><b>The gauge</b> ({R(0xCC77)}) moves {R(FUEL_SHOWN)} one row a pass towards the "
        f"level, and {R(0xCAA7)} turns it red on two passes in four once it is low. "
        f"<b>Running out</b> ({R(0xCC63)}): once the gauge shows empty, the death byte is set "
        f"the next time the low seven bits of {R(0x9A64)} are 0 -- up to 128 passes of "
        f"grace. With the tank emptied in the terrace scene, the gauge took {gauge_passes} "
        f"passes to run down to empty and the ship died {grace} passes after that.</p>",

        "<h3>The death byte and the death sequence</h3>",
        table(["Death byte", "What happens"], [
            ["1-3", "every object starts exploding"],
            ["not 0", "nothing touches the ship, nothing new spawns, no damage, no fuel "
                      "death"],
            ["10", f"{R(0x8CB2)}: the ship breaks into four pieces of debris and five "
                   f"falling pieces"],
            ["10-$2C", f"{R(0x72AB)} each pass"],
            ["$0B on", f"{R(SHIP_PASS)} no longer moves the ship"],
            ["12", f"the play loop goes to the death sequence ({R(0xF48B)})"],
            ["$50", "the sequence ends"],
        ]),
        f"<p>The death sequence stops the landscape, sets the fuel empty, and loops on "
        f"{R(SHIP_PASS)}, the pause test, the gauge, {R(0x8D42)} and {R(0xC1CE)} until the "
        f"byte reaches $50. Then {R(0xF4DD)}, the play area dissolved ({R(DISSOLVE_PLAY_AREA)}: "
        "every byte ANDed sixteen times with masks that each clear one bit, running on from "
        f"byte to byte so the picture crumbles) and cleared, {R(0xF4C6)} takes a life, and "
        f"{R(0xF440)} starts the next at the restart point.</p>",
        f"<p>Worked example, the same death. The empty gauge set the death byte to 1 in "
        f"{R(0xCC77)} and {R(0x8D42)} counted it to {first_seen} later in the same pass; "
        f"{passes_dying} more passes took it to 12, then {sequence} passes of the death sequence to $50. The play area at death "
        f"byte {pick_names}, then part way through the dissolve, then the first pass of the "
        "next life:</p>",
        figure(images["death"], "A death from an empty tank, stage by stage."),

        "<h3>Lives</h3>",
        f"<p>{R(bc.LIVES)}: {lives_at_start} at a new game (read from the game), one taken "
        f"by {R(0xF4C6)} after each death, at most 9. The panel shows lives less one: the "
        f"ship in play is not counted. At none, {R(0xF4FC)}. <b>Extra lives</b> "
        f"({R(0x9020)}) come from the ship-icon pick-up, thrown by the same mounds every "
        f"(lives x 4)th throw ({R(0x896E)}): one throw in twenty with five lives, one in four "
        "with one -- the game helps a player who is losing. The ore aboard survives a death "
        f"({R(0xF600)}).</p>",

        confirmed([
            "Run in the simulator when this page was built: three hits and a repair through "
            "damage_ship, with the icon read from the screen; the fuel burn over 32 passes "
            "for each way of flying; a death from an empty tank, from the gauge to the next "
            "life.",
            "Read from the code: the shield, the refuel and the fuel thief, the extra-life "
            "rule, the death byte's other steps. The shield's 25 seconds or so assume about "
            "20 passes a second.",
        ]),
        "</div>"])


# --------------------------------------------------------------------------
# The architecture.
# --------------------------------------------------------------------------

START = 0x9A66
GAME = 0xF422
PASS_STAGES = [   # (stop, what ran since the stop before)
    (TO_SCROLL, "ship_pass: the controls, the ship's movement, the landscape test, the "
                "shots"),
    (DRAW_LANDSCAPE_CALL, "scroll_landscape: the origins and the window (and the ground "
                          "objects when the landscape moves up)"),
    (LANDSCAPE_DRAWN, "draw_landscape"),
    (SPRITES_DRAWN, "the ground objects, the beams, the stars"),
    (AFTER_SHIP_PASS, "draw_ship: the ship, trail, jets, firing"),
    (AFTER_GAUGE, "update_fuel_gauge"),
    (AFTER_SPAWN, "spawn_tick"),
    (AFTER_OBJECTS, "update_objects: the nine sky objects"),
    (bc.PLAY_LOOP, "random, and back round the loop"),
]
ENTRY_COLOURS = {"c": (90, 140, 255), "b": (255, 160, 60), "w": (255, 120, 40),
                 "t": (255, 230, 80), "g": (90, 220, 110), "s": (120, 120, 120),
                 "u": (150, 40, 40), "i": (60, 60, 60)}
ENTRY_KINDS = {"c": "code", "b": "data", "w": "words", "t": "text", "g": "variables",
               "s": "space", "u": "unused"}
REGIONS = [  # (from, to, what) -- addresses and words only, from memory-map.md
    (0x4000, 0x5AFF, "the display"),
    (0x5B00, 0x5B79, "the stack, down from $5B80"),
    (0x5B7A, 0x5B7F, "the stack's top: three return addresses while the landscape is drawn"),
    (0x5B80, 0x5C13, "the four on-screen cells' collision-box lists, over the loader's entry"),
    (0x5C15, 0x5C40, "scratch variables, in the system variables"),
    (0x5C80, 0x5C83, "the entry: DI, JP start"),
    (0x5C94, 0x6112, "the objects lying in the world and the places pick-ups are dealt to"),
    (0x61BC, 0x6C3B, "the map: 96 columns by 28 rows of tile numbers"),
    (0x6C3C, 0x70D7, "the tile table and the tile records"),
    (0x70D8, 0x731E, "the title tune and the sound effects"),
    (0x731F, 0x8346, "the sprite graphics"),
    (0x8347, 0xE248, "the code, with its tables and variables"),
    (0xE249, 0xE580, "the POP blitters and the pieces' tables by shift"),
    (0xE581, 0xE749, "the nine stored landscape graphics"),
    (0xE74A, 0xF0FA, "their shifted copies, made at the start"),
    (0xF10F, 0xF5E6, "the menu and the game's flow"),
    (0xF5E7, 0xF6B8, "the two player records"),
    (0xF6B9, 0xF7E4, "the ship's picture, built from its add-ons"),
    (0xF7EB, 0xF8FF, "start-up code, then the compositor's buffer"),
    (0xF900, 0xF9FF, "start-up code, then the bit-reversal table"),
    (0xFA00, 0xFFFF, "the loader's leftovers, then the shift tables"),
]


def skool_entries(skool: Path) -> list[tuple[int, str]]:
    """Every entry's start and type, from the skool file."""
    entries = []
    for line in skool.read_text(encoding="utf-8").split("\n"):
        match = re.match(r"^([bcgistuw])\$([0-9A-F]{4})", line)
        if match:
            entries.append((int(match.group(2), 16), match.group(1)))
    return sorted(entries)


def memory_picture(entries, first: int = 0x5B00, scale: int = 2):
    """A byte a pixel, 256 to a row, coloured by the type of entry holding it,
    with the addresses down the left every $800."""
    from PIL import Image, ImageDraw

    rows = (0x10000 - first) // 256
    margin = 44
    image = Image.new("RGB", (margin + 256 * scale, rows * scale), (20, 20, 60))
    pixels = image.load()
    bounds = entries + [(0x10000, "")]
    for (start, kind), (end, _) in zip(bounds, bounds[1:]):
        colour = ENTRY_COLOURS.get(kind, (60, 60, 60))
        for address in range(max(start, first), end):
            offset = address - first
            x, y = margin + (offset & 255) * scale, (offset >> 8) * scale
            for dx in range(scale):
                for dy in range(scale):
                    pixels[x + dx, y + dy] = colour
    draw = ImageDraw.Draw(image)
    for address in range(0x6000, 0x10000, 0x1000):
        y = (address - first) // 256 * scale
        draw.text((2, y - 5), f"${address:04X}", fill=(220, 220, 220))
        draw.line([(margin - 4, y), (margin - 1, y)], fill=(220, 220, 220))
    return image


def _architecture_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    R = listing.r

    # The start-up's length: from the entry to the outer loop.
    log("  the start-up and a pass's timing...")
    machine = Game(snapshot)
    machine.run_to(START, 5)
    t0 = machine.t
    machine.run_to(GAME, 5)
    startup = machine.t - t0

    # The stack's depth when the landscape is drawn.
    game = base_game(snapshot)
    game.run_to(0xD0BD, 2)
    landscape_sp = game.reg("SP")
    _check(landscape_sp == 0x5B7A, f"draw_landscape was entered with SP ${landscape_sp:04X}")

    # A pass, stage by stage, over the terrace flight.
    timing = base_game(snapshot)
    totals = [0] * len(PASS_STAGES)
    pass_lengths = []
    count = 0
    for keys, n in TERRACE_FLIGHT + [(["a", "z"], 60), (["q"], 40)]:
        for _ in range(n):
            bc._keep_alive(timing.memory)
            start = last = timing.t
            for k, (stop, _) in enumerate(PASS_STAGES):
                timing.run_to(stop, 2, keys)
                totals[k] += timing.t - last
                last = timing.t
            pass_lengths.append(timing.t - start)
            count += 1
    mean_pass = sum(pass_lengths) / count
    stage_rows = []
    for (stop, what), total in zip(PASS_STAGES, totals):
        stage_rows.append([R(stop), what, f"{total / count:,.0f}", f"{100 * total / sum(totals):.0f}"])
    pass_lengths.sort()
    per_second = TSTATES / mean_pass

    entries = skool_entries(snapshot.with_name("cyberun.skool"))
    kinds: dict[str, int] = {}
    bounds = entries + [(0x10000, "")]
    for (start, kind), (end, _) in zip(bounds, bounds[1:]):
        kinds[kind] = kinds.get(kind, 0) + end - start
    key = ", ".join(f'<span style="color:rgb{ENTRY_COLOURS[k]}">{ENTRY_KINDS[k]}</span> '
                    f"({kinds.get(k, 0):,} bytes)" for k in ENTRY_KINDS if kinds.get(k))
    region_rows = [[f"${a:04X}-${b:04X}", R(a) if a >= 0x5B00 else "", what]
                   for a, b, what in REGIONS]
    images = {"memory": pictures.piece("architecture_memory.png", memory_picture(entries),
                                       "The memory map", 1)}

    flow = "\n".join([
        f"{R(0x5C80)}    DI; JP start (the loader jumps here)",
        f"{R(START)}         SP = $5B80; border black; {R(0xF86B)}; JP game",
        f"{R(GAME)}          every game starts here",
        f"  {R(0xF26C)}        the title tune until a key, the menu until 0",
        f"  {R(0xF3BD)}    both player records cleared, 5 lives each, places dealt",
        f"  {R(0x9A72)}, {R(0x9A7E)}, {R(0xCA3F)}",
        f"  {R(0xF4EE)}, a pause, {R(0x9F2C)}",
        "  into the first life at $F44C, past the reset",
        f"{R(0xF440)}          every later life",
        f"  {R(0xF311)}    the per-life tables reset; no lives left: back to game",
        "  the ore back from the player record; the gone bit's BIT and SETs patched",
        f"  {R(0xDCA1)}    the fly-in, until play begins",
        "  the play loop at $F46C, until",
        f"    the death byte reaches 12: the death sequence, {R(0xF4C6)}, round to play",
        f"    {R(0x96AB)} is $FF: {R(LEVEL_DONE)}, the next planet, round to play",
    ])
    one_pass = "\n".join([
        f"$F46C  {R(SHIP_PASS)}",
        f"         the pass counted; every fourth, {R(0xC33C)}",
        f"         {R(0xB234)}: {R(0xB115)} (controls, fuel), the speeds and the steps",
        f"         {R(0xB9EC)}, {R(0xBA21)}, {R(0xA8F4)}, {R(0xBF66)}",
        f"         {R(0xB706)}: the shots",
        f"         JP {R(0xDDF8)}",
        f"           [a cell crossed] {R(0xDF08)}, {R(0xDEE1)}",
        f"           {R(0xAC60)} before or after the landscape, by the vertical scroll",
        f"           {R(0xD0BD)}",
        f"           {R(0x9BDA)}, {R(0xBFE3)}",
        f"           JP {R(0xC3E3)}: the ship, trail and jets, the pause test, "
        f"{R(0xB731)}; RET",
        f"$F46F  {R(0xCC77)}: the gauge, {R(0xCC63)}",
        f"$F472  {R(0x87AF)}: clouds and attackers",
        f"$F475  {R(0x8D42)}: the death byte; the nine sky objects",
        f"$F478  {R(0xF23B)}",
        "       the death byte at 12? the launch done? else round again",
    ])

    return "\n".join([
        '<div class="kl-list">',
        "<p>How Cyberun is put together: what runs from loading to the menu, a game, a life "
        "and a pass of play, what sets the speed, and where everything lies in memory.</p>",

        "<h3>From loading to the menu, a game and a life</h3>",
        f"<pre>{flow}</pre>",
        f"<p>The start-up -- {R(START)} to {R(GAME)}, almost all of it {R(0xF86B)} and "
        f"{R(0xF7EB)} building the shift tables and the shifted landscape pieces -- took "
        f"{startup:,} T-states in the simulator, {startup / TSTATES:.2f} seconds. "
        f"Interrupts are never enabled: {R(0x5B80)} and {R(0x5C80)} both execute DI and "
        "nothing executes EI. There is no HALT and no interrupt routine, and the game's "
        "stack is the 128 bytes under $5B80, in the printer buffer.</p>",

        "<h3>One pass of play</h3>",
        f"<pre>{one_pass}</pre>",
        f"<p>{R(SHIP_PASS)} does not return to the loop itself: it jumps to {R(0xDDF8)}, which "
        f"jumps on to {R(0xC3E3)}, whose RET goes back to the play loop. The IY that "
        f"{R(SHIP_PASS)} pushes is popped by {R(0xC3E3)}; the push also puts the stack at "
        f"the depth the landscape renderer assumes when it reloads SP from {R(0x5B7A)} after "
        f"each piece -- checked in the simulator: {R(0xD0BD)} was entered with SP "
        f"${landscape_sp:04X}. The ship's image is redrawn on odd passes, the carried part "
        "on even ones; the side jet on odd passes and the lift jet on even; the shield timer "
        "counts on odd passes.</p>",

        "<h3>Timing</h3>",
        "<p>Nothing paces the game: with interrupts off it never waits for a frame, so a "
        "pass takes as long as its work. Measured in the simulator over "
        f"{count} passes of flying -- the flight to the terrace scene, then climbing left "
        f"and firing -- a pass took {pass_lengths[0]:,} to {pass_lengths[-1]:,} T-states, "
        f"{mean_pass:,.0f} on average: {mean_pass / FRAME:.1f} television frames, about "
        f"{per_second:.0f} passes a second. Where the time went, from the play loop round "
        "to the play loop, stopped after each stage of every pass:</p>",
        table(["Stopped at", "What ran", "T-states a pass", "Per cent"], stage_rows),
        "<p>So a busy screen plays slower, and a sound effect -- a timing loop inside the "
        "pass -- stalls the pass it is played in. Counts kept in passes (the shield, the "
        "death sequence, the fuel's grace) are not fixed lengths of time.</p>",

        "<h3>The death byte</h3>",
        f"<p>{R(bc.DYING)} is the whole of the death's state: 0 alive, set to 1 by a third "
        f"hit or an empty tank, counted up a pass at a time by {R(0x8D42)}; the play loop "
        "leaves for the death sequence at 12, which ends at $50 (see "
        "<a href=\"DamageAndFuel.html\">damage, fuel and dying</a>). "
        f"{R(0x96AB)} reaching $FF ends the level instead (see "
        "<a href=\"RocketAndOre.html\">the rocket</a>).</p>",

        "<h3>Two players</h3>",
        f"<p>The two players never need to know which one is playing: their whole 105-byte "
        f"records are swapped at each turn ({R(0xF591)}), and the one shared table, the "
        f"objects lying in the world ({R(0x5C94)}), gets its per-player bit by patching the "
        f"BIT and SET instructions that test it ({R(0xE114)}, {R(0xA8F4)}, {R(0xABA8)}).</p>",

        "<h3>Memory</h3>",
        "<p>The game runs from $5B00 to $FFFF. Below the loaded block are the stack, the "
        "four collision-box lists over the loader's entry and some forty scratch variables "
        "in the system variables. The block holds the world's level data first, then the "
        "tunes, the sound effects and the sprites, then the code with its tables and "
        "variables, the landscape pieces at its end. Above it: the menu and the game's "
        "flow, the player records, the ship's picture, and the start-up code that becomes "
        "a sprite buffer and a bit-reversal table, over the six pages of shift tables built "
        "on the loader's leftovers.</p>",
        table(["Addresses", "Starts at", "What"], region_rows),
        f"<p>The listing's entries by type, a byte a pixel, 256 to a row from $5B00 "
        f"(read from the listing): {key}.</p>",
        figure(images["memory"], "Memory from $5B00 to $FFFF, by the listing's entries."),

        confirmed([
            "Run in the simulator when this page was built: the start-up's length; the stack "
            "pointer at draw_landscape; a pass's T-states, stage by stage, over "
            f"{count} passes.",
            "Read from the code: the order of everything and the alternate-pass work. The "
            "memory map is the listing's entries.",
            "The simulator does not emulate the ULA's memory contention, so a real "
            "Spectrum's passes are somewhat longer than those measured here.",
        ]),
        "</div>"])


# --------------------------------------------------------------------------
# Together.
# --------------------------------------------------------------------------

PAGES = {
    "Architecture": _architecture_page,
    "Landscape": _landscape_page,
    "LandscapeCollision": _collision_page,
    "Drawing": _drawing_page,
    "Ship": _ship_page,
    "Objects": _objects_page,
    "RocketAndOre": _rocket_page,
    "DamageAndFuel": _damage_page,
}


def check_html(name: str, body: str) -> None:
    """A ref section's body: no line may start with ; or [ (a comment, a new
    section), and a # in front of a colour would be read as a macro."""
    for number, line in enumerate(body.split("\n"), 1):
        if line.startswith(";") or line.startswith("["):
            raise ValueError(f"{name}: line {number} starts with {line[0]!r}")
    if re.search(r"#[0-9A-Fa-f]{6}\b", body):
        raise ValueError(f"{name}: a colour written with # (use rgb())")
    for match in re.finditer(r"#([A-Z]+)", body):
        if match.group(1) not in ("R", "HTML", "LINK"):
            raise ValueError(f"{name}: '#{match.group(1)}' would be read as a skool macro")


def build(snapshot: Path, html_dir: Path, log=print, only=None) -> dict[str, str]:
    """Run the worked examples, draw the pictures into
    html_dir/images/howitworks and return the pages' HTML by section name."""
    snapshot = Path(snapshot)
    listing = Listing(snapshot.with_name("cyberun.skool"))
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
