"""Ant Attack's reference pages: its bugs, its pokes and facts worth knowing.

build() returns SkoolKit's own Bug, Poke and Fact sections -- [Bug:x:Title],
[Poke:x:Title], [Fact:x:Title] -- for the pages ref, and draws the one picture
they show. The prose is written from the code and from checks made in the
emulator; every poke was tried live against the same trial without it, and
each says what that trial gave. Those checks were made on a private
zx_server, level 1 as the boy, driven by breakpoints on PLAY's frame loop;
notes/antattack/driving.md says how.

Nothing here quotes the game: addresses, instructions and prose only. The
one picture, the unused script run by the game's own RUN_SCRIPT, is drawn at
build time into the HTML directory, like the other generated pages.
"""
from __future__ import annotations

import re
from pathlib import Path

# The instructions each poke changes, as the listing shows them. build()
# checks the listing still says so before offering the poke.
TIME_JR = 0x8DDD          # COUNT_DOWN_TIME: JR Z past the decrement when at zero
AMMO_DEC = 0x8D1A         # THROW_GRENADE: DEC A, one grenade fewer
ENERGY_DEC = 0x8F41       # HANDLE_EVENTS: DEC (HL), the player bitten
THEIR_ENERGY_DEC = 0x8F6A  # HANDLE_EVENTS: DEC (HL), the rescued person bitten
BLAST_PLAYER_RET = 0x8D67  # THROW_GRENADE: RET NZ before blowing the player up
BLAST_THEM_RET = 0x8D8A    # THROW_GRENADE: RET NZ before blowing them up
ANT_RELOAD = 0x8A6F        # ANT_TURN: LD A,(IX+$0D), the count to the next skip

EXPECTED_INSTRUCTIONS = {
    TIME_JR: "JR Z,", AMMO_DEC: "DEC A", ENERGY_DEC: "DEC (HL)",
    THEIR_ENERGY_DEC: "DEC (HL)", BLAST_PLAYER_RET: "RET NZ",
    BLAST_THEM_RET: "RET NZ", ANT_RELOAD: "LD A,(IX+$0D)",
}

# Opcodes the pokes write, named for what they are.
JR, NOP, RET, LD_A_N = 0x18, 0x00, 0xC9, 0x3E

UNUSED_SCRIPT = 0x8B60     # "OWCH!", which nothing runs
UNUSED_SCRIPT_LENGTH = 32
RUN_SCRIPT_STREAM = 0x8E22  # RUN_SCRIPT, past finding the script: IX points at its stream byte
SCRATCH = 0x5B0F            # the printer buffer, where the copy is run from
IMAGES = "images/reference"


# --------------------------------------------------------------------------
# The listing: which addresses are entries (for #R), and where BASIC lines are
# --------------------------------------------------------------------------

_ENTRY_RE = re.compile(r"^[bcgistuw]\$([0-9A-F]{4})\b")
_INSTRUCTION_RE = re.compile(r"^[ *]\$([0-9A-F]{4}) (.*?)\s*(;|$)")
_BASIC_RE = re.compile(r"^; BASIC line (\d+)\s*$")


def read_listing(skool: Path) -> tuple[set[int], dict[int, int], dict[int, str]]:
    """Entry addresses, BASIC line number -> entry address, and each instruction."""
    entries, basic, instructions = set(), {}, {}
    pending_line = None
    for line in skool.read_text(encoding="utf-8").splitlines():
        match = _BASIC_RE.match(line)
        if match:
            pending_line = int(match.group(1))
            continue
        match = _ENTRY_RE.match(line)
        if match:
            address = int(match.group(1), 16)
            entries.add(address)
            if pending_line is not None:
                basic[pending_line] = address
                pending_line = None
            rest = line[len(match.group(0)):]
            instructions[address] = rest.split(";")[0].strip()
            continue
        match = _INSTRUCTION_RE.match(line)
        if match:
            instructions[int(match.group(1), 16)] = match.group(2).strip()
    return entries, basic, instructions


def linker(entries: set[int], basic: dict[int, int]):
    """A function that makes a section's links safe for the current listing.

    #R$ADDR stays a link only where ADDR starts an entry (the lead may split
    or merge entries); elsewhere it becomes plain $ADDR, or its link text.
    LINE(n) becomes a link to BASIC line n's entry.
    """
    def keep_or_plain(match):
        if int(match.group(1), 16) in entries:
            return match.group(0)
        if match.group(2):
            return match.group(2)[1:-1]
        return "$" + match.group(1)

    def line(match):
        number = int(match.group(1))
        if number in basic:
            return f"#R${basic[number]:04X}(line {number})"
        return f"line {number}"

    def fix(text: str) -> str:
        text = re.sub(r"#R\$([0-9A-F]{4})(\([^)]*\))?", keep_or_plain, text)
        return re.sub(r"LINE\((\d+)\)", line, text)
    return fix


