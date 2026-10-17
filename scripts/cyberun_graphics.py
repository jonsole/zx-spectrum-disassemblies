"""Cyberun's graphics pages -- the landscape's pieces, every sprite, the
object types, the add-ons and the rocket, and the panel -- drawn from the
game at build time.

build_cyberun.py --html calls build(), which draws the pictures into
html_dir/images/graphics/ and returns five ref sections: Pieces, Sprites,
ObjectTypes, AddOns and Panel. Nothing here is committed output: the pictures
are the game's, and so are the tables the pages are made from. What is
committed is the prose, the addresses, and the code that runs the game to
draw them.

Everything is drawn by the game's own code, run in SkoolKit's simulator (the
build's Machine), on a game started and run to its menu so that the start-up
has built the shift tables, the landscape pieces' shifted copies and the
bit-reversal table:

- A landscape step by its blitter, from the four shift tables (#R$E37D and
  the three after it): SP on the step's graphic and variant, A its row pairs,
  run to the blitter's JP to after_step_drawn.
- An object's picture by the sprite compositor: clear_sprite_pair, the end
  of prepare_draw (the new image's header, clip and row routine) and
  draw_object_images, which jumps into draw_sprite_pair -- the sequence every
  object goes through every pass.
- The ship and what hangs from it by the direct drawer (draw_direct_pair),
  the ship's picture first built by build_ship_sprite into its buffer.
- The special beam by its own frame expander and draw_beam; the panel's
  bitmaps by draw_bitmap; the font by print_string.
- The menu, the panel in play and the planet-secured screen are read off the
  screen of a running game, the last staged with the build's own restart.

Two things are drawn here from their bytes, and the pages say so: the ore
rows (only ever copied into the ship's picture) and the add-ons' masks.
"""
from __future__ import annotations

import html
import re
from pathlib import Path

IMAGES = "images/graphics"
TRAP = 0x0000               # a return address the game never reaches
STACK = 0x5B70              # below the game's stack top (#R$5B7A)
TIME_LIMIT = 3500000 * 5    # five seconds of the machine's time for any one call
SCRATCH = 0xF800            # the sprite buffer: text records for the printer go here

# The object tables (see their entries).
OBJECT_HANDLERS = 0xAF25    # twelve words, types $13-$1E
FIRST_TYPE = 0x13
TYPE_COUNT = 12
GRAPHIC_LISTS = 0xAF3D      # 31 words, graphic numbers 0-$1E
GRAPHIC_COUNT = 31
DIRECT_GRAPHICS = list(range(1, 12)) + list(range(0x0E, 0x13))   # words that point at a graphic
HEIGHT_FIRST = range(0x0E, 0x13)                                   # the jets
ADDON_GRAPHICS = 0xAF95     # eleven words: add-ons 1-11
ADDON_PLACES = 0xAFD7       # nine words: where each goes in the ship's picture
ADDON_COUNT = 9
SMALL_OBJECT_EFFECTS = 0x944C
CONTACT_EFFECT = 0x8E2C
DEFAULT_EFFECT = 0x8D9D     # LD A,$50 in update_objects: the effect a routine does not set
WAVE_TABLE = 0x990A         # ten kinds of four bytes: type, flags, frame byte, frame range
WAVE_KINDS = 10
OBJECT_KIND_FLAGS = 0xE0FD  # 17 kinds: bits 5-7 the shot kind, bit 4 animated
OBJECT_PART_PAIRS = 0xE10E  # an animated kind's frame byte and frame range
OBJECT_KIND_BYTES = 0xE205  # 17 kinds: the two colours
KIND_COUNT = 17
MAP_OBJECT_KINDS = 0x5C94
MAP_OBJECT_COUNT = 290
TYPE_0D, TYPE_1B, TYPE_1C, TYPE_1E = 0x0D, 0x1B, 0x1C, 0x1E
ROCKET_PART_TABLE = 0x96B0  # five bytes a part: flags, drawn x, line, X and Y offsets
ROCKET_PARTS = 8
TANK_PART = 6
TANK_FULL_FRAME = 8
BEAM_FRAMES = 0xB8CF        # six words: the special beam's frame cycle
BEAM_FRAME_COUNT = 6
ORE_ROWS = 0x7721           # 2 bytes a row, 18 rows, no header
ORE_FULL = 18
SPRITES_START, SPRITES_END = 0x731F, 0x8347
SLAB, SPIRE = 0x7436, 0x74E7

# The routines run to draw.
CLEAR_SPRITE_PAIR = 0xA2EA
PREPARE_DRAW_TAIL = 0xADB8  # CALL new_sprite_header / JP set_new_sprite
DRAW_OBJECT_IMAGES = 0xAD1B
NEW_X, NEW_Y = 0xA1D5, 0xA1D6
DISSOLVE_STEP = 0xA302
DRAW_DIRECT_PAIR = 0xA59F
DIRECT_ROWS_OLD, DIRECT_ROWS_NEW = 0x5C1C, 0x5C1D
DIRECT_DRAW_ROW = 0xA678    # width 6; each narrower width 5 bytes on
DIRECT_DRAW_MIRRORED = 0xA7D6   # width 6; each narrower width 7 bytes on
BIT_REVERSE_PAGE = 0xF9
PIXEL_TO_SCREEN = 0xA149
DRAW_BITMAP = 0xC96F
PRINT_STRING = 0xA115
NEW_BEAM_FRAME = 0xB8B5
DRAW_BEAM = 0xB336
SHOT_RECORD = 0xB37A        # the first shot record, borrowed to draw the beam
BEAM_CELLS = 8
BUILD_SHIP = 0xAFE9
SHIP_PICTURE = 0xF6B9
SHIP_PICTURE_BYTES = 306    # 50 rows of 6, and the row past it (#R$F7E5)
SHIP_HEIGHT = 0xC1A9
SHIP_ROWS = 50               # the buffer's rows
SHIP_GRAPHIC = 0xC1AA
SHIP_SCREEN_X = 0xC902
SHIP_SCREEN_Y = 0xC903
SHIP_LINE = 0x5C38
ADDON_SLOTS = 0xF5EE
PART_CARRIED = 0xF601
ORE = 0xC905
SHIP_RECORD = 0xC8E5
PART_BEING_FITTED = 0xC904
TOGGLE_CARRIED_PART = 0xAA37
ORE_REDRAW = 0xA8D9       # the entry build_ship_sprite uses
MAP_REBUILD = 0x5C3C

# The landscape.
SHIFT_TABLES = ((0, 0xE37D), (2, 0xE2BD), (4, 0xE2FD), (6, 0xE33D))
PIECE_SHAPES = 0xE3BD
GRAPHIC_OFFSETS = 0xCCBF
BUILD_SHIFTED_PIECES = 0xF7EB
BUILD_SHIFTED_END = 0xF856
SHIFT_SLOPE_PIECE, SHIFT_FLAT_PIECE = 0xF939, 0xF8E2
AFTER_STEP_DRAWN = 0xD711   # every blitter but the flat one ends with JP here
FLAT_STEP_DONE = 0xD714     # the flat blitter comes back to the second instruction
FLAT_BLITTER = 0xE24D
FLAT_JRS = (0xE25A, 0xE25E, 0xE262)   # its three patchable displacements: 0 draws all
CAP_OFFSET, CAP_SIZE, CAP_COUNT = 0x24, 12, 4
FLAT_COPY_BYTES = 84        # 28 rows of 3 bytes a shifted flat copy

# The screens.
MENU_RECORD_COUNT = 12

INKS = [(0, 0, 0), (0, 0, 0xD7), (0xD7, 0, 0), (0xD7, 0, 0xD7),
        (0, 0xD7, 0), (0, 0xD7, 0xD7), (0xD7, 0xD7, 0), (0xD7, 0xD7, 0xD7)]
BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF),
          (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0), (0xFF, 0xFF, 0xFF)]
COLOUR_NAMES = ["black", "blue", "red", "magenta", "green", "cyan", "yellow", "white"]
WHITE = (0xFF, 0xFF, 0xFF, 0xFF)
CLEAR = (0, 0, 0, 0)

# Register numbers in SkoolKit's simulator.
REGISTERS = {"A": 0, "F": 1, "B": 2, "C": 3, "D": 4, "E": 5, "H": 6, "L": 7,
             "IXh": 8, "IXl": 9, "IYh": 10, "IYl": 11, "SP": 12}
PAIRS = {"BC": ("B", "C"), "DE": ("D", "E"), "HL": ("H", "L"),
         "IX": ("IXh", "IXl"), "IY": ("IYh", "IYl")}

# What each type is, for its heading: names by appearance and behaviour.
TYPE_NAMES = {
    0x13: "the clouds", 0x14: "the rotor craft", 0x15: "debris",
    0x16: "the saucer", 0x17: "the eye pod", 0x18: "the pillar",
    0x19: "the tough attacker", 0x1A: "the dome", 0x1B: "the animated ground objects",
    0x1C: "bullets, pick-ups and wreck pieces", 0x1D: "rocks and comets",
    0x1E: "a rocket part falling into place",
}
TYPE_SAYS = {
    0x13: "Drifts with the sky and cannot be shot: the wave table gives it bit 5 of +$10, "
          "already shot. Touching one halves each of the ship's speeds that runs the "
          "cloud's way (#R$8F1E). Clouds have records 7 and 8 to themselves (#R$8792) and "
          "come through the wave table into records 0-3 too; about one in eight is the big "
          "cloud, which counts twice in the load, and a white one now and then drops a "
          "pellet (#R$8813).",
    0x14: "Waits, then homes on the ship for good, steering towards it every pass "
          "(#R$97FF). Worth 250. Only once both jets are fitted does the wave table reach "
          "it.",
    0x15: "What a shot attacker becomes (#R$9035), and four pieces of the ship's wreck "
          "(#R$8CB2): it flies a loop from #R$9873, mirrored by its quarter, and is "
          "harmless.",
    0x16: "Homes on the ship like the rotor craft. Worth 200; with the rotor craft, the "
          "wave table's reward for fitting both jets.",
    0x17: "Turns at the ship, aiming again every 10 to 25 passes (#R$9837). Worth 150.",
    0x18: "Drifts at random (#R$984D). Worth 100.",
    0x19: "Takes 14 hits (#R$94A8), now and then stopping dead or homing on the ship, and "
          "fires a dash left or right. Worth 75 a hit. Once worn down the special beam "
          "destroys it, and it gives the ore tank one or two units of ore.",
    0x1A: "Drifts at random. Worth 90.",
    0x1B: "Never in the sky. Its frame list is the animated ground objects' (#R$E114), "
          "and the update table's word for it points at that list, not at code: harmless, "
          "since only sky objects are run through the table.",
    0x1C: "Thrown by the ground objects and fired by the clouds and the tough attacker "
          "(#R$882B), and five of them fly out of the ship's wreck. What touching one does "
          "goes by its frame (#R$944C, read at #R$9457): the table below.",
    0x1D: "A meteor shower's rocks and comets (#R$87F5): aimed across the ship, they "
          "damage it and die on contact, and explode on the landscape. Worth 350.",
    0x1E: "A rocket part let go over the rocket's place falls into its slot without "
          "testing the landscape (#R$9724); touching it only pushes. See "
          '<a href="AddOns.html#parts">the rocket parts</a>.',
}
# The contact-effect bits (#R$8E2D), bit 7 first.
EFFECT_BITS = [(0x80, "slows the ship"), (0x40, "damages"), (0x20, "refuels"),
               (0x10, "pushes"), (0x08, "is collected"), (0x04, "drains fuel"),
               (0x02, "gives a life"), (0x01, "is destroyed")]
