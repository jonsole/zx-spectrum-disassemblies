"""Disassemble Pentagram (1986, Ultimate Play the Game) from its tape.

THE TAPE. Three files, each a header and a data block: a one-line BASIC
loader "pent" (LINE 1), "pp" (CODE 24576,6912) and "game" (CODE
24064,31390). The loader is

    1 BORDER 0: INK 0: PAPER 0: CLS : PRINT AT 19,0;" ";: CLEAR 24064:
      LOAD ""SCREEN$ : PRINT AT 19,0;: LOAD ""CODE 24064: PRINT USR 24064

so the loading screen, whatever the address in its header says, goes to the
screen: LOAD ""SCREEN$ loads 6912 bytes to 16384 and ignores the header's
24576. CLEAR 24064 puts RAMTOP and the machine stack just below $5E00, and
the game block loads from $5E00 to $D89D. USR 24064 enters it at $5E00, which
is DI, LD SP,$5E00 and JP $AF87. There is no protection and nothing is
encrypted: the block is the game exactly as it runs.

tap2sna runs the ROM's own LOAD on a simulated machine and stops at $5E00,
before the game has run a single instruction. That matters here more than
usual: the game mirrors and flips sprites in place, toggling bits in their
headers and rewriting their bytes, so a snapshot taken once it has drawn
anything is not the tape any more. The disassembly is of the loaded image.

WHAT IS DISASSEMBLED: $5E00 to the top of memory. The block ends at $D89D;
everything above it the game builds at run time -- the screen buffer rooms
are drawn into (it starts at $D88F, in the block's last bytes), a bit-reversal
table at $F100 and tables of pre-shifted masks at $F200-$FFFF -- and those are
described as buffers, their bytes whatever the snapshot holds.

SEPARATING CODE FROM DATA the way the Ant Attack build does: play the game in
SkoolKit's simulator from $5E00 and record every address executed, in
sessions that pick each control method and start, walk, turn, jump, fire,
pick up and put down, pause, and visit every room; and in staged scenes for
what play will not reach in a sensible time. Then follow the branches out of
what ran (scripts/codemap.py), which invents nothing. See build_aticatac.py
for why that is the safe direction to be wrong in, and why the round trip at
the end cannot catch data dressed as code.

THE LEVEL DATA -- the room directory, the scenery and object templates, the
graphic table, the sprites and the font -- is laid out a record per line by
scripts/pentagram_data.py from the snapshot at every build, so the game's
design is never written into a committed file.

The game and everything built from it is copyrighted ((c) 1986 Ultimate Play
the Game / A.C.G.). Built locally, gitignored, never committed. See README.md.

Usage:
    python scripts/build_pentagram.py --tape "path/to/Pentagram.tzx" [--html]
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
OUT_DIR = PROJECT_ROOT / "game_disassembly" / "pentagram"
# Hand-written comments, layered over the generated control file. Source, not
# output: addresses and prose only, so it is committed.
ANNOTATIONS = PROJECT_ROOT / "scripts" / "pentagram_annotations.ctl"
REF = PROJECT_ROOT / "scripts" / "pentagram.ref"
ROM = PROJECT_ROOT / "roms" / "48.rom"
SJASMPLUS = PROJECT_ROOT / "tools" / "sjasmplus" / "sjasmplus.exe"

# Where USR 24064 enters the game, and where tap2sna stops.
ENTRY = 0x5E00
# The disassembly: the game block and everything above it.
BLOCK_START = 0x5E00
BLOCK_END = 0x10000
# The end of the game block on the tape; above it is only what the game
# builds while it runs.
LOADED_END = 0xD89E
# The code, for following branches: from the entry to the end of the block.
DESCENT_START = 0x5E00
DESCENT_END = LOADED_END

TSTATES_PER_SECOND = 3500000
NEWLINE = chr(10)

# The update routine for each graphic: a word each, the main loop's jump
# table (see pentagram_data.py, which lays it out).
HANDLERS = 0xAE2F
GRAPHIC_COUNT = 172


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
    """Simulate the real LOAD, stopping where USR 24064 enters the game."""
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
CONTROL = 0xA709            # bits 1-2: 0 keyboard, 1 Kempston, 2 cursor, 3 Interface II
PLAYER = 0xA76F             # the player's legs; his body is the next record
PLAYER_ROOM = 0xA777        # +8 of his record
PLAYER_STATE = 0xA77C       # +$0D: bit 6 set means killed
TEMPLATE_ROOM = 0xC407      # +8 of the player template restarts copy back
LIVES = 0xA721
DROP_TIMER = 0xA73D         # turns to the next thing falling from the sky
TURN = 0xA715               # the turn counter, a word
CARRIED = 0xA722            # four entries of four bytes; +$0C is put down next
BUCKET_OUT = 0xA70E
PENTAGRAM_ON = 0xA70F
QUEST_DONE = 0xA74C
PLACED = 0xA74B
QUEST_RECORDS = 0xD432      # 18 records of 16 bytes, copied from $D312 at a new game
QUEST_SIZE = 16
ROOM_PENTAGRAM = 82

# Kempston bits, as IN A,($1F) reads them at #R$BE40.
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
    variable number of tries, like a well that gives a bucket only after
    enough shots."""

    def __init__(self, what: str, steps: list, test, times: int):
        self.what, self.steps, self.test, self.times = what, steps, test, times


