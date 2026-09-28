"""Nightshade's animations, as GIFs of the game running its own code.

build_nightshade.py --html calls build(), which writes the GIFs into the
HTML directory and returns the Animations section. Nothing here is committed
output: every frame is the game's own drawing.

Nightshade animates the way Ultimate's Filmation games do: an object's
graphic -- byte 0 of its 16-byte record -- picks both the routine that runs
it every turn (#R$D599) and its sprite (#R$6E9E), so a thing animates by
changing its own graphic. The knight's legs count the low three bits of
theirs round six walking frames, his top copies them, a monster or a sparkle
counts the low two bits of its own round four, and whatever vanishes becomes
graphic 12 and counts to 15.

What is Nightshade's own is that the town is drawn round the knight: he
always stands in the middle of the play area, and every turn the cells
round him are drawn again into a buffer (#R$CF08) and copied to the screen
(#R$E200), so as he walks the town moves under him, and when the town is
turned round (the Z key) it is seen from the other side.

The frames are not put together from the sprites. Each animation is the game
running in SkoolKit's simulator, from the snapshot at $5E00, started the way
the build's sessions start it (build_nightshade.Machine: the menu, 1 for the
keyboard, 0) and put into the cell wanted by the game's own restart: the
cell and the facing go into the start records (#R$CC36), his life is ended
the way a monster ends it -- both his records made the vanishing cloud --
and the game starts the next life there (#R$CBAC), as it does after every
death (build_nightshade._go). Where more is staged than that -- a monster, a
villain or a bonus written into a record, a thing into his hands -- the
function says so, and so does the page. Then the game is run a turn at a
time -- a turn being one pass of the main loop from MAIN_LOOP ($BE71) back to
it: every record's update, the things that happen once a turn, the town and
everything in it drawn into the buffer, the buffer copied to the screen --
and each frame of a GIF is the screen as that turn left it, read from screen
memory.

Nightshade has no wait in its main loop -- interrupts are off throughout, and
nothing paces a turn -- so a turn lasts as long as the work in it. Each frame
is shown for as long as the game took over its turn, counted in T-states in
the simulator at 3.5MHz. The simulator has no memory contention, so the game
runs a little faster here than on a real Spectrum. A frame drawn identically
to the one before is merged into it. Where there are no turns -- the menu,
the screen after a game, the tune at the end -- the screen is read once a
television frame (69,888 T-states), and identical frames merged; in the
ending, where both come, a sample never stops inside the copy of the buffer
to the screen, so no picture is half of one turn and half of the next.
"""
from __future__ import annotations

import html
import re
from pathlib import Path

import build_nightshade as bn

SKOOL = bn.OUT_DIR / "nightshade.skool"
TSTATES_PER_SECOND = 3_500_000
T_STATES_PER_MS = 3500
TV_FRAME = 69_888                 # T-states in a 48K Spectrum's frame
FLASH_FRAMES = 16                 # the ULA swaps FLASH cells every 16 frames
TURN_LIMIT = 30 * TSTATES_PER_SECOND   # a turn longer than this is a hang

# The game (see the entries).
MAIN_LOOP = bn.MAIN_LOOP          # where each turn begins
END_OF_TURN = 0xBECD              # the buffers to the screen (#R$E200), then round again
SPAWNS = 0xBE9B                   # the CALL of #R$C5CE: every update done, nothing new yet
MENU_LOOP = bn.MENU_LOOP
VARIABLES = 0xBBAA                # RANDOM, the first of the variables
RECORDS = bn.KNIGHT               # 23 records of 16 bytes
RECORD_SIZE = 16
RECORD_COUNT = 23
RECORDS_END = bn.RECORDS_END
GRAPHICS = 0x6E9E                 # graphic number -> sprite (#R$E353)
UPDATES = 0xD599                  # graphic number -> update routine
TURNS = 0xBBB2
VIEW = bn.VIEW
LIVES = bn.LIVES
HITS = bn.HITS
ARRIVING = bn.ARRIVING
HERE = 0x70                       # ARRIVING once he has appeared (#R$DA7A)
ARRIVE_FROM = 0x28                # ARRIVING at a new life (#R$CBAC)
ARRIVE_END = 0x4C                 # ...and the count that ends it (#R$DA7A)
CARRIED = bn.CARRIED
SCORE = bn.SCORE
TOP_SPEED = 0xBBBE
SPEED_TIME = 0xBBF5
FLASH = 0xBBFB                    # the play area's paper this turn (#R$D847)
LAST_FLASH = 0xBBFC               # ...kept at the end of the turn, when FLASH is cleared
GAME_OVER = 0xCC56
ENDING = bn.ENDING
START_RECORDS = 0xCC36            # the knight's two records at a new life
START_FACING = START_RECORDS + 6
MONSTER_TEMPLATE = 0xCE79         # what a monster starts as (#R$CDE8)
ENDING_RECORDS = 0xCCE4           # graphic, x and y for each of ten (#R$CC56)
VANISH = bn.VANISH                # 12-15: the cloud (#R$D7D8)

# The records, by index from KNIGHT.
LEGS, TOP = 0, 1
ANTIBODY, ANTIBODY2 = 2, 3
FINDS = 4                         # 4-7; a dead villain's sparkles too
BONUS = 8
OBJECTS = 9                       # 9-12
VILLAINS = 13                     # 13-16
MONSTERS = 17                     # 17-22

# Facing, bits 6-7 of +6 (#R$DB89): $00 +V, $40 +U, $80 -V, $C0 -U.
FACINGS = [(0x00, "+V"), (0x40, "+U"), (0x80, "-V"), (0xC0, "-U")]

# The screen: the game's x and y (y counting up, #R$E3D9) and the display.
# Buffer byte 2 goes to column 7 (#R$E148): the screen's x is the game's
# plus 24, rounded down to a byte; the game's y 72 is line 127.
PLAY_AREA = (56, 16, 232, 128)
WHOLE_SCREEN = (0, 0, 256, 192)
SCREEN = 0x4000
SCREEN_END = 0x5B00

# The Spectrum's colours, normal and BRIGHT, for the pictures and the GIF
# palette.
SPECTRUM = [(0, 0, 0), (0, 0, 0xD7), (0xD7, 0, 0), (0xD7, 0, 0xD7),
            (0, 0xD7, 0), (0, 0xD7, 0xD7), (0xD7, 0xD7, 0), (0xD7, 0xD7, 0xD7)]
SPECTRUM_BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF),
                   (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0), (0xFF, 0xFF, 0xFF)]
PALETTE = SPECTRUM + SPECTRUM_BRIGHT
_FLAT_PALETTE = [c for colour in PALETTE for c in colour] + [0] * (768 - 3 * len(PALETTE))
INKS = ["black", "blue", "red", "magenta", "green", "cyan", "yellow", "white"]


def _esc(text: str) -> str:
    return html.escape(text, quote=False)


def _word(memory, address: int) -> int:
    return memory[address] | (memory[address + 1] << 8)


def _signed(value: int) -> int:
    return value - 256 if value & 0x80 else value


def skool_entries() -> set:
    """The addresses that start an entry in the listing, the only ones #R can
    link to."""
    found = set()
    if SKOOL.exists():
        for line in SKOOL.read_text(encoding="utf-8").splitlines():
            match = re.match(r"^[bcgistuw]\$([0-9A-F]{4})", line)
            if match:
                found.add(int(match.group(1), 16))
    return found


def link(text: str, entries: set) -> str:
    """#R$ADDR where ADDR starts an entry; a plain $ADDR otherwise."""
    return re.sub(r"#R\$([0-9A-F]{4})",
                  lambda m: m.group(0) if int(m.group(1), 16) in entries else "$" + m.group(1),
                  text)


# --------------------------------------------------------------------------
# The game, running.
# --------------------------------------------------------------------------

def _tracer_class():
    from skoolkit.kbtracer import KEY_BITS
    from skoolkit.simutils import T
    from skoolkit.trace import Tracer

    class GameTracer(Tracer):
        """Held keys and a Kempston stick for the game's IN, as the build's
        sessions give them, and the T-state of every change of the speaker
        bit (bit 4 of an OUT to port $FE)."""

        def __init__(self, simulator):
            super().__init__(simulator, 0, 0, 0, [0] * 16, 0, False)
            self.keys = set()
            self.kempston = 0
            self.speaker = 0
            self.edges = []
            self.write_port = self._write

        def read_port(self, registers, port):
            if port & 0xFF == 0x1F:
                return self.kempston
            if port & 1:
                return 0xFF
            result = 0xFF
            for key in self.keys:
                half_row, bits = KEY_BITS[key]
                if port & half_row == 0:
                    result &= bits
            return result

        def _write(self, registers, port, value, offset=0):
            if port & 1 == 0 and (value & 0x10) != self.speaker:
                self.speaker = value & 0x10
                self.edges.append(registers[T])

    return GameTracer


class Frame:
    """What one turn (or one television frame) left: the screen, the
    variables and the object records, how long it took, and the speaker
    edges made in it."""

    def __init__(self, memory, start: int, end: int, edges: list[int], keys=()):
        self.keys = frozenset(keys)
        self.screen_bytes = bytes(memory[SCREEN:SCREEN_END])
        self.variables = bytes(memory[VARIABLES:RECORDS_END])
        self.start, self.end = start, end
        self.tstates = end - start
        self.edges = edges
        self.speaker = 0
        self.phase = None
        self.turn_end = False

    def record(self, index: int) -> bytes:
        at = RECORDS - VARIABLES + RECORD_SIZE * index
        return self.variables[at:at + RECORD_SIZE]

    def variable(self, address: int) -> int:
        return self.variables[address - VARIABLES]

    def screen(self, flash_inverted: bool = False):
        """The display as the ULA shows it: a picture in PALETTE's indices
        (0-7 normal, 8-15 BRIGHT), 256 by 192."""
        from PIL import Image

        image = Image.frombytes("P", (256, 192), bytes(_indices(self.screen_bytes,
                                                                flash_inverted)))
        image.putpalette(_FLAT_PALETTE)
        return image


# Each byte's eight pixels as 0 (paper) or 1 (ink), and for each attribute
# the translation of those into palette indices.
_BITS = [bytes((byte >> (7 - bit)) & 1 for bit in range(8)) for byte in range(256)]


def _translations(flash_inverted: bool) -> list[bytes]:
    out = []
    for attr in range(256):
        bright = 8 if attr & 0x40 else 0
        ink, paper = bright + (attr & 7), bright + ((attr >> 3) & 7)
        if attr & 0x80 and flash_inverted:
            ink, paper = paper, ink
        out.append(bytes([paper, ink]) + bytes(254))
    return out


_TRANSLATE = {False: _translations(False), True: _translations(True)}


def _indices(data: bytes, flash_inverted: bool) -> bytearray:
    table = _TRANSLATE[flash_inverted]
    out = bytearray(256 * 192)
    for y in range(192):
        row = ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
        attrs = 0x1800 + (y >> 3) * 32
        at = y * 256
        for column in range(32):
            out[at:at + 8] = _BITS[data[row + column]].translate(table[data[attrs + column]])
            at += 8
    return out


