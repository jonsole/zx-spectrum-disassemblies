"""Disassemble Ant Attack (1983, Sandy White / Quicksilva) from its tape.

THE TAPE. There are three blocks: a BASIC header, a 76-byte BASIC program, and
one headerless block of 41984 bytes. The program is a single line,

    1 RANDOMIZE USR (PEEK 23635+256*PEEK 23636+53)

which jumps into machine code parked after the line's ENTER (PROG+53):

    DI
    LD IX,$5C00          ; load to the system variables...
    LD DE,$A400          ; ...and on to the top of memory: 41984 bytes
    LD A,$FF             ; a data block
    AND A
    CCF                  ; carry set: LOAD, not VERIFY
    EX AF,AF'
    LD SP,$5BF0          ; out of the way, in the printer buffer
    LD HL,$9700
    PUSH HL              ; where LD-BYTES will "return" to
    JP $0562             ; LD-BYTES, past its own set-up

The block overwrites the whole of RAM from the system variables up, including
the BASIC program that is running -- which is replaced by the game's own, 8K
of it. What makes that work is that nothing returns to the old program:
LD-BYTES returns to $9700, which checks the load (JP NC,0 resets on a tape
error), switches to interrupt mode 2 and types RUN into the edit line itself,
then jumps into the ROM's statement loop. The header's auto-run line starts
the loader; nothing would start the game's own BASIC, so the game does.

The game is half BASIC and half machine code. BASIC runs the title screen, the
choice of boy or girl, the score card and story text, and sets each level up
by POKEing tables at $B420 and $B480 (the positions of the ten people to be
rescued are its DATA statements). The machine code does the rest, through
three entry points: USR 32768 plays (or, with a count in $B438, just draws a
few frames), USR 32912 reads the girl-or-boy key and USR 32919 waits for any
key.

So the disassembly covers everything the block loads, $5C00-$FFFF: the system
variables and the BASIC as data (each BASIC line a block of its own, with its
listing as the description), and the game from $8000.

THE INTERRUPT ROUTINE is protection against BREAK. The vector table at
$9800-$9900 sends every interrupt to $9797, which passes it to the ROM's
$0038 unless ERR_NR says an error has happened -- BREAK, say -- in which case
it drops into the same code that typed RUN at load time and starts the program
again. The game cannot be stopped into BASIC.

SEPARATING CODE FROM DATA the way the Atic Atac build does: play the game in
SkoolKit's simulator (from $9708, past the load checks, whose flags only a real
load sets) and record every address executed. See build_aticatac.py for why
that is the safe direction to be wrong in, and why the round trip at the end
cannot catch data dressed as code.

The game and everything built from it is copyrighted ((c) Sandy White 1983).
Built locally, gitignored, never committed. See README.md.

Usage:
    python scripts/build_antattack.py --tape "path/to/Ant Attack.tzx"
"""
from __future__ import annotations

import argparse
import contextlib
import functools
import io
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from sna import RAM_SIZE, Registers, write_sna

PROJECT_ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = PROJECT_ROOT / "game_disassembly" / "antattack"
# Hand-written comments, layered over the generated control file. Source, not
# output: addresses and prose only, so it is committed.
ANNOTATIONS = PROJECT_ROOT / "scripts" / "antattack_annotations.ctl"
REF = PROJECT_ROOT / "scripts" / "antattack.ref"
ROM = PROJECT_ROOT / "roms" / "48.rom"
SJASMPLUS = PROJECT_ROOT / "tools" / "sjasmplus" / "sjasmplus.exe"

# Where LD-BYTES returns to once the block is in, and the first instruction
# past the two load checks there. The checks test the carry flag and DE as
# LD-BYTES leaves them, which a simulation started from a snapshot does not
# reproduce, so the playthrough starts after them.
LOADED = 0x9700
PAST_LOAD_CHECKS = 0x9708
# The loader's own stack, in the printer buffer.
LOADER_STACK = 0x5BF0
# The block: everything from the system variables to the top of memory.
BLOCK_START = 0x5C00
BLOCK_END = 0x10000
# RAMTOP is $7FFF, so the machine code starts here.
CODE_START = 0x8000
SYSVARS_END = 0x5CB6       # where the system variables stop and...
PROG = 23635               # the system variables holding where BASIC starts...
VARS = 23627               # ...and where it ends

TSTATES_PER_SECOND = 3500000
NEWLINE = chr(10)


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
    """Simulate the real LOAD, stopping where LD-BYTES returns to $9700."""
    from skoolkit import tap2sna

    _log(f"Loading {tape.name} (simulated LOAD)...")
    # as_uri: tap2sna reads its input as a URL, and C:\ would be scheme "c".
    with contextlib.redirect_stdout(io.StringIO()):
        tap2sna.main(["--start", str(LOADED), tape.resolve().as_uri(), str(out)])
    if not out.exists():
        sys.exit(f"error: tap2sna did not write {out}")


# --------------------------------------------------------------------------
# Step 2: play the game to find out which addresses are code.
# --------------------------------------------------------------------------

# Every step of a session is (keys held, seconds), or a function to apply to
# the simulated machine's memory at that point.
#
# From the inlay: 0, P, ENTER and SPACE pick one of four views; V moves
# forward and C jumps (both together climb); SYMBOL SHIFT and M turn; S, D, F
# and G throw a grenade, nearer to further; 1 goes back to the city gate,
# which ends the level in BASIC's eyes -- "Have another go!" -- and so walks
# the BASIC's retry path too.
PLAY_STEPS = [
    (["v"], 1.5), (["SS"], 0.3), (["v"], 1.0), (["v", "c"], 1.0),
    (["m"], 0.3), (["v"], 2.0), (["c"], 0.4), (["s"], 0.2), ([], 0.5),
    (["d"], 0.2), (["v"], 1.0), (["f"], 0.2), (["m"], 0.6), (["g"], 0.2),
    (["0"], 0.3), (["v"], 1.0), (["p"], 0.3), (["v"], 1.0),
    (["ENTER"], 0.3), (["v", "c"], 1.5), (["SPACE"], 0.3), (["v"], 1.0),
]
RETREAT = [(["1"], 0.3), ([], 2.0), (["SPACE"], 0.3), ([], 3.0), (["v"], 0.3)]

# The object records (see the annotations for their fields) and the few
# variables the sessions below reach into.
PLAYER = 0xB480
RESCUEE = 0xB490
TIME = 0xB436
# A spot outside the walls, where coordinates are below $80 and nothing is
# solid, and the cell beside it.
OUTSIDE = (0x70, 0x70)


def _start(sex: str) -> list:
    """From the title screen to the first frame of play."""
    # The title flashes its logo to BEEPs for several seconds before it asks,
    # and the story card and "READY WHEN YOU ARE" each wait for a key.
    return [([], 12.0), ([sex], 0.5), ([], 3.0),
            (["SPACE"], 0.3), ([], 3.0), (["v"], 0.3), ([], 1.0)]


def _blocked(memory, x: int, y: int, height: int) -> bool:
    """TEST_MAP_BIT's answer, from the map directly."""
    if x < 0x80 or y < 0x80:
        return False
    return bool(memory[0xC000 + 128 * (y - 0x80) + (x - 0x80)] >> height & 1)


def _beside_rescuee(memory) -> None:
    """Put the player in a free cell next to the person waiting to be rescued.

    Random play never gets anywhere near them -- they are somewhere in a city
    of 16384 cells -- so without this the finding, the following and the
    rescue itself would never run. Only the simulated machine is moved; what
    happens next is the game's own doing.
    """
    x, y, height = memory[RESCUEE], memory[RESCUEE + 1], memory[RESCUEE + 2]
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        if not _blocked(memory, x + dx, y + dy, height):
            memory[PLAYER:PLAYER + 3] = [x + dx, y + dy, height]
            return
    raise RuntimeError(f"nowhere free beside the rescuee at ({x:02X},{y:02X},{height})")


def _both_outside(memory) -> None:
    """Put the player and the rescued person outside the walls, side by side."""
    x, y = OUTSIDE
    memory[PLAYER:PLAYER + 3] = [x, y, 0]
    memory[RESCUEE:RESCUEE + 3] = [x + 1, y, 0]


def _nearly_out_of_time(memory) -> None:
    """Leave a second or so on the clock, to see the game run out of time."""
    memory[TIME:TIME + 2] = [0, 20]


