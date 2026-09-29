"""Fairlight's graphics pages -- the textures, the parts rooms are drawn from,
the object templates, every sprite, the panel, the font and the title page --
drawn from the game at build time.

build_fairlight.py --html calls build(), which draws the pictures into
html_dir/images/graphics/ and returns seven ref sections: Textures, Parts,
Templates, Sprites, Panel, Font and TitlePage. Nothing here is committed
output: the pictures are the game's, and so are the lists of what uses what.
What is committed is the prose, the addresses, and short names for what the
pictures show, each given after looking at the picture.

Everything is drawn by the game's own code, run in SkoolKit's simulator on
copies of a real game (build_fairlight's Machine: the loading tune, the title
page and a key, into the first room, three passes of the main loop):

- A texture by the room interpreter's own fill: a one-off drawing of a
  square outlined only in the clean copy ($E4 $00 ... $E4 $01) and a fill
  code inside it, run from DRAW_CURRENT_ROOM's own entry after the room is
  found (#R$E55B), and coloured by ATTRI (#R$F0FB). Every picture is compared
  with the texture's bytes read the way the listing describes them, and the
  build stops if one differs.
- A part as the first room that draws it draws it: the room is drawn by
  DRAW_CURRENT_ROOM, stopped where DRAW_PART calls the interpreter for the
  part and where that call returns; what changed on the screen in between is
  the part. A part no room draws is drawn alone.
- An object type by PLACE_OBJECT (#R$EB1A) from its template, into the
  knight's record, and REDRAW_OBJECT (#R$ECBD) with nothing else in the
  room; a sprite by REDRAW_OBJECT from a record holding it. Each is drawn
  over a clean copy of zeros and one of ones: a pixel set in the first is
  the image, one clear in the second is solid, and one set in the second
  only is where the room shows through. Mirrored sprites are turned round
  first by the game's own MIMAN, MIWRAI and MITRO (#R$F117). Every picture is
  compared with the sprite's bytes as fairlight_data.sprite_image reads
  them (mirrored for the mirrored ones).
- The panel, the font and the title page by the game's own printer
  (#R$EBFE), the thing-in-use box (#R$EC4C, #R$EC75), the message line
  (#R$E038) and the main loop's LIFE (#R$FE47), read back from the screen.
"""
from __future__ import annotations

import html
import re
from pathlib import Path

import fairlight_data as fd

IMAGES = "images/graphics"

# The game's variables and records (see their entries).
OBJECT_COUNT = 0xFF80
THIS_RECORD = 0xFF83
MESSAGE = 0xFF87
ROOM_COLOUR = 0xFF8E
LIFE_TENS = 0xFF95
LIFE_UNITS = 0xFF96
GAME_FLAGS = 0xFF97
SELECTED = 0xFF9E
CARRIED = 0xFF9F
ROOM = 0xFFB4
PARTS_TABLE = 0xFFB5
ORIGIN = 0xFFDF
KNIGHT = 0xBC90
RECORD = 20
CLEAN_COPY = 0xC000
TEXTURES = fd.TEXTURES
FONT = fd.GLYPHS

# The routines run.
DRAW_CURRENT_ROOM = 0xE55B
ROOM_FOUND = 0xE575         # DRAW_CURRENT_ROOM after the room is found
ATTRI = 0xF0FB
PART_CALL = 0xEA33          # DRAW_PART's CALL of the interpreter for the part
PART_DONE = 0xEA36          # and where it returns
PLACE_OBJECT = 0xEB1A
REDRAW_OBJECT = 0xECBD
PRINT = 0xEBFE
FONT_OPERAND = 0xEC36       # the font's address in PRINT_FIND_GLYPH's LD HL
SHOW_THING_IN_USE = 0xEC4C
CLEAR_THING_BOX = 0xEC75
SHOW_MESSAGE = 0xE038
START_PASS = 0xFF21
MESSAGE_LINE = 0xFF42
MIMAN, MIWRAI, MITRO = 0xF117, 0xF11F, 0xF127
TITLE_SCREEN = 0xF065
TITLE_PAGE_TEXT = 0xB686

# Scratch space for one-off drawings and the programs that call the printer:
# the master copy of the object table (#R$639C), which only a new game reads.
SCRATCH = 0x639C
STACK = 0x639A              # the game's own stack top (#R$C47C)
TRAP = 0x6898               # a HALT, in the same spare stretch: a return address
TIME_LIMIT = 3500000 * 5    # five seconds of the machine's time for any one call

SCREEN_SCALE = 2
SPRITE_SCALE = 2
TEXTURE_SCALE = 2
CHAR_SCALE = 4

INKS = [(0, 0, 0), (0, 0, 0xD7), (0xD7, 0, 0), (0xD7, 0, 0xD7),
        (0, 0xD7, 0), (0, 0xD7, 0xD7), (0xD7, 0xD7, 0), (0xD7, 0xD7, 0xD7)]
BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF),
          (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0), (0xFF, 0xFF, 0xFF)]
# A piece shown alone is drawn as the game draws it: black ink on paper,
# the paper the Spectrum's white when no room's colour is given (the same
# colours as fairlight_data.sprite_image). Transparent is left clear, and
# the page shows it on its blue-grey (kl-sprite).
INK = fd.INK_RGB + (255,)
PAPER = fd.PAPER_RGB + (255,)
CLEAR = (0, 0, 0, 0)
# The attribute a piece is printed in on its own: black ink on white paper,
# not BRIGHT.
ALONE_ATTRIBUTE = 0x38
# A part's picture is in the colours of the room it is drawn in: what the
# part drew in the room's ink, the room so far drawn a mix of its ink and
# paper (ROOM_SO_FAR of the way from paper to ink), on its paper. Where the
# part cleared ink is shown in the page's own colour, magenta, which no
# room has for its paper or its ink.
ROOM_SO_FAR = 0.4
PART_CLEARED = (230, 0, 230)

# Short names for what each object type's picture shows, given after drawing
# each one. A name is a claim about the picture only; what the game does with
# the thing is said from the code beside it.
TYPE_NAMES = {
    0: "a long table", 1: "a small crate", 2: "a chequered ball", 3: "a stool",
    4: "a shallow dish or a purse", 5: "a chest", 6: "a tub", 7: "a framed picture",
    8: "a barrel", 9: "a round flask", 10: "an invisible box", 11: "an invisible box",
    12: "an invisible box", 13: "the troll", 14: "a key", 15: "a small crown",
    16: "a round table", 17: "a small lamp or bell", 18: "a flat square slab",
    19: "an upright slab", 20: "an upright slab, the other way", 21: "a cross, lying down",
    22: "a suit of armour with a halberd", 23: "a potted plant",
    24: "a flat square slab", 25: "a goblet or a stand", 26: "a guard", 27: "a guard that rises from the floor, its helmet first",
    28: "a helmet", 29: "a small bottle", 30: "a loaf", 31: "a small round thing",
    32: "a flat bundle", 33: "a guard", 34: "an hourglass", 35: "a chain",
    36: "a tall bottle", 37: "a figure lying down", 38: "the end of a bench",
    39: "a bed", 40: "a small cloud", 41: "a tall pole", 42: "an invisible box",
    43: "an invisible box", 44: "an invisible box", 45: "the wraith",
    46: "an upright slab", 47: "an invisible slab", 48: "a flower with a face",
    49: "a bush", 50: "a book", 51: "a small hunched figure", 52: "a ghost",
    53: "a small flame", 54: "a small flame", 55: "a black oval: a hole",
    56: "a robed figure",
    0x47: "a doorway", 0x49: "a doorway, facing the other way",
    0x52: "the rim of a hole in the floor",
}
# What the movement kind in a template (its byte 9, the record's +14) makes
# the object do (#R$F1E0, #R$F309).
STATES = {
    0: "lies still, and falls",
    3: "moves in a straight line, bouncing off what it meets",
    4: "stays put and strikes the knight when he is in reach",
    6: "a guard: patrols along x, and chases the knight within 30",
    7: "the troll: chases the knight",
    9: "a guard that rises out of the floor, then chases the knight",
    10: "a guard: patrols along the other floor axis, and chases the knight within 30",
    11: "the wraith: chases the knight",
    12: "hangs in the air and flickers",
    13: "wanders diagonally, turning back off what it meets",
    14: "hangs in the air and flickers",
    15: "stands still until the book lies in its room, then is a wraith",
}
# The low nibble of +12, the thing's kind, as the object code reads it
# (#R$F959, #R$FE47, #R$F1E0).
KINDS = {
    1: "a door", 2: "a step (climbed along one axis)", 3: "a step (climbed along the other)",
    4: "adds 10 to LIFE when used", 5: "freezes the room's creatures when used",
    6: "makes LIFE 99 when used", 7: "kills at a touch", 8: "a decoy for the rising guards",
    9: "carries the knight to room 30 when used", 10: "destroys a wraith it falls on",
    11: "wakes the figure in room 61",
}
# Short names for the textures, given after drawing each.
TEXTURE_NAMES = [
    "a fine chequer", "horizontal lines", "vertical stripes", "solid ink",
    "diamonds of dots", "bricks", "small bricks seen at an angle",
    "small bricks seen at the other angle", "a basket weave", "rough stones", "large diamonds",
    "upright boards, with a grain", "not a pattern: bytes of the ROM", "a net of scales",
    "vertical lines, broken by dots", "large bricks seen at an angle",
    "large bricks seen at the other angle", "floorboards seen at an angle",
    "not a pattern: noise", "nothing: all paper", "a fine grid of dots", "a dense speckle",
    "letters: A with a ring, A and O with two dots", "letters: a with a ring, a and o with two dots",
    "nothing: all paper", "nothing: all paper",
]


def _word(memory, address: int) -> int:
    return memory[address] | memory[address + 1] << 8


def _esc(text: str) -> str:
    return html.escape(text, quote=False)


def _plural(count: int, word: str, words: str | None = None) -> str:
    return f"{count} {word if count == 1 else (words or word + 's')}"


def _numbers(values) -> str:
    return fd._numbers(sorted(set(values))) if values else ""


def _img(path: str, image, alt: str, scale: int = 1, cls: str = "kl-piece") -> str:
    return (f'<img class="{cls}" src="{path}" alt="{_esc(alt)}" '
            f'width="{image.width * scale}" height="{image.height * scale}">')


def _scaled(image, scale: int):
    from PIL import Image

    return image.resize((image.width * scale, image.height * scale), Image.NEAREST)


def _operand(memory, address: int, opcode: list[int], size: int = 2) -> int:
    """The immediate operand of the instruction at address, after checking it
    is the instruction expected -- so that a wrong address stops the build."""
    if list(memory[address:address + len(opcode)]) != opcode:
        raise ValueError(f"graphics: the instruction at ${address:04X} is not "
                         + " ".join(f"{b:02X}" for b in opcode))
    at = address + len(opcode)
    return memory[at] if size == 1 else _word(memory, at)


def attribute_colours(attr: int) -> tuple:
    """The ink and the paper an attribute gives, BRIGHT if it says so."""
    table = BRIGHT if attr & 0x40 else INKS
    return table[attr & 7], table[attr >> 3 & 7]


