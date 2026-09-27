"""The Hobbit's reference pages: pokes, facts worth knowing, and one new bug.

build() returns SkoolKit's own Poke and Fact sections -- [Poke:x:Title],
[Fact:x:Title] -- and a [Bug:x:Title] for the Bugs page, as ref sections for
the lead to place. The prose is written from the code and from checks made
in the emulator. Every poke was tried live against the same trial without
it, on a private zx_server loaded with hobbit.z80 (the machine as the tape
leaves it, stopped at START), the pokes written before the game started,
driven by breakpoints at the game's own waits with commands put straight
into its input line (notes/hobbit/driving.md); each says what that trial
gave. Where a trial was staged by poking the game's state -- the player moved
somewhere, an object given -- the text says so.

Nothing here quotes the game: addresses, instructions, the pokes' own bytes
and prose, with the game's messages described rather than copied. build()
reads the listing to check that each instruction a poke changes is still
the one the poke was written for, and to keep #R links only where they name
an entry.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

# --------------------------------------------------------------------------
# What the pokes change, and what the listing must still say there
# --------------------------------------------------------------------------

PLAYER = 0xC11B            # the player's object record
WORLD_COPY = 0xF400        # START's copy of the object records, put back by every new game
CARRIES = 3                # record byte 3: how much it can carry
STRENGTH = 5               # record byte 5: strength
DEFENCE = 6                # record byte 6: defence

PATIENCE_DEC = 0x7253      # GET_KEY: DEC HL, one scan less before the game types WAIT
SEES_ALL = 0x95F1          # TOO_DARK: RET NZ, only characters other than the player see
ROAD_WIPE = 0x97DB         # NEW_GAME_CHOICES: LD (HL),$00, wiping the shut road's exit
FOREST_HOOK = 0xC7DD       # IN_THE_FOREST, the arrival hook for locations 2 and 3
JOSTLE_CLAMP = 0x921C      # JOSTLE: the eight bytes that keep the sum to 0-255
LOWER_HALLS_SCORE = 0x8D96  # VISIT_SCORES: the lower halls' score word

EXPECTED = {
    PATIENCE_DEC: ("DEC HL", None),
    SEES_ALL: ("RET NZ", None),
    ROAD_WIPE: ("LD (HL),$00", None),
    FOREST_HOOK: ("LD A,($8D9B)", None),
    JOSTLE_CLAMP: ("JR NC,$9224", None),
    JOSTLE_CLAMP + 7: ("DEC A", None),
    LOWER_HALLS_SCORE - 1: ("DEFB", "lower halls"),
    LOWER_HALLS_SCORE: ("DEFW", None),
    PLAYER + CARRIES: ("DEFB", "Carries up to"),
    PLAYER + STRENGTH: ("DEFB", "Strength"),
    PLAYER + DEFENCE: ("DEFB", "Defence"),
}

# Opcodes the pokes write, named for what they are.
RET, NOP, LD_A_HL = 0xC9, 0x00, 0x7E

# JOSTLE, mended in its own eight bytes: BIT 7,C / JR Z,+1 / CCF / JR NC,+1 /
# SBC A,A. A downward jostle then keeps its result, and only a real overflow
# upwards clamps (to 255). An underflow below 0 comes out 255 rather than 0,
# which only a value under 10 can reach; nothing DO_ATTACK jostles is that
# small, and the original gets that case wrong as well.
JOSTLE_FIX = [0xCB, 0x79, 0x28, 0x01, 0x3F, 0x30, 0x01, 0x9F]

FULL_LOWER_HALLS = 450     # 750 - 200 + 450 = 1000, the whole of SHOW_SCORE's scale


# --------------------------------------------------------------------------
# The listing: which addresses are entries (for #R), and each instruction
# --------------------------------------------------------------------------

_ENTRY_RE = re.compile(r"^[bcgistuw]\$([0-9A-F]{4})\b")
_INSTRUCTION_RE = re.compile(r"^[ *]\$([0-9A-F]{4}) ")


def read_listing(skool: Path) -> tuple[set[int], dict[int, tuple[str, str]]]:
    """Entry addresses, and each address's instruction and comment."""
    entries, instructions = set(), {}
    for line in skool.read_text(encoding="utf-8").splitlines():
        match = _ENTRY_RE.match(line) or _INSTRUCTION_RE.match(line)
        if not match:
            continue
        address = int(match.group(1), 16)
        if line[0] not in " *":
            entries.add(address)
        body = line[len(match.group(0)):]
        instruction, _, comment = body.partition(";")
        instructions[address] = (instruction.strip(), comment.strip())
    return entries, instructions


