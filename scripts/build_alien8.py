"""Disassemble Alien 8 (1985, Ultimate Play the Game) from its tape.

THE TAPE. Three files, each a header and a data block: a BASIC loader
"Alien8.1" (LINE 1), "Alien8.2" (CODE 16384,6912) and "Alien8.3" (CODE
25341,40195). The loader is

    1 BORDER NOT PI: PAPER NOT PI: INK NOT PI: CLEAR VAL "25340":
      LOAD "Alien8.2"SCREEN$ : PRINT AT VAL "20",NOT PI;: LOAD "Alien8.3"CODE
   30 RANDOMIZE USR 25344

so the loading screen goes to the screen, CLEAR 25340 puts RAMTOP at $62FC,
and the game block loads from $62FD to the very top of memory, $FFFF.
RANDOMIZE USR 25344 enters it at $6300 -- three bytes in -- which is DI, LD
SP,$F100, NOP and JP $A631. There is no protection and nothing is encrypted:
the block is the game exactly as it runs.

tap2sna runs the ROM's own LOAD on a simulated machine and stops at $6300,
before the game has run a single instruction. That matters here as it does
for Knight Lore and Pentagram: the game turns sprites round in place,
toggling bits in their headers and rewriting their bytes, and rewrites the
rooms' colour bits and the places the valves lie at every new game, so a
snapshot taken once it has run is not the tape any more. The disassembly is of
the loaded image.

WHAT IS DISASSEMBLED: $5B00 to the top of memory. Below the block, from
$5B00, are the game's variables and its 56 object records, which the game
clears before it uses them: their bytes in the snapshot are whatever the
ROM and the BASIC loader left there (the printer buffer, the system
variables, the loader), and are described as the game's work areas. The
block's top end holds bytes that are not the game's -- the loader's machine
saved them along with it, because the block runs on to $FFFF: a copyright
line from 1984, the Spectrum ROM's letters, what looks like Interface 1 ROM
code and its error messages, another font, and stack debris. All of them lie
where the game puts its screen buffer ($D200-$E9FF), its stack (up to
$F100) and its lookup tables ($F100-$FFFF), which it writes before it reads,
so none of them is used; the listing says what each is.

SEPARATING CODE FROM DATA the way the Pentagram build does: play the game in
SkoolKit's simulator from $6300 and record every address executed, in
sessions that pick each control method and start, walk, turn, jump, pick up
and put down, pause, and visit every room; and in staged scenes for what play
will not reach in a sensible time (game over, the chambers, the ending, the
clock running out). Then follow the branches out of what ran
(scripts/codemap.py), which invents nothing. See build_aticatac.py for why
that is the safe direction to be wrong in, and why the round trip at the end
cannot catch data dressed as code.

THE LEVEL DATA -- the room directory, the object templates, the backgrounds,
the places the valves lie, the graphic table, the sprites and the font -- is
laid out a record per line by scripts/alien8_data.py from the snapshot at
every build, so the game's design is never written into a committed file.

The game and everything built from it is copyrighted ((c) 1985 Ultimate Play
the Game / A.C.G.). Built locally, gitignored, never committed. See README.md.

Usage:
    python scripts/build_alien8.py --tape "path/to/Alien 8.tap" [--html]
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
OUT_DIR = PROJECT_ROOT / "game_disassembly" / "alien8"
# Hand-written comments, layered over the generated control file. Source, not
# output: addresses and prose only, so it is committed.
ANNOTATIONS = PROJECT_ROOT / "scripts" / "alien8_annotations.ctl"
REF = PROJECT_ROOT / "scripts" / "alien8.ref"
ROM = PROJECT_ROOT / "roms" / "48.rom"
SJASMPLUS = PROJECT_ROOT / "tools" / "sjasmplus" / "sjasmplus.exe"

# Where RANDOMIZE USR 25344 enters the game, and where tap2sna stops.
ENTRY = 0x6300
# The disassembly: the game's variables and object records below the block,
# the block, and everything it overlaps above.
BLOCK_START = 0x5B00
BLOCK_END = 0x10000
# The game block on the tape: $62FD (CLEAR 25340 + 1) to the top of memory.
LOADED_START = 0x62FD
LOADED_END = 0x10000
# The code, for following branches: from the entry to the end of the
# game's own bytes, before the screen buffer.
DESCENT_START = 0x6300
DESCENT_END = 0xD200

TSTATES_PER_SECOND = 3500000
NEWLINE = chr(10)

# The update routine for each graphic: a word each, the main loop's jump
# table (see alien8_data.py, which lays it out).
HANDLERS = 0xA7EA
HANDLER_COUNT = 131


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
    """Simulate the real LOAD, stopping where USR 25344 enters the game."""
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
CONTROL = 0x5B04            # bits 1-2: 0 keyboard, 1 Kempston, 2 cursor, 3 Interface II;
                            # bit 3 directional control
LIVES = 0x5B1A
GAME_OVER = 0x5B24          # 1 while the re-programming scene after a game runs
PLAYER = 0x5B88             # the robot's legs; his top is the next record
PLAYER_TOP = 0x5BA8
PLAYER_ROOM = 0x5B90        # +8 of his record
# The two records a new life copies into the player's (#R$CA07): +1 and
# +2 of each are the U and V he appears at, +8 the room.
START_LEGS = 0xCA1D
START_TOP = 0xCA3D
# The places the valves (and the extra lives) lie: 36 records of 9 bytes,
# +0 the graphic and +5-+8 the U, V, Z and room it is at now (#R$AE99).
PLACES = 0x76E3
PLACE_SIZE = 9
# A room's two records for what lies in it from the places (#R$AE99): the
# first holds the first place in the table that is in the room.
VALVE = 0x5BC8
ROOM_RECORDS = 0x5C08       # records 4-55: what the room builder makes
# The three carried things, four bytes each; the last is put down next
# (#R$BD6B).
CARRIED_LAST = 0x5B84
CHAMBERS = 0x5B40           # chambers activated, BCD; 24 ends the game
WON = 0x5B23                # set with the twenty-fourth
CLOCK = 0x5B36              # the light years left: four bytes (#R$AD66)
CLOCK_TICK = 0xAD66         # where the main loop counts them down, once a turn
VALVE_GRAPHIC = 96          # 96-99: the four kinds of valve
EXTRA_LIFE = 12             # the graphic that gives a life when touched (#R$BEE0)
SOCKETS = range(112, 116)   # a chamber's socket, one graphic per kind of valve
# The graphics his legs have while he is walking about: 16-23, two views
# (from behind and from the front) of four step frames each; the four
# facings come from bit 2 of the graphic and the mirror flag (the update
# routine at $C0BE). While he turns they are 24-27, the part-way views.
LEGS = range(16, 24)
# The first graphic of the sparkle he dies in (#R$B39A).
DYING = 0x30

# Kempston bits, as IN A,($1F) reads them at #R$C954.
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
    was right once stays right: each step waits for what it means (in a room,
    at the menu) and the build stops, saying which, if that never comes.
    """

    def __init__(self, what: str, test, seconds: float = 20.0, keys=(), stick: int = 0):
        self.what, self.test, self.seconds = what, test, seconds
        self.keys, self.stick = keys, stick


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
    """The game on a simulated 48K Spectrum, from the snapshot at $6300."""

    def __init__(self, snapshot: Path, executed: set | None = None):
        from skoolkit import CSimulator, read_bin_file
        from skoolkit.simulator import Simulator
        from skoolkit.simutils import SP

        memory = list(game_memory(snapshot))
        memory[:0x4000] = read_bin_file(str(ROM))
        self.simulator = (CSimulator or Simulator)(
            memory, state={"iff": 0, "im": 1, "tstates": 0})
        # The game's first instructions set their own stack; this one only
        # has to be somewhere harmless until then.
        self.simulator.registers[SP] = ENTRY
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


