"""Cyberun's animations, as GIFs of the game running its own code.

build_cyberun.py --html calls build(), which writes the GIFs into the HTML
directory (images/animations/) and returns the Animations section. Nothing
written is committed: every frame is the game's own drawing, made at build
time from the snapshot, and this module holds none of the game's bytes.

Two ways of running the game:

- Live. The game is started through the menu as the build's sessions start
  it (build_cyberun._start) and, where a scene needs somewhere else, a new
  life is put there by the game's own restart (build_cyberun.restart_at and
  new_life_at), with any add-ons or rocket parts poked at the same moment.
  Then it is run a pass at a time -- PLAY_LOOP ($F46C) to PLAY_LOOP, or the
  death sequence's loop at $F49E -- holding keys as a player would, and each
  frame is the screen as the pass left it. Cyberun is not frame-locked
  (interrupts are off and a pass takes as long as its work), so each frame
  is shown for as long as its pass took, in T-states at 3.5MHz.

- On its own. For the objects' animation cycles, the game's routines are
  called on one record a pass at a time on a cleared screen (harness(),
  cycle()): the same steps update_objects takes for an object -- a new
  sprite pair, the old image set up for rubbing out, then animate_object and
  place-draw-colour -- without the steering and moving. Those frames are
  shown for one pass each, the pass length being the median of the passes
  of the landscape-scrolling run.

Where a scene is staged beyond a restart (an attacker put in front of the
ship, the fuel set low, the damage undone), the function says so and so
does the page.
"""
from __future__ import annotations

import html
import re
from pathlib import Path

import build_cyberun as bc

SKOOL = bc.OUT_DIR / "cyberun.skool"
TSTATES_PER_SECOND = 3_500_000
T_STATES_PER_MS = 3500
TV_FRAME = 69_888                 # T-states in a 48K Spectrum's frame
FLASH_FRAMES = 16                 # the ULA swaps FLASH cells every 16 frames
PASS_LIMIT = 20 * TSTATES_PER_SECOND   # a pass longer than this is a hang

SCREEN = 0x4000
SCREEN_END = 0x5B00

# The Spectrum's colours, normal and BRIGHT, for the GIF palette.
SPECTRUM = [(0, 0, 0), (0, 0, 0xD7), (0xD7, 0, 0), (0xD7, 0, 0xD7),
            (0, 0xD7, 0), (0, 0xD7, 0xD7), (0xD7, 0xD7, 0), (0xD7, 0xD7, 0xD7)]
SPECTRUM_BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF),
                   (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0), (0xFF, 0xFF, 0xFF)]
PALETTE = SPECTRUM + SPECTRUM_BRIGHT
_FLAT_PALETTE = [c for colour in PALETTE for c in colour] + [0] * (768 - 3 * len(PALETTE))
_GIF_PALETTE = [c for colour in PALETTE for c in colour]


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


def screen_image(data: bytes, flash_inverted: bool = False):
    """6912 bytes of display file and attributes as the ULA shows them: a
    picture in PALETTE's indices, 256 by 192."""
    from PIL import Image

    table = _TRANSLATE[flash_inverted]
    out = bytearray(256 * 192)
    for y in range(192):
        row = ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
        attrs = 0x1800 + (y >> 3) * 32
        at = y * 256
        for column in range(32):
            out[at:at + 8] = _BITS[data[row + column]].translate(table[data[attrs + column]])
            at += 8
    image = Image.frombytes("P", (256, 192), bytes(out))
    image.putpalette(_FLAT_PALETTE)
    return image