class Machine:
    """The game on a simulated 48K Spectrum, from the snapshot at $5E00."""

    def __init__(self, snapshot: Path, executed: set | None = None):
        from skoolkit import CSimulator, read_bin_file
        from skoolkit.simulator import Simulator
        from skoolkit.simutils import SP

        memory = list(game_memory(snapshot))
        memory[:0x4000] = read_bin_file(str(ROM))
        self.simulator = (CSimulator or Simulator)(
            memory, state={"iff": 0, "im": 1, "tstates": 0})
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
    """In a room, alive and not dying: his legs have a graphic and the
    killed bit is clear."""
    return memory[PLAYER] != 0 and not memory[PLAYER_STATE] & 0x40


def _in_room(room: int):
    return lambda memory: memory[PLAYER_ROOM] == room and _playing(memory)


def _at_menu(memory) -> bool:
    """Back at the menu after a game: #R$AF93 has cleared the variables and
    the object records, so there is no player and no turn counted."""
    return memory[PLAYER] == 0 and memory[TURN] == 0 and memory[TURN + 1] == 0


def _lives(memory) -> None:
    """Five lives, BCD, whatever has happened: the sessions die a lot."""
    memory[LIVES] = 0x05


def _go(room: int) -> list:
    """Into a room by the game's own restart: the room goes where the restart
    copies the player from (#R$C2EC), and the killed bit ends this life."""
    def poke(memory):
        _lives(memory)
        memory[PLAYER_ROOM] = room
        memory[TEMPLATE_ROOM] = room
        memory[PLAYER_STATE] |= 0x40
    return [Until("a live player", _playing), poke,
            Until(f"room {room}", _in_room(room), 30.0), ([], 0.5)]


def _start(choice: str) -> list:
    """From the menu, with a control method, through the start tune into
    the first room."""
    return [([], 1.0), ([choice], 0.3), ([], 0.5), (["0"], 0.3),
            Until("the first room", _playing, 30.0), ([], 0.5)]


