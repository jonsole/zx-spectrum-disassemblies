"""The Hobbit's "How it works" deep dives: parsing, the characters, fighting,
the messages and the pictures.

build() returns each page's HTML by ref section name, and draws the pictures
into the HTML directory. Nothing here is a transcription of the game: every
table is read from the game's memory as the page is built, every quoted line
is what the game printed, captured at PRINT_CHAR, and every worked example is
the game's own code run in SkoolKit's simulator -- a real game driven by
hobbit_drive.Hobbit, or one of the game's routines called on its own with a
machine set up for it. Where a scene is staged (a strength poked, an object
moved) the page says what was staged and what the game then did.

The prose is written from reading the listing (scripts/hobbit_annotations.ctl
and the code it describes) and the notes in notes/hobbit/, and checked against
what the runs give; the pages say which claims rest on which. Like the rest of
the build, the pictures and the pages are the game's content and are never
committed. The commands typed in the worked examples are the player's words,
not the game's.
"""
from __future__ import annotations

import functools
import html
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import build_hobbit as bh

IMAGE_DIR = "images/howitworks"     # under html_dir
IMAGE_SRC = "../" + IMAGE_DIR       # from the pages, which are in reference/

# --------------------------------------------------------------------------
# Addresses run or read here. See their entries in the listing.
# --------------------------------------------------------------------------

# The main loop and the line.
MAIN_TOKENISE_CALL = 0x6D31     # MAIN_LOOP's CALL TOKENISE
MAIN_TOKEN_BACK = 0x6D34        # ... and just after it: the token in B, C, D
MAIN_PARSE = 0x6D8A             # MAIN_LOOP: the line is tokenised, parse it
MAIN_OBEY_CALL = 0x6D96         # MAIN_LOOP's CALL OBEY
LINE_TAKEN = 0x6D20             # MAIN_LOOP, back from READ_LINE: the line is in
READ_LINE = 0x6DD6
INPUT_LINE = 0x6FF9
TOKENISE = 0x6E97
PUNCTUATION_TOKEN = 0x6F30
MATCH_WORD = 0x6F47
MATCH_WORD_LOOKUP = 0x6F5D      # MATCH_WORD, the typed word copied and measured
TRY_ENTRY = 0x6F72              # MATCH_WORD's way in for each candidate
LETTERS_AGREE = 0x6FBA
TYPED_WORD = 0x707A             # the typed word's letter codes
TYPED_LENGTH = 0x708A
TOKENS = 0x709C
WORD_INDEX = 0x6000
WORD_LIST = 0x6040
SECOND_LIST = 0x67AB

# The parser.
PARSE_COMMAND = 0x7585
CLASS_DISPATCH_JUMP = 0x75D1    # CLASS_DISPATCH's JP (HL)
CLASS_DISPATCH = 0x75C1
PARSER_CLASSES = 0x75D2
NEXT_TOKEN = 0x7873
PHRASE = 0x757A
AND_TOKENS = 0x7574
PARSE_THEN = 0x75FA
PARSE_AND = 0x770B
PARSE_VERB = 0x7733
PARSE_NOUN = 0x77D1
PARSE_ADJECTIVE = 0x77C9
PARSE_ARTICLE = 0x7790
PARSE_ADVERB = 0x76F2
PARSE_PREPOSITION = 0x77A2
PARSE_END = 0x75F6
PARSE_SPECIAL = 0x8251
SPECIAL_WORDS = 0x8271
SPECIAL_QUOTE = 0x8315
ORDER_BEGINS = 0x82FD
WORD_IT = 0x82E2
FILE_PHRASE = 0x782B
STORE_WORD = 0x7918
NOT_ALLOWED_HERE = 0x7929
COPY_VERB_ON = 0x78B7
FRAMES = 0xB800
COMMAND_FRAME = 0xB9C8
FRAME_SIZE = 24
ORDERS = 0xB738
ORDER_SIZE = 25
ORDER_COUNT = 0xB737

# From a frame to an action.
OBEY = 0x7960
OBEY_REAL = 0x7980              # OBEY, the command checked: now for real
TURN_OVER = 0x798B              # OBEY's CALL END_OF_TURN
OBEY_NEXT = 0x798E
PARSE_ACTION = 0x79B6
PATTERN_FOUND = 0x79C4          # PARSE_ACTION, back from MATCH_PATTERN
SEARCH_BEGUN = 0x79E9           # PARSE_ACTION, the code and options set
MATCH_AND_TRY = 0x7A14
MATCH_PATTERN = 0x7B9E
ASSIGN_PHRASES = 0x7C23
PATTERN_FLAGS = 0x70F3
PATTERN_OPTIONS = 0x7B78
TRY_TARGETS = 0x7CFC
TRY_IT = 0x7AED
TRY_IT_DONE = 0x7AF0
HANDLED = 0x94D6
FIND_NAMED_OBJECT = 0x9DD9
NAME_FITS = 0x9E0F              # FIND_NAMED_OBJECT: an object's name fits
NAME_FOUND = 0x9E1D             # ... and what it returns
NAME_MATCHES = 0x71F3
TARGET_TROUBLE = 0x7DBC
NARRATE_ACTION = 0x712B
DO_ACTION = 0x950F
DO_ACTION_RUN = 0x958C          # DO_ACTION's CALL RUN_ROUTINE: HL the handler
FIND_OBJECT_HANDLER = 0x9B81
ACTION_TABLE = 0xC730
ACTION_TABLE_END = 0xC78E
ACTION_PATTERNS = 0xAB53
FOR_REAL = 0x9D44
IN_REACH = 0x9E34
DO_TALK = 0x9034
ASSIGN_ORDERS = 0x7EBA
TAKE_ORDER = 0x7F1A
PHRASES = 0x793D
TARGET_NAME = 0x7942
INSTRUMENT_NAME = 0x7948
PROBE = 0x7958
IT_NAME = 0xB6E0
ACTION = 0xB6E7
TARGET = 0xB6E8
INSTRUMENT = 0xB6E9
ACTING = 0xB6EA
DOING_IT = 0xB6FA
SUCCEEDED = 0xB6FB
FLAGS_FIRST_WORDS = 0xB71D
FLAGS_LAST_WORDS = 0xB71E
IS_ORDER = 0xB71B
COMMAND_FRAMES = 0xB706
TOKEN_POINTER = 0xB6DC
ACTOR = 0xB70C

# Printing.
PRINT_CHAR = 0x858B
PRINT_GATE = 0x8576
PRINTED = 0x858F                # PRINT_CHAR past its gate: really printed
RUN_MESSAGE = 0x72D3
RUN_MESSAGE_HL = 0x72DD

OBJECT_INDEX = 0xC063
PLAYER_WHERE = 0xC12B

# The Spectrum's colours, indexed by BRIGHT * 8 + the colour number.
PALETTE = [((level if c & 2 else 0), (level if c & 4 else 0), (level if c & 1 else 0))
           for level in (0xD7, 0xFF) for c in range(8)]


# --------------------------------------------------------------------------
# HTML helpers.
# --------------------------------------------------------------------------

def esc(text: str) -> str:
    """Text for a ref section: escaped, and with nothing skool2html would
    read as a macro."""
    return html.escape(text, quote=False).replace("#", "&#35;")


def said(text: str) -> str:
    """Something the game printed, as a quotation."""
    return "&ldquo;" + esc(" ".join(text.split())) + "&rdquo;"


def code(text: str) -> str:
    return f"<code>{esc(text)}</code>"


def table(headers, rows, cls: str = "default") -> str:
    head = "".join(f"<th>{h}</th>" for h in headers)
    body = "".join("<tr>" + "".join(f"<td>{c}</td>" for c in row) + "</tr>" for row in rows)
    return f'<table class="{cls}"><tr>{head}</tr>{body}</table>'


def plain(text: str) -> str:
    """Text for an attribute: no tags and no macros."""
    text = re.sub(r"<[^>]+>", "", text)
    text = re.sub(r"#R\$([0-9A-F]{4})(\([^)]*\))?", lambda m: "$" + m.group(1), text)
    return text.replace('"', "&quot;")


def img(name: str, image, alt: str = "", scale: int = 2, shrink: bool = True) -> str:
    fit = " max-width: 100%; height: auto;" if shrink else ""
    return (f'<img src="{IMAGE_SRC}/{name}" alt="{plain(alt)}" '
            f'width="{image.width * scale}" height="{image.height * scale}" '
            f'style="image-rendering: pixelated; image-rendering: crisp-edges;{fit}">')


def figure(name: str, image, caption: str, scale: int = 2) -> str:
    return (f'<div style="display: inline-block; vertical-align: top; margin: 0 12px 12px 0; '
            f'max-width: {max(image.width * scale + 4, 200)}px">'
            f'{img(name, image, caption, scale)}'
            f'<p style="margin: 4px 0 0 0; font-size: 0.9em">{caption}</p></div>')


def pre(text: str) -> str:
    return f'<pre style="white-space: pre-wrap">{esc(text)}</pre>'


def hexbytes(data) -> str:
    return " ".join(f"{b:02X}" for b in data)


NUMBER_WORDS = ["no", "one", "two", "three", "four", "five", "six", "seven", "eight",
                "nine", "ten", "eleven", "twelve"]


def words(number: int) -> str:
    return NUMBER_WORDS[number] if 0 <= number < len(NUMBER_WORDS) else str(number)


# --------------------------------------------------------------------------
# Links into the listing.
# --------------------------------------------------------------------------

_ENTRY_RE = re.compile(r"^[bcgistuw]\$([0-9A-F]{4})\s")
_INSTRUCTION_RE = re.compile(r"^[bcgistuw* ]\$([0-9A-F]{4})\s")


@functools.lru_cache(maxsize=None)
def _skool_index(skool: str) -> tuple[frozenset, dict]:
    """The entry starts in the skool file, and every label with its address."""
    path = Path(skool)
    if not path.exists():
        return frozenset(), {}
    entries, labels, pending = set(), {}, []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("@label="):
            pending.append(line[len("@label="):])
            continue
        match = _INSTRUCTION_RE.match(line)
        if match:
            address = int(match.group(1), 16)
            if _ENTRY_RE.match(line):
                entries.add(address)
            for label in pending:
                labels[address] = label
            pending = []
        elif not line.startswith("@"):
            pending = []
    return frozenset(entries), labels


class Links:
    """#R$ADDR(LABEL) where the address starts an entry in the skool file,
    plain $ADDR otherwise: the entries are read at build time."""

    def __init__(self, skool: Path):
        self.entries, self.labels = _skool_index(str(skool))
        self.starts = sorted(self.entries)
        self.missing: set[int] = set()

    def __call__(self, address: int, text: str | None = None) -> str:
        label = text if text is not None else self.labels.get(address)
        if address in self.entries:
            return f"#R${address:04X}({label})" if label else f"#R${address:04X}"
        self.missing.add(address)
        return f"{label} (${address:04X})" if label else f"${address:04X}"

    def label(self, address: int) -> str:
        return self.labels.get(address, f"${address:04X}")

    def routine(self, address: int) -> int:
        """The entry an address is in."""
        import bisect
        i = bisect.bisect_right(self.starts, address) - 1
        return self.starts[i] if i >= 0 else address

    def within(self, address: int) -> str:
        """The routine an address is in, linked, with the label of the address
        itself if it has one of its own."""
        entry = self.routine(address)
        text = self(entry)
        own = self.labels.get(address)
        if own and entry != address:
            text += f" ({own})"
        return text


# --------------------------------------------------------------------------
# The game, in the simulator, with probes.
# --------------------------------------------------------------------------

class Halt(Exception):
    """Raised by a probe to stop the machine where it is."""


class Session:
    """A game in SkoolKit's simulator, driven a whole command at a time as
    hobbit_drive.Hobbit drives it, with probes: `watch` maps an address to a
    function called just before the instruction there runs, which can read the
    machine through self.memory and self.registers. Everything printed past
    PRINT_CHAR's gate is captured, tagged with the phase the probes set."""

    def __init__(self):
        from hobbit_drive import Hobbit

        self.game = Hobbit()
        self.sim = self.game.sim
        self.memory = self.game.memory
        self.registers = self.sim.registers
        self.phase = ""
        self.printed: list[tuple[str, str]] = []

    @property
    def tstates(self) -> int:
        from skoolkit.simutils import T
        return self.registers[T]

    def word(self, address: int) -> int:
        return self.memory[address] | (self.memory[address + 1] << 8)

    def reg16(self, high: int, low: int) -> int:
        return (self.registers[high] << 8) | self.registers[low]

    def stack_top(self) -> int:
        from skoolkit.simutils import SP
        return self.word(self.registers[SP])

    def run(self, keys, seconds: float, watch=None, stop: int = 0) -> None:
        from skoolkit.simutils import PC, T

        game, registers = self.game, self.registers
        game.tracer.keys = set(keys)
        tf = df = None
        if watch:
            def tf(pc, i, t0):
                probe = watch.get(registers[PC])
                if probe:
                    probe(self)
            df = lambda pc: ""
        try:
            self.sim.trace(game.pc, stop, 0, registers[T] + int(seconds * bh.TSTATES_PER_SECOND),
                           True, None, None, None, df, tf)
        finally:
            # A probe may end the run early by raising Halt.
            game.pc = registers[PC]

    def say(self, command: str, watch=None) -> str:
        """Give the game one command, as Hobbit.say does, running the probes;
        return what was printed."""
        from hobbit_drive import LINE_LENGTH, READ_LINE_READY, WAIT_FOR_ANY_KEY
        from skoolkit.simutils import A, B, H, L

        watch = dict(watch or {})
        start = len(self.printed)
        before = watch.get(PRINTED)

        def capture(session):
            char = session.registers[A]
            text = chr(char) if 32 <= char < 127 else "\n" if char == 13 else ""
            session.printed.append((session.phase, text))
            if before:
                before(session)
        watch[PRINTED] = capture
        game = self.game
        game.ready()
        text = command.upper()
        for i, char in enumerate(text):
            self.memory[INPUT_LINE + i] = ord(char)
        cursor = INPUT_LINE + len(text)
        self.registers[H], self.registers[L] = cursor >> 8, cursor & 0xFF
        self.registers[B] = LINE_LENGTH - len(text)
        self.run([], 0.05, watch)
        # Hold ENTER until the reader has taken the line, and let go there.
        # Running on for a fixed time instead can carry a command answered at
        # once (a refusal, an unknown word) past the next prompt unseen, and
        # the game, left waiting, then types WAIT itself.
        self.run(["ENTER"], 1.0, watch, stop=LINE_TAKEN)
        if game.pc != LINE_TAKEN:
            raise RuntimeError(f"the line was not taken (PC ${game.pc:04X})")
        for _ in range(10):
            self.run([], 60, watch, stop=READ_LINE_READY)
            if game.pc == READ_LINE_READY:
                break
            if WAIT_FOR_ANY_KEY <= game.pc < WAIT_FOR_ANY_KEY + 14:
                self.run(["SPACE"], 0.05, watch)
                self.run([], 0.05, watch)
        else:
            raise RuntimeError(f"the game never asked for a line (PC ${game.pc:04X})")
        return "".join(t for _, t in self.printed[start:])

    def text(self, phase: str | None = None, start: int = 0) -> str:
        return "".join(t for p, t in self.printed[start:] if phase is None or p == phase)


class Machine:
    """A bare call into the game: a fresh machine from the tape's state (or a
    given memory), a routine called with chosen registers and a sentinel
    return address, and the machine read afterwards."""

    RETURN_HERE = 0x0010
    STACK = 0x5E80

    def __init__(self, memory=None):
        from skoolkit import CSimulator
        from skoolkit.simulator import Simulator

        if memory is None:
            memory = bh.machine_memory(bh.OUT_DIR / "hobbit.z80")
        self.sim = (CSimulator or Simulator)(list(memory), registers={"SP": self.STACK},
                                             state={"iff": 0, "im": 1, "tstates": 0})
        self.tracer = bh._key_tracer_class()(self.sim)
        self.sim.set_tracer(self.tracer)
        self.memory = self.sim.memory
        self.registers = self.sim.registers

    def call(self, address: int, registers: dict | None = None, watch=None,
             limit_seconds: float = 60) -> int:
        """Run the routine at `address` until it returns; the T-states taken."""
        from skoolkit.simutils import PC, SP, T
        import skoolkit.simutils as su

        memory, regs = self.memory, self.registers
        regs[SP] = self.STACK
        memory[self.STACK] = self.RETURN_HERE & 0xFF
        memory[self.STACK + 1] = self.RETURN_HERE >> 8
        pairs = {"BC": ("B", "C"), "DE": ("D", "E"), "HL": ("H", "L"),
                 "IX": ("IXh", "IXl"), "IY": ("IYh", "IYl")}
        for name, value in (registers or {}).items():
            if name in pairs:
                high, low = pairs[name]
                regs[getattr(su, high)], regs[getattr(su, low)] = value >> 8, value & 0xFF
            else:
                regs[getattr(su, name)] = value
        tf = df = None
        if watch:
            def tf(pc, i, t0):
                probe = watch.get(regs[PC])
                if probe:
                    probe(self)
            df = lambda pc: ""
        start = regs[T]
        self.sim.trace(address, self.RETURN_HERE, 0,
                       start + int(limit_seconds * bh.TSTATES_PER_SECOND),
                       False, None, None, None, df, tf)
        if regs[PC] != self.RETURN_HERE:
            raise RuntimeError(f"${address:04X} did not return (PC ${regs[PC]:04X})")
        return regs[T] - start

    def word(self, address: int) -> int:
        return self.memory[address] | (self.memory[address + 1] << 8)


# --------------------------------------------------------------------------
# The game's data, read.
# --------------------------------------------------------------------------

