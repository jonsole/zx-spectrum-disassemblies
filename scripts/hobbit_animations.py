"""The Hobbit's animations, as GIFs of the game running its own code.

build_hobbit.py's HTML build calls build(), which writes the GIFs into the
HTML directory and returns the Animations section. Nothing here is committed
output: every frame is the game's, made when the pages are built.

The Hobbit has no sprites and no frame loop, so its animations are what the
screen does while the game runs. The pictures being drawn are the Locations
page's GIFs (hobbit_pages.py) and the fast-draw comparison the Patches page's;
this page has the rest: the opening, the story typed out and scrolled, the
trolls' clearing at dawn, a fight, being eaten and starting again, the game
typing WAIT for an idle player, the input cursor, PAUSE -- and, drawn on the
site's map rather than read off the screen, the other characters walking about
while the player waits.

Each is a game started the way hobbit_drive.Hobbit starts one, from the
snapshot the tape leaves, in SkoolKit's simulator, and then played: commands
typed a key at a time (so the game echoes them), key waits answered as the
game reaches them, and the screen memory read at every frame interrupt, 69888
T-states apart at 3.5MHz. The simulator has no memory contention, so a real
Spectrum runs the same code a little slower; the times are the simulator's.

Where a number has to be read from inside a routine -- a blow and a guard, a
capture, each character printed -- the same game is played a second time from
START with the same keys at the same T-states (Game.replay), stopped at that
routine, and checked to end where the filmed game ended, byte for byte.
"""
from __future__ import annotations

import html
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import build_hobbit as bh

IMAGE_DIR = "images/animations"     # under html/hobbit/; the page is reference/animations.html
PAGE_IMAGES = "../" + IMAGE_DIR

# --------------------------------------------------------------------------
# Addresses. See their entries in the listing.
# --------------------------------------------------------------------------

TITLE_WAIT = 0x6C6D         # NEW_GAME: the title screen waits for a key
TITLE_KEY_SEEN = 0x6C76     # ...and has seen one
LINE_TAKEN = 0x6D20         # MAIN_LOOP, just after CALL READ_LINE
READ_LINE_READY = 0x6DF3    # READ_LINE with HL and B set, before any key
INPUT_LINE = 0x6FF9
WAIT_FOR_ANY_KEY = (0x969A, 0x96A2)     # the loop; $96A3 is past it
KEY_SEEN = 0x96A3
WAIT_AND_RESTART = (0x90DF, 0x90E7)     # won or dead: a key starts again
PRINT_SHOWN = 0x858F        # PRINT_CHAR past PRINT_GATE: really printed
INPUT_STYLE = 0xB701        # set: PRINT_CHAR's output goes to the input window
ACTING, TARGET = 0xB6EA, 0xB6E8     # who is doing the action, and to what
OBJECT_INDEX = 0xC063
CHARACTERS = 0xCACB
PLAYER_WHERE = 0xC12B
PICTURE_TABLE = 0xCC00
TROLLS_CLEARING = 5
TROLLS = (0x47, 0x48)
BLOW_AND_GUARD = 0x91C1     # DO_ATTACK with the jostled blow and guard in hand
CAPTURED = 0xA41D           # DO_CAPTURE past FOR_REAL: a capture done, B = where to
DEAD = 0x08                 # flag bit 3 of an object's byte 7

FRAME_TSTATES = 69888       # one frame interrupt to the next
FLASH_FRAMES = 16           # the ULA swaps FLASH ink and paper every 16
T_PER_MS = 3500
BORDER = 16                 # pixels of border drawn round the screen

# Typing: how long a key is held and the gap after it -- the build's own
# typing speeds (build_hobbit's --hold and --gap defaults).
KEY_HOLD, KEY_GAP = 0.10, 0.06

PALETTE = [((level if c & 2 else 0), (level if c & 4 else 0), (level if c & 1 else 0))
           for level in (0xD7, 0xFF) for c in range(8)]


def _esc(text: str) -> str:
    return html.escape(text, quote=False).replace("#", "&#35;")


# --------------------------------------------------------------------------
# The game, running.
# --------------------------------------------------------------------------

class _Tracer:
    """The simulator's ports: the keys held down, and the border the game
    last sent to the ULA."""

    def __init__(self):
        from skoolkit.kbtracer import KEY_BITS
        self.key_bits = KEY_BITS
        self.keys: set[str] = set()
        self.border = 7

    def read_port(self, registers, port):
        if port & 0xFF == 0x1F:     # Kempston joystick: nothing pressed
            return 0
        if port & 1:                # not the ULA
            return 0xFF
        result = 0xFF
        for key in self.keys:
            half_row, bits = self.key_bits[key]
            if port & half_row == 0:
                result &= bits
        return result

    def write_port(self, registers, port, value, offset=0):
        if port & 1 == 0:
            self.border = value & 7


class Frame:
    """The screen at one frame interrupt: its 6912 bytes, the border, the
    T-state it was read at, and where the game was."""

    def __init__(self, t: int, screen: bytes, border: int, pc: int = 0):
        self.t, self.screen, self.border, self.pc = t, screen, border, pc