# --------------------------------------------------------------------------
# The one picture: the unused script, run by the game's own code
# --------------------------------------------------------------------------

def draw_unused_script(snapshot: Path, out: Path) -> None:
    """Run the script at UNUSED_SCRIPT through RUN_SCRIPT on a game in progress.

    It has no stream byte of its own, so a copy is run from the printer
    buffer with stream 2 (the upper screen) in front of it, entering
    RUN_SCRIPT where it has found a script and has IX on the stream byte.
    """
    from build_antattack import call_routine, playing_machine, screen_image

    memory = list(playing_machine(snapshot).memory)
    memory[SCRATCH] = 2
    memory[SCRATCH + 1:SCRATCH + 1 + UNUSED_SCRIPT_LENGTH] = \
        memory[UNUSED_SCRIPT:UNUSED_SCRIPT + UNUSED_SCRIPT_LENGTH]
    # SkoolKit's simulator numbers IXh, IXl, IYh, IYl 8-11; IY is the ROM's.
    registers = {8: SCRATCH >> 8, 9: SCRATCH & 0xFF, 10: 0x5C, 11: 0x3A}
    after = call_routine(memory, RUN_SCRIPT_STREAM, registers)
    out.parent.mkdir(parents=True, exist_ok=True)
    screen_image(after).resize((512, 384)).save(out)


# --------------------------------------------------------------------------
# The sections
# --------------------------------------------------------------------------

def _pokes() -> dict[str, str]:
    return {
        "Poke:time:Infinite time": f"""\
#R$8DD0 takes a tick off the clock every third frame, but first checks for
zero with a JR Z at ${TIME_JR:04X} that jumps straight to the printing. Make it
an unconditional JR: the time is still printed, but never goes down, so the
game can never run out of time (and every rescue scores the full clock, since
the score is the time left times the rescues). Tested: with the clock set to 5
at the start of level 1, the game ran out of time within 40 frames and went to
the "TIME UP!" card without the poke; with it the clock still read 5 after 40
frames, and play went on.

POKE {TIME_JR},{JR}""",

        "Poke:grenades:Infinite grenades": f"""\
#R$8D00 checks that there is a grenade left and then takes one with DEC A at
${AMMO_DEC:04X}; make that a NOP. The count stays at 20 however many are
thrown. Tested: three throws from the city gate took the count from 20 to 17
without the poke, and left it at 20 with it.

POKE {AMMO_DEC},{NOP}""",

        "Poke:energy:Infinite energy": f"""\
A bite costs the player a point of energy in #R$8F00, with DEC (HL) at
${ENERGY_DEC:04X}; make it a NOP. "BITTEN!" still shows, but the energy stays
at 20. It does not cover being caught in your own grenade's blast, which
sets the energy to 0 outright: for that, see the grenades that hurt nobody. Tested: an ant put
two cells from the player bit eight times in 60 frames, taking the energy
from 20 to 12 without the poke; with it the energy stayed at 20 through the
same eight bites.

POKE {ENERGY_DEC},{NOP}""",

        "Poke:theirenergy:Infinite energy for the one you rescue": f"""\
The same for the person being rescued: their bite is the DEC (HL) at
${THEIR_ENERGY_DEC:04X} in #R$8F00. Since either energy reaching 0 ends the
attempt (#R$8ED0), this keeps a follower from being eaten on the way out.
Tested: an ant placed beyond the stunned rescuee bit them once in 80 frames,
20 to 19, without the poke; with it their energy stayed at 20.

POKE {THEIR_ENERGY_DEC},{NOP}""",

        "Poke:safegrenades:Grenades that hurt nobody": f"""\
Every frame of its flight, #R$8D00 checks whether the grenade is in the
player's cell or the rescued person's, and if so blows them up (see the bug
about throwing on the move). Both checks end in a RET NZ that skips someone
already exploding: make them plain RETs, at ${BLAST_PLAYER_RET:04X} and
${BLAST_THEM_RET:04X}, and the grenade passes through people. The blast still
kills and stuns ants as before (#R$8D9A). Tested: throwing while walking blew
the player up, energy 0, without the poke, and with it the player walked on
at 20; a grenade thrown at the rescued person two cells ahead blew them up
("HOW COULD YOU ?") without the poke, and exploded harmlessly beside them
with it.

POKE {BLAST_PLAYER_RET},{RET}: POKE {BLAST_THEM_RET},{RET}""",

        "Poke:slowants:Every ant at half speed": f"""\
#R$8A5D lets an ant move on every frame but one in n, where n is the ant's
own speed at +$0D: 20 for the first ant, so it hardly ever rests, and 2 for
the other four at first, rising to 3 and 4 as the rescues mount up (BASIC's
sp, LINE(90)). Where it reloads the count, replace LD A,(IX+$0D) at
${ANT_RELOAD:04X} with LD A,2 and a NOP, and every ant rests every other frame
whatever its speed. On the first levels this only slows the fast ant; from
the fourth rescue on it slows them all. Tested: over the first 60 frames of
level 1 the fast ant took 57 steps without the poke and 39 with it, as its
counter predicts (it was 19 frames from its first rest); the other four took
30 steps each both times.

POKE {ANT_RELOAD},{LD_A_N}: POKE {ANT_RELOAD + 1},2: POKE {ANT_RELOAD + 2},{NOP}""",
    }


