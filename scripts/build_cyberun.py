"""Disassemble Cyberun (1986, Ultimate Play the Game) from its tape.

THE TAPE. Three files, each a header and a data block, all at the ROM's
speed: a BASIC loader "CYBER", "PIC" (CODE 24576,6990) and "CY" (CODE
24192,40300). The BASIC loads PIC and calls it at 24576, then loads CY and
calls 23424 ($5B80).

PIC's first job is to copy a 16-byte routine to $FC00. The entry at $5B80
sets the stack to $FE00, calls that routine -- which moves the 40K game
block down from $5E80 to $5C80 -- and then walks down the block from $FA00
with RRD, which moves every byte's nibbles along by one: the tape holds the
game four bits out of step. Then it jumps to $5C80, which is DI and JP
$9A66, the game's own start.

tap2sna runs the ROM's own LOAD, PIC and the entry on a simulated machine
and stops at $5C80, after the decoding and before the game has run an
instruction of its own. The disassembly is of that image: the game as it
runs, not as it lies on the tape.

WHAT IS DISASSEMBLED: $5B00 to the top of memory. Below the game, from
$5B00, are the entry routine (in the printer buffer, where the BASIC's
USR 23424 finds it) and the game's work areas; above it, the copy routine
PIC left at $FC00 and the stack the entry set up under $FE00.

SEPARATING CODE FROM DATA the way the Alien 8 and Pentagram builds do: play
the game in SkoolKit's simulator from $5C80 and record every address
executed, in sessions that pick each control method and fly, fire, take
hits, run out of fuel, die and lose the game; then follow the branches out
of what ran (scripts/codemap.py), which invents nothing. See
build_aticatac.py for why that is the safe direction to be wrong in, and
why the round trip at the end cannot catch data dressed as code.

The game and everything built from it is copyrighted ((c) 1986 Ultimate
Play the Game). Built locally, gitignored, never committed. See README.md.

Usage:
    python scripts/build_cyberun.py --tape "path/to/Cyberun.tzx" [--html]
"""
from __future__ import annotations

import argparse
import bisect
import contextlib
import functools
import io
import re
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

PROJECT_ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = PROJECT_ROOT / "game_disassembly" / "cyberun"
# Hand-written comments, layered over the generated control file. Source, not
# output: addresses and prose only, so it is committed.
ANNOTATIONS = PROJECT_ROOT / "scripts" / "cyberun_annotations.ctl"
REF = PROJECT_ROOT / "scripts" / "cyberun.ref"
ROM = PROJECT_ROOT / "roms" / "48.rom"
SJASMPLUS = PROJECT_ROOT / "tools" / "sjasmplus" / "sjasmplus.exe"

# Where the entry jumps once the block is decoded, and where tap2sna stops.
ENTRY = 0x5C80
# The disassembly: the entry and work areas below the game, the game, and
# PIC's routine and the stack above it.
BLOCK_START = 0x5B00
BLOCK_END = 0x10000
# The game as the entry leaves it: moved down to $5C80 and decoded up to
# $FA00 (the RRD walks down from there).
LOADED_START = 0x5C80
LOADED_END = 0xFA00
# The code, for following branches.
DESCENT_START = 0x5C80
DESCENT_END = 0xFA00

TSTATES_PER_SECOND = 3500000
NEWLINE = chr(10)

# The sprite compositor's table of entry points into its row loops: eleven
# for erasing and eleven for drawing, one per width.
ROW_LOOPS = 0xA294
ROW_LOOP_COUNT = 22
# The update routine for each object type: a word each, read at $A195.
# Slot 8 (type $1B) points at a graphic list, not code.
TYPE_HANDLERS = 0xAF25
TYPE_HANDLER_COUNT = 12
TYPE_1B_SLOT = 8

# Code reached only from code the sessions never ran, or through an
# instruction the game patches: the instruction that reaches it, and where.
READ_EDGES = {
    0xA3CA: 0xA3CF,     # DJNZ, displacement patched at $A3B6: the first LDI of the copy chain
    0x930E: 0x92B4,     # CALL Z: find a missile's target
    0xC088: 0xC10E,     # CALL: is a star in sight (stars only live in map rows 0-3)
    0x88C1: 0x8970,     # JP Z: the spray for shot kind 6
    0x9CC4: 0x9D30,     # CALL: draw the special beam
    0x9CBD: 0x9D53,     # CALL: place the special beam
    0xB0E2: 0xB0E5,     # JR: an add-on's mask and picture into the ship's buffer
    0xB0D9: 0xB0F8,     # JR Z: the same, its draw loop
    0xB8B2: 0xB8DB,     # JP: expand a special-beam frame
    0xBD15: 0xBD17,     # JR, displacement patched to 0 or 3: the CALL it switches on
    0xBD2A: 0xBD2C,     # the same
    0xBD73: 0xBD75,     # the same
    0xBD84: 0xBD86,     # the same
    0xD47F: 0xD481,     # JR, displacement patched to 0 or 1 at $D426/$D432: DEC A, or past it
    0xD480: 0xD482,     #   (keyed on the displacement byte, the JR's other landing)
    # The landscape's dispatch: the JR at $D701, displacement patched to 0,
    # 2, 5, 8 or 11, lands on JP (IY) (the full blitter) or one of four
    # jumps to the clipping blitters at the play area's edges.
    0xD701: 0xD703,
    0xD702: 0xD705,     #   (keyed on the displacement byte: the other landings)
    0xD704: 0xD708,
    0xD706: 0xD70B,
    0xD707: 0xD70E,
    # Inside the clipping blitters, the landings of their own patched JRs,
    # read with each one's patching code.
    0xDB92: 0xDBB1,
    0xDB93: 0xDBB2,
    0xDB94: 0xDBB3,
    0xDBC1: 0xDBF3,
    0xDBC6: 0xDBF7,
    0xDC0B: 0xDC0D,
    0xDC0C: 0xDC0E,
    0xDC39: 0xDC3B,
    0xDC3D: 0xDC3F,
    0xDC53: 0xDC55,
    0xDC7F: 0xDC81,
    0xDC80: 0xDC82,
}

# The four landscape shift tables (shifts 0, 2, 4, 6): 16 entries of two
# words each, a blitter entry point (jumped to through IY) and the step's
# graphic. The entry points are edges, like a jump table's.
SHIFT_TABLES = (0xE37D, 0xE2BD, 0xE2FD, 0xE33D)
SHIFT_TABLE_ENTRIES = 16


def _log(message: str) -> None:
    print(message, flush=True)


@functools.lru_cache(maxsize=None)
def _read_snapshot(path: str) -> tuple:
    from skoolkit.snapshot import Snapshot

    return tuple(Snapshot.get(path).memory)


def game_memory(snapshot: Path) -> tuple:
    """The snapshot's 64K, read once and shared. Read-only."""
    return _read_snapshot(str(snapshot))


def _word(memory, address: int) -> int:
    return memory[address] | memory[address + 1] << 8


# --------------------------------------------------------------------------
# Step 1: load the tape.
# --------------------------------------------------------------------------

