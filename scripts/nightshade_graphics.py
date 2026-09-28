"""Nightshade's graphics pages -- the tiles and edge pictures the town is
built from, the graphic table, every sprite, the panel and the font -- drawn
from the game at build time.

build_nightshade.py --html calls build(), which draws the pictures into
html_dir/images/graphics/ and returns five ref sections: Tiles, GraphicTable,
Sprites, Panel and Font. Nothing here is committed output: the pictures are
the game's, and so are the lists of what uses what. What is committed is the
prose, the addresses, and short names for what the pictures show, each given
after looking at the picture.

Everything is drawn by the game's own code, run in SkoolKit's simulator:

- A game is started the way build_nightshade.py's sessions start one (its
  Machine, key 1 and key 0 on the menu, through the start tune) and run to
  the top of its first turn (MAIN_LOOP, #R$BE0F), so the drawing tables are
  built (#R$E0FB) and the variables are a real game's. The menu is kept too,
  as it stands at the first pass of its loop.
- Each sprite is drawn by DRAW_SPRITE_AT (#R$E3D9) from a spare object
  record holding its graphic, its flags and a place, into the play area's
  buffer (#R$E5C4): once on a buffer of zeros and once on a buffer of ones.
  A pixel set in the first is the image; one cleared in the second is the
  mask; one set in the second and not the first is where the background
  shows through. Mirrored pictures are the same with bit 6 of the record's
  flags set, so TURN_SPRITE (#R$E353) turns the stored bytes round first,
  as it does in play. Every picture is compared with the sprite's bytes read
  the way the listing reads them (build_nightshade.sprite_image), and the
  build stops if one differs.
- The knight in his four facings is his two real records after a turn with
  the facing poked in at the start of it, drawn with DRAW_SPRITE (#R$E3D9)
  and so projected and offset as in play.
- Tiles by PUT_TILE (#R$D425), edge pictures by PUT_EDGE (#R$D2B2), from a
  tile number or an edge picture's address, first face and second (mirrored).
- The panel, the menu's border and the characters by the game's own
  routines (#R$C1FD, #R$C4A4, #R$C4DC, #R$C29A, the lives' part of #R$CBAC,
  #R$C2ED, the printer's #R$CB19), read back from the screen.
"""
from __future__ import annotations

import html
import re
from pathlib import Path

import nightshade_data as nd

IMAGES = "images/graphics"

# Where the game keeps what the pictures need (see their entries).
MAIN_LOOP = 0xBE71
BUFFER = 0xE5C4             # 24 bytes by 112 lines, row 0 the bottom (y 72)
BUFFER_ROWS = 112
BUFFER_ROW = 24
BUFFER_Y = 72               # the y of the buffer's row 0
BUFFER_X = 16               # the x of a row's first byte
DRAW_X = 0xBBB6
DRAW_PASS = 0xBBF2          # non-zero: a building's second face, drawn mirrored
FONT_BASE = 0xBBAC
VIEW = 0xBBBA
LIVES = 0xBBCD
ARRIVING = 0xBC02
ARRIVED = 0x70
CARRIED = 0xBC03
CARRIED_PLACES = 11
KNIGHT = 0xBC8E
KNIGHT_TOP = 0xBC9E
VILLAINS = 0xBD5E
SPARE_RECORD = 0xBDEE       # the last monster record, borrowed to draw from
SCRATCH = 0xF195            # an unused byte (#R$F195), for PUT_TILE's tile number
PERCENT = 0xBBFD
TRAP = 0x0000               # a return address nothing in the game reaches
STACK = 0x5E00              # the game's own stack top (#R$BDFE)

DRAW_SPRITE = 0xE3D9
DRAW_SPRITE_AT = 0xE3FF
PUT_TILE = 0xD425
PUT_EDGE = 0xD2B2
TILE_MASKS = 0xD4EF
DRAW_VILLAINS = 0xC1FD
DRAW_CARRIED = 0xC4A4
COLOUR_CARRIED = 0xC4DC
PRINT_HEADING = 0xC29A
PRINT_COMPASS = 0xC2C8
DRAW_LIVES = 0xCBEB         # the lives' part of NEW_LIFE
ADD_SCORE = 0xC2ED
PRINT_CODE = 0xCB1F
PRINT_PERCENTAGE = 0xBF36
DRAW_PANEL_FRAME = 0xC83F
DRAW_PLAY_FRAME = 0xCA55
PRINT_BORDER = 0xCA9D
FRAME_PIECES = 0xCAE5
FACING_LOOKS = 0xDCDC

# Where a sprite is drawn in the buffer for its picture: x on a byte
# boundary (so the plain run, #R$E49F, draws it; the shifted runs give the
# same picture a few pixels on), y a few lines up from the bottom.
SPRITE_X, SPRITE_Y = 64, 80
TILE_X, TILE_Y = 64, 72

SPRITE_SCALE = 2
TILE_SCALE = 2
CHAR_SCALE = 3
SCREEN_SCALE = 2

WHITE = (255, 255, 255, 255)
BLACK = (0, 0, 0, 255)
CLEAR = (0, 0, 0, 0)
KEPT = (90, 90, 140, 255)   # background a tile leaves alone, in the mask picture
INKS = [(0, 0, 0), (0, 0, 0xD7), (0xD7, 0, 0), (0xD7, 0, 0xD7),
        (0, 0xD7, 0), (0, 0xD7, 0xD7), (0xD7, 0xD7, 0), (0xD7, 0xD7, 0xD7)]
BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF),
          (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0), (0xFF, 0xFF, 0xFF)]

# Short names for what each sprite shows, by address, given after drawing
# each one. A name is a claim about the picture only: which villain the game
# calls what is not in its text, and where the code says what a thing does
# the Graphic table says which routine.
SPRITE_NAMES = {
    0x7017: "the front of the pit",
    0x70E9: "a piece of the back of the pit",
    0x713F: "a piece of the back of the pit",
    0x71A1: "a piece of the back of the pit",
    0x7213: "a piece of the back of the pit",
    0x7265: "a piece of the back of the pit",
    0x7297: "a curled shape with a scroll on top: perhaps a winged boot",
    0x7331: "a flaming face",
    0x73DB: "a flaming face, larger",
    0x74AF: "a flaming face",
    0x7691: "a spiky round monster, from behind",
    0x7735: "a spiky round monster, from behind",
    0x77DF: "a horned head, from behind",
    0x787D: "a horned head, from behind",
    0x791B: "a crested monster, from behind",
    0x79C5: "a crested monster, from behind",
    0x7B2F: "a puff, smallest",
    0x7B71: "a puff",
    0x7BB3: "a puff",
    0x7BF5: "a puff, largest",
    0x7C37: "a flask",
    0x7C79: "a hooded figure with a scythe, from behind",
    0x7D41: "a ghost",
    0x7E45: "a ghost",
    0x7F49: "a cross, lying down",
    0x7FA5: "a book",
    0x8019: "a hammer",
    0x8075: "an hourglass",
    0x810D: "a skeleton",
    0x81DB: "a horned monster with its arms up, from behind",
    0x829D: "a horned monster with its arms up, from behind",
    0x8359: "a spiral",
    0x838F: "a spiral, turned",
    0x83C5: "a spiral, turned",
    0x83FB: "a spiral, turned",
    0x8431: "a ball with spikes",
    0x8473: "a round ball",
    0x84B5: "a ball with spikes, the other way",
    0x84F7: "two crossed sticks",
    0x8539: "two crossed sticks, turning",
    0x857B: "the sticks end on",
    0x85BD: "two crossed sticks, turning",
    0x85FF: "a small disc",
    0x8641: "a disc",
    0x8683: "a disc with a mark",
    0x86C5: "a large disc with a three-lobed mark",
    0x8707: "a skeleton",
    0x87E1: "a skeleton, from behind",
    0x88BB: "a skeleton, from behind",
    0x8995: "a hooded figure with a scythe",
    0x8A63: "a dome, narrow",
    0x8ADD: "a dome",
    0x8B57: "a dome, wide",
    0x8BCB: "a blob",
    0x8C33: "a blob",
    0x8C9B: "a blob burst flat",
    0x8D03: "a long flat slug",
    0x8D8D: "a long flat slug",
    0x8E07: "a long flat slug",
    0x8E91: "a swarm of dots",
    0x8F05: "a swarm of dots",
    0x8F7F: "a swarm of dots",
    0x8FFF: "a crested monster with teeth",
    0x90A9: "a crested monster with teeth",
    0x9153: "a horned head",
    0x91F1: "a horned head",
    0x928F: "a spiky round monster, grinning",
    0x933F: "a spiky round monster, grinning",
    0x93EF: "a horned monster with its arms up",
    0x94AB: "a horned monster with its arms up",
    0x9567: "a hooded figure",
    0x9635: "a hooded figure, from behind",
}
TOP_NAME = "the knight's top half"
LEGS_NAME = "the knight's legs"


def _word(memory, address: int) -> int:
    return memory[address] | memory[address + 1] << 8


def _signed(byte: int) -> int:
    return byte - 256 if byte & 0x80 else byte


def _esc(text: str) -> str:
    return html.escape(text, quote=False)


def _plural(count: int, word: str, words: str | None = None) -> str:
    return f"{count} {word if count == 1 else (words or word + 's')}"


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


def _graphic_links(graphics) -> str:
    out = []
    values = sorted(graphics)
    start = None
    for index, value in enumerate(values):
        if start is None:
            start = value
        if index + 1 == len(values) or values[index + 1] != value + 1:
            if start == value:
                out.append(f'<a href="GraphicTable.html#graphic{start}">{start}</a>')
            else:
                out.append(f'<a href="GraphicTable.html#graphic{start}">{start}</a>-'
                           f'<a href="GraphicTable.html#graphic{value}">{value}</a>')
            start = None
    return ", ".join(out)


def _img(path: str, image, alt: str, scale: int = 1, cls: str = "kl-piece") -> str:
    return (f'<img class="{cls}" src="{path}" alt="{_esc(alt)}" '
            f'width="{image.width * scale}" height="{image.height * scale}">')


def _scaled(image, scale: int):
    from PIL import Image

    return image.resize((image.width * scale, image.height * scale), Image.NEAREST)


# --------------------------------------------------------------------------
# The listing: which addresses are entries, and what they are called.
# --------------------------------------------------------------------------

