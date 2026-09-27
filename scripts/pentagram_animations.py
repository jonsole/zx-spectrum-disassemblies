"""Pentagram's animations, as GIFs of the game running its own code.

build_pentagram.py --html calls build(), which writes the GIFs into the HTML
directory and returns the Animations section. Nothing here is committed
output: every frame is the game's own drawing.

Pentagram has no animation frames as such, any more than Knight Lore has: an
object's graphic number -- byte 0 of its 32-byte record -- picks both its
update routine (through the table at $AE2F) and its sprite (through $6DD7),
so an object animates by changing its own graphic. The player's legs step
the low two bits of theirs, a puff counts from 64 to 71, a crumbling block
from 136 to 139, a homer cycles four by a counter.

The frames are not put together from the sprites. Each animation is the game
running in SkoolKit's simulator, from the snapshot at $5E00, started the way
the build's sessions start it (build_pentagram.Machine: the menu, a control
key, 0) and put into the room wanted by the game's own restart: the room and
where he stands go into the player template at $C3FF, the killed bit is set,
and the game puts him back there a life later ($C2EC), as it does after
every death. The rooms are picked for a clear view of the thing shown (see
each function); where a scene is staged beyond that -- a collectable moved,
the killed bit set with nothing near him -- the function says so, and so
does the page. Then the game is run a turn at a time -- a turn being one pass
of the main loop from MAIN_LOOP ($AFDA) back to it: every object's update,
the depth-sorted drawing into the buffer, the changed rectangles copied to
the screen, the wait that evens the pace, the turn's sound -- and each frame
of a GIF is the screen as that turn left it, read from screen memory. So the
player is put together by the game from his two records, each thing is
drawn in the order and at the offsets its own routine sets, and what one
frame shows next to the next is exactly what the game drew.

Each frame is shown for as long as the game took over its turn, counted in
T-states in the simulator at 3.5MHz. The simulator has no memory contention,
so the game runs a little faster here than on a real Spectrum, where the ULA
holds up writes to the screen; a frame drawn identically to the one before
is merged into it. Where there is no turn -- the menu, the win and game-over
screens -- the screen is read once a television frame (69,888 T-states) and
identical frames merged, and FLASH is shown as the ULA shows it, swapping
ink and paper every 16 television frames.
"""
from __future__ import annotations

import html
import re
from pathlib import Path

import build_pentagram as bp

SKOOL = bp.OUT_DIR / "pentagram.skool"
TSTATES_PER_SECOND = 3_500_000
T_STATES_PER_MS = 3500
TV_FRAME = 69_888                 # T-states in a 48K Spectrum's frame
FLASH_FRAMES = 16                 # the ULA swaps FLASH cells every 16 frames

# The game (see the entries).
MAIN_LOOP = 0xAFDA                # where each turn begins
PLAYER = bp.PLAYER                # record 0, the legs; the body is record 1
RECORD_SIZE = 32
RECORD_COUNT = 54
OBJECTS_END = PLAYER + RECORD_SIZE * RECORD_COUNT
TEMPLATE = 0xC3FF                 # the player as he came into the room
TEMPLATE_BODY = TEMPLATE + RECORD_SIZE
LIVES = bp.LIVES
DROP_TIMER = bp.DROP_TIMER
DROP_BAN = 0xA742
TURNS = bp.TURN
BUCKET_OUT = bp.BUCKET_OUT
PENTAGRAM_ON = bp.PENTAGRAM_ON
QUEST_DONE = bp.QUEST_DONE
PLACED = bp.PLACED
PLAYER_ROOM = bp.PLAYER_ROOM
KILLED = 0x40                     # +$0D bit 6
MIRRORED = 0x40                   # +$07 bit 6
GRAPHICS = 0x6DD7                 # graphic number -> sprite

# The screen and what a frame keeps.
VARIABLES = bp.CONTROL            # the game's variables, up to the object records
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

TURN_LIMIT = 20 * TSTATES_PER_SECOND   # a turn longer than this is a hang


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
            self.speaker = 0            # $AF87's first OUT leaves it off
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

    def __init__(self, memory, start: int, end: int, edges: list[int], turn: int = -1):
        self.screen_bytes = bytes(memory[SCREEN:SCREEN_END])
        self.variables = bytes(memory[VARIABLES:PLAYER])
        self.control = memory[bp.CONTROL]
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

    def has_flash(self) -> bool:
        return any(attr & 0x80 for attr in self.screen_bytes[0x1800:])

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
    """Pentagram on a simulated 48K Spectrum, from the snapshot at $5E00:
    build_pentagram's Machine, with a tracer that also logs the speaker."""

    def __init__(self, snapshot: Path):
        from skoolkit.simutils import T

        self.machine = bp.Machine(snapshot)
        self.tracer = _tracer_class()(self.machine.simulator)
        self.machine.tracer = self.tracer
        self.machine.simulator.set_tracer(self.tracer)
        self.sim = self.machine.simulator
        self.memory = self.sim.memory
        self.T = T

    @property
    def now(self) -> int:
        return self.sim.registers[self.T]

    def play(self, steps, label: str = "animation") -> None:
        """Steps as build_pentagram's sessions take them."""
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
        behind -- won, or over -- the turn is run a television frame at a
        time, and if the test comes true before the turn ends, the frame
        returned is what there is so far, marked `left`, and the machine is
        left where it got to, within a television frame of the moment."""
        from skoolkit.simutils import PC

        if self.machine.pc != MAIN_LOOP:
            self.to_turn()
        start = self.now
        first = len(self.tracer.edges)
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
        frame = Frame(self.memory, start, self.now, edges, _word(self.memory, TURNS))
        frame.left = left
        return frame

    def turns(self, count: int, each=None) -> list[Frame]:
        frames = []
        for _ in range(count):
            if each is not None:
                each(self)
            frames.append(self.turn())
        return frames

    def sample(self, tstates: int) -> Frame:
        """Run for `tstates` whatever the game is doing, and take the screen
        as it is then: for the screens that have no turns."""
        from skoolkit.simutils import PC

        start = self.now
        first = len(self.tracer.edges)
        self.sim.trace(self.machine.pc, 0, 0, start + tstates, True, None, None,
                       None, None, None)
        self.machine.pc = self.sim.registers[PC]
        edges = [t - start for t in self.tracer.edges[first:]]
        return Frame(self.memory, start, self.now, edges)

    # -- staging -----------------------------------------------------------

    def start_game(self, choice: str = "1") -> None:
        """From the snapshot through the menu into the first room, as the
        build's sessions start (keyboard by default)."""
        self.play(bp._start(choice))
        self.to_turn()

    def playing(self) -> bool:
        return bp._playing(self.memory)

    def enter(self, room: int, u: int = 128, v: int = 128, facing: int = 2,
              z: int = 128, settle: int = 3) -> list[Frame]:
        """Put the player into `room`, standing at U, V, Z and facing
        `facing` (0 lower U, 1 higher U, 2 higher V, 3 lower V; #R$C5BD), by
        the game's own restart: the player template (#R$C3FF) is set as a
        doorway would have left it, but without the walk in, and the killed
        bit ends this life. Five lives are put back first. Returns the turns
        from the killing to `settle` turns after he is standing in the new
        room."""
        self.poke(LIVES, 5)
        graphic = 32 + (4 if facing in (1, 3) else 0) + 2      # standing, frame 2
        flags = self.peek(TEMPLATE + 7) & ~MIRRORED
        if facing in (0, 1):
            flags |= MIRRORED
        self.poke(TEMPLATE, [graphic, u, v, z])
        self.poke(TEMPLATE + 7, flags)
        self.poke(TEMPLATE + 8, room)
        self.poke(TEMPLATE + 0x0C, 0)                       # no walk in
        self.poke(TEMPLATE_BODY + 8, room)
        self.poke(PLAYER + 0x0D, self.peek(PLAYER + 0x0D) | KILLED)
        frames = []
        for _ in range(60):
            frames.append(self.turn())
            if self.peek(PLAYER_ROOM) == room and self.playing() and frames[-1].record(0)[0]:
                break
        else:
            raise RuntimeError(f"the restart into room {room} never came")
        self.poke(LIVES, 5)
        frames += self.turns(settle)
        return frames

    def no_drops(self) -> None:
        """Nothing from the sky in this room (DROP_BAN, as #R$CB89 sets it for
        rooms with the well or a quest thing)."""
        self.poke(DROP_BAN, 1)

    def find(self, graphics) -> int:
        """The first record index whose graphic is in `graphics`."""
        for index in range(RECORD_COUNT):
            if self.peek(PLAYER + RECORD_SIZE * index) in graphics:
                return index
        raise ValueError(f"no record of graphics {sorted(graphics)}")

    def record_address(self, index: int) -> int:
        return PLAYER + RECORD_SIZE * index


