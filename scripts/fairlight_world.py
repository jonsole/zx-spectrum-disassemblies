"""Fairlight's castle: the Castle and Rooms pages, drawn from the game at build time.

build_fairlight.py --html calls build(), which draws every one of the 81 rooms
with the game's own code into the HTML directory, lays them out by their doors,
and returns the two pages' sections. Like everything the build writes from the
game, none of it is committed: the pictures are the game's, and so are the
lists of what each room holds.

How the pictures are made. The game is started in SkoolKit's simulator the way
the build's sessions start it (build_fairlight.Machine and _start: through the
loading tune and the title into a new game), and stopped at the first pass of
the main loop: every variable is as a new game has it. From that base, for
each room, the room number goes in ROOM and the game carries on at TELE
($F09B), the way a new game (and the thing that carries the knight off) enters
a room -- a fresh base each time, so nothing one room did (a wraith's or a
troll's frames turned round in place, which EEN would turn back) is carried
into the next. At ROOMST ($FD20) the knight's sprite is taken away, so that he
is not in the picture and his update is skipped; then the game runs on to the
second pass of its main loop, by when it has drawn the room, drawn its still
things into the background, drawn every other object once where it stands and
coloured the screen (#R$FE47). The screen is read out of screen memory. Rooms
1, 79 and 81, which the game only ever draws as backdrops (GAME OVER, the
title, the end of the quest), are drawn by calling DRAW_CURRENT_ROOM ($E55B)
and ATTRI ($F0FB), as #R$F065 and #R$FD20 do, with nothing printed over them.

The map. A door's record says which room it leads to and where the knight
arrives there, so from room 29 outwards every room's place relative to its
neighbours can be worked out -- and the loops do not close: the same room is
put in different places by different routes, by up to hundreds of units. So no
single picture of the castle in its own geometry can be honest, and the page
draws a grid instead: every room a tile, placed on the game's own diagonals (a
door out through the back right wall leads to the tile up and to the right),
with the doors drawn between them. The places on the grid are chosen here, by
a search that puts as many rooms as it can next to their neighbours in the
direction their doors say, from a fixed seed so every build draws the same map.

The doors are walked through in the simulator: the knight put in each door and
walked the way it goes (holes in the floor: dropped onto; holes in the
ceiling: stood under on a raised floor and jumped), without the key and then
with it, and where he ends up recorded.
"""
from __future__ import annotations

import math
import random
import re
from pathlib import Path

import fairlight_data as fd

# --------------------------------------------------------------------------
# Addresses (see their entries in the listing).
# --------------------------------------------------------------------------

ROOMST = 0xFD20
LOAD_ROOM = 0xFD9C
START_PASS = 0xFF21         # the main loop's pass begins (the build's MAIN_LOOP)
MAIN_LOOP = 0xFE47
TELE = 0xF09B
TITLE_SCREEN = 0xF065
TITLE_WAIT = 0xF0D8
DRAW_CURRENT_ROOM = 0xE55B
DO_ROOM_COMMAND = 0xE5E8
ATTRI = 0xF0FB
PLACE_ROOM_OBJECTS = 0xEACC
PLACE_OBJECT = 0xEB1A
ISO_MOVE = 0xE4F7
CHE3D = 0xF1E0
CREATURE_UPDATE = 0xF309
PICK_UP = 0xF4F4
SET_THING_ROOM = 0xF4E6
BUMPED = 0xF7C4
ARRIVAL_CHECK = 0xF89E
SAVE_OBJECT_POSITIONS = 0xF906
OBJECTS_MEET = 0xF959
SKIPPED_REMOVAL = 0xFA74
FIND_OBSTACLE = 0xFCA5
DRAW_STILL_THINGS = 0xFE15
SUCCESS_PRINT = 0xFD63      # ROOMST prints "succeeded" from here...
FAILURE_PRINT = 0xFD57      # ...or "failed" from here

FIXED_RECORDS = 0xBC18
KNIGHT = 0xBC90
RECORDS = 0xBCA4
OBJECTS = 0xA924            # the object table while the game runs
TEMPLATES = 0xB734
LARGE_TEMPLATES = 0xB9AA
MASTER_OBJECTS = 0x639C
MASTER_VARIABLES = 0x684C

OBJECT_COUNT = 0xFF80
MESSAGE = 0xFF87
LIFE_TENS = 0xFF95
LIFE_UNITS = 0xFF96
GAME_FLAGS = 0xFF97
SELECTED = 0xFF9E
CARRIED = 0xFF9F
ROOM = 0xFFB4
GAME_STACK = 0x639A
RECORD = 20
FIRST_DOOR_TYPE = 0x46

# Kinds (low nibble of +12) and states (low nibble of +14), as the object code
# reads them (#R$F959, #R$FE47, #R$F1E0, #R$F309).
KIND_DOOR = 1
KIND_PIT = 7
KIND_BOOK = 11
QUEST_THING = 5             # #R$FD20 looks for it among what is carried
ENDING_ROOM = 81
TROLL_STATE = 7
CARRY_OFF_ROOM = 30         # where a kind-9 thing takes the knight (#R$FE47)

KIND_WORDS = {
    0: "nothing when used",
    4: "used: LIFE up 10",
    5: "used: freezes the room's creatures",
    6: "used: LIFE to 99; also destroys a wraith it falls on",
    8: "a lure: the guards that rise from the floor go for it",
    9: "used: carries the knight off to room 30",
    10: "destroys a wraith it falls on or is pushed onto",
    11: "the thing room 61 waits for",
}

# The creatures, by state (+14's low nibble). (key, name, states)
CREATURES = [
    ("guards", "Guards", (6, 9, 10)),
    ("trolls", "Trolls", (7,)),
    ("wraiths", "Wraiths", (11, 15)),
    ("ghosts", "Ghosts", (13,)),
    ("strikers", "Strikers", (4,)),
    ("bouncers", "Bouncing things", (3,)),
    ("flames", "Flames and flickers", (12, 14)),
]
STATE_WORDS = {
    3: "bounces about, hurting what it touches",
    4: "strikes at the knight within its reach",
    6: "a guard: patrols along x, chases within 30",
    7: "the troll: chases, turning its frames to face its way",
    9: "a guard that rises out of the floor, then chases",
    10: "a guard: patrols along y, chases within 30",
    11: "a wraith: chases",
    12: "hangs and flickers (by its picture and its place, a torch's flame)",
    13: "the ghost: wanders, takes things it meets",
    14: "hangs and flickers",
    15: "waits for the book, then a wraith",
}

# The keys that walk each way (the direction bits are #R$F595's): up y is
# Q-T, down y A-G, up x Y-P, down x H-ENTER; SPACE jumps.
WALK_KEYS = {0x40: "q", 0x80: "a", 0x08: "y", 0x04: "h"}
JUMP_KEY = "SPACE"
WAY_WORDS = {0x08: "back right (up x)", 0x04: "front left (down x)",
             0x40: "back left (up y)", 0x80: "front right (down y)",
             0x10: "up, a hole in the ceiling", 0x20: "down, a hole in the floor"}
WAY_SHORT = {0x08: "up x", 0x04: "down x", 0x40: "up y", 0x80: "down y", 0x10: "up",
             0x20: "down"}
# On the grid: the neighbour a door leads to, in (column, row) steps along x
# and y; a hole goes straight up or down the page.
WAY_STEP = {0x08: (1, 0), 0x04: (-1, 0), 0x40: (0, 1), 0x80: (0, -1), 0x10: (1, 1),
            0x20: (-1, -1)}

VERDICT_WORDS = {"failure": "printed FAILED", "success": "printed SUCCEDED, as the game spells it",
                 "neither": "reached neither print", "not carried": "the thing was not picked up"}
KNIGHT_SIZE = (8, 28, 8)    # +9 to +11 of his record (#R$BC90)
TSTATES = 3500000
SENTINEL = 0x5B00           # a return address the calls stop at
CALL_STACK = 0x6398

# The map: tiles of a room's screen at half size, on a diagonal grid.
TILE_W, TILE_H = 128, 96
GAP = 30
MARGIN = 24
LAYOUT_SEED = 1
LAYOUT_STEPS = 400000
LAYOUT_PULL = 0.1
GROUND = (7, 7, 28)         # aticatac.css's page colour

INKS = [(0, 0, 0), (0, 0, 0xD7), (0xD7, 0, 0), (0xD7, 0, 0xD7), (0, 0xD7, 0), (0, 0xD7, 0xD7),
        (0xD7, 0xD7, 0), (0xD7, 0xD7, 0xD7)]
BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF), (0, 0xFF, 0), (0, 0xFF, 0xFF),
          (0xFF, 0xFF, 0), (0xFF, 0xFF, 0xFF)]

# The layers: (key, what, colour, shown at first). "doors" is the links drawn
# between the tiles; the rest put a marker on a room's tile, in a slot of its
# own so that several on one room sit side by side.
LAYERS = [
    ("doors", "Doors, and the keys they need", (240, 240, 240), True),
    ("start", "Where a game starts", (60, 220, 60), True),
    ("quest", "The quest", (230, 60, 230), True),
    ("keys", "Where the keys lie", (240, 220, 40), False),
    ("things", "Other things to pick up", (255, 190, 120), False),
    ("guards", "Guards", (240, 50, 50), False),
    ("trolls", "Trolls", (200, 120, 60), False),
    ("wraiths", "Wraiths", (150, 150, 255), False),
    ("ghosts", "Ghosts", (200, 200, 200), False),
    ("strikers", "Strikers", (255, 90, 160), False),
    ("bouncers", "Bouncing things", (60, 220, 230), False),
    ("flames", "Flames and flickers", (255, 140, 0), False),
    ("pits", "Pits", (120, 60, 20), False),
    ("bug", "The room 19 bug", (255, 255, 255), False),
]
MARKER_R = 8
MARKER_STEP = 20
MARKERS_PER_ROW = 5
SUPERSAMPLE = 3

