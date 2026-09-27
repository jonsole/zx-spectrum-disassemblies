"""Pentagram's world: the Room structure page, drawn from the game at build time.

build_pentagram.py --html calls build(), which draws every room with the
game's own code into the HTML directory and returns the page's section. Like
everything the build writes from the game, none of it is committed: the
pictures are the game's, and so are the room lists.

How the pictures are made. The game is started in SkoolKit's simulator the
way the build's sessions start it (build_pentagram.Machine, the menu, key 1
and 0), and stopped where a room is entered, at GAME_LOOP ($AFC8) just after
a life has started. From that state, each room is drawn by setting the
player's room, emptying his two records so that he is not in the picture, and
running the game's own code: the room builder, the quest things put in, the
first turn of the main loop -- every object's update routine once, then the
drawing of the whole room into the buffer -- up to the point on that first
turn where the room's colour has been put on the screen and the panel has not
yet been drawn into the buffer ($B06C). The picture is read out of the buffer
at $D88F (192 rows of 32 bytes, the bottom line first) in that colour. The
score's call at $AFD4 is skipped, because it prints into the same buffer.

The map. Pentagram's rooms are not numbered on a grid: each doorway's
scenery entry carries the number of the room it leads to (the first pillar's
+$08, #R$C7AD), and which wall the doorway is in follows from where its
template stands the pillars. Laying the rooms out square by square from the
doorways' sides gives one consistent grid -- every loop closes -- except that
a few rooms land on squares other rooms already hold; those are drawn aside
with lines to where their doorways lead (see world_layout).

The layers are read from the game's tables (the start rooms, the quest
records, the collectables' places, the update-routine table) and from the
rooms as the game builds them (the well, lifts, crumbling blocks, and what
has its deadly bits set after a turn); the doorways are walked through in the
simulator.
"""
from __future__ import annotations

import html
import re
from pathlib import Path

import pentagram_data as pd

# --------------------------------------------------------------------------
# Addresses (see their entries in the listing).
# --------------------------------------------------------------------------

GAME_LOOP = 0xAFC8          # enter a room: file the quest things, build, put them in
SCORE_CALL = 0xAFD4         # CALL $BB14: prints the score into the buffer
AFTER_SCORE = 0xAFD7
MAIN_LOOP = 0xAFDA          # a turn begins
ROOM_DRAWN = 0xB06C         # first turn in a room: the colour is on the screen, the
                            # panel not yet drawn into the buffer
BUFFER = 0xD88F             # 192 rows of 32 bytes, the bottom line first
ATTRIBUTES = 0x5800

PENTAGRAM_ON = 0xA70F
LIVES = 0xA721
PLAYER = 0xA76F             # the legs; the body is the next record
BODY = 0xA78F
RECORD = 32
RECORDS = 54
ROOM_AT = 8                 # +8 of a record: its room
FLAGS_AT = 7
STATE_AT = 0x0D             # bits 7 and 5: deadly (#R$C291); bit 6: killed
DEADLY_BITS = 0xA0
KILLED = 0x40
PLAYER_ROOM = PLAYER + ROOM_AT

START_ROOMS = 0xC2E8        # four rooms, one picked by bits 0-1 of RANDOM (#R$C2CE)
CHOOSE_START = 0xC2CE
MAKE_DEADLY = 0xC291
FIRST_PILLAR = 0xC7AD       # the update routine of a doorway's first pillar
BUILD_ROOM = 0xC92C
QUEST_INTO_ROOM = 0xB097
BAN_DROPS = 0xCB89
NEW_QUEST = 0xD16F
QUEST_START = pd.QUEST_START
QUEST_RECORDS = 0xD432      # the live copy the game plays with
QUEST_SIZE = pd.QUEST_SIZE
COLLECTABLE_RECORDS = range(4, 9)
PIECE_RECORDS = range(9, 17)
QUEST_ITEM_RECORDS = range(0, 4)

# Update routines, by what they make of an object (the table at #R$AE2F says
# which graphics have them).
WELL = 0xCFD2
LIFT = 0xCDBB
CONVEYORS = (0xD2DE, 0xD2E9, 0xD2F4, 0xD2FF)
CONVEYOR_PUSH = 0xB866
CRUMBLING = 0xD2AD
SINKING = 0xCDA0

# The walk test: how far inside the wall he starts, facing out, and how long
# he is given.
WALK_INSET = 12
WALK_TURNS = 80
WALK_KEY = "a"              # the A-G half-row walks (keyboard control)
JUMP_KEY = "q"              # Q E T U O jump
# Standing graphics of the legs, and the mirror bit, for each way out: the
# facing is 2 with the mirror bit clear, 0 with it set, plus bit 2 of the
# graphic (#R$C5BD); 0 is -U, 1 +U, 2 +V, 3 -V.
FACE = {"W": (34, 0x40), "E": (38, 0x40), "N": (34, 0x00), "S": (38, 0x00)}
PLAYER_HALF = 5
PLAYER_HEIGHT = 23

SIDES = ("N", "E", "S", "W")
SIDE_NAMES = {"N": "north", "E": "east", "S": "south", "W": "west"}
OPPOSITE = {"N": "S", "S": "N", "E": "W", "W": "E"}
STEP = {"N": (0, 1), "S": (0, -1), "E": (1, 0), "W": (-1, 0)}
SIZE_WORDS = {0: "square", 1: "long from south to north", 2: "long from west to east"}

SPECTRUM = [(0, 0, 0), (0, 0, 0xD7), (0xD7, 0, 0), (0xD7, 0, 0xD7),
            (0, 0xD7, 0), (0, 0xD7, 0xD7), (0xD7, 0xD7, 0), (0xD7, 0xD7, 0xD7)]
SPECTRUM_BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF),
                   (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0), (0xFF, 0xFF, 0xFF)]

TSTATES = 3500000


def _word(memory, address: int) -> int:
    return memory[address] | memory[address + 1] << 8