# A round of keyboard play: walk (the A-G and H-ENTER rows), turn both ways
# (CAPS-V, and SPACE-B), jump (Q E T U O), fire (W R Y I P), and pick up or
# put down (1-0). Rotational control: every walk is the way he faces.
KEYBOARD_ROUND = [
    (["a"], 1.2), (["z"], 0.15), (["h"], 1.0), (["x"], 0.15), (["s"], 1.5),
    (["q"], 0.3), ([], 0.6), (["a", "e"], 0.8), (["w"], 0.2), ([], 0.5),
    (["m"], 0.15), (["ENTER"], 1.2), (["1"], 0.2), ([], 0.5),
    (["b"], 0.15), (["d"], 1.0), (["r"], 0.2), (["u"], 0.3), (["6"], 0.2),
    (["n"], 0.15), (["g"], 1.5), (["p"], 0.2), (["o"], 0.3), ([], 0.4),
    (["SS"], 0.15), (["c"], 0.15), (["v"], 0.15), (["j"], 1.0),
]
# The same with a Kempston joystick: left and right turn, up walks, down
# jumps, fire fires; the bottom row's keys pick up and put down.
STICK_ROUND = [
    ([], 1.2, J_UP), ([], 0.15, J_LEFT), ([], 1.0, J_UP), ([], 0.15, J_RIGHT),
    ([], 0.3, J_DOWN), ([], 0.6), ([], 0.8, J_UP | J_DOWN), ([], 0.2, J_FIRE),
    ([], 0.4), (["z"], 0.2), ([], 0.4), ([], 1.0, J_UP | J_LEFT), (["b"], 0.2),
    ([], 1.2, J_UP),
]
# Cursor keys: 5 left, 8 right, 7 walk, 6 jump, 0 fire.
CURSOR_ROUND = [
    (["7"], 1.2), (["5"], 0.15), (["7"], 1.0), (["8"], 0.15), (["6"], 0.3),
    ([], 0.5), (["0"], 0.2), ([], 0.4), (["x"], 0.2), ([], 0.4), (["7", "8"], 1.0),
]
# Interface II, the first stick: 6 left, 7 right, 8 down, 9 up, 0 fire --
# and the second, 1-5, which the game reads in the same half-row pass.
SINCLAIR_ROUND = [
    (["9"], 1.2), (["6"], 0.15), (["9"], 1.0), (["7"], 0.15), (["8"], 0.3),
    ([], 0.5), (["0"], 0.2), ([], 0.4), (["c"], 0.2), ([], 0.4), (["4"], 1.0),
    (["1"], 0.15), (["2"], 0.15), (["3"], 0.3), (["5"], 0.2),
]
# SPACE on its own pauses; SPACE again goes on (#R$B4E0).
PAUSE = [(["SPACE"], 0.2), ([], 1.0), (["SPACE"], 0.2), ([], 0.5)]


def _rooms(snapshot: Path) -> list[int]:
    from pentagram_data import room_records

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
    """No lives left, and killed: #R$C2EC finds none to take, and it is over."""
    memory[LIVES] = 0
    memory[PLAYER_STATE] |= 0x40


def _drop_soon(memory) -> None:
    """Something falls from the sky within a turn or two (#R$CBAB)."""
    memory[DROP_TIMER] = 1


# The quest, as the game sets it: a well gives a bucket when it has been
# shot at enough (#R$CFD2 counts the bolts that touch it); a bucket put down
# where a quest item is flies to it (#R$D0AC), and the item is done
# (#R$CF68); when all four are, the pentagram's pieces appear in room 82
# (#R$D13A); and the five collectables brought there fly to their places
# (#R$CD16), the fifth ending the game (#R$C302). The sessions stage only
# where things are -- the player beside the well or the bucket, the
# collectables already in room 82 -- and let the game do the rest.
WELL_ROOM = 71              # a well with no monsters, ringed by still hazards
WELL_SPOT = (120, 148)      # inside the ring, the well ahead of him
QUEST_ROOMS = [122, 128, 17, 33]    # where quest items 0-3 lie ($D312)
BUCKET = 90                 # the bucket's graphic
COLLECTABLES = range(4, 9)  # quest records 4-8: graphics 148 down to 144
# Where #R$CD16 sends each collectable in room 82, by graphic: the table at
# $D562 read the way the game reads it, graphic AND 7 as the index.
COLLECTABLE_TARGETS = 0xD562


def _place(u: int, v: int):
    """Stand the player (both his records) at U, V."""
    def poke(memory):
        for record in (PLAYER, PLAYER + 32):
            memory[record + 1], memory[record + 2] = u, v
    return poke