# The CSS the pages need, for fairlight.css (the lead adds it). The boxes are
# the map's earlier siblings, so a selector reaches the overlays with no script,
# as Knight Lore's castle map does.
LAYER_CSS = "\n".join(
    # "div.kl-castle img.fl-layer": knightlore.css's "div.kl-castle img" sets
    # display: block, and a bare "img.fl-layer" is too weak to hide them.
    ["div.kl-castle img.fl-layer { position: absolute; left: 0; top: 0; pointer-events: none; "
     "display: none; }",
     ",\n".join(f"#fl-layer-{key}:checked ~ div.kl-castle img.fl-layer-{key}"
                for key, *_ in LAYERS) + " { display: block; }"]
    + [f"span.fl-key-{key} {{ background-color: rgb{colour}; }}" for key, _, colour, _ in LAYERS]
    + ["span.fl-key-doors { border-radius: 0; height: 0.25em; vertical-align: 0.2em; }",
       "ul.fl-room-list { margin-top: 0; }",
       "ul.fl-room-list img.kl-thumb { max-height: 40px; vertical-align: middle; "
       "margin-right: 0.4em; }",
       ])


def _word(memory, address: int) -> int:
    return memory[address] | memory[address + 1] << 8


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


def _plural(count: int, word: str, plural: str | None = None) -> str:
    return f"{count} {word if count == 1 else (plural or word + 's')}"


def _room_link(number: int) -> str:
    return f'<a href="Rooms.html#room{number}">{number}</a>'


def _rooms(numbers) -> str:
    return ", ".join(_room_link(n) for n in sorted(set(numbers))) or "none"


def _way_bits(direction: int) -> int:
    for bit in (0x08, 0x04, 0x40, 0x80, 0x10, 0x20):
        if direction & bit:
            return bit
    return 0


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
# The object table, read from the tape's copy.
# --------------------------------------------------------------------------

def table_entries(memory) -> list[dict]:
    """The object table (#R$C4E0 on the tape, #R$A924 while the game runs),
    entry by entry, numbered from 1 as #R$EACC numbers them."""
    out = []
    small = fd.tape_address(TEMPLATES)
    large = fd.tape_address(LARGE_TEMPLATES)
    for number, (address, length, room, kind) in enumerate(fd.object_records(memory), 1):
        entry = {"number": number, "address": address, "runtime": address - fd.OBJECTS_TAPE
                 + OBJECTS, "room": room, "type": kind}
        if length == 6:
            template = small + 11 * kind
            entry.update(door=False, kind=memory[address + 2],
                         place=tuple(memory[address + 3:address + 6]),
                         sprite=_word(memory, template + 4), width=memory[template + 2],
                         height=memory[template + 3], state=memory[template + 9] & 15)
        else:
            template = large + 9 * (kind - FIRST_DOOR_TYPE)
            entry.update(door=True, place=tuple(memory[address + 2:address + 5]),
                         to=memory[address + 5], key=memory[address + 6],
                         arrive=(memory[address + 7], memory[address + 8], memory[address + 10]),
                         way=memory[address + 9], sizes=tuple(memory[template + 6:template + 9]),
                         sprite=_word(memory, template + 4))
        out.append(entry)
    return out


# --------------------------------------------------------------------------
# The game, ready to enter rooms.
# --------------------------------------------------------------------------