def _esc(text: str) -> str:
    return html.escape(str(text), quote=False)


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
# The game, ready to enter any room.
# --------------------------------------------------------------------------

class World:
    """The game in the simulator, stopped at GAME_LOOP with a life just
    started, as the base every room is drawn and walked from."""

    def __init__(self, snapshot: Path):
        import build_pentagram as bp

        self.machine = bp.Machine(snapshot)
        # Into a game the way the build's sessions go: the menu, 1 for the
        # keyboard, 0 to start, and the start tune.
        self.machine.play(bp._start("1"), "the world's start")
        self.simulator = self.machine.simulator
        memory = self.simulator.memory
        # A new life: killed, he comes back through RESTART to GAME_LOOP.
        memory[LIVES] = 5
        memory[PLAYER + STATE_AT] |= KILLED
        self._trace(self.machine.pc, GAME_LOOP, 30)
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

    def reset(self, room: int, pokes=None) -> None:
        """The base state, the player moved to `room` and out of sight.
        The collectables are taken out of the quest records: they start in
        random places each game, and have a layer of their own."""
        memory = self.simulator.memory
        memory[:] = self.base
        for index, value in enumerate(self.base_registers):
            self.simulator.registers[index] = value
        memory[PLAYER + ROOM_AT] = room
        memory[BODY + ROOM_AT] = room
        memory[PLAYER] = 0
        memory[BODY] = 0
        for number in COLLECTABLE_RECORDS:
            memory[QUEST_RECORDS + QUEST_SIZE * number] = 0
        if pokes:
            pokes(memory)

    def enter(self) -> None:
        """GAME_LOOP up to the first turn, without printing the score."""
        from skoolkit.simutils import PC

        self._trace(GAME_LOOP, SCORE_CALL, 5)
        self.simulator.registers[PC] = AFTER_SCORE
        self._trace(AFTER_SCORE, MAIN_LOOP, 5)

    def records(self) -> list[tuple]:
        """The room's object records now: (record, graphic, U, V, Z, half
        U, V, height, flags, state), records 2 up (not the player's)."""
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

    def draw(self, room: int, pokes=None) -> dict:
        """Room `room` as the game draws it on entering: the picture, the
        records as built, and the records after the first turn."""
        from PIL import Image

        self.reset(room, pokes)
        self.enter()
        built = self.records()
        self._trace(MAIN_LOOP, ROOM_DRAWN, 10)
        after = self.records()
        memory = self.simulator.memory
        image = Image.new("RGB", (256, 192))
        pixels = image.load()
        for y in range(192):
            row = BUFFER + (191 - y) * 32
            for column in range(32):
                byte = memory[row + column]
                attr = memory[ATTRIBUTES + (y >> 3) * 32 + column]
                palette = SPECTRUM_BRIGHT if attr & 0x40 else SPECTRUM
                ink, paper = palette[attr & 7], palette[(attr >> 3) & 7]
                for bit in range(8):
                    pixels[column * 8 + bit, y] = ink if byte & (0x80 >> bit) else paper
        return {"image": image, "built": built, "after": after}

    def walk(self, room: int, side: int, u: int, v: int, z: int, keys) -> tuple:
        """Stand him at (u, v, z) in `room` facing out through `side`, hold
        `keys`, and see where he gets to. Deaths are taken back at every
        turn (the killed bits cleared), so what is measured is whether the
        way is open, not whether it is safe."""
        memory = self.simulator.memory
        self.reset(room)
        graphic, mirror = FACE[side]
        memory[PLAYER] = graphic
        memory[PLAYER + 1], memory[PLAYER + 2], memory[PLAYER + 3] = u, v, z
        memory[PLAYER + FLAGS_AT] = (memory[PLAYER + FLAGS_AT] & ~0x40) | mirror
        memory[BODY + 1], memory[BODY + 2], memory[BODY + 3] = u, v, z + 12
        for record in (PLAYER, BODY):
            memory[record + 0x0C] = 0
            memory[record + STATE_AT] = 0
        self.machine.tracer.keys = set()
        self.enter()
        self.machine.tracer.keys = set(keys)
        try:
            for turn in range(WALK_TURNS):
                memory[LIVES] = 5
                memory[PLAYER + STATE_AT] &= ~KILLED
                memory[BODY + STATE_AT] &= ~KILLED
                self._trace(MAIN_LOOP, MAIN_LOOP, 5)
                if memory[PLAYER_ROOM] != room:
                    return ("through", turn + 1, memory[PLAYER_ROOM],
                            memory[PLAYER + 1], memory[PLAYER + 2], memory[PLAYER + 3])
                if not 16 <= memory[PLAYER] < 48:
                    return ("died", turn + 1)
            return ("stuck", memory[PLAYER + 1], memory[PLAYER + 2], memory[PLAYER + 3])
        finally:
            self.machine.tracer.keys = set()


# --------------------------------------------------------------------------
# The rooms and their doorways, read.
# --------------------------------------------------------------------------

def scenery_pieces(memory, template: int) -> list[list[int]]:
    """A scenery template's 8-byte pieces, as #R$C92C copies them: on while
    the byte after a piece is not zero."""
    address = _word(memory, pd.SCENERY_TABLE + 2 * template)
    pieces = []
    while True:
        pieces.append(list(memory[address:address + 8]))
        address += 8
        if memory[address] == 0:
            return pieces


def first_pillar_graphics(memory) -> set[int]:
    return {g for g in range(pd.GRAPHIC_COUNT) if _word(memory, pd.HANDLERS + 2 * g) == FIRST_PILLAR}


def doorway_templates(memory, sizes) -> dict[int, dict]:
    """Every scenery template that is a doorway -- one with a first pillar,
    the piece whose update routine (#R$C7AD) takes him to the room in its
    +$08 -- with the wall it stands in, from the pillar's position: at the
    high or low U wall (U 197 or 59) or the high or low V wall. East is +U
    and north +V, the way the projection draws them (up-right is +V)."""
    pillars = first_pillar_graphics(memory)
    floor = sizes[0][2]
    out = {}
    for template in range(pd.SCENERY_COUNT):
        if _word(memory, pd.SCENERY_TABLE + 2 * template) == pd.SCENERY_TABLE:
            continue
        for graphic, u, v, z, *_ in scenery_pieces(memory, template):
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
                out[template] = {"side": side, "z": z, "raised": z > floor,
                                 "graphic": graphic, "middle": middle}
                break
    return out


