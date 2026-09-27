"""Atic Atac's "How it works" deep dives: drawing, movement and collision,
the monsters, the doors, and the quest (food, health and the A.C.G. key).

build() returns each page's HTML, by ref section name, and draws the pictures
into the HTML directory. Nothing here is a transcription of the game: every
table is read from the game's memory as the page is built, and every scene and
worked example is the game's own code, run in SkoolKit's simulator on a game
started from the title screen the way build_aticatac starts one. Where a scene
is staged -- a creature written into a monster slot, an object put at the
player's feet, a key put in the inventory -- the staging is only the starting
state; what follows is the game's doing, and the page says which is which.

The prose is written from reading the listing (scripts/aticatac_annotations.ctl
and the code it describes) and the notes in notes/aticatac/, and checked
against what the runs give; the pages say which claims rest on which. Like the
rest of the build, the pictures and the pages are the game's content and are
never committed.

The first game after loading is always laid out the same way: the title screen
runs with interrupts off, so FRAMES -- which the tape poked -- has the same
value whenever a game starts from the snapshot, and everything START_GAME
chooses from it comes out alike. Every run here starts from that first game.
"""
from __future__ import annotations

import functools
import html
import re
from pathlib import Path

import build_aticatac as ba

IMAGE_DIR = "images/howitworks"
TSTATES_PER_SECOND = 3_500_000
FRAME_TSTATES = 69_888
RUN_LIMIT = 20 * TSTATES_PER_SECOND      # a bound on any one run to a stop

# --------------------------------------------------------------------------
# Addresses: routines (entry points and a few places inside them).
# --------------------------------------------------------------------------

TITLE_SCREEN = 0x7C19
START_GAME = 0x7D9A
MAIN_LOOP = 0x7DC3
MAIN_LOOP_MONSTERS = 0x7E13
ROOM_LIST_PASS = 0x7E23
LIST_ENTRY_DONE = 0x7E35       # where DISPATCH_FROM_LIST's handlers return to
FIRST_PASS_CONTENTS = 0x7E52   # CALL DRAW_ROOM_CONTENTS, on a room's first pass
AFTER_CONTENTS = 0x7E55
PASS_TAIL = 0x7E5A             # the end-of-pass housekeeping begins
DISPATCH_ACTOR = 0x7E7E
DISPATCH_FROM_LIST = 0x7E93
FRAME_TICK = 0x7EB2
ACTOR_HANDLERS = 0x7EE6
ROOM_HANDLERS = 0x802A         # ACTOR_HANDLERS + 2 * $A2
INERT_SPRITE = 0x807A
CLEAR_PLAY_AREA = 0x8093
UPDATE_WIZARD = 0x80D2
KNIGHT_FIRE = 0x8134
WIZARD_FIRE = 0x814B
FIRE_WEAPON = 0x817C
SPIN_AXE = 0x81DB
SPIN_SPELL = 0x81F0
SPIN_WEAPON = 0x8209
SERF_FIRE = 0x8283
AIM_SWORD = 0x82F1
MOVE_ARCS = 0x8301
STEP_VECTORS = 0x83CA
SPAWN_MONSTER_INTO_ROOM = 0x83EA
SPAWN_PUT = 0x840D             # a creature is about to be written into slot DE
MOVE_ACTOR = 0x845F
STEP_ACTOR = 0x84CD
CHECK_SHOT_HIT = 0x8566
RANDOM_POSITION = 0x8598
CHECK_HIT = 0x85B2
MONSTER_CAUGHT_PLAYER = 0x85EA
ACTOR_TICK_TIMER = 0x85F0
SPAWN_MONSTER = 0x85F7
MOVE_BAT = 0x862E
MOVE_HOPPER = 0x8672
RANDOM_VELOCITY = 0x86F2
MOVE_FACE = 0x871A
KILL_MONSTER = 0x875F
COUNTDOWN_ACTOR = 0x8787
MOVE_GHOST = 0x87A6
HOME_IN = 0x882D
MOVE_MUMMY = 0x8862
MOVE_DRACULA = 0x8906
MOVE_FRANKENSTEIN = 0x8988
BIG_MONSTER_STEP = 0x89BB
MOVE_DEVIL = 0x89ED
LOSE_FOOD_SIXTEEN = 0x8A15
LOSE_FOOD_EIGHT = 0x8A1E
MOVE_WITCH = 0x8A2F
MOVE_FACING_FLYER = 0x8A80
SCAN_COLLECTABLES = 0x8ADB
MOVE_HUMPBACK = 0x8AFF
MONSTER_TEMPLATE = 0x8B6A
SPAWN_TYPES = 0x8B7A
DRAW_FOOD = 0x8B8A
GAME_OVER = 0x8C35
END_DELAY = 0x8C4A
EAT_FOOD = 0x8C63
FLASH_SCORE = 0x8C8C
MATERIALISING = 0x8CB7
DYING = 0x8D45
LOAD_INITIAL_STATE = 0x8D61
MOVE_PLAYER = 0x8D77
UPDATE_SERF = 0x8DC4
UPDATE_KNIGHT = 0x8E26
PLAYER_TICK = 0x8E78
REDRAW_ACTOR = 0x8E8E
LOSE_LIFE = 0x8EA0
LOSE_FOOD_THIRTY_TWO = 0x8ED7
STEER = 0x8EEF
APPLY_HEADING = 0x8F66
SCALE_SIGNED = 0x8F80
DECAY_HEADING = 0x8F96
TEST_STEP_IN_ROOM = 0x8FCA
ALLOW_IF_IN_ROOM = 0x8FE9
TEST_STEP_BOXES = 0x900A
TEST_ROOM_BOXES = 0x902B
PLAYER_AT_DOOR = 0x90CC
NEAR_PLAYER = 0x90FB
ENTER_ROOM = 0x9117
ARRIVE_IN_ROOM = 0x9147
TIMED_DOOR_OPEN = 0x915F
TIMED_DOOR_SHUT = 0x917D
TOGGLE_TIMED_DOOR = 0x9193
TRAPDOOR_CLOSED = 0x91BC
TRAPDOOR = 0x91C5
BIG_DOOR = 0x91ED
DOOR = 0x91F2
DRAW_DOOR = 0x91FE
DRAW_RECORD = 0x9213
DOOR_NEEDS_KEY = 0x9222
DOOR_LOCKED_A = 0x9244
DOOR_LOCKED_B = 0x9252
DOOR_COLOURS = 0x925C
SET_BOTH_HALVES = 0x9260
FIND_CARRIED = 0x9273
DOOR_OTHER_SIDE = 0x9286
DRAW_ROOM_CONTENTS = 0x9291
PICK_UP = 0x92F5
REMEMBER_CARRIED = 0x9326
SHIFT_CARRIED = 0x934C
DROP_CARRIED = 0x9358
READ_PICKUP_KEY = 0x938B
READ_CONTROLS = 0x93BE
PUT_DOWN = 0x93E3
DOOR_SERF = 0x9421
DOOR_WIZARD = 0x9428
DOOR_KNIGHT = 0x942F
PLACE_PLAYER = 0x9443
PAUSE = 0x9489
PLACE_ACG_KEY = 0x94B6
KEY_ROOM_SETS = 0x94DD
CHOOSE_TIMED_DOORS = 0x94F5
OPEN_DOOR = 0x954D
SHUT_DOOR = 0x9565
CHECK_IN_DOORWAY = 0x957D
DROP_GRAVESTONE = 0x95A9
GRAVESTONE = 0x95D7
TICK_CLOCK = 0x95DA
ACG_DOOR = 0x961B
DRAW_SUMMARY = 0x9641
MARK_ROOM_VISITED = 0x96AF
COUNT_ROOMS_EXPLORED = 0x96C9
SHOW_END_SCREEN = 0x96EC
END_MESSAGES = 0x9710
TRAPDOOR_FALL = 0x9731
FALL_STARTS = 0x973A
SET_ARRIVAL_HEADING = 0x986A
ARRIVAL_HEADINGS = 0x9883
MUSHROOM = 0x988B
MUSHROOM_DRAIN = 0x98B1
PLACE_KEYS = 0x98D2
RANDOM_ROOMS = (0x990C, 0x9914, 0x991C)
REGROW_FOOD = 0x9924
DRAW_SPRITE_PIXELS = 0x9962
PIXEL_DRAWERS = 0x9970
DRAW_SPRITE_COLOURS = 0x9980
COLOUR_DRAWERS = 0x9985
REVERSE_BITS = 0x9A92
START_AT_LAST_ROW = 0x9ABA
DRAW_ROOM = 0x9BEA
ROOM_FLOODED = 0x9C0B          # in DRAW_ROOM: the attributes are done, the outline not
DRAW_OUTLINE = 0x9C2F
DRAW_LINE = 0x9C79
SPRITE_COMBINE_OPCODE = 0x9D19
ERASE_DRAW_ROWS = 0x9E9B
SHIFT_CHAIN = 0x9F2B
DRAW_THING = 0x9F4A
ERASE_THING = 0x9F56
SETUP_ERASE = 0x9F80
SETUP_SPRITE_DRAW = 0x9F9F
DRAW_JR = 0x9F29               # the JR whose displacement SETUP_SPRITE_DRAW writes
REDRAW_MOVED = 0x9FCA
ALIGN_ROWS = 0x9FD1
ACTOR_TO_WORKSPACE = 0x9FFB
DRAW_FROM_RECORD = 0xA01A
COLOUR_FILLERS = 0xA064
DRAW_INVENTORY = 0xA13B
ADD_SCORE = 0xA19C
PLOT_TILE = 0xA1D3
DRAW_SCROLL = 0xA219
PAINT_PANEL = 0xA240
DRAW_LIVES = 0xA2CE
PLAY_SOUND_NEW_ROOM = 0xA403

# The drawers of the eight modes, pixels and colours.
PIXEL_DRAWER_ENTRIES = (0x99C9, 0x99E5, 0x9A0A, 0x9A50, 0x9ACB, 0x9AEF, 0x9B14, 0x9B5D)
COLOUR_DRAWER_ENTRIES = (0x9D25, 0x9D47, 0x9D6F, 0x9DA0, 0x9DCE, 0x9DF8, 0x9E21, 0x9E55)
COLOUR_FILLER_NAMES = ("still", "moved right", "moved left", None, "moved down",
                       "moved down and right", "moved down and left", None, "moved up",
                       "moved up and right", "moved up and left")

# --------------------------------------------------------------------------
# Addresses: variables and records.
# --------------------------------------------------------------------------

FRAMES = 0x5C78
RUNNING_SUM = 0x5E05
TICKS = 0x5E12
ROOM_DRAWN = 0x5E14
WORK_SPRITE = 0x5E15
ROOM_COLOUR = 0x5E1A
ROOM_HALF_WIDTH = 0x5E1D
ROOM_HALF_HEIGHT = 0x5E1E
PICKUP_USED = 0x5E1F
PICKUP_KEY = 0x5E20
LIVES = 0x5E21
SPAWN_ROOM = 0x5E26
SPAWN_COUNTDOWN = 0x5E27
FOOD_LEVEL = 0x5E28
SCORE = 0x5E2A
IN_DOORWAY = 0x5E2D
DOOR_WAIT = 0x5E2E
CARRIED = 0x5E30
FLASH_COUNT = 0x5E3C
CLOCK = 0x5E3D
ROOMS_SEEN = 0x5E40
REGROW_CURSOR = 0x5E55

PLAYER = 0xEA90
ROOM = PLAYER + 1
PLAYER_X = PLAYER + 3
PLAYER_Y = PLAYER + 4
WEAPON = 0xEA98
SOUND_SLOT = 0xEAA0
ACG_PIECES = (0xEAA8, 0xEAB0, 0xEAB8)
KEYS = {"green": 0xEAC0, "red": 0xEAC8, "cyan": 0xEAD0, "yellow": 0xEAD8}
MUMMY_LURE = 0xEAE0
GRAVESTONES = 0xEAE8
CRUCIFIX = 0xEB08
SPANNER = 0xEB10
OBJECTS = 0xEB18
FOOD = 0xEB58
MUSHROOMS = 0xEDD8
DROP_CONTROLLER = 0xEE58
CREATURE_SLOTS = (0xEE60, 0xEE70, 0xEE80)
MUMMY, DRACULA, DEVIL, FRANKENSTEIN, HUMPBACK = 0xEE90, 0xEEA0, 0xEEB0, 0xEEC0, 0xEED0
BIG_FIVE = (("the mummy", MUMMY, MOVE_MUMMY), ("Dracula", DRACULA, MOVE_DRACULA),
            ("the devil", DEVIL, MOVE_DEVIL),
            ("Frankenstein's monster", FRANKENSTEIN, MOVE_FRANKENSTEIN),
            ("the humpback", HUMPBACK, MOVE_HUMPBACK))
LIVE_DOORS = 0xEEE0
TEMPLATE = 0x600D
RUNTIME_OFFSET = PLAYER - TEMPLATE     # runtime = template + this
TEMPLATE_DOORS = 0x645D
TEMPLATE_END = TEMPLATE + 5488
ROOM_CONTENTS = 0x757D
ROOM_TABLE = 0xA854
ROOM_SHAPES = 0xA982

X, Y, MODE = 3, 4, 5
PLAY_CENTRE = (0x58, 0x68)             # the walk rectangle's centre (ALLOW_IF_IN_ROOM)

# Keys, keyboard control: Q left, W right, E down, R up, T fire (READ_CONTROLS).
LEFT, RIGHT, DOWN, UP, FIRE, PICK = "q", "w", "e", "r", "t", "SS"

CHARACTERS = {"4": "knight", "5": "wizard", "6": "serf"}
CHARACTER_BASE = {"knight": 0x01, "wizard": 0x11, "serf": 0x21}
CHARACTER_HANDLER = {"knight": UPDATE_KNIGHT, "wizard": UPDATE_WIZARD, "serf": UPDATE_SERF}
CHARACTER_FIRE = {"knight": KNIGHT_FIRE, "wizard": WIZARD_FIRE, "serf": SERF_FIRE}

# The Spectrum's colours, normal and bright.
PALETTE = [[(0, 0, 0), (0, 0, 215), (215, 0, 0), (215, 0, 215), (0, 215, 0), (0, 215, 215),
            (215, 215, 0), (215, 215, 215)],
           [(0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255), (0, 255, 0), (0, 255, 255),
            (255, 255, 0), (255, 255, 255)]]
COLOUR_NAMES = ["black", "blue", "red", "magenta", "green", "cyan", "yellow", "white"]
MARK = (255, 60, 60)


# --------------------------------------------------------------------------
# A game in the simulator.
# --------------------------------------------------------------------------

def _key_tracer_class():
    return ba._key_tracer_class()


@functools.lru_cache(maxsize=None)
def _start_state(snapshot: str, character: str) -> tuple:
    """Memory and registers of the first game after loading, started from the
    title screen with the keyboard and `character` ("4", "5" or "6") chosen,
    and run on to the first FRAME_TICK with the player in play.

    The keys are pressed by time, as build_aticatac's playthroughs press
    them: the title screen runs with interrupts off and reads the keyboard on
    every turn of its loop, so a key held for 0.3 s is seen whatever the
    moment. Holding 0 starts the game."""
    from skoolkit import CSimulator
    from skoolkit.simulator import Simulator
    from skoolkit.simutils import PC, T

    memory = ba.machine_memory(Path(snapshot))
    sim = (CSimulator or Simulator)(memory, state={"iff": 0, "im": 1, "tstates": 0})
    tracer = _key_tracer_class()(sim)
    sim.set_tracer(tracer)
    pc = ba.ENTRY
    for keys, seconds in [([], 3.0), (["1"], 0.3), ([], 0.5), ([character], 0.3),
                          ([], 0.5), (["0"], 1.0)]:
        tracer.keys = set(keys)
        stop = START_GAME if keys == ["0"] else 0
        sim.trace(pc, stop, 0, sim.registers[T] + int(seconds * TSTATES_PER_SECOND),
                  True, None, None, None, None, None)
        pc = sim.registers[PC]
    if pc != START_GAME:
        raise RuntimeError("the title screen did not start a game")
    game = Game(sim.memory, list(sim.registers[:29]))
    started = game.copy()
    game.keys(["0"])
    game.frames(15)             # let go of 0 a moment later, as a person would
    game.keys(())
    for _ in range(2000):
        game.frame()
        if 0 < game.memory[PLAYER] <= 0x30:
            break
    else:
        raise RuntimeError("the player never came into play")
    return (tuple(started.memory), tuple(started.registers)), \
        (tuple(game.memory), tuple(game.registers))


class Game:
    """A game in progress in SkoolKit's simulator, a machine of its own made
    from a saved state, so a scene can be staged, run and thrown away without
    spoiling the next one."""

    def __init__(self, memory, registers):
        from skoolkit import CSimulator
        from skoolkit.simulator import Simulator
        from skoolkit.simutils import IFF, IM, T

        state = {"iff": registers[IFF], "im": registers[IM], "tstates": registers[T]}
        self.sim = (CSimulator or Simulator)(list(memory), state=state)
        for index, value in enumerate(registers[:T + 1]):
            self.sim.registers[index] = value
        self.tracer = _key_tracer_class()(self.sim)
        self.sim.set_tracer(self.tracer)

    @classmethod
    def at_start(cls, snapshot: Path) -> "Game":
        """Stopped at START_GAME, the knight chosen: the castle not yet set up."""
        (memory, registers), _ = _start_state(str(snapshot), "4")
        return cls(memory, registers)

    @classmethod
    def playing(cls, snapshot: Path, character: str = "knight") -> "Game":
        """Stopped at the first FRAME_TICK with the player in play, in room $00."""
        code = {v: k for k, v in CHARACTERS.items()}[character]
        _, (memory, registers) = _start_state(str(snapshot), code)
        return cls(memory, registers)

    def copy(self) -> "Game":
        return Game(self.sim.memory, self.registers)

    @property
    def registers(self) -> list:
        return list(self.sim.registers[:29])

    @property
    def memory(self):
        return self.sim.memory

    @property
    def pc(self) -> int:
        from skoolkit.simutils import PC
        return self.sim.registers[PC]

    @property
    def tstates(self) -> int:
        from skoolkit.simutils import T
        return self.sim.registers[T]

    def reg(self, name: str) -> int:
        from skoolkit.simutils import REGISTERS
        if len(name) == 2 and name not in ("SP", "PC"):
            if name in ("IX", "IY"):
                return (self.sim.registers[REGISTERS[name + "h"]] << 8
                        | self.sim.registers[REGISTERS[name + "l"]])
            return (self.sim.registers[REGISTERS[name[0]]] << 8
                    | self.sim.registers[REGISTERS[name[1]]])
        return self.sim.registers[REGISTERS[name]]

    def set_reg(self, name: str, value: int) -> None:
        from skoolkit.simutils import REGISTERS
        if len(name) == 2 and name not in ("SP", "PC"):
            high, low = (name + "h", name + "l") if name in ("IX", "IY") else (name[0], name[1])
            self.sim.registers[REGISTERS[high]] = value >> 8
            self.sim.registers[REGISTERS[low]] = value & 0xFF
        else:
            self.sim.registers[REGISTERS[name]] = value

    def keys(self, keys=()) -> None:
        self.tracer.keys = set(keys)

    def until(self, stops, keys=None, limit: int = RUN_LIMIT) -> int:
        """Run on (at least one instruction), interrupts on as the game has
        them, until PC is one of `stops`; with `keys` held if given. Returns
        the address stopped at."""
        from skoolkit.simutils import PC, T

        if isinstance(stops, int):
            stops = (stops,)
        if keys is not None:
            self.keys(keys)
        end = self.sim.registers[T] + limit
        while True:
            if len(stops) == 1:
                self.sim.trace(self.sim.registers[PC], stops[0], 0, end,
                               True, None, None, None, None, None)
            else:
                self._until_any(stops, end)
            if self.sim.registers[PC] in stops:
                return self.sim.registers[PC]
            if self.sim.registers[T] >= end:
                raise RuntimeError(f"stopped at ${self.sim.registers[PC]:04X} waiting for "
                                   + ", ".join(f"${s:04X}" for s in stops))

    def _until_any(self, stops, end: int) -> None:
        """Step, with interrupts, until PC is in `stops`."""
        from skoolkit.simutils import PC, T

        stop_set = set(stops)
        registers = self.sim.registers
        while registers[T] < end:
            self.step()
            if registers[PC] in stop_set:
                return

    def step(self) -> None:
        """One instruction, then an interrupt if one is due: the ULA holds
        the line for 32 T-states from the start of each frame, and the Z80
        takes it at the end of an instruction if interrupts are on."""
        from skoolkit.simutils import PC, T

        registers = self.sim.registers
        pc = registers[PC]
        self.sim.run()
        after = registers[T]
        if after % FRAME_TSTATES < 32 and registers[26]:
            self.sim.accept_interrupt(registers, self.sim.memory, pc)

    def frame(self, keys=None) -> None:
        """On to the next FRAME_TICK: one 50Hz frame of the player's."""
        self.until(FRAME_TICK, keys)

    def frames(self, count: int, keys=None) -> None:
        for _ in range(count):
            self.frame(keys)

    def pass_(self, keys=None) -> None:
        """On to the top of the next main-loop pass."""
        self.until(MAIN_LOOP, keys)

    def passes(self, count: int, keys=None) -> None:
        for _ in range(count):
            self.pass_(keys)

    def call(self, address: int, registers: dict | None = None,
             limit: int = RUN_LIMIT) -> int:
        """Run a routine to its return, interrupts off; the T-states it took.
        The return address is $0000's first byte in RAM terms -- $5B00, in the
        printer buffer, which nothing in the game uses."""
        from skoolkit.simutils import PC, SP, T

        saved = self.registers
        sp = 0x5B80
        self.memory[sp] = 0x00
        self.memory[sp + 1] = 0x5B
        self.sim.registers[SP] = sp
        self.sim.registers[26] = 0
        for name, value in (registers or {}).items():
            self.set_reg(name, value)
        start = self.sim.registers[T]
        self.sim.registers[PC] = address
        self.sim.trace(address, 0x5B00, 0, start + limit, False, None, None, None, None, None)
        if self.sim.registers[PC] != 0x5B00:
            raise RuntimeError(f"${address:04X} did not return (at ${self.pc:04X})")
        taken = self.sim.registers[T] - start
        keep_t = self.sim.registers[T]
        for index, value in enumerate(saved):
            self.sim.registers[index] = value
        self.sim.registers[T] = keep_t
        return taken

    # Reading and staging.

    def word(self, address: int) -> int:
        return self.memory[address] | self.memory[address + 1] << 8

    def record(self, address: int, length: int = 16) -> list[int]:
        return [self.memory[address + k] for k in range(length)]

    def put(self, address: int, values) -> None:
        for offset, value in enumerate(values):
            self.memory[address + offset] = value & 0xFF

    def calm(self) -> None:
        """No small creatures: the three slots emptied and the spawner's
        countdown put back to its start (see SPAWN_MONSTER_INTO_ROOM)."""
        for slot in CREATURE_SLOTS:
            self.put(slot, [0] * 16)
        self.memory[SPAWN_COUNTDOWN] = 0x20
        self.memory[SPAWN_ROOM] = self.memory[ROOM]

    def park_big_five(self) -> None:
        """Every big monster into room $95, the black entry nobody visits."""
        for _, record, _ in BIG_FIVE:
            self.memory[record + 1] = 0x95

    def score(self) -> int:
        return int("".join(f"{self.memory[SCORE + k]:02X}" for k in range(3)))

    def clock(self) -> str:
        h, m, s = (self.memory[CLOCK + k] for k in range(3))
        return f"{h:X}:{m:02X}:{s:02X}"

    def player(self) -> tuple[int, int, int]:
        return self.memory[ROOM], self.memory[PLAYER_X], self.memory[PLAYER_Y]

    def in_play(self) -> bool:
        return 0 < self.memory[PLAYER] <= 0x30

    def carry(self, slot: int, record: int, sprite: int, colour: int) -> None:
        """Put an object in an inventory slot as REMEMBER_CARRIED does: the
        record's address, its sprite and colour; the record itself emptied."""
        self.put(CARRIED + 4 * slot, [record & 0xFF, record >> 8, sprite, colour])
        self.memory[record] = 0

    def room_list(self, room: int) -> list[int]:
        """The records a room's list names, each at the half in that room."""
        pointer = self.word(ROOM_CONTENTS + 2 * room)
        out = []
        while True:
            entry = self.word(pointer)
            if entry == 0:
                return out
            address = (entry - ROOM_CONTENTS) & 0xFFFF
            out.append(address if self.memory[address + 1] == room else address + 8)
            pointer += 2