class Castle:
    """The game in the simulator, stopped at the first pass of a new game's
    main loop, as the base every picture and every walk starts from."""

    def __init__(self, snapshot: Path):
        import build_fairlight as bf

        self.bf = bf
        self.machine = bf.Machine(snapshot)
        self.machine.play(bf._start(), "the castle's start")
        self.simulator = self.machine.simulator
        self.base = bytes(self.simulator.memory)
        self.base_registers = list(self.simulator.registers)
        self.base_pc = self.machine.pc

    @property
    def memory(self):
        return self.simulator.memory

    def reset(self) -> None:
        self.simulator.memory[:] = self.base
        for index, value in enumerate(self.base_registers):
            self.simulator.registers[index] = value
        self.machine.pc = self.base_pc

    def run_to(self, address: int, seconds: float = 20.0, keys=()) -> bool:
        """Run until the game reaches `address` (at least one instruction on),
        or give up: True if it got there."""
        self.machine.run(seconds, keys, stop=address)
        return self.machine.pc == address

    def enter(self, room: int, hide_knight: bool = True, before=None) -> bool:
        """Into `room` the way a new game goes into its first: ROOM set and on
        at TELE with the stack it has there. `before(memory)` may change the
        game first (the object table, say). With `hide_knight` his sprite is
        taken away at ROOMST, after TELE has reset his record. Stops at the
        start of the second pass of the main loop, the room drawn, coloured,
        and everything in it drawn once; False if it never got there."""
        from skoolkit.simutils import SP

        self.reset()
        memory = self.memory
        if before is not None:
            before(memory)
        memory[ROOM] = room
        self.simulator.registers[SP] = GAME_STACK
        self.machine.pc = TELE
        if not self.run_to(ROOMST):
            return False
        if hide_knight:
            memory[KNIGHT + 4] = memory[KNIGHT + 5] = 0
        return self.run_to(START_PASS) and self.run_to(START_PASS)

    def title(self) -> bool:
        """The title page: room 79 drawn, coloured and printed over by the
        game's own title routine (#R$F065), stopped at its wait for a key."""
        from skoolkit.simutils import SP

        self.reset()
        self.simulator.registers[SP] = GAME_STACK
        self.machine.pc = TITLE_SCREEN
        return self.run_to(TITLE_WAIT)

    def game_over(self) -> bool:
        """GAME OVER over room 1: LIFE put to nought at the start of a pass,
        so that the main loop ends the game (#R$FE47), stopped at the wait."""
        self.reset()
        self.memory[LIFE_TENS] = self.memory[LIFE_UNITS] = 0
        return self.run_to(TITLE_WAIT)

    def ending(self, carrying: bool) -> str:
        """Room 81 entered through TELE from room 29, with thing 5 carried
        (laid in room 29 and picked up first) or with nothing: which verdict
        #R$FD20 prints. The screen is left at the wait for a key after it."""
        from skoolkit.simutils import SP

        def lay(memory):
            if carrying:
                base = OBJECTS + 6 * (QUEST_THING - 1)
                memory[base] = 29
                memory[base + 3], memory[base + 4], memory[base + 5] = 100, 60, 100

        self.enter(29, hide_knight=False, before=lay)
        if carrying and not self.carry(QUEST_THING):
            return "not carried"
        self.memory[ROOM] = ENDING_ROOM
        self.simulator.registers[SP] = GAME_STACK
        self.machine.pc = TELE
        self.machine.run(10.0, [], stop=SUCCESS_PRINT if carrying else FAILURE_PRINT)
        verdict = "neither"
        if self.machine.pc == SUCCESS_PRINT:
            verdict = "success"
        elif self.machine.pc == FAILURE_PRINT:
            verdict = "failure"
        self.run_to(TITLE_WAIT)
        return verdict

    def records(self) -> list[list[int]]:
        """The object records in use from the knight's (the seventh) on."""
        memory = self.memory
        return [list(memory[KNIGHT + RECORD * index:KNIGHT + RECORD * (index + 1)])
                for index in range(memory[OBJECT_COUNT] - 6)]

    def fixed(self) -> list[list[int]]:
        memory = self.memory
        return [list(memory[FIXED_RECORDS + RECORD * index:FIXED_RECORDS + RECORD * (index + 1)])
                for index in range(6)]

    def screen(self):
        memory = self.memory
        return screen_image(bytes(memory[0x4000:0x5800]), bytes(memory[0x5800:0x5B00]))

    # ----------------------------------------------------------------------
    # Walking through doors.
    # ----------------------------------------------------------------------

    def _alive(self) -> None:
        self.memory[LIFE_TENS] = self.memory[LIFE_UNITS] = 9

    def _hold(self, keys, seconds: float, room: int, watch: dict) -> None:
        """Hold keys a twentieth of a second at a time, LIFE kept up, until
        the room changes or the time is up; note any message shown."""
        waited = 0.0
        while waited < seconds:
            self._alive()
            self.machine.run(0.02, keys)
            waited += 0.02
            watch["message"] = max(watch.get("message", 0), self.memory[MESSAGE])
            if self.memory[ROOM] != room or self.machine.pc == TITLE_WAIT:
                return

    def carry(self, number: int) -> bool:
        """The object table's thing `number`, lying in the room, picked up the
        game's own way (X) with the knight stood on it, into the place in
        use. True if it is carried."""
        bf = self.bf
        memory = self.memory
        record = None
        for index in range(1, memory[OBJECT_COUNT] - 6):
            address = KNIGHT + RECORD * index
            if memory[address + 0x13] == number and memory[address + 12] & 0x20:
                record = address
                break
        if record is None:
            return False
        # Anything else that can be picked up is hidden a moment (bit 5 of
        # +16), so that the search (#R$F4F4) cannot find it first.
        others = []
        for index in range(1, memory[OBJECT_COUNT] - 6):
            address = KNIGHT + RECORD * index
            if address != record and memory[address + 12] & 0x20                     and not memory[address + 16] & 0x20:
                memory[address + 16] |= 0x20
                others.append(address)
        self._alive()
        bf._onto_knight(record)(memory)
        self.machine.run(0.3, ["x"])
        self.machine.run(0.3, [])
        for address in others:
            memory[address + 16] &= ~0x20 & 0xFF
        # On to the start of a pass, where nothing holds a working copy of
        # a record that would be written back over what is changed next.
        self.run_to(START_PASS)
        return any(_word(memory, CARRIED + 2 * slot) == record for slot in range(5))

    def walk_door(self, room: int, door: dict, key: int = 0, record_place=None,
                  lay: tuple = (), clear: bool = False) -> dict:
        """Put the knight in `door` of `room` and go the way it goes: walk into
        a doorway, drop onto a hole in the floor, jump into a hole in the
        ceiling from a floor raised to just under it. With `key`, that thing
        is first put in the room and picked up. Returns where he ended up and
        the message the game showed, if any."""
        def lay_key(memory):
            for number in ((key,) if key else ()) + tuple(lay):
                base = OBJECTS + 6 * (number - 1)
                memory[base] = room
                memory[base + 3], memory[base + 4], memory[base + 5] = 100, 60, 100

        if not self.enter(room, hide_knight=False, before=lay_key):
            return {"outcome": "not entered"}
        memory = self.memory
        if key and not self.carry(key):
            return {"outcome": "key not picked up"}
        records = self.records()
        match = None
        for index, record in enumerate(records):
            if record[12] & 15 == KIND_DOOR and tuple(record[6:9]) == (record_place
                                                                       or door["place"]):
                match = KNIGHT + RECORD * index
        if match is None:
            return {"outcome": "no such door"}
        # Where to stand is worked out from the door as the table has it,
        # which is where the room's picture shows it.
        x, top, y = door["place"]
        width, height, depth = door["sizes"]
        kw, kh, kd = KNIGHT_SIZE
        way = _way_bits(door["way"])
        watch: dict = {}
        tries = []
        box = room_box(self.fixed())

        def spots(start, span, walls, size):
            """Three places along the part of the door's span inside the room
            -- the big arches reach past the walls -- for the knight's near
            corner: at each end and in the middle. Something standing in part
            of a doorway, or lying where he would arrive, spoils only some."""
            low, high = max(start, walls[0]), min(start + span, walls[1])
            if high - low < size:
                low, high = start, start + span
            room_for = max(0, high - low - size)
            return sorted({low + 1 if room_for > 1 else low, low + room_for // 2,
                           low + max(0, room_for - 1)})

        def overlaps(start, span, size):
            """Five places for the knight's near corner at which he still
            overlaps a hole: a hole is small, and the furniture round one (a
            table over it, the table's legs) leaves only parts of it open."""
            low, high = start - size + 1, start + span - 1
            return sorted({low + (high - low) * i // 4 for i in range(5)})

        xs = spots(x, width, box["x"], kw)
        ys = spots(y, depth, box["y"], kd)
        if way in (0x10, 0x20):
            xs = overlaps(x, width, kw)
            ys = overlaps(y, depth, kd)
        if way in (0x40, 0x80, 0x08, 0x04):
            # Just outside the doorway, touching it, wholly within its width
            # (or depth), his feet on its foot or a little above: his first
            # step, two units, takes him into the door and no further, so it
            # is the door he meets and not what stands beyond it.
            feet = top - height
            if way == 0x40:
                places = [(along, y - kd) for along in xs]
            elif way == 0x80:
                places = [(along, y + depth) for along in xs]
            elif way == 0x08:
                places = [(x - kw, along) for along in ys]
            else:
                places = [(x + width, along) for along in ys]
            for lift in (0, 2, 4):
                for place in places:
                    tries.append((place, feet + lift + kh, [WALK_KEYS[way]], None))
        elif way == 0x20:
            for along_x in xs:
                for along_y in ys:
                    tries.append(((along_x, along_y), top + kh + 2, [], None))
        else:
            floor = top - height - kh - 2
            for along_x in xs:
                for along_y in ys:
                    tries.append(((along_x, along_y), floor + kh, [JUMP_KEY], floor))
        cleared = []
        if clear:
            # Staged: whatever can be moved and stands over the hole taken out
            # of the room (bit 5 of +16, as a thing that vanishes), as if the
            # knight had pushed it off.
            for index, record in enumerate(self.records()):
                if index and record[12] & 15 != KIND_DOOR and record[16] & 31                         and record[6] < x + width and x < record[6] + record[9]                         and record[8] < y + depth and y < record[8] + record[11]:
                    memory[KNIGHT + RECORD * index + 16] |= 0x20
                    cleared.append(record[19])
        snapshot = (bytes(memory), list(self.simulator.registers), self.machine.pc)
        messages = set()
        for (kx, ky), ktop, keys, floor in tries:
            memory[:] = snapshot[0]
            for index, value in enumerate(snapshot[1]):
                self.simulator.registers[index] = value
            self.machine.pc = snapshot[2]
            watch = {}
            if floor is not None:
                # Staged: the room's floor (#R$BC18's first record) raised
                # to just under the hole, so that a jump reaches it.
                memory[FIXED_RECORDS + 7] = floor
            memory[KNIGHT + 6], memory[KNIGHT + 7], memory[KNIGHT + 8] = kx, ktop, ky
            self._hold(keys, 1.5, room, watch)
            if watch.get("message"):
                messages.add(watch["message"])
            if self.machine.pc == TITLE_WAIT or memory[ROOM] != room:
                break
        outcome = {"outcome": "stayed"}
        if self.machine.pc == TITLE_WAIT or (door["to"] == 0 and memory[ROOM] == 1):
            outcome = {"outcome": "game over", "room": memory[ROOM]}
        elif memory[ROOM] != room:
            outcome = {"outcome": "through", "room": memory[ROOM],
                       "arrived": (memory[KNIGHT + 6], memory[KNIGHT + 7], memory[KNIGHT + 8])}
        outcome["messages"] = sorted(messages)
        outcome["cleared"] = cleared
        outcome["message"] = max(messages, default=0)
        return outcome


def screen_image(bitmap: bytes, attributes: bytes):
    """The Spectrum's screen as a picture."""
    from PIL import Image

    image = Image.new("RGB", (256, 192))
    pixels = image.load()
    for y in range(192):
        base = (y & 0xC0) << 5 | (y & 7) << 8 | (y & 0x38) << 2
        for column in range(32):
            byte = bitmap[base + column]
            attribute = attributes[(y >> 3) * 32 + column]
            palette = BRIGHT if attribute & 0x40 else INKS
            ink, paper = palette[attribute & 7], palette[attribute >> 3 & 7]
            for bit in range(8):
                pixels[column * 8 + bit, y] = ink if byte & (0x80 >> bit) else paper
    return image


# --------------------------------------------------------------------------
# The doors' geometry: where each room lies relative to its neighbours.
# --------------------------------------------------------------------------

def room_box(fixed) -> dict:
    """The room's box from its six fixed records (#R$BC18): the floor's top,
    the ceiling's underside, and the inner faces of the four walls."""
    xs = sorted((fixed[2][6], fixed[3][6]))
    ys = sorted((fixed[4][8], fixed[5][8]))
    return {"x": (xs[0] + 10, xs[1]), "y": (ys[0] + 10, ys[1]), "floor": fixed[0][7],
            "ceiling": fixed[1][7] - 10}


def door_offset(door: dict, boxes: dict):
    """Where the room behind `door` lies relative to its own room, from the
    arithmetic of #R$F7C4's arrival: along the doorway, the knight's place is
    carried across exactly (the door's corner goes to the arrival point); across
    it, the door's face goes to the arrival point; through a hole, x and y are
    carried across, and the height is taken to be the one room's floor at the
    other's ceiling, since he arrives in the air. None where a room's box is
    not known."""
    x, top, y = door["place"]
    ax, atop, ay = door["arrive"]
    width, height, depth = door["sizes"]
    way = _way_bits(door["way"])
    if way in (0x10, 0x20):
        here, there = boxes.get(door["room"]), boxes.get(door["to"])
        if here is None or there is None:
            return None
        rise = (here["floor"] - there["ceiling"] if way == 0x20
                else here["ceiling"] - there["floor"])
        return (x - ax, y - ay, rise)
    if way in (0x40, 0x80):
        return (x - ax, y + (depth if way == 0x80 else 0) - ay, top - atop)
    return (x + (width if way == 0x04 else 0) - ax, y - ay, top - atop)


def check_geometry(doors, boxes, start: int):
    """Place every room by the doors from `start` outwards, first route first,
    and then see what every door says: (placed, disagreements), each
    disagreement (room, room behind, by how much)."""
    origin = {start: (0, 0, 0)}
    order = [start]
    index = 0
    while index < len(order):
        room = order[index]
        index += 1
        for door in doors:
            if door["room"] != room:
                continue
            offset = door_offset(door, boxes)
            if offset is None or door["to"] in origin:
                continue
            origin[door["to"]] = tuple(origin[room][k] + offset[k] for k in range(3))
            order.append(door["to"])
    disagree = []
    for door in doors:
        offset = door_offset(door, boxes)
        if offset is None or door["room"] not in origin or door["to"] not in origin:
            continue
        miss = [origin[door["room"]][k] + offset[k] - origin[door["to"]][k] for k in range(3)]
        if max(abs(v) for v in miss) > 12:
            disagree.append((door["room"], door["to"], max(abs(v) for v in miss)))
    return origin, disagree


# --------------------------------------------------------------------------
# The grid.
# --------------------------------------------------------------------------

def lay_out(rooms, links, start: int, seed: int = LAYOUT_SEED) -> dict:
    """A place (column, row) for every room: first each room next to the room
    it is first reached from, in the direction the door says (or the nearest
    free place); then a search that moves and swaps rooms to put as many as it
    can next to their neighbours the way their doors say, from a fixed seed."""
    place = {start: (0, 0)}
    used = {(0, 0): start}
    queue = [start]
    while queue:
        room = queue.pop(0)
        for a, b, step in links:
            if a != room or b in place:
                continue
            px, py = place[room]
            want = (px + step[0], py + step[1])
            spot = None
            for radius in range(0, 12):
                ring = [(want[0] + dx, want[1] + dy) for dx in range(-radius, radius + 1)
                        for dy in range(-radius, radius + 1)
                        if max(abs(dx), abs(dy)) == radius
                        and (want[0] + dx, want[1] + dy) not in used]
                if ring:
                    spot = min(ring, key=lambda c: (abs(c[0] - want[0]) + abs(c[1] - want[1]), c))
                    break
            place[b] = spot
            used[spot] = b
            queue.append(b)
    for room in rooms:
        if room not in place:
            raise RuntimeError(f"room {room} has no door to it from room {start}")
    by_room: dict[int, list[int]] = {}
    for index, (a, b, _) in enumerate(links):
        by_room.setdefault(a, []).append(index)
        by_room.setdefault(b, []).append(index)

    def cost(index):
        a, b, step = links[index]
        return (abs(place[a][0] + step[0] - place[b][0])
                + abs(place[a][1] + step[1] - place[b][1]))

    # A little pull towards the middle, so that the map stays compact.
    middle_c = sum(c for c, _ in place.values()) / len(place)
    middle_r = sum(r for _, r in place.values()) / len(place)

    def pull(room):
        c, r = place[room]
        return LAYOUT_PULL * (abs(c - middle_c) + abs(r - middle_r))

    rng = random.Random(seed)
    order = sorted(place)
    for turn in range(LAYOUT_STEPS):
        heat = 3.0 * (1 - turn / LAYOUT_STEPS) + 0.01
        room = rng.choice(order)
        here = place[room]
        there = (here[0] + rng.randint(-3, 3), here[1] + rng.randint(-3, 3))
        if there == here:
            continue
        other = used.get(there)
        touched = set(by_room.get(room, []))
        if other is not None:
            touched |= set(by_room.get(other, []))
        movers = (room,) if other is None else (room, other)
        before = sum(cost(i) for i in touched) + sum(pull(m) for m in movers)
        place[room] = there
        if other is not None:
            place[other] = here
        change = sum(cost(i) for i in touched) + sum(pull(m) for m in movers) - before
        if change <= 0 or rng.random() < math.exp(-change / heat):
            used[there] = room
            if other is not None:
                used[here] = other
            else:
                del used[here]
        else:
            place[room] = here
            if other is not None:
                place[other] = there
    return place


def link_ok(place, a, b, step) -> bool:
    return (place[a][0] + step[0], place[a][1] + step[1]) == place[b]


def tile_origins(place) -> tuple[dict, tuple]:
    """Each room's tile's top-left on the map: column c and row r go to the
    diagonals u = c - r and v = c + r, so that up x is up and to the right
    and up y up and to the left, as on the game's screen."""
    us = [c - r for c, r in place.values()]
    vs = [c + r for c, r in place.values()]
    # Neighbours on a diagonal differ by one in u and one in v: half a tile
    # and a gap across, and a whole tile and a gap down, so they never meet.
    step_x = (TILE_W + GAP) / 2
    step_y = TILE_H + GAP
    out = {}
    for room, (c, r) in place.items():
        out[room] = (round(MARGIN + (c - r - min(us)) * step_x),
                     round(MARGIN + (max(vs) - (c + r)) * step_y))
    width = round(2 * MARGIN + (max(us) - min(us)) * step_x + TILE_W)
    height = round(2 * MARGIN + (max(vs) - min(vs)) * step_y + TILE_H)
    return out, (width, height)


def _font(size: int):
    from PIL import ImageFont

    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


def _clip(p, q, box):
    """The point where the segment from p (inside box) to q leaves box."""
    (x0, y0), (x1, y1) = p, q
    left, top, right, bottom = box
    t = 1.0
    for edge, delta, start in ((left, x1 - x0, x0), (right, x1 - x0, x0),
                               (top, y1 - y0, y0), (bottom, y1 - y0, y0)):
        if delta:
            s = (edge - start) / delta
            if 0 < s < t:
                point = (x0 + s * (x1 - x0), y0 + s * (y1 - y0))
                if left - 0.5 <= point[0] <= right + 0.5 and top - 0.5 <= point[1] <= bottom + 0.5:
                    t = s
    return (x0 + t * (x1 - x0), y0 + t * (y1 - y0))


# --------------------------------------------------------------------------
# The pages.
# --------------------------------------------------------------------------

def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:

    from build_fairlight import game_memory

    memory = game_memory(snapshot)
    ref = Refs(snapshot.with_name("fairlight.skool"))
    image_dir = html_dir / "images" / "world"
    image_dir.mkdir(parents=True, exist_ok=True)

    entries = table_entries(memory)
    things = [e for e in entries if not e["door"] and e["number"] < 256]
    table_doors = [e for e in entries if e["door"]]
    start_room = memory[ROOM]       # the tape's variables, which START copies to the master
    room_records = fd._stream_records(memory, fd.ROOMS, fd.ROOM_COUNT)

    log("  starting a game, and drawing every room with the game's own code...")
    castle = Castle(snapshot)
    if castle.memory[ROOM] != start_room:
        raise RuntimeError(f"a new game began in room {castle.memory[ROOM]}, not {start_room}")
    rooms: dict[int, dict] = {}
    backdrops = (1, 79, ENDING_ROOM)
    for room in range(1, fd.ROOM_COUNT + 1):
        if room in backdrops:
            # Drawn only as the backdrops they are, with what the game prints
            # over them: GAME OVER, the title page, the verdict of a quest
            # done.
            if room == 1:
                shown = castle.game_over()
            elif room == 79:
                shown = castle.title()
            else:
                shown = castle.ending(True) == "success"
            if not shown or (room != 79 and castle.memory[ROOM] != room):
                raise RuntimeError(f"room {room}'s screen was not reached")
            info = {"records": [], "fixed": None, "box": None}
        else:
            if not castle.enter(room):
                raise RuntimeError(f"room {room} was never entered")
            if castle.memory[ROOM] != room:
                raise RuntimeError(f"entering room {room} ended in room {castle.memory[ROOM]}")
            info = {"records": castle.records(), "fixed": castle.fixed()}
            info["box"] = room_box(info["fixed"])
        info["colour"] = castle.memory[0xFF8E]
        picture = castle.screen()
        picture.save(image_dir / f"room{room:02d}.png")
        info["picture"] = picture
        rooms[room] = info

    # The doors, as the rooms built them, checked against the table.
    doors = []
    for room in sorted(rooms):
        for record in rooms[room]["records"][1:]:
            if record[12] & 15 != KIND_DOOR:
                continue
            door = {"room": room, "place": tuple(record[6:9]), "sizes": tuple(record[9:12]),
                    "to": record[13], "key": record[14], "arrive": (record[15], record[16],
                                                                    record[18]),
                    "way": record[17]}
            doors.append(door)
    table_set = sorted((e["room"], e["place"], e["to"], e["key"], e["way"]) for e in table_doors)
    built_set = sorted((d["room"], d["place"], d["to"], d["key"], d["way"]) for d in doors)
    if table_set != built_set:
        raise RuntimeError("the rooms' door records are not the object table's doors")
    for door in doors:
        entry = next(e for e in table_doors if e["room"] == door["room"]
                     and e["place"] == door["place"])
        door["number"] = entry["number"]
        door["runtime"] = entry["runtime"]
    boxes = {room: info["box"] for room, info in rooms.items() if info["box"]}

    log("  walking through every door in the simulator...")
    book = next(e for e in entries if not e["door"] and e["kind"] & 15 == KIND_BOOK)
    # The room the book is the key into, whose way out waits for it (#R$F7C4).
    waiting = next(d["to"] for d in doors if d["key"] == book["number"])
    for door in doors:
        door["walk"] = castle.walk_door(door["room"], door)
        if door["key"]:
            door["walk_key"] = castle.walk_door(door["room"], door, door["key"])
        if door["walk"]["outcome"] == "stayed" and _way_bits(door["way"]) == 0x20:
            # A hole in the floor with something over it; and room 61's,
            # which waits for the book to lie in the room.
            if door["room"] == waiting:
                door["walk_book"] = castle.walk_door(door["room"], door, lay=(book["number"],))
            else:
                door["walk_clear"] = castle.walk_door(door["room"], door, clear=True)

    log("  measuring the pit in room 10, the room 19 bug and the ending...")
    measured = measure_special(castle, entries, doors)

    # The geometry, and the grid.
    origin, disagree = check_geometry(doors, boxes, start_room)
    links = [(d["room"], d["to"], WAY_STEP[_way_bits(d["way"])]) for d in doors if d["to"]]
    castle_rooms = sorted(set(origin) | {start_room})
    unreached = [room for room in range(1, fd.ROOM_COUNT + 1) if room not in origin]
    log("  laying the rooms out on a grid...")
    place = lay_out(castle_rooms, links, start_room)
    # The rooms no door leads to, in a row below the rest.
    low_c = min(c - r for c, r in place.values())
    bottom = min(c + r for c, r in place.values()) - 2
    for index, room in enumerate(unreached):
        u, v = low_c + 2 * index, bottom
        if (u + v) % 2:
            u += 1
        place[room] = ((u + v) // 2, (v - u) // 2)
    adjacent = sum(1 for a, b, step in links if link_ok(place, a, b, step))
    origins, size = tile_origins(place)

    log("  drawing the map and its layers...")
    # Things in the table, by room; creatures and the rest, by the records.
    thing_rooms: dict[int, list[dict]] = {}
    for entry in things:
        thing_rooms.setdefault(entry["room"], []).append(entry)
    keys_used = sorted({d["key"] for d in doors if d["key"]})
    creatures: dict[str, dict[int, list]] = {key: {} for key, _, _ in CREATURES}
    for room, info in rooms.items():
        for record in info["records"][1:]:
            if record[12] & 15 == KIND_DOOR or not (record[4] or record[5]):
                continue
            state = record[14] & 15
            for key, _, states in CREATURES:
                if state in states and record[16] & 31:
                    creatures[key].setdefault(room, []).append(record)
    pits = sorted(room for room, info in rooms.items()
                  if any(r[12] & 15 == KIND_PIT for r in info["records"][1:]))
    trapdoors = [d for d in doors if d["to"] == 0]
    quest = quest_chain(doors, entries, start_room)

    marked = {"start": {start_room: ["S"]}, "keys": {}, "things": {}, "quest": {}, "pits": {},
              "bug": {}}
    for entry in things:
        if entry["number"] in keys_used:
            marked["keys"].setdefault(entry["room"], []).append(str(entry["number"]))
        elif entry["kind"] & 0x20:
            marked["things"].setdefault(entry["room"], []).append("")
    for room, labels in marked["things"].items():
        marked["things"][room] = [str(len(labels))]
    for key, _, _ in CREATURES:
        marked[key] = {room: [str(len(records))] for room, records in creatures[key].items()}
    for room, label in quest["marks"].items():
        marked["quest"][room] = [label]
    for room in pits:
        marked["pits"][room] = ["P"]
    for door in trapdoors:
        marked["pits"][door["room"]] = ["P"]
    marked["bug"] = {19: ["19"], 25: ["!"], 21: ["!"]}

    whole = draw_map(rooms, place, origins, size, doors, links)
    whole.save(image_dir / "castle.png", optimize=True)
    slot_of = {key: index for index, (key, *_) in enumerate(l for l in LAYERS if l[0] != "doors")}
    for key, what, colour, shown in LAYERS:
        if key == "doors":
            layer = draw_links(size, origins, doors, place)
        else:
            layer = draw_markers(size, origins, marked[key], colour, slot_of[key])
        layer.save(image_dir / f"layer_{key}.png", optimize=True)

    # Thumbnails of the things and creatures, drawn from their own bytes.
    sprites_drawn = set()

    def thumb(address: int, width: int, height: int) -> str:
        if not address or not width or not height:
            return ""
        name = f"sprite{address:04x}_{width}x{height}.png"
        if name not in sprites_drawn:
            fd.sprite_image(memory, address, width, height, scale=2).save(image_dir / name)
            sprites_drawn.add(name)
        return f'<img class="kl-thumb" src="images/world/{name}" alt="sprite ${address:04X}">'

    sections = {}
    sections["Castle"] = castle_page(
        memory, ref, rooms, doors, entries, things, keys_used, creatures, pits, trapdoors,
        quest, measured, origin, disagree, links, adjacent, place, size, start_room,
        unreached, marked, thumb)
    sections["Rooms"] = rooms_page(memory, ref, rooms, room_records, doors, entries, things,
                                   creatures, pits, trapdoors, quest, measured, start_room,
                                   keys_used, thumb)
    walked = sum(1 for d in doors if d["walk"].get("outcome") in ("through", "game over"))
    log(f"  {len(rooms)} rooms, {len(doors)} doors ({walked} walked through without a key); "
        f"{adjacent} of {len(links)} doors next to their room on the grid; "
        f"{len(disagree)} doors disagree with the first route's geometry")
    return sections


# --------------------------------------------------------------------------
# Measurements.
# --------------------------------------------------------------------------

def measure_special(castle: Castle, entries, doors) -> dict:
    """The things the Castle page states that need the game run: the ending's
    test, and the room 19 bug."""
    memory = castle.memory
    out = {}
    out["ending_without"] = castle.ending(False)
    out["ending_with"] = castle.ending(True)

    # Room 19: its drawing's things with no number; one picked up.
    door = next((d for d in doors if d["room"] == 25 and d["to"] == 21), None)
    bug = {"door": door}
    if door and castle.enter(19, hide_knight=False):
        records = castle.records()
        unnumbered = [KNIGHT + RECORD * i for i, r in enumerate(records)
                      if i and r[0x13] == 0 and r[12] & 0x20 and r[12] & 15 != KIND_DOOR]
        bug["unnumbered"] = len(unnumbered)
        if unnumbered:
            # Walk him a moment towards up x so that he faces that way, freeze
            # the room's creatures (bit 7 of GAME_FLAGS, what a thing of kind
            # 5 does) so the thing lies still, and put it just ahead of him.
            castle._alive()
            castle.machine.run(0.1, ["y"])
            memory[GAME_FLAGS] |= 0x80
            thing = unnumbered[0]
            memory[thing + 6] = memory[KNIGHT + 6] + 6
            memory[thing + 8] = memory[KNIGHT + 8]
            memory[thing + 7] = (memory[KNIGHT + 7] - memory[KNIGHT + 10]
                                 + memory[thing + 10]) & 0xFF
            bug["before"] = memory[door["runtime"] + 2]
            castle._alive()
            castle.machine.run(0.3, ["x"])
            castle.machine.run(0.3, [])
            bug["carried"] = any(_word(memory, CARRIED + 2 * s) == thing for s in range(5))
            bug["after"] = memory[door["runtime"] + 2]
    if door:
        # The door with the byte the bug writes, walked into from room 25.
        def spoil(mem):
            mem[door["runtime"] + 2] = 0xFE
        bug["walk_spoiled"] = _walk_with(castle, 25, door, spoil,
                                         (0xFE,) + tuple(door["place"][1:]))
    out["bug"] = bug
    return out


def _walk_with(castle: Castle, room: int, door: dict, change, record_place=None) -> dict:
    """walk_door with the object table changed before the room is entered."""
    original = castle.enter

    def enter(number, hide_knight=True, before=None):
        def both(memory):
            change(memory)
            if before is not None:
                before(memory)
        return original(number, hide_knight, both)

    castle.enter = enter
    try:
        return castle.walk_door(room, door, record_place=record_place)
    finally:
        castle.enter = original


def quest_chain(doors, entries, start: int) -> dict:
    """Which rooms can be reached with which keys, round by round: first
    through the doors that need none, then each time with the keys lying in
    the rooms reached so far. A key is a thing's number in the object table
    (#R$F7C4). Room 61's way out also needs the thing of kind 11 lying in
    it, which is the key of the way in, so it is reachable both ways once
    that key is."""
    lying = {e["number"]: e["room"] for e in entries if not e["door"] and e["number"] < 256}
    have: set[int] = set()
    reached = {start}
    rounds = []
    while True:
        changed = True
        while changed:
            changed = False
            for door in doors:
                if door["room"] in reached and door["to"] and door["to"] not in reached \
                        and (not door["key"] or door["key"] in have):
                    reached.add(door["to"])
                    changed = True
        found = sorted(k for k in {d["key"] for d in doors if d["key"]}
                       if k not in have and lying.get(k) in reached)
        rounds.append((sorted(reached), found))
        if not found:
            break
        have |= set(found)
    marks = {}
    marks[lying[QUEST_THING]] = "5"
    marks[ENDING_ROOM] = "E"
    for door in doors:
        if door["to"] == ENDING_ROOM:
            marks[door["room"]] = str(door["key"])
    book = next(e for e in entries if not e["door"] and e["kind"] & 15 == KIND_BOOK)
    marks[book["room"]] = "B"
    marks[61] = "W"
    return {"rounds": rounds, "marks": marks, "book": book, "lying": lying}


# --------------------------------------------------------------------------
# Pictures of the castle.
# --------------------------------------------------------------------------

def draw_map(rooms, place, origins, size, doors, links):
    from PIL import Image, ImageDraw

    image = Image.new("RGB", size, GROUND)
    draw = ImageDraw.Draw(image)
    font = _font(12)
    for room in sorted(place):
        x, y = origins[room]
        tile = rooms[room]["picture"].resize((TILE_W, TILE_H), Image.LANCZOS)
        image.paste(tile, (x, y))
        draw.rectangle((x - 1, y - 1, x + TILE_W, y + TILE_H), outline=(60, 60, 110))
        label = str(room)
        box = draw.textbbox((0, 0), label, font=font)
        draw.rectangle((x, y, x + box[2] + 6, y + box[3] + 4), fill=(0, 0, 0))
        draw.text((x + 3, y + 1), label, fill=(255, 255, 255), font=font)
    return image


def draw_links(size, origins, doors, place):
    """The doors: a line between the two rooms' tiles for each pair of
    rooms with a door between them -- white, yellow with the key's number
    where a door needs one, dashed cyan for a hole, an arrowhead where the
    way goes only one way."""
    from PIL import Image, ImageDraw

    big = SUPERSAMPLE
    image = Image.new("RGBA", (size[0] * big, size[1] * big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    font = _font(11 * big)
    pairs: dict[tuple, list] = {}
    for door in doors:
        if door["to"] and door["to"] in origins:
            pairs.setdefault(tuple(sorted((door["room"], door["to"]))), []).append(door)

    def centre(room):
        x, y = origins[room]
        return (x + TILE_W / 2, y + TILE_H / 2)

    def box(room):
        x, y = origins[room]
        return (x - 1, y - 1, x + TILE_W + 1, y + TILE_H + 1)

    labels = []
    for (a, b), group in sorted(pairs.items()):
        ways = {(d["room"], d["to"]) for d in group}
        hole = all(_way_bits(d["way"]) in (0x10, 0x20) for d in group)
        keys = sorted({d["key"] for d in group if d["key"]})
        colour = (240, 220, 40) if keys else ((60, 220, 230) if hole else (240, 240, 240))
        p = _clip(centre(a), centre(b), box(a))
        q = _clip(centre(b), centre(a), box(b))
        pts = [(p[0] * big, p[1] * big), (q[0] * big, q[1] * big)]
        length = math.dist(*pts)
        if hole:
            dash = 8 * big
            count = max(1, int(length // (2 * dash)))
            for i in range(count + 1):
                s, e = 2 * i * dash / length, min(1.0, (2 * i + 1) * dash / length)
                if s >= 1:
                    break
                draw.line([(pts[0][0] + s * (pts[1][0] - pts[0][0]), pts[0][1] + s * (pts[1][1] - pts[0][1])),
                           (pts[0][0] + e * (pts[1][0] - pts[0][0]), pts[0][1] + e * (pts[1][1] - pts[0][1]))],
                          fill=colour + (255,), width=3 * big)
        else:
            draw.line(pts, fill=(0, 0, 0, 255), width=6 * big)
            draw.line(pts, fill=colour + (255,), width=3 * big)
        for start, end, room in ((pts[0], pts[1], b), (pts[1], pts[0], a)):
            if len(ways) == 1 and (room == b) == ((a, b) in ways):
                angle = math.atan2(end[1] - start[1], end[0] - start[0])
                tip = end
                head = 12 * big
                left = (tip[0] - head * math.cos(angle - 0.45), tip[1] - head * math.sin(angle - 0.45))
                right = (tip[0] - head * math.cos(angle + 0.45), tip[1] - head * math.sin(angle + 0.45))
                draw.polygon([tip, left, right], fill=colour + (255,), outline=(0, 0, 0, 255))
        if keys:
            labels.append((((pts[0][0] + pts[1][0]) / 2, (pts[0][1] + pts[1][1]) / 2),
                           "key " + ",".join(str(k) for k in keys)))
    for (x, y), text in labels:
        bbox = draw.textbbox((0, 0), text, font=font)
        w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
        draw.rectangle((x - w / 2 - 3 * big, y - h / 2 - 3 * big, x + w / 2 + 3 * big,
                        y + h / 2 + 3 * big), fill=(240, 220, 40, 255), outline=(0, 0, 0, 255))
        draw.text((x - w / 2 - bbox[0], y - h / 2 - bbox[1]), text, fill=(0, 0, 0, 255), font=font)
    return image.resize(size, Image.LANCZOS)


def draw_markers(size, origins, marked: dict, colour, slot: int):
    """A marker for each room in `marked` (room: [label]), in the layer's
    slot on the tile: rows of five from the tile's top right corner."""
    from PIL import Image, ImageDraw

    big = SUPERSAMPLE
    image = Image.new("RGBA", (size[0] * big, size[1] * big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    font = _font(10 * big)
    dark = sum(colour) > 400
    for room, labels in marked.items():
        if room not in origins:
            continue
        x, y = origins[room]
        column, row = slot % MARKERS_PER_ROW, slot // MARKERS_PER_ROW
        cx = (x + TILE_W - 4 - MARKER_R - column * MARKER_STEP) * big
        cy = (y + 4 + MARKER_R + row * MARKER_STEP) * big
        r = MARKER_R * big
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=colour + (255,),
                     outline=(0, 0, 0, 255), width=2 * big)
        text = labels[0] if labels else ""
        if len(labels) > 1:
            text = ",".join(labels) if len(",".join(labels)) <= 3 else str(len(labels))
        if text:
            bbox = draw.textbbox((0, 0), text, font=font)
            draw.text((cx - (bbox[2] + bbox[0]) / 2, cy - (bbox[3] + bbox[1]) / 2), text,
                      fill=(0, 0, 0, 255) if dark else (255, 255, 255, 255), font=font)
    return image.resize(size, Image.LANCZOS)


# --------------------------------------------------------------------------
# The Castle page.
# --------------------------------------------------------------------------

def _door_word(door) -> str:
    return WAY_WORDS.get(_way_bits(door["way"]), f"${door['way']:02X}")


def _walk_text(walk: dict | None) -> str:
    if not walk:
        return "not tried"
    outcome = walk.get("outcome")
    if outcome == "through":
        return f"went through to room {_room_link(walk['room'])}"
    if outcome == "game over":
        return "GAME OVER"
    message = {1: " (BLOCKED)", 2: " (LOCKED)", 3: " (TOO HEAVY)"}.get(walk.get("message"), "")
    return {"stayed": "stayed" + message}.get(outcome, outcome or "?")


def _walk_more(door) -> str:
    """What the follow-up tries of a door that kept him out found."""
    out = ""
    if door.get("walk_clear"):
        walk = door["walk_clear"]
        things = ", ".join(str(n) for n in walk.get("cleared", []) if n) or "nothing numbered"
        out += (f"; with what lay over it that can be moved taken away (things {things}): "
                f"{_walk_text(walk)}")
    if door.get("walk_book"):
        out += f"; with the book lying in the room: {_walk_text(door['walk_book'])}"
    return out


def castle_page(memory, ref, rooms, doors, entries, things, keys_used, creatures, pits,
                trapdoors, quest, measured, origin, disagree, links, adjacent, place, size,
                start_room, unreached, marked, thumb) -> str:
    lines = ['<div class="kl-list">']
    worst = max((m for _, _, m in disagree), default=0)
    loops = sorted({tuple(sorted((a, b))) for a, b, _ in disagree})
    lines.append(
        "<p>Fairlight's castle is 81 rooms, each a little drawing program in the room table "
        f"at {ref(fd.ROOMS)} (the rooms and their commands are laid out in the listing, one "
        f"entry a room), and the object table at {ref(fd.OBJECTS_TAPE)} -- {ref(OBJECTS)} while "
        f"the game runs -- which says what is in each room: "
        f"{sum(1 for e in entries if not e['door'])} entries of six bytes "
        "for the things, the creatures and the furniture, and "
        f"{sum(1 for e in entries if e['door'])} of eleven for the doors. There is no map, "
        "no grid and no room numbering scheme: a room's number is only its place in the room "
        "table, and the castle is held together by nothing but its doors, each of which names "
        "the room behind it and the place the knight arrives at there. This page lays the "
        "rooms out by those doors, marks on the map where things are, and lists the doors, "
        'the keys and the quest; <a href="Rooms.html">the rooms</a> page has every room with '
        "its picture and what it holds.</p>")
    lines.append(
        "<p><b>What is measured and what is read.</b> Measured, in SkoolKit's simulator: every "
        "room's picture (entered the way a new game enters its first room, and drawn by the "
        f"game's own code, {ref(ROOMST)} and {ref(DRAW_CURRENT_ROOM)}), what each room holds as "
        "the game builds it, the room's box (its floor, ceiling and walls, the six records at "
        f"{ref(FIXED_RECORDS)}), every door walked through, the pit in room 10, the room 19 "
        "bug and the ending's test. Read from the tables: where every door leads and the key it "
        "needs, where every thing lies at the start, the chain of keys. Worked out here from the "
        "doors' arithmetic: where each room lies relative to its neighbours, and that the whole "
        "does not fit together. Chosen by this page, not the game: the grid the rooms are drawn "
        "on.</p>")

    # The map.
    toggles, overlays, keys = [], [], []
    for key, what, colour, shown in LAYERS:
        toggles.append(f'<input type="checkbox" class="kl-toggle" id="fl-layer-{key}"'
                       + (" checked" if shown else "") + ">"
                       f'<label for="fl-layer-{key}"><span class="kl-key fl-key-{key}">'
                       f"</span>{what}</label>")
        overlays.append(f'<img class="fl-layer fl-layer-{key}" src="images/world/layer_{key}.png" '
                        'alt="">')
    areas = []
    origins, _ = tile_origins(place)
    for room in sorted(place):
        x, y = origins[room]
        areas.append(f'<area shape="rect" coords="{x},{y},{x + TILE_W},{y + TILE_H}" '
                     f'href="Rooms.html#room{room}" title="Room {room}" alt="Room {room}">')

    def key_line(key, text):
        what = next(w for k, w, _, _ in LAYERS if k == key)
        keys.append(f'<p><span class="kl-key fl-key-{key}"></span><b>{what}</b>: {text}</p>')

    lines += ["<h3>The castle</h3>",
              "<p>Every room drawn by the game, at half size, on a grid of the page's making. The "
              "grid follows the game's own diagonals: a door out through the back right wall "
              "(up x) leads, where the grid allows, to the tile up and to the right, the back "
              "left (up y) up and to the left, and a hole in the ceiling to the tile straight "
              f"above. {adjacent} of the {len(links)} doors lead to the tile next door in that "
              "direction; the others are drawn as longer lines, because the castle cannot be "
              "laid out so that they all do (below, <i>Why a grid</i>). Rooms "
              + " and ".join(str(r) for r in unreached) + ", which no door leads to, are in "
              "the bottom row: GAME OVER's and the title's backdrops, shown as the game shows "
              f"them; room {ENDING_ROOM}, the end, is shown with the verdict of a quest done. "
              "Click a room for its entry; tick a box for a layer.</p>",
              '<div class="kl-layers">', "".join(toggles),
              '<div class="kl-castle"><div class="kl-castle-stack">'
              f'<img src="images/world/castle.png" usemap="#castle" alt="The castle" '
              f'width="{size[0]}" height="{size[1]}">' + "".join(overlays) + "</div>"
              f'<map name="castle">{"".join(areas)}</map></div></div>']

    locked = [d for d in doors if d["key"]]
    one_way = sorted({(d["room"], d["to"]) for d in doors if d["to"]
                      and not any(e["room"] == d["to"] and e["to"] == d["room"] for e in doors)})
    key_line("doors", f"{len(doors)} doors, {len(locked)} of them locked. A line joins two rooms "
             "with a door between them: white for a doorway, dashed cyan for a hole, yellow with "
             "the key's number where the door needs one; an arrowhead where the way goes only one "
             "way (" + ", ".join(f"{_room_link(a)} to {_room_link(b)}" for a, b in one_way)
             + "). A key is the number of a thing in the object table.")
    key_line("start", f"room {_room_link(start_room)}. A new game's variables come from the tape's "
             f"copy at {ref(0xFF80, 'the variables')} (copied to the master at {ref(MASTER_VARIABLES)} and back at "
             f"every new game, {ref(TITLE_SCREEN)}), and their ROOM is {start_room}; the knight's "
             f"record is put back the same way, and a thing of kind 9, used, sends him to room "
             f"{_room_link(CARRY_OFF_ROOM)} through the same code ({ref(MAIN_LOOP)}). Measured: "
             f"the simulator's new game began in room {start_room}.")
    rounds = quest["rounds"]
    lying = quest["lying"]
    book = quest["book"]
    key_to_81 = next(d["key"] for d in doors if d["to"] == ENDING_ROOM)
    door_81 = next(d for d in doors if d["to"] == ENDING_ROOM)
    key_line("quest", f"5 -- thing 5 in room {_room_link(lying[QUEST_THING])}, what the ending "
             f"looks for; B -- the book, thing {book['number']}, in room "
             f"{_room_link(book['room'])}; W -- room {_room_link(61)}, where the book must be "
             f"left; {key_to_81} -- room {_room_link(door_81['room'])}, whose door to the end "
             f"needs thing {key_to_81}; E -- room {_room_link(ENDING_ROOM)}, the end. See "
             "<i>The quest</i> below.")
    key_line("keys", "the things that open doors, each marked with its number: "
             + "; ".join(f"thing {k} in room {_room_link(lying[k])}" for k in keys_used)
             + ". Where they lie at the start of a game, from the object table; a thing dropped "
             f"elsewhere is remembered there ({ref(SAVE_OBJECT_POSITIONS)}).")
    other_things = [e for e in things if e["kind"] & 0x20 and e["number"] not in keys_used]
    key_line("things", f"the other {len(other_things)} things of the object table that can be "
             "picked up (bit 5 of their kind byte), counted by room: "
             + ", ".join(f"{_room_link(r)} ({len(v)})" for r, v in sorted(
                 (r, [e for e in other_things if e["room"] == r]) for r in
                 {e["room"] for e in other_things}))
             + ". The rooms page lists them, with what each does.")
    for key, name, states in CREATURES:
        found = creatures[key]
        total = sum(len(v) for v in found.values())
        key_line(key, f"{total} in {len(found)} rooms, counted by room: "
                 + ", ".join(f"{_room_link(r)} ({len(v)})" for r, v in sorted(found.items()))
                 + ". " + "; ".join(f"state {s}: {STATE_WORDS[s]}" for s in states) + ".")
    trap = trapdoors[0] if trapdoors else None
    key_line("pits", f"rooms {_rooms(pits)}, whose floor is a record of kind 7 below a bridge: "
             f"anything that falls onto it vanishes, and the knight's LIFE goes to 0 "
             f"({ref(OBJECTS_MEET)}); and room {_room_link(trap['room']) if trap else '?'}, "
             "whose pit is a door -- a hole in the floor that leads to room 0 (below, <i>The "
             "pit in room 10</i>).")
    bug = measured["bug"]
    key_line("bug", f"room {_room_link(19)}, where two things of the room's own drawing can be "
             f"picked up, and rooms {_room_link(25)} and {_room_link(21)}, whose door they spoil "
             "(below, <i>The room 19 bug</i>).")
    lines += keys

    # Why a grid.
    lines += ["<h3>Why a grid</h3>",
              "<p>Each door gives the room behind it a place relative to its own. Along a "
              "doorway the knight's place is carried across exactly -- the door's corner in "
              "this room is the arrival point in the next -- and across it the door's face "
              "becomes the arrival point, less his depth when he goes the way the axis falls "
              f"({ref(BUMPED)}); his height is carried across the same way. Through a hole his x "
              "and y are carried across, and he arrives in the air, so this page takes the room "
              "below to have its ceiling at the floor above. Starting from room "
              f"{start_room} and giving each room the place the first door found to it says, "
              f"{len(origin)} rooms are placed; then every door was checked against those "
              f"places, and {len(disagree)} of the {len(doors) - 1} doors put the room behind them "
              f"somewhere else, by up to {worst} units -- about "
              f"{worst / 130:.1f} rooms' widths. The pairs: "
              + ", ".join(f"{_room_link(a)}-{_room_link(b)}" for a, b in loops)
              + ". Some are a few units out, and follow from how each door's face was taken; the "
              "rest are loops of rooms that do not close. The castle is drawn room by room, and "
              "no one room shows its neighbours, so the game never needs them to fit, and they "
              "do not. Hence the grid: it keeps each door's direction where it can and gives up "
              "distances altogether.</p>"]

    # Doors.
    lines += ["<h3>The doors</h3>",
              "<p>A door is an eleven-byte record of the object table, and becomes an object "
              f"record of kind 1 when its room is entered ({ref(PLACE_OBJECT)}). It has no update "
              f"of its own ({ref(CHE3D)} skips it): it is dealt with when something walks into "
              f"it ({ref(BUMPED)}). Anything but the knight is stopped by it as by a wall.</p>",
              '<table class="kl-table"><tr><th>Byte</th><th>Record</th><th>What</th></tr>',
              "<tr><td>0</td><td></td><td>The room the door is in</td></tr>",
              f"<tr><td>1</td><td></td><td>Its type, ${FIRST_DOOR_TYPE:02X} up: a template at "
              f"{ref(LARGE_TEMPLATES)} gives its size and, for some, a sprite</td></tr>",
              "<tr><td>2-4</td><td>+6 to +8</td><td>Its place: x, the top, y</td></tr>",
              "<tr><td>5</td><td>+13</td><td>The room behind it</td></tr>",
              "<tr><td>6</td><td>+14</td><td>The key: the number of the thing that must be in "
              "the place in use, or 0 for none</td></tr>",
              "<tr><td>7, 8</td><td>+15, +16</td><td>The x and the top the knight arrives at "
              "(each carried across relative to the door where it is not the way through)</td></tr>",
              "<tr><td>9</td><td>+17</td><td>The way through: the direction bits of "
              f"{ref(0xF595)} -- $04 down x, $08 up x, $40 up y, $80 down y, $10 up, $20 down"
              "</td></tr>",
              "<tr><td>10</td><td>+18</td><td>The y he arrives at</td></tr>",
              "</table>"]
    ways = {}
    for door in doors:
        ways.setdefault(_way_bits(door["way"]), []).append(door)
    lines.append("<p>" + "; ".join(f"{len(ways.get(bit, []))} lead {WAY_WORDS[bit]}"
                                  for bit in (0x08, 0x04, 0x40, 0x80, 0x10, 0x20))
                 + ". The knight goes through only moving the way the door goes, which the "
                 "fall that is added to every step he takes on the ground includes: so he drops "
                 "through a hole in the floor by walking onto it, and to go up through a hole in "
                 "the ceiling he must jump into it from something high enough.</p>")
    walked = [d for d in doors if d["walk"].get("outcome") in ("through", "game over")]
    right = [d for d in walked if d["walk"].get("room") == d["to"]
             or (d["to"] == 0 and d["walk"].get("outcome") == "game over")]
    stayed_locked = [d for d in locked if d["walk"].get("message") == 2
                     and d["walk"].get("outcome") == "stayed"]
    opened = [d for d in locked if d.get("walk_key", {}).get("outcome") == "through"
              and d["walk_key"].get("room") == d["to"]]
    failed = [d for d in doors if d not in walked and not d["key"]]
    blocked_somewhere = [d for d in doors if 1 in d["walk"].get("messages", [])
                         or 1 in d.get("walk_key", {}).get("messages", [])]
    failed_key = [d for d in locked if d not in opened]
    lines.append(
        "<p><b>Every door walked.</b> When this page was built each door was tried in the "
        "simulator, each from a fresh entry into its room: the knight put just outside the "
        "doorway, touching it, within its width and with his feet on its foot, and walked the "
        "way it goes; put just above a hole in the floor; or, for a hole in the ceiling, stood "
        "under it on the room's floor raised to just below it (a staging: the floor record's "
        "height changed) and made to jump. Each was tried from a few places along the door, "
        "since furniture stands in parts of some doorways, and a thing lying where he would "
        f"arrive keeps him out (BLOCKED, {ref(BUMPED)}): that was seen at some place "
        f"for {_plural(len(blocked_somewhere), 'door')} ("
        + ", ".join(f"room {_room_link(d['room'])}'s to {d['to']}" for d in blocked_somewhere)
        + f"). LIFE was kept up throughout. Without any key, {len(walked)} of the "
        f"{len(doors)} doors took him through, {len(right)} of them to the room the record "
        "names"
        + (f"; {len(failed)} that need no key did not: "
           + ", ".join(f"room {_room_link(d['room'])}'s to {d['to']} ({_walk_text(d['walk'])}"
                       f"{_walk_more(d)})" for d in failed) if failed else "")
        + f". Of the {len(locked)} locked doors, {len(stayed_locked)} said LOCKED and kept him "
        "out; then, with the key laid in the room and picked up the game's own way (X) into "
        f"the place in use, {len(opened)} let him through to the room they name"
        + (" (not: " + ", ".join(f"room {_room_link(d['room'])}'s to {d['to']}: "
                                 f"{_walk_text(d.get('walk_key'))}" for d in failed_key) + ")"
           if failed_key else "")
        + ".</p>")

    # Keys.
    lines += ["<h3>The keys</h3>",
              f"<p>Doors are opened by {len(keys_used)} things, each named by the number of its entry in the "
              "object table. The thing must be in the place in use when the knight walks into "
              "the door, or it is LOCKED; carried in another place it does not count.</p>",
              '<table class="kl-table"><tr><th>Thing</th><th>Picture</th><th>Lies in</th>'
              "<th>Opens</th></tr>"]
    for number in keys_used:
        entry = next(e for e in entries if e["number"] == number)
        opens = [d for d in doors if d["key"] == number]
        lines.append(f"<tr><td>{number}</td><td>{thumb(entry['sprite'], entry['width'], entry['height'])}"
                     f"</td><td>{_room_link(entry['room'])}</td><td>"
                     + "; ".join(f"{_room_link(d['room'])} to {_room_link(d['to'])} "
                                 f"({WAY_SHORT[_way_bits(d['way'])]})" for d in opens)
                     + "</td></tr>")
    lines.append("</table>")
    reach_lines = []
    seen = set()
    for index, (reached, found) in enumerate(rounds):
        new = [r for r in reached if r not in seen]
        seen |= set(reached)
        reach_lines.append(
            f"<tr><td>{'no key' if index == 0 else 'with ' + ', '.join(str(k) for k in sorted(set().union(*[set(f) for _, f in rounds[:index]])))}"
            f"</td><td>{len(new)}: {_rooms(new)}</td><td>{', '.join(str(k) for k in found) or '-'}"
            "</td></tr>")
    lines += ["<p>Which rooms are open to a knight with which keys, read from the doors: from "
              f"room {start_room}, through every door that needs no key, then again with the keys "
              "lying in the rooms reached so far, until no new key turns up. This counts only "
              "doors and keys -- not how much he can carry, the jumps, the things that block an "
              "arrival -- and takes the way out of room 61 to be open once its way in is (see "
              "the quest).</p>",
              '<table class="kl-table"><tr><th>Keys</th><th>Rooms newly open</th>'
              "<th>Keys found there</th></tr>"] + reach_lines + ["</table>"]
    never = sorted(set(range(1, fd.ROOM_COUNT + 1)) - set(rounds[-1][0]))
    lines.append(f"<p>Never open by any door: rooms {', '.join(str(r) for r in never)}. Room 1 "
                 f"is drawn only as the backdrop to GAME OVER and room 79 only under the title "
                 f"({ref(TITLE_SCREEN)}); the object table puts nothing in either, and neither "
                 "has a patch for the room's box (the six records the collision code tests). Room "
                 "0 is not a room at all: see the pit in room 10.</p>")

    # The quest.
    door_13 = next((d for d in doors if d["key"] == QUEST_THING), None)
    door_61 = next((d for d in doors if d["to"] == 61), None)
    key_8_room = lying.get(key_to_81)
    lines += ["<h3>The quest</h3>",
              "<p>The story has the knight bring the Book of Light out of the castle to free the "
              f"wizard. What the game checks is this. Room {ENDING_ROOM} is the end: "
              f"{ref(ROOMST)} does not enter it but draws it, and prints that the quest has "
              f"succeeded if one of the five things carried is number {QUEST_THING} in the object "
              "table -- the thing that lies in room "
              f"{_room_link(lying[QUEST_THING])} at the start -- and failed if not; then GAME "
              "OVER either way. Measured: entering room 81 with nothing carried, "
              f"{ref(ROOMST)} went to its failure ({VERDICT_WORDS[measured['ending_without']]}); "
              f"with thing {QUEST_THING} picked up first, to its success "
              f"({VERDICT_WORDS[measured['ending_with']]}). Thing {QUEST_THING} is this: "
              + thumb(next(e for e in entries if e["number"] == QUEST_THING)["sprite"],
                      next(e for e in entries if e["number"] == QUEST_THING)["width"],
                      next(e for e in entries if e["number"] == QUEST_THING)["height"])
              + " -- not the picture of a book. The thing drawn as a book, "
              f"{thumb(book['sprite'], book['width'], book['height'])} (thing {book['number']}, "
              f"in room {_room_link(book['room'])}), is the one of kind 11, and does not go "
              "to the end.</p>",
              "<p>The only door into room 81 is in room "
              f"{_room_link(door_81['room'])} and needs thing {key_to_81}, which lies in room "
              f"{_room_link(key_8_room)}. Room 61 is reached by one way, a hole in the ceiling of "
              f"room {_room_link(door_61['room']) if door_61 else '?'}, and that door's key is "
              f"thing {door_61['key'] if door_61 else '?'} -- the book. Its only way out is a "
              "hole in its floor, which lets him through only while a thing of kind 11 -- the "
              f"book -- lies in the room ({ref(BUMPED)}); and there the figure that has stood "
              f"still until then (state 15, {ref(CREATURE_UPDATE)}) wakes as a wraith. So the "
              "book is used up: it opens room 61 and is left on its floor. And the book lies in "
              f"room {_room_link(book['room'])}, reached only by a hole from room "
              + (f"{_room_link(next(d['room'] for d in doors if d['to'] == book['room']))}, which is "
                 f"reached by the door from room {_room_link(door_13['room'])} whose key is thing "
                 f"{QUEST_THING} itself." if door_13 else "?.")
              + " The chain, read from the doors and the table:</p>",
              "<ol>",
              f"<li>Thing {QUEST_THING}, in room {_room_link(lying[QUEST_THING])}, opens the door "
              f"from room {_room_link(door_13['room']) if door_13 else '?'} to room "
              f"{_room_link(door_13['to']) if door_13 else '?'}.</li>",
              f"<li>Through the hole in its floor to room {_room_link(book['room'])}, for the book "
              f"(thing {book['number']}).</li>",
              f"<li>The book opens the hole up from room "
              f"{_room_link(door_61['room']) if door_61 else '?'} into room 61; left there, it "
              f"lets him out again, and he takes thing {key_to_81}.</li>",
              f"<li>Thing {key_to_81} opens room {_room_link(door_81['room'])}'s door to room "
              f"{ENDING_ROOM}, entered with thing {QUEST_THING} still carried.</li>",
              "</ol>",
              "<p>Which thing the story's Book of Light is, the game does not say; the test at the "
              f"end is for thing {QUEST_THING}.</p>"]

    # The pit in room 10.
    if trap:
        lines += ["<h3>The pit in room 10</h3>",
                  f"<p>Room {trap['room']}'s object list has a door of type "
                  f"${next(e for e in entries if e['door'] and e['room'] == trap['room'] and e['to'] == 0)['type']:02X} "
                  f"with no sprite at x {trap['place'][0]}, y {trap['place'][2]}, "
                  f"{trap['sizes'][0]} by {trap['sizes'][2]} and 2 high, its top 2 above the "
                  "floor: a hole in the floor -- where the room's drawing shows a pit -- whose "
                  f"room behind is 0 and whose arrival point is a dummy ({', '.join(str(v) for v in trap['arrive'])}). "
                  f"{ref(ROOMST)} does nothing for room 0 but return, and it returns to the new "
                  f"game's code ({ref(TITLE_SCREEN)}), which saves the room's things and says "
                  "GAME OVER. Since every step the knight takes includes the fall, walking onto "
                  "the pit takes him through it. Measured: walked into the pit, he "
                  + ("went through to GAME OVER, LIFE untouched"
                     if trap["walk"].get("outcome") == "game over" else _walk_text(trap["walk"]))
                  + f". The description of {ref(ROOMST)} that no room 0 is ever given is so for "
                  "new games but not for this door. Rooms 9 and 12's pits work differently, by a "
                  "floor that kills.</p>"]

    # The room 19 bug.
    door = bug.get("door")
    if door:
        lines += ["<h3>The room 19 bug</h3>",
                  f"<p>Room 19's drawing places {bug.get('unnumbered', '?')} things of its own, "
                  "which can be picked up but, not being from the object table, have no number "
                  f"(+19 is 0). Picking one up asks {ref(SET_THING_ROOM)} to mark its entry in the "
                  "table as carried (room $FE), and with number 0 that routine counts 256 "
                  "entries of six bytes on from just below the table: 1536 bytes in, the x of "
                  f"the table's entry {door['number']}, the door from room 25 to room 21. "
                  f"Measured: with the room's creatures frozen and the thing laid in front of him, "
                  f"X picked it up ({'carried' if bug.get('carried') else 'not carried'}) and "
                  f"that byte went from {bug.get('before')} to {bug.get('after')}. Then, with the "
                  "byte at 254, the door walked into from room 25: "
                  f"{_walk_text(bug.get('walk_spoiled'))}; before, "
                  f"{_walk_text(door['walk'])}. Room 21 can still be reached from room 25 by "
                  "other ways round; dropping the thing would write 19 there instead.</p>"]
    lines.append("</div>")
    return "\n".join(lines)


# --------------------------------------------------------------------------
# The Rooms page.
# --------------------------------------------------------------------------

def rooms_page(memory, ref, rooms, room_records, doors, entries, things, creatures, pits,
               trapdoors, quest, measured, start_room, keys_used, thumb) -> str:
    names = {1: "the backdrop to GAME OVER, which the game prints over it "
                f"({ref(TITLE_SCREEN)}); shown here with it",
             79: f"the title's picture, under the title page ({ref(TITLE_SCREEN)}); shown here "
                 "with it",
             ENDING_ROOM: f"the backdrop to the end of the quest ({ref(ROOMST)}); shown here "
                          f"with the verdict printed when thing {QUEST_THING} is carried in"}
    lines = ['<div class="kl-list">',
             "<p>Every room as the game draws it when it is entered at the start of a game, "
             "without the knight: the room's drawing, then its doors and still things drawn "
             f"into it ({ref(DRAW_STILL_THINGS)}), then every other object drawn once where it "
             f"stands, and the colour put on ({ref(MAIN_LOOP)}). Rooms 1, 79 and 81 are only ever "
             "backdrops, and are shown as the game shows them, with what it prints over them. "
             "Positions are x, the "
             "top, y; x runs up to the back right, y up to the back left. The listing's entry "
             "for each room has its drawing commands; the object table's entries are there "
             f"too, from {ref(fd.OBJECTS_TAPE)}.</p>"]
    for room in range(1, fd.ROOM_COUNT + 1):
        info = rooms[room]
        address, length = room_records[room - 1]
        colour = info["colour"]
        paper = fd.INKS[colour >> 3 & 7]
        facts = [f"its commands {ref(address)}, {length} bytes", f"{paper} paper"]
        box = info["box"]
        if box:
            facts.append(f"floor at {box['floor']}, ceiling at {box['ceiling']}, x {box['x'][0]}"
                         f"-{box['x'][1]}, y {box['y'][0]}-{box['y'][1]}")
            facts.append(f"{len(info['records']) + 6} object records built")
        notes = []
        if room in names:
            notes.append(f"Drawn only as {names[room]}."
                         + (" Its commands are its colour and the end: it draws nothing, a "
                            "blank screen for the words." if length == 4 else ""))
        if room == start_room:
            notes.append("A new game starts here.")
        if room == CARRY_OFF_ROOM:
            notes.append("A thing of kind 9, used, carries the knight here.")
        if room in quest["marks"]:
            notes.append({"5": f"Thing {QUEST_THING}, which the ending looks for, lies here.",
                          "E": "The end of the quest.",
                          "B": "The book (the thing of kind 11) lies here.",
                          "W": "The book must be left here to get out."}.get(
                quest["marks"][room], f"Its door to room {ENDING_ROOM} needs thing "
                                      f"{quest['marks'][room]}."))
        if room in pits:
            notes.append("A pit: its floor kills.")
        if any(d["room"] == room for d in trapdoors):
            notes.append("A pit: a hole in its floor ends the game.")
        if room == 19:
            notes.append("Two things of the room's own can be picked up, which spoils the door "
                         "from room 25 to room 21 (the room 19 bug).")
        exits = []
        for door in (d for d in doors if d["room"] == room):
            text = f"{_door_word(door)} to "
            text += _room_link(door["to"]) if door["to"] else "room 0 (GAME OVER)"
            text += f", at {', '.join(str(v) for v in door['place'])}"
            if door["key"]:
                text += f"; needs thing {door['key']}"
            text += f"; walked: {_walk_text(door['walk'])}"
            if door["key"]:
                text += f", and with the key: {_walk_text(door.get('walk_key'))}"
            text += _walk_more(door)
            exits.append(f"<li>{text}</li>")
        ins = sorted({d["room"] for d in doors if d["to"] == room})
        held = []
        for entry in (e for e in things if e["room"] == room):
            kind = entry["kind"]
            if not kind & 0x20:
                continue
            what = KIND_WORDS.get(kind & 15, f"kind {kind & 15}")
            if entry["number"] in keys_used:
                what = f"a key ({what})" if kind & 15 else "a key"
            held.append(f"<li>{thumb(entry['sprite'], entry['width'], entry['height'])}"
                        f"thing {entry['number']} (type {entry['type']}): {what}; at "
                        f"{', '.join(str(v) for v in entry['place'])}</li>")
        movers = []
        for key, name, states in CREATURES:
            for record in creatures[key].get(room, []):
                state = record[14] & 15
                who = f"thing {record[19]}" if record[19] else "placed by the room's drawing"
                movers.append(f"<li>{thumb(_word(record, 4), record[2], record[3])}"
                              f"{STATE_WORDS[state]} ({who}); at "
                              f"{', '.join(str(v) for v in record[6:9])}</li>")
        rest = [r for r in info["records"][1:] if r[12] & 15 != KIND_DOOR
                and not (r[12] & 0x20) and not any(r in v.get(room, []) for v in creatures.values())]
        lines += [f'<div class="kl-item" id="room{room}">',
                  f'<img class="kl-scene" src="images/world/room{room:02d}.png" alt="Room {room}">',
                  f"<p><b>Room {room}</b>: " + "; ".join(facts) + "."
                  + (" " + " ".join(notes) if notes else "") + "</p>"]
        if info["box"]:
            lines.append("<p>Exits:</p>" + ('<ul class="fl-room-list">' + "".join(exits) + "</ul>"
                                            if exits else "<p>none.</p>"))
            lines.append(f"<p>Doors in from: {_rooms(ins)}.</p>")
            lines.append(('<p>Things:</p><ul class="fl-room-list">' + "".join(held) + "</ul>")
                         if held else "<p>Things: none.</p>")
            lines.append(('<p>Creatures:</p><ul class="fl-room-list">' + "".join(movers) + "</ul>")
                         if movers else "<p>Creatures: none.</p>")
            if rest:
                drawn = sum(1 for r in rest if r[4] or r[5])
                parts = []
                if drawn:
                    parts.append(f"{drawn} drawn (furniture and fittings)")
                if len(rest) - drawn:
                    parts.append(f"{len(rest) - drawn} unseen (invisible blocks, the steps of "
                                 "stairs, a pit's floor)")
                lines.append(f"<p>And {_plural(len(rest), 'object')} that do nothing but stand "
                             f"in the way: {' and '.join(parts)}.</p>")
        elif ins:
            lines.append(f"<p>Doors in from: {_rooms(ins)}.</p>")
        lines.append("</div>")
    lines.append("</div>")
    return "\n".join(lines)
