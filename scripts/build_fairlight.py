"""Disassemble Fairlight (1985, The Edge) from its tape.

THE TAPES. Fairlight was released twice on tape for the 48K Spectrum, and
both are in ZXDB: Release 1 and Release 2. Each is a BASIC loader, a
3092-byte block and a 48538-byte block, the two long ones recorded at a
turbo speed; Release 2 has one more short BASIC program before the others,
which prints a warning against copying and loads the next. The loader is
the Alkatraz Protection System's (June 1985, its BASIC says): LINE 0 of the
BASIC runs `RANDOMIZE USR 24194`, a routine in the BASIC that decrypts
itself in layers (the first XORs it with bytes of the ROM) and loads the
3092-byte block to $D125-$DD38; that block, decrypted again, is the turbo
loader for the long block (notes/fairlight/loading.md). It reads a two-byte header, then the
loading screen a line of 32 bytes at a time in its own order (the attribute
row first, then the eight pixel lines of each character row), then the game
in four pieces: 14 bytes at $DAC9 that extend its own list of pieces, the
game at $5B00-$DABF, $DD39-$FFFF, and 3 bytes of its own checksum. Each byte
is XORed with a key that changes as it goes, with the count left and the
address it is stored at. While it loads, a countdown is drawn over the
loading screen. If the checksum fails, the loader wipes memory and resets;
if it holds, the loader clears itself and returns to $C47C.

$C47C is where the game begins. It sets the stack, calls a routine at
$C000 that plays a tune on the beeper over the loading screen until a key
is pressed, and (in Release 2) moves its level data into place and jumps to
$F065, the title screen. tap2sna runs the ROM, the BASIC and the loader on a
simulated machine and stops at $C47C, before the game has run an
instruction; make_snapshot() then does the loader's decryption again on the
tape's own block and checks the result is what the snapshot holds, so the
account above is checked at every build, not only written down.

WHICH RELEASE. Release 2 -- the later -- is disassembled: it is the one
Ville Krumlinde's disassembly (github.com/VilleKrumlinde/FairlightZ80) was
made from, which lets his map be set beside this one address for address.
The build refuses Release 1, whose code is laid out differently (see
notes/fairlight/versions.md for what differs).

WHAT IS DISASSEMBLED: $5B00 to the top of memory, all of it loaded from the
tape but for the loader's own $DAC0-$DD38. Much of it is replaced as the
game starts: the start-up copies level data from $C4E0 and $D2F0 over
$A924 and $B734, which on the tape hold leftovers of the assembler's source
text, and a copy of the object table goes to $639C; and from the first room
on, $C000-$DBFF is the game's screen and sprite buffers.

SEPARATING CODE FROM DATA: play the game in SkoolKit's simulator from $C47C
and record every address executed, in sessions for each control, every
room, the fighting, carrying and using things, death, game over and the
ending; then follow the branches out of what ran (scripts/codemap.py),
which invents nothing. The game prints its text through a routine that
reads the string from after its own CALL, and the descent is told so.

THE LEVEL DATA -- the rooms and the shared pieces they are drawn from, the
objects in the rooms, the object templates, the textures, the font, the
sprites and the game's text -- is laid out a record per line by
scripts/fairlight_data.py from the snapshot at every build, so the game's
design is never written into a committed file.

Credit: Ville Krumlinde's disassembly, which has no licence, is used for
facts, addresses and names only, and is credited where it is used; every
word of prose here is this project's own.

The game and everything built from it is copyrighted ((c) 1985 The Edge /
Bo Jangeborg). Built locally, gitignored, never committed. See README.md.

Usage (from game-disassemblies/, with the tape in the emulator repository's tapes/):
    python scripts/build_fairlight.py --tape "../tapes/Fairlight (1985)(The Edge)(Release 2).tzx" [--html]
"""
from __future__ import annotations

import argparse
import contextlib
import functools
import io
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

PROJECT_ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = PROJECT_ROOT / "game_disassembly" / "fairlight"
# Hand-written comments, layered over the generated control file. Source, not
# output: addresses and prose only, so it is committed.
ANNOTATIONS = PROJECT_ROOT / "scripts" / "fairlight_annotations.ctl"
REF = PROJECT_ROOT / "scripts" / "fairlight.ref"
ROM = PROJECT_ROOT / "roms" / "48.rom"
SJASMPLUS = PROJECT_ROOT / "tools" / "sjasmplus" / "sjasmplus.exe"
# Ville Krumlinde's disassembly, cloned beside the scripts (untracked): read
# for the cross-reference of his labels against this listing's entries.
KRUMLINDE = PROJECT_ROOT / ".fairlight-disassembly-src" / "fairlight.asm"

# Where the loader hands over, and where tap2sna stops.
ENTRY = 0xC47C
# The disassembly: everything from the printer buffer to the top of memory.
BLOCK_START = 0x5B00
BLOCK_END = 0x10000
# The loader's own bytes, between the two runs of the game it loads.
LOADER_START = 0xDAC0
LOADER_END = 0xDD39

TSTATES_PER_SECOND = 3500000
NEWLINE = chr(10)

# The loader. The turbo stage starts at LOADER_STAGE; the key it XORs with
# is the byte at LOADER_KEY, the table of pieces it pops is at LOADER_TABLE,
# and the long block begins with a header it checks against LOADER_HEADER.
LOADER_STAGE = 0xDADF
LOADER_KEY = 0xDD35
LOADER_TABLE = 0xDAC3
LOADER_HEADER_AT = 0xDADD
LOADER_HEADER = 0x03F6
LOADER_RETURN = 0xDCB2
GAME_BLOCK_LENGTH = 48538
LINE = 0x20

# Release 2's first instructions at the hand-over: LD HL,$639A; LD SP,HL;
# CALL $C000; LD IY,$FF80. Release 1 has LD HL,$6392 and no LD IY there.
RELEASE_2_START = bytes.fromhex("219a63f9cd00c0fd2180ff")


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

def _tap2sna(tape: Path, start: int, out: Path) -> None:
    from skoolkit import tap2sna

    # as_uri: tap2sna reads its input as a URL, and C:\ would be scheme "c".
    with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
        tap2sna.main(["--start", str(start), tape.resolve().as_uri(), str(out)])
    if not out.exists():
        sys.exit(f"error: tap2sna did not write {out}")


def make_snapshot(tape: Path, out: Path) -> None:
    """Simulate the real LOAD, stopping where the loader hands over."""
    _log(f"Loading {tape.name} (simulated LOAD)...")
    if out.exists():
        out.unlink()
    _tap2sna(tape, ENTRY, out)
    memory = game_memory(out)
    if bytes(memory[ENTRY:ENTRY + len(RELEASE_2_START)]) != RELEASE_2_START:
        sys.exit(f"error: {tape.name} is not Release 2 -- the annotations are for Release 2 "
                 f"(see notes/fairlight/versions.md)")
    check_loader(tape, out)