def _playing(memory) -> bool:
    """In a room and walking about: his legs have one of their eight graphics
    (not the materialising at a new life, nor the sparkle of a death)."""
    return memory[PLAYER] in LEGS


def _in_room(room: int):
    return lambda memory: memory[PLAYER_ROOM] == room and _playing(memory)


def _in_game_over(memory) -> bool:
    """The re-programming scene after a game (#R$B761 sets the flag)."""
    return memory[GAME_OVER] != 0


def _at_menu(memory) -> bool:
    """Back at the menu after a game: the scene is over and the object
    records have been cleared (#R$A647)."""
    return memory[GAME_OVER] == 0 and memory[PLAYER] == 0 and memory[PLAYER_TOP] == 0


def _lives(memory) -> None:
    """Five lives, whatever has happened: the sessions die a lot."""
    memory[LIVES] = 5


def _kill(memory) -> None:
    """Start his death the way #R$B39A does: both records turned into the
    first frame of the sparkle and out of collisions. The sparkle runs its
    frames, empties the records, and the main loop starts a new life."""
    for record in (PLAYER, PLAYER_TOP):
        memory[record] = DYING
        memory[record + 7] |= 0x02


def _go(room: int, spot: tuple[int, int] | None = None) -> list:
    """Into a room by the game's own restart: the room -- and, if given, the
    U and V to appear at -- goes where a new life copies the player from
    (#R$CA07), and a death ends this life. Without a spot he appears where
    he last came through a doorway, which in another room may be inside
    something, or something deadly; the tour does not mind."""
    def poke(memory):
        _lives(memory)
        for record in (START_LEGS, START_TOP):
            memory[record + 8] = room
            if spot is not None:
                memory[record + 1], memory[record + 2] = spot
        _kill(memory)
    return [Until("a live player", _playing, 30.0), poke,
            Until(f"room ${room:02X}", _in_room(room), 30.0), ([], 0.5)]


