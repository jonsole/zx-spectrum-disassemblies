"""Cyberun's planet: the Planet, Tiles, WorldObjects and PickupPlaces pages,
drawn from the game at build time.

build_cyberun.py --html calls build(), which draws the whole map, every tile
and every kind of thing lying in the world with the game's own code into the
HTML directory, and returns the pages' sections. Like everything the build
writes from the game, none of it is committed: the pictures are the game's,
and so are the map, the tiles and the tables decoded here.

How the landscape is drawn. The game is started in SkoolKit's simulator the
way the build's sessions start it (build_cyberun.Machine, _start), to the
first pass of play, so every table the start-up builds is there. Then each
pass is the game's own scroll_landscape ($DDF8) run from its entry to the
CALL to draw_beams, with the stack where the play loop has it (SP $5B7C: the
renderer reloads SP from stack_top, $5B7A, after each piece, which is right
only at that depth). The screen is never cleared by the game -- only the
strips a moving edge uncovers are painted -- so a cell drawn once from a
standing start shows only its outline. The game gets a correct screen by the
fly-in: the play area filled first, then the view moved a page with the
fills painting behind every moving piece. This module does the same thing
over the whole depth of the planet: for each map column the play area starts
black (the sky above row 3, where the map holds no pieces), and the view
descends 4 lines a pass from row 2 to the bottom of the map, so every piece
comes up from the bottom of the play area and the game's fills paint the
ground under each floor and the cavern under each ceiling as it goes. The
play area is read whenever the view lies exactly on a cell. No region is
filled here. (One trap: draw_landscape culls whole pieces by the collision
boxes it records only when the view has crossed a cell or map_rebuild is
set; a view put somewhere by hand and drawn without either is culled by the
old cells' boxes and draws nothing. The descent crosses a cell on its first
pass; the one-pass drawing on the Planet page runs a map_rebuild pass first.)

The things in the world are drawn by the game too: one at a time, with the
landscape emptied in a scratch copy of the map, brought in by the game's own
load_map_window ($DF08) into a ground-object slot and drawn by
update_ground_objects ($AC60) in the same pass.
"""
from __future__ import annotations

import html
import re
from pathlib import Path

# --------------------------------------------------------------------------
# Addresses (see their entries in the listing).
# --------------------------------------------------------------------------

PLAY_LOOP = 0xF46C          # the play loop: also the sentinel return address
SCROLL_LANDSCAPE = 0xDDF8   # one pass of scrolling and drawing
DRAW_BEAMS = 0x9BDA         # the pass is stopped at scroll_landscape's CALL to it
DRAW_LANDSCAPE = 0xD0BD
DRAW_STARS = 0xBFE3
LOAD_MAP_WINDOW = 0xDF08
UPDATE_GROUND_OBJECTS = 0xAC60
FILL_BEHIND = 0xD9A8        # fill_behind_moving_piece
FILL_UNDER_SLOPE = 0xE41C
START_LANDSCAPE = 0xDCA1
FLY_IN_STEP = 0xDD79
SAVE_RESTART_POINT = 0xC33C
COLOUR_PIECE = 0xCF38
STACK_IN_PASS = 0x5B7C      # SP at scroll_landscape: two below stack_top's top
STACK_TOP = 0x5B7A

LANDSCAPE_MAP = 0x61BC      # 96 x 28 tile numbers, row 1 first
TILE_TABLE = 0x6C3C         # 171 words
TILE_RECORDS = 0x6D92
TILE_RECORDS_END = 0x70D8
TILE_COUNT = 171
MAP_COLUMNS = 96
MAP_ROWS = 28
READ_MAP_CELL = 0xE235
UPSIDE_DOWN = 0x99
MIRRORED = 0xFF
PADDING = 0x95              # a byte from $95 up before the count is skipped
BEAM_TILE = 0xA6            # draw_beams draws a beam across a cell of this tile
FLY_IN_SWAP = (0x3E, 0xAA)  # load_map_window: tile $3E drawn as $AA in the fly-in

ORIGIN_X = 0xCE41
ORIGIN_Y = 0xCE42
VIEW_X = 0xCE45
VIEW_Y = 0xCE46
VIEW_COLUMN = 0xCE57
VIEW_ROW = 0xCE58
SCROLL_DOWN = 0xCCBA
SCROLL_ACROSS = 0xCCBB
MAP_REBUILD = 0x5C3C
GROUND_ATTR_ABOVE = 0xDC95
GROUND_ATTR_BELOW = 0xDC96
PLANET_GROUND_COLOURS = 0xDC97
CAVERN_ROW = 0x0C           # set_landscape_colours: the second colour from row 12

MAP_OBJECT_KINDS = 0x5C94
MAP_OBJECTS_PER_COLUMN = 0x5DB6
MAP_OBJECT_PLACES = 0x5E17
OBJECT_COUNT = 290
OBJECT_KIND_FLAGS = 0xE0FD
OBJECT_PART_PAIRS = 0xE10E
OBJECT_KIND_BYTES = 0xE205  # the kinds' colours
KIND_COUNT = 17
SPAWN_COLUMN_OBJECTS = 0xE08F
SPAWN_OBJECTS_FROM_LIST = 0xE114
GROUND_OBJECT_FIRES = 0x8820
FIRE_FROM = 0x882B
SHOT_KIND_FLAGS = 0x89A7
SHOT_KIND_TEMPLATES = 0x89AF
SMALL_OBJECT_EFFECTS = 0x944C
SHIP_HITS_GROUND_OBJECTS = 0xA8F4
BEAM_HITS_GROUND_OBJECT = 0xABA8
MAP_SQUARE_BIT = 0xAC08
DRAW_BEAMS_ROUTINE = 0x9BDA
BEAM_HITS_SHIP = 0x9D0E
LOAD_ORE = 0xA8A5
ANIMATE_OBJECT = 0x910A
CONTACT_EFFECT = 0x8E2C
PLAYER_FLAG_BITS = 0xF5EA
GROUND_OBJECTS = 0xA80B
SLOT_SIZE = 26
SLOTS = 6
GROUND_SLOTS = 4
PICKUP_RECORD = 0xA873
ANIMATED_GRAPHIC = 0x1B
PLAIN_GRAPHIC = 0x0D
MASK_WORLD_OBJECTS = 0x9A8A

PLACE_POOL = 0x605B         # place_pool_kind3, the first of the five groups
POOL_GROUPS = {3: 0x605B, 1: 0x609B, 5: 0x60DB, 2: 0x60E3, 4: 0x6103}
POOL_PLACES = 46
POOL_KIND2_NEVER = (0x60E3, 0x60EB)   # deal_places marks these dealt at once
DEALING_LIST = 0x61A9
DEALING_COUNT = 19
DEAL_PLACES = 0x6113
DEALING_LIST_LAST = 0x61BB
NEW_GAME = 0xF3BD
PLANET_SECURED = 0x83D6
PLAYER_PLACES = 0xF604      # the current player's 19 places
OTHER_PLAYER_PLACES = 0xF66D
PLACE_SIZE = 4
ADDON_PLACES = 11           # places 0-10 are kind $0C, 11-18 kind $1E
ADDON_GRAPHICS = 0xAF95
ROCKET_PART_FRAMES = 0xAF7B
COLLECT_PICKUP = 0xAAD7
CARRIED_PART = 0xC1CE
RANDOM_A = 0x9BCB

ROCKET_X = 0x96AC           # a word: the pixel, then the page column
ROCKET_Y = 0x96AE           # a word: the line, then the page row
DRAW_ROCKET = 0x9572
DROP_PART = 0x9724
SHIP_RECORD = 0xC8E5
START_POSITION = 0xF3B7
CLEAR_PLAYER_RECORD = 0xF39E

# The play area on the screen: byte columns 1-28, lines $18-$B7.
PLAY_TOP = 0x18
PLAY_LINES = 160
PLAY_COLUMN = 1
PLAY_BYTES = 28
CELL_W = 224
CELL_H = 160
PAGE_X0 = 8                 # a page's x runs from 8 to $E7 ...
PAGE_Y0 = 0x18              # ... and its y from $18 to $B7

# The descent: 4 lines a pass, the step the fly-in uses.
DESCEND = 0xFC
FIRST_VIEW_ROW = 2          # draw_landscape is not called above view row 3
TSTATES = 3500000

# The pictures.
OVERVIEW_SCALE = 16         # the overview: a cell 14 x 10 pixels
FULL_SCALE = 2              # the whole planet at half size
SPRITE_ZOOM = 3

PALETTE = [(0, 0, 0), (0, 0, 0xD7), (0xD7, 0, 0), (0xD7, 0, 0xD7),
           (0, 0xD7, 0), (0, 0xD7, 0xD7), (0xD7, 0xD7, 0), (0xD7, 0xD7, 0xD7),
           (0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF),
           (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0), (0xFF, 0xFF, 0xFF)]
COLOUR_NAMES = ["black", "blue", "red", "magenta", "green", "cyan", "yellow", "white"]

DIRECTION_NAMES = [
    "flat floor", "gentle slope up to the right", "45-degree slope up to the right",
    "steep slope up to the right", "gentle slope up to the left",
    "45-degree slope up to the left", "steep slope up to the left",
    "flat ceiling", "gentle ceiling slope, right", "45-degree ceiling slope, right",
    "steep ceiling slope, right", "gentle ceiling slope, left",
    "45-degree ceiling slope, left", "steep ceiling slope, left",
    "wall stepping right", "wall stepping left"]
# upside_down_table ($CE14) and mirror_table ($CE04), as draw_landscape uses them.
UPSIDE_DOWN_TABLE = 0xCE14
MIRROR_TABLE = 0xCE04

# Names by appearance or by what the code does with them (the notes:
# attackers.md, world-and-objects-in-it.md, rocket-and-ore.md).
KIND_NAMES = {0: "flask", 3: "spiky mound", 4: "lamp", 5: "domed robot",
              6: "beam generator", 7: "beam generator", 8: "ore deposit",
              9: "ore deposit", 0x0A: "ore deposit", 0x0C: "domed robot",
              0x0D: "pylon craft", 0x0E: "refuel pad", 0x01: "pedestal", 0x02: "cloud",
              0x0B: "ringed planet", 0x0F: "saucer", 0x10: "lamp"}