def _tape_blocks(tape: Path) -> list[bytes]:
    from skoolkit.tape import parse_tap, parse_tzx

    data = tape.read_bytes()
    parsed = parse_tzx(data) if tape.suffix.lower() == ".tzx" else parse_tap(data)
    return [bytes(block.data) for block in parsed.blocks if block.data]


def screen_order() -> list[int]:
    """The addresses of the 216 lines of 32 bytes the loader reads the
    loading screen into, in the order it reads them. It builds the list by
    pushing, from the bottom of the screen up, each character row's eight
    pixel lines and then its attribute row, and pops it from the top."""
    pushed = []
    attributes, pixels = 0x5AE0, 0x57E0
    for _ in range(24):
        for _ in range(8):
            pushed.append(pixels)
            pixels -= 0x100
        low = (pixels & 0xFF) - LINE & 0xFF
        pixels = pixels & 0xFF00 | low
        if low != 0xE0:
            pixels += 0x800
        pushed.append(attributes)
        attributes -= LINE
    return pushed[::-1]


def check_loader(tape: Path, snapshot: Path) -> None:
    """Decrypt the tape's long block the way the turbo loader does, and check
    the snapshot holds the result -- so that the account of the loader in the
    listing is checked at every build.

    The key and the loader's table of pieces are the loader's own, from a
    second simulated load stopped where the turbo stage starts ($DADF). For
    each byte read from the tape (L), with DE the count left in the piece and
    IX the address: A = key XOR D XOR E XOR IXh XOR IXl XOR L goes to (IX);
    when bit 4 of E is set the key gains $8A + E - D; and it always gains
    $67."""
    blocks = [block for block in _tape_blocks(tape) if len(block) == GAME_BLOCK_LENGTH]
    if len(blocks) != 1:
        sys.exit(f"error: expected one block of {GAME_BLOCK_LENGTH} bytes on the tape")
    data = blocks[0]
    with tempfile.TemporaryDirectory() as scratch:
        middle = Path(scratch) / "turbo.z80"
        _tap2sna(tape, LOADER_STAGE, middle)
        memory = bytearray(game_memory(middle))
    state = {"key": memory[LOADER_KEY], "at": 0}

    def piece(address: int, count: int) -> None:
        for left in range(count, 0, -1):
            byte = data[state["at"]]
            state["at"] += 1
            memory[address] = (state["key"] ^ left >> 8 ^ left & 0xFF ^ address >> 8
                               ^ address & 0xFF ^ byte)
            if left & 0x10:
                state["key"] = state["key"] + 0x8A + (left & 0xFF) - (left >> 8) & 0xFF
            state["key"] = state["key"] + 0x67 & 0xFF
            address += 1

    piece(LOADER_HEADER_AT, 2)
    if _word(memory, LOADER_HEADER_AT) != LOADER_HEADER:
        sys.exit("error: the long block's header does not decrypt to the one the loader checks")
    for address in screen_order():
        piece(address, LINE)
    # Then the words the loader pops: more 32-byte lines until a zero, and
    # then pairs of a length and an address until a zero length. The first
    # of the pieces rewrites the table ahead of where it is being read.
    table = LOADER_TABLE
    pieces = []
    while _word(memory, table):
        piece(_word(memory, table), LINE)
        table += 2
    table += 2
    while _word(memory, table):
        length, address = _word(memory, table), _word(memory, table + 2)
        pieces.append((address, length))
        piece(address, length)
        table += 4
    if state["at"] != len(data) or _word(memory, table + 2) != LOADER_RETURN:
        sys.exit("error: the loader's pieces do not account for the tape's block")
    loaded = game_memory(snapshot)
    checked = 0
    # The pieces that are the game; the others are the loader's own table and
    # checksum, which it goes on to overwrite with its stack and clear.
    game = [(a, n) for a, n in pieces if not LOADER_START <= a < LOADER_END]
    for address, length in game:
        if True:
            if bytes(loaded[address:address + length]) != bytes(memory[address:address + length]):
                sys.exit(f"error: the tape's block decrypted the loader's way is not what the "
                         f"snapshot holds at ${address:04X}")
            checked += length
    _log(f"  the tape's block decrypted the loader's way is the snapshot's game, "
         f"{checked} bytes in {', '.join(f'${a:04X}-${a + n - 1:04X}' for a, n in game)}")


# --------------------------------------------------------------------------
# Step 2: play the game to find out which addresses are code.
# --------------------------------------------------------------------------

# The variables the sessions read and write; see the annotations for each.
ROOM = 0xFFB4               # the room the knight is in (IY+$34)
LIFE_TENS = 0xFF95          # LIFE, two decimal digits
LIFE_UNITS = 0xFF96
CARRIED = 0xFF9F            # five words: the records of the things carried
SELECTED = 0xFF9E           # the low byte of the carried word in use
KNIGHT = 0xBC90             # the knight's object record, 20 bytes
RECORD = 20
OBJECT_COUNT = 0xFF80       # how many object records are in use
TITLE_WAIT = 0xF0D8         # the wait for a key under the title and after GAME OVER
NEW_GAME = 0xF089           # the title's key taken: the new game's set-up
ENTER_GAME_ROOM = 0xF09B    # a new game: the knight's record reset, into the room
GAME_STACK = 0x639A         # SP at $F065 and all the way to the room's entry
ENDING_ROOM = 81            # the room that prints the end of the quest
GAME_OVER_ROOM = 1
TITLE_ROOM = 79
QUEST_THING = 5             # the object table's entry #R$FD20 looks for
QUEST_THING_ROOM = 33       # the room the object table puts it in
HEAVY_ROOMS = [20, 34, 49]  # rooms with many things in them
MAIN_LOOP = 0xFF21          # once a pass of the main loop


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

    def __init__(self, what: str, test, seconds: float = 20.0, keys=(), stick: int = 0,
                 during=None, required: bool = True):
        self.what, self.test, self.seconds = what, test, seconds
        self.keys, self.stick, self.during = keys, stick, during
        self.required = required


class Repeat:
    """A session step: play some steps over again until test(memory) is
    true, at most `times` times, or fail."""

    def __init__(self, what: str, steps: list, test, times: int):
        self.what, self.steps, self.test, self.times = what, steps, test, times


class At:
    """A session step: run until the game reaches an address, or fail -- for
    a poke that has to land at a known point in the game's pass."""

    def __init__(self, what: str, address: int, seconds: float = 20.0):
        self.what, self.address, self.seconds = what, address, seconds