def linker(entries: set[int]):
    """A function that keeps #R$ADDR a link only where ADDR starts an entry.

    Elsewhere it becomes its link text, or plain $ADDR, so a section never
    links to the middle of an entry if the lead splits or merges them.
    """
    def keep_or_plain(match):
        if int(match.group(1), 16) in entries:
            return match.group(0)
        if match.group(2):
            return match.group(2)[1:-1]
        return "$" + match.group(1)

    def fix(text: str) -> str:
        return re.sub(r"#R\$([0-9A-F]{4})(\([^)]*\))?", keep_or_plain, text)
    return fix


def check_listing(instructions: dict[int, tuple[str, str]]) -> None:
    for address, (instruction, comment) in EXPECTED.items():
        found, remark = instructions.get(address, ("", ""))
        if not found.startswith(instruction) or (comment and comment not in remark):
            raise RuntimeError(f"hobbit_reference: ${address:04X} is '{found} ; {remark}', "
                               f"not {instruction}{' ; ' + comment if comment else ''}: "
                               "the pokes need checking")


# --------------------------------------------------------------------------
# The sections
# --------------------------------------------------------------------------

def _pokes(v: dict[str, str]) -> dict[str, str]:
    """The pokes, with their POKE lines worked out from the constants."""
    return {
        "Poke:making:Making the pokes": """\
The tape's BASIC loads the game at $6000 and starts it with PRINT USR 27648,
the address of #R$6C00(START). A poke is best made before that: in the
loader, or on a snapshot stopped at START, as the trials below were. The
pokes that change the player's record need care after that point, because
START copies every object record aside once, to #R$F400(WORLD_COPY), and each
new game (#R$6C27(NEW_GAME)) copies the records back from there -- so each of
those pokes changes both copies, and then holds whenever it is made. The
hidden road's poke acts when a new game begins. The others change the code and
take effect at once.

Most of the trials were staged: the player put straight into a place by
writing its location, and objects given the same way (see how the game is
driven in <code>notes/hobbit/driving.md</code>). Each was run from the same
start with and without the poke, and the same commands gave the same luck
both times, so any difference is the poke's.""",

        "Poke:strength:A strong player": f"""\
The player's strength is byte 5 of its record, #R$C11B(PLAYER): 64, the same
as its defence. #R$9171(DO_ATTACK) adds a weapon's strength to it, jostles it
(see <a href="bugs.html#jostle">the bug</a>) and sets it against the target's defence; a blow more than 16
over the defence kills. At 255 the blow is more than 16 over any guard in
the game -- the trolls' and the dragon's included, bare-handed -- except in the
one blow in about 25 that the jostle turns into nothing (read from the code;
tried on Thorin).
Tested: ATTACK THORIN at the first prompt was wasted against his guard of 129
without the poke; with it, one blow killed him.

Eating adds 10 to strength and kills a player who would reach 128 (#R$92B5(DO_EAT));
from 255 the sum wraps round past 255 and leaves 9, below the limit. So a
strong player who eats is weak again, not dead: tested, EAT FOOD after the
fight above took the strength from 255 to 9.

{v['strength']}""",

        "Poke:jostle:Fights as they were meant": f"""\
#R$9213(JOSTLE) is meant to add -10 to +10 to a blow and to a guard, but it
turns every downward jostle into zero (see <a href="bugs.html#jostle">the bug</a>). Its last eight bytes,
from ${JOSTLE_CLAMP:04X}, can be rewritten so that it tests the sign first --
BIT 7,C / JR Z,+1 / CCF / JR NC,+1 / SBC A,A -- and then only a sum that really
passes 255 is clamped. No blow or guard is ever zero after that, and fights
come out as the rest of #R$9171(DO_ATTACK) expects.
Tested, with the vicious warg kept beside the player in the treeless
opening: without the poke it killed the player with its twelfth blow, when the
player's guard came out as 0; with it the player took 61 of its blows,
from 46 to 65 against guards from 54 to 74, was wounded once, and was alive at
the end. The warg's blow, 55 give or take ten, can never be more than 16 over the
player's guard of 64 give or take ten, so the poke makes it harmless in one
blow, as it was meant to be.

{v['jostle']}""",

        "Poke:defence:Never killed in a fight": f"""\
The player's defence is byte 6 of its record, #R$C11B(PLAYER). Made 255, the
guard jostles up to 255 and no blow can beat it -- except that the unmended
#R$9213(JOSTLE) makes a guard of 0 about one time in 25, which any blow over
16 kills. So this poke needs the one above as well; together the player's
guard is always 245 or more, and #R$9171(DO_ATTACK) can neither kill nor wound
the player. It does not help against the dragon's fire, Bard's arrows, the
trolls eating, or any of the other deaths, which do not fight.
Tested, with the warg kept beside the player: with the defence alone it
killed the player at its twelfth blow, as without any poke, when the guard
came out 0; with both, all 61 of its blows were wasted against guards of
245 to 255.

{v['defence']}""",

        "Poke:light:Never in the dark": f"""\
#R$95ED(TOO_DARK) begins by letting anyone but the player see, with RET NZ at
${SEES_ALL:04X} after testing who is acting. Make it a plain RET: for the
player, too, A is 0 and the carry clear -- "can see" -- so no place is ever
dark, with or without the sword. Moves go where they are told, there are no
falls, dark places are described, drawn and scored, and a player shut in the
barrel can open it.
Tested in the trolls' cave with the sword moved out of it: without the poke
LOOK was refused as too dark, and three moves each fell in the dark, halving
the strength to 8; with it LOOK described the cave, and the same moves were
simply refused as having no way out.

{v['light']}""",

        "Poke:forest:A safe forest": f"""\
Arriving on the forest road or in the forest (locations 2 and 3) runs
#R$C7DD(IN_THE_FOREST), which starts timer 8: the eyes that sting to death a
player who leaves, or who stays four turns (see <a href="bugs.html#forest">the bug</a>). Make its first
byte RET and the timer never starts.
Tested from the other forest road, at 46: EAST then WEST back killed the
player on arrival without the poke; with it the player went there and back,
waited four turns on the forest road, went on into the forest, waited four
more, and was alive throughout.

{v['forest']}""",

        "Poke:patience:No WAIT unless you type it": f"""\
#R$7249(GET_KEY) counts down #R$B714(PATIENCE), 3000 keyboard scans, while it
waits for a key, and when it runs out the game types WAIT for the player and
the world moves on. Make the DEC HL at ${PATIENCE_DEC:04X} a NOP and the count
never goes down: the game waits at its prompt for as long as the player does.
Tested at the first prompt with no key pressed: without the poke the game
typed WAIT after 1171 frames, 23.4 seconds; with it nothing had happened
after 4000 frames, 80 seconds, and it was still scanning the keyboard.

{v['patience']}""",

        "Poke:road:The hidden road always open": f"""\
Every new game, #R$97AD(NEW_GAME_CHOICES) picks one of the five roads in
#R$C80E(HIDDEN_ROADS) and wipes its exit, three bytes of zeros with
LD (HL),$00 at ${ROAD_WIPE:04X}, until Elrond reads the curious map. Change it
to LD A,(HL) -- the operand byte, 0, becomes a NOP -- and the loop reads the
three bytes instead of wiping them. The road is still chosen, and Elrond still
names it, but it is never shut. It acts at the start of the next game.
Tested: the trials' game shut the long lake's way east to Lake Town. Without
the poke the exit was three zeros, the long lake listed no way east, and EAST
was refused; with it the exit was intact and EAST went to Lake Town.

{v['road']}""",

        "Poke:score:The missing quarter": f"""\
The fourteen places in #R$8D6E(VISIT_SCORES) are worth 750 tenths of a per
cent between them, so no game can score more than 75% (see <a href="bugs.html#score">the bug</a>). Make the
lower halls worth {FULL_LOWER_HALLS} instead of 200, and the places add up to
1000. Tested with the player put at the front gate and walked north into the
lower halls: the score went from 0 to 200 without the poke and to 450 with
it, and SCORE said 45.0%.

The game still cannot say 100%: #R$83F5(SHOW_SCORE) prints only two digits
before the point, so a full 1000 comes out as a colon and 0.0% (see <a href="facts.html#hundred">the fact</a>).

{v['score']}""",

        "Poke:carry:Carry anything": f"""\
The player can carry 64 (byte 3 of #R$C11B(PLAYER)); #R$8CF1(CAN_LIFT) refuses
anything that would go over. Doors, walls and the wooden chest weigh 255, so
at 255 the player can lift the chest. Tested in Bag End: TAKE CHEST was
refused as too heavy without the poke; with it the player took the chest and
carried it east to the lonelands and on to the trolls' clearing. The treasure
can then go into the chest anywhere: the game is won wherever the two meet
(#R$A9D6(CHECK_WON)).

{v['carry']}""",
    }