def make_snapshot(tape: Path, out: Path) -> None:
    """Simulate the real LOAD, PIC and the entry, stopping at $5C80."""
    from skoolkit import tap2sna

    _log(f"Loading {tape.name} (simulated LOAD)...")
    # as_uri: tap2sna reads its input as a URL, and C:\ would be scheme "c".
    with contextlib.redirect_stdout(io.StringIO()):
        tap2sna.main(["--start", str(ENTRY), tape.resolve().as_uri(), str(out)])
    if not out.exists():
        sys.exit(f"error: tap2sna did not write {out}")


# --------------------------------------------------------------------------
# Step 2: play the game to find out which addresses are code.
# --------------------------------------------------------------------------

# The variables the sessions read and write. See the annotations for each.
MENU_LOOP = 0x8615          # the menu's loop: reached once a pass while it waits,
                            # after the title tune, which any key cuts short
PLAY_LOOP = 0xF46C          # the play loop: reached once a pass of the game
CONTROL_P1 = 0x870A         # the menu's control method for each player:
CONTROL_P2 = 0x870D         # 0 keyboard, 1 Kempston, 2 cursor, 3 Interface II
TWO_PLAYERS = 0xF2E2        # 0 one player, 1 two (keys A and B on the menu)
DYING = 0x8F53              # 0 alive; counts up from 1 through the death
HITS = 0x8FC3               # hits taken; the third kills
FUEL = 0xCC4B               # a word; the high byte $42 full to $BE empty
FUEL_FULL = 0x4200
FUEL_EMPTY = 0xBE00
LIVES = 0xF5ED              # the current player's lives

# Held to cut the title tune short: any key does (it reads every row,
# $9A9A), but SPACE and CAPS SHIFT are also what $9EE3 tests for during
# play, and ENTER only thrusts.
TUNE_KEYS = ["ENTER"]

# Kempston bits, as IN A,($1F) reads them at $B180.
J_RIGHT, J_LEFT, J_DOWN, J_UP, J_FIRE = 1, 2, 4, 8, 16


def _key_tracer_class():
    from skoolkit.kbtracer import KEY_BITS
    from skoolkit.trace import Tracer

    class KeyTracer(Tracer):
        """A Tracer whose read_port reports held keys and a Kempston stick."""

        def __init__(self, simulator):
            super().__init__(simulator, 0, 0, 0, [0] * 16, 0, False)
            self.keys = set()
            self.kempston = 0

        def read_port(self, registers, port):
            if port & 0xFF == 0x1F:     # Kempston joystick
                return self.kempston
            if port & 1:                # not the ULA
                return 0xFF
            result = 0xFF
            for key in self.keys:
                half_row, bits = KEY_BITS[key]
                if port & half_row == 0:
                    result &= bits
            return result

    return KeyTracer


class Until:
    """A session step: hold keys until test(memory) is true, or fail.

    Driving by the game's own state rather than by time, so a script that
    was right once stays right: each step waits for what it means and the
    build stops, saying which, if that never comes.
    """

    def __init__(self, what: str, test, seconds: float = 20.0, keys=(), stick: int = 0):
        self.what, self.test, self.seconds = what, test, seconds
        self.keys, self.stick = keys, stick


class At:
    """A session step: run until the game reaches an address, or fail -- for
    a poke that has to land at a known point in the game's pass rather than
    wherever the simulator happened to stop. Holds `keys` on the way (the
    title tune stops at any key) and releases them on arrival."""

    def __init__(self, what: str, address: int, seconds: float = 20.0, keys=()):
        self.what, self.address, self.seconds, self.keys = what, address, seconds, keys


class Machine:
    """The game on a simulated 48K Spectrum, from the snapshot at $5C80."""

    def __init__(self, snapshot: Path, executed: set | None = None):
        from skoolkit import CSimulator, read_bin_file
        from skoolkit.simulator import Simulator
        from skoolkit.simutils import SP

        memory = list(game_memory(snapshot))
        memory[:0x4000] = read_bin_file(str(ROM))
        self.simulator = (CSimulator or Simulator)(
            memory, state={"iff": 0, "im": 1, "tstates": 0})
        # The game's start sets its own stack; this one only has to be
        # somewhere harmless until then (the entry's own, under $FE00).
        self.simulator.registers[SP] = 0xFE00
        self.tracer = _key_tracer_class()(self.simulator)
        self.simulator.set_tracer(self.tracer)
        self.pc = ENTRY
        self.executed = executed

    @property
    def memory(self):
        return self.simulator.memory

    def run(self, seconds: float, keys=(), stick: int = 0) -> None:
        from skoolkit.simutils import PC, T

        self.tracer.keys = set(keys)
        self.tracer.kempston = stick
        simulator = self.simulator
        simulator.trace(self.pc, 0, 0, simulator.registers[T] + int(seconds * TSTATES_PER_SECOND),
                        True, None, self.executed, None, None, None)
        self.pc = simulator.registers[PC]

    def run_to(self, step: At, label: str) -> None:
        from skoolkit.simutils import PC, T

        self.tracer.keys = set(step.keys)
        self.tracer.kempston = 0
        simulator = self.simulator
        simulator.trace(self.pc, step.address, 0,
                        simulator.registers[T] + int(step.seconds * TSTATES_PER_SECOND),
                        True, None, self.executed, None, None, None)
        self.pc = simulator.registers[PC]
        if self.pc != step.address:
            sys.exit(f"error: session {label!r}: ran {step.seconds} s and never reached "
                     f"{step.what} (${step.address:04X}; PC ${self.pc:04X})")
        self.tracer.keys = set()

    def until(self, step: Until, label: str) -> None:
        waited = 0.0
        while not step.test(self.memory):
            if waited >= step.seconds:
                sys.exit(f"error: session {label!r}: waited {step.seconds} s for "
                         f"{step.what}, and it never came (PC ${self.pc:04X})")
            self.run(0.05, step.keys, step.stick)
            waited += 0.05

    def play(self, steps, label: str) -> None:
        for step in steps:
            if isinstance(step, Until):
                self.until(step, label)
            elif isinstance(step, At):
                self.run_to(step, label)
            elif callable(step):
                step(self.memory)
            else:
                keys, seconds = step[0], step[1]
                stick = step[2] if len(step) > 2 else 0
                self.run(seconds, keys, stick)


def _poke(address: int, value: int):
    def poke(memory):
        memory[address] = value
    return poke


def _keep_alive(memory) -> None:
    """Undo the damage and refill the tank, between slices of play: for
    the long tours, where what is being mapped is the landscape and the
    things in it, not dying."""
    memory[HITS] = 0
    memory[FUEL] = FUEL_FULL & 0xFF
    memory[FUEL + 1] = FUEL_FULL >> 8


def _start(control: int = 0, players: int = 1) -> list:
    """From the menu: set player 1's control method, the number of
    players, and press 0; then wait for the first pass of play."""
    return [At("the menu", MENU_LOOP, 120.0, TUNE_KEYS),
            _poke(CONTROL_P1, control), _poke(CONTROL_P2, control),
            _poke(TWO_PLAYERS, players - 1),
            (["0"], 0.2), At("the first pass of play", PLAY_LOOP, 30.0)]


