"""Nightshade's "How it works" pages: how the game is put together, how the
town is drawn, how things move through it, the monsters and the antibodies,
and the quest.

build() returns each page's HTML for the build's generated ref file and
writes the pictures into html_dir/images/howitworks/. Nothing here is a
transcription of the game: every table is read from the game's memory as the
page is built, and every worked example is the game's own code, run in
SkoolKit's simulator -- the build's own Machine (build_nightshade.py), started
from the snapshot at $5E00 with R as the loader left it and FRAMES left
alone, and driven the way the build's sessions drive it: by keys, by the
game's own restart into a chosen cell, and by pokes made at the start of a
turn. Where a scene is staged by writing to memory, the page says what was
written.

Nightshade is Filmation II: a scrolling town with no heights, where Knight
Lore, Alien 8 and Pentagram have rooms of blocks. It shares their tune
player, menu, key reading, sprite rows and sound routines, and little else;
where it does what one of them does, the page says so briefly and links that
game's page, and puts its depth on what is Nightshade's own. The prose is
written from the listing's annotations and the stage 2 notes. Numbers the
prose quotes are read back from the runs, and the build stops if a run does
not come out the way the code says it must.
"""
from __future__ import annotations

import re
from pathlib import Path

import build_nightshade as bn
import nightshade_data as nd

IMAGE_URL = "images/howitworks"
KNIGHT_LORE = "../knightlore"
ALIEN8 = "../alien8"
PENTAGRAM = "../pentagram"
TSTATES = 3500000

# --------------------------------------------------------------------------
# Addresses read or run here (see their entries in the listing).
# --------------------------------------------------------------------------

LOADER = 0x5B80
FRAMES = 0x5C78
FRAMES_MIDDLE = 0x5C79
NMIADD = 0x5CB0
ENTRY = 0x5E00
TOWN = nd.MAP
START = 0xBDFE
NEW_GAME = 0xBE0F
MAIN_LOOP = 0xBE71
NEXT_OBJECT = 0xBE75
END_OF_TURN = 0xBECD
LIVES_BYTE = 0xBEDD
PERCENTAGE = 0xBEDF
PRINT_PERCENTAGE = 0xBF36
VISIT_CELL = 0xBF48
SPAWN_CREATURE = 0xBF95
CREATURE_UPDATE = 0xBFF1
MONSTER112_UPDATE = 0xC083
STRIKE_OUTCOME = 0xC0B9
MONSTER_HIT_TABLE = 0xC0D1
HIT_DESTROYS, HIT_CHANGES, HIT_SPLITS, HIT_DEMOTES = 0xC0DE, 0xC0ED, 0xC101, 0xC152
APPEARING_UPDATE = 0xC164
NEAREST_VILLAIN = 0xC19C
STOCK_BUILDINGS = 0xC1DB
RESET = 0xC1F9
DRAW_VILLAINS = 0xC1FD
ADD_SCORE = 0xC2ED
PICK_UP_THING = 0xC489
COLOUR_CARRIED = 0xC4DC
THING_COLOURS = 0xC52F
ANTIBODY_STRIKE = 0xC538
OBJECT_STRIKE = 0xC554
TOUCHING_KNIGHT = 0xC55F
TOUCH_TEST = 0xC572
NEXT_TURN = 0xC5B4
SPAWN_FIND = 0xC5CE
COLOUR_STRIP = 0xC889
COLOUR_KNIGHT = 0xC898
MENU = 0xC8CA
RANDOM_START_CELL = 0xCB7B
NEW_LIFE = 0xCBAC
TAKE_LIFE = 0xCBDD
GAME_OVER = 0xCC56
ENDING_RECORDS = 0xCCE4
SPAWN_MONSTER = 0xCDE8
WANDERING_MONSTER = 0xCE89
KNIGHT_KILLED = 0xCEC4
DRAW_CELLS = 0xCF08
DRAW_STEP = 0xCF5F
DRAW_FRONT_CELL = 0xCFA5
LIST_THINGS_IN_CELL = 0xCFAF
SORT_AND_DRAW_THINGS = 0xCFF2
DEPTH_TABLE = 0xD0A0
DEPTH_KEEP, DEPTH_SWAP, DEPTH_BY_CORNERS = 0xD0C4, 0xD0C5, 0xD0D0
DRAW_LIST = 0xD15D
TURN_CELL = 0xD17D
DRAW_OUTLINE = 0xD19D
DRAW_EDGE = 0xD273
PUT_EDGE = 0xD2B2
COLOUR_WALL = 0xD356
DRAW_WALLS = 0xD372
DRAW_WALL_COLUMN = 0xD3C2
TEST_COLUMN = 0xD3E2
CLAIM_COLUMN = 0xD3E6
PUT_TILE = 0xD425
PROJECT_THING = 0xD4F3
PROJECT_CELL = 0xD508
LOOK_UP_CELL = 0xD564
DISPATCH = 0xD593
UPDATES = nd.UPDATES
VILLAIN_SPARKLES = 0xD6D6
SPEED_BONUS = 0xD727
HITS_BONUS = 0xD74C
PLACE_BONUS = 0xD76C
VANISHING = 0xD7D8
ANTIBODY_FLIGHT = 0xD7ED
OBJECT_FLIGHT = 0xD80C
VILLAIN_DYING = 0xD847
CHECK_QUEST_DONE = 0xD865
PLACE_OBJECTS = 0xD88E
PLACE_VILLAINS = 0xD8E7
OBJECT_LYING = 0xD942
VILLAIN_WANDER = 0xD94F
FIND_WANDER = 0xD9A3
UPDATE_TOP = 0xD9EB
UPDATE_KNIGHT = 0xDA7A
KNIGHT_THROWS = 0xDAB7
TURN_TOWN = 0xDB68
TURN_KNIGHT = 0xDB89
KNIGHT_WALKS = 0xDC60
COAST_TABLE = 0xDC71
WALK_ON = 0xDCA8
WALK_STEP = 0xDCB5
SET_STEP = 0xDCE0
APPLY_STEP = 0xDD01
STEER = 0xDD28
KNIGHT_DIRECTION = 0xDD99
WANDER_STEP = 0xDDCF
RANDOM_STEP = 0xDDFC
MOVE_SPLIT = 0xDE0D
MOVE_CLIPPED = 0xDE59
MOVE_TABLE = 0xDE6A
CLIP_PLUS_V = 0xDE72
PLACE_IN_CELL = 0xE028
HIT_BOXES_U = 0xE063
HIT_BOXES_V = 0xE0A0
OVERLAP_U = 0xE087
MAKE_TABLES = 0xE0FB
COPY_BUFFER = 0xE148
COPY_ATTR_BUFFER = 0xE1AD
SHOW_PLAY_AREA = 0xE200
READ_CONTROLS = 0xE241
TURN_SPRITE = 0xE353
DRAW_SPRITE = 0xE3D9
BUFFER_ADDRESS = 0xE53A
BUFFER = 0xE5C4
ATTR_BUFFER = 0xF044
MIRROR_TABLES = 0xF200
REVERSE_TABLE = 0xF900
SHIFT_TABLES = 0xFA00

# Variables.
RANDOM = 0xBBAA
TURNS = 0xBBB2
CELL_LOOKED_UP = 0xBBB4
DRAW_X = 0xBBB6
DRAW_Y = 0xBBB8
VIEW = 0xBBBA
COLUMNS_DRAWN = 0xBBBB
TOP_SPEED = 0xBBBE
SCORE = 0xBBC9
LIVES = 0xBBCD
STOCKS = 0xBBCE
HITS = 0xBBF3
SPEED_TIME = 0xBBF5
PERCENT = 0xBBFD
ENDING = 0xBBFF
CONTROLS = 0xBC01
ARRIVING = 0xBC02
CARRIED = 0xBC03
VISITED = 0xBC0E

# The object records.
RECORD = 16
RECORD_COUNT = 23
KNIGHT = 0xBC8E
KNIGHT_TOP = 0xBC9E
ANTIBODIES = 0xBCAE
FINDS = 0xBCCE
BONUS = 0xBD0E
OBJECTS = 0xBD1E
VILLAINS = 0xBD5E
MONSTERS = 0xBD9E
RECORDS_END = 0xBDFE
START_RECORDS = 0xCC36

# Offsets into a record.
U, V, SPEED, FACING, FLAGS, SIZE_U, SIZE_V, STEP_U, STEP_V = 1, 3, 5, 6, 7, 8, 9, 10, 11

# The play area: the buffer's lines count up from its bottom, at y 72.
PLAY_BOTTOM = 72
PLAY_LINES = 112
BUFFER_ROW = 24
SHOWN_BYTES = 22

SPECTRUM = [(0, 0, 0), (0, 0, 0xD7), (0xD7, 0, 0), (0xD7, 0, 0xD7),
            (0, 0xD7, 0), (0, 0xD7, 0xD7), (0xD7, 0xD7, 0), (0xD7, 0xD7, 0xD7)]
SPECTRUM_BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF),
                   (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0), (0xFF, 0xFF, 0xFF)]
INKS = ["black", "blue", "red", "magenta", "green", "cyan", "yellow", "white"]
BACKGROUND = (20, 20, 60)
OUTLINE = (255, 64, 64)

RET = 0xC9


def _word(memory, address: int) -> int:
    return memory[address] | memory[address + 1] << 8


def _signed(byte: int) -> int:
    return byte - 256 if byte & 0x80 else byte


def _esc(text: str) -> str:
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def _bcd(value: int) -> int:
    return (value >> 4) * 10 + (value & 15)


def _check(condition: bool, what: str) -> None:
    """The prose says what the code does; if a run disagrees, the page would
    be wrong, so the build stops instead."""
    if not condition:
        raise RuntimeError(f"nightshade_howitworks: {what}")


def _numbers(values) -> str:
    """1, 2, 3, 5 as '1-3, 5'."""
    values = sorted(values)
    runs, start = [], None
    for index, value in enumerate(values):
        if start is None:
            start = value
        if index + 1 == len(values) or values[index + 1] != value + 1:
            runs.append(str(start) if start == value else f"{start}-{value}")
            start = None
    return ", ".join(runs)


# --------------------------------------------------------------------------
# The listing: which addresses are entries, for #R links.
# --------------------------------------------------------------------------

class Listing:
    """The entries of nightshade.skool and every label in it, read at build
    time, so a link is only made to an address that starts an entry."""

    def __init__(self, skool: Path):
        self.entries: dict[int, str] = {}
        self.labels: dict[int, str] = {}
        label = None
        if skool.exists():
            lines = skool.read_text(encoding="utf-8").split("\n")
        else:
            lines = []
        for line in lines:
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

    def r(self, address: int, text: str | None = None) -> str:
        """A link to an entry; an entry point inside one links its entry
        with the entry point's own label as the text."""
        if address in self.entries:
            return f"#R${address:04X}({text})" if text else f"#R${address:04X}"
        entry = self.entry_of(address)
        if entry is not None and (text or address in self.labels):
            return f"#R${entry:04X}({text or self.labels[address]})"
        self.unlinked.add(address)
        return text or f"${address:04X}"

    def name(self, address: int) -> str:
        return self.labels.get(address) or self.entries.get(address) or f"${address:04X}"


# --------------------------------------------------------------------------
# The game, in the simulator.
# --------------------------------------------------------------------------

class Game:
    """The game on the build's simulated Spectrum (build_nightshade.Machine),
    started from the menu with the keyboard and driven turn by turn."""

    def __init__(self, snapshot: Path, start: bool = True, r: int | None = None,
                 pokes: dict | None = None):
        self.machine = bn.Machine(snapshot)
        if r is not None:
            from skoolkit.simutils import R
            self.machine.simulator.registers[R] = r
        for address, value in (pokes or {}).items():
            self.memory[address] = value
        if start:
            self.play(bn._start("1"))
            self.play([bn.Until("a live knight", bn._playing, 30.0)])
            self.turns(1)

    @property
    def memory(self):
        return self.machine.memory

    @property
    def registers(self):
        return self.machine.simulator.registers

    @property
    def pc(self) -> int:
        return self.machine.pc

    @property
    def tstates(self) -> int:
        from skoolkit.simutils import T
        return self.registers[T]

    def play(self, steps) -> None:
        self.machine.play(steps, "how it works")

    def run_to(self, stop: int, seconds: float = 10.0, keys=(), stick: int = 0,
               required: bool = True) -> bool:
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
            if required:
                raise RuntimeError(f"the game never reached ${stop:04X} in {seconds} s "
                                   f"(PC ${self.machine.pc:04X})")
            return False
        return True

    def run_for(self, seconds: float, keys=()) -> None:
        """Run for a time with no stop, wherever it ends."""
        self.machine.run(seconds, keys)

    def turns(self, count: int = 1, keys=(), stick: int = 0) -> None:
        """Play whole turns, each to the start of the next."""
        for _ in range(count):
            self.run_to(MAIN_LOOP, 10.0, keys, stick)

    def go(self, u: int, v: int) -> None:
        """Into a cell by the game's own restart (build_nightshade._go), then
        on to the start of a turn."""
        self.play(bn._go(u, v))
        self.turns(1)

    def place_knight(self, u_low: int, v_low: int) -> None:
        """Both his records moved within his cell (the low bytes of U and V):
        a poke at the start of a turn, before his legs' update."""
        for base in (KNIGHT, KNIGHT_TOP):
            self.memory[base + U] = u_low
            self.memory[base + V] = v_low

    def clear_monsters(self) -> None:
        for index in range(6):
            self.memory[MONSTERS + RECORD * index] = 0

    def save(self):
        return (bytes(self.machine.simulator.memory), self.registers[:], self.machine.pc)

    def restore(self, state) -> None:
        self.machine.simulator.memory[:] = state[0]
        self.registers[:] = state[1]
        self.machine.pc = state[2]

    def reg(self, name: str) -> int:
        from skoolkit import simutils
        return self.registers[getattr(simutils, name)]

    def ix(self) -> int:
        return self.reg("IXh") << 8 | self.reg("IXl")

    def iy(self) -> int:
        return self.reg("IYh") << 8 | self.reg("IYl")

    def hl(self) -> int:
        return self.reg("H") << 8 | self.reg("L")

    @staticmethod
    def record(index: int) -> int:
        return KNIGHT + RECORD * index


def call(memory, address: int, registers: dict | None = None, seconds: float = 2.0,
         stops=()):
    """Run one routine on a fresh simulator over a copy of `memory` until it
    returns (or reaches one of `stops`); the simulator afterwards. A return
    address is pushed first, $5BFE, in the printer buffer, which the game
    never runs: the simulator stops as the routine's RET reaches it. The
    stack is the game's own, below $5E00."""
    from skoolkit import CSimulator, read_bin_file
    from skoolkit.simulator import Simulator
    from skoolkit.simutils import PC, SP

    memory = list(memory)
    if not any(memory[:0x4000]):
        memory[:0x4000] = read_bin_file(str(bn.ROM))
    trap = 0x5BFE
    stack = 0x5DF0
    memory[stack:stack + 2] = [trap & 0xFF, trap >> 8]
    simulator = (CSimulator or Simulator)(memory, state={"iff": 0, "im": 1, "tstates": 0})
    from skoolkit import simutils
    for name, value in (registers or {}).items():
        simulator.registers[getattr(simutils, name)] = value
    simulator.registers[SP] = stack
    simulator.registers[PC] = address
    simulator.set_tracer(bn._key_tracer_class()(simulator))
    limit = int(seconds * TSTATES)
    if not stops:
        # trace(start, stop, max_operations, max_time, interrupts, ...)
        simulator.trace(address, trap, 0, limit, False, None, None, None, None, None)
        if simulator.registers[PC] != trap:
            raise RuntimeError(f"${address:04X} did not return "
                               f"(PC ${simulator.registers[PC]:04X})")
        return simulator
    # Several places to stop: one instruction at a time.
    from skoolkit.simutils import T
    stop_at = set(stops) | {trap}
    while simulator.registers[T] < limit:
        simulator.trace(simulator.registers[PC], 0, 1, limit, False, None, None, None,
                        None, None)
        if simulator.registers[PC] in stop_at:
            return simulator
    raise RuntimeError(f"${address:04X} reached none of the stops")


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


