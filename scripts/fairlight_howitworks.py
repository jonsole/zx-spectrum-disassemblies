"""Fairlight's "How it works" pages: how the game is put together, how a room
is drawn, how a moving object is put on the screen, how things move and
collide, and the things and creatures of the castle.

build() returns each page's HTML for the build's generated ref file and
writes the pictures into html_dir/images/howitworks/. Nothing here is a
transcription of the game: every table is read from the game's memory as the
page is built, and every worked example is the game's own code run in
SkoolKit's simulator -- the build's own Machine (build_fairlight.py), started
from the snapshot at $C47C, through the loading tune and the title into the
first room, and driven the way the build's sessions drive it: by keys, and by
entering a room the way a new game enters its first (TELE). Where a scene is
staged by writing to memory, the page says what was written. Numbers the
prose quotes are read back from the runs, and the build stops if a run does
not come out the way the code says it must.

Fairlight is Bo Jangeborg's engine, not Ultimate's Filmation: rooms are
little programs of points, lines and textured fills rather than rooms of
blocks, and moving objects are put straight onto the screen through four
buffer pages and a clean copy of the room. The prose is written from the
listing's annotations and the stage 2 notes. Ville Krumlinde's disassembly
(github.com/VilleKrumlinde/FairlightZ80, no licence) came first; facts from it
are credited, none of its words or pictures are used, and where this
disassembly disagrees with it the pages say so and how it was checked.
"""
from __future__ import annotations

import re
from pathlib import Path

import build_fairlight as bf
import fairlight_data as fd

IMAGE_URL = "images/howitworks"
TSTATES = 3500000
KRUMLINDE = "https://github.com/VilleKrumlinde/FairlightZ80"

# --------------------------------------------------------------------------
# Addresses read or run here (see their entries in the listing).
# --------------------------------------------------------------------------

# Below the code.
FRAMES = 0x5C78             # the ROM's frame counter, under a sprite
KSTATE = 0x5C00             # the ROM's keyboard variables, likewise
SOURCE_AND_STACK = 0x617C
STACK_TOP = 0x639A
MASTER_OBJECTS = 0x639C
MASTER_VARIABLES = 0x684C
MASTER_KNIGHT = 0x6889
ROOMS = fd.ROOMS
PARTS = fd.PARTS
OBJECTS = 0xA924
TITLE_PAGE_TEXT = 0xB686
TEMPLATES = 0xB734
LARGE_TEMPLATES = 0xB9AA
PATCHES = 0xBA3E
FONT = 0xBAD8
FIXED_RECORDS = 0xBC18
KNIGHT = 0xBC90
RECORDS = 0xBCA4
CLEAN_COPY = 0xC000
LOADING_TUNE = 0xC000
TUNE_EI = 0xC018
NOTE_LENGTH = 0xC025
TUNE_PLAYED = 0xC00F        # back from a note in the tune's loop
TUNE_VOICES = 0xC0B0
START = 0xC47C
START_DI = 0xC487
OBJECTS_TAPE = fd.OBJECTS_TAPE
TEMPLATES_TAPE = fd.TEMPLATES_TAPE
LOADER_TABLE = 0xDAC0
LOADER_RETURN_WORD = 0xDAD9
LOADER_CLEARED = 0xDADF
LOADER_FAILURE = 0xDCC9
SYMBOL_TABLE = fd.SYMBOLS
MESS2 = 0xDFF2
SHOW_MESSAGE = 0xE038
TEXTURES = fd.TEXTURES
COMPOSITE_TO_SCREEN = 0xE3E4
COMPOSITE_LOOP = 0xE45C
ISO_MOVE = 0xE4F7
DRAW_CURRENT_ROOM = 0xE55B
ROOM_DEFAULTS = 0xE582
DRAW_ROOM_RECORD = 0xE597
RUN_ROOM_COMMANDS = 0xE5A6
CARRY_OUT = 0xE5AC          # RUN_ROOM_COMMANDS: the CALL of DO_ROOM_COMMAND
CLEAR_ROOM_SCREEN = 0xE5BA
DO_ROOM_COMMAND = 0xE5E8
PATCH_RECORDS = 0xE605
FILL_NEXT_SEED = 0xE734
FILL_SEED = 0xE73D
FILL_NEXT_PIXEL = 0xE7B2
FILL_PIXEL_MARKED = 0xE7C5  # one pixel marked in the clean copy
FILL_WHOLE_BYTE = 0xE806
FILL_BYTE_MARKED = 0xE825   # eight marked at once
FILL_BYTE_TO_LEFT = 0xE834
PLOT_LINE_START = 0xE87D
MORE_ROOM_COMMANDS = 0xE89B
DRAW_LINE = 0xE8A0
DRAW_PART = 0xEA1D
PLACE_ROOM_OBJECTS = 0xEACC
PLACE_OBJECT = 0xEB1A
PLACE_FROM_TEMPLATE = 0xEB4C
PRINT = 0xEBFE
SHOW_THING_IN_USE = 0xEC4C
CLEAR_THING_BOX = 0xEC75
REDRAW_OBJECT = 0xECBD
REDRAW_TO_SCREEN = 0xED44   # REDRAW_OBJECT: the CALL of the compositor
CULL_OBJECT = 0xED47
SORT_AND_DRAW_BEHIND = 0xEDC6
IS_IN_FRONT = 0xEE73
DRAW_SPRITE = 0xEE8D
DRAW_SPRITE_ROWS = 0xEF6C
SHIFT_JR = 0xEFD0
FAR_CORNER = 0xF036
CLEAR_BELOW = 0xF050
TITLE_SCREEN = 0xF065
NEW_GAME = 0xF089
TELE = 0xF09B
WAIT = 0xF0D2
INPUT = 0xF0DF
IN31 = 0xF0E6
ATTRI = 0xF0FB
RESTOR = 0xF10B
MIMAN = 0xF117
MIWRAI = 0xF11F
MITRO = 0xF127
MW = 0xF157
FACING = 0xF199
DECLI1 = 0xF1B4
CHE3D = 0xF1E0
FREEZE_TEST = 0xF263        # CHE3D: Release 2's CP 5 : JR NZ,I00
STEER = 0xF2F7
CREATURE_UPDATE = 0xF309
KNIGHT_UPDATE = 0xF3CD
SET_THING_ROOM = 0xF4E6
PICK_UP = 0xF4F4
PICK_UP_LOOK_ON = 0xF52A
KNIGHT_CONTROLS = 0xF595
ANIMATE_AND_MOVE = 0xF65C
ADD_GRAVITY = 0xF67E
COMMIT_STEP = 0xF6D2
KNIGHT_FIXED_POINT = 0xF6E9
BUMPED = 0xF7C4
SAVE_OBJECT_POSITIONS = 0xF906
OBJECTS_MEET = 0xF959
MEET_DECOY = 0xFA83
BLOCKED_MOVE = 0xFA9C
STEP_ALONG_X = 0xFC07
ZOOMIN = 0xFC48
AIM_AT = 0xFC66
FIND_OBSTACLE = 0xFCA5
TEST_ONE_RECORD = 0xFCDC
ROOMST = 0xFD20
ROOM_DRAWN = 0xFDEF         # ROOMST: back from drawing the room
DRAW_STILL_THINGS = 0xFE15
MAIN_LOOP = 0xFE47
START_PASS = 0xFF21         # the author's ST3: once a pass
MESSAGE_LINE = 0xFF42
OBJECTS_LOOP = 0xFF45
UPDATE_CALL = 0xFF54        # the main loop's CALL of CHE3D
UPDATE_DONE = 0xFF57

# Variables (IY holds $FF80).
OBJECT_COUNT = 0xFF80
THIS_RECORD = 0xFF83
GRAVITY = 0xFF85
OPTIONS = 0xFF86
MESSAGE = 0xFF87
NO_RISE_MASK = 0xFF8B
ROOM_COLOUR = 0xFF8E
DECOY = 0xFF8F
THINGS_NOTED = 0xFF91
CARRIED_WEIGHT = 0xFF92
FALL_COUNT = 0xFF94
LIFE_TENS = 0xFF95
LIFE_UNITS = 0xFF96
GAME_FLAGS = 0xFF97
STRIKES_LEFT = 0xFF98
SELECTED = 0xFF9E
CARRIED = 0xFF9F
ROOM = 0xFFB4
FREE_RECORD = 0xFFB8
DRAW_LIST = 0xFFC6
REGION_X, REGION_Y, REGION_W, REGION_H = 0xFFE4, 0xFFE5, 0xFFE6, 0xFFE7
LINE_PAGE = 0xFFEA
MODE = 0xFFEB
LIST_FLAGS = 0xFFF1         # while drawing: bit 1, the list has something to draw
DRAW_WIDTH = 0xFFF3
LIST_LAST = 0xFFFF          # while drawing: the list's last index

# The object records: twenty bytes, from the six fixed ones.
RECORD = 20
KNIGHT_NUMBER = 7

SPECTRUM = [(0, 0, 0), (0, 0, 0xD7), (0xD7, 0, 0), (0xD7, 0, 0xD7),
            (0, 0xD7, 0), (0, 0xD7, 0xD7), (0xD7, 0xD7, 0), (0xD7, 0xD7, 0xD7)]
SPECTRUM_BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF),
                   (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0), (0xFF, 0xFF, 0xFF)]
INKS = ["black", "blue", "red", "magenta", "green", "cyan", "yellow", "white"]
BACKGROUND = (20, 20, 60)     # the page's own: between pictures in a strip
# Fairlight draws black ink on each room's coloured paper. A picture from the
# screen takes the colours of its attributes (or of the room it shows); one
# with no colours of its own -- a texture's cells, a screen still black on
# black -- is black ink on the Spectrum's white paper, as a sprite alone is
# (fairlight_data.sprite_image).
INK = fd.INK_RGB
PAPER = fd.PAPER_RGB
# The fill's map is the page's own picture, not the game's: the clean copy's
# set pixels orange on dark blue.
MAP_INK = (255, 200, 60)
MAP_PAPER = (16, 16, 60)
# Behind a sprite's see-through part: the Sprites page's blue-grey (kl-sprite).
SPRITE_BACKING = (0x5A, 0x5A, 0x8C)


def record(number: int) -> int:
    """The address of object record `number`, counted from 1 at #R$BC18."""
    return FIXED_RECORDS + RECORD * (number - 1)


def _word(memory, address: int) -> int:
    return memory[address] | memory[address + 1] << 8


def _esc(text: str) -> str:
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def _check(condition: bool, what: str) -> None:
    """The prose says what the code does; if a run disagrees, the page would
    be wrong, so the build stops instead."""
    if not condition:
        raise RuntimeError(f"fairlight_howitworks: {what}")


def _numbers(values) -> str:
    """1, 2, 3, 5 as '1-3, 5'."""
    values = sorted(set(values))
    runs, start = [], None
    for index, value in enumerate(values):
        if start is None:
            start = value
        if index + 1 == len(values) or values[index + 1] != value + 1:
            runs.append(str(start) if start == value else f"{start}-{value}")
            start = None
    return ", ".join(runs)


def _life(memory) -> int:
    return memory[LIFE_TENS] * 10 + memory[LIFE_UNITS]


# --------------------------------------------------------------------------
# The listing: which addresses are entries, for #R links.
# --------------------------------------------------------------------------

class Listing:
    """The entries of fairlight.skool and every label in it, read at build
    time, so a link is only made to an address that starts an entry."""

    def __init__(self, skool: Path):
        self.entries: dict[int, str] = {}
        self.labels: dict[int, str] = {}
        self.titles: dict[int, str] = {}
        label = None
        title = None
        lines = skool.read_text(encoding="utf-8").split("\n") if skool.exists() else []
        previous = ""
        for line in lines:
            if line.startswith("@label="):
                label = line[len("@label="):]
                previous = line
                continue
            if line.startswith("; ") and previous == "":
                title = line[2:]
            match = re.match(r"^([bcgistuw ]|\*)\$([0-9A-F]{4})", line)
            if match:
                address = int(match.group(2), 16)
                if match.group(1) not in (" ", "*"):
                    self.entries[address] = label or ""
                    self.titles[address] = title or ""
                if label:
                    self.labels[address] = label
                label = None
                title = None
            elif not line.startswith("@") and not line.startswith(";"):
                label = None
            previous = line
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
    """The game on the build's simulated Spectrum (build_fairlight.Machine),
    started through the tune and the title into the first room, and driven a
    pass of the main loop at a time."""

    def __init__(self, snapshot: Path, start: bool = True):
        self.machine = bf.Machine(snapshot)
        if start:
            self.play(bf._start())

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

    def run_to(self, stop: int, seconds: float = 10.0, keys=(), required: bool = True,
               interrupts: bool = False) -> bool:
        """Run until PC reaches `stop` -- at least one instruction first, so
        stopping at the same place again catches the next time round -- or
        fail, naming where it was, after `seconds` of the game's time."""
        from skoolkit.simutils import PC, T

        simulator = self.machine.simulator
        self.machine.tracer.keys = set(keys)
        limit = simulator.registers[T] + int(seconds * TSTATES)
        simulator.trace(self.machine.pc, stop, 0, limit, interrupts, None, None, None, None,
                        None)
        self.machine.pc = simulator.registers[PC]
        if self.machine.pc != stop:
            if required:
                raise RuntimeError(f"the game never reached ${stop:04X} in {seconds} s "
                                   f"(PC ${self.machine.pc:04X})")
            return False
        return True

    def passes(self, count: int = 1, keys=(), alive: bool = True) -> None:
        """Whole passes of the main loop, each to the start of the next
        (START_PASS), LIFE topped up before each unless `alive` is off."""
        for _ in range(count):
            if alive:
                bf._alive(self.memory)
            self.run_to(START_PASS, 10.0, keys)

    def enter(self, room: int) -> None:
        """Into a room the way a new game enters its first (TELE), to the
        start of its first pass."""
        self.play(bf._enter(room))

    def enter_to(self, room: int, stop: int) -> None:
        """Into a room as enter() does, stopping at `stop` on the way."""
        self.play(bf._enter(room)[:3])
        self.run_to(stop)

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

    def hl(self) -> int:
        return self.reg("H") << 8 | self.reg("L")

    def records(self) -> list[int]:
        """The numbers of the records in use after the knight's."""
        return list(range(KNIGHT_NUMBER + 1, self.memory[OBJECT_COUNT] + 1))


# --------------------------------------------------------------------------
# Pictures.
# --------------------------------------------------------------------------

def _row_address(y: int) -> int:
    """The display file's address of line y, counted down from the top."""
    return 0x4000 | ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)


def screen_image(memory, colour: int | None = None, base: int = 0x4000):
    """The display file as a 256 by 192 picture, in its attributes -- or all
    in `colour`, for a room still being drawn black on black. Where the ink
    and the paper are one colour the pixels could not be seen, and are shown
    black on white. `base` $C000 reads the clean copy, which is laid out like
    the screen."""
    from PIL import Image

    image = Image.new("RGB", (256, 192))
    pixels = image.load()
    for y in range(192):
        row = _row_address(y) - 0x4000 + base
        for column in range(32):
            byte = memory[row + column]
            attr = colour if colour is not None else memory[0x5800 + (y >> 3) * 32 + column]
            palette = SPECTRUM_BRIGHT if attr & 0x40 else SPECTRUM
            ink, paper = palette[attr & 7], palette[(attr >> 3) & 7]
            if ink == paper:
                ink, paper = INK, PAPER
            for bit in range(8):
                pixels[column * 8 + bit, y] = ink if byte & (0x80 >> bit) else paper
    return image


def map_image(memory):
    """The clean copy at #R$C000 -- the fill's map -- in the page's own
    colours, MAP_INK on MAP_PAPER: it has none of its own."""
    from PIL import Image

    image = Image.new("RGB", (256, 192))
    pixels = image.load()
    for y in range(192):
        row = _row_address(y) - 0x4000 + CLEAN_COPY
        for column in range(32):
            byte = memory[row + column]
            for bit in range(8):
                pixels[column * 8 + bit, y] = MAP_INK if byte & (0x80 >> bit) else MAP_PAPER
    return image


def big(image, scale: int = 2):
    from PIL import Image

    return image.resize((image.width * scale, image.height * scale), Image.NEAREST)


def strip(images, gap: int = 6, background=BACKGROUND):
    """Pictures side by side, their tops level."""
    from PIL import Image

    width = sum(image.width for image in images) + gap * (len(images) - 1)
    height = max(image.height for image in images)
    out = Image.new("RGB", (width, height), background)
    x = 0
    for image in images:
        out.paste(image, (x, 0))
        x += image.width + gap
    return out


def grid(images, columns: int, gap: int = 6, background=BACKGROUND):
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


def label(image, text: str, colour=(255, 255, 80)):
    """A number or a word in the top left corner of a picture, on a dark
    patch so that it reads over anything."""
    from PIL import ImageDraw

    draw = ImageDraw.Draw(image)
    box = draw.textbbox((3, 2), text)
    draw.rectangle([box[0] - 2, box[1] - 2, box[2] + 2, box[3] + 2], fill=(0, 0, 0))
    draw.text((3, 2), text, fill=colour)
    return image


def sprite_of(memory, address: int, width: int, height: int, scale: int = 1):
    """A sprite drawn as the listing draws it (fairlight_data.sprite_image:
    black ink on white paper) on the Sprites page's blue-grey, so that its
    solid part and its see-through part both show."""
    from PIL import Image

    image = fd.sprite_image(memory, address, width, height, scale)
    out = Image.new("RGB", image.size, SPRITE_BACKING)
    out.paste(image, (0, 0), image)
    return out


def project(a: int, h: int, b: int) -> tuple[float, float]:
    """Where a point of the room lands on the screen: x from the left and y
    down from the top. #R$E4F7 gives the slopes -- a step along +6 is a pixel
    right and half a row up, along +8 a pixel left and half a row up, and
    up +7 a row up -- and the knight's fixed point at $F6E9 the constants:
    at (50, 78, 50) his sprite's top left corner is at x 116, y 34, and the
    sprite, 24 pixels wide, is centred on his footprint."""
    x = a - b + 128
    y = (a + b) / 2 + h - 96
    return x, 191 - y