class Data:
    """Names and tables read from the tape's memory, shared by the pages."""

    def __init__(self):
        self.memory = list(bh.game_memory(bh.OUT_DIR / "hobbit.z80"))
        memory = self.memory
        self.records = bh.object_records(memory)
        self.record = {r["number"]: r for r in self.records}
        self.names = {r["number"]: bh.name_of(memory, r["start"] + 8) for r in self.records}
        self.rooms = bh.room_records(memory)
        self.room_name = {k: bh.name_of(memory, r["start"] + 2)
                          for k, r in self.rooms.items() if k}
        self.words = bh.decode_words(memory)
        self.word_by_address = {w.address: w for w in self.words}

    def name(self, number: int) -> str:
        if number == 0:
            return "you"
        if number == 0xFF:
            return "-"
        return self.names.get(number, f"${number:02X}")

    def word(self, reference: int) -> str:
        return (bh.word_at(self.memory, reference) or "").upper()

    def entry_text(self, address: int) -> str:
        entry = self.word_by_address.get(address)
        return entry.text if entry else self.word(address - WORD_INDEX)

    def frame_words(self, frame) -> dict:
        """A command frame's fields as words."""
        def w(offset):
            reference = frame[offset] | (frame[offset + 1] << 8)
            return reference, self.word(reference) if reference & 0x0FFF else ""
        out = {"verb": w(0), "adverb": w(2)}
        for n, base in ((1, 4), (2, 14)):
            out[f"prep{n}"] = [w(base), w(base + 2)]
            out[f"noun{n}"] = w(base + 4)
            out[f"adj{n}"] = [w(base + 6), w(base + 8)]
        return out

    def phrase_text(self, frame, base: int) -> str:
        """A noun phrase in a frame, as words: prepositions, adjectives, noun."""
        parts = []
        for offset in (base, base + 2, base + 6, base + 8, base + 4):
            reference = frame[offset] | (frame[offset + 1] << 8)
            if reference & 0x0FFF:
                parts.append(self.word(reference))
        return " ".join(parts)

    def name_text(self, data) -> str:
        """A six-byte name -- noun, two adjectives -- as words, adjectives first."""
        refs = [data[i] | (data[i + 1] << 8) for i in (0, 2, 4)]
        noun, *adjectives = [self.word(r) if r & 0x0FFF else "" for r in refs]
        return " ".join(w for w in adjectives + [noun] if w)


HEAR_A_NOISE = 0xB027           # the message CHARACTERS_ACT prints in the dark


@functools.lru_cache(maxsize=None)
def _speaker():
    from hobbit_drive import Hobbit
    return Hobbit()


@functools.lru_cache(maxsize=None)
def game_says(address: int, actor: int | None = None, target: int | None = None) -> str:
    """What RUN_MESSAGE prints for the message at `address`, captured at
    PRINT_CHAR from a game at its first prompt (hobbit_drive.Hobbit.message).
    `target` makes that object the action's target, for the codes that name it."""
    speaker = _speaker()
    if target is not None:
        record = next(r["start"] for r in bh.object_records(speaker.memory)
                      if r["number"] == target)
        speaker.memory[0xB6E8] = target
        speaker.memory[0xB708], speaker.memory[0xB709] = record & 0xFF, record >> 8
    # Lower case, as the story window prints every letter (STORY_CHAR makes
    # them so, capitalising only after a full stop); the messages' own
    # capitals mean nothing on screen.
    return speaker.message(address, actor).lower()


# --------------------------------------------------------------------------
# Parsing: one line followed through the game's own code.
# --------------------------------------------------------------------------

# The line followed: typed at the first prompt, in Bag End, with Thorin and
# Gandalf there and the curious map in the player's hands (Gandalf's first
# step gives it). It has a synonym for a verb (SAY, READ), an order in quotes
# with an adverb in it, THEN, an adjective, AND before a verb, and IT.
PARSE_LINE = 'SAY TO THORIN "QUICKLY OPEN THE CHEST" THEN READ THE CURIOUS MAP AND DROP IT'
# Words run through TOKENISE on their own, each for one of its rules.
TOKENISE_TESTS = [
    ("EXAM", "EXAMINE", "shorter than the entry: an abbreviation"),
    ("INV", "INVENTORY", "the same"),
    ("CUR", "CURIOUS", "an abbreviation takes the first entry that agrees, in bucket order"),
    ("SWORDS", "SWORD", "longer than the entry, which has five letters, and nothing after it "
                        "agrees as well"),
    ("INT", "INTO", "IN agrees but is too short to be stretched (under four letters); INTO "
                    "then takes it as an abbreviation"),
    ("MAPS", None, "longer than MAP, which has only three letters"),
    ("EXAMINING", None, "its seventh letter disagrees with EXAMINE's"),
    ("XYZZY", None, "no word begins with X"),
]
TAKE_ORDER_DONE = 0x7F2F        # TAKE_ORDER's way out: the order parsed and tried


def parse_trace() -> dict:
    """Run PARSE_LINE and record each stage as the game's code reaches it."""
    from skoolkit.simutils import A, B, C, D, E, F, H, L, IXh, IXl

    session = Session()
    memory, regs = session.memory, session.registers
    out = {"words": [], "tokens": None, "commands": [], "order_run": None, "assigned": None}
    state = {"command": None, "order": None}

    def blank() -> dict:
        return {"reads": [], "dispatch": [], "frames": None, "count": 0, "pattern": None,
                "action": None, "fits": [], "found": [], "tries": [], "real": None,
                "handlers": [], "quotes": []}

    def current(s):
        if s.phase == "order":
            return state["order"]
        if s.phase in ("parse", "player"):
            return state["command"]
        return None

    def new_word(s):
        out["words"].append({"start": s.reg16(H, L), "codes": None, "candidates": [],
                             "token": None})

    def typed(s):
        out["words"][-1]["codes"] = [memory[TYPED_WORD + i] for i in range(memory[TYPED_LENGTH])]

    def candidate(s):
        out["words"][-1]["candidates"].append(s.reg16(IXh, IXl))

    def token(s):
        out["words"][-1]["token"] = (regs[B], regs[C], regs[D])

    def tokens(s):
        if out["tokens"] is None:
            out["tokens"] = bytes(memory[TOKENS:TOKENS + 64])

    def parse_command(s):
        s.phase = "parse"
        state["command"] = blank()
        out["commands"].append(state["command"])

    def next_token(s):
        command = current(s)
        if command is not None and s.phase in ("parse", "order"):
            command["reads"].append((s.word(TOKEN_POINTER), s.stack_top(), regs[E]))

    def dispatch(s):
        command = current(s)
        if command is not None and s.phase in ("parse", "order"):
            command["dispatch"].append((regs[D], regs[B], regs[C], s.reg16(H, L), regs[E],
                                        s.word(TOKEN_POINTER) - 2))

    def quote(s):
        if s.phase == "parse":
            state["command"]["quotes"].append((memory[IS_ORDER], memory[COMMAND_FRAMES]))

    def obey(s):
        command = state["command"]
        count = memory[COMMAND_FRAMES]
        command["count"] = count
        command["frames"] = [bytes(memory[COMMAND_FRAME - FRAME_SIZE * i:
                                          COMMAND_FRAME - FRAME_SIZE * i + FRAME_SIZE])
                             for i in range(max(count, 1))]
        command["orders"] = bytes(memory[ORDERS:ORDERS + 8 * ORDER_SIZE])
        command["order_count"] = memory[ORDER_COUNT]
        command["it_before"] = bytes(memory[IT_NAME:IT_NAME + 6])
        command["text_from"] = len(s.printed)
        s.phase = "player"

    def pattern(s):
        command = current(s)
        if command is not None and s.phase in ("player", "order") and command["pattern"] is None:
            command["pattern"] = (bytes(memory[PROBE:PROBE + 8]), s.reg16(IXh, IXl),
                                  not regs[F] & 0x40)

    def action(s):
        command = current(s)
        if command is not None and s.phase in ("player", "order") and command["action"] is None:
            command["action"] = {"code": memory[ACTION], "b71d": memory[FLAGS_FIRST_WORDS],
                                 "b71e": memory[FLAGS_LAST_WORDS],
                                 "target_name": bytes(memory[TARGET_NAME:TARGET_NAME + 6]),
                                 "instrument_name": bytes(memory[INSTRUMENT_NAME:
                                                                 INSTRUMENT_NAME + 6]),
                                 "it": bytes(memory[IT_NAME:IT_NAME + 6]),
                                 "phrases_at": (memory[0x7954], memory[0x7955])}

    def fits(s):
        command = current(s)
        if command is not None and s.phase in ("player", "order"):
            command["fits"].append(memory[s.reg16(IXh, IXl)])

    def found(s):
        command = current(s)
        if command is not None and s.phase in ("player", "order"):
            command["found"].append(memory[s.reg16(IXh, IXl)])

    def try_it(s):
        command = current(s)
        if command is not None and s.phase in ("player", "order"):
            command["tries"].append({"caller": s.stack_top(), "target": memory[TARGET],
                                     "instrument": memory[INSTRUMENT], "result": None})

    def try_done(s):
        command = current(s)
        if command is not None and s.phase in ("player", "order") and command["tries"]:
            command["tries"][-1]["result"] = memory[SUCCEEDED]

    def real(s):
        command = current(s)
        if command is not None and s.phase == "player":
            command["real"] = (memory[ACTION], memory[TARGET], memory[INSTRUMENT],
                               memory[ACTING])

    def handler(s):
        command = current(s)
        if command is not None and s.phase in ("player", "order"):
            command["handlers"].append((s.reg16(H, L), s.reg16(IXh, IXl), memory[DOING_IT],
                                        memory[ACTING]))

    def turn_over(s):
        if s.phase == "player":
            state["command"]["text_to"] = len(s.printed)
            s.phase = "world"

    def assign(s):
        if out["assigned"] is None:
            out["assigned"] = (regs[A], memory[TARGET], memory[ORDER_COUNT],
                               bytes(memory[ORDERS:ORDERS + 8 * ORDER_SIZE]))

    def take_order(s):
        if s.phase == "world" and out["order_run"] is None:
            slot = next((ORDERS + ORDER_SIZE * i for i in range(8)
                         if memory[ORDERS + ORDER_SIZE * i] == memory[ACTING]), None)
            state["order"] = dict(blank(), who=memory[ACTING], slot=slot,
                                  bytes=bytes(memory[slot:slot + ORDER_SIZE]) if slot else b"",
                                  start=len(s.printed))
            out["order_run"] = state["order"]
            s.phase = "order"

    def order_done(s):
        if s.phase == "order":
            s.phase = "order-done"

    watch = {
        TOKENISE: new_word, MATCH_WORD_LOOKUP: typed, TRY_ENTRY: candidate,
        MAIN_TOKEN_BACK: token, MAIN_PARSE: tokens, PARSE_COMMAND: parse_command,
        NEXT_TOKEN: next_token, CLASS_DISPATCH_JUMP: dispatch, SPECIAL_QUOTE: quote,
        MAIN_OBEY_CALL: obey, PATTERN_FOUND: pattern, SEARCH_BEGUN: action,
        NAME_FITS: fits, NAME_FOUND: found, TRY_IT: try_it, TRY_IT_DONE: try_done,
        OBEY_REAL: real, DO_ACTION_RUN: handler, TURN_OVER: turn_over,
        ASSIGN_ORDERS: assign, TAKE_ORDER: take_order, TAKE_ORDER_DONE: order_done,
    }
    session.phase = "read"
    session.say(PARSE_LINE, watch)
    out["printed"] = session.printed
    out["memory"] = list(memory)
    return out


def tokenise_word(word: str) -> dict:
    """TOKENISE run on one word, on a fresh machine: the candidates it tried
    and the token it gave."""
    from skoolkit.simutils import IXh, IXl

    machine = Machine()
    memory = machine.memory
    tried = []
    for i, char in enumerate(word):
        memory[INPUT_LINE + i] = ord(char)
    memory[INPUT_LINE + len(word)] = 0x0D

    def candidate(m):
        tried.append((m.registers[IXh] << 8) | m.registers[IXl])
    from skoolkit.simutils import A, B, C
    machine.call(TOKENISE, {"HL": INPUT_LINE}, {TRY_ENTRY: candidate})
    regs = machine.registers
    return {"word": word, "class": regs[A], "token": (regs[B] << 8) | regs[C],
            "candidates": tried}


# E, the parser's state, bit by bit: what each set bit allows (read from the
# handlers that test and clear them).
E_BITS = [(1, "verb"), (2, "adverb"), (4, "article"), (6, "1st phrase free"),
          (7, "2nd phrase free")]


def e_text(e: int) -> str:
    allowed = [what for bit, what in E_BITS if e & (1 << bit)]
    text = ", ".join(allowed) if allowed else "nothing"
    if not e & 8:
        text += "; just after AND"
    return f"${e:02X}: {text}"


def pattern_flags(memory, code: int) -> tuple[int, int, list]:
    """The pattern's two flag bytes, gathered as PATTERN_FLAGS gathers them,
    and its four word references."""
    start = ACTION_PATTERNS + 8 * (code - 1)
    refs = [memory[start + i] | (memory[start + i + 1] << 8) for i in (0, 2, 4, 6)]
    first = (memory[start + 3] & 0xF0) | (memory[start + 1] >> 4)
    last = (memory[start + 7] & 0xF0) | (memory[start + 5] >> 4)
    return first, last, refs


FIND_MODES = {0: "things", 1: "characters", 2: "either", 3: "either"}


def pattern_row(data: Data, code: int, handlers: dict, link) -> list:
    memory = data.memory
    first, last, refs = pattern_flags(memory, code)
    shown = [data.word(r) if r & 0x0FFF else "" for r in refs]
    options = []
    if first & 0x10:
        options.append("not narrated")
    if last & 0x40:
        options.append("needs light")
    if first & 0x80:
        options.append("the target is a place")
    if first & 0x01:
        options.append("PATTERN_OPTION")
    target = f"{FIND_MODES[(last >> 2) & 3]}" if first & 0x08 else "-"
    instrument = f"{FIND_MODES[last & 3]}" if first & 0x04 else "-"
    handler = handlers.get(code)
    return [f'<a href="actions.html&#35;act{code}">{code}</a>',
            " ".join(esc(w) for w in shown[:3] if w) or "-", esc(shown[3]) or "-",
            f"${first:02X} ${last:02X}", target, instrument,
            "with the particle" if first & 0x20 else "-",
            ", ".join(options) or "-",
            link(handler) if handler else "objects' own only"]


def _token_word(data: Data, token: int) -> str:
    offset = token & 0x0FFF
    return data.entry_text(WORD_INDEX + offset) if offset else ""


def _class_name(cls: int) -> str:
    return bh.WORD_CLASSES.get(cls, {0xC: "end of the line", 0xD: "not a word"}.get(cls, "?"))