def _start(*choices: str) -> list:
    """From the menu, with a control method, through the start tune into
    the first room."""
    steps = [([], 1.0)]
    for choice in choices:
        steps += [([choice], 0.3), ([], 0.5)]
    return steps + [(["0"], 0.3), Until("the first room", _playing, 30.0), ([], 0.5)]


# A round of keyboard play (#R$C9A5 reads the rows): walk (the A-G and H-ENTER
# rows), turn both ways (CAPS-V, and SPACE-B), jump (the Q-T and Y-P rows),
# and pick up or put down (1-0).
KEYBOARD_ROUND = [
    (["a"], 1.2), (["z"], 0.15), (["h"], 1.0), (["x"], 0.15), (["s"], 1.5),
    (["q"], 0.3), ([], 0.6), (["a", "e"], 0.8), (["w"], 0.2), ([], 0.5),
    (["m"], 0.15), (["ENTER"], 1.2), (["1"], 0.2), ([], 0.5),
    (["b"], 0.15), (["d"], 1.0), (["r"], 0.2), (["u"], 0.3), (["6"], 0.2),
    (["n"], 0.15), (["g"], 1.5), (["p"], 0.2), (["o"], 0.3), ([], 0.4),
    (["SS"], 0.15), (["c"], 0.15), (["v"], 0.15), (["j"], 1.0),
]
# The same with a Kempston joystick (#R$C954): left and right turn, up walks,
# fire jumps, down picks up and puts down.
STICK_ROUND = [
    ([], 1.2, J_UP), ([], 0.15, J_LEFT), ([], 1.0, J_UP), ([], 0.15, J_RIGHT),
    ([], 0.3, J_FIRE), ([], 0.6), ([], 0.8, J_UP | J_FIRE), ([], 0.2, J_DOWN),
    ([], 0.4), ([], 1.0, J_UP | J_LEFT), ([], 0.2, J_DOWN), ([], 1.2, J_UP),
]
# Cursor keys (#R$C979): 5 left, 8 right, 7 walk, 0 jump, 6 pick up.
CURSOR_ROUND = [
    (["7"], 1.2), (["5"], 0.15), (["7"], 1.0), (["8"], 0.15), (["0"], 0.3),
    ([], 0.5), (["6"], 0.2), ([], 0.4), (["7", "8"], 1.0), (["6"], 0.2), ([], 0.4),
]
# Interface II, the first stick: 6 left, 7 right, 8 down, 9 up, 0 fire.
SINCLAIR_ROUND = [
    (["9"], 1.2), (["6"], 0.15), (["9"], 1.0), (["7"], 0.15), (["0"], 0.3),
    ([], 0.5), (["8"], 0.2), ([], 0.4), (["9", "7"], 1.0), (["8"], 0.2), ([], 0.4),
]
# SPACE on its own pauses; SPACE again goes on (#R$CE22).
PAUSE = [(["SPACE"], 0.2), ([], 1.0), (["SPACE"], 0.2), ([], 0.5)]


