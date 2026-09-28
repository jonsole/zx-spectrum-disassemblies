"""Nightshade's town: the Town, Buildings and CellTypes pages, drawn from the game at build time.

build_nightshade.py --html calls build(), which draws the town, its 58
building definitions and its 36 cell types with the game's own code into the
HTML directory and returns the three pages' sections. Like everything the
build writes from the game, none of it is committed: the pictures are the
game's, and so are the cell lists.

How the pictures are made. The game is started in SkoolKit's simulator the
way the build's sessions start it (build_nightshade.Machine, the menu, key 1
and 0), and stopped at the start of a turn (MAIN_LOOP): the drawing tables
are built (#R$E0FB) and every variable is as a game has it. From that base
each building is drawn by calling the game's own routines as subroutines:

- DRAW_WALLS ($D372) for a cell of the type wanted -- one cell of the map is
  given the type, and read through LOOK_UP_CELL ($D564) the way the view
  reads it -- with the knight's U and V set so that the cell's corner lands
  where it is wanted on the screen (the projection is PROJECT_CELL, $D508,
  and the corner it gives is checked). The play area's buffer is 112 lines
  of 192 pixels, smaller than a building (256 pixels wide, up to 184 lines
  high), so each is drawn four times, moved by a whole number of 16-pixel
  columns and lines, and the pieces put together. Walls are written over the
  buffer, clear pixels and all, so each drawing is made twice, into a buffer
  of zeros and a buffer of ones: a pixel the same in both is the wall's.
  The ink is read back from the attribute buffer, where COLOUR_WALL ($D356)
  put it. In the two drawings with the building's feet below the play area
  -- which the game never draws -- COLOUR_WALL would write its colour below
  the attribute buffer, into the top lines of the pixel buffer, so there it
  is made to return at once.
- DRAW_OUTLINE ($D19D) the same way for the line round a building's foot
  that the game draws for the cells in front of the knight; it is ORed into
  the buffer, so one buffer of zeros is enough.

The town map puts each cell's walls where the game's projection puts the
cell's corner -- checked by PROJECT_CELL for every cell of the town -- and
pastes them back to front, so that nearer walls stand in front. That last
step is the page's: the game draws only the nine cells round the knight, and
hides what is behind a wall by claiming its screen columns (#R$D3C2), not by
drawing back to front.

The layers are measured with the game's own code wherever there is code for
them: the start cells by running RANDOM_START_CELL ($CB7B) on every value its
random number can have, the places for objects and villains by running
PLACE_VILLAINS and PLACE_OBJECTS ($D8E7, $D88E) on every value theirs can
have, the finds by running SPAWN_FIND ($C5CE) in a cell of every type, and
the percentage by running PERCENTAGE ($BEDF). Which cells a knight can walk
between is worked out here from the box lists, the way the collision code
reads them, and then checked by walking him across every edge between two
cells he can be in, with the game running and the walk key held.
"""
from __future__ import annotations

import re
from pathlib import Path

import nightshade_data as nd

# --------------------------------------------------------------------------
# Addresses (see their entries in the listing).
# --------------------------------------------------------------------------

MAIN_LOOP = 0xBE71
PERCENTAGE = 0xBEDF
STOCK_BUILDINGS = 0xC1DB
STOCK_AFTER_STIR = 0xC1DE   # just past its CALL $C5B4: HL from RANDOM
SPAWN_FIND = 0xC5CE
RANDOM_START_CELL = 0xCB7B
START_AFTER_STIR = 0xCB7E   # just past its CALL $C5BB: DE from RANDOM
DRAW_CELLS = 0xCF08
TURN_CELL = 0xD17D
DRAW_OUTLINE = 0xD19D
COLOUR_WALL = 0xD356
DRAW_WALLS = 0xD372
DRAW_WALL_COLUMN = 0xD3C2
PUT_TILE = 0xD425
PROJECT_CELL = 0xD508
LOOK_UP_CELL = 0xD564
PLACE_OBJECTS = 0xD88E
OBJECTS_AFTER_STIR = 0xD891
PLACE_VILLAINS = 0xD8E7
VILLAINS_AFTER_STIR = 0xD8EA
FIND_WANDER = 0xD9A3
PLACE_IN_CELL = 0xE028
HIT_BOXES_U = 0xE063
OVERLAP_U = 0xE087
VISIT_CELL = 0xBF48
THING_COLOURS = 0xC52F

RANDOM = 0xBBAA
TURNS = 0xBBB2
DRAW_X = 0xBBB6
DRAW_Y = 0xBBB8
VIEW = 0xBBBA
COLUMNS_DRAWN = 0xBBBB
STOCKS = 0xBBCE
PERCENT = 0xBBFD
LAST_FLASH = 0xBBFC
ARRIVING = 0xBC02
VISITED = 0xBC0E
KNIGHT = 0xBC8E
KNIGHT_TOP = 0xBC9E
FINDS = 0xBCCE
BONUS = 0xBD0E
OBJECTS = 0xBD1E
MONSTERS = 0xBD9E
LIVES = 0xBBCD
HITS = 0xBBF3
VILLAINS = 0xBD5E
START_U_CELL = 0xCC38
START_V_CELL = 0xCC3A
BUFFER = 0xE5C4             # 112 lines of 24 bytes, the bottom line first
ATTRIBUTES = 0xF044         # 14 rows of 24 bytes, the bottom row first
BUFFER_END = ATTRIBUTES
ATTRIBUTES_END = 0xF194
RECORD = 16

# The buffer's geometry, from #R$E53A: byte (x / 8 - 2) of line (y - 72).
BUFFER_WIDTH = 24
BUFFER_LINES = 112
BUFFER_X0 = 16              # x of the buffer's first byte
BUFFER_Y0 = 72              # y of its first (bottom) line, counting up
SHOWN_X0 = 32               # the first two bytes are a margin never shown (#R$E148)

# A building, drawn from its cell's corner (#R$D372): 16 columns of 16
# pixels, the first face stepping 8 lines down a column and the second 8 up,
# a lower tile at the column's y and an upper one 64 lines above it; tiles
# are at most 64 lines high. So it spans 256 pixels, and from 56 lines below
# the corner (the lowest column's foot) to 128 above it.
WALL_WIDTH = 256
WALL_BELOW = 56
WALL_ABOVE = 128
WALL_HEIGHT = WALL_BELOW + WALL_ABOVE
# An outline (#R$D19D) reaches from the front corner, 64 lines below the
# cell's corner, to a little above the back corner, 64 above it.
OUTLINE_BELOW = 64
OUTLINE_ABOVE = 80
OUTLINE_HEIGHT = OUTLINE_BELOW + OUTLINE_ABOVE
# Where the corner is put for each of the four drawings: two across, two up.
# The x keeps every column on a 16-pixel boundary, and each y keeps every
# column's foot at or above 0 (#R$D3C2 skips a column with a foot below it).
PASS_X = (32, -128)
PASS_Y = (128, 56)
# The screen columns (x / 16) claimed before the walls are drawn, so that
# only the ones the buffer holds are drawn in: #R$CF08 claims the same four
# at the start of every turn.
CLAIMED = 0xE001            # columns 0 and 13-15

# The scratch cell a building is drawn from, in the view's terms.
SCRATCH = (16, 16)

MAP_CELL = 256              # units a cell
SENTINEL = 0x5B00           # a return address nothing else runs (the printer buffer)
STACK = 0x5DF0
TSTATES = 3500000

# The Spectrum's bright colours, and the page's.
SPECTRUM_BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF),
                   (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0), (0xFF, 0xFF, 0xFF)]
INK_NAMES = ["black", "blue", "red", "magenta", "green", "cyan", "yellow", "white"]
MAP_GROUND = (7, 7, 28)     # aticatac.css's page colour
MAP_GRID = (30, 30, 70)     # the cells' outlines on the ground: the page's, not the game's
# The solid cells -- the ring round the town and the blocks inside it -- are
# types 1 and 2, whose boxes close all four sides: no knight, villain or
# object is ever in one. The town map leaves their walls out, which would
# otherwise bury the town in cyan, and shows them as black ground.
SOLID_TYPES = (1, 2)
MAP_SOLID = (0, 0, 0)
MAP_MARGIN = 24
OVERVIEW_SCALE = 4          # the overview is a quarter of the full size

# The graphics a find is, by kind (#R$C5CE), and the carried thing it
# becomes (#R$C481).
FIND_GRAPHIC = 0x30
FIRST_ANTIBODY = 5

# The collision boxes (#R$E063): the knight's half-size in units (+8, +9 of
# his record), and the half units a cell spans.
KNIGHT_HALF = 16
CELL_LOW, CELL_HIGH = 64, 192

# The walk test: the key that walks with keyboard control (#R$E2DA reads
# the A-G row), how long it is held, and the tries: from the middle of the
# cell, and then nearer the edge, each with and without some turns first.
WALK_KEY = "a"
WALK_TURNS = 80
WALK_TRIES = [(128, 0), (160, 0), (128, 3), (160, 7)]

# The layers: (key, what, colour, shown at first).
LAYERS = [
    ("types", "Cell types", (230, 230, 230), True),
    ("standable", "The 625 cells that count", (60, 200, 90), False),
    ("finds", "Where finds come from", (240, 220, 40), False),
    ("start", "Where a new game can start", (60, 220, 60), False),
    ("placed", "Where objects and villains can be put", (230, 60, 230), False),
    ("game", "One game's villains and objects", (255, 120, 60), False),
    ("boxes", "The walls the knight bumps into", (255, 70, 70), False),
]

