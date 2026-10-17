"""Cyberun's reference pages: its bugs, its pokes and facts worth knowing.

build() returns SkoolKit's own Bug, Poke and Fact sections -- [Bug:x:Title],
[Poke:x:Title], [Fact:x:Title] -- for the lead to place in cyberun.ref.

The prose is written from the code and from trials run in SkoolKit's
simulator with build_cyberun's Machine and its staging (a new life put
anywhere by the game's own restart). Every poke was tried against the same
trial without it, and the page says what each trial gave; the trials are
the functions under "The trials" below, which build() does not run (they take
a few minutes): `python scripts/cyberun_reference.py --trials` runs them
again and prints what the prose quotes, in TRIALS. The 128K trials use
SkoolKit's 128K memory with the game put in RAM banks 5, 2 and 0, paged as a
128 in 128 mode leaves a machine-code program: the 48 BASIC ROM, bank 0 at
$C000, paging unlocked.

Nothing here quotes the game: addresses, instructions, the pokes' own bytes
and prose. The tables are worked out from the snapshot at build time -- the
planets' names and colours, the missiles' ranking against the points, the
objects lying in the world, the landscape's graphics, the patched gone bits,
the spawn table's end -- and the four pictures, the ship carrying a rocket
part with and without the hook and the ore tank after a two-unit load and
after a turn, are drawn by the game's own code in SkoolKit's simulator into
the HTML directory. build() also reads the listing to check that each
instruction a poke or a bug is about is still the one the prose was written
for, and to keep #R links only where they name an entry.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

# --------------------------------------------------------------------------
# What the pokes change, and what the listing must still say there
# --------------------------------------------------------------------------

DAMAGE_SHIP = 0x8F76        # damage_ship, the second half of contact_damage
FUEL_BURN = 0xB149          # read_controls: LD DE,8, the burn for steering or thrust
LIVES_DEC = 0xF4CF          # lose_life: DEC A, a life fewer
START_ATTACKER = 0x89D3     # start_attacker's first instruction
BEAM_HITS_SHIP = 0x9D0E     # beam_hits_ship's first instruction
SHIELD_DEC = 0xC385         # ship_pass: DEC A, the shield timer down
GUN_COOLING_LD = 0xB745     # fire: LD A,6, the passes to the next shot
HOOK_TEST = 0xAAE2          # collect_pickup: RET Z, no hook
BEAM_ADDON_TEST = 0xB843    # special_beam_key: RET Z, no add-on 7
TANK_TEST = 0x9740          # drop_part: JR NZ past the ore test, not part 6
LIVES_LD = 0xF3CE           # new_game: LD A,5
# The keyboard reads whose A can have bit 7 clear (the half-rows to read):
# the menu's B ($7F), read_keyboard (0 for any key, $7E for a joystick's
# special key), the pause test ($7F) and the keyboard method's two reads of
# the bottom right half-row ($7F).
PAGING_OUTS = (0x86C8, 0x9BC3, 0x9EE5, 0xB1DF, 0xB1FB)

# Instructions the bugs and facts are about.
TARGET_INC = 0x92C7         # find_missile_target: INC A, the type plus one
TARGET_SUB = 0x92CA         # find_missile_target: SUB $14
ORE_CLEAR = 0xA8CE          # load_ore: LD (HL),0, the clearing loop
ORE_LINE_UP = 0xA8D4        # load_ore: CALL line_up_de, which moves DE
ADDON9_ROWS = 0xB091        # build_ship_sprite: add-on 9's 11 rows, after the start is set
MASK_TEST = 0xB0D7          # fit_addon: CP $FF, a mask or not
PAD_REPAIR = 0xA9B9         # ship_hits_ground_objects: LD A,$FF into the hit count
PAD_CALL = 0xA9BE           # ... CALL damage_ship
SHIELD_TEST = 0x8F7A         # damage_ship: RET NZ with the shield up
TYPE_1B_WORD = 0xAF35       # object_handlers: type $1B's word
PATCH_LD = 0xF456           # play: LD A,$7E, player 1's BIT 7,(HL)
PATCH_OR = 0xF461           # play: OR $F0, the SETs

EXPECTED_INSTRUCTIONS = {
    DAMAGE_SHIP: "LD A,($896F)", FUEL_BURN: "LD DE,$0008", LIVES_DEC: "DEC A",
    START_ATTACKER: "LD B,$06", BEAM_HITS_SHIP: "LD A,($96AB)", SHIELD_DEC: "DEC A",
    GUN_COOLING_LD: "LD A,$06", HOOK_TEST: "RET Z", BEAM_ADDON_TEST: "RET Z",
    TANK_TEST: "JR NZ,$974A", LIVES_LD: "LD A,$05",
    TARGET_INC: "INC A", TARGET_SUB: "SUB $14", ORE_CLEAR: "LD (HL),$00",
    ORE_LINE_UP: "CALL $A1B3", ADDON9_ROWS: "LD A,($C1A9)", MASK_TEST: "CP $FF",
    PAD_REPAIR: "LD A,$FF", PAD_CALL: "CALL $8F76", SHIELD_TEST: "RET NZ",
    TYPE_1B_WORD: "DEFW $AFCB", PATCH_LD: "LD A,$7E", PATCH_OR: "OR $F0",
}
for _address in PAGING_OUTS:
    EXPECTED_INSTRUCTIONS[_address] = "OUT ($FD),A"

# Opcodes the pokes write, named for what they are.
NOP, JR, RET, OR_A = 0x00, 0x18, 0xC9, 0xB7

POKES = {
    "nohits": [(DAMAGE_SHIP, RET)],
    "nofuel": [(FUEL_BURN, RET)],
    "lives": [(LIVES_DEC, OR_A)],
    "noattackers": [(START_ATTACKER, RET)],
    "beams": [(BEAM_HITS_SHIP, RET)],
    "shield": [(SHIELD_DEC, NOP)],
    "rapid": [(GUN_COOLING_LD + 1, 0)],
    "hook": [(HOOK_TEST, NOP)],
    "beamkey": [(BEAM_ADDON_TEST, NOP)],
    "emptytank": [(TANK_TEST, JR)],
    "128k": [(address + offset, NOP) for address in PAGING_OUTS for offset in (0, 1)],
}

# --------------------------------------------------------------------------
# The game's memory, as the trials and tables use it
# --------------------------------------------------------------------------

OBJECT_RECORDS = 0x9974     # nine 24-byte sky records
RECORD_SIZE = 24
SHOT_RECORDS = 0xB37A       # four shot records
SECOND_PICKUP = 0xA88D      # the second pick-up record
SHIELD_TIMER = 0x896F
SPECIAL_BEAM_ON = 0xB832
METEOR_SHOWER = 0x87F5
MISSILE_VALUES = 0x92EE
TYPE_POINTS = 0x929C
FIRST_TYPE = 0x13           # the sky types run from $13 to $1E
TYPE_COUNT = 12
PLANET_NAMES = 0x8459
PLANET_COLOURS = 0xDC97
PLANETS = 5
NAME_LENGTH = 16
LANDSCAPE_MAP = 0x61BC
MAP_COLUMNS, MAP_ROWS = 96, 28
SPAWN_MASKS = 0x855C
SPAWN_POINTS = 0x8605
OBJECT_KINDS = 0x5C94
OBJECTS_PER_COLUMN = 0x5DB6
TANK_FULL = 0x9746          # drop_part's CP $12 operand: the ore a full tank holds
FUEL_STEP = 0xB14A          # read_controls' LD DE,8 operand: the burn a pass
SHIFT_TABLES = (0xE37D, 0xE2BD, 0xE2FD, 0xE33D)     # shifts 0, 2, 4, 6
SHIFT_ENTRIES = 16

# Ground kinds, from the notes' reading of the code (world-and-objects-in-it.md).
ORE_UNITS = {8: 1, 9: 1, 0x0A: 2}     # load_ore: two units for kind $0A
REFUEL_PAD = 0x0E
MOUND = 3

# The sky types by appearance (the listing's and notes' names).
TYPE_NAMES = {
    0x13: "cloud", 0x14: "rotor craft", 0x15: "debris", 0x16: "saucer", 0x17: "eye pod",
    0x18: "pillar", 0x19: "tough attacker", 0x1A: "dome", 0x1B: "(ground objects only)",
    0x1C: "bullets, pick-ups, wreck pieces", 0x1D: "rock or comet",
    0x1E: "a rocket part falling into place",
}
# The same, as the prose lists them.
SHORT_NAMES = {
    0x13: "clouds", 0x14: "rotor craft", 0x15: "debris", 0x16: "saucers", 0x17: "eye pods",
    0x18: "pillars", 0x19: "tough attackers", 0x1A: "domes", 0x1C: "bullets",
    0x1D: "meteor-shower rocks",
}
COLOURS = ["black", "blue", "red", "magenta", "green", "cyan", "yellow", "white"]
WORDS = ["no", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]

IMAGES = "images/reference"
PICTURE_SCALE = 3

# --------------------------------------------------------------------------
# What the trials gave (see "The trials" below; --trials prints them again)
# --------------------------------------------------------------------------

TRIALS = {
    # KEYBOARD_ROUND twelve times (124 s), the tank refilled between slices:
    # the seconds into the trial of each death, and of the game over.
    "hits": {"deaths": [6.7, 23.5, 37.2, 48.5, 72.0], "over": 79.7, "poke_lives": 5},
    # The same round 24 times (247 s), the hits undone between slices: when
    # the empty tank killed, and with the poke the fuel thieves' drains.
    "fuel": {"empty": 155.4, "poke_drains": 4, "poke_highest": 0x82},
    # Deaths by an empty tank from a new game: the lives after each.
    "lives": {"none": [4, 3, 2, 1, 0], "deaths": 7, "seconds": 7.6, "nop_seconds": 13.6},
    # KEYBOARD_ROUND six times (62 s), refuelled and repaired: what started
    # in the attackers' four records, by type, and in the clouds' two.
    "attackers": {"none": {0x13: 11, 0x17: 5, 0x18: 7, 0x19: 1, 0x1A: 5, 0x1D: 9},
                  "clouds": 22, "showers": 1, "poke_clouds": 47},
    # 600 passes hovering in a beam's way at map column 44, row 8.
    "beams": {"touches": 27, "hits": 27, "poke_drawn": 465},
    # The shield's timer set to $FF as the pick-up sets it, then 1200 passes.
    "shield": {"gone": 509, "hits": 3},
    # 420 passes holding fire: the shots.
    "rapid": {"none": 60, "poke": 120},
    # Part 0 under the ship on its pad, 100 passes: the pass it was taken.
    "hook": {"poke": 2, "hook": 2},
    # Holding 1 in open sky at map column 30, row 5.
    "beamkey": {"out": 2, "cells": 8, "full": 17, "shrinking": 24},
    # Over the rocket's place with part 6 aboard and six built, 150 passes.
    "emptytank": {"let_go": 2, "frame": 8, "built": 10, "ore_rows_left_12": 7},
    # A new life inside the finished rocket, to the next planet's first pass.
    "planet": {"score": 50000},
    # The tank filled over the rocket and delivered: the one byte left, as
    # (picture row, byte in the row, its value).
    "tank_pixel": (12, 3, 0x10),
    # The game's own memory on a 128K: the paging writes without the poke.
    "128k": {"writes": [(0x00FD, 0x00), (0x7FFD, 0x7F)]},
    # The missiles: targets chosen with add-on 8, and with add-ons 4, 5 and 8,
    # 120 s each; every one the best by the type less $13.
    "missiles": {"choices": 122 + 163,
                 "chosen": [0x14, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1D],
                 "passed": [0x13, 0x15, 0x1C]},
    # Passes a second in the shield trial's 1200 passes of flying.
    "rate": 22.3,
}

# --------------------------------------------------------------------------
# The listing: entries (for #R), each instruction, and every label
# --------------------------------------------------------------------------

_ENTRY_RE = re.compile(r"^[bcgistuw]\$([0-9A-F]{4})\b")
_INSTRUCTION_RE = re.compile(r"^[ *]\$([0-9A-F]{4}) (.*?)\s*(;|$)")


def read_listing(skool: Path) -> tuple[set[int], dict[int, str], dict[int, str]]:
    """Entry addresses, each instruction by address, and each label by
    address (entry points included)."""
    entries, instructions, labels = set(), {}, {}
    label = None
    for line in skool.read_text(encoding="utf-8").splitlines():
        if line.startswith("@label="):
            label = line[7:].strip()
            continue
        match = _ENTRY_RE.match(line)
        if match:
            address = int(match.group(1), 16)
            entries.add(address)
            instructions[address] = line[len(match.group(0)):].split(";")[0].strip()
        else:
            match = _INSTRUCTION_RE.match(line)
            if match:
                address = int(match.group(1), 16)
                instructions[address] = match.group(2).strip()
        if match and label:
            labels[address] = label
        if match or not line.startswith("@"):
            label = None
    return entries, instructions, labels


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


def _word(memory, address: int) -> int:
    return memory[address] | memory[address + 1] << 8


def _table(header: list[str], rows: list[list[str]]) -> str:
    head = "".join(f"<th>{cell}</th>" for cell in header)
    body = "".join("<tr>" + "".join(f"<td>{cell}</td>" for cell in row) + "</tr>" for row in rows)
    return f'<table class="kl-table"><tr>{head}</tr>{body}</table>'


# --------------------------------------------------------------------------
# What is read from the game at build time
# --------------------------------------------------------------------------

def game_text(memory, address: int, length: int) -> str:
    """The game's character codes as text: 0-25 the letters, $1A-$23 the
    digits, $26 a space (planet_names' description)."""
    out = []
    for code in memory[address:address + length]:
        if code < 26:
            out.append(chr(ord("A") + code))
        elif code < 0x24:
            out.append(chr(ord("0") + code - 26))
        else:
            out.append(" ")
    return "".join(out).strip()


def colour_name(attribute: int) -> str:
    return ("bright " if attribute & 0x40 else "") + COLOURS[attribute & 7]


def planets(memory) -> list[tuple[str, str, str]]:
    """Each planet's name and its landscape's two colours, above the caverns
    and in them."""
    return [(game_text(memory, PLANET_NAMES + NAME_LENGTH * n, NAME_LENGTH),
             colour_name(memory[PLANET_COLOURS + 2 * n]),
             colour_name(memory[PLANET_COLOURS + 2 * n + 1])) for n in range(PLANETS)]


def bcd(memory, address: int) -> int:
    return int(f"{memory[address]:02X}{memory[address + 1]:02X}")


def missile_ranking(memory) -> list[tuple[int, int, int]]:
    """(type, missile value, points) for each sky type, the value read as the
    code reads it: by the type less $13 (INC A, then SUB $14)."""
    return [(kind, memory[MISSILE_VALUES + kind - FIRST_TYPE],
             bcd(memory, TYPE_POINTS + 2 * (kind - FIRST_TYPE)))
            for kind in range(FIRST_TYPE, FIRST_TYPE + TYPE_COUNT)]


def world_objects(memory) -> dict:
    """The objects lying in the world, from map_object_kinds and the counts
    per column."""
    total = sum(memory[OBJECTS_PER_COLUMN + column] for column in range(MAP_COLUMNS))
    kinds = [memory[OBJECT_KINDS + n] & 0x3F for n in range(total)]
    return {"total": total,
            "ore": sum(ORE_UNITS.get(kind, 0) for kind in kinds),
            "deposits": {kind: kinds.count(kind) for kind in ORE_UNITS},
            "pads": kinds.count(REFUEL_PAD), "mounds": kinds.count(MOUND)}


def map_tiles(memory) -> dict[int, list[tuple[int, int]]]:
    """Tile number -> the map cells (column, row) holding it."""
    cells: dict[int, list[tuple[int, int]]] = {}
    for row in range(1, MAP_ROWS + 1):
        for column in range(MAP_COLUMNS):
            tile = memory[LANDSCAPE_MAP + (row - 1) * MAP_COLUMNS + column]
            cells.setdefault(tile, []).append((column, row))
    return cells


def landscape_graphics(memory, entries: set[int]) -> tuple[int, int]:
    """How many graphics the shift-0 table draws its 16 directions from, and
    how many the other three shifts' tables do -- each counted as the
    listing's entries the graphic pointers fall in."""
    ordered = sorted(entries)

    def entry_of(address):
        found = ordered[0]
        for entry in ordered:
            if entry > address:
                break
            found = entry
        return found

    stored = {entry_of(_word(memory, SHIFT_TABLES[0] + 4 * n + 2)) for n in range(SHIFT_ENTRIES)}
    made = {entry_of(_word(memory, table + 4 * n + 2))
            for table in SHIFT_TABLES[1:] for n in range(SHIFT_ENTRIES)}
    return len(stored), len(made)


def count_instructions(instructions: dict[int, str], text: str) -> int:
    return sum(1 for address, instruction in instructions.items()
               if instruction == text and 0x5C80 <= address < 0xFA00)


# --------------------------------------------------------------------------
# The simulator: staging, one pass at a time, and calling a routine
# --------------------------------------------------------------------------

def _started(snapshot: Path, pokes=(), control: int = 0):
    """A Machine from the snapshot through the title tune to the menu, the
    pokes put in there (so a poke to new_game counts), and on to the first
    pass of play."""
    import build_cyberun as bc
    machine = bc.Machine(snapshot)
    machine.play([bc.At("the menu", bc.MENU_LOOP, 120.0, bc.TUNE_KEYS)], "reference")
    for address, value in pokes:
        machine.memory[address] = value
    machine.play(bc._start(control)[1:], "reference")
    return machine


def _one_pass(machine, keys=(), stop=None, executed=None) -> bool:
    """Run to the next arrival at `stop` (the play loop), holding keys; the
    addresses run are added to `executed`. False if it never came."""
    import build_cyberun as bc
    from skoolkit.simutils import PC, T
    stop = bc.PLAY_LOOP if stop is None else stop
    simulator = machine.simulator
    machine.tracer.keys = set(keys)
    machine.tracer.kempston = 0
    limit = simulator.registers[T] + 5 * bc.TSTATES_PER_SECOND
    if machine.pc == stop:
        simulator.trace(machine.pc, 0, 1, 0, True, None, executed, None, None, None)
        machine.pc = simulator.registers[PC]
    simulator.trace(machine.pc, stop, 0, limit, True, None, executed, None, None, None)
    machine.pc = simulator.registers[PC]
    return machine.pc == stop


def _call(machine, address: int, registers: dict, stop: int | None = None) -> None:
    """Run a routine of the game from the play loop, as if called there:
    the play loop's address is pushed as its return address. With `stop`,
    run only from `address` to there instead (a fragment that ends in a
    jump)."""
    import build_cyberun as bc
    from skoolkit.simutils import PC, SP, T
    simulator, memory = machine.simulator, machine.memory
    if stop is None:
        stop = bc.PLAY_LOOP
        sp = simulator.registers[SP] - 2
        memory[sp], memory[sp + 1] = stop & 0xFF, stop >> 8
        simulator.registers[SP] = sp
    for register, value in registers.items():
        simulator.registers[register] = value
    simulator.trace(address, stop, 0, simulator.registers[T] + bc.TSTATES_PER_SECOND,
                    True, None, None, None, None, None)
    if simulator.registers[PC] != stop:
        raise RuntimeError(f"cyberun_reference: ${address:04X} never reached ${stop:04X}")
    machine.pc = bc.PLAY_LOOP


def _hover(machine, row: int, view_y: int, passes: int, each=None) -> None:
    """Hold thrust whenever the view is below (row, view_y), so the ship
    hovers about the place a life started at; the tank refilled every pass.
    each(memory, executed) after every pass."""
    import build_cyberun as bc
    memory = machine.memory
    for _ in range(passes):
        memory[bc.FUEL], memory[bc.FUEL + 1] = 0, bc.FUEL_FULL >> 8
        low = (memory[0xCE58], memory[0xCE46]) > (row, view_y)
        executed = set()
        if not _one_pass(machine, ["a"] if low else [], executed=executed):
            raise RuntimeError("cyberun_reference: the play loop stopped coming round")
        if each:
            each(memory, executed)


def _ship_picture(memory) -> bytes:
    start, height = _word(memory, 0xC1AA), memory[0xC1A9]
    return bytes(memory[start:start + 6 * height])


# Places the trials and pictures stage a life at, by the game's own restart.
SKY = (30, 5, 0x08, 0x60)               # open sky, nothing near
BEAM_PLACE = (44, 8, 0x08, 0x69)        # tile $A6 below: a beam crosses the ship's line
OVER_ROCKET = (0x51, 0x09, 0xE6, 0x60)  # the sky over the rocket, the ship at x $5C after a pass


def _new_life(machine, place, pokes: dict) -> None:
    """build_cyberun's new_life_at, with longer waits: the tank is emptied,
    and the death it brings can be twelve seconds coming (the gauge drains a
    row a pass to show empty, then up to 128 passes' grace); at the end of
    the death sequence the next life's place is set by the game's own
    restart."""
    import build_cyberun as bc
    machine.play([(["a"], 0.3), bc._kill_by_fuel,
                  bc.Until("a death from empty fuel", lambda m: m[bc.DYING] != 0, 30.0),
                  bc.Until("the end of the death sequence", lambda m: m[bc.DYING] >= 0x50, 30.0),
                  bc.restart_at(*place, sky=True, pokes=pokes),
                  bc.Until("the next ship", lambda m: m[bc.DYING] == 0, 30.0)], "reference")


def _over_rocket(machine, pokes: dict) -> None:
    """A new life in the sky over the rocket's place, with the ship at x $5C,
    where drop_part lets a part go. The first pass after a restart sometimes
    moves the ship two pixels, depending on the life before, so the place is
    tried again a step over until the ship is where it should be."""
    column, row, view_x, view_y = OVER_ROCKET
    memory = machine.memory
    for _ in range(4):
        _new_life(machine, (column, row, view_x, view_y), pokes)
        for _ in range(3):
            _hover(machine, row, view_y, 1)
            if memory[0xC8E6] == 0x52 and memory[0xC8E7] == 0x5C:
                return
        view_x = (view_x + 0x5C - memory[0xC8E7]) & 0xFF
    raise RuntimeError("cyberun_reference: could not put the ship over the rocket's place")


# --------------------------------------------------------------------------
# The pictures, drawn by the game at build time
# --------------------------------------------------------------------------

def _screen_crop(memory, path: Path, column: int, row: int, width: int, height: int,
                 scale: int = PICTURE_SCALE) -> None:
    """A rectangle of character cells from the screen, as the game drew it."""
    from skoolkit.components import get_image_writer
    from skoolkit.graphics import Frame, scr_udgs
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "wb") as f:
        get_image_writer().write_image([Frame(scr_udgs(memory, column, row, width, height), scale)], f)