def _rooms(snapshot: Path) -> list[int]:
    from alien8_data import room_records

    return [record["number"] for record in room_records(game_memory(snapshot))]


def _alive(steps: list) -> list:
    """Steps with the lives topped up before each: rooms are deadly, and a
    session that ran out of lives would spend the rest of itself at the menu."""
    out = []
    for step in steps:
        out += [_lives, step]
    return out


def _tour(rooms: list[int], seconds: float, round_=KEYBOARD_ROUND[:6]) -> list:
    """Every room in turn, a few seconds of walking in each."""
    steps = []
    for room in rooms:
        steps += _go(room) + _alive(round_ + [([], seconds)])
    return steps


def _game_over(memory) -> None:
    """No lives left, and dying: the new life #R$CA07 would start finds none
    to take, and it is over."""
    memory[LIVES] = 0
    _kill(memory)


def _put(place: int, graphic: int, room: int, u: int, v: int, z: int):
    """A place record holding `graphic` at U, V, Z in `room`: what the next
    visit to that room builds into its first free valve record."""
    def poke(memory):
        record = PLACES + PLACE_SIZE * place
        memory[record] = graphic
        memory[record + 5:record + 9] = bytes((u, v, z, room))
    return poke


def _beside_valve(memory) -> None:
    """The player just short of the valve in V, near enough to pick it up
    (#R$BEA7 widens his box by four each way)."""
    u, v = memory[VALVE + 1], memory[VALVE + 2]
    for record in (PLAYER, PLAYER_TOP):
        memory[record + 1], memory[record + 2] = u, v - 14


# Chambers, one of each kind of socket (the room data's object templates
# 24-27), and a spot in each room that is clear of what is deadly there.
CHAMBER_ROOMS = [(0x0C, 0), (0x62, 1), (0x1D, 2), (0x0A, 3)]
LAST_CHAMBER = (0x41, 1)
CLEAR_SPOT = (96, 160)
# The room the simulator's games start in: the seed at $5B00 picks one of
# four (#R$CA6D), and a simulated start is the same every time.
START_ROOM = 0x4E
PRESS = [_lives, (["1"], 0.2), ([], 0.8)]


def _over_socket(memory) -> None:
    """The valve, if it has not found the socket by itself, held high above
    it to fall on it: in some rooms the socket stands on something, and the
    valve steering itself arrives underneath."""
    if not VALVE_GRAPHIC <= memory[VALVE] < VALVE_GRAPHIC + 4:
        return
    for record in range(PLAYER, PLAYER + 56 * 32, 32):
        if memory[record] in SOCKETS:
            memory[VALVE + 1], memory[VALVE + 2] = memory[record + 1], memory[record + 2]
            memory[VALVE + 3] = memory[record + 3] + 30
            return
    sys.exit("error: staged chamber: no socket in the room")


def _chamber(place: int, room: int, kind: int, count: int) -> list:
    """A valve of the socket's kind put high in the chamber's room, and held
    over the socket: it falls on it (#R$AF79 steers it the last of the way),
    and the chamber is activated and counted. Waiting on the room and the
    count, not on the player: the twenty-fourth ends the game before he has
    finished appearing."""
    def poke(memory):
        _lives(memory)
        for record in (START_LEGS, START_TOP):
            memory[record + 8] = room
            memory[record + 1], memory[record + 2] = CLEAR_SPOT
        _kill(memory)
    return [_put(place, VALVE_GRAPHIC + kind, room, 128, 128, 200),
            Until("a live player", _playing, 30.0), poke,
            Until(f"room ${room:02X} built with the valve in it",
                  lambda memory: (memory[PLAYER_ROOM] == room
                                  and memory[VALVE] in (VALVE_GRAPHIC + kind, VALVE_GRAPHIC + 4 + kind)),
                  30.0),
            _over_socket,
            Until(f"chamber ${room:02X} activated", lambda memory: memory[CHAMBERS] == count, 30.0)]