# The CSS the page needs, for nightshade.css (the lead adds it). The boxes
# are the map's earlier siblings, so a selector reaches the SVG's groups
# with no script, as Knight Lore's castle map does.
LAYER_CSS = "\n".join(
    ["svg.ns-layers { position: absolute; left: 0; top: 0; width: 100%; height: 100%; "
     "pointer-events: none; }",
     "svg.ns-layers .ns-layer { display: none; }",
     ",\n".join(f"#ns-layer-{key}:checked ~ div.kl-castle svg.ns-layers .ns-layer-{key}"
                for key, *_ in LAYERS) + " { display: inline; }",
     "svg.ns-layers text { font-family: sans-serif; font-weight: bold; }"]
    + [f"span.ns-key-{key} {{ background-color: rgb{colour}; }}" for key, _, colour, _ in LAYERS]
    + ["div.ns-row { display: flex; flex-wrap: wrap; gap: 0.8em; align-items: flex-start; }",
       "div.ns-row > div { flex: 1 1 360px; }",
       "figure.ns-view { margin: 0; text-align: center; font-size: 0.85em; }",
       "img.ns-view { image-rendering: pixelated; width: 256px; height: auto; display: block; }",
       "img.ns-building { image-rendering: pixelated; width: 512px; max-width: 100%; height: auto; "
       "margin-right: 0.5em; vertical-align: top; }",
       "img.ns-plan { width: 272px; max-width: 100%; height: auto; display: block; }",
       "img.ns-icon { image-rendering: pixelated; width: 32px; height: 32px; "
       "vertical-align: middle; }",
       "table.ns-tiles td { text-align: center; padding: 1px 3px; }",
       "table.ns-tiles img { image-rendering: pixelated; height: 64px; }"])


def _word(memory, address: int) -> int:
    return memory[address] | memory[address + 1] << 8


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


def _plural(count: int, word: str, plural: str | None = None) -> str:
    return f"{count} {word if count == 1 else (plural or word + 's')}"


# --------------------------------------------------------------------------
# The listing: which addresses are entries, so #R links only go to those.
# --------------------------------------------------------------------------

class Refs:
    def __init__(self, skool: Path):
        self.entries = set()
        if skool.exists():
            for line in skool.read_text(encoding="utf-8").splitlines():
                match = re.match(r"^[bcgistuw]\$([0-9A-F]{4})", line)
                if match:
                    self.entries.add(int(match.group(1), 16))

    def __call__(self, address: int, text: str | None = None) -> str:
        if address in self.entries:
            return f"#R${address:04X}" + (f"({text})" if text else "")
        return (f"{text} (${address:04X})" if text else f"${address:04X}")


# --------------------------------------------------------------------------
# The game, ready to have its routines called.
# --------------------------------------------------------------------------

class Game:
    """The game in the simulator, stopped at the start of a turn in a new
    game, as the base every drawing and every measurement starts from."""

    def __init__(self, snapshot: Path):
        import build_nightshade as bn

        self.machine = bn.Machine(snapshot)
        # Into a game the way the build's sessions go: the menu, 1 for the
        # keyboard, 0 to start, the tune, the knight appeared; then on to
        # the start of the next turn.
        self.machine.play(bn._start("1") + [bn.At("the start of a turn", MAIN_LOOP)],
                          "the town's start")
        self.simulator = self.machine.simulator
        self.base = bytes(self.simulator.memory)
        self.base_registers = list(self.simulator.registers)

    @property
    def memory(self):
        return self.simulator.memory

    def reset(self) -> None:
        self.simulator.memory[:] = self.base
        for index, value in enumerate(self.base_registers):
            self.simulator.registers[index] = value

    def call(self, address: int, hl: int | None = None, seconds: float = 5.0) -> None:
        """Run the routine at `address` until it returns, to a sentinel put
        on a stack of its own."""
        from skoolkit.simutils import H, L, PC, SP, T

        simulator = self.simulator
        memory = simulator.memory
        memory[STACK] = SENTINEL & 0xFF
        memory[STACK + 1] = SENTINEL >> 8
        simulator.registers[SP] = STACK
        if hl is not None:
            simulator.registers[H], simulator.registers[L] = hl >> 8, hl & 0xFF
        simulator.trace(address, SENTINEL, 0, simulator.registers[T] + int(seconds * TSTATES),
                        False, None, None, None, None, None)
        if simulator.registers[PC] != SENTINEL:
            raise RuntimeError(f"the routine at ${address:04X} never returned "
                               f"(stopped at ${simulator.registers[PC]:04X})")

    def set_word(self, address: int, value: int) -> None:
        self.memory[address] = value & 0xFF
        self.memory[address + 1] = value >> 8 & 0xFF

    def word(self, address: int) -> int:
        return _word(self.memory, address)

    # ----------------------------------------------------------------------
    # Drawing.
    # ----------------------------------------------------------------------

    def _map_address(self, view: int, column: int, row: int) -> int:
        """The map byte #R$D564 reads for the view's cell (column, row):
        turned round, the map is read backwards from its end."""
        offset = 32 * row + column
        return nd.MAP + (1023 - offset if view else offset)

    def _place_knight(self, view: int, column: int, row: int, x: int, y: int) -> None:
        """The knight's U and V such that the view's cell (column, row) has
        its corner at x, y: from #R$D508, x = (dU + dV + $F0) / 2 and
        y = (dV - dU + $1B0) / 4, dU and dV the corner less the knight, both
        in the view's terms; and turned round, the knight's own U and V are
        8191 less the view's (#R$D18E)."""
        du = x - 2 * y + 96
        dv = x + 2 * y - 336
        u_view = column * MAP_CELL - du
        v_view = row * MAP_CELL - dv
        if view:
            u_view, v_view = 8191 - u_view, 8191 - v_view
        self.set_word(KNIGHT + 1, u_view)
        self.set_word(KNIGHT + 3, v_view)

    def _stage(self, cell_type: int, view: int, x: int, y: int) -> None:
        self.reset()
        memory = self.memory
        column, row = SCRATCH
        memory[VIEW] = view
        memory[LAST_FLASH] = 0
        memory[self._map_address(view, column, row)] = cell_type
        self._place_knight(view, column, row, x, y)
        # The corner where it is wanted? PROJECT_CELL projects the cell the
        # look-up kept.
        self.call(LOOK_UP_CELL, row << 8 | column)
        self.call(PROJECT_CELL)
        got = (self.word(DRAW_X), self.word(DRAW_Y))
        if got != (x & 0xFFFF, y & 0xFFFF):
            raise RuntimeError(f"the corner projected to {got}, not {(x, y)}")

    def _buffer(self) -> bytes:
        return bytes(self.memory[BUFFER:BUFFER_END])

    def walls(self, cell_type: int, view: int):
        """The walls of a cell of `cell_type` in `view`, drawn by #R$D372:
        (a 1-bit picture, a mask of the pixels drawn, the attribute the
        walls were coloured with)."""
        from PIL import Image, ImageChops

        picture = Image.new("1", (WALL_WIDTH, WALL_HEIGHT), 0)
        mask = Image.new("1", (WALL_WIDTH, WALL_HEIGHT), 0)
        attributes = set()
        for x in PASS_X:
            for y in PASS_Y:
                drawn = []
                for fill in (0x00, 0xFF):
                    self._stage(cell_type, view, x, y)
                    memory = self.memory
                    # A column whose foot is below the play area would have
                    # its colour put in attribute rows below the attribute
                    # buffer, which are the top lines of the pixel buffer:
                    # the game never draws a wall that low (#R$D356), so in
                    # the drawings that do, the colouring is left out -- a
                    # RET over its first byte -- and the ink is taken from
                    # the others.
                    coloured_here = y - WALL_BELOW >= BUFFER_Y0
                    if not coloured_here:
                        memory[COLOUR_WALL] = 0xC9
                    memory[BUFFER:BUFFER_END] = bytes([fill]) * (BUFFER_END - BUFFER)
                    memory[ATTRIBUTES:ATTRIBUTES_END] = bytes(ATTRIBUTES_END - ATTRIBUTES)
                    self.set_word(COLUMNS_DRAWN, CLAIMED)
                    self.call(DRAW_WALLS, SCRATCH[1] << 8 | SCRATCH[0])
                    drawn.append(_buffer_image(self._buffer()))
                    if coloured_here:
                        attributes |= set(memory[ATTRIBUTES:ATTRIBUTES_END]) - {0}
                # A pixel the same over zeros and over ones is the wall's.
                same = ImageChops.logical_xor(drawn[0], drawn[1])
                same = ImageChops.invert(same.convert("L")).convert("1")
                _paste_pass(picture, mask, drawn[0], same, x, y, WALL_ABOVE)
        return picture, mask, attributes

    def outline(self, cell_type: int, view: int):
        """The line round the foot of a cell of `cell_type` in `view`, drawn
        by #R$D19D: a 1-bit picture."""
        from PIL import Image

        picture = Image.new("1", (WALL_WIDTH, OUTLINE_HEIGHT), 0)
        mask = Image.new("1", (WALL_WIDTH, OUTLINE_HEIGHT), 0)
        for x in PASS_X:
            for y in PASS_Y:
                self._stage(cell_type, view, x, y)
                memory = self.memory
                memory[BUFFER:BUFFER_END] = bytes(BUFFER_END - BUFFER)
                self.call(DRAW_OUTLINE, SCRATCH[1] << 8 | SCRATCH[0])
                drawn = _buffer_image(self._buffer())
                everything = Image.new("1", drawn.size, 1)
                _paste_pass(picture, mask, drawn, everything, x, y, OUTLINE_ABOVE)
        return picture

    def project_all(self) -> dict:
        """The corner of every cell as PROJECT_CELL gives it, the knight
        standing in the middle of the town, in the usual view."""
        self.reset()
        self.memory[VIEW] = 0
        self.set_word(KNIGHT + 1, 16 * MAP_CELL + 128)
        self.set_word(KNIGHT + 3, 16 * MAP_CELL + 128)
        out = {}
        for row in range(32):
            for column in range(32):
                self.call(LOOK_UP_CELL, row << 8 | column)
                self.call(PROJECT_CELL)
                out[(column, row)] = (_signed16(self.word(DRAW_X)), _signed16(self.word(DRAW_Y)))
        return out

    # ----------------------------------------------------------------------
    # Measuring.
    # ----------------------------------------------------------------------

    def start_cells(self) -> dict:
        """Every value of the ten bits of RANDOM that #R$CB7B uses, run
        through the routine from just after its stir: {cell: how many}."""
        self.reset()
        out: dict[tuple, int] = {}
        for value in range(1024):
            self.set_word(RANDOM, value)
            self.call(START_AFTER_STIR)
            cell = (self.memory[START_U_CELL], self.memory[START_V_CELL])
            out[cell] = out.get(cell, 0) + 1
        return out

    def placements(self, after_stir: int, records: int) -> list:
        """Every value of the twelve bits of RANDOM that #R$D8E7 and #R$D88E
        use, run through the routine from just after its stir: for each, the
        four records' cells."""
        self.reset()
        out = []
        for value in range(4096):
            self.set_word(RANDOM, value)
            self.call(after_stir)
            out.append([(self.memory[records + RECORD * index + 2],
                         self.memory[records + RECORD * index + 4]) for index in range(4)])
        return out

    def stocks(self) -> list:
        """What #R$C1DB gives each cell type for every value of the twelve
        bits of RANDOM it uses: (lowest, highest) by type."""
        self.reset()
        low, high = [99] * nd.CELL_TYPES, [-1] * nd.CELL_TYPES
        for value in range(4096):
            self.set_word(RANDOM, value)
            self.call(STOCK_AFTER_STIR)
            for kind in range(nd.CELL_TYPES):
                stock = self.memory[STOCKS + kind]
                low[kind] = min(low[kind], stock)
                high[kind] = max(high[kind], stock)
        return list(zip(low, high))

    def find_in(self, cell_type: int):
        """A find made by #R$C5CE with the knight in a cell of `cell_type`:
        its graphic and its +5, or None; the type is given a stock of one
        and the turn counter a multiple of 16."""
        self.reset()
        memory = self.memory
        column, row = SCRATCH
        memory[nd.MAP + 32 * row + column] = cell_type
        memory[KNIGHT + 2], memory[KNIGHT + 4] = column, row
        memory[ARRIVING] = 0x70
        memory[TURNS] = 0
        memory[STOCKS + cell_type] = 1
        for index in range(4):
            memory[FINDS + RECORD * index] = 0
        self.call(SPAWN_FIND)
        if memory[FINDS] == 0:
            return None
        return memory[FINDS], memory[FINDS + 5], memory[STOCKS + cell_type]

    def walk(self, here: tuple, there: tuple, along: int, start: int, idle: int) -> bool:
        """Stand the knight in cell `here` at `start` half units across it
        towards `there` and `along` half units along the edge between them,
        facing it, hold the walk key for WALK_TURNS runs of a twentieth of a
        second, and see whether he gets into `there`. What else is about is
        kept out of the way -- the villains shut in the corner cell, the
        monsters, the bonus and the finds emptied, his lives and hits topped
        up -- so that what is tested is the walls. `idle` turns first vary
        the game's state between tries."""
        self.reset()
        self.machine.pc = MAIN_LOOP
        memory = self.memory
        for _ in range(idle):
            self.machine.run(0.05, [])
        across = 0 if there[0] != here[0] else 1
        hu, hv = (start, along) if across == 0 else (along, start)
        u = here[0] * MAP_CELL + 2 * (hu - CELL_LOW)
        v = here[1] * MAP_CELL + 2 * (hv - CELL_LOW)
        for record in (KNIGHT, KNIGHT_TOP):
            self.set_word(record + 1, u)
            self.set_word(record + 3, v)
        # Facing +U or +V (bits 6-7 of +6, #R$DCE0).
        memory[KNIGHT + 6] = memory[KNIGHT + 6] & 0x3F | (0x40 if across == 0 else 0)
        for index in range(4):
            memory[VILLAINS + RECORD * index + 2] = 0
            memory[VILLAINS + RECORD * index + 4] = 0
        for _ in range(WALK_TURNS):
            memory[LIVES], memory[HITS] = 5, 3
            for index in range(6):
                memory[MONSTERS + RECORD * index] = 0
            for index in range(4):
                memory[FINDS + RECORD * index] = 0
            memory[BONUS] = 0
            self.machine.run(0.05, [WALK_KEY])
            if (memory[KNIGHT + 2], memory[KNIGHT + 4]) == there:
                return True
        return False

    def percentage(self, cells, villains_alive: bool) -> int:
        """PERCENTAGE ($BEDF) with the VISITED bits of `cells` set."""
        self.reset()
        memory = self.memory
        memory[VISITED:VISITED + 128] = bytes(128)
        for column, row in cells:
            memory[VISITED + 4 * row + (column >> 3)] |= 1 << (column & 7)
        for index in range(4):
            memory[VILLAINS + RECORD * index] = 0x60 + 4 * (3 - index) if villains_alive else 0
        self.call(PERCENTAGE, seconds=20.0)
        high, low = memory[PERCENT], memory[PERCENT + 1]
        return 100 * high + 10 * (low >> 4) + (low & 15)