# The shot kinds a ground object throws (bits 5-7 of #R$E0FD), as #R$882B
# makes them.
SHOT_KINDS = {1: "bullets; one in eight the shield ring, and now and then an extra life",
              2: "the refuel pick-up, straight up", 3: "pellets, straight down",
              4: "a spray upwards", 5: "the fuel thief, sprayed upwards",
              6: "a spray, downwards from high up"}
# What some ground kinds are for, from the code that treats them apart.
KIND_ROLES = {
    6: "a generator of the flickering beams: destroying it with the special beam switches "
       "off the beams in its row and half of the world (#R$ABA8, #R$AC08)",
    7: "a generator of the flickering beams, as kind 6",
    8: "an ore deposit: one unit to the tank (#R$A8A5)",
    9: "an ore deposit: one unit",
    0x0A: "an ore deposit: two units",
    0x0B: "the one kind the special beam passes over (#R$ABA8)",
    0x0E: "the refuel pad: fills the tank and repairs the ship (#R$A8F4)",
}
# The graphic numbers below $13: what each is, and its drawer.
LOW_GRAPHICS = [
    ([0], "the homing missile, by its facing (#R$9307)"),
    (range(1, 7), "the ship's trail, bending with its speed across (#R$C4ED)"),
    (range(7, 12), "the stars of the three layers, at an even or odd x (#R$BFE3)"),
    ([0x0C], 'an add-on lying on the planet: its frame is the add-on less one (see '
             '<a href="AddOns.html">the add-ons</a>)'),
    ([0x0D], 'a ground object: its frame is its kind (<a href="#kinds">below</a>)'),
    (range(0x0E, 0x11), "the side jet's three flickering frames (#R$C5FF)"),
    (range(0x11, 0x13), "the lift jet: $12, or $11 while thrusting (#R$C6D2)"),
]
# The add-ons' effects, read from the code that tests each slot.
ADDON_SAYS = {
    1: "The hook: without it no rocket part can be picked up (#R$AAD7).",
    2: "A second hook. It is never picked up: #R$AFE9 sets its slot to twice add-on 1's, so "
       "it comes and goes with the hook. With it the lift jet is not hidden over a box below "
       "(#R$C6D0).",
    3: "The ore tank's picture. Never fitted in a game: its place is never dealt, and the "
       "tank comes as rocket part 6 instead. Fitted here to show where it would hang.",
    4: "The side jet (#R$C5FF), and a top speed across of 4 pixels a pass instead of 2.",
    5: "The lift jet (#R$C6D2), a top climb of 4, and no ceiling: the ship may climb from "
       "page row 5 to row 0, where the stars are (#R$B115).",
    6: "Fuel burned at half the rate (#R$B115).",
    7: "The special beam, fired with the special key while the ship is still (#R$B833).",
    8: "Every other shot a homing missile (#R$B731).",
    9: "Stands on top of the ship, adding 11 rows upwards, and lets it lift the slab and "
       "spire (#R$C1CE).",
}
FLAT_DIRECTIONS = (0, 7)


def _word(memory, address: int) -> int:
    return memory[address] | memory[address + 1] << 8


def _signed(value: int) -> int:
    return value - 256 if value & 0x80 else value


def _esc(text: str) -> str:
    return html.escape(text, quote=False)


def _plural(count: int, word: str, words: str | None = None) -> str:
    return f"{count} {word if count == 1 else (words or word + 's')}"


def _anchor(address: int) -> str:
    return f"sprite{address:04x}"


# --------------------------------------------------------------------------
# The listing: which addresses are entries, and what they are called.
# --------------------------------------------------------------------------

class Listing:
    """Entry starts, labels and titles from cyberun.skool, so that a #R link
    is made only to an entry that exists."""

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

    def name(self, address: int) -> str:
        return self.labels.get(address, f"${address:04X}")

    def title(self, address: int) -> str:
        entry = self.entry_of(address)
        return self.titles.get(entry, "") if entry is not None else ""

    def ref(self, address: int, text: str | None = None) -> str:
        if address in self.titles:
            return f"#R${address:04X}({text})" if text else f"#R${address:04X}"
        return text or f"${address:04X}"

    def routine(self, address: int) -> str:
        """A routine by its label, linked: an address inside an entry is named
        by its own label if it has one, and its entry linked."""
        name = self.labels.get(address, f"${address:04X}")
        if address in self.titles:
            return f"#R${address:04X}({name})"
        entry = self.entry_of(address)
        if entry is None:
            return name
        return f"{name}, in #R${entry:04X}({self.labels.get(entry, f'${entry:04X}')})"

    def place(self, address: int) -> str:
        """An address in data: the address, and the entry it is in."""
        if address in self.titles:
            return f"#R${address:04X}(${address:04X})"
        entry = self.entry_of(address)
        if entry is None:
            return f"${address:04X}"
        return f"${address:04X}, in #R${entry:04X}({self.labels.get(entry, f'${entry:04X}')})"

    def check_links(self, body: str) -> str:
        """Every #R to an address that is not an entry start made plain, and
        noted, so that a page never links to nothing."""
        def fix(match):
            address = int(match.group(1), 16)
            if not self.titles or address in self.titles:
                return match.group(0)
            self.missing.add(address)
            return match.group(2)[1:-1] if match.group(2) else f"${address:04X}"
        return re.sub(r"#R\$([0-9A-F]{4})(\([^()]*\))?", fix, body)


# --------------------------------------------------------------------------
# The game, run to its menu, and the calls into it.
# --------------------------------------------------------------------------

class Rig:
    """The game started and run to its menu in SkoolKit's simulator, so the
    start-up's tables are built; each scene is a fresh copy of that machine."""

    def __init__(self, snapshot: Path):
        import build_cyberun as bc

        self.bc = bc
        self.snapshot = snapshot
        machine = bc.Machine(snapshot)
        machine.play([bc.At("the menu", bc.MENU_LOOP, 600.0, bc.TUNE_KEYS)], "the graphics pages")
        self.memory = bytes(machine.memory)
        self.tracer_class = type(machine.tracer)

    def scene(self) -> "Scene":
        """A copy of the machine at the menu with the screen cleared: black
        pixels, white ink on black paper."""
        from skoolkit import CSimulator
        from skoolkit.simulator import Simulator

        simulator = (CSimulator or Simulator)(list(self.memory),
                                              state={"iff": 0, "im": 1, "tstates": 0})
        simulator.set_tracer(self.tracer_class(simulator))
        memory = simulator.memory
        memory[0x4000:0x5800] = bytes(0x1800)
        memory[0x5800:0x5B00] = bytes([0x07]) * 0x300
        return Scene(simulator)


class Scene:
    def __init__(self, simulator):
        self.simulator = simulator

    @property
    def memory(self):
        return self.simulator.memory

    def call(self, address: int, what: str, stop: int = TRAP, **registers) -> dict:
        """Run from address with the given registers until it returns to the
        trap (or reaches stop), or fail saying where the game went."""
        from skoolkit.simutils import PC, SP, T

        regs = self.simulator.registers
        memory = self.memory
        memory[STACK - 2] = TRAP & 0xFF
        memory[STACK - 1] = TRAP >> 8
        regs[SP] = STACK - 2
        for name, value in registers.items():
            if name in PAIRS:
                high, low = PAIRS[name]
                regs[REGISTERS[high]], regs[REGISTERS[low]] = value >> 8, value & 0xFF
            else:
                regs[REGISTERS[name]] = value
        self.simulator.trace(address, stop, 0, regs[T] + TIME_LIMIT, False,
                             None, None, None, None, None)
        if regs[PC] != stop:
            raise RuntimeError(f"graphics: {what} never reached ${stop:04X} "
                               f"(PC ${regs[PC]:04X})")
        return {name: regs[number] for name, number in REGISTERS.items()}

    def screen_address(self, x: int, y: int) -> int:
        """The game's own pixel_to_screen."""
        regs = self.call(PIXEL_TO_SCREEN, "pixel_to_screen", H=y, L=x)
        return regs["H"] << 8 | regs["L"]

    # The drawers.

    def composite(self, graphic: int, x: int, y: int) -> None:
        """An object's picture as the compositor draws it: a new image and no
        old one, byte-aligned or shifted by x."""
        self.call(CLEAR_SPRITE_PAIR, "clear_sprite_pair")
        self.memory[NEW_X], self.memory[NEW_Y] = x, y
        self.memory[DISSOLVE_STEP] = 0
        regs = self.call(PREPARE_DRAW_TAIL, "the end of prepare_draw", DE=graphic)
        self.call(DRAW_OBJECT_IMAGES, "draw_object_images",
                  B=regs["B"], D=regs["D"], E=regs["E"], IXh=regs["IXh"], IXl=regs["IXl"])

    def direct(self, graphic: int, rows: int, width: int, x: int, y: int,
               mirrored: bool = False) -> None:
        """A picture as the direct drawer draws the ship and what goes with
        it: rows of width bytes from graphic, bottom row at line y, no old
        image; mirrored as when the ship faces left."""
        self.memory[DIRECT_ROWS_OLD] = 0
        self.memory[DIRECT_ROWS_NEW] = rows
        address = self.screen_address(x, y)
        if mirrored:
            self.call(DRAW_DIRECT_PAIR, "draw_direct_pair", HL=address + width - 1, DE=graphic,
                      IX=DIRECT_DRAW_MIRRORED + 7 * (6 - width), B=BIT_REVERSE_PAGE)
        else:
            self.call(DRAW_DIRECT_PAIR, "draw_direct_pair", HL=address, DE=graphic,
                      IX=DIRECT_DRAW_ROW + 5 * (6 - width))

    def bitmap(self, graphic: int, x: int, y: int) -> None:
        self.call(DRAW_BITMAP, "draw_bitmap", H=y, L=x, DE=graphic)

    def text(self, x: int, y: int, attribute: int, codes: list[int]) -> None:
        record = [x, y, attribute, len(codes)] + list(codes)
        self.memory[SCRATCH:SCRATCH + len(record)] = bytes(record)
        self.call(PRINT_STRING, "print_string", DE=SCRATCH)

    def beam(self, frame: int, x: int, y: int) -> None:
        """The special beam at one frame of its cycle, BEAM_CELLS long, by
        new_beam_frame and draw_beam, with the first shot record borrowed."""
        memory = self.memory
        memory[SHOT_RECORD] = 0                    # going right
        memory[SHOT_RECORD + 0x0E] = BEAM_CELLS
        memory[SHOT_RECORD + 0x15] = 0x80 | frame
        regs = self.call(NEW_BEAM_FRAME, "new_beam_frame", IX=SHOT_RECORD)
        self.call(DRAW_BEAM, "draw_beam", B=BEAM_CELLS, D=regs["D"], E=regs["E"],
                  HL=self.screen_address(x, y))

    def build_ship(self, addons, part: int | None = None, ore: int = 0) -> tuple[int, int]:
        """The ship's picture as the game makes it, with these add-ons fitted:
        build_ship_sprite into a cleared buffer; then, for a rocket part, what
        picking one up does -- part_being_fitted set and toggle_carried_part,
        which XORs the part into the bottom rows and makes the picture five
        rows taller; then ore in the tank by load_ore's redraw. Returns the
        picture's first row's address and its height."""
        memory = self.memory
        for n in range(1, ADDON_COUNT + 1):
            memory[ADDON_SLOTS + n - 1] = n if n in addons else 0
        memory[PART_CARRIED] = 0xFF
        memory[ORE] = 0
        memory[MAP_REBUILD] = 0
        memory[SHIP_PICTURE:SHIP_PICTURE + SHIP_PICTURE_BYTES] = bytes(SHIP_PICTURE_BYTES)
        self.call(BUILD_SHIP, "build_ship_sprite", IX=SHIP_RECORD)
        if part is not None:
            memory[PART_CARRIED] = part
            memory[PART_BEING_FITTED] = 0xC0 | part
            self.call(TOGGLE_CARRIED_PART, "toggle_carried_part", IX=SHIP_RECORD)
            memory[PART_BEING_FITTED] = 0
        if ore:
            memory[ORE] = ore
            self.call(ORE_REDRAW, "load_ore's redraw")
        return _word(memory, SHIP_GRAPHIC), memory[SHIP_HEIGHT]

    def blit(self, blitter: int, graphic: int, pairs: int, column: int, y: int) -> None:
        """One landscape step by its blitter: SP on its graphic, A its row
        pairs, HL the screen address; to the blitter's jump back into
        after_step_drawn."""
        flat = blitter == FLAT_BLITTER
        if flat:
            for jr in FLAT_JRS:
                self.memory[jr] = 0
        address = self.screen_address(column * 8, y)
        self.call(blitter, "a landscape blitter", stop=FLAT_STEP_DONE if flat else AFTER_STEP_DRAWN,
                  A=pairs, HL=address, SP=graphic)

    # Reading the screen back.

    def picture(self, left: int, top: int, width: int, height: int, colours: bool = False,
                ink=WHITE):
        """A rectangle of the screen (pixels): white on clear, or in the
        screen's own colours."""
        return screen_picture(self.memory, left, top, width, height, colours, ink)


