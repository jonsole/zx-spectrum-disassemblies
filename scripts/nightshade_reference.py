"""Nightshade's reference pages: its bugs, its pokes and facts worth knowing.

build() returns SkoolKit's own Bug, Poke and Fact sections -- [Bug:x:Title],
[Poke:x:Title], [Fact:x:Title] -- for the lead to place on the Bugs, Pokes
and Facts pages (reference/bugs.html and so on). Architecture and Provenance
are written elsewhere.

The prose is written from the code and from runs of the game. Every bug says
whether it was read from the code, run in SkoolKit's simulator or watched in
the emulator; every poke was tried in the simulator against the same trial
without it, and says what each gave. The simulator runs are the build's own
Machine and session helpers (scripts/build_nightshade.py): a game started
from the menu, pokes made only at the start of a turn, cells entered by the
game's own restart. The live checks were made on a private zx_server
(ports 14711/18000/18500, --no-audio), loaded with nightshade.z80 or, for
the 128K, a 128K snapshot made from it, driven by breakpoints at MENU_LOOP
($C8E1) and MAIN_LOOP ($BE71), and killed afterwards. Where a trial was
staged by writing the game's state -- a villain put on the knight, every
cell marked visited, a record emptied -- the text says so.

Some of it is checked again at every build, in the simulator, and the build
stops if the game no longer does what the text says: the game-over screen at
a hundred per cent, with and without the poke that mends it (the two
pictures), the reset that the usual lives poke brings on (a picture), the
stack running into NMIADD after 156 games (a picture of the 157th), and
where the villains' hum reads its pitches, with and without its poke.
build() also reads the listing to check that each instruction a poke changes
is still the one the poke was written for, and keeps #R links only where
they name an entry.

Nothing here quotes the game: addresses, instructions, the pokes' own bytes
and prose. The pictures are written into the HTML directory only.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

# --------------------------------------------------------------------------
# What the bugs and pokes are about, and what the listing must still say
# --------------------------------------------------------------------------

TAKE_LIFE = 0xCBDD          # NEW_LIFE: DEC (HL), a life taken (and checked)
LIVES_POINTER = 0xCBDA      # NEW_LIFE: LD HL,$BBCD, the lives for that DEC
MONSTER_HIT = 0xCEC2        # MONSTER_HITS_KNIGHT: DEC (HL), a hit taken
VILLAIN_TOUCH = 0xD974      # VILLAIN_WANDER: RET NC, not touching the knight
TOP_SPEED_START = 0xBE4B    # NEW_GAME: LD A,$0A, the top speed
TOP_SPEED_AGAIN = 0xDA95    # UPDATE_KNIGHT: LD A,$0A, when the faster walk ends
TOP_SPEED_BONUS = 0xD740    # SPEED_BONUS: LD A,$12, the faster walk
SPAWN_MONSTER = 0xCDE8      # its first instruction
SPAWN_CREATURE = 0xBF95     # its first instruction
HUNDRED_JUMP = 0xBF40       # PRINT_PERCENTAGE: JP $C327, past the font
SPARE = 0xF195              # UNUSED_F195: never touched (measured, stage 1)
HUM_OFFSET = 0xD954         # VILLAIN_WANDER: AND $F0, the table offset
HUM_TABLE = 0xD959          # VILLAIN_WANDER: LD HL,$C35D, the lost address
READ_KEYS = 0xE239          # READ_KEYS: OUT ($FD),A
EFFECT_THREE = 0xC3DE       # EFFECT_TABLE: effect 3's address
FIRE_SOUND = 0xC3F4         # its first instruction, effect 3's first note

EXPECTED_INSTRUCTIONS = {
    TAKE_LIFE: "DEC (HL)", LIVES_POINTER: "LD HL,$BBCD", MONSTER_HIT: "DEC (HL)",
    VILLAIN_TOUCH: "RET NC", TOP_SPEED_START: "LD A,$0A", TOP_SPEED_AGAIN: "LD A,$0A",
    TOP_SPEED_BONUS: "LD A,$12", SPAWN_MONSTER: "LD A,($BC02)",
    SPAWN_CREATURE: "LD A,($BBB2)", HUNDRED_JUMP: "JP $C327", HUM_OFFSET: "AND $F0",
    HUM_TABLE: "LD HL,$C35D", READ_KEYS: "OUT ($FD),A", EFFECT_THREE: "DEFW $C3F0",
    FIRE_SOUND: "LD C,$20",
}

# Opcodes the pokes write, named for what they are.
NOP, RET, JP = 0x00, 0xC9, 0xC3
PUSH_HL, POP_HL, LD_HL_NN, LD_NN_HL = 0xE5, 0xE1, 0x21, 0x22
ADD_A_N, LD_C_A, LD_B_N = 0xC6, 0x4F, 0x06

# Addresses the pokes and the checks use.
FONT = 0x6CDE               # the digits and capitals (#R$C314 points FONT_BASE here)
TEXT_FONT_BASE = 0x6B5E     # code 0 of the text font: 48 characters below FONT
FONT_BASE = 0xBBAC
PERCENT = 0xBBFD            # the hundreds; PERCENT + 1 the tens and units
PRINT_BCD_LOW = 0xC327
VILLAIN_PITCHES = 0xC35D    # the four villains' tables, sixteen bytes each
ROM_ROW_OF_PITCHES = 0x80   # what the hum reads instead: $0080 + graphic bits
PERCENT_PRINTED = 0xCC83    # GAME_OVER, just after PRINT_PERCENTAGE
SCORE_PRINTED = 0xCC8C      # GAME_OVER, the screen complete before the tune
PITCH_READ = 0xC347         # BLIP_FROM_TABLE: LD B,(HL), the pitch
NMIADD = 0x5CB0
JP_HL = 0xE9                # what the tape leaves in NMIADD

# The pokes' new top speeds: WALK_ON's rounding leaves the knight two short
# of whatever TOP_SPEED holds, so two more reaches the 10 and 18 meant.
SPEED_MEANT, BONUS_MEANT = 12, 20

IMAGES = "images/reference"
ALIEN8_REF = "../../alien8"             # from reference/bugs.html and the like
PENTAGRAM_REF = "../../pentagram"
KNIGHTLORE_REF = "../../knightlore"
WORDS = ["none", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]


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


# --------------------------------------------------------------------------
# The pokes, as bytes
# --------------------------------------------------------------------------

def _operand_bytes(word: int) -> tuple[int, int]:
    return word & 0xFF, word >> 8


# Infinite lives. The check in NEW_LIFE reads only the DEC (HL) itself, so
# the DEC is left alone and HL is pointed elsewhere: at ROM address 2, which
# holds $11 in the 48K ROM (the first byte of LD DE,$FFFF). The DEC does not
# change the ROM, and $11 less one is positive, so the JP M after it never
# goes to the game over.
ROM_TARGET = 0x0002
LIVES_POKE = [(LIVES_POINTER + 1, ROM_TARGET & 0xFF), (LIVES_POINTER + 2, ROM_TARGET >> 8)]

IMMUNITY = [(MONSTER_HIT, RET), (VILLAIN_TOUCH, RET)]

SPEEDS = [(TOP_SPEED_START + 1, SPEED_MEANT), (TOP_SPEED_AGAIN + 1, SPEED_MEANT),
          (TOP_SPEED_BONUS + 1, BONUS_MEANT)]

NO_MONSTERS = [(SPAWN_MONSTER, RET), (SPAWN_CREATURE, RET)]

# A hundred per cent in the digits' font: eleven bytes in a part of memory
# the game never touches -- PUSH HL, LD HL,FONT, LD (FONT_BASE),HL, POP HL,
# JP PRINT_BCD_LOW -- and PRINT_PERCENTAGE's jump sent there instead.
HUNDRED_ROUTINE = [PUSH_HL, LD_HL_NN, *_operand_bytes(FONT), LD_NN_HL, *_operand_bytes(FONT_BASE),
                   POP_HL, JP, *_operand_bytes(PRINT_BCD_LOW)]
HUNDRED_FIX = ([(SPARE + i, byte) for i, byte in enumerate(HUNDRED_ROUTINE)]
               + [(HUNDRED_JUMP + 1, SPARE & 0xFF), (HUNDRED_JUMP + 2, SPARE >> 8)])

# The villains' hum from their own tables: the offset cut to bits 4-5 (AND
# $30), and the table's address added into BC -- ADD A,$5D : LD C,A :
# LD B,$C3 : NOP -- in the six bytes where LD C,A : LD B,0 : LD HL,$C35D were.
HUM_FIX = [(HUM_OFFSET + 1, 0x30), (HUM_OFFSET + 2, ADD_A_N), (HUM_OFFSET + 3, VILLAIN_PITCHES & 0xFF),
           (HUM_OFFSET + 4, LD_C_A), (HUM_OFFSET + 5, LD_B_N), (HUM_OFFSET + 6, VILLAIN_PITCHES >> 8),
           (HUM_OFFSET + 7, NOP)]

NO_OUT = [(READ_KEYS, NOP), (READ_KEYS + 1, NOP)]


def _poke_line(*writes) -> str:
    return ": ".join(f"POKE {address},{value}" for address, value in writes)


# --------------------------------------------------------------------------
# Runs of the game at build time
# --------------------------------------------------------------------------

def _started(snapshot: Path, pokes=()):
    """A game started from the menu with the keyboard, the pokes made before
    the game has run an instruction (START clears only its variables)."""
    import build_nightshade as bn

    machine = bn.Machine(snapshot)
    for address, value in pokes:
        machine.memory[address] = value
    machine.play(bn._start("1"), "reference: a game")
    return machine


def _write_screen(memory, path: Path, scale: int = 2) -> None:
    from skoolkit.components import get_image_writer
    from skoolkit.graphics import Frame, scr_udgs

    with open(path, "wb") as f:
        get_image_writer().write_image([Frame(scr_udgs(memory, 0, 0, 32, 24), scale)], f)


def hundred_screens(snapshot: Path, out_dir: Path) -> dict:
    """The screen after a game finished at a hundred per cent, as it is and
    with the poke that mends it.

    A game is started, and at the start of a turn every cell a knight can
    stand in is marked visited and the four villain records are emptied --
    as the percentage counts them, all four destroyed. The main loop's check
    for the villains (#R$D865) then goes to the game over, which works out
    the percentage and prints it; the picture is taken when the score has
    been printed too. Returns what the percentage and FONT_BASE held when the
    percentage was printed, for each."""
    import build_nightshade as bn

    def stage(memory):
        bn._visited_everywhere(memory)
        for n in range(4):
            memory[bn.VILLAINS + 16 * n] = 0

    found = {}
    for name, pokes in (("hundred", []), ("hundred_poked", HUNDRED_FIX)):
        machine = _started(snapshot, pokes)
        machine.play(bn._turn(stage) + [bn.At("the percentage printed", PERCENT_PRINTED, 30.0)],
                     f"reference: {name}")
        memory = machine.memory
        found[name] = (memory[PERCENT], memory[PERCENT + 1],
                       memory[FONT_BASE] | memory[FONT_BASE + 1] << 8)
        machine.play([bn.At("the score printed", SCORE_PRINTED, 30.0)], f"reference: {name}")
        _write_screen(memory, out_dir / f"{name}.png")
    return found


def reset_screen(snapshot: Path, out_dir: Path) -> bool:
    """The usual infinite-lives poke, a NOP over TAKE_LIFE, and the first
    death after it: NEW_LIFE finds its check failed and jumps to RESET. The
    picture is three seconds after the jump to address 0. Returns whether
    address 0 was reached."""
    import build_nightshade as bn

    machine = _started(snapshot, [(TAKE_LIFE, NOP)])
    machine.play(bn._turn(bn._kill), "reference: a death")
    try:
        machine.play([bn.At("the reset", 0x0000, 10.0)], "reference: the reset")
    except SystemExit:
        return False
    machine.run(3.0)
    _write_screen(machine.memory, out_dir / "reset.png", 1)
    return True


def stack_games(snapshot: Path, out_dir: Path) -> dict:
    """Game after game ended at once, until one fails, with SP noted at the
    menu after each. Each game is started from the menu and ended at the
    start of a turn with no lives left and the knight's life ending, so the
    game over comes by its usual way (#R$CBAC). The last picture is the game
    that failed, a second after it stopped short of play."""
    import build_nightshade as bn
    from skoolkit.simutils import SP

    machine = bn.Machine(snapshot)
    machine.play([bn.At("the menu", bn.MENU_LOOP, 30.0)], "reference: the menu")
    stack = [machine.simulator.registers[SP]]
    nmiadd = None
    games = 0
    for games in range(1, 400):
        try:
            machine.play(bn._start("1")[1:] + bn._turn(bn._game_over)
                         + [bn.At("the menu again", bn.MENU_LOOP, 60.0)], "reference: the stack")
        except SystemExit:
            break
        stack.append(machine.simulator.registers[SP])
        if machine.memory[NMIADD] != JP_HL and nmiadd is None:
            nmiadd = games
    machine.run(1.0)
    _write_screen(machine.memory, out_dir / "stack.png")
    return {"failed": games, "nmiadd": nmiadd, "first": stack[0], "last": stack[-1],
            "steps": sorted({a - b for a, b in zip(stack, stack[1:])})}


def hum_reads(snapshot: Path) -> dict[str, dict[int, set[int]]]:
    """Where BLIP_FROM_TABLE reads each villain's pitch, as the game is and
    with the hum poke: each villain in turn put in the knight's cell, a
    little way off, marked as drawn last turn; the address at the LD B,(HL)
    noted three times over, less the turn's four bits. Returns, for each
    trial, the villain's graphic -> the bases found."""
    import build_nightshade as bn
    from skoolkit.simutils import H, IXh, IXl, L

    results = {}
    for name, pokes in (("as is", []), ("poked", HUM_FIX)):
        machine = _started(snapshot, pokes)
        memory, registers = machine.memory, machine.simulator.registers
        bases: dict[int, set[int]] = {}
        for n in range(4):
            record = bn.VILLAINS + 16 * n

            def near(memory, record=record):
                memory[record + 2], memory[record + 4] = memory[bn.KNIGHT + 2], memory[bn.KNIGHT + 4]
                memory[record + 1] = (memory[bn.KNIGHT + 1] + 0x60) & 0xFF
                memory[record + 3] = memory[bn.KNIGHT + 3]
                memory[record + 7] |= 2

            def away(memory, record=record):
                memory[record + 2] = (memory[bn.KNIGHT + 2] + 10) & 31

            machine.play(bn._turn(near), "reference: a villain near")
            found = 0
            for _ in range(40):
                machine.play([bn.At("the pitch", PITCH_READ, 5.0)], "reference: the hum")
                if registers[IXh] * 256 + registers[IXl] == record:
                    address = registers[H] * 256 + registers[L]
                    bases.setdefault(memory[record] & 0xFC, set()).add(address - (memory[0xBBB2] & 15))
                    found += 1
                    if found == 3:
                        break
            machine.play(bn._turn(away), "reference: the villain away")
        results[name] = bases
    return results


# --------------------------------------------------------------------------
# The bugs
# --------------------------------------------------------------------------

def _bugs(rom_pitches: tuple[int, int], stack: dict) -> dict[str, str]:
    low, high = rom_pitches
    games = stack["failed"]
    return {
        "Bug:hum:The villains hum the ROM": f"""\
While a villain is on the screen it hums: #R$D94F(VILLAIN_WANDER) calls
BLIP_FROM_TABLE (in #R$C332) every turn, which plays twelve waves at a pitch
picked from sixteen by the turn counter's low four bits. Each villain was
meant to have its sixteen: the four tables at VILLAIN_PITCHES, between the
creature's table and the next routine (#R$C34D), are exactly four times
sixteen bytes, patterns between $20 and $90 like the creature's. The code
misses them twice over. VILLAIN_WANDER loads the
tables' address into HL, but BLIP_FROM_TABLE builds its address from the turn
bits in HL plus BC, overwriting HL first; and the offset VILLAIN_WANDER puts
in BC, the graphic turned left two bits and cut with AND $F0, keeps the
graphic's bit 5 along with its kind, so it is $80, $90, $A0 or $B0 rather
than 0, 16, 32 or 48. Every villain's pitches come from the ROM, from
$0080 to $00BF -- a few bytes of code and the start of the ROM's table of
BASIC keywords, pitches anywhere from {low} to {high} -- and the four tables
are never read.

Run in the simulator (checked at every build): each villain put in the
knight's cell a little way off, the pitch read at $C347 came from $00B0 to
$00BF for the villain of graphics 108-111, $00A0-$00AF for 104-107,
$0090-$009F for 100-103 and $0080-$008F for 96-99. The only reference to the
tables in the code is VILLAIN_WANDER's LD HL (searched). Either half mended
alone would not do; <a href="pokes.html#hum">the poke</a> mends both, and
the villains then read their own tables. What the hum sounds like is on
<a href="../Sounds.html">the sounds page</a>.""",

        "Bug:hundred:A hundred per cent prints three wrong characters": f"""\
After every game #R$CC56(GAME_OVER) prints the percentage of the game done
(#R$BEDF). Under a hundred #R$BF36(PRINT_PERCENTAGE) goes through the whole
of #R$C314(PRINT_BCD), which first points FONT_BASE at the digits
(#R$6CDE). At a hundred it prints three digits instead, and to start with the
hundreds' lower digit it jumps into the routine at PRINT_BCD_LOW, past that
line. GAME_OVER has just printed its text, which leaves FONT_BASE 48
characters lower, where the text font's code 0 would be -- bytes of the
buildings' definitions -- so the 1, 0 and 0 come out as three meaningless
characters. A hundred per cent is only reached by finishing the game, and
the ending follows this screen, so every player who finishes with every
cell visited sees it.

<div><img class="kl-scene" src="../{IMAGES}/hundred.png" alt="The game-over screen at a hundred per cent: three wrong characters after COMPLETED"/></div>
Run in the simulator (at every build): a game started from the menu, and at
the start of a turn every cell a knight can stand in marked visited and the
four villains' records emptied, which the percentage counts as four
destroyed. The game went to its game over by its own check (#R$D865), with
PERCENT holding 1 and 0 and FONT_BASE the text font's as the percentage was
printed; the picture is the screen when the score has been printed too.
Watched in the emulator the same way: the screen's bytes were the same, byte
for byte. With <a href="pokes.html#hundred">the poke</a>, the same run prints
100.""",

        "Bug:stack:The 157th game crashes": f"""\
Only #R$BDFE(START) sets the stack pointer. #R$CC56(GAME_OVER) is not called
but jumped to, from routines the main loop calls (#R$CBAC when the last life
is taken, #R$D865 when the last villain is gone), and it leaves by jumping to
#R$BE0F(NEW_GAME) or, for the ending, to MAIN_LOOP; and the end of the ending
(#R$CD10) jumps to NEW_GAME from inside an update routine. Nothing takes the
return addresses back off: every game over leaves two bytes on the stack, and
an ending four. The stack starts at $5E00 and grows down through what is left
of the BASIC program towards the system variables, where #R$5CB0(NMIADD)
holds the JP (HL) that every update goes through (#R$D593).

Run in the simulator (at every build): games started from the menu and ended
at once, one after another, with the stack pointer read at the menu after
each -- down by exactly {stack['steps'][0] if stack['steps'] else 0} bytes a game, from
${stack['first']:04X} to ${stack['last']:04X}. At the menu after game {stack['nmiadd']} NMIADD no longer held
JP (HL), and game {games} never got as far as the knight: its first update jumped
through the byte the stack had left there. Watched in the emulator too, with
the same result to the game: NMIADD changed at the 156th menu, and the 157th
game stopped at $5ED8 with the panel drawn and an empty play area. An ending
took the stack pointer at the menu down by four (the simulator, a finished
game staged as in <a href="#hundred">the hundred per cent</a>).

<div><img class="kl-scene" src="../{IMAGES}/stack.png" alt="The 157th game: the panel drawn, the play area empty, and nothing moving"/></div>
Play goes deeper into the stack than a game over does, so a game that ends
at a deeper point could fail a game or two sooner. Each game takes minutes,
so no one is likely to meet this without a script; a reload starts the count
again.""",

        "Bug:antibody:Only the first antibody can strike": """\
Two antibodies can be in flight at once: the knight's throw takes the first
free of the two antibody records (#R$DAB7). #R$C538(ANTIBODY_STRIKE), which
the monsters and the creature ask whether an antibody has hit them, means to
try both records, and loads the size of a record into DE for the step from
one to the next -- but never adds it to IY. It tries the first record twice.
An antibody thrown while another is still flying goes in the second record
and passes through everything.

Run in the simulator: two antibodies thrown in quick succession with the
game's own throw, and a monster of graphic 112 put four of the second's steps
ahead of it. The second antibody passed through the place the monster stood,
flew on until it met a wall and burst; the monster walked on and the score
did not change. The same monster put ahead of a single antibody, in the first
record, was struck the turn they met, and both burst for 2500 points.""",

        "Bug:split:A split overwrites the first monster": """\
When the kinds of a monster of graphics 112-127 and of the antibody that
strikes it add up to 2, four apart, #R$C0D1 sends the strike to #R$C101(HIT_SPLITS),
for 1500 points. By its shape it means to copy the monster into
an empty monster record and send the two off in opposite directions, each a
quarter turn from the way it was going. But its search
tests IY for an empty record, and IY is the antibody's record and the ones
after it, while IX, which the nearness test reads, stays on the first monster
record. So the struck monster is copied over the first monster record --
whatever is there -- unless that record is within a cell of the knight and
none of the five records after the antibody's is empty, when nothing is
copied. A monster in the first record copies itself onto itself, and does not
split at all.

Run in the simulator: a monster of graphic 120 in the fourth monster record
struck by an antibody of graphic 80, with a monster of graphic 64 two cells
from the knight in the first record. After the strike the first record held a
copy of the struck monster, on top of it and walking the other way, and the
monster of 64 was simply gone -- no burst, no points of its own; the score
went up by 1500. The same with the creature (graphic 136) in the first
record.""",

        "Bug:bonus:The bonus is looked for outside the town": """\
When there is no bonus #R$D76C(PLACE_BONUS) picks a cell for one: the
knight's column or four to its right, and a row from four above his to three
below. The column is wrapped round the town's 32 before the cell is looked
up; the row is wrapped only as it is stored. Near the top or the bottom of
the town the look-up (TOWN_CELL, in #R$E028, which checks nothing) reads a
byte from outside the map -- a row of -4 to -1 is taken as 252 to 255 rows
of 32 bytes, which lands in the sprites, and rows 32 to 34 in the table after
the map -- and uses it as
the cell's type, while the bonus goes into the wrapped row at the other edge
of the town.

Run in the simulator, with the bonus record emptied at the start of each of
300 turns: with the knight in cell (1,1), 74 of the look-ups were outside the
map; every one of those bytes let the bonus be placed, in rows 29 to 31, most
of them solid, and every one was gone at its first update (#R$D727 keeps a
bonus only within three cells of him). With him in cell (26,30), 105 look-ups
fell in the table after the map, and the bonus went to rows 0 and 1, solid
cells, and vanished the same way. Harmless: at worst there is no bonus near
him for a turn.""",

        "Bug:stray:A monster that may not appear appears in the corner": """\
Every fourth turn #R$CDE8(SPAWN_MONSTER) brings a monster into the knight's
cell or one of the eight round it. It copies the monster's first record
(#R$CE79, graphic 128 at U 0, V 0) into a free monster record before it
looks at the cell it chose, and if that cell is solid it returns -- leaving
the monster at the very corner of the town, cell (0,0), which is solid. After
its four turns of appearing (#R$C164) it becomes a monster like any other.
Anywhere in the middle of the town its own update then finds it too far from
the knight and empties its record: it has only kept a record busy for five
turns.

In the town's top left-hand corner it is not so tidy. With the knight in cell
(1,1), next to the corner, the stray is near enough to live; it walks off the
map, to column or row 255, and #R$C069(NEAR_KNIGHT), which compares cells a
byte at a time, finds 255 two cells from 1 and keeps it. Run in the
simulator for 1500 turns in cell (1,1): three or four of the six monster
records held a monster outside the map in all but 37 turns, and every one of
them had started as a stray at (0,0). They are never drawn and never reach
him, but they leave only two or three records for the monsters he can see.
In cell (2,2), whose neighbours are all open, and in (16,16), none left the
map. Read and run; nothing in the game says this is meant.""",

        "Bug:speed:The knight never reaches his top speed": """\
TOP_SPEED is 10, and 18 while the faster walk of the bonus lasts (#R$D727).
With walk held, #R$DCA8(WALK_ON) takes his speed halfway towards it each turn
and then clears bit 0 to keep it even. The last step is always too small to
survive that: from a standstill he goes 4, 6, 8 and stays at 8, and on the
faster walk 8, 12, 14, 16 and stays at 16. When the faster walk runs out
(#R$DA7A) his speed is set straight to 8, where he would have been anyway.
Perhaps the rounding was meant and the numbers were not; either way he walks
at four-fifths and eight-ninths of the speeds written in the code.

Run in the simulator, walk held along an open street: 4, 6, 8, 8, 8 ... and,
with the bonus just taken, 8, 12, 14, 16, 16 ... (and he still came to rest on
the eight-unit grid when the key was let go). With TOP_SPEED two higher
(<a href="pokes.html#speed">the poke</a>) he reaches 10 and 18.""",

        "Bug:drawlist:A sixteenth thing in one cell would overwrite TURN_CELL": """\
To draw the things in a cell, #R$CFAF(LIST_THINGS_IN_CELL) puts the address
of every record in it on #R$D15D(DRAW_LIST) and ends the list with a zero
word. The list has room for fifteen addresses and the zero; nothing counts
them. A sixteenth would put the zero over the first two bytes of the next
routine, #R$D17D(TURN_CELL), turning its LD A,(VIEW) into two NOPs and a
stray third byte, and from then on it would turn a cell round when A happened
to be odd rather than when the town is turned round.

Staged in the simulator: fourteen records put in the knight's cell beside
his two. After one turn TURN_CELL's first two bytes were 0, and they stayed so
after the extra records were taken away; with thirteen, fifteen in all, they
were untouched. In play the most found in one cell was four (stage 2's
measure over thirty cells). Sixteen is possible in principle -- his own two
records, two antibodies just thrown, four finds and six monsters make
fourteen, and the bonus he has walked up to and an object or two he has
thrown down there would make sixteen -- but it would take a remarkable crowd.
Latent.""",

        "Bug:attrspill:A wall's colour runs one byte past the attribute buffer": """\
The walls are coloured in the attribute buffer (#R$F044) a strip two cells
wide at a time, from the row of a wall's foot up to the top of the play area
(#R$D356, #R$C889). A strip whose left cell is the last of its row puts its
second byte in the next row's first -- the row's hidden margin, which is
never copied to the screen -- and on the top row, which is the buffer's last,
one byte past the buffer: #R$F194(ATTR_SPILL). Nothing reads it; the
buffer's clearing (#R$E200) starts just below it.

Run in the simulator: 1000 turns of walking and turning in 25 cells chosen at
random, with a marker put in ATTR_SPILL at the start of each: 269 of the turns
overwrote it, always with one of the walls' four colours, and the bytes after
it (#R$F195) never changed. Harmless.""",

        "Bug:128k:A stray OUT pages a 128K's memory": f"""\
#R$E239(READ_KEYS), byte for byte Knight Lore's, Alien 8's and Pentagram's,
does OUT ($FD),A before IN A,($FE), with the half-rows to read in A. OUT
(n),A puts A on the top half of the address bus, so the port is A * 256 +
$FD. A 48K ignores it; a 128K takes any port with bits 15 and 1 clear as its
paging port. Every half-row value with bit 7 clear is a paging write: the menu
tune's any-key test (#R$C63D) reads with A = 0, which pages in the 128's
editor ROM -- harmless, but the ROM bytes the game reads for chance and for
the villains' hum are then that ROM's -- and the pause test (#R$E32C) reads
$7E at the end of every turn, which puts RAM bank 6 at $C000, where the code
from $C000 up is, shows the other screen, and locks the paging.

Watched in the emulator's 128K, from the loaded game put into a 128K snapshot
with the 48 BASIC ROM and bank 0 paged in and the paging unlocked, as the
128's Tape Loader leaves them: the menu worked, and by the first turn the
paging port held 0; at the end of that turn it held $7E -- bank 6 at the
top, the second screen, locked -- and the machine ran off into the BASIC ROM
and stayed there over a blank screen. So on a 128K the game must be run in 48
mode. Alien 8 and Pentagram go the same way
(<a href="{ALIEN8_REF}/reference/bugs.html#128k">Alien 8</a>,
<a href="{PENTAGRAM_REF}/reference/bugs.html#128k">Pentagram</a>).
<a href="pokes.html#128k">The poke</a> that removes the OUT is with the
pokes.""",

        "Bug:pickup:The pick-up sound starts with a byte of code": """\
#R$C3BD(EFFECT_NOTE) plays a sound effect a note a turn, the last note first:
an effect of n notes plays the n bytes after its address in #R$C3D8, counting
down, and never the byte at the address itself. So each effect starts with
the next effect's first note. Effect 3, four notes when an object is taken up
(#R$D942), is the last, and its first note is the byte after the table: the
first byte of #R$C3F4(FIRE_SOUND)'s code, a half-wave count of 14 where the
table's run from 48 to 128 -- a click well above the three low notes that
follow. Pentagram has the same routine, but nothing there starts its effect
3.

Run in the simulator: an object put beside the knight and taken up; the four
notes were read from $C3F4, $C3F3, $C3F2 and $C3F1.""",
    }


# --------------------------------------------------------------------------
# The pokes
# --------------------------------------------------------------------------

def _pokes(reset_seen: bool, hum: dict) -> dict[str, str]:
    reset_text = ("the Spectrum started again from its copyright message"
                  if reset_seen else "the game did not reset (see the build log)")
    return {
        "Poke:lives:Infinite lives": f"""\
#R$CBAC(NEW_LIFE) takes a life with DEC (HL) at TAKE_LIFE (${TAKE_LIFE:04X}), and
goes to the game over when that leaves less than none. The usual poke, a NOP
there, does not work: before each new life NEW_LIFE reads that very byte, and
unless it is still DEC (HL) it jumps to address 0 and the Spectrum starts
again (see <a href="facts.html#protection">the facts</a>). So leave the DEC
where it is and aim it elsewhere: the LD HL before it gets ROM address 2
instead of LIVES. DEC (HL) cannot change the ROM, and the byte there, $11 in
the 48K ROM and in the 128's 48 BASIC ROM, less one is positive, so the JP M
after it never goes to the game over.

Tested in the simulator: a villain put on the knight at the start of every
life. Without the poke LIVES went 5, 4, 3, 2, 1, 0 and the sixth death was the
game over. With it, twelve deaths the same way and LIVES stayed at 5, the
panel showing five knights throughout. With the NOP instead, at the first
death {reset_text}:

<div><img src="../{IMAGES}/reset.png" alt="The Spectrum's copyright message: the machine reset by the game's check"/></div>
{_poke_line(*LIVES_POKE)}""",

        "Poke:immunity:Nothing can kill him": f"""\
Two things end his lives. A monster or the creature that touches him takes one
of his three hits at MONSTER_HITS_KNIGHT (in #R$CE89), and the third ends the
life; a villain's touch ends it at once (#R$D94F, into KNIGHT_KILLED). Make
the DEC (HL) that takes the hit a RET -- the monster has already been made to
vanish -- and the RET NC with which a villain gives up when it is not
touching him a plain RET, and neither can hurt him. The monsters still score
when they meet him.

Tested in the simulator, in cell (16,16): a villain put on him at the start of
every turn cost 13 lives in 300 turns without the pokes and none with them;
a monster of graphic 112 put on him whenever its record was free cost 29
hits and 9 lives in 300 turns without, and nothing with, the hits staying at
three.

{_poke_line(*IMMUNITY)}""",

        "Poke:speed:The top speeds the numbers say": f"""\
The knight never reaches TOP_SPEED (see <a href="bugs.html#speed">the
bugs</a>): he stops two short. Give TOP_SPEED two more wherever it is set --
{SPEED_MEANT} at a new game (#R$BE0F) and when the faster walk ends (#R$DA7A),
{BONUS_MEANT} for the faster walk (#R$D727) -- and he walks at the 10 and 18
the code names.

Tested in the simulator, walk held along an open street: without the pokes
his speed went 4, 6, 8 and stayed at 8, and after the bonus 8, 12, 14, 16 and
stayed at 16; with them 6, 8, 10 and 10, and after the bonus 10, 14, 16, 18
and 18. He still came to rest on the eight-unit grid when the key was let go.

{_poke_line(*SPEEDS)}""",

        "Poke:nomonsters:No monsters and no creature": f"""\
Monsters are brought in by #R$CDE8(SPAWN_MONSTER) every fourth turn, and the
creature by #R$BF95(SPAWN_CREATURE) every 256th. A RET as the first
instruction of each and none ever comes; the villains still wander, and still
kill at a touch, and the antibodies have nothing to strike.

Tested in the simulator, 1000 turns in cell (16,16): without the pokes the
six monster records were busy 5833 record-turns in all -- nearly all six all
the time -- and the creature was there for 52 turns; with them the records
stayed empty.

{_poke_line(*NO_MONSTERS)}""",

        "Poke:hundred:A hundred per cent printed as 100": f"""\
#R$BF36(PRINT_PERCENTAGE) prints a hundred in whatever font was used last
(see <a href="bugs.html#hundred">the bugs</a>). These pokes put eleven bytes
into #R$F195, which the game never touches -- PUSH HL, LD HL,$6CDE (the
digits), LD ($BBAC),HL (FONT_BASE), POP HL, JP $C327 -- and point
PRINT_PERCENTAGE's jump there instead of straight at PRINT_BCD_LOW. The
routine is outside the tape's block, so the pokes go in after loading.

Tested in the simulator, the same finished game as the bug's: FONT_BASE held
the digits' font when the percentage was printed, and the screen said 100:

<div><img class="kl-scene" src="../{IMAGES}/hundred_poked.png" alt="The game-over screen at a hundred per cent with the poke: COMPLETED 100"/></div>
{_poke_line(*HUNDRED_FIX)}""",

        "Poke:hum:The villains hum their own tunes": f"""\
Each villain was meant to hum from a table of its own, and hums from the ROM
instead (see <a href="bugs.html#hum">the bugs</a>). These pokes rewrite the
seven bytes of #R$D94F(VILLAIN_WANDER) from the AND onwards: AND $30, so the
offset is the kind alone, 0 to 48; then ADD A,$5D : LD C,A : LD B,$C3 and a
NOP, so that BC is the table itself, where LD C,A : LD B,0 and the unused LD
HL,$C35D were. BLIP_FROM_TABLE adds the turn's four bits to BC as it always
did.

Tested in the simulator (at every build), each villain put near the knight:
the pitches were read from {hum}, one table each.

{_poke_line(*HUM_FIX)}""",

        "Poke:128k:Play on a 128K in 128 mode": f"""\
#R$E239(READ_KEYS) sends the half-rows it is about to read to port $FD
before reading port $FE, an OUT that does nothing on a 48K and pages memory on
a 128K (see <a href="bugs.html#128k">the bugs</a>). The IN after it selects
the half-rows by itself, so the OUT can simply go: two NOPs.

Tested in the emulator's 128K, from the loaded game put into a 128K snapshot
with the 48 BASIC ROM and bank 0 paged in and the paging unlocked: without
the poke the game crashed at the end of its first turn of play; with it, 300
turns of play with the paging as it started ($10: bank 0, the 48 BASIC ROM,
unlocked). On a 48K it changes nothing but the refresh register, which counts
one fetch for the OUT where it counts two for the NOPs, and with it the
random numbers.

{_poke_line(*NO_OUT)}""",
    }


# --------------------------------------------------------------------------
# The facts
# --------------------------------------------------------------------------

def _facts(memory) -> dict[str, str]:
    frames = memory[0x5C78] | memory[0x5C79] << 8
    lives_opcode = memory[0xBEDD]
    return {
        "Fact:protection:Four checks, and a poke that resets the machine": f"""\
The tape loads the game scrambled and then three small blocks: 43 bytes of
loader into the printer buffer (#R$5B80), one byte, JP (HL), into
#R$5CB0(NMIADD), and two into FRAMES. The loader sets bit 7 of the refresh
register, unscrambles the game and starts it with interrupts off, for good --
there is no EI in the game, so FRAMES never counts again. The game then
checks all three, each in its own way: #R$BDFE(START) goes back to BASIC
unless FRAMES' middle byte is ${frames >> 8:02X}; every object update, every table of
routines, goes through a jump to NMIADD (#R$D593); and at every new game
#R$C1DB checks R's bit 7, which only a program can set, and resets the
Spectrum if it is clear. A copy made without the small blocks, or started any
other way, fails one of them.

A fourth check is aimed at players. Before each new life #R$CBAC(NEW_LIFE)
reads the instruction that takes a life, and if it is not DEC (HL) it jumps to
address 0: the usual infinite-lives poke resets the machine at the first
death (run in the simulator; <a href="pokes.html#lives">the pokes</a> have a
picture, and a poke that gets past it). Knight Lore, Alien 8 and Pentagram
have nothing of the kind.

FRAMES has a second use: #R$BE0F(NEW_GAME) starts the turn counter from it,
${frames:04X}, at every game, and the menu counts it on once a pass (see
<a href="#menu">waiting at the menu</a>). The checks read from the code; the
reset without R's bit 7 run in the simulator (the build's first simulator
runs did exactly that until they took R from the snapshot).""",

        "Fact:lives:The number of lives is an opcode": f"""\
There is no instruction that loads the number of lives. #R$BE0F(NEW_GAME)
reads the byte at LIVES_BYTE -- the opcode of the JR that closes the main
loop, ${lives_opcode:02X} -- and shifts it right twice: {lives_opcode >> 2}. The first life takes one
as it starts (#R$CBAC), so the panel shows five, and a game is six lives in
all. A search for the number finds nothing, and a poke to the byte breaks the
main loop. Whether it was meant as a guard is not known; it works as one. Read,
and run in the simulator: LIVES was 5 in the first life and the sixth death
was the game over.""",

        "Fact:score:The score's last two digits are always nought": """\
The score is printed as seven digits (PRINT_SCORE_AT, in #R$C2ED): the
lower digit of SCORE's
first byte, its next two bytes, and the byte after them, SCORE_ZEROS, which
nothing adds to -- #R$C2ED(ADD_SCORE) adds to the two bytes before it, and a
new game clears it. So every score ends 00, and the points are really
hundreds: a monster of graphics 64-79 adds 5 and shows as 500, a strike on
one of 112-127 adds 10 to 25 (1000 to 2500), and destroying a villain adds 25
to the middle byte: 250000. Read, and searched: no instruction addresses
SCORE_ZEROS.""",

        "Fact:menu:Waiting at the menu deals the town": """\
The menu (#R$C8CA) goes round its loop about forty times a second, and every
pass counts the turn counter on and stirs the random number with the refresh
register (#R$C5B4). The random number decides the knight's start cell
(#R$CB7B), where the four objects and the four villains go (#R$D88E,
#R$D8E7, from bytes of the ROM that it picks), how many finds each type of
building holds (#R$C1DB), and much else; the turn counter decides when
the creature first comes (every 256th turn) and which monsters head for the
knight (those born in the first half of each 256). So how long the player
waits before pressing 0 deals a different town. Run in the simulator:
starting the first game after one to six passes of the menu gave six
different start cells and six different sets of places for the villains.""",

        "Fact:rom:The ROM as a table of chance": """\
Nightshade reads bytes of the Spectrum's ROM as random numbers, with the
random number as the address: the objects and the villains are placed by
pairs of ROM bytes as a column and a row (#R$D88E, #R$D8E7), each building
type's stock of finds comes from the ROM's first 4K (#R$C1DB), and the puff
of a thing vanishing is pitched by ROM bytes (#R$C435). The villains' hum
reads the ROM too, though that was not meant (see
<a href="bugs.html#hum">the bugs</a>). Read. On a 128K whose editor ROM has
been paged in, all of these read other bytes (see
<a href="bugs.html#128k">the bugs</a>).""",

        "Fact:filmation:Filmation II, not Filmation I": f"""\
Knight Lore, Alien 8 and Pentagram are rooms: a room is built into object
records -- walls, blocks and doorways as well as what moves -- and every one
of them is sorted by depth in three dimensions and drawn as a masked sprite;
the screen flips to the next room at a doorway. Nightshade (Filmation II, as
Ultimate called it) is a town of 32 by 32 cells (#R$5E04), a byte a cell for
its type, and the view moves with the knight, who stays in the middle. The
buildings are not objects at all: #R$CF08 picks, from what stands round him,
which cells to draw and in what order, and draws their walls from tiles, the
nearest first, each 16-pixel column of the screen taken by the first wall to
reach it, so nothing behind can show there and nothing needs sorting. Only
23 records of 16 bytes are left for what moves (Knight Lore's are 32 bytes),
nothing has a height -- nothing jumps, falls or stands on anything -- and the
depth sort (#R$CFF2) orders only the things within one cell, in two
dimensions. Collision is with boxes kept for each cell type (#R$6334). Read;
see <a href="../Architecture.html">how the game is put together</a> and
<a href="../Drawing.html">the drawing</a>, and, for Filmation I,
<a href="{KNIGHTLORE_REF}/DepthSort.html">Knight Lore's depth sort</a>.""",

        "Fact:shared:What it shares with Knight Lore, Alien 8 and Pentagram": f"""\
Little of the engine, and much of the frame round it. Compared routine by
routine with the three other games' loaded code: #R$E239(READ_KEYS) is byte
for byte all three's; the tune player (#R$C63D, #R$C656, #R$C661) is
instruction for instruction Alien 8's and Pentagram's, and its note table
(#R$C6B9, 61 notes of three bytes) is the same bytes as theirs and Knight
Lore's; the menu (#R$C8CA) is
Alien 8's with its own tune and random number; the pause (#R$E32C) is Alien
8's without its beeps; the sprite turning (#R$E353) is nearly Alien 8's. The
sound effects -- #R$C3BD, #R$C3F4, #R$C471, the ending's note (#R$C39D) -- are
Pentagram's, and #R$C332's blip and its 80 bytes of pitches are in Pentagram
too, where the blip is never called: Pentagram, the later game, kept them from
this one. The town, its drawing, the movement and collision, the monsters and
the quest are Nightshade's own. See Alien 8's and Pentagram's reference pages
(<a href="{ALIEN8_REF}/reference/facts.html">Alien 8</a>,
<a href="{PENTAGRAM_REF}/reference/facts.html">Pentagram</a>).""",

        "Fact:names:The villains have no names in the game": """\
The game's text -- the menu, the panel's heading and the lines after a game
(#R$CDAF) -- names none of the game's characters or things: not the four
villains, not the four objects that destroy them, not the monsters or the
creature. The listing calls them by
their pictures and their graphic numbers -- the villain of graphics 108-111,
say, and the object whose record lies 64 bytes before the villain's, the only
thing that can destroy it (#R$C554) (see <a href="../Quest.html">the
quest</a>).
The names players know come from outside the game and were not checked
against it here; which picture goes with which name is left open.""",
    }


# --------------------------------------------------------------------------
# build
# --------------------------------------------------------------------------

def _hum_summary(hum: dict[int, set[int]]) -> str:
    parts = []
    for graphic in sorted(hum, reverse=True):
        base = min(hum[graphic])
        parts.append(f"${base:04X}-${base + 15:04X} for the villain of {graphic}-{graphic + 3}")
    return ", ".join(parts[:-1]) + " and " + parts[-1] if len(parts) > 1 else "".join(parts)


def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    import build_nightshade as bn

    snapshot = Path(snapshot)
    skool = snapshot.with_name("nightshade.skool")
    entries, instructions, _ = read_listing(skool)
    for address, expected in EXPECTED_INSTRUCTIONS.items():
        found = instructions.get(address, "")
        if found != expected:
            raise RuntimeError(f"nightshade_reference: ${address:04X} is '{found}', "
                               f"not {expected}: the pokes and bugs need checking")
    memory = bn.game_memory(snapshot)
    if any(memory[SPARE + i] for i in range(len(HUNDRED_ROUTINE))):
        raise RuntimeError(f"nightshade_reference: ${SPARE:04X} is no longer empty: check "
                           f"that nothing uses it before poking a routine there")

    out_dir = Path(html_dir) / IMAGES
    out_dir.mkdir(parents=True, exist_ok=True)

    log("  reference: the game-over screen at a hundred per cent, and mended...")
    hundred = hundred_screens(snapshot, out_dir)
    percent, low, font = hundred["hundred"]
    if (percent, low) != (1, 0) or font != TEXT_FONT_BASE:
        raise RuntimeError(f"nightshade_reference: a hundred per cent was {percent:X}{low:02X} "
                           f"with FONT_BASE ${font:04X}, not 100 with the text font's")
    if hundred["hundred_poked"][2] != FONT:
        raise RuntimeError("nightshade_reference: the hundred poke did not set the digits' font")

    log("  reference: the usual lives poke, and the reset...")
    reset_seen = reset_screen(snapshot, out_dir)
    if not reset_seen:
        raise RuntimeError("nightshade_reference: the NOP over TAKE_LIFE no longer resets")

    log("  reference: games until the stack reaches NMIADD...")
    stack = stack_games(snapshot, out_dir)
    if stack["steps"] != [2]:
        raise RuntimeError(f"nightshade_reference: the stack moved {stack['steps']} a game, not 2")
    if stack["nmiadd"] is None or stack["failed"] != stack["nmiadd"] + 1:
        raise RuntimeError(f"nightshade_reference: game {stack['failed']} failed, but NMIADD "
                           f"changed after game {stack['nmiadd']}: the stack bug needs rereading")
    log(f"  reference: game {stack['failed']} failed (NMIADD overwritten after game "
        f"{stack['nmiadd']})")

    log("  reference: the villains' hum, as it is and poked...")
    hum = hum_reads(snapshot)
    for graphic, bases in hum["as is"].items():
        expected = ROM_ROW_OF_PITCHES + 4 * (graphic - 0x60)
        if bases != {expected}:
            raise RuntimeError(f"nightshade_reference: villain {graphic} hummed from "
                               f"{sorted(bases)}, not ${expected:04X}")
    for graphic, bases in hum["poked"].items():
        expected = VILLAIN_PITCHES + 4 * (graphic - 0x60)
        if bases != {expected}:
            raise RuntimeError(f"nightshade_reference: poked, villain {graphic} hummed from "
                               f"{sorted(bases)}, not ${expected:04X}")
    if len(hum["as is"]) != 4 or len(hum["poked"]) != 4:
        raise RuntimeError("nightshade_reference: not every villain hummed")

    rom = bn.ROM.read_bytes()
    rom_pitches = (min(rom[0x80:0xC0]), max(rom[0x80:0xC0]))

    fix = linker(entries)
    sections = {}
    for name, body in (list(_bugs(rom_pitches, stack).items())
                       + list(_pokes(reset_seen, _hum_summary(hum["poked"])).items())
                       + list(_facts(memory).items())):
        sections[name] = fix(body)
    for name, body in sections.items():
        for line in body.splitlines():
            if line.startswith((";", "[")):
                raise RuntimeError(f"nightshade_reference: {name} has a line starting "
                                   f"with ; or [: {line}")
    log(f"  reference: {sum(1 for n in sections if n.startswith('Bug'))} bugs, "
        f"{sum(1 for n in sections if n.startswith('Poke'))} pokes, "
        f"{sum(1 for n in sections if n.startswith('Fact'))} facts")
    return sections
