"""Ant Attack's "How it works" deep dives: drawing, movement, the ants, the
grenade, and the rescue.

build() returns each page's HTML, by ref section name, and draws the pictures
into the HTML directory. Nothing here is a transcription of the game: every
table is read from the game's memory as the page is built, and every scene and
worked example is the game's own code, run in SkoolKit's simulator on a game
in progress (build_antattack.playing_machine). Where a scene is staged -- the
player put beside an ant, a wall built on open ground -- the staging is only
the starting positions; what follows is the game's doing, and the page says
which is which.

The prose is written from reading the listing (scripts/antattack_annotations.ctl
and the code it describes) and checked against what the runs give; the pages
say which claims rest on which. Like the rest of the build, the pictures and
the pages are the game's content and are never committed.
"""
from __future__ import annotations

import functools
import html
import re
from pathlib import Path

import build_antattack as ba

IMAGE_DIR = "images/howitworks"
TSTATES_PER_FRAME_LIMIT = 20_000_000     # a bound on any one frame's run

# --------------------------------------------------------------------------
# Addresses run or read here. See their entries in the listing.
# --------------------------------------------------------------------------

PLAY_LOOP = 0x8014          # PLAY's CALL GAME_FRAME: the top of every frame
PLAY_COUNT = 0x801D         # PLAY, after the frame and its checks: FRAMES_LEFT
PLAY_RETURNS = 0x8033       # PLAY's RET to BASIC
GAME_FRAME = 0x8E80
DRAW_SPRITE = 0x80A0
READ_CONTROLS = 0x8060
COPY_TO_SCREEN = 0x8100
PLANE_TO_BUFFER = 0x8130
CLEAR_PLANES = 0x8160
MARK_PLANE = 0x8180
BUILD_PLANES = 0x81B0
DRAW_BLOCK = 0x8203
CLEAR_BUFFER_ROWS = 0x8300
RANDOM = 0x8360
READ_MAP_CELL = 0x8380
GATHER_VIEW = 0x83B0
MOVE_GRENADE = 0x83E0
READ_VIEW_KEYS = 0x8400
SCROLL_VIEW = 0x8460
DRAW_VIEW = 0x84A0
SHARE_CELL = 0x84D0
DRAW_SCENE = 0x8500
BLOCK_DRAWN = 0x852B
DRAW_HERE = 0x852F
NEXT_SPRITE = 0x8550
SELECT_BLOCK_DRAWER = 0x8570
SORT_SPRITES = 0x8580
SPRITE_DISTANCES = 0x85D0
PROJECT_SPRITES = 0x8600
GATHER_VIEWS = (0x8681, 0x86A1, 0x86C1, 0x86E1)
DRAW_BLOCK_TURNED = 0x8703
BLAST_ANT = 0x87A0
BLAST_FRAME = 0x82E0
SCANNER = 0x87D0
MOVE_OBJECT = 0x8800
LANDED = 0x8860
FALL = 0x8880
BITTEN = 0x88A0
STUNNED = 0x88B0
ON_TOP = 0x88C0
RISE = 0x88D0
STEP_UP = 0x88E0
STEP = 0x8900
TEST_MAP_BIT = 0x8920
TOGGLE_MAP_BIT = 0x8940
TEST_BELOW = 0x895D
CHOOSE_FRAME = 0x8980
MOVE_OR_RESPAWN = 0x89D0
MOVE_ANT = 0x8A00
ANT_TURN = 0x8A5D
DISTANCE = 0x8A80
DIRECTION_TO = 0x8A91
FOLLOW_PLAYER = 0x8AB6
FILL_PLAY_ATTRIBUTES = 0x8B00
PARALYSE_ANT = 0x8BD1
THROW_GRENADE = 0x8D00
GRENADE_BLAST = 0x8D9A
COUNT_DOWN_TIME = 0x8DD0
PLAY_SCRIPT = 0x8E02
RUN_SCRIPT = 0x8E0D
CHECK_RESCUED = 0x8EA0
CHECK_GAME_OVER = 0x8ED0
FINAL_SCRIPT = 0x8EF2
HANDLE_EVENTS = 0x8F00
MOVE_RESCUEE = 0x8F80
GRENADE_SOUNDS = 0x8FD0
MOVE_PLAYER = 0x82C0
MOVE_ANTS = 0x80D3
PLAY = 0x8000
SCRIPTS = 0x9000

RENDER_BUFFER = 0xA000
BUFFER_ROWS = 140
VIEW_CELLS = 0xB180
VIEW_ORIGIN = 0xB420
VIEW = 0xB422
RANDOM_BITS = 0xB428
GRENADE_EVENTS = 0xB42D
THROW_TIME = 0xB42E
AMMO = 0xB42F
PLAYER_ENERGY = 0xB431
RESCUEE_ENERGY = 0xB433
TIME_TICKS = 0xB435
TIME = 0xB436
FRAMES_LEFT = 0xB438
SPRITE_LIST = 0xB450
PLAYER = 0xB480
RESCUEE = 0xB490
GRENADE = 0xB4A0
ANTS = [0xB4B0 + 16 * i for i in range(5)]
PLANES = 0xB500
CITY_MAP = 0xC000

# The fields of an object record (see the annotations' header).
X, Y, HEIGHT, FIRST_FRAME, FACING, FALLING, STUN, FLAGS = range(8)
ANIM, BLAST, HOME_X, HOME_Y, HOME_HEIGHT, STATE, COUNT, EVENT = range(8, 16)
PARALYSED = 0xFF
EVENTS = {0: "", 1: "a step", 2: "a bad fall", 4: "bitten", 8: "blown up"}

# The offset READ_VIEW_KEYS takes from the player for each view: the origin
# is the player's x less the low byte and y less the high.
VIEW_OFFSETS = {0: 0x12FD, 1: 0xFDEE, 2: 0xEE03, 3: 0x0312}
VIEW_KEYS = {0: "SPACE", 1: "ENTER", 2: "P", 3: "0"}

INK = (0, 0, 0)
PAPER = (255, 255, 255)
NEW_INK = (205, 0, 0)       # pixels a stage has just changed


# --------------------------------------------------------------------------
# A game in the simulator.
# --------------------------------------------------------------------------

@functools.lru_cache(maxsize=None)
def _start_state(snapshot: str) -> tuple:
    """Memory and registers of a game a few frames in, stopped at PLAY_LOOP.

    playing_machine plays from the title screen through the choice of boy and
    the story card, and leaves the boy walking in at the city gate; from there
    the simulation runs on, no keys held, to the top of the next frame.
    """
    from skoolkit.simutils import PC, T

    sim = ba.playing_machine(Path(snapshot))
    sim.tracer.keys = set()
    sim.trace(sim.registers[PC], PLAY_LOOP, 0, sim.registers[T] + TSTATES_PER_FRAME_LIMIT,
              False, None, None, None, None, None)
    if sim.registers[PC] != PLAY_LOOP:
        raise RuntimeError(f"the game did not reach ${PLAY_LOOP:04X}")
    return tuple(sim.memory), tuple(sim.registers[:28])


class Game:
    """A game in progress in SkoolKit's simulator.

    Each Game is a machine of its own, made from a saved state, so a scene can
    be staged, run and thrown away without spoiling the next one. Between
    calls it is stopped at PLAY_LOOP, the top of a frame, unless a method says
    otherwise.
    """

    def __init__(self, memory, registers):
        from skoolkit import CSimulator
        from skoolkit.simulator import Simulator
        from skoolkit.simutils import IFF, IM, T

        # The interrupt mode is the game's own (2, set at load, so that an
        # error in BASIC restarts it through INTERRUPT); the registers list
        # carries it when it comes from a running simulator.
        state = {"iff": registers[IFF] if len(registers) > IM else 0,
                 "im": registers[IM] if len(registers) > IM else 2, "tstates": registers[T]}
        self.sim = (CSimulator or Simulator)(list(memory), state=state)
        for index, value in enumerate(registers[:T + 1]):
            self.sim.registers[index] = value
        self.tracer = ba._key_tracer_class()(self.sim)
        self.sim.set_tracer(self.tracer)
        self.ended = False

    @classmethod
    def start(cls, snapshot: Path) -> "Game":
        memory, registers = _start_state(str(snapshot))
        return cls(memory, registers)

    def copy(self) -> "Game":
        return Game(self.sim.memory, list(self.sim.registers[:28]))

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

    def until(self, stop: int, keys=None, limit: int = TSTATES_PER_FRAME_LIMIT) -> None:
        """Run on (at least one instruction) until PC is `stop`, with `keys`
        held (or the keys already held, if None)."""
        from skoolkit.simutils import PC, T

        if keys is not None:
            self.tracer.keys = set(keys)
        self.sim.trace(self.sim.registers[PC], stop, 0, self.sim.registers[T] + limit,
                       False, None, None, None, None, None)
        if self.sim.registers[PC] != stop:
            raise RuntimeError(f"stopped at ${self.sim.registers[PC]:04X} waiting for ${stop:04X}")

    def frame(self, keys=()) -> bool:
        """One turn of PLAY's loop: a game frame and the checks after it.

        False, and the game stopped at PLAY's RET, if that was the last frame
        before PLAY goes back to BASIC (FRAMES_LEFT counted out)."""
        self.until(PLAY_COUNT, keys)
        left = self.memory[FRAMES_LEFT]
        if left == 1:
            self.until(PLAY_RETURNS)
            self.ended = True
            return False
        self.until(PLAY_LOOP)
        return True

    def step(self) -> None:
        """One instruction."""
        self.sim.run()

    def call(self, address: int, registers: dict | None = None,
             limit: int = TSTATES_PER_FRAME_LIMIT) -> int:
        """Run a routine to its return, on this machine; the T-states it took.

        The return address is one PLAY_LOOP's frames never execute: $5B00, in
        the printer buffer, as build_antattack.call_routine uses.
        """
        from skoolkit.simutils import PC, SP, T

        saved_pc, saved_sp = self.sim.registers[PC], self.sim.registers[SP]
        sp = 0x5B80
        self.memory[sp:sp + 2] = bytes([0x00, 0x5B])
        self.sim.registers[SP] = sp
        for name, value in (registers or {}).items():
            self.set_reg(name, value)
        start = self.sim.registers[T]
        self.sim.registers[PC] = address
        self.until(0x5B00, limit=limit)
        taken = self.sim.registers[T] - start
        self.sim.registers[PC], self.sim.registers[SP] = saved_pc, saved_sp
        return taken

    # The records.

    def record(self, address: int) -> list[int]:
        return list(self.memory[address:address + 16])

    def place(self, address: int, x: int, y: int, height: int) -> None:
        """Move a person or the grenade: nothing of theirs is in the map."""
        self.memory[address:address + 3] = bytes([x & 0xFF, y & 0xFF, height])

    def move_ant(self, ant: int, x: int, y: int, height: int) -> None:
        """Move an ant and its bit in the map with it (see TOGGLE_MAP_BIT)."""
        old_x, old_y, old_height = self.memory[ant:ant + 3]
        if old_x >= 0x80 and old_y >= 0x80 and old_height < 6:
            self.memory[cell_address(old_x, old_y)] ^= 1 << old_height
        self.memory[ant:ant + 3] = bytes([x, y, height])
        if x >= 0x80 and y >= 0x80:
            self.memory[cell_address(x, y)] ^= 1 << height

    def park_ants(self, keep=()) -> None:
        """Put every ant not in `keep` out of the way: outside the walls, far
        off, where nothing is solid and they are out of every view used here,
        paralysed so that they stay there."""
        for index, ant in enumerate(ANTS):
            if index in keep:
                continue
            self.move_ant(ant, 0x10 + 4 * index, 0x10, 0)
            self.memory[ant + STUN] = PARALYSED
            self.memory[ant + BLAST] = 0

    def look_at(self, view: int, x: int | None = None, y: int | None = None) -> None:
        """Set the view as READ_VIEW_KEYS does: the view number, and an origin
        the view's offset from (x, y), the player's cell unless given."""
        if x is None:
            x, y = self.memory[PLAYER], self.memory[PLAYER + 1]
        offset = VIEW_OFFSETS[view]
        self.memory[VIEW] = view
        self.memory[VIEW_ORIGIN] = (x - (offset & 0xFF)) & 0xFF
        self.memory[VIEW_ORIGIN + 1] = (y - (offset >> 8)) & 0xFF

    def cell(self, x: int, y: int) -> int:
        if x < 0x80 or y < 0x80:
            return 0
        return self.memory[cell_address(x, y)]

    def set_cell(self, x: int, y: int, value: int) -> None:
        self.memory[cell_address(x, y)] = value


def cell_address(x: int, y: int) -> int:
    return CITY_MAP + 128 * (y - 0x80) + (x - 0x80)


def open_ground(memory, size: int, start=(0x84, 0x84), avoid=()) -> tuple[int, int]:
    """The first square of empty cells, size across, inside the walls, from
    `start` on, not overlapping the squares in `avoid` ((x, y, size) each)."""
    for y in range(start[1], 0x100 - size):
        for x in range(start[0], 0x100 - size):
            if any(ax - size < x < ax + asize and ay - size < y < ay + asize
                   for ax, ay, asize in avoid):
                continue
            if all(memory[cell_address(xx, yy)] == 0
                   for yy in range(y, y + size) for xx in range(x, x + size)):
                return x, y
    raise RuntimeError("no open ground")


# --------------------------------------------------------------------------
# Pictures.
# --------------------------------------------------------------------------

def buffer_image(memory, before=None, top: int = 0, rows: int = BUFFER_ROWS):
    """The render buffer as a picture, black on white; with `before`, the
    pixels that have changed since then and are now set in red."""
    from PIL import Image

    image = Image.new("RGB", (256, rows), PAPER)
    pixels = image.load()
    for y in range(rows):
        base = RENDER_BUFFER + 32 * (top + y)
        for column in range(32):
            byte = memory[base + column]
            changed = byte ^ before[base + column] if before is not None else 0
            if not byte:
                continue
            for bit in range(8):
                mask = 0x80 >> bit
                if byte & mask:
                    pixels[column * 8 + bit, y] = NEW_INK if changed & mask else INK
    return image


def screen_image(memory):
    return ba.screen_image(memory)


def play_area(memory):
    """The part of the screen the view is copied to: lines 12-127, columns
    1-30 (see COPY_TO_SCREEN)."""
    return screen_image(memory).crop((8, 12, 248, 128))


def save(image, image_dir: Path, name: str):
    image.save(image_dir / name)
    return image


def img(name: str, image, alt: str = "", scale: int = 2, title: str = "",
        shrink: bool = True) -> str:
    """An <img> of a picture saved at its own size, shown `scale` times larger
    with its pixels kept square; `shrink` lets it narrow to fit a small
    screen, which a picture in a table cell should not."""
    extra = f' title="{html.escape(title)}"' if title else ""
    fit = " max-width: 100%; height: auto;" if shrink else ""
    return (f'<img src="{IMAGE_DIR}/{name}" alt="{html.escape(alt)}"{extra} '
            f'width="{image.width * scale}" height="{image.height * scale}" '
            f'style="image-rendering: pixelated; image-rendering: crisp-edges;{fit}">')


def plain(text: str) -> str:
    """Text for an attribute: no tags, and no skool macros, which skool2html
    would expand into links inside the attribute."""
    text = re.sub(r"<[^>]+>", "", text)
    text = re.sub(r"#R\$([0-9A-F]{4})", lambda match: "$" + match.group(1), text)
    return text.replace("&ndash;", "-")


def figure(name: str, image, caption: str, scale: int = 2) -> str:
    return (f'<div style="display: inline-block; vertical-align: top; margin: 0 12px 12px 0; '
            f'max-width: {max(image.width * scale + 4, 200)}px">'
            f'{img(name, image, plain(caption), scale)}'
            f'<p style="margin: 4px 0 0 0; font-size: 0.9em">{caption}</p></div>')


def strip(images, gap: int = 4, background=(255, 255, 255)):
    from PIL import Image

    width = sum(i.width for i in images) + gap * (len(images) - 1)
    height = max(i.height for i in images)
    out = Image.new("RGB", (width, height), background)
    x = 0
    for image in images:
        out.paste(image, (x, 0))
        x += image.width + gap
    return out


def table(headers, rows) -> str:
    head = "".join(f"<th>{h}</th>" for h in headers)
    body = "".join("<tr>" + "".join(f"<td>{c}</td>" for c in row) + "</tr>" for row in rows)
    return f'<table class="default"><tr>{head}</tr>{body}</table>'


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
    $ADDR otherwise -- the lead is splitting the data into more entries while
    this is written, so the set is read at build time."""

    def __init__(self, skool: Path):
        self.entries = _entries(str(skool))
        self.missing: set[int] = set()

    def __call__(self, address: int) -> str:
        if address in self.entries:
            return f"#R${address:04X}"
        self.missing.add(address)
        return f"${address:04X}"


NUMBER_WORDS = ["no", "one", "two", "three", "four", "five", "six", "seven", "eight",
                "nine", "ten"]


def words(number: int) -> str:
    return NUMBER_WORDS[number] if 0 <= number < len(NUMBER_WORDS) else str(number)


# The game's own words, read from the game when the pages are built, so that
# none of its text is in this file: the scripts by number, and a few of
# BASIC's messages by (line, which quoted string on it).
_TEXTS: dict = {}
BASIC_TEXTS = {"another go": (400, 0), "out of time": (3210, 0)}


def load_texts(snapshot: Path) -> None:
    memory = ba.game_memory(snapshot)
    for number, address in enumerate(ba.script_addresses(memory), 1):
        _TEXTS[number] = ba.script_text(memory, address)
    for key, (line, index) in BASIC_TEXTS.items():
        strings = re.findall(r'"([^"]*)"', basic_line(snapshot, line))
        _TEXTS[key] = " ".join(strings[index].split())


def say(key, first_line: bool = False) -> str:
    """A message of the game's, in quotation marks, for a page."""
    text = _TEXTS[key]
    if first_line:
        text = text.split(" / ")[0]
    text = " ".join(text.replace(" / ", " ").replace('"', " ").split())
    return "&ldquo;" + html.escape(text) + "&rdquo;"


def _fmt_cell(x: int, y: int, height: int | None = None) -> str:
    text = f"${x:02X}, ${y:02X}"
    return text + (f", {height}" if height is not None else "")


# --------------------------------------------------------------------------
# Drawing: one frame, stage by stage.
# --------------------------------------------------------------------------

# The frame followed: a real game, not staged. The boy walks in at the gate
# (V held for WALK_IN frames from the first frame playing_machine reaches)
# and then stands in the gateway while the ants come out of their nest to
# him; FRAME_AFTER frames later all five are in view, with the girl waiting
# to be rescued on the wall beside the gate (level 1's place).
WALK_IN = 12
FRAME_AFTER = 390

# DRAW_VIEW's calls, by the address each returns to: (stage, routine).
DRAW_STAGES = [
    (0x84A3, "gather", GATHER_VIEW),
    (0x84A6, "planes", BUILD_PLANES),
    (0x84B2, "clear", CLEAR_BUFFER_ROWS),
    (0x84B5, "project", PROJECT_SPRITES),
    (0x84B8, "scroll", SCROLL_VIEW),
    (0x84BB, "sort", SORT_SPRITES),
    (0x84BE, "distances", SPRITE_DISTANCES),
    (0x84C1, "select", SELECT_BLOCK_DRAWER),
    (0x84C4, "paint", DRAW_SCENE),
    (0x84C7, "copy", COPY_TO_SCREEN),
]
# GAME_FRAME's calls, by the address each returns to.
FRAME_STAGES = [
    (0x8E83, "the player", MOVE_PLAYER),
    (0x8E86, "the rescued person", MOVE_RESCUEE),
    (0x8E89, "the grenade", MOVE_GRENADE),
    (0x8E8C, "the ants", MOVE_ANTS),
    (0x8E8F, "the view keys", READ_VIEW_KEYS),
    (0x8E92, "drawing", DRAW_VIEW),
    (0x8E95, "events", HANDLE_EVENTS),
    (0x8E98, "grenade messages", GRENADE_SOUNDS),
    (0x8E9B, "the clock", COUNT_DOWN_TIME),
]
NEXT_HEIGHT = 0x8511        # DRAW_SCENE's pass loop: a height's pass is done
BLOCK_ENTRIES = (DRAW_BLOCK, DRAW_BLOCK_TURNED)
SPRITE_DRAWN = 0x8535       # DRAW_HERE, back from DRAW_SPRITE


