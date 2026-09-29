"""Fairlight's animations, as GIFs of the game running its own code.

build_fairlight.py --html calls build(), which writes the GIFs into the HTML
directory and returns the Animations section. Nothing here is committed
output: every frame is the game's own drawing.

HOW FAIRLIGHT ANIMATES. An object's record (twenty bytes from #R$BC18, the
knight's the seventh at #R$BC90) holds the address of the sprite it shows at
+4 and +5, and the routine that updates it every pass (the author's CHE3D,
#R$F1E0, and #R$F309 after it) changes that address as it goes: a run of
frames stepped by the author's ANIM (#R$F595) -- forward to the last and
back, so a run of three shows 0, 1, 2, 1, 0 ... -- or a frame chosen by what
the object is doing. Where a picture has to face another way, the sprites of
the knight, the troll and the wraith are turned round in memory (MIRROR,
#R$F127); the guards have a set of frames for each way they walk. Then the
object is redrawn where it now stands: #R$ECBD rebuilds that rectangle of
the screen, and only that one, from the clean copy of the room (#R$C000),
the object's own sprite, and whatever overlaps it in front or behind.

HOW THEY ARE MADE. Each animation is the game running in SkoolKit's
simulator, from the snapshot at $C47C, started the way the build's sessions
start it (build_fairlight.Machine: any key for the tune, any key for the
title), which leaves it in room 29, the first room of a game, at START_PASS
($FF21), the top of the main loop's pass. Another room is entered the way a
new game enters its first (build_fairlight._enter: ROOM set and TELE,
$F09B). That shortcut skips the author's EEN (#R$F906), which turns a troll's
or a wraith's sprites back as a room is left; every run here starts from the
snapshot and enters at most one room before its subject, and the first room
(29) has neither, so their sprites are as the tape has them when the run
begins. Where more is staged -- the knight put somewhere, a creature's place
changed in the object table before the room is entered, LIFE topped up --
the function says so, and so does the page.

Then the game is run a pass at a time -- a pass being the main loop from
START_PASS back to it: the keys, LIFE, the message line, and every record
from the knight's updated and redrawn (#R$FE47) -- and each frame of a GIF
is the screen as that pass left it, read from screen memory. Fairlight's
main loop does not wait for the television's frame -- interrupts are off
from the start-up on (#R$C47C) -- so a pass lasts as long as its work, and
each picture is shown until the next pass has finished drawing: for as long
as that pass took, counted in T-states at 3.5MHz. The simulator has no
memory contention, so the game runs a little faster here than on a
Spectrum. Where there are no passes -- a room being drawn, the title, GAME
OVER, the end of the quest -- the screen is read once a television frame
(69,888 T-states).

A room is drawn black on black (#R$E5BA clears the attributes) and coloured
only when it is finished (#R$F0FB); the pictures of a room being drawn show
the pixels in the colours the room will get, and say so.

THE CREATURES ALONE. The creatures are shown alone, as the Sprites page
draws a sprite: in runs made as above, the creature's record and the bytes
of the sprite it pointed at were kept at the end of every pass, and that
sprite -- as it lay in memory then, turned round or not -- is drawn by
itself by the game's own REDRAW_OBJECT (#R$ECBD) and compositor (#R$E3E4)
on a spare machine, from a record holding it alone, once over a clean copy
of zeros and once over ones: a pixel set in the first is the image, one
cleared in the second the solid part of the mask. Each picture is checked
against the sprite's bytes as the listing reads them (fairlight_data's
sprite_image), and the bytes against the tape's, as they are or turned
round, and a difference stops the build.
"""
from __future__ import annotations

import html
import re
from pathlib import Path

import build_fairlight as bf
import fairlight_data as fd

SKOOL = bf.OUT_DIR / "fairlight.skool"
TSTATES_PER_SECOND = 3_500_000
T_STATES_PER_MS = 3500
TV_FRAME = 69_888                 # T-states in a 48K Spectrum's frame
FLASH_FRAMES = 16                 # the ULA swaps FLASH cells every 16 frames
PASS_LIMIT = 30 * TSTATES_PER_SECOND   # a pass longer than this is a hang

# Where the game is, as it runs.
START_PASS = 0xFF21               # the author's ST3: once a pass of the main loop
TITLE_WAIT = bf.TITLE_WAIT        # PAUS: waiting for a key (title, GAME OVER, the end)
ENTER_GAME_ROOM = bf.ENTER_GAME_ROOM
GAME_STACK = bf.GAME_STACK
DRAW_ROOM = 0xE55B                # DRAW_CURRENT_ROOM
ROOM_COMMAND = 0xE5A6             # RUN_ROOM_COMMANDS: fetches each command
REDRAW = 0xECBD                   # REDRAW_OBJECT, the author's SRP
COMPOSITE = 0xE3E4                # COMPOSITE_TO_SCREEN
ISO_MOVE = 0xE4F7

# The records and the variables.
RECORDS = 0xBC18                  # record 1; the knight's is 7
RECORD_SIZE = 20
RECORDS_END = 0xC000
KNIGHT = bf.KNIGHT
KNIGHT_NUMBER = 7
VARIABLES = 0xFF80
OBJECT_COUNT = 0xFF80
THIS_RECORD = 0xFF83
LIFE_TENS, LIFE_UNITS = bf.LIFE_TENS, bf.LIFE_UNITS
GAME_FLAGS = 0xFF97
ROOM = bf.ROOM
CARRIED = bf.CARRIED
SELECTED = bf.SELECTED
FALL_COUNT = 0xFF94
OBJECTS = 0xA924                  # the object table, where the game reads it
CLEAN_COPY = 0xC000               # the clean copy of the screen (RESTOR)

SCREEN = 0x4000
SCREEN_END = 0x5B00
WHOLE_SCREEN = (0, 0, 256, 192)

# The Spectrum's colours, normal then BRIGHT, as palette indices 0-15.
SPECTRUM = [(0, 0, 0), (0, 0, 0xD7), (0xD7, 0, 0), (0xD7, 0, 0xD7),
            (0, 0xD7, 0), (0, 0xD7, 0xD7), (0xD7, 0xD7, 0), (0xD7, 0xD7, 0xD7)]
SPECTRUM_BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF),
                   (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0), (0xFF, 0xFF, 0xFF)]
PALETTE = SPECTRUM + SPECTRUM_BRIGHT
# Index 16: the outline drawn round a rectangle the compositor rebuilt.
HIGHLIGHT = 16
_FLAT_PALETTE = ([c for colour in PALETTE for c in colour] + [0xFF, 0x60, 0x00]
                 + [0] * (768 - 3 * (len(PALETTE) + 1)))


def _esc(text: str) -> str:
    return html.escape(text, quote=False)


def _word(memory, address: int) -> int:
    return memory[address] | (memory[address + 1] << 8)


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
# The screen.
# --------------------------------------------------------------------------

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


def _indices(data: bytes, flash_inverted: bool, colour=None) -> bytearray:
    """The display as palette indices, 256 by 192; with `colour`, every
    character cell in that attribute instead of its own."""
    table = _TRANSLATE[flash_inverted]
    out = bytearray(256 * 192)
    for y in range(192):
        row = ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
        attrs = 0x1800 + (y >> 3) * 32
        at = y * 256
        for column in range(32):
            attr = data[attrs + column] if colour is None else colour
            out[at:at + 8] = _BITS[data[row + column]].translate(table[attr])
            at += 8
    return out


def screen_picture(data: bytes, flash_inverted: bool = False, colour=None):
    from PIL import Image

    image = Image.frombytes("P", (256, 192), bytes(_indices(data, flash_inverted, colour)))
    image.putpalette(_FLAT_PALETTE)
    return image


# --------------------------------------------------------------------------
# The game, running.
# --------------------------------------------------------------------------