def parsing_page(data: Data, link, log) -> str:
    memory = data.memory
    trace = parse_trace()
    log("  parsing: traced " + str(len(trace["words"])) + " words, "
        + str(len(trace["commands"])) + " commands")
    printed = trace["printed"]
    player_text = "".join(t for p, t in printed if p in ("player",))
    world_text = "".join(t for p, t in printed if p in ("world", "order-done", "order"))

    # ---- the words
    word_rows = []
    for w in trace["words"]:
        b, c, cls = w["token"]
        tok = (b << 8) | c
        typed_text = ""
        end = w["start"]
        line = PARSE_LINE + "\r"
        # What was typed at this place in the line, from the start TOKENISE was
        # given (it skips spaces itself).
        offset = w["start"] - INPUT_LINE
        rest = line[offset:].lstrip(" ")
        if rest.startswith("\r"):
            typed_text = "(end)"
        elif rest[0] in ".,\"":
            typed_text = rest[0]
        else:
            typed_text = re.match(r"[A-Z]+", rest).group(0)
        tried = w["candidates"]
        if tried:
            names = [data.entry_text(a) for a in tried]
            shown = ", ".join(names) if len(names) <= 5 else (
                ", ".join(names[:2]) + f" ... ({len(names) - 4} more) ... " + ", ".join(names[-2:]))
            chosen = tried[-1]
            meaning = _token_word(data, tok)
            synonym = "" if WORD_INDEX + (tok & 0x0FFF) == chosen else f" &rarr; {esc(meaning)}"
            entry = f"{esc(data.entry_text(chosen))} (${chosen:04X}){synonym}"
        else:
            shown, entry = "-", "-"
        codes = " ".join(str(x) for x in w["codes"]) if w["codes"] else "-"
        word_rows.append([esc(typed_text), codes, f"{len(tried)}: {esc(shown)}" if tried else "-",
                          entry, f"${cls >> 4:X} {esc(_class_name(cls >> 4))}",
                          f"{b:02X} {c:02X}"])

    token_bytes = trace["tokens"]
    tokens = []
    for i in range(0, len(token_bytes), 2):
        tok = (token_bytes[i] << 8) | token_bytes[i + 1]
        tokens.append(tok)
        if token_bytes[i] & 0xF0 == 0xC0:
            break
    token_rows = []
    for i, tok in enumerate(tokens):
        cls = tok >> 12
        word = _token_word(data, tok)
        if cls == 0x9 and not tok & 0x0FFF:
            word = "(a quote)"
        elif cls == 0xB and not tok & 0x0FFF:
            word = "(a full stop, put in by the main loop)"
        elif cls == 0xC:
            word = "(the end)"
        token_rows.append([f"${TOKENS + 2 * i:04X}", f"{tok >> 8:02X} {tok & 0xFF:02X}",
                           f"${cls:X}", esc(word)])

    # ---- the word classes
    class_rows = []
    for cls in range(13):
        handler = memory[PARSER_CLASSES + 2 * cls] | (memory[PARSER_CLASSES + 2 * cls + 1] << 8)
        entries = [w for w in data.words if w.cls == cls]
        plain_words = [w.text for w in entries if w.synonym_of is None]
        sample = ", ".join(plain_words[:6]) + (", ..." if len(plain_words) > 6 else "")
        class_rows.append([f"${cls:X}", esc(_class_name(cls)), link(handler),
                           str(len(entries)) if cls < 0xC else "-", esc(sample) or "-"])

    # ---- the commands
    command_parts = []
    handlers = {k: v for k, v, _ in bh.keyed_table(memory, ACTION_TABLE)}
    for n, command in enumerate(trace["commands"], 1):
        rows = []
        for tok_at, caller, e in command["reads"]:
            tok = (token_bytes[tok_at - TOKENS] << 8) | token_bytes[tok_at + 1 - TOKENS]
            dispatched = next((d for d in command["dispatch"] if d[5] == tok_at), None)
            word = _token_word(data, tok)
            cls = tok >> 12
            if cls == 0x9 and not tok & 0x0FFF:
                word = "(quote)"
            elif cls == 0xB and not tok & 0x0FFF:
                word = "(full stop)"
            elif cls == 0xC:
                word = "(end)"
            reader = link.within(caller - 3)
            goes = link(dispatched[3]) if dispatched and caller == CLASS_DISPATCH else "-"
            rows.append([esc(word), f"${cls:X}", reader, e_text(e), goes])
        frame = command["frames"][0]
        fields = data.frame_words(frame)
        frame_rows = [["0-1", "verb", hexbytes(frame[0:2]), esc(fields["verb"][1]) or "-"],
                      ["2-3", "adverb or direction", hexbytes(frame[2:4]),
                       esc(fields["adverb"][1]) or "-"]]
        for p, base in ((1, 4), (2, 14)):
            what = [("prepositions", base, 4), ("noun", base + 4, 2), ("adjectives", base + 6, 4)]
            for label, at, size in what:
                refs = [frame[at + k] | (frame[at + k + 1] << 8) for k in range(0, size, 2)]
                text = " ".join(data.word(r) for r in refs if r & 0x0FFF)
                frame_rows.append([f"{at}-{at + size - 1}", f"phrase {p}: {label}",
                                   hexbytes(frame[at:at + size]), esc(text) or "-"])
        command_parts.append((n, command, rows, frame_rows))

    first = trace["commands"][0]
    order_slot = first["orders"][:ORDER_SIZE]
    order_frame = order_slot[1:]
    order_fields = [["0", "whose", f"{order_slot[0]:02X}", "not yet given ($FF: waiting)"]]
    for label, at, size in (("verb", 0, 2), ("adverb", 2, 2), ("phrase 1: noun", 8, 2),
                            ("phrase 1: adjectives", 10, 4)):
        refs = [order_frame[at + k] | (order_frame[at + k + 1] << 8) for k in range(0, size, 2)]
        text = " ".join(data.word(r) for r in refs if r & 0x0FFF)
        order_fields.append([f"{at + 1}-{at + size}", label, hexbytes(order_frame[at:at + size]),
                             esc(text) or "-"])

    # ---- patterns and objects for each command
    def pattern_story(command) -> str:
        probe, address, found = command["pattern"]
        probe_words = [(probe[i] | (probe[i + 1] << 8)) for i in (0, 2, 4)]
        probe_text = ", ".join(esc(data.word(r)) if r & 0x0FFF else "-" for r in probe_words)
        action = command["action"]
        code_ = action["code"]
        first_flags, last_flags, _ = pattern_flags(memory, code_)
        return (f"probe [{probe_text}]; pattern {code_} at ${address:04X}, "
                f"{esc(bh.pattern_sentence(memory, code_))}; flags ${first_flags:02X} ${last_flags:02X}")

    def object_story(command) -> list:
        rows = []
        action = command["action"]
        rows.append(["target's name (TARGET_NAME)", esc(data.name_text(action["target_name"])) or "-"])
        if any(action["instrument_name"]):
            rows.append(["instrument's name", esc(data.name_text(action["instrument_name"]))])
        fits = ", ".join(f"{esc(data.name(n))} (${n:02X})" for n in command["fits"]) or "none"
        rows.append(["objects whose name fits", fits])
        found = ", ".join(f"{esc(data.name(n))}" for n in command["found"] if n != 0xFF) or "none"
        rows.append(["of those, in the actor's reach", found])
        for t in command["tries"]:
            who = "MATCH_AND_TRY" if t["caller"] == 0x7A53 else (
                "OBEY" if t["caller"] == 0x797D else "TAKE_ORDER" if t["caller"] == 0x7F55
                else f"${t['caller']:04X}")
            rows.append([f"tested by {who}, DOING_IT = 0",
                         f"{esc(data.name(t['target']))}: SUCCEEDED = {t['result']}"])
        for hl, ix, doing, acting in command["handlers"]:
            if doing != 1:
                continue
            where = ("ACTION_TABLE, the ordinary handler" if ACTION_TABLE <= ix < ACTION_TABLE_END
                     else f"its own record (${ix:04X})")
            rows.append(["for real: the handler DO_ACTION runs", f"{link(hl)}, from {where}"])
        return rows

    trace_commands = trace["commands"]
    c1, c2, c3 = trace_commands[:3]
    order = trace["order_run"]
    assigned = trace["assigned"]

    def texts(command) -> str:
        return "".join(t for _, t in printed[command["text_from"]:command.get("text_to", 0)])

    # ---- the TOKENISE tests
    tests = []
    for word, expected, why in TOKENISE_TESTS:
        result = tokenise_word(word)
        cls = result["class"] >> 4
        got = None if cls == 0xD else _token_word(data, result["token"])
        if got != expected:
            log(f"  parsing: TOKENISE gave {got} for {word}, not {expected} as the page says")
        outcome = ("not a word ($D0)" if got is None
                   else f"{esc(got)} (token ${result['token']:04X})")
        tried = [a for a in result["candidates"]
                 if data.entry_text(a)[:1] == word[0]]
        if not tried:
            last = "no word begins with that letter"
        elif got is None:
            last = f"the last, {esc(data.entry_text(tried[-1]))}; then the bucket ended"
        else:
            last = esc(data.entry_text(tried[-1]))
        tests.append([esc(word), str(len(tried)), last, outcome, why])

    # ---- the pattern table
    pattern_rows = [pattern_row(data, code_, handlers, link) for code_ in range(1, 60)]

    # ---- the page
    L = link
    parts = [
        "<p>A command goes through six hands between the keyboard and the thing being done: "
        f"the line reader ({L(READ_LINE)}), the tokeniser ({L(TOKENISE)}), the parser's "
        f"state machine ({L(PARSE_COMMAND)}), the pattern matcher ({L(MATCH_PATTERN)}), the "
        f"object matcher ({L(MATCH_AND_TRY)}) and the one routine that does anything for "
        f"anyone ({L(DO_ACTION)}). The <a href=\"how-it-works.html\">overview</a> says what "
        "each is for; this page follows one real line through all of them, with what each "
        "left in its buffers.</p>",

        "<h3>The line followed</h3>",
        f"<p>Typed at the first prompt of a game, in Bag End, where Thorin and Gandalf are "
        f"and the player holds the curious map (Gandalf's first step gives it):</p>",
        f"<pre>{esc(PARSE_LINE)}</pre>",
        "<p>It has an order in quotes with an adverb in it, THEN, two verbs that are "
        "synonyms (SAY, READ), an adjective, AND in front of a verb, and IT. The game was "
        "run in SkoolKit's simulator when this page was built, the line put into the input "
        "buffer as <code>scripts/hobbit_drive.py</code> does, and every table below was read "
        "from the machine by a probe on the address named, just before the instruction there "
        "ran. What the game printed, from PRINT_CHAR past its gate (the player's commands, "
        "then the rest of the world's turns, Thorin's among them):</p>",
        pre(player_text.strip("\n")),
        pre(world_text.replace("> ", "").strip("\n")),

        "<h3>1. The line</h3>",
        f"<p>{L(READ_LINE)} takes keys into {L(INPUT_LINE)} as plain ASCII, echoing them, and "
        "ends the line with a carriage return ($0D). Nothing is done to the words yet. The "
        "cursor is only registers -- HL walking the line, B counting the room left, 128 to "
        "start -- which is how a command can be put in from outside (see the notes' "
        "driving.md).</p>",

        "<h3>2. Words into tokens</h3>",
        f"<p>The main loop calls {L(TOKENISE)} once per word, from $6D31, and keeps each "
        f"two-byte token in {L(TOKENS)}. A full stop, a comma or a quote is a token by "
        f"itself ({L(PUNCTUATION_TOKEN)}). Anything else is copied as letter codes -- the low "
        f"five bits of each character, so A is 1 -- into {L(TYPED_WORD)}, up to the first "
        f"character below $40, and looked up by {L(MATCH_WORD)}: the first letter picks a "
        f"bucket from {L(WORD_INDEX)}, and each entry in it is unpacked and compared by "
        f"{L(LETTERS_AGREE)} over the shorter of the two lengths, until one agrees. The table "
        "is each call, with the candidates it unpacked (read at $6F72, where each one "
        "starts) and the token it returned (in B and C at $6D34):</p>",
        table(["Typed", "Letter codes", "Candidates tried", "Entry taken", "Class", "Token"],
              word_rows),
        "<p>Two things happen here that nothing downstream ever sees. A synonym is resolved: "
        "SAY's entry ends with a link to TALK, and READ's to EXAMINE, and the token carries "
        "the word linked to, so from here on the game only knows TALK and EXAMINE. And the "
        "buckets are only grouped by initial letter, not sorted, so a common word can be "
        "found late: CURIOUS was the 22nd C-word unpacked.</p>",
        "<p>The same routine, called on single words on a fresh machine, shows its rules for "
        "short and long words: a typed word may be shorter than the entry (an abbreviation, "
        "taken as soon as the letters agree, so the first in the bucket wins), or longer, but "
        "only if the entry has four letters or more and the next candidate does not also "
        "agree:</p>",
        table(["Typed", "Candidates", "Last candidate", "Token", "Why"], tests),
        f"<p>So the tokens for the whole line, as the parser finds them in {L(TOKENS)} "
        f"at $6D8A: the class in the top nibble, the dictionary offset from $6000 below. The "
        "main loop has made one change: at the closing quote it put a full-stop token first "
        "($B0 $00), so that what is said ends as a sentence.</p>",
        table(["At", "Token", "Class", "Word"], token_rows),

        "<h3>3. Word classes, and a handler for each</h3>",
        f"<p>The class is two bits of the entry's first byte and two of its second. "
        f"{L(CLASS_DISPATCH)} turns it into an index into {L(PARSER_CLASSES)} and jumps "
        "there; the handlers are the parser. Read from the game (the word counts from the "
        "dictionary, synonyms included):</p>",
        table(["Class", "Words of", "Handler", "Words", "Some of them"], class_rows),
    ]

    parts += [
        "<h3>4. The state machine, and the frames it fills</h3>",
        f"<p>{L(PARSE_COMMAND)} parses one command and returns to the main loop, which obeys "
        f"it and calls it again while there is more on the line. It takes tokens through "
        f"{L(NEXT_TOKEN)}; register E says what may come next, each handler setting and "
        "clearing its bits. A handler that wants to know what follows reads on itself, so "
        "not every token goes through the class dispatch: a preposition looks for another "
        "preposition, an adjective for the noun after it. The words go into a 24-byte "
        f"<b>frame</b> at {L(COMMAND_FRAME)} (more frames, for a sentence that needs them, "
        f"lie below it, from {L(FRAMES)}): the verb, an adverb or a direction, and two noun "
        "phrases of two prepositions, the noun and two adjectives, each a two-byte word "
        "reference, low byte first. Articles are noted and dropped.</p>",
        "<p>Each command below is one call of PARSE_COMMAND: every token read, by which "
        "routine (the caller of NEXT_TOKEN), E as it was then, and where the class dispatch "
        "sent it; then the frame as OBEY found it at $6D96.</p>",
    ]
    for n, command, rows, frame_rows in command_parts:
        title = {1: "TALK TO THORIN, and an order", 2: "EXAMINE THE CURIOUS MAP",
                 3: "DROP IT"}.get(n, f"Command {n}")
        parts.append(f"<h4>Command {n}: {esc(title)}</h4>")
        parts.append(table(["Token", "Class", "Read by", "E", "Dispatched to"], rows))
        parts.append("<p>The frame, as OBEY found it:</p>")
        parts.append(table(["Offset", "Field", "Bytes", "Words"], frame_rows))
        if n == 1:
            parts.append(
                f"<p>The quote is a class $9 token with no word, which {L(PARSE_SPECIAL)} finds "
                f"in slot 0 of {L(SPECIAL_WORDS)}: its handler is {L(SPECIAL_QUOTE)}. At the "
                f"opening quote it calls {L(ORDER_BEGINS)}, which keeps the sentence so far "
                "aside and parses what follows in a fresh frame with IS_ORDER set -- "
                "QUICKLY, OPEN, THE, CHEST, and the full stop the main loop added, which ends "
                "the order as THEN would but, inside quotes, carries straight on. At the "
                f"closing quote SPECIAL_QUOTE files each frame parsed since into a free slot "
                f"of {L(ORDERS)}, marked $FF, puts the first sentence back and goes on. The "
                "THEN after it ends the command. So the frame OBEY gets holds only TALK TO "
                "THORIN; the order is in ORDERS slot 0, as it was at $6D96:</p>")
            parts.append(table(["Byte", "Field", "Bytes", "Words"], order_fields))
        if n == 2:
            parts.append(
                f"<p>AND is where the machine looks ahead. {L(PARSE_AND)} passes over any more "
                f"ANDs and saves a checkpoint ({L(AND_TOKENS)}: the place in TOKENS, E, the "
                "frame), then ends this part as THEN would and starts a new noun phrase. "
                f"The next token is DROP, a verb, and {L(PARSE_VERB)} finds E's bit 3 clear -- "
                "just after AND -- so the AND joined two commands, not two noun phrases: it "
                "goes back to the checkpoint and ends the command there. DROP IT is left in "
                "TOKENS for the next call, after this command has been done.</p>")
        if n == 3:
            parts.append(
                f"<p>IT is a special word too. {L(WORD_IT)} copies the six bytes kept at "
                f"{L(IT_NAME)} -- the name of the last target, set when the command before "
                f"was matched: {esc(data.name_text(c2['action']['it']))} -- into the phrase as if they had been typed, and "
                f"files it. So the frame is exactly what DROP THE {esc(data.name_text(c2['action']['it']))} would give.</p>")

    parts += [
        "<h3>5. From a frame to an action: the sentence patterns</h3>",
        f"<p>There is no table of verbs. {L(OBEY)} calls {L(PARSE_ACTION)}, which calls "
        f"{L(MATCH_PATTERN)}: it gathers a probe at $7958 -- the verb, then up to two words "
        "picked from the frame's phrases, their prepositions or particles -- and compares it "
        f"with each 8-byte pattern in {L(ACTION_PATTERNS)} by {L(NAME_MATCHES)}, the same "
        "comparison the objects' names are matched with, so the order of the two picked "
        "words does not matter. The action code is the pattern's place in the list. For "
        "the three commands (read at $79C4 and $79E9):</p>",
        table(["Command", "Probe, pattern and flags"],
              [["1", pattern_story(c1)], ["2", pattern_story(c2)], ["3", pattern_story(c3)]]),
        f"<p>Each pattern's four word references carry four flag bits each, which "
        f"{L(PATTERN_FLAGS)} gathers into two bytes, FLAGS_FIRST_WORDS ($B71D) and "
        "FLAGS_LAST_WORDS ($B71E). What they mean is read from the code that tests them: "
        "in the first, bit 3 the pattern has a target and bit 2 an instrument (PARSE_ACTION "
        "and WOULD_WORK), bit 4 it is not narrated (NARRATE_ACTION), bit 5 the target's "
        "phrase is the one with the particle (ASSIGN_PHRASES), bit 7 the target is a place "
        f"and bit 0 PATTERN_OPTION ({L(PATTERN_OPTIONS)}); in the second, bits 2-3 and 0-1 "
        "are the kinds of object the target and the instrument may be (the mode "
        f"{L(FIND_NAMED_OBJECT)} searches in: things, characters, or either) and bit 6 the "
        "action needs light. Every pattern in the game, with those decoded (the code links "
        "to the <a href=\"actions.html\">Actions page</a>, which has each one's handlers "
        "and the objects that carry their own):</p>",
        table(["Code", "Words", "Last word", "Flags", "Target", "Instrument",
               "Target phrase", "Options", "Ordinary handler"], pattern_rows),
        "<p>The ten directions are the patterns with GO as the last word, so NORTH and GO "
        "NORTH are one action. Two flags are not accounted for by the table: bit 5 of the "
        "second byte, set for GIVE TO alone, which ASSIGN_PHRASES reads when no particle "
        "was typed; and bit 7 of the second byte, set for CLIMB OUT OF alone, which "
        "NARRATE_ACTION reads to put both particle words before the object.</p>",

        "<h3>6. Finding the objects: try, then do</h3>",
        f"<p>A name is not turned into an object up front. {L(ASSIGN_PHRASES)} decides "
        "which phrase is the target and which the instrument -- by where the preposition the "
        "pattern wants turns up, not by order -- and copies their nouns and adjectives to "
        f"TARGET_NAME and INSTRUMENT_NAME, and the target's to {L(IT_NAME)} for IT. Then "
        f"{L(MATCH_AND_TRY)} goes through the objects whose name fits, in reach of the actor "
        f"({L(FIND_NAMED_OBJECT)}, {L(IN_REACH)}), and for each one runs the action through "
        f"{L(DO_ACTION)} with {L(DOING_IT)} clear: a test. Every handler makes its checks and "
        f"then calls {L(FOR_REAL)}, which in a test sets {L(SUCCEEDED)} and returns from "
        "the handler, so nothing changes and nothing is printed. The first object that would "
        f"work is kept. {L(OBEY)} then tests it once more, narrates it "
        f"({L(NARRATE_ACTION)}), sets DOING_IT and runs DO_ACTION for real. For the three "
        "commands (fits read at $9E0F, tests at $7AED and $7AF0, the handler at $958C):</p>",
    ]
    for n, command in ((1, c1), (2, c2), (3, c3)):
        parts.append(f"<h4>Command {n}</h4>")
        parts.append(table(["Stage", "What the machine held"], object_story(command)))
        parts.append(pre(texts(command).strip("\n")))
    parts += [
        "<p>The map's EXAMINE is the map's own: its record carries a handler for action 28, "
        "and DO_ACTION asks the object before it looks in ACTION_TABLE (see the "
        "<a href=\"how-it-works.html\">overview</a>). Here the player is not Elrond, so it "
        "only says the symbols cannot be read.</p>",

        "<h3>7. The order, on Thorin's turn</h3>",
        f"<p>TALK TO's handler, {L(DO_TALK)}, decides how many of the sentences in ORDERS "
        f"the character takes: a random number up to its limit (6 for Thorin), and "
        f"{L(ASSIGN_ORDERS)} gives it that many of those waiting and throws the rest away. "
        f"Here it was called with {assigned[0]}, and {assigned[2]} was waiting, so slot 0's "
        f"first byte became Thorin's number, ${assigned[1]:02X}. On his turn in the world's "
        f"turn that followed, {L(TAKE_ORDER)} freed the slot and parsed the frame the way "
        f"the player's are: pattern {order['action']['code']} "
        f"({esc(bh.pattern_sentence(memory, order['action']['code']))}), target "
        f"{esc(data.name_text(order['action']['target_name']))}, which fitted "
        f"{esc(', '.join(data.name(n) for n in order['fits']))}; tested, it would work, "
        "and he did it:</p>",
        pre("".join(t for p, t in printed if p == "order-done").strip("\n")),
        "<p>The adverb was parsed and kept at offset 2 of the frame, and played no part: "
        "MATCH_PATTERN's probe is the verb and the phrases' prepositions, not offset 2 "
        "(<i>read</i>), so QUICKLY OPEN THE CHEST is OPEN THE CHEST. How "
        "the characters' turns work is on <a href=\"character-lives.html\">How the "
        "characters live</a>.</p>",
    ]

    parts += [
        "<h3>What is confirmed, and what is not</h3>",
        "<ul>",
        "<li><b>Run</b> when this page was built: everything in the tables above -- the "
        "candidates, the tokens, the tokens each handler read and where the dispatch sent "
        "them, the frames, the order slot, the probes, the patterns and their codes, the "
        "objects that fitted, each test's answer, the handlers run, and what was printed. "
        "The single-word TOKENISE results likewise.</li>",
        "<li><b>Read</b> from the code: what each bit of E means, the pattern flags' "
        "meanings (from the instructions that test them; the two single-pattern bits are "
        "described by where they are read, not by a run that shows them mattering), and "
        "that the adverb takes no part in choosing the action.</li>",
        f"<li><b>Not worked out</b>: when {L(COPY_VERB_ON)} moves a frame's phrase to "
        "second place, and ALL ... EXCEPT, whose code runs in the build's playthrough "
        "but whose result is not checked here.</li>",
        "</ul>",
    ]
    return "\n".join(parts)