def screen_picture(memory, left: int, top: int, width: int, height: int,
                   colours: bool = False, ink=WHITE):
    from PIL import Image

    image = Image.new("RGBA", (width, height), CLEAR)
    pixels = image.load()
    for row in range(height):
        y = top + row
        line = 0x4000 | (y & 0xC0) << 5 | (y & 7) << 8 | (y & 0x38) << 2
        for column in range(width):
            x = left + column
            bit = memory[line + (x >> 3)] & (0x80 >> (x & 7))
            if colours:
                attr = memory[0x5800 + (y >> 3) * 32 + (x >> 3)]
                table = BRIGHT if attr & 0x40 else INKS
                rgb = table[attr & 7] if bit else table[attr >> 3 & 7]
                pixels[column, row] = rgb + (255,)
            elif bit:
                pixels[column, row] = ink
    return image


def _bbox(images) -> tuple[int, int, int, int] | None:
    """The smallest box holding every drawn pixel of every image."""
    box = None
    for image in images:
        found = image.getbbox()
        if found is None:
            continue
        if box is None:
            box = found
        else:
            box = (min(box[0], found[0]), min(box[1], found[1]),
                   max(box[2], found[2]), max(box[3], found[3]))
    return box


def _bytes_picture(memory, address: int, width: int, rows: int, ink=WHITE):
    """Rows of bytes drawn as they lie, the bottom row first: for what the
    game itself never draws on its own (the pages say so)."""
    from PIL import Image

    image = Image.new("RGBA", (width * 8, rows), CLEAR)
    pixels = image.load()
    for row in range(rows):
        for column in range(width):
            byte = memory[address + row * width + column]
            for bit in range(8):
                if byte & (0x80 >> bit):
                    pixels[column * 8 + bit, rows - 1 - row] = ink
    return image


def _img(path: str, image, alt: str, scale: int = 2, css: str = "cy-sprite") -> str:
    return (f'<img class="{css}" src="{path}" alt="{_esc(alt)}" '
            f'width="{image.width * scale}" height="{image.height * scale}">')


def _save(image, image_dir: Path, name: str) -> str:
    image.save(image_dir / name)
    return f"{IMAGES}/{name}"


def _colour_name(nibble: int) -> str:
    return ("bright " if nibble & 8 else "") + COLOUR_NAMES[nibble & 7]


def _two_colours(byte: int) -> tuple[int, int]:
    """+$0D's two colours as prepare_draw takes them: odd passes the low
    nibble, even passes the high, each ink bits 0-2 with BRIGHT bit 3."""
    return byte & 0x0F, byte >> 4


def _colour_rgb(nibble: int) -> tuple:
    return (BRIGHT if nibble & 8 else INKS)[nibble & 7] + (255,)


def _effect_text(value: int) -> str:
    if value == 0xFF:
        return "$FF: the shield (#R$8E2D)"
    if value == 0:
        return "0: harmless"
    words = [what for bit, what in EFFECT_BITS if value & bit]
    return f"${value:02X}: " + ", ".join(words)


# --------------------------------------------------------------------------
# The game's tables, read.
# --------------------------------------------------------------------------