class Jump:
    """A session step: carry on at another address with the stack pointer
    set -- how a staged scene enters the game's own code at the point the
    game itself would, rather than poking state and hoping."""

    def __init__(self, what: str, address: int, stack: int):
        self.what, self.address, self.stack = what, address, stack


class Machine:
    """The game on a simulated 48K Spectrum, from the snapshot at $C47C."""

    def __init__(self, snapshot: Path, executed: set | None = None,
                 sprites: set | None = None):
        from skoolkit import CSimulator, read_bin_file
        from skoolkit.simulator import Simulator
        from skoolkit.snapshot import Snapshot

        state = Snapshot.get(str(snapshot))
        memory = list(game_memory(snapshot))
        memory[:0x4000] = read_bin_file(str(ROM))
        # The registers as the loader left them: the game sets SP itself, and
        # Release 2 sets IY; interrupts are off, on only inside the tune's
        # routine at $C000, and off for good from START's DI at $C487.
        registers = {"A": state.a, "F": state.f, "BC": state.bc, "DE": state.de,
                     "HL": state.hl, "IX": state.ix, "IY": state.iy, "SP": state.sp,
                     "I": state.i, "R": state.r, "^AF": state.a2 << 8 | state.f2,
                     "^BC": state.bc2, "^DE": state.de2, "^HL": state.hl2, "PC": state.pc}
        self.simulator = (CSimulator or Simulator)(
            memory, registers, state={"iff": state.iff1, "im": state.im,
                                      "tstates": state.tstates})
        self.tracer = _key_tracer_class()(self.simulator)
        self.simulator.set_tracer(self.tracer)
        self.pc = state.pc
        self.executed = executed
        self.sprites = sprites

    @property
    def memory(self):
        return self.simulator.memory

    def run(self, seconds: float, keys=(), stick: int = 0, stop: int = 0) -> None:
        from skoolkit.simutils import PC, T

        self.tracer.keys = set(keys)
        self.tracer.kempston = stick
        simulator = self.simulator
        # interrupts=True offers the machine's interrupts, as a Spectrum would;
        # the game takes none after the start-up's DI at $C487 (IFF stays 0).
        simulator.trace(self.pc, stop, 0, simulator.registers[T] + int(seconds * TSTATES_PER_SECOND),
                        True, None, self.executed, None, None, None)
        self.pc = simulator.registers[PC]
        if self.sprites is not None:
            self.note_sprites()

    def note_sprites(self) -> None:
        """The sprite each object in the room shows now: its record's +4 and
        +5 (where the sprite is), +2 (its width in pixels) and +3 (its
        height), as #R$EE8D reads them. Only the records the room has in use
        (#R$FF80 counts them) are read."""
        memory = self.memory
        for index in range(min(memory[OBJECT_COUNT], 48)):
            record = KNIGHT + RECORD * index
            address = _word(memory, record + 4)
            if address:
                self.sprites.add((address, memory[record + 2], memory[record + 3]))

    def run_to(self, step: At, label: str) -> None:
        self.run(step.seconds, stop=step.address)
        if self.pc != step.address:
            sys.exit(f"error: session {label!r}: ran {step.seconds} s and never reached "
                     f"{step.what} (${step.address:04X}; PC ${self.pc:04X})")

    def jump(self, step: Jump) -> None:
        from skoolkit.simutils import SP

        self.simulator.registers[SP] = step.stack
        self.pc = step.address

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
            elif isinstance(step, Jump):
                self.jump(step)
            elif isinstance(step, Then):
                self.play(step.make(self.memory), label)
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


class Then:
    """A session step: steps made from the game's state when it is reached --
    for what depends on the room, such as the things lying in it."""

    def __init__(self, what: str, make):
        self.what, self.make = what, make


def _alive(memory) -> None:
    """LIFE back to 99, whatever has happened: the sessions fight and fall a
    lot, and a session that died would spend the rest of itself at the title."""
    memory[LIFE_TENS] = memory[LIFE_UNITS] = 9


def _playing(memory) -> bool:
    return memory[LIFE_TENS] or memory[LIFE_UNITS]


def _with_life(steps: list) -> list:
    """Steps with LIFE topped up before each."""
    out = []
    for step in steps:
        out += [_alive, step]
    return out


def _start() -> list:
    """Through the tune on the loading screen (any key ends it) and the title
    (any key again) into the first room."""
    return [([], 0.5), (["SPACE"], 0.2), At("the title", TITLE_WAIT, 30.0),
            ([], 0.3), (["SPACE"], 0.2), At("the first pass of the main loop", MAIN_LOOP, 30.0)]


def _enter(room: int) -> list:
    """Into a room the way a new game enters its first one: the room goes in
    ROOM, and the game carries on at ENTER_GAME_ROOM with the stack it has
    there, which resets the knight's record and loads and draws the room.
    The thing that carries him off (#R$FE8F) goes the same way, but only
    after EEN (#R$F906), which this skips: EEN also turns the troll's and
    wraith's shared frames back to unmirrored, so a picture taken after this
    shortcut can show them mirrored where the game would not."""
    def poke(memory):
        _alive(memory)
        memory[ROOM] = room
    return [At("a pass of the main loop", MAIN_LOOP, 30.0), poke,
            Jump(f"room {room}", ENTER_GAME_ROOM, GAME_STACK),
            At(f"the main loop in room {room}", MAIN_LOOP, 30.0)]


# A round of keyboard play: walk each way (Q-T, A-G, Y-P, H-ENTER) and
# diagonally, jump (SPACE, SYMBOL SHIFT), fight (B-M), pick up (X-V), drop
# (CAPS SHIFT, Z), choose a carried thing (1-5) and use it (6, 7).
KEYBOARD_ROUND = [
    (["q"], 0.5), (["a"], 0.5), (["y"], 0.5), (["h"], 0.5), (["q", "y"], 0.4),
    (["a", "h"], 0.4), (["SPACE"], 0.3), ([], 0.3), (["SS", "q"], 0.4), ([], 0.3),
    (["b"], 0.4), (["n", "y"], 0.4), ([], 0.2), (["x"], 0.2), ([], 0.2), (["z"], 0.2),
    ([], 0.2), (["2"], 0.2), (["1"], 0.2), (["6"], 0.2), (["7"], 0.2), (["0"], 0.2),
    ([], 0.3),
]
# Kempston bits, as IN A,($1F) reads them (#R$F0E6).
J_RIGHT, J_LEFT, J_DOWN, J_UP, J_FIRE = 1, 2, 4, 8, 16
STICK_ROUND = [
    ([], 0.5, J_UP), ([], 0.5, J_DOWN), ([], 0.5, J_LEFT), ([], 0.5, J_RIGHT),
    ([], 0.4, J_UP | J_RIGHT), ([], 0.4, J_DOWN | J_LEFT), ([], 0.4, J_FIRE), ([], 0.3),
    ([], 0.4, J_FIRE | J_UP), ([], 0.3), (["x"], 0.2, J_LEFT), ([], 0.3),
]