def _signed16(value: int) -> int:
    return value - 0x10000 if value & 0x8000 else value


def _buffer_image(data: bytes):
    """The play area's buffer as a picture, the top line first."""
    from PIL import Image

    lines = [data[BUFFER_WIDTH * line:BUFFER_WIDTH * (line + 1)]
             for line in range(BUFFER_LINES - 1, -1, -1)]
    return Image.frombytes("1", (BUFFER_WIDTH * 8, BUFFER_LINES), b"".join(lines))


def _paste_pass(picture, mask, drawn, drawn_mask, corner_x: int, corner_y: int, above: int):
    """Put the shown part of one drawing into a building's picture, whose
    top-left is `above` lines over the corner and whose left edge is the
    corner: buffer pixel (bx, line) is x = bx + 16 and y = 72 + line counted
    up; only x from SHOWN_X0 is taken, as the game shows."""
    left = SHOWN_X0 - BUFFER_X0
    crop = (left, 0, BUFFER_WIDTH * 8, BUFFER_LINES)
    part, part_mask = drawn.crop(crop), drawn_mask.crop(crop)
    # The buffer's top line is y = 72 + 111; in the picture, row
    # above - (y - corner_y).
    dx = SHOWN_X0 - corner_x
    dy = above - (BUFFER_Y0 + BUFFER_LINES - 1 - corner_y)
    picture.paste(part, (dx, dy), part_mask)
    mask.paste(part_mask, (dx, dy), part_mask)


def coloured(picture, mask, ink: tuple, scale: int = 1):
    """A 1-bit drawing in an ink, black where drawn and clear, and
    transparent where nothing was drawn."""
    from PIL import Image

    image = Image.new("RGBA", picture.size, (0, 0, 0, 0))
    black = Image.new("RGBA", picture.size, (0, 0, 0, 255))
    lit = Image.new("RGBA", picture.size, ink + (255,))
    image.paste(black, (0, 0), mask.convert("L"))
    image.paste(lit, (0, 0), picture.convert("L"))
    if scale != 1:
        image = image.resize((image.width * scale, image.height * scale), Image.NEAREST)
    return image


# --------------------------------------------------------------------------
# The town, read.
# --------------------------------------------------------------------------

def cell_boxes(memory, cell_type: int) -> list[tuple]:
    """A cell type's boxes (#R$6334): centre U and V, half-sizes in U and V,
    in the cell's half units (64 to 191)."""
    address = _word(memory, nd.BOX_TABLE + 2 * cell_type)
    boxes = []
    while memory[address]:
        boxes.append(tuple(memory[address:address + 4]))
        address += 4
    return boxes


def _open_along(boxes, axis: int, at: int) -> list[tuple]:
    """Where the knight's centre can be along the other axis while his
    centre is at `at` on `axis`, without overlapping a box as #R$E087 and
    #R$E0C4 test it: his half-size halved plus the box's, in half units.
    Intervals of the other axis, inclusive, from 64 to 191."""
    reach = KNIGHT_HALF // 2
    blocked = []
    for box in boxes:
        centre, half = box[axis], box[axis + 2]
        other, other_half = box[1 - axis], box[3 - axis]
        if abs(at - centre) < reach + half:
            blocked.append((other - other_half - reach + 1, other + other_half + reach - 1))
    free, start = [], CELL_LOW
    for low, high in sorted(blocked):
        if low > start:
            free.append((start, low - 1))
        start = max(start, high + 1)
    if start <= CELL_HIGH - 1:
        free.append((start, CELL_HIGH - 1))
    return free


def _overlap(a: list[tuple], b: list[tuple]) -> bool:
    for low_a, high_a in a:
        for low_b, high_b in b:
            if max(low_a, low_b) <= min(high_a, high_b):
                return True
    return False


def walkable_links(memory) -> dict:
    """Which neighbouring cells a knight can walk between, worked out from
    the boxes: across the edge between two cells, a place along it where his
    box, centred on the edge, meets no box of either cell. The cells' own
    interiors hold no boxes, so a cell is one space inside its walls."""
    boxes = {kind: cell_boxes(memory, kind) for kind in range(nd.CELL_TYPES)}
    links = {}
    for row in range(32):
        for column in range(32):
            here = nd.cell(memory, column, row)
            # +U: this cell's high U edge (192) and the next one's low (64);
            # axis 0 is U, so the free places are along V.
            if column < 31:
                there = nd.cell(memory, column + 1, row)
                links[((column, row), (column + 1, row))] = _overlap(
                    _open_along(boxes[here], 0, CELL_HIGH), _open_along(boxes[there], 0, CELL_LOW))
            if row < 31:
                there = nd.cell(memory, column, row + 1)
                links[((column, row), (column, row + 1))] = _overlap(
                    _open_along(boxes[here], 1, CELL_HIGH), _open_along(boxes[there], 1, CELL_LOW))
    return links