def _poke_lines() -> dict[str, str]:
    """Each poke's POKE statements, in decimal, from the constants."""
    def pokes(pairs):
        return ": ".join(f"POKE {address},{value}" for address, value in pairs)

    def both(field, value):
        return pokes([(PLAYER + field, value), (WORLD_COPY + field, value)])

    jostle = pokes([(JOSTLE_CLAMP + i, byte) for i, byte in enumerate(JOSTLE_FIX)])
    return {
        "strength": both(STRENGTH, 255),
        "jostle": jostle,
        "defence": both(DEFENCE, 255) + ": " + jostle,
        "light": pokes([(SEES_ALL, RET)]),
        "forest": pokes([(FOREST_HOOK, RET)]),
        "patience": pokes([(PATIENCE_DEC, NOP)]),
        "road": pokes([(ROAD_WIPE, LD_A_HL)]),
        "score": pokes([(LOWER_HALLS_SCORE, FULL_LOWER_HALLS & 0xFF),
                        (LOWER_HALLS_SCORE + 1, FULL_LOWER_HALLS >> 8)]),
        "carry": both(CARRIES, 255),
    }


BUGS = {
    "Bug:jostle:A fight's luck only runs one way": """\
Every blow and every guard in a fight is jostled by #R$9213(JOSTLE): A plus a
random number from #R$9CA8(RANDOM), -10 to +10, kept to 0-255. It adds with
ADD A,B and takes a carry as going past 255. But a negative number is added as
a byte of 246 to 255, which carries whenever the result is fine -- and the
routine then sees the negative sign and returns 0. So every downward jostle
turns a blow or a guard into nothing. (Below 10 the opposite happens: a sum
that really goes under 0 does not carry, and comes out as 246 or more.)

Downward jostles are rare, because RANDOM halves its byte until it is no more
than 20, and every byte from 21 up lands in the top half: only a byte under 10
gives a negative number, about one call in 25. So in practice a fight's
"give or take ten" is plus 0 to 10, and one time in about 25 the blow or the
guard is 0. A blow of 0 is wasted. A guard of 0 loses to any blow over 16 --
a kill. So anyone can kill anyone with luck: the vicious warg can kill the
player, the player bare-handed can kill the dragon (read from the code; not
tried), and a fight between the strong can end at any blow.

Measured in the simulator: 2000 jostles of 104 came out 104 to 114, or 0 (71
times), and never 94 to 103. Watched in the emulator, with the warg kept
beside the player: its blows came out 55 to 62 and the player's guards 65 to
73 -- the warg's blow, 55 give or take ten, could never be more than 16 over
64 give or take ten. The ninth time both came out 0, and the blow was wasted;
the twelfth time the guard alone came out 0, and the warg killed the player
with one blow. Thorin's blow of 104 was seen come out
0 too. The <a href="pokes.html#jostle">pokes</a> have a fix.""",
}