class Data:
    """The tables the pages are made from, read from the snapshot as the
    game's code reads them."""

    def __init__(self, memory, listing: Listing):
        self.memory = memory
        self.lists = [_word(memory, GRAPHIC_LISTS + 2 * g) for g in range(GRAPHIC_COUNT)]
        # A list's length: up to the next list or the next entry, whichever
        # comes first (the lists overlap: #R$9894).
        starts = set(self.lists[g] for g in range(GRAPHIC_COUNT) if g not in DIRECT_GRAPHICS)
        bounds = sorted(starts | set(listing.entries))
        self.frames: dict[int, list[int]] = {}
        for graphic in range(GRAPHIC_COUNT):
            start = self.lists[graphic]
            if graphic in DIRECT_GRAPHICS:
                self.frames[graphic] = [start]
                continue
            end = min([b for b in bounds if b > start] + [start + 32])
            count = min((end - start) // 2, 16)
            self.frames[graphic] = [_word(memory, start + 2 * f) for f in range(count)]
        self.handlers = {FIRST_TYPE + t: _word(memory, OBJECT_HANDLERS + 2 * t)
                         for t in range(TYPE_COUNT)}
        self.addons = [_word(memory, ADDON_GRAPHICS + 2 * n) for n in range(11)]
        self.places = [_word(memory, ADDON_PLACES + 2 * n) for n in range(ADDON_COUNT)]
        self.beam_frames = [_word(memory, BEAM_FRAMES + 2 * f) for f in range(BEAM_FRAME_COUNT)]
        self.waves = [list(memory[WAVE_TABLE + 4 * k:WAVE_TABLE + 4 * k + 4])
                      for k in range(WAVE_KINDS)]
        self.kind_flags = list(memory[OBJECT_KIND_FLAGS:OBJECT_KIND_FLAGS + KIND_COUNT])
        self.kind_colours = list(memory[OBJECT_KIND_BYTES:OBJECT_KIND_BYTES + KIND_COUNT])
        self.kind_counts = [0] * KIND_COUNT
        for i in range(MAP_OBJECT_COUNT):
            kind = memory[MAP_OBJECT_KINDS + i] & 0x3F
            if kind < KIND_COUNT:
                self.kind_counts[kind] += 1
        self.small_effects = list(memory[SMALL_OBJECT_EFFECTS:SMALL_OBJECT_EFFECTS
                                         + len(self.frames[TYPE_1C])])
        self.rocket = [list(memory[ROCKET_PART_TABLE + 5 * p:ROCKET_PART_TABLE + 5 * p + 5])
                       for p in range(ROCKET_PARTS)]
        # The jets' pictures are height-first; so are the beam's frames.
        self.height_first = {self.lists[g] for g in HEIGHT_FIRST} | set(self.beam_frames)

    def kind_frames(self, kind: int) -> list[int]:
        """A ground kind's pictures, as #R$E114 sets it up: graphic $0D at its
        kind, or, with bit 4 of its flags, graphic $1B through the frame range
        #R$E10E gives it (the high nibble the first frame, the low the last)."""
        flags = self.kind_flags[kind]
        if flags & 0x10:
            frame_range = self.memory[OBJECT_PART_PAIRS + (flags & 0x0F) + 1]
            return [self.frames[TYPE_1B][f] for f in range(frame_range >> 4, (frame_range & 0x0F) + 1)]
        return [self.frames[TYPE_0D][kind]]

    def contact_effect(self, kind: int) -> int | None:
        """The effect a type's routine leaves in contact_effect: LD A,n or
        XOR A, then LD ($8E2C),A, at its start; or the default update_objects
        loads ($50) if it leaves it alone. None for a type with a table."""
        memory = self.memory
        handler = self.handlers[kind]
        store = [0x32, CONTACT_EFFECT & 0xFF, CONTACT_EFFECT >> 8]
        if memory[handler] == 0x3E and list(memory[handler + 2:handler + 5]) == store:
            return memory[handler + 1]
        if memory[handler] == 0xAF and list(memory[handler + 1:handler + 4]) == store:
            return 0
        if kind == TYPE_1C:
            return None
        return memory[DEFAULT_EFFECT + 1]

    def users(self) -> dict[int, list[tuple]]:
        """Every graphic address and what draws it: (graphic number, frame)
        from the lists, ('addon', n), ('beam', frame)."""
        out: dict[int, list[tuple]] = {}
        for graphic in range(GRAPHIC_COUNT):
            for frame, address in enumerate(self.frames[graphic]):
                out.setdefault(address, []).append((graphic, None if graphic in DIRECT_GRAPHICS
                                                    else frame))
        for n, address in enumerate(self.addons, 1):
            out.setdefault(address, []).append(("addon", n))
        for frame, address in enumerate(self.beam_frames):
            out.setdefault(address, []).append(("beam", frame))
        return out


# --------------------------------------------------------------------------
# Pictures, each drawn once by the game and shared by the pages.
# --------------------------------------------------------------------------

SPRITE_X, SPRITE_Y = 0x10, 0xB0     # byte-aligned, clear of every clip


class Pictures:
    """Every graphic drawn by the routine that draws it in the game, saved
    under images/graphics, by address."""

    def __init__(self, rig: Rig, data: Data, image_dir: Path):
        self.rig, self.data, self.image_dir = rig, data, image_dir
        self.paths: dict[int, str] = {}
        self.images: dict[int, object] = {}
        self.how: dict[int, str] = {}

    def _keep(self, address: int, image, how: str) -> None:
        name = f"sprite{address:04x}.png"
        self.paths[address] = _save(image, self.image_dir, name)
        self.images[address] = image
        self.how[address] = how

    def composite(self, address: int) -> None:
        memory = self.rig.memory
        width, height = memory[address], memory[address + 1]
        scene = self.rig.scene()
        scene.composite(address, SPRITE_X, SPRITE_Y)
        self._keep(address, scene.picture(SPRITE_X, SPRITE_Y - height + 1, width * 8, height),
                   "the compositor (#R$A303)")

    def direct(self, address: int, rows: int, width: int, graphic: int, how: str) -> None:
        scene = self.rig.scene()
        scene.direct(graphic, rows, width, SPRITE_X, SPRITE_Y)
        self._keep(address, scene.picture(SPRITE_X, SPRITE_Y - rows + 1, width * 8, rows), how)

    def bitmap(self, address: int) -> None:
        memory = self.rig.memory
        width, height = memory[address], memory[address + 1]
        scene = self.rig.scene()
        scene.bitmap(address, SPRITE_X, SPRITE_Y)
        self._keep(address, scene.picture(SPRITE_X, SPRITE_Y - height + 1, width * 8, height),
                   "draw_bitmap (#R$C96F)")

    def beam(self, address: int, frame: int) -> None:
        memory = self.rig.memory
        rows = memory[address]
        scene = self.rig.scene()
        scene.beam(frame, SPRITE_X, SPRITE_Y)
        self._keep(address, scene.picture(SPRITE_X, SPRITE_Y - rows + 1, BEAM_CELLS * 8, rows),
                   "the special beam's expander and draw_beam (#R$B8B5, #R$B336)")

    def from_bytes(self, address: int, width: int, rows: int, how: str) -> None:
        self._keep(address, _bytes_picture(self.rig.memory, address, width, rows), how)


def draw_everything(rig: Rig, data: Data, image_dir: Path, log) -> Pictures:
    memory = rig.memory
    pictures = Pictures(rig, data, image_dir)
    users = data.users()
    for address, uses in sorted(users.items()):
        graphics = [u[0] for u in uses if isinstance(u[0], int)]
        if address in data.height_first:
            if any(u[0] == "beam" for u in uses):
                frame = next(u[1] for u in uses if u[0] == "beam")
                pictures.beam(address, frame)
            else:
                # A jet: the height, then lines of a fixed width (#R$C7A3).
                width = 2 if any(g in range(0x0E, 0x11) for g in graphics) else 4
                pictures.direct(address, memory[address], width, address + 1,
                                "the direct drawer (#R$A59F), as #R$C5FF and #R$C6D2 draw the jets")
        elif any(g in range(1, 7) for g in graphics):
            # The trail: plain form, one byte wide, drawn by the direct drawer.
            pictures.direct(address, memory[address + 1], memory[address], address + 2,
                            "the direct drawer (#R$A59F), as #R$C4ED draws the trail")
        elif address in (SLAB, SPIRE):
            pictures.direct(address, memory[address + 1], memory[address], address + 2,
                            "the direct drawer (#R$A59F), as #R$C27F draws the carried load")
        else:
            pictures.composite(address)
    pictures.from_bytes(ORE_ROWS, 2, ORE_FULL, "drawn here from its bytes: the game only copies "
                        "it into the ship's picture (#R$A8A5)")
    log(f"  graphics: {len(pictures.paths)} pictures drawn by the game's own drawers")
    return pictures


# --------------------------------------------------------------------------
# The landscape's pieces.
# --------------------------------------------------------------------------

def _shift_routines(memory) -> list[tuple[int, int, int]]:
    """(graphic, copy, routine) for each stored piece, read from the LD HL /
    EXX / LD HL / CALL (or JP) runs of build_shifted_pieces."""
    found = []
    address = BUILD_SHIFTED_PIECES
    while address < BUILD_SHIFTED_END:
        if (memory[address] == 0x21 and memory[address + 3] == 0xD9 and memory[address + 4] == 0x21
                and memory[address + 7] in (0xCD, 0xC3)):
            copy = _word(memory, address + 1)
            graphic = _word(memory, address + 5)
            routine = _word(memory, address + 8)
            found.append((graphic, copy, routine))
            address += 10
        else:
            address += 1
    return found


def _direction_name(direction: int) -> str:
    base = direction - 7 if 7 <= direction < 14 else direction
    names = {0: "flat", 1: "a gentle slope climbing right", 2: "a 45-degree slope climbing right",
             3: "a steep slope climbing right", 4: "a gentle slope climbing left",
             5: "a 45-degree slope climbing left", 6: "a steep slope climbing left"}
    if direction == 14:
        return "a wall, stepping right"
    if direction == 15:
        return "a wall, stepping left"
    text = names[base]
    if direction == 0:
        return "flat floor"
    if direction == 7:
        return "flat ceiling"
    return text + (", as a ceiling" if direction >= 7 else "")


def _pieces_page(rig: Rig, listing: Listing, image_dir: Path, log) -> str:
    memory = rig.memory
    tape = rig.bc.game_memory(rig.snapshot)
    stored = _shift_routines(memory)
    shapes = [list(memory[PIECE_SHAPES + 3 * r:PIECE_SHAPES + 3 * r + 3]) for r in range(9)]
    tables = {shift: [(_word(memory, table + 4 * d), _word(memory, table + 4 * d + 2))
                      for d in range(16)] for shift, table in SHIFT_TABLES}
    # What each stored graphic is for: the directions whose shift-0 graphic
    # lies in it.
    starts = sorted(g for g, _, _ in stored)

    def stored_of(address: int) -> int | None:
        found = None
        for start in starts:
            if start <= address:
                found = start
        return found

    copies = sorted(c for _, c, _ in stored)

    def copy_of(address: int) -> int | None:
        found = None
        for start in copies:
            if start <= address:
                found = start
        return found

    # Draw: for each direction and shift, the three variants (and a flat
    # piece's four end caps) side by side, each step by its own blitter.
    # The bottom line odd, as every step's is: a row pair never crosses a
    # character row between its two rows (the blitters fix the address up
    # only after each pair).
    gap, bottom = 4, 0xA7    # seven flat steps fit by column 31
    strips: dict[tuple[int, int], object] = {}
    for direction in range(16):
        row = direction if direction < 7 else direction - 7
        rise = shapes[row][2]
        pairs = rise // 2 if rise else 2
        images = {}
        for shift, _ in SHIFT_TABLES:
            blitter, graphic = tables[shift][direction]
            offsets = [memory[GRAPHIC_OFFSETS + 6 * row + 2 * v + (1 if shift else 0)]
                       for v in range(3)]
            if direction in FLAT_DIRECTIONS:
                offsets += [CAP_OFFSET + CAP_SIZE * n for n in range(CAP_COUNT)]
            scene = rig.scene()
            for item, offset in enumerate(offsets):
                scene.blit(blitter, graphic + offset, pairs, 2 + gap * item, bottom)
            images[shift] = scene.picture(0, bottom - 20, 256, 22)
        box = _bbox(images.values())
        for shift, image in images.items():
            strips[(direction, shift)] = image.crop(box) if box else image
    # The flat copies: which of their bytes the start-up wrote, and which
    # came on the tape.
    flat_notes = []
    for graphic, copy, routine in stored:
        if routine != SHIFT_FLAT_PIECE:
            continue
        rows_made = []
        for shift in range(3):
            base = copy + shift * FLAT_COPY_BYTES
            changed = [i for i in range(FLAT_COPY_BYTES) if memory[base + i] != tape[base + i]]
            rows_made.append((min(changed) // 3, max(changed) // 3) if changed else None)
        flat_notes.append((graphic, copy, rows_made))

    lines = ['<div class="kl-list">',
             "<p>The landscape is drawn every pass from pieces: straight runs of identical "
             "steps in one of 16 directions (#R$D0BD). Each step is drawn by a POP blitter "
             "with SP on its graphic, two rows a POP, climbing the screen; its graphic is "
             "stored exactly as the blitter writes it -- the bottom row left to right, the row "
             "above right to left, and so on up. For each of the four fine-scroll positions, "
             "0, 2, 4 and 6 pixels, a table gives every direction a blitter and a graphic: "
             + ", ".join(f"{listing.ref(t)} for shift {s}" for s, t in SHIFT_TABLES)
             + ", chosen each pass by the scroll (#R$CCBD).</p>",
             "<p>Only nine graphics are stored. A ceiling (directions 7 to 13) has graphics of "
             "its own, but a step climbing left is its partner's graphic started one row "
             "later and drawn by a blitter that turns every byte round through the "
             f"bit-reversal table ({listing.ref(0xF900)}): with the zig-zag order, starting a "
             "row later makes every row's bytes arrive the other way round, and reversing "
             "each byte finishes the mirror. Each graphic holds three variants of its step, "
             "one above the other, and #R$CE24 walks a fixed jumble of 0, 1 and 2 along a run "
             "so that a long flat stretch is not one pattern repeated; the offset of each "
             f"variant comes from {listing.ref(GRAPHIC_OFFSETS)}. The two flat graphics carry "
             "four end caps after their variants, drawn at the ends of a run instead of a "
             "variant (#R$D588).</p>",
             "<p>The shifted copies are made at start-up, by #R$F7EB, over bytes that are "
             "zeros on the tape: a slope one byte wider than its graphic, its open side "
             "filled with the ground's checker (#R$F939); a flat piece rotated rather than "
             "shifted, since the ground under it repeats every 24 pixels (#R$F8E2). So the "
             "pictures here are of a game run to its menu in SkoolKit's simulator, after the "
             "start-up: each step is drawn by the blitter its table names, with SP on the "
             "graphic at the variant's offset and A its pairs of rows, and run to the jump "
             "back into after_step_drawn (#R$D711) -- one call of what #R$D672 does for "
             "every step. White is a pixel set; the strips are the three variants left to "
             "right, then, for the flat pieces, the four end caps.</p>",
             '<h3 id="stored">The nine stored graphics</h3>',
             '<table class="kl-table"><tr><th>Graphic</th><th>Directions at shift 0</th>'
             "<th>Shifted copies</th><th>Made by</th></tr>"]
    for graphic, copy, routine in sorted(stored, key=lambda s: s[0]):
        directions = [d for d in range(16) if stored_of(tables[0][d][1]) == graphic]
        lines.append(f"<tr><td>{listing.routine(graphic)}</td>"
                     f"<td>{', '.join(str(d) for d in directions)}</td>"
                     f"<td>{listing.routine(copy)}</td><td>{listing.routine(routine)}</td></tr>")
    lines.append("</table>")
    for graphic, copy, rows_made in flat_notes:
        made = "; ".join(f"shift {2 * (i + 1)}: rows {r[0]} to {r[1]}" if r else
                         f"shift {2 * (i + 1)}: none"
                         for i, r in enumerate(rows_made))
        lines.append(f"<p>{listing.routine(graphic)}'s copies at {listing.routine(copy)}, 28 "
                     f"rows of 3 bytes each: the rows the start-up writes, compared with the "
                     f"tape's bytes in the simulator -- {made}. Those are the three variants "
                     "(4 rows each); the 16 rows after them, the four end caps, came on the "
                     "tape already shifted.</p>")
    def cell(direction: int, shift: int) -> str:
        blitter, graphic = tables[shift][direction]
        image = strips[(direction, shift)]
        path = _save(image, image_dir, f"piece{direction:02d}_{shift}.png")
        return (f"{_img(path, image, f'Direction {direction} at shift {shift}')}"
                f"<br>{listing.routine(blitter)}<br>graphic {listing.place(graphic)}")

    lines += ['<h3 id="flat">The flat pieces</h3>',
              "<p>Directions 0 and 7, the flat floor and the flat ceiling: three bytes wide and "
              "four rows tall, drawn as two pairs of rows, all by the one blitter at every "
              "shift. Each strip is the three variants, then the four end caps, each drawn by "
              "the blitter at its offset (#R$D588 picks a cap's: $24 plus 12 times its "
              "number).</p>",
              '<table class="kl-table"><tr><th>Shift</th>'
              + "".join(f'<th id="direction{d}">{d}: {_esc(_direction_name(d))}</th>'
                        for d in FLAT_DIRECTIONS) + "</tr>"]
    for shift, table in SHIFT_TABLES:
        lines.append(f"<tr><td>{shift} ({listing.ref(table)})</td>"
                     + "".join(f"<td>{cell(d, shift)}</td>" for d in FLAT_DIRECTIONS) + "</tr>")
    lines.append("</table>")
    lines += ['<h3 id="directions">The other 14 directions at the four shifts</h3>',
              "<p>A row a direction: what it is, then, at each shift, its step's three "
              "variants as its blitter draws them, the blitter, and where its graphic starts "
              f"-- the variant's offset is added to that. The run and rise are from "
              f"{listing.ref(PIECE_SHAPES)}. Climbing-left directions at a shift use their "
              "partner's graphic at the opposite shift (2 for 6), started one row on.</p>",
              '<table class="kl-table"><tr><th>Direction</th>'
              + "".join(f"<th>Shift {s} ({listing.ref(t)})</th>" for s, t in SHIFT_TABLES)
              + "</tr>"]
    for direction in range(16):
        if direction in FLAT_DIRECTIONS:
            continue
        row = direction if direction < 7 else direction - 7
        run, _, rise = shapes[row]
        lines.append(f'<tr id="direction{direction}"><td><b>{direction}</b>: '
                     f"{_esc(_direction_name(direction))}<br>run {_signed(run)}, rise {rise}</td>"
                     + "".join(f"<td>{cell(direction, shift)}</td>" for shift, _ in SHIFT_TABLES)
                     + "</tr>")
    lines.append("</table></div>")
    log("  graphics: 16 directions at 4 shifts drawn by their blitters")
    return "\n".join(lines)


# --------------------------------------------------------------------------
# Sprites.
# --------------------------------------------------------------------------

def _uses_text(address: int, uses: list[tuple], data: Data) -> str:
    out = []
    for use in sorted(uses, key=lambda u: u[0] != "addon"):
        what, frame = use
        if what == "addon":
            anchor = f"addon{frame}" if frame <= ADDON_COUNT else "load"
            out.append(f'<a href="AddOns.html#{anchor}">add-on {frame}</a>')
        elif what == "beam":
            out.append(f"step {frame} of the special beam's cycle")
        elif what == TYPE_0D:
            if frame < KIND_COUNT:
                out.append(f'<a href="ObjectTypes.html#kind{frame}">ground kind {frame}</a>')
        elif what == TYPE_1B:
            kinds = [k for k in range(KIND_COUNT) if address in data.kind_frames(k)
                     and data.kind_flags[k] & 0x10]
            out.append(f'type $1B frame {frame} (<a href="ObjectTypes.html#kinds">ground kind'
                       f'{"s" if len(kinds) != 1 else ""} {", ".join(str(k) for k in kinds)}</a>)')
        elif what == 0x0C:
            out.append(f"lying on the planet as type $0C frame {frame}")
        elif what == TYPE_1E:
            part = f"part {frame}" if frame < ROCKET_PARTS else "the ore tank, full"
            out.append(f'<a href="AddOns.html#part{frame}">rocket {part}</a> (type $1E frame {frame})')
        elif what >= FIRST_TYPE:
            out.append(f'<a href="ObjectTypes.html#type{what:02x}">type ${what:02X}</a> frame {frame}')
        else:
            out.append(f'<a href="ObjectTypes.html#graphic{what:02x}">graphic ${what:02X}</a>'
                       + (f" frame {frame}" if frame is not None else ""))
    if address == ORE_ROWS:
        out.append('the ore in the tank (<a href="AddOns.html#part6">part 6</a>)')
    return "; ".join(dict.fromkeys(out)) or "nothing"


def _form(address: int, data: Data) -> str:
    memory = data.memory
    if address == ORE_ROWS:
        return f"16 by {ORE_FULL}, rows only"
    if address in data.height_first:
        rows = memory[address]
        width = 2 if address in data.beam_frames or address in (data.lists[0x0E], data.lists[0x0F],
                                                               data.lists[0x10]) else 4
        return f"{width * 8} by {rows}, height first"
    width, height = memory[address], memory[address + 1]
    text = f"{width * 8} by {height}"
    if address in data.addons[:ADDON_COUNT]:
        after = address + 2 + width * height
        text += ", masked" if memory[after] != 0xFF else ", no mask"
        text += f"; needs height {memory[address - 1]}"
    return text


def _sprites_page(pictures: Pictures, data: Data, listing: Listing, image_dir: Path) -> str:
    memory = data.memory
    users = data.users()
    in_range = sorted(a for a in pictures.paths if SPRITES_START <= a < SPRITES_END)
    others = sorted(a for a in pictures.paths if not SPRITES_START <= a < SPRITES_END)
    # Entries in the range that hold no graphic start of their own: the
    # pictures of the two big add-ons, after their size bytes.
    covered = set()
    for address in in_range:
        covered.add(listing.entry_of(address))

    def row(address: int) -> str:
        image = pictures.images[address]
        entry = listing.entry_of(address)
        names = listing.routine(address)
        title = listing.titles.get(entry, "") if entry is not None else ""
        extra = ""
        if address in (SLAB, SPIRE):
            picture = address + 2
            extra = f"<br>its picture {listing.routine(picture)}"
        if address in data.addons[:ADDON_COUNT]:
            width, height = memory[address], memory[address + 1]
            mask = address + 2 + width * height
            if memory[mask] != 0xFF:
                mask_image = _bytes_picture(memory, mask, width, height)
                path = _save(mask_image, image_dir, f"mask{address:04x}.png")
                extra += ("<br>its mask, drawn here from its bytes: "
                          + _img(path, mask_image, "Mask"))
        return (f'<tr id="{_anchor(address)}"><td>{_img(pictures.paths[address], image, title)}</td>'
                f"<td>{names}<br>${address:04X}{extra}</td><td>{_esc(title)}</td>"
                f"<td>{_form(address, data)}</td><td>{pictures.how[address]}</td>"
                f"<td>{_uses_text(address, users.get(address, []), data)}</td></tr>")

    header = ('<table class="kl-table"><tr><th>Picture</th><th>Graphic</th><th>What it shows</th>'
              "<th>Size and form</th><th>Drawn here by</th><th>Used as</th></tr>")
    lines = ['<div class="kl-list">',
             "<p>Every picture of the things that move, from the rocket's parts at "
             f"{listing.ref(SPRITES_START)} to the last at {listing.ref(0x8303)}, then the "
             "small ones kept elsewhere, the special beam's frames and the panel's bitmaps. "
             "Almost all are in one form: a byte of width in bytes, a byte of height in lines, "
             "then the lines, the bottom line first, with no mask -- everything is drawn "
             "upwards from its bottom line. The add-ons have a byte before them, the height the "
             "ship's picture must have to show them, and a mask after (or $FF for none); the "
             "jets and the beam's frames are height first, with no width byte, their drawers "
             "entered at a fixed width.</p>",
             "<p>Each is drawn here by the routine that draws it in the game, run in "
             "SkoolKit's simulator on a game started and run to its menu: an object's picture "
             "by the compositor -- #R$A2EA, the end of #R$AD48 (the header, the clip and the "
             "row routine) and #R$AD1B, which jumps into #R$A303 -- byte-aligned on a cleared "
             "screen; the ship's parts by the direct drawer #R$A59F; the beam by its own "
             "code. White is a pixel set; no sprite has colours of its own (#R$AE98 paints "
             "the cells an object covers). The table says what uses each: the graphic number "
             f"and frame from {listing.ref(GRAPHIC_LISTS)}, an add-on, a rocket part or a "
             "ground kind.</p>",
             '<p><a href="#sprites">The sprites</a> -- <a href="#small">The small pictures '
             'kept elsewhere</a> -- <a href="#beam">The special beam</a> -- '
             '<a href="#panel">The panel\'s bitmaps</a> -- <a href="Panel.html#font">The '
             "font</a></p>",
             f'<h3 id="sprites">The sprites, {listing.ref(SPRITES_START, f"${SPRITES_START:04X}")} '
             f"to ${SPRITES_END - 1:04X}</h3>", header]
    lines += [row(a) for a in in_range if a not in data.beam_frames]
    lines.append("</table>")
    lines += ['<h3 id="small">The small pictures kept elsewhere</h3>',
              "<p>The missile's two facings, the trail's six bends, the stars, the shield "
              "ring and the attackers' dash, each beside the code that uses it. The trail is "
              "drawn by the direct drawer like the ship, everything else here by the "
              "compositor. The ship icon under each score is frame 8 of type $1C, the extra "
              "life, and the panel draws the same bytes with draw_bitmap.</p>", header]
    lines += [row(a) for a in others if a not in data.beam_frames]
    lines.append("</table>")
    # The special beam.
    cycle = ", ".join(str(sorted(set(data.beam_frames)).index(a)) for a in data.beam_frames)
    lines += ['<h3 id="beam">The special beam</h3>',
              f"<p>Four frames, the cycle {listing.ref(BEAM_FRAMES)} walks running {cycle}: "
              "each a height and a 16-pixel pattern a line. #R$B8B5 expands this pass's frame "
              "into an 8-byte-wide pattern in #R$F880 (#R$B8DB), and #R$B336 ORs as many "
              "cells of it as the beam is long onto the screen, as it does a laser's. Drawn "
              f"here that way at the beam's full length, {BEAM_CELLS} cells, from the first shot "
              "record.</p>", header]
    lines += [row(a) for a in sorted(set(data.beam_frames))]
    lines.append("</table>")
    lines += _panel_bitmaps(pictures, listing)
    lines.append("</div>")
    return "\n".join(lines)


# The panel's bitmaps: (address, what it is), all drawn with draw_bitmap.
PANEL_BITMAPS = [
    (0xC94D, "the frame's ornament on the top and bottom edges (#R$CACB)"),
    (0xC955, "the frame's ornament on the sides (#R$CACB)"),
    (0xCC14, "the frame's corners, the four one after another (#R$CACB, for the panel's frame "
             "and the menu's)"),
    (0xCB66, "the gauge's label, beside it (#R$CA3F)"),
    (0xCBD1, "the gauge's cap at the top of the tube, line $43 (#R$CBAE)"),
    (0xCBDB, "the gauge's cap at its foot, line $BF (#R$CBAE)"),
    (0x870E, "player 1's pointer on the menu (#R$8690)"),
    (0x874F, "player 2's pointer on the menu (#R$8690)"),
    (0xF2E3, "the copyright line's glyphs, two one after the other (#R$F26C)"),
]
CORNER_COUNT = 4
COPYRIGHT_GLYPHS = 2


def _panel_bitmaps(pictures: Pictures, listing: Listing) -> list[str]:
    rig = pictures.rig
    memory = rig.memory
    lines = ['<h3 id="panel">The panel\'s bitmaps</h3>',
             "<p>Byte-aligned bitmaps in the same form, drawn over whatever is there by "
             "#R$C96F, never erased: the frame round the play area (and the menu's, which "
             "uses the same corners and ornaments), the fuel gauge and the menu's pointers. "
             "Each is drawn here by draw_bitmap; the corners and the copyright glyphs follow "
             "one another, so each list is drawn as the game walks it. The ship icon under "
             'each score is <a href="#sprite' + f"{0xC927:04x}" + '">above</a>. See '
             '<a href="Panel.html">the panel and the menu</a> for them in place.</p>',
             '<table class="kl-table"><tr><th>Picture</th><th>Bitmap</th><th>Size</th>'
             "<th>What it is</th></tr>"]
    for address, what in PANEL_BITMAPS:
        count = CORNER_COUNT if address == 0xCC14 else COPYRIGHT_GLYPHS if address == 0xF2E3 else 1
        scene = rig.scene()
        cursor, x, sizes, parts = address, SPRITE_X, [], []
        for _ in range(count):
            width, height = memory[cursor], memory[cursor + 1]
            scene.bitmap(cursor, x, SPRITE_Y)
            parts.append((x, width, height))
            sizes.append(f"{width * 8} by {height}")
            cursor += 2 + width * height
            x += width * 8 + 8
        top = SPRITE_Y - max(h for _, _, h in parts) + 1
        image = scene.picture(SPRITE_X, top, x - 8 - SPRITE_X, SPRITE_Y - top + 1)
        path = _save(image, pictures.image_dir, f"bitmap{address:04x}.png")
        lines.append(f'<tr id="{_anchor(address)}"><td>{_img(path, image, listing.name(address))}</td>'
                     f"<td>{listing.routine(address)}</td><td>{', '.join(sizes)}</td>"
                     f"<td>{what}</td></tr>")
    lines.append("</table>")
    return lines


# --------------------------------------------------------------------------
# The object types.
# --------------------------------------------------------------------------

def _frames_html(addresses: list[int], pictures: Pictures, first: int = 0) -> str:
    cells = []
    for frame, address in enumerate(addresses, first):
        image = pictures.images.get(address)
        if image is None:
            continue
        cells.append(f'<td><a href="Sprites.html#{_anchor(address)}">'
                     f"{_img(pictures.paths[address], image, f'Frame {frame}')}</a>"
                     f"<br>{frame}: ${address:04X}</td>")
    return '<table class="kl-table"><tr>' + "".join(cells) + "</tr></table>"


def _object_types_page(pictures: Pictures, data: Data, listing: Listing, image_dir: Path) -> str:
    memory = data.memory
    lines = ['<div class="kl-list">',
             "<p>Nine 24-byte records at #R$9974 hold what flies in the sky. A record's first "
             "byte is its type, $13 to $1E, and the type is all there is to what a thing is: "
             f"it picks the update routine the object loop (#R$8D42) runs for it every pass, a "
             f"word in {listing.ref(OBJECT_HANDLERS)} ({listing.routine(0xA18D)}), and its list of "
             f"frames, a word in {listing.ref(GRAPHIC_LISTS)}. Bits 0-3 of the record's +$13 pick "
             "the frame (#R$ADBE); #R$910A steps it through the range in +$14 at the rate in "
             "+$13's upper bits. The update routine also leaves a byte in #R$8E2C, the effect "
             f"of touching the ship -- ${memory[DEFAULT_EFFECT + 1]:02X}, damage and push, unless "
             "it says otherwise (#R$8D42) -- which #R$8E2D acts on bit by bit.</p>",
             "<p>The same graphic table serves the numbers below $13: the missile, the trail, the "
             "stars, the jets, and the two kinds of thing lying on the ground, which share the "
             'records\' layout (see <a href="#low">the graphic numbers below $13</a> and '
             '<a href="#kinds">the ground objects</a>). Every frame is drawn by the compositor '
             '(see <a href="Sprites.html">the sprites</a>, where each says what else uses '
             "it). The attackers start through the wave table, " + listing.ref(WAVE_TABLE)
             + ", which gives each kind its type, flags and frames.</p>",
             "<p>" + " -- ".join(f'<a href="#type{t:02x}">${t:02X}</a>'
                                 for t in range(FIRST_TYPE, FIRST_TYPE + TYPE_COUNT))
             + ' -- <a href="#kinds">Ground objects</a> -- <a href="#low">Below $13</a></p>']
    for kind in range(FIRST_TYPE, FIRST_TYPE + TYPE_COUNT):
        handler = data.handlers[kind]
        frames = data.frames[kind]
        list_address = data.lists[kind]
        lines += [f'<div class="kl-item" id="type{kind:02x}">',
                  f"<h3>Type ${kind:02X}: {_esc(TYPE_NAMES[kind])}</h3>"]
        if kind == TYPE_1B:
            routine = (f"none: the word at ${OBJECT_HANDLERS + 2 * (kind - FIRST_TYPE):04X} is "
                       f"{listing.routine(handler)}, its frame list")
        else:
            routine = listing.routine(handler)
        effect = data.contact_effect(kind)
        rows = [("Update routine", routine),
                ("Frames", f"{_plural(len(frames), 'frame')} from {listing.routine(list_address)}")]
        if effect is not None and kind != TYPE_1B:
            rows.append(("Contact effect", _effect_text(effect)))
        waves = [(k, w) for k, w in enumerate(data.waves) if w[0] == kind]
        if waves:
            rows.append(("In the wave table", "; ".join(
                f"kind {k}: top speed {(w[1] & 7) + 1}, frames {w[3] >> 4} to {w[3] & 0x0F}"
                + (", already shot" if w[1] & 0x20 else "") for k, w in waves)))
        lines.append('<table class="kl-table">' + "".join(
            f"<tr><th>{name}</th><td>{value}</td></tr>" for name, value in rows) + "</table>")
        lines.append(f"<p>{TYPE_SAYS[kind]}</p>")
        lines.append(_frames_html(frames, pictures))
        if kind == TYPE_1C:
            lines.append('<table class="kl-table"><tr><th>Frame</th><th>What it is</th>'
                         "<th>Contact effect</th></tr>" + "".join(
                             f"<tr><td>{f}</td><td>{_esc(listing.title(a))}</td>"
                             f"<td>{_effect_text(data.small_effects[f])}</td></tr>"
                             for f, a in enumerate(frames)) + "</table>")
        lines.append("</div>")
    # The ground objects.
    lines += ['<h3 id="kinds">The ground objects</h3>',
              f"<p>The {MAP_OBJECT_COUNT} things lying in the world are a kind each "
              f"({listing.ref(MAP_OBJECT_KINDS)}), brought into four ground records as the view "
              "reaches them (#R$E114). A kind is graphic $0D with the kind as its frame -- or, "
              f"when bit 4 of its byte in {listing.ref(OBJECT_KIND_FLAGS)} is set, graphic $1B, "
              f"animated between the two frames {listing.ref(OBJECT_PART_PAIRS)} names. Its two "
              f"colours, one on odd passes and one on even, are its byte in "
              f"{listing.ref(OBJECT_KIND_BYTES)}; bits 5-7 of its flags are what it throws, one "
              "pass in 16 while on the screen (#R$8820). Ground objects have no contact effect: "
              "the ship bounces off them (#R$A8F4), and only the special beam can destroy them. "
              "The pictures are tinted here with the kind's two colours; the counts are of the "
              "world's table.</p>",
              '<table class="kl-table"><tr><th>Kind</th><th>Pictures</th><th>Colours</th>'
              "<th>Throws</th><th>In the world</th><th>What it is</th></tr>"]
    for kind in range(KIND_COUNT):
        frames = data.kind_frames(kind)
        flags = data.kind_flags[kind]
        odd, even = _two_colours(data.kind_colours[kind])
        cells = []
        for frame_number, address in enumerate(frames):
            base = pictures.images[address]
            for colour in dict.fromkeys((odd, even)):
                tinted = _tint(base, _colour_rgb(colour))
                path = _save(tinted, image_dir, f"kind{kind:02d}_{frame_number}_{colour:x}.png")
                cells.append(f'<a href="Sprites.html#{_anchor(address)}">'
                             f"{_img(path, tinted, f'Kind {kind}')}</a>")
        colours = (_colour_name(odd) if odd == even
                   else f"{_colour_name(odd)} and {_colour_name(even)}, flashing")
        shot = flags >> 5
        throws = f"kind {shot}: {SHOT_KINDS.get(shot, '')}" if shot else "nothing"
        how = ("graphic $1B, animated" if flags & 0x10 else f"graphic $0D, frame {kind}")
        title = "; ".join(dict.fromkeys(listing.title(a) for a in frames))
        role = KIND_ROLES.get(kind, "")
        lines.append(f'<tr id="kind{kind}"><td>{kind}</td><td>{" ".join(cells)}</td>'
                     f"<td>{colours}</td><td>{throws}</td><td>{data.kind_counts[kind]}</td>"
                     f"<td>{_esc(title)} ({how}){': ' + role if role else ''}</td></tr>")
    lines.append("</table>")
    # Below $13.
    lines += ['<h3 id="low">The graphic numbers below $13</h3>',
              "<p>Not sky objects, but numbers in the same graphic table, given to the "
              "records of the shots, the stars, the ship's jets and trail, and the things on "
              "the ground. The trail's, the stars' and the jets' words point at a graphic, not "
              "a list.</p>",
              '<table class="kl-table"><tr><th>Graphic</th><th>Pictures</th><th>What it is</th></tr>']
    for numbers, what in LOW_GRAPHICS:
        numbers = list(numbers)
        if numbers in ([0x0C], [0x0D]):
            pics = f"{_plural(len(data.frames[numbers[0]]), 'frame')} from {listing.routine(data.lists[numbers[0]])}"
        else:
            addresses = [a for g in numbers for a in data.frames[g]]
            pics = _frames_html(addresses, pictures, numbers[0] if len(numbers) > 1 else 0)
        label = (f"${numbers[0]:02X}" if len(numbers) == 1 else f"${numbers[0]:02X}-${numbers[-1]:02X}")
        anchors = "".join(f'<span id="graphic{n:02x}"></span>' for n in numbers)
        lines.append(f"<tr><td>{anchors}{label}</td><td>{pics}</td><td>{what}</td></tr>")
    lines.append("</table></div>")
    return "\n".join(lines)


def _tint(image, rgba):
    from PIL import Image

    out = Image.new("RGBA", image.size, CLEAR)
    pixels, source = out.load(), image.load()
    for y in range(image.height):
        for x in range(image.width):
            if source[x, y][3]:
                pixels[x, y] = rgba
    return out


# --------------------------------------------------------------------------
# The add-ons, the ship and the rocket.
# --------------------------------------------------------------------------

SHIP_X = 0x60               # where the ship stands on the screen (#R$C902)


def _ship_picture(rig: Rig, addons, part: int | None = None, ore: int = 0,
                  mirrored: bool = False, load: bool = False):
    """The ship as build_ship_sprite makes its picture and the direct drawer
    draws it, at its place on the screen; with the slab and spire hanging
    where draw_carried_piece puts them, if asked."""
    scene = rig.scene()
    graphic, height = scene.build_ship(addons, part, ore)
    memory = scene.memory
    bottom = memory[SHIP_SCREEN_Y]
    scene.direct(graphic, height, 6, SHIP_X, bottom, mirrored)
    top = bottom - height + 1
    left, right = SHIP_X, SHIP_X + 48
    if load:
        # draw_carried_piece: the slab 5 bytes wide at x $68, its bottom line
        # $0D above the shot line; the spire 3 wide at x $78, $23 higher.
        line = memory[SHIP_LINE]
        for address, x, y in ((SLAB, 0x68, line - 0x0D), (SPIRE, 0x78, line - 0x0D - 0x23)):
            width, rows = memory[address], memory[address + 1]
            scene.direct(address + 2, rows, width, x, y)
            top = min(top, y - rows + 1)
            bottom = max(bottom, y)
            right = max(right, x + width * 8)
    return scene.picture(left, top, right - left, bottom - top + 1), height, graphic


def _addons_page(rig: Rig, pictures: Pictures, data: Data, listing: Listing,
                 image_dir: Path, log) -> str:
    memory = rig.memory
    bare, bare_height, bare_start = _ship_picture(rig, [])
    bare_path = _save(bare, image_dir, "ship_bare.png")
    every = list(range(1, ADDON_COUNT + 1))
    full, full_height, full_start = _ship_picture(rig, every)
    full_path = _save(full, image_dir, "ship_all.png")
    left, _, _ = _ship_picture(rig, every, mirrored=True)
    left_path = _save(left, image_dir, "ship_all_left.png")
    lines = ['<div class="kl-list">',
             "<p>The ship's picture is not stored: it is built in RAM, in "
             f"{listing.ref(SHIP_PICTURE)}, by {listing.routine(BUILD_SHIP)} at every life and "
             "whenever an add-on is fitted. The buffer is 50 rows of 6 bytes, drawn from its first "
             f"row upwards; the bare ship, {listing.ref(0xC891)}, 14 rows, goes in rows 26 to 39, "
             "and each add-on fitted -- the nine slots from "
             f"{listing.ref(ADDON_SLOTS)}, add-on n's holding n -- is drawn in at its own place "
             f"from {listing.ref(ADDON_PLACES)} by #R$B09C: its mask ANDed on first, unless the "
             "byte after its picture is $FF, then the picture ORed on. Each add-on's graphic in "
             f"{listing.ref(ADDON_GRAPHICS)} has a byte before it, the height the picture must "
             "have to show it; the highest wins (#R$C1A9), and drawing starts that many rows "
             "below row 40 (#R$C1AA). So the add-ons hang below the ship and the sprite grows "
             "downwards, its top staying where it was on the screen -- all but add-on 9, which "
             "stands on top.</p>",
             "<p>Each ship here is built that way: the slots set, the buffer cleared, "
             "build_ship_sprite run in SkoolKit's simulator, and the picture drawn by the direct "
             "drawer (#R$A59F) from where #R$C1AA points, for as many rows as #R$C1A9 says, at "
             "the ship's place on the screen. The add-ons themselves are drawn as they lie on "
             "the planet, type $0C objects through the compositor, the add-on less one as the "
             "frame.</p>",
             '<p><a href="#addons">The add-ons</a> -- <a href="#load">The slab and spire</a> -- '
             '<a href="#parts">The rocket parts</a> -- <a href="#rocket">The rocket</a></p>',
             f"<p>{_img(bare_path, bare, 'The bare ship')} {_img(full_path, full, 'Every add-on')} "
             f"{_img(left_path, left, 'Every add-on, facing left')}</p>",
             f"<p>The bare ship, {bare_height} rows; with all nine add-ons, {full_height} rows; "
             "and the same facing left, drawn right to left through the bit-reversal table by "
             "the mirrored drawer, as #R$BFB8 has it."
             + (f" With add-on 9 the picture is {full_height} rows, its top row past the "
                f"buffer's 300 bytes, in {listing.ref(0xF7E5)}: simulated, as #R$AFE9 reads."
                if (full_start - SHIP_PICTURE) // 6 + full_height > SHIP_ROWS else "") + "</p>",
             '<h3 id="addons">The add-ons</h3>',
             '<table class="kl-table"><tr><th>Add-on</th><th>Lying on the planet</th>'
             "<th>Graphic</th><th>Slot</th><th>In the picture</th><th>What it does</th>"
             "<th>The ship with it</th></tr>"]
    for n in range(1, ADDON_COUNT + 1):
        address = data.addons[n - 1]
        image = pictures.images[address]
        width, height = memory[address], memory[address + 1]
        place = data.places[n - 1] - SHIP_PICTURE
        fitted = [1, 2] if n == 2 else [n]
        ship, ship_height, _ = _ship_picture(rig, fitted)
        ship_path = _save(ship, image_dir, f"ship_addon{n}.png")
        masked = memory[address + 2 + width * height] != 0xFF
        slot = ADDON_SLOTS + n - 1
        lines.append(
            f'<tr id="addon{n}"><td>{n}</td>'
            f'<td><a href="Sprites.html#{_anchor(address)}">'
            f"{_img(pictures.paths[address], image, f'Add-on {n}')}</a></td>"
            f"<td>{listing.routine(address)}<br>{_esc(listing.title(address))}</td>"
            f"<td>{listing.routine(slot)}</td>"
            f"<td>row {place // 6}, byte {place % 6}; height byte {memory[address - 1]}; "
            f"{'masked' if masked else 'no mask'}</td>"
            f"<td>{ADDON_SAYS[n]}</td>"
            f"<td>{_img(ship_path, ship, f'The ship with add-on {n}')}<br>{ship_height} rows"
            + (" (fitted with add-on 1)" if n == 2 else "") + "</td></tr>")
    lines.append("</table>")
    # The slab and spire.
    load, _, _ = _ship_picture(rig, [9], load=True)
    load_path = _save(load, image_dir, "ship_load.png")
    lines += ['<h3 id="load">The slab and spire</h3>',
              f"<p>Add-ons 10 and 11, {listing.routine(SLAB)} and {listing.routine(SPIRE)}, are "
              "never fitted: they lie on the planet as places 9 and 10 of the player's dealt "
              "places, the spire 16 pixels right of and 35 lines above the slab (#R$6113). With "
              "add-on 9 fitted, touching the slab picks both up (#R$F5F7), and the ship carries "
              "them as two pieces drawn on their own by #R$C27F -- the slab 5 bytes wide, the "
              "spire 3 -- until the view comes down to the surface's lowest row, where #R$C1AC "
              "puts them down again, the same distance apart. What carrying them is for does not "
              "show in the code. #R$C27F puts the slab's bottom line 13 lines above the shot "
              "line (#R$5C38), which is 8 below the top of the ship's picture before add-on 9's "
              "rows: so the load rides on top of the ship, on add-on 9, not under it, the spire "
              "16 pixels right of the slab and 35 lines higher. Here they are drawn by the direct "
              "drawer from their pictures, past the size bytes, and then where #R$C27F puts them "
              "over a ship with add-on 9, its picture built and its shot line set by #R$AFE9 "
              "9 (bright white in the game, #R$AF04):</p>",
              "<p>" + " ".join(_img(pictures.paths[a], pictures.images[a], listing.name(a))
                               for a in (SLAB, SPIRE))
              + f" {_img(load_path, load, 'The ship carrying the slab and spire')}</p>"]
    # The rocket parts.
    lines += ['<h3 id="parts">The rocket parts</h3>',
              f"<p>Eight parts, delivered in order: type $1E's frames from "
              f"{listing.ref(0xAF7B)}, the ninth the ore tank full. With the hook fitted the ship "
              "picks up only the part due next (#R$AAD7), and #R$AA37 XORs its graphic into the "
              "bottom rows of the ship's picture, shifted 4 pixels through the shift tables, "
              "five rows taller -- which #R$AFE9 does again whenever it rebuilds the picture "
              "with a part carried. Each ship here is built that way, with add-on 1 and the "
              f"part carried; the tank is shown empty and with {ORE_FULL} units of ore, drawn "
              "into it one row a unit by the tail of #R$A8A5. The offsets are each part's place "
              f"in the rocket from its base, from {listing.ref(ROCKET_PART_TABLE)}.</p>",
              '<table class="kl-table"><tr><th>Part</th><th>Picture</th><th>Graphic</th>'
              "<th>Offset from the base</th><th>Carried</th></tr>"]
    part_frames = data.frames[TYPE_1E]
    for part, address in enumerate(part_frames):
        image = pictures.images[address]
        if part < ROCKET_PARTS:
            ship, _, _ = _ship_picture(rig, [1], part=part)
            ship_path = _save(ship, image_dir, f"ship_part{part}.png")
            carried = _img(ship_path, ship, f"Carrying part {part}")
            if part == TANK_PART:
                tank, _, _ = _ship_picture(rig, [1], part=part, ore=ORE_FULL)
                tank_path = _save(tank, image_dir, "ship_part6_full.png")
                carried += " " + _img(tank_path, tank, "Carrying the full tank")
            x, y = _signed(data.rocket[part][3]), _signed(data.rocket[part][4])
            offset = f"{x}, {y}"
            name = f"{part}"
        else:
            carried = "drawn for part 6 once it is full (#R$9572, #R$9724)"
            offset = f"part {TANK_PART}'s"
            name = f"{part}: the tank, full"
        lines.append(f'<tr id="part{part}"><td>{name}</td>'
                     f'<td><a href="Sprites.html#{_anchor(address)}">'
                     f"{_img(pictures.paths[address], image, f'Part {part}')}</a></td>"
                     f"<td>{listing.routine(address)}<br>{_esc(listing.title(address))}</td>"
                     f"<td>{offset}</td><td>{carried}</td></tr>")
    lines.append("</table>")
    lines += _rocket_section(rig, listing, image_dir)
    lines.append("</div>")
    log("  graphics: the ship built with each add-on and each rocket part")
    return "\n".join(lines)


def _rocket_section(rig: Rig, listing: Listing, image_dir: Path) -> list[str]:
    """The finished rocket on the screen of a running game: a life staged
    inside it with all eight parts built, by the build's own restart, read
    off the screen a pass after the ship has docked."""
    bc = rig.bc
    machine = bc.Machine(rig.snapshot)
    machine.play(bc._start(0)
                 + bc.new_life_at(bc.restart_at(*bc.ROCKET_VIEW, pokes={bc.PARTS_BUILT: 8}))
                 + [bc.Until("the launch", lambda m: m[bc.LAUNCH] != 0, 10.0),
                    bc.At("a pass", bc.PLAY_LOOP, 5.0)]
                 + [bc.At("a pass", bc.PLAY_LOOP, 5.0)] * 3, "the rocket")
    image = screen_picture(machine.memory, 8, 0x18, 224, 160, colours=True)
    path = _save(image, image_dir, "rocket.png")
    machine.play([bc.At("a pass", bc.PLAY_LOOP, 5.0)] * 12, "the rocket")
    rising = screen_picture(machine.memory, 8, 0x18, 224, 160, colours=True)
    rising_path = _save(rising, image_dir, "rocket_rising.png")
    return ['<h3 id="rocket">The rocket</h3>',
            "<p>The eight parts stand at the rocket's place, page column $52 of map row 10, "
            "each at its offset from the base (#R$96AC), drawn in turn by #R$9572 through one "
            "record (#R$9A4C). Here a game is played in SkoolKit's simulator and a life staged "
            "inside the rocket with all eight parts built, by the game's own restart, as the "
            "build's sessions do: the play area as the game drew it a few passes after the ship "
            "docked (#R$96AB set), and a dozen passes later, the rocket rising and the view "
            "climbing with it (#R$B234 flies the ship itself during the launch).</p>",
            f"<p>{_img(path, image, 'The rocket built, the ship docked', css='cy-picture')} "
            f"{_img(rising_path, rising, 'The rocket rising', css='cy-picture')}</p>"]


# --------------------------------------------------------------------------
# The panel, the menu, the planet-secured screen and the font.
# --------------------------------------------------------------------------

FONT_CHARS = 45
FONT_PER_LINE = 15
DOUBLE_PER_LINE = 14


def _font_section(rig: Rig, listing: Listing, image_dir: Path) -> list[str]:
    """The 45 characters printed by print_string, at both sizes."""
    scene = rig.scene()
    cells = []
    for line in range(FONT_CHARS // FONT_PER_LINE):
        codes = list(range(line * FONT_PER_LINE, (line + 1) * FONT_PER_LINE))
        y = 0x30 + 0x10 * line
        scene.text(0x10, y, 0x47, codes)
        for i, code in enumerate(codes):
            cells.append((code, scene.picture(0x10 + 8 * i, y - 7, 8, 8)))
    double_scene = rig.scene()
    rows = []
    for line in range((FONT_CHARS + DOUBLE_PER_LINE - 1) // DOUBLE_PER_LINE):
        codes = list(range(line * DOUBLE_PER_LINE, min(FONT_CHARS, (line + 1) * DOUBLE_PER_LINE)))
        y = 0x2F + 0x18 * line             # an odd line, as #R$A0DB needs
        double_scene.text(0x10, y, 0xC7, codes)
        rows.append(y)
    double = double_scene.picture(0x10, rows[0] - 15, DOUBLE_PER_LINE * 16, rows[-1] - rows[0] + 16)
    double_path = _save(double, image_dir, "font_double.png")
    table = []
    for code, image in cells:
        path = _save(image, image_dir, f"char{code:02d}.png")
        if code < 26:
            shown = chr(ord("A") + code)
        elif code < 36:
            shown = str(code - 26)
        else:
            shown = f"{code}"
        table.append(f"<td>{_img(path, image, shown, 3)}<br>{code}"
                     + (f": {shown}" if code < 36 else "") + "</td>")
    grid = "".join("<tr>" + "".join(table[i:i + FONT_PER_LINE]) + "</tr>"
                   for i in range(0, len(table), FONT_PER_LINE))
    return ['<h3 id="font">The font</h3>',
            f"<p>{FONT_CHARS} characters of seven bytes at {listing.ref(0x9F76)}, the bottom row "
            "first, bit 0 of every row clear for the gap between characters; the eighth line "
            "of the cell is left blank. The codes are the game's own: 0 to 25 the letters, 26 "
            "to 35 the digits (a score digit is printed as $1A plus the digit), then two "
            "spaces either side of the II of the menu's Interface II, a full stop, a dash, and "
            "four pieces of the rule under the menu's title. Each is printed here by #R$A115, the game's printer, from "
            "a text record -- x, y, attribute, count, codes -- written in the sprite buffer; "
            "#R$A0B1 finds a character at the font plus seven times its code.</p>",
            '<table class="kl-table">' + grid + "</table>",
            "<p>Bit 7 of a record's attribute asks for double size: #R$A115 patches the "
            "printer's JR to reach #R$A0DB, which doubles each row's two nibbles to a byte each "
            "through #R$5C84 and writes each on two lines, 16 by 14 pixels and a 2 by 2 block "
            "of attributes -- the menu's title. The same characters, printed that way:</p>",
            f"<p>{_img(double_path, double, 'The font at double size', 2)}</p>"]


def _panel_page(rig: Rig, listing: Listing, image_dir: Path, log) -> str:
    bc = rig.bc
    # The menu, the title tune cut short, a pass later so the pointers stand
    # at their methods.
    machine = bc.Machine(rig.snapshot)
    machine.play([bc.At("the menu", bc.MENU_LOOP, 600.0, bc.TUNE_KEYS), ([], 1.0),
                  bc.At("the menu", bc.MENU_LOOP, 5.0)], "the menu")
    menu = screen_picture(machine.memory, 0, 0, 256, 192, colours=True)
    menu_path = _save(menu, image_dir, "menu.png")
    # The panel in play: a game started and played still for eight seconds,
    # so the gauge has climbed to full, with the no-damage poke (a RET at
    # damage_ship), so the ship icon keeps its white.
    machine = bc.Machine(rig.snapshot)
    machine.play(bc._start(0) + [_no_damage] + bc._alive([([], 1.0)] * 8)
                 + [bc._keep_alive, bc.At("a pass", bc.PLAY_LOOP, 5.0)], "the panel")
    play = screen_picture(machine.memory, 0, 0, 256, 192, colours=True)
    play_path = _save(play, image_dir, "panel.png")
    # The planet secured: a life staged inside the finished rocket; on to the
    # end of the level, read after planet_secured has printed and counted the
    # bonus, before the tune.
    machine = bc.Machine(rig.snapshot)
    machine.play(bc._start(0)
                 + bc.new_life_at(bc.restart_at(*bc.ROCKET_VIEW, pokes={bc.PARTS_BUILT: 8}))
                 + [bc.Until("the launch", lambda m: m[bc.LAUNCH] != 0, 10.0),
                    bc.Until("the rocket gone", lambda m: m[bc.LAUNCH] == 0xFF, 60.0),
                    bc.At("the planet secured", LEVEL_TUNE_CALL, 120.0)], "the planet secured")
    secured = screen_picture(machine.memory, 0, 0, 256, 192, colours=True)
    secured_path = _save(secured, image_dir, "secured.png")
    log("  graphics: the menu, the panel and the planet-secured screen read off the screen")
    lines = ['<div class="kl-list">',
             "<p>Three screens, each read off the screen of the game running in SkoolKit's "
             "simulator, and the font that prints them. Everything on them is drawn from data by "
             "a handful of small routines, all drawing upwards from a bottom row: #R$A115 prints "
             "a text record, #R$C96F copies a bitmap, #R$C991 paints a rectangle of "
             "attributes, and #R$CACB draws a frame from a 17-byte description (see "
             '<a href="Sprites.html#panel">the panel\'s bitmaps</a>).</p>',
             '<p><a href="#menu">The menu</a> -- <a href="#panel">The panel</a> -- '
             '<a href="#secured">The planet secured</a> -- <a href="#font">The font</a></p>',
             '<h3 id="menu">The menu</h3>',
             f"<p>{_img(menu_path, menu, 'The menu', css='cy-picture')}</p>",
             "<p>As #R$F26C leaves it, read at the top of #R$8615 a second after the title tune "
             f"was cut short: the frame from {listing.ref(0xF22A)} (its corners and ticks set "
             "by #R$F26C), the twelve text records of #R$F112 -- the title at double size -- "
             "the copyright line's two glyphs (#R$F2E3) and the rule under the title. Each "
             "player's pointer (#R$870E, #R$874F) is moved a line a pass towards the line of "
             "its control method by #R$8690, at the lines in #R$8704, and drawn over itself with "
             "no erase: its blank lines rub out what it leaves behind. The chosen number of "
             "players flashes white every four passes (#R$8666). A and B choose one or two "
             "players, 1 and 2 step the players' methods, 0 starts (#R$86B9).</p>",
             '<h3 id="panel">The panel</h3>',
             f"<p>{_img(play_path, play, 'The panel in play', css='cy-picture')}</p>",
             "<p>A game started from the menu and played still for eight seconds, so that the "
             "gauge's column has climbed to full, with the no-damage poke (a RET at #R$8F54's "
             "second half, $8F76) so that the ship icon under the score stays white; the "
             "picture is otherwise as the game drew it. "
             "#R$CA3F draws the panel once a life: the score lines in yellow for the player in "
             f"play and red for the other ({listing.ref(0xC9DA)} and the records after it), the "
             "lives, HI and the high score, the ship icon under each score (#R$C927), the frame "
             "round the play area from #R$CA1D, and the fuel gauge's outline and label (#R$CBAE, "
             "#R$CB66). After that only the score, the lives and the gauge change. The gauge's "
             "column moves a line a pass towards the fuel's level by toggling two rows with XOR "
             "(#R$CC77), which leaves it a rounded top; it turns red on two passes in four once "
             "seven tenths of the fuel is used (#R$CAA7). Each hit recolours the ship icon "
             "under the score -- yellow, magenta, then black (#R$8F54) -- and a refuel pad "
             "makes it white again.</p>",
             '<h3 id="secured">The planet secured</h3>',
             f"<p>{_img(secured_path, secured, 'The planet-secured screen', css='cy-picture')}</p>",
             "<p>A game played in the simulator, a life staged inside the rocket with all eight "
             "parts built by the game's own restart, and played on through the docking and the "
             "launch until #R$F52A has called #R$83D6 and is about to play the level's tune. "
             f"The lines are the four records at {listing.ref(0x84A9)}, the finished planet's "
             f"name copied from {listing.ref(0x8459)} into {listing.ref(0x8505)}, and the four "
             f"from {listing.ref(0x8515)} with the next planet's name; the score has had its ten "
             "bonuses of 5000, each with a zap.</p>"]
    lines += _font_section(rig, listing, image_dir)
    lines.append("</div>")
    return "\n".join(lines)


LEVEL_TUNE_CALL = 0xF530
DAMAGE_SHIP = 0x8F76        # damage_ship: a RET here is the no-damage poke
RET = 0xC9


def _no_damage(memory) -> None:
    memory[DAMAGE_SHIP] = RET    # in level_done, after planet_secured: LD DE,level_tune


# --------------------------------------------------------------------------
# Together.
# --------------------------------------------------------------------------

def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    """Draw the pictures into html_dir/images/graphics and return the
    Pieces, Sprites, ObjectTypes, AddOns and Panel sections."""
    listing = Listing(snapshot.with_name("cyberun.skool"))
    image_dir = html_dir / "images" / "graphics"
    image_dir.mkdir(parents=True, exist_ok=True)
    log("  graphics: running the start-up to the menu...")
    rig = Rig(snapshot)
    data = Data(rig.memory, listing)
    pictures = draw_everything(rig, data, image_dir, log)
    sections = {
        "Pieces": _pieces_page(rig, listing, image_dir, log),
        "Sprites": _sprites_page(pictures, data, listing, image_dir),
        "ObjectTypes": _object_types_page(pictures, data, listing, image_dir),
        "AddOns": _addons_page(rig, pictures, data, listing, image_dir, log),
        "Panel": _panel_page(rig, listing, image_dir, log),
    }
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
    log(f"  graphics: {len(pictures.paths)} sprites, 16 piece directions, "
        f"{TYPE_COUNT} object types, {ADDON_COUNT} add-ons and three screens")
    return sections