BUGS = {
    "Bug:throwing:Throwing on the move blows you up": """\
Each frame #R$8E80 moves the player first and the grenade after. A throw
(#R$8D00) puts the grenade in the player's cell and it moves on one cell
that same frame; on every later frame of the flight, before moving it again,
the code checks whether it shares a cell with the player -- and a player who
walks on after it has just stepped into exactly that cell, since both move a
cell a frame the same way. So throwing with V held, or walking on in the
direction of the throw at any time during the flight, blows the player up:
"SILLY! YOU BLEW YOURSELF UP !", and the energy goes to 0.

Presumably the check is there for a grenade that lands on the player or the
rescued person; catching up with it from behind looks unintended. Watched in the emulator: with V and S pressed together the
grenade was one cell ahead of the player after the throw, and on the next
frame the player was in that cell, exploding, with energy 0; thrown from
standing and left alone, the same grenade hurt nobody. The pokes have a fix.""",

    "Bug:nearmiss:A near miss cures a paralysed ant": """\
Landing on an ant paralyses it for good: #R$8BD1 sets its stun count at +$06
to $FF, and #R$8A5D never moves an ant with that value. But #R$87A0, which
stuns any ant five to seven cells from an exploding grenade, writes 24 frames
of stun into the same byte without looking at what was there. A near miss
turns permanent paralysis into an ordinary stun, and 24 of the ant's frames
later it is up and chasing again. (A direct hit also clears it, but that
kills the ant anyway, and it comes back at its home like any other.)

Watched in the emulator: a paralysed ant eight cells in front of the player
was still paralysed, and had not moved, 80 frames later; with a grenade
thrown to explode six cells from it, its stun read $17 a few frames after
the blast, and within the same 80 frames it had walked over and bitten the
player.""",

    "Bug:badfall:A bad fall drowns out the other person's news": """\
#R$8F00 reads the player's and the rescued person's events (+$0F) together,
the player's in E and the other's in D. A bad fall is dealt with first, by
a CALL to #R$8E00 or #R$8E02 -- and #R$8E02 keeps the script number in D,
which #R$8E0D counts down to 0 while it finds the script. So if the player
falls badly, whatever happened to the rescued person that frame is lost; and
if the rescued person falls badly, the routine returns without looking at
the player's event at all. A bite then costs no energy and a grenade blast
does not end the attempt.

It needs the two events in the same frame, so it is rare in play. Watched in
the emulator, by writing the two events at #R$8F00 and letting it run: the
player bitten alone lost a point and heard "BITTEN!"; bitten while the
rescued person fell badly, only "HELP! I FELL!" played and the energy stayed
at 20, and the same with the player blown up; the player's bad fall with the
rescued person bitten played only "NASTY FALL !", and both falling badly
played only the player's.""",

    "Bug:stunnedfall:A fall that starts stunned is never landed": """\
#R$8800 asks whether there is anything underneath before it looks at the stun
count, so an object in the air falls (#R$8880) and its stun does not count
down. When it reaches the ground the stun is still there, so #R$8800 takes
its stunned branch, #R$88B0 -- which clears the fall count -- and #R$8860 is
never reached: no stun for the fall, no "NASTY FALL !", however far it was.

In play this is nearly latent. Nothing stunned walks, so it only arises when
what a stunned object stands on moves away -- an ant, or the other person,
and #R$84D0 clears both people's stuns while one is on the other's head. The
rescued person starts every level stunned for four frames, so a drop at the
start would do them no harm, but every waiting place is on solid ground. Watched in the emulator: the player
dropped five blocks over open ground landed stunned for 48 frames with
"NASTY FALL !"; the same drop starting with a stun of 10 kept the 10 all the
way down, landed without a message, and simply counted the 10 away.""",

    "Bug:farside:Found from the far side of the world": """\
#R$8A80 measures distance as the difference in x plus the difference in y,
each worked out in eight bits, and the sum is eight bits too. A difference
of exactly 128 comes out as 128, and 128 + 128 wraps round to 0. The walls
keep everything inside to differences below 128, but outside them the
player's coordinates run all the way down to 0, so there is one cell
outside the city -- the waiting person's x and y each 128 away -- that the
code takes to be the waiting person's own.

#R$8F80 finds the person when the distance is under 4 and the two are at the
same height. Everyone waits on a block or higher, and outside the walls the
player walks on the ground, so it takes a jump: watched in the emulator, on
level 1, the player jumping in that one cell was found -- "MY HERO!", and the
person started following -- from 256 cells away along the grid, while the
same jump one cell along found nobody. Ants reckon their distance from the
player with the same routine, so they too must misjudge a player far outside
(read from the code, not watched).""",

    "Bug:neverfalls:A flag that nothing sets": """\
#R$8880 starts by testing bit 3 of an object's flags, and if it is set,
clears the fall count and carries on as if standing: the object would never
fall. Nothing sets that bit -- not the DATA that sets up the records, not
any code -- so these are the only instructions in the game never seen to run
in the build's playthroughs. A leftover, or a feature that was not finished;
it does no harm. Watched in the emulator with the bit set by hand: the player
put five blocks up over open ground stayed at that height, standing on
nothing, for as long as it was watched.""",
}