class Game:
    """Nightshade on a simulated 48K Spectrum, from the snapshot at $5E00:
    build_nightshade's Machine (R taken from the snapshot, FRAMES left
    alone, or the game resets), with a tracer that also logs the speaker."""

    def __init__(self, snapshot: Path):
        from skoolkit.simutils import T

        self.machine = bn.Machine(snapshot)
        self.tracer = _tracer_class()(self.machine.simulator)
        self.machine.tracer = self.tracer
        self.machine.simulator.set_tracer(self.tracer)
        self.sim = self.machine.simulator
        self.memory = self.sim.memory
        self.T = T
        self.quieting = False

    @property
    def now(self) -> int:
        return self.sim.registers[self.T]

    @property
    def pc(self) -> int:
        return self.machine.pc

    def play(self, steps, label: str = "animation") -> None:
        """Steps as build_nightshade's sessions take them."""
        self.machine.play(steps, label)

    def poke(self, address: int, value) -> None:
        if isinstance(value, (list, tuple, bytes, bytearray)):
            for offset, byte in enumerate(value):
                self.memory[address + offset] = byte
        else:
            self.memory[address] = value

    def peek(self, address: int) -> int:
        return self.memory[address]

    def hold(self, keys=(), stick: int = 0) -> None:
        self.tracer.keys = set(keys)
        self.tracer.kempston = stick

    def run_to(self, address: int, limit: int = TURN_LIMIT) -> None:
        from skoolkit.simutils import PC

        self.sim.trace(self.machine.pc, address, 0, self.now + limit, True, None, None,
                       None, None, None)
        self.machine.pc = self.sim.registers[PC]
        if self.machine.pc != address:
            raise RuntimeError(f"${address:04X} was not reached (PC ${self.machine.pc:04X})")

    def to_turn(self) -> None:
        """Run on to the start of the next turn, if not at one."""
        if self.machine.pc != MAIN_LOOP:
            self.run_to(MAIN_LOOP)

    def _frame(self, start: int, first: int, speaker: int) -> Frame:
        frame = Frame(self.memory, start, self.now,
                      [t - start for t in self.tracer.edges[first:]], self.tracer.keys)
        frame.speaker = speaker
        return frame

    def turn(self) -> Frame:
        """One turn, from MAIN_LOOP to MAIN_LOOP. While `quieting`, the turn
        stops at SPAWNS, after every record's update and before anything
        new can come, for quiet()."""
        self.to_turn()
        start, first, speaker = self.now, len(self.tracer.edges), self.tracer.speaker
        if self.quieting and not self.peek(ENDING):
            self.run_to(SPAWNS)
            self.quiet()
        self.run_to(MAIN_LOOP)
        frame = self._frame(start, first, speaker)
        frame.turn_end = True
        return frame

    def turns(self, count: int, each=None) -> list[Frame]:
        frames = []
        for _ in range(count):
            self.to_turn()
            if each is not None:
                each(self)
            frames.append(self.turn())
        return frames

    def sample(self, tstates: int = TV_FRAME, stop: int = 0) -> Frame:
        """Run for `tstates` whatever the game is doing -- or until it
        reaches `stop`, if that comes first -- and take the screen as it is
        then. The frame's `stopped` says whether `stop` was reached."""
        from skoolkit.simutils import PC

        start, first, speaker = self.now, len(self.tracer.edges), self.tracer.speaker
        self.sim.trace(self.machine.pc, stop, 0, start + tstates, True, None, None,
                       None, None, None)
        self.machine.pc = self.sim.registers[PC]
        frame = self._frame(start, first, speaker)
        frame.stopped = bool(stop) and self.machine.pc == stop
        return frame

    def watch(self) -> Frame:
        """A television frame of whatever the game is doing, never stopping
        inside the copy of a turn's picture to the screen: a sample that
        reaches END_OF_TURN is followed through the copy to MAIN_LOOP, and
        marked as the end of a turn, so that the screen it keeps is whole."""
        start, first, speaker = self.now, len(self.tracer.edges), self.tracer.speaker
        sampled = self.sample(TV_FRAME, END_OF_TURN)
        if not sampled.stopped:
            return sampled
        self.run_to(MAIN_LOOP)
        frame = self._frame(start, first, speaker)
        frame.turn_end = True
        return frame

    def record_address(self, index: int) -> int:
        return RECORDS + RECORD_SIZE * index

    def record(self, index: int) -> list[int]:
        address = self.record_address(index)
        return list(self.memory[address:address + RECORD_SIZE])

    def top_up(self) -> None:
        """Six lives, as a new game gives (#R$BE0F), and all three hits:
        nothing staged here is about dying unless it says so. A new life
        takes one and draws the rest on the panel, so the panel shows five,
        as at the start of a game."""
        self.poke(LIVES, 6)
        self.poke(HITS, 3)

    # -- staging -----------------------------------------------------------

    def give(self, things) -> None:
        """Have him pick up each of `things` in turn, by the game's own
        pick-up (#R$C489), so that the panel shows them: an object (thing
        1-4) is its own record (#R$D88E gives record n graphic 7 - n, and
        thing 1 is graphic 4) put where he stands; an antibody (thing 5-8)
        is a find of graphic 48, 52, 56 or 60 (#R$C481) put there in the
        first find record. Each is half-size 8 each way, as objects and
        finds are (#R$D8D7, #R$C5CE). Runs the turns it takes."""
        for thing in things:
            if thing <= 4:
                self.put(OBJECTS + 4 - thing, thing + 3, size=(8, 8))
            else:
                self.put(FINDS, 48 + 4 * (thing - 5), size=(8, 8))
            for _ in range(8):
                self.turn()
                if thing in self.memory[CARRIED:CARRIED + 11]:
                    break
            else:
                raise RuntimeError(f"thing {thing} was never picked up")
        self.to_turn()

    def start_game(self) -> None:
        """From the snapshot through the menu into the town, as the build's
        sessions start (keyboard)."""
        self.play(bn._start("1"))
        self.to_turn()

    def playing(self) -> bool:
        return bn._playing(self.memory)

    def quiet(self) -> None:
        """Keep the records that things come into by themselves busy with
        graphic 1 -- the empty picture, whose update does nothing (#R$D6D5)
        -- in cell (0,0), the corner of the town, which is solid: then no
        monster can appear (#R$CDE8 wants an empty monster record), no find
        (#R$C5CE) and no bonus (#R$D76C), and nothing wanders into a picture
        that is about something else. Only empty records are filled, so what
        is there already is left alone. The creature (#R$BF95) takes a
        record anyway, but only once in 256 turns (see go()). go() sets
        `quieting`, and every turn then does this at SPAWNS."""
        for index in [FINDS, FINDS + 1, FINDS + 2, FINDS + 3, BONUS] + list(
                range(MONSTERS, MONSTERS + 6)):
            if self.peek(self.record_address(index)) == 0:
                self.poke(self.record_address(index), [1] + [0] * (RECORD_SIZE - 1))

    def go(self, u: int, v: int, facing: int = 0x40, quiet: bool = True,
           settle: int = 2, creature: bool = False) -> list[Frame]:
        """Put the knight into cell (u, v) facing `facing`, by the game's own
        restart (build_nightshade._go): the cell and the facing go into the
        start records, his two records become the vanishing cloud, and when
        it has gone #R$CBAC starts the next life there, he appears, and
        `settle` more turns are run. Returns the turns from the one the
        cloud was set in. With `quiet`, every turn from here on keeps the
        records things come into busy (quiet()). Unless `creature`, the turn
        counter's low byte is then set to 1, so that the creature, which
        comes when it is 0 (#R$BF95), is 255 turns away."""
        self.to_turn()
        self.top_up()
        self.quieting = quiet
        self.poke(bn.START_U_CELL, u)
        self.poke(bn.START_V_CELL, v)
        self.poke(START_FACING, facing)
        bn._kill(self.memory)
        frames = []
        for _ in range(120):
            frames.append(self.turn())
            self.top_up()
            if bn._in_cell(u, v)(self.memory) and self.peek(bn.KNIGHT + 6) & 0xC0 == facing:
                break
        else:
            raise RuntimeError(f"the restart into cell ({u},{v}) never came")
        if not creature:
            self.poke(TURNS, 1)
        frames += self.turns(settle)
        return frames

    def put(self, index: int, graphic: int, du: int = 0, dv: int = 0, template: int = 0,
            facing: int | None = None, flags: int = 0, size=None) -> None:
        """Record `index` given `graphic` at the knight's place plus (du,
        dv) units, 16-bit, across cells if need be: from `template` (16
        bytes, #R$CE79 for a monster) or, without one, with the size and
        drawing offset the game gives the things he meets (#R$D7C7: 16 each
        way, 12 left and 4 up)."""
        address = self.record_address(index)
        if template:
            data = list(self.memory[template:template + RECORD_SIZE])
        else:
            data = [0] * RECORD_SIZE
            data[8] = data[9] = 0x10
            data[12], data[13] = 0xF4, 0x04
        knight = self.record(LEGS)
        u = (knight[1] | knight[2] << 8) + du
        v = (knight[3] | knight[4] << 8) + dv
        data[0] = graphic
        data[1], data[2] = u & 0xFF, u >> 8 & 0xFF
        data[3], data[4] = v & 0xFF, v >> 8 & 0xFF
        data[7] = flags
        if facing is not None:
            data[6] = facing
        if size is not None:
            data[8], data[9] = size
        self.poke(address, data)


# --------------------------------------------------------------------------
# Cropping and saving.
# --------------------------------------------------------------------------

def sprite_size(memory, graphic: int) -> tuple[int, int]:
    """A graphic's sprite's width in bytes and height in lines (#R$E353)."""
    sprite = _word(memory, GRAPHICS + 2 * graphic)
    return memory[sprite] & 0x0F, memory[sprite + 1]


def drawn_box(memory, record: bytes):
    """Where the drawing code put this record's picture this turn, as a box
    of screen pixels (left, top, right, bottom), or None if it was not
    drawn: +E and +F are the game's x and y of the sprite's bottom left
    (#R$E3D9), bit 1 of +7 is set when it is drawn, and bits 1-2 of x shift
    it into one byte more. The bit is cleared only by the routines that
    make a sound for something drawn last turn, so a thing that has gone
    out of view can keep it, and its old place: this is used only for
    things that are in view, or clear it every turn themselves (the cloud,
    the sparkles)."""
    if record[0] < 2 or not record[7] & 2:
        return None
    width, height = sprite_size(memory, record[0])
    x, y = record[14], record[15]
    # The drawing's own limits (#R$E3D9): a record whose +E and +F are not
    # a place it could have been drawn at -- the knight's start records
    # copied in at a new life carry 0 and 0 -- was not drawn.
    if not width or not height or not 16 <= x <= 202 or y >= 184 or y + height <= 72:
        return None
    left = ((x - 16) >> 3) * 8 + 40
    right = left + 8 * (width + (1 if x & 6 else 0))
    bottom = 199 - y + 1
    return (max(PLAY_AREA[0], left), max(PLAY_AREA[1], bottom - height),
            min(PLAY_AREA[2], right), min(PLAY_AREA[3], bottom))


def _union(a, b):
    if a is None:
        return b
    if b is None:
        return a
    return min(a[0], b[0]), min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3])