def the_real_frame(snapshot: Path) -> Game:
    """The game at the top of the frame the drawing page follows."""
    game = Game.start(snapshot)
    for _ in range(WALK_IN):
        game.frame(["v"])
    for _ in range(FRAME_AFTER):
        game.frame()
    return game


def trace_draw(game: Game) -> dict:
    """Follow one frame through DRAW_VIEW: memory after every stage, the
    T-states each took, and every block and sprite DRAW_SCENE paints, pass by
    pass. The game is left at the top of the next frame."""
    game.until(DRAW_VIEW)
    result = {"before": bytes(game.memory), "stages": [], "cells": [], "draws": [],
              "passes": [], "paint_split": {"blocks": 0, "sprites": 0, "scan": 0}}
    # GATHER_VIEW, one instruction at a time, to log every cell it reads.
    start = game.tstates
    while game.pc != DRAW_STAGES[0][0]:
        if game.pc == READ_MAP_CELL:
            result["cells"].append((game.reg("E"), game.reg("D")))
        game.step()
    result["stages"].append(("gather", GATHER_VIEW, game.tstates - start, bytes(game.memory)))
    for stop, name, routine in DRAW_STAGES[1:]:
        start = game.tstates
        if name != "paint":
            game.until(stop)
            result["stages"].append((name, routine, game.tstates - start, bytes(game.memory)))
            continue
        # DRAW_SCENE, one instruction at a time.
        mode, height = "scan", 0
        while game.pc != stop:
            pc = game.pc
            if pc in BLOCK_ENTRIES:
                mode = "blocks"
                result["draws"].append(("block", height, game.reg("HL") - PLANES, None))
            elif pc == DRAW_SPRITE:
                mode = "sprites"
                frame = game.memory[game.reg("IX")]
                result["draws"].append(("sprite", height, game.reg("HL") - PLANES, frame))
            elif pc == BLOCK_DRAWN or pc == SPRITE_DRAWN:
                mode = "scan"
            elif pc == NEXT_HEIGHT:
                result["passes"].append((height, bytes(game.memory)))
                height += 1
            before = game.tstates
            game.step()
            result["paint_split"][mode] += game.tstates - before
        result["stages"].append((name, routine, game.tstates - start, bytes(game.memory)))
    game.frame()
    return result


def profile_frames(game: Game, frames: int, keys=(), counts=None) -> dict:
    """T-states in each part of GAME_FRAME and of DRAW_VIEW, over `frames`
    frames of the game as it stands, keys held: name -> list of counts."""
    counts = {} if counts is None else counts
    game.tracer.keys = set(keys)
    for _ in range(frames):
        game.until(GAME_FRAME)
        frame_start = game.tstates
        for stop, name, _ in FRAME_STAGES:
            start = game.tstates
            if name == "drawing":
                for draw_stop, draw_name, _ in DRAW_STAGES:
                    draw_start = game.tstates
                    game.until(draw_stop)
                    counts.setdefault("draw:" + draw_name, []).append(game.tstates - draw_start)
                game.until(stop)
            else:
                game.until(stop)
            counts.setdefault(name, []).append(game.tstates - start)
        counts.setdefault("frame", []).append(game.tstates - frame_start)
        game.frame(keys)
    return counts


# Colours for heights 0-5 (and the empty sky pass, 6), light to dark: a
# block's own ink and paper pixels become the darker and lighter of a pair.
HEIGHT_COLOURS = [(198, 219, 239), (158, 202, 225), (107, 174, 214), (66, 146, 198),
                  (33, 113, 181), (8, 81, 156), (8, 48, 107)]
SAND = (238, 226, 190)
WINDOW_COLOUR = (0, 150, 220)


def _shade(colour, factor: float):
    return tuple(int(c * factor) for c in colour)


def block_shape(snapshot: Path, drawer: int = DRAW_BLOCK) -> list[list]:
    """The block DRAW_BLOCK (or DRAW_BLOCK_TURNED) paints, 16 x 16: 1 ink, 0
    paper, None where what is behind shows through (build_antattack's
    block_picture, which paints it twice over different backgrounds)."""
    return ba.block_picture(snapshot, drawer)


def block_image(shape):
    """A block as a picture, the see-through pixels chequered pink."""
    from PIL import Image

    image = Image.new("RGB", (16, 16))
    pixels = image.load()
    for y in range(16):
        for x in range(16):
            pixel = shape[y][x]
            if pixel is None:
                pixels[x, y] = (255, 196, 196) if (x + y) & 1 else (255, 228, 228)
            else:
                pixels[x, y] = INK if pixel else PAPER
    return image


def planes_image(planes: bytes, shape):
    """PLANES painted the way DRAW_SCENE paints it -- every place holding
    $01 from the back, then every $02, and so on -- but with a flat colour
    per height in place of the shaded block, cut to the window the screen
    copy shows."""
    from PIL import Image

    image = Image.new("RGB", (256 + 16, BUFFER_ROWS), PAPER)
    pixels = image.load()
    for height in range(6):
        colour = HEIGHT_COLOURS[height]
        for place in range(511):
            if planes[place] != 1 << height:
                continue
            half_row, column = place >> 4, place & 15
            left, top = 16 * column + 8 * (half_row & 1), 4 * half_row
            for y in range(16):
                for x in range(16):
                    pixel = shape[y][x]
                    if pixel is not None and top + y < BUFFER_ROWS:
                        pixels[left + x, top + y] = _shade(colour, 0.8) if pixel else colour
    return image.crop((8, 12, 248, 128))