# --------------------------------------------------------------------------
# Cropping and saving.
# --------------------------------------------------------------------------

def drawn_box(record: bytes):
    """Where the drawing code last put this record's picture, as a box of
    screen pixels (left, top, right, bottom): +$1A is the pixel x and +$1B the
    bottom row counted up from the bottom of the screen (#R$B2C5), and +$18
    and +$19 the width in bytes and the rows drawn (#R$B3E7), from the byte
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
    (#R$B2C5), as a screen pixel counted from the top."""
    u, v = record[1], record[2]
    z = record[3] if z is None else z
    px = (u + v - 128) & 0xFF
    py = ((((v - u + 128) & 0xFF) >> 1) + z - 104) & 0xFF
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

EMPTY_ROOM = 30        # trees round the walls and nothing else in it
LEGS, BODY = 0, 1
BOLT = 2               # the first bolt record, BOLTS
FLYERS = (4, 5)        # FLYERS and FLYER_SECOND
WALK_KEY, JUMP_KEY, FIRE_KEY, TAKE_KEY = "a", "q", "w", "1"
# Where every walk starts: the middle of the room, well away from the trees
# along its walls, since a cycle is four turns and twelve units.
WALK_FROM = (128, 128)


def started(snapshot: Path) -> Game:
    game = Game(snapshot)
    game.start_game()
    return game


def walking(snapshot: Path, facing: int) -> dict:
    """One cycle of the walk, facing each way: walk held from standing, and
    the first four turns whose legs go through frames 0, 1, 2, 3."""
    game = started(snapshot)
    game.enter(EMPTY_ROOM, *WALK_FROM, facing=facing)
    game.no_drops()
    game.hold([WALK_KEY])
    frames = []
    for _ in range(24):
        frames.append(game.turn())
        cycle = frames[-4:]
        if len(cycle) == 4 and [f.record(LEGS)[0] & 3 for f in cycle] == [0, 1, 2, 3]:
            return animation(f"walk-{facing}", cycle, [LEGS, BODY], anchor_record=LEGS)
    raise RuntimeError("no clean walk cycle")


def jumping(snapshot: Path) -> dict:
    """A standing jump with the jump key held until he lands."""
    game = started(snapshot)
    game.enter(EMPTY_ROOM, 128, 128, facing=3)
    game.no_drops()
    frames = [game.turn()]
    game.hold([JUMP_KEY])
    for _ in range(40):
        frames.append(game.turn())
        record = frames[-1].record(LEGS)
        if len(frames) > 2 and not record[0x0C] & 0x08:
            break                      # bit 3 of +$0C: the jump is over
    game.hold()
    frames += game.turns(2)
    return animation("jump", frames, [LEGS, BODY], anchor_record=LEGS, fixed_z=True,
                     labels=labelled(frames, LEGS, "Z"))


def firing(snapshot: Path) -> dict:
    """A bolt fired towards a wall, and its puff when it bumps into it."""
    game = started(snapshot)
    game.enter(EMPTY_ROOM, 150, 128, facing=0)
    game.no_drops()
    frames = [game.turn()]
    game.hold([FIRE_KEY])
    frames.append(game.turn())
    game.hold()
    for _ in range(40):
        frames.append(game.turn())
        if frames[-1].record(BOLT)[0] == 0:
            break
    return animation("fire", frames, [LEGS, BODY, BOLT],
                     labels=[label if label.split()[0] != "0" else "-"
                             for label in labelled(frames, BOLT, "U")])


def _stand_on(game: Game, room: int, graphics, safe=(128, 128), drop: int = 8) -> int:
    """Into `room` twice: once to find the thing of one of `graphics`, then
    again standing on top of it -- `drop` units above, so that he lands on it
    in the first turns. Returns the thing's record index."""
    game.enter(room, *safe)
    thing = game.find(graphics)
    record = game.record_address(thing)
    u, v, z, height = (game.peek(record + 1), game.peek(record + 2), game.peek(record + 3),
                       game.peek(record + 6))
    game.enter(room, u, v, facing=2, z=z + height + drop, settle=0)
    game.no_drops()
    # The first turn in a room redraws the whole screen; the pictures start
    # after it.
    game.turn()
    return game.find(graphics)


def lift(snapshot: Path) -> dict:
    """Room 94's lift (graphic 84), in the middle of a cross of spikes, with
    him standing on it: one cycle, from the turn it sets off upwards to the
    turn it is back at rest on the floor."""
    game = started(snapshot)
    thing = _stand_on(game, 94, {84})
    frames = game.turns(90)
    heights = [f.record(thing)[3] for f in frames]
    up = next(i for i in range(1, len(heights)) if heights[i] > heights[i - 1])
    top = heights.index(max(heights), up)
    down = next(i for i in range(top, len(heights)) if heights[i] == heights[up - 1])
    frames = frames[up - 2:down + 2]
    return animation("lift", frames, [LEGS, BODY, thing], labels=labelled(frames, thing, "Z"))


def conveyor(snapshot: Path) -> dict:
    """Room 129's conveyor (graphic 140), carrying him along U until he drops
    off its end."""
    game = started(snapshot)
    thing = _stand_on(game, 129, {140})
    frames = []
    for _ in range(40):
        frames.append(game.turn())
        record = frames[-1].record(LEGS)
        if len(frames) > 4 and record[3] == 128:
            break                      # on the floor
    frames += game.turns(3)
    return animation("conveyor", frames, [LEGS, BODY, thing],
                     labels=labelled(frames, LEGS, "UZ", graphic=False))


