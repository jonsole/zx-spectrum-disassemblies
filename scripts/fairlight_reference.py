"""Fairlight's reference pages: its bugs, its pokes and facts worth knowing.

build() returns SkoolKit's own Bug, Poke and Fact sections -- [Bug:x:Title],
[Poke:x:Title], [Fact:x:Title] -- for the lead to place on the Bugs, Pokes
and Facts pages (reference/bugs.html and so on).

The prose is written from the code and from runs of the game. Every bug says
whether it was read from the code or run in SkoolKit's simulator; every poke
was tried in the simulator against the same trial without it, and says what
each gave. The runs use the build's own Machine and session steps
(scripts/build_fairlight.py): a game started from the loading tune and the
title with keys, rooms entered the way a new game enters its first, things
picked up and used with the game's own keys, and pokes made before the game
has run an instruction. Where a trial was staged by writing the game's state
-- the knight put beside a thing, a counter set -- the text says so.

Everything the pages claim from a run is run again at every build, and the
build stops if the game no longer does what the text says: the door the
numberless things of room 19 break and mend, the knight's states under the
freeze with and without Release 1's instruction, the decoy hiding the thing
of kind 11, the stale record numbers, each poke against its trial, the
trapdoor to room 0, SYMBOL SHIFT and 0, interrupts off. build() also reads
the listing to check that each instruction a poke or a bug names is still
the one the text was written for, and keeps #R links only where they name an
entry.

Release 1 is not what the build loads, so its bug is shown by making Release
2's one differing instruction Release 1's (two bytes at $F263); the same
trial was played on Release 1 itself, loaded from its own tape, when this
was written (notes/fairlight/versions.md).

Nothing here quotes the game but what is read from the snapshot at build
time -- a few lines of the author's source text left in memory -- and that
goes into the HTML directory only, with the pictures.
"""
from __future__ import annotations

import html
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

# --------------------------------------------------------------------------
# What the bugs and pokes are about, and what the listing must still say
# --------------------------------------------------------------------------

SET_THING_ROOM = 0xF4E6     # ROMM: LD B,(IX+$13), the thing's number
SET_THING_LOOP = 0xF4F0     # DJNZ $F4EF: six bytes a number, B times
SAVE_POSITIONS = 0xF91A     # EEN: LD B,(IX+$13), the same count
FREEZE_TEST = 0xF263        # I3: CP $05, the jump let through the freeze
FREEZE_JUMP = 0xF265        # JR NZ,$F22C, everything else to I00
I01 = 0xF245                # CP $0B: the type once, the state after a decoy
STALE_MEET = 0xFA0D         # LD A,($FFF8) after the mover's redraw
STALE_MEET_STORE = 0xFA10   # LD ($FF83),A
STALE_PICK = 0xF57E         # LD A,($FFF8) after the knight's redraw
STALE_PICK_STORE = 0xF581   # LD ($FF83),A
TAKE_THING = 0xF555         # WEI3, where FOUND_RECORD is still the thing's
DECLIF = 0xF1B6             # SET 0,(IY+$17): the way into LIFE's subtraction
WEIGHT_TEST = 0xF54D        # JR C,$F555: under 8, take it
KEY_TEST = 0xF7DE           # JR Z,$F7FF: no key needed
ROOM_FLAGS = 0xFE41         # LD (IY+$17),$05: a new room's GAME_FLAGS
FREEZE_SET = 0xFEC8         # SET 7,(IY+$17): the thing of kind 5 used
QUIT_TEST = 0xFE8C          # BIT 1,B: SYMBOL SHIFT with 0
QUIT = 0xFE8E               # RET NZ
ROOM_ZERO = 0xFD26          # ROOMST: AND A, then RET Z for room 0
START_DI = 0xC487           # DI, for good

EXPECTED_INSTRUCTIONS = {
    SET_THING_ROOM: "LD B,(IX+$13)", SET_THING_LOOP: "DJNZ $F4EF", SAVE_POSITIONS: "LD B,(IX+$13)",
    FREEZE_TEST: "CP $05", FREEZE_JUMP: "JR NZ,$F22C", I01: "CP $0B",
    STALE_MEET: "LD A,($FFF8)", STALE_MEET_STORE: "LD ($FF83),A",
    STALE_PICK: "LD A,($FFF8)", STALE_PICK_STORE: "LD ($FF83),A", TAKE_THING: "LD ($FF92),A",
    DECLIF: "SET 0,(IY+$17)", WEIGHT_TEST: "JR C,$F555", KEY_TEST: "JR Z,$F7FF",
    ROOM_FLAGS: "LD (IY+$17),$05", FREEZE_SET: "SET 7,(IY+$17)", QUIT_TEST: "BIT 1,B",
    QUIT: "RET NZ", ROOM_ZERO: "AND A", START_DI: "DI", WEIGHT_TEST + 2: "LD (IY+$07),$03",
}

# Opcodes the pokes and the Release 1 trial write, named for what they are.
RET, JR = 0xC9, 0x18
LIFE_POKE = [(DECLIF, RET)]
WEIGHT_POKE = [(WEIGHT_TEST, JR)]
KEY_POKE = [(KEY_TEST, JR)]
FROZEN_FLAGS = 0x85         # $05 with bit 7, the freeze
FREEZE_POKE = [(ROOM_FLAGS + 3, FROZEN_FLAGS)]
# Release 1 has JR I00 where Release 2 has CP 5 : JR NZ,I00 (versions.md).
I00 = 0xF22C
RELEASE_1_FREEZE = [(FREEZE_TEST, JR), (FREEZE_TEST + 1, (I00 - (FREEZE_TEST + 2)) & 0xFF)]

# The game's variables and records (see the annotations for each).
ROOM = 0xFFB4
LIFE_TENS, LIFE_UNITS = 0xFF95, 0xFF96
CARRIED = 0xFF9F
CARRIED_WEIGHT = 0xFF92
MESSAGE = 0xFF87
GAME_FLAGS = 0xFF97
THINGS_NOTED = 0xFF91
THIS_RECORD = 0xFF83
FOUND_RECORD = 0xFFF8
KNIGHT = 0xBC90
FIXED_RECORDS = 0xBC18      # record 1; record n is 20 x (n - 1) on
RECORD = 20
OBJECT_TABLE = 0xA924       # where the start-up puts it
BELOW_TABLE = 0xA91E        # SET_THING_ROOM's base: six bytes before entry 1
THINGS = 163                # the six-byte records at the table's start
MESSAGE_LOCKED, MESSAGE_HEAVY = 2, 3

# Room 19's two things of kind 4 that the room's drawing places, and the
# door their number-0 pick-up reaches: 256 steps of six from BELOW_TABLE.
NUMBERLESS_KIND = 0x34
WRECKED = (BELOW_TABLE + 6 * 256) & 0xFFFF
MENDING_ROOM = 50           # the byte's own value: the door's x

TITLE_WAIT = 0xF0D8
AFTER_ROOMST = 0xF0AF       # TELE, after the game (ROOMST) has returned

IMAGES = "images/reference"
KRUMLINDE_URL = "https://github.com/VilleKrumlinde/FairlightZ80"
ZXDB_URL = "https://spectrumcomputing.co.uk/entry/1712"


# --------------------------------------------------------------------------
# The listing: entries (for #R), each instruction, and every label
# --------------------------------------------------------------------------

_ENTRY_RE = re.compile(r"^[bcgistuw]\$([0-9A-F]{4})\b")
_INSTRUCTION_RE = re.compile(r"^[ *]\$([0-9A-F]{4}) (.*?)\s*(;|$)")


def read_listing(skool: Path) -> tuple[set[int], dict[int, str]]:
    """Entry addresses, and each instruction by address."""
    entries, instructions = set(), {}
    for line in skool.read_text(encoding="utf-8").splitlines():
        match = _ENTRY_RE.match(line)
        if match:
            address = int(match.group(1), 16)
            entries.add(address)
            instructions[address] = line[len(match.group(0)):].split(";")[0].strip()
            continue
        match = _INSTRUCTION_RE.match(line)
        if match:
            instructions[int(match.group(1), 16)] = match.group(2).strip()
    return entries, instructions