class Game:
    """One game in the simulator, from the snapshot the tape leaves, stopped
    at START; the screen can be filmed at every frame interrupt while it
    runs."""

    def __init__(self):
        from skoolkit import CSimulator, read_bin_file
        from skoolkit.simulator import Simulator
        from skoolkit.snapshot import Snapshot

        snap = Snapshot.get(str(bh.OUT_DIR / "hobbit.z80"))
        memory = list(snap.memory)
        memory[:0x4000] = read_bin_file(str(bh.ROM))
        self.sim = (CSimulator or Simulator)(
            memory, registers={"SP": bh.STACK, "IY": bh.SYSVARS},
            state={"iff": 1, "im": 1, "tstates": 0})
        self.tracer = _Tracer()
        self.sim.set_tracer(self.tracer)
        self.memory = self.sim.memory
        self.pc = bh.ENTRY
        self.film: list[Frame] | None = None
        self.events: list[tuple[int, str]] = []
        # Every change of the keys held, with its T-state: all the game's
        # input, so that the same game can be played again exactly.
        self.inputs: list[tuple[int, frozenset]] = []

    # -- time and the screen

    @property
    def t(self) -> int:
        from skoolkit.simutils import T
        return self.sim.registers[T]

    def frame(self) -> Frame:
        return Frame(self.t, bytes(self.memory[0x4000:0x5B00]), self.tracer.border, self.pc)

    def note(self, what: str) -> None:
        self.events.append((self.t, what))

    # -- running

    def _trace(self, stop: int, until: int) -> None:
        from skoolkit.simutils import PC
        self.sim.trace(self.pc, stop, 0, until, True, None, None, None, None, None)
        self.pc = self.sim.registers[PC]

    def run(self, seconds: float, stop: int = 0) -> bool:
        """Run for up to `seconds`, or until PC is `stop` (True if it got
        there), filming each frame interrupt passed on the way if filming."""
        from skoolkit.simutils import PC
        if stop and self.pc == stop:
            # A trace that starts on its own stop address ends at once.
            self.sim.trace(self.pc, 0, 1, 0, True, None, None, None, None, None)
            self.pc = self.sim.registers[PC]
        return self.run_to(self.t + int(seconds * bh.TSTATES_PER_SECOND), stop)

    def run_to(self, until: int, stop: int = 0) -> bool:
        # Always in pieces that end at frame interrupts, filming or not, so
        # that a game run twice with the same keys -- once filmed, once
        # stopped at a routine to read what it does -- takes every key and
        # every stop at the same T-state and plays out the same.
        while self.t < until:
            boundary = (self.t // FRAME_TSTATES + 1) * FRAME_TSTATES
            self._trace(stop, min(until, boundary))
            if self.film is not None and self.t >= boundary:
                self.film.append(self.frame())
            if stop and self.pc == stop:
                return True
        return False

    def next_frame(self, stop: int = 0) -> bool:
        """Run to the next frame interrupt, or until PC is `stop`."""
        return self.run_to((self.t // FRAME_TSTATES + 1) * FRAME_TSTATES, stop)

    def keys(self, keys) -> None:
        keys = frozenset(keys)
        if keys != self.tracer.keys:
            self.inputs.append((self.t, keys))
        self.tracer.keys = keys

    def replay(self, inputs: list, until: int, watch: int, seen) -> None:
        """Play a game again from START with the keys another played it with,
        to T-state `until`, calling `seen(self)` each time PC reaches `watch`
        -- a routine to read what it does, where the filmed run could not
        stop as well as at its own stops. A key changed at a T-state where the
        other run had stopped, and the simulator stops at the first
        instruction boundary at or past a given T-state, so each change lands
        where it did before and the game plays out the same; the caller
        checks that it did."""
        from skoolkit.simutils import PC
        events = [(t, k) for t, k in inputs if t < until] + [(until, None)]
        for t_next, keys in events:
            while self.t < t_next:
                self._trace(watch, t_next)
                if self.pc == watch and self.t < t_next:
                    seen(self)
                    self.sim.trace(self.pc, 0, 1, 0, True, None, None, None, None, None)
                    self.pc = self.sim.registers[PC]
            if keys is not None:
                self.tracer.keys = keys

    def hold(self, keys, seconds: float, stop: int = 0) -> bool:
        self.keys(keys)
        return self.run(seconds, stop)

    def in_loop(self, span) -> bool:
        return span[0] <= self.pc <= span[1]

    def to_prompt(self, limit: float = 120.0, on_wait=None) -> str:
        """Run until the game asks for a line ('ready'), answering the key
        wait after each new picture on the way; 'over' if it stops in
        WAIT_AND_RESTART instead (dead, or won). Polled every frame: a wait
        loops until a key comes, so a frame late costs nothing but that
        frame. `on_wait` is called at a picture's key wait before the key
        goes down."""
        self.keys([])
        start = self.t
        if self.pc == READ_LINE_READY:
            self.run(0, READ_LINE_READY)    # off the stop, one instruction
        while self.t - start < limit * bh.TSTATES_PER_SECOND:
            if self.next_frame(READ_LINE_READY):
                self._last_frame()
                return "ready"
            if self.in_loop(WAIT_FOR_ANY_KEY):
                if on_wait:
                    on_wait(self)
                self.note("key")
                # Let go just past where it is seen: a key still down when a
                # story line ends skips that line's pause and then waits.
                self.hold(["SPACE"], 1.0, KEY_SEEN)
                self.keys([])
            elif self.in_loop(WAIT_AND_RESTART):
                self._last_frame()
                return "over"
        raise RuntimeError(f"the game never asked for a line (PC ${self.pc:04X})")

    def _last_frame(self) -> None:
        # The screen where the run stopped, if it has changed since the last
        # frame interrupt: the prompt, say, printed after it.
        if self.film is not None:
            frame = self.frame()
            if not self.film or (frame.screen, frame.border) != (self.film[-1].screen, self.film[-1].border):
                self.film.append(frame)

    def type_line(self, text: str) -> None:
        """Type `text` and ENTER a key at a time, as a player would, from the
        prompt; the game echoes each key into the input window. Checked
        against what READ_LINE put in INPUT_LINE."""
        if self.pc != READ_LINE_READY:
            raise RuntimeError(f"not at the prompt (PC ${self.pc:04X})")
        self.note("typing " + text)
        # SCAN_KEYBOARD counts a key only if it was up at the scan before, and
        # the first prompt's scan table starts as if every key were down: let
        # one scan see the keyboard empty first, as a player's would.
        self.hold([], 0.05)
        for char in text.upper():
            self.hold(bh._keys_for(char), KEY_HOLD)
            self.hold([], KEY_GAP)
        if not self.hold(["ENTER"], 1.0, LINE_TAKEN):
            raise RuntimeError(f"ENTER was not taken (PC ${self.pc:04X})")
        self.keys([])
        got = bytes(self.memory[INPUT_LINE:INPUT_LINE + len(text) + 1])
        if got != text.upper().encode() + b"\r":
            raise RuntimeError(f"typed {text!r}, the game read {got!r}")

    def say(self, text: str, limit: float = 120.0) -> str:
        self.type_line(text)
        return self.to_prompt(limit)

    def start(self) -> None:
        """From START to the title screen's key wait, then past the opening
        to the first prompt."""
        if not self.hold([], 5.0, TITLE_WAIT):
            raise RuntimeError("the title screen never came")
        self.press_at_title()
        if self.to_prompt() != "ready":
            raise RuntimeError("the first turn did not end at a prompt")

    def press_at_title(self) -> None:
        self.note("key")
        # SPACE, not N: N held means no pictures.
        self.hold(["SPACE"], 1.0, TITLE_KEY_SEEN)
        self.keys([])

    # -- the game's state

    def records(self) -> dict[int, int]:
        """Object number -> the start of its record, from OBJECT_INDEX."""
        return {number: start for number, start, _ in bh.keyed_table(self.memory, OBJECT_INDEX)}


# --------------------------------------------------------------------------
# Pictures.
# --------------------------------------------------------------------------

def screen_image(frame: Frame, border: int = BORDER):
    """The whole screen and a border round it, as a PIL image in the
    Spectrum's colours. FLASH is drawn in the phase the ULA is in at the
    frame's T-state."""
    from PIL import Image

    screen = frame.screen
    rows = bytearray()
    for y in range(192):
        row = ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
        rows += screen[row:row + 32]
    mask = Image.frombytes("1", (256, 192), bytes(rows)).convert("L")
    attributes = screen[0x1800:0x1B00]
    swapped = (frame.t // FRAME_TSTATES // FLASH_FRAMES) & 1
    inks, papers = [], []
    for a in attributes:
        bright = 8 if a & 0x40 else 0
        ink, paper = a & 7, (a >> 3) & 7
        if a & 0x80 and swapped:
            ink, paper = paper, ink
        inks.append(PALETTE[bright + ink])
        papers.append(PALETTE[bright + paper])
    ink_layer = Image.new("RGB", (32, 24))
    paper_layer = Image.new("RGB", (32, 24))
    ink_layer.putdata(inks)
    paper_layer.putdata(papers)
    picture = Image.composite(ink_layer.resize((256, 192), Image.NEAREST),
                              paper_layer.resize((256, 192), Image.NEAREST), mask)
    if not border:
        return picture
    framed = Image.new("RGB", (256 + 2 * border, 192 + 2 * border), PALETTE[frame.border])
    framed.paste(picture, (border, border))
    return framed


def save_gif(path: Path, frames: list[tuple], scale: int = 2) -> None:
    """Save (image, milliseconds) pairs as a looping GIF, identical pictures
    in a row merged into one, at `scale` times the size."""
    from PIL import Image

    merged: list[list] = []
    for image, ms in frames:
        if merged and merged[-1][0].tobytes() == image.tobytes():
            merged[-1][1] += ms
        else:
            merged.append([image, ms])
    images = [image.resize((image.width * scale, image.height * scale), Image.NEAREST)
              for image, _ in merged]
    # GIF durations are in hundredths of a second; PIL rounds.
    durations = [max(20, int(round(ms))) for _, ms in merged]
    path.parent.mkdir(parents=True, exist_ok=True)
    images[0].save(path, save_all=True, append_images=images[1:], duration=durations,
                   optimize=True, disposal=1, loop=0)


def gif_frames(film: list[Frame], holds: dict[int, float] | None = None, crop=None,
               border: int = BORDER, last_hold: float = 3000) -> list[tuple]:
    """(image, ms) pairs from a film: each frame lasts until the next was read
    -- a fiftieth of a second, or less where a stop cut it short -- except a
    frame in `holds` (by index), shown that many ms: a wait the game would sit
    in for as long as nobody pressed a key. The last is held `last_hold` more."""
    out = []
    for i, frame in enumerate(film):
        image = screen_image(frame, border)
        if crop:
            image = image.crop(crop)
        if holds and i in holds:
            ms = holds[i]
        else:
            next_t = film[i + 1].t if i + 1 < len(film) else frame.t + FRAME_TSTATES
            ms = (next_t - frame.t) / T_PER_MS
        out.append((image, ms))
    out[-1] = (out[-1][0], out[-1][1] + last_hold)
    return out


# --------------------------------------------------------------------------
# What the game was doing at each frame: PC at the interrupt, by routine.
# --------------------------------------------------------------------------

AT_PROMPT = "at the prompt (#R$6DD6(READ_LINE))"
TURN = "the turn: the parser, the characters, the story composed and printed"
KINDS = [
    ((0x6C6D, 0x6C74), "the title screen, waiting for a key (#R$6C00(START))"),
    ((0x969A, 0x96A2), "the picture finished, waiting for a key (#R$969A(WAIT_FOR_ANY_KEY))"),
    ((0x90DF, 0x90E7), "waiting for a key to start a new game (#R$90D2(PLAYER_DIES))"),
    ((0x84B9, 0x84CA), "PAUSE: waiting for a key (#R$84B9(NEW_KEYPRESS))"),
    ((0x8441, 0x8449), "PAUSE: waiting for the key to be let go (#R$843A(DO_PAUSE))"),
    ((0x86E2, 0x86EE), "the pause at the end of a story line (#R$86A1(STORY_CHAR))"),
    ((0x86F8, 0x8700), "waiting for the keys to be let go (#R$86A1(STORY_CHAR))"),
    ((0x7F78, 0x8250), "drawing the picture (#R$7F78(DRAW_LOCATION_PICTURE))"),
    ((0x6DD6, 0x6E96), AT_PROMPT),
    ((0x7249, 0x728A), AT_PROMPT),
    ((0x8B78, 0x8BFA), AT_PROMPT),
]


def kind_of(pc: int) -> str:
    for (low, high), what in KINDS:
        if low <= pc <= high:
            return what
    return TURN


def phases(film: list[Frame], events: list[tuple[int, str]],
           holds: dict[int, float] | None = None, shortest: int = 3) -> list[tuple]:
    """The film as runs of the same kind of work, from where PC was at each
    frame interrupt: (start s, length s, what, shown-for s or None), times
    from the first frame. A run shorter than `shortest` frames between two of
    one kind is taken as part of them -- a character echoed while typing, a
    routine called from the print loop."""
    kinds = [kind_of(f.pc) for f in film]
    while True:
        runs = []
        for i, k in enumerate(kinds):
            if runs and runs[-1][1] == k:
                runs[-1][2] += 1
            else:
                runs.append([i, k, 1])
        for j in range(1, len(runs) - 1):
            start, kind, length = runs[j]
            held = holds and any(i in holds for i in range(start, start + length))
            if length < shortest and runs[j - 1][1] == runs[j + 1][1] != kind and not held:
                for i in range(start, start + length):
                    kinds[i] = runs[j - 1][1]
                break
        else:
            break
    out = []
    t0 = film[0].t
    for start, kind, length in runs:
        end = start + length
        t_start = film[start].t
        # The last frame is where the run stopped -- the prompt, usually --
        # and ends it.
        t_end = film[end].t if end < len(film) else film[-1].t
        what = kind
        if kind == AT_PROMPT:
            typed = [e[7:] for t, e in events
                     if e.startswith("typing ") and t_start - FRAME_TSTATES <= t < t_end]
            if typed:
                what = f"typing {typed[0]} and ENTER (#R$6DD6(READ_LINE))"
        held = [holds[i] for i in range(start, end) if holds and i in holds]
        out.append(((t_start - t0) / bh.TSTATES_PER_SECOND,
                    (t_end - t_start) / bh.TSTATES_PER_SECOND, what,
                    held[0] / 1000 if held else None))
    return out


NUMBER_CELL = "text-align: right; padding-right: 12px; white-space: nowrap"


def phase_table(rows) -> str:
    lines = ['<table class="default"><tr><th>From</th><th>For</th>'
             '<th>What the game was doing</th></tr>']
    for start, length, what, held in rows:
        if held and what == AT_PROMPT:
            note = f" -- shown for {held:.1f}s here"
        elif held:
            note = f" -- shown for {held:.1f}s here; the game waits for as long as it takes"
        else:
            note = ""
        if length == 0 and what.startswith("at the prompt"):
            what, span = "the next prompt: the end", ""
        else:
            span = f"{length:.2f}s"
        lines.append(f'<tr><td style="{NUMBER_CELL}">{start:.2f}s</td>'
                     f'<td style="{NUMBER_CELL}">{span}</td><td>{what}{note}</td></tr>')
    lines.append("</table>")
    return "".join(lines)


# --------------------------------------------------------------------------
# The scenes.
# --------------------------------------------------------------------------

def _require(ok: bool, what: str) -> None:
    if not ok:
        raise RuntimeError(what)


def opening(log) -> dict:
    """From the title screen to the first prompt."""
    game = Game()
    _require(game.hold([], 5.0, TITLE_WAIT), "the title screen never came")
    game.film = [game.frame()]
    holds = {0: 3000.0}

    def on_wait(g):
        holds[len(g.film) - 1] = 1500.0

    game.press_at_title()
    _require(game.to_prompt(on_wait=on_wait) == "ready", "the opening did not end at a prompt")
    return {"film": game.film, "holds": holds, "events": game.events}


def _picture_bytes(game: Game, location: int) -> tuple[int, int, int]:
    """Where a location's picture stream starts, and its first two bytes:
    the border and the attribute CLEAR_CANVAS starts the picture with."""
    stream = next(value for key, value, _ in bh.keyed_table(game.memory, PICTURE_TABLE)
                  if key == location)
    return stream, game.memory[stream], game.memory[stream + 1]


def clearing(log) -> dict:
    """Into the trolls' clearing at night and straight out, WAIT until dawn,
    and back in by day -- one game, typed a key at a time."""
    game = Game()
    game.start()
    for command in ("OPEN DOOR", "EAST"):
        _require(game.say(command) == "ready", f"{command} did not come back to a prompt")
    _require(game.memory[PLAYER_WHERE] == 4, "not in the lonelands")
    stream, *night = _picture_bytes(game, TROLLS_CLEARING)
    marks = []

    def on_wait(g):
        marks.append(len(g.film) - 1)

    # In, at night.
    game.film = []
    game.events = []
    game.type_line("EAST")
    _require(game.to_prompt(on_wait=on_wait) == "ready", "entering the clearing did not end at a prompt")
    _require(game.memory[PLAYER_WHERE] == TROLLS_CLEARING, "not in the clearing")
    enter_film, enter_events = game.film, game.events
    night_index = marks[0]
    story_end, story_screen = game.t, bytes(game.memory[0x4000:0x5B00])
    # Straight out, and WAIT for the dawn.
    game.film = None
    _require(game.say("SOUTHEAST") == "ready", "SOUTHEAST did not come back")
    _require(game.memory[PLAYER_WHERE] == 9, "not in Rivendell")
    turns_after = 1
    dawn = None
    while dawn is None and turns_after < 8:
        game.film = []
        game.events = []
        game.type_line("WAIT")
        _require(game.to_prompt() == "ready", "WAIT did not come back")
        turns_after += 1
        if [game.memory[stream], game.memory[stream + 1]] != night:
            dawn = (game.film, game.events)
    _require(dawn is not None, "no dawn")
    day = [game.memory[stream], game.memory[stream + 1]]
    records = game.records()
    trolls_dead = all(game.memory[records[n] + 7] & DEAD for n in TROLLS)
    # Back in, by day.
    marks.clear()
    game.film = []
    game.events = []
    game.type_line("WEST")
    _require(game.to_prompt(on_wait=on_wait) == "ready", "going back did not end at a prompt")
    _require(game.memory[PLAYER_WHERE] == TROLLS_CLEARING, "not back in the clearing")
    return {"enter_film": enter_film, "enter_events": enter_events, "night_index": night_index,
            "story_end": story_end, "story_screen": story_screen, "inputs": list(game.inputs),
            "dawn_film": dawn[0], "dawn_events": dawn[1], "turns_after": turns_after,
            "return_film": game.film, "return_events": game.events, "day_index": marks[0],
            "stream": stream, "night": night, "day": day, "trolls_dead": trolls_dead}


def story_letters(scene: dict) -> list:
    """Play the clearing's game again, from START with the same keys, to the
    end of the turn that entered the clearing, stopping at every character
    PRINT_CHAR really prints (past PRINT_GATE) into the story window after
    the picture's key: (T-state, character, the screen before it is drawn)."""
    from skoolkit.simutils import A

    replay = Game()
    printed = []
    start = scene["enter_film"][scene["night_index"]].t

    def seen(g):
        if g.t >= start and not g.memory[INPUT_STYLE]:
            printed.append((g.t, g.sim.registers[A], g.frame()))

    replay.replay(scene["inputs"], scene["story_end"], PRINT_SHOWN, seen)
    _require(replay.t == scene["story_end"] and replay.pc == READ_LINE_READY,
             "the replay of the clearing ended somewhere else")
    _require(bytes(replay.memory[0x4000:0x5B00]) == scene["story_screen"],
             "the replay of the clearing drew something else")
    return printed


FIGHT_TURNS = 5
ELROND = 0x41


def fight(log) -> dict:
    """To Rivendell (E, E, SE -- through the clearing and out) and ATTACK
    ELROND, turn after turn, bare-handed; then the same game played again,
    stopped at every blow, to read each blow and guard."""
    from skoolkit.simutils import A, B

    game = Game()
    game.start()
    for command in ("OPEN DOOR", "EAST", "EAST", "SOUTHEAST"):
        _require(game.say(command) == "ready", f"{command} did not come back to a prompt")
    records = game.records()
    _require(game.memory[PLAYER_WHERE] == 9 and game.memory[records[ELROND] + 16] == 9,
             "the player and Elrond are not both in Rivendell")

    def stats():
        return {n: (game.memory[records[n] + 5], game.memory[records[n] + 6],
                    game.memory[records[n] + 7]) for n in (0, ELROND)}

    before = stats()
    game.film = [game.frame()]
    game.events = []
    turns = []
    for _ in range(FIGHT_TURNS):
        start = game.t
        result = game.say("ATTACK ELROND")
        turns.append({"start": start, "end": game.t, "result": result, "after": stats()})
        if result != "ready":
            break
    blows = []

    def seen(g):
        blows.append({"t": g.t, "by": g.memory[ACTING], "at": g.memory[TARGET],
                      "blow": g.sim.registers[B], "guard": g.sim.registers[A]})

    replay = Game()
    replay.replay(game.inputs, game.t, BLOW_AND_GUARD, seen)
    _require(replay.t == game.t and list(replay.memory) == list(game.memory),
             "the fight played again came out differently")
    for turn in turns:
        turn["blows"] = [b for b in blows if turn["start"] <= b["t"] < turn["end"]]
    # The walk passed through the trolls' clearing, and their dawn comes
    # four turns later -- in the middle of the fight.
    dawned = all(game.memory[records[n] + 7] & DEAD for n in TROLLS)
    return {"film": game.film, "events": game.events, "turns": turns, "before": before,
            "dawned": dawned}


ROAMING_TURNS = 50


def roaming(log) -> dict:
    """The game left alone from the first prompt: every turn a WAIT the game
    types itself when no key comes, with everyone's place read off their
    records after each. The first such turn is filmed."""
    game = Game()
    game.start()
    records = game.records()
    cast = [0] + sorted(n for n in records if n >= 0x3C)

    def places():
        return {n: (game.memory[records[n] + 16], game.memory[records[n] + 1],
                    game.memory[records[n] + 7]) for n in cast}

    def in_story():
        return {game.memory[CHARACTERS + 7 * i] for i in range(17)} - {0}

    at, times, story = [places()], [game.t], [in_story()]
    game.film = [game.frame()]
    game.events = []
    first = None
    for _ in range(ROAMING_TURNS):
        result = game.to_prompt(limit=60)
        _require(bytes(game.memory[INPUT_LINE:INPUT_LINE + 5]) == b"WAIT\r",
                 "a turn that was not the game's own WAIT")
        if first is None:
            first = (game.film, game.events)
            game.film = None
        at.append(places())
        times.append(game.t)
        story.append(in_story())
        if result != "ready":
            break
    # What passed between them: the same game played twice more, stopped at
    # every capture and at every blow.
    from skoolkit.simutils import A, B
    happened = []

    def turn_of(t):
        return next(i for i, end in enumerate(times) if end >= t)

    def captured(g):
        if g.t > times[0]:
            happened.append({"turn": turn_of(g.t), "t": g.t, "what": "capture", "by": g.memory[ACTING],
                             "at": g.memory[TARGET], "to": g.sim.registers[B]})

    def blow(g):
        if g.t > times[0]:
            happened.append({"turn": turn_of(g.t), "t": g.t, "what": "blow", "by": g.memory[ACTING],
                             "at": g.memory[TARGET], "blow": g.sim.registers[B],
                             "guard": g.sim.registers[A]})

    for watch, seen in ((CAPTURED, captured), (BLOW_AND_GUARD, blow)):
        replay = Game()
        replay.replay(game.inputs, game.t, watch, seen)
        _require(replay.t == game.t and list(replay.memory) == list(game.memory),
                 "the roaming game played again came out differently")
    happened.sort(key=lambda e: e["t"])
    return {"at": at, "times": times, "story": story, "cast": cast,
            "first_film": first[0], "first_events": first[1], "happened": happened}


def eaten(log) -> dict:
    """Into the trolls' clearing and WAIT there: a troll eats the player. A
    key at the end starts a new game, filmed to its first prompt."""
    game = Game()
    game.start()
    for command in ("OPEN DOOR", "EAST", "EAST"):
        _require(game.say(command) == "ready", f"{command} did not come back to a prompt")
    _require(game.memory[PLAYER_WHERE] == TROLLS_CLEARING, "not in the clearing")
    game.film = [game.frame()]
    game.events = []
    game.type_line("WAIT")
    _require(game.to_prompt() == "over", "the player was not eaten")
    records = game.records()
    killed = [n for n in TROLLS if game.memory[records[n] + 7] & DEAD]
    strength = {n: game.memory[records[n] + 5] for n in TROLLS}
    holds = {len(game.film) - 1: 2500.0}
    game.note("key")
    # The key that ends WAIT_AND_RESTART is still down when NEW_GAME reaches
    # the title's key wait, so the new game goes straight on; let go there.
    _require(game.hold(["SPACE"], 1.0, TITLE_KEY_SEEN), "no new game")
    game.keys([])

    def on_wait(g):
        holds[len(g.film) - 1] = 1500.0

    _require(game.to_prompt(on_wait=on_wait) == "ready", "the new game did not come to a prompt")
    return {"film": game.film, "events": game.events, "holds": holds, "killed": killed,
            "strength": strength}


def pause(log) -> dict:
    """PAUSE at the first prompt: a green border until a key."""
    game = Game()
    game.start()
    game.film = [game.frame()]
    game.events = []
    game.type_line("PAUSE")
    game.run(1.0)
    _require(game.tracer.border == 4 and game.in_loop((0x84C2, 0x84CA)),
             f"PAUSE is not waiting with a green border (PC ${game.pc:04X})")
    game.note("key")
    game.hold(["SPACE"], 0.1)
    game.keys([])
    _require(game.to_prompt() == "ready", "PAUSE did not come back to a prompt")
    return {"film": game.film, "events": game.events}


# --------------------------------------------------------------------------
# The map of who is where.
# --------------------------------------------------------------------------

# How each character is marked on the map: a label of this page's own and a
# colour, by object number. The names beside them in the key are the game's.
MARKS = {
    0x00: ("Y", (200, 0, 0)),       # the player: "you"
    0x3E: ("G", (30, 70, 210)),     # Gandalf
    0x3F: ("Th", (215, 110, 0)),    # Thorin
    0x40: ("WE", (0, 140, 150)),    # the wood elf
    0x41: ("El", (140, 0, 170)),    # Elrond
    0x42: ("Bu", (120, 120, 120)),  # the butler
    0x43: ("Wa", (0, 0, 0)),        # the vicious warg
    0x44: ("Go", (120, 120, 0)),    # Gollum
    0x46: ("Ba", (0, 0, 120)),      # Bard
    0x3C: ("Dr", (190, 0, 70)),     # the dragon
    0x47: ("T1", (130, 75, 25)),    # the hideous troll
    0x48: ("T2", (130, 75, 25)),    # the vicious troll
}
GOBLINS = (0x3D, 0x45, 0x49, 0x4A, 0x4B, 0x4C)
for _number, _goblin in enumerate(GOBLINS, 1):
    MARKS[_goblin] = (f"g{_number}", (0, 125, 0))
CELL_W, CELL_H = 64, 46
BOX_W, BOX_H = 56, 38
MAP_MARGIN = 12
TURN_MS, FIRST_MS, LAST_MS = 700, 2000, 3000


def _font(size: int):
    from PIL import ImageFont
    try:
        return ImageFont.load_default(size=size)
    except TypeError:           # a Pillow without FreeType sizes
        return ImageFont.load_default()


def happening(event: dict, names: dict, room_name: dict) -> str:
    """One capture or blow from the roaming run, in words."""
    by, at = names[event["by"]], names[event["at"]] if event["at"] else "you"
    if event["what"] == "capture":
        return f"{by} captures {at}, into {room_name.get(event['to'], event['to'])} ({event['to']})"
    margin = event["blow"] - event["guard"]
    result = "wasted" if margin <= 0 else "a kill" if margin > 16 else f"a wound, margin {margin}"
    return f"{by} attacks {at}: blow {event['blow']}, guard {event['guard']}, {result}"


def map_frames(scene: dict, rooms: dict, placed: dict, names: dict, dark: set,
               room_name: dict) -> list[tuple]:
    """A picture of the map per turn: every location a box at its place on
    the site's map (hobbit_pages.map_layout), the ways between them, and every
    character a disc in the box it is in -- hollow while its CHARACTERS slot
    is still empty, crossed out once dead -- with a line from where it was
    the turn before if it moved."""
    from PIL import Image, ImageDraw

    xs = [x for x, _ in placed.values()]
    ys = [y for _, y in placed.values()]
    left, top = min(xs), min(ys)
    header = 44
    cast = scene["cast"]
    key_rows = (len(cast) + 5) // 6
    width = (max(xs) - left + 1) * CELL_W + 2 * MAP_MARGIN
    height = header + (max(ys) - top + 1) * CELL_H + 2 * MAP_MARGIN + key_rows * 18 + 8
    small, label, title = _font(10), _font(9), _font(14)

    def box(location):
        x, y = placed[location]
        bx = MAP_MARGIN + (x - left) * CELL_W + (CELL_W - BOX_W) // 2
        by = header + MAP_MARGIN + (y - top) * CELL_H + (CELL_H - BOX_H) // 2
        return bx, by

    def centre(location):
        bx, by = box(location)
        return bx + BOX_W // 2, by + BOX_H // 2

    base = Image.new("RGB", (width, height), (215, 215, 215))
    draw = ImageDraw.Draw(base)
    draw.fontmode = "1"
    drawn = set()
    for here, room in rooms.items():
        for _, direction, _, there in room["exits"]:
            if direction and there in placed and here in placed and there != here:
                pair = (min(here, there), max(here, there))
                if pair not in drawn:
                    drawn.add(pair)
                    draw.line([centre(here), centre(there)], fill=(165, 165, 165), width=1)
    for location in placed:
        bx, by = box(location)
        fill = (150, 150, 150) if location in dark else (240, 240, 240)
        draw.rectangle([bx, by, bx + BOX_W, by + BOX_H], fill=fill, outline=(60, 60, 60))
        draw.text((bx + 2, by + 1), str(location), fill=(0, 0, 0), font=small)
    key_top = header + (max(ys) - top + 1) * CELL_H + 2 * MAP_MARGIN
    for i, number in enumerate(cast):
        mark, colour = MARKS[number]
        kx = MAP_MARGIN + (i % 6) * ((width - 2 * MAP_MARGIN) // 6)
        ky = key_top + (i // 6) * 18
        draw.ellipse([kx, ky, kx + 14, ky + 14], fill=colour)
        draw.text((kx + 7, ky + 7), mark, fill=(255, 255, 255), font=label, anchor="mm")
        draw.text((kx + 19, ky + 1), names[number], fill=(0, 0, 0), font=small)

    frames = []
    at, times, story = scene["at"], scene["times"], scene["story"]
    for turn in range(len(at)):
        image = base.copy()
        draw = ImageDraw.Draw(image)
        draw.fontmode = "1"
        seconds = (times[turn] - times[0]) / bh.TSTATES_PER_SECOND
        text = (f"Turn {turn} of {len(at) - 1}: {int(seconds // 60)}m {seconds % 60:04.1f}s "
                "of game time" if turn else "The first prompt, before any turn of waiting")
        draw.text((MAP_MARGIN, 6), text, fill=(0, 0, 0), font=title)
        news = [happening(e, names, room_name) for e in scene["happened"] if e["turn"] == turn]
        if news:
            draw.text((MAP_MARGIN, 25), "This turn: " + "; ".join(news), fill=(170, 0, 0), font=small)
        if turn:
            for number in cast:
                was, now = at[turn - 1][number][0], at[turn][number][0]
                if was != now and was in placed and now in placed:
                    draw.line([centre(was), centre(now)], fill=MARKS[number][1], width=3)
        here: dict[int, list[int]] = {}
        for number in cast:
            here.setdefault(at[turn][number][0], []).append(number)
        for location, numbers in here.items():
            if location not in placed:
                continue
            bx, by = box(location)
            per_row = 4 if len(numbers) > 6 else 3
            size = 12 if len(numbers) > 6 else 15
            for i, number in enumerate(numbers):
                mark, colour = MARKS[number]
                cx = bx + 4 + (i % per_row) * (size + 2) + (BOX_W - 8 - per_row * (size + 2)) // 2
                cy = by + 11 + (i // per_row) * (size + 1)
                where, holder, flags = at[turn][number]
                if number and number not in story[turn]:
                    draw.ellipse([cx, cy, cx + size, cy + size], fill=(240, 240, 240),
                                 outline=colour, width=2)
                    draw.text((cx + size / 2, cy + size / 2), mark, fill=colour, font=label, anchor="mm")
                else:
                    draw.ellipse([cx, cy, cx + size, cy + size], fill=colour)
                    draw.text((cx + size / 2, cy + size / 2), mark, fill=(255, 255, 255),
                              font=label, anchor="mm")
                if flags & DEAD:
                    draw.line([cx, cy, cx + size, cy + size], fill=(255, 0, 0), width=2)
                    draw.line([cx, cy + size, cx + size, cy], fill=(255, 0, 0), width=2)
        ms = FIRST_MS if turn == 0 else TURN_MS
        if turn == len(at) - 1:
            ms += LAST_MS
        frames.append((image, ms))
    return frames


# --------------------------------------------------------------------------
# The page.
# --------------------------------------------------------------------------

def _ordinal(n: int) -> str:
    return {1: "first", 2: "second", 3: "third", 4: "fourth", 5: "fifth", 6: "sixth",
            7: "seventh"}.get(n, f"{n}th")


def _rrca(value: int) -> int:
    return ((value >> 1) | ((value & 1) << 7)) & 0xFF


def _wound(strength: int, defence: int, margin: int) -> tuple[int, int]:
    """What DO_ATTACK's wound does to a target's strength and defence, done
    the way its instructions at $91D2-$91F8 do it: the margin doubled (RLCA),
    rotated right twice, and each result's complement added, kept only when
    the addition carries -- that is, when it does not go below zero."""
    a = _rrca(_rrca((margin << 1) & 0xFF))
    total = (~a & 0xFF) + strength
    if total > 0xFF:
        strength = total & 0xFF
    a = _rrca(a)
    total = (~a & 0xFF) + defence
    if total > 0xFF:
        defence = total & 0xFF
    return strength, defence


def _check_wear(scene: dict) -> bool:
    """Whether every strength and defence read after each turn of the fight
    is what _wound gives for that turn's blows, from the values before."""
    now = {n: list(v[:2]) for n, v in scene["before"].items()}
    for turn in scene["turns"]:
        for b in turn["blows"]:
            margin = b["blow"] - b["guard"]
            if 0 < margin <= 16 and b["at"] in now:
                now[b["at"]] = list(_wound(*now[b["at"]], margin))
        for n, values in turn["after"].items():
            if list(values[:2]) != now[n]:
                return False
    return True


def _flashing(film: list[Frame]) -> int:
    return sum(1 for f in film if any(a & 0x80 for a in f.screen[0x1800:]))


def _entry_starts() -> frozenset:
    skool = bh.OUT_DIR / "hobbit.skool"
    if not skool.exists():
        return frozenset()
    return frozenset(int(m, 16) for m in re.findall(r"^[bcgistuw@]?\$([0-9A-F]{4})",
                                                     skool.read_text(encoding="utf-8"), re.M))


def _links(text: str, starts: frozenset) -> str:
    """#R$ADDR only where ADDR starts an entry in hobbit.skool; plain $ADDR
    (and the label in brackets, if any, kept as text) otherwise."""
    def one(m):
        address = int(m.group(1), 16)
        if address in starts:
            return m.group(0)
        return f"${m.group(1)}" + (f" ({m.group(2)})" if m.group(2) else "")
    return re.sub(r"#R\$([0-9A-F]{4})(?:\(([^)]*)\))?", one, text)


def _img(name: str, width: int, height: int, alt: str) -> str:
    return (f'<img src="{PAGE_IMAGES}/{name}" width="{width}" height="{height}" '
            f'alt="{_esc(alt)}" style="max-width: 100%; height: auto; image-rendering: pixelated">')


def _seconds(film: list[Frame]) -> float:
    return (film[-1].t - film[0].t) / bh.TSTATES_PER_SECOND


def _cap_long(frames: list[tuple], longest: float, shown: float) -> tuple[list[tuple], list[float]]:
    """Merge identical pictures in a row, and show any that lasts more than
    `longest` ms for `shown` ms instead; returns the frames and the real
    lengths of those shortened."""
    merged: list[list] = []
    for image, ms in frames:
        if merged and merged[-1][0].tobytes() == image.tobytes():
            merged[-1][1] += ms
        else:
            merged.append([image, ms])
    cut = []
    for pair in merged:
        if pair[1] > longest:
            cut.append(pair[1] / 1000)
            pair[1] = shown
    return [tuple(p) for p in merged], cut


def build(html_dir: Path, log=print) -> dict[str, str]:
    """Play the scenes, write the GIFs into html_dir/images/animations, and
    return the Animations section."""
    from PIL import Image

    import hobbit_pages as hp

    out_dir = html_dir / IMAGE_DIR
    out_dir.mkdir(parents=True, exist_ok=True)
    log("Playing the animations in the game's own code...")
    starts = _entry_starts()
    tape = bh.game_memory(bh.OUT_DIR / "hobbit.z80")
    rooms = {k: r for k, r in bh.room_records(tape).items() if k}
    room_name = {k: bh.name_of(tape, r["start"] + 2) for k, r in rooms.items()}
    records = {r["number"]: r["start"] for r in bh.object_records(tape)}
    names = {n: bh.name_of(tape, s + 8) for n, s in records.items()}

    def place(location: int) -> str:
        if location in room_name:
            return (f'<a href="locations.html&#35;loc{location}">{_esc(room_name[location])}</a> '
                    f'({location})')
        return str(location)

    def who(number: int) -> str:
        return f'<a href="characters.html&#35;obj{number}">{_esc(names[number])}</a>'

    streams = [value for _, value, _ in bh.keyed_table(tape, PICTURE_TABLE)]
    flashing = sum(1 for stream in streams if tape[stream + 1] & 0x80)
    body = []
    body.append(
        "<p>The Hobbit has no sprites and no frame loop: what moves on its screen is a picture "
        "being drawn, the story being typed out and scrolled, and the odd change of border. The "
        'pictures being drawn are on the <a href="locations.html">Locations</a> page (each '
        "picture's own entry in the listing shows its GIF), and the <a href=\"patches.html\">"
        "Patches</a> page has the original and the fast-drawing patch side by side. This page has "
        "the rest, and one animation the screen never shows: the other characters walking about "
        "the map while the player waits.</p>")
    body.append(
        "<p>Every animation here is a game played in SkoolKit's simulator when these pages were "
        "built, from the snapshot the tape leaves (the same start as <code>scripts/hobbit_drive.py"
        "</code>): commands typed a key at a time, held a tenth of a second with a gap of 0.06s, "
        "as the build's own playthrough types them, so the game echoes them; each key wait "
        "answered as soon as the game reaches it; and the screen memory and the border read at "
        "every frame interrupt, 69888 T-states apart. Each frame of a GIF lasts as long as the "
        "game took, at 3.5MHz and without the memory contention of a real Spectrum, which would "
        "be a little slower; where the game waits for a key for as long as it takes, the GIF holds "
        "the picture for a second or two and the table under it says so. Identical pictures in a "
        "row are one frame. The tables say what the game was doing, from where the program "
        "counter was at each frame interrupt.</p>")

    # ------------------------------------------------------------ opening
    log("  the opening")
    scene = opening(log)
    film, holds = scene["film"], scene["holds"]
    title_flash = sum(1 for a in film[0].screen[0x1800:] if a & 0x80)
    flashing += _flashing(film)
    save_gif(out_dir / "opening.gif", gif_frames(film, holds))
    started = phases(film, scene["events"], holds)
    picture = [p for p in started if p[2].startswith("drawing the picture")]
    body.append('<h3 id="opening">The opening</h3>')
    body.append("<p>" + _img("opening.gif", 576, 448, "The title screen, then Bag End drawn and described") + "</p>")
    body.append(
        "<p>The title is the loading screen, still on the screen from the tape: the game draws "
        "nothing of it. #R$6C00(START) keeps a copy of the objects, rooms and variables for new "
        "games, and NEW_GAME makes the border black and waits at $6C6D for a key -- N held "
        "there turns the pictures off for the game. Nothing on the title moves: "
        f"{'no attribute has FLASH set' if not title_flash else f'{title_flash} attributes have FLASH set'}"
        " and the only code running is the key test. Then #R$6FD3(CLEAR_SCREEN), the wavy "
        "#R$6DCC(DIVIDER) across row 18, \"&gt; LOOK\" printed in the input window, and the "
        "first turn is that LOOK (#R$8C4B(DO_LOOK), #R$9630(DESCRIBE_ROOM), "
        "#R$965B(DESCRIBE_LOCATION)): the room's description goes into the story window first, "
        "then the picture is drawn -- "
        f"{picture[0][1]:.1f}s of it here -- then the game waits for a key, and only then does "
        "the rest of the description come, scrolling the story up over the picture. The "
        f"whole opening, from the key to the first prompt, took {_seconds(film[1:]):.1f}s.</p>")
    body.append(phase_table(started))

    # ------------------------------------------------------------ the clearing
    log("  the trolls' clearing")
    scene = clearing(log)
    enter, night_index = scene["enter_film"], scene["night_index"]
    story_film = enter[night_index:]
    flashing += _flashing(enter) + _flashing(scene["dawn_film"]) + _flashing(scene["return_film"])
    printed = story_letters(scene)
    save_gif(out_dir / "story.gif", gif_frames(story_film, {0: 1500.0}))
    told = phases(story_film, scene["enter_events"], {0: 1500.0})
    pauses = [p for p in told if p[2].startswith("the pause")]
    letters = [(t, c) for t, c, _ in printed]
    lines = sum(1 for _, c in letters if c == 13)
    gaps = sorted(b[0] - a[0] for a, b in zip(letters, letters[1:]) if a[1] != 13)
    per_letter = gaps[len(gaps) // 2]
    per_frame = {}
    for t, c in letters:
        per_frame[t // FRAME_TSTATES] = per_frame.get(t // FRAME_TSTATES, 0) + 1
    # A few lines a letter at a time, slowed: from the line that ends at the
    # first pause to the end of the second line after it.
    SLOW = 5
    crs = [i for i, (_, c) in enumerate(letters) if c == 13]
    paused = [i for i in crs if i + 1 < len(letters) and letters[i + 1][0] - letters[i][0] > 0.3 * bh.TSTATES_PER_SECOND]
    first = crs[crs.index(paused[0]) - 1] + 1 if paused and crs.index(paused[0]) else 0
    last = crs[min(len(crs) - 1, crs.index(paused[0]) + 2)] if paused else len(letters) - 1
    slow = []
    crop = (0, 96, 256, 152)
    for i in range(first, last + 2):
        if i >= len(printed):
            break
        t, _, frame = printed[i]
        image = screen_image(frame, 0).crop(crop)
        next_t = printed[i + 1][0] if i + 1 < len(printed) else scene["story_end"]
        slow.append((image, (next_t - t) / T_PER_MS * SLOW))
    slow[-1] = (slow[-1][0], slow[-1][1] + 2000)
    save_gif(out_dir / "story_letters.gif", slow, scale=3)
    slow_ms = sum(ms for _, ms in slow) - 2000
    body.append('<h3 id="story">The story being told</h3>')
    body.append("<p>" + _img("story.gif", 576, 448, "The story of arriving in the trolls' clearing, told over its picture") + "</p>")
    body.append(
        "<p>The turn that walks into the trolls' clearing, from its picture finished and waiting "
        "for a key to the next prompt. Everything the story says goes through #R$858B(PRINT_CHAR) "
        "to #R$86A1(STORY_CHAR), a character at a time in the game's own six-pixel font "
        "(#R$87C9(NARROW_CHAR)), always on row 17; at the end of each line #R$876B(SCROLL_STORY) "
        "moves rows 0-17 up by one, picture and all, which is how the story climbs over the "
        "picture. The input window below the divider is the ROM's font "
        "(#R$85B7(INPUT_CHAR)) and does not move. #R$6D13(MAIN_LOOP) lets a turn's first nine "
        "lines out at once (NO_PAUSE_LINES, #R$B716); after that each line waits about half a "
        "second, or until a key, before it scrolls.</p>")
    body.append(
        f"<p>Measured in the same game played again and stopped at every character printed "
        f"past #R$8576(PRINT_GATE): {len(letters)} characters and {lines} line ends in the story "
        f"window this turn, one every {per_letter} T-states ({per_letter / T_PER_MS:.1f}ms) "
        f"while a line is going out -- up to {max(per_frame.values())} in one fiftieth of a "
        f"second, so on the screen a line appears in two or three frames rather than a letter "
        f"at a time. {len(pauses)} lines waited, to the nearest frame, "
        f"{', '.join(f'{p[1]:.2f}s' for p in pauses)} (the loop at $86DF: 32768 polls of the "
        f"keyboard at 62 T-states, 0.58s). Below, {len([1 for _, c in letters[first:last + 1] if c == 13])} "
        f"of those lines at a fifth of the speed, a frame for every character, "
        f"{slow_ms / 1000:.1f}s where the game took {slow_ms / SLOW / 1000:.2f}s:</p>")
    body.append("<p>" + _img("story_letters.gif", 768, 168, "Lines of the story a letter at a time, slowed") + "</p>")
    body.append(phase_table(told))

    # night and day
    # The picture's canvas and a strip of border round it, to show the two
    # side by side at twice the size.
    strip = 4
    canvas = (BORDER - strip, BORDER - strip, BORDER + 256 + strip, BORDER + 128 + strip)
    day_film = scene["return_film"]
    for name, frame in (("clearing_night.png", enter[night_index]),
                        ("clearing_day.png", day_film[scene["day_index"]])):
        still = screen_image(frame).crop(canvas)
        still.resize((still.width * 2, still.height * 2), Image.NEAREST).save(out_dir / name)
    still_w, still_h = 2 * (256 + 2 * strip), 2 * (128 + 2 * strip)
    dawn = scene["dawn_film"] + day_film
    dawn_holds = {len(scene["dawn_film"]) + scene["day_index"]: 1500.0}
    save_gif(out_dir / "dawn.gif", gif_frames(dawn, dawn_holds))
    dawn_events = scene["dawn_events"] + scene["return_events"]
    stream, (nb, na), (db, da) = scene["stream"], scene["night"], scene["day"]
    colour = bh.COLOURS
    body.append('<h3 id="dawn">The trolls\' clearing: night into day</h3>')
    body.append("<p>" + _img("clearing_night.png", still_w, still_h, "The trolls' clearing at night")
                + " " + _img("clearing_day.png", still_w, still_h, "The trolls' clearing by day") + "</p>")
    body.append(
        f"<p>The same picture, #R${stream:04X}, drawn on the way in and after the dawn, each "
        f"as it stood finished, waiting for a key, with the border it set. The picture is not redrawn at dawn and has no second version: its first two "
        f"bytes, the border and the attribute #R$820B(CLEAR_CANVAS) fills the canvas with before "
        f"the stream runs, are {nb} and ${na:02X} on the tape ({colour[nb]} border, "
        f"{colour[(na >> 3) & 7]} paper, {colour[na & 7]} ink) and "
        f"#R$A971(TROLLS_TURN_TO_STONE) writes {db} and ${da:02X} over them "
        f"({colour[db]} border, {colour[(da >> 3) & 7]} paper, {colour[da & 7]} ink); "
        f"the rest of the stream is the same. Its lines are drawn in black, and "
        f"#R$81B5(PLOT_PIXEL) flips a cell's ink to the opposite colour when it would be the "
        f"same as the paper, so on the black canvas every line and fill comes out white, and on "
        f"cyan black. NEW_GAME writes the night's zeros back at $6C2B, so every game starts in "
        f"the dark. The bytes were read before and after the dawn turn in the game below.</p>")
    body.append("<p>" + _img("dawn.gif", 576, 448, "Day dawns while the player waits in Rivendell; back in the clearing") + "</p>")
    body.append(
        f"<p>One game: OPEN DOOR, EAST, EAST into the clearing (its story is the animation "
        f"above), SOUTHEAST at once to Rivendell, then WAIT. The trolls' script counts the turns "
        f"itself (#R$A94E(TROLLS_EAT) each turn, a pause when the player is not there), and "
        f"the dawn came at the end of the {_ordinal(scene['turns_after'])} turn after the one that "
        f"entered: the GIF starts with that WAIT being typed. The dawn's words are printed "
        f"wherever the player is (the routine turns printing on first); both trolls were "
        f"{'dead' if scene['trolls_dead'] else 'NOT dead'} after it (flag bit 3 of their records). "
        f"Then WEST, back into the clearing, and its picture drawn by day.</p>")
    body.append(phase_table(phases(dawn, dawn_events, dawn_holds)))

    # ------------------------------------------------------------ fight
    log("  a fight")
    scene = fought = fight(log)
    film = scene["film"]
    flashing += _flashing(film)
    save_gif(out_dir / "fight.gif", gif_frames(film))
    body.append('<h3 id="fight">A fight: attacking Elrond</h3>')
    body.append("<p>" + _img("fight.gif", 576, 448, "ATTACK ELROND, five turns") + "</p>")
    body.append(
        f"<p>Nothing staged: a new game, OPEN DOOR, EAST, EAST, SOUTHEAST -- into Rivendell, "
        f"which has no picture, so the story fills the screen -- and ATTACK ELROND typed "
        f"{len(scene['turns'])} times, bare-handed. Elrond is on the player's side and the elves'; "
        f"attacking him takes him off the player's (#R$914A(SAME_SIDE)), and his script's "
        f"reaction to ATTACK WITH is to hit back. Each blow is #R$9171(DO_ATTACK): the "
        f"attacker's strength jostled by -10 to +10 (#R$9213(JOSTLE)) against the target's "
        f"defence jostled the same way; no stronger is wasted, more than 16 stronger kills, and "
        f"anything between wounds, wearing the target's strength and defence down -- "
        f"erratically, because the halving is a rotate (see "
        f'<a href="bugs.html">Bugs</a>). The same game played again with the same keys, '
        f"stopped at $91C1 where the blow and guard are both in hand, gave:</p>")
    rows = ['<table class="default"><tr><th>Turn</th><th>Blow by</th><th>At</th><th>Blow</th>'
            '<th>Guard</th><th>Result</th><th>After the turn: you</th><th>Elrond</th></tr>']
    before = scene["before"]
    rows.append(f"<tr><td>before</td><td></td><td></td><td></td><td></td><td></td>"
                f"<td>{before[0][0]}/{before[0][1]}</td><td>{before[ELROND][0]}/{before[ELROND][1]}</td></tr>")
    for n, turn in enumerate(scene["turns"], 1):
        after = turn["after"]
        for k, b in enumerate(turn["blows"]):
            margin = b["blow"] - b["guard"]
            result = ("wasted" if margin <= 0 else "a kill" if margin > 16 else
                      f"a wound, margin {margin}" + (" (odd)" if margin & 1 else ""))
            cells = [str(n) if k == 0 else "", who(b["by"]) if b["by"] else "you",
                     who(b["at"]) if b["at"] else "you", str(b["blow"]), str(b["guard"]), result]
            if k == len(turn["blows"]) - 1:
                cells += [f"{after[0][0]}/{after[0][1]}", f"{after[ELROND][0]}/{after[ELROND][1]}"]
            else:
                cells += ["", ""]
            rows.append("<tr>" + "".join(f"<td>{c}</td>" for c in cells) + "</tr>")
    rows.append("</table>")
    body.append("".join(rows))
    worked = _check_wear(scene)
    wasted = sum(1 for turn in scene["turns"] for b in turn["blows"]
                 if b["by"] == ELROND and b["blow"] <= b["guard"])
    by_elrond = sum(1 for turn in scene["turns"] for b in turn["blows"] if b["by"] == ELROND)
    body.append(
        f"<p>Strength/defence are bytes 5 and 6 of each record, read after each turn. "
        f"{'Every change in them is' if worked else 'NOT every change in them is'} what "
        f"DO_ATTACK's arithmetic gives for the margins above (worked out from the instructions "
        f"at $91D2-$91F8 and compared): a margin m is doubled, rotated right twice and taken "
        f"off with CPL and ADD, written back only if that does not go below zero -- so an even "
        f"m takes m/2 + 1 off the strength and, when m is a multiple of four, m/4 + 1 off the "
        f"defence, while an odd m rotates its low bit into bit 7, over 128, which a strength or "
        f"defence of 64 cannot pay, and does nothing at all. Neither side kills easily: 64 "
        f"against 64, each give or take ten, needs the blow at the top of its range and the "
        f"guard near the bottom of its to beat it by 17. Elrond struck back {by_elrond} times "
        f"and {wasted} of them were wasted.")
    if scene["dawned"]:
        body[-1] += (' The "day dawns" in the middle of the fight is the trolls\' dawn '
                     '(<a href="&#35;dawn">above</a>): the walk to Rivendell went through their '
                     "clearing.")
    body[-1] += "</p>"

    # ------------------------------------------------------------ roaming
    log("  the characters roaming (and the map layout)")
    scene = roam = roaming(log)
    placed = hp.map_layout(rooms)
    dark = {k for k, r in rooms.items() if not tape[r["start"]] & 0x80}
    save_gif(out_dir / "roaming.gif", map_frames(scene, rooms, placed, names, dark, room_name),
             scale=1)
    at, times, cast = scene["at"], scene["times"], scene["cast"]
    turns = len(at) - 1
    per_turn = (times[-1] - times[0]) / turns / bh.TSTATES_PER_SECOND
    movers = [n for n in cast if len({at[i][n][0] for i in range(len(at))}) > 1]
    still = [n for n in cast if n not in movers]
    body.append('<h3 id="roaming">The characters roaming</h3>')
    body.append("<p>" + _img("roaming.gif", 1100, 700, "Where every character is, turn by turn") + "</p>")
    body.append(
        f"<p>A new game left alone at its first prompt in Bag End for {turns} turns -- the first "
        f"LOOK, which the game types itself, is already a turn, so the others have moved once by "
        f"then. Nobody types "
        f"anything: after about 23 seconds with no key #R$7249(GET_KEY) types WAIT itself and "
        f"presses ENTER, so every turn here is the game's own WAIT (checked in "
        f"#R$6FF9(INPUT_LINE) after each), {per_turn:.1f}s of game time apiece, nearly all of it "
        f"the patience running out. After each turn every character's place is read from byte 16 "
        f"of its record (#R$C063(OBJECT_INDEX)). The map is the <a href=\"map.html\">Map</a> "
        f"page's layout, grey boxes the dark places; a line in a character's colour is the way it "
        f"went that turn; a hollow disc is a character whose #R$CACB(CHARACTERS) slot is still "
        f"empty -- not yet in the story, so it does nothing -- and a cross a dead one. The GIF "
        f"shows {TURN_MS / 1000:.1f}s a turn.</p>")
    body.append(
        f"<p>What moves them is each character's own script (#R$980E(CHARACTERS_ACT); the "
        f'<a href="characters.html">Characters</a> page has every script). In this run '
        f"{len(movers)} of the {len(cast)} moved and {len(still)} never did. Thorin's script "
        f"follows the player, who only waited; the characters not yet in the story do nothing "
        f"at all.</p>")
    summary = ['<table class="default"><tr><th></th><th>Character</th><th>In the story</th>'
               '<th>Turns it moved in</th><th>Places it was in</th><th>At the first prompt</th>'
               '<th>Where it ended</th></tr>']
    for number in cast:
        route = [at[i][number][0] for i in range(len(at))]
        moves = sum(1 for a, b in zip(route, route[1:]) if a != b)
        ended = place(route[-1])
        if moves:
            last_move = max(i for i in range(1, len(route)) if route[i] != route[i - 1])
            if last_move < turns:
                ended += f" (from turn {last_move})"
        in_story = "the player" if not number else ("yes" if number in scene["story"][0] else "not yet")
        summary.append(f"<tr><td>{MARKS[number][0]}</td><td>{who(number) if number else 'you'}</td>"
                       f"<td>{in_story}</td><td style=\"{NUMBER_CELL}\">{moves}</td>"
                       f"<td style=\"{NUMBER_CELL}\">{len(set(route))}</td>"
                       f"<td>{place(route[0])}</td><td>{ended}</td></tr>")
    summary.append("</table>")
    body.append("".join(summary))
    happened = scene["happened"]
    captures = [e for e in happened if e["what"] == "capture"]
    blows = [e for e in happened if e["what"] == "blow"]
    body.append(
        f"<p>Between them, found by playing the same game twice more, stopped at every capture "
        f"that was done for real (#R$A3E6(DO_CAPTURE) past its test, at $A41D) and at every blow "
        f"(#R$9171(DO_ATTACK) at $91C1): {len(captures)} capture{'s' if len(captures) != 1 else ''} "
        f"and {len(blows)} blow{'s' if len(blows) != 1 else ''}, none of them seen by the player. "
        f"A capture puts the captive straight into the elves' dungeon or the goblins', with "
        f"everything it carries, without its walking there.</p>")
    if happened:
        body.append("<ul>" + "".join(f"<li>Turn {e['turn']}: {_esc(happening(e, names, room_name))}</li>"
                                     for e in happened) + "</ul>")
    body.append("<p>The whole run, a column a turn; a bold number is a move that turn, and a "
                "place's name is in its tooltip.</p>")
    table = ['<div style="overflow-x: auto"><table class="default" style="font-size: 80%">',
             "<tr><th></th>" + "".join(f"<th>{i}</th>" for i in range(len(at))) + "</tr>"]
    for number in cast:
        cells = []
        for i in range(len(at)):
            location = at[i][number][0]
            moved = i and location != at[i - 1][number][0]
            text = f"<b>{location}</b>" if moved else str(location)
            cells.append(f'<td title="{_esc(room_name.get(location, str(location)))}">{text}</td>')
        table.append(f"<tr><th>{MARKS[number][0]}&nbsp;{_esc(names[number])}</th>" + "".join(cells) + "</tr>")
    table.append("</table></div>")
    body.append("".join(table))

    # ------------------------------------------------------------ eaten
    log("  eaten")
    scene = eaten(log)
    film, holds = scene["film"], scene["holds"]
    flashing += _flashing(film)
    save_gif(out_dir / "eaten.gif", gif_frames(film, holds))
    body.append('<h3 id="eaten">Eaten, and starting again</h3>')
    body.append("<p>" + _img("eaten.gif", 576, 448, "WAIT in the trolls' clearing: eaten, and a new game") + "</p>")
    body.append(
        "<p>A new game, OPEN DOOR, EAST, EAST into the clearing, and WAIT there. On the next turn "
        "the troll's script finds the player where it is (#R$A94E(TROLLS_EAT)) and eats him: "
        "#R$90D2(PLAYER_DIES) prints the end and the score (#R$83F5(SHOW_SCORE)) and waits for a "
        "key. That key goes back into NEW_GAME, which puts back the objects, the rooms and the "
        "variables from the copies #R$6C00(START) made, and -- the key still being down when it "
        "reaches the title's key wait at $6C6D -- starts at once: the screen cleared, Bag End "
        "drawn again, the first LOOK. The title picture is not shown again; it is gone from the "
        "screen.")
    for number in scene["killed"]:
        body[-1] += (f" And the troll that ate him, {_esc(names[number])}, dies of it: "
                     f"#R$92B5(DO_EAT) adds ten to the eater's strength and kills it if that "
                     f"reaches 128, and a troll's is {scene['strength'][number]}.")
    body[-1] += "</p>"
    body.append(phase_table(phases(film, scene["events"], holds)))

    # ------------------------------------------------------------ the rest
    log("  the rest")
    body.append('<h3 id="other">Everything else that moves</h3>')
    # The game typing WAIT itself.
    film = roam["first_film"]
    flashing += _flashing(film)
    frames, cut = _cap_long(gif_frames(film), 5000, 3000)
    save_gif(out_dir / "patience.gif", frames)
    body.append("<p>" + _img("patience.gif", 576, 448, "Nobody at the keyboard: the game types WAIT itself") + "</p>")
    body.append(
        f"<p><b>Nobody at the keyboard.</b> The first turn of the run above: the prompt, "
        f"{', '.join(f'{c:.1f}s' for c in cut)} of nothing (shown here for 3s), then the game "
        f"typing WAIT into the input window itself and the turn that follows. The time is "
        f"#R$B714(PATIENCE), 3000 scans of the keyboard at about 7.8ms each, set by "
        f"#R$6DD6(READ_LINE) for every line; see <a href=\"how-it-works.html\">How it "
        f"works</a>.</p>")
    rows = phases(film, roam["first_events"])
    if cut and rows and rows[0][1] > 5:
        rows[0] = rows[0][:3] + (3.0,)
    body.append(phase_table(rows))
    # Typing, and the cursor.
    film = fought["film"]
    typed = [t for t, e in fought["events"] if e.startswith("typing ")][0]
    end = next(i for i, f in enumerate(film) if f.t > typed and kind_of(f.pc) != AT_PROMPT)
    frames = gif_frames(film[:end + 1], crop=(0, 152, 256, 192), border=0)
    save_gif(out_dir / "typing.gif", frames, scale=3)
    body.append("<p>" + _img("typing.gif", 768, 120, "ATTACK ELROND typed into the input window") + "</p>")
    body.append(
        f"<p><b>Typing, and the cursor.</b> The input window while ATTACK ELROND is typed, at "
        f"the fight's first prompt ({(film[end].t - film[0].t) / bh.TSTATES_PER_SECOND:.1f}s, "
        f"at the typing speed above). #R$6DD6(READ_LINE) echoes each key through "
        f"#R$85B7(INPUT_CHAR) in the ROM's font, capitals always, and INPUT_CHAR draws the "
        f"cursor after it: a +, which the game prints as an ordinary character and never "
        f"flashes. ENTER blanks it, and the window scrolls up a line (#R$860D(SCROLL_INPUT)) when "
        f"a line fills or ends.</p>")
    # PAUSE.
    scene = pause(log)
    film = scene["film"]
    flashing += _flashing(film)
    save_gif(out_dir / "pause.gif", gif_frames(film))
    green = [p for p in phases(film, scene["events"], shortest=1)
             if p[2].startswith("PAUSE: waiting for a key")]
    body.append("<p>" + _img("pause.gif", 576, 448, "PAUSE: a green border until a key") + "</p>")
    body.append(
        f"<p><b>PAUSE.</b> #R$843A(DO_PAUSE) makes the border green and waits for a key "
        f"(#R$84B9(NEW_KEYPRESS)), then for the key to be let go, and makes it white again. "
        f"Typed at the first prompt here; the key came {green[0][1] if green else 0:.1f}s after "
        f"the border went green. The game writes the border in six places, found by searching "
        f"for OUT ($FE): black for the title (NEW_GAME), white in #R$6FD3(CLEAR_SCREEN), the "
        f"picture's own colour in #R$820B(CLEAR_CANVAS), white again in "
        f"#R$969A(WAIT_FOR_ANY_KEY) once the key after a picture comes (the night clearing's "
        f"black border turns white there, in the story animation above), and these two.</p>")
    body.append(
        "<p><b>What does not move.</b> SAVE and LOAD call the ROM's own tape routines, whose "
        "border stripes are the ROM's, not the game's. PRINT sends each story line to a ZX "
        "Printer from #R$8B22(LINE_TO_PRINTER) with nothing on the screen to show for it (and "
        "the simulator has no printer). "
        + (f"No frame filmed for this page has an attribute with FLASH set, and no picture "
           f"starts with one (the second byte of each of the {len(streams)} streams in "
           f"#R$CC00(PICTURE_TABLE))." if not flashing else
           f"{flashing} frames filmed for this page have a FLASH attribute.")
        + "</p>")
    text = _links("\n".join(body), starts)
    for line in text.splitlines():
        if line.startswith((";", "[")):
            raise RuntimeError(f"a section line may not start with that: {line[:40]}")
    return {"Animations": text}
