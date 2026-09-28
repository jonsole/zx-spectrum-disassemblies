"""Disassemble Nightshade (1985, Ultimate Play the Game) from its tape.

THE TAPE. A BASIC loader "NIGHT" (LINE 0), then four CODE files, each a
header and a data block: "SP" (CODE 16384,6912, the loading screen), "0"
(CODE 24576,34816), "1" (CODE 23424,43), "2" (CODE 23728,1) and "3" (CODE
23672,2). The loader beeps five times, clears the screen to black, prints
that the game is loading, and then

    LOAD ""SCREEN$ : LOAD ""CODE : LOAD ""CODE : LOAD ""CODE : LOAD ""CODE :
    PRINT USR 23424

so "0" loads the game at $6000-$E7FF, "1" a 43-byte routine into the printer
buffer at $5B80, "2" one byte, $E9 (JP (HL)), into the system variable NMIADD
at $5CB0, and "3" two bytes, $6334, into FRAMES at $5C78. The routine at
$5B80 sets bit 7 of the R register, unscrambles the game block in place --
each pair of bytes has a nibble swapped between them by RLD -- moves it down
to $5E00-$E5FF, and jumps to $5E00: DI and JP to the game's start.

That is the protection, and all three of its pieces are checked by the game
itself: the start returns to BASIC unless the high byte of FRAMES is $63;
the object dispatcher ends in JP $5CB0, so without the JP (HL) there no
object is ever updated; and every new game reads R and jumps to 0 -- a reset
-- unless bit 7 is set, which only LD R,A can do. tap2sna runs the ROM's own
LOAD and the loader on a simulated machine and stops at $5E00, before the
game has run a single instruction, so all three are in the snapshot; and the
simulator here starts with R taken from it. make_snapshot() also runs the
unscrambling on the tape's own block and checks it gives the snapshot's
bytes, so what the loader does is checked, not only described.

The game changes itself as it runs (sprites are turned round in place), so
the disassembly is of the loaded image, stopped at $5E00.

WHAT IS DISASSEMBLED: $5B00 to the top of memory. Below the game are the
system variables, the loader's routine, the BASIC program and the game's
stack (down from $5E00). The game's code runs from $BDFE to $E5C3; above it
are the screen buffer and its attributes ($E5C4-$F193) and the lookup
tables the game builds ($F200-$FFFF), which it writes before it reads; the
bytes the snapshot holds there are leftovers of the load (the tail of the
unscrambled block, which the move down left behind at $E600-$E7FF, and the
ROM's user-defined graphics at the top).

SEPARATING CODE FROM DATA the way the Alien 8 build does: play the game in
SkoolKit's simulator from $5E00 and record every address executed, in
sessions that pick each control method and walk, turn, fire and turn the
view round, visit every cell of the town, and in staged scenes for what play
will not reach in a sensible time (the four objects picked up and thrown at
the four villains, the ending, game over, the bonuses). Then follow the
branches out of what ran (scripts/codemap.py), which invents nothing.

THE LEVEL DATA -- the town map, the drawing order, the buildings, their
boxes and tiles, the graphic table, the sprites, the fonts, the tunes and the
text -- is laid out a record per line by scripts/nightshade_data.py from the
snapshot at every build, so the game's design is never written into a
committed file.

The game and everything built from it is copyrighted ((c) 1985 Ultimate Play
the Game / A.C.G.). Built locally, gitignored, never committed. See README.md.

Usage:
    python scripts/build_nightshade.py --tape "path/to/Nightshade.tzx" [--html]
"""
from __future__ import annotations

import argparse
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
OUT_DIR = PROJECT_ROOT / "game_disassembly" / "nightshade"
# Hand-written comments, layered over the generated control file. Source, not
# output: addresses and prose only, so it is committed.
ANNOTATIONS = PROJECT_ROOT / "scripts" / "nightshade_annotations.ctl"
REF = PROJECT_ROOT / "scripts" / "nightshade.ref"
ROM = PROJECT_ROOT / "roms" / "48.rom"
SJASMPLUS = PROJECT_ROOT / "tools" / "sjasmplus" / "sjasmplus.exe"

# Where the loader's routine jumps to, and where tap2sna stops.
ENTRY = 0x5E00
# The disassembly: everything from the printer buffer to the top of memory.
BLOCK_START = 0x5B00
BLOCK_END = 0x10000
# The game block as it lies after the loader has moved it down: $5E00-$E5FF,
# and the 512 bytes the move left behind above it.
LOADED_START = 0x5E00
LOADED_END = 0xE800
# The code, for following branches: from the entry to the screen buffer.
DESCENT_START = 0x5E00
DESCENT_END = 0xE5C4

# The loader: where "0" loads, how long it is, the routine that unscrambles
# it and where it moves it.
LOAD_ADDRESS = 0x6000
LOAD_LENGTH = 0x8800
LOADER = 0x5B80
LOADER_LENGTH = 43

TSTATES_PER_SECOND = 3500000
NEWLINE = chr(10)