def screen_image(memory, box=None):
    """The Spectrum's screen from $4000 in its colours; cut to (x, y, x2, y2)
    in pixels if given."""
    from PIL import Image

    image = Image.new("RGB", (256, 192))
    pixels = image.load()
    for y in range(192):
        address = 0x4000 | (y & 0xC0) << 5 | (y & 7) << 8 | (y & 0x38) << 2
        for column in range(32):
            byte = memory[address + column]
            attr = memory[0x5800 + (y // 8) * 32 + column]
            table = BRIGHT if attr & 0x40 else INKS
            ink, paper = table[attr & 7], table[attr >> 3 & 7]
            for bit in range(8):
                pixels[column * 8 + bit, y] = ink if byte & (0x80 >> bit) else paper
    return image.crop(box) if box else image


def _pixel(memory, x: int, y: int, base: int = 0x4000) -> bool:
    """A pixel of the screen (or of the clean copy, base $C000), y from the top."""
    address = base | (y & 0xC0) << 5 | (y & 7) << 8 | (y & 0x38) << 2 | x >> 3
    return bool(memory[address] & (0x80 >> (x & 7)))


# --------------------------------------------------------------------------
# The listing: which addresses are entries, and what they are called.
# --------------------------------------------------------------------------

class Listing:
    """Entry starts, labels and titles from fairlight.skool, so that a #R
    link is made only to an entry that exists."""

    def __init__(self, skool: Path):
        self.labels: dict[int, str] = {}
        self.titles: dict[int, str] = {}
        self.missing = set()
        self.entries: list[int] = []
        comment, label = [], None
        if not skool.exists():
            return
        for line in skool.read_text(encoding="utf-8").splitlines():
            if line.startswith("@label="):
                label = line[7:].strip()
                continue
            if line.startswith("@"):
                continue
            if line.startswith(";"):
                comment.append(line[2:])
                continue
            match = re.match(r"^([bcgistuw* ])\$([0-9A-F]{4})", line)
            if match:
                address = int(match.group(2), 16)
                if match.group(1) not in "* ":
                    self.titles[address] = comment[0] if comment else ""
                if label:
                    self.labels[address] = label
            comment, label = [], None
        self.entries = sorted(self.titles)

    def entry_of(self, address: int) -> int | None:
        found = None
        for entry in self.entries:
            if entry > address:
                break
            found = entry
        return found

    def ref(self, address: int, text: str | None = None) -> str:
        if address in self.titles:
            return f"#R${address:04X}({text})" if text else f"#R${address:04X}"
        return text or f"${address:04X}"

    def name(self, address: int) -> str:
        return self.labels.get(address, f"${address:04X}")

    def routine(self, address: int) -> str:
        """A routine by its label, linked; an entry point inside an entry is
        named with its entry, linked."""
        name = self.labels.get(address, f"${address:04X}")
        if address in self.titles:
            return f"#R${address:04X}({name})"
        entry = self.entry_of(address)
        if entry is None:
            return name
        return f"{name} (in #R${entry:04X}({self.labels.get(entry, f'${entry:04X}')}))"

    def check_links(self, body: str) -> str:
        def fix(match):
            address = int(match.group(1), 16)
            if not self.titles or address in self.titles:
                return match.group(0)
            self.missing.add(address)
            return match.group(2)[1:-1] if match.group(2) else f"${address:04X}"
        return re.sub(r"#R\$([0-9A-F]{4})(\([^()]*\))?", fix, body)


# --------------------------------------------------------------------------
# The game, and its code run on copies of it.
# --------------------------------------------------------------------------

class Rig:
    """A game started as a player starts one, and the game's routines called
    on copies of it."""

    def __init__(self, snapshot: Path):
        import build_fairlight as bf

        self.bf = bf
        self.tape = bf.game_memory(snapshot)
        machine = bf.Machine(snapshot)
        machine.play([([], 0.5), (["SPACE"], 0.2), bf.At("the title", bf.TITLE_WAIT, 30.0)],
                      "the graphics pages: the title")
        self.title = list(machine.memory)
        # Three passes of the main loop: after the first the room's colours
        # are put on (#R$FE47).
        machine.play([([], 0.3), (["SPACE"], 0.2)]
                     + [bf.At("a pass of the main loop", bf.MAIN_LOOP, 30.0)] * 3,
                     "the graphics pages: a game")
        self.game = list(machine.memory)
        self.tracer_class = type(machine.tracer)
        # GAME OVER: LIFE gone, and the game's own way to the screen after it.
        def dead(memory):
            memory[LIFE_TENS] = memory[LIFE_UNITS] = 0
        machine.play([bf.At("a pass of the main loop", bf.MAIN_LOOP, 30.0), dead,
                      bf.At("GAME OVER", bf.TITLE_WAIT, 30.0)], "the graphics pages: game over")
        self.game_over = list(machine.memory)
        # The end of the quest, both ways: straight into room 81, and with the
        # thing it asks for fetched first (build_fairlight's sessions).
        machine = bf.Machine(snapshot)
        machine.play(bf._start() + bf._enter(bf.ENDING_ROOM)[:3]
                     + [bf.At("the end of the quest", bf.TITLE_WAIT, 30.0)],
                     "the graphics pages: the quest failed")
        self.failed = list(machine.memory)
        machine = bf.Machine(snapshot)
        machine.play(bf._start() + bf._enter(bf.QUEST_THING_ROOM)
                     + bf._pick_numbered(bf.QUEST_THING) + bf._enter(bf.ENDING_ROOM)[:3]
                     + [bf.At("the end of the quest", bf.TITLE_WAIT, 30.0)],
                     "the graphics pages: the quest done")
        self.succeeded = list(machine.memory)

    def simulator(self, memory):
        from skoolkit import CSimulator
        from skoolkit.simulator import Simulator

        memory = list(memory)
        memory[TRAP] = 0x76     # HALT
        simulator = (CSimulator or Simulator)(memory, state={"iff": 0, "im": 1, "tstates": 0})
        simulator.set_tracer(self.tracer_class(simulator))
        return simulator

    @staticmethod
    def start(simulator, **registers) -> None:
        """The stack with TRAP to return to, and the registers given (ix, iy,
        hl, de, bc, a); IY is the variables' base unless given."""
        from skoolkit.simutils import A, B, C, D, E, H, L, IXh, IXl, IYh, IYl, SP

        memory = simulator.memory
        memory[STACK - 2] = TRAP & 0xFF
        memory[STACK - 1] = TRAP >> 8
        simulator.registers[SP] = STACK - 2
        pairs = {"ix": (IXh, IXl), "iy": (IYh, IYl), "hl": (H, L), "de": (D, E), "bc": (B, C)}
        registers.setdefault("iy", 0xFF80)
        for name, value in registers.items():
            if name in pairs:
                high, low = pairs[name]
                simulator.registers[high], simulator.registers[low] = value >> 8, value & 0xFF
            elif name == "a":
                simulator.registers[A] = value
            else:
                raise ValueError(name)

    @staticmethod
    def run(simulator, start: int, stop: int) -> int:
        """Run from start until PC is stop (at least one instruction first),
        or the time limit; return PC. A routine that returns ends at TRAP."""
        from skoolkit.simutils import PC, T

        simulator.trace(start, stop, 0, simulator.registers[T] + TIME_LIMIT, False,
                        None, None, None, None, None)
        return simulator.registers[PC]

    def call(self, simulator, start: int, what: str, stop: int = TRAP, **registers) -> None:
        self.start(simulator, **registers)
        pc = self.run(simulator, start, stop)
        if pc != stop:
            raise RuntimeError(f"graphics: {what} never reached ${stop:04X} (PC ${pc:04X})")

    # ---- drawing ------------------------------------------------------

    def drawing(self, commands: list[int], what: str):
        """A one-off room record -- a colour byte and commands -- drawn by
        DRAW_CURRENT_ROOM from where it has found the room, and coloured."""
        simulator = self.simulator(self.game)
        simulator.memory[SCRATCH:SCRATCH + len(commands)] = commands
        self.call(simulator, ROOM_FOUND, what, ix=SCRATCH)
        self.call(simulator, ATTRI, "the colours")
        return simulator.memory

    def room_part_calls(self, room: int) -> list[int]:
        """The parts the room draws, in the order the interpreter draws them
        (repeats and parts within parts included)."""
        from skoolkit.simutils import B

        simulator = self.simulator(self.game)
        simulator.memory[ROOM] = room
        self.start(simulator)
        calls, pc = [], DRAW_CURRENT_ROOM
        while True:
            pc = self.run(simulator, pc, PART_CALL)
            if pc != PART_CALL:
                break
            calls.append(simulator.registers[B])
        if pc not in (TRAP, TRAP + 1):
            raise RuntimeError(f"graphics: room {room} did not finish (PC ${pc:04X})")
        return calls

    def part_in_room(self, room: int, call: int):
        """Room drawn to its call-th part call: the screen before the part,
        after it, and the whole room at the end (coloured)."""
        from skoolkit.simutils import SP

        simulator = self.simulator(self.game)
        simulator.memory[ROOM] = room
        self.start(simulator)
        pc = DRAW_CURRENT_ROOM
        for _ in range(call + 1):
            pc = self.run(simulator, pc, PART_CALL)
            if pc != PART_CALL:
                raise RuntimeError(f"graphics: room {room} has no part call {call}")
        before = list(simulator.memory[0x4000:0x5800])
        stack = simulator.registers[SP]
        while True:
            pc = self.run(simulator, pc, PART_DONE)
            if pc != PART_DONE:
                raise RuntimeError(f"graphics: the part in room {room} never returned")
            if simulator.registers[SP] == stack:
                break
        after = list(simulator.memory[0x4000:0x5800])
        pc = self.run(simulator, pc, TRAP)
        return before, after

    # ---- objects and sprites -----------------------------------------

    def _redraw(self, memory, setup, what: str):
        """REDRAW_OBJECT on the knight's record, as setup leaves it, with no
        other record in use; over a clean copy of zeros and one of ones.
        Returns the two memories."""
        runs = []
        for fill in (0x00, 0xFF):
            simulator = self.simulator(memory)
            state = simulator.memory
            state[CLEAN_COPY:CLEAN_COPY + 0x1800] = [fill] * 0x1800
            state[ORIGIN:ORIGIN + 3] = [0, 0, 0]
            setup(simulator)
            state[OBJECT_COUNT] = 7
            state[THIS_RECORD] = 7
            self.call(simulator, REDRAW_OBJECT, what, hl=KNIGHT)
            runs.append(state)
        return runs

    @staticmethod
    def _three_colour(dark, light, box):
        """Image from the run on zeros, solid from the run on ones; box is
        (x, y, width, height) with y from the top. The image is ink, the
        solid part paper, the rest clear (see INK and PAPER)."""
        from PIL import Image

        x0, y0, width, height = box
        image = Image.new("RGBA", (width, height), CLEAR)
        pixels = image.load()
        for y in range(height):
            for x in range(width):
                if _pixel(dark, x0 + x, y0 + y):
                    pixels[x, y] = INK
                elif not _pixel(light, x0 + x, y0 + y):
                    pixels[x, y] = PAPER
        return image

    @staticmethod
    def _box(memory):
        x, top, width, height = memory[KNIGHT:KNIGHT + 4]
        if x + width > 256 or top > 191 or top - height + 1 < 0:
            raise ValueError("graphics: a picture would fall off the screen")
        return x, 191 - top, width, height

    def sprite(self, address: int, width: int, height: int, memory=None, x: int = 96,
               top: int = 150):
        """The sprite as REDRAW_OBJECT draws a record holding it."""
        def setup(simulator):
            state = simulator.memory
            state[KNIGHT:KNIGHT + 6] = [x, top, width, height, address & 0xFF, address >> 8]
        dark, light = self._redraw(memory or self.game, setup, f"the sprite at ${address:04X}")
        return self._three_colour(dark, light, self._box(dark))

    def object_type(self, kind: int, template_height: int):
        """An object of a type made by PLACE_OBJECT from its template, standing
        on the floor at 100, 100, and drawn by REDRAW_OBJECT. Returns the
        picture and the record's first six bytes."""
        top = 50 + template_height
        if kind < fd.LARGE_FIRST:
            bytes_after = [kind, 0, 100, top, 100]
        else:
            bytes_after = [kind, 100, top, 100, 0, 0, 0, 0, 0, 0]
        def setup(simulator):
            state = simulator.memory
            state[SCRATCH:SCRATCH + len(bytes_after)] = bytes_after
            state[OBJECT_COUNT] = 6
            self.call(simulator, PLACE_OBJECT, f"type {kind}", hl=SCRATCH, ix=KNIGHT)
        dark, light = self._redraw(self.game, setup, f"type {kind}")
        return self._three_colour(dark, light, self._box(dark)), list(dark[KNIGHT:KNIGHT + 6])

    def mirrored(self, routine: int, width: int, height: int):
        """Memory with a kind's sprites turned round by the game's own MIMAN,
        MIWRAI or MITRO: a scratch record facing as stored, turned to $40."""
        simulator = self.simulator(self.game)
        record = SCRATCH + 0x40
        simulator.memory[record:record + RECORD] = [0] * RECORD
        simulator.memory[record + 2] = width
        simulator.memory[record + 3] = height
        self.call(simulator, routine, f"the mirroring at ${routine:04X}", ix=record,
                  bc=0x0040, de=0x0000)
        return list(simulator.memory)

    # ---- the printer ----------------------------------------------------

    def printed(self, memory, string: list[int], font: int | None = None,
                clear: bool = True, attribute: int = ALONE_ATTRIBUTE):
        """A string printed by the game's PRINT, from a CALL in scratch
        memory with the string after it; the font's address patched in
        PRINT_FIND_GLYPH if given."""
        simulator = self.simulator(memory)
        state = simulator.memory
        if clear:
            state[0x4000:0x5800] = [0] * 0x1800
            state[0x5800:0x5B00] = [attribute] * 0x300
        program = [0xCD, PRINT & 0xFF, PRINT >> 8] + string + [0xA4, 0xC9]
        state[SCRATCH:SCRATCH + len(program)] = program
        if font is not None:
            state[FONT_OPERAND], state[FONT_OPERAND + 1] = font & 0xFF, font >> 8
        self.call(simulator, SCRATCH, "the printer")
        return state


# --------------------------------------------------------------------------
# The game's data, read.
# --------------------------------------------------------------------------

class Data:
    def __init__(self, memory, frames):
        self.memory = memory
        self.frames = frames
        self.rooms = fd._stream_records(memory, fd.ROOMS, fd.ROOM_COUNT)
        self.parts = fd._stream_records(memory, fd.PARTS, fd.PART_COUNT)
        # What each room and part does directly.
        self.room_direct = [self._direct(a + 3, a + n) for a, n in self.rooms]
        self.part_direct = [self._direct(a + 2, a + n) for a, n in self.parts]
        # Rooms each part is drawn in, directly or through other parts; and the
        # parts that call it.
        self.part_rooms: dict[int, set[int]] = {p: set() for p in range(1, fd.PART_COUNT + 1)}
        self.part_callers: dict[int, set[int]] = {p: set() for p in range(1, fd.PART_COUNT + 1)}
        for part, direct in enumerate(self.part_direct, 1):
            for called in direct["parts"]:
                self.part_callers[called].add(part)
        self.room_parts: dict[int, set[int]] = {}
        for room, direct in enumerate(self.room_direct, 1):
            parts = self._all_parts(direct["parts"])
            self.room_parts[room] = parts
            for part in parts:
                self.part_rooms[part].add(room)
        # Textures by room and part.
        self.texture_rooms: dict[int, set[int]] = {t: set() for t in range(fd.TEXTURE_COUNT)}
        self.texture_parts: dict[int, set[int]] = {t: set() for t in range(fd.TEXTURE_COUNT)}
        for part, direct in enumerate(self.part_direct, 1):
            for texture in direct["fills"]:
                self.texture_parts[texture].add(part)
        for room, direct in enumerate(self.room_direct, 1):
            textures = set(direct["fills"])
            for part in self.room_parts[room]:
                textures |= set(self.part_direct[part - 1]["fills"])
            for texture in textures:
                self.texture_rooms[texture].add(room)
        # Templates.
        self.small = fd.tape_address(fd.SMALL_HOME)
        self.large = fd.tape_address(fd.LARGE_HOME)
        self.types = list(range(fd.SMALL_COUNT)) + [fd.LARGE_FIRST + i
                                                    for i in range(fd.LARGE_COUNT)]
        # Where each type is put: (room, +12, how), from the object table and
        # from the rooms' and parts' own objects.
        self.uses: dict[int, list[tuple[int, int, str]]] = {t: [] for t in self.types}
        for address, length, room, kind in fd.object_records(memory):
            flags = memory[address + 2] if kind < fd.LARGE_FIRST else 1
            self.uses.setdefault(kind, []).append((room, flags, "table"))
        for room, direct in enumerate(self.room_direct, 1):
            for kind, flags in direct["objects"]:
                self.uses[kind].append((room, flags, "room"))
            for part in self.room_parts[room]:
                for kind, flags in self.part_direct[part - 1]["objects"]:
                    self.uses[kind].append((room, flags, f"part {part}"))

    def _direct(self, start: int, end: int) -> dict:
        memory = self.memory
        out = {"fills": [], "parts": [], "objects": [], "patches": [], "invisible": False,
               "commands": 0}
        for at, length, what in fd.room_commands(memory, start, end):
            out["commands"] += 1
            op = memory[at]
            if what.startswith("Fill"):
                out["fills"].append(op - 0xE6)
            elif what.startswith("Part"):
                out["parts"].append(memory[at + 1])
            elif what.startswith("Object:"):
                out["objects"].append((op, memory[at + 1]))
            elif what.startswith("Patch"):
                out["patches"].append(op)
            elif what.startswith("$E4 $00"):
                out["invisible"] = True
        return out

    def _all_parts(self, parts, seen=None) -> set[int]:
        seen = set() if seen is None else seen
        for part in parts:
            if part not in seen:
                seen.add(part)
                self._all_parts(self.part_direct[part - 1]["parts"], seen)
        return seen

    def template(self, kind: int) -> list[int]:
        if kind < fd.LARGE_FIRST:
            address = self.small + fd.SMALL_SIZE * kind
            return list(self.memory[address:address + fd.SMALL_SIZE])
        address = self.large + fd.LARGE_SIZE * (kind - fd.LARGE_FIRST)
        return list(self.memory[address:address + fd.LARGE_SIZE])

    def template_address(self, kind: int) -> tuple[int, int]:
        """(tape, runtime) addresses of a type's template."""
        if kind < fd.LARGE_FIRST:
            return self.small + fd.SMALL_SIZE * kind, fd.SMALL_HOME + fd.SMALL_SIZE * kind
        index = kind - fd.LARGE_FIRST
        return self.large + fd.LARGE_SIZE * index, fd.LARGE_HOME + fd.LARGE_SIZE * index


def sprite_expected(memory, address: int, width: int, height: int):
    """A sprite from its bytes as the compositor (#R$E3E4) shows the object it
    redraws: where the mask has a bit set the room shows through, whatever the
    image has (a few sprites have pixels with both set); elsewhere the image's
    bit is ink and a clear one solid paper -- black on white, as INK and
    PAPER. fairlight_data.sprite_image draws the same, at its own scale."""
    from PIL import Image

    columns = width // 8
    size = columns * height
    image = Image.new("RGBA", (width, height), CLEAR)
    pixels = image.load()
    for row in range(height):
        for column in range(columns):
            bits = memory[address + row * columns + column]
            mask = memory[address + size + row * columns + column]
            for bit in range(8):
                if mask & (0x80 >> bit):
                    continue
                pixels[column * 8 + bit, row] = INK if bits & (0x80 >> bit) else PAPER
    return image


def both_set(memory, address: int, width: int, height: int) -> int:
    """How many pixels of a sprite have both the image's bit and the mask's."""
    size = (width // 8) * height
    return sum(bin(memory[address + i] & memory[address + size + i]).count("1")
               for i in range(size))


def _texture_expected(memory, index: int, box):
    """A texture's pixels on the screen from its bytes, read the way the
    listing describes the format (#R$E5E8): the pair of cells by bit 3 of the
    line counted up from the bottom (set: bytes 0-15), the cell by bit 3 of
    the column (set: the right one), and a cell's bytes from the top of the
    character row."""
    base = TEXTURES + 32 * index
    x0, y0, x1, y1 = box
    rows = []
    for y in range(y0, y1):
        line = 191 - y
        pair = 0 if line & 8 else 16
        row = []
        for x in range(x0, x1):
            cell = 8 if x & 8 else 0
            byte = memory[base + pair + cell + (7 - (line & 7))]
            row.append(bool(byte & (0x80 >> (x & 7))))
        rows.append(row)
    return rows


# --------------------------------------------------------------------------
# Textures.
# --------------------------------------------------------------------------

# The square each texture is drawn in: rows and columns of its outline (rows
# counted up from the bottom, as the room commands count them), and a point
# inside. The inside is 64 pixels each way, from x 64 and from row 64.
SWATCH = (63, 128)


def _texture_commands(index: int, colour: int) -> list[int]:
    low, high = SWATCH
    corners = [(low, high), (high, high), (high, low), (low, low)]
    commands = [colour, 0xE4, 0x00, low, low]
    for row, column in corners:
        commands += [0xCF, row, column, 0xD2]
    commands += [0xE4, 0x01, 96, 96, 0xE6 + index, 0xE5]
    return commands


def _textures_page(data: Data, rig: Rig, listing: Listing, image_dir: Path) -> str:
    memory = data.memory
    rom = rig.game[:0x4000]
    box = (64, 191 - 127, 128, 191 - 63)
    rows = []
    unused = []
    for index in range(fd.TEXTURE_COUNT):
        rooms = sorted(data.texture_rooms[index])
        parts = sorted(data.texture_parts[index])
        colour = memory[data.rooms[rooms[0] - 1][0] + 2] if rooms else 0x38
        state = rig.drawing(_texture_commands(index, colour), f"texture {index}")
        drawn = [[_pixel(state, x, y) for x in range(box[0], box[2])]
                 for y in range(box[1], box[3])]
        if drawn != _texture_expected(memory, index, box):
            raise ValueError(f"graphics: texture {index} as the fill draws it is not its bytes")
        image = screen_image(state, (box[0] - 8, box[1] - 8, box[2] + 8, box[3] + 8))
        name = f"texture{index:02d}.png"
        _scaled(image, TEXTURE_SCALE).save(image_dir / name)
        address = TEXTURES + 32 * index
        where = []
        if rooms:
            where.append(f"{_plural(len(rooms), 'room')}: {_numbers(rooms)}")
        if parts:
            where.append("parts " + ", ".join(f'<a href="Parts.html#part{p}">{p}</a>'
                                              for p in parts))
        if not rooms:
            unused.append(index)
        in_colour = (f"in the colours of room {rooms[0]}" if rooms
                     else "in black on white: no room uses it")
        rows.append(f'<tr id="texture{index}"><td>{index}<br>${0xE6 + index:02X}<br>'
                    f"{listing.ref(address, listing.name(address))}</td>"
                    f"<td>{_img(f'{IMAGES}/{name}', image, f'Texture {index}', TEXTURE_SCALE)}"
                    f"<br><small>{in_colour}</small></td>"
                    f"<td>{_esc(TEXTURE_NAMES[index])}</td>"
                    f"<td>{'<br>'.join(where) if where else '<i>none</i>'}</td></tr>")
    # The ROM, and the rest of memory, searched for each texture's bytes.
    in_rom = {}
    elsewhere = {}
    for index in range(fd.TEXTURE_COUNT):
        body = bytes(memory[TEXTURES + 32 * index:TEXTURES + 32 * index + 32])
        if len(set(body)) > 1:
            found = bytes(rom).find(body)
            if found >= 0:
                in_rom[index] = found
            hits = [a for a in range(0x4000, 0x10000 - 32)
                    if a != TEXTURES + 32 * index and bytes(memory[a:a + 32]) == body]
            elsewhere[index] = hits
    blank = [i for i in range(fd.TEXTURE_COUNT)
             if not any(memory[TEXTURES + 32 * i:TEXTURES + 32 * i + 32])]
    solid = [i for i in range(fd.TEXTURE_COUNT)
             if all(b == 0xFF for b in memory[TEXTURES + 32 * i:TEXTURES + 32 * i + 32])]
    # The Swedish letters: the eight cells of textures 22 and 23 printed by
    # the game's printer with its font's address pointed at them.
    letters_at = TEXTURES + 32 * 22
    string = [0xC8, 8, 180] + list(range(8))
    state = rig.printed(rig.game, string, font=letters_at)
    letters = screen_image(state, (8, 191 - 180, 72, 191 - 180 + 8))
    _scaled(letters, CHAR_SCALE).save(image_dir / "swedish_letters.png")
    # Each letter against the ROM's character set: the character with the
    # most rows in common.
    likeness = []
    names = ["", "A with a ring", "A with two dots", "O with two dots",
             "a with a ring", "a with two dots", "o with two dots", ""]
    for cell in range(8):
        glyph = memory[letters_at + 8 * cell:letters_at + 8 * cell + 8]
        if not any(glyph):
            continue
        best, same = None, -1
        for code in range(0x20, 0x80):
            theirs = rom[0x3D00 + 8 * (code - 0x20):0x3D00 + 8 * (code - 0x20) + 8]
            count = sum(1 for a, b in zip(glyph, theirs) if a == b)
            if count > same:
                best, same = code, count
        differ = [row for row in range(8)
                  if glyph[row] != rom[0x3D00 + 8 * (best - 0x20) + row]]
        likeness.append(f"{names[cell]}: the ROM's {chr(best)} but for row "
                        f"{' and '.join(str(r) for r in differ)}" if differ else
                        f"{names[cell]}: the ROM's {chr(best)}")
    used = [i for i in range(fd.TEXTURE_COUNT) if data.texture_rooms[i]]
    lines = ['<div class="kl-list">',
             f"<p>A room's surfaces are flood fills (#R$E5E8): a fill code, ${0xE6:02X} to "
             f"$FF, floods the area round the drawing's point with one of {fd.TEXTURE_COUNT} "
             f"textures of 32 bytes at {listing.ref(TEXTURES, f'${TEXTURES:04X}')}. What stops "
             "the flood is not the screen but the clean copy of it at #R$C000($C000), where the room's "
             "lines are (copied there by code $E2, or drawn there alone after $E4 $00), and "
             "the fill marks each pixel it paints there too; the screen only receives the "
             "texture, which replaces whatever was under it.</p>",
             "<p>A texture is a tile 16 pixels square in four cells of eight bytes, and the "
             "tile is anchored to the screen, not to the area: bit 3 of the line, counted up "
             "from the bottom, chooses the pair of cells (set: bytes 0-15, clear: bytes "
             "16-31), bit 3 of the column the cell of the pair (clear: the first eight bytes, "
             "set: the second), and a cell's bytes run from the top of the character row. So "
             "two fills of one texture side by side join without a seam. Ville Krumlinde's "
             "notes read bytes 8-15 as eight more rows of one cell; they are the right-hand "
             "cell of the same rows (read from #R$E734's addressing, and drawn here).</p>",
             "<p>Each texture here is drawn by the game's own fill: a one-off room record -- a "
             "square outlined only in the clean copy ($E4 $00, four lines, $E4 $01), a point "
             "inside it and the fill code -- run in SkoolKit's simulator from the point where "
             f"{listing.ref(DRAW_CURRENT_ROOM)} has found its room, and coloured by "
             f"{listing.ref(ATTRI)} in the colours of the first room that uses the texture. "
             "The square is 64 pixels each way, four tiles, with a margin of the room's paper "
             "round it. Every picture was checked, pixel for pixel, against the texture's "
             "bytes read as described above.</p>",
             f"<p>Only {len(used)} of the {fd.TEXTURE_COUNT} are used by any room, directly or "
             "through the parts it draws (read from every room's and part's commands): "
             f"{_numbers(used)}. The room counts below include the rooms that draw a part "
             "which fills with the texture.</p>",
             '<table class="kl-table"><tr><th>Texture<br>code<br>entry</th><th>As the fill '
             "draws it</th><th>What it shows</th><th>Used by</th></tr>"] + rows + ["</table>"]
    lines += ['<h3 id="not-patterns">Four that are not patterns</h3>']
    if 12 in in_rom:
        lines.append(f"<p><b>Texture 12</b> is 32 bytes of the ROM: ${in_rom[12]:04X}-"
                     f"${in_rom[12] + 31:04X}, byte for byte (searched at this build) -- the "
                     "end of the ROM's table of the keys' letters and digits and the start of "
                     "its table of the keywords the keys give in extended mode. Drawn as a "
                     "texture it is noise. No room fills with it.</p>")
    if 18 in elsewhere:
        where18 = ("they are found in the ROM" if 18 in in_rom else
                   "they are found nowhere else in memory or in the ROM")
        lines.append(f"<p><b>Texture 18</b> is noise too: its 32 bytes have no pattern, and "
                     f"{where18} (searched at this build). What they "
                     "were is not known; no room fills with it (read), so whatever was there "
                     "when the game was saved stayed there (inferred).</p>")
    lines.append("<p><b>Textures 22 and 23</b> are not textures at all but eight characters, "
                 "8 by 8 each: a blank, the Swedish capitals with a ring and with two dots "
                 "(&Aring;, &Auml;, &Ouml;), their small letters (&aring;, &auml;, &ouml;) and "
                 "a blank -- the three letters the Swedish alphabet has after Z, in its order. "
                 "The game's own font (#R$BAD8) has no letters but A to Z and no room fills "
                 "with codes $FC or $FD, so the game never shows them; they are, most likely, "
                 "a Swedish author's character definitions left where the textures were "
                 "assembled (inferred). Printed here by the game's own printer (#R$EBFE), with "
                 "the font's address in PRINT_FIND_GLYPH pointed at them, in black on "
                 "white:</p>")
    lines.append(_img(f"{IMAGES}/swedish_letters.png", letters, "The eight characters",
                      CHAR_SCALE))
    lines.append("<p>They are not drawn in the game's font's style but in the ROM's: compared "
                 "with the ROM's character set row for row (at this build), "
                 + "; ".join(_esc(x) for x in likeness)
                 + ". The rings and dots are added to the ROM's own letters, the one or two "
                 "rows at the top.</p>")
    if blank or solid:
        lines.append(f"<p>Plainer ones: {', '.join(f'texture {i}' for i in solid)} "
                     f"{'is' if len(solid) == 1 else 'are'} solid ink, and "
                     f"{', '.join(f'texture {i}' for i in blank)} are all paper -- a fill with "
                     "one of those rubs out rather than draws. Of them only "
                     + (", ".join(str(i) for i in solid + blank if data.texture_rooms[i]) or "none")
                     + " is used.</p>")
    lines.append("</div>")
    return "\n".join(lines)


# --------------------------------------------------------------------------
# Parts.
# --------------------------------------------------------------------------

def _room_links(data: Data, listing: Listing, rooms) -> str:
    """Rooms, each linked to its picture on the rooms page."""
    return ", ".join(f'<a href="Rooms.html#room{room}">{room}</a>' for room in sorted(rooms))


def _part_picture(before, after, colour: int, margin: int = 8):
    """The screen after a part, in the colours of the room it was drawn in
    (the room's colour byte, an attribute): what the part drew in the room's
    ink, the rest of the room faded towards its paper, on its paper; where
    the part cleared ink, PART_CLEARED. Cut to what it changed. None if it
    changed nothing."""
    from PIL import Image

    ink, paper = attribute_colours(colour)
    room_ink = tuple(round(p + ROOM_SO_FAR * (i - p)) for i, p in zip(ink, paper))
    image = Image.new("RGB", (256, 192), paper)
    pixels = image.load()
    xs, ys = [], []
    for y in range(192):
        base = (y & 0xC0) << 5 | (y & 7) << 8 | (y & 0x38) << 2
        for column in range(32):
            a, b = before[base + column], after[base + column]
            if not (a | b):
                continue
            for bit in range(8):
                mask = 0x80 >> bit
                x = column * 8 + bit
                if (a ^ b) & mask:
                    pixels[x, y] = ink if b & mask else PART_CLEARED
                    xs.append(x)
                    ys.append(y)
                elif b & mask:
                    pixels[x, y] = room_ink
    if not xs:
        return None
    box = (max(0, min(xs) - margin), max(0, min(ys) - margin),
           min(256, max(xs) + 1 + margin), min(192, max(ys) + 1 + margin))
    return image.crop(box)


def _parts_page(data: Data, rig: Rig, listing: Listing, image_dir: Path) -> str:
    # The first room, in room order, whose drawing calls each part, and which
    # of its calls that is.
    first: dict[int, tuple[int, int]] = {}
    calls_of = {}
    for room in range(1, fd.ROOM_COUNT + 1):
        calls = rig.room_part_calls(room)
        calls_of[room] = calls
        for number, part in enumerate(calls):
            first.setdefault(part, (room, number))
        if set(calls) != data.room_parts[room]:
            raise ValueError(f"graphics: room {room} drew parts {sorted(set(calls))}, and its "
                             f"commands name {sorted(data.room_parts[room])}")
    rows = []
    clearing = []           # the parts that clear ink the room had drawn
    for part in range(1, fd.PART_COUNT + 1):
        address, length = data.parts[part - 1]
        direct = data.part_direct[part - 1]
        name = f"part{part:02d}.png"
        if part in first:
            room, call = first[part]
            before, after = rig.part_in_room(room, call)
            colour = data.memory[data.rooms[room - 1][0] + 2]
            how = f"as room {room} draws it, in its colours"
        else:
            colour = ALONE_ATTRIBUTE
            state = rig.drawing([colour, 0xE0, part, 0xE5], f"part {part}")
            before, after = [0] * 0x1800, list(state[0x4000:0x5800])
            how = ("alone, from the drawing's starting state, in black on white: "
                   "no room draws it")
        picture = _part_picture(before, after, colour)
        if any(a & ~b for a, b in zip(before, after)):
            clearing.append(part)
        if picture is not None:
            _scaled(picture, SCREEN_SCALE).save(image_dir / name)
            cell = (f"<p>{_img(f'{IMAGES}/{name}', picture, f'Part {part}', SCREEN_SCALE)}"
                    f"<br><small>Drawn {how}.</small></p>")
        else:
            cell = f"<p><i>Draws nothing on the screen</i> ({how}).</p>"
        what = []
        if direct["fills"]:
            what.append("fills with " + ", ".join(
                f'<a href="Textures.html#texture{t}">texture {t}</a>' for t in direct["fills"]))
        if direct["parts"]:
            what.append("draws " + ", ".join(f'<a href="#part{p}">part {p}</a>'
                                             for p in direct["parts"]))
        if direct["invisible"]:
            what.append("draws lines only into the clean copy ($E4 $00), to bound a fill")
        if direct["objects"]:
            kinds = {}
            for kind, _ in direct["objects"]:
                kinds[kind] = kinds.get(kind, 0) + 1
            what.append("places " + ", ".join(
                f'<a href="Templates.html#type{k}">{_esc(TYPE_NAMES.get(k, f"type {k}"))}</a>'
                + (f" &times;{n}" if n > 1 else "") for k, n in sorted(kinds.items())))
        if direct["patches"]:
            what.append("sets the room's floor, ceiling and walls (patch "
                        + ", ".join(f"${p:02X}" for p in direct["patches"]) + ")")
        if direct["commands"] <= 1:
            what.append("nothing: the part is empty")
        rooms = sorted(data.part_rooms[part])
        callers = sorted(data.part_callers[part])
        used = []
        if rooms:
            used.append(f"drawn in {_plural(len(rooms), 'room')}: {_room_links(data, listing, rooms)}")
        else:
            used.append("drawn in no room")
        if callers:
            used.append("called by " + ", ".join(f'<a href="#part{p}">part {p}</a>'
                                                 for p in callers))
        rows.append(f'<div class="kl-item" id="part{part}"><h4>Part {part}: '
                    f"{listing.ref(address, listing.name(address))}, {length} bytes</h4>{cell}"
                    f"<p>Besides lines it {'; '.join(what) or 'does nothing'}. It is "
                    f"{'; '.join(used)}.</p></div>")
    unused = [p for p in range(1, fd.PART_COUNT + 1) if not data.part_rooms[p]]
    busiest = max(range(1, fd.PART_COUNT + 1), key=lambda p: len(data.part_rooms[p]))
    lines = ['<div class="kl-list">',
             f"<p>Rooms are drawn by an interpreter (#R$E5E8, #R$E89B) from commands: points, "
             "lines between them, mode bits that make points relative or mirrored, repeats, "
             "fills, and parts -- shared runs of commands that any room, or any part, can call "
             f"with $E0 or $E1 and a number. There are {fd.PART_COUNT} parts, laid out one after "
             f"another from {listing.ref(fd.PARTS, f'${fd.PARTS:04X}')}, each a length and its "
             "commands; DRAW_PART (in #R$E89B) finds part n by walking the lengths from the "
             "first. $E1 keeps the drawing's points, mode and origin round the part, $E0 does "
             "not, and a part draws with whatever state its caller left -- where it appears "
             "depends on the point it is called at. A part may also place objects and set the "
             "room's walls (object mode, $E4 $04); what it places is drawn later, as the room "
             "is entered (#R$FE15), not by the interpreter.</p>",
             "<p>So each part is shown here as the game draws it in a real room: the first room, "
             f"in room order, whose drawing calls it, drawn by {listing.ref(DRAW_CURRENT_ROOM)} "
             "in SkoolKit's simulator and stopped where DRAW_PART calls the interpreter for the "
             "part and where that call returns. A room is drawn black on black and coloured "
             "all at once afterwards (#R$F0FB); each picture here is in the colours that room "
             "is then given, its ink on its paper, and a part no room draws is in black on "
             "white. What the part drew is "
             "in the room's ink, and the room as far as it had been drawn is faded towards "
             "the paper"
             + ((", with magenta, the page's own colour and not the game's, where the part "
                 "cleared ink the room had drawn (part"
                 + ("s " if len(clearing) > 1 else " ")
                 + ", ".join(f'<a href="#part{p}">{p}</a>' for p in clearing) + ")")
                if clearing else "")
             + "; the picture is cut to what the part changed, and includes what the parts it "
             "calls draw. A large black area is a fill, usually with solid ink (texture 3), "
             "which the rooms use for what lies beyond their walls. The parts "
             "each room drew in the simulator were checked against the parts its commands "
             f"name, for every room. <a href=\"#part{busiest}\">Part {busiest}</a> is the one most "
             f"rooms draw ({len(data.part_rooms[busiest])} of them): the corner in front of the "
             "room's floor, bottom left, that LIFE is printed on (see <a href=\"Panel.html\">the "
             "panel</a>).</p>"]
    if unused:
        lines.append(f"<p>No room draws part{'s' if len(unused) > 1 else ''} "
                     + ", ".join(f'<a href="#part{p}">{p}</a>' for p in unused)
                     + "; they are drawn alone, from the point the drawing starts at "
                     "(50, 50).</p>")
    lines += rows + ["</div>"]
    return "\n".join(lines)


# --------------------------------------------------------------------------
# Templates.
# --------------------------------------------------------------------------

def _kind_text(flags: int) -> str:
    parts = []
    kind = flags & 0x0F
    if kind in KINDS:
        parts.append(KINDS[kind])
    if flags & 0x10:
        parts.append("hurts at a touch")
    if flags & 0x20:
        parts.append("can be picked up")
    if flags & 0x40:
        parts.append("the sword can kill it")
    if flags & 0x80:
        parts.append("a fighter")
    return ", ".join(parts)


def _templates_page(data: Data, rig: Rig, listing: Listing, image_dir: Path,
                    sprite_anchor: dict[int, str]) -> tuple[str, dict[int, str]]:

    memory = data.memory
    pictures: dict[int, str] = {}
    rows_small, rows_large = [], []
    for kind in data.types:
        template = data.template(kind)
        tape, home = data.template_address(kind)
        sprite = _word(template, 4)
        width, height = template[2], template[3]
        sizes = template[6:9]
        cell = ""
        if sprite:
            image, record = rig.object_type(kind, sizes[1])
            expected = sprite_expected(memory, sprite, width, height)
            if list(image.getdata()) != list(expected.getdata()):
                raise ValueError(f"graphics: type {kind} as the game draws it is not its "
                                 "sprite's bytes")
            name = f"type{kind:02x}.png"
            _scaled(image, SPRITE_SCALE).save(image_dir / name)
            pictures[kind] = f"{IMAGES}/{name}"
            cell = (f'<a href="Sprites.html#{sprite_anchor.get(sprite, "")}">'
                    + _img(pictures[kind], image, f"Type {kind}", SPRITE_SCALE, "kl-sprite")
                    + "</a>")
            sprite_text = (f'<a href="Sprites.html#{sprite_anchor.get(sprite, "")}">'
                           f"${sprite:04X}</a>, {width} by {height}")
        else:
            sprite_text = "none"
        uses = data.uses.get(kind, [])
        rooms = sorted({room for room, _, _ in uses if room < 0xFE})
        by_table = sum(1 for _, _, how in uses if how == "table")
        by_drawing = sum(1 for _, _, how in uses if how != "table")
        flags = sorted({f for _, f, _ in uses})
        where = []
        if uses:
            where.append(f"{by_table} in the object table, {by_drawing} placed by rooms' "
                         "drawings" if by_drawing else f"{by_table} in the object table")
            if rooms:
                where.append("rooms " + _room_links(data, listing, rooms))
            outside = sum(1 for room, _, _ in uses if room >= 0xFE)
            if outside:
                where.append(f"{outside} in no room at the start")
        else:
            where.append("<i>nowhere</i>")
        if kind < fd.LARGE_FIRST:
            state = template[9]
            weight = template[10]
            if weight:
                behaviour = STATES.get(state, f"state {state}")
                behaviour += f"; weight {weight - 16}" if weight >= 16 else f"; +16 {weight}"
            else:
                behaviour = ("stays put: the dispatcher never updates it, and it is drawn "
                             "into the room's picture as the room is entered")
                if state:
                    behaviour += f" (its movement kind, {state}, is never acted on)"
            kinds = "; ".join(f"${f:02X}: {_kind_text(f)}" if _kind_text(f) else f"${f:02X}"
                              for f in flags)
            row = (f'<tr id="type{kind}"><td>{kind}<br>{listing.ref(tape, f"${tape:04X}")}'
                   f"<br><small>${home:04X}</small></td><td>{cell}</td>"
                   f"<td>{_esc(TYPE_NAMES.get(kind, ''))}</td><td>{sprite_text}</td>"
                   f"<td>{sizes[0]}, {sizes[1]}, {sizes[2]}</td><td>{_esc(behaviour)}</td>"
                   f"<td>{kinds or '-'}</td><td>{'<br>'.join(where)}</td></tr>")
            rows_small.append(row)
        else:
            row = (f'<tr id="type{kind}"><td>${kind:02X} ({kind})<br>{listing.ref(tape, f"${tape:04X}")}'
                   f"<br><small>${home:04X}</small></td><td>{cell}</td>"
                   f"<td>{_esc(TYPE_NAMES.get(kind, 'an invisible door'))}</td><td>{sprite_text}</td>"
                   f"<td>{sizes[0]}, {sizes[1]}, {sizes[2]}</td>"
                   f"<td>{'<br>'.join(where)}</td></tr>")
            rows_large.append(row)
    no_sprite = [k for k in data.types if k < fd.LARGE_FIRST and not _word(data.template(k), 4)]
    unused_types = [k for k in data.types if not data.uses.get(k)]
    lines = ['<div class="kl-list">',
             "<p>Everything in a room but its lines and fills is an object: a twenty-byte "
             "record (#R$BC90 has the layout) made from a type, a template for the type and a "
             "few bytes of the object table (#R$A924) or of a room's drawing. "
             f"{listing.ref(PLACE_OBJECT)} copies the template's screen position, sprite size "
             "and sprite (+0 to +5) and its sizes (+9 to +11) into the record, and for the "
             "small types two more bytes: the movement kind (+14, what the object dispatcher "
             "#R$F1E0 does with it) and +16 (nought for a thing that never moves, which is "
             "drawn once into the room's picture as it is entered; otherwise 16 plus its "
             "weight). The bytes after the type give +12 -- the thing's kind and flags, which "
             "say what it does -- and its place. The kind belongs to the object, not the type: "
             "one type can be a harmless thing in one room and a thing that restores LIFE in "
             "another.</p>",
             f"<p>{fd.SMALL_COUNT} types, 0-{fd.SMALL_COUNT - 1}, have 11-byte templates at "
             f"{listing.ref(fd.SMALL_HOME, f'${fd.SMALL_HOME:04X}')} (on the tape at "
             f"{listing.ref(data.small, f'${data.small:04X}')}); {fd.LARGE_COUNT}, "
             f"${fd.LARGE_FIRST:02X}-${fd.LARGE_FIRST + fd.LARGE_COUNT - 1:02X}, have 9-byte "
             f"templates at ${fd.LARGE_HOME:04X} (on the tape at "
             f"{listing.ref(data.large, f'${data.large:04X}')}). The large types are the doors: "
             "every one is kind 1, and its six more bytes say where the door leads (#R$F7C4). "
             "Types $39-$45 have no template: nothing uses them.</p>",
             "<p>Each picture is drawn by the game: an object of the type made by "
             f"{listing.ref(PLACE_OBJECT)} in SkoolKit's simulator, standing on the floor at "
             f"100, 100, and drawn by {listing.ref(REDRAW_OBJECT)} with no other object in the "
             "room, over a clean copy of zeros and again of ones, which separates the image "
             "from the solid part and the transparent. They are in the game's colours: the "
             "image black ink, the solid part paper -- the Spectrum's white here, a room's own "
             "colour in the game -- and the transparent part clear, on the page's blue-grey. "
             "Every picture was checked against the sprite's bytes. "
             f"{_plural(len(no_sprite), 'small type')} have no sprite ("
             + ", ".join(f'<a href="#type{k}">{k}</a>' for k in no_sprite)
             + "): they are invisible boxes a room puts where its drawing shows something "
             "solid -- a raised floor, a step, the side of a table drawn in lines -- so that "
             "the knight walks round it or on it. The sizes are the record's +9 to +11: along "
             "the floor one way, the height, along the floor the other way.</p>",
             "<p>Where each type is used counts the object table's records and the objects "
             "rooms place in their drawings (directly or in a part), read from the tables. "
             "The kinds are the +12 values the type is given; what each means is read from "
             "the code (#R$F959, #R$FE47): the low nibble the kind, bit 4 hurts at a touch, "
             "bit 5 can be picked up, bit 6 can be killed by the sword, bit 7 a fighter. The "
             "names say what the pictures show; the game has no names for them.</p>"]
    if unused_types:
        lines.append("<p>No room and no record of the object table uses type"
                     + ("s " if len(unused_types) > 1 else " ")
                     + ", ".join(f'<a href="#type{k}">{k if k < fd.LARGE_FIRST else f"${k:02X}"}</a>'
                                 for k in unused_types) + ".</p>")
    lines += ['<h3 id="small">Types 0-56</h3>',
              '<table class="kl-table"><tr><th>Type<br>template</th><th>As drawn</th>'
              "<th>What it shows</th><th>Sprite</th><th>Sizes</th><th>What it does</th>"
              "<th>Kinds (+12)</th><th>Where</th></tr>"] + rows_small + ["</table>"]
    lines += [f'<h3 id="large">Types ${fd.LARGE_FIRST:02X}-${fd.LARGE_FIRST + fd.LARGE_COUNT - 1:02X}: doors</h3>',
              "<p>Three have sprites: the two doorways, one for each way a wall runs, and the "
              "rim of a hole in the floor. The rest are invisible: openings the room's own "
              "lines draw (an arch, a gap), or holes and ladders up, their sizes the shape of "
              "the opening.</p>",
              '<table class="kl-table"><tr><th>Type<br>template</th><th>As drawn</th>'
              "<th>What it shows</th><th>Sprite</th><th>Sizes</th><th>Where</th></tr>"]
    lines += rows_large + ["</table>", "</div>"]
    return "\n".join(lines), pictures


# --------------------------------------------------------------------------
# Sprites.
# --------------------------------------------------------------------------

class SpriteGroups:
    """What uses each sprite, read from the code that chooses it."""

    def __init__(self, memory, data: Data):
        op = lambda address, opcode: _operand(memory, address, opcode)
        byte = lambda address, opcode: _operand(memory, address, opcode, 1)
        ld_hl, ld_de = [0x21], [0x11]
        self.knight = op(MIMAN, ld_hl)
        self.knight_planes = byte(MIMAN + 4, [0x0E])
        self.wraith = op(MIWRAI, ld_hl)
        self.wraith_planes = byte(MIWRAI + 4, [0x0E])
        self.troll = op(MITRO, ld_hl)
        self.troll_planes = byte(MITRO + 4, [0x0E])
        self.walk_away = op(0xF5DF, ld_hl)
        self.stand = op(0xF420, ld_hl)
        self.fidget = op(0xF429, ld_hl)
        self.stand_away = op(0xF42F, ld_hl)
        self.fidget_away = op(0xF439, ld_hl)
        self.stoop = op(0xF504, ld_hl)
        self.stoop_away = self.stoop + op(0xF4FE, ld_hl)
        self.fight = op(0xF5F9, ld_hl)
        self.fight_away = self.fight + op(0xF5F3, ld_hl)
        self.step = op(0xF623, ld_de)
        self.guards = [op(0xF33C, ld_hl), op(0xF343, ld_hl), op(0xF34A, ld_hl), op(0xF351, ld_hl)]
        self.guard_step = op(0xF354, ld_de)
        self.rising = [op(0xF2D3, ld_hl), op(0xF2DA, ld_hl), op(0xF2E1, ld_hl), op(0xF2E8, ld_hl)]
        self.troll_away = self.troll + op(0xF3C3, ld_de)
        self.troll_step = op(0xF3C7, ld_de)
        self.wraith_away = self.wraith + op(0xF368, ld_de)
        self.flyer, self.flyer_step = op(0xF376, ld_hl), op(0xF373, ld_de)
        self.ghost, self.ghost_step = op(0xF390, ld_hl), op(0xF38D, ld_de)
        self.cloud, self.cloud_step = op(0xF399, ld_hl), op(0xF39C, ld_de)
        self.striker, self.striker_step = op(0xF296, ld_hl), op(0xF299, ld_de)
        self.template_types: dict[int, list[int]] = {}
        for kind in data.types:
            sprite = _word(data.template(kind), 4)
            if sprite:
                self.template_types.setdefault(sprite, []).append(kind)

    @staticmethod
    def run(first: int, step: int, count: int = 3) -> list[int]:
        return [first + step * i for i in range(count)]


def _sprites_page(data: Data, rig: Rig, listing: Listing, image_dir: Path,
                  groups: SpriteGroups) -> tuple[str, dict[int, str]]:
    from PIL import ImageOps

    memory = data.memory
    sizes = {address: (width, height) for address, width, height, _ in data.frames}
    listed = set(sizes)
    g = groups
    kstep = g.step
    extra = {}
    # The type-48 creature's run: its template's frame and the two after it.
    for address in g.run(g.striker, g.striker_step)[1:]:
        if address not in sizes:
            sizes[address] = sizes[g.striker]
            extra[address] = "a frame of the type-48 run, not a sprite entry of its own"
    unused_sprite = 0x9E68
    if unused_sprite not in sizes:
        sizes[unused_sprite] = (24, 16)
        extra[unused_sprite] = "not named by anything"
    # (key, title, text, [(address, what)], mirrored by)
    knight = [
        (g.knight + kstep * i, f"walking, towards the viewer, frame {i}") for i in range(3)] + [
        (g.walk_away + kstep * i, f"walking, away, frame {i}") for i in range(3)] + [
        (g.stoop, "stooping to pick up, towards the viewer"),
        (g.stoop_away, "stooping to pick up, away"),
        (g.fight, "fighting, sword out, towards the viewer"),
        (g.fight + kstep, "fighting, stepping in, towards the viewer"),
        (g.fight_away, "fighting, sword out, away"),
        (g.fight_away + kstep, "fighting, stepping in, away"),
        (g.fidget, "a fidget, towards the viewer"),
        (g.fidget_away, "a fidget, away")]
    guard_names = ["going down y, or standing", "going up x", "going down x", "going up y"]
    guards = [(address, f"{guard_names[n]}, frame {i}")
              for n, first in enumerate(g.guards)
              for i, address in enumerate(g.run(first, g.guard_step))]
    rising = [(address, f"rising out of the floor, stage {i}" if i else
               "the helmet: stage 0 of rising, and what a killed guard leaves")
              for i, address in enumerate(g.rising)]
    troll = ([(address, f"towards the viewer, frame {i}")
              for i, address in enumerate(g.run(g.troll, g.troll_step))]
             + [(address, f"away, frame {i}")
                for i, address in enumerate(g.run(g.troll_away, g.troll_step))])
    wraith = [(g.wraith, "towards the viewer"), (g.wraith_away, "away")]
    group_list = [
        ("knight", "The knight", knight, "MIMAN"),
        ("guards", "The guards", guards + rising, None),
        ("troll", "The troll", troll, "MITRO"),
        ("wraith", "The wraith", wraith, "MIWRAI"),
        ("floaters", "The ghost and the floating things",
         [(a, f"the ghost, frame {i}") for i, a in enumerate(g.run(g.ghost, g.ghost_step))]
         + [(a, f"the small hunched figure, frame {i}")
            for i, a in enumerate(g.run(g.flyer, g.flyer_step))]
         + [(a, f"the small cloud, frame {i}")
            for i, a in enumerate(g.run(g.cloud, g.cloud_step))]
         + [(a, f"the flower with a face, frame {i}" + (" (striking)" if i else ""))
            for i, a in enumerate(g.run(g.striker, g.striker_step))], None),
    ]
    claimed = {a for _, _, entries, _ in group_list for a, _ in entries}
    doors, things = [], []
    for address in sorted(sizes):
        if address in claimed or address == unused_sprite:
            continue
        kinds = g.template_types.get(address)
        if not kinds:
            raise ValueError(f"graphics: the sprite at ${address:04X} is in no group")
        names = "; ".join(f"type {k if k < fd.LARGE_FIRST else f'${k:02X}'}: "
                          f"{TYPE_NAMES.get(k, '')}" for k in kinds)
        if all(k >= fd.LARGE_FIRST for k in kinds):
            doors.append((address, names))
        else:
            things.append((address, names))
    group_list += [("things", "Things and furniture", things, None),
                   ("doors", "Doors", doors, None),
                   ("unused", "A sprite nothing uses", [(unused_sprite, "a diagonal shaft")], None)]
    # Which templates' sprites the creatures have too.
    mirrors = {"MIMAN": (MIMAN, g.knight, g.knight_planes),
               "MIWRAI": (MIWRAI, g.wraith, g.wraith_planes),
               "MITRO": (MITRO, g.troll, g.troll_planes)}
    pictures: dict[int, str] = {}
    anchors: dict[int, str] = {}
    body = []
    total = 0
    for key, title, entries, mirror in group_list:
        mirrored_memory = None
        if mirror:
            routine, first, planes = mirrors[mirror]
            width, height = sizes[first]
            mirrored_memory = rig.mirrored(routine, width, height)
            stride = 2 * (width // 8) * height
            turned = set(range(first, first + stride * (planes // 2), stride))
            if {a for a, _ in entries} != turned:
                raise ValueError(f"graphics: {mirror} turns {len(turned)} frames, and "
                                 f"the {title.lower()} have {len(entries)}")
        rows = []
        for address, what in entries:
            width, height = sizes[address]
            plain = rig.sprite(address, width, height)
            expected = sprite_expected(memory, address, width, height)
            if list(plain.getdata()) != list(expected.getdata()):
                raise ValueError(f"graphics: sprite ${address:04X} as REDRAW_OBJECT draws it "
                                 "is not its bytes")
            name = f"sprite{address:04x}.png"
            _scaled(plain, SPRITE_SCALE).save(image_dir / name)
            pictures[address] = f"{IMAGES}/{name}"
            anchors[address] = f"sprite{address:04x}"
            label = listing.name(address)
            cell = _img(pictures[address], plain, label, SPRITE_SCALE, "kl-sprite")
            if mirrored_memory is not None:
                turned = rig.sprite(address, width, height, mirrored_memory)
                if list(turned.getdata()) != list(ImageOps.mirror(expected).getdata()):
                    raise ValueError(f"graphics: sprite ${address:04X} turned by {mirror} is "
                                     "not its bytes mirrored")
                mname = f"sprite{address:04x}m.png"
                _scaled(turned, SPRITE_SCALE).save(image_dir / mname)
                cell += " " + _img(f"{IMAGES}/{mname}", turned, f"{label} mirrored",
                                   SPRITE_SCALE, "kl-sprite")
            if address in listed:
                total += 1
            entry = listing.ref(address, label) if address in listing.titles else f"${address:04X}"
            note = f"<br><small>{_esc(extra[address])}</small>" if address in extra else ""
            rows.append(f'<tr id="sprite{address:04x}"><td>{cell}</td><td>{entry}<br>'
                        f"${address:04X}</td><td>{_esc(what)}{note}</td>"
                        f"<td>{width} by {height}</td></tr>")
        body.append((key, title, rows, mirror))
    if total != len(listed):
        raise ValueError(f"graphics: {total} of the {len(listed)} sprites drawn")
    text = {
        "knight": f"Fourteen frames of 24 by 31 from {listing.ref(g.knight)}, 186 bytes apart, "
                  "all of them turned round in memory by #R$F117 whenever he turns "
                  "between a way that is drawn as stored and one that is mirrored: facing up x "
                  "(Y to P) and down y (A to G) he is drawn as stored, up y (Q to T) and down x "
                  "(H to ENTER) mirrored; towards the viewer (down y, down x) or away (up x, up "
                  "y) chooses the frames. KNIGHT_CONTROLS (#R$F595) walks him through a run of "
                  "three (ANIM plays 0, 1, 2, 1, 0 ...); standing, he shows the middle frame of "
                  "the run, and now and then a fidget (#R$F309). A jump (KNIGHT_JUMP) shows the "
                  "walking frames: the first as he takes off, then the walk goes on through the "
                  "air. Fighting (B to M, or fire) he steps in three passes and holds the sword "
                  "out three; picking up he stoops (#R$F4F4). Each frame is shown as stored and "
                  "as MIMAN turns it.",
        "guards": "Types 26, 33 and 27 (#R$F309, #R$F1E0): four runs of three frames of 24 by "
                  "26, 156 bytes apart, one for each way a guard can go on the floor -- the "
                  "later test wins, so going diagonally a guard shows the run of up y or down x "
                  "-- and never mirrored. Between the second and third run lie the frames of a "
                  "guard of type 27 rising out of the floor, chosen by a count as it rises: "
                  "first the helmet, which is also what a guard killed by the sword becomes "
                  "(#R$F959), and the template's sprite for types 27 and 28.",
        "troll": "Type 13 (#R$F309's state 7): six frames of 24 by 38, three towards the "
                 "viewer and three away, turned round in memory by #R$F127. The frames are "
                 "shared by every troll, so the record's mirroring flag is true only because no "
                 "room has two, and leaving a room turns them back (#R$F906).",
        "wraith": "Type 45 (state 11), and type 56 once it wakes (#R$F309): one frame towards "
                  "the viewer and one away, turned by #R$F11F, never animated.",
        "floaters": "Type 52, the ghost, which wanders and steals things it meets (state 13); "
                    "type 51, the small hunched figure, and type 40, the small cloud, which hang "
                    "and flicker (states 12 and 14); and type 48, the flower with a face, which "
                    "strikes when the knight comes close (state 4, #R$F1E0). Each is a run of "
                    "three frames. The flower's second and third frames lie in "
                    "#R$5D14, after its template's frame; the build's sessions never saw "
                    "them, as no session stood the knight in front of one.",
        "things": "The sprites of the templates (see <a href=\"Templates.html\">the object "
                  "types</a>): one frame each, never mirrored. Some serve two types -- the "
                  "slabs, the helmet -- which differ in size or weight.",
        "doors": "The doors that have a picture (the rest are drawn by the rooms' lines).",
        "unused": "A sprite of 24 by 16 between two others (#R$9E68): no template and no code "
                  "names it, and the sessions never saw it on an object.",
    }
    lines = ['<div class="kl-list">',
             f"<p>Every sprite: {len(listed)} as the listing lays them out, grouped by what "
             "uses them, and the two frames of the flower's run and the one sprite nothing "
             "uses beside them. A sprite is its image, a row at a time from the top, then a "
             "mask of the same size; its width and height are not in the sprite but in the "
             "record that shows it (+2, +3), and so in the template or the code that sets "
             "the sprite. Where the image has a bit set the pixel is ink; where neither has "
             "it is solid paper; where the mask has, the room shows through. Fairlight draws "
             "black ink on each room's coloured paper, and so are the sprites here: black ink "
             "on the Spectrum's white paper, and the see-through part clear, on the page's "
             "blue-grey.</p>",
             f"<p>Each picture is drawn by the game: a record holding the sprite, drawn by "
             f"{listing.ref(REDRAW_OBJECT)} in SkoolKit's simulator with no other object in "
             "the room, over a clean copy of zeros and again of ones, and read back from the "
             "screen. Every one was checked against the sprite's bytes. Three kinds are "
             "turned round by the game itself, in memory, when they turn: the knight, the "
             "troll and the wraith; they are shown as stored and as turned by the game's own "
             "routine (#R$F117, #R$F127, #R$F11F), and the turned pictures were checked "
             "against the bytes mirrored. Nothing else is ever mirrored: the guards have a "
             "run of frames for each way, and things do not turn.</p>",
             "<p>Which sprite each creature shows is read from the code that chooses it; "
             "every address below comes from the game's instructions at this build.</p>",
             "<p>" + " -- ".join(f'<a href="#{key}">{title}</a>' for key, title, _, _ in body)
             + "</p>"]
    for key, title, rows, mirror in body:
        lines += [f'<h3 id="{key}">{title}</h3>', f"<p>{text[key]}</p>",
                  '<table class="kl-table"><tr><th>' + ("As stored; as turned" if mirror
                                                        else "Sprite")
                  + "</th><th>Entry</th><th>What it shows</th><th>Size</th></tr>"]
        lines += rows + ["</table>"]
    lines.append("</div>")
    return "\n".join(lines), anchors


# --------------------------------------------------------------------------
# The panel.
# --------------------------------------------------------------------------

PANEL_BOX = (0, 120, 104, 192)      # the panel's corner of the screen, x and y from the top


def _panel_page(data: Data, rig: Rig, listing: Listing, image_dir: Path,
                panel_part: int | None) -> str:
    game = rig.game
    whole = screen_image(game)
    _scaled(whole, SCREEN_SCALE).save(image_dir / "panel_game.png")
    corner = screen_image(game, PANEL_BOX)
    _scaled(corner, 3).save(image_dir / "panel_corner.png")
    # The thing in use: five things in the five places, each chosen in turn
    # and shown by SHOW_THING_IN_USE. The things are made by PLACE_OBJECT in
    # spare records.
    things = [14, 9, 34, 50, 29]
    shots = []
    simulator = rig.simulator(game)
    state = simulator.memory
    records = []
    for index, kind in enumerate(things):
        record = 0xBF00 - RECORD * (index + 1)
        height = data.template(kind)[7]
        state[SCRATCH:SCRATCH + 5] = [kind, 0x20, 100, 50 + height, 100]
        rig.call(simulator, PLACE_OBJECT, f"type {kind}", hl=SCRATCH, ix=record)
        records.append(record)
    state[OBJECT_COUNT] = game[OBJECT_COUNT]
    for index, record in enumerate(records):
        state[CARRIED + 2 * index], state[CARRIED + 2 * index + 1] = record & 0xFF, record >> 8
    for index, record in enumerate(records):
        state[SELECTED] = 0x9F + 2 * index
        rig.call(simulator, SHOW_THING_IN_USE, f"place {index + 1}", hl=record)
        image = screen_image(state, (0, 128, 56, 176))
        name = f"panel_place{index + 1}.png"
        _scaled(image, 3).save(image_dir / name)
        shots.append(f"<td>{_img(f'{IMAGES}/{name}', image, f'Place {index + 1}', 3)}<br>"
                     f"place {index + 1}: "
                     f'<a href="Templates.html#type{things[index]}">'
                     f"{_esc(TYPE_NAMES[things[index]])}</a></td>")
    # An empty place: CLEAR_THING_BOX alone.
    state[SELECTED] = 0xA7
    state[CARRIED + 8] = state[CARRIED + 9] = 0
    rig.call(simulator, CLEAR_THING_BOX, "an empty place")
    image = screen_image(state, (0, 128, 56, 176))
    _scaled(image, 3).save(image_dir / "panel_empty.png")
    shots.append(f"<td>{_img(f'{IMAGES}/panel_empty.png', image, 'An empty place', 3)}<br>"
                 "place 5, empty</td>")
    # The messages, and LIFE printed by the main loop's own lines.
    messages = []
    for number, what in ((1, "blocked"), (2, "locked"), (3, "too heavy")):
        simulator = rig.simulator(game)
        simulator.memory[MESSAGE] = number
        rig.call(simulator, SHOW_MESSAGE, f"message {number}")
        image = screen_image(simulator.memory, (16, 168, 104, 192))
        name = f"panel_message{number}.png"
        _scaled(image, 3).save(image_dir / name)
        messages.append(f"<td>{_img(f'{IMAGES}/{name}', image, what, 3)}<br>message {number}"
                        "</td>")
    simulator = rig.simulator(game)
    simulator.memory[LIFE_TENS], simulator.memory[LIFE_UNITS] = 4, 2
    simulator.memory[GAME_FLAGS] |= 1
    rig.call(simulator, START_PASS, "LIFE", stop=MESSAGE_LINE)
    image = screen_image(simulator.memory, (16, 160, 104, 192))
    _scaled(image, 3).save(image_dir / "panel_life.png")
    messages.append(f"<td>{_img(f'{IMAGES}/panel_life.png', image, 'LIFE 42', 3)}<br>"
                    "LIFE at 42</td>")
    part_text = (f'drawn by the room itself, in <a href="Parts.html#part{panel_part}">'
                 f"part {panel_part}</a>, which {len(data.part_rooms[panel_part])} rooms draw"
                 if panel_part else "drawn by the room itself")
    lines = ['<div class="kl-list">',
             "<p>Fairlight has no panel apart from the room: the room fills the screen, and "
             "the few things the player needs are in its bottom left-hand corner, in front of "
             f"the floor's edge -- {part_text}: a solid fill beyond the edge and a fine chequer "
             f"below it, with the rest of the room's lines, and coloured with it. On it "
             "the game prints LIFE (its label once, by #R$FD20 as the room is entered, and the "
             "two digits by the main loop whenever LIFE changes, #R$FE47), the number of the "
             "carried place in use, 1 to 5, and a box 24 by 32 with the thing in that place. "
             "The five things carried are not shown together: only the one chosen with keys 1 "
             "to 5 is in the box. Here is a game at its third pass in the first room (room 29), "
             "read from the screen of the game run in SkoolKit's simulator:</p>",
             _img(f"{IMAGES}/panel_game.png", whole, "The first room", SCREEN_SCALE, "kl-scene"),
             "<br>",
             _img(f"{IMAGES}/panel_corner.png", corner, "The panel's corner", 3),
             '<h3 id="box">The box</h3>',
             f"<p>{listing.ref(CLEAR_THING_BOX)} (the author's INFO0) puts the box back as the "
             "clean copy of the room has it and prints the place's digit at x 10, y 50; "
             f"{listing.ref(SHOW_THING_IN_USE)} (INFOR) then draws the thing's sprite in it, the "
             "image only, with no mask, over the box. Staged here by the game's own routines: "
             "five things made by PLACE_OBJECT in spare records and put in the five places, "
             "each place chosen (SELECTED) and shown by SHOW_THING_IN_USE, and then an empty "
             "place cleared by CLEAR_THING_BOX alone. The sprite is drawn from the box's corner, "
             "so a thing smaller than the box sits at its bottom left, and one wider would "
             "spill out.</p>",
             '<table class="kl-table"><tr>' + "".join(shots) + "</tr></table>",
             '<h3 id="messages">The message line</h3>',
             f"<p>{listing.ref(SHOW_MESSAGE)} prints a message over LIFE's digits for ten passes "
             "and then nine spaces, after which the main loop prints LIFE again: BLOCKED when "
             "the knight's way or a drop is blocked, LOCKED at a door he has not the key for, "
             "TOO HEAVY when what he would pick up would make his load 8 or more. Each drawn "
             "by the game's routine with the message number put where the game puts it; and "
             "LIFE printed by the main loop's own lines (START_PASS, in #R$FE47) with LIFE at "
             "42:</p>",
             '<table class="kl-table"><tr>' + "".join(messages) + "</tr></table>",
             "<p>Every character is printed by #R$EBFE, which draws it as an 8 by 8 picture "
             "through the sprite compositor (#R$E3E4) at any pixel, not in character cells, "
             "and in the room's colours: nothing on the screen has colours of its own, since "
             "the whole screen is coloured with one attribute (#R$F0FB). See "
             '<a href="Font.html">the font</a>.</p>',
             "</div>"]
    return "\n".join(lines)


# --------------------------------------------------------------------------
# The font.
# --------------------------------------------------------------------------

def _font_page(data: Data, rig: Rig, listing: Listing, image_dir: Path, code_starts: set[int]) -> str:
    memory = data.memory
    font_dir = image_dir / "font"
    font_dir.mkdir(parents=True, exist_ok=True)
    # All forty characters printed by the game's printer, eight to a row.
    string = []
    for code in range(fd.GLYPH_COUNT):
        string += [0xC8, 8 + 16 * (code % 10), 180 - 16 * (code // 10), code]
    state = rig.printed(rig.game, string)
    cells = []
    for code in range(fd.GLYPH_COUNT):
        x, top = 8 + 16 * (code % 10), 191 - (180 - 16 * (code // 10))
        image = screen_image(state, (x, top, x + 8, top + 8))
        expected = memory[FONT + 8 * code:FONT + 8 * code + 8]
        # Printed black on white: a pixel is ink where it is black, and
        # every other pixel must be the paper.
        drawn = [sum(0x80 >> b for b in range(8) if image.getpixel((b, r)) == INK[:3])
                 for r in range(8)]
        stray = [image.getpixel((b, r)) for r in range(8) for b in range(8)
                 if image.getpixel((b, r)) not in (INK[:3], PAPER[:3])]
        if drawn != list(expected) or stray:
            raise ValueError(f"graphics: character {code} as the printer draws it is not "
                             "its bytes")
        name = f"char{code:02d}.png"
        _scaled(image, CHAR_SCALE).save(font_dir / name)
        shown = fd.glyph_text(code)
        label = {" ": "space"}.get(shown, shown if len(shown) == 1 else "a picture")
        cells.append(f'<td id="char{code}"><img class="kl-thumb" src="{IMAGES}/font/{name}" '
                     f'alt="{_esc(label)}" width="{8 * CHAR_SCALE}" height="{8 * CHAR_SCALE}">'
                     f"<br>{code}<br>{_esc(label)}</td>")
    rows = "".join("<tr>" + "".join(cells[i:i + 10]) + "</tr>" for i in range(0, len(cells), 10))
    # Every string the game prints: the printer's CALLs in the code (the
    # build's code map says which are instructions).
    strings = []
    for call, start, end in fd.inline_strings(memory):
        entry = listing.entry_of(call)
        if entry is None or call not in code_starts:
            continue
        pieces = fd.string_pieces(memory, start, end)
        texts = [what[1:-1] for _, _, what in pieces if what.startswith('"')]
        text = " / ".join(t for t in texts if t.strip())
        if not text:
            if any(texts) and entry in (0xEBF5, CLEAR_THING_BOX):
                text = "<i>one character, written into the string before it is printed</i>"
            elif any(texts):
                text = f"<i>{len(texts[0])} spaces, to rub out what is there</i>"
            else:
                text = "<i>only a move of the printing position</i>"
        else:
            text = _esc(text)
        uses = sorted({memory[a] for a in range(start, end - 1)
                       if memory[a] < fd.GLYPH_COUNT})
        strings.append((call, entry, text, uses, pieces))
    used_codes = set()
    for _, _, _, uses, pieces in strings:
        used_codes |= set(uses)
    # LIFE's digits are any of the ten (#R$FE47 adds 27 to each), the place's
    # 1 to 5 (#R$EC75).
    used_codes |= set(range(27, 37))
    unused = [c for c in range(fd.GLYPH_COUNT) if c not in used_codes]
    string_rows = []
    for call, entry, text, _, _ in strings:
        string_rows.append(f"<tr><td>{listing.routine(entry)}<br><small>${call:04X}</small></td>"
                           f"<td>{text}</td></tr>")
    rom = rig.game[0x3D00:0x4000]
    same_as_rom = [c for c in range(1, fd.GLYPH_COUNT)
                   if bytes(memory[FONT + 8 * c:FONT + 8 * c + 8]) in
                   [bytes(rom[8 * i:8 * i + 8]) for i in range(96)]]
    lines = ['<div class="kl-list">',
             f"<p>{fd.GLYPH_COUNT} characters of 8 by 8 at {listing.ref(FONT)}, one font for "
             "everything the game writes: the title page, LIFE and the place number in the "
             "corner, the message line, GAME OVER and the end of the quest. The game's text is "
             "not ASCII but the characters' numbers: 0 a space, 1-26 the letters, 27-36 the "
             "digits, 37 a full stop, 38 a dash. The printer (#R$EBFE) finds character n at the "
             "font plus eight times n, the top row first, and draws it through the sprite "
             "compositor as an 8 by 8 picture at any pixel of the screen, replacing what was "
             "under it; the string follows the CALL, with $C8 and an x and a y to move and $A4 "
             "to end. There is no lower case. "
             + (f"{_plural(len(same_as_rom), 'character')} of the font "
                f"{'is' if len(same_as_rom) == 1 else 'are'} the ROM's own ("
                + ", ".join(fd.glyph_text(c) for c in same_as_rom) + ")"
                if same_as_rom else "None of the characters is the ROM's (compared at this build)")
             + ".</p>",
             "<p>Printed here by the game's own PRINT, from a CALL with a string of all forty, "
             "each character at its own place, on a screen coloured black ink on white paper "
             "(in the game they take the room's colours); each was checked against its "
             "bytes:</p>",
             '<table class="kl-table">' + rows + "</table>",
             "<p>Character 39 is not a letter but a small round picture, a curl inside a ring; "
             + (", ".join(f"{c} ({_esc(fd.glyph_text(c)) if c != 39 else 'the picture'})"
                          for c in unused) + " are printed by nothing"
                if unused else "every character is printed somewhere")
             + " (read from every string after a CALL to the printer, and from the code that "
             "prints LIFE's digits and the place's).</p>",
             '<h3 id="swedish">The Swedish letters</h3>',
             "<p>The font stops at Z, but the game carries the three letters Swedish has after "
             "it, &Aring;, &Auml; and &Ouml;, capital and small, in eight characters where the "
             "textures are, as textures 22 and 23 (see "
             '<a href="Textures.html#not-patterns">the textures</a>). They are drawn in the '
             "ROM's style, not in this font's, and nothing prints them.</p>",
             '<h3 id="strings">Every string</h3>',
             "<p>The strings after the game's CALLs to the printer, found by searching the code "
             "for the CALL and read the way the printer reads them; a / is a move of the "
             "printing position. The digits of LIFE and the place's number are put into "
             "strings of one character as they are printed (#R$EBF5, #R$EC75).</p>",
             '<table class="kl-table"><tr><th>Routine</th><th>Text</th></tr>']
    lines += string_rows + ["</table>", "</div>"]
    return "\n".join(lines)


# --------------------------------------------------------------------------
# The title page.
# --------------------------------------------------------------------------

def _title_page(data: Data, rig: Rig, listing: Listing, image_dir: Path) -> str:
    shots = {}
    for name, memory in (("loading", rig.tape), ("title", rig.title), ("gameover", rig.game_over),
                         ("failed", rig.failed), ("succeeded", rig.succeeded)):
        image = screen_image(memory)
        _scaled(image, SCREEN_SCALE).save(image_dir / f"screen_{name}.png")
        shots[name] = _img(f"{IMAGES}/screen_{name}.png", image, name, SCREEN_SCALE, "kl-scene")
    # Room 79 on its own, drawn and coloured the way the title routine does.
    simulator = rig.simulator(rig.game)
    simulator.memory[ROOM] = 79
    rig.call(simulator, DRAW_CURRENT_ROOM, "room 79")
    rig.call(simulator, ATTRI, "its colours")
    image = screen_image(simulator.memory)
    _scaled(image, SCREEN_SCALE).save(image_dir / "screen_room79.png")
    shots["room79"] = _img(f"{IMAGES}/screen_room79.png", image, "Room 79", SCREEN_SCALE,
                           "kl-scene")
    title_room = data.room_direct[78]
    # The doors that lead to room 81: +13 of a door's record is the room
    # behind it, +14 its key (#R$F7C4).
    memory = data.memory
    ways = [(room, memory[address + 6]) for address, length, room, kind
            in fd.object_records(memory) if kind >= fd.LARGE_FIRST and memory[address + 5] == 81]
    ways_text = "; ".join(f"from room {room}" + (f", with thing {key} as its key" if key else "")
                          for room, key in ways) or "by no door"
    lines = ['<div class="kl-list">',
             "<p>The game's first screen is the tape's own loading screen, which stays up while "
             "the loading tune plays (#R$C000) until a key is pressed. It was loaded with the "
             "game, a line at a time in the loader's own order, and is shown here from the "
             "snapshot the build makes of the tape:</p>",
             shots["loading"],
             '<h3 id="title">The title page</h3>',
             f"<p>The title page is a room. {listing.ref(TITLE_SCREEN)} puts 79 in ROOM, draws it "
             "with the same interpreter as every other room (#R$E55B) -- the banner is its lines "
             f"and {_plural(len(title_room['fills']), 'fill')} ("
             + ", ".join(f'<a href="Textures.html#texture{t}">texture {t}</a>'
                         for t in title_room["fills"])
             + f"), in the colour of its record -- colours the screen (#R$F0FB), and prints the "
             f"words with {listing.ref(TITLE_PAGE_TEXT)}, one string for the printer with a "
             "move before each line; then \"9-JOY\" (this release's Kempston joystick, turned "
             "on and off with 9) and the wait for a key. Room 79 drawn and coloured on its own, "
             "by the game's routines in SkoolKit's simulator, and the title page as the game "
             "shows it, read from the screen where it waits for the key (#R$F0D2):</p>",
             shots["room79"], shots["title"],
             "<p>The arrows beside the keys are the room's lines too. The keys are the "
             "keyboard's rows: Y to P, H to ENTER, Q to T and A to G walk, one row each way; "
             "SYMBOL SHIFT and SPACE jump, B to M fight, X to V pick up, CAPS SHIFT and Z drop, "
             "1 to 5 choose a carried place and 6 and 7 use what is in it (#R$F309, "
             "#R$FE47).</p>",
             '<h3 id="gameover">GAME OVER, and the end of the quest</h3>',
             "<p>The two other screens between games are made the same way. When LIFE runs "
             "out, room 1 is drawn and GAME OVER printed over it (#R$F065). The end of the "
             f"quest is room 81, reached through a door ({ways_text}: read from the object "
             "table), where #R$FD20 prints the verdict: "
             "success if one of the five things carried is number 5 in the object table (the "
             "thing that lies in room 33), failure otherwise; then #R$DFF2's two lines about "
             "the quest going on. Read from the screen of the game run in the simulator: LIFE "
             "set to nought in the first room; the knight sent into room 81 with nothing; and "
             "sent there with the thing from room 33 (the build's own sessions):</p>",
             shots["gameover"], shots["failed"], shots["succeeded"],
             "</div>"]
    return "\n".join(lines)


# --------------------------------------------------------------------------
# Together.
# --------------------------------------------------------------------------

def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    """Draw the pictures into html_dir/images/graphics and return the
    Textures, Parts, Templates, Sprites, Panel, Font and TitlePage sections."""
    import build_fairlight as bf

    memory = bf.game_memory(snapshot)
    listing = Listing(snapshot.with_name("fairlight.skool"))
    frames = bf.sprite_frames(snapshot, snapshot.with_name("fairlight.map"))
    data = Data(memory, frames)
    image_dir = html_dir / "images" / "graphics"
    image_dir.mkdir(parents=True, exist_ok=True)
    log("  graphics: starting a game to draw with...")
    rig = Rig(snapshot)
    # The sprites must be as the tape has them before any are drawn: a
    # creature turned round in the game so far would have them mirrored.
    for address, width, height, _ in frames:
        length = fd.sprite_length(width, height)
        if rig.game[address:address + length] != list(memory[address:address + length]):
            raise ValueError(f"graphics: the sprite at ${address:04X} is not as the tape has it")
    log("  graphics: textures...")
    textures = _textures_page(data, rig, listing, image_dir)
    log("  graphics: parts...")
    parts = _parts_page(data, rig, listing, image_dir)
    log("  graphics: sprites and templates...")
    groups = SpriteGroups(memory, data)
    sprites, anchors = _sprites_page(data, rig, listing, image_dir, groups)
    templates, _ = _templates_page(data, rig, listing, image_dir, anchors)
    log("  graphics: the panel, the font and the title page...")
    panel_part = max(range(1, fd.PART_COUNT + 1), key=lambda p: len(data.part_rooms[p]))
    panel = _panel_page(data, rig, listing, image_dir, panel_part)
    code_map = snapshot.with_name("fairlight.map").read_bytes()
    code = {a for a, flag in enumerate(code_map) if flag & 1}
    font = _font_page(data, rig, listing, image_dir, code)
    title = _title_page(data, rig, listing, image_dir)
    sections = {"Textures": textures, "Parts": parts, "Templates": templates,
                "Sprites": sprites, "Panel": panel, "Font": font, "TitlePage": title}
    sections = {name: listing.check_links(body) for name, body in sections.items()}
    if listing.missing:
        log("  graphics: no entry at " + ", ".join(f"${a:04X}" for a in sorted(listing.missing))
            + " -- linked as plain text")
    for name, body in sections.items():
        for number, line in enumerate(body.split("\n"), 1):
            if line.startswith((";", "[")):
                raise ValueError(f"{name}, line {number}: a ref line may not start with "
                                 f"{line[0]!r}")
        if re.search(r"#[0-9A-Fa-f]{6}\b", body):
            raise ValueError(f"{name}: a colour written with a bare # would be read as a macro")
    log(f"  graphics: {fd.TEXTURE_COUNT} textures, {fd.PART_COUNT} parts, "
        f"{len(data.types)} templates and {len(anchors)} sprites drawn by the game's code")
    return sections