# --------------------------------------------------------------------------
# The pages.
# --------------------------------------------------------------------------

PAGES = [
    ("Parsing", "How a sentence is understood", "parsing_page"),
    ("CharacterLives", "How the characters live", "characters_page"),
    ("Fighting", "How a fight is decided", "fighting_page"),
    ("Messages", "How the text is stored and told", "messages_page"),
    ("Drawing", "How a picture is drawn", "drawing_page"),
]


def build(html_dir: Path, log=print, only=None) -> dict[str, str]:
    """Draw the pictures into html_dir/images/howitworks and return the
    pages' HTML by ref section name. `only` limits it to some sections."""
    html_dir = Path(html_dir)
    (html_dir / IMAGE_DIR).mkdir(parents=True, exist_ok=True)
    link = Links(bh.OUT_DIR / "hobbit.skool")
    data = Data()
    data.html_dir = html_dir
    log("Writing the how-it-works deep dives...")
    sections = {}
    for name, _title, function in PAGES:
        if only and name not in only:
            continue
        body = globals()[function](data, link, log)
        for line in body.splitlines():
            if line.startswith((";", "[")):
                raise ValueError(f"{name}: a line starts with {line[0]!r}: {line[:60]}")
        sections[name] = body
    if link.missing:
        log("  not entries (shown as plain addresses): "
            + ", ".join(f"${a:04X}" for a in sorted(link.missing)))
    return sections


# --------------------------------------------------------------------------
# The characters: twenty turns of WAIT, every character's script followed.
# --------------------------------------------------------------------------

CHARACTERS = 0xCACB
CHARACTER_SIZE = 7
CHARACTERS_ACT = 0x980E
CHARACTER_TURN = 0x9826         # CHARACTERS_ACT: A = the character, IY its slot
SCRIPT_STEP = 0x9885            # each step considered: HL = the step
ORDER_TAKEN = 0x98A9            # CHARACTERS_ACT's CALL TAKE_ORDER
STEP_REFUSED = 0x99AA
NEXT_CHARACTER = 0x9901
SCRIPT_RANDOM = 0x9A59
SCRIPT_DO = 0x9928
SCRIPT_BARE = 0x9974
ACTOR_TRIES = 0x99C6
REACT = 0x9AA0
REACT_TO_ACTION = 0x95DF
CAPTIVE = 0x9B16
STEPS_REFUSED = 0x980B
PRINTING_ON = 0xB702
END_OF_TURN = 0x96B3
RANDOM_POSITIVE = 0x9C9F
BARD_TAKES_ORDER = 0xA8AB
KILL = 0x977F
WAIT_TURNS = 20
# The characters followed turn by turn, by object number: Gandalf, Thorin, and
# the vicious warg, who roams furthest and picks a fight on the way.
FOLLOWED = (0x3E, 0x3F, 0x43)
ACTOR_DOES_IT = 0x9A32          # ACTOR_TRIES's CALL DO_ACTION: the action for real
PRINT_BUFFER = 0x7567           # PRINT_WORD, about to print the word it built


def character_turns(turns: int = WAIT_TURNS) -> dict:
    """Play `turns` turns of WAIT from the first prompt, and record every
    character's script as CHARACTERS_ACT runs it: the steps considered, how
    each ended, the sentence it composed (seen or not), and where every
    character is after each turn."""
    from skoolkit.simutils import A, H, L, IXh, IXl, IYh, IYl

    session = Session()
    memory, regs = session.memory, session.registers
    records = {r["number"]: r["start"] for r in bh.object_records(memory)}
    turn_log: list[dict] = []
    state = {"turn": None, "who": None}

    def where() -> dict:
        return {n: (memory[start + 16], memory[start + 1]) for n, start in records.items()}

    def turn_start(s):
        state["turn"] = {"acts": {}, "order": []}
        turn_log.append(state["turn"])

    def character(s):
        who = regs[A]
        state["who"] = who
        act = {"slot": s.reg16(IYh, IYl), "steps": [], "said": [], "seen": False,
               "end": None, "random": 0, "did": []}
        state["turn"]["acts"][who] = act
        state["turn"]["order"].append(who)

    def act():
        turn = state["turn"]
        if turn is None or state["who"] is None:
            return None
        return turn["acts"].get(state["who"])

    def step(s):
        a = act()
        if a is not None:
            a["steps"].append({"at": s.reg16(H, L), "refused": False})

    def refused(s):
        a = act()
        if a is not None and a["steps"]:
            a["steps"][-1]["refused"] = True

    def random_switch(s):
        a = act()
        if a is not None:
            a["random"] += 1

    def next_character(s):
        a = act()
        if a is not None:
            a["end"] = s.word(state["turn"]["acts"][state["who"]]["slot"] + 2)
            a["seen"] = bool(memory[PRINTING_ON])
        state["who"] = None

    def composed(s):
        # Everything a character's real action composes, printed or not:
        # PRINT_CHAR before its gate, while DOING_IT says this is for real.
        a = act()
        if a is not None and memory[DOING_IT] == 1:
            char = regs[A]
            a["said"].append(chr(char) if 32 <= char < 127 else "\n" if char == 13 else "")

    def does(s):
        a = act()
        if a is not None:
            a["did"].append((memory[ACTION], memory[TARGET], memory[INSTRUMENT]))

    def word_break(s):
        # Out of sight PRINT_WORD puts no space before a word (it asks the
        # story window where it is), so mark the break here.
        a = act()
        if a is not None and memory[DOING_IT] == 1 and a["said"] and a["said"][-1] not in " \n":
            a["said"].append(" ")

    def react(s):
        # REACT: A the character something was done to, B the action.
        from skoolkit.simutils import B
        if state["turn"] is not None:
            state["turn"].setdefault("reactions", []).append(
                (regs[A], regs[B], state["who"]))

    watch = {ACTOR_DOES_IT: does, PRINT_BUFFER: word_break, CHARACTERS_ACT: turn_start, CHARACTER_TURN: character, SCRIPT_STEP: step,
             STEP_REFUSED: refused, SCRIPT_RANDOM: random_switch, REACT: react,
             NEXT_CHARACTER: next_character, PRINT_CHAR: composed}
    start = {"where": where(),
             "slots": bytes(memory[CHARACTERS:CHARACTERS + 17 * CHARACTER_SIZE + 1])}
    printed = []
    for _ in range(turns):
        before = len(session.printed)
        session.phase = "wait"
        session.say("WAIT", watch)
        turn_log[-1]["where"] = where()
        turn_log[-1]["printed"] = session.text(start=before)
    return {"start": start, "turns": turn_log, "records": records,
            "memory": list(memory)}


def _loc_link(data: Data, location: int) -> str:
    if location in data.room_name:
        return f'<a href="locations.html&#35;loc{location}">{esc(data.room_name[location])}</a>'
    return "nowhere" if location in (0, 0xFF) else str(location)


def _char_link(data: Data, number: int) -> str:
    if number == 0:
        return "the player"
    return f'<a href="characters.html&#35;obj{number}">{esc(data.name(number))}</a>'


def characters_page(data: Data, link, log) -> str:
    memory = data.memory
    program = bh.script_program(memory)
    labels = program["labels"]
    trace = character_turns()
    turns = trace["turns"]
    log(f"  characters: {len(turns)} turns of WAIT")
    L = link

    def step_name(address: int) -> str:
        return labels.get(address, f"${address:04X}")

    def step_text(address: int) -> str:
        step = program["steps"].get(address) or bh.script_step(memory, address)
        text = bh.describe_step(memory, program, step,
                                lambda a: labels.get(a) or link(a))
        if step["fallback"] is not None:
            text += f"; if refused, on at {step_name(step['fallback'])}"
        return text

    # ---- the slots, as the tape has them
    slot_rows = []
    start_where = {n: memory[data.record[n]["start"] + 16] for n in data.record}
    for slot in program["slots"]:
        who = slot["character"]
        slot_rows.append([
            f"${slot['address']:04X}", _char_link(data, who) + (" (empty on the tape)" if slot["empty"] else ""),
            _loc_link(data, start_where.get(who, 0)),
            str(slot["limit"]), step_name(slot["current"]), link.within(slot["table"]),
            str(slot["orders"])])

    # ---- the opcodes
    opcode_rows = [
        ["0, 2", "4", f"an action and its two objects, tried as the character's own sentence "
                      f"({L(SCRIPT_DO)}); $FF for an object means whatever fits"],
        ["1, 3", "4", "a routine, run first as a test with printing off and again for real only "
                      "if it set SUCCEEDED (also SCRIPT_DO); the fourth byte is not used"],
        ["4", "2", f"an action with no objects, which acts on whatever fits ({L(SCRIPT_BARE)}); "
                   "action $FF is a pause: nothing this turn"],
        ["$0C", "2", f"switch to its reaction script for the action that follows ({L(REACT)})"],
        ["$0E", "3", "go to the address that follows, and carry on"],
        ["$0F", "2", f"switch to one of its ordinary scripts at random ({L(SCRIPT_RANDOM)}): "
                     "the lesser of the operand and the slot's byte 1 bounds the choice"],
        ["other", "1", "back to its first script; the turn is over"],
    ]
    bit_rows = [["4 ($10)", "a two-byte fallback follows: where the script goes on if the step "
                            "is refused"],
                ["5 ($20)", "used up: once it works SCRIPT_DO writes 0 over the step's first byte "
                            "(only Thorin's remark about the small curious key has it)"],
                ["6 ($40)", "an order from the player cannot interrupt it"]]

    # ---- the three followed, turn by turn
    followed_tables = []
    for who in FOLLOWED:
        rows = []
        for n, turn in enumerate(turns, 1):
            act = turn["acts"].get(who)
            if act is None:
                rows.append([str(n), "-", "-", _loc_link(data, turn["where"][who][0])])
                continue
            steps = []
            for step in act["steps"]:
                kind = memory[step["at"]] & 0x0F
                mark = ("" if kind > 4 else " <i>(refused)</i>" if step["refused"]
                        else " <i>(done)</i>")
                steps.append(f"{esc(step_name(step['at']))}: {step_text(step['at'])}{mark}")
            sentence = " ".join("".join(act["said"]).split())
            if sentence:
                did = sentence
                did = esc(did) + ("" if act["seen"] else " <i>(out of sight: not printed)</i>")
            else:
                did = "-"
            if act["random"]:
                steps.append(f"<i>{words(act['random'])} random switch"
                             f"{'es' if act['random'] > 1 else ''}</i>")
            rows.append([str(n), "<br>".join(steps), did, _loc_link(data, turn["where"][who][0])])
        followed_tables.append((who, rows))

    # ---- where everyone went
    shown = [0] + [n for n in FOLLOWED] + [0x40]
    where_rows = []
    start_row = ["start"] + [_loc_link(data, trace["start"]["where"][n][0]) for n in shown]
    where_rows.append(start_row)
    for n, turn in enumerate(turns, 1):
        row = [str(n)]
        for who in shown:
            loc, holder = turn["where"][who]
            text = _loc_link(data, loc)
            if who and holder not in (0xFF,) and holder != 0:
                text += f" (held by {esc(data.name(holder))})"
            prev = (turns[n - 2]["where"][who][0] if n > 1
                    else trace["start"]["where"][who][0])
            row.append(text if loc != prev else "<span style=\"color: &#35;777\">" + text + "</span>")
        where_rows.append(row)

    # ---- everyone, in sum
    summary_rows = []
    everyone = []
    for turn in turns:
        for who in turn["order"]:
            if who not in everyone:
                everyone.append(who)
    for who in everyone:
        acts = [t["acts"][who] for t in turns if who in t["acts"]]
        considered = sum(len(a["steps"]) for a in acts)
        refused = sum(1 for a in acts for s in a["steps"] if s["refused"])
        seen = sum(1 for a in acts if a["seen"] and "".join(a["said"]).strip())
        places = {t["where"][who][0] for t in turns}
        summary_rows.append([_char_link(data, who), str(len(acts)), str(considered), str(refused),
                             str(sum(a["random"] for a in acts)), str(len(places)), str(seen)])

    seen_by = [data.name(r) for r in everyone
               if any(t["acts"][r]["seen"] and "".join(t["acts"][r]["said"]).strip()
                      for t in turns if r in t["acts"])]
    seen_text = (" and ".join(esc(n) for n in seen_by) + (" were" if len(seen_by) > 1 else " was")
                 if seen_by else "nobody was")
    warg_places = [t["where"][0x43][0] for t in turns]
    warg_end = _loc_link(data, warg_places[-1])

    # ---- reactions, from the script tables
    reaction_rows = []
    for address, table_ in sorted(program["tables"].items()):
        owners = ", ".join(_char_link(data, o) for o in table_["owners"])
        ordinary = [labels.get(t, f"${t:04X}") for _, key, t in table_["entries"] if key == 0]
        reacts = [f"{esc(bh.pattern_sentence(memory, key))}: {esc(labels.get(t, f'${t:04X}'))}"
                  for _, key, t in table_["entries"] if key]
        reaction_rows.append([link.within(address), owners, str(len(ordinary)),
                              "; ".join(reacts) or "-"])

    # ---- the reaction watched
    slot_of = {sl["character"]: sl for sl in program["slots"]}
    reactions = [(n, r) for n, t in enumerate(turns, 1) for r in t.get("reactions", [])
                 if r[0] in slot_of]
    watched = []
    for n, (target, action, actor) in reactions:
        entries = program["tables"][slot_of[target]["table"]]["entries"]
        entry = next((t for _, key, t in entries if key == action), None)
        outcome = (f"its table has an entry for that action, so its script was moved to "
                   f"{esc(step_name(entry))}" if entry is not None
                   else "its table has no entry for that action, so its script went on as it was")
        watched.append(f"<li>Turn {n}: {esc(data.name(actor))} did "
                       f"{esc(bh.pattern_sentence(memory, action))} (${action:02X}) to "
                       f"{esc(data.name(target))}; {outcome}.</li>")
    reaction_text = ""
    if watched:
        reaction_text = (f"<p>Reactions seen in these twenty turns -- the calls of {L(REACT)} "
                         f"from {L(REACT_TO_ACTION)} whose target was a character:</p><ul>"
                         + "".join(watched) + "</ul>"
                         "<p>REACT_TO_ACTION also calls REACT, harmlessly, for many actions with "
                         "no target at all (a RUN, say): it tests the flags of whatever record "
                         "TARGET_RECORD last held, and REACT then finds no character numbered "
                         "$FF (<i>read</i>, and seen in the same run).</p>")

    # ---- Bard
    bard_step = bh.script_step(memory, bh.BARD_ORDER_STEP)
    bard_text = step_text(bh.BARD_ORDER_STEP)

    gandalf = next(sl for sl in program["slots"] if sl["character"] == 0x3E)
    gandalf_table = program["tables"][gandalf["table"]]
    gandalf_ordinary = [labels.get(t, f"${t:04X}") for _, key, t in gandalf_table["entries"] if key == 0]

    parts = [
        "<p>Seventeen characters share the world with the player, and every one of them takes a "
        "turn after each of the player's -- wherever it is, seen or not. A character is an "
        "ordinary object record with a slot in "
        f"{L(CHARACTERS)} pointing into a small script, and what it does is always an action "
        "tried as if it had typed it, through the same code as the player's "
        "(<a href=\"parsing.html\">How a sentence is understood</a>). This page is the "
        "machinery, and twenty real turns of it.</p>",

        "<h3>The slots</h3>",
        f"<p>Seven bytes each, from {L(CHARACTERS)}, read from the tape: the character, how "
        "many of its ordinary scripts a random switch may choose among, where its script has "
        "got to, its script table, and how many of the player's orders it takes at once. "
        "Three slots are empty on the tape and are filled in by arrival hooks when the story "
        "reaches their characters. The step names are the listing's labels.</p>",
        table(["Slot", "Character", "Starts at", "Scripts", "Its step", "Script table", "Orders"],
              slot_rows),

        "<h3>The steps</h3>",
        "<p>A script is a list of steps. The low four bits of a step's first byte are its "
        "opcode (read from CHARACTERS_ACT's own tests):</p>",
        table(["Opcode", "Bytes", "Does"], opcode_rows),
        "<p>and three more bits of the same byte change how it is taken:</p>",
        table(["Bit", "Means"], bit_rows),
        "<p>The whole of every script is written out on the <a href=\"characters.html\">"
        "Characters page</a>.</p>",

        "<h3>A character's turn</h3>",
        f"<p>{L(END_OF_TURN)} calls {L(CHARACTERS_ACT)}, which goes through the slots in "
        "order. For each character (<i>read</i>):</p>",
        "<ol>",
        f"<li>It becomes the subject of the sentence: ACTING, ACTOR and ACTOR_AT are set to it, "
        "and printing is turned off.</li>",
        "<li>If the player can see it, printing is turned on -- unless the player is in the "
        f"dark, when the first thing anyone does is only heard, {said(game_says(HEAR_A_NOISE))}, "
        "and nothing else is printed.</li>",
        f"<li>If something holds it ({L(CAPTIVE)}), it tries to climb out, or does nothing if "
        "that something is closed.</li>",
        "<li>If an order is waiting for it and the step it is on may be interrupted, it takes "
        f"the order instead ({L(TAKE_ORDER)}): that is its turn.</li>",
        f"<li>Otherwise it runs steps from where its script has got to. A step that is tried "
        f"goes through {L(ACTOR_TRIES)}: WOULD_WORK tests it exactly as the player's commands "
        f"are tested, and only then does {L(DO_ACTION)} do it and NARRATE_ACTION tell it. A "
        f"refused step ({L(STEP_REFUSED)}) is counted and the script goes on at its fallback "
        "or the next step; one that works, a pause, or six refusals end the turn.</li>",
        "</ol>",
        "<p>So what a character does is decided and done whether anyone sees it or not; the "
        "player is told only what happens in sight. The runs below show both, because the "
        "sentences were captured at PRINT_CHAR before its gate, while DOING_IT said the action "
        "was real, which is where the out-of-sight ones are composed and then not printed.</p>",

        f"<h3>Twenty turns of WAIT</h3>",
        f"<p>A game started as the build starts one, and WAIT typed at the first prompt "
        f"{words(len(turns))} times, in Bag End, in SkoolKit's simulator. Probes on "
        f"CHARACTERS_ACT's slot loop ($9826), each step it considers (SCRIPT_STEP, $9885), "
        f"the refusals ($99AA), the random switches, DO_ACTION's call from ACTOR_TRIES "
        "($9A32) and REACT recorded each character's turn; the places are the object "
        "records' location bytes after each turn. Gandalf, Thorin and the vicious warg:</p>",
    ]
    for who, rows in followed_tables:
        parts.append(f"<h4>{_char_link(data, who)}</h4>")
        parts.append(table(["Turn", "Steps tried", "What it did", "Where after"], rows))
        if who == 0x3E:
            parts.append(
                "<p>Gandalf's first steps give the player the curious map and open the round "
                "green door (the map before the first prompt, the door on the first WAIT). "
                f"After that he has {words(len(gandalf_ordinary))} ordinary scripts "
                f"({esc(', '.join(gandalf_ordinary))}), and they are one list entered at different "
                "places: each is RUN and one more thing, running on into the next, and the last "
                "ends in a switch at random. So he goes somewhere, tries to do something there -- "
                "take, drop, give, chat, open, close -- and goes on, and a refusal falls through "
                "to the next step. Where he is after twenty turns is chance: RUN picks a "
                f"direction with {L(0x9CA8)}, and the switches pick a script.</p>")
        if who == 0x3F:
            parts.append(
                "<p>Thorin's script is a loop that tries the same things in the same order "
                "every turn: FOLLOW the player (refused: they are already together), TAKE the "
                "small curious key (refused: it is not here), ask where the thief is "
                "(refused: the player can be seen), and then his chatter routine, which always "
                "does something -- waits, says his line or sings -- and ends his turn. The "
                "script then goes back to the start. Only the last step is ever seen.</p>")
        if who == 0x43:
            parts.append(
                "<p>The warg's script is ATTACK WITH, whatever fits; failing that FOLLOW and "
                "howl; failing that RUN; failing that a pause. Every turn it could see nobody to "
                "attack, so it ran. Then it met the wood elf, attacked, and the fight is decided "
                "as on <a href=\"fighting.html\">How a fight is decided</a>. The elf's "
                f"answer, on its next turn, was to capture it, and captives of the elf go to "
                f"{warg_end}: there RUN is refused, and the warg pauses every turn.</p>")
    parts += [
        reaction_text,
        "<h3>Where they went</h3>",
        "<p>The player stays in Bag End throughout; the location of each after every turn, "
        "grey where it did not change (the wood elf, whose turns are not tabled above, is "
        "added for the warg's sake):</p>",
        table(["Turn", "The player"] + [_char_link(data, w) for w in FOLLOWED]
              + [_char_link(data, 0x40)], where_rows),

        "<h3>Everyone, in sum</h3>",
        "<p>The same twenty turns for all the characters in play: how many turns each took, "
        "how many steps it considered and how many of those were refused, the random "
        "switches, how many places it was in, and how many of its turns the player was told "
        "about.</p>",
        table(["Character", "Turns", "Steps", "Refused", "Random switches", "Places",
               "Seen"], summary_rows),
        "<p>Almost everything happens out of sight: the trolls try their one step six times "
        "a turn and are refused each time until the player comes, the goblins patrol their "
        f"tunnels, Gollum paces by his lake, and only {seen_text} seen at all. Nothing in the "
        "scripts is tied to a place, which is why no two games play alike.</p>",

        "<h3>Reactions</h3>",
        "<p>A script table's entries keyed 0 are the ordinary scripts; any other key is an "
        "action code, and that entry is the character's reaction when that action is done "
        f"to it. After an action for real, {L(DO_ACTION)} calls {L(REACT_TO_ACTION)} for each "
        f"object that is a living character, and {L(REACT)} looks the action up in the "
        "character's table and, if it is there, moves its script to that entry. Every table "
        "in the game:</p>",
        table(["Table", "Used by", "Ordinary scripts", "Reactions"], reaction_rows),

        "<h3>Orders, and why Bard is different</h3>",
        f"<p>What the player says in quotes is parsed into frames of its own and filed in "
        f"{L(ORDERS)}; TALK TO's handler, {L(DO_TALK)}, gives the character a random number "
        "of them up to its limit (slot byte 6), and on its turn one replaces the step it is "
        "on, unless that step has bit 6. The whole path, from the quote mark to Thorin "
        "opening a chest, is followed on <a href=\"parsing.html\">How a sentence is "
        "understood</a>. A limit of 0 means the character never listens, and a random 0 "
        "means it refuses this time.</p>",
        f"<p>Bard's slot takes orders too, but his only ordinary script is "
        f"{L(BARD_TAKES_ORDER)} and one step at ${bh.BARD_ORDER_STEP:04X}, both with bit 6: "
        "no order can interrupt them. Instead the routine parses a waiting order itself and "
        "writes its action and objects into that step, which he then tries every turn until "
        "it works. So an order to Bard is not done once, on his next turn: it is kept, and "
        "carried out as soon as it can be -- which is how SHOOT THE DRAGON is meant to be "
        f"given. On the tape the step reads: {bard_text}. Because the game rewrites it, SAVE "
        "carries its three bytes, and a new game does not put it back (see "
        "<a href=\"bugs.html\">Bugs</a>).</p>",

        "<h3>What is confirmed, and what is not</h3>",
        "<ul>",
        "<li><b>Run</b> when this page was built: every step, refusal, switch, sentence and "
        "place in the twenty turns, and the reaction watched.</li>",
        "<li><b>Read</b>: the slot and step formats (the build decodes every script and "
        "requires every byte from the scripts' start to TIMERS to be a table or a step), the "
        "turn's order of events, the reactions tables, and Bard's order step. The notes "
        "record Thorin's used-up step and the trolls' dawn as measured in earlier runs.</li>",
        "<li><b>Not worked out</b>: how a step's &ldquo;whatever fits&rdquo; chooses among "
        "several candidates (assumed to be the order of the object index, as MATCH_AND_TRY "
        "walks it), and part of ACTOR_TRIES ($99E5), two ways into NARRATE_ACTION.</li>",
        "</ul>",
    ]
    return "\n".join(p for p in parts if p)


