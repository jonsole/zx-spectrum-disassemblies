"""Alien 8's reference pages: how the game is put together, its bugs, its
pokes and facts worth knowing.

build() returns SkoolKit's own Bug, Poke and Fact sections -- [Bug:x:Title],
[Poke:x:Title], [Fact:x:Title] -- and the body of the Architecture page, for
the lead to place. Provenance is a box page in alien8.ref and is not written
here.

The prose is written from the code and from checks made in the emulator.
Every poke was tried live against the same trial without it, and says what
that trial gave; every bug and fact says whether it was read from the code,
run in SkoolKit's simulator or watched in the emulator. The live checks were
made on a private zx_server loaded with alien8.z80, driven by breakpoints at
the end of each turn (MAIN_END_OF_TURN, $A6DC) from the first turns of the
first game, as notes/alien8/driving.md describes. Where a trial was staged by
writing the game's state -- a room entered by the game's own restart, a
valve put in a place record, a life taken away -- the text says so.

Nothing here quotes the game: addresses, instructions, the pokes' own bytes
and prose. The tables are worked out from the snapshot at build time -- the
update-routine table, the fullest room, the rooms with remote-controlled
robots, how the extra lives fall among the places -- and the one picture,
the panel showing ten lives, is drawn by the game's own code in SkoolKit's
simulator into the HTML directory. build() also reads the listing to check
that each instruction a poke changes is still the one the poke was written
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

LIVES_DEC = 0xCA18          # NEW_LIFE: DEC (HL), a life fewer
LEGS_KILLED = 0xC0C1        # PLAYER_LEGS: BIT 6,(IX+$0D), killed?
LEGS_JUMP = 0xC0C5          # PLAYER_LEGS: JR Z past the death
TOP_KILLED = 0xC6E7         # TOP_FOLLOWS_LEGS: BIT 6,(IX+$0D)
TOP_JUMP = 0xC6EB           # TOP_FOLLOWS_LEGS: JR Z past the death
CLOCK_BORROW = 0xADC9       # its first instruction
KIND_TEST = 0xAF90          # LOOSE_VALVE: JR NZ, not this socket's kind
KIND_AGAIN = 0xAFEF         # LOOSE_VALVE: JR Z, the kinds again
LAST_CHAMBER = 0xB040       # LOOSE_VALVE: CP $24, the twenty-fourth
DROP_LATCHED = 0xAD1D       # CEILING_DROP: RET NZ, latched
TURN_SOUND = 0xC217         # TURNING_LEGS: CALL $B6D4, the sound that loses C
SPARE_CODE = 0xAB1F         # FACE_BY_STEP_UNUSED: nothing reaches it
READ_KEYS = 0xB759          # READ_KEYS: OUT ($FD),A

EXPECTED_INSTRUCTIONS = {
    LIVES_DEC: "DEC (HL)", LEGS_KILLED: "BIT 6,(IX+$0D)", LEGS_JUMP: "JR Z,$C0CE",
    TOP_KILLED: "BIT 6,(IX+$0D)", TOP_JUMP: "JR Z,$C6F4", CLOCK_BORROW: "LD HL,$5B39",
    KIND_TEST: "JR NZ,$AFD0", KIND_AGAIN: "JR Z,$AFF8", LAST_CHAMBER: "CP $24",
    DROP_LATCHED: "RET NZ", TURN_SOUND: "CALL $B6D4", SPARE_CODE: "LD A,(IX+$09)",
    READ_KEYS: "OUT ($FD),A",
}

# Opcodes and operands the pokes write, named for what they are.
NOP, JR, RET, CALL, PUSH_BC, POP_BC = 0x00, 0x18, 0xC9, 0xCD, 0xC5, 0xC1
RES_6 = 0xB6                # the fourth byte of RES 6,(IX+d), where BIT 6 has $76
FOOTSTEP_NOW = 0xB6D4       # the sound TURNING_LEGS calls

# Memory the tables read at build time.
UPDATES = 0xA7EA            # a word per graphic: its update routine
UPDATE_COUNT = 131          # graphics 0 to 130 (#R$A6B1 indexes it)
GRAPHICS = 0x7827
GRAPHIC_COUNT = 132
START_ROOMS = 0xCA9E
PLACE_COUNT = 36
ROOM_RECORDS = 52           # records 4 to 55, what the room builder fills
REMOTE_ROBOT = 124
FRAGILE = 129
PANEL_ICON = 131

# The live measurements the prose quotes (see the module's docstring).
FRAMES_QUIET = 85           # 50 turns standing in an empty room
FRAMES_START = 95           # 50 turns standing in start room $13

IMAGES = "images/reference"
KNIGHTLORE_TOP = "../knightlore"        # from a page at the top of html_dir
PENTAGRAM_TOP = "../pentagram"
KNIGHTLORE_REF = "../../knightlore"     # from reference/bugs.html and the like
PENTAGRAM_REF = "../../pentagram"
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


def _word(memory, address: int) -> int:
    return memory[address] | memory[address + 1] << 8


def _ranges(numbers: list[int]) -> str:
    """1, 2, 3, 5 -> '1-3, 5'."""
    runs, start, last = [], None, None
    for n in sorted(numbers):
        if start is None:
            start = last = n
        elif n == last + 1:
            last = n
        else:
            runs.append((start, last))
            start = last = n
    if start is not None:
        runs.append((start, last))
    return ", ".join(f"{a}" if a == b else f"{a}-{b}" for a, b in runs)


def _rooms(numbers) -> str:
    numbers = sorted(numbers)
    text = [f"${n:02X}" for n in numbers]
    if len(text) < 2:
        return "".join(text)
    return ", ".join(text[:-1]) + " and " + text[-1]


# --------------------------------------------------------------------------
# What is read from the game at build time
# --------------------------------------------------------------------------

def _template_pieces(memory, index: int) -> list[int]:
    """The graphics of an object template's five-byte pieces, up to the zero
    that ends it (#R$CD62)."""
    import alien8_data as ad
    address = _word(memory, ad.OBJECT_TABLE + 2 * index)
    if not address:
        return []
    graphics = []
    while True:
        graphics.append(memory[address])
        address += 5
        if memory[address] == 0:
            return graphics


def _background_pieces(memory, index: int) -> int:
    import alien8_data as ad
    address = _word(memory, ad.BACKGROUND_TABLE + 2 * index)
    count = 0
    while memory[address]:
        count += 1
        address += 8
    return count


def room_contents(memory) -> dict[int, dict]:
    """Per room: the records the builder fills (each background piece and
    each template piece at each position) and the templates it places --
    template 31 moving to the second page, template 0 the nudge (#R$CCA7)."""
    import alien8_data as ad
    rooms = {}
    for record in ad.room_records(memory):
        filled = sum(_background_pieces(memory, b) for _, b in record["backgrounds"])
        page, templates = 0, []
        for _, template, _, positions in record["groups"]:
            if template == 0:
                continue
            if template == 31:
                page = 32
                continue
            templates += [template + page] * len(positions)
            filled += len(_template_pieces(memory, template + page)) * len(positions)
        rooms[record["number"]] = {"filled": filled, "templates": templates}
    return rooms


def rooms_with(memory, rooms: dict, graphic: int) -> dict[int, int]:
    """Room -> how many copies of a graphic the room's templates place."""
    found = {}
    for number, room in rooms.items():
        count = sum(_template_pieces(memory, t).count(graphic) for t in room["templates"])
        if count:
            found[number] = count
    return found


def extra_life_counts() -> dict[int, int]:
    """How many of the 256 values RANDOM can hold at a new game give two
    extra lives and how many three: #R$AF3F counts D down once a place and
    gives an extra life where its low four bits reach nought."""
    counts = {}
    for random in range(256):
        d, n = random, 0
        for _ in range(PLACE_COUNT):
            d = (d - 1) & 0xFF
            if d & 0x0F == 0:
                n += 1
        counts[n] = counts.get(n, 0) + 1
    return counts


def update_table(memory, labels: dict[int, str]) -> list[tuple[int, str, list[int]]]:
    """(routine, its label, the graphics that use it), in address order."""
    users: dict[int, list[int]] = {}
    for graphic in range(UPDATE_COUNT):
        users.setdefault(_word(memory, UPDATES + 2 * graphic), []).append(graphic)
    return [(address, labels.get(address, f"${address:04X}"), graphics)
            for address, graphics in sorted(users.items())]


def graphic_131(memory) -> dict:
    """Graphic 131: the sprite it draws, which other graphics share it, and
    whether any template or background places it."""
    import alien8_data as ad
    sprite = _word(memory, GRAPHICS + 2 * PANEL_ICON)
    sharers = [g for g in range(GRAPHIC_COUNT) if g != PANEL_ICON
               and _word(memory, GRAPHICS + 2 * g) == sprite]
    placed = [i for i in range(ad.OBJECT_COUNT) if PANEL_ICON in _template_pieces(memory, i)]
    for index in range(ad.BACKGROUND_COUNT):
        address = _word(memory, ad.BACKGROUND_TABLE + 2 * index)
        while memory[address]:
            if memory[address] == PANEL_ICON:
                placed.append(100 + index)
            address += 8
    return {"sprite": sprite, "sharers": sharers, "placed": placed}


def draw_lives(snapshot: Path, out_dir: Path) -> list[int]:
    """The lives on the panel, nine and then ten, drawn by the game.

    A game is started from the menu as the build's sessions start one; an
    extra life is put in the start room beside where a life starts, LIVES is
    set to the number wanted and the robot's death is started. The game's
    own new life takes one away, and the extra life, touched as he appears,
    gives it back (#R$BEE0), printing the count on the panel (#R$BA57).
    Returns the counts it drew; each picture is the panel's middle, from the
    screen."""
    import build_alien8 as ba
    from skoolkit.components import get_image_writer
    from skoolkit.graphics import Frame, scr_udgs

    drawn = []
    out_dir.mkdir(parents=True, exist_ok=True)
    for lives in (9, 10):
        machine = ba.Machine(snapshot)
        machine.play(ba._start("1"), "reference: a game")

        def stage(memory, lives=lives):
            place = ba.PLACES + ba.PLACE_SIZE
            memory[place] = ba.EXTRA_LIFE
            memory[place + 5:place + 9] = bytes((128, 140, 64, ba.START_ROOM))
            memory[ba.LIVES] = lives
            for record in (ba.START_LEGS, ba.START_TOP):
                memory[record + 8] = ba.START_ROOM
                memory[record + 1], memory[record + 2] = 128, 128
            ba._kill(memory)

        machine.play([ba.Until("a live player", ba._playing, 30.0), stage,
                      ba.Until("the extra life taken",
                               lambda memory: memory[ba.PLACES + ba.PLACE_SIZE] == 0, 30.0),
                      ([], 0.5)], f"reference: {lives} lives")
        memory = machine.memory
        if memory[ba.LIVES] != lives:
            raise RuntimeError(f"alien8_reference: staged {lives} lives, the game has "
                               f"{memory[ba.LIVES]}")
        drawn.append(memory[ba.LIVES])
        with open(out_dir / f"lives{lives}.png", "wb") as f:
            get_image_writer().write_image([Frame(scr_udgs(memory, 13, 21, 6, 3), 3)], f)
    return drawn


# --------------------------------------------------------------------------
# The pokes
# --------------------------------------------------------------------------

def _poke_line(*writes) -> str:
    return ": ".join(f"POKE {address},{value}" for address, value in writes)


IMMUNITY = [(LEGS_KILLED + 3, RES_6), (LEGS_JUMP, JR), (TOP_KILLED + 3, RES_6), (TOP_JUMP, JR)]
ANY_KIND = [(KIND_TEST + 1, 0), (KIND_AGAIN, JR)]
KEEP_WALKING = [(SPARE_CODE, PUSH_BC), (SPARE_CODE + 1, CALL), (SPARE_CODE + 2, FOOTSTEP_NOW & 0xFF),
                (SPARE_CODE + 3, FOOTSTEP_NOW >> 8), (SPARE_CODE + 4, POP_BC), (SPARE_CODE + 5, RET),
                (TURN_SOUND + 1, SPARE_CODE & 0xFF), (TURN_SOUND + 2, SPARE_CODE >> 8)]


def _pokes() -> dict[str, str]:
    return {
        "Poke:lives:Infinite lives": f"""\
#R$CA07(NEW_LIFE) starts every life, the first of a game included: it copies
the two start records over the robot's and takes a life with DEC (HL) at
${LIVES_DEC:04X}, going to the game over (#R$B761) when that leaves less than
none. Make the DEC a NOP and LIVES never moves. The JP M after it still tests
the sign flag, which both ways in leave clear (read: #R$CAD2 ends on a
subtraction that leaves a small positive number, and the main loop's check
on the robot's records ends on a zero). Put in before a game starts, the panel
should show 05 instead of 04 (read).
Tested: standing still in room $5E at U 96, V 160, where the chaser homes in
(the room entered by the game's own restart), he was killed every 37 turns,
and from 4 lives the fifth death, 170 turns in, was the game over. With the
poke he died 33 times in 1200 turns and LIVES never moved.

{_poke_line((LIVES_DEC, NOP))}""",

        "Poke:immunity:Nothing can kill him": f"""\
Whatever kills the robot does it the same way: the collision code sets bit 6
of the +$0D of the record it meets -- from the mover's bit 7, or the
obstacle's bit 5 (#R$C497, #R$C4E6, #R$C535) -- and the next time the legs'
update routine (#R$C0BE) or the top's (#R$C6E4) runs, it tests that bit and
starts the dying sparkle, marking the other half killed too. Make each BIT 6 a
RES 6 -- one byte, the fourth of the instruction -- and each JR Z after it a
JR, and the mark is wiped and ignored every turn, on both halves. (The legs' routine
while he turns, #R$C1E2, never looks at the bit; the top's catches it then.)
Tested: the same trial as the lives poke -- room $5E, standing still in the
chaser's way -- five deaths in 170 turns and the game over without it; with
it, 1200 turns, no death, and 4 lives.

{_poke_line(*IMMUNITY)}""",

        "Poke:clock:The light years never run out": f"""\
#R$AD66(RUN_CLOCK) counts the light years down once a turn: #R$ADC9 takes one
off the last digit (borrowing up the others) whenever the last digit has
finished rolling into place, and all four at nought ends the game. A RET as
#R$ADC9's first instruction and nothing is ever taken off; the digits that
are rolling finish their roll and stop.
Tested: from the first turns of a game, 700 turns took the clock from 5997 to
5897 -- a light year every seven turns -- and with the poke it stayed at
5997. With the clock staged at 0001 at the start of a turn, the game was over
6 turns later; with the poke, 300 turns later it still said 0001.

{_poke_line((CLOCK_BORROW, RET))}""",

        "Poke:anykind:Any valve will do": f"""\
A valve (#R$AF79) steers itself to a chamber's socket, and activates the
chamber when it sits on it, only when the socket is of its own kind: the JR NZ
at ${KIND_TEST:04X} skips everything if the kinds differ, and the JR Z at
${KIND_AGAIN:04X} checks them again before the valve is seated (otherwise it
would be destroyed, which never happens as the game is). Give the first JR a
displacement of 0, so that it goes on whichever way the test comes out, and
make the second a JR, and any valve does for any chamber. It becomes the
seated valve of its own kind, which the summary counts all the same
(#R$AC6B looks only for a seated valve in the chamber's room).
Tested: in chamber $0C, whose socket takes kind 0, a valve of kind 1 put in
the room's middle, high up, before the room was entered: without the poke it
fell onto the things hanging in the middle of the room and lay there for 200
turns, and held over
the socket and dropped onto it, it sat there another 200 turns with the count
at 00. With the poke it steered itself onto the socket while the robot was
still appearing, the room turned white and the count went to 01.

{_poke_line(*ANY_KIND)}""",

        "Poke:firstwins:The first chamber wins": f"""\
When a chamber is activated #R$AF79 adds one to CHAMBERS in BCD and compares
it with $24 at ${LAST_CHAMBER:04X}: the twenty-fourth sets WON and ends the
game. Make the CP $24 a CP 1 and the first chamber ends it -- a quick way to
see the arrival screen, the rating for a finished game and the scene of the
robot being oiled.
Tested: a valve of kind 0 put in chamber $0C's room: without the poke it
steered itself onto the socket, the count went to 01 and the game went on for
another 100 turns; with it, WON was set and the game went straight to its
end (#R$B761).

{_poke_line((LAST_CHAMBER + 1, 1))}""",

        "Poke:nodrops:Nothing drops from the ceiling": f"""\
The things hanging from the ceiling (graphic 73, #R$AD13) fall one at a time
on a turn when the random number is under 16 -- but only when DROP_LATCH is
clear, and #R$CAA2 sets it on entering an even-numbered room, where all four
rooms that have them are ($0C, $1C, $58, $84); picking something up or taking
an extra life there clears it. Make the RET NZ that obeys the latch a RET and
they never fall. They are still deadly to walk into (read).
Tested: in room $58, with its sixteen hanging over a floor of blocks, the
robot stood on the block under one, and the latch was cleared as a pick-up
clears it (the immunity poke in both trials, so that nothing restarted the
room): without this poke all sixteen had fallen within 300 turns, one at a
time, the last the one over him, which came to rest on his head; with it,
none fell in 600 turns.

{_poke_line((DROP_LATCHED, RET))}""",

        "Poke:turning:Keep walking through a turn": f"""\
A quarter turn costs a walking robot three turns standing still where two
were meant (see <a href="bugs.html#turning">the bugs</a>): the sound
#R$C1E2 makes as a turn ends leaves C at nought, and C was the controls. These
pokes put a four-instruction routine -- PUSH BC, CALL the sound, POP BC, RET
-- into the first bytes of #R$AB1F, code that nothing reaches, and call it in
place of the sound, so the step meant for the last turn of a turn is taken.
Tested: walking with A held and turning with Z (or X) for one turn in room
$2B, U and V stood still for three turns without the pokes, and for two with
them, after which the robot walked on 3 units a turn either way.

{_poke_line(*KEEP_WALKING)}""",

        "Poke:128k:Play on a 128K in 128 mode": f"""\
#R$B759(READ_KEYS) sends the half-row it is about to read to port $FD before
reading port $FE, an OUT that does nothing on a 48K Spectrum and pages memory
on a 128K (see the bugs). The IN after it selects the half-rows by itself, so
the OUT can simply go: two NOPs.
Tested on the emulator's 128K machine, from the loaded game put into a 128K
snapshot with the 48 BASIC ROM and bank 0 paged in and paging unlocked, as
the 128's Tape Loader leaves it: without the poke the game crashed on its
first turn of play; with it, 300 turns of play, walking out of start room $13
into room $14, and the paging was as it started. On the 48K the same 300
turns went exactly as without the poke, to the same room and the same spot.

{_poke_line((READ_KEYS, NOP), (READ_KEYS + 1, NOP))}""",
    }


# --------------------------------------------------------------------------
# The bugs
# --------------------------------------------------------------------------

def _bugs(fullest: tuple[int, int], lives_drawn: list[int]) -> dict[str, str]:
    room, filled = fullest
    spare = ROOM_RECORDS - filled
    return {
        "Bug:turning:A turn forgets that he was walking": """\
Alien 8's robot turns through an in-between view (graphics 24-27) held for
two turns, where Knight Lore's and Pentagram's heroes turn at once. The turn
a turn starts takes no step (#R$C296 takes none with an in-between graphic),
the next only lets him fall, and on the third #R$C1E2 puts in the new facing
and means to take a step if walk is held, by coming into #R$C296 at
MOVE_IF_WALKING, which tests bit 2 of C, the controls. But first it makes the
turn's sound (#R$B6CE, at the entry that skips the frame test), whose loop
counts C down to nought and hands it back so. The step is never taken, and
gravity takes its full two units whatever is held. #R$C25E, which makes the
same sound as he walks, keeps BC round it.

Watched in the emulator, in room $2B, walking along U with A held and
turning left with Z for one turn: U went 131, 134, 137, then the in-between
view 26 for two turns and the new facing on the third, all at U 137, V 128,
and V only began to grow on the turn after that. With BC kept round the
sound (<a href="pokes.html#turning">the poke</a>), the new facing came with
its first step, V 131. The same with X, turning right.""",

        "Bug:valves:A life that starts on a valve destroys it": """\
Knight Lore's depth sort has a case for two boxes that occupy the same space,
and there it destroys a collectable; Alien 8 keeps it for its valves
(#R$C8AB): unless one of the two is out of the collision tests, a loose valve
(graphics 96-99) found sharing space with anything becomes graphic 64, the
sparkle things vanish in, and at 65 its place in #R$76E3 is emptied (#R$B3B0).
The valve is gone for the rest of the game. The collision code keeps things
from moving into each other, but a new life does not move the robot: it
copies him from the start records (#R$CA07), at the spot where he last came
through a doorway (read), and the appearing robot is in the collision tests.
So a valve put down where he came into a room is destroyed the next time he
dies in that room.

Watched in the emulator, the valve staged: a kind-0 valve in room $2B at
U 128, V 128, on the floor, and the robot's death started with his start
records in that room at the same spot. As he began to appear the depth sort
destroyed the valve (the IY branch, with IX on his legs): its record went
through graphics 65 and 1 to empty, and its place's graphic to 0. The same
valve 22 units away was untouched.

Every valve may count. #R$AF3F deals the kinds round in turn and gives every
sixteenth place an extra life instead, and places sixteen apart are of the
same kind, so the kind that lands on the extra lives loses them: in a game
with three extra lives that kind has six valves, as many as its sockets, and
a valve lost this way leaves the twenty-fourth chamber out of reach
(inferred from the dealing; see the facts).""",

        "Bug:128k:A stray OUT pages a 128K's memory": f"""\
#R$B759(READ_KEYS) does OUT ($FD),A before IN A,($FE), with the half-rows to
read in A. OUT (n),A puts A on the top half of the address bus, so the port
is A * 256 + $FD. A 48K ignores it. A 128K takes any port with bits 15 and 1
clear as its paging port, $7FFD: every half-row value with bit 7 clear is a
paging write. The menu tune's "any key" test (#R$B4A1) reads with A = 0, which
pages the 128's editor ROM in and does no harm, since the game never calls
the ROM (it only reads its bytes as noise). But the pause test (#R$CE22) reads
$7E at the end of every turn, whatever the controls, and the keyboard reader
reads SPACE's half-row as $7F: either puts RAM bank 6 or 7 at $C000, where the
code from $C000 up and the screen buffer are, and locks the paging.

Watched in the emulator's 128K, from the loaded game put into a 128K snapshot
with the 48 BASIC ROM and bank 0 paged in, as the 128's Tape Loader leaves
it: the menu worked, with ROM 0 paged in by the tune's key test; at the end of
the first turn of play READ_KEYS was called with $7E from the pause test, the
paging port became $7E -- bank 6 at the top, the second screen shown, locked
-- and the machine ran off into the ROM. So on a 128K the game must be run in
48 mode. Pentagram has the same OUT, and
<a href="{PENTAGRAM_REF}/reference/bugs.html#128k">the same fate</a>. The poke
that removes the OUT is with the pokes.""",

        "Bug:lives:Ten lives would show as none": f"""\
LIVES counts in binary -- #R$CA07 takes one with DEC, #R$BEE0 adds one with
INC -- but #R$BA57 prints it as two BCD digits, with the font itself as the
base so that digit n is the nth character (#R$6308). Ten lives, $0A, print as
0 and the eleventh character, which is a second nought (see the facts): 00.
It cannot happen in play. A game starts with five, the first life takes one,
and #R$AF3F deals two or three extra lives a game, never more (worked out for
every value of the random number it starts from), so a player who never dies
ends with at most seven.

<div><img src="../{IMAGES}/lives9.png" alt="The panel's lives with nine"/> <img src="../{IMAGES}/lives10.png" alt="The panel's lives with ten, showing 00"/></div>
Drawn by the game's own code in SkoolKit's simulator: a game started from the
menu, LIVES staged at {lives_drawn[0]} and then at {lives_drawn[1]} as a life
begins beside an extra life, which the robot touches as he appears. Watched in
the emulator too: nine lives and an extra life made ten, and the panel said
00.""",

        "Bug:collapse:A collapsing block empties the place at address 0": """\
Graphic 65, the last frame of the sparkle a thing vanishes in, empties the
thing's place in #R$76E3 through the address in +$10 and +$11 of its record
(#R$B3B0), which is right for an extra life. But a collapsing block
(#R$B28C) goes through the same frames when it is stood on, and its +$10 and
+$11 are nought: it writes a zero to address 0, which is ROM and ignores it.
Watched in the emulator, in room $12, the robot put on the stack of two
collapsing blocks: each became graphic 65, and a logpoint on the write showed
HL = $0000 both times; the ROM's first byte was unchanged. Harmless.""",

        "Bug:socket:The socket projects the wrong record": """\
A chamber's socket (#R$AE68) brings its sparkle back when nothing lies in the
room from the places and the record after the socket is empty -- as when the
sparkle vanished because a valve lay there and the valve has gone. It puts
the sparkle's graphic in the record and then jumps to #R$AE8A, which projects
the record at IY onto the screen. IY is whatever an earlier update routine
left there, not the sparkle. It does no harm: the record projected is
recomputed from its own position, and every object drawn is projected again
by #R$D013 anyway, so the new sparkle is drawn where it should be.
Watched in the emulator, in chamber $0C with a valve of the wrong kind in the
room and then taken away as a pick-up takes it: at the jump IY was $5B88, the
robot's legs, and the sparkle came back over the socket the next turn.""",

        "Bug:scene:The hammer leaves the robot's head green": """\
In the scene after a lost game the robot is re-programmed: a glove, a hook
and a hammer take turns to strike him. Each piece of the scene colours the
character cells it covers (#R$AC21), except any that are bright green,
$44 -- the hammer's colour, so that nothing paints over the hammer as it
swings. But once the hammer has swung back up, the cells it coloured on the
robot's head are still bright green, and the robot, which skips them too,
never gets them back. Watched in the emulator: twenty turns into the scene the
robot was cyan all over; three hundred turns in, after the hammer's blows, the
top of his head was green.""",

        "Bug:footstep:The lower halves' footsteps are silent": """\
The two-part creatures (templates 17 to 19) put their lower half, graphic 11,
in a record of its own, and its update routine (#R$B055) asks for a footstep
each time the upper half moves. #R$B6C0 plays one only for an even graphic --
Knight Lore's walkers changed graphic as they walked -- and 11 is odd, so it
returns at once, every time. Read from the code; the build's sessions never
ran the rest of #R$B6C0.""",

        f"Bug:clearing:A room of more than {ROOM_RECORDS} records would run away": f"""\
#R$CCA7(BUILD_ROOM) fills records from the fifth up, as many as the room's
backgrounds and templates need, and then clears the rest, stopping when its
pointer is exactly #R$6288, the end of the records (BUILD_CLEAR_REST, $CCD0).
Nothing checks that the room fitted: a room of more than {ROOM_RECORDS} records
would build past the end of the records, and the clearing loop, testing for
equality only, would never meet $6288 again and would clear its way through
memory. None does. Counted from the room data the way the builder reads it,
the fullest room is ${room:02X}, with {filled} records, {WORDS[spare] if spare < 10 else spare}
to spare, and nothing adds records to a room once it is built -- the socket's
sparkle only reuses its own. Watched in the emulator: room ${room:02X}, entered,
had {filled} records in use. Latent.""",

        "Bug:flip:A sprite one row high would turn over 256 times": """\
Sprites are turned in place (#R$D174): upside down by swapping rows in pairs
from the ends inwards, half the height times. A sprite one row high makes that
nought, and the DJNZ loop would run 256 times, through whatever follows the
sprite. Only one sprite is one row high, graphic 5, the sides of the border
(#R$CBC3), and it is only ever mirrored, never turned upside down, so it never
happens. Read from the code and the graphic table; Knight Lore's routine is
the same.""",

        "Bug:third:A third valve in a room would overrun": """\
#R$AE99, as a room is built, puts every place in use in that room into
records 2 and 3, and clears what is left of them. Nothing stops it at two: a
third would go into record 4, the room's first, and the clearing after the
loop would never meet record 4 again and would run on through memory. The 36
places start in 36 different rooms, and a valve is put down only into an
empty one of the two records (#R$BD6B), so a room never holds three. Knight
Lore's find_special_objs_here has the same shape. Read; latent.""",
    }


# --------------------------------------------------------------------------
# The facts
# --------------------------------------------------------------------------

def _facts(memory, rooms: dict, extras: dict[int, int], icon: dict) -> dict[str, str]:
    robots = rooms_with(memory, rooms, REMOTE_ROBOT)
    two = [r for r, n in robots.items() if n > 1]
    fragile = rooms_with(memory, rooms, FRAGILE)
    starts = [memory[START_ROOMS + i] for i in range(4)]
    placed = ("no template or background places it" if not icon["placed"]
              else "a template or background places it too")
    shared = ("no other graphic draws that sprite" if not icon["sharers"]
              else "graphics " + _ranges(icon["sharers"]) + " draw the same sprite")
    two_text = (f"Room {_rooms(two)} has two" if len(two) == 1 else f"Rooms {_rooms(two)} have two")
    return {
        "Fact:copyright:Knight Lore's copyright line is still in the block": """\
Just after the last routine, at #R$D1EB, where Knight Lore has its own, lies a
line of text naming 1984 and A.C.G. that nothing reads: it is Knight Lore's
copyright line, byte for byte (compared with Knight Lore's loaded game). Alien
8's own menu names 1985 (#R$BB90). Knight Lore's block ends the same way --
copyright line, screen buffer, tables -- which suggests the new game was made
by working on the old one's source.""",

        "Fact:interface1:An Interface 1 in the leftovers": """\
The tape block runs to the top of memory, so it carries whatever the machine
it was saved from had above the code, in the space the game uses for its
screen buffer (#R$D200) and its tables (#R$F100). Among it are the Spectrum
ROM's capital letters, stack debris, another program's font, and 1464 bytes
that are, by their structure, the start of the Interface 1's ROM -- its
restart routines, its use of the Interface 1's system variables, and its
error reports -- so the mastering machine had a Microdrive interface fitted.
Measured by disassembling the leftover as if at address 0 (30 of its 31
jumps into itself land on instruction starts); not compared with an Interface
1 ROM image. The game overwrites all of it before reading any (measured in the
simulator).""",

        "Fact:deadcode:Knight Lore's werewolf and window, left in": """\
Two routines no one calls are Knight Lore's, compared with its loaded game:
#R$B65F, the sound of Sabreman turning into the werewolf (sound_transform
there), equal but for the address of the sound routine it calls; and the code
at $CBE3 inside #R$CBC3, which coloured Knight Lore's sun-and-moon window
(colour_panel), equal but for the address of its fill routine. Alien 8 has
neither a werewolf nor the window. Other code left unreached: #R$AB1F, which
would turn a thing to face along its steps; code and a table of pitches after
the note table at #R$B51D that would beep at a pitch chosen by the turn
counter; a drawing
nudge at $BF42; and #R$A8F1, a check on the refresh register that returns at
once.""",

        "Fact:rating:Knight Lore's rating, word for word": f"""\
The summary after a game rates the player with one of eight words from
#R$B9DD -- four for a game lost, four better ones for a game won, a step up
for every 32 rooms seen (#R$B761, #R$B881). The words, their order and the
rule are Knight Lore's (compared with its table and its game_over_summary),
down to AVERAGE ranking below FAIR. Only the counts beside them are Alien
8's: the chambers activated and not, and the crew lost in the ones not
(#R$AC6B). See <a href="{KNIGHTLORE_REF}/reference/facts.html">Knight Lore's
facts</a>.""",

        "Fact:nought:The clock rolls from a second nought": """\
The light years (#R$AD66) are four digits, each drawn a few rows out of line
while it rolls into place, like a mechanical counter's wheel: a digit that has
just changed shows mostly the character after it, and scrolls down. The
character after 9 in the font (#R$6308) is a second 0, the same eight bytes,
so a 9 that follows a 0 rolls in from a nought as it should. The text printer
never uses that code, since it is the colon. It is also why ten lives would
print as 00 (see the bugs). Compared from the font's bytes.""",

        "Fact:icon:Graphic 131 is only a picture on the panel": f"""\
The graphic table (#R$7827) has {GRAPHIC_COUNT} words, graphics 0 to
{GRAPHIC_COUNT - 1}, but the table of update routines (#R$A7EA) has
{UPDATE_COUNT}: graphic {PANEL_ICON}, the last, has none. Nothing in a room
could have it -- {placed}, and {shared} -- because nothing but the panel draws
it: #R$CB0F puts it beside the count of chambers activated, as the chambers'
icon, through the spare record it draws the panel with, which never goes
through the update table. Read from the snapshot at build time.""",

        "Fact:remote:The remote-controlled robots": f"""\
Some rooms have a robot of their own, graphic {REMOTE_ROBOT} (#R$A9C7), which
the player drives by standing on the buttons on the floor: each of four makes
it walk two units a turn one way, the pad (#R$AA4D) stops it. Counted from the
room data: {len(robots)} rooms have them, {_rooms(robots)}. {two_text},
and control passes from one to the other each time he steps off a button.
They are harmless, and they push the fragile things (graphic {FRAGILE},
#R$A9B1) -- deadly to touch, and broken by any push -- that stand in
{len(fragile)} rooms, {_rooms(fragile)}. Measured in the simulator (the
build's sessions, room $0B).""",

        "Fact:crew:The cryonaughts": """\
The frozen crew in the chambers (graphic 74, #R$AE96) only stand, but the
summary counts them: every chamber not activated at the end of the game adds
its crew to those lost (#R$AC6B). A game lost at once counts all 24 chambers
unactivated and 132 crew lost (watched in the emulator and counted from the
room data). Both the summary and the arrival screen after a win (#R$B8A9)
spell them CRYONAUGHTS.""",

        "Fact:menu:Waiting at the menu chooses the start": f"""\
#R$CA6D starts a game in one of four rooms from #R$CA9E -- {_rooms(starts)} --
by the low two bits of SEED, and #R$AF3F starts the kinds of valve from SEED
plus the refresh register. SEED is the ROM's frame counter as the game first
runs (#R$A631), plus the turn count at every new game, and #R$BA7E adds one to
it every time round its loop, about thirty times a second (20 passes took 31
frames, measured): so how long the player
waits before pressing 0 chooses the start room. Watched in the emulator,
starting the first game after loading at successive passes of the menu: the
start room went $13, $4E, $88, $D7 and round again. (Pentagram stirs its
random number only once before its menu, so there the wait makes no
difference.)""",

        "Fact:tune:The menu tune plays at every visit": """\
#R$B4A1 plays the menu's tune once and remembers it in TUNE_HEARD; but
TUNE_HEARD is one of the variables #R$A647 clears after every game, so the
tune plays again, in full unless a key stops it, each time the game comes back
to the menu. Knight Lore does exactly the same. Watched in the emulator: after
a game over, the scene and the return to the menu, the tune's 79 notes played
before the menu first read its keys.""",

        "Fact:extras:Two or three extra lives, all out of one kind": f"""\
#R$AF3F deals the 36 places at every new game: valves of the four kinds in
turn, but every sixteenth place, by a second count started from the random
number, an extra life instead, whose kind is skipped. So there are
{WORDS[min(extras)]} or {WORDS[max(extras)]} extra lives a game --
{WORDS[max(extras)]} for {extras[max(extras)]} of the 256 values the count can
start from -- and, because they are sixteen places apart, they all take the
place of valves of one kind. With two, that kind has seven valves and the
others nine; with three, it has six, exactly as many as the chambers of its
kind want. Worked out from the code, and watched in the emulator: the first
game after loading dealt extra lives at places 15 and 31 and seven valves of
one kind, nine of each of the others.""",

        "Fact:clock:How long the light years last": f"""\
6000 light years at the start (#R$A647), a light year off every seven turns
(#R$AD66): 42,000 turns. The clock counts turns, not time, and a turn is at
least six units of about 20,000 T-states (#R$A6C0), so in an empty room, with
the robot standing still, 50 turns took {FRAMES_QUIET} frames and the whole
clock would last about {round(42000 * FRAMES_QUIET / 50 / 50 / 60)} minutes;
busier rooms take longer over a turn and stretch the time with it (50 turns
in the start room, {FRAMES_START} frames). Watched in the emulator.""",

        "Fact:tuneplayer:Knight Lore's tune player": f"""\
The tunes are played by Knight Lore's code: #R$B4C5 is its note player, and
the note table at #R$B51D, 61 rows of three bytes, is Knight Lore's to the
byte (compared with Knight Lore's loaded game) -- as it is Pentagram's, a year
later. See <a href="{KNIGHTLORE_REF}/Sounds.html">Knight Lore's sounds</a>.""",
    }


# --------------------------------------------------------------------------
# How the game is put together
# --------------------------------------------------------------------------

def _architecture(memory, labels: dict[int, str], entries: set[int], rooms: dict) -> str:
    rows = []
    for address, label, graphics in update_table(memory, labels):
        name = f"#R${address:04X}({label})" if address in entries else label
        rows.append(f"<tr><td>{name}</td><td>{_ranges(graphics)}</td></tr>")
    updates = ('<table class="kl-table"><tr><th>Routine</th><th>Graphics</th></tr>'
               + "".join(rows) + "</table>")
    fullest = max(room["filled"] for room in rooms.values())
    regions = [
        ("$5B00-$5B87", "#R$5B00", "the variables, over the printer buffer and the system variables; "
                                   "Knight Lore's layout, 160 bytes lower, as far as $5B33"),
        ("$5B88-$6287", "#R$5B88", "56 object records of 32 bytes: the robot's legs and top, two for "
                                   "what lies in the room from the places, and 52 for the room"),
        ("$6300-$6307", "#R$6300", "the entry: DI, the stack at $F100, and a jump to #R$A631"),
        ("$6308-$645F", "#R$6308", "the font: digits and capitals"),
        ("$6460-$73C7", "#R$6469", f"the three room sizes, then the room directory: "
                                   f"{len(rooms)} rooms on a 16 by 16 grid"),
        ("$73C8-$76E2", "#R$73C8", "the object templates and their table, the backgrounds and theirs "
                                   "(#R$7519)"),
        ("$76E3-$7826", "#R$76E3", "the 36 places a valve or an extra life lies"),
        ("$7827-$792E", "#R$7827", "the graphic table: a word per graphic number, the sprite it draws"),
        ("$792F-$A630", "#R$792F", "the sprites, end to end"),
        ("$A631-$D1EA", "#R$A631", "the code, with its tables among it -- the update-routine table "
                                   "(#R$A7EA), the notes and tunes, the texts, the start records "
                                   "(#R$CA1D)"),
        ("$D1EB-$D1FF", "#R$D1EB", "Knight Lore's copyright line, unused"),
        ("$D200-$E9FF", "#R$D200", "the screen buffer, bottom row first, every picture drawn in it "
                                   "before it is copied to the screen"),
        ("$EA00-$F0FF", "#R$EA00", "the stack, down from $F100"),
        ("$F100-$FFFF", "#R$F100", "tables built before the menu (#R$CFA7): bits reversed, and each "
                                   "byte shifted by one to seven bits"),
    ]
    region_rows = "".join(f"<tr><td>{link}({span})</td><td>{what}</td></tr>"
                          for span, link, what in regions)
    region_table = ('<table class="kl-table"><tr><th>Addresses</th><th>What</th></tr>'
                    + region_rows + "</table>")
    parts = [
        ("The main loop, the variables, the 32-byte object record, the update table",
         "Knight Lore's; 56 records where Knight Lore has 40, and the stack reset above the "
         "screen buffer for every object"),
        ("The exits: the room number moved by 1 or 16, the doorway's pillars, where he comes in",
         "Knight Lore's, nearly to the instruction; the walk into a room one turn longer"),
        ("The robot's jumping, falling, walking and the exit test in his move",
         "Knight Lore's; his turning is Alien 8's own (below)"),
        ("The places: dealt at a new game, brought into a room, written back",
         "Knight Lore's special objects, with four kinds of valve, and the extra lives dealt "
         "by a count of their own"),
        ("The menu with directional control, the text printer, the border, the rating",
         "Knight Lore's"),
        ("The tune player and its notes; most sound effects",
         f'Knight Lore\'s, the notes to the byte (<a href="{KNIGHTLORE_TOP}/Sounds.html">its '
         "sounds</a>)"),
        ("Movers: shuttling blocks, dropping and collapsing blocks, pushables, the thing that "
         "drops from the ceiling", "Knight Lore's update routines with Alien 8's graphic numbers"),
        ("Drawing: projection, sprites turned in place, masking through the shift tables, "
         "wiping only what moved",
         f'Knight Lore\'s reworked, and carried on into Pentagram instruction for instruction '
         f'(<a href="{PENTAGRAM_TOP}/Drawing.html">Pentagram\'s drawing</a>)'),
        ("The depth sort",
         f'Knight Lore\'s 27-case table (<a href="{KNIGHTLORE_TOP}/DepthSort.html">depth '
         "sorting</a>), in the code Pentagram kept; Knight Lore's destruction of a thing that "
         'shares space, kept for the valves (<a href="reference/bugs.html#valves">a bug</a>)'),
        ("Collision: Z, then U, then V, a unit at a time, harm passed both ways",
         f'Knight Lore\'s (<a href="{KNIGHTLORE_TOP}/Collision.html">collision</a>), with a '
         "lander's Z step passed to what it lands on, which carries the robot on conveyors and "
         "lifts -- as Pentagram does later"),
        ("The room builder", "the code Pentagram's builder is, with its placement nudge live "
                             "(Pentagram's never runs)"),
        ("Reading the controls", "much as Pentagram's reader, over Knight Lore's keyboard routine"),
        ("The turning robot: an in-between view for two turns",
         'Alien 8\'s own (<a href="Movement.html">how the robot moves</a>)'),
        ("Valves, sockets, the 24 chambers, the summary's counts, the arrival",
         'Alien 8\'s own (<a href="Chambers.html">the chambers</a>)'),
        ("The light-years clock, the remote-controlled robots, the fragile things, the "
         "leapers, the mice, the two-part creatures, conveyors and lifts",
         'Alien 8\'s own (<a href="Station.html">the station</a>)'),
        ("The scenes after a game: the robot re-programmed, or oiled", "Alien 8's own"),
    ]
    part_rows = "".join(f"<tr><td>{what}</td><td>{whose}</td></tr>" for what, whose in parts)
    part_table = ('<table class="kl-table"><tr><th>Part</th><th>Whose</th></tr>'
                  + part_rows + "</table>")
    return "\n".join([
        '<div class="kl-list">',
        "<p>Alien 8 is Knight Lore's engine carrying a new game, a year after Knight Lore and a "
        "year before Pentagram. Much is Knight Lore's, sometimes to the instruction: the main "
        "loop, the object record, the exits, the special objects that became the valves, the "
        "menu and the tune player. Much of the rest was reworked here -- the drawing, the depth "
        "sort's code, the collision code, the room builder, the control reader -- and those are "
        "the parts Pentagram took over nearly unchanged. What is Alien 8's alone is the game: "
        "the valves and the chambers, the clock, the remote-controlled robots, the turning "
        "robot, the scenes after a game. This page is the map of the whole: where things are, "
        "what runs when, and which parts come from where. Knight Lore's "
        f'<a href="{KNIGHTLORE_TOP}/Architecture.html">own page</a> describes the engine as it '
        "was.</p>",

        "<h3>Memory</h3>",
        "<p>The tape's one block of code and data loads at $62FD and runs to the very top of "
        "memory; the loader enters it three bytes in, at $6300. Below it, over the system "
        "variables and the BASIC loader, the game keeps its variables and its object records, "
        "cleared before use. The block holds the level data and the sprites first, then the "
        "code, then -- in the part of it that is space, not game -- the screen buffer every "
        "picture is drawn into, the stack, and tables built at the start; the tape carries the "
        "mastering machine's leftovers there. The ROM is never called, since the game reads "
        "the keyboard and makes its sounds itself (its bytes are read only as noise), and "
        "interrupts are never enabled: there is no EI in the game, and the pause is a busy "
        "wait.</p>",
        region_table,

        "<h3>A game, a life, a room, a turn</h3>",
        "<p>#R$A647 is four loops, one inside another. A game: the variables and records "
        "cleared, the drawing tables built, five lives and 6000 light years, the menu (#R$BA7E), "
        "the start tune, the start records filled with one of four start rooms (#R$CA6D), the "
        "valves and extra lives dealt to their places (#R$AF3F), and every room's colour put "
        "back (#R$CAD2). A life: #R$CA07 copies the start records over the robot's two and "
        "takes a life, and with none left it is the game over (#R$B761). A room: #R$CAA2 files "
        "the valves of the room he left back in their places, builds the room into the object "
        "records (#R$CCA7), brings in what lies there from the places (#R$AE99), puts him in "
        "the doorway he came by (#R$CC01), and sets the drop latch in an even-numbered room. "
        "A turn: every one of the 56 records has its update routine run, and at the end of the "
        "turn (#R$A6C0) the turn is counted, what changed is listed and drawn in depth order "
        "(#R$C71C, #R$CEAB), the turn is padded out, the clock runs (#R$AD66), and the pause "
        "key is read.</p>",
        "<p>Walking through a doorway jumps straight back to the room loop, dropping two return "
        "addresses from the stack by hand, after copying the robot into the start records "
        "(#R$C3B7), so a life starts where he last came in. A death is noticed at the end of a "
        "turn, when both of his records have emptied at the end of the sparkle, and goes back "
        "to the life loop. The game ends three ways -- the last life, the clock, the "
        "twenty-fourth chamber -- all at #R$B761, which shows the summary and then sets "
        "GAME_OVER and runs the scene after the game in the same main loop, with no clock and "
        "no controls, until one of the scene's own routines goes back to the menu.</p>",

        "<h3>The update routines</h3>",
        "<p>An object record's first byte is its graphic number, and that number is both what "
        "is drawn (through the graphic table, #R$7827) and what runs: #R$A7EA has a word per "
        "graphic, the routine the main loop jumps to with IX on the record and the address of "
        "#R$A6C0 on the stack. So an object animates, or changes its behaviour, by changing its "
        "own first byte: a valve becomes a seated valve four graphics on, the robot's legs "
        "become the in-between views as he turns and graphic 48, the sparkle, as he dies, and "
        "anything gone becomes graphic 1, which the drawing code empties. The table, read from "
        f"the snapshot, routine by routine ({UPDATE_COUNT} words, graphics 0 to "
        f"{UPDATE_COUNT - 1}; graphic {PANEL_ICON} has a sprite but no routine, since only the "
        "panel draws it):</p>",
        updates,
        "<p>Most routines start by setting their own drawing nudge and end by moving through "
        "the collision code and, if anything moved, marking the object and what it overlaps to "
        "be drawn again (#R$BFAB). Scenery that never changes has #R$A8F0, a RET.</p>",

        "<h3>Speed</h3>",
        "<p>Every turn visits all 56 records, empty or not, and then #R$A6C0 waits six units of "
        "about 20,000 T-states less the drawing the turn has done, so a quiet room does not run "
        "faster than a moderately busy one; a room with six units of drawing or more runs as "
        "fast as it can. Even an empty room, with the robot standing still, does five units of "
        f"drawing a turn, so the wait is rarely more than one unit. Watched in the emulator, "
        f"standing still for 50 turns: {FRAMES_QUIET} frames in an empty room, {FRAMES_START} "
        "in the start room $13. The clock counts turns, so it slows with the game.</p>",

        "<h3>Chance</h3>",
        "<p>SEED starts as the ROM's frame counter when the game is first run, has the last "
        "game's turn count added at every new game and one added every time round the menu's "
        "loop; it picks the start room, and with the refresh register the first kind of valve "
        "dealt. RANDOM is stirred with the refresh register after every object's turn and with "
        "the turn counter and a byte of the ROM at the end of every turn (#R$A6C0), so how long "
        "each update took feeds the next number. It decides where the extra lives go, when a "
        "thing drops from the ceiling or a leaper jumps, and which way a mouse turns.</p>",

        "<h3>What is Knight Lore's, and what is new</h3>",
        part_table,
        f"<p>Knight Lore's 40 records became 56 and the code that walks them followed: the list "
        f"of what to draw holds all of them, which Pentagram, with 54, later got wrong. The "
        f"fullest room fills {fullest} of the 52 room records. There is no day and night, no "
        "transformation and no cauldron; the clock is the time limit instead, and the chambers "
        "the goal.</p>",
        "</div>",
    ])


# --------------------------------------------------------------------------
# build
# --------------------------------------------------------------------------

def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    import build_alien8 as ba

    snapshot = Path(snapshot)
    skool = snapshot.with_name("alien8.skool")
    entries, instructions, labels = read_listing(skool)
    for address, expected in EXPECTED_INSTRUCTIONS.items():
        found = instructions.get(address, "")
        if found != expected:
            raise RuntimeError(f"alien8_reference: ${address:04X} is '{found}', "
                               f"not {expected}: the pokes and bugs need checking")
    if SPARE_CODE not in entries:
        raise RuntimeError(f"alien8_reference: ${SPARE_CODE:04X} is no longer an entry of "
                           f"its own: check that nothing reaches it before poking it")

    memory = ba.game_memory(snapshot)
    rooms = room_contents(memory)
    fullest = max(((room["filled"], number) for number, room in rooms.items()))
    extras = extra_life_counts()
    icon = graphic_131(memory)
    log("  reference: the panel with nine and ten lives...")
    drawn = draw_lives(snapshot, Path(html_dir) / IMAGES)
    log(f"  reference: drew {drawn}; bugs, pokes, facts, architecture")

    fix = linker(entries)
    sections = {"Architecture": fix(_architecture(memory, labels, entries, rooms))}
    for name, body in (list(_bugs((fullest[1], fullest[0]), drawn).items())
                       + list(_pokes().items())
                       + list(_facts(memory, rooms, extras, icon).items())):
        sections[name] = fix(body)
    for name, body in sections.items():
        for line in body.splitlines():
            if line.startswith((";", "[")):
                raise RuntimeError(f"alien8_reference: {name} has a line starting "
                                   f"with ; or [: {line}")
    return sections