# A round of flying on the keyboard: thrust, steer both ways, fire, the
# number row, and still.
KEYBOARD_ROUND = [
    (["a", "x"], 0.6), (["x"], 1.0), (["x", "q"], 1.0), (["a", "v"], 0.4),
    (["n", "p"], 1.0), (["z", "a"], 0.6), (["z"], 1.0), (["c", "w"], 1.0),
    (["m", "SS"], 0.4), (["b", "l"], 0.4), (["1"], 0.3), ([], 0.6),
    (["k", "x", "e"], 1.0), (["ENTER", "z", "t"], 1.0),
]
STICK_ROUND = [
    ([], 0.3, J_UP | J_RIGHT), ([], 1.0, J_RIGHT), ([], 1.0, J_RIGHT | J_FIRE),
    ([], 0.5, J_DOWN), ([], 1.0, J_LEFT | J_UP), ([], 1.0, J_LEFT | J_FIRE),
    ([], 0.5, 0),
]
# Cursor keys: 5 left, 6 down, 7 up, 8 right, 0 fire (rows $EF and $F7).
CURSOR_ROUND = [
    (["7", "8"], 0.6), (["8"], 1.0), (["8", "0"], 1.0), (["6"], 0.4),
    (["5", "7"], 1.0), (["5", "0"], 1.0), ([], 0.4),
]
# Interface II, player 1: 6 left, 7 right, 8 down, 9 up, 0 fire (row $EF).
SINCLAIR_ROUND = [
    (["9", "7"], 0.6), (["7"], 1.0), (["7", "0"], 1.0), (["8"], 0.4),
    (["6", "9"], 1.0), (["6", "0"], 1.0), ([], 0.4),
]


def _alive(steps: list) -> list:
    """Steps with the damage and the fuel undone between each."""
    out = []
    for step in steps:
        out += [_keep_alive, step]
    return out


def _kill_by_fuel(memory) -> None:
    memory[FUEL] = FUEL_EMPTY & 0xFF
    memory[FUEL + 1] = FUEL_EMPTY >> 8


def _last_life(memory) -> None:
    memory[LIVES] = 1


def _dead_and_back(memory) -> bool:
    return memory[DYING] == 0


# Staging a scene by the game's own restart. At every life start_landscape
# restores the view from three words of the player's record -- the map cell,
# the place in it and the fine scroll -- which save_restart_point keeps up to
# date every fourth pass, death sequence included. So the scene is set by
# writing them at the very end of a death sequence, after the last save:
# the next life then flies in there, with the landscape, the collision lists
# and the objects all built by the game itself.
RESTART_SCROLL = 0xF5FA     # restart_scroll: the view's map column, row
RESTART_VIEW = 0xF5FC       # restart_view: x (bit 0 set: a sky restart), y in the cell
RESTART_FINE = 0xF5FE       # restart_fine: origin_x, origin_y
ADDON_SLOTS = 0xF5EE        # add-on n's slot is $F5EE + n - 1, holding n when fitted
PART_CARRIED = 0xF601       # rocket_part_carried: $FF none
PARTS_BUILT = 0xF602        # parts_built: delivered, also the part due next
ORE = 0xC905                # ore aboard, 18 to fill the tank
LAUNCH = 0x96AB             # launch_state: non-zero while the rocket rises, $FF done
# Where the ship stands inside the rocket, which draw_rocket ($9672) waits
# for: page column $52, x $5C, page row $0A, y $63 or more. The ship sits at
# screen x $60, so the view is a page to the left, $E6 in. Where the fly-in
# leaves the ship across can still differ by a step with the life before it
# (the reference page's trials met x $5E); the build's own sessions are
# deterministic and dock every time, and its Until steps would stop the
# build if they did not.
ROCKET_VIEW = (0x51, 0x0A, 0xE6, 0x18)


def restart_at(column: int, row: int, view_x: int, view_y: int, sky: bool = True,
               pokes: dict | None = None):
    """A step that sets the next life's place (and any other bytes)."""
    def poke(memory):
        memory[RESTART_SCROLL], memory[RESTART_SCROLL + 1] = column, row
        memory[RESTART_VIEW], memory[RESTART_VIEW + 1] = view_x | (1 if sky else 0), view_y
        # The origins are what makes screen = place + origin: x 8, y $B7.
        memory[RESTART_FINE] = (8 - view_x) & 0xFF
        memory[RESTART_FINE + 1] = (0xB7 - view_y) & 0xFF
        for address, value in (pokes or {}).items():
            memory[address] = value
    return poke


def new_life_at(poke) -> list:
    """Empty the tank, and at the end of the death sequence set the scene."""
    return [(["a"], 0.3), _kill_by_fuel,
            # The gauge first runs down a row a pass, then up to 128 passes'
            # grace: more than ten seconds at times.
            Until("a death from empty fuel", lambda m: m[DYING] != 0, 30.0),
            Until("the end of the death sequence", lambda m: m[DYING] >= 0x50, 30.0),
            poke,
            Until("the next ship", _dead_and_back, 30.0)]


def all_addons(memory) -> None:
    for n in range(1, 10):
        memory[ADDON_SLOTS + n - 1] = n


