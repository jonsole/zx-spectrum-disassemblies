"""Alien 8's station: the Room structure page, drawn from the game at build time.

build_alien8.py --html calls build(), which draws every room with the game's
own code into the HTML directory and returns the page's section. Like
everything the build writes from the game, none of it is committed: the
pictures are the game's, and so are the room lists.

How the pictures are made. The game is started in SkoolKit's simulator the
way the build's sessions start it (build_alien8.Machine, the menu, key 1 and
0), and a new life is begun the way the sessions begin one -- the robot's
death started (build_alien8._kill) -- so that the game stops at MAIN_NEW_ROOM
($A68B) with a life just started: the base every room is drawn from. From
there each room is drawn by giving the robot's two records the room, emptying
their graphics so that he is not in the picture, and running the game's own
code: ENTER_ROOM ($CAA2: the valves of the room left put back in their
places, the builder, the buffer cleared, and what lies in this room from the
places put in), then the first turn of the main
loop -- every object's update routine once, then the drawing of the whole
room into the buffer ($CEAB) -- up to $A715, where the turn's wait is over
and neither the clock nor the panel has yet been drawn into the buffer. The
picture is read out of the buffer at $D200 (192 rows of 32 bytes, the bottom
line first) in the room's ink, bright on black, which is what COLOUR_PANEL
($A749) gives the whole screen a moment later.

The map. Alien 8 keeps Knight Lore's grid: a room's number is a row in its
high four bits and a column in its low four, and a doorway steps it by 1 in
U (the column, wrapping within the row) or 16 in V (#R$C397 and the three
after it). So the whole station is laid out by room number alone, as Knight
Lore's castle_map lays out the castle, in the game's own projection.

The layers are read from the game's tables (the start rooms, the places, the
update-routine table) and from the rooms as the game builds them (the
sockets, the robots, lifts and blocks, the things on the ceiling, and what
has its deadly bits set after a turn); the doorways are walked through in the
simulator.
"""
from __future__ import annotations

import html
import re
from pathlib import Path

import alien8_data as ad

# --------------------------------------------------------------------------
# Addresses (see their entries in the listing).
# --------------------------------------------------------------------------

MAIN_NEW_ROOM = 0xA68B      # CALL ENTER_ROOM: build the room he is in
MAIN_NEXT_TURN = 0xA68E     # a turn begins
ROOM_DRAWN = 0xA715         # end of the first turn's wait: the room drawn into
                            # the buffer, the clock and the panel not yet
BUFFER = 0xD200             # 192 rows of 32 bytes, the bottom line first
ENTER_ROOM = 0xCAA2
BUILD_ROOM = 0xCCA7
ADJUST_FOR_ARCH = 0xCC6D
ARRIVE = 0xCC01
EXIT_LOW_U = 0xC397         # the four exits: #R$C397, #R$C3F0, #R$C40B, #R$C426
EXIT_HIGH_U = 0xC3F0
EXIT_HIGH_V = 0xC40B
EXIT_LOW_V = 0xC426
HANDLE_EXIT = 0xC36D
FIRST_PILLAR = 0xBFEA       # the update routine of a doorway's first pillar
CALC_PIXEL_XY = 0xCFD2
NEW_GAME_START = 0xCA6D
START_ROOMS = 0xCA9E        # four rooms, one picked by bits 0-1 of the seed
INIT_SPECIAL = 0xAF3F       # deals the places at every new game
FIND_SPECIAL = 0xAE99       # the room's places into records 2 and 3
LOOSE_VALVE = 0xAF79
SOCKET = 0xAE68
SOCKET_SPARKLE = 0xAE33
SUMMARISE = 0xAC6B
SPIKES = 0xB2A4             # its entry holds MAKE_DEADLY ($B2A7)
MAKE_DEADLY = 0xB2A7
CEILING_DROP = 0xAD13
REMOTE_ROBOT = 0xA9C7
REMOTE_BUTTON = 0xAA63
REMOTE_PAD = 0xAA4D
FRAGILE = 0xA9B1
LIFT = 0xB31F
BOBBER = 0xB33F             # an entry point inside LIFT's routine
SHUTTLES = (0xB224, 0xB21C)
CONVEYOR = 0xB267
COLLAPSING = 0xB28C
SINKING = 0xB2B6
RESET_COLOURS = 0xCAD2
ROOM_SIZES = ad.SIZES

LIVES = 0x5B1A
ROOM_INK = 0x5B0D
PLAYER = 0x5B88             # the legs; the top is the next record
TOP = 0x5BA8
RECORD = 32
RECORDS = 56
ROOM_AT = 8
FLAGS_AT = 7
STATE_AT = 0x0D             # bits 7 and 5: deadly (#R$B2A4); bit 6: killed
DEADLY_BITS = 0xA0
KILLED = 0x40
FIRST_ROOM_RECORD = 4       # records 4-55 are the room's (#R$CCA7)
PLACES = ad.PLACES
PLACE_SIZE = ad.PLACE_SIZE

# Graphics, by what the update-routine table makes of them.
VALVES = range(96, 100)     # the four kinds, loose
EXTRA_LIFE = 12
SOCKET_GRAPHICS = range(112, 116)
CRYONAUT = 74
ROBOTS = range(124, 128)
BUTTONS = (122, 123)
PAD = 128
FIRST_PILLAR_GRAPHIC = 2

# The walk test: how far inside the wall he starts, facing out, and how long
# he is given.
WALK_INSET = 12
WALK_TURNS = 60
WALK_KEY = "a"              # the A-G half-row walks (keyboard control)
JUMP_KEY = "q"              # the Q-T half-row jumps
# The legs' standing graphic and the mirror bit for each way out. The facing
# (#R$C319) is 2 for a mirrored sprite plus bit 2 of the graphic: 0 lower U
# (west), 1 higher U (east), 2 higher V (north), 3 lower V (south). The top's
# graphic is the legs' plus 16, as the start records have them (22 and 38).
FACE = {"W": (18, 0x00), "E": (22, 0x00), "N": (18, 0x40), "S": (22, 0x40)}
TOP_GRAPHIC_OFFSET = 16
PLAYER_HALF = 7
PLAYER_HEIGHT = 23          # legs 12, top 11 on top of them
TOP_HEIGHT = 12

SIDES = ("N", "E", "S", "W")
SIDE_NAMES = {"N": "north", "E": "east", "S": "south", "W": "west"}
OPPOSITE = {"N": "S", "S": "N", "E": "W", "W": "E"}
SIZE_WORDS = {0: "square", 1: "long from south to north", 2: "long from west to east"}

SPECTRUM_BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF),
                   (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0), (0xFF, 0xFF, 0xFF)]

TSTATES = 3500000


def _word(memory, address: int) -> int:
    return memory[address] | memory[address + 1] << 8


def _esc(text: str) -> str:
    return html.escape(str(text), quote=False)


def room_step(number: int, side: str) -> int:
    """The room a doorway in `side` leads to, as the exits work it out: east
    and west change the column alone, so it wraps within the row (#R$C397,
    #R$C3F0); north and south add or take 16 (#R$C40B, #R$C426)."""
    if side == "E":
        return (number & 0xF0) | ((number + 1) & 0x0F)
    if side == "W":
        return (number & 0xF0) | ((number - 1) & 0x0F)
    return (number + (16 if side == "N" else -16)) & 0xFF


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

    def within(self, address: int) -> str:
        """A link to the entry an address starts, or else the address and a
        link to the entry it is inside (an entry point such as $B33F)."""
        if address in self.entries or not self.entries:
            return self(address)
        below = [entry for entry in self.entries if entry < address]
        if not below:
            return self(address)
        return f"${address:04X} in #R${max(below):04X}"


# --------------------------------------------------------------------------
# The game, ready to enter any room.
# --------------------------------------------------------------------------