def linker(entries: set[int]):
    """#R$ADDR stays a link only where ADDR starts an entry; elsewhere it
    becomes its link text, or plain $ADDR."""
    def keep_or_plain(match):
        if int(match.group(1), 16) in entries:
            return match.group(0)
        if match.group(2):
            return match.group(2)[1:-1]
        return "$" + match.group(1)

    def fix(text: str) -> str:
        return re.sub(r"#R\$([0-9A-F]{4})(\([^)]*\))?", keep_or_plain, text)
    return fix


def _poke_line(*writes) -> str:
    return ": ".join(f"POKE {address},{value}" for address, value in writes)


# --------------------------------------------------------------------------
# Runs of the game
# --------------------------------------------------------------------------

def _game(snapshot: Path, pokes=(), room: int | None = None):
    """A game started with keys from the loading tune and the title, the
    pokes made before the game has run an instruction; and, if asked, a
    room entered the way a new game enters its first."""
    import build_fairlight as bf

    machine = bf.Machine(snapshot)
    for address, value in pokes:
        machine.memory[address] = value
    machine.play(bf._start(), "reference: a game")
    if room is not None:
        machine.play(bf._enter(room), f"reference: room {room}")
    return machine


def _pass(machine, keys=()) -> None:
    """One pass of the main loop, keys held: from just past START_PASS to
    it again."""
    import build_fairlight as bf

    machine.run(0.0005, keys)
    machine.run(2.0, keys, stop=bf.MAIN_LOOP)
    if machine.pc != bf.MAIN_LOOP:
        raise RuntimeError(f"fairlight_reference: a pass did not come round (PC ${machine.pc:04X})")


def _records(memory) -> list[int]:
    """The records in use after the knight's."""
    return [KNIGHT + RECORD * index for index in range(1, memory[0xFF80] - 6)]


def _number(record: int) -> int:
    return (record - FIXED_RECORDS) // RECORD + 1


def _life(memory) -> int:
    return memory[LIFE_TENS] * 10 + memory[LIFE_UNITS]


def _carried(memory) -> list[int]:
    return [memory[CARRIED + 2 * n] | memory[CARRIED + 2 * n + 1] << 8 for n in range(5)]


def _screen(memory, scale: int = 2):
    """The Spectrum's screen from its memory, colours and all."""
    from PIL import Image

    normal = [(0, 0, 0), (0, 0, 205), (205, 0, 0), (205, 0, 205), (0, 205, 0), (0, 205, 205),
              (205, 205, 0), (205, 205, 205)]
    bright = [(0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255), (0, 255, 0), (0, 255, 255),
              (255, 255, 0), (255, 255, 255)]
    image = Image.new("RGB", (256, 192))
    pixels = image.load()
    for y in range(192):
        row = 0x4000 | (y & 0xC0) << 5 | (y & 7) << 8 | (y & 0x38) << 2
        for column in range(32):
            bits = memory[row + column]
            attribute = memory[0x5800 + (y >> 3) * 32 + column]
            colours = bright if attribute & 0x40 else normal
            ink, paper = colours[attribute & 7], colours[attribute >> 3 & 7]
            for bit in range(8):
                pixels[column * 8 + bit, y] = ink if bits & (0x80 >> bit) else paper
    return image.resize((256 * scale, 192 * scale), Image.NEAREST)


def _try_door(machine, door: int, room: int) -> int:
    """The knight put in a door and walked each way in turn; the room he
    ends in."""
    import build_fairlight as bf

    memory = machine.memory
    machine.play([bf.At("a pass", bf.MAIN_LOOP), bf._alive, bf._at_door(door)], "reference: a door")
    for key in ("q", "a", "y", "h"):
        machine.play([bf._alive, ([key], 0.4)], "reference: a door")
        if memory[ROOM] != room:
            break
    return memory[ROOM]


def _door_to(memory, target: int) -> int | None:
    for record in _records(memory):
        if memory[record + 12] & 0x0F == 1 and memory[record + 13] == target:
            return record
    return None


# The numberless things of room 19 --------------------------------------

def _pick_numberless(machine) -> dict:
    """In room 19, the knight put ten short of one of the room's own things
    and X pressed: the pick-up's search reaches four units past him."""
    import build_fairlight as bf

    memory = machine.memory
    machine.play(bf._enter(19), "reference: room 19")
    things = [r for r in _records(memory) if memory[r + 12] == NUMBERLESS_KIND and not memory[r + 19]]
    if len(things) != 2:
        raise RuntimeError(f"fairlight_reference: room 19 has {len(things)} numberless things, not 2")
    thing = things[0]
    machine.play([bf.At("a pass", bf.MAIN_LOOP)], "reference: room 19")
    life = _life(memory)
    memory[KNIGHT + 6] = memory[thing + 6] - 10
    memory[KNIGHT + 8] = memory[thing + 8]
    machine.play([(["x"], 0.3), ([], 0.3)], "reference: the pick-up")
    return {"thing": thing, "taken": thing in _carried(memory), "life": (life, _life(memory)),
            "byte": memory[WRECKED]}


def numberless_trials(snapshot: Path, out_dir: Path) -> dict:
    """Room 25's door to room 21: walked through as the game starts; after
    one of room 19's numberless things is picked up (with a picture of each
    room); after it is dropped in room 50; and the door's record after the
    thing has been carried out of another room by a door."""
    import build_fairlight as bf

    found = {}
    machine = _game(snapshot, room=25)
    found["door"] = list(machine.memory[WRECKED - 2:WRECKED + 9])
    found["before"] = _try_door(machine, _door_to(machine.memory, 21), 25)

    machine = _game(snapshot)
    memory = machine.memory
    found["pick"] = _pick_numberless(machine)
    for _ in range(2):
        _pass(machine)
    _screen(memory).save(out_dir / "room19.png")
    machine.play(bf._enter(25), "reference: room 25")
    door = _door_to(memory, 21)
    found["door_x"] = memory[door + 6]
    found["after"] = _try_door(machine, door, 25)
    _pass(machine)
    _screen(memory).save(out_dir / "room25.png")
    machine.play(bf._enter(MENDING_ROOM), "reference: room 50")
    for _ in range(4):
        machine.play([bf._alive, ([], 0.3), (["z"], 0.3), ([], 0.3)], "reference: the drop")
        if not any(_carried(memory)):
            break
    found["dropped"] = memory[WRECKED]
    machine.play(bf._enter(25), "reference: room 25")
    found["mended"] = _try_door(machine, _door_to(memory, 21), 25)

    # Out of room 29 by its door to room 30, carrying it: EEN (#R$F906)
    # meets its record, which comes right after the knight's, before the
    # first door.
    machine = _game(snapshot)
    memory = machine.memory
    _pick_numberless(machine)
    machine.play(bf._enter(29), "reference: room 29")
    carried = _carried(memory)[0]
    position = None
    for door in [r for r in _records(memory) if memory[r + 12] & 0x0F == 1]:
        machine.play([bf.At("a pass", bf.MAIN_LOOP), bf._alive, bf._at_door(door)], "reference: 29")
        for key in ("q", "a", "y", "h"):
            position = list(memory[carried + 6:carried + 9])
            machine.play([bf._alive, ([key], 0.4)], "reference: 29")
            if memory[ROOM] != 29:
                break
        if memory[ROOM] != 29:
            break
    # ROOM changes before EEN runs: let the entry into the next room finish.
    machine.play([bf.At("a pass", bf.MAIN_LOOP)], "reference: 30")
    found["left_for"] = memory[ROOM]
    found["position"] = position
    found["written"] = list(memory[WRECKED + 3:WRECKED + 6])
    return found


def numberless_census(snapshot: Path) -> dict[int, int]:
    """Every room from 2 to 80 but the title's entered, and its records with
    a sprite and number 0 counted that SET_THING_ROOM could be given: things
    that can be picked up (+12 bit 5), wraiths (state 11) and the things of
    kind 6 and 10 that destroy them. Room -> how many."""
    import build_fairlight as bf

    machine = _game(snapshot)
    memory = machine.memory
    found = {}
    for room in range(2, 81):
        if room == 79:
            continue
        machine.play(bf._enter(room), "reference: census")
        for record in _records(memory):
            if memory[record + 19] or not memory[record + 4] | memory[record + 5]:
                continue
            kind, state = memory[record + 12], memory[record + 14] & 0x0F
            if kind & 0x20 or state == 11 or kind & 0x0F in (6, 10):
                found[room] = found.get(room, 0) + 1
    return found


# The freeze and the jump ---------------------------------------------------