def _chambers() -> list:
    """Every kind of chamber activated, one revisited, then the last of the
    24 (the count staged at 23) and the ending, back to the menu, and a new
    game after it -- which puts the rooms' colours back (#R$CAD2)."""
    steps = _start("1")
    for place, (room, kind) in enumerate(CHAMBER_ROOMS):
        steps += _chamber(place, room, kind, place + 1)
        steps += _alive([([], 1.0), (["a"], 0.5), ([], 0.5)])
    steps += _go(CHAMBER_ROOMS[0][0], CLEAR_SPOT) + _alive([([], 1.5), (["a"], 0.5)])
    room, kind = LAST_CHAMBER
    steps += [lambda memory: memory.__setitem__(CHAMBERS, 0x23)]
    steps += _chamber(len(CHAMBER_ROOMS), room, kind, 0x24)
    steps += [Until("the twenty-fourth chamber", lambda memory: memory[WON] != 0, 10.0),
              Until("the scene after the ending", _in_game_over, 90.0),
              Until("the menu after the ending", _at_menu, 120.0)]
    return steps + _start("1") + _alive(KEYBOARD_ROUND)


def _records_of(memory, graphics) -> list[int]:
    """The room's object records holding any of the graphics, in order."""
    return [record for record in range(ROOM_RECORDS, PLAYER + 56 * 32, 32)
            if memory[record] in graphics]


def _onto(graphic: int, which: int = 0):
    """The player dropped on top of the room's `which`th object of a graphic
    -- a button, a pad -- to land on it the way a jump would."""
    def poke(memory):
        records = _records_of(memory, (graphic,))
        if len(records) <= which:
            sys.exit(f"error: staged scene: no graphic {graphic} number {which} in the room")
        record = records[which]
        for part in (PLAYER, PLAYER_TOP):
            memory[part + 1], memory[part + 2] = memory[record + 1], memory[record + 2]
        memory[PLAYER + 3] = memory[record + 3] + memory[record + 6] + 8
        memory[PLAYER_TOP + 3] = memory[PLAYER + 3] + 12
    return poke


def _under(graphic: int):
    """The player on the floor straight under the room's first object of a
    graphic."""
    def poke(memory):
        records = _records_of(memory, (graphic,))
        if not records:
            sys.exit(f"error: staged scene: no graphic {graphic} in the room")
        for part in (PLAYER, PLAYER_TOP):
            memory[part + 1], memory[part + 2] = memory[records[0] + 1], memory[records[0] + 2]
    return poke


# The remote-controlled robots (graphics 124-127): a room of them, with the
# buttons that drive them (122 and 123, two of each) and the pad (128) that
# stops them. Landing on one sets the robots' orders at $5B42 (#R$AA63).
REMOTE_ROOM = 0x0B
BUTTONS = [(122, 0), (123, 0), (128, 0), (122, 1), (123, 1)]
# The things that drop from the ceiling when the player is under them
# (graphic 73, #R$AD13) -- but only once something has been picked up in
# an even-numbered room ($5B3B, cleared by a pick-up), and only on a turn
# the random byte at $5B05 is under 16, which the scene makes this turn.
DROP_ROOM = 0x1C
DROP_LATCH = 0x5B3B
DROP_TEST = 0xAD2A
RANDOM = 0x5B05