def _things(memory) -> list[int]:
    """The records in the room of things that can be picked up (bit 5 of +12),
    other than the knight's."""
    return [KNIGHT + RECORD * index for index in range(1, memory[OBJECT_COUNT])
            if memory[KNIGHT + RECORD * index + 12] & 0x20]


def _onto_knight(record: int):
    """A thing put where the knight stands, its foot level with his: where
    the pick-up test (#R$F4F4) finds it."""
    def poke(memory):
        memory[record + 6] = memory[KNIGHT + 6]
        memory[record + 7] = memory[KNIGHT + 7] - memory[KNIGHT + 10] + memory[record + 10] & 0xFF
        memory[record + 8] = memory[KNIGHT + 8]
    return poke


def _life(tens: int):
    def poke(memory):
        memory[LIFE_TENS], memory[LIFE_UNITS] = tens, 9
    return poke


def _handle_things(memory) -> list:
    """Each thing in the room picked up, used and dropped, one at a time --
    with LIFE at 59 while it is used, so that a thing that adds to it
    (#R$FE8F) has room to."""
    steps = []
    for number, record in enumerate(_things(memory)):
        steps += [At("a pass of the main loop", MAIN_LOOP), _alive, _onto_knight(record),
                  (["x"], 0.3), ([], 0.3), _life(5 if number % 2 else 9), (["6"], 0.2),
                  ([], 0.3), _alive, (["z"], 0.3), ([], 0.3)]
    return steps


def _others(memory) -> list[int]:
    """The records in the room of what is neither a door nor a thing that
    can be picked up: the room's creatures, furniture and traps."""
    return [KNIGHT + RECORD * index for index in range(1, memory[OBJECT_COUNT])
            if memory[KNIGHT + RECORD * index + 12] & 0x0F != 1
            and not memory[KNIGHT + RECORD * index + 12] & 0x20]


def _back_in(room: int):
    """If LIFE has run out -- something in the room kills at a touch
    (#R$FA58) -- through GAME OVER and the title into the room again."""
    def make(memory):
        if memory[LIFE_TENS] or memory[LIFE_UNITS]:
            return []
        return ([At("GAME OVER", TITLE_WAIT, 30.0), ([], 0.3), (["SPACE"], 0.2),
                 At("the title", TITLE_WAIT, 30.0), ([], 0.3), (["SPACE"], 0.2),
                 At("the first room", MAIN_LOOP, 30.0)] + _enter(room))
    return make


def _touch_others(room: int):
    """Each of the room's other objects put where the knight stands, for
    whatever it does to him when they meet (#R$F959)."""
    def make(memory):
        steps = []
        for record in _others(memory):
            steps += [At("a pass of the main loop", MAIN_LOOP), _alive, _onto_knight(record),
                      ([], 0.3), Then("LIFE", _back_in(room))]
        return steps
    return make


def _load_up(memory) -> list:
    """The things in the room picked up into each of the five places in
    turn (1-5 choose the place, #R$FEF1), none dropped, until they are too
    heavy to carry (#R$F52A)."""
    steps = []
    for place, record in enumerate(_things(memory)[:5]):
        steps += [At("a pass of the main loop", MAIN_LOOP), _alive,
                  ([str(place + 1)], 0.2), ([], 0.2), _onto_knight(record),
                  (["x"], 0.3), ([], 0.3)]
    return steps


def _numbered(number: int):
    """The record of the thing that is the object table's `number`th entry:
    +$13 holds the number (#R$EACC)."""
    def find(memory):
        for index in range(1, memory[OBJECT_COUNT]):
            record = KNIGHT + RECORD * index
            if memory[record + 0x13] == number:
                return record
        return None
    return find


def _pick_numbered(number: int) -> list:
    def make(memory):
        record = _numbered(number)(memory)
        if record is None:
            sys.exit(f"error: no thing numbered {number} in room {memory[ROOM]}")
        return [_alive, _onto_knight(record), (["x"], 0.3), ([], 0.3)]
    return [At("a pass of the main loop", MAIN_LOOP), Then(f"thing {number}", make),
            Until(f"thing {number} carried", lambda memory: any(
                _word(memory, CARRIED + 2 * slot) and memory[_word(memory, CARRIED + 2 * slot) + 0x13]
                == number for slot in range(5)), 5.0)]


def _doors(memory) -> list[int]:
    """The records in the room of doors and doorways (type 1 in the low
    nibble of +12, #R$F7C4)."""
    return [KNIGHT + RECORD * index for index in range(1, memory[OBJECT_COUNT])
            if memory[KNIGHT + RECORD * index + 12] & 0x0F == 1]


def _at_door(record: int):
    """The knight put where a door is, his feet on the door's floor."""
    def poke(memory):
        memory[KNIGHT + 6] = memory[record + 6]
        memory[KNIGHT + 8] = memory[record + 8]
    return poke


def _try_doors(room: int, index: int = 0):
    """Each door of the room in turn: the knight put in it and walked each
    way, until one takes him to another room (#R$F8EC) or none is left."""
    def make(memory):
        doors = _doors(memory)
        if memory[ROOM] != room or index >= len(doors):
            return []
        steps = [At("a pass of the main loop", MAIN_LOOP), _alive, _at_door(doors[index])]
        for key in ("q", "a", "y", "h"):
            steps += [([key], 0.4), _alive]
        return steps + [Then(f"door {index + 1} of room {room}", _try_doors(room, index + 1))]
    return make