def _record_of(memory, graphic: int) -> int | None:
    for record in range(PLAYER, PLAYER + 54 * 32, 32):
        if memory[record] == graphic:
            return record
    return None


def _beside_bucket(memory) -> None:
    """The player just short of the bucket in V, where #R$BF79 finds it."""
    record = _record_of(memory, BUCKET)
    if record is None:
        sys.exit("error: session 'the quest': no bucket to stand beside")
    _place(memory[record + 1], memory[record + 2] - 14)(memory)


# Shooting: a dozen shots (fire is taken once a press, #R$C126), then a
# quarter turn, and again, until the well has had enough.
VOLLEY = [_lives, (["w"], 0.15), ([], 0.25)] * 12 + [(["z"], 0.15), ([], 0.3)]
PRESS = [_lives, (["1"], 0.2), ([], 0.8)]


def _quest_item(room: int, done: int) -> list:
    """A bucket from the well, carried to a quest item's room and put down."""
    return (_go(WELL_ROOM) + [([], 1.0), _place(*WELL_SPOT), ([], 0.5),
                              Repeat("a bucket from the well", VOLLEY,
                                     lambda memory: memory[BUCKET_OUT], 8),
                              ([], 2.0), _beside_bucket, ([], 0.5),
                              # Each press passes what he carries one place
                              # along (#R$C091); from the last it is put down.
                              Repeat("the bucket carried, next to put down", PRESS,
                                     lambda memory: memory[CARRIED + 12] == BUCKET, 6)]
            + _go(room) + [([], 1.0),
                           Repeat("the bucket put down", PRESS,
                                  lambda memory: memory[CARRIED + 12] == 0, 3),
                           Until(f"quest item {done} done",
                                 lambda memory: memory[QUEST_DONE] == done, 30.0)])


def _collectables_in_room_82(memory) -> None:
    """The five collectables on the floor of room 82, each sixteen units
    short of its place towards the middle, with a clear line to it."""
    for number in COLLECTABLES:
        record = QUEST_RECORDS + QUEST_SIZE * number
        graphic = memory[record]
        target = COLLECTABLE_TARGETS + 2 * (graphic & 7)
        u, v = memory[target], memory[target + 1]
        if abs(128 - u) >= abs(128 - v):
            u += 16 if u < 128 else -16
        else:
            v += 16 if v < 128 else -16
        memory[record + 1], memory[record + 2], memory[record + 3] = u, v, 128
        memory[record + 8] = ROOM_PENTAGRAM


def _quest() -> list:
    steps = _start("1")
    for done, room in enumerate(QUEST_ROOMS, 1):
        steps += _quest_item(room, done)
    steps += [Until("the pentagram's pieces", lambda memory: memory[PENTAGRAM_ON], 5.0)]
    steps += _go(ROOM_PENTAGRAM) + _alive([([], 2.0), (["a"], 0.5), ([], 1.0)])
    steps += [_collectables_in_room_82] + _go(ROOM_PENTAGRAM)
    steps += [Until("the fifth collectable in its place", lambda memory: memory[PLACED] >= 5, 40.0),
              Until("the menu after the ending", _at_menu, 60.0)]
    return steps + _start("1") + _alive(KEYBOARD_ROUND)


def _directional(memory) -> None:
    """Bit 3 of the control byte: the joystick steers by direction, turning
    him to face the way pushed (#R$C4C8). No menu choice sets it."""
    memory[CONTROL] |= 0x08


