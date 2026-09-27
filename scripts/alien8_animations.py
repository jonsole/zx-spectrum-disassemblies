"""Alien 8's animations, as GIFs of the game running its own code.

build_alien8.py --html calls build(), which writes the GIFs into the HTML
directory and returns the Animations section. Nothing here is committed
output: every frame is the game's own drawing.

Alien 8 has no animation frames as such, any more than Knight Lore or
Pentagram has: an object's graphic number -- byte 0 of its 32-byte record --
picks both its update routine (through the table at $A7EA) and its sprite
(through $7827), so an object animates by changing its own graphic. The
robot's legs step the low two bits of theirs, a turn puts them in one of
four part-way views for two turns, a death's sparkle counts from 48 to 55, a
socket's sparkle from 108 to 111.

The frames are not put together from the sprites. Each animation is the game
running in SkoolKit's simulator, from the snapshot at $6300, started the way
the build's sessions start it (build_alien8.Machine: the menu, 1 for the
keyboard, 0) and put into the room wanted by the game's own restart: the
room, the spot and the way he faces go into the start records at $CA1D, his
death is begun the way $B39A begins it, and the game starts the next life
there ($CA07) and has him appear, as it does after every death. The rooms are
picked for a clear view of the thing shown (see each function); where a scene
is staged beyond that -- a valve put in a room, the robot put on a button --
the function says so, and so does the page. Then the game is run a turn at a
time -- a turn being one pass of the main loop from MAIN_NEXT_TURN ($A68E)
back to it: every object's update, the depth-sorted drawing into the buffer,
the changed rectangles copied to the screen, the wait that evens the pace,
the clock -- and each frame of a GIF is the screen as that turn left it, read
from screen memory. So the robot is put together by the game from his two
records, each thing is drawn in the order and at the offsets its own routine
sets, and what one frame shows next to the next is exactly what the game drew.

Each frame is shown for as long as the game took over its turn, counted in
T-states in the simulator at 3.5MHz. The simulator has no memory contention,
so the game runs a little faster here than on a real Spectrum, where the ULA
holds up writes to the screen; a frame drawn identically to the one before
is merged into it. Where there is no turn -- the menu, the summary -- the
screen is read once a television frame (69,888 T-states) and identical
frames merged, and FLASH is shown as the ULA shows it, swapping ink and
paper every 16 television frames.
"""
from __future__ import annotations

import html
import re
from pathlib import Path

import build_alien8 as ba

SKOOL = ba.OUT_DIR / "alien8.skool"
TSTATES_PER_SECOND = 3_500_000
T_STATES_PER_MS = 3500
TV_FRAME = 69_888                 # T-states in a 48K Spectrum's frame
FLASH_FRAMES = 16                 # the ULA swaps FLASH cells every 16 frames

# The game (see the entries).
MAIN_LOOP = 0xA68E                # MAIN_NEXT_TURN: where each turn begins
PLAYER = ba.PLAYER                # record 0, the legs; the top is record 1
RECORD_SIZE = 32
RECORD_COUNT = 56
OBJECTS_END = PLAYER + RECORD_SIZE * RECORD_COUNT
START_LEGS = ba.START_LEGS        # the robot as the next life starts
START_TOP = ba.START_TOP
LIVES = ba.LIVES
TURNS = 0x5B02
RANDOM = ba.RANDOM
CONTROL = ba.CONTROL
PLAYER_ROOM = ba.PLAYER_ROOM
GAME_OVER = ba.GAME_OVER
WON = ba.WON
CHAMBERS = ba.CHAMBERS
CLOCK = ba.CLOCK
PLACES = ba.PLACES
PLACE_SIZE = ba.PLACE_SIZE
VALVE = ba.VALVE                  # records 2 and 3: what the room has from the places
CARRIED_LAST = ba.CARRIED_LAST
DROP_LATCH = ba.DROP_LATCH
MIRRORED = 0x40                   # +$07 bit 6
GRAPHICS = 0x7827                 # graphic number -> sprite
FLOOR = 64                        # every room's (#R$6460)
APPEARING = 56                    # the first frame of the robot appearing (#R$BC70)
STANDING = 17                     # legs together, from behind; +4 from the front

# The screen and what a frame keeps.
VARIABLES = 0x5B00                # the game's variables, up to the object records
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

TURN_LIMIT = 30 * TSTATES_PER_SECOND   # a turn longer than this is a hang


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
# The game, running.
# --------------------------------------------------------------------------

def _tracer_class():
    from skoolkit.kbtracer import KEY_BITS
    from skoolkit.simutils import T
    from skoolkit.trace import Tracer

    class GameTracer(Tracer):
        """Held keys and a Kempston stick for the game's IN, as the build's
        sessions give them, and the T-state of every change of the speaker
        bit (bit 4 of an OUT to port $FE) the game makes."""

        def __init__(self, simulator):
            super().__init__(simulator, 0, 0, 0, [0] * 16, 0, False)
            self.keys = set()
            self.kempston = 0
            self.speaker = 0            # the loader leaves it off
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
    """What one turn (or one television frame) left: the screen, the object
    records, how long it took, and the speaker edges made in it."""

    def __init__(self, memory, start: int, end: int, edges: list[int], turn: int = -1,
                 keys=()):
        self.keys = frozenset(keys)        # the keys held through it
        self.speaker = 0                   # the speaker bit as it began (set by Game)
        self.screen_bytes = bytes(memory[SCREEN:SCREEN_END])
        self.variables = bytes(memory[VARIABLES:PLAYER])
        self.objects = bytes(memory[PLAYER:OBJECTS_END])
        self.start, self.end = start, end
        self.tstates = end - start
        self.edges = edges
        self.turn = turn
        self.left = False

    def record(self, index: int) -> bytes:
        return self.objects[RECORD_SIZE * index:RECORD_SIZE * (index + 1)]

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
    """Alien 8 on a simulated 48K Spectrum, from the snapshot at $6300:
    build_alien8's Machine, with a tracer that also logs the speaker."""

    def __init__(self, snapshot: Path):
        from skoolkit.simutils import T

        self.machine = ba.Machine(snapshot)
        self.tracer = _tracer_class()(self.machine.simulator)
        self.machine.tracer = self.tracer
        self.machine.simulator.set_tracer(self.tracer)
        self.sim = self.machine.simulator
        self.memory = self.sim.memory
        self.T = T

    @property
    def now(self) -> int:
        return self.sim.registers[self.T]

    @property
    def pc(self) -> int:
        return self.machine.pc

    def play(self, steps, label: str = "animation") -> None:
        """Steps as build_alien8's sessions take them."""
        self.machine.play(steps, label)

    def poke(self, address: int, value) -> None:
        if isinstance(value, (list, tuple, bytes)):
            for offset, byte in enumerate(value):
                self.memory[address + offset] = byte
        else:
            self.memory[address] = value

    def peek(self, address: int) -> int:
        return self.memory[address]

    def hold(self, keys=(), stick: int = 0) -> None:
        self.tracer.keys = set(keys)
        self.tracer.kempston = stick

    def to_turn(self) -> None:
        """Run on to the start of the next turn."""
        self.run_to(MAIN_LOOP)

    def run_to(self, address: int, limit: int = TURN_LIMIT) -> None:
        from skoolkit.simutils import PC

        self.sim.trace(self.machine.pc, address, 0, self.now + limit, True, None, None,
                       None, None, None)
        self.machine.pc = self.sim.registers[PC]
        if self.machine.pc != address:
            raise RuntimeError(f"${address:04X} was not reached (PC ${self.machine.pc:04X})")

    def turn(self, leaves=None) -> Frame:
        """One turn, from MAIN_LOOP to MAIN_LOOP. The machine must be at
        MAIN_LOOP (to_turn() gets it there).

        With `leaves`, a test of memory for the game having left the turns
        behind -- a game ended -- the turn is run a television frame at a
        time, and if the test comes true before the turn ends, the frame
        returned is what there is so far, marked `left`, and the machine is
        left where it got to, within a television frame of the moment."""
        from skoolkit.simutils import PC

        if self.machine.pc != MAIN_LOOP:
            self.to_turn()
        start = self.now
        first = len(self.tracer.edges)
        speaker = self.tracer.speaker
        left = False
        if leaves is None:
            self.run_to(MAIN_LOOP)
        else:
            while True:
                self.sim.trace(self.machine.pc, MAIN_LOOP, 0, self.now + TV_FRAME, True,
                               None, None, None, None, None)
                self.machine.pc = self.sim.registers[PC]
                if self.machine.pc == MAIN_LOOP:
                    break
                if leaves(self.memory):
                    left = True
                    break
                if self.now - start > TURN_LIMIT:
                    raise RuntimeError(f"a turn did not end (PC ${self.machine.pc:04X})")
        edges = [t - start for t in self.tracer.edges[first:]]
        frame = Frame(self.memory, start, self.now, edges, _word(self.memory, TURNS),
                      self.tracer.keys)
        frame.speaker = speaker
        frame.left = left
        return frame

    def turn_through(self, address: int, count: int, finish: bool = True) -> list[Frame]:
        """One turn, cut into pieces where the game reaches `address` --
        `count` times, a Frame for each piece -- and, with `finish`, a last
        piece to the end of the turn: for a turn in which the game does
        something long of its own, such as the colours of a chamber cycling
        (#R$AF79). Stops the build if the turn ends before the address has
        come round `count` times."""
        from skoolkit.simutils import PC

        if self.machine.pc != MAIN_LOOP:
            self.to_turn()
        frames = []
        for _ in range(count + 1 if finish else count):
            stop = address if len(frames) < count else MAIN_LOOP
            start = self.now
            first = len(self.tracer.edges)
            speaker = self.tracer.speaker
            if not frames:
                # Past MAIN_LOOP's first instruction, so that meeting
                # MAIN_LOOP again means the turn is over.
                self.sim.trace(self.machine.pc, 0, 1, start + TURN_LIMIT, True, None, None,
                               None, None, None)
            executed = set()
            self.sim.trace(self.sim.registers[PC], stop, 0, start + TURN_LIMIT, True, None,
                           executed, None, None, None)
            self.machine.pc = self.sim.registers[PC]
            if self.machine.pc != stop or (stop != MAIN_LOOP and MAIN_LOOP in executed):
                raise RuntimeError(f"${address:04X} did not come {count} times in the turn")
            edges = [t - start for t in self.tracer.edges[first:]]
            frames.append(Frame(self.memory, start, self.now, edges, _word(self.memory, TURNS),
                                self.tracer.keys))
            frames[-1].speaker = speaker
        return frames

    def turns(self, count: int, each=None) -> list[Frame]:
        frames = []
        for _ in range(count):
            if each is not None:
                each(self)
            frames.append(self.turn())
        return frames

    def sample(self, tstates: int, stop: int = 0) -> Frame:
        """Run for `tstates` whatever the game is doing -- or until it
        reaches `stop`, if that comes first -- and take the screen as it is
        then: for the screens that have no turns. The frame's `stopped` says
        whether `stop` was reached."""
        from skoolkit.simutils import PC

        start = self.now
        first = len(self.tracer.edges)
        speaker = self.tracer.speaker
        self.sim.trace(self.machine.pc, stop, 0, start + tstates, True, None, None,
                       None, None, None)
        self.machine.pc = self.sim.registers[PC]
        edges = [t - start for t in self.tracer.edges[first:]]
        frame = Frame(self.memory, start, self.now, edges, keys=self.tracer.keys)
        frame.speaker = speaker
        frame.stopped = bool(stop) and self.machine.pc == stop
        return frame

    # -- staging -----------------------------------------------------------

    def start_game(self, choice: str = "1") -> None:
        """From the snapshot through the menu into the first room, as the
        build's sessions start (keyboard by default)."""
        self.play(ba._start(choice))
        self.to_turn()

    def playing(self) -> bool:
        return ba._playing(self.memory)

    def enter(self, room: int, u: int = 128, v: int = 128, facing: int = 1,
              settle: int = 3, z: int = FLOOR) -> list[Frame]:
        """Put the robot into `room`, standing at U, V (and Z) and facing
        `facing` (0 lower U, 1 higher U, 2 higher V, 3 lower V; #R$C319), by
        the game's own restart: the start records (#R$CA1D) are set as a
        doorway would have left them, but without the walk in, and his death
        is begun the way #R$B39A begins it (build_alien8._kill). Five lives
        are put back first. Returns the turns from the death to `settle`
        turns after he is walking about in the new room."""
        self.poke(LIVES, 5)
        legs = STANDING + (4 if facing & 1 else 0)
        for record, graphic, height in ((START_LEGS, legs, 0), (START_TOP, legs + 16, 12)):
            flags = self.peek(record + 7) & ~MIRRORED
            if facing & 2:
                flags |= MIRRORED
            self.poke(record, [APPEARING, u, v, z + height])
            self.poke(record + 7, flags)
            self.poke(record + 8, room)
            self.poke(record + 9, [0, 0, 0, 0])          # no steps, no walk in
            self.poke(record + 0x10, graphic)
        ba._kill(self.memory)
        frames = []
        for _ in range(80):
            frames.append(self.turn())
            if self.peek(PLAYER_ROOM) == room and self.playing():
                break
        else:
            raise RuntimeError(f"the restart into room ${room:02X} never came")
        self.poke(LIVES, 5)
        frames += self.turns(settle)
        return frames

    def find(self, graphics, after: int = 0) -> int:
        """The first record index (from `after`) whose graphic is in
        `graphics`."""
        for index in range(after, RECORD_COUNT):
            if self.peek(PLAYER + RECORD_SIZE * index) in graphics:
                return index
        raise ValueError(f"no record of graphics {sorted(graphics)}")

    def find_all(self, graphics) -> list[int]:
        return [index for index in range(RECORD_COUNT)
                if self.peek(PLAYER + RECORD_SIZE * index) in graphics]

    def record_address(self, index: int) -> int:
        return PLAYER + RECORD_SIZE * index