FACTS = {
    "Fact:owch:A script that says OWCH, and nothing plays": f"""\
At #R$8B60($8B60), outside the table #R$8E0D counts its scripts from, is one more in
the same format: a PRINT AT near the bottom of the view, then letters between
notes. Its letters spell "OWCH!". Nothing refers to it. It would not work as
it is either: it has no stream byte at the front, and an end marker sits
between the C and the H, so run by the game's own #R$8E0D from a copy with a
stream byte put in front, it plays its notes and prints only the first three
letters:

<img src="../{IMAGES}/owch.png" width="512" height="384" alt="The unused script, run">""",

    "Fact:frames:Four frames that nothing draws": """\
Frames $F0-$F3 (#R$BC00(at $BC00)), between the boy's last pose and the
grenade's flight, are never drawn. #R$8600 picks an object's frame from +$08: with bit 7 set, the
frame is +$08 itself, and nothing writes such a value except the blast
frames $F4-$F7 (#R$82E0, #R$8980, #R$8D00); otherwise it is the first frame
plus four times +$08 plus the facing, and +$08 is never more than 4 for the
people and 1 for the ants. The boy's twenty frames end at $EF and the ants'
eight start at $F8. What the four were meant to show -- they are drawn on
#LINK(Sprites)(the sprites page) -- is not known.""",

    "Fact:grenadeball:The grenade's own picture, far outside the walls": """\
The grenade's record gives frames $68-$6B as its sprite (#R$9A00(at $9A00)): a
large round bomb with a fuse, stored with the girl's frames. In flight and exploding it is
drawn as $F4-$F7 instead, and when it has gone off it goes home -- to x 0,
y $40, far outside the city, where it waits for the next throw. Nobody need
ever go there, but it is open ground, and anyone who walks out that far
finds the big grenade sitting there: watched in the emulator, with the
player put two cells from it.""",

    "Fact:break:BREAK starts the game again": """\
The interrupt routine, #R$9797, passes each interrupt to the ROM unless an
error is waiting in ERR_NR -- and then, instead, it types RUN and starts the
BASIC again (#R$97A0). So BREAK, which the ROM turns into error L between
BASIC statements, takes the game back to its title screen rather than
stopping it. Watched in the emulator: CAPS SHIFT and SPACE at the girl-or-boy
question stopped at #R$97A0 with ERR_NR holding $14 (report L), and the
title came round again. During play the machine code never lets the ROM
look for BREAK, so the same two keys only pick view 0: 30 frames of them
changed nothing else.""",

    "Fact:energy:Energy is not a life": """\
When either energy reaches 0 (#R$8ED0) the level simply starts again: BASIC's
LINE(60) ends the game only when the time has run out, and otherwise
LINE(70) says "Have another go!" and sets the level up afresh, both energies
back to 20 -- but not the clock, which only LINE(20) resets, after a rescue.
So there are no lives: every failure costs only the time it took. Watched in
the emulator: the player eaten with 968 left on the clock was back at the
gate, ready to go, with 968 still on it.""",

    "Fact:keyone:Key 1 is a free refill": """\
Key 1 goes back to the gate: #R$8000 returns to BASIC the moment it sees it,
and BASIC treats that as a failed attempt. The level is set up again from
its DATA (LINE(100)), with 20 grenades and both energies full, and the
person to be rescued back at their post -- while the clock runs on from where
it was. Watched in the emulator: with 18 grenades, 17 energy and 979 on the
clock, pressing 1 gave 20, 20 and 978.""",

    "Fact:random:Every attempt is dealt the same ants": """\
The only randomness in the machine code is #R$8360, a 32-bit shift register
at $B428, which decides which way an ant turns when it is not getting closer
(and makes the hiss of #R$8B4A).
BASIC's LINE(210) sets it to 1, 1, 1, 1 with the other variables at the start
of every level and every retry, so an attempt played with the same keys on
the same frames plays out the same, ant for ant. Watched in the emulator: it
held 1, 1, 1, 1 at the start of #R$8000 on a retry, as on a new level.""",

    "Fact:seed:A random number for nobody": """\
Every time #R$8000 finishes normally it copies the first byte of its random
number into the ROM's SEED, for BASIC. BASIC calls it as RANDOMIZE USR 32768,
and RANDOMIZE then stores its own argument, the USR result, in SEED on top of
it -- and the BASIC has no RND anywhere to use either. Watched with a
watchpoint on SEED: the write at $802F was followed at once by the ROM's own
at $1E5A.""",

    "Fact:xor:The ants are part of the map": """\
Nothing in the game tests one object against another for collisions. Each
ant is a set bit in the city map at #R$C000, XORed out by #R$8940 before it
moves and back in after (#R$8A00), so everything else walks into it as into a
wall, and a bite is simply finding one's own cell occupied (#R$8800). The
map in memory changes as the ants walk. See #LINK(HowItWorks)(how the game
works).""",

    "Fact:load:Loaded over the system variables": """\
The game is one headerless block of 41984 bytes loaded to $5C00: over the
system variables and the BASIC program that is loading it, and on to the top
of memory. The loader survives because it never returns to that program --
LD-BYTES returns to #R$9700, which switches to its own interrupt routine and
types RUN into the game's own BASIC, loaded with everything else.""",

    "Fact:score:The score is time times rescues": """\
BASIC's LINE(90) scores a rescue as the time left on the clock times the
number rescued so far, including this one: the same speed is worth ten times
as much on the tenth level as on the first. The time left also decides where
the next person waits (see #LINK(Levels)(the levels)).""",

    "Fact:clock:The clock counts frames": """\
#R$8DD0 takes a tick off the clock every third frame, and there is no frame
pacing anywhere: a frame takes as long as the drawing does. The clock's 1001
ticks are 3003 frames, and at the 500,000-600,000 T-states a frame measured
for this disassembly (six or seven frames a second) that comes to about
eight minutes -- more in a busy view, less in an empty one.""",

    "Fact:fastant:One ant is fast": """\
Of the five ants, the first always rests only one frame in 20 (LINE(140)),
while the other four rest every other frame until the fourth rescue, and one
frame in three or four after it (#R$8A5D). Counted in the emulator over the
first 60 frames of level 1: 57 steps for the first ant, 30 for each of the
others.""",
}


def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    skool = snapshot.with_name("antattack.skool")
    entries, basic, instructions = read_listing(skool)

    for address, expected in EXPECTED_INSTRUCTIONS.items():
        found = instructions.get(address, "")
        if not found.startswith(expected):
            raise RuntimeError(f"antattack_reference: ${address:04X} is '{found}', "
                               f"not {expected}: the pokes need checking")

    draw_unused_script(snapshot, html_dir / IMAGES / "owch.png")
    log("  reference: bugs, pokes and facts")

    fix = linker(entries, basic)
    sections = {}
    for name, body in list(BUGS.items()) + list(_pokes().items()) + list(FACTS.items()):
        sections[name] = fix(body)
    return sections