# --------------------------------------------------------------------------
# Fighting: the game's own DO_ATTACK, over the cast and over the margins.
# --------------------------------------------------------------------------

DO_ATTACK = 0x9171
SAME_SIDE = 0x914A
JOSTLE = 0x9213
WOUNDS = 0x9226
WOUNDS_COUNT = 16
ONE_PLACE = 0x9246
RANDOM = 0x9CA8
BLOW_AND_GUARD = 0x91C1         # DO_ATTACK: B = the blow, A = the guard, both jostled
WOUND_MARGIN = 0x91D2           # DO_ATTACK: a wound, margin 1-16
WOUND_PRINT = 0x91FB            # DO_ATTACK: worn down, the wound's message in HL
A_KILL = 0x91FE                 # DO_ATTACK: more than 16 stronger
MSG_WASTED = 0xAF50             # the message DO_ATTACK prints when the guard holds
PLAYER_DIES = 0x90D2
WAIT_AND_RESTART = 0x90DF
DO_SHOOT = 0x9076
DO_STRIKE = 0x92ED
SWORD = 0x0E
FIGHT_RUNS = 500                # blows per pair in the outcome table
RANDOM_STATE = (0xB70E, 0xB712, 0xB713)   # RANDOM_LAST and RANDOM_POINTER


class Arena:
    """DO_ATTACK called on its own, on a machine taken from a game at its first
    prompt: the records, the variables and RANDOM's state are the game's. The
    world is put back after every blow (a kill empties a slot and drops what
    the dead held) except RANDOM's state, which runs on as it would."""

    WORLD = (0xB6DA, 0xCB43)    # the variables to the end of CHARACTERS

    def __init__(self, memory):
        self.machine = Machine(memory)
        self.memory = self.machine.memory
        self.saved = bytes(self.memory[self.WORLD[0]:self.WORLD[1]])

    def record(self, number: int) -> int:
        address = OBJECT_INDEX
        while self.memory[address] != 0xFF:
            if self.memory[address] == number:
                return self.memory[address + 1] | (self.memory[address + 2] << 8)
            address += 3
        raise KeyError(number)

    def blow(self, attacker: int, target: int, weapon: int = 0xFF,
             strength: int | None = None, defence: int | None = None) -> dict:
        from skoolkit.simutils import A, B
        memory = self.memory
        random_state = [memory[a] for a in RANDOM_STATE]
        memory[self.WORLD[0]:self.WORLD[1]] = self.saved
        for a, v in zip(RANDOM_STATE, random_state):
            memory[a] = v
        att, tgt = self.record(attacker), self.record(target)
        if strength is not None:
            memory[att + 5] = strength
        if defence is not None:
            memory[tgt + 6] = defence
        memory[ACTING], memory[TARGET], memory[INSTRUMENT] = attacker, target, weapon
        memory[ACTOR], memory[ACTOR + 1] = att & 0xFF, att >> 8
        memory[0xB708], memory[0xB709] = tgt & 0xFF, tgt >> 8
        wpn = self.record(weapon) if weapon != 0xFF else 0
        memory[0xB70A], memory[0xB70B] = wpn & 0xFF, wpn >> 8
        memory[DOING_IT] = 1
        memory[PRINTING_ON] = 0
        out = {"outcome": "refused", "blow": None, "guard": None, "message": None}
        before = (memory[tgt + 5], memory[tgt + 6])

        def weighed(m):
            out["blow"], out["guard"] = m.registers[B], m.registers[A]
            out["outcome"] = "wasted"
        def wound(m):
            out["outcome"] = "wound"
            out["margin"] = out["blow"] - out["guard"]
        def printed(m):
            out["after"] = (memory[tgt + 5], memory[tgt + 6])
        def kill(m):
            # Decided: stop before KILL, which for the player would end the
            # game and wait for a key.
            out["outcome"] = "kill"
            raise Halt()
        try:
            self.machine.call(DO_ATTACK, watch={BLOW_AND_GUARD: weighed, WOUND_MARGIN: wound,
                                                WOUND_PRINT: printed, A_KILL: kill})
        except Halt:
            pass
        out["before"] = before
        return out

    def wear(self, target: int, margin: int) -> tuple[int, int, int]:
        """The wound branch of DO_ATTACK on its own, for an exact margin: run
        from $91C1 with the blow and the guard in B and A. Returns the target's
        strength and defence after, and the WOUNDS entry the message came from."""
        from skoolkit.simutils import H, L
        memory = self.memory
        memory[self.WORLD[0]:self.WORLD[1]] = self.saved
        tgt = self.record(target)
        memory[0xB708], memory[0xB709] = tgt & 0xFF, tgt >> 8
        memory[DOING_IT], memory[PRINTING_ON] = 1, 0
        seen = {}

        def printed(m):
            seen["message"] = (m.registers[H] << 8) | m.registers[L]
        guard = 100
        self.machine.call(BLOW_AND_GUARD, {"A": guard, "B": guard + margin, "IX": tgt},
                          watch={WOUND_PRINT: printed})
        return memory[tgt + 5], memory[tgt + 6], seen.get("message")


def expected_wear(strength: int, defence: int, margin: int) -> tuple[int, int]:
    """What DO_ATTACK's wear should leave, worked out from its instructions:
    RLCA doubles the margin, RRCA twice rotates it -- the second time the
    margin's bit 0 goes into bit 7 -- and CPL then ADD takes that value plus
    one off the strength, written back only if it did not go below zero; the
    defence the same with one more RRCA."""
    def rrca(v):
        return ((v >> 1) | ((v & 1) << 7)) & 0xFF
    first = rrca(rrca((margin << 1) & 0xFF))
    second = rrca(first)
    new_strength = strength - first - 1 if strength > first else strength
    new_defence = defence - second - 1 if defence > second else defence
    return new_strength, new_defence


GOBLIN_RETURNS_AT = 0xA448
THORIN_KILLED = 0xA73B
EMPTY_OUT = 0x9D53
BROKEN_OR_DEAD = 0xA18C
CANCEL_ORDERS = 0x7F60
FIGHT_WAITS = 10                # WAITs before the warg meets the wood elf


def fight_probes(log: list, memory, stop_on_death: bool = False) -> dict:
    """Probes that record every real blow DO_ATTACK weighs."""
    from skoolkit.simutils import A, B

    current = {}

    def start(s):
        current.clear()
        current.update({"attacker": memory[ACTING], "target": memory[TARGET],
                        "weapon": memory[INSTRUMENT]})

    def weighed(s):
        target = memory[0xB708] | (memory[0xB709] << 8)
        entry = dict(current, blow=s.registers[B], guard=s.registers[A], outcome="wasted",
                     record=target, before=(memory[target + 5], memory[target + 6]))
        log.append(entry)

    def wound(s):
        if log:
            log[-1]["outcome"] = "wound"

    def printed(s):
        if log:
            target = log[-1]["record"]
            log[-1]["after"] = (memory[target + 5], memory[target + 6])

    def kill(s):
        if log:
            log[-1]["outcome"] = "kill"

    def dies(s):
        if stop_on_death:
            raise Halt()

    return {DO_ATTACK: start, BLOW_AND_GUARD: weighed, WOUND_MARGIN: wound,
            WOUND_PRINT: printed, A_KILL: kill, PLAYER_DIES: dies}