# --------------------------------------------------------------------------
# Cropping and saving.
# --------------------------------------------------------------------------

def drawn_box(record: bytes):
    """Where the drawing code last put this record's picture, as a box of
    screen pixels (left, top, right, bottom): +$1A is the pixel x and +$1B the
    bottom row counted up from the bottom of the screen (#R$CFD2), and +$18
    and +$19 the width in bytes and the rows drawn (#R$C63D), from the byte
    that holds that x."""
    if record[0] < 2:
        return None
    width, height, x, y = record[0x18], record[0x19], record[0x1A], record[0x1B]
    if not width or not height or y >= 192:
        return None
    left = (x >> 3) * 8
    return left, max(0, 192 - y - height), min(256, left + 8 * width), 192 - y


def anchor(record: bytes, z: int | None = None) -> tuple[int, int]:
    """The projection of the record's U, V, Z without its drawing nudge
    (#R$CFD2), as a screen pixel counted from the top."""
    u, v = record[1], record[2]
    z = record[3] if z is None else z
    px = (u + v - 128) & 0xFF
    py = ((((v - u + 128) & 0xFF) >> 1) + z - 40) & 0xFF
    return px, 191 - py


def _union(a, b):
    if a is None:
        return b
    if b is None:
        return a
    return min(a[0], b[0]), min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3])