def sessions(snapshot: Path, cycles: int) -> list:
    # The title tune played to its end, once.
    menu = ([At("the menu", MENU_LOOP, 600.0)]
            + [(["a"], 0.5), (["b"], 0.5), (["1"], 0.5), ([], 0.3), (["2"], 0.5), ([], 0.3),
               (["1"], 0.5), ([], 0.3), (["1"], 0.5), ([], 0.3), (["1"], 0.5), ([], 0.3),
               (["a"], 0.5), ([], 4.0)]
            + _start(0) + KEYBOARD_ROUND)
    keyboard = _start(0) + KEYBOARD_ROUND * cycles
    kempston = _start(1) + _alive(STICK_ROUND * cycles)
    cursor = _start(2) + _alive(CURSOR_ROUND * cycles)
    sinclair = _start(3) + _alive(SINCLAIR_ROUND * cycles)
    tour_right = _start(0) + _alive([(["x", "q"], 2.0), (["x", "a", "q"], 0.3)] * (cycles * 6))
    tour_left = _start(0) + _alive([(["z", "q"], 2.0), (["z", "a", "q"], 0.3)] * (cycles * 6))
    fuel = (_start(0) + [(["a", "x"], 0.5), _kill_by_fuel,
                         Until("a death from empty fuel", lambda m: m[DYING] != 0, 10.0),
                         Until("the next ship", _dead_and_back, 30.0)]
            + KEYBOARD_ROUND)
    over = (_start(0) + [(["a", "x"], 0.5), _last_life, _kill_by_fuel,
                         Until("a death from empty fuel", lambda m: m[DYING] != 0, 10.0),
                         At("the menu after the game", MENU_LOOP, 300.0, TUNE_KEYS)]
            + _start(0) + KEYBOARD_ROUND)
    # SPACE and CAPS SHIFT, which $9EE3 tests for, in play.
    breaks = _start(0) + [(["SPACE"], 0.5), ([], 2.0), (["SPACE"], 0.5), ([], 2.0),
                          (["CS"], 0.5), ([], 2.0), (["CS"], 0.5), ([], 2.0)] + KEYBOARD_ROUND
    two = (_start(0, players=2) + KEYBOARD_ROUND * 2
           + [_kill_by_fuel, Until("a death from empty fuel", lambda m: m[DYING] != 0, 10.0),
              Until("the other player's ship", _dead_and_back, 30.0)]
           + KEYBOARD_ROUND * 2)
    # Staged scenes, each a new life put somewhere by the game's own restart
    # (restart_at): what a session of ordinary play would take far too long
    # to reach.
    # The rocket built: the ship starts inside it, docks, and the rocket
    # rises; the planet is secured and the next planet begins.
    launch = (_start(0) + new_life_at(restart_at(*ROCKET_VIEW, pokes={PARTS_BUILT: 8}))
              + [Until("the launch", lambda m: m[LAUNCH] != 0, 10.0),
                 Until("the rocket gone", lambda m: m[LAUNCH] == 0xFF, 60.0),
                 At("the next planet's first pass", PLAY_LOOP, 120.0, TUNE_KEYS)]
              + KEYBOARD_ROUND)
    # A part carried to the rocket with the hook fitted (add-ons 1 and 2):
    # part 0, and the ore tank, part 6, full.
    hook = {ADDON_SLOTS: 1, ADDON_SLOTS + 1: 2}
    deliver_0 = (_start(0) + new_life_at(restart_at(*ROCKET_VIEW, pokes={
                     **hook, PART_CARRIED: 0, PARTS_BUILT: 0}))
                 + [Until("part 0 delivered", lambda m: m[PARTS_BUILT] == 1, 20.0)]
                 + _alive(KEYBOARD_ROUND))
    deliver_6 = (_start(0) + new_life_at(restart_at(*ROCKET_VIEW, pokes={
                     **hook, PART_CARRIED: 6, PARTS_BUILT: 6, ORE: 18}))
                 + [Until("the ore tank delivered", lambda m: m[PARTS_BUILT] == 7, 20.0)]
                 + _alive(KEYBOARD_ROUND))
    # Every add-on fitted: the special beam (the number row, the ship still),
    # missiles with the fire, and the lift jet up towards the stars.
    addons = (_start(0) + new_life_at(all_addons)
              + _alive([([], 1.0), (["1"], 2.0), ([], 1.0), (["1"], 2.0), (["q"], 1.0),
                        (["q", "x"], 2.0), (["a"], 3.0), (["a", "x"], 3.0), (["a"], 6.0),
                        (["a", "z"], 6.0), (["a"], 6.0), ([], 1.0), (["1"], 2.0)] * 2))
    # Tours at five depths, from the stars down to the deepest caverns, for
    # the landscape's clipping and its upside-down and mirrored tiles.
    tours = [(f"tour at map row {row}",
              _start(0) + new_life_at(restart_at(0x20, row, 0x80, 0x60))
              + _alive([(["x", "q"], 2.0), (["x", "a", "q"], 0.4), (["x"], 1.0),
                        (["z", "a"], 0.6)] * 12))
             for row in (3, 12, 16, 20, 22)]
    return [
        ("menu", menu),
        ("keyboard", keyboard),
        ("Kempston", kempston),
        ("cursor", cursor),
        ("Interface II", sinclair),
        ("tour right", tour_right),
        ("tour left", tour_left),
        ("out of fuel", fuel),
        ("game over", over),
        ("two players", two),
        ("SPACE and CAPS SHIFT", breaks),
        ("the launch", launch),
        ("part 0 delivered", deliver_0),
        ("the ore tank delivered", deliver_6),
        ("every add-on", addons),
    ] + tours


def build_code_map(snapshot: Path, out: Path, cycles: int) -> None:
    executed: set[int] = set()
    for label, steps in sessions(snapshot, cycles):
        before = len(executed)
        started = time.time()
        machine = Machine(snapshot, executed)
        machine.play(steps, label)
        _log(f"  {label}: +{len(executed) - before} addresses "
             f"({time.time() - started:.1f} s)")

    ran = {a for a in executed if DESCENT_START <= a < DESCENT_END}
    _log(f"  {len(executed)} addresses executed; {len(ran)} instruction starts "
         f"in the game")
    # What really ran, kept apart from what descent adds to it, so that
    # "has this ever run?" can be answered afterwards.
    executed_map = bytearray(65536)
    for address in ran:
        executed_map[address] = 1
    out.with_name(out.stem + "-executed.map").write_bytes(bytes(executed_map))
    code = extend_by_descent(list(game_memory(snapshot)), ran)

    # SkoolKit reads a 65536-byte map as one byte per address, bit 0 set.
    data = bytearray(65536)
    for address in code:
        data[address] = 1
    out.write_bytes(bytes(data))


def extend_by_descent(memory: list, executed: set[int]) -> set[int]:
    """Follow the game's own branches out from everything that ran.

    The same method as build_alien8.py's (and build_hobbit.py's, which
    says at length why): seeds are addresses a CPU executed, branches are
    only followed out of those, and the CPU's instruction boundaries overrule
    the decoder's wherever they meet.
    """
    import codemap

    # The sprite compositor's entry points into its unrolled erase and draw
    # loops, one word per width (#R$A294, read at $A23C): a jump table is a
    # list of edges, not a guess, and the widest entry of each loop is
    # used by no sprite the sessions met.
    seeds = set(executed) | {_word(memory, ROW_LOOPS + 2 * width)
                             for width in range(ROW_LOOP_COUNT)}
    # And the handlers in the object-type table (#R$AF25, read at $A195),
    # except type $1B's, which points at graphics (see the table's entry).
    seeds |= {_word(memory, TYPE_HANDLERS + 2 * kind) for kind in range(TYPE_HANDLER_COUNT)
              if kind != TYPE_1B_SLOT}
    # And the edges that start in code no session ran. The walk follows
    # branches only out of executed instructions (codemap.walk says why), so
    # a call made from unrun code is not followed; each of these was read,
    # instruction and target, when the range was described.
    seeds |= set(READ_EDGES.values())
    # And the landscape blitters' entry points, from the shift tables.
    seeds |= {_word(memory, table + 4 * entry) for table in SHIFT_TABLES
              for entry in range(SHIFT_TABLE_ENTRIES)}
    forbidden: set[int] = set()
    for _ in range(12):
        code, indirect, _ = codemap.walk(memory, seeds, DESCENT_START, DESCENT_END,
                                         (), forbidden)
        straddling = {a for a in code
                      if any((a + o) & 0xFFFF in executed
                             for o in range(1, codemap.decode(memory, a).length))}
        if not straddling:
            break
        forbidden |= straddling
    if forbidden:
        _log(f"  {len(forbidden)} decoded instruction(s) struck out for "
             f"straddling an address the CPU executed")

    inside, aimed_at = set(), set()
    for address in code:
        instruction = codemap.decode(memory, address)
        aimed_at.update(instruction.targets)
        for offset in range(1, instruction.length):
            inside.add((address + offset) & 0xFFFF)
    disagreed = sorted(executed & inside - aimed_at)
    if disagreed:
        sys.exit(f"error: {len(disagreed)} executed address(es) fall inside a "
                 f"decoded instruction, first at ${disagreed[0]:04X} -- fix "
                 f"codemap.py rather than skipping this check")
    _log(f"  following branches from there: +{len(code - executed)} more "
         f"instruction starts ({len(indirect)} indirect jumps stopped it)")
    return code