def _play(cycles: int) -> list:
    script = []
    for cycle in range(cycles):
        script += PLAY_STEPS
        if cycle % 3 == 2:
            script += RETREAT
    return script


def _rescues(sex: str, cycles: int) -> list:
    """Find the person, let them follow a while, lead them out -- twice."""
    script = _start(sex)
    for _ in range(2):
        script += [_beside_rescuee, ([], 1.0), (["v"], 1.0), (["SS"], 0.3),
                   (["v"], 1.0), ([], 1.0), _both_outside, ([], 2.0),
                   # The score card, then the next story card and READY.
                   (["SPACE"], 0.3), ([], 4.0), (["SPACE"], 0.3), ([], 3.0),
                   (["v"], 0.3), ([], 1.0)]
    return script + _play(cycles // 2)


# Staged scenes. Random play reaches the everyday code, but the things that
# happen when two objects meet -- a bite, a grenade landing near an ant,
# dropping onto one -- depend on where things are, and in a city this size
# they almost never line up by chance. Each scene puts the pieces in place on
# the simulated machine and then lets the game run; everything that follows
# is the game's own code. The scenes are built on a patch of open ground
# inside the walls, since outside them nothing is solid and nothing collides.
ANT = 0xB4B0          # the first of the five


def _cell(x: int, y: int) -> int:
    return 0xC000 + 128 * (y - 0x80) + (x - 0x80)


def _open_ground(memory, size: int = 11) -> tuple[int, int]:
    """The first square of empty cells, size across, inside the walls."""
    for y in range(0x84, 0x100 - size):
        for x in range(0x84, 0x100 - size):
            if all(memory[_cell(xx, yy)] == 0
                   for yy in range(y, y + size) for xx in range(x, x + size)):
                return x, y
    raise RuntimeError("no open ground")


def _move_ant(memory, ant: int, x: int, y: int, height: int) -> None:
    """Move an ant, and its bit in the map with it.

    An ant is part of the map: MOVE_ANT XORs it out before moving and back in
    after (TOGGLE_MAP_BIT). Moving the record alone leaves a phantom block
    where it was, and the XOR at the new place then puts one in the ant's own
    cell -- which reads as a bite, and pushes the ant up a block.
    """
    old_x, old_y, old_height = memory[ant:ant + 3]
    if old_x >= 0x80 and old_y >= 0x80:
        memory[_cell(old_x, old_y)] ^= 1 << old_height
    memory[ant:ant + 3] = [x, y, height]
    memory[_cell(x, y)] ^= 1 << height


def _bitten(memory) -> None:
    """An ant two cells from the player, to walk into them: "BITTEN!"."""
    x, y = _open_ground(memory)
    memory[PLAYER:PLAYER + 3] = [x + 3, y + 3, 0]
    _move_ant(memory, ANT, x + 5, y + 3, 0)


def _good_shot(memory) -> None:
    """A stunned ant three cells ahead of the player, to throw at: "GOOD SHOT!"."""
    x, y = _open_ground(memory)
    memory[PLAYER:PLAYER + 3] = [x, y + 3, 0]
    memory[PLAYER + 4] = 1                      # facing x up
    _move_ant(memory, ANT, x + 3, y + 3, 0)
    memory[ANT + 6] = 0x40                      # stunned, so it stays there


def _near_miss(memory) -> None:
    """As _good_shot, but eight cells ahead: stunned by the blast, not killed."""
    x, y = _open_ground(memory)
    memory[PLAYER:PLAYER + 3] = [x, y + 3, 0]
    memory[PLAYER + 4] = 1
    _move_ant(memory, ANT, x + 8, y + 3, 0)
    memory[ANT + 6] = 0x40


def _drop_on_ant(memory) -> None:
    """The player three blocks up over a stunned ant: "PARALYSED AN ANT !".

    The third ant, so that PARALYSE_ANT's search passes two before finding it.
    """
    x, y = _open_ground(memory)
    ant = ANT + 32
    _move_ant(memory, ant, x + 3, y + 3, 0)
    memory[ant + 6] = 0x40
    memory[PLAYER:PLAYER + 3] = [x + 3, y + 3, 3]


def _grenade_the_rescuee(memory) -> None:
    """The rescued person two cells ahead, stunned: "HOW COULD YOU ?"."""
    x, y = _open_ground(memory)
    memory[PLAYER:PLAYER + 3] = [x, y + 3, 0]
    memory[PLAYER + 4] = 1
    memory[RESCUEE:RESCUEE + 3] = [x + 2, y + 3, 0]
    memory[RESCUEE + 6] = 0x40


def _ant_through_rescuee(memory) -> None:
    """An ant on the far side of the stunned rescued person: "THEY GOT ME"."""
    x, y = _open_ground(memory)
    memory[PLAYER:PLAYER + 3] = [x, y + 3, 0]
    memory[RESCUEE:RESCUEE + 3] = [x + 2, y + 3, 0]
    memory[RESCUEE + 6] = 0x40
    _move_ant(memory, ANT, x + 4, y + 3, 0)


def _on_the_players_head(memory) -> None:
    """The rescued person, following, one block up in the player's own cell."""
    x, y = _open_ground(memory)
    memory[PLAYER:PLAYER + 3] = [x + 3, y + 3, 0]
    memory[RESCUEE:RESCUEE + 3] = [x + 3, y + 3, 1]
    memory[RESCUEE + 0xD] = 1                   # following


def _nasty_fall(memory) -> None:
    """The player five blocks up over open ground: "NASTY FALL !"."""
    x, y = _open_ground(memory)
    memory[PLAYER:PLAYER + 3] = [x + 3, y + 3, 5]


def _their_fall(memory) -> None:
    """The rescued person, following, five blocks up: "HELP! I FELL!"."""
    x, y = _open_ground(memory)
    memory[PLAYER:PLAYER + 3] = [x + 3, y + 3, 0]
    memory[RESCUEE:RESCUEE + 3] = [x + 5, y + 3, 5]
    memory[RESCUEE + 0xD] = 1
    # BASIC starts them stunned for four frames (line 120's DATA), and a fall
    # that ends while the stun is still counting is never landed: MOVE_OBJECT
    # takes the stunned branch, which clears the fall count without a word.
    memory[RESCUEE + 6] = 0


def _on_the_rescuees_head(memory) -> None:
    """The player dropped onto the head of the rescued person, following.

    Not a landing at all: SHARE_CELL clears the player's fall count as soon as
    the two are a block apart in one cell, so there is no bad fall and no
    search for an ant underneath.
    """
    x, y = _open_ground(memory)
    memory[RESCUEE:RESCUEE + 3] = [x + 3, y + 3, 0]
    memory[RESCUEE + 0xD] = 1
    memory[RESCUEE + 6] = 0
    memory[PLAYER:PLAYER + 3] = [x + 3, y + 3, 3]


def _drop_on_a_block(memory) -> None:
    """The player three blocks up over a one-block-high wall.

    Landing at height 1 on something that is not an ant, so PARALYSE_ANT
    searches all five and finds none.
    """
    for address in range(0xC000, 0x10000):
        if memory[address] == 0x01:
            offset = address - 0xC000
            memory[PLAYER:PLAYER + 3] = [0x80 + offset % 128, 0x80 + offset // 128, 3]
            return
    raise RuntimeError("no one-block wall")


def _one_rescue_to_win(memory) -> None:
    """Set BASIC's fin -- the number of rescues that wins, 10 -- to 1.

    Line 95 runs the ending (GO SUB 3600, and FINAL_SCRIPT through USR 36594)
    once sg, the rescues so far, reaches fin. fin is a long-named numeric
    variable: its first letter with bits 5 and 7 set, the middle letters, the
    last with bit 7 set, then five bytes of number -- 0, 0, low, high, 0 for a
    small integer.
    """
    name = bytes([0xA0 + ord("f") - 0x60, ord("i"), ord("n") | 0x80])
    start, end = _word(memory, VARS), _word(memory, 23641)      # VARS, E_LINE
    area = bytes(memory[start:end])
    at = area.find(name)
    if at < 0:
        raise RuntimeError("no variable fin in the BASIC variables")
    number = start + at + len(name)
    memory[number:number + 5] = [0, 0, 1, 0, 0]


def _scene(stage, *steps) -> callable:
    return lambda cycles: _start("b") + [stage, *steps]


# Each session picks boy or girl at the title screen: the two are drawn and
# moved by the same code, with their own graphics, and the one not being
# played is the one to be rescued. A throw waits out the "MY HERO!" music when
# the scene puts the rescued person within reach, since keys pressed while a
# script plays are not seen.
SESSIONS = [
    ("boy", lambda cycles: _start("b") + _play(cycles)),
    ("girl", lambda cycles: _start("g") + _play(cycles)),
    ("boy, rescuing", lambda cycles: _rescues("b", cycles)),
    ("girl, out of time", lambda cycles: _start("g") + [_nearly_out_of_time, ([], 3.0)]
                                         + [(["SPACE"], 0.3), ([], 8.0)]
                                         + _start("g")[1:] + _play(cycles // 2)),
    ("bitten", _scene(_bitten, ([], 4.0))),
    ("good shot", _scene(_good_shot, (["s"], 0.1), ([], 2.0))),
    ("near miss", _scene(_near_miss, (["s"], 0.1), ([], 2.0))),
    ("paralysed an ant", _scene(_drop_on_ant, ([], 2.0))),
    ("how could you", _scene(_grenade_the_rescuee, ([], 4.0), (["s"], 0.1), ([], 3.0))),
    ("they got me", _scene(_ant_through_rescuee, ([], 6.0))),
    ("on the player's head", _scene(_on_the_players_head, ([], 0.5), (["v"], 1.0))),
    ("on the rescuee's head", _scene(_on_the_rescuees_head, ([], 2.0))),
    ("nasty fall", _scene(_nasty_fall, ([], 3.0))),
    ("onto a wall", _scene(_drop_on_a_block, ([], 2.0))),
    ("help, I fell", _scene(_their_fall, ([], 4.0))),
    # One rescue, then the ending: the score card's key, the ending's own
    # pauses and music, and "PRESS A KEY FOR NEW GAME".
    ("the ending", lambda cycles: _start("b") + [_one_rescue_to_win]
     + [_beside_rescuee, ([], 2.0), _both_outside, ([], 2.0),
        (["SPACE"], 0.3), ([], 25.0), (["SPACE"], 0.3), ([], 12.0)]),
]


def _key_tracer_class():
    from skoolkit.kbtracer import KEY_BITS
    from skoolkit.trace import Tracer

    class KeyTracer(Tracer):
        """A Tracer whose read_port reports a set of held-down keys."""

        def __init__(self, simulator):
            super().__init__(simulator, 0, 0, 0, [0] * 16, 0, False)
            self.keys = set()

        def read_port(self, registers, port):
            if port & 0xFF == 0x1F:     # Kempston joystick: nothing pressed
                return 0
            if port & 1:                # not the ULA
                return 0xFF
            result = 0xFF
            for key in self.keys:
                half_row, bits = KEY_BITS[key]
                if port & half_row == 0:
                    result &= bits
            return result

    return KeyTracer


def build_code_map(snapshot_path: Path, out: Path, cycles: int) -> None:
    from skoolkit import CSimulator, read_bin_file
    from skoolkit.simulator import Simulator
    from skoolkit.simutils import PC, SP, T

    key_tracer_class = _key_tracer_class()
    rom_data = read_bin_file(str(ROM))
    if CSimulator is None:
        _log("  (no C simulator installed -- this will be slow)")

    executed: set[int] = set()
    for label, script in SESSIONS:
        memory = list(game_memory(snapshot_path))
        memory[:0x4000] = rom_data
        simulator = (CSimulator or Simulator)(
            memory, state={"iff": 0, "im": 1, "tstates": 0})
        simulator.registers[SP] = LOADER_STACK
        tracer = key_tracer_class(simulator)
        simulator.set_tracer(tracer)

        before = len(executed)
        pc = PAST_LOAD_CHECKS
        for step in script(cycles):
            if callable(step):
                step(simulator.memory)
                continue
            keys, seconds = step
            tracer.keys = set(keys)
            simulator.trace(pc, 0, 0,
                            simulator.registers[T] + int(seconds * TSTATES_PER_SECOND),
                            True, None, executed, None, None, None)
            pc = simulator.registers[PC]
        _log(f"  {label}: +{len(executed) - before} addresses")

    ran = {a for a in executed if CODE_START <= a < BLOCK_END}
    _log(f"  {len(executed)} addresses executed; {len(ran)} instruction starts "
         f"from ${CODE_START:04X}")
    # What really ran, kept apart from what descent adds to it, so that
    # "has this ever run?" can be answered afterwards -- the annotations say
    # which routines are only read from the code.
    executed_map = bytearray(65536)
    for address in ran:
        executed_map[address] = 1
    out.with_name(out.stem + "-executed.map").write_bytes(bytes(executed_map))
    code = extend_by_descent(list(game_memory(snapshot_path)), ran)

    # SkoolKit reads a 65536-byte map as one byte per address, bit 0 set.
    data = bytearray(65536)
    for address in code:
        data[address] = 1
    out.write_bytes(bytes(data))


# Entry points the BASIC calls that a playthrough may never reach: USR 36594
# is only made from line 3600, when the tenth person has been rescued.
BASIC_ENTRIES = {0x8000, 0x8090, 0x8097, 0x8EF2}
# The code: $8000 to the vector table, which starts at $9800.
DESCENT_END = 0x9800


def extend_by_descent(memory: list, executed: set[int]) -> set[int]:
    """Follow the game's own branches out from everything that ran.

    The same method as build_hobbit.py's, which says at length why: seeds are
    addresses a CPU executed, branches are only followed out of those, and the
    CPU's instruction boundaries overrule the decoder's wherever they meet.
    """
    import codemap

    seeds = executed | BASIC_ENTRIES
    forbidden: set[int] = set()
    for _ in range(12):
        code, indirect, _ = codemap.walk(memory, seeds, CODE_START, DESCENT_END,
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

    # An executed address inside a decoded instruction that nothing branches
    # to means the decode has drifted out of step, and every instruction after
    # it is invented; the round trip would not notice.
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

def _capture(func, args) -> str:
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        func(args)
    return buf.getvalue()


def basic_blocks(snapshot: Path) -> str:
    """Control-file blocks for $5C00-$7FFF: system variables, BASIC, workspace.

    Each BASIC line is a data block of its own, titled with its line number
    and described by its listing, so the program reads as a program in the
    disassembly while still reassembling to the same bytes.
    """
    from skoolkit.basic import BasicLister

    memory = game_memory(snapshot)
    prog, vars_ = _word(memory, PROG), _word(memory, VARS)
    listing = BasicLister().list_basic(list(memory)).split(NEWLINE)
    lines = [f"@ ${BLOCK_START:04X} label=SYSTEM_VARIABLES",
             f"b ${BLOCK_START:04X} System variables",
             f"D ${BLOCK_START:04X} The tape block starts here, so it carries a set "
             f"of system variables of its own: PROG, VARS and the rest point at the "
             f"game's BASIC, and ERR_SP and RAMTOP at its stack, just below the machine code."]
    # The four system variables the machine code touches, by their ROM names.
    lines += [f"B ${BLOCK_START:04X},58",
              "@ $5C3A label=ERR_NR",
              "B $5C3A,1 ERR_NR: #R$9797 watches it for an error to restart from",
              "B $5C3B,2",
              "@ $5C3D label=ERR_SP",
              "B $5C3D,2 ERR_SP: #R$97A0 restarts BASIC with the stack it points at",
              "B $5C3F,26",
              "@ $5C59 label=E_LINE",
              "B $5C59,2 E_LINE: where #R$97A0 types RUN",
              "B $5C5B,27",
              "@ $5C76 label=SEED",
              "B $5C76,2 SEED: #R$8000 leaves the game's random number here, and RANDOMIZE "
              "USR overwrites it at once",
              f"B $5C78,{SYSVARS_END - 0x5C78}"]
    if prog > SYSVARS_END:
        lines += [f"@ ${SYSVARS_END:04X} label=CHANNELS",
                  f"b ${SYSVARS_END:04X} Channel information"]
    address = prog
    for text in listing:
        number = memory[address] << 8 | memory[address + 1]
        length = _word(memory, address + 2)
        # The listing is tokenised text; a '#' would start a skool macro.
        # The listing is full of POKEd and PEEKed addresses; they are BASIC's,
        # not the disassembly's to turn into labels.
        lines += [f"@ ${address:04X} ignoreua:d",
                  f"@ ${address:04X} label=LINE{number}",
                  f"b ${address:04X} BASIC line {number}",
                  f"D ${address:04X} {text.strip().replace('#', '##')}",
                  f"B ${address:04X},4 Line number (big-endian) and length",
                  f"B ${address + 4:04X},{length}"]
        address += 4 + length
    if address != vars_:
        sys.exit(f"error: the BASIC ends at ${address:04X}, but VARS is ${vars_:04X}")
    lines += [f"@ ${vars_:04X} label=BASIC_VARIABLES",
              f"b ${vars_:04X} BASIC variables and workspace",
              f"D ${vars_:04X} Up to RAMTOP: the variables area (empty on the tape), "
              f"the edit line, the calculator stack and the machine stack."]
    return NEWLINE.join(lines) + NEWLINE


_COMMENT_RE = re.compile(r"^\s{2}\$([0-9A-F]{4})(?:,(\d+))?\s")
_SPAN_RE = re.compile(r"^;\s*span\s+\$([0-9A-F]{4}),(\d+)\s*$")
_BLOCK_RE = re.compile(r"^[bctwsiu] \$([0-9A-F]{4})")


def declared_spans() -> list[tuple[int, int]]:
    """Data-block extents the annotations claim, as `; span $ADDR,LENGTH`.

    sna2ctl starts new blocks in the middle of tables -- the scripts at $9000
    come out as dozens of alternating text and data blocks -- and a second
    control file can add block boundaries but never remove them. So the
    generated ones inside a declared span are dropped before the two are
    merged. Returned as (start, end), end exclusive.
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


def strip_spanned_blocks(ctl_text: str, spans: list[tuple[int, int]]) -> str:
    """Drop generated block directives that fall strictly inside a span."""
    kept = []
    for line in ctl_text.splitlines():
        match = _BLOCK_RE.match(line)
        if match:
            address = int(match.group(1), 16)
            if any(start < address < end for start, end in spans):
                continue
        kept.append(line)
    return NEWLINE.join(kept)


def check_annotations(bare_skool: str) -> None:
    """Stop the build on an instruction comment whose length splits an instruction.

    A `  $ADDR,N` directive whose N does not end on an instruction boundary
    makes sna2skool cut the instruction in two and decode on from the middle
    of it; the listing still reassembles, so nothing later would say so.
    """
    # Lines are "c$8093 ...", " $8096 ..." or "*$809A ..." -- the star marks
    # a jump target, which is an instruction boundary like any other.
    boundaries = {int(m.group(1), 16)
                  for m in (re.match(r"^[bctwsiu ]?\*?\$([0-9A-F]{4})\s", line)
                            for line in bare_skool.split(NEWLINE)) if m}
    problems = []
    for number, line in enumerate(ANNOTATIONS.read_text(encoding="utf-8").split(NEWLINE), 1):
        match = _COMMENT_RE.match(line)
        if not match or match.group(2) is None:
            continue
        address = int(match.group(1), 16)
        end = address + int(match.group(2))
        if address in boundaries and end not in boundaries:
            valid = min((b for b in boundaries if b >= end), default=None)
            problems.append(f"  {ANNOTATIONS.name}:{number}: ${address:04X},"
                            f"{match.group(2)} ends mid-instruction"
                            + (f" -- try ,{valid - address}" if valid else ""))
    if problems:
        sys.exit("error: annotation lengths that split an instruction:" + NEWLINE
                 + NEWLINE.join(problems))


SCRIPTS = 0x9000
SCRIPT_COUNT = 17


def script_addresses(memory) -> list[int]:
    """Where each script starts: after the Nth $FF from SCRIPTS."""
    addresses, address = [], SCRIPTS
    for _ in range(SCRIPT_COUNT):
        while memory[address] != 0xFF:
            address += 1
        address += 1
        addresses.append(address)
    return addresses


def script_text(memory, address: int) -> str:
    """A script's words, one line per PRINT AT, notes and colours left out."""
    lines, current = [], ""
    address += 1                                # the stream
    while memory[address] != 0xFF:
        byte = memory[address]
        address += 1
        if byte == 0x16:                        # AT row,column
            lines.append(current)
            current = ""
            address += 2
        elif 0x10 <= byte <= 0x15 or byte in (0x7D, 0x7E):
            address += 1                        # a colour, or a number's address
        elif 0x20 <= byte < 0x7D:
            current += chr(byte)
    lines.append(current)
    return " / ".join(line.strip() for line in lines if line.strip())


def script_blocks(snapshot: Path) -> str:
    """A block per script, labelled SCRIPT1 to SCRIPT17, words as DEFM.

    Generated rather than written into the annotations because the titles are
    the scripts' own words -- the game's text, which stays out of the
    repository. RUN_SCRIPT finds a script by counting the $FF that ends each
    one from SCRIPTS, so the first block starts one byte in.
    """
    memory = game_memory(snapshot)
    lines = []
    for number, start in enumerate(script_addresses(memory), 1):
        end = start
        while memory[end] != 0xFF:
            end += 1
        words = script_text(memory, start) or "a sound"
        lines += [f"@ ${start:04X} label=SCRIPT{number}",
                  f"b ${start:04X} Script {number}: {words.replace('#', '##')}"]
        # Runs of printable text as DEFM, the rest -- the stream, AT and its
        # operands, notes, colours -- as DEFB.
        address = start
        while address <= end:
            run = address
            while run < end and 0x20 <= memory[run] < 0x7D and memory[run - 1] not in (0x16, 0x17, 0x7D, 0x7E):
                run += 1
            if run - address >= 2:
                lines.append(f"T ${address:04X},{run - address}")
                address = run
            else:
                lines.append(f"B ${address:04X},1")
                address += 1
    return NEWLINE.join(lines) + NEWLINE


FRAME_BYTES = 64                # 16 rows of mask, graphic, mask, graphic
SPRITE_TABLES = [(0x68, 0x80), (0xDC, 0x100)]   # frames at $9A00 and at $B700
CITY = 0xC000
CITY_SIDE = 128
CITY_ROW_PART = 32              # bytes to a line of the listing: not 16, or
                                # $FFF0 (LD BC,-16 at $8677) would land on one


def frame_name(frame: int) -> str:
    """What a frame shows, from SPRITE_SETS: who, the pose, the facing."""
    for title, first, rows in SPRITE_SETS:
        count = 4 * len(rows)
        if first <= frame < first + count:
            row, facing = divmod(frame - first, 4)
            what = rows[row]
            if title in ("The boy", "The girl", "The ants"):
                return f"{title[4:]}, {what[:1].lower() + what[1:]}, facing {facing}"
            return f"{title[4:] if title.startswith('The ') else title[:1].lower() + title[1:]}"
    return "not used by any object"


def data_blocks(snapshot: Path) -> str:
    """An entry per sprite frame and per row of the city, generated rather
    than written into the annotations because the pictures and the rows'
    counts are the game's. The annotations title the first of each table."""
    memory = game_memory(snapshot)
    lines = []
    for first, end in SPRITE_TABLES:
        for frame in range(first, end):
            address = 0x8000 + FRAME_BYTES * frame
            if frame == first:
                # The annotations name and title the table's first entry.
                lines.append(f"D ${address:04X} This entry is frame ${frame:02X}: "
                             f"{frame_name(frame)}.")
            else:
                lines += [f"@ ${address:04X} label=FRAME{frame:02X}",
                          f"b ${address:04X} Sprite frame ${frame:02X}: {frame_name(frame)}"]
            lines += [f"D ${address:04X} #HTML({sprite_macro(frame)})",
                      f"B ${address:04X},{FRAME_BYTES},4 Rows of mask, graphic, mask, graphic"]
    for row in range(CITY_SIDE):
        address = CITY + CITY_SIDE * row
        cells = memory[address:address + CITY_SIDE]
        blocks = sum(bin(cell & 0x3F).count("1") for cell in cells)
        tallest = max(cell.bit_length() for cell in cells)
        y = 0x80 + row
        if row:
            lines += [f"@ ${address:04X} label=CITY_Y{y:02X}",
                      f"b ${address:04X} The city: the row at y=${y:02X}"]
        lines += [f"D ${address:04X} {'The row at y=$80: ' if not row else ''}"
                  f"{blocks} block{'s' if blocks != 1 else ''}"
                  + (f", up to {tallest} high." if tallest else ": open ground.")]
        for part in range(0, CITY_SIDE, CITY_ROW_PART):
            lines.append(f"B ${address + part:04X},{CITY_ROW_PART},8 "
                         f"x=${0x80 + part:02X} to ${0x80 + part + CITY_ROW_PART - 1:02X}")
    return NEWLINE.join(lines) + NEWLINE


def label_unlabelled(skool_text: str) -> str:
    """Give each entry the annotations leave without a label -- the $FF and
    $02 filler between routines -- one named after the entry before it, so
    every address in the listing has a name."""
    out, previous, label = [], None, None
    for line in skool_text.split(NEWLINE):
        if line.startswith("@label="):
            label = line[len("@label="):]
        elif re.match(r"^[bcgistuw]\$[0-9A-F]{4}", line):
            if label is None and previous:
                # The entry's comment is already out; its label goes just
                # before its first line, as sna2skool writes one.
                label = f"{previous}_PAD"
                out.append(f"@label={label}")
            previous, label = label, None
        elif re.match(r"^[ *]\$[0-9A-F]{4}", line):
            label = None            # a label inside an entry names a jump target
        out.append(line)
    return NEWLINE.join(out)


def build_asm(snapshot: Path, code_map: Path, ctl: Path, skool: Path, asm: Path) -> None:
    from skoolkit import skool2asm, sna2ctl, sna2skool

    _log("Generating control file...")
    auto_ctl = _capture(sna2ctl.main, [
        "-m", str(code_map), "-h",
        "-s", str(CODE_START), "-e", str(BLOCK_END), str(snapshot),
    ])
    # sna2ctl marks $8000, where it was told to start, as where the assembly
    # starts; that has to be the start of the block instead, or skool2asm
    # silently leaves the system variables and the BASIC out of the listing.
    auto_ctl = NEWLINE.join(line for line in auto_ctl.splitlines()
                            if not re.match(r"^@ \$[0-9A-F]{4} (start|org)$", line))
    spans = declared_spans()
    kept = strip_spanned_blocks(auto_ctl, spans)
    if spans:
        dropped = auto_ctl.count(NEWLINE) - kept.count(NEWLINE)
        _log(f"  {len(spans)} declared span(s); dropped {dropped} generated "
             f"block boundar{'y' if dropped == 1 else 'ies'} inside them")
    ctl.write_text(f"@ ${BLOCK_START:04X} start{NEWLINE}@ ${BLOCK_START:04X} org{NEWLINE}"
                   + basic_blocks(snapshot) + kept + NEWLINE + script_blocks(snapshot)
                   + data_blocks(snapshot),
                   encoding="utf-8")

    _log("Generating skool file...")
    ctls = ["-c", str(ctl)]
    if ANNOTATIONS.exists():
        # Disassemble once with only the annotations' block directives, to
        # learn where the instruction boundaries are, so that a comment whose
        # length splits an instruction is reported by line number rather than
        # as a byte count that is a few out a hundred lines of output later.
        structure = OUT_DIR / "antattack-structure.ctl"
        structure.write_text(NEWLINE.join(
            " ".join(line.split(" ", 2)[:2])
            for line in ANNOTATIONS.read_text(encoding="utf-8").splitlines()
            if re.match(r"^[bctwsiu] \$[0-9A-F]{4}", line)), encoding="utf-8")
        check_annotations(_capture(sna2skool.main,
                                   ["-H", "-c", str(ctl), "-c", str(structure),
                                    str(snapshot)]))
        ctls += ["-c", str(ANNOTATIONS)]
    # ListRefs=2: every entry gets its "Used by the routines at ..." line.
    # sna2skool's default writes it only for an entry with no comment of its
    # own, and nearly every entry here has one, so the callers went missing.
    skool.write_text(label_unlabelled(_capture(sna2skool.main,
                                               ["-H", "-I", "ListRefs=2", *ctls,
                                                str(snapshot)])),
                     encoding="utf-8")

    _log("Generating assembly...")
    text = _capture(skool2asm.main, ["-H", "-c", str(skool)])
    asm.write_text("    DEVICE ZXSPECTRUM48\n" + text, encoding="utf-8")


# --------------------------------------------------------------------------
# Step 4: assemble it back and prove it round-trips.
# --------------------------------------------------------------------------

def assemble(asm: Path, sld: Path) -> bytes:
    sjasmplus = str(SJASMPLUS) if SJASMPLUS.exists() else "sjasmplus"
    raw = OUT_DIR / "antattack.rawbin"
    _log("Assembling with sjasmplus...")
    result = subprocess.run(
        [sjasmplus, asm.name, f"--sld={sld.name}", "--fullpath", f"--raw={raw.name}"],
        cwd=OUT_DIR, text=True, capture_output=True)
    if result.returncode != 0:
        sys.exit(f"error: sjasmplus failed:\n{result.stdout}\n{result.stderr}")
    game_bytes = raw.read_bytes()
    raw.unlink()
    return game_bytes


def verify(game_bytes: bytes, snapshot: Path) -> None:
    reference = bytes(game_memory(snapshot)[BLOCK_START:BLOCK_END])
    if len(game_bytes) != len(reference):
        sys.exit(f"error: assembled {len(game_bytes)} bytes, expected {len(reference)}")
    if game_bytes != reference:
        differing = sum(1 for a, b in zip(game_bytes, reference) if a != b)
        sys.exit(f"error: assembled output differs from the tape in "
                 f"{differing} bytes -- the disassembly is not faithful")
    _log(f"Verified: {len(game_bytes)} bytes reassemble byte-for-byte")


# --------------------------------------------------------------------------
# Step 5: wrap it back up as a .sna.
# --------------------------------------------------------------------------

def write_snapshot(game_bytes: bytes, snapshot: Path, out: Path) -> None:
    """The machine as LD-BYTES leaves it, about to return to $9700.

    The block is the whole of RAM from $5C00, so the only thing below it is
    the screen and the printer buffer, taken from the loaded image. The flags
    and DE are what a good load leaves -- carry set, nothing left to load --
    because the code at $9700 checks exactly those and resets otherwise.
    """
    memory = list(game_memory(snapshot))
    memory[BLOCK_START:BLOCK_END] = game_bytes
    ram = bytes(bytearray(memory[0x4000:0x4000 + RAM_SIZE]))
    regs = Registers(pc=LOADED, sp=LOADER_STACK, af=0x0001, de=0, iy=0x5C3A,
                     ir=0x3F00, im=1)
    out.write_bytes(write_sna(regs, ram, border=0))


# --------------------------------------------------------------------------
# Step 6 (--html): the browsable disassembly and its pages.
# --------------------------------------------------------------------------

# Everything below writes pages that quote the game -- its sprites, its text,
# its city -- so, like the disassembly itself, it is built locally and not
# committed. The prose pages are scripts/antattack.ref, which is.

INK = (0, 0, 0)
PAPER = (205, 205, 205)
SPECTRUM = [(0, 0, 0), (0, 0, 205), (205, 0, 0), (205, 0, 205),
            (0, 205, 0), (0, 205, 205), (205, 205, 0), (205, 205, 205)]
SPECTRUM_BRIGHT = [(0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255),
                   (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]

# The five poses CHOOSE_FRAME picks between, in frame order: each is four
# frames, one per facing relative to the view.
POSES = ["Standing", "Walking", "Arms out: stunned, or throwing",
         "Lying down: stunned for longer", "Arms up: falling"]
# (title, first frame, row titles). A person's frame is first + 4 x pose +
# facing; an ant's animation frame is only ever 0 or 1.
SPRITE_SETS = [
    ("The boy", 0xDC, POSES),
    ("The girl", 0x6C, POSES),
    ("The ants", 0xF8, ["Walking, one foot", "Walking, the other"]),
    ("The grenade", 0xF4, ["In flight ($F4), then the blast, frame by frame"]),
    ("Four frames nothing draws", 0xF0, ["Never drawn: no code produces these frame numbers"]),
    ("The grenade's own frames", 0x68, [
        "Its record's first frame: drawn at its home, far outside the walls, "
        "when the player goes near; in flight it is $F4 onwards"]),
]
SPRITE_SCALE = 4
SPRITE_ATTR = 0x38          # black on white, as the play area is


def sprite_macro(frame: int) -> str:
    """A #UDGARRAY that draws one 16x16 frame straight from the snapshot.

    A frame is 16 rows of mask, graphic, mask, graphic, so each 8x8 cell takes
    every fourth byte, and its mask is the byte before. Mask type 2 is the
    game's own: AND the mask, then OR the graphic.
    """
    a = 0x8000 + 64 * frame
    cells = [(a + 1, a), (a + 3, a + 2), (a + 33, a + 32), (a + 35, a + 34)]
    specs = ";".join(f"${g:04X}:${m:04X}" for g, m in cells)
    return (f"#UDGARRAY2,{SPRITE_ATTR},{SPRITE_SCALE},4,0,0,0,2({specs})"
            f"(sprites/frame{frame:02X})")


def write_sprites_ref(path: Path) -> None:
    lines = ["[Page:Sprites]", "SectionPrefix=Sprites", ""]
    for title, first, rows in SPRITE_SETS:
        anchor = re.sub(r"[^a-z]", "", title.lower())
        lines.append(f"[Sprites:{anchor}:{title}]")
        lines.append('<table class="default"><tr><th>Frames</th>'
                     + "".join(f"<th>Facing {f}</th>" for f in range(4)) + "</tr>")
        for index, row in enumerate(rows):
            frames = [first + 4 * index + facing for facing in range(4)]
            cells = "".join(f"<td>{sprite_macro(f)}<br>${f:02X}</td>" for f in frames)
            lines.append(f"<tr><td>{row}</td>{cells}</tr>")
        lines += ["</table>", ""]
    path.write_text(NEWLINE.join(lines), encoding="utf-8")


def playing_machine(snapshot: Path):
    """A simulator paused in the first frames of a game, after the title."""
    from skoolkit import CSimulator, read_bin_file
    from skoolkit.simulator import Simulator
    from skoolkit.simutils import PC, SP, T

    memory = list(game_memory(snapshot))
    memory[:0x4000] = read_bin_file(str(ROM))
    simulator = (CSimulator or Simulator)(memory, state={"iff": 0, "im": 1, "tstates": 0})
    simulator.registers[SP] = LOADER_STACK
    tracer = _key_tracer_class()(simulator)
    simulator.set_tracer(tracer)
    pc = PAST_LOAD_CHECKS
    for keys, seconds in _start("b"):
        tracer.keys = set(keys)
        simulator.trace(pc, 0, 0, simulator.registers[T] + int(seconds * TSTATES_PER_SECOND),
                        True, None, None, None, None, None)
        pc = simulator.registers[PC]
    return simulator


def call_routine(memory: list, address: int, registers: dict) -> list:
    """Run a routine on a copy of memory until it returns; the memory after."""
    from skoolkit import CSimulator
    from skoolkit.simulator import Simulator
    from skoolkit.simutils import SP

    # The routine returns to an address in the printer buffer that nothing
    # else executes, and the simulation stops there.
    # The return address goes in before the simulator is made: it works on
    # its own copy of the memory it is given.
    memory = list(memory)
    memory[0x5B80:0x5B82] = [0x00, 0x5B]
    simulator = (CSimulator or Simulator)(memory, state={"iff": 0, "im": 1, "tstates": 0})
    for register, value in registers.items():
        simulator.registers[register] = value
    simulator.registers[SP] = 0x5B80
    simulator.run(address, 0x5B00)
    return simulator.memory


def screen_image(memory: list):
    """The Spectrum screen in memory, as a PIL image."""
    from PIL import Image

    image = Image.new("RGB", (256, 192))
    pixels = image.load()
    for y in range(192):
        row = 0x4000 | ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
        for column in range(32):
            byte = memory[row + column]
            attr = memory[0x5800 + (y >> 3) * 32 + column]
            palette = SPECTRUM_BRIGHT if attr & 0x40 else SPECTRUM
            ink, paper = palette[attr & 7], palette[(attr >> 3) & 7]
            for bit in range(8):
                pixels[column * 8 + bit, y] = ink if byte & (0x80 >> bit) else paper
    return image


# What sets each script off, by number. Prose, not the game's.
SCRIPT_CAUSES = {
    1: "The player lands from a fall of five frames or more", 2: "The rescued person does",
    3: "A grenade blows an ant up", 4: "A grenade is thrown: the count is reprinted",
    5: "A grenade explodes", 6: "The player is caught in their own blast",
    7: "An ant bites the player", 8: "The player's energy changes: reprinted",
    9: "The rescued person is caught in the blast", 10: "An ant bites the rescued person",
    11: "Their energy changes: reprinted", 12: "The player finds them",
    13: "Both are out of the city", 14: "An ant bites the player's last point of energy away",
    15: "The same, for the rescued person", 16: "The player lands on an ant",
    17: "The tenth rescue: BASIC line 3600, through USR 36594",
}
SCRIPT_IMAGES = "images/scripts"


def render_scripts(snapshot: Path, out_dir: Path) -> None:
    """Run each script on a game in progress and keep the screen it leaves."""
    from skoolkit.simutils import A

    out_dir.mkdir(parents=True, exist_ok=True)
    base = list(playing_machine(snapshot).memory)
    for number in range(1, SCRIPT_COUNT + 1):
        memory = list(base)
        if number == SCRIPT_COUNT:
            # The ending runs on the screen BASIC clears for it (line 3600:
            # GO SUB 2000, PAPER 6), not over the city.
            memory[0x4000:0x5800] = [0] * 0x1800
            memory[0x5800:0x5B00] = [0x30] * 0x300
        memory = call_routine(memory, 0x8E02, {A: number})
        screen_image(memory).resize((512, 384)).save(out_dir / f"script{number:02d}.png")


def write_scripts_ref(snapshot: Path, path: Path) -> None:
    memory = game_memory(snapshot)
    lines = ["[Page:Scripts]", "PageContent=#INCLUDE(ScriptsBody)", "", "[ScriptsBody]",
             "Every message the machine code puts on the screen, and every sound it makes, is one "
             "of these: a record in #R$9000 run by #R$8E0D. Each picture is the screen the "
             "script leaves, run in a simulator on a game in progress -- the ending on a "
             "plain yellow screen, as BASIC clears one for it.",
             '<table class="default"><tr><th>No.</th><th>Where</th><th>Says</th>'
             '<th>When</th><th>Leaves</th></tr>']
    for number, address in enumerate(script_addresses(memory), 1):
        text = script_text(memory, address).replace("<", "&lt;") or "<em>nothing: a sound</em>"
        lines.append(f"<tr><td>{number}</td><td>#R${address:04X}</td>"
                     f"<td>{text}</td><td>{SCRIPT_CAUSES[number]}</td>"
                     f'<td><img src="{SCRIPT_IMAGES}/script{number:02d}.png" '
                     f'width="256" height="192" alt="Script {number}"></td></tr>')
    lines.append("</table>")
    path.write_text(NEWLINE.join(lines), encoding="utf-8")


def read_levels(snapshot: Path) -> list[dict]:
    """The ten levels from BASIC: the story card and where the person waits.

    Line 800 does RESTORE sg*10+1000 and GO SUB to the same line, which sets
    c$ (the story card); the DATA on the next line are x, y and height, one
    triple for the first level and four for each after it.
    """
    from skoolkit.basic import BasicLister

    listing = BasicLister().list_basic(list(game_memory(snapshot)))
    lines = {}
    for line in listing.split(NEWLINE):
        match = re.match(r"^\s*(\d+) (.*)$", line)
        if match:
            lines[int(match.group(1))] = match.group(2)
    levels = []
    for level in range(10):
        number = 1000 + 10 * level
        story = re.search(r'c\$="(.*)"', lines[number]).group(1)
        values = [int(v) for v in re.findall(r"\d+", lines[number + 1].replace("DATA", ""))]
        spots = [tuple(values[i:i + 3]) for i in range(0, len(values), 3)]
        levels.append({"level": level + 1, "story": " ".join(story.split()), "spots": spots})
    return levels


def write_levels_ref(snapshot: Path, path: Path) -> None:
    levels = read_levels(snapshot)
    lines = ["[Page:Levels]", "PageContent=#INCLUDE(LevelsBody)", "", "[LevelsBody]",
             "The levels are BASIC's, lines 800-870 and the DATA at 1001-1091. Each has a story "
             "card, printed before it starts, and a place where the person to be rescued waits "
             "-- x, y and height, on the map below. From the second level on there are four "
             "places, and which one is used depends on the time left when the last person was "
             "led out: line 850 skips time MOD 4 of them. After a failed attempt the choice "
             "stays what it was.",
             "The ants speed up too: line 90 sets sp, the number of frames in which an ant "
             "misses one step, to 2 + INT(rescues / 4) from the fourth rescue, and line 190 "
             "pokes it into four of the five ants -- the first is always fast. The score for a "
             "rescue is the time left times the number rescued so far.",
             '<table class="default"><tr><th>Level</th><th>Story card</th>'
             '<th>Where they wait (x, y, height)</th></tr>']
    for level in levels:
        spots = "<br>".join(f"${x:02X}, ${y:02X}, {h}" for x, y, h in level["spots"])
        lines.append(f"<tr><td>{level['level']}</td><td>{level['story']}</td><td>{spots}</td></tr>")
    lines.append("</table>")
    path.write_text(NEWLINE.join(lines), encoding="utf-8")


def block_picture(snapshot: Path, drawer: int) -> list[list]:
    """The block DRAW_BLOCK paints, 16 x 16, as ink (1), paper (0) or clear (None).

    Painted twice by the game's own routine, once onto a cleared render buffer
    and once onto a filled one: a pixel that comes out the same both times is
    the block's, and one that does not is the background showing through.
    """
    from skoolkit.simutils import D, E, H, L

    place = 0xB500 + 32 * 4 + 4                 # well inside the buffer
    top = 0xA000 + 32 * 32 + 8                  # where PLANE_TO_BUFFER puts it
    results = []
    for fill in (0x00, 0xFF):
        memory = list(game_memory(snapshot))
        memory[0xA000:0xB180] = [fill] * 0x1180
        # The drawer ends by jumping back into DRAW_SCENE, at BLOCK_DRAWN;
        # stop there instead.
        from skoolkit import CSimulator
        from skoolkit.simulator import Simulator
        simulator = (CSimulator or Simulator)(memory, state={"iff": 0, "im": 1, "tstates": 0})
        registers = simulator.registers
        registers[H], registers[L], registers[D], registers[E] = place >> 8, place & 0xFF, 0, 0x1F
        simulator.run(drawer, 0x852B)
        results.append(simulator.memory)
    rows = []
    for row in range(16):
        pixels = []
        for byte in range(2):
            address = top + 32 * row + byte
            clear, filled = results[0][address], results[1][address]
            for bit in range(8):
                mask = 0x80 >> bit
                if (clear & mask) == (filled & mask):
                    pixels.append(1 if clear & mask else 0)
                else:
                    pixels.append(None)
        rows.append(pixels)
    return rows


# The city in the game's own projection, view 0, and its layers. A cell (u, v)
# at height h is drawn at 8(u + v) across and 4(v - u) - 8h down, u and v
# counted from $80. The one gap in the outer wall is on the y=$FF side; past it
# y wraps round to $00 and up, open ground, where the player starts -- so v
# carries on past 127 there, and that much of the outside is drawn beyond the
# gate, empty ground in front of the city.
OUTSIDE_ROWS = 12               # y=$00 to $0B, past the gate
HEIGHTS = 6                     # bits 0-5 of a cell: a block at each height
BLOCK = 16                      # the block picture is 16 by 16
GROUND_DOWN = 11                # its bottom diamond's middle, down from its top
LEVEL_NUMBER_SIZE = 14          # points, for the level beside each place
OBJECT_DATA_LINES = range(110, 190, 10)     # DATA for the eight objects
HOME = 10                       # +$0A: home x, then y and height
# (key, what, colour, shown at first)
CITY_LAYERS = [
    ("start", "Where the player starts", (0, 160, 0), True),
    ("gate", "The way in and out", (0, 140, 220), True),
    ("ants", "Where the ants start", (220, 0, 0), True),
    ("rescue", "Where someone waits, by level", (200, 0, 170), True),
]
CITY_SIZE = (8 * (256 + OUTSIDE_ROWS) + BLOCK, 4 * (256 + OUTSIDE_ROWS) + 8 * HEIGHTS + BLOCK)
CITY_ORIGIN_Y = 4 * 127 + 8 * HEIGHTS       # where v - u = 0 lands, for a block on the ground


def basic_data(snapshot: Path) -> dict[int, list[int]]:
    """The numbers on each DATA line of the game's BASIC, by line number."""
    from skoolkit.basic import BasicLister

    data = {}
    for line in BasicLister().list_basic(list(game_memory(snapshot))).split(NEWLINE):
        match = re.match(r"^\s*(\d+) DATA (.*)$", line)
        if match:
            data[int(match.group(1))] = [int(v) for v in match.group(2).split(",")]
    return data


def object_homes(snapshot: Path) -> list[tuple[int, int, int]]:
    """Each object's home -- x, y, height at +$0A -- as BASIC's DATA sets it
    at the start of a level: the player, the rescued person (whose DATA leaves
    it to line 800), the grenade, then the five ants."""
    data = basic_data(snapshot)
    return [tuple(data[line][HOME:HOME + 3]) for line in OBJECT_DATA_LINES]


def city_openings(memory) -> list[tuple[int, int]]:
    """The cells of the outer wall's four edges with nothing in them."""
    edges = ([(x, 0x80) for x in range(0x80, 0x100)] + [(x, 0xFF) for x in range(0x80, 0x100)]
             + [(0x80, y) for y in range(0x80, 0x100)] + [(0xFF, y) for y in range(0x80, 0x100)])
    return [(x, y) for x, y in edges if memory[0xC000 + 128 * (y - 0x80) + (x - 0x80)] == 0]


def _cell_uv(x: int, y: int) -> tuple[int, int]:
    """A cell's u and v in the projection; y below $80 is past the gate, in
    front of the city."""
    return x - 0x80, (y - 0x80 if y >= 0x80 else 128 + y)


def _ground(x: int, y: int) -> tuple[int, int]:
    """The middle of a cell's ground in the projection: the bottom diamond
    of the block that would stand on it."""
    u, v = _cell_uv(x, y)
    return 8 * (u + v) + BLOCK // 2, CITY_ORIGIN_Y + 4 * (v - u) + GROUND_DOWN


def _diamond(x: int, y: int) -> list[tuple[int, int]]:
    """A cell's ground: left, top, right, bottom."""
    cx, cy = _ground(x, y)
    return [(cx - 8, cy), (cx, cy - 4), (cx + 8, cy), (cx, cy + 4)]


def render_city(snapshot: Path, out_dir: Path, levels: list[dict]) -> dict[str, list]:
    """Antescher in the game's own projection, view 0, and the layers over
    it. Returns what each layer marks."""
    from PIL import Image, ImageDraw, ImageFont

    out_dir.mkdir(parents=True, exist_ok=True)
    memory = game_memory(snapshot)

    # Each block the picture #R$8203 paints, captured by running it, and
    # painted lowest height first and then top to bottom, as DRAW_SCENE
    # paints -- so it hides exactly what the game would hide.
    block = block_picture(snapshot, 0x8203)
    city = Image.new("RGB", CITY_SIZE, PAPER)
    pixels = city.load()
    cells = []
    for v in range(128):
        for u in range(128):
            cell = memory[0xC000 + 128 * v + u]
            for h in range(HEIGHTS):
                if cell >> h & 1:
                    cells.append((h, 4 * (v - u) - 8 * h, 8 * (u + v)))
    cells.sort()
    for h, down, across in cells:
        for row in range(BLOCK):
            for column in range(BLOCK):
                pixel = block[row][column]
                if pixel is not None:
                    pixels[across + column, CITY_ORIGIN_Y + down + row] = INK if pixel else PAPER
    city.save(out_dir / "city.png")

    homes = object_homes(snapshot)
    marked = {
        "start": [homes[0][:2]],
        "gate": city_openings(memory),
        "ants": [home[:2] for home in homes[3:]],
        "rescue": [(x, y, level["level"]) for level in levels for x, y, _ in level["spots"]],
    }
    font = ImageFont.load_default(LEVEL_NUMBER_SIZE)
    for key, _, colour, _ in CITY_LAYERS:
        layer = Image.new("RGBA", CITY_SIZE, (0, 0, 0, 0))
        draw = ImageDraw.Draw(layer)
        for place in marked[key]:
            cx, cy = _ground(place[0], place[1])
            if key == "gate":
                draw.polygon(_diamond(place[0], place[1]), fill=colour + (255,))
            else:
                draw.ellipse([cx - 8, cy - 6, cx + 8, cy + 6], outline=colour + (255,), width=3)
            if key == "rescue":
                draw.text((cx + 10, cy - 12), str(place[2]), fill=colour + (255,), font=font,
                          stroke_width=2, stroke_fill=PAPER)
        layer.save(out_dir / f"layer_{key}.png")
    return marked


def write_city_ref(snapshot: Path, path: Path, marked: dict[str, list]) -> None:
    """The city page: the city in the game's projection with its layers, each
    row of it a link to that row's entry."""
    width, height = CITY_SIZE

    def row_area(y: int) -> str:
        # A row of cells runs up and to the right: from the first cell's
        # left and bottom corners to the last cell's top and right.
        left, _, _, bottom = _diamond(0x80, y)
        _, top, right, _ = _diamond(0xFF, y)
        coords = ",".join(f"{a},{b}" for a, b in (left, top, right, bottom))
        return (f'<area shape="poly" coords="{coords}" href="asm/{0xC000 + 128 * (y - 0x80)}.html" '
                f'title="y=${y:02X}" alt="y=${y:02X}">')

    areas = "".join(row_area(y) for y in range(0x80, 0x100))
    toggles, overlays = [], []
    for key, what, _, shown in CITY_LAYERS:
        toggles.append(f'<input type="checkbox" class="aa-toggle" id="aa-layer-{key}"'
                       + (" checked" if shown else "") + ">"
                       f'<label for="aa-layer-{key}"><span class="aa-key aa-key-{key}"></span>'
                       f"{what}</label>")
        overlays.append(f'<img class="aa-layer aa-layer-{key}" '
                        f'src="images/city/layer_{key}.png" alt="">')
    start = marked["start"][0]
    gate = marked["gate"]
    ants = marked["ants"]
    keys = [
        f'<p><span class="aa-key aa-key-start"></span><b>Where the player starts</b>: '
        f"x=${start[0]:02X}, y=${start[1]:02X} -- the home BASIC gives the player "
        f"(#R$B480, +$0A and +$0B, from the DATA at line 110), just outside the gate: "
        f"past y=$FF the coordinate wraps round to $00, and anything under $80 is "
        f"outside the walls.</p>",
        f'<p><span class="aa-key aa-key-gate"></span><b>The way in and out</b>: the '
        f"{len(gate)} cells of the outer wall with nothing in them, x=${gate[0][0]:02X} to "
        f"${gate[-1][0]:02X} on the y=${gate[0][1]:02X} side -- the only gap. A rescue is "
        f"done when both people are out of the city (#R$8EA0).</p>",
        f'<p><span class="aa-key aa-key-ants"></span><b>Where the ants start</b>: '
        + ", ".join(f"x=${x:02X}, y=${y:02X}" for x, y in ants)
        + " -- each ant's home from lines 140-180; an object goes home when its explosion "
        "countdown (+$09) runs out, and BASIC sets that to 1, so they appear there as a "
        "level starts.</p>",
        '<p><span class="aa-key aa-key-rescue"></span><b>Where someone waits</b>, numbered '
        "by level: see <a href=\"Levels.html\">the levels</a> for how one of each level's "
        "places is picked.</p>",
    ]
    lines = ["[CityBody]",
             "<p>Antescher is a map of 128 by 128 cells at #R$C000, one byte a cell and one "
             "bit a height: bit 0 is a block on the ground, bit 5 a block five up, so a wall "
             "is a column of set bits. Coordinates run from $80 to $FF; anything lower is "
             "outside the walls, where nothing is solid and nothing collides. Each row of "
             "the map is an entry of its own in the listing.</p>",
             "<p>The whole city at once, the way the game draws a corner of it: view 0, "
             "each block the picture #R$8203 paints -- captured by running that routine "
             "rather than copied -- and painted in the same order #R$8500 uses, lowest "
             "height first and then from the back, so every block hides exactly what it "
             "hides in the game. x runs up and to the right, y down and to the right; the "
             "open ground past the gate, where the player starts, is in front of the city "
             "at the bottom right. Each layer is read from the game when these pages are "
             "built -- the city map, BASIC's DATA and the levels -- and a box shows or hides "
             "it; a mark sits on its cell's ground, so one behind a wall shows through it. "
             "Click a row of the city to see its bytes.</p>",
             '<div class="aa-layers">' + "".join(toggles)
             + '<div class="aa-city"><div class="aa-city-stack">'
             f'<img src="images/city/city.png" usemap="#aacity" '
             f'alt="Antescher in the game\'s projection" width="{width}" height="{height}">'
             + "".join(overlays) + "</div>"
             f'<map name="aacity">{areas}</map></div></div>'] + keys
    path.write_text(NEWLINE.join(lines), encoding="utf-8")


# The generated pages beyond the listing, each family in a module of its own
# beside this script: build(snapshot, html_dir, log) draws its pictures and
# records its sounds into html_dir and returns its ref sections, name to body.
PAGE_MODULES = ["antattack_howitworks", "antattack_animations", "antattack_sounds",
                "antattack_reference"]


def write_pages_ref(snapshot: Path, html_dir: Path, path: Path) -> None:
    import importlib

    sys.path.insert(0, str(Path(__file__).resolve().parent))
    sections = {}
    for name in PAGE_MODULES:
        sections.update(importlib.import_module(name).build(snapshot, html_dir, _log))
    path.write_text(NEWLINE.join(f"[{name}]{NEWLINE}{body}{NEWLINE}"
                                 for name, body in sections.items()), encoding="utf-8")


def build_html(skool: Path, snapshot: Path, out: Path) -> None:
    from skoolkit import skool2html

    _log("Writing HTML disassembly...")
    game_dir = out / "antattack"
    levels = read_levels(snapshot)
    sprites_ref = OUT_DIR / "antattack-sprites.ref"
    scripts_ref = OUT_DIR / "antattack-scripts.ref"
    levels_ref = OUT_DIR / "antattack-levels.ref"
    write_sprites_ref(sprites_ref)
    write_scripts_ref(snapshot, scripts_ref)
    write_levels_ref(snapshot, levels_ref)
    city_ref = OUT_DIR / "antattack-city.ref"
    marked = render_city(snapshot, game_dir / "images" / "city", levels)
    write_city_ref(snapshot, city_ref, marked)
    pages_ref = OUT_DIR / "antattack-pages.ref"
    write_pages_ref(snapshot, game_dir, pages_ref)
    # -a: the pages use the annotations' labels, so a call reads CALL
    # DRAW_VIEW there too. -S: antattack.css, which the ref names, is beside
    # this script. -o: redraw the images every time, since skool2html
    # otherwise keeps any it finds, however old.
    args = ["-H", "-a", "-o", "-d", str(out), "-S", str(Path(__file__).resolve().parent),
            str(skool), str(REF), str(sprites_ref), str(scripts_ref), str(levels_ref),
            str(city_ref), str(pages_ref)]
    _capture(skool2html.main, args)
    _log("  running the scripts...")
    render_scripts(snapshot, game_dir / SCRIPT_IMAGES)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--tape", required=True, type=Path,
                        help="the Ant Attack .tzx or .tap to disassemble")
    parser.add_argument("--html", action="store_true",
                        help="also write a browsable HTML disassembly under "
                             "game_disassembly/antattack/html/")
    parser.add_argument("--cycles", type=int, default=12,
                        help="rounds of PLAY_STEPS per playthrough session (default 12)")
    args = parser.parse_args()

    if not args.tape.exists():
        sys.exit(f"error: {args.tape} not found")
    if not ROM.exists():
        sys.exit(f"error: {ROM} not found -- see README.md for where to get it")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    snapshot = OUT_DIR / "antattack.z80"
    code_map = OUT_DIR / "antattack.map"
    ctl = OUT_DIR / "antattack.ctl"
    skool = OUT_DIR / "antattack.skool"
    asm = OUT_DIR / "antattack.asm"
    sld = OUT_DIR / "antattack.sld"
    sna = OUT_DIR / "antattack.sna"

    make_snapshot(args.tape, snapshot)
    _log("Playing the game to map out which addresses are code...")
    build_code_map(snapshot, code_map, args.cycles)
    build_asm(snapshot, code_map, ctl, skool, asm)
    game_bytes = assemble(asm, sld)
    verify(game_bytes, snapshot)
    write_snapshot(game_bytes, snapshot, sna)
    if args.html:
        build_html(skool, snapshot, OUT_DIR / "html")

    _log("")
    _log(f"Wrote {asm}, {sld}, and {sna}")
    if args.html:
        _log(f"HTML disassembly: {OUT_DIR / 'html' / 'antattack' / 'index.html'}")
    _log("Load roms/48.rom first, then this .sna + .sld.")


if __name__ == "__main__":
    main()