def rom_pairs_walk(rom, start: int, count: int, solid) -> list[tuple]:
    """The cells #R$D8E7's loop would read from `start`: pairs of bytes as
    a column and a row, masked to 0-31, skipping solid cells."""
    out, address = [], start
    while len(out) < count:
        column, row = rom[address] & 31, rom[address + 1] & 31
        address += 2
        if not solid(column, row):
            out.append((column, row))
    return out


# --------------------------------------------------------------------------
# Pictures of the town.
# --------------------------------------------------------------------------

def _corner(column: int, row: int) -> tuple:
    """A cell's corner in pixels from the map's origin: x = (U + V)
    / 2 and y down the page = (U - V) / 4, #R$D508's projection."""
    return 128 * (column + row), 64 * (column - row)


def _point(column: int, row: int, hu: float, hv: float) -> tuple:
    """A point of a cell at (hu, hv) in its half units (64 to 191)."""
    u = column * MAP_CELL + 2 * (hu - CELL_LOW)
    v = row * MAP_CELL + 2 * (hv - CELL_LOW)
    return (u + v) / 2, (u - v) / 4


def town_picture(memory, sprites: dict, view: int):
    """The whole town in `view`: every cell's walls where the projection
    puts its corner, back to front. `sprites` is (type, view) to an RGBA
    picture WALL_HEIGHT high, the corner WALL_ABOVE lines down its left
    edge. Returns the picture and the offset of the map's origin in it."""
    from PIL import Image, ImageDraw

    width = 128 * 62 + WALL_WIDTH + 2 * MAP_MARGIN
    top = 64 * -31 - WALL_ABOVE - MAP_MARGIN
    height = 64 * 62 + WALL_ABOVE + OUTLINE_BELOW + 2 * MAP_MARGIN
    origin = (MAP_MARGIN, -top)
    image = Image.new("RGBA", (width, height), MAP_GROUND + (255,))
    draw = ImageDraw.Draw(image)
    for row in range(32):
        for column in range(32):
            x, y = _corner(column, row)
            x, y = x + origin[0], y + origin[1]
            diamond = [(x, y), (x + 128, y + 64), (x + 256, y), (x + 128, y - 64)]
            if view_cell(memory, view, column, row) in SOLID_TYPES:
                draw.polygon(diamond, fill=MAP_SOLID)
            else:
                draw.polygon(diamond, outline=MAP_GRID)
    # Back to front: further back is smaller U and larger V (#R$CFF2), which
    # is higher up the page.
    cells = sorted(((c, r) for r in range(32) for c in range(32)), key=lambda cr: cr[0] - cr[1])
    for column, row in cells:
        kind = view_cell(memory, view, column, row)
        if not kind or kind in SOLID_TYPES:
            continue
        x, y = _corner(column, row)
        sprite = sprites[(kind, view)]
        image.alpha_composite(sprite, (x + origin[0], y + origin[1] - WALL_ABOVE))
    return image.convert("RGB"), origin


def view_cell(memory, view: int, column: int, row: int) -> int:
    """The type of the view's cell (column, row), as #R$D564 reads it."""
    if view:
        return nd.cell(memory, 31 - column, 31 - row)
    return nd.cell(memory, column, row)


def box_plan(boxes, ink: tuple, scale: int = 1):
    """A cell's boxes drawn on its ground, in the game's projection: the
    cell's diamond, and each box as the diamond it covers. The page's
    drawing: the game has boxes only to test against, and never draws one."""
    from PIL import Image, ImageDraw

    big = 4
    image = Image.new("RGB", ((256 + 16) * big, (128 + 16) * big), MAP_GROUND)
    draw = ImageDraw.Draw(image)

    def at(hu, hv):
        u, v = 2 * (hu - CELL_LOW), 2 * (hv - CELL_LOW)
        return ((8 + (u + v) / 2) * big, (8 + 64 + (u - v) / 4) * big)

    draw.polygon([at(64, 64), at(192, 64), at(192, 192), at(64, 192)], fill=(22, 22, 60),
                 outline=(90, 90, 140), width=big)
    for cu, cv, su, sv in boxes:
        corners = [at(cu - su, cv - sv), at(cu + su, cv - sv), at(cu + su, cv + sv),
                   at(cu - su, cv + sv)]
        draw.polygon(corners, fill=ink)
    image = image.resize(((256 + 16) * scale, (128 + 16) * scale), Image.LANCZOS)
    return image


def icon_picture(memory, thing: int, ink: tuple):
    """A carried thing's icon, its four characters two by two as #R$C4A4
    prints them, in `ink` on black."""
    from PIL import Image

    image = Image.new("RGB", (16, 16), (0, 0, 0))
    pixels = image.load()
    for index in range(4):
        base = nd.ICONS + 8 * (4 * thing + index)
        ox, oy = 8 * (index & 1), 8 * (index >> 1)
        for line in range(8):
            byte = memory[base + line]
            for bit in range(8):
                if byte & (0x80 >> bit):
                    pixels[ox + bit, oy + line] = ink
    return image.resize((32, 32), Image.NEAREST)


# --------------------------------------------------------------------------
# The pages.
# --------------------------------------------------------------------------

def _svg_diamond(points, scale: float) -> str:
    return " ".join(f"{x / scale:.0f},{y / scale:.0f}" for x, y in points)