FACTS = {
    "Fact:cast:The player is one of the cast": """\
The player is object 0, with a record in #R$C063(OBJECT_INDEX) laid out like
anyone else's -- size, what it carries, strength, defence, sides, flags -- and
the same code moves it, fights for it and tells what it does. Like the other
objects it can carry handlers of its own, and it has two: EAT, the ordinary
one (#R$92B5(DO_EAT)), and after it #R$90D2(PLAYER_DIES). So the player is
edible: anyone who manages to EAT it gains the strength food gives and takes it
out of the world, and the second handler ends the game. The trolls do not go
through it -- #R$A94E(TROLLS_EAT) calls the same eating and then the death
itself -- but the record is ready for anyone who does. (Read from the record
and the routines.)""",

    "Fact:unseen:Fights you never see": """\
The characters act whether or not the player can see them (#R$980E(CHARACTERS_ACT)),
and that includes fighting each other. Watched in the emulator: after the
player attacked Thorin in Bag End -- which takes him off the player's side for
good (#R$914A(SAME_SIDE)) -- he attacked Gandalf out of sight, and the two
exchanged 23 blows each over the following turns while the player, whose
defence had been poked to 255, waited at home; it ended with a blow of 121 from Gandalf
against a guard of 0, the jostle bug's doing, which #R$9171(DO_ATTACK) takes
as a kill. In another trial a goblin fought Gandalf and Elrond, and the two
trolls came to blows with each other, all out of the player's sight.""",

    "Fact:wait:Time passes without you": """\
The world only moves in turns, but the game will take a turn by itself:
#R$7249(GET_KEY) gives the player 3000 keyboard scans (#R$B714(PATIENCE)) to
press something, and when they run out it types WAIT and presses ENTER. Each
key pressed leaves what was left plus 500, never more than 3000, so it is a
limit on pauses, not on the whole line. Watched in the emulator: from the
first prompt with no key pressed, the WAIT came after 1171 frames, 23.4
seconds. <a href="pokes.html#patience">A poke</a> stops the countdown.""",

    "Fact:sealed:A room nobody can enter": """\
Location 47, an empty place, has ways in from the mountains to its west and
from the other empty place to its south, and no ways out. It holds one thing,
the stone, whose size is 254 -- exactly the room's capacity -- so
#R$9C41(ROOM_LEFT) finds no space in it at all and #R$8E85(CAN_PASS) turns
everybody away. No instruction names the room or the stone. Watched in the
emulator: NORTH from location 51 and EAST from location 48 were both refused,
the place being too full to enter. Whether it was sealed on purpose, or a room
left unfinished, the code does not say.""",

    "Fact:read:READ is EXAMINE": """\
The dictionary (#R$6040(WORD_LIST)) makes READ a synonym of EXAMINE, and the
tokeniser swaps it before anything else sees the word. So READ MAP is EXAMINE
MAP -- watched: the two gave the same answer -- and that is why telling Elrond
to read the map works: his reading is the curious map's own EXAMINE handler
(#R$A7C4(ELROND_READS_MAP)), which only does anything for Elrond. Other
synonyms matter too: CAPTURE is ATTACK, so the player cannot capture anyone,
only attack them.""",

    "Fact:sword:The sword lights a room from the floor": """\
The only light in the game is the short strong sword, and #R$95ED(TOO_DARK)
asks only whether it is within reach (#R$9E34(IN_REACH)), not whether anyone
is holding it. So a dark place is lit while the sword lies in it -- as it does
in the trolls' cave, where it starts. Watched in the emulator: in the trolls'
cave LOOK described the cave, the sword on the floor among its contents;
with the sword moved away, the same LOOK was refused as too dark. The torch
has the sword's flags but is never tested, so it lights nothing.""",

    "Fact:hundred:The score cannot say 100%": """\
#R$83F5(SHOW_SCORE) prints the score, in tenths of a per cent, as two digits,
a point and a third, each digit worked out by #R$842E(DIGIT), which counts
how many times its place value goes in and adds that to the character 0. The
first digit is the tens of per cent, left out when it is 0; nothing prints
hundreds. A full 1000 would be ten tens, and the character after 9 is a colon.
Watched in the emulator: with #R$B6F7(SCORE) set to 1000, SCORE said the
player had mastered :0.0% of the adventure. Since the places the game scores
are worth only 750 (see <a href="bugs.html#score">the bug</a>), no game ever gets there.""",

    "Fact:wine:Drunk on the wine": """\
Drinking the wine from the barrel runs #R$AAF9(WINE_DRUNK) after the ordinary
DRINK, and it sets #R$B700(DRUNK) and starts timer 7 for five turns. While it
is set, #R$858B(PRINT_CHAR) follows every S it prints with an H. Watched in
the emulator, with the wine given to the player in Bag End: after DRINK WINE,
every s in the story came out followed by an h, through the next four turns,
and on the fifth turn after drinking the timer ran out and the text was sober
again. The drink also added one to the player's strength.""",

    "Fact:bard:Bard remembers his orders": """\
Bard takes orders unlike anyone else: his script is #R$A8AB(BARD_TAKES_ORDER)
and one step, and the routine writes each order he is given -- the action and
its two objects -- into that step, which he then tries every turn until it
works. So SAY TO BARD "SHOOT THE DRAGON" is carried out whenever it can be.
Because the game rewrites its own script there, SAVE and LOAD carry those
three bytes by hand; but a new game does not put them back, so Bard starts
the next game with the last order he was given. On the tape the step is a
placeholder that his first order replaces. (Read from the code.)""",

    "Fact:timers:Ten clocks, one alarm a turn": """\
Besides the characters, the world's turn (#R$96B3(END_OF_TURN)) runs ten
timers in #R$CA84(TIMERS): the barrel's ride down the river, the spider web
mending and smothering, the goblins' door, the bog, the magic door, the ring,
the wine, the eyes in the forest and the side door into the mountain. Each
has a length in turns, a routine for when it runs out and, for some, a
warning for the turns before. Only one may go off in a turn: a second that
reaches zero in the same turn is held back until the next. Most are started
by arriving somewhere (#R$C78E(ARRIVAL_HOOKS)), which is why a place can be
safe for a turn or two and then kill. (Read from the code.)""",

    "Fact:words:562 words in the first four kilobytes": """\
The game's dictionary sits in the 4K from $6000: 355 words the parser
understands, grouped by initial letter behind a 26-entry index
(#R$6040(WORD_LIST)), and 207 more that only the game's own sentences use,
packed the same way but reached by no index at all (#R$67AB(SECOND_LIST)).
Each letter takes a byte, five bits for the letter -- A is 1, so ASCII's low
five bits are the code -- and the spare bits carry the word's class and
whether it takes an ending. Everything else in the game names a word by a
12-bit offset into this 4K and four bits of flags. (Read from the code and
decoded by the build.)""",

    "Fact:compression:Five thousand characters in two and a half kilobytes": """\
None of the game's text is stored as text. A message is a little program for
#R$72D3(RUN_MESSAGE): two bytes name a dictionary word, one byte one of 32
common words (#R$AD3D(COMMON_WORDS)), others print punctuation or call on a
control code for the actor's name, IS or ARE, HIS or YOUR. The build's
decoder counts about 5600 characters of fixed text in the 177 messages'
2397 bytes, before any names are filled in; room and object names are six
bytes each, whatever their length. Sentences about actions are not stored at
all, but built from the action's pattern.""",

    "Fact:printer:Its own printer driver": """\
PRINT sends every line of the story to a ZX Printer, and the game does it
with its own code, not the ROM's. #R$82A5(PRINTER_ON) turns it on only if the
printer answers on port $FB; then at each new line #R$8B22(LINE_TO_PRINTER)
reads the line's eight rows of pixels straight off the screen and sends them
out a dot at a time, as the ROM's COPY does. The printer buffer at $5B00 is
never used. (Read from the code; the emulator has no ZX Printer to try it on.)""",

    "Fact:interrupts:Interrupts off from start to finish": """\
#R$6C00(START) disables interrupts, and nothing in the game enables them
again: the ROM's tape routines, used by SAVE and LOAD, end with EI, and the
game disables them straight after. So the game reads the keyboard itself, and
everything it times -- the WAIT it types, the pause at the end of a line --
is counted in keyboard scans and busy loops, not in frames. (Read from the
code: there is no EI in the game.)""",

    "Fact:pictures:Two pictures inside two others": """\
The 22 pictures (#R$CC00(PICTURE_TABLE)) are programs of lines, fills and
paint, about 10K between them -- a quarter of the game. Two of them save space
by running on into another: the goblins' dungeon draws a few things of its
own and then carries straight on as the dark dungeon's picture, and the
trolls' clearing does the same into the levelled elvish clearing's. The
clearing is also the only picture the game changes as it runs: drawn by night
until the trolls turn to stone, and by day after (#R$A971(TROLLS_TURN_TO_STONE)).
(Read from the picture streams as the build decodes them.)""",

    "Fact:versions:What v1.0 is": """\
Two releases of The Hobbit are archived: the first, known as v1.0 though its
authors called it v1.1, and v1.2, the one disassembled here, which fixed its
bugs and put the programmers' names on the loading screen. The Sinclair
Research re-release is v1.0. Compared byte for byte, the two differ in most
of their 40K -- the code has moved about -- but the scoring is the same:
v1.0 keeps its score at $B5E8 rather than #R$B6F7(SCORE), adds to it in the
same one place, and its table of scoring places is identical. Your Sinclair
blamed the first release's troubles on a road near the long lake that never
opened; which routines v1.2 changed has not been compared.""",
}


def build(html_dir: Path, log=print) -> dict[str, str]:
    import build_hobbit as bh

    skool = bh.OUT_DIR / "hobbit.skool"
    if not skool.exists():
        skool = Path(html_dir).resolve().parents[1] / "hobbit.skool"
    entries, instructions = read_listing(skool)
    check_listing(instructions)
    log("  reference: pokes, facts and a bug")

    fix = linker(entries)
    sections = {}
    for name, body in (list(_pokes(_poke_lines()).items()) + list(BUGS.items())
                       + list(FACTS.items())):
        sections[name] = fix(body)
    for name, body in sections.items():
        for line in body.splitlines():
            if line.startswith((";", "[")):
                raise RuntimeError(f"hobbit_reference: {name} has a line starting "
                                   f"with ; or [: {line}")
    return sections