def crop(frames: list[Frame], records: list[int], anchor_record: int | None = None,
         fixed_z: bool = False, margin: int = 3, box=None) -> list:
    """Each frame's picture, cut down to the union of what `records` drew in
    all of them (or to `box`). With `anchor_record`, the box moves with that
    record's position -- only across the floor with fixed_z, so a jump is
    seen to rise."""
    z = frames[0].record(anchor_record)[3] if anchor_record is not None and fixed_z else None
    offsets, union = [], None
    for frame in frames:
        if anchor_record is not None:
            offsets.append(anchor(frame.record(anchor_record), z))
        else:
            offsets.append((0, 0))
        ox, oy = offsets[-1]
        for index in records:
            found = drawn_box(frame.record(index))
            if found is not None:
                union = _union(union, (found[0] - ox, found[1] - oy,
                                       found[2] - ox, found[3] - oy))
    if box is not None:
        union = box
        margin = 0
    if union is None:
        raise ValueError("nothing was drawn")
    left, top, right, bottom = (union[0] - margin, union[1] - margin,
                                union[2] + margin, union[3] + margin)
    pictures = []
    for frame, (ox, oy) in zip(frames, offsets):
        inverted = bool((frame.end // TV_FRAME // FLASH_FRAMES) & 1)
        whole = frame.screen(inverted)
        pictures.append(whole.crop((max(0, left + ox), max(0, top + oy),
                                    min(256, right + ox), min(192, bottom + oy)))
                        if anchor_record is None else
                        whole.crop((left + ox, top + oy, right + ox, bottom + oy)))
    return pictures


def duration(tstates: int) -> int:
    """A frame's time in milliseconds, to the 10ms a GIF can say."""
    return max(20, round(tstates / T_STATES_PER_MS / 10) * 10)


def merge(pictures: list, frames: list[Frame], labels: list[str]) -> list[tuple]:
    """(picture, milliseconds, label, tstates) per frame shown, identical
    pictures in a row as one, shown for their total time."""
    out = []
    for picture, frame, label in zip(pictures, frames, labels):
        if out and out[-1][0].tobytes() == picture.tobytes():
            last = out[-1]
            if label not in last[2]:
                last[2].append(label)
            out[-1] = (last[0], last[1], last[2], last[3] + frame.tstates)
        else:
            out.append((picture, 0, [label], frame.tstates))
    return [(p, duration(t), "/".join(label), t) for p, _, label, t in out]


def save_gif(path: Path, frames: list[tuple]) -> None:
    """Frames (picture, milliseconds, ...) as a looping GIF in the Spectrum's
    colours."""
    images = [picture for picture, *_ in frames]
    for image in images:
        image.putpalette(_FLAT_PALETTE)
    images[0].save(path, save_all=True, append_images=images[1:], loop=0,
                   duration=[ms for _, ms, *_ in frames], disposal=1, optimize=False)


def graphics_label(frame: Frame, records: list[int]) -> str:
    return "+".join(str(frame.record(i)[0]) for i in records if frame.record(i)[0] > 1) or "-"


def labelled(frames: list[Frame], record: int, fields: str, graphic: bool = True) -> list[str]:
    """A label per frame: the record's graphic and the named fields of its
    position (any of "UVZ")."""
    out = []
    for frame in frames:
        data = frame.record(record)
        parts = [str(data[0])] if graphic else []
        parts += [f"{name} {data['UVZ'.index(name) + 1]}" for name in fields]
        out.append(" ".join(parts))
    return out


def animation(key: str, frames: list[Frame], records: list[int], label_records=None,
              labels=None, **options) -> dict:
    pictures = crop(frames, records, **options)
    if labels is None:
        labels = [graphics_label(f, label_records if label_records is not None else records)
                  for f in frames]
    return {"key": key, "frames": merge(pictures, frames, labels), "turns": frames}


# --------------------------------------------------------------------------
# The animations.
# --------------------------------------------------------------------------

EMPTY_ROOM = 0x6D      # four walls, two doorways and nothing else
LEGS, TOP = 0, 1
WALK_KEY, JUMP_KEY, TAKE_KEY = "a", "q", "1"
LEFT_KEY, RIGHT_KEY = "z", "x"


def started(snapshot: Path) -> Game:
    game = Game(snapshot)
    game.start_game()
    return game


def walking(snapshot: Path, facing: int) -> dict:
    """One cycle of the walk, facing each way: walk held from standing, and
    the first four turns whose legs go through frames 0, 1, 2, 3."""
    game = started(snapshot)
    game.enter(EMPTY_ROOM, 128, 128, facing=facing)
    game.hold([WALK_KEY])
    frames = []
    for _ in range(24):
        frames.append(game.turn())
        cycle = frames[-4:]
        if len(cycle) == 4 and [f.record(LEGS)[0] & 3 for f in cycle] == [0, 1, 2, 3]:
            return animation(f"walk-{facing}", cycle, [LEGS, TOP], anchor_record=LEGS)
    raise RuntimeError("no clean walk cycle")


def _facing(record: bytes) -> int:
    """#R$C319: the mirror bit twice, and bit 2 of the graphic."""
    return (2 if record[7] & MIRRORED else 0) + ((record[0] >> 2) & 1)


def turning(snapshot: Path) -> dict:
    """A whole turn round, right turn held from standing facing 0: four
    quarter turns, each a part-way view held two turns and then the new
    facing. Then a turn standing."""
    game = started(snapshot)
    game.enter(EMPTY_ROOM, 128, 128, facing=0)
    frames = [game.turn()]
    game.hold([RIGHT_KEY])
    for _ in range(40):
        frames.append(game.turn())
        if len(frames) > 4 and (frames[-1].record(LEGS)[0] == frames[0].record(LEGS)[0]
                                and _facing(frames[-1].record(LEGS))
                                == _facing(frames[0].record(LEGS))):
            break
    game.hold()
    frames += game.turns(1)
    return animation("turn", frames, [LEGS, TOP], labels=_turn_labels(frames))


def _turn_labels(frames: list[Frame]) -> list[str]:
    out = []
    for frame in frames:
        legs = frame.record(LEGS)
        mirrored = "m" if legs[7] & MIRRORED else ""
        if 24 <= legs[0] <= 27:
            out.append(f"{legs[0]}{mirrored} part way")
        else:
            out.append(f"{legs[0]}{mirrored} facing {_facing(legs)}")
    return out


def jumping(snapshot: Path) -> dict:
    """A standing jump with the jump key held until he lands."""
    game = started(snapshot)
    game.enter(EMPTY_ROOM, 128, 110, facing=2)
    frames = [game.turn()]
    game.hold([JUMP_KEY])
    for _ in range(40):
        frames.append(game.turn())
        record = frames[-1].record(LEGS)
        if len(frames) > 2 and not record[0x0C] & 0x08:
            break                      # bit 3 of +$0C: the jump is over
    game.hold()
    frames += game.turns(2)
    return animation("jump", frames, [LEGS, TOP], anchor_record=LEGS, fixed_z=True,
                     labels=labelled(frames, LEGS, "Z"))


VALVE_GRAPHIC = ba.VALVE_GRAPHIC          # 96-99, a kind each
SOCKETS = range(112, 116)
CHAMBER_ROOM, CHAMBER_KIND = 0x0C, 0      # a socket in a pit of blocks, open above
ACTIVATE_PASS = 0xB026                    # #R$AF79's DEC D, the end of each pass
ACTIVATE_PASSES = 16
WHOLE_SCREEN = (0, 0, 256, 192)
# The room and the panel below it: where the robot stands and the three
# boxes of carried things.
ROOM_AND_PANEL = (0, 48, 256, 192)
CARRY_PLACE = 0                           # the place a staged valve borrows
PRESS_GAP = 4                             # turns between presses


def _press(game: Game, key: str = TAKE_KEY) -> Frame:
    """One turn with a key held, then let go: #R$BD6B acts once a press."""
    game.hold([key])
    frame = game.turn()
    game.hold()
    return frame


def carrying(snapshot: Path) -> dict:
    """A valve lying in front of him, picked up and put down again: four
    presses of the pick-up key, PRESS_GAP turns apart. The first takes it
    into the panel's first box; the next two move it along the boxes; the
    fourth puts it down under him and he stands on it. The valve is staged:
    place CARRY_PLACE is given a valve in the empty room, 14 units in front
    of where he appears, as the build's valve session does
    (build_alien8._put)."""
    game = started(snapshot)
    ba._put(CARRY_PLACE, VALVE_GRAPHIC + 1, EMPTY_ROOM, 128, 142, FLOOR)(game.memory)
    game.enter(EMPTY_ROOM, 128, 128, facing=2)
    frames = game.turns(2)
    for _ in range(4):
        frames.append(_press(game))
        frames += game.turns(PRESS_GAP - 1)
    frames += game.turns(2)
    labels = [_carried_label(f) for f in frames]
    return animation("carrying", frames, [], box=ROOM_AND_PANEL, labels=labels)


def _carried_label(frame: Frame) -> str:
    """Where the valve is: in the room (its record's graphic) or in which of
    the three carried slots (#R$BC9D's boxes)."""
    slots = [frame.variable(address) for address in (0x5B7C, 0x5B80, CARRIED_LAST)]
    for box, graphic in enumerate(slots):
        if graphic:
            return f"box {box + 1}"
    valve = frame.record(2)[0]
    if valve in range(VALVE_GRAPHIC, VALVE_GRAPHIC + 4):
        return f"in the room, Z {frame.record(2)[3]}, him {frame.record(LEGS)[3]}"
    return "-"


def socket_sparkle(snapshot: Path) -> dict:
    """The socket in room CHAMBER_ROOM with nothing from the places in the
    room: its sparkle over it, 16 turns, him standing well away."""
    game = started(snapshot)
    game.enter(CHAMBER_ROOM, *ba.CLEAR_SPOT, facing=1)
    socket = game.find(SOCKETS)
    frames = game.turns(16)
    return animation("sparkle", frames, [socket, socket + 1],
                     labels=[str(f.record(socket + 1)[0]) for f in frames])


def _seat_valve(game: Game, chambers: int = 0) -> tuple[list[Frame], int]:
    """He stands on the block beside room CHAMBER_ROOM's socket, 16 units
    from it in V and 24 above its base, carrying a valve of its kind in the
    last of his three slots, and presses the pick-up key once: #R$BD6B puts
    the valve down under him, #R$AF79 steers it a unit a turn towards the
    socket, out from under him, and it drops into the pit onto the socket.
    Staged: CARRIED_LAST given the valve and the place it came from, as a
    pick-up leaves them (#R$BE76), CHAMBERS set to `chambers`, and he is put
    8 above the block to land on it. Returns the turns from the one before
    the press to the one that leaves the valve sitting on the socket -- the
    next turn activates the chamber -- and the socket's record index."""
    game.enter(CHAMBER_ROOM, *ba.CLEAR_SPOT, facing=1)
    socket = game.find(SOCKETS, TOP + 1)
    record = game.record_address(socket)
    u, v, z, height = (game.peek(record + 1), game.peek(record + 2), game.peek(record + 3),
                       game.peek(record + 6))
    beside = [i for i in game.find_all({30}) if i > TOP
              and game.peek(game.record_address(i) + 1) == u
              and game.peek(game.record_address(i) + 2) == v - 16]
    block = game.record_address(max(beside, key=lambda i: game.peek(game.record_address(i) + 3)))
    top = game.peek(block + 3) + game.peek(block + 6)
    place = PLACES + PLACE_SIZE * CARRY_PLACE
    game.poke(place, 0)
    game.poke(CARRIED_LAST, [VALVE_GRAPHIC + CHAMBER_KIND, 0x14, place & 0xFF, place >> 8])
    game.poke(CHAMBERS, chambers)
    game.enter(CHAMBER_ROOM, u, v - 16, facing=2, z=top + 8, settle=0)
    game.turn()                        # the first turn in a room redraws it all
    frames = game.turns(2)
    frames.append(_press(game))
    for _ in range(60):
        valve = game.memory[VALVE:VALVE + 4]
        if list(valve[1:4]) == [u, v, z + height] and valve[0] in range(96, 100):
            return frames, socket
        frames.append(game.turn())
    raise RuntimeError("the valve never sat on the socket")


def chamber(snapshot: Path) -> list[dict]:
    """Room CHAMBER_ROOM's chamber activated (see _seat_valve): the valve put
    down and finding its way onto the socket, then the turn it activates the
    chamber, cut at the end of each of its sixteen passes over the colours,
    and the turns after. Two pictures of the one run: the valve's way to the
    socket, close to, and the activation, the whole screen."""
    game = started(snapshot)
    frames, socket = _seat_valve(game)
    passes = game.turn_through(ACTIVATE_PASS, ACTIVATE_PASSES)
    for number, frame in enumerate(passes[:-1]):
        frame.phase = f"pass {number + 1}"
    after = game.turns(4)
    whole = frames + passes + after
    labels = [getattr(f, "phase", None)
              or (f"valve {f.record(2)[0]} V {f.record(2)[2]} Z {f.record(2)[3]}"
                  if f.record(2)[0] else "carried") for f in whole]
    seating = animation("seating", whole, [LEGS, TOP, 2, socket], labels=labels)
    seating["socket"] = socket
    seating["before"] = frames
    shown = frames[-2:] + passes + after
    labels = [getattr(f, "phase", None) or f"{f.variable(CHAMBERS):02X} activated"
              for f in shown]
    activating = animation("chamber", shown, [], box=WHOLE_SCREEN, labels=labels)
    activating["passes"] = passes
    activating["socket"] = socket
    return [seating, activating]


def _stand_on(game: Game, room: int, graphics, safe=(96, 160), drop: int = 8,
              which: int = 0, facing: int = 1) -> int:
    """Into `room` twice: once to find the `which`th thing of one of
    `graphics`, then again standing on top of it -- `drop` units above, so
    that he lands on it in the first turns, the way a jump onto it would
    end. Returns the thing's record index."""
    game.enter(room, *safe, facing=facing)
    thing = [i for i in game.find_all(graphics) if i > TOP][which]
    record = game.record_address(thing)
    u, v, z, height = (game.peek(record + 1), game.peek(record + 2), game.peek(record + 3),
                       game.peek(record + 6))
    game.enter(room, u, v, facing=facing, z=z + height + drop, settle=0)
    return [i for i in game.find_all(graphics) if i > TOP][which]


LIFT_ROOM = 0x23           # two lifts (graphic 47) beside two rows of conveyors


def lift(snapshot: Path) -> dict:
    """Room LIFT_ROOM's first lift with him landing on it: from the turn it
    first rises to the turn it is back on the floor."""
    game = started(snapshot)
    thing = _stand_on(game, LIFT_ROOM, {47}, safe=(128, 176))
    game.turn()                        # the first turn in a room redraws it all
    frames = game.turns(130)
    heights = [f.record(thing)[3] for f in frames]
    up = next(i for i in range(1, len(heights)) if heights[i] > heights[i - 1])
    top = heights.index(max(heights), up)
    down = next(i for i in range(top, len(heights)) if heights[i] == heights[up - 1])
    frames = frames[up - 2:down + 2]
    return animation("lift", frames, [LEGS, TOP, thing], labels=labelled(frames, thing, "Z"))


CONVEYOR_ROOM = 0x0D       # a ring of conveyors round a spike


def conveyor(snapshot: Path) -> dict:
    """Room CONVEYOR_ROOM's ring of conveyors (graphics 68-71), with him
    landing on its first piece and standing still: carried round."""
    game = started(snapshot)
    _stand_on(game, CONVEYOR_ROOM, range(68, 72))
    game.turn()                        # the first turn in a room redraws it all
    frames = game.turns(56)
    ring = [i for i in game.find_all(range(68, 72)) if i > TOP]
    return animation("conveyor", frames, [LEGS, TOP] + ring,
                     labels=labelled(frames, LEGS, "UV", graphic=False))


DROPPING_ROOM = 0x12       # three dropping blocks (graphic 44) in steps up from the floor


def dropping(snapshot: Path) -> dict:
    """Room DROPPING_ROOM's highest dropping block with him landing on it,
    until it has stopped."""
    game = started(snapshot)
    game.enter(DROPPING_ROOM, 128, 128, facing=1)
    blocks = [i for i in game.find_all({44}) if i > TOP]
    highest = max(range(len(blocks)),
                  key=lambda n: game.peek(game.record_address(blocks[n]) + 3))
    thing = _stand_on(game, DROPPING_ROOM, {44}, safe=(128, 128), which=highest)
    game.turn()                        # the first turn in a room redraws it all
    frames = []
    for _ in range(80):
        frames.append(game.turn())
        if len(frames) > 6 and frames[-1].record(thing)[3] == frames[-4].record(thing)[3]:
            break                      # it has stopped
    frames += game.turns(2)
    return animation("dropping", frames, [LEGS, TOP, thing], labels=labelled(frames, thing, "Z"))


COLLAPSING_ROOM = 0x15     # collapsing blocks (graphic 45) in steps from the floor


def collapsing(snapshot: Path) -> dict:
    """A collapsing block on the floor of room COLLAPSING_ROOM, with him
    landing on it, until he is on the floor."""
    game = started(snapshot)
    thing = _stand_on(game, COLLAPSING_ROOM, {45})
    frames = [game.turn()]             # he lands on it
    for _ in range(20):
        frames.append(game.turn())
        if frames[-1].record(thing)[0] == 0:
            break
    for _ in range(20):
        frames.append(game.turn())
        if frames[-1].record(LEGS)[3] == FLOOR:
            break
    frames += game.turns(2)
    return animation("collapsing", frames, [LEGS, TOP, thing], label_records=[thing])


DYING = range(48, 56)       # the sparkle a death is (#R$B39A)
# Spots to try in a room of size 0, 128 by 128 (#R$6460): well inside its
# walls, at 64 to 192 in U and V. Sizes 1 and 2 are 64 by 128 and 128 by 64,
# U or V from 96 to 160; their spots are given with the rooms.
CORNERS = ((80, 176), (176, 80), (176, 176), (80, 80))


def _watch(snapshot: Path, key: str, room: int, graphics, where=((96, 160),), facing=1,
           turns: int = 48, count: int = 2, fields: str = "UV", with_him: bool = False,
           each=None) -> dict:
    """Things of `graphics` in `room` going about their business, with him
    standing out of their way: at the first of the spots in `where` from
    which nothing killed him in the turns watched (the things are deadly,
    and where they go depends on the random number, so a spot is tried and
    the next taken if he died)."""
    for spot in where:
        game = started(snapshot)
        game.enter(room, *spot, facing=facing)
        things = [i for i in game.find_all(graphics) if i > TOP][:count]
        frames = []
        for _ in range(turns):
            if each is not None:
                each(game)
            frames.append(game.turn())
            if frames[-1].record(LEGS)[0] in DYING:
                break
        else:
            break
    else:
        raise RuntimeError(f"{key}: he was killed from every spot tried")
    labels = [", ".join(labelled([frame], thing, fields)[0] for thing in things)
              for frame in frames]
    return animation(key, frames, things + ([LEGS, TOP] if with_him else []), labels=labels)


def mice(snapshot: Path) -> dict:
    """Room $4D's two clockwork mice (graphics 116-119), and nothing else."""
    return _watch(snapshot, "mice", 0x4D, range(116, 120), turns=64, where=((80, 104), (176, 104), (80, 152), (176, 152)))


def chaser(snapshot: Path) -> dict:
    """Room $9C's chaser (graphics 76-79) coming at him and pushing him."""
    return _watch(snapshot, "chaser", 0x9C, range(76, 80), where=((152, 100),), turns=40,
                  count=1, with_him=True)


SLOW_CHASER_ROOM = 0x5E    # one homing thing and nothing else


def slow_chaser(snapshot: Path) -> dict:
    """Room SLOW_CHASER_ROOM's homing thing (graphics 120, 121) coming at
    him, standing still in the corner furthest from it, until it reaches him
    and he dies: to the end of the sparkle."""
    game = started(snapshot)
    game.enter(SLOW_CHASER_ROOM, 150, 72, facing=1)
    chaser = game.find((120, 121), TOP + 1)
    frames = []
    for _ in range(120):
        frames.append(game.turn())
        if frames[-1].record(LEGS)[0] in DYING:
            break
    else:
        raise RuntimeError("the homing thing never reached him")
    frames += game.turns(8)
    labels = [f"{f.record(chaser)[0]} U {f.record(chaser)[1]} V {f.record(chaser)[2]}"
              for f in frames]
    return animation("slow-chaser", frames, [LEGS, TOP, chaser], labels=labels)


def wanderer(snapshot: Path) -> dict:
    """Room $89's two-part creature (graphic 95 over graphic 11)."""
    return _watch(snapshot, "wanderer", 0x89, (94, 95, 11), turns=64,
                  where=((80, 104), (176, 104), (80, 152), (176, 152)),
                  count=2)


def pacer(snapshot: Path) -> dict:
    """Room $A6's pacer (graphic 86 over graphic 11)."""
    return _watch(snapshot, "pacer", 0xA6, (86, 87, 11), where=CORNERS, turns=40,
                  count=2)


def leapers(snapshot: Path) -> dict:
    """Room $97's rows of leapers (graphic 130)."""
    return _watch(snapshot, "leapers", 0x97, {130}, where=((128, 128), (128, 184)), turns=64, count=8,
                  fields="Z")


def bobbers(snapshot: Path) -> dict:
    """Room $36's two bobbing blocks (graphic 31) among still deadly things."""
    return _watch(snapshot, "bobbers", 0x36, {31}, where=CORNERS, turns=64, count=2,
                  fields="Z")


def shuttles(snapshot: Path) -> dict:
    """Room $61's two shuttling blocks, one along U (graphic 66) and one along
    V (67), high over the floor."""
    return _watch(snapshot, "shuttles", 0x61, (66, 67), where=CORNERS, turns=40, count=2)


CEILING_ROOM = 0x58        # sixteen things hanging over the middle of the room


def ceiling(snapshot: Path) -> dict:
    """Room CEILING_ROOM's things hanging from the ceiling (graphic 73),
    him standing clear of them. DROP_LATCH, which the room sets because its
    number is even (#R$CAA2), is cleared, as picking something up clears it
    (#R$BE76); then from the turn the first lets go until the second has
    landed."""
    game = started(snapshot)
    game.enter(CEILING_ROOM, 150, 180, facing=1)
    game.poke(DROP_LATCH, 0)
    things = [i for i in game.find_all({73}) if i > TOP]
    frames, falling, landed = [], [], 0
    for _ in range(400):
        game.poke(LIVES, 5)
        frame = game.turn()
        now = [i for i in things if frame.record(i)[0x0D] & 0x04]
        if now or falling:
            frames.append(frame)
        for i in falling:
            if i not in now:
                landed += 1
        falling = now
        if landed >= 2:
            break
    else:
        raise RuntimeError("nothing dropped")
    frames += game.turns(3)
    moved = [i for i in things if frames[0].record(i)[3] != frames[-1].record(i)[3]]
    labels = [", ".join(f"Z {f.record(i)[3]}" for i in moved) for f in frames]
    return animation("ceiling", frames, moved, labels=labels)


REMOTE_ROOM = 0xD9         # one robot, its pad and buttons, and a block of fragile things
REMOTE_ROBOTS = range(124, 128)
FRAGILE = 129


def remote(snapshot: Path) -> dict:
    """Room REMOTE_ROOM: him put on the mirrored button of graphic 122 --
    order 3, two units a turn in plus V (#R$AA63, #R$AA43) -- as a jump onto
    it would leave him, and kept there; the robot walks the way the button
    says into the fragile thing in its path, which breaks. Until it is gone
    and three turns more."""
    game = started(snapshot)
    game.enter(REMOTE_ROOM, 96, 160, facing=1)
    buttons = [i for i in game.find_all({122}) if i > TOP]
    button = next(i for i in buttons if game.peek(game.record_address(i) + 7) & MIRRORED)
    record = game.record_address(button)
    u, v, z, height = (game.peek(record + 1), game.peek(record + 2), game.peek(record + 3),
                       game.peek(record + 6))
    game.enter(REMOTE_ROOM, u, v, facing=1, z=z + height + 8, settle=0)
    game.turn()                        # the first turn in a room redraws it all
    robot = game.find(REMOTE_ROBOTS, TOP + 1)
    ru, rv = game.peek(game.record_address(robot) + 1), game.peek(game.record_address(robot) + 2)
    ahead = [i for i in game.find_all({FRAGILE})
             if game.peek(game.record_address(i) + 1) == ru
             and game.peek(game.record_address(i) + 2) > rv]
    target = min(ahead, key=lambda i: game.peek(game.record_address(i) + 2))
    frames = []
    for _ in range(80):
        frames.append(game.turn())
        if frames[-1].record(target)[0] == 0:
            break
    else:
        raise RuntimeError("the fragile thing did not break")
    frames += game.turns(3)
    labels = [f"robot {f.record(robot)[0]} V {f.record(robot)[2]}, it "
              f"{f.record(target)[0] or '-'}" for f in frames]
    anim = animation("remote", frames, [LEGS, TOP, button, robot, target], labels=labels)
    anim["records"] = (robot, target, button)
    return anim


CLOCK_BOX = (200, 156, 248, 184)   # the light years' frame on the panel (#R$CB5A)


def clock(snapshot: Path) -> dict:
    """The light years from the first turn of a game: 6000 as a new game
    sets them (#R$A647), counted down to 5996, a digit rolling into place
    one row a turn."""
    game = Game(snapshot)
    game.play([([], 1.0), (["1"], 0.3), ([], 0.5), (["0"], 0.3)])
    game.hold()
    game.to_turn()
    frames = []
    for _ in range(40):
        frames.append(game.turn())
        if _clock_digits(frames[-1]) == "5995":
            break
    labels = [_clock_label(f) for f in frames]
    return animation("clock", frames, [], box=CLOCK_BOX, labels=labels)


def _clock_digits(frame: Frame) -> str:
    return "".join(str(frame.variable(CLOCK + i) >> 4) for i in range(4))


def _clock_label(frame: Frame) -> str:
    """The digits, and each one's count of rows still to roll (bits 0-2)."""
    rolling = [frame.variable(CLOCK + i) & 7 for i in range(4)]
    return _clock_digits(frame) + ("" if not any(rolling) else
                                   " rolling " + "".join(str(r) for r in rolling))


SPIKE_ROOM = 0x12          # a spike (graphic 46) on the floor in a corner
SPIKES = 46


def _to_the_spike(game: Game) -> int:
    """Into SPIKE_ROOM, standing 32 units from its spike in V and facing it:
    the spike's record index."""
    game.enter(SPIKE_ROOM, 96, 160, facing=1)
    spike = game.record_address(game.find({SPIKES}, TOP + 1))
    u, v = game.peek(spike + 1), game.peek(spike + 2)
    game.enter(SPIKE_ROOM, u, v + 32, facing=3)
    return game.find({SPIKES}, TOP + 1)


def dying(snapshot: Path) -> dict:
    """He walks into a spike -- walk held until he is killed -- and the game
    puts him back for the next life: from the turn before he walks to the
    third turn of the new life."""
    game = started(snapshot)
    spike = _to_the_spike(game)
    frames = [game.turn()]
    game.hold([WALK_KEY])
    for _ in range(40):
        frames.append(game.turn())
        if frames[-1].record(LEGS)[0] in DYING:
            break
    else:
        raise RuntimeError("he walked and did not die")
    game.hold()
    for _ in range(60):
        frames.append(game.turn())
        if frames[-1].record(LEGS)[0] in ba.LEGS:
            break
    else:
        raise RuntimeError("the next life never came")
    frames += game.turns(3)
    anim = animation("dying", frames, [LEGS, TOP, spike], label_records=[LEGS, TOP])
    anim["spike"] = spike
    return anim


# Where the screens after a game end (#R$B761): the arrival screen (a game
# won) goes on to the summary at SUMMARY_SCREEN; the summary to the scene once
# GAME_OVER is set, at $B7C4.
SUMMARY_SCREEN = 0xB76B
SCENE_SET_UP = 0xB7C4


def _after_game(game: Game, screens: list[tuple[str, int]], after: float = 1.0,
                scene_turns: int = 2000) -> list[Frame]:
    """From wherever the end of a game has got to: the screens in `screens`
    -- a name, and the address that ends it -- read a television frame at a
    time; then the scene after a game a turn at a time, to the menu; then
    `after` seconds of the menu, a television frame at a time. Each frame's
    `phase` names what it shows."""
    frames = []
    for name, end in screens:
        for _ in range(90 * 50):
            frame = game.sample(TV_FRAME, end)
            frame.phase = name
            frames.append(frame)
            if frame.stopped:
                break
        else:
            raise RuntimeError(f"{name} never ended")
    game.to_turn()                     # the scene's first turn (#R$B761)
    for _ in range(scene_turns):
        frame = game.turn(leaves=ba._at_menu)
        frame.phase = "the menu" if frame.left else "the scene"
        frames.append(frame)
        if frame.left:
            break
    else:
        raise RuntimeError("the scene after the game never ended")
    at_menu = game.now
    while game.now - at_menu < after * TSTATES_PER_SECOND:
        frame = game.sample(TV_FRAME)
        frame.phase = "the menu"
        frames.append(frame)
    return frames


def _phases(frames: list[Frame], turn_label) -> list[str]:
    """What each frame of an ending shows: a turn of the game (labelled by
    turn_label), or the screen or scene it is part of."""
    return [getattr(frame, "phase", None) or turn_label(frame) for frame in frames]


def game_over(snapshot: Path) -> dict:
    """The last life lost: as dying(), with no lives left, so that #R$CA07
    finds none to take and the game ends (#R$B761) -- the summary, under the
    game-over tune, then the re-programming scene, then the menu. No key is
    pressed: every wait runs its full time. The whole screen, a turn at a
    time where there are turns and a television frame at a time where there
    are not."""
    game = started(snapshot)
    _to_the_spike(game)
    game.poke(LIVES, 0)
    frames = [game.turn()]
    game.hold([WALK_KEY])
    for _ in range(40):
        game.poke(LIVES, 0)
        frame = game.turn()
        frames.append(frame)
        if frame.record(LEGS)[0] in DYING:
            break
    game.hold()
    for _ in range(40):
        frame = game.turn(leaves=lambda memory: memory[LIVES] == 0xFF)
        frames.append(frame)
        if frame.left:
            break
    else:
        raise RuntimeError("the game did not end")
    frames += _after_game(game, [("the summary", SCENE_SET_UP)])
    return animation("game-over", frames, [], box=WHOLE_SCREEN,
                     labels=_phases(frames, lambda f: graphics_label(f, [LEGS, TOP])))


def win(snapshot: Path) -> dict:
    """The twenty-fourth chamber, activated as chamber() activates the first
    but with CHAMBERS set to $23 (BCD) beforehand, as the build's ending
    session sets it: the valve's way to the socket, the colours, then
    #R$B761 with WON set -- the arrival screen under its tune, the summary
    under the game-over tune, the robot oiled -- and the menu. No key is
    pressed. The whole screen."""
    game = started(snapshot)
    frames, _ = _seat_valve(game, chambers=0x23)
    passes = game.turn_through(ACTIVATE_PASS, ACTIVATE_PASSES, finish=False)
    for number, frame in enumerate(passes):
        frame.phase = f"pass {number + 1}"
    frames += passes
    frames += _after_game(game, [("the arrival screen", SUMMARY_SCREEN),
                                 ("the summary", SCENE_SET_UP)])
    if not any(f.variable(WON) for f in frames):
        raise RuntimeError("the twenty-fourth chamber did not end the game")
    return animation("win", frames, [], box=WHOLE_SCREEN,
                     labels=_phases(frames, lambda f: f"{f.variable(CHAMBERS):02X} activated"))


MENU_KEYS = ["2", "3", "4", "5", "1"]   # a control method each, directional, then back
MENU_WAIT = 1.2                         # seconds between them
TUNE_HEARD = 0x5B31


def menu(snapshot: Path) -> dict:
    """The menu as the game first shows it: its tune, and 2, 3, 4, 5 and 1
    pressed in turn (each 0.2 seconds, and MENU_WAIT apart) -- the first
    press stops the tune -- the flash moving to the method chosen and 5
    setting directional control. Read once a television frame."""
    game = Game(snapshot)
    frames = []
    for _ in range(10 * 50):
        game.sample(TV_FRAME)             # up to the menu's first showing
        if game.peek(TUNE_HEARD):
            break
    for _ in range(int(3 * TSTATES_PER_SECOND / TV_FRAME)):
        frames.append(game.sample(TV_FRAME))
    for key in MENU_KEYS:
        game.hold([key])
        for _ in range(int(0.2 * TSTATES_PER_SECOND / TV_FRAME)):
            frames.append(game.sample(TV_FRAME))
        game.hold()
        for _ in range(int(MENU_WAIT * TSTATES_PER_SECOND / TV_FRAME)):
            frames.append(game.sample(TV_FRAME))
    return animation("menu", frames, [], box=WHOLE_SCREEN,
                     labels=[_menu_label(f) for f in frames])


def _menu_label(frame: Frame) -> str:
    """Which control method's line is flashing (bits 1-2 of CONTROL) and
    whether directional control is on (bit 3)."""
    control = frame.variable(CONTROL)
    return f"method {((control >> 1) & 3) + 1}" + (", directional" if control & 8 else "")


# --------------------------------------------------------------------------
# What each animation shows, measured from the frames that made it.
# --------------------------------------------------------------------------

def _signed(value: int) -> int:
    return value - 256 if value > 127 else value


def _index_of(frames: list[Frame], graphics) -> int | None:
    for frame in frames:
        for index in range(TOP + 1, RECORD_COUNT):
            if frame.record(index)[0] in graphics:
                return index
    return None


def _range_text(values) -> str:
    values = list(values)
    return f"{min(values)} to {max(values)}" if min(values) != max(values) else f"{values[0]}"


def _turn_times(frames: list[Frame]) -> str:
    times = [f.tstates for f in frames]
    return (f"{min(times):,} to {max(times):,} T-states" if min(times) != max(times)
            else f"{times[0]:,} T-states")


def _steps(frames: list[Frame], index: int, field: int) -> list[int]:
    values = [f.record(index)[field] for f in frames]
    return [_signed((b - a) & 0xFF) for a, b in zip(values, values[1:])]


def _measure_walk(frames, facing) -> str:
    first, last = frames[0].record(LEGS), frames[-1].record(LEGS)
    du, dv = _signed((last[1] - first[1]) & 0xFF), _signed((last[2] - first[2]) & 0xFF)
    axis = f"U {du:+d}" if du else f"V {dv:+d}"
    mirrored = "mirrored" if first[7] & MIRRORED else "not mirrored"
    return (f"Measured: legs {', '.join(str(f.record(LEGS)[0]) for f in frames)}, top "
            f"{', '.join(str(f.record(TOP)[0]) for f in frames)} ({mirrored}); from the "
            f"first frame to the last he moved {axis}, three units a turn (#R$C2F6), a "
            f"turn taking "
            f"{_turn_times(frames)}.")


def _measure_turn(frames) -> str:
    labels = _turn_labels(frames)
    part_way = sum(1 for f in frames if 24 <= f.record(LEGS)[0] <= 27)
    tops = sorted({f.record(TOP)[0] for f in frames})
    return (f"Measured, turn by turn: {', '.join(labels)} (m: mirrored). {part_way} turns "
            f"of part-way views in {len(frames) - 2} turns of the key held: each quarter "
            f"is two turns part way and one in the new facing, and the next quarter "
            f"starts at once while the key is still down. The top's graphics were "
            f"{', '.join(str(g) for g in tops)}, the legs' plus 16 every turn (#R$C6E4). "
            f"He did not move: U and V stayed at {frames[0].record(LEGS)[1]}, "
            f"{frames[0].record(LEGS)[2]}.")


def _measure_jump(frames) -> str:
    heights = [f.record(LEGS)[3] for f in frames]
    top = max(heights)
    steps = [b - a for a, b in zip(heights, heights[1:])]
    moved = _signed((frames[-1].record(LEGS)[2] - frames[0].record(LEGS)[2]) & 0xFF)
    return (f"Measured: the legs' Z turn by turn was {', '.join(str(z) for z in heights)} "
            f"-- steps of {', '.join(f'{s:+d}' for s in steps)}: up {top - heights[0]} and "
            f"down again, rising by 7, 6, 5 ... (8, less a gravity of 1 a turn while jump "
            f"is held and he is rising or level) and falling by 1, 3, 5 ... (2 a turn once "
            f"he is going down), until the floor stops him. The jump carried him "
            f"{moved:+d} in V, three units a turn the way he faces.")


def _measure_carrying(frames) -> str:
    presses = []
    for number, frame in enumerate(frames):
        slots = [frame.variable(a) for a in (0x5B7C, 0x5B80, CARRIED_LAST)]
        presses.append((number, slots, frame.record(2)[0], frame.record(LEGS)[3],
                        frame.record(2)[3]))
    before = presses[0]
    after = presses[-1]
    return (f"Measured: before the first press the valve (graphic {before[2]}) lay in "
            f"record 2 at Z {before[4]} and he stood at Z {before[3]}; each press moved "
            f"it one box along the panel (the slots CARRIED, then the one after, then "
            f"CARRIED_LAST); the fourth put it back in record 2 at Z {after[4]}, under "
            f"him, and he was lifted to Z {after[3]}, standing on it. Every press played "
            f"#R$B6B1's beep.")


def _measure_sparkle(frames) -> str:
    socket = _index_of(frames, SOCKETS)
    graphics = [f.record(socket + 1)[0] for f in frames]
    shown = sum(1 for g in graphics if g in range(104, 108))
    kind = frames[0].record(socket)[0] & 3
    return (f"Measured: the record after the socket (graphic {frames[0].record(socket)[0]}, "
            f"kind {kind}) went {', '.join(str(g) for g in graphics)} -- the sparkle "
            f"(108-111) a frame a turn, and the valve wanted ({104 + kind}) for two turns "
            f"each time the frame came round to {108 + kind}: {shown} of {len(frames)} "
            f"turns. It hovered at Z {frames[0].record(socket + 1)[3]}, 13 above the "
            f"socket's {frames[0].record(socket)[3]}.")


def _measure_chamber(anim) -> str:
    frames, passes = anim["turns"], anim["passes"]
    before, after = frames[0], frames[-1]
    socket = _index_of(frames, SOCKETS)
    valve = after.record(2)
    pass_times = [p.tstates for p in passes[1:-1]]
    total = sum(p.tstates for p in passes)
    return (f"Measured: the turn the chamber was activated in took {total:,} T-states "
            f"({total / TSTATES_PER_SECOND:.2f} s), of which each of the middle passes "
            f"over the 768 attribute cells took {_range_text(f"{t:,}" for t in pass_times)} "
            f"T-states with "
            f"its sparkle's sound and pause. After it the valve was graphic {valve[0]} at "
            f"U {valve[1]}, V {valve[2]}, Z {valve[3]} -- the socket's U and V and its Z "
            f"{after.record(socket)[3]} plus 12 -- the room's ink (ROOM_INK) had gone from "
            f"{before.variable(0x5B0D)} to {after.variable(0x5B0D)}, and CHAMBERS from "
            f"{before.variable(CHAMBERS):02X} to {after.variable(CHAMBERS):02X}.")


def _measure_seating(anim) -> str:
    frames = [f for f in anim["turns"] if not getattr(f, "phase", None)]
    socket = anim["socket"]
    press = next(n for n, f in enumerate(frames) if f.record(2)[0] in range(96, 100))
    seated = next(n for n, f in enumerate(frames) if f.record(2)[0] in range(100, 104))
    valve = [f.record(2) for f in frames[press:seated]]
    legs = [f.record(LEGS)[3] for f in frames[press:seated]]
    his_v = frames[press].record(LEGS)[2]
    return (f"Measured: put down under him at V {his_v} and Z {valve[0][3]} (he was lifted "
            f"to Z {legs[0]}), and already a step on by the end of that turn, the valve's "
            f"V went "
            f"{', '.join(str(r[2]) for r in valve)} -- a unit a turn towards the socket's "
            f"{frames[0].record(socket)[2]} -- and its Z "
            f"{', '.join(str(r[3]) for r in valve)}: out from under him (he fell back to Z "
            f"{legs[-1]}, the top of the block) and down into the pit onto the socket, 12 "
            f"above its base at {frames[0].record(socket)[3]}. The turn after it sat there "
            f"it became graphic {frames[seated].record(2)[0]}, {seated - press} turns after "
            f"the press.")


def _measure_lift(frames) -> str:
    lift = _index_of(frames, {47})
    heights = [f.record(lift)[3] for f in frames]
    top = heights.index(max(heights))
    rises = sum(1 for a, b in zip(heights, heights[1:top + 1]) if b > a)
    falls = sum(1 for a, b in zip(heights[top:], heights[top + 1:]) if b < a)
    legs = [f.record(LEGS)[3] - f.record(lift)[3] for f in frames]
    return (f"Measured: the lift's Z went from {heights[0]} up to {max(heights)} in "
            f"{rises} turns of one unit each and down again to {heights[-1]} in {falls}, "
            f"with his legs {_range_text(legs)} above it all the way; LIFT_TOP was "
            f"{frames[0].variable(0x5B25)} (its first Z, {heights[0]}, plus 48). The turns "
            f"took {_turn_times(frames)}.")


def _measure_conveyor(frames) -> str:
    moves = []
    for a, b in zip(frames, frames[1:]):
        du = _signed((b.record(LEGS)[1] - a.record(LEGS)[1]) & 0xFF)
        dv = _signed((b.record(LEGS)[2] - a.record(LEGS)[2]) & 0xFF)
        moves.append((du, dv))
    kinds = sorted(set(moves))
    first, last = frames[0].record(LEGS), frames[-1].record(LEGS)
    return (f"Measured: his U and V went from {first[1]}, {first[2]} to {last[1]}, "
            f"{last[2]}; every turn's move was one of "
            + ", ".join(f"({u:+d}, {v:+d})" for u, v in kinds)
            + " in U and V, two units a turn along the conveyor under him, turning the "
            "corners with the ring. He stood still throughout.")


def _moved(frames: list[Frame], graphics) -> int:
    """The first record of one of `graphics` whose Z changed over the frames."""
    return next(i for i in range(TOP + 1, RECORD_COUNT)
                if frames[0].record(i)[0] in graphics
                and frames[0].record(i)[3] != frames[-1].record(i)[3])


def _measure_dropping(frames) -> str:
    block = _moved(frames, {44})
    heights = [f.record(block)[3] for f in frames]
    moving = sum(1 for a, b in zip(heights, heights[1:]) if b < a)
    return (f"Measured: the block's Z went from {heights[0]} to {heights[-1]}, one unit a "
            f"turn for {moving} turns, with him on top, and stopped on the floor; the "
            f"turns took {_turn_times(frames)}.")


def _measure_collapsing(frames) -> str:
    block = _index_of(frames, {45})
    graphics = [f.record(block)[0] for f in frames]
    return (f"Measured: the block's graphic turn by turn, {', '.join(str(g) for g in graphics)}; "
            f"his legs' Z {', '.join(str(f.record(LEGS)[3]) for f in frames)}. The 64 is "
            f"set and stepped on to 65 in the same turn (#R$B28C jumps into #R$B3A4), so "
            f"it is never drawn.")


def _moves(frames, index) -> list[tuple[int, int]]:
    return list(zip(_steps(frames, index, 1), _steps(frames, index, 2)))


def _measure_mice(frames) -> str:
    mice = [i for i in range(TOP + 1, RECORD_COUNT)
            if frames[0].record(i)[0] in range(116, 120)]
    speeds = set()
    turns = 0
    for mouse in mice:
        for du, dv in _moves(frames, mouse):
            if du or dv:
                speeds.add(abs(du) + abs(dv))
        mirrors = [f.record(mouse)[7] & MIRRORED for f in frames]
        turns += sum(1 for a, b in zip(mirrors, mirrors[1:]) if a != b)
    return (f"Measured over {len(frames)} turns: moves of "
            f"{', '.join(str(s) for s in sorted(speeds))} units a turn (two to five, less "
            f"where the collision code cut one short) along U or V, never both at once, "
            f"and {turns} quarter turns "
            f"between the two mice (the mirror flag flipping each time); the graphics "
            f"flip between a pair every turn they run.")


def _measure_chaser(frames) -> str:
    chaser = _index_of(frames, range(76, 80))
    moves = _moves(frames, chaser)
    him = _signed((frames[-1].record(LEGS)[2] - frames[0].record(LEGS)[2]) & 0xFF)
    him_u = _signed((frames[-1].record(LEGS)[1] - frames[0].record(LEGS)[1]) & 0xFF)
    graphics = [f.record(chaser)[0] for f in frames[:8]]
    return ("Measured: its steps from turn to turn were "
            + ", ".join(f"({u:+d}, {v:+d})" for u, v in sorted(set(moves)))
            + f" in U and V; its graphics {', '.join(str(g) for g in graphics)} ...; it "
            f"came up against him and pushed him {him_u:+d} in U and {him:+d} in V before "
            f"both were stopped, and he was not harmed.")


def _measure_slow(frames) -> str:
    chaser = _index_of(frames, (120, 121))
    died = next(n for n, f in enumerate(frames) if f.record(LEGS)[0] in DYING)
    moves = _moves(frames[:died + 1], chaser)
    return ("Measured: its steps from turn to turn were "
            + ", ".join(f"({u:+d}, {v:+d})" for u, v in sorted(set(moves)))
            + f" in U and V, its graphic flipping between 120 and 121 every turn; from "
            f"U {frames[0].record(chaser)[1]}, V {frames[0].record(chaser)[2]}, with him "
            f"at U {frames[0].record(LEGS)[1]}, V {frames[0].record(LEGS)[2]}, it reached "
            f"him in {died} turns, and he died.")


def _measure_creature(frames, graphics) -> str:
    upper = _index_of(frames, graphics)
    moves = _moves(frames, upper)
    turned = sum(1 for a, b in zip(moves, moves[1:]) if a != b and any(b))
    return ("Measured: its steps from turn to turn were "
            + ", ".join(f"({u:+d}, {v:+d})" for u, v in sorted(set(moves)))
            + f" in U and V over {len(frames)} turns, with {turned} changes of direction; "
            f"the lower half (graphic 11, the next record) kept to the same U and V, 12 "
            f"below.")


def _measure_leapers(frames) -> str:
    leapers = [i for i in range(TOP + 1, RECORD_COUNT) if frames[0].record(i)[0] == 130]
    rises, most = [], 0
    for leaper in leapers:
        heights = [f.record(leaper)[3] for f in frames]
        rises += [s for s in _steps(frames, leaper, 3) if s > 0]
        most = max(most, max(heights) - min(heights))
    in_air = max(sum(1 for i in leapers if f.record(i)[0x10] & 1) for f in frames)
    return (f"Measured: rises of {', '.join(str(r) for r in sorted(set(rises)))} units a "
            f"turn, a leap of at most {most} units, and never more than {in_air} of the "
            f"{len(leapers)} in the air at once.")


def _measure_shuttles(frames) -> str:
    blocks = [i for i in range(TOP + 1, RECORD_COUNT) if frames[0].record(i)[0] in (66, 67)]
    parts = []
    for block in blocks:
        graphic = frames[0].record(block)[0]
        field, axis = (1, "U") if graphic == 66 else (2, "V")
        values = [f.record(block)[field] for f in frames]
        steps = sorted({abs(s) for s in _steps(frames, block, field) if s})
        rests = sum(1 for a, b in zip(values, values[1:]) if a == b)
        parts.append(f"graphic {graphic} along {axis}, {min(values)} to {max(values)} in steps "
                     f"of {', '.join(str(x) for x in steps)}, standing still for {rests} of the "
                     f"turns")
    return (f"Measured over {len(frames)} turns: {'; '.join(parts)} -- a turn standing at "
            f"each end, where the folded count repeats.")


def _measure_bobbers(frames) -> str:
    blocks = [i for i in range(TOP + 1, RECORD_COUNT) if frames[0].record(i)[0] == 31]
    parts = []
    for block in blocks:
        heights = [f.record(block)[3] for f in frames]
        steps = _steps(frames, block, 3)
        parts.append(f"Z {min(heights)} to {max(heights)}, "
                     f"{'/'.join(str(x) for x in sorted({-s for s in steps if s < 0}))} a turn "
                     f"down and {'/'.join(str(x) for x in sorted({s for s in steps if s > 0}))} "
                     f"up")
    return (f"Measured over {len(frames)} turns: {'; '.join(parts)}; LIFT_TOP was "
            f"{frames[0].variable(0x5B25)}.")


def _measure_ceiling(frames) -> str:
    things = [i for i in range(TOP + 1, RECORD_COUNT) if frames[0].record(i)[0] == 73
              and frames[0].record(i)[3] != frames[-1].record(i)[3]]
    first = [f.record(things[0])[3] for f in frames]
    low = min(first)
    fall = first[:first.index(low) + 1]
    return (f"Measured: the first to let go fell {', '.join(str(z) for z in fall)} -- one "
            f"unit more each turn (#R$BFB6's gravity) -- and landed at {low}; the next "
            f"let go only once it had landed (DROPPING).")


def _measure_remote(anim) -> str:
    frames = anim["turns"]
    robot, target, button = anim["records"]
    moves = _moves(frames, robot)
    graphics = [f.record(target)[0] for f in frames]
    broke = next(n for n, g in enumerate(graphics) if g != FRAGILE)
    return (f"Measured: REMOTE_ORDERS was ${frames[1].variable(0x5B42):02X} (bit 7, a robot "
            f"in control; order 3) while he stood on the button; the robot's steps were "
            + ", ".join(f"({u:+d}, {v:+d})" for u, v in sorted(set(moves)))
            + f" in U and V, its graphic stepping 124-127; on turn {broke + 1} the thing "
            f"in its way went {', '.join(str(g) for g in graphics[broke:broke + 3])} and "
            f"its record emptied.")


def _measure_clock(frames) -> str:
    changes = [n for n, (a, b) in enumerate(zip(frames, frames[1:]))
               if _clock_digits(a) != _clock_digits(b)]
    gaps = sorted({b - a for a, b in zip(changes, changes[1:])})
    return (f"Measured: {_clock_digits(frames[0])} on the first turn of the game, all four "
            f"digits rolling from 6000, then a light year every "
            f"{', '.join(str(g) for g in gaps)} turns, the digit that changes rolling a "
            f"row a turn for six turns and resting for one.")


def _measure_dying(frames) -> str:
    graphics = [f"{f.record(LEGS)[0]}+{f.record(TOP)[0]}" for f in frames]
    appearing = sum(1 for f in frames if 56 <= f.record(LEGS)[0] <= 63)
    return ("Measured: legs and top turn by turn, " + ", ".join(graphics)
            + f". The sparkle is a frame a turn; appearing took {appearing} turns, a frame "
            "every other turn (on odd turn counts). The long frame near the end is the "
            "turn in which the room was built again and the next, which copies the whole "
            "of it to the screen.")


def _holds(anim, names) -> str:
    """How long each phase of an ending lasted, from the T-states of its
    frames."""
    out = []
    for name in names:
        tstates = sum(f.tstates for f in anim["turns"] if getattr(f, "phase", "") == name)
        out.append(f"{name} {tstates / TSTATES_PER_SECOND:.1f} s")
    return ", ".join(out)


def _measure_game_over(anim) -> str:
    frames = anim["turns"]
    scene = [f for f in frames if getattr(f, "phase", "") == "the scene"]
    return (f"Measured: {_holds(anim, ['the summary', 'the scene'])} -- the summary "
            f"stayed through the game-over tune and #R$B899's wait, a key being never "
            f"pressed; the scene ran {len(scene)} turns of {_turn_times(scene)}, no wait "
            f"evening them out.")


def _measure_win(anim) -> str:
    frames = anim["turns"]
    scene = [f for f in frames if getattr(f, "phase", "") == "the scene"]
    return (f"Measured: {_holds(anim, ['the arrival screen', 'the summary', 'the scene'])}; "
            f"the scene ran {len(scene)} turns.")


def _measure_menu(anim) -> str:
    return ("Measured: the FLASH cells swap every 16 television frames (320 ms), which is "
            "the ULA's doing, not the game's; the game moves the flash to the line of the "
            "key pressed (bits 1-2 of CONTROL) on its next pass, and key 5 turns the "
            "directional-control line's flash on (bit 3).")


def _measure(key: str, anim: dict) -> str:
    frames = anim["turns"]
    if key.startswith("walk-"):
        return _measure_walk(frames, int(key[-1]))
    simple = {"turn": _measure_turn, "jump": _measure_jump, "carrying": _measure_carrying,
              "sparkle": _measure_sparkle, "lift": _measure_lift,
              "conveyor": _measure_conveyor, "dropping": _measure_dropping,
              "collapsing": _measure_collapsing, "shuttles": _measure_shuttles,
              "mice": _measure_mice, "bobbers": _measure_bobbers, "chaser": _measure_chaser,
              "slow-chaser": _measure_slow, "leapers": _measure_leapers,
              "ceiling": _measure_ceiling, "clock": _measure_clock,
              "dying": _measure_dying}
    if key in simple:
        return simple[key](frames)
    if key == "wanderer":
        return _measure_creature(frames, (94, 95))
    if key == "pacer":
        return _measure_creature(frames, (86, 87))
    by_anim = {"chamber": _measure_chamber, "seating": _measure_seating,
               "remote": _measure_remote,
               "game-over": _measure_game_over, "win": _measure_win, "menu": _measure_menu}
    return by_anim[key](anim)


# The words for each animation: title, the graphics it shows (linked to their
# sprites), and what drives it. #R links only where an entry starts; link()
# makes the rest plain addresses.
TEXT = {
    "walk-0": ("Walking, facing 0 (lower U)", list(range(16, 20)) + list(range(32, 36)),
               "The legs' routine, #R$C0BE, reads the controls every turn, and while walk "
               "is held #R$C25E steps the low two bits of their graphic through four "
               "frames -- a stride, legs together, the other stride, together again -- with "
               "a footstep (#R$B6CE) on leaving each stride, and #R$C296 moves him three "
               "units the way he faces. The top (#R$C6E4) copies the legs' place every "
               "turn, sits 12 above them and takes their graphic plus 16. The way he faces "
               "is two bits (#R$C319): bit 2 of the graphic, the view from behind (16-19) "
               "or from the front (20-23), and the mirror bit. Facing 0 is from behind, not "
               "mirrored: up and to the left on the screen. When walk is let go the legs "
               "carry on to frame 1, legs together, and stand. Knight Lore's walk is six "
               'frames (<a href="../knightlore/Animations.html#sabreman-a">its '
               'animations</a>), Pentagram\'s four with frame 2 the standing one '
               '(<a href="../pentagram/Animations.html#walk-0">its animations</a>).'),
    "walk-1": ("Walking, facing 1 (higher U)", list(range(20, 24)) + list(range(36, 40)),
               "The same cycle seen from the front, not mirrored: down and to the right."),
    "walk-2": ("Walking, facing 2 (higher V)", list(range(16, 20)) + list(range(32, 36)),
               "From behind, mirrored: up and to the right."),
    "walk-3": ("Walking, facing 3 (lower V)", list(range(20, 24)) + list(range(36, 40)),
               "From the front, mirrored: down and to the left."),
    "turn": ("Turning round", [17, 21, 24, 25, 26, 27, 33, 37, 40, 41, 42, 43],
             "Alien 8's own. Knight Lore and Pentagram turn a quarter in one turn; here "
             "#R$C13C, on a turn key (or a joystick push under directional control), gives "
             "the legs a part-way view from #R$C1D2 or #R$C1DA -- 24 between the two "
             "facings away from the viewer, 25 between the two towards him, 26 side on, "
             "and 27, 26's drawing mirrored, on the other side -- and a count in bits 1-2 "
             "of +D. For graphics 24-27 the legs' routine is #R$C1E2, which holds the view "
             "for two turns, letting him only fall, and then gives him the standing "
             "graphic of the new facing from #R$C22D or #R$C235, with a footstep's sound. "
             "So a quarter turn takes three turns, and a walking robot stops while he "
             "turns. Here the right-turn key (X) was held from facing 0 for a whole circle: "
             "0, 2, 1, 3 and 0 again, clockwise on the screen."),
    "jump": ("Jumping", list(range(16, 20)) + list(range(32, 36)),
             "#R$C23D starts a jump when jump is held, he is not jumping already (bit 3 of "
             "+C) and not falling: a Z step of 8, with a rising sweep of sound (#R$B62C). "
             "#R$C296's gravity takes it away again -- one a turn while he is rising or "
             "level with jump held, two otherwise -- and a fall faster than two a turn "
             "sounds a note pitched by his height (#R$B63C). A jump always carries him "
             "forward, three units a turn, and the legs step all the way. Knight Lore's "
             "jump test, on the speed; Pentagram tests whether he stands on something. "
             "Here jump was held from standing until he landed; the picture stays over his "
             "place on the floor, so the rise is seen."),
    "dying": ("Dying, and the next life", list(range(48, 64)),
              "He walked into a spike (graphic 46, deadly both ways: #R$B2A4). The "
              "collision code marks him killed, and his routines turn both of his records "
              "into the sparkle a thing dies in (#R$B39A): #R$B3A4 steps it from 48 to 55 "
              "a turn at a time, with a sound that shortens as it goes, and 55 makes the "
              "record graphic 1, emptied when it is next drawn (#R$B3B0). With both of them empty the main loop starts the next "
              "life (#R$CA07): the start records, which hold him as he came into the room, "
              "are copied back, the room is built again, and he appears -- graphics 56 to "
              "62, a frame every other turn (#R$BC70), each with a sweep of sound, and "
              "63, which gives him back his own graphic (#R$BC83). Knight Lore's death and "
              'materialising (<a href="../knightlore/Animations.html#dying">its '
              "animations</a>), with a death of its own."),
    "carrying": ("Carrying a valve", [97],
                 "Only valves can be carried. #R$BD6B, from the legs' routine, acts once "
                 "for each press of the pick-up key, and only while he stands on something "
                 "inside the walls. It looks for a valve within his reach (#R$BEA7, his box "
                 "made four bigger each way) in the two records a room keeps for what lies "
                 "in it from the places (#R$AE99), and takes it into the first of three "
                 "slots, moving the others along. With nothing to take it puts down "
                 "whatever is in the last slot, under him, and lifts him 12 onto it; with "
                 "the last slot empty it only moves the slots along. So a valve just "
                 "picked up takes two more presses to reach the last slot and a fourth to "
                 "go down. The slots are the panel's three boxes (#R$BC9D), each coloured "
                 "by the kind of valve, and every press that gets that far beeps (#R$B6B1). "
                 "Here a valve (graphic 97) was staged in the empty room 14 units in front "
                 "of him, as the build's valve session puts one (one of the places given "
                 "the valve and the room); the presses and all that follows are the game's. "
                 "The picture is the room and the panel."),
    "sparkle": ("A socket's sparkle, and the valve it wants", [112, 108, 109, 110, 111, 104],
                "Each cryogenic chamber has a socket (#R$AE68, graphics 112-115, one for "
                "each kind of valve), built with its sparkle in the record after it "
                "(#R$AE33): the sparkle hovers 13 above the socket and steps through four "
                "frames, 108-111, drawn with the sprites of the sparkle a thing dies in; "
                "when the frame comes round to the socket's kind it becomes for two turns "
                "a picture of the valve the socket wants (#R$AE17, graphics 104-107, drawn "
                "with the valves' sprites). Both go the moment anything lies in the room "
                "from the places (#R$AE81), and the socket puts the sparkle back when the "
                "room is clear of them again. Here room $0C's socket, of kind 0, with "
                "nothing from the places in the room."),
    "seating": ("A valve finding its socket", [96, 100, 112],
                "A valve does the work itself (#R$AF79). Every turn, if the room's socket "
                "is of its kind, it takes a step of one unit in U and in V towards it; "
                "when it sits exactly on it -- the same U and V, 12 above the socket's "
                "base -- it becomes a seated valve (graphic 4 more, #R$AE5D, which never "
                "moves again and cannot be picked up) and activates the chamber in the "
                "same turn (the next picture). Room $0C's socket is at the bottom of a pit "
                "of blocks. Here he stood on the block beside it, carrying a valve of its "
                "kind in the last slot, and pressed the pick-up key: #R$BD6B put the valve "
                "down under him, it slid out from under him a unit a turn, dropped into "
                "the pit onto the socket and seated itself, and the colours went round. "
                "Staged: the valve written into the last slot as a pick-up leaves it "
                "(#R$BD6B), and him put 8 above the block to land on it; the rest is the "
                "game."),
    "chamber": ("A chamber activated", [100],
                "The activation, inside the valve's update (#R$AF79): sixteen passes over "
                "the whole attribute file, each adding one to every cell's ink -- twice "
                "round the eight colours, black among them -- each with a sparkle's sound "
                "(#R$B5EE) and a pause; then the room's ink is made white in its record "
                "for the rest of the game, the screen and the panel are coloured again "
                "(#R$A749), and CHAMBERS goes up by one and is printed; the twenty-fourth "
                "ends the game (#R$B761). All of it is one turn of the game, over a second "
                "long: the picture cuts it at the end of each pass (the DEC D at $B026), "
                "each piece shown as long as it took. The objects are not redrawn until "
                "the turn's end, so the valve and the panel's box change only in the last "
                "picture. The whole screen, from the same run as the one before."),
    "lift": ("A lift", [47],
             "#R$B31F, graphic 47, in room $23. It stays where it is until the robot lands "
             "on it -- the collision code marks what he lands on (bit 3 of +D) -- and then "
             "goes up -- a unit a turn with him on it (measured) -- until it "
             "passes LIFT_TOP, which the first lift in the room sets to its own Z plus 48; "
             "then it comes down a unit a turn, and from the floor it starts up again. "
             "A note pitched by its height every turn it moves. Pentagram's "
             'lift (<a href="../pentagram/Animations.html#lift">its animations</a>) keeps '
             "its state in +17 and stops at a fixed 176."),
    "bobbers": ("Bobbing blocks", [31],
                "The lift's routine entered at its second part, BOBBER (in #R$B31F), for "
                "graphic 31: always moving, whether ridden or not, down a unit a turn and "
                "up two, the top being LIFT_TOP, which the first bobbing block in the room "
                "sets to its own Z. Here room $36's two, half a cycle apart."),
    "conveyor": ("A ring of conveyors", [68, 69, 70, 71],
                 "Graphics 68-71 (#R$B267, #R$B27A, #R$B280, #R$B286) never move: each "
                 "turn they give themselves a step of two units, +V, +U, -V or -U, and "
                 "what lands on one takes that step (the collision code gives a thing "
                 "landing on another the other's U and V steps where it has none of its "
                 "own), and a beep sounds (#R$B6BB). Room $0D's are laid in a ring round a "
                 "spike; he was dropped on the first piece and stood still, and was carried "
                 "round. Pentagram's conveyors push every other turn from a table "
                 '(<a href="../pentagram/Animations.html#conveyor">its animations</a>).'),
    "dropping": ("A dropping block", [44],
                 "#R$B2B6, graphic 44, in room $12. Each turn the robot (or another mover of "
                 "graphics 16 to 47) stands on it, it sinks one unit, with a "
                 "grinding note pitched by its height, until it lands on what is under it. "
                 "Knight Lore's dropping block."),
    "collapsing": ("A collapsing block", [45, 65],
                   "#R$B28C, graphic 45, in room $15. Landed on, it becomes graphic 64 and "
                   "is stepped on at once to 65 (#R$B3A4), which empties it the turn after "
                   "(#R$B3B0), and he falls to the floor. Building the room again brings it "
                   'back. Knight Lore\'s crumbling block goes in a frame of sparkle (<a '
                   'href="../knightlore/Animations.html#crumbling">its animations</a>).'),
    "shuttles": ("Shuttling blocks", [66, 67],
                 "#R$B224, graphic 66, and #R$B21C, graphic 67, the same along V: the block follows "
                 "the turn counter, whose low five bits folded at bit 4 go 0 to 15 and back "
                 "over 32 turns, stepping a unit a turn towards that place in a span of 16; "
                 "blocks in odd-numbered records add 16 first, so they run half a cycle out "
                 "of step with the others. A note pitched by U (or V) every turn. Knight Lore's "
                 "shuttle_block. Here room $61's two, high up."),
    "remote": ("A remote-controlled robot breaks a fragile thing", [124, 125, 126, 127, 129, 54, 55],
               "The rooms with fragile things (#R$A9B1, graphic 129: deadly both ways, and "
               "it breaks as soon as anything moves it) have a robot (#R$A9C7) that the "
               "player drives from a pad (#R$AA4D) and four buttons (#R$AA63) by standing "
               "on them: each button, by its graphic and its mirror bit, orders the robot "
               "in control two units a turn one way (#R$AA43), and the pad holds it still. "
               "The robot is harmless and pushes what it walks into. Here room $D9: he was "
               "put on the mirrored button of graphic 122 (order 3, plus V), as landing on "
               "it would leave him, and stayed there; the robot walked into the fragile "
               "thing in its path, which went through the last two frames of the dying "
               "sparkle (54, 55) and was gone."),
    "mice": ("Clockwork mice", list(range(116, 120)),
             "#R$AAA1, graphics 116-119: deadly both ways. A mouse runs straight along U or "
             "V at two to five units a turn (the turn counter's low two bits plus two), "
             "flipping between two graphics, for a random count of turns up to 15; when "
             "it is stopped, is blocked or has run its count it beeps (#R$B6BB) and turns a "
             "quarter, left or right at random, with a new speed and count. Here room "
             "$4D's two, with him standing where they did not reach him in this run."),
    "chaser": ("A chaser", list(range(76, 80)),
               "#R$B19C, graphics 76-79: a crackle of sparks that heads for the robot at "
               "four units a turn in U and in V (#R$B165), runs through its four frames "
               "every turn and sounds a note pitched by its position. Nothing makes it "
               "deadly: it shoves him about like anything else that moves. Here room $9C's, "
               "coming at him and pushing him until both were stopped."),
    "slow-chaser": ("A homing thing", [120, 121],
                    "#R$AA89, graphics 120 and 121: deadly both ways; one unit a turn "
                    "towards him in U and in V (#R$B165), falling, flipping between its "
                    "two graphics, with a warble (#R$B690). Here room $5E's, with him "
                    "standing still in the corner furthest from it, until it reached him."),
    "wanderer": ("A wanderer", [94, 95, 11],
                 "#R$B06B, graphics 94 and 95 over graphic 11 (#R$B055): a creature of two "
                 "records that walks two units a turn one of four ways and, when stopped, "
                 "thuds (#R$B619) and turns a quarter, left or right by the random number. "
                 "The two halves are one box while it moves (#R$B1FA, #R$B20B); the lower "
                 "half is put back under the upper after. Deadly both ways. Here room $89's."),
    "pacer": ("A pacer", [86, 87, 11],
              "#R$B110, graphics 86 and 87 over graphic 11: two units a turn along one "
              "axis, and when stopped it turns round with a thud and walks back. Deadly "
              "both ways. Here room $A6's."),
    "leapers": ("Leapers", [130],
                "#R$A8F9, graphic 130: deadly both ways. One at a time (LEAPING, $5B43), "
                "on one turn in four by the random number, a leaper jumps: two units a turn "
                "up to 48 above where it stood, or until something stops it, and then falls "
                "back, with a note pitched by its height each turn it is in the air. Here "
                "room $97's two rows of four."),
    "ceiling": ("Things dropping from the ceiling", [73],
                "#R$AD13, graphic 73: deadly both ways; it hangs until DROP_LATCH is clear, "
                "no other is falling (DROPPING), and the random number is under 16 -- one "
                "turn in sixteen -- and then falls, a note pitched by its height every "
                "turn, and crashes when it lands (#R$AD54, #R$B676). The latch is set when "
                "an even-numbered room is entered (#R$CAA2) -- every room these hang in is "
                "even-numbered -- and cleared by picking something up or taking an extra "
                "life. Knight Lore's spiked ball. Here room $58's sixteen, with DROP_LATCH "
                "cleared by a poke, as a pick-up clears it, and him standing clear."),
    "clock": ("The light years", [],
              "#R$AD66, once a turn: the four digits in CLOCK each hold a count of rows "
              "still to roll in their low bits; the rolling ones roll a row a turn "
              "(#R$ADE5), and when the last digit has come to rest a light year is taken "
              "off (#R$ADC9), each digit that changes given a count of 7. Each digit is "
              "printed rows out of line by its count (#R$ADB0), so it rolls down into "
              "place like a mechanical counter's wheel. The digits are the font's "
              "(#R$6308), the last inverted. From the first turn of a game: 6000, which "
              "rolls all four digits."),
    "game-over": ("Game over", [80, 81, 82, 83, 88, 89, 90, 91],
                  "The last life lost: walking into the spike with no lives left, so that "
                  "#R$CA07 finds none to take, and #R$B761 ends the game -- the summary "
                  "(the chambers activated and not, the cryonauts lost, a rating from the "
                  "rooms seen), under the game-over tune (#R$B3F7) until a key, then about "
                  "fourteen seconds more or until a key; then the re-programming scene, run "
                  "by the main loop with GAME_OVER set and no wait between turns: sparks "
                  "over the robot's head (#R$ABF5), then a glove, a hammer and a hook "
                  "taking turns to strike it (#R$AB61), fifteen times, and the menu. No key "
                  "was pressed. The whole screen, a turn at a time in the scene and a "
                  "television frame at a time elsewhere."),
    "win": ("The win", [100, 85, 92, 93],
            "The twenty-fourth chamber, activated as above with CHAMBERS set to $23 "
            "beforehand, as the build's ending session sets it: the valve on the socket, "
            "the colours, and #R$B761 with WON set -- the arrival screen (#R$B8A9) under "
            "its tune, the summary as after a lost game but with a better rating, then the "
            "scene: the robot lowered into a can of oil and raised again, gleaming white "
            "(#R$A971, #R$A95A), the winning tune, and the menu. No key was pressed. The "
            "whole screen."),
    "menu": ("The menu", [],
             "#R$BA7E draws the menu (#R$BC25), plays its tune once, the first time it is "
             "shown after a game (#R$B4A1; any key stops it), and goes round a loop: keys "
             "1 to 4 set the control method and 5 toggles directional control, each with "
             "a beep, #R$BAFB setting FLASH on the chosen lines; 0 starts the game. Here "
             "2, 3, 4, 5 and 1 were pressed in turn."),
}

GROUPS = [
    ("The robot", ["walk-0", "walk-1", "walk-2", "walk-3", "turn", "jump", "dying"]),
    ("Valves and chambers", ["carrying", "sparkle", "seating", "chamber"]),
    ("Blocks that move", ["lift", "bobbers", "conveyor", "dropping", "collapsing",
                          "shuttles"]),
    ("The remote-controlled robots", ["remote"]),
    ("Creatures", ["mice", "chaser", "slow-chaser", "wanderer", "pacer", "leapers",
                   "ceiling"]),
    ("The panel", ["clock"]),
    ("The end of a game, and the menu", ["game-over", "win", "menu"]),
]

# Pictured at three times the Spectrum's size; the rest at twice, and the
# whole-screen ones at twice, as scenes.
SPRITE_SIZED = {"walk-0", "walk-1", "walk-2", "walk-3", "turn", "jump", "dying",
                "collapsing", "seating", "clock", "sparkle"}
WHOLE = {"chamber", "game-over", "win", "menu", "carrying"}

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
    return ", ".join(parts) + f"; {len(frames)} frames, {total:.1f} s in all"


def _sprite_links(memory, graphics) -> str:
    parts = []
    for graphic in graphics:
        sprite = _word(memory, GRAPHICS + 2 * graphic)
        parts.append(f"{graphic} (#R${sprite:04X})")
    return ", ".join(parts)


# Each run made once per snapshot and kept: alien8_sounds records most of
# its effects from these same runs, and the build calls both modules in one
# process.
_RUNS: dict = {}


def run(snapshot: Path, make, *args):
    """make(snapshot, *args), made once per snapshot and kept."""
    key = (str(snapshot), make.__name__, args)
    if key not in _RUNS:
        _RUNS[key] = make(snapshot, *args)
    return _RUNS[key]


MAKERS = (turning, jumping, dying, carrying, socket_sparkle, chamber, lift, bobbers,
          conveyor, dropping, collapsing, shuttles, remote, mice, chaser, slow_chaser,
          wanderer, pacer, leapers, ceiling, clock, game_over, win, menu)


def animations(snapshot: Path, log=print) -> dict[str, dict]:
    made = {}
    for facing in range(4):
        made[f"walk-{facing}"] = run(snapshot, walking, facing)
    for make in MAKERS:
        log(f"  {make.__name__}")
        result = run(snapshot, make)
        for anim in result if isinstance(result, list) else [result]:
            made[anim["key"]] = anim
    return made


def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    """Write the GIFs into html_dir/images/animations and return the
    Animations section."""
    out_dir = html_dir / "images" / "animations"
    out_dir.mkdir(parents=True, exist_ok=True)
    log("Running Alien 8's animations in the game's own code...")
    made = animations(snapshot, log)
    memory = ba.game_memory(snapshot)
    entries = skool_entries()
    lines = ['<div class="kl-list">',
             "<p>Alien 8's objects have no frame numbers. An object's graphic -- the "
             "first byte of its 32-byte record -- chooses both the routine that runs it "
             "every turn, through #R$A7EA, and the sprite it is drawn with, through "
             "#R$7827, so a thing animates by changing its own graphic: the legs step "
             "the low two bits of theirs, a turn puts them in a part-way view for two "
             "turns, a death's sparkle counts from 48 to 55, a socket's sparkle round "
             "108 to 111. It is Knight Lore's scheme, and Pentagram's (see "
             '<a href="../knightlore/Animations.html">Knight Lore\'s animations</a> and '
             '<a href="../pentagram/Animations.html">Pentagram\'s</a>); what is animated '
             "is Alien 8's.</p>",
             "<p>Each animation below was made by running the game in SkoolKit's "
             "simulator when these pages were built: started from the menu, put into the "
             "room wanted by the game's own restart (the room, the spot and the facing "
             "written into the start records at #R$CA1D, and his death begun as #R$B39A "
             "begins it), and then run a turn at a time -- every object's routine, the "
             "depth-sorted drawing, the copy to the screen, the wait that evens out the "
             "pace -- with each picture read off the screen as the turn left it. Where "
             "more than that was staged, the animation says what. Each frame is shown "
             "for as long as the game took over its turn, counted in T-states in the "
             "simulator at 3.5MHz; the simulator has none of a real Spectrum's memory "
             "contention, so the game runs a little faster here than on the machine. A "
             "frame drawn the same as the one before is merged into it. A quiet room's "
             "turn is about 35 ms: the game waits out the time a turn with little to draw "
             "does not use (#R$A6C0), but cannot give back what a busy one overruns, so "
             "busy rooms run slower. The screens after a game and the menu have no turns: "
             "they were read once a television frame (69,888 T-states), with FLASH shown "
             "as the ULA shows it.</p>",
             "<p>Under each: the graphics shown with their sprites, what was measured "
             "in the run, and the frames of the picture with what they show and how long "
             "each lasts.</p>"]
    for heading, keys in GROUPS:
        lines.append(f"<h3>{_esc(heading)}</h3>")
        for key in keys:
            anim = made[key]
            title, graphics, words = TEXT[key]
            frames = anim["frames"]
            save_gif(out_dir / f"{key}.gif", frames)
            width, height = frames[0][0].size
            scale = 3 if key in SPRITE_SIZED else 2
            css = "kl-sprite" if key in SPRITE_SIZED else "kl-piece"
            if key in WHOLE:
                css = "kl-scene"
            lines += [f'<div class="kl-item" id="{key}">',
                      f"<h4>{_esc(title)}</h4>",
                      f'<img class="{css}" src="images/animations/{key}.gif" '
                      f'alt="{_esc(title)}" width="{width * scale}" height="{height * scale}">',
                      f"<p>{link(words, entries)}</p>"]
            if graphics:
                lines.append(f"<p>Graphics and their sprites: "
                             f"{link(_sprite_links(memory, graphics), entries)}.</p>")
            lines += [f"<p>{link(_esc_measure(_measure(key, anim)), entries)}</p>",
                      f"<p>In the picture: {_esc(_order(frames))}.</p>",
                      "</div>"]
    lines.append("</div>")
    body = "\n".join(lines)
    for line in body.splitlines():
        if line.startswith((";", "[")):
            raise RuntimeError(f"a section line starts with {line[0]!r}: {line[:40]}")
    return {"Animations": body}


def _esc_measure(text: str) -> str:
    """A measurement's text for the page: its own characters escaped."""
    return _esc(text)