class Station:
    """The game in the simulator, stopped at MAIN_NEW_ROOM with a life just
    started, as the base every room is drawn and walked from."""

    def __init__(self, snapshot: Path):
        import build_alien8 as ba

        self.machine = ba.Machine(snapshot)
        # Into a game the way the build's sessions go: the menu, 1 for the
        # keyboard, 0 to start, the tune, and the robot materialised.
        self.machine.play(ba._start("1"), "the station's start")
        self.simulator = self.machine.simulator
        memory = self.simulator.memory
        # A new life, the way the sessions start one: his death begun, the
        # sparkle run out, and MAIN_NEW_LIFE taking the start records.
        memory[LIVES] = 5
        ba._kill(memory)
        self._trace(self.machine.pc, MAIN_NEW_ROOM, 30)
        self.base = bytes(self.simulator.memory)
        self.base_registers = list(self.simulator.registers)

    def _trace(self, start: int, stop: int, seconds: float) -> None:
        from skoolkit.simutils import PC, T

        simulator = self.simulator
        simulator.trace(start, stop, 0, simulator.registers[T] + int(seconds * TSTATES),
                        False, None, None, None, None, None)
        if simulator.registers[PC] != stop:
            raise RuntimeError(f"the game never reached ${stop:04X} "
                               f"(stopped at ${simulator.registers[PC]:04X})")

    def reset(self, room: int) -> None:
        """The base state, the robot moved to `room`."""
        memory = self.simulator.memory
        memory[:] = self.base
        for index, value in enumerate(self.base_registers):
            self.simulator.registers[index] = value
        memory[PLAYER + ROOM_AT] = room
        memory[TOP + ROOM_AT] = room

    def records(self) -> list[tuple]:
        """The object records now, 2 up (not the robot's): (record, graphic,
        U, V, Z, half U, V, height, flags, state)."""
        memory = self.simulator.memory
        out = []
        for index in range(2, RECORDS):
            address = PLAYER + RECORD * index
            if memory[address]:
                out.append((index, memory[address], memory[address + 1], memory[address + 2],
                            memory[address + 3], memory[address + 4], memory[address + 5],
                            memory[address + 6], memory[address + FLAGS_AT],
                            memory[address + STATE_AT]))
        return out

    def draw(self, room: int) -> dict:
        """Room `room` as the game draws it on entering: the picture, the
        records as built, and the records after the first turn."""
        from PIL import Image

        self.reset(room)
        memory = self.simulator.memory
        # No robot in the picture: an empty record is not listed for drawing
        # (#R$C71C), and its update routine is NO_UPDATE.
        memory[PLAYER] = 0
        memory[TOP] = 0
        self._trace(MAIN_NEW_ROOM, MAIN_NEXT_TURN, 5)
        built = self.records()
        self._trace(MAIN_NEXT_TURN, ROOM_DRAWN, 10)
        after = self.records()
        ink = memory[ROOM_INK] & 7
        colour = SPECTRUM_BRIGHT[ink]
        image = Image.new("RGB", (256, 192))
        pixels = image.load()
        for y in range(192):
            row = BUFFER + (191 - y) * 32
            for column in range(32):
                byte = memory[row + column]
                if byte:
                    for bit in range(8):
                        if byte & (0x80 >> bit):
                            pixels[column * 8 + bit, y] = colour
        return {"image": image, "built": built, "after": after, "ink": ink}

    def walk(self, room: int, side: str, u: int, v: int, z: int, keys) -> tuple:
        """Stand him at (u, v, z) in `room` facing out through `side`, hold
        `keys`, and see where he gets to. A death is taken back at every
        turn (the killed bits cleared), so what is measured is whether the
        way is open, not whether it is safe."""
        memory = self.simulator.memory
        self.reset(room)
        graphic, mirror = FACE[side]
        for record, part_graphic, part_z in ((PLAYER, graphic, z),
                                             (TOP, graphic + TOP_GRAPHIC_OFFSET, z + TOP_HEIGHT)):
            memory[record] = part_graphic
            memory[record + 1], memory[record + 2], memory[record + 3] = u, v, part_z
            memory[record + FLAGS_AT] = (memory[record + FLAGS_AT] & ~0x40) | mirror
            # No step, no walk into the room, no jump, nothing stood on.
            for offset in range(0x09, 0x10):
                memory[record + offset] = 0
        self.machine.tracer.keys = set()
        self._trace(MAIN_NEW_ROOM, MAIN_NEXT_TURN, 5)
        self.machine.tracer.keys = set(keys)
        try:
            for turn in range(WALK_TURNS):
                memory[LIVES] = 5
                memory[PLAYER + STATE_AT] &= ~KILLED
                memory[TOP + STATE_AT] &= ~KILLED
                self._trace(MAIN_NEXT_TURN, MAIN_NEXT_TURN, 5)
                if memory[PLAYER + ROOM_AT] != room:
                    return ("through", turn + 1, memory[PLAYER + ROOM_AT],
                            memory[PLAYER + 1], memory[PLAYER + 2], memory[PLAYER + 3])
                if not 16 <= memory[PLAYER] < 32:
                    return ("died", turn + 1)
            return ("stuck", memory[PLAYER + 1], memory[PLAYER + 2], memory[PLAYER + 3])
        finally:
            self.machine.tracer.keys = set()


# --------------------------------------------------------------------------
# The doorways, read.
# --------------------------------------------------------------------------

def background_pieces(memory, index: int) -> list[list[int]]:
    """A background's 8-byte pieces, as #R$CCA7 copies them: on while the
    first byte of the next is not zero."""
    address = _word(memory, ad.BACKGROUND_TABLE + 2 * index)
    pieces = []
    while memory[address]:
        pieces.append(list(memory[address:address + 8]))
        address += 8
    return pieces


def doorway_backgrounds(memory, sizes) -> dict[int, dict]:
    """Every background that is a doorway -- one with a first pillar, the
    piece whose update routine (#R$BFEA) arms the exit -- with the wall it
    stands in, from the pillar's position: at the high or low U wall (U 197
    or 59) or the high or low V wall. East is +U and north +V, as on Knight
    Lore's page: the projection draws +U down to the right and +V up to the
    right (#R$CFD2)."""
    floor = sizes[0][2]
    pillars = {g for g in range(ad.HANDLER_COUNT)
               if _word(memory, ad.HANDLERS + 2 * g) == FIRST_PILLAR}
    out = {}
    for index in range(ad.BACKGROUND_COUNT):
        for graphic, u, v, z, *_ in background_pieces(memory, index):
            if graphic in pillars:
                if u >= 192:
                    side = "E"
                elif u < 64:
                    side = "W"
                elif v >= 192:
                    side = "N"
                else:
                    side = "S"
                middle = (u, v + 13) if side in "EW" else (u - 13, v)
                out[index] = {"side": side, "z": z, "raised": z > floor,
                              "middle": middle, "pillar": (u, v)}
                break
    return out


def room_exits(records, doorways) -> dict[tuple[int, str], dict]:
    exits = {}
    for record in records:
        number = record["number"]
        for position, (_, background) in enumerate(record["backgrounds"]):
            if background in doorways:
                door = doorways[background]
                key = (number, door["side"])
                if key in exits:
                    raise ValueError(f"room ${number:02X} has two doorways in its "
                                     f"{door['side']} wall")
                exits[key] = {"to": room_step(number, door["side"]), "background": background,
                              "position": position, "raised": door["raised"],
                              "z": door["z"], "middle": door["middle"]}
    return exits


# --------------------------------------------------------------------------
# The map.
# --------------------------------------------------------------------------

ROOM_SPACING = 128          # a square: walls 64 either side of a room's centre
MAP_GROUND = (7, 7, 28)     # aticatac.css's page colour
MAP_FLOOR = (16, 16, 60)
MAP_FLOOR_EDGE = (40, 40, 110)
MAP_MARGIN = 16
MAP_OVERVIEW_WIDTH = 1200