def room_list(memory, room: int) -> list[int]:
    pointer = memory[ROOM_CONTENTS + 2 * room] | memory[ROOM_CONTENTS + 2 * room + 1] << 8
    out = []
    while True:
        entry = memory[pointer] | memory[pointer + 1] << 8
        if entry == 0:
            return out
        address = (entry - ROOM_CONTENTS) & 0xFFFF
        out.append(address if memory[address + 1] == room else address + 8)
        pointer += 2


# --------------------------------------------------------------------------
# Pictures.
# --------------------------------------------------------------------------

def screen_image(memory, columns=(0, 32), rows=(0, 24), attributes: bool = True):
    """The screen as the Spectrum shows it (FLASH shown as its first phase),
    or ink black on white without the attributes."""
    from PIL import Image

    left, right = columns
    top, bottom = rows
    image = Image.new("RGB", (8 * (right - left), 8 * (bottom - top)))
    pixels = image.load()
    for row in range(top, bottom):
        for column in range(left, right):
            attr = memory[0x5800 + 32 * row + column]
            if attributes:
                bright = (attr >> 6) & 1
                ink, paper = PALETTE[bright][attr & 7], PALETTE[bright][(attr >> 3) & 7]
            else:
                ink, paper = (0, 0, 0), (255, 255, 255)
            for line in range(8):
                y = 8 * row + line
                address = 0x4000 + ((y & 0xC0) << 5) + ((y & 7) << 8) + ((y & 0x38) << 2) + column
                byte = memory[address]
                for bit in range(8):
                    pixels[8 * (column - left) + bit, 8 * (row - top) + line] = \
                        ink if byte & (0x80 >> bit) else paper
    return image


def play_area(memory):
    return screen_image(memory, (0, 24), (0, 24))


def panel(memory):
    return screen_image(memory, (24, 32), (0, 24))


def changed_image(memory, before, columns=(0, 24), rows=(0, 24)):
    """The screen with every pixel and cell that differs from `before` marked:
    changed pixels red on the picture as shown."""
    image = screen_image(memory, columns, rows)
    pixels = image.load()
    left, top = columns[0], rows[0]
    for y in range(8 * top, 8 * rows[1]):
        for column in range(left, columns[1]):
            address = 0x4000 + ((y & 0xC0) << 5) + ((y & 7) << 8) + ((y & 0x38) << 2) + column
            diff = memory[address] ^ before[address]
            if not diff:
                continue
            for bit in range(8):
                if diff & (0x80 >> bit):
                    pixels[8 * (column - left) + bit, y - 8 * top] = MARK
    return image