def freeze_jump(snapshot: Path, pokes=()) -> dict:
    """Room 24: its thing of kind 5 picked up and used (6), SPACE held for
    two passes, twenty passes noted, then Q held for ten."""
    import build_fairlight as bf

    machine = _game(snapshot, pokes, 24)
    memory = machine.memory
    thing = [r for r in _records(memory) if memory[r + 12] & 0x0F == 5][0]
    machine.play([bf.At("a pass", bf.MAIN_LOOP), bf._alive, bf._onto_knight(thing), (["x"], 0.3),
                  ([], 0.3), (["6"], 0.2), ([], 0.3)], "reference: the freeze")
    flags = memory[GAME_FLAGS]
    states = []
    for n in range(20):
        _pass(machine, ["SPACE"] if n < 2 else [])
        states.append(memory[KNIGHT + 14] & 0x0F)
    start = (memory[KNIGHT + 6], memory[KNIGHT + 8])
    for _ in range(10):
        _pass(machine, ["q"])
    return {"flags": flags, "states": states,
            "moved": abs(memory[KNIGHT + 6] - start[0]) + abs(memory[KNIGHT + 8] - start[1])}


# The decoy and the thing of kind 11 ------------------------------------

DECOY, KIND_11 = 11, 7          # their numbers in the object table
DECOY_ROOM, KIND_11_ROOM = 20, 14
ROOM_61 = 61


def decoy_trial(snapshot: Path, order) -> dict:
    """Two things fetched from their rooms into places 1 and 2 in the given
    order, carried into room 61 by a new game's way in, and dropped, place
    1 first; then forty passes, and the knight put on the room's one door,
    the hole down to room 60."""
    import build_fairlight as bf

    machine = _game(snapshot)
    memory = machine.memory
    for place, (room, number) in enumerate(order, 1):
        machine.play(bf._enter(room), "reference: fetch")
        machine.play([bf.At("a pass", bf.MAIN_LOOP), ([str(place)], 0.2), ([], 0.2)], "reference: place")
        machine.play(bf._pick_numbered(number), "reference: fetch")
    machine.play(bf._enter(ROOM_61), "reference: room 61")
    for place in (1, 2):
        machine.play([bf.At("a pass", bf.MAIN_LOOP), bf._alive, ([str(place)], 0.2), ([], 0.2)],
                     "reference: place")
        if place == 2:
            machine.play([(["q"], 0.3), ([], 0.2)], "reference: a step")
        machine.play([(["z"], 0.3), ([], 0.3)], "reference: drop")
    if any(_carried(memory)):
        raise RuntimeError("fairlight_reference: the decoy trial could not drop both things")
    figure = [r for r in _records(memory) if memory[r + 14] & 0x0F in (11, 15) and memory[r + 4] | memory[r + 5]][0]
    start = (memory[figure + 6], memory[figure + 8])
    noted = set()
    for _ in range(40):
        _pass(machine)
        bf._alive(memory)
        noted.add(memory[THINGS_NOTED])
    moved = abs(memory[figure + 6] - start[0]) + abs(memory[figure + 8] - start[1])
    order_in_room = [memory[r + 19] for r in _records(memory)[:2]]
    door = [r for r in _records(memory) if memory[r + 12] & 0x0F == 1][0]
    machine.play([bf.At("a pass", bf.MAIN_LOOP), bf._alive, bf._at_door(door)], "reference: hole")
    for _ in range(30):
        _pass(machine)
        bf._alive(memory)
        if memory[ROOM] != ROOM_61:
            break
    return {"noted": noted, "figure_moved": moved, "state": memory[figure + 14] & 0x0F,
            "room": memory[ROOM], "records": order_in_room}


# The record numbers read too late -----------------------------------------

GUARD_ROOM = 77


def stale_kill(snapshot: Path, out_dir: Path, mend: bool) -> dict:
    """Room 77: the knight fights (B held) until its guard's last strike
    turns it into a helmet (#R$F959), stopping where the helmet is redrawn
    with THIS_RECORD from FOUND_RECORD. With mend, THIS_RECORD is given the
    helmet's own number there instead. The screen as the redraw leaves it,
    and after the next pass."""
    import build_fairlight as bf
    from skoolkit.simutils import A, IXh, IXl

    machine = _game(snapshot, room=GUARD_ROOM)
    memory = machine.memory
    machine.play([bf.At("a pass", bf.MAIN_LOOP)], "reference: fight")
    for _ in range(600):
        bf._alive(memory)
        machine.run(0.05, keys=["b"], stop=0xF9EC)
        if machine.pc == 0xF9EC:
            break
    else:
        raise RuntimeError("fairlight_reference: no guard became a helmet in room 77")
    machine.run(1.0, keys=["b"], stop=STALE_MEET_STORE)
    registers = machine.simulator.registers
    helmet = registers[IXh] << 8 | registers[IXl]
    read = registers[A]
    if mend:
        registers[A] = _number(helmet)
    machine.run(1.0, keys=["b"], stop=0xFA16)
    first = _screen(memory, 1)
    _pass(machine, ["b"])
    return {"read": read, "helmet": _number(helmet), "screens": (first, _screen(memory, 1))}


def stale_pick(snapshot: Path) -> dict:
    """Room 20's decoy picked up: FOUND_RECORD at TAKE_THING, and what the
    pick-up puts in THIS_RECORD for the thing's own redraw."""
    import build_fairlight as bf
    from skoolkit.simutils import A

    machine = _game(snapshot, room=DECOY_ROOM)
    memory = machine.memory
    thing = bf._numbered(DECOY)(memory)
    machine.play([bf.At("a pass", bf.MAIN_LOOP), bf._alive, bf._onto_knight(thing)], "reference: pick")
    machine.run(3.0, keys=["x"], stop=TAKE_THING)
    at_take = memory[FOUND_RECORD]
    machine.run(3.0, keys=["x"], stop=STALE_PICK_STORE)
    return {"thing": _number(thing), "at_take": at_take, "stored": machine.simulator.registers[A]}


def _differing_pixels(one, other) -> int:
    from PIL import ImageChops

    difference = ImageChops.difference(one, other).convert("L")
    return difference.width * difference.height - difference.histogram()[0]


# The pokes' trials --------------------------------------------------------

def life_trials(snapshot: Path, pokes) -> dict:
    """Three ways to lose LIFE: room 77's guard left to come at him for 300
    passes; room 2's troll put on him; a fall from 60 units above the floor
    in room 29."""
    import build_fairlight as bf

    found = {}
    machine = _game(snapshot, pokes, GUARD_ROOM)
    memory = machine.memory
    found["over"] = None
    for n in range(300):
        _pass(machine)
        if not _life(memory):
            found["over"] = n + 1
            break
    found["guard"] = _life(memory)
    machine = _game(snapshot, pokes, 2)
    memory = machine.memory
    troll = [r for r in _records(memory) if memory[r + 14] & 0x0F == 7][0]
    _pass(machine)
    bf._onto_knight(troll)(memory)
    for _ in range(5):
        _pass(machine)
    found["troll"] = _life(memory)
    machine = _game(snapshot, pokes, 29)
    memory = machine.memory
    _pass(machine)
    memory[KNIGHT + 7] = memory[KNIGHT + 7] + 60 & 0xFF
    for _ in range(60):
        _pass(machine)
    found["fall"] = _life(memory)
    return found


def weight_trial(snapshot: Path, pokes, room: int) -> dict:
    """The build's own load-up: the room's things picked up into places 1-5
    in turn, none dropped."""
    import build_fairlight as bf

    machine = _game(snapshot, pokes, room)
    memory = machine.memory
    heavy = False
    for place, record in enumerate(bf._things(memory)[:5]):
        machine.play([bf.At("a pass", bf.MAIN_LOOP), bf._alive, ([str(place + 1)], 0.2), ([], 0.2),
                      bf._onto_knight(record)], "reference: a load")
        # TOO HEAVY is the pick-up's store of message 3 (#R$F52A).
        machine.run(0.3, ["x"], stop=WEIGHT_TEST + 2)
        heavy = heavy or machine.pc == WEIGHT_TEST + 2
        machine.run(0.3)
    machine.play([bf.At("a pass", bf.MAIN_LOOP)], "reference: a load")
    return {"carried": sum(1 for record in _carried(memory) if record),
            "weight": memory[CARRIED_WEIGHT], "heavy": heavy}