def crop(memory, frames: list[Frame], records: list[int] = (), margin: int = 4,
         box=None) -> list:
    """Each frame's picture, cut down to the union of what `records` drew in
    all of them, with a margin, inside the play area (or cut to `box`)."""
    if box is None:
        union = None
        for frame in frames:
            for index in records:
                union = _union(union, drawn_box(memory, frame.record(index)))
        if union is None:
            raise ValueError("nothing was drawn")
        box = (max(PLAY_AREA[0], union[0] - margin), max(PLAY_AREA[1], union[1] - margin),
               min(PLAY_AREA[2], union[2] + margin), min(PLAY_AREA[3], union[3] + margin))
    pictures = []
    for frame in frames:
        inverted = bool((frame.end // TV_FRAME // FLASH_FRAMES) & 1)
        pictures.append(frame.screen(inverted).crop(box))
    return pictures


def duration(tstates: int) -> int:
    """A frame's time in milliseconds, to the 10ms a GIF can say."""
    return max(20, round(tstates / T_STATES_PER_MS / 10) * 10)


def shown_for(frames: list[Frame]) -> list[int]:
    """How long each frame's picture stays on the screen, in T-states: a
    picture is copied to the screen at the end of its turn and stays there
    until the next is copied at the end of the next turn, so it is shown
    for as long as the next turn takes (the last frame, for its own)."""
    return [frames[i + 1].tstates if i + 1 < len(frames) else frames[i].tstates
            for i in range(len(frames))]


def merge(pictures: list, frames: list[Frame], labels: list[str]) -> list[tuple]:
    """(picture, milliseconds, label, tstates) per frame shown, identical
    pictures in a row as one, shown for their total time."""
    out = []
    for picture, tstates, label in zip(pictures, shown_for(frames), labels):
        if out and out[-1][0].tobytes() == picture.tobytes():
            last = out[-1]
            if label not in last[2]:
                last[2].append(label)
            out[-1] = (last[0], last[1], last[2], last[3] + tstates)
        else:
            out.append((picture, 0, [label], tstates))
    return [(p, duration(t), "/".join(label), t) for p, _, label, t in out]


def save_gif(path: Path, frames: list[tuple]) -> None:
    """Frames (picture, milliseconds, ...) as a looping GIF in the Spectrum's
    colours."""
    images = [picture for picture, *_ in frames]
    for image in images:
        image.putpalette(_FLAT_PALETTE)
    if len(images) == 1:
        images[0].save(path)
        return
    images[0].save(path, save_all=True, append_images=images[1:], loop=0,
                   duration=[ms for _, ms, *_ in frames], disposal=1, optimize=False)


def graphics_label(frame: Frame, records) -> str:
    return "+".join(str(frame.record(i)[0]) for i in records if frame.record(i)[0] > 1) or "-"


def animation(key: str, memory, frames: list[Frame], records=(), labels=None,
              **options) -> dict:
    pictures = crop(memory, frames, records, **options)
    if labels is None:
        labels = [graphics_label(f, records) for f in frames]
    return {"key": key, "frames": merge(pictures, frames, labels), "turns": frames}


# --------------------------------------------------------------------------
# The animations.
# --------------------------------------------------------------------------
WALK_KEY, LEFT_KEY, RIGHT_KEY, FIRE_KEY, VIEW_KEY = "a", "x", "c", "q", "z"
# An open cell in the middle of a street of buildings: row 23 of the town is
# open from column 20 to 29, with buildings along both sides (the map at
# #R$5E04), so he can walk nine cells along it.
STREET = (29, 23)
OPEN_CELL = (24, 23)
# A cell of that street with a building's wall across it at the +V side
# (cell (22,24) of the map): walking +V from the middle he meets it 14 turns
# later (measured).
WALL_CELL = (22, 23)
TOWN_WALK_TURNS = 100


# Each run made once per snapshot and kept: some animations are cut from
# another's run, and nightshade_sounds may record from these same runs when
# the build calls both modules in one process.
_RUNS: dict = {}


def run(snapshot: Path, make, *args):
    """make(snapshot, *args), made once per snapshot and kept."""
    key = (str(snapshot), make.__name__, args)
    if key not in _RUNS:
        _RUNS[key] = make(snapshot, *args)
    return _RUNS[key]


def started(snapshot: Path) -> Game:
    game = Game(snapshot)
    game.start_game()
    return game


def _knight_label(frame: Frame) -> str:
    legs, top = frame.record(LEGS), frame.record(TOP)
    return f"{legs[0]}+{top[0]}{'m' if legs[7] & 0x40 else ''}"


def walking(snapshot: Path, facing: int) -> dict:
    """Walk held from standing in the open cell, facing `facing`, until his
    speed has settled and his legs have been through all six frames at it:
    the GIF is those six turns, over and over. The turns from standing are
    kept for the measurement."""
    game = started(snapshot)
    game.go(*OPEN_CELL, facing=facing)
    game.hold([WALK_KEY])
    frames = []
    for _ in range(40):
        frames.append(game.turn())
        cycle = frames[-6:]
        if (len(cycle) == 6 and all(f.record(LEGS)[5] == cycle[0].record(LEGS)[5] for f in cycle)
                and [f.record(LEGS)[0] & 7 for f in cycle] == [0, 1, 2, 3, 4, 5]
                and all(f.record(TOP)[0] == f.record(LEGS)[0] + 16 for f in cycle)):
            anim = animation(f"walk-{facing >> 6}", game.memory, cycle, [LEGS, TOP],
                             labels=[_knight_label(f) for f in cycle])
            anim["all"] = frames
            return anim
    raise RuntimeError("no clean walk cycle")


def _facing(record: bytes) -> int:
    return record[6] & 0xC0


def turning(snapshot: Path) -> dict:
    """Standing in the open cell facing +U, the right-turn key held until
    he faces +U again; then a turn standing."""
    game = started(snapshot)
    game.go(*OPEN_CELL, facing=0x40)
    frames = [game.turn()]
    game.hold([RIGHT_KEY])
    for _ in range(40):
        frames.append(game.turn())
        facings = [_facing(f.record(LEGS)) for f in frames]
        if len(set(facings)) == 4 and facings[-1] == 0x40:
            break
    else:
        raise RuntimeError("he never came round")
    game.hold()
    frames += game.turns(1)
    labels = [f"{_knight_label(f)} {dict(FACINGS)[_facing(f.record(LEGS))]}" for f in frames]
    return animation("turn", game.memory, frames, [LEGS, TOP], labels=labels)


def standing(snapshot: Path) -> dict:
    """Standing still in the open cell for 200 turns, facing +U, towards
    the viewer: the top's poses (#R$D9EB) come by themselves, one turn in
    32."""
    game = started(snapshot)
    game.go(*OPEN_CELL, facing=0x40)
    frames = game.turns(200)
    return animation("standing", game.memory, frames, [LEGS, TOP],
                     labels=[_knight_label(f) for f in frames])


def town_walk(snapshot: Path) -> dict:
    """The whole play area while he walks along the street from its east
    end, facing -U, for TOWN_WALK_TURNS turns from standing."""
    game = started(snapshot)
    game.go(*STREET, facing=0xC0)
    frames = game.turns(2)
    game.hold([WALK_KEY])
    frames += game.turns(TOWN_WALK_TURNS)
    labels = [f"cell {f.record(LEGS)[2]},{f.record(LEGS)[4]} U {f.record(LEGS)[1]}"
              for f in frames]
    return animation("town-walk", game.memory, frames, box=PLAY_AREA, labels=labels)


def town_turn(snapshot: Path) -> dict:
    """The town turned round: in the street, the Z key held for a turn and
    let go (#R$DB68 acts on the release), then again after eight turns. The
    whole screen, for the panel's heading."""
    game = started(snapshot)
    game.go(STREET[0] - 2, STREET[1], facing=0xC0)
    frames = game.turns(3)
    for _ in range(2):
        game.hold([VIEW_KEY])
        frames.append(game.turn())
        game.hold()
        frames += game.turns(8)
    labels = [("turned round" if f.variable(VIEW) & 1 else "the usual way")
              + (", Z held" if VIEW_KEY in f.keys else "") for f in frames]
    return animation("town-turn", game.memory, frames, box=WHOLE_SCREEN, labels=labels)


def _phase(frame: Frame) -> str:
    """What the knight is doing: vanishing, appearing, or here."""
    legs = frame.record(LEGS)[0]
    arriving = frame.variable(ARRIVING)
    if legs in range(VANISH, VANISH + 4):
        return f"vanishing {legs}"
    if legs == 0:
        return "gone"
    if arriving != HERE:
        return f"appearing, ARRIVING {arriving}"
    return f"here {_knight_label(frame)}"


def arriving(snapshot: Path) -> dict:
    """A life ended and the next begun. Standing in the open cell facing
    -U with one hit left, a monster of graphic 64 is put on top of him: its
    update finds it touching him and takes his last hit (#R$CE89), both his
    records become the vanishing cloud and his cell goes into the start
    records; when the cloud has gone #R$CBAC plays the new-life tune, and he
    rises out of the ground, ARRIVING lines of him drawn (#R$E3D9), two
    more a turn (#R$DA7A), until he is all there."""
    game = started(snapshot)
    game.go(*OPEN_CELL, facing=0xC0)
    frames = game.turns(2)
    game.to_turn()
    game.poke(HITS, 1)
    game.put(MONSTERS, 64, template=MONSTER_TEMPLATE)
    for _ in range(80):
        frames.append(game.turn())
        if len(frames) > 6 and game.peek(ARRIVING) == HERE and game.playing():
            break
    else:
        raise RuntimeError("the next life never came")
    frames += game.turns(3)
    return animation("arriving", game.memory, frames, [LEGS, TOP, MONSTERS], margin=6,
                     labels=[_phase(f) for f in frames])


def _speed_label(frame: Frame) -> str:
    legs = frame.record(LEGS)
    return f"speed {legs[5]}, bonus {frame.record(BONUS)[0]}"


def bonus(snapshot: Path, graphic: int) -> dict:
    """A bonus (#R$D76C) of `graphic` put 72 units ahead of him in the
    open cell, facing -U, and walk held: he walks into it, it becomes the
    vanishing cloud (#R$D7D8), and for graphic 2 he walks on at the faster
    speed (#R$D727); for graphic 3 his hits come back, shown by his colour
    (#R$D74C), which is why he starts this one with one hit. The bonus is
    staged; the rest is the game."""
    game = started(snapshot)
    game.go(*OPEN_CELL, facing=0xC0)
    game.to_turn()
    if graphic == 3:
        game.poke(HITS, 1)
    game.put(BONUS, graphic, du=-72)
    frames = game.turns(2, each=lambda g: g.poke(HITS, 1) if graphic == 3 else None)
    game.hold([WALK_KEY])
    clouded = False
    for _ in range(60):
        frames.append(game.turn())
        cloud = game.peek(game.record_address(BONUS)) in range(VANISH, VANISH + 4)
        if clouded and not cloud:
            break
        clouded |= cloud
    else:
        raise RuntimeError("he never took the bonus")
    frames += game.turns(14 if graphic == 2 else 4)
    game.hold()
    key = "bonus-speed" if graphic == 2 else "bonus-hits"
    return animation(key, game.memory, frames, box=PLAY_AREA,
                     labels=[_speed_label(f) + f", hits {f.variable(HITS)}" for f in frames])


def vanishing(snapshot: Path) -> dict:
    """The cloud, cropped from the speed bonus's run: the bonus from the
    turn before he touches it until its record is empty."""
    anim = run(snapshot, bonus, 2)
    turns = anim["turns"]
    first = next(n for n, f in enumerate(turns) if f.record(BONUS)[0] in range(VANISH, VANISH + 4))
    last = next(n for n in range(first, len(turns))
                if turns[n].record(BONUS)[0] not in range(VANISH, VANISH + 4))
    frames = turns[first - 1:last + 1]
    return animation("vanishing", bn.game_memory(snapshot), frames, [BONUS], margin=6,
                     labels=[f"bonus record {f.record(BONUS)[0]}" for f in frames])


def _antibody_label(frame: Frame) -> str:
    return (f"antibodies {frame.record(ANTIBODY)[0]}, {frame.record(ANTIBODY2)[0]}; carried "
            + ",".join(str(t) for t in frame.variables[CARRIED - VARIABLES:CARRIED - VARIABLES + 4]))


# The four kinds of antibody, as things carried (#R$C489): 5-8.
ANTIBODY_THINGS = [5, 6, 7, 8]
THROW_GAP = 8


def antibodies(snapshot: Path) -> dict:
    """He is given the four kinds of antibody (things 5-8, in CARRIED, as
    four picked up would leave them), standing in WALL_CELL facing +V,
    towards the building there; fire is pressed for a turn every THROW_GAP
    turns: the last taken is thrown first (#R$DAB7), flies at 12 units a
    step, two steps a turn (#R$D7ED), and vanishes at the wall."""
    game = started(snapshot)
    game.go(*WALL_CELL, facing=0x00)
    game.to_turn()
    game.give(ANTIBODY_THINGS)
    frames = game.turns(2)
    for _ in ANTIBODY_THINGS:
        game.hold([FIRE_KEY])
        frames.append(game.turn())
        game.hold()
        frames += game.turns(THROW_GAP - 1)
    return animation("antibodies", game.memory, frames, box=PLAY_AREA,
                     labels=[_antibody_label(f) for f in frames])


def bump(snapshot: Path) -> dict:
    """Walk held from the middle of WALL_CELL facing +V, into the building
    across it: when his legs are stopped the top throws its arms out
    (graphic 22 or 30, #R$D9EB) and he bumps against it (#R$C3AA) for as
    long as walk is held; then let go."""
    game = started(snapshot)
    game.go(*WALL_CELL, facing=0x00)
    frames = game.turns(1)
    game.hold([WALK_KEY])
    for _ in range(40):
        frames.append(game.turn())
        if frames[-1].record(TOP)[0] in (22, 30):
            break
    else:
        raise RuntimeError("he never met the wall")
    frames += game.turns(6)
    game.hold()
    frames += game.turns(3)
    return animation("bump", game.memory, frames, [LEGS, TOP],
                     labels=[f"{_knight_label(f)} V {f.record(LEGS)[3]}" for f in frames])


def _monster_label(frame: Frame, first: int = MONSTERS, count: int = 6) -> str:
    return " ".join(str(frame.record(i)[0]) for i in range(first, first + count)
                    if frame.record(i)[0] > 1) + f"; hits {frame.variable(HITS)}"


# Where the four staged monsters are put, from the knight, in units of U
# and V: round him, far enough apart to be told from one another.
FOUR_PLACES = [(-64, -64), (64, -64), (-64, 64), (64, 64)]
MONSTER_TURNS = 16
# Cells to wait in for a monster to appear in view, and for how long.
APPEAR_CELLS = [(24, 18), (24, 23), (16, 15), (14, 12)]
APPEAR_TURNS = 400


def monsters(snapshot: Path, first: int) -> dict:
    """Four monsters, one of each kind -- graphics `first`, +4, +8 and +12
    -- put round him in the open cell as #R$CDE8's template makes them
    (#R$CE79: speed 6, 16 by 16 units), as if each had just finished
    appearing (#R$C164 gives graphic 76 a depth of 24 in V, so that one
    has it too), and left to go their ways for MONSTER_TURNS turns, him standing
    still. What touches him takes a hit
    (his hits are topped up every turn); what wanders more than two cells
    off is gone. The records a new monster would appear in are kept busy
    (quiet()), so the four are all there is."""
    game = started(snapshot)
    game.go(*OPEN_CELL, facing=0xC0)
    game.to_turn()
    for n, (du, dv) in enumerate(FOUR_PLACES):
        graphic = first + 4 * n
        game.put(MONSTERS + n, graphic, du, dv, template=MONSTER_TEMPLATE,
                 facing=FACINGS[n][0],
                 size=(0x10, 0x18) if graphic == 76 else None)
    frames = game.turns(MONSTER_TURNS, each=lambda g: g.poke(HITS, 3))
    key = f"monsters-{first}"
    return animation(key, game.memory, frames, box=PLAY_AREA,
                     labels=[_monster_label(f) for f in frames])


def appearing(snapshot: Path) -> dict:
    """A monster appearing by itself (#R$CDE8): the game left to run with
    him standing still in a cell of APPEAR_CELLS until a monster record
    holds graphic 128 where it is drawn; then its turns from there until it
    has been a monster for a few turns. Most monsters appear in cells round
    his that are not drawn, or inside buildings, and with him standing
    still the six records soon fill with monsters that stay; so while
    waiting, and only then, the monster records are emptied at the start
    of every turn, as walking away from them would empty them."""
    for cell in APPEAR_CELLS:
        game = started(snapshot)
        game.go(*cell, facing=0xC0, quiet=False)
        frames = []
        index = None
        for _ in range(APPEAR_TURNS):
            # Monsters left behind are forgotten (#R$CE89, #R$C083); him
            # standing still, none is, so the records are emptied as if
            # they had been, and one can appear every fourth turn.
            for n in range(MONSTERS, MONSTERS + 6):
                game.poke(game.record_address(n), 0)
            frames.append(game.turn())
            game.top_up()
            for n in range(MONSTERS, MONSTERS + 6):
                if (frames[-1].record(n)[0] == 128
                        and drawn_box(game.memory, frames[-1].record(n))):
                    index = n
                    break
            if index is not None:
                break
        if index is not None:
            break
    else:
        raise RuntimeError("no monster appeared in view")
    kept = [frames[-2], frames[-1]]
    for _ in range(8):
        kept.append(game.turn())
        game.top_up()
    return {**animation("appearing", game.memory, kept, [index], margin=8,
                        labels=[str(f.record(index)[0]) for f in kept]), "index": index}


def creature(snapshot: Path) -> dict:
    """The creature (#R$BF95) put in his cell 80 units off along U and V,
    as the game puts it there once in 256 turns, him standing still in the
    open cell: it makes for him two units a turn along each axis (#R$C02C),
    and touching him it bursts and takes a hit (#R$BFF1), his colour going
    from white to yellow (#R$C065)."""
    game = started(snapshot)
    game.go(*OPEN_CELL, facing=0xC0)
    game.to_turn()
    game.put(MONSTERS, 136, 80, 80)
    frames = []
    for _ in range(80):
        frames.append(game.turn())
        if frames[-1].record(MONSTERS)[0] not in range(136, 140) and len(frames) > 2:
            break
    else:
        raise RuntimeError("the creature never reached him")
    frames += game.turns(6)
    return animation("creature", game.memory, frames, box=PLAY_AREA,
                     labels=[_monster_label(f, MONSTERS, 1) for f in frames])


def _score(frame: Frame) -> str:
    at = SCORE - VARIABLES
    return "".join(f"{b:02X}" for b in frame.variables[at:at + 3]) + "00"


def _strike_label(frame: Frame) -> str:
    monsters = " ".join(str(frame.record(i)[0]) for i in (MONSTERS, MONSTERS + 1)
                        if frame.record(i)[0] > 1)
    return (f"antibody {frame.record(ANTIBODY)[0] or 'none'}; monsters {monsters or 'none'}"
            f"; score {_score(frame)}")


# The outcomes of an antibody striking a monster of 112-127 (#R$C0D1): the
# monster's kind (bits 2-3 of 112-127) plus the antibody's (of 80-95), four
# apart. With the monster of 112, kind 0, the antibody picks the outcome:
# thing 5 is thrown as graphic 80 (kind 0), 6 as 84 and so on (#R$DAB7).
STRIKES = [("strike-destroyed", 5, 112), ("strike-changed", 6, 112),
           ("strike-split", 7, 112), ("strike-demoted", 8, 112), ("strike-64", 5, 64)]
AHEAD = 96                        # where a target is put, along his facing
# ...and a monster of 64-79, which does not walk towards him but wanders at
# random up to 14 units a turn (#R$DDCF), where the antibody will be a turn
# after it is thrown (24 units a turn, #R$D7ED), give or take its wander.
AHEAD_WANDERER = 60


def strike(snapshot: Path, key: str) -> dict:
    """In the open cell facing -U he is given one antibody (thing 5-8, as
    picking one up leaves it) and fire is pressed for a turn; when it is in
    flight a monster of graphic 112 (or 64) is put AHEAD units in front of
    him, facing him, from the monster template (#R$CE79), in the second
    monster record -- a split copies the monster into the first (#R$C101),
    which quiet() leaves far off in the corner of the town, so there is
    room for it. The antibody meets it, and what the strike does is the
    game's."""
    _, thing, graphic = next(item for item in STRIKES if item[0] == key)
    game = started(snapshot)
    game.go(*OPEN_CELL, facing=0xC0)
    game.to_turn()
    game.give([thing])
    frames = game.turns(1)
    game.hold([FIRE_KEY])
    frames.append(game.turn())
    game.hold()
    if game.peek(game.record_address(ANTIBODY)) not in range(80, 96):
        raise RuntimeError("the antibody was not thrown")
    game.put(MONSTERS + 1, graphic, -(AHEAD if graphic >= 112 else AHEAD_WANDERER),
             template=MONSTER_TEMPLATE, facing=0x40)
    score = bytes(game.memory[SCORE:SCORE + 3])
    for _ in range(12):
        frames.append(game.turn())
        game.poke(HITS, 3)
        if bytes(game.memory[SCORE:SCORE + 3]) != score:
            break
    else:
        raise RuntimeError(f"{key}: the antibody never struck")

    frames += game.turns(10, each=lambda g: g.poke(HITS, 3))
    return animation(key, game.memory, frames, box=PLAY_AREA,
                     labels=[_strike_label(f) for f in frames])


def _villain_label(frame: Frame, which: int) -> str:
    sparkles = [frame.record(FINDS + n)[0] for n in range(4)]
    return (f"object {frame.record(OBJECTS + which)[0]}, villain "
            f"{frame.record(VILLAINS + which)[0]}, sparkles "
            + (",".join(str(g) for g in sparkles if g in range(140, 144)) or "none")
            + f", paper {INKS[frame.variable(LAST_FLASH) >> 3 & 7]}")


VILLAIN_TEMPLATE = 0xD932         # what a villain starts as (#R$D8E7)


def villain_destroyed(snapshot: Path, which: int = 0) -> dict:
    """Villain `which` destroyed by its object. In the open cell facing -U
    he is given the object that kills it (thing 4 - which, as picking it
    up would leave it, #R$C489) and fire is pressed for a turn: the object
    is thrown from its own record (#R$DAB7). The villain is then put AHEAD
    units in front of him facing him, from the villains' template
    (#R$D932). The rest is the game's: the strike (#R$D80C), the villain
    dying in a flash of the play area (#R$D847), the four sparkles
    (#R$D6D6, #R$D70A), the panel's villain coloured in (#R$C1FD) and the
    score. The whole screen."""
    game = started(snapshot)
    game.go(*OPEN_CELL, facing=0xC0)
    game.to_turn()
    game.give([4 - which])
    frames = game.turns(1)
    game.hold([FIRE_KEY])
    frames.append(game.turn())
    game.hold()
    if game.peek(game.record_address(OBJECTS + which)) not in range(8, 12):
        raise RuntimeError("the object was not thrown")
    game.put(VILLAINS + which, 108 - 4 * which, -AHEAD, template=VILLAIN_TEMPLATE,
             facing=0x40)
    struck = None
    for n in range(80):
        frames.append(game.turn())
        game.top_up()
        villain = game.peek(game.record_address(VILLAINS + which))
        if struck is None and villain >= 132:
            struck = n
        sparkling = False
        for k in range(4):
            address = game.record_address(FINDS + k)
            if game.peek(address) in range(140, 144) and game.peek(address + 7) & 2:
                sparkling = True
        if struck is not None and not sparkling and not villain:
            break
    else:
        raise RuntimeError("the villain was never destroyed")
    frames += game.turns(3)
    return animation("villain-destroyed", game.memory, frames, box=WHOLE_SCREEN,
                     labels=[_villain_label(f, which) for f in frames])


def _cell_distance(record_a, record_b) -> tuple[int, int]:
    return abs(record_a[2] - record_b[2]), abs(record_a[4] - record_b[4])


# The panel's carried things (#R$C4A4): 16 pixels a place up from the
# bottom of the screen, 16 in, two characters square; the first four
# places, with the frame round them.
PANEL_BOX = (0, 104, 48, 192)
# What he is given to carry for the flashing: the object for villain 3,
# an antibody, the object for villain 0, another antibody.
FLASH_CARRIED = [1, 5, 4, 6]
NEAR = 3 * 256                    # villain 0 put three cells along U from him
FAR_CELL = (3, 21)                # an open cell far from the open cell
FLASH_TURNS = 16


def _flash_label(frame: Frame) -> str:
    return (f"villain 0 {_cell_distance(frame.record(VILLAINS), frame.record(LEGS))} cells off; "
            f"places " + ", ".join(f"{INKS[frame.screen_bytes[0x1800 + 32 * row + 2] & 7]}"
                                   for row in (22, 20, 18, 16)))


def panel_flash(snapshot: Path) -> dict:
    """The panel's warning. In the open cell he is given four things to
    carry (FLASH_CARRIED, as picking them up leaves them); villain 0 is put
    three cells along U from him, standing (speed 0) so that it stays
    there, and the other three well away in FAR_CELL. #R$C4DC colours the
    carried things every turn: each in its own colour, but the object that
    kills a villain less than five cells off in column and row through the
    antibodies' colours, a new one each turn. The first and third places
    hold the objects for villains 3 and 0: only the third flashes."""
    game = started(snapshot)
    game.go(*OPEN_CELL, facing=0xC0)
    game.to_turn()
    game.give(FLASH_CARRIED)
    for which in range(4):
        game.put(VILLAINS + which, 108 - 4 * which, template=VILLAIN_TEMPLATE, facing=0x40)
        address = game.record_address(VILLAINS + which)
        if which == 0:
            game.poke(address + 2, game.peek(address + 2) + NEAR // 256)
        else:
            game.poke(address + 2, FAR_CELL[0])
            game.poke(address + 4, FAR_CELL[1])
        game.poke(address + 5, 0)
    frames = game.turns(FLASH_TURNS, each=lambda g: g.poke(g.record_address(VILLAINS) + 5, 0))
    return animation("panel-flash", game.memory, frames, box=PANEL_BOX,
                     labels=[_flash_label(f) for f in frames])


def villains(snapshot: Path) -> dict:
    """The four villains walking (#R$D94F), each put, from the villains'
    template (#R$D932), 80 units out from him along U or V and facing away
    from him, him standing still in the open cell: each walks at speed 4,
    turning at walls and now and then at random (#R$DD28), its picture
    taken from its facing (#R$D978). A villain kills at a touch, so the
    run stops if one reaches him."""
    game = started(snapshot)
    game.go(*OPEN_CELL, facing=0xC0)
    game.to_turn()
    places = [(-80, 0, 0xC0), (80, 0, 0x40), (0, -80, 0x80), (0, 80, 0x00)]
    for which, (du, dv, facing) in enumerate(places):
        game.put(VILLAINS + which, 108 - 4 * which, du, dv, template=VILLAIN_TEMPLATE,
                 facing=facing)
    frames = []
    for _ in range(VILLAIN_TURNS):
        frames.append(game.turn())
        game.top_up()
        if not game.playing():
            break
    return animation("villains", game.memory, frames, box=PLAY_AREA,
                     labels=[" ".join(str(f.record(VILLAINS + n)[0]) for n in range(4))
                             for f in frames])


VILLAIN_TURNS = 30


# The menu: a key for each control method, directional control, then the
# keyboard again; MENU_WAIT seconds apart, each held for MENU_HOLD.
MENU_KEYS = ["2", "3", "4", "5", "1"]
MENU_WAIT = 1.2
MENU_HOLD = 0.2


def _watch_for(game: Game, seconds: float, phase: str, keys=()) -> list[Frame]:
    game.hold(keys)
    frames = []
    until = game.now + int(seconds * TSTATES_PER_SECOND)
    while game.now < until:
        frame = game.watch()
        frame.phase = phase
        frames.append(frame)
    return frames


def menu(snapshot: Path) -> dict:
    """The menu (#R$C8CA) from the first time it is shown: its tune plays
    until a key (#R$C63D); then 2, 3, 4, 5 and 1 pressed in turn, each
    control method a short tune (#R$C7F4) and the flash moved to its line
    (#R$C949), 5 turning directional control on. Read once a television
    frame; the whole screen."""
    game = Game(snapshot)
    game.play([bn.At("the menu", MENU_LOOP, 30.0)])
    frames = _watch_for(game, MENU_WAIT * 2, "the menu's tune")
    for key in MENU_KEYS:
        frames += _watch_for(game, MENU_HOLD, f"{key} pressed", [key])
        frames += _watch_for(game, MENU_WAIT, f"after {key}")
    game.hold()
    return animation("menu", game.memory, frames, box=WHOLE_SCREEN,
                     labels=[f.phase for f in frames])


def _ending_phase(frame: Frame, seen: dict) -> str:
    """What an ending frame shows, from what the game has done so far."""
    if frame.variable(ENDING):
        seen["ending"] = True
        moving = [n for n in range(5, 9) if frame.record(n)[0] in range(144, 152)]
        if not moving:
            return "the pit, empty"
        n = moving[0]
        return f"record {n}: villain {frame.record(n)[0]} at x {frame.record(n)[10]}, y {frame.record(n)[11]}"
    if seen.get("ending"):
        return "the menu"
    return "game over"


def ending(snapshot: Path) -> dict:
    """The ending, staged the way the build's quest session ends but
    without the play before it: at the start of a turn the four villain
    records are emptied, as four destroyed villains leave them; at the end
    of that turn #R$D865 finds none left and no sparkles, and #R$CC56
    shows the percentage and the score under the game-over tune, then
    empties every record, fills ten from #R$CCE4 and sets ENDING. From
    there the main loop only updates records: the back of the pit and its
    front, and the four villains of the ending, each waiting while the one
    before it is still on its way (#R$CD58), carried across to the pit and
    sunk into it; when the last has gone the end tune plays (#R$CD10) and
    the menu comes back. Read once a television frame, never inside the
    copy of a turn to the screen (Game.watch); the whole screen."""
    game = started(snapshot)
    game.go(*OPEN_CELL, facing=0xC0)
    game.to_turn()
    for which in range(4):
        game.poke(game.record_address(VILLAINS + which), 0)
    start, first = game.now, len(game.tracer.edges)
    game.run_to(GAME_OVER)
    frames, seen = [game._frame(start, first, 0)], {"turned": True}
    labels = ["the last turn of play"]
    for _ in range(ENDING_LIMIT):
        frame = game.watch()
        frames.append(frame)
        if frame.variable(ENDING) and not frame.turn_end and seen.get("ending"):
            # A sample inside a turn still shows the turn before's picture.
            labels.append(labels[-1])
        else:
            labels.append(_ending_phase(frame, seen))
        if seen.get("ending") and not frame.variable(ENDING):
            break
    else:
        raise RuntimeError("the ending never came back to the menu")
    more = _watch_for(game, 1.0, "the menu")
    frames += more
    labels += [f.phase for f in more]
    return animation("ending", game.memory, frames, box=WHOLE_SCREEN, labels=labels)


ENDING_LIMIT = 50 * 60            # television frames: a minute


# --------------------------------------------------------------------------
# What the recordings show, checked against what the code says they should.
# --------------------------------------------------------------------------

# Every comparison that failed, for build() to log: a page that says the
# recording disagrees with the code must not go by unnoticed.
DISAGREEMENTS: list[str] = []


def _fmt(value) -> str:
    """A value for a sentence: lists and pairs without Python's brackets."""
    if isinstance(value, tuple):
        if all(isinstance(v, int) for v in value):
            return "(" + ", ".join(f"{v:+d}" if v < 0 else str(v) for v in value) + ")"
        return " then ".join(_fmt(v) for v in value)
    if isinstance(value, list):
        return ", ".join(_fmt(v) for v in value)
    return str(value)


def _check(what: str, expected, measured) -> str:
    """A sentence comparing what the code implies with what was recorded."""
    if expected == measured:
        return f"{what}: {_fmt(measured)}, as the code has it."
    DISAGREEMENTS.append(f"{what}: expected {expected}, recorded {measured}")
    return (f"{what}: the code implies {_fmt(expected)}, the recording shows "
            f"{_fmt(measured)}.")


def _position(record: bytes) -> tuple[int, int]:
    return record[1] | record[2] << 8, record[3] | record[4] << 8


def _moves(frames: list[Frame], index: int) -> list[tuple[int, int]]:
    out = []
    for a, b in zip(frames, frames[1:]):
        (ua, va), (ub, vb) = _position(a.record(index)), _position(b.record(index))
        out.append((ub - ua, vb - va))
    return out


def _ms(frames: list[Frame]) -> str:
    times = sorted(round(f.tstates / T_STATES_PER_MS) for f in frames if f.turn_end)
    if not times:
        return ""
    return f"{times[0]}-{times[-1]} ms" if times[0] != times[-1] else f"{times[0]} ms"


def _halfway(speed: int, top: int) -> int:
    """#R$DCA8: halfway from the speed to the top speed, rounded down to even."""
    return (speed + top) // 2 & 0xFE


def _ramp(start: int, top: int, count: int) -> list[int]:
    out, speed = [], start
    for _ in range(count):
        speed = _halfway(speed, top)
        out.append(speed)
    return out


def _measure_walk(anim: dict) -> str:
    turns = anim["all"]
    speeds = [f.record(LEGS)[5] for f in turns]
    ramp = speeds[:5]
    steps = sorted({abs(du) + abs(dv) for du, dv in _moves(turns[-7:], LEGS)})
    frames = [f.record(LEGS)[0] & 7 for f in anim["turns"]]
    return " ".join([
        _check("His speed over the first five turns with walk held from standing",
               _ramp(0, 10, 5), ramp),
        _check("The distance moved a turn once it has settled, along the one axis he faces",
               [8], steps),
        _check("The walking frame, one a turn", [0, 1, 2, 3, 4, 5], frames),
        f"A turn took {_ms(anim['turns'])} here."])


def _measure_turn(anim: dict) -> str:
    turns = anim["turns"]
    changes = [n for n in range(1, len(turns))
               if _facing(turns[n].record(LEGS)) != _facing(turns[n - 1].record(LEGS))]
    gaps = sorted({b - a for a, b in zip(changes, changes[1:])})
    return (_check("Turns between one quarter turn and the next, the key held", [2], gaps)
            + " #R$DB89 sets the turn delay to 1, and a delay counts down a turn before "
            "he can turn again. Each quarter turn changes the view between behind "
            "(16-21) and the front (24-29), the mirror bit, or both, by #R$DCDC.")


def _measure_standing(anim: dict) -> str:
    turns = anim["turns"]
    poses, run = [], 0
    for frame in turns:
        if frame.record(TOP)[0] in (38, 39, 46, 47):
            run += 1
        elif run:
            poses.append(run)
            run = 0
    if run:
        poses.append(run)
    inside = all(2 <= p <= 10 for p in poses)
    return (f"Measured over {len(turns)} turns: {len(poses)} poses, lasting "
            f"{', '.join(str(p) for p in poses)} turns"
            + ("" if inside else " -- outside the two to nine turns the code gives, "
               "and one more for the turn that starts it")
            + ". One in 32 of the turns without one would start a pose, on average; the "
            "random number decides which turns.")


def _measure_bump(anim: dict) -> str:
    turns = anim["turns"]
    stopped = [f.record(LEGS)[3] for f in turns if f.record(TOP)[0] in (22, 30)]
    return (f"Measured: his V stopped at {_fmt(sorted(set(stopped)))} within the cell, with "
            f"his half-size of 16 that is the wall at the cell's edge; the top showed arms "
            f"out for {len(stopped)} turns, one for each turn walk was held against the "
            f"wall, and went back to following the legs when it was let go.")


def _measure_town_walk(anim: dict) -> str:
    turns = anim["turns"]
    cells = []
    for frame in turns:
        cell = (frame.record(LEGS)[2], frame.record(LEGS)[4])
        if not cells or cells[-1] != cell:
            cells.append(cell)
    steps = sorted({abs(du) for du, _ in _moves(turns[5:], LEGS)})
    return (_check("The distance he moved a turn along U once at speed", [8], steps)
            + f" He went through cells {', '.join(f'({u},{v})' for u, v in cells)}: "
            f"256 units a cell, 32 turns. The picture is the play area, redrawn every "
            f"turn round him; a turn took {_ms(turns)}.")


def _measure_town_turn(anim: dict) -> str:
    turns = anim["turns"]
    flips = [n for n in range(1, len(turns))
             if turns[n].variable(VIEW) != turns[n - 1].variable(VIEW)]
    held = [n for n, f in enumerate(turns) if VIEW_KEY in f.keys]
    after = [f - h for h, f in zip(held, flips)]
    return (_check("Turns from the one with Z held to the one the view changed in", [1, 1],
                   after)
            + " #R$DB68 acts when the key is let go. The panel's heading changes with "
            "it (#R$C29A).")


def _measure_arriving(anim: dict, memory) -> str:
    turns = anim["turns"]
    clouds = [f for f in turns if f.record(LEGS)[0] in range(VANISH, VANISH + 4)]
    arrive = [f.variable(ARRIVING) for f in turns if f.variable(ARRIVING) != HERE]
    tune = max(turns, key=lambda f: f.tstates)
    here = turns[-1]
    feet = here.record(LEGS)[15] - 72
    head = here.record(TOP)[15] + sprite_size(memory, here.record(TOP)[0])[1] - 72
    shown = sum(1 for f in turns if f.variable(ARRIVING) not in (HERE, ARRIVE_FROM))
    return " ".join([
        _check("Turns his records were the cloud", 4, len(clouds)),
        f"The turn his record emptied played the new-life tune and took "
        f"{round(tune.tstates / T_STATES_PER_MS)} ms; it ended with ARRIVING at "
        f"{arrive[0]}, which then went {', '.join(str(a) for a in arrive[1:4])} ... "
        f"{arrive[-1]}.",
        _check("Turns he was drawn cut short, ARRIVING counting from 42 to 74 by two",
               (ARRIVE_END - 2 - ARRIVE_FROM) // 2, shown),
        f"His feet stand {feet} lines above the bottom of the play area and the top of "
        f"his head {head}, so he rises into sight from ARRIVING {feet} and is whole "
        f"from {head}; the count goes on to 76, when it becomes $70 and he can move."])


def _measure_bonus(anim: dict, graphic: int) -> str:
    turns = anim["turns"]
    took = next(n for n, f in enumerate(turns) if f.record(BONUS)[0] == VANISH)
    if graphic == 2:
        speeds = [f.record(LEGS)[5] for f in turns[took:took + 5]]
        return " ".join([
            _check("His speed from the turn he touched it", [8] + _ramp(8, 18, 4), speeds),
            f"SPEED_TIME was {turns[took].variable(SPEED_TIME)} and TOP_SPEED "
            f"{turns[took].variable(TOP_SPEED)} after it; it counts down a turn at a time "
            f"(#R$DA7A), about 18 seconds at these turns."])
    return _check("His hits before and after he touched it",
                  (1, 3), (turns[took - 1].variable(HITS), turns[took].variable(HITS)))


def _measure_vanishing(anim: dict) -> str:
    graphics = [f.record(BONUS)[0] for f in anim["turns"]]
    return _check("The bonus record, turn by turn", [2, 12, 13, 14, 15, 1], graphics) + (
        " The record empties in the turn after 15; the 1 is the empty graphic these "
        "pages put in idle records, which keeps another bonus from coming at once.")


def _measure_antibodies(anim: dict) -> str:
    turns = anim["turns"]
    order, flights, steps = [], [], set()
    for index in (ANTIBODY, ANTIBODY2):
        run = 0
        for a, b in zip(turns, turns[1:]):
            ga, gb = a.record(index)[0], b.record(index)[0]
            if gb in range(80, 96):
                if ga not in range(80, 96):
                    order.append((turns.index(b), gb & 0xFC))
                    run = 0
                else:
                    du, dv = _position(b.record(index))[0] - _position(a.record(index))[0], \
                        _position(b.record(index))[1] - _position(a.record(index))[1]
                    steps.add(abs(du) + abs(dv))
                run += 1
            elif ga in range(80, 96):
                flights.append(run)
    thrown = [g for _, g in sorted(order)]
    return " ".join([
        _check("The antibodies' graphics in the order thrown", [92, 88, 84, 80], thrown),
        _check("The distance an antibody moved a turn", [24], sorted(steps)),
        f"Each flew {', '.join(str(f) for f in flights)} turns before the wall stopped it "
        f"and it became the cloud; the two antibody records were used by turns, the second "
        f"while the first was still busy with the last throw's cloud (#R$DAB7)."])


def _measure_monsters(anim: dict, first: int) -> str:
    turns = anim["turns"]
    steps, frames_ok = set(), True
    for n in range(4):
        index = MONSTERS + n
        for (du, dv), a, b in zip(_moves(turns, index), turns, turns[1:]):
            if a.record(index)[0] in range(first, first + 16) and \
                    b.record(index)[0] in range(first, first + 16):
                steps.add((abs(du), abs(dv)))
                if first == 64 and (b.record(index)[0] & 3) != ((a.record(index)[0] + 1) & 3):
                    frames_ok = False
    if first == 64:
        largest = max(max(s) for s in steps)
        return (f"Measured: steps of up to {largest} units a turn along U and V, both at "
                f"once (#R$DDCF gives each up to 14), and "
                + ("the frame stepped on every turn (#R$CEF8)." if frames_ok else
                   "the frame did not always step on.")
                + f" A turn took {_ms(turns)}.")
    along = sorted({max(s) for s in steps if min(s) == 0})
    return (_check("The distance a monster of 112-127 moved a turn, along one axis", [6],
                   along)
            + " Its picture is one of two by its facing, mirrored for U, its walking frame "
            f"flipped every turn (#R$D978). A turn took {_ms(turns)}.")


def _measure_appearing(anim: dict) -> str:
    index = anim["index"]
    graphics = [f.record(index)[0] for f in anim["turns"]]
    start = graphics.index(128)
    return (_check("The record's graphics from its first turn",
                   [128, 129, 130, 131], graphics[start:start + 4])
            + f" Then it became {graphics[start + 4]}: a monster of "
            + ("64-79" if graphics[start + 4] < 80 else "112-127")
            + ", of the kind of the villain nearest it (#R$C164).")


def _measure_creature(anim: dict) -> str:
    turns = anim["turns"]
    moving = [m for m, f in zip(_moves(turns, MONSTERS), turns[1:])
              if f.record(MONSTERS)[0] in range(136, 140)]
    burst = next(n for n, f in enumerate(turns) if f.record(MONSTERS)[0] == VANISH)
    return " ".join([
        _check("Its step each turn in U and V", [(-2, -2)], sorted(set(moving))),
        _check("The turn it touched him in, from 80 units off each way: touching needs "
               "less than 24 between them along each axis (its half-size of 16 and half "
               "his, #R$C55F)", (80 - 24) // 2 + 1, burst + 1),
        _check("His hits before and after", (3, 2),
               (turns[burst - 1].variable(HITS), turns[burst].variable(HITS)))])


STRIKE_POINTS = {0: 2500, 1: 2000, 2: 1500, 3: 1000}


def _measure_strike(anim: dict, key: str) -> str:
    _, thing, graphic = next(item for item in STRIKES if item[0] == key)
    turns = anim["turns"]
    before = int(_score(turns[0]))
    after = int(_score(turns[-1]))
    struck = next(n for n, f in enumerate(turns) if int(_score(f)) != before)
    monster = turns[struck].record(MONSTERS + 1)[0]
    antibody = 60 + 4 * thing
    if graphic == 64:
        return (_check("Points scored", 500, after - before)
                + " (#R$CE89 adds 5 at the score's hundreds; every score ends 00). "
                f"The antibody and the monster both became graphic {monster}, the cloud, "
                f"in the same turn.")
    outcome = ((graphic >> 2) + (antibody >> 2)) & 3
    text = [_check(f"Points for outcome {outcome} of #R$C0D1 (monster 112, antibody {antibody})",
                   STRIKE_POINTS[outcome], after - before)]
    if outcome == 1:
        text.append(_check("The monster's graphic after", 116, monster & 0xFC))
    elif outcome == 2:
        first = turns[struck].record(MONSTERS)[0]
        text.append(f"After the strike the first monster record held {first} and the "
                    f"second {monster}: the copy, and the original, each turned a quarter.")
    elif outcome == 3:
        text.append(_check("The monster's graphic after", 64, monster & 0xFC))
    else:
        text.append(_check("The monster's graphic after", VANISH, monster))
    return " ".join(text)


def _measure_villain(anim: dict) -> str:
    turns = anim["turns"]
    dying = [f for f in turns if f.record(VILLAINS)[0] in range(132, 136)]
    papers = [INKS[f.variable(LAST_FLASH) >> 3 & 7] for f in dying]
    # The updates run before the turn is counted (#R$C5B4), so the counter a
    # frame ends with is one more than the one #R$D847 read.
    counted = [(f.variable(TURNS) - 1) & 0xFF for f in dying]
    expected_papers = [INKS[c & 7] for c in counted]
    # A new frame only on odd turns: struck on an even one it shows 132 and
    # then two turns of each of 133-135; on an odd one it goes straight to
    # 133.
    expected_dying = 7 if counted[0] % 2 == 0 else 6
    sparkle_steps = sorted({abs(du) + abs(dv) for n in range(4)
                            for (du, dv), a, b in zip(_moves(turns, FINDS + n), turns, turns[1:])
                            if a.record(FINDS + n)[0] in range(140, 144)
                            and b.record(FINDS + n)[0] in range(140, 144)})
    return " ".join([
        _check("Turns the villain was dying (132-135), struck on "
               + ("an even" if expected_dying == 7 else "an odd") + " turn", expected_dying,
               len(dying)),
        "Its record was empty in the turn after.",
        _check("The play area's paper in those turns, by the turn counter's low bits",
               expected_papers, papers),
        _check("A sparkle's move a turn", [12], sparkle_steps),
        f"The score went from {_score(turns[0])} to {_score(turns[-1])}."])


def _measure_flash(anim: dict) -> str:
    turns = anim["turns"]
    third = [INKS[f.screen_bytes[0x1800 + 32 * 18 + 2] & 7] for f in turns]
    first = {INKS[f.screen_bytes[0x1800 + 32 * 22 + 2] & 7] for f in turns}
    return (f"Measured, the third place's ink turn by turn: {', '.join(third[:8])} ...; "
            f"the first place's: {', '.join(sorted(first))} throughout. "
            + _check("Turns before the third place's colour came round again", 4,
                     next(n for n in range(1, len(third)) if third[n] == third[0])))


def _measure_villains(anim: dict) -> str:
    turns = anim["turns"]
    steps = sorted({max(abs(du), abs(dv)) for n in range(4)
                    for du, dv in _moves(turns, VILLAINS + n) if du or dv})
    return (_check("The distance a villain moved a turn", [4], steps)
            + f" Over {len(turns)} turns, him standing still; the hum is played for each "
            f"villain drawn (#R$C332).")


def _measure_menu(anim: dict) -> str:
    turns = anim["turns"]
    return (f"Read once a television frame, {len(turns)} samples. The tune stopped at the "
            f"first key; each change of control method played the short tune before the "
            f"menu went on, which is why the flash moves a moment after the key.")


def _measure_ending(anim: dict, memory) -> str:
    turns = [f for f in anim["turns"] if f.turn_end and f.variable(ENDING)]
    front = memory[ENDING_RECORDS + 3 * 9 + 1] + 4
    parts = []
    for n in range(5, 9):
        x0, y0 = memory[ENDING_RECORDS + 3 * n + 1], memory[ENDING_RECORDS + 3 * n + 2]
        places = [(x0, y0)] + [(f.record(n)[10], f.record(n)[11]) for f in turns
                               if f.record(n)[0] in range(144, 152)]
        across = sum(1 for a, b in zip(places, places[1:]) if a[0] != b[0])
        down = sum(1 for a, b in zip(places, places[1:]) if a[1] != b[1])
        waited = sum(1 for f in turns if f.record(n)[0] in range(144, 152)
                     and (f.record(n)[10], f.record(n)[11]) == (x0, y0))
        parts.append(f"Record {n} (graphic {memory[ENDING_RECORDS + 3 * n]}) waited "
                     f"{waited} turns;")
        parts.append(_check(f"from x {x0} to the pit at x {front}, turns crossing",
                            -(-abs(front - x0) // 4), across))
        parts.append(_check("Turns drawn sinking, 4 lines a turn from y 128 while y is "
                            "48 or more", (y0 - 48) // 4, down))
    return " ".join(parts) + f" {len(turns)} turns of the ending in all, {_ms(turns)} each."


def measure(key: str, anim: dict, memory) -> str:
    """What was measured in an animation's run, against the code."""
    if key.startswith("walk-"):
        return _measure_walk(anim)
    if key.startswith("monsters-"):
        return _measure_monsters(anim, int(key.split("-")[1]))
    if key.startswith("strike-"):
        return _measure_strike(anim, key)
    simple = {"turn": _measure_turn, "standing": _measure_standing, "bump": _measure_bump,
              "town-walk": _measure_town_walk, "town-turn": _measure_town_turn,
              "vanishing": _measure_vanishing, "antibodies": _measure_antibodies,
              "appearing": _measure_appearing, "creature": _measure_creature,
              "villain-destroyed": _measure_villain, "panel-flash": _measure_flash,
              "villains": _measure_villains, "menu": _measure_menu}
    if key in simple:
        return simple[key](anim)
    if key == "arriving":
        return _measure_arriving(anim, memory)
    if key == "ending":
        return _measure_ending(anim, memory)
    if key == "bonus-speed":
        return _measure_bonus(anim, 2)
    if key == "bonus-hits":
        return _measure_bonus(anim, 3)
    raise KeyError(key)


# --------------------------------------------------------------------------
# The page.
# --------------------------------------------------------------------------

_WALK = ("The legs step through their six frames one a turn, the low three bits of the "
         "graphic counting 0 to 5 (#R$DCA8), 16-21 from behind and 24-29 from the "
         "front, his face showing (bit 3 of the graphic); the top copies them each "
         "turn, 32-37 or 40-45 (#R$D9EB), and stands on them. Facing +U or -V he comes "
         "towards the viewer. Which view, and whether it is mirrored, comes from the facing and the way "
         "the town is turned (#R$DCDC). His speed goes halfway to the top speed of 10 "
         "each turn, rounded down to an even number, so it settles at 8. He stays in the "
         "middle of the play area and the town moves under him. Here the open cell "
         "(24,23) of the town, walk held from standing; the six turns at full speed, "
         "over and over.")

TEXT = {
    "walk-0": ("Walking, facing +V", [16, 32], _WALK + " Facing +V he is seen from "
               "behind, mirrored."),
    "walk-1": ("Walking, facing +U", [24, 40], "As above, facing +U: seen from the front."),
    "walk-2": ("Walking, facing -V", [24, 40], "As above, facing -V: seen from the front, "
               "mirrored."),
    "walk-3": ("Walking, facing -U", [16, 32], "As above, facing -U: seen from behind."),
    "turn": ("Turning", [16, 24],
             "The turn keys turn him a quarter at a time (#R$DB89): left takes $40 off "
             "the facing, right adds it, and a turn sets a delay that lets the next come "
             "only every other turn while the key is held. He does not turn part way: "
             "the legs and top simply take the picture for the new facing, from the front or "
             "behind, mirrored or not (#R$DCDC). Here right held from facing +U until he "
             "faced +U again."),
    "standing": ("Standing still", [38, 39, 46, 47],
                 "While he is not turning, one turn in 32 the top starts a pose of its "
                 "own for two to nine turns, 38 or 39 from behind, 46 or 47 from the "
                 "front (#R$D9EB), and then goes back to matching the legs. Here 200 turns "
                 "standing, facing +U, towards the viewer, with the frames that do not change merged."),
    "bump": ("Walking into a wall", [22, 30],
             "When the legs are stopped by a wall (#R$DE59 sets bit 0 of their flags) the "
             "top throws its arms out -- graphic 22 seen from behind, 30 from the front -- "
             "stays where it is, and the bump warbles (#R$C3AA) every turn walk is held. "
             "Here walk held from the middle of cell (22,23), facing +V, into the building "
             "of cell (22,24), and then let go."),
    "town-walk": ("The town as he walks", [],
                  "Nightshade's own: the knight stands still in the middle of the play "
                  "area and the town is drawn round him every turn (#R$CF08) -- the cells "
                  "the drawing order picks round his, walls and all, back to front -- "
                  "into the buffer, which is copied to the screen at the end of the turn "
                  "(#R$E200). So the whole play area changes every turn, and a turn is "
                  "as long as the drawing takes. Here the street along row 23 of the town, "
                  "walked from its east end facing -U, from standing."),
    "town-turn": ("Turning the town round", [],
                  "Z or SYMBOL SHIFT shows the town from the other side (#R$DB68): the key "
                  "is latched while held and acts when it is let go, flipping VIEW, and "
                  "every cell is then looked up and drawn turned round (#R$D17D, "
                  "#R$D18E), the knight seen from his other side, and the panel's heading "
                  "changes between NORTH and SOUTH (#R$C29A). Here, standing in cell "
                  "(27,23) facing -U, Z pressed and let go twice. The whole screen."),
    "arriving": ("A life lost, and the next life rising from the ground", [12, 13, 14, 15],
                 "Standing in the open cell with one hit left, a monster of graphic 64 was "
                 "put on him (the only thing staged): its update found it touching him and "
                 "took the last hit (#R$CE89), which ends his life -- both his records and "
                 "the monster become the cloud, and his cell and facing go into the start "
                 "records. When the cloud has gone, #R$CBAC plays the new-life tune and "
                 "copies him back in, with ARRIVING at 40; each turn the legs' update adds "
                 "two (#R$DA7A), and the drawing shows only the lines of his two records "
                 "that are less than ARRIVING above the bottom of the play area "
                 "(#R$E3D9), so he rises out of the ground feet first. Nothing touches him "
                 "until ARRIVING has reached 76 and become $70 (#R$C55F)."),
    "bonus-speed": ("The bonus of a faster walk", [2],
                    "A bonus (#R$D76C) lies near him almost all the time, graphic 2 or "
                    "3. Touched, graphic 2 (#R$D727) becomes the cloud and gives him a "
                    "top speed of 18 for 255 turns: his speed goes on halfway to it each "
                    "turn, to 16, and the footsteps come twice as often. Here a bonus of "
                    "graphic 2 was put 72 units ahead of him in the open cell (staged), "
                    "and walk held."),
    "bonus-hits": ("The bonus of the hits back", [3],
                   "Graphic 3 (#R$D74C) gives him back all three hits of his life, and "
                   "his colour goes back to white (#R$C065, #R$C898). Here with one hit "
                   "left, green, a bonus of graphic 3 put 72 units ahead (staged), and "
                   "walk held."),
    "vanishing": ("The cloud things vanish in", [12, 13, 14, 15],
                  "Whatever is taken up, destroyed or killed becomes graphic 12 and "
                  "counts to 15, one a turn, and then its record is emptied, with a "
                  "crackle if it was drawn (#R$D7D8, #R$C435). The dying villain's "
                  "graphics 132-135 are drawn with the same pictures (#R$D847). Cut from "
                  "the run above: the bonus as he touches it."),
    "antibodies": ("Antibodies thrown", [80, 84, 88, 92],
                   "Fire throws the last thing taken up (#R$DAB7). An antibody goes into a "
                   "free antibody record as a copy of his legs' record, graphic 80, 84, 88 "
                   "or 92 by its kind, and flies at speed 12, moving twice a turn, its four "
                   "frames stepping on, until a wall, where it becomes the cloud "
                   "(#R$D7ED). The antibodies share their pictures with the finds they "
                   "were picked up as. Here he picked up four finds, one of each kind, by "
                   "the game's own pick-up (the finds were put where he stood), in cell "
                   "(22,23) facing the wall across it, and fire was pressed every eight "
                   "turns."),
    "monsters-64": ("The monsters of graphics 64-79", [64, 68, 72, 76],
                    "Four kinds of four frames (#R$CE89). They wander: every so often a "
                    "new random step of up to 14 units each way (#R$DDCF), the frame "
                    "stepped on every turn; touching him they vanish and take a hit, and "
                    "more than two cells off they are gone. Any antibody destroys them. "
                    "Here one of each kind, staged round him in the open cell from the "
                    "monster template (#R$CE79), him standing still."),
    "monsters-112": ("The monsters of graphics 112-127", [112, 116, 120, 124],
                     "The other monsters (#R$C083) walk: at speed 6 the way they face, "
                     "turning at walls and now and then (#R$DD28), those born in the "
                     "first half of every 256 turns towards the knight; the picture is "
                     "one of two by the facing, mirrored along U, its frame flipped "
                     "every turn (#R$D978). What an antibody does to one depends on the "
                     "kinds of both (below). Here one of each kind, staged round him in "
                     "the open cell, facing each way."),
    "appearing": ("A monster appearing", [128, 129, 130, 131],
                  "Every fourth turn a free monster record gets a monster appearing "
                  "(#R$CDE8) in his cell or one round it; it counts 128 to 131, one a "
                  "turn, with a rising note (#R$C455), and then becomes a monster of "
                  "64-79 or 112-127, by the random number, of the kind of the villain "
                  "nearest it (#R$C164). Here the game was left to run with him standing "
                  "still until one appeared where it was drawn; while waiting, the monster "
                  "records were emptied every turn, as walking away from monsters empties "
                  "them, so that new ones kept coming."),
    "creature": ("The creature", [136, 137, 138, 139],
                 "Every 256 turns a monster record becomes the creature, in his own cell "
                 "(#R$BF95). It makes for him two units a turn along U and along V "
                 "(#R$C02C), blipping, its four frames stepping on; led into a wall it "
                 "bursts for 1000 points, and touching him it bursts and takes a hit "
                 "(#R$BFF1), his colour going from white to yellow. Here put 80 units "
                 "off along each axis in his cell, where the game would put it (staged), "
                 "him standing still."),
    "strike-destroyed": ("An antibody strikes: destroyed", [112, 80],
                         "The monster's kind (bits 2-3 of 112-127) and the antibody's "
                         "(bits 2-3 of 80-95), added, pick one of four outcomes from "
                         "#R$C0D1, so each kind of monster is destroyed by one kind of "
                         "antibody. Monster 112 and antibody 80: 0, destroyed, 2500 "
                         "points (#R$C0DE). In each of these the monster was staged 96 "
                         "units ahead of him, facing him, in the open cell, after one "
                         "antibody of the kind was picked up and thrown."),
    "strike-changed": ("An antibody strikes: changed", [112, 84, 116],
                       "Monster 112 and antibody 84: 1, changed into the next kind, 116, "
                       "which another antibody would destroy; 2000 points (#R$C0ED)."),
    "strike-split": ("An antibody strikes: split", [112, 88],
                     "Monster 112 and antibody 88: 2, split, 1500 points (#R$C101). The "
                     "copy goes into the first monster record whatever is there -- the "
                     "loop that should find an empty record looks at the wrong one "
                     "(see #R$C101) -- and the two are turned a quarter each way."),
    "strike-demoted": ("An antibody strikes: turned into a lesser monster", [112, 92, 64],
                       "Monster 112 and antibody 92: 3, turned into a monster of 64 or 68 "
                       "(#R$C152), 1000 points; any antibody destroys those."),
    "strike-64": ("An antibody strikes a monster of 64-79", [64, 80],
                  "Any antibody destroys a monster of 64-79: both become the cloud, and "
                  "5 goes on the score, 500 as printed (#R$CE89). Here the monster was "
                  "put 60 units ahead, where the antibody would be a turn after the "
                  "throw, since these wander rather than walk at him."),
    "villain-destroyed": ("A villain destroyed, and its sparkles", [108, 11, 132, 140],
                          "Only the object in the same place in its records destroys a "
                          "villain (#R$C554). Thrown, an object flies at speed 12 twice a "
                          "turn (#R$D80C); striking its villain it becomes the cloud, "
                          "scores 250000, sends out four sparkles from the villain's place "
                          "(#R$D6D6), one each way, which fly on until they meet a wall "
                          "(#R$D70A), and redraws the panel's villains, the dead one now "
                          "in the object's colour (#R$C1FD). The villain dies for seven or "
                          "eight turns (#R$D847: a new frame only on odd turns), the play "
                          "area's paper a new colour each turn. "
                          "Here the object for villain 0 (the one drawn with graphic 108) "
                          "was picked up and thrown in the open cell, facing -U, and the "
                          "villain put 96 units ahead of him (staged). The whole screen."),
    "panel-flash": ("The panel's warning", [],
                    "The carried things are coloured every turn (#R$C4DC): each in its "
                    "own colour, but an object whose villain is less than five cells off "
                    "in column and row flashes through the four antibodies' colours, a "
                    "new one each turn -- the only sign of a villain out of sight. Here "
                    "he picked up the objects for villains 3 and 0 and two antibodies; "
                    "villain 0 was put three cells along U from him, kept standing, and "
                    "the others far off (staged). The panel, bottom four places."),
    "villains": ("The villains", [108, 104, 100, 96],
                 "A villain walks at speed 4 (#R$D94F), turning at walls and now and "
                 "then at random, its picture from its facing (#R$D978), humming while it "
                 "is on the screen; it kills him at a touch, whatever his hits. Here the "
                 "four put 80 units from him along U and V, facing away (staged), him "
                 "standing still."),
    "menu": ("The menu", [],
             "The menu (#R$C8CA) is Alien 8's, key 5 and all (see "
             '<a href="../alien8/Animations.html#menu">Alien 8\'s</a>), but its tune plays '
             "once until a key (#R$C63D), and a change of control method plays a short tune "
             "(#R$C7F4) where Alien 8 beeps. Here 2, 3, 4, 5 and 1 pressed in turn. The "
             "whole screen, read once a television frame."),
    "ending": ("The ending", list(range(144, 158)),
               "With the four villains gone and their sparkles off the screen, #R$D865 "
               "ends the game: #R$CC56 shows the percentage and the score under the "
               "game-over tune, then empties every record, fills ten from #R$CCE4 and "
               "lets the main loop run them: five pictures of the back of a pit and one "
               "of its front, updated last so it is drawn over what sinks, and the four "
               "villains, each waiting unseen while the record before it holds one on its "
               "way (#R$CD58) -- so they come record by record, the villains of 96, 100, "
               "104 and 108 -- carried across to the pit at up to four a turn, then sunk "
               "four lines a turn, in their own colours, with a note that rises. When the "
               "last is gone the end tune plays and the menu comes back (#R$CD10). Staged: "
               "the four villain records emptied at the start of a turn, as four destroyed "
               "villains leave them; the rest is the game's. The whole screen."),
}

GROUPS = [
    ("The knight", ["walk-0", "walk-1", "walk-2", "walk-3", "turn", "standing", "bump",
                    "arriving"]),
    ("The town", ["town-walk", "town-turn"]),
    ("Bonuses and the cloud", ["bonus-speed", "bonus-hits", "vanishing"]),
    ("Antibodies and monsters", ["antibodies", "appearing", "monsters-64", "monsters-112",
                                 "creature", "strike-destroyed", "strike-changed",
                                 "strike-split", "strike-demoted", "strike-64"]),
    ("The villains", ["villains", "panel-flash", "villain-destroyed"]),
    ("The menu and the ending", ["menu", "ending"]),
]

# Pictured at three times the Spectrum's size; the rest at twice.
SPRITE_SIZED = {"walk-0", "walk-1", "walk-2", "walk-3", "turn", "standing", "bump",
                "arriving", "vanishing", "appearing", "panel-flash"}
WHOLE = {"town-turn", "villain-destroyed", "menu", "ending"}
MAX_LISTED = 12


def _order(frames: list[tuple]) -> str:
    """The frames of the GIF: what each shows and for how long; frames in a
    row with the same label as one run."""
    runs = []
    for _, ms, label, _ in frames:
        if runs and runs[-1][0] == label:
            runs[-1][1] += 1
            runs[-1][2] += ms
        else:
            runs.append([label, 1, ms])
    parts = [f"{label} ({ms} ms)" if count == 1 else f"{label} x{count} ({ms} ms)"
             for label, count, ms in runs]
    total = sum(ms for _, ms, _, _ in frames) / 1000
    if len(parts) > MAX_LISTED:
        parts = parts[:MAX_LISTED - 1] + ["and so on"]
    return "; ".join(parts) + f". {len(frames)} frames, {total:.1f} s in all"


def _sprite_links(memory, graphics) -> str:
    return ", ".join(f"{g} (#R${_word(memory, GRAPHICS + 2 * g):04X})" for g in graphics)


def animations(snapshot: Path, log=print) -> dict[str, dict]:
    made = {}
    for facing, _ in FACINGS:
        made[f"walk-{facing >> 6}"] = run(snapshot, walking, facing)
    for make, args in [(turning, ()), (standing, ()), (bump, ()), (arriving, ()),
                       (town_walk, ()), (town_turn, ()), (bonus, (2,)), (bonus, (3,)),
                       (vanishing, ()), (antibodies, ()), (appearing, ()),
                       (monsters, (64,)), (monsters, (112,)), (creature, ())] + [
            (strike, (key,)) for key, _, _ in STRIKES] + [
            (villains, ()), (panel_flash, ()), (villain_destroyed, ()), (menu, ()),
            (ending, ())]:
        log(f"  {make.__name__}{'' if not args else ' ' + str(args[0])}")
        anim = run(snapshot, make, *args)
        made[anim["key"]] = anim
    return made


def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    """Write the GIFs into html_dir/images/animations and return the
    Animations section."""
    out_dir = html_dir / "images" / "animations"
    out_dir.mkdir(parents=True, exist_ok=True)
    log("Running Nightshade's animations in the game's own code...")
    DISAGREEMENTS.clear()
    made = animations(snapshot, log)
    memory = bn.game_memory(snapshot)
    entries = skool_entries()
    lines = ['<div class="kl-list">',
             "<p>Nightshade's objects animate the way the Filmation games' do: an "
             "object's graphic -- the first byte of its 16-byte record -- chooses both "
             "the routine that runs it every turn, through #R$D599, and its sprite, "
             "through #R$6E9E, so a thing animates by changing its own graphic. The "
             "knight's legs count six walking frames, the monsters and the sparkles four, "
             "whatever vanishes counts from 12 to 15. What is Nightshade's own is the "
             "town: the knight stands in the middle of the play area and the town is "
             "drawn round him again every turn, so it moves as he walks and turns round "
             "when he turns it. (See "
             '<a href="../knightlore/Animations.html">Knight Lore\'s animations</a> and '
             '<a href="../alien8/Animations.html">Alien 8\'s</a> for the rooms of the '
             "first Filmation games.)</p>",
             "<p>Each animation below was made by running the game in SkoolKit's "
             "simulator when these pages were built: started from the menu with the "
             "keyboard, and put into the cell wanted by the game's own restart (the cell "
             "and facing written into the start records at #R$CC36 and his life ended, "
             "so that #R$CBAC starts the next there); then run a turn at a time -- every "
             "record's update, the town drawn round him, the buffer copied to the screen "
             "-- with each picture read off the screen as the turn left it. So that "
             "nothing wanders into a picture about something else, the records monsters, "
             "finds and bonuses come into were kept busy with an empty graphic that does "
             "nothing, unless the animation is about them; where more was staged, the "
             "animation says what. Nightshade's main loop has no wait: interrupts are "
             "off and a turn lasts as long as its work, about 60 to 90 ms in the town. "
             "Each picture is shown for as long as it stayed on the screen -- until the "
             "next turn's was copied over it -- counted in T-states at 3.5MHz; the "
             "simulator has none of a real Spectrum's memory contention, so the game "
             "runs a little faster here than on the machine. A frame drawn the same as "
             "the one before is merged into it. The menu and the screens of the ending "
             "have no turns: they were read once a television frame (69,888 T-states), "
             "FLASH shown as the ULA shows it.</p>",
             "<p>Under each: the graphics shown with their sprites, what was measured in "
             "the run beside what the code says it should be, and the frames of the "
             "picture with what they show and how long each lasts.</p>"]
    for heading, keys in GROUPS:
        lines.append(f"<h3>{_esc(heading)}</h3>")
        for key in keys:
            anim = made[key]
            title, graphics, words = TEXT[key]
            frames = anim["frames"]
            save_gif(out_dir / f"{key}.gif", frames)
            width, height = frames[0][0].size
            scale = 3 if key in SPRITE_SIZED else 2
            css = "kl-sprite" if key in SPRITE_SIZED else ("kl-scene" if key in WHOLE
                                                           else "kl-piece")
            lines += [f'<div class="kl-item" id="{key}">',
                      f"<h4>{_esc(title)}</h4>",
                      f'<img class="{css}" src="images/animations/{key}.gif" '
                      f'alt="{_esc(title)}" width="{width * scale}" height="{height * scale}">',
                      f"<p>{link(words, entries)}</p>"]
            if graphics:
                lines.append(f"<p>Graphics and their sprites: "
                             f"{link(_sprite_links(memory, graphics), entries)}.</p>")
            lines += [f"<p>{link(_esc(measure(key, anim, memory)), entries)}</p>",
                      f"<p>In the picture: {_esc(_order(frames))}.</p>",
                      "</div>"]
    lines.append("</div>")
    body = "\n".join(lines)
    for line in body.splitlines():
        if line.startswith((";", "[")):
            raise RuntimeError(f"a section line starts with {line[0]!r}: {line[:40]}")
    for problem in DISAGREEMENTS:
        log(f"  WARNING: animation disagrees with the code: {problem}")
    return {"Animations": body}