def outline_boxes(image, boxes, scale: int, width: int = 1):
    """Each box (a, h, b, size_a, height, size_b, colour) drawn over the
    picture as a wire frame, projected by project()."""
    from PIL import ImageDraw

    draw = ImageDraw.Draw(image)

    def at(a, h, b):
        x, y = project(a, h, b)
        return (x * scale + scale // 2, y * scale + scale // 2)

    for a, h, b, sa, sh, sb, colour in boxes:
        for level in (h, h - sh):
            draw.line([at(a, level, b), at(a + sa, level, b), at(a + sa, level, b + sb),
                       at(a, level, b + sb), at(a, level, b)], fill=colour, width=width)
        for aa, bb in ((a, b), (a + sa, b), (a, b + sb), (a + sa, b + sb)):
            draw.line([at(aa, h, bb), at(aa, h - sh, bb)], fill=colour, width=width)
    return image


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

    def piece(self, name: str, image, alt: str = "", scale: int = 1,
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


def page(name: str, text: str) -> str:
    """A link to another of these pages."""
    return f'<a href="{name}.html">{text}</a>'


def krumlinde(text: str = "Ville Krumlinde's disassembly") -> str:
    return f'<a href="{KRUMLINDE}">{text}</a>'


def swatch(colour) -> str:
    """A small square of a colour, for a key to a picture (rgb(), since a #
    before a colour would be read as a macro)."""
    r, g, b = colour
    return (f'<span style="display: inline-block; width: 0.9em; height: 0.9em; '
            f'background-color: rgb({r}, {g}, {b}); border: 1px solid rgb(0, 0, 0); '
            f'vertical-align: -0.1em; margin-right: 0.3em;"></span>')


# --------------------------------------------------------------------------
# The game's tables, read as the code reads them.
# --------------------------------------------------------------------------

def template(memory, kind: int) -> int:
    """The tape's address of the template for an object type (#R$EB1A):
    eleven bytes for types below $46, nine from $46."""
    if kind < fd.LARGE_FIRST:
        return fd.tape_address(fd.SMALL_HOME) + fd.SMALL_SIZE * kind
    return fd.tape_address(fd.LARGE_HOME) + fd.LARGE_SIZE * (kind - fd.LARGE_FIRST)


def template_state(memory, kind: int) -> int:
    """The movement state a type starts in: the low nibble of its template's
    byte 9, which #R$EB4C puts in +14."""
    return memory[template(memory, kind) + 9] & 15


def template_weight(memory, kind: int) -> int:
    """Byte 10 of the template, the record's +16: 0 for a still object, else
    16 plus its weight."""
    return memory[template(memory, kind) + 10]


def things(memory) -> list[dict]:
    """The object table's records, numbered from 1 as #R$EACC numbers them,
    with the fields #R$EB1A reads."""
    out = []
    for number, (address, length, room, kind) in enumerate(fd.object_records(memory), 1):
        entry = {"number": number, "address": address, "room": room, "type": kind,
                 "length": length}
        if kind < fd.LARGE_FIRST:
            entry["kind"] = memory[address + 2]
            entry["place"] = tuple(memory[address + 3:address + 6])
        else:
            entry["place"] = tuple(memory[address + 2:address + 5])
            entry["door"] = tuple(memory[address + 5:address + 11])
        out.append(entry)
    return out


def walk_room(memory, room: int | None = None, part: int | None = None, depth: int = 0):
    """Every command a room's drawing carries out, in order, as (address,
    length, what) from fairlight_data.room_commands, the parts it draws
    followed into (a part drawn twice is followed twice) and repeats played
    out as the interpreter plays them."""
    if room is not None:
        address = fd.room_address(memory, room)
        commands = fd.room_commands(memory, address + 3, address + _word(memory, address))
    else:
        address = fd.part_address(memory, part)
        commands = fd.room_commands(memory, address + 2, address + _word(memory, address))
    out = []
    index = 0
    repeat_from, repeats = None, 0
    while index < len(commands):
        at, length, what = commands[index]
        out.append((at, length, what, depth))
        op = memory[at]
        if what.startswith("Part"):
            out += walk_room(memory, part=memory[at + 1], depth=depth + 1)
        elif what.startswith("Repeat"):
            repeat_from, repeats = index + 1, memory[at + 1]
        elif op == 0xD6 and what.startswith("End of the repeat") and repeat_from is not None:
            repeats -= 1
            if repeats > 0:
                index = repeat_from
                continue
            repeat_from = None
        index += 1
    return out


# --------------------------------------------------------------------------
# 1. How the game is put together.
# --------------------------------------------------------------------------

def tune_run(snapshot: Path) -> dict:
    """The loading tune played to its end in the simulator, no key pressed:
    how many notes, and how long in T-states until both voices rest."""
    game = Game(snapshot, start=False)
    start = game.tstates
    notes, last = 0, start
    while True:
        game.run_to(TUNE_PLAYED, 5.0)
        now = game.tstates
        if now - last < 20000:          # a note that played nothing: both resting
            break
        notes += 1
        last = now
    return {"notes": notes, "tstates": last - start}


TUNE_REST = 41


def tune_notes(memory) -> list[list[int]]:
    """The notes of each voice, from the byte after its start pointer to its
    $40 (#R$C026)."""
    out = []
    for voice in range(2):
        at = _word(memory, TUNE_VOICES + 4 * voice) + 1
        notes = []
        while memory[at] != 0x40:
            notes.append(memory[at])
            at += 1
        out.append(notes)
    return out


def interrupt_trial(snapshot: Path) -> dict:
    """A second of play with the simulator offering interrupts: the
    interrupt flip-flop, and the ROM's frame counter, which the ROM's
    interrupt routine would count up fifty times a second."""
    from skoolkit.simutils import IFF

    game = Game(snapshot)
    before = list(game.memory[FRAMES:FRAMES + 3])
    iff = game.registers[IFF]
    game.machine.run(1.0, ["q"])        # interrupts=True: offered every frame
    after = list(game.memory[FRAMES:FRAMES + 3])
    return {"iff": iff, "iff after": game.registers[IFF], "frames": before,
            "frames after": after}


TIMING_ROOMS = [29, 2, 20, 71]
TIMING_PASSES = 24


def pass_timing(snapshot: Path) -> list[dict]:
    """Passes of the main loop in a few rooms, the knight standing and then
    walking: T-states from START_PASS to START_PASS, and the records in use."""
    out = []
    game = Game(snapshot)
    for room in TIMING_ROOMS:
        if room != game.memory[ROOM]:
            game.enter(room)
        game.passes(2)
        for walking in (False, True):
            times = []
            for index in range(TIMING_PASSES):
                bf._alive(game.memory)
                # Walking: six passes up +8 (Q), six back down (A), so that he
                # stays in the room.
                keys = (("q",) if index % 12 < 6 else ("a",)) if walking else ()
                start = game.tstates
                game.run_to(START_PASS, 10.0, keys)
                times.append(game.tstates - start)
            _check(game.memory[ROOM] == room, f"the knight walked out of room {room}")
            out.append({"room": room, "walking": walking, "times": times,
                        "records": game.memory[OBJECT_COUNT]})
    return out


BUSY_ROOM = 2               # the troll, the barrels and the things on the table
BUSY_PASSES = 6


def one_pass(snapshot: Path, room: int = BUSY_ROOM) -> dict:
    """One pass of the main loop in a room, part by part and record by record:
    the knight walking, a few passes in so that everything is under way."""
    game = Game(snapshot)
    game.enter(room)
    game.passes(BUSY_PASSES, ("y",))
    memory = game.memory
    bf._alive(memory)
    start = game.tstates
    parts = []
    game.run_to(MESSAGE_LINE, 5.0, ("y",))
    parts.append(("LIFE printed, if it changed", game.tstates - start))
    mark = game.tstates
    game.run_to(OBJECTS_LOOP, 5.0, ("y",))
    parts.append(("the message line", game.tstates - mark))
    records = []
    mark = game.tstates
    for _ in range(memory[OBJECT_COUNT] - KNIGHT_NUMBER + 1):
        game.run_to(UPDATE_CALL, 5.0, ("y",))
        number, at = memory[THIS_RECORD], game.tstates
        fields = bytes(memory[record(number):record(number) + RECORD])
        game.run_to(UPDATE_DONE, 5.0, ("y",))
        records.append({"number": number, "fields": fields, "tstates": game.tstates - at})
    game.run_to(MAIN_LOOP, 5.0, ("y",))
    parts.append(("every record from the knight's (CHE3D)", game.tstates - mark))
    mark = game.tstates
    game.run_to(START_PASS, 5.0, ("y",))
    parts.append(("the keys between passes", game.tstates - mark))
    return {"parts": parts, "records": records, "total": game.tstates - start,
            "screen": screen_image(memory)}


def source_runs(memory, start: int, end: int) -> tuple[int, int, int]:
    """The leftover source text in a range: how many whole lines, and the
    first and last line numbers. A line is a carriage return, its number
    (low byte first) and the text; only the numbers are read here."""
    numbers = []
    for at in range(start, end - 3):
        if memory[at] == 0x0D:
            number = _word(memory, at + 1)
            # The author numbered his lines in tens, and a line's text starts
            # with a tab or a label.
            if (number and number % 10 == 0 and (memory[at + 3] == 9
                                                 or 0x41 <= memory[at + 3] <= 0x5A)
                    and (not numbers or number > numbers[-1])):
                numbers.append(number)
    if not numbers:
        return 0, 0, 0
    return len(numbers), numbers[0], numbers[-1]


# What each stretch of memory is on the tape and while the game runs, and
# the colour it has in the picture.
KINDS = {
    "code": ((230, 80, 80), "code"),
    "graphics": ((80, 200, 90), "sprites, the font and the textures"),
    "level": ((240, 200, 60), "rooms, parts, the object table and the templates"),
    "records": ((90, 180, 240), "object records and variables"),
    "tune": ((240, 130, 200), "the loading tune"),
    "buffers": ((170, 110, 230), "the clean copy and the compositor's pages"),
    "leftover": ((110, 110, 130), "leftovers: source text, symbols, the loader"),
    "unused": ((40, 40, 60), "unused or unidentified"),
}
MEMORY_OUTLINE = [
    # (start, end, on the tape, while the game runs, what)
    (0x5B00, 0x617C, "graphics", "graphics", "sprites (and the system variables under them)"),
    (0x617C, 0x639C, "leftover", "leftover", "leftover source text; the stack grows down "
     "from its top"),
    (0x639C, 0x689D, "leftover", "level", "leftover text on the tape; the master copy of "
     "the object table, the variables and the knight's record once the game starts"),
    (0x689D, 0x68B0, "unused", "unused", "zeros"),
    (0x68B0, 0x758C, "level", "level", "the 81 rooms"),
    (0x758C, 0x7CCB, "level", "level", "the 56 parts rooms are drawn from"),
    (0x7CCB, 0x7D00, "unused", "unused", "53 bytes not identified"),
    (0x7D00, 0xA8FC, "graphics", "graphics", "sprites"),
    (0xA8FC, 0xA924, "leftover", "leftover", "leftover source text"),
    (0xA924, 0xB680, "leftover", "level", "leftover text on the tape; the object table "
     "once the start-up has copied it"),
    (0xB680, 0xB686, "leftover", "leftover", "leftover source text"),
    (0xB686, 0xB734, "code", "code", "the title page's words"),
    (0xB734, 0xBAD8, "leftover", "level", "leftover text on the tape; the templates and "
     "patches once copied"),
    (0xBAD8, 0xBC18, "graphics", "graphics", "the font"),
    (0xBC18, 0xBCA4, "records", "records", "the six fixed records and the knight's"),
    (0xBCA4, 0xC000, "leftover", "records", "leftover text on the tape; the room's object "
     "records in play"),
    (0xC000, 0xC0B0, "code", "buffers", "the loading tune's player; the clean copy of the "
     "room in play"),
    (0xC0B0, 0xC47C, "tune", "buffers", "the loading tune's notes"),
    (0xC47C, 0xC4BA, "code", "buffers", "the start-up"),
    (0xC4BA, 0xC4E0, "leftover", "buffers", "leftover text"),
    (0xC4E0, 0xD135, "level", "buffers", "the object table as the tape has it"),
    (0xD135, 0xD2F0, "leftover", "buffers", "leftover text"),
    (0xD2F0, 0xD694, "level", "buffers", "the templates as the tape has them"),
    (0xD694, 0xDAC0, "leftover", "buffers", "leftover text; the clean copy ends at $D7FF, "
     "and the compositor's four pages run from $D800 to $DBFF"),
    (0xDAC0, 0xDC00, "leftover", "buffers", "the loader's table and its cleared code"),
    (0xDC00, 0xDD39, "leftover", "leftover", "the end of the cleared loader, and its failure "
     "routine"),
    (0xDD39, 0xDFF2, "leftover", "leftover", "the assembler's symbol table"),
    (0xDFF2, 0xE0A4, "code", "code", "the closing lines, the message line, symbol scraps"),
    (0xE0A4, 0xE3E4, "graphics", "graphics", "the 26 textures"),
    (0xE3E4, 0xFF6A, "code", "code", "the code"),
    (0xFF6A, 0xFF80, "leftover", "leftover", "bits of the ROM's user-defined graphics"),
    (0xFF80, 0x10000, "records", "records", "the variables"),
]


def memory_picture(tape: bool):
    """$5B00 to $FFFF as rows of 1 KB, 4 bytes a pixel, coloured by what each
    stretch is on the tape or while the game runs."""
    from PIL import Image, ImageDraw

    first, rows, row_height, left = 0x5800, 42, 7, 40
    draw_start = 0x5B00
    image = Image.new("RGB", (left + 256, rows * row_height), BACKGROUND)
    draw = ImageDraw.Draw(image)
    for start, end, on_tape, running, _ in MEMORY_OUTLINE:
        colour = KINDS[on_tape if tape else running][0]
        for address in range(max(start, draw_start), end, 4):
            row, column = (address - first) // 1024, (address % 1024) // 4
            y = row * row_height
            draw.line([(left + column, y), (left + column, y + row_height - 2)], fill=colour)
    for row in range(0, rows, 4):
        draw.text((2, row * row_height - 2), f"{first + row * 1024:04X}", fill=(200, 200, 220))
    return image


def _architecture_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    R = listing.r
    memory = bf.game_memory(snapshot)

    log("  the tune, played out...")
    tune = tune_run(snapshot)
    voices = tune_notes(memory)
    note_passes = 256 - memory[NOTE_LENGTH]
    note_tstates = note_passes * 256 * 96
    # The first note from which both voices rest to the end: #R$C049 returns
    # at once from there on.
    sounding = len(voices[0])
    while sounding and voices[0][sounding - 1] == voices[1][sounding - 1] == TUNE_REST:
        sounding -= 1
    _check(len(voices[0]) == len(voices[1]) and tune["notes"] == sounding,
           f"the tune played {tune['notes']} notes, and its voices sound for {sounding}")
    _check(abs(tune["tstates"] / tune["notes"] - note_tstates) < note_tstates * 0.02,
           "a note did not take 18 passes of 256 turns of 96 T-states")

    log("  interrupts...")
    trial = interrupt_trial(snapshot)
    _check(trial["iff"] == 0 and trial["iff after"] == 0, "interrupts were on in play")
    _check(trial["frames"] == trial["frames after"], "FRAMES moved in play")
    _check(memory[START_DI] == 0xF3 and memory[TUNE_EI] == 0xFB,
           "the DI and the EI are not where the page says")
    frames_sprite = listing.entry_of(FRAMES)
    kstate_sprite = listing.entry_of(KSTATE)

    log("  passes, timed...")
    timing = pass_timing(snapshot)
    timing_rows = []
    for entry in timing:
        times = entry["times"]
        mean = sum(times) / len(times)
        timing_rows.append([
            R(fd.room_address(memory, entry["room"]), f"room {entry['room']}"),
            "walking (Q, A)" if entry["walking"] else "standing",
            entry["records"], f"{min(times):,}", f"{round(mean):,}", f"{max(times):,}",
            f"{TSTATES / mean:.1f}"])
    all_means = [sum(e["times"]) / len(e["times"]) for e in timing]

    log("  one pass, record by record...")
    busy = one_pass(snapshot)
    record_rows = []
    for entry in busy["records"]:
        fields = entry["fields"]
        kind, state, weight = fields[12], fields[14], fields[16]
        sprite = fields[4] | fields[5] << 8
        if entry["number"] == KNIGHT_NUMBER:
            what = "the knight"
        elif kind & 15 == 1:
            what = "a door"
        elif not sprite:
            what = "no sprite: an invisible box"
        elif fields[16] & 0x20:
            what = "carried or gone"
        elif not weight & 31:
            what = "still: scenery"
        elif state & 15 == 0:
            what = "a thing lying (state 0)"
        elif state & 15 == 7:
            what = "the troll (state 7)"
        else:
            what = f"state {state & 15}"
        sprite_text = R(sprite, f"${sprite:04X}") if sprite else ""
        record_rows.append([entry["number"], what, sprite_text, f"{entry['tstates']:,}"])
    part_rows = [[what, f"{t:,}"] for what, t in busy["parts"]]
    part_rows.append(["<b>the whole pass</b>", f"<b>{busy['total']:,}</b>"])
    updated = [e for e in busy["records"] if e["tstates"] > 200]
    busy_fig = figure(pictures.stage("architecture_pass.png", big(busy["screen"]),
                                     f"Room {BUSY_ROOM} at the end of the pass traced"),
                      f"Room {BUSY_ROOM} at the end of the pass in the table: the knight, "
                      "walking with Y held, and the troll beside him, with the barrels behind "
                      "and the table and stools to the right.")

    log("  the start-up's copies...")
    copies = []
    at = START_DI + 1
    for _ in range(3):      # LD HL,nn and LD DE,nn in either order, LD BC,nn, LDIR
        pair = {memory[at]: _word(memory, at + 1), memory[at + 3]: _word(memory, at + 4)}
        _check(memory[at + 6] == 0x01 and tuple(memory[at + 9:at + 11]) == (0xED, 0xB0),
               f"no LDIR copy at ${at:04X}")
        copies.append((pair.get(0x21), pair.get(0x11), _word(memory, at + 7)))
        at += 11
    _check(copies[0] == (OBJECTS_TAPE, OBJECTS, 0x0D5C) and copies[1] == (TEMPLATES_TAPE,
           TEMPLATES, 0x03A4), f"the start-up's copies are {copies}")

    log("  the leftovers...")
    nodes, _, _ = fd.symbols(memory)
    routine_names = [(value, name) for _, _, name, value in nodes if value in listing.entries]
    runs = []
    for start, end in ((0x617C, 0x639C), (0xA8FC, 0xB686), (0xB734, 0xBAD8),
                       (0xBCA4, 0xC000), (0xC436, 0xC47C), (0xC4BA, 0xC4E0),
                       (0xD135, 0xD2F0), (0xD694, 0xDAC0)):
        count, first, last = source_runs(memory, start, end)
        if count:
            runs.append((start, end, count, first, last))
    master = source_runs(bf.game_memory(snapshot), MASTER_OBJECTS, MASTER_OBJECTS + 293)

    loader_return = _word(memory, LOADER_RETURN_WORD)
    _check(loader_return == START, f"the loader's last piece returns to ${loader_return:04X}")

    log("  the states...")
    state_types: dict[int, list[int]] = {}
    for kind in range(fd.SMALL_COUNT):
        if _word(memory, template(memory, kind) + 4):
            state_types.setdefault(template_state(memory, kind), []).append(kind)
    _check(state_types.get(7) == [13] and state_types.get(11) == [45]
           and 2 not in state_types, f"the templates' states are {state_types}")

    outline_rows = []
    for start, end, on_tape, running, what in MEMORY_OUTLINE:
        link = R(start) if start in listing.entries else f"${start:04X}"
        outline_rows.append([link, f"${end - 1:04X}", f"{end - start:,}", what])
    key = " ".join(f"{swatch(colour)}{what}" for colour, what in KINDS.values())
    memory_fig = figure(pictures.piece("architecture_memory.png",
                                       strip([big(memory_picture(True), 1),
                                              big(memory_picture(False), 1)], gap=24),
                                       "Memory on the tape and in play"),
                        "$5B00 to $FFFF, a row a kilobyte and four bytes a pixel: on the left "
                        "as the tape leaves it at #R$C47C, on the right once the game runs. "
                        f"Key: {key}.")

    def types(states) -> str:
        found = []
        for state in states:
            found += state_types.get(state, [])
        return ("type " if len(found) == 1 else "types ") + _numbers(found)

    state_rows = [
        ["0", "things lying", R(CHE3D), "only falls; a thing just dropped or knocked makes "
         "its last movement once more"],
        ["3", types([3]), R(CHE3D, "I30"),
         "bounces about: keeps its movement, turning round off whatever it meets"],
        ["4", types([4]), R(CHE3D, "I4"),
         "strikes when the knight is within reach in front of it"],
        ["5", "the knight in a jump", R(CHE3D, "I5"), "eight passes going up"],
        ["6, 10", types([6, 10]),
         R(CREATURE_UPDATE, "GUARD_MOVES"), "guards: patrol, and chase within 30"],
        ["7", "type 13", R(CREATURE_UPDATE, "I6"), "the troll: chases"],
        ["8", "the knight", R(CREATURE_UPDATE, "KNIGHT_UPDATE"), "the controls"],
        ["9", types([9]), R(CHE3D, "I9"),
         "rises out of the floor, then chases (or goes for a decoy)"],
        ["11", "type 45", R(CREATURE_UPDATE, "WRAITH_MOVES"), "the wraith: chases"],
        ["12, 14", types([12, 14]),
         R(CREATURE_UPDATE, "I12"), "hang in the air and flicker"],
        ["13", types([13]), R(CREATURE_UPDATE, "I6"),
         "the ghost: wanders, and steals things it touches"],
        ["15", types([15]), R(CREATURE_UPDATE, "I6"),
         "stands still until a thing of kind 11 lies in the room, then becomes a wraith"],
    ]

    fields = [
        ["+0, +1", "where the sprite's top left corner is on the screen: x, and y counted up "
         "from the bottom"],
        ["+2, +3", "the sprite's width in pixels and height in rows"],
        ["+4, +5", "the sprite: its image, then its mask; 0 for a record nothing draws"],
        ["+6, +7, +8", "where it is in the room: +6 and +8 along the floor, +7 the height of "
         "its top"],
        ["+9, +10, +11", "its size: along +6, down from the top, along +8. The box is a corner "
         "and three sizes"],
        ["+12", "its kind: the low nibble what it is (1 a door, 4-11 things that do "
         "something), bit 4 hurts at a touch, bit 5 can be carried, bit 6 can be killed, "
         "bit 7 a fighter"],
        ["+13", "the direction it goes in (the bits are on " + page("Movement", "the movement "
         "page") + ")"],
        ["+14", "its state: the low nibble its behaviour, bit 4 carried along one pass, bits "
         "5 and 6 which way it faces, bit 7 in the air"],
        ["+15", "a countdown: to a new course, the end of a jump's rise or a bounce"],
        ["+16", "0 for a still object, which is never updated; otherwise 16 plus its "
         "weight, and bit 5 while it is carried or gone"],
        ["+17", "its animation: the frame, the run's last frame, going back"],
        ["+18", "its course: a chaser's heading, or the direction it keeps in the air"],
        ["+19", "its number in the object table, for the things; 0 for anything else"],
    ]

    run_rows = [[R(start) if start in listing.entries else f"${start:04X}",
                 f"${end - 1:04X}", f"{count}", f"{first}-{last}"]
                for start, end, count, first, last in runs]

    return "\n".join([
        '<div class="kl-list">',
        "<p>Fairlight (The Edge, 1985) is Bo Jangeborg's game, and its engine is his own. "
        "It is an isometric flip-screen adventure like Ultimate's Knight Lore, but it works "
        "quite differently: a room is not a picture or a set of blocks but a short "
        "program of points, lines and textured fills that the game runs each time the "
        "knight walks in, and a moving object is put onto the screen straight from four "
        "256-byte buffers and a clean copy of the room, without the screen ever being "
        "redrawn as a whole. This page is the outline: the tape, the start-up, a pass of "
        "the main loop, the object records, the states objects are in, where everything "
        "lies in memory, and what else the tape carries.</p>",

        "<h3>The tape and the loader</h3>",
        "<p>The tape carries the Alkatraz Protection System's loader. Its BASIC holds a "
        "routine that decrypts itself in layers and loads a second, turbo-speed stage, "
        "which reads the long block: the loading screen a line at a time in its own order, "
        "then the game in pieces, every byte XORed with a key that changes as it goes, "
        "with the count of bytes left and with the address it is stored at. The first "
        "piece extends the loader's own list of pieces; the last three bytes loaded are "
        f"the address the loader's last RET goes to, ${loader_return:04X}, and a byte of the "
        f"checksum ({R(LOADER_TABLE)}, offset {LOADER_RETURN_WORD - LOADER_TABLE}). "
        f"When the checksum holds, the loader clears itself ({R(LOADER_CLEARED)}) and "
        f"returns there; when it does not, {R(LOADER_FAILURE)} wipes memory, asks for the "
        "tape to be rewound and resets the machine. The build loads the tape through "
        "all of this in SkoolKit's simulator and does the decryption again on the tape's "
        "own bytes, checking the result against what the simulator loaded.</p>",

        "<h3>The start-up</h3>",
        f"<p>{R(START)} is the game's first instruction. It sets the stack two bytes "
        f"below the end of a stretch of leftover text ({R(SOURCE_AND_STACK)}), plays the "
        f"loading tune ({R(LOADING_TUNE)}) until a key is pressed, points IY at the "
        "variables at $FF80, turns interrupts off, and makes its copies:</p>",
        table(["From", "To", "Bytes", "What"], [
            [R(OBJECTS_TAPE), R(OBJECTS), f"{copies[0][2]:,}", "the object table (and some "
             "text after it)"],
            [R(TEMPLATES_TAPE), R(TEMPLATES), f"{copies[1][2]:,}", "the object templates and "
             "the room patches"],
            [R(OBJECTS), R(MASTER_OBJECTS), f"{copies[2][2]:,}", "a master copy of the "
             "object table's first 1200 bytes, for new games"],
            ["$FF80", R(MASTER_OBJECTS, "MASTER_VARIABLES"), "61", "a new game's variables"],
            [R(KNIGHT), R(MASTER_OBJECTS, "MASTER_KNIGHT"), "20", "the knight's record"],
        ]),
        f"<p>and jumps to the title ({R(TITLE_SCREEN)}), a loop the game never leaves: "
        "room 79 drawn with the title page's words over it, a key, the master copies put "
        "back, the knight put in the start room (TELE, the author's name), the game played "
        f"inside {R(ROOMST)}, then room 1 drawn behind GAME OVER, and round again. The "
        "places the tables are copied to hold leftover source text on the tape, and the "
        "places they are copied from, like the tune itself, become the game's screen "
        "buffers as soon as the first room is drawn: the start-up and the tune can run "
        "only once.</p>",
        f"<p>The tune is two voices on the beeper, each a square wave kept in its own copy "
        f"of the port byte and sent to port $FE in turn, round a loop whose two ways take "
        f"the same 96 T-states so that neither voice's pitch disturbs the other's. Each "
        f"voice has {len(voices[0])} notes, the last {len(voices[0]) - sounding} of them rests "
        f"in both; a note lasts {note_passes} passes of 256 turns of the "
        f"loop, {note_tstates:,} T-states, about {note_tstates / TSTATES:.3f} seconds. Played "
        f"to its end in the simulator with no key pressed, both voices fell silent after "
        f"{tune['notes']} notes and {tune['tstates'] / TSTATES:.1f} seconds (the ROM's "
        "KEY-SCAN between notes adds a little to each), and the routine went on scanning "
        "the keyboard in silence.</p>",

        "<h3>Interrupts are off</h3>",
        f"<p>The tune's routine turns interrupts on as it returns ({R(LOADING_TUNE)}, at "
        f"${TUNE_EI:04X}), and the start-up turns them off three instructions later "
        f"(${START_DI:04X}) -- for good: nothing turns them on again, and the game calls "
        "no ROM routine that would. It has to run that way. The sprites begin at $5B00 and "
        "lie over the ROM's system variables, which the ROM's interrupt routine writes to "
        f"fifty times a second: FRAMES, at ${FRAMES:04X}, is inside the sprite at "
        f"{R(frames_sprite)}, and the keyboard variables from ${KSTATE:04X} inside "
        f"{R(kstate_sprite)}. When this page was built, a second of play in the simulator "
        f"with interrupts offered every frame left the interrupt flip-flop clear and FRAMES "
        f"as it was ({', '.join(f'${b:02X}' for b in trial['frames'])}). "
        f"{krumlinde()} reads the IM 1 in his snapshot as the ROM's routine running fifty "
        "times a second; this disassembly's own earlier notes said the same. Neither is "
        "so.</p>",
        "<p>So nothing paces the game: there is no HALT and no wait for the television's "
        "frame. A pass of the main loop takes as long as its work takes.</p>",

        "<h3>A pass of the main loop</h3>",
        f"<p>{R(ROOMST)} enters a room: it moves the records of the things the knight "
        f"carries up behind his own, draws the room ({R(DRAW_CURRENT_ROOM)}, which also "
        f"makes the records of its objects), copies the bare room to the clean copy, draws "
        f"the doors and still things into it ({R(DRAW_STILL_THINGS)}), copies it again, and "
        f"falls into the main loop, {R(MAIN_LOOP)}, which runs inside it until the game "
        "ends. One pass is:</p>",
        "<ol>"
        "<li>the keys that are not the knight's own: 9 turns the Kempston joystick on or "
        "off; SPACE with SYMBOL SHIFT pauses; SYMBOL SHIFT with 0 ends the game; 6 or 7 "
        "uses the thing in the chosen place; 1 to 5 choose a place. After a room's first "
        "pass its colours are put on here, all at once;</li>"
        f"<li>LIFE printed again if it has changed (START_PASS, the author's ST3);</li>"
        f"<li>the message line: BLOCKED, LOCKED or TOO HEAVY, for ten passes "
        f"({R(SHOW_MESSAGE)});</li>"
        f"<li>every record from the knight's (the seventh) to the last in use, each "
        f"updated by the author's CHE3D ({R(CHE3D)}): the knight's controls, every "
        "creature's move, every fall, every collision and every redraw happen inside "
        "it.</li>"
        "</ol>",
        f"<p>The game returns from {R(ROOMST)} when LIFE reaches 00, or on SYMBOL SHIFT and "
        "0; a door, or the thing that carries the knight off, goes back into it with the "
        "stack as it was. Timed in the simulator when this page was built, "
        f"{TIMING_PASSES} passes in each of a few rooms, standing still and walking, in "
        "T-states:</p>",
        table(["Room", "The knight", "Records in use", "Least", "Mean", "Most",
               "Passes a second"],
              timing_rows),
        f"<p>So the game runs at {TSTATES / max(all_means):.0f} to "
        f"{TSTATES / min(all_means):.0f} passes a second, slower where more is moving. The "
        "slowest passes are the walking ones in which the knight turns round (every sixth "
        "here): turning mirrors all his frames in memory, which costs more than a whole "
        f"pass ({page('SpriteDrawing', 'turning round')}). One "
        f"pass in room {BUSY_ROOM}, traced part by part and record by record, the knight "
        "walking:</p>",
        table(["Part of the pass", "T-states"], part_rows),
        table(["Record", "What", "Sprite", "T-states in CHE3D"], record_rows),
        f"<p>{len(updated)} of the {len(busy['records'])} records took any time: CHE3D "
        "returns at once for doors, invisible boxes and still things, which never move and "
        "are part of the clean copy. A thing lying on the floor is not still -- it can be "
        "pushed, carried or knocked -- and even when it does not move it costs thousands "
        "of T-states a pass: gravity asks it to fall every time, and the step is tested "
        "against every other record before the floor stops it. A creature or the knight "
        "costs its update, its collision tests, and the redraw of its rectangle of screen "
        "with everything that overlaps it.</p>",
        busy_fig,

        "<h3>The object records</h3>",
        f"<p>Everything the game moves, draws or collides with is a record of twenty "
        f"bytes, numbered from 1 at {R(FIXED_RECORDS)}. The first six have no sprite and "
        "are the room itself: its floor, its ceiling and its four walls, huge boxes that "
        "each room's patch code moves into place. The seventh is the knight "
        f"({R(KNIGHT)}); after him come the things he carries, then the room's objects, "
        f"made from the object table and from the room's own drawing ({R(RECORDS)}). The "
        "fields:</p>",
        table(["Offset", "What"], fields),
        f"<p>While a record is being updated, {R(CHE3D)} copies its first 19 bytes to $FFE4 "
        "on, so the code reaches field n as IY+$64+n; the author's leftover source calls "
        "that copy T and the variables V, as in (T+13) and (V+3). The same bytes serve the "
        "room drawing as its points and mode while a room is drawn, and the sprite drawing "
        "as the rectangle it rebuilds: each use sets what it reads first.</p>",

        "<h3>States</h3>",
        f"<p>The low nibble of +14 is an object's state, and {R(CHE3D)} and its "
        f"continuation {R(CREATURE_UPDATE)} are a dispatch on it. Each object type's "
        f"template ({R(TEMPLATES)}) gives the state it starts in; read from the templates "
        "when this page was built:</p>",
        table(["State", "Who", "Handled at", "What it does"], state_rows),
        "<p>Before any state, CHE3D passes over records with no sprite, doors, things "
        "carried or gone, and still things; on a room's first pass it only draws each "
        "object; and an object in the air carries on the way it was going. Every case "
        f"ends in the same place, {R(ANIMATE_AND_MOVE)}: the frame, gravity, the step, "
        "the collisions and the redraw. State 2 is in no template, so the one piece of "
        "code that would set one up never runs. The creatures are on "
        + page("Creatures", "their own page") + ".</p>",

        "<h3>Where everything is</h3>",
        memory_fig,
        table(["From", "To", "Bytes", "What"], outline_rows),
        f"<p>The code is about 7 KB, most of it from {R(SHOW_MESSAGE)} up. Two things "
        "make the map unusual. The start-up moves the level data it needs from where the "
        "tape has it to where the code reads it, and the places it leaves become buffers: "
        f"from the first room on, $C000-$D7FF is the clean copy of the room ({R(RESTOR)}) "
        f"and $D800-$DBFF the four pages the compositor works in ({R(COMPOSITE_TO_SCREEN)}). "
        "And about 9 KB of what the tape loads is not the game at all.</p>",

        "<h3>What else the tape carries</h3>",
        "<p>The tape was saved from the development machine's memory, and much of that "
        "memory was the tools' rather than the game's. Pieces of the game's own source "
        "text lie in the gaps between the game's bytes, and where the start-up copies "
        "tables over them. Each line is a carriage return, a two-byte line number and the "
        "text; read by their line numbers only:</p>",
        table(["From", "To", "Lines", "Line numbers"], run_rows),
        f"<p>(and {master[0]} more lines, {master[1]}-{master[2]}, at {R(MASTER_OBJECTS)} "
        "on the tape, before the start-up copies the master copy over them). The lines "
        "near the object table are its own DEFB lines; others are the source of the "
        "pick-up, the key reading, the room's set-up and the use of a carried thing, "
        "which is how many of the author's labels are known -- matched instruction for "
        "instruction to the code they became. They also give his two variable bases, V "
        "for $FF80 and T for $FFE4.</p>",
        f"<p>Part of the assembler's symbol table survives too ({R(SYMBOL_TABLE)}): "
        f"{len(nodes)} whole symbols, each a node of a tree with a name and a value, "
        f"and the value of every one an instruction of this very release's code. "
        f"{len(routine_names)} of them name the first instruction of a routine in this "
        "listing, and the listing uses his names for those: "
        + ", ".join(R(value, name) for value, name in sorted(routine_names))
        + ". The rest name places inside routines, and are kept as their labels. The "
        "title routine's own name is lost but for its last letter: the loader's bytes "
        "cut the first node short.</p>",

        "<h3>Beside Krumlinde's reading</h3>",
        f"<p>{krumlinde()} came first, and many facts and some names here are his. It was "
        "made from a snapshot taken in play, with the start-up long gone, which is why "
        "his entry point and his stack are reconstructions; this listing starts from the "
        f"tape, at {R(START)}. Where this page differs from his: interrupts are off, not "
        f"on; the six records at {R(FIXED_RECORDS)} are the room's box, not spare records; "
        f"{R(SAVE_OBJECT_POSITIONS)} copies the records' places into the object table, "
        "not the other way; and the compositor reads all four of its pages "
        f"({page('SpriteDrawing', 'how a moving object is drawn')}).</p>",

        "<h3>Confirmed and inferred</h3>",
        "<ul>"
        "<li>Run in the simulator when this page was built: the tune to its end; a second "
        "of play with interrupts offered; the passes timed; one pass traced record by "
        "record.</li>"
        "<li>Read from the game when this page was built: the loader's return address, the "
        "start-up's copies, the tune's notes, the states in the templates, the symbol "
        "table's names, the source text's line numbers.</li>"
        "<li>Read from the code: the order of a pass, the record fields, the loader's "
        "steps (and checked by the build against the tape every time).</li>"
        "<li>Inferred: that the interrupts are off because of the sprites under the "
        "system variables. Nothing says so, but nothing else would work.</li>"
        "</ul>",
        "</div>"])


# --------------------------------------------------------------------------
# Every room, entered once: shared by the pages.
# --------------------------------------------------------------------------

_CENSUS: dict = {}


def census(snapshot: Path) -> dict:
    """Every room from 2 to 80 but the title's (79), entered the way a new
    game enters its first, and every record in it read at the start of its
    first pass: {room: {"count": OBJECT_COUNT, "records": [(number, 20
    bytes)], "fixed": [20 bytes x 6]}}. Rooms 1 and 81 are GAME OVER's
    backdrop and the end of the quest, which the knight never plays in."""
    key = str(snapshot)
    if key in _CENSUS:
        return _CENSUS[key]
    game = Game(snapshot)
    out = {}
    for room in range(2, 81):
        if room == 79:
            continue
        game.enter(room)
        memory = game.memory
        out[room] = {
            "count": memory[OBJECT_COUNT],
            "records": [(n, bytes(memory[record(n):record(n) + RECORD]))
                        for n in range(KNIGHT_NUMBER + 1, memory[OBJECT_COUNT] + 1)],
            "fixed": [bytes(memory[record(n):record(n) + RECORD]) for n in range(1, 7)],
        }
    _CENSUS[key] = out
    return out


# --------------------------------------------------------------------------
# 2. How a room is drawn.
# --------------------------------------------------------------------------

STAGE_ROOM = 29             # the room a new game starts in
OUTLINE_ROOM = 2            # the invisible outline ($E4 $00 ... $E4 $01)
FLIP_ROOM = 26              # the one room that flips pixels ($CD)


def command_trace(snapshot: Path, room: int, stops: set[int] | None = None,
                  patch: dict | None = None, game: Game | None = None) -> dict:
    """A room drawn by the game's own interpreter, stopped before every
    command it carries out (RUN_ROOM_COMMANDS, at the CALL of DO_ROOM_COMMAND)
    to note the command's address, and at the end of the drawing. Before
    each command whose address is in `stops` the screen and the clean copy
    are kept. `patch` is written into memory first (a command changed, to see
    what it does). A `game` given is carried on with (from wherever it is),
    rather than a new one started."""
    memory0 = bf.game_memory(snapshot)
    expected = [w for w in walk_room(memory0, room=room) if w[2] != "End"]
    game = game or Game(snapshot)
    for address, value in (patch or {}).items():
        game.memory[address] = value
    game.enter_to(room, CARRY_OUT)
    seen, pictures, marked = [], {}, []
    for index in range(len(expected)):
        if index:
            game.run_to(CARRY_OUT)
        address = game.ix()
        seen.append(address)
        marked.append(pixels_set(bytes(game.memory[CLEAN_COPY:CLEAN_COPY + 0x1800])))
        if stops and address in stops and address not in pictures:
            pictures[address] = (bytes(game.memory[0x4000:0x5800]),
                                 bytes(game.memory[CLEAN_COPY:CLEAN_COPY + 0x1800]))
    game.run_to(ROOM_DRAWN)
    marked.append(pixels_set(bytes(game.memory[CLEAN_COPY:CLEAN_COPY + 0x1800])))
    # What each fill command added to the clean copy.
    filled = sum(marked[i + 1] - marked[i] for i, w in enumerate(expected)
                 if w[2].startswith("Fill"))
    return {"seen": seen, "expected": [w[0] for w in expected], "pictures": pictures,
            "filled": filled, "fills": sum(1 for w in expected if w[2].startswith("Fill")),
            "end": (bytes(game.memory[0x4000:0x5800]),
                    bytes(game.memory[CLEAN_COPY:CLEAN_COPY + 0x1800])),
            "colour": game.memory[ROOM_COLOUR], "game": game}


def _as_memory(screen: bytes, clean: bytes | None = None):
    """A 64 KB list holding a screen (and a clean copy) where the picture
    functions look for them."""
    memory = [0] * 0x10000
    memory[0x4000:0x4000 + len(screen)] = screen
    if clean is not None:
        memory[CLEAN_COPY:CLEAN_COPY + len(clean)] = clean
    return memory


def pixels_set(data: bytes) -> int:
    return bin(int.from_bytes(data, "big")).count("1")


def pixels_differing(one: bytes, two: bytes) -> int:
    return sum(bin(a ^ b).count("1") for a, b in zip(one, two))


def fill_counts(snapshot: Path, room: int) -> dict:
    """How the room's fills went: the pixels marked one at a time (at
    $E7C5), the bytes marked eight at once ($E825, #R$E806), and the runs
    taken off the stack ($E73D) -- each counted by running from stop to stop
    in a fresh drawing of the room until the drawing is done -- and the
    pixels set in the clean copy by the fills."""
    game = Game(snapshot)
    game.enter_to(room, ROOM_DRAWN)
    end = game.tstates
    out = {}
    for name, stop in (("pixels", FILL_PIXEL_MARKED), ("bytes", FILL_BYTE_MARKED),
                       ("runs", FILL_SEED)):
        game = Game(snapshot)
        game.enter_to(room, CARRY_OUT)
        count = 0
        while game.run_to(stop, 3.0, required=False) and game.tstates < end:
            count += 1
        out[name] = count
    return out


def texture_cells(memory, index: int, scale: int = 8):
    """A texture's 32 bytes as its four 8 by 8 cells, apart, each in the
    order the fill reads it: bytes 0-7 and 8-15 on the top row (the character
    rows in which y, counted from the bottom, has bit 3 set), 16-23 and 24-31
    below; each cell's first byte its top row. Black ink on white paper, as
    fairlight_data.texture_image draws the texture laid."""
    from PIL import Image, ImageDraw

    cell = 8 * scale
    gap = 10
    image = Image.new("RGB", (2 * cell + gap, 2 * cell + gap), BACKGROUND)
    pixels = image.load()
    base = TEXTURES + 32 * index
    for half in range(2):
        for side in range(2):
            for row in range(8):
                bits = memory[base + 16 * half + 8 * side + row]
                for bit in range(8):
                    colour = INK if bits & (0x80 >> bit) else PAPER
                    x0 = side * (cell + gap) + bit * scale
                    y0 = half * (cell + gap) + row * scale
                    for dy in range(scale):
                        for dx in range(scale):
                            pixels[x0 + dx, y0 + dy] = colour
    draw = ImageDraw.Draw(image)
    for half in range(2):
        for side in range(2):
            first = 16 * half + 8 * side
            label_at = (side * (cell + gap) + 2, half * (cell + gap) + 2)
            box = draw.textbbox(label_at, f"{first}-{first + 7}")
            draw.rectangle([box[0] - 1, box[1] - 1, box[2] + 1, box[3] + 1], fill=(0, 0, 0))
            draw.text(label_at, f"{first}-{first + 7}", fill=(255, 255, 80))
    return image


def _room_drawing_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    R = listing.r
    memory = bf.game_memory(snapshot)

    log("  every room's commands, and every room drawn...")
    code_counts: dict[str, list[int]] = {}

    def count(key: str, executed: bool):
        entry = code_counts.setdefault(key, [0, 0])
        entry[1 if executed else 0] += 1

    def key_of(address: int, what: str) -> str:
        op = memory[address]
        if what.startswith("Object:"):
            return "object"
        if what.startswith("Patch"):
            return "patch"
        if what.startswith("$E4: nothing"):
            return "$E4 in object mode"
        if op < 0xC0:
            return "point"
        if op >= 0xE6:
            return "fill"
        if op == 0xE4:
            return f"$E4 ${memory[address + 1]:02X}"
        return f"${op:02X}"

    for base, total, first in ((ROOMS, fd.ROOM_COUNT, 3), (PARTS, fd.PART_COUNT, 2)):
        for address, length in fd._stream_records(memory, base, total):
            for at, n, what in fd.room_commands(memory, address + first, address + length):
                if what != "End":
                    count(key_of(at, what), False)
    executed_total = 0
    for room in range(1, fd.ROOM_COUNT + 1):
        for at, n, what, depth in walk_room(memory, room=room):
            if what != "End":
                count(key_of(at, what), True)
                executed_total += 1

    # The interpreter against the listing: every room but GAME OVER's empty
    # one and the end of the quest, drawn by the game, command by command.
    mismatched = []
    checker = Game(snapshot)
    for room in range(2, 81):
        trace = command_trace(snapshot, room, game=checker)
        if trace["seen"] != trace["expected"]:
            mismatched.append(room)
    _check(not mismatched, f"the interpreter and the listing disagree in rooms {mismatched}")
    room_one = fd.room_address(memory, 1)
    _check(len(fd.room_commands(memory, room_one + 3, room_one + _word(memory, room_one)))
           == 1, "room 1 is not empty")
    rooms_census = census(snapshot)

    log("  room 29, stage by stage...")
    top = [(at, what) for at, n, what, depth in walk_room(memory, room=STAGE_ROOM)
           if depth == 0 and what != "End"]

    def first(test, after: int = 0) -> int:
        for index, (at, what) in enumerate(top):
            if index >= after and test(what, memory[at]):
                return index
        raise RuntimeError("no such command in the stage room")

    part_one = first(lambda w, op: w.startswith("Part"))
    after_repeat = first(lambda w, op: op == 0xD6) + 1
    while top[after_repeat][1].startswith("Mode") or top[after_repeat][1].startswith("End of"):
        after_repeat += 1
    clean = first(lambda w, op: op == 0xE2)
    first_fill = first(lambda w, op: op >= 0xE6)
    last_part = first(lambda w, op: w.startswith("Part"), clean)
    objects = first(lambda w, op: w == "Objects follow")
    stage_indexes = [part_one, after_repeat, clean, first_fill + 1, last_part, objects]
    stops = {top[i][0] for i in stage_indexes + [first_fill]}
    trace = command_trace(snapshot, STAGE_ROOM, stops)
    colour = trace["colour"]
    game = trace["game"]
    # Then the room's still things are drawn into it, and on the first pass
    # everything that moves; the colours go on at the start of the second.
    game.run_to(START_PASS)
    still = bytes(game.memory[0x4000:0x5800])
    game.run_to(START_PASS)
    final = screen_image(game.memory)
    executed_here = len(trace["seen"])
    top_count = len(top)

    door_part = memory[top[first(lambda w, op: w.startswith("Part"), after_repeat)][0] + 1]
    captions = [
        f"the outline: {part_one} commands, points joined by lines",
        f"part {memory[top[part_one][0] + 1]}, and a repeat of relative points",
        f"part {door_part}, a door, drawn twice, the second time mirrored (mode bit 6)",
        "$E2 kept a clean copy; the first fill",
        "the rest of the fills",
        f"part {memory[top[last_part][0] + 1]}: the panel",
    ]
    stage_images = []
    for number, index in enumerate(stage_indexes, 1):
        screen_bytes = trace["pictures"][top[index][0]][0]
        stage_images.append(label(screen_image(_as_memory(screen_bytes), colour),
                                  str(number)))
    stage_images.append(label(screen_image(_as_memory(still), colour), "7"))
    stage_images.append(label(final.copy(), "8"))
    stages_fig = figure(pictures.piece("rooms_stages.png", grid(stage_images, 2),
                                       f"Room {STAGE_ROOM}, stage by stage"),
                        f"Room {STAGE_ROOM} drawn by the game's own interpreter, stopped "
                        "along the way: " + "; ".join(f"{n}, {c}" for n, c in
                                                     enumerate(captions, 1))
                        + "; 7, the room's drawing done and its doors and still things drawn "
                        "into it, at the start of the first pass; 8, at the start of the "
                        "second, everything that moves drawn by the first and the room "
                        "coloured. Until then the attributes are black on black, and the "
                        "pictures before 8 are shown in the room's colour.")
    fill_screen, fill_clean = trace["pictures"][top[first_fill + 1][0]]
    map_fig = figure(pictures.piece(
        "rooms_fill_map.png",
        strip([screen_image(_as_memory(fill_screen), colour),
               map_image(_as_memory(fill_screen, fill_clean))], gap=8),
        "The screen and the clean copy after the first fill"),
        f"After the first fill of room {STAGE_ROOM}: the screen (left), in the room's "
        "colours, and the clean copy at $C000 (right), which the fill works against, in "
        "this page's own colours -- a set pixel orange on dark blue -- since it has none. "
        "$E2 copied the outline there; the fill marked every pixel it painted, so the "
        "painted area is solid in the copy while on the screen it has the texture.")

    log("  the fills, counted...")
    fills = fill_counts(snapshot, STAGE_ROOM)
    filled = fills["pixels"] + 8 * fills["bytes"]
    _check(trace["filled"] == filled,
           f"the fills marked {filled} pixels, and the clean copy gained {trace['filled']}")
    fill_codes = sorted({memory[at] for at, _, what, _ in
                         [c for r in range(1, fd.ROOM_COUNT + 1)
                          for c in walk_room(memory, room=r)] if what.startswith("Fill")})

    log("  room 2's invisible outline...")
    outline_top = [(at, what) for at, n, what, depth in walk_room(memory, room=OUTLINE_ROOM)
                   if depth == 0 and what != "End"]
    to_map = next(at for at, what in outline_top if what.startswith("$E4 $00"))
    to_screen = next(at for at, what in outline_top if what.startswith("$E4 $01"))
    outline_fill = next(at for at, what in outline_top if at > to_map
                        and what.startswith("Fill"))
    outline = command_trace(snapshot, OUTLINE_ROOM, {to_map, outline_fill, to_screen})
    colour2 = outline["colour"]
    before_screen, _ = outline["pictures"][to_map]
    lines_screen, lines_clean = outline["pictures"][outline_fill]
    after_screen, after_clean = outline["pictures"][to_screen]
    _check(before_screen == lines_screen, "the invisible outline changed the screen")
    outline_fig = figure(pictures.piece(
        "rooms_invisible_outline.png",
        strip([screen_image(_as_memory(lines_screen), colour2),
               map_image(_as_memory(lines_screen, lines_clean)),
               screen_image(_as_memory(after_screen), colour2)], gap=8),
        "Room 2's invisible outline"),
        f"Room {OUTLINE_ROOM}: the screen when $E4 $00 has cleared the clean copy and "
        "the outline has been drawn into it (left: the screen has not changed); the clean "
        "copy then (middle: only the outline, orange on dark blue as above); and the "
        "screen after the fill inside it "
        "(right), which lays a second texture over part of a wall that is textured "
        "already.")
    no_outline = command_trace(snapshot, OUTLINE_ROOM,
                               patch={to_map + 1: 2, to_screen + 1: 2})
    outline_pixels = pixels_differing(outline["end"][0], no_outline["end"][0])
    _check(outline_pixels > 0, "room 2 draws the same without its $E4 $00")

    log("  room 26's flipped line...")
    flip_at = next(at for at, n, what, depth in walk_room(memory, room=FLIP_ROOM)
                   if memory[at] == 0xCD)
    flipped = command_trace(snapshot, FLIP_ROOM)
    unflipped = command_trace(snapshot, FLIP_ROOM, patch={flip_at: 0xD1})
    flip_pixels = pixels_differing(flipped["end"][0], unflipped["end"][0])
    _check(flip_pixels > 0, "room 26 draws the same without its $CD")

    log("  textures, patches, templates...")
    texture_fig = figure(pictures.piece("rooms_texture.png", strip([
        texture_cells(memory, 6, 8), big(fd.texture_image(memory, 6, 1), 5)], gap=16),
        "Texture 6: its four cells, and as the fill lays it"),
        "Texture 6 (fill code $EC, #R$E164): its 32 bytes as the four cells the fill "
        "reads, labelled with their bytes (left), and laid as the fill lays it, two tiles "
        "each way (right), black ink on white paper. Its bricks are 16 pixels long, which is what the left and "
        "right cells are for; its top and bottom pairs happen to be the same.")
    _check(0xE6 + 22 not in fill_codes and 0xE6 + 23 not in fill_codes,
           "a room fills with texture 22 or 23")
    letters_fig = figure(pictures.piece("rooms_letters.png", strip([
        texture_cells(memory, 22, 6), texture_cells(memory, 23, 6)], gap=16),
        "Textures 22 and 23"),
        "Textures 22 (#R$E364) and 23 (#R$E384), which no room fills with, drawn the "
        "same way: the Swedish capital and small letters with a ring and with dots, one "
        "cell of each blank.")
    patch_base = fd.tape_address(fd.PATCHES_HOME)
    patch_rooms: dict[int, list[int]] = {}
    for room in range(1, fd.ROOM_COUNT + 1):
        for at, n, what, depth in walk_room(memory, room=room):
            if what.startswith("Patch"):
                patch_rooms.setdefault(memory[at], []).append(room)
    patch_rows = []
    for code in sorted(patch_rooms):
        values = list(memory[patch_base + 6 * (code - fd.PATCH_FIRST):
                             patch_base + 6 * (code - fd.PATCH_FIRST) + 6])
        patch_rows.append([f"${code:02X}"] + [str(v) for v in values]
                          + [_numbers(patch_rooms[code])])
    fixed = rooms_census[STAGE_ROOM]["fixed"]
    stage_patch = [memory[at] for at, _, what, _ in walk_room(memory, room=STAGE_ROOM)
                   if what.startswith("Patch")][0]
    patched = list(memory[patch_base + 6 * (stage_patch - fd.PATCH_FIRST):
                          patch_base + 6 * (stage_patch - fd.PATCH_FIRST) + 6])
    _check([fixed[0][7], fixed[1][7], fixed[2][6], fixed[3][6], fixed[4][8], fixed[5][8]]
           == patched, "room 29's fixed records are not its patch's values")
    most = max(rooms_census.items(), key=lambda item: item[1]["count"])

    # One placed object, worked through: the first thing in the stage room
    # with a sprite whose place is an even step from 50, 50.
    example = None
    for number, fields in rooms_census[STAGE_ROOM]["records"]:
        if fields[19] and (fields[4] or fields[5]):
            entry = things(memory)[fields[19] - 1]
            a, t, b = entry["place"]
            if (a - 50) % 2 == 0 and (b - 50) % 2 == 0:
                example = (number, fields, entry)
                break
    _check(example is not None, "no object to work through in room 29")
    number, fields, entry = example
    kind_template = template(memory, entry["type"])
    tx, ty, height = memory[kind_template], memory[kind_template + 1], memory[kind_template + 7]
    a, t, b = entry["place"]
    x = tx + (a - 50) - (b - 50)
    y = ty + (a - 50) // 2 + (b - 50) // 2 + (t - (50 + height))
    _check((x & 0xFF, y & 0xFF) == (fields[0], fields[1]),
           f"the worked object came out at {fields[0]}, {fields[1]}, not {x}, {y}")

    code_rows = []
    order = [("point", "$00-$BF", "2", "a point: the byte a row (counted up from the bottom), "
              "the next a column; with the mode bits, a line to it"),
             ("$C0", "$C0", "3", "the second point"),
             ("$CF", "$CF", "1", "the second point to the point"),
             ("$D0", "$D0", "1", "the two points swapped"),
             ("$D2", "$D2", "1", "a line from the second point to the point"),
             ("$D5", "$D5", "2", "repeat what follows, up to $D6, n times"),
             ("$D6", "$D6", "1", "the end of the repeat"),
             ("$E0", "$E0", "2", "draw part n, which may change the drawing's state"),
             ("$E1", "$E1", "2", "draw part n, keeping the state"),
             ("$E2", "$E2", "1", "copy the screen into the clean copy"),
             ("$E4 $00", "$E4 $00", "2", "clear the clean copy; lines go into it"),
             ("$E4 $01", "$E4 $01", "2", "lines onto the screen again"),
             ("$E4 $04", "$E4 $04", "2", "object mode: place the object table's things, and "
              "the rest is objects"),
             ("$E4 $05", "$E4 $05", "5", "place the table's things, and move the origin"),
             ("fill", "$E6-$FF", "1", "a textured flood fill from the point"),
             ("object", "(object mode) $00-$E3", "5", "an object: its type, +12 and its "
              "place"),
             ("patch", "(object mode) $E6 up", "1", "a patch: the room's floor, ceiling and "
              "walls")]
    for key, code, length, what in order:
        counts = code_counts.get(key, [0, 0])
        code_rows.append([code, length, what, counts[0], counts[1]])
    mode_counts = sum(v[0] for k, v in code_counts.items()
                      if k.startswith("$C") and k not in ("$C0", "$CF"))
    mode_runs = sum(v[1] for k, v in code_counts.items()
                    if k.startswith("$C") and k not in ("$C0", "$CF"))
    code_rows.insert(2, ["$C1-$CE", "1", "the mode bits on and off (below)", mode_counts,
                         mode_runs])
    unused_modes = [f"${op:02X}" for op in range(0xC1, 0xCF) if f"${op:02X}" not in
                    code_counts]

    mode_rows = [
        ["0", "$CB, $CC", "lines clear pixels instead of setting them"],
        ["1", "$CD, $CE", "lines flip pixels"],
        ["2", "$C3, $C4", "after each point the second point moves to it, so that lines "
         "join up"],
        ["3", "$C5, $C6", "the second point moves along with the first"],
        ["4", "$C1, $C2", "points are relative: added to the point before"],
        ["5", "$C7, $C8", "a line from the second point to each new point"],
        ["6", "$C9, $CA", "columns mirrored: the drawing is flipped left to right"],
        ["7", "$E4 $04", "object mode, to the end of the room or the part"],
    ]

    return "\n".join([
        '<div class="kl-list">',
        f"<p>A room in Fairlight is not stored as a picture. It is a short program for a "
        f"little drawing machine: points, lines between them, textured flood fills, "
        f"shared pieces called parts, and at the end a list of the objects the room holds. "
        f"The game runs it each time the knight walks in. There are {fd.ROOM_COUNT} rooms "
        f"({R(ROOMS)} on) and {fd.PART_COUNT} parts ({R(PARTS)} on), each record a length "
        f"word and its commands, a room's with a colour byte first; drawing every room "
        f"once carries out {executed_total:,} commands. This page follows the drawing "
        f"machine through a room, the start room {STAGE_ROOM}, with pictures taken by "
        "stopping the game's own interpreter along the way.</p>",

        "<h3>The interpreter</h3>",
        f"<p>{R(DRAW_CURRENT_ROOM)} finds the room by walking the table from room 1, each "
        f"record's first word its length; it sets the drawing's variables from "
        f"{R(ROOM_DEFAULTS)} (both points at 50, 50, the origin at 0, no mode bits) and "
        f"calls {R(DRAW_ROOM_RECORD)}. That clears the screen with black ink on black "
        f"paper ({R(CLEAR_ROOM_SCREEN)}), so the room is drawn unseen, keeps the colour "
        f"byte, and carries out the commands one at a time ({R(DO_ROOM_COMMAND)}, and "
        f"{R(MORE_ROOM_COMMANDS)} for the rarer ones) until the $E5 that ends them. A part "
        "is run by the same loop, recursively, so parts can draw parts. The commands, how "
        "many of each the rooms and parts hold, and how many are carried out when every "
        "room is drawn once:</p>",
        table(["Code", "Bytes", "What", "In the data", "Carried out"], code_rows),
        f"<p>Codes $D1, $D3, $D4, $D7-$DF and $E3 match nothing and do nothing. Of the mode "
        f"codes, {', '.join(unused_modes) or 'none'} is in no room or part. The point is "
        "a row and a column with the row counted up from the bottom of the screen, and "
        "rows go round modulo 192. The mode byte (IY+$6B) decides what a point does:</p>",
        table(["Bit", "Codes", "What"], mode_rows),
        "<p>With bits 2 and 5 on, a run of points is a polyline: each point draws a line "
        "from the last and becomes the start of the next. Bit 4 with bit 3 makes a "
        "pattern that can be moved about and repeated; bit 6 lets one part serve for a "
        "left-hand and a right-hand copy of a thing.</p>",

        f"<h3>Room {STAGE_ROOM}, stage by stage</h3>",
        f"<p>Room {STAGE_ROOM}, the room a new game starts in, has {top_count} commands of "
        f"its own; with its parts and its repeat, the interpreter carries out "
        f"{executed_here}. When this page was built the game drew it, stopping before every "
        "command to note which one it was about to carry out: the order was exactly the "
        "one this listing lays out in the room's entry and its parts'. The same was checked "
        "for every room from 2 to 80, the title's included (room 1, GAME OVER's backdrop, "
        "has no commands at all, and 81 is the end of the quest). The screen at a few of "
        "those stops:</p>",
        stages_fig,
        f"<p>The drawing ends with the objects: $E4 $04 turns object mode on, the object "
        f"table's things for the room are placed ({R(PLACE_ROOM_OBJECTS)}), and what "
        f"follows is the room's own list -- a patch code, then objects of its own. Then "
        f"{R(ROOMST)} copies the bare room to the clean copy, and {R(DRAW_STILL_THINGS)} "
        "draws each door and each still object into it and copies it again, so that they "
        "too are part of the background. The first pass of the main loop draws everything "
        f"that moves, and after it {R(ATTRI)} puts the room's colour on all 768 attribute "
        "bytes at once: the room appears complete.</p>",

        "<h3>Lines</h3>",
        f"<p>$D2, and every point while mode bit 5 is on, draws a line from the second "
        f"point to the point, both ends included (DRAW_LINE, in {R(MORE_ROOM_COMMANDS)}). "
        "It is Bresenham's: a step along the longer distance at every pixel, and one along "
        "the shorter whenever the running error passes the longer, with the screen "
        "address stepped a line or a pixel at a time rather than worked out afresh. The "
        f"pen sets the pixel, or clears it (mode bit 0), or flips it (bit 1) "
        f"({R(PLOT_LINE_START)}). Only room {FLIP_ROOM} flips, for its last line, which "
        f"crosses a wall that is textured already: drawn by the game with its $CD turned "
        f"into a code that does nothing, {flip_pixels} pixels of the room came out "
        "different, all along that line.</p>",

        "<h3>The textured fill</h3>",
        f"<p>Codes $E6 to $FF fill the area round the point with one of 26 textures "
        f"({R(TEXTURES)} on, 32 bytes each; {len(fill_codes)} of them are used by some room "
        f"or part). The fill ({R(FILL_NEXT_SEED)}, {R(FILL_NEXT_PIXEL)}) is a span fill "
        "with the machine stack as its list of runs still to do: from a place taken off "
        "the stack it goes right to the end of the run, then paints leftwards a pixel at "
        "a time, and pushes a place in the row above or below whenever a clear run begins "
        "there. What bounds it is not the screen but the clean copy at $C000, 32 KB "
        "above the screen and laid out like it: a pixel set there stops the fill, and "
        "every pixel the fill paints is set there, so nothing is painted twice. The "
        "screen only receives the texture, which replaces whatever was there.</p>",
        map_fig,
        f"<p>Room {STAGE_ROOM}'s drawing runs {trace['fills']} fills, "
        f"{len([1 for at, w in top if w.startswith('Fill')])} of its own and the rest in its "
        f"parts. When this page was built they took {fills['runs']:,} runs off the stack "
        f"and painted {filled:,} pixels -- exactly as many as the clean copy gained -- "
        f"{fills['pixels']:,} of them one at a time and {8 * fills['bytes']:,} eight at a "
        f"time, in {fills['bytes']:,} whole bytes. The whole bytes are "
        f"{R(FILL_WHOLE_BYTE)}'s: when the fill steps into a new byte, and all eight "
        "pixels are clear in the clean copy and the rows above and below are each the same "
        "all along it (clear where a run is open there, set where none is), nothing in the "
        "byte can change the fill's course, so it marks and paints all eight at once. On "
        f"a room's big plain areas that is most of the work: here "
        f"{100 * 8 * fills['bytes'] / filled:.0f}% of the pixels.</p>",
        texture_fig,
        "<p>A texture is a 16 by 16 tile in four 8 by 8 cells. Which cell a pixel takes "
        "depends on the screen, not on the fill: bit 3 of its row picks the top or bottom "
        "pair, bit 3 of its column the left or right cell, and the row within the "
        "character row the byte. So the pattern lines up with the character cells, and "
        "with the colours, whatever the area's shape, and two fills of one texture meet "
        f"without a seam. {krumlinde()} has bytes 0-15 as the rows of even character rows "
        "and byte n as pixel row n; the code (read at $E787-$E7A7) makes bytes 8-15 the "
        "right-hand cell of the same rows, and the bricks drawn that way come out whole. "
        f"Only {len(fill_codes)} of the 26 textures are ever used, and two of the others "
        "are not patterns at all, but letters.</p>",
        letters_fig,

        "<h3>Outlines nobody sees</h3>",
        "<p>$E2 copies the screen into the clean copy, so that what has been drawn so far "
        "bounds the fills that follow. $E4 $00 does something cleverer: it clears the clean "
        "copy and sends the lines that follow into it instead of onto the screen, where "
        "they bound a fill without ever being seen; $E4 $01 sends them back. Room "
        f"{OUTLINE_ROOM} uses the pair to lay a second texture over part of a wall that is "
        "already textured -- which a fill against the ordinary clean copy could not do, "
        "since the wall's own bricks would stop it at once.</p>",
        outline_fig,
        f"<p>Drawn by the game with its $E4 $00 and $E4 $01 turned into $E4 $02, which "
        f"does nothing, room {OUTLINE_ROOM} came out {outline_pixels} pixels different: "
        "the clean copy was never cleared, the fill found its first point already set, "
        "and the panel on the wall is not there. Part 16 does the same.</p>",

        "<h3>Parts, repeats and origins</h3>",
        "<p>$E0 n and $E1 n draw part n in the middle of the room's commands and come "
        "back. $E1 saves the drawing's state -- both points, the mode, the repeat and the "
        "origin -- and puts it back afterwards; $E0 lets the part change it. Either way "
        "object mode ends with the part. $D5 n repeats what follows up to the $D6 n times; "
        "there is one repeat count, so repeats do not nest. $E4 $05 moves the origin that "
        "object mode adds to every object it places: room 17 repeats a part four times, "
        "moving the origin each time, and so puts down four pairs of objects in a row. "
        "Both $E4 $04 and $E4 $05 first place the object table's things, once in each "
        "drawing (bit 0 of IY+$3C), with the origin still at 0.</p>",

        "<h3>The room's box: patches</h3>",
        f"<p>Records 1 to 6 ({R(FIXED_RECORDS)}) are the room's floor, ceiling and four "
        "walls for the collision code: huge boxes with no sprite. A patch code in the "
        f"room's object list ({R(DO_ROOM_COMMAND, 'PATCH_RECORDS')}) sets them from the "
        f"table of patches ({R(PATCHES)}): the floor's top, the ceiling's, the two walls "
        f"across +6 and the two across +8. Every room the knight plays in has one, in its "
        "own list or a part's; the codes in use:</p>",
        table(["Code", "Floor's top", "Ceiling's top", "Record 3's +6", "Record 4's +6",
               "Record 5's +8", "Record 6's +8", "Rooms"], patch_rows),
        f"<p>So nearly every floor is at 50, the height the knight's feet are at when he "
        f"stands on it. Room {STAGE_ROOM}'s is patch ${stage_patch:02X}, and its six records, "
        "read in the running game, hold exactly those values. The two rooms with a floor "
        "at 10 are the rooms with pits. None of this is drawn: what the knight bumps into "
        "is these boxes, and the boxes the room's objects make, never the lines of the "
        f"picture. How they are used is on {page('Movement', 'the movement page')}.</p>",

        "<h3>Placing objects</h3>",
        f"<p>{R(PLACE_ROOM_OBJECTS)} walks the whole object table ({R(OBJECTS)}) for "
        f"entries in this room, and {R(PLACE_OBJECT)} makes each one's record at the next "
        f"free one: from its type's template ({R(TEMPLATES)}) the sprite, where the sprite "
        "goes on the screen, its sizes, its starting state and its weight; from the entry "
        "its kind and its place. A thing gets its number in the table at +19, so that its "
        "room can be written back when it is carried off. The room's own objects, after "
        "$E4 $04, are made the same way from five bytes each.</p>",
        f"<p>A template's screen place is right for an object standing at 50, 50 on a "
        f"floor at 50 -- its top at 50 plus its height -- so the record is first put "
        f"there and {R(ISO_MOVE)} moves it "
        "to the place asked for, moving the sprite with it: a step along +6 is a pixel "
        "right and half a row up, along +8 a pixel left and half a row up, and up +7 a "
        f"row up. Worked through for record {number} of room {STAGE_ROOM}, the object "
        f"table's thing {entry['number']} (type {entry['type']}, at {a}, {t}, {b}): its "
        f"template puts the sprite at x {tx}, y {ty}; the move adds {a - 50} along +6, "
        f"{b - 50} along +8 and {t - 50 - height} in height, so x {tx} + {a - 50} - "
        f"{b - 50} = {x} and y {ty} + {(a - 50) // 2} + {(b - 50) // 2} + "
        f"{t - 50 - height} = {y} -- where the game put it.</p>",
        f"<p>The most records a room makes is {most[1]['count']} (room {most[0]}), the six "
        f"fixed ones and the knight's among them; the area from {R(RECORDS)} holds 43.</p>",

        "<h3>Beside Krumlinde's reading</h3>",
        f"<p>{krumlinde()} has the interpreter's structure and most of its names right. "
        "Where this page differs: the texture format (above); his \"solid\" texture $E8 "
        "is vertical stripes; $E0 is not a jump but a call, and rooms go on drawing after "
        "it; the bytes after $E4 $05 are the objects' origin; and the patch codes set six "
        "bytes of the room's own box records, not a shared byte of the object table's "
        "records.</p>",

        "<h3>Confirmed and inferred</h3>",
        "<ul>"
        f"<li>Run in the simulator when this page was built: the drawing of every room from 2 "
        f"to 80 command by command against the listing; the stages "
        f"of room {STAGE_ROOM}; the fills counted; room {OUTLINE_ROOM} without its outline "
        f"commands and room {FLIP_ROOM} without its flip; room {STAGE_ROOM}'s box; the "
        "worked object; every room entered for its record count.</li>"
        "<li>Read from the game when this page was built: the command counts, the patches, "
        "the templates.</li>"
        "<li>Read from the code: what each command does.</li>"
        f"<li>Inferred: why room {FLIP_ROOM} flips its last line (so that it shows over both "
        "colours of the texture it crosses).</li>"
        "</ul>",
        "</div>"])


# --------------------------------------------------------------------------
# 3. How a moving object is drawn.
# --------------------------------------------------------------------------

FRAME_ROOM = 2              # the knight beside the troll
# The pages' labels in the pictures, a colour each (the page's, not the game's).
PAGE_COLOURS = {0xD8: (240, 120, 60), 0xD9: (90, 200, 250), 0xDA: (200, 120, 240),
                0xDB: (240, 230, 120)}


def troll_record(memory) -> int:
    for number in range(KNIGHT_NUMBER + 1, memory[OBJECT_COUNT] + 1):
        if memory[record(number) + 14] & 15 == 7:
            return number
    raise RuntimeError("no troll in the room")


def frame_capture(snapshot: Path, d6: int, d8: int) -> dict:
    """The knight's redraw beside the troll in room 2, stopped where
    #R$ECBD hands the region to the compositor: the four pages, the region,
    the draw list, the screen and the clean copy there, and the screen after
    the compositor. The creatures are frozen first (bit 7 of GAME_FLAGS, as
    the type-5 thing does), and the knight's +6 and +8 are put `d6`, `d8`
    from the troll's at the start of a pass; LIFE is topped up."""
    game = Game(snapshot)
    game.enter(FRAME_ROOM)
    memory = game.memory
    troll = record(troll_record(memory))
    memory[GAME_FLAGS] |= 0x80
    game.passes(3)
    memory[KNIGHT + 6] = (memory[troll + 6] + d6) & 0xFF
    memory[KNIGHT + 8] = (memory[troll + 8] + d8) & 0xFF
    game.passes(2)
    for _ in range(200):
        bf._alive(memory)
        game.run_to(REDRAW_TO_SCREEN)
        if memory[THIS_RECORD] == KNIGHT_NUMBER:
            break
    else:
        raise RuntimeError("the knight was never redrawn")
    region = {"x": memory[REGION_X], "y": memory[REGION_Y], "w": memory[REGION_W],
              "h": memory[REGION_H], "bytes": memory[DRAW_WIDTH], "flags": memory[LIST_FLAGS]}
    pages = {page: bytes(memory[page << 8:(page << 8) + 256]) for page in PAGE_COLOURS}
    last = memory[LIST_LAST]
    listed = [] if last == 0xFF else list(memory[DRAW_LIST:DRAW_LIST + last + 1])
    before = bytes(memory[0x4000:0x5800])
    clean = bytes(memory[CLEAN_COPY:CLEAN_COPY + 0x1800])
    sp = game.reg("SP")
    game.run_to(_word(memory, sp))
    after = bytes(memory[0x4000:0x5800])
    return {"region": region, "pages": pages, "listed": listed, "before": before,
            "after": after, "clean": clean, "colour": memory[ROOM_COLOUR],
            "troll": troll_record(memory),
            "knight": tuple(memory[KNIGHT + 6:KNIGHT + 9]),
            "troll at": tuple(memory[troll + 6:troll + 9])}


def attribute_colours(attr: int) -> tuple:
    """The ink and the paper an attribute gives, BRIGHT if it says so; black
    on white where they are one colour (see screen_image)."""
    palette = SPECTRUM_BRIGHT if attr & 0x40 else SPECTRUM
    ink, paper = palette[attr & 7], palette[(attr >> 3) & 7]
    return (INK, PAPER) if ink == paper else (ink, paper)


def page_image(data: bytes, region: dict, colour: int, scale: int = 3):
    """A compositor page as the region's rows: the region's width in bytes
    and one more, as many rows as it is high, wrapping within the page. A
    page has no colours of its own; it is drawn in `colour`, the attribute
    of the room it was made in, a set bit as ink."""
    from PIL import Image

    ink, paper = attribute_colours(colour)
    stride = region["bytes"] + 1
    rows = region["h"]
    image = Image.new("RGB", (stride * 8, rows), paper)
    pixels = image.load()
    for row in range(rows):
        for column in range(stride):
            byte = data[(row * stride + column) & 0xFF]
            for bit in range(8):
                if byte & (0x80 >> bit):
                    pixels[column * 8 + bit, row] = ink
    return big(image, scale)


def region_image(screen: bytes, region: dict, colour: int, scale: int = 3):
    """The rectangle of the screen (or the clean copy) the compositor rebuilds:
    from the byte x is in, the width in bytes and one more, from the top row
    down as many rows as the region is high; in `colour`, the attribute of
    the room it shows."""
    from PIL import Image

    ink, paper = attribute_colours(colour)
    stride = region["bytes"] + 1
    rows = region["h"]
    image = Image.new("RGB", (stride * 8, rows), paper)
    pixels = image.load()
    for row in range(rows):
        y = 191 - region["y"] + row
        if not 0 <= y < 192:
            continue
        address = _row_address(y) - 0x4000 + (region["x"] >> 3)
        for column in range(stride):
            if (region["x"] >> 3) + column > 31:
                break
            byte = screen[address + column]
            for bit in range(8):
                if byte & (0x80 >> bit):
                    pixels[column * 8 + bit, row] = ink
    return big(image, scale)


def mirror_trial(snapshot: Path) -> dict:
    """The knight turned from walking down +6 (H, his frames mirrored) to
    walking down +8 (A, as drawn) in room 29: his first walking frame's bytes
    before and after, and the T-states the turn's mirroring took."""
    game = Game(snapshot)
    memory = game.memory
    out = {}
    for key in ("a", "h"):
        game.passes(3, (key,))
        out[key] = (bytes(memory[0x9110:0x9110 + 2 * 3 * 31]), memory[KNIGHT + 14])
    # Once more the other way, timing MIMAN's call; then the next pass's
    # call, which finds them the right way round already.
    game.passes(1)
    for name in ("tstates", "no turn"):
        game.run_to(MIMAN, 5.0, ("a",))
        back = _word(memory, game.reg("SP"))
        start = game.tstates
        game.run_to(back, 5.0, ("a",))
        out[name] = game.tstates - start
    return out


def _sprite_drawing_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    R = listing.r

    log("  the knight and the troll, both ways round...")
    # Their boxes must not touch: frozen, the troll keeps the "hurts at a touch"
    # bit its own case would have cleared, and a mover that hurts vanishes when
    # it touches something (#R$F959).
    behind = frame_capture(snapshot, 0, -16)       # the knight nearer: the troll behind
    front = frame_capture(snapshot, 16, 0)         # the knight farther: the troll in front
    troll_number = behind["troll"]
    _check(troll_number in behind["listed"] and behind["region"]["flags"] & 2,
           "with the knight nearer, the troll is not on the list behind him")
    _check(any(front["pages"][0xD8]) and troll_number not in front["listed"],
           "with the knight farther, the troll's cover is not in page $D8")
    _check(not any(behind["pages"][0xD8]), "something is in front of the knight")

    def row(capture, name: str) -> str:
        from PIL import ImageDraw

        region = capture["region"]
        colour = capture["colour"]
        # The screen round the rectangle, the rectangle outlined; everything
        # in the room's colours, the pages too, which have none of their own
        # (a set bit ink). Each page's label is in a colour of its own.
        left = max(0, min(256 - 104, (region["x"] & 0xF8) - 36))
        top = max(0, min(192 - region["h"] - 40, 191 - region["y"] - 20))
        context = screen_image(_as_memory(capture["after"]), colour).crop(
            (left, top, left + 104, top + region["h"] + 40))
        context = big(context, 3)
        draw = ImageDraw.Draw(context)
        x0 = ((region["x"] & 0xF8) - left) * 3
        y0 = (191 - region["y"] - top) * 3
        draw.rectangle([x0 - 1, y0 - 1, x0 + (region["bytes"] + 1) * 24,
                        y0 + region["h"] * 3], outline=(255, 60, 60))
        images = [context]
        images.append(label(region_image(capture["before"], region, colour), "before"))
        images.append(label(region_image(capture["clean"], region, colour), "clean"))
        for number in PAGE_COLOURS:
            images.append(label(page_image(capture["pages"][number], region, colour),
                                f"${number:02X}", PAGE_COLOURS[number]))
        images.append(label(region_image(capture["after"], region, colour), "after"))
        return pictures.piece(name, strip(images, gap=8), "The knight's redraw")

    behind_img = row(behind, "sprites_behind.png")
    front_img = row(front, "sprites_front.png")

    def listed(capture) -> str:
        if not capture["listed"]:
            return "empty"
        return ", ".join(str(n) for n in capture["listed"])

    log("  turning round...")
    turn = mirror_trial(snapshot)
    _check(turn["a"][0] != turn["h"][0] and (turn["a"][1] ^ turn["h"][1]) & 0x20,
           "the knight's frame did not change when he turned")
    frames = []
    for key in ("a", "h"):
        mem = _as_memory(b"")
        mem[0x9110:0x9110 + len(turn[key][0])] = turn[key][0]
        frames.append(big(sprite_of(mem, 0x9110, 24, 31), 3))
    turn_fig = figure(pictures.piece("sprites_mirror.png", strip(frames, gap=16),
                                     "The knight's first walking frame, both ways"),
                      "The bytes of the knight's first walking frame (#R$9110) in memory, "
                      "walking down +8 (A, left) and then down +6 (H, right): the same "
                      "bytes, turned end for end in place.")

    region = behind["region"]
    return "\n".join([
        '<div class="kl-list">',
        "<p>Fairlight never redraws the screen as a whole once a room is up. When "
        "something moves, the game rebuilds only the rectangle of screen its sprite "
        "covers, straight onto the screen, from the clean copy of the room and four "
        "256-byte pages of working memory. What the pages hold decides what is in front "
        "of what. This page follows one such redraw in a real room, through the game's "
        "own code, once with another object behind the one redrawn and once with it in "
        "front.</p>",

        "<h3>The chain</h3>",
        f"<p>Every object's update ends in {R(REDRAW_OBJECT)}, the author's SRP, with its "
        "record. It copies the record's first twelve bytes to $FFE4 on -- the sprite's "
        "place, size and image -- and works on the rectangle they give, made three rows "
        "taller at the top and at the bottom, in five steps:</p>",
        "<ol>"
        f"<li>page $D8 is cleared, and the object's mask is drawn into page $D9 "
        f"({R(DRAW_SPRITE)}, mode $80); an object carried off or gone instead fills page $D9 "
        "so that the clean copy shows through where it was;</li>"
        f"<li>every other record from the knight's on goes to {R(CULL_OBJECT)}: one whose "
        "sprite misses the rectangle is left out; one that overlaps it and stands in front "
        f"of the object ({R(IS_IN_FRONT)}) has its cover drawn at once into page $D8 (mode "
        "0); one behind goes on a list at page $DA;</li>"
        f"<li>if anything on the list needs drawing, {R(SORT_AND_DRAW_BEHIND)} sorts it "
        "and draws it, back to front, into pages $DA (where they cover) and $DB (what they "
        "show) -- modes 4 and 8;</li>"
        f"<li>{R(COMPOSITE_TO_SCREEN)} makes each screen byte of the rectangle from the "
        "pages, the clean copy and the object's own image.</li>"
        "</ol>",
        "<p>The compositor's rule, for each byte:</p>",
        "<ul>"
        "<li>where page $D9 is clear, the object's image; where it is set, the clean copy "
        "(the screen byte's address with bit 7 set, 32 KB up);</li>"
        "<li>and where page $D9 is set and page $DA too, page $DB instead -- something "
        "behind, showing through a transparent part of the object or round it (only when "
        "bit 1 of IY+$71 says the list drew anything: the steps for $DA and $DB are "
        "skipped by rewritten JRs otherwise);</li>"
        "<li>and where page $D8 is set, the screen's own byte, untouched: something in "
        "front covers the object there.</li>"
        "</ul>",
        "<p>So the objects in front are never redrawn at all. The screen already shows "
        "them, and page $D8 simply keeps the compositor's hands off those pixels.</p>",

        "<h3>A real frame</h3>",
        f"<p>Room {FRAME_ROOM}, with the troll frozen where it stood (bit 7 of GAME_FLAGS, "
        "which the type-5 thing sets) and the knight put beside it: when this page was "
        "built the game was stopped where the knight's redraw hands the rectangle to the "
        f"compositor ({R(REDRAW_OBJECT)}, at $ED44), and the pages read out, each as rows of "
        f"the rectangle's width in bytes and one more ({region['bytes'] + 1} bytes by "
        f"{region['h']} rows here). First the knight nearer the viewer, at "
        f"{', '.join(map(str, behind['knight']))} with the troll at "
        f"{', '.join(map(str, behind['troll at']))} -- 16 less along +8, their boxes apart "
        "but their sprites overlapping:</p>",
        figure(behind_img,
               "The knight in front of the troll. From the left: the screen afterwards, "
               "with the rectangle outlined in red; the rectangle on the screen before; the "
               "clean copy there; page $D8, empty, for nothing "
               "stands in front of him; page $D9, his mask with three rows of nothing above "
               "and below; page $DA, the cover of what is behind him; page $DB, what that "
               "shows; and the screen after the compositor. All are in the room's colours, "
               "black ink on its paper; the clean copy and the pages have no colours of "
               "their own, and a bit set in them is shown as ink."),
        f"<p>The list at page $DA held records {listed(behind)} -- the troll is record "
        f"{troll_number}, and record {[n for n in behind['listed'] if n != troll_number][0]} "
        "one of the things stacked by the wall -- and page $DB what they show. Then "
        f"the knight farther off, at {', '.join(map(str, front['knight']))}, 16 more along "
        "+6 than the troll:</p>",
        figure(front_img,
               "The troll in front of the knight: now page $D8 holds the troll's cover, so "
               "the screen keeps the troll where it overlaps him, and the troll is not on "
               f"the list, which held only record {listed(front)}, one of the things stacked "
               "by the wall behind him."),
        f"<p>Depth comes from {R(IS_IN_FRONT)}: an object stands in front of another "
        "unless it lies wholly beyond it along some axis -- its +6 at or past the other's "
        f"far edge along +6 ({R(FAR_CORNER)} works out +6 plus +9), its top at or below "
        "the other's floor, or its +8 at or past the other's far edge along +8. Greater "
        "+6 and +8 are farther from the viewer. It is asked only of objects whose sprites "
        "overlap, and one answer is enough to order two of them.</p>",

        "<h3>Sorting what is behind</h3>",
        f"<p>{R(SORT_AND_DRAW_BEHIND)} sorts the list so that each object is drawn before "
        "anything in front of it. An isometric scene has no single depth to sort by, so "
        "it works by moving: for each place in turn, if any later entry stands in front "
        "of the one there, that one is taken out, the rest close up, it goes on the end, "
        "and the place is looked at again. Three objects can each stand in front of the "
        "next, and then this would go round for ever; fifty moves at each place (IY+$7E) "
        "is the limit. The list -- record numbers, thirty bytes at most -- is copied up to "
        "$FFC6 before pages $DA and $DB are cleared, and drawn from its end back: each "
        "object's cover ORed into $DA and cleared out of $DB, then its image ORed into "
        "$DB.</p>",
        "<p>Still things -- doors, and objects that never move -- are on the list too, "
        "but are already in the clean copy, so behind the redrawn object they are skipped "
        "until the first live object in the drawing order: from there on they are drawn "
        "as well, since they may cover it. As a room is entered the same machinery draws "
        f"the still things into the picture ({R(DRAW_STILL_THINGS)}, with bit 4 of "
        "GAME_FLAGS set), leaving the live ones out.</p>",

        "<h3>Drawing a sprite</h3>",
        f"<p>{R(DRAW_SPRITE)} is the one routine that draws objects, and it never touches "
        "the screen: it draws into a page, laid out as the rectangle, clipped to it and "
        "shifted to the pixel. A sprite is its image and then its mask, each its width in "
        "bytes by its height in rows. The mode says what goes where:</p>",
        table(["Mode", "For", "Into", "What"], [
            ["$80", "the object redrawn", "$D9", "its mask, with three rows of nothing "
             "covered above and below"],
            ["0", "an object in front", "$D8", "its cover: the mask inverted, a bit set "
             "where it shows"],
            ["4", "an object behind", "$DA (and $DB)", "its cover, ORed in, and cleared out "
             "of $DB"],
            ["8", "an object behind", "$DB", "its image, ORed in"],
        ]),
        f"<p>The shift is done by jumping into a run of seven RRCAs: before each sprite "
        f"the routine writes 7 less x mod 8 into the displacement of the JR in front of "
        f"them ({R(DRAW_SPRITE_ROWS)}), and the masks for the two parts of a shifted byte "
        "into the operands of three ANDs. The compositor does the same for the object's "
        "own image. The listing shows those operands as the tape has them.</p>",

        "<h3>Turning round</h3>",
        "<p>Every sprite has two views, towards the viewer and away. The other two "
        "directions are the same views mirrored -- and the mirroring is done to the "
        "sprite bytes themselves, in memory, when an object turns "
        f"({R(MW)}): each row turned end for end, bytes and bits. The knight's fourteen "
        f"frames turn together ({R(MIMAN)}); so do the troll's six ({R(MITRO)}) and the "
        f"wraith's two ({R(MIWRAI)}). Bit 5 of +14 records which way round the bytes are "
        "now.</p>",
        turn_fig,
        f"<p>Turning the knight round is dear: measured when this page was built, the call "
        f"that mirrored his frames took {turn['tstates']:,} T-states, more than a whole pass "
        f"usually takes, while the next pass's call, finding them the right way round, took "
        f"{turn['no turn']:,}: the pass in which he turns takes that much longer. And since the "
        "bytes are shared, a "
        "record's bit 5 is only true if one object uses them: no room has two trolls or "
        f"two wraiths, and leaving a room turns them back ({R(SAVE_OBJECT_POSITIONS)}) so "
        "the next room's, whose record comes fresh with bit 5 clear, agrees with them. "
        "The knight's +14 is kept through a new game for the same reason.</p>",

        "<h3>Beside Krumlinde's reading</h3>",
        f"<p>{krumlinde()} traced the blit well -- the rewritten JR into the RRCAs, the "
        "rewritten masks, the spill into the next byte -- and several names here are his. "
        "He concluded that pages $DA and $DB never reach the screen, since the compositor "
        "loads B with $D8: it does, and then steps B through $D9, $DA and $DB with INC B, "
        "in exactly the instructions his snapshot had jumped over (the JRs the compositor "
        "rewrites held other values when his snapshot was taken). The frame above shows "
        "$DA and $DB at work. He also has modes 4 and 8 drawing the other planes: the "
        "plane offset is added when bit 3 is clear, so mode 8 draws the image and the "
        "others the mask. And page $D8 is not a leftover room buffer but the cover of "
        "what is in front.</p>",

        "<h3>Confirmed and inferred</h3>",
        "<ul>"
        "<li>Run in the simulator when this page was built: the knight's redraw beside the "
        "troll both ways round, with the pages, the list and the screen read out; the "
        "knight turned, and the turn timed.</li>"
        "<li>Read from the code: the chain, the compositor's rule, the sort and its "
        "limit, the modes, the shift.</li>"
        "<li>Inferred: that the fifty-move limit is there to break rings of three or more; "
        "nothing else would need it.</li>"
        "</ul>",
        "</div>"])


# --------------------------------------------------------------------------
# 4. Movement and collision.
# --------------------------------------------------------------------------

BOX_ROOM = 2
BOX_COLOURS = {"knight": (255, 240, 80), "sprite": (80, 230, 90), "door": (80, 220, 240),
               "step": (255, 150, 40), "box": (255, 70, 70)}
FALL_ROOM = 29
FALL_HEIGHTS = [30, 40, 50, 60]
CLIMB_START = (120, 78, 160)        # at the foot of room 2's stairs, walking up +6
PUSH_START = (116, 78, 110)         # behind a stool in room 2, walking up +6
PUSH_THING = 14                     # the stool's record


def knight_passes(snapshot: Path, room: int, place, keys, count: int, watch: int | None = None,
                  release_after: int | None = None) -> list[dict]:
    """The knight put at `place` (+6, +7, +8) in a room, its creatures frozen,
    and `count` passes played holding `keys` (let go after `release_after`
    passes, if given): his place, state and LIFE after each, and those of
    record `watch`."""
    game = Game(snapshot)
    if room != game.memory[ROOM]:
        game.enter(room)
    memory = game.memory
    memory[GAME_FLAGS] |= 0x80
    game.passes(2)
    memory[KNIGHT + 6], memory[KNIGHT + 7], memory[KNIGHT + 8] = place
    rows = []
    for index in range(count):
        held = keys if release_after is None or index < release_after else ()
        before = _life(memory)
        game.passes(1, held, alive=False)
        row = {"place": tuple(memory[KNIGHT + 6:KNIGHT + 9]), "state": memory[KNIGHT + 14],
               "life": _life(memory), "life before": before, "fall": memory[FALL_COUNT]}
        if watch is not None:
            other = record(watch)
            row["other"] = tuple(memory[other + 6:other + 9])
            row["other state"] = memory[other + 14]
            row["other count"] = memory[other + 15]
        rows.append(row)
    return rows


def fall_trial(snapshot: Path, height: int) -> dict:
    """The knight dropped from `height` above the floor of room 29: the passes
    he fell for, and the LIFE it cost."""
    game = Game(snapshot)
    memory = game.memory
    game.passes(2)
    floor = memory[KNIGHT + 7]
    memory[KNIGHT + 7] = floor + height
    memory[LIFE_TENS], memory[LIFE_UNITS] = 9, 9
    falling = 0
    for _ in range(80):
        game.passes(1, alive=False)
        if memory[KNIGHT + 14] & 0x80:
            falling += 1
        elif falling:
            game.passes(1, alive=False)     # the landing is charged on the next pass
            break
    return {"height": height, "passes": falling, "life": _life(memory),
            "top": memory[KNIGHT + 7], "floor": floor}


def writes_to(memory, address: int) -> list[int]:
    """Every place in the code that could write the byte at `address` (one of
    the variables): LD (nn),A / LD (nn),HL and the like with its address, and
    LD (IY+d),r / LD (IY+d),n and the read-modify-write IY instructions with
    its offset. A search of the bytes, over the code's ranges."""
    out = []
    offset = address - 0xFF80
    ranges = [(0xB686, 0xB734), (0xC000, 0xC0B0), (0xC47C, 0xC4BA), (0xDFF2, 0xE0A4),
              (0xE3E4, 0xFF6A)]
    low, high = address & 0xFF, address >> 8
    for start, end in ranges:
        for at in range(start, end - 3):
            b = memory[at:at + 4]
            if b[0] in (0x32, 0x22) and (b[1], b[2]) in ((low, high), ((address - 1) & 0xFF,
                                                                        high)):
                out.append(at)
            if b[0] == 0xED and b[1] in (0x43, 0x53, 0x63, 0x73) and (b[2], b[3]) in (
                    (low, high), ((address - 1) & 0xFF, high)):
                out.append(at)
            if b[0] == 0xFD and b[2] == offset and (
                    0x70 <= b[1] <= 0x77 and b[1] != 0x76 or b[1] in (0x36, 0x34, 0x35)):
                out.append(at)
            if b[0] == 0xFD and b[1] == 0xCB and b[2] == offset and (b[3] & 0xC0) != 0x40:
                out.append(at)
    return out


def _movement_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    R = listing.r
    memory = bf.game_memory(snapshot)

    log("  the boxes of room 2...")
    game = Game(snapshot)
    game.enter(BOX_ROOM)
    game.passes(3)
    live = game.memory
    boxes, counts = [], {}
    for number in range(KNIGHT_NUMBER, live[OBJECT_COUNT] + 1):
        at = record(number)
        fields = live[at:at + RECORD]
        sprite = fields[4] | fields[5] << 8
        if number == KNIGHT_NUMBER:
            kind = "knight"
        elif fields[12] & 15 == 1:
            kind = "door"
        elif sprite:
            kind = "sprite"
        elif fields[12] & 15 in (2, 3):
            kind = "step"
        else:
            kind = "box"
        counts[kind] = counts.get(kind, 0) + 1
        boxes.append((fields[6], fields[7], fields[8], fields[9], fields[10], fields[11],
                      BOX_COLOURS[kind]))
    fixed = [list(live[record(n):record(n) + RECORD]) for n in range(1, 7)]
    from PIL import Image
    # The room in its own colours, darkened so that the boxes stand out.
    dimmed = Image.blend(screen_image(live), Image.new("RGB", (256, 192), (0, 0, 0)), 0.5)
    room_picture = outline_boxes(big(dimmed, 3), boxes, 3, width=2)
    boxes_fig = figure(pictures.stage("movement_boxes.png", room_picture,
                                      f"Room {BOX_ROOM} with every record's box drawn"),
                       f"Room {BOX_ROOM}, in its own colours darkened, with the box of every "
                       "record from the "
                       "knight's on drawn over it, projected the way #R$E4F7 moves sprites: "
                       + ", ".join(f"{swatch(BOX_COLOURS[k])}{w}" for k, w in (
                           ("knight", "the knight"), ("sprite", "objects with sprites"),
                           ("door", "doors"), ("step", "invisible steps (kind 3)"),
                           ("box", "other invisible boxes")) if counts.get(k)) + ". The steps of the "
                       "stairs are boxes the drawing's object list puts down; nothing "
                       "draws them.")
    _check(counts.get("step", 0) >= 4, f"room {BOX_ROOM} has {counts.get('step', 0)} steps")

    log("  gravity's constants...")
    gravity, no_rise = memory[GRAVITY], memory[NO_RISE_MASK]
    _check(gravity & 0xFC == 0x20 and no_rise == 0xEF, "gravity's constants are not $23/$EF")
    gravity_writes = writes_to(memory, GRAVITY) + writes_to(memory, NO_RISE_MASK)
    _check(not gravity_writes, f"something writes gravity's constants: {gravity_writes}")

    log("  falls...")
    falls = [fall_trial(snapshot, h) for h in FALL_HEIGHTS]
    fall_rows = []
    for fall in falls:
        expected = max(0, fall["height"] // 2 - 20)
        _check(fall["passes"] == fall["height"] // 2 and 99 - fall["life"] == expected
               and fall["top"] == fall["floor"],
               f"a fall of {fall['height']}: {fall['passes']} passes, LIFE {fall['life']}")
        fall_rows.append([fall["height"], fall["passes"], expected, 99 - fall["life"]])

    log("  a jump...")
    game = Game(snapshot)
    memory_live = game.memory
    game.passes(2)
    ground = memory_live[KNIGHT + 7]
    jump_rows = []
    for index in range(20):
        game.passes(1, ("SPACE",) if index == 0 else ())
        jump_rows.append((index + 1, memory_live[KNIGHT + 14] & 15,
                          memory_live[KNIGHT + 14] >> 7, memory_live[KNIGHT + 7]))
        if index > 2 and memory_live[KNIGHT + 7] == ground and not memory_live[KNIGHT + 14] & 0x80:
            break
    peak = max(row[3] for row in jump_rows)
    rising = sum(1 for row in jump_rows if row[1] == 5)
    _check(peak - ground == 16 and rising == 8, f"the jump rose {peak - ground} in {rising}")

    log("  climbing and pushing...")
    climb = knight_passes(snapshot, BOX_ROOM, CLIMB_START, ("y",), 30)
    push = knight_passes(snapshot, BOX_ROOM, PUSH_START, ("y",), 12, watch=PUSH_THING)
    stool = record(PUSH_THING)
    stool_weight = live[stool + 16]
    _check(stool_weight & 31 and stool_weight <= 18 + 5, "the stool cannot be pushed")
    _check(push[-1]["other"][0] > live[stool + 6], "the stool did not move")
    climbed = climb[-1]["place"][1] - CLIMB_START[1]
    _check(climbed > 0, "the knight did not climb the stairs")
    climb_rows = [[i + 1, row["place"][0], row["place"][1],
                   "in the air" if row["state"] & 0x80 else ""]
                  for i, row in enumerate(climb)]
    push_rows = [[i + 1, row["place"][0], row["other"][0],
                  "coasting" if row["other state"] & 0x80 else "", row["other count"]
                  if row["other state"] & 0x80 else ""]
                 for i, row in enumerate(push)]

    direction_rows = [
        ["0", "turn back when stopped, rather than stop"],
        ["1", "rising: no gravity this pass"],
        ["2", "down +6 (H to ENTER; the stick left)"],
        ["3", "up +6 (Y to P; the stick right)"],
        ["4", "up"],
        ["5", "down: gravity"],
        ["6", "up +8 (Q to T; the stick up)"],
        ["7", "down +8 (A to G; the stick down)"],
    ]
    fixed_rows = [
        ["1", "the floor", f"{fixed[0][6]}, {fixed[0][7]}, {fixed[0][8]}",
         f"{fixed[0][9]} by {fixed[0][10]} by {fixed[0][11]}", "its top, +7"],
        ["2", "the ceiling", f"{fixed[1][6]}, {fixed[1][7]}, {fixed[1][8]}",
         f"{fixed[1][9]} by {fixed[1][10]} by {fixed[1][11]}", "its top, +7"],
        ["3", "a wall across +6", f"{fixed[2][6]}, {fixed[2][7]}, {fixed[2][8]}",
         f"{fixed[2][9]} by {fixed[2][10]} by {fixed[2][11]}", "+6"],
        ["4", "the other", f"{fixed[3][6]}, {fixed[3][7]}, {fixed[3][8]}",
         f"{fixed[3][9]} by {fixed[3][10]} by {fixed[3][11]}", "+6"],
        ["5", "a wall across +8", f"{fixed[4][6]}, {fixed[4][7]}, {fixed[4][8]}",
         f"{fixed[4][9]} by {fixed[4][10]} by {fixed[4][11]}", "+8"],
        ["6", "the other", f"{fixed[5][6]}, {fixed[5][7]}, {fixed[5][8]}",
         f"{fixed[5][9]} by {fixed[5][10]} by {fixed[5][11]}", "+8"],
    ]
    floor_top = fixed[0][7]

    return "\n".join([
        '<div class="kl-list">',
        "<p>Everything in a Fairlight room -- the knight, the creatures, the things lying "
        "about, the doors, the furniture, the floor and the walls -- is a box, and moving "
        "is trying a box in a new place against every other box. There is no separate map "
        "of the room for collisions: the drawing is only a picture, and what the knight "
        "stands on, walks into, climbs and pushes are the object records. This page is "
        "how a move is made, from the direction byte to the gravity that is added to it, "
        "the test against the boxes, what happens when it fails, and what that gives: "
        "walls, floors, stairs, pushing, riding, jumping and falling.</p>",

        "<h3>Directions and steps</h3>",
        "<p>A direction is a byte with a bit for each way, the same for every object (its "
        "+13 on the ground, +18 in the air, and the copies the move works with):</p>",
        table(["Bit", "Means"], direction_rows),
        f"<p>The knight's keys (read in {R(KNIGHT_CONTROLS)}) set one of the four floor "
        "directions; a later test wins, so he never walks diagonally, though other things "
        f"do. A step ({R(STEP_ALONG_X)} and the two after it) is two units along one "
        "floor axis, one along each of the two for a diagonal, and always two up or down. "
        "On the screen, up +6 goes up and to the right, up +8 up and to the left.</p>",

        "<h3>Boxes</h3>",
        f"<p>A record's box is a corner and three sizes: from +6 for +9 along +6, from +8 "
        f"for +11 along +8, and from its top, +7, down +10 (read in {R(TEST_ONE_RECORD)}, "
        "the author's BB2). Two boxes meet when they overlap along all three axes, each "
        "test strict, so boxes that only touch do not. Room "
        f"{BOX_ROOM}'s records, their boxes drawn over the room:</p>",
        boxes_fig,
        f"<p>{R(FIND_OBSTACLE)} walks the records in use from the last down to the first "
        "and stops at the first whose box meets the one being tried, leaving out the "
        "mover's own and anything carried or gone (a door always counts). The first six "
        f"records ({R(FIXED_RECORDS)}) are the room's own box -- in room {BOX_ROOM}, read in "
        "the running game:</p>",
        table(["Record", "What", "Corner", "Size", "Set by the patch"], fixed_rows),
        f"<p>So an object stands on the floor when its foot, +7 less +10, is at "
        f"{floor_top}: the floor's box is ten high with its top there, and the step down "
        "that gravity asks for meets it.</p>",

        "<h3>Gravity</h3>",
        f"<p>Every object's update ends in the same code ({R(ANIMATE_AND_MOVE)}). There, "
        f"unless the direction has bit 1 (rising), the up bit is taken out -- ANDed with "
        f"${no_rise:02X} from $FF8B -- and down is added -- ORed with ${gravity & 0xFC:02X}, "
        f"the top six bits of ${gravity:02X} at $FF85. Both are constants among the "
        "variables: a new game restores them from the master copy, and a search of the "
        "code for every instruction that could store into either found none. So "
        "everything that is not rising tries to fall two units every pass, and a floor, a "
        "table or another object is what stops it. That is also what makes a thing lying "
        f"on the floor cost time every pass ({page('Architecture', 'the pass traced')}): "
        "its fall is tried, and stopped, again and again.</p>",
        "<p>A step down sets bit 7 of the state, in the air. While it is set the object's "
        "own case is not run at all: it goes on the way +18 says, and a fall keeps only "
        "the down bit there, so everything falls straight down, the knight at the end of a "
        "jump too. The air ends when the fall is stopped.</p>",

        "<h3>What a blocked move does</h3>",
        f"<p>When the tried box meets another record, {R(BUMPED)} deals with doors "
        f"(for the knight, a way to another room) and {R(OBJECTS_MEET)} with what the two "
        f"objects do to each other ({page('Creatures', 'the creatures page')}); what is "
        f"left comes to BLOCKED_MOVE ({R(MEET_DECOY)}). It works out how much of the move "
        "that one object stops, trying from where the mover was:</p>",
        "<ul>"
        "<li>each moving axis alone, +6, the height and +8. One that collides is taken out "
        "of the move, and the mover's direction on it turned round if it bounces (bit 0) "
        "or cleared if not. So something walking diagonally into a wall slides along "
        "it;</li>"
        "<li>then the pairs: +6 with the height colliding takes the height out, +6 with +8 "
        "both, the height with +8 the height;</li>"
        "<li>if all three are still in after that, only the whole diagonal collides, and "
        "none of it is made.</li>"
        "</ul>",
        "<p>Then what is left of the move is tried again, and may meet something else. "
        "Three of the collisions do more:</p>",
        "<ul>"
        "<li><b>Climbing.</b> Running along +6 into an object of kind 3, or along +8 into "
        "one of kind 2, is a climb: the mover goes up for three passes. Those objects "
        "are the invisible steps of a staircase.</li>"
        "<li><b>Riding.</b> Coming down onto an object that is moving -- by its own state, "
        "or coasting -- the mover rides it: its state's bit 4, and the other's direction "
        "copied into its own at the end of the move, so next pass it goes the same way.</li>"
        "<li><b>Pushing.</b> Unless the mover landed on it, or it is a door or still, the "
        "other is pushed if its +16 is no more than 5 above the mover's: it coasts (bit 7 "
        "of its state, in the air) the way the mover asked to go, for the mover's +16 less "
        "its own, plus 6, passes. +16 is 16 plus the weight, and the knight's is 18, so he "
        "can push anything that can move at all; the heavier it is, the sooner it stops.</li>"
        "</ul>",

        f"<h3>Climbing room {BOX_ROOM}'s stairs</h3>",
        f"<p>The knight put at {', '.join(map(str, CLIMB_START))}, at the foot of the "
        f"stairs, with Y held (up +6), in the simulator when this page was built -- his "
        "+6 and his top, +7, after each pass:</p>",
        table(["Pass", "+6", "+7", ""], climb_rows),
        f"<p>Each time he walks into the next step he stops, goes up for three passes, "
        f"falls back two onto the step and walks on: {climbed} units higher after "
        f"{len(climb)} passes. The steps are boxes of kind 3, 10 high and each a little "
        "higher than the one before, laid over each other.</p>",

        "<h3>Pushing a stool</h3>",
        f"<p>The knight put behind one of room {BOX_ROOM}'s stools (record {PUSH_THING}, "
        f"+16 = {stool_weight}: weight {stool_weight - 16}) and walked into it with Y. "
        f"The rule gives it 18 less {stool_weight}, plus 6: {18 - stool_weight + 6} passes "
        "of coasting a push. Measured, the knight's +6, the stool's, and its countdown "
        "(+15) while it coasts:</p>",
        table(["Pass", "Knight's +6", "Stool's +6", "", "Its +15"], push_rows),
        "<p>The stool moves ahead of him two units a pass while it coasts, and he catches "
        "it up and pushes again.</p>",

        "<h3>Jumping</h3>",
        f"<p>SPACE or SYMBOL SHIFT ({R(KNIGHT_CONTROLS)}) makes the knight's direction "
        "his walking one with up and rising added, +15 = 8 and his state 5. For eight "
        f"passes {R(CHE3D)}'s state-5 case moves him up two a pass without gravity, the "
        "way he was walking; then he is state 8 again and falls. SPACE for one pass in room "
        f"{FALL_ROOM}, when this page was built:</p>",
        table(["Pass", "State", "In the air", "+7 (his top)"],
              [[p, s, "yes" if a else "", t] for p, s, a, t in jump_rows]),
        f"<p>Up {peak - ground} in {rising} passes, and down again. A jump is how the "
        "knight goes up through a hole in a ceiling -- a door whose way is up -- and over "
        "low things.</p>",

        "<h3>Falling</h3>",
        f"<p>The knight counts the passes he falls for ($FF94, at the commit in "
        f"{R(ANIMATE_AND_MOVE)}); when he lands, his update ({R(CREATURE_UPDATE, 'KNIGHT_UPDATE')}) "
        "takes a LIFE point for every pass over 20 -- two units a pass, so a fall of more "
        f"than 40. Dropped from above room {FALL_ROOM}'s floor in the simulator when this "
        "page was built:</p>",
        table(["Height", "Passes falling", "LIFE by the rule", "LIFE lost"], fall_rows),

        "<h3>The first pass in a room</h3>",
        "<p>On the first pass after a room is entered (bit 2 of GAME_FLAGS) nothing moves: "
        "each object's direction is cleared, but all three axes are marked as moving, so "
        "the test runs on a box one unit up +6, two down and one down +8 from where it is, "
        "and whatever that meets is dealt with as usual; then the object is only drawn. "
        "What the offset box is for has not been worked out.</p>",

        "<h3>Beside Krumlinde's reading</h3>",
        f"<p>{krumlinde()} reads the sizes as half-widths about a centre; the box test "
        "compares against the corner and the corner plus the size, and the pick-up's "
        "search box, measured in stage 2, reaches exactly as far as a corner-and-size box "
        "would. He finds no code that makes things fall, and leaves open what holds them "
        "up: gravity is the down bit forced into every direction that is not rising, "
        "applied by the ordinary step, and floors are the fixed records and the invisible "
        "boxes. His assembler source writes the minus-20 step through the records as a "
        "load of the variable at $FFEC; it is the number, which only looks like the "
        "address.</p>",

        "<h3>Confirmed and inferred</h3>",
        "<ul>"
        f"<li>Run in the simulator when this page was built: room {BOX_ROOM}'s boxes read; "
        "the falls, the jump, the climb and the push, each from a staged place with the "
        "creatures frozen.</li>"
        "<li>Searched when this page was built: no instruction stores into the two "
        "gravity constants.</li>"
        "<li>Read from the code: the direction bits, the order of the axis tests, riding, "
        "the push rule.</li>"
        "<li>Inferred: the box outlines' alignment with the picture. The slopes of the "
        "projection are #R$E4F7's; its constants come from the knight's fixed point, and "
        "the outlines fit the sprites and the stairs by eye.</li>"
        "</ul>",
        "</div>"])


# --------------------------------------------------------------------------
# 5. Things and creatures.
# --------------------------------------------------------------------------

THINGS_ROOM = 29            # the teleporting thing lies in the start room
DECOY_ROOM = 20             # a rising guard and a decoy
KILL_ROOM = 29              # a guard to fight
EEN_ROOM = 20
QUEST_THING = bf.QUEST_THING
QUEST_THING_ROOM = bf.QUEST_THING_ROOM
R1_FREEZE_TEST = [0x18, 0xC7, 0x00, 0x00]   # Release 1's JR I00 (and two spare bytes)

KIND_NAMES = {
    0: "nothing when used",
    4: "used: LIFE up by 10, to 99 at most",
    5: "used: freezes the room's creatures until the knight leaves",
    6: "used: LIFE to 99",
    8: "a decoy: the rising guards go for it rather than the knight, and take it",
    9: "used: carries the knight to room 30, where a new game starts him",
    10: "destroys a wraith it is dropped or pushed onto",
    11: "while it lies in room 61, the figure there wakes and the room's hole works",
}
CREATURES = [
    # (state, name, what it does)
    (6, "guard", "patrols along +6, chasing the knight when within 30"),
    (10, "guard", "patrols along +8, chasing the knight when within 30"),
    (9, "rising guard", "rises out of the floor, then always chases (or goes for a decoy)"),
    (7, "troll", "chases; hurts at a touch until its first pass (below)"),
    (11, "wraith", "chases; only two things can destroy it"),
    (13, "ghost", "wanders, turning off whatever it meets; takes any thing it touches"),
    (12, "floating thing", "hangs in the air and flickers"),
    (14, "floating thing", "hangs in the air and flickers"),
    (15, "the figure of room 61", "stands until the kind-11 thing lies in the room, then "
     "is a wraith"),
    (4, "winged creature", "strikes when the knight stands within reach in front of it"),
    (3, "bouncing ball", "bounces about, hurting what it touches"),
]


def template_sprite(memory, kind: int, scale: int = 2):
    """The sprite a type's template names, drawn."""
    at = template(memory, kind)
    sprite = _word(memory, at + 4)
    return sprite, sprite_of(memory, sprite, memory[at + 2], memory[at + 3], scale)


def freeze_jump(snapshot: Path, release_one: bool) -> dict:
    """The creatures frozen (bit 7 of GAME_FLAGS, as using a kind-5 thing sets
    it) in the start room, SPACE for one pass, then nothing for 19, then Q for
    ten: the knight's state each pass, and how far Q took him. With
    `release_one`, Release 1's instruction is put at $F263 first."""
    game = Game(snapshot)
    memory = game.memory
    if release_one:
        memory[FREEZE_TEST:FREEZE_TEST + 4] = R1_FREEZE_TEST
    game.passes(2)
    memory[GAME_FLAGS] |= 0x80
    states = []
    for index in range(20):
        game.passes(1, ("SPACE",) if index == 0 else ())
        states.append(memory[KNIGHT + 14] & 15)
    before = memory[KNIGHT + 8]
    game.passes(10, ("q",))
    return {"states": states, "walked": memory[KNIGHT + 8] - before}


def kill_guard(snapshot: Path) -> dict:
    """The start room's guard (state 6), frozen, put against the knight's +6
    side on the floor, and the knight fighting towards it (B and Y held):
    each pass a strike counter went down, and what the guard became."""
    game = Game(snapshot)
    memory = game.memory
    game.passes(2)
    guard = next(n for n in game.records() if memory[record(n) + 14] & 15 == 6)
    at = record(guard)
    memory[GAME_FLAGS] |= 0x80
    memory[at + 6] = (memory[KNIGHT + 6] + memory[KNIGHT + 9] + 2) & 0xFF
    memory[at + 8] = memory[KNIGHT + 8]
    memory[at + 7] = (memory[KNIGHT + 7] - memory[KNIGHT + 10] + memory[at + 10]) & 0xFF
    before = (memory[at + 12], memory[at + 14], _word(memory, at + 4))
    strikes, last = [], list(memory[STRIKES_LEFT:STRIKES_LEFT + 6])
    for index in range(200):
        game.passes(1, ("b", "y"))
        now = list(memory[STRIKES_LEFT:STRIKES_LEFT + 6])
        if now != last:
            strikes.append(index + 1)
        last = now
        if memory[at + 12] != before[0]:
            break
    return {"guard": guard, "before": before, "strikes": strikes,
            "after": (memory[at + 12], memory[at + 14], _word(memory, at + 4)),
            "counters": last}


def decoy_trial(snapshot: Path, with_decoy: bool) -> dict:
    """Room 20's rising guard and its decoy, left to play out for up to 400
    passes (without the decoy's kind, when `with_decoy` is off): when the decoy
    vanished, its object-table room, and where the guard and the knight were."""
    game = Game(snapshot)
    game.enter(DECOY_ROOM)
    memory = game.memory
    guard = next(n for n in game.records() if memory[record(n) + 14] & 15 == 9)
    decoy = next(n for n in game.records() if memory[record(n) + 12] & 15 == 8)
    at = record(decoy)
    if not with_decoy:
        memory[at + 12] &= 0xF0
    number = memory[at + 19]
    taken = None
    for index in range(400):
        game.passes(1)
        if memory[at + 16] & 0x20:
            taken = index + 1
            break
    return {"guard": guard, "decoy": decoy, "taken": taken, "number": number,
            "table room": memory[OBJECTS - 6 + 6 * number],
            "guard at": tuple(memory[record(guard) + 6:record(guard) + 9]),
            "knight at": tuple(memory[KNIGHT + 6:KNIGHT + 9]),
            "noted": memory[THINGS_NOTED]}


def teleport_trial(snapshot: Path) -> dict:
    """The kind-9 thing in the start room picked up (the knight put on it, X)
    and used (6): the places, the thing's object-table room, and the room
    after."""
    game = Game(snapshot)
    memory = game.memory
    game.passes(2)
    thing = next(n for n in game.records() if memory[record(n) + 12] & 15 == 9)
    at = record(thing)
    number = memory[at + 19]
    bf._onto_knight(at)(memory)
    game.passes(2, ("x",))
    game.passes(1)
    carried = _word(memory, CARRIED)
    table_room = memory[OBJECTS - 6 + 6 * number]
    game.passes(1, ("6",))
    game.passes(2)
    return {"number": number, "carried": carried, "record": at, "table room": table_room,
            "room": memory[ROOM], "table room after": memory[OBJECTS - 6 + 6 * number],
            "knight": tuple(memory[KNIGHT + 6:KNIGHT + 9])}


def een_trial(snapshot: Path) -> dict:
    """A thing in room 20 moved, and the game ended (LIFE 0), which runs #R$F906:
    its object-table entry before and after."""
    game = Game(snapshot)
    game.enter(EEN_ROOM)
    memory = game.memory
    thing = next(n for n in game.records() if memory[record(n) + 19]
                 and memory[record(n) + 12] & 15 != 1)
    at = record(thing)
    entry = OBJECTS - 6 + 6 * memory[at + 19]
    before = tuple(memory[entry + 3:entry + 6])
    memory[at + 6] += 4
    memory[at + 8] += 6
    moved = tuple(memory[at + 6:at + 9])
    memory[LIFE_TENS] = memory[LIFE_UNITS] = 0
    game.run_to(0xF0B2)
    return {"number": memory[at + 19], "before": before, "moved": moved,
            "after": tuple(memory[entry + 3:entry + 6])}


def _creatures_page(snapshot: Path, listing: Listing, pictures: Pictures, log) -> str:
    R = listing.r
    memory = bf.game_memory(snapshot)
    table_things = things(memory)
    small = [t for t in table_things if t["type"] < fd.LARGE_FIRST]
    doors = [t for t in table_things if t["type"] >= fd.LARGE_FIRST]
    first_door = doors[0]["number"]
    movable = [t for t in small if t["number"] < first_door]
    statics = [t for t in small if t["number"] > first_door]
    _check(all(d["number"] < statics[0]["number"] for d in doors),
           "the doors are not all between the things and the statics")

    log("  the things by kind...")
    by_kind: dict[int, list[dict]] = {}
    for thing in movable:
        if thing["kind"] & 0x20:
            by_kind.setdefault(thing["kind"] & 15, []).append(thing)
    kind_rows = []
    for kind in sorted(by_kind):
        entries = by_kind[kind]
        seen_types, images = [], []
        for entry in entries:
            if entry["type"] not in seen_types:
                seen_types.append(entry["type"])
        for kind_type in seen_types:
            sprite, image = template_sprite(memory, kind_type, 2)
            images.append(pictures.piece(f"things_type{kind_type}.png", image,
                                         f"Type {kind_type}", css="fl-sprite"))
        kind_rows.append([kind, " ".join(images), len(entries),
                          _numbers(e["room"] for e in entries if e["room"] < 0xFE),
                          KIND_NAMES.get(kind, "")])
    weights = sorted({template_weight(memory, t["type"]) - 16 for t in movable
                      if t["kind"] & 0x20 and template_weight(memory, t["type"]) & 31})
    heaviest = max(weights)

    log("  using the kind-9 thing...")
    teleport = teleport_trial(snapshot)
    _check(teleport["carried"] == teleport["record"] and teleport["table room"] == 0xFE
           and teleport["room"] == 30, f"the kind-9 thing: {teleport}")

    log("  a room's things saved...")
    een = een_trial(snapshot)
    _check(een["after"] == een["moved"] and een["before"] != een["moved"],
           f"EEN did not save the moved thing: {een}")

    log("  doors...")
    ways = {}
    for door in doors:
        ways[door["door"][4]] = ways.get(door["door"][4], 0) + 1
    doorways = sum(ways.get(bit, 0) for bit in (0x04, 0x08, 0x40, 0x80))
    holes_down, holes_up = ways.get(0x20, 0), ways.get(0x10, 0)
    _check(doorways + holes_down + holes_up == len(doors), f"door ways {ways}")
    keys: dict[int, list[int]] = {}
    for door in doors:
        if door["door"][1]:
            keys.setdefault(door["door"][1], []).append(door)
    key_rows = []
    for number in sorted(keys):
        thing = table_things[number - 1]
        sprite, image = template_sprite(memory, thing["type"], 2)
        rooms = sorted({d["room"] for d in keys[number]})
        key_rows.append([number, pictures.piece(f"things_type{thing['type']}.png", image,
                                                f"Type {thing['type']}", css="fl-sprite"),
                         thing["room"], len(keys[number]),
                         _numbers(rooms)])

    log("  the creatures, room by room...")
    rooms_census = census(snapshot)
    creature_rooms: dict[int, set[int]] = {}
    creature_kinds: dict[int, set[int]] = {}
    for room, data in rooms_census.items():
        for number, fields in data["records"]:
            if fields[12] & 15 == 1 or not (fields[4] or fields[5]) or not fields[16] & 31:
                continue
            state = fields[14] & 15
            if state in (0,):
                continue
            creature_rooms.setdefault(state, set()).add(room)
            creature_kinds.setdefault(state, set()).add(fields[12])
    state_types: dict[int, list[int]] = {}
    for kind in range(fd.SMALL_COUNT):
        if _word(memory, template(memory, kind) + 4):
            state_types.setdefault(template_state(memory, kind), []).append(kind)
    creature_rows = []
    for state, name, what in CREATURES:
        kinds_of = state_types.get(state, [])
        images = []
        for kind_type in kinds_of[:1]:
            sprite, image = template_sprite(memory, kind_type, 2)
            images.append(pictures.piece(f"creature_type{kind_type}.png", image,
                                         f"Type {kind_type}", css="fl-sprite")
                          + "<br>" + R(sprite, f"${sprite:04X}"))
        flags = set()
        for value in creature_kinds.get(state, set()):
            if value & 0x80:
                flags.add("fighter")
            if value & 0x40:
                flags.add("can be killed")
            if value & 0x10:
                flags.add("hurts")
        creature_rows.append([state, name, ", ".join(str(k) for k in kinds_of),
                              " ".join(images), _numbers(creature_rooms.get(state, [])),
                              ", ".join(sorted(flags)), what])

    log("  a guard killed...")
    kill = kill_guard(snapshot)
    _check(len(kill["strikes"]) == 4 and kill["after"][2] == 0xA4B8
           and kill["after"][0] & 0x20, f"the guard was not killed as the code says: {kill}")
    _, helmet = template_sprite(memory, 27, 3)

    log("  a decoy...")
    decoy = decoy_trial(snapshot, True)
    no_decoy = decoy_trial(snapshot, False)
    _check(decoy["taken"] and decoy["table room"] == 0xFE and not decoy["noted"] & 1,
           f"the decoy was not taken: {decoy}")
    _check(no_decoy["taken"] is None, "the thing was taken without its kind 8")

    log("  the freeze, in both releases...")
    release_two = freeze_jump(snapshot, False)
    release_one = freeze_jump(snapshot, True)
    _check(tuple(memory[FREEZE_TEST:FREEZE_TEST + 2]) == (0xFE, 0x05),
           "Release 2 has not CP 5 at $F263")
    _check(release_two["states"][:9] == [5] * 8 + [8] and release_two["walked"] > 0,
           f"Release 2's knight: {release_two}")
    _check(set(release_one["states"]) == {5} and release_one["walked"] == 0,
           f"Release 1's knight: {release_one}")

    banes = [t for t in movable if t["kind"] & 0x20 and t["kind"] & 15 in (6, 10)]
    banes_there = [t for t in banes if t["room"] in creature_rooms.get(11, set())]

    meet_rows = [
        ["1", "the mover hurts (bit 4): the troll, the balls", "the knight loses 10 "
         "(not on a room's first pass); anything else that can move is knocked up; the "
         "mover vanishes"],
        ["2", "the knight walks into something that hurts", "he loses 10; it vanishes"],
        ["3", "a fighter (bit 7) walks into the knight", "he loses 1"],
        ["3", "the knight walks into a fighter", "sword not out: he loses 1. Sword out and "
         "the other can be killed (bit 6): one of its four strikes is gone; at none a guard "
         "becomes a helmet, anything else vanishes"],
        ["4", "the ghost meets a thing that can be carried", "the thing leaves the game"],
        ["5", "a thing of kind 6 or 10 meets a wraith", "both leave the game"],
        ["6", "anything meets a kind-7 floor (the pits of rooms 9 and 12)", "it vanishes; the "
         "knight's LIFE goes to 00"],
        ["7", "a rising guard meets a decoy", "the decoy leaves the game"],
        ["8", "anything else", "an obstacle (" + page("Movement", "movement") + ")"],
    ]

    return "\n".join([
        '<div class="kl-list">',
        "<p>The knight shares the castle with things he can carry and use, doors that "
        "need keys, and creatures that chase him, hurt him, and in one case steal from "
        "him. All of them are object records, and what each does is written in a few "
        "bits of them: the kind byte (+12) says what a thing is and what touching it "
        "does, the state (+14) what a creature does each pass. This page is those bits, "
        "the object table that remembers where everything is, and each creature, with the "
        "rules for what happens when two of them meet.</p>",

        "<h3>The object table</h3>",
        f"<p>{R(OBJECTS)} holds {len(table_things)} records: a room and a type, then four "
        f"bytes for a type below $46 or nine for the others. The first {len(movable)} are "
        f"the things, six bytes each; then {len(doors)} doors of eleven; then "
        f"{len(statics)} more of six, which the author's leftover source heads STATIC OBJ. "
        f"Only the first {len(movable)} can move between rooms: {R(SET_THING_ROOM)} (the "
        "author's ROMM) finds a thing's entry by its number, six bytes a number, which "
        "works only while every record before it is six bytes long. A thing's room is "
        "written there when it is picked up ($FE, no room), dropped, or taken out of the "
        f"game; its place is written back by {R(SAVE_OBJECT_POSITIONS)} (the author's EEN) "
        "whenever the knight leaves a room, for every record of the room up to the first "
        f"door. Measured: in room {EEN_ROOM}, thing {een['number']} moved to "
        f"{', '.join(map(str, een['moved']))} and the game ended -- its entry went from "
        f"{', '.join(map(str, een['before']))} to {', '.join(map(str, een['after']))}. A "
        "new game puts the first 1200 bytes back from the master copy, which is all the "
        "things.</p>",

        "<h3>Things</h3>",
        "<p>A thing with bit 5 of its kind byte can be carried. The low nibble says what it "
        "does; the things in the table, by kind, with their templates' sprites:</p>",
        table(["Kind", "Sprites", "How many", "Rooms", "What it does"], kind_rows),
        f"<p>The knight carries up to five, one in each of five places (1 to 5 choose the "
        f"place in use; the panel shows it, {R(SHOW_THING_IN_USE)}). X, C or V picks up "
        f"({R(PICK_UP)}): only into an empty place, from a box his own size four units "
        f"ahead of him, the first thing there that can be carried -- unless the load would "
        f"reach 8. A thing's weight is its +16 less 16; the heaviest weigh {heaviest}. "
        "CAPS SHIFT or Z drops the thing in use beside him, level with his top, and it "
        "falls; if something is in the way it is BLOCKED.</p>",
        f"<p>6 or 7 uses the thing in the place in use ({R(MAIN_LOOP)}), if its kind does "
        "anything; it is used up. The start room has the kind-9 thing: when this page was "
        f"built the knight was put on it, X picked it up (the place held its record, "
        f"${teleport['carried']:04X}, and its entry said room {teleport['table room']}), "
        f"and 6 used it: two passes later he was in room {teleport['room']}, at "
        f"{', '.join(map(str, teleport['knight']))}, the place a new game puts him, and "
        f"the thing's entry still said {teleport['table room after']}: gone for good.</p>",

        "<h3>Doors</h3>",
        f"<p>Every eleven-byte record is a door: {len(doors)} of them. Its six bytes after "
        "the place give the room behind it (+13), the thing that is its key (+14, a "
        "thing's number, or none), where the knight arrives (+15, +16, +18) and the way "
        f"through (+17, a direction). {doorways} are doorways, walked through along +6 or "
        f"+8; {holes_down} are holes he drops through, and {holes_up} holes up, which need "
        f"a jump. {R(BUMPED)} takes him through when he walks into one the right way, "
        "holding its key in the place in use and wholly within its span: the room's "
        "things are saved and the room behind is entered -- unless a thing (a troll "
        "aside) already stands where he would arrive, which is BLOCKED. Anyone else "
        f"finds a door a wall. {sum(len(v) for v in keys.values())} doors need a key:</p>",
        table(["Key (thing)", "Sprite", "Lies in room", "Doors", "In rooms"], key_rows),
        "<p>Room 61's only way out, a hole, also needs the kind-11 thing to be lying in the "
        "room; the same thing wakes the room's figure (below).</p>",

        "<h3>The creatures</h3>",
        f"<p>A creature is a state. Its template gives it one, and {R(CHE3D)} and "
        f"{R(CREATURE_UPDATE)} act on it every pass (see "
        f"{page('Architecture', 'the states')}). From the templates and from every room "
        "entered in the simulator when this page was built:</p>",
        table(["State", "What", "Types", "Sprite", "Rooms", "Kind bits", "What it does"],
              creature_rows),
        "<p>The names are this disassembly's, from the pictures and from the author's own "
        f"routine names {R(MITRO)} and {R(MIWRAI)} (mirror troll, mirror wraith). The "
        "winged creature's strike never happened in the build's play-throughs; stage 2 of "
        "this disassembly staged it, and it takes 3 LIFE a pass.</p>",

        "<h3>Chasing</h3>",
        f"<p>A chaser keeps its course in +18 and a countdown in +15 ({R(STEER)}, the "
        f"author's ZZ1). When the count runs out, {R(ZOOMIN)} picks the target -- the "
        f"knight, or for a rising guard a decoy lying in the room -- and {R(AIM_AT)} "
        "points the chaser along one floor axis only, whichever the target is further off "
        "along, and sets the count to 10 passes, or 3 when it is within 14 along +8. So a "
        "creature zigzags after the knight, changing its mind every few passes. The "
        "guards of states 6 and 10 chase only when he is within 30; otherwise they walk to "
        "and fro.</p>",

        "<h3>When two meet</h3>",
        f"<p>When a move runs into something that is not a door, {R(OBJECTS_MEET)} looks at "
        "the kind bytes of the mover and the other, in this order:</p>",
        table(["", "When", "What happens"], meet_rows),
        "<p>LIFE is two decimal digits; at 00 the game is over. Falls cost it too "
        f"({page('Movement', 'movement')}). The troll's table records have bit 4 set, but "
        "its own case clears it on its first pass, so after that it only fights like a "
        "guard.</p>",

        "<h3>Fighting</h3>",
        f"<p>B, N or M fights: the sword is out for three passes, then away for three as "
        f"the knight steps forward. As {R(FIND_OBSTACLE)} walks the records it deals the "
        "fighters six strike counters ($FF98-$FF9D), set to 4 as each room is entered, the "
        "first six fighters from the top of the list one each. When this page was built "
        f"the start room's guard (record {kill['guard']}) was frozen, put against the "
        "knight's side, and the knight held B and Y: its counter went down at passes "
        f"{', '.join(map(str, kill['strikes']))}, and at the fourth strike the guard "
        "became its helmet -- sprite $A4B8, a thing that can be picked up, knocked into the "
        "air.</p>",
        figure(pictures.piece("creatures_helmet.png", helmet, "The helmet",
                              css="fl-sprite"),
               "What a guard leaves: #R$A4B8, also the first frame of a rising guard."),

        "<h3>The decoy</h3>",
        f"<p>As {R(CHE3D)} goes through a room's things it notes the first decoy (kind 8) "
        "it meets, and the rising guards go for that instead of the knight; one that "
        f"reaches it takes it out of the game ({R(MEET_DECOY)}). In room {DECOY_ROOM}, "
        "played in the simulator when this page was built, the rising guard took the decoy "
        f"after {decoy['taken']} passes, its entry went to room {decoy['table room']} and "
        "the note was cleared. With the decoy's kind cleared first, the guard went for the "
        f"knight instead, and after 400 passes the thing was still there.</p>",

        "<h3>The ghost and the wraith</h3>",
        "<p>The ghost (state 13) takes any thing that can be carried that it runs into: "
        "its entry goes to room $FE, and it is gone. The wraith (state 11) cannot be "
        "killed with the sword -- its kind byte lacks bit 6 -- but a thing of kind 6 or 10 "
        "dropped or pushed onto it destroys both; stage 2 of this disassembly staged that "
        f"in room 28. Of the {len(banes)} things of those kinds, {len(banes_there)} start in "
        "a room with a wraith.</p>",

        "<h3>The freeze, and Release 1's lock</h3>",
        "<p>Using a kind-5 thing sets bit 7 of GAME_FLAGS, and only entering a room clears "
        f"it. While it is set, {R(CHE3D)} treats every state but the knight's 8 and his "
        "jump's 5 as state 0: the creatures stand and only fall. Release 1 exempted only "
        "state 8 -- it has JR I00 where Release 2 has CP 5 and JR NZ,I00 at $F263 -- and "
        "there a jump during the freeze is never counted down: the knight stays in state 5, "
        "and never walks again. Played in the simulator when this page was built, the "
        "freeze set, SPACE for one pass and then Q for ten, in Release 2 and with Release "
        "1's instruction put at $F263:</p>",
        table(["", "The knight's state, pass by pass", "Q moved him along +8"], [
            ["Release 2", " ".join(str(s) for s in release_two["states"]),
             release_two["walked"]],
            ["Release 1's instruction", " ".join(str(s) for s in release_one["states"]),
             release_one["walked"]],
        ]),
        "<p>That is very likely why the instruction was changed (inferred: nothing says "
        "so). Stage 2 of this disassembly also played it in Release 1 itself, loaded from "
        "its own tape, with the same result.</p>",

        "<h3>Beside Krumlinde's reading</h3>",
        f"<p>{krumlinde()} has the drop and the door's LOCKED; where this page differs: "
        f"{R(SAVE_OBJECT_POSITIONS)} copies the records' places into the table, not the "
        "table into the records; the second BLOCKED in the door code is the arrival spot "
        "being taken; kind 4 adds ten to LIFE, and kind 5 freezes the creatures; 0 with "
        "SYMBOL SHIFT quits and 6 or 7 uses, where he has 0 as the use key; and the "
        "alternative target of the rising guards is the decoy.</p>",

        "<h3>Confirmed and inferred</h3>",
        "<ul>"
        "<li>Run in the simulator when this page was built: the kind-9 thing picked up "
        "and used; a room's things saved; every room entered for its creatures; a guard "
        "killed; the decoy taken, and not taken without its kind; the freeze and a jump, "
        "with each release's instruction.</li>"
        "<li>Read from the game when this page was built: the object table, the doors and "
        "keys, the templates' states and weights.</li>"
        "<li>Read from the code: the meeting rules, chasing, the ghost and the wraith. "
        "Stage 2 staged the winged creature's strike and the wraith's end.</li>"
        "<li>Inferred: the names of the creatures and things, from their pictures.</li>"
        "</ul>",
        "</div>"])


# --------------------------------------------------------------------------
# Together.
# --------------------------------------------------------------------------

PAGES = {
    "Architecture": "_architecture_page",
    "RoomDrawing": "_room_drawing_page",
    "SpriteDrawing": "_sprite_drawing_page",
    "Movement": "_movement_page",
    "Creatures": "_creatures_page",
}
TITLES = {
    "Architecture": "How the game is put together",
    "RoomDrawing": "How a room is drawn",
    "SpriteDrawing": "How a moving object is drawn",
    "Movement": "Movement and collision",
    "Creatures": "Things and creatures",
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
    listing = Listing(snapshot.with_name("fairlight.skool"))
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