def fighting_page(data: Data, link, log) -> str:
    from hobbit_drive import Hobbit
    from skoolkit.simutils import A

    memory = data.memory
    L = link
    rec = lambda n: data.record[n]["start"]
    strength = lambda n: memory[rec(n) + 5]
    defence = lambda n: memory[rec(n) + 6]
    side_bits = lambda n: memory[rec(n) + 4] & 0x70
    SIDES = {0x10: "the player's", 0x20: "the goblins'", 0x40: "the elves'"}

    def sides_text(n):
        bits = side_bits(n)
        names = [name for bit, name in SIDES.items() if bits & bit]
        return " and ".join(names) if names else "none"

    cast = [0] + sorted(n for n in data.record if 0x3C <= n <= 0x4C)
    # Characters with the same strength, defence and side are one row: the
    # goblins, the trolls.
    groups: dict[tuple, list] = {}
    for n in cast:
        groups.setdefault((strength(n), defence(n), side_bits(n)), []).append(n)
    reps = [members for members in groups.values()]

    def group_name(members) -> str:
        if len(members) == 1:
            return _char_link(data, members[0])
        return f"{_char_link(data, members[0])} and {words(len(members) - 1)} more like it"

    cast_rows = [[group_name(m), str(strength(m[0])), str(defence(m[0])), esc(sides_text(m[0]))]
                 for m in reps]

    # ---- the dice: JOSTLE on its own, many times
    game = Hobbit()
    first_prompt = bytes(game.memory)
    machine = Machine(first_prompt)
    from collections import Counter
    added = Counter()
    base = 128
    draws = 5000
    for _ in range(draws):
        machine.call(JOSTLE, {"A": base})
        added[machine.registers[A]] += 1
    dice_rows = []
    for value in sorted(added):
        shift = value - base
        dice_rows.append([str(value), f"{shift:+d}" if value else "0 (a negative draw)",
                          f"{100 * added[value] / draws:.1f}%"])
    zero_share = 100 * added[0] / draws

    # ---- who can hurt whom
    arena = Arena(first_prompt)
    attackers = [([0], "the player, bare-handed", 0xFF), ([0], "the player, with the sword", SWORD)]
    attackers += [(m, None, 0xFF) for m in reps if m[0] != 0]
    targets = reps
    grid_rows = []
    for members, label, weapon in attackers:
        who = members[0]
        row = [label or group_name(members)]
        for target_members in targets:
            target = target_members[0]
            if target == who:
                row.append("-")
                continue
            counts = Counter(arena.blow(who, target, weapon)["outcome"]
                             for _ in range(FIGHT_RUNS))
            if counts["refused"] == FIGHT_RUNS:
                row.append("<i>same side</i>")
                continue
            kill = 100 * counts["kill"] / FIGHT_RUNS
            wound = 100 * counts["wound"] / FIGHT_RUNS
            row.append(f"{kill:.0f} / {wound:.0f}")
        grid_rows.append(row)
    grid_head = ["Attacker (strength)"] + [
        f"{group_name(m)} ({defence(m[0])})" for m in targets]
    for row, (members, label, weapon) in zip(grid_rows, attackers):
        total = strength(members[0]) + (strength(weapon) if weapon != 0xFF else 0)
        row[0] += f" ({min(total, 255)})"

    # ---- wearing down, margin by margin
    wear_targets = [0x3F, 0x47, 0x3D]
    wear_rows = []
    mismatches = 0
    for margin in range(1, 17):
        row = [str(margin)]
        message = None
        for t in wear_targets:
            s_after, d_after, message = arena.wear(t, margin)
            expected = expected_wear(strength(t), defence(t), margin)
            ok = (s_after, d_after) == expected
            mismatches += not ok
            row.append(f"{s_after}/{d_after}" + ("" if ok else " (!)"))
        wear_rows.append(row + [f"{margin}, message ${message:04X}"])
    if mismatches:
        log(f"  fighting: {mismatches} wear results differ from the formula")

    # ---- the wound messages
    wound_rows = []
    for index in range(WOUNDS_COUNT + 1):
        address = memory[WOUNDS + 2 * index] | (memory[WOUNDS + 2 * index + 1] << 8)
        text = game_says(address, 0x43, 0x40)
        margin = index if index else None
        where = (f"${WOUNDS + 2 * index:04X}" + (" (after the table: ONE_PLACE's first bytes)"
                                                 if index == WOUNDS_COUNT else ""))
        wound_rows.append([where, str(index), f"${address:04X}",
                           str(margin) if margin else "never", said(text)])

    # ---- a real fight: the warg and the wood elf, unstaged
    session = Session()
    blows: list = []
    probes = fight_probes(blows, session.memory)
    wait_text = []
    for turn in range(1, FIGHT_WAITS + 1):
        before = len(blows)
        session.say("WAIT", probes)
        for b in blows[before:]:
            b["turn"] = turn
    warg_fight = [b for b in blows if {b["attacker"], b["target"]} & {0x43, 0x40}]

    def blow_rows(entries) -> list:
        rows = []
        for b in entries:
            weapon = "" if b["weapon"] == 0xFF else f" with the {esc(data.name(b['weapon']))}"
            after = b.get("after")
            result = b["outcome"]
            if result == "wound":
                result += f", margin {b['blow'] - b['guard']}"
            rows.append([str(b.get("turn", "")), esc(data.name(b["attacker"])) + weapon,
                         esc(data.name(b["target"])),
                         f"{b['before'][0]}/{b['before'][1]}", str(b["blow"]), str(b["guard"]),
                         result, f"{after[0]}/{after[1]}" if after else "-"])
        return rows

    # ---- a staged fight: the player, the sword and Thorin
    duel = Session()
    sword = rec(SWORD)
    player_where = duel.memory[rec(0) + 16]
    duel.memory[sword + 1] = 0          # held by the player
    duel.memory[sword + 16] = player_where
    duel_blows: list = []
    probes = fight_probes(duel_blows, duel.memory, stop_on_death=True)
    duel_text = []
    ended = "neither died in twelve turns"
    for turn in range(1, 13):
        before = len(duel_blows)
        start = len(duel.printed)
        try:
            duel.say("ATTACK THORIN WITH SWORD", probes)
        except Halt:
            for b in duel_blows[before:]:
                b["turn"] = turn
            duel_text.append((turn, duel.text(start=start)))
            ended = f"the player was killed on turn {turn}"
            break
        for b in duel_blows[before:]:
            b["turn"] = turn
        duel_text.append((turn, duel.text(start=start)))
        if duel.memory[rec(0x3F) + 7] & 0x08:
            ended = f"Thorin was killed on turn {turn}"
            break
    duel_log = "\n".join(text.replace("> ", "").strip("\n") for _, text in duel_text)
    log(f"  fighting: the duel ended: {ended}; {len(duel_blows)} blows")

    parts = [
        "<p>Every fight in the game -- the player's, and the characters' among themselves -- "
        f"is one routine, {L(DO_ATTACK)}, reached through ATTACK WITH (and STRIKE WITH and "
        "THROW AT). This page reads it line by line, then runs it: on its own, thousands of "
        "times, to see who can hurt whom, and in two real fights.</p>",

        "<h3>A blow, step by step</h3>",
        "<ol>",
        f"<li>{L(SAME_SIDE)}: an attacker and a target that share a side (bits 4-6 of byte 4 "
        "of their records) do not fight -- except that the player attacking a friend first "
        "takes the friend off the player's side, for good.</li>",
        "<li>The weapon's noun, or FIST, is kept for the messages. A weapon that is in more "
        "than one place (a river, a door) cannot kill.</li>",
        "<li>The <b>blow</b>: the attacker's strength (byte 5) plus the weapon's, at most 255, "
        f"then jostled by {L(JOSTLE)}.</li>",
        f"<li>{L(FOR_REAL)}: a test ends here, so a character considering an attack decides "
        "only that it could.</li>",
        "<li>The <b>guard</b>: the target's defence (byte 6), jostled the same way.</li>",
        "<li>Guard no less than the blow: wasted, and the game says the defence was too "
        "strong.</li>",
        "<li>Blow more than 16 above the guard: one well-placed blow kills "
        f"({L(KILL)}).</li>",
        f"<li>Otherwise it is a wound: the margin, 1 to 16, picks a message from {L(WOUNDS)} "
        "and wears the target's strength and defence down.</li>",
        "</ol>",

        "<h3>The dice are loaded</h3>",
        f"<p>{L(JOSTLE)} is meant to add a random -10 to +10 ({L(RANDOM)} with a limit of "
        "10) and keep the result to 0-255. Two things make it something else. RANDOM draws "
        "a byte, halves it until it is no more than twice the limit and takes the limit off, "
        "so a byte above 20 always lands in 10-20 and comes out as 0 to +10; only a byte "
        "of 0-9 gives a negative number. And JOSTLE's clamp is written for a result that "
        "overflowed upwards: after ADD A,B it takes the carry to mean out of range, and "
        "then gives 0 if the draw was negative, 255 if not. But adding a negative draw "
        "(a byte of $F6-$FF) to anything of 10 or more always carries -- that is just "
        "subtraction -- so every negative draw turns the whole value to 0. (Below 10 it "
        "fails the other way: no carry, and 5 - 8 wraps round to 253.)</p>",
        f"<p>Measured: JOSTLE called {draws} times with 128, on a machine taken from a game "
        "at its first prompt, RANDOM's state running on from call to call:</p>",
        table(["Result", "Added", "Share"], dice_rows),
        f"<p>So a blow or a guard is its strength plus 0 to 10 -- plus 1 to 5 twice as often "
        f"as the rest -- and about one time in {round(100 / zero_share) if zero_share else 0} "
        f"({zero_share:.1f}%) it is 0. A blow of 0 is always wasted; a guard of 0 lets "
        "anything with a strength of 17 or more kill with one blow. That, more than the "
        "strengths, is what decides many fights.</p>",

        "<h3>The cast</h3>",
        "<p>Strength, defence and side, from the records as the tape has them (characters "
        "alike in all three are one row). The short strong sword adds "
        f"{strength(SWORD)} to its bearer's blow.</p>",
        table(["Character", "Strength", "Defence", "Side"], cast_rows),

        "<h3>Who can hurt whom</h3>",
        f"<p>{L(DO_ATTACK)} itself, called {FIGHT_RUNS} times for each pair on the machine "
        "above, with the records and variables put back after every blow and RANDOM's "
        "state left to run on. Each cell is the share of blows that killed, then the share "
        "that wounded; the rest were wasted. <i>Same side</i> is SAME_SIDE refusing "
        "(the player's own side is left out of that: the player may attack anyone).</p>",
        table(grid_head, grid_rows),
        "<p>Read down a column for how safe a character is. The player's bare hands "
        "(64 + 0..10) can never beat a goblin's ordinary guard (96 + 0..10) -- but when the "
        "goblin's guard comes out 0, one blow kills it. The trolls and the dragon are out of "
        "reach of the player's ordinary blow, even with the sword, and fall to it only when "
        "their guard collapses the same way.</p>",

        "<h3>Wearing down</h3>",
        f"<p>A wound takes something off the target's strength and defence. {L(DO_ATTACK)} "
        "doubles the margin to index WOUNDS (RLCA), then halves it back and halves it again "
        "with RRCA -- a rotate, where a shift was surely meant, so the margin's lowest bit "
        "goes round into bit 7. That value plus one comes off the strength, and the next "
        "rotate plus one off the defence, each only if it does not take them below zero. "
        "So an even margin m takes m/2 + 1 off the strength, and an odd one tries to take "
        "129 or more: a target of 128 or less is spared entirely, a stronger one loses "
        "nearly all of it. The defence loses a quarter of the margin plus one when the "
        "margin is a multiple of 4, about 65 when it is one more than that, and 129 or more "
        "otherwise -- again nothing for a weak target and most of it for a strong one. "
        "The table is the wound branch run from $91C1 with the blow and the "
        "guard set for each margin, against three targets as the tape has them; each result "
        "matched the value worked out from the instructions beforehand "
        f"({'all ' + str(16 * len(wear_targets)) if not mismatches else str(mismatches) + ' did not'}).</p>",
        table(["Margin"] + [f"{_char_link(data, t)} ({strength(t)}/{defence(t)})"
                            for t in wear_targets] + ["WOUNDS entry"], wear_rows),
        "<p>See <a href=\"bugs.html\">Bugs</a>. A troll, at 160/160, loses nearly all its "
        "strength to any odd margin and nearly all its defence to a margin of 2, 6, 10 or "
        "14 -- which, with the dice above, makes a long fight with a troll a matter of luck "
        "rather than strength.</p>",

        "<h3>What a wound is called</h3>",
        f"<p>The message comes from {L(WOUNDS)} at twice the margin. The margins run from 1, "
        "so the table is read one entry late: its first message is never shown, and a "
        "margin of exactly 16 reads the word after the table, the first two bytes of "
        f"{L(ONE_PLACE)}'s code -- $2ADD, an address in the ROM, whose bytes RUN_MESSAGE "
        "reads as a message. Each run through RUN_MESSAGE here, with the vicious warg "
        "as the actor and the wood elf as the target:</p>",
        table(["Word at", "Entry", "Message", "Margin", "Prints"], wound_rows),

        "<h3>A fight nobody sees</h3>",
        f"<p>From <a href=\"character-lives.html\">How the characters live</a>: {FIGHT_WAITS} "
        "turns of WAIT from the first prompt, nothing staged, and on the last the vicious "
        "warg meets the wood elf. Every real blow DO_ATTACK weighed, read at $91C1 (the "
        "blow and guard after the dice) and $91FB (the target after the wear):</p>",
        table(["Turn", "Attacker", "Target", "Target before", "Blow", "Guard", "Outcome",
               "Target after"], blow_rows(warg_fight)),

        "<h3>A fight staged</h3>",
        "<p>The player given the short strong sword in Bag End (its holder and location "
        "poked), and ATTACK THORIN WITH SWORD typed every turn until one of them died "
        f"({esc(ended)}). The first blow takes Thorin off the player's side; his reaction "
        "script (ON_ATTACK_WITH) then attacks back every turn. Every blow:</p>",
        table(["Turn", "Attacker", "Target", "Target before", "Blow", "Guard", "Outcome",
               "Target after"], blow_rows(duel_blows)),
        "<p>What the game printed:</p>",
        pre(duel_log),
        f"<p>A short fight, and a typical one. Thorin's strength, {strength(0x3F)}, against "
        f"the player's defence of {defence(0)} leaves a margin of at least "
        f"{strength(0x3F) - defence(0) - 10} -- far more than 16 -- so unless the dice give "
        "his blow a 0 his first reply kills, and the player's own first blow has to be the "
        "one that decides it.</p>",

        "<h3>Sides, and killing</h3>",
        "<p>The sides are the player's (the player, Gandalf, Thorin, Bard), the goblins' (the "
        "goblins, Gollum) and the elves' (the wood elf, the butler), with Elrond on both "
        "the player's and the elves'; the dragon, the warg and the trolls are on none, so "
        "anyone may fight them and they anyone (the table above, read from byte 4). "
        f"{L(KILL)}: the player's death is {L(PLAYER_DIES)}; anyone else is marked dead "
        f"(flag bit 3), drops what it holds ({L(EMPTY_OUT)}), loses its slot in CHARACTERS, "
        f"is renamed DEAD ({L(BROKEN_OR_DEAD)}) and has its orders thrown away "
        f"({L(CANCEL_ORDERS)}). A goblin comes straight back ({L(GOBLIN_RETURNS_AT)}), and "
        f"Thorin's death shatters the small curious key ({L(THORIN_KILLED)}). The other "
        f"ways to kill -- {L(DO_SHOOT)}, the dragon's BURN -- do not go through the blow at "
        "all.</p>",

        "<h3>What is confirmed, and what is not</h3>",
        "<ul>",
        "<li><b>Run</b> when this page was built: the dice, every cell of the table, the wear "
        "for every margin against three targets (checked against the arithmetic worked out "
        "from the instructions), every wound message, and both fights.</li>",
        "<li><b>Read</b>: the order of the steps, the sides and what KILL does.</li>",
        "<li>The table's shares are from one run of RANDOM's state, with DO_ATTACK called "
        "directly. RANDOM also mixes in a byte at an offset DE from its pointer, DE being "
        "whatever its caller left there, so the sequence it gives depends on the calling "
        "context as well as on the seed (R at the start); in play the shares will differ "
        "somewhat, a cell with a few per cent most of all.</li>",
        "</ul>",
    ]
    return "\n".join(parts)


# --------------------------------------------------------------------------
# Messages: the bytecode, run element by element.
# --------------------------------------------------------------------------

CONTROL_CODES = 0x7295
CONTROL_COUNT = 0x17
COMMON_WORDS = 0xAD3D
MESSAGES = 0xAD7D
MESSAGE_ELEMENT = 0x72F4        # RUN_MESSAGE: IX at the next element
PRINT_WORD = 0x74BA
ARTICLE = 0x743F
ARTICLES = 0xAD2D
ENDINGS = 0xB71F
STORY_CHAR = 0x86A1
STORY_NEW_LINE = 0x86D8         # STORY_CHAR: a line is done, the pause next
STORY_SCROLL = 0x8701           # STORY_CHAR: the pause over, scroll
INPUT_CHAR = 0x85B7
NARROW_CHAR = 0x87C9
FONT = 0x8822
NO_PAUSE_LINES = 0xB716
INPUT_STYLE = 0xB701
NARRATE_ACTION_AT = 0x712B
DRUNK = 0xB700
STORY_COLUMNS = 0x869B          # columns left on the story line, of 42
STORY_LAST = 0x86A0             # the last character printed on it, 0 at its start
# The message followed: one of the wounds, chosen because it has every kind
# of element and prints differently for every actor.
FOLLOWED_MESSAGE = 0xAF20

# What each control code does, in this page's words (the handlers are read
# from CONTROL_CODES at build time).
CONTROL_MEANINGS = {
    0x00: "an object whose record the caller pushed, with no article",
    0x01: "a word the caller pushed",
    0x02: "jump by the signed byte after it",
    0x03: "the instrument's noun (WEAPON_NAME)",
    0x04: "a word the caller pushed, with its article",
    0x05: "nothing",
    0x06: "the actor's name, or YOU",
    0x07: "the target, with its article",
    0x08: "a backspace: the next word joins the last",
    0x09: "the instrument, with its article",
    0x0A: "nothing",
    0x0B: "the message the signed byte after it points at",
    0x0C: "HIS, or YOUR when the actor is the player",
    0x0D: "a new line (the literal character)",
    0x0E: "HIS, or YOUR, for the target",
    0x0F: "nothing",
    0x10: "the actor and IS, or YOU ARE",
    0x11: "the target and IS, or YOU ARE",
    0x12: "nothing",
    0x13: "a pushed object and IS",
    0x14: "end: a new line",
    0x15: "end: a full stop and a new line",
    0x16: "end",
}


def message_run(address: int, actor: int, target: int, weapon: int | None = None) -> list:
    """RUN_MESSAGE on one message, from a game at its first prompt with the
    sentence made about `actor` and `target`: each element's address and what
    was printed while it was the current one."""
    from skoolkit.simutils import A, IXh, IXl

    speaker = _speaker()
    machine = Machine(bytes(speaker.memory))
    memory = machine.memory
    records = {r["number"]: r["start"] for r in bh.object_records(memory)}
    memory[ACTING] = actor
    memory[ACTOR], memory[ACTOR + 1] = records[actor] & 0xFF, records[actor] >> 8
    memory[TARGET] = target
    memory[0xB708], memory[0xB709] = records[target] & 0xFF, records[target] >> 8
    if weapon is not None:
        memory[INSTRUMENT] = weapon
        memory[0xB70A], memory[0xB70B] = records[weapon] & 0xFF, records[weapon] >> 8
        memory[0xB6FC], memory[0xB6FD] = memory[records[weapon] + 8], memory[records[weapon] + 9]
    memory[DOING_IT], memory[PRINTING_ON], memory[INPUT_STYLE] = 1, 1, 0
    # At the start of a fresh story line, so that PRINT_WORD does not wrap it.
    memory[STORY_COLUMNS], memory[STORY_LAST] = 42, 0
    elements: list[list] = []

    def element(m):
        elements.append([(m.registers[IXh] << 8) | m.registers[IXl], ""])

    def printed(m):
        if elements:
            char = m.registers[A]
            elements[-1][1] += chr(char) if 32 <= char < 127 else "\n" if char == 13 else ""
    machine.call(RUN_MESSAGE_HL, {"HL": address}, watch={MESSAGE_ELEMENT: element,
                                                         PRINTED: printed})
    return elements