def crumbling(snapshot: Path) -> dict:
    """A crumbling block in room 64, with him landing on it, until he is on
    the floor."""
    game = started(snapshot)
    thing = _stand_on(game, 64, {136})
    frames = []
    for _ in range(40):
        frames.append(game.turn())
        if frames[-1].record(thing)[0] == 0:
            break
    for _ in range(20):
        frames.append(game.turn())
        if frames[-1].record(LEGS)[3] == 128:
            break
    frames += game.turns(2)
    return animation("crumbling", frames, [LEGS, BODY, thing], label_records=[thing])


def sinking(snapshot: Path) -> dict:
    """Room 146's sinking block (graphic 78), with him standing on it."""
    game = started(snapshot)
    thing = _stand_on(game, 146, {78})
    frames = []
    for _ in range(80):
        frames.append(game.turn())
        if len(frames) > 6 and frames[-1].record(thing)[3] == frames[-4].record(thing)[3]:
            break                      # it has stopped
    frames += game.turns(2)
    return animation("sinking", frames, [LEGS, BODY, thing], labels=labelled(frames, thing, "Z"))


def _watch(snapshot: Path, key: str, room: int, graphics, where=(128, 128), facing=2,
           turns: int = 64, count: int = 2) -> dict:
    """Things of `graphics` in `room` going about their business, with him
    standing out of their way."""
    game = started(snapshot)
    game.enter(room, *where, facing=facing)
    game.no_drops()
    things = [i for i in range(RECORD_COUNT)
              if game.peek(game.record_address(i)) in graphics][:count]
    frames = []
    for _ in range(turns):
        game.poke(LIVES, 5)
        frames.append(game.turn())
    fields = {"pacers": "UV", "deadly-pacers": "V", "spider": "UV"}[key]
    labels = [", ".join(labelled([frame], thing, fields)[0] for thing in things)
              for frame in frames]
    return animation(key, frames, things, labels=labels)


def bobbing(snapshot: Path) -> dict:
    """Room 88's two deadly heads (graphic 86): each falls to the floor and
    rises to 176, over and over. From one landing to the next."""
    def landings(frames):
        heights = [f.record(first)[3] for f in frames]
        return [i for i in range(1, len(heights) - 1)
                if heights[i] <= heights[i - 1] and heights[i] < heights[i + 1]]
    game = started(snapshot)
    game.enter(88, 128, 96, facing=2)
    game.no_drops()
    things = [i for i in range(RECORD_COUNT) if game.peek(game.record_address(i)) == 86]
    first = things[0]
    frames = []
    for _ in range(260):
        frames.append(game.turn())
        if len(landings(frames)) >= 2:
            break
    lows = landings(frames)
    frames = frames[lows[0]:lows[1]]
    return animation("bobbing", frames, things, labels=labelled(frames, first, "Z"))


def pacers(snapshot: Path) -> dict:
    """Room 2's two pacers, graphic 87 along U and 88 along V."""
    return _watch(snapshot, "pacers", 2, {87, 88}, where=(160, 160), turns=72)


def deadly_pacers(snapshot: Path) -> dict:
    """Room 6's two deadly heads that pace along V (graphic 93)."""
    return _watch(snapshot, "deadly-pacers", 6, {93}, where=(80, 128), turns=56)


def spider(snapshot: Path) -> dict:
    """Room 9's spider among its blocks."""
    return _watch(snapshot, "spider", 9, {89}, where=(176, 176), turns=40, count=1)


# Where he stands while things fall. With him standing still the random
# number's low bits can settle into a cycle that never gives #R$CBAB its
# chance, so several spots are tried, each after more and more idle turns.
SKY_SPOTS = [(100, 160), (160, 100), (100, 100), (160, 160)]
SKY_KINDS = {48: range(48, 52), 160: range(160, 164), 164: range(164, 168),
             80: range(80, 82), 168: range(168, 172)}