# --------------------------------------------------------------------------
# Step 3: map -> control file -> skool -> asm.
# --------------------------------------------------------------------------

def _capture(func, args, warnings: list | None = None) -> str:
    """What a SkoolKit command writes to stdout; its warnings, from stderr,
    appended to `warnings` when given (and otherwise left on the console)."""
    buf, err = io.StringIO(), io.StringIO()
    with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(err):
        func(args)
    if warnings is not None:
        text = err.getvalue()
        # A warning is a WARNING: line and the indented line under it.
        entries = re.split(r"(?m)^(?=WARNING:)", text)
        warnings.extend(entry.strip() for entry in entries if entry.startswith("WARNING"))
    elif err.getvalue():
        sys.stderr.write(err.getvalue())
    return buf.getvalue()


_COMMENT_RE = re.compile(r"^\s{2}\$([0-9A-F]{4})(?:,(\d+))?\s")
_SPAN_RE = re.compile(r"^;\s*span\s+\$([0-9A-F]{4}),(\d+)\s*$")
_BLOCK_RE = re.compile(r"^([bctwsiug]) \$([0-9A-F]{4})")
_SUBBLOCK_RE = re.compile(r"^([BCSTW]) \$([0-9A-F]{4}),(\d+)")
_ANY_DIRECTIVE_RE = re.compile(r"^[bctwsiugBCSTWLMNRDE@] \$([0-9A-F]{4})")


def declared_spans() -> list[tuple[int, int]]:
    """Data-block extents the annotations claim, as `; span $ADDR,LENGTH`.

    sna2ctl starts new blocks in the middle of tables, and a second control
    file can add block boundaries but never remove them; so the generated
    ones inside a declared span are dropped before the two are merged.
    Returned as (start, end), end exclusive.
    """
    if not ANNOTATIONS.exists():
        return []
    spans = []
    for line in ANNOTATIONS.read_text(encoding="utf-8").splitlines():
        match = _SPAN_RE.match(line)
        if match:
            start = int(match.group(1), 16)
            spans.append((start, start + int(match.group(2))))
    return spans


def annotated_entries() -> list[tuple[int, int]]:
    """Every entry the annotations start, from its start to the next one's.

    The annotations are where the entries are decided: each describing pass
    found the real extent of its tables, routines and variables, and sna2ctl's
    guesses -- a table cut into text and data fragments wherever its bytes
    happened to look like letters -- are dropped inside each, as they are
    inside a declared span. Where the annotations start nothing, sna2ctl's
    blocks stand.
    """
    if not ANNOTATIONS.exists():
        return []
    starts = sorted({int(m.group(2), 16)
                     for m in (_BLOCK_RE.match(line) for line in
                               ANNOTATIONS.read_text(encoding="utf-8").splitlines()) if m})
    return [(start, end) for start, end in zip(starts, starts[1:] + [BLOCK_END])]


def _block_type_at(ctl_lines: list[str], address: int) -> str:
    """The type of the sna2ctl block that covers an address."""
    kind = "b"
    for line in ctl_lines:
        match = _BLOCK_RE.match(line)
        if match:
            if int(match.group(2), 16) > address:
                break
            kind = match.group(1)
    return kind


def take_over(ctl_text: str, ranges: list[tuple[int, int]], keep_start: bool) -> str:
    """Drop what sna2ctl says inside each range, and make sure a block starts
    where each range ends, so the bytes after it keep sna2ctl's type.

    With keep_start, a block directive exactly at a range's start survives
    (a declared span keeps sna2ctl's block and its type); without it, the
    generated lines provide the block.
    """
    lines = ctl_text.splitlines()
    kept = []
    for line in lines:
        match = _ANY_DIRECTIVE_RE.match(line)
        if match:
            address = int(match.group(1), 16)
            inside = any((start < address < end) or (address == start and not keep_start)
                         for start, end in ranges)
            if inside:
                continue
        kept.append(line)
    starts = {int(m.group(2), 16) for m in (_BLOCK_RE.match(line) for line in kept) if m}
    for start, end in ranges:
        if end < BLOCK_END and end not in starts:
            kept.append(f"{_block_type_at(lines, end)} ${end:04X}")
    # Back in address order, directives at one address kept together.
    def key(item):
        index, line = item
        match = _ANY_DIRECTIVE_RE.match(line)
        return (int(match.group(1), 16) if match else -1, index)
    ordered = [line for _, line in sorted(enumerate(kept), key=key)
               if _ANY_DIRECTIVE_RE.match(line)]
    header = [line for line in kept if not _ANY_DIRECTIVE_RE.match(line)]
    return NEWLINE.join(header + ordered)


def check_annotations(bare_skool: str) -> None:
    """Stop the build on an instruction comment whose length splits an instruction.

    A `  $ADDR,N` directive whose N does not end on an instruction boundary
    makes sna2skool cut the instruction in two and decode on from the middle
    of it; the listing still reassembles, so nothing later would say so.
    """
    boundaries = {int(m.group(1), 16)
                  for m in (re.match(r"^[bctwsiug ]?\*?\$([0-9A-F]{4})\s", line)
                            for line in bare_skool.split(NEWLINE)) if m}
    boundaries.add(BLOCK_END)
    problems = []
    for number, line in enumerate(ANNOTATIONS.read_text(encoding="utf-8").split(NEWLINE), 1):
        match = _COMMENT_RE.match(line)
        if not match:
            continue
        address = int(match.group(1), 16)
        if address not in boundaries:
            problems.append(f"  {ANNOTATIONS.name}:{number}: ${address:04X} is not the "
                            f"start of an instruction")
            continue
        if match.group(2) is None:
            continue
        end = address + int(match.group(2))
        if end not in boundaries:
            valid = min((b for b in boundaries if b >= end), default=None)
            problems.append(f"  {ANNOTATIONS.name}:{number}: ${address:04X},"
                            f"{match.group(2)} ends mid-instruction"
                            + (f" -- try ,{valid - address}" if valid else ""))
    if problems:
        sys.exit("error: annotation lines that split an instruction:" + NEWLINE
                 + NEWLINE.join(problems))