def element_kind(data: Data, address: int) -> tuple[str, str, int]:
    """One message element as RUN_MESSAGE reads it: its kind, what it holds,
    and its length."""
    memory = data.memory
    byte = memory[address]
    if byte & 0x80:
        reference = ((byte & 0x7F) << 8) | memory[address + 1]
        flags = reference >> 12
        ends = {2: "; ends the message", 3: "; ends with a full stop",
                6: "; ends with a new line"}.get(flags, "")
        return "word", f"{esc(data.word(reference))}, flags ${flags:X}{ends}", 2
    if byte >= 0x60:
        slot = COMMON_WORDS + 2 * (byte - 0x60)
        reference = memory[slot] | (memory[slot + 1] << 8)
        return "common word", f"${byte:02X}: {esc(data.word(reference))}", 1
    if byte >= 0x20:
        return "literal", esc(repr(chr(byte))), 1
    length = 2 if byte in (0x02, 0x0B) else 1
    return "control code", f"${byte:02X}: {esc(CONTROL_MEANINGS.get(byte, '?'))}", length


def screen_image(memory, scale: int = 1):
    """The whole screen, bitmap and attributes, as a PIL image."""
    from PIL import Image

    rows = bytearray()
    for y in range(192):
        row = 0x4000 | ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
        rows += bytes(memory[row:row + 32])
    mask = Image.frombytes("1", (256, 192), bytes(rows)).convert("L")
    attributes = bytes(memory[0x5800:0x5B00])
    ink = Image.new("RGB", (32, 24))
    paper = Image.new("RGB", (32, 24))
    ink.putdata([PALETTE[(8 if a & 0x40 else 0) + (a & 7)] for a in attributes])
    paper.putdata([PALETTE[(8 if a & 0x40 else 0) + ((a >> 3) & 7)] for a in attributes])
    image = Image.composite(ink.resize((256, 192), Image.NEAREST),
                            paper.resize((256, 192), Image.NEAREST), mask)
    return image.resize((256 * scale, 192 * scale), Image.NEAREST) if scale > 1 else image


def with_border(image, colour, width: int = 16):
    from PIL import Image
    out = Image.new("RGB", (image.width + 2 * width, image.height + 2 * width), colour)
    out.paste(image, (width, width))
    return out


def messages_page(data: Data, link, log) -> str:
    memory = data.memory
    L = link
    image_dir = data.html_dir / IMAGE_DIR

    # ---- the control codes and the common words, read from the game
    control_rows = []
    for code_ in range(CONTROL_COUNT):
        handler = memory[CONTROL_CODES + 2 * code_] | (memory[CONTROL_CODES + 2 * code_ + 1] << 8)
        control_rows.append([f"${code_:02X}", link(handler), esc(CONTROL_MEANINGS[code_])])
    common = []
    for i in range(32):
        slot = COMMON_WORDS + 2 * i
        common.append(f"${0x60 + i:02X} {esc(data.word(memory[slot] | (memory[slot + 1] << 8)))}")
    common_rows = [common[i:i + 8] for i in range(0, 32, 8)]

    # ---- one message, element by element, for three speakers
    elements, _ = bh.message_elements(memory, FOLLOWED_MESSAGE)
    runs = [(0, 0x3F, SWORD), (0x3F, 0, SWORD), (0x43, 0x40, None)]
    run_texts = []
    for actor, target, weapon in runs:
        run = message_run(FOLLOWED_MESSAGE, actor, target, weapon)
        by_element = {}
        for at, text in run:
            by_element[at] = by_element.get(at, "") + text
        run_texts.append(by_element)
    element_rows = []
    for at in elements:
        kind, what, length = element_kind(data, at)
        row = [f"${at:04X}", hexbytes(memory[at:at + length]), kind, what]
        row += [esc(t.get(at, "")).replace("\n", " <i>(new line)</i>") or "-" for t in run_texts]
        element_rows.append(row)
    whole = ["".join(t.get(at, "") for at in elements).strip() for t in run_texts]
    run_heads = [f"{esc(data.name(a))} to {esc(data.name(t))}" for a, t, _ in runs]

    # ---- the endings and the articles
    endings = []
    for i in range(6):
        raw = memory[ENDINGS + 4 * i:ENDINGS + 4 * i + 4]
        text = "".join("(backspace)" if b == 8 else chr(b) for b in raw if b)
        endings.append([str(i), hexbytes(raw), esc(text)])
    articles = []
    for i in range(4):
        plain_ = memory[ARTICLES + 2 * i] | (memory[ARTICLES + 2 * i + 1] << 8)
        told = memory[ARTICLES + 8 + 2 * i] | (memory[ARTICLES + 9 + 2 * i] << 8)
        articles.append([str(i), esc(data.word(plain_)), esc(data.word(told))])

    # ---- compression, over every message
    starts = bh.message_starts(memory)
    counts = {"word": 0, "common word": 0, "literal": 0, "control code": 0}
    chars = {"word": 0, "common word": 0, "literal": 0}
    total_bytes = 0
    for start in starts:
        els, end = bh.message_elements(memory, start)
        total_bytes += end - start
        for at in els:
            kind, _, _ = element_kind(data, at)
            counts[kind] += 1
            byte = memory[at]
            if kind == "word":
                chars["word"] += len(data.word(((byte & 0x7F) << 8) | memory[at + 1])) + 1
            elif kind == "common word":
                slot = COMMON_WORDS + 2 * (byte - 0x60)
                chars["common word"] += len(data.word(memory[slot] | (memory[slot + 1] << 8))) + 1
            elif kind == "literal":
                chars["literal"] += 1
    fixed = sum(chars.values())
    # And printed: each message run through RUN_MESSAGE with the player acting
    # (the codes that print a pushed value print whatever is on the stack, so
    # those messages are left out of this count).
    printed_total = printed_bytes = skipped = 0
    for start in starts:
        els, end = bh.message_elements(memory, start)
        if any(memory[a] in (0x00, 0x01, 0x04, 0x13) and not memory[a] & 0x80 for a in els):
            skipped += 1
            continue
        text = game_says(start, 0)
        printed_total += len(text)
        printed_bytes += end - start
    rooms = len(data.rooms)
    objects = len(data.records)

    # ---- the pause, measured
    session = Session()
    lines = []
    marks = {}

    def line_done(s):
        marks["t"] = s.tstates
        marks["left"] = s.memory[NO_PAUSE_LINES]

    def scrolled(s):
        if "t" in marks:
            lines.append((marks["left"], s.tstates - marks.pop("t")))
    session.say(PARSE_LINE, {STORY_NEW_LINE: line_done, STORY_SCROLL: scrolled})
    pause_rows = [[str(n), str(left), f"{t:,}", f"{t / bh.TSTATES_PER_SECOND:.2f} s"]
                  for n, (left, t) in enumerate(lines, 1)]
    session.say("XYZZY")
    screen = screen_image(session.memory)
    screen.save(image_dir / "messages_screen.png")

    parts = [
        f"<p>The game has {len(starts)} messages, {rooms} room descriptions and names and "
        f"{objects} object names, and holds none of them as text. A message is a small program for "
        f"{L(RUN_MESSAGE)}, and a name is three dictionary references. This page takes "
        "one message apart, runs it for three different speakers through the game's own "
        "code, measures what the scheme saves, and follows the text to the screen.</p>",

        "<h3>The bytecode</h3>",
        f"<p>{L(RUN_MESSAGE)} walks the message a byte at a time (<i>read</i>):</p>",
        table(["Byte", "Means"], [
            ["bit 7 set", "the first of a two-byte word reference, high byte first: twelve "
                          "bits of dictionary offset from $6000 and a flag nibble; flags 2, 3 "
                          f"and 6 also end the message (plainly, with a full stop, or with a "
                          f"new line). {L(PRINT_WORD)} prints it"],
            ["$60-$7F", f"one of the 32 common words in {L(COMMON_WORDS)}, a byte each"],
            ["$20-$5F", "a literal character: punctuation, and words the dictionary lacks, "
                        "spelled out"],
            ["$00-$13", f"a control code: its handler from {L(CONTROL_CODES)} is called, "
                        "and the message goes on"],
            ["$14-$16", "a control code that ends the message"],
        ]),
        "<p>The control codes, with their handlers read from the table:</p>",
        table(["Code", "Handler", "Prints"], control_rows),
        "<p>And the common words, the byte that stands for each:</p>",
        table(["", "", "", "", "", "", "", ""], common_rows),

        "<h3>One message, taken apart</h3>",
        f"<p>The message at ${FOLLOWED_MESSAGE:04X} is one of the wounds a fight can "
        "print. Each element as RUN_MESSAGE reads it, and what the game printed while it "
        "was the element in hand -- probed at $72F4, where RUN_MESSAGE picks up the next "
        "element, and at PRINT_CHAR -- for three speakers: the player attacking Thorin "
        "with the sword, Thorin attacking the player with it, and the warg attacking the "
        "wood elf bare-handed (so there is no instrument's noun to print):</p>",
        table(["At", "Bytes", "Kind", "Holds"] + run_heads, element_rows),
        "<p>Whole, as the three printed it:</p>",
        "<ul>" + "".join(f"<li>{h}: {said(w)}</li>" for h, w in zip(run_heads, whole)) + "</ul>",
        "<p>Each was started at the beginning of a story line. Where the next word would "
        f"have passed the 42nd column, {L(PRINT_WORD)} began a new line before it -- the "
        "<i>(new line)</i> in the table -- and the full stop that ends the message is "
        "followed by one too.</p>",
        f"<p>{len(elements)} elements, {bh.message_elements(memory, FOLLOWED_MESSAGE)[1] - FOLLOWED_MESSAGE} "
        "bytes. The same bytes say YOU or THORIN, YOUR or HIS, ARE or IS; and the verb "
        f"agrees with its subject: {L(PRINT_WORD)} adds an ending when the sentence is "
        f"about someone other than the player ({L(ACTING)} not zero), if the "
        "word allows one (bit 7 of its second dictionary byte) and its flags do not forbid "
        "it: $40 always inflects, $50 never, $10 agrees with the target instead of the "
        "actor, anything else with the actor.</p>",

        "<h3>Endings and articles</h3>",
        f"<p>The ending is named by bits 5-7 of the word's third byte, from {L(ENDINGS)}; "
        "the fourth is how CARRY becomes CARRIES -- a backspace takes the Y back off:</p>",
        table(["Ending", "Bytes", "Adds"], endings),
        f"<p>A noun's reference carries its article ({L(ARTICLE)}): bit 7 marks a proper "
        "name, printed with no article and a capital (except YOU); otherwise bits 4-6 pick "
        f"one of four from {L(ARTICLES)} -- or, in the input window and while an action "
        "is being narrated, from the second four, which say THE for everything but SOME:</p>",
        table(["Choice", "Normally", "Narrating"], articles),
        f"<p>Sentences about actions are not stored at all: {L(NARRATE_ACTION_AT)} builds "
        "them from the action's pattern (see <a href=\"parsing.html\">How a sentence is "
        "understood</a>), which is why the characters' doings read so alike.</p>",

        "<h3>What it saves</h3>",
        f"<p>Measured over all {len(starts)} stored messages, ${MESSAGES:04X} on, walked by the build's decoder (the same tests RUN_MESSAGE makes): "
        f"{total_bytes} bytes hold {counts['word']} word references, "
        f"{counts['common word']} common-word bytes, {counts['literal']} literal characters "
        f"and {counts['control code']} control codes. Spelled out, the fixed text is "
        f"{fixed} characters with its spaces -- {chars['word']} from the references, "
        f"{chars['common word']} from the common words and {chars['literal']} literals -- "
        f"so {fixed / total_bytes:.1f} characters to the byte before any name is "
        "printed. Run through RUN_MESSAGE itself with the player speaking, the "
        f"{len(starts) - skipped} messages that do not print something a caller pushed "
        f"({skipped} do) printed {printed_total} characters from {printed_bytes} bytes: "
        f"{printed_total / printed_bytes:.1f} to 1. A room or object name costs six bytes "
        f"-- three references -- however long its words, and there are {rooms} rooms and "
        f"{objects} objects. The word list the messages draw on, {L(SECOND_LIST)}, is "
        "reached by no index at all: a message names each word by its offset.</p>",
        "<p>Six places inside messages are ways in of their own: five share another "
        "message's tail (the east bank of the black river is the end of the west bank's "
        "description), and one starts on the second byte of a word reference, which it "
        "reads as a control code.</p>",

        "<h3>To the screen: two windows</h3>",
        f"<p>Everything goes out through {L(PRINT_CHAR)}, which asks {L(PRINT_GATE)} "
        "first: nothing is printed unless the action is for real (DOING_IT) and printing "
        f"is on (the actor can be seen). Then {L(INPUT_STYLE)} chooses the window. The "
        f"story goes to {L(STORY_CHAR)}: row 17, in the game's own six-pixel font "
        f"({L(FONT)}, drawn by {L(NARROW_CHAR)} at any pixel, so 42 columns fit), every "
        "letter lower case except the first of a sentence, the whole window scrolling up "
        "over the picture. The parser's replies, the prompt and the tape messages go to "
        f"{L(INPUT_CHAR)}: rows 19-23, in the ROM's font and capitals. The screen after "
        "the line followed on the parsing page and then XYZZY, drawn from screen memory:</p>",
        figure("messages_screen.png", screen,
               "The story above the wavy divider, scrolled up over where Bag End's picture "
               "was; below it the input window, with the prompt and the parser's complaint "
               "about XYZZY."),
        f"<p><b>Line breaking.</b> {L(PRINT_WORD)} builds each word in WORD_BUFFER first and, "
        "if it would not fit on the line, starts a new one before it: words are never split "
        "(<i>read</i>, and visible above).</p>",
        f"<p><b>The pause.</b> At the end of each story line {L(STORY_CHAR)} counts down "
        f"{L(NO_PAUSE_LINES)}; while it lasts there is no pause, and once it is 0 the game "
        "polls the keyboard up to 32768 times before scrolling -- about 0.58 s by the "
        "instruction timings -- or less if a key is pressed. The main loop sets it to 9 "
        "before every line typed. Measured on the line followed on the parsing page, the "
        "time from the end of each story line to its scroll:</p>",
        table(["Line", "NO_PAUSE_LINES", "T-states", "Time"], pause_rows),
        "<p>The first nine lines scroll at once; the first of them waited only for the "
        "ENTER the line was typed with to be let go. From the tenth, each line waits the "
        "full count.</p>"

        "<h3>What is confirmed, and what is not</h3>",
        "<ul>",
        "<li><b>Run</b> when this page was built: the element walk and the three renderings, "
        "the printed-character count, and the pauses.</li>",
        "<li><b>Read</b>: the bytecode's grammar (proved by the build, which walks every "
        "message and checks that every pointer into them lands on a start or a known way "
        "in), the endings' and articles' choice.</li>",
        "<li><b>Not checked</b>: EMPTY's ending, which would print EMPTYIES if the word "
        "were ever inflected; and which callers push the values codes $00, $01, $04 and "
        "$13 print.</li>",
        "</ul>",
    ]
    return "\n".join(parts)


# --------------------------------------------------------------------------
# Drawing: a picture run op by op through the game's own interpreter.
# --------------------------------------------------------------------------

DRAW_LOCATION_PICTURE = 0x7F78
RUN_PICTURE = 0x7FA7
PICTURE_OP = 0x7FBC             # RUN_PICTURE's loop: IY at the next op
PICTURE_END = 0x8069
DRAW_LINE = 0x8151
FLOOD_FILL = 0x8071
PLOT_PIXEL = 0x81B5
PIXEL_ADDRESS = 0x81DE
PIXEL_SET = 0x80EE
CLEAR_CANVAS = 0x820B
PICTURE_TABLE = 0xCC00
PICTURES_ON = 0xB707
TROLLS_TURN_TO_STONE = 0xA971
NEW_GAME = 0x6C27
TOO_DARK = 0x95ED
ATTR_ROUTINES = (0x80F5, 0x8106, 0x8117, 0x8121)
DRAWING_CODE = (0x7F77, 0x824E)  # DRAW_LOCATION_PICTURE to CLEAR_CANVAS's end
FOLLOWED_PICTURE = 1             # Bag End, the first picture a game shows
TROLLS_CLEARING = 5
DAY_BYTES = (0x05, 0x28)         # what TROLLS_TURN_TO_STONE writes: cyan border and paper
LINE_GROUPS = 4                  # how many pictures to show the lines being drawn in


def op_kind(byte: int) -> str:
    """An op as RUN_PICTURE tests it, in its own order."""
    if byte == 0x00:
        return "end"
    if byte == 0x08:
        return "move"
    if byte & 0x80:
        return "line"
    if byte & 0x40:
        return "fill"
    if byte & 0x20:
        return "paint"
    return "skip"


def canvas_image(memory):
    """The top 128 scanlines and their attributes, as the game leaves them."""
    return screen_image(memory).crop((0, 0, 256, 128))


def picture_machine(clean: bytes, location: int, patch: bytes | None = None) -> Machine:
    """A machine ready to draw `location`'s picture: the game at its first
    prompt with the player standing there in the light, as hobbit_pages draws
    them. `patch` is a whole memory image whose fast-draw ranges replace the
    original's."""
    machine = Machine(clean)
    memory = machine.memory
    if patch is not None:
        for start, end in bh.FAST_DRAW_RANGES + [bh.FAST_LOW]:
            memory[start:end] = patch[start:end]
    rooms = bh.room_records(memory)
    memory[rooms[location]["start"]] |= 0x80
    player = next(r["start"] for r in bh.object_records(memory) if r["number"] == 0)
    memory[player + 16] = location
    memory[PICTURES_ON] = 1
    return machine