# The update routine for each graphic, a word each: the main loop's jump
# table (see nightshade_data.py, which lays it out).
UPDATES = 0xD599
UPDATE_COUNT = 158
# The other tables of routines reached through the dispatcher at $D593, by
# address and number of words: a monster's end when an antibody hits it
# ($C083), the depth test's outcomes ($CFF2), the knight's walk by facing
# ($DC60), and the steps along and across a facing ($DD28, $DE59).
JUMP_TABLES = [(0xC0D1, 4), (0xD0A0, 18), (0xDC71, 4), (0xDD6A, 4), (0xDE6A, 4)]


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
    """Simulate the real LOAD, stopping where the loader enters the game."""
    from skoolkit import tap2sna

    _log(f"Loading {tape.name} (simulated LOAD)...")
    # as_uri: tap2sna reads its input as a URL, and C:\ would be scheme "c".
    with contextlib.redirect_stdout(io.StringIO()):
        tap2sna.main(["--start", str(ENTRY), tape.resolve().as_uri(), str(out)])
    if not out.exists():
        sys.exit(f"error: tap2sna did not write {out}")
    check_loader(tape, out)


def _tape_blocks(tape: Path) -> list[bytes]:
    from skoolkit.tape import parse_tap, parse_tzx

    data = tape.read_bytes()
    parsed = parse_tzx(data) if tape.suffix.lower() == ".tzx" else parse_tap(data)
    return [bytes(block.data) for block in parsed.blocks if block.data]