def check_structure(generated: str, owned: list[tuple[int, int]],
                    spans: list[tuple[int, int]]) -> None:
    """Fail the build if the generated blocks and the spans are not one layout.

    The round trip cannot see any of this: a table sliced into pieces, a
    block whose sub-blocks stop short, two blocks claiming the same bytes all
    still reassemble. So: the ranges cyberun_data.py owns and the spans the
    annotations declare must not overlap; and inside every generated block
    the sub-blocks must run on from one another, with no gap and no overlap,
    to the next block or the end of the range.
    """
    problems = []
    named = [(s, e, "generated") for s, e in owned] + [(s, e, "span") for s, e in spans]
    for s, e, _ in named:
        if e <= s:
            problems.append(f"${s:04X}-${e:04X} ends before it starts (a length, not an end?)")
    ordered = sorted(named)
    for (s1, e1, n1), (s2, _, n2) in zip(ordered, ordered[1:]):
        if s2 < e1:
            problems.append(f"{n1} ${s1:04X}-${e1 - 1:04X} overlaps {n2} at ${s2:04X}")

    ends = sorted(e for _, e in owned)
    block, cursor = None, None
    def close():
        if block is None:
            return
        limit = min((e for s, e in owned if s <= block < e), default=None)
        if cursor != limit and cursor not in starts:
            problems.append(f"the sub-blocks of the block at ${block:04X} stop at "
                            f"${cursor:04X}, short of the next block")
    starts = {int(m.group(2), 16) for m in (_BLOCK_RE.match(line)
                                            for line in generated.splitlines()) if m}
    starts |= set(ends)
    for line in generated.splitlines():
        match = _BLOCK_RE.match(line)
        if match:
            close()
            block = cursor = int(match.group(2), 16)
            continue
        match = _SUBBLOCK_RE.match(line)
        if match and block is not None:
            address, length = int(match.group(2), 16), int(match.group(3))
            if address != cursor:
                problems.append(f"the sub-block at ${address:04X} in the block at "
                                f"${block:04X} should start at ${cursor:04X}")
            cursor = address + length
    close()
    # A picture paragraph (D) for an address that starts no entry would be
    # lost without a word: each must land on an entry the annotations or the
    # generated lines start.
    entries = {s for s, _ in annotated_entries()}
    entries |= {int(m.group(2), 16) for m in (_BLOCK_RE.match(line)
                                              for line in generated.splitlines()) if m}
    for line in generated.splitlines():
        match = re.match(r"^D \$([0-9A-F]{4}) ", line)
        if match and int(match.group(1), 16) not in entries:
            problems.append(f"the paragraph at ${match.group(1)} is not at the start of an entry")
    if problems:
        for problem in problems:
            _log(f"  STRUCTURE: {problem}")
        sys.exit(f"error: {len(problems)} structural problem(s) -- the bytes would "
                 f"still reassemble; what is wrong is what the listing says about them")
    _log(f"  {len(owned)} generated ranges and {len(spans)} spans, no overlaps; "
         f"every generated sub-block accounted for")


# Placeholder names for the entries the annotations have not named yet, by
# kind, so every address in the listing has a label; each is replaced as the
# annotations name its entry.
PLACEHOLDER = {"c": "SUB", "b": "DATA", "t": "TEXT", "w": "WORDS", "s": "SPACE",
               "u": "UNUSED", "g": "VAR", "i": "IGNORED"}


def label_unlabelled(skool_text: str) -> str:
    """Give each entry the annotations leave without a label a placeholder
    one -- SUB for code, DATA for data and so on, then its address -- so
    every address in the listing has a name. No underscore before the
    address: skool2asm names jump targets NAME_0, NAME_1..., and a label
    ending in an underscore and digits could collide with one of those."""
    out, label = [], None
    for line in skool_text.split(NEWLINE):
        if line.startswith("@label="):
            label = line[len("@label="):]
        else:
            match = re.match(r"^([bcgistuw])\$([0-9A-F]{4})", line)
            if match:
                if label is None:
                    out.append(f"@label={PLACEHOLDER[match.group(1)]}{match.group(2)}")
                label = None
            elif re.match(r"^[ *]\$[0-9A-F]{4}", line):
                label = None
        out.append(line)
    return NEWLINE.join(out)


def build_asm(snapshot: Path, code_map: Path, ctl: Path, skool: Path, asm: Path) -> int:
    from skoolkit import skool2asm, sna2ctl, sna2skool


    _log("Generating control file...")
    auto_ctl = _capture(sna2ctl.main, [
        "-m", str(code_map), "-h",
        "-s", str(BLOCK_START), "-e", str(BLOCK_END), str(snapshot),
    ])
    auto_ctl = NEWLINE.join(line for line in auto_ctl.splitlines()
                            if not re.match(r"^@ \$[0-9A-F]{4} (start|org)$", line))
    memory = game_memory(snapshot)
    # The tables laid out a record per line from the game's own bytes, by
    # cyberun_data.py once it exists; until then sna2ctl's blocks stand.
    try:
        import cyberun_data
    except ImportError:
        cyberun_data = None
    generated = cyberun_data.data_blocks(memory) if cyberun_data else ""
    (OUT_DIR / "cyberun-data.ctl").write_text(generated, encoding="utf-8")
    owned = cyberun_data.OWNED if cyberun_data else []
    spans = declared_spans()
    check_structure(generated, owned, spans)
    merged = take_over(auto_ctl, owned, keep_start=False)
    merged = take_over(merged, spans, keep_start=True)
    entries = annotated_entries()
    merged = take_over(merged, entries, keep_start=True)
    dropped = len(auto_ctl.splitlines()) - len(merged.splitlines())
    _log(f"  {len(owned)} generated ranges, {len(spans)} declared spans and "
         f"{len(entries)} annotated entries replaced {dropped} of sna2ctl's directives")
    # The generated blocks go in at their places, so the file stays in order.
    ctl_lines = merged.splitlines() + generated.splitlines()
    def key(item):
        index, line = item
        match = _ANY_DIRECTIVE_RE.match(line)
        return (int(match.group(1), 16) if match else 0x10000, index)
    directives = [line for _, line in sorted(enumerate(ctl_lines), key=key)
                  if _ANY_DIRECTIVE_RE.match(line)]
    ctl.write_text(f"@ ${BLOCK_START:04X} start{NEWLINE}@ ${BLOCK_START:04X} org{NEWLINE}"
                   + NEWLINE.join(directives) + NEWLINE, encoding="utf-8")

    _log("Generating skool file...")
    warnings: list[str] = []
    ctls = ["-c", str(ctl)]
    if ANNOTATIONS.exists():
        # Disassemble once with only the annotations' block directives, to
        # learn where the instruction boundaries are, so that a comment whose
        # length splits an instruction is reported by line number.
        structure = OUT_DIR / "cyberun-structure.ctl"
        structure.write_text(NEWLINE.join(
            " ".join(line.split(" ", 2)[:2])
            for line in ANNOTATIONS.read_text(encoding="utf-8").splitlines()
            if _BLOCK_RE.match(line)), encoding="utf-8")
        # Its warnings count too: an overlap it reports (a w block read as
        # words from its first byte, one running into the next entry) is a
        # real fault in the annotations, even if the full pass hides it.
        check_annotations(_capture(sna2skool.main,
                                   ["-H", "-c", str(ctl), "-c", str(structure),
                                    str(snapshot)], warnings))
        ctls += ["-c", str(ANNOTATIONS)]
    # ListRefs=2: every entry gets its "Used by the routines at ..." line.
    skool.write_text(label_unlabelled(_capture(sna2skool.main,
                                               ["-H", "-I", "ListRefs=2", *ctls,
                                                str(snapshot)], warnings)),
                     encoding="utf-8")

    _log("Generating assembly...")
    text = _capture(skool2asm.main, ["-H", "-c", str(skool)], warnings)
    asm.write_text("    DEVICE ZXSPECTRUM48\n" + text, encoding="utf-8")
    report = OUT_DIR / "cyberun-warnings.txt"
    report.write_text(NEWLINE.join(warnings) + NEWLINE, encoding="utf-8")
    _log(f"  {len(warnings)} warning(s)" + (f" -- see {report.name}" if warnings else ""))
    return len(warnings)