def draw_picture(clean: bytes, location: int, pictures: bool = False,
                 patch: bytes | None = None, stream_bytes: tuple | None = None) -> dict:
    """DRAW_LOCATION_PICTURE for one location, with a probe at every op
    RUN_PICTURE takes: its address and the T-states when it began, and (with
    `pictures`) the canvas as it stood."""
    from skoolkit.simutils import IYh, IYl, T

    machine = picture_machine(clean, location, patch)
    memory = machine.memory
    if stream_bytes is not None:
        start = bh.keyed_table(memory, PICTURE_TABLE)
        address = next(s for loc, s, _ in start if loc == location)
        memory[address], memory[address + 1] = stream_bytes
    ops = []

    def op(m):
        ops.append({"at": (m.registers[IYh] << 8) | m.registers[IYl], "t": m.registers[T],
                    "canvas": canvas_image(memory) if pictures else None})
    start_t = machine.registers[T]
    total = machine.call(DRAW_LOCATION_PICTURE, {"A": location}, watch={PICTURE_OP: op})
    end_t = machine.registers[T]
    return {"ops": ops, "start": start_t, "end": end_t, "total": total,
            "final": canvas_image(memory), "memory": memory}


def op_times(run: dict, memory) -> dict:
    """T-states by op kind: from each op's start to the next's, the first
    stretch (clearing the canvas) apart."""
    times = {"clear": run["ops"][0]["t"] - run["start"] if run["ops"] else run["total"]}
    counts = {}
    for this, following in zip(run["ops"], run["ops"][1:] + [{"t": run["end"]}]):
        kind = op_kind(memory[this["at"]])
        times[kind] = times.get(kind, 0) + following["t"] - this["t"]
        counts[kind] = counts.get(kind, 0) + 1
    return {"times": times, "counts": counts}


def routine_profile(clean: bytes, location: int, link) -> dict:
    """Every instruction of one picture's drawing, its T-states put down to the
    routine it is in."""
    machine = picture_machine(clean, location)
    regs = machine.registers
    spent: dict[int, int] = {}
    state = {"pc": None, "t": None}
    cache: dict[int, int] = {}

    def tf(pc, i, t0):
        # Called after each instruction with the T-states it began at.
        routine = cache.get(pc)
        if routine is None:
            routine = cache[pc] = link.routine(pc)
        state.setdefault("last", None)
        if state["pc"] is not None:
            spent[state["pc"]] = spent.get(state["pc"], 0) + t0 - state["t"]
        state["pc"], state["t"] = routine, t0
    from skoolkit.simutils import PC, SP, T
    memory = machine.memory
    regs[SP] = Machine.STACK
    memory[Machine.STACK], memory[Machine.STACK + 1] = Machine.RETURN_HERE & 0xFF, Machine.RETURN_HERE >> 8
    from skoolkit.simutils import A
    regs[A] = location
    start = regs[T]
    machine.sim.trace(DRAW_LOCATION_PICTURE, Machine.RETURN_HERE, 0,
                      start + 60 * bh.TSTATES_PER_SECOND, False, None, None, None,
                      lambda pc: "", tf)
    if state["pc"] is not None:
        spent[state["pc"]] = spent.get(state["pc"], 0) + regs[T] - state["t"]
    return {"spent": spent, "total": regs[T] - start}


def drawing_page(data: Data, link, log) -> str:
    from PIL import Image
    from hobbit_drive import Hobbit

    memory = data.memory
    L = link
    image_dir = data.html_dir / IMAGE_DIR
    clean = bytes(Hobbit().memory)
    seconds = lambda t: t / bh.TSTATES_PER_SECOND

    # ---- the picture table
    records = bh.keyed_table(memory, PICTURE_TABLE)
    table_rows = []
    all_runs = {}
    kinds_total: dict[str, int] = {}
    counts_total: dict[str, int] = {}
    for location, start, _ in records:
        visited = bh.picture_boundaries(memory, start)
        run = draw_picture(clean, location)
        all_runs[location] = run
        timing = op_times(run, run["memory"])
        for kind, t in timing["times"].items():
            kinds_total[kind] = kinds_total.get(kind, 0) + t
        for kind, n in timing["counts"].items():
            counts_total[kind] = counts_total.get(kind, 0) + n
        kinds = {}
        for a in visited:
            k = op_kind(memory[a])
            kinds[k] = kinds.get(k, 0) + 1
        table_rows.append([f'<a href="locations.html&#35;loc{location}">{location}</a>',
                           esc(data.room_name.get(location, "?")), link.within(start),
                           str(visited[-1] + 1 - start),
                           str(kinds.get("line", 0)), str(kinds.get("move", 0)),
                           str(kinds.get("fill", 0)), str(kinds.get("paint", 0)),
                           f"{seconds(run['total']):.1f} s"])
    total_time = sum(r["total"] for r in all_runs.values())
    pairs = []
    for location, start, _ in records:
        visited = set(bh.picture_boundaries(memory, start))
        end = max(visited)
        for other, s, _ in records:
            if other != location and start < s < end and s + 2 in visited:
                pairs.append((location, other))
    log(f"  drawing: {len(records)} pictures drawn, {seconds(total_time):.1f} s of drawing")

    # ---- Bag End, op by op
    followed = draw_picture(clean, FOLLOWED_PICTURE, pictures=True)
    fmem = followed["memory"]
    ops = followed["ops"]
    groups = []
    line_ops = [i for i, o in enumerate(ops) if op_kind(fmem[o["at"]]) in ("line", "move")]
    first_other = next((i for i, o in enumerate(ops)
                        if op_kind(fmem[o["at"]]) not in ("line", "move")), len(ops))
    size = max(1, -(-first_other // LINE_GROUPS))
    for g in range(0, first_other, size):
        groups.append((g, min(first_other, g + size)))
    for i in range(first_other, len(ops)):
        if op_kind(fmem[ops[i]["at"]]) != "end":
            groups.append((i, i + 1))
    ends_t = [o["t"] for o in ops[1:]] + [followed["end"]]
    frames = []
    for n, (a, b) in enumerate(groups):
        after = ops[b]["canvas"] if b < len(ops) else followed["final"]
        kinds = {}
        for o in ops[a:b]:
            k = op_kind(fmem[o["at"]])
            kinds[k] = kinds.get(k, 0) + 1
        took = ends_t[b - 1] - ops[a]["t"]
        name = f"draw_bagend_{n:02d}.png"
        big = after.resize((after.width, after.height), Image.NEAREST)
        big.save(image_dir / name)
        what = ", ".join(f"{v} {k}{'s' if v != 1 else ''}" for k, v in kinds.items())
        detail = ""
        if b - a == 1:
            at = ops[a]["at"]
            byte = fmem[at]
            kind = op_kind(byte)
            if kind == "fill":
                detail = (f": {bh.COLOURS[byte & 7]} from {fmem[at + 1]}, {fmem[at + 2]}")
            elif kind == "paint":
                cell = ((fmem[at + 1] << 8) | fmem[at + 2]) - 0x5800
                detail = f": {bh.COLOURS[byte & 7]} from row {cell // 32}, column {cell % 32}"
        caption = (f"Ops {a + 1}-{b} (${ops[a]['at']:04X}): {what}{detail}. "
                   f"{seconds(took):.2f} s.")
        if b - a == 1:
            caption = f"Op {a + 1} (${ops[a]['at']:04X}): {what}{detail}. {seconds(took):.2f} s."
        frames.append(figure(name, big, caption, scale=2))
    clear_time = followed["ops"][0]["t"] - followed["start"]
    bag_timing = op_times(followed, fmem)

    # ---- time by op kind, Bag End and all the pictures
    def kind_rows(timing_times, timing_counts, total):
        rows = []
        for kind in ("clear", "move", "line", "fill", "paint", "end"):
            t = timing_times.get(kind, 0)
            n = timing_counts.get(kind, 1 if kind == "clear" else 0)
            if not t and not n:
                continue
            per = f"{t // n:,}" if n else "-"
            rows.append([kind, str(n if kind != "clear" else "-"), f"{t:,}",
                         f"{seconds(t):.2f} s", f"{100 * t / total:.1f}%", per])
        return rows
    bag_rows = kind_rows(bag_timing["times"], bag_timing["counts"], followed["total"])
    all_rows = kind_rows(kinds_total, counts_total, total_time)

    # ---- where the time goes, by routine, in Bag End
    profile = routine_profile(clean, FOLLOWED_PICTURE, link)
    prof_rows = []
    for routine, t in sorted(profile["spent"].items(), key=lambda kv: -kv[1])[:8]:
        prof_rows.append([link(routine), f"{t:,}", f"{100 * t / profile['total']:.1f}%"])

    # ---- the fast-draw patch, if it has been built
    fast_text = ""
    fast_sna = bh.OUT_DIR / "hobbit_fast.sna"
    if fast_sna.exists():
        patch = bytes(bh.machine_memory(fast_sna))
        fast = draw_picture(clean, FOLLOWED_PICTURE, patch=patch)
        same = fast["final"].tobytes() == followed["final"].tobytes()
        fast_timing = op_times(fast, fast["memory"])
        fast_rows = []
        for kind in ("clear", "move", "line", "fill", "paint"):
            a = bag_timing["times"].get(kind, 0)
            b = fast_timing["times"].get(kind, 0)
            if a or b:
                fast_rows.append([kind, f"{seconds(a):.2f} s", f"{seconds(b):.2f} s",
                                  f"{a / b:.1f}x" if b else "-"])
        fast_rows.append(["the whole picture", f"{seconds(followed['total']):.2f} s",
                          f"{seconds(fast['total']):.2f} s",
                          f"{followed['total'] / fast['total']:.1f}x"])
        fast_text = "\n".join([
            "<p>The same measurement with the patch from <a href=\"patches.html\">Patches</a> "
            "laid over the same machine (its ranges copied from the patched snapshot the "
            "build makes): the ops are the same ones, at the same places in the stream, and "
            f"the finished canvas is {'identical' if same else 'NOT identical'} to the "
            "original's. Only the lines and fills get faster: the moves, the paints and "
            "clearing the canvas are untouched code.</p>",
            table(["Op", "Original", "Patched", "Faster by"], fast_rows)])
        if not same:
            log("  drawing: the patched Bag End differs from the original")
    else:
        fast_text = ("<p>(The patched snapshot was not built with this page, so the patched "
                     "timings are not shown here; see <a href=\"patches.html\">Patches</a>.)</p>")

    # ---- the trolls' clearing, by night and by day
    trolls_start = next(s for loc, s, _ in records if loc == TROLLS_CLEARING)
    night_bytes = (memory[trolls_start], memory[trolls_start + 1])
    night = draw_picture(clean, TROLLS_CLEARING)["final"]
    day = draw_picture(clean, TROLLS_CLEARING, stream_bytes=DAY_BYTES)["final"]
    night.save(image_dir / "draw_trolls_night.png")
    day.save(image_dir / "draw_trolls_day.png")
    partner = None
    visited5 = set(bh.picture_boundaries(memory, trolls_start))
    for loc, s, _ in records:
        if loc != TROLLS_CLEARING and trolls_start < s and s + 2 in visited5:
            partner = loc

    def colour_text(border: int, attribute: int) -> str:
        return (f"${border:02X} ${attribute:02X}: {bh.COLOURS[border & 7]} border, "
                f"{bh.COLOURS[(attribute >> 3) & 7]} paper, {bh.COLOURS[attribute & 7]} ink")

    fmt_rows = [
        ["header", "2", "the border colour, and the attribute the canvas starts as "
                        f"({L(CLEAR_CANVAS)})"],
        ["$00", "1", "the end"],
        ["$08 x y", "3", "move the pen"],
        ["bit 7 set", "2", f"a line ({L(DRAW_LINE)}): bits 0-2 its direction (bit 0 the "
                           "vertical axis leads, bit 1 down, bit 2 left), the second byte's "
                           "bits 0-5 its length less one, and the minor-axis step -- one "
                           "step every n pixels -- split between the first byte's bits 2-5 "
                           "and the second's bits 6-7"],
        ["bit 6 set", "3", f"a flood fill ({L(FLOOD_FILL)}) in the ink of bits 0-2, from "
                           "x, y; the pen does not move"],
        ["bit 5 set", "3+", "paint attribute cells: bits 0-2 the colour, then an attribute "
                            "address, high byte first, then path bytes of two bits of "
                            "direction and six of count, to $FF"],
    ]

    bag = data.room_name.get(FOLLOWED_PICTURE, "")
    parts = [
        "<p>A picture is not stored as pixels. It is a program of a few hundred ops -- move "
        f"the pen, draw a line, flood-fill, paint colours -- for {L(RUN_PICTURE)}, which "
        "draws it into the top 128 scanlines of the screen while the game does nothing "
        f"else. This page follows the first picture a game shows, {esc(bag)} (Bag End), "
        "op by op through the game's own interpreter, times every op in every picture, and "
        "draws the one picture the game changes as it runs, both ways.</p>",

        "<h3>The stream</h3>",
        f"<p>{L(DRAW_LOCATION_PICTURE)} looks the location up in {L(PICTURE_TABLE)} and "
        f"hands the stream to {L(RUN_PICTURE)}, which walks it with IY and tests each op "
        "in this order (<i>read</i>):</p>",
        table(["Op", "Bytes", "Does"], fmt_rows),
        "<p>x runs 0-255 across and y 0-127 up from the bottom of the canvas; a stream that "
        "draws before it moves starts at (127, 63). Every pixel plotted also sets its "
        f"cell's ink ({L(PLOT_PIXEL)}), flipped if it would be the paper's colour, so a line "
        "is never invisible. The 22 pictures, with the ops each stream holds and how long "
        "the game took to draw it here:</p>",
        table(["Location", "Name", "Stream", "Bytes", "Lines", "Moves", "Fills", "Paints",
               "Drawing"], table_rows),
        f"<p>{seconds(total_time):.1f} s of drawing in all. {words(len(pairs)).capitalize()} "
        "streams do not end: the last private op of "
        + " and of ".join(f"location {o}'s" for o, _ in pairs)
        + " takes the next picture's two header bytes as its operands and runs on into it "
        "(" + "; ".join(f"{o} into {i}" for o, i in pairs) + "), so each of those is another "
        "picture with a few more ops first.</p>",

        f"<h3>Bag End, op by op</h3>",
        f"<p>{L(DRAW_LOCATION_PICTURE)} run for location {FOLLOWED_PICTURE} on a game at its "
        "first prompt, with a probe at $7FBC, the top of RUN_PICTURE's loop, taking the "
        "canvas each time an op begins -- so each picture below is the canvas after the ops "
        f"named, with the time they took. Clearing the canvas came first: "
        f"{seconds(clear_time):.2f} s. Then {first_other} moves and lines, shown in "
        f"{len(groups) - (len(ops) - 1 - first_other)} pictures, and each fill and paint "
        "on its own:</p>",
        '<div style="display: flex; flex-wrap: wrap">' + "".join(frames) + "</div>",
        "<p>The outline is almost free; the fills are the picture's time. The Locations "
        "page has every picture animated at the speed the game draws it.</p>",

        "<h3>Where the time goes</h3>",
        "<p>The same run, the T-states from each op's start to the next's, by kind:</p>",
        table(["Op", "How many", "T-states", "Time", "Share", "Each"], bag_rows),
        f"<p>And the same over all {len(records)} pictures:</p>",
        table(["Op", "How many", "T-states", "Time", "Share", "Each"], all_rows),
        "<p>Inside the ops, the time is in addressing. Every instruction of Bag End's "
        "drawing, its T-states put down to the routine it is in (probed at every "
        "instruction):</p>",
        table(["Routine", "T-states", "Share"], prof_rows),
        f"<p>{L(DRAW_LINE)} and {L(FLOOD_FILL)} step their point a pixel at a time, so "
        f"they always know where the next pixel is -- and then {L(PIXEL_ADDRESS)} works its "
        "screen address out again from x and y, rotating the mask into place one bit at a "
        f"time. The fill does it for every pixel it tests ({L(PIXEL_SET)}), above, below "
        "and beside the sweep, as well as for every pixel it plots, and keeps its queue of "
        "seeds on the machine stack.</p>",

        "<h3>The fast-draw patch</h3>",
        "<p>The patch on <a href=\"patches.html\">Patches</a> keeps every algorithm and "
        "every seed and carries the address and mask along with the point instead, working "
        "them out from scratch only where a line or a sweep begins; then it takes the "
        "fill's own bookkeeping down too. Nine times faster over the 22 pictures, and the "
        "same pixels.</p>",
        fast_text,

        "<h3>The trolls' clearing, by night and by day</h3>",
        f"<p>The one picture the game changes. On the tape the first two bytes of location "
        f"{TROLLS_CLEARING}'s stream are {colour_text(*night_bytes)}: night. When day dawns "
        f"and the trolls turn to stone, {L(TROLLS_TURN_TO_STONE)} writes "
        f"{colour_text(*DAY_BYTES)}, and {link.within(NEW_GAME)} writes the night back before every "
        "game. The drawing is the same; drawn both ways here by DRAW_LOCATION_PICTURE, the "
        "second with the two bytes the dawn writes:</p>",
        figure("draw_trolls_night.png", night, "By night, as the tape has it: the lines "
               "come out white, because black ink on black paper is flipped by PLOT_PIXEL.",
               scale=2),
        figure("draw_trolls_day.png", day, "By day, after the dawn: the same ops on cyan.",
               scale=2),
        f"<p>Location {TROLLS_CLEARING}'s stream runs on into location "
        f"{partner}'s -- {esc(data.room_name.get(partner, '?'))} -- so the clearing is that "
        "picture with the trolls' ops first, and its colour bytes are the only ones in the "
        "game with a writer.</p>",

        "<h3>What is confirmed, and what is not</h3>",
        "<ul>",
        "<li><b>Run</b> when this page was built: every picture drawn and timed, Bag End "
        "op by op with its canvas, the profile by routine, the patched timings when the "
        "patched snapshot exists, and both clearings.</li>",
        "<li><b>Read</b>: the op grammar (the build decodes every stream by RUN_PICTURE's "
        "own tests and checks the two shared ones) and what the dawn and NEW_GAME write.</li>",
        "<li>Times are T-states at 3.5 MHz with no memory contention, as SkoolKit's "
        "simulator counts them; interrupts are off while a picture is drawn, so nothing "
        "else takes a share.</li>",
        "</ul>",
    ]
    return "\n".join(parts)