ORE_KINDS = (8, 9, 0x0A)        # beam_hits_ground_object: kinds 8 to $0A
GENERATOR_KINDS = (6, 7)        # beam_hits_ground_object: kinds 6 and 7
BEAM_PROOF_KIND = 0x0B          # beam_hits_ground_object: not kind $0B
REFUEL_FRAMES = (4, 5)          # ship_hits_ground_objects: graphic $1B, frame 4 or 5
ADDON_NAMES = {1: "the hook", 2: "the second hook", 3: "the ore tank",
               4: "the side jet (a block)", 5: "the lift jet (arches)",
               6: "the fuel saver (a mound)", 7: "the special beam (a post)",
               8: "the missiles (a bar)", 9: "the figure", 10: "the slab", 11: "the spire"}
PART_NAMES = {0: "a section of bars", 1: "a checked section", 2: "a crate-like section",
              3: "a crate-like section", 4: "a fin", 5: "a fin", 6: "the ore tank",
              7: "the nose cone"}


def _word(memory, address: int) -> int:
    return memory[address] | memory[address + 1] << 8


def _esc(text) -> str:
    return html.escape(str(text), quote=False)


def _hex(number: int) -> str:
    return f"${number:02X}"


def _numbers(values) -> str:
    values = sorted(set(values))
    runs, start = [], None
    for index, value in enumerate(values):
        if start is None:
            start = value
        if index + 1 == len(values) or values[index + 1] != value + 1:
            runs.append(_hex(start) if start == value else f"{_hex(start)}-{_hex(value)}")
            start = None
    return ", ".join(runs)


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
        return f"{text} (${address:04X})" if text else f"${address:04X}"


# --------------------------------------------------------------------------
# The game's tables, decoded.
# --------------------------------------------------------------------------

def tile_record(memory, tile: int) -> dict:
    """Tile `tile`'s record, read the way draw_landscape reads it ($D0BD):
    the markers, the padding, the count, then each piece -- x, y, direction
    and steps, and the two end codes of a flat piece."""
    start = _word(memory, TILE_TABLE + 2 * tile)
    address = start
    upside = mirrored = False
    padding = None
    if memory[address] == 0:
        return {"tile": tile, "address": start, "base": start, "upside": False,
                "mirrored": False, "padding": None, "pieces": [], "end": start + 1}
    if memory[address] == UPSIDE_DOWN:
        upside = True
        address += 1
    if memory[address] == MIRRORED:
        mirrored = True
        address += 1
    if memory[address] >= PADDING:
        padding = memory[address]
        address += 1
    base = address
    count = memory[address]
    address += 1
    pieces = []
    for _ in range(count):
        x, y, code = memory[address], memory[address + 1], memory[address + 2]
        address += 3
        direction, steps = code >> 4, (code & 15) or 16
        ends = None
        if direction in (0, 7):
            ends = (memory[address], memory[address + 1])
            address += 2
        drawn = direction
        if upside:
            drawn = memory[UPSIDE_DOWN_TABLE + drawn]
        if mirrored:
            drawn = memory[MIRROR_TABLE + drawn]
        pieces.append({"x": x, "y": y, "direction": direction, "steps": steps,
                       "ends": ends, "drawn": drawn})
    return {"tile": tile, "address": start, "base": base, "upside": upside,
            "mirrored": mirrored, "padding": padding, "pieces": pieces, "end": address}


def landscape_map(memory) -> list[list[int]]:
    """map[row][column] for rows 1-28 (row 0, the sky, is not stored)."""
    out = [[0] * MAP_COLUMNS]
    for row in range(1, MAP_ROWS + 1):
        address = LANDSCAPE_MAP + (row - 1) * MAP_COLUMNS
        out.append(list(memory[address:address + MAP_COLUMNS]))
    return out


def world_objects(memory) -> list[dict]:
    """The 290 objects, unpacked the way spawn_objects_from_list does: the
    column from the running count, the rest from the two position bytes."""
    out = []
    index = 0
    for column in range(MAP_COLUMNS):
        for _ in range(memory[MAP_OBJECTS_PER_COLUMN + column]):
            first = memory[MAP_OBJECT_PLACES + 2 * index]
            second = memory[MAP_OBJECT_PLACES + 2 * index + 1]
            out.append({"index": index, "kind": memory[MAP_OBJECT_KINDS + index] & 0x3F,
                        "column": column, "row": second & 0x1F,
                        "x": (first & 3) << 3 | (second & 0xE0), "y": (first & 0xFC) - 1})
            index += 1
    if index != OBJECT_COUNT:
        raise RuntimeError(f"the column counts add up to {index}, not {OBJECT_COUNT}")
    return out


def kind_table(memory) -> list[dict]:
    """Each kind's flags, as spawn_objects_from_list uses them: the shot kind
    (bits 7-5), animated (bit 4) with its frames from object_part_pairs, and
    its two colours."""
    out = []
    for kind in range(KIND_COUNT):
        flags = memory[OBJECT_KIND_FLAGS + kind]
        entry = {"kind": kind, "flags": flags, "shot": flags >> 5,
                 "animated": bool(flags & 0x10), "colours": memory[OBJECT_KIND_BYTES + kind]}
        if entry["animated"]:
            pair = OBJECT_PART_PAIRS + (flags & 0x0F)
            entry["frame_byte"] = memory[pair]
            entry["range"] = memory[pair + 1]
            entry["frames"] = (memory[pair + 1] >> 4, memory[pair + 1] & 15)
        out.append(entry)
    return out


def shot_effects(memory) -> dict[int, dict]:
    """Each shot kind 1-8: the frame of type $1C it is thrown as
    (shot_kind_templates, the third byte's low nibble) and that frame's
    contact effect (small_object_effects)."""
    out = {}
    for shot in range(1, 9):
        template = SHOT_KIND_TEMPLATES + 4 * (shot - 1)
        frame = memory[template + 2] & 15
        last = memory[template + 3] & 15
        out[shot] = {"frame": frame, "last": last,
                     "effect": memory[SMALL_OBJECT_EFFECTS + frame]}
    return out


def pool_places(memory) -> list[dict]:
    """The 46 places of the pool, group by group in memory order."""
    starts = sorted(POOL_GROUPS.items(), key=lambda item: item[1])
    out = []
    for position, (group, start) in enumerate(starts):
        end = starts[position + 1][1] if position + 1 < len(starts) \
            else PLACE_POOL + POOL_PLACES * PLACE_SIZE
        for number, address in enumerate(range(start, end, PLACE_SIZE)):
            out.append({"group": group, "number": number, "address": address,
                        "column": memory[address] & 0x7F, "row": memory[address + 1],
                        "x": memory[address + 2], "y": memory[address + 3],
                        "never": address in POOL_KIND2_NEVER})
    if len(out) != POOL_PLACES:
        raise RuntimeError(f"the pool has {len(out)} places, not {POOL_PLACES}")
    return out


# --------------------------------------------------------------------------
# The game in the simulator.
# --------------------------------------------------------------------------

