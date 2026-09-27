"""Atic Atac's reference pages: its bugs, its pokes and facts worth knowing.

build() returns SkoolKit's own Bug, Poke and Fact sections -- [Bug:x:Title],
[Poke:x:Title], [Fact:x:Title] -- for the lead to place beside the ones
already in aticatac.ref (CONGRATULATIONT, its poke, and seven facts, which
these do not repeat). The prose is written from the code and from checks
made in the emulator. Every poke was tried live against the same trial
without it, and says what that trial gave; every bug and fact says whether
it was read from the code or watched. The checks were made on a private
zx_server loaded with aticatac.z80, driven by breakpoints at FRAME_TICK and
MAIN_LOOP from the first frame in play of the first game, as the knight
(notes/aticatac/driving.md says how). Where a trial was staged by writing
the game's state -- a monster put on the player, an object given, the
player moved to another room -- the text says so.

Nothing here quotes the game: addresses, instructions, the pokes' own bytes
and prose. The room numbers in the tables are read from the snapshot at
build time, and the one picture -- the devil's and Frankenstein's caves the
moment the player arrives -- is drawn by the game's own code in SkoolKit's
simulator into the HTML directory, like the other generated pages. build()
also reads the listing to check that each instruction a poke changes is
still the one the poke was written for, and to keep #R links only where
they name an entry.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

# --------------------------------------------------------------------------
# What the pokes change, and what the listing must still say there
# --------------------------------------------------------------------------

HUNGER_GATE = 0x8E80       # PLAYER_TICK: JR NZ past the life-force drain unless TICKS AND 15 is 0
TOUCH_SUB = 0x8EDA         # LOSE_FOOD_THIRTY_TWO: SUB $20
SPAWNER = 0x83EA           # SPAWN_MONSTER_INTO_ROOM: its first instruction
EIGHT_SUB = 0x8A21         # LOSE_FOOD_EIGHT: SUB $08
SIXTEEN_SUB = 0x8A18       # LOSE_FOOD_SIXTEEN: SUB $10
MUSHROOM_DEC = 0x98B4      # MUSHROOM_DRAIN: DEC A
LIVES_DEC = 0x8EA7         # LOSE_LIFE: DEC A, one life fewer
KEY_TEST = 0x9233          # DOOR_NEEDS_KEY: JP NZ to "draw it shut" when the key is not carried
ACG_TEST = 0x961B          # ACG_DOOR: LD HL,$5E32, the start of the test for the three pieces
PASSAGE_TEST = 0x9435      # the character doors' JR NC, "not this character"
REGROW_WRAP = 0x995B       # REGROW_FOOD: LD HL,$EB58, where the cursor goes back to
ACG_OPEN = 0x9632          # ACG_DOOR's "carrying all three" branch

EXPECTED_INSTRUCTIONS = {
    HUNGER_GATE: "JR NZ,$8E8E", TOUCH_SUB: "SUB $20", SPAWNER: "LD A,($5E26)",
    EIGHT_SUB: "SUB $08", SIXTEEN_SUB: "SUB $10", MUSHROOM_DEC: "DEC A",
    LIVES_DEC: "DEC A", KEY_TEST: "JP NZ,$923F", ACG_TEST: "LD HL,$5E32",
    PASSAGE_TEST: "JR NC,$943D", REGROW_WRAP: "LD HL,$EB58", ACG_OPEN: "CALL $954D",
}

# Opcodes the pokes write, named for what they are.
NOP, JR, RET, AND_A, JP = 0x00, 0x18, 0xC9, 0xA7, 0xC3

# Memory the facts and bugs read at build time.
FRAMES = 0x5C78                 # the frame counter as the loaded snapshot has it
RANDOM_ROOMS_ONE = 0x990C       # the green key's eight rooms
RANDOM_ROOMS_TWO = 0x9914       # the red key's and the mummy's
RANDOM_ROOMS_THREE = 0x991C     # the cyan key's
KEY_ROOM_SETS = 0x94DD          # eight sets of three rooms for the A.C.G. pieces
YELLOW_KEY = 0x6055             # the yellow key's template record (its room never changes)
FIRST_FOOD = 0x60D5             # the first of the eighty food records in the template
DEVIL_ROOM, FRANK_ROOM = 0x43, 0x55
DEVIL_SLOT, FRANK_SLOT = 0xEEB0, 0xEEC0
MAIN_LOOP = 0x7DC3              # the top of a pass

IMAGES = "images/reference"


# --------------------------------------------------------------------------
# The listing: which addresses are entries (for #R), and each instruction
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


# --------------------------------------------------------------------------
# What is read from the game at build time
# --------------------------------------------------------------------------

def castle_choices(memory) -> dict:
    """The rooms START_GAME can choose, and the choice the loaded snapshot makes."""
    frames = memory[FRAMES] | (memory[FRAMES + 1] << 8)
    rows = []
    for index in range(8):
        rows.append({
            "green": memory[RANDOM_ROOMS_ONE + index],
            "red": memory[RANDOM_ROOMS_TWO + index],
            "pieces": list(memory[KEY_ROOM_SETS + 3 * index:KEY_ROOM_SETS + 3 * index + 3]),
            "cyan": memory[RANDOM_ROOMS_THREE + index],
        })
    return {"frames": frames, "rows": rows, "yellow": memory[YELLOW_KEY + 1],
            "first_food_room": memory[FIRST_FOOD + 1]}


def choices_table(choices: dict, room) -> str:
    """The eight arrangements as an HTML table, with the cyan key's own column."""
    first = choices["frames"] & 7
    first_cyan = (choices["frames"] >> 8) & 7
    lines = ['<table class="data">',
             "<tr><th>FRAMES AND 7</th><th>Green key</th><th>Red key and the mummy</th>"
             "<th>A.C.G. pieces $8C, $8D, $8E</th><th>Cyan key, by FRAMES' middle byte AND 7</th></tr>"]
    for index, row in enumerate(choices["rows"]):
        mark = " (the first game)" if index == first else ""
        cyan_mark = " (the first game, and every game until FRAMES' middle byte moves)" \
            if index == first_cyan else ""
        pieces = ", ".join(room(r) for r in row["pieces"])
        lines.append(f"<tr><td>{index}{mark}</td><td>{room(row['green'])}</td>"
                     f"<td>{room(row['red'])}</td><td>{pieces}</td>"
                     f"<td>{room(row['cyan'])}{cyan_mark}</td></tr>")
    lines.append("</table>")
    return "\n".join(lines)