def sessions(snapshot: Path, cycles: int) -> list:
    keyboard = _start() + _with_life(KEYBOARD_ROUND * cycles)
    # 9 turns the joystick on and off (#R$FE47).
    kempston = _start() + [(["9"], 0.2), ([], 0.3)] + _with_life(STICK_ROUND * cycles) + [
        (["9"], 0.2), ([], 0.3)] + _with_life(KEYBOARD_ROUND)
    tour = _start()
    for room in range(2, ENDING_ROOM):
        if room == TITLE_ROOM:
            continue
        tour += _enter(room) + _with_life(KEYBOARD_ROUND[:12])
        tour += [Then(f"the things in room {room}", _handle_things)]
        # And a while standing still, for what lives in the room to come
        # at him (#R$F1E0).
        tour += _with_life([([], 0.5)] * 6)
    doors = _start()
    for room in range(2, ENDING_ROOM):
        if room == TITLE_ROOM:
            continue
        doors += _enter(room) + [Then(f"the doors of room {room}", _try_doors(room))]
    over = _start() + _with_life(KEYBOARD_ROUND) + [
        At("a pass of the main loop", MAIN_LOOP),
        lambda memory: memory.__setitem__(LIFE_TENS, 0) or memory.__setitem__(LIFE_UNITS, 0),
        At("GAME OVER", TITLE_WAIT, 30.0), ([], 0.3), (["SPACE"], 0.2),
        At("the title again", TITLE_WAIT, 30.0), ([], 0.3), (["SPACE"], 0.2),
        At("the first room again", MAIN_LOOP, 30.0)] + _with_life(KEYBOARD_ROUND)
    ending = _start() + _enter(ENDING_ROOM)[:3] + [At("the end of the quest", TITLE_WAIT, 30.0)]
    # The quest done: the thing numbered 5 in the object table (#R$FD20
    # looks for it among what is carried), fetched from the room where it
    # lies, and then the room that ends the quest.
    success = (_start() + _enter(QUEST_THING_ROOM) + _pick_numbered(QUEST_THING)
               + _enter(ENDING_ROOM)[:3] + [At("the end of the quest", TITLE_WAIT, 30.0)])
    heavy = _start()
    for room in HEAVY_ROOMS:
        heavy += _enter(room) + [Then(f"a load in room {room}", _load_up)]
    touch = _start()
    for room in range(2, ENDING_ROOM):
        if room == TITLE_ROOM:
            continue
        touch += _enter(room) + [Then(f"what is in room {room}", _touch_others(room))]
    return [
        ("keyboard", keyboard),
        ("Kempston joystick", kempston),
        ("every room", tour),
        ("every door", doors),
        ("game over", over),
        ("the end of the quest", ending),
        ("the quest done", success),
        ("too heavy", heavy),
        ("meeting everything", touch),
    ]


def build_code_map(snapshot: Path, out: Path, cycles: int) -> None:
    executed: set[int] = set()
    sprites: set[tuple[int, int, int]] = set()
    for label, steps in sessions(snapshot, cycles):
        before = len(executed)
        started = time.time()
        machine = Machine(snapshot, executed, sprites)
        machine.play(steps, label)
        _log(f"  {label}: +{len(executed) - before} addresses "
             f"({time.time() - started:.1f} s)")

    ran = {a for a in executed if BLOCK_START <= a < BLOCK_END}
    _log(f"  {len(executed)} addresses executed; {len(ran)} instruction starts "
         f"in the game")
    # What really ran, kept apart from what descent adds to it, so that
    # "has this ever run?" can be answered afterwards.
    executed_map = bytearray(65536)
    for address in ran:
        executed_map[address] = 1
    out.with_name(out.stem + "-executed.map").write_bytes(bytes(executed_map))
    # The sprites seen, for fairlight_data.py to lay out.
    out.with_name(out.stem + "-sprites.txt").write_text(NEWLINE.join(
        f"${a:04X} {w} {h}" for a, w, h in sorted(sprites)) + NEWLINE, encoding="utf-8")
    code = extend_by_descent(list(game_memory(snapshot)), ran)

    # SkoolKit reads a 65536-byte map as one byte per address, bit 0 set.
    data = bytearray(65536)
    for address in code:
        data[address] = 1
    out.write_bytes(bytes(data))


