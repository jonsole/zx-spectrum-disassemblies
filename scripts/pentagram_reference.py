"""Pentagram's reference pages: how the game is put together, its bugs, its
pokes and facts worth knowing.

build() returns SkoolKit's own Bug, Poke and Fact sections -- [Bug:x:Title],
[Poke:x:Title], [Fact:x:Title] -- and the body of the Architecture page, for
the lead to place. Provenance is a box page in pentagram.ref and is not
written here.

The prose is written from the code and from checks made in the emulator.
Every poke was tried live against the same trial without it, and says what
that trial gave; every bug and fact says whether it was read from the code,
run in SkoolKit's simulator or watched in the emulator. The live checks were
made on a private zx_server loaded with pentagram.z80, driven by breakpoints
at the main loop (MAIN_LOOP, $AFDA, once a turn) from the first turn of the
first game, as notes/pentagram/driving.md describes. Where a trial was
staged by writing the game's state -- a room entered by the game's own
restart, a quest record moved, a life taken away -- the text says so.

Nothing here quotes the game: addresses, instructions, the pokes' own bytes
and prose. The tables are worked out from the snapshot at build time -- the
fullest rooms, the doorway links, the points each thing from the sky is
worth, the update-routine table -- and the one picture, the game-over screen
of a game lost in its first room, is drawn by the game's own code in
SkoolKit's simulator into the HTML directory. build() also reads the listing
to check that each instruction a poke changes is still the one the poke was
written for, and to keep #R links only where they name an entry.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

# --------------------------------------------------------------------------
# What the pokes change, and what the listing must still say there
# --------------------------------------------------------------------------

LIVES_DEC = 0xC2FD          # RESTART_PLAYER: DEC (HL), a life fewer
KILLED_TEST = 0xC443        # PLAYER_LEGS: BIT 6,(IX+$0D), killed?
KILLED_JUMP = 0xC447        # PLAYER_LEGS: JR Z past the death
WELL_COUNT = 0xCFE7         # WELL: CP $20, the 32nd touching turn
SKY_DROP = 0xCBAB           # SKY_DROP: its first instruction
START_PICK = 0xC2DC         # CHOOSE_START: AND $03, one of four rooms
PACING = 0xB04A             # OBJECT_DONE: ADD A,$06, six units less the work
READ_KEYS = 0xB952          # READ_KEYS: OUT ($FD),A
FIRST_BOLT = 0xCFBD         # BOLT_TOUCHING: CALL $C21E, past the puff test

EXPECTED_INSTRUCTIONS = {
    LIVES_DEC: "DEC (HL)", KILLED_TEST: "BIT 6,(IX+$0D)", KILLED_JUMP: "JR Z,$C450",
    WELL_COUNT: "CP $20", SKY_DROP: "LD A,($A742)", START_PICK: "AND $03",
    PACING: "ADD A,$06", READ_KEYS: "OUT ($FD),A", FIRST_BOLT: "CALL $C21E",
}

# Opcodes and operands the pokes write, named for what they are.
NOP, JR, RET = 0x00, 0x18, 0xC9
RES_6 = 0xB6                # the fourth byte of RES 6,(IX+d), where BIT 6 has $76
HIT_TEST_LOW = 0x16         # the low byte of HIT_TEST, $C216

# Memory the tables read at build time.
UPDATES = 0xAE2F            # a word per graphic: its update routine
GRAPHIC_COUNT = 172
DROP_GRAPHICS = 0xCC09      # the eight things that can fall
START_ROOMS = 0xC2E8
ROOM_RECORDS = 48           # object records for a room's contents
DRAW_LIST_BYTES = 48        # DRAW_LIST, $B55A
PLAYER_RECORDS = 2
AFTER_GAME = 0xAF93         # where GAME_OVER goes back to the menu, screen still up
PERCENT = 0xA74D

IMAGES = "images/reference"
WORDS = ["none", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
KNIGHTLORE = "../knightlore"               # from a top-level page (Architecture)
KNIGHTLORE_FROM_REFERENCE = "../../knightlore"   # from Bugs, Pokes, Facts in reference/


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


# --------------------------------------------------------------------------
# What is read from the game at build time
# --------------------------------------------------------------------------

def _scenery_pieces(memory, template: int) -> int:
    """Records a scenery template fills: 8-byte pieces until one starts
    with zero (#R$C92C's piece loop)."""
    import pentagram_data as pd
    address = _word(memory, pd.SCENERY_TABLE + 2 * template)
    count = 0
    while True:
        count += 1
        address += 8
        if memory[address] == 0:
            return count


def room_fill(memory) -> list[tuple[int, int]]:
    """(room, records the builder fills) for every room, fullest first:
    each scenery piece and each placed object takes a record."""
    import pentagram_data as pd
    fill = []
    for record in pd.room_records(memory):
        count = sum(_scenery_pieces(memory, template) for _, template, _ in record["scenery"])
        count += sum(len(positions) for _, _, _, positions in record["groups"])
        fill.append((record["number"], count))
    fill.sort(key=lambda item: (-item[1], item[0]))
    return fill


def doorway_links(memory) -> dict:
    """The doorways, read from the room data: a doorway is a scenery entry
    whose template is an arch (graphics 6-9), and its second byte is the
    room it leads to."""
    import pentagram_data as pd
    arches = set()
    for template in range(pd.SCENERY_COUNT):
        address = _word(memory, pd.SCENERY_TABLE + 2 * template)
        if address != pd.SCENERY_TABLE and 6 <= memory[address] <= 9:
            arches.add(template)
    records = pd.room_records(memory)
    ends = []
    for record in records:
        for _, template, destination in record["scenery"]:
            if template in arches:
                ends.append((record["number"], destination))
    pairs = set(ends)
    links = {tuple(sorted(pair)) for pair in pairs}
    one_way = sorted((a, b) for a, b in pairs if (b, a) not in pairs)
    neighbours = sum(1 for a, b in links if abs(a - b) == 1)
    per_room = {}
    for room, _ in ends:
        per_room[room] = per_room.get(room, 0) + 1
    numbers = [record["number"] for record in records]
    return {"rooms": len(records), "doorways": len(ends), "links": len(links),
            "one_way": one_way, "neighbours": neighbours,
            "dead_ends": sorted(r for r, n in per_room.items() if n == 1),
            "four": sorted(r for r, n in per_room.items() if n == 4),
            "far": sorted((abs(a - b), a, b) for a, b in links)[-3:],
            "unused": sorted(set(range(max(numbers) + 1)) - set(numbers))}


def shot_points(graphic: int) -> int:
    """What #R$C264 adds for a thing of this graphic: B hundreds from the
    graphic rotated left three times, C tens and units from it rotated left
    twice, as BCD."""
    rotate = lambda value, n: ((value << n) | (value >> (8 - n))) & 0xFF  # noqa: E731
    tens_units = rotate(graphic, 2) & 0x77
    hundreds = rotate(graphic, 3) & 0x07
    return hundreds * 100 + (tens_units >> 4) * 10 + (tens_units & 0x0F)


def update_table(memory, labels: dict[int, str]) -> list[tuple[int, str, list[int]]]:
    """(routine, its label, the graphics that use it), in address order."""
    users: dict[int, list[int]] = {}
    for graphic in range(GRAPHIC_COUNT):
        users.setdefault(_word(memory, UPDATES + 2 * graphic), []).append(graphic)
    return [(address, labels.get(address, f"${address:04X}"), graphics)
            for address, graphics in sorted(users.items())]


def draw_game_over(snapshot: Path, out_dir: Path) -> int:
    """The game-over screen of a first game lost in its first room.

    A game is started from the menu as the build's sessions start one, and
    at its first turn the lives are set to none and the player is killed
    (the killed bit of his +$0D). The game runs its own death, the game
    over, the percentage and the wait, and is stopped where it goes back to
    the menu, with the screen still up. Returns the percentage it printed,
    as a number.
    """
    import build_pentagram as bp
    from skoolkit.components import get_image_writer
    from skoolkit.graphics import Frame, scr_udgs
    from skoolkit.simutils import PC, T

    machine = bp.Machine(snapshot)
    machine.play(bp._start("1"), "reference: a game lost at once")
    bp._game_over(machine.memory)
    simulator = machine.simulator
    simulator.trace(machine.pc, AFTER_GAME, 0,
                    simulator.registers[T] + 120 * bp.TSTATES_PER_SECOND,
                    True, None, None, None, None, None)
    if simulator.registers[PC] != AFTER_GAME:
        raise RuntimeError("pentagram_reference: the game over never went back to the menu")
    memory = simulator.memory
    out_dir.mkdir(parents=True, exist_ok=True)
    with open(out_dir / "gameover.png", "wb") as f:
        get_image_writer().write_image([Frame(scr_udgs(memory, 0, 0, 32, 24), 2)], f)
    hundreds, tens_units = memory[PERCENT], memory[PERCENT + 1]
    return hundreds * 100 + (tens_units >> 4) * 10 + (tens_units & 0x0F)


# --------------------------------------------------------------------------
# The pokes
# --------------------------------------------------------------------------

def _poke_line(*writes) -> str:
    return ": ".join(f"POKE {address},{value}" for address, value in writes)


IMMUNITY = [(KILLED_TEST + 3, RES_6), (KILLED_JUMP, JR)]


def _pokes() -> dict[str, str]:
    return {
        "Poke:lives:Infinite lives": f"""\
#R$C2EC(RESTART_PLAYER) starts every life, the first included: it copies the
player template over his two records and takes a life with DEC (HL) at
${LIVES_DEC:04X}, going to the game over when that leaves less than none.
Make the DEC a NOP and LIVES never moves. The JP M after it still tests the
sign flag, which the code before it leaves clear on both ways in (read). Put
in before a game starts, the panel should show 05 instead of 04 (read, not
tried).
Tested: standing still at the middle of room 6, where two deadly pacers go
back and forth through the spot (the room entered by the game's own restart),
he was killed every 16 turns; with 3 lives the fourth death was the game over,
at turn 63. With the poke he died 75 times in 1200 turns and the panel said 03
throughout.

{_poke_line((LIVES_DEC, NOP))}""",

        "Poke:immunity:Nothing can kill him": f"""\
Whatever kills the player does it the same way: the collision code sets bit 6
of the +$0D of his legs' record (the mover's bit 7, or the obstacle's bit 5,
#R$B742), and the next time his update routine #R$C440 runs it tests that bit
and turns him into the puff. Make the BIT 6 a RES 6 -- one byte, the fourth of
the instruction -- and the JR Z after it a JR, and the mark is wiped and
ignored every turn. His body is out of every collision test already (#R$C5D3),
so nothing else needs doing. Deadly things still bump him, and homers still
chase him.
Tested: the same trial as the lives poke -- room 6, standing between the two
deadly pacers -- four deaths in 63 turns and the game over without it; with
it, 1200 turns, no death, three lives.

{_poke_line(*IMMUNITY)}""",

        "Poke:well:The well gives the bucket at once": f"""\
#R$CFD2(WELL) counts, in its own record, the turns on which one of his bolts
touches it, and makes the bucket on the 32nd -- the CP $20 at ${WELL_COUNT:04X}.
Make that CP 1 and the first touch does it. (The count is otherwise lost each
time he leaves the room: the well's record is built afresh.)
Tested: in room 71, the well's room with no monsters, the player put inside
the ring of hazards facing the well and firing a bolt every five turns: the
bucket came after 7 shots and 35 turns without the poke (see the bugs for
why only 7), after the first shot and 5 turns with it.

{_poke_line((WELL_COUNT + 1, 1))}""",

        "Poke:sky:Nothing falls from the sky": f"""\
#R$CBAB(SKY_DROP) runs at the top of every turn and is the only thing that
puts a homer, a sky roamer or a sky walker into the two records kept for
them. A RET as its first instruction, and nothing ever falls; the things a
room starts with are not affected.
Tested: standing in room 30, which is empty and allows drops, with the
immunity poke in both trials so that nothing restarted the room: without this
poke three things fell in 1000 turns, 80 turns apart, the first about 80
turns after he arrived; after the third both records held homers, which do
not leave, and nothing more could fall. With it, nothing fell.

{_poke_line((SKY_DROP, RET))}""",

        "Poke:start:Always start in room 51": f"""\
#R$C2CE(CHOOSE_START) takes RANDOM AND 3 as an index into the four start rooms
at #R$C2E8. Make the AND $03 at ${START_PICK:04X} an AND 0 and every game starts
in the first of them, room 51.
Tested: eight games started, each after a game over reached after a different
number of turns (5 to 40): without the poke they began in rooms 92 and 12,
with it all eight began in 51. The collectables were put out exactly as
without it, since #R$D16F(NEW_QUEST) reads the same random number.

{_poke_line((START_PICK + 1, 0))}""",

        "Poke:fast:No waiting between turns": f"""\
At the end of every turn #R$B00C(OBJECT_DONE) waits six units of about 33,000
T-states less the drawing the turn has already done (DRAW_WORK), so a quiet
room runs no faster than a busy one. Make the ADD A,$06 at ${PACING:04X} an ADD
A,0 and it never waits. Busy rooms, where the work is six units or more
already, are unchanged.
Tested: standing still in room 30, 50 turns took 123 frames without the poke
and 76 with it (four units of work a turn, so two of waiting saved); in the
start room, room 92, with nine units of work a turn, 50 turns took 122
frames either way.

{_poke_line((PACING + 1, 0))}""",

        "Poke:128k:Play on a 128K in 128 mode": f"""\
#R$B952(READ_KEYS) sends the half-row it is about to read to port $FD before
reading port $FE, an OUT that does nothing on a 48K Spectrum and pages
memory on a 128K (see the bugs). The IN after it selects the half-rows by
itself, so the OUT can simply go: two NOPs.
Tested on the emulator's 128K machine, from the loaded game put into a 128K
snapshot with the 48 BASIC ROM and bank 0 paged in and paging unlocked, as
the 128's Tape Loader leaves it: without the poke the game crashed to the ROM
on its first turn of play; with it, 300 turns of play, walking out of the
start room into the next, and the paging was as it started. On the 48K the
same 300 turns went exactly as without the poke.

{_poke_line((READ_KEYS, NOP), (READ_KEYS + 1, NOP))}""",
    }


# --------------------------------------------------------------------------
# The bugs
# --------------------------------------------------------------------------

def _bugs(fill: list[tuple[int, int]], percent: int) -> dict[str, str]:
    fullest = fill[0]
    top = ", ".join(f"{room} ({count})" for room, count in fill[:5])
    listed = fullest[1] + PLAYER_RECORDS
    room_free = ROOM_RECORDS - fullest[1]
    fits = DRAW_LIST_BYTES - 1
    too_many = fits + 1 - listed
    return {
        "Bug:droptimer:The drop timer reads one record eighteen times": """\
Things fall from the sky once DROP_TIMER has run out (#R$CBAB), and
#R$CC31(RESET_DROP_TIMER) sets it at the start of every room and after every
drop. By its shape it counts the quest items still to do -- a loop over the
eighteen quest records at #R$D432, adding one for each graphic of 112 to 115
-- and sets four turns for each, plus eight: 8 to 24 turns. But the loop
loads DE with the record length and never adds it to HL. It tests the first
record eighteen times, so the timer is 80 turns while the first quest item
(the one in room 122) is still to do, and 8 once it is done, whatever the
other three are.

Watched in the emulator, reading DROP_TIMER at the first turn in room 30:
80 with the quest items as a new game has them; 8 with only the first staged
as done; 80 with the other three done and not the first; 8 with all four.
Meant: 24, 20, 12 and 8.""",

        "Bug:percent:Nothing done is 56 per cent": f"""\
#R$C6EA(PERCENTAGE) adds up the game-over score -- half the rooms seen, at
most 54, 4 for each quest item done and 6 for each collectable placed -- and
counts it into BCD one at a time with ADD A,1 / DAA in a DJNZ loop. With a
sum of 0 the loop runs 256 times, not none, and 256 in BCD with the hundreds
dropped is 56. The sum is 0 whenever a game ends before a second room has
been seen, since one room halves to nothing. So a player who loses every
life in the room he started in is told he has done more than half the quest.

<div><img src="../{IMAGES}/gameover.png" alt="The game-over screen of a game lost in its first room"/></div>
The picture was drawn by the game's own code in SkoolKit's simulator: a first
game started from the menu, the lives taken away at its first turn and the
player killed; the game's own death, game over and percentage followed, and
printed {percent:02d}. Watched in the emulator too: the same in the start
room gave 56, and with one more room seen, 01.""",

        "Bug:directional:Steering by direction was left half done": """\
Knight Lore let a joystick steer by direction -- push the way you want him to
face -- and Pentagram keeps the code: #R$C4C8 has a directional branch, and
#R$BF66 takes the pick-up control from bit 5 of INPUT instead of bit 4 in that
mode, which bit 3 of CONTROL selects. No menu choice sets bit 3, so it is
reachable only by a poke, and there it is broken three ways. #R$BDF8 never
sets bit 5, so nothing can be picked up or put down. The directional code
takes bit 4 as down, but every joystick reads down as jump (bit 3) and bit 4
is the pick-up keys, so the stick can never turn him to face down and left,
and the pick-up keys turn him instead. And #R$BBD8 would flash the start line
of the menu, where Knight Lore had a line for this mode (read, not seen).

Watched in the emulator, with the cursor joystick chosen and a bucket staged
beside him in room 30: the bottom-row key picked it up with CONTROL 4; with
CONTROL 12 (bit 3 set) the bucket stayed where it was and he turned from
facing 0 to facing 3; the stick's down (6) left him facing 0.""",

        f"Bug:drawlist:Too much in room {fullest[0]} crashes the game": f"""\
#R$B531(LIST_DRAWN) writes the number of every record to be drawn into
#R$B55A(DRAW_LIST), and an $FF after the last. The list has {DRAW_LIST_BYTES}
bytes -- Knight Lore's size, for its forty records -- but Pentagram has 54,
and nothing checks: a list of more than {fits} records runs over the first
bytes of #R$B58A(SORT_AND_DRAW), which follows it. On the first turn in a room
everything is listed, because everything has to be drawn. Counted from the
room data the way #R$C92C reads it, the fullest rooms fill, of their 48
records: {top}. Room {fullest[0]} lists {listed} with the player's legs and
body, {room_free} records to spare -- and the quest things he carries fill
records too when they are put down there. {WORDS[too_many].capitalize()} of them {"is" if too_many == 1 else "are"} enough.

With {fits + 1} listed, the $FF lands on the XOR A that begins SORT_AND_DRAW
and stays there. $FF is RST $38: every turn from then on starts drawing with a
call to the ROM's interrupt routine, which ends with EI, so interrupts come on
in a game written to run without them. The next frame interrupt lands while
the sprite drawer (#R$B3D3) is reading a sprite with the stack pointer
pointed into it, and the return address pushed there overwrites the sprite;
the game goes wrong from there. With more listed, record numbers overwrite the code as well.

Watched in the emulator, with collectables' quest records staged into room
{fullest[0]} (as if carried there and put down) and the room entered by the
game's own restart: with two, {fits} were listed and 300 turns went by
normally; with three, {fits + 1} were listed, SORT_AND_DRAW began with $FF,
the ROM's interrupt routine ran over and over during the first turn --
called at first from $B58B, then from all over the drawing code with the
stack inside sprite data. In that run the game never finished its first turn
in the room; in another, stopped differently, it went four turns with its
variables overwritten -- the turn counter and the room number read as
nonsense -- and hung. With five, 50 were listed and it ran six turns before
it hung.""",

        "Bug:wellbolts:The well counts one bolt's puff and not the other's": f"""\
#R$CFB2(BOLT_TOUCHING) asks whether either of his two bolts is touching the
well, with #R$C216(HIT_TEST), which ignores a puff -- graphics 64 to 71, what a
bolt turns into when it hits something. The second bolt goes in at the top,
but the first goes in at HIT_TEST_Z, past the test for a puff. So a bolt fired
from the first record counts for the turn it touches the well and then for
each of the eight turns its puff hangs there; one from the second record
counts once. #R$CFD2(WELL) wants 32.

Watched in the emulator, logging the well's count at the instruction that
adds to it, in room 71 with a shot every five turns: 32 counts in 35 turns,
from 7 shots, all but a few of them made by the first record's bolt or its
puff. With the first record sent through the puff test like the second
(below), the same shooting took 32 shots and 160 turns, one count a shot.
Which of the two was meant is not known; the difference is only that they are
not the same.

{_poke_line((FIRST_BOLT + 1, HIT_TEST_LOW))}""",

        "Bug:128k:A stray OUT pages a 128K's memory": f"""\
#R$B952(READ_KEYS) does OUT ($FD),A before IN A,($FE), with the half-rows to
read in A. OUT (n),A puts A on the top half of the address bus, so the port
is A * 256 + $FD. A 48K ignores it. A 128K takes any port with bits 15 and 1
clear as its paging port, $7FFD: every half-row value with bit 7 clear is a
paging write. The menu tune's "any key" test (#R$D69C) reads with A = 0,
which pages the 128's editor ROM in and does no harm, since the game never
calls the ROM. But in play the keyboard reads SPACE's half-row as $7F, and
the pause test (#R$B4E0) reads $7E every turn, whatever the controls: that
puts RAM bank 7 or 6 at $C000, where most of the code and the screen buffer
are, and locks the paging. The game cannot survive its first turn.

Watched in the emulator's 128K, from the loaded game put into a 128K snapshot
with the 48 BASIC ROM and bank 0 paged in, as the 128's Tape Loader leaves
it: the menu worked, with ROM 0 paged in by the tune's key test; at the first
turn of play READ_KEYS was called with $7F from the keyboard reader, the
paging port became $7F, locked, and the machine ended in the ROM, reset.
So on a 128K the game must be run in 48 mode. Knight Lore's
<a href="{KNIGHTLORE_FROM_REFERENCE}/asm/46583.html">keyboard routine</a> has the same OUT,
and its callers pass $7E too; it was not tried on a 128K. The poke that
removes the OUT is with the pokes.""",

        "Bug:allfour:The last quest item's link is bent": """\
When the fourth quest item is done, #R$D13A(ALL_FOUR_DONE) walks the quest
records setting bit 4 of each pentagram piece's flags, and with each piece it
also sets bit 0 of +$11 of IX -- the quest item that called it. +$10 and +$11
are that object's link to its own quest record, so the link now points 256
bytes further on. Nothing follows a quest item's link -- only a carried
thing's link is used, by #R$BF79, and a quest item cannot be carried -- and
the record is matched by graphic when he leaves the room (#R$B115), so it
does no harm. What the SET was meant to do is not known.

Watched in the emulator, with three quest items staged as done and the
bucket staged as carried into room 122 and put down: it rose, flew to the
stone and was used up in 58 turns; the stone became graphic 116, QUEST_DONE
went to 4, the lives from 4 to 5, PENTAGRAM_ON was set, and the stone's link
went from $D432 to $D532.""",

        "Bug:lives:Lives are added without BCD": """\
LIVES is printed as two BCD digits (#R$C29A) and a quest item adds one with a
plain INC (#R$CF68); #R$C2EC takes one with a plain DEC. Past 9 the INC would
make $0A, not $10. It never happens: a game starts with five, the first
life takes one, and there are only four quest items, so a player who never
dies ends with eight. Read from the code; the one extra life was watched (see
the bug above).""",
    }


# --------------------------------------------------------------------------
# The facts
# --------------------------------------------------------------------------

def _facts(memory, links: dict, labels: dict[int, str]) -> dict[str, str]:
    drops = [memory[DROP_GRAPHICS + i] for i in range(8)]
    kinds = []
    for first in dict.fromkeys(drops):
        routine = _word(memory, UPDATES + 2 * first)
        family = [g for g in range(first, min(first + 4, GRAPHIC_COUNT))
                  if _word(memory, UPDATES + 2 * g) == routine]
        points = ", ".join(str(shot_points(g)) for g in family)
        name = labels.get(routine, f"${routine:04X}")
        kinds.append(f"<tr><td>{_ranges(family)}</td><td>{name}</td>"
                     f"<td>{drops.count(first)} in 8</td><td>{points}</td></tr>")
    table = ('<table class="kl-table"><tr><th>Graphics</th><th>Update routine</th>'
             "<th>Chance of falling</th><th>Points, by frame</th></tr>"
             + "".join(kinds) + "</table>")
    starts = ", ".join(str(memory[START_ROOMS + i]) for i in range(4))
    far = ", ".join(f"{a} and {b}" for _, a, b in reversed(links["far"]))
    one_way = ("none of them one-way" if not links["one_way"] else
               "one-way: " + ", ".join(f"{a} to {b}" for a, b in links["one_way"]))
    return {
        "Fact:tunes:Knight Lore's tune player": f"""\
The tunes are played by Knight Lore's code. #R$D6C0(PLAY_NOTE) is Knight Lore's
note player instruction for instruction, the two addresses in it apart (the
note table's and a helper's), and #R$D718(NOTES), 61 rows of three bytes, is
Knight Lore's table to the byte, with the same odd row 18 that repeats row 17's
pitch. Compared byte for byte with Knight Lore's loaded game. The sound effects
in play are Pentagram's own: short beeps, one note a turn, from #R$D5F2. See
<a href="{KNIGHTLORE_FROM_REFERENCE}/Sounds.html">Knight Lore's sounds</a>.""",

        "Fact:points:Points are made from a graphic's bits": f"""\
Shooting down a thing from the sky is the only way to score, and the points
are not looked up: #R$C264(SHOOT_DOWN), the only caller of #R$BB29, makes them from the thing's graphic
number -- the hundreds from bits 5-7, the tens from bits 2-4 and the units
from bits 6, 7 and 0 -- so no digit can pass 7 and the sum stays good BCD. A
thing's graphic changes as it flies, so what it is worth depends on the frame
it is hit in. The eight things #R$CBAB can drop (#R$CC09), worked out from
the snapshot:

{table}
Watched in the emulator: in room 30, firing at what fell, six hits scored
241 (graphic 80), 512 (166), 516 (167), 502 (160), 241 (80) and 526 (171),
each as the formula says.""",

        "Fact:arches:A doorway carries its destination": f"""\
Knight Lore works out the next room from the grid: plus or minus one, or
sixteen. Pentagram's rooms are not on a grid. Each arch in a room's scenery
list is two bytes, the template and the room it leads to, and #R$C92C copies
that second byte into +$08 of every piece of the arch; the arch's first pillar
(#R$C7AD) moves the player there. Read from the room data: {links['rooms']}
rooms with {links['doorways']} doorways, which pair up into {links['links']}
links, {one_way}; only {links['neighbours']} of the links join rooms whose
numbers differ by one, and the farthest apart join rooms {far}. Room 0 is
reached by doorways whose destination byte is 0 -- the value every piece of
scenery that is not a doorway has too. {len(links['dead_ends'])} rooms have one
doorway only, {len(links['four'])} have four, and the numbers
{_ranges(links['unused'])} are not rooms at all.""",

        "Fact:doorway:A life starts again at the last doorway": """\
When he walks out through an arch, #R$C843 copies both his records into the
player template at #R$C3FF, still marked with the wall he left by, and when a
life is lost #R$C2EC copies the template back and the room is built again: he
comes back in through the doorway he entered by, facing the way he was
walking, and walks in again. Only a new game resets the template
(#R$C2CE). Watched in the emulator: walking out of room 92 into room 91 he
arrived at U 195; killed there a few steps in, he started again at U 195,
V 128.""",

        "Fact:firstgame:Chance is drawn before the menu": f"""\
#R$AF87 stirs the refresh register R into RANDOM once, just before the menu,
and nothing touches RANDOM again until the game has chosen where the five
collectables start (#R$D16F) and which of rooms {starts} it starts in
(#R$C2CE). The time spent on the menu makes no difference, so the first game
after loading is decided by R at the moment the game began to run -- in an
emulator loading the same file the same way, always the same game. Watched
in the emulator: games started after 1, 2, 3, 5 and 8 passes of the menu all
began in room 92, with the collectables in rooms 16, 129, 18, 146 and 27;
the same game put into a 128K snapshot, which has R at 0, began in room 100.
Later games are stirred by the play before them (every object's turn adds R
and a byte of the ROM, #R$B00C): forty games started in the simulator after
games over of varying length began in all four rooms.""",

        "Fact:miremare:The win names the next game": """\
The fifth collectable put in its place on the pentagram ends the game
(#R$CD16), and #R$C302(WON) congratulates the player and tells him his
adventure continues in Mire Mare -- the next Sabreman game, announced and
never released. Then the game-over screen follows as after any game, with the
percentage (#R$C6EA).""",

        "Fact:unused:Left in, never used": """\
Code and data that nothing reaches, each checked by searching the loaded game
for its address and by the build's play sessions: a blip pitched by the turn
counter with 80 bytes of pitches (#R$D56C), two beeps pitched by a graphic
number (#R$D665), a whole tune (#R$D824), effects 2 and 3 of the four the
sound sequencer has (#R$D60D), a routine that would reverse a homer's height
speed (#R$CCFB), code that would set the room builder's position nudge
(#R$CA7C, so the nudge is always 0), three drawing offsets (#R$C750), an
update routine that makes a thing deadly (#R$C28B), Knight Lore's printer for
strings with a colour byte (#R$BC7A), two lone RETs (#R$C4A2, #R$C74A), and
two sprites no graphic number reaches (#R$8547, #R$8A17). The main loop saves
the stack pointer every turn in MAIN_SP and never reads it; the menu loads a
variable into HL and at once overwrites it. The update-routine table gives
graphic 60, a piece of the panel, the bolts' routine (#R$C1C5).""",

        "Fact:loading:The loading screen ignores its own header": """\
The tape's second block is the loading screen, and its header says CODE
24576,6912 -- $6000, in the middle of where the game will load. The BASIC
loader reads it with LOAD ""SCREEN$, which puts 6912 bytes at the screen
whatever the header says, and then loads the game over $5E00-$D89D. Read
from the tape and confirmed by the simulated load that builds this
disassembly.""",

        "Fact:extralife:Each quest item gives a life": """\
When the bucket reaches a quest item, #R$CF68(QUEST_ITEM) adds a life as well
as counting the item done, and redraws the lives at once (#R$C29A). With five
lives at the start there are nine in a game. Watched in the emulator: the
fourth item done took the lives from 4 to 5.""",
    }


# --------------------------------------------------------------------------
# How the game is put together
# --------------------------------------------------------------------------

def _architecture(memory, labels: dict[int, str], entries: set[int], fill) -> str:
    import pentagram_data as pd

    rooms = pd.room_records(memory)
    rows = []
    for address, label, graphics in update_table(memory, labels):
        name = f"#R${address:04X}({label})" if address in entries else label
        rows.append(f"<tr><td>{name}</td><td>{_ranges(graphics)}</td></tr>")
    updates = ('<table class="kl-table"><tr><th>Routine</th><th>Graphics</th></tr>'
               + "".join(rows) + "</table>")
    regions = [
        ("$5E00-$5E06", "#R$5E00", "the entry: DI, the stack below $5E00, and a jump to #R$AF87"),
        ("$5E07-$696C", "#R$5E07", f"the three room sizes, then the room directory (#R$5E10): "
                                   f"{len(rooms)} records, one per room"),
        ("$696D-$6DD6", "#R$696D", "the scenery templates and their table, then the object "
                                   "templates and theirs (#R$6CE5)"),
        ("$6DD7-$6F2E", "#R$6DD7", "the graphic table: a word per graphic number, the sprite it draws"),
        ("$6F2F-$A708", "#R$6F2F", "the sprites, end to end, with the font among them (#R$8355)"),
        ("$A709-$A76E", "#R$A709", "the variables, zero on the tape"),
        ("$A76F-$AE2E", "#R$A76F", "54 object records of 32 bytes: the player's legs and body, "
                                   "two bolts, two things from the sky, and 48 for the room"),
        ("$AE2F-$AF86", "#R$AE2F", "the update-routine table, a word per graphic number"),
        ("$AF87-$D88E", "#R$AF87", "the code, with its small tables among it -- the quest records "
                                   "(#R$D312, copied to #R$D432 for a game), the collectables' "
                                   "places (#R$D1A5) and targets (#R$D562), the notes and the tunes"),
        ("$D88F-$F08E", "#R$D88F", "the screen buffer, bottom row first; its first bytes are the "
                                   "last of the tape block"),
        ("$F100-$FFFF", "#R$F100", "tables the game builds at every start (#R$B29A): bits "
                                   "reversed, and each byte shifted by one to seven bits"),
    ]
    region_rows = "".join(f"<tr><td>{link}({span})</td><td>{what}</td></tr>"
                          for span, link, what in regions)
    region_table = ('<table class="kl-table"><tr><th>Addresses</th><th>What</th></tr>'
                    + region_rows + "</table>")
    mine = [
        ("The main loop and its pacing", "Knight Lore's, with the same wait of six units less "
                                         "the drawing done; the stack is no longer reset for "
                                         "each object"),
        ("Drawing: projection, turning sprites round in place, masking through the shift "
         "tables, wiping only what moved",
         f'Knight Lore\'s (<a href="{KNIGHTLORE}/MovingObjects.html">how a moving object is '
         "drawn</a>), with a clamp at the left edge of the screen added and the draw list "
         'not grown to fit (<a href="reference/bugs.html#drawlist">a bug</a>)'),
        ("The depth sort", f'Knight Lore\'s, with the same 27-entry table (<a href="{KNIGHTLORE}'
                           '/DepthSort.html">depth sorting</a>); boxes that intersect are no '
                           "longer a special case"),
        ("Collision: Z, then U, then V, a unit at a time, harm passed both ways",
         f'Knight Lore\'s (<a href="{KNIGHTLORE}/Collision.html">collision</a>), plus conveyors, '
         "a mark on what the player stands on, and carrying for lifts"),
        ("The player: turning, walking, jumping, the legs and the body",
         "Knight Lore's, less the werewolf, the sounds of turning and falling, and the exit test"),
        ("Arches", "Knight Lore's shape, but the arch itself sends him on, to the room in its "
                   "own record"),
        ("Picking up and putting down", "Knight Lore's queue of three, searching all 48 room "
                                        "records rather than Knight Lore's two"),
        ("The menu, the text printer, the border", "Knight Lore's, nearly instruction for "
                                                   "instruction, one menu line shorter"),
        ("The tune player and its notes", "Knight Lore's, to the byte"),
        ("The room directory and its builder", "Pentagram's own: rooms of any number, "
                                               "doorways carrying their destinations"),
        ("The quest records", "Pentagram's own: eighteen things that remember their room and "
                              "place from visit to visit"),
        ("Firing, bolts, scoring", "Pentagram's own; Knight Lore has no weapon"),
        ("Things from the sky, homers", "Pentagram's own"),
        ("The well, the bucket, the pentagram, the collectables", "Pentagram's own"),
        ("Sound effects in play", "Pentagram's own: a note a turn from a short sequence"),
        ("Reading the controls", "Pentagram's own reader; Knight Lore's keyboard routine"),
    ]
    mine_rows = "".join(f"<tr><td>{what}</td><td>{whose}</td></tr>" for what, whose in mine)
    mine_table = ('<table class="kl-table"><tr><th>Part</th><th>Whose</th></tr>'
                  + mine_rows + "</table>")
    return "\n".join([
        '<div class="kl-list">',
        "<p>Pentagram is Knight Lore's engine carrying a new game. The drawing, the depth "
        "sort, the collision code, the player's movement and much of the rest are Knight "
        "Lore's, sometimes to the instruction; the rooms, the quest and everything that "
        "moves or is fired or falls are new. This page is the map of the whole: where things "
        "are, what runs when, and which parts come from where. Knight Lore's "
        f'<a href="{KNIGHTLORE}/Architecture.html">own page</a> describes the engine as it '
        "was.</p>",

        "<h3>Memory</h3>",
        "<p>The tape's one block of code and data loads at $5E00 and runs to $D89D; the "
        "loader enters it at its first byte, with the stack just below. Everything the game "
        "keeps is laid out from there up: the level data and the sprites first, then the "
        "variables and the object records -- all zero on the tape -- and the code. Above the "
        "code are the screen buffer, which every picture is drawn into before it is copied "
        "to the screen, and tables the game builds each time it starts. The system variables "
        "are not used and the ROM is never called -- its bytes are read only as random "
        "numbers -- since the game reads the keyboard and makes its sounds itself; and it "
        "runs with interrupts off, turning them on only while paused.</p>",
        region_table,

        "<h3>A game, a life, a room, a turn</h3>",
        "<p>#R$AF87 is four loops, one inside another. A game: the variables and records "
        "cleared, the drawing tables built, five lives, the menu, the start tune, the quest "
        "records set out afresh with the collectables put in five places chosen at random "
        "(#R$D16F), and one of four start rooms chosen (#R$C2CE). A life: #R$C2EC copies the "
        "player template over his two records and takes a life, and with none left it is the "
        "game over. A room: the quest things of the room he left are filed back in their "
        "records (#R$B115), the room is built into the object records (#R$C6B6), the quest "
        "things that are in it are put in with it (#R$B097), the room is marked as one where "
        "things may or may not fall (#R$CB89), and the drop timer is set (#R$CC31). A turn: "
        "perhaps something falls (#R$CBAB), then every one of the 54 records has its update "
        "routine run, and #R$B00C draws what changed and waits.</p>",
        "<p>Walking through an arch jumps straight back to the room loop, dropping two "
        "return addresses from the stack by hand (#R$C843); a death is noticed at the end of "
        "a turn, when both of his records have emptied, and goes back to the life loop.</p>",

        "<h3>The update routines</h3>",
        "<p>An object record's first byte is its graphic number, and that number is both what "
        "is drawn (through the graphic table, #R$6DD7) and what runs: #R$AE2F has a word per "
        "graphic, the routine the main loop jumps to with IX on the record and the address "
        "of #R$B00C on the stack. So an object animates, or changes its behaviour, by changing "
        "its own first byte: the bolt steps through 151, 150 and 149, a quest item goes up by "
        "four when it is done, anything that dies becomes graphic 64, the puff, and then 1, "
        "which the drawing code empties. The table, read from the snapshot, routine by "
        "routine:</p>",
        updates,
        "<p>Most routines end the same way: set their own drawing offset, move through the "
        "collision code, and if anything moved, mark the object and what it overlaps to be "
        "drawn again (the end of #R$CC4B). Scenery and anything else that never changes has "
        "#R$C43F, a RET.</p>",

        "<h3>Speed</h3>",
        "<p>Every turn does the same work whatever is happening -- all 54 records are visited, "
        "empty or not -- and then #R$B00C waits six units of about 33,000 T-states less the "
        "drawing the turn has done, so that a quiet room does not run faster than a busy one. "
        "A busy room, with six units of drawing or more, runs as fast as it can. Watched in "
        "the emulator, standing still for 50 turns: 123 frames in the empty room 30, with "
        "two units of waiting a turn, and 122 in the cluttered start room, with none.</p>",

        "<h3>Chance</h3>",
        "<p>RANDOM is one byte. It is stirred with the refresh register once before the menu, "
        "and after every object's turn with R, the turn counter and a byte of the ROM that "
        "the turn counter points at (#R$B00C). Since R counts instructions, how long each "
        "update took feeds the next number. The start room, the collectables' places, what "
        "falls and where, and which way a spider turns all come from it.</p>",

        "<h3>What is Knight Lore's, and what is new</h3>",
        mine_table,
        f"<p>The records went from Knight Lore's 40 to 54 and the code that walks them followed, "
        f'but the list of what to draw did not: <a href="reference/bugs.html#drawlist">the '
        f"bugs</a> have what happens when room {fill[0][0]}, the fullest, has a few things "
        "added to it. There is no day and night, no transformation, "
        "no cauldron and no clock.</p>",
        "</div>",
    ])


# --------------------------------------------------------------------------
# build
# --------------------------------------------------------------------------

def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    import build_pentagram as bp

    snapshot = Path(snapshot)
    skool = snapshot.with_name("pentagram.skool")
    entries, instructions, labels = read_listing(skool)
    for address, expected in EXPECTED_INSTRUCTIONS.items():
        found = instructions.get(address, "")
        if found != expected:
            raise RuntimeError(f"pentagram_reference: ${address:04X} is '{found}', "
                               f"not {expected}: the pokes and bugs need checking")

    memory = bp.game_memory(snapshot)
    fill = room_fill(memory)
    links = doorway_links(memory)
    log("  reference: the game over of a game lost in its first room...")
    percent = draw_game_over(snapshot, Path(html_dir) / IMAGES)
    log(f"  reference: it printed {percent} per cent; bugs, pokes, facts, architecture")

    fix = linker(entries)
    sections = {"Architecture": fix(_architecture(memory, labels, entries, fill))}
    for name, body in (list(_bugs(fill, percent).items()) + list(_pokes().items())
                       + list(_facts(memory, links, labels).items())):
        sections[name] = fix(body)
    for name, body in sections.items():
        for line in body.splitlines():
            if line.startswith((";", "[")):
                raise RuntimeError(f"pentagram_reference: {name} has a line starting "
                                   f"with ; or [: {line}")
    return sections