def draw_caves(snapshot: Path, out_dir: Path) -> list[tuple[int, int, int]]:
    """The devil's and Frankenstein's caves the moment the player walks in.

    A game is started from the title screen as render_rooms starts one
    (new_game_memory), and from that moment -- three seconds on, the player
    still rising -- the player is made the knight standing at the room's
    centre in each cave in turn, and ARRIVE_IN_ROOM runs through the first
    pass of MAIN_LOOP, which draws the room's contents. Returns each monster's
    room, x and y as the picture has them.
    """
    import build_aticatac as ba
    from skoolkit import CSimulator
    from skoolkit.components import get_image_writer
    from skoolkit.graphics import Frame, scr_udgs
    from skoolkit.simulator import Simulator
    from skoolkit.simutils import PC

    _, started = ba.new_game_memory(snapshot)
    out_dir.mkdir(parents=True, exist_ok=True)
    writer = get_image_writer()
    where = []
    for room, slot in ((DEVIL_ROOM, DEVIL_SLOT), (FRANK_ROOM, FRANK_SLOT)):
        machine = (CSimulator or Simulator)(list(started), state={"iff": 1, "im": 1, "tstates": 0})
        machine.set_tracer(ba._key_tracer_class()(machine))
        machine.memory[ba.CURRENT_ROOM] = room
        machine.memory[ba.CURRENT_ROOM - 1] = 0x08      # the knight, in play
        machine.memory[ba.CURRENT_ROOM + 2] = 0x58      # x, y: the room's centre
        machine.memory[ba.CURRENT_ROOM + 3] = 0x68
        machine.registers[24] = ba.STACK
        # ARRIVE_IN_ROOM ends in JP MAIN_LOOP; one instruction on, the run to
        # MAIN_LOOP again is the first pass, which draws what is in the room.
        machine.trace(ba.REDRAW_ROOM, MAIN_LOOP, 0, 10_000_000, True,
                      None, None, None, None, None)
        machine.trace(machine.registers[PC], 0, 1, 0, True, None, None, None, None, None)
        machine.trace(machine.registers[PC], MAIN_LOOP, 0, 20_000_000, True,
                      None, None, None, None, None)
        if machine.registers[PC] != MAIN_LOOP:
            raise RuntimeError("aticatac_reference: the cave never finished its first pass")
        where.append((room, machine.memory[slot + 3], machine.memory[slot + 4]))
        with open(out_dir / ("cave%02X.png" % room), "wb") as f:
            writer.write_image([Frame(scr_udgs(machine.memory, 0, 0, 24, 24), 2)], f)
    return where