def extend_by_descent(memory: list, executed: set[int]) -> set[int]:
    """Follow the game's own branches out from everything that ran.

    The same method as build_nightshade.py's: seeds are addresses a CPU
    executed, branches are only followed out of those, and the CPU's
    instruction boundaries overrule the decoder's wherever they meet. One
    thing is added: a CALL to the text printer is followed by its string,
    not by code, so the bytes of every string are struck out before the
    walk and it stops at them.
    """
    import codemap
    import fairlight_data

    strings = set()
    for call, start, end in fairlight_data.inline_strings(memory):
        strings.update(range(start, end))
    forbidden: set[int] = set(strings)
    for _ in range(12):
        code, indirect, _ = codemap.walk(memory, executed, BLOCK_START, BLOCK_END, (),
                                         forbidden)
        straddling = {a for a in code
                      if any((a + o) & 0xFFFF in executed
                             for o in range(1, codemap.decode(memory, a).length))}
        if not straddling:
            break
        forbidden |= straddling
    if forbidden - strings:
        _log(f"  {len(forbidden - strings)} decoded instruction(s) struck out for "
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
    ran_strings = sorted(executed & strings)
    if ran_strings:
        sys.exit(f"error: a string after a CALL to the printer ran, at ${ran_strings[0]:04X}")
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
    still reassemble. So: the ranges fairlight_data.py owns and the spans the
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


# The object record's fields, by offset: the names the listing gives an
# (IX+n) that indexes a record (the layout is at #R$BC90), written into the
# .asm as EQUs so that it still assembles to the same bytes.
RECORD_FIELDS = {0x00: "OBJ_SCREEN_X", 0x01: "OBJ_SCREEN_Y", 0x02: "OBJ_WIDTH",
                 0x03: "OBJ_ROWS", 0x04: "OBJ_SPRITE", 0x05: "OBJ_SPRITE+1",
                 0x06: "OBJ_X", 0x07: "OBJ_TOP", 0x08: "OBJ_Z", 0x09: "OBJ_LEN_X",
                 0x0A: "OBJ_HEIGHT", 0x0B: "OBJ_LEN_Z", 0x0C: "OBJ_KIND",
                 0x0D: "OBJ_DIRECTION", 0x0E: "OBJ_STATE", 0x0F: "OBJ_COUNT",
                 0x10: "OBJ_WEIGHT", 0x11: "OBJ_FRAME", 0x12: "OBJ_COURSE",
                 0x13: "OBJ_NUMBER"}
RECORD_SIZE = 20
# The routines in which IX is always an object record's first byte when it
# is indexed: their R lines in the annotations say so, and IX moves only by
# whole records ($14) or is saved and restored whole. Left out: the room
# drawing ($E597, $E5E8, $E89B, $EACC), the compositor ($E3E4) and the copy
# ($EBEA), where IX walks bytes; and $EB4C before $EB86, where the copy has
# left IX partway into the record, so that (IX+$06) there is +12. From its
# POP IX on, IX is the record again.
RECORD_IX_ROUTINES = {0xE4F7, 0xEB1A, 0xECBD, 0xED47, 0xEDC6, 0xEE73, 0xEE8D,
                      0xF036, 0xF127, 0xF157, 0xF1E0, 0xF2F7, 0xF309, 0xF4E6,
                      0xF52A, 0xF595, 0xF65C, 0xF7C4, 0xF906, 0xF959, 0xFA79,
                      0xFA83, 0xFC66,
                      0xFCA5, 0xFCDC, 0xFD20, 0xFE15, 0xFE47}
# ...and PATCH_RECORDS, which sets IX to the first of the six box records
# ($BC18) and writes one field in each: (IX+$2E) is the third's +6, written
# (IX+2*OBJ_SIZE+OBJ_X).
RECORD_IX_RANGES = [(0xEB86, 0xEBEA), (0xE60B, 0xE634)]
# Four places where IX is partway into a record, or past it, named from
# where it stands: #R$EB4C's copy leaves it at +6 and then at +12 (a small
# type), and after #R$EB1A it is the next free record, so the one just made
# is 20 bytes back.
RECORD_IX_PARTWAY = {0xEB5E: ('(IX+$06)', '(IX+OBJ_KIND-OBJ_X)'),
                     0xEB7E: ('(IX+$02)', '(IX+OBJ_STATE-OBJ_KIND)'),
                     0xEB83: ('(IX+$04)', '(IX+OBJ_WEIGHT-OBJ_KIND)'),
                     0xEB15: ('(IX-$01)', '(IX+OBJ_NUMBER-OBJ_SIZE)')}


# IY holds $FF80, the variables' base, from the start-up on -- the author's
# source calls it V, as in (V+3) -- so an (IY+n) is the variable at $FF80+n,
# written (IY+NAME-V). Two exceptions: AIM_AT is handed a record in IY (the
# target's), so its (IY+n) are record fields; and in ROOMST's loop that loads
# a room's records IY walks the table of carried places two bytes a turn, so
# its offsets stay numbers.
VARIABLES_BASE = 0xFF80
IY_RECORD_ROUTINES = {0xFC66}
IY_UNNAMED_RANGES = [(0xFDA8, 0xFDD7)]


def _variable_labels(skool_text: str) -> dict[int, str]:
    """The label of every labelled byte from VARIABLES_BASE up."""
    labels, pending = {}, None
    for line in skool_text.split(NEWLINE):
        if line.startswith("@label="):
            pending = line[len("@label="):]
            continue
        match = re.match(r"^[ *bcgistuw]\$([0-9A-F]{4}) ", line)
        if match and pending:
            address = int(match.group(1), 16)
            if address >= VARIABLES_BASE:
                labels[address] = pending
        if not line.startswith("@"):
            pending = None
    return labels


def _variable_name(address: int, labels: dict[int, str]) -> str:
    """The variable at `address`: its own label, or the one before plus n."""
    below = max(a for a in labels if a <= address)
    return labels[below] if below == address else f"{labels[below]}+{address - below}"


def name_record_fields(skool_text: str) -> str:
    """Write (IX+n) as (IX+field) wherever IX is an object record, and (IY+n)
    as (IY+variable-V) wherever IY is the variables' base."""
    variables = _variable_labels(skool_text)
    out, entry = [], None
    for line in skool_text.split(NEWLINE):
        match = re.match(r"^([bcgistuw])\$([0-9A-F]{4})", line)
        if match:
            entry = int(match.group(2), 16)
        instruction = re.match(r"^[ *c]\$([0-9A-F]{4}) ", line)
        if instruction:
            address = int(instruction.group(1), 16)
            if address in RECORD_IX_PARTWAY:
                old, new = RECORD_IX_PARTWAY[address]
                if old not in line:
                    raise ValueError(f"${address:04X} has no {old} to name")
                line = line.replace(old, new)
            elif entry in RECORD_IX_ROUTINES or any(a <= address < b for a, b in RECORD_IX_RANGES):
                line = re.sub(r"\(IX\+\$([0-9A-F]{2})\)",
                              lambda m: f"(IX+{_field_name(int(m.group(1), 16))})", line)
            if entry in IY_RECORD_ROUTINES:
                line = re.sub(r"\(IY\+\$([0-9A-F]{2})\)",
                              lambda m: f"(IY+{_field_name(int(m.group(1), 16))})", line)
            elif (entry is not None and entry >= 0xB686
                  and not any(a <= address < b for a, b in IY_UNNAMED_RANGES)):
                line = re.sub(r"\(IY\+\$([0-9A-F]{2})\)",
                              lambda m: "(IY+" + _variable_name(VARIABLES_BASE + int(m.group(1), 16),
                                                                variables) + "-V)", line)
        out.append(line)
    return NEWLINE.join(out)


def _field_name(offset: int) -> str:
    """A field of this record, or of the one `offset // 20` records on."""
    records, field = divmod(offset, RECORD_SIZE)
    if records == 0:
        return RECORD_FIELDS[field]
    return f"{records}*OBJ_SIZE+{RECORD_FIELDS[field]}" if records > 1 else f"OBJ_SIZE+{RECORD_FIELDS[field]}"


def record_equates() -> str:
    """The fields' EQUs, for the top of the .asm."""
    lines = ["; The object record's fields: the (IX+n) offsets named in the listing."]
    for offset, name in sorted(RECORD_FIELDS.items()):
        if "+" not in name:
            lines.append(f"{name} EQU ${offset:02X}")
    lines.append(f"OBJ_SIZE EQU ${RECORD_SIZE:02X}")
    lines.append("; The variables' base, which IY holds: (IY+ROOM-V) is ROOM.")
    lines.append(f"V EQU ${VARIABLES_BASE:04X}")
    return NEWLINE.join(lines) + NEWLINE


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

    import fairlight_data

    _log("Generating control file...")
    auto_ctl = _capture(sna2ctl.main, [
        "-m", str(code_map), "-h",
        "-s", str(BLOCK_START), "-e", str(BLOCK_END), str(snapshot),
    ])
    auto_ctl = NEWLINE.join(line for line in auto_ctl.splitlines()
                            if not re.match(r"^@ \$[0-9A-F]{4} (start|org)$", line))
    memory = game_memory(snapshot)
    code = {a for a, flag in enumerate(code_map.read_bytes()) if flag & 1}
    frames = sprite_frames(snapshot, code_map)
    generated = fairlight_data.data_blocks(memory, frames, code)
    (OUT_DIR / "fairlight-data.ctl").write_text(generated, encoding="utf-8")
    owned = fairlight_data.owned(memory, frames, code)
    spans = declared_spans()
    check_structure(generated, owned, spans)
    merged = take_over(auto_ctl, owned, keep_start=False)
    merged = take_over(merged, spans, keep_start=True)
    # The strings after CALLs to the printer are laid out inside their
    # routines: whatever block sna2ctl started at a string, or where the code
    # goes on after it, goes.
    string_text, string_ranges = fairlight_data.strings(memory, code)
    merged = NEWLINE.join(
        line for line in merged.splitlines()
        if not (_ANY_DIRECTIVE_RE.match(line)
                and any(start <= int(_ANY_DIRECTIVE_RE.match(line).group(1), 16) <= end
                        for start, end in string_ranges)))
    generated += string_text
    # And again, read after the annotations: a comment whose length ends where
    # a string starts makes sna2skool carry the routine's code on over the
    # string, and a later control file's directives win.
    (OUT_DIR / "fairlight-strings.ctl").write_text(string_text, encoding="utf-8")
    _log(f"  {len(frames)} sprites and {len(string_ranges)} strings laid out")
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
        structure = OUT_DIR / "fairlight-structure.ctl"
        structure.write_text(NEWLINE.join(
            " ".join(line.split(" ", 2)[:2])
            for line in ANNOTATIONS.read_text(encoding="utf-8").splitlines()
            if _BLOCK_RE.match(line)), encoding="utf-8")
        # Its warnings count too: an overlap it reports is a real fault in the
        # annotations, even if the full pass hides it.
        check_annotations(_capture(sna2skool.main,
                                   ["-H", "-c", str(ctl), "-c", str(structure),
                                    str(snapshot)], warnings))
        ctls += ["-c", str(ANNOTATIONS)]
    ctls += ["-c", str(OUT_DIR / "fairlight-strings.ctl")]
    # ListRefs=2: every entry gets its "Used by the routines at ..." line.
    skool.write_text(name_record_fields(label_unlabelled(_capture(
        sna2skool.main, ["-H", "-I", "ListRefs=2", *ctls, str(snapshot)], warnings))),
                     encoding="utf-8")

    _log("Generating assembly...")
    text = _capture(skool2asm.main, ["-H", "-c", str(skool)], warnings)
    asm.write_text("    DEVICE ZXSPECTRUM48\n" + record_equates() + text, encoding="utf-8")
    report = OUT_DIR / "fairlight-warnings.txt"
    report.write_text(NEWLINE.join(warnings) + NEWLINE, encoding="utf-8")
    _log(f"  {len(warnings)} warning(s)" + (f" -- see {report.name}" if warnings else ""))
    return len(warnings)


def report_coverage(snapshot: Path, code_map: Path, skool: Path, out: Path) -> None:
    """How much is code, how much data, and which code never ran.

    Written to fairlight-coverage.txt beside the listing, a line per run of
    instructions that recursive descent found but no session executed, with
    the entry each is in -- the list of what the sessions have yet to reach,
    and of what a description of it rests on reading alone.
    """
    import codemap

    memory = list(game_memory(snapshot))
    code_starts = {a for a, flag in enumerate(code_map.read_bytes()) if flag & 1}
    # The code map follows branches only out of what ran, so code reached
    # only from code that never ran ($F493, behind a branch in an unrun
    # stretch) is code in the listing but not in the map. Every instruction
    # of the listing's code entries counts.
    in_code = False
    for line in skool.read_text(encoding="utf-8").split(NEWLINE):
        entry = re.match(r"^([bcgistuw])\$([0-9A-F]{4})", line)
        if entry:
            in_code = entry.group(1) == "c"
        if in_code:
            # Not the DEFBs a code entry may hold.
            instruction = re.match(r"^[ *c]\$([0-9A-F]{4}) (?!DEF)", line)
            if instruction:
                code_starts.add(int(instruction.group(1), 16))
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
    loader = LOADER_END - LOADER_START
    lines = [f"{total} bytes disassembled (${BLOCK_START:04X}-${BLOCK_END - 1:04X}); "
             f"{total - loader} of them the game the tape loads, {loader} the loader's own",
             f"{code_bytes} bytes are code: {len(code_starts)} instructions, "
             f"{len(ran & code_starts)} executed in the sessions and "
             f"{len(unrun)} not run in them, found by following branches or read",
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
    raw = OUT_DIR / "fairlight.rawbin"
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

    The header -- PC at $C47C, the registers and the rest -- is carried
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
# Step 6: Krumlinde's labels beside this listing's entries.
# --------------------------------------------------------------------------

_LISTING_RE = re.compile(r"^\s*\d+\s+([0-9A-F]{4}) ((?:[0-9A-F]{2} ?)+?)\s{2,}(.*)$")
_DATA_WORDS = {"db", "dw", "defb", "defw", "defs", "ds", "defm", "dm"}


def krumlinde_map() -> tuple[dict[int, list[str]], set[int]]:
    """Krumlinde's labels and his code map, from the listing sjasmplus makes
    of his fairlight.asm (in a scratch directory: the clone is not touched).
    Returns his line labels by address (not his EQUs, most of which name
    bytes inside his data) and the addresses where he has an instruction
    (a listing line whose source is not DB, DW, DEFS and the like). His source assembles to Release 2's image from
    $4000, so an address there is an address here."""
    sjasmplus = str(SJASMPLUS) if SJASMPLUS.exists() else "sjasmplus"
    labels: dict[int, list[str]] = {}
    code: set[int] = set()
    with tempfile.TemporaryDirectory() as scratch:
        work = Path(scratch)
        (work / "k.asm").write_text(KRUMLINDE.read_text(encoding="utf-8"), encoding="utf-8")
        subprocess.run([sjasmplus, "k.asm", "--raw=k.bin", "--lst=k.lst"], cwd=work,
                       capture_output=True, text=True)
        listing = work / "k.lst"
        if not listing.exists():
            return labels, code
        for line in listing.read_text(encoding="utf-8", errors="replace").splitlines():
            match = _LISTING_RE.match(line)
            if not match:
                continue
            address = int(match.group(1), 16)
            source = match.group(3).split(";")[0].strip()
            label = re.match(r"^(\w+):\s*(.*)$", source)
            if label:
                labels.setdefault(address, []).append(label.group(1))
                source = label.group(2)
            word = source.split()[0].lower() if source.split() else ""
            if word and word not in _DATA_WORDS:
                code.add(address)
    return labels, code


def write_krumlinde(skool: Path, code_map: Path, out: Path) -> None:
    """For each entry, the label Krumlinde gives its address, if any, and his
    labels inside it: the starting point for naming things in stage 2, and a
    record of where the two maps agree. At the top, how far they agree on
    what is code."""
    if not KRUMLINDE.exists():
        _log(f"  (no {KRUMLINDE.name} at {KRUMLINDE.parent}: no cross-reference)")
        return
    labels, his_code = krumlinde_map()
    # Ours: every instruction in the listing (in a routine, and not one of
    # the DEFBs of a string after a CALL to the printer).
    ours = set()
    for line in skool.read_text(encoding="utf-8").split(NEWLINE):
        match = re.match(r"^[c *]\$([0-9A-F]{4}) (\S+)", line)
        if match and not match.group(2).startswith("DEF"):
            ours.add(int(match.group(1), 16))
    his = {a for a in his_code if BLOCK_START <= a < BLOCK_END}
    both = ours & his
    only_ours = sorted(ours - his)
    only_his = sorted(his - ours)

    def runs(addresses):
        out_runs, start, previous = [], None, None
        for address in addresses:
            if start is not None and address - previous <= 4:
                previous = address
                continue
            if start is not None:
                out_runs.append((start, previous))
            start = previous = address
        if start is not None:
            out_runs.append((start, previous))
        return out_runs

    entries = []
    for line in skool.read_text(encoding="utf-8").split(NEWLINE):
        match = re.match(r"^([bcgistuw])\$([0-9A-F]{4})", line)
        if match:
            entries.append((int(match.group(2), 16), match.group(1)))
    ends = [e for e, _ in entries[1:]] + [BLOCK_END]
    lines = ["# Each entry of this listing, with Ville Krumlinde's label at its address and",
             "# his labels inside it (github.com/VilleKrumlinde/FairlightZ80; names only;",
             "# his line labels, not his EQUs). Stage 1 of the Fairlight disassembly.",
             "#",
             f"# Instruction starts: ours {len(ours)}, his {len(his)}, both {len(both)}.",
             f"# Ours and not his: {len(only_ours)}, in "
             + ", ".join(f"${s:04X}-${e:04X}" for s, e in runs(only_ours)),
             f"# His and not ours: {len(only_his)}, in "
             + ", ".join(f"${s:04X}-${e:04X}" for s, e in runs(only_his)),
             "#",
             "# entry  kind  his label at the entry  |  his labels inside",
             ""]
    at_entry = inside_count = code_entries = code_named = 0
    for (address, kind), end in zip(entries, ends):
        here = labels.get(address, [])
        inside = [f"{name}@${a:04X}" for a in range(address + 1, end)
                  for name in labels.get(a, [])]
        at_entry += bool(here)
        inside_count += bool(inside)
        if kind == "c":
            code_entries += 1
            code_named += bool(here)
        lines.append(f"${address:04X}  {kind}  {', '.join(here) or '-'}"
                     + (f"  |  {', '.join(inside)}" if inside else ""))
    out.write_text(NEWLINE.join(lines) + NEWLINE, encoding="utf-8")
    _log(f"  Krumlinde's map: {len(both)} of our {len(ours)} instructions are his too, "
         f"{len(only_his)} of his are not ours; {code_named} of our {code_entries} routines "
         f"start at one of his labels -- see {out.name}")


# --------------------------------------------------------------------------
# Step 7 (--html): the browsable disassembly and its pages.
# --------------------------------------------------------------------------

# The generated pages beyond the listing, each family in a module of its own
# beside this script: build(snapshot, html_dir, log) draws its pictures and
# records its sounds into html_dir and returns its ref sections, name to body.
# A module not written yet is skipped, so the pages can arrive one at a time.
PAGE_MODULES = ["fairlight_howitworks", "fairlight_world", "fairlight_graphics",
                "fairlight_animations", "fairlight_sounds", "fairlight_reference"]


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


def sprite_frames(snapshot: Path, code_map: Path) -> list:
    """Every sprite, from the templates and from what the sessions saw
    (fairlight.map's -sprites.txt), as fairlight_data.sprite_frames() lays
    them out."""
    import fairlight_data

    seen = []
    for line in code_map.with_name(code_map.stem + "-sprites.txt").read_text(
            encoding="utf-8").splitlines():
        address, width, height = line.split()
        seen.append((int(address[1:], 16), int(width), int(height)))
    return fairlight_data.sprite_frames(game_memory(snapshot), seen)


def build_html(skool: Path, snapshot: Path, code_map: Path, out: Path) -> None:
    from skoolkit import skool2html

    import fairlight_data

    _log("Writing HTML disassembly...")
    game_dir = out / "fairlight"
    memory = game_memory(snapshot)
    # The title from the loading screen, for the top of every page (LogoImage
    # in fairlight.ref); written before skool2html, which shows a logo only
    # if the file is there.
    fairlight_data.write_logo(memory, game_dir / "images" / "logo.png", _log)
    count = fairlight_data.draw_pictures(memory, sprite_frames(snapshot, code_map),
                                         game_dir / "images")
    _log(f"  {count} pictures drawn")
    pages_ref = OUT_DIR / "fairlight-pages.ref"
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
                        help="the Fairlight Release 2 .tzx to disassemble")
    parser.add_argument("--html", action="store_true",
                        help="also write a browsable HTML disassembly under "
                             "game_disassembly/fairlight/html/")
    parser.add_argument("--cycles", type=int, default=4,
                        help="rounds of play per playing session (default 4)")
    args = parser.parse_args()

    if not args.tape.exists():
        sys.exit(f"error: {args.tape} not found")
    if not ROM.exists():
        sys.exit(f"error: {ROM} not found -- see README.md for where to get it")

    started = time.time()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    snapshot = OUT_DIR / "fairlight.z80"
    code_map = OUT_DIR / "fairlight.map"
    ctl = OUT_DIR / "fairlight.ctl"
    skool = OUT_DIR / "fairlight.skool"
    asm = OUT_DIR / "fairlight.asm"
    sld = OUT_DIR / "fairlight.sld"
    rebuilt = OUT_DIR / "fairlight-rebuilt.z80"

    make_snapshot(args.tape, snapshot)
    _log("Playing the game to map out which addresses are code...")
    build_code_map(snapshot, code_map, args.cycles)
    warnings = build_asm(snapshot, code_map, ctl, skool, asm)
    report_coverage(snapshot, code_map, skool, OUT_DIR / "fairlight-coverage.txt")
    game_bytes = assemble(asm, sld)
    verify(game_bytes, snapshot)
    write_snapshot(game_bytes, snapshot, rebuilt)
    write_krumlinde(skool, code_map, OUT_DIR / "krumlinde.txt")
    if args.html:
        build_html(skool, snapshot, code_map, OUT_DIR / "html")

    _log("")
    _log(f"Wrote {asm}, {sld} and {rebuilt} in {time.time() - started:.0f} s")
    if args.html:
        _log(f"HTML disassembly: {OUT_DIR / 'html' / 'fairlight' / 'index.html'}")
    _log("Load roms/48.rom first, then the .z80 + .sld.")
    if warnings:
        # Everything is written, so the warnings can be looked at in place;
        # but a build with any is not a finished one.
        sys.exit(f"error: {warnings} warning(s) from sna2skool and skool2asm -- see "
                 f"{OUT_DIR / 'fairlight-warnings.txt'}")


if __name__ == "__main__":
    main()