class Frame:
    """What one pass (or one stretch of time) left: the screen, the whole of
    memory, and how long it took."""

    def __init__(self, memory, start: int, end: int, keys=()):
        self.memory = bytes(memory[:0x10000])
        self.start, self.end = start, end
        self.tstates = end - start
        self.keys = frozenset(keys)

    def __getitem__(self, address: int) -> int:
        return self.memory[address]

    def word(self, address: int) -> int:
        return _word(self.memory, address)

    def screen(self):
        inverted = bool((self.end // TV_FRAME // FLASH_FRAMES) & 1)
        return screen_image(self.memory[SCREEN:SCREEN_END], inverted)


class Game:
    """Cyberun on a simulated 48K Spectrum, from the snapshot at $5C80:
    build_cyberun's Machine (its tracer gives the game held keys and a
    Kempston stick), run a pass of the play loop at a time."""

    def __init__(self, snapshot: Path):
        from skoolkit.simutils import PC, T

        self.machine = bc.Machine(snapshot)
        self.sim = self.machine.simulator
        self.memory = self.sim.memory
        self.registers = self.sim.registers
        self.PC, self.T = PC, T

    @property
    def now(self) -> int:
        return self.registers[self.T]

    def play(self, steps, label: str = "animation") -> None:
        """Steps as build_cyberun's sessions take them."""
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
        self.machine.tracer.keys = set(keys)
        self.machine.tracer.kempston = stick

    def run_to(self, address: int, limit: int = PASS_LIMIT) -> None:
        """Run on until PC is `address` -- at least one instruction first, so
        that from `address` itself this is the next time round."""
        self.sim.trace(self.machine.pc, 0, 1, self.now + limit, True, None, None,
                       None, None, None)
        self.machine.pc = self.registers[self.PC]
        if self.machine.pc != address:
            self.sim.trace(self.machine.pc, address, 0, self.now + limit, True, None, None,
                           None, None, None)
            self.machine.pc = self.registers[self.PC]
        if self.machine.pc != address:
            raise RuntimeError(f"${address:04X} was not reached (PC ${self.machine.pc:04X})")

    def run_for(self, tstates: int, stop: int = 0) -> bool:
        """Run for `tstates`, or until PC reaches `stop`; True if it did."""
        self.sim.trace(self.machine.pc, stop, 0, self.now + tstates, True, None, None,
                       None, None, None)
        self.machine.pc = self.registers[self.PC]
        return bool(stop) and self.machine.pc == stop

    def pass_(self, keys=(), stop: int = bc.PLAY_LOOP, leaves=None) -> Frame:
        """One pass of the play loop, from PLAY_LOOP to PLAY_LOOP, holding
        `keys`. With `leaves`, a test of memory for the game having left the
        play loop (the level ended), the pass is run a television frame at a
        time, and if the test comes true first, the frame returned is the
        screen as it is then, marked `left`."""
        self.hold(keys)
        start = self.now
        if leaves is None:
            self.run_to(stop)
            return Frame(self.memory, start, self.now, keys)
        self.sim.trace(self.machine.pc, 0, 1, self.now + PASS_LIMIT, True, None, None,
                       None, None, None)
        self.machine.pc = self.registers[self.PC]
        left = False
        while self.machine.pc != stop:
            if leaves(self.memory):
                left = True
                break
            if self.now - start > PASS_LIMIT:
                raise RuntimeError(f"a pass did not end (PC ${self.machine.pc:04X})")
            self.run_for(TV_FRAME, stop)
        frame = Frame(self.memory, start, self.now, keys)
        frame.left = left
        return frame

    def passes(self, count: int, keys=(), each=None, stop: int = bc.PLAY_LOOP) -> list[Frame]:
        frames = []
        for _ in range(count):
            if each is not None:
                each(self)
            frames.append(self.pass_(keys, stop))
        return frames

    def call(self, address: int, limit: int = TSTATES_PER_SECOND, **registers) -> None:
        """Call a routine of the game on its own: registers set (by name, as
        skoolkit.simutils.REGISTERS has them, or IX / IY as words), a return
        address pushed, and the routine run until it returns there. The
        registers are put back afterwards, so a game stopped at the play loop
        goes on from there as if nothing had been called."""
        from skoolkit.simutils import REGISTERS, SP

        kept = list(self.registers[:self.T]) + [self.machine.pc]

        for name, value in registers.items():
            if name in ("IX", "IY", "HL", "DE", "BC"):
                high, low = {"IX": ("IXh", "IXl"), "IY": ("IYh", "IYl"), "HL": ("H", "L"),
                             "DE": ("D", "E"), "BC": ("B", "C")}[name]
                self.registers[REGISTERS[high]] = value >> 8
                self.registers[REGISTERS[low]] = value & 0xFF
            else:
                self.registers[REGISTERS[name]] = value
        sp = (self.registers[SP] - 2) & 0xFFFF
        self.memory[sp], self.memory[sp + 1] = RETURN & 0xFF, RETURN >> 8
        self.registers[SP] = sp
        self.registers[self.PC] = address
        self.machine.pc = address
        self.sim.trace(address, RETURN, 0, self.now + limit, True, None, None, None, None,
                       None)
        self.machine.pc = self.registers[self.PC]
        if self.machine.pc != RETURN:
            raise RuntimeError(f"${address:04X} did not return (PC ${self.machine.pc:04X})")
        for index, value in enumerate(kept[:-1]):
            if index != self.T:
                self.registers[index] = value
        self.registers[self.PC] = self.machine.pc = kept[-1]

    def screen_frame(self, start: int | None = None) -> Frame:
        return Frame(self.memory, self.now if start is None else start, self.now)


# A place in the ROM where nothing runs: the 48K ROM's spare bytes from
# $386E are all $FF, and the game never calls into the ROM (it runs with
# interrupts off and its own routines). A routine called by Game.call returns
# here, where the simulator stops.
RETURN = 0x386E


# --------------------------------------------------------------------------
# The game's variables the animations read and write (see the entries).
# --------------------------------------------------------------------------

PLAY_LOOP = bc.PLAY_LOOP          # play_2: once a pass of the play loop
DEATH_LOOP = 0xF49E               # the death sequence's loop, once a pass
MENU_LOOP = bc.MENU_LOOP          # menu_loop, once a pass of the menu
DYING = bc.DYING                  # death_count
HITS = bc.HITS
FUEL = bc.FUEL
PASS_COUNTER = 0x9A64             # pass_counter
OBJECTS = 0x9974                  # object_records: nine of 24 bytes
RECORD = 24
RECORDS = 9
SHIP = 0xC8E5                     # ship_record
SHIP_ACROSS = 0xC8FE              # ship_across_speed, high byte first
SHIP_CLIMB = 0xC900               # ship_down_speed, high byte first
SHIP_FACING = 0xC8FD              # bit 7 facing left
SHIP_SCREEN_Y = 0xC903            # the ship's bottom line on the screen
SHIP_HEIGHT = 0xC1A9
SHIP_LINE = 0x5C38                # the shots' line, 8 below the picture's top
STEER = 0x5C36                    # steer_push: $80 left, 3 right
TRAIL_FRAME = 0xC7BC              # trail_frame
SCROLL_DOWN = 0xCCBA              # this pass's steps, signed
SCROLL_ACROSS = 0xCCBB
VIEW_COLUMN, VIEW_ROW = 0xCE57, 0xCE58
VIEW_X, VIEW_Y = 0xCE45, 0xCE46
ORIGIN_X, ORIGIN_Y = 0xCE41, 0xCE42
RIGHT_COLUMN = 0xDDF7
SHOTS = 0xB37A                    # shot_records: four of 24 bytes
SIDE_JET = 0xC6C2                 # side_jet_record
LIFT_JET = 0xC78F                 # lift_jet_record
BEAM_STATE = 0x9BD6               # beam_state: pattern, colour, timer
FUEL_SHOWN = 0xCC62
GAUGE_COLOUR = 0xCBAD
POINTERS = (0x8708, 0x870B)       # the menu's pointer records: x, line, method
PART_CARRIED = bc.PART_CARRIED
PARTS_BUILT = bc.PARTS_BUILT
LAUNCH = bc.LAUNCH
ADDON_SLOTS = bc.ADDON_SLOTS

# The routines the animations call on their own.
CLEAR_SPRITE_PAIR = 0xA2EA
PREPARE_ERASE = 0xAD27
ANIMATE = 0x910A                  # animate_object
PLACE_DRAW = 0x951B               # place_draw: place, draw, colour (update_attacker's tail)
FREE_OBJECT = 0xAC34
COPY_POSITION = 0x898E
MOVE_OBJECT = 0xBF66
DISSOLVE_PLAY_AREA = 0x9EFE
DISSOLVE_SWEEP_END = 0x9F27       # the EX AF,AF' after each of its sixteen sweeps

# The tables the object animations read.
GRAPHIC_LISTS = 0xAF3D            # object_graphic_lists
WAVE_TABLE = 0x990A               # wave_table: type, flags, frame byte, range
ATTACKER_COLOURS = 0x9933
SHOT_KIND_FLAGS = 0x89A7          # one byte a kind of shot from kind 1
SHOT_TEMPLATES = 0x89AF           # four bytes a kind: offset, offset, frame byte, range
PART_PAIRS = 0xE10E               # object_part_pairs: frame byte, range
KIND_FLAGS = 0xE0FD               # object_kind_flags
KIND_COLOURS = 0xE205             # object_kind_bytes


def _signed(value: int) -> int:
    return value - 256 if value & 0x80 else value


def _pilot(target: int):
    """Keys for holding the ship near a height: thrust while the view is
    below `target` (page row * 256 + line in the page), as a player holds a
    height, nothing otherwise."""
    def keys(game):
        here = game.peek(VIEW_ROW) * 256 + game.peek(VIEW_Y)
        return ["a"] if here > target else []
    return keys


def _keep_alive(game) -> None:
    bc._keep_alive(game.memory)


def started(snapshot: Path) -> Game:
    """From the snapshot through the menu to the first pass of a game, on
    the keyboard, as the build's sessions start it."""
    game = Game(snapshot)
    game.play(bc._start(0))
    return game


def restarted(snapshot: Path, place, pokes: dict | None = None, sky: bool = True) -> Game:
    """A game whose second life starts at `place` (map column, row, the
    view's x and y in the cell), by the game's own restart
    (build_cyberun.restart_at), with `pokes` set at the same moment; run on
    to the first pass of that life."""
    game = Game(snapshot)
    game.play(bc._start(0) + bc.new_life_at(bc.restart_at(*place, sky=sky, pokes=pokes)))
    game.run_to(PLAY_LOOP)
    return game


def flown(game: Game, count: int, keys, each=None) -> list[Frame]:
    """`count` passes, with keys (a list, or a function of the game giving
    one) and an optional step before each."""
    frames = []
    for _ in range(count):
        if each is not None:
            each(game)
        held = keys(game) if callable(keys) else keys
        frames.append(game.pass_(held))
    return frames


# --------------------------------------------------------------------------
# Cropping, timing and saving.
# --------------------------------------------------------------------------

PLAY_AREA = (8, 24, 232, 184)     # x 8-$E7, lines $18-$B7


def ship_box(frame: Frame, left: int = 64, right: int = 176, above: int = 14,
             below: int = 6) -> tuple:
    """A box round the ship as it is in `frame`: x left to right, from
    `above` lines over the picture's top to `below` under its bottom."""
    top = frame[SHIP_SCREEN_Y] - frame[SHIP_HEIGHT] + 1 - above
    return left, max(24, top), right, min(184, frame[SHIP_SCREEN_Y] + 1 + below)


def crop(frames: list[Frame], box) -> list:
    return [frame.screen().crop(box) for frame in frames]


def drawn_box(frames: list[Frame], region=PLAY_AREA, margin: int = 2):
    """The smallest box inside `region` holding every pixel set in any of
    the screens, widened by `margin`: for pictures drawn on a cleared
    screen."""
    union = None
    for frame in frames:
        box = frame.screen().crop(region).getbbox()
        if box is None:
            continue
        box = (box[0] + region[0], box[1] + region[1], box[2] + region[0], box[3] + region[1])
        union = box if union is None else (min(union[0], box[0]), min(union[1], box[1]),
                                           max(union[2], box[2]), max(union[3], box[3]))
    if union is None:
        raise ValueError("nothing was drawn")
    return (max(0, union[0] - margin), max(0, union[1] - margin),
            min(256, union[2] + margin), min(192, union[3] + margin))


def duration(tstates: int) -> int:
    """A frame's time in milliseconds, to the 10ms a GIF can say."""
    return max(20, round(tstates / T_STATES_PER_MS / 10) * 10)


def merge(pictures: list, frames: list[Frame], labels: list[str]) -> list[tuple]:
    """(picture, milliseconds, label, tstates) per frame shown: identical
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
    """Frames (picture, milliseconds, ...) as a looping GIF in the
    Spectrum's colours."""
    images = [picture for picture, *_ in frames]
    for image in images:
        # Sixteen entries, not 256: a full palette is written with every
        # frame, and would be most of a small picture's bytes.
        image.putpalette(_GIF_PALETTE)
    images[0].save(path, save_all=True, append_images=images[1:], loop=0,
                   duration=[ms for _, ms, *_ in frames], disposal=1, optimize=False)


def animation(key: str, frames: list[Frame], box, labels: list[str], **extra) -> dict:
    out = {"key": key, "passes": frames, "box": box,
           "frames": merge(crop(frames, box), frames, labels)}
    out.update(extra)
    return out


# --------------------------------------------------------------------------
# The animations, live: the game played in the simulator, a pass at a time.
# --------------------------------------------------------------------------

def scroll(snapshot: Path) -> dict:
    """The landscape scrolling: the first life, flown left from where a game
    starts, up the hillside there, thrust held five passes in nine."""
    game = started(snapshot)
    count = [0]

    def keys(_):
        count[0] += 1
        return ["z"] + (["a"] if count[0] % 9 < 5 else [])
    flown(game, 4, keys, _keep_alive)
    frames = flown(game, 36, keys, _keep_alive)
    labels = [f"{abs(_signed(f[SCROLL_ACROSS]))} px" for f in frames]
    return animation("scroll", frames, PLAY_AREA, labels)


def _ship_labels(frames: list[Frame]) -> list[str]:
    out = []
    for f in frames:
        facing = "left" if f[SHIP_FACING] & 0x80 else "right"
        out.append(f"facing {facing}, trail {f[TRAIL_FRAME]}")
    return out


def trail(snapshot: Path) -> dict:
    """The trail bending with the speed: the first life, from standing on
    the ground where a game starts, right held for 20 passes and then
    nothing for 30, so the ship speeds up and the drag slows it again."""
    game = started(snapshot)
    frames = flown(game, 20, ["x"], _keep_alive) + flown(game, 30, [], _keep_alive)
    return animation("trail", frames, ship_box(frames[0], 72, 160), _ship_labels(frames))


def turning(snapshot: Path) -> dict:
    """The ship turning: right held for 20 passes, then left for 24."""
    game = started(snapshot)
    frames = flown(game, 20, ["x"], _keep_alive) + flown(game, 24, ["z"], _keep_alive)
    return animation("turning", frames[12:], ship_box(frames[0], 72, 160),
                     _ship_labels(frames[12:]))


# Where a game starts (start_position, $F3B7: map column $0D, row 7), as a
# restart over the ground: the place a ship is put when the scene wants the
# ground under it and a life that starts with add-ons fitted.
START_PLACE = (0x0D, 7, 0x90, 0x3B)
JETS = {ADDON_SLOTS + 3: 4, ADDON_SLOTS + 4: 5}


def _jet_labels(frames: list[Frame]) -> list[str]:
    out = []
    for f in frames:
        parts = []
        if f[LIFT_JET + 3] & 0x80:
            parts.append(f"lift jet ${f[LIFT_JET]:02X}" + (" mirrored" if f[LIFT_JET + 3] & 0x40
                                                          else ""))
        if f[SIDE_JET + 3] & 0x80:
            parts.append(f"side jet ${f[SIDE_JET]:02X}")
        out.append(", ".join(parts) or "no jet")
    return out


def jets(snapshot: Path) -> dict:
    """The side and lift jets: a life started where a game starts, over the
    ground, with add-ons 4 and 5 fitted by the restart; thrust held 14
    passes, nothing for 6, right for 14 and left for 14."""
    game = restarted(snapshot, START_PLACE, JETS, sky=False)
    frames = (flown(game, 14, ["a"], _keep_alive) + flown(game, 6, [], _keep_alive)
              + flown(game, 14, ["x"], _keep_alive) + flown(game, 14, ["z"], _keep_alive))
    box = ship_box(frames[0], 64, 176, 12, 0)
    box = box[:3] + (min(184, box[3] + 34),)
    return animation("jets", frames, box, _jet_labels(frames))


def _shot_labels(frames: list[Frame]) -> list[str]:
    """Each laser in flight: its length in cells and whether its head has
    stopped."""
    out = []
    for f in frames:
        parts = []
        for n in range(4):
            shot = SHOTS + RECORD * n
            if f[shot] != 0xFF and f[shot + 0x0B] and not f[shot + 0x16] & 0x80:
                state = "stopped" if f[shot + 0x10] & 0x80 else "growing"
                if f[shot + 0x10] & 0x40:
                    state = "tail catching up"
                parts.append(f"{_plural(f[shot + 0x0E], 'cell')}, {state}")
        out.append("; ".join(parts) or "none")
    return out


def laser(snapshot: Path) -> dict:
    """A laser shot: the first life, standing where a game starts, fire
    pressed for one pass; then the passes until it is gone."""
    game = started(snapshot)
    flown(game, 2, [], _keep_alive)
    frames = flown(game, 1, ["q"], _keep_alive) + flown(game, 15, [], _keep_alive)
    while frames[-1][SHOTS + 0x0B] == 0 and len(frames) > 2 and \
            frames[-2][SHOTS + 0x0B] == 0:
        frames.pop()
    box = ship_box(frames[0], 8, 232, 6, 4)
    return animation("laser", frames, box, _shot_labels(frames))


def _beam_labels(frames: list[Frame]) -> list[str]:
    out = []
    for f in frames:
        label = "none"
        for n in range(4):
            shot = SHOTS + RECORD * n
            if f[shot] != 0xFF and f[shot + 0x15] & 0x80 and f[shot + 0x0B]:
                label = f"{_plural(f[shot + 0x0E], 'cell')}, step {f[shot + 0x15] & 0x0F}"
        out.append(label)
    return out


def special_beam(snapshot: Path) -> dict:
    """The special beam: a life started over the ground where a game
    starts, with add-on 7 fitted by the restart; thrust for 12 passes to
    lift off, then the special key (1) held for 34 passes and let go. (On
    the ground the beam's probe meets the ground at once and the beam ends
    the pass it starts.)"""
    game = restarted(snapshot, START_PLACE, {ADDON_SLOTS + 6: 7}, sky=False)
    flown(game, 4, [], _keep_alive)
    frames = flown(game, 12, ["a"], _keep_alive) + flown(game, 34, ["1"], _keep_alive)
    frames += flown(game, 16, [], _keep_alive)
    while len(frames) > 2 and _beam_labels(frames[-2:]) == ["none", "none"]:
        frames.pop()
    while len(frames) > 2 and _beam_labels(frames[:2]) == ["none", "none"]:
        frames.pop(0)
    box = ship_box(frames[0], 8, 232, 6, 10)
    return animation("special-beam", frames, box, _beam_labels(frames))


def stage_object(game: Game, index: int, kind: int, dx: int, dy: int = 0,
                 colour: int = 0x77, wait: int = 60) -> int:
    """Put a sky object of wave-table kind `kind` in record `index`, `dx`
    pixels right of the ship and `dy` down, the way the game puts a thing at
    the ship (#R$8D29): the record cleared (#R$AC34), the ship's place copied
    in (#R$898E) and moved once by the offset (#R$BF66); then the kind's
    four bytes from the wave table, as #R$89D3 copies them, a colour, and a
    first wait of `wait` passes before its steering changes its course
    (#R$97DF). The other sky records are freed. Returns the record's
    address."""
    for n in range(RECORDS):
        game.poke(OBJECTS + RECORD * n, 0xFF)
    record = OBJECTS + RECORD * index
    game.call(FREE_OBJECT, IX=record)
    game.call(COPY_POSITION, IX=record, IY=SHIP)
    game.poke(record + 7, [dx & 0xFF, 0, dy & 0xFF, 0])
    game.call(MOVE_OBJECT, IX=record)
    game.poke(record + 7, [0, 0, 0, 0, 0, 0])
    game.poke(record + 0x0E, [0, 0])
    entry = WAVE_TABLE + 4 * kind
    game.poke(record, game.peek(entry))
    game.poke(record + 0x10, game.peek(entry + 1))
    game.poke(record + 0x13, [game.peek(entry + 2), game.peek(entry + 3)])
    game.poke(record + 0x0D, colour)
    game.poke(record + 0x15, [wait, 0, 0xF0])
    return record


def _record_labels(frames: list[Frame], record: int) -> list[str]:
    out = []
    for f in frames:
        kind = f[record]
        if kind == 0xFF:
            out.append("gone")
        elif f[record + 0x17] & 0x08:
            out.append(f"type ${kind:02X} dissolving, step {f[record + 0x17] & 7}")
        else:
            out.append(f"type ${kind:02X} frame {f[record + 0x13] & 0x0F}")
    return out


PILLAR = 3        # wave-table kind 3: type $18


def explosion(snapshot: Path) -> dict:
    """A shot attacker breaking up: the first life, standing where a game
    starts; a pillar (wave kind 3, type $18) staged 56 pixels ahead of the
    ship at its height (stage_object), and fire pressed for a pass."""
    game = started(snapshot)
    flown(game, 2, [], _keep_alive)
    record = stage_object(game, 0, PILLAR, 56, 0, 0xCC)
    frames = flown(game, 1, ["q"], _keep_alive)
    for _ in range(40):
        frames.append(game.pass_([]))
        _keep_alive(game)
        if frames[-1][record] == 0xFF:
            break
    bottom = frames[0][SHIP_SCREEN_Y]
    box = (80, 24, 232, min(184, bottom + 24))
    return animation("explosion", frames, box, _record_labels(frames, record))


def _missile_labels(frames: list[Frame], target: int) -> list[str]:
    out = []
    for f in frames:
        parts = []
        for n in range(4):
            shot = SHOTS + RECORD * n
            if f[shot] == 0 and f[shot + 0x16] & 0x80:
                aim = f[shot + 0x17] >> 4
                parts.append("missile, " + ("no target" if aim == 0x0F else f"target record {aim}"))
        parts.append(_record_labels([f], target)[0])
        out.append("; ".join(parts))
    return out


def missile(snapshot: Path) -> dict:
    """A homing missile: a life started over the ground where a game starts
    with add-on 8 fitted by the restart; a pillar staged 72 pixels ahead of
    the ship and 40 above it; fire pressed for a pass. With add-on 8 every
    other shot is a missile: should this one be a laser, it is let go and
    the scene staged again for the next."""
    pokes = {ADDON_SLOTS + 7: 8}
    game = restarted(snapshot, START_PLACE, pokes, sky=False)
    flown(game, 4, [], _keep_alive)
    record = stage_object(game, 0, PILLAR, 72, -40, 0xCC)
    def missiles():
        return [n for n in range(4) if game.peek(SHOTS + RECORD * n) == 0
                and game.peek(SHOTS + RECORD * n + 0x16) & 0x80]
    frames = flown(game, 1, ["q"], _keep_alive)
    if not missiles():
        # That shot was a laser: let it go, and the next is a missile.
        flown(game, 12, [], _keep_alive)
        record = stage_object(game, 0, PILLAR, 72, -40, 0xCC)
        frames = flown(game, 1, ["q"], _keep_alive)
    for _ in range(60):
        frames.append(game.pass_([]))
        _keep_alive(game)
        if not missiles() and game.peek(record) == 0xFF:
            break
    box = (72, 24, 232, min(184, frames[0][SHIP_SCREEN_Y] + 16))
    return animation("missile", frames, box, _missile_labels(frames, record))


# --------------------------------------------------------------------------
# The objects' own animations: the game's animate, place and draw routines
# called on one record, a pass at a time, on a cleared screen.
# --------------------------------------------------------------------------

# Two small routines put in the ROM's spare bytes (after RETURN), so that
# Game.call can run one object's share of a pass the way update_objects
# ($8D42) runs it: a new sprite pair (#R$A2EA), the old image set up for
# rubbing out if it was drawn (#R$AD27), the registers swapped (the update
# routines run in the other set), and then the body: animate (#R$910A) and
# place, draw and colour (place_draw, the tail of #R$9507) -- every step
# of an update routine but the steering and the moving.
ONE_OBJECT = 0x3880
ANIMATE_AND_DRAW = 0x38A0
_ONE_OBJECT_CODE = (0xCD, CLEAR_SPRITE_PAIR & 0xFF, CLEAR_SPRITE_PAIR >> 8,
                    0xDD, 0xCB, 0x10, 0x7E,                       # BIT 7,(IX+$10)
                    0xC4, PREPARE_ERASE & 0xFF, PREPARE_ERASE >> 8,   # CALL NZ
                    0xDD, 0xCB, 0x10, 0xB6,                       # RES 6,(IX+$10)
                    0xD9,                                         # EXX
                    0xCD, ANIMATE_AND_DRAW & 0xFF, ANIMATE_AND_DRAW >> 8,
                    0xC9)
_ANIMATE_AND_DRAW_CODE = (0xCD, ANIMATE & 0xFF, ANIMATE >> 8,
                          0xC3, PLACE_DRAW & 0xFF, PLACE_DRAW >> 8)

# The view the harness sets, so that a record's place in its page is its
# place on the screen: the view at the top left of page (column $10, row 5),
# with the screen offsets that make x and y come out unchanged
# (place_on_screen #R$ADD8 adds origin_x to x, and origin_y plus $60 to y).
HARNESS_VIEW = {VIEW_COLUMN: 0x10, RIGHT_COLUMN: 0x11, VIEW_ROW: 5, VIEW_X: 8,
                VIEW_Y: 0x18, ORIGIN_X: 0, ORIGIN_Y: 0xA0}
HARNESS_X, HARNESS_Y = 0x70, 0x80     # where the object is put: screen x, bottom line


def harness(snapshot: Path) -> Game:
    """A game run to its first pass of play, so that the start-up's tables
    exist, then stopped: the screen cleared, the sky records freed, the
    view set to HARNESS_VIEW, and the two small routines put in place."""
    game = started(snapshot)
    game.poke(ONE_OBJECT, list(_ONE_OBJECT_CODE))
    game.poke(ANIMATE_AND_DRAW, list(_ANIMATE_AND_DRAW_CODE))
    return game


def _clear(game: Game) -> None:
    game.poke(SCREEN, [0] * (SCREEN_END - SCREEN))
    for n in range(RECORDS):
        game.poke(OBJECTS + RECORD * n, 0xFF)
    for address, value in HARNESS_VIEW.items():
        game.poke(address, value)


def cycle(game: Game, graphic: int, frame_byte: int, frames_range: int, colour: int,
          passes: int, pass_tstates: int, dissolve: bool = False) -> list[Frame]:
    """One record of `graphic` with this frame byte (+$13) and range
    (+$14), animated and drawn by the game for `passes` passes on a cleared
    screen. With `dissolve`, it is exploding (+$17 bit 3) from the start.
    Each frame is given `pass_tstates`, the length of a pass measured in
    flight."""
    _clear(game)
    record = OBJECTS
    game.poke(record, [graphic, 0x10, HARNESS_X, 0, 5, HARNESS_Y] + [0] * 18)
    game.poke(record + 0x0D, colour)
    game.poke(record + 0x10, 0x01)
    game.poke(record + 0x13, [frame_byte, frames_range])
    if dissolve:
        game.poke(record + 0x17, 0x08)
    out = []
    for _ in range(passes):
        game.poke(PASS_COUNTER, (game.peek(PASS_COUNTER) + 1) & 0xFF)
        start = game.now
        game.call(ONE_OBJECT, IX=record)
        frame = game.screen_frame(start)
        frame.tstates = pass_tstates
        out.append(frame)
    return out


# --------------------------------------------------------------------------
# Dying.
# --------------------------------------------------------------------------

def _death_pass(game: Game) -> Frame:
    """A pass of the play loop, or of the death sequence's loop once the
    death byte has reached 12 (it is counted up in the pass, from 11)."""
    return game.pass_([], PLAY_LOOP if game.peek(DYING) < 11 else DEATH_LOOP)


def _death_labels(frames: list[Frame]) -> list[str]:
    return [f"death byte {f[DYING]}" for f in frames]


DEATH_GAME: dict = {}


def wreck(snapshot: Path) -> dict:
    """The ship's wreck: the first life, flown left from where a game starts
    for 40 passes (towards the hillside), then the death byte set to 1 as a
    third hit sets it (#R$8F54), and the passes until the wreck has flown
    (death byte $22)."""
    game = started(snapshot)
    flown(game, 40, ["z", "a"], _keep_alive)
    game.poke(DYING, 1)
    frames = []
    while game.peek(DYING) < 0x22:
        frames.append(_death_pass(game))
    DEATH_GAME[str(snapshot)] = game
    box = ship_box(frames[0], 40, 200, 56, 40)
    return animation("wreck", frames, box, _death_labels(frames))


def death_dissolve(snapshot: Path) -> dict:
    """The play area dissolving at the end of the death sequence: the same
    game as the wreck, run on to the dissolve (#R$9EFE), and read at its
    start and at the end of each of its sixteen sweeps (the EX AF,AF' at
    $9F27), and once more when the play area has been cleared, as the life
    is taken (#R$F4C6)."""
    game = DEATH_GAME.pop(str(snapshot), None)
    if game is None:
        wreck(snapshot)
        game = DEATH_GAME.pop(str(snapshot))
    game.hold([])
    game.run_to(DISSOLVE_PLAY_AREA, 60 * TSTATES_PER_SECOND)
    frames = [game.screen_frame()]
    labels = ["before"]
    for sweep in range(16):
        start = game.now
        game.run_to(DISSOLVE_SWEEP_END)
        frames.append(game.screen_frame(start))
        labels.append(f"sweep {sweep + 1}")
    start = game.now
    game.run_to(LOSE_LIFE)
    frames.append(game.screen_frame(start))
    labels.append("cleared")
    frames[0].tstates = frames[1].tstates
    return animation("death-dissolve", frames, PLAY_AREA, labels)


LOSE_LIFE = 0xF4C6


# --------------------------------------------------------------------------
# The rocket.
# --------------------------------------------------------------------------

HOOK = {ADDON_SLOTS: 1, ADDON_SLOTS + 1: 2}
PART_DROPPED = 7          # the part let go in the picture: the nose, on seven standing


def _rocket_labels(frames: list[Frame]) -> list[str]:
    out = []
    for f in frames:
        carried = f[PART_CARRIED]
        falling = [n for n in range(RECORDS) if f[OBJECTS + RECORD * n] == 0x1E]
        if f[LAUNCH]:
            out.append("launch" if f[LAUNCH] != 0xFF else "gone")
        elif carried != 0xFF:
            out.append(f"part {carried} carried")
        elif falling:
            out.append(f"part {f[PARTS_BUILT]} falling")
        else:
            out.append(f"{f[PARTS_BUILT]} parts built")
    return out


def part_drop(snapshot: Path) -> dict:
    """A rocket part falling into its slot: a life started a little left of
    and above the rocket's place (build_cyberun.ROCKET_VIEW, the view 24
    pixels further left and in the page row above, at line $60) with the
    hook fitted, three parts built and part 3
    carried, as the build's delivery sessions stage it; right held until the
    part is let go over the rocket, and thrust as needed throughout to hold
    the ship's height while the part falls into place."""
    column, row, view_x, view_y = bc.ROCKET_VIEW
    place = (column, row - 1, view_x - DROP_RUN_UP, DROP_VIEW_Y)
    pokes = {**HOOK, PART_CARRIED: PART_DROPPED, PARTS_BUILT: PART_DROPPED}
    game = restarted(snapshot, place, pokes)
    hold = _pilot((row - 1) * 256 + DROP_VIEW_Y)
    frames = []
    for _ in range(120):
        keys = (["x"] if game.peek(PART_CARRIED) != 0xFF else []) + hold(game)
        frames.append(game.pass_(keys))
        _keep_alive(game)
        if game.peek(PARTS_BUILT) > PART_DROPPED:
            frames += flown(game, 3, hold, _keep_alive)
            break
    else:
        raise RuntimeError("the part never reached its slot")
    return animation("part-drop", frames, PART_BOX, _rocket_labels(frames))


DROP_RUN_UP = 24
DROP_VIEW_Y = 0x48        # the view a page row up: the ship over the top of the stack
PART_BOX = (48, 24, 200, 184)


def launch(snapshot: Path) -> dict:
    """The launch: a life started inside the rocket's place with all eight
    parts built (build_cyberun.ROCKET_VIEW), as the build's launch session
    stages it; the ship docks at once and the rocket rises."""
    game = restarted(snapshot, bc.ROCKET_VIEW, {PARTS_BUILT: 8})
    frames = []
    for _ in range(LAUNCH_LIMIT):
        frames.append(game.pass_([], leaves=lambda memory: memory[LAUNCH] == 0xFF))
        if frames[-1].left:
            break
    else:
        raise RuntimeError("the rocket never left")
    # About four hundred passes: the start and the end are shown, the climb
    # between them (the rocket still on the screen, the view rising with it
    # a page row at a time) left out.
    shown = frames[:LAUNCH_START] + frames[-LAUNCH_END:]
    labels = _rocket_labels(shown)
    labels[LAUNCH_START] = f"{len(frames) - LAUNCH_START - LAUNCH_END} passes later: " +         labels[LAUNCH_START]
    return animation("launch", shown, LAUNCH_BOX, labels, total=len(frames))


LAUNCH_LIMIT = 1000
LAUNCH_START, LAUNCH_END = 30, 40
LAUNCH_BOX = (72, 24, 184, 184)


# --------------------------------------------------------------------------
# The panel, the menu and the flickering beams.
# --------------------------------------------------------------------------

GAUGE_BOX = (236, 60, 256, 196)
LOW_FUEL = 0xA800                 # the fuel word staged for the gauge's fall


def _gauge_labels(frames: list[Frame]) -> list[str]:
    out = []
    for f in frames:
        colour = "red" if f[GAUGE_COLOUR] & 7 == 2 else "yellow"
        out.append(f"shown ${f[FUEL_SHOWN]:02X}, {colour}")
    return out


def fuel_gauge(snapshot: Path) -> dict:
    """The fuel gauge: a game's first passes, as the column climbs from
    where the fly-in left it to the full tank a line a pass; then the fuel
    word set to $A800 (as if 102 of the 124 lines had been burnt) and the
    passes while the column comes down to it, flashing red since the fuel's
    level is past $98.
    The ship stands still all the while, so it burns nothing; hits are
    undone each pass (not the fuel), so that nothing ends the life."""
    def no_hits(game):
        game.poke(HITS, 0)
    game = started(snapshot)
    frames = [game.pass_([])]
    while frames[-1][FUEL_SHOWN] != frames[-1][FUEL + 1] and len(frames) < 200:
        frames += flown(game, 1, [], no_hits)
    frames += flown(game, 4, [], no_hits)
    game.poke(FUEL, [LOW_FUEL & 0xFF, LOW_FUEL >> 8])
    for _ in range(200):
        frames += flown(game, 1, [], no_hits)
        if frames[-1][FUEL_SHOWN] == LOW_FUEL >> 8:
            break
    frames += flown(game, 12, [], no_hits)
    if any(f[DYING] for f in frames):
        raise RuntimeError("the ship died in the fuel gauge's run")
    return animation("fuel-gauge", frames, GAUGE_BOX, _gauge_labels(frames))


MENU_BOX = (40, 84, 224, 184)


def _menu_labels(frames: list[Frame]) -> list[str]:
    names = ("Keyboard", "Kempston", "Cursor", "Interface II")
    out = []
    for f in frames:
        parts = []
        for player, pointer in enumerate(POINTERS, 1):
            parts.append(f"P{player} line ${f[pointer + 1]:02X} ({names[f[pointer + 2] & 3]})")
        out.append(", ".join(parts))
    return out


def menu_arrows(snapshot: Path) -> dict:
    """The menu's pointers: the menu reached with the title tune cut short
    (ENTER held, as the build's sessions do), then 1 pressed for a pass and
    the pointer left to slide, four times round (player 1's method from
    Keyboard to Kempston, Cursor, Interface II and back), then 2 twice for
    player 2's; a frame each pass of the menu's loop (#R$8615)."""
    game = Game(snapshot)
    game.play([bc.At("the menu", MENU_LOOP, 600.0, bc.TUNE_KEYS)])
    frames = flown_menu(game, 2, [])
    for key, times in (("1", 4), ("2", 2)):
        for _ in range(times):
            frames += flown_menu(game, 1, [key])
            frames += flown_menu(game, MENU_SLIDE, [])
    return animation("menu-arrows", frames, MENU_BOX, _menu_labels(frames))


MENU_SLIDE = 24          # passes for a pointer to slide a whole line down (20 lines) and settle


def flown_menu(game: Game, count: int, keys) -> list[Frame]:
    return [game.pass_(keys, MENU_LOOP) for _ in range(count)]


# A stretch of sky over a row of tile $A6 (map columns $49-$55 of row 7):
# the view in the row above, low enough that the beams 9 lines below the top
# of row 7's cells cross the screen above the ship.
BEAMS_PLACE = (75, 6, 0x40, 0x90)
BEAMS_BOX = (8, 40, 232, 128)


def _flicker_labels(frames: list[Frame]) -> list[str]:
    out = []
    for f in frames:
        pattern, colour = f[BEAM_STATE], f[BEAM_STATE + 1]
        out.append(f"pattern ${pattern:02X}, colour {colour & 7}" if pattern else "none")
    return out


def flicker_beams(snapshot: Path) -> dict:
    """The flickering beams: a life started in the sky over a row of tile
    $A6 (BEAMS_PLACE), held at that height by thrust as a player would
    (thrust while below it), kept from harm by undoing the damage each pass
    (the beams hit the ship); run until the beams first show, then 90
    passes."""
    game = restarted(snapshot, BEAMS_PLACE)
    hold = _pilot(BEAMS_PLACE[1] * 256 + BEAMS_PLACE[3])
    for _ in range(400):
        game.pass_(hold(game))
        _keep_alive(game)
        if game.peek(BEAM_STATE):
            break
    frames = flown(game, 90, hold, _keep_alive)
    return animation("flicker-beams", frames, BEAMS_BOX, _flicker_labels(frames))


# --------------------------------------------------------------------------
# The objects' cycles.
# --------------------------------------------------------------------------

# Each object's frame byte and range come from where the game takes them:
# the wave table for the attackers (by kind), make_debris for debris, the
# shot templates for the bullets, object_part_pairs for the animated ground
# objects (by kind, at the offset in the kind's flag byte). The colour is
# one the game would give: for the attackers one of the eight in
# attacker_colours (#R$9933), picked here by index so that each looks
# different; the bullets' from shot_kind_flags; the ground objects' from
# object_kind_bytes.
#   key, title, source, graphic or wave kind, colour index or None
OBJECT_CYCLES = [
    ("dome", "Dome (type $1A)", "wave", 0, 1),
    ("eye-pod", "Eye pod (type $17)", "wave", 2, 3),
    ("pillar", "Pillar (type $18)", "wave", 3, 4),
    ("rotor-craft", "Rotor craft (type $14)", "wave", 6, 5),
    ("saucer", "Saucer (type $16)", "wave", 7, 2),
    ("rock", "Rock (type $1D, wave kind 8)", "wave", 8, 0),
    ("comet", "Comet (type $1D, wave kind 9)", "wave", 9, 7),
    ("debris", "Debris (type $15)", "debris", 0x15, 4),
    ("bullet", "Bullet (type $1C, shot kind 1)", "shot", 1, None),
    ("lamp", "Lamp (type $1B, ground kind 4)", "ground", 4, None),
    ("domed-robot", "Domed robot (type $1B, ground kind 5)", "ground", 5, None),
    ("fuel-station", "Fuel station (type $1B, ground kind $0E)", "ground", 0x0E, None),
]
DEBRIS_FRAMES = (0x50, 0x05)      # make_debris (#R$903D): +$13 $50, +$14 $05


def object_setup(memory, source: str, which: int, colour_index):
    """(graphic, frame byte, range, colour) for an OBJECT_CYCLES entry, read
    from the game's tables."""
    colour = memory[ATTACKER_COLOURS + colour_index] if colour_index is not None else 0x77
    if source == "wave":
        entry = WAVE_TABLE + 4 * which
        return memory[entry], memory[entry + 2], memory[entry + 3], colour
    if source == "debris":
        return which, DEBRIS_FRAMES[0], DEBRIS_FRAMES[1], colour
    if source == "shot":
        template = SHOT_TEMPLATES + 4 * (which - 1)
        nibble = memory[SHOT_KIND_FLAGS + which - 1] & 0x0F
        return 0x1C, memory[template + 2], memory[template + 3], nibble * 0x11
    offset = memory[KIND_FLAGS + which] & 0x0F
    return (0x1B, memory[PART_PAIRS + offset], memory[PART_PAIRS + offset + 1],
            memory[KIND_COLOURS + which])


def rate(frame_byte: int) -> int:
    """Passes per frame: the count's reload, bits 6-7; 0 behaves as 3
    (#R$910A)."""
    return (frame_byte >> 6) or 3


def object_cycles(snapshot: Path, pass_tstates: int) -> list[dict]:
    game = harness(snapshot)
    memory = game.memory
    out = []
    for key, title, source, which, colour_index in OBJECT_CYCLES:
        graphic, frame_byte, frames_range, colour = object_setup(memory, source, which,
                                                                 colour_index)
        first, last = frames_range >> 4, frames_range & 0x0F
        count = max(8, 2 * (last - first + 1) * rate(frame_byte) + 1)
        frames = cycle(game, graphic, frame_byte, frames_range, colour, count, pass_tstates)
        labels = [f"frame {f[OBJECTS + 0x13] & 0x0F}" for f in frames]
        out.append(animation(key, frames, drawn_box(frames), labels, graphic=graphic,
                             frame_byte=frame_byte, range=frames_range, colour=colour))
    # A destroyed object's dissolve: the pillar again, exploding from the start.
    graphic, frame_byte, frames_range, colour = object_setup(memory, "wave", PILLAR, 4)
    frames = cycle(game, graphic, frame_byte, frames_range, colour, 9, pass_tstates,
                   dissolve=True)
    labels = []
    for f in frames:
        step = f[OBJECTS + 0x17] & 7
        labels.append("freed" if f[OBJECTS] == 0xFF else f"dissolve step {step}")
    out.append(animation("dissolve", frames, drawn_box(frames), labels, graphic=graphic,
                         frame_byte=frame_byte, range=frames_range, colour=colour))
    return out


# --------------------------------------------------------------------------
# What was measured in each run.
# --------------------------------------------------------------------------

def _seconds(frames: list[Frame]) -> str:
    total = sum(f.tstates for f in frames)
    return f"{len(frames)} passes, {total / TSTATES_PER_SECOND:.1f} s"


def _runs(values) -> list[tuple]:
    """(value, count) for each run of equal values."""
    out = []
    for value in values:
        if out and out[-1][0] == value:
            out[-1][1] += 1
        else:
            out.append([value, 1])
    return [tuple(run) for run in out]


def _plural(count: int, word: str) -> str:
    return f"{count} {word}" + ("" if count == 1 else ("es" if word.endswith("s") else "s"))


def _measure_scroll(anim) -> str:
    frames = anim["passes"]
    steps = [abs(_signed(f[SCROLL_ACROSS])) for f in frames]
    ups = [abs(_signed(f[SCROLL_DOWN])) for f in frames]
    counts = ", ".join(f"{steps.count(s)} of {s}" for s in sorted(set(steps)))
    vertical = ", ".join(f"{ups.count(s)} of {s}" for s in sorted(set(ups)))
    return (f"Measured over {_seconds(frames)}: steps across of {counts} pixels; "
            f"steps up or down of {vertical}. The passes took "
            f"{min(f.tstates for f in frames):,} to {max(f.tstates for f in frames):,} "
            f"T-states.")


def _measure_trail(anim) -> str:
    frames = anim["passes"]
    runs = _runs(f[TRAIL_FRAME] for f in frames)
    shown = ", ".join(f"{value} for {_plural(count, 'pass')}" for value, count in runs)
    speeds = sorted({abs(_signed(f[SHIP_ACROSS])) for f in frames})
    return (f"Measured over {_seconds(frames)}: the trail's frame went {shown}; the whole "
            f"part of the speed across reached {max(speeds)}.")


def _measure_turning(anim) -> str:
    frames = anim["passes"]
    turned = next(i for i, f in enumerate(frames) if f[SHIP_FACING] & 0x80)
    steered = next(i for i, f in enumerate(frames) if f[STEER] == 0x80)
    stopped = next((i for i, f in enumerate(frames) if i > steered
                    and _signed(f[SHIP_ACROSS]) >= 0), None)
    text = (f"Measured: left was first read in pass {steered + 1} of the picture, and the "
            f"ship faced left at the end of pass {turned + 1}")
    if stopped is not None:
        text += (f"; the speed across had come round to zero or the other way by pass "
                 f"{stopped + 1}, {stopped - steered} passes after the turn began")
    return text + f". {_seconds(frames)} in all."


def _measure_jets(anim) -> str:
    frames = anim["passes"]
    lift = [(f[LIFT_JET], bool(f[LIFT_JET + 3] & 0x40)) for f in frames if f[LIFT_JET + 3] & 0x80]
    side = [f[SIDE_JET] for f in frames if f[SIDE_JET + 3] & 0x80]
    flips = sum(1 for a, b in zip(lift, lift[1:]) if a[1] != b[1])
    return (f"Measured over {_seconds(frames)}: the lift jet was on the screen after "
            f"{len(lift)} passes (graphics "
            f"{', '.join(f'${g:02X}' for g in sorted({g for g, _ in lift}))}), its mirroring "
            f"changing {flips} times; the side jet after {len(side)}, graphics "
            f"{' '.join(f'${g:02X}' for g in side[:12])}" + (" ..." if len(side) > 12 else "")
            + ".")


def _shot_lengths(frames: list[Frame], special: bool) -> list[int]:
    out = []
    for f in frames:
        length = 0
        for n in range(4):
            shot = SHOTS + RECORD * n
            if f[shot] != 0xFF and f[shot + 0x0B] and not f[shot + 0x16] & 0x80 \
                    and bool(f[shot + 0x15] & 0x80) == special:
                length = max(length, f[shot + 0x0E])
        out.append(length)
    return out


def _measure_laser(anim) -> str:
    frames = anim["passes"]
    lengths = _shot_lengths(frames, False)
    longest = max(lengths)
    grow = lengths.index(longest)
    return (f"Measured: the beam was {longest} cells long at most, reached on pass "
            f"{grow + 1}, a cell a pass; it was gone {lengths[::-1].index(longest)} passes "
            f"after it was last that long. {_seconds(frames)} from the press.")


def _measure_special(anim) -> str:
    frames = anim["passes"]
    lengths = _shot_lengths(frames, True)
    longest = max(lengths)
    full = lengths.count(longest)
    return (f"Measured: {longest} cells at most, held for {_plural(full, 'pass')}"
            f"; {sum(1 for n in lengths if n)} passes with the beam out, "
            f"{_seconds(frames)} in the picture.")


def _measure_missile(anim) -> str:
    frames = anim["passes"]
    hit = next((i for i, f in enumerate(frames) if f[OBJECTS] == 0x15), None)
    if hit is None:
        return f"{_seconds(frames)}."
    return (f"Measured: the missile reached the pillar on pass {hit + 1}, "
            f"{sum(f.tstates for f in frames[:hit + 1]) / TSTATES_PER_SECOND:.1f} s after "
            f"it was fired; {_seconds(frames)} in the picture.")


def _measure_explosion(anim) -> str:
    frames = anim["passes"]
    hit = next(i for i, f in enumerate(frames) if f[OBJECTS] == 0x15)
    flying = sum(1 for f in frames if f[OBJECTS] == 0x15)
    return (f"Measured: the pillar became debris on pass {hit + 1} after the press, and "
            f"the debris flew for {flying} passes before it was freed.")


def _measure_wreck(anim) -> str:
    frames = anim["passes"]
    wrecked = next(i for i, f in enumerate(frames) if f[DYING] >= 10)
    return (f"Measured: the death byte went from 2 to {frames[-1][DYING]} over "
            f"{_seconds(frames)}; the wreck appeared {wrecked + 1} passes after the byte "
            f"was set. The passes from 10 on are longer: the death sound "
            f"({max(f.tstates for f in frames):,} T-states at most against "
            f"{min(f.tstates for f in frames):,}).")


def _measure_death_dissolve(anim) -> str:
    frames = anim["passes"]
    black = next(i for i, f in enumerate(frames)
                 if f.screen().crop(PLAY_AREA).convert("RGB").getbbox() is None)
    sweep = frames[1].tstates
    return (f"Measured: each sweep took {sweep:,} T-states ({sweep / T_STATES_PER_MS:.0f} "
            f"ms); the play area was black after sweep {black} of the sixteen, and the "
            f"other {16 - black} change nothing.")


def _measure_part_drop(anim) -> str:
    frames = anim["passes"]
    let_go = next(i for i, f in enumerate(frames) if f[PART_CARRIED] == 0xFF)
    built = next(i for i, f in enumerate(frames) if f[PARTS_BUILT] > PART_DROPPED)
    return (f"Measured: the part was let go on pass {let_go + 1} and was in its slot "
            f"{built - let_go} passes later, when the parts built went up to "
            f"{frames[built][PARTS_BUILT]}.")


def _measure_launch(anim) -> str:
    return (f"Measured: {anim['total']} passes from the restart to the rocket's leaving the "
            f"screen (launch_state $FF); the picture shows the first {LAUNCH_START} and the "
            f"last {LAUNCH_END}.")


def _measure_fuel_gauge(anim) -> str:
    frames = anim["passes"]
    shown = [f[FUEL_SHOWN] for f in frames]
    steps = {abs(a - b) for a, b in zip(shown, shown[1:])} - {0}
    red = [f for f in frames if f[GAUGE_COLOUR] & 7 == 2]
    return (f"Measured over {_seconds(frames)}: the shown level moved by "
            f"{' or '.join(str(s) for s in sorted(steps))} line a pass, from ${shown[0]:02X} "
            f"up to ${min(shown):02X} and then down to ${max(shown):02X}; red on "
            f"{len(red)} of the passes.")


def _measure_menu(anim) -> str:
    frames = anim["passes"]
    moves = set()
    for a, b in zip(frames, frames[1:]):
        for pointer in POINTERS:
            moves.add(b[pointer + 1] - a[pointer + 1])
    moves.discard(0)
    each = sum(f.tstates for f in frames) / len(frames)
    return (f"Measured: the pointers moved by {', '.join(str(m) for m in sorted(moves))} "
            f"lines a pass; a pass of the menu's loop took {each:,.0f} T-states on average "
            f"({each / T_STATES_PER_MS:.0f} ms).")


def _measure_flicker(anim) -> str:
    frames = anim["passes"]
    runs = _runs((f[BEAM_STATE], f[BEAM_STATE + 1]) for f in frames)
    shown = [count for (pattern, _), count in runs if pattern]
    dark = [count for (pattern, _), count in runs if not pattern]
    text = f"Measured over {_seconds(frames)}: {len(shown)} patterns shown"
    if shown:
        text += f", for {', '.join(str(c) for c in shown)} passes"
    if dark:
        text += f"; none shown for {', '.join(str(c) for c in dark)} passes between"
    return text + "."


def _measure_cycle(anim) -> str:
    frames = anim["passes"]
    runs = _runs(f[OBJECTS + 0x13] & 0x0F for f in frames)
    inner = runs[1:-1] or runs
    held = sorted({count for _, count in inner})
    order = [value for value, _ in runs]
    first, last = anim["range"] >> 4, anim["range"] & 0x0F
    return (f"Frame byte ${anim['frame_byte']:02X}, range ${anim['range']:02X}: frames "
            f"{first} to {last} of the list, each held "
            f"{' or '.join(str(h) for h in held)} pass{'es' if held != [1] else ''}; "
            f"in the run, frames {' '.join(str(v) for v in order[:12])}"
            f"{' ...' if len(order) > 12 else ''}. Colour ${anim['colour']:02X}.")


def _measure_dissolve(anim) -> str:
    frames = anim["passes"]
    steps = [f[OBJECTS + 0x17] & 7 for f in frames if f[OBJECTS] != 0xFF]
    return (f"Measured: steps {' '.join(str(s) for s in steps)} drawn, one a pass, and the "
            f"record freed on the pass after the seventh.")


MEASURES = {
    "scroll": _measure_scroll, "trail": _measure_trail, "turning": _measure_turning,
    "jets": _measure_jets, "laser": _measure_laser, "special-beam": _measure_special,
    "missile": _measure_missile, "explosion": _measure_explosion, "wreck": _measure_wreck,
    "death-dissolve": _measure_death_dissolve, "part-drop": _measure_part_drop,
    "launch": _measure_launch, "fuel-gauge": _measure_fuel_gauge,
    "menu-arrows": _measure_menu, "flicker-beams": _measure_flicker,
    "dissolve": _measure_dissolve,
}


# --------------------------------------------------------------------------
# The page.
# --------------------------------------------------------------------------

# key: (title, prose). The prose says what the game does and, last, what was
# staged for the picture; the measurements and the frames are added under it.
TEXT = {
    "dome": ("Dome",
             "Wave kind 0. The wave table (#R$990A) gives it the frame byte $50 and the "
             "range $02: frames 0 to 2 of type $1A's list, a new one every pass."),
    "eye-pod": ("Eye pod",
                "Wave kind 2, type $17: frame byte $F0, range $01 -- two frames, three "
                "passes each."),
    "pillar": ("Pillar",
               "Wave kind 3, type $18: frame byte $F0, range $03 -- four frames, three "
               "passes each. Its list holds three pictures, the second used twice, so it "
               "opens and closes."),
    "rotor-craft": ("Rotor craft",
                    "Wave kind 6, type $14 (#R$AF8D): four frames, three passes each."),
    "saucer": ("Saucer",
               "Wave kind 7, type $16: four frames, three passes each, here in colour $FD, "
               "the one colour of #R$9933 whose two halves differ -- bright white on one pass "
               "and bright cyan on the next (#R$AD48), so it flickers as it turns."),
    "rock": ("Rock",
             "Wave kind 8, type $1D, the meteor shower's (#R$9494): frame byte $50, frames "
             "0 to 5 of #R$98FA, a new one every pass, so it tumbles."),
    "comet": ("Comet",
              "Wave kind 9, the same type $1D: frame byte $56 and range $67, frames 6 and 7 "
              "of the same list, a new one every pass."),
    "debris": ("Debris",
               "What a shot attacker becomes (#R$9035, which sets +$13 to $50 and +$14 to "
               "$05): frames 0 to 5 of #R$9894, a new one every pass. The list repeats two "
               "of its pictures, so it bursts, shrinks and bursts again. Coloured here with "
               "the pillar's colour, which a shot attacker keeps."),
    "bullet": ("Bullet",
               "Type $1C, shot kind 1, what the spiky mounds throw: the template at #R$89AF "
               "gives frame byte $50 and range $02, frames 0 to 2 of #R$98C2, a new one every "
               "pass; its colour, bright yellow, is the low nibble of the kind's byte in "
               "#R$89A7, used for both halves. The other kinds of shot have a range of one "
               "frame and do not animate."),
    "lamp": ("Lamp",
             "A ground object of kind 4. Its byte in #R$E0FD has bit 4 set, so "
             "#R$E114 makes it graphic $1B with the frame byte and range from #R$E10E "
             "(offset 0: $50, $01) and +$15 bit 7 set, and #R$AC60 animates it: frames 0 "
             "and 1 of #R$AFCB, a new one every pass, in its kind's colours from #R$E205 "
             "($CD, bright green and bright cyan on alternate passes)."),
    "domed-robot": ("Domed robot",
                    "Ground kind 5 (and kind $0C, in other colours): offset 2 of #R$E10E, "
                    "frames 2 and 3 of graphic $1B, every pass; colours $DF."),
    "fuel-station": ("Fuel station",
                     "Ground kind $0E, the refuel pad: offset 4 of #R$E10E, frames 4 and 5, "
                     "every pass -- the two frames #R$A8F4 looks for when the ship lands on "
                     "it; colours $EE."),
    "dissolve": ("A destroyed object dissolving",
                 "An object marked exploding (+$17 bit 3: hit by the special beam, run out "
                 "of life, touched the landscape, or caught by the ship's death) is not "
                 "freed at once. #R$AD48 counts a step in bits 0-2 of +$17 each pass and "
                 "hands it to the compositor, which ANDs the new image's rows with that "
                 "step's mask from #R$A2FB -- seven bits, then six, down to one -- rotated a "
                 "bit per byte so the gaps do not line up (#R$A498); at the eighth step the "
                 "record is freed and only the rubbing out is left. The object goes on "
                 "animating while it crumbles. Here the pillar, marked exploding from its "
                 "first pass."),
    "scroll": ("The landscape scrolling",
               "Nothing is scrolled in memory: each pass #R$DDF8 redraws the landscape of "
               "the four map cells the view straddles straight onto the screen (#R$D0BD), "
               "from pieces pre-shifted by 0, 2, 4 and 6 pixels, and paints only the strips "
               "a moving edge uncovers -- black sky and the ground's checker look the same "
               "after a 2-pixel move, which is why every step is 2 pixels (or 4). The ship "
               "never moves on the screen; its speed is the scroll. Here the first life, "
               "flown left from where a game starts, towards the hillside, thrust held five "
               "passes in nine; the whole play area, from the fifth pass."),
    "trail": ("The trail",
              "The thin line rising from the back of the ship (#R$C4ED) bends with the speed "
              "across: its frame is 1 + twice the whole pixels + the half, from the six "
              "pictures of #R$C7C8, mirrored with the way the ship faces. It is rubbed out "
              "and drawn again only when its frame changes, the ship turns, or the "
              "collision code asks. Here the first life, standing where a game starts: "
              "right held for 20 passes, then nothing for 30 while the drag slows the "
              "ship."),
    "turning": ("The ship turning",
                "The ship's picture is drawn over itself each odd pass and rubbed out only "
                "when it changes (#R$C3E3): a turn is the steering against the facing, and "
                "then the old picture's rows are rubbed out and the new one's drawn in turn, "
                "mirrored through the bit-reversal table (#R$C421). The facing turns at once; "
                "the speed comes round slowly, and the trail with it. Here right held for 20 "
                "passes and then left for 24; the picture starts at the twelfth."),
    "jets": ("The side and lift jets",
             "With add-on 5 the lift jet (#R$C6D2) hangs under the ship on even passes: "
             "graphic $11 while thrusting, $12 otherwise, mirrored on every other draw so "
             "that it seems to spin, and left out for a pass when the ground is close below. "
             "With add-on 4 the side jet (#R$C5FF) flickers behind the ship on odd passes "
             "while it steers, its graphic through the eight steps of #R$C7A9 ($0E, $0F, "
             "$10 in a jumbled order) and its colour through #R$C79B. Here a life started "
             "where a game starts, with add-ons 4 and 5 fitted by the restart: thrust for "
             "14 passes, nothing for 6, right for 14 and left for 14."),
    "laser": ("A laser shot",
              "#R$B731 starts it ahead of the ship's nose; #R$B483 grows it a cell a pass, "
              "its head 16 pixels and its tail 8, drawing it with OR from an 8-byte pattern "
              "(#R$B3DA) read from a moving offset, so the head stays solid and the tail "
              "ragged, and rubbing it out by ANDing exactly what was drawn (#R$B5AF). A "
              "probe running ahead tests the landscape; when it hits, or the head reaches "
              "the edge, the head stops and the tail catches up. Here the first life, "
              "standing where a game starts, fire pressed for one pass."),
    "special-beam": ("The special beam",
                     "With add-on 7, the special key fires it while the ship is still "
                     "(#R$B833), and the ship then hangs where it is. #R$B414 grows it a "
                     "cell every other pass up to 8, its frame stepping 0, 1, 2, 3, 2, 1 "
                     "through #R$B8CF, each frame expanded into the sprite buffer by #R$B8DB "
                     "and drawn and rubbed out like a laser of several lines; after 22 "
                     "passes, or when the key is let go, it shrinks a cell a pass. Here a life "
                     "started over the ground where a game starts, with add-on 7 fitted by "
                     "the restart, lifted off with 12 passes of thrust, then 1 held for 34 "
                     "passes. On the ground it would not show: the probe meets the ground on "
                     "the beam's first pass and it ends at once."),
    "missile": ("A homing missile",
                "With add-on 8 every other shot is a missile (#R$B731): an ordinary object "
                "of type 0, 8 pixels a pass. #R$9307 looks for a target among the sky "
                "records drawn this pass, by type, through #R$92EE, and steers at it hard "
                "(+/-$C0 an axis), so it overshoots and comes round. Here a life started "
                "where a game starts with add-on 8 fitted by the restart, a pillar staged 72 "
                "pixels ahead of the ship and 40 above (see below), and fire pressed once. "
                "The pillar (type $18) is one the missile will choose: as the code indexes "
                "the table, it rates 6 (see #R$92EE)."),
    "explosion": ("A shot attacker breaking up",
                  "A shot attacker is scored and becomes debris (#R$9035): type $15, "
                  "harmless, its frames cycling every pass, flying the fixed loop of "
                  "#R$9873 -- sixteen velocity pairs, out, up, round and down -- in one of "
                  "its four mirror images, until #R$96D8 reaches the loop's end and frees it. "
                  "Here the first life, standing where a game starts; a pillar staged 56 "
                  "pixels ahead of the ship at its height (see below), and fire pressed for a "
                  "pass."),
    "wreck": ("The ship's wreck",
              "The third hit (or an empty tank) sets #R$8F53 to 1; #R$8D42 counts it up a "
              "pass. While it is 1 to 3 every sky object is marked exploding and dissolves; "
              "at 10 #R$8CB2 fills all nine records with the wreck -- four debris flying the "
              "four mirror images of the debris loop at once, a burst, and five yellow pieces "
              "thrown up by #R$8D1F under gravity -- and the death sound plays every pass. "
              "From 11 the ship is no longer drawn; at 12 the play loop gives way to the "
              "death sequence's. Here the first life, flown left for 40 passes from where a "
              "game starts; then the death byte set to 1, as the third hit sets it "
              "(#R$8F54)."),
    "death-dissolve": ("The play area dissolving",
                       "At the end of the death sequence, after the death tune, "
                       "#R$9EFE ANDs every byte of the play area sixteen times with the "
                       "next of the masks at #R$9F44, the masks running on from byte to "
                       "byte and line to line, so the picture loses its pixels in a "
                       "scattered pattern; then the play area is cleared (#R$9EF5). It is "
                       "not a pass: the picture is read at the start and after each "
                       "sweep, each shown as long as the sweep took, and once more as the "
                       "life is taken (#R$F4C6). The same run as the wreck."),
    "part-drop": ("A rocket part falling into its slot",
                  "#R$9724 lets the part the ship carries go when the ship is over the "
                  "rocket's place (page column $52, pixel $5C, row 10 or above): it becomes "
                  "a type $1E object (#R$9524) falling under a slight acceleration, without "
                  "testing the landscape, until it reaches its slot -- the rocket's base "
                  "plus the part's offset from #R$96B0 -- where it is freed, the parts built "
                  "go up by one and 1500 points are scored. #R$9572 draws the parts already "
                  "standing. Here the nose cone, part 7, with seven parts built: a life "
                  "started a little left of and above the rocket's place with the hook "
                  "fitted and the part carried, right held until it was let go, thrust as "
                  "needed to hold the height."),
    "launch": ("The launch",
               "With all eight parts built and the ship in place inside the rocket, "
               "#R$9572 sets #R$96AB, puts the ship away, and from then on moves the "
               "rocket's base up each pass by the view's own climb -- #R$B234 holds "
               "thrust on at the fast climb until the view reaches page row 0 -- so the "
               "rocket stays put on the screen while the landscape falls away; in page row "
               "0 the base rises 4 lines a pass, and once part 0 has left the screen "
               "#R$96AB becomes $FF and the level ends. Here a life started inside the "
               "rocket's place with eight parts built, as the build's launch session "
               "stages it; the climb in between is left out of the picture."),
    "fuel-gauge": ("The fuel gauge",
                   "#R$CC77 moves the shown level a line a pass towards the fuel's, by "
                   "XORing two rows -- three pixels at one and the two either side at the "
                   "next -- so the column keeps a rounded top and is never redrawn whole. "
                   "#R$CAA7 colours it on odd passes: yellow, or red on two passes in four "
                   "once the fuel's level has reached $98, about seven tenths used. Here a game's first passes, "
                   "the column climbing to the full tank; then the fuel set to $A800 (102 of "
                   "the 124 lines burnt) and the column coming down to it."),
    "menu-arrows": ("The menu's pointers",
                    "Each pass of #R$8615 moves each player's pointer towards the line of "
                    "the control method chosen (#R$8690): one line a pass down, four up. "
                    "The pointer is drawn with #R$C96F over whatever is there, and the "
                    "blank lines at its head and foot rub out what it leaves behind, so "
                    "there is no erase. Here the menu, the title tune cut short with ENTER; "
                    "then 1 pressed for a pass and the pointer left to slide, four times "
                    "round, and 2 twice."),
    "flicker-beams": ("The flickering beams",
                      "Over every map cell of tile $A6 a one-line beam crosses the cell 9 "
                      "lines below its top (#R$9BDA, #R$9D53). When the timer in #R$9BD6 "
                      "runs out the game picks, half the time, a pattern from #R$9DA9 in a "
                      "random bright colour for 1-32 passes, and otherwise none for 1-16. "
                      "The pattern is rotated by the fine scroll, so it stays still on the "
                      "world. A beam touching the ship damages it. Here a life started in "
                      "the sky over a row of tile $A6 (map columns $49-$55 of row 7, the "
                      "view in row 6), held at its height by thrust; the damage was undone "
                      "each pass."),
}

GROUPS = [
    ("The objects' own animations", ["dome", "eye-pod", "pillar", "rotor-craft", "saucer",
                                     "rock", "comet", "debris", "bullet", "lamp",
                                     "domed-robot", "fuel-station", "dissolve"]),
    ("The landscape", ["scroll"]),
    ("The ship", ["trail", "turning", "jets"]),
    ("Weapons", ["laser", "special-beam", "missile", "explosion"]),
    ("Dying", ["wreck", "death-dissolve"]),
    ("The rocket", ["part-drop", "launch"]),
    ("The panel, the menu and the beams", ["fuel-gauge", "menu-arrows", "flicker-beams"]),
]

CYCLE_KEYS = set(GROUPS[0][1])
STAGED = {"missile", "explosion"}
SCALE = 2
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


# Each run made once per snapshot and kept, in case another module wants the
# same runs in the same process.
_RUNS: dict = {}

LIVE = (scroll, trail, turning, jets, laser, special_beam, missile, explosion, wreck,
        death_dissolve, part_drop, launch, fuel_gauge, menu_arrows, flicker_beams)


def animations(snapshot: Path, log=print) -> tuple[dict[str, dict], int]:
    """Every animation, by key, and the length of a pass used for the
    objects' cycles: the median of the scroll's passes."""
    key = str(snapshot)
    if key in _RUNS:
        return _RUNS[key]
    made = {}
    for make in LIVE:
        log(f"  {make.__name__}")
        anim = make(snapshot)
        made[anim["key"]] = anim
    lengths = sorted(f.tstates for f in made["scroll"]["passes"])
    pass_tstates = lengths[len(lengths) // 2]
    log("  the objects' cycles")
    for anim in object_cycles(snapshot, pass_tstates):
        made[anim["key"]] = anim
    _RUNS[key] = (made, pass_tstates)
    return _RUNS[key]


def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    """Write the GIFs into html_dir/images/animations and return the
    Animations section."""
    out_dir = html_dir / "images" / "animations"
    out_dir.mkdir(parents=True, exist_ok=True)
    log("Running Cyberun's animations in the game's own code...")
    made, pass_tstates = animations(snapshot, log)
    entries = skool_entries()
    flight = made["scroll"]["passes"]
    fastest = min(f.tstates for f in flight)
    slowest = max(f.tstates for f in flight)
    pass_ms = pass_tstates / T_STATES_PER_MS
    lines = ['<div class="kl-list">',
             "<p>Every picture below is the game's own drawing, made when these pages "
             "were built by running Cyberun in SkoolKit's simulator from the tape's "
             "snapshot. Nothing is put together from the sprites.</p>",
             "<p><b>The game played.</b> Most of the animations are the game running: "
             "started through the menu as the build's sessions start it, and where a "
             "scene needs somewhere else -- the rocket, the sky over the beams, a life with "
             "add-ons -- a new life put there by the game's own restart (the restart point "
             "written at the end of a death sequence, as the build does), with the add-ons "
             "or parts it needs set at the same moment. Each frame is the screen as one "
             "pass of the play loop left it, read at #R$F440's loop (the CALL at $F46C) or, "
             "during the death sequence, at its own loop ($F49E). Keys were held as a "
             "player holds them; where more was staged -- an attacker put in front of the "
             "ship, the fuel set low, the damage undone -- the animation says so.</p>",
             "<p><b>A pass is not a frame.</b> The game never waits for the television: "
             "interrupts are off and a pass takes as long as its work, two or three "
             "television frames. So each frame of a picture is shown for as long as the "
             "game took over that pass, counted in T-states in the simulator at 3.5MHz "
             "and rounded to the 10 ms a GIF can say; a frame drawn the same as the one "
             "before is merged into it. In the flight over the landscape a pass took "
             f"{fastest:,} to {slowest:,} T-states, {pass_tstates:,} in the middle "
             f"({pass_ms:.0f} ms, {1000 / pass_ms:.0f} passes a second). The simulator has "
             "none of a real Spectrum's memory contention, so on the machine, where the ULA "
             "holds up the processor's reads and writes of the screen, a pass takes "
             "somewhat longer; the notes' figure of about 20 passes a second was made by "
             "counting television frames in the emulator.</p>",
             "<p><b>The objects' own animations</b> are the game's routines called on one "
             "record, a pass at a time, on a cleared screen: the record set up with the "
             "type, frame byte and range the game gives that thing (from the tables each "
             "names), then each pass the same steps #R$8D42 takes for an object -- a new "
             "sprite pair, the old image set up for rubbing out, and animate_object "
             "(#R$910A), place, draw and colour (the tail of #R$9507) -- but no steering "
             "and no moving, so the thing animates where it stands. Each of those frames "
             f"is shown for one pass of {pass_tstates:,} T-states, the middle pass of the "
             "flight above.</p>",
             "<p>The animator is one byte, +$13 of the record: bits 0-3 the frame in the "
             "type's list (#R$AF3D), bits 4-5 a count, bits 6-7 the count's reload; "
             "+$14 holds the first and last frames. Each call counts down and, when the "
             "count reads 1, steps the frame on, from the last back to the first, and "
             "reloads -- one frame every one, two or three passes.</p>",
             "<p>Each picture is shown at twice the Spectrum's size. Under each: what was "
             "measured in the run, and the frames of the picture with what they show and "
             "how long each lasts.</p>"]
    for heading, keys in GROUPS:
        lines.append(f"<h3>{_esc(heading)}</h3>")
        for key in keys:
            anim = made[key]
            title, words = TEXT[key]
            frames = anim["frames"]
            save_gif(out_dir / f"{key}.gif", frames)
            width, height = frames[0][0].size
            lines += [f'<div class="kl-item" id="{key}">',
                      f"<h4>{_esc(title)}</h4>",
                      f'<img class="cy-picture" src="images/animations/{key}.gif" '
                      f'alt="{_esc(title)}" width="{width * SCALE}" '
                      f'height="{height * SCALE}">',
                      f"<p>{link(words, entries)}</p>"]
            if key in STAGED:
                lines.append("<p>Staged: the object was put in a record the way the game "
                             "puts a thing at the ship (#R$8D29: the record cleared, the "
                             "ship's place copied in and moved once by the offset), given its "
                             "kind's four bytes from #R$990A as #R$89D3 copies them and a "
                             "first wait of 60 passes before it changes course (#R$97DF); "
                             "the other sky records were freed.</p>")
            measure = (_measure_cycle if key in CYCLE_KEYS and key != "dissolve"
                       else MEASURES[key])
            lines += [f"<p>{link(_esc(measure(anim)), entries)}</p>",
                      f"<p>In the picture: {_esc(_order(frames))}.</p>",
                      "</div>"]
    lines.append("</div>")
    body = "\n".join(lines)
    for line in body.splitlines():
        if line.startswith((";", "[")):
            raise RuntimeError(f"a section line starts with {line[0]!r}: {line[:40]}")
    return {"Animations": body}