def check_loader(tape: Path, snapshot: Path) -> None:
    """Do what the routine at $5B80 does to the tape's game block, and check
    the snapshot holds the result -- so the account of the loader in the
    listing is checked every build, not only written down.

    The routine takes the block a pair of bytes at a time, from $6000 and
    $6001: LD A,(DE) then RLD with (HL) gives A the high nibble of the second
    byte in place of its own low one, and the second byte its own low nibble
    moved up with the first byte's low nibble under it; then LD (DE),A. Then
    it moves $6000-$E7FF down to $5E00 with LDIR."""
    blocks = [block for block in _tape_blocks(tape) if len(block) == LOAD_LENGTH + 2]
    if len(blocks) != 1:
        sys.exit(f"error: expected one block of {LOAD_LENGTH} bytes on the tape")
    memory = bytearray(65536)
    memory[LOAD_ADDRESS:LOAD_ADDRESS + LOAD_LENGTH] = blocks[0][1:-1]
    for pair in range(LOAD_LENGTH // 2):
        first, second = LOAD_ADDRESS + 2 * pair, LOAD_ADDRESS + 2 * pair + 1
        a, t = memory[first], memory[second]
        memory[second] = (t << 4 | a & 0x0F) & 0xFF
        memory[first] = a & 0xF0 | t >> 4
    moved = memory[LOAD_ADDRESS:LOAD_ADDRESS + LOAD_LENGTH]
    memory[ENTRY:ENTRY + LOAD_LENGTH] = moved
    loaded = game_memory(snapshot)
    if bytes(loaded[LOADED_START:LOADED_END]) != bytes(memory[LOADED_START:LOADED_END]):
        sys.exit("error: the tape's block, unscrambled the loader's way, is not what "
                 "the snapshot holds")
    loader = [block for block in _tape_blocks(tape) if len(block) == LOADER_LENGTH + 2]
    if len(loader) != 1 or bytes(loaded[LOADER:LOADER + LOADER_LENGTH]) != loader[0][1:-1]:
        sys.exit("error: the loader's routine is not in the printer buffer")
    _log(f"  the tape's game block unscrambled and moved the loader's way is the "
         f"snapshot's ${LOADED_START:04X}-${LOADED_END - 1:04X}")


# --------------------------------------------------------------------------
# Step 2: play the game to find out which addresses are code.
# --------------------------------------------------------------------------

# The variables the sessions read and write. See the annotations for each.
CONTROL = 0xBBB0            # bits 1-2: 0 keyboard, 1 Kempston, 2 cursor, 3 Interface II;
                            # bit 3 directional control
VIEW = 0xBBBA               # bit 0: the town turned round (Z or SYMBOL SHIFT)
LIVES = 0xBBCD
HITS = 0xBBF3               # hits left in this life: 3, 2, 1 (white, yellow, green)
ENDING = 0xBBFF             # set while the ending plays
ARRIVING = 0xBC02           # counts up while the knight appears; $70 once he is here
CARRIED = 0xBC03            # the eleven carried things
KNIGHT = 0xBC8E             # his legs' record; his top is the next
KNIGHT_TOP = 0xBC9E
RECORDS_END = 0xBDFE        # 23 records of 16 bytes from KNIGHT
BONUS = 0xBD0E              # the record for a bonus (graphics 2 and 3, #R$D76C)
OBJECTS = 0xBD1E            # the four objects, graphics 7, 6, 5, 4 (#R$D88E)
VILLAINS = 0xBD5E           # the four villains, graphics 108, 104, 100, 96 up (#R$D8E7)
SCORE = 0xBBC9              # three bytes of BCD
VISITED = 0xBC0E            # a bit for each cell visited (#R$BF48)
ANTIBODIES = 0xBCAE         # two records for antibodies in flight (#R$DAB7)
MONSTERS = 0xBD9E           # six records for monsters (#R$CDE8)
FINDS = 0xBCCE              # four records for what is found in buildings (#R$C5CE)
# The knight's two records at a new life (#R$CBAC): +2 and +4 of the first
# are the column and row of the cell he appears in.
START_U_CELL = 0xCC38
START_V_CELL = 0xCC3A
MENU_LOOP = 0xC8E1          # the menu, once a pass (#R$C8CA)
MAIN_LOOP = 0xBE71          # the main loop, once a turn
VANISH = 0x0C               # the graphic of something vanishing (#R$D7D8)
BONUS_SPEED, BONUS_CURE = 2, 3
OBJECT_GRAPHIC = 4          # 4-7: the four objects lying in the town
FIND_GRAPHIC = 0x30         # 48-63: what is found in a building
VILLAIN_GRAPHIC = 0x60      # 96-111: the four villains
DYING_VILLAIN = 0x84        # a villain struck by its object

# Kempston bits, as IN A,($1F) reads them at #R$E289.
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
    was right once stays right: each step waits for what it means (the
    knight in a cell, the menu) and the build stops, saying which, if that
    never comes.
    """

    def __init__(self, what: str, test, seconds: float = 20.0, keys=(), stick: int = 0,
                 during=None, required: bool = True):
        self.what, self.test, self.seconds = what, test, seconds
        self.keys, self.stick, self.during = keys, stick, during
        # Not required: give up quietly when the time is up, for a try that
        # a Repeat round it tests and repeats.
        self.required = required


class Repeat:
    """A session step: play some steps over again until test(memory) is
    true, at most `times` times, or fail -- for what takes the game a
    variable number of tries."""

    def __init__(self, what: str, steps: list, test, times: int):
        self.what, self.steps, self.test, self.times = what, steps, test, times


class At:
    """A session step: run until the game reaches an address, or fail -- for
    a poke that has to land at a known point in the game's turn rather than
    wherever the simulator happened to stop."""

    def __init__(self, what: str, address: int, seconds: float = 20.0):
        self.what, self.address, self.seconds = what, address, seconds


class Machine:
    """The game on a simulated 48K Spectrum, from the snapshot at $5E00."""

    def __init__(self, snapshot: Path, executed: set | None = None):
        from skoolkit import CSimulator, read_bin_file
        from skoolkit.simulator import Simulator
        from skoolkit.simutils import R, SP
        from skoolkit.snapshot import Snapshot

        memory = list(game_memory(snapshot))
        memory[:0x4000] = read_bin_file(str(ROM))
        self.simulator = (CSimulator or Simulator)(
            memory, state={"iff": 0, "im": 1, "tstates": 0})
        # The game's first instructions set their own stack; this one only
        # has to be somewhere harmless until then.
        self.simulator.registers[SP] = ENTRY
        # R as the loader left it, bit 7 set: every new game checks the bit
        # (#R$C1DB) and resets the machine without it.
        self.simulator.registers[R] = Snapshot.get(str(snapshot)).r
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

        self.tracer.keys = set()
        self.tracer.kempston = 0
        simulator = self.simulator
        simulator.trace(self.pc, step.address, 0,
                        simulator.registers[T] + int(step.seconds * TSTATES_PER_SECOND),
                        True, None, self.executed, None, None, None)
        self.pc = simulator.registers[PC]
        if self.pc != step.address:
            sys.exit(f"error: session {label!r}: ran {step.seconds} s and never reached "
                     f"{step.what} (${step.address:04X}; PC ${self.pc:04X})")

    def until(self, step: Until, label: str) -> None:
        waited = 0.0
        while not step.test(self.memory):
            if waited >= step.seconds:
                if not step.required:
                    return
                sys.exit(f"error: session {label!r}: waited {step.seconds} s for "
                         f"{step.what}, and it never came (PC ${self.pc:04X})")
            if step.during is not None:
                step.during(self.memory)
            self.run(0.05, step.keys, step.stick)
            waited += 0.05

    def play(self, steps, label: str) -> None:
        for step in steps:
            if isinstance(step, Until):
                self.until(step, label)
            elif isinstance(step, At):
                self.run_to(step, label)
            elif isinstance(step, Repeat):
                for _ in range(step.times):
                    self.play(step.steps, label)
                    if step.test(self.memory):
                        break
                else:
                    sys.exit(f"error: session {label!r}: {step.times} tries and no sign "
                             f"of {step.what} (PC ${self.pc:04X})")
            elif callable(step):
                step(self.memory)
            else:
                keys, seconds = step[0], step[1]
                stick = step[2] if len(step) > 2 else 0
                self.run(seconds, keys, stick)


def _turn(*pokes) -> list:
    """Pokes made at the start of a turn, before the first object's update.

    Anywhere else they can land in the middle of an update routine, which
    then finishes with what it read before: the knight's own routine, part
    way through when his record was turned into the vanishing graphic,
    wrote its walking frame's bit back over it (#R$DC14) and left graphic 4
    -- an object lying in the street -- where he had been, and no new life
    ever came."""
    return [At("the start of a turn", MAIN_LOOP)] + list(pokes)


def _playing(memory) -> bool:
    """In the town and walking about: he has finished appearing, and his
    legs have one of their walking graphics (16-21, 24-29)."""
    return memory[ARRIVING] == 0x70 and 0x10 <= memory[KNIGHT] < 0x20


def _in_cell(u: int, v: int):
    return lambda memory: (_playing(memory) and memory[KNIGHT + 2] == u
                           and memory[KNIGHT + 4] == v)


def _lives(memory) -> None:
    """Five lives and all his hits, whatever has happened: the sessions die a
    lot."""
    memory[LIVES] = 5
    memory[HITS] = 3


def _kill(memory) -> None:
    """End his life the way #R$CE89 does: both records turned into the
    vanishing graphic. When it has run its frames the first record is empty,
    and the main loop starts a new life (#R$CBAC)."""
    memory[KNIGHT] = memory[KNIGHT_TOP] = VANISH


def _go(u: int, v: int) -> list:
    """Into a cell by the game's own restart: the cell goes where a new life
    copies the knight from (#R$CBAC), and his life ends."""
    def poke(memory):
        _lives(memory)
        memory[START_U_CELL], memory[START_V_CELL] = u, v
        _kill(memory)
    # Lives are topped up while he appears too: a villain standing in the
    # cell kills him the moment he is there (#R$D94F), and he starts again
    # in the same cell (#R$CE89), as many times as it takes.
    return ([Until("a live knight", _playing, 30.0, during=_lives)] + _turn(poke)
            + [Until(f"cell ({u},{v})", _in_cell(u, v), 30.0, during=_lives)])


def _start(*choices: str) -> list:
    """From the menu, with a control method, through the start tune into
    the town."""
    steps = [At("the menu", MENU_LOOP, 30.0), ([], 0.5)]
    for choice in choices:
        steps += [([choice], 0.3), ([], 0.5)]
    return steps + [(["0"], 0.3), Until("the knight in the town", _playing, 30.0)]


# A round of keyboard play (#R$E2DA reads the rows): walk (the A-G and
# H-ENTER rows), turn left (X, V, B, M) and right (C, N), fire (the Q-T and
# Y-P rows), and turn the town round (Z, SYMBOL SHIFT).
KEYBOARD_ROUND = [
    (["a"], 1.2), (["x"], 0.3), (["h"], 1.0), (["c"], 0.3), (["s"], 1.5),
    (["q"], 0.3), ([], 0.4), (["a", "e"], 0.8), (["z"], 0.3), ([], 0.4),
    (["m"], 0.3), (["ENTER"], 1.2), (["y"], 0.3), ([], 0.4),
    (["b"], 0.3), (["d"], 1.0), (["SS"], 0.3), ([], 0.4), (["n"], 0.3),
    (["v"], 0.3), (["g"], 1.5), (["p"], 0.3), ([], 0.4), (["1"], 0.3),
]
# The same with a Kempston joystick (#R$E289): left and right turn, up
# walks, fire fires, down is only for directional control.
STICK_ROUND = [
    ([], 1.2, J_UP), ([], 0.3, J_LEFT), ([], 1.0, J_UP), ([], 0.3, J_RIGHT),
    ([], 0.3, J_FIRE), ([], 0.6), ([], 0.8, J_UP | J_FIRE), ([], 0.3, J_DOWN),
    ([], 0.4), ([], 1.0, J_UP | J_LEFT), ([], 0.3, J_DOWN), ([], 1.2, J_UP),
    ([], 1.0, J_DOWN | J_LEFT), ([], 1.0, J_RIGHT), ([], 1.0, J_UP | J_RIGHT),
]
# Cursor keys (#R$E2AE): 5 left, 8 right, 7 walk, 6 down, 0 fire.
CURSOR_ROUND = [
    (["7"], 1.2), (["5"], 0.3), (["7"], 1.0), (["8"], 0.3), (["0"], 0.3),
    ([], 0.5), (["6"], 0.3), ([], 0.4), (["7", "8"], 1.0), (["6"], 0.3), ([], 0.4),
]
# Interface II, the first stick on 6-0 and the second on 1-5 (#R$E250).
SINCLAIR_ROUND = [
    (["9"], 1.2), (["6"], 0.3), (["9"], 1.0), (["7"], 0.3), (["0"], 0.3),
    ([], 0.5), (["8"], 0.3), ([], 0.4), (["9", "7"], 1.0), (["8"], 0.3), ([], 0.4),
    (["4"], 1.0), (["1"], 0.3), (["2"], 0.3), (["3"], 0.3), (["5"], 0.3), ([], 0.4),
]
# SPACE on its own pauses; SPACE again goes on (#R$E32C).
PAUSE = [(["SPACE"], 0.2), ([], 1.0), (["SPACE"], 0.2), ([], 0.5)]


def _alive(steps: list) -> list:
    """Steps with the lives topped up before each: the town is deadly, and a
    session that ran out of lives would spend the rest of itself at the menu."""
    out = []
    for step in steps:
        out += [_lives, step]
    return out


def _cells(snapshot: Path) -> list[tuple[int, int]]:
    """Every cell a new life may start in (#R$CB7B takes any but types 1 and
    2), row by row."""
    from nightshade_data import cell

    memory = game_memory(snapshot)
    return [(u, v) for v in range(32) for u in range(32)
            if cell(memory, u, v) not in (1, 2)]


def _tour(cells: list[tuple[int, int]], round_: list) -> list:
    """Every cell in turn, a little walking in each."""
    steps = []
    for u, v in cells:
        steps += _go(u, v) + _alive(round_)
    return steps


def _game_over(memory) -> None:
    """No lives left, and his life ending: #R$CBAC finds none to take."""
    memory[LIVES] = 0
    _kill(memory)


def _beside_knight(record: int, graphic: int, du: int = 0, dv: int = 0):
    """A record holding `graphic` where the knight stands (or a few units
    off), the size things he meets are given (#R$D7C7)."""
    def poke(memory):
        memory[record] = graphic
        for offset in (1, 2, 3, 4):
            memory[record + offset] = memory[KNIGHT + offset]
        memory[record + 1] = (memory[record + 1] + du) & 0xFF
        memory[record + 3] = (memory[record + 3] + dv) & 0xFF
        memory[record + 7] = 0
        memory[record + 8] = memory[record + 9] = 0x10
        memory[record + 12], memory[record + 13] = 0xF4, 0x04
    return poke


def _carrying(thing: int):
    return lambda memory: thing in memory[CARRIED:CARRIED + 11]


def _signed(byte: int) -> int:
    return byte - 256 if byte & 0x80 else byte


def _onto_thrown(which: int):
    """The villain put where the object thrown at it will be once its next
    update has moved it -- four of its steps on (+A and +B), since it moves
    twice a turn by twice its step (#R$D80C) -- so that the test after the
    move (#R$C554) finds the two touching."""
    def poke(memory):
        thrown, villain = OBJECTS + 16 * which, VILLAINS + 16 * which
        if not 8 <= memory[thrown] < 12:
            return
        for offset, step in ((1, 10), (3, 11)):
            where = _word(memory, thrown + offset) + 4 * _signed(memory[thrown + step])
            memory[villain + offset] = where & 0xFF
            memory[villain + offset + 1] = where >> 8 & 0xFF
    return poke


def _in_flight(memory) -> int | None:
    for record in (ANTIBODIES, ANTIBODIES + 16):
        if 0x50 <= memory[record] < 0x60:
            return record
    return None


def _ahead(record: int, graphic: int, placed: dict):
    """A monster of `graphic` put where the antibody in flight will be after
    its next update (as _onto_thrown does for a villain): the monsters'
    records come after the antibodies' in a turn, so the monster's own
    update finds the two touching (#R$C538)."""
    def poke(memory):
        thrown = _in_flight(memory)
        if thrown is None:
            return
        memory[record:record + 16] = bytes(16)
        memory[record] = graphic
        for offset, step in ((1, 10), (3, 11)):
            where = _word(memory, thrown + offset) + 4 * _signed(memory[thrown + step])
            memory[record + offset] = where & 0xFF
            memory[record + offset + 1] = where >> 8 & 0xFF
        memory[record + 8] = memory[record + 9] = 0x10
        memory[record + 12], memory[record + 13] = 0xF4, 0x04
        placed["yes"] = True
        placed["score"] = bytes(memory[SCORE:SCORE + 3])
    return poke


def _antibody_at(graphic: int, kind: int) -> list:
    """An antibody of `kind` (5-8) carried and thrown, and a monster of
    `graphic` put in its way; until the monster is struck, which takes more
    than one try when the antibody meets a wall first."""
    record = MONSTERS
    placed = {"yes": False}

    def give(memory):
        placed["yes"] = False
        if not memory[CARRIED]:
            memory[CARRIED] = kind

    def struck(memory):
        # Whatever a strike does to the monster -- it vanishes, turns into
        # another, or splits in two (#R$C0D1) -- it scores (#R$C2ED).
        return placed["yes"] and bytes(memory[SCORE:SCORE + 3]) != placed["score"]

    # Facing a wall close by, an antibody meets it in the turn it is thrown
    # and is never seen in flight; so he turns and tries again.
    attempt = ([(["x"], 0.3), _lives] + _turn(give)
               + [Until("an antibody in flight", lambda memory: _in_flight(memory) is not None,
                        0.5, keys=["q"], required=False)])
    one_try = ([Repeat("an antibody in flight", attempt,
                       lambda memory: _in_flight(memory) is not None, 12)]
               + _turn(_ahead(record, graphic, placed))
               + [Until(f"monster {graphic} struck", struck, 2.0, required=False)])
    return ([Until("a live knight", _playing, 30.0),
             Repeat(f"monster {graphic} struck by antibody {kind}", one_try, struck, 8)]
            + _alive([([], 0.5)]))


def _villain(which: int) -> list:
    """Object `which` (its record is OBJECTS + 16 * which, and it is the one
    that kills villain `which`) laid where the knight stands, picked up and
    thrown; and the moment it is in flight, its villain put where it is.
    The object's record is updated before the villain's in a turn, so it
    finds the two touching (#R$D80C) before the villain can reach the
    knight."""
    graphic = OBJECT_GRAPHIC + 3 - which
    thing = graphic - 3
    thrown, villain = OBJECTS + 16 * which, VILLAINS + 16 * which
    # First thrown at nothing: it flies until it meets a wall and lies down
    # again (#R$D80C); then picked up again and thrown at the villain.
    return ([Until("a live knight", _playing, 30.0), _lives]
            + _turn(_beside_knight(thrown, graphic))
            + [Until(f"object {graphic} carried", _carrying(thing), 10.0),
               Until(f"object {graphic} thrown", lambda memory: 8 <= memory[thrown] < 12,
                     5.0, keys=["q"]),
               Until(f"object {graphic} lying again", lambda memory: memory[thrown] == graphic,
                     20.0, during=_lives)]
            + _turn(_beside_knight(thrown, graphic))
            + [Until(f"object {graphic} carried", _carrying(thing), 10.0),
               Until(f"object {graphic} thrown", lambda memory: 8 <= memory[thrown] < 12,
                     5.0, keys=["q"])]
            + _turn(_onto_thrown(which))
            + [Until(f"villain {which} struck",
                     lambda memory: memory[villain] == 0 or memory[villain] >= DYING_VILLAIN,
                     10.0)])


def _visited_everywhere(memory) -> None:
    """The visited bit of every cell a new life may start in: a byte for
    each eight columns, four to a row, the column's low three bits the bit
    (#R$BF66)."""
    from nightshade_data import cell

    for v in range(32):
        for u in range(32):
            if cell(memory, u, v) not in (1, 2):
                memory[VISITED + 4 * v + (u >> 3)] |= 1 << (u & 7)


def _quest() -> list:
    """The four objects each thrown at its villain, and the ending that
    follows the last; then back at the menu, a new game."""
    # Every cell visited too, so that the percentage is a hundred (#R$BEDF,
    # #R$BF36): the 625 cells a knight can be in and three for each villain
    # make 637, which the sum turns into exactly 100.
    steps = _start("1") + [_visited_everywhere]
    for which in range(4):
        steps += _villain(which) + _alive([([], 1.0)])
    steps += [Until("the ending", lambda memory: memory[ENDING] != 0, 60.0),
              At("the menu after the ending", MENU_LOOP, 180.0)]
    return steps + _start("1") + _alive(KEYBOARD_ROUND)


def sessions(snapshot: Path, cycles: int) -> list:
    cells = _cells(snapshot)
    keyboard = _start("1") + _alive(KEYBOARD_ROUND * cycles + PAUSE + KEYBOARD_ROUND)
    kempston = _start("2") + _alive(STICK_ROUND * cycles + PAUSE)
    cursor = _start("3") + _alive(CURSOR_ROUND * cycles)
    sinclair = _start("4") + _alive(SINCLAIR_ROUND * cycles)
    # Directional control with the town the usual way round, and turned
    # round, which it reads its own way (#R$DC43).
    directional = _start("2", "5") + _alive(STICK_ROUND * cycles + [(["z"], 0.3), ([], 0.3)]
                                            + STICK_ROUND * cycles)
    tour = _start("1") + _tour(cells, KEYBOARD_ROUND[:5])
    over = (_start("1") + _alive(KEYBOARD_ROUND) + [Until("a live knight", _playing)]
            + _turn(_game_over) + [At("the menu again", MENU_LOOP, 60.0)]
            + _start("1") + _alive(KEYBOARD_ROUND))
    # The two bonuses (#R$D76C): graphic 2 makes him faster for a while,
    # graphic 3 gives him his hits back.
    bonuses = _start("1")
    for graphic in (BONUS_SPEED, BONUS_CURE):
        bonuses += [Until("a live knight", _playing)]
        bonuses += _turn(lambda memory: memory.__setitem__(HITS, 1),
                         _beside_knight(BONUS, graphic))
        bonuses += [Until(f"bonus {graphic} taken",
                          lambda memory: memory[BONUS] in (0, VANISH, VANISH + 1, VANISH + 2,
                                                           VANISH + 3), 10.0)]
        bonuses += _alive(KEYBOARD_ROUND[:8])
    # Long enough for the faster walk to wear off (#R$DA7A).
    bonuses += _alive([([], 5.0)] * 5)
    # What is found in buildings (#R$C5CE): each of the four kinds picked up,
    # then thrown as antibodies (#R$DAB7), and the eleven places filled.
    finds = _start("1")
    for kind in range(4):
        finds += [Until("a live knight", _playing)]
        finds += _turn(_beside_knight(FINDS, FIND_GRAPHIC + 4 * kind))
        finds += [Until(f"find {kind} carried", _carrying(5 + kind), 10.0)]
    finds += _alive([(["q"], 0.2), ([], 0.4)] * 6 + KEYBOARD_ROUND)
    finds += [Until("a live knight", _playing)]
    finds += _turn(lambda memory: memory.__setitem__(slice(CARRIED, CARRIED + 11), bytes([5] * 11)),
                   _beside_knight(FINDS, FIND_GRAPHIC))
    finds += [([], 1.0)]
    # Fire held down: a throw every few turns, until both antibody records
    # are busy and the next replaces one (#R$DAB7).
    finds += _alive([(["q"], 0.2), ([], 0.4)] * 6 + [(["q"], 2.0)] + KEYBOARD_ROUND)
    # Both antibody records busy when he throws: the older is made to vanish
    # instead (#R$DAB7).
    finds += [Until("a live knight", _playing)]
    finds += _turn(lambda memory: memory.__setitem__(CARRIED, 5),
                   _beside_knight(ANTIBODIES, 0x50, du=40), _beside_knight(ANTIBODIES + 16, 0x50, du=-40))
    finds += [(["q"], 0.15), ([], 0.5)]
    # Each kind of antibody at a monster of graphics 112-127, whose fate
    # depends on the two together (#R$C083); at one of 64-79 (#R$CE89); and
    # at the creature of 136-139 (#R$BFF1).
    for kind in range(5, 9):
        finds += _antibody_at(0x70, kind)
    finds += _antibody_at(0x40, 5) + _antibody_at(0x88, 5)
    return [
        ("keyboard", keyboard),
        ("Kempston joystick", kempston),
        ("cursor joystick", cursor),
        ("Interface II", sinclair),
        ("directional control", directional),
        ("every cell", tour),
        ("game over", over),
        ("the bonuses", bonuses),
        ("finds and antibodies", finds),
        ("the villains and the ending", _quest()),
    ]


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

    The same method as build_alien8.py's: seeds are addresses a CPU
    executed, branches are only followed out of those, and the CPU's
    instruction boundaries overrule the decoder's wherever they meet.
    """
    import codemap

    # And the routines the dispatcher at $D593 jumps to through its tables:
    # a jump table is a list of edges, not a guess, and a graphic no session
    # met still has its update routine there.
    seeds = set(executed) | {_word(memory, UPDATES + 2 * graphic)
                             for graphic in range(UPDATE_COUNT)}
    for table, count in JUMP_TABLES:
        seeds |= {_word(memory, table + 2 * index) for index in range(count)}
    # The loader's routine in the printer buffer ran too, in tap2sna's
    # simulated load rather than here; it is followed from its first
    # instruction, and within itself only (its last jump is to the game).
    loader, _, _ = codemap.walk(memory, {LOADER}, LOADER, LOADER + LOADER_LENGTH, (), set())
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
         f"instruction starts ({len(indirect)} indirect jumps stopped it), and "
         f"{len(loader)} in the loader's routine")
    return code | loader

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
    still reassemble. So: the ranges nightshade_data.py owns and the spans the
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

    import nightshade_data

    _log("Generating control file...")
    auto_ctl = _capture(sna2ctl.main, [
        "-m", str(code_map), "-h",
        "-s", str(BLOCK_START), "-e", str(BLOCK_END), str(snapshot),
    ])
    auto_ctl = NEWLINE.join(line for line in auto_ctl.splitlines()
                            if not re.match(r"^@ \$[0-9A-F]{4} (start|org)$", line))
    memory = game_memory(snapshot)
    generated = nightshade_data.data_blocks(memory)
    (OUT_DIR / "nightshade-data.ctl").write_text(generated, encoding="utf-8")
    owned = nightshade_data.OWNED
    spans = declared_spans()
    check_structure(generated, owned, spans)
    merged = take_over(auto_ctl, owned, keep_start=False)
    merged = take_over(merged, spans, keep_start=True)
    dropped = len(auto_ctl.splitlines()) - len(merged.splitlines())
    _log(f"  {len(owned)} generated ranges and {len(spans)} declared spans replaced "
         f"{dropped} of sna2ctl's directives")
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
        structure = OUT_DIR / "nightshade-structure.ctl"
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
    report = OUT_DIR / "nightshade-warnings.txt"
    report.write_text(NEWLINE.join(warnings) + NEWLINE, encoding="utf-8")
    _log(f"  {len(warnings)} warning(s)" + (f" -- see {report.name}" if warnings else ""))
    return len(warnings)


def report_coverage(snapshot: Path, code_map: Path, skool: Path, out: Path) -> None:
    """How much is code, how much data, and which code never ran.

    Written to nightshade-coverage.txt beside the listing, a line per run of
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
    raw = OUT_DIR / "nightshade.rawbin"
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

    The header -- PC at $5E00, the registers and the rest -- is carried
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

# Everything below writes pages that quote the game -- its sprites, its
# tiles, its town -- so, like the disassembly itself, it is built locally and not
# committed. The prose pages are scripts/nightshade.ref, which is.

SPRITE_SCALE = 3


def sprite_image(memory, address: int, scale: int = SPRITE_SCALE):
    """The sprite at `address` as #R$E3D9 draws it, on a clear background.

    The pairs are a mask byte and an image byte, bottom row first. The
    drawing keeps the screen where neither is set, clears it where the mask
    alone is set, and sets it wherever the image is: (screen AND NOT mask)
    OR image. So a set image bit shows whether or not the mask is set, and
    only mask-and-nothing is black.
    """
    from PIL import Image

    width, height = memory[address] & 0x0F, memory[address + 1]
    image = Image.new("RGBA", (width * 8, height), (0, 0, 0, 0))
    pixels = image.load()
    for row in range(height):
        base = address + 2 + row * width * 2
        y = height - 1 - row
        for column in range(width):
            mask, bits = memory[base + 2 * column], memory[base + 2 * column + 1]
            for bit in range(8):
                if bits & (0x80 >> bit):
                    pixels[column * 8 + bit, y] = (255, 255, 255, 255)
                elif mask & (0x80 >> bit):
                    pixels[column * 8 + bit, y] = (0, 0, 0, 255)
    return image.resize((width * 8 * scale, height * scale), Image.NEAREST)


def tile_image(memory, address: int, scale: int = SPRITE_SCALE):
    """A tile, or an edge picture, as #R$D425 and #R$D2B2 draw them: a height
    byte, then two bytes a row, bottom row first. A tile is written over what
    is there, so its clear bits are black; an edge picture is ORed on, but is
    drawn the same way here, to be seen."""
    from PIL import Image

    height = memory[address]
    image = Image.new("RGBA", (16, height), (0, 0, 0, 255))
    pixels = image.load()
    for row in range(height):
        y = height - 1 - row
        for column in range(2):
            bits = memory[address + 1 + 2 * row + column]
            for bit in range(8):
                if bits & (0x80 >> bit):
                    pixels[column * 8 + bit, y] = (255, 255, 255, 255)
    return image.resize((16 * scale, height * scale), Image.NEAREST)


def draw_sprites(snapshot: Path, out_dir: Path) -> int:
    import nightshade_data

    memory = game_memory(snapshot)
    out_dir.mkdir(parents=True, exist_ok=True)
    count = 0
    for address in nightshade_data.picture_sprites(memory):
        sprite_image(memory, address).save(out_dir / nightshade_data.sprite_picture_name(address))
        count += 1
    return count


def draw_tiles(snapshot: Path, out_dir: Path) -> int:
    import nightshade_data

    memory = game_memory(snapshot)
    out_dir.mkdir(parents=True, exist_ok=True)
    count = 0
    for address in nightshade_data.picture_tiles(memory):
        tile_image(memory, address).save(out_dir / nightshade_data.tile_picture_name(address))
        count += 1
    return count


# The generated pages beyond the listing, each family in a module of its own
# beside this script: build(snapshot, html_dir, log) draws its pictures and
# records its sounds into html_dir and returns its ref sections, name to body.
# A module not written yet is skipped, so the pages can arrive one at a time.
PAGE_MODULES = ["nightshade_howitworks", "nightshade_world", "nightshade_graphics",
                "nightshade_animations", "nightshade_sounds", "nightshade_reference"]


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


def build_html(skool: Path, snapshot: Path, out: Path, tape: Path) -> None:
    from skoolkit import skool2html

    import filmation_logos

    _log("Writing HTML disassembly...")
    game_dir = out / "nightshade"
    # The title from the loading screen, for the top of every page
    # (LogoImage in nightshade.ref) and the landing page; written before
    # skool2html, which shows a logo only if the file is there.
    filmation_logos.write_logo("nightshade", tape, game_dir / "images" / "logo.png", _log)
    count = draw_sprites(snapshot, game_dir / "images" / "sprites")
    tiles = draw_tiles(snapshot, game_dir / "images" / "tiles")
    _log(f"  {count} sprites and {tiles} tiles drawn")
    pages_ref = OUT_DIR / "nightshade-pages.ref"
    built = write_pages_ref(snapshot, game_dir, pages_ref)
    _log(f"  page modules: {', '.join(built) if built else 'none yet'}")
    # -a: the pages use the annotations' labels. -S: the style sheets the ref
    # names are beside this script. -o: redraw the images every time.
    args = ["-H", "-a", "-o", "-d", str(out), "-S", str(Path(__file__).resolve().parent),
            str(skool), str(REF), str(pages_ref)]
    _capture(skool2html.main, args)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--tape", required=True, type=Path,
                        help="the Nightshade .tzx or .tap to disassemble")
    parser.add_argument("--html", action="store_true",
                        help="also write a browsable HTML disassembly under "
                             "game_disassembly/nightshade/html/")
    parser.add_argument("--cycles", type=int, default=8,
                        help="rounds of play per playing session (default 8)")
    args = parser.parse_args()

    if not args.tape.exists():
        sys.exit(f"error: {args.tape} not found")
    if not ROM.exists():
        sys.exit(f"error: {ROM} not found -- see README.md for where to get it")

    started = time.time()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    snapshot = OUT_DIR / "nightshade.z80"
    code_map = OUT_DIR / "nightshade.map"
    ctl = OUT_DIR / "nightshade.ctl"
    skool = OUT_DIR / "nightshade.skool"
    asm = OUT_DIR / "nightshade.asm"
    sld = OUT_DIR / "nightshade.sld"
    rebuilt = OUT_DIR / "nightshade-rebuilt.z80"

    make_snapshot(args.tape, snapshot)
    _log("Playing the game to map out which addresses are code...")
    build_code_map(snapshot, code_map, args.cycles)
    warnings = build_asm(snapshot, code_map, ctl, skool, asm)
    report_coverage(snapshot, code_map, skool, OUT_DIR / "nightshade-coverage.txt")
    game_bytes = assemble(asm, sld)
    verify(game_bytes, snapshot)
    write_snapshot(game_bytes, snapshot, rebuilt)
    if args.html:
        build_html(skool, snapshot, OUT_DIR / "html", args.tape)

    _log("")
    _log(f"Wrote {asm}, {sld} and {rebuilt} in {time.time() - started:.0f} s")
    if args.html:
        _log(f"HTML disassembly: {OUT_DIR / 'html' / 'nightshade' / 'index.html'}")
    _log("Load roms/48.rom first, then the .z80 + .sld.")
    if warnings:
        # Everything is written, so the warnings can be looked at in place;
        # but a build with any is not a finished one.
        sys.exit(f"error: {warnings} warning(s) from sna2skool and skool2asm -- see "
                 f"{OUT_DIR / 'nightshade-warnings.txt'}")


if __name__ == "__main__":
    main()