def room_exits(records, doorways) -> dict[tuple[int, str], dict]:
    exits = {}
    for record in records:
        for index, (part, template, destination) in enumerate(record["scenery"]):
            if template in doorways:
                door = doorways[template]
                key = (record["number"], door["side"])
                if key in exits:
                    raise ValueError(f"room {record['number']} has two doorways "
                                     f"in its {door['side']} wall")
                exits[key] = {"to": destination, "template": template, "entry": index,
                              "raised": door["raised"], "middle": door["middle"],
                              "address": part}
    return exits


def world_layout(records, exits) -> dict:
    """Squares for every room, from the doorways alone.

    Walking from room to room by the doorways, each step moves one square
    the way the doorway faces; a room reached twice must be reached at the
    same square, or the doorways contradict each other (none do). Where two
    rooms land on one square, the lower-numbered keeps it and the other is
    drawn aside: its group -- the rooms joined to it by doorways that were
    also turned out -- moves together to the nearest place with room for it,
    and its doorways back to the rest are drawn as lines."""
    numbers = [record["number"] for record in records]
    grid, contradictions = {}, []
    for root in numbers:
        if root in grid:
            continue
        grid[root] = (0, 0) if not grid else (1000 * len(grid), 0)
        queue = [root]
        while queue:
            room = queue.pop(0)
            for side in SIDES:
                exit_ = exits.get((room, side))
                if not exit_:
                    continue
                dx, dy = STEP[side]
                square = (grid[room][0] + dx, grid[room][1] + dy)
                other = exit_["to"]
                if other in grid:
                    if grid[other] != square:
                        contradictions.append((room, side, other))
                    continue
                grid[other] = square
                queue.append(other)
    held, turned_out = {}, set()
    for room in sorted(numbers):
        square = grid[room]
        if square in held:
            turned_out.add(room)
        else:
            held[square] = room
    # Group the turned-out rooms by doorways between them.
    groups, seen = [], set()
    for room in sorted(turned_out):
        if room in seen:
            continue
        group, queue = [], [room]
        seen.add(room)
        while queue:
            current = queue.pop(0)
            group.append(current)
            for side in SIDES:
                exit_ = exits.get((current, side))
                if exit_ and exit_["to"] in turned_out and exit_["to"] not in seen:
                    seen.add(exit_["to"])
                    queue.append(exit_["to"])
        groups.append(sorted(group))
    placed = {room: grid[room] for room in numbers if room not in turned_out}
    taken = set(placed.values())
    moves = {}
    for group in groups:
        best = None
        for margin in (1, 0):
            for distance in range(1, 40):
                candidates = []
                for dx in range(-distance, distance + 1):
                    for dy in range(-distance, distance + 1):
                        if max(abs(dx), abs(dy)) != distance:
                            continue
                        cells = [(grid[r][0] + dx, grid[r][1] + dy) for r in group]
                        near = {(x + mx, y + my) for x, y in cells
                                for mx in range(-margin, margin + 1)
                                for my in range(-margin, margin + 1)}
                        if not near & taken:
                            candidates.append((abs(dx) + abs(dy), dy < 0, dx, dy))
                if candidates:
                    _, _, dx, dy = min(candidates)
                    best = (dx, dy)
                    break
            if best:
                break
        moves[tuple(group)] = best
        for room in group:
            placed[room] = (grid[room][0] + best[0], grid[room][1] + best[1])
            taken.add(placed[room])
    sharing = {room: held[grid[room]] for room in turned_out}
    return {"grid": grid, "placed": placed, "groups": groups, "moves": moves,
            "sharing": sharing, "contradictions": contradictions}


# --------------------------------------------------------------------------
# The map.
# --------------------------------------------------------------------------

ROOM_SPACING = 128          # a square: walls 64 either side of a room's centre
MAP_GROUND = (7, 7, 28)     # aticatac.css's page colour
MAP_FLOOR = (16, 16, 60)
MAP_FLOOR_EDGE = (40, 40, 110)
MAP_ASIDE_FLOOR = (46, 14, 58)      # a room drawn aside from its square
MAP_ASIDE_EDGE = (120, 60, 140)
MAP_LINK = (230, 190, 255)          # a doorway to a room drawn aside
MAP_MARGIN = 16
MAP_OVERVIEW_WIDTH = 1200