# --------------------------------------------------------------------------
# The pokes
# --------------------------------------------------------------------------

def _poke_line(*writes) -> str:
    return ": ".join(f"POKE {address},{value}" for address, value in writes)


HUNGER = [(HUNGER_GATE, JR)]
TOUCHES = [(TOUCH_SUB + 1, 0)]
BIG_FIVE = [(EIGHT_SUB + 1, 0), (SIXTEEN_SUB + 1, 0)]
MUSHROOMS = [(MUSHROOM_DEC, AND_A)]


def _pokes() -> dict[str, str]:
    return {
        "Poke:lifeforce:Infinite life force": f"""\
Five things take the life force down, and each has its own code: hunger in
#R$8E78(PLAYER_TICK), a small creature's touch in #R$8ED7, the four big
hunters' in #R$8A1E, the humpback's in #R$8A15 and a mushroom in #R$98B1.
The line below is the four pokes that follow put together -- no hunger,
harmless creatures, the big five harmless and harmless mushrooms -- and with
all of them the roast never shrinks. Tested: the devil, the humpback and a
mushroom put on the player in the first room, with creatures free to come,
killed him in 37 frames without the pokes; with them the life force read 240
at every one of 600 frames, and three creatures burst on touching him for
465 points.

{_poke_line(*(HUNGER + TOUCHES + BIG_FIVE + MUSHROOMS))}""",

        "Poke:hunger:No hunger": f"""\
The roast runs down on its own in #R$8E78(PLAYER_TICK): on the passes when
TICKS AND 15 is zero, the JR NZ at ${HUNGER_GATE:04X} falls through to a DEC
of the life force. Make it an unconditional JR and the drain is always
skipped. Nothing else is: creatures, the big five and mushrooms still bite.
(The clock on the scroll counts up and costs nothing; it only goes on the
end screen.) Tested: standing still in the first room for 500 frames took
the life force from 240 to 176 without the poke -- 32 to hunger and 32 to
the one creature that reached him -- and to 208 with it, the creature's 32
alone.

{_poke_line(*HUNGER)}""",

        "Poke:creatures:Harmless creatures": f"""\
A small creature that catches the player costs 32 units through
#R$8ED7 and is destroyed for 155 points (#R$85EA). Make its SUB $20 at
${TOUCH_SUB:04X} a SUB 0: the touch still kills the creature and still
scores, but costs nothing, so walking into creatures becomes the easy way to
clear a room. Tested: the same 500 frames standing in the first room left
the life force at 207 with the poke, hunger's share, against 176 without;
one creature reached the player, burst and scored 155 both times.

{_poke_line(*TOUCHES)}""",

        "Poke:nocreatures:No creatures": f"""\
Every small creature comes from #R$83EA, called once a frame while the player
is in play. A RET as its first instruction stops them all: the rooms stay
empty except for the big five, whose records are not spawned. Tested: in the
same 500 frames in the first room, four creatures materialised without the
poke and one reached the player (155 points, 32 units); with it none
appeared, the score stayed 0, and the life force went down only to hunger,
240 to 208.

{_poke_line((SPAWNER, RET))}""",

        "Poke:bigfive:The big five harmless": f"""\
The mummy, Dracula, Frankenstein's monster and the devil cost eight units a
pass in contact through #R$8A1E; the humpback sixteen through #R$8A15. Make
both SUBs subtract nothing (${EIGHT_SUB + 1:04X} and ${SIXTEEN_SUB + 1:04X}
are their operands) and they can stand on the player all day. The spanner
still kills Frankenstein's monster.
Tested: the devil put on top of the player killed him in 49 frames without
the poke; with it he was alive 200 frames later, 240 down to 230 by hunger.
The humpback: dead in 24 frames without, 228 after 200 frames with.

{_poke_line(*BIG_FIVE)}""",

        "Poke:mushrooms:Harmless mushrooms": f"""\
Standing within 12 pixels of a mushroom takes a unit a pass in #R$98B1, and a
mushroom that finds the life force at zero kills (see the bug about one death
costing two lives). Turn its DEC A at ${MUSHROOM_DEC:04X} into AND A: the
value is stored back unchanged, and the zero test after it still sees the
life force as it was. The warning noise still plays. Tested: a mushroom put
under the player took the life force from 240 to 48 in 400 frames without
the poke; with it, 221 -- hunger's share.

{_poke_line(*MUSHROOMS)}""",

        "Poke:lives:Infinite lives": f"""\
#R$8EA0 takes a life with DEC A at ${LIVES_DEC:04X}, after checking for none
left; make it a NOP and LIVES stays at 3. #R$9443, which starts each new
life, treats LIVES = 3 as the first life of the game and skips a redraw, so
with the poke it always skips it; that makes no difference that could be
seen: the play area after each death was compared pixel for pixel with the
unpoked game's, and they were the same. Tested: starving four times in a row
left 2, 1 and 0 lives and then GAME OVER at the fourth death without the
poke; with it, 3 after every death, and a fifth life after the fourth.

{_poke_line((LIVES_DEC, NOP))}""",

        "Poke:keys:Every locked door open": f"""\
A locked door asks #R$9222 each pass whether a key of its colour is carried,
and the JP NZ at ${KEY_TEST:04X} sends it off to be drawn shut when not.
Three NOPs, and every red, green, cyan and yellow door behaves as if its key
were in the inventory: it opens, and once walked through becomes an ordinary
door for the rest of the game, as it would with the key. Tested: walking up
into the first room's cyan door with no key stopped at y $32; with the cyan
key staged in the inventory the player went through in 33 frames; with the
poke and no key, the same 33 frames.

{_poke_line((KEY_TEST, NOP), (KEY_TEST + 1, NOP), (KEY_TEST + 2, NOP))}""",

        "Poke:acgdoor:The A.C.G. door always open": f"""\
#R$961B wants the three pieces of the key in the three inventory slots, in
order. Replace its first instruction with a jump to the "all three" branch at
${ACG_OPEN:04X} and the great door in the first room opens for anyone -- the
game can be won by walking east from the start. Tested: walking right from
the start with nothing carried stopped at x $8E against the shut door;
with the poke the player went through in 28 frames, into room $8E, and the
end screen followed.

{_poke_line((ACG_TEST, JP), (ACG_TEST + 1, ACG_OPEN & 0xFF), (ACG_TEST + 2, ACG_OPEN >> 8))}""",

        "Poke:passages:Every secret passage for every character": f"""\
The clocks are doors for the knight, the bookcases for the wizard and the
barrels for the serf: each handler subtracts its character's first sprite
code from the player's and lets him through if the answer is under 16
(#R$9421 and the two entry points after it). NOP the JR NC at ${PASSAGE_TEST:04X} that
turns everyone else away, and all three kinds work for all three characters.
Tested: the knight, moved to room $0A and walking up into its bookcase,
stopped at y $52 without the poke; with it he went through in 12 frames.

{_poke_line((PASSAGE_TEST, NOP), (PASSAGE_TEST + 1, NOP))}""",
    }