# The ship's part of the screen on its pad at the start: x $60 is column 12,
# its top line 98 in character row 12, and with the hook and a part it reaches
# down 40 lines; a column either side.
SHIP_WINDOW = (11, 11, 8, 7)
# The ore tank's ore columns (x $70-$7F, columns 14 and 15) with a column
# either side, and the three character rows above the ship's bottom line.
TANK_SCALE = 8


def draw_hookless(snapshot: Path, out_dir: Path) -> list[str]:
    """Rocket part 0 picked up with the hook poke and no hook, and with the
    hook: the part is put in the second pick-up record under the ship on its
    pad at the start, as load_map_window fills one."""
    import build_cyberun as bc
    names = []
    for name, pokes, hook in (("part_no_hook", POKES["hook"], 0), ("part_hook", [], 1)):
        machine = _started(snapshot, pokes)
        for _ in range(10):
            _one_pass(machine)
        memory = machine.memory
        memory[bc.ADDON_SLOTS] = hook
        if hook:
            # Fitted as collect_pickup fits an add-on, so that the picture
            # is rebuilt with it: +$1F of the ship's record is the add-on.
            memory[0xC904] = 1
            for _ in range(4):
                _one_pass(machine)
        _stage_part(memory)
        for _ in range(12):
            memory[bc.HITS] = 0
            _one_pass(machine)
        if memory[bc.PART_CARRIED] != 0:
            raise RuntimeError(f"cyberun_reference: {name}: the part was not taken")
        _screen_crop(memory, out_dir / f"{name}.png", *SHIP_WINDOW)
        names.append(name)
    return names