def _project(u: int, v: int, z: int) -> tuple:
    """#R$B2C5: pixel x = U + V - 128, and pixel y = (V - U + 128) / 2 + Z -
    104 counted up from the bottom -- here counted from the top."""
    return u + v - 128, 191 - ((v - u + 128) // 2 + z - 104)


def _floor_corners(size) -> list[tuple]:
    half_u, half_v, floor = size
    return [_project(128 + su * half_u, 128 + sv * half_v, floor)
            for su, sv in ((-1, -1), (1, -1), (1, 1), (-1, 1))]


def _edge_middle(size, side: str) -> tuple:
    half_u, half_v, floor = size
    u = 128 + {"E": half_u, "W": -half_u}.get(side, 0)
    v = 128 + {"N": half_v, "S": -half_v}.get(side, 0)
    return _project(u, v, floor)


def world_map(records, pictures: dict, sizes, layout, exits) -> tuple:
    """The whole world as one picture, each room's floor as a polygon on it,
    and the middle of each floor's edges, for the markers. Floors first, then
    the rooms back to front with black left transparent, then the lines from
    the rooms drawn aside to where their doorways lead."""
    from PIL import Image, ImageChops, ImageDraw

    placed = layout["placed"]
    place = {}
    for number, (gx, gy) in placed.items():
        u_world, v_world = gx * ROOM_SPACING, gy * ROOM_SPACING
        place[number] = (u_world + v_world, (u_world - v_world) // 2)
    left = min(x for x, _ in place.values())
    top = min(y for _, y in place.values())
    width = max(x for x, _ in place.values()) + 256 - left
    height = max(y for _, y in place.values()) + 192 - top
    image = Image.new("RGB", (width, height), MAP_GROUND)
    draw = ImageDraw.Draw(image)
    by_number = {record["number"]: record for record in records}
    floors, edges = {}, {}
    for number in placed:
        size = sizes[by_number[number]["size"]]
        ox, oy = place[number][0] - left, place[number][1] - top
        floors[number] = [(ox + x, oy + y) for x, y in _floor_corners(size)]
        edges[number] = {side: (ox + _edge_middle(size, side)[0], oy + _edge_middle(size, side)[1])
                         for side in SIDES}
        aside = number in layout["sharing"]
        draw.polygon(floors[number], fill=MAP_ASIDE_FLOOR if aside else MAP_FLOOR,
                     outline=MAP_ASIDE_EDGE if aside else MAP_FLOOR_EDGE)
    order = sorted(placed, key=lambda n: (placed[n][0] - placed[n][1], placed[n][0] + placed[n][1]))
    for number in order:
        picture = pictures[number]
        mask = picture.convert("L").point(lambda value: 255 if value else 0)
        image.paste(picture, (place[number][0] - left, place[number][1] - top), mask)
    links = []
    for (room, side), exit_ in exits.items():
        other = exit_["to"]
        adjacent = (placed[room][0] + STEP[side][0], placed[room][1] + STEP[side][1]) == placed[other]
        if not adjacent and room < other:
            links.append((room, side, other))
    for room, side, other in links:
        start = edges[room][side]
        end = edges[other][OPPOSITE[side]]
        draw.line([start, end], fill=MAP_LINK, width=3)
        for x, y in (start, end):
            draw.ellipse((x - 5, y - 5, x + 5, y + 5), fill=MAP_LINK)
    ground = Image.new("RGB", image.size, MAP_GROUND)
    box = ImageChops.difference(image, ground).getbbox()
    x0, y0 = max(0, box[0] - MAP_MARGIN), max(0, box[1] - MAP_MARGIN)
    x1, y1 = min(image.width, box[2] + MAP_MARGIN), min(image.height, box[3] + MAP_MARGIN)
    image = image.crop((x0, y0, x1, y1))
    floors = {n: [(x - x0, y - y0) for x, y in corners] for n, corners in floors.items()}
    edges = {n: {s: (x - x0, y - y0) for s, (x, y) in sides.items()} for n, sides in edges.items()}
    return image, floors, edges, links


# The layers: (key, what, colour, shown at first). Room layers put a dot in
# a slot round the floor's centre, so that several on one room sit side by
# side; the doorway layer puts a square on the doorway's edge of the floor.
LAYERS = [
    ("start", "Where a game starts", (60, 220, 60), True),
    ("well", "The well", (70, 150, 255), True),
    ("quest", "The four quest items", (230, 60, 230), True),
    ("pentagram", "The pentagram", (255, 255, 255), True),
    ("spots", "Where the collectables can start", (240, 220, 40), True),
    ("deadly", "Deadly things", (240, 50, 50), False),
    ("lifts", "Lifts and conveyors", (60, 220, 230), False),
    ("crumbling", "Crumbling and sinking blocks", (255, 140, 0), False),
    ("raised", "Raised doorways: one way unless climbed to", (180, 130, 255), False),
]
ROOM_LAYER_SLOTS = {"start": (-1.5, -0.5), "well": (-0.5, -0.5), "quest": (0.5, -0.5),
                    "pentagram": (1.5, -0.5), "spots": (-1.5, 0.5), "deadly": (-0.5, 0.5),
                    "lifts": (0.5, 0.5), "crumbling": (1.5, 0.5)}
MARKER_RADIUS = 4.5         # on the overview, in pixels
MARKER_STEP = 11
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


# --------------------------------------------------------------------------
# Measuring.
# --------------------------------------------------------------------------

def handlers_to_graphics(memory) -> dict[int, list[int]]:
    out: dict[int, list[int]] = {}
    for graphic in range(pd.GRAPHIC_COUNT):
        out.setdefault(_word(memory, pd.HANDLERS + 2 * graphic), []).append(graphic)
    return out


def walk_doorways(world, records, exits, sizes) -> dict:
    """Every doorway walked through in the simulator. A floor-level one:
    standing WALK_INSET units inside its wall at the middle of the arch,
    facing out, walk; if that does not take him through, try again with jump
    held too, and then from a few more places near it clear of every object.
    A raised one: standing on its ledge in the doorway, at the arch's
    height, walk. Each result says whether he came out in the room the
    doorway names."""
    by_number = {record["number"]: record for record in records}
    results = {}
    for (room, side), exit_ in sorted(exits.items()):
        half_u, half_v, floor = sizes[by_number[room]["size"]]
        half = half_u if side in "EW" else half_v
        sign = 1 if side in "NE" else -1
        if exit_["raised"]:
            mu, mv = exit_["middle"]
            spot = (128 + sign * (half - 2), mv) if side in "EW" else (mu, 128 + sign * (half - 2))
            outcome = world.walk(room, side, spot[0], spot[1], exit_["z"] if "z" in exit_ else 176,
                                 (WALK_KEY,))
            results[(room, side)] = {"how": "ledge" if outcome[0] == "through" else "no",
                                     "outcome": outcome, "from": spot}
            continue
        world.reset(room)
        world.enter()
        objects = world.records()
        tries = []
        for inset in range(WALK_INSET, 2 * half, 4):
            for offset in (0, 4, -4, 8, -8):
                along = 128 + sign * (half - inset)
                u, v = (along, 128 + offset) if side in "EW" else (128 + offset, along)
                clear = all(not (abs(ou - u) < hu + PLAYER_HALF and abs(ov - v) < hv + PLAYER_HALF
                                 and oz < floor + PLAYER_HEIGHT and oz + hz > floor)
                            for _, _, ou, ov, oz, hu, hv, hz, _, _ in objects)
                if clear:
                    tries.append((u, v))
            if len(tries) >= 4:
                break
        found = None
        for keys, how in (((WALK_KEY,), "walk"), ((WALK_KEY, JUMP_KEY), "jump")):
            for u, v in tries[:4]:
                outcome = world.walk(room, side, u, v, floor, keys)
                if outcome[0] == "through":
                    found = {"how": how, "outcome": outcome, "from": (u, v)}
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


def _room_link(number: int) -> str:
    return f'<a href="#room{number}">{number}</a>'


def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    from PIL import Image

    from build_pentagram import game_memory

    memory = game_memory(snapshot)
    ref = Refs(snapshot.with_name("pentagram.skool"))
    image_dir = html_dir / "images" / "world"
    image_dir.mkdir(parents=True, exist_ok=True)

    records = pd.room_records(memory)
    sizes = [pd.room_size(memory, index) for index in range(3)]
    doorways = doorway_templates(memory, sizes)
    exits = room_exits(records, doorways)
    for (room, side), exit_ in exits.items():
        exit_["z"] = doorways[exit_["template"]]["z"]
    layout = world_layout(records, exits)
    handlers = handlers_to_graphics(memory)
    graphic_sprite = {g: _word(memory, pd.GRAPHICS + 2 * g) for g in range(pd.GRAPHIC_COUNT)}
    pictured = set(pd.picture_sprites(memory))

    log("  drawing the rooms with the game's own code...")
    world = World(snapshot)
    drawn = {}
    for record in records:
        number = record["number"]
        drawn[number] = world.draw(number)
        drawn[number]["image"].save(image_dir / f"room{number}.png")
    pentagram_room = memory[QUEST_START + QUEST_SIZE * PIECE_RECORDS[0] + ROOM_AT]

    def pentagram_on(mem):
        mem[PENTAGRAM_ON] = 1
    with_pieces = world.draw(pentagram_room, pentagram_on)
    with_pieces["image"].save(image_dir / f"room{pentagram_room}_pentagram.png")

    log("  walking through every doorway...")
    walks = walk_doorways(world, records, exits, sizes)

    # What each room holds, as built and after a turn.
    built_graphics = {n: [r[1] for r in drawn[n]["built"]] for n in drawn}
    deadly_graphics = {n: sorted({r[1] for r in drawn[n]["after"] if r[9] & DEADLY_BITS})
                       for n in drawn}
    deadly_all = sorted({g for gs in deadly_graphics.values() for g in gs})
    deadly_by_handler: dict[int, list[int]] = {}
    for graphic in deadly_all:
        deadly_by_handler.setdefault(_word(memory, pd.HANDLERS + 2 * graphic), []).append(graphic)
    # Read: which graphics have an update routine that calls MAKE_DEADLY.
    well_graphics = set(handlers.get(WELL, []))
    lift_graphics = set(handlers.get(LIFT, []))
    conveyor_graphics = {g for address in CONVEYORS for g in handlers.get(address, [])}
    crumbling_graphics = set(handlers.get(CRUMBLING, []))
    sinking_graphics = set(handlers.get(SINKING, []))

    starts = list(memory[START_ROOMS:START_ROOMS + 4])
    quest_rooms = [memory[QUEST_START + QUEST_SIZE * n + ROOM_AT] for n in QUEST_ITEM_RECORDS]
    quest_graphics = [memory[QUEST_START + QUEST_SIZE * n] for n in QUEST_ITEM_RECORDS]
    piece_rooms = sorted({memory[QUEST_START + QUEST_SIZE * n + ROOM_AT] for n in PIECE_RECORDS})
    spots = [tuple(memory[pd.SPOTS + 4 * n:pd.SPOTS + 4 * n + 4]) for n in range(pd.SPOT_COUNT)]
    spots_by_room: dict[int, list[int]] = {}
    for number, spot in enumerate(spots):
        spots_by_room.setdefault(spot[0], []).append(number)

    marked = {
        "start": sorted(set(starts)),
        "well": sorted(n for n in drawn if well_graphics & set(built_graphics[n])),
        "quest": sorted(set(quest_rooms)),
        "pentagram": piece_rooms,
        "spots": sorted(spots_by_room),
        "deadly": sorted(n for n in drawn if deadly_graphics[n]),
        "lifts": sorted(n for n in drawn if (lift_graphics | conveyor_graphics) & set(built_graphics[n])),
        "crumbling": sorted(n for n in drawn
                            if (crumbling_graphics | sinking_graphics) & set(built_graphics[n])),
    }
    # The quest items are put into their rooms by the game's own code: check.
    for room, graphic in zip(quest_rooms, quest_graphics):
        if graphic not in built_graphics[room]:
            raise RuntimeError(f"quest item graphic {graphic} did not appear in room {room}")
    raised = sorted(key for key, exit_ in exits.items() if exit_["raised"])

    log("  putting the world together...")
    pictures = {n: drawn[n]["image"] for n in drawn}
    whole, floors, edges, links = world_map(records, pictures, sizes, layout, exits)
    whole.save(image_dir / "world.png")
    scale = MAP_OVERVIEW_WIDTH / whole.width
    overview = whole.resize((MAP_OVERVIEW_WIDTH, round(whole.height * scale)), Image.LANCZOS)
    overview.save(image_dir / "world_overview.png")
    areas = "".join(
        '<area shape="poly" coords="'
        + ",".join(f"{round(x * scale)},{round(y * scale)}" for x, y in corners)
        + f'" href="#room{number}" title="Room {number}" alt="Room {number}">'
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
        toggles.append(f'<input type="checkbox" class="kl-toggle" id="pg-layer-{key}"'
                       + (" checked" if shown else "") + ">"
                       f'<label for="pg-layer-{key}"><span class="kl-key pg-key-{key}">'
                       f"</span>{what} ({count})</label>")
        overlays.append(f'<img class="pg-layer pg-layer-{key}" '
                        f'src="images/world/layer_{key}.png" alt="">')

    def key_line(key, text):
        what = next(w for k, w, _, _ in LAYERS if k == key)
        keys.append(f'<p><span class="kl-key pg-key-{key}"></span><b>{what}</b>: {text}</p>')

    key_line("start", ", ".join(_room_link(n) for n in starts)
             + f". {ref(CHOOSE_START)} copies one of the four bytes at {ref(START_ROOMS)} into "
             "the player's template, picked by the two low bits of the random number, which "
             "the menu has been stirring.")
    key_line("well", ", ".join(_room_link(n) for n in marked["well"])
             + ". The rooms whose built records include graphic "
             + ", ".join(str(g) for g in sorted(well_graphics))
             + f", the graphic whose update routine is the well's ({ref(WELL)}): shot at for "
             "long enough, it gives the bucket.")
    key_line("quest", "; ".join(f"{_room_link(room)} (record {n}, graphic {g})"
                                for n, (room, g) in enumerate(zip(quest_rooms, quest_graphics)))
             + f". From the first four quest records at {ref(QUEST_START)}, which "
             f"{ref(NEW_QUEST)} copies for play at every new game; each room's picture shows its "
             f"item, put there by {ref(QUEST_INTO_ROOM)} as the room is entered. A bucket put "
             "down in one of these rooms flies to the item and finishes it.")
    key_line("pentagram", ", ".join(_room_link(n) for n in piece_rooms)
             + f". All eight pieces' records (9 to 16 at {ref(QUEST_START)}) name this room, but "
             f"{ref(QUEST_INTO_ROOM)} leaves them out until all four quest items are done; the "
             "room's entry below shows it both ways.")
    key_line("spots", "; ".join(f"{_room_link(room)} (place{'s' if len(n) > 1 else ''} "
                                f"{', '.join(str(i) for i in n)})"
                                for room, n in sorted(spots_by_room.items()))
             + f". The {pd.SPOT_COUNT} places at {ref(pd.SPOTS)}: {ref(NEW_QUEST)} puts the five "
             "collectables in five places in a row from the list, starting at one of the first "
             "sixteen chosen at random, so each game uses a different run of five.")
    key_line("deadly", ", ".join(_room_link(n) for n in marked["deadly"])
             + f". Measured: the rooms in which, after the game has built them and run every "
             f"object's update routine once, some record has its deadly bits set -- bits 7 and 5 "
             f"of +$0D, which only {ref(MAKE_DEADLY)} sets. The graphics found deadly this way, "
             "with the update routines that made them so: "
             + "; ".join(f"{_numbers(gs)} ({ref(h)})" for h, gs in sorted(deadly_by_handler.items()))
             + ". Things that fall from the sky are not counted: they can come in any room "
             f"where nothing bans them ({ref(BAN_DROPS)}).")
    key_line("lifts", ", ".join(_room_link(n) for n in marked["lifts"])
             + f". Rooms whose built records include a lift (graphic "
             f"{_numbers(lift_graphics)}, {ref(LIFT)}) or a conveyor (graphics "
             f"{_numbers(conveyor_graphics)}, {ref(CONVEYORS[0])} and its neighbours, the push "
             f"itself in {ref(CONVEYOR_PUSH)}).")
    key_line("crumbling", ", ".join(_room_link(n) for n in marked["crumbling"])
             + f". Rooms with a block that crumbles a stage a turn while stood on (graphics "
             f"{_numbers(crumbling_graphics)}, {ref(CRUMBLING)}) or one that sinks (graphic "
             f"{_numbers(sinking_graphics)}, {ref(SINKING)}).")
    key_line("raised", ", ".join(f"{_room_link(room)} {SIDE_NAMES[side]} to {exits[(room, side)]['to']}"
                                 for room, side in raised)
             + ". Doorways whose arch stands on a ledge above the floor, marked on their wall. "
             "Coming the other way he arrives on the ledge and steps down; to leave by one he "
             "must first climb to the ledge's height, which the page does not try to settle.")

    # Doorway statistics.
    pairs = sum(1 for (room, side), exit_ in exits.items()
                if exits.get((exit_["to"], OPPOSITE[side]), {}).get("to") == room)
    raised_pairs = sum(1 for room, side in raised
                       if not exits[(exits[(room, side)]["to"], OPPOSITE[side])]["raised"])
    through = [key for key, result in walks.items() if result["how"] in ("walk", "jump", "ledge")
               and result["outcome"][2] == exits[key]["to"]]
    jumps = sorted(key for key, result in walks.items() if result["how"] == "jump")
    failed = sorted(key for key, result in walks.items() if result["how"] == "no")
    floor_doors = [key for key in exits if not exits[key]["raised"]]
    walked = [key for key in floor_doors if walks[key]["how"] == "walk"]
    ledge = [key for key in raised if walks[key]["how"] == "ledge"]
    exits_of: dict[int, list[str]] = {}
    for room, side in exits:
        exits_of.setdefault(room, []).append(side)
    to_room_zero = sorted(key for key, exit_ in exits.items() if exit_["to"] == 0)
    size_counts = [sum(1 for r in records if r["size"] == s) for s in range(3)]
    xs = [x for x, _ in layout["grid"].values()]
    ys = [y for _, y in layout["grid"].values()]

    lines = ['<div class="kl-list">',
             "<p>Pentagram's world is 139 rooms of forest and ruin, each a record in the room "
             f"directory at {ref(pd.ROOMS)}. This page draws every one of them with the game's own "
             "code, puts them together into one map in the game's own projection, marks on it "
             "where the game's things are, and gives each room's record decoded. Knight Lore, "
             "whose engine this is, keeps its castle on a numbered grid "
             '(<a href="../knightlore/RoomStructure.html">its rooms</a>); Pentagram does not, '
             "and working out its map is part of what follows.</p>",
             "<p><b>What is measured and what is read.</b> The pictures are measured: each room is "
             "built and drawn by the game in a simulator, and read out of its screen buffer. So "
             "are the things found in the rooms as built (the well, lifts, crumbling blocks), "
             "the deadly things (from the bits the game sets, after a turn), and the doorways "
             "(each one walked through). Read from the game's tables: the record format, the "
             "doorways' destinations and walls, the start rooms, the quest records and the "
             "collectables' places. Worked out from those, and not something the game itself "
             "holds anywhere: the layout of the map.</p>",
             "<h3>The world</h3>",
             "<p>No arithmetic on room numbers leads from one room to the next. A doorway is a "
             f"scenery entry whose template stands the two pillars of an arch in one of the "
             f"walls, and its second byte is the number of the room it leads to: the room "
             f"builder ({ref(BUILD_ROOM)}) copies that byte into every piece's +$08, and the "
             f"first pillar's update routine ({ref(FIRST_PILLAR)}) sends him there once he is "
             "through. Which wall the arch is in, the template says by where it puts the "
             "pillars: at the high or the low U wall, or the high or the low V wall. On the "
             "screen, +U runs down to the right and +V up to the right "
             f"({ref(0xB2C5)}); here +U is called east and +V north. Leaving by the east wall "
             f"he arrives at the west wall of the next room, lined up with its arch "
             f"({ref(0xCA82)}).</p>",
             f"<p>There are {len(exits)} doorways, and every one has a partner: the room it leads "
             f"to has a doorway in the opposite wall leading back ({pairs} of {len(exits)}). "
             "Taking each doorway as one step the way it faces, and starting anywhere, every "
             "room gets a square, and every loop comes back to where it started: "
             + ("no two routes to a room disagree. " if not layout["contradictions"] else
                f"{len(layout['contradictions'])} routes disagree. ")
             + f"The squares span {max(xs) - min(xs) + 1} columns by {max(ys) - min(ys) + 1} rows. "
             "But the world is not quite flat: "
             + "; ".join(
                 f"room{'s' if len(group) > 1 else ''} {_numbers(group)} "
                 f"{'land' if len(group) > 1 else 'lands'} on the squares of "
                 f"{_numbers(layout['sharing'][r] for r in group)}"
                 for group in layout["groups"])
             + ". A doorway only names a room, so nothing in the game needs the rooms to fit "
             "on a plan, and nothing stops two of them sharing a place: walking through one, "
             "the player cannot see the other. On the map each of these is drawn aside, on a "
             "darker floor, and "
             "a line joins each of its doorways to the room it leads to.</p>",
             "<p>Below, each room is drawn by the game and put on its square, in the game's "
             "projection, on its floor; the back rooms are pasted first, so nearer rooms stand "
             "in front. Click a room for its entry, or "
             '<a href="images/world/world.png">see the whole world at full size</a>. The '
             "markers show where things are, each from the game's own tables or from the rooms "
             "as the game builds them; tick a box to show its layer.</p>",
             '<div class="kl-layers">', "".join(toggles),
             '<div class="kl-castle"><div class="kl-castle-stack">'
             f'<img src="images/world/world_overview.png" usemap="#world" alt="The world" '
             f'width="{overview.width}" height="{overview.height}">'
             + "".join(overlays) + "</div>"
             f'<map name="world">{areas}</map></div></div>']
    lines += keys

    lines += ["<h3>The doorways</h3>",
              f"<p>{len(floor_doors)} doorways are at floor level and {len(raised)} are raised: "
              "their arch stands on a ledge (the scenery templates with graphic 11 beside them), "
              "and each raised doorway's partner on the other side is at floor level "
              f"({raised_pairs} of {len(raised)}). Every doorway was tried in the simulator when "
              f"this page was built: the room built, the player stood {WALK_INSET} units inside "
              "the wall in the middle of the arch (or, where something stands there, at the "
              "nearest clear spot further in), facing out, and the walk key held, with any "
              "death taken back at each turn so that what is tested is whether the way is open. "
              f"{len(walked)} of the {len(floor_doors)} floor-level doorways let him straight "
              "through"
              + (f"; {len(jumps)} more only with jump held as well ("
                 + ", ".join(f"room {_room_link(r)}'s {SIDE_NAMES[s]} doorway" for r, s in jumps)
                 + ")" if jumps else "")
              + (f"; {len(failed)} did not let him through at all: "
                 + ", ".join(f"{_room_link(r)} {SIDE_NAMES[s]}" for r, s in failed) if failed else
                 "; none is blocked")
              + f". Standing on the ledge of a raised doorway and walking out took him through "
              f"{len(ledge)} of the {len(raised)}. In all {len(through)}, he came out in the room "
              "the doorway's byte names. So no doorway is shut and none leads one way only, "
              "except that a raised one must be climbed to.</p>"]
    if to_room_zero:
        lines.append("<p>" + ", ".join(f"Room {_room_link(r)}'s {SIDE_NAMES[s]} doorway"
                                       for r, s in to_room_zero)
                     + " leads to room 0: a destination byte of zero is a real doorway, like any "
                     "other, since the pillar's routine takes whatever the byte holds.</p>")

    lines += ["<h3>A room record</h3>",
              f"<p>The records are packed end to end at {ref(pd.ROOMS)}, with no index: "
              f"{ref(BUILD_ROOM)} finds a room by stepping from one record to the next until the "
              "number matches. In order:</p>",
              '<table class="kl-table"><tr><th>Byte</th><th>What</th></tr>',
              "<tr><td>0</td><td>The room's number.</td></tr>",
              "<tr><td>1</td><td>How many bytes follow: the distance from this byte to the next "
              "record. The builder counts them down and stops wherever they run out -- even "
              "partway through a group of objects (rooms "
              + ", ".join(_room_link(r["number"]) for r in records
                          if any(len(p) < n for _, _, n, p in r["groups"]))
              + " have a group cut short this way).</td></tr>",
              "<tr><td>2</td><td>Bits 0-2 the ink the whole room is drawn in (the builder adds "
              f"BRIGHT); bits 3-7 its size, an index into {ref(pd.SIZES)}.</td></tr>",
              "<tr><td>3 ...</td><td>The scenery, two bytes an entry: a scenery template, an "
              f"index into {ref(pd.SCENERY_TABLE)} (see "
              '<a href="Scenery.html">the scenery</a>), and a byte the builder copies into +$08 '
              "of every piece: for a doorway, the room it leads to; for other scenery, "
              "zero.</td></tr>",
              "<tr><td>$FF</td><td>The end of the scenery, if objects follow.</td></tr>",
              "<tr><td>groups</td><td>A byte whose bits 3-7 are an object template, an index into "
              f"{ref(pd.OBJECT_TABLE)} (see <a href=\"Templates.html\">the templates</a>), and "
              "bits 0-2 the number of copies less one; then a position byte for each copy. "
              "Template 31 would switch to a second page of templates; no room uses it.</td></tr>",
              "</table>",
              "<p>A position byte is a cell of the floor and a level: bits 0-2 the U cell and "
              "bits 3-5 the V cell of an 8 by 8 grid, bits 6-7 the level. The builder makes U = "
              "72 + 16 times the U cell, V likewise, and Z = the floor's height + 12 times the "
              "level. Scenery carries its own coordinates, so a scenery template always stands "
              "in the same place in a room.</p>",
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
               if sorted(exits_of[r["number"]]) == (["N", "S"] if r["size"] == 1 else ["E", "W"]))
    lines += ["</table>",
              f"<p>{ends} of the {len(narrow)} narrow rooms are corridors with a doorway at "
              "each end and none in the long walls.</p>",
              "<h3>Every room</h3>",
              "<p>Each drawn by the game as it is entered at the start of a game: the quest "
              "items are in their rooms, the collectables (which start in random places) are "
              "left out, and so is the player. Positions are cells (U, V, level).</p>"]

    def graphic_thumb(graphic: int) -> str:
        sprite = graphic_sprite.get(graphic)
        if sprite in pictured:
            return (f'<img class="kl-thumb" src="images/sprites/{pd.sprite_picture_name(sprite)}" '
                    f'alt="graphic {graphic}">')
        return ""

    for record in records:
        number = record["number"]
        size = sizes[record["size"]]
        gx, gy = layout["grid"][number]
        where = f"square ({gx}, {gy}) from room {records[0]['number']}'s"
        if number in layout["sharing"]:
            where += (f", which is also room {_room_link(layout['sharing'][number])}'s: drawn "
                      "aside on the map")
        notes = []
        if number in starts:
            notes.append("a game can start here")
        if number in marked["well"]:
            notes.append("the well is here")
        if number in quest_rooms:
            notes.append(f"quest item {quest_rooms.index(number)} is here")
        if number in piece_rooms:
            notes.append("the pentagram appears here")
        if number in spots_by_room:
            notes.append("a collectable can start here (place "
                         + ", ".join(f"{i} at U {spots[i][1]}, V {spots[i][2]}, Z {spots[i][3]}"
                                     for i in spots_by_room[number]) + ")")
        scenery = []
        for part, template, destination in record["scenery"]:
            text = f'<a href="Scenery.html#scenery{template}">scenery {template}</a>'
            if template in doorways:
                side = doorways[template]["side"]
                how = walks[(number, side)]["how"]
                text += (f": {'a raised' if doorways[template]['raised'] else 'a'} doorway "
                         f"{SIDE_NAMES[side]} to {_room_link(destination)}")
                if how == "jump":
                    text += " (a jump needed to get through it)"
                elif how == "no":
                    text += " (not walked through)"
            scenery.append(text)
        groups = []
        for _, template, count, positions in record["groups"]:
            if template == 31:
                groups.append("a switch to the second page of templates")
                continue
            graphic = memory[_word(memory, pd.OBJECT_TABLE + 2 * template)]
            text = (f'{graphic_thumb(graphic)}<a href="Templates.html#object{template}">'
                    f"template {template}</a> (graphic {graphic})")
            text += (f" x{len(positions)}" if len(positions) > 1 else "") + " at "
            text += ", ".join(_cell(p) for p in positions)
            if len(positions) < count:
                text += f" (the header says {count}; the byte count runs out first)"
            groups.append(text)
        deadly = deadly_graphics[number]
        lines += [f'<div class="kl-item" id="room{number}">',
                  f'<img class="kl-scene" src="images/world/room{number}.png" '
                  f'alt="Room {number}">',
                  f"<p><b>Room {number}</b> -- {ref(record['address'], 'its record')}: "
                  f"{SIZE_WORDS.get(record['size'], '')}, {2 * size[0]} by {2 * size[1]}, "
                  f"{pd.INKS[record['ink']]}; {where}."
                  + (" " + "; ".join(notes)[0].upper() + "; ".join(notes)[1:] + "." if notes else "")
                  + "</p>",
                  "<p>Scenery: " + ("; ".join(scenery) or "none") + ".</p>",
                  '<p class="pg-room-objects">Objects: ' + ("; ".join(groups) or "none") + ".</p>"]
        if deadly:
            lines.append(f"<p>Deadly after a turn: graphic{'s' if len(deadly) > 1 else ''} "
                         f"{_numbers(deadly)}.</p>")
        if number == pentagram_room:
            lines += [f'<img class="kl-scene" src="images/world/room{number}_pentagram.png" '
                      f'alt="Room {number} with the pentagram">',
                      "<p>The same room drawn again with the flag that all four quest items are "
                      "done set: the game brings in the eight pieces of the pentagram, where the "
                      "five collectables are to be brought.</p>"]
        lines.append("</div>")
    lines.append("</div>")

    log(f"  {len(records)} rooms, {len(exits)} doorways ({len(raised)} raised), "
        f"{len(layout['groups'])} group(s) drawn aside; walked through "
        f"{len(through)} of {len(exits)}; deadly graphics {_numbers(deadly_all)}")
    return {"RoomStructure": "\n".join(lines)}