def sessions(snapshot: Path, cycles: int) -> list:
    rooms = _rooms(snapshot)
    keyboard = _start("1") + _alive(KEYBOARD_ROUND * cycles + PAUSE + KEYBOARD_ROUND)
    kempston = _start("2") + _alive(STICK_ROUND * cycles + PAUSE)
    cursor = _start("3") + _alive(CURSOR_ROUND * cycles)
    sinclair = _start("4") + _alive(SINCLAIR_ROUND * cycles)
    tour = _start("1") + _tour(rooms, 1.0)
    over = (_start("1") + _alive(KEYBOARD_ROUND) + [Until("a live player", _playing), _game_over,
                                                    Until("the menu again", _at_menu, 60.0)]
            + _start("1") + _alive(KEYBOARD_ROUND))
    # Room 30 is empty and nothing bans a drop there; fire at what falls.
    flyers = _start("1") + _go(30)
    for _ in range(cycles):
        flyers += [_drop_soon] + _alive([([], 1.5), (["w"], 0.2), (["z"], 0.15), (["r"], 0.2),
                                         ([], 1.0), (["a"], 0.8), (["y"], 0.2), ([], 2.0)])
    return [
        ("keyboard", keyboard),
        ("Kempston joystick", kempston),
        ("cursor joystick", cursor),
        ("Interface II", sinclair),
        ("every room", tour),
        ("game over", over),
        ("things from the sky", flyers),
        ("the quest and the ending", _quest()),
        ("directional joystick", _start("2") + [_directional] + _alive(STICK_ROUND * cycles)),
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

    The same method as build_antattack.py's (and build_hobbit.py's, which
    says at length why): seeds are addresses a CPU executed, branches are
    only followed out of those, and the CPU's instruction boundaries overrule
    the decoder's wherever they meet.
    """
    import codemap

    # And the update routines, one per graphic, that the main loop jumps to
    # through the table at $AE2F (JP (HL) at $B00B): a jump table is a list
    # of edges, not a guess, and a graphic no session met still has its
    # routine there.
    seeds = set(executed) | {_word(memory, HANDLERS + 2 * graphic)
                             for graphic in range(GRAPHIC_COUNT)}
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
    still reassemble. So: the ranges pentagram_data.py owns and the spans the
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

    import pentagram_data

    _log("Generating control file...")
    auto_ctl = _capture(sna2ctl.main, [
        "-m", str(code_map), "-h",
        "-s", str(BLOCK_START), "-e", str(BLOCK_END), str(snapshot),
    ])
    auto_ctl = NEWLINE.join(line for line in auto_ctl.splitlines()
                            if not re.match(r"^@ \$[0-9A-F]{4} (start|org)$", line))
    memory = game_memory(snapshot)
    generated = pentagram_data.data_blocks(memory)
    (OUT_DIR / "pentagram-data.ctl").write_text(generated, encoding="utf-8")
    owned = pentagram_data.OWNED
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
    ctls = ["-c", str(ctl)]
    if ANNOTATIONS.exists():
        # Disassemble once with only the annotations' block directives, to
        # learn where the instruction boundaries are, so that a comment whose
        # length splits an instruction is reported by line number.
        structure = OUT_DIR / "pentagram-structure.ctl"
        structure.write_text(NEWLINE.join(
            " ".join(line.split(" ", 2)[:2])
            for line in ANNOTATIONS.read_text(encoding="utf-8").splitlines()
            if _BLOCK_RE.match(line)), encoding="utf-8")
        check_annotations(_capture(sna2skool.main,
                                   ["-H", "-c", str(ctl), "-c", str(structure),
                                    str(snapshot)]))
        ctls += ["-c", str(ANNOTATIONS)]
    # ListRefs=2: every entry gets its "Used by the routines at ..." line.
    warnings: list[str] = []
    skool.write_text(label_unlabelled(_capture(sna2skool.main,
                                               ["-H", "-I", "ListRefs=2", *ctls,
                                                str(snapshot)], warnings)),
                     encoding="utf-8")

    _log("Generating assembly...")
    text = _capture(skool2asm.main, ["-H", "-c", str(skool)], warnings)
    asm.write_text("    DEVICE ZXSPECTRUM48\n" + text, encoding="utf-8")
    report = OUT_DIR / "pentagram-warnings.txt"
    report.write_text(NEWLINE.join(warnings) + NEWLINE, encoding="utf-8")
    _log(f"  {len(warnings)} warning(s)" + (f" -- see {report.name}" if warnings else ""))
    return len(warnings)


def report_coverage(snapshot: Path, code_map: Path, skool: Path, out: Path) -> None:
    """How much is code, how much data, and which code never ran.

    Written to pentagram-coverage.txt beside the listing, a line per run of
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
    loaded = LOADED_END - BLOCK_START
    lines = [f"{total} bytes disassembled (${BLOCK_START:04X}-${BLOCK_END - 1:04X}); "
             f"{loaded} of them loaded from the tape",
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
    raw = OUT_DIR / "pentagram.rawbin"
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
    """The snapshot tap2sna made, with $5E00 up replaced by the assembled bytes.

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
# rooms -- so, like the disassembly itself, it is built locally and not
# committed. The prose pages are scripts/pentagram.ref, which is.

SPRITE_SCALE = 3


def sprite_image(memory, address: int, scale: int = SPRITE_SCALE):
    """The sprite at `address` as #R$B44F draws it, on a clear background.

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
    import pentagram_data

    memory = game_memory(snapshot)
    out_dir.mkdir(parents=True, exist_ok=True)
    count = 0
    for address in pentagram_data.picture_sprites(memory):
        sprite_image(memory, address).save(out_dir / pentagram_data.sprite_picture_name(address))
        count += 1
    return count


# The generated pages beyond the listing, each family in a module of its own
# beside this script: build(snapshot, html_dir, log) draws its pictures and
# records its sounds into html_dir and returns its ref sections, name to body.
# A module not written yet is skipped, so the pages can arrive one at a time.
PAGE_MODULES = ["pentagram_howitworks", "pentagram_world", "pentagram_graphics",
                "pentagram_animations", "pentagram_sounds", "pentagram_reference"]


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
    game_dir = out / "pentagram"
    count = draw_sprites(snapshot, game_dir / "images" / "sprites")
    _log(f"  {count} sprites drawn")
    pages_ref = OUT_DIR / "pentagram-pages.ref"
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
                        help="the Pentagram .tzx or .tap to disassemble")
    parser.add_argument("--html", action="store_true",
                        help="also write a browsable HTML disassembly under "
                             "game_disassembly/pentagram/html/")
    parser.add_argument("--cycles", type=int, default=8,
                        help="rounds of play per playing session (default 8)")
    args = parser.parse_args()

    if not args.tape.exists():
        sys.exit(f"error: {args.tape} not found")
    if not ROM.exists():
        sys.exit(f"error: {ROM} not found -- see README.md for where to get it")

    started = time.time()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    snapshot = OUT_DIR / "pentagram.z80"
    code_map = OUT_DIR / "pentagram.map"
    ctl = OUT_DIR / "pentagram.ctl"
    skool = OUT_DIR / "pentagram.skool"
    asm = OUT_DIR / "pentagram.asm"
    sld = OUT_DIR / "pentagram.sld"
    rebuilt = OUT_DIR / "pentagram-rebuilt.z80"

    make_snapshot(args.tape, snapshot)
    _log("Playing the game to map out which addresses are code...")
    build_code_map(snapshot, code_map, args.cycles)
    warnings = build_asm(snapshot, code_map, ctl, skool, asm)
    report_coverage(snapshot, code_map, skool, OUT_DIR / "pentagram-coverage.txt")
    game_bytes = assemble(asm, sld)
    verify(game_bytes, snapshot)
    write_snapshot(game_bytes, snapshot, rebuilt)
    if args.html:
        build_html(skool, snapshot, OUT_DIR / "html")

    _log("")
    _log(f"Wrote {asm}, {sld} and {rebuilt} in {time.time() - started:.0f} s")
    if args.html:
        _log(f"HTML disassembly: {OUT_DIR / 'html' / 'pentagram' / 'index.html'}")
    _log("Load roms/48.rom first, then the .z80 + .sld.")
    if warnings:
        # Everything is written, so the warnings can be looked at in place;
        # but a build with any is not a finished one.
        sys.exit(f"error: {warnings} warning(s) from sna2skool and skool2asm -- see "
                 f"{OUT_DIR / 'pentagram-warnings.txt'}")


if __name__ == "__main__":
    main()