LOCKED_ROOM, LOCKED_TO = 21, 22


def key_trial(snapshot: Path, pokes) -> dict:
    """Room 21's door to room 22, which needs thing 1 as its key: the knight
    put 12 short of it, within its width, and Q held."""
    machine = _game(snapshot, pokes, LOCKED_ROOM)
    memory = machine.memory
    door = _door_to(memory, LOCKED_TO)
    key = memory[door + 14]
    memory[KNIGHT + 6] = memory[door + 6] + 2
    memory[KNIGHT + 8] = memory[door + 8] - 12
    locked = False
    for _ in range(12):
        _pass(machine, ["q"])
        locked = locked or memory[MESSAGE] == MESSAGE_LOCKED
        if memory[ROOM] != LOCKED_ROOM:
            break
    return {"key": key, "room": memory[ROOM], "locked": locked}


START_ROOM = 33


def start_trial(snapshot: Path, out_dir: Path) -> dict:
    """ROOM poked in the snapshot, before the start-up copies the variables
    to the master copy; a game started; the room at its first pass."""
    import build_fairlight as bf

    found = {"plain": _game(snapshot).memory[ROOM]}
    machine = _game(snapshot, [(ROOM, START_ROOM)])
    memory = machine.memory
    found["poked"] = memory[ROOM]
    for _ in range(3):
        _pass(machine)
    _screen(memory).save(out_dir / "start.png")
    # A second game after that one: the master copy still says so.
    machine.play([bf.At("a pass", bf.MAIN_LOOP), (["SS", "0"], 0.3), ([], 0.3),
                  bf.At("GAME OVER", TITLE_WAIT, 30.0), ([], 0.3), (["SPACE"], 0.2),
                  bf.At("the title", TITLE_WAIT, 30.0), ([], 0.3), (["SPACE"], 0.2),
                  bf.At("the next game", bf.MAIN_LOOP, 30.0)], "reference: again")
    found["again"] = memory[ROOM]
    return found


FREEZE_ROOM = 2


def freeze_trial(snapshot: Path, pokes) -> dict:
    """Room 2 for forty passes: how far its creatures (states 6 up) move;
    then Q held for ten passes."""
    machine = _game(snapshot, pokes, FREEZE_ROOM)
    memory = machine.memory
    _pass(machine)
    creatures = [r for r in _records(memory) if memory[r + 16] & 0x1F and memory[r + 14] & 0x0F >= 6
                 and memory[r + 14] & 0x0F != 8]
    where = {r: tuple(memory[r + 6:r + 9]) for r in creatures}
    moved = 0
    for _ in range(40):
        _pass(machine)
        memory[LIFE_TENS] = memory[LIFE_UNITS] = 9
        for record in creatures:
            now = tuple(memory[record + 6:record + 9])
            moved += sum(abs(a - b) for a, b in zip(now, where[record]))
            where[record] = now
    start = (memory[KNIGHT + 6], memory[KNIGHT + 8])
    for _ in range(10):
        _pass(machine, ["q"])
    return {"creatures": len(creatures), "moved": moved, "flags": memory[GAME_FLAGS],
            "walked": abs(memory[KNIGHT + 6] - start[0]) + abs(memory[KNIGHT + 8] - start[1])}


# The facts' runs -----------------------------------------------------------

TRAPDOOR_ROOM = 10


def trapdoor_trial(snapshot: Path, out_dir: Path) -> dict:
    """Room 10, a picture of it, then the knight put over the middle of its
    floor's hole and H held: where he ends up."""
    import build_fairlight as bf

    machine = _game(snapshot, room=TRAPDOOR_ROOM)
    memory = machine.memory
    for _ in range(3):
        _pass(machine)
    _screen(memory).save(out_dir / "room10.png")
    hole = _door_to(memory, 0)
    life = _life(memory)
    memory[KNIGHT + 6] = memory[hole + 6] + memory[hole + 9] // 2
    memory[KNIGHT + 8] = memory[hole + 8] + memory[hole + 11] // 2
    machine.run(3.0, ["h"], stop=AFTER_ROOMST)
    reached = machine.pc == AFTER_ROOMST
    machine.run(3.0, [], stop=TITLE_WAIT)
    return {"reached": reached, "life": life, "room": memory[ROOM], "waiting": machine.pc == TITLE_WAIT,
            "hole": list(memory[hole + 6:hole + 12])}


def quit_trial(snapshot: Path) -> dict:
    """SYMBOL SHIFT and 0 held at a pass; and the interrupt flip-flop there."""
    import build_fairlight as bf
    from skoolkit.simutils import IFF

    machine = _game(snapshot)
    iff = machine.simulator.registers[IFF]
    machine.play([bf.At("a pass", bf.MAIN_LOOP)], "reference: quit")
    machine.run(2.0, ["SS", "0"], stop=AFTER_ROOMST)
    return {"quit": machine.pc == AFTER_ROOMST, "iff": iff, "life": _life(machine.memory)}


SWEDISH = (22, 23)              # textures, fill codes $FC and $FD
SCRATCH_STREAM = 0xDB00         # page $DB: not in use while a room is drawn