def crop_around(image, x: int, y: int, width: int, height: int):
    left = max(0, min(image.width - width, x - width // 2))
    top = max(0, min(image.height - height, y - height // 2))
    return image.crop((left, top, left + width, top + height))


def strip(images, gap: int = 4, background=(40, 40, 60)):
    from PIL import Image

    width = sum(i.width for i in images) + gap * (len(images) - 1)
    height = max(i.height for i in images)
    out = Image.new("RGB", (width, height), background)
    x = 0
    for image in images:
        out.paste(image, (x, 0))
        x += image.width + gap
    return out


def save(image, image_dir: Path, name: str):
    image.save(image_dir / name)
    return image


def img(name: str, image, alt: str = "", scale: int = 2, shrink: bool = True) -> str:
    fit = " max-width: 100%; height: auto;" if shrink else ""
    alt = html.escape(plain(alt), quote=False).replace('"', "&quot;")
    return (f'<img src="{IMAGE_DIR}/{name}" alt="{alt}" '
            f'width="{image.width * scale}" height="{image.height * scale}" '
            f'style="image-rendering: pixelated; image-rendering: crisp-edges;{fit}">')


def plain(text: str) -> str:
    """Text for an attribute: no tags, and no skool macros."""
    text = re.sub(r"<[^>]+>", "", text)
    text = re.sub(r"#R\$([0-9A-F]{4})(\([^)]*\))?",
                  lambda match: (match.group(2) or "")[1:-1] or "$" + match.group(1), text)
    return text.replace("&ndash;", "-").replace("&amp;", "and").replace("&#35;", "")


def figure(name: str, image, caption: str, scale: int = 2) -> str:
    return (f'<div style="display: inline-block; vertical-align: top; margin: 0 12px 12px 0; '
            f'max-width: {max(image.width * scale + 4, 200)}px">'
            f'{img(name, image, caption, scale)}'
            f'<p style="margin: 4px 0 0 0; font-size: 0.9em">{caption}</p></div>')


def table(headers, rows) -> str:
    head = "".join(f"<th>{h}</th>" for h in headers)
    body = "".join("<tr>" + "".join(f"<td>{c}</td>" for c in row) + "</tr>" for row in rows)
    return f'<table class="default"><tr>{head}</tr>{body}</table>'


def evidence(confirmed, inferred) -> str:
    """The page's closing split: what was run or read, and what is inferred."""
    return ("<h3>What is confirmed and what is inferred</h3>"
            "<ul>" + "".join(f"<li>{item}</li>" for item in confirmed) + "</ul>"
            + ("<p>Inferred, or not tried:</p><ul>"
               + "".join(f"<li>{item}</li>" for item in inferred) + "</ul>" if inferred else ""))


# --------------------------------------------------------------------------
# Links into the listing.
# --------------------------------------------------------------------------

_ENTRY_RE = re.compile(r"^[bcgistuw]\$([0-9A-F]{4})\s")


@functools.lru_cache(maxsize=None)
def _entries(skool: str) -> frozenset:
    path = Path(skool)
    if not path.exists():
        return frozenset()
    found = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        match = _ENTRY_RE.match(line)
        if match:
            found.add(int(match.group(1), 16))
    return frozenset(found)


class Links:
    """#R$ADDR where the address starts an entry in the skool file, plain
    $ADDR otherwise (an entry point inside a routine); read at build time,
    since the entries change as the disassembly does."""

    def __init__(self, skool: Path):
        self.entries = _entries(str(skool))
        self.sorted_entries = sorted(self.entries)
        self.labels = dict(_labels(str(skool)))
        self.missing: set[int] = set()

    def __call__(self, address: int, text: str | None = None) -> str:
        if address in self.entries:
            return f"#R${address:04X}" + (f"({text})" if text else "")
        # A labelled place inside a routine: its name, linked to the entry
        # that holds it.
        label = self.labels.get(address)
        container = [a for a in self.sorted_entries if a <= address]
        if label and container:
            return f"#R${container[-1]:04X}({text or label})"
        self.missing.add(address)
        return text + f" (${address:04X})" if text else f"${address:04X}"


def hexb(value: int) -> str:
    return f"${value:02X}"


def room_ref(memory, room: int) -> str:
    """A room, linked to its list in the listing."""
    return ba.room_link(memory, room)


def colour_word(attr: int) -> str:
    return COLOUR_NAMES[attr & 7]


_LABEL_RE = re.compile(r"^@label=(\S+)")
_INSTRUCTION_RE = re.compile(r"^[bcgistuw* ]\$([0-9A-F]{4})\s")


@functools.lru_cache(maxsize=None)
def _labels(skool: str) -> tuple:
    """Every labelled address in the listing, sorted: (address, label)."""
    path = Path(skool)
    if not path.exists():
        return ()
    found = []
    pending = None
    for line in path.read_text(encoding="utf-8").splitlines():
        match = _LABEL_RE.match(line)
        if match:
            pending = match.group(1)
            continue
        match = _INSTRUCTION_RE.match(line)
        if match and pending:
            found.append((int(match.group(1), 16), pending))
        if not line.startswith("@"):
            pending = None
    return tuple(sorted(found))


class Profile:
    """T-states charged to the labelled piece of code each instruction is in,
    by running the game with SkoolKit's per-instruction trace hook: each
    instruction's cost is the time to the next one's start, so an interrupt
    taken after it is charged to it too (and the ROM's handler to the ROM).
    SkoolKit's machine has no memory contention, so these are the Z80's own
    timings, a floor under what a real Spectrum takes."""

    def __init__(self, skool: Path):
        import bisect

        self.labels = _labels(str(skool))
        self.addresses = [a for a, _ in self.labels]
        self.bisect = bisect.bisect_right
        self.counts: dict[str, int] = {}
        self.by_kind: dict[str, int] = {}
        self.first_address: dict[str, int] = {}

    def name(self, pc: int) -> str:
        if pc < 0x4000:
            return "the ROM (the frame interrupt)"
        index = self.bisect(self.addresses, pc) - 1
        if index < 0:
            return "below the game"
        address, label = self.labels[index]
        self.first_address[label] = address
        return label

    def run(self, game: Game, stop: int, keys=None) -> int:
        """Run `game` on to `stop` (at least one instruction), charging the
        time; returns the T-states it took."""
        if keys is not None:
            game.keys(keys)
        log = []

        def df(pc):
            return ""

        def tf(pc, i, t0):
            log.append((pc, t0))

        registers = game.sim.registers
        contexts = []
        state = {"now": "loop"}

        def tf_context(pc, i, t0):
            # Who the time is spent for: the record being dispatched, read
            # from IX as the dispatcher jumps to its handler, or the loop.
            if pc == DISPATCH_JUMP:
                state["now"] = record_kind(registers[IXH] << 8 | registers[IXL])
            elif pc == FRAME_TICK:
                state["now"] = "frame"
            elif pc == FRAME_TICK_RET:
                state["now"] = "loop"
            elif PASS_HOUSEKEEPING <= pc < DISPATCH_ACTOR:
                state["now"] = "housekeeping"
            elif MAIN_LOOP <= pc < DISPATCH_ACTOR or pc == LIST_ENTRY_DONE:
                state["now"] = "loop"
            log.append((pc, t0))
            contexts.append(state["now"] if pc >= 0x4000 else "interrupt")

        start = game.tstates
        game.sim.trace(game.pc, stop, 0, start + RUN_LIMIT, True, None, None, None, df,
                       tf_context)
        if game.pc != stop:
            raise RuntimeError(f"profile: stopped at ${game.pc:04X}")
        end = game.tstates
        for index, (pc, t0) in enumerate(log):
            t1 = log[index + 1][1] if index + 1 < len(log) else end
            name = self.name(pc)
            self.counts[name] = self.counts.get(name, 0) + t1 - t0
            kind = contexts[index]
            self.by_kind[kind] = self.by_kind.get(kind, 0) + t1 - t0
        return end - start


DISPATCH_JUMP = 0x7E90          # DISPATCH_ACTOR's JP $5CB0: IX is the record
FRAME_TICK_RET = 0x7EE5
PASS_HOUSEKEEPING = 0x7E44      # MAIN_LOOP after the room list: TICKS and the rest
IXH, IXL = 8, 9                 # SkoolKit's register indices


def record_kind(address: int) -> str:
    """What a runtime record is, by where it lies."""
    if address == PLAYER:
        return "the player"
    if address == WEAPON:
        return "the weapon"
    if address == SOUND_SLOT:
        return "the sound slot"
    if address == DROP_CONTROLLER:
        return "the drop controller"
    if 0xEAA8 <= address < DROP_CONTROLLER:
        return "objects, food and mushrooms"
    if CREATURE_SLOTS[0] <= address < MUMMY:
        return "the three creature slots"
    if MUMMY <= address < LIVE_DOORS:
        return "the big five"
    if address >= LIVE_DOORS:
        return "doors and furniture"
    if address in (SCRATCH_RECORDS):
        return "the scroll"
    return "other"


SCRATCH_RECORDS = (0xA17D, 0x8C2D)   # UI_RECORD and FOOD_RECORD: the scroll's pictures


# --------------------------------------------------------------------------
# Drawing: a room entered, stage by stage.
# --------------------------------------------------------------------------

# The room followed is $00, where every game starts: the richest room near the
# start, with doors in three walls, the A.C.G. door and eight pieces of
# furniture. It is entered for real: the knight walks out through its south
# door into room $07 and, after ARRIVE_WAIT frames there, back up through the
# same door. Nothing is staged.
ARRIVE_WAIT = 20
ARRIVAL_STAGES = [
    # (stop, key, what has just happened)
    (0x914D, "seen", "MARK_ROOM_VISITED"),
    (0x9150, "clear", "CLEAR_PLAY_AREA"),
    (ROOM_FLOODED, "flood", "DRAW_ROOM, the flood"),
    (0x9153, "outline", "DRAW_ROOM, the outline"),
    (0x9156, "panel", "PAINT_PANEL"),
    (0x9159, "inventory", "DRAW_INVENTORY"),
    (MAIN_LOOP, "sound", "PLAY_SOUND_NEW_ROOM"),
]


def walk_through(game: Game, keys, room_now: int, limit_frames: int = 200) -> int:
    """Hold `keys` until the player is in another room; the frames it took."""
    for count in range(1, limit_frames + 1):
        game.frame(keys)
        if game.memory[ROOM] != room_now:
            return count
    raise RuntimeError(f"still in room ${room_now:02X} after {limit_frames} frames")


def follow_arrival(snapshot: Path) -> dict:
    """Walk into room $00 from room $07 and stop after every stage of
    ENTER_ROOM, ARRIVE_IN_ROOM and the first main-loop pass: the memory and
    the T-states each took."""
    game = Game.playing(snapshot)
    game.calm()
    out_frames = walk_through(game, [DOWN], 0)
    game.frames(ARRIVE_WAIT, [])
    game.calm()
    game.until(ENTER_ROOM, [UP])
    result = {"out_frames": out_frames, "from_room": game.memory[ROOM],
              "door": game.reg("IX"), "at_door": bytes(game.memory),
              "at_player": game.player(), "stages": [], "entries": []}
    start = game.tstates
    for stop, key, what in ARRIVAL_STAGES:
        before = game.tstates
        game.until(stop)
        result["stages"].append((key, what, game.tstates - before, bytes(game.memory)))
    # The first pass: DRAW_ROOM cleared ROOM_DRAWN, so the loop goes straight
    # to the room's list, whose handlers draw each door and piece of furniture
    # in full, then DRAW_ROOM_CONTENTS draws everything else in the room.
    game.until(LIST_ENTRY_DONE)
    names = game.room_list(game.memory[ROOM])
    previous = bytes(game.memory)
    for address in names:
        before = game.tstates
        game.until(LIST_ENTRY_DONE)
        result["entries"].append((address, game.tstates - before, previous, bytes(game.memory)))
        previous = bytes(game.memory)
    before = game.tstates
    game.until(AFTER_CONTENTS)
    result["contents"] = (game.tstates - before, previous, bytes(game.memory))
    game.until(MAIN_LOOP)
    result["first_pass_end"] = bytes(game.memory)
    result["total"] = game.tstates - start
    frames = 0
    while game.memory[PLAYER + 2] & 0x0F:
        game.frame([UP])
        frames += 1
    result["walk_in_frames"] = frames
    game.frame([])
    result["walked_in"] = bytes(game.memory)
    result["game"] = game
    return result


def changed_box(before, after, columns=(0, 24), rows=(0, 24)):
    """The pixel box (left, top, right, bottom) of every screen byte and
    attribute cell that differs, or None."""
    cells = set()
    for row in range(rows[0], rows[1]):
        for column in range(columns[0], columns[1]):
            if before[0x5800 + 32 * row + column] != after[0x5800 + 32 * row + column]:
                cells.add((column, row))
            for line in range(8):
                y = 8 * row + line
                address = 0x4000 + ((y & 0xC0) << 5) + ((y & 7) << 8) + ((y & 0x38) << 2) + column
                if before[address] != after[address]:
                    cells.add((column, row))
                    break
    if not cells:
        return None
    left = min(c for c, _ in cells) * 8
    right = (max(c for c, _ in cells) + 1) * 8
    top = min(r for _, r in cells) * 8
    bottom = (max(r for _, r in cells) + 1) * 8
    return left, top, right, bottom


def draw_in_mode(game: Game, kind: int, mode: int, room_colour: int = 0x45,
                 size=(6, 8)):
    """One furniture graphic drawn by the game's own drawers on a blank
    screen: DRAW_SPRITE_PIXELS and DRAW_SPRITE_COLOURS, as DRAW_DOOR calls
    them, with its bottom-left corner at (8, 8 * rows - 1)."""
    h = game.copy()
    for address in range(0x4000, 0x5800):
        h.memory[address] = 0
    for address in range(0x5800, 0x5B00):
        h.memory[address] = 0x07
    h.memory[ROOM_COLOUR] = room_colour
    bottom = 8 * size[1] - 1
    h.call(DRAW_SPRITE_PIXELS, {"B": mode << 5, "C": kind, "D": bottom, "E": 0x08})
    h.call(DRAW_SPRITE_COLOURS, {"B": mode << 5, "C": kind, "D": bottom - 1, "E": 0x08})
    return h


def ink_bitmap(memory, columns: int, rows: int):
    """The set pixels of the top-left of the screen as a 1-bit picture,
    cropped to what is set."""

    image = screen_image(memory, (0, columns), (0, rows), attributes=False).convert("L")
    image = image.point(lambda v: 255 if v < 128 else 0).convert("1")
    box = image.getbbox()
    return image.crop(box) if box else image


def diff_image(before, after, box):
    """The pixels in `box` (left, top, right, bottom): white if set in both,
    red if rubbed out since `before`, green if newly set."""
    from PIL import Image

    left, top, right, bottom = box
    image = Image.new("RGB", (right - left, bottom - top))
    pixels = image.load()
    for y in range(top, bottom):
        for x in range(left, right):
            address = 0x4000 + ((y & 0xC0) << 5) + ((y & 7) << 8) + ((y & 0x38) << 2) + (x >> 3)
            mask = 0x80 >> (x & 7)
            was, now = before[address] & mask, after[address] & mask
            pixels[x - left, y - top] = ((255, 255, 255) if was and now else (230, 40, 40) if was
                                         else (40, 220, 40) if now else (0, 0, 0))
    return image


def stray_pixels(memory, x: int, y: int, rows: int, colour: int) -> int:
    """How many set pixels of a sprite's rows (16 wide from x, `rows` up from
    y) stand in a cell whose attribute is not `colour`."""
    count = 0
    for line in range(y - rows + 1, y + 1):
        for column in range(x, x + 16):
            address = 0x4000 + ((line & 0xC0) << 5) + ((line & 7) << 8) + ((line & 0x38) << 2)                 + (column >> 3)
            if memory[address] & (0x80 >> (column & 7)):
                if memory[0x5800 + 32 * (line >> 3) + (column >> 3)] != colour:
                    count += 1
    return count


def match_transform(stored, drawn) -> str:
    """Which of the eight symmetries of a rectangle takes the picture as
    stored to the picture drawn -- tried with PIL, pixel for pixel."""
    from PIL import Image

    candidates = [
        ("as stored", None),
        ("mirrored left to right", Image.Transpose.FLIP_LEFT_RIGHT),
        ("turned a quarter clockwise", Image.Transpose.ROTATE_270),
        ("turned a quarter anticlockwise", Image.Transpose.ROTATE_90),
        ("upside down", Image.Transpose.FLIP_TOP_BOTTOM),
        ("turned a half turn", Image.Transpose.ROTATE_180),
        ("reflected in the leading diagonal (top-left to bottom-right)", Image.Transpose.TRANSPOSE),
        ("reflected in the other diagonal (bottom-left to top-right)", Image.Transpose.TRANSVERSE),
    ]
    found = []
    for name, operation in candidates:
        image = stored if operation is None else stored.transpose(operation)
        if image.size == drawn.size and list(image.getdata()) == list(drawn.getdata()):
            found.append(name)
    return " or ".join(found) if found else "none of the eight"


ROW_ERASE_START = 0x9EDC      # FETCH_ROW: the erase side reads a row of the old picture
ROW_DRAW_START = 0x9F21       # SHIFT_AND_PLOT: the draw side reads a row of the new one
SCREEN_STORES = (0x9ED2, 0x9ED6, 0x9EF7, 0x9EFB, 0x9EFF, 0x9F17, 0x9F1B, 0x9F3C)
FILLER_ENTRIES = {}


def screen_line(address: int) -> int:
    """The pixel line of a display-file address."""
    high, low = address >> 8, address & 0xFF
    return ((high & 0x18) << 3) | ((low & 0xE0) >> 2) | (high & 0x07)


def trace_redraw(game: Game, keys) -> dict:
    """Follow one frame's redraw of the player, from REDRAW_ACTOR, one
    instruction at a time: every row the erase and the draw sides put on the
    screen, in order, with the screen after each; then which colour filler
    DRAW_FROM_RECORD chose. The game is left at the next FRAME_TICK."""
    game.frame(keys)
    game.until(PLAYER_TICK)
    game.until(REDRAW_ACTOR)
    record = game.record(PLAYER, 8)
    result = {"old": (game.memory[WORK_SPRITE], game.memory[WORK_SPRITE + 1],
                      game.memory[WORK_SPRITE + 2]),
              "new": (record[0], record[X], record[Y]), "rows": [],
              "before": bytes(game.memory), "attr_before": bytes(game.memory)}
    side = None
    game.step()                                     # into REDRAW_MOVED
    result["jr"] = None
    while game.pc != REDRAW_ACTOR + 3:
        pc = game.pc
        if pc == ROW_ERASE_START:
            side = "erase"
        elif pc == ROW_DRAW_START:
            side = "draw"
            if result["jr"] is None:
                result["jr"] = game.memory[DRAW_JR + 1]
        elif pc in SCREEN_STORES and side is not None:
            line = screen_line(game.reg("HL"))
            if not result["rows"] or result["rows"][-1][:2] != (side, line):
                result["rows"].append((side, line, None))
        game.step()
        if pc in SCREEN_STORES and result["rows"]:
            side_now, line_now, _ = result["rows"][-1]
            result["rows"][-1] = (side_now, line_now, bytes(game.memory))
    result["after_pixels"] = bytes(game.memory)
    result["height"] = game.memory[0x5E11]
    # DRAW_FROM_RECORD, to the filler it jumps to through JP (HL).
    fillers = {game.word(COLOUR_FILLERS + 2 * k): k for k in range(11)}
    while game.pc not in fillers:
        game.step()
    result["filler"] = (game.pc, fillers[game.pc])
    game.until(FRAME_TICK)
    result["after"] = bytes(game.memory)
    return result


WALL_OF_MODE = {0: "north", 4: "south", 3: "east", 7: "west"}
TIMED_NAMES = {0x20: "timed door, shut", 0x21: "timed door, open",
               0x22: "timed cave door, shut", 0x23: "timed cave door, open",
               0x18: "trapdoor, closed"}
WALL_FURNITURE = (0x11, 0x15, 0x16, 0x1C, 0x1D, 0x1E, 0x25)


def record_name(kind: int) -> str:
    """A door's or piece of furniture's type in words."""
    if kind in TIMED_NAMES:
        return TIMED_NAMES[kind]
    return ba.furniture_name(kind)


def handler_of(memory, kind: int) -> int:
    """The handler a room record of this type is dispatched to."""
    entry = ROOM_HANDLERS + 2 * kind
    return memory[entry] | memory[entry + 1] << 8


def span_text(values) -> str:
    low, high = min(values), max(values)
    return f"{low:,}" if low == high else f"{low:,} &ndash; {high:,}"


def rows_summary(rows) -> str:
    """The erase-and-draw order in words: runs of one side alone, and runs of
    pairs (an erase and a draw on the same line)."""
    parts = []
    index = 0
    while index < len(rows):
        side, line, _ = rows[index]
        paired = (index + 1 < len(rows) and side == "erase" and rows[index + 1][0] == "draw"
                  and rows[index + 1][1] == line)
        if paired:
            first = line
            count = 0
            while (index + 1 < len(rows) and rows[index][0] == "erase"
                   and rows[index + 1][0] == "draw" and rows[index + 1][1] == rows[index][1]):
                last = rows[index][1]
                count += 1
                index += 2
            parts.append(f"{count} pairs, each erasing a row of the old picture and then "
                         f"drawing the new picture's row on the same line, from line {first} "
                         f"up to line {last}")
            continue
        run = [line]
        index += 1
        while index < len(rows) and rows[index][0] == side and not (
                index + 1 < len(rows) and rows[index][0] == "erase"
                and rows[index + 1][0] == "draw" and rows[index + 1][1] == rows[index][1]):
            run.append(rows[index][1])
            index += 1
        what = "the old picture's" if side == "erase" else "the new picture's"
        verb = "erased" if side == "erase" else "drawn"
        plural = len(run) > 1
        parts.append(f"{what} row{'s' if plural else ''} on line{'s' if plural else ''} "
                     f"{', '.join(str(v) for v in run)} {verb} on "
                     f"{'their' if plural else 'its'} own")
    return "; then ".join(parts)


def _drawing_page(snapshot: Path, image_dir: Path, link, log) -> str:
    from PIL import Image, ImageDraw

    log("  following room $00 as it is entered...")
    memory0 = ba.game_memory(snapshot)
    arrival = follow_arrival(snapshot)
    stages = {key: (what, taken, mem) for key, what, taken, mem in arrival["stages"]}
    room = 0
    room_colour = memory0[ROOM_TABLE + 2 * room]
    shape = memory0[ROOM_TABLE + 2 * room + 1]
    from_room = arrival["from_room"]
    game = arrival["game"]

    at_door = save(screen_image(arrival["at_door"]), image_dir, "draw_at_door.png")
    outline = save(screen_image(stages["outline"][2]), image_dir, "draw_outline.png")
    painted = save(screen_image(stages["panel"][2]), image_dir, "draw_panel.png")
    contents_taken, contents_before, contents_after = arrival["contents"]
    first_pass = save(play_area(arrival["first_pass_end"]), image_dir, "draw_first_pass.png")
    walked = save(screen_image(arrival["walked_in"]), image_dir, "draw_walked_in.png")

    entry_figures, entry_rows = [], []
    for number, (address, taken, before, after) in enumerate(arrival["entries"], 1):
        record = [after[address + k] for k in range(8)]
        kind, mode = record[0], record[MODE] >> 5
        box = changed_box(before, after)
        name = f"draw_entry{number:02d}.png"
        if box:
            left, top, right, bottom = box
            picture = play_area(after).crop((max(0, left - 8), max(0, top - 8),
                                             min(192, right + 8), min(192, bottom + 8)))
            picture = save(picture, image_dir, name)
            wall = WALL_OF_MODE.get(mode) if kind not in WALL_FURNITURE else None
            caption = (f"{number}. {html.escape(record_name(kind))}, mode {mode}"
                       + (f" ({wall} wall)" if wall else ""))
            entry_figures.append(figure(name, picture, caption))
        handler = handler_of(after, kind)
        entry_rows.append([str(number), f"{html.escape(record_name(kind))} ({hexb(kind)})",
                           str(mode), link(handler), f"{taken:,}"])

    # The time each stage of the arrival took.
    entries_total = sum(t for _, t, _, _ in arrival["entries"])
    stage_rows = [
        [f"{link(ENTER_ROOM)} and {link(MARK_ROOM_VISITED)}: the far side of the door, "
         "the new position and heading, the room's bit in ROOMS_SEEN", stages["seen"][1]],
        [f"{link(CLEAR_PLAY_AREA)}: 24 columns by 192 lines of zeros", stages["clear"][1]],
        [f"{link(DRAW_ROOM)}: the room's colour into 24 &times; 24 attributes", stages["flood"][1]],
        [f"{link(DRAW_ROOM)}: the outline ({link(DRAW_OUTLINE)}, {link(DRAW_LINE)}, a pixel "
         "at a time)", stages["outline"][1]],
        [f"{link(PAINT_PANEL)}: the scroll's colours", stages["panel"][1]],
        [f"{link(DRAW_INVENTORY)}: the three carried things", stages["inventory"][1]],
        [f"The first pass: the {len(arrival['entries'])} doors and pieces of furniture in the "
         "room's list", entries_total],
        [f"The first pass: {link(DRAW_ROOM_CONTENTS)}", contents_taken],
    ]
    accounted = sum(r[1] for r in stage_rows)
    stage_rows.append(["The rest: the new-room sound, the loop, the end of the pass",
                       arrival["total"] - accounted])
    stage_rows = [[what, f"{taken:,}", f"{100 * taken / arrival['total']:.0f}%"]
                  for what, taken in stage_rows]
    stage_rows.append(["<b>From the door to the second pass</b>", f"<b>{arrival['total']:,}</b>",
                       "100%"])
    arrival_frames = arrival["total"] / FRAME_TSTATES
    slowest = max(arrival["entries"], key=lambda e: e[1])
    slowest_kind = slowest[3][slowest[0]]
    slowest_mode = slowest[3][slowest[0] + MODE] >> 5
    mode0 = next(e for e in arrival["entries"] if e[3][e[0] + MODE] >> 5 == 0
                 and e[3][e[0]] in ba.DOOR_KINDS)

    # The eight modes, drawn by the game's own drawers.
    log("  drawing furniture in the eight modes...")
    playing = Game.playing(snapshot)
    demo_kinds = (0x1E, 0x02)
    stored = {kind: ink_bitmap(draw_in_mode(playing, kind, 0).memory, 6, 8) for kind in demo_kinds}
    mode_pictures = []
    for kind in demo_kinds:
        row = [screen_image(draw_in_mode(playing, kind, mode).memory, (0, 6), (0, 8))
               for mode in range(8)]
        mode_pictures.append(save(strip(row), image_dir, f"draw_modes_{kind:02X}.png"))
    matches = []
    for mode in range(8):
        found = [match_transform(stored[kind],
                                 ink_bitmap(draw_in_mode(playing, kind, mode).memory, 6, 8))
                 for kind in demo_kinds]
        matches.append(found[0] if len(set(found)) == 1 else " / ".join(found))

    uses = {}
    for address in range(TEMPLATE_DOORS, TEMPLATE_END, 8):
        kind = memory0[address]
        if kind == 0:
            continue
        is_door = kind in ba.DOOR_KINDS
        uses.setdefault(memory0[address + MODE] >> 5, [0, 0])[0 if is_door else 1] += 1
    mode_rows = []
    for mode in range(8):
        drawer = memory0[PIXEL_DRAWERS + 2 * mode] | memory0[PIXEL_DRAWERS + 2 * mode + 1] << 8
        colours = memory0[COLOUR_DRAWERS + 2 * mode] | memory0[COLOUR_DRAWERS + 2 * mode + 1] << 8
        doors, furniture = uses.get(mode, [0, 0])
        mode_rows.append([str(mode), hexb(mode << 5), link(drawer), link(colours),
                          matches[mode], str(doors), str(furniture)])
    unused_modes = [str(m) for m in range(8) if m not in uses]

    # Colour tables: what their cells say.
    keep_total = room_total = fixed_total = 0
    uses_room = set()
    for kind in range(1, 0x28):
        pointer = 0xA64E + 2 * (kind - 1)
        address = memory0[pointer] | memory0[pointer + 1] << 8
        width, height = memory0[address], memory0[address + 1]
        cells = [memory0[address + 2 + k] for k in range(width * height)]
        keep_total += cells.count(0)
        room_total += cells.count(0xFF)
        fixed_total += len(cells) - cells.count(0) - cells.count(0xFF)
        if 0xFF in cells:
            uses_room.add(record_name(kind))

    # One step of the player, followed through REDRAW_MOVED.
    log("  following one step through REDRAW_MOVED...")
    game.frames(3, [UP, RIGHT])
    traced = trace_redraw(game, [UP, RIGHT])
    old_sprite, old_x, old_y = traced["old"]
    new_sprite, new_x, new_y = traced["new"]
    rows = traced["rows"]
    unshared = next(i for i, r in enumerate(rows) if r[0] == "draw")
    moments = [traced["before"]] + [rows[i - 1][2] for i in
                                    (unshared, unshared + (len(rows) - unshared) // 2, len(rows))]
    crops = []
    box = (new_x - 12, new_y - 30, new_x + 28, new_y + 6)
    for mem in moments:
        picture = diff_image(traced["before"], mem, box)
        crops.append(picture.resize((picture.width * 4, picture.height * 4), Image.NEAREST))
    step_strip = save(strip(crops, gap=8), image_dir, "draw_step.png")
    filler_address, filler_index = traced["filler"]
    sprite_rows = traced["height"]
    rotated = ((sprite_rows >> 1) | (sprite_rows << 7)) & 0xFF
    rotated = ((rotated >> 1) | (rotated << 7)) & 0xFF
    rotated = (rotated + 1) & 0xFF
    rotated = ((rotated >> 1) | (rotated << 7)) & 0xFF
    block_cells = (rotated & 0x1F) + 1
    span_cells = new_y // 8 - (new_y - sprite_rows + 1) // 8 + 1
    stray = stray_pixels(traced["after"], new_x, new_y, sprite_rows, traced["after"][PLAYER + MODE])
    left, top = (new_x - 20) & 0xF8, (new_y - 36) & 0xF8
    attr_pics = []
    for mem in (traced["before"], traced["after"]):
        picture = screen_image(mem).crop((left, top, left + 56, top + 48))
        big = picture.resize((picture.width * 4, picture.height * 4), Image.NEAREST)
        draw = ImageDraw.Draw(big)
        for x in range(0, big.width, 32):
            draw.line([(x, 0), (x, big.height)], fill=(110, 110, 110))
        for y in range(0, big.height, 32):
            draw.line([(0, y), (big.width, y)], fill=(110, 110, 110))
        attr_pics.append(big)
    attr_strip = save(strip(attr_pics, gap=8), image_dir, "draw_step_colours.png")

    # The shift chain's entry for each x AND 7, as SETUP_SPRITE_DRAW writes it.
    shift_rows = []
    for low in range(8):
        h = game.copy()
        h.memory[PLAYER_X] = 0x58 | low
        h.call(SETUP_SPRITE_DRAW, {"IX": PLAYER})
        displacement = h.memory[DRAW_JR + 1]
        signed = displacement - 256 if displacement > 127 else displacement
        target = (DRAW_JR + 2 + signed) & 0xFFFF
        if target >= SHIFT_CHAIN:
            shifts = (SHIFT_CHAIN + 14 - target) // 2
            what = f"{shifts} shift{'s' if shifts != 1 else ''} left"
            where = f"{link(SHIFT_CHAIN)} + {target - SHIFT_CHAIN}"
        else:
            what = "none"
            where = link(target)
        shift_rows.append([str(low), hexb(displacement), where, what, str(h.memory[0x5E10])])

    filler_rows = []
    for index, name in enumerate(COLOUR_FILLER_NAMES):
        if name is None:
            continue
        address = memory0[COLOUR_FILLERS + 2 * index] | memory0[COLOUR_FILLERS + 2 * index + 1] << 8
        mark = " (this step)" if index == filler_index else ""
        filler_rows.append([str(index), name + mark, link(address)])

    # The scroll, in the two rooms.
    panels = save(strip([panel(arrival["at_door"]), panel(stages["panel"][2])], gap=8),
                  image_dir, "draw_panels.png")
    colour_from = memory0[ROOM_TABLE + 2 * from_room]

    # Where a pass's time goes.
    log("  profiling ten seconds in room $00...")
    profile = Profile(snapshot.with_name("aticatac.skool"))
    game.pass_()
    start = game.tstates
    lengths = []
    walk = [[RIGHT], [LEFT], [LEFT], [RIGHT], [UP], [DOWN]]
    while game.tstates - start < 10 * TSTATES_PER_SECOND:
        second = (game.tstates - start) // TSTATES_PER_SECOND
        lengths.append(profile.run(game, MAIN_LOOP, walk[second % 6]))
    elapsed = game.tstates - start
    passes = len(lengths)
    creatures_now = [game.memory[a] for a in CREATURE_SLOTS]
    total = sum(profile.by_kind.values())
    kind_text = {
        "the player": f"The player's handler: {link(MOVE_PLAYER)} and the collision tests, "
                      "the spawner, the drain, the redraw",
        "the three creature slots": "The three creature slots: movers and redraws, or "
                                    f"{link(INERT_SPRITE)}'s delay for an empty one",
        "doors and furniture": "Doors and furniture from the room's list: their colours",
        "loop": f"{link(MAIN_LOOP)} itself: walking 119 object records and 8 monster slots, "
                "checking FRAMES between each",
        "the big five": "The big five, wherever they are",
        "the sound slot": "The sound slot: effects beeped a frame at a time",
        "interrupt": "The ROM's frame interrupt",
        "the weapon": "The weapon",
        "the scroll": "The scroll's pictures (the roast, the inventory)",
        "housekeeping": "The end of the pass: the pick-up key, the pause, food regrowth",
        "frame": f"{link(FRAME_TICK)}'s own work and the clock",
        "objects, food and mushrooms": "Objects, food and mushrooms in the room",
        "the drop controller": f"The drop controller ({link(PUT_DOWN)})",
        "other": "Anything else",
    }
    kind_rows = [[kind_text.get(k, k), f"{v // passes:,}", f"{100 * v / total:.0f}%"]
                 for k, v in sorted(profile.by_kind.items(), key=lambda kv: -kv[1])
                 if 100 * v / total >= 0.5]
    top_rows = []
    for label, value in sorted(profile.counts.items(), key=lambda kv: -kv[1])[:12]:
        address = profile.first_address.get(label)
        name = link(address, label) if address is not None else label
        top_rows.append([name, f"{value // passes:,}", f"{100 * value / total:.1f}%"])
    per_pass = elapsed / passes

    lines = [
        "<p>Atic Atac draws a room once, when the player comes in, and from then on "
        "touches only what moves. A room is a flood of colour and a vector outline; "
        "its doors and furniture are wide pictures drawn once in any of eight "
        "orientations, with their colours repainted every pass; and the player, the "
        "creatures and the objects are sixteen-pixel sprites XORed onto the screen, "
        "each erased where it was and drawn where it is, a row at a time. This page follows "
        "a room being entered, stage by stage, through the game's own code in SkoolKit's "
        "simulator, then one step of the player, and ends with where the time goes.</p>",

        "<h3>The room followed</h3>",
        f"<p>Room {room_ref(memory0, room)}, where every game starts: a {colour_word(room_colour)} "
        f"square hall (shape {hexb(shape)}) with doors in three walls, the A.C.G. door in the "
        f"fourth, and eight pieces of furniture. Nothing was staged. A game was started from "
        "the title screen with the knight, as the build starts one; the knight walked down "
        f"through the south door into room {room_ref(memory0, from_room)} ({arrival['out_frames']} "
        f"frames holding E), waited {ARRIVE_WAIT} frames there, and walked back up (R) until "
        f"the door's handler, {link(DOOR)}, found him in its box and called {link(ENTER_ROOM)}. "
        "The screen at that moment, still showing the room he is leaving:</p>",
        figure("draw_at_door.png", at_door,
               f"Room ${from_room:02X} as ENTER_ROOM is called: the knight in the doorway at "
               f"the {'top' if arrival['at_player'][2] < PLAY_CENTRE[1] else 'bottom'}."),

        "<h3>1. The room: a flood and an outline</h3>",
        f"<p>{link(ENTER_ROOM)} swaps to the door's far half, which gives the new room and "
        "where the player appears (see <a href=\"Doors.html\">the doors</a>), then falls into "
        f"{link(ARRIVE_IN_ROOM)}: mark the room seen ({link(MARK_ROOM_VISITED)}), blank the "
        f"play area ({link(CLEAR_PLAY_AREA)}: the 24 left-hand columns, all 192 lines; the "
        f"scroll is left alone), draw the room ({link(DRAW_ROOM)}), colour the scroll "
        f"({link(PAINT_PANEL)}), redraw the inventory ({link(DRAW_INVENTORY)}) and start the "
        f"new-room sound ({link(PLAY_SOUND_NEW_ROOM)}).</p>",
        f"<p>{link(DRAW_ROOM)} reads the room's two bytes in {link(ROOM_TABLE)}, a colour and a "
        "shape. It fills all 576 attribute cells of the play area with the colour -- after "
        "which the screen still looks black, since there are no pixels in them yet -- and "
        f"copies the shape's walk limits from {link(ROOM_SHAPES)} to ROOM_HALF_WIDTH and "
        "ROOM_HALF_HEIGHT, which is all <a href=\"Movement.html\">collision</a> knows of the "
        f"room's shape. Then {link(DRAW_OUTLINE)} walks the shape's edge list and "
        f"{link(DRAW_LINE)} joins its corners a pixel at a time, ORing into the screen (every "
        "shape is drawn on <a href=\"RoomTypes.html\">the room types page</a>). After the "
        f"outline the scroll still wears the old room's colours, until {link(PAINT_PANEL)}:</p>",
        figure("draw_outline.png", outline, "After DRAW_ROOM: the outline, in the room's red. "
               "The scroll is still coloured for the room just left."),
        figure("draw_panel.png", painted, "After PAINT_PANEL: the scroll recoloured to match."),

        "<h3>2. The doors and furniture, from the room's list</h3>",
        f"<p>{link(DRAW_ROOM)} also clears ROOM_DRAWN, and on a pass with it clear "
        f"{link(MAIN_LOOP)} skips the objects and monsters and goes straight to the room's list "
        f"in {link(ROOM_CONTENTS)}. Each entry names a sixteen-byte door or furniture record "
        f"by its half in this room; {link(DISPATCH_FROM_LIST)} dispatches it to its type's "
        f"handler, and every handler ends in {link(DRAW_DOOR)}, which draws the colours and, "
        f"because ROOM_DRAWN is clear, the pixels too ({link(DRAW_RECORD)}). Room $00's list has "
        f"{len(arrival['entries'])} entries; the screen after each, cut to what it changed "
        "(the two south and west doors are timed doors, open at the time):</p>",
        "".join(entry_figures),
        table(["", "Record", "Mode", "Handler", "T-states"], entry_rows),
        f"<p>The dearest was the {html.escape(record_name(slowest_kind))} in mode "
        f"{slowest_mode}, at {slowest[1]:,} T-states, where the "
        f"{html.escape(record_name(mode0[3][mode0[0]]))} in the north wall, mode 0, took "
        f"{mode0[1]:,}. The A.C.G. door is the biggest graphic in the room and drawn in a "
        "turned mode, which costs most (below).</p>",

        "<h3>3. Everything else in the room</h3>",
        f"<p>At the end of that first pass {link(DRAW_ROOM_CONTENTS)} draws every object and "
        f"monster whose room byte is this room, once, with {link(DRAW_THING)} -- here only the "
        "knight himself, in the doorway -- and the loop sets ROOM_DRAWN. From the second pass "
        "on, the loop dispatches the objects and monsters again, each handler redrawing its "
        "own sprite when it moves, and the room list's handlers repaint only their "
        f"colours. The room at the end of that first pass, and after the "
        f"{arrival['walk_in_frames']} frames in which the knight walks himself in (the "
        "arrival walk, on <a href=\"Doors.html\">the doors page</a>):</p>",
        figure("draw_first_pass.png", first_pass, "The first pass done: the room complete, the "
               "knight on the south door."),
        figure("draw_walked_in.png", walked, "The arrival walk done."),
        f"<p>From the door to the second pass took {arrival['total']:,} T-states -- "
        f"{arrival_frames:.1f} frames, {arrival['total'] / TSTATES_PER_SECOND:.2f} of a "
        "second -- in which nothing else moved:</p>",
        table(["Stage", "T-states", "Share"], stage_rows),
        f"<p>The outline is the dearest part: every pixel of it is placed by a line stepper "
        f"whose slope comes from a shift-and-subtract division ({link(0xA379)}), and a square "
        "hall's outline is long.</p>",

        "<h3>Eight ways to lay a picture down</h3>",
        "<p>A door or piece of furniture is stored once, the right way up, and its +$05 byte "
        "says how to lay it down: the top three bits are a mode, 0-7, that picks one routine "
        f"from {link(PIXEL_DRAWERS)} for the pixels and one from {link(COLOUR_DRAWERS)} for the "
        "colours; bits 1-0 pick how the pixels meet the screen, written into each drawer's "
        f"loop by {link(SPRITE_COMBINE_OPCODE)} (0 store, 1 OR, 2 or 3 XOR). Below, two graphics "
        "-- the suit of armour, which is symmetrical neither way, and a door -- each drawn "
        "in all eight modes by the game's own DRAW_SPRITE_PIXELS and DRAW_SPRITE_COLOURS on "
        "a blank screen, modes 0 to 7 left to right:</p>",
        figure("draw_modes_1E.png", mode_pictures[0], "The suit of armour, modes 0-7.", scale=2),
        figure("draw_modes_02.png", mode_pictures[1], "A door, modes 0-7.", scale=2),
        "<p>Each drawn picture was then compared, pixel for pixel, with the stored picture "
        "put through each of the eight symmetries of a rectangle (by the Python imaging "
        "library), which gives the fifth column; the last two count the door and furniture "
        "halves in the castle's template drawn in each mode:</p>",
        table(["Mode", "+$05", "Pixels", "Colours", "The picture, as drawn", "Door halves",
               "Furniture halves"], mode_rows),
        f"<p>Mirroring costs the copy loop a <code>DEC DE</code> for an <code>INC DE</code> "
        f"and a trip through {link(REVERSE_BITS)} for each byte; turning upside down, one call "
        f"to {link(START_AT_LAST_ROW)} first; the four modes that turn or reflect in a diagonal "
        "build each screen byte from one bit of eight rows, which is why they are slower. A "
        "door's mode is its wall -- the picture of a door in the north wall, turned, serves the "
        "other three -- and bit 6, set for the four diagonal modes, is also what "
        f"{link(PLAYER_AT_DOOR)} reads as &ldquo;in a side wall&rdquo;. The labels of modes "
        "3 and 6 follow the drawers' loops, not the geometry: DRAW_FLIP_ANTIDIAGONAL reflects in the "
        "diagonal from bottom-left to top-right, and DRAW_FLIP_DIAGONAL in the one a "
        "mathematician would call the transpose. "
        + (f"Mode{'s' if len(unused_modes) > 1 else ''} {' and '.join(unused_modes)} "
           f"{'are' if len(unused_modes) > 1 else 'is'} in no record of the template. "
           if unused_modes else "") + "</p>",
        f"<p>The colour tables, one per graphic from {link(0xA64E)}, are a width and height "
        "in cells and a byte per cell, walked in the same order as the pixels. A byte of $00 "
        "leaves the cell as it is, $FF writes the room's colour, and anything else is written "
        f"as it is. Across the 39 tables there are {keep_total} cells of $00, {room_total} of "
        f"$FF and {fixed_total} of fixed colours; $FF is used by "
        f"{', '.join(html.escape(n) for n in sorted(uses_room))}. So those take the colour "
        "of whatever room they stand in, and the four coloured doors are one graphic with four "
        "colour tables. Since the colours are repainted on every pass, a creature that crosses "
        "a door leaves it coloured correctly again a moment later.</p>",

        "<h3>One step of a moving thing</h3>",
        "<p>The player, creatures and objects are drawn another way: sixteen pixels wide, any "
        "height, placed at any pixel and XORed on, so that drawing the same thing twice rubs it "
        f"out. A handler starts with {link(ACTOR_TO_WORKSPACE)}, which copies the sprite and "
        "position into the workspace before the record is moved, and ends by redrawing: "
        f"{link(REDRAW_MOVED)} sets up the new picture in one register bank "
        f"({link(SETUP_SPRITE_DRAW)}) and the old in the other ({link(SETUP_ERASE)}); "
        f"{link(ALIGN_ROWS)} deals with the rows the two do not share, and "
        f"{link(ERASE_DRAW_ROWS)} does the rest two at a time, swapping banks with EXX: erase a "
        "row of the old, draw a row of the new, bottom up.</p>",
        "<p>Followed in the simulator, one instruction at a time: in room $00, the knight "
        f"walking up and to the right, from ({hexb(old_x)}, {hexb(old_y)}) to ({hexb(new_x)}, "
        f"{hexb(new_y)}), sprite {hexb(old_sprite)} to {hexb(new_sprite)}. The "
        f"{sum(1 for r in rows if r[0] == 'erase')} rows erased and "
        f"{sum(1 for r in rows if r[0] == 'draw')} drawn went: {rows_summary(rows)}. So each "
        "line of the screen changes once, from old to new, and there is no moment at which the "
        "knight is missing. The pixels before, after the rows only the old picture had, "
        "halfway, and at the end, four times size: white where a pixel was set before and "
        "still is, red where it has been rubbed out, green where it has been drawn:</p>",
        figure("draw_step.png", step_strip, "One step, in four moments.", scale=1),
        "<p>The shift that places the sprite at its pixel costs no loop. Each row's two bytes "
        f"go into HL and A is cleared; {link(SHIFT_CHAIN)} is seven copies of "
        "<code>ADD HL,HL / ADC A,A</code>, each shifting the three bytes A, H, L one pixel "
        f"left, and {link(SETUP_SPRITE_DRAW)} writes the displacement of the JR in front of it "
        "so that the jump lands part-way down the chain. Run for each x AND 7 on a copy of the "
        "game, it writes:</p>",
        table(["x AND 7", "JR displacement", "Lands at", "Shift", "Columns touched"], shift_rows),
        "<p>Seven shifts left of three bytes leave the picture one pixel into the first byte, "
        "and no shift leaves it on the byte boundary, so the sprite's left edge is at x "
        "itself; with no shift only two columns are touched. The erase side has its own "
        f"chain and its own patched JR ({link(0x9EE6)}).</p>",
        f"<p>Then the colours. {link(DRAW_FROM_RECORD)} compares the old and new position to "
        f"choose one of the fillers in {link(COLOUR_FILLERS)}; each paints the thing's "
        "block of cells -- two columns, three when it is not on a cell boundary, as tall as the "
        "sprite -- in its own colour, and the column or row it has just left in the room's "
        "(two of the eleven entries, for combinations that cannot happen, point at "
        "INERT_SPRITE):</p>",
        table(["Index", "Movement", "Filler"], filler_rows),
        "<p>The cells round the knight before and after the same step, lines on the cell "
        "boundaries: the white block goes with him and the room's red comes back behind.</p>",
        figure("draw_step_colours.png", attr_strip, "The step's colours, before and after.",
               scale=1),
        f"<p>One line of the knight is left red, at the top of his helmet. "
        f"{link(DRAW_FROM_RECORD)} works the block's height out from the sprite's (its "
        f"rows over eight, by an RRCA sequence, plus one): the knight's {sprite_rows} rows "
        f"make {block_cells} cells, counted up from the cell his bottom line is in. At y "
        f"{new_y} his rows run from line {new_y - sprite_rows + 1} to {new_y}, across "
        f"{span_cells} cells, so the top line is outside the block; the simulator's screen "
        f"shows {stray} of his pixels standing in a cell not painted his colour.</p>",
        "<p>So a creature carries its colour with it and leaves the room's behind; where two "
        "things overlap, whichever is painted last colours the shared cells, which is the "
        "attribute clash the game lives with. Doors and furniture get their colours back on "
        "the next pass.</p>",

        "<h3>The scroll</h3>",
        f"<p>The status panel is drawn once per game by {link(DRAW_SCROLL)}: a character set of "
        "its own laid out 8 by 24 cells from x 192 (see <a href=\"Graphics.html\">the "
        "graphics</a>). During a game only its contents change -- the clock "
        f"({link(TICK_CLOCK)}), the score ({link(ADD_SCORE)}), the roast ({link(DRAW_FOOD)}), "
        f"the lives ({link(DRAW_LIVES)}) and the inventory ({link(DRAW_INVENTORY)}), all on "
        "<a href=\"Quest.html\">the quest page</a> -- and its colour, which "
        f"{link(PAINT_PANEL)} sets on every room change: the room's ink complemented (bright "
        "green where that would be black or blue), with fixed bands of magenta, white, cyan and "
        f"yellow behind the clock and score. Room ${from_room:02X} is "
        f"{colour_word(colour_from)}, room $00 {colour_word(room_colour)}:</p>",
        figure("draw_panels.png", panels, f"The scroll in room ${from_room:02X} and in room $00.",
               scale=2),

        "<h3>Where the time goes</h3>",
        f"<p>Once the room is drawn, a pass of {link(MAIN_LOOP)} handles every object and "
        "creature in the room and every big monster wherever it is, and between records calls "
        f"{link(FRAME_TICK)} whenever FRAMES has moved, so the player moves once a frame "
        "whatever the pass costs. The game was run on from the arrival above for ten seconds "
        "of emulated time, the knight walking right, left, left, right, up and down a second "
        "each and creatures arriving as they do. Every instruction's T-states were charged "
        "to the record being dispatched at the time (IX, read as the dispatcher jumps) and to "
        f"the labelled routine it is in. {passes} passes ran in {elapsed / FRAME_TSTATES:.0f} "
        f"frames: {per_pass:,.0f} T-states a pass on average ({span_text(lengths)}), "
        f"{per_pass / FRAME_TSTATES:.2f} frames, about {TSTATES_PER_SECOND / per_pass:.0f} "
        "passes a second. At the end the three creature slots held sprites "
        f"{', '.join(hexb(c) for c in creatures_now)}.</p>",
        table(["For", "T-states a pass", "Share"], kind_rows),
        "<p>The labelled routines that took the most:</p>",
        table(["Routine", "T-states a pass", "Share"], top_rows),
        f"<p>The player's share is mostly the walk test: {link(TEST_ROOM_BOXES)} walks the "
        "room's list twice a frame, once for each axis, testing the step against every door "
        "and table (see <a href=\"Movement.html\">movement</a>). The sprite routines -- the "
        "shift chains, the XOR plots, the row loop -- come next; then the doors' and "
        "furniture's colours, repainted every pass. These are T-states of the simulator, which "
        "has no memory contention: a real Spectrum loses more wherever the code reads or "
        "writes the screen.</p>",

        evidence([
            "Run in SkoolKit's simulator from the title screen, nothing staged: the walk into "
            "room $00, every stage of the arrival with its picture and T-states, the first "
            "pass entry by entry, the step followed instruction by instruction with its rows "
            "and the colour filler it chose, and the ten seconds profiled.",
            "Run on a copy of the game: the eight modes drawn by the game's drawers, each "
            "matched pixel for pixel to a symmetry of the stored picture; the shift chain's "
            "displacements written by SETUP_SPRITE_DRAW for each x AND 7.",
            "Read from the game's data: the modes the template uses, the colour tables' cells, "
            "the fillers' table.",
            "Read from the code: the combine bits and SPRITE_COMBINE_OPCODE, the scroll's "
            "colour scheme.",
        ], [
            "That the diagonal modes are slower because of their bit-gathering loops is read "
            "from the loops and fits the timings, but was not measured drawer by drawer.",
            "The times are for one room and one ten-second run; a room with more furniture, "
            "or creatures crowding, has longer passes. No timing with contention was taken.",
        ]),
    ]
    return "\n".join(lines)


# --------------------------------------------------------------------------
# Movement and collision.
# --------------------------------------------------------------------------

def stage_room(game: Game, room: int, x: int, y: int) -> None:
    """Put the player in `room` at (x, y) and redraw it the way the build's
    room pictures do: write the room and position, then run ARRIVE_IN_ROOM
    (which ends in JP MAIN_LOOP, resetting the stack) on to the first
    FRAME_TICK after the room's first pass. This skips ENTER_ROOM, so there
    is no arrival walk; the heading is cleared so the player stands still."""
    from skoolkit.simutils import PC, SP

    game.until(MAIN_LOOP)
    game.put(PLAYER + 1, [room])
    game.memory[PLAYER_X] = x
    game.memory[PLAYER_Y] = y
    game.memory[PLAYER + 2] = 0
    game.memory[PLAYER + 6] = game.memory[PLAYER + 7] = 0
    game.calm()
    game.sim.registers[SP] = ba.STACK
    game.sim.registers[PC] = ARRIVE_IN_ROOM
    game.until(MAIN_LOOP)
    game.until(MAIN_LOOP)
    game.calm()
    game.frame([])


def probe_room(game: Game) -> dict:
    """Where the player's feet may go in the room he is in, asked of the game
    itself: for every pixel of the play area, the player is put there and
    TEST_STEP_IN_ROOM and TEST_STEP_BOXES are called with a step of nothing,
    as MOVE_PLAYER calls them. Bit 4 of +$02 (MOVE_PLAYER's "do not apply x")
    starts set; what the two tests leave in it says whether a step to that
    point would be taken. Returns (x, y) -> 'room', 'doorway', 'solid' or
    None."""
    h = game.copy()
    result = {}
    for y in range(0, 192):
        for x in range(0, 192):
            h.memory[PLAYER_X] = x
            h.memory[PLAYER_Y] = y
            h.memory[PLAYER + 2] = 0x30
            h.call(TEST_STEP_IN_ROOM, {"IX": PLAYER, "DE": 0})
            in_rect = not h.memory[PLAYER + 2] & 0x10
            h.call(TEST_STEP_BOXES, {"IX": PLAYER, "DE": 0})
            allowed = not h.memory[PLAYER + 2] & 0x10
            if allowed:
                result[x, y] = "room" if in_rect else "doorway"
            elif in_rect:
                result[x, y] = "solid"
    return result


PROBE_COLOURS = {"room": (40, 150, 60), "doorway": (60, 110, 230), "solid": (230, 60, 60)}


def probe_image(memory, probe: dict):
    """The room as drawn, with the probe's answers laid over it."""
    from PIL import Image

    base = play_area(memory).convert("RGB")
    overlay = Image.new("RGB", base.size, (0, 0, 0))
    mask = Image.new("L", base.size, 0)
    pixels, alpha = overlay.load(), mask.load()
    for (x, y), what in probe.items():
        pixels[x, y] = PROBE_COLOURS[what]
        alpha[x, y] = 120
    base.paste(overlay, (0, 0), mask)
    return base


def box_of(record) -> tuple:
    """A door's or table's walk box, decoded as TEST_ROOM_BOXES decodes it:
    (x from, x to, y from, y to), inclusive, y counted upwards from the
    bottom edge."""
    def part(byte):
        offset = ((byte >> 4) - 16 if byte & 0x80 else byte >> 4) * 4
        return offset, (byte & 0x0F) * 4
    x_offset, x_size = part(record[6])
    y_offset, y_size = part(record[7])
    x0 = record[X] + x_offset
    y0 = record[Y] + y_offset
    return x0, x0 + x_size, y0 - y_size, y0


def track(game: Game, frames: int, keys, address: int = PLAYER, calm: bool = True) -> list:
    """(room, x, y) of a record after each of `frames` frames with `keys`;
    with `calm`, the spawner is held off after every frame."""
    out = []
    for _ in range(frames):
        game.frame(keys)
        if calm:
            game.calm()
        out.append((game.memory[address + 1], game.memory[address + X],
                    game.memory[address + Y]))
    return out


def path_image(memory, points, colour=(255, 255, 0), offset=(8, -8)):
    """The play area with a dot at each point (a sprite's x, y is its
    bottom-left corner; the dot is put near its middle)."""
    from PIL import ImageDraw

    image = play_area(memory).resize((384, 384))
    draw = ImageDraw.Draw(image)
    for x, y in points:
        cx, cy = 2 * (x + offset[0]), 2 * (y + offset[1])
        draw.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=colour)
    return image


def coast_expected(decay: int, frames: int) -> list:
    """What DECAY_HEADING and SCALE_SIGNED should give after the key is let
    go at full heading: the pixels moved on each following frame."""
    heading = 32
    out = []
    for _ in range(frames):
        heading = max(0, heading - decay)
        out.append(heading >> 4)
    return out


DOORWAY_Y = 0xA8     # below room $00's rectangle, inside its south door's walk box


def _movement_page(snapshot: Path, image_dir: Path, link, log) -> str:

    memory0 = ba.game_memory(snapshot)

    # The three characters, read from their handlers' first instructions.
    log("  measuring the three characters' coasting...")
    rows, coast_rows, coasting = [], [], {}
    for name in ("knight", "wizard", "serf"):
        handler = CHARACTER_HANDLER[name]
        step = memory0[handler + 1]
        decay = memory0[handler + 4]
        unused = memory0[handler + 7] | memory0[handler + 8] << 8
        g = Game.playing(snapshot, name)
        g.calm()
        g.park_big_five()
        x0 = g.memory[PLAYER_X]
        held = track(g, 8, [RIGHT])
        after = track(g, 20, [])
        xs = [x0] + [p[1] for p in held] + [p[1] for p in after]
        moves = [xs[k + 1] - xs[k] for k in range(len(xs) - 1)]
        released = moves[8:]
        coast = sum(released)
        coasting[name] = (coast, released, coast_expected(decay, len(released)))
        rows.append([name, link(handler), hexb(step), str(decay), f"${unused:04X}",
                     str(moves[0]), str(coast)])
        shown = released[:18]
        coast_rows.append([name] + [str(v) for v in shown])
    agree = all(v[1] == v[2] for v in coasting.values())

    # The walk test, probed in two rooms.
    log("  probing where the player may stand...")
    game = Game.playing(snapshot)
    game.calm()
    probe0 = probe_room(game)
    room0_pic = save(probe_image(game.memory, probe0), image_dir, "move_probe00.png")
    table_room = 0x2A
    staged = game.copy()
    stage_room(staged, table_room, 0x58, 0x68)
    staged.calm()
    probe_t = probe_room(staged)
    room_t_pic = save(probe_image(staged.memory, probe_t), image_dir,
                      f"move_probe{table_room:02X}.png")
    half_w, half_h = game.memory[ROOM_HALF_WIDTH], game.memory[ROOM_HALF_HEIGHT]
    xs_room = [x for (x, y), w in probe0.items() if w == "room"]
    ys_room = [y for (x, y), w in probe0.items() if w == "room"]
    box_rows = []
    for room_game, room in ((game, 0), (staged, table_room)):
        for address in room_game.room_list(room):
            record = room_game.record(address, 8)
            if record[6] & 0x0F == 0 and record[7] & 0x0F == 0:
                continue
            x0, x1, y0, y1 = box_of(record)
            state = ("solid" if record[MODE] & 4 else "shut: ignored" if record[MODE] & 8
                     else "a doorway")
            box_rows.append([f"${room:02X}", html.escape(record_name(record[0])),
                             f"{hexb(record[X])}, {hexb(record[Y])}",
                             f"{hexb(record[6])} {hexb(record[7])}",
                             f"x {hexb(x0)}-{hexb(x1)}, y {hexb(y0)}-{hexb(y1)}", state])
    furniture_boxes = 0
    zero_boxes = 0
    solid_kinds = set()
    for address in range(TEMPLATE_DOORS, TEMPLATE_END, 8):
        kind = memory0[address]
        if not kind or kind in ba.DOOR_KINDS:
            continue
        if memory0[address + 6] & 0x0F or memory0[address + 7] & 0x0F:
            furniture_boxes += 1
        else:
            zero_boxes += 1
        if memory0[address + MODE] & 4:
            solid_kinds.add(record_name(kind))

    # Set pieces.
    log("  running the set pieces...")
    pieces = []
    base = Game.playing(snapshot)
    base.calm()
    base.park_big_five()

    # 1. Straight into the east wall.
    g = base.copy()
    start = g.player()
    path = track(g, 50, [RIGHT])
    limit_x = PLAY_CENTRE[0] + half_w - 1
    stop_x = path[-1][1]
    frames_moving = sum(1 for k in range(1, len(path)) if path[k][1] != path[k - 1][1]) + 1
    pieces.append([
        f"Holding W (right) from ({hexb(start[1])}, {hexb(start[2])}) in room $00, the middle "
        "of the room",
        f"Two pixels a frame for {frames_moving} frames, then x stayed at {hexb(stop_x)}: the "
        f"step to {hexb(stop_x + 2)} fails ALLOW_IF_IN_ROOM (|x - $58| must be below "
        f"{hexb(half_w)}) and there is no doorway there.",
        f"The rectangle's last x is {hexb(limit_x)}; from an even start, the last even x "
        f"below it is {hexb(limit_x & 0xFE)}."])
    right_pic = save(path_image(g.memory, [(p[1], p[2]) for p in path]), image_dir,
                     "move_right.png")

    # 2. Diagonally into the same wall: x stops, y carries on.
    g2 = g.copy()
    slide = track(g2, 12, [RIGHT, UP])
    pieces.append([
        "Then W and R together (up and right) against that wall",
        f"x stayed at {hexb(slide[-1][1])} while y went from {hexb(path[-1][2])} to "
        f"{hexb(slide[-1][2])}: each axis is tested alone, so the player slides along "
        "the wall.",
        "MOVE_PLAYER tests the new x with the old y and the new y with the old x, and "
        "APPLY_HEADING moves only on the axes allowed."])

    # 3. Into a table.
    g3 = staged.copy()
    tables = [a for a in g3.room_list(table_room) if g3.memory[a] == 0x12]
    start_point = None
    for address in tables:
        first_table = g3.record(address, 8)
        tx0, tx1, ty0, ty1 = box_of(first_table)
        for y in range(ty0, ty1 + 1):
            x = tx0 - 20
            if all(probe_t.get((xx, y)) == "room" for xx in range(x, tx0)):
                start_point = (x & 0xFE, y)
                break
        if start_point:
            break
    g3 = game.copy()
    stage_room(g3, table_room, *start_point)
    start3 = g3.player()
    table_path = track(g3, 30, [RIGHT])
    stop3 = table_path[-1][1]
    pieces.append([
        f"Holding W from ({hexb(start3[1])}, {hexb(start3[2])}) in room ${table_room:02X}, "
        f"towards the table at ({hexb(first_table[X])}, {hexb(first_table[Y])}) (staged: "
        "the player put in the room)",
        f"Stopped at x {hexb(stop3)}, short of the table's box, which starts at x "
        f"{hexb(tx0)}: the step to {hexb(stop3 + 2)} lands in a solid box and "
        "TEST_ROOM_BOXES sets the bit back.",
        f"The table's box, from its +$06 and +$07: x {hexb(tx0)}-{hexb(tx1)}, y "
        f"{hexb(ty0)}-{hexb(ty1)}."])
    table_pic = save(path_image(g3.memory, [(p[1], p[2]) for p in table_path]), image_dir,
                     "move_table.png")

    # 4. Out through the open south door, and the arrival walk.
    g4 = base.copy()
    out = []
    for frame in range(80):
        g4.frame([DOWN])
        g4.calm()
        out.append(g4.player())
        if g4.memory[ROOM] != 0:
            break
    arrival = g4.player()
    nibble = g4.memory[PLAYER + 2] & 0x0F
    heading = g4.memory[PLAYER + 6], g4.memory[PLAYER + 7]
    walk_in = []
    while g4.memory[PLAYER + 2] & 0x0F:
        g4.frame([LEFT, UP])
        g4.calm()
        walk_in.append(g4.player())
    after_walk = track(g4, 6, [LEFT, UP])
    door_half = [a for a in base.room_list(0) if base.memory[a + MODE] >> 5 == 4
                 and base.memory[a] in (0x02, 0x21, 0x23, 0x01)][0]
    other = base.record(door_half ^ 8, 8)
    expect_x = (other[X] + ((other[2] << 1 | other[2] >> 7) & 0x1E)) & 0xFF
    expect_y = (other[Y] - ((other[2] >> 3 | other[2] << 5) & 0x1E)) & 0xFF
    pieces.append([
        "Holding E (down) from the start, towards room $00's south door (open: a timed door "
        "at the time)",
        f"After {len(out)} frames the door's handler found the player in its box and "
        f"ENTER_ROOM put him in room ${arrival[0]:02X} at ({hexb(arrival[1])}, "
        f"{hexb(arrival[2])}), heading ({heading[0] - 256 if heading[0] > 127 else heading[0]}, "
        f"{heading[1] - 256 if heading[1] > 127 else heading[1]}), with {nibble} in the low "
        "nibble of +$02.",
        f"The far half's x plus twice the low nibble of its +$02, and y minus twice the high "
        f"nibble: ({hexb(expect_x)}, {hexb(expect_y)}). SET_ARRIVAL_HEADING gives 32 away "
        "from the wall."])
    moved_down = all(walk_in[k][2] > walk_in[k - 1][2] for k in range(1, len(walk_in)))
    steady_x = all(p[1] == walk_in[0][1] for p in walk_in)
    pieces.append([
        f"Then Q and R held (left and up) through the {len(walk_in)} frames of the arrival walk",
        f"The player kept walking {'straight down' if moved_down and steady_x else 'on'}, two "
        f"pixels a frame, from y {hexb(walk_in[0][2])} to {hexb(walk_in[-1][2])}, the keys "
        f"ignored; only then did he turn up and left ({hexb(after_walk[-1][1])}, "
        f"{hexb(after_walk[-1][2])} six frames later).",
        "While the low nibble counts down, DECAY_HEADING does nothing and STEER skips the "
        "controls, stepping 2 along the heading's sign; no door can fire either."])

    # 5. Into the locked door without its key.
    g5 = base.copy()
    locked = next(a for a in g5.room_list(0) if g5.memory[a] in range(0x08, 0x10))
    lock = g5.record(locked, 8)
    g5.memory[PLAYER_X] = lock[X] + 4
    blocked = track(g5, 60, [UP])
    top_y = PLAY_CENTRE[1] - half_h + 1
    pieces.append([
        f"Holding R (up) under room $00's {record_name(lock[0])} in the north wall, no key "
        "carried",
        f"Stopped at y {hexb(blocked[-1][2])}, still in room ${blocked[-1][0]:02X}: the door is "
        "shut (bit 3 of its +$05), so TEST_ROOM_BOXES ignores its doorway and the rectangle's "
        "edge holds.",
        f"The rectangle's top is y {hexb(top_y)}; from an even start the last even y above it "
        f"is {hexb((top_y + 1) & 0xFE)}."])

    # 6. The same with the key, staged in the first inventory slot.
    g6 = base.copy()
    colour = memory0[DOOR_COLOURS + (lock[0] & 3)]
    key = next(address for address in KEYS.values() if g6.memory[address + MODE] == colour)
    g6.carry(0, key, 0x81, colour)
    g6.memory[PLAYER_X] = lock[X] + 4
    through = []
    for _ in range(80):
        g6.frame([UP])
        g6.calm()
        through.append(g6.player())
        if g6.memory[ROOM] != 0:
            break
    after_types = (g6.memory[locked], g6.memory[locked ^ 8])
    pieces.append([
        f"The same, with the {colour_word(colour)} key written into the first inventory slot "
        "(staged)",
        f"Through into room ${through[-1][0]:02X} after {len(through)} frames; both halves of " +
        ("the door are now type " + (hexb(after_types[0]) if after_types[0] == after_types[1]
                                     else f"{hexb(after_types[0])} and {hexb(after_types[1])}")
         + ", a plain door."),
        "DOOR_NEEDS_KEY finds the key with FIND_CARRIED, OPEN_DOOR clears bit 3 on both "
        "halves, and DOOR_LOCKED_A turns the door into a plain one as the player goes through "
        "(<a href=\"Doors.html\">the doors</a>)."])

    # 7. Firing from a doorway, and from the room.
    g7 = base.copy()
    g7.memory[PLAYER_X] = 0x58
    g7.memory[PLAYER_Y] = DOORWAY_Y                 # in the south doorway, outside the rectangle
    g7.frame([])
    in_doorway = g7.memory[IN_DOORWAY]
    g7.frames(3, [FIRE])
    weapon_doorway = g7.memory[WEAPON]
    g8 = base.copy()
    g8.frames(1, [])
    g8.frame([FIRE])
    weapon_room = g8.memory[WEAPON]
    pieces.append([
        f"T (fire) held for three frames standing in the south doorway, y {hexb(DOORWAY_Y)}",
        f"IN_DOORWAY was {in_doorway}; the weapon slot stayed "
        f"{'empty' if weapon_doorway == 0 else hexb(weapon_doorway)}. The same key in the "
        f"middle of the room launched sprite {hexb(weapon_room)}.",
        "KNIGHT_FIRE (and the wizard's and serf's) returns at once if IN_DOORWAY is set, "
        "which CHECK_IN_DOORWAY sets whenever the player is outside the rectangle."])

    # 8. The axe, thrown right from the middle of room $00.
    g9 = base.copy()
    for _ in range(2):
        g9.frame([RIGHT])
    g9.frame([RIGHT, FIRE])
    axe = []
    velocities = []
    for _ in range(60):
        if g9.memory[WEAPON] == 0:
            break
        axe.append((g9.memory[WEAPON + X], g9.memory[WEAPON + Y]))
        velocities.append(g9.memory[WEAPON + 6])
        g9.frame([])
        g9.calm()
    bounces = sum(1 for k in range(1, len(velocities)) if velocities[k] != velocities[k - 1])
    axe_pic = save(path_image(g9.memory, axe, (255, 80, 80)), image_dir, "move_axe.png")
    pieces.append([
        "The knight walking right and pressing T in the middle of room $00",
        f"The axe flew {len(axe)} frames at four pixels a frame, bouncing {bounces} "
        f"time{'s' if bounces != 1 else ''} off the walls -- standing still for the frame of "
        "each bounce -- and vanished.",
        "FIRE_WEAPON gives it 4 a frame along the heading and a lifetime of 48 frames; "
        "SPIN_WEAPON reverses a velocity that would leave the rectangle."])

    char_rows = rows
    frames_header = ["Frame after release"] + [str(k + 1) for k in range(18)]
    weapon_rows = [
        ["knight", link(KNIGHT_FIRE), "axe, $40-$47", f"{link(SPIN_AXE)}: eight angles, from "
         "FRAMES, as it flies", "red"],
        ["wizard", link(WIZARD_FIRE), "spell, $34-$37", f"{link(SPIN_SPELL)}: four frames in "
         "turn", "cyan and white by turns"],
        ["serf", link(SERF_FIRE), "sword, $38-$3F", f"{link(AIM_SWORD)}: the one of eight "
         "angles its velocity points along", "yellow"],
    ]

    lines = [
        "<p>The player moves once a frame, on the 50Hz tick, whatever else is happening; "
        "creatures move once a pass of the main loop (see <a href=\"Monsters.html\">the "
        "monsters</a>). There are no collision masks or maps. The player may step anywhere "
        "inside the room's walk rectangle; a step outside it is allowed only into an open "
        "doorway's box, and a step into a table's box is refused. Everything else -- being "
        "caught, shot, picking up, eating, going through a door -- is a distance test. This "
        "page takes each in turn and then runs a set of situations through the game's own "
        "code in SkoolKit's simulator.</p>",

        "<h3>Three characters, one routine</h3>",
        f"<p>{link(UPDATE_KNIGHT)}, {link(UPDATE_WIZARD)} and {link(UPDATE_SERF)} run once a "
        f"frame from {link(FRAME_TICK)}, for sprites $01-$10, $11-$20 and $21-$30. Each loads "
        f"BC, DE and HL and calls {link(MOVE_PLAYER)}; those are the only numbers that differ "
        "between the three. The values, read from each handler's first three instructions, "
        "and what a run of each did -- in room $00 at the start of a game, W held for eight "
        "frames and let go, creatures kept out:</p>",
        table(["Character", "Handler", "Step (B)", "Decay (E)", "HL", "First frame",
               "Coast after release (px)"], char_rows),
        f"<p>{link(MOVE_PLAYER)} reads the controls ({link(READ_CONTROLS)}) into a wanted "
        f"change of 32 on each axis, lets the heading in +$06 and +$07 fall towards zero by "
        f"the character's decay ({link(DECAY_HEADING)}), adds the change and clamps it to 32 "
        f"({link(STEER)}), and turns the heading into a step by dividing by sixteen "
        f"({link(SCALE_SIGNED)}): 32 is two pixels, 16-31 one, less than 16 none. So all three "
        "reach full speed, two pixels a frame, on the first frame a key is held; they differ "
        "only in how they stop. Let go, the heading falls by the decay each frame: the "
        "wizard's 32 stops him dead, the knight's 3 lets him slide five pixels, the serf's 1 "
        "sixteen. The pixels moved on each frame after release, measured:</p>",
        table(frames_header, coast_rows),
        "<p>" + ("These are exactly what DECAY_HEADING and SCALE_SIGNED give when worked "
                 "through by hand from a heading of 32." if agree else
                 "These differ from what DECAY_HEADING and SCALE_SIGNED give worked through by "
                 "hand: " + "; ".join(f"{n}: expected {v[2]}" for n, v in coasting.items()))
        + " The HL each handler passes is pushed and popped by MOVE_PLAYER and never used; "
        "STEER clamps to the BC value instead.</p>",
        "<p>The picture follows the heading: while moving, on frames when FRAMES AND 3 is "
        "zero, the sprite steps through its four walking frames, picks left, right, up or "
        "down by the larger of the two headings, and a footstep sounds.</p>",

        "<h3>The walk test</h3>",
        f"<p>Before the move, {link(MOVE_PLAYER)} sets bits 4 and 5 of the player's +$02, "
        "meaning &ldquo;do not apply x&rdquo; and &ldquo;do not apply y&rdquo;. Then, for the "
        "new x with the old y, and the new y with the old x:</p>",
        "<ol>"
        f"<li>{link(TEST_STEP_IN_ROOM)} and {link(ALLOW_IF_IN_ROOM)}: if the point is strictly "
        f"inside the walk rectangle -- |x - $58| below ROOM_HALF_WIDTH and |y - $68| below "
        "ROOM_HALF_HEIGHT, the two numbers DRAW_ROOM copied from the room's shape -- clear "
        "the bit.</li>"
        f"<li>{link(TEST_STEP_BOXES)} calls {link(TEST_ROOM_BOXES)}, which walks the room's list "
        "of door and furniture halves. Each has a box in +$06 (across) and +$07 (up): the top "
        "four bits a signed offset in fours from the record's own x or y, the bottom four a "
        "size in fours; the box runs right from x plus the offset and up from y plus the "
        "offset. If the point is inside: a record with bit 3 of +$05 set (a shut door) is "
        "ignored; one with bit 2 set (solid) sets the bit, refusing the step even inside the "
        "room; any other clears it, allowing the step even outside the rectangle.</li>"
        f"<li>{link(APPLY_HEADING)} adds the step on the axes whose bit is clear.</li>"
        "</ol>",
        f"<p>To see the rule whole, the game was asked about every pixel of the play area: "
        "the player put there, bit 4 set, and the two tests called with a step of nothing, "
        "exactly as MOVE_PLAYER calls them. Green is a point inside the rectangle, allowed; "
        "blue a point outside it allowed by a doorway's box; red a point inside the "
        "rectangle refused by a solid box; uncoloured, refused. The first picture is room "
        f"$00 at the start of the game; the second room ${table_room:02X}, with its two "
        "tables, the player put there to draw it (staged). The points are the player's x "
        "and y, his sprite's bottom-left corner: the rectangle's centre, ($58, $68), is where "
        "that corner is when a sixteen-pixel figure stands in the middle of the play area.</p>",
        figure("move_probe00.png", room0_pic,
               f"Room $00: the rectangle is x {hexb(min(xs_room))}-{hexb(max(xs_room))}, y "
               f"{hexb(min(ys_room))}-{hexb(max(ys_room))}. The locked door (north) and the "
               "A.C.G. door (east) are shut, so they add nothing."),
        figure(f"move_probe{table_room:02X}.png", room_t_pic,
               f"Room ${table_room:02X}: the two tables' solid boxes cut into the rectangle."),
        "<p>The boxes behind the pictures, as the records give them (only records with a box "
        "of any size are listed):</p>",
        table(["Room", "Record", "x, y", "+$06 +$07", "Box", "What it does"], box_rows),
        f"<p>A doorway's box reaches from inside the room out through the wall, so an open "
        "door is a channel out of the rectangle to its own trigger box, and a shut door is "
        f"simply wall. Among the furniture, {furniture_boxes} halves in the template have a box "
        f"of any size and {zero_boxes} a box of nothing; the solid ones are all "
        f"{', '.join(html.escape(k) for k in sorted(solid_kinds))}. "
        f"{link(CHECK_IN_DOORWAY)} records in IN_DOORWAY whether the player is outside the "
        "rectangle on either axis: no firing from a doorway, and an open timed door will not "
        "shut on him.</p>",
        "<p>Creatures do none of this. Their movers step them with "
        f"{link(STEP_ACTOR)}, which reverses a velocity that would take them out of the "
        "rectangle (the big monsters' a little smaller), and doors and furniture mean nothing "
        "to them: they never leave their room.</p>",

        "<h3>Contact tests</h3>",
        "<p>Everything else is a box round a point:</p>",
        table(["Test", "Between", "Box", "Also needs"], [
            [link(CHECK_HIT), "a creature and the player", "|dx| &lt; 12, |dy| &lt; 12",
             "the same room; the player in play ($01-$30)"],
            [link(CHECK_SHOT_HIT), "a creature and the weapon", "the same",
             "the same room; a weapon in flight"],
            [link(NEAR_PLAYER), "food, a collectable or a mushroom and the player", "the same",
             "nothing: PICK_UP adds its own in-play test, food and mushrooms do not"],
            [link(PLAYER_AT_DOOR), "a door and the player",
             "0 &le; x - door x &lt; C, 0 &le; door y - y &lt; B, one of them halved across "
             "the door", "the player in play; the low nibble of his +$02 clear"],
        ]),
        f"<p>The door's C and B come from its handler: $11 each ({link(DOOR)}), so 17 by 8 "
        f"in the top or bottom wall and 8 by 17 in a side wall; $20 each for a big door "
        f"({link(BIG_DOOR)}); $18 for a trapdoor; $30 by $20 for the A.C.G. door. Being in play "
        "matters: while the player rises or sinks (sprites $66 and $67) nothing can touch "
        "him and no door lets him through.</p>",

        "<h3>Set pieces</h3>",
        "<p>Each row was run in the simulator from the first game's start in room $00 (the "
        "knight, creatures kept out, the big five sent away), with only the keys named held -- "
        "except where the row says it was staged. The last column is what the code says "
        "should happen, worked out before the run.</p>",
        table(["Situation", "What the game did", "What the code predicts"], pieces),
        figure("move_right.png", right_pic, "The walk right in room $00: a dot at each frame's "
               "position.", scale=1),
        figure("move_table.png", table_pic, f"The walk into the table in room "
               f"${table_room:02X}.", scale=1),
        figure("move_axe.png", axe_pic, "The axe's flight in room $00, a dot a frame.", scale=1),

        "<h3>The weapons</h3>",
        "<p>Fire launches the character's weapon only when the weapon slot, the second half "
        f"of the player's record at $EA98, is empty and the player is not in a doorway. "
        f"{link(FIRE_WEAPON)} gives it four pixels a frame along each axis the heading is "
        "non-zero on (or the way the player faces, standing still), the player's room and "
        "position, and a lifetime of 48 frames. It is then dispatched every frame like the "
        f"player; all three weapons end in {link(SPIN_WEAPON)}, which bounces them off the "
        "rectangle's edges with a click and ends them -- erased, with a sound -- when the 48 "
        "frames are up, when they have hit something, or at once if the player has left the "
        "room.</p>",
        table(["Character", "Fire routine", "Sprites", "Picture chosen by", "Colour"],
              weapon_rows),
        "<p>What a weapon can hit is on <a href=\"Monsters.html\">the monsters page</a>: any "
        "small creature, none of the big five.</p>",

        evidence([
            "Measured in the simulator: the coasting of all three characters (and compared "
            "with the arithmetic of DECAY_HEADING and SCALE_SIGNED), and every set piece in the "
            "table, run with keys from the start of the first game.",
            "Asked of the game's own code: the pictures of where the player may stand, from "
            "TEST_STEP_IN_ROOM and TEST_STEP_BOXES called at every pixel.",
            "Read from the game's data: the handlers' constants, the boxes in the records, "
            "the doors' tolerances.",
        ], [
            f"Room ${table_room:02X}, the table set piece and the key were staged: the player "
            "written into the room and the key into the inventory; what followed was the "
            "game's.",
            "The contact tests are read from the code; they are exercised on the monsters and "
            "quest pages.",
        ]),
    ]
    return "\n".join(lines)


# --------------------------------------------------------------------------
# The monsters.
# --------------------------------------------------------------------------

SAFE_SPOT = (0x58, 0xAC)
MUMMY_KNIGHT = (0x28, 0x98)  # a corner of the mummy's room, away from its patrol     # room $00's south doorway: out of every creature's reach
TRACK_PASSES = 300
MOVER_NOTES = {
    MOVE_ACTOR: "a random pair of direction bits every 16 passes; the velocity eased a step "
                "a pass towards &plusmn;2",
    MOVE_GHOST: "the same, every 8 passes",
    MOVE_BAT: "a new random velocity (1 or 2 each way) every 256 passes",
    MOVE_ARCS: "every 16 passes a random direction, then steps from STEP_VECTORS in turn, "
               "swinging from across to down: arcs",
    MOVE_HOPPER: "a counter from -7 to 7, halved into the vertical velocity, restarted with "
                 "a new random velocity when it tops out: hops",
    MOVE_FACE: "a new random velocity every 17 passes",
    MOVE_WITCH: "a new random velocity every 16 passes, the vertical half halved; faces the "
                "way it flies",
    MOVE_FACING_FLYER: "the same every 32 passes, the horizontal part &plusmn;2; faces the way "
                       "it flies",
}


def creature_name(code: int) -> str:
    """The annotations' name for a creature's sprite, or what it looks like
    where they have none."""
    name = ba.sprite_name(code).split(" -- ")[0]
    if name.startswith("sprite $"):
        name = UNNAMED_CREATURES.get(code, name)
    return name


UNNAMED_CREATURES = {0x94: "a cloaked figure (as drawn)"}


def hold_spawner(game: Game) -> None:
    """Keep the spawner from adding creatures, leaving the slots alone."""
    game.memory[SPAWN_COUNTDOWN] = 0x20
    game.memory[SPAWN_ROOM] = game.memory[ROOM]


def put_creature(game: Game, slot: int, code: int, x: int = 0x68, y: int = 0x68,
                 arriving: bool = True) -> None:
    """A creature written into a slot the way SPAWN_MONSTER_INTO_ROOM writes
    one: MONSTER_TEMPLATE's sixteen bytes, the player's room, the type in
    +$02 -- arriving as sprites $58-$5B for 32 passes -- or, with arriving
    False, already the type itself."""
    record = [game.memory[MONSTER_TEMPLATE + k] for k in range(16)]
    record[1] = game.memory[ROOM]
    record[2] = code
    record[X], record[Y] = x, y
    if not arriving:
        record[0] = code
    game.put(CREATURE_SLOTS[slot], record)


def move_player(game: Game, x: int, y: int) -> None:
    """Move the player where he stands: rubbed out where he is by the game's
    own ERASE_THING, written to the new place, redrawn by DRAW_THING."""
    game.call(ACTOR_TO_WORKSPACE, {"IX": PLAYER})
    game.call(ERASE_THING, {"IX": PLAYER})
    game.memory[PLAYER_X], game.memory[PLAYER_Y] = x, y
    game.call(ACTOR_TO_WORKSPACE, {"IX": PLAYER})
    game.call(DRAW_THING, {"IX": PLAYER})


def pass_track(game: Game, record: int, passes: int, spawner: bool = False) -> list:
    """The record's (sprite, room, x, y) after each of `passes` passes, the
    spawner held off unless `spawner`."""
    out = []
    for _ in range(passes):
        game.pass_([])
        if not spawner:
            hold_spawner(game)
        out.append((game.memory[record], game.memory[record + 1], game.memory[record + X],
                    game.memory[record + Y]))
    return out


def multi_path_image(memory, series, scale: int = 2):
    """The play area with each series of (x, y) points dotted in its colour."""
    from PIL import ImageDraw

    image = play_area(memory).resize((192 * scale, 192 * scale))
    draw = ImageDraw.Draw(image)
    for points, colour in series:
        for x, y in points:
            cx, cy = scale * (x + 8), scale * (y - 8)
            draw.ellipse([cx - scale, cy - scale, cx + scale, cy + scale], fill=colour)
    return image


def distance(a, b) -> int:
    return max(abs(a[0] - b[0]), abs(a[1] - b[1]))


def _monsters_page(snapshot: Path, image_dir: Path, link, log) -> str:

    memory0 = ba.game_memory(snapshot)
    base = Game.playing(snapshot)
    base.calm()
    base.park_big_five()

    # The spawn table, read from the game.
    spawn_codes = [memory0[SPAWN_TYPES + k] for k in range(16)]
    kinds = []
    for code in spawn_codes:
        if code not in kinds:
            kinds.append(code)
    handler = {code: memory0[ACTOR_HANDLERS + 2 * code] | memory0[ACTOR_HANDLERS + 2 * code + 1] << 8
               for code in kinds}

    # Each kind, staged in room $00 with the player standing out of reach in
    # the south doorway, tracked for TRACK_PASSES passes.
    log("  tracking each kind of creature...")
    parked = base.copy()
    move_player(parked, *SAFE_SPOT)
    parked.frame([])
    kind_rows, track_figures = [], []
    for code in kinds:
        g = parked.copy()
        put_creature(g, 0, code, 0x60, 0x60)
        arrival = pass_track(g, CREATURE_SLOTS[0], 34)
        became = next((k for k, p in enumerate(arrival) if p[0] & 0xFE == code & 0xFE), None)
        path = pass_track(g, CREATURE_SLOTS[0], TRACK_PASSES)
        alive = [p for p in path if p[0] and p[1] == 0]
        still_there = g.memory[CREATURE_SLOTS[0]] not in (0, 0x6C, 0x6D, 0x6E, 0x6F)
        picture = multi_path_image(g.memory, [([(p[2], p[3]) for p in alive], (255, 255, 0))], 1)
        name = f"monster_track_{code:02X}.png"
        save(picture, image_dir, name)
        label = html.escape(creature_name(code))
        track_figures.append(figure(name, picture, f"{hexb(code)} {label}", scale=1))
        xs = [p[2] for p in alive]
        ys = [p[3] for p in alive]
        kind_rows.append([hexb(code), label, str(spawn_codes.count(code)), link(handler[code]),
                          MOVER_NOTES.get(handler[code], ""),
                          f"x {hexb(min(xs))}-{hexb(max(xs))}, y {hexb(min(ys))}-{hexb(max(ys))}"
                          + ("" if still_there else "; gone")])
    arrival_passes = became

    # Spawning in a real game: standing still in room $00 from the start.
    log("  watching the spawner in room $00...")
    g = Game.playing(snapshot)
    g.park_big_five()
    events = []
    slots = [g.memory[a] for a in CREATURE_SLOTS]
    types = [0, 0, 0]
    food, score = g.memory[FOOD_LEVEL], g.score()
    frames = 0
    while frames < 500:
        g.frame([])
        frames += 1
        for index, address in enumerate(CREATURE_SLOTS):
            now = g.memory[address]
            if slots[index] == 0 and now:
                types[index] = g.memory[address + 2]
                events.append((frames, f"slot {index + 1}: a creature arrives (sprite "
                                       f"{hexb(now)}), to become {hexb(types[index])}, "
                                       f"{html.escape(creature_name(types[index]))}"))
            elif slots[index] and now == 0:
                events.append((frames, f"slot {index + 1}: the burst ends; the slot is free"))
            elif now & 0xFC == 0x6C and slots[index] & 0xFC != 0x6C:
                events.append((frames, f"slot {index + 1}: it touches the knight and bursts"))
            slots[index] = now
        if g.memory[FOOD_LEVEL] != food or g.score() != score:
            if g.score() != score:
                events.append((frames, f"life force {food} &rarr; {g.memory[FOOD_LEVEL]}, "
                                       f"score {score} &rarr; {g.score()}"))
            food, score = g.memory[FOOD_LEVEL], g.score()
    spawn_rows = [[f"{f / 50:.2f} s (frame {f})", text] for f, text in events]
    first_spawn = next((f for f, t in events if "arrives" in t), None)
    touches = sum(1 for f, t in events if "touches" in t)

    # Touching, shooting, dying.
    log("  touching and shooting...")
    set_rows = []
    g = base.copy()
    player = g.player()
    put_creature(g, 0, 0x5C, player[1], player[2], arriving=False)
    food, score = g.memory[FOOD_LEVEL], g.score()
    g.pass_([])
    hold_spawner(g)
    g.pass_([])
    burst = g.memory[CREATURE_SLOTS[0]]
    burst_passes = 0
    while g.memory[CREATURE_SLOTS[0]] and burst_passes < 60:
        g.pass_([])
        hold_spawner(g)
        burst_passes += 1
    set_rows.append([
        "A spider written into a slot on top of the knight (staged)",
        f"Life force {food} &rarr; {g.memory[FOOD_LEVEL]}, score {score} &rarr; {g.score()}; "
        f"the spider became sprite {hexb(burst)}, the burst, and its slot was free "
        f"{burst_passes + 1} passes later.",
        f"{link(CHECK_HIT)}, then {link(MONSTER_CAUGHT_PLAYER)}: {link(LOSE_FOOD_THIRTY_TWO)} and "
        f"{link(KILL_MONSTER)}, which adds 155 and starts a 16-pass burst "
        f"({link(COUNTDOWN_ACTOR)})."])

    g = base.copy()
    g.frames(2, [RIGHT])
    player = g.player()
    put_creature(g, 0, 0x5C, min(0x8C, player[1] + 0x28), player[2], arriving=False)
    g.memory[CREATURE_SLOTS[0] + 8] = g.memory[CREATURE_SLOTS[0] + 9] = 0
    score = g.score()
    food = g.memory[FOOD_LEVEL]
    g.frame([RIGHT, FIRE])
    for frame in range(30):
        g.frame([])
        hold_spawner(g)
        if g.memory[CREATURE_SLOTS[0]] & 0xFC == 0x6C:
            break
    set_rows.append([
        f"A spider staged {hexb(0x28)} pixels to the right of the knight, who walks right "
        "and fires",
        f"The axe reached it in {frame + 1} frames: sprite {hexb(g.memory[CREATURE_SLOTS[0]])} "
        f"(the burst), score {score} &rarr; {g.score()}, life force unchanged "
        f"({food} &rarr; {g.memory[FOOD_LEVEL]}).",
        f"The spider's mover calls {link(CHECK_SHOT_HIT)} first: a hit sets the weapon's hit "
        f"flag, which ends its flight, and jumps to {link(KILL_MONSTER)}."])

    g = base.copy()
    put_creature(g, 0, 0x5C, 0x30, 0x40, arriving=False)
    put_creature(g, 1, 0x62, 0x80, 0x40, arriving=False)
    g.pass_([])
    score = g.score()
    g.memory[FOOD_LEVEL] = 1
    cleared = died = None
    for count in range(1, 200):
        g.pass_([])
        hold_spawner(g)
        if died is None and g.memory[PLAYER] == 0x67:
            died = count
        if all(g.memory[a] & 0xFC in (0, 0x6C) for a in CREATURE_SLOTS[:2]):
            cleared = count
            break
    set_rows.append([
        "A spider and a ghost staged in the room, then the life force set to 1",
        f"The knight died on the next drain and began to sink (sprite $67, pass {died}); "
        f"both creatures had burst by pass {cleared}, and the score went from {score} to "
        f"{g.score()}.",
        f"While the player's sprite is not $01-$30, every small creature's mover ends in "
        f"{link(KILL_MONSTER)} (the test at {link(STEP_ACTOR)}'s tail): dying clears the room, "
        "and pays for it."])

    # Leaving them behind.
    g = base.copy()
    put_creature(g, 0, 0x5C, 0x40, 0x40, arriving=False)
    g.memory[CREATURE_SLOTS[0] + 8] = g.memory[CREATURE_SLOTS[0] + 9] = 0
    for _ in range(80):
        g.frame([DOWN])
        hold_spawner(g)
        if g.memory[ROOM] != 0:
            break
    left_passes = 0
    for left_passes in range(1, 400):
        g.pass_([])
        g.memory[SPAWN_COUNTDOWN] = 0x20
        g.memory[SPAWN_ROOM] = g.memory[ROOM]
        if g.memory[CREATURE_SLOTS[0]] == 0:
            break
    set_rows.append([
        "The same spider left in room $00 while the knight walks out of the south door",
        f"Its slot was emptied {left_passes} passes after he left.",
        f"A creature not in the player's room only counts down its +$0F "
        f"({link(ACTOR_TICK_TIMER)}), which its mover zeroes on every pass in the room: "
        "256 passes."])

    # The big five.
    log("  the big five...")
    start = Game.at_start(snapshot)
    start.until(ARRIVE_IN_ROOM)
    five_rows = []
    for name, record, mover in BIG_FIVE:
        first = start.record(record, 16)
        cost = {MOVE_HUMPBACK: 16}.get(mover, 8)
        five_rows.append([name, f"${record:04X}", room_ref(memory0, first[1]),
                          hexb(first[0]), link(mover), str(cost)])

    def hunt(monster: int, room: int, setup=None, passes: int = 200, where=None,
             stop_at_touch: bool = True, knight=(0x58, 0x68)):
        """The monster in `room`, the knight put in its middle (staged), the
        monster's (x, y) each pass; stops when it is within CHECK_HIT's 12
        pixels of him. Returns the game, the path and the pass it touched."""
        g = base.copy()
        g.memory[monster + 1] = room
        if where:
            g.memory[monster + X], g.memory[monster + Y] = where
        if setup:
            setup(g)
        stage_room(g, room, *knight)
        path = [(g.memory[monster + X], g.memory[monster + Y])]
        touched = None
        for count in range(1, passes + 1):
            g.pass_([])
            hold_spawner(g)
            here = (g.memory[monster + X], g.memory[monster + Y])
            path.append(here)
            if abs(here[0] - knight[0]) < 12 and abs(here[1] - knight[1]) < 12:
                touched = count
                if stop_at_touch:
                    break
        return g, path, None, touched

    # Frankenstein, with and without the spanner.
    frank_rows = []
    for with_spanner in (False, True):
        g = base.copy()
        room = start.memory[FRANKENSTEIN + 1]
        g.memory[FRANKENSTEIN + 1] = room
        g.memory[FRANKENSTEIN + X], g.memory[FRANKENSTEIN + Y] = 0x58, 0x68
        if with_spanner:
            g.carry(0, SPANNER, 0x8B, g.memory[SPANNER + MODE])
        stage_room(g, room, 0x58, 0x68)
        food, score = g.memory[FOOD_LEVEL], g.score()
        for count in range(10):
            g.pass_([])
            hold_spawner(g)
        frank_rows.append([
            "carrying the spanner (staged in the first slot)" if with_spanner else "no spanner",
            f"{food} &rarr; {g.memory[FOOD_LEVEL]}", f"{score} &rarr; {g.score()}",
            f"sprite {hexb(g.memory[FRANKENSTEIN])}"
            + (" (the burst)" if g.memory[FRANKENSTEIN] & 0xFC == 0x6C else "")
            + (", room byte " + hexb(g.memory[FRANKENSTEIN + 1])
                                                         if g.memory[FRANKENSTEIN] else " (empty)")])

    # Dracula with and without the crucifix.
    drac_room = start.memory[DRACULA + 1]
    g1, drac_path, _, drac_touch = hunt(DRACULA, drac_room, passes=120, where=(0x28, 0x38))
    g2, flee_path, _, flee_touch = hunt(
        DRACULA, drac_room, setup=lambda g: g.carry(0, CRUCIFIX, 0x8A, g.memory[CRUCIFIX + MODE]),
        passes=120, where=(0x48, 0x58))
    drac_pic = save(strip([multi_path_image(g1.memory, [(drac_path, (255, 80, 80))], 1),
                           multi_path_image(g2.memory, [(flee_path, (80, 255, 80))], 1)], gap=6),
                    image_dir, "monster_dracula.png")
    drac_d0 = distance(drac_path[0], (0x58, 0x68))
    flee_d0, flee_d1 = distance(flee_path[0], (0x58, 0x68)), distance(flee_path[-1], (0x58, 0x68))

    # Dracula wandering while the player is elsewhere.
    g = base.copy()
    g.memory[DRACULA + 1] = drac_room
    rooms = [drac_room]
    seconds = 60
    for _ in range(seconds * 50):
        g.frame([])
        g.calm()
        g.memory[FOOD_LEVEL] = 200
        if g.memory[DRACULA + 1] != rooms[-1]:
            rooms.append(g.memory[DRACULA + 1])
    wander_shapes = sorted({memory0[ROOM_TABLE + 2 * r + 1] for r in rooms})

    # The mummy: patrol while the red key is there, hunt once it has gone.
    mummy_room = start.memory[MUMMY + 1]
    g3, patrol, _, _ = hunt(MUMMY, mummy_room, passes=260, stop_at_touch=False,
                            knight=MUMMY_KNIGHT)
    red = KEYS["red"]
    g4, hunting, _, hunt_touch = hunt(
        MUMMY, mummy_room, setup=lambda g: g.carry(0, red, 0x81, g.memory[red + MODE]),
        passes=160, where=(0x68, 0x38))
    hunting_flag = g4.memory[MUMMY + 6] & 0x80
    mummy_pic = save(strip([multi_path_image(g3.memory, [(patrol, (255, 255, 0))], 1),
                            multi_path_image(g4.memory, [(hunting, (255, 80, 80))], 1)], gap=6),
                     image_dir, "monster_mummy.png")
    first_target = (memory0[TEMPLATE + MUMMY - PLAYER + 0x0B],
                    memory0[TEMPLATE + MUMMY - PLAYER + 0x0C])
    turns = sum(1 for k in range(1, len(patrol) - 1)
                if patrol[k] in ((0x68, 0x38), (0x8C, 0x68)) and patrol[k + 1] != patrol[k])

    # The humpback and an object in its room.
    hump_room = start.memory[HUMPBACK + 1]
    g5 = base.copy()
    obj = OBJECTS
    kind_obj = g5.memory[obj]
    g5.memory[obj + 1] = hump_room
    g5.memory[obj + X], g5.memory[obj + Y] = 0x30, 0x88
    g5.memory[HUMPBACK + 1] = hump_room
    stage_room(g5, hump_room, 0x58, 0x68)
    hump_path = []
    gone = None
    for count in range(300):
        g5.pass_([])
        hold_spawner(g5)
        hump_path.append((g5.memory[HUMPBACK + X], g5.memory[HUMPBACK + Y]))
        if g5.memory[obj] == 0 and gone is None:
            gone = count + 1
            break
    hump_pic = save(multi_path_image(g5.memory, [(hump_path, (255, 255, 0))], 1), image_dir,
                    "monster_humpback.png")

    # The devil.
    devil_room = start.memory[DEVIL + 1]
    g6, devil_path, _, devil_touch = hunt(DEVIL, devil_room, passes=120, where=(0x30, 0x40))
    devil_food = g6.memory[FOOD_LEVEL]
    for _ in range(10):
        g6.pass_([])
        hold_spawner(g6)
    devil_food_after = g6.memory[FOOD_LEVEL]

    lines = [
        "<p>The creatures that make a room dangerous are of two sorts. The small ones -- "
        "spiders, bats, ghosts, witches and the rest -- are not placed in the castle at all: "
        "they are spawned into the player's room, three at most, and wander it until they "
        "touch him, are shot, or are left behind. The big five -- the mummy, Dracula, the "
        "devil, Frankenstein's monster and the humpback -- live in slots of their own, are "
        "dispatched on every pass wherever they are, cannot be shot, and each has a rule of "
        "its own. Every example below ran through the game's own code in SkoolKit's "
        "simulator, from the first game after loading.</p>",

        "<h3>Spawning</h3>",
        f"<p>{link(SPAWN_MONSTER_INTO_ROOM)} is called once a frame from the player's handler, so "
        "only while the player is in play. A new room resets SPAWN_ROOM and a 32-frame "
        "countdown; when that runs out a creature appears, and from then on one appears on any "
        "frame when the low four bits of the refresh register are zero -- one frame in sixteen, "
        "near enough -- if one of the three slots at $EE60, $EE70 and $EE80 is free. The slot "
        f"gets {link(MONSTER_TEMPLATE)}, the player's room, a type from {link(SPAWN_TYPES)} "
        f"by the low four bits of FRAMES, a place near the middle ({link(RANDOM_POSITION)}) and "
        f"a random velocity ({link(RANDOM_VELOCITY)}). For its first 32 passes it is the "
        f"arrival animation, sprites $58-$5B ({link(SPAWN_MONSTER)}); then it becomes its "
        f"type. The sixteen entries of SPAWN_TYPES, read from the game:</p>",
        table(["Code", "Creature", "Chance in 16", "Mover", "How it moves (read)",
               f"Where it went in {TRACK_PASSES} passes"], kind_rows),
        "<p>The creatures' names are the annotations'. Each was then staged -- written into "
        "the first slot as the spawner writes one, arriving, in the middle of room $00, with "
        "the knight standing in the south doorway where nothing in the room can reach him and "
        f"the spawner held off -- and followed for {TRACK_PASSES} passes of the main loop after "
        f"its arrival (which took {arrival_passes} passes here), a dot at each:</p>",
        "".join(track_figures),
        f"<p>All of them bounce off the room's walk rectangle through {link(STEP_ACTOR)} and "
        "ignore doors and furniture; none leaves its room. Most animate by flipping bit 0 of "
        "the sprite.</p>",
        "<p>And a real game, not staged: the knight standing still in room $00 from the "
        "start for ten seconds (500 frames), the big five sent away. What happened in the "
        "slots:</p>",
        table(["When", "What"], spawn_rows),
        f"<p>The first creature came {first_spawn / 50:.2f} s in, with no grace at all: "
        f"{link(0x80CB)} has left SPAWN_ROOM at 0, which is the starting room, and the "
        "countdown at 0, so the spawner is already in its one-in-sixteen mode when the "
        "knight has risen. Anywhere else, entering the room gives 32 frames first. "
        f"{touches} creatures touched the knight in the ten seconds.</p>",

        "<h3>Touching, shooting and being left behind</h3>",
        f"<p>Every small mover calls {link(CHECK_SHOT_HIT)} and {link(CHECK_HIT)}, a 12-pixel "
        "box each way round the weapon and round the player (see <a href=\"Movement.html\">"
        "movement</a>). Either way the creature dies. Being caught costs 32 of the life force "
        "but pays the same 155 points as a shot.</p>",
        table(["Situation", "What the game did", "The code"], set_rows),

        "<h3>The big five</h3>",
        f"<p>Their records are the last five monster slots, dispatched every pass by "
        f"{link(MAIN_LOOP_MONSTERS)} wherever they are. Each homes in with {link(HOME_IN)}: a "
        "velocity of 1 on each axis towards a target, so a pixel a pass -- slower than the "
        "player's two a frame -- inside a slightly smaller rectangle than the player's. While "
        f"the player is not in play the four hunters turn round and walk away "
        f"({link(BIG_MONSTER_STEP)}). None calls CHECK_SHOT_HIT, so the axe, spell and sword "
        "pass through them. Where they start in the first game, read from the running game "
        "after START_GAME, and what a touch costs a pass:</p>",
        table(["Monster", "Record", "Starts in", "Sprite", "Mover", "Touch, per pass"],
              five_rows),
        f"<p>The mummy's room is chosen by {link(PLACE_KEYS)} with the red key's, so it is "
        "the red key's room in every game; the other four start where the template puts them. "
        "The hunters head for the player's x and y even from another room, so when he comes "
        "back they are wherever he was standing when he left, relative to the room.</p>",

        "<h4>Frankenstein's monster and the spanner</h4>",
        f"<p>{link(MOVE_FRANKENSTEIN)}: when he touches the player, if "
        f"{link(FIND_CARRIED)} finds the spanner ($8B) in the inventory, 1000 points and "
        f"{link(KILL_MONSTER)}; otherwise {link(LOSE_FOOD_EIGHT)}. Staged: the knight put in his "
        "room with Frankenstein's monster on top of him, 10 passes each way:</p>",
        table(["The knight", "Life force", "Score", "Frankenstein's slot after"], frank_rows),
        "<p>The kill adds its own 155 to the 1000, and nothing ever refills the slot.</p>",

        "<h4>Dracula and the crucifix</h4>",
        f"<p>{link(MOVE_DRACULA)} asks {link(FIND_CARRIED)} for the crucifix ($8A). With it "
        "carried he takes HOME_IN's velocity and turns it round: he runs. Without it, in the "
        f"player's room, he hunts. Staged in his room, ${drac_room:02X}, the knight in the "
        f"middle: without the crucifix Dracula went from {drac_d0} pixels away to within reach "
        f"in {drac_touch} passes; with the knight carrying it, from {flee_d0} pixels away "
        f"to {flee_d1} in {len(flee_path) - 1}, backed into the wall:</p>",
        figure("monster_dracula.png", drac_pic, "Dracula's 120 passes, without the crucifix "
               "(red) and with it (green).", scale=1),
        f"<p>Out of the player's room he wanders. On a pass that falls on a frame when FRAMES "
        "is 0 -- about once a second, since the game resets FRAMES every 50 -- he picks a "
        "random room from 0 to 127 and moves there if its shape is $00, $01 or $02 (a square "
        "hall, a cave or an octagonal hall) and it is not the player's. Left for "
        f"{seconds} seconds while the knight stood in room $00, he moved {len(rooms) - 1} "
        f"times: {', '.join(hexb(r) for r in rooms)} (shapes "
        f"{', '.join(hexb(s) for s in wander_shapes)}).</p>",

        "<h4>The mummy and the red key</h4>",
        f"<p>{link(MOVE_MUMMY)}: if object $80 is in its room it walks to it and sends it to "
        "room $6B. Otherwise, while the red key lies in its room, it walks back and forth "
        "between two points; once the key is gone it sets bit 7 of its +$06 and hunts the "
        f"player for the rest of the game. Staged in room ${mummy_room:02X} with the knight "
        f"standing in a corner at ({hexb(MUMMY_KNIGHT[0])}, {hexb(MUMMY_KNIGHT[1])}), the key "
        f"still in the room: the mummy walked from its place to ({hexb(first_target[0])}, "
        f"{hexb(first_target[1])}), the target the template gives it, and then back and forth "
        f"between ({hexb(0x68)}, {hexb(0x38)}) and ({hexb(0x8C)}, {hexb(0x68)}), the two its "
        f"code writes, for 260 passes ({turns} turns). With the red key in the knight's inventory instead (staged), bit 7 "
        f"was {'set' if hunting_flag else 'still clear'} and the mummy reached him in "
        f"{hunt_touch} passes:</p>",
        figure("monster_mummy.png", mummy_pic, "The mummy guarding (yellow) and hunting (red).",
               scale=1),

        "<h4>The humpback</h4>",
        f"<p>{link(MOVE_HUMPBACK)} looks through the eight collectables $82-$89 "
        f"({link(SCAN_COLLECTABLES)}); if one is in its room it walks to it and empties its "
        "record, and the object is gone for the game. Otherwise it stands still. Touching it "
        f"costs 16 a pass ({link(LOSE_FOOD_SIXTEEN)}). Staged: object {hexb(kind_obj)} "
        f"(its record at ${obj:04X}) put in room ${hump_room:02X} at ($30, $88) with the knight "
        f"in the middle: the humpback reached it and emptied the record after "
        f"{gone} passes.</p>",
        figure("monster_humpback.png", hump_pic, "The humpback's walk to the object.", scale=1),

        "<h4>The devil</h4>",
        f"<p>{link(MOVE_DEVIL)} hunts, costs 8 a pass, and nothing in the code stops him: "
        "no object, no weapon. Staged in his room, the knight in the middle, he reached him "
        f"at pass {devil_touch}; ten passes of touching took the life force from {devil_food} "
        f"to {devil_food_after}, eight a pass and the ordinary drain.</p>",

        evidence([
            "Run in the simulator, nothing staged: ten seconds of spawning in room $00, and "
            f"Dracula's wandering for {seconds} seconds.",
            "Staged, then run: each creature kind's track, the touch, the shot, the clearing "
            "at death, the time-out, and every big-five example -- the records and inventory "
            "written, the rest the game's own doing.",
            "Read from the game's data: SPAWN_TYPES, the handler table, where the big five "
            "start.",
        ], [
            "The movers' descriptions are read from the code; the tracks show the result, not "
            "each rule in isolation.",
            "Room $6B, where the mummy sends object $80: whether it matters to the player was "
            "not looked at.",
        ]),
    ]
    return "\n".join(lines)


# --------------------------------------------------------------------------
# Doors, keys and trapdoors.
# --------------------------------------------------------------------------

DOOR_TYPE_NOTES = {
    0x01: "cave door, always open", 0x02: "door, always open",
    0x03: "the big door frame at a staircase's top; a wider doorway",
    0x08: "red door", 0x09: "green door", 0x0A: "cyan door", 0x0B: "yellow door",
    0x0C: "red cave door", 0x0D: "green cave door", 0x0E: "cyan cave door",
    0x0F: "yellow cave door",
    0x10: "grandfather clock: a door for the knight only",
    0x17: "bookcase: for the wizard only", 0x1A: "barrel: for the serf only",
    0x18: "trapdoor, closed", 0x19: "trapdoor, open",
    0x20: "timed door, shut", 0x21: "timed door, open",
    0x22: "timed cave door, shut", 0x23: "timed cave door, open",
    0x24: "the A.C.G. door",
}
TIMED_WATCH_PASSES = 700
TRAPDOOR_WATCH_SECONDS = 60


def half_counts(memory, start: int, end: int) -> dict:
    counts = {}
    for address in range(start, end, 8):
        kind = memory[address]
        if kind:
            counts[kind] = counts.get(kind, 0) + 1
    return counts


def _doors_page(snapshot: Path, image_dir: Path, link, log) -> str:
    from PIL import Image

    memory0 = ba.game_memory(snapshot)
    started = Game.at_start(snapshot)
    started.until(ARRIVE_IN_ROOM)                    # START_GAME done: the castle set up
    template_counts = half_counts(memory0, TEMPLATE_DOORS, TEMPLATE_END)
    live_counts = half_counts(started.memory, LIVE_DOORS, 0x10000)

    kind_rows = []
    for kind in sorted(set(template_counts) | set(live_counts)):
        if kind not in DOOR_TYPE_NOTES:
            continue
        handler = handler_of(memory0, kind)
        kind_rows.append([hexb(kind), DOOR_TYPE_NOTES[kind], link(handler),
                          str(template_counts.get(kind, 0)), str(live_counts.get(kind, 0))])
    furniture_halves = sum(v for k, v in template_counts.items() if k not in DOOR_TYPE_NOTES)

    # CHOOSE_TIMED_DOORS, run from the code: before and after, pair by pair.
    before = Game.at_start(snapshot)
    before.until(CHOOSE_TIMED_DOORS)
    ticks_low = before.memory[TICKS]
    frames_low = before.memory[FRAMES]
    rom_page = (frames_low & 0x0F) | 0x10
    converted = {0x01: [0, 0], 0x02: [0, 0]}
    for address in range(LIVE_DOORS, 0x10000, 16):
        kind, other = before.memory[address], before.memory[address + 8]
        if kind in (1, 2) and kind == other:
            converted[kind][0] += 1
            if started.memory[address] in (0x20, 0x22):
                converted[kind][1] += 1
    room0_timed = [a for a in started.room_list(0) if started.memory[a] in (0x20, 0x21, 0x22, 0x23)]

    # Walking through: the arrival headings, read from the table.
    heading_rows = []
    for index, wall in ((0, "north (mode 0)"), (2, "east (mode 3)"), (4, "south (mode 4)"),
                        (6, "west (mode 7)")):
        dx, dy = memory0[ARRIVAL_HEADINGS + index], memory0[ARRIVAL_HEADINGS + index + 1]
        dx = dx - 256 if dx > 127 else dx
        dy = dy - 256 if dy > 127 else dy
        way = {(0, 32): "down", (0, -32): "up", (32, 0): "right", (-32, 0): "left"}[(dx, dy)]
        heading_rows.append([wall, f"{dx}, {dy}", way])

    # A timed door followed: the knight standing in room $00.
    log("  watching room $00's timed doors...")
    g = Game.playing(snapshot)
    g.park_big_five()
    g.calm()
    doors = [a for a in g.room_list(0) if g.memory[a] in (0x20, 0x21, 0x22, 0x23)]
    state = {a: g.memory[a] for a in doors}
    toggles = []
    waits = []
    open_pic = shut_pic = None
    south = doors[0]
    sx, sy = g.memory[south + X], g.memory[south + Y]
    for count in range(1, TIMED_WATCH_PASSES + 1):
        g.pass_([])
        g.calm()
        waits.append(g.memory[DOOR_WAIT])
        for address in doors:
            if g.memory[address] != state[address]:
                state[address] = g.memory[address]
                wall = WALL_OF_MODE.get(g.memory[address + MODE] >> 5, "?")
                toggles.append((count, wall, record_name(g.memory[address]), g.word(TICKS)))
        if south in doors:
            crop = play_area(g.memory).crop((sx - 16, sy - 32, sx + 32, sy + 8))
            if g.memory[south] & 1 and open_pic is None:
                open_pic = crop
            if not g.memory[south] & 1 and shut_pic is None:
                shut_pic = crop
    gaps = [toggles[k][0] - toggles[k - 1][0] for k in range(1, len(toggles))]
    timed_rows = [[str(c), wall, name, str(t)] for c, wall, name, t in toggles]
    door_pics = [p.resize((p.width * 3, p.height * 3), Image.NEAREST)
                 for p in (open_pic, shut_pic) if p is not None]
    timed_pic = save(strip(door_pics, gap=8), image_dir, "doors_timed.png") if door_pics else None

    # The doorway rule: standing in the south doorway as the countdown runs out.
    g2 = Game.playing(snapshot)
    g2.park_big_five()
    g2.calm()
    south_half = next(a for a in g2.room_list(0)
                      if g2.memory[a] in (0x21, 0x23) and g2.memory[a + MODE] >> 5 == 4)
    move_player(g2, 0x58, 0xA8)
    held_open = 0
    for count in range(1, 400):
        g2.pass_([])
        g2.calm()
        if g2.memory[DOOR_WAIT] == 0 and g2.memory[south_half] & 1:
            held_open += 1
        if held_open >= 20:
            break
    stayed = g2.memory[south_half]
    stayed_doorway = g2.memory[IN_DOORWAY]
    move_player(g2, 0x58, 0x68)
    shut_after = None
    for count in range(1, 200):
        g2.pass_([])
        g2.calm()
        if not g2.memory[south_half] & 1:
            shut_after = count
            break

    # Locked doors: the key carried, then dropped.
    log("  keys and locked doors...")
    colour_rows = []
    for low in range(4):
        colour = memory0[DOOR_COLOURS + low]
        colour_rows.append([str(low), f"{hexb(0x08 + low)}, {hexb(0x0C + low)}", hexb(colour),
                            colour_word(colour),
                            str(template_counts.get(0x08 + low, 0)),
                            str(template_counts.get(0x0C + low, 0))])
    playing = Game.playing(snapshot)
    lock_pics = [screen_image(draw_in_mode(playing, kind, 0).memory, (0, 6), (0, 8))
                 for kind in range(0x08, 0x10)]
    locks_pic = save(strip(lock_pics), image_dir, "doors_locked.png")
    g3 = Game.playing(snapshot)
    g3.park_big_five()
    g3.calm()
    locked = next(a for a in g3.room_list(0) if 0x08 <= g3.memory[a] <= 0x0F)
    lock_colour = memory0[DOOR_COLOURS + (g3.memory[locked] & 3)]
    key = next(a for a in KEYS.values() if g3.memory[a + MODE] == lock_colour)
    key_rows = []
    key_rows.append(["At the start, no key", "shut" if g3.memory[locked + MODE] & 8 else "open"])
    g3.carry(0, key, 0x81, lock_colour)
    g3.pass_([])
    g3.pass_([])
    key_rows.append([f"The {colour_word(lock_colour)} key written into slot 1, two passes later",
                     ("shut" if g3.memory[locked + MODE] & 8 else "open") + ", both halves: "
                     + ("the same" if (g3.memory[locked + MODE] & 8) == (g3.memory[(locked ^ 8) + MODE] & 8)
                        else "different")])
    g3.put(CARRIED, [0, 0, 0, 0])
    g3.pass_([])
    g3.pass_([])
    key_rows.append(["The slot emptied again, two passes later",
                     "shut" if g3.memory[locked + MODE] & 8 else "open"])

    key_place_rows = []
    for name, table_address, source in (
            ("green", RANDOM_ROOMS[0], "FRAMES AND 7"),
            ("red (and the mummy)", RANDOM_ROOMS[1], "(FRAMES + TICKS) AND 7"),
            ("cyan", RANDOM_ROOMS[2], "(FRAMES' high byte + TICKS' high byte) AND 7")):
        rooms = [memory0[table_address + k] for k in range(8)]
        record = KEYS[name.split()[0]]
        chosen = started.memory[record + 1]
        key_place_rows.append([name, link(table_address), source,
                               ", ".join(("<b>" + hexb(r) + "</b>") if r == chosen else hexb(r)
                                         for r in rooms),
                               room_ref(memory0, chosen)])
    yellow_room = started.memory[KEYS["yellow"] + 1]
    key_place_rows.append(["yellow", "(the template)", "never moved", "", room_ref(memory0, yellow_room)])

    # The characters' doors: a clock, tried by each character.
    log("  the characters' doors...")
    clock_room, clock = None, None
    for room in range(149):
        for address in started.room_list(room):
            if started.memory[address] == 0x10 and started.memory[address + MODE] >> 5 == 0:
                clock_room, clock = room, address
                break
        if clock is not None:
            break
    clock_record = started.record(clock, 8)
    clock_other = started.memory[(clock ^ 8) + 1]
    char_rows = []
    for name in ("knight", "wizard", "serf"):
        g4 = Game.playing(snapshot, name)
        g4.park_big_five()
        g4.calm()
        stage_room(g4, clock_room, clock_record[X] + 4, clock_record[Y] + 0x30)
        result = None
        for count in range(1, 60):
            g4.frame([UP])
            g4.calm()
            if g4.memory[ROOM] != clock_room:
                result = f"through, into room ${g4.memory[ROOM]:02X}, after {count} frames"
                break
        if result is None:
            live = clock
            result = (f"stopped at y {hexb(g4.memory[PLAYER_Y])} under it, the clock shut "
                      f"(bit 3 of its +$05 {'set' if g4.memory[live + MODE] & 8 else 'clear'})")
        char_rows.append([name, result])

    # A trapdoor: the fall, followed.
    log("  following a fall through a trapdoor...")
    trap_room, trap = None, None
    for room in range(149):
        for address in started.room_list(room):
            if started.memory[address] == 0x19:
                trap_room, trap = room, address
                break
        if trap is not None:
            break
    live_trap = trap
    trap_record = started.record(trap, 8)
    landing_room = started.memory[(trap ^ 8) + 1]
    g6 = Game.playing(snapshot)
    g6.park_big_five()
    g6.calm()
    stage_room(g6, trap_room, trap_record[X] + 4, trap_record[Y] - 0x24)
    g6.keys([DOWN])
    walked = 0
    while True:
        stop = g6.until((FALL_STARTS, FRAME_TICK))
        if stop == FALL_STARTS:
            break
        walked += 1
        g6.calm()
        if walked > 200:
            raise RuntimeError("the knight never reached the trapdoor")
    g6.keys([])
    fall_pics = [screen_image(g6.memory, (0, 24), (0, 24))]
    run_pics = []
    fall_start = g6.tstates
    steps = 0
    shaft = None
    while True:
        stop = g6.until((0x976F, ENTER_ROOM))
        if stop == ENTER_ROOM:
            break
        steps += 1
        if steps == 1:
            shaft = screen_image(g6.memory, (0, 24), (0, 24), attributes=False)
        if steps in (8, 64, 120):
            fall_pics.append(screen_image(g6.memory, (0, 24), (0, 24)))
        if 40 <= steps < 48:
            run_pics.append(screen_image(g6.memory, (0, 24), (0, 24)))
    fall_time = g6.tstates - fall_start
    g6.until(MAIN_LOOP)
    g6.until(MAIN_LOOP)
    landed = g6.player()
    fall_pics.append(screen_image(g6.memory, (0, 24), (0, 24)))
    fall_strip = save(strip([p.resize((96, 96), Image.NEAREST) for p in fall_pics], gap=4),
                      image_dir, "doors_fall.png")
    run_strip = save(strip([p.resize((96, 96), Image.NEAREST) for p in run_pics], gap=4),
                     image_dir, "doors_fall_steps.png")
    shaft_pic = save(shaft, image_dir, "doors_fall_shaft.png")

    # A trapdoor's own opening and shutting, with the knight in its room.
    g7 = Game.playing(snapshot)
    g7.park_big_five()
    g7.calm()
    stage_room(g7, trap_room, 0x30, 0x40)
    trap_state = g7.memory[live_trap]
    trap_events = []
    frames = 0
    while frames < TRAPDOOR_WATCH_SECONDS * 50:
        g7.frame([])
        g7.calm()
        g7.memory[FOOD_LEVEL] = 200
        frames += 1
        if g7.memory[live_trap] != trap_state:
            trap_state = g7.memory[live_trap]
            trap_events.append((frames, trap_state, g7.word(TICKS)))
    trap_rows = [[f"{f / 50:.1f} s", "closed" if t == 0x18 else "open", f"${ticks:04X}"]
                 for f, t, ticks in trap_events]
    closes = sum(1 for _, t, _ in trap_events if t == 0x18)
    closed_frames = 0
    shut_since = None
    for f, t, _ in trap_events:
        if t == 0x18:
            shut_since = f
        elif shut_since is not None:
            closed_frames += f - shut_since
            shut_since = None
    if shut_since is not None:
        closed_frames += TRAPDOOR_WATCH_SECONDS * 50 - shut_since
    open_share = 100 - 100 * closed_frames / (TRAPDOOR_WATCH_SECONDS * 50)

    total_timed = converted[1][1] + converted[2][1]
    lines = [
        "<p>A door in Atic Atac is one sixteen-byte record whose two eight-byte halves stand in "
        "the two rooms it joins. Its type says what kind of door it is -- plain, locked, timed, a "
        "trapdoor, a secret passage for one character, the way out -- and picks the handler "
        "that the room's list dispatches it to on every pass. This page reads the kinds from "
        "the game, then follows the doors that change: the timed doors, chosen at random when "
        "a game starts and opening and shutting by themselves; the locked doors and their keys; "
        "the characters' doors; and the trapdoors. Everything was run through the game's own "
        "code in SkoolKit's simulator, from the first game after loading.</p>",

        "<h3>The record</h3>",
        table(["Offset", "In a door's half"], [
            ["+$00", "type: which kind of door (and, less $A1, which graphic draws it)"],
            ["+$01", "the room this half stands in"],
            ["+$02", "where the player arrives coming through the other way: the low nibble "
                     "twice is added to this half's x, the high nibble twice taken from its y"],
            ["+$03, +$04", "x and y of the door's bottom-left corner"],
            ["+$05", "bits 7-5 the drawing mode, which is also the wall (0 north, 4 south, 3 "
                     "east, 7 west); bit 3 shut; bit 2 solid; bits 1-0 how it meets the screen"],
            ["+$06, +$07", "its walk box (see <a href=\"Movement.html\">movement</a>)"],
        ]),
        f"<p>The two halves are eight bytes apart, so {link(DOOR_OTHER_SIDE)} finds the far "
        f"side by flipping bit 3 of the address, and {link(OPEN_DOOR)} and {link(SHUT_DOOR)} "
        "always set or clear bit 3 of +$05 on both, so the two sides never disagree. Furniture "
        "uses the same record, though nothing passes between its halves "
        f"({furniture_halves} halves of the template have types that are not doors).</p>",

        "<h3>The kinds</h3>",
        f"<p>A room record of type t is dispatched from entry $A2 + t of "
        f"{link(ACTOR_HANDLERS)} ({link(DISPATCH_FROM_LIST)} starts its lookup at $802A). The door types, their handlers read from that table, and "
        "how many record halves of each there are in the template and in the first game once "
        "START_GAME has run:</p>",
        table(["Type", "What", "Handler", "Halves in the template", "In the first game"],
              kind_rows),
        "<p>Types $18 and $20-$23 are not in the template: the game makes them as it runs.</p>",

        "<h3>Walking through</h3>",
        f"<p>{link(DOOR)} asks {link(PLAYER_AT_DOOR)} whether the player is in the door's "
        f"box -- 17 pixels each way, halved across the door -- and, if he is, calls "
        f"{link(ENTER_ROOM)}: to the other half; its room becomes the player's; its +$02 gives "
        f"where he appears; {link(SET_ARRIVAL_HEADING)} gives him a heading of 32 away from "
        f"the arrival door's wall, from {link(ARRIVAL_HEADINGS)}:</p>",
        table(["Arrival door's wall", "Heading (x, y)", "He walks"], heading_rows),
        "<p>and the low nibble of his +$02 is set to 15. Then the room is drawn (see <a "
        "href=\"Drawing.html\">drawing</a>). While the nibble counts down, once a frame, the "
        "controls are ignored and he walks in on his own, and no door can fire, so he cannot "
        "bounce straight back out; a run on <a href=\"Movement.html\">the movement page</a> "
        "shows the fifteen frames. Creatures in the old room stay there; a weapon in flight "
        "vanishes, since it is no longer in the player's room.</p>",

        "<h3>Timed doors</h3>",
        f"<p>Once, at the start of a game, {link(CHOOSE_TIMED_DOORS)} walks every door record. "
        "Where both halves are a plain door ($02) or a plain cave door ($01), it reads a byte "
        "from a pointer made of TICKS' low byte and FRAMES' low four bits with bit 4 set -- an "
        "address in the ROM, $1000-$1FFF, stepped on a byte per record -- and if the byte is "
        "below $70, makes both halves a shut timed door ($20) or timed cave door ($22). The "
        "ROM is the random numbers. In the first game after loading TICKS is "
        f"{ticks_low} and FRAMES' low byte {hexb(frames_low)} when it runs, so it reads from "
        f"${rom_page:02X}{ticks_low:02X} on, and it made {converted[2][1]} of the "
        f"{converted[2][0]} plain doors and {converted[1][1]} of the {converted[1][0]} plain "
        f"cave doors timed ({total_timed} doors in all, counted pair by pair from the records "
        "before and after). The same doors, every first game: FRAMES is frozen on the title "
        f"screen. Room $00 has {len(room0_timed)} of them.</p>",
        f"<p>A timed door's handler ({link(TIMED_DOOR_SHUT)} or {link(TIMED_DOOR_OPEN)}) does "
        "nothing on odd passes; on even passes it counts down one shared counter, DOOR_WAIT. "
        f"The door that finds it at zero calls {link(TOGGLE_TIMED_DOOR)}: the counter back to "
        f"{memory0[TOGGLE_TIMED_DOOR + 1]}, the picture XORed off, bit 0 of the type flipped on "
        "both halves ($20 and $21, $22 and $23), the door opened or shut to match, the new "
        "picture drawn, and a rasp. Only the doors in the player's room are dispatched, so only "
        "they count down. Followed in room $00, the knight standing still for "
        f"{TIMED_WATCH_PASSES} passes:</p>",
        table(["Pass", "Wall", "Became", "TICKS"], timed_rows),
        (f"<p>The toggles came {span_text(gaps)} passes apart" if gaps else "<p>")
        + f": with {len(doors)} timed doors in the room both count the one counter down on "
        f"every even pass, so it empties twice as fast as it would for one, and they take "
        f"turns. The south door open and shut:</p>",
        figure("doors_timed.png", timed_pic, "Room $00's south door, open and shut.", scale=1)
        if timed_pic else "",
        f"<p>An open timed door will not shut while the player is in a doorway: at zero, "
        f"TIMED_DOOR_OPEN looks at IN_DOORWAY and just acts as a door. Staged: the knight put "
        f"in room $00's south doorway, at y $A8, below the rectangle. The counter reached zero "
        f"and stayed there for {held_open} passes with the door still "
        f"{'open' if stayed & 1 else 'shut'} (IN_DOORWAY {stayed_doorway}); put back in the "
        f"middle of the room, the door shut {shut_after} pass{'es' if shut_after != 1 else ''} "
        "later.</p>",

        "<h3>Locked doors and the keys</h3>",
        f"<p>Types $08-$0B are locked doors and $0C-$0F locked cave doors, their colour the "
        f"low two bits of the type through {link(DOOR_COLOURS)}. All four colours are one "
        "graphic with four colour tables; drawn by the game, the doors then the cave doors:</p>",
        figure("doors_locked.png", locks_pic, "Types $08-$0F, drawn by the game's drawers.",
               scale=2),
        table(["Low bits", "Types", "Colour", "", "Door halves", "Cave door halves"],
              colour_rows),
        f"<p>On every pass {link(DOOR_NEEDS_KEY)} asks {link(FIND_CARRIED)} for sprite $81 (a key) "
        "in the door's colour among the three carried things. Not carried: SHUT_DOOR, and the "
        "walk test ignores its doorway. Carried: OPEN_DOOR, and PLAYER_AT_DOOR as for any door; "
        f"going through, {link(DOOR_LOCKED_A)} sets both halves to $02 ({link(DOOR_LOCKED_B)} "
        "to $01) -- a plain door, open to anyone, for the rest of the game -- and the key is "
        f"kept. Room $00's {record_name(g3.memory[locked])}, with its key given and taken "
        "away (staged in the inventory):</p>",
        table(["", "The door"], key_rows),
        "<p>The movement page shows the knight going through with the key: the door becomes "
        f"type $02 on both halves. Where the keys are is chosen by {link(PLACE_KEYS)} at the "
        "start of a game, before the template is copied, from three tables of eight rooms; "
        "TICKS is always 0 at that moment, so the green and red keys use the same index and "
        "move together. The yellow key never moves. The first game's rooms in bold:</p>",
        table(["Key", "Table", "Index", "Candidates", "First game"], key_place_rows),

        "<h3>Doors that know who you are</h3>",
        f"<p>{link(DOOR_KNIGHT)}, {link(DOOR_WIZARD)} and {link(DOOR_SERF)} -- a grandfather "
        "clock, a bookcase and a barrel -- take the character's first sprite code from the "
        "player's and ask whether what is left is under 16. The right character gets "
        "OPEN_DOOR and an ordinary doorway; anyone else gets SHUT_DOOR and a picture. Each "
        f"character was staged in room ${clock_room:02X} below its clock (at "
        f"{hexb(clock_record[X])}, {hexb(clock_record[Y])}, in the north wall, leading to room "
        f"${clock_other:02X}) and walked up into it:</p>",
        table(["Character", "What happened"], char_rows),

        "<h3>Trapdoors</h3>",
        f"<p>All {template_counts.get(0x19, 0)} trapdoors start open, type $19. The open "
        f"trapdoor's handler ({link(TRAPDOOR)}) jumps to {link(TRAPDOOR_FALL)} unless the "
        "byte RUNNING_SUM is zero, when it closes instead (the tail of "
        f"{link(TRAPDOOR_CLOSED)}, which flips the type to $18). A closed one opens again "
        "whenever TICKS' low byte is zero, every 256 passes. RUNNING_SUM is a running sum of "
        "FRAMES and TICKS that MAIN_LOOP keeps at the end of every pass. The trapdoor in room "
        f"${trap_room:02X}, watched for {TRAPDOOR_WATCH_SECONDS} seconds with the knight "
        f"standing well away from it: it closed {closes} times and was open "
        f"{open_share:.0f}% of the time, each time opening on the pass after TICKS' low byte "
        "came round to zero:</p>",
        table(["When", "It became", "TICKS"], trap_rows) if trap_rows else
        "<p>(It did not change in that time.)</p>",
        f"<p>{link(TRAPDOOR_FALL)} asks PLAYER_AT_DOOR with a box of 24 by 12. On it, the "
        "play area is cleared and drawn as entry $96 of the room table -- twelve nested "
        "rectangles -- and for 128 frames a falling tone plays while the middle four "
        "attribute cells are white one frame in eight and black otherwise, spread outwards by "
        "the spiral fill; then ENTER_ROOM, through the trapdoor's other half, which is the "
        f"landing place in the room below. Staged: the knight put in room ${trap_room:02X} "
        f"above the trapdoor and walked down onto it ({walked} frames). The fall took "
        f"{fall_time / FRAME_TSTATES:.0f} frames -- 128 steps, each waiting for FRAMES to "
        "move, and some of the tone's beeps outlast a frame -- and he landed in room "
        f"${landed[0]:02X} at ({hexb(landed[1])}, {hexb(landed[2])}) (the trapdoor's other half "
        f"says room ${landing_room:02X}).</p>",
        "<p>The rectangles are drawn in the fall's own colour, black on black, so they are "
        "seen only where the attributes are white: each step the spiral fill copies every "
        "cell's colour from the one inside it, so the white pulses from the middle travel "
        "outwards a ring of cells a step, lighting whatever part of a rectangle lies in a white "
        "ring -- here the bottom and right-hand sides, where the lines and the cells line up. The pixels on their own, "
        "then the play area as shown at the start of the fall, after 8, 64 and 120 steps, and "
        "in the room below; then eight steps in a row, 40 to 47:</p>",
        figure("doors_fall_shaft.png", shaft_pic, "The fall's pixels, ink only.", scale=1),
        figure("doors_fall.png", fall_strip, "The fall.", scale=1),
        figure("doors_fall_steps.png", run_strip, "Steps 40-47.", scale=1),

        evidence([
            "Run in the simulator, nothing staged: CHOOSE_TIMED_DOORS in the first game (the "
            "records compared before and after), the timed doors of room $00 followed pass by "
            "pass, and the key rooms chosen by PLACE_KEYS.",
            "Staged, then run: the doorway rule (the knight put in the doorway), the locked "
            "door with its key given and taken away, each character at the clock, the fall "
            f"(the knight put in room ${trap_room:02X}), and the trapdoor watched in its room.",
            "Read from the game's data: the types and handlers, the arrival headings, the door "
            "colours, the key tables.",
        ], [
            "That timed doors in rooms the player is not in are frozen follows from their "
            "handlers being dispatched only from the player's room's list; it was not watched.",
        ]),
    ]
    return "\n".join(lines)


# --------------------------------------------------------------------------
# Food, health and the A.C.G. key.
# --------------------------------------------------------------------------

COLLECTABLE_USES = {
    0x80: "the mummy walks to it and sends it to room $6B (MOVE_MUMMY)",
    0x81: "opens the locked doors of its colour (DOOR_NEEDS_KEY)",
    0x8A: "carried, Dracula runs from the player (MOVE_DRACULA)",
    0x8B: "carried, touching Frankenstein's monster kills him (MOVE_FRANKENSTEIN)",
    0x8C: "the A.C.G. key's first piece (ACG_DOOR)",
    0x8D: "the second piece",
    0x8E: "the third piece",
}
INVENTORY_BOX = (192, 20, 256, 48)      # the scroll's three slots, DRAW_INVENTORY at ($C8, $2C)
ROAST_BOX = (192, 81, 256, 124)


def draw_sprite(game: Game, code: int, colour: int):
    """One sprite drawn by the game's own DRAW_THING and DRAW_AT_POSITION
    on a blank screen, through a scratch record in the first creature slot."""
    h = game.copy()
    for address in range(0x4000, 0x5800):
        h.memory[address] = 0
    for address in range(0x5800, 0x5B00):
        h.memory[address] = 0
    record = CREATURE_SLOTS[0]
    h.put(record, [code, h.memory[ROOM], 0, 0x10, 0x17, colour] + [0] * 10)
    h.call(ACTOR_TO_WORKSPACE, {"IX": record})
    h.call(DRAW_THING, {"IX": record})
    h.call(0x92E0, {"IX": record})
    return screen_image(h.memory, (2, 5), (0, 3))


def press_pick_up(game: Game, frames: int = 3) -> None:
    """SYMBOL SHIFT held for a few frames, then let go for as many: one press."""
    for _ in range(frames):
        game.frame([PICK])
        game.calm()
    for _ in range(frames):
        game.frame([])
        game.calm()


def place_at_feet(game: Game, record: int) -> None:
    """An object's record moved to where the player stands (staged)."""
    game.memory[record + 1] = game.memory[ROOM]
    game.memory[record + X] = game.memory[PLAYER_X]
    game.memory[record + Y] = game.memory[PLAYER_Y]


def carried(game: Game) -> list:
    return [game.memory[CARRIED + 4 * k + 2] for k in range(3)]


def _quest_page(snapshot: Path, image_dir: Path, link, log) -> str:
    from PIL import Image

    memory0 = ba.game_memory(snapshot)
    started = Game.at_start(snapshot)
    started.until(ARRIVE_IN_ROOM)
    base = Game.playing(snapshot)
    base.calm()
    base.park_big_five()

    # The drains, their sizes read from the code.
    drain_rows = [
        ["time", f"{link(PLAYER_TICK)}, on every frame of a pass when TICKS AND 15 is 0", "1",
         "when it reaches 0"],
        ["a small creature's touch", link(LOSE_FOOD_THIRTY_TWO),
         str(memory0[LOSE_FOOD_THIRTY_TWO + 4]), "at 0 or below"],
        ["the mummy, Dracula, the devil or Frankenstein's monster, a pass in contact",
         link(LOSE_FOOD_EIGHT), str(memory0[LOSE_FOOD_EIGHT + 4]), "only when it goes below 0"],
        ["the humpback, a pass in contact", link(LOSE_FOOD_SIXTEEN),
         str(memory0[LOSE_FOOD_SIXTEEN + 4]), "only when it goes below 0"],
        ["standing on a mushroom, a pass", link(MUSHROOM_DRAIN), "1", "when it reaches 0"],
    ]
    log("  measuring the life force...")
    g = base.copy()
    food0, ticks0, t0 = g.memory[FOOD_LEVEL], g.word(TICKS), g.tstates
    for _ in range(1000):
        g.frame([])
        g.calm()
    lost = food0 - g.memory[FOOD_LEVEL]
    passes = (g.word(TICKS) - ticks0) & 0xFFFF
    seconds = (g.tstates - t0) / TSTATES_PER_SECOND
    full_lasts = 240 / (lost / seconds)

    # The zero wrap: the devil's touch at 8, then the time drain.
    g = base.copy()
    g.memory[FOOD_LEVEL] = 8
    g.memory[DEVIL + 1] = 0
    g.memory[DEVIL + X], g.memory[DEVIL + Y] = g.memory[PLAYER_X], g.memory[PLAYER_Y]
    wrap_values = [8]
    for _ in range(400):
        g.frame([])
        g.calm()
        if g.memory[FOOD_LEVEL] != wrap_values[-1]:
            wrap_values.append(g.memory[FOOD_LEVEL])
            if wrap_values[-1] == 0:
                g.memory[DEVIL + 1] = 0x95
            if len(wrap_values) >= 4 or not g.in_play():
                break

    # The roast at several levels, drawn by DRAW_FOOD.
    g = base.copy()
    roasts = []
    for level in (240, 180, 120, 60, 16):
        g.memory[FOOD_LEVEL] = level
        g.call(DRAW_FOOD)
        roasts.append(screen_image(g.memory).crop(ROAST_BOX))
    roast_pic = save(strip(roasts), image_dir, "quest_roast.png")

    # Eating.
    food_rows = []
    for level in (100, 200):
        g = base.copy()
        g.memory[FOOD_LEVEL] = level
        g.memory[FOOD + 1] = 0
        place_at_feet(g, FOOD)
        kind = g.memory[FOOD]
        g.frames(2, [])
        food_rows.append([f"{level}", f"{hexb(kind)} at the knight's feet (staged)",
                          str(min(240, level + 64)), str(g.memory[FOOD_LEVEL]),
                          "empty" if g.memory[FOOD] == 0 else "still there"])
    food_kinds = {}
    for address in range(FOOD, MUSHROOMS, 8):
        kind = started.memory[address]
        food_kinds.setdefault(kind, started.memory[address + MODE])
    food_pics = [draw_sprite(base, kind, food_kinds[kind]) for kind in sorted(food_kinds)]
    food_pic = save(strip([p.resize((p.width * 3, p.height * 3), Image.NEAREST) for p in food_pics]),
                    image_dir, "quest_food.png")

    # Regrowth, staged: an emptied slot in another room, the cursor just before it.
    g = base.copy()
    slot = next(a for a in range(FOOD, MUSHROOMS, 8) if g.memory[a + 1] != 0)
    slot_room = g.memory[slot + 1]
    g.memory[slot] = 0
    g.put(REGROW_CURSOR, [(slot - 8) & 0xFF, (slot - 8) >> 8])
    g.until(MAIN_LOOP)
    g.put(TICKS, [0xFF, 0x01])
    g.pass_([])
    g.pass_([])
    regrown = g.memory[slot]

    # Mushrooms.
    g = base.copy()
    mushroom = MUSHROOMS
    mroom = g.memory[mushroom + 1]
    mx, my = g.memory[mushroom + X], g.memory[mushroom + Y]
    stage_room(g, mroom, mx, my)
    g.memory[FOOD_LEVEL] = 200
    before = g.memory[FOOD_LEVEL]
    ticks_before = g.word(TICKS)
    for _ in range(40):
        g.pass_([])
        g.calm()
    mush_lost = before - g.memory[FOOD_LEVEL]
    mush_passes = (g.word(TICKS) - ticks_before) & 0xFFFF

    # Dying and rising, followed.
    log("  following a death...")
    g = base.copy()
    g.memory[FOOD_LEVEL] = 1
    px, py = g.memory[PLAYER_X], g.memory[PLAYER_Y]
    phases = []
    shots = []
    frame = 0
    sprite = g.memory[PLAYER]
    lives_before = g.memory[LIVES]
    while frame < 400:
        g.frame([])
        g.calm()
        frame += 1
        now = g.memory[PLAYER]
        phase = ("in play" if 0 < now <= 0x30 else "sinking" if now == 0x67 else
                 "waiting, the score flashing" if now == 0x66 and g.memory[FLASH_COUNT] else
                 "rising" if now == 0x66 else hexb(now))
        if not phases or phases[-1][0] != phase:
            phases.append([phase, frame, frame])
        else:
            phases[-1][2] = frame
        shots.append((phase, frame, screen_image(g.memory).crop((px - 16, py - 36, px + 32, py + 12))))
        if phase == "in play" and len(phases) > 2:
            break
    grave = next((a for a in range(GRAVESTONES, GRAVESTONES + 32, 8) if g.memory[a] == 0x8F), None)
    death_rows = [[p, str(b - a + 1)] for p, a, b in phases if p != "in play"]
    picks = []
    for phase, count in (("sinking", 4), ("waiting, the score flashing", 1), ("rising", 5),
                         ("in play", 1)):
        these = [shot for shot in shots if shot[0] == phase]
        if these:
            step = max(1, len(these) // count)
            picks += these[::step][:count]
    pick_frames = [str(f) for _, f, _ in picks]
    death_pic = save(strip([p.resize((p.width * 2, p.height * 2), Image.NEAREST)
                            for _, _, p in picks]), image_dir, "quest_death.png")
    lives_after = g.memory[LIVES]

    # Game over, staged.
    g = base.copy()
    g.memory[LIVES] = 0
    g.memory[FOOD_LEVEL] = 1
    g.until(GAME_OVER)
    g.until(END_DELAY)
    over_pic = save(play_area(g.memory), image_dir, "quest_game_over.png")

    # The collectables in the first game.
    log("  objects and the inventory...")
    collect_rows = []
    for address in list(ACG_PIECES) + list(KEYS.values()) + [MUMMY_LURE, CRUCIFIX, SPANNER] + \
            [OBJECTS + 8 * k for k in range(8)]:
        record = started.record(address, 8)
        picture = draw_sprite(base, record[0], record[MODE])
        name = f"quest_object_{address:04X}.png"
        big = save(picture.resize((picture.width * 2, picture.height * 2), Image.NEAREST),
                   image_dir, name)
        use = COLLECTABLE_USES.get(record[0], "nothing but the humpback (MOVE_HUMPBACK)")
        collect_rows.append([img(name, big, f"sprite {hexb(record[0])}", 1, shrink=False),
                             hexb(record[0]), f"${address:04X}", colour_word(record[MODE]),
                             room_ref(memory0, record[1]), use])

    # The queue, with real presses of SYMBOL SHIFT.
    g = base.copy()
    queue_rows, queue_pics = [], []
    items = [("the crucifix", CRUCIFIX), ("the spanner", SPANNER), ("object $82", OBJECTS),
             ("the green key", KEYS["green"])]
    for name, record in items:
        place_at_feet(g, record)
        press_pick_up(g)
        queue_rows.append([f"{name} put at his feet (staged), SYMBOL SHIFT pressed",
                           ", ".join(hexb(c) if c else "empty" for c in carried(g)),
                           ""])
        queue_pics.append(screen_image(g.memory).crop(INVENTORY_BOX))
    dropped = items[0][1]
    queue_rows[-1][2] = (f"{items[0][0]} is back on the floor: room ${g.memory[dropped + 1]:02X} "
                         f"at ({hexb(g.memory[dropped + X])}, {hexb(g.memory[dropped + Y])}), "
                         f"the knight at ({hexb(g.memory[PLAYER_X])}, {hexb(g.memory[PLAYER_Y])})")
    for walk_keys in ([RIGHT], [DOWN]):
        for _ in range(12):
            g.frame(walk_keys)
            g.calm()
        oldest = g.word(CARRIED + 8)
        oldest_sprite = g.memory[CARRIED + 10]
        press_pick_up(g)
        fell = (f"{hexb(oldest_sprite)} fell at his feet: room ${g.memory[oldest + 1]:02X}, "
                f"({hexb(g.memory[oldest + X])}, {hexb(g.memory[oldest + Y])})"
                if oldest else "nothing fell")
        queue_rows.append(["walked twelve frames away, SYMBOL SHIFT pressed on nothing",
                           ", ".join(hexb(c) if c else "empty" for c in carried(g)), fell])
        queue_pics.append(screen_image(g.memory).crop(INVENTORY_BOX))
    queue_pic = save(strip([p.resize((p.width * 2, p.height * 2), Image.NEAREST) for p in queue_pics]),
                     image_dir, "quest_queue.png")

    # The A.C.G. key: where the pieces go.
    set_rows = []
    chosen = [started.memory[a + 1] for a in ACG_PIECES]
    for index in range(8):
        rooms = [memory0[KEY_ROOM_SETS + 3 * index + k] for k in range(3)]
        mark = " (the first game)" if rooms == chosen else ""
        set_rows.append([str(index) + mark] + [room_ref(memory0, r) for r in rooms])

    # The door's order, both ways, and a win with real key presses.
    log("  winning...")
    door = next(a for a in base.room_list(0) if base.memory[a] == 0x24)
    order_rows = []
    for order in ((0x8C, 0x8D, 0x8E), (0x8E, 0x8D, 0x8C)):
        g = base.copy()
        for slot_index, sprite in enumerate(order):
            g.carry(slot_index, ACG_PIECES[sprite - 0x8C], sprite, 0x46)
        g.pass_([])
        g.pass_([])
        order_rows.append([", ".join(hexb(c) for c in order),
                           "shut" if g.memory[door + MODE] & 8 else "open"])
    g = base.copy()
    for sprite in (0x8E, 0x8D, 0x8C):
        place_at_feet(g, ACG_PIECES[sprite - 0x8C])
        press_pick_up(g)
    in_hand = carried(g)
    walk_start = g.tstates
    g.until(ENTER_ROOM, [RIGHT], limit=5 * TSTATES_PER_SECOND)
    walk = round((g.tstates - walk_start) / FRAME_TSTATES)
    g.until(ARRIVE_IN_ROOM)
    arrived = g.player()
    g.until(SHOW_END_SCREEN)
    g.until(END_DELAY)
    end_pic = save(play_area(g.memory), image_dir, "quest_end.png")
    end_time, end_score = g.clock(), g.score()
    end_seen = g.memory[0x5E54]
    wrong = base.copy()
    for sprite in (0x8C, 0x8D, 0x8E):
        place_at_feet(wrong, ACG_PIECES[sprite - 0x8C])
        press_pick_up(wrong)
    wrong_hand = carried(wrong)
    for _ in range(40):
        wrong.frame([RIGHT])
        wrong.calm()
    wrong_stop = wrong.player()

    # The percentage, run through COUNT_ROOMS_EXPLORED.
    pct_rows = []
    for count in (1, 2, 3, 4, 30, 75, 100, 148, 149):
        h = base.copy()
        for k in range(19):
            h.memory[ROOMS_SEEN + k] = 0
        for room in range(count):
            h.memory[ROOMS_SEEN + room // 8] |= 1 << (room % 8)
        h.call(COUNT_ROOMS_EXPLORED)
        pct_rows.append([str(count), f"{h.memory[0x5E54]:X}"])

    lines = [
        "<p>The knight, the wizard or the serf is trapped in the castle with a life force that "
        "runs down, and gets out through the great door in the starting room with the three "
        "pieces of the A.C.G. key -- carried in the right order. This page follows the life "
        "force, food, dying, the objects and the three-slot inventory, and the key, and "
        "ends with a win played through the game's own code in SkoolKit's simulator. The "
        "first game after loading always hides everything in the same places (FRAMES is "
        "frozen on the title screen), so the rooms named here are that game's.</p>",

        "<h3>The life force</h3>",
        "<p>One byte, FOOD_LEVEL, 240 at the start of each life, drawn as the roast on the "
        "scroll. What takes it away, the amounts read from the code:</p>",
        table(["Cause", "Where", "Units", "Death"], drain_rows),
        f"<p>The time drain's gate counts passes of the main loop, not frames, and stays open "
        "for every frame of the pass on which it is true, so it takes one or two units in "
        f"sixteen passes. Standing in room $00 with creatures kept away, the knight lost {lost} "
        f"units in {seconds:.1f} seconds ({passes} passes): a full 240 lasts about "
        f"{full_lasts:.0f} seconds with nothing else happening.</p>",
        f"<p>{link(DRAW_FOOD)} redraws the roast only when the level crosses a multiple of "
        "eight: the whole roast with rows taken off its top, one per eighth, over the picture "
        "of the bones. The scroll's roast at 240, 180, 120, 60 and 16, drawn by DRAW_FOOD:</p>",
        figure("quest_roast.png", roast_pic, "The roast at five levels.", scale=2),
        f"<p>One quirk: {link(LOSE_FOOD_EIGHT)} and {link(LOSE_FOOD_SIXTEEN)} die only on a "
        "borrow, so a touch that leaves exactly 0 is survived, and if the next thing to happen "
        "is the time drain its <code>DEC A</code> turns 0 into 255 -- a full roast and more. "
        f"Staged: the life force set to 8 and the devil put on the knight in room $00. It went "
        f"{' &rarr; '.join(str(v) for v in wrap_values)}: the touch left 0, the devil was then "
        "sent away, and the next drain made it 255. (Another touch at 0 would have killed: "
        "0 - 8 borrows.)</p>",

        "<h3>Food</h3>",
        f"<p>Eighty pieces, ten each of eight kinds, $50-$57, each with its room. "
        f"{link(EAT_FOOD)}: when the player is within 12 pixels, the food is rubbed out, its "
        "slot emptied, a sound started, and 64 added to the life force, capped at 240. The "
        "eight kinds, drawn by the game:</p>",
        figure("quest_food.png", food_pic, "Food $50-$57.", scale=1),
        table(["Life force before", "Food", "Worked out", "Life force two frames later",
               "The food's record"], food_rows),
        "<p>Where the two differ by one, the time drain took its unit in the same frames.</p>",
        f"<p>Eaten food grows back. {link(REGROW_FOOD)} runs when TICKS is a multiple of 512: "
        "it steps a cursor on to the next of the eighty food slots, and if that slot is empty "
        "and not in the player's room refills it with kind $50 + (FRAMES AND 7), in its old "
        f"place. Staged: the food slot at ${slot:04X} (room ${slot_room:02X}) emptied, the "
        "cursor put just before it and TICKS just before a multiple of 512; two passes later "
        f"the slot held {hexb(regrown)}. A round of all eighty takes 40,960 passes, about half "
        "an hour.</p>",
        f"<p>Sixteen mushrooms are the other way round. {link(MUSHROOM)}: while the player is "
        "within 12 pixels it takes a unit a pass and makes the caught sound; when the life "
        "force runs out the mushroom is rubbed out too and the life is lost. There is no "
        f"in-play test, so it drains a rising player as well. Staged in room ${mroom:02X} with "
        f"the knight on its first mushroom: {mush_lost} units in {mush_passes} passes, one a "
        "pass and the rest the time drain.</p>",

        "<h3>Dying</h3>",
        f"<p>{link(LOSE_LIFE)}: with no lives left, {link(GAME_OVER)}; otherwise one fewer, and "
        f"the player's sprite becomes $67, sinking. {link(DYING)} lowers the figure a row on "
        f"three frames in four; at the bottom {link(DROP_GRAVESTONE)} leaves a gravestone ($8F) "
        "in the first free of four slots, and PLACE_PLAYER starts the next life in the same "
        f"room: the score flashes for 104 frames ({link(FLASH_SCORE)}), then "
        f"{link(MATERIALISING)} raises the figure a row every four frames. Followed with the "
        "life force set to 1 in room $00 (staged), the phases, in frames:</p>",
        table(["Phase", "Frames"], death_rows),
        f"<p>Lives went from {lives_before} to {lives_after}"
        + (f", and a gravestone record appeared at ${grave:04X}" if grave else "")
        + f". The spot where he died, at frames {', '.join(pick_frames)} after the fatal "
        "drain: sinking, the gravestone while the score flashes, rising, and in play:</p>",
        figure("quest_death.png", death_pic, "Sinking, the gravestone, rising.", scale=1),
        f"<p>While sinking or rising the player is not in play: nothing can touch him, and the "
        "small creatures in the room are destroyed for 155 points each (see <a "
        "href=\"Monsters.html\">the monsters</a>). START_GAME sets LIVES to 3, and a death at 0 "
        "is the end: four lives in all. Staged with LIVES 0 and the life force at 1, "
        f"{link(GAME_OVER)} blanked the play area and printed its summary, then waited in "
        f"{link(END_DELAY)} -- about ten seconds -- before the title:</p>",
        figure("quest_game_over.png", over_pic, "The game over screen.", scale=2),

        "<h3>Objects and the inventory</h3>",
        "<p>Eighteen collectables, $80-$8E, each a record with its room. Where the first game "
        "puts them (read from the running game once START_GAME has run), what they look like "
        "(drawn by the game) and what reads them:</p>",
        table(["", "Sprite", "Record", "Colour", "Room", "What it is for"], collect_rows),
        "<p>The eight at $EB18 have no reader but the humpback's search, which takes them "
        f"away for good ({link(SCAN_COLLECTABLES)}); {link(FIND_CARRIED)}'s callers ask only "
        "for the keys, the crucifix and the spanner.</p>",
        f"<p>The inventory is three slots of four bytes at CARRIED ($5E30), newest first. "
        f"{link(PICK_UP)}, when SYMBOL SHIFT is held and this press has not been used, the "
        f"player in play and within 12 pixels: {link(DROP_CARRIED)} puts the third slot's "
        f"object back at the player's feet, {link(SHIFT_CARRIED)} moves the other two along, "
        f"and {link(REMEMBER_CARRIED)} puts the new one in front and empties its record. "
        f"{link(PUT_DOWN)}, run every pass by the drop controller, does the same on a press "
        "with nothing underfoot, but with slot one left empty: so a press on nothing moves the "
        "queue along, and an object only falls out when pushed past the third slot. Pressed "
        "for real, in room $00, with each object put at the knight's feet first:</p>",
        table(["Step", "Slots after (newest first)", "Also"], queue_rows),
        figure("quest_queue.png", queue_pic, "The scroll's three slots after each step.",
               scale=1),

        "<h3>The A.C.G. key</h3>",
        f"<p>Three collectables, $8C, $8D and $8E. {link(PLACE_ACG_KEY)} hides them when a game "
        f"starts: (FRAMES + TICKS) AND 7 picks one of eight sets of three rooms in "
        f"{link(KEY_ROOM_SETS)}, written into the pieces' records in the template before it is "
        "copied. TICKS is 0 then and FRAMES the same value PLACE_KEYS uses, so the set's number "
        "is the green and red keys' index too: at most eight arrangements of those three "
        "together. The eight sets:</p>",
        table(["Set", "$8C", "$8D", "$8E"], set_rows),
        f"<p>The great door is one record of type $24, one half in room $00's east wall and "
        f"one in room $8E. {link(ACG_DOOR)} reads the sprite in each inventory slot in turn "
        "and wants $8C, $8D, $8E -- newest first, so $8E must be picked up first -- and then "
        "opens with a doorway of 24 by 32 (it is in a side wall); otherwise it shuts and is only "
        "drawn. Staged in the inventory, two passes each way:</p>",
        table(["Slots, newest first", "The door"], order_rows),
        f"<p>And played: the three pieces put at the knight's feet in room $00 one at a time, "
        f"$8E, then $8D, then $8C, and SYMBOL SHIFT pressed for each -- leaving "
        f"{', '.join(hexb(c) for c in in_hand)} in the slots -- then W held. He walked through "
        f"the door in {walk} frames into room ${arrived[0]:02X}, a passage; {link(MAIN_LOOP)} "
        f"ends every pass by comparing the player's room with $8E and jumping to "
        f"{link(SHOW_END_SCREEN)}. The same pieces picked up the other way round left "
        f"{', '.join(hexb(c) for c in wrong_hand)} in the slots, and the knight stopped at x "
        f"{hexb(wrong_stop[1])}, against the shut door. The end screen, as the game drew it:</p>",
        figure("quest_end.png", end_pic, "The end of the game.", scale=2),
        "<p>The first line ends in $D4, T with the end marker, where S ($D3) was meant (see "
        "<a href=\"reference/bugs.html\">the bugs</a>). Winning adds nothing to the score.</p>",

        "<h3>The clock, the score and the percentage</h3>",
        f"<p>{link(TICK_CLOCK)} counts hours, minutes and seconds from the start of the game, "
        "subtracting 50 from FRAMES each second -- so FRAMES stays under 50 in play -- and "
        "stops while the game is paused. The score, six BCD digits, has two sources only: "
        f"{link(KILL_MONSTER)} adds 155 for every small creature destroyed, and "
        f"{link(MOVE_FRANKENSTEIN)} 1000 for Frankenstein's monster killed with the spanner. "
        f"The win above -- the pieces having been put at the knight's feet -- ended at "
        f"{end_time} with a score of {end_score}. The end screens' "
        f"third figure is {link(COUNT_ROOMS_EXPLORED)}'s: two for every three rooms whose bit "
        "is set in ROOMS_SEEN, plus one, in BCD, shown with a percent sign. Run with that many "
        "bits set:</p>",
        table(["Rooms seen", "Figure"], pct_rows),
        f"<p>So any 147 rooms or more make 99, the most two BCD digits hold. The win above, "
        f"having seen rooms $00 and $8E, showed {end_seen:X}.</p>",

        evidence([
            "Run in the simulator, nothing staged: the life force's drain in room $00, the key "
            "and piece rooms of the first game, and the win's walk through the door.",
            "Staged, then run: eating, regrowth, the mushroom, the death and the game over "
            "(the life force and lives written), the objects put at the knight's feet for the "
            "inventory and the win (the presses of SYMBOL SHIFT were real), the door's order "
            "with the pieces written into the slots, the percentages.",
            "Read from the game's data: the drains' sizes, the eight key sets, the collectables' "
            "records.",
        ], [
            "The zero wrap is quoted from the notes' run, not repeated here.",
            "The uses of the eight objects at $EB18 rest on there being no other reader "
            "(searched in the code); what they meant to the designers is not known.",
        ]),
    ]
    return "\n".join(lines)


# --------------------------------------------------------------------------

PAGES = [
    ("Drawing", "How a room is drawn", "_drawing_page"),
    ("Movement", "How the player moves and collides", "_movement_page"),
    ("Monsters", "How the monsters live", "_monsters_page"),
    ("Doors", "Doors, keys and trapdoors", "_doors_page"),
    ("Quest", "Food, health and the A.C.G. key", "_quest_page"),
]


def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    """Draw the pictures into html_dir/images/howitworks and return the
    pages' HTML by ref section name."""
    snapshot = Path(snapshot)
    image_dir = Path(html_dir) / IMAGE_DIR
    image_dir.mkdir(parents=True, exist_ok=True)
    link = Links(snapshot.with_name("aticatac.skool"))
    log("Writing the how-it-works deep dives...")
    sections = {}
    for name, _title, function in PAGES:
        body = globals()[function](snapshot, image_dir, link, log)
        for line in body.splitlines():
            if line.startswith((";", "[")):
                raise ValueError(f"{name}: a line starts with {line[0]!r}: {line[:60]}")
        sections[name] = body
    if link.missing:
        log("  not entries (linked as plain addresses): "
            + ", ".join(f"${a:04X}" for a in sorted(link.missing)))
    return sections