def buffer_image(memory, colour: bool = True, as_stored: bool = False, margin: bool = False):
    """The play area as the buffers at BUFFER and ATTR_BUFFER hold it: 112
    lines of 24 bytes, the first the bottom line, so drawn from the bottom up
    it is the picture #R$E148 copies to the screen; `as_stored` draws it in
    memory order, first row at the top, which is upside down. Only the 22
    bytes of a row that reach the screen, unless `margin`, which adds the two
    hidden ones at the left, drawn dimmed."""
    from PIL import Image

    first = 0 if margin else 2
    width = (BUFFER_ROW - first) * 8
    image = Image.new("RGB", (width, PLAY_LINES))
    pixels = image.load()
    for row in range(PLAY_LINES):
        y = row if as_stored else PLAY_LINES - 1 - row
        for column in range(first, BUFFER_ROW):
            byte = memory[BUFFER + row * BUFFER_ROW + column]
            if colour:
                attr = memory[ATTR_BUFFER + (row >> 3) * BUFFER_ROW + column]
                palette = SPECTRUM_BRIGHT if attr & 0x40 else SPECTRUM
                ink, paper = palette[attr & 7], palette[(attr >> 3) & 7]
            else:
                ink, paper = (255, 255, 255), (0, 0, 0)
            if column < 2:
                ink = tuple(c // 2 + 40 for c in ink)
                paper = tuple(c // 2 + 40 for c in paper)
            for bit in range(8):
                pixels[(column - first) * 8 + bit, y] = ink if byte & (0x80 >> bit) else paper
    return image


def attr_image(memory):
    """The attribute buffer alone: each cell filled with its ink, inside a
    one-pixel border of its paper, so both show."""
    from PIL import Image, ImageDraw

    image = Image.new("RGB", (SHOWN_BYTES * 8, PLAY_LINES))
    draw = ImageDraw.Draw(image)
    for row in range(PLAY_LINES // 8):
        top = PLAY_LINES - 8 - row * 8
        for column in range(2, BUFFER_ROW):
            attr = memory[ATTR_BUFFER + row * BUFFER_ROW + column]
            palette = SPECTRUM_BRIGHT if attr & 0x40 else SPECTRUM
            left = (column - 2) * 8
            draw.rectangle([left, top, left + 7, top + 7], fill=palette[(attr >> 3) & 7])
            draw.rectangle([left + 1, top + 1, left + 6, top + 6], fill=palette[attr & 7])
    return image


def big(image, scale: int = 2):
    from PIL import Image

    return image.resize((image.width * scale, image.height * scale), Image.NEAREST)


def strip(images, gap: int = 4, background=BACKGROUND):
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


def grid(images, columns: int, gap: int = 4, background=BACKGROUND):
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


def sprite_of(memory, graphic: int, scale: int = 1):
    """A graphic's sprite, drawn from its bytes the way the listing's sprite
    pictures are (build_nightshade.sprite_image), on the page's background."""
    from PIL import Image

    image = bn.sprite_image(memory, _word(memory, nd.GRAPHICS + 2 * graphic), scale)
    out = Image.new("RGB", image.size, (90, 90, 140))
    out.paste(image, (0, 0), image)
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
        """A picture shown 512 wide (kl-stage)."""
        self.save(name, image)
        return f'<img class="kl-stage" src="{IMAGE_URL}/{name}" alt="{_esc(alt)}">'

    def piece(self, name: str, image, alt: str = "", scale: int = 2,
              css: str = "kl-piece") -> str:
        self.save(name, image)
        return (f'<img class="{css}" src="{IMAGE_URL}/{name}" alt="{_esc(alt)}" '
                f'width="{image.width * scale}" height="{image.height * scale}">')


def figure(img: str, caption: str) -> str:
    return f'<div class="kl-item">{img}<p>{caption}</p></div>'


def table(headings: list[str], rows: list[list]) -> str:
    head = "".join(f"<th>{h}</th>" for h in headings)
    body = "".join("<tr>" + "".join(f"<td>{cell}</td>" for cell in row) + "</tr>"
                   for row in rows)
    return f'<table class="kl-table"><tr>{head}</tr>{body}</table>'


def kl(page: str, text: str) -> str:
    return f'<a href="{KNIGHT_LORE}/{page}.html">{text}</a>'


def a8(page: str, text: str) -> str:
    return f'<a href="{ALIEN8}/{page}.html">{text}</a>'


def pg(page: str, text: str) -> str:
    return f'<a href="{PENTAGRAM}/{page}.html">{text}</a>'


def page(name: str, text: str) -> str:
    """A link to another of Nightshade's pages."""
    return f'<a href="{name}.html">{text}</a>'


def update_routine(memory, graphic: int) -> int:
    return _word(memory, UPDATES + 2 * graphic)


def graphic_runs(memory) -> list[tuple[int, int, int]]:
    """(first graphic, last graphic, routine) for each run of graphics that
    UPDATES gives the same routine."""
    runs = []
    for graphic in range(nd.GRAPHIC_COUNT):
        routine = update_routine(memory, graphic)
        if runs and runs[-1][2] == routine and runs[-1][1] == graphic - 1:
            runs[-1] = (runs[-1][0], graphic, routine)
        else:
            runs.append((graphic, graphic, routine))
    return runs


def graphics_text(first: int, last: int) -> str:
    return str(first) if first == last else f"{first}-{last}"


# --------------------------------------------------------------------------
# 1. How the game is put together.
# --------------------------------------------------------------------------

TRAP = 0x5BFE               # a return address pushed for START's RET to reach


def protection_trials(snapshot: Path) -> dict:
    """Each of the game's four checks, failed on purpose in the simulator,
    and what the game then did; and the same checks passed, as the tape
    leaves them."""
    from skoolkit.simutils import R, SP

    out = {}
    # 1. FRAMES' middle byte. START's RET goes back to whoever called it --
    # on a Spectrum, the ROM that ran PRINT USR; here a trap address pushed
    # for it.
    for label, value in (("intact", None), ("changed", 0x64)):
        game = Game(snapshot, start=False)
        game.memory[0x5DFE], game.memory[0x5DFF] = TRAP & 0xFF, TRAP >> 8
        game.registers[SP] = 0x5DFE
        if value is not None:
            game.memory[FRAMES_MIDDLE] = value
        returned = game.run_to(TRAP, 2.0, required=False)
        out[f"frames {label}"] = {"returned": returned, "tstates": game.tstates,
                                  "pc": game.pc}
    # 2. NMIADD without the tape's JP (HL): zero, as the ROM leaves it.
    game = Game(snapshot, start=False, pokes={NMIADD: 0})
    game.play([bn.At("the menu", bn.MENU_LOOP, 30.0), ([], 0.5), (["0"], 0.3)])
    first = game.run_to(MAIN_LOOP, 5.0, required=False)
    second = game.run_to(MAIN_LOOP, 5.0, required=False)
    out["nmiadd"] = {"first": first, "second": second, "pc": game.pc}
    # 3. R's bit 7 clear, as it would be without the loader.
    game = Game(snapshot, start=False)
    game.registers[R] &= 0x7F
    game.play([bn.At("the menu", bn.MENU_LOOP, 30.0), ([], 0.5), (["0"], 0.3)])
    out["r"] = {"reset": game.run_to(0x0000, 10.0, required=False)}
    game = Game(snapshot)
    out["r intact"] = {"playing": bn._playing(game.memory)}
    # 4. The infinite-lives poke: a NOP over the DEC (HL) that takes a life.
    game = Game(snapshot)
    out["take life byte"] = game.memory[TAKE_LIFE]
    game.memory[TAKE_LIFE] = 0x00
    bn._kill(game.memory)
    out["lives"] = {"reset": game.run_to(0x0000, 10.0, required=False)}
    return out


TIMING_STOPS = [(0xBE91, "every record updated"),
                (0xBEAD, "the finds, monsters, creature and bonus; the sound effect's note; "
                 "the panel's colours"),
                (0xBEB0, "the town and everything in it drawn into the buffer"),
                (END_OF_TURN, "the knight coloured; a new life; the end of the quest"),
                (0xBED0, "the buffers copied to the screen and cleared"),
                (MAIN_LOOP, "the flash ended; the pause key read")]
TIMING_EVERY = 13           # every 13th cell a knight can stand in
TIMING_TURNS = 8            # turns in each


def time_turns(snapshot: Path) -> dict:
    """Turns played walking (and now and then turning) in a spread of cells:
    the T-states each part of the turn took."""
    game = Game(snapshot)
    memory = game.memory
    cells = [(u, v) for v in range(32) for u in range(32) if nd.cell(memory, u, v) not in (1, 2)]
    phases = [[] for _ in TIMING_STOPS]
    totals = []
    for u, v in cells[::TIMING_EVERY]:
        game.go(u, v)
        for turn in range(TIMING_TURNS):
            bn._lives(memory)
            keys = ["a"] if turn % 4 else ["a", "x"]
            start = last = game.tstates
            for index, (stop, _) in enumerate(TIMING_STOPS):
                game.run_to(stop, 5.0, keys)
                phases[index].append(game.tstates - last)
                last = game.tstates
            totals.append(game.tstates - start)
    return {"phases": phases, "totals": totals, "cells": len(cells[::TIMING_EVERY])}


SCENE_CELL = (9, 23)        # an open cell with buildings behind and in front
SCENE_SPOT = (140, 160)     # the knight's place in it, the low bytes of U and V
BUSY_TURNS = 240


def one_turn(game: Game) -> list[dict]:
    """Every record's update in one turn: its graphic, its routine and the
    T-states it took, stopping at the main loop's call of DISPATCH and at
    the instruction after it."""
    out = []
    for _ in range(RECORD_COUNT):
        game.run_to(0xBE7B)
        record, start = game.ix(), game.tstates
        graphic = game.memory[record]
        game.run_to(0xBE7E)
        out.append({"record": record, "graphic": graphic, "tstates": game.tstates - start})
    return out


def busiest_turn(snapshot: Path) -> tuple[list[dict], object]:
    """A turn of real play with many records in use: the knight walked about
    a built-up part of the town, and the turn with the most records in use
    out of those watched is traced."""
    game = Game(snapshot)
    memory = game.memory
    game.go(*SCENE_CELL)
    best, best_state = -1, None
    for turn in range(BUSY_TURNS):
        bn._lives(memory)
        keys = ["a"] if turn % 6 else ["a", "x"]
        game.turns(1, keys)
        used = sum(1 for i in range(RECORD_COUNT) if memory[Game.record(i)])
        if used > best:
            best, best_state = used, game.save()
    game.restore(best_state)
    records = one_turn(game)
    game.run_to(END_OF_TURN)
    return records, screen_after(game)


def screen_after(game: Game):
    """The screen once this turn's buffers are copied to it."""
    game.run_to(0xBED0)
    return screen_image(game.memory)


RECORD_KINDS = [
    (KNIGHT, 1, "the knight's legs", "his whole update: the controls, turning, walking, "
     "throwing"),
    (KNIGHT_TOP, 1, "the knight's top", "follows the legs; its own poses"),
    (ANTIBODIES, 2, "antibodies in flight", "thrown by the knight"),
    (FINDS, 4, "finds in buildings", "and, when a villain dies, its sparkles"),
    (BONUS, 1, "a bonus", "a faster walk or the hits back"),
    (OBJECTS, 4, "the four objects", "lying, carried (the record then empty) or thrown"),
    (VILLAINS, 4, "the four villains", "each killed only by the object in the same place "
     "among the objects"),
    (MONSTERS, 6, "monsters", "or the creature"),
]

FIELDS = [
    ("+0", "graphic", "picks the update routine (#R$D599) and the sprite (#R$6E9E); 0 is an "
     "empty record"),
    ("+1, +2", "U", "the high byte the town's column, the low byte the place across the cell"),
    ("+3, +4", "V", "the same: the high byte the row"),
    ("+5", "speed", "units a turn along the facing; a find keeps the type of cell it came "
     "from here"),
    ("+6", "facing", "bits 6-7: $00 +V, $40 +U, $80 -V, $C0 -U; the low bits a count -- the "
     "knight's turn delay, a monster's turns to its next change of course"),
    ("+7", "flags", "bit 0 stopped by a wall this turn, bit 1 drawn this turn, bit 5 heads "
     "for the knight, bit 6 mirrored, bit 7 upside down (never set)"),
    ("+8, +9", "half-sizes", "how far it reaches from its centre along U and along V"),
    ("+A, +B", "step", "this turn's move along U and V, signed"),
    ("+C, +D", "drawing offset", "added to where its centre projects, for the sprite's "
     "bottom left corner"),
    ("+E, +F", "where drawn", "the pixel x and y it was drawn at"),
]

MEMORY_OUTLINE = [
    (0x5B00, 0x5C00, "the printer buffer, with the loader's routine at #R$5B80"),
    (0x5C00, 0x5CCB, "the system variables, two of them set by the tape: FRAMES and NMIADD"),
    (0x5CCB, 0x5E00, "what is left of the BASIC loader, and the game's stack, which grows "
     "down into it"),
    (0x5E00, 0x5E04, "the entry"),
    (0x5E04, 0x6204, "the town map: 32 rows of 32 cells, a byte each"),
    (0x6204, 0x62A4, "the drawing order: 32 records of five steps"),
    (0x62A4, 0x6576, "the building table, the box table and the boxes, and the edge picture "
     "under each tile"),
    (0x6576, 0x6CB6, "the building definitions: two faces of eight columns of two tiles each"),
    (0x6CB6, 0x7017, "the panel's frame, the font, the tile and graphic tables, the edge "
     "pictures"),
    (0x7017, 0xA257, "the sprites, with the carried things' pictures and the panel's icons "
     "among them"),
    (0xA257, 0xBB0A, "the tiles the buildings are drawn from"),
    (0xBB0A, 0xBBAA, "the border's characters"),
    (0xBBAA, 0xBC8E, "the variables"),
    (0xBC8E, 0xBDFE, "the 23 object records"),
    (0xBDFE, 0xE5C4, "the code, with the notes and tunes, the menu, the text and the record "
     "templates in it"),
    (0xE5C4, 0xF044, "the play area's pixel buffer: 112 lines of 24 bytes"),
    (0xF044, 0xF194, "its attribute buffer: 14 rows of 24"),
    (0xF194, 0xF200, "a byte the colour fill spills into, and unused bytes"),
    (0xF200, 0xF800, "tables for drawing mirrored at an even pixel, built at a new game"),
    (0xF800, 0xF900, "unused"),
    (0xF900, 0xFA00, "every byte reversed"),
    (0xFA00, 0x10000, "tables for drawing shifted by 2, 4 and 6 pixels"),
]


def _architecture_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    from skoolkit.snapshot import Snapshot

    R = listing.r
    memory = bn.game_memory(snapshot)
    r_register = Snapshot.get(str(snapshot)).r

    log("  the four checks, each failed on purpose...")
    trials = protection_trials(snapshot)
    _check(trials["frames changed"]["returned"], "START did not return with FRAMES changed")
    _check(not trials["frames intact"]["returned"], "START returned with FRAMES as the tape "
                                                    "left it")
    _check(trials["nmiadd"]["first"] and not trials["nmiadd"]["second"],
           "the game came round its main loop twice without NMIADD")
    _check(trials["r"]["reset"] and trials["r intact"]["playing"],
           "R's bit 7 did not decide between a reset and a game")
    _check(trials["take life byte"] == 0x35 and trials["lives"]["reset"],
           "the lives check did not reset the machine")
    _check(r_register & 0x80, "the snapshot's R has bit 7 clear")
    frames_return = trials["frames changed"]["tstates"]

    log("  a turn's time, part by part...")
    timing = time_turns(snapshot)
    totals = timing["totals"]
    mean = sum(totals) / len(totals)
    timing_rows = []
    for (stop, what), values in zip(TIMING_STOPS, timing["phases"]):
        timing_rows.append([what, f"{min(values):,}", f"{round(sum(values) / len(values)):,}",
                            f"{max(values):,}"])
    timing_rows.append(["<b>the whole turn</b>", f"<b>{min(totals):,}</b>",
                        f"<b>{round(mean):,}</b>", f"<b>{max(totals):,}</b>"])
    copy = timing["phases"][4]
    _check(min(copy) == max(copy), "the copy to the screen did not take the same time every "
                                   "turn")
    draw = timing["phases"][2]
    _check(sum(draw) > sum(totals) / 2, "the drawing is not most of a turn")

    log("  one busy turn, record by record...")
    records, screen = busiest_turn(snapshot)
    in_use = [r for r in records if r["graphic"]]
    record_rows = []
    for entry in records:
        index = (entry["record"] - KNIGHT) // RECORD
        graphic = entry["graphic"]
        routine = update_routine(memory, graphic)
        record_rows.append([index, f"${entry['record']:04X}", graphic, R(routine),
                            f"{entry['tstates']:,}"])
    busy_fig = figure(pictures.stage("architecture_turn.png", big(screen),
                                     "The screen after the turn traced"),
                      f"The screen after the turn in the table: {len(in_use)} of the 23 "
                      "records in use. The play area is the framed part; the panel below "
                      "and down the left side is drawn straight onto the screen.")

    slowest = max(records, key=lambda r: r["tstates"])
    sound_note = ""
    if 128 <= slowest["graphic"] <= 131:
        sound_note = (f" The sounds are played inside the updates, and nothing else happens "
                      f"while they play: record {(slowest['record'] - KNIGHT) // RECORD}, a "
                      f"monster appearing on the screen, spent {slowest['tstates']:,} "
                      f"T-states on its note ({R(0xC455)}).")

    kind_rows = []
    for base, count, what, note in RECORD_KINDS:
        index = (base - KNIGHT) // RECORD
        numbers = str(index) if count == 1 else f"{index}-{index + count - 1}"
        kind_rows.append([numbers, R(base), what, note])

    run_rows = []
    for first, last, routine in graphic_runs(memory):
        run_rows.append([graphics_text(first, last), R(routine)])

    outline_rows = []
    for start, end, what in MEMORY_OUTLINE:
        link = R(start) if start in listing.entries else f"${start:04X}"
        outline_rows.append([link, f"${end - 1:04X}", f"{end - start:,}", what])

    lives = memory[LIVES_BYTE] >> 2
    _check(lives == 6, f"the lives byte gives {lives}")

    return "\n".join([
        '<div class="kl-list">',
        "<p>Nightshade (1985) is the first of Ultimate's Filmation II games. Where Knight "
        "Lore, Alien 8 and Pentagram show one room at a time, Nightshade's town scrolls: "
        "the knight stays in the middle of the screen and the streets move under him. "
        "It keeps the earlier games' tune player, menu, key reading, sprite rows and "
        "several sound routines, but the town, how it is drawn, how things move through "
        "it, the object records and the quest are all its own. This page is the "
        "game's outline: the tape and its protection, a turn of the main loop, the object "
        "records and how each is updated, and where everything is in memory.</p>",

        "<h3>The tape, and the four checks</h3>",
        "<p>The tape's BASIC loader loads a loading screen and then four blocks: the game, "
        f"{bn.LOAD_LENGTH:,} bytes at ${bn.LOAD_ADDRESS:04X}; {bn.LOADER_LENGTH} bytes into "
        f"the printer buffer at {R(LOADER)}; one byte into the system variable NMIADD at "
        f"{R(NMIADD)}; and two into FRAMES at ${FRAMES:04X}. Then <code>PRINT USR "
        f"{LOADER}</code> runs the routine in the printer buffer. It turns the interrupts "
        "off for good, sets bit 7 of the R register, and unscrambles the game block a pair "
        "of bytes at a time: RLD swaps a nibble between the two, so a pair loaded as "
        "<i>ab cd</i> (a nibble a letter) becomes <i>ac db</i>. Then it moves the block "
        f"down 512 bytes to {R(ENTRY)} and jumps there. The build does the same to the "
        "tape's block and checks that the result is what the snapshot holds.</p>",
        "<p>Each of the three small blocks is a check the game makes on itself, and a "
        "copy that skips any of them does not play. A fourth check is aimed at players "
        "rather than copiers. Each was tried in the simulator when this page was built, "
        "by undoing what the tape did:</p>",
        table(["Check", "Where", "What the tape leaves", "Undone in the simulator"], [
            ["FRAMES", R(START),
             f"FRAMES' middle byte ${memory[FRAMES_MIDDLE]:02X}. Interrupts are off from "
             "the loader on, so FRAMES never counts again",
             f"With the middle byte changed, START's RET went straight back to its caller, "
             f"after {frames_return} T-states. Left as the tape set it, the game went on "
             "into its menu"],
            ["NMIADD", f"{R(DISPATCH)}, for every object",
             f"${memory[NMIADD]:02X}, <code>JP (HL)</code>, in NMIADD. Every table of "
             "routines in the game is reached through a jump to it",
             f"With NMIADD zero, as the ROM leaves it, the game got as far as its first turn "
             f"and never came round to a second: after five seconds of the game's time the "
             f"processor was at ${trials['nmiadd']['pc']:04X}"],
            ["R's bit 7", R(STOCK_BUILDINGS),
             f"R ${r_register:02X}: bit 7 set by the loader. The refresh counter counts only "
             "the low seven bits, so only a program's LD R,A can set it",
             "With bit 7 clear, starting a game from the menu jumped to address 0: the "
             "Spectrum starts again from its copyright message. With it set, the game "
             "played"],
            ["The lives", R(NEW_LIFE),
             f"the DEC (HL) that takes a life, at ${TAKE_LIFE:04X}, which each new life "
             f"checks is still ${trials['take life byte']:02X}",
             "With a NOP there, the obvious infinite-lives poke, the knight's first death "
             "jumped to address 0"],
        ]),
        f"<p>The number of lives is hidden too: a new game takes it from the opcode of the "
        f"JR that closes the main loop, at ${LIVES_BYTE:04X}: ${memory[LIVES_BYTE]:02X} "
        f"shifted right twice is {lives}, and the first life takes one of them.</p>",

        "<h3>A turn</h3>",
        f"<p>There is no clock in the game at all. Interrupts are off from the loader on, "
        f"there is no HALT to wait for the television frame, and nothing counts time but "
        f"the turns themselves. {R(NEW_GAME)} sets a game up and falls into MAIN_LOOP, one "
        "turn, which goes round for as long as the game lasts:</p>",
        "<ol>"
        f"<li>Every object record is updated, the knight's legs first: its graphic picks "
        f"a routine from {R(UPDATES)}, called through {R(DISPATCH)} with IX on the record, "
        f"and the random number is stirred after each ({R(NEXT_TURN)}).</li>"
        f"<li>The turn is counted. Unless the ending is playing: every sixteenth turn a "
        f"find may appear in the knight's cell ({R(SPAWN_FIND)}); every fourth, a monster "
        f"round him ({R(SPAWN_MONSTER)}); every 256th, the creature "
        f"({R(SPAWN_CREATURE)}); a bonus when there is none ({R(PLACE_BONUS)}); a note "
        f"of any sound effect playing; and the carried things coloured on the panel "
        f"({R(COLOUR_CARRIED)}).</li>"
        f"<li>The town and everything in it are drawn into the buffer ({R(DRAW_CELLS)}; "
        f"see {page('Drawing', 'how the town is drawn')}).</li>"
        f"<li>The knight is coloured by his hits, a new life started if his record has "
        f"emptied ({R(NEW_LIFE)}), and the game ended if the villains are gone "
        f"({R(CHECK_QUEST_DONE)}).</li>"
        f"<li>END_OF_TURN: the buffers are copied to the screen and cleared "
        f"({R(SHOW_PLAY_AREA)}), a villain's flash is kept for the next turn's colours "
        "and ended, and the pause key is read.</li>"
        "</ol>",
        f"<p>So a turn takes as long as it takes. Timed in the simulator when this page was "
        f"built, {len(totals)} turns of walking (and now and then turning) in "
        f"{timing['cells']} cells spread across the town, in T-states:</p>",
        table(["Part of the turn", "Least", "Mean", "Most"], timing_rows),
        f"<p>The mean turn is {mean / TSTATES * 1000:.0f} milliseconds, about "
        f"{TSTATES / mean:.0f} turns a second; the quickest ran at "
        f"{TSTATES / min(totals):.0f} a second and the slowest at "
        f"{TSTATES / max(totals):.1f}. The drawing is most of it, and it depends on how "
        "much of the town is built up round the knight: the game slows down among the "
        "buildings and speeds up in the open. Copying the buffers to the screen and "
        f"clearing them costs exactly the same {copy[0]:,} every turn. Knight Lore, Alien 8 "
        f"and Pentagram pad a quiet turn out with a delay ({a8('Drawing', 'Alien 8')}); "
        "Nightshade has none.</p>",

        "<h3>The object records</h3>",
        f"<p>Everything that moves is one of 23 records of 16 bytes from {R(KNIGHT)}: half "
        "the size of the earlier games' records, since nothing in the town has a height or "
        "falls. Each kind of thing has its own records, and the order matters: a thrown "
        "object only ever looks for the villain four records on from its own, so the "
        f"pairing of objects and villains is the order of the records "
        f"({page('Quest', 'the quest')}).</p>",
        table(["Records", "From", "What", ""], kind_rows),
        "<p>The fields, as the update routines use them:</p>",
        table(["Offset", "Field", "What it is"], [list(f) for f in FIELDS]),
        f"<p>One turn of real play, the knight walked about a built-up part of the town "
        f"from cell ({SCENE_CELL[0]},{SCENE_CELL[1]}) and the turn with the most records in "
        f"use out of {BUSY_TURNS} traced: every record, in the order the main loop takes "
        f"them, with its graphic, the routine that graphic picks, and the T-states that "
        f"routine took. An empty record costs the jump to {R(update_routine(memory, 0))}, "
        f"which returns at once.{sound_note}</p>",
        table(["Record", "Address", "Graphic", "Update routine", "T-states"], record_rows),
        busy_fig,

        "<h3>Graphics and their routines</h3>",
        f"<p>The graphic number is the whole of a record's kind: {R(UPDATES)} gives each of "
        f"the {nd.GRAPHIC_COUNT} graphics its update routine, and a thing changes what it "
        "is by changing its graphic -- a monster appearing counts up through 128-131 and "
        "then becomes a monster, anything destroyed becomes graphic 12, the start of a "
        "puff. The graphics come in runs of four frames or directions, and a run shares a "
        "routine:</p>",
        table(["Graphics", "Update routine"], run_rows),
        f"<p>Every table of routines is reached the same way: {R(DISPATCH)} looks the "
        "address up and jumps not to it but to NMIADD, where the tape's JP (HL) makes the "
        f"jump. Besides {R(UPDATES)} there are five small tables: what an antibody does to "
        f"a monster ({R(MONSTER_HIT_TABLE)}), the depth sort's outcomes ({R(DEPTH_TABLE)}), "
        f"and three by the knight's or a walker's facing -- coming to a stop "
        f"({R(COAST_TABLE)}), turning towards the knight ({R(0xDD6A)}) and stopping at the "
        f"walls ({R(MOVE_TABLE)}).</p>",

        "<h3>Where everything is</h3>",
        table(["From", "To", "Bytes", "What"], outline_rows),
        f"<p>The game's code runs from {R(START)} to ${BUFFER - 1:04X}; below it are the "
        "level data and the graphics, above it the buffers and the tables it builds at "
        f"every new game ({R(MAKE_TABLES)}). The stack is set once, at {R(START)}, below "
        "the game, and is never set again: every game over leaves two bytes on it and "
        "every ending four, since those are jumped into from routines that were called. "
        "After 156 game overs in one sitting it has crept down over NMIADD and the game "
        f"crashes (measured by stage 2 of this disassembly; see {R(START)}).</p>",

        "<h3>Beside the earlier games</h3>",
        table(["", "Knight Lore, Alien 8, Pentagram", "Nightshade"], [
            ["The world", "rooms of blocks, one at a time", f"a scrolling town of 32 by 32 "
             f"cells ({R(TOWN)})"],
            ["Heights", "everything has a Z, and falls", "none"],
            ["Object records", f"40, 56 and 54 records of 32 bytes "
             f"({kl('Architecture', 'Knight Lore')}, {a8('Architecture', 'Alien 8')})",
             "23 of 16"],
            ["Drawing", "only what changed, redrawn in rectangles",
             "the whole play area every turn"],
            ["Pacing", "a delay pads out a quiet turn", "none: a turn takes what it takes"],
            ["Dispatch", "JP (HL) in the code", "JP (HL) in NMIADD, loaded from the tape"],
        ]),

        "<h3>Confirmed and inferred</h3>",
        "<ul>"
        "<li>Run in the simulator when this page was built: the four checks, each undone in "
        "turn; the timing of a turn's parts; the records of a busy turn.</li>"
        "<li>Read from the code: the load and the unscrambling (and checked by the build "
        "against the tape every time); the turn's order; the records' fields; the lives "
        "from the JR's opcode.</li>"
        "<li>Inferred: that the lives byte was chosen as a guard; nothing says so, but it "
        "works as one.</li>"
        "</ul>",
        "</div>"])


# --------------------------------------------------------------------------
# Together.
# --------------------------------------------------------------------------

PAGES = {
    "Architecture": "_architecture_page",
    "Drawing": "_drawing_page",
    "Movement": "_movement_page",
    "Creatures": "_creatures_page",
    "Quest": "_quest_page",
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
    listing = Listing(snapshot.with_name("nightshade.skool"))
    pictures = Pictures(html_dir)
    sections = {}
    for name, function in PAGES.items():
        if only and name not in only:
            continue
        if function not in globals():
            continue
        log(f"Writing the how-it-works page {name}...")
        body = globals()[function](snapshot, listing, pictures, log)
        check_html(name, body)
        sections[name] = body
    if listing.unlinked:
        # Not an error -- the address is still printed -- but a link was meant.
        log("  how it works: no entry to link at " + ", ".join(
            f"${a:04X}" for a in sorted(listing.unlinked)))
    return sections


# --------------------------------------------------------------------------
# 2. How the town is drawn.
# --------------------------------------------------------------------------

DRAW_SCENE_SPOT = (104, 200)    # the knight near the back of SCENE_CELL, on the
                                # eight-unit grid he comes to rest on (#R$DC60)
DRAW_SCENE_MONSTER = (72, 40, -70)   # a monster of 64-79 put in front of him: graphic, dU, dV
NEIGHBOURS = [(-1, 1), (-1, 0), (0, 1), (-1, -1), (1, 1)]   # bits 0-4 of the pattern
FRONT = [(0, 0), (0, -1), (1, 0), (1, -1)]                   # drawn last, in this order
COLUMNS_START = 0xE001          # COLUMNS_DRAWN at the start of every turn


def cell_name(du: int, dv: int) -> str:
    if not du and not dv:
        return "his own"
    parts = []
    if du:
        parts.append(f"U{du:+d}")
    if dv:
        parts.append(f"V{dv:+d}")
    return " ".join(parts)


def project(du: int, dv: int) -> tuple[int, int]:
    """PROJECT_POINT's formula, for a point dU and dV from the knight: x and y
    (y counting up the screen, as the buffer's lines do)."""
    return (du + dv + 0xF0) >> 1, (dv - du + 0x1B0) >> 2


def _signed16(value: int) -> int:
    return value - 65536 if value & 0x8000 else value


def stage_scene(game: Game, spot=DRAW_SCENE_SPOT, monster=DRAW_SCENE_MONSTER) -> None:
    """At the start of a turn: the knight at `spot` in his cell, no monsters
    but one of 64-79 in front of him."""
    memory = game.memory
    game.place_knight(*spot)
    game.clear_monsters()
    if monster:
        graphic, du, dv = monster
        bn._beside_knight(MONSTERS, graphic, du, dv)(memory)


def scene_game(snapshot: Path, spot=DRAW_SCENE_SPOT, monster=DRAW_SCENE_MONSTER) -> Game:
    """The game at the start of a turn with the drawing's scene staged: the
    knight into SCENE_CELL by the game's own restart, then moved within it,
    the monsters cleared and one put in front of him, and two turns played
    so that everything has settled; then staged again."""
    game = Game(snapshot)
    game.go(*SCENE_CELL)
    for _ in range(2):
        stage_scene(game, spot, monster)
        game.turns(1)
    stage_scene(game, spot, monster)
    return game


def trace_drawing(game: Game) -> dict:
    """Follow one turn's drawing (#R$CF08) step by step: the buffer and
    COLUMNS_DRAWN after each of the five cells behind the knight and each of
    the four in front, where each wall's cell corner projected to, and the
    buffer when the turn is done."""
    memory = game.memory
    stages = []

    def capture(what: str, cell, action):
        columns = memory[COLUMNS_DRAWN] | memory[COLUMNS_DRAWN + 1] << 8
        stages.append({"what": what, "cell": cell, "action": action,
                       "image": buffer_image(memory), "columns": columns,
                       "ink": 4 + (memory[0xBBC0] & 3)})

    game.run_to(DRAW_STEP)
    # Where the knight is once every record has been updated this turn.
    knight_u = _word(memory, KNIGHT + U)
    knight_v = _word(memory, KNIGHT + V)
    view = memory[VIEW] & 1
    capture("start", None, None)
    corners = []
    for _ in range(5):
        game.run_to(0xCF81)
        action, hl = game.reg("A"), game.hl()
        cell = (hl & 0xFF, hl >> 8)
        if action == 1:
            game.run_to(0xD38A)
            corners.append((cell, _signed16(_word(memory, DRAW_X)),
                            _signed16(_word(memory, DRAW_Y))))
        elif action == 0:
            game.run_to(0xCFAA)
        game.run_to(0xCF8D)
        capture("back", cell, action)
    for _ in range(4):
        game.run_to(DRAW_FRONT_CELL)
        hl = game.hl()
        cell = (hl & 0xFF, hl >> 8)
        game.run_to(0xCFAA)
        capture("outline", cell, 2)
    game.run_to(0xBEB0)
    capture("things", None, None)
    game.run_to(END_OF_TURN)
    capture("done", None, None)
    return {"stages": stages, "corners": corners, "knight": (knight_u, knight_v),
            "view": view}


def scene_variant(snapshot: Path, patches: dict, pokes: dict | None = None,
                  spot=DRAW_SCENE_SPOT, monster=DRAW_SCENE_MONSTER):
    """The scene's turn run again with some of the drawing's code patched
    (a RET over a routine's first byte, say) or some variables written at the
    start of the turn: the buffer at the end of the turn."""
    game = scene_game(snapshot, spot, monster)
    memory = game.memory
    for address, value in patches.items():
        memory[address] = value
    for address, value in (pokes or {}).items():
        memory[address] = value
    game.run_to(END_OF_TURN)
    return game


def tile_columns(snapshot: Path, patches: dict) -> list[int]:
    """The scene's turn run an instruction at a time from DRAW_CELLS to the
    end of the drawing, with `patches` applied: the x of every tile
    PUT_TILE is called for."""
    from skoolkit.simutils import PC, T

    game = scene_game(snapshot)
    memory = game.memory
    for address, value in patches.items():
        memory[address] = value
    game.run_to(DRAW_CELLS)
    simulator = game.machine.simulator
    pc, xs = game.pc, set()
    limit = simulator.registers[T] + 2 * TSTATES
    while pc != 0xBEB0:
        if pc == PUT_TILE:
            xs.add(memory[DRAW_X])
        simulator.trace(pc, 0, 1, limit, False, None, None, None, None, None)
        pc = simulator.registers[PC]
        if simulator.registers[T] >= limit:
            raise RuntimeError("the drawing never ended")
    return sorted(xs)


def claims_image(stages: list[dict], cell_size: int = 16):
    """COLUMNS_DRAWN as a row of sixteen boxes after each wall: grey for the
    four claimed before any wall is drawn, and each other box in the ink of
    the wall that claimed it; the eleven columns the screen shows are
    underlined."""
    from PIL import Image, ImageDraw

    walls = [s for s in stages if s["what"] == "back"]
    rows = len(walls) + 1
    image = Image.new("RGB", (16 * cell_size + 1, rows * (cell_size + 6) + 4), BACKGROUND)
    draw = ImageDraw.Draw(image)
    owner = {}
    previous = COLUMNS_START
    for k in range(16):
        if COLUMNS_START >> k & 1:
            owner[k] = (110, 110, 110)
    snapshots = [dict(owner)]
    for stage in walls:
        new = stage["columns"] & ~previous
        for k in range(16):
            if new >> k & 1:
                owner[k] = SPECTRUM_BRIGHT[stage["ink"]]
        previous = stage["columns"]
        snapshots.append(dict(owner))
    for row, owned in enumerate(snapshots):
        top = row * (cell_size + 6) + 2
        for k in range(16):
            box = [k * cell_size, top, (k + 1) * cell_size - 2, top + cell_size - 2]
            draw.rectangle(box, fill=owned.get(k, (0, 0, 0)), outline=(90, 90, 140))
        draw.line([2 * cell_size, top + cell_size, 13 * cell_size - 2, top + cell_size],
                  fill=(255, 255, 255))
    return image


def label(draw, xy, text: str, colour, centred: bool = True) -> None:
    """Text on a dark box, so that it reads over a picture."""
    left, top, right, bottom = draw.textbbox((0, 0), text)
    width, height = right - left, bottom - top
    x, y = xy
    if centred:
        x -= width // 2
    draw.rectangle([x - 2, y - 2, x + width + 2, y + height + 3], fill=(10, 10, 30))
    draw.text((x - left, y - top), text, fill=colour)


def nine_cells_image(memory, trace: dict, screen):
    """The knight's cell and the eight round it, projected by the game's
    formula (checked against the game's own projection of every wall's
    cell), each marked with what the drawing order drew there, and the play
    area with this turn's picture in it, dimmed."""
    from PIL import Image, ImageDraw

    ku, kv = trace["knight"]
    cu, cv = ku >> 8, kv >> 8
    roles = {}
    for stage in trace["stages"]:
        if stage["cell"] is None:
            continue
        du, dv = stage["cell"][0] - cu, stage["cell"][1] - cv
        if trace["view"]:
            du, dv = -du, -dv
        roles[(du, dv)] = {1: "walls", 0: "things", 2: "outline, things"}[stage["action"]]
    points = {}
    for du in (-1, 0, 1, 2):
        for dv in (-1, 0, 1, 2):
            points[(du, dv)] = project((cu + du) * 256 - ku, (cv + dv) * 256 - kv)
    xs = [p[0] for p in points.values()]
    ys = [p[1] for p in points.values()]
    left, top = min(xs) - 8, max(ys) + 8
    width, height = max(xs) + 8 - left, top - (min(ys) - 8)

    def at(x, y):
        return (x - left, top - y)

    image = Image.new("RGB", (width, height), BACKGROUND)
    shown = Image.blend(screen, Image.new("RGB", screen.size, BACKGROUND), 0.45)
    image.paste(shown, at(32, 72 + PLAY_LINES - 1))
    draw = ImageDraw.Draw(image)
    fills = {"walls": (240, 170, 60), "things": (120, 220, 120),
             "outline, things": (130, 180, 255)}
    for du in (-1, 0, 1):
        for dv in (-1, 0, 1):
            corners = [points[(du, dv)], points[(du + 1, dv)], points[(du + 1, dv + 1)],
                       points[(du, dv + 1)]]
            draw.polygon([at(*p) for p in corners], outline=fills.get(roles.get((du, dv)),
                                                                      (90, 90, 90)))
    x0, y0 = at(32, 72 + PLAY_LINES)
    x1, y1 = at(32 + 176, 72)
    draw.rectangle([x0, y0, x1, y1], outline=(255, 255, 255))
    for du in (-1, 0, 1):
        for dv in (-1, 0, 1):
            corners = [points[(du, dv)], points[(du + 1, dv)], points[(du + 1, dv + 1)],
                       points[(du, dv + 1)]]
            role = roles.get((du, dv))
            colour = fills.get(role, (160, 160, 160))
            mx = sum(p[0] for p in corners) // 4
            my = sum(p[1] for p in corners) // 4
            tx, ty = at(mx, my)
            label(draw, (tx, ty - 12), cell_name(du, dv) + (" cell" if not du and not dv
                                                             else ""), colour)
            if role:
                label(draw, (tx, ty + 2), role, colour)
    kx, ky = at(*project(0, 0))
    draw.ellipse([kx - 3, ky - 3, kx + 3, ky + 3], fill=(255, 64, 64))
    return image


DEPTH_CELL_SPOT = (128, 128)
DEPTH_THINGS = [(BONUS, 3, -60, 60), (OBJECTS, 7, 40, -40), (OBJECTS + RECORD, 6, 26, 26)]


def depth_example(snapshot: Path) -> dict:
    """Three things staged in the knight's own cell -- a bonus behind him and
    two objects, one in front and one beside him -- and the order the depth
    sort draws the five records in, stopping at every call of DRAW_SPRITE
    while his cell's things are drawn."""
    game = Game(snapshot)
    memory = game.memory
    u, v = open_cell(memory)
    game.go(u, v)

    def stage():
        game.place_knight(*DEPTH_CELL_SPOT)
        game.clear_monsters()
        for record, graphic, du, dv in DEPTH_THINGS:
            bn._beside_knight(record, graphic, du, dv)(memory)
            if record != BONUS:
                memory[record + SIZE_U] = memory[record + SIZE_V] = 8
    stage()
    game.turns(1)
    stage()
    game.run_to(0xCF91)
    game.run_to(SORT_AND_DRAW_THINGS)
    listed = []
    address = DRAW_LIST
    while _word(memory, address):
        listed.append(_word(memory, address))
        address += 2
    boxes = {}
    for record in listed:
        boxes[record] = (memory[record], memory[record + U], memory[record + V],
                         memory[record + SIZE_U], memory[record + SIZE_V])
    order = []
    for _ in listed:
        game.run_to(DRAW_SPRITE)
        order.append(game.ix())
    game.run_to(END_OF_TURN)
    return {"cell": (u, v), "listed": listed, "order": order, "boxes": boxes,
            "image": buffer_image(memory), "knight": (memory[KNIGHT + U], memory[KNIGHT + V])}


def depth_picture(example: dict, scale: int = 3):
    """The buffer where the things are, with each record's box drawn on the
    ground as the projection puts it, numbered in the order drawn."""
    from PIL import ImageDraw

    image = big(example["image"], scale)
    draw = ImageDraw.Draw(image)
    ku, kv = example["knight"]
    colours = [(255, 90, 90), (255, 190, 60), (80, 230, 120), (90, 170, 255)]
    groups = []
    for number, record in enumerate(example["order"], 1):
        box = example["boxes"][record][1:]
        for group in groups:
            if group[0] == box:
                group[1].append(number)
                break
        else:
            groups.append((box, [number]))

    def screen(u, v):
        x, y = project(u - ku, v - kv)
        return ((x - 32) * scale, (PLAY_BOTTOM + PLAY_LINES - 1 - y) * scale)

    for index, (box, numbers) in enumerate(groups):
        u, v, su, sv = box
        corners = [(u - su, v - sv), (u + su, v - sv), (u + su, v + sv), (u - su, v + sv)]
        colour = colours[index % len(colours)]
        draw.polygon([screen(*c) for c in corners], outline=colour, width=2)
        x, y = screen(u + su, v + sv)
        label(draw, (x + 6, y - 6), ", ".join(map(str, numbers)), colour, centred=False)
    return image


def depth_outcomes(memory) -> list[tuple[int, int]]:
    return [(index, _word(memory, DEPTH_TABLE + 2 * index)) for index in range(18)]


U_WORDS = ["the candidate wholly at larger U", "they overlap in U",
           "the candidate wholly at smaller U"]
V_WORDS = ["wholly at larger V", "overlapping in V", "wholly at smaller V"]


def knight_colours(snapshot: Path) -> list:
    """The knight, cropped from the scene's buffer, with three hits, two and
    one: HITS written at the start of the turn."""
    images = []
    for hits in (3, 2, 1):
        game = scene_variant(snapshot, {}, {HITS: hits}, spot=(128, 128), monster=None)
        image = buffer_image(game.memory)
        x, y = project(0, 0)
        images.append(big(image.crop((x - 32 - 16, PLAY_LINES - 1 - (y - PLAY_BOTTOM) - 44,
                                      x - 32 + 20, PLAY_LINES - 1 - (y - PLAY_BOTTOM) + 4)), 3))
    return images


def _drawing_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    R = listing.r
    memory = bn.game_memory(snapshot)

    log("  the scene's turn, cell by cell...")
    game = scene_game(snapshot)
    trace = trace_drawing(game)
    stages = trace["stages"]
    ku, kv = trace["knight"]
    for cell, x, y in trace["corners"]:
        ex, ey = project(cell[0] * 256 - ku, cell[1] * 256 - kv)
        _check((x, y) == (ex, ey), f"cell {cell}'s corner projected to {x}, {y}, not the "
                                   f"formula's {ex}, {ey}")
    _check(stages[0]["columns"] == COLUMNS_START, "COLUMNS_DRAWN did not start at $E001")
    backs = [s for s in stages if s["what"] == "back"]
    fronts = [s for s in stages if s["what"] == "outline"]
    cu, cv = ku >> 8, kv >> 8
    pattern = 0
    for bit, (du, dv) in enumerate(NEIGHBOURS):
        if nd.cell(memory, cu + du, cv + dv):
            pattern |= 1 << bit
    steps = nd.draw_steps(memory, pattern)
    _check([(cu + du, cv + dv, a) for du, dv, a in steps]
           == [(s["cell"][0], s["cell"][1], s["action"]) for s in backs],
           "the cells drawn behind the knight are not the drawing order's record")
    _check([s["cell"] for s in fronts] == [(cu + du, cv + dv) for du, dv in FRONT],
           "the cells in front were not drawn in the order read")
    final = stages[-1]["image"]
    screen_fig_img = pictures.stage("drawing_scene.png", big(final, 3),
                                    "The scene as the turn ends")

    stage_rows = []
    stage_images = [stages[0]["image"]]
    previous = COLUMNS_START
    for number, stage in enumerate(backs, 1):
        du, dv = stage["cell"][0] - cu, stage["cell"][1] - cv
        new = stage["columns"] & ~previous
        claimed = [k for k in range(16) if new >> k & 1]
        previous = stage["columns"]
        what = "its walls" if stage["action"] == 1 else "the things in it"
        ctype = nd.cell(memory, *stage["cell"])
        stage_rows.append([number, f"({stage['cell'][0]},{stage['cell'][1]}), "
                           f"{cell_name(du, dv)}", ctype, what,
                           _numbers(claimed) if claimed else "none",
                           INKS[4 + (ctype & 3)] if stage["action"] == 1 else ""])
        stage_images.append(stage["image"])
    for number, stage in enumerate(fronts, len(backs) + 1):
        du, dv = stage["cell"][0] - cu, stage["cell"][1] - cv
        ctype = nd.cell(memory, *stage["cell"])
        stage_rows.append([number, f"({stage['cell'][0]},{stage['cell'][1]}), "
                           f"{cell_name(du, dv)}", ctype,
                           "its outline, if built on" + ("" if ctype else " (it is not)"),
                           "", ""])
    stage_images.append(stages[-2]["image"])
    stage_images.append(stages[-1]["image"])
    stage_strip = pictures.piece("drawing_stages.png", grid([big(i) for i in stage_images],
                                                             2, 6),
                                 "The buffer after each step of the drawing order", 1)
    claims = pictures.piece("drawing_claims.png", claims_image(stages), "COLUMNS_DRAWN "
                            "after each wall", 2)
    all_claimed = [s for s in backs if s["columns"] == 0xFFFF]
    first_full = backs.index(all_claimed[0]) + 1 if all_claimed else None

    log("  the scene with parts of the drawing patched out...")
    variants = {}
    for name, patches in (("no_walls", {DRAW_WALLS: RET}),
                          ("no_outlines", {DRAW_OUTLINE: RET}),
                          ("no_things", {SORT_AND_DRAW_THINGS: RET}),
                          ("walls_only", {DRAW_OUTLINE: RET, SORT_AND_DRAW_THINGS: RET}),
                          ("no_claims", {0xD3E4: 0, 0xD3E5: 0})):
        variants[name] = buffer_image(scene_variant(snapshot, patches).memory)
    _check(variants["no_things"] != final and variants["no_walls"] != final,
           "patching out the things or the walls changed nothing")
    usual_xs = tile_columns(snapshot, {})
    unclaimed_xs = tile_columns(snapshot, {0xD3E4: 0, 0xD3E5: 0})
    extra_xs = [x for x in unclaimed_xs if x not in usual_xs]
    _check(all(16 <= x < 208 for x in usual_xs), f"tiles were drawn at x {usual_xs}")
    _check(any(x >= 208 for x in extra_xs), "without the test no tile was drawn right of the "
                                             "buffer")
    variant_figs = [
        figure(pictures.piece("drawing_walls_only.png", big(variants["walls_only"], 2),
                              "Walls only", 1),
               f"Walls only: {R(DRAW_OUTLINE)} and {R(SORT_AND_DRAW_THINGS)} each made to "
               "return at once."),
        figure(pictures.piece("drawing_no_things.png", big(variants["no_things"], 2),
                              "Walls and outlines", 1),
               f"Walls and outlines: {R(SORT_AND_DRAW_THINGS)} made to return."),
        figure(pictures.piece("drawing_no_walls.png", big(variants["no_walls"], 2),
                              "No walls", 1),
               f"Everything but the walls: {R(DRAW_WALLS)} made to return."),
        figure(pictures.piece("drawing_no_claims.png", big(variants["no_claims"], 2),
                              "No column claims", 1),
               f"No test of the claims: the JR after the patched BIT in "
               f"{R(DRAW_WALL_COLUMN)} replaced by two NOPs. Every column is still claimed, "
               "but none is skipped, so a wall further back is drawn over the nearer one "
               "in front of it. The columns each turn starts with claimed are drawn too: "
               f"tiles went at x {', '.join(map(str, extra_xs))} as well as the usual "
               f"{usual_xs[0]} to {usual_xs[-1]}. A tile right of the buffer runs off the end "
               "of each row into the start of the row above -- the yellow down the left "
               "edge -- and off the top row into the attribute buffer, which is where the "
               "stray cells at the bottom left come from (those bytes were watched in the "
               "simulator, an instruction at a time, while this page was written: "
               "PUT_TILE wrote them)."),
    ]

    log("  the buffer as it lies in memory, the colours, the town turned round...")
    stored = buffer_image(game.memory, as_stored=True, margin=True)
    colours = attr_image(game.memory)
    plain = buffer_image(game.memory, colour=False)
    turned = buffer_image(scene_variant(snapshot, {}, {VIEW: 1}).memory)
    knights = knight_colours(snapshot)

    screen = buffer_image(game.memory)
    diagram = nine_cells_image(memory, trace, screen)

    log("  three things in one cell, and the depth sort...")
    example = depth_example(snapshot)
    order_names = []
    for record in example["order"]:
        graphic = example["boxes"][record][0]
        index = (record - KNIGHT) // RECORD
        order_names.append(f"record {index} (graphic {graphic})")
    _check(sorted(example["order"]) == sorted(example["listed"]),
           "the depth sort drew something other than what was listed")
    _check(example["order"][0] == BONUS and example["order"][-1] == OBJECTS,
           "the thing behind the knight was not drawn first, or the one in front last")
    depth_img = pictures.piece("drawing_depth.png", depth_picture(example), "Five records "
                               "in one cell, numbered in the order drawn", 1)
    outcome_rows = []
    for index, routine in depth_outcomes(memory):
        turned_round = index >= 9
        u_part, v_part = index % 3, (index % 9) // 3
        what = {DEPTH_KEEP: "the candidate stays", DEPTH_SWAP: "the other becomes the "
                "candidate", DEPTH_BY_CORNERS: "decided by their nearest corners"}.get(
            routine, R(routine))
        outcome_rows.append([index, U_WORDS[u_part], V_WORDS[v_part],
                             "turned round" if turned_round else "", R(routine), what])

    order_rows = []
    for number in range(nd.DRAW_ORDER_COUNT):
        built = [cell_name(*NEIGHBOURS[bit]) for bit in range(5) if number >> bit & 1]
        steps_text = []
        for du, dv, action in nd.draw_steps(memory, number):
            _check(action == (1 if number >> NEIGHBOURS.index((du, dv)) & 1 else 0),
                   f"record {number}: a step's action does not follow whether it is built on")
            steps_text.append(f"{cell_name(du, dv)} {'walls' if action else 'things'}")
        order_rows.append([number, ", ".join(built) if built else "none",
                           "; ".join(steps_text)])

    copy_rows = SHOWN_BYTES // 2
    return "\n".join([
        '<div class="kl-list">',
        "<p>Knight Lore, Alien 8 and Pentagram draw a room of blocks, and each block is a "
        "sprite like everything else, sorted into order in three dimensions "
        f"({kl('DepthSort', 'Knight Lore')}, {a8('Drawing', 'Alien 8')}). Nightshade has "
        "a whole town, bigger than any room, and draws it quite differently. Its "
        "buildings are not sprites: they are walls built from tiles, drawn solid and never "
        "sorted, and nothing has a height. The whole play area is drawn afresh into a "
        "buffer every turn, round the knight, who stays in the middle while the town "
        "scrolls. This page follows one turn's drawing through the game's own code, "
        "stage by stage.</p>",

        "<h3>1. Where things are on the screen</h3>",
        f"<p>Positions in the town are U and V, 16-bit, 256 units to a cell: the high byte "
        f"is the cell's column or row on the 32 by 32 map ({R(TOWN)}), the low byte the "
        f"place across it. {R(PROJECT_CELL)} places everything relative to the knight. "
        "With dU and dV a point's distance from him,</p>",
        "<p><code>x = (dU + dV + 240) / 2</code> and <code>y = (dV - dU + 432) / 4</code>,"
        "</p>",
        "<p>y counting up the screen, as the buffer's lines do. It is Filmation's "
        "projection at half the scale and with no height: U runs right and down the "
        "screen, V right and up. The knight's own point is always x 120, y 108, the "
        "middle of the play area, which is why the town scrolls rather than he. A cell "
        "projects to a diamond 256 pixels wide and 128 high, bigger than the play area, "
        "which is 176 by 112, so only the knight's cell and the eight round it can ever "
        f"be on the screen. In the turn followed here, every wall's cell corner "
        f"{R(PROJECT_CELL)} worked out was checked against the formula, and "
        f"{len(trace['corners'])} of {len(trace['corners'])} agreed.</p>",
        figure(pictures.piece("drawing_nine_cells.png", diagram, "The nine cells round the "
                              "knight, projected", 1),
               f"The knight's cell ({cu},{cv}) and the eight round it, projected by the "
               "formula, each marked with what the drawing order did there this turn: "
               "walls behind him, outlines and things in front. The white rectangle is the "
               "play area, with this turn's picture in it, dimmed; the red dot is the "
               "knight's point."),

        "<h3>2. The drawing order</h3>",
        f"<p>The drawing is {R(DRAW_CELLS)}, once a turn. It looks at the five cells "
        "behind or beside the knight's -- further back is smaller U and larger V, higher "
        "up the screen -- and makes a number of five bits from which of them are built "
        f"on. That number picks one of 32 records of five steps in {R(nd.DRAW_ORDER)}, "
        "and each step names a cell and what to draw there: its walls if it is built on, "
        "the things in it if it is open. Then come the four cells in front: his own, "
        "V-1, U+1 and U+1 V-1, in that order, each drawn as a building's outline on the "
        "ground and then the things in it. So nothing built in front of the knight is "
        "ever drawn solid: he is never hidden behind a wall, and a building he stands "
        "in front of shows as the line where its walls meet the ground.</p>",
        "<p>The 32 records, read from the game when this page was built (a step's cell "
        "is named from the knight's):</p>",
        table(["Record", "Built on", "The five steps, in order"], order_rows),
        "<p>Every record gives all five cells, the walls of each one that is built on "
        "and the things in each that is not; the order is what changes. The build "
        "checks both. The step byte could also say <i>draw its outline</i> or <i>draw "
        "nothing</i>, but no record uses either.</p>",

        "<h3>3. One turn, step by step</h3>",
        f"<p>The scene: cell ({cu},{cv}), open ground, with buildings on all five cells "
        f"behind it and one in front, the knight near its back edge (the low bytes of his "
        f"U and V written as {DRAW_SCENE_SPOT[0]} and {DRAW_SCENE_SPOT[1]}), and a "
        f"monster of graphic {DRAW_SCENE_MONSTER[0]} put in front of him, the other "
        "monster records emptied: all written at the start of the turn. The game's own "
        f"code then ran the turn, stopped after each step of {R(DRAW_CELLS)}:</p>",
        table(["Step", "Cell", "Type", "Drawn", "Columns claimed", "Colour"], stage_rows),
        figure(stage_strip, "The buffer at the start of the drawing, after each of the "
               "five steps behind the knight, after the four cells in front (outlines and "
               "things), and as the turn ends, with the knight coloured: left to right and "
               "down. The colours are the attribute buffer's as it stood at each moment."),
        figure(screen_fig_img, "The turn's buffer, three times the Spectrum's size."),
        "<p>The same turn run three more times, each with one part of the drawing made to "
        "return at once -- a RET written over its first byte at the start of the turn -- "
        "shows what each part contributes:</p>",
        '<div>' + "".join(variant_figs[:3]) + "</div>",

        "<h3>4. Walls, nearest first</h3>",
        f"<p>A building behind the knight is drawn by {R(DRAW_WALLS)}. Its cell type picks "
        f"a definition from {R(nd.BUILDINGS)} -- two for each type, one for each way the "
        "town can be seen -- and a definition is two faces of eight columns, each column "
        f"a tile on the ground and a tile 64 lines above it ({R(nd.TILE_TABLE)}). The "
        "faces stand on the cell's near edges: from its corner, eight columns 16 pixels "
        "right and 8 lines down, then eight right and up, the second face drawn mirrored. "
        f"{R(PUT_TILE)} writes a tile over whatever is in the buffer, keeping only the "
        f"pixels either side of its 16, and {R(COLOUR_WALL)} colours the column from the "
        "wall's foot to the top of the play area. So a wall hides everything above it on "
        "the screen, and walls are drawn nearest first.</p>",
        f"<p>That needs a record of what is already covered. The screen is taken as "
        f"sixteen columns 16 pixels wide, a bit each in COLUMNS_DRAWN, and "
        f"{R(DRAW_WALL_COLUMN)} tests a column's bit before drawing it and sets it after: "
        "a column a nearer wall has claimed is skipped. Both instructions are written by "
        "the routine as it goes -- it patches the bit number into a BIT and a SET "
        "(TEST_COLUMN and CLAIM_COLUMN) -- and since all the cells' corners are 128 "
        "pixels apart, every tile column in a turn lies at the same place within its 16 "
        "pixels, so a tile and a screen column always coincide. Each turn starts with "
        f"${COLUMNS_START:04X}: the column left of the buffer and the three right of it "
        "already claimed, which keeps walls from being drawn off either side, where a "
        "buffer row's bytes would run on into the next row's; and a wall stops as soon as "
        "all sixteen are claimed."
        + (f" In the scene every column was claimed after step {first_full}, so the "
           "walls after it drew nothing at all." if first_full and first_full < len(backs)
           else "") + "</p>",
        figure(claims, "COLUMNS_DRAWN at the start of the turn (top) and after each of the "
               "five steps behind the knight: grey the four claimed before anything is "
               "drawn, each other column in the colour of the wall that claimed it, black "
               "unclaimed. The line under each row marks the eleven columns the screen "
               "shows (the next one to the left is the buffer's hidden margin)."),
        '<div>' + "".join(variant_figs[3:]) + "</div>",

        "<h3>5. Outlines in front</h3>",
        f"<p>For the four cells in front, {R(DRAW_OUTLINE)} draws only the line where a "
        "building's walls meet the ground, all the way round: the near two faces from "
        "the definition for this view, and the far two from the definition for the other "
        f"view, which is the same building seen from behind. Under each tile is an edge "
        f"picture ({R(nd.TILE_EDGES)}): a plain line, or for a tile with an archway a "
        "short stub at one end, so an archway leaves a gap in the outline. The edges are "
        f"ORed into the buffer ({R(PUT_EDGE)}) and claim no columns.</p>",

        "<h3>6. The things in a cell</h3>",
        f"<p>Where a step says <i>the things in it</i>, {R(LIST_THINGS_IN_CELL)} lists "
        f"every object record whose U and V fall in that cell, at {R(DRAW_LIST)}, and "
        f"{R(SORT_AND_DRAW_THINGS)} draws them back to front. A thing belongs to one cell "
        "only, by the high bytes of its position, and is drawn with that cell's things. "
        f"Each is drawn whole, through its mask ({R(DRAW_SPRITE)}), so what is drawn "
        "later covers what was drawn before. The sort is the earlier games' in two "
        "dimensions: the first thing not yet drawn is the candidate, every later one is "
        "compared with it by their boxes' sides in U and V, and one further back takes "
        "its place; at the end of the list the candidate is drawn. The comparison's "
        f"eighteen outcomes go through {R(DEPTH_TABLE)}:</p>",
        table(["Outcome", "U", "V", "", "Routine", ""], outcome_rows),
        "<p>Nine outcomes for how two boxes lie on the two axes, and nine more with the "
        "town turned round, when <i>further back</i> is the other way. Knight Lore's table "
        f"has 27, for three axes ({kl('DepthSort', 'its depth-sort page')}). Unlike the "
        "earlier games, a pass carries on down the list from a new candidate rather than "
        "going back to the top, so it can never go round in a circle and needs no chain "
        "of candidates to catch one; the price is that a new candidate is never compared "
        "with the things the pass has already gone by.</p>",
        f"<p>A worked example: cell ({example['cell'][0]},{example['cell'][1]}), the knight "
        f"at its middle, with a bonus (graphic 3) put behind him, one object (graphic 7) "
        f"in front and another (graphic 6) beside him, and the monsters cleared. Run in "
        f"the simulator and stopped at every call of {R(DRAW_SPRITE)} while his cell's "
        f"things were drawn, the order was {', '.join(order_names)}: the bonus behind "
        "him first, then his legs and top, the object beside him, and the one in front "
        "last.</p>",
        figure(depth_img, "The five records' boxes on the ground, where the projection "
               "puts them, numbered in the order the depth sort drew them. The knight's "
               "legs and top share one box."),

        "<h3>7. The buffer, and the copy</h3>",
        f"<p>Everything is drawn into {R(BUFFER)}, 24 bytes by {PLAY_LINES} lines, whose "
        "first line is the bottom of the play area: the game's y counts up the screen, so "
        "in memory the picture is upside down. Each row's first two bytes are a margin "
        "the screen never shows, which takes a sprite drawn at the left edge. At the end "
        f"of the turn {R(COPY_BUFFER)} copies it to the screen with the stack pointer: SP "
        "is pointed just past the end of a screen line and each PUSH puts two buffer "
        f"bytes on it, {copy_rows} to a line, while HL reads the buffer backwards -- "
        f"from the bottom line up. {R(COPY_ATTR_BUFFER)} does the same for the "
        f"attributes, and {R(SHOW_PLAY_AREA)} then clears both buffers, again by PUSHing. "
        "Interrupts are off the whole game, so nothing else can use the stack meanwhile. "
        "The whole play area is copied every turn, whatever changed.</p>",
        '<div>'
        + figure(pictures.piece("drawing_stored.png", big(stored, 2), "The buffer as "
                                "stored", 1),
                 "The buffer as it lies in memory, first row at the top: the picture "
                 "upside down, with the two hidden bytes of each row dimmed at the left.")
        + figure(pictures.piece("drawing_plain.png", big(plain, 2), "The pixels", 1),
                 "The same pixels the right way up, as the copy puts them on the screen.")
        + "</div>",
        f"<p>Tiles and sprites are drawn at any even pixel through tables "
        f"{R(MAKE_TABLES)} builds at every new game: for each byte, shifted right two, "
        f"four and six places, the part that stays in its byte and the part that falls "
        f"into the next ({R(SHIFT_TABLES)}), the same for the byte reversed "
        f"({R(MIRROR_TABLES)}), and every byte reversed ({R(REVERSE_TABLE)}). Bit 0 of x "
        "is ignored, so things move across the screen two pixels at a time. A tile on a "
        "building's second face is mirrored as it is drawn; a sprite is turned round in "
        f"place, its bytes rewritten, when a thing faces the other way ({R(TURN_SPRITE)}), "
        f"as the earlier games do ({a8('Drawing', 'Alien 8')}).</p>",

        "<h3>8. Colour</h3>",
        f"<p>The attribute buffer, {R(ATTR_BUFFER)}, is cleared every turn to bright white "
        "ink on black -- or on the paper a dying villain flashes -- and the walls colour "
        "it: a wall's ink is bright green, cyan, yellow or white by the two low bits of "
        "its cell's type, from its foot up to the top of the play area. The outlines and "
        "the things take whatever colour is where they are drawn, so a monster in front "
        "of a yellow wall is yellow where they overlap. The knight is the exception: "
        "every turn the four rows of two cells where he always stands are coloured by the "
        f"hits he has left ({R(COLOUR_KNIGHT)}), white, yellow or green.</p>",
        '<div>'
        + figure(pictures.piece("drawing_colours.png", big(colours, 2), "The attributes",
                                1),
                 "The scene's attribute buffer alone, a square for each character cell: "
                 "its ink inside a border of its paper. The walls' colours run up from their "
                 "feet. The four cells not bright are the right-hand halves of the knight's "
                 "four rows of two, which his colouring leaves so.")
        + figure(pictures.piece("drawing_knight_colours.png", strip(knights), "The knight "
                                "by his hits", 1),
                 "The knight with three hits left, two and one (HITS written at the start "
                 "of the turn).")
        + "</div>",

        "<h3>9. Turning the town round</h3>",
        f"<p>Z or SYMBOL SHIFT turns the town round, to be seen from the other side "
        f"({R(TURN_TOWN)}). Nothing in the town moves. Everything the drawing reads is "
        f"read through the view instead: {R(LOOK_UP_CELL)} reads the map backwards, "
        f"{R(TURN_CELL)} turns a cell's column c into 31 - c and its row r into 31 - r, "
        "positions become their distance from the town's far edge, each building uses "
        "its other definition -- the two faces the first one left out -- and the depth "
        "sort adds 9 to its outcomes. So what was in front of the knight is now behind "
        "him, drawn as walls, and what was behind him is outlines. The panel's heading "
        "changes from north to south.</p>",
        '<div>'
        + figure(pictures.piece("drawing_usual.png", big(screen, 2), "The usual view", 1),
                 "The scene the usual way round.")
        + figure(pictures.piece("drawing_turned.png", big(turned, 2), "Turned round", 1),
                 "The same turn with bit 0 of VIEW set at its start: the same place seen "
                 "from the other side.")
        + "</div>",

        "<h3>Confirmed and inferred</h3>",
        "<ul>"
        "<li>Run in the simulator when this page was built: the scene's turn, stopped "
        "after every step of the drawing order, with COLUMNS_DRAWN read at each; every "
        "wall's projected corner checked against the formula; the same turn with each "
        "part of the drawing patched out, with the column claims undone, with the town "
        "turned round and with the knight's hits changed; the depth sort's order in a "
        "staged cell.</li>"
        "<li>Read from the game: the 32 drawing-order records and the 18 depth outcomes, "
        "each checked by the build against the rule the page gives.</li>"
        "<li>Read from the code: the projection's constants, the buffer's layout and the "
        "copy.</li>"
        "<li>Inferred: that the cells in front are drawn as outlines so that the knight "
        "is never hidden. The code shows only that they are.</li>"
        "</ul>",
        "</div>"])


# --------------------------------------------------------------------------
# 3. How things move.
# --------------------------------------------------------------------------

WALK_CELL_SPOT = (128, 128)     # the middle of the most open cell (open_cell)
WALK_TURNS = 8
FACINGS = [(0x00, "+V", "right and up the screen", "from behind"),
           (0x40, "+U", "right and down", "from the front"),
           (0x80, "-V", "left and down", "from the front"),
           (0xC0, "-U", "left and up", "from behind")]
WALL_SPOT = (80, 160)           # in SCENE_CELL, facing +V: the wall beside a doorway ahead
DOOR_SPOT = (128, 160)          # ...and the doorway itself
WALL_TURNS = 14


def open_cell(memory) -> tuple[int, int]:
    """The open cell with the most open cells round it (the first of them
    in the map's order)."""
    cells = sorted(((sum(nd.cell(memory, u + a, v + b) == 0
                         for a in (-1, 0, 1) for b in (-1, 0, 1)), -v, -u)
                    for v in range(2, 30) for u in range(2, 30) if nd.cell(memory, u, v) == 0),
                   reverse=True)
    _, v, u = cells[0]
    return -u, -v


def face(memory, facing: int) -> None:
    """The knight's two records turned to a facing, with no turn delay."""
    for base in (KNIGHT, KNIGHT_TOP):
        memory[base + FACING] = facing


def walk_and_stop(snapshot: Path) -> dict:
    """In the open: the knight walked from a standstill with the walk key
    held for WALK_TURNS turns and then let go, once at his usual top speed
    and once with the bonus's (TOP_SPEED and SPEED_TIME written as #R$D727
    writes them); then the turn key held from a standstill."""
    game = Game(snapshot)
    memory = game.memory
    game.go(*open_cell(memory))
    game.place_knight(*WALK_CELL_SPOT)
    game.clear_monsters()
    face(memory, 0x40)
    game.turns(2)
    start = game.save()
    out = {}
    for top in (10, 18):
        game.restore(start)
        if top == 18:
            memory[TOP_SPEED] = 18
            memory[SPEED_TIME] = 255
        walking, stopping = [], []
        for _ in range(WALK_TURNS):
            game.clear_monsters()
            game.turns(1, ["a"])
            walking.append((memory[KNIGHT + SPEED], _word(memory, KNIGHT + U)))
        for _ in range(6):
            game.clear_monsters()
            game.turns(1)
            stopping.append((memory[KNIGHT + SPEED], _word(memory, KNIGHT + U)))
        out[top] = {"walking": walking, "stopping": stopping}
    game.restore(start)
    out["start"] = _word(memory, KNIGHT + U)
    facings = []
    for _ in range(9):
        game.clear_monsters()
        game.turns(1, ["x"])
        facings.append(memory[KNIGHT + FACING])
    out["facings"] = facings
    return out


def boxes_of(memory, cell_type: int) -> list[tuple[int, int, int, int]]:
    address = _word(memory, nd.BOX_TABLE + 2 * cell_type)
    out = []
    while memory[address]:
        out.append(tuple(memory[address:address + 4]))
        address += 4
    return out


def walk_into_wall(snapshot: Path, spot=WALL_SPOT, turns: int = WALL_TURNS) -> dict:
    """In SCENE_CELL, facing +V: the knight walked at the building ahead,
    stopping at MOVE_CLIPPED and APPLY_STEP in his own update each turn to
    read his step before and after the walls trimmed it."""
    game = Game(snapshot)
    memory = game.memory
    game.go(*SCENE_CELL)
    game.place_knight(*spot)
    game.clear_monsters()
    face(memory, 0x00)
    game.turns(2)
    rows = []
    for turn in range(turns):
        game.clear_monsters()
        bn._lives(memory)
        game.run_to(MOVE_CLIPPED, keys=["a"])
        _check(game.ix() == KNIGHT, "the first MOVE_CLIPPED of a turn was not the knight's")
        before = _signed(memory[KNIGHT + STEP_V])
        game.run_to(APPLY_STEP, keys=["a"])
        after = _signed(memory[KNIGHT + STEP_V])
        game.run_to(END_OF_TURN, keys=["a"])
        rows.append({"turn": turn + 1, "before": before, "after": after,
                     "v": _word(memory, KNIGHT + V), "u": _word(memory, KNIGHT + U),
                     "flag": memory[KNIGHT + FLAGS] & 1, "top": memory[KNIGHT_TOP],
                     "speed": memory[KNIGHT + SPEED]})
        if turn == turns - 1:
            image = buffer_image(memory)
            knight = (_word(memory, KNIGHT + U), _word(memory, KNIGHT + V))
        game.turns(1, ["a"])
    return {"rows": rows, "image": image, "knight": knight}


def boxes_picture(memory, image, knight, scale: int = 3, draw_knight: bool = True):
    """A buffer picture with the boxes of the nine cells round the knight
    drawn on the ground where the projection puts them, and the knight's
    own box."""
    from PIL import ImageDraw

    image = big(image, scale)
    draw = ImageDraw.Draw(image)
    ku, kv = knight

    def screen(u, v):
        x, y = project(u - ku, v - kv)
        return ((x - 32) * scale, (PLAY_BOTTOM + PLAY_LINES - 1 - y) * scale)

    cu, cv = ku >> 8, kv >> 8
    for du in (-1, 0, 1):
        for dv in (-1, 0, 1):
            u0, v0 = (cu + du) * 256, (cv + dv) * 256
            for bu, bv, su, sv in boxes_of(memory, nd.cell(memory, cu + du, cv + dv)):
                mu, mv = u0 + (bu - 64) * 2, v0 + (bv - 64) * 2
                corners = [(mu - 2 * su, mv - 2 * sv), (mu + 2 * su, mv - 2 * sv),
                           (mu + 2 * su, mv + 2 * sv), (mu - 2 * su, mv + 2 * sv)]
                draw.polygon([screen(*c) for c in corners], outline=(255, 60, 60), width=2)
    if draw_knight:
        corners = [(ku - 16, kv - 16), (ku + 16, kv - 16), (ku + 16, kv + 16), (ku - 16, kv + 16)]
        draw.polygon([screen(*c) for c in corners], outline=(80, 220, 255), width=2)
    return image


def through_doorway(snapshot: Path) -> dict:
    """The same walk in line with the doorway: the knight walks on into the
    building, and the turn he is in the middle of it is drawn."""
    game = Game(snapshot)
    memory = game.memory
    game.go(*SCENE_CELL)
    game.place_knight(*DOOR_SPOT)
    game.clear_monsters()
    face(memory, 0x00)
    game.turns(2)
    target = SCENE_CELL[1] + 1
    for _ in range(60):
        game.clear_monsters()
        bn._lives(memory)
        game.turns(1, ["a"])
        if memory[KNIGHT + V + 1] == target and memory[KNIGHT + V] >= 0x70:
            break
    else:
        raise RuntimeError("the knight never got through the doorway")
    game.clear_monsters()
    game.run_to(END_OF_TURN)
    return {"image": buffer_image(memory), "cell": (memory[KNIGHT + U + 1], target),
            "knight": (_word(memory, KNIGHT + U), _word(memory, KNIGHT + V))}


def _percent(count: int, total: int) -> str:
    value = count * 100 / total
    return f"{value:.1f}%" if value < 1 else f"{value:.0f}%"


def random_steps(snapshot: Path) -> dict:
    """RANDOM_STEP (#R$DDFC) run for every value of C, with B 4 (the finds)
    and 7 (the monsters of 64-79): how often each step comes out."""
    memory = bn.game_memory(snapshot)
    out = {}
    for bits in (4, 7):
        counts = {}
        for value in range(256):
            simulator = call(memory, RANDOM_STEP, {"B": bits, "C": value})
            from skoolkit.simutils import A
            step = _signed(simulator.registers[A])
            counts[step] = counts.get(step, 0) + 1
        out[bits] = counts
    return out


def _movement_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    R = listing.r
    memory = bn.game_memory(snapshot)

    log("  walking, stopping and turning in the open...")
    walk = walk_and_stop(snapshot)
    for top, expected in ((10, [4, 6, 8]), (18, [8, 12, 14, 16])):
        speeds = [s for s, _ in walk[top]["walking"]]
        _check(speeds[:len(expected)] == expected and all(s == expected[-1]
                                                          for s in speeds[len(expected):]),
               f"with top speed {top} the knight's speeds were {speeds}")
        final = walk[top]["stopping"][-1]
        _check(final[0] == 0 and final[1] % 8 == 0,
               f"the knight did not come to rest on the grid: {final}")
    walk_rows = []
    for top in (10, 18):
        cells = [str(speed) for speed, _ in walk[top]["walking"]]
        coast = []
        last = walk[top]["walking"][-1][1]
        for speed, u in walk[top]["stopping"]:
            if u != last:
                coast.append(str(u - last))
            last = u
        walk_rows.append([top, ", ".join(cells), f"{walk[top]['walking'][-1][1]}",
                          ", ".join(coast), f"{walk[top]['stopping'][-1][1]}"])
    turn_facings = [f"${f:02X}" for f in walk["facings"]]
    _check(walk["facings"][:4] == [0x01, 0x00, 0xC1, 0xC0],
           f"turning left from +U went {turn_facings[:4]}")

    log("  into a wall, and through a doorway...")
    wall = walk_into_wall(snapshot)
    stopped = [r for r in wall["rows"] if r["flag"]]
    _check(bool(stopped) and stopped[0]["after"] < stopped[0]["before"],
           "the walk never met the wall")
    _check(all(r["after"] == 0 for r in stopped[1:]), "the knight moved on against the wall")
    _check(stopped[0]["top"] in (22, 30), "his top did not throw its arms out at the wall")
    wall_rows = []
    for r in wall["rows"]:
        wall_rows.append([r["turn"], r["speed"], r["before"], r["after"],
                          f"{r['v']} (row {r['v'] >> 8}, {r['v'] & 0xFF})",
                          "set" if r["flag"] else "", r["top"]])
    first_stop = stopped[0]
    box_type = nd.cell(memory, SCENE_CELL[0], SCENE_CELL[1] + 1)
    wall_img = pictures.piece("movement_wall.png", boxes_picture(memory, wall["image"],
                                                                 wall["knight"]),
                              "The knight against the wall, with the cells' boxes", 1)
    door = through_doorway(snapshot)
    door_img = pictures.piece("movement_inside.png", boxes_picture(memory, door["image"],
                                                                   door["knight"],
                                                                   draw_knight=False),
                              "Inside a building", 1)
    door_type = nd.cell(memory, *door["cell"])

    counts_by_size = {}
    for cell_type in range(nd.CELL_TYPES):
        count = len(boxes_of(memory, cell_type))
        counts_by_size.setdefault(count, []).append(cell_type)
    box_rows = [[count, _numbers(types)] for count, types in sorted(counts_by_size.items())]
    full_walls = [t for t in range(nd.CELL_TYPES)
                  if sorted(boxes_of(memory, t)) == sorted([(128, 66, 64, 2), (190, 128, 2, 64),
                                                            (128, 190, 64, 2), (66, 128, 2, 64)])]

    log("  the random steps...")
    steps = random_steps(snapshot)
    step_rows = []
    for bits in (4, 7):
        counts = steps[bits]
        total = sum(counts.values())
        text = ", ".join(f"{step:+d}: {_percent(counts[step], total)}"
                         for step in sorted(counts) if counts[step])
        step_rows.append([bits, f"{min(counts)} to {max(counts)}", text])
        _check(max(counts) == 2 * bits and min(counts) == -2 * bits,
               f"RANDOM_STEP with B={bits} gave {min(counts)} to {max(counts)}")

    facing_rows = [[f"${f:02X}", name, where, seen] for f, name, where, seen in FACINGS]
    return "\n".join([
        '<div class="kl-list">',
        "<p>Nothing in Nightshade's town has a height, nothing falls, and nothing pushes "
        "anything else: things move over a flat map, and the only thing that stops them is "
        "a building's walls. Knight Lore's and Alien 8's movement is a different engine "
        f"altogether, three axes of boxes tested against each other "
        f"({kl('Collision', 'Knight Lore')}, {a8('Movement', 'Alien 8')}); Nightshade's is "
        "its own, and this page takes it apart: the knight's walk, his turning, his two "
        "records, the walls, and how the other things find their way.</p>",

        "<h3>Facing and stepping</h3>",
        f"<p>A record faces one of four ways, in bits 6 and 7 of +6. {R(SET_STEP)} turns its "
        "speed into this turn's step (+A and +B): the speed along the one axis it faces, "
        "negative for the minus facings, nothing along the other. The step is then trimmed "
        f"at the walls ({R(MOVE_CLIPPED)}) and only then added to U and V "
        f"({R(APPLY_STEP)}). Adding $40 to the facing is a quarter turn to the right.</p>",
        table(["Facing", "Along", "On the screen", "The knight is seen"], facing_rows),

        "<h3>The knight's walk</h3>",
        f"<p>While the walk key is held, {R(WALK_ON)} takes his speed halfway to his top "
        "speed each turn and rounds it down to an even number -- which means it never "
        "gets there: halfway from 8 to 10 is 9, and 9 rounded down is 8 again. His top "
        "speed is 10, and 18 while a bonus's faster walk lasts, so he walks at 8 and "
        "hurries at 16. When the key is let go he does not stop dead: "
        f"{R(COAST_TABLE)}'s routine for his facing steps him on 4, then 2, then 1, until "
        "his place along the way he faces is a multiple of 8, so he always comes to rest "
        "on an eight-unit grid. Every step counts a footstep, and every fourth one "
        "(every second when hurrying) makes a sound.</p>",
        f"<p>Run in the simulator when this page was built, in the middle of an open cell "
        f"facing +U, the walk key held for {WALK_TURNS} turns from a standstill and then "
        "let go, once as the game starts him and once with TOP_SPEED and SPEED_TIME "
        f"written as the bonus writes them ({R(SPEED_BONUS)}):</p>",
        table(["Top speed", "Speed each turn, key held", "U when let go",
               "Steps after", "U at rest"], walk_rows),

        "<h3>Turning</h3>",
        f"<p>The low three bits of his facing byte are a turn delay ({R(TURN_KNIGHT)}): a "
        "turn sets it to 1, and while it is not 0 it counts down and he cannot turn again, "
        "so a turn key held down turns him a quarter every other turn. Held from a "
        f"standstill facing +U ($40), the left key gave his facing byte turn by turn as "
        f"{', '.join(turn_facings)}: round to +V, -U, -V and back, a quarter every second "
        "turn.</p>",
        "<p>With a joystick and directional control chosen on the menu, the stick's "
        "direction is a facing -- up +V, right +U, down -V, left -U -- and he turns a "
        "quarter towards it (either way, at random, if it is behind him), walking only "
        "once he faces it. With the town turned round the stick's directions are swapped "
        f"end for end ({R(0xDC43)}) so that it still means the same way on the "
        f"screen.</p>",

        "<h3>Two records</h3>",
        f"<p>The knight is his legs ({R(KNIGHT)}), which do all of the above "
        f"({R(UPDATE_KNIGHT)}), and his top ({R(KNIGHT_TOP)}), drawn over them "
        f"({R(UPDATE_TOP)}). The top copies the legs' place every turn and shows the "
        "picture that matches the legs' walking frame; now and then, one turn in 32 while "
        "he is not turning, it strikes a pose of its own for two to nine turns. When the "
        "legs are stopped by a wall the top throws its arms out -- graphic 30 from the "
        "front, 22 from behind -- with a bump, and stays where it is. Two views, each "
        "mirrored or not, make his four facings: facing +U or -V he comes towards the "
        "viewer and shows his face (legs 24-29, top 40-45, which bit 3 of the graphic "
        "picks), facing +V or -U he is seen from behind (16-21 and 32-37).</p>",

        "<h3>Walls</h3>",
        f"<p>Every cell type has a list of boxes ({R(nd.BOX_TABLE)}), four bytes a box: "
        "its centre in U and V and its half-sizes, in half units measured across the "
        "cell, which runs from 64 to 191 in them. The boxes are a building's walls, thin "
        "and running along the cell's edges, with gaps where the building has doors: a "
        "building is a room the knight can walk into. The cell types with four whole "
        f"walls and no gaps -- types {_numbers(full_walls)}, the solid cells the game never "
        "starts him in -- are the only ones he cannot enter. How many boxes each type "
        "has:</p>",
        table(["Boxes", "Cell types"], box_rows),
        f"<p>{R(MOVE_CLIPPED)} goes by the record's facing to one of four routines "
        f"({R(MOVE_TABLE)}). Each finds the cells its front edge is in -- the edge at "
        "its centre plus or minus its half-size, from one corner to the other -- and, if "
        "this turn's step takes the edge into the next row or column of cells, the cells "
        "it goes into: at most four. For each, the record, moved by half its step, is "
        f"tested against every box of the cell's type ({R(HIT_BOXES_U)}, "
        f"{R(HIT_BOXES_V)}): they overlap along an axis when the distance between the "
        "centres is less than half the record's half-size plus the box's. The first box "
        "it runs into cuts the step by twice the overlap, which leaves the record "
        "touching the box's face, and sets bit 0 of its flags to say it was stopped.</p>",
        f"<p>Walked at a wall in the simulator: cell ({SCENE_CELL[0]},{SCENE_CELL[1]}), the "
        f"knight put at U {WALL_SPOT[0]} and V {WALL_SPOT[1]} across it, facing +V, "
        f"towards the building on cell ({SCENE_CELL[0]},{SCENE_CELL[1] + 1}), type "
        f"{box_type}, with the walk key held:</p>",
        table(["Turn", "Speed", "Step in V", "After the walls", "V", "Stopped", "Top's "
               "graphic"], wall_rows),
        f"<p>On turn {first_stop['turn']} the step of {first_stop['before']} was cut to "
        f"{first_stop['after']}, which left his front edge exactly against the wall, and "
        "after that every step was cut to nothing. His speed stays where it was: the wall "
        "does not slow him, it only trims each step. His top shows graphic "
        f"{first_stop['top']}, arms out.</p>",
        '<div>'
        + figure(wall_img, "The last turn of the walk, with the boxes of the nine cells "
                 "round him drawn on the ground in red, where the projection puts them, and "
                 "his own box in blue. The wall ahead of him is the building's near wall; "
                 "the gap in it is a doorway.")
        + figure(door_img, f"The same walk started in line with the doorway, U "
                 f"{DOOR_SPOT[0]}: he walks on into the building, cell "
                 f"({door['cell'][0]},{door['cell'][1]}), type {door_type}. His own cell "
                 "is always drawn as an outline, so from inside a building its walls are "
                 "lines on the ground.")
        + "</div>",

        "<h3>Everything else that moves</h3>",
        "<p>The same trimming moves everything. What differs is how each decides where to "
        "go:</p>",
        "<ul>"
        f"<li><b>Thrown things.</b> An antibody ({R(ANTIBODY_FLIGHT)}) or an object "
        f"({R(OBJECT_FLIGHT)}) flies straight on at speed 12, moving twice a turn, and "
        "the second move keeps the wall flag from the first, so meeting a wall on either "
        "ends the flight. A sparkle from a dead villain flies the same way, once a "
        "turn.</li>"
        f"<li><b>Villains and the monsters of 112-127</b> walk at their speed the way they "
        f"face, and {R(STEER)} turns them: a quarter turn left or right at random when a "
        "wall stops them, and again when a count in the facing byte runs out. A monster "
        "born in the first half of a 256-turn cycle has bit 5 of its flags set and turns "
        f"towards the knight instead ({R(KNIGHT_DIRECTION)}): the facing along whichever "
        "axis he is further away on. No villain is ever given bit 5, so the villains "
        "wander and never chase.</li>"
        f"<li><b>Finds and the monsters of 64-79</b> wander: now and then "
        f"{R(WANDER_STEP)} gives them a new random step in both U and V at once, and "
        f"{R(MOVE_SPLIT)} trims it as a move along U and then one along V, since the "
        "trimming only knows the four facings.</li>"
        f"<li><b>The creature</b> steps two units towards the knight along each axis every "
        f"turn ({R(0xC02C)}), and bursts at the first wall.</li>"
        "</ul>",
        f"<p>A wanderer's steps come from {R(RANDOM_STEP)}: two units for each 0 among B "
        "bits of the random number, negative if the next bit is 0 -- the count of heads "
        "in B tosses, so steps near B are likeliest and the extremes rare. Run for every "
        "value of the byte it reads:</p>",
        table(["B", "Step", "How often, over all 256 values"], step_rows),

        "<h3>Confirmed and inferred</h3>",
        "<ul>"
        "<li>Run in the simulator when this page was built: the walk from a standstill at "
        "both top speeds, the coming to rest on the grid, the turn key held, the walk "
        "into a wall with the step read before and after the trimming, the walk through "
        "a doorway, and RANDOM_STEP for every input.</li>"
        "<li>Staged: the knight's place in his cell and his facing, and TOP_SPEED and "
        "SPEED_TIME for the faster walk, written at the start of a turn; the monsters "
        "cleared each turn so that none interfered.</li>"
        "<li>Read from the code: the steering, the homing and the flights.</li>"
        "<li>Inferred: that the eight-unit grid is there so that he stands square in "
        "doorways; nothing in the code says why.</li>"
        "</ul>",
        "</div>"])


# --------------------------------------------------------------------------
# 4. Monsters, antibodies and the creature.
# --------------------------------------------------------------------------

OUTCOME_NAMES = {HIT_DESTROYS: "destroyed", HIT_CHANGES: "changed into the next kind",
                 HIT_SPLITS: "split in two", HIT_DEMOTES: "turned into one of 64-79"}
BONUS_CELL = (16, 16)
BONUS_TRIES = 300


def _ix_iy(ix: int, iy: int | None = None) -> dict:
    registers = {"IXh": ix >> 8, "IXl": ix & 0xFF}
    if iy is not None:
        registers.update({"IYh": iy >> 8, "IYl": iy & 0xFF})
    return registers


def _put(memory, record: int, graphic: int, column: int, row: int, size: int = 16) -> None:
    """A record at the middle of a cell, with a half-size each way."""
    memory[record] = graphic
    memory[record + U], memory[record + U + 1] = 0x80, column
    memory[record + V], memory[record + V + 1] = 0x80, row
    memory[record + SIZE_U] = memory[record + SIZE_V] = size


def strike_table(snapshot: Path) -> dict:
    """STRIKE_OUTCOME (#R$C0B9) run for every kind of monster of 112-127
    against every kind of antibody: the routine MONSTER_HIT_TABLE sends it
    to, found by stopping at the four."""
    from skoolkit.simutils import PC

    memory = list(bn.game_memory(snapshot))
    out = {}
    monster, antibody = MONSTERS + 2 * RECORD, ANTIBODIES
    for mk in range(4):
        for ak in range(4):
            memory[monster] = 112 + 4 * mk
            memory[antibody] = 80 + 4 * ak
            simulator = call(memory, STRIKE_OUTCOME, _ix_iy(monster, antibody),
                             stops=list(OUTCOME_NAMES))
            out[(mk, ak)] = simulator.registers[PC]
    return out


def nearest_kinds(snapshot: Path) -> dict:
    """NEAREST_VILLAIN (#R$C19C) with a monster appearing beside each villain
    in turn, the villains in cells far apart: the kind it returns."""
    from skoolkit.simutils import A

    memory = list(bn.game_memory(snapshot))
    out = {}
    for n in range(4):
        for k in range(4):
            _put(memory, VILLAINS + RECORD * k, 108 - 4 * k, 4 + 8 * k, 10)
        _put(memory, MONSTERS, 128, 4 + 8 * n, 11)
        out[n] = call(memory, NEAREST_VILLAIN, _ix_iy(MONSTERS)).registers[A]
    return out


def antibody_records(snapshot: Path) -> dict:
    """ANTIBODY_STRIKE (#R$C538) with a monster and an antibody on the same
    spot, the antibody in the first record and then in the second."""
    from skoolkit.simutils import F

    out = {}
    for which in (0, 1):
        memory = list(bn.game_memory(snapshot))
        for record in (ANTIBODIES, ANTIBODIES + RECORD):
            memory[record] = 0
        _put(memory, MONSTERS, 64, 5, 5)
        _put(memory, ANTIBODIES + RECORD * which, 80, 5, 5)
        out[which] = call(memory, ANTIBODY_STRIKE, _ix_iy(MONSTERS)).registers[F] & 1
    return out


def bonus_placements(snapshot: Path) -> dict:
    """The knight left standing in an open cell, the bonus record emptied at
    the start of each of BONUS_TRIES turns: where PLACE_BONUS put the new
    one, and whether it was still there, in the same place, a turn later."""
    game = Game(snapshot)
    memory = game.memory
    game.go(*BONUS_CELL)
    placed, kept, none, graphics = {}, {}, 0, {2: 0, 3: 0}
    for _ in range(BONUS_TRIES):
        bn._lives(memory)
        game.clear_monsters()
        memory[BONUS] = 0
        game.run_to(END_OF_TURN)
        if memory[BONUS] not in (2, 3):
            none += 1
            game.turns(1)
            continue
        graphics[memory[BONUS]] += 1
        where = bytes(memory[BONUS + 1:BONUS + 5])
        cell = (memory[BONUS + U + 1] - memory[KNIGHT + U + 1],
                memory[BONUS + V + 1] - memory[KNIGHT + V + 1])
        placed[cell] = placed.get(cell, 0) + 1
        game.turns(1)
        game.run_to(END_OF_TURN)
        if memory[BONUS] in (2, 3) and bytes(memory[BONUS + 1:BONUS + 5]) == where:
            kept[cell] = kept.get(cell, 0) + 1
        game.turns(1)
    return {"placed": placed, "kept": kept, "none": none, "graphics": graphics}


def game_stocks(snapshot: Path) -> list[int]:
    game = Game(snapshot)
    return [game.memory[STOCKS + t] for t in range(nd.CELL_TYPES)]


def spawn_watch(snapshot: Path, turns: int = 600) -> dict:
    """The knight standing in an open cell for `turns` turns: monsters that
    appeared, and the turn counter's low byte whenever the creature did."""
    game = Game(snapshot)
    memory = game.memory
    game.go(*BONUS_CELL)
    before = [memory[MONSTERS + RECORD * r] for r in range(6)]
    appeared, creature, kinds = 0, [], {}
    for _ in range(turns):
        bn._lives(memory)
        game.run_to(END_OF_TURN)
        now = [memory[MONSTERS + RECORD * r] for r in range(6)]
        for old, new in zip(before, now):
            if new == 128 and old != 128:
                appeared += 1
            if 64 <= new < 80 or 112 <= new < 128:
                if not (64 <= old < 80 or 112 <= old < 128):
                    sort = "64-79" if new < 80 else "112-127"
                    kinds[sort] = kinds.get(sort, 0) + 1
        if any(136 <= g < 140 for g in now) and not any(136 <= g < 140 for g in before):
            creature.append(memory[TURNS])
        before = now
        game.turns(1)
    return {"appeared": appeared, "creature": creature, "kinds": kinds, "turns": turns}


def _creatures_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    R = listing.r
    memory = bn.game_memory(snapshot)

    def pic(graphic: int, alt: str) -> str:
        return pictures.piece(f"sprite_{graphic}.png", sprite_of(memory, graphic),
                              alt, 2)

    log("  what each antibody does to each monster...")
    strikes = strike_table(snapshot)
    for (mk, ak), routine in strikes.items():
        expected = [HIT_DESTROYS, HIT_CHANGES, HIT_SPLITS, HIT_DEMOTES][(mk + ak) & 3]
        _check(routine == expected, f"monster kind {mk}, antibody kind {ak}: "
                                    f"${routine:04X}")
    kinds = nearest_kinds(snapshot)
    _check(all(kinds[n] == 3 - n for n in range(4)), f"NEAREST_VILLAIN gave {kinds}")
    records = antibody_records(snapshot)
    _check(records == {0: 1, 1: 0}, f"ANTIBODY_STRIKE gave {records}")
    _check(memory[0xD36C] == 0x03 and memory[0xD36E] == 0x44,
           "COLOUR_WALL does not take bright ink 4-7 from the type's low two bits")
    _check(memory[0xC611] == 0x03 and memory[0xC615] == 0x30,
           "SPAWN_FIND does not take graphic 48 + 4 * the type's low two bits")

    strike_rows = []
    for mk in range(4):
        row = [f"{pic(112 + 4 * mk, f'Monster {112 + 4 * mk}')} {112 + 4 * mk}-"
               f"{115 + 4 * mk}"]
        for ak in range(4):
            name = OUTCOME_NAMES[strikes[(mk, ak)]]
            row.append(f"<b>{name}</b>" if name == "destroyed" else name)
        strike_rows.append(row)

    on_map = sorted({nd.cell(memory, u, v) for u in range(32) for v in range(32)} - {0, 1, 2})
    chain_rows = []
    for n in range(4):
        villain = 108 - 4 * n
        kind = kinds[n]
        killer = [ak for ak in range(4) if strikes[(kind, ak)] == HIT_DESTROYS][0]
        panel_ink = INKS[memory[THING_COLOURS + 5 + killer] & 7]
        chain_rows.append([
            f"{pic(villain, f'Villain {villain}')} {villain}",
            f"{pic(112 + 4 * kind, '')} {112 + 4 * kind} and {pic(64 + 4 * kind, '')} "
            f"{64 + 4 * kind}",
            f"{pic(80 + 4 * killer, '')} {80 + 4 * killer}",
            f"{pic(48 + 4 * killer, '')} {48 + 4 * killer}",
            f"{INKS[4 + killer]} (types {_numbers([t for t in on_map if t & 3 == killer])})",
            panel_ink])

    log("  the finds' stock, the bonus, and what appears round a knight left standing...")
    stocks = game_stocks(snapshot)
    stocked = stocks[2:]
    _check(stocks[0] == 0 and stocks[1] == 0 and min(stocked) >= 16 and max(stocked) <= 31,
           f"the stocks are not 16-31: {stocks}")
    bonus = bonus_placements(snapshot)
    placed_total = sum(bonus["placed"].values())
    kept_total = sum(bonus["kept"].values())
    kept_cells = sorted(bonus["kept"])
    _check(all(du == 0 and abs(dv) in (2, 3) for du, dv in kept_cells),
           f"a bonus outside his column, or further than three rows, outlasted its first "
           f"update: {kept_cells}")
    bonus_rows = []
    for cell in sorted(bonus["placed"], key=lambda c: (c[0], c[1])):
        bonus_rows.append([f"{cell[0]:+d}", f"{cell[1]:+d}", bonus["placed"][cell],
                           bonus["kept"].get(cell, 0)])
    watch = spawn_watch(snapshot)
    _check(all(t == 0 for t in watch["creature"]) and watch["creature"],
           f"the creature came when the turn counter's low byte was {watch['creature']}")

    monster_pics = " ".join(pic(g, f"Graphic {g}") for g in (64, 68, 72, 76))
    monster2_pics = " ".join(pic(g, f"Graphic {g}") for g in (112, 116, 120, 124))
    appear_pics = " ".join(pic(g, f"Graphic {g}") for g in (128, 129, 130, 131))
    creature_pic = pic(136, "The creature")
    antibody_pics = " ".join(pic(g, f"Graphic {g}") for g in (80, 84, 88, 92))
    find_pics = " ".join(pic(g, f"Graphic {g}") for g in (48, 52, 56, 60))
    bonus_pics = f"{pic(2, 'Graphic 2')} {pic(3, 'Graphic 3')}"

    return "\n".join([
        '<div class="kl-list">',
        "<p>The town is full of things that come for the knight: monsters that appear "
        "round him every few turns, and now and then a creature out of nowhere. He fights "
        "them with antibodies, which he finds in the buildings, and each villain's "
        "monsters fall to one kind of antibody only. This page is how all of that "
        "works. The four villains themselves, and the objects that kill them, are "
        f"{page('Quest', 'the quest')}.</p>",

        "<h3>Where monsters come from</h3>",
        f"<p>Every fourth turn, once the knight has appeared, {R(SPAWN_MONSTER)} puts a "
        "monster in the first free one of the six monster records: in his cell or one "
        "of the eight round it, at a random place, as graphic 128, a monster appearing. "
        f"It takes four turns to appear, 128 to 131, with a note that rises "
        f"({R(APPEARING_UPDATE)}):</p>",
        f"<p>{appear_pics}</p>",
        "<p>Then the random number's low byte makes it one of two sorts: below 128 a "
        "walker of graphics 112-127, otherwise a wanderer of 64-79. Both come in four kinds of "
        f"four frames, and the kind is the kind of the villain nearest where it appeared "
        f"({R(NEAREST_VILLAIN)}): run with a monster appearing beside each villain in "
        f"turn, it returned {', '.join(str(kinds[n]) for n in range(4))} for the villains "
        "in records 0 to 3. A monster three cells or more from the knight is simply "
        "forgotten, its record emptied, so they only ever gather round him. Left standing "
        f"in an open cell for {watch['turns']} turns, the knight saw {watch['appeared']} "
        f"monsters appear, {watch['kinds'].get('64-79', 0)} becoming wanderers and "
        f"{watch['kinds'].get('112-127', 0)} walkers: fewer than one every fourth turn, "
        "because a new one needs a free record, and not evenly split, since the random "
        "number is not evenly spread.</p>",
        f"<p>{monster_pics} The wanderers, 64-79 ({R(WANDERING_MONSTER)}): they drift "
        "about at random, up to 14 units a turn each way. Any antibody destroys one, for "
        "500 points; touching the knight, one takes a hit off him, scores 500 all the same, "
        "and bursts.</p>",
        f"<p>{monster2_pics} The walkers, 112-127 ({R(MONSTER112_UPDATE)}): they walk "
        "straight, turning at walls and now and then, and one that appeared in the first "
        "half of a 256-turn cycle turns towards the knight when it turns (see "
        f"{page('Movement', 'how things move')}). Touching him, one takes a hit, scores "
        "2500 and bursts.</p>",

        "<h3>Hits</h3>",
        f"<p>The knight has three hits a life (HITS). A monster or the creature that "
        f"touches him ({R(TOUCHING_KNIGHT)}) takes one, and his colour shows what is left: "
        "white, then yellow, then green (see "
        f"{page('Drawing', 'the drawing page')}). The last hit ends the life. A villain "
        "that touches him ends it at once, whatever he has left. Nothing can touch him "
        "while he is appearing at the start of a life. Touching is the same test "
        f"everywhere ({R(TOUCH_TEST)}): the two are closer along U than the first's "
        "half-size plus half the second's, and the same along V -- so it is not "
        "symmetrical, and the knight, as the second, reaches only half as far as his "
        "half-size says.</p>",

        "<h3>Antibodies, and what they do</h3>",
        f"<p>Every sixteenth turn, if a find record is free, {R(SPAWN_FIND)} puts a find "
        "in the knight's own cell -- if that cell is built on and its type still has "
        "finds in stock. So finds come only inside buildings. The kind of find is the low "
        "two bits of the building's type, which is also what picks its walls' colour: "
        "green, cyan, yellow or white. A find wanders about the room and is his if he "
        f"touches it ({R(FIND_WANDER)}); carried, it is an antibody, and the fire key "
        f"throws the last thing he took up ({R(KNIGHT_THROWS)}).</p>",
        f"<p>{find_pics} The four finds, 48-63; carried and thrown, each is an antibody "
        f"in flight: {antibody_pics}</p>",
        f"<p>A find left behind when the knight leaves the room goes back into the stock. "
        f"The stock is kept by cell type, not by building ({R(STOCKS)}): every building "
        f"of a type shares it. A new game gives each type from 2 up 16 to 31 finds, read "
        f"from the ROM ({R(STOCK_BUILDINGS)}); in the game this page started, "
        f"{sum(stocked)} in all, {min(stocked)} to {max(stocked)} a type.</p>",
        f"<p>An antibody in flight does not look for anything. Each monster, in its own "
        f"update, asks whether an antibody touches it ({R(ANTIBODY_STRIKE)}). A wanderer "
        "is simply destroyed. What happens to a walker depends on the two kinds together: "
        f"{R(STRIKE_OUTCOME)} adds the monster's kind to the antibody's, and the sum's "
        f"low two bits pick one of four routines ({R(MONSTER_HIT_TABLE)}). Run in the "
        "simulator for every pair, stopping at whichever of the four it reached:</p>",
        table(["Monster", "Antibody 80-83", "84-87", "88-91", "92-95"], strike_rows),
        f"<p>Destroyed scores 2500 ({R(HIT_DESTROYS)}); changed into the next kind, one "
        f"that needs another antibody, 2000 ({R(HIT_CHANGES)}); split in two, 1500 "
        f"({R(HIT_SPLITS)}); turned into a wanderer, which any antibody will then destroy, "
        f"1000 ({R(HIT_DEMOTES)}). The split does not do what it was meant to: its search "
        "for a free record looks at the wrong records, and the copy lands on the first "
        "monster record whatever is in it.</p>",
        "<p>So each villain's walkers fall to one kind of antibody only, and the kind "
        "comes from the colour of the building it was found in. Put together from the "
        "runs above and the code that makes finds and antibodies:</p>",
        table(["Villain", "Its monsters", "Destroyed by", "Found as", "In buildings "
               "coloured", "On the panel"], chain_rows),
        f"<p>One more slip: {R(ANTIBODY_STRIKE)} means to try both antibody records, but "
        "loads the step to the second into a register and never adds it, so it tries the "
        "first twice. Run with a monster and an antibody on the same spot: with the "
        f"antibody in the first record, {'struck' if records[0] else 'not struck'}; in "
        f"the second, {'struck' if records[1] else 'not struck'}. An antibody thrown while "
        "another is still in flight passes through every monster it meets.</p>",

        "<h3>The creature</h3>",
        f"<p>{creature_pic} Once every 256 turns, when the turn counter's low byte comes "
        f"round to 0, {R(SPAWN_CREATURE)} turns the first monster record that is not "
        "near the knight into the creature, graphics 136-139, and puts it in his own cell. "
        f"It makes straight for him, two units a turn along each axis ({R(CREATURE_UPDATE)}), "
        "blipping as it comes. Touching him it takes a hit; an antibody (the first record's) "
        "bursts it for 1000; and a wall bursts it too, for the same 1000 -- the reward "
        "for leading it into one. Watched with the knight standing still for "
        f"{watch['turns']} turns, it came {len(watch['creature'])} times, each time with "
        "the counter's low byte at 0.</p>",

        "<h3>The bonus</h3>",
        f"<p>{bonus_pics} A bonus is nearly always about. Whenever the bonus record is "
        f"empty, {R(PLACE_BONUS)} tries to put one in a cell in the knight's own column "
        "or the fourth to its right, and from four rows above his to three below, as "
        "long as the cell is not solid and not beside him: graphic 2, a faster walk for "
        f"255 turns ({R(SPEED_BONUS)}), on an even turn, and graphic 3, all three hits "
        f"back ({R(HITS_BONUS)}), on an odd one. But a bonus lies only while the knight "
        "is within three cells of it in both directions, so one placed four columns "
        "over, or four rows away, is gone again at its first update, and the next turn "
        f"tries again. With the knight standing in cell ({BONUS_CELL[0]},{BONUS_CELL[1]}) "
        f"and the bonus record emptied at the start of each of {BONUS_TRIES} turns, "
        f"{placed_total} bonuses were placed ({bonus['graphics'][2]} of graphic 2, "
        f"{bonus['graphics'][3]} of graphic 3; the other {bonus['none']} turns chose a "
        f"solid cell or one beside him), and {kept_total} were still there a turn later: "
        "all of them in his own column, two or three rows away.</p>",
        table(["Columns over", "Rows over", "Placed", "Still there a turn later"],
              bonus_rows),
        "<p>The rows are far from even. The row comes from the random number's high byte, "
        "which is the least random part of it: the turn counter's high byte added once a "
        "stir, the same for 256 turns at a time.</p>",

        "<h3>Confirmed and inferred</h3>",
        "<ul>"
        "<li>Run in the simulator when this page was built: the strike outcomes for all "
        "sixteen pairs; the nearest villain's kind for each villain; the antibody test "
        "with each antibody record; the finds' stock at a new game; the bonus's "
        "placements; the monsters and the creature round a knight left standing.</li>"
        "<li>Read from the code: the spawning rates, the hits, the scores, the chain from "
        "a building's colour to a find's kind to an antibody's (the build checks the "
        "bytes that make it).</li>"
        "<li>Inferred: that the one-kind-per-villain scheme was meant as the game's "
        "puzzle -- a player has to learn which buildings' antibodies work where -- and "
        "that the split and the second antibody record are slips.</li>"
        "</ul>",
        "</div>"])


# --------------------------------------------------------------------------
# 5. The quest.
# --------------------------------------------------------------------------

PERCENT_CASES = [(1, 0), (64, 0), (100, 0), (312, 0), (625, 0), (625, 3), (625, 4),
                 (0, 4), (1024, 0)]


def object_strikes(snapshot: Path) -> dict:
    """OBJECT_STRIKE (#R$C554) with object n thrown and villain m on the
    same spot, the other villain records empty: whether it strikes."""
    from skoolkit.simutils import F

    out = {}
    for n in range(4):
        for m in range(4):
            memory = list(bn.game_memory(snapshot))
            for k in range(4):
                memory[VILLAINS + RECORD * k] = 0
            _put(memory, OBJECTS + RECORD * n, 11 - n, 5, 5)
            _put(memory, VILLAINS + RECORD * m, 108 - 4 * m, 5, 5)
            out[(n, m)] = call(memory, OBJECT_STRIKE,
                               _ix_iy(OBJECTS + RECORD * n)).registers[F] & 1
    return out


def percentages(snapshot: Path) -> list[tuple[int, int, int]]:
    """PERCENTAGE (#R$BEDF) with the first N cells' bits of VISITED set and
    the first V villain records emptied: the percentage it works out."""
    out = []
    for cells, destroyed in PERCENT_CASES:
        memory = list(bn.game_memory(snapshot))
        for index in range(128):
            memory[VISITED + index] = 0
        for cell in range(cells):
            memory[VISITED + cell // 8] |= 1 << (cell % 8)
        for k in range(4):
            memory[VILLAINS + RECORD * k] = 0 if k < destroyed else 108 - 4 * k
        simulator = call(memory, PERCENTAGE)
        value = _bcd(simulator.memory[PERCENT]) * 100 + _bcd(simulator.memory[PERCENT + 1])
        out.append((cells, destroyed, value))
    return out


SCORE_WHAT = {
    0xC026: "the creature struck by an antibody, or run into a wall",
    0xC0B0: "a walker (112-127) touching the knight",
    0xC0E2: "a walker destroyed by an antibody",
    0xC0F9: "a walker changed into the next kind",
    0xC123: "a walker split, with no record to split into",
    0xC14C: "a walker split in two",
    0xC15C: "a walker turned into a wanderer",
    0xCEED: "a wanderer (64-79) struck, or touching the knight",
    0xD83B: "a villain destroyed by its object",
}


def score_calls(memory, listing: Listing) -> list[tuple[int, int, int]]:
    """Every LD BC,nn followed by CALL or JP ADD_SCORE in the code: where,
    and the points as shown (B the ten thousands and C the hundreds, BCD)."""
    out = []
    for address in range(START, BUFFER - 6):
        if (memory[address] == 0x01 and memory[address + 3] in (0xCD, 0xC3)
                and _word(memory, address + 4) == ADD_SCORE):
            b, c = memory[address + 2], memory[address + 1]
            out.append((address, _bcd(b) * 10000 + _bcd(c) * 100, listing.entry_of(address)))
    return out


def quest_run(snapshot: Path) -> dict:
    """A game played by the build's own quest steps (build_nightshade._villain):
    each object laid by the knight, picked up, thrown once at nothing, picked
    up again and thrown with its villain put in its way. The screen after the
    first villain has died, the paper flashing while it dies, and the ending."""
    game = Game(snapshot)
    memory = game.memory
    placed = {"objects": [(memory[OBJECTS + RECORD * n + U + 1],
                           memory[OBJECTS + RECORD * n + V + 1]) for n in range(4)],
              "villains": [(memory[VILLAINS + RECORD * n + U + 1],
                            memory[VILLAINS + RECORD * n + V + 1]) for n in range(4)]}
    before = screen_image(memory)
    game.play(bn._villain(0))
    flashes, frames = [], []
    for _ in range(9):
        game.run_to(END_OF_TURN)
        flashes.append(memory[0xBBFB] >> 3 & 7)
        frames.append(memory[VILLAINS])
        game.turns(1)
    after = screen_image(memory)
    score = bytes(memory[SCORE:SCORE + 3])
    for n in (1, 2, 3):
        game.play(bn._villain(n))
    game.play([bn.Until("the ending", lambda m: m[ENDING] != 0, 60.0)])
    ending, turns = None, 0
    for turns in range(1, 600):
        if not game.run_to(MAIN_LOOP, 10.0, required=False):
            break
        if turns == 30:
            ending = screen_image(memory)
    return {"placed": placed, "before": before, "after": after, "flashes": flashes,
            "frames": frames, "score": score, "ending": ending, "ending_turns": turns}


def ending_crop(screen, margin: int = 24):
    """The part of an ending screen with anything on it, and a margin."""
    box = screen.getbbox()
    if box is None:
        return screen
    left, top, right, bottom = box
    return screen.crop((max(0, left - margin), max(0, top - margin),
                        min(256, right + margin), min(192, bottom + margin)))


def _quest_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    R = listing.r
    memory = bn.game_memory(snapshot)

    def pic(graphic: int, alt: str) -> str:
        return pictures.piece(f"sprite_{graphic}.png", sprite_of(memory, graphic), alt, 2)

    log("  which object strikes which villain...")
    strikes = object_strikes(snapshot)
    _check(all(strikes[(n, m)] == (1 if n == m else 0) for n in range(4) for m in range(4)),
           f"OBJECT_STRIKE's pairs are not record for record: {strikes}")
    pair_rows = []
    for n in range(4):
        thing = 4 - n
        colour = INKS[memory[THING_COLOURS + thing] & 7]
        pair_rows.append([n, f"{pic(7 - n, f'Object {7 - n}')} {7 - n} lying, {11 - n} "
                             f"thrown", thing,
                          f"{pic(108 - 4 * n, f'Villain {108 - 4 * n}')} {108 - 4 * n}-"
                          f"{111 - 4 * n}", colour])
    strike_matrix = []
    for n in range(4):
        strike_matrix.append([f"object record {n}"] + ["<b>struck</b>" if strikes[(n, m)]
                                                         else "passes through"
                                                         for m in range(4)])

    log("  the percentage, and the score...")
    cases = percentages(snapshot)
    standable = sum(1 for u in range(32) for v in range(32) if nd.cell(memory, u, v) not in (1, 2))
    _check(standable == 625, f"{standable} cells a knight can stand in")
    table_cases = {(c, d): p for c, d, p in cases}
    _check(table_cases[(625, 4)] == 100 and table_cases[(625, 0)] == 98,
           f"the percentages are {cases}")
    percent_rows = [[c, d, c + 3 * d, f"{p}%"] for c, d, p in cases]
    scores = score_calls(memory, listing)
    _check(any(points == 250000 for _, points, _ in scores), "no 250000 among the scores")
    score_rows = []
    for address, points, entry in scores:
        score_rows.append([f"{points:,}", SCORE_WHAT.get(address, ""),
                           R(entry) if entry is not None else f"${address:04X}",
                           f"${address:04X}"])

    log("  the quest played to the end...")
    run = quest_run(snapshot)
    _check(run["score"] == bytes([0, 0x25, 0]), f"one villain scored {run['score'].hex()}")
    _check(run["ending"] is not None, "the ending never came")
    panel_before = big(run["before"].crop((0, 136, 256, 192)), 2)
    panel_after = big(run["after"].crop((0, 136, 256, 192)), 2)
    watched = []
    for flash, frame in zip(run["flashes"], run["frames"]):
        watched.append(INKS[flash])
        if frame == 0:
            break
    flash_names = ", ".join(watched)
    lives = memory[LIVES_BYTE] >> 2
    obj_cells = ", ".join(f"({u},{v})" for u, v in run["placed"]["objects"])
    vil_cells = ", ".join(f"({u},{v})" for u, v in run["placed"]["villains"])

    return "\n".join([
        '<div class="kl-list">',
        "<p>Nightshade's quest: four villains haunt the town, and each can be destroyed "
        "only by one of four objects that lie somewhere in its streets. The knight has to "
        "find each object, carry it, and throw it at the right villain. When all four are "
        "gone the game ends with the villains sinking into a pit. This page is how the "
        "game keeps track of all that, and what it counts: the score, the percentage and "
        "the lives.</p>",

        "<h3>Four objects, four villains</h3>",
        f"<p>At every new game {R(PLACE_OBJECTS)} and {R(PLACE_VILLAINS)} put the four "
        "objects and the four villains each in a cell of its own choosing: a random "
        "address in the ROM is read in pairs of bytes as a column and a row, until one is "
        "a cell a knight can stand in. Nothing stops two sharing a cell, or a villain "
        "standing where the knight starts. In the game this page started, the objects "
        f"were in cells {obj_cells} and the villains in {vil_cells}.</p>",
        "<p>Which object kills which villain is decided by nothing but the order of the "
        f"records. A thrown object ({R(OBJECT_FLIGHT)}) tests only the villain four "
        f"records -- 64 bytes -- on from its own ({R(OBJECT_STRIKE)}), so object record n "
        "and villain record n are a pair:</p>",
        table(["Record", "Object", "Carried as thing", "Its villain", "Colour on the "
               "panel"], pair_rows),
        "<p>Run in the simulator with each object and each villain on the same spot, the "
        "other villain records empty:</p>",
        table(["", "Villain record 0", "1", "2", "3"], strike_matrix),
        "<p>A thrown object passes through the other three villains as if they were not "
        "there, and flies on until it meets a wall, where it falls and lies as an object "
        "again, to be picked up once more.</p>",

        "<h3>Carrying</h3>",
        f"<p>The knight carries up to eleven things, objects and antibodies alike, in the "
        f"order he took them up ({R(CARRIED)}), each shown on the panel down the left of "
        f"the screen, the first at the bottom ({R(PICK_UP_THING)}). The fire key throws "
        "the last one taken up, so the order he gathers things in is the order he can "
        "use them. With all eleven places full an object stays where it lies, but a find "
        "is taken up and lost. An object he carries flashes on the panel when its villain "
        f"is less than five cells away in both directions ({R(COLOUR_CARRIED)}): the "
        "game's hint that the villain it kills is near.</p>",

        "<h3>A villain destroyed</h3>",
        f"<p>Struck by its object, a villain becomes graphic 132, dying "
        f"({R(VILLAIN_DYING)}): for eight turns it bursts and the whole play area's paper "
        "flashes through the colours, one a turn; 250,000 goes on the score; four sparkles "
        f"fly out from where it stood ({R(VILLAIN_SPARKLES)}), taking over the four find "
        "records, whatever was in them; and the villains on the panel are drawn again, "
        f"the dead one now in its colour ({R(DRAW_VILLAINS)}). Run in the simulator with "
        "the build's own quest steps, the first villain struck and watched from the "
        f"next turn on: the paper went {flash_names}, a colour a turn until the record "
        "emptied, and the score was 0250000.</p>",
        '<div>'
        + figure(pictures.piece("quest_panel_before.png", panel_before, "The panel at the "
                                "start", 1),
                 "The panel at the start of the game: the four villains in outline.")
        + figure(pictures.piece("quest_panel_after.png", panel_after, "The panel after a "
                                "villain", 1),
                 "After the first villain has died: its picture in its colour, and the "
                 "score.")
        + "</div>",
        f"<p>When all four villain records are empty and no sparkle is still on the screen "
        f"({R(CHECK_QUEST_DONE)}), the game is over, with the quest done "
        f"({R(GAME_OVER)}): the percentage and the score are shown, and then ten records "
        f"are filled from {R(ENDING_RECORDS)} and the main loop runs on with nothing but "
        "them -- the back and front of a pit, and the four villains, carried across one "
        "at a time and sunk into it. In the run above it lasted "
        f"{run['ending_turns']} turns before the game went back to its menu.</p>",
        figure(pictures.piece("quest_ending.png", big(ending_crop(run["ending"]), 2),
                              "The ending", 1),
               "The ending, thirty turns in: the first villain, in red, over the pit and "
               "sinking into it."),

        "<h3>The score</h3>",
        f"<p>{R(ADD_SCORE)} adds in BCD, and the score shows seven digits, the last two "
        "always 00: they are printed from a byte nothing ever writes. So what is shown is "
        "a hundred times what the code adds. Every call that scores, found by searching "
        "the code for a load of BC followed by a call or jump to ADD_SCORE:</p>",
        table(["Points", "For", "In", "At"], score_rows),
        "<p>A monster that touches the knight scores as it takes his hit, the same as "
        "destroying it would.</p>",

        "<h3>The percentage</h3>",
        f"<p>After every game {R(PERCENTAGE)} works out how much of it was done: a unit for "
        f"every cell the knight has been in (a bit each in {R(VISITED)}, set by "
        f"{R(VISIT_CELL)} as he walks) and three for every villain destroyed. Each unit "
        "adds 10288 to a 16-bit sum of which 65536 is one per cent, counting the carries "
        f"in BCD, and 144 more at the end: exactly what makes 637 units a hundred. The "
        f"town has {standable} cells a knight can stand in, and 625 + 3 x 4 is 637. Run "
        "with VISITED and the villain records staged:</p>",
        table(["Cells visited", "Villains destroyed", "Units", "Percentage"], percent_rows),
        "<p>Every cell alone is 98%; the villains make the rest. The count wraps past 99 "
        "without carrying, which only matters for more cells than a knight can visit "
        f"(every bit set, 1024 units, comes out as {table_cases[(1024, 0)]}%: the hundred "
        "is lost). And the hundred, "
        f"when it comes, is printed wrongly ({R(PRINT_PERCENTAGE)}): it is printed by "
        "jumping into the digit printer past the point where it chooses its font, so the "
        "three characters come out of whatever font was used last.</p>",

        "<h3>Lives</h3>",
        f"<p>A game starts with {lives} lives -- from the opcode at LIVES_BYTE, see "
        f"{page('Architecture', 'how the game is put together')} -- and the first life "
        f"takes one, so the panel shows {lives - 1}. When a life ends the knight vanishes "
        f"where he stood, and the next starts in that same cell ({R(NEW_LIFE)}, from the "
        f"cell {R(KNIGHT_KILLED)} writes into the start records): he appears from the "
        "ground up over eighteen turns, untouchable meanwhile, and the monsters round "
        "him are cleared away. A villain standing in the cell kills him again the moment "
        "he has appeared, as often as he comes back. With no life left to take the game "
        "is over.</p>",

        "<h3>Beside Pentagram</h3>",
        f"<p>Pentagram, a year later, has a quest of its own "
        f"({pg('Quest', 'the well, the bucket and the pentagram')}) and monsters of its own "
        f"({pg('Creatures', 'bolts, things from the sky and the monsters')}), in rooms. "
        "Nightshade's quest is thrown rather than carried to a place, and its pairs are "
        "fixed by nothing but where the records lie.</p>",

        "<h3>Confirmed and inferred</h3>",
        "<ul>"
        "<li>Run in the simulator when this page was built: the object-and-villain pairs, "
        "all sixteen; the percentage for each case in the table; a game played by the "
        "build's quest steps through the four villains and the ending.</li>"
        "<li>Staged: in the quest run each object is laid by the knight and its villain "
        "put in its path (build_nightshade._villain), so no walking of the town was "
        "needed; the percentages from written VISITED bits and villain records.</li>"
        "<li>Read from the code: the placing, the carrying and throwing order, the "
        "flashing hint, the scoring calls (searched), the lives.</li>"
        "<li>Inferred: that the pairs were meant to follow the records' order; the code "
        "gives no other link between an object and its villain.</li>"
        "</ul>",
        "</div>"])