class Listing:
    """Entry starts, labels and titles from nightshade.skool, so that a #R
    link is made only to an entry that exists."""

    def __init__(self, skool: Path):
        self.labels: dict[int, str] = {}
        self.titles: dict[int, str] = {}
        self.missing = set()
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
        if address in self.titles:
            return f"#R${address:04X}({text})" if text else f"#R${address:04X}"
        return text or f"${address:04X}"

    def name(self, address: int) -> str:
        return self.labels.get(address, f"${address:04X}")

    def routine(self, address: int) -> str:
        """A routine by its label, linked; an entry point inside an entry is
        named with its offset, and its entry linked."""
        name = self.labels.get(address, f"${address:04X}")
        if address in self.titles:
            return f"#R${address:04X}({name})"
        entry = self.entry_of(address)
        if entry is None:
            return name
        return (f"{name}, {address - entry} bytes into "
                f"#R${entry:04X}({self.labels.get(entry, f'${entry:04X}')})")

    def check_links(self, body: str) -> str:
        def fix(match):
            address = int(match.group(1), 16)
            if not self.titles or address in self.titles:
                return match.group(0)
            self.missing.add(address)
            return match.group(2)[1:-1] if match.group(2) else f"${address:04X}"
        return re.sub(r"#R\$([0-9A-F]{4})(\([^()]*\))?", fix, body)


# --------------------------------------------------------------------------
# The game, and its code run on copies of it.
# --------------------------------------------------------------------------

TIME_LIMIT = 3500000 * 5    # five seconds of the machine's time for any one call


class Rig:
    """A game started as a player starts one, and the game's routines called
    on copies of it."""

    def __init__(self, snapshot: Path):
        import build_nightshade as bn

        self.bn = bn
        machine = bn.Machine(snapshot)
        steps = bn._start("1")
        machine.play(steps[:1], "the graphics pages: the menu")
        self.menu = list(machine.memory)
        machine.play(steps[1:] + [bn.At("the first turn", MAIN_LOOP)],
                     "the graphics pages: a game")
        self.game = list(machine.memory)
        self.tracer_class = type(machine.tracer)
        self.tape = bn.game_memory(snapshot)

    def simulator(self, memory):
        from skoolkit import CSimulator
        from skoolkit.simulator import Simulator

        simulator = (CSimulator or Simulator)(list(memory),
                                              state={"iff": 0, "im": 1, "tstates": 0})
        simulator.set_tracer(self.tracer_class(simulator))
        return simulator

    @staticmethod
    def call(simulator, start: int, what: str, stop: int = TRAP, **registers) -> None:
        """Run from start until the routine returns to TRAP (or reaches stop),
        with the registers given (ix, iy, hl, de, bc, a, a2); fail saying
        where it went instead."""
        from skoolkit.simutils import (A, B, C, D, E, H, L, IXh, IXl, IYh, IYl, PC, SP, T,
                                       xA)

        memory = simulator.memory
        memory[STACK - 2] = TRAP & 0xFF
        memory[STACK - 1] = TRAP >> 8
        simulator.registers[SP] = STACK - 2
        pairs = {"ix": (IXh, IXl), "iy": (IYh, IYl), "hl": (H, L), "de": (D, E), "bc": (B, C)}
        for name, value in registers.items():
            if name in pairs:
                high, low = pairs[name]
                simulator.registers[high], simulator.registers[low] = value >> 8, value & 0xFF
            elif name == "a":
                simulator.registers[A] = value
            elif name == "a2":
                simulator.registers[xA] = value
            else:
                raise ValueError(name)
        simulator.trace(start, stop, 0, simulator.registers[T] + TIME_LIMIT, False,
                        None, None, None, None, None)
        if simulator.registers[PC] != stop:
            raise RuntimeError(f"graphics: {what} never reached ${stop:04X} "
                               f"(PC ${simulator.registers[PC]:04X})")

    # ---- sprites --------------------------------------------------------

    def _sprite_runs(self, graphic: int, flags: int):
        runs = []
        for fill in (0x00, 0xFF):
            memory = list(self.game)
            memory[BUFFER:BUFFER + BUFFER_ROW * BUFFER_ROWS] = [fill] * (BUFFER_ROW * BUFFER_ROWS)
            memory[SPARE_RECORD:SPARE_RECORD + 16] = [0] * 16
            memory[SPARE_RECORD] = graphic
            memory[SPARE_RECORD + 7] = flags
            memory[SPARE_RECORD + 14] = SPRITE_X
            memory[SPARE_RECORD + 15] = SPRITE_Y
            memory[ARRIVING] = ARRIVED
            simulator = self.simulator(memory)
            self.call(simulator, DRAW_SPRITE_AT, f"graphic {graphic}", ix=SPARE_RECORD)
            runs.append(simulator.memory)
        return runs

    def sprite(self, graphic: int, mirrored: bool = False):
        """The sprite of a graphic as DRAW_SPRITE_AT draws it: white image,
        black mask, clear elsewhere; cut to the sprite's own size."""
        address = _word(self.game, nd.GRAPHICS + 2 * graphic)
        width, height = self.tape[address] & 0x0F, self.tape[address + 1]
        dark, light = self._sprite_runs(graphic, 0x40 if mirrored else 0)
        image = _three_colour(dark, light)
        left = SPRITE_X - BUFFER_X
        top = BUFFER_ROWS - 1 - (SPRITE_Y - BUFFER_Y) - (height - 1)
        return image.crop((left, top, left + 8 * width, top + height))

    def knight(self, facing: int):
        """His legs and top as a turn with this facing leaves them, drawn by
        DRAW_SPRITE -- projected, and offset, as in play."""
        simulator = self.simulator(self.game)
        memory = simulator.memory
        memory[KNIGHT + 6] = facing << 6           # no turn under way
        self.call(simulator, MAIN_LOOP, f"a turn facing {facing}", stop=MAIN_LOOP)
        state = list(simulator.memory)
        looks = (state[KNIGHT], state[KNIGHT + 7], state[KNIGHT_TOP], state[KNIGHT_TOP + 7])
        runs = []
        for fill in (0x00, 0xFF):
            memory = list(state)
            memory[BUFFER:BUFFER + BUFFER_ROW * BUFFER_ROWS] = [fill] * (BUFFER_ROW * BUFFER_ROWS)
            memory[ARRIVING] = ARRIVED
            simulator = self.simulator(memory)
            self.call(simulator, DRAW_SPRITE, "his legs", ix=KNIGHT)
            self.call(simulator, DRAW_SPRITE, "his top", ix=KNIGHT_TOP)
            runs.append(simulator.memory)
        image = _three_colour(*runs)
        return image.crop(image.getbbox()), looks

    def ending(self, pieces: list[tuple[int, int, int]]):
        """Graphics drawn one after another by DRAW_SPRITE_AT at screen places
        (graphic, x, y), on a clear buffer: white on black, as on the screen
        but for the colours, cut to what was drawn."""
        memory = list(self.game)
        memory[BUFFER:BUFFER + BUFFER_ROW * BUFFER_ROWS] = [0] * (BUFFER_ROW * BUFFER_ROWS)
        simulator = self.simulator(memory)
        for graphic, x, y in pieces:
            state = simulator.memory
            for offset in range(16):
                state[SPARE_RECORD + offset] = 0
            state[SPARE_RECORD], state[SPARE_RECORD + 14], state[SPARE_RECORD + 15] = graphic, x, y
            self.call(simulator, DRAW_SPRITE_AT, f"graphic {graphic}", ix=SPARE_RECORD)
        image = _buffer_bits(simulator.memory)
        box = image.convert("L").getbbox()
        return image.crop((box[0] - 4, box[1] - 4, box[2] + 4, box[3] + 4))

    # ---- tiles and edges --------------------------------------------------

    def _tile_run(self, x: int, mirrored: bool, fill: int, tile: int | None = None,
                  edge: int | None = None):
        memory = list(self.game)
        memory[BUFFER:BUFFER + BUFFER_ROW * BUFFER_ROWS] = [fill] * (BUFFER_ROW * BUFFER_ROWS)
        memory[DRAW_X], memory[DRAW_X + 1] = x, 0
        memory[DRAW_PASS] = 1 if mirrored else 0
        simulator = self.simulator(memory)
        if edge is None:
            simulator.memory[SCRATCH] = tile
            self.call(simulator, PUT_TILE, f"tile {tile}", iy=SCRATCH, de=TILE_Y << 8 | x)
        else:
            self.call(simulator, PUT_EDGE, f"edge picture ${edge:04X}", hl=edge,
                      de=TILE_Y << 8 | x)
        return simulator.memory

    def tile(self, number: int, height: int, mirrored: bool = False):
        memory = self._tile_run(TILE_X, mirrored, 0x00, tile=number)
        image = _buffer_bits(memory)
        left = TILE_X - BUFFER_X
        return image.crop((left, BUFFER_ROWS - height, left + 16, BUFFER_ROWS))

    def tile_kept(self, number: int, height: int, shift: int):
        """A tile at a shift, over a buffer of zeros and of ones: what differs
        is the background the masks keep."""
        runs = [self._tile_run(TILE_X + shift, False, fill, tile=number) for fill in (0, 0xFF)]
        from PIL import Image

        dark, light = _buffer_bits(runs[0]), _buffer_bits(runs[1])
        image = Image.new("RGBA", dark.size)
        out, a, b = image.load(), dark.load(), light.load()
        for y in range(image.height):
            for x in range(image.width):
                if a[x, y] != b[x, y]:
                    out[x, y] = KEPT
                else:
                    out[x, y] = a[x, y]
        left = TILE_X - BUFFER_X - 8
        return image.crop((left, BUFFER_ROWS - height - 4, left + 32, BUFFER_ROWS))

    def edge(self, address: int, height: int, mirrored: bool = False):
        memory = self._tile_run(TILE_X, mirrored, 0x00, edge=address)
        bits = _buffer_bits(memory)
        from PIL import Image

        image = Image.new("RGBA", bits.size, CLEAR)
        out, a = image.load(), bits.load()
        for y in range(image.height):
            for x in range(image.width):
                if a[x, y] == WHITE:
                    out[x, y] = WHITE
        left = TILE_X - BUFFER_X
        return image.crop((left, BUFFER_ROWS - height, left + 16, BUFFER_ROWS))


def _buffer_bits(memory):
    """The play area's buffer as white on black, the bottom row at the foot."""
    from PIL import Image

    image = Image.new("RGBA", (BUFFER_ROW * 8, BUFFER_ROWS), BLACK)
    pixels = image.load()
    for row in range(BUFFER_ROWS):
        base = BUFFER + BUFFER_ROW * row
        y = BUFFER_ROWS - 1 - row
        for column in range(BUFFER_ROW):
            byte = memory[base + column]
            if byte:
                for bit in range(8):
                    if byte & (0x80 >> bit):
                        pixels[column * 8 + bit, y] = WHITE
    return image