def _stage_part(memory) -> None:
    """Rocket part 0 in the second pick-up record, under the middle of the
    ship as it stands on its pad at the start (column $0E, x $16 is screen
    x $70 there)."""
    record = SECOND_PICKUP
    memory[record + 1], memory[record + 2] = 0x0E, 0x16
    memory[record + 4], memory[record + 5] = 7, 0x97
    memory[record + 0x13], memory[record + 0x0D], memory[record] = 0, 0xFF, 0x1E


def draw_ore(snapshot: Path, out_dir: Path) -> dict:
    """The tank with four units, then two more loaded by load_ore (as a
    kind-$0A deposit gives them), then the same after the ship has turned
    and turned back, which rubs the whole picture out and draws it again."""
    import build_cyberun as bc
    from skoolkit.simutils import A
    machine = _started(snapshot)
    _new_life(machine, SKY, {bc.PART_CARRIED: 6, bc.PARTS_BUILT: 6, bc.ORE: 4, bc.ADDON_SLOTS: 1})
    _hover(machine, SKY[1], SKY[3], 6)
    memory = machine.memory
    _call(machine, 0xA8AA, {A: 2})
    _hover(machine, SKY[1], SKY[3], 6)
    stray = _stray_ore_rows(memory)
    tank = (13, memory[0xC903] // 8 - 2, 4, 3, TANK_SCALE)
    _screen_crop(memory, out_dir / "ore_loaded.png", *tank)
    for keys in (["z"], ["x"]):
        for _ in range(3):
            _one_pass(machine, keys)
        _hover(machine, SKY[1], SKY[3], 4)
    _screen_crop(memory, out_dir / "ore_redrawn.png", *tank)
    return {"stray": stray, "after_turn": _stray_ore_rows(memory), "ore": memory[bc.ORE]}


def _stray_ore_rows(memory) -> list[int]:
    """The rows of the tank's ore columns where the screen holds more than
    the ship's picture: bytes 2 and 3 of each row, x $70-$7F."""
    bottom, start = memory[0xC903], _word(memory, 0xC1AA)
    stray = []
    for row in range(memory[0xC1A9]):
        y = bottom - row
        screen = 0x4000 | (y & 0xC0) << 5 | (y & 7) << 8 | (y & 0x38) << 2
        for column in (2, 3):
            if memory[screen + 12 + column] != memory[start + 6 * row + column]:
                stray.append(row)
                break
    return stray


# --------------------------------------------------------------------------
# The trials (not run by build(); --trials runs them and prints TRIALS)
# --------------------------------------------------------------------------

def _slices(machine, steps, every, refuel=False, repair=False, slice_seconds=0.05):
    """(keys, seconds) steps in short slices, every(memory, seconds) after
    each; the tank refilled and the hits undone between slices if asked."""
    import build_cyberun as bc
    memory, clock = machine.memory, 0.0
    for keys, seconds in steps:
        done = 0.0
        while done < seconds - 1e-9:
            if refuel:
                memory[bc.FUEL], memory[bc.FUEL + 1] = 0, bc.FUEL_FULL >> 8
            if repair and memory[bc.DYING] == 0:
                memory[bc.HITS] = 0
            machine.run(slice_seconds, keys)
            done += slice_seconds
            clock += slice_seconds
            every(memory, clock)


def trial_hits(snapshot, pokes, rounds=12):
    import build_cyberun as bc
    machine = _started(snapshot, pokes)
    state = {"hits": 0, "deaths": [], "over": None, "h": 0, "d": 0}

    def every(memory, clock):
        hits, dying = memory[bc.HITS], memory[bc.DYING]
        if hits > state["h"]:
            state["hits"] += hits - state["h"]
        if dying and not state["d"] and state["over"] is None:
            state["deaths"].append(round(clock, 1))
        if memory[bc.LIVES] == 0 and state["over"] is None:
            state["over"] = round(clock, 1)
        state["h"], state["d"] = hits, dying
    _slices(machine, bc.KEYBOARD_ROUND * rounds, every, refuel=True)
    return {"deaths": state["deaths"], "hits": state["hits"], "over": state["over"],
            "lives": machine.memory[bc.LIVES]}


def trial_fuel(snapshot, pokes, rounds=24):
    import build_cyberun as bc
    machine = _started(snapshot, pokes)
    state = {"empty": None, "highest": 0, "drains": 0, "last": None}

    def every(memory, clock):
        level = memory[bc.FUEL + 1]
        if memory[bc.DYING] == 0:
            # A fuel thief's drain is 16 steps at once; the burn is 8/256 a pass.
            if state["last"] is not None and level >= state["last"] + 16:
                state["drains"] += 1
            state["highest"] = max(state["highest"], level)
            state["last"] = level
        elif state["empty"] is None:
            state["empty"] = round(clock, 1)
    _slices(machine, bc.KEYBOARD_ROUND * rounds, every, repair=True)
    return state


def trial_lives(snapshot, pokes, deaths=7):
    import build_cyberun as bc
    machine = _started(snapshot, pokes)
    out = []
    for _ in range(deaths):
        machine.executed = set()
        machine.play([(["a"], 0.3), bc._kill_by_fuel,
                      # The gauge drains a row a pass to show empty, then up
                      # to 128 passes' grace: as much as twelve seconds.
                      bc.Until("a death", lambda m: m[bc.DYING] != 0, 30.0)], "reference")
        waited = 0.0
        while waited < 60 and machine.memory[bc.DYING]:
            machine.run(0.1, [])
            waited += 0.1
        menu = 0xF26C in machine.executed     # menu: the game is over
        out.append((machine.memory[bc.LIVES], 0xF4FC in machine.executed, round(waited, 1)))
        if menu:
            break
    machine.executed = None
    return out


def trial_attackers(snapshot, pokes, rounds=6):
    import build_cyberun as bc
    machine = _started(snapshot, pokes)
    last = [0xFF] * 9
    state = {"attackers": {}, "thrown": 0, "clouds": 0, "showers": 0, "shower": 0}

    def every(memory, clock):
        for record in range(9):
            kind = memory[OBJECT_RECORDS + RECORD_SIZE * record]
            if last[record] == 0xFF and kind != 0xFF:
                if record < 4:
                    state["attackers"][kind] = state["attackers"].get(kind, 0) + 1
                elif record < 7:
                    state["thrown"] += 1
                else:
                    state["clouds"] += 1
            last[record] = kind
        if memory[METEOR_SHOWER] and not state["shower"]:
            state["showers"] += 1
        state["shower"] = memory[METEOR_SHOWER]
    _slices(machine, bc.KEYBOARD_ROUND * rounds, every, refuel=True, repair=True,
            slice_seconds=0.02)
    return state


def trial_beams(snapshot, pokes, passes=600):
    import build_cyberun as bc
    machine = _started(snapshot, POKES["noattackers"] + list(pokes))
    _new_life(machine, BEAM_PLACE, {})
    _one_pass(machine)
    state = {"touches": 0, "hits": 0, "drawn": 0}

    def each(memory, executed):
        state["touches"] += 0x9D1D in executed     # beam_hits_ship found a touch
        state["drawn"] += 0x9D30 in executed       # draw_flicker_beam ran
        state["hits"] += memory[bc.HITS]
        memory[bc.HITS] = 0
    _hover(machine, BEAM_PLACE[1], BEAM_PLACE[3], passes, each)
    return state


def trial_shield(snapshot, pokes, passes=1200):
    import build_cyberun as bc
    from skoolkit.simutils import T
    machine = _started(snapshot, pokes)
    _one_pass(machine)
    memory = machine.memory
    memory[SHIELD_TIMER] = 0xFF
    state = {"gone": None, "hits": 0, "died": None}
    start = machine.simulator.registers[T]
    for n in range(passes):
        memory[bc.FUEL], memory[bc.FUEL + 1] = 0, bc.FUEL_FULL >> 8
        before = memory[bc.HITS]
        keys = bc.KEYBOARD_ROUND[(n // 20) % len(bc.KEYBOARD_ROUND)][0]
        if not _one_pass(machine, keys):
            state["died"] = n
            break
        state["hits"] += memory[bc.HITS] > before
        if memory[SHIELD_TIMER] == 0 and state["gone"] is None:
            state["gone"] = n + 1
    seconds = (machine.simulator.registers[T] - start) / bc.TSTATES_PER_SECOND
    state["left"] = memory[SHIELD_TIMER]
    state["rate"] = round(passes / seconds, 1) if state["died"] is None else None
    return state


def trial_rapid(snapshot, pokes, passes=420):
    import build_cyberun as bc
    machine = _started(snapshot, pokes)
    _one_pass(machine)
    shots = 0
    for _ in range(passes):
        machine.memory[bc.FUEL], machine.memory[bc.FUEL + 1] = 0, bc.FUEL_FULL >> 8
        machine.memory[bc.HITS] = 0
        executed = set()
        _one_pass(machine, ["q"], executed=executed)
        shots += 0xB76B in executed                # fire cleared a record for a shot
    return shots


def trial_hook(snapshot, pokes, hook=0, passes=100):
    import build_cyberun as bc
    machine = _started(snapshot, pokes)
    for _ in range(10):
        _one_pass(machine)
    memory = machine.memory
    memory[bc.ADDON_SLOTS] = hook
    _stage_part(memory)
    taken = None
    for n in range(passes):
        memory[bc.HITS] = 0
        _one_pass(machine)
        if memory[bc.PART_CARRIED] != 0xFF and taken is None:
            taken = n + 1
    return taken


def trial_hookless_delivery(snapshot):
    """Rocket part 0 carried with no hook, delivered from a new life over the
    rocket's place: is anything left in the ship's picture?"""
    import build_cyberun as bc
    machine = _started(snapshot)
    _over_rocket(machine, {bc.PART_CARRIED: 0, bc.PARTS_BUILT: 0, bc.ADDON_SLOTS: 0})
    _hover(machine, OVER_ROCKET[1], OVER_ROCKET[3], 10)
    memory = machine.memory
    return {"delivered": memory[bc.PART_CARRIED] == 0xFF,
            "blank": not any(_ship_picture(memory)), "height": memory[0xC1A9]}


def trial_beamkey(snapshot, pokes, addon=False, passes=40):
    """Holding 1 in open sky: the pass the beam came out, its longest, and
    each pass's (beam on, cells, age) to compare one trial with another."""
    import build_cyberun as bc
    machine = _started(snapshot, pokes)
    if addon:
        machine.memory[bc.ADDON_SLOTS + 6] = 7
    _new_life(machine, SKY, {})
    memory, history = machine.memory, []
    for _ in range(passes):
        memory[bc.HITS] = 0
        _one_pass(machine, ["1"])
        history.append((memory[SPECIAL_BEAM_ON], memory[SHOT_RECORDS + 0x0E],
                        memory[SHOT_RECORDS + 0x11]))
    out = next((n + 1 for n, (on, _, _) in enumerate(history) if on), None)
    cells = [c for _, c, _ in history]
    longest = max(cells)
    first_full = cells.index(longest) if longest else None
    shrinking = next((n + 1 for n in range(len(cells) - 1) if cells[n + 1] < cells[n]), None)
    return {"out": out, "cells": longest, "full": first_full and first_full + 1,
            "shrinking": shrinking, "history": tuple(history)}


def trial_emptytank(snapshot, pokes, ore=0, passes=150):
    import build_cyberun as bc
    machine = _started(snapshot, pokes)
    _new_life(machine, OVER_ROCKET, {bc.PART_CARRIED: 6, bc.PARTS_BUILT: 6, bc.ORE: ore,
                                     bc.ADDON_SLOTS: 1})
    memory = machine.memory
    state = {"let_go": None, "built": None, "frame": None, "x": set()}
    for n in range(passes):
        memory[bc.HITS] = 0
        memory[bc.FUEL], memory[bc.FUEL + 1] = 0, bc.FUEL_FULL >> 8
        _one_pass(machine)
        if n:
            state["x"].add(memory[0xC8E7])
        if state["let_go"] is None and memory[bc.PART_CARRIED] == 0xFF:
            state["let_go"] = n + 1
            for record in range(9):
                address = OBJECT_RECORDS + RECORD_SIZE * record
                if memory[address] == 0x1E:
                    state["frame"] = memory[address + 0x13]
        if state["built"] is None and memory[bc.PARTS_BUILT] == 7:
            state["built"] = n + 1
    state["x"] = sorted(state["x"])
    # Rows of the picture below the bare ship whose middle two bytes, where
    # the ore is drawn, still hold something: the hooks are in the outer ones.
    picture = _ship_picture(memory)
    state["ore_rows_left"] = sum(1 for row in range(len(picture) // 6 - 14)
                                 if picture[6 * row + 2] or picture[6 * row + 3])
    return state


def trial_startlives(snapshot, n):
    import build_cyberun as bc
    pokes = [] if n is None else [(LIVES_LD + 1, n)]
    return _started(snapshot, pokes).memory[bc.LIVES]


def trial_planet(snapshot):
    """A new life inside the finished rocket (build_cyberun's ROCKET_VIEW,
    eight parts built): the docking, the launch, the planet secured, and
    the next planet's first pass."""
    import build_cyberun as bc
    machine = _started(snapshot)
    memory = machine.memory
    before = {"level": memory[0xF5F9], "colours": (memory[0xDC95], memory[0xDC96])}
    machine.play(bc.new_life_at(bc.restart_at(*bc.ROCKET_VIEW, sky=True,
                                              pokes={bc.PARTS_BUILT: 8, bc.ADDON_SLOTS: 1})),
                 "reference")
    landscape = bytes(memory[LANDSCAPE_MAP:LANDSCAPE_MAP + MAP_COLUMNS * MAP_ROWS])
    machine.executed = set()
    machine.play([bc.Until("the next planet", lambda m: m[0xF5F9] != before["level"], 120.0),
                  bc.At("the next planet's play", bc.PLAY_LOOP, 60.0)], "reference")
    secured = 0x83D6 in machine.executed
    machine.executed = None
    return {"before": before, "secured": secured, "level": memory[0xF5F9],
            "colours": (memory[0xDC95], memory[0xDC96]), "parts": memory[bc.PARTS_BUILT],
            "carried": memory[bc.PART_CARRIED],
            "score": int("".join(f"{memory[0xF5E7 + n]:02X}" for n in (2, 1, 0))),
            "same_map": bytes(memory[LANDSCAPE_MAP:LANDSCAPE_MAP + MAP_COLUMNS * MAP_ROWS])
            == landscape}


def trial_tank_pixel(snapshot):
    """The empty ore tank hung under the ship in the sky over the rocket's
    place, filled there by nine calls of load_ore with two units each (as
    kind-$0A deposits fill it), which lets drop_part deliver it; the ship's
    picture then, against the picture of a ship with only the hook.
    (picture row, byte, the byte, the hooked ship's byte) where they differ."""
    import build_cyberun as bc
    from skoolkit.simutils import A
    machine = _started(snapshot)
    _new_life(machine, SKY, {bc.ADDON_SLOTS: 1})
    _hover(machine, SKY[1], SKY[3], 4)
    hooked = _ship_picture(machine.memory)
    machine = _started(snapshot)
    _over_rocket(machine, {bc.ADDON_SLOTS: 1, bc.PART_CARRIED: 6, bc.PARTS_BUILT: 6, bc.ORE: 0})
    memory = machine.memory
    for _ in range(9):
        _call(machine, 0xA8AA, {A: 2})
        _hover(machine, OVER_ROCKET[1], OVER_ROCKET[3], 2)
    _hover(machine, OVER_ROCKET[1], OVER_ROCKET[3], 10)
    after = _ship_picture(memory)
    differences = [(n // 6, n % 6, after[n], hooked[n]) for n in range(min(len(after), len(hooked)))
                   if after[n] != hooked[n]]
    return {"delivered": memory[bc.PARTS_BUILT] == 7, "differences": differences}


def trial_pad_shield(snapshot, shield):
    """From a pass of play with two hits taken: the refuel pad's repair
    (ship_hits_ground_objects from $A9B9, which calls damage_ship), then a
    hit (damage_ship) with the shield gone. The hit count and the icon's
    colour after each."""
    import build_cyberun as bc
    machine = _started(snapshot)
    _one_pass(machine)
    memory = machine.memory
    memory[bc.HITS], memory[SHIELD_TIMER] = 2, 0xFF if shield else 0
    _call(machine, PAD_REPAIR, {}, stop=PAD_CALL + 3)
    after_pad = (memory[bc.HITS], memory[0x8FC1])
    memory[SHIELD_TIMER] = 0
    _call(machine, DAMAGE_SHIP, {})
    return {"pad": after_pad, "hit": (memory[bc.HITS], memory[0x8FC1])}


def trial_addon9(snapshot):
    """Add-on 9 alone: the picture as the game builds it, the six spare bytes
    after the buffer, and whether the picture changes with the 24 bytes of
    the next graphics that its mask runs into set to $FF (no masking), or
    with no mask at all."""
    import build_cyberun as bc

    def built(patch):
        machine = _started(snapshot)
        for address, value in patch:
            machine.memory[address] = value
        _new_life(machine, SKY, {bc.ADDON_SLOTS + 8: 9})
        _hover(machine, SKY[1], SKY[3], 6)
        memory = machine.memory
        return _ship_picture(memory), bytes(memory[0xF7E5:0xF7EB]), memory[0xC1A9], _word(memory, 0xC1AA)

    game = built([])
    own_mask = built([(address, 0xFF) for address in range(0x75D7, 0x75EF)])
    no_mask = built([(0x75D1, 0xFF)])
    return {"height": game[2], "start": game[3], "spare": game[1].hex(),
            "same_with_own_mask": game[0] == own_mask[0], "same_with_no_mask": game[0] == no_mask[0]}


def trial_missiles(snapshot, addons, seconds=120):
    """Every target find_missile_target picks, against the best by the type
    less $13 among what it could pick from (records 0-6 drawn)."""
    import build_cyberun as bc
    from skoolkit.simutils import IXh, IXl, PC, T
    machine = _started(snapshot)
    _new_life(machine, (0x0D, 7, 0x90, 0xB7), {bc.ADDON_SLOTS + a - 1: a for a in addons})
    memory, simulator = machine.memory, machine.simulator
    values = [memory[MISSILE_VALUES + n] for n in range(TYPE_COUNT)]
    state = {"choices": {}, "best": 0, "other": 0, "passed": {}}

    def value(kind):
        index = (kind - FIRST_TYPE) & 0xFF
        return values[index] if index < TYPE_COUNT else 0

    def at_return():
        missile = simulator.registers[IXh] << 8 | simulator.registers[IXl]
        target = memory[missile + 0x17] >> 4
        if target == 0x0F:
            return
        candidates = [memory[OBJECT_RECORDS + RECORD_SIZE * r] for r in range(7)
                      if memory[OBJECT_RECORDS + RECORD_SIZE * r] != 0xFF
                      and memory[OBJECT_RECORDS + RECORD_SIZE * r + 0x10] & 0x80]
        kind = memory[OBJECT_RECORDS + RECORD_SIZE * target]
        state["choices"][kind] = state["choices"].get(kind, 0) + 1
        for candidate in set(candidates) - {kind}:
            state["passed"][candidate] = state["passed"].get(candidate, 0) + 1
        if value(kind) == max(value(c) for c in candidates):
            state["best"] += 1
        else:
            state["other"] += 1

    # Steering one way and then the other for three seconds at a time,
    # firing all the while, and thrusting whenever the view has sunk below
    # where the life started, so that the ship stays among the attackers
    # rather than falling into the caverns.
    stop = 0x92ED                                  # find_missile_target's RET
    home = (memory[0xCE58], memory[0xCE46])
    clock, slice_seconds = 0.0, 0.1
    while clock < seconds:
        memory[bc.HITS] = 0
        memory[bc.FUEL], memory[bc.FUEL + 1] = 0, bc.FUEL_FULL >> 8
        keys = ["x" if int(clock / 3) % 2 == 0 else "z", "q"]
        if (memory[0xCE58], memory[0xCE46]) > home:
            keys.append("a")
        machine.tracer.keys = set(keys)
        end = simulator.registers[T] + int(slice_seconds * bc.TSTATES_PER_SECOND)
        while simulator.registers[T] < end:
            if machine.pc == stop:
                at_return()
                simulator.trace(machine.pc, 0, 1, 0, True, None, None, None, None, None)
                machine.pc = simulator.registers[PC]
            simulator.trace(machine.pc, stop, 0, end, True, None, None, None, None, None)
            machine.pc = simulator.registers[PC]
        clock += slice_seconds
    return state


class Machine128:
    """The game on SkoolKit's 128K memory: banks 5, 2 and 0 from the
    snapshot, the 48 BASIC ROM and bank 0 paged in, paging unlocked ($10).
    Every write to a port SkoolKit takes for $7FFD is logged."""

    def __init__(self, snapshot: Path, pokes=()):
        import build_cyberun as bc
        from skoolkit import CSimulator
        from skoolkit.pagingtracer import Memory
        from skoolkit.simulator import Simulator
        ram = list(bc.game_memory(snapshot))
        for address, value in pokes:
            ram[address] = value
        banks = [bytearray(0x4000) for _ in range(8)]
        for bank, start in ((5, 0x4000), (2, 0x8000), (0, 0xC000)):
            banks[bank][:] = bytes(ram[start:start + 0x4000])
        memory = Memory(banks, 0x10)
        memory.convert()
        self.simulator = (CSimulator or Simulator)(
            memory, {"SP": 0xFE00}, {"iff": 0, "im": 1, "tstates": 0},
            {"frame_duration": 70908, "int_active": 36})
        self.tracer = bc._key_tracer_class()(self.simulator)
        self.tracer.out7ffd = 0x10
        self.writes = []
        paging = self.tracer.write_port

        def write_port(registers, port, value, offset=0):
            if port & 0x8002 == 0:
                self.writes.append((port, value))
            return paging(registers, port, value, offset)
        self.tracer.write_port = write_port
        self.simulator.set_tracer(self.tracer)
        self.pc = bc.ENTRY

    def run_to(self, address: int, seconds: float, keys=()) -> bool:
        import build_cyberun as bc
        from skoolkit.simutils import PC, T
        self.tracer.keys = set(keys)
        self.simulator.trace(self.pc, address, 0,
                             self.simulator.registers[T] + int(seconds * bc.TSTATES_PER_SECOND),
                             True, None, None, None, None, None)
        self.pc = self.simulator.registers[PC]
        self.tracer.keys = set()
        return self.pc == address

    def run(self, seconds: float, keys=()) -> None:
        self.run_to(0x10000, seconds, keys)


def trial_128k(snapshot, pokes):
    import build_cyberun as bc
    machine = Machine128(snapshot, pokes)
    state = {"menu": machine.run_to(bc.MENU_LOOP, 30.0, bc.TUNE_KEYS)}
    machine.run(2.0)
    machine.run(0.3, ["0"])
    state["play"] = machine.run_to(bc.PLAY_LOOP, 30.0)
    if state["play"]:
        for keys, seconds in bc.KEYBOARD_ROUND:
            machine.run(seconds, keys)
        state["play"] = machine.run_to(bc.PLAY_LOOP, 5.0)
    state["pc"] = machine.pc
    state["paging"] = machine.tracer.out7ffd
    state["writes"] = machine.writes[:4]
    state["count"] = len(machine.writes)
    return state


def trial_48k_keys(snapshot, pokes):
    """On a 48K: does steering, thrust, fire and the pause still work?"""
    import build_cyberun as bc
    machine = _started(snapshot, pokes)
    memory, out = machine.memory, {}
    view = (memory[0xCE57], memory[0xCE45])
    machine.run(1.0, ["x"])
    out["steers"] = (memory[0xCE57], memory[0xCE45]) != view
    height = (memory[0xCE58], memory[0xCE46])
    machine.run(1.0, ["a"])
    out["climbs"] = (memory[0xCE58], memory[0xCE46]) < height
    machine.executed = set()
    machine.run(0.5, ["q"])
    out["fires"] = 0xB76B in machine.executed
    machine.run(0.3, ["SPACE"])
    machine.executed = set()
    machine.run(1.0, [])
    out["pauses"] = bc.PLAY_LOOP not in machine.executed
    machine.run(0.3, ["SPACE"])
    machine.run(0.5, [])
    machine.executed = set()
    machine.run(0.5, [])
    out["goes_on"] = bc.PLAY_LOOP in machine.executed
    machine.executed = None
    return out


def run_trials(snapshot: Path) -> dict:
    """Every trial the prose quotes, each with and without its poke,
    printed as each finishes."""
    trials = {
        "hits": lambda: {"none": trial_hits(snapshot, []),
                         "poke": trial_hits(snapshot, POKES["nohits"])},
        "fuel": lambda: {"none": trial_fuel(snapshot, []),
                         "poke": trial_fuel(snapshot, POKES["nofuel"])},
        "lives": lambda: {"none": trial_lives(snapshot, []),
                          "nop": trial_lives(snapshot, [(LIVES_DEC, NOP)]),
                          "poke": trial_lives(snapshot, POKES["lives"])},
        "attackers": lambda: {"none": trial_attackers(snapshot, []),
                              "poke": trial_attackers(snapshot, POKES["noattackers"])},
        "beams": lambda: {"none": trial_beams(snapshot, []),
                          "poke": trial_beams(snapshot, POKES["beams"])},
        "shield": lambda: {"none": trial_shield(snapshot, []),
                           "poke": trial_shield(snapshot, POKES["shield"])},
        "rapid": lambda: {"none": trial_rapid(snapshot, []),
                          "poke": trial_rapid(snapshot, POKES["rapid"])},
        "hook": lambda: {"none": trial_hook(snapshot, []),
                         "poke": trial_hook(snapshot, POKES["hook"]),
                         "hook": trial_hook(snapshot, [], hook=1),
                         "delivered": trial_hookless_delivery(snapshot)},
        "beamkey": lambda: {"none": trial_beamkey(snapshot, []),
                            "poke": trial_beamkey(snapshot, POKES["beamkey"]),
                            "addon": trial_beamkey(snapshot, [], addon=True)},
        "emptytank": lambda: {"none": trial_emptytank(snapshot, []),
                              "poke": trial_emptytank(snapshot, POKES["emptytank"]),
                              "full": trial_emptytank(snapshot, [], ore=18),
                              "poke12": trial_emptytank(snapshot, POKES["emptytank"], ore=12)},
        "startlives": lambda: {n: trial_startlives(snapshot, n) for n in (None, 9, 1)},
        "planet": lambda: trial_planet(snapshot),
        "tank_pixel": lambda: trial_tank_pixel(snapshot),
        "pad_shield": lambda: {"none": trial_pad_shield(snapshot, False),
                               "shield": trial_pad_shield(snapshot, True)},
        "addon9": lambda: trial_addon9(snapshot),
        "128k": lambda: {"none": trial_128k(snapshot, []),
                         "poke": trial_128k(snapshot, POKES["128k"]),
                         "48k": trial_48k_keys(snapshot, []),
                         "48k_poke": trial_48k_keys(snapshot, POKES["128k"])},
        "missiles": lambda: {"8": trial_missiles(snapshot, [8]),
                             "458": trial_missiles(snapshot, [4, 5, 8])},
    }
    results = {}
    for name, trial in trials.items():
        results[name] = trial()
        print(f"{name}: {results[name]}", flush=True)
    return results


# --------------------------------------------------------------------------
# The pokes
# --------------------------------------------------------------------------

def _poke_line(*writes) -> str:
    return ": ".join(f"POKE {address},{value}" for address, value in writes)


def _and(words: list[str]) -> str:
    return ", ".join(words[:-1]) + " and " + words[-1] if len(words) > 1 else "".join(words)


def _count(n: int, word: str) -> str:
    return f"{WORDS[n] if n < len(WORDS) else n} {word}{'' if n == 1 else 's'}"


def _seconds(values) -> str:
    text = [f"{value:g}" for value in values]
    return ", ".join(text[:-1]) + " and " + text[-1]


def _pokes(key_reads: int) -> dict[str, str]:
    t = TRIALS
    started = t["attackers"]["none"]
    lives = ", ".join(str(n) for n in t["lives"]["none"])
    beam = t["beamkey"]
    return {
        "Poke:nohits:No damage": f"""\
Every hit -- an attacker, a bullet, a rock, a flickering beam -- goes through
damage_ship, the second half of #R$8F54(contact_damage), at ${DAMAGE_SHIP:04X}:
it counts the hit in #R$8FC3(hit_count) and kills on the third. A RET as its
first instruction and nothing is counted. A refuel pad repairs through the
same routine (see the facts), so with the poke a pad leaves the count at $FF
instead of nought; nothing else counts it up, so that does no harm.
Tested: from the first pass of a new game, build_cyberun's round of keys
(thrust, steering both ways, fire) twelve times over, 124 seconds of play,
with the tank refilled between slices so that only hits could kill. Without
the poke the ship died on its third hit five times, {_seconds(t["hits"]["deaths"])}
seconds in, and the game was over at {t["hits"]["over"]:g} seconds; with it, no hit
was counted and the five lives were still there at the end.

{_poke_line(*POKES["nohits"])}""",

        "Poke:nofuel:No fuel burned": f"""\
#R$B115(read_controls) burns fuel on every pass the ship steers or thrusts: 8
(16 for both at once, halved with add-on 6) added to #R$CC4B(fuel) through
#R$CC4D(add_fuel), from ${FUEL_BURN:04X}. A RET there and the burn never
happens. The pick-ups and pads still work: a refuel pick-up or pad fills the
tank, and a fuel thief still takes its 16 steps.
Tested: the same round of keys 24 times, 247 seconds, with the hits undone
between slices so that only the fuel could kill. Without the poke the tank ran
dry and the ship died {t["fuel"]["empty"]:g} seconds in; with it, no death, and the
gauge moved only for {WORDS[t["fuel"]["poke_drains"]]} fuel thieves' drains, to
${t["fuel"]["poke_highest"]:02X} at most (it reads $42 full, $BE empty).

{_poke_line(*POKES["nofuel"])}""",

        "Poke:lives:Infinite lives": f"""\
#R$F4C6(lose_life) takes a life with the DEC A at ${LIVES_DEC:04X}, stores it,
and goes to #R$F4FC(game_over) on a zero. The obvious poke, a NOP for the DEC
(POKE {LIVES_DEC},0), keeps the lives but not the game: the JR Z then tests the
flags the caller left, and the death sequence's last call,
#R$9F2C(clear_play_area), ends on a DEC C that reaches nought -- so every death
shows GAME OVER, plays its tune and checks the high score before play goes on
(game_over returns, and the lives are not nought). OR A in place of the DEC
leaves the lives as they are and sets the flags from them, never nought.
Tested: {WORDS[t["lives"]["deaths"]]} deaths in a row by emptying the tank, from a new
game. Without a poke the lives went {lives}, and the fifth death was the game
over. With OR A, five lives after each of the seven and #R$F4FC never ran, a
death taking {t["lives"]["seconds"]:g} seconds to the next ship. With the NOP, five
lives too, but #R$F4FC ran at every death and each took
{t["lives"]["nop_seconds"]:g} seconds.

{_poke_line(*POKES["lives"])}""",

        "Poke:noattackers:No attackers, no meteor showers": f"""\
#R$87E7(spawn_attacker) finds a free record among the first four and calls
#R$89D3(start_attacker), which takes the next kind from the wave table -- or,
during a meteor shower, a rock or a comet -- and places it. A RET as its first
instruction and the record is left free. Clouds still come, through
#R$8792(spawn_cloud), which goes straight to the placing code, and the ground
objects still throw their bullets and pick-ups (read).
Tested: the round of keys six times, 62 seconds, refuelled and repaired.
Without the poke {sum(started.values())} things started in the attackers' four records:
{started[0x18]} pillars, {started[0x17]} eye pods, {started[0x1A]} domes, {WORDS[started[0x19]]} tough
attacker, {started[0x13]} clouds, and {started[0x1D]} rocks and comets of a meteor shower.
With it, none; a meteor shower began and brought nothing, and
{t["attackers"]["poke_clouds"]} clouds came in the clouds' own two records.

{_poke_line(*POKES["noattackers"])}""",

        "Poke:beams:Harmless beams": f"""\
A flickering beam that touches the ship's box damages it through
#R$9D0E(beam_hits_ship). A RET as its first instruction and the beams are only
lines. (The no-damage poke makes them harmless too, since they hurt through
damage_ship; this one leaves every other kind of hit as it was.)
Tested with the attackers stopped in both trials (the poke above), the ship
hovering for 600 passes where a beam crosses its line -- a new life by the
game's own restart at map column 44, row 8, with tile $A6 below -- and the hits
undone each pass: without the poke the beam touched the ship
{t["beams"]["touches"]} times, each a hit; with it, the beams were drawn on
{t["beams"]["poke_drawn"]} of the 600 passes and no hit was counted.

{_poke_line(*POKES["beams"])}""",

        "Poke:shield:A shield that lasts": f"""\
The shield ball sets #R$896F(shield_timer) to $FF, and #R$C374(ship_pass)
counts it down on odd passes with the DEC A at ${SHIELD_DEC:04X}; while it is
not nought no hit counts, and an attacker that touches the ship is destroyed.
A NOP for the DEC and a shield once picked up lasts the rest of the life (each
new life clears it).
Tested: the timer set to $FF as the pick-up sets it, at the end of a pass,
then 1200 passes of the round of keys with the tank refilled. Without the
poke it ran out after {t["shield"]["gone"]} passes, and three hits and a death
followed; with it, it was still $FF after 1200 passes, and no hit counted.

{_poke_line(*POKES["shield"])}""",

        "Poke:rapid:No gun cooling": f"""\
#R$B731(fire) sets #R$5C39(gun_cooling) to 6 with each shot and counts it down
a pass at a time before the next. Make the 6 a nought and the gun fires on
every pass that fire is held and one of the four shot records is free.
Tested: 420 passes holding fire from the start of a game:
{t["rapid"]["none"]} shots without the poke, one every seven passes;
{t["rapid"]["poke"]} with it, as many as four records allow.

{_poke_line(*POKES["rapid"])}""",

        "Poke:hook:Rocket parts without the hook": f"""\
#R$AAD7(collect_pickup) takes a rocket part only with add-on 1, the hook,
fitted: the RET Z at ${HOOK_TEST:04X}. A NOP there and the part due next is
taken without it. But the ship's picture is not ready for it:
#R$AA37(toggle_carried_part) sets the picture to start at the first row of the
buffer whenever a part hangs, which is right only for a ship as tall as the
hook makes it. Without the hook the picture drawn is the part and the empty
rows above it, and the ship vanishes, leaving the part hanging in the air;
after the part is delivered it starts 30 bytes on, still empty, until a new
life or an add-on rebuilds it (#R$AFE9).
Tested: rocket part 0 put in the second pick-up record under the middle of
the ship as it stands on its pad at the start, as #R$DF08(load_map_window)
fills one. Without the poke it lay there for 100 passes; with it, it was taken
on pass {t["hook"]["poke"]}, as it was with the hook fitted and no poke. Carried
without the hook from a new life over the rocket's place and let go there,
the part left the ship's picture blank.

<div><img src="../{IMAGES}/part_no_hook.png" alt="Rocket part 0 taken without the hook: the ship has vanished"/> <img src="../{IMAGES}/part_hook.png" alt="The same with the hook fitted"/></div>
Drawn by the game's own code in SkoolKit's simulator, from the screen, the ship
on its pad at the start: part 0 taken with the poke and no hook, and without
the poke with the hook.

{_poke_line(*POKES["hook"])}""",

        "Poke:beamkey:The special beam without add-on 7": f"""\
#R$B833(special_beam_key) launches the special beam when the special key is
pressed (the number row on the keyboard), add-on 7 is fitted and the ship is
still. A NOP for the RET Z that tests the add-on, and the beam needs only the
key and a still ship.
Tested: a new life in open sky at map column 30, row 5, by the game's own
restart, holding 1 from the first pass. Without the poke, nothing. With it,
the beam came out on pass {beam["out"]}, grew a cell every other pass to
{beam["cells"]} cells by pass {beam["full"]} and began to shrink on pass
{beam["shrinking"]} -- pass for pass what add-on 7 gives without the poke.

{_poke_line(*POKES["beamkey"])}""",

        "Poke:emptytank:Deliver the ore tank empty": f"""\
#R$9724(drop_part) lets a carried part go over the rocket's place, but part 6,
the ore tank, only with 18 ore aboard: the JR NZ at ${TANK_TEST:04X} skips the
ore test for the other parts. Make it a JR and the tank goes like any other
part. It falls with the full tank's picture (frame 8 is chosen by the part's
number, further on) and the ore aboard is emptied. Taking it off the ship's
picture XORs out the empty tank where the full one would be, so with more than
five units aboard some rows of ore stay drawn under the hook.
Tested: a new life by the game's own restart in the sky over the rocket's
place, carrying the tank with six parts built. With the tank empty and no
poke it was kept for 150 passes, the ship at x $5C throughout; with the poke
it was let go on pass {t["emptytank"]["let_go"]}, fell with frame
{t["emptytank"]["frame"]} and was counted the seventh part on pass
{t["emptytank"]["built"]} -- just as a full tank went without the poke. With 12
units aboard and the poke, {WORDS[t["emptytank"]["ore_rows_left_12"]]} rows of ore stayed in the
picture under the hook; with five, none.

{_poke_line(*POKES["emptytank"])}""",

        "Poke:startlives:Lives at a new game": f"""\
#R$F3BD(new_game) gives each player five lives with the LD A,5 at
${LIVES_LD:04X}. Poke its operand with n from 1 to 9; the panel shows one digit,
the lives less the ship in play.
Tested: the lives at the first pass of a new game were 5 without the poke,
and 9 and 1 with it set to 9 and to 1.

POKE {LIVES_LD + 1},n""",

        "Poke:128k:Play on a 128K in 128 mode": f"""\
Every keyboard read writes the half-rows it is about to read to port $FD
first, which pages memory on a 128K (see the bugs). Five of the {key_reads} reads
can be given a value with bit 7 clear -- the menu's B, the pause test, the
keyboard method's two reads of the bottom right half-row, and
#R$9BC3(read_keyboard), which the title tune calls with nought and a
joystick's special key with $7E -- and the IN after each selects the half-rows
by itself, so their five OUTs can go: two NOPs each.
Tested in SkoolKit's 128K machine, the game put in RAM as a 128 in 128 mode
leaves a machine-code program (the 48 BASIC ROM and bank 0 paged in, paging
unlocked): without the poke the game crashed on the menu's first pass (see the
bugs); with it, the menu, a new game and a round of play, with no write to the
paging port. On a 48K the poked game steered, thrust, fired and paused as
before.

{_poke_line(*POKES["128k"])}""",
    }


# --------------------------------------------------------------------------
# The bugs
# --------------------------------------------------------------------------

def _bugs(memory, tiles: dict, world: dict, ore_picture: dict) -> dict[str, str]:
    t = TRIALS
    masks = SPAWN_POINTS - SPAWN_MASKS
    last = [tile for tile in tiles if tile >= masks]
    stray_tile = min(last) if last else None
    cells = tiles.get(stray_tile, [])
    where = (f"once, at map column {cells[0][0]}, row {cells[0][1]}" if len(cells) == 1
             else f"in {len(cells)} cells")
    mask = memory[SPAWN_POINTS]
    points = [n for n in range(8) if mask & (1 << n)]
    point_text = " and ".join(f"point {n} (x ${memory[SPAWN_POINTS + 2 * n]:02X}, line "
                              f"${memory[SPAWN_POINTS + 2 * n + 1]:02X})" for n in points)
    stray = ore_picture["stray"]
    rows = " and ".join(str(row) for row in stray)
    record_bytes = 0xA8A5 - 0xA80B
    pixel_row, pixel_byte, _ = t["tank_pixel"]
    writes = " and then ".join(f"${value:02X} to port ${port:04X}" for port, value in t["128k"]["writes"])
    return {
        "Bug:128k:A stray OUT pages a 128K's memory": f"""\
Every keyboard read in the game is OUT ($FD),A and then IN A,($FE) with the
same A, the half-rows to read. OUT (n),A puts A on the top half of the address
bus, so the port is A * 256 + $FD. A 48K ignores it. A 128K takes any port
with bits 15 and 1 clear as its paging port $7FFD, so every A with bit 7 clear
is a paging write. The title tune's key test (#R$9A9A) reads with A nought,
which pages the 128's editor ROM in -- harmless, since the game never calls the
ROM. But the menu's test for B (#R$86B9) reads $7F on every pass of the menu,
and so do the pause test (#R$9EE3) on every pass of play and the keyboard
method's reads of the bottom right half-row; and a joystick's special key
reads $7E. $7F puts RAM bank 7 at $C000, where everything from $C000 up is,
shows the second screen, and locks the paging.
Watched in SkoolKit's 128K machine, the game put in RAM paged as a 128 in 128
mode leaves a machine-code program: the writes to the paging port were
{writes}. The menu came up after the first; at the second, on the menu's
first pass, the call #R$8615(menu_loop) makes next, to #R$F23B(random), ran
into bank 7, and the machine ran off into the ROM; no game started. On a 128
the game must be run in 48 mode. <a href="pokes.html#128k">The pokes</a> have
the five OUTs to remove.""",

        "Bug:ore:Two units of ore leave stray pixels on the tank": f"""\
When the special beam mines a deposit, #R$A8A5(load_ore) adds its ore to the
tank, and clears the tank's rows on the screen that are to show it before the
ship's picture is redrawn: two bytes a row at x $70, from the old level up.
But the loop moves DE up a line (#R$A1B3(line_up_de)) while it writes through
HL, so it clears the same two bytes every time. With one unit that is right.
With two -- the {world["deposits"][0x0A]} deposits of kind $0A, and the tough attacker
worn down by the beam -- the second new row is never cleared, and since the
ship is drawn over itself with OR and rubbed out only when its picture changes
(a turn), that row shows the empty tank's pixels and the ore's together.
Watched in SkoolKit's simulator: the tank staged with four units and
#R$A8A5 called as the beam's end calls it, with two. The screen held more than
the ship's picture in the tank's ore columns in picture row {rows} -- the
second new row -- until the ship turned and turned back, after which
{"it matched" if not ore_picture["after_turn"] else "it still did not"}.

<div><img src="../{IMAGES}/ore_loaded.png" alt="The tank after a two-unit load"/> <img src="../{IMAGES}/ore_redrawn.png" alt="The same after the ship has turned and turned back"/></div>
Drawn by the game's own code in SkoolKit's simulator, from the screen, four
columns of the tank from its bottom line up: just after the load, with three
pixels too many on the sixth line up, in the left half of the ore; and after
the ship has turned and turned back.""",

        "Bug:tank:A pixel stays behind when the tank is delivered": f"""\
A rocket part hangs under the hook by being XORed into the ship's picture
(#R$AA37(toggle_carried_part)), so that the same call takes it out again. The
ore tank is hung empty, frame 6; #R$A8A5 writes the ore into it a row at a
time, over the tank's middle two bytes; and when the full tank is let go,
#R$9724(drop_part) has frame 8, the full tank, XORed out. Frame 8 is not quite
the empty tank with the ore written in: in the tank's top row it lacks one
pixel that the top row of ore has, and that pixel is left in the picture, where
the top of the tank was. It stays until the picture is next built
(#R$AFE9, at a new life or an add-on fitted).
Watched in SkoolKit's simulator: the empty tank hung in the sky over the
rocket's place, filled there by nine calls of #R$A8A5 with two units each,
which let #R$9724 deliver it; the ship's picture then differed from the hooked
ship's in one byte, picture row {pixel_row}, byte {pixel_byte}, by one pixel.""",

        "Bug:padshield:A refuel pad under the shield saves the next hit": """\
A refuel pad repairs the ship by setting #R$8FC3(hit_count) to $FF and calling
damage_ship (in #R$8F54), which counts it on to nought and colours the panel's
ship icon white again. But damage_ship does nothing at all while the shield
is up, so a pad touched under the shield leaves the count at $FF: the hits
already taken are not repaired, the icon keeps its colour, and the next hit
after the shield has gone counts the $FF on to nought -- a repair instead of a
hit.
Watched in SkoolKit's simulator, running the pad's code and damage_ship
themselves from a pass of play with two hits taken: without the shield the
pad left the count at 0 and the next hit made it 1, the icon yellow; with the
shield up the pad left it at $FF and the icon as it was, and the next hit, the
shield gone, made the count 0 and the icon white.""",

        "Bug:addon9:Add-on 9 runs one row past the ship's picture": """\
The ship's picture is put together in a buffer of 300 bytes, 50 rows of six,
at #R$F6B9(ship_picture), cleared at each life. #R$AFE9(build_ship_sprite)
works out where drawing starts from the tallest add-on and then, for add-on 9,
the figure that stands on top, adds 11 rows to the height without moving the
start, so the picture's top row is row 50: the six bytes after the buffer,
#R$F7E5(spare_after_ship), into which add-on 9's top row is drawn and which
nothing clears. Harmless: nothing else uses them, they are nought on the tape,
and the same row is drawn into them every time.
Watched in SkoolKit's simulator: with add-on 9 fitted the picture was 25 rows
from the bare ship's bottom row, and the spare bytes held the figure's top row
and nothing else.

A near miss beside it: an add-on's graphic is followed by $FF or by a mask the
size of its picture (#R$B09C), and add-on 9's (#R$75B1) has neither -- six
bytes of mask, three rows' worth, and then the next graphic. #R$B0E4 takes 30
bytes, so the figure's mask runs on through the post (#R$75D8) and the next
height byte. Those 24 bytes fall on rows of the buffer above the bare ship,
which are empty, and on one row where they take away nothing the figure does
not put back: built with them set to $FF, the picture was the same (watched
in the simulator), and built with no mask at all it was not.""",

        "Bug:spawn:The spawn table stops one tile short": f"""\
An attacker starts at one of eight spawn points of a map cell near the view,
those that the cell's tile allows in #R$855C(spawn_point_masks), a byte a tile
(#R$8A28). The table has {masks} bytes, tiles $00 to ${masks - 1:02X}; the map uses
tile ${stray_tile:02X} {where}, and that cell reads its mask from the first byte of the
next table, #R$8605(spawn_points): ${mask:02X}, which allows {point_text}. Tile
$AA, which the fly-in draws in place of tile $3E, would read the second, but
nothing spawns during the fly-in. Worked out from the snapshot at build time;
whether that point suits that cell was not checked.""",

        "Bug:type1b:Type $1B's update routine is a list of graphics": """\
#R$A18D(run_sky_object_handler) runs a sky object's update by its type, from
the twelve words of #R$AF25(object_handlers) for types $13 to $1E. Type $1B's
word is #R$AFCB(type1b_graphics), the frame list of the animated ground
objects, not code: a sky record of type $1B would jump into it. None ever is:
the sky records are given types from the wave table, the shots' and the
wreck's own, and $1E for a falling rocket part, while graphic $1B is given only
to ground objects, which are updated by #R$AC60 and never through the table.
Read; latent.""",

        "Bug:records:The second pick-up record overlaps load_ore": f"""\
The six ground-object records at #R$A80B are 26 bytes each, 156 bytes, but
#R$A8A5(load_ore) starts {record_bytes} bytes on: the second pick-up record's +$18
and +$19 are load_ore's first instruction. Those two bytes are a ground
object's number in the world's table (#R$5C94), which only the first four
records are given (#R$E114(spawn_objects_from_list)), which are read only for
objects that are not pick-ups, and which #R$AC34(free_object) leaves alone.
Read; latent.""",
    }


# --------------------------------------------------------------------------
# The facts
# --------------------------------------------------------------------------

def _facts(memory, instructions: dict, entries: set[int], tiles: dict, world: dict) -> dict[str, str]:
    t = TRIALS
    planet_rows = [[str(n + 1), name, above, below]
                   for n, (name, above, below) in enumerate(planets(memory))]
    planet_table = _table(["Planet", "Name", "Above the caverns", "The caverns"], planet_rows)

    ranking = missile_ranking(memory)
    ranked = sorted(ranking, key=lambda item: (-item[1], -item[2]))
    missile_rows = []
    for kind, value, points in ranked:
        worth = f"{points}" + (" a hit" if kind == 0x19 else "") if points else "-"
        missile_rows.append([f"${kind:02X}", TYPE_NAMES[kind], str(value) if value else "never",
                             worth])
    missile_table = _table(["Type", "What", "Missile value", "Points"], missile_rows)
    chosen = _and([SHORT_NAMES[kind] for kind in t["missiles"]["chosen"]])
    passed = _and([SHORT_NAMES[kind] for kind in t["missiles"]["passed"]])

    lives_rows = [[str(lives), f"one in {4 * lives}"] for lives in range(1, 10)]
    lives_table = _table(["Lives", "Bullet throws that are an extra life"], lives_rows)

    deposits = world["deposits"]
    stored, made = landscape_graphics(memory, entries)
    player1, player2, sets = memory[PATCH_LD + 1], memory[0xF45D], memory[PATCH_OR + 1]
    patch_rows = [["$E118", "#R$E114(spawn_objects_from_list)", "is it gone?",
                   f"BIT 7,(HL), ${player1:02X}", f"BIT 6,(HL), ${player2:02X}"],
                  ["$A9B8", "#R$A8F4(ship_hits_ground_objects)", "a refuel pad used up",
                   f"SET 7,(HL), ${player1 | sets:02X}", f"SET 6,(HL), ${player2 | sets:02X}"],
                  ["$ABDE", "#R$ABA8(beam_hits_ground_object)", "destroyed by the special beam",
                   f"SET 7,(HL), ${player1 | sets:02X}", f"SET 6,(HL), ${player2 | sets:02X}"]]
    patch_table = _table(["Byte", "In", "For", "Player 1", "Player 2"], patch_rows)

    names = [name for name, _, _ in planets(memory)]
    full_tank = memory[TANK_FULL]
    burn = memory[FUEL_STEP]
    steps = (bc_fuel_empty() - bc_fuel_full()) >> 8
    tank_passes = steps * 256 // burn
    outs = count_instructions(instructions, "OUT ($FD),A")
    eis = count_instructions(instructions, "EI")
    halts = count_instructions(instructions, "HALT")
    dis = count_instructions(instructions, "DI")
    beams = len(tiles.get(0xA6, []))
    rate = t["rate"]
    return {
        "Fact:planets:Every planet is the same map": f"""\
When the rocket has risen, #R$F52A(level_done) and #R$83D6(planet_secured)
take the player on to the next of five planets, and the map does not change:
the planet's number, in the player's record, is read only for the planet's
name and for its landscape's two colours, which #R$DCA1(start_landscape)
takes from #R$DC97(planet_ground_colours). The map, the objects in it and the
places the parts are dealt from are the same; the objects the player took or
destroyed come back; rocket parts 0-5 stand built, the empty ore tank hangs
under the ship and the nose cone is dealt a new place. After the fifth the
first comes round again. Read from the snapshot at build time:

{planet_table}
Watched in SkoolKit's simulator: a new life by the game's own restart inside
the finished rocket docked, the rocket rose, {t["planet"]["score"]:,} points were added
and the next life began on {names[1]}, in its colours, with six parts built,
the tank aboard and the map's bytes unchanged.""",

        "Fact:lives:Extra lives come faster when losing": f"""\
The spiky mounds ({world["mounds"]} of the objects in the world) throw bullets,
now and then a shield ball, and now and then an extra life.
#R$896E(extra_life_countdown) counts the bullet throws down and, at nought,
makes that throw the extra life and starts again from the current lives times
four (#R$882B(fire_from), which throws for #R$8820):

{lives_table}
So a player down to the last ship sees a life every fourth throw, five times
as often as a player with five. #R$9020(contact_extra_life) adds it, to nine
at most. Read; no trial here met a mound throwing.""",

        "Fact:still:The ship never moves on the screen": """\
The ship stays at x $60, in the middle of the play area: steering and thrust
become this pass's scroll, 2 or 4 pixels (#R$B234, #R$DDF8), the world moves
the other way, and the ship's record moves through the world with the view.
So it can be drawn over itself with OR on every other pass and rubbed out only
when its picture changes -- a turn, an add-on, a part (#R$C3E3(draw_ship)).
Read.""",

        "Fact:scroll:The background is never cleared, so the scroll is 2 pixels": """\
Nothing clears the play area during play. The landscape is drawn again every
pass, straight onto the screen (#R$D0BD(draw_landscape)), but only its pieces:
the sky is black and the inside of the ground a checker of $55 and $AA bytes,
and both look the same after a move of 2 pixels across or 2 lines up or down,
so only the thin strips a moving edge uncovers need painting. That is why
every scroll step is 2 pixels, or 4, two at once (measured in the emulator),
and why every life starts with a fly-in that paints the play area into a
known state.""",

        "Fact:pieces:Nine graphics draw sixteen directions at four shifts": f"""\
A landscape piece runs in one of 16 directions -- flat, three slopes each way,
the same as ceilings, two walls -- and is drawn at one of four fine shifts.
The shift-0 table (#R$E37D(piece_blitters_shift0)) draws all sixteen from
{WORDS[stored]} stored graphics, and the other three shifts' tables from {WORDS[made]}
more, each holding one graphic's three shifted copies, made at start-up
(#R$F7EB(build_shifted_pieces)) -- counted from the four tables in the snapshot
at build time. A slope climbing left is the right-climbing graphic started a
row later: the graphics are stored in zig-zag rows, so that reverses each
row's bytes, and a bit-reversal table, which #R$F856(build_bit_reverse) writes
over the start-up code once it has run, reverses the bits.""",

        "Fact:players:Two players are two swapped records": f"""\
Everything that belongs to a player is in one 105-byte record, the current
player's always at #R$F5E7, the other's at #R$F650; at a change of turn
#R$F591(swap_players) swaps the two byte for byte, and the two score lines on
the panel with them, so no other code asks who is playing. The one thing the
players share is the world's table of objects (#R$5C94), a byte an object
with a gone bit for each player, and #R$F440(play) patches the one BIT and the
two SETs that use it at the start of every life (the opcode bytes read from
the snapshot at build time):

{patch_table}""",

        "Fact:repair:A refuel pad repairs through the damage routine": """\
damage_ship (in #R$8F54) counts a hit in #R$8FC3(hit_count) and colours the
panel's ship icon by the new count: yellow after one, magenta after two, black
and the death after three, and white for nought. A refuel pad
(#R$A8F4(ship_hits_ground_objects)) repairs by setting the count to $FF and
calling damage_ship, which counts it on to nought: one routine both damages
and repairs. The pad also fills the tank and is used up, for that player,
until the planet is secured. Read, and run in the simulator (see
<a href="bugs.html#padshield">the bugs</a> for what the shield does to it).""",

        "Fact:shield:The shield lasts 510 passes": f"""\
The shield ball, one bullet throw in eight, sets #R$896F(shield_timer) to $FF,
and #R$C374 counts it down on odd passes, so it lasts 510 passes -- about
{round(510 / rate)} seconds at the {rate:g} passes a second the simulator's flying ran
at. While it runs no hit counts, an attacker that touches the ship is
destroyed instead, and #R$F1BD paints the ship cyan, flashing over its last 32
counts. Measured in the simulator: set to $FF at the end of a pass, it reached
nought {t["shield"]["gone"]} passes later.""",

        "Fact:meteors:Meteor showers": f"""\
Once a pass, #R$87AF(spawn_tick) starts a meteor shower when one random byte
is $6A and two bits of another are nought -- one pass in 1024, under a minute
at the pass rate -- and #R$87F5(meteor_shower) then counts 128 passes. While
it runs and the view is above the caverns, #R$89D3 puts a rock or a comet near
the ship instead of an attacker, aimed across it from the top of the play
area; they damage the ship and die on touching it. Watched in the simulator:
{WORDS[t["attackers"]["showers"]]} shower in the 62 seconds of the attackers trial, its
{t["attackers"]["none"][0x1D]} rocks and comets among the things started.""",

        "Fact:restart:Where the next ship starts": """\
Every fourth pass #R$C33C(save_restart_point) saves the view's place in the
player's record as the next life's start -- but only at a safe place: the play
area's bottom pixel row nothing but the ground's checker, or all four
on-screen map cells empty sky or beam tiles. At the next life
#R$DCA1(start_landscape) flies the landscape in to that place. A new game
starts from #R$F3B7(start_position). The trials on these pages stage their
scenes the same way: the place is written at the end of a death sequence,
after the last save, and the game builds the rest.""",

        "Fact:out:Every key read writes to port $FD first": f"""\
Each of the game's {outs} keyboard reads -- counted in the listing at build
time -- writes the half-rows it is about to read to port $FD before reading
port $FE (#R$9BC3(read_keyboard) is one). A 48K ignores the write, and why it
is there is not known; on a 128K it pages memory, and the game crashes (see
<a href="bugs.html#128k">the bugs</a>).""",

        "Fact:interrupts:No interrupts, no frame sync": f"""\
The game runs with interrupts off from its first instruction: its code, from
#R$5C80 up, has {_count(dis, "DI")}, {_count(eis, "EI").replace("no EIs", "no EI")} and
{_count(halts, "HALT").replace("no HALTs", "no HALT")} (counted in the listing at build time), so
there is no interrupt routine and nothing waits for a frame.
A pass takes as long as its work -- the landscape, up to fifteen sprites,
sounds that are timing loops -- about two or three frames: {rate:g} passes a
second in the simulator's flying, about 20 measured in the emulator.
Everything counted in passes -- the shield, the death sequence, the fuel's
grace -- lasts longer on a busy screen.""",

        "Fact:fuel:A tank lasts about three minutes of steering": f"""\
The gauge has {steps} steps from full to empty, and #R$B115(read_controls)
burns {burn}/256 of a step on each pass the ship steers or thrusts (twice that
for both at once, half with add-on 6); coasting and falling cost nothing. So
a full tank is {tank_passes:,} passes of steering, about
{round(tank_passes / rate / 60, 1):g} minutes at {rate:g} passes a second, and an empty
gauge kills after up to 128 passes' grace (#R$CC63). Measured in the
simulator: the round of keys, which steers or thrusts nearly all the time,
emptied the tank and killed the ship {t["fuel"]["empty"]:g} seconds in.""",

        "Fact:world:What lies in the world": f"""\
{world["total"]} objects lie at fixed places in the world, in tables sorted by map
column (#R$5C94). Counted from them at build time: {world["pads"]} refuel pads;
{sum(deposits.values())} ore deposits -- {deposits[8]} and {deposits[9]} of the two kinds that give
one unit, {deposits[0x0A]} of the kind that gives two -- {world["ore"]} units in all for a
tank of {full_tank}; and {world["mounds"]} spiky mounds. The map has {beams} cells of tile
$A6, the flickering beams', which the beams' generators switch off, a map row
and half the world at a time, once the special beam has destroyed them.""",

        "Fact:missiles:The missiles go for what is worth most": f"""\
A homing missile (add-on 8) without a target takes the best of the objects
drawn in the first seven records by #R$92EE(missile_target_values)
(#R$92B4(find_missile_target)). The code adds one to the type to test for a
free record ($FF) and then subtracts $14 from that, so the table is read by the
type less $13, as #R$929C(type_points) is -- and so read, it ranks the
attackers by their points, the tough attacker, which takes many hits, last.
Clouds, debris, bullets and falling parts are never chosen. Read from the
snapshot at build time:

{missile_table}
Watched in the simulator: 120 seconds of flying with fire held and add-on 8,
and 120 more with add-ons 4 and 5 as well, which bring the rotor craft and the
saucer. Every one of the {t["missiles"]["choices"]} targets chosen was the best there by
this ranking, {chosen} among them; {passed} were there and passed over.""",

        "Fact:docking:Docking borrows the death byte": """\
When the ship flies into the finished rocket, #R$9572(draw_rocket) sets
#R$8F53(death_count) to 10 for the length of two calls -- #R$C421 and the
trail, which rub the ship out at 10 -- and puts it back to nought at once, so
#R$8D42(update_objects), which would start the wreck and the death sound, never
sees it. Then #R$96AB(launch_state) is set and the rocket rises. Read, and run
in the simulator's planet trial (see the first fact).""",

        "Fact:tough:The tough attacker ignores seven hits in eight": """\
The tough attacker (type $19, #R$94A8(update_tough_attacker)) counts a laser
hit only on a pass whose pass counter has its low three bits clear: seven
laser hits in eight are thrown away. It flashes white from ten counted hits
and explodes at fourteen, scoring 75 for each. A missile's hit counts at once,
and the special beam kills it only once worn down, when it also gives a carried
ore tank one or two units. Read.""",
    }


def bc_fuel_full() -> int:
    import build_cyberun as bc
    return bc.FUEL_FULL


def bc_fuel_empty() -> int:
    import build_cyberun as bc
    return bc.FUEL_EMPTY


# --------------------------------------------------------------------------
# build
# --------------------------------------------------------------------------

def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    import build_cyberun as bc

    snapshot = Path(snapshot)
    skool = snapshot.with_name("cyberun.skool")
    entries, instructions, labels = read_listing(skool)
    for address, expected in EXPECTED_INSTRUCTIONS.items():
        found = instructions.get(address, "")
        if found != expected:
            raise RuntimeError(f"cyberun_reference: ${address:04X} is '{found}', "
                               f"not {expected}: the pokes and bugs need checking")

    memory = bc.game_memory(snapshot)
    ranking = missile_ranking(memory)
    order = [value for _, value, _ in sorted(ranking, key=lambda item: -item[2]) if value]
    if order != sorted(order, reverse=True):
        raise RuntimeError("cyberun_reference: the missiles' values no longer follow the "
                           "points: the missiles fact needs checking")
    tiles = map_tiles(memory)

    out_dir = Path(html_dir) / IMAGES
    log("  reference: the ship carrying a part, with and without the hook...")
    draw_hookless(snapshot, out_dir)
    log("  reference: the ore tank after a two-unit load...")
    ore_picture = draw_ore(snapshot, out_dir)
    if not ore_picture["stray"] or ore_picture["after_turn"]:
        raise RuntimeError(f"cyberun_reference: the ore tank's stray pixels came out as "
                           f"{ore_picture}: the ore bug needs checking")
    log("  reference: bugs, pokes, facts")

    fix = linker(entries)
    world = world_objects(memory)
    key_reads = count_instructions(instructions, "OUT ($FD),A")
    sections = {}
    for name, body in (list(_bugs(memory, tiles, world, ore_picture).items())
                       + list(_pokes(key_reads).items())
                       + list(_facts(memory, instructions, entries, tiles, world).items())):
        sections[name] = fix(body)
    for name, body in sections.items():
        for line in body.splitlines():
            if line.startswith((";", "[")):
                raise RuntimeError(f"cyberun_reference: {name} has a line starting "
                                   f"with ; or [: {line}")
    return sections


if __name__ == "__main__":
    import build_cyberun as _bc
    if "--trials" in sys.argv:
        run_trials(_bc.OUT_DIR / "cyberun.z80")