def from_the_sky(snapshot: Path, kind: int) -> dict:
    """Something of `kind` falling from the sky into room 30: DROP_TIMER set
    to 1 every turn (so a drop is tried every turn, with #R$CBAB's one chance
    in four) until one comes, the game begun again each time until the
    random graphic is the one wanted. From the turn it appears until 30 turns
    after it lands, or until his death is over."""
    wanted = SKY_KINDS[kind]
    for attempt in range(160):
        game = started(snapshot)
        game.enter(EMPTY_ROOM, *SKY_SPOTS[attempt % len(SKY_SPOTS)], facing=3)
        game.turns(attempt // len(SKY_SPOTS))
        flyer = None
        for _ in range(60):
            game.poke(DROP_TIMER, 1)
            frame = game.turn()
            flyer = next((i for i in FLYERS if frame.record(i)[0]), None)
            if flyer is not None:
                break
        if flyer is None or frame.record(flyer)[0] not in wanted:
            continue
        game.no_drops()
        frames = [frame]
        landed = None
        for _ in range(90):
            game.poke(LIVES, 5)
            frames.append(game.turn())
            record = frames[-1].record(flyer)
            if landed is None and record[0x0C] & 0x04:
                landed = len(frames)
            if landed is not None and len(frames) >= landed + 30:
                break
            if frames[-1].record(LEGS)[0] == 0 or not record[0]:
                break                  # his death is over, or it has gone
        return animation(f"sky-{kind}", frames, [LEGS, BODY, flyer],
                         labels=labelled(frames, flyer, "Z"))
    raise RuntimeError(f"nothing of graphic {kind} fell")


WELL_ROOM = bp.WELL_ROOM       # 71: the well inside a ring of spikes
SHOT_WELL_ROOM = 123           # a well behind a pool of flat spikes
SHOT_WELL_FROM = (88, 100)     # in front of the pool, the well straight ahead
QUEST_RECORDS = bp.QUEST_RECORDS
QUEST_SIZE = bp.QUEST_SIZE
BUCKET = bp.BUCKET
CARRIED_LAST = bp.CARRIED + 12


def _fire_until(game: Game, test, turns: int) -> list[Frame]:
    """Fire every other turn -- fire is taken once a press (#R$C126) -- until
    test(memory)."""
    frames = []
    for number in range(turns):
        game.poke(LIVES, 5)
        game.hold([FIRE_KEY] if number % 2 == 0 else [])
        frames.append(game.turn())
        if test(game.memory):
            break
    else:
        raise RuntimeError("the well never gave a bucket")
    game.hold()
    return frames


def well(snapshot: Path) -> dict:
    """Room 123's well shot at from across the pool of flat spikes in front of
    it -- a bolt flies at a height of 132, over things one unit high -- until
    it gives the bucket, and the bucket falling. The last 24 turns of the
    shooting, and on until the bucket has landed. (Room 71's well, which the
    build's sessions use, is ringed by spikes as tall as he is, which hide
    him wherever he can shoot from.)"""
    game = started(snapshot)
    game.enter(SHOT_WELL_ROOM, *SHOT_WELL_FROM, facing=2)
    well_record = game.find({120})
    frames = _fire_until(game, lambda memory: memory[BUCKET_OUT], 400)
    bucket = game.find({BUCKET})
    for _ in range(60):
        frames.append(game.turn())
        if frames[-1].record(bucket)[0x0C] & 0x04:
            break
    frames += game.turns(4)
    start = max(0, next(i for i, f in enumerate(frames) if f.record(bucket)[0] == BUCKET) - 24)
    frames = frames[start:]
    labels = [f"count {f.record(well_record)[0x14]}" for f in frames]
    return animation("well", frames, [LEGS, BODY, well_record, BOLT, BOLT + 1, bucket],
                     labels=labels,
                     label_records=[BOLT, BOLT + 1, bucket])


def _bucket_carried(game: Game) -> None:
    """The build's own steps to a bucket (build_pentagram._quest_item, up to
    the bucket carried and next to be put down)."""
    game.play(bp._go(WELL_ROOM) + [
        ([], 1.0), bp._place(*bp.WELL_SPOT), ([], 0.5),
        bp.Repeat("a bucket from the well", bp.VOLLEY, lambda memory: memory[BUCKET_OUT], 8),
        ([], 2.0), bp._beside_bucket, ([], 0.5),
        bp.Repeat("the bucket carried, next to put down", bp.PRESS,
                  lambda memory: memory[CARRIED_LAST] == BUCKET, 6)])
    game.to_turn()


def _put_down_by(game: Game, item: int, keep: bool) -> list[Frame]:
    """Into the room of quest item `item` (0-3), standing 24 units from it in
    U, and the bucket put down: then until the item is done and the puff has
    gone."""
    record = QUEST_RECORDS + QUEST_SIZE * item
    u, v, room = game.peek(record + 1), game.peek(record + 2), game.peek(record + 8)
    game.enter(room, u + 24 if u < 128 else u - 24, v, facing=0 if u < 128 else 1)
    done = game.peek(QUEST_DONE)
    frames = []
    for number in range(80):
        game.poke(LIVES, 5)
        game.hold([TAKE_KEY] if number == 0 else [])
        frames.append(game.turn())
        if game.peek(QUEST_DONE) > done:
            break
    else:
        raise RuntimeError(f"quest item {item} was not done")
    frames += game.turns(10)
    return frames if keep else []


def quest(snapshot: Path) -> list[dict]:
    """The quest played through in one game, as the build's quest session
    plays it: room 82 before; a bucket carried to each of the four quest
    items (the first one's flight kept); room 82 after, with the pentagram;
    then the five collectables put into room 82 short of their places, and
    their glide on to the win, the game-over screen and the menu."""
    game = started(snapshot)
    out = []
    before = game.enter(82, 128, 100, facing=2)[-1]
    for item in range(4):
        _bucket_carried(game)
        frames = _put_down_by(game, item, keep=item == 0)
        if frames:
            bucket = next(i for i in range(RECORD_COUNT) if frames[0].record(i)[0] == BUCKET)
            thing = next(i for i in range(RECORD_COUNT) if frames[0].record(i)[0] in range(112, 116))
            labels = [f"{a} {b}" for a, b in zip(labelled(frames, bucket, "Z"),
                                                 labelled(frames, thing, ""))]
            out.append(animation("bucket", frames, [LEGS, BODY, bucket, thing],
                                 labels=labels))
    if not game.peek(PENTAGRAM_ON):
        raise RuntimeError("the four quest items did not bring the pentagram")
    after = game.enter(82, 128, 100, facing=2)[-1]
    # Not an animation the game plays -- the pieces are simply there when the
    # room is next built (#R$B097) -- so the two are shown a second and a
    # half each.
    out.append({"key": "pentagram",
                "frames": [(f.screen(), COMPARISON_MS, label, f.tstates)
                           for f, label in ((before, "before"), (after, "after"))],
                "turns": [before, after]})
    bp._collectables_in_room_82(game.memory)
    game.enter(82, 128, 100, facing=2, settle=0)
    frames = []
    for _ in range(60):
        game.poke(LIVES, 5)
        frames.append(game.turn(leaves=lambda memory: memory[PLACED] >= 5))
        if frames[-1].left:
            break
    else:
        raise RuntimeError("the fifth collectable never reached its place")
    frames += _until_menu(game)
    out.append(animation("win", frames, [], box=WHOLE_SCREEN,
                         labels=_phases(frames, lambda f: f"{f.variable(PLACED)} placed")))
    return out


WHOLE_SCREEN = (0, 0, 256, 192)


def _phases(frames: list[Frame], turn_label) -> list[str]:
    """What each frame of an ending shows: a turn (labelled by turn_label),
    or the screen the game is on, by the colour it filled the screen with."""
    labels = []
    for frame in frames:
        if frame.turn >= 0:
            labels.append(turn_label(frame))
        else:
            labels.append(SCREEN_COLOURS.get(frame.screen_bytes[0x1800], "changing"))
    return labels


# The attribute each screen is filled with (#R$C302 and #R$AF87), read from
# the top left-hand cell, which the border covers.
SCREEN_COLOURS = {0x45: "the win", 0x46: "game over", 0x43: "the menu"}


COMPARISON_MS = 1500


def _until_menu(game: Game, after: float = 1.0) -> list[Frame]:
    """A television frame at a time until the menu is up, and `after`
    seconds of it."""
    frames = []
    at_menu = None
    for _ in range(40 * 50):
        frames.append(game.sample(TV_FRAME))
        if at_menu is None and bp._at_menu(game.memory) and game.peek(0xA734):
            at_menu = game.now
        if at_menu is not None and game.now - at_menu >= after * TSTATES_PER_SECOND:
            return frames
    raise RuntimeError("the menu never came")


def dying(snapshot: Path) -> dict:
    """He is killed standing in room 30 -- the killed bit set, as the
    collision code sets it when he touches something deadly -- and the game
    puts him back for the next life: from the turn before to the fourth turn
    of the new life."""
    game = started(snapshot)
    game.enter(EMPTY_ROOM, 128, 128, facing=3)
    game.no_drops()
    frames = [game.turn()]
    game.poke(PLAYER + 0x0D, game.peek(PLAYER + 0x0D) | KILLED)
    for _ in range(30):
        frames.append(game.turn())
        if frames[-1].record(LEGS)[0] in range(32, 40):
            break
    frames += game.turns(3)
    return animation("dying", frames, [LEGS, BODY])


def game_over(snapshot: Path) -> dict:
    """The last life lost: as dying(), with no lives left, so that the game
    goes to the game-over screen (#R$C2EC) and then back to the menu."""
    game = started(snapshot)
    game.enter(EMPTY_ROOM, 128, 128, facing=3)
    game.no_drops()
    game.poke(LIVES, 0)
    frames = [game.turn()]
    game.poke(PLAYER + 0x0D, game.peek(PLAYER + 0x0D) | KILLED)
    for _ in range(30):
        frames.append(game.turn(leaves=lambda memory: memory[LIVES] == 0xFF))
        if frames[-1].left:
            break
    else:
        raise RuntimeError("the game did not end")
    frames += _until_menu(game)
    return animation("game-over", frames, [], box=WHOLE_SCREEN,
                     labels=_phases(frames, lambda f: graphics_label(f, [LEGS, BODY])))


MENU_KEYS = ["2", "3", "4", "1"]     # a control method each, then back
MENU_WAIT = 1.2                      # seconds between them


def menu(snapshot: Path) -> dict:
    """The menu as the game starts: shown, with its tune, and 2, 3, 4 and 1
    pressed in turn (each 0.2 seconds, and MENU_WAIT apart), the flash
    moving to the method chosen. Read once a television frame."""
    game = Game(snapshot)
    frames = []
    while not game.peek(0xA734):
        game.sample(TV_FRAME)             # up to the menu's first showing
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
    """Which control method's line is flashing: bits 1-2 of CONTROL."""
    return f"method {((frame.control >> 1) & 3) + 1}"


# --------------------------------------------------------------------------
# What each animation shows, measured from the frames that made it.
# --------------------------------------------------------------------------

def _signed(value: int) -> int:
    return value - 256 if value > 127 else value


def _index_of(frames: list[Frame], graphics) -> int | None:
    for frame in frames:
        for index in range(RECORD_COUNT):
            if frame.record(index)[0] in graphics:
                return index
    return None


def _range_text(values) -> str:
    values = list(values)
    return f"{min(values)} to {max(values)}" if min(values) != max(values) else f"{values[0]}"


def _turn_times(frames: list[Frame]) -> str:
    times = [f.tstates for f in frames]
    return f"{min(times):,} to {max(times):,} T-states" if min(times) != max(times) \
        else f"{times[0]:,} T-states"


def _measure_walk(frames, facing) -> str:
    first, last = frames[0].record(LEGS), frames[-1].record(LEGS)
    du, dv = _signed((last[1] - first[1]) & 0xFF), _signed((last[2] - first[2]) & 0xFF)
    axis = f"U {du:+d}" if du else f"V {dv:+d}"
    return (f"Measured: legs {', '.join(str(f.record(LEGS)[0]) for f in frames)}, body "
            f"{', '.join(str(f.record(BODY)[0]) for f in frames)}; from the first frame "
            f"to the last he moved {axis} (three units a turn, #R$C68D), the turns taking "
            f"{_turn_times(frames)}.")


def _measure_jump(frames) -> str:
    heights = [f.record(LEGS)[3] for f in frames]
    top = max(heights)
    return (f"Measured: the legs' Z turn by turn was {', '.join(str(z) for z in heights)} "
            f"-- up {top - heights[0]} and down again in {len(frames) - 1} turns, rising "
            "by 7, 6, 5 ... (8 less a gravity of 1 a turn with jump held) and falling by "
            "1, 3, 5 ... (2 a turn); the jump also carries him forward three units a turn, "
            "the way he faces.")


def _measure_fire(frames) -> str:
    bolt = [f.record(BOLT) for f in frames]
    flying = [r[1] for r in bolt if r[0] in (149, 150, 151)]
    puffs = [r[0] for r in bolt if 64 <= r[0] <= 71]
    return (f"Measured: the bolt's U turn by turn, {', '.join(str(u) for u in flying)} -- "
            f"eight a turn from 16 in front of him, at Z {bolt[1][3]} -- then the puff, "
            f"graphics {', '.join(str(g) for g in puffs)}, one a turn where it bumped the "
            "wall; then the record is empty.")


def _measure_sky(frames, key) -> str:
    flyer = next(i for i in FLYERS if frames[0].record(i)[0])
    heights = [f.record(flyer)[3] for f in frames]
    died = any(64 <= f.record(LEGS)[0] <= 71 for f in frames)
    lowest = min(heights)
    down = heights.index(lowest)
    text = (f"Measured: it appeared at U {frames[0].record(flyer)[1]}, V "
            f"{frames[0].record(flyer)[2]}, Z {heights[0]} (#R$CC11's 216, less the "
            f"first turn's fall)")
    text += "; its Z turn by turn " + ", ".join(str(z) for z in heights[:14]) + " ..."
    text += f", down to {lowest} on turn {down}"
    text += "; graphics " + ", ".join(sorted({str(f.record(flyer)[0]) for f in frames}))
    text += "."
    on_him = [n for n, f in enumerate(frames) if _on_him(f, flyer)]
    if died:
        text += " It reached him, and his death is in the picture too."
    elif on_him:
        text += (f" On turn {on_him[0]} it came down on top of him -- at Z "
                 f"{heights[on_him[0]]}, his legs' Z plus their height, overlapping him "
                 f"in U and V -- for {len(on_him)} turn{'s' if len(on_him) > 1 else ''}, "
                 "doing him no harm.")
    return text


def _on_him(frame: Frame, index: int) -> bool:
    """Whether the record sits on the player's legs: its Z at the top of
    theirs, and overlapping them in U and V."""
    legs, thing = frame.record(LEGS), frame.record(index)
    return (thing[3] == legs[3] + legs[6]
            and abs(thing[1] - legs[1]) < thing[4] + legs[4]
            and abs(thing[2] - legs[2]) < thing[5] + legs[5])


def _measure_lift(frames) -> str:
    lift = _index_of(frames, {84})
    heights = [f.record(lift)[3] for f in frames]
    top = heights.index(max(heights))
    rises = sum(1 for a, b in zip(heights, heights[1:top + 1]) if b > a)
    return (f"Measured: the lift's Z went from {heights[0]} to {max(heights)} one unit a "
            f"turn over {rises} turns, with his legs 12 above it, and back to "
            f"{heights[-1]} in {len(heights) - 1 - top} turns: "
            + ", ".join(str(z) for z in heights[top:]) + " on the way down.")


def _measure_conveyor(frames) -> str:
    us = [f.record(LEGS)[1] for f in frames]
    zs = [f.record(LEGS)[3] for f in frames]
    return (f"Measured: his U turn by turn, {', '.join(str(u) for u in us)} -- two units "
            f"every other turn, the turns the turn counter is odd -- and his Z "
            f"{zs[0]} to {zs[-1]} as he dropped off its end.")


def _measure_crumbling(frames) -> str:
    block = _index_of(frames, {136})
    return (f"Measured: the block's graphic turn by turn, "
            f"{', '.join(str(f.record(block)[0]) for f in frames)}; his legs' Z "
            f"{', '.join(str(f.record(LEGS)[3]) for f in frames)}.")


def _measure_sinking(frames) -> str:
    block = _index_of(frames, {78})
    heights = [f.record(block)[3] for f in frames]
    moving = sum(1 for a, b in zip(heights, heights[1:]) if b < a)
    return (f"Measured: the block's Z went from {heights[0]} to {heights[-1]}, one unit a "
            f"turn for {moving} turns, with him on top, and stopped on the floor.")


def _measure_bobbing(frames) -> str:
    head = _index_of(frames, {86})
    heights = [f.record(head)[3] for f in frames]
    top = heights.index(max(heights))
    return (f"Measured: Z from {heights[0]} up to {max(heights)} in {top} turns, one a "
            f"turn -- the first turn up too: the step of 2 that #R$CE31 sets on landing "
            f"is overwritten with 1 before it moves -- and down one a turn to {heights[-1]} in "
            f"{len(heights) - 1 - top}; the two heads move together.")


def _measure_pacers(frames, graphics) -> str:
    parts = []
    for graphic in sorted(graphics):
        index = _index_of(frames, {graphic})
        if index is None:
            continue
        us = [f.record(index)[1] for f in frames]
        vs = [f.record(index)[2] for f in frames]
        axis, values = ("U", us) if max(us) != min(us) else ("V", vs)
        parts.append(f"graphic {graphic} along {axis}, {min(values)} to {max(values)}")
    return (f"Measured: {'; '.join(parts)}, two units a turn and turning at each end; "
            f"{len(frames)} turns of {_turn_times(frames)}.")


def _measure_spider(frames) -> str:
    spider = _index_of(frames, {89})
    steps = {(_signed((b.record(spider)[1] - a.record(spider)[1]) & 0xFF),
              _signed((b.record(spider)[2] - a.record(spider)[2]) & 0xFF))
             for a, b in zip(frames, frames[1:])}
    return ("Measured: its steps from turn to turn were "
            + ", ".join(f"({u:+d}, {v:+d})" for u, v in sorted(steps))
            + " in U and V -- four and four when nothing is in the way, less where the "
            "collision code cuts a step short.")


def _measure_well(frames) -> str:
    well = _index_of(frames, {120})
    counts = [f.record(well)[0x14] for f in frames]
    bucket = next(n for n, f in enumerate(frames) if any(f.record(i)[0] == BUCKET
                                                         for i in range(RECORD_COUNT)))
    return (f"Measured: the well's count (+14) over these turns, "
            f"{', '.join(str(c) for c in counts[:bucket + 1])}: one more on every turn a "
            f"bolt, or the first bolt record's puff, touched it; on the 32nd the bucket "
            f"appeared, turn {bucket + 1} of the picture, and the count went back to 0.")


def _measure_bucket(frames) -> str:
    bucket = _index_of(frames, {BUCKET})
    item = _index_of(frames, set(range(112, 116)))
    with_bucket = [f for f in frames if f.record(bucket)[0] == BUCKET]
    heights = [f.record(bucket)[3] for f in with_bucket]
    slid = sum(1 for a, b in zip(with_bucket, with_bucket[1:])
               if b.record(bucket)[3] == a.record(bucket)[3]
               and b.record(bucket)[1] != a.record(bucket)[1])
    rose = sum(1 for a, b in zip(heights, heights[1:]) if b > a)
    tune = max(frames, key=lambda f: f.tstates)
    return (f"Measured: put down under him (#R$BF79 lifts him onto it), the bucket first "
            f"slid {slid} turns towards the item along the floor, a unit a turn, "
            f"unable to rise with him on it; out from under him, it rose from Z "
            f"{heights[0]} to {max(heights)}, {rose} turns; the turn it arrived "
            f"took {tune.tstates / TSTATES_PER_SECOND:.2f} s, the quest-item tune "
            f"(#R$D847) played inside it; then the puff, and the item went from graphic "
            f"{frames[0].record(item)[0]} to {frames[-1].record(item)[0]}.")


def _measure_pentagram(frames) -> str:
    counts = [sum(1 for i in range(RECORD_COUNT) if 128 <= f.record(i)[0] <= 135)
              for f in frames]
    return (f"Measured: pieces of the pentagram (graphics 128-135) among the room's "
            f"records, {counts[0]} before and {counts[1]} after.")


def _screens(frames) -> str:
    """The long holds of an ending: each screen and how long it stayed."""
    holds = [(ms, label) for _, ms, label, _ in frames
             if label in SCREEN_COLOURS.values() and ms >= 1000]
    names = {"the win": "the congratulations (under the winning tune)",
             "game over": "the game-over screen (under its tune, then the wait)",
             "the menu": "the menu"}
    return " and ".join(f"{names[label]} for {ms / 1000:.1f} s" for ms, label in holds)


def _measure_win(animation_) -> str:
    frames = animation_["turns"]
    turns = [f for f in frames if f.turn >= 0 and not f.left]
    placed = [f.variable(PLACED) for f in turns]
    last = next(f for f in frames if f.left)
    together = max(placed) == 0 and last.variable(PLACED) == 5
    return (f"Measured: {len(turns)} whole turns of the glide with PLACED at "
            f"{_range_text(placed)}, and in the next "
            + ("all five reached their places together, PLACED going to 5, and the game "
               "left the turn for #R$C302" if together else
               f"PLACED reached {last.variable(PLACED)}")
            + f"; then {_screens(animation_['frames'])}, and the menu.")


def _measure_dying(frames) -> str:
    graphics = [f"{f.record(LEGS)[0]}+{f.record(BODY)[0]}" for f in frames]
    return ("Measured: legs and body turn by turn, " + ", ".join(graphics)
            + ". The long frame near the end is the turn in which the room is built "
            "again and the next, which copies the whole of it to the screen.")


def _measure_game_over(animation_) -> str:
    return (f"Measured: {_screens(animation_['frames'])} -- the wait is 64 times 8192 "
            "turns of a 26 T-state loop, #R$C302, about 3.9 s -- before the menu.")


def _measure_menu(animation_) -> str:
    return ("Measured: the FLASH cells swap every 16 television frames (320 ms), which "
            "is the ULA's doing, not the game's; the game moves the flash to the line of "
            "the key pressed (bits 1-2 of CONTROL) on its next pass.")


# The words for each animation: title, the graphics it shows (linked to their
# sprites), and what drives it. #R links only where an entry starts.
TEXT = {
    "walk-0": ("Walking, facing 0 (lower U)", list(range(32, 36)) + list(range(40, 44)),
               "The legs' routine, #R$C440, steps the low two bits of their graphic every "
               "turn walk is held (#R$C58D) -- four frames, of which frame 2 is also the "
               "standing pose -- and #R$C5D3 then makes the body the legs' graphic plus 8, "
               "12 units above them from behind and 8 from the front. The facing is two "
               "bits (#R$C5BD): the mirror bit, and bit 2 of the graphic, which picks the "
               "view from behind (32-35) or the front (36-39). Facing 0 is from behind, "
               "mirrored: up and to the left on the screen. Knight Lore's walk is six "
               'frames (<a href="../knightlore/Animations.html#sabreman-a">its '
               "animations</a>); this one is four."),
    "walk-1": ("Walking, facing 1 (higher U)", list(range(36, 40)) + list(range(44, 48)),
               "The same cycle seen from the front, mirrored: down and to the right."),
    "walk-2": ("Walking, facing 2 (higher V)", list(range(32, 36)) + list(range(40, 44)),
               "From behind, not mirrored: up and to the right."),
    "walk-3": ("Walking, facing 3 (lower V)", list(range(36, 40)) + list(range(44, 48)),
               "From the front, not mirrored: down and to the left."),
    "jump": ("Jumping", list(range(36, 40)),
             "#R$C56C starts a jump when he is standing on something: a Z step of 8, which "
             "#R$C61D's gravity takes down again, one a turn while jump is held and he is "
             "still rising, two otherwise. The legs keep stepping through their four "
             "frames all the way, and a jump always carries him forward. Here jump was "
             "held from standing until he landed; the picture stays over his place on the "
             "floor, so the rise is seen."),
    "fire": ("Firing a bolt, and its puff", [150, 151, 149] + list(range(64, 72)),
             "#R$C126 takes one of the two bolt records on a new press of fire and "
             "starts it 16 units in front of him and 4 up, eight units a turn the way he "
             "faces (#R$C1BD). #R$C1C5 steps its graphic down through 150, 149, 151 and "
             "round, and holds it at a "
             "height of 132; when the collision code cuts its move short in U or V it "
             "becomes a puff (#R$C107): #R$C111 steps the graphic 64 to 70 a turn at a "
             "time, with a burst of noise each, and #R$C11D makes 71 graphic 1, which the "
             "drawing code rubs out. The puff is Knight Lore's sparkle put to more uses: "
             "every bolt that hits a wall, every thing shot down, the bucket, and the "
             "player himself when he dies."),
    "sky-48": ("From the sky: a homer (48-51)", [48, 49, 50, 51],
               "#R$CBAB, once a turn: when DROP_TIMER has run out, one chance in four of "
               "a drop into one of the two records kept for them, from #R$CC11 at a "
               "height of 216 and a random U and V, as one of the eight graphics at "
               "#R$CC09. Rooms with the well, a quest item or a piece of the pentagram "
               "never get one (#R$CB89). Graphics 48-51 are a homer (#R$CC4B): it falls, "
               "and flies at him, each of its speeds gaining three sixteenths of a unit a "
               "turn towards him, and turns round when it bumps into anything; its "
               "graphic is a count in +10 of four frames. A homer is not deadly: "
               "#R$CC4B never calls #R$C291 and #R$CC11 leaves +D clear, so all it "
               "does is get in his way."),
    "sky-160": ("From the sky: a homer (160-163)", [160, 161, 162, 163],
                "The same routine, #R$CC4B, with other sprites: the four frames of "
                "160-163."),
    "sky-164": ("From the sky: a homer (164-167)", [164, 165, 166, 167],
                "And 164-167, the third homer #R$CC09 can drop."),
    "sky-80": ("From the sky: a runner (80, 81)", [80, 81],
               "Graphics 80 and 81 enter the spiders' routine #R$D1F5 past its flip: "
               "deadly, falling ever faster (its steps are never cleared) but never below "
               "a height of 129, running straight at four units a turn and taking a new "
               "way when the collision code stops it -- along U if it bumped in V, and "
               "the other way round. Bit 0 of the graphic and the mirror bit make four "
               "facings from two pictures."),
    "sky-168": ("From the sky: a walker (168-171)", [168, 169, 170, 171],
                "#R$D251: as the runner, but its picture changes every turn between the "
                "two graphics of a pair, a two-frame walk, and bit 1 goes with the way "
                "it runs."),
    "lift": ("A lift", [84],
             "#R$CDBB, graphic 84, in room 94. At rest it waits for him: when he lands on "
             "it the collision code marks it (bit 7 of +17, #R$B890) and it starts up, "
             "asking for two units a turn and giving him a Z step of three -- it only "
             "rises while it keeps bumping into what is on it, so it climbs one unit a "
             "turn under him. At 176 it stops and sends him down with a Z step of -2; "
             "falling onto it, he pushes it down faster and faster, and at the floor it "
             "is at rest, and as he is standing on it, off it goes again."),
    "conveyor": ("A conveyor", [140],
                 "Graphics 140-143 look like a plain block. What stands on one is carried "
                 "by the collision code (#R$B866): on every other turn, the first time "
                 "anything lands on it that turn, the step from #R$D30A for its graphic "
                 "is added -- +2 in U for 140, as here in room 129 -- and its own routine "
                 "(#R$D2DE) only clears the once-a-turn bit again. Room 37's conveyors, "
                 "by their places in its record, point at rows of spikes."),
    "crumbling": ("A crumbling block", [136, 137, 138, 139],
                  "#R$D2AD, graphics 136-139, in room 64. Each turn he stands on it -- "
                  "bit 7 of +17, set by the collision code when he or the heavy block "
                  "lands (#R$B890), and bit 3 of +D -- it steps one graphic on, and after "
                  "139 it becomes graphic 1 and is rubbed out. He falls to the floor. "
                  "Knight Lore's crumbling block goes in a frame of sparkle "
                  '(<a href="../knightlore/Animations.html#crumbling">its animations</a>); '
                  "this one takes four turns to go."),
    "sinking": ("A sinking block", [78],
                "#R$CDA0, graphic 78, in room 146. With him on it, whatever Z step the "
                "collision code passes it becomes -1, so it sinks one unit a turn and "
                "takes him down with it, until it reaches the floor."),
    "bobbing": ("Bobbing heads", [86],
                "Graphic 86 (#R$CE9A) is made deadly and goes on into #R$CE31: falling one "
                "unit a turn until it lands, then rising a unit a turn to 176, then "
                "falling again -- for ever, with nobody near. Here room 88's two heads, "
                "which start together and stay together, from one landing to the next."),
    "pacers": ("Pacers", [87, 88],
               "Graphic 87 (PACER_U, in #R$CEA0) moves two units a turn along U and 88 "
               "(PACER_V, in #R$CEDA) along V, turning round whenever they bump into "
               "something (bit 0 of +10 keeps the way). In room 2 they are platforms high "
               "among the blocks, and he can ride them: a pacer passes its step to what "
               "stands on it."),
    "deadly-pacers": ("Deadly pacers", [93],
                      "Graphics 92 and 93 are the same pacers made deadly first "
                      "(#R$CEA0, #R$CEDA), with a head's sprite. Room 6's two pace along "
                      "V, out of step."),
    "spider": ("A spider", [89],
               "#R$CF22, graphic 89: deadly, falling, and turned over every other turn, "
               "which is its scuttle; it moves diagonally four units a turn in U and V and "
               "picks a new diagonal at random (bit 3 of RANDOM and of R) whenever it "
               "bumps into something. Room 9's is penned in by blocks."),
    "well": ("The well shot at, and the bucket", [120, 90, 150, 151, 149, 64],
             "#R$CFD2, the well (graphic 120), counts in +14 the turns a bolt touches it "
             "(#R$CFB2: within two units, the first bolt record's puff counting too, the "
             "second's not). On the 32nd, if no bucket is out, it copies its own record "
             "into a free one as the bucket, graphic 90, at the well's U and 8 further "
             "in V, 141 up: on top of the well. The count is in the well's own record, "
             "so the 32 must come in one visit to the room. Here room 123's well, shot "
             "at from across the pool of flat spikes in front of it (a bolt flies at a "
             "height of 132, over things one unit high)."),
    "bucket": ("The bucket flies to a quest item", [90, 112, 116],
               "Put down in a room with a quest item not yet done, the bucket "
               "(#R$D0AC) finds it and from then on rises a unit a turn to 176 while "
               "#R$D085 steers it over the item. When it can move no more it tells the "
               "item (bit 0 of +16), plays the quest-item tune with the game standing "
               "still, and turns into a puff. The item (#R$CF68) then becomes its "
               "finished form, graphic + 4 in its record and its quest record "
               "(#R$CF9E), and a life is added. Here quest item 0, graphic 112, in room "
               "122, with the bucket put down 24 units from it."),
    "pentagram": ("The pentagram appears", list(range(128, 136)),
                  "Not an animation the game plays. When the fourth quest item is done, "
                  "#R$D13A sets PENTAGRAM_ON, and from then on #R$B097 lets the eight "
                  "pieces of the pentagram, 128-135, into room 82 when it is built; "
                  "before, they are kept out. Room 82 as it was built before the first "
                  "quest item and after the fourth, in the same game, each shown for "
                  "a second and a half."),
    "win": ("The win", [144, 145, 146, 147, 148, 152, 156],
            "In room 82 with the pentagram there, a collectable (#R$CD16) glides a unit "
            "a turn in U and V towards its own place from #R$D562 without falling; there "
            "it becomes graphic + 8, a still thing, and PLACED counts it. The fifth ends "
            "the game with a jump to #R$C302: the congratulations, the winning tune, the "
            "game-over screen with the percentage (#R$C6EA), its tune, a wait, and the "
            "menu. For this picture the five were put into room 82, each 16 units short "
            "of its place with a clear way to it, as the build's quest session does; the "
            "rest is the game."),
    "dying": ("Dying, and the next life", list(range(64, 72)) + [38, 46],
              "Killed -- bit 6 of +D, which the collision code sets when he touches "
              "something deadly -- the legs mark the body too, and both become puffs "
              "(#R$C440, #R$C5D3, #R$C107). When both records are empty, #R$B00C starts "
              "the next life: #R$C2EC copies the player template, which holds him as he "
              "came into this room, over both records, and the room is built again. "
              "There is no materialising, as there is in "
              '<a href="../knightlore/Animations.html#materialising">Knight Lore</a>: he '
              "is simply there. Here the killed bit was set with nothing near him."),
    "game-over": ("Game over", list(range(64, 72)),
                  "The same death with no lives left: #R$C2EC finds none to take and goes "
                  "to the game-over screen (GAME_OVER, in #R$C302), and from there to the "
                  "menu. The picture is the whole screen, read once a television frame."),
    "menu": ("The menu", [],
             "#R$BB74 prints the menu once (#R$BCB4 draws the border and shows it), plays "
             "its tune the first time (#R$D69C, stopped by any key) and then goes round a "
             "loop: keys 1 to 4 set the control method, and #R$BBD8 sets FLASH on that "
             "method's line; 0 starts the game. Here 2, 3, 4 and 1 were pressed in turn."),
}

GROUPS = [
    ("Sabreman", ["walk-0", "walk-1", "walk-2", "walk-3", "jump", "fire"]),
    ("Things from the sky", ["sky-48", "sky-160", "sky-164", "sky-80", "sky-168"]),
    ("Blocks that move", ["lift", "conveyor", "crumbling", "sinking", "pacers"]),
    ("Monsters in the rooms", ["bobbing", "deadly-pacers", "spider"]),
    ("The quest", ["well", "bucket", "pentagram", "win"]),
    ("Death, the end and the menu", ["dying", "game-over", "menu"]),
]

# Pictured at three times the Spectrum's size; the rest at twice, and the
# whole-screen ones at their own size, doubled only by the page width.
SPRITE_SIZED = {"walk-0", "walk-1", "walk-2", "walk-3", "jump", "crumbling", "lift",
                "conveyor", "sinking", "dying"}
WHOLE = {"pentagram", "win", "game-over", "menu"}


def _measure(key: str, anim: dict) -> str:
    frames = anim["turns"]
    if key.startswith("walk-"):
        return _measure_walk(frames, int(key[-1]))
    if key.startswith("sky-"):
        return _measure_sky(frames, key)
    simple = {"jump": _measure_jump, "fire": _measure_fire, "lift": _measure_lift,
              "conveyor": _measure_conveyor, "crumbling": _measure_crumbling,
              "sinking": _measure_sinking, "bobbing": _measure_bobbing,
              "spider": _measure_spider, "well": _measure_well, "bucket": _measure_bucket,
              "pentagram": _measure_pentagram, "dying": _measure_dying}
    if key in simple:
        return simple[key](frames)
    if key == "pacers":
        return _measure_pacers(frames, {87, 88})
    if key == "deadly-pacers":
        return _measure_pacers(frames, {93})
    if key == "win":
        return _measure_win(anim)
    if key == "game-over":
        return _measure_game_over(anim)
    return _measure_menu(anim)


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


def animations(snapshot: Path, log=print) -> dict[str, dict]:
    made = {}
    for facing in range(4):
        made[f"walk-{facing}"] = walking(snapshot, facing)
    for make in (jumping, firing, lift, conveyor, crumbling, sinking, bobbing, pacers,
                 deadly_pacers, spider, well, dying, game_over, menu):
        log(f"  {make.__name__}")
        anim = make(snapshot)
        made[anim["key"]] = anim
    for kind in SKY_KINDS:
        made[f"sky-{kind}"] = from_the_sky(snapshot, kind)
    log("  the quest")
    for anim in quest(snapshot):
        made[anim["key"]] = anim
    return made


def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    """Write the GIFs into html_dir/images/animations and return the
    Animations section."""
    out_dir = html_dir / "images" / "animations"
    out_dir.mkdir(parents=True, exist_ok=True)
    log("Running Pentagram's animations in the game's own code...")
    made = animations(snapshot, log)
    memory = bp.game_memory(snapshot)
    entries = skool_entries()
    lines = ['<div class="kl-list">',
             "<p>Pentagram's objects have no frame numbers. An object's graphic -- the "
             "first byte of its 32-byte record -- chooses both the routine that runs it "
             "every turn, through #R$AE2F, and the sprite it is drawn with, through "
             "#R$6DD7, so a thing animates by changing its own graphic: the legs step "
             "the low two bits of theirs, a puff counts up from 64 to 71, a crumbling "
             "block from 136 to 139, a homer cycles four by a counter. It is Knight "
             "Lore's scheme (see "
             '<a href="../knightlore/Animations.html">Knight Lore\'s animations</a>); '
             "what is animated is Pentagram's.</p>",
             "<p>Each animation below was made by running the game in a simulator when "
             "these pages were built: started from the menu, put into the room wanted by "
             "the game's own restart (the room and his place written into the player "
             "template, and the killed bit set), and then run a turn at a time -- every "
             "object's routine, the depth-sorted drawing, the copy to the screen, the "
             "wait that evens out the pace -- with each picture read off the screen as "
             "the turn left it. Each frame is shown for as long as the game took over "
             "its turn, counted in T-states in the simulator, which has none of the "
             "memory contention of a real Spectrum, so the game runs a little faster "
             "here; a frame drawn the same as the one before is merged into it. A turn "
             "in a quiet room is about 45 ms; the game waits out the time a busy one "
             "does not use, but cannot give back what it overruns, so busy rooms run "
             "slower. The menu and the end screens have no turns: they were read once "
             "a television frame (69,888 T-states).</p>",
             "<p>Under each: the graphics shown with their sprites, what was measured "
             "in the run, and the frames of the picture with the graphics in them (or "
             "what they show) and how long each lasts.</p>"]
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
                scale, css = 2, "kl-scene"
            lines += [f'<div class="kl-item" id="{key}">',
                      f"<h4>{_esc(title)}</h4>",
                      f'<img class="{css}" src="images/animations/{key}.gif" '
                      f'alt="{_esc(title)}" width="{width * scale}" height="{height * scale}">',
                      f"<p>{link(words, entries)}</p>"]
            if graphics:
                lines.append(f"<p>Graphics and their sprites: "
                             f"{link(_sprite_links(memory, graphics), entries)}.</p>")
            lines += [f"<p>{link(_measure(key, anim), entries)}</p>",
                      f"<p>In the picture: {_esc(_order(frames))}.</p>",
                      "</div>"]
    lines.append("</div>")
    body = "\n".join(lines)
    for line in body.splitlines():
        if line.startswith((";", "[")):
            raise RuntimeError(f"a section line starts with {line[0]!r}: {line[:40]}")
    return {"Animations": body}