def _three_colour(dark, light):
    """Image from the run on zeros, mask from the run on ones."""
    from PIL import Image

    image = Image.new("RGBA", (BUFFER_ROW * 8, BUFFER_ROWS), CLEAR)
    pixels = image.load()
    for row in range(BUFFER_ROWS):
        base = BUFFER + BUFFER_ROW * row
        y = BUFFER_ROWS - 1 - row
        for column in range(BUFFER_ROW):
            a, b = dark[base + column], light[base + column]
            if a == 0 and b == 0xFF:
                continue
            for bit in range(8):
                mask = 0x80 >> bit
                if a & mask:
                    pixels[column * 8 + bit, y] = WHITE
                elif not b & mask:
                    pixels[column * 8 + bit, y] = BLACK
    return image


def screen_image(memory, cells=None):
    """The Spectrum's screen from $4000, in its colours; cut to (column,
    row, width, height) in character cells if given."""
    from PIL import Image

    image = Image.new("RGB", (256, 192))
    pixels = image.load()
    for y in range(192):
        address = 0x4000 | (y & 0xC0) << 5 | (y & 7) << 8 | (y & 0x38) << 2
        for column in range(32):
            byte = memory[address + column]
            attr = memory[0x5800 + (y // 8) * 32 + column]
            table = BRIGHT if attr & 0x40 else INKS
            ink, paper = table[attr & 7], table[attr >> 3 & 7]
            for bit in range(8):
                pixels[column * 8 + bit, y] = ink if byte & (0x80 >> bit) else paper
    if cells:
        column, row, width, height = cells
        image = image.crop((8 * column, 8 * row, 8 * (column + width), 8 * (row + height)))
    return image


def _screen_address(row: int, column: int) -> int:
    return 0x4000 | (row & 0x18) << 8 | (row & 7) << 5 | column


# --------------------------------------------------------------------------
# The game's data, read.
# --------------------------------------------------------------------------

def _operand(memory, address: int, opcode: list[int], offset: int) -> int:
    """The immediate operand of the instruction at address, after checking
    it is the instruction expected -- so a wrong address stops the build."""
    if list(memory[address:address + len(opcode)]) != opcode:
        raise ValueError(f"graphics: the instruction at ${address:04X} is not "
                         + " ".join(f"{b:02X}" for b in opcode))
    return memory[address + offset]


class Data:
    def __init__(self, memory):
        self.memory = memory
        self.sprite_of = [_word(memory, nd.GRAPHICS + 2 * g) for g in range(nd.GRAPHIC_COUNT)]
        self.update_of = [_word(memory, nd.UPDATES + 2 * g) for g in range(nd.GRAPHIC_COUNT)]
        self.sprites = nd.sprite_entries(memory)
        self.tiles = nd.tile_entries(memory)
        self.edges = nd.edge_entries(memory)
        self.tile_address = [_word(memory, nd.TILE_TABLE + 2 * t) for t in range(nd.TILE_COUNT)]
        self.tile_edge = [memory[nd.TILE_EDGES + t] for t in range(nd.TILE_COUNT)]
        self.edge_address = [_word(memory, nd.EDGE_TABLE + 2 * e) for e in range(nd.EDGE_COUNT)]
        # Buildings: each definition's table indices (type * 2 + view), and
        # for each tile number where it is used.
        self.building_indices = nd.building_starts(memory)
        self.tile_uses: dict[int, list[tuple[int, int, int, int]]] = {}
        for address in self.building_indices:
            for face in range(2):
                for column in range(8):
                    for level in range(2):
                        tile = memory[address + 16 * face + 2 * column + level]
                        self.tile_uses.setdefault(tile, []).append((address, face, column, level))
        self.cells_of_type = [0] * nd.CELL_TYPES
        for v in range(nd.MAP_SIZE):
            for u in range(nd.MAP_SIZE):
                kind = nd.cell(memory, u, v)
                if kind < nd.CELL_TYPES:
                    self.cells_of_type[kind] += 1
        self.masks = list(memory[TILE_MASKS:TILE_MASKS + 4])
        self.looks = list(memory[FACING_LOOKS:FACING_LOOKS + 4])
        self.kinds = self._kinds(memory)

    def _kinds(self, memory):
        """The kinds of record the game makes, with their half-sizes and
        drawing offsets, each read from where the game sets them."""
        def template(address):
            return (memory[address + 8], memory[address + 9],
                    _signed(memory[address + 12]), _signed(memory[address + 13]))

        ix = lambda address: _operand(memory, address, [0xDD, 0x36, memory[address + 2]], 3)
        iy = lambda address: _operand(memory, address, [0xFD, 0x36, memory[address + 2]], 3)
        hl = lambda address: _operand(memory, address, [0x36], 1)
        la = lambda address: _operand(memory, address, [0x3E], 1)
        legs, top = template(nd.START_RECORDS), template(nd.START_RECORDS + 16)
        monster = template(nd.MONSTER_RECORD)
        thrown_size = la(0xDB20)
        return [
            ("knight's legs", "16-21, 24-29", legs, nd.START_RECORDS, None),
            ("knight's top", "22, 30, 32-47", top, nd.START_RECORDS, "the second of the two"),
            ("object lying", "4-7", template(nd.OBJECT_RECORD), nd.OBJECT_RECORD, None),
            ("thrown object or antibody", "8-11, 80-95",
             (thrown_size, thrown_size, _signed(iy(0xDB28)), _signed(iy(0xDB2C))), 0xDAB7,
             None),
            ("villain", "96-111", template(nd.VILLAIN_RECORD), nd.VILLAIN_RECORD, None),
            ("monster", "128-131, then 64-79 or 112-127", monster, nd.MONSTER_RECORD,
             f"graphic 76 is given a half-size of {ix(0xC18C)} in V as it appears (#R$C164)"),
            ("find", "48-63", (la(0xC62C), la(0xC62C), _signed(iy(0xC634)), _signed(iy(0xC638))),
             0xC5CE, None),
            ("bonus", "2, 3", (ix(0xD7C7), ix(0xD7CB), _signed(ix(0xD7CF)), _signed(ix(0xD7D3))),
             0xD76C, None),
            ("creature", "136-139", (ix(0xBFD4), ix(0xBFD8), _signed(ix(0xBFDC)), _signed(ix(0xBFE0))),
             0xBF95, "put in a monster record, which keeps what it had where these are not "
                     "written: the fallback, all six records near the knight, changes only "
                     "the graphic"),
            ("sparkle", "140-143", (hl(0xD6F7), hl(0xD6FA), _signed(hl(0xD6FF)), _signed(hl(0xD702))),
             0xD6D6, None),
        ]


# --------------------------------------------------------------------------
# The groups: what each graphic is, from the update table and the code that
# gives graphics to records (the annotations of #R$D599 and each routine).
# --------------------------------------------------------------------------

# (key, title, graphics, text, mirrored by)
GROUPS = [
    ("empty", "Nothing", [0, 1, 23, 31],
     "An empty record is graphic 0, and the main loop still calls its routine, a RET "
     "(#R$D6D5). 1, 23 and 31 have the same routine and the same empty sprite; 23 and 31 sit "
     "in the gaps of the knight's runs, and nothing gives a record 1, 23 or 31.",
     "never drawn: the sprite has no width (#R$E3D9 draws nothing)"),
    ("legs", "The knight's legs", list(range(16, 22)) + list(range(24, 30)),
     "His own record (#R$DA7A). Bit 3 of the graphic is the view -- 16-21 from behind, "
     "24-29 from the front, with his face showing (the pictures say so, drawn on the "
     "<a href=\"Sprites.html#knight\">sprites page</a>: facing +U or -V he comes towards "
     "the viewer, facing +V or -U he goes away) -- and the low three bits count six walking frames, 0-5, which use "
     "four pictures: 16, 17, 18, 19, 18, 17 (#R$DCA8).",
     "by his facing and the view, from #R$DCDC (#R$DB89)"),
    ("top", "The knight's top", [22, 30] + list(range(32, 48)),
     "His second record, drawn over his legs (#R$D9EB): 32-37 match the frames 16-21 "
     "from behind and 40-45 the frames 24-29 from the front; 38, 39, 46 and 47 are the poses he strikes now and then, "
     "one turn in 32 when he is not turning, for two to nine turns; 22 and 30 are his arms thrown out when he walks into a wall. 32-47 enter "
     "the routine 21 bytes in, at TOP_FOLLOWS, past the wall test.",
     "the legs' flags, copied every turn (#R$D9EB)"),
    ("objects", "The four objects", list(range(4, 12)),
     "Put in random cells at every new game (#R$D88E), graphic 7 in record 0 down to 4 in "
     "record 3; taken up (#R$D942), they are carried as things 1-4 and thrown as 8-11 "
     "(#R$DAB7, #R$D80C), and each kills only the villain in the record 64 bytes on "
     "(#R$C554): the hammer the skeleton, the hourglass the hooded figure with the scythe, "
     "the cross the hooded figure, the book the ghost. A throw that meets a wall leaves it "
     "lying again, 4-7.",
     "never by their own code: a thrown object is a copy of the legs' record, so it keeps "
     "his mirroring, and keeps it when it falls (#R$DAB7, #R$D80C)"),
    ("finds", "Finds, antibodies and sparkles", list(range(48, 64)) + list(range(80, 96))
     + list(range(140, 144)),
     "A find (48-63) turns up in a building every sixteen turns (#R$C5CE), one of four kinds "
     "by the cell's type, four frames each; taken up it is an antibody, carried as thing 5-8 "
     "and thrown as 80-95 (#R$DAB7, #R$D7ED), the same sprites. When a villain dies its "
     "four sparkles (140-143, #R$D6D6, #R$D70A) are the first frames of the four kinds.",
     "finds and sparkles never; an antibody is a copy of the legs' record, so it keeps his "
     "mirroring (#R$DAB7)"),
    ("villains", "The four villains", list(range(96, 112)),
     "Put in random cells at every new game (#R$D8E7), 108 in record 0 down to 96 in record "
     "3; each walks at random (#R$D94F) and kills the knight at a touch. Four graphics "
     "each: bit 1 is which of two pictures by its facing and the view, bit 0 the walking "
     "frame, toggled every turn (#R$D978). The ghost has one picture from either side but "
     "two frames; the two hooded figures have two pictures and one frame; the skeleton "
     "has all four.",
     "facing along U (#R$D978)"),
    ("monsters", "The monsters of 112-127", list(range(112, 128)),
     "Four kinds, one for each villain, of four graphics each, chosen as they appear by the "
     "villain nearest (#R$C164); they walk, turn, and some turn towards the knight "
     "(#R$C083). Bit 1 of the graphic is the view, bit 0 the walking frame, as for the "
     "villains (#R$D978). What an antibody does to one depends on its kind and the "
     "antibody's (#R$C0D1).",
     "facing along U (#R$D978)"),
    ("wanderers", "The monsters of 64-79", list(range(64, 80)),
     "Four kinds of four frames each, stepped round by #R$CEF8; they wander at random and "
     "any antibody destroys them (#R$CE89). A monster of 112-127 struck the wrong way can "
     "turn into one (#R$C152).",
     "while the town is turned round (#R$CE89)"),
    ("creature", "The creature", list(range(136, 140)),
     "Put in the knight's cell every 256 turns (#R$BF95); it makes for him two units a turn "
     "and bursts at a wall (#R$BFF1). Four frames, three pictures: 139 is 137 again.",
     "never by its own code; it is put in a monster record and keeps that record's flags "
     "(read from #R$BF95, which does not write them)"),
    ("clouds", "Puffs", list(range(12, 16)) + list(range(128, 136)),
     "One set of four pictures, used three ways: 12-15 something vanishing, smallest first "
     "(#R$D7D8); 128-131 a monster appearing, the same pictures largest first (#R$C164); "
     "132-135 a villain dying, flashing the play area (#R$D847).",
     "never by their own code; a record that turns into a puff keeps its flags"),
    ("bonuses", "Bonuses", [2, 3],
     "Put near the knight whenever there is none (#R$D76C): 2 on an even turn, 3 on an odd "
     "one. 2 makes him faster for a while (#R$D727), 3 gives him his three hits back "
     "(#R$D74C).",
     "never"),
    ("ending", "The ending", list(range(144, 158)),
     "Ten records from #R$CCE4 once the four villains are gone (#R$CC56), drawn at a place "
     "on the screen with no projection (DRAW_SPRITE_AT, #R$E3D9): the five pieces of the back "
     "of a pit (153-157, #R$CD10), the four villains carried across and sunk into it one "
     "after another, two frames each (144-151, #R$CD58), and the pit's front (152), drawn "
     "last so that they sink behind it.",
     "never: the ending's records have no flags (#R$CC56)"),
]

WHAT_GRAPHIC = {
    0: "an empty record", 1: "nothing", 23: "nothing", 31: "nothing",
    2: "a bonus: a faster walk", 3: "a bonus: the hits back",
    4: "the book, lying", 5: "the cross, lying", 6: "the hourglass, lying", 7: "the hammer, lying",
    8: "the book, thrown", 9: "the cross, thrown", 10: "the hourglass, thrown",
    11: "the hammer, thrown",
    22: "arms out, from behind", 30: "arms out, from the front",
    38: "a pose, from behind", 39: "a pose, from behind",
    46: "a pose, from the front", 47: "a pose, from the front",
    152: "the pit's front",
}
for _g in range(16, 22):
    WHAT_GRAPHIC[_g] = f"walking frame {_g - 16}, from behind"
for _g in range(24, 30):
    WHAT_GRAPHIC[_g] = f"walking frame {_g - 24}, from the front"
for _g in range(32, 38):
    WHAT_GRAPHIC[_g] = f"with walking frame {_g - 32}, from behind"
for _g in range(40, 46):
    WHAT_GRAPHIC[_g] = f"with walking frame {_g - 40}, from the front"
_FIND_KINDS = ["a spiral", "a spiked ball", "crossed sticks", "a disc"]
for _k in range(4):
    for _f in range(4):
        WHAT_GRAPHIC[48 + 4 * _k + _f] = f"find kind {_k} ({_FIND_KINDS[_k]}), frame {_f}"
        WHAT_GRAPHIC[80 + 4 * _k + _f] = f"antibody kind {_k} ({_FIND_KINDS[_k]}), frame {_f}"
    WHAT_GRAPHIC[140 + _k] = f"a sparkle ({_FIND_KINDS[_k]})"
_VILLAINS = {96: "the ghost", 100: "the hooded figure", 104: "the hooded figure with the scythe",
             108: "the skeleton"}
for _base, _name in _VILLAINS.items():
    for _f in range(4):
        WHAT_GRAPHIC[_base + _f] = f"{_name}: picture {_f >> 1}, frame {_f & 1}"
for _i, _base in enumerate((96, 96, 100, 100, 104, 104, 108, 108)):
    WHAT_GRAPHIC[144 + _i] = f"{_VILLAINS[_base]} in the ending, frame {_i & 1}"
for _i in range(5):
    WHAT_GRAPHIC[153 + _i] = f"the back of the pit, piece {_i}"
_MONSTER_KINDS = ["the horned monster with its arms up", "the spiky round monster",
                  "the horned head", "the crested monster"]
for _k in range(4):
    for _f in range(4):
        WHAT_GRAPHIC[112 + 4 * _k + _f] = (f"monster kind {_k} ({_MONSTER_KINDS[_k]}): "
                                           f"picture {_f >> 1}, frame {_f & 1}")
_WANDERERS = ["a blob", "a swarm", "a dome", "a slug"]
for _k in range(4):
    for _f in range(4):
        WHAT_GRAPHIC[64 + 4 * _k + _f] = f"monster kind {_k} ({_WANDERERS[_k]}), frame {_f}"
for _f in range(4):
    WHAT_GRAPHIC[12 + _f] = f"vanishing, frame {_f}"
    WHAT_GRAPHIC[128 + _f] = f"a monster appearing, frame {_f}"
    WHAT_GRAPHIC[132 + _f] = f"a villain dying, frame {_f}"
    WHAT_GRAPHIC[136 + _f] = f"the creature, frame {_f}"


def _group_of(graphic: int) -> str:
    for key, _, graphics, _, _ in GROUPS:
        if graphic in graphics:
            return key
    raise ValueError(f"graphic {graphic} is in no group")


# --------------------------------------------------------------------------
# Tiles and edge pictures.
# --------------------------------------------------------------------------

def _tiles_page(data: Data, rig: Rig, listing: Listing, image_dir: Path) -> str:
    memory = data.memory
    face_names = ("first", "second")
    level_names = ("lower", "upper")
    unused = [a for a, _, numbers in data.tiles if not any(n in data.tile_uses for n in numbers)]
    heights = sorted({memory[a] for a, _, _ in data.tiles})
    # The heights by where the buildings use a tile: lower or upper.
    level_heights = [sorted({memory[data.tile_address[tile]]
                             for tile, uses in data.tile_uses.items()
                             for _, _, _, level in uses if level == wanted})
                     for wanted in (0, 1)]
    if all(len(h) == 1 for h in level_heights):
        wall = (f" Every tile a building uses as a lower tile is {level_heights[0][0]} lines "
                f"high and every one it uses as an upper tile {level_heights[1][0]}, so a wall "
                f"is {64 + level_heights[1][0]} lines from its foot to its top.")
    else:
        wall = (f" The lower tiles are {' or '.join(map(str, level_heights[0]))} lines high, "
                f"the upper ones {' or '.join(map(str, level_heights[1]))}.")
    # The masks at work: one tile at each of the four shifts over a buffer
    # of zeros and one of ones; grey is what the masks keep.
    demo_tile = 9
    demo_height = memory[data.tile_address[demo_tile]]
    shifts = []
    for shift in (0, 2, 4, 6):
        image = rig.tile_kept(demo_tile, demo_height, shift)
        name = f"tile_shift{shift}.png"
        image.save(image_dir / name)
        caption = (f"x + {shift}: masks ${data.masks[shift // 2]:02X} and "
                   f"${data.masks[shift // 2] ^ 0xFF:02X}" if shift else
                   "on a byte boundary: no masks")
        shifts.append(f"<td>{_img(f'{IMAGES}/{name}', image, f'Shifted {shift}', TILE_SCALE)}"
                      f"<br>{caption}</td>")
    lines = ['<div class="kl-list">',
             f"<p>A building's walls are drawn from tiles: {len(data.tiles)} pictures 16 pixels "
             f"wide, reached through the {nd.TILE_COUNT} words of {listing.ref(nd.TILE_TABLE)} "
             f"(tile numbers {_numbers([n for n in range(nd.TILE_COUNT) if data.tile_address.count(data.tile_address[n]) > 1])} "
             f"share a picture). Each is a height byte -- {' or '.join(str(h) for h in heights)} -- "
             "and two bytes a row, the bottom row first. A building's definition "
             f"({listing.ref(nd.BUILDINGS)}) gives each of its two faces eight columns of a "
             "lower tile and an upper tile, and a column of wall is the lower tile standing on "
             "the ground and the upper one 64 lines above it (#R$D3C2)." + wall + " The first face runs "
             "down the screen to the right and is drawn as the tiles are stored; the second "
             "runs up it and is drawn mirrored (DRAW_PASS). Each tile is shown here both ways, "
             f"drawn by the game's own {listing.routine(PUT_TILE)} in SkoolKit's simulator "
             "into the play area's buffer and read back.</p>",
             "<p>A tile is solid: the game writes its sixteen pixels over whatever is in the "
             "buffer, it does not mask them in as a sprite does. What does the masking is the "
             "pixels either side. Drawn at an x that is not a multiple of 8, a row of the tile "
             "covers three buffer bytes; the middle one is wholly the tile's, and in the first "
             "and the last the pixels outside the tile must be kept. "
             f"{listing.ref(TILE_MASKS)} gives, by the shift, the mask of the first byte's "
             "pixels to keep, and its complement keeps those in the last; "
             f"{listing.ref(PUT_TILE)} patches both into its ANDs before it draws. Here is "
             f"tile {demo_tile} drawn at each of the four shifts over a filled buffer: in grey "
             "the pixels the masks kept, in black and white the tile's own. Nothing is drawn "
             "at an odd x: the drawing ignores bit 0.</p>",
             '<table class="kl-table"><tr>' + "".join(shifts) + "</tr></table>",
             "<p>Under each column of a wall goes an edge picture, the line where the wall "
             "meets the ground (#R$D273); in front of the knight, where the walls themselves "
             "are left out so as not to hide him, a building is only its edge pictures all the "
             "way round (#R$D19D). They are at the foot of this page.</p>",
             "<p>None of these tiles is Knight Lore's, Alien 8's or Pentagram's: those games "
             "build their rooms from sprites (see "
             '<a href="../knightlore/Scenery.html">Knight Lore\'s scenery</a>), and none of '
             "these tiles' rows is found in any of their snapshots (searched when this page "
             "was written, 2026-09-28).</p>",
             '<h3 id="tiles">The tiles</h3>',
             '<table class="kl-table"><tr><th>Tile</th><th>As stored; mirrored</th>'
             "<th>Height</th><th>Edge picture</th><th>Used in</th></tr>"]
    for address, _, numbers in data.tiles:
        height = memory[address]
        plain = rig.tile(numbers[0], height)
        mirror = rig.tile(numbers[0], height, True)
        from PIL import ImageOps

        expected = _tile_decoded(memory, address)
        if list(plain.getdata()) != list(expected.getdata()) or \
                list(mirror.getdata()) != list(ImageOps.mirror(expected).getdata()):
            raise ValueError(f"graphics: tile ${address:04X} as the game draws it is not its bytes")
        names = [f"tile{address:04x}.png", f"tile{address:04x}m.png"]
        _scaled(plain, TILE_SCALE).save(image_dir / names[0])
        _scaled(mirror, TILE_SCALE).save(image_dir / names[1])
        pictures = (_img(f"{IMAGES}/{names[0]}", plain, f"Tile {numbers[0]}", TILE_SCALE)
                    + " " + _img(f"{IMAGES}/{names[1]}", mirror, f"Tile {numbers[0]} mirrored",
                                 TILE_SCALE))
        edges = sorted({data.tile_edge[n] for n in numbers})
        edge_text = ", ".join(f'<a href="#edge{e}">{e}</a>' for e in edges)
        places = [use for number in numbers for use in data.tile_uses.get(number, [])]
        by_building = sorted({building for building, _, _, _ in places},
                             key=lambda b: min(data.building_indices[b]))
        cells = {index >> 1 for building in by_building
                 for index in data.building_indices[building]}
        count = sum(data.cells_of_type[kind] for kind in cells)
        if places:
            lower = sum(1 for _, _, _, level in places if level == 0)
            first = sum(1 for _, face, _, _ in places if face == 0)
            used = (f"{_plural(len(places), 'column')} ({lower} {level_names[0]}, "
                    f"{len(places) - lower} {level_names[1]}; {first} on a {face_names[0]} face, "
                    f"{len(places) - first} on a {face_names[1]}) in "
                    f"{_plural(len(by_building), 'definition')}, for cell types "
                    f"{_numbers(cells)}: {_plural(count, 'cell')} of the town.<br>Definitions "
                    + ", ".join(listing.ref(b, str(min(data.building_indices[b])))
                                for b in by_building))
        else:
            used = "<i>no building</i>"
        lines.append(f'<tr id="tile{numbers[0]}"><td>{", ".join(str(n) for n in numbers)}<br>'
                     f"{listing.ref(address, listing.name(address))}</td><td>{pictures}</td>"
                     f"<td>{height}</td><td>{edge_text}</td><td>{used}</td></tr>")
    lines.append("</table>")
    if unused:
        lines.append("<p>No building uses the tiles at "
                     + ", ".join(listing.ref(a) for a in unused) + ".</p>")
    # Edge pictures.
    lines += ['<h3 id="edges">The edge pictures</h3>',
              f"<p>{len(data.edges)} pictures for {nd.EDGE_COUNT} numbers, in the tiles' "
              f"format, through {listing.ref(nd.EDGE_TABLE)}. Each tile has an edge number in "
              f"{listing.ref(nd.TILE_EDGES)}: 0 under a plain tile, 2 and 3 under the tiles "
              "whose lower part is an archway -- a short stub of line at one end, so that the "
              "archway is a gap in the building's outline. For the faces seen from behind "
              "#R$D273 XORs the number with 1, which swaps the stubs: 0 and 1 are the same "
              "picture. Unlike a tile an edge picture is ORed into the buffer "
              f"({listing.routine(PUT_EDGE)}), so it never hides what is under it; drawn here by "
              "that routine on an empty buffer, as stored and mirrored.</p>",
              '<table class="kl-table"><tr><th>Edge number</th><th>As stored; mirrored</th>'
              "<th>Height</th><th>Under the tiles</th></tr>"]
    for address, _, numbers in data.edges:
        height = memory[address]
        plain = rig.edge(address, height)
        mirror = rig.edge(address, height, True)
        expected = [pixel == WHITE for pixel in _tile_decoded(memory, address).getdata()]
        if [pixel == WHITE for pixel in plain.getdata()] != expected:
            raise ValueError(f"graphics: edge picture ${address:04X} as the game draws it is "
                             "not its bytes")
        names = [f"edge{address:04x}.png", f"edge{address:04x}m.png"]
        _scaled(plain, TILE_SCALE * 2).save(image_dir / names[0])
        _scaled(mirror, TILE_SCALE * 2).save(image_dir / names[1])
        pictures = (_img(f"{IMAGES}/{names[0]}", plain, f"Edge {numbers[0]}", TILE_SCALE * 2,
                         "kl-sprite")
                    + " " + _img(f"{IMAGES}/{names[1]}", mirror, f"Edge {numbers[0]} mirrored",
                                 TILE_SCALE * 2, "kl-sprite"))
        near = [t for t in range(nd.TILE_COUNT) if data.tile_edge[t] in numbers]
        far = [t for t in range(nd.TILE_COUNT) if data.tile_edge[t] ^ 1 in numbers]
        under = []
        if near:
            under.append("near faces: " + ", ".join(f'<a href="#tile{t}">{t}</a>' for t in near))
        if far:
            under.append("faces seen from behind: " + _numbers(far))
        lines.append(f'<tr id="edge{numbers[0]}"><td>{", ".join(str(n) for n in numbers)}<br>'
                     f"{listing.ref(address, listing.name(address))}</td><td>{pictures}</td>"
                     f"<td>{height}</td><td>{'<br>'.join(under) or 'none'}</td></tr>")
    lines.append("</table>")
    lines.append("</div>")
    body = "\n".join(lines)
    # Tile numbers that share a picture are anchored on its first number.
    for address, _, numbers in data.tiles:
        for number in numbers[1:]:
            body = body.replace(f'href="#tile{number}"', f'href="#tile{numbers[0]}"')
    for address, _, numbers in data.edges:
        for number in numbers[1:]:
            body = body.replace(f'href="#edge{number}"', f'href="#edge{numbers[0]}"')
    return body


def _tile_decoded(memory, address: int):
    """A tile from its bytes: a height byte, two bytes a row, bottom first."""
    from PIL import Image

    height = memory[address]
    image = Image.new("RGBA", (16, height), BLACK)
    pixels = image.load()
    for row in range(height):
        for column in range(2):
            byte = memory[address + 1 + 2 * row + column]
            for bit in range(8):
                if byte & (0x80 >> bit):
                    pixels[8 * column + bit, height - 1 - row] = WHITE
    return image


# --------------------------------------------------------------------------
# Sprites.
# --------------------------------------------------------------------------

# The groups on the Sprites page, in order: a sprite goes in the first whose
# graphics include one of its own.
SPRITE_GROUPS = [
    ("knight", "The knight", "legs top"),
    ("finds", "Finds and antibodies", "finds"),
    ("objects", "The four objects", "objects"),
    ("villains", "The four villains", "villains"),
    ("monsters", "The monsters of 112-127", "monsters"),
    ("wanderers", "The monsters of 64-79", "wanderers"),
    ("creature", "The creature", "creature"),
    ("clouds", "Puffs: vanishing, appearing and dying", "clouds"),
    ("bonuses", "Bonuses", "bonuses"),
    ("ending", "The ending's pit", "ending"),
    ("empty", "The empty sprite", "empty"),
]
# Groups whose sprites are drawn mirrored in play (see GROUPS).
MIRRORED_GROUPS = {"legs", "top", "villains", "monsters", "wanderers", "objects", "finds"}


def _sprite_name(address: int, graphics: list[int]) -> str:
    if address in SPRITE_NAMES:
        return SPRITE_NAMES[address]
    kinds = {_group_of(g) for g in graphics}
    # Bit 3 of the knight's graphics is the view from the front, his face
    # showing (#R$DCDC sets it facing +U or -V, towards the viewer).
    side = "from the front" if graphics and graphics[0] & 8 else "from behind"
    if kinds == {"legs"}:
        return f"{LEGS_NAME}, {side}"
    if kinds == {"top"}:
        return f"{TOP_NAME}, {side}"
    return ""


def _sprites_page(data: Data, rig: Rig, listing: Listing, image_dir: Path,
                  shared: dict | None) -> tuple[str, dict[int, str]]:
    memory = data.memory
    pictures: dict[int, str] = {}
    by_group: dict[str, list] = {key: [] for key, _, _ in SPRITE_GROUPS}
    for address, length, graphics in data.sprites:
        kinds = {_group_of(g) for g in graphics} if graphics else {"empty"}
        for key, _, members in SPRITE_GROUPS:
            if kinds & set(members.split()):
                by_group[key].append((address, length, graphics))
                by_group[key].sort(key=lambda entry: min(entry[2]) if entry[2] else 0)
                break
    drawn = 0
    from PIL import ImageOps
    import build_nightshade as bn

    rows_of: dict[str, list[str]] = {}
    for key, _, _ in SPRITE_GROUPS:
        rows = []
        for address, length, graphics in by_group[key]:
            width, height = memory[address] & 0x0F, memory[address + 1]
            label = listing.name(address)
            name = _sprite_name(address, graphics)
            cell = ""
            if width and height:
                graphic = graphics[0]
                plain = rig.sprite(graphic)
                expected = bn.sprite_image(memory, address, 1)
                if list(plain.getdata()) != list(expected.getdata()):
                    raise ValueError(f"graphics: sprite ${address:04X} as DRAW_SPRITE_AT draws "
                                     "it is not its bytes")
                picture = f"sprite{address:04x}.png"
                _scaled(plain, SPRITE_SCALE).save(image_dir / picture)
                pictures[address] = f"{IMAGES}/{picture}"
                cell = _img(pictures[address], plain, label, SPRITE_SCALE, "kl-sprite")
                drawn += 1
                if {_group_of(g) for g in graphics} & MIRRORED_GROUPS:
                    mirror = rig.sprite(graphic, True)
                    if list(mirror.getdata()) != list(ImageOps.mirror(expected).getdata()):
                        raise ValueError(f"graphics: sprite ${address:04X} mirrored by "
                                         "TURN_SPRITE is not its bytes mirrored")
                    mirrored = f"sprite{address:04x}m.png"
                    _scaled(mirror, SPRITE_SCALE).save(image_dir / mirrored)
                    cell += " " + _img(f"{IMAGES}/{mirrored}", mirror, f"{label} mirrored",
                                       SPRITE_SCALE, "kl-sprite")
                size = f"{width * 8} by {height}"
            else:
                size, name = "0 by 0", "nothing: the drawing code draws nothing"
            rows.append(f'<tr id="sprite{address:04x}"><td>{cell}</td>'
                        f"<td>{listing.ref(address, label)}<br>${address:04X}</td>"
                        f"<td>{_esc(name)}</td><td>{size}</td>"
                        f"<td>{_graphic_links(graphics) if graphics else '<i>none</i>'}</td></tr>")
        rows_of[key] = rows

    # The ending's pit, put together: its records from #R$CCE4, the back's
    # five first, then the front (record 9); and again with a villain between
    # them, at the x the villains stop at over the pit (four right of the
    # front's, #R$CD58) and part way down.
    records = [tuple(memory[nd.ENDING_RECORDS + 3 * i:nd.ENDING_RECORDS + 3 * i + 3])
               for i in range(nd.ENDING_COUNT)]
    pit = [r for r in records if r[0] >= 152]
    back, front = [r for r in pit if r[0] != 152], [r for r in pit if r[0] == 152]
    sinking = (records[5][0], front[0][1] + 4, front[0][2] + 8)
    ending_cells = []
    for name, pieces, caption in (
            ("ending_pit.png", back + front, "the back and the front, where #R$CCE4 puts them"),
            ("ending_sinking.png", back + [sinking] + front,
             f"graphic {sinking[0]} between them, placed by hand at x {sinking[1]}, "
             f"y {sinking[2]}")):
        image = rig.ending(pieces)
        _scaled(image, SPRITE_SCALE).save(image_dir / name)
        ending_cells.append(f"<td>{_img(f'{IMAGES}/{name}', image, 'The pit', SPRITE_SCALE)}"
                            f"<br>{caption}</td>")

    # The knight, whole, in his four facings.
    knights = []
    facing_names = ["+V", "+U", "-V", "-U"]
    for facing in range(4):
        image, (legs, legs_flags, top, top_flags) = rig.knight(facing)
        name = f"knight_facing{facing}.png"
        _scaled(image, SPRITE_SCALE).save(image_dir / name)
        knights.append(f"<td>{_img(f'{IMAGES}/{name}', image, 'The knight', SPRITE_SCALE, 'kl-sprite')}"
                       f"<br>facing {facing_names[facing]}: legs {legs}, top {top}"
                       f"{', mirrored' if legs_flags & 0x40 else ''}</td>")

    total = sum(1 for a, _, _ in data.sprites if memory[a] & 0x0F and memory[a + 1])
    lines = ['<div class="kl-list">',
             f"<p>Every sprite, {total} pictures and the empty sprite, in three runs "
             f"(from {listing.ref(nd.SPRITES_1, f'${nd.SPRITES_1:04X}')}, "
             f"{listing.ref(nd.SPRITES_2, f'${nd.SPRITES_2:04X}')} and "
             f"{listing.ref(nd.SPRITES_3, f'${nd.SPRITES_3:04X}')}) between the fonts and the tiles, grouped by what "
             "uses them. A sprite is a width byte (bits 0-3 the width in bytes; bits 6 and 7 "
             "say whether it is stored mirrored or upside down at the moment), a height byte, "
             "and a mask byte and an image byte for each byte of each row, the bottom row "
             "first: Knight Lore's format (see "
             '<a href="../knightlore/Sprites.html">Knight Lore\'s sprites</a>). Where the mask '
             "is set the buffer is cleared, and the image is laid in wherever it is set, so an "
             "image bit shows whatever the mask, a mask bit alone is black, and where both are "
             "clear the background shows through -- here the blue-grey.</p>",
             f"<p>Each picture is drawn by the game: DRAW_SPRITE_AT, an entry point of "
             f"{listing.ref(DRAW_SPRITE)}, "
             "run in SkoolKit's simulator on a spare object record holding one of the sprite's "
             "graphics, into the play area's buffer, once over zeros and once over ones -- which "
             "separates the image from the mask -- at twice the Spectrum's size. The sprites "
             "that are drawn mirrored in play are shown both ways, the second with bit 6 of the "
             f"record's flags set, so that {listing.routine(0xE353)} turns the stored bytes round "
             "before the drawing, as it does in the game. Every picture was checked against "
             "the sprite's bytes as the listing reads them, and the mirrored ones against "
             "those turned round: the same, pixel for pixel. No sprite is turned upside down: "
             "nothing sets the flag (#R$E353).</p>",
             "<p>Beside each are the graphic numbers that name it (see "
             '<a href="GraphicTable.html">the graphic table</a> for what each is and does). '
             "No sprite is wider than four bytes, the widest the drawing code's unrolled runs "
             "would take five (#R$E49F).</p>"]
    if shared is not None and not shared["sprites"]:
        lines.append(f"<p>None of them is another Ultimate game's: none of the {total} "
                     "sprites' mask and image bytes is found anywhere in the snapshot of "
                     + ", ".join(shared["games"][:-1])
                     + (" or " if len(shared["games"]) > 1 else "") + shared["games"][-1]
                     + " (searched at this build).</p>")
    elif shared is not None:
        lines.append("<p>Sprites found byte for byte in the other games' snapshots (searched "
                     "at this build): " + ", ".join(shared["sprites"]) + ".</p>")
    lines.append("<p>" + " -- ".join(f'<a href="#{key}">{title}</a>'
                                     for key, title, _ in SPRITE_GROUPS if rows_of[key]) + "</p>")
    for key, title, _ in SPRITE_GROUPS:
        if not rows_of[key]:
            continue
        lines.append(f'<h3 id="{key}">{title}</h3>')
        text = {
            "knight": "The knight is two records, legs and top, each with its own sprite "
                      "(#R$D9EB, #R$DA7A). Here he is whole in his four facings, as the game "
                      "draws him: from a real game, the facing poked into his legs' record at "
                      "the start of a turn and the turn run (#R$DB89 gives the legs their "
                      "picture and mirroring from #R$DCDC, the top copies them), then his two "
                      "records drawn by DRAW_SPRITE (#R$E3D9) with the projection and each "
                      "record's own drawing offset -- the top is drawn 11 lines above the "
                      "legs. Facing +U or -V he comes towards the viewer and is seen from the "
                      "front, his face showing (legs 24-29, top 40-45); facing +V or -U he "
                      "goes away and is seen from behind (16-21, 32-37); the mirroring gives "
                      "the second of each pair.",
            "finds": "Four kinds of four frames. A find wanders about a building until it "
                     "is taken up, and is thrown as an antibody with the same pictures; the "
                     "first frame of each kind is also a sparkle from a dead villain.",
            "objects": "Each is drawn the same lying (4-7) and thrown (8-11).",
            "villains": "Up to two pictures each -- which one by its facing and the view -- "
                        "and two walking frames: the ghost has one picture and two frames, "
                        "the hooded figures two pictures and one frame, the skeleton two of "
                        "each. The same sprites are the ending's villains (144-151).",
            "monsters": "Four kinds, each seen from in front and from behind, two frames each.",
            "wanderers": "Four kinds, each with three pictures for its four frames: the "
                         "second is also the fourth.",
            "creature": "Three pictures for four frames.",
            "clouds": "One set of four, played small to large for a thing vanishing and a "
                      "villain dying, and large to small for a monster appearing.",
            "bonuses": "The faster walk and the hits back.",
            "ending": "Drawn only in the ending, at the screen positions of #R$CCE4, and "
                      "coloured by the attributes #R$CD10 gives them: the pieces are mostly "
                      "mask, the dark of the pit, with lines of stone in white.",
            "empty": "No width and no height; graphics 0, 1, 23 and 31 name it.",
        }[key]
        lines.append(f"<p>{text}</p>")
        if key == "ending":
            lines.append("<p>Put together by the game's DRAW_SPRITE_AT in the order the main loop "
                         "updates the records, white on black as they are on the screen but for "
                         "the colours; the second with one of the villains of the ending drawn "
                         "between the back and the front, as it is while it sinks:</p>")
            lines.append('<table class="kl-table"><tr>' + "".join(ending_cells)
                         + "</tr></table>")
        if key == "knight":
            lines.append('<table class="kl-table"><tr>' + "".join(knights) + "</tr></table>")
        lines.append('<table class="kl-table"><tr><th>Sprite</th><th>Entry</th>'
                     "<th>What it shows</th><th>Size</th><th>Graphics</th></tr>")
        lines += rows_of[key]
        lines.append("</table>")
    lines.append("</div>")
    return "\n".join(lines), pictures


# --------------------------------------------------------------------------
# The graphic table.
# --------------------------------------------------------------------------

def _graphic_table_page(data: Data, listing: Listing, pictures: dict[int, str]) -> str:
    memory = data.memory
    kinds_rows = []
    for name, graphics, (su, sv, ox, oy), source, note in data.kinds:
        kinds_rows.append(f"<tr><td>{_esc(name)}</td><td>{graphics}</td><td>{su}, {sv}</td>"
                          f"<td>{ox:+d}, {oy:+d}</td><td>{listing.ref(source)}"
                          + (f"; {note}" if note else "") + "</td></tr>")
    lines = ['<div class="kl-list">',
             f"<p>An object record's first byte is its graphic, one of {nd.GRAPHIC_COUNT}, and "
             "it decides everything else about the thing: the sprite it is drawn with, through "
             f"{listing.ref(nd.GRAPHICS)} (#R$E353), and the update routine the main loop runs "
             f"for it every turn, through {listing.ref(nd.UPDATES)} and the dispatcher "
             "(#R$D593, which jumps by way of NMIADD, one of the tape's protections). There is "
             "no frame number: a thing animates, turns or becomes something else by changing "
             "its graphic, and the graphics come in runs of four -- four frames, or two "
             "pictures of two frames -- that share a routine. Many graphics share a sprite: "
             "the four objects are the same thrown or lying, the finds the same as the "
             "antibodies, and one set of puffs serves three purposes.</p>",
             "<p>What is not in the graphic is in the record. Where a sprite is drawn is the "
             "record's place projected (#R$D4F3) plus its drawing offset (+C, +D), which puts "
             "the sprite's bottom left corner there; how big the thing is, for touching and "
             "for walls, is its half-sizes (+8, +9). The game sets both when it makes a "
             "record, by the kind of thing, and a record keeps them as its graphic changes. "
             "Read from where each is set:</p>",
             '<table class="kl-table"><tr><th>Record</th><th>Graphics</th><th>Half-size U, V</th>'
             "<th>Drawing offset x, y</th><th>Set by</th></tr>" + "".join(kinds_rows) + "</table>",
             "<p>A half-size of 16 is a thing 32 units across, an eighth of a cell; the offset "
             "of -12 centres a sprite three bytes wide on its place, -8 one two bytes wide. So "
             "a thrown object, three bytes wide with the antibodies' -8, is drawn four pixels "
             "right of where it lay (read from the code; not looked for in play). The ending's records have "
             "none: they are drawn where #R$CCE4 puts them, with no projection.</p>",
             "<p>Mirroring is bit 6 of the flags (+7), and the routines that set it are "
             "given with each group below. Bit 7 would turn a sprite upside down and nothing "
             "sets it.</p>",
             "<p>" + " -- ".join(f'<a href="#{key}">{title}</a>' for key, title, _, _, _ in GROUPS)
             + "</p>"]
    for key, title, graphics, text, mirrored in GROUPS:
        lines += [f'<h3 id="{key}">{title}</h3>', f"<p>{text}</p>",
                  f"<p>Mirrored: {mirrored}.</p>",
                  '<table class="kl-table"><tr><th>Graphic</th><th>Sprite</th>'
                  "<th>What it is</th><th>Update routine</th></tr>"]
        rows = []
        for graphic in sorted(graphics):
            sprite = data.sprite_of[graphic]
            picture = pictures.get(sprite)
            cell = (f'<a href="Sprites.html#sprite{sprite:04x}"><img class="kl-thumb" '
                    f'src="{picture}" alt=""></a><br>' if picture else "")
            width, height = memory[sprite] & 0x0F, memory[sprite + 1]
            cell += (listing.ref(sprite, f"${sprite:04X}")
                     + (f", {width * 8} by {height}" if width else ", empty"))
            routine = listing.routine(data.update_of[graphic])
            rows.append([graphic, cell, _esc(WHAT_GRAPHIC.get(graphic, "")), routine])
        # A run of rows with the same sprite or routine shares one cell.
        spans = {}
        for column in (1, 3):
            start = 0
            while start < len(rows):
                end = start
                while end + 1 < len(rows) and rows[end + 1][column] == rows[start][column] \
                        and rows[end + 1][0] == rows[end][0] + 1:
                    end += 1
                spans[(start, column)] = end - start + 1
                for skipped in range(start + 1, end + 1):
                    spans[(skipped, column)] = 0
                start = end + 1
        for number, (graphic, cell, shows, routine) in enumerate(rows):
            text_row = f'<tr id="graphic{graphic}"><td>{graphic}</td>'
            for column, value in ((1, cell), (2, shows), (3, routine)):
                span = spans.get((number, column), 1)
                if span == 1:
                    text_row += f"<td>{value}</td>"
                elif span > 1:
                    text_row += f'<td rowspan="{span}">{value}</td>'
            lines.append(text_row + "</tr>")
        lines.append("</table>")
    lines.append("</div>")
    return "\n".join(lines)


# --------------------------------------------------------------------------
# The panel.
# --------------------------------------------------------------------------

def _char_blocks(rig: Rig, address: int, blocks: list[list[list[int]]]):
    """Characters from address, printed by the game's PRINT_CODE (#R$CB19)
    onto a cleared screen in blocks -- each a list of rows of codes, as the
    game puts them together -- with a character's gap between blocks."""
    simulator = rig.simulator(rig.game)
    memory = simulator.memory
    for index in range(0x4000, 0x5800):
        memory[index] = 0
    for index in range(0x5800, 0x5B00):
        memory[index] = 0x47
    memory[FONT_BASE], memory[FONT_BASE + 1] = address & 0xFF, address >> 8
    column, row, tallest, used = 0, 0, 0, 0
    for block in blocks:
        width = max(len(line) for line in block)
        if column + width > 32:
            column, row, tallest = 0, row + tallest + 1, 0
        for y, line in enumerate(block):
            for x, code in enumerate(line):
                rig.call(simulator, PRINT_CODE, f"character {code}", a=code,
                         hl=_screen_address(row + y, column + x))
        tallest = max(tallest, len(block))
        used = max(used, column + width)
        column += width + 1
    return screen_image(simulator.memory, (0, 0, used, row + tallest))


def _panel_page(data: Data, rig: Rig, listing: Listing, image_dir: Path) -> str:
    memory = data.memory
    # The screen at the top of the first turn of a game.
    start = screen_image(rig.game)
    _scaled(start, SCREEN_SCALE).save(image_dir / "panel_start.png")
    menu = screen_image(rig.menu)
    _scaled(menu, SCREEN_SCALE).save(image_dir / "panel_menu.png")
    # Staged: all eight things carried, two villains destroyed, two lives
    # lost, the town turned round, and a score.
    simulator = rig.simulator(rig.game)
    state = simulator.memory
    knight_column, knight_row = state[KNIGHT + 2], state[KNIGHT + 4]
    for record in range(4):
        base = VILLAINS + 16 * record
        if record in (1, 3):
            state[base] = 0
        else:
            # Far from the knight, so that no carried object flashes (#R$C4DC).
            state[base + 2] = (knight_column + 16) & 31
            state[base + 4] = (knight_row + 16) & 31
    rig.call(simulator, DRAW_VILLAINS, "the villains")
    for place in range(8):
        state[CARRIED + place] = place + 1
        rig.call(simulator, DRAW_CARRIED, f"carried thing {place + 1}", hl=CARRIED + place,
                 bc=(CARRIED_PLACES - place) << 8)
    rig.call(simulator, COLOUR_CARRIED, "the carried things' colours")
    state[LIVES] = 3
    rig.call(simulator, DRAW_LIVES, "the lives")
    state[VIEW] = 1
    rig.call(simulator, PRINT_HEADING, "the heading")
    rig.call(simulator, ADD_SCORE, "the score", bc=0x2525)
    staged = screen_image(simulator.memory)
    _scaled(staged, SCREEN_SCALE).save(image_dir / "panel_staged.png")
    # The character sets.
    sets = [("panel_frame", nd.PANEL_CHARS, nd.PANEL_CHAR_COUNT, "the frame round the carried "
             f"things, printed by {listing.ref(DRAW_PANEL_FRAME)} in bright magenta: 0 the top of "
             "an upright, 1 an upright, 2 the left-hand bottom corner, 3 a length of the bar "
             "along the bottom and 4 the right-hand corner; here the top of an upright over two "
             "lengths of it, and the foot as the game prints it, 2, 3, 3, 4"),
            ("panel_border", nd.BORDER_CHARS, nd.BORDER_CHAR_COUNT, "the pieces of the frame "
             f"round the play area ({listing.ref(DRAW_PLAY_FRAME)}, yellow on red) and of the "
             f"border round the menu and the screen after a game ({listing.ref(PRINT_BORDER)}, "
             f"bright yellow on blue), four to a piece two characters square as "
             f"{listing.ref(FRAME_PIECES)} arranges them; here its six pieces: the "
             "corners, top left, top right, bottom left and bottom right, then a length of the "
             "top or the bottom and a length of a side"),
            ("panel_icons", nd.ICONS, nd.ICON_CHARS, "the carried things, four characters "
             f"each, two over two ({listing.routine(DRAW_CARRIED)}): first the blank of an empty "
             "place, then things 1-4, the objects (the book, the cross, the hourglass, the "
             "hammer), and 5-8, the four kinds of antibody"),
            ("panel_compass", nd.PANEL_ICONS, nd.PANEL_ICON_CHARS, "the compass, stored "
             "as its two rows of four and printed as two blocks of two by two by "
             f"{listing.ref(PRINT_COMPASS)}; the heading, four characters for each view, north "
             f"and south ({listing.ref(PRINT_HEADING)}); and a life, two by four (#R$CC1D)")]
    strips = []
    # Each set laid out as the game puts it together: the frame's upright and
    # its foot (#R$C83F: codes 2, 3, 3, 4 along the bottom row); the six pieces of #R$CAE5, two by two; each carried
    # thing two by two (#R$C4A4); the compass two rows of four (#R$C2DF), each
    # heading a row of four, a life two by four (#R$CC2E).
    pieces = list(memory[FRAME_PIECES:FRAME_PIECES + 24])
    layouts = {
        "panel_frame": [[[0], [1], [1]], [[2, 3, 3, 4]]],
        "panel_border": [[pieces[4 * p:4 * p + 2], pieces[4 * p + 2:4 * p + 4]] for p in range(6)],
        "panel_icons": [[[4 * t, 4 * t + 1], [4 * t + 2, 4 * t + 3]] for t in range(9)],
        "panel_compass": [[[0, 1, 2, 3], [4, 5, 6, 7]], [[8, 9, 10, 11]], [[12, 13, 14, 15]],
                          [[16, 17], [18, 19], [20, 21], [22, 23]]],
    }
    for name, address, count, text in sets:
        image = _char_blocks(rig, address, layouts[name])
        _scaled(image, CHAR_SCALE).save(image_dir / f"{name}.png")
        strips.append(f"<p>{listing.ref(address, listing.name(address))}, "
                      f"{_plural(count, 'character')}: {text}.</p>"
                      + _img(f"{IMAGES}/{name}.png", image, name, CHAR_SCALE))
    lines = ['<div class="kl-list">',
             "<p>The play area is only the middle of the screen, 22 characters by 14, in its "
             "frame; the game buffers that part alone (#R$E5C4) and prints everything else "
             "straight onto the screen, once when a game starts and again only when something "
             "changes. Down the left, in a frame of its own, are the eleven places for what the "
             "knight carries; along the bottom his lives, the score, the four villains, the "
             "compass and the heading.</p>",
             "<p>Here is the whole screen at the top of the first turn of a game, as the game "
             "drew it in SkoolKit's simulator (read from the screen, colours and all): #R$BE0F "
             "has drawn the frames, the heading over the score and the score, the compass and "
             "NORTH, five white knights for the lives (#R$CBAC) and the villains, still "
             "about, as outlines (#R$C1FD).</p>",
             _img(f"{IMAGES}/panel_start.png", start, "A game starting", SCREEN_SCALE, "kl-scene"),
             "<p>The same, staged by calling the game's own routines on it: all eight kinds of "
             f"thing carried ({listing.routine(DRAW_CARRIED)} for each place, then "
             f"{listing.ref(COLOUR_CARRIED)} for the colours); the villains of records 1 and 3 "
             f"-- the hooded figure with the scythe and the ghost -- destroyed and "
             f"{listing.ref(DRAW_VILLAINS)} run again, which draws them as pictures in the "
             "colour of the object that kills them; two lives lost (the lives' part of "
             f"{listing.ref(0xCBAC)}: blue knights for the lost); the town turned round "
             f"({listing.ref(PRINT_HEADING)}: SOUTH, in magenta); and 252500 added to the "
             f"score ({listing.ref(ADD_SCORE)}). The play area is the first turn's.</p>",
             _img(f"{IMAGES}/panel_staged.png", staged, "The panel, staged", SCREEN_SCALE,
                  "kl-scene"),
             "<p>A villain still about is drawn from its sprite's first standing picture -- "
             "108, 104, 100 and 96 -- as the mask byte of each pair less the image byte, which "
             "comes out as its outline, in white; a dead one as the image bytes, its picture, "
             "in colour (#R$C1FD). The carried things are coloured every turn: an object in "
             "the colour its villain is drawn in once dead, an antibody by its kind; an object "
             "whose villain is within five cells flashes through the antibodies' colours "
             "instead, the game's hint (#R$C4DC).</p>",
             '<h3 id="border">The border</h3>',
             f"<p>{listing.ref(PRINT_BORDER)} draws the border round the whole screen for the "
             "menu and for the screen after a game, in the pieces of the play area's frame; "
             "here round the menu, as the game shows it at the first pass of the menu's loop "
             "(#R$C8CA).</p>",
             _img(f"{IMAGES}/panel_menu.png", menu, "The menu", SCREEN_SCALE, "kl-scene"),
             '<h3 id="characters">The panel\'s characters</h3>',
             "<p>The panel is printed a character at a time by the text printer (#R$CB19), each "
             "set with FONT_BASE pointed at its own characters, and each character eight bytes, "
             "the top row first. Printed here by the game's PRINT_CODE, put together as the "
             "game puts them, in white; the game colours them as it prints (#R$CB5B).</p>"]
    lines += strips
    lines += ["<p>None of these characters is found in Knight Lore's, Alien 8's or Pentagram's "
              "snapshots but one plain bar of the border's (searched): the panel is "
              'Nightshade\'s own. Compare <a href="../alien8/Objects.html#screen">Alien 8\'s '
              "panel</a>, drawn from sprites.</p>",
              "</div>"]
    return "\n".join(lines)


# --------------------------------------------------------------------------
# The font.
# --------------------------------------------------------------------------

def _font_page(data: Data, rig: Rig, listing: Listing, image_dir: Path,
               shared: dict | None) -> str:
    memory = data.memory
    text_base = nd.FONT - 8 * nd.FONT_FIRST
    # Each character printed by PRINT_CODE with the text base, as the
    # printer prints a letter's code.
    simulator = rig.simulator(rig.game)
    screen = simulator.memory
    font_dir = image_dir / "font"
    font_dir.mkdir(parents=True, exist_ok=True)
    cells = []
    for index in range(nd.FONT_CHARS):
        code = nd.FONT_FIRST + index
        for address in range(0x4000, 0x4800):
            screen[address] = 0
        for address in range(0x5800, 0x5900):
            screen[address] = 0x47
        screen[FONT_BASE], screen[FONT_BASE + 1] = text_base & 0xFF, text_base >> 8
        rig.call(simulator, PRINT_CODE, f"code ${code:02X}", a=code, hl=0x4000)
        image = screen_image(screen, (0, 0, 1, 1))
        name = f"char{code:02x}.png"
        _scaled(image, CHAR_SCALE).save(font_dir / name)
        shown = {";": "copyright sign", ":": "full stop", "=": "per cent sign"}.get(chr(code))
        label = chr(code) if chr(code).isalnum() else f"${code:02X}"
        cells.append(f'<td><img class="kl-thumb" src="{IMAGES}/font/{name}" alt="{_esc(label)}">'
                     f"<br>{_esc(label)}" + (f"<br><small>{shown}</small>" if shown else "")
                     + "</td>")
    rows = "".join("<tr>" + "".join(cells[i:i + 11]) + "</tr>" for i in range(0, len(cells), 11))
    blanks = [nd.FONT_FIRST + i for i in range(nd.FONT_CHARS)
              if not any(memory[nd.FONT + 8 * i:nd.FONT + 8 * i + 8])]
    # The percentage at 100, printed as #R$BF36 prints it: with the text
    # font's base left over from the lines before it, and with the digits'.
    hundreds = []
    for base, what in ((text_base, "as the game prints it"), (nd.FONT, "with the digits' base")):
        simulator = rig.simulator(rig.game)
        state = simulator.memory
        for address in range(0x4000, 0x4800):
            state[address] = 0
        for address in range(0x5800, 0x5900):
            state[address] = 0x45
        state[PERCENT], state[PERCENT + 1] = 0x01, 0x00
        state[FONT_BASE], state[FONT_BASE + 1] = base & 0xFF, base >> 8
        rig.call(simulator, PRINT_PERCENTAGE, "the percentage", hl=0x4000, a2=0x45)
        image = screen_image(state, (0, 0, 4, 1))
        name = f"percent_{'text' if base == text_base else 'digits'}.png"
        _scaled(image, CHAR_SCALE).save(font_dir / name)
        hundreds.append(f"<td>{_img(f'{IMAGES}/font/{name}', image, what, CHAR_SCALE)}"
                        f"<br>{what}</td>")
    lines = ['<div class="kl-list">',
             f"<p>{nd.FONT_CHARS} characters of 8 by 8 pixels at {listing.ref(nd.FONT)}, one font "
             "for everything the game writes: the menu, the panel's heading and the score, the "
             "screen after a game. Each is eight bytes, the top row first, and the printer "
             "(#R$CB19) finds one at FONT_BASE plus eight times its code. For text FONT_BASE is "
             "384 bytes below the font (#R$C9EF, #R$C9FC), so that the codes are ASCII: $30 is "
             "the 0, $41 the A. For numbers it is the font itself (#R$C314), so that a digit's "
             "value is its code. There is no lower case, and a space, which would be below the "
             f"font, is printed as code ${0x3C:02X}, one of the {_plural(len(blanks), 'blank')} ("
             + ", ".join(f"${c:02X}" for c in blanks) + "). Three signs are where ASCII has "
             "others: the semicolon's code is a copyright sign, the colon's a full stop and "
             "the equals sign's a per cent sign.</p>",
             "<p>Printed here by the game's PRINT_CODE with the text base, a character at a "
             "time, in bright white:</p>",
             '<table class="kl-table">' + rows + "</table>"]
    if shared is not None and shared.get("font"):
        lines.append("<p>" + shared["font"] + "</p>")
    lines += ['<h3 id="hundred">A hundred per cent</h3>',
              "<p>The percentage after a game is printed by #R$BF36, and at a hundred it goes "
              "into the digits' printer past the instructions that set FONT_BASE (#R$C314): "
              "the text printed just before has left it at the text base, where codes 0 and 1 "
              "are bytes of the buildings. Both ways, by the game's own routine with the "
              "percentage set to 100:</p>",
              '<table class="kl-table"><tr>' + "".join(hundreds) + "</tr></table>",
              "</div>"]
    return "\n".join(lines)


# --------------------------------------------------------------------------
# What the other Ultimate games share.
# --------------------------------------------------------------------------

def _char_name(code: int) -> str:
    """A character of the font as the game draws it."""
    return {":": "the full stop", ";": "the copyright sign",
            "=": "the per cent sign"}.get(chr(code), chr(code))


NEIGHBOURS = [("Knight Lore", "knightlore/knightlore.sna", 0x6108, 40),
              ("Alien 8", "alien8/alien8.z80", 0x6308, 43),
              ("Pentagram", "pentagram/pentagram.z80", 0x8355, 43)]


def neighbours(memory, snapshot: Path) -> dict | None:
    """Search the other games' snapshots, where they have been built, for
    Nightshade's sprites and font characters."""
    from skoolkit.snapshot import Snapshot

    root = snapshot.resolve().parent.parent
    found = {}
    for name, path, font, count in NEIGHBOURS:
        if (root / path).exists():
            found[name] = (bytes(Snapshot.get(str(root / path)).memory[0x4000:0x10000]),
                           font - 0x4000, count)
    if not found:
        return None
    result = {"games": list(found), "sprites": []}
    for address, length, _ in nd.sprite_entries(memory):
        if length > 2:
            body = bytes(memory[address + 2:address + length])
            for name, (other, _, _) in found.items():
                if other.find(body) >= 0:
                    result["sprites"].append(f"${address:04X} in {name}")
    sentences = []
    for name, (other, font, count) in found.items():
        theirs = [other[font + 8 * i:font + 8 * i + 8] for i in range(count)]
        same, where = [], []
        for index in range(nd.FONT_CHARS):
            mine = bytes(memory[nd.FONT + 8 * index:nd.FONT + 8 * index + 8])
            if not any(mine):
                continue
            if mine in theirs:
                same.append(_char_name(nd.FONT_FIRST + index))
                where.append(theirs.index(mine))
        drawn = [_char_name(nd.FONT_FIRST + i) for i in range(nd.FONT_CHARS)
                 if any(memory[nd.FONT + 8 * i:nd.FONT + 8 * i + 8])]
        if len(same) == len(drawn):
            sentences.append(f"every one of the {len(drawn)} drawn characters is one of "
                             f"{name}'s, byte for byte")
        elif 2 * len(same) > len(drawn):
            missing = [c for c in drawn if c not in same]
            sentences.append(f"all but {', '.join(missing)} are {name}'s")
        elif same:
            sentences.append(f"only {len(same)} are {name}'s ("
                             + ", ".join(same) + "), at other codes")
        else:
            sentences.append(f"none is {name}'s")
    result["font"] = ("Compared with the fonts of the other Ultimate games at this build, "
                      "character by character: " + "; ".join(sentences) + ". Knight Lore's "
                      "font has the digits and then the letters, with the full stop, the "
                      "copyright sign and the per cent sign after them; Nightshade's holds the "
                      "same characters rearranged into ASCII order, so that its printer can "
                      "take a letter's own code (see "
                      '<a href="../alien8/Sprites.html#font">Alien 8\'s font</a> and '
                      '<a href="../pentagram/Sprites.html">Pentagram\'s</a>).'
                      if "Knight Lore" in found else
                      "Compared with the fonts of " + ", ".join(found) + ": "
                      + "; ".join(sentences) + ".")
    return result


# --------------------------------------------------------------------------
# Together.
# --------------------------------------------------------------------------

def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    """Draw the pictures into html_dir/images/graphics and return the Tiles,
    GraphicTable, Sprites, Panel and Font sections."""
    import build_nightshade as bn

    memory = bn.game_memory(snapshot)
    listing = Listing(snapshot.with_name("nightshade.skool"))
    data = Data(memory)
    image_dir = html_dir / "images" / "graphics"
    image_dir.mkdir(parents=True, exist_ok=True)
    log("  graphics: starting a game to draw with...")
    rig = Rig(snapshot)
    shared = neighbours(memory, snapshot)
    log("  graphics: tiles and edge pictures...")
    tiles = _tiles_page(data, rig, listing, image_dir)
    log("  graphics: sprites...")
    sprites, pictures = _sprites_page(data, rig, listing, image_dir, shared)
    table = _graphic_table_page(data, listing, pictures)
    log("  graphics: the panel and the font...")
    panel = _panel_page(data, rig, listing, image_dir)
    font = _font_page(data, rig, listing, image_dir, shared)
    sections = {"Tiles": tiles, "GraphicTable": table, "Sprites": sprites, "Panel": panel,
                "Font": font}
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
    log(f"  graphics: {len(pictures)} sprites, {len(data.tiles)} tiles and "
        f"{len(data.edges)} edge pictures drawn by the game's code")
    return sections