def letters_picture(snapshot: Path, out_dir: Path) -> None:
    """Two boxes filled with textures 22 and 23 by the game's own drawing:
    a made-up room record -- a colour byte, $E4 $00 so that the boxes'
    outlines go only into the fill's map, a box, a point inside it and its
    fill code, twice, then $E4 $01 and the end -- drawn by DRAW_ROOM_RECORD
    (#R$E597) with the drawing variables set as #R$E55B sets them."""
    from skoolkit.simutils import IXh, IXl, IYh, IYl, SP

    def box(bottom, left, top, right, texture):
        return [0xC0, bottom, left, 0xC3, 0xC7, bottom, right, top, right, top, left, bottom, left,
                0xC4, 0xC8, (bottom + top) // 2, (left + right) // 2, 0xE6 + texture]

    # Outlines one pixel outside whole 16 by 16 tiles, which are anchored to
    # the screen: rows 96-143 up from the bottom are lines 48-95 down.
    stream = ([0x47, 0xE4, 0x00] + box(95, 15, 144, 112, SWEDISH[0])
              + box(95, 127, 144, 224, SWEDISH[1]) + [0xE4, 0x01, 0xE5])
    machine = _game(snapshot)
    memory = machine.memory
    registers = machine.simulator.registers
    memory[SCRATCH_STREAM:SCRATCH_STREAM + len(stream)] = stream
    memory[0xFFDF:0xFFDF + 20] = memory[0xE582:0xE582 + 20]
    done = 0x0005                                   # a return address in the ROM, to stop at
    registers[SP] -= 2
    memory[registers[SP]], memory[registers[SP] + 1] = done & 0xFF, done >> 8
    registers[IXh], registers[IXl] = SCRATCH_STREAM >> 8, SCRATCH_STREAM & 0xFF
    registers[IYh], registers[IYl] = 0xFF, 0x80
    machine.pc = 0xE597
    machine.run(5.0, stop=done)
    if machine.pc != done:
        raise RuntimeError("fairlight_reference: the letters' drawing did not return")
    memory[0x5800:0x5B00] = [0x47] * 0x300
    _screen(memory, 3).crop((3 * 8, 3 * 40, 3 * 232, 3 * 104)).save(out_dir / "letters.png")


# The author's source text --------------------------------------------------

SOURCE_WITH_WEI3 = (0x617C, 0x639C)     # the stretch before the master copy


def source_lines(memory, start: int, end: int) -> list[tuple[int, str]]:
    """The numbered lines of source text in a stretch: CR, a two-byte line
    number, the text, tabs between its fields. The first line is cut off."""
    out = []
    at = start
    while at < end and memory[at] != 13:
        at += 1
    while at + 3 < end:
        number = memory[at + 1] | memory[at + 2] << 8
        text, at = [], at + 3
        while at < end and memory[at] != 13:
            text.append(chr(memory[at]) if memory[at] in (9,) or 32 <= memory[at] < 127 else "?")
            at += 1
        if at >= end:
            break
        out.append((number, "".join(text)))
    return out


def wei3_excerpt(memory, instructions: dict[int, str]) -> tuple[list[tuple[int, str]], int]:
    """The author's lines from WEI3 to the RET after it, and how many of
    them start with the same mnemonic as the game's instructions from
    TAKE_THING on."""
    lines = source_lines(memory, *SOURCE_WITH_WEI3)
    first = next(i for i, (_, text) in enumerate(lines) if text.startswith("WEI3"))
    excerpt = []
    for number, text in lines[first:]:
        excerpt.append((number, text))
        if text.split("\t")[1:2] == ["RET"]:
            break
    game = []
    address = TAKE_THING
    while len(game) < len(excerpt):
        instruction = instructions[address]
        game.append(instruction.split()[0])
        address = next(a for a in sorted(instructions) if a > address)
    same = sum(1 for (_, text), word in zip(excerpt, game) if text.split("\t")[1] == word)
    return excerpt, same


def _source_html(excerpt) -> str:
    rows = []
    for number, text in excerpt:
        fields = text.split("\t")
        label, rest = fields[0], fields[1:]
        # SkoolKit drops a line's leading spaces, so every row starts with
        # its line number, and the number is not padded.
        rows.append(f"{number} {label:<6}{' '.join(f'{f:<6}' for f in rest).rstrip()}")
    return "<pre>" + html.escape("\n".join(rows)) + "</pre>"


# --------------------------------------------------------------------------
# The bugs
# --------------------------------------------------------------------------

def _bugs(numberless: dict, lock: dict, decoy: dict, stale: dict) -> dict[str, str]:
    pick = numberless["pick"]
    written = numberless["written"]
    position = numberless["position"]
    as_is, release_1 = lock["as_is"], lock["release_1"]
    hides, shows = decoy["hides"], decoy["shows"]
    kill, pick_stale = stale["kill"], stale["pick"]

    def states(values):
        return " ".join(str(v) for v in values)

    return {
        "Bug:numberless:Room 19's two things wreck a door in room 25": f"""\
Every thing the knight can carry from room to room has a number, its place in
the object table (#R$A924), and its record keeps it at +19 (#R$EACC). When a
thing is picked up, dropped, stolen or destroyed, #R$F4E6(SET_THING_ROOM) (the
author's ROMM) finds its entry by counting six bytes a number from just below
the table, with DJNZ; and when the knight leaves a room, #R$F906(EEN) saves
where each thing is the same way. Room 19's drawing places two things of its
own -- kind 4 (used, they add ten to LIFE), bouncing, hurting at a touch, and
able to be picked up -- which are not in the table and so have number 0. For
them DJNZ goes round 256 times, and the byte written is 1536 bytes on: ${WRECKED:04X},
the third byte of an eleven-byte entry, the door from room 25 to room 21.
Its x is {numberless['door'][2]}.

Run in the simulator (checked at every build): as the game starts, the knight
put in that doorway and walked into it arrives in room {numberless['before']}. In room 19,
put ten units short of one of the two things, X took it
({'LIFE unchanged' if pick['life'][0] == pick['life'][1] else f"LIFE {pick['life'][0]} to {pick['life'][1]}"}), and ${WRECKED:04X} became ${pick['byte']:02X}, the room
SET_THING_ROOM gives a thing carried. The door's record in room 25 now had x
{numberless['door_x']}, far outside the room, and walking into the doorway left him in room
{numberless['after']}: the door no longer exists. Dropping the thing writes the room
it is dropped in instead, so carried to room {MENDING_ROOM} and dropped there it put
back the {numberless['dropped']} the door had, and room 25's doorway led to room
{numberless['mended']} again. Carried out of room 29 by its door to room {numberless['left_for']}, its
record -- a carried thing's record comes straight after the knight's -- came
before the room's doors, so EEN wrote its position ({', '.join(str(v) for v in position)}) over the next three bytes of the same entry: the
door's destination, its key and the x the knight arrives at became
{', '.join(str(v) for v in written)}. From then on the door, wherever its x, leads to room
{written[0]}, which does not exist, and wants thing {written[1]} as its key.

<div><img class="kl-scene" src="../{IMAGES}/room19.png" alt="Room 19 just after one of its own things has been picked up: it shows in the panel's box"/></div>
<div><img class="kl-scene" src="../{IMAGES}/room25.png" alt="Room 25 afterwards: the knight at the room's near edge, the way to room 21, and unable to go on"/></div>
They are the only numberless things that can be carried: every room 2 to 80
was entered in the simulator (at every build) and every record read, and no
other record with a sprite and number 0 can be picked up, stolen by the ghost
or destroyed with a wraith, the three ways to SET_THING_ROOM. Reaching one is the only
difficulty: it hurts at a touch, costing ten LIFE and vanishing
(#R$F959), and the pick-up's search reaches four units past the knight.
The author may have met the same trouble once: the five bytes the pits'
code jumps over (#R$FA74) would have called SET_THING_ROOM for the knight,
whose number is 0 too (read; why they are skipped is not known).""",

        "Bug:freeze:Release 1: a jump while the creatures are frozen stops the knight for good": f"""\
Using a thing of kind 5 freezes the creatures until the next room: #R$FE47
sets bit 7 of GAME_FLAGS, which only a room's entry clears (#R$FE15). While
it is set, #R$F1E0(CHE3D) sends the knight's state, 8, to his controls
(#R$F3CD) and treats every other state as state 0, a thing lying still:
only the fall. The knight's jump is state 5, counted down by its own case and
ended by setting state 8 again. Release 2 lets state 5 through as well
(CP 5 : JR NZ at ${FREEZE_TEST:04X}). Release 1 has JR I00 there: a jump that begins
during the freeze is handled as a thing lying still, nothing counts it down,
and state 8 never comes back. With no controls he cannot walk to another
room, the only thing that ends the freeze.

Run in the simulator (at every build), Release 2 as it is and with Release
1's two bytes put in its place: in room 24 its thing of kind 5 was picked
up and used (GAME_FLAGS ${as_is['flags']:02X}), SPACE held for two passes, and the
knight's state noted each pass for twenty. Release 2: {states(as_is['states'])},
and then Q moved him {as_is['moved']} units in ten passes. Release 1's instruction:
{states(release_1['states'])}, and Q moved him {release_1['moved']}. The same trial on
Release 1 itself, loaded from its own tape, gave the same states. Ending the
game with SYMBOL SHIFT and 0 is the way out (see
<a href="facts.html#keys">the facts</a>); a new game starts with the freeze
cleared. This is surely why Release 2 changed that instruction and no other
in the object dispatcher (inferred; <a href="facts.html#releases">the
facts</a> list what else changed).""",

        "Bug:decoy:A decoy on the floor hides the thing of kind 11": f"""\
Each pass #R$F1E0(CHE3D) notes, among the things lying still, the first decoy
(kind 8, which the guards of state 9 go after) and whether a thing of kind 11
lies in the room; room 61 waits for that thing -- its creature stays still and
its one way out, a hole down to room 60, stays shut until it lies there
(#R$F3A1, #R$F7C4). The test for kind 11 (CP $0B at ${I01:04X}) compares A, which holds
the thing's kind only on the way in that has just found no decoy. Once a decoy
is known, the other way in reaches the same CP with A holding the thing's
state, 0 for anything lying still. So a thing of kind 11 whose record comes
after a decoy's is never noticed. (With the creatures frozen, a wraith's state
11 would pass the test instead; nothing the flag controls is affected by that
outside room 61.)

Run in the simulator (at every build): the decoy (thing {DECOY}, from room
{DECOY_ROOM}) and the thing of kind 11 (thing {KIND_11}, from room {KIND_11_ROOM}) fetched into two
places, carried into room 61 and dropped there, place 1 first. A carried
thing's record keeps its place's order, so the first place's thing is looked
at first each pass. Decoy in place 1: THINGS_NOTED stayed
{', '.join(f'${v:02X}' for v in sorted(hides['noted']))} for forty passes, the creature moved {hides['figure_moved']} units, and the
knight put on the hole stayed in room {hides['room']}. The other way round:
THINGS_NOTED {', '.join(f'${v:02X}' for v in sorted(shows['noted']))}, the creature, woken, moved {shows['figure_moved']}
units, and the hole took him to room {shows['room']}. Picking the decoy up again
clears the flags and puts things right. Only room 61 cares, and only a
player who brings a decoy there and drops it before the thing of kind 11
meets it.""",

        "Bug:stale:Two redraws read a record number after it has changed": f"""\
FOUND_RECORD (#R$FFF8) holds the number of the record a search last met
(#R$FCA5, the author's T+20); it is also where #R$EE8D keeps a sprite's width
in bytes while drawing it. Twice the game reads it as a record's number when
something has been drawn since the search, so that it holds a width. #R$F959, when a thing has vanished or a guard has
become a helmet, finishes the mover's move -- redrawing the mover -- and then
takes FOUND_RECORD as THIS_RECORD for redrawing the other (${STALE_MEET:04X}); the
pick-up (#R$F52A) redraws the knight stooping, then does the same for the thing
it has taken (${STALE_PICK:04X}). THIS_RECORD is the one record #R$ECBD leaves out
of a redraw, and a width in bytes is 1 to 6 -- no sprite is wider than 48
pixels -- which is always one of the six fixed records the redraw never
looks at anyway. So nothing is left out. A thing that has vanished or been
taken is left out regardless (#R$ED47 skips a record whose bit 5 of +16 is
set); a helmet is not, and is taken as lying in front of itself, so for one
pass the screen keeps what it showed inside the helmet's shape.

Run in the simulator (at every build): room 20's decoy picked up,
FOUND_RECORD was {pick_stale['at_take']} (the decoy's record) at TAKE_THING and THIS_RECORD was given
{pick_stale['stored']}. In room 77, the knight fighting with B held until the guard's
last strike: THIS_RECORD was given {kill['read']} for the helmet, record {kill['helmet']}.
Given {kill['helmet']} instead, the screen after the redraw differed in
{kill['first']} pixel{'s' if kill['first'] != 1 else ''}, and after the next pass in {kill['next']}: the helmet lies
mostly behind the knight, where the old picture and the new one agree. Harmless
in practice.""",
    }


# --------------------------------------------------------------------------
# The pokes
# --------------------------------------------------------------------------

def _pokes(life: dict, weight: dict, keys: dict, start: dict, freeze: dict) -> dict[str, str]:
    lives_as_is, lives_poked = life["as_is"], life["poked"]
    over = (f"LIFE ran out after {lives_as_is['over']} passes and the game was over"
            if lives_as_is["over"] else f"LIFE was {lives_as_is['guard']} after 300 passes")

    def loads(trials):
        return "; ".join(f"room {room}, {t['carried']} carried, weight {t['weight']}"
                         + (", TOO HEAVY shown" if t["heavy"] else "")
                         for room, t in trials.items())

    return {
        "Poke:life:LIFE that never goes down": f"""\
Everything that takes LIFE goes through DECLIF (in #R$F1B4): ten for a thing
that hurts at a touch, one for a fighter's touch, three for a striking
creature, one a pass for a long fall. A RET as its first instruction and
none of them takes any. The pits' floors in rooms 9 and 12 (#R$F959) still
end the game: they set LIFE to 0 directly, and hide the knight.

Tested in the simulator. Room 77, standing still for 300 passes while its
guard came at him: without the poke {over}; with it LIFE stayed at
{lives_poked['guard']}. Room 2's troll put on him: {lives_as_is['troll']} and {lives_poked['troll']}. A fall from 60
units above the floor of room 29: {lives_as_is['fall']} and {lives_poked['fall']}, from 99. ZXDB's pokes
file (<a href="{ZXDB_URL}">the game's entry</a>) does it another way,
POKE 61893,0, which sends the store of LIFE's new value into the ROM; tried
in the same trials when this was written, it did the same.

{_poke_line(*LIFE_POKE)}""",

        "Poke:weight:No weight limit": f"""\
The pick-up (#R$F52A) adds the thing's weight to what the knight carries and
refuses it, with TOO HEAVY, at 8 or more. Make the JR C after the test a
plain JR and everything is taken; a load of five of the heaviest things
weighs 30, well inside the byte. ZXDB's pokes file (<a href="{ZXDB_URL}">the
game's entry</a>) has this same poke.

Tested in the simulator, the build's own load-up (each thing of the room put
where he stands and taken into places 1 to 5 in turn): without the poke,
{loads(weight['as_is'])}. With it, {loads(weight['poked'])}.

{_poke_line(*WEIGHT_POKE)}""",

        "Poke:keys:Every door without its key": f"""\
A door that needs a key names the thing's number at +14 of its record, and
#R$F7C4 compares it with the thing in the place in use, saying LOCKED if it is
not there. Make the JR Z that skips the test for a door with no key a plain
JR and no door needs one -- including room 31's way into room 81, the end of
the quest, which needs thing 8. The way out of room 61 still waits for the
thing of kind 11 (<a href="bugs.html#decoy">the bugs</a>).

Tested in the simulator: room 21's door to room 22, which needs thing
{keys['as_is']['key']}, walked into with nothing carried. Without the poke:
{'LOCKED, and' if keys['as_is']['locked'] else ''} still in room {keys['as_is']['room']}. With it: room {keys['poked']['room']}. ZXDB's pokes
file (<a href="{ZXDB_URL}">the game's entry</a>) makes the JR Z after the
comparison a JR instead, POKE 63478,24; tried when this was written, it
opened the same door.

{_poke_line(*KEY_POKE)}""",

        "Poke:start:Start in any room": f"""\
A new game takes its variables from a master copy (#R$F065) that the
start-up (#R$C47C) makes of the variables as the tape left them, ROOM (${ROOM:04X})
among them: {start['plain']}. Poke ROOM before the game runs -- in a snapshot
taken at the hand-over -- and every game starts in that room, with the
knight where a new game puts him in room {start['plain']}. In nine of the other rooms
(3, 4, 9, 12, 23, 46, 52, 55 and 69) that is inside something or over a pit,
and he could not walk more than one of the four ways from there (run for
every room when this was written). ZXDB's pokes file (<a href="{ZXDB_URL}">the
game's entry</a>) pokes the same address. Room 81 is the end of the quest:
started there, a game prints its verdict (failure) and goes to GAME OVER.
Room 1, the dark room GAME OVER is printed over, can be walked in (both run).

Tested in the simulator, room {START_ROOM}: the first pass was in room {start['poked']}, and after
SYMBOL SHIFT and 0, GAME OVER and the title, the next game began in room
{start['again']} too. Without the poke, room {start['plain']}.

<div><img class="kl-scene" src="../{IMAGES}/start.png" alt="A new game begun in room 33, where the thing the end of the quest asks for lies"/></div>
POKE {ROOM},n (n from 1 to 81; before the game starts)""",

        "Poke:freeze:Every creature frozen, in every room": f"""\
Using a thing of kind 5 freezes the creatures until the next room: bit 7 of
GAME_FLAGS, set by #R$FE47 and cleared when a room is entered, because
#R$FE15 sets GAME_FLAGS to $05. Make that ${FROZEN_FLAGS:02X} and every room starts frozen:
creatures only fall, and nothing chases, patrols or strikes. The knight
still walks and jumps (in Release 2; see <a href="bugs.html#freeze">the
bugs</a> for Release 1). Things that hurt at a touch still hurt if he walks
into them.

Tested in the simulator, room 2 for forty passes: without the poke its
{freeze['as_is']['creatures']} creature{'s' if freeze['as_is']['creatures'] != 1 else ''} moved {freeze['as_is']['moved']} units in all; with it {freeze['poked']['moved']}, GAME_FLAGS ${freeze['poked']['flags']:02X},
and Q then moved the knight {freeze['poked']['walked']} units in ten passes.

{_poke_line(*FREEZE_POKE)}""",
    }


# --------------------------------------------------------------------------
# The facts
# --------------------------------------------------------------------------

def _facts(memory, excerpt, same: int, symbol_count: int, symbol_starts: int, used: set[int],
           trapdoor: dict, quit: dict, eidi: list[tuple[int, str]]) -> dict[str, str]:
    unused = [t for t in SWEDISH if 0xE6 + t not in used]
    return {
        "Fact:source:The author's source text and symbol table, left in memory": f"""\
The tape carries more than the game. When Bo Jangeborg saved it, parts of
his assembler's working memory went with it: pieces of the game's own source
text -- numbered lines, the fields separated by tabs, in several stretches
(#R$617C, #R$A8FC, #R$BCA4, #R$C4BA, #R$D135, #R$D694 and others) -- and part
of the assembler's symbol table (#R$DD39), whose {symbol_count} whole names and values are this very
release's: {symbol_starts} of them are the first instruction of a routine in this listing.
The game never reads either, and much of the text is overwritten when the
game starts. They give the listing many of its names: ROOMST, ZOOMIN, CHE3D,
EEN, MESS2, WAIT, PRINT, and the labels I0 to I95 inside #R$F1E0. The text
also shows that he reached the variables at $FF80 as V+n and the working
copy of a record at $FFE4 as T+n.

Here, read from the snapshot at build time, are his lines for the end of the
pick-up (the lines from WEI3 to its RET, at #R$617C); {same} of the {len(excerpt)}
begin with the same instruction as the game's code from ${TAKE_THING:04X} on
(#R$F52A), which is what they assembled to:

{_source_html(excerpt)}
ROMM is #R$F4E6, DOE the instruction at $F4E3, SRP #R$ECBD and INFOR #R$EC4C.""",

        "Fact:swedish:Swedish letters among the textures": f"""\
The fills that give the rooms their stone, brick and wood take their pattern
from 26 textures of 16 by 16 pixels (#R$E0A4). Two of them are not patterns
at all: texture {SWEDISH[0]} (#R$E364) holds the capitals Å, Ä and Ö, texture {SWEDISH[1]}
(#R$E384) the small å, ä and ö -- the three letters the Swedish alphabet has
beyond the English one. The game's font (#R$BAD8) has no use for them, and
{'no room fills with either' if len(unused) == 2 else 'a room fills with one of them'} (read: every room's and part's commands, counted at every
build). A reasonable guess is that they belong to the author's own tools, left
among the textures; Bo Jangeborg is Swedish.

Drawn by the game's own fill (at every build): two boxes outlined into the
fill's map and filled with fill codes $FC and $FD by #R$E597, the way a room
is drawn:

<div><img class="kl-scene" src="../{IMAGES}/letters.png" alt="Two areas filled with textures 22 and 23: rows of Swedish capitals and small letters with rings and dots"/></div>""",

        "Fact:interrupts:Interrupts off, all game": f"""\
The game runs with interrupts disabled. The only EI and DI instructions in it
are {', '.join(f'{what} at ${a:04X}' for a, what in eidi)} (searched, at every build). The loading
tune (#R$C000) turns interrupts off while it plays and on as it ends, for
two instructions: the start-up's DI (#R$C487) comes straight after and nothing
turns them on again. It has to: the sprites at #R$5B00 lie over the ROM's
system variables, where the ROM's interrupt routine would count FRAMES and
scan the keyboard fifty times a second. Nothing paces the game either: each
pass of the main loop (#R$FE47) takes as long as its room takes to update.
Run in the simulator (at every build): the interrupt flip-flop was
{quit['iff']} at the first pass of a game.""",

        "Fact:keys:6 and 7 use, and SYMBOL SHIFT with 0 ends the game": f"""\
The title page lists the walking, jumping, fighting, taking and dropping
keys. The others are read by the main loop (#R$FE47): 1 to 5 choose one of
the five places a thing is carried in; 6 or 7 use the thing in it (a thing of
kind 4 adds ten to LIFE, 6 fills it, 5 freezes the creatures, 9 carries the
knight off to room 30, and each is used up); SPACE with SYMBOL SHIFT pauses
until a key; 9 turns the Kempston joystick on and off; and 0 with SYMBOL
SHIFT returns from the game at once, to GAME OVER with LIFE still in hand.
Read, and run in the simulator (at every build): SYMBOL SHIFT and 0 held at
a pass {'ended the game' if quit['quit'] else 'did not end the game'} with LIFE at {quit['life']}.""",

        "Fact:trapdoor:A trapdoor in room 10 ends the game": f"""\
Every door's record names the room behind it (#R$F7C4), and one names room 0:
a hole in the floor of room 10, which the knight falls through. There is no
room 0. #R$F8EC goes to #R$FD20(ROOMST) with it as it would for any room,
and ROOMST's first test is for room 0, on which it returns -- the way the
main loop leaves it at the end of a game. So the fall ends the game on the
spot, whatever LIFE is left, with GAME OVER.

Run in the simulator (at every build): room 10 entered, and the knight put
over the middle of the hole (x {trapdoor['hole'][0]} to {trapdoor['hole'][0] + trapdoor['hole'][3]}, y {trapdoor['hole'][2]} to
{trapdoor['hole'][2] + trapdoor['hole'][5]}) with H held: the game returned from ROOMST with LIFE at
{trapdoor['life']}, drew room {trapdoor['room']} behind GAME OVER and waited for a key.

<div><img class="kl-scene" src="../{IMAGES}/room10.png" alt="Room 10: a cave whose floor has a dark hole in it"/></div>""",

        "Fact:releases:What Release 2 changed": """\
Fairlight came out twice on tape for the 48K Spectrum, and this is Release 2.
Compared byte for byte with Release 1, both loaded from their tapes and
stopped where the loader hands over, it changes five things. The Kempston
joystick, which Release 1 has switched off (its reading routine starts XOR A
: RET), becomes an option: 9 turns it on and off (#R$FE47, #R$F0E6), and the
title page says so. The setting up of the tables moves out of the title
routine into the start-up (#R$C47C), in memory the game overwrites once it
runs, 52 bytes the resident code no longer needs. The object dispatcher lets
the knight's jump through the freeze (see <a href="bugs.html#freeze">the
bugs</a>). Room 67 loses a part it drew and an origin it set. Three door
records differ in a byte each. Everything else that differs is leftover
text, the symbol table's values and the loader's checksum. The rooms, the
sprites and the templates are the same.""",

        "Fact:credits:Who made it": f"""\
The title page (#R$B686) names Bo Jangeborg and The Edge, and no one else. ZXDB
(<a href="{ZXDB_URL}">its entry</a>) credits Bo Jangeborg with the code, the
design, the level design, the story and in-game graphics; Jack Wilkes with
in-game graphics and the loading screen; Niclas Osterlin with in-game
graphics; Mark Alexander with the music (the loading tune, #R$C000); and
Stuart Hughes with the inlay's art. It was published by The Edge in 1985 at
&pound;9.95, as Fairlight: A Prelude, and its last lines (#R$DFF2) point to
the sequel, Fairlight II.""",

        "Fact:krumlinde:Where this reading differs from Krumlinde's": f"""\
Ville Krumlinde's disassembly (<a href="{KRUMLINDE_URL}">FairlightZ80</a>),
labelled and commented, came first, and this one was made beside it; many of
its names and findings are his, credited where they are used. His snapshot
was taken in the middle of a game, which hid the start-up and the loader from
him, and several of his conclusions come out differently here. Each was
checked against the code, and those marked run also in the simulator:
<ul class="kl-list">
<li><b>The entry point.</b> He starts at the title routine (#R$F065) and
rebuilds the stack for it; the loader returns to #R$C47C, which sets the stack,
plays the loading tune, sets IY, puts the tables in place and then jumps to
the title (run).</li>
<li><b>Interrupts.</b> He has the ROM's interrupt running fifty times a
second; the start-up turns interrupts off for good (read and run; see
<a href="#interrupts">above</a>).</li>
<li><b>The compositor's four pages.</b> He concludes that two of the four
256-byte pages at $D800 (#R$E3E4) never reach the screen; the compositor
reads all four, stepping from one to the next, and the pages behind the
moving object carry the objects behind it (read, and run: the pages drawn
out in the middle of a redraw).</li>
<li><b>The textures.</b> He reads a texture as sixteen rows of two bytes;
bytes 8 to 15 are the right-hand half of the same eight rows, a 16 by 16 tile
in four 8 by 8 cells (read, and drawn: the brick textures only join up this
way).</li>
<li><b>The room's box.</b> The six records before the knight's
(#R$BC18) are the floor, the ceiling and the four walls, which a room's patch
codes set (#R$E5E8); he has the patches changing the object table (read, and
run: the records read in every room).</li>
<li><b>Saving the room's things.</b> #R$F906(EEN) copies each thing's position
from its record into the object table as the knight leaves, not the other way
(run).</li>
<li><b>The use key</b> is 6 or 7, not 0; 0 with SYMBOL SHIFT ends the game,
and SPACE with SYMBOL SHIFT pauses (run).</li>
<li><b>The carried things.</b> #R$FD9C (the author's ROS) walks the five places
a thing is carried in, not a list of the room's objects (read).</li>
</ul>""",
    }


# --------------------------------------------------------------------------
# build
# --------------------------------------------------------------------------

def _fill_codes_used(memory) -> set[int]:
    import fairlight_data as fd

    used = set()
    for base, count, skip in ((fd.ROOMS, fd.ROOM_COUNT, 3), (fd.PARTS, fd.PART_COUNT, 2)):
        for address, length in fd._stream_records(memory, base, count):
            for at, _, what in fd.room_commands(memory, address + skip, address + length):
                if what.startswith("Fill with texture"):
                    used.add(memory[at])
    return used


def _check(condition: bool, what: str) -> None:
    if not condition:
        raise RuntimeError(f"fairlight_reference: {what}")


def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    import build_fairlight as bf
    import fairlight_data as fd

    snapshot = Path(snapshot)
    entries, instructions = read_listing(snapshot.with_name("fairlight.skool"))
    for address, expected in EXPECTED_INSTRUCTIONS.items():
        found = instructions.get(address, "")
        _check(found == expected, f"${address:04X} is '{found}', not {expected}: the pokes and "
                                  f"bugs need checking")
    tape = bf.game_memory(snapshot)
    out_dir = Path(html_dir) / IMAGES
    out_dir.mkdir(parents=True, exist_ok=True)

    log("  reference: room 19's numberless things and room 25's door...")
    numberless = numberless_trials(snapshot, out_dir)
    pick = numberless["pick"]
    _check(numberless["door"][2] == MENDING_ROOM, f"the door's x is {numberless['door'][2]}, not "
                                                  f"{MENDING_ROOM}")
    _check(numberless["before"] == 21, "room 25's door did not lead to room 21")
    _check(pick["taken"] and pick["byte"] == 0xFE, "the numberless thing's pick-up did not "
                                                   "write $FE into the door")
    _check(numberless["after"] == 25 and numberless["door_x"] == 0xFE,
           "the wrecked door still worked")
    _check(numberless["dropped"] == MENDING_ROOM and numberless["mended"] == 21,
           "the drop in room 50 did not mend the door")
    _check(numberless["left_for"] == 30 and numberless["written"] == numberless["position"],
           "EEN did not write the carried thing's position into the door")
    census = numberless_census(snapshot)
    _check(census == {19: 2}, f"numberless records that SET_THING_ROOM could meet: {census}")

    log("  reference: the freeze and the jump, Release 2 and Release 1's instruction...")
    lock = {"as_is": freeze_jump(snapshot), "release_1": freeze_jump(snapshot, RELEASE_1_FREEZE)}
    _check(lock["as_is"]["flags"] & 0x80 and lock["release_1"]["flags"] & 0x80,
           "the thing of kind 5 did not freeze the creatures")
    _check(lock["as_is"]["states"][-1] == 8 and lock["as_is"]["moved"] > 0,
           "Release 2's jump did not end under the freeze")
    _check(set(lock["release_1"]["states"][1:]) == {5} and lock["release_1"]["moved"] == 0,
           "Release 1's instruction did not lock the knight")

    log("  reference: a decoy and the thing of kind 11 in room 61...")
    decoy = {"hides": decoy_trial(snapshot, [(DECOY_ROOM, DECOY), (KIND_11_ROOM, KIND_11)]),
             "shows": decoy_trial(snapshot, [(KIND_11_ROOM, KIND_11), (DECOY_ROOM, DECOY)])}
    _check(decoy["hides"]["records"] == [DECOY, KIND_11] and not any(v & 2 for v in decoy["hides"]["noted"])
           and decoy["hides"]["room"] == ROOM_61 and not decoy["hides"]["figure_moved"],
           f"the decoy did not hide the thing of kind 11: {decoy['hides']}")
    _check(all(v & 2 for v in decoy["shows"]["noted"]) and decoy["shows"]["room"] == 60,
           f"the thing of kind 11 was not noticed first: {decoy['shows']}")

    log("  reference: the stale record numbers...")
    as_is = stale_kill(snapshot, out_dir, False)
    mended = stale_kill(snapshot, out_dir, True)
    stale = {"pick": stale_pick(snapshot),
             "kill": {"read": as_is["read"], "helmet": as_is["helmet"],
                      "first": _differing_pixels(as_is["screens"][0], mended["screens"][0]),
                      "next": _differing_pixels(as_is["screens"][1], mended["screens"][1])}}
    _check(1 <= as_is["read"] <= 6 and as_is["helmet"] > 7, "the helmet's stale number is not "
                                                             "a fixed record's")
    _check(stale["pick"]["at_take"] == stale["pick"]["thing"] and 1 <= stale["pick"]["stored"] <= 6,
           "the pick-up's record number is not stale")

    log("  reference: the pokes against their trials...")
    life = {"as_is": life_trials(snapshot, []), "poked": life_trials(snapshot, LIFE_POKE)}
    _check(life["as_is"]["guard"] < 99 and life["as_is"]["troll"] < 99 and life["as_is"]["fall"] < 99,
           "LIFE was not lost without the poke")
    _check(life["poked"] == {"over": None, "guard": 99, "troll": 99, "fall": 99},
           f"the LIFE poke let LIFE go: {life['poked']}")
    heavy_rooms = (20, 34)
    weight = {name: {room: weight_trial(snapshot, pokes, room) for room in heavy_rooms}
              for name, pokes in (("as_is", []), ("poked", WEIGHT_POKE))}
    _check(all(t["heavy"] and t["weight"] < 8 for t in weight["as_is"].values()),
           "no load was too heavy without the poke")
    _check(all(not t["heavy"] and t["weight"] >= 8 for t in weight["poked"].values()),
           "the weight poke still refused a load")
    keys = {"as_is": key_trial(snapshot, []), "poked": key_trial(snapshot, KEY_POKE)}
    _check(keys["as_is"]["room"] == LOCKED_ROOM and keys["as_is"]["locked"], "the door was not locked")
    _check(keys["poked"]["room"] == LOCKED_TO, "the key poke did not open the door")
    start = start_trial(snapshot, out_dir)
    _check(start["poked"] == START_ROOM == start["again"], "the start-room poke did not hold")
    freeze = {"as_is": freeze_trial(snapshot, []), "poked": freeze_trial(snapshot, FREEZE_POKE)}
    _check(freeze["as_is"]["moved"] > 0 and freeze["poked"]["moved"] == 0
           and freeze["poked"]["walked"] > 0, f"the freeze poke did not freeze: {freeze}")

    log("  reference: the facts' runs...")
    trapdoor = trapdoor_trial(snapshot, out_dir)
    _check(trapdoor["reached"] and trapdoor["room"] == 1 and trapdoor["waiting"],
           "room 10's hole did not end the game")
    quit = quit_trial(snapshot)
    _check(quit["quit"] and quit["iff"] == 0, "SYMBOL SHIFT and 0, or interrupts off, failed")
    letters_picture(snapshot, out_dir)
    eidi = sorted((a, i) for a, i in instructions.items() if i in ("EI", "DI"))
    _check([a for a, _ in eidi] == [0xC00B, 0xC018, START_DI], f"EI and DI are at {eidi}")
    excerpt, same = wei3_excerpt(tape, instructions)
    symbols, _, _ = fd.symbols(tape)
    starts = sum(1 for _, _, _, value in symbols if value in entries)

    fix = linker(entries)
    sections = {}
    for name, body in (list(_bugs(numberless, lock, decoy, stale).items())
                       + list(_pokes(life, weight, keys, start, freeze).items())
                       + list(_facts(tape, excerpt, same, len(symbols), starts,
                                     _fill_codes_used(tape), trapdoor, quit, eidi).items())):
        sections[name] = fix(body)
    for name, body in sections.items():
        for line in body.splitlines():
            if line.startswith((";", "[")):
                raise RuntimeError(f"fairlight_reference: {name} has a line starting with ; or [: {line}")
    log(f"  reference: {sum(1 for n in sections if n.startswith('Bug'))} bugs, "
        f"{sum(1 for n in sections if n.startswith('Poke'))} pokes, "
        f"{sum(1 for n in sections if n.startswith('Fact'))} facts")
    return sections


if __name__ == "__main__":
    import time

    started = time.time()
    root = Path(__file__).resolve().parent.parent / "game_disassembly" / "fairlight"
    target = Path(sys.argv[1]) if len(sys.argv) > 1 else root / "html" / "fairlight"
    result = build(root / "fairlight.z80", target)
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else None
    if out:
        out.write_text("\n".join(f"[{name}]\n{body}\n" for name, body in result.items()), encoding="utf-8")
    print(f"{len(result)} sections in {time.time() - started:.0f} s")