# --------------------------------------------------------------------------
# The bugs
# --------------------------------------------------------------------------

def _bugs(choices: dict, room, caves: list) -> dict[str, str]:
    frames = choices["frames"]
    first = choices["rows"][frames & 7]
    first_cyan = choices["rows"][(frames >> 8) & 7]["cyan"]
    pieces = ", ".join(room(r) for r in first["pieces"])
    devil, frank = caves
    return {
        "Bug:firstgame:Every first game is the same castle": f"""\
#R$7D9A hides the A.C.G. key's three pieces, places the green, red and cyan
keys and the mummy, and chooses which doors will open and shut by themselves,
all from the ROM's frame counter FRAMES. But #R$6000 turns the interrupts off
as the game starts, and nothing turns them on until the first pass of
#R$7DC3 -- after all of that has been chosen. FRAMES does not move on the
title screen, so the first game after loading is decided by how many frames
the loader took, whatever is pressed on the menu and whenever.

The loaded snapshot has FRAMES at ${frames:04X}, which puts the pieces in
{pieces}, the green key in {room(first['green'])}, the red key and the mummy
in {room(first['red'])} and the cyan key in {room(first_cyan)} (the yellow is
always in {room(choices['yellow'])}). Watched in the emulator: FRAMES read
${frames:04X} on the title screen and still did after three hundred turns of
its loop; a game started from there, as the knight, and another started after
choosing a different control option and the serf, both had exactly those
rooms. A
real Spectrum should do the same on every load, if its loader takes the same
number of frames (not checked on hardware).""",

        "Bug:castles:Fewer castles than it seems": f"""\
Even after the first game, the choices are narrower than they look.
#R$94B6 and #R$98D2 add TICKS to FRAMES to pick their rooms, but #R$7D9A has
just cleared TICKS (#R$80CB), so the green key, the red key with the mummy,
and the set of rooms for the A.C.G. pieces all come from the same number,
FRAMES AND 7: eight arrangements, each always with the same partners. The
timed doors (#R$94F5) take their random bytes from a stretch of ROM chosen by
FRAMES AND 15, so each arrangement comes with one of two patterns of doors.

The cyan key is chosen from FRAMES' middle byte instead, which in play never
changes: #R$95DA takes 50 off FRAMES every second, so its low byte never
reaches 256 to carry. It moves only while the interrupts are left on outside
play, and that happens after one kind of ending only: a game over caused in
the main loop -- by a creature, a big monster or a mushroom -- runs its
ten-second delay and the title screen that follows with interrupts on. Dying
of hunger happens inside #R$7EB2, which has turned them off, and the end
screen follows #R$9489, which has too; after either, FRAMES stands still
until the next game begins.

{choices_table(choices, room)}

Watched in the emulator, ending games in both ways from the first game after
a varying number of frames and starting another: after six games over by
hunger, FRAMES had not moved during the delay or on the title screen, the
cyan key was in {room(first_cyan)} every time, and the other keys and the
pieces followed FRAMES AND 7 through the table; after six games over by the
devil, FRAMES ran on through both, its middle byte reached $26 to $28, and the
cyan key went to $4C and $53. A win left FRAMES frozen too.""",

        "Bug:zerowrap:A touch that leaves nothing fills the roast": f"""\
#R$8A1E and #R$8A15, the big five's touches, subtract from the life force and
kill only when that borrows (JR C). A result of exactly zero is stored, and
the player lives. The next drain -- hunger in #R$8E78(PLAYER_TICK), or a
mushroom -- does DEC A and tests for zero, and 0 minus 1 is 255: not zero,
so it is stored, and the roast on the scroll is full again, fuller than
eating can make it (#R$8C63 stops at 240). It needs the life force at a
multiple of 8 (of 16 for the humpback) when the touching starts, which is
less rare than it sounds: every life starts at 240 and food adds 64 (how
often it happens in play was not counted). The small creatures' #R$8ED7
tests for zero as well as a borrow, so they cannot do it.

Watched in the emulator, with a watchpoint on the life force: set to 8, with
the devil put on the player, the store at $8A25 wrote 0 and the player
carried on; with the devil sent back to his own room, the next write was
the hunger drain's store at $8E88, 0 to 255, then 254, and the roast was
drawn whole.""",

        "Bug:mushroom:One death, two lives": """\
#R$988B, a mushroom, drains the player whenever he is within 12 pixels of it
(#R$90FB), without asking whether he is alive: it goes on while he sinks
into the floor. Dying to a big monster (#R$8A1E) or to hunger leaves the life
force where it was -- neither stores the final value -- so a mushroom beside
the body counts the last few units down, and on reaching zero it calls
#R$8EA0 a second time and disappears (#R$98C8). One death costs two lives.

Watched in the emulator, staging only the room and keeping small creatures
away: the player put beside the mushroom in the devil's cave, room $43, with
a full life force, stood still. The devil arrived and ran the life force out with 6
left; #R$8EA0 ran for the devil with three spare lives, and a few passes
later ran again for the mushroom, the player still sinking, with the life
force at 0. He rose with one spare life instead of two, and the mushroom was
gone. (A small creature's touch stores 0 before killing, and a mushroom's DEC
turns that into 255, so it takes only one life.)""",

        "Bug:firstfood:The first piece of food never grows back": f"""\
#R$9924 refills eaten food, one of the eighty food records every 512 passes,
by stepping a cursor through them. It steps before it looks, and when the
step reaches the end it puts the cursor back on the first record and returns
without looking; the next step moves it to the second. #R$7D9A starts the
cursor on the first record too. So the first food record -- the one in
{room(choices['first_food_room'])} at the start of every game -- is never
looked at, and once eaten it is gone for good.

Watched in the emulator: with the first two records emptied and the cursor
on the last, TICKS was set so that the next four passes each opened the
gate. The cursor went back to the first record, then refilled the second
(with food $56), then went on; the first stayed empty. Moving the reset back
one record fixes it, and was tested the same way: the first record was
refilled at the next step.

POKE {REGROW_WRAP + 1},{0x50}""",

        "Bug:gravestones:A second gravestone rubs out the first": """\
When the player dies, #R$95A9 puts a gravestone in the first free one of four
slots at the spot where he fell and draws it -- with XOR, like every moving
thing. The new life always rises at the same place in the room (#R$9443
copies it from its template), so dying twice without moving puts two
gravestones in exactly the same place, and the second rubs the first out.
The two records are still there; a third makes one visible again. And the
four slots are never emptied, so after the fourth death there are no more.

Watched in the emulator: starved three times in a row standing where he
rose, the knight had a gravestone under him after the first death, none
after the second -- with two gravestone records holding the same room, x and
y -- and one again after the third.""",

        "Bug:rock:The devil and Frankenstein's monster stand in the rock": f"""\
The four big hunters are dispatched every pass wherever they are, and while
the player is not in play -- rising at the start of every life, the first
included, or sinking at the end of one -- they walk away from where he is
(#R$89BB(BIG_MONSTER_STEP)), up to 52 pixels from the centre: the limits in
DE, $3434, handed to #R$84CD(STEP_ACTOR). That suits a square hall, whose walk
area reaches 56 pixels from the centre, but the devil and Frankenstein's
monster live in caves, whose walk area stops at 40. While the player rises in
the first room at the start of a game, both back off to about 50 pixels up and
left of their caves' centres, into the rock, and that is where the player finds
them on arriving; they walk out onto the floor from there.

<div style="display:flex;flex-wrap:wrap;gap:16px;align-items:flex-start">
<div><div style="font-size:11px;margin-bottom:4px">Room ${devil[0]:02X}: the devil at x ${devil[1]:02X}, y ${devil[2]:02X}</div>
<img src="../{IMAGES}/cave{devil[0]:02X}.png" alt="the devil's cave on arrival"/></div>
<div><div style="font-size:11px;margin-bottom:4px">Room ${frank[0]:02X}: Frankenstein's monster at x ${frank[1]:02X}, y ${frank[2]:02X}</div>
<img src="../{IMAGES}/cave{frank[0]:02X}.png" alt="Frankenstein's cave on arrival"/></div>
</div>
<div style="clear:both"></div>
Both pictures were drawn by the game's own code: a game started from the
title screen, and three seconds later the knight put at the centre of each
cave and the first pass of the main loop run. Watched in the emulator too:
arriving in each cave from the first game's start, the monster stood 49
pixels up and left of the centre after the first pass; and with the player
dying in the devil's cave, the devil backed away to 51 pixels down and right,
into the rock in the opposite corner, until the new life began.""",

        "Bug:dracula:Dracula forgets where he was going": """\
Away from the player, #R$8906 writes $68, $68 into its +$0B and +$0C as a
place to walk to, and then calls #R$882D -- which takes its target from DE,
not from the record. #R$8862, the mummy, stores its targets in the same two
bytes and loads DE from them before the same call; Dracula's routine lacks
the two loads, and DE still holds $468A, the crucifix's sprite and colour
from the test just before. So off-screen Dracula walks to x $8A, y $46,
wherever he is, and that is where he stands when the player finds him. It
is harmless, and in a cave -- Dracula's random moves allow caves -- it puts
him 50 pixels right of the centre, in the rock.

Watched in the emulator over 600 frames of the first game: Dracula, in room
$68, walked from x $27, y $37 to x $8A, y $46 a pixel a pass, and kept that
position through moves to rooms $17, $45 and $55 -- the last of them a cave
-- while +$0B and +$0C read $68 throughout.""",
    }