def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    from PIL import Image

    from build_nightshade import ROM, game_memory

    memory = game_memory(snapshot)
    ref = Refs(snapshot.with_name("nightshade.skool"))
    image_dir = html_dir / "images" / "world"
    image_dir.mkdir(parents=True, exist_ok=True)

    counts = [0] * nd.CELL_TYPES
    cells_of: dict[int, list[tuple]] = {}
    for row in range(32):
        for column in range(32):
            kind = nd.cell(memory, column, row)
            counts[kind] += 1
            cells_of.setdefault(kind, []).append((column, row))

    def solid(column: int, row: int) -> bool:
        return nd.cell(memory, column, row) in SOLID_TYPES

    standable = [(c, r) for r in range(32) for c in range(32) if not solid(c, r)]

    log("  starting a game to draw the town with...")
    game = Game(snapshot)
    base = game.base

    # The projection, checked for every cell: relative to the knight, every
    # corner is where _corner() puts it.
    projected = game.project_all()
    x0, y0 = projected[(0, 0)]
    for (column, row), (x, y) in projected.items():
        want_x, want_y = _corner(column, row)
        if (x - x0, -(y - y0)) != (want_x, want_y):
            raise RuntimeError(f"cell ({column},{row}) projected to {(x, y)}, not where the map "
                               "puts it")

    # The building definitions: which table entries reach each.
    starts = nd.building_starts(memory)
    definitions = sorted(starts)
    definition_of = {}
    for index in range(2 * nd.CELL_TYPES):
        definition_of[(index >> 1, index & 1)] = _word(memory, nd.BUILDINGS + 2 * index)

    log("  drawing every cell type's walls and outline with the game's own code...")
    walls, outlines, inks = {}, {}, {}
    for kind in range(1, nd.CELL_TYPES):
        for view in (0, 1):
            picture, mask, attributes = game.walls(kind, view)
            walls[(kind, view)] = (picture, mask)
            if len(attributes) != 1:
                raise RuntimeError(f"type {kind}: the walls were coloured {sorted(attributes)}")
            inks[(kind, view)] = attributes.pop()
            outlines[(kind, view)] = game.outline(kind, view)
    for kind in range(1, nd.CELL_TYPES):
        if inks[(kind, 0)] != inks[(kind, 1)]:
            raise RuntimeError(f"type {kind}'s two views are coloured differently")
    ink_of = {kind: inks[(kind, 0)] & 7 for kind in range(1, nd.CELL_TYPES)}

    # One picture per definition, in white, from the first type and view
    # that uses it; and a check that every other use draws the same.
    definition_picture = {}
    for kind in range(1, nd.CELL_TYPES):
        for view in (0, 1):
            address = definition_of[(kind, view)]
            picture, mask = walls[(kind, view)]
            if address in definition_picture:
                if (list(definition_picture[address][0].getdata()) != list(picture.getdata())
                        or list(definition_picture[address][1].getdata())
                        != list(mask.getdata())):
                    raise RuntimeError(f"the building at ${address:04X} drew differently "
                                       f"for type {kind}")
            else:
                definition_picture[address] = (picture, mask)
    missing = set(definitions) - set(definition_picture)
    if missing:
        raise RuntimeError(f"building definitions no type draws: {sorted(missing)}")
    for address in definitions:
        picture, mask = definition_picture[address]
        coloured(picture, mask, (255, 255, 255)).save(image_dir / f"building{address:04x}.png")

    sprites = {}
    for kind in range(1, nd.CELL_TYPES):
        ink = SPECTRUM_BRIGHT[ink_of[kind]]
        for view in (0, 1):
            picture, mask = walls[(kind, view)]
            sprites[(kind, view)] = coloured(picture, mask, ink)
            sprites[(kind, view)].save(image_dir / f"type{kind}_{view}.png")
            outline = outlines[(kind, view)]
            coloured(outline, outline, (255, 255, 255)).save(
                image_dir / f"type{kind}_{view}_outline.png")
        box_plan(cell_boxes(memory, kind), SPECTRUM_BRIGHT[ink_of[kind]]).save(
            image_dir / f"type{kind}_boxes.png")
    box_plan([], (255, 255, 255)).save(image_dir / "type0_boxes.png")

    log("  measuring the start cells, the places and the stocks with the game's own code...")
    start_counts = game.start_cells()
    rom = list(ROM.read_bytes()) if ROM.exists() else list(base[:0x4000])
    villain_runs = game.placements(VILLAINS_AFTER_STIR, VILLAINS)
    object_runs = game.placements(OBJECTS_AFTER_STIR, OBJECTS)
    if villain_runs != object_runs:
        raise RuntimeError("PLACE_VILLAINS and PLACE_OBJECTS placed differently")
    # The same, walked here from the ROM's bytes: the model the page states.
    for value in range(4096):
        if rom_pairs_walk(rom, value, 4, solid) != villain_runs[value]:
            raise RuntimeError(f"RANDOM {value}: the ROM walk and the game disagree")
    placed_counts: dict[tuple, int] = {}
    for run in villain_runs:
        for cell in run:
            placed_counts[cell] = placed_counts.get(cell, 0) + 1
    furthest = max(value + 2 * _pairs_read(rom, value, solid) for value in range(4096))
    # The start cells, by the rule the listing states: the first cell not
    # solid from a random one on, wrapping at the end of the map.
    model: dict[tuple, int] = {}
    for value in range(1024):
        offset = value
        while nd.cell(memory, offset & 31, offset >> 5) in (1, 2):
            offset = (offset + 1) & 1023
        cell = (offset & 31, offset >> 5)
        model[cell] = model.get(cell, 0) + 1
    if model != start_counts:
        raise RuntimeError("RANDOM_START_CELL disagrees with the rule")
    stock_ranges = game.stocks()
    finds = {kind: game.find_in(kind) for kind in range(nd.CELL_TYPES)}
    for kind in range(2, nd.CELL_TYPES):
        if finds[kind] is None or finds[kind][0] != FIND_GRAPHIC + 4 * (kind & 3):
            raise RuntimeError(f"type {kind}: SPAWN_FIND made {finds[kind]}")
    all_visited = game.percentage(standable, True)
    all_done = game.percentage(standable, False)
    links = walkable_links(memory)
    log("  walking the knight across every edge between two standable cells...")
    walked = {}
    boxes_of = {kind: cell_boxes(memory, kind) for kind in range(nd.CELL_TYPES)}
    for (here, there), open_ in links.items():
        if solid(*here) or solid(*there):
            continue
        along = _crossing_place(boxes_of, memory, here, there)
        tries = WALK_TRIES if open_ else WALK_TRIES[:1]
        walked[(here, there)] = any(game.walk(here, there, along, start, idle)
                                    for start, idle in tries)
    disagree = sorted(pair for pair, got in walked.items() if got != links[pair])
    # The regions the knight can walk round, from the links.
    region_of: dict[tuple, int] = {}
    regions = []
    for cell in standable:
        if cell in region_of:
            continue
        region, todo = [cell], [cell]
        region_of[cell] = len(regions)
        while todo:
            column, row = todo.pop()
            for other in ((column + 1, row), (column - 1, row),
                          (column, row + 1), (column, row - 1)):
                pair = tuple(sorted(((column, row), other)))
                if links.get(pair) and other not in region_of:
                    region_of[other] = len(regions)
                    region.append(other)
                    todo.append(other)
        regions.append(sorted(region, key=lambda cr: (cr[1], cr[0])))
    main_region = max(range(len(regions)), key=lambda i: len(regions[i]))
    cut_off = sorted((cell for i, region in enumerate(regions) if i != main_region
                      for cell in region), key=lambda cr: (cr[1], cr[0]))

    # This game: the simulator's.
    def as_placed(records):
        return [(base[records + RECORD * i + 2], base[records + RECORD * i + 4],
                 base[records + RECORD * i]) for i in range(4)]

    game_villains, game_objects = as_placed(VILLAINS), as_placed(OBJECTS)
    game_start = (base[START_U_CELL], base[START_V_CELL])
    game_stocks = list(base[STOCKS:STOCKS + nd.CELL_TYPES])
    # The objects lie where they were put; the villains have had a few turns
    # to walk, so only the objects are checked against the places.
    for column, row, _ in game_objects:
        if (column, row) not in placed_counts:
            raise RuntimeError(f"this game put something in ({column},{row}), outside the set")

    log("  putting the town together...")
    maps = {}
    for view in (0, 1):
        whole, origin = town_picture(memory, sprites, view)
        whole.save(image_dir / f"town{view}.png", optimize=True)
        overview = whole.resize((whole.width // OVERVIEW_SCALE, whole.height // OVERVIEW_SCALE),
                                Image.LANCZOS)
        overview.save(image_dir / f"town{view}_overview.png", optimize=True)
        maps[view] = (whole, overview, origin)

    thing_colours = [base[THING_COLOURS + i] & 7 for i in range(9)]
    for kind in range(4):
        thing = FIRST_ANTIBODY + kind
        icon_picture(memory, thing, SPECTRUM_BRIGHT[thing_colours[thing]]).save(
            image_dir / f"antibody{kind}.png")

    sections = {}
    sections["Town"] = _town_page(
        memory, ref, maps, counts, cells_of, standable, start_counts, placed_counts,
        furthest, stock_ranges, game_stocks, finds, thing_colours, all_visited, all_done, links,
        regions, main_region, cut_off, game_villains, game_objects, game_start, ink_of, walked,
        disagree)
    sections["Buildings"] = _buildings_page(memory, ref, definitions, starts, definition_of,
                                            counts)
    sections["CellTypes"] = _cell_types_page(
        memory, ref, counts, cells_of, definition_of, ink_of, finds, stock_ranges, game_stocks,
        thing_colours, start_counts, placed_counts)
    log(f"  {len(definitions)} building definitions, {nd.CELL_TYPES} cell types; "
        f"{len(standable)} standable cells, {len(start_counts)} start cells, "
        f"{len(placed_counts)} cells for objects and villains; percentage {all_visited} "
        f"and {all_done}; {len(regions)} walkable regions")
    return sections


def _crossing_place(boxes_of, memory, here: tuple, there: tuple) -> int:
    """Where along the edge between two cells to cross it: the middle of the
    first place the boxes of both leave open (_open_along), or the middle of
    the edge if there is none."""
    across = 0 if there[0] != here[0] else 1
    free_here = _open_along(boxes_of[nd.cell(memory, *here)], across, CELL_HIGH)
    free_there = _open_along(boxes_of[nd.cell(memory, *there)], across, CELL_LOW)
    for low_a, high_a in free_here:
        for low_b, high_b in free_there:
            low, high = max(low_a, low_b), min(high_a, high_b)
            if low <= high:
                return (low + high) // 2
    return 128


def _pairs_read(rom, start: int, solid) -> int:
    """How many pairs #R$D8E7's loop reads from `start` for its four."""
    found, pairs, address = 0, 0, start
    while found < 4:
        column, row = rom[address] & 31, rom[address + 1] & 31
        address += 2
        pairs += 1
        if not solid(column, row):
            found += 1
    return pairs


def _cell_link(column: int, row: int, kind: int) -> str:
    return f'<a href="CellTypes.html#type{kind}">({column},{row})</a>'


def _type_link(kind: int, text: str | None = None) -> str:
    return f'<a href="CellTypes.html#type{kind}">{text or kind}</a>'


def _town_page(memory, ref, maps, counts, cells_of, standable, start_counts, placed_counts,
               furthest, stock_ranges, game_stocks, finds, thing_colours,
               all_visited, all_done, links, regions, main_region, cut_off, game_villains,
               game_objects, game_start, ink_of, walked, disagree) -> str:
    scale = OVERVIEW_SCALE
    whole, overview, origin = maps[0]

    def corner(column, row):
        x, y = _corner(column, row)
        return x + origin[0], y + origin[1]

    def diamond(column, row, inset: float = 0.0):
        x, y = corner(column, row)
        return [(x + inset * 2, y), (x + 128, y + 64 - inset), (x + 256 - inset * 2, y),
                (x + 128, y - 64 + inset)]

    def centre(column, row):
        x, y = corner(column, row)
        return x + 128, y

    built = [k for k in range(3, nd.CELL_TYPES) if counts[k]]
    unused = [k for k in range(3, nd.CELL_TYPES) if not counts[k]]

    # The layers, as SVG groups over the overview.
    groups = {}
    labels = []
    for (column, row), kind in ((cr, nd.cell(memory, *cr)) for cr in
                                ((c, r) for r in range(32) for c in range(32))):
        if kind > 1:
            x, y = centre(column, row)
            labels.append(f'<text x="{x / scale:.0f}" y="{y / scale + 4:.0f}">{kind}</text>')
    groups["types"] = ('<g text-anchor="middle" font-size="11" fill="rgb(255,255,255)" '
                       'stroke="rgb(0,0,0)" stroke-width="2.5" paint-order="stroke">'
                       + "".join(labels) + "</g>")
    path = "".join(f"M{_svg_diamond(diamond(c, r, 6), scale)}Z" for c, r in standable)
    groups["standable"] = (f'<path d="{path}" fill="rgba(60,200,90,0.35)" '
                           f'stroke="rgb(60,200,90)" stroke-width="1"/>')
    find_paths = []
    for kind in range(4):
        thing = FIRST_ANTIBODY + kind
        colour = SPECTRUM_BRIGHT[thing_colours[thing]]
        cells = [(c, r) for c, r in standable if nd.cell(memory, c, r) >= 2
                 and nd.cell(memory, c, r) & 3 == kind]
        path = "".join(f"M{_svg_diamond(diamond(c, r, 36), scale)}Z" for c, r in cells)
        find_paths.append(f'<path d="{path}" fill="rgb{colour}" stroke="rgb(0,0,0)" '
                          f'stroke-width="1"/>')
    groups["finds"] = "".join(find_paths)
    most_start = max(start_counts.values())
    circles = []
    for (column, row), count in sorted(start_counts.items()):
        x, y = centre(column, row)
        radius = 2 + 6 * (count / most_start) ** 0.5
        circles.append(f'<circle cx="{(x - 40) / scale:.1f}" cy="{y / scale:.1f}" '
                       f'r="{radius:.1f}"><title>({column},{row}): {count} of 1024</title>'
                       "</circle>")
    groups["start"] = ('<g fill="rgb(60,220,60)" stroke="rgb(0,0,0)" stroke-width="1">'
                       + "".join(circles) + "</g>")
    most_placed = max(placed_counts.values())
    circles = []
    for (column, row), count in sorted(placed_counts.items()):
        x, y = centre(column, row)
        radius = 2 + 6 * (count / most_placed) ** 0.5
        circles.append(f'<circle cx="{(x + 40) / scale:.1f}" cy="{y / scale:.1f}" '
                       f'r="{radius:.1f}"><title>({column},{row}): {count} of 16384</title>'
                       "</circle>")
    groups["placed"] = ('<g fill="rgb(230,60,230)" stroke="rgb(0,0,0)" stroke-width="1">'
                        + "".join(circles) + "</g>")
    marks = []
    for letter, things in (("V", game_villains), ("O", game_objects)):
        for index, (column, row, _) in enumerate(things):
            x, y = centre(column, row)
            dx = -18 if letter == "V" else 18
            marks.append(f'<circle cx="{x / scale:.0f}" cy="{y / scale:.0f}" r="5" '
                         f'fill="rgb(255,120,60)" stroke="rgb(0,0,0)" stroke-width="1.5"/>'
                         f'<text x="{(x + dx * 3) / scale:.0f}" y="{(y - 40) / scale:.0f}" '
                         f'text-anchor="middle" font-size="17" fill="rgb(255,120,60)" '
                         f'stroke="rgb(0,0,0)" stroke-width="3.5" paint-order="stroke">'
                         f"{letter}{index}</text>")
    x, y = centre(*game_start)
    marks.append(f'<circle cx="{x / scale:.0f}" cy="{y / scale:.0f}" r="5" '
                 f'fill="rgb(255,255,255)" stroke="rgb(0,0,0)" stroke-width="1.5"/>'
                 f'<text x="{x / scale:.0f}" y="{(y + 80) / scale:.0f}" text-anchor="middle" '
                 f'font-size="17" fill="rgb(255,255,255)" stroke="rgb(0,0,0)" stroke-width="3.5" '
                 f'paint-order="stroke">K</text>')
    groups["game"] = "".join(marks)
    box_path = []
    for row in range(32):
        for column in range(32):
            kind = nd.cell(memory, column, row)
            if kind < 2:
                continue
            for cu, cv, su, sv in cell_boxes(memory, kind):
                points = [_point(column, row, cu + du * su, cv + dv * sv)
                          for du, dv in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
                points = [(x + origin[0], y + origin[1]) for x, y in points]
                box_path.append(f"M{_svg_diamond(points, scale)}Z")
    groups["boxes"] = (f'<path d="{"".join(box_path)}" fill="rgb(255,70,70)" '
                       f'stroke="rgb(255,70,70)" stroke-width="1.5" stroke-linejoin="round"/>')
    svg = (f'<svg class="ns-layers" viewBox="0 0 {overview.width} {overview.height}">'
           + "".join(f'<g class="ns-layer ns-layer-{key}">{groups[key]}</g>'
                     for key, *_ in LAYERS) + "</svg>")

    # The image map: nearer cells first, so a click on a wall picks the
    # cell whose wall it is. A built cell's area is its walls' outline, an
    # open one its ground.
    areas = []
    order = sorted(((c, r) for r in range(32) for c in range(32)), key=lambda cr: cr[1] - cr[0])
    for column, row in order:
        kind = nd.cell(memory, column, row)
        x, y = corner(column, row)
        if kind:
            points = [(x, y), (x + 128, y + 64), (x + 256, y), (x + 256, y - WALL_ABOVE),
                      (x + 128, y + 64 - WALL_ABOVE), (x, y - WALL_ABOVE)]
        else:
            points = diamond(column, row)
        coords = ",".join(f"{round(px / scale)},{round(py / scale)}" for px, py in points)
        areas.append(f'<area shape="poly" coords="{coords}" href="CellTypes.html#type{kind}" '
                     f'title="({column},{row}): type {kind}" alt="({column},{row})">')

    toggles, keys = [], []
    for key, what, colour, shown in LAYERS:
        toggles.append(f'<input type="checkbox" class="kl-toggle" id="ns-layer-{key}"'
                       + (" checked" if shown else "") + ">"
                       f'<label for="ns-layer-{key}"><span class="kl-key ns-key-{key}">'
                       f"</span>{what}</label>")

    def key_line(key, text):
        what = next(w for k, w, _, _ in LAYERS if k == key)
        keys.append(f'<p><span class="kl-key ns-key-{key}"></span><b>{what}</b>: {text}</p>')

    type2 = cells_of.get(2, [])
    key_line("types", f"the number the map holds ({ref(nd.MAP)}) for every cell but open "
             f"ground (type 0, {counts[0]} cells) and type 1 ({counts[1]} cells), the solid walls: "
             "the ring round the town and the blocks inside it, left unnumbered so that the rest "
             f"can be read. The other {1024 - counts[0] - counts[1]} cells are of "
             f"{len(built) + (1 if type2 else 0)} types. Click any cell, numbered or not, for its "
             'type on the <a href="CellTypes.html">cell types</a> page.')
    key_line("standable", f"{len(standable)} cells, every one that is not type 1 or 2. They are "
             f"the cells a knight can be in: {ref(RANDOM_START_CELL)}, {ref(PLACE_OBJECTS)} and "
             f"{ref(PLACE_VILLAINS)} all pass over types 1 and 2 when they choose a cell, and "
             "those two types' boxes close all four sides. "
             f"Each is a bit in VISITED once he has been there ({ref(VISIT_CELL)}), and "
             f"{ref(PERCENTAGE)} counts a unit for each and three for each villain destroyed: "
             f"{len(standable)} and 12 make 637, which it turns into exactly 100%. Measured: "
             f"PERCENTAGE run with these {len(standable)} bits set gives {all_visited}% with the "
             f"four villains alive and {all_done}% with them gone.")
    kinds_text = "; ".join(
        f'<img class="ns-icon" src="images/world/antibody{kind}.png" alt=""> types with low bits '
        f"{kind} give graphic {FIND_GRAPHIC + 4 * kind}, carried as thing {FIRST_ANTIBODY + kind} "
        f"({INK_NAMES[thing_colours[FIRST_ANTIBODY + kind]]})"
        for kind in range(4))
    low = min(r[0] for r in stock_ranges[2:])
    high = max(r[1] for r in stock_ranges[2:])
    key_line("finds", f"every cell a find can come from, coloured by the kind of antibody it "
             f"gives. Every sixteenth turn {ref(SPAWN_FIND)} puts a find in the knight's cell if "
             f"its type has any left in STOCKS; the kind is the type's low two bits: {kinds_text}. "
             f"Measured: SPAWN_FIND run with the knight in a cell of each type made exactly that "
             f"graphic for types 2 to 35. The stock is the type's, shared by every cell of the "
             f"type, and {ref(STOCK_BUILDINGS)} sets it at every new game to {low}-{high} for "
             f"each type from 2 to 35 (measured over all 4096 places in the ROM it can read "
             f"from); types 0 and 1 get none, so open ground gives nothing, and type 2's stock "
             f"is never drawn on because no knight can stand in its one cell"
             + (f", {_cell_link(*type2[0], 2)}" if type2 else "") + ". A find left behind goes "
             f"back to its type's stock ({ref(FIND_WANDER)}).")
    heavy = sorted(start_counts.items(), key=lambda item: -item[1])[:5]
    key_line("start", f"{len(start_counts)} cells, every standable one. {ref(RANDOM_START_CELL)} "
             "takes ten bits of the random number as a cell of the map and, if it is solid, "
             "steps on through the map, wrapping at the end, to the next that is not; so a cell "
             "just after a run of solid ones in the map is chosen for the whole run. Measured: "
             "the routine run from just after its stir on all 1024 values gave these cells, each "
             "marked by how many of the 1024 choose it -- from 1 up to "
             + ", ".join(f"{count} for {_cell_link(c, r, nd.cell(memory, c, r))}"
                         for (c, r), count in heavy)
             + ". How likely each is in a real game depends on how even the random number's "
             "low ten bits are, which is not measured here.")
    key_line("placed", f"{len(placed_counts)} of the {len(standable)} standable cells. At a new "
             f"game {ref(PLACE_VILLAINS)} and then {ref(PLACE_OBJECTS)} each take the random "
             "number's low twelve bits as an address in the first 4K of the ROM and read the "
             "bytes from there in pairs, a column and a row each masked to 0-31, taking the "
             "first four that are not solid cells for their four records and passing over the "
             "rest. So only the cells some pair of the ROM's bytes spells can ever hold a villain "
             "or an object, and the same cells for both. Measured: both routines run from just "
             "after their stirs on all 4096 values put their four records in these cells and no "
             "others, the same four for the same value, and exactly where a walk of the ROM's "
             f"pairs from that address says; the furthest any walk reads is ${furthest - 1:04X}. "
             "Each cell is marked by how many of the 4 x 4096 places land there. Nothing keeps "
             "two apart, or a villain out of the knight's first cell.")
    key_line("game", "the four villains (V0-V3, records 0-3 at VILLAINS) and four objects "
             "(O0-O3; object record n kills villain n) in the simulator's game, the one this page "
             "was drawn from, at the start of its first turn after the knight appeared -- the "
             "objects where they were put, the villains a few steps on -- and the knight's first "
             "cell (K): "
             + "; ".join(f"V{i} {_cell_link(c, r, nd.cell(memory, c, r))} (graphic {g})"
                         for i, (c, r, g) in enumerate(game_villains))
             + "; "
             + "; ".join(f"O{i} {_cell_link(c, r, nd.cell(memory, c, r))} (graphic {g})"
                         for i, (c, r, g) in enumerate(game_objects))
             + f"; K {_cell_link(*game_start, nd.cell(memory, *game_start))}. Another game puts "
             "them elsewhere, but always in the cells of the last layer.")
    key_line("boxes", f"every cell's boxes (the lists at {ref(nd.BOX_TABLE)}), drawn on the ground "
             "where they stand: the walls the collision code tests the knight and everything "
             f"else against ({ref(HIT_BOXES_U)} and the routines round it), for every cell but "
             "the solid ones of types 1 and 2, whose four walls are whole. A gap in a wall is a "
             "way in. They are drawn here from the lists; the game never draws a box.")

    link_count = sum(1 for open_ in links.values() if open_)
    region_text = (f"all {len(standable)} are one region: the knight can walk from any to any"
                   if len(regions) == 1 else
                   f"they make {len(regions)} regions; the largest holds "
                   f"{len(regions[main_region])} cells, and "
                   + ", ".join(_cell_link(c, r, nd.cell(memory, c, r)) for c, r in cut_off)
                   + " cannot be walked to from it")

    lines = ['<div class="kl-list">',
             "<p>Nightshade's town is one map of 32 by 32 cells, a byte each, at "
             f"{ref(nd.MAP)}. Nothing else describes the world: a cell's byte is its type, and "
             "the type alone gives the building that stands on it (the building table, "
             f"{ref(nd.BUILDINGS)}, a definition for each way of looking at it), the boxes the "
             f"knight bumps into ({ref(nd.BOX_TABLE)}), the colour of its walls and the kind of "
             "find it gives. The screen shows the knight's cell and the eight round it, scrolled "
             f"so that he stays in the middle ({ref(PROJECT_CELL)}); this page draws all 1024 "
             "at once. The rooms, the grid and the room builder of "
             '<a href="../knightlore/RoomStructure.html">Knight Lore</a> and '
             '<a href="../alien8/RoomStructure.html">Alien 8</a> are gone: there are no rooms, '
             "no room records and no doorways, only cells.</p>",
             "<p><b>What is measured and what is read.</b> Measured, in SkoolKit's simulator, by "
             "calling the game's own routines: every picture (the walls by "
             f"{ref(DRAW_WALLS)}, the lines on the ground by {ref(DRAW_OUTLINE)}, the colours by "
             f"{ref(COLOUR_WALL)}), where each cell goes (by {ref(PROJECT_CELL)}, for every "
             "cell), the start cells, the cells objects and villains can be put in, the kind of "
             "find each type gives, the stocks and the percentage. Read from the tables: the "
             "types, the boxes. Worked out from the boxes, and then walked in the simulator: "
             "which neighbouring cells the knight can walk between. Put together by this page, "
             "not by the game: the whole town in one picture, back to front. Cells are given "
             "as (column, row).</p>",
             "<h3>The town</h3>",
             "<p>Every cell with a building is drawn by the game's own wall routine and put "
             "where the game's projection puts its corner; the cells further back are pasted "
             "first, so that nearer walls stand in front. The game itself never draws more than "
             "the cells round the knight, and draws only the walls behind him: the ones in front "
             "are reduced to their line on the ground, so as not to hide him "
             f"({ref(DRAW_CELLS)}). The faint outlines of the cells on the ground are the page's. "
             "The solid cells, types 1 and 2 -- the ring round the town and the blocks inside "
             "it, which nothing can ever be in -- are shown as black ground without their "
             "walls, which would bury the town; the game draws them like any other cell, and "
             '<a href="CellTypes.html#type1">cell types</a> shows them. '
             "This is the usual view, north on the panel's compass, the viewer at the high-U, "
             "low-V corner; the view turned round is below. Click a cell for its type, or "
             '<a href="images/world/town0.png">see the whole town at full size</a>. Tick a box '
             "to show a layer.</p>",
             '<div class="kl-layers">', "".join(toggles),
             '<div class="kl-castle"><div class="kl-castle-stack">'
             f'<img src="images/world/town0_overview.png" usemap="#town0" '
             f'alt="The town, in the usual view" width="{overview.width}" '
             f'height="{overview.height}">'
             + svg + "</div>"
             f'<map name="town0">{"".join(areas)}</map></div></div>']
    lines += keys
    walked_open = sum(1 for got in walked.values() if got)
    lines.append(f"<p><b>Walking about.</b> Taking two neighbouring cells to be joined where "
                 "the knight's box, centred on the edge between them, can stand somewhere along "
                 "it without meeting a box of either -- the test "
                 f"{ref(OVERLAP_U)} makes, with his half-size of {KNIGHT_HALF} halved as it "
                 f"halves it -- {link_count} of the {len(links)} edges are open, and of the "
                 f"{len(standable)} standable cells {region_text}. Then measured: for each of the "
                 f"{len(walked)} edges between two standable cells the knight was stood in the "
                 "middle of the first, level with the gap the boxes leave (or the middle of the "
                 f"edge where they leave none), facing the second, and walked for four seconds of "
                 "the game with everything else cleared out of his way; an edge he did not cross "
                 "was tried again from nearer it and after a few turns of the game. He crossed "
                 f"{walked_open} of them"
                 + (", exactly the open ones" if not disagree else
                    "; the reckoning and the walk disagree at "
                    + ", ".join(f"{_cell_link(*a, nd.cell(memory, *a))}-"
                                f"{_cell_link(*b, nd.cell(memory, *b))}" for a, b in disagree))
                 + ". The town's edge is all type 1, so nothing ever reaches the end of the "
                 "map, and the look-ups that do not check a column or a row against 32 never "
                 "need to.</p>")

    # The turned view.
    _, overview1, origin1 = maps[1]
    areas1 = []
    for column, row in order:
        kind = view_cell(memory, 1, column, row)
        x, y = _corner(column, row)
        x, y = x + origin1[0], y + origin1[1]
        if kind:
            points = [(x, y), (x + 128, y + 64), (x + 256, y), (x + 256, y - WALL_ABOVE),
                      (x + 128, y + 64 - WALL_ABOVE), (x, y - WALL_ABOVE)]
        else:
            points = [(x, y), (x + 128, y + 64), (x + 256, y), (x + 128, y - 64)]
        coords = ",".join(f"{round(px / scale)},{round(py / scale)}" for px, py in points)
        areas1.append(f'<area shape="poly" coords="{coords}" href="CellTypes.html#type{kind}" '
                      f'title="({31 - column},{31 - row}): type {kind}" '
                      f'alt="({31 - column},{31 - row})">')
    lines += ["<h3>The town turned round</h3>",
              "<p>Z or SYMBOL SHIFT turns the town round, to be seen from the opposite corner "
              "(VIEW; the panel then says south). Nothing is moved: the drawing reads the map "
              f"backwards from its last byte ({ref(LOOK_UP_CELL)}), which is column 31 - c and "
              f"row 31 - r ({ref(TURN_CELL)}), turns every position the same way, and takes each "
              "type's second building definition, which draws the building's other two walls "
              "-- the ones the usual view has at the back. Here is the whole town that way "
              "round, drawn the same way; "
              '<a href="images/world/town1.png">at full size</a>.</p>',
              '<div class="kl-castle"><div class="kl-castle-stack">'
              f'<img src="images/world/town1_overview.png" usemap="#town1" '
              f'alt="The town, turned round" width="{overview1.width}" '
              f'height="{overview1.height}">'
              f'</div><map name="town1">{"".join(areas1)}</map></div>']

    # The map's format.
    lines += ["<h3>The map</h3>",
              f"<p>{ref(nd.MAP)}: 1024 bytes, 32 rows of 32. A position in the town is a U and a "
              "V of 16 bits each, 256 units to a cell; the high byte of U is the cell's column "
              "and the high byte of V its row, so the cell is the byte at 32 times the row plus "
              f"the column ({ref(LOOK_UP_CELL)}; {ref(PLACE_IN_CELL)} for the collision code). "
              "The low bytes are the place within the cell: every record keeps its cell in its "
              "position, and there is nothing like a room number.</p>",
              '<table class="kl-table"><tr><th>Byte</th><th>Cells</th><th>What it is</th></tr>',
              f"<tr><td>0</td><td>{counts[0]}</td><td>Open ground: no building, no boxes, no "
              "finds. Nothing is drawn on it but what walks on it.</td></tr>",
              f"<tr><td>1</td><td>{counts[1]}</td><td>Solid: a building whose boxes close all "
              "four sides. The ring round the town and the blocks inside it. No find, and never "
              "a start or a place for a villain or object.</td></tr>",
              f"<tr><td>2</td><td>{counts[2]}</td><td>Solid too, with its own building: "
              + (", ".join(_cell_link(c, r, 2) for c, r in type2)) +
              ". It is given a stock of finds like the types above it, which nothing can "
              "take.</td></tr>",
              f"<tr><td>3-35</td><td>{1024 - counts[0] - counts[1] - counts[2]}</td><td>Built "
              f"on: {len(built)} types in the map"
              + (f" (types {_numbers(unused)} have buildings and boxes but no cell)" if unused
                 else "")
              + ". The type picks the building, two definitions for the two views; the boxes; "
              "the ink of the walls, from its low two bits (green, cyan, yellow, white); and "
              "the kind of find, from the same two bits.</td></tr>",
              "</table>",
              "<p>Every type's walls, outlines and boxes are on the "
              '<a href="CellTypes.html">cell types</a> page, and the 58 building definitions on '
              '<a href="Buildings.html">the buildings</a> page. How many cells of each type:</p>',
              '<table class="kl-table"><tr><th>Type</th><th>Cells</th><th>Type</th>'
              "<th>Cells</th><th>Type</th><th>Cells</th><th>Type</th><th>Cells</th></tr>"]
    rows = (nd.CELL_TYPES + 3) // 4
    for index in range(rows):
        cells = []
        for column in range(4):
            kind = index + rows * column
            if kind < nd.CELL_TYPES:
                cells.append(f"<td>{_type_link(kind)}</td><td>{counts[kind]}</td>")
            else:
                cells.append("<td></td><td></td>")
        lines.append("<tr>" + "".join(cells) + "</tr>")
    lines += ["</table>", "</div>"]
    return "\n".join(lines)


def _definition_label(address: int) -> str:
    return f"building{address:04x}"


def _buildings_page(memory, ref, definitions, starts, definition_of, counts) -> str:
    tile_address = {tile: _word(memory, nd.TILE_TABLE + 2 * tile) for tile in range(nd.TILE_COUNT)}
    lines = ['<div class="kl-list">',
             f"<p>{len(definitions)} building definitions, 32 bytes each, from "
             f"{ref(nd.BUILDING_DEFS, f'${nd.BUILDING_DEFS:04X}')} to "
             f"${nd.PANEL_CHARS - 1:04X}. The building table ({ref(nd.BUILDINGS)}) gives one for "
             "each cell type and each way round the town is seen: type times two, plus one "
             f"turned round; {2 * nd.CELL_TYPES - 2} entries, since open ground has none, reach "
             f"these {len(definitions)}. A definition is two faces of eight columns, each column "
             "a pair of tile numbers, the tile on the ground and the tile above it "
             f"({ref(nd.TILE_TABLE)}; the tiles are in the listing from {ref(nd.TILES)}).</p>",
             f"<p>{ref(DRAW_WALLS)} draws one from the cell's corner: the first face eight "
             "columns rightwards and down the screen, along the cell's low-V edge, and the "
             "second, mirrored, rightwards and up along its high-U edge -- the two edges nearer "
             f"the viewer. {ref(DRAW_WALL_COLUMN)} draws a column, the lower tile with its foot at "
             f"the column's place and the upper one 64 lines above ({ref(PUT_TILE)}); tiles are "
             "written over what is under them, clear pixels and all, so a wall hides what is "
             "behind it. The walls behind the knight are drawn this way. For a cell in front of "
             f"him, or his own, {ref(DRAW_OUTLINE)} draws only the line along the foot of all "
             "four walls instead, the far two from the other view's definition, with a gap "
             f"wherever a tile has an archway ({ref(nd.TILE_EDGES)}).</p>",
             "<p>Each picture below is the definition drawn by the game's own DRAW_WALLS in the "
             "simulator, in white (the game colours it by the cell type: see the "
             '<a href="CellTypes.html">cell types</a>, where each type\'s two views are side by '
             "side), and the tiles of each column, the upper above the lower. Where one "
             "definition serves several types or both views, every one was drawn and they are "
             "the same.</p>"]
    for address in definitions:
        users = starts[address]
        uses = []
        for index in users:
            kind, view = index >> 1, index & 1
            uses.append(f'{_type_link(kind, "type " + str(kind))} '
                        f"{'turned round' if view else 'in the usual view'}"
                        f" ({_plural(counts[kind], 'cell')})")
        faces = []
        for face in range(2):
            base = address + 16 * face
            uppers, lowers = [], []
            for column in range(8):
                lower, upper = memory[base + 2 * column], memory[base + 2 * column + 1]
                for tile, out in ((upper, uppers), (lower, lowers)):
                    tile_at = tile_address[tile]
                    out.append(f'<td><img src="images/tiles/{nd.tile_picture_name(tile_at)}" '
                               f'alt="tile {tile}"><br>{ref(tile_at, str(tile))}</td>')
            name = "First face" if face == 0 else "Second face, drawn mirrored"
            faces.append(f'<table class="ns-tiles"><tr><th>{name}'
                         f"</th>{''.join(uppers)}</tr><tr><th></th>{''.join(lowers)}</tr>"
                         "</table>")
        lines += [f'<div class="kl-item" id="{_definition_label(address)}">',
                  '<div class="ns-row">',
                  f'<img class="ns-building" src="images/world/building{address:04x}.png" '
                  f'alt="The building at ${address:04X}">',
                  f"<div><p><b>{ref(address, f'${address:04X}')}</b>: for " + "; ".join(uses)
                  + ".</p>",
                  "".join(faces),
                  "</div></div></div>"]
    lines.append("</div>")
    return "\n".join(lines)


def _cell_types_page(memory, ref, counts, cells_of, definition_of, ink_of, finds, stock_ranges,
                     game_stocks, thing_colours, start_counts, placed_counts) -> str:
    lines = ['<div class="kl-list">',
             f"<p>The {nd.CELL_TYPES} cell types, the numbers the town map holds "
             f"({ref(nd.MAP)}). A type is all there is to a cell: it picks the building that "
             f"stands on it, two definitions for the two ways round ({ref(nd.BUILDINGS)}); the "
             f"boxes the knight and everything else bump into ({ref(nd.BOX_TABLE)}, tested by "
             f"{ref(HIT_BOXES_U)}); the ink of its walls ({ref(COLOUR_WALL)}: bright green, "
             "cyan, yellow or white by its low two bits); and, from the same two bits, the "
             f"kind of antibody found in it ({ref(SPAWN_FIND)}), from a stock the type's cells "
             "share.</p>",
             "<p>For each type: its walls in the usual view and turned round, as the game draws "
             f"them behind the knight ({ref(DRAW_WALLS)}); the line on the ground it draws "
             f"instead when the cell is in front of him or is his own ({ref(DRAW_OUTLINE)}), both "
             "ways round; and its boxes, drawn on the cell's ground in the same projection -- the "
             "page's drawing of the list, since the game never draws a box. A box is its centre "
             "and its half-sizes in half units: a cell runs from 64 to 191 each way, U down to "
             "the right and V up to the right. All the pictures but the boxes are the game's own "
             "code run in the simulator.</p>"]
    for kind in range(nd.CELL_TYPES):
        boxes = cell_boxes(memory, kind)
        cells = cells_of.get(kind, [])
        lines.append(f'<div class="kl-item" id="type{kind}">')
        if kind:
            views = []
            for view in (0, 1):
                way = "turned round" if view else "the usual view"
                views.append(f'<figure class="ns-view"><img class="ns-view" '
                             f'src="images/world/type{kind}_{view}.png" alt="Type {kind}, {way}">'
                             f"<figcaption>Walls, {way}</figcaption></figure>")
            for view in (0, 1):
                way = "turned round" if view else "the usual view"
                views.append(f'<figure class="ns-view"><img class="ns-view" '
                             f'src="images/world/type{kind}_{view}_outline.png" '
                             f'alt="Type {kind}, on the ground, {way}">'
                             f"<figcaption>On the ground, {way}</figcaption></figure>")
            lines.append('<div class="ns-row">' + "".join(views) + "</div>")
        lines.append('<div class="ns-row"><figure class="ns-view"><img class="ns-plan" '
                     f'src="images/world/type{kind}_boxes.png" alt="Type {kind}, its boxes">'
                     "<figcaption>Boxes</figcaption></figure><div>")
        facts = []
        if kind == 0:
            facts.append("open ground: no building (both of its table entries are 0), no boxes, "
                         "no finds")
        else:
            usual, turned = definition_of[(kind, 0)], definition_of[(kind, 1)]
            if usual == turned:
                facts.append(f'building <a href="Buildings.html#building{usual:04x}">'
                             f"${usual:04X}</a> both ways round")
            else:
                facts.append(f'building <a href="Buildings.html#building{usual:04x}">'
                             f"${usual:04X}</a>, and turned round "
                             f'<a href="Buildings.html#building{turned:04x}">${turned:04X}</a>')
            facts.append(f"walls in bright {INK_NAMES[ink_of[kind]]}")
        if kind in (1, 2):
            facts.append("solid: never chosen for a start, a villain or an object, and closed "
                         "on all four sides")
        if kind >= 2:
            find = finds[kind]
            thing = FIRST_ANTIBODY + (kind & 3)
            facts.append(f'finds: <img class="ns-icon" src="images/world/antibody{kind & 3}.png" '
                         f'alt=""> graphic {find[0]}, antibody thing {thing} '
                         f"({INK_NAMES[thing_colours[thing]]}); a stock of "
                         f"{stock_ranges[kind][0]}-{stock_ranges[kind][1]} at each new game, "
                         f"{game_stocks[kind]} in the simulator's"
                         + (" -- which nothing can take, since no knight can be in the cell"
                            if kind == 2 else ""))
        if boxes:
            facts.append(f"{_plural(len(boxes), 'box', 'boxes')} "
                         f"({ref(_word(memory, nd.BOX_TABLE + 2 * kind))})")
        where = ""
        if not cells:
            where = "No cell of the town has this type."
        elif kind in (0, 1):
            where = f"{_plural(len(cells), 'cell')} of the town."
        elif kind == 2:
            where = "One cell: " + ", ".join(f"({c},{r})" for c, r in cells) + "."
        else:
            starts = sum(start_counts.get(c, 0) for c in cells)
            placed = sum(1 for c in cells if c in placed_counts)
            where = (f"{_plural(len(cells), 'cell')}: "
                     + ", ".join(f"({c},{r})" for c, r in cells)
                     + f". Chosen by {starts} of the 1024 values of a new game's start "
                     f"({ref(RANDOM_START_CELL)}); {placed} of them can hold a villain or an "
                     "object.")
        lines.append(f"<p><b>Type {kind}</b>: " + "; ".join(facts) + ". " + where + "</p>")
        if boxes:
            lines.append('<table class="kl-table"><tr><th>Centre U</th><th>Centre V</th>'
                         "<th>Half-size U</th><th>Half-size V</th><th>Where</th></tr>"
                         + "".join(f"<tr><td>{cu}</td><td>{cv}</td><td>{su}</td><td>{sv}</td>"
                                   f"<td>{_box_where(cu, cv, su, sv)}</td></tr>"
                                   for cu, cv, su, sv in boxes)
                         + "</table>")
        lines.append("</div></div></div>")
    lines.append("</div>")
    return "\n".join(lines)


def _box_where(cu: int, cv: int, su: int, sv: int) -> str:
    """Which edge of the cell a box stands on, and how much of it."""
    if su <= 2 and sv <= 2:
        return "a post at a corner" if cu in (66, 190) and cv in (66, 190) else "a post"
    if sv <= 2:
        edge = "low-V" if cv < 128 else "high-V"
        span, along = su, cu
    elif su <= 2:
        edge = "high-U" if cu > 128 else "low-U"
        span, along = sv, cv
    else:
        return "inside the cell"
    if span >= 64:
        return f"the whole {edge} edge"
    if su <= 4 and sv <= 4:
        return f"a post on the {edge} edge"
    return f"part of the {edge} edge, {along - span} to {along + span}"