def _project(u: int, v: int, z: int) -> tuple:
    """#R$CFD2: pixel x = U + V - 128, and pixel y = (V - U + 128) / 2 + Z -
    40 counted up from the bottom -- here counted from the top."""
    return u + v - 128, 191 - ((v - u + 128) // 2 + z - 40)


def _grid(number: int) -> tuple:
    return number & 15, number >> 4


def _floor_corners(size) -> list[tuple]:
    half_u, half_v, floor = size
    return [_project(128 + su * half_u, 128 + sv * half_v, floor)
            for su, sv in ((-1, -1), (1, -1), (1, 1), (-1, 1))]


def _edge_middle(size, side: str) -> tuple:
    half_u, half_v, floor = size
    u = 128 + {"E": half_u, "W": -half_u}.get(side, 0)
    v = 128 + {"N": half_v, "S": -half_v}.get(side, 0)
    return _project(u, v, floor)


def station_map(records, pictures: dict, sizes) -> tuple:
    """The whole station as one picture, each room's floor as a polygon on
    it, and the middle of each floor's edges, for the markers. Floors first,
    so each room reads as a tile, then the rooms back to front with black
    left transparent, so that nearer rooms stand in front."""
    from PIL import Image, ImageChops, ImageDraw

    place = {}
    for record in records:
        column, row = _grid(record["number"])
        u_world, v_world = column * ROOM_SPACING, row * ROOM_SPACING
        place[record["number"]] = (u_world + v_world, (u_world - v_world) // 2)
    left = min(x for x, _ in place.values())
    top = min(y for _, y in place.values())
    width = max(x for x, _ in place.values()) + 256 - left
    height = max(y for _, y in place.values()) + 192 - top
    image = Image.new("RGB", (width, height), MAP_GROUND)
    draw = ImageDraw.Draw(image)
    floors, edges = {}, {}
    for record in records:
        number = record["number"]
        size = sizes[record["size"]]
        ox, oy = place[number][0] - left, place[number][1] - top
        floors[number] = [(ox + x, oy + y) for x, y in _floor_corners(size)]
        edges[number] = {side: (ox + _edge_middle(size, side)[0], oy + _edge_middle(size, side)[1])
                         for side in SIDES}
        draw.polygon(floors[number], fill=MAP_FLOOR, outline=MAP_FLOOR_EDGE)

    def back_to_front(number):
        column, row = _grid(number)
        return (column - row, column + row)

    for number in sorted(pictures, key=back_to_front):
        picture = pictures[number]
        mask = picture.convert("L").point(lambda value: 255 if value else 0)
        image.paste(picture, (place[number][0] - left, place[number][1] - top), mask)
    ground = Image.new("RGB", image.size, MAP_GROUND)
    box = ImageChops.difference(image, ground).getbbox()
    x0, y0 = max(0, box[0] - MAP_MARGIN), max(0, box[1] - MAP_MARGIN)
    x1, y1 = min(image.width, box[2] + MAP_MARGIN), min(image.height, box[3] + MAP_MARGIN)
    image = image.crop((x0, y0, x1, y1))
    floors = {n: [(x - x0, y - y0) for x, y in corners] for n, corners in floors.items()}
    edges = {n: {s: (x - x0, y - y0) for s, (x, y) in sides.items()} for n, sides in edges.items()}
    return image, floors, edges


# The layers: (key, what, colour, shown at first). Room layers put a dot in a
# slot round the floor's centre, so that several on one room sit side by
# side; the four chamber layers share a slot (a room has one socket at most),
# and the raised-doorway layer puts a diamond on the doorway's edge.
CHAMBER_COLOURS = [(255, 255, 255), (70, 150, 255), (230, 60, 230), (255, 190, 120)]
LAYERS = [
    ("start", "Where a game starts", (60, 220, 60), True),
    ("chamber0", "Chambers wanting valve kind 0", CHAMBER_COLOURS[0], True),
    ("chamber1", "Chambers wanting valve kind 1", CHAMBER_COLOURS[1], True),
    ("chamber2", "Chambers wanting valve kind 2", CHAMBER_COLOURS[2], True),
    ("chamber3", "Chambers wanting valve kind 3", CHAMBER_COLOURS[3], True),
    ("places", "The 36 places: valves and extra lives", (240, 220, 40), True),
    ("robots", "Remote-controlled robots", (60, 220, 230), False),
    ("deadly", "Deadly things", (240, 50, 50), False),
    ("lifts", "Lifts, bobbing blocks, shuttles and conveyors", (150, 240, 150), False),
    ("crumbling", "Collapsing and sinking blocks", (255, 140, 0), False),
    ("drops", "Things that drop from the ceiling", (160, 160, 160), False),
    ("raised", "Raised doorways: one way unless climbed to", (180, 130, 255), False),
]
ROOM_LAYER_SLOTS = {"start": (-1.5, -0.5), "chamber0": (-0.5, -0.5), "chamber1": (-0.5, -0.5),
                    "chamber2": (-0.5, -0.5), "chamber3": (-0.5, -0.5), "places": (0.5, -0.5),
                    "robots": (1.5, -0.5), "deadly": (-1.5, 0.5), "lifts": (-0.5, 0.5),
                    "crumbling": (0.5, 0.5), "drops": (1.5, 0.5)}
MARKER_RADIUS = 5.5         # on the overview, in pixels
MARKER_STEP = 13
MARKER_SUPERSAMPLE = 4


def _layer_image(size, centres, rooms_marked, colour, slot):
    from PIL import Image, ImageDraw

    big = MARKER_SUPERSAMPLE
    image = Image.new("RGBA", (size[0] * big, size[1] * big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    r = MARKER_RADIUS * big
    for number in rooms_marked:
        cx, cy = centres[number]
        x = (cx + slot[0] * MARKER_STEP) * big
        y = (cy + slot[1] * MARKER_STEP) * big
        draw.ellipse((x - r, y - r, x + r, y + r), fill=colour + (255,),
                     outline=(0, 0, 0, 255), width=2 * big)
    return image.resize(size, Image.LANCZOS)


def _doorway_layer_image(size, points, colour):
    from PIL import Image, ImageDraw

    big = MARKER_SUPERSAMPLE
    image = Image.new("RGBA", (size[0] * big, size[1] * big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    r = MARKER_RADIUS * big
    for x, y in points:
        x, y = x * big, y * big
        draw.polygon([(x, y - r * 1.3), (x + r * 1.3, y), (x, y + r * 1.3), (x - r * 1.3, y)],
                     fill=colour + (255,), outline=(0, 0, 0, 255))
    return image.resize(size, Image.LANCZOS)


# The CSS the layers need, for alien8.css (the lead adds it): the boxes are
# the map's earlier siblings, so a selector can reach it with no script.
LAYER_CSS = "\n".join(
    ["img.a8-layer { position: absolute; left: 0; top: 0; pointer-events: none; display: none; }",
     ",\n".join(f"#a8-layer-{key}:checked ~ div.kl-castle img.a8-layer-{key}"
                for key, *_ in LAYERS) + " { display: block; }"]
    + [f"span.a8-key-{key} {{ background-color: rgb{colour}; }}" for key, _, colour, _ in LAYERS]
    + ["span.a8-key-raised { border-radius: 0; transform: rotate(45deg) scale(0.85); }",
       "ul.a8-room-objects { margin-top: 0; }",
       "ul.a8-room-objects img.kl-thumb { max-height: 32px; vertical-align: middle; "
       "margin-right: 0.4em; }"])


# --------------------------------------------------------------------------
# Measuring.
# --------------------------------------------------------------------------

def handlers_to_graphics(memory) -> dict[int, list[int]]:
    out: dict[int, list[int]] = {}
    for graphic in range(ad.HANDLER_COUNT):
        out.setdefault(_word(memory, ad.HANDLERS + 2 * graphic), []).append(graphic)
    return out


def walk_doorways(station, records, exits, sizes, built) -> dict:
    """Every doorway walked through in the simulator. A floor-level one:
    standing WALK_INSET units inside its wall at the middle of the arch,
    facing out, walk; if that does not take him through, try again from a
    few more places near it clear of every object, and then with jump held
    too. A raised one: standing on its ledge in the doorway, at the arch's
    height, walk; and, to see whether it can be climbed to, from the floor
    below it, walk and jump. Each result says whether he came out in the
    room the doorway leads to."""
    by_number = {record["number"]: record for record in records}
    results = {}
    for (room, side), exit_ in sorted(exits.items()):
        half_u, half_v, floor = sizes[by_number[room]["size"]]
        half = half_u if side in "EW" else half_v
        sign = 1 if side in "NE" else -1
        mu, mv = exit_["middle"]
        if exit_["raised"]:
            spot = (128 + sign * (half - 2), mv) if side in "EW" else (mu, 128 + sign * (half - 2))
            outcome = station.walk(room, side, spot[0], spot[1], exit_["z"], (WALK_KEY,))
            below = (128 + sign * (half - WALK_INSET), mv) if side in "EW" else \
                (mu, 128 + sign * (half - WALK_INSET))
            climb = station.walk(room, side, below[0], below[1], floor, (WALK_KEY, JUMP_KEY))
            results[(room, side)] = {"how": "ledge" if outcome[0] == "through" else "no",
                                     "outcome": outcome, "from": spot,
                                     "climbed": climb[0] == "through", "climb": climb}
            continue
        # Where to stand: on the floor, clear of every object; and, where
        # objects cover the floor in front of the arch, on top of them.
        objects = [o for o in built[room] if o[1] > 3]      # not the pillars
        on_floor, on_top = [], []
        for inset in range(WALK_INSET, 2 * half, 4):
            for offset in (0, 4, -4, 8, -8):
                along = 128 + sign * (half - inset)
                u, v = (along, 128 + offset) if side in "EW" else (128 + offset, along)
                under = [(oz, hz) for _, _, ou, ov, oz, hu, hv, hz, _, _ in objects
                         if abs(ou - u) < hu + PLAYER_HALF and abs(ov - v) < hv + PLAYER_HALF]
                if not any(oz < floor + PLAYER_HEIGHT and oz + hz > floor for oz, hz in under):
                    on_floor.append((u, v, floor))
                elif offset == 0:
                    on_top.append((u, v, max(oz + hz for oz, hz in under)))
            if len(on_floor) >= 4:
                break
        found = None
        for tries, keys, how in ((on_floor[:4], (WALK_KEY,), "walk"),
                                 (on_floor[:4], (WALK_KEY, JUMP_KEY), "jump"),
                                 (on_top[:2], (WALK_KEY,), "walk"),
                                 (on_top[:2], (WALK_KEY, JUMP_KEY), "jump")):
            for u, v, z in tries:
                outcome = station.walk(room, side, u, v, z, keys)
                if outcome[0] == "through":
                    found = {"how": how, "outcome": outcome, "from": (u, v, z),
                             "on_top": z > floor}
                    break
            if found:
                break
        results[(room, side)] = found or {"how": "no", "outcome": None, "from": None}
    return results


# --------------------------------------------------------------------------
# The page.
# --------------------------------------------------------------------------

def _cell(position: int) -> str:
    return f"({position & 7}, {position >> 3 & 7}, {position >> 6})"


def _numbers(values) -> str:
    values = sorted(set(values))
    runs, start = [], None
    for index, value in enumerate(values):
        if start is None:
            start = value
        if index + 1 == len(values) or values[index + 1] != value + 1:
            runs.append(str(start) if start == value else f"{start}-{value}")
            start = None
    return ", ".join(runs)


def _hex(number: int) -> str:
    return f"${number:02X}"


def _room_link(number: int) -> str:
    return f'<a href="#room{number:02x}">${number:02X}</a>'


def _rooms(numbers) -> str:
    return ", ".join(_room_link(n) for n in sorted(numbers)) or "none"


def _template_name(index: int) -> str:
    return ad._template_name(index)


def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    from PIL import Image

    from build_alien8 import game_memory

    memory = game_memory(snapshot)
    ref = Refs(snapshot.with_name("alien8.skool"))
    image_dir = html_dir / "images" / "world"
    image_dir.mkdir(parents=True, exist_ok=True)

    records = ad.room_records(memory)
    by_number = {record["number"]: record for record in records}
    sizes = [ad.room_size(memory, index) for index in range(ad.SIZE_COUNT)]
    doorways = doorway_backgrounds(memory, sizes)
    exits = room_exits(records, doorways)
    handlers = handlers_to_graphics(memory)
    graphic_sprite = {g: _word(memory, ad.GRAPHICS + 2 * g) for g in range(ad.GRAPHIC_COUNT)}
    pictured = set(ad.picture_sprites(memory))

    # Page 1 and page 2 of the object templates: a group's template index in
    # the table at OBJECT_TABLE is its header's number, plus 32 after a
    # template-31 header (#R$CCA7).
    def template_graphics(index: int) -> list[int]:
        address = _word(memory, ad.OBJECT_TABLE + 2 * index)
        graphics = []
        while True:
            graphics.append(memory[address])
            address += 5
            if memory[address] == 0:
                return graphics

    def groups_of(record) -> list[tuple]:
        """(start, table index, count, positions) for each real group, and
        the nudges, with page 2's templates numbered on from 32."""
        out, page = [], 0
        for start, template, count, positions in record["groups"]:
            if template == 31:
                page = 32
                out.append((start, 31, count, positions))
            elif template == 0:
                out.append((start, 0, count, positions))
            else:
                out.append((start, template + page, count, positions))
        return out

    log("  drawing the rooms with the game's own code...")
    station = Station(snapshot)
    base = station.base
    drawn = {}
    for record in records:
        number = record["number"]
        drawn[number] = station.draw(number)
        drawn[number]["image"].save(image_dir / f"room{number:02x}.png")

    built = {n: drawn[n]["built"] for n in drawn}
    built_graphics = {n: {r[1] for r in drawn[n]["built"]} for n in drawn}
    room_records_used = {n: sum(1 for r in drawn[n]["built"] if r[0] >= FIRST_ROOM_RECORD)
                         for n in drawn}

    # Checked against what the tables say: every graphic a room's templates
    # and backgrounds name was built into that room.
    for record in records:
        number = record["number"]
        expected = set()
        for _, background in record["backgrounds"]:
            expected.update(piece[0] for piece in background_pieces(memory, background))
        for _, index, _, _ in groups_of(record):
            if index not in (0, 31):
                expected.update(template_graphics(index))
        missing = expected - built_graphics[number]
        if missing:
            raise RuntimeError(f"room ${number:02X}: graphics {sorted(missing)} named by its "
                               "record were not built")

    log("  walking through every doorway...")
    walks = walk_doorways(station, records, exits, sizes, built)

    # What each room holds, as built and after a turn.
    deadly_graphics = {n: sorted({r[1] for r in drawn[n]["after"] if r[9] & DEADLY_BITS})
                       for n in drawn}
    deadly_all = sorted({g for gs in deadly_graphics.values() for g in gs})
    deadly_by_handler: dict[int, list[int]] = {}
    for graphic in deadly_all:
        deadly_by_handler.setdefault(_word(memory, ad.HANDLERS + 2 * graphic), []).append(graphic)

    def rooms_with(graphics) -> list[int]:
        graphics = set(graphics)
        return sorted(n for n in drawn if graphics & built_graphics[n])

    lift_graphics = set(handlers.get(LIFT, []))
    bobber_graphics = set(handlers.get(BOBBER, []))
    shuttle_graphics = {g for address in SHUTTLES for g in handlers.get(address, [])}
    conveyor_graphics = set(range(68, 72))
    crumble_graphics = set(handlers.get(COLLAPSING, []))
    sink_graphics = set(handlers.get(SINKING, []))
    drop_graphics = set(handlers.get(CEILING_DROP, []))
    robot_graphics = set(ROBOTS)

    # The places, as the simulator's game dealt them (graphic now at +0,
    # where it is at +5 to +8), and as the tape has them (+1 to +4).
    places = []
    for number in range(ad.PLACE_COUNT):
        address = PLACES + PLACE_SIZE * number
        places.append({"number": number, "graphic": base[address],
                       "u": memory[address + 1], "v": memory[address + 2],
                       "z": memory[address + 3], "room": memory[address + 4],
                       "dealt_room": base[address + 8]})
    places_by_room: dict[int, list[dict]] = {}
    for place in places:
        places_by_room.setdefault(place["room"], []).append(place)
    # Each place's thing was put in its room by the game's own code: check.
    for place in places:
        if place["graphic"] and place["graphic"] not in built_graphics[place["room"]]:
            raise RuntimeError(f"place {place['number']}'s graphic {place['graphic']} did not "
                               f"appear in room ${place['room']:02X}")
    dealt_lives = [p for p in places if p["graphic"] == EXTRA_LIFE]
    dealt_valves = [p for p in places if p["graphic"] in VALVES]

    # The chambers: a socket of one kind in each (object templates 24-27),
    # and the crew, the cryonauts of templates 21 and 22.
    chambers = {}
    for record in records:
        number = record["number"]
        sockets = sorted(built_graphics[number] & set(SOCKET_GRAPHICS))
        if not sockets:
            continue
        if len(sockets) > 1:
            raise RuntimeError(f"room ${number:02X} has sockets of two kinds")
        crew = sum(len(positions) for _, index, _, positions in groups_of(record)
                   if index not in (0, 31) and CRYONAUT in template_graphics(index))
        chambers[number] = {"kind": sockets[0] - SOCKET_GRAPHICS[0], "crew": crew}
    crew_rooms = sorted(n for n in drawn if CRYONAUT in built_graphics[n])

    starts = list(memory[START_ROOMS:START_ROOMS + 4])
    marked = {
        "start": sorted(set(starts)),
        "places": sorted(places_by_room),
        "robots": rooms_with(robot_graphics),
        "deadly": sorted(n for n in drawn if deadly_graphics[n]),
        "lifts": rooms_with(lift_graphics | bobber_graphics | shuttle_graphics | conveyor_graphics),
        "crumbling": rooms_with(crumble_graphics | sink_graphics),
        "drops": rooms_with(drop_graphics),
    }
    for kind in range(4):
        marked[f"chamber{kind}"] = sorted(n for n, c in chambers.items() if c["kind"] == kind)
    raised = sorted(key for key, exit_ in exits.items() if exit_["raised"])

    log("  putting the station together...")
    pictures = {n: drawn[n]["image"] for n in drawn}
    whole, floors, edges = station_map(records, pictures, sizes)
    whole.save(image_dir / "station.png")
    scale = MAP_OVERVIEW_WIDTH / whole.width
    overview = whole.resize((MAP_OVERVIEW_WIDTH, round(whole.height * scale)), Image.LANCZOS)
    overview.save(image_dir / "station_overview.png")
    areas = "".join(
        '<area shape="poly" coords="'
        + ",".join(f"{round(x * scale)},{round(y * scale)}" for x, y in corners)
        + f'" href="#room{number:02x}" title="Room ${number:02X}" alt="Room ${number:02X}">'
        for number, corners in sorted(floors.items()))
    centres = {n: (sum(x for x, _ in c) * scale / 4, sum(y for _, y in c) * scale / 4)
               for n, c in floors.items()}

    toggles, overlays, keys = [], [], []
    for key, what, colour, shown in LAYERS:
        if key == "raised":
            points = [(edges[room][side][0] * scale, edges[room][side][1] * scale)
                      for room, side in raised]
            _doorway_layer_image(overview.size, points, colour).save(image_dir / f"layer_{key}.png")
            count = len(raised)
        else:
            _layer_image(overview.size, centres, marked[key], colour,
                         ROOM_LAYER_SLOTS[key]).save(image_dir / f"layer_{key}.png")
            count = len(marked[key])
        toggles.append(f'<input type="checkbox" class="kl-toggle" id="a8-layer-{key}"'
                       + (" checked" if shown else "") + ">"
                       f'<label for="a8-layer-{key}"><span class="kl-key a8-key-{key}">'
                       f"</span>{what} ({count})</label>")
        overlays.append(f'<img class="a8-layer a8-layer-{key}" '
                        f'src="images/world/layer_{key}.png" alt="">')

    def key_line(key, text):
        what = next(w for k, w, _, _ in LAYERS if k == key)
        keys.append(f'<p><span class="kl-key a8-key-{key}"></span><b>{what}</b>: {text}</p>')

    def graphic_thumb(graphic: int) -> str:
        sprite = graphic_sprite.get(graphic)
        if sprite in pictured:
            return (f'<img class="kl-thumb" src="images/sprites/{ad.sprite_picture_name(sprite)}" '
                    f'alt="graphic {graphic}">')
        return ""

    kind_counts = [len(marked[f"chamber{k}"]) for k in range(4)]
    key_line("start", _rooms(starts)
             + f". {ref(NEW_GAME_START)} gives the start records one of the four bytes at "
             f"{ref(START_ROOMS)}, picked by bits 0-1 of the seed, which the menu counts up "
             "while it waits. The games on this page are the simulator's, which always start "
             f"in room {_room_link(station.base[PLAYER + ROOM_AT])}.")
    for kind in range(4):
        key_line(f"chamber{kind}",
                 "; ".join(f"{_room_link(n)} ({chambers[n]['crew']} crew)"
                             for n in marked[f"chamber{kind}"])
                 + f". The rooms whose socket is graphic {SOCKET_GRAPHICS[kind]}, which takes "
                 f"a valve of graphic {VALVES[kind]}: a valve of that kind in the room steers "
                 f"itself onto the socket and, landing on it, activates the chamber "
                 f"({ref(LOOSE_VALVE)}).")
    extra_word = (f"{len(dealt_lives)} extra li{'ves' if len(dealt_lives) != 1 else 'fe'} "
                  f"(places {', '.join(str(p['number']) for p in dealt_lives)})")
    key_line("places", _rooms(places_by_room)
             + f". The {ad.PLACE_COUNT} places at {ref(PLACES)}, one in each of "
             f"{len(places_by_room)} rooms. Where each lies is on the tape; what lies there is "
             f"dealt at every new game by {ref(INIT_SPECIAL)}: the four kinds of valve in turn, "
             "starting from a kind picked by the seed and the refresh register, except that "
             "every sixteenth place, counted from a start the random number picks, gets an "
             "extra life instead and the kind it would have had is skipped -- two or three "
             "lives a game, and 33 or 34 valves for the 24 chambers. The simulator's game "
             f"dealt {len(dealt_valves)} valves and "
             f"{extra_word}; another game deals them otherwise. Each room's entry below says "
             "which place is in it and what this game put there.")
    key_line("robots", _rooms(marked["robots"])
             + f". Rooms built with a remote-controlled robot (graphics {_numbers(ROBOTS)}, "
             f"{ref(REMOTE_ROBOT)}). Standing on one of the room's four buttons "
             f"(graphics {_numbers(BUTTONS)}, {ref(REMOTE_BUTTON)}) sends the robot two units a "
             f"turn one of four ways; the pad (graphic {PAD}, {ref(REMOTE_PAD)}) holds it "
             "still.")
    key_line("deadly", _rooms(marked["deadly"])
             + f". Measured: the rooms in which, after the game has built them and run every "
             f"object's update routine once, some record has its deadly bits set -- bits 7 and 5 "
             f"of +$0D, which only MAKE_DEADLY sets (at $B2A7, in {ref(SPIKES)}). The graphics "
             "found deadly this way, with the update routines that made them so: "
             + "; ".join(f"{_numbers(gs)} ({ref.within(h)})"
                         for h, gs in sorted(deadly_by_handler.items()))
             + ".")
    key_line("lifts", _rooms(marked["lifts"])
             + f". Rooms built with a lift (graphic {_numbers(lift_graphics)}, {ref(LIFT)}: it "
             f"moves only while ridden), a bobbing block (graphic {_numbers(bobber_graphics)}, "
             f"{ref.within(BOBBER)}, which rises and sinks by itself), a shuttling block (graphics "
             f"{_numbers(shuttle_graphics)}, {ref(SHUTTLES[1])} and {ref(SHUTTLES[0])}) or a "
             f"conveyor (graphics {_numbers(conveyor_graphics)}, {ref(CONVEYOR)} and the three "
             "after it).")
    key_line("crumbling", _rooms(marked["crumbling"])
             + f". Rooms with a block that collapses under him (graphic "
             f"{_numbers(crumble_graphics)}, {ref(COLLAPSING)}) or one that sinks while stood on "
             f"(graphic {_numbers(sink_graphics)}, {ref(SINKING)}).")
    key_line("drops", _rooms(marked["drops"])
             + f". Rooms with graphic {_numbers(drop_graphics)} ({ref(CEILING_DROP)}), which hangs "
             "from the ceiling and falls on a turn when the random number is under 16. Every "
             "one of these rooms has an even number, and entering an even-numbered room sets "
             f"the latch that stops them ({ref(ENTER_ROOM)}): they hang still until something "
             "is picked up there, or an extra life is taken.")
    key_line("raised", "; ".join(f"{_room_link(room)} {SIDE_NAMES[side]} to "
                                 f"{_room_link(exits[(room, side)]['to'])}"
                                 for room, side in raised)
             + ". Doorways whose arch stands on a ledge, marked on their wall. Coming the "
             f"other way he arrives on the ledge ({ref(ADJUST_FOR_ARCH)} gives him the arch's "
             "height) and steps down; to leave by one he must get up to the ledge first.")

    # Doorway statistics.
    pairs = sum(1 for (room, side), exit_ in exits.items()
                if exits.get((exit_["to"], OPPOSITE[side]), {}).get("to") == room)
    raised_pairs = sum(1 for room, side in raised
                       if not exits[(exits[(room, side)]["to"], OPPOSITE[side])]["raised"])
    raised_sides = sorted({side for _, side in raised})
    through = [key for key, result in walks.items() if result["how"] in ("walk", "jump", "ledge")
               and result["outcome"][2] == exits[key]["to"]]
    wrong = sorted(key for key, result in walks.items() if result["how"] in ("walk", "jump", "ledge")
                   and result["outcome"][2] != exits[key]["to"])
    jumps = sorted(key for key, result in walks.items()
                   if result["how"] == "jump" and not result.get("on_top"))
    failed = sorted(key for key, result in walks.items() if result["how"] == "no")
    floor_doors = [key for key in exits if not exits[key]["raised"]]
    walked = [key for key in floor_doors
              if walks[key]["how"] == "walk" and not walks[key].get("on_top")]
    ledge = [key for key in raised if walks[key]["how"] == "ledge"]
    topped = sorted(key for key, result in walks.items() if result.get("on_top"))
    climbed = sorted(key for key in raised if walks[key].get("climbed"))
    wraps = sorted(key for key, exit_ in exits.items()
                   if abs(_grid(exit_["to"])[0] - _grid(key[0])[0]) > 1
                   or abs(_grid(exit_["to"])[1] - _grid(key[0])[1]) > 1)
    missing_rooms = sorted(key for key, exit_ in exits.items() if exit_["to"] not in by_number)
    unpartnered = sorted(key for key, exit_ in exits.items()
                         if exits.get((exit_["to"], OPPOSITE[key[1]]), {}).get("to") != key[0])
    exits_of: dict[int, list[str]] = {}
    for room, side in exits:
        exits_of.setdefault(room, []).append(side)
    size_counts = [sum(1 for r in records if r["size"] == s) for s in range(ad.SIZE_COUNT)]
    reached, queue = {starts[0]}, [starts[0]]
    while queue:
        room = queue.pop()
        for side in SIDES:
            exit_ = exits.get((room, side))
            if exit_ and exit_["to"] in by_number and exit_["to"] not in reached \
                    and walks[(room, side)]["how"] in ("walk", "jump") and not exit_["raised"]:
                reached.add(exit_["to"])
                queue.append(exit_["to"])
    # The regions the floor-level doorways make: rooms from which each can
    # reach the other without leaving by a raised doorway.
    def floor_reach(start: int) -> set:
        seen, todo = {start}, [start]
        while todo:
            room = todo.pop()
            for side in SIDES:
                exit_ = exits.get((room, side))
                if exit_ and not exit_["raised"] and exit_["to"] in by_number \
                        and exit_["to"] not in seen and walks[(room, side)]["how"] != "no":
                    seen.add(exit_["to"])
                    todo.append(exit_["to"])
        return seen

    reach_of = {n: floor_reach(n) for n in by_number}
    regions, placed_in = [], {}
    for number in sorted(by_number):
        if number in placed_in:
            continue
        region = sorted(m for m in reach_of[number] if number in reach_of[m])
        for m in region:
            placed_in[m] = len(regions)
        regions.append(region)
    main = max(range(len(regions)), key=lambda i: len(regions[i]))
    rows = sorted({n >> 4 for n in by_number})
    columns = sorted({n & 15 for n in by_number})
    full = sorted(n for n, used in room_records_used.items()
                  if used == RECORDS - FIRST_ROOM_RECORD)
    most = max(room_records_used.values())
    nudged = sorted(r["number"] for r in records
                    if any(t == 0 for _, t, _, _ in r["groups"]))
    nudges: dict[int, list[int]] = {}
    for r in records:
        for _, t, _, p in r["groups"]:
            if t == 0:
                nudges.setdefault(p[0], []).append(r["number"])
    paged = sorted(r["number"] for r in records
                   if any(t == 31 for _, t, _, _ in r["groups"]))
    cut_short = sorted(r["number"] for r in records
                       if any(len(p) < n for _, t, n, p in r["groups"] if t not in (0, 31)))

    lines = ['<div class="kl-list">',
             "<p>Alien 8's cryogenic ship is 128 rooms on Knight Lore's 16 by 16 grid, each a "
             f"record in the room directory at {ref(ad.ROOMS)}. This page draws every one of "
             "them with the game's own code, puts them together into one map in the game's own "
             "projection, marks on it where the game's things are, and gives each room's record "
             "decoded. The grid, the record and the builder are Knight Lore's "
             '(<a href="../knightlore/RoomStructure.html">its castle</a>); Pentagram, the next '
             "game on the engine, gave the grid up "
             '(<a href="../pentagram/RoomStructure.html">its world</a>).</p>',
             "<p><b>What is measured and what is read.</b> Measured, in SkoolKit's simulator: the "
             "pictures (each room built and drawn by the game, and read out of its screen "
             "buffer); what each room holds as built (the sockets, the robots, lifts and blocks, "
             "the things on the ceiling, and each place's valve or life, which were checked "
             "against the records); the deadly things (from the bits the game sets, after a "
             "turn); what the places held in the simulator's game; and the doorways (each one "
             "walked through). Read from the game's tables and code: the record format, the "
             "sizes, which background is a doorway and in which wall, where each doorway leads, "
             "the start rooms, the places' positions, and what the latch on the falling things "
             "and the dealing of the places do. The map's layout is the game's own arithmetic on "
             "room numbers.</p>",
             "<h3>The station</h3>",
             "<p>A room's number is its square on a 16 by 16 grid: the high four bits the row, "
             "the low four the column. Leaving by a doorway changes the number by arithmetic "
             f"alone, in the robot's move ({ref(HANDLE_EXIT)}): out through the wall at higher U "
             f"adds 1 and at lower U takes 1, changing only the column so that it wraps within "
             f"the row ({ref(EXIT_HIGH_U)}, {ref(EXIT_LOW_U)}); out at higher V adds 16 and at "
             f"lower V takes 16 ({ref(EXIT_HIGH_V)}, {ref(EXIT_LOW_V)}). On the screen +U runs "
             f"down to the right and +V up to the right ({ref(CALC_PIXEL_XY)}); here, as on "
             "Knight Lore's page, +U is called east and +V north. Whichever wall he leaves "
             "by, the exit leaves a marker of 0 or $FF in his U or V, and "
             f"{ref(ARRIVE)} turns it into a place just inside the opposite wall of the next "
             f"room, at the height of the arch there ({ref(ADJUST_FOR_ARCH)}).</p>",
             f"<p>{len(by_number)} of the 256 squares are rooms, in rows {rows[0]} to {rows[-1]} "
             f"and columns {columns[0]} to {columns[-1]}. Below, every room is drawn by the game "
             "and put where the game's own projection places its square, on its floor; the back "
             "rooms are pasted first, so nearer rooms stand in front. Click a room for its "
             'entry, or <a href="images/world/station.png">see the whole station at full '
             "size</a>. The markers show where things are, each from the game's own tables or "
             "from the rooms as the game builds them; tick a box to show its layer.</p>",
             '<div class="kl-layers">', "".join(toggles),
             '<div class="kl-castle"><div class="kl-castle-stack">'
             f'<img src="images/world/station_overview.png" usemap="#station" alt="The station" '
             f'width="{overview.width}" height="{overview.height}">'
             + "".join(overlays) + "</div>"
             f'<map name="station">{areas}</map></div></div>']
    lines += keys

    crew_where = ("exactly the chambers" if set(crew_rooms) == set(chambers)
                  else f"not only the chambers: {_rooms(crew_rooms)}")
    lines += ["<h3>The chambers</h3>",
              f"<p>{len(chambers)} rooms have a socket, one to a room: {kind_counts[0]}, "
              f"{kind_counts[1]}, {kind_counts[2]} and {kind_counts[3]} of the four kinds. A "
              "socket is object template 24 to 27, which puts the socket (graphics "
              f"{_numbers(SOCKET_GRAPHICS)}, {ref(SOCKET)}) and above it a sparkle (graphics "
              f"108-111, {ref(SOCKET_SPARKLE)}) that flashes a picture of the valve it wants "
              "while the room holds none. The socket's graphic less 112 is the kind, and a "
              "valve's graphic less 96; they must match. "
              + ("The four sockets are drawn with one sprite, so only the sparkle's picture "
                 "tells the kinds apart on the screen. "
                 if len({graphic_sprite[g] for g in SOCKET_GRAPHICS}) == 1 else "")
              + "The crew are the cryonauts, graphic "
              f"{CRYONAUT} (object templates 21 and 22), in {len(crew_rooms)} rooms, "
              f"{crew_where}; {sum(c['crew'] for c in chambers.values())} of them in all, which "
              "is the count the summary at the end of a game gives as lost when no chamber is "
              f"activated ({ref(SUMMARISE)} counts a chamber's crew from its record).</p>"]
    lines.append('<table class="kl-table"><tr><th>Kind</th><th>Valve</th><th>Socket</th>'
                 "<th>Chambers</th></tr>")
    for kind in range(4):
        lines.append(f"<tr><td>{kind}</td><td>{graphic_thumb(VALVES[kind])} graphic "
                     f"{VALVES[kind]}</td><td>{graphic_thumb(SOCKET_GRAPHICS[kind])} graphic "
                     f"{SOCKET_GRAPHICS[kind]}</td><td>"
                     + ", ".join(f"{_room_link(n)} ({chambers[n]['crew']})"
                                 for n in marked[f"chamber{kind}"]) + "</td></tr>")
    lines.append("</table>")

    lines += ["<h3>The doorways</h3>",
              f"<p>A doorway is a background whose first piece is a pillar of graphic "
              f"{FIRST_PILLAR_GRAPHIC}, whose update routine ({ref(FIRST_PILLAR)}) lets the robot "
              "through the wall while he stands in the arch. Which wall it is in follows from "
              "where the pillar stands: backgrounds "
              + "; ".join(f'<a href="Scenery.html#background{b}">{b}</a> '
                          f"{SIDE_NAMES[d['side']]}{' (raised)' if d['raised'] else ''}"
                          for b, d in sorted(doorways.items()))
              + f". The builder takes a room's doorways to be its first four backgrounds "
              f"({ref(ADJUST_FOR_ARCH)} looks only there for the arch he comes in by), and in "
              "every room they are.</p>",
              f"<p>There are {len(exits)} doorways. Every one leads to a room that exists "
              + ("" if not missing_rooms else f"(except {len(missing_rooms)}) ")
              + f"and has a doorway in the opposite wall leading back ({pairs} of {len(exits)}"
              + (f"; not: {', '.join(f'{_room_link(r)} {SIDE_NAMES[s]}' for r, s in unpartnered)}"
                 if unpartnered else "")
              + "), and "
              + ("none crosses the edge of the grid, so the wrapping arithmetic is never used"
                 if not wraps else
                 f"{len(wraps)} cross the edge of the grid and wrap")
              + f". {len(floor_doors)} are at floor level and {len(raised)} are raised: their "
              "arch stands 48 units up, on a ledge of two blocks (backgrounds "
              '<a href="Scenery.html#background12">12</a> and '
              '<a href="Scenery.html#background13">13</a>), and all of them are in the '
              + " and ".join(SIDE_NAMES[s] for s in raised_sides)
              + f" walls, the near ones the picture does not draw. Every raised doorway's "
              f"partner on the other side is at floor level ({raised_pairs} of {len(raised)}).</p>",
              "<p>Every doorway was tried in the simulator when this page was built: the room "
              f"built, the robot stood {WALK_INSET} units inside the wall in the middle of the "
              "arch (or, where something stands there, at the nearest clear spot further in), "
              "facing out, and the walk key held, with any death taken back at each turn so "
              "that what is tested is whether the way is open; where objects cover the floor in "
              "front of the arch, he was also stood on top of them. "
              f"{len(walked)} of the {len(floor_doors)} floor-level doorways let him straight "
              "through"
              + (f"; {len(jumps)} more only with jump held as well ("
                 + ", ".join(f"room {_room_link(r)}'s {SIDE_NAMES[s]} doorway" for r, s in jumps)
                 + ")" if jumps else "")
              + (f"; {len(topped)} only from on top of what covers the floor in front of the arch ("
                 + ", ".join(f"{_room_link(r)} {SIDE_NAMES[s]}" for r, s in topped) + ")"
                 if topped else "")
              + (f"; {len(failed)} did not let him through at all: "
                 + ", ".join(f"{_room_link(r)} {SIDE_NAMES[s]}" for r, s in failed) if failed else
                 "; none is blocked")
              + f". Standing on the ledge of a raised doorway and walking out took him through "
              f"{len(ledge)} of the {len(raised)}; walking and jumping at one from the floor "
              f"below took him through {len(climbed)}"
              + (" (" + ", ".join(f"{_room_link(r)} {SIDE_NAMES[s]}" for r, s in climbed) + ")"
                 if climbed else "")
              + f". In all {len(through)}, he came out in the room the arithmetic names"
              + (f"; in {len(wrong)} he did not ("
                 + ", ".join(f"{_room_link(r)} {SIDE_NAMES[s]}" for r, s in wrong) + ")"
                 if wrong else "")
              + ".</p>"]

    def door_list(pairs) -> str:
        return ", ".join(f"{_room_link(r)} {SIDE_NAMES[s]} to {_room_link(exits[(r, s)]['to'])}"
                         + (" (raised)" if exits[(r, s)]["raised"] else "")
                         for r, s in pairs) or "none"

    others = [i for i in range(len(regions)) if i != main]
    crossings = [key for key, exit_ in exits.items()
                 if placed_in[key[0]] != placed_in.get(exit_["to"], -1)]
    one_way_up = all(exits[key]["raised"] != exits[(exits[key]["to"], OPPOSITE[key[1]])]["raised"]
                     for key in crossings)
    lines += ["<p>The raised doorways matter. Taking only the floor-level doorways he walked "
              f"through, the station falls into {len(regions)} regions, each a set of rooms "
              f"that can all reach one another: one of {len(regions[main])} rooms, which holds "
              f"{len(set(starts) & set(regions[main]))} of the 4 start rooms and "
              f"{len(set(chambers) & set(regions[main]))} of the {len(chambers)} chambers, and "
              f"{len(others)} more, of {min(len(regions[i]) for i in others)} to "
              f"{max(len(regions[i]) for i in others)} rooms each. "
              + ("Between two regions the pair of doorways always has one raised and one at "
                 "floor level, so every crossing is a walk one way and a climb onto a ledge 48 "
                 "units up the other. "
                 if one_way_up else
                 "Between two regions the doorways are not always a raised one and a floor-level "
                 "one. ")
              + f"A walk and a jump from the floor did not get him onto a ledge in any of the "
              f"{len(raised)} rooms with one (above); how he does it in play -- by climbing "
              "what the room holds -- this page does not try to settle. So some regions are "
              "pockets that are walked into and must be climbed out of, and others are "
              "reached only by a climb. The regions other than the largest, with every doorway "
              "across their edge:</p>",
              '<table class="kl-table"><tr><th>Rooms</th><th>Ways in</th>'
              "<th>Ways out</th><th>Holds</th></tr>"]
    for index in others:
        region = regions[index]
        ways_in = sorted(key for key, exit_ in exits.items()
                         if exit_["to"] in region and key[0] not in region)
        ways_out = sorted(key for key, exit_ in exits.items()
                          if key[0] in region and exit_["to"] not in region)
        holds = []
        if set(starts) & set(region):
            holds.append("start room " + _rooms(set(starts) & set(region)))
        if set(chambers) & set(region):
            holds.append("chamber" + ("s " if len(set(chambers) & set(region)) > 1 else " ")
                         + _rooms(set(chambers) & set(region)))
        in_region = [n for n in region if n in places_by_room]
        if in_region:
            holds.append(f"place{'s' if len(in_region) > 1 else ''} in " + _rooms(in_region))
        lines.append(f"<tr><td>{_rooms(region)}</td><td>{door_list(ways_in)}</td>"
                     f"<td>{door_list(ways_out)}</td><td>{'; '.join(holds) or '-'}</td></tr>")
    lines.append("</table>")

    lines += ["<h3>A room record</h3>",
              f"<p>The records are packed end to end at {ref(ad.ROOMS)}, with no index: "
              f"{ref(BUILD_ROOM)} finds a room by stepping from one record to the next until the "
              "number matches. In order:</p>",
              '<table class="kl-table"><tr><th>Byte</th><th>What</th></tr>',
              "<tr><td>0</td><td>The room's number: row in bits 4-7, column in bits 0-3.</td></tr>",
              "<tr><td>1</td><td>How many bytes follow: the distance from this byte to the next "
              "record. The builder counts them down and stops wherever they run out -- even "
              "partway through a group of objects"
              + (" (" + _rooms(cut_short) + " have a group cut short this way)" if cut_short else
                 " (no room's record does)")
              + ".</td></tr>",
              "<tr><td>2</td><td>Bits 6-7 the size, an index into "
              f"{ref(ROOM_SIZES)}; bits 3-5 the room's colour; bits 0-2 the ink it is drawn in, "
              f"which is clear on the tape: {ref(RESET_COLOURS)} copies bits 3-5 into them at "
              f"every new game, and activating the room's chamber makes them white "
              f"({ref(LOOSE_VALVE)}).</td></tr>",
              "<tr><td>3 ...</td><td>The backgrounds, a byte each: an index into "
              f"{ref(ad.BACKGROUND_TABLE)} (see "
              '<a href="Scenery.html">the scenery</a>). Each background is a list of eight-byte '
              "pieces, a record each, which carry their own position.</td></tr>",
              "<tr><td>$FF</td><td>The end of the backgrounds, if objects follow. A room with "
              "none just ends.</td></tr>",
              "<tr><td>groups</td><td>A byte whose bits 3-7 are an object template, an index into "
              f"{ref(ad.OBJECT_TABLE)} (see <a href=\"Templates.html\">the templates</a>), and "
              "bits 0-2 the number of copies less one; then a position byte for each copy. Two "
              "template numbers are not templates: 0 takes the byte after it as a placement "
              f"nudge for the groups that follow ({len(nudged)} rooms use it), and 31 moves on "
              "to the second page of templates, indexes 32 to 39, for the rest of the record "
              f"({len(paged)} rooms), and skips the byte after it. Both cost two bytes whatever "
              "their count says.</td></tr>",
              "</table>",
              "<p>A position byte is a cell of the floor and a level: bits 0-2 the U cell and "
              "bits 3-5 the V cell of an 8 by 8 grid, bits 6-7 the level. The builder makes U = "
              "72 + 16 times the U cell, V likewise, and Z = the floor + 12 times the level. The "
              "nudge adds 8 to U if its bit 0 is set, 8 to V if bit 1 is, and its bits 2-7 to Z. "
              "The values the rooms use: "
              + "; ".join(f"${value:02X} {len(rooms)} time{'s' if len(rooms) > 1 else ''}"
                          + (f" ({_rooms(rooms)})" if len(rooms) < 4 else "")
                          for value, rooms in sorted(nudges.items(), key=lambda i: -len(i[1])))
              + ". $30 lifts the objects after it 48 units, onto a ledge or a stack.</p>",
              "<p>The three sizes, as half-sizes about the room's centre at 128, and the floor's "
              "height:</p>",
              '<table class="kl-table"><tr><th>Size</th><th>Half U</th><th>Half V</th>'
              "<th>Floor</th><th>Shape</th><th>Rooms</th></tr>"]
    for index, (half_u, half_v, floor) in enumerate(sizes):
        lines.append(f"<tr><td>{index}</td><td>{half_u}</td><td>{half_v}</td><td>{floor}</td>"
                     f"<td>{2 * half_u} by {2 * half_v}, {SIZE_WORDS.get(index, '')}</td>"
                     f"<td>{size_counts[index]}</td></tr>")
    narrow = [r for r in records if r["size"]]
    ends = sum(1 for r in narrow
               if sorted(exits_of.get(r["number"], [])) == (["N", "S"] if r["size"] == 1 else ["E", "W"]))
    lines += ["</table>",
              f"<p>{ends} of the {len(narrow)} narrow rooms are corridors with a doorway at "
              "each end and none in the long walls. A room becomes object records from "
              f"{ref(PLAYER)}: the robot's two, two for what lies in the room from the places "
              f"({ref(FIND_SPECIAL)}), then everything the record names, backgrounds first, "
              f"from record {FIRST_ROOM_RECORD} up. That leaves {RECORDS - FIRST_ROOM_RECORD} "
              f"records for the room; the most any room was built with is {most}"
              + (f", in {_rooms(full)}" if full else "")
              + ".</p>",
              "<h3>Every room</h3>",
              "<p>Each drawn by the game as it is entered at the start of a life, without the "
              "robot: what the places hold is what the simulator's game dealt. Positions are "
              "cells (U, V, level).</p>"]

    def routine_of(graphic: int) -> str:
        if graphic >= ad.HANDLER_COUNT:
            return ""
        return ref.within(_word(memory, ad.HANDLERS + 2 * graphic))

    for record in records:
        number = record["number"]
        size = sizes[record["size"]]
        column, row = _grid(number)
        notes = []
        if number in starts:
            notes.append("a game can start here")
        if number in chambers:
            chamber = chambers[number]
            notes.append(f"a cryogenic chamber, wanting a valve of kind {chamber['kind']} "
                         f"(graphic {VALVES[chamber['kind']]}), with {chamber['crew']} crew")
        for place in places_by_room.get(number, []):
            held = ("a valve of kind " + str(place["graphic"] - VALVES[0])
                    if place["graphic"] in VALVES else
                    "an extra life" if place["graphic"] == EXTRA_LIFE else
                    f"graphic {place['graphic']}")
            notes.append(f"place {place['number']} is here, at U {place['u']}, V {place['v']}, "
                         f"Z {place['z']}: in this game, {held}")
        if number in marked["robots"]:
            notes.append("a remote-controlled robot is here")
        if number in marked["drops"]:
            notes.append("something hangs from the ceiling, ready to drop")
        scenery = []
        for _, background in record["backgrounds"]:
            text = f'<a href="Scenery.html#background{background}">background {background}</a>'
            if background in doorways:
                side = doorways[background]["side"]
                how = walks[(number, side)]["how"]
                text += (f": {'a raised' if doorways[background]['raised'] else 'a'} doorway "
                         f"{SIDE_NAMES[side]} to {_room_link(room_step(number, side))}")
                if walks[(number, side)].get("on_top"):
                    text += " (walked through from on top of what stands in front of it)"
                elif how == "jump":
                    text += " (a jump needed to get through it)"
                elif how == "no":
                    text += " (not walked through)"
            scenery.append(text)
        groups = []
        for _, index, count, positions in groups_of(record):
            if index == 31:
                groups.append("on to the second page of templates")
                continue
            if index == 0:
                groups.append(f"placement nudge ${positions[0]:02X}")
                continue
            graphics = template_graphics(index)
            text = (f'{graphic_thumb(graphics[0])}<a href="Templates.html#template{index}">'
                    f"template {_template_name(index)}</a> (graphic"
                    f"{'s' if len(graphics) > 1 else ''} {', '.join(str(g) for g in graphics)}, "
                    f"{routine_of(graphics[0])})")
            text += (f" x{len(positions)}" if len(positions) > 1 else "") + " at "
            text += ", ".join(_cell(p) for p in positions)
            if len(positions) < count:
                text += f" (the header says {count}; the byte count runs out first)"
            groups.append(text)
        deadly = deadly_graphics[number]
        lines += [f'<div class="kl-item" id="room{number:02x}">',
                  f'<img class="kl-scene" src="images/world/room{number:02x}.png" '
                  f'alt="Room ${number:02X}">',
                  f"<p><b>Room ${number:02X}</b> (row {row}, column {column}) -- "
                  f"{ref(record['address'])}: {SIZE_WORDS.get(record['size'], '')}, "
                  f"{2 * size[0]} by {2 * size[1]}, {ad.INKS[record['colour']]}; "
                  f"{room_records_used[number]} records built."
                  + (" " + "; ".join(notes)[0].upper() + "; ".join(notes)[1:] + "." if notes else "")
                  + "</p>",
                  "<p>Backgrounds: " + ("; ".join(scenery) or "none") + ".</p>",
                  ('<p>Objects:</p><ul class="a8-room-objects">'
                   + "".join(f"<li>{g}</li>" for g in groups) + "</ul>")
                  if groups else "<p>Objects: none.</p>"]
        if deadly:
            lines.append(f"<p>Deadly after a turn: graphic{'s' if len(deadly) > 1 else ''} "
                         f"{_numbers(deadly)}.</p>")
        lines.append("</div>")
    lines.append("</div>")

    log(f"  {len(records)} rooms, {len(exits)} doorways ({len(raised)} raised); walked through "
        f"{len(through)} of {len(exits)} (jump {len(jumps)}, failed {len(failed)}, wrong "
        f"{len(wrong)}, raised climbed {len(climbed)}); reached {len(reached)}; deadly graphics "
        f"{_numbers(deadly_all)}; chambers {len(chambers)}; most records {most}")
    return {"RoomStructure": "\n".join(lines)}