# --------------------------------------------------------------------------
# The facts
# --------------------------------------------------------------------------

FACTS = {
    "Fact:score:Points come only from killing": """\
#R$A19C has two callers. The kill of a small creature (#R$875F(KILL_MONSTER))
adds 155, whether it was shot, walked into or caught by the player's death;
killing Frankenstein's monster with the spanner (#R$8988) adds 1000 more.
Nothing else scores: not keys, objects, rooms or escaping, and the other
four of the big five cannot be killed at all -- none of them tests for the
weapon (#R$8566 is called only by the small creatures' movers), so the axe,
the spell and the sword pass through them. Watched in the emulator: a game
won by walking straight to the door, with the three pieces staged in the
inventory, ended with a score of 0.""",

    "Fact:deathclears:Dying is worth 155 a head": """\
While the player sinks or rises, every small creature in the room is killed
on its next move (STEP_ACTOR, the tail of #R$845F), with the 155 points of
any other kill. The big five are exempt. Watched in the emulator: with three
creatures just materialising in the first room, starving the player took the
score from 0 to 465 and emptied all three slots.""",

    "Fact:humpback:The humpback eats treasure": """\
Eight of the collectables -- $82 to $89 -- have no use: nothing asks whether
they are carried. Nothing, that is, except the humpback (#R$8AFF), which looks
for one of them in its room (#R$8ADB), walks to it and empties its record, so
the object is gone for the game. It does this whether the player is there or
not. Watched in the emulator: object $82 put in the humpback's room, room
$56, was gone 40 frames later, the humpback standing where it had been.""",

    "Fact:crucifix:Dracula fears the crucifix": """\
#R$8906 asks #R$9273 whether the yellow crucifix is carried; if it is,
Dracula reverses whatever #R$882D would have him do, and runs from the player
instead of towards him. Watched in the emulator: Dracula put 12 pixels from
the player in the first room closed in and had the life force down to 4 in
80 frames; with the crucifix in the inventory he backed away, 13 pixels to
48, and the player lost only hunger's 4.""",

    "Fact:spanner:The spanner kills Frankenstein's monster": """\
Touched while the cyan spanner is carried, Frankenstein's monster
(#R$8988) scores 1000, is killed like any small creature, for 155 more, and
never comes back -- his slot is not refilled. Without the spanner he costs
8 a pass like the others. Watched in the emulator: put on the player, he
took the life force from 240 to 46 in 40 frames; with the spanner in the
inventory, the score went to 1155 at once and his record was emptied.""",

    "Fact:lure:The mummy has an errand": """\
Object $80, a red leaf-like thing, starts in room $09. If it is ever in the
mummy's room, #R$8862 abandons patrol and pursuit alike, walks to it, and on
reaching it moves it to room $6B, leaving it at the same x and y; then it
takes up its business again. Room $09 is one of the eight rooms the mummy can
be put in (with the red key), so in those games it does this at once.
Watched in the emulator: the object put in the mummy's room reached by the
mummy in 148 frames, and its room byte became $6B.""",

    "Fact:percent:Never 100 per cent": """\
The third figure on the end screens is a percentage of the castle seen
(#R$9641): #R$96C9 counts the rooms marked in the visited map, scores 2 for
each complete three and adds 1. All 149 rooms give 99; the starting room
alone gives 1. Watched in the emulator: a game won by walking from the first
room straight through the A.C.G. door, having seen two rooms, showed 01.""",

    "Fact:regrow:Food grows back": """\
Eaten food is not gone for good. Once every 512 passes, #R$9924 moves on to
the next of the eighty food records, and if it is empty and not in the
player's room it is filled again, in the same place, with one of the eight
kinds chosen from FRAMES -- not necessarily the kind that was eaten. A whole round of the
eighty takes about half an hour of play. Watched in the emulator: an emptied
record came back as food $56 when the cursor reached it. (Except the very
first record: see the bugs.)""",

    "Fact:timeddoors:Doors timed by the ROM": """\
About half the plain doors in each game open and shut by themselves. At the
start, #R$94F5 walks the doors reading a byte of the ROM for each -- the
Spectrum's own code used as random numbers -- and a byte below $70 makes that
door a timed one, shut to begin with. In play they share one countdown of 94
steps, taken on every other pass by whichever timed door is in the player's
room, so a room with two of them toggles twice as often. They move only while
the player is in their room: their handlers are run from the room's list and
nowhere else. (Read from the code. The first game converts 68 of the 125
plain door halves, counted in the simulator.)""",

    "Fact:modes:One door, four walls": """\
There is one picture of a door, not four. The top three bits of a door's +$05
choose one of eight drawing routines (#R$9970), and the eight are the eight
ways to lay a rectangle down -- as stored, mirrored, turned either way, upside
down, a half turn, and mirrored across either diagonal -- each with a matching
routine for the colours (#R$9985). A door's mode is its wall. The four locked
doors are the same picture again with four colour tables, and the furniture
uses the same eight modes: see #LINK(Architecture)(the architecture page).""",

    "Fact:twospeeds:A crowded room slows the monsters, not the player": """\
#R$7DC3 runs flat out, moving every monster once a pass, and calls #R$7EB2 --
the player, the weapon, the sound and the clock -- each time the ROM's frame
counter has moved. So the player always moves at 50 frames a second, while
everything else moves once a pass, and a pass is longer in a room with more
furniture and creatures (about 1.7 frames in the empty first room, measured
in the simulator). Hunger is counted in passes too (#R$8E78(PLAYER_TICK)
drains on every sixteenth), so the roast lasts longer in a busy room.""",
}


# --------------------------------------------------------------------------
# build
# --------------------------------------------------------------------------

def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    import build_aticatac as ba

    snapshot = Path(snapshot)
    skool = snapshot.with_name("aticatac.skool")
    entries, instructions = read_listing(skool)
    for address, expected in EXPECTED_INSTRUCTIONS.items():
        found = instructions.get(address, "")
        if found != expected:
            raise RuntimeError(f"aticatac_reference: ${address:04X} is '{found}', "
                               f"not {expected}: the pokes need checking")

    memory = ba.machine_memory(snapshot)
    choices = castle_choices(memory)

    def room(number):
        return ba.room_link(memory, number)

    caves = draw_caves(snapshot, Path(html_dir) / IMAGES)
    log("  reference: bugs, pokes and facts")

    fix = linker(entries)
    sections = {}
    for name, body in (list(_bugs(choices, room, caves).items()) + list(_pokes().items())
                       + list(FACTS.items())):
        sections[name] = fix(body)
    for name, body in sections.items():
        for line in body.splitlines():
            if line.startswith((";", "[")):
                raise RuntimeError(f"aticatac_reference: {name} has a line starting "
                                   f"with ; or [: {line}")
    return sections