class Frame:
    """What one pass (or one television frame) left: the screen, the object
    records, the variables, how long it took, the keys held, and the bytes of
    the sprites of the records asked for (`keep`), as they lay in memory."""

    def __init__(self, memory, start: int, end: int, keys=(), keep=(), pc: int = 0):
        self.keys = frozenset(keys)
        self.screen_bytes = bytes(memory[SCREEN:SCREEN_END])
        self.records = bytes(memory[RECORDS:RECORDS_END])
        self.variables = bytes(memory[VARIABLES:0x10000])
        self.start, self.end = start, end
        self.tstates = end - start
        self.pc = pc
        self.label = ""
        self.kind = "pass"
        self.stopped = False
        self.sprites = {}
        for number in keep:
            record = self.record(number)
            address = record[4] | record[5] << 8
            if address:
                length = fd.sprite_length(record[2], record[3])
                self.sprites[address] = bytes(memory[address:address + length])

    def record(self, number: int) -> bytes:
        at = RECORD_SIZE * (number - 1)
        return self.records[at:at + RECORD_SIZE]

    def variable(self, address: int) -> int:
        return self.variables[address - VARIABLES]

    def life(self) -> int:
        return 10 * self.variable(LIFE_TENS) + self.variable(LIFE_UNITS)

    def screen(self, colour=None):
        inverted = bool((self.end // TV_FRAME // FLASH_FRAMES) & 1)
        return screen_picture(self.screen_bytes, inverted, colour)


class Game:
    """Fairlight on a simulated 48K Spectrum, from the snapshot at $C47C:
    build_fairlight's Machine, whose tracer holds keys."""

    def __init__(self, snapshot: Path):
        from skoolkit.simutils import T

        self.machine = bf.Machine(snapshot)
        self.sim = self.machine.simulator
        self.memory = self.sim.memory
        self.T = T
        self.keep: tuple = ()

    @property
    def now(self) -> int:
        return self.sim.registers[self.T]

    @property
    def pc(self) -> int:
        return self.machine.pc

    def play(self, steps, label: str = "animation") -> None:
        self.machine.play(steps, label)

    def poke(self, address: int, value) -> None:
        if isinstance(value, (list, tuple, bytes, bytearray)):
            for offset, byte in enumerate(value):
                self.memory[address + offset] = byte
        else:
            self.memory[address] = value

    def peek(self, address: int) -> int:
        return self.memory[address]

    def hold(self, keys=()) -> None:
        self.machine.tracer.keys = set(keys)

    def run_to(self, address: int, limit: int = PASS_LIMIT) -> None:
        from skoolkit.simutils import PC

        self.sim.trace(self.machine.pc, address, 0, self.now + limit, False, None, None,
                       None, None, None)
        self.machine.pc = self.sim.registers[PC]
        if self.machine.pc != address:
            raise RuntimeError(f"${address:04X} was not reached (PC ${self.machine.pc:04X})")

    def to_pass(self) -> None:
        if self.machine.pc != START_PASS:
            self.run_to(START_PASS)

    def frame(self, start: int) -> Frame:
        return Frame(self.memory, start, self.now, self.machine.tracer.keys, self.keep,
                     self.machine.pc)

    def pass_(self) -> Frame:
        """One pass, START_PASS to START_PASS."""
        self.to_pass()
        start = self.now
        self.run_to(START_PASS)
        return self.frame(start)

    def passes(self, count: int, each=None) -> list[Frame]:
        frames = []
        for _ in range(count):
            self.to_pass()
            if each is not None:
                each(self)
            frames.append(self.pass_())
        return frames

    def sample(self, tstates: int = TV_FRAME, stop: int = 0) -> Frame:
        """Run for `tstates` whatever the game is doing, or until `stop`."""
        from skoolkit.simutils import PC

        start = self.now
        self.sim.trace(self.machine.pc, stop, 0, start + tstates, False, None, None,
                       None, None, None)
        self.machine.pc = self.sim.registers[PC]
        frame = self.frame(start)
        frame.stopped = bool(stop) and self.machine.pc == stop
        return frame

    def call(self, address: int, **registers) -> None:
        """Run a routine of the game's from here, with registers set, and
        come back: the registers and the stack as they were, but for what the
        routine did to memory. It returns to an address in the ROM that the
        game never runs ($0008), where the run stops."""
        from skoolkit import simutils as su

        regs = self.sim.registers
        saved = list(regs)
        names = {"A": su.A, "B": su.B, "C": su.C, "D": su.D, "E": su.E, "H": su.H,
                 "L": su.L}
        for name, value in registers.items():
            if name in ("IX", "IY"):
                regs[su.IXh if name == "IX" else su.IYh] = value >> 8
                regs[su.IXl if name == "IX" else su.IYl] = value & 0xFF
            elif name in ("BC", "DE", "HL"):
                regs[names[name[0]]], regs[names[name[1]]] = value >> 8, value & 0xFF
            else:
                regs[names[name]] = value
        sp = (regs[su.SP] - 64) & 0xFFFF
        sp -= 2
        self.memory[sp], self.memory[sp + 1] = 0x08, 0x00
        regs[su.SP] = sp
        self.sim.trace(address, 0x0008, 0, self.now + TSTATES_PER_SECOND, False, None, None,
                       None, None, None)
        if regs[su.PC] != 0x0008:
            raise RuntimeError(f"the call of ${address:04X} did not return (PC "
                               f"${regs[su.PC]:04X})")
        tstates = regs[su.T]
        for index, value in enumerate(saved):
            regs[index] = value
        regs[su.T] = tstates
        regs[su.PC] = self.machine.pc

    # -- staging -----------------------------------------------------------

    def alive(self) -> None:
        """LIFE to 99, as the build's sessions keep it."""
        self.poke(LIFE_TENS, 9)
        self.poke(LIFE_UNITS, 9)

    def start_game(self) -> None:
        """Through the tune and the title into room 29, the first room, as the
        build's sessions start."""
        self.play(bf._start())
        self.to_pass()

    def enter(self, room: int) -> None:
        """Into a room as a new game enters its first (build_fairlight._enter)."""
        self.play(bf._enter(room))
        self.to_pass()

    def move(self, record: int, x: int, y: int, z: int) -> None:
        """Move a record -- anywhere in memory -- to x, y, z (+6, +7, +8) by
        the game's own ISO_MOVE (#R$E4F7), so that its place on the screen
        moves with it."""
        self.call(ISO_MOVE, IX=record, B=x, D=y, H=z)

    def table_entries(self, room: int) -> list[int]:
        """The addresses of the object table's records for `room`."""
        out, address = [], OBJECTS
        while self.peek(address) != 0xFF:
            if self.peek(address) == room:
                out.append(address)
            address += 6 if self.peek(address + 1) < 0x46 else 11
        return out

    def records_in_use(self) -> list[int]:
        return list(range(KNIGHT_NUMBER, self.peek(OBJECT_COUNT) + 1))

    def record_address(self, number: int) -> int:
        return RECORDS + RECORD_SIZE * (number - 1)

    def record(self, number: int) -> list[int]:
        address = self.record_address(number)
        return list(self.memory[address:address + RECORD_SIZE])


def started(snapshot: Path) -> Game:
    game = Game(snapshot)
    game.start_game()
    return game


# --------------------------------------------------------------------------
# Things alone: a record and its sprite's bytes kept at the end of a pass,
# drawn by themselves by the game's own redraw.
# --------------------------------------------------------------------------

# A picture of a thing alone is what the Sprites page shows, in the game's
# colours: Fairlight draws black ink on each room's paper, so the sprite's
# image is black ink, the solid part of its mask the Spectrum's white paper
# (fairlight_data.sprite_image), and it is clear where the background shows
# through. In a GIF that is three colours, the first transparent; it is given
# the Sprites page's blue-grey for a viewer that ignores transparency, and
# the page shows them on that blue-grey too (kl-sprite).
ALONE_CLEAR, ALONE_INK, ALONE_PAPER = 0, 1, 2
_ALONE_BACKING = (0x5A, 0x5A, 0x8C)
_ALONE_PALETTE = (list(_ALONE_BACKING) + list(fd.INK_RGB) + list(fd.PAPER_RGB)
                  + [0] * (768 - 9))
ALONE_SCALE = 3                   # on the page, three times the Spectrum's size
# Where the spare machine draws a thing: x on a byte boundary, so that the
# compositor shifts nothing, and the top row well inside the screen.
RIG_X, RIG_Y = 64, 150


def mirrored_sprite(data: bytes, width: int) -> bytes:
    """A sprite's bytes turned end for end, row by row, image and mask, as
    the author's MW (#R$F157) turns them in place."""
    columns = width // 8
    out = bytearray()
    for row in range(len(data) // columns):
        line = data[row * columns:(row + 1) * columns]
        out += bytes(int(f"{byte:08b}"[::-1], 2) for byte in reversed(line))
    return bytes(out)


class Rig:
    """A spare machine for drawing one record's sprite by itself with the
    game's own REDRAW_OBJECT (#R$ECBD): the record goes into the knight's
    place, the seventh, with OBJECT_COUNT and THIS_RECORD 7, so that nothing
    else is looked at; its sprite's bytes go where the record points; the
    clean copy of the screen (#R$C000), which the compositor (#R$E3E4) shows
    wherever the mask lets it, is filled with zeros and then with ones. A
    pixel set over the zeros is the image; one clear over the ones, the solid
    part of the mask."""

    def __init__(self, snapshot: Path):
        self.game = started(snapshot)
        self.tape = bf.game_memory(snapshot)
        self.drawn: dict = {}

    def _draw(self, record: bytes, data: bytes, fill: int) -> list[list[int]]:
        game = self.game
        width, height = record[2], record[3]
        address = record[4] | record[5] << 8
        spare = bytearray(record)
        spare[0], spare[1] = RIG_X, RIG_Y
        spare[16] &= 0xDF            # not carried or gone
        game.poke(KNIGHT, spare)
        game.poke(address, data)
        game.poke(OBJECT_COUNT, KNIGHT_NUMBER)
        game.poke(THIS_RECORD, KNIGHT_NUMBER)
        game.poke(GAME_FLAGS, 0)
        game.poke(CLEAN_COPY, [fill] * 6144)
        game.call(REDRAW, HL=KNIGHT)
        screen = game.memory
        rows = []
        for y in range(height):
            line = 191 - RIG_Y + y
            base = SCREEN | ((line & 0xC0) << 5) | ((line & 7) << 8) | ((line & 0x38) << 2)
            bits = []
            for column in range(width // 8):
                byte = screen[base + RIG_X // 8 + column]
                bits += [(byte >> (7 - b)) & 1 for b in range(8)]
            rows.append(bits)
        return rows

    def picture(self, record: bytes, data: bytes):
        """The sprite `data` (image then mask, as it lay in memory) drawn from
        `record` (RGBA)."""
        from PIL import Image

        key = (bytes(record[2:6]), data)
        if key in self.drawn:
            return self.drawn[key]
        width, height = record[2], record[3]
        image_rows = self._draw(record, data, 0x00)
        mask_rows = self._draw(record, data, 0xFF)
        picture = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        pixels = picture.load()
        for y in range(height):
            for x in range(width):
                if image_rows[y][x]:
                    pixels[x, y] = fd.INK_RGB + (255,)
                elif not mask_rows[y][x]:
                    pixels[x, y] = fd.PAPER_RGB + (255,)
        # Checked against the sprite's bytes as the listing reads them
        # (fairlight_data.sprite_image): where the mask is set the background
        # shows, whatever the image says, as the compositor has it.
        address = record[4] | record[5] << 8
        copy = list(self.game.memory)
        copy[address:address + len(data)] = data
        listing = fd.sprite_image(copy, address, width, height, 1)
        if list(picture.getdata()) != list(listing.getdata()):
            raise ValueError(f"animations: the sprite at ${address:04X} drawn by #R$ECBD is not "
                             f"the sprite the listing reads")
        self.drawn[key] = picture
        return picture

    def turned(self, record: bytes, data: bytes) -> bool:
        """Whether the bytes are the tape's sprite turned round (True) or as
        the tape has it (False); anything else stops the build."""
        address = record[4] | record[5] << 8
        tape = bytes(self.tape[address:address + len(data)])
        if data == tape:
            return False
        size = len(data) // 2
        if data == mirrored_sprite(tape[:size], record[2]) + mirrored_sprite(tape[size:],
                                                                             record[2]):
            return True
        raise ValueError(f"animations: the sprite at ${address:04X} is neither the tape's "
                         f"nor the tape's turned round")


# --------------------------------------------------------------------------
# Scenes: the screen, cropped, a frame a pass.
# --------------------------------------------------------------------------

def drawn_box(record: bytes):
    """Where a record's sprite is on the screen, as a box of pixels (left,
    top, right, bottom), or None for a record with no sprite: +0 is x, +1 the
    top row counted up from the bottom of the screen, +2 and +3 the width
    and height (#R$ECBD)."""
    if not (record[4] or record[5]) or not record[2] or not record[3]:
        return None
    left, top = record[0], 191 - record[1]
    return (max(0, left), max(0, top), min(256, left + record[2]), min(192, top + record[3]))


def _union(a, b):
    if a is None:
        return b
    if b is None:
        return a
    return min(a[0], b[0]), min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3])


def crop_box(frames: list[Frame], records=(), margin: int = 6, extra=None):
    """The union of what `records` drew in all the frames (and `extra`), with
    a margin, inside the screen."""
    union = extra
    for frame in frames:
        for number in records:
            union = _union(union, drawn_box(frame.record(number)))
    if union is None:
        raise ValueError("nothing was drawn")
    return (max(0, union[0] - margin), max(0, union[1] - margin),
            min(256, union[2] + margin), min(192, union[3] + margin))


def duration(tstates: int) -> int:
    """A frame's time in milliseconds, to the 10ms a GIF can say."""
    return max(20, round(tstates / T_STATES_PER_MS / 10) * 10)


def shown_for(frames: list[Frame]) -> list[int]:
    """How long each frame's picture stays on the screen, in T-states: until
    the next frame's is complete, which takes as long as the next frame (the
    last frame, for its own)."""
    return [frames[i + 1].tstates if i + 1 < len(frames) else frames[i].tstates
            for i in range(len(frames))]


def merge(pictures: list, times: list[int], labels: list[str]) -> list[tuple]:
    """(picture, milliseconds, label, tstates) per frame shown, identical
    pictures in a row as one, shown for their total time."""
    out = []
    for picture, tstates, label in zip(pictures, times, labels):
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


def scene(key: str, frames: list[Frame], records=(), labels=None, box=None, margin: int = 6,
          extra=None, times=None) -> dict:
    """An animation of the screen, cropped to what `records` drew (or to
    `box`), a picture a frame, each shown until the next is complete."""
    if box is None:
        box = crop_box(frames, records, margin, extra)
    pictures = [frame.screen(getattr(frame, "colour", None)).crop(box) for frame in frames]
    if labels is None:
        labels = [frame.label for frame in frames]
    if times is None:
        times = shown_for(frames)
    return {"key": key, "frames": merge(pictures, times, labels), "passes": frames,
            "box": box}


# --------------------------------------------------------------------------
# Things alone: the pictures, the GIFs, and the longest stretches.
# --------------------------------------------------------------------------

def alone_frames(rig: Rig, passes: list[Frame], number: int, first: int, end: int,
                 cycle: int = 1, label=None) -> list[tuple]:
    """(picture, milliseconds, label, tstates) for record `number` in passes
    first to end - 1 of a run: the sprite it pointed at, as it lay in memory
    at the end of the pass, drawn alone. Cut to whole rounds of `cycle`
    passes, so that the GIF loops as the game goes round; each picture shown
    for as long as the scenes show its pass (shown_for(), over the whole
    run), identical pictures in a row as one."""
    count = end - first
    if count >= cycle:
        count -= count % cycle
    times = shown_for(passes)
    out = []
    for n in range(first, first + count):
        record = passes[n].record(number)
        address = record[4] | record[5] << 8
        data = passes[n].sprites[address]
        picture = rig.picture(record, data)
        name = label(record) if label else f"${address:04X}"
        if rig.turned(record, data):
            name += " turned"
        if out and out[-1][0].size == picture.size and \
                out[-1][0].tobytes() == picture.tobytes():
            last = out[-1]
            if name not in last[1]:
                last[1].append(name)
            out[-1] = (last[0], last[1], last[2] + times[n])
        else:
            out.append((picture, [name], times[n]))
    return [(p, duration(t), "/".join(names), t) for p, names, t in out]


def _canvas(pictures) -> tuple[int, int]:
    return max(p.width for p in pictures), max(p.height for p in pictures)


def save_alone_gif(path: Path, frames: list[tuple], size: tuple[int, int]) -> None:
    """Frames (picture, milliseconds, ...) as a looping GIF, transparent
    where the sprite lets the background through. Every frame is the whole
    canvas with its picture at the bottom left, so that a thing stands on
    the same ground whatever its frame, and is cleared before the next
    (disposal 2), or the clear parts of one would show the last. The GIF is
    read back and each frame compared with what was meant."""
    from PIL import Image

    images = []
    for picture, *_ in frames:
        canvas = Image.new("P", size, ALONE_CLEAR)
        canvas.putpalette(_ALONE_PALETTE)
        pixels, source = canvas.load(), picture.load()
        top = size[1] - picture.height
        for y in range(picture.height):
            for x in range(picture.width):
                red, green, blue, alpha = source[x, y]
                if alpha:
                    colour = (red, green, blue)
                    if colour not in (fd.INK_RGB, fd.PAPER_RGB):
                        raise ValueError(f"animations: {path.name} has a pixel neither ink "
                                         "nor paper")
                    pixels[x, top + y] = ALONE_INK if colour == fd.INK_RGB else ALONE_PAPER
        images.append(canvas)
    if len(images) == 1:
        images[0].save(path, transparency=ALONE_CLEAR)
    else:
        images[0].save(path, save_all=True, append_images=images[1:], loop=0,
                       duration=[ms for _, ms, *_ in frames], disposal=2,
                       transparency=ALONE_CLEAR, optimize=False)
    with Image.open(path) as gif:
        for n, meant in enumerate(images):
            gif.seek(n)
            got = gif.convert("RGBA")
            want = meant.convert("RGBA")
            for (r1, g1, b1, a1), (r2, g2, b2, _) in zip(got.getdata(), want.getdata()):
                expected = None if (r2, g2, b2) == _ALONE_BACKING else (r2, g2, b2)
                if (expected is None and a1) or (expected is not None and
                                                 (not a1 or (r1, g1, b1) != expected)):
                    raise RuntimeError(f"animations: {path.name} frame {n} did not read back "
                                       "as written")


def _longest(runs: list[list[Frame]], numbers: list[int], look) -> dict:
    """For each value look(record) gives other than None, the longest stretch
    of passes in a row, in any run, in which the run's record gave it: value
    -> (length, run index, record number, first pass, end)."""
    best: dict = {}
    for index, passes in enumerate(runs):
        number = numbers[index]
        n = 0
        while n < len(passes):
            value = look(passes[n].record(number))
            if value is None:
                n += 1
                continue
            end = n
            while end < len(passes) and look(passes[end].record(number)) == value:
                end += 1
            if value not in best or end - n > best[value][0]:
                best[value] = (end - n, index, number, n, end)
            n = end
    return best


# --------------------------------------------------------------------------
# The runs. Each is made once per snapshot and kept: some animations are cut
# from another's run.
# --------------------------------------------------------------------------

_RUNS: dict = {}


def run(snapshot: Path, make, *args):
    """make(snapshot, *args), made once per snapshot and kept."""
    key = (str(snapshot), make.__name__, args)
    if key not in _RUNS:
        _RUNS[key] = make(snapshot, *args)
    return _RUNS[key]


# The keys (the title page lists them; #R$F595 reads them).
UP_X, DOWN_X, UP_Y, DOWN_Y = "y", "h", "q", "a"
JUMP_KEY, FIGHT_KEY, PICK_KEY = "SPACE", "b", "x"
# The four ways, by the direction bit #R$F595 gives each, with what MIRROR
# (#R$F127) makes of it in bits 5 and 6 of the state (+14), in the order the
# tables show them.
WAYS = [(0x08, 0x00, "up x", UP_X), (0x40, 0x20, "up y", UP_Y),
        (0x04, 0x60, "down x", DOWN_X), (0x80, 0x40, "down y", DOWN_Y)]
WAY_WORDS = {"up x": "up x (Y-P): up and to the right on the screen",
             "up y": "up y (Q-T): up and to the left",
             "down x": "down x (H-ENTER): down and to the left",
             "down y": "down y (A-G): down and to the right"}

# The knight's frames (#R$F595): 14 of 24 by 31, 186 bytes apart from $9110.
KNIGHT_FRAMES = 0x9110
KNIGHT_FRAME = 186


def knight_pose(address: int) -> str:
    """What the knight's frame at `address` is, by its place among his 14."""
    names = ["walking 0 (facing the viewer)", "walking 1 (facing the viewer)",
             "walking 2 (facing the viewer)", "walking 0 (facing away)",
             "walking 1 (facing away)", "walking 2 (facing away)",
             "stooping (facing the viewer)", "stooping (facing away)",
             "sword out (facing the viewer)", "stepping (facing the viewer)",
             "sword out (facing away)", "stepping (facing away)",
             "fidget (facing the viewer)", "fidget (facing away)"]
    index, rest = divmod(address - KNIGHT_FRAMES, KNIGHT_FRAME)
    if rest or not 0 <= index < len(names):
        return f"${address:04X}"
    return names[index]


def _knight_label(frame: Frame) -> str:
    record = frame.record(KNIGHT_NUMBER)
    return (f"{knight_pose(record[4] | record[5] << 8)}, at {record[6]},{record[7]},"
            f"{record[8]}")


# The knight's room: 61, the chapel-like room with the plank floor, where
# the only creature (state 15) stands still unless the thing of kind 11
# lies there (#R$F309), and the floor is clear enough to walk about.
KNIGHT_ROOM = 61
# Where each walk starts: 16 passes of 2 units stay clear of the tables,
# the benches and the hole (measured).
WALK_STARTS = {"up x": (66, 78, 96), "up y": (140, 78, 66), "down x": (150, 78, 96),
               "down y": (160, 78, 160)}
WALK_PASSES = 16
ROOM_MIDDLE = (114, 78, 96)


def in_room(snapshot: Path, room: int, knight=None, settle: bool = True) -> Game:
    """Started, into `room`, the knight moved to `knight` (x, top, z) by
    ISO_MOVE before the first pass draws him, and LIFE at 99. With `settle`,
    the passes of the fidget every entry by TELE begins with are run: the
    master copy of his record (#R$639C) has 1 in his stance count, +18, so
    on the second pass he starts a fidget of 14 passes (#R$F309)."""
    game = started(snapshot)
    game.keep = (KNIGHT_NUMBER,)
    game.enter(room)
    if knight is not None:
        _place(game, KNIGHT_NUMBER, *knight)
    game.alive()
    if settle:
        game.passes(2)
        for _ in range(20):
            if not game.peek(GAME_FLAGS) & 0x08:
                break
            game.pass_()
        else:
            raise RuntimeError("the fidget at the start never ended")
    return game


def walking(snapshot: Path, way: str) -> dict:
    """The knight standing in room 61, then the key for `way` held for
    WALK_PASSES passes."""
    game = in_room(snapshot, KNIGHT_ROOM, WALK_STARTS[way])
    frames = game.passes(1)
    key = next(k for _, _, name, k in WAYS if name == way)
    game.hold([key])
    frames += game.passes(WALK_PASSES)
    game.hold()
    for frame in frames:
        frame.label = _knight_label(frame)
    return {**scene(f"walk-{way.replace(' ', '')}", frames, [KNIGHT_NUMBER]), "way": way}


def jumping(snapshot: Path, running: bool) -> dict:
    """A jump in room 61: SPACE for one pass, standing; or, running, walking
    up x with SPACE for one pass among the walking. Then until he has
    landed and stood for two passes."""
    start = (66, 78, 96) if running else ROOM_MIDDLE
    game = in_room(snapshot, KNIGHT_ROOM, start)
    frames = game.passes(1)
    if running:
        game.hold([UP_X])
        frames += game.passes(4)
        game.hold([UP_X, JUMP_KEY])
    else:
        game.hold([JUMP_KEY])
    frames += game.passes(1)
    game.hold([UP_X] if running else [])
    for _ in range(40):
        frames.append(game.pass_())
        state = frames[-1].record(KNIGHT_NUMBER)[14]
        if state & 0x0F == 8 and not state & 0x80 and len(frames) > 12:
            break
    game.hold()
    frames += game.passes(2)
    for frame in frames:
        frame.label = _knight_label(frame)
    return scene("jump-running" if running else "jump", frames, [KNIGHT_NUMBER])


def fighting(snapshot: Path) -> dict:
    """In room 61, turned to face down x (H for a pass), then B held for 12
    passes: the sword out and the step forward, twice."""
    game = in_room(snapshot, KNIGHT_ROOM, ROOM_MIDDLE)
    frames = game.passes(1)
    game.hold([DOWN_X])
    frames += game.passes(1)
    game.hold([FIGHT_KEY])
    frames += game.passes(12)
    game.hold()
    frames += game.passes(2)
    for frame in frames:
        frame.label = _knight_label(frame) + (", sword out" if frame.variable(GAME_FLAGS) & 2
                                             else "")
    return scene("fight", frames, [KNIGHT_NUMBER])


# The thing picked up in room 61: the object table's number 88, lying on
# the floor at 110, 58, 130 (read from its record).
STOOP_THING = 88
STOOP_START = (100, 78, 130)
PANEL_BOX = (0, 112, 80, 192)


def _numbered(game: Game, number: int) -> int:
    """The record number of the table's thing `number` in the room (+19)."""
    for n in game.records_in_use():
        if game.record(n)[19] == number:
            return n
    raise RuntimeError(f"no thing numbered {number} in room {game.peek(ROOM)}")


def stooping(snapshot: Path) -> dict:
    """In room 61, a step up x to face the thing numbered 88 on the floor
    ahead, then X for a pass: he stoops (#R$F4F4), the thing goes from the
    floor into the panel's box (#R$EC4C)."""
    game = in_room(snapshot, KNIGHT_ROOM, STOOP_START)
    thing = _numbered(game, STOOP_THING)
    frames = game.passes(1)
    game.hold([UP_X])
    frames += game.passes(1)
    game.hold()
    frames += game.passes(2)
    game.hold([PICK_KEY])
    frames += game.passes(1)
    game.hold()
    frames += game.passes(6)
    for frame in frames:
        carried = [frame.variable(CARRIED + 2 * i) | frame.variable(CARRIED + 2 * i + 1) << 8
                   for i in range(5)]
        frame.label = _knight_label(frame) + (", carrying it" if game.record_address(thing)
                                              in carried else "")
    anim = scene("stoop", frames, [KNIGHT_NUMBER, thing], extra=PANEL_BOX)
    anim["thing"] = thing
    return anim


def standing(snapshot: Path) -> dict:
    """Standing still in room 61 until he fidgets (#R$F309: after 128 to
    255 passes, for 14), cut to the fidget with four passes either side."""
    game = in_room(snapshot, KNIGHT_ROOM, ROOM_MIDDLE)
    stance = game.peek(KNIGHT + 18)
    frames = game.passes(1)
    fidget = None
    for _ in range(400):
        frames.append(game.pass_())
        if frames[-1].variable(GAME_FLAGS) & 0x08:
            fidget = len(frames) - 1
            break
    if fidget is None:
        raise RuntimeError("he never fidgeted")
    for _ in range(30):
        frames.append(game.pass_())
        if not frames[-1].variable(GAME_FLAGS) & 0x08:
            break
    frames += game.passes(3)
    for frame in frames:
        frame.label = _knight_label(frame)
    anim = scene("standing", frames[fidget - 4:], [KNIGHT_NUMBER])
    anim["still"] = fidget          # the passes he stood before it
    anim["stance"] = stance         # his stance count as they began
    anim["fidget"] = sum(1 for f in frames[fidget:] if f.variable(GAME_FLAGS) & 0x08)
    anim["all"] = frames
    return anim


def falling(snapshot: Path) -> dict:
    """Room 68: the knight put by its hole (a door whose way is down,
    #R$F7C4) and Q held: he walks onto it, goes through into room 67 at the
    door's top of 140 (#R$F8EC), and falls to the landing below. The whole
    screen; the passes in which a room is drawn are read a television frame
    at a time."""
    game = in_room(snapshot, 68, (111, 78, 140))
    frames = game.passes(1)
    game.hold([UP_Y])
    frames += _through(game, 68)
    game.hold()
    for _ in range(40):
        frames.append(game.pass_())
        if frames[-1].record(KNIGHT_NUMBER)[14] & 0x80 == 0 and len(frames) > 12 and \
                frames[-2].record(KNIGHT_NUMBER)[14] & 0x80:
            break
    frames += game.passes(4)
    for frame in frames:
        if not frame.label:
            frame.label = (f"room {frame.variable(ROOM)}, "
                           + _knight_label(frame)
                           + (", in the air" if frame.record(KNIGHT_NUMBER)[14] & 0x80 else ""))
    return scene("fall", frames, box=WHOLE_SCREEN)


def _through(game: Game, room: int, limit: int = 40) -> list[Frame]:
    """Passes until one leaves `room`; that one read a television frame at a
    time, to the first pass of the room it goes to; then that pass, after
    which the new room is coloured (#R$FE47)."""
    frames = []
    for _ in range(limit):
        game.to_pass()
        start = game.now
        snapshot_room = game.peek(ROOM)
        # One pass, but stopped every television frame.
        samples = []
        while True:
            frame = game.sample(TV_FRAME, START_PASS)
            samples.append(frame)
            if frame.stopped:
                break
        if game.peek(ROOM) == snapshot_room:
            whole = game.frame(start)
            frames.append(whole)
            continue
        for sample in samples:
            sample.label = "the next room being drawn"
            sample.kind = "television frame"
        frames += samples
        after = game.pass_()
        after.label = "its first pass, the objects drawn"
        frames.append(after)
        return frames
    raise RuntimeError(f"he never left room {room}")


def long_fall(snapshot: Path) -> dict:
    """A fall that costs LIFE: the knight put 80 units above the floor of
    room 61 (his top at 158) and left to fall, two units a pass, until he
    has landed; each pass over 20 costs a point (#R$F309). The whole screen,
    for LIFE at the bottom. The only other staging: his stance count."""
    game = in_room(snapshot, KNIGHT_ROOM, (114, 158, 96), settle=False)
    # His stance count up, so that the fidget every entry by TELE begins
    # with (in_room()) does not start on his first pass and stay on him all
    # the way down: in the air his update is not run (#R$F1E0).
    game.poke(KNIGHT + 18, 100)
    frames = []
    for _ in range(80):
        frames.append(game.pass_())
        if len(frames) > 3 and not frames[-1].record(KNIGHT_NUMBER)[14] & 0x80 and \
                frames[-1].life() < 99:
            break
    frames += game.passes(4)
    for frame in frames:
        frame.label = (_knight_label(frame) + f", LIFE {frame.life():02d}"
                       + (f", falling {frame.variable(FALL_COUNT)}"
                          if frame.variable(FALL_COUNT) else ""))
    return scene("fall-damage", frames, box=WHOLE_SCREEN)


# --------------------------------------------------------------------------
# The creatures.
# --------------------------------------------------------------------------

def find_state(game: Game, state: int, nth: int = 0) -> int:
    """The number of the room's `nth` record with a sprite in state `state`
    (the low nibble of +14)."""
    found = [n for n in game.records_in_use()[1:]
             if game.record(n)[14] & 0x0F == state and (game.record(n)[4] or game.record(n)[5])]
    if len(found) <= nth:
        raise RuntimeError(f"no creature in state {state} in room {game.peek(ROOM)}")
    return found[nth]


def collisions(game: Game, number: int, x: int, top: int, z: int) -> list[int]:
    """The records whose boxes a box of record `number`'s sizes at x, top, z
    would meet, as #R$FCDC tests them: x from +6 for +9, the height from +7
    less +10 up to +7, z from +8 for +11, each test strict. The floor
    (record 1) is left out: standing on it is not meeting it."""
    own = game.record(number)
    out = []
    for n in range(2, game.peek(OBJECT_COUNT) + 1):
        other = game.record(n)
        if n == number or other[16] & 0x20:
            continue
        if (x < other[6] + other[9] and other[6] < x + own[9]
                and top - own[10] < other[7] and other[7] - other[10] < top
                and z < other[8] + other[11] and other[8] < z + own[11]):
            out.append(n)
    return out


def _place(game: Game, number: int, x: int, top: int, z: int) -> None:
    """Record `number` moved to x, top, z by ISO_MOVE, before the first pass
    draws it; somewhere it meets nothing, or the run stops."""
    hits = collisions(game, number, x, top, z)
    if hits:
        raise RuntimeError(f"record {number} at {x},{top},{z} in room {game.peek(ROOM)} "
                           f"would meet records {hits}")
    game.move(game.record_address(number), x, top, z)


def creature_run(snapshot: Path, room: int, state: int, centre, offset, passes: int,
                 nth: int = 0) -> dict:
    """One run for a creature: into `room`; the creature in `state` moved
    to `centre` (x, z; its own height) and the knight put `offset` (x, z)
    from it, standing; then `passes` passes, LIFE put back to 99 before each
    (what the creature takes from him is not the point), the creature's
    record and sprite kept each pass."""
    game = in_room(snapshot, room, settle=False)
    number = find_state(game, state, nth)
    game.keep = (KNIGHT_NUMBER, number)
    record = game.record(number)
    if centre is not None:
        _place(game, number, centre[0], record[7], centre[1])
        record = game.record(number)
    if offset is not None:
        _place(game, KNIGHT_NUMBER, record[6] + offset[0], 78, record[8] + offset[1])
    frames = game.passes(passes, each=lambda g: g.alive())
    return {"passes": frames, "number": number, "room": room}


# The four places the knight is put, from the creature, so that it walks
# each way to him (#R$FC66 chooses the floor axis he is further along).
FOUR_PLACES = [(1, 0), (0, 1), (-1, 0), (0, -1)]

# The guards' frames by the way they walk (GUARD_FRAMES in #R$F309): three
# of 24 by 26, 156 bytes apart, from each.
GUARD_SETS = {0xA110: "up x", 0xA728: "up y", 0xA554: "down x", 0x9F3C: "down y"}
GUARD_FRAME = 156


def guard_way(record) -> str | None:
    address = record[4] | record[5] << 8
    for base, way in GUARD_SETS.items():
        if base <= address < base + 3 * GUARD_FRAME:
            return way
    return None


def mirror_way(record) -> str:
    """The way MIRROR (#R$F127) last turned it: bits 5 and 6 of +14."""
    return next(name for _, bits, name, _ in WAYS if bits == record[14] & 0x60)


def moving(record) -> bool:
    return bool(record[13] & 0xCC)


# Each family: its rows (a name, the room, the state, where the creature is
# put, how far the knight is put from it, the passes), how its way is read,
# and the round of frames it goes through.
FAMILIES = {
    "guards": {"rooms": [("a guard", 31, 10, (114, 110), 24, 24)],
               "way": guard_way, "cycle": 4, "turned": False},
    "troll": {"rooms": [("the troll", 5, 7, (110, 140), 40, 24)],
              "way": mirror_way, "cycle": 4, "turned": True},
    "wraith": {"rooms": [("a wraith", 56, 11, (100, 130), 32, 20)],
               "way": mirror_way, "cycle": 1, "turned": True},
}


def family(snapshot: Path, key: str) -> dict:
    """A family of creatures alone, by the way they face: for each row the
    staging run four times, the knight put on each side of the creature in
    turn; for each way, the longest stretch of passes in which it faced that
    way (its frames, for a guard; the way MIRROR turned it, for the troll
    and the wraith), drawn alone pass by pass, cut to whole rounds of its
    frames. A creature that has reached the knight goes on facing him and
    stepping through its frames as it pushes against him, moving on one
    pass in two; those passes are in the stretch too."""
    spec = FAMILIES[key]
    rig = run(snapshot, Rig, )
    rows = []
    for name, room, state, centre, distance, passes in spec["rooms"]:
        made = [run(snapshot, creature_run, room, state, centre,
                    (dx * distance, dz * distance), passes) for dx, dz in FOUR_PLACES]
        # Not the first pass, in which a creature is only drawn (#R$F1E0)
        # and +13 is still its template's.
        runs = [m["passes"][1:] for m in made]
        numbers = [m["number"] for m in made]

        look = spec["way"]

        best = _longest(runs, numbers, look)
        cells = []
        for _, _, way, _ in WAYS:
            found = best.get(way)
            if found is None:
                cells.append("not seen in these runs")
                continue
            _, index, number, first, end = found
            frames = alone_frames(rig, runs[index], number, first, end, spec["cycle"])
            count = end - first
            if count >= spec["cycle"]:
                count -= count % spec["cycle"]
            used = runs[index][first:first + count]
            cells.append({"name": f"{key}-{way.replace(' ', '')}", "frames": frames,
                          "passes": used, "number": number, "way": way,
                          "times": shown_for(runs[index])[first:first + count]})
        drawn = [p for cell in cells if isinstance(cell, dict) for p, *_ in cell["frames"]]
        rows.append({"name": name, "room": room, "state": state, "cells": cells,
                     "size": _canvas(drawn), "runs": runs, "numbers": numbers})
    return {"key": key, "rows": rows}


def alone_one(snapshot: Path, key: str, made: dict, first: int, end: int, cycle: int = 1,
              label=None) -> dict:
    """One creature alone, over passes first to end - 1 of a run."""
    rig = run(snapshot, Rig)
    passes, number = made["passes"], made["number"]
    frames = alone_frames(rig, passes, number, first, end, cycle, label)
    count = end - first
    if count >= cycle:
        count -= count % cycle
    return {"key": key, "frames": frames, "size": _canvas([p for p, *_ in frames]),
            "passes": passes[first:first + count], "number": number, "run": made,
            "times": shown_for(passes)[first:first + count]}


def _steady(passes: list[Frame], number: int, start: int = 1) -> tuple[int, int]:
    """The first stretch from `start` in which the creature keeps moving."""
    first = start
    while first < len(passes) and not moving(passes[first].record(number)):
        first += 1
    end = first
    while end < len(passes) and moving(passes[end].record(number)):
        end += 1
    return first, end


def ghost(snapshot: Path) -> dict:
    """The ghost of room 3 (state 13) left to wander for 40 passes from
    where the room puts it, the knight standing where a new game starts him."""
    made = run(snapshot, creature_run, 3, 13, None, None, 40)
    first, end = _steady(made["passes"], made["number"])
    return alone_one(snapshot, "ghost", made, first, end, 4)


def hunched(snapshot: Path) -> dict:
    """The small hunched figure of room 25 (state 12), which hangs where it is, for
    17 passes."""
    made = run(snapshot, creature_run, 25, 12, None, None, 17)
    return alone_one(snapshot, "hunched", made, 1, 17, 4)


def cloud(snapshot: Path) -> dict:
    """One of the four things of room 47 in state 14, which hang where they
    are, for 17 passes."""
    made = run(snapshot, creature_run, 47, 14, None, None, 17)
    return alone_one(snapshot, "cloud", made, 1, 17, 4)


# The state-4 creature struck at: the one of room 45's five that the object
# table puts at 140, 74, 90; the knight put 10 short of it along x, inside
# the box it strikes into (its own, moved 12 towards lower x, #R$F1E0).
STRIKE_ROOM = 45
STRIKE_IDLE = 6
STRIKE_PASSES = 12


def strike_run(snapshot: Path) -> dict:
    """Room 45: the knight put well away from the creature for STRIKE_IDLE
    passes, then 10 short of it along x (his record's x and z written: his
    place on the screen is worked out afresh from them every pass,
    #R$F65C), for STRIKE_PASSES passes. LIFE is put back to 99 before each
    pass and read after it."""
    game = in_room(snapshot, STRIKE_ROOM, settle=False)
    table = [a for a in game.table_entries(STRIKE_ROOM) if game.peek(a + 1) == 48]
    number = None
    for n in game.records_in_use():
        record = game.record(n)
        if record[14] & 0x0F == 4 and (record[6], record[8]) == (140, 90):
            number = n
    if number is None or not table:
        raise RuntimeError("the creature at 140, 74, 90 is not in room 45")
    game.keep = (KNIGHT_NUMBER, number)
    frames = game.passes(STRIKE_IDLE, each=lambda g: g.alive())
    record = game.record(number)
    game.poke(KNIGHT + 6, record[6] - 10)
    game.poke(KNIGHT + 8, record[8])
    frames += game.passes(STRIKE_PASSES, each=lambda g: g.alive())
    return {"passes": frames, "number": number, "room": STRIKE_ROOM}


def strike(snapshot: Path) -> dict:
    made = run(snapshot, strike_run)
    return alone_one(snapshot, "strike", made, 1, len(made["passes"]))


def rising_run(snapshot: Path) -> dict:
    """Room 72, as the table has it: its state-9 guard rises and comes for
    the knight, standing where a new game starts him, 70 passes."""
    return run(snapshot, creature_run, 72, 9, None, None, 70)


def rising(snapshot: Path) -> dict:
    made = rising_run(snapshot)
    passes, number = made["passes"], made["number"]
    risen = next(n for n, f in enumerate(passes) if f.record(number)[17] & 0x40)
    return alone_one(snapshot, "rising", made, 1, min(len(passes), risen + 8))


# The book: the object table's thing 7 (kind 11), which lies in room 14 and
# wakes the figure of room 61 (#R$F309).
BOOK = 7


def waking_run(snapshot: Path) -> dict:
    """Room 61 with the book in it: before the room is entered the book's
    object-table record is given room 61 and a place on its floor (60, 54,
    100), so that the room places it; the knight stands in the middle; 30
    passes."""
    game = started(snapshot)
    address = OBJECTS + 6 * (BOOK - 1)
    game.poke(address, KNIGHT_ROOM)
    game.poke(address + 3, [60, 54, 100])
    game.keep = (KNIGHT_NUMBER,)
    game.enter(KNIGHT_ROOM)
    game.move(KNIGHT, *ROOM_MIDDLE)
    number = find_state(game, 15)
    game.keep = (KNIGHT_NUMBER, number)
    frames = game.passes(30, each=lambda g: g.alive())
    return {"passes": frames, "number": number, "room": KNIGHT_ROOM}


def waking(snapshot: Path) -> dict:
    made = run(snapshot, waking_run)
    return alone_one(snapshot, "waking", made, 0, 24)


# --------------------------------------------------------------------------
# Whole-screen scenes: the game between passes too.
# --------------------------------------------------------------------------

# A pass that has not come back to START_PASS within this many television
# frames is not an ordinary one -- a room is being drawn, or the game has
# left the main loop -- and is kept a television frame at a time.
ORDINARY_PASS = 12
PAUS_END = TITLE_WAIT + 7         # PAUS is the seven bytes from $F0D8 (#R$F0D2)
INPUT, INPUT_END = 0xF0DF, 0xF0E6  # which it calls, to come back to $F0DC


def waiting(game: Game) -> bool:
    """Whether the game is in PAUS, waiting for a key (#R$F0D2): in its
    loop, or in INPUT called from it."""
    from skoolkit.simutils import SP

    if TITLE_WAIT <= game.pc < PAUS_END:
        return True
    sp = game.sim.registers[SP]
    return INPUT <= game.pc < INPUT_END and _word(game.memory, sp) == TITLE_WAIT + 4


def watch(game: Game, done, limit: int = 400, tail: int = 25, label=None,
          each=None) -> list[Frame]:
    """The game run a television frame at a time. An ordinary pass is kept
    as one frame, the screen at its end; a pass that takes longer than
    ORDINARY_PASS television frames (a room drawn, the game gone from the
    main loop) is kept frame by frame. Stops `tail` television frames after
    the game starts waiting for a key (PAUS), or when done(frames) says so
    at the end of a pass. each(game), if given, is called after every
    television frame: to let go of a key, say, before the game waits for
    them all to be let go (#R$F0D2)."""
    frames: list[Frame] = []
    samples: list[Frame] = []
    for _ in range(limit * ORDINARY_PASS):
        sample = game.sample(TV_FRAME, START_PASS)
        samples.append(sample)
        if each is not None:
            each(game)
        if sample.stopped:
            if len(samples) <= ORDINARY_PASS:
                sample.start = samples[0].start
                sample.tstates = sample.end - sample.start
                sample.kind = "pass"
                frames.append(sample)
            else:
                for kept in samples:
                    kept.kind = "television frame"
                frames += samples
            samples = []
            if done(frames):
                break
        elif waiting(game):
            for kept in samples:
                kept.kind = "television frame"
            frames += samples
            for _ in range(tail):
                frame = game.sample(TV_FRAME)
                frame.kind = "television frame, waiting for a key"
                frames.append(frame)
            break
    else:
        raise RuntimeError("the scene never ended")
    if label is not None:
        for frame in frames:
            frame.label = label(frame)
    return frames


def _where(frame: Frame) -> str:
    return f"room {frame.variable(ROOM)}, LIFE {frame.life():02d} ({frame.kind})"


# Room 44, whose only live thing is the knight, with a door in its far wall
# along y (a door object of type 72, #R$F7C4), to room 43.
DOOR_ROOM, DOOR_TO = 44, 43
DOOR_START = (92, 78, 156)


def door(snapshot: Path) -> dict:
    """Room 44: the knight put a few steps short of the door in its far
    wall and Q held: he walks up y into it, through to room 43, which is
    drawn and appears, and he walks on."""
    game = in_room(snapshot, DOOR_ROOM, DOOR_START)
    game.hold([UP_Y])
    frames = watch(game, lambda f: f[-1].variable(ROOM) == DOOR_TO and sum(
        1 for x in f if x.variable(ROOM) == DOOR_TO and x.kind == "pass") >= 6, label=_where)
    game.hold()
    return scene("door", frames, box=WHOLE_SCREEN)


def title(snapshot: Path) -> dict:
    """From the snapshot at $C47C: half a second of the loading tune over the
    loading screen, SPACE for a fifth of a second to end it, the title (room
    79 drawn, coloured, and its words printed, #R$F065) until the game waits
    for a key; then SPACE again, and the first room of a game, 29, drawn and
    coloured, and its first passes."""
    game = Game(snapshot)
    game.keep = (KNIGHT_NUMBER,)
    game.machine.run(0.5)
    first = game.sample(TV_FRAME)
    first.kind = "the loading tune"
    frames = [first]
    game.hold(["SPACE"])
    for _ in range(10):
        sample = game.sample(TV_FRAME)
        sample.kind = "SPACE held"
        frames.append(sample)
    game.hold()
    frames += watch(game, lambda f: False, tail=40)
    game.hold(["SPACE"])
    for _ in range(10):
        sample = game.sample(TV_FRAME)
        sample.kind = "SPACE held"
        frames.append(sample)
    game.hold()
    frames += watch(game, lambda f: sum(1 for x in f if getattr(x, "kind", "") == "pass") >= 3)
    for frame in frames:
        frame.label = frame.kind
    return scene("title", frames, box=WHOLE_SCREEN)


# The pit of room 9: the knight put on the bridge (its slabs have their top
# at 70, #R$BC18's floor is at 10 with a slab of kind 7 over it).
PIT_ROOM = 9
BRIDGE = (80, 98, 104)


def game_over(snapshot: Path) -> dict:
    """Room 9: the knight put on the bridge over the pit, and A held: he
    walks off its near edge, falls, and meets the slab of kind 7 at the
    bottom, which takes all his LIFE (#R$F959); the main loop returns from
    #R$FD20, and #R$F065 draws room 1 behind GAME OVER and waits for a key.
    LIFE is not topped up here."""
    game = in_room(snapshot, PIT_ROOM, BRIDGE)
    game.hold([DOWN_Y])

    def let_go(game):
        # Off the bridge and falling: A let go, as a player would, or GAME
        # OVER would wait for it (#R$F0D2).
        if game.peek(KNIGHT + 14) & 0x80:
            game.hold()

    frames = watch(game, lambda f: False, limit=200, tail=75, label=_where, each=let_go)
    return scene("game-over", frames, box=WHOLE_SCREEN)


# The door into room 81, where the quest ends: room 31's, which needs thing
# 8 in the place in use (+14 of its record, #R$F7C4). Thing 8 lies in room
# 61; thing 5, which the end asks after (#R$FD20), in room 33.
END_DOOR_ROOM = 31
END_KEY = 8
QUEST_THING = 5
END_START = (150, 78, 84)


def _take(game: Game, room: int, number: int, place: int) -> None:
    """Into `room`, place `place` chosen (its key held for a pass), and the
    thing numbered `number` picked up the way the build's sessions pick one
    (build_fairlight._pick_numbered: the thing put where he stands, X)."""
    game.enter(room)
    game.passes(2)
    game.hold([str(place)])
    game.pass_()
    game.hold()
    game.pass_()
    game.play(bf._pick_numbered(number))
    game.to_pass()


def ending(snapshot: Path, done: bool) -> dict:
    """The end of the quest: thing 8, the key to room 31's door, picked up in
    room 61 into place 2 -- and, for `done`, thing 5 picked up in room 33
    into place 1 first -- then room 31, the knight put before the door with
    place 2 in use, and Y held: he goes through into room 81 (#R$FD20), whose
    picture is drawn and coloured, the verdict printed, and the two lines of
    #R$DFF2, and the game waits for a key."""
    game = started(snapshot)
    game.keep = (KNIGHT_NUMBER,)
    if done:
        _take(game, 33, QUEST_THING, 1)
    _take(game, KNIGHT_ROOM, END_KEY, 2)
    game.enter(END_DOOR_ROOM)
    game.move(KNIGHT, *END_START)
    game.alive()
    game.passes(2)
    game.hold(["2"])
    game.pass_()
    game.hold([UP_X])

    def let_go(game):
        # Through the door: Y let go, or the end would wait for it (#R$F0D2).
        if game.peek(ROOM) != END_DOOR_ROOM:
            game.hold()

    frames = watch(game, lambda f: False, limit=100, tail=75, label=_where, each=let_go)
    return scene("ending-done" if done else "ending-failed", frames, box=WHOLE_SCREEN)


# --------------------------------------------------------------------------
# A room being drawn, command by command.
# --------------------------------------------------------------------------

DRAWN_ROOM = 29


def _commands(memory) -> dict:
    """Every command of every room and part, by its address: what it is
    (fairlight_data.room_commands, the listing's own reading)."""
    out = {}
    for base, count, skip in ((fd.ROOMS, fd.ROOM_COUNT, 3), (fd.PARTS, fd.PART_COUNT, 2)):
        address = base
        for _ in range(count):
            length = _word(memory, address)
            for at, _, what in fd.room_commands(memory, address + skip, address + length):
                out[at] = re.sub(r" \(#R\$[0-9A-F]{4}\)", "", what)
            address += length
    return out


def drawing(snapshot: Path, room: int = DRAWN_ROOM) -> dict:
    """Room 29 drawn from nothing: from a game in room 29, ROOM set to it
    again and TELE entered, as a new game enters it; then the screen read
    at every command the interpreter fetches (#R$E5A6) and at least once a
    television frame, until the room's last command; then the still things
    and the doors drawn in (#R$FE15), and the first pass, after which the
    room is coloured (#R$FE47). The game draws a room black on black; up to
    the colouring, the pixels are shown here in the colours the room gets.
    The screen is kept once a television frame, each labelled with the
    commands the interpreter fetched in it."""
    from skoolkit.simutils import IXh, IXl

    game = started(snapshot)
    memory = game.memory
    commands = _commands(memory)
    record = fd.room_address(memory, room)
    last = record + _word(memory, record) - 1
    colour = memory[record + 2]
    game.poke(ROOM, room)
    game.alive()
    game.play([bf.Jump(f"room {room}", ENTER_GAME_ROOM, GAME_STACK)])
    game.run_to(DRAW_ROOM)
    frames = []
    done: list[str] = []
    current = "the screen cleared"
    count = 0
    start = game.now
    while True:
        # Stop at every command fetched, but keep a frame only once a
        # television frame has gone by: its label is the commands it took in.
        sample = game.sample(start + TV_FRAME - game.now, ROOM_COMMAND)
        at = None
        if sample.stopped:
            at = game.sim.registers[IXh] << 8 | game.sim.registers[IXl]
        if not sample.stopped or at == last:
            frame = game.frame(start)
            frame.colour = colour
            frame.kind = "drawing"
            frame.label = ", ".join(done) if done else f"{current}, going on"
            frames.append(frame)
            done = []
            start = game.now
            if at == last:
                break
        if at is not None:
            if game.peek(at) != 0xE5:
                count += 1
            current = commands.get(at, f"${game.peek(at):02X}")
            done.append(current)
    # The command count: fetches of a command other than $E5, which ends a
    # room or a part.
    rest = watch(game, lambda f: sum(1 for x in f if x.kind == "pass") >= 2)
    coloured = False
    for frame in rest:
        if frame.kind == "pass" and not coloured:
            frame.colour = colour
            frame.label = "the first pass: the objects drawn"
            coloured = True
        elif frame.kind == "pass":
            frame.label = "coloured, and the next pass"
        else:
            frame.colour = colour
            frame.label = "the doors and the still things drawn in"
    anim = scene("drawing", frames + rest, box=WHOLE_SCREEN)
    anim["commands"] = count
    anim["drawn"] = sum(f.tstates for f in frames)
    return anim


# --------------------------------------------------------------------------
# A moving object redrawn: the compositor at work.
# --------------------------------------------------------------------------

# The knight walks down x along the far side of the table at 80, 64, 120 in
# room 61 (it is nearer the viewer, and covers him), towards the figure at
# 92, 80, 164 (farther, behind him).
COMPOSITE_START = (116, 78, 146)
COMPOSITES = 24
SLOW_MS = 400                     # each call held this long in the GIF


class Composite:
    """One call of the compositor: the rectangle it rebuilt, from IY+$64 on
    at its entry (#R$E3E4), and whose redraw it was."""

    def __init__(self, memory):
        self.x, self.y = memory[0xFFE4], memory[0xFFE5]
        self.height, self.columns = memory[0xFFE7], memory[0xFFF3]
        self.record = memory[THIS_RECORD]
        self.behind = bool(memory[0xFFF1] & 2)

    def box(self):
        """The screen bytes it rewrites: its width in bytes and one more,
        from the byte x is in; its rows, from the top (y counts up)."""
        left = (self.x >> 3) * 8
        top = 191 - self.y
        return (left, max(0, top), min(256, left + 8 * (self.columns + 1)),
                min(192, top + self.height))


def compositing(snapshot: Path) -> dict:
    """Room 61: the knight put at 116, 78, 146 and H held, and the game
    stopped at every call of the compositor (#R$E3E4) for COMPOSITES calls:
    each frame is the screen as the call before left it, with the rectangle
    that call rebuilt outlined. The GIF is slowed: each frame is held
    SLOW_MS; the real time of each call is in its label."""
    from PIL import ImageDraw

    game = in_room(snapshot, KNIGHT_ROOM, COMPOSITE_START)
    figure = find_state(game, 15)
    game.hold([DOWN_X])
    game.passes(2)
    game.to_pass()
    game.run_to(COMPOSITE)
    calls = [Composite(game.memory)]
    frames = []
    for _ in range(COMPOSITES):
        frame = game.sample(PASS_LIMIT, COMPOSITE)
        if not frame.stopped:
            raise RuntimeError("the compositor was not called again")
        frames.append(frame)
        calls.append(Composite(game.memory))
    game.hold()
    box = None
    for call in calls[:-1]:
        box = _union(box, call.box())
    box = (max(0, box[0] - 16), max(0, box[1] - 12), min(256, box[2] + 16),
           min(192, box[3] + 12))
    pictures = []
    labels = []
    for frame, call in zip(frames, calls):
        picture = frame.screen()
        left, top, right, bottom = call.box()
        ImageDraw.Draw(picture).rectangle((left, top, right - 1, bottom - 1),
                                          outline=HIGHLIGHT)
        pictures.append(picture.crop(box))
        whose = {KNIGHT_NUMBER: "the knight", figure: "the robed figure"}.get(
            call.record, f"record {call.record}")
        labels.append(f"{whose}'s redraw, {right - left} by {bottom - top} pixels"
                      + (", with objects behind" if call.behind else ""))
    out = [(p, SLOW_MS, label, f.tstates) for p, label, f in zip(pictures, labels, frames)]
    return {"key": "compositor", "frames": out, "calls": calls[:-1], "passes": frames,
            "box": box}


# --------------------------------------------------------------------------
# What the recordings show, checked against what the code says they should.
# --------------------------------------------------------------------------

# Every comparison that failed, for build() to log: a page that says the
# recording disagrees with the code must not go by unnoticed.
DISAGREEMENTS: list[str] = []


def _fmt(value) -> str:
    if isinstance(value, bool):
        return "yes" if value else "no"
    if isinstance(value, (list, tuple)):
        return ", ".join(_fmt(v) for v in value)
    return str(value)


def _check(what: str, expected, measured) -> str:
    """'what: V, as the code says' or, if they differ, both -- and the
    difference kept for the build's log."""
    if expected == measured:
        return f"{what}: {_fmt(measured)}, as the code says"
    DISAGREEMENTS.append(f"{what}: expected {_fmt(expected)}, measured {_fmt(measured)}")
    return f"{what}: {_fmt(measured)} measured, where the code gives {_fmt(expected)}"


def _ms(tstates) -> int:
    return round(tstates / T_STATES_PER_MS)


def _span(values) -> str:
    low, high = min(values), max(values)
    return f"{low} ms" if low == high else f"{low}-{high} ms"


def _cycle(indices: list[int]) -> list[int]:
    """What a run of three frames stepped by ANIM (#R$F595) gives from where
    `indices` starts: 0, 1, 2, 1, 0 ... from the first frame, going the way
    the second says."""
    order = [0, 1, 2, 1]
    for phase in range(4):
        if order[phase] == indices[0] and (len(indices) < 2 or order[(phase + 1) % 4]
                                           == indices[1]):
            return [order[(phase + n) % 4] for n in range(len(indices))]
    return [order[n % 4] for n in range(len(indices))]


def _index(address: int, base: int, step: int, count: int = 3) -> int:
    return (address - base) // step % count


def _knight(frame: Frame):
    return frame.record(KNIGHT_NUMBER)


def _sprite(record) -> int:
    return record[4] | record[5] << 8


# The screen's move for a step of 2 each way (#R$E4F7: x by +6 less +8, y by
# half their sum): up x right 2 and up 1, and so on.
SCREEN_STEP = {"up x": (2, 1), "up y": (-2, 1), "down x": (-2, -1), "down y": (2, -1)}
AXIS_STEP = {"up x": (2, 0), "up y": (0, 2), "down x": (-2, 0), "down y": (0, -2)}


def _measure_walk(anim: dict) -> str:
    way = anim["way"]
    walking = [f for f in anim["passes"] if f.keys]
    records = [_knight(f) for f in walking]
    indices = [_index(_sprite(r), KNIGHT_FRAMES, KNIGHT_FRAME) for r in records]
    moves = sorted({(b[6] - a[6], b[8] - a[8]) for a, b in zip(records, records[1:])})
    screen = sorted({(b[0] - a[0], b[1] - a[1]) for a, b in zip(records, records[1:])})
    times = [_ms(f.tstates) for f in walking]
    parts = [_check("the walking frames, pass by pass", _cycle(indices), indices),
             _check("each step along x and y, in units", [AXIS_STEP[way]], moves),
             _check("each step on the screen, x and y in pixels", [SCREEN_STEP[way]], screen)]
    text = "; ".join(parts) + f". Passes of {_span(times[1:])}"
    if times[0] > 2 * max(times[1:]):
        text += (f"; the first, in which he turns round and #R$F117 turns all 28 of his "
                 f"planes over in memory, {times[0]} ms")
    return text + "."


def _measure_jump(anim: dict) -> str:
    passes = anim["passes"]
    tops = [_knight(f)[7] for f in passes]
    xs = [_knight(f)[6] for f in passes]
    peak = tops.index(max(tops))
    start = next(n for n in range(len(tops)) if tops[n] > tops[0]) - 1
    rise = [b - a for a, b in zip(tops[start:peak], tops[start + 1:peak + 1])]
    end = next(n for n in range(peak, len(tops)) if tops[n] == tops[0])
    fall = [b - a for a, b in zip(tops[peak:end], tops[peak + 1:end + 1])]
    parts = [_check("the rise, units a pass", [2] * 8, rise),
             _check("the fall, units a pass", [-2] * 8, fall)]
    if anim["key"] == "jump-running":
        across = [b - a for a, b in zip(xs[start:end], xs[start + 1:end + 1])]
        parts.append(_check("along x while rising, then falling",
                            ([2] * 8, [0] * 8), (across[:8], across[8:16])))
    return "; ".join(parts) + f". Passes of {_span([_ms(f.tstates) for f in passes])}."


def _runs(values) -> list[tuple]:
    out = []
    for value in values:
        if out and out[-1][0] == value:
            out[-1][1] += 1
        else:
            out.append([value, 1])
    return [tuple(r) for r in out]


def _measure_fight(anim: dict) -> str:
    fighting = [f for f in anim["passes"] if FIGHT_KEY in f.keys]
    out = [bool(f.variable(GAME_FLAGS) & 2) for f in fighting]
    runs = [n for _, n in _runs(out)]
    xs = [_knight(f)[6] for f in fighting]
    moved = sum(1 for a, b in zip(xs, xs[1:]) if a != b)
    steps = sorted({b - a for a, b in zip(xs, xs[1:]) if a != b})
    return (_check("passes with the sword out and away, in turn", [3] * len(runs), runs)
            + "; " + _check("each step forward along x, in units", [-2], steps)
            + f". He moved on {moved} of the {len(fighting) - 1} passes after the first.")


def _measure_stoop(anim: dict) -> str:
    stooped = [f for f in anim["passes"]
               if knight_pose(_sprite(_knight(f))).startswith("stooping")]
    carried = anim["passes"][-1].label.endswith("carrying it")
    return (_check("passes he is shown stooping", 1, len(stooped))
            + f"; the thing is in the place in use afterwards: {'yes' if carried else 'no'}.")


def _measure_standing(anim: dict) -> str:
    return (_check("passes standing before the fidget (one fewer than his stance count, "
                   "+18, as they began: the fidget starts in the pass that counts it to "
                   "nought)", anim["stance"] - 1, anim["still"]) + "; "
            + _check("passes of the fidget", 14, anim["fidget"]) + ".")


def _measure_fall(anim: dict) -> str:
    passes = [f for f in anim["passes"] if f.kind == "pass" and f.variable(ROOM) == 67]
    tops = [_knight(f)[7] for f in passes]
    falls = sorted({a - b for a, b in zip(tops, tops[1:]) if a != b})
    falling = sum(1 for a, b in zip(tops, tops[1:]) if a != b)
    landed = min(tops)
    return (_check("his top as he comes through, from the door's +16", 140, max(tops))
            + "; " + _check("units a pass while falling", [2], falls)
            + "; " + _check("passes falling", (140 - landed) // 2, falling)
            + "; " + _check("LIFE lost (none unless a fall passes 20)", 0,
                            anim["passes"][0].life() - passes[-1].life())
            + f". Room 67 took {_ms(sum(f.tstates for f in anim['passes'] if f.kind != 'pass'))}"
              f" ms to draw, the screen black meanwhile.")


def _measure_fall_damage(anim: dict) -> str:
    passes = anim["passes"]
    counted = max(f.variable(FALL_COUNT) for f in passes)
    fallen = _knight(passes[0])[7] - _knight(passes[-1])[7]
    lost = passes[0].life() - passes[-1].life()
    return (_check("units fallen", 80, fallen) + "; "
            + _check("passes counted falling (FALL_COUNT)", 40, counted) + "; "
            + _check("LIFE lost, a point a pass over 20", counted - 20, lost) + ".")


def _cell_indices(cell: dict, base_of) -> list[int]:
    out = []
    for frame in cell["passes"]:
        record = frame.record(cell["number"])
        base, step = base_of(_sprite(record))
        out.append(_index(_sprite(record), base, step))
    return out


def _guard_base(address: int):
    for base in GUARD_SETS:
        if base <= address < base + 3 * GUARD_FRAME:
            return base, GUARD_FRAME
    return address, GUARD_FRAME


def _troll_base(address: int):
    return (0x8BB8 if address < 0x8E64 else 0x8E64), 228


def _measure_family(anim: dict) -> str:
    key = anim["key"]
    parts = []
    for row in anim["rows"]:
        for cell in row["cells"]:
            if isinstance(cell, str):
                parts.append(f"{cell}")
                continue
            turned = all("turned" in label for _, _, label, _ in cell["frames"])
            if key == "wraith":
                expected_turned = cell["way"] in ("up y", "down x")
                sprites = sorted({f"${_sprite(f.record(cell['number'])):04X}"
                                  for f in cell["passes"]})
                want = "$5F08" if cell["way"].startswith("up") else "$5E88"
                parts.append(_check(f"{cell['way']}: the frame", [want], sprites) + "; "
                             + _check("turned round", expected_turned, turned))
                continue
            base_of = _guard_base if key == "guards" else _troll_base
            indices = _cell_indices(cell, base_of)
            text = _check(f"{cell['way']}: frames", _cycle(indices), indices)
            if key == "troll":
                text += "; " + _check("turned round", cell["way"] in ("up y", "down x"), turned)
            parts.append(text)
    times = [_ms(t) for row in anim["rows"] for cell in row["cells"] if isinstance(cell, dict)
             for t in cell["times"]]
    return "; ".join(parts) + f". Passes of {_span(times)}."


def _measure_one(anim: dict, base: int, step: int) -> str:
    indices = [_index(_sprite(f.record(anim["number"])), base, step) for f in anim["passes"]]
    return (_check("frames, pass by pass", _cycle(indices), indices)
            + f". Passes of {_span([_ms(t) for t in anim['times']])}.")


def _measure_strike(anim: dict) -> str:
    passes = anim["passes"]
    number = anim["number"]
    striking = [f for f in passes if _sprite(f.record(number)) != 0x5C84 or
                f.life() < 99]
    losses = sorted({99 - f.life() for f in striking})
    first = passes.index(striking[0]) if striking else 0
    indices = [(_sprite(f.record(number)) - 0x5C84) // 144 for f in passes[first:]]
    return (_check("LIFE taken each pass he is in reach", [3], losses) + "; "
            + _check("frames while striking", _cycle(indices), indices)
            + f". Passes of {_span([_ms(t) for t in anim['times']])}.")


def _measure_rising(anim: dict) -> str:
    made = anim["run"]
    passes, number = made["passes"], made["number"]
    start = passes[0].record(number)[17]
    counts = [n for sprite, n in _runs([_sprite(f.record(number)) for f in passes[1:]])][:4]
    expected = [0x37 - (start + 1), 3, 3, 3]
    return (_check("passes as the helmet, then in each of the three frames of the rise",
                   expected, counts)
            + f" (+17 starts at ${start:02X} and counts up a pass; #R$F1E0 changes the frame "
              f"at $37, $3A and $3D and has it risen at $40). Then it walks after the "
              f"knight in the guards' frames.")


def _measure_waking(anim: dict) -> str:
    made = anim["run"]
    passes, number = made["passes"], made["number"]
    woke = next(n for n, f in enumerate(passes) if f.record(number)[14] & 0x0F != 15)
    state = passes[woke].record(number)[14] & 0x0F
    return (_check("the pass it wakes on (the first only draws the room's objects, "
                   "#R$F1E0, and the book is noticed on the second)", 1, woke) + "; "
            + _check("its state from then on", 11, state) + ".")


def _measure_door(anim: dict, memory) -> str:
    passes = anim["passes"]
    # Where the door put him: his record while the room behind is drawn, and
    # where he was on the last pass before.
    arrived = [f for f in passes if f.variable(ROOM) == DOOR_TO and f.kind != "pass"][-1]
    record = _knight(arrived)
    before = _knight([f for f in passes if f.variable(ROOM) == DOOR_ROOM][-1])
    drawing = sum(f.tstates for f in passes if f.kind != "pass")
    door = None
    # The object table as the tape has it (the start-up copies it to #R$A924).
    for address, size, room, _ in fd.object_records(memory):
        if size == 11 and room == DOOR_ROOM and memory[address + 5] == DOOR_TO:
            door = address
    text = ""
    if door is not None:
        text = _check("where he arrives, x and z (#R$F7C4, going along y: x as far on from "
                      "the door's +15 as he was from its corner, z its +18)",
                      (memory[door + 7] + before[6] - memory[door + 2], memory[door + 10]),
                      (record[6], record[8])) + ". "
    return text + (f"The pass that took him through lasted {_ms(drawing)} ms, nearly all of "
                   f"it room {DOOR_TO} being drawn, black on black.")


def _black(frame: Frame) -> bool:
    return not any(frame.screen_bytes[6144:])


def _measure_scene(anim: dict) -> str:
    """For the whole-screen scenes that leave the main loop: how long the
    screen stays black while a picture is drawn, and how long it takes to
    appear."""
    passes = anim["passes"]
    runs = []
    for frame in passes:
        black = _black(frame)
        if runs and runs[-1][0] == black:
            runs[-1][1] += frame.tstates
        else:
            runs.append([black, frame.tstates])
    blacks = [_ms(t) for black, t in runs if black]
    return ("Black while a picture is drawn: " + ", ".join(f"{t} ms" for t in blacks) + "."
            if blacks else "")


def _measure_drawing(anim: dict) -> str:
    return (f"{anim['commands']} commands fetched by the interpreter (#R$E5A6), parts "
            f"and repeats included, in {_ms(anim['drawn'])} ms; the frames are a "
            f"television frame (20 ms) apart.")


def _measure_compositor(anim: dict) -> str:
    sizes = {}
    for call in anim["calls"]:
        left, top, right, bottom = call.box()
        sizes.setdefault(call.record, (right - left, bottom - top))
    parts = []
    for record, size in sorted(sizes.items()):
        rec = anim["passes"][0].record(record)
        expected = (8 * (rec[2] // 8 + 1), rec[3] + 6)
        whose = "the knight" if record == KNIGHT_NUMBER else "the robed figure"
        parts.append(_check(f"{whose}'s rectangle, width and height in pixels "
                            f"(a byte more than its sprite, three rows more above and below)",
                            expected, size))
    times = [_ms(f.tstates) for f in anim["passes"]]
    return "; ".join(parts) + f". A call and what follows it to the next: {_span(times)}."


def measure(key: str, anim: dict, memory) -> str:
    if key.startswith("walk-"):
        return _measure_walk(anim)
    if key.startswith("jump"):
        return _measure_jump(anim)
    simple = {"fight": _measure_fight, "stoop": _measure_stoop, "standing": _measure_standing,
              "fall": _measure_fall, "fall-damage": _measure_fall_damage,
              "guards": _measure_family, "troll": _measure_family, "wraith": _measure_family,
              "strike": _measure_strike, "rising": _measure_rising, "waking": _measure_waking,
              "drawing": _measure_drawing, "compositor": _measure_compositor}
    if key in simple:
        return simple[key](anim)
    if key == "ghost":
        return _measure_one(anim, 0x5B30, 0x5C)
    if key == "hunched":
        return _measure_one(anim, 0x5B00, 0x10)
    if key == "cloud":
        return _measure_one(anim, 0x6104, 0x28)
    if key == "door":
        return _measure_door(anim, memory)
    return _measure_scene(anim)


# --------------------------------------------------------------------------
# The page.
# --------------------------------------------------------------------------

def _walk_text(way: str) -> str:
    facing = "away from the viewer" if way.startswith("up") else "towards the viewer"
    turned = ("turned round from the tape's by" if way in ("up y", "down x")
              else "as the tape has them, not turned by")
    return ("He walks " + WAY_WORDS[way] + ", facing " + facing + ": #R$F595 shows his walk "
            "from #R$9110 (towards the viewer) or #R$933E (away), three frames 186 bytes "
            "apart, stepped by the author's ANIM -- forward to the last and back, so 0, 1, 2, "
            "1 and round again, a frame a pass -- and his frames are " + turned + " #R$F117, "
            "which mirrors all fourteen of his frames in memory when he turns between a way "
            "that is drawn as stored and one that is its mirror image. Each pass he steps two "
            "units, and #R$E4F7 moves him on the screen by the projection of the step. In "
            "room 61, the knight put at a clear stretch of its floor, standing a pass and "
            "then walking for 16.")


WALK_SPRITES = ["$9110", "$91CA", "$9284", "$933E", "$93F8", "$94B2"]
TEXT = {
    "walk-upx": ("Walking up x", WALK_SPRITES, _walk_text("up x")),
    "walk-upy": ("Walking up y", WALK_SPRITES, _walk_text("up y")),
    "walk-downx": ("Walking down x", WALK_SPRITES, _walk_text("down x")),
    "walk-downy": ("Walking down y", WALK_SPRITES, _walk_text("down y")),
    "standing": ("Standing, and the fidget", ["$99C8", "$9A82"],
                 "Standing, he shows the middle frame of his walk (#R$91CA, or #R$93F8 "
                 "facing away). His record's +18 counts his stance down a pass at a time "
                 "(#R$F309); at nought a fidget begins, 14 passes of #R$99C8 or #R$9A82 "
                 "(bit 3 of GAME_FLAGS), and after it a random count of 128 to 255 passes "
                 "starts again. The master copy of his record (#R$639C) has 1 there, so every "
                 "game begins, and every entry by the thing that carries him off, with a "
                 "fidget on the second pass. Here the knight stood in room 61 after that "
                 "first fidget, until the next came; the GIF is the fidget with four passes "
                 "either side."),
    "jump": ("Jumping", [], "SPACE or SYMBOL SHIFT (#R$F595): his state becomes 5 with +15 at "
             "8, and for eight passes #R$F1E0 moves him up two units a pass without the fall, "
             "stepping through his walk as it goes (INP5, which is why his legs move in the "
             "air); then his state is 8 again and gravity brings him down, two units a pass, "
             "straight down, in whatever frame he was in. Here, standing in the middle of "
             "room 61, SPACE was held for one pass."),
    "jump-running": ("A running jump", [], "The same jump taken walking: Y held, and "
                     "SPACE with it for one pass. He rises the way he was walking, and "
                     "comes down straight: a fall keeps only the down bit of the way "
                     "(#R$F65C)."),
    "fight": ("Fighting", ["$96E0", "$979A", "$9854", "$990E"],
              "B, N or M (#R$F595, the author's INP59): the sword comes out for three "
              "passes, standing (bit 1 of GAME_FLAGS, #R$96E0 facing the viewer or #R$9854 "
              "away), and goes away for three while he steps forward (#R$979A or #R$990E), "
              "for as long as the key is held. The sword out is what lets him hurt a creature "
              "he meets (#R$F959). In room 61, turned to face down x with H for a pass, "
              "then B held for 12 passes."),
    "stoop": ("Stooping to pick something up", ["$956C", "$9626"],
              "X, C or V (#R$F4F4): he stoops (#R$956C, or #R$9626 facing away) and the "
              "game looks for a thing that can be carried in a box his size four units "
              "ahead; the thing found is wiped from the room by redrawing the rectangle it "
              "stood in without it (#R$ECBD, with THIS_RECORD pointing at it), and drawn "
              "in the panel's box for the place in use (#R$EC4C). In room 61, a step "
              "up x to face the stool the object table numbers 88, then X for a pass."),
    "fall": ("Falling through a hole", [],
             "Room 68's hole is a door whose way is down (#R$F7C4): Q held, he walks onto "
             "it, the fall that every step carries meets it, and he goes through to room 67 "
             "at the height the door gives, 140 (#R$F8EC). While room 67 is drawn the "
             "screen is black; then he falls, two units a pass, to the landing of the "
             "stairs. A fall of 20 passes or fewer costs nothing. The whole screen; the "
             "pass that went through the door is shown a television frame at a time."),
    "fall-damage": ("A fall that costs LIFE", [],
                    "The knight put 80 units above the floor of room 61 (his top at 158) "
                    "and left to fall. FALL_COUNT (IY+$14) counts the passes he falls; when "
                    "he lands, #R$F309 takes a point of LIFE for each over 20. His stance "
                    "count was raised first, so that the fidget every entry by TELE begins "
                    "with does not start on his first pass and stay on him all the way down: "
                    "in the air his own update does not run (#R$F1E0), and he keeps the "
                    "frame he had. The whole screen, for LIFE at the bottom."),
    "guards": ("The guards", [],
               "A guard has a set of three frames of 24 by 26 for each way it walks, 156 "
               "bytes apart (GUARD_FRAMES in #R$F309): #R$A110 up x, #R$A728 up y, #R$A554 "
               "down x and #R$9F3C down y (and standing), stepped by ANIM a frame a pass. "
               "Nothing is turned round. The guards of states 6 and 10 patrol along x or "
               "along y and chase the knight when he is within 30; those of state 9 rise "
               "first (below) and then always chase; all use these frames. Staged in room "
               "31 with its state-10 guard moved to 114, 110 and the knight put 24 away on "
               "each side in turn, so that it came for him each way."),
    "troll": ("The troll", [],
              "Three frames of 24 by 38, 228 bytes apart: #R$8BB8 towards the viewer and "
              "#R$8E64 away. MITRO (#R$F127) turns all six round in memory when it turns "
              "between a way drawn as stored and one that is its mirror image (up y and down "
              "x). There is only ever one troll in a room, which is what makes turning shared "
              "sprites safe; #R$F906 turns them back as the knight leaves. Staged in room 5, "
              "the troll moved to 110, 140 and the knight put 40 away on each side in turn."),
    "wraith": ("The wraith", [],
               "One frame each view, 16 by 32: #R$5E88 towards the viewer and #R$5F08 away, "
               "turned round by MIWRAI (#R$F11F) as the troll's are. It glides without "
               "stepping. Staged in room 56, the wraith moved to 100, 130 and the knight put "
               "32 away on each side in turn."),
    "ghost": ("The ghost", ["$5B30", "$5B8C", "$5BE8"],
              "State 13 (#R$F309): three frames of 16 by 23 from #R$5B30, stepped by ANIM; "
              "it wanders diagonally, turning back off whatever it meets, and faces no way "
              "in particular. Room 3's, left to itself for 40 passes."),
    "hunched": ("The small hunched figure", ["$5B00", "$5B10", "$5B20"],
                "State 12: three frames of 8 by 8 from #R$5B00. It hangs where it is, "
                "without even falling, and steps through its frames. Room 25's, for 16 "
                "passes."),
    "cloud": ("The small cloud", ["$6104", "$612C", "$6154"],
              "State 14: three frames of 16 by 10 from #R$6104, hanging still. One of room "
              "47's four, for 16 passes."),
    "strike": ("The flower with a face, striking", ["$5C84", "$5D14", "$5DA4"],
               "State 4 (#R$F1E0, the author's I4): it stays where it is and shows #R$5C84 "
               "until the knight is inside its own box moved 12 units down x; then each pass "
               "it takes three from LIFE and steps through #R$5C84 and the two frames after "
               "it, #R$5D14, 144 bytes apart. In room 45, the knight put well away for six "
               "passes and then 10 short of the creature the object table puts at 140, 74, 90 "
               "(his x and z written into his record: his place on the screen is worked out "
               "afresh from them each pass, #R$F65C). This code never ran in the build's play "
               "sessions."),
    "rising": ("A guard rising out of the floor", ["$A4B8", "$A41C", "$A380", "$A2E4"],
               "State 9 (#R$F1E0): the guard starts as its helmet, #R$A4B8, and +17 counts "
               "up a pass at a time; at $37 it becomes #R$A41C, at $3A #R$A380, at $3D "
               "#R$A2E4, and at $40 it has risen (+17 = $51) and walks after the knight in "
               "the guards' frames. Room 72's, as the object table has it, the knight "
               "standing where a new game starts him."),
    "waking": ("The robed figure waking", ["$6084"],
               "State 15 (#R$F309): room 61's robed figure (#R$6084) stands quite still, "
               "not even falling, until the thing of kind 11 -- the book -- lies in the "
               "room; then it takes the wraith's frames and state 11 and comes for the "
               "knight. Staged: before room 61 was entered, the object table's record for "
               "the book (thing 7, which lies in room 14) was given room 61 and a place on "
               "its floor."),
    "drawing": ("A room being drawn", [],
                "Room 29, the first room of a game, drawn from nothing by its commands "
                "(#R$E55B, #R$E5A6): points and lines, parts shared between rooms, and "
                "fills that flood an area with a texture a run at a time (#R$E734), bounded "
                "by what is set in the clean copy of the screen (#R$C000), which the room "
                "fills with its outline first. Then the doors and still things are drawn in "
                "and the screen copied to the clean copy again (#R$FE15), and after the first "
                "pass, which draws the live objects, the room is coloured (#R$F0FB). The game "
                "draws all this black on black -- the player sees nothing until the colours "
                "go on -- so up to then the pixels here are shown in the colours the room "
                "gets. The screen was read once a television frame, each frame labelled with "
                "the commands fetched in it."),
    "compositor": ("A moving object redrawn", [],
                   "Nothing is drawn to a buffer and copied: #R$ECBD rebuilds only the "
                   "rectangle of the screen an object covers -- a byte wider than its "
                   "sprite and three rows more above and below -- straight onto the screen, "
                   "from the clean copy of the room, the object's own sprite and mask, and "
                   "whatever overlaps it: objects in front leave their pixels on the screen, "
                   "objects behind are drawn in first (#R$E3E4). In room 61 the knight walks "
                   "down x behind a table, towards the robed figure, which is behind him and "
                   "is redrawn every pass too. Each frame is the screen after one call of the "
                   "compositor, with the rectangle it rebuilt outlined (the outline is not the "
                   "game's). Slowed down: each call is held for 0.4 seconds."),
    "door": ("Through a door", [],
             "Room 44: the knight walks up y into the door in its far wall (#R$F7C4): the "
             "door's +17 says which way it is gone through, its +13 the room behind and its "
             "+15, +16 and +18 where he arrives. #R$F8EC puts him there and enters the room "
             "(#R$FD20): the screen goes black while room 43 is drawn, the doors and still "
             "things are drawn in, the first pass draws the rest, and the room is coloured "
             "all at once. The whole screen; the pass that went through the door is shown a "
             "television frame at a time."),
    "title": ("The title page, and a game starting", [],
              "From the loaded tape: the loading tune over the loading screen until a key "
              "(#R$C000), then the title (#R$F065): room 79 drawn black on black, coloured, "
              "and the title page's words printed a character at a time through the "
              "compositor (#R$B686, #R$EBFE), then the wait for a key (PAUS). A key starts a "
              "game: room 29 is drawn, again unseen, and appears after its first pass. Read "
              "a television frame at a time, and pass by pass once the game is running."),
    "game-over": ("GAME OVER", [],
                  "Room 9's bridge over the pit: the knight walks off its near edge (A), "
                  "falls, and meets the slab of kind 7 at the bottom, which takes all his LIFE "
                  "(#R$F959) -- he vanishes as he touches it. The main loop sees LIFE at 00 "
                  "and returns from #R$FD20; #R$F065 draws room 1 behind GAME OVER and waits "
                  "for a key. Nothing staged but the knight's place on the bridge."),
    "ending-failed": ("The end of the quest, failed", [],
                      "Room 31's door into room 81 needs thing 8 in the place in use. Here "
                      "thing 8, picked up in room 61, is the only thing carried, and walking "
                      "through the door ends the game (#R$FD20): room 81, the verdict, the two "
                      "closing lines (#R$DFF2), and a wait for a key before GAME OVER."),
    "ending-done": ("The end of the quest, done", [],
                    "The same, carrying thing 5 as well, picked up in room 33 first: "
                    "#R$FD20 looks for it among the five places, and the verdict is the "
                    "other one."),
}

GROUPS = [
    ("The knight", ["walk-upx", "walk-upy", "walk-downx", "walk-downy", "standing", "jump",
                    "jump-running", "fight", "stoop", "fall", "fall-damage"]),
    ("The creatures, alone", ["guards", "troll", "wraith", "ghost", "hunched", "cloud",
                              "strike", "rising", "waking"]),
    ("Drawing", ["drawing", "compositor"]),
    ("Doors, the title and the end", ["door", "title", "game-over", "ending-failed",
                                      "ending-done"]),
]
# Pictured at three times the Spectrum's size; the rest (whole screens) at
# twice. The things alone are at ALONE_SCALE.
SMALL = {"walk-upx", "walk-upy", "walk-downx", "walk-downy", "standing", "jump",
         "jump-running", "fight", "stoop", "compositor"}
MAX_LISTED = 12


def _order(frames: list[tuple]) -> str:
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


def _fills(anim: dict) -> str:
    """For the room being drawn: each fill, and how long it took -- from the
    television frame its command was fetched in to the next command."""
    fills = []
    for frame in anim["passes"]:
        label = frame.label
        if frame.kind != "drawing":
            continue
        if "Fill with texture" in label and not label.endswith("going on"):
            fills.append([re.findall(r"Fill with texture (\d+)", label)[-1], frame.tstates])
        elif label.endswith("going on") and label.startswith("Fill") and fills:
            fills[-1][1] += frame.tstates
    total = sum(ms for _, ms, _, _ in anim["frames"]) / 1000
    return (f"{len(anim['frames'])} frames, {total:.1f} s in all. The fills, each with the time "
            f"from the television frame it began in to the one it ended in: "
            + ", ".join(f"texture {t} ({_ms(n)} ms)" for t, n in fills))


def _sprite_links(addresses, known: set) -> str:
    """Links to the Sprites page's rows, for the sprites it has."""
    return ", ".join(f'<a href="Sprites.html#sprite{int(a[1:], 16):04x}">{a}</a>'
                     if int(a[1:], 16) in known else a for a in addresses)


def _alone_caption(cell: dict) -> str:
    seen = []
    for _, _, label, _ in cell["frames"]:
        for part in label.split("/"):
            if part not in seen:
                seen.append(part)
    if len(cell["frames"]) == 1:
        return f"{', '.join(seen)}: one picture, {len(cell['passes'])} passes"
    ms = [_ms(t) for t in cell["times"]]
    return f"{', '.join(seen)}; {len(cell['passes'])} passes of {_span(ms)}"


def _family_table(anim: dict, out_dir: Path) -> list[str]:
    lines = ['<table class="kl-table">',
             "<tr><th></th>" + "".join(f"<th>{_esc(WAY_WORDS[name])}</th>"
                                       for _, _, name, _ in WAYS) + "</tr>"]
    for row in anim["rows"]:
        cells = []
        for cell in row["cells"]:
            if isinstance(cell, str):
                cells.append(f"<td>{_esc(cell)}</td>")
                continue
            save_alone_gif(out_dir / f"{cell['name']}.gif", cell["frames"], row["size"])
            width, height = row["size"]
            cells.append(f'<td><img class="kl-sprite" src="images/animations/{cell["name"]}.gif" '
                         f'alt="{_esc(row["name"])}, {cell["way"]}" width="{width * ALONE_SCALE}" '
                         f'height="{height * ALONE_SCALE}"><br>{_esc(_alone_caption(cell))}</td>')
        lines.append(f'<tr><td>{_esc(row["name"])}<br>(<a href="Rooms.html#room{row["room"]}">'
                     f'room {row["room"]}</a>)</td>' + "".join(cells) + "</tr>")
    lines.append("</table>")
    return lines


def animations(snapshot: Path, log=print) -> dict[str, dict]:
    made = {}
    todo = ([(walking, (way,)) for _, _, way, _ in WAYS]
            + [(standing, ()), (jumping, (False,)), (jumping, (True,)), (fighting, ()),
               (stooping, ()), (falling, ()), (long_fall, ())]
            + [(family, (key,)) for key in FAMILIES]
            + [(ghost, ()), (hunched, ()), (cloud, ()), (strike, ()), (rising, ()),
               (waking, ()), (drawing, ()), (compositing, ()), (door, ()), (title, ()),
               (game_over, ()), (ending, (False,)), (ending, (True,))])
    for make, args in todo:
        log(f"  {make.__name__}{'' if not args else ' ' + str(args[0])}")
        anim = run(snapshot, make, *args)
        made[anim["key"]] = anim
    return made


def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    """Write the GIFs into html_dir/images/animations and return the
    Animations section."""
    out_dir = html_dir / "images" / "animations"
    out_dir.mkdir(parents=True, exist_ok=True)
    log("Running Fairlight's animations in the game's own code...")
    DISAGREEMENTS.clear()
    made = animations(snapshot, log)
    memory = bf.game_memory(snapshot)
    entries = skool_entries()
    code_map = snapshot.with_name("fairlight.map")
    known = ({a for a, *_ in bf.sprite_frames(snapshot, code_map)} if code_map.exists()
             else set())
    lines = ['<div class="kl-list">',
             "<p>An object in Fairlight animates by changing the sprite its record points "
             "at (+4 and +5): every pass of the main loop the author's CHE3D (#R$F1E0, "
             "going on at #R$F309) updates each object in the room, chooses its frame -- "
             "from a run of three that his ANIM steps forward and back, 0, 1, 2, 1, or by "
             "what the object is doing -- moves it, and redraws it where it now stands. The "
             "knight, the troll and the wraith face four ways with two views, one of them "
             "turned round in memory whenever they change between a way drawn as stored "
             "and its mirror image (#R$F127); the guards have a set of frames for each way. "
             "Only the rectangle an object covers is redrawn, straight onto the screen "
             "(#R$ECBD).</p>",
             "<p>Each animation below was made by running the game in SkoolKit's simulator "
             "when these pages were built: the tape's snapshot, the loading tune and the "
             "title passed with a key, and the room wanted entered the way a new game enters "
             "its first (TELE, in #R$F065). Where more was staged -- the knight put somewhere, "
             "a creature's place changed, something added to a room -- the animation says so. "
             "Each frame is the screen as a pass of the main loop left it. The main loop "
             "does not wait for the television (interrupts are off from #R$C47C on), so a "
             "pass lasts as long as its work -- about 30 to 100 ms in these rooms -- and each "
             "picture is shown for as long as the next pass took, counted in T-states at "
             "3.5MHz; the simulator has none of a real Spectrum's memory contention, so the "
             "game runs a little faster here. A picture the same as the one before is merged "
             "into it. Where the game is between passes -- a room being drawn, the title, "
             "the end -- the screen was read once a television frame (69,888 T-states).</p>",
             "<p>The creatures are shown alone, the way the "
             '<a href="Sprites.html">Sprites</a> page shows a sprite. In runs made the same '
             "way, the creature's record and the bytes of the sprite it pointed at -- as "
             "they lay in memory, turned round or not -- were kept at the end of every pass, "
             "and drawn by themselves by the game's own #R$ECBD and #R$E3E4 on a spare "
             "machine, once over a clean copy of zeros and once over ones: a pixel set in "
             "the first is the image, one clear in the second the solid part of the mask. "
             "Every picture was checked against the sprite's bytes as the listing reads them, "
             "and the bytes against the tape's, as they are or turned round. They are in "
             "the game's colours, black ink on paper: the image black, the solid part of "
             "the mask the Spectrum's white paper (a room's own colour in the game), the "
             "rest transparent, shown on the Sprites page's blue-grey. Each picture stands on its bottom left corner, "
             "and is shown for as long as its pass stayed on the screen. Where the way a "
             "creature faces changes its picture, its table has a GIF for each way.</p>",
             "<p>Under each: what it shows and how it was staged; what was measured in the "
             "run beside what the code says it should be; and the frames of the picture, "
             "with what each shows and for how long.</p>"]
    for heading, keys in GROUPS:
        lines.append(f"<h3>{_esc(heading)}</h3>")
        for key in keys:
            anim = made[key]
            title, sprites, words = TEXT[key]
            lines += [f'<div class="kl-item" id="{key}">', f"<h4>{_esc(title)}</h4>"]
            if "rows" in anim:
                lines += _family_table(anim, out_dir)
            elif "size" in anim:
                save_alone_gif(out_dir / f"{key}.gif", anim["frames"], anim["size"])
                width, height = anim["size"]
                lines.append(f'<img class="kl-sprite" src="images/animations/{key}.gif" '
                             f'alt="{_esc(title)}" width="{width * ALONE_SCALE}" '
                             f'height="{height * ALONE_SCALE}">')
            else:
                save_gif(out_dir / f"{key}.gif", anim["frames"])
                width, height = anim["frames"][0][0].size
                scale = 3 if key in SMALL else 2
                css = "kl-piece" if key in SMALL else "kl-scene"
                lines.append(f'<img class="{css}" src="images/animations/{key}.gif" '
                             f'alt="{_esc(title)}" width="{width * scale}" '
                             f'height="{height * scale}">')
            lines.append(f"<p>{link(words, entries)}</p>")
            if sprites:
                lines.append(f"<p>Sprites: {_sprite_links(sprites, known)}.</p>")
            measured = measure(key, anim, memory)
            if measured:
                measured = measured[0].upper() + measured[1:]
                lines.append(f"<p>{link(_esc(measured), entries)}</p>")
            if key == "drawing":
                lines.append(f"<p>In the picture: {_esc(_fills(anim))}.</p>")
            elif "rows" not in anim:
                lines.append(f"<p>In the picture: {_esc(_order(anim['frames']))}.</p>")
            lines.append("</div>")
    lines.append("</div>")
    body = "\n".join(lines)
    for line in body.splitlines():
        if line.startswith((";", "[")):
            raise RuntimeError(f"a section line starts with {line[0]!r}: {line[:40]}")
    for problem in DISAGREEMENTS:
        log(f"  WARNING: animation disagrees with the code: {problem}")
    return {"Animations": body}