def check_executed_in_code(code_map: Path, skool: Path) -> None:
    """Stop the build if an address the processor executed lies in an entry
    the annotations type as data.

    Either the annotations are wrong (code they call data), or a session
    sent the game somewhere it never goes -- a staged scene that left the
    ship inside rock once ran it off the bottom of the map and into the
    frame's corner bitmaps, where it stopped on a HALT -- and the code map is
    polluted. Neither should pass silently.
    """
    ran = code_map.with_name(code_map.stem + "-executed.map").read_bytes()
    entries, kinds, labels, label = [], {}, {}, None
    for line in skool.read_text(encoding="utf-8").split(NEWLINE):
        if line.startswith("@label="):
            label = line[len("@label="):]
            continue
        match = re.match(r"^([bcgistuw])\$([0-9A-F]{4})", line)
        if match:
            address = int(match.group(2), 16)
            entries.append(address)
            kinds[address], labels[address] = match.group(1), label
            label = None
    problems = {}
    for address in range(BLOCK_START, BLOCK_END):
        if ran[address]:
            entry = entries[bisect.bisect_right(entries, address) - 1]
            if kinds[entry] != "c":
                problems.setdefault(entry, []).append(address)
    if problems:
        for entry, addresses in sorted(problems.items()):
            _log(f"  EXECUTED IN DATA: {labels[entry]} (${entry:04X}, {kinds[entry]}): "
                 f"{len(addresses)} address(es) from ${addresses[0]:04X}")
        sys.exit(f"error: {len(problems)} data entr(ies) hold executed addresses")
    _log("  every executed address is in a code entry")


def report_coverage(snapshot: Path, code_map: Path, skool: Path, out: Path) -> None:
    """How much is code, how much data, and which code never ran.

    Written to cyberun-coverage.txt beside the listing, a line per run of
    instructions that recursive descent found but no session executed, with
    the entry each is in -- the list of what the sessions have yet to reach,
    and of what a description of it rests on reading alone.
    """
    import codemap

    memory = list(game_memory(snapshot))
    code_starts = {a for a, flag in enumerate(code_map.read_bytes()) if flag & 1}
    ran = {a for a, flag in enumerate(
        code_map.with_name(code_map.stem + "-executed.map").read_bytes()) if flag & 1}
    lengths = {a: codemap.decode(memory, a).length for a in code_starts}
    code_bytes = sum(lengths.values())
    unrun = sorted(code_starts - ran)
    runs, start, previous = [], None, None
    for address in unrun:
        if start is not None and address == previous + lengths[previous]:
            previous = address
            continue
        if start is not None:
            runs.append((start, previous + lengths[previous]))
        start = previous = address
    if start is not None:
        runs.append((start, previous + lengths[previous]))

    entries, kinds = [], {}
    for line in skool.read_text(encoding="utf-8").split(NEWLINE):
        match = re.match(r"^([bcgistuw])\$([0-9A-F]{4})", line)
        if match:
            entries.append((int(match.group(2), 16), match.group(1)))
            kinds[match.group(1)] = kinds.get(match.group(1), 0) + 1

    def entry_of(address):
        found = None
        for entry, _ in entries:
            if entry > address:
                break
            found = entry
        return found

    total = BLOCK_END - BLOCK_START
    loaded = LOADED_END - LOADED_START
    lines = [f"{total} bytes disassembled (${BLOCK_START:04X}-${BLOCK_END - 1:04X}); "
             f"{loaded} of them loaded from the tape (${LOADED_START:04X} up)",
             f"{code_bytes} bytes are code: {len(code_starts)} instructions, "
             f"{len(ran & code_starts)} executed in the sessions and "
             f"{len(unrun)} found only by following branches",
             f"{total - code_bytes} bytes are data, buffers and tables",
             "entries: " + ", ".join(f"{count} {kind}" for kind, count in sorted(kinds.items())),
             "",
             f"Code that never ran ({len(runs)} runs, "
             f"{sum(e - s for s, e in runs)} bytes), with its entry:"]
    for start, end in runs:
        entry = entry_of(start)
        lines.append(f"  ${start:04X}-${end - 1:04X}  {end - start:4d} bytes  "
                     f"in ${entry:04X}" if entry is not None else f"  ${start:04X}")
    out.write_text(NEWLINE.join(lines) + NEWLINE, encoding="utf-8")
    for line in lines[:5]:
        _log(f"  {line}")
    _log(f"  code that never ran: {len(runs)} runs, {sum(e - s for s, e in runs)} bytes "
         f"-- see {out.name}")


# --------------------------------------------------------------------------
# Step 4: assemble it back and prove it round-trips.
# --------------------------------------------------------------------------

def assemble(asm: Path, sld: Path) -> bytes:
    sjasmplus = str(SJASMPLUS) if SJASMPLUS.exists() else "sjasmplus"
    raw = OUT_DIR / "cyberun.rawbin"
    _log("Assembling with sjasmplus...")
    result = subprocess.run(
        [sjasmplus, asm.name, f"--sld={sld.name}", "--fullpath", f"--raw={raw.name}"],
        cwd=OUT_DIR, text=True, capture_output=True)
    if result.returncode != 0:
        sys.exit(f"error: sjasmplus failed:\n{result.stdout}\n{result.stderr}")
    counts = re.search(r"Errors: (\d+), warnings: (\d+)", result.stdout + result.stderr)
    if not counts or counts.group(2) != "0":
        sys.exit(f"error: sjasmplus warned:\n{result.stdout}\n{result.stderr}")
    game_bytes = raw.read_bytes()
    raw.unlink()
    return game_bytes


def verify(game_bytes: bytes, snapshot: Path) -> None:
    reference = bytes(game_memory(snapshot)[BLOCK_START:BLOCK_END])
    if len(game_bytes) != len(reference):
        sys.exit(f"error: assembled {len(game_bytes)} bytes, expected {len(reference)}")
    if game_bytes != reference:
        bad = [i for i, (a, b) in enumerate(zip(game_bytes, reference)) if a != b]
        sys.exit(f"error: assembled output differs from the tape in {len(bad)} bytes, "
                 f"first at ${BLOCK_START + bad[0]:04X} -- the disassembly is not faithful")
    _log(f"Verified: {len(game_bytes)} bytes reassemble byte-for-byte")


# --------------------------------------------------------------------------
# Step 5: write the snapshot back.
# --------------------------------------------------------------------------