class Game:
    """The game in the simulator at the first pass of play, with every
    thing in the world and every dealt place marked gone (so that only the
    landscape is drawn unless one is brought back), as the base each picture
    is drawn from."""

    def __init__(self, snapshot: Path):
        import numpy as np

        import build_cyberun as bc

        self.np = np
        lines = np.arange(PLAY_TOP, PLAY_TOP + PLAY_LINES)
        self.line_offsets = ((lines & 0xC0) << 5) | ((lines & 7) << 8) | ((lines & 0x38) << 2)
        self.attr_offsets = 0x1800 + (lines >> 3) * 32
        self.machine = bc.Machine(snapshot)
        self.machine.play(bc._start(), "the planet's start")
        self.simulator = self.machine.simulator
        memory = self.simulator.memory
        # The game's own first screen and the ship's place, before anything
        # is changed: the start position, measured.
        self.first_screen = self.capture()
        self.first_view = (memory[VIEW_COLUMN], memory[VIEW_ROW], memory[VIEW_X], memory[VIEW_Y],
                           memory[ORIGIN_X], memory[ORIGIN_Y])
        self.ship = (memory[SHIP_RECORD + 1], memory[SHIP_RECORD + 2],
                     memory[SHIP_RECORD + 4], memory[SHIP_RECORD + 5])
        self.dealt = [tuple(memory[PLAYER_PLACES + PLACE_SIZE * n:
                                   PLAYER_PLACES + PLACE_SIZE * n + PLACE_SIZE])
                      for n in range(DEALING_COUNT)]
        for index in range(OBJECT_COUNT):
            memory[MAP_OBJECT_KINDS + index] |= 0xC0
        for base in (PLAYER_PLACES, OTHER_PLAYER_PLACES):
            for n in range(DEALING_COUNT):
                memory[base + PLACE_SIZE * n] |= 0x80
        for slot in range(SLOTS):
            memory[GROUND_OBJECTS + SLOT_SIZE * slot] = 0xFF
            memory[GROUND_OBJECTS + SLOT_SIZE * slot + 0x10] = 0
        self.base = bytes(memory)
        self.base_registers = list(self.simulator.registers)
        code = self.base[SCROLL_LANDSCAPE:LOAD_MAP_WINDOW]
        call = bytes([0xCD, DRAW_BEAMS & 0xFF, DRAW_BEAMS >> 8])
        if code.count(call) != 1:
            raise RuntimeError("scroll_landscape's CALL to draw_beams was not found")
        self.stop = SCROLL_LANDSCAPE + code.index(call)

    def reset(self) -> None:
        memory = self.simulator.memory
        memory[:] = self.base
        for index, value in enumerate(self.base_registers):
            self.simulator.registers[index] = value

    def _trace(self, start: int, stop: int, seconds: float = 2.0) -> None:
        from skoolkit.simutils import PC, T

        simulator = self.simulator
        simulator.trace(start, stop, 0, simulator.registers[T] + int(seconds * TSTATES),
                        False, None, None, None, None, None)
        if simulator.registers[PC] != stop:
            raise RuntimeError(f"the game never reached ${stop:04X} from ${start:04X} "
                               f"(stopped at ${simulator.registers[PC]:04X})")

    def call(self, address: int, hl: int | None = None) -> None:
        """Call a routine of the game's with the stack where the play loop
        has it, and run it to its return."""
        from skoolkit.simutils import H, L, SP

        registers = self.simulator.registers
        memory = self.simulator.memory
        if hl is not None:
            registers[H], registers[L] = hl >> 8, hl & 0xFF
        sp = STACK_IN_PASS - 2
        memory[sp], memory[sp + 1] = PLAY_LOOP & 0xFF, PLAY_LOOP >> 8
        registers[SP] = sp
        self._trace(address, PLAY_LOOP)

    def scroll_pass(self, down: int) -> None:
        """One pass of scroll_landscape, stopped where it calls draw_beams:
        the view moved, the window rebuilt if a cell was crossed, the
        ground objects updated and drawn, and the landscape drawn."""
        from skoolkit.simutils import SP

        memory = self.simulator.memory
        memory[SCROLL_DOWN] = down & 0xFF
        memory[SCROLL_ACROSS] = 0
        self.simulator.registers[SP] = STACK_IN_PASS
        self._trace(SCROLL_LANDSCAPE, self.stop)

    def capture(self):
        """The play area as colour numbers 0-15 (BRIGHT adds 8), 160 x 224."""
        np = self.np
        screen = np.frombuffer(bytes(self.simulator.memory[0x4000:0x5B00]), np.uint8)
        columns = np.arange(PLAY_COLUMN, PLAY_COLUMN + PLAY_BYTES)
        bits = np.unpackbits(screen[self.line_offsets[:, None] + columns[None, :]], axis=1)
        attrs = screen[self.attr_offsets[:, None] + columns[None, :]].astype(np.uint8)
        bright = (attrs & 0x40) >> 3
        ink = np.repeat((attrs & 7) | bright, 8, axis=1)
        paper = np.repeat(((attrs >> 3) & 7) | bright, 8, axis=1)
        out = np.where(bits == 1, ink, paper).astype(np.uint8)
        # BRIGHT black is black: one number for it, so that "not 0" is ink.
        out[out == 8] = 0
        return out

    def clear_play_area(self, checker: bool, attr: int) -> None:
        """The play area black, or filled with the checker the way
        start_landscape fills it ($55 on the odd lines, $AA on the even), in
        one colour."""
        memory = self.simulator.memory
        for index, offset in enumerate(self.line_offsets):
            line = PLAY_TOP + index
            value = (0x55 if line & 1 else 0xAA) if checker else 0
            start = 0x4000 + int(offset) + PLAY_COLUMN
            memory[start:start + PLAY_BYTES] = bytes([value]) * PLAY_BYTES
        for row in range(PLAY_TOP // 8, (PLAY_TOP + PLAY_LINES) // 8):
            start = 0x5800 + row * 32 + PLAY_COLUMN
            memory[start:start + PLAY_BYTES] = bytes([attr]) * PLAY_BYTES

    def set_view(self, column: int, row: int) -> None:
        """The view's page at (column, row), lying exactly on the page
        below: origin_x 0 (view_x 8) and origin_y 0 (view_y $B7)."""
        memory = self.simulator.memory
        memory[VIEW_COLUMN], memory[VIEW_ROW] = column, row
        memory[ORIGIN_X], memory[VIEW_X] = 0, PAGE_X0
        memory[ORIGIN_Y], memory[VIEW_Y] = 0, 0xB7
        memory[MAP_REBUILD] = 0

    def descend(self, column: int, rows, start_row: int = FIRST_VIEW_ROW,
                checker: bool = False) -> dict:
        """Start the view on (column, start_row) over a play area cleared to
        black (or the checker), and let it descend 4 lines a pass. Each time
        it lies exactly on a cell, that cell -- the row below the view's --
        is read off the screen if it is one of `rows`."""
        memory = self.simulator.memory
        self.set_view(column, start_row)
        self.clear_play_area(checker, memory[GROUND_ATTR_ABOVE])
        wanted = set(rows)
        out = {}
        while wanted - set(out):
            self.scroll_pass(DESCEND)
            if memory[ORIGIN_Y] == 0:
                row = memory[VIEW_ROW] + 1
                if row in wanted:
                    out[row] = self.capture()
                if row > max(wanted):
                    raise RuntimeError(f"column {column}: passed row {row} without "
                                       f"reading {sorted(wanted - set(out))}")
        return out

    def specimen(self, column: int, row: int, setup, passes: int = 24) -> list:
        """A thing drawn by the game alone: the map emptied (a scratch
        copy), the play area black, `setup(memory)` bringing back the one
        thing to draw, the view put on (column, row - 1) lying on row `row`,
        the window built by load_map_window, and `passes` passes run without
        scrolling. Returns each pass's play area and the slot records."""
        memory = self.simulator.memory
        self.reset()
        memory[LANDSCAPE_MAP:LANDSCAPE_MAP + MAP_COLUMNS * MAP_ROWS] = \
            bytes(MAP_COLUMNS * MAP_ROWS)
        setup(memory)
        self.set_view(column, row - 1)
        self.clear_play_area(False, memory[GROUND_ATTR_ABOVE])
        self.call(LOAD_MAP_WINDOW, (row - 1) << 8 | column)
        out = []
        for _ in range(passes):
            self.scroll_pass(0)
            slots = [bytes(memory[GROUND_OBJECTS + SLOT_SIZE * s:
                                  GROUND_OBJECTS + SLOT_SIZE * (s + 1)]) for s in range(SLOTS)]
            out.append((self.capture(), slots))
        return out


# --------------------------------------------------------------------------
# Pictures.
# --------------------------------------------------------------------------

def _rgb(indices):
    import numpy as np

    return np.array(PALETTE, np.uint8)[indices]


def _save_cell(indices, path: Path) -> None:
    """A play-area picture at its own size, as a 16-colour PNG."""
    from PIL import Image

    image = Image.fromarray(indices, "P")
    image.putpalette([value for colour in PALETTE for value in colour])
    image.save(path, optimize=True)


def _sprite(captures, path: Path, zoom: int = SPRITE_ZOOM) -> tuple | None:
    """The ink of a thing drawn alone on a black play area, cropped to what
    was drawn, black left clear, and enlarged. Returns its size in pixels
    (unenlarged), or None if nothing was drawn."""
    import numpy as np
    from PIL import Image

    ink = captures != 0
    if not ink.any():
        return None
    rows = np.where(ink.any(axis=1))[0]
    columns = np.where(ink.any(axis=0))[0]
    crop = captures[rows[0]:rows[-1] + 1, columns[0]:columns[-1] + 1]
    rgba = np.zeros(crop.shape + (4,), np.uint8)
    rgba[..., :3] = _rgb(crop)
    rgba[..., 3] = np.where(crop != 0, 255, 0)
    image = Image.fromarray(rgba, "RGBA")
    image = image.resize((image.width * zoom, image.height * zoom), Image.NEAREST)
    image.save(path, optimize=True)
    return (crop.shape[1], crop.shape[0])


def _distinct(images) -> list:
    """The images that differ in shape (where ink is), first seen first."""
    out, seen = [], []
    for image in images:
        shape = image != 0
        if not shape.any():
            continue
        if not any((shape == other).all() for other in seen):
            seen.append(shape)
            out.append(image)
    return out


# The layers on the planet's overview: (key, what, colour, shown at first).
LAYERS = [
    ("start", "Where a game starts", (60, 230, 60), True),
    ("rocket", "The rocket's place", (255, 255, 255), True),
    ("group1", "Pick-up places, group 1", (255, 220, 40), True),
    ("group2", "Pick-up places, group 2", (255, 140, 0), True),
    ("group3", "Pick-up places, group 3", (70, 160, 255), True),
    ("group4", "Pick-up places, group 4", (255, 90, 200), True),
    ("group5", "Pick-up places, group 5", (170, 120, 255), True),
    ("refuel", "Refuel pads", (0, 255, 255), False),
    ("ore", "Ore deposits", (200, 160, 90), False),
    ("generators", "Beam generators", (255, 255, 120), False),
    ("beams", "Flickering-beam screens (tile $A6)", (255, 40, 40), False),
    ("hurt", "Things that throw what hurts", (255, 70, 70), False),
    ("thief", "Things that throw the fuel thief", (190, 90, 255), False),
    ("fuel", "Things that throw fuel", (120, 255, 160), False),
    ("other", "Everything else lying on the planet", (170, 170, 170), False),
]
MARKER_RADIUS = 2.6
MARKER_SUPERSAMPLE = 4


def _markers(size, points, colour, shape="dot"):
    from PIL import Image, ImageDraw

    big = MARKER_SUPERSAMPLE
    image = Image.new("RGBA", (size[0] * big, size[1] * big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    r = MARKER_RADIUS * big
    for x, y in points:
        x, y = x * big, y * big
        if shape == "diamond":
            r2 = r * 1.7
            draw.polygon([(x, y - r2), (x + r2, y), (x, y + r2), (x - r2, y)],
                         fill=colour + (255,), outline=(0, 0, 0, 255))
        elif shape == "square":
            draw.rectangle((x - r, y - r, x + r, y + r), fill=colour + (255,),
                           outline=(0, 0, 0, 255), width=big)
        else:
            draw.ellipse((x - r, y - r, x + r, y + r), fill=colour + (255,),
                         outline=(0, 0, 0, 255), width=big)
    return image.resize(size, Image.LANCZOS)


def _cells_layer(size, cells, colour, scale):
    """A frame, half filled, over each of `cells`."""
    from PIL import Image, ImageDraw

    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    for column, row in cells:
        x0, y0 = column * CELL_W / scale, (row - 1) * CELL_H / scale
        x1, y1 = x0 + CELL_W / scale - 1, y0 + CELL_H / scale - 1
        draw.rectangle((x0, y0, x1, y1), fill=colour + (110,), outline=colour + (255,))
    return image


def _world_xy(column: int, row: int, x: int, y: int) -> tuple:
    """A place in the world as a pixel of the whole-planet picture at full
    size: map rows 1-28 down, a page's x from 8 and its y from $18."""
    return column * CELL_W + x - PAGE_X0, (row - 1) * CELL_H + y - PAGE_Y0


# --------------------------------------------------------------------------
# The pages.
# --------------------------------------------------------------------------

STYLE = """<style>
div.cyw-map { overflow-x: auto; max-width: 100%; margin: 0.5em 0; }
div.cyw-stack { position: relative; display: inline-block; }
div.cyw-stack img { display: block; max-width: none; }
div.cyw-stack img.cyw-layer { position: absolute; left: 0; top: 0; pointer-events: none; display: none; }
LAYER_RULES
input.cyw-toggle { margin-left: 1em; }
span.cyw-key { display: inline-block; width: 0.8em; height: 0.8em; border-radius: 50%; border: 1px solid black; margin: 0 0.35em 0 0.2em; vertical-align: -0.05em; }
KEY_RULES
span.cyw-key-beams, span.cyw-key-rocket { border-radius: 0; }
div.cyw-pair { display: flex; flex-wrap: wrap; gap: 1em; align-items: flex-start; }
div.cyw-pair figure { margin: 0; }
img.cyw-cell { image-rendering: pixelated; width: 448px; max-width: 100%; height: auto; }
div.cyw-tile { display: flex; flex-wrap: wrap; gap: 1em; align-items: flex-start; margin: 1em 0 1.5em 0; }
div.cyw-tile > div { flex: 1 1 22em; }
img.cyw-thing { background-color: rgb(90, 90, 140); padding: 4px; image-rendering: pixelated; vertical-align: middle; margin: 2px 0.5em 2px 0; }
</style>"""


def _style() -> str:
    layer_rules = ",\n".join(f"#cyw-layer-{key}:checked ~ div.cyw-map img.cyw-layer-{key}"
                             for key, *_ in LAYERS) + " { display: block; }"
    key_rules = "\n".join(f"span.cyw-key-{key} {{ background-color: rgb{colour}; }}"
                          for key, _, colour, _ in LAYERS)
    return STYLE.replace("LAYER_RULES", layer_rules).replace("KEY_RULES", key_rules)


def _tile_link(tile: int) -> str:
    return f'<a href="Tiles.html#tile{tile:02x}">${tile:02X}</a>'


def _row_runs(row_tiles) -> str:
    """A map row as runs of one tile: '$00-$0B $00; $0C $05; ...'."""
    out = []
    start = 0
    for column in range(1, MAP_COLUMNS + 1):
        if column == MAP_COLUMNS or row_tiles[column] != row_tiles[start]:
            span = f"${start:02X}" if start == column - 1 else f"${start:02X}-${column - 1:02X}"
            out.append(f"{span}: {_tile_link(row_tiles[start])}")
            start = column
    return "; ".join(out)


def _cells_text(cells) -> str:
    """Map cells grouped by row: 'row 5: $0C, $1F; row 6: ...'."""
    by_row: dict[int, list[int]] = {}
    for column, row in cells:
        by_row.setdefault(row, []).append(column)
    return "; ".join(f'<a href="Planet.html#row{row}">row {row}</a>: ' + _numbers(columns)
                     for row, columns in sorted(by_row.items()))


def classify(kind: dict, shots: dict) -> str:
    """Which layer a kind of thing belongs to, from what the code does with
    it: a refuel pad by its frames (ship_hits_ground_objects), ore and the
    beam generators by the kinds beam_hits_ground_object tests, and the
    throwers by the contact effect of what they throw."""
    if kind["animated"] and kind["frames"] == REFUEL_FRAMES:
        return "refuel"
    if kind["kind"] in ORE_KINDS:
        return "ore"
    if kind["kind"] in GENERATOR_KINDS:
        return "generators"
    if kind["shot"]:
        effect = shots[kind["shot"]]["effect"]
        if effect & 0x40:
            return "hurt"
        if effect & 0x04:
            return "thief"
        if effect & 0x20:
            return "fuel"
    return "other"


def kind_name(number: int) -> str:
    return KIND_NAMES.get(number, "")


def _kind_link(number: int) -> str:
    name = kind_name(number)
    return f'<a href="WorldObjects.html#kind{number:02x}">kind ${number:02X}</a>' \
        + (f" ({name})" if name else "")


def _colour_word(nibble: int) -> str:
    return ("bright " if nibble & 8 else "") + COLOUR_NAMES[nibble & 7]


def _two_colours(byte: int) -> str:
    low, high = byte & 15, byte >> 4
    if low == high:
        return _colour_word(low)
    return f"{_colour_word(low)} and {_colour_word(high)} by turns"


SHOT_WORDS = {1: "bullets thrown up in a spray (one in eight the shield ball, and now and then "
                 "the extra-life icon)",
              2: "the refuel pick-up, straight up", 3: "pellets, straight down from high up",
              4: "pellets sprayed upwards", 5: "the fuel thief, sprayed upwards",
              6: "pellets sprayed, downwards from high up", 7: "the dash, to the right",
              8: "the dash, to the left"}


def _planet_page(ref, memory, the_map, tiles, objects, kinds, shots, pool, dealing, game,
                 overview, scale, agree, colours, demo, image_dir: Path) -> str:
    size = overview.size
    classes = {k["kind"]: classify(k, shots) for k in kinds}

    def at(column, row, x, y, dx=8, dy=-8):
        wx, wy = _world_xy(column, row, x + dx, y + dy)
        return wx / scale, wy / scale

    marks: dict[str, list] = {key: [] for key, *_ in LAYERS}
    ship_column, ship_x, ship_row, ship_y = game.ship
    marks["start"].append(at(ship_column, ship_row, ship_x, ship_y, 20, -6))
    rocket = (memory[ROCKET_X + 1], memory[ROCKET_X], memory[ROCKET_Y + 1], memory[ROCKET_Y])
    marks["rocket"].append(at(rocket[0], rocket[2], rocket[1], rocket[3], 4, -20))
    for place in pool:
        marks[f"group{place['group']}"].append(at(place["column"], place["row"], place["x"],
                                                  place["y"]))
    for thing in objects:
        marks[classes[thing["kind"]]].append(at(thing["column"], thing["row"], thing["x"],
                                                thing["y"]))
    beam_cells = [(c, r) for r in range(1, MAP_ROWS + 1) for c in range(MAP_COLUMNS)
                  if the_map[r][c] == BEAM_TILE]

    toggles, overlays = [], []
    for key, what, colour, shown in LAYERS:
        if key == "beams":
            layer = _cells_layer(size, beam_cells, colour, scale)
            count = len(beam_cells)
        else:
            shape = {"start": "diamond", "rocket": "square"}.get(key, "dot")
            layer = _markers(size, marks[key], colour, shape)
            count = len(marks[key])
        layer.save(image_dir / f"layer_{key}.png", optimize=True)
        toggles.append(f'<input type="checkbox" class="cyw-toggle" id="cyw-layer-{key}"'
                       + (" checked" if shown else "") + ">"
                       f'<label for="cyw-layer-{key}"><span class="cyw-key cyw-key-{key}">'
                       f"</span>{_esc(what)} ({count})</label>")
        overlays.append(f'<img class="cyw-layer cyw-layer-{key}" '
                        f'src="images/world/layer_{key}.png" alt="">')

    # The image map: a cell with pieces goes to its tile, and the rest of
    # each row (one area after the cells, which take precedence) to the
    # row's listing.
    cell_w, cell_h = CELL_W / scale, CELL_H / scale
    areas = []
    for row in range(1, MAP_ROWS + 1):
        y0, y1 = round((row - 1) * cell_h), round(row * cell_h)
        for column in range(MAP_COLUMNS):
            tile = the_map[row][column]
            if tiles[tile]["pieces"] or tile == BEAM_TILE:
                x0, x1 = round(column * cell_w), round((column + 1) * cell_w)
                areas.append(f'<area shape="rect" coords="{x0},{y0},{x1},{y1}" '
                             f'href="Tiles.html#tile{tile:02x}" '
                             f'title="Column ${column:02X}, row {row}: tile ${tile:02X}" alt="">')
    for row in range(1, MAP_ROWS + 1):
        y0, y1 = round((row - 1) * cell_h), round(row * cell_h)
        areas.append(f'<area shape="rect" coords="0,{y0},{size[0]},{y1}" href="#row{row}" '
                     f'title="Map row {row}" alt="Map row {row}">')

    # What the layers say.
    used = sorted({t for r in range(1, MAP_ROWS + 1) for t in the_map[r]})
    empty_tiles = [t for t in range(TILE_COUNT) if not tiles[t]["pieces"]]
    empty_cells = sum(1 for r in range(1, MAP_ROWS + 1) for t in the_map[r]
                      if not tiles[t]["pieces"])
    start_words = [_word(memory, START_POSITION + 2 * n) for n in range(3)]
    view_column, view_row, view_x, view_y, origin_x, origin_y = game.first_view
    groups = sorted({p["group"] for p in pool})
    by_class: dict[str, list[int]] = {}
    for number, key in classes.items():
        if any(t["kind"] == number for t in objects):
            by_class.setdefault(key, []).append(number)
    counts = {key: sum(1 for t in objects if classes[t["kind"]] == key) for key, *_ in LAYERS}

    # The beams and their generators, by the bit map_square_bit gives each:
    # the page row and the half of the map (columns below $30, and from $30).
    def square(column, row):
        return (row, 0 if column < 0x30 else 1)
    beam_squares: dict[tuple, list] = {}
    for column, row in beam_cells:
        beam_squares.setdefault(square(column, row), []).append((column, row))
    generators = [t for t in objects if t["kind"] in GENERATOR_KINDS]
    generator_squares: dict[tuple, list] = {}
    for thing in generators:
        generator_squares.setdefault(square(thing["column"], thing["row"]), []).append(thing)
    powered = sorted(s for s in beam_squares if s in generator_squares)
    unpowered = sorted(s for s in beam_squares if s not in generator_squares)
    idle = sorted(s for s in generator_squares if s not in beam_squares)
    beyond = sorted({t["row"] for t in generators if not 1 <= t["row"] <= 12})

    def half_word(half):
        return "west (columns $00-$2F)" if half == 0 else "east (columns $30-$5F)"

    def kinds_text(key):
        return ", ".join(_kind_link(n) for n in sorted(by_class.get(key, []))) or "none"

    keys = []

    def key_line(key, text):
        what = next(w for k, w, _, _ in LAYERS if k == key)
        keys.append(f'<p><span class="cyw-key cyw-key-{key}"></span><b>{_esc(what)}</b>: '
                    f"{text}</p>")

    key_line("start", f"Measured: the ship's place at the first pass of play of a new game in "
             f"the simulator, page column ${ship_column:02X} at x ${ship_x:02X}, page row "
             f"{ship_row} at y ${ship_y:02X}. A new game's player records get their restart "
             f"point from {ref(START_POSITION)} ({ref(CLEAR_PLAYER_RECORD)}): the words "
             + ", ".join(f"${w:04X}" for w in start_words)
             + f" -- map column ${start_words[0] & 0xFF:02X} and row {start_words[0] >> 8}, "
             f"the in-page x and y, and the scroll origins. {ref(START_LANDSCAPE)} starts the "
             f"view a row lower, in row {(start_words[0] >> 8) + 1}, over a play area filled "
             f"with the checker, and flies it up until the ship's place is clear sky "
             f"({ref(FLY_IN_STEP)}); the first pass of play found the view's page at "
             f"column ${view_column:02X}, row {view_row}, its x ${view_x:02X} and y "
             f"${view_y:02X} at the play area's edges. Every life after the first starts from "
             f"the last safe place {ref(SAVE_RESTART_POINT)} kept.")
    key_line("rocket", f"Page column ${rocket[0]:02X} at x ${rocket[1]:02X}, page row "
             f"{rocket[2]} at line ${rocket[3]:02X}: the rocket's base, the words "
             f"{ref(ROCKET_X)} and {ref(ROCKET_Y)}, from which {ref(DRAW_ROCKET)} draws the "
             f"parts delivered so far and over which {ref(DROP_PART)} lets a carried part go. "
             "Every planet has its rocket here.")
    group_uses: dict[int, list[int]] = {}
    for place, value in enumerate(dealing):
        group_uses.setdefault(value, []).append(place)
    for group in groups:
        places = [p for p in pool if p["group"] == group]
        never = [p for p in places if p["never"]]
        dealt = group_uses.get(group, [])
        key_line(f"group{group}",
                 f"{len(places)} places at {ref(POOL_GROUPS[group])}"
                 + (f" ({len(never)} never dealt: {ref(DEAL_PLACES)} marks them taken before "
                    "it starts)" if never else "")
                 + f"; the dealing list deals place{'s' if len(dealt) > 1 else ''} "
                 + ", ".join(str(n) for n in dealt) + " from it: "
                 + "; ".join(_place_word(n) for n in dealt)
                 + '. See <a href="PickupPlaces.html">the pick-up places</a>.')
    key_line("refuel", f"{counts['refuel']} of them, {kinds_text('refuel')}: animated "
             f"graphic $1B in frames {REFUEL_FRAMES[0]} and {REFUEL_FRAMES[1]}, which "
             f"{ref(SHIP_HITS_GROUND_OBJECTS)} treats as a refuel pad -- the tank filled, the "
             "ship repaired, and the pad used up for this player.")
    key_line("ore", f"{counts['ore']} deposits, {kinds_text('ore')}: the kinds "
             f"{ref(BEAM_HITS_GROUND_OBJECT)} lets the special beam mine, one unit of ore each "
             f"from kinds 8 and 9 and two from $0A ({ref(LOAD_ORE)}), "
             f"{sum(1 if t['kind'] < 0x0A else 2 for t in objects if t['kind'] in ORE_KINDS)} "
             "units in the world for a tank of 18.")
    key_line("generators", f"{counts['generators']} of them, {kinds_text('generators')}. "
             f"Destroying one with the special beam sets the bit {ref(MAP_SQUARE_BIT)} gives "
             f"its page row and half of the map, which is the bit {ref(DRAW_BEAMS_ROUTINE)} "
             "tests before drawing a beam in a screen of the same row and half: so one "
             "generator switches off every beam in its row and half of the world.")
    key_line("beams", f"{len(beam_cells)} map cells of tile ${BEAM_TILE:02X}, in rows "
             + ", ".join(str(r) for r in sorted({r for _, r in beam_cells}))
             + f". {ref(DRAW_BEAMS_ROUTINE)} draws a one-line beam across each such screen in "
             f"view, flickering in a random pattern and colour, and a beam touching the ship "
             f"damages it ({ref(BEAM_HITS_SHIP)}) -- the planet's only danger that is part of "
             "the map. Taking each beam screen's row and half: "
             f"{len(powered)} of the {len(beam_squares)} have a generator in the same row and "
             "half" + (", " + "; ".join(f"row {r} {half_word(h)} has none"
                                        for r, h in unpowered) if unpowered else "")
             + (f"; and {len(idle)} generators' row and half hold no beam screen ("
                + "; ".join(f"row {r} {half_word(h)}" for r, h in idle) + ")" if idle else "")
             + (f". Generators lie in rows {', '.join(str(r) for r in beyond)}, past the "
                "twelve rows the bits cover: there map_square_bit's byte falls past "
                f"{ref(PLAYER_FLAG_BITS)}'s three" if beyond else "")
             + ".")
    key_line("hurt", f"{counts['hurt']} of them, {kinds_text('hurt')}: every kind whose shot "
             f"(bits 7-5 of its byte in {ref(OBJECT_KIND_FLAGS)}) is thrown as a frame of type "
             f"$1C whose contact effect ({ref(SMALL_OBJECT_EFFECTS)}) has the damage bit. "
             f"{ref(GROUND_OBJECT_FIRES)} lets each fire one pass in 16 at random while it is on "
             "the screen. The things themselves never harm the ship: it bounces off them.")
    key_line("thief", f"{counts['thief']} of them, {kinds_text('thief')}: the throw is the "
             "fuel thief, whose touch takes 16 steps of fuel.")
    key_line("fuel", f"{counts['fuel']} of them, {kinds_text('fuel')}: the throw is the refuel "
             "pick-up, 28 steps of fuel.")
    key_line("other", f"{counts['other']} more, {kinds_text('other')}: scenery that throws "
             f"nothing and is not one of the above. The special beam can destroy any thing "
             f"lying on the planet except kind ${BEAM_PROOF_KIND:02X}.")

    above, below = colours[0], colours[1]
    lines = [_style(),
             "<p>Cyberun's planet is a ring of 96 by 28 map cells, each a page the size of the "
             f"play area, 224 pixels by 160. {ref(LANDSCAPE_MAP)} holds a tile number for each "
             f"(row 0, the sky, is not stored), and {ref(TILE_TABLE)} turns it into a tile "
             f'record (see <a href="Tiles.html">the tiles</a>). {len(used)} of the '
             f"{TILE_COUNT} tiles are used; {len(empty_tiles)} have no pieces at all "
             f"({_numbers(empty_tiles)}), and {empty_cells} of the {MAP_COLUMNS * MAP_ROWS} "
             "cells hold one of those: sky, solid rock and the inside of a hill are the same "
             "empty tile, told apart only by what is on the screen already. The surface's "
             "lowest row is 11, the caverns run from row 12 down, and rows 1 to 3 hold no "
             "pieces at all. Every planet is this one map; only the two landscape colours "
             f"({ref(PLANET_GROUND_COLOURS)}) and the name change.</p>",
             "<h3>How this picture was made</h3>",
             f"<p>Every cell is drawn by the game's own landscape code, {ref(DRAW_LANDSCAPE)}, "
             f"run in SkoolKit's simulator one pass at a time through {ref(SCROLL_LANDSCAPE)}, "
             "with the stack where the play loop has it. The game never clears its screen: "
             "the sky is black and the ground's inside is the checker $55/$AA, both unchanged "
             "by a 2-pixel move, so the renderer draws only each piece's steps and paints only "
             "the strips a moving edge uncovers. A cell drawn once from a black screen "
             "therefore shows just the outline and the lips of its pieces (left, below). The "
             f"game gets a whole picture by its fly-in ({ref(START_LANDSCAPE)}): the play area "
             "filled first, then the view moved a page so that the fills paint behind every "
             f"moving piece ({ref(FILL_BEHIND)}). This page does the same over the whole depth "
             "of the planet: for each map column the play area starts black, the view stands "
             "in row 2 (the sky), and it descends 4 lines a pass -- the fly-in's step -- to "
             "the bottom of the map. Every piece then comes up from the bottom of the play "
             "area, and the game's fills paint the checker under each floor and black under "
             "each ceiling as it rises. Whenever the view lies exactly on a cell, the play area "
             "is read. Nothing in the picture is filled or drawn by this page; the only start "
             "it is given is black, which is what the sky above row 3 is.</p>",
             f"<p>Checked: the game's own screen at the first pass of a new game, after its own "
             f"fly-in, is the window of this picture at the view's place to "
             f"{agree * 100:.2f}% of its pixels (right, below).</p>",
             '<div class="cyw-pair">'
             f'<figure><img class="cyw-cell" src="images/world/standing.png" '
             f'alt="A cell drawn from a standing start"><figcaption>Column ${demo[0]:02X}, row '
             f"{demo[1]}, drawn in one pass from a black screen</figcaption></figure>"
             f'<figure><img class="cyw-cell" src="images/world/swept.png" '
             f'alt="The same cell from the descent"><figcaption>The same cell from the '
             "descent</figcaption></figure>"
             f'<figure><img class="cyw-cell" src="images/world/first_screen.png" '
             f'alt="The game\'s first screen"><figcaption>The game\'s own first screen of a new '
             "game</figcaption></figure></div>",
             "<p>The colours are the game's too, and carry a history in the same way. "
             f"{ref(COLOUR_PIECE)} colours the attribute cells along each piece's steps, "
             f"{_colour_word(above & 15)} above row {CAVERN_ROW} and "
             f"{_colour_word(below & 15)} from it down on the first planet; a cell no piece "
             "passes keeps the colour it had, so where a shaft or a stretch of rock goes down "
             "from the surface without pieces, the surface's colour comes down with it -- as it "
             "does on the screen when the ship flies down there. (A life started in the "
             "caverns begins with the whole play area in the caverns' colour.) During the "
             f"fly-in tile ${FLY_IN_SWAP[0]:02X} is drawn as tile ${FLY_IN_SWAP[1]:02X} "
             f"({ref(LOAD_MAP_WINDOW)}); the descent here is play, so it is drawn as "
             "itself.</p>",
             "<h3>The planet</h3>",
             "<p>Click a cell for its tile, or an empty one for its map row's listing; or "
             '<a href="images/world/planet.png">see the whole planet at half size</a> '
             f"({MAP_COLUMNS * CELL_W // FULL_SCALE} by {MAP_ROWS * CELL_H // FULL_SCALE}, each "
             "2 by 2 block of pixels averaged, so the checker shows as an even half-tone). "
             "West is left; the world wraps from column $5F back to column $00. Tick a box to "
             "show a layer, each read from the game's tables.</p>",
             "<div>" + "".join(toggles),
             '<div class="cyw-map"><div class="cyw-stack">'
             f'<img src="images/world/planet_overview.png" usemap="#cyw-planet" '
             f'alt="The planet" width="{size[0]}" height="{size[1]}">'
             + "".join(overlays) + "</div>"
             f'<map name="cyw-planet">{"".join(areas)}</map></div></div>']
    lines += keys
    lines += ["<h3>The map, row by row</h3>",
              f"<p>Each row of {ref(LANDSCAPE_MAP)} as runs of one tile: the columns, then the "
              "tile. The landscape's colour is the first of the planet's pair above row "
              f"{CAVERN_ROW} and the second from it down ({ref(0xDEE1)}).</p>",
              '<table class="kl-table"><tr><th>Row</th><th>Cells</th></tr>']
    for row in range(1, MAP_ROWS + 1):
        lines.append(f'<tr id="row{row}"><td>{row}</td><td>{_row_runs(the_map[row])}</td></tr>')
    lines.append("</table>")
    return "\n".join(lines)


def _tiles_page(ref, memory, tiles, uses, tile_pictures, tile_start) -> str:
    bases: dict[int, list[int]] = {}
    for tile in tiles:
        if tile["pieces"]:
            bases.setdefault(tile["base"], []).append(tile["tile"])
    plain = [t for t in tiles if t["pieces"] and not t["upside"] and not t["mirrored"]]
    upside = [t for t in tiles if t["upside"] and not t["mirrored"]]
    mirrored = [t for t in tiles if t["mirrored"] and not t["upside"]]
    both = [t for t in tiles if t["upside"] and t["mirrored"]]
    empty = [t["tile"] for t in tiles if not t["pieces"]]
    counts = [len(t["pieces"]) for t in tiles if t["pieces"]]
    end_codes = sorted({code for t in tiles for p in t["pieces"] if p["ends"] for code in p["ends"]})
    direction_use = [0] * 16
    for tile in tiles:
        for piece in tile["pieces"]:
            direction_use[piece["direction"]] += 1
    shapes = []
    for direction in range(16):
        shapes.append(f"<tr><td>{direction}</td><td>{DIRECTION_NAMES[direction]}</td>"
                      f"<td>{memory[UPSIDE_DOWN_TABLE + direction]}</td>"
                      f"<td>{memory[MIRROR_TABLE + direction]}</td>"
                      f"<td>{direction_use[direction]}</td></tr>")
    ceiling_only = sorted(t for t, checker in tile_start.items() if checker)
    lines = [_style(),
             f"<p>The {TILE_COUNT} tiles of the planet, each drawn on its own by the game. A "
             f"tile number picks a word in {ref(TILE_TABLE)}, the address of the tile's record "
             f"in {ref(TILE_RECORDS)}, which {ref(DRAW_LANDSCAPE)} reads: a list of pieces, "
             "each a straight run of identical steps in one of sixteen directions, chained end "
             'to end across the page. The <a href="Planet.html">planet</a> links each map cell '
             "here.</p>",
             "<h3>A tile record</h3>",
             '<table class="kl-table"><tr><th>Bytes</th><th>What</th></tr>',
             "<tr><td>0</td><td>An empty tile: nothing is drawn. "
             f"{len(empty)} tiles point at an empty record ({_numbers(empty)}).</td></tr>",
             f"<tr><td>${UPSIDE_DOWN:02X} (optional)</td><td>The tile is turned upside down: "
             f"each direction goes through {ref(UPSIDE_DOWN_TABLE)} (floors become ceilings), "
             f"a flat piece's y is moved by XOR $0C and its end codes by XOR 1 "
             f"({ref(0xCD6B)}).</td></tr>",
             f"<tr><td>${MIRRORED:02X} (optional)</td><td>The tile is mirrored left to right: "
             f"each direction goes through {ref(MIRROR_TABLE)}, x is reflected across the page, "
             "a flat run starts from its other end and its end codes swap sides (XOR 2) -- "
             "except a flat piece whose right end code is $16, which is left alone.</td></tr>",
             f"<tr><td>${PADDING:02X}-$FF (optional)</td><td>Skipped: padding.</td></tr>",
             f"<tr><td>count</td><td>The number of pieces, {min(counts)} to {max(counts)} in "
             "the tiles that have any (a collision-box list has room for seven).</td></tr>",
             "<tr><td>x, y</td><td>Each piece's start in the page: its lowest point, x from 8 "
             "and y from $18 down the page.</td></tr>",
             f"<tr><td>direction, steps</td><td>High nibble the direction, low nibble the "
             f"number of steps (0 is 16), read by {ref(0xCD08)}.</td></tr>",
             "<tr><td>two end codes</td><td>Only for a flat piece (directions 0 and 7): the "
             "codes of its first and last step, which pick end caps, a drop or a lip "
             f"({ref(0xD86A)}). The values used: {_numbers(end_codes)}.</td></tr>",
             "</table>",
             "<p>The markers let four tiles share one record: a plain record at A can be "
             "pointed at from A-1 with $99 before it (upside down), from A-2 with $FF $99 (the "
             "$99 is then padding: mirrored) and from A-3 with $99 $FF $99 (both). Decoded "
             f"here: {len(plain)} plain tiles with pieces, {len(upside)} upside down, "
             f"{len(mirrored)} mirrored and {len(both)} both, from {len(bases)} records with "
             "pieces.</p>",
             '<table class="kl-table"><tr><th>Direction</th><th>Shape</th><th>Upside down</th>'
             "<th>Mirrored</th><th>Pieces</th></tr>"] + shapes + [
             "</table>",
             f"<p>Each tile here is drawn alone by the game's own code, as on the planet's "
             "page: the map emptied in a scratch copy but for this tile, in the row it is "
             "first used in (so in that row's colour; row 5 for a tile the map never uses), and "
             f"the view brought down onto it 4 lines a pass by {ref(SCROLL_LANDSCAPE)}, so that "
             "the game's own fills paint behind the pieces as they come up the screen. The play "
             "area starts black, the sky; except for the tiles whose pieces are all ceilings ("
             + ", ".join(_tile_link(t) for t in ceiling_only)
             + "), where it starts with the checker that start_landscape fills the play area "
             "with, the rock above a cavern's roof. Alone, a tile has no neighbours: ground "
             "that a neighbouring tile's pieces would close off is left as the descent found "
             "it, and a tile with both floors and ceilings shows black above all its pieces. "
             "On the planet's page every tile is in its place.</p>",
             "<h3>Every tile</h3>"]
    for tile in tiles:
        number = tile["tile"]
        cells = uses.get(number, [])
        head = f'<h4 id="tile{number:02x}">Tile ${number:02X}</h4>'
        facts = [f"Record at ${tile['address']:04X}"
                 + (", upside down" if tile["upside"] else "")
                 + (", mirrored" if tile["mirrored"] else "")
                 + (f", padding ${tile['padding']:02X}" if tile["padding"] is not None else "")
                 + "."]
        if tile["pieces"]:
            sharers = [t for t in bases[tile["base"]] if t != number]
            facts.append(f"Its pieces are the record at ${tile['base']:04X}"
                         + (", shared with " + ", ".join(_tile_link(t) for t in sharers)
                            if sharers else "") + ".")
        else:
            facts.append("No pieces.")
        if cells:
            facts.append(f"Used in {len(cells)} map cell{'s' if len(cells) > 1 else ''}: "
                         + _cells_text(cells) + ".")
        else:
            facts.append("Not used in the map.")
        if number == BEAM_TILE:
            facts.append(f"A flickering beam crosses every cell of this tile "
                         f"({ref(DRAW_BEAMS_ROUTINE)}).")
        if number in FLY_IN_SWAP:
            facts.append(f"During the fly-in tile ${FLY_IN_SWAP[0]:02X} is drawn as tile "
                         f"${FLY_IN_SWAP[1]:02X} ({ref(LOAD_MAP_WINDOW)}).")
        body = "<p>" + " ".join(facts) + "</p>"
        if tile["pieces"]:
            rows = []
            for piece in tile["pieces"]:
                ends = (f"${piece['ends'][0]:02X}, ${piece['ends'][1]:02X}"
                        if piece["ends"] else "")
                drawn = ("" if piece["drawn"] == piece["direction"]
                         else f" (drawn as {piece['drawn']}, {DIRECTION_NAMES[piece['drawn']]})")
                rows.append(f"<tr><td>${piece['x']:02X}</td><td>${piece['y']:02X}</td>"
                            f"<td>{piece['direction']}: {DIRECTION_NAMES[piece['direction']]}"
                            f"{drawn}</td><td>{piece['steps']}</td><td>{ends}</td></tr>")
            body += ('<table class="kl-table"><tr><th>x</th><th>y</th><th>Direction</th>'
                     "<th>Steps</th><th>Ends</th></tr>" + "".join(rows) + "</table>")
        if number in tile_pictures:
            picture = (f'<img class="cyw-cell" src="images/world/tile{number:02x}.png" '
                       f'alt="Tile ${number:02X}">')
            lines.append(head + f'<div class="cyw-tile">{picture}<div>{body}</div></div>')
        else:
            lines.append(head + body)
    return "\n".join(lines)


def _objects_page(ref, memory, objects, kinds, shots, kind_pictures, the_map) -> str:
    classes = {k["kind"]: classify(k, shots) for k in kinds}
    layer_words = {key: what for key, what, _, _ in LAYERS}
    per_column = [memory[MAP_OBJECTS_PER_COLUMN + c] for c in range(MAP_COLUMNS + 1)]
    lines = [_style(),
             f"<p>{OBJECT_COUNT} things lie at fixed places on the planet, in three tables "
             f"sorted by map column: a kind byte each ({ref(MAP_OBJECT_KINDS)}), a count for "
             f"each column ({ref(MAP_OBJECTS_PER_COLUMN)}, with a 97th byte repeating column "
             f"0's, {per_column[MAP_COLUMNS]}, for the wrap from column $5F) and two packed "
             f"position bytes each ({ref(MAP_OBJECT_PLACES)}). Decoded here as "
             f"{ref(SPAWN_OBJECTS_FROM_LIST)} unpacks them: the column from the running count, "
             "the map row from bits 0-4 of the second byte, the x in the page from bits 0-1 of "
             "the first (its bits 3-4) and bits 5-7 of the second, and the y (the bottom line) "
             "as bits 2-7 of the first less one. The counts add up to "
             f"{sum(per_column[:MAP_COLUMNS])}, and every place lies in its page: x "
             f"{min(t['x'] for t in objects)} to {max(t['x'] for t in objects)} in steps of 8, "
             f"y {min(t['y'] for t in objects)} to {max(t['y'] for t in objects)} in steps of "
             f"4, rows {min(t['row'] for t in objects)} to {max(t['row'] for t in objects)}.</p>",
             f"<p>Whenever the view crosses into a new cell, {ref(LOAD_MAP_WINDOW)} frees the "
             f"slots whose things have left the 2 by 2 window and {ref(SPAWN_COLUMN_OBJECTS)} "
             f"brings in the things of the window's two columns and rows, at most four at a "
             f"time ({ref(GROUND_OBJECTS)}). A kind byte's bits 7 and 6 mark the thing gone for "
             f"player 1 and player 2 ({ref(SHIP_HITS_GROUND_OBJECTS)} sets one when a refuel "
             f"pad is used up, {ref(BEAM_HITS_GROUND_OBJECT)} when the special beam destroys "
             f"one), and {ref(MASK_WORLD_OBJECTS)} clears them at a new game and the current "
             f"player's at the end of a planet ({ref(PLANET_SECURED)}).</p>",
             f"<p>Each kind's byte in {ref(OBJECT_KIND_FLAGS)} gives bits 7-5 the kind of shot "
             f"it throws ({ref(GROUND_OBJECT_FIRES)}, one pass in 16 at random while it is on "
             f"the screen) and, with bit 4 set, makes it an animated graphic $1B whose two "
             f"frames come from {ref(OBJECT_PART_PAIRS)}; otherwise it is graphic $0D with the "
             f"kind as its frame. Its colours are its byte in {ref(OBJECT_KIND_BYTES)}, one in "
             "each nibble, shown on alternate passes. The pictures are drawn by the game: the "
             f"one thing brought back, moved within its column to the middle of a page in an "
             f"emptied scratch copy of the map, brought in by {ref(LOAD_MAP_WINDOW)} and drawn "
             f"by {ref(UPDATE_GROUND_OBJECTS)} over a black play area, for 24 passes; every "
             "shape it took is shown. The bottom character row of some keeps the colour of the "
             f"play area under it ({ref(0xACDD)} stops the colour patch short so as not to "
             "colour the ground). The names are by appearance, or by what the code does with "
             "the kind.</p>",
             '<table class="kl-table"><tr><th>Kind</th><th>Picture</th><th>What</th>'
             "<th>Colours</th><th>Throws</th><th>Number</th></tr>"]
    for kind in kinds:
        number = kind["kind"]
        things = [t for t in objects if t["kind"] == number]
        pictures = "".join(f'<img class="cyw-thing" src="images/world/{name}" alt="">'
                           for name in kind_pictures.get(number, []))
        what = kind_name(number)
        if kind["animated"]:
            what = (what + ", " if what else "") + \
                f"animated: graphic $1B, frames {kind['frames'][0]} and {kind['frames'][1]}"
        else:
            what = (what + ", " if what else "") + f"graphic $0D, frame {number}"
        if number == BEAM_PROOF_KIND:
            what += "; the special beam cannot destroy it"
        throws = ""
        if kind["shot"]:
            throws =f"shot kind {kind['shot']}: {SHOT_WORDS.get(kind['shot'], '')}"
        lines.append(f'<tr><td><a href="#kind{number:02x}">${number:02X}</a></td>'
                     f"<td>{pictures}</td><td>{_esc(what)}</td>"
                     f"<td>{_two_colours(kind['colours'])}</td><td>{throws}</td>"
                     f"<td>{len(things)}</td></tr>")
    lines.append("</table>")
    lines.append("<h3>Where each kind lies</h3>")
    for kind in kinds:
        number = kind["kind"]
        things = [t for t in objects if t["kind"] == number]
        layer = layer_words[classes[number]]
        pictures = "".join(f'<img class="cyw-thing" src="images/world/{name}" alt="">'
                           for name in kind_pictures.get(number, []))
        name = kind_name(number)
        title = f"Kind ${number:02X}" + (f": {name}" if name else "")
        places = "; ".join(
            f'<a href="Planet.html#row{t["row"]}">${t["column"]:02X}, row {t["row"]}</a> '
            f'(x ${t["x"]:02X}, y ${t["y"]:02X})' for t in things)
        lines.append(f'<h4 id="kind{number:02x}">{_esc(title)}</h4>'
                     f"<p>{pictures}{len(things)} on the planet; on the planet's map, the layer "
                     f"&ldquo;{_esc(layer)}&rdquo;. By map column and row, with the place in "
                     f"the page: {places}.</p>")
    return "\n".join(lines)


def _places_page(ref, memory, pool, dealing, pickup_pictures, game) -> str:
    groups = sorted({p["group"] for p in pool}, key=lambda g: POOL_GROUPS[g])
    lines = [_style(),
             "<p>The add-ons and the rocket's parts are not in the tables of things lying on "
             f"the planet. At a new game {ref(NEW_GAME)} has {ref(DEAL_PLACES)} deal each player "
             f"{DEALING_COUNT} places from a pool of {len(pool)}, following the dealing list "
             f"{ref(DEALING_LIST)}, into the player's record ({ref(PLAYER_PLACES)} for the "
             f"player in play). Each place is four bytes: map column, map row, x and y in the "
             f"page. As the view moves, {ref(LOAD_MAP_WINDOW)} puts any of the current player's "
             "places in the window that are not yet taken (bit 7 of the first byte) into the "
             f"two pick-up slots: places 0-{ADDON_PLACES - 1} as graphic $0C, an add-on lying "
             f"on the planet, with the place's number as its frame ({ref(ADDON_GRAPHICS)}), and "
             f"places {ADDON_PLACES}-{DEALING_COUNT - 1} as graphic $1E, rocket parts 0-7 "
             f"({ref(ROCKET_PART_FRAMES)}). The pictures are drawn by the game that way: one "
             "place given to the player, in an emptied scratch copy of the map, brought in by "
             f"load_map_window and drawn by {ref(UPDATE_GROUND_OBJECTS)}.</p>",
             "<h3>The dealing list</h3>",
             f"<p>An entry of 1 to 5 deals a random place not yet dealt from that group of the "
             f"pool: a random byte ({ref(RANDOM_A)}) ANDed with the group's size less one, "
             "tried again while the place is taken, so the groups' sizes are powers of two. An "
             "entry of 0 deals nothing and leaves the place $FF, no place -- unless the next "
             "entry is 3, when the place before it is copied 16 to the right and 35 up. The "
             "pool is all free again at each call, so the two players' places are dealt "
             "independently and may coincide. At the end of a planet the last entry alone "
             f"({ref(DEALING_LIST_LAST)}) is dealt again by {ref(PLANET_SECURED)}: the nose cone "
             "moves.</p>",
             '<table class="kl-table"><tr><th>Place</th><th>Entry</th><th>What lies there</th>'
             "<th>Picture</th><th>Dealt in the simulator's game</th></tr>"]
    for place, value in enumerate(dealing):
        if value:
            source = f'<a href="#group{value}">group {value}</a>'
        elif place + 1 < len(dealing) and dealing[place + 1] == 3:
            source = "0: the place before, 16 right and 35 up"
        else:
            source = "0: none"
        picture = (f'<img class="cyw-thing" src="images/world/{pickup_pictures[place]}" alt="">'
                   if place in pickup_pictures else "")
        dealt = game.dealt[place]
        where = ("none" if dealt[0] == 0xFF else
                 f'<a href="Planet.html#row{dealt[1]}">${dealt[0] & 0x7F:02X}, row {dealt[1]}</a>'
                 f" (x ${dealt[2]:02X}, y ${dealt[3]:02X})")
        lines.append(f"<tr><td>{place}</td><td>{source}</td><td>{_esc(_place_word(place))}"
                     f"</td><td>{picture}</td><td>{where}</td></tr>")
    lines.append("</table>")
    lines.append("<p>Places 1 and 2, add-ons 2 and 3, are never dealt: add-on 2 comes with "
                 "add-on 1, and the ore tank comes as rocket part 6. Places 9 and 10 are the "
                 f"two-piece load ({ref(CARRIED_PART)}), the spire dealt beside the slab at "
                 "exactly the offset at which the ship carries them. The last column is the "
                 "simulator's own new game, one deal among many.</p>")
    lines.append("<h3>The pool</h3>")
    lines.append('<p>Five groups, one for each entry value, each in map-column order. On the '
                 '<a href="Planet.html">planet</a> each group is a layer.</p>')
    for group in groups:
        places = [p for p in pool if p["group"] == group]
        dealt_here = [n for n, v in enumerate(dealing) if v == group]
        lines.append(f'<h4 id="group{group}">Group {group}: {len(places)} places at '
                     f"${POOL_GROUPS[group]:04X}</h4>")
        lines.append("<p>Feeds " + "; ".join(f"place {n}, {_esc(_place_word(n))}"
                                             for n in dealt_here)
                     + (f" -- {len(dealt_here)} places from {len(places) - sum(p['never'] for p in places)}"
                        f" that can be dealt, so no two of them coincide"
                        if len(dealt_here) > 1 else "") + ".</p>")
        rows = "".join(
            f"<tr><td>{p['number']}</td><td>${p['address']:04X}</td>"
            f'<td><a href="Planet.html#row{p["row"]}">${p["column"]:02X}</a></td>'
            f"<td>{p['row']}</td><td>${p['x']:02X}</td><td>${p['y']:02X}</td>"
            f"<td>{'never dealt' if p['never'] else ''}</td></tr>" for p in places)
        lines.append('<table class="kl-table"><tr><th>#</th><th>Address</th><th>Column</th>'
                     "<th>Row</th><th>x</th><th>y</th><th></th></tr>" + rows + "</table>")
    return "\n".join(lines)


def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    import time

    import numpy as np
    from PIL import Image

    began = time.time()
    ref = Refs(snapshot.with_name("cyberun.skool"))
    image_dir = html_dir / "images" / "world"
    image_dir.mkdir(parents=True, exist_ok=True)

    game = Game(snapshot)
    memory = game.base
    the_map = landscape_map(memory)
    tiles = [tile_record(memory, tile) for tile in range(TILE_COUNT)]
    objects = world_objects(memory)
    kinds = kind_table(memory)
    shots = shot_effects(memory)
    pool = pool_places(memory)
    dealing = list(memory[DEALING_LIST:DEALING_LIST + DEALING_COUNT])
    colours = list(memory[PLANET_GROUND_COLOURS:PLANET_GROUND_COLOURS + 2])

    # Checks on what was read, so that a wrong decode stops the build.
    if max(t["end"] for t in tiles) != TILE_RECORDS_END:
        raise RuntimeError("the tile records do not end where the listing says")
    empty_rows = [row for row in range(1, MAP_ROWS + 1)
                  if all(not tiles[t]["pieces"] for t in the_map[row])]
    if empty_rows[:3] != [1, 2, 3]:
        raise RuntimeError(f"map rows 1-3 are not all empty (empty: {empty_rows})")
    for thing in objects:
        if not (1 <= thing["row"] <= MAP_ROWS and PAGE_X0 <= thing["x"] < PAGE_X0 + CELL_W
                and PAGE_Y0 <= thing["y"] < PAGE_Y0 + CELL_H):
            raise RuntimeError(f"object {thing['index']} decodes outside its page: {thing}")

    # The whole planet, drawn by the game: each map column swept from the
    # sky to the bottom of the map. Rows 1-3 have no pieces and are black.
    log("  drawing the planet with the game's own code...")
    planet = np.zeros((MAP_ROWS * CELL_H, MAP_COLUMNS * CELL_W), np.uint8)
    for column in range(MAP_COLUMNS):
        game.reset()
        cells = game.descend(column, range(4, MAP_ROWS + 1))
        for row, picture in cells.items():
            planet[(row - 1) * CELL_H:row * CELL_H, column * CELL_W:(column + 1) * CELL_W] = picture
    # The game's own first screen of a new game, found in the picture: the
    # play area's top line is view_y + 1 in the view's page.
    view_column, view_row, view_x, view_y, _, _ = game.first_view
    top = (view_row - 1) * CELL_H + view_y + 1 - PAGE_Y0
    left = view_column * CELL_W + view_x - PAGE_X0
    window = planet[top:top + CELL_H, left:left + CELL_W]
    agree = float((window == game.first_screen).mean()) if window.shape == (CELL_H, CELL_W) else 0.0
    _save_cell(game.first_screen, image_dir / "first_screen.png")

    # The whole planet at half size, each 2 by 2 block averaged so that the
    # checker becomes an even half-tone rather than thinning to black.
    palette = np.array(PALETTE, np.uint16)
    half = np.zeros((planet.shape[0] // FULL_SCALE, planet.shape[1] // FULL_SCALE, 3), np.uint8)
    for row in range(MAP_ROWS):
        strip = palette[planet[row * CELL_H:(row + 1) * CELL_H]]
        total = strip[0::2, 0::2] + strip[1::2, 0::2] + strip[0::2, 1::2] + strip[1::2, 1::2]
        half[row * CELL_H // 2:(row + 1) * CELL_H // 2] = (total // 4).astype(np.uint8)
    half_image = Image.fromarray(half, "RGB")
    flat = half.reshape(-1, 3).astype(np.uint32)
    codes = flat[:, 0] << 16 | flat[:, 1] << 8 | flat[:, 2]
    unique, inverse = np.unique(codes, return_inverse=True)
    if len(unique) <= 256:
        indexed = Image.fromarray(inverse.reshape(half.shape[:2]).astype(np.uint8), "P")
        indexed.putpalette([value for code in unique.tolist()
                            for value in (code >> 16, code >> 8 & 255, code & 255)])
        indexed.save(image_dir / "planet.png", optimize=True)
    else:
        half_image.save(image_dir / "planet.png", optimize=True)
    overview = half_image.reduce(OVERVIEW_SCALE // FULL_SCALE)
    overview.save(image_dir / "planet_overview.png", optimize=True)

    # A cell drawn in one pass from a black screen, beside the same cell from
    # the descent: the surface cell with the most pieces.
    demo = max(((c, r) for r in range(4, CAVERN_ROW) for c in range(MAP_COLUMNS)),
               key=lambda cell: (len(tiles[the_map[cell[1]][cell[0]]]["pieces"]), -cell[1],
                                 -cell[0]))
    game.reset()
    scratch = game.simulator.memory
    game.set_view(demo[0], demo[1] - 1)
    game.call(LOAD_MAP_WINDOW, (demo[1] - 1) << 8 | demo[0])
    # A pass with map_rebuild set first, as after a restart: only then does
    # draw_landscape record the new cells' collision boxes, by which it culls
    # the pieces (without them it culls by the boxes of wherever the view was
    # before). Then the play area black, and one pass of play.
    scratch[MAP_REBUILD] = 3
    game.scroll_pass(0)
    scratch[MAP_REBUILD] = 0
    game.clear_play_area(False, scratch[GROUND_ATTR_ABOVE])
    game.scroll_pass(0)
    _save_cell(game.capture(), image_dir / "standing.png")
    _save_cell(planet[(demo[1] - 1) * CELL_H:demo[1] * CELL_H,
                      demo[0] * CELL_W:(demo[0] + 1) * CELL_W], image_dir / "swept.png")
    log(f"  planet drawn in {time.time() - began:.0f} s; the game's first screen agrees "
        f"{agree * 100:.2f}%")

    # Every tile on its own, in the row it is first used in.
    uses: dict[int, list[tuple]] = {}
    for row in range(1, MAP_ROWS + 1):
        for column in range(MAP_COLUMNS):
            uses.setdefault(the_map[row][column], []).append((column, row))
    tile_pictures, tile_start = {}, {}
    for tile in tiles:
        pieces = tile["pieces"]
        if not pieces:
            continue
        number = tile["tile"]
        row = min((r for _, r in uses.get(number, [])), default=5)
        game.reset()
        scratch = game.simulator.memory
        scratch[LANDSCAPE_MAP:LANDSCAPE_MAP + MAP_COLUMNS * MAP_ROWS] = bytes(MAP_COLUMNS * MAP_ROWS)
        scratch[LANDSCAPE_MAP + (row - 1) * MAP_COLUMNS] = number
        sloped = [p["drawn"] for p in pieces if p["drawn"] < 14]
        ceilings = bool(sloped) and all(7 <= d <= 13 for d in sloped)
        picture = game.descend(0, [row], row - 2, ceilings)[row]
        _save_cell(picture, image_dir / f"tile{number:02x}.png")
        tile_pictures[number] = row
        tile_start[number] = ceilings

    # Each kind of thing alone: its first one brought back.
    kind_pictures: dict[int, list[str]] = {}
    for kind in range(KIND_COUNT):
        first = next((t for t in objects if t["kind"] == kind), None)
        if first is None:
            continue

        def bring_back(scratch, index=first["index"]):
            scratch[MAP_OBJECT_KINDS + index] &= 0x3F
            # Moved within its own column to the middle of row 5's page, so
            # that the whole of it is on the screen.
            x, y = 0x70, 0xA3
            scratch[MAP_OBJECT_PLACES + 2 * index] = ((y + 1) & 0xFC) | ((x >> 3) & 3)
            scratch[MAP_OBJECT_PLACES + 2 * index + 1] = (x & 0xE0) | 5

        passes = game.specimen(first["column"], 5, bring_back, 24)
        names = []
        for number, picture in enumerate(_distinct([p for p, _ in passes])):
            name = f"kind{kind:02x}_{number}.png"
            if _sprite(picture, image_dir / name):
                names.append(name)
        kind_pictures[kind] = names

    # Each dealt place's pick-up alone, away from the ship's reach.
    pickup_pictures: dict[int, str] = {}
    for place in range(DEALING_COUNT):
        def put_place(scratch, place=place):
            address = PLAYER_PLACES + PLACE_SIZE * place
            scratch[address:address + PLACE_SIZE] = bytes([10, 5, 0xA0, 0xA3])

        passes = game.specimen(10, 5, put_place, 4)
        name = f"place{place:02d}.png"
        if _sprite(passes[1][0], image_dir / name):
            pickup_pictures[place] = name

    sections = {
        "Planet": _planet_page(ref, memory, the_map, tiles, objects, kinds, shots, pool, dealing,
                               game, overview, OVERVIEW_SCALE, agree, colours, demo, image_dir),
        "Tiles": _tiles_page(ref, memory, tiles, uses, tile_pictures, tile_start),
        "WorldObjects": _objects_page(ref, memory, objects, kinds, shots, kind_pictures, the_map),
        "PickupPlaces": _places_page(ref, memory, pool, dealing, pickup_pictures, game),
    }
    log(f"  the planet, {len(tile_pictures)} tiles, {len(objects)} things in "
        f"{len(kind_pictures)} kinds, {len(pool)} pool places ({time.time() - began:.0f} s)")
    return sections


def _place_word(place: int) -> str:
    """What lies at dealt place `place`."""
    if place < ADDON_PLACES:
        return f"add-on {place + 1}, {ADDON_NAMES.get(place + 1, '')}"
    part = place - ADDON_PLACES
    return f"rocket part {part}, {PART_NAMES.get(part, '')}"