def gather_image(memory, cells, marks, scale: int = 5):
    """The city from above around the cells GATHER_VIEW read, x across and y
    down: blocks grey by their top height, the ground sand, outside the walls
    white; the cells read for the 512 places tinted blue, and the rows read
    only for the heights above them orange. `marks` are (x, y,
    colour) dots."""
    from PIL import Image, ImageDraw

    # Unwrapped coordinates, so a view across the edge of the map stays in
    # one piece: everything relative to the first cell read.
    ox, oy = cells[0]

    def unwrap(x, y):
        return ox + ((x - ox + 128) & 0xFF) - 128, oy + ((y - oy + 128) & 0xFF) - 128

    flat = [unwrap(x, y) for x, y in cells]
    left = min(x for x, _ in flat) - 3
    right = max(x for x, _ in flat) + 3
    top = min(y for _, y in flat) - 3
    bottom = max(y for _, y in flat) + 3
    image = Image.new("RGB", ((right - left + 1) * scale, (bottom - top + 1) * scale),
                      (250, 250, 250))
    draw = ImageDraw.Draw(image)

    def box(x, y):
        return [(x - left) * scale, (y - top) * scale,
                (x - left) * scale + scale - 1, (y - top) * scale + scale - 1]

    for y in range(top, bottom + 1):
        for x in range(left, right + 1):
            xx, yy = x & 0xFF, y & 0xFF
            if xx < 0x80 or yy < 0x80:
                continue
            value = memory[cell_address(xx, yy)]
            colour = SAND if not value else tuple(210 - 28 * value.bit_length() for _ in range(3))
            draw.rectangle(box(x, y), fill=colour)
    pixels = image.load()
    for index, (x, y) in enumerate(flat):
        tint = (40, 110, 230) if index < 512 else (240, 140, 20)
        x0, y0, x1, y1 = box(x, y)
        for py in range(y0, y1 + 1):
            for px in range(x0, x1 + 1):
                old = pixels[px, py]
                pixels[px, py] = tuple((2 * o + 3 * c) // 5 for o, c in zip(old, tint))
    for x, y, colour in marks:
        x0, y0, x1, y1 = box(*unwrap(x, y))
        draw.ellipse([x0 + 1, y0 + 1, x1 - 1, y1 - 1], fill=colour)
    return image


def with_window(image):
    """A whole render buffer picture with the rows and columns COPY_TO_SCREEN
    takes outlined."""
    from PIL import ImageDraw

    image = image.copy()
    ImageDraw.Draw(image).rectangle([8 - 1, 12 - 1, 248, 128], outline=WINDOW_COLOUR)
    return image


def sprite_frame_images(memory, frame: int):
    """A frame's mask and graphic, 16 x 16 (see DRAW_SPRITE): the mask black
    where it cuts the background away, the graphic black where it sets a
    pixel."""
    from PIL import Image

    base = 0x8000 + 64 * frame
    mask = Image.new("RGB", (16, 16), PAPER)
    graphic = Image.new("RGB", (16, 16), PAPER)
    for row in range(16):
        for half in range(2):
            m = memory[base + 4 * row + 2 * half]
            g = memory[base + 4 * row + 2 * half + 1]
            for bit in range(8):
                x = 8 * half + bit
                if not m & (0x80 >> bit):
                    mask.putpixel((x, row), INK)
                if g & (0x80 >> bit):
                    graphic.putpixel((x, row), INK)
    return mask, graphic


def paint_block(game: Game, place: int, drawer: int = DRAW_BLOCK) -> None:
    """Run a block drawer on its own: it jumps back into DRAW_SCENE when it
    is done, at BLOCK_DRAWN, so stop there."""
    game.set_reg("HL", PLANES + place)
    game.set_reg("DE", 0x1F)
    game.set_reg("PC", drawer)
    game.until(BLOCK_DRAWN)


def paint_sprite(game: Game, place: int, frame: int) -> None:
    """Run DRAW_SPRITE on its own, IX on a frame byte in the printer buffer."""
    game.memory[0x5B90] = frame
    game.call(DRAW_SPRITE, {"HL": PLANES + place, "DE": 0x1F, "IX": 0x5B90})


def gather_steps(game: Game) -> dict[int, list]:
    """For each view, the first 33 cells GATHER_VIEW reads, relative to the
    view origin: both half-rows of the first row and the start of the next."""
    steps = {}
    for view in range(4):
        trial = game.copy()
        trial.memory[VIEW] = view
        origin = trial.memory[VIEW_ORIGIN], trial.memory[VIEW_ORIGIN + 1]
        trial.set_reg("PC", GATHER_VIEW)
        cells = []
        while len(cells) < 33:
            if trial.pc == READ_MAP_CELL:
                x, y = trial.reg("E"), trial.reg("D")
                cells.append((((x - origin[0] + 128) & 0xFF) - 128,
                              ((y - origin[1] + 128) & 0xFF) - 128))
            trial.step()
        steps[view] = cells
    return steps


def _object_name(address: int) -> str:
    if address == PLAYER:
        return "the player"
    if address == RESCUEE:
        return "the rescued person"
    if address == GRENADE:
        return "the grenade"
    return f"ant {ANTS.index(address) + 1}"


# The records in the order PROJECT_SPRITES fills SPRITE_LIST: last first.
LIST_ORDER = list(reversed([PLAYER, RESCUEE, GRENADE] + ANTS))


def _place_text(place: int) -> str:
    """A SPRITE_LIST place (one more than the place proper) as its parts."""
    if place >> 8 == 0xFF:
        return "out of view"
    proper = place - 1
    return (f"{place} = 512 &times; {proper >> 9} + 16 &times; {(proper >> 4) & 31} "
            f"+ {proper & 15} + 1")


def _sprite_list(memory) -> list[tuple[int, int]]:
    return [(memory[SPRITE_LIST + 3 * i] | memory[SPRITE_LIST + 3 * i + 1] << 8,
             memory[SPRITE_LIST + 3 * i + 2]) for i in range(8)]


def _drawing_views(game: Game, image_dir: Path) -> list:
    """The frame's scene in each of the four views, drawn by DRAW_VIEW."""
    out = []
    for view in range(4):
        trial = game.copy()
        trial.look_at(view)
        trial.call(DRAW_VIEW)
        name = f"draw_view{view}.png"
        out.append((view, name, save(play_area(trial.memory), image_dir, name)))
    return out


# Places the drawing cost was measured at, besides the frame followed: the
# view centred on where the person waits on levels 1 to 5 (the first of each
# level's four places), in all four views.
MEASURED_LEVELS = 5


def _measure_views(game: Game, snapshot: Path) -> dict[str, list[int]]:
    """DRAW_VIEW's stages, and DRAW_SCENE's split, over many views."""
    counts: dict[str, list[int]] = {}
    spots = [(game.memory[PLAYER], game.memory[PLAYER + 1])]
    for level in ba.read_levels(snapshot)[:MEASURED_LEVELS]:
        x, y, _ = level["spots"][0]
        spots.append((x, y))
    for x, y in spots:
        for view in range(4):
            trial = game.copy()
            trial.look_at(view, x, y)
            traced = trace_draw(trial)
            for name, _, taken, _ in traced["stages"]:
                counts.setdefault(name, []).append(taken)
            for name, taken in traced["paint_split"].items():
                counts.setdefault("paint:" + name, []).append(taken)
            counts.setdefault("blocks drawn", []).append(
                sum(1 for d in traced["draws"] if d[0] == "block"))
            counts.setdefault("view", []).append(sum(t for _, _, t, _ in traced["stages"]))
    return counts


def _drawing_page(snapshot: Path, image_dir: Path, link, log) -> str:
    from PIL import Image

    log("  following a frame through the drawing...")
    game = the_real_frame(snapshot)
    at_frame = game.copy()
    views = _drawing_views(at_frame, image_dir)
    steps = gather_steps(at_frame)
    traced = trace_draw(game)
    stages = {name: (routine, taken, memory) for name, routine, taken, memory in traced["stages"]}
    memory_before = traced["before"]
    shape = block_shape(snapshot)
    turned = block_shape(snapshot, DRAW_BLOCK_TURNED)

    player = [memory_before[PLAYER + k] for k in range(16)]
    rescuee = [memory_before[RESCUEE + k] for k in range(16)]

    # The pictures, stage by stage.
    save(with_window(buffer_image(memory_before)), image_dir, "draw_before.png")
    marks = [(memory_before[a], memory_before[a + 1], (0, 0, 0)) for a in ANTS]
    marks += [(player[X], player[Y], (220, 0, 0)), (rescuee[X], rescuee[Y], (190, 0, 190))]
    gathered = save(gather_image(stages["gather"][2], traced["cells"], marks), image_dir,
                    "draw_gather.png")
    planes = stages["planes"][2][PLANES:PLANES + 512]
    planes_pic = save(planes_image(planes, shape), image_dir, "draw_planes.png")
    cleared = save(with_window(buffer_image(stages["clear"][2])), image_dir, "draw_cleared.png")
    passes = []
    previous = stages["clear"][2]
    drawn_by_pass = {}
    for kind, height, place, frame in traced["draws"]:
        drawn_by_pass.setdefault(height, []).append((kind, place, frame))
    for height, memory in traced["passes"]:
        changed = memory[RENDER_BUFFER:RENDER_BUFFER + 32 * BUFFER_ROWS] != \
            previous[RENDER_BUFFER:RENDER_BUFFER + 32 * BUFFER_ROWS]
        if changed:
            name = f"draw_pass{height}.png"
            passes.append((height, name, save(with_window(buffer_image(memory, previous)),
                                              image_dir, name)))
        previous = memory
    screen = save(play_area(stages["copy"][2]), image_dir, "draw_screen.png")
    blocks = [save(block_image(s).resize((64, 64), Image.NEAREST), image_dir, n)
              for s, n in ((shape, "draw_block.png"), (turned, "draw_block_turned.png"))]

    # A sprite with its mask, and drawn by DRAW_SPRITE over a block.
    boy_frame = next(frame for kind, _, _, frame in traced["draws"]
                     if kind == "sprite" and 0xDC <= frame < 0xF0)
    mask, graphic = sprite_frame_images(memory_before, boy_frame)
    demo = at_frame.copy()
    demo.memory[RENDER_BUFFER:RENDER_BUFFER + 32 * BUFFER_ROWS] = bytes(32 * BUFFER_ROWS)
    demo_place = 16 * 10 + 4
    paint_block(demo, demo_place)
    paint_block(demo, demo_place + 1)
    under = bytes(demo.memory)
    paint_sprite(demo, demo_place + 16, boy_frame)
    top, left = 4 * (demo_place >> 4), 16 * (demo_place & 15)
    over = buffer_image(demo.memory, under).crop((left - 4, top - 4, left + 36, top + 24))
    sprite_pics = [save(i.resize((64, 64), Image.NEAREST), image_dir, n)
                   for i, n in ((mask, "draw_mask.png"), (graphic, "draw_graphic.png"))]
    over_pic = save(over.resize((over.width * 3, over.height * 3), Image.NEAREST), image_dir,
                    "draw_sprite_over.png")

    # The sprite list, as each stage left it.
    projected = _sprite_list(stages["project"][2])
    sorted_list = _sprite_list(stages["sort"][2])
    spaced = _sprite_list(stages["distances"][2])
    by_frame = {}
    for address, (place, frame) in zip(LIST_ORDER, projected):
        by_frame.setdefault((place, frame), address)
    list_rows = []
    for address, (place, frame) in zip(LIST_ORDER, projected):
        record = [memory_before[address + k] for k in range(16)]
        list_rows.append([_object_name(address), _fmt_cell(record[X], record[Y], record[HEIGHT]),
                          _place_text(place), f"${frame:02X}"])
    sorted_rows = []
    for index, ((place, frame), (distance, _)) in enumerate(zip(sorted_list, spaced)):
        address = by_frame.get((place, frame))
        name = _object_name(address) if address else "?"
        sorted_rows.append([str(index + 1), name, str(place) if place >> 8 != 0xFF else "out of view",
                            str(distance) if index else f"{distance} (the place itself)"])

    # What DRAW_SCENE did, pass by pass.
    ants_in_map = []
    for kind, height, place, frame in traced["draws"]:
        if kind == "sprite" and frame >= 0xF8:
            ants_in_map.append((place, planes[place]))
    swallowed = sum(1 for place, value in ants_in_map if value == 1)
    hidden = [place for place, value in ants_in_map if value not in (1, 0xFF)]
    pass_rows = []
    for height in range(7):
        drawn = drawn_by_pass.get(height, [])
        block_count = sum(1 for kind, _, _ in drawn if kind == "block")
        sprites = ", ".join(f"${frame:02X} at {place}" for kind, place, frame in drawn
                            if kind == "sprite")
        pass_rows.append([f"${1 << height:02X}", str(height), str(block_count), sprites or "none"])

    # The time.
    log("  measuring the drawing on twenty-four views...")
    measured = _measure_views(at_frame, snapshot)
    real = profile_frames(Game.start(snapshot), WALK_IN, ["v"])
    real = profile_frames(the_real_frame(snapshot).copy(), 20, (), real)

    def span(values):
        low, high = min(values), max(values)
        return f"{low:,}" if low == high else f"{low:,} &ndash; {high:,}"

    stage_text = {
        "gather": f"Gather the cells ({link(GATHER_VIEW)}, {link(READ_MAP_CELL)} 672 times)",
        "planes": f"Build the planes ({link(BUILD_PLANES)}: {link(CLEAR_PLANES)}, then "
                  f"{link(MARK_PLANE)} six times)",
        "clear": f"Clear the buffer ({link(CLEAR_BUFFER_ROWS)} four times)",
        "project": f"Place the objects ({link(PROJECT_SPRITES)})",
        "scroll": f"Scroll? ({link(SCROLL_VIEW)})",
        "sort": f"Sort them ({link(SORT_SPRITES)})",
        "distances": f"Distances ({link(SPRITE_DISTANCES)})",
        "select": f"Pick the block ({link(SELECT_BLOCK_DRAWER)})",
        "paint": f"Paint ({link(DRAW_SCENE)})",
        "copy": f"Copy to the screen ({link(COPY_TO_SCREEN)})",
    }
    this_frame = {name: taken for name, _, taken, _ in traced["stages"]}
    total_view = sum(this_frame.values())
    time_rows = []
    for _, name, _ in DRAW_STAGES:
        time_rows.append([stage_text[name], f"{this_frame[name]:,}",
                          f"{100 * this_frame[name] / total_view:.0f}%", span(measured[name])])
        if name == "paint":
            for part, what in (("blocks", "&nbsp;&nbsp;of which drawing blocks"),
                               ("sprites", "&nbsp;&nbsp;of which drawing sprites"),
                               ("scan", "&nbsp;&nbsp;of which the CPIR scan and the "
                                        "passes")):
                taken = traced["paint_split"][part]
                time_rows.append([what, f"{taken:,}", f"{100 * taken / total_view:.0f}%",
                                  span(measured["paint:" + part])])
    time_rows.append(["<b>All of DRAW_VIEW</b>", f"<b>{total_view:,}</b>", "100%",
                      span(measured["view"])])
    frame_rows = [[f"{what} ({link(routine)})", span(real[name])]
                  for _, name, routine in FRAME_STAGES
                  for what in [name[0].upper() + name[1:]]]
    frame_rows.append(["<b>The whole frame</b>", f"<b>{span(real['frame'])}</b>"])
    per_frame = sum(real["frame"]) / len(real["frame"])
    fps = ba.TSTATES_PER_SECOND / per_frame
    block_counts = measured["blocks drawn"]
    one_block = (sum(measured["paint:blocks"]) / sum(block_counts)) if sum(block_counts) else 0

    offsets_rows = []
    for view in range(4):
        offset = VIEW_OFFSETS[view]
        dx, dy = -((offset & 0xFF) - 256 if offset & 0x80 else offset & 0xFF), \
            -((offset >> 8) - 256 if offset & 0x8000 else offset >> 8)
        cells = steps[view]
        along = (cells[1][0] - cells[0][0], cells[1][1] - cells[0][1])
        second = cells[16]
        next_row = cells[32]
        offsets_rows.append([str(view), VIEW_KEYS[view], f"{dx:+d}, {dy:+d}",
                             f"{along[0]:+d}, {along[1]:+d}", f"{second[0]:+d}, {second[1]:+d}",
                             f"{next_row[0]:+d}, {next_row[1]:+d}"])

    view_figures = "".join(
        figure(name, image, f"View {view} ({VIEW_KEYS[view]})") for view, name, image in views)
    pass_figures = "".join(
        figure(name, image, f"After the ${1 << height:02X} pass (height {height}): what it "
                            f"painted in red.")
        for height, name, image in passes)
    empty_passes = [str(height) for height in range(7) if height not in {p[0] for p in passes}]

    return "\n".join([
        "<p>Ant Attack draws the whole of what you see afresh every frame. There is no "
        "keeping track of what moved: the city round the player is read from the map, turned "
        "into a picture in a render buffer at "
        f"{link(RENDER_BUFFER)}, the people and ants put in at the right depth, and the "
        "middle of the buffer copied to the screen. This page follows one frame through "
        f"that, in the game's own code, from {link(DRAW_VIEW)}'s first call to its last.</p>",

        "<h3>The frame followed</h3>",
        "<p>Not a staged scene: a game started as the build starts one (the boy chosen, the "
        f"story card and the prompt to start passed), V held for {WALK_IN} frames to walk in at the gate, "
        f"then nothing pressed for {FRAME_AFTER} frames while the ants came out of their "
        "nest to him. By then all five have reached the wall, the girl is lying where she "
        "waits on level 1, on the wall beside the gate, and the boy stands in the gateway. "
        "Everything was run in SkoolKit's simulator when this page was built. This is the "
        "screen at the end of the frame:</p>",
        figure("draw_screen.png", screen, "The frame, as COPY_TO_SCREEN leaves it."),

        "<h3>1. Four views</h3>",
        f"<p>The view is one of four, chosen with 0, P, ENTER or SPACE ({link(READ_VIEW_KEYS)}), "
        f"each looking at the city from a different corner. {link(VIEW)} holds which, and "
        f"{link(VIEW_ORIGIN)} the cell the view is read from: the key sets it to the player's "
        "cell less an offset, so that the player lands in the middle of the picture. The "
        "offsets are the operands in READ_VIEW_KEYS; the steps are the cells the four "
        f"gathering routines ({link(GATHER_VIEWS[0])}, {link(GATHER_VIEWS[1])}, "
        f"{link(GATHER_VIEWS[2])}, {link(GATHER_VIEWS[3])}) were seen to read, run from the "
        "same origin (x, y, relative to it):</p>",
        table(["View", "Key", "Origin from the player", "Along a half-row",
               "Second half-row starts at", "Next row starts at"], offsets_rows),
        "<p>Each is the one before turned a quarter. The same frame's scene in all four, drawn "
        "by DRAW_VIEW with the view set as the key would set it:</p>",
        view_figures,
        f"<p>{link(SELECT_BLOCK_DRAWER)} picks the block picture to suit: {link(DRAW_BLOCK)} "
        f"for views 0 and 2 and {link(DRAW_BLOCK_TURNED)} for 1 and 3, since turning a "
        "quarter swaps which face of a block is lit.</p>",

        "<h3>2. Gathering the cells</h3>",
        f"<p>{link(GATHER_VIEW)} jumps to the view's own routine, 32 bytes apart from "
        f"{link(GATHER_VIEWS[0])}, which reads 21 rows of 32 cells into {link(VIEW_CELLS)} "
        f"through {link(READ_MAP_CELL)}. A row is two half-rows of 16 cells, each along a "
        "diagonal of the map, the second one cell to the side of the first; each row starts "
        "one cell further along the other diagonal. So the view is a diamond of the map, "
        "and its rows run across the screen. A cell outside the walls, with x or y below "
        "$80, reads as 0: the land outside is flat and empty.</p>",
        f"<p>The first 16 rows are the 512 places of the picture. The other five are read "
        "only for their taller blocks: a block h high appears 2h half-rows up the screen "
        "from its cell, so the cells nearest the viewer, below the bottom of the picture, "
        "can still show their tops in it.</p>",
        figure("draw_gather.png", gathered,
               "The city from above (x across, y down) around the cells this frame read, "
               "blocks grey by height, outside the walls white: the 512 cells read for the "
               "places tinted blue, the five further rows orange. The player is the red dot, "
               "the girl the purple, the ants black -- and the ants are in the map, as blocks "
               "(see below).", scale=2),

        "<h3>3. Height by height into PLANES</h3>",
        f"<p>{link(BUILD_PLANES)} turns the gathered cells into {link(PLANES)}: 512 places, "
        "one for each position a block's picture can take, 32 half-rows of 16. It fills "
        f"them with $FF ({link(CLEAR_PLANES)}) and then calls {link(MARK_PLANE)} once for "
        "each height, lowest first. For height h, MARK_PLANE reads the gathered cells "
        "32h further on -- h rows, 2h half-rows -- and writes the height's bit, $01 to $20, "
        "into every place whose cell has a block at that height. A higher block overwrites "
        "a lower one.</p>",
        "<p>That is the whole of the 3D. A block one higher and one row nearer has its "
        "picture in exactly the same place as the block behind it, so it hides that one "
        "completely, and keeping only the highest height for each place throws away "
        "nothing that could be seen (worked out from the projection below, and borne out by "
        "the pictures). What is left is, for each place on the screen, the one block to be "
        "drawn there, if any.</p>",
        figure("draw_planes.png", planes_pic,
               "PLANES for this frame, painted in DRAW_SCENE's order with one flat colour per "
               "height (lightest for the ground layer, darker upwards) in place of the "
               "shaded block."),
        f"<p>Before that, {link(CLEAR_BUFFER_ROWS)} clears the part of the buffer that will "
        f"be shown: 29 rows, four apart, on each of four calls, {link(0xB44F)} moving the "
        "starting row on each time, so rows 12 to 127 are cleared. The rows above and below, "
        "and nothing else, keep what the last frames left there (the leftovers outside the "
        "blue frame), since they are never copied.</p>",
        figure("draw_cleared.png", cleared, "The render buffer after clearing. The blue frame "
                                            "is the part COPY_TO_SCREEN copies."),

        "<h3>4. Where the people and ants go</h3>",
        f"<p>{link(PROJECT_SPRITES)} places the eight objects in the same grid. For each, "
        "from the fifth ant back to the player, it takes the position relative to the view "
        "origin, (dx, dy), turns it for the view -- (u, v) is (dx, dy) in view 0, (dy, "
        "-dx) in view 1, (-dx, -dy) in view 2 and (-dy, dx) in view 3 -- and projects it: "
        "the half-row is v - u - 2h and the column (u + v) / 2, h being the height. Either "
        f"out of 0-31 and the object is out of view ({link(0x85FA)} gives it a place past the end). "
        "The place is 512h + 16 &times; half-row + column, plus one: the height counts whole "
        "passes of the painting below. On the screen that is 8(u + v) pixels across and "
        "4(v - u) - 8h down from the corner of the buffer.</p>",
        f"<p>With the place goes the sprite frame: the record's first frame, plus four times "
        "its animation frame, plus its facing turned by the view -- or, with bit 7 of the "
        "animation frame set, that frame outright. This frame's list, in "
        f"{link(SPRITE_LIST)}:</p>",
        table(["Object", "Cell and height", "Place", "Frame"], list_rows),
        f"<p>{link(SORT_SPRITES)} bubble-sorts the list by place, and "
        f"{link(SPRITE_DISTANCES)} turns each place into its distance from the one before; "
        "the painting counts those down:</p>",
        table(["Order", "Object", "Place", "Count"], sorted_rows),
        f"<p>{link(SCROLL_VIEW)} looks at where the player went: outside the middle of the "
        "view (columns 4 to 11 of 16, half-rows 8 to 23 of 32) it moves the view origin a "
        "cell the way the player faces, unless the player is jumping or falling. The "
        "cells are already gathered, so it shows next frame.</p>",

        "<h3>5. Painting, back to front</h3>",
        f"<p>{link(DRAW_SCENE)} makes seven passes over PLANES, one for each height's bit "
        "from $01 to $40, and in each pass finds every place holding that bit, from the "
        "first place to the last, with CPIR, jumping to the block picture for each "
        f"({link(BLOCK_DRAWN)} brings it back). The places run from the back of the view "
        "to the front, and the passes from the ground up, so everything is painted after "
        "what it covers. The $40 pass has no blocks in it -- there is no seventh height -- "
        "but it keeps the count going for anything standing on top of the tallest walls.</p>",
        f"<p>The objects are threaded in with no test of their own. CPIR counts BC down "
        "as it goes, and BC is the distance to the next object in the sorted list, counted "
        f"across all the passes. When CPIR runs out of count before it finds a block, "
        f"{link(DRAW_HERE)} draws the object due at that place, and {link(NEXT_SPRITE)} "
        "loads the next distance (skipping any of 0: a second object in exactly the same "
        "place is not drawn). So an object at height h is painted in pass h, after every "
        "block lower than it and every block at its height further back, and before the "
        "rest.</p>",
        "<p>An ant is a block in the map (see "
        '<a href="Ants.html">how the ants hunt</a>), so its own cell is marked in PLANES '
        "like any wall -- and an ant's place is exactly where its block would be drawn. The "
        "plus one in every place is what makes that work: CPIR finds the ant's block and "
        "runs out of count on the same byte, and the running out wins (JP PO), so the "
        "sprite is drawn there instead and the scan carries on past the block. In this "
        f"frame {words(swallowed)} of the ants' places held their own $01 and no block was "
        "drawn at any of them"
        + (f"; the other ant's place held a taller block in front of it, which pass "
           f"{planes[hidden[0]].bit_length() - 1} painted over it." if hidden else ".")
        + "</p>",
        table(["Pass", "Height", "Blocks drawn", "Sprites drawn (frame at place)"], pass_rows),
        pass_figures,
        f"<p>Passes {', '.join(empty_passes)} drew nothing in this frame. The whole paint "
        f"drew {sum(1 for d in traced['draws'] if d[0] == 'block')} blocks and "
        f"{sum(1 for d in traced['draws'] if d[0] == 'sprite')} sprites.</p>",

        "<h3>The block and the sprites</h3>",
        f"<p>The block is code. {link(DRAW_BLOCK)} and {link(DRAW_BLOCK_TURNED)} are unrolled "
        "runs of stores with the picture in their operands: eight steps, each painting a row "
        "of the top face, merged with what is behind it at the edges, and the row eight "
        f"below it, the sides, outright. {link(PLANE_TO_BUFFER)} gives each place its "
        "corner in the buffer: a place is 16 pixels wide, each half-row four pixels below "
        "the last and half a place across, so the blocks tile like bricks. Here are the two "
        "pictures, each painted by its own routine twice, over a clear buffer and a full "
        "one: the pink pixels are where the background shows through.</p>",
        "".join(figure(n, i, what, scale=1) for n, i, what in (
            ("draw_block.png", blocks[0], f"{link(DRAW_BLOCK)}, views 0 and 2."),
            ("draw_block_turned.png", blocks[1], f"{link(DRAW_BLOCK_TURNED)}, views 1 and 3."))),
        f"<p>A sprite frame is 64 bytes, 16 rows of mask, graphic, mask, graphic; frame f is "
        f"64f bytes from {link(PLAY)}, so the boy's and the ants' frames are in "
        f"{link(0xB700)} and the girl's in {link(0x9A00)} (all of them are on "
        '<a href="Sprites.html">the sprites page</a>). '
        f"{link(DRAW_SPRITE)} ANDs each byte of the buffer with the mask and ORs in the "
        "graphic. The boy's frame in this scene is "
        f"${boy_frame:02X}, at {link(0x8000 + 64 * boy_frame)}; here it is drawn by "
        "DRAW_SPRITE over two blocks drawn by DRAW_BLOCK, what it changed in red. The mask "
        "clears very little: the people and the ants are drawn almost entirely in ink, "
        "ORed over whatever is behind them.</p>",
        "".join(figure(n, i, what, scale=1) for n, i, what in (
            ("draw_mask.png", sprite_pics[0], "The mask: black where it clears the "
                                              "background."),
            ("draw_graphic.png", sprite_pics[1], "The graphic."),
            ("draw_sprite_over.png", over_pic, "Drawn over two blocks."))),

        "<h3>6. To the screen</h3>",
        f"<p>{link(COPY_TO_SCREEN)} copies rows 12 to 127 of the buffer, bytes 1 to 30 of "
        "each, to the same lines and columns of the screen with LDIR: 116 rows of 30 bytes. "
        "The byte either side and the rows above and below are margin, for blocks and "
        "sprites that hang over the edge of the view. The attributes are never touched: the "
        "play area stays black on white, as BASIC left it.</p>",
        figure("draw_before.png", with_window(buffer_image(memory_before)),
               "The render buffer as the frame began: the last frame's picture, whole, "
               "margins and all."),

        "<h3>Where the time goes</h3>",
        "<p>T-states for each stage of DRAW_VIEW, counted in the simulator for the frame "
        f"followed above and, for the range, over {len(measured['view'])} views: that frame's "
        f"place and the places the person waits on levels 1 to {MEASURED_LEVELS}, each in "
        "all four views. DRAW_SCENE's time is split by where the program counter was: inside "
        "a block drawer, inside DRAW_SPRITE, or in the scan itself.</p>",
        table(["Stage", "This frame", "Share", "Range over the views"], time_rows),
        f"<p>A block costs about {one_block:,.0f} T-states to draw, and the scan through "
        "PLANES, seven passes of 512 bytes by CPIR at 21 T-states a byte, is about 75,000 "
        "before anything is found. The frame as a whole, over the "
        f"{len(real['frame'])} frames of the run above -- the {WALK_IN} walking in, and "
        f"{len(real['frame']) - WALK_IN} more at the spot the frame was taken:</p>",
        table(["Part of the frame", "T-states"], frame_rows),
        f"<p>That is about {per_frame:,.0f} T-states, {fps:.1f} frames a second at 3.5 MHz. The "
        "simulator does not model the ULA's memory contention, so these are counts, not "
        "timings: the real machine is a little slower wherever the code touches the screen "
        "(the copy's writes, the printing of the clock) and not at all in the render buffer "
        "and the code, which are above $8000. Nothing paces the frames -- there is no HALT "
        "or frame count in the loop -- so the game runs as fast as it draws, and drawing is "
        "almost all of it. The clock's figure is high one frame in three, when it prints the "
        "time through the ROM.</p>",

        "<h3>What is confirmed and what is inferred</h3>",
        "<ul>"
        "<li>Confirmed by running: every picture and table on this page is the game's code "
        "run in the simulator -- the cells read, the planes, the passes, the sprite list, the "
        "views, the T-state counts. The ant sprites taking the place of the ants' own blocks "
        "was checked in the frame followed.</li>"
        "<li>Read from the code: the projection formulas, the per-view turns, the scroll "
        "window, and why CPIR's running out wins over a match on the same byte (JP PO "
        "is taken when BC reaches 0, whatever else CPIR found).</li>"
        "<li>Inferred: that keeping only the highest block for a place loses nothing that "
        "could be seen, and that painting height by height is then always right. It follows "
        "from the projection, and no picture made for these pages shows a fault, but it has "
        "not been proved for every arrangement of blocks and objects. Two objects in "
        "exactly the same place (an ant in the player's cell, say) is read from the code, "
        "not watched.</li>"
        "</ul>",
    ])


# --------------------------------------------------------------------------
# Set pieces: a patch of open ground, built on, for the other pages.
# --------------------------------------------------------------------------

AFTER_DRAW = 0x8E92         # GAME_FRAME, back from DRAW_VIEW: before HANDLE_EVENTS
GROUND = 15                 # the set piece's patch of open ground, cells across


class SetPiece:
    """A game with the ants parked out of the way and a patch of open ground
    to build on: (x0, y0) is its corner, and cells are given relative to it.
    Every staging -- the walls, where people stand -- is written into the
    simulated machine before a run; everything in the run is the game's."""

    def __init__(self, snapshot: Path):
        self.base = Game.start(snapshot)
        # The first frame sends the player home to the gate (his explosion
        # countdown, set by BASIC); let it happen before anything is placed.
        self.base.frame()
        self.base.park_ants()
        self.x0, self.y0 = open_ground(self.base.memory, GROUND)

    def game(self) -> Game:
        return self.base.copy()

    def at(self, dx: int, dy: int) -> tuple[int, int]:
        return self.x0 + dx, self.y0 + dy

    def wall(self, game: Game, cells, height: int) -> None:
        """Columns of `height` blocks on the given (dx, dy) cells."""
        for dx, dy in cells:
            game.set_cell(self.x0 + dx, self.y0 + dy, (1 << height) - 1)

    def put(self, game: Game, record: int, dx: int, dy: int, height: int,
            facing: int = 1) -> None:
        game.place(record, self.x0 + dx, self.y0 + dy, height)
        game.memory[record + FACING] = facing

    def put_ant(self, game: Game, index: int, dx: int, dy: int, height: int = 0,
                facing: int = 0) -> None:
        ant = ANTS[index]
        game.memory[ant + STUN] = 0
        game.move_ant(ant, self.x0 + dx, self.y0 + dy, height)
        game.memory[ant + FACING] = facing


def run_logged(game: Game, frames: int, keys=(), watch=(PLAYER,), pictures: bool = False):
    """Run `frames` frames with `keys` held, and for each the watched records
    as they stand after the drawing and before HANDLE_EVENTS clears the event
    bytes -- with, if asked, the play area as that frame drew it."""
    log = []
    for index in range(frames):
        if game.ended:
            break
        # keys: the keys held throughout, or a list of them, one per frame.
        frame_keys = keys[index] if keys and isinstance(keys[0], (list, tuple)) else keys
        game.until(AFTER_DRAW, frame_keys)
        entry = {record: game.record(record) for record in watch}
        entry["energy"] = game.memory[PLAYER_ENERGY + 1], game.memory[RESCUEE_ENERGY + 1]
        entry["ammo"] = game.memory[AMMO + 1]
        entry["throw"] = game.memory[THROW_TIME]
        if pictures:
            entry["picture"] = play_area(game.memory)
            entry["origin"] = game.memory[VIEW_ORIGIN], game.memory[VIEW_ORIGIN + 1], \
                game.memory[VIEW]
        entry["last"] = not game.frame(frame_keys)
        entry["after"] = {record: game.record(record) for record in watch}
        log.append(entry)
    return log


def screen_position(x: int, y: int, height: int, origin) -> tuple[int, int]:
    """Where PROJECT_SPRITES puts an object's picture on the screen: its top
    left, in pixels, for the view origin (ox, oy, view)."""
    ox, oy, view = origin
    dx, dy = (x - ox + 128) % 256 - 128, (y - oy + 128) % 256 - 128
    u, v = [(dx, dy), (dy, -dx), (-dx, -dy), (-dy, dx)][view]
    return 8 * (u + v), 4 * (v - u) - 8 * height


def crop_around(picture, x: int, y: int, width: int = 112, height: int = 88):
    """A piece of a play_area picture centred on screen pixel (x, y)."""
    # play_area starts at screen (8, 12).
    left = min(max(x - 8 - width // 2, 0), picture.width - width)
    top = min(max(y - 12 - height // 2, 0), picture.height - height)
    return picture.crop((left, top, left + width, top + height))


def filmstrip(log, record: int, width: int = 96, height: int = 80, centre=None):
    """The pictures of a run_logged(pictures=True) run side by side, each cut
    to the same box round where `record` was in the first frame (or round
    `centre`, a screen pixel)."""
    if centre is None:
        first = log[0]
        x, y, h = first[record][X], first[record][Y], first[record][HEIGHT]
        sx, sy = screen_position(x, y, h, first["origin"])
        centre = sx + 8, sy + 8
    return strip([crop_around(entry["picture"], centre[0], centre[1], width, height)
                  for entry in log])


def basic_records(snapshot: Path) -> list[list[int]]:
    """The object records as BASIC's DATA sets them each level (lines 110 to
    180, sixteen numbers a record; -1 leaves a byte as it was)."""
    from skoolkit.basic import BasicLister

    listing = BasicLister().list_basic(list(ba.game_memory(snapshot)))
    records = []
    for line in listing.split("\n"):
        match = re.match(r"^\s*(\d+) DATA (.*)$", line)
        if match and 110 <= int(match.group(1)) <= 180:
            records.append([int(v) for v in match.group(2).split(",")])
    if len(records) != 8 or any(len(r) != 16 for r in records):
        raise RuntimeError("the object DATA is not eight records of sixteen")
    return records


def basic_line(snapshot: Path, number: int) -> str:
    from skoolkit.basic import BasicLister

    listing = BasicLister().list_basic(list(ba.game_memory(snapshot)))
    for line in listing.split("\n"):
        match = re.match(r"^\s*(\d+) (.*)$", line)
        if match and int(match.group(1)) == number:
            return match.group(2)
    raise RuntimeError(f"no BASIC line {number}")


# --------------------------------------------------------------------------
# Movement.
# --------------------------------------------------------------------------

ROW = 6                     # the set pieces' row across the patch of ground


def _mv_walk(sp, g):
    sp.put(g, PLAYER, 3, ROW, 0)


def _mv_wall1(sp, g):
    sp.put(g, PLAYER, 4, ROW, 0)
    sp.wall(g, [(5, ROW)], 1)


def _mv_wall2(sp, g):
    sp.put(g, PLAYER, 4, ROW, 0)
    sp.wall(g, [(5, ROW)], 2)


def _mv_early_jump(sp, g):
    sp.put(g, PLAYER, 3, ROW, 0)
    sp.wall(g, [(5, ROW)], 1)


def _mv_roof(sp, g):
    sp.put(g, PLAYER, 4, ROW, 0)
    g.set_cell(*sp.at(4, ROW), 0x02)


def _mv_ledge(sp, g):
    sp.put(g, PLAYER, 3, ROW, 1)
    sp.wall(g, [(1, ROW), (2, ROW), (3, ROW)], 1)


def _mv_gap(sp, g):
    sp.put(g, PLAYER, 3, ROW, 1)
    sp.wall(g, [(2, ROW), (3, ROW), (5, ROW), (6, ROW), (7, ROW)], 1)


def _mv_bite(sp, g):
    sp.put(g, PLAYER, 4, ROW, 0)
    sp.put_ant(g, 0, 6, ROW, 0, facing=3)


def _following(g, record=RESCUEE):
    g.memory[record + STATE] = 1
    g.memory[record + STUN] = 0


def _mv_step_up(sp, g):
    sp.put(g, PLAYER, 10, ROW, 1)
    sp.wall(g, [(8, ROW), (9, ROW), (10, ROW), (11, ROW)], 1)
    sp.put(g, RESCUEE, 5, ROW, 0)
    _following(g)


def _mv_step_up2(sp, g):
    sp.put(g, PLAYER, 10, ROW, 2)
    sp.wall(g, [(8, ROW), (9, ROW), (10, ROW), (11, ROW)], 2)
    sp.put(g, RESCUEE, 5, ROW, 0)
    _following(g)


def _mv_on_her(sp, g):
    sp.put(g, RESCUEE, 4, ROW, 0)
    _following(g)
    sp.put(g, PLAYER, 4, ROW, 1)


def _mv_drop_on_her(sp, g):
    sp.put(g, RESCUEE, 4, ROW, 0)
    _following(g)
    sp.put(g, PLAYER, 4, ROW, 5)


def _mv_her_on_him(sp, g):
    sp.put(g, PLAYER, 4, ROW, 0)
    sp.put(g, RESCUEE, 4, ROW, 1)
    _following(g)


def _mv_stunned_drop(sp, g):
    sp.put(g, PLAYER, 4, ROW, 5)
    g.memory[PLAYER + STUN] = 3


def _mv_on_ant(sp, g):
    sp.put_ant(g, 2, 4, ROW, 0)
    g.memory[ANTS[2] + STUN] = 0x40
    sp.put(g, PLAYER, 4, ROW, 3)


def _mv_her_fall(sp, g):
    sp.put(g, PLAYER, 4, ROW, 0)
    sp.put(g, RESCUEE, 6, ROW, 5)
    _following(g)


# (what, set-up, keys, frames, the record followed, what the code says should
# happen -- worked out from the listing before the run, and shown beside it).
MOVES = [
    ("Walking on open ground", _mv_walk, ["v"], 3, PLAYER,
     "a cell a frame, each a step (an event for the click)"),
    ("Walking into a wall one block high", _mv_wall1, ["v"], 3, PLAYER,
     "blocked: no step, and the player cannot step up (no bit 4)"),
    ("The same, jumping as well (V and C)", _mv_wall1, ["v", "c"], 5, PLAYER,
     "up a block; next frame the grace frame of the fall walks him onto the wall; "
     "with C still held, he jumps again"),
    ("Jumping at a wall two blocks high", _mv_wall2, ["v", "c"], 5, PLAYER,
     "up a block, but the way ahead is still blocked, so he drops back"),
    ("Jumping a cell short of the wall", _mv_early_jump, ["v", "c"], 5, PLAYER,
     "up, a step forward in the air into the empty cell, and down again: a jump "
     "covers one cell"),
    ("Jumping under a roof (C)", _mv_roof, ["c"], 2, PLAYER,
     "no room above: no jump"),
    ("Walking off a ledge one block high", _mv_ledge, ["v"], 5, PLAYER,
     "a step off the edge, the grace frame's step, then the drop"),
    ("Walking over a one-cell gap", _mv_gap, ["v"], 5, PLAYER,
     "the grace frame carries him over the gap, and he walks on"),
    ("An ant walks into the player's cell", _mv_bite, [], 5, PLAYER,
     "the ant is in the map, so the player's own cell is full: bitten, pushed up a "
     "block, and a point of energy off"),
    ("The rescued person, following, meets a one-block wall", _mv_step_up, [], 6, RESCUEE,
     "blocked, but bit 4 is set: up a block in her own cell, then on over the wall"),
    ("The same, but the wall is two blocks high", _mv_step_up2, [], 8, RESCUEE,
     "up a block, still blocked, up another in her own cell -- but that used the grace "
     "frame, so she falls back: two blocks stop her"),
    ("The player standing on the rescued person's head", _mv_on_her, [], 3, PLAYER,
     "bit 0: she counts as something to stand on"),
    ("The player dropped five blocks onto her head", _mv_drop_on_her, [], 7, PLAYER,
     "SHARE_CELL clears his fall a block above her: no landing at all"),
    ("The player walks off with her on his head", _mv_her_on_him, ["v"], 5, RESCUEE,
     "nothing carries her: she is left in the air, and falls"),
    ("The player falls five blocks while stunned", _mv_stunned_drop, [], 8, PLAYER,
     "the stunned branch clears the fall count, so it is never landed"),
    ("The player drops three blocks onto a stunned ant", _mv_on_ant, [], 5, PLAYER,
     "landing at height 1: PARALYSE_ANT finds the ant underneath"),
    ("The rescued person, following, falls five blocks", _mv_her_fall, [], 8, RESCUEE,
     "a bad fall, as for the player"),
]


def _frame_text(entry, record: int, start, sp) -> str:
    r = entry[record]
    dx = r[X] - start[0]
    dy = r[Y] - start[1]
    where = f"{dx:+d}" if dy == 0 else f"{dx:+d},{dy:+d}"
    notes = []
    if r[FALLING]:
        notes.append(f"falling {r[FALLING]}")
    if r[STUN]:
        notes.append(f"stunned {r[STUN]}" if r[STUN] != PARALYSED else "paralysed")
    if r[EVENT]:
        notes.append(EVENTS.get(r[EVENT], f"event {r[EVENT]}"))
    return f"{where}, h{r[HEIGHT]}" + (f" ({', '.join(notes)})" if notes else "")


def _falls(sp) -> list[tuple]:
    """Drop the player from each height and see how LANDED takes it."""
    rows = []
    for blocks in range(1, 7):
        g = sp.game()
        sp.put(g, PLAYER, 4, ROW, blocks)
        g.look_at(0)
        log = run_logged(g, blocks + 3)
        landed = next(e for e in log if e[PLAYER][EVENT] in (1, 2) and e[PLAYER][HEIGHT] == 0)
        frame = log.index(landed) + 1
        stun, event = landed[PLAYER][STUN], landed[PLAYER][EVENT]
        falling = blocks + 1
        expected_stun = 8 * falling if falling >= 5 else falling
        expected_event = 2 if falling >= 5 else 1
        rows.append((blocks, falling, frame, expected_stun, stun, expected_event, event))
    return rows


def _movement_page(snapshot: Path, image_dir: Path, link, log) -> str:
    log("  running the movement set pieces...")
    sp = SetPiece(snapshot)
    records = basic_records(snapshot)

    # The record, with each object's starting values from BASIC's DATA.
    names = ["The player", "The rescued person", "The grenade", "Ant 1", "Ant 2",
             "Ant 3", "Ant 4", "Ant 5"]
    fields = ["x", "y", "height", "first frame", "facing", "falling", "stunned", "flags",
              "animation", "explosion", "home x", "home y", "home height", "+$0D", "+$0E",
              "event"]

    def value(v, field):
        if v < 0:
            return "&ndash;"
        if field in (0, 1, 3, 7, 10, 11):
            return f"${v:02X}"
        return str(v)

    record_rows = []
    for field in range(16):
        record_rows.append([f"+${field:02X}", fields[field]]
                           + [value(records[i][field], field) for i in range(8)])

    # TEST_MAP_BIT's answers, run on a cell with blocks at heights 0 and 2
    # inside the walls, and on a cell outside.
    g = sp.game()
    cx, cy = sp.at(4, ROW)
    g.set_cell(cx, cy, 0x05)
    test_rows = []
    for height in [0xFF] + list(range(8)):
        answers = []
        for x, y in ((cx, cy), (0x40, 0x40)):
            g.call(TEST_MAP_BIT, {"A": height, "DE": y << 8 | x})
            answers.append("solid" if g.reg("F") & 1 else "empty")
        test_rows.append([str(height if height != 0xFF else -1)] + answers)

    # The situations.
    move_rows = []
    for what, setup, keys, frames, record, expected in MOVES:
        g = sp.game()
        setup(sp, g)
        g.look_at(0)
        start = (g.memory[record + X], g.memory[record + Y])
        watched = (PLAYER, RESCUEE, ANTS[0], ANTS[2])
        logged = run_logged(g, frames, keys, watch=watched)
        frames_text = "; ".join(f"{i}: {_frame_text(e, record, start, sp)}"
                                for i, e in enumerate(logged, 1))
        extra = ""
        if setup is _mv_bite:
            extra = (f" Energy {logged[0]['energy'][0]} before, {logged[-1]['energy'][0]} "
                     "after.")
        if setup is _mv_on_ant:
            ant = logged[-1][ANTS[2]]
            extra = (" The ant's stun count: "
                     + ("$FF, paralysed for good." if ant[STUN] == PARALYSED
                        else f"{ant[STUN]}."))
        keys_text = " and ".join(k.upper() for k in keys) or "none"
        who = "the player" if record == PLAYER else "the rescued person"
        move_rows.append([what, keys_text, expected,
                          f"{who.capitalize()}, frame by frame: {frames_text}.{extra}"])

    falls = _falls(sp)
    fall_rows = [[str(b), str(f), str(fr), str(es), str(s), EVENTS[ee], EVENTS[e]]
                 for b, f, fr, es, s, ee, e in falls]
    fall_ok = all(es == s and ee == e for _, _, _, es, s, ee, e in falls)

    # Pictures: the climb, and the bite.
    pictures = []
    for name, setup, keys, frames, record, caption in (
            ("move_climb.png", _mv_wall1, ["v", "c"], 5, PLAYER,
             "Climbing a one-block wall with V and C held, a frame a picture: up, onto "
             "the wall, up again, forward into the air, and down."),
            ("move_bite.png", _mv_bite, [], 5, PLAYER,
             "An ant walks into the player's cell: the frame after, he is bitten and "
             "pushed up a block, and then drops back."),
            ("move_step_up.png", _mv_step_up, [], 6, RESCUEE,
             "The rescued person following the player up a step on her own.")):
        g = sp.game()
        setup(sp, g)
        g.look_at(0)
        logged = run_logged(g, frames, keys, watch=(PLAYER, RESCUEE), pictures=True)
        picture = filmstrip(logged, record)
        pictures.append(figure(name, save(picture, image_dir, name), caption))

    return "\n".join([
        f"<p>Everything that moves in Ant Attack -- the player, the person to be rescued, "
        f"the grenade and the ants -- is moved by one routine, {link(MOVE_OBJECT)}, reached "
        f"through {link(MOVE_OR_RESPAWN)}. Positions are whole cells and whole blocks: a "
        "step is a cell and a drop is a block, one a frame, and there is nothing in between. "
        "This page sets out the record, what counts as solid, and the order in which "
        "MOVE_OBJECT decides what an object does, then runs the game's own code on a set of "
        "situations to show what it makes of each.</p>",

        "<h3>The record</h3>",
        f"<p>Eight records of 16 bytes at {link(PLAYER)}, in the order GAME_FRAME "
        f"({link(GAME_FRAME)}) moves them after the player: the rescued person "
        f"({link(MOVE_RESCUEE)}), the grenade ({link(MOVE_GRENADE)}), the five ants "
        f"({link(MOVE_ANTS)}). BASIC fills them at the start of every level from the DATA "
        "in lines 110 to 180, and these are the values it sets, read from the program as "
        "it loads (a dash is -1 in the DATA: that byte is left alone):</p>",
        table(["", "Field"] + names, record_rows),
        "<ul>"
        "<li>Flags, +$07: bit 0 may stand on the other person (the player and the rescued "
        "person each have it), bit 1 jump and bit 2 move (set from the keys for the player, "
        f"by {link(FOLLOW_PLAYER)} for the rescued person and at the throw for the grenade; "
        "the ants have bit 2 set for good), bit 3 never falls (no one has it, and nothing "
        "sets it), bit 4 steps up a one-block rise by itself.</li>"
        "<li>The explosion countdown at +$09 starts at 1 for the player, the grenade and the "
        "ants: on the first frame each goes home, to +$0A to +$0C. That is how the player "
        "starts at the gate and the ants in their nest.</li>"
        "<li>The two people's first frames are left alone by the DATA: lines 610 and 620 "
        "poke them once, when the boy or the girl is chosen ($DC for the boy, $6C for the "
        "girl), and the other one is the person to be rescued.</li>"
        "<li>+$0D and +$0E are the ants' speed and count (see "
        '<a href="Ants.html">the ants</a>) and the rescued person\'s state and last '
        'distance (see <a href="Rescue.html">the rescue</a>).</li>'
        "</ul>",

        "<h3>What is solid</h3>",
        f"<p>Only the map. {link(TEST_MAP_BIT)} answers whether a cell has a block at a "
        f"height, and everything asks it. The people are not in the map, so nothing "
        f"collides with them; the ants are, put there by {link(TOGGLE_MAP_BIT)}, so everything "
        "collides with the ants. Its answers, run on a cell with blocks at heights 0 and 2 "
        "inside the walls, and on a cell outside:</p>",
        table(["Height", "Inside the walls", "Outside"], test_rows),
        "<p>Height -1 is always solid, which is what the ground is; 6, one above the tallest "
        "block, is always empty; 7 and above are solid, a ceiling no jump gets through. "
        "Outside the walls, with x or y below $80, there is nothing but the ground.</p>",

        "<h3>One frame of MOVE_OBJECT</h3>",
        f"<p>The questions are asked in this order, and the first that applies decides the "
        "frame:</p>",
        "<ol>"
        f"<li><b>Anything to stand on?</b> {link(TEST_BELOW)} asks about the height below. "
        f"If not, {link(FALL)}: count a frame of falling at +$05; on the first frame the "
        "object may still walk -- the grace frame -- and after that it drops a block a "
        "frame.</li>"
        f"<li><b>Something in its own cell?</b> Only an ant can have walked in: bitten "
        f"({link(BITTEN)}), and {link(RISE)} pushes the object up a block.</li>"
        f"<li><b>Stunned?</b> Count the stun down ({link(STUNNED)}), clear the fall count, "
        "and do nothing else.</li>"
        f"<li><b>Just landed?</b> A fall count of 2 or more means it was falling last frame: "
        f"{link(LANDED)}.</li>"
        f"<li><b>Jump?</b> Bit 1: {link(RISE)} goes up a block if the cell above is free, "
        "and otherwise carries on as a walk.</li>"
        f"<li><b>Walk?</b> Bit 2: the next cell the way it faces ({link(STEP)}), at its own "
        f"height. Free: step there, and an event of 1 for the click. Blocked: "
        f"{link(STEP_UP)}, which for an object with bit 4 rises a block in its own cell if "
        "there is room, to walk on next frame.</li>"
        "</ol>",
        f"<p>The player's keys are read into the flags first ({link(READ_CONTROLS)}): "
        "V is bit 2 and C bit 1, every frame, so they act only while held. SYMBOL SHIFT and "
        "M turn a quarter each frame they are held -- not while stunned. And after the move, "
        f"{link(CHOOSE_FRAME)} picks the picture from the state: the blast, lying down for a "
        "long stun, arms out for a short one, arms up falling, legs moving walking.</p>",

        "<h3>The code, tried</h3>",
        "<p>Each row is a situation built on a patch of open ground inside the walls, with "
        "the ants moved out of the way, and then left to the game: the frames are the "
        "game's own, run in the simulator when this page was built, and read after each "
        "frame's drawing (before the events are cleared). Positions are cells along the way "
        "the one followed faces, from where it started, and heights.</p>",
        table(["Situation", "Keys", "What the code says", "What it did"], move_rows),
        *pictures,

        "<h3>Falls</h3>",
        f"<p>A fall is counted in frames at +$05, the grace frame included, so a drop of n "
        f"blocks is n + 1 frames. {link(LANDED)} makes it a step if it was under five frames, "
        "and stuns for as many frames as it lasted; five or more is a bad fall -- "
        f"{say(1)} for the player, {say(2)} for the rescued person "
        f"({link(HANDLE_EVENTS)}) -- and stuns for eight frames for every frame of it. So "
        "four blocks is the most that is safe to drop. The expected figures are worked out "
        "from those rules; the others are what the game did, dropping the player from each "
        "height over open ground:</p>",
        table(["Blocks", "Frames falling", "Landed on frame", "Stun expected", "Stun given",
               "Event expected", "Event given"], fall_rows),
        "<p>" + ("Every figure is as expected. " if fall_ok else
                 "<b>Some figures differ from the rules above; see the table.</b> ")
        + "A stunned person does nothing at all, and at six or seven frames a second a "
        "six-block fall costs the player the best part of ten seconds. A short fall is "
        "not quite free either: every landing, even from a jump, stuns for two frames or "
        "more.</p>",
        "<p>Two ways out of a landing, both in the table above. A fall that ends while the "
        "stun count is still running is never landed: the stunned branch comes before the "
        "landing and clears the fall count. And two people in one cell a block apart are "
        f"never falling: {link(SHARE_CELL)}, run every frame for the rescued person once she "
        "follows, clears the player's fall count and both stuns. BASIC starts the rescued "
        "person stunned for four frames, enough to swallow a short drop. A landing at "
        f"height 1 has one more job: it may be on an ant's back, and {link(PARALYSE_ANT)} "
        'looks for one (see <a href="Ants.html">the ants</a>).</p>',

        "<h3>Standing on each other</h3>",
        f"<p>Bit 0 of the flags lets {link(TEST_BELOW)} count the other person -- the one "
        "IY points at, which for the player is the rescued person and the other way round "
        "-- as something to stand on, if they are exactly one block below in the same cell. "
        "That is all: nothing carries anyone. Walk out from under someone and they are left "
        "standing on air, and fall; walk off someone's head and you fall. The rescued "
        f"person in the player's own cell is handled by {link(ON_TOP)}: on top of him she "
        "takes his facing and walks on, underneath she stops.</p>",

        "<h3>What is confirmed and what is inferred</h3>",
        "<ul>"
        "<li>Confirmed by running: every row of the tables above -- the situations, the "
        "falls, TEST_MAP_BIT's answers -- is the game's code run in the simulator on a "
        "staged scene. The staging is the starting positions and the walls; the rest is "
        "the game.</li>"
        "<li>Read from the code: the order of the questions in MOVE_OBJECT, and the "
        "fields of the record. The DATA values are read from the BASIC as loaded.</li>"
        "<li>Not run: bit 3 of the flags, never falls. Nothing in the game or its BASIC "
        "sets it, so the three instructions behind it in FALL have never been seen to "
        "run; what they would do is read from the code (clear the fall count and carry on "
        "as if standing).</li>"
        "</ul>",
    ])


# --------------------------------------------------------------------------
# The ants.
# --------------------------------------------------------------------------

DIRECTION_ARROWS = {0: "&darr;", 1: "&rarr;", 2: "&uarr;", 3: "&larr;"}  # x across, y down


def from_above(memory, left: int, top: int, width: int, height: int, scale: int = 12,
               marks=(), path=(), outline=()):
    """A patch of the city from above, x across and y down: the ground sand,
    each block grey by its top height. `marks` are (x, y, colour) dots,
    `path` a list of cells joined by a line that darkens as it goes, and
    `outline` (x, y, colour) squares."""
    from PIL import Image, ImageDraw

    image = Image.new("RGB", (width * scale, height * scale), (250, 250, 250))
    draw = ImageDraw.Draw(image)
    for y in range(height):
        for x in range(width):
            value = memory[cell_address(left + x, top + y)] if left + x >= 0x80 and \
                top + y >= 0x80 else 0
            colour = SAND if not value else tuple(200 - 26 * value.bit_length() for _ in range(3))
            draw.rectangle([x * scale, y * scale, x * scale + scale - 1, y * scale + scale - 1],
                           fill=colour, outline=(215, 205, 170) if not value else None)
    centre = lambda x, y: ((x - left) * scale + scale // 2, (y - top) * scale + scale // 2)
    for x, y, colour in outline:
        cx, cy = centre(x, y)
        draw.rectangle([cx - scale // 2, cy - scale // 2, cx + scale // 2 - 1, cy + scale // 2 - 1],
                       outline=colour, width=2)
    for index in range(1, len(path)):
        shade = 200 - int(180 * index / len(path))
        draw.line([centre(*path[index - 1]), centre(*path[index])], fill=(shade, shade, 255),
                  width=max(2, scale // 5))
    for x, y, colour in marks:
        cx, cy = centre(x, y)
        r = scale // 3
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=colour)
    return image


def grid_image(cells: dict, colours: dict, size: int, scale: int = 14):
    """A square of cells (dx, dy) from -size to size, coloured by value."""
    from PIL import Image, ImageDraw

    side = 2 * size + 1
    image = Image.new("RGB", (side * scale, side * scale), PAPER)
    draw = ImageDraw.Draw(image)
    for (dx, dy), value in cells.items():
        x, y = (dx + size) * scale, (dy + size) * scale
        draw.rectangle([x, y, x + scale - 2, y + scale - 2], fill=colours[value])
    return image


def level_start(snapshot: Path) -> Game:
    """A real game at the top of its first frame of play: the title, the boy
    chosen, the story card, BASIC's two-frame preview behind the prompt to
    start, and V pressed to start (build_antattack's _start, stopped at the
    first frame instead of a second or so later)."""
    from skoolkit import CSimulator, read_bin_file
    from skoolkit.simulator import Simulator
    from skoolkit.simutils import PC, SP, T

    memory = list(ba.game_memory(snapshot))
    memory[:0x4000] = read_bin_file(str(ba.ROM))
    sim = (CSimulator or Simulator)(memory, state={"iff": 0, "im": 1, "tstates": 0})
    sim.registers[SP] = ba.LOADER_STACK
    tracer = ba._key_tracer_class()(sim)
    sim.set_tracer(tracer)
    pc = ba.PAST_LOAD_CHECKS
    steps = ba._start("b")
    # Up to the prompt to start, which the last two steps answer.
    for keys, seconds in steps[:-2]:
        tracer.keys = set(keys)
        sim.trace(pc, 0, 0, sim.registers[T] + int(seconds * ba.TSTATES_PER_SECOND),
                  True, None, None, None, None, None)
        pc = sim.registers[PC]
    tracer.keys = set(steps[-2][0])
    sim.trace(pc, PLAY_LOOP, 0, sim.registers[T] + 5 * ba.TSTATES_PER_SECOND,
              True, None, None, None, None, None)
    if sim.registers[PC] != PLAY_LOOP or sim.memory[FRAMES_LEFT] != 0:
        raise RuntimeError("the first frame of play was not reached")
    return Game(sim.memory, list(sim.registers[:28]))


def _pillar_rows(snapshot: Path):
    """The first frames of a real level, watching the first ant, the second,
    and the first ant's home cell: its home is inside a pillar."""
    start = level_start(snapshot)
    first, second = ANTS[0], ANTS[1]
    pillar = (start.memory[first + HOME_X], start.memory[first + HOME_Y])
    on_tape = ba.game_memory(snapshot)[cell_address(*pillar)]
    rows = [["The first frame of play begins", _fmt_cell(*start.record(first)[:3]),
             _fmt_cell(*start.record(second)[:3]), f"${start.cell(*pillar):02X}", ""]]
    for frame in range(1, 9):
        start.until(AFTER_DRAW, ["v"] if frame == 1 else [])
        a, b = start.record(first), start.record(second)
        rows.append([f"After frame {frame}", _fmt_cell(a[X], a[Y], a[HEIGHT]),
                     _fmt_cell(b[X], b[Y], b[HEIGHT]), f"${start.cell(*pillar):02X}",
                     EVENTS.get(a[EVENT], "") or "&ndash;"])
        start.frame()
    return rows, pillar, on_tape


def _ant_log(g: Game, ant: int, frames: int, keys=()):
    out = []
    for index in range(frames):
        g.frame(keys if index == 0 else ())
        out.append(g.record(ant))
    return out


def _ants_page(snapshot: Path, image_dir: Path, link, log) -> str:
    from PIL import Image

    log("  running the ants...")
    sp = SetPiece(snapshot)
    records = basic_records(snapshot)
    ant = ANTS[0]

    # 1. In the map: one move of an ant along a wall top, the cells watched.
    g = sp.game()
    sp.wall(g, [(d, ROW) for d in range(2, 9)], 1)
    sp.put(g, PLAYER, 11, ROW, 0)
    sp.put_ant(g, 0, 4, ROW, 1, facing=1)
    g.look_at(0)
    old_cell, new_cell = sp.at(4, ROW), sp.at(5, ROW)
    xor_rows = [["Before the ant's turn", f"${g.cell(*old_cell):02X}", f"${g.cell(*new_cell):02X}"]]
    g.until(MOVE_ANT)
    g.until(0x8A0D)
    xor_rows.append([f"After the first {link(TOGGLE_MAP_BIT)}: out of the map",
                     f"${g.cell(*old_cell):02X}", f"${g.cell(*new_cell):02X}"])
    g.until(0x8A10)
    xor_rows.append([f"After {link(MOVE_OR_RESPAWN)}: a step, x {g.memory[ant + X] - sp.x0:+d}",
                     f"${g.cell(*old_cell):02X}", f"${g.cell(*new_cell):02X}"])
    g.until(0x8A1E)
    xor_rows.append(["After the second TOGGLE_MAP_BIT: back in, where it is now",
                     f"${g.cell(*old_cell):02X}", f"${g.cell(*new_cell):02X}"])

    # 2. The nest: the homes from DATA, under the pyramid.
    homes = [(r[HOME_X], r[HOME_Y]) for r in records[3:]]
    city = ba.game_memory(snapshot)
    nest_left, nest_top = min(x for x, _ in homes) - 6, min(y for _, y in homes) - 3
    nest = save(from_above(city, nest_left, nest_top, 22, 18, 10,
                           marks=[(x, y, (200, 0, 0)) for x, y in homes]),
                image_dir, "ants_nest.png")
    nest_rows = [[f"Ant {i + 1}", _fmt_cell(x, y, records[3 + i][HOME_HEIGHT]),
                  f"${city[cell_address(x, y)]:02X}"] for i, (x, y) in enumerate(homes)]

    # 3. Which way: DIRECTION_TO for every cell round a target.
    g = sp.game()
    direction_rows = []
    for dy in range(-4, 5):
        row = []
        for dx in range(-4, 5):
            if dx == 0 and dy == 0:
                row.append("<b>P</b>")
                continue
            g.call(DIRECTION_TO, {"HL": (0xC0 + dy) << 8 | (0xC0 + dx), "DE": 0xC0C0})
            row.append(DIRECTION_ARROWS[g.reg("A") & 3])
        direction_rows.append(row)
    direction_table = ('<table class="default" style="text-align: center">'
                       + "".join("<tr>" + "".join(f'<td style="width: 1.6em">{c}</td>' for c in row)
                                 + "</tr>" for row in direction_rows) + "</table>")

    # 4. A chase round a wall.
    wall = [(6, d) for d in range(3, 10)]
    g = sp.game()
    sp.put(g, PLAYER, 10, ROW, 0)
    sp.wall(g, wall, 2)
    sp.put_ant(g, 0, 2, ROW, 0, facing=1)
    g.look_at(0)
    start = sp.at(2, ROW)
    chase_frames = []
    path = [start]
    arrived = None
    decisions = {"closer": 0, "turned": 0}
    for frame in range(1, 121):
        before = g.record(ant)
        if frame in (1, 20, 40, 60) or arrived is None and frame > 60:
            g.until(AFTER_DRAW)
            record = g.record(ant)
            origin = g.memory[VIEW_ORIGIN], g.memory[VIEW_ORIGIN + 1], g.memory[VIEW]
            picture = play_area(g.memory)
            if frame in (1, 20, 40, 60):
                chase_frames.append((frame, picture, origin))
        g.frame()
        record = g.record(ant)
        path.append((record[X], record[Y]))
        if record[FACING] & 3 != before[FACING] & 3 and (record[X], record[Y]) == \
                (before[X], before[Y]):
            decisions["turned"] += 1
        elif (record[X], record[Y]) != (before[X], before[Y]):
            decisions["closer"] += 1
        if arrived is None and (record[X], record[Y]) == sp.at(10, ROW):
            arrived = frame
            break
    player_cell = sp.at(10, ROW)
    chase = save(from_above(g.memory, sp.x0, sp.y0, GROUND, GROUND, 16,
                            marks=[(start[0], start[1], (0, 0, 0)),
                                   (player_cell[0], player_cell[1], (220, 0, 0))],
                            path=path), image_dir, "ants_chase.png")
    px, py = screen_position(player_cell[0], player_cell[1], 0, chase_frames[0][2])
    chase_figures = "".join(
        figure(f"ants_chase{frame}.png",
               save(crop_around(picture, px - 24, py + 8, 176, 104), image_dir,
                    f"ants_chase{frame}.png"),
               f"Frame {frame}.")
        for frame, picture, _ in chase_frames)

    # 5. Speed: an ant outside the walls, where nothing is in the way, chasing
    # a player far off in a straight line, for 60 frames.
    speed_rows = []
    for speed in (2, 3, 4, 20):
        g = sp.game()
        g.place(PLAYER, 0x70, 0x40, 0)
        g.move_ant(ANTS[1], 0x10, 0x40, 0)
        g.memory[ANTS[1] + STUN] = 0
        g.memory[ANTS[1] + FACING] = 1
        g.memory[ANTS[1] + STATE] = speed
        g.memory[ANTS[1] + COUNT] = speed
        g.look_at(0)
        for _ in range(60):
            g.frame()
        moved = g.memory[ANTS[1] + X] - 0x10
        speed_rows.append([str(speed), str(60 - 60 // speed), str(moved)])

    # 6. Bites: the player standing still, an ant three cells off.
    bite_rows = []
    for index, speed in ((0, records[3][STATE]), (1, 2)):
        g = sp.game()
        sp.put(g, PLAYER, 6, ROW, 0)
        sp.put_ant(g, index, 9, ROW, 0, facing=3)
        g.memory[ANTS[index] + STATE] = speed
        g.memory[ANTS[index] + COUNT] = speed
        g.look_at(0)
        logged = run_logged(g, 120, watch=(PLAYER,))
        bites = [i for i, e in enumerate(logged, 1) if e[PLAYER][EVENT] == 4]
        bite_rows.append([f"{speed}", str(len(bites)), f"{bites[0]}" if bites else "-",
                          str(logged[-1]["energy"][0])])
    # The last point of energy: how many frames are left after it.
    g = sp.game()
    sp.put(g, PLAYER, 6, ROW, 0)
    sp.put_ant(g, 0, 8, ROW, 0, facing=3)
    g.memory[PLAYER_ENERGY + 1] = 1
    g.look_at(0)
    logged = run_logged(g, 40)
    eaten = next((i for i, e in enumerate(logged, 1) if e[PLAYER][EVENT] == 4), None)
    last = next((i for i, e in enumerate(logged, 1) if e["last"]), None)
    after_eaten = (last - eaten) if eaten and last else None

    # The first frames of a real level: the first ant arrives home inside a
    # pillar of the nest.
    pillar_rows, pillar, pillar_on_tape = _pillar_rows(snapshot)
    # The waiting rescued person is not moved, so not bitten.
    waiting = []
    for state in (0, 1):
        g = sp.game()
        sp.put(g, RESCUEE, 6, ROW, 0)
        g.memory[RESCUEE + STATE] = state
        g.memory[RESCUEE + STUN] = 0
        sp.put(g, PLAYER, 12, ROW, 0)
        sp.put_ant(g, 0, 7, ROW, 0, facing=3)
        g.look_at(0)
        logged = run_logged(g, 20, watch=(RESCUEE, ANTS[0]))
        through = any(e[ANTS[0]][X:Y + 1] == e[RESCUEE][X:Y + 1] for e in logged)
        waiting.append((through, logged[-1]["energy"][1]))

    # 7. Grenades: BLAST_ANT for every cell round an explosion.
    g = sp.game()
    blast = {}
    for dy in range(-9, 10):
        for dx in range(-9, 10):
            t = g.copy()
            t.memory[ANTS[1]:ANTS[1] + 3] = bytes([0xC0 + dx, 0xC0 + dy, 0])
            t.memory[ANTS[1] + STUN] = 0
            t.memory[ANTS[1] + BLAST] = 0
            t.call(BLAST_ANT, {"HL": 0xC0C0, "C": 0, "IY": ANTS[1]})
            if t.memory[ANTS[1] + BLAST]:
                blast[(dx, dy)] = "blown"
            elif t.memory[ANTS[1] + STUN]:
                blast[(dx, dy)] = ("stunned", t.memory[ANTS[1] + STUN])
            else:
                blast[(dx, dy)] = "missed"
    stun_given = {v[1] for v in blast.values() if isinstance(v, tuple)}
    blast_values = {k: (v if not isinstance(v, tuple) else "stunned") for k, v in blast.items()}
    blast_values[(0, 0)] = "centre"
    blast_pic = save(grid_image(blast_values, {"blown": (205, 0, 0), "stunned": (240, 170, 60),
                                               "missed": (235, 235, 235),
                                               "centre": (0, 0, 0)}, 9),
                     image_dir, "ants_blast.png")
    blown_max = max(abs(dx) + abs(dy) for (dx, dy), v in blast_values.items() if v == "blown")
    stunned_max = max(abs(dx) + abs(dy) for (dx, dy), v in blast_values.items() if v == "stunned")

    # A half-speed ant blown up: which frame each frame draws for it.
    g = sp.game()
    sp.put(g, PLAYER, 2, ROW, 0, facing=1)
    sp.put_ant(g, 1, 5, ROW, 0, facing=3)
    g.memory[ANTS[1] + STUN] = 0x40
    g.look_at(0)
    drawn = []
    blast_strip = []
    for frame in range(12):
        g.until(0x84B5, ["s"] if frame == 0 else [])        # after PROJECT_SPRITES
        entry = SPRITE_LIST + 3 * LIST_ORDER.index(ANTS[1])
        place = g.memory[entry] | g.memory[entry + 1] << 8
        drawn.append((g.memory[ANTS[1] + BLAST], g.memory[entry + 2], place))
        g.until(AFTER_DRAW)
        origin = g.memory[VIEW_ORIGIN], g.memory[VIEW_ORIGIN + 1], g.memory[VIEW]
        if place >> 8 != 0xFF:
            ax, ay = sp.at(5, ROW)
            sx, sy = screen_position(ax, ay, 0, origin)
            blast_strip.append(crop_around(play_area(g.memory), sx + 8, sy + 8, 40, 36))
        g.frame()
    shown = [f"${frame:02X}" for count, frame, place in drawn if place >> 8 != 0xFF]
    blast_frames = sum(1 for count, frame, place in drawn
                       if place >> 8 != 0xFF and 0xF4 <= frame <= 0xF7)
    ant_frames = sum(1 for count, frame, place in drawn if place >> 8 != 0xFF and frame >= 0xF8)
    blast_strip_pic = save(strip(blast_strip, 2), image_dir, "ants_blasted.png")

    # A paralysed ant in a blast.
    revived_rows = []
    for distance in (3, 6, 9):
        g = sp.game()
        sp.put(g, PLAYER, 1, ROW, 0, facing=1)
        # S throws for two frames: the grenade explodes two cells ahead.
        sp.put_ant(g, 1, 3 + distance, ROW, 0)
        g.memory[ANTS[1] + STUN] = PARALYSED
        g.look_at(0)
        logged = _ant_log(g, ANTS[1], 60, ["s"])
        explosion = 3          # the frame the grenade explodes, S being 2 frames
        after = logged[explosion - 1]
        home = after[BLAST] != 0
        moved = next((i for i, r in enumerate(logged, 1)
                      if (r[X], r[Y]) != sp.at(3 + distance, ROW)), None)
        if home:
            what = f"blown up (countdown {after[BLAST]}), stun count 0"
        elif after[STUN] != PARALYSED:
            what = f"stunned: the stun count is {after[STUN]}"
        else:
            what = "missed: still paralysed"
        revived_rows.append([str(distance), what,
                             f"frame {moved}" if moved else "not in 60 frames"])

    arrived_text = (f"It reached the player's cell on frame {arrived}" if arrived else
                    "It had not reached the player after 120 frames")

    return "\n".join([
        f"<p>Five ants, all moved by the same few routines: {link(MOVE_ANTS)} gives each "
        f"its turn through {link(ANT_TURN)}, and {link(MOVE_ANT)} moves it. They do very "
        "little -- step, look at the distance to the player, turn -- and the city does the "
        "rest. This page takes them apart one piece at a time, running the game's own code "
        "on set pieces for each.</p>",

        "<h3>The ants are in the map</h3>",
        f"<p>The one trick everything else hangs on. {link(MOVE_ANT)} takes the ant out of "
        f"the map before it moves -- {link(TOGGLE_MAP_BIT)} flips the bit for its height in "
        "its cell -- moves it like anything else, and flips the bit in its new cell. Between "
        "turns, every ant is a block. So nothing needs a test for ants: the player walks "
        "into one as into a wall, stands on one as on a wall, and PLANES draws one as a wall "
        'until its sprite takes the block\'s place (see <a href="Drawing.html">the '
        "drawing</a>). One ant's turn, on top of a wall one block high, the two cells it "
        "moves between watched in the simulator:</p>",
        table(["", "The cell it leaves", "The cell it enters"], xor_rows),
        "<p>$03 is the wall's block at height 0 with the ant at height 1 on it; $01 the "
        "wall alone. It has to be an XOR both ways, so the map and the ant's record must "
        "always agree: an ant whose record were moved without its bit would leave a block "
        "behind and put one in its own cell -- and find itself &ldquo;bitten&rdquo; (below). "
        "Which is presumably why BASIC's DATA leaves the ants' x, y and height alone at the "
        "start of each level (the dashes in the record table on "
        '<a href="Movement.html">how people move</a>) and sends them home through the '
        "explosion countdown instead: MOVE_ANT then takes each out where the map has it and "
        "puts it back at home.</p>",

        "<h3>Home: the nest</h3>",
        "<p>The ants' homes, from the DATA, are five cells in a row at ground level. The map "
        "has nothing at height 0 there but blocks above: they are inside the stepped "
        "pyramid near the middle of the city, which is hollow at the bottom. The map byte "
        "of each home cell, read from the game:</p>",
        table(["", "Home (x, y, height)", "Map byte there"], nest_rows),
        figure("ants_nest.png", nest,
               "The nest from above (x across, y down), blocks grey by their top height; the "
               "homes in red. Every home cell has blocks over it and none on the ground.",
               scale=1),
        "<p>An ant goes home when a level starts and when a grenade has blown it up.</p>",
        f"<p>The first ant's home is not like the others. Its cell holds ${pillar_on_tape:02X} "
        "in the map as loaded: a block at height 0 as well as the roof -- one of the two "
        "pillars at the ends of the nest's front row. Arriving there, the ant XORs its own "
        "bit into the cell and so takes the pillar's block out: the map shows the cell empty "
        "at ground level while the ant is in it. On its next turn MOVE_ANT takes it out of "
        "the map again, which puts the pillar back, and MOVE_OBJECT finds a block in the "
        "ant's own cell -- a bite, as far as it can tell. The first frames of a real level "
        f"(the boy chosen, V pressed at the prompt to start), watching the first ant, the second, and the "
        f"cell at {_fmt_cell(*pillar)}:</p>",
        table(["", "Ant 1", "Ant 2", "The pillar's cell", "Ant 1's event"], pillar_rows),
        "<p>While the pillar reads as empty, the second ant is free to walk into the same "
        "cell, and for a few frames two ants and a pillar share one bit of the map. Nothing "
        "comes of it that a player "
        "would see: HANDLE_EVENTS only looks at the two people's events, the roof stops the "
        "bite pushing the ant up, and once both have walked out the pillar is whole again. "
        "(Found by running; that the pillar is meant to be there, and the home is simply "
        "set one cell too far along, is an inference.)</p>",

        "<h3>Which way to go</h3>",
        f"<p>On each turn {link(MOVE_ANT)} first takes the ant's step, then compares its "
        f"distance from the player before and after ({link(DISTANCE)}: the x and y "
        "differences added, no diagonals). There is no looking ahead.</p>",
        "<ul>"
        "<li><b>Closer:</b> it keeps going the way it faces, legs moving, and if it is now "
        f"less than four cells away it turns to face the player with {link(DIRECTION_TO)}."
        "</li>"
        "<li><b>Not closer</b> -- blocked, or the step took it away: its legs stop, and it "
        f"turns a quarter left or right, whichever the next bit from {link(RANDOM)} "
        "says. That step is not undone: an ant that walks the wrong way stays there, turned."
        "</li>"
        "</ul>",
        "<p>Every ant chases the player; none chases the rescued person (MOVE_ANTS points IY "
        "at the player for all five). DIRECTION_TO never answers with a diagonal. Along a "
        "row or column it points straight at the target; off them it picks one of the two "
        "directions that close the gap by which quarter the target is in. Run for every "
        "cell round a target P, x across and y down, each arrow the way an ant there would "
        "turn:</p>",
        direction_table,
        "<p>A pinwheel: in each quarter the ants swing the same way round, so ants closing "
        "in from all sides tend to circle the last few cells rather than come straight in. "
        "(That reading is inferred from the table, not measured.)</p>",
        f"<p>A worked example: the fast ant, three cells short of a wall two blocks high, "
        "with the player standing still on the far side. The ants and the player are staged; "
        f"every step after is the game's. {arrived_text}, having taken "
        f"{decisions['closer']} steps and turned on the spot {decisions['turned']} times.</p>",
        figure("ants_chase.png", chase,
               "The ant's path from above, x across and y down, the line darkening as it goes: "
               "the ant starts at the black dot, the player is the red.", scale=1),
        chase_figures,

        "<h3>Speed</h3>",
        f"<p>{link(ANT_TURN)} counts +$0E down every frame, and on the frame it reaches zero "
        "the ant does nothing and the count goes back to +$0D. So an ant misses one frame "
        "in every +$0D. The first ant's +$0D is 20 in the DATA -- it misses one frame in "
        "twenty -- and line 190 pokes the other four with BASIC's <code>sp</code>, which "
        "line 10 sets to 2 and line 90 raises to 2 + INT(rescues / 4) from the fourth "
        "rescue: 2 on levels 1 to 4, 3 on levels 5 to 8, 4 on levels 9 and 10. So on the "
        "first four levels four of the ants move at half speed, and one never slows. "
        "Measured: an ant outside the walls, where nothing is in its way, chasing a player "
        "far off in a straight line for 60 frames, against the 60 - 60 / +$0D steps the "
        "rule gives:</p>",
        table(["+$0D", "Steps expected", "Steps taken"], speed_rows),
        f"<p>The skipped frame is also the only frame on which the ant is left as "
        f"{link(BLAST_FRAME)} set it -- which matters below.</p>",

        "<h3>Biting</h3>",
        "<p>An ant's step can take it into the player's cell: the player is not in the map, "
        f"so nothing stops it. On the player's next move {link(MOVE_OBJECT)} finds his own "
        f"cell occupied -- the ant's bit -- and that is a bite: {link(BITTEN)} records it and "
        "pushes him up a block, onto the ant's back. "
        f"{link(HANDLE_EVENTS)} takes a point of energy off and says so. The player has 20 "
        "points (BASIC's line 220, every attempt). Standing still with an ant three cells "
        "away, for 120 frames:</p>",
        table(["The ant's +$0D", "Bites", "First bite on frame", "Energy left"], bite_rows),
        f"<p>The bite that takes the last point shows {say(14)}, and "
        f"{link(CHECK_GAME_OVER)} puts a count of five in {link(FRAMES_LEFT)}: "
        + (f"staged with one point left, the bite came on frame {eaten} and PLAY went back "
           f"to BASIC after frame {last}, {words(after_eaten)} frames later"
           if after_eaten is not None else "PLAY goes back to BASIC a few frames later")
        + f". That is not the end of the game: BASIC puts up {say('another go')} "
        "and starts the level again, energy and ammunition full, the clock where it was. "
        'Only the clock ends a game (see <a href="Rescue.html">the rescue</a>).</p>',
        "<p>The rescued person is bitten the same way once she follows the player -- "
        "moving, she runs MOVE_OBJECT, which is where bites are found -- and has 20 points "
        "of her own; at zero, the attempt is over just the same. While she waits she is "
        "never moved, so she cannot be bitten at all: staged with an ant walking through "
        f"her cell, she {'was walked through' if waiting[0][0] else 'was passed'} and kept "
        f"{waiting[0][1]} points; the same scene with her following cost her "
        f"{20 - waiting[1][1]}.</p>",

        "<h3>Grenades and ants</h3>",
        f"<p>While a grenade explodes, {link(GRENADE_BLAST)} runs {link(BLAST_ANT)} for each "
        "ant at the grenade's height: within four cells, along the grid, the ant is blown "
        f"up -- {say(3)} -- and within seven it is stunned "
        f"for {', '.join(str(s) for s in sorted(stun_given))} of its turns. At any other height "
        "it is untouched. BLAST_ANT run for an ant in every cell round an explosion at the "
        "middle, at the same height:</p>",
        figure("ants_blast.png", blast_pic,
               f"Red: blown up (up to {blown_max} cells away). Orange: stunned (up to "
               f"{stunned_max}). Grey: missed.", scale=1),
        "<p>A blown-up ant stops where it is for its explosion countdown, five of its "
        "turns, and then goes home to the nest, whole: nothing kills an ant. A stunned ant "
        "does not stand still either: MOVE_ANT compares distances after the (lack of a) "
        "move, finds itself no closer, and turns at random, so it spins on the spot until "
        "the stun runs out.</p>",
        "<p>The explosion is not always drawn. ANT_TURN sets the blast frame first, but on "
        "every turn the ant takes, MOVE_ANT's &ldquo;not closer&rdquo; sets the animation "
        "frame back to an ordinary ant's; only on the frames the ant skips does the blast "
        "frame survive to be drawn. A half-speed ant, blown up by a grenade thrown with S, "
        f"frame by frame, as {link(PROJECT_SPRITES)} listed it: {', '.join(shown)} -- "
        f"{words(blast_frames)} blast frames and {words(ant_frames)} ant frames, "
        "alternating. The fast ant skips one frame in twenty, so it is almost never seen "
        "exploding at all. (Found by running; whether it was meant is not known.)</p>",
        figure("ants_blasted.png", blast_strip_pic,
               "The half-speed ant after the blast, a frame a picture: blast and ant in turn.",
               scale=2),
        "<p>A paralysed ant -- one the player has landed on, stunned for good at $FF -- is "
        "skipped by ANT_TURN altogether. But BLAST_ANT does not look: it overwrites the stun "
        "either way. A paralysed ant staged at three distances from where a grenade thrown "
        "with S explodes, the ant as the explosion's frame left it, and the first frame it "
        "was seen to move:</p>",
        table(["Cells from the explosion", "The ant", "Moving again"], revived_rows),
        "<p>So a grenade does not finish off a paralysed ant; it frees it -- sent home "
        "whole, or stunned for a while and then back on its feet.</p>",
        "<p>The sprites include four frames of an ant on its back, $F0 to $F3 (on "
        '<a href="Sprites.html">the sprites page</a>). Nothing draws them: an ant\'s frame is '
        "only ever its first frame plus 0 or 1 for the legs, or the blast. A stunned or "
        "paralysed ant is drawn standing.</p>",

        "<h3>What is confirmed and what is inferred</h3>",
        "<ul>"
        "<li>Confirmed by running, on staged scenes in the simulator: the XOR in and out, "
        "DIRECTION_TO's answers, the chase, the speeds, the bites and the end of the "
        "energy, the waiting person not being bitten, the blast's reach, the blast frame "
        "only on skipped frames, and the paralysed ant freed by a blast.</li>"
        "<li>Read from the code: that every ant chases the player and none the rescued "
        "person; the speeds by level (BASIC lines 10, 90 and 190); that nothing draws "
        "frames $F0 to $F3.</li>"
        "<li>Inferred: why BASIC leaves the ants' positions alone (to keep the map and the "
        "records in step), that the pyramid's hollow is meant as a nest, and what the "
        "pinwheel does to a crowd of ants.</li>"
        "</ul>",
    ])


# --------------------------------------------------------------------------
# The grenade.
# --------------------------------------------------------------------------

THROW_KEYS = [("S", ["s"]), ("D", ["d"]), ("F", ["f"]), ("G", ["g"]), ("S and G", ["s", "g"])]
KEY_BITS = {"s": 0x02, "d": 0x04, "f": 0x08, "g": 0x10}     # the A-G half-row


def side_view(memory, sp, row: int, first: int, last: int, player, path, top: int = 4):
    """A slice of a set piece seen from the side, along `row`: x across from
    `first` to `last`, heights up; blocks grey, the player red, and each
    frame's grenade position a blue dot labelled with the frame numbers (an
    orange dot where it exploded)."""
    from PIL import Image, ImageDraw, ImageFont

    size = 30
    font = ImageFont.load_default(size=11)
    columns = last - first + 1
    image = Image.new("RGB", (columns * size, (top + 1) * size + 6), (250, 250, 250))
    draw = ImageDraw.Draw(image)
    ground = top * size

    def box(dx, height):
        x = (dx - first) * size
        y = ground - (height + 1) * size
        return x, y

    draw.rectangle([0, ground, image.width, image.height], fill=SAND)
    for dx in range(first, last + 1):
        value = memory[cell_address(*sp.at(dx, row))]
        for height in range(6):
            if value >> height & 1 and height < top:
                x, y = box(dx, height)
                draw.rectangle([x, y, x + size - 1, y + size - 1], fill=(150, 150, 150),
                               outline=(110, 110, 110))
    px, py = box(*player)
    draw.rectangle([px + 10, py + 4, px + size - 11, py + size - 1], fill=(205, 0, 0))
    places = {}
    for frame, dx, height, exploding in path:
        places.setdefault((dx, height), []).append((frame, exploding))
    for (dx, height), frames in places.items():
        x, y = box(dx, height)
        colour = (240, 140, 20) if any(e for _, e in frames) else (40, 90, 220)
        draw.ellipse([x + 9, y + 14, x + size - 10, y + size - 3], fill=colour)
        label = ",".join(str(f) for f, _ in frames[:3]) + ("+" if len(frames) > 3 else "")
        draw.text((x + size // 2, y + 7), label, fill=(0, 0, 0), font=font, anchor="mm")
    return image


def _grenade_run(sp, setup, keys, frames, watch=(GRENADE, PLAYER, RESCUEE)):
    g = sp.game()
    setup(sp, g)
    g.look_at(0)
    per_frame = [list(keys)] + [[] for _ in range(frames - 1)]
    return g, run_logged(g, frames, per_frame, watch=watch)


def _grenade_path(logged, sp):
    """(frame, dx, height, exploding) for each frame the grenade was out."""
    path = []
    for frame, entry in enumerate(logged, 1):
        r = entry[GRENADE]
        if r[X] < 0x80 or r[Y] < 0x80:
            continue                    # at home, outside the walls
        path.append((frame, r[X] - sp.x0, r[HEIGHT], r[BLAST] != 0))
    return path


def _gr_flat(sp, g):
    sp.put(g, PLAYER, 1, ROW, 0)


def _gr_step(sp, g):
    sp.put(g, PLAYER, 1, ROW, 0)
    sp.wall(g, [(5, ROW), (6, ROW), (7, ROW), (8, ROW), (9, ROW)], 1)


def _gr_tall(sp, g):
    sp.put(g, PLAYER, 1, ROW, 0)
    sp.wall(g, [(4, ROW), (5, ROW), (6, ROW)], 2)


def _gr_ledge(sp, g):
    sp.put(g, PLAYER, 1, ROW, 2)
    sp.wall(g, [(0, ROW), (1, ROW), (2, ROW)], 2)


def _gr_in_front(sp, g):
    sp.put(g, PLAYER, 3, ROW, 0)
    sp.wall(g, [(4, ROW)], 3)


GRENADE_PATHS = [
    ("Open ground", _gr_flat, ["f"], 12, 0, 10,
     "straight on, a cell a frame, and explodes eight cells on"),
    ("A wall one block high", _gr_step, ["f"], 12, 0, 10,
     "blocked, it rises a block in its own cell (bit 4, as the rescued person does) and "
     "rolls on along the top"),
    ("A wall two blocks high", _gr_tall, ["f"], 12, 0, 7,
     "it climbs a block, tries again and climbs another, but has used its grace frame "
     "and falls back: it cannot get over"),
    ("Off a ledge two blocks high", _gr_ledge, ["f"], 12, 0, 8,
     "the grace frame's step off the edge, a drop, and a landing that stuns it, as it "
     "would a person, so that it sits still until its time runs out"),
]


def _grenades_page(snapshot: Path, image_dir: Path, link, log) -> str:
    from PIL import Image

    log("  throwing grenades...")
    sp = SetPiece(snapshot)
    records = basic_records(snapshot)

    # 1. How far each key throws: outside the walls, where nothing is in the way.
    key_rows = []
    for name, keys in THROW_KEYS:
        def setup(_sp, g):
            g.place(PLAYER, 0x20, 0x40, 0)
            g.memory[PLAYER + FACING] = 1
        g, logged = _grenade_run(sp, setup, keys, 40)
        bits = sum(KEY_BITS[k] for k in keys)
        exploded = next(e for e in logged if e[GRENADE][BLAST])
        ahead = exploded[GRENADE][X] - 0x20
        key_rows.append([name, f"${bits:02X}", str(bits), str(bits), str(ahead),
                         str(logged[0]["ammo"])])

    # 2. Held down: throws again when the last one has gone home.
    g = sp.game()
    _gr_flat(sp, g)
    g.look_at(0)
    held = run_logged(g, 14, ["s"], watch=(GRENADE,))
    launches = [i for i, e in enumerate(held, 1)
                if e[GRENADE][X] >= 0x80 and e[GRENADE][BLAST] == 0 and
                (i == 1 or held[i - 2][GRENADE][X] < 0x80)]
    ammo_used = held[0]["ammo"] + 1 - held[-1]["ammo"]
    g = sp.game()
    _gr_flat(sp, g)
    g.memory[AMMO + 1] = 0
    g.look_at(0)
    empty = run_logged(g, 3, ["s"], watch=(GRENADE,))
    no_ammo = all(e[GRENADE][X] < 0x80 for e in empty)

    # 3. Its pictures, drawn by DRAW_SPRITE on a cleared buffer.
    g = sp.game()
    g.memory[RENDER_BUFFER:RENDER_BUFFER + 32 * BUFFER_ROWS] = bytes(32 * BUFFER_ROWS)
    pictures = []
    for index, frame in enumerate(range(0xF4, 0xF8)):
        place = 16 * 8 + 2 + 2 * index
        paint_sprite(g, place, frame)
        left, top = 16 * (place & 15), 4 * (place >> 4)
        pictures.append(buffer_image(g.memory).crop((left, top, left + 16, top + 16)))
    frames_pic = save(strip([p.resize((48, 48), Image.NEAREST) for p in pictures], 8),
                      image_dir, "grenade_frames.png")

    # 4. Paths over set pieces.
    path_rows = []
    for index, (what, setup, keys, frames, first, last, expected) in enumerate(GRENADE_PATHS):
        g, logged = _grenade_run(sp, setup, keys, frames)
        path = _grenade_path(logged, sp)
        player = (logged[0][PLAYER][X] - sp.x0, logged[0][PLAYER][HEIGHT])
        picture = side_view(g.memory, sp, ROW, first, last, player, path)
        name = f"grenade_path{index}.png"
        save(picture, image_dir, name)
        where = path[-1] if path else None
        result = (f"exploded {where[1] - player[0]:+d} cells along, at height {where[2]}"
                  if where else "did not explode")
        path_rows.append([what, expected, img(name, picture, what, 1, shrink=False), result])

    # 5. Against the people.
    people_rows = []
    cases = [
        ("Throwing with F while walking forward (V held)", _gr_flat, ["v", "f"], ["v"], PLAYER),
        ("Throwing with F at a three-block wall in the next cell", _gr_in_front, ["f"], [],
         PLAYER),
        ("The rescued person two cells ahead, stunned so she stays put", None, ["f"], [],
         RESCUEE),
        ("The rescued person beside where a grenade thrown with S explodes", None, ["s"], [],
         RESCUEE),
    ]
    for what, setup, first_keys, rest_keys, victim in cases:
        g = sp.game()
        if setup:
            setup(sp, g)
        elif "beside" in what:
            sp.put(g, PLAYER, 1, ROW, 0)
            sp.put(g, RESCUEE, 3, ROW + 1, 0)
            g.memory[RESCUEE + STUN] = 0x40
        else:
            sp.put(g, PLAYER, 1, ROW, 0)
            sp.put(g, RESCUEE, 3, ROW, 0)
            g.memory[RESCUEE + STUN] = 0x40
        g.look_at(0)
        per_frame = [first_keys] + [rest_keys] * 15
        logged = run_logged(g, 16, per_frame, watch=(GRENADE, PLAYER, RESCUEE))
        hit = next((i for i, e in enumerate(logged, 1) if e[victim][EVENT] == 8), None)
        energy = 0 if victim == PLAYER else 1
        last = next((i for i, e in enumerate(logged, 1) if e["last"]), None)
        if hit:
            e = logged[hit - 1]
            outcome = (f"blown up on frame {hit}, in the cell {e[victim][X] - sp.x0:+d} "
                       f"along, at height {e[victim][HEIGHT]}; energy "
                       f"{logged[hit]['energy'][energy] if hit < len(logged) else 0} "
                       f"after; PLAY back to BASIC after frame {last}")
        else:
            outcome = (f"untouched: energy {logged[-1]['energy'][energy]} after "
                       f"{len(logged)} frames")
        people_rows.append([what, " and ".join(k.upper() for k in first_keys), outcome])

    # 6. A worked example: a direct hit, a frame at a time.
    g = sp.game()
    sp.put(g, PLAYER, 0, ROW, 0)
    sp.put_ant(g, 1, 9, ROW, 0)
    g.memory[ANTS[1] + STUN] = 0x40
    g.look_at(0)
    shot = run_logged(g, 30, [["f"]] + [[]] * 29, watch=(GRENADE, PLAYER, ANTS[1]),
                      pictures=True)
    first = shot[0]
    x0, y0 = screen_position(first[PLAYER][X], first[PLAYER][Y], 0, first["origin"])
    x1, y1 = screen_position(*sp.at(9, ROW), 0, first["origin"])
    centre = ((x0 + x1) // 2 + 8, (y0 + y1) // 2 + 8)
    shot_figures = []
    for frame in (1, 3, 5, 7, 9, 10, 11, 12):
        entry = shot[frame - 1]
        picture = crop_around(entry["picture"], centre[0], centre[1], 144, 80)
        name = f"grenade_shot{frame}.png"
        grenade = entry[GRENADE]
        if grenade[BLAST]:
            state = "exploding"
        elif grenade[X] >= 0x80:
            state = f"in flight, {entry['throw']} frames to go"
        else:
            state = "gone home"
        shot_figures.append(figure(name, save(picture, image_dir, name),
                                   f"Frame {frame}: {state}."))
    blown = next((i for i, e in enumerate(shot, 1) if e[ANTS[1]][BLAST]), None)
    ant_home = (records[4][HOME_X], records[4][HOME_Y])
    went_home = next((i for i, e in enumerate(shot, 1)
                      if (e[ANTS[1]][X], e[ANTS[1]][Y]) == ant_home), None)

    return "\n".join([
        f"<p>There is one grenade, the third object record ({link(GRENADE)}), and "
        f"{link(MOVE_GRENADE)} handles it every frame: {link(THROW_GRENADE)} to throw it or "
        f"keep it flying, {link(MOVE_OR_RESPAWN)} to move it like anything else, "
        f"{link(BLAST_FRAME)} for its explosion's pictures and {link(GRENADE_BLAST)} to see "
        "what the explosion caught. Between throws it waits at its home, "
        f"{_fmt_cell(records[2][HOME_X], records[2][HOME_Y], records[2][HOME_HEIGHT])}, far "
        "outside the walls and out of every view.</p>",

        "<h3>Throwing</h3>",
        f"<p>S, D, F and G throw. THROW_GRENADE reads the A-to-G half-row and keeps bits 1 "
        "to 4 -- S, D, F and G -- and that number is the flight time in frames, kept in "
        f"{link(THROW_TIME)}: 2, 4, 8 or 16, so the keys further along throw further. Keys "
        "held together add up. The grenade starts in the player's cell, facing his way, and "
        "moves a cell every frame, so it explodes as many cells ahead as it flew frames. "
        "Measured outside the walls, where nothing is in the way:</p>",
        table(["Keys", "Bits", "Flight frames", "Cells expected", "Cells measured",
               "Grenades left after"], key_rows),
        f"<p>Every throw costs one of the grenades counted at {link(AMMO)}, which BASIC sets "
        "to 20 for each attempt (line 220); with none left the keys do nothing "
        f"({'confirmed: staged with none left, nothing was thrown' if no_ammo else 'but a staged throw with none left went ahead'}). "
        "Only one grenade can be out: a key is ignored while one is flying or exploding, and "
        "a key held down throws again the moment the last has gone home -- held for "
        f"{len(held)} frames, S threw on frames {', '.join(str(f) for f in launches)} and "
        f"used {ammo_used}. The throw sets the player's picture to arms out for the frame.</p>",

        "<h3>In flight and exploding</h3>",
        "<p>In flight the grenade is drawn as frame $F4 outright (bit 7 of its animation "
        "byte). When the time runs out it explodes where it is: THROW_GRENADE sets its "
        "explosion countdown to 5 and stops it moving. MOVE_OR_RESPAWN counts that down in "
        "the same frame, so BLAST_FRAME shows $F4, $F7, $F6 and $F5 -- the countdown's low "
        "two bits -- over four frames, and on the fifth the grenade goes home. Its own "
        "frames, $68 to $6B, are never seen. The four explosion frames, drawn by "
        f"{link(DRAW_SPRITE)}:</p>",
        figure("grenade_frames.png", frames_pic, "Frames $F4, $F5, $F6 and $F7.", scale=1),

        "<h3>No arc</h3>",
        "<p>The grenade is not thrown through the air. It moves along the ground by the "
        f"same {link(MOVE_OBJECT)} as the people, at its own height: it has bit 4 of the "
        "flags, so it climbs a one-block step as the rescued person does, and it falls off "
        'edges with the same grace frame (see <a href="Movement.html">how people move</a>). '
        "Thrown with F from the red cell, the grenade's place each frame, seen from the side "
        "(the numbers are the frames it spent in each place):</p>",
        table(["Set piece", "What the code says", "The grenade's path", "Result"], path_rows),

        "<h3>Checked against both people, every frame</h3>",
        "<p>The people are not in the map, so the grenade cannot collide with them. Instead "
        "THROW_GRENADE compares its cell and height with the player's and then with the "
        "rescued person's on every frame of the flight, the last included, and anyone it "
        "shares a cell with is blown up: their explosion countdown set, and an event of 8 "
        f"for {link(HANDLE_EVENTS)}, which puts their energy straight to 0 -- "
        f"{say(6)} or {say(9)} -- and "
        "the attempt is over. The explosion itself harms only ants; a person beside it is "
        "safe. On staged scenes:</p>",
        table(["Situation", "Keys", "What happened"], people_rows),
        "<p>So a grenade must not be thrown while walking forward -- the player walks into "
        "it the next frame -- nor at a wall right in front, where it climbs up in the "
        "player's own cell and falls back on him; and the person being rescued is at risk "
        "along the whole flight, not just where it lands.</p>",

        "<h3>What it does to ants</h3>",
        f"<p>While the countdown runs, GRENADE_BLAST runs {link(BLAST_ANT)} for each of the five ants "
        "at the grenade's height: blown up within four cells, stunned within seven. The "
        'details, and what it does to a paralysed ant, are on <a href="Ants.html">how the '
        "ants hunt</a>. A worked example: F thrown at an ant nine cells away, stunned so "
        "that it stays there, run in the simulator a frame at a time:</p>",
        "".join(shot_figures),
        "<p>" + (f"The ant was blown up on frame {blown}, the frame the grenade exploded a "
                 "cell short of it. From then on it is drawn as the blast only on the frames "
                 "it skips -- the flicker in frames 10 to 12 -- "
                 if blown else "The ant was not blown up. ")
        + (f"and on frame {went_home} it was back at its home in the nest."
           if went_home else "and it had not gone home within 30 frames.") + "</p>",

        "<h3>What is confirmed and what is inferred</h3>",
        "<ul>"
        "<li>Confirmed by running, on staged scenes in the simulator: the range of each "
        "key, the ammunition, the re-throw while held, the paths over walls and ledges, and "
        "every row of the table of people.</li>"
        "<li>Read from the code: the key bits, the order of the checks, the explosion "
        "frames and the home position; the messages are the scripts HANDLE_EVENTS runs "
        '(see <a href="Scripts.html">the scripts</a>).</li>'
        "<li>Nothing here is inferred, except that the missing arc and the danger to the "
        "thrower were meant: they follow from the code as it is.</li>"
        "</ul>",
    ])


# --------------------------------------------------------------------------
# Finding and rescuing.
# --------------------------------------------------------------------------

VARS_ADDR = 23627           # the ROM's VARS and E_LINE system variables
E_LINE = 23641
ERR_NR = 23610              # the ROM's error number, report code less one
ERR_SP = 23613
PPC = 23621                 # the line and statement BASIC is on
SUBPPC = 23623
STKEND = 23653
RESTART = 0x97A0            # RESTART_BASIC, where INTERRUPT sends an error
FOUND_SCRIPT_DONE = 0x8FCB  # MOVE_RESCUEE, back from script 12
RESCUED_SCRIPT_DONE = 0x8EBD    # CHECK_RESCUED, back from its script
SCANNER_ATTRIBUTE = 0x5A5A  # the first attribute SCANNER colours
GREEN, RED = 4, 2           # its two colours (SCANNER's operands)
WAIT_KEY = 0x8097


def _number(data) -> float:
    """A number in the ROM's five-byte form."""
    if data[0] == 0:
        value = data[2] | data[3] << 8
        return value - 65536 if data[1] == 0xFF else value
    mantissa = (data[1] | 0x80) << 24 | data[2] << 16 | data[3] << 8 | data[4]
    value = mantissa / 2 ** 32 * 2 ** (data[0] - 128)
    return -value if data[1] & 0x80 else value


def basic_variables(memory) -> dict:
    """BASIC's numeric variables: name -> (address of the value, value)."""
    address = memory[VARS_ADDR] | memory[VARS_ADDR + 1] << 8
    end = memory[E_LINE] | memory[E_LINE + 1] << 8
    found = {}
    while address < end and memory[address] != 0x80:
        kind, letter = memory[address] >> 5, chr((memory[address] & 0x1F) + 0x60)
        if kind == 3:                           # a one-letter number
            found[letter] = (address + 1, _number(memory[address + 1:address + 6]))
            address += 6
        elif kind == 5:                         # a number with a longer name
            name, address = letter, address + 1
            while not memory[address] & 0x80:
                name += chr(memory[address])
                address += 1
            name += chr(memory[address] & 0x7F)
            found[name] = (address + 1, _number(memory[address + 1:address + 6]))
            address += 6
        elif kind == 7:                         # a FOR control variable
            found[letter] = (address + 1, _number(memory[address + 1:address + 6]))
            address += 19
        else:                                   # strings and arrays: skip
            address += 3 + (memory[address + 1] | memory[address + 2] << 8)
    return found


def run_basic(game: Game, stop: int, keys=(), seconds: float = 40.0) -> None:
    """Let BASIC run, with interrupts, until PC reaches `stop`."""
    from skoolkit.simutils import PC, T

    game.tracer.keys = set(keys)
    game.sim.trace(game.sim.registers[PC], stop, 0,
                   game.sim.registers[T] + int(seconds * ba.TSTATES_PER_SECOND),
                   True, None, None, None, None, None)
    if game.sim.registers[PC] != stop:
        raise RuntimeError(f"BASIC stopped at ${game.sim.registers[PC]:04X}, not ${stop:04X}")


def grid_distance(a, b) -> int:
    """DISTANCE's answer for two cells: the x and y differences, each taken
    as an 8-bit signed number, so that $FF and $00 are neighbours."""
    total = 0
    for k in range(2):
        difference = (a[k] - b[k]) & 0xFF
        total += 256 - difference if difference & 0x80 else difference
    return total


def _blocked_ahead(memory, record) -> bool:
    x, y, height, facing = (memory[record + X], memory[record + Y], memory[record + HEIGHT],
                            memory[record + FACING] & 3)
    dx, dy = [(0, 1), (1, 0), (0, -1), (-1, 0)][facing]
    nx, ny = (x + dx) & 0xFF, (y + dy) & 0xFF
    if nx < 0x80 or ny < 0x80 or height > 5:
        return False
    return bool(memory[cell_address(nx, ny)] >> height & 1)


def _steer(memory, facing: int, jump_when_blocked: bool = True) -> list[str]:
    """The keys a player would press this frame to face `facing` and walk,
    jumping when the way ahead is blocked. Turning comes first: SYMBOL SHIFT
    turns one way, M the other, a quarter a frame."""
    now = memory[PLAYER + FACING] & 3
    turn = (facing - now) & 3
    if turn == 1 or turn == 2:
        return ["m"]
    if turn == 3:
        return ["SS"]
    keys = ["v"]
    if jump_when_blocked and _blocked_ahead(memory, PLAYER):
        keys.append("c")
    return keys


# The scripted player's plan for level 1, by phase: (what, the test that ends
# it). The keys each frame come from _steer, reading the game's memory: the
# player is steered, not replayed, so the plan survives the ants getting in
# the way.
LEVEL1_GATE_X = 0xB6        # the column of the low wall beside the gate
LEVEL1_STOP_Y = 0xF4        # a cell short of the wall she waits on


def scripted_rescue(snapshot: Path, rescues_before: int | None = None, strict: bool = True):
    """Play level 1 from its first frame to the rescue, steering the player
    by the keys, and on into BASIC's score card. The log has a line per
    frame. With `rescues_before`, BASIC's count of rescues, sg, is set to it
    as PLAY hands back to BASIC -- after this rescue, before line 90 counts
    it -- so that BASIC goes on as if that many had been made before."""
    game = level_start(snapshot)
    target = (game.memory[RESCUEE + X], game.memory[RESCUEE + Y], game.memory[RESCUEE + HEIGHT])
    frames, phase, found_screen, rescued_screen = [], 0, None, None
    phases = {}
    time_start = game.memory[TIME] << 8 | game.memory[TIME + 1]
    for frame in range(1, 400):
        m = game.memory
        px, py, ph = m[PLAYER + X], m[PLAYER + Y], m[PLAYER + HEIGHT]
        if phase == 0 and px == LEVEL1_GATE_X:
            phase = 1
        if phase == 1 and py == LEVEL1_STOP_Y and ph == 0 and not m[PLAYER + FALLING] \
                and not m[PLAYER + STUN]:
            phase = 2
        if phase == 2 and m[RESCUEE + STATE] == 1:
            phase = 3
        phases.setdefault(phase, frame)
        if phase == 0:
            keys = _steer(m, 3, False)
        elif phase == 1:
            keys = _steer(m, 2)
        elif phase == 2:
            keys = ["c"]
        else:
            # Lead her out, waiting whenever she drops four cells behind: she
            # stops for good at six (FOLLOW_PLAYER).
            behind = grid_distance((px, py), (m[RESCUEE + X], m[RESCUEE + Y]))
            keys = _steer(m, 0) if behind < 4 else []
        game.tracer.keys = set(keys)
        # Stop where the two scripts have just been shown, to keep the screen.
        game.until(MOVE_RESCUEE, keys)
        state_before = m[RESCUEE + STATE]
        game.until(0x8E86)                          # back from MOVE_RESCUEE
        if state_before == 0 and m[RESCUEE + STATE] == 1:
            found_screen = bytes(m)
        scanner = m[SCANNER_ATTRIBUTE]
        game.until(AFTER_DRAW)
        entry = {"frame": frame, "phase": phase, "keys": keys,
                 PLAYER: game.record(PLAYER), RESCUEE: game.record(RESCUEE),
                 "scanner": scanner, "picture": play_area(m),
                 "origin": (m[VIEW_ORIGIN], m[VIEW_ORIGIN + 1], m[VIEW]),
                 "time": m[TIME] << 8 | m[TIME + 1],
                 "energy": (m[PLAYER_ENERGY + 1], m[RESCUEE_ENERGY + 1])}
        game.until(0x801A)                          # back from CHECK_RESCUED
        if m[RESCUEE + STATE] == 2 and rescued_screen is None:
            rescued_screen = bytes(m)
            entry["rescued"] = True
        frames.append(entry)
        if not game.frame():
            break
    else:
        if strict:
            raise RuntimeError("the scripted rescue did not finish")
        return {"frames": frames, "phases": phases}
    time_left = frames[-1]["time"]
    if rescues_before is not None:
        address, _ = basic_variables(game.memory)["sg"]
        game.memory[address:address + 5] = bytes([0, 0, rescues_before, 0, 0])
    # On into BASIC: the score card waits for a key.
    run_basic(game, WAIT_KEY, seconds=120.0)
    card = bytes(game.memory)
    variables = {name: value for name, (_, value) in basic_variables(game.memory).items()}
    return {"frames": frames, "phases": phases, "target": target, "found": found_screen,
            "rescued": rescued_screen, "card": card, "variables": variables,
            "time_start": time_start, "time_left": time_left,
            "next_place": tuple(game.memory[RESCUEE:RESCUEE + 3]), "game": game}


def tenth_rescue(snapshot: Path) -> dict:
    """The ending, reached with as little staging as possible.

    Level 1 is played for real (scripted_rescue); as PLAY hands back, BASIC's
    count of rescues is set to 8, so line 90 makes it 9 and BASIC sets up
    level 10 itself -- its story card, its place, its score card -- with every
    variable a real tenth level has. Level 10 is started by pressing keys as
    before; then the rescue itself is staged, as build_antattack's session
    for the ending does: the player put beside the person to be found, then
    both put outside the walls. BASIC then counts the tenth rescue and runs
    the ending. Its outcome is read two ways, on two copies of the machine:
    whether it reaches the ending's wait for a key, and whether an error
    restarts the game (INTERRUPT sends any BASIC error to RESTART_BASIC)."""
    run = scripted_rescue(snapshot, rescues_before=8)
    game = run["game"]
    level10 = tuple(game.memory[RESCUEE:RESCUEE + 3])
    run_basic(game, WAIT_KEY + 8, ["SPACE"])            # past the score card
    run_basic(game, WAIT_KEY, [])                       # the prompt to start
    run_basic(game, PLAY_LOOP, ["v"])
    game.tracer.keys = set()
    ba._beside_rescuee(game.memory)
    for _ in range(20):
        game.frame()
        if game.memory[RESCUEE + STATE] == 1:
            break
    else:
        raise RuntimeError("the staged tenth rescue did not find anyone")
    ba._both_outside(game.memory)
    for _ in range(20):
        if not game.frame():
            break
    else:
        raise RuntimeError("the staged tenth rescue did not end the level")
    result = {"card": run["card"], "place": level10}
    ending, error = game.copy(), game.copy()
    try:
        run_basic(error, RESTART, seconds=90.0)
        result["error"] = (error.memory[ERR_NR], error.memory[PPC] | error.memory[PPC + 1] << 8,
                           error.memory[SUBPPC])
        result["error_screen"] = bytes(error.memory)
        result["free"] = ((error.memory[ERR_SP] | error.memory[ERR_SP + 1] << 8)
                          - (error.memory[STKEND] | error.memory[STKEND + 1] << 8))
    except RuntimeError:
        result["error"] = None
    try:
        run_basic(ending, WAIT_KEY, seconds=90.0)
        result["ending"] = bytes(ending.memory)
    except RuntimeError:
        result["ending"] = None
    return result


def _place_view(base: Game, x: int, y: int, height: int):
    """The game's view of a place where someone waits: the rescued person put
    there as BASIC puts her, lying, the view centred on her."""
    g = base.copy()
    g.place(PLAYER, 0x40, 0x40, 0)
    g.place(RESCUEE, x, y, height)
    g.memory[RESCUEE + STATE] = 0
    g.memory[RESCUEE + ANIM] = 3
    g.look_at(0, x, y)
    g.call(DRAW_VIEW)
    sx, sy = screen_position(x, y, height, (g.memory[VIEW_ORIGIN], g.memory[VIEW_ORIGIN + 1], 0))
    return crop_around(play_area(g.memory), sx + 8, sy + 8, 96, 64)


def _rescue_page(snapshot: Path, image_dir: Path, link, log) -> str:
    from PIL import Image

    log("  playing level 1 to a rescue...")
    levels = ba.read_levels(snapshot)
    run = scripted_rescue(snapshot)
    frames = run["frames"]
    vars_after = run["variables"]
    tx, ty, th = run["target"]

    # 1. Every place, drawn by the game.
    sp = SetPiece(snapshot)
    place_rows = []
    for level in levels:
        cells = []
        for index, (x, y, height) in enumerate(level["spots"]):
            name = f"rescue_place{level['level']:02d}_{index}.png"
            picture = save(_place_view(sp.base, x, y, height), image_dir, name)
            alt = f"Level {level['level']}, place {index + 1}"
            cells.append(img(name, picture, alt, 2, shrink=False) + "<br>"
                         + _fmt_cell(x, y, height))
        cells += [""] * (4 - len(cells))
        place_rows.append([str(level["level"])] + cells)

    # 2. The run, phase by phase.
    phase_names = ["Walk along the outside of the wall to its low stretch",
                   "Over the low wall and up to the wall she waits on",
                   "Jump, to be at her height",
                   "Lead her out: back over the wall and away from the city"]
    phase_rows = []
    first_frames = sorted(run["phases"].items())
    for index, (phase, start) in enumerate(first_frames):
        end = first_frames[index + 1][1] - 1 if index + 1 < len(first_frames) else frames[-1]["frame"]
        phase_rows.append([phase_names[phase], f"{start} to {end}"])
    found_frame = next(e["frame"] for e in frames if e[RESCUEE][STATE] == 1)
    rescued_frame = next(e["frame"] for e in frames if e.get("rescued"))
    scanner_rows = []
    for e in frames:
        if e["phase"] in (1, 2) or e["frame"] == found_frame:
            p, r = e[PLAYER], e[RESCUEE]
            distance = grid_distance(p, r)
            colour = {GREEN: "green", RED: "red"}.get(e["scanner"], f"${e['scanner']:02X}")
            scanner_rows.append([str(e["frame"]), _fmt_cell(p[X], p[Y], p[HEIGHT]), str(distance),
                                 colour, "found" if e["frame"] == found_frame else ""])
    scanner_rows = scanner_rows[-12:]
    follow_rows = []
    for e in frames:
        if e["phase"] == 3:
            p, r = e[PLAYER], e[RESCUEE]
            distance = grid_distance(p, r)
            walking = "walking" if r[FLAGS] & 4 else "standing"
            follow_rows.append([str(e["frame"]), _fmt_cell(p[X], p[Y], p[HEIGHT]),
                                _fmt_cell(r[X], r[Y], r[HEIGHT]), str(distance), walking])

    # Pictures: the path, the moments.
    path_p = [(e[PLAYER][X], e[PLAYER][Y]) for e in frames if e[PLAYER][Y] >= 0x80]
    path_r = [(e[RESCUEE][X], e[RESCUEE][Y]) for e in frames if e[RESCUEE][Y] >= 0x80]
    level_start_game = level_start(snapshot)
    above = from_above(level_start_game.memory, tx - 8, ty - 3, 17, 13, 16,
                       marks=[(tx, ty, (190, 0, 190))], path=path_p)
    pixels_path = from_above(level_start_game.memory, tx - 8, ty - 3, 17, 13, 16, path=path_r)
    above = Image.blend(above, pixels_path, 0.35)
    above_pic = save(above, image_dir, "rescue_path.png")
    found_pic = save(play_area(run["found"]), image_dir, "rescue_found.png")
    rescued_pic = save(play_area(run["rescued"]), image_dir, "rescue_out.png")
    card_pic = save(screen_image(run["card"]), image_dir, "rescue_card.png")
    scan_pics = []
    for colour, what in ((GREEN, "green"), (RED, "red")):
        entry = next(e for e in frames if e["scanner"] == colour and e["phase"] in (0, 1, 2))
        scan_pics.append((what, entry["frame"]))
    crossing = [e for e in frames if e["phase"] == 3][:]
    strip_frames = crossing[::3][:8]
    lead_out = filmstrip(strip_frames, PLAYER, 96, 80)
    lead_pic = save(lead_out, image_dir, "rescue_lead.png")

    # 3. The ending: level 1 again, then BASIC told it was the ninth rescue.
    log("  and on to a tenth rescue and the ending...")
    tenth = tenth_rescue(snapshot)
    tenth_card = save(screen_image(tenth["card"]), image_dir, "rescue_card9.png")
    if tenth["ending"] is not None:
        ending_pic = save(screen_image(tenth["ending"]), image_dir, "rescue_ending.png")
        ending_figure = figure("rescue_ending.png", ending_pic,
                               "The ending, as BASIC leaves it waiting for a key.", scale=2)
    else:
        ending_figure = "<p><b>The ending did not reach its wait for a key in this build.</b></p>"
    if tenth["error"]:
        number, line, statement = tenth["error"]
        error_text = (f" A BASIC error was seen on the way: report code {number + 1} at line "
                      f"{line}, statement {statement}, which INTERRUPT turns into a restart.")
    else:
        error_text = " No BASIC error occurred on the way."

    time_used = run["time_start"] - run["time_left"]
    frames_played = frames[-1]["frame"]
    score = vars_after.get("se")
    tim = vars_after.get("tim")
    r_value = vars_after.get("r")
    spots2 = levels[1]["spots"]
    chosen = spots2.index(run["next_place"]) if run["next_place"] in spots2 else None

    return "\n".join([
        "<p>Each level someone is waiting in the city, and the level is won by finding them "
        "and bringing them out. This page follows that through the code: where they wait, "
        "how they are found, how they follow, what counts as out, and what the clock, the "
        "energy and the score make of it. The worked example is a real game -- level 1 "
        "played from its first frame by a scripted player who presses the keys, in the "
        "simulator, and on into BASIC's score card.</p>",

        "<h3>Where they wait</h3>",
        "<p>The places are BASIC's: the DATA on the line after each level's story card "
        "(1001 to 1091). Line 800 reads them into the rescued person's record, x, y and "
        f"height, at {link(RESCUEE)}. Level 1 has one place; every later level has four, and line "
        "850 picks one by the clock: <code>r</code> is the time left when the last person "
        "was brought out, MOD 4, and line 860 skips that many places. A failed attempt does "
        "not change <code>r</code>, so the place stays the same until the next rescue. "
        f"Each place, drawn by the game's own {link(DRAW_VIEW)} with the person lying there as BASIC "
        'leaves them (see <a href="Levels.html">the levels</a> for the story cards):</p>',
        table(["Level", "Time MOD 4 = 0", "1", "2", "3"], place_rows),
        f"<p>While waiting, the person is never moved: {link(MOVE_RESCUEE)} only measures the "
        "distance to the player. So they do not fall, cannot be bitten, and lie still -- "
        "BASIC starts them with the lying-down picture and a stun of four frames, which "
        "nothing counts down until they are found.</p>",

        "<h3>Finding them</h3>",
        f"<p>Every frame, {link(MOVE_RESCUEE)} takes the player's distance ({link(DISTANCE)}, "
        f"along the grid) and compares it with last frame's, kept at +$0E; {link(SCANNER)} "
        "colours the SCAN box on the panel green if it is smaller and red if not. That is "
        "the only guidance the game gives. When the distance is under four and the two are "
        "at the same height, they are found: +$0D becomes 1, "
        f"{say(12, first_line=True)} plays (script 12), and from the next frame they follow. The "
        "height must match exactly -- standing below them on the ground a cell away does "
        "not count.</p>",
        f"<p>In the run, the girl waits at {_fmt_cell(tx, ty, th)}, on top of a wall one "
        "block high a little way inside the gate. The player walked in along the outside of "
        "the city wall, over its low stretch, up to the foot of her wall, and jumped. The "
        "last frames before the find:</p>",
        table(["Frame", "The player", "Distance", "Scanner", ""], scanner_rows),
        figure("rescue_found.png", found_pic,
               f"Frame {found_frame}, as {say(12, first_line=True)} finished: the message is "
               "printed over the play area, and the next frame's picture covers it."),

        "<h3>Following</h3>",
        f"<p>Once found, the person runs the same routines as everything else, every frame: "
        f"{link(SHARE_CELL)}, then {link(FOLLOW_PLAYER)} to choose, {link(MOVE_OR_RESPAWN)} "
        f"to move and {link(CHOOSE_FRAME)} for the picture. FOLLOW_PLAYER sets the walk bit "
        "while they are two to five cells from the player and clears it at one cell (beside "
        "him) or six or more (left behind: they stop and wait to be fetched). They keep "
        "their facing if one more step along it would end beside the player, and otherwise "
        f"turn towards him ({link(DIRECTION_TO)}). They have bit 4, so they step up a single "
        "block by themselves, but they cannot jump: a wall two blocks high stops them. In the "
        "player's own cell, "
        f"{link(ON_TOP)} decides: on top of him they walk on, under him they stop. Walking "
        'is at the player\'s speed, a cell a frame (see <a href="Movement.html">how people '
        "move</a>).</p>",
        "<p>Leading her out of the run, frame by frame:</p>",
        table(["Frame", "The player", "The girl", "Distance", "She is"], follow_rows),
        figure("rescue_lead.png", lead_pic,
               "Every third frame of leading her out, from the find to the gate."),
        figure("rescue_path.png", above_pic,
               "The run from above, x across and y down: the player's path darkening as it "
               "goes, the girl's fainter; she waited at the purple dot.", scale=1),

        "<h3>Out of the city</h3>",
        f"<p>{link(CHECK_RESCUED)} runs after every frame. The city is x and y from $80 to "
        "$FF; the player is outside if x or y has bit 7 clear, and the same for the person "
        "following. When both are outside -- anywhere outside, and together or not -- +$0D "
        f"becomes 2 (BASIC's <code>w</code>), {say(13)} plays (script "
        f"13), and {link(FRAMES_LEFT)} is set to 1, so PLAY goes back to BASIC after this "
        "frame. Coordinates wrap, so the gate side of the city, at y $FF, is next to y $00, "
        "already outside. The person has to be two cells behind the player to be walking, "
        "so the player has to go a couple of cells further out than they do.</p>",
        f"<p>In the run the rescue came on frame {rescued_frame}:</p>",
        figure("rescue_out.png", rescued_pic, f"As {say(13)} finished."),

        "<h3>Time and energy</h3>",
        "<p>The time is set to 1001 when a level starts (line 750) and "
        f"{link(COUNT_DOWN_TIME)} takes one off every third frame, so a level has 3003 frames: "
        "about eight minutes at the six or seven frames a second the drawing allows (see "
        '<a href="Drawing.html">how a scene is drawn</a>). In the run it went from '
        f"{run['time_start']} to {run['time_left']} in {frames_played} frames "
        f"({time_used} ticks). {link(CHECK_GAME_OVER)} stops play when the time or either "
        "energy reaches 0. Energy is 20 each, a bite costs one and a grenade all of it "
        '(see <a href="Ants.html">the ants</a> and <a href="Grenades.html">the '
        "grenade</a>). Running out of energy only ends the attempt: BASIC says "
        f"{say('another go')}, resets the records, the energies and the grenades, "
        "and starts the same level again -- but not the time, which carries on from where "
        f"it was. Running out of time ends the game (line 60): {say('out of time')}, the "
        "score, and back to the title.</p>",

        "<h3>The score, and the next place</h3>",
        "<p>After a rescue BASIC's line 90 adds one to <code>sg</code>, the people saved, and "
        "adds the time left times <code>sg</code> to the score <code>se</code>: the second "
        "rescue is worth twice its time, the tenth ten times. So speed pays more and more. "
        "Then line 20 starts the next level: the clock back to 1001, the next place chosen "
        "(above), and the score card. From the run, BASIC's variables at the score card: "
        f"<code>sg</code> {vars_after.get('sg'):g}, <code>tim</code> {tim:g}, "
        f"<code>se</code> {score:g} (= {tim:g} &times; 1), and <code>r</code> "
        f"{r_value:g} (= {tim:g} MOD 4), so level 2 has the person at "
        f"{_fmt_cell(*run['next_place'])}"
        + (f", its place {chosen + 1} of four." if chosen is not None else ".")
        + "</p>",
        figure("rescue_card.png", card_pic, "The score card BASIC showed after the run.",
               scale=2),
        "<p>Line 90 also makes the ants faster from the fourth rescue on (see "
        '<a href="Ants.html">the ants</a>).</p>',

        "<h3>The end</h3>",
        "<p>When <code>sg</code> reaches <code>fin</code>, which line 10 sets to 10, line 95 "
        f"runs the ending instead of another level: line 3600 clears the screen and calls "
        f"{link(FINAL_SCRIPT)} (USR 36594), which plays script 17, then BASIC draws its "
        "medal with CIRCLE and prints the total, waits, and asks for a key for a new game. "
        "The ten places are all the game has.</p>",
        "<p>To see it without playing ten levels, the run above was repeated with one "
        f"change: as {link(PLAY)} handed back to BASIC after the level-1 rescue, <code>sg</code> was "
        "set to 8, so that line 90 counted the rescue as the ninth. BASIC then set up level "
        "10 by itself -- its story card, its place, chosen by the time left as always, "
        f"{_fmt_cell(*tenth['place'])} -- and showed the score card for nine; level 10 was "
        "started with the keys, and only its rescue was staged, by putting the player beside "
        "the person waiting and then both outside the walls. BASIC counted the tenth rescue "
        "and ran the ending." + error_text + " The score is the level-1 rescue's time times "
        "nine, plus the staged rescue's times ten.</p>",
        figure("rescue_card9.png", tenth_card, "The score card after the &ldquo;ninth&rdquo; "
                                               "rescue.", scale=2),
        ending_figure,
        "<p>A word of warning for anyone staging it differently: the game's BASIC fills memory "
        "almost to the machine stack, and the medal's CIRCLEs need what little is left. With "
        "<code>fin</code> set to 1 instead, so that the level-1 rescue itself is the last, "
        "the story card string <code>c$</code> still holds level 1's text, the longest, and "
        "line 3610 ran out of memory in the simulator while this page was being written -- "
        f"which {link(0x9797)} answers by restarting the game. The real tenth rescue has level 10's "
        "shorter text there, and as above it gets through.</p>",

        "<h3>What is confirmed and what is inferred</h3>",
        "<ul>"
        "<li>Confirmed by running: the whole of level 1, from the first frame to the score "
        "card, played in the simulator by pressing keys -- the finding, the scanner, the "
        "following, the rescue, the clock and the score, and the place chosen for level "
        "2. The places' pictures are the game's own drawing of each.</li>"
        "<li>Staged: only the way to the ending -- the count of rescues set to 8 after a real "
        "first rescue, and level 10's rescue itself.</li>"
        "<li>Read from the code and the BASIC: the rules for following, the timing of the "
        "clock, what a failed attempt resets, and the game over on time.</li>"
        "</ul>",
    ])


# --------------------------------------------------------------------------

PAGES = [
    ("Drawing", "How a scene is drawn", "_drawing_page"),
    ("Movement", "How people move", "_movement_page"),
    ("Ants", "How the ants hunt", "_ants_page"),
    ("Grenades", "How a grenade flies", "_grenades_page"),
    ("Rescue", "Finding and rescuing", "_rescue_page"),
]


def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    """Draw the pictures into html_dir/images/howitworks and return the
    pages' HTML by ref section name."""
    snapshot = Path(snapshot)
    image_dir = Path(html_dir) / IMAGE_DIR
    image_dir.mkdir(parents=True, exist_ok=True)
    link = Links(snapshot.with_name("antattack.skool"))
    load_texts(snapshot)
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