def write_snapshot(game_bytes: bytes, snapshot: Path, out: Path) -> None:
    """The snapshot tap2sna made, with $5B00 up replaced by the assembled bytes.

    The header -- PC at $5C80, the registers and the rest -- is carried
    across from the one read, so the file written must be that file again
    byte for byte: the check covers what verify() cannot, that the splice
    went in at the right place and nothing else moved.
    """
    from skoolkit.snapshot import Z80

    original = snapshot.read_bytes()
    z80 = Z80(original)
    ram = list(z80.ram())
    ram[BLOCK_START - 0x4000:BLOCK_END - 0x4000] = game_bytes
    z80.set_ram(ram)
    rebuilt = bytes(z80.data())
    out.write_bytes(rebuilt)
    if rebuilt != original:
        bad = [i for i, (a, b) in enumerate(zip(rebuilt, original)) if a != b]
        sys.exit(f"error: the snapshot written differs from the one read in "
                 f"{len(bad) + abs(len(rebuilt) - len(original))} byte(s)")
    _log(f"Verified: the snapshot it writes is the snapshot it read, "
         f"all {len(rebuilt)} bytes")


# --------------------------------------------------------------------------
# Step 6 (--html): the browsable disassembly and its pages.
# --------------------------------------------------------------------------

# Everything below writes pages that quote the game, so, like the
# disassembly itself, it is built locally and not committed. The prose
# pages are scripts/cyberun.ref, which is.

# The generated pages beyond the listing, each family in a module of its own
# beside this script: build(snapshot, html_dir, log) draws its pictures and
# records its sounds into html_dir and returns its ref sections, name to body.
# A module not written yet is skipped, so the pages can arrive one at a time.
PAGE_MODULES = ["cyberun_howitworks", "cyberun_world", "cyberun_graphics",
                "cyberun_animations", "cyberun_sounds", "cyberun_reference"]


# The loading screen's title: the top five character rows. PIC draws the
# picture while the tape loads and nothing clears it before the game starts,
# so the snapshot at $5C80 still holds it.
LOGO_ROWS = 5
LOGO_SCALE = 2


def write_logo(snapshot: Path, path: Path) -> None:
    """The title in its own colours on a clear background, twice the size."""
    from PIL import Image

    memory = game_memory(snapshot)
    palette = [((0xD7 if c & 2 else 0), (0xD7 if c & 4 else 0), (0xD7 if c & 1 else 0))
               for c in range(8)]
    bright = [tuple(0xFF if v else 0 for v in rgb) for rgb in palette]
    height = LOGO_ROWS * 8
    image = Image.new("RGBA", (256, height), (0, 0, 0, 0))
    pixels = image.load()
    for y in range(height):
        row = 0x4000 | (y & 0xC0) << 5 | (y & 7) << 8 | (y & 0x38) << 2
        for column in range(32):
            attr = memory[0x5800 + (y >> 3) * 32 + column]
            colours = bright if attr & 0x40 else palette
            ink, paper = colours[attr & 7], colours[attr >> 3 & 7]
            bits = memory[row + column]
            for bit in range(8):
                # Some of the letters are drawn in paper, so each pixel takes
                # its own colour; only black is left clear.
                colour = ink if bits & (0x80 >> bit) else paper
                if colour != (0, 0, 0):
                    pixels[column * 8 + bit, y] = colour + (255,)
    box = image.getbbox()
    if box is None:
        return
    image = image.crop((box[0] - 4, max(box[1] - 4, 0), box[2] + 4, box[3] + 4))
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize((image.width * LOGO_SCALE, image.height * LOGO_SCALE),
                 Image.NEAREST).save(path)


def write_pages_ref(snapshot: Path, html_dir: Path, path: Path) -> list[str]:
    import importlib

    sections, built = {}, []
    for name in PAGE_MODULES:
        if not (Path(__file__).resolve().parent / f"{name}.py").exists():
            continue
        sections.update(importlib.import_module(name).build(snapshot, html_dir, _log))
        built.append(name)
    path.write_text(NEWLINE.join(f"[{name}]{NEWLINE}{body}{NEWLINE}"
                                 for name, body in sections.items()), encoding="utf-8")
    return built


def build_html(skool: Path, snapshot: Path, out: Path) -> None:
    from skoolkit import skool2html

    _log("Writing HTML disassembly...")
    game_dir = out / "cyberun"
    # The title from the loading screen, for the top of every page
    # (LogoImage in cyberun.ref); written before skool2html, which shows a
    # logo only if the file is there.
    write_logo(snapshot, game_dir / "images" / "logo.png")
    # The pictures the generated control file's paragraphs show in the
    # entries, each drawn by the game's own drawing code (cyberun_data.py).
    import cyberun_data
    count = cyberun_data.draw_pictures(snapshot, game_dir / "images" / "graphics", _log)
    _log(f"  {count} pictures drawn")
    pages_ref = OUT_DIR / "cyberun-pages.ref"
    built = write_pages_ref(snapshot, game_dir, pages_ref)
    _log(f"  page modules: {', '.join(built) if built else 'none yet'}")
    refs = [str(REF)] if REF.exists() else []
    # -a: the pages use the annotations' labels. -S: the style sheets the ref
    # names are beside this script. -o: redraw the images every time.
    args = ["-H", "-a", "-o", "-d", str(out), "-S", str(Path(__file__).resolve().parent),
            str(skool), *refs, str(pages_ref)]
    _capture(skool2html.main, args)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--tape", required=True, type=Path,
                        help="the Cyberun .tzx to disassemble")
    parser.add_argument("--html", action="store_true",
                        help="also write a browsable HTML disassembly under "
                             "game_disassembly/cyberun/html/")
    parser.add_argument("--cycles", type=int, default=6,
                        help="rounds of play per playing session (default 6)")
    args = parser.parse_args()

    if not args.tape.exists():
        sys.exit(f"error: {args.tape} not found")
    if not ROM.exists():
        sys.exit(f"error: {ROM} not found -- see README.md for where to get it")

    started = time.time()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    snapshot = OUT_DIR / "cyberun.z80"
    code_map = OUT_DIR / "cyberun.map"
    ctl = OUT_DIR / "cyberun.ctl"
    skool = OUT_DIR / "cyberun.skool"
    asm = OUT_DIR / "cyberun.asm"
    sld = OUT_DIR / "cyberun.sld"
    rebuilt = OUT_DIR / "cyberun-rebuilt.z80"

    make_snapshot(args.tape, snapshot)
    _log("Playing the game to map out which addresses are code...")
    build_code_map(snapshot, code_map, args.cycles)
    warnings = build_asm(snapshot, code_map, ctl, skool, asm)
    check_executed_in_code(code_map, skool)
    report_coverage(snapshot, code_map, skool, OUT_DIR / "cyberun-coverage.txt")
    game_bytes = assemble(asm, sld)
    verify(game_bytes, snapshot)
    write_snapshot(game_bytes, snapshot, rebuilt)
    if args.html:
        build_html(skool, snapshot, OUT_DIR / "html")

    _log("")
    _log(f"Wrote {asm}, {sld} and {rebuilt} in {time.time() - started:.0f} s")
    if args.html:
        _log(f"HTML disassembly: {OUT_DIR / 'html' / 'cyberun' / 'index.html'}")
    _log("Load roms/48.rom first, then the .z80 + .sld.")
    if warnings:
        # Everything is written, so the warnings can be looked at in place;
        # but a build with any is not a finished one.
        sys.exit(f"error: {warnings} warning(s) from sna2skool and skool2asm -- see "
                 f"{OUT_DIR / 'cyberun-warnings.txt'}")


if __name__ == "__main__":
    main()