def sessions(snapshot: Path, cycles: int) -> list:
    rooms = _rooms(snapshot)
    keyboard = _start("1") + _alive(KEYBOARD_ROUND * cycles + PAUSE + KEYBOARD_ROUND)
    kempston = _start("2") + _alive(STICK_ROUND * cycles + PAUSE)
    cursor = _start("3") + _alive(CURSOR_ROUND * cycles)
    sinclair = _start("4") + _alive(SINCLAIR_ROUND * cycles)
    directional = _start("2", "5") + _alive(STICK_ROUND * cycles)
    tour = _start("1") + _tour(rooms, 3.0, KEYBOARD_ROUND[:14])
    over = (_start("1") + _alive(KEYBOARD_ROUND) + [Until("a live player", _playing), _game_over,
                                                    Until("the game-over scene", _in_game_over, 60.0),
                                                    Until("the menu again", _at_menu, 120.0)]
            + _start("1") + _alive(KEYBOARD_ROUND))
    # A valve beside him in the start room: picked up, passed along the
    # three carried places (each press moves them on, #R$BE60), put down.
    valves = (_start("1") + [_put(0, VALVE_GRAPHIC + 1, START_ROOM, 128, 156, 64)]
              + _go(START_ROOM, (128, 128))
              + [_lives, _beside_valve, ([], 0.3),
                 Repeat("the valve carried, next to put down", PRESS,
                        lambda memory: memory[CARRIED_LAST] != 0, 4),
                 (["z"], 0.3), (["a"], 0.6),
                 Repeat("the valve put down", PRESS,
                        lambda memory: memory[CARRIED_LAST] == 0, 2)]
              + _alive(KEYBOARD_ROUND))
    # An extra life lying against where he appears: #R$BEE0 widens his box
    # by one, finds it touching, gives a life and empties its place.
    extra = (_start("1") + [_put(1, EXTRA_LIFE, START_ROOM, 128, 140, 64)]
             + _go(START_ROOM, (128, 128))
             + [Until("the extra life taken",
                      lambda memory: memory[PLACES + PLACE_SIZE] == 0, 10.0)]
             + _alive(KEYBOARD_ROUND[:6]))
    # The clock all but out as #R$AD66 starts its turn. (0,0,0,1) is the
    # last digit 0 still rolling one row -- each byte's low three bits are a
    # roll count -- and the turn's count runs it out and ends the game; one
    # whole light year left would be (0,0,0,$10). Poked anywhere else in the
    # turn, the half-done borrow can wrap the count round to 9s instead.
    clock = (_start("1") + _alive(KEYBOARD_ROUND[:6])
             + [At("the clock's turn", CLOCK_TICK),
                lambda memory: memory.__setitem__(slice(CLOCK, CLOCK + 4), bytes((0, 0, 0, 1))),
                Until("the scene after the clock ran out", _in_game_over, 90.0),
                Until("the menu again", _at_menu, 120.0)])
    remote = _start("1") + _go(REMOTE_ROOM, CLEAR_SPOT)
    for graphic, which in BUTTONS:
        remote += [_lives, _onto(graphic, which), ([], 3.0)]
    drop = (_start("1") + _go(DROP_ROOM, CLEAR_SPOT)
            + [_lives, _under(73), lambda memory: memory.__setitem__(DROP_LATCH, 0),
               At("the drop's random test", DROP_TEST),
               lambda memory: memory.__setitem__(RANDOM, 0), ([], 3.0)])
    return [
        ("keyboard", keyboard),
        ("Kempston joystick", kempston),
        ("cursor joystick", cursor),
        ("Interface II", sinclair),
        ("directional control", directional),
        ("every room", tour),
        ("game over", over),
        ("valves carried", valves),
        ("an extra life", extra),
        ("the chambers and the ending", _chambers()),
        ("the clock runs out", clock),
        ("remote control", remote),
        ("things that drop", drop),
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

    The same method as build_pentagram.py's (and build_hobbit.py's, which
    says at length why): seeds are addresses a CPU executed, branches are
    only followed out of those, and the CPU's instruction boundaries overrule
    the decoder's wherever they meet.
    """
    import codemap

    # And the update routines, one per graphic, that the main loop jumps to
    # through the table at $A7EA (JP (HL) at $A6BF): a jump table is a list
    # of edges, not a guess, and a graphic no session met still has its
    # routine there.
    seeds = set(executed) | {_word(memory, HANDLERS + 2 * graphic)
                             for graphic in range(HANDLER_COUNT)}
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
    still reassemble. So: the ranges alien8_data.py owns and the spans the
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

    import alien8_data

    _log("Generating control file...")
    auto_ctl = _capture(sna2ctl.main, [
        "-m", str(code_map), "-h",
        "-s", str(BLOCK_START), "-e", str(BLOCK_END), str(snapshot),
    ])
    auto_ctl = NEWLINE.join(line for line in auto_ctl.splitlines()
                            if not re.match(r"^@ \$[0-9A-F]{4} (start|org)$", line))
    memory = game_memory(snapshot)
    generated = alien8_data.data_blocks(memory)
    (OUT_DIR / "alien8-data.ctl").write_text(generated, encoding="utf-8")
    owned = alien8_data.OWNED
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
        structure = OUT_DIR / "alien8-structure.ctl"
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
    report = OUT_DIR / "alien8-warnings.txt"
    report.write_text(NEWLINE.join(warnings) + NEWLINE, encoding="utf-8")
    _log(f"  {len(warnings)} warning(s)" + (f" -- see {report.name}" if warnings else ""))
    return len(warnings)


def report_coverage(snapshot: Path, code_map: Path, skool: Path, out: Path) -> None:
    """How much is code, how much data, and which code never ran.

    Written to alien8-coverage.txt beside the listing, a line per run of
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
    raw = OUT_DIR / "alien8.rawbin"
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

    The header -- PC at $6300, the registers and the rest -- is carried
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
# rooms -- so, like the disassembly itself, it is built locally and not
# committed. The prose pages are scripts/alien8.ref, which is.

SPRITE_SCALE = 3


def sprite_image(memory, address: int, scale: int = SPRITE_SCALE):
    """The sprite at `address` as #R$D013 draws it, on a clear background.

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


def draw_sprites(snapshot: Path, out_dir: Path) -> int:
    import alien8_data

    memory = game_memory(snapshot)
    out_dir.mkdir(parents=True, exist_ok=True)
    count = 0
    for address in alien8_data.picture_sprites(memory):
        sprite_image(memory, address).save(out_dir / alien8_data.sprite_picture_name(address))
        count += 1
    return count


# The generated pages beyond the listing, each family in a module of its own
# beside this script: build(snapshot, html_dir, log) draws its pictures and
# records its sounds into html_dir and returns its ref sections, name to body.
# A module not written yet is skipped, so the pages can arrive one at a time.
PAGE_MODULES = ["alien8_howitworks", "alien8_world", "alien8_graphics",
                "alien8_animations", "alien8_sounds", "alien8_reference"]


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
    game_dir = out / "alien8"
    # The title from the loading screen, for the top of every page
    # (LogoImage in alien8.ref) and the landing page; written before
    # skool2html, which shows a logo only if the file is there.
    filmation_logos.write_logo("alien8", tape, game_dir / "images" / "logo.png", _log)
    count = draw_sprites(snapshot, game_dir / "images" / "sprites")
    _log(f"  {count} sprites drawn")
    pages_ref = OUT_DIR / "alien8-pages.ref"
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
                        help="the Alien 8 .tap or .tzx to disassemble")
    parser.add_argument("--html", action="store_true",
                        help="also write a browsable HTML disassembly under "
                             "game_disassembly/alien8/html/")
    parser.add_argument("--cycles", type=int, default=8,
                        help="rounds of play per playing session (default 8)")
    args = parser.parse_args()

    if not args.tape.exists():
        sys.exit(f"error: {args.tape} not found")
    if not ROM.exists():
        sys.exit(f"error: {ROM} not found -- see README.md for where to get it")

    started = time.time()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    snapshot = OUT_DIR / "alien8.z80"
    code_map = OUT_DIR / "alien8.map"
    ctl = OUT_DIR / "alien8.ctl"
    skool = OUT_DIR / "alien8.skool"
    asm = OUT_DIR / "alien8.asm"
    sld = OUT_DIR / "alien8.sld"
    rebuilt = OUT_DIR / "alien8-rebuilt.z80"

    make_snapshot(args.tape, snapshot)
    _log("Playing the game to map out which addresses are code...")
    build_code_map(snapshot, code_map, args.cycles)
    warnings = build_asm(snapshot, code_map, ctl, skool, asm)
    report_coverage(snapshot, code_map, skool, OUT_DIR / "alien8-coverage.txt")
    game_bytes = assemble(asm, sld)
    verify(game_bytes, snapshot)
    write_snapshot(game_bytes, snapshot, rebuilt)
    if args.html:
        build_html(skool, snapshot, OUT_DIR / "html", args.tape)

    _log("")
    _log(f"Wrote {asm}, {sld} and {rebuilt} in {time.time() - started:.0f} s")
    if args.html:
        _log(f"HTML disassembly: {OUT_DIR / 'html' / 'alien8' / 'index.html'}")
    _log("Load roms/48.rom first, then the .z80 + .sld.")
    if warnings:
        # Everything is written, so the warnings can be looked at in place;
        # but a build with any is not a finished one.
        sys.exit(f"error: {warnings} warning(s) from sna2skool and skool2asm -- see "
                 f"{OUT_DIR / 'alien8-warnings.txt'}")


if __name__ == "__main__":
    main()
