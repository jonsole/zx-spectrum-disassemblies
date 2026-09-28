"""Nightshade's sounds, recorded from the game's own code at build time.

build_nightshade.py --html calls build(), which writes a WAV of every tune
and sound effect into the HTML directory's audio/ folder and returns the
Sounds section. Nothing here is committed output: the sounds are the game's.

A 48K Spectrum has one bit of sound hardware, bit 4 of port $FE, and every
noise Nightshade makes is its code setting and clearing that bit with the
processor counting in between. So a sound is recorded by running the code
that makes it in SkoolKit's simulator with a tracer that notes the T-state of
every OUT to port $FE that changes bit 4; the gaps between those edges are
the waveform, which SkoolKit's audio writer renders to a WAV at 44100 Hz.
Nothing is synthesised: every edge in every file is an OUT the game executed.

Two kinds of recording:

- A call. The routine that makes the sound, called on a machine of its own
  built from the snapshot with the ROM in place, the registers and variables
  it reads set to the values given, and a return address the run stops at.
  A fresh machine for each call, so that nothing is inherited from the last.
  The tunes are recorded this way, and what the villains' tables would have
  played had the code that reads them worked.
- A run of turns. The game itself, started from the menu the way the
  build's sessions start it (build_nightshade.Machine and _start), and run a
  turn at a time from MAIN_LOOP to MAIN_LOOP, the edges kept with the real
  turns between them. Everything heard in play is recorded this way. What a
  run needs that play would take long to bring about is staged by poking at
  the start of a turn -- a bonus or an object laid where the knight stands,
  as the build's own sessions lay them; a villain held in his cell; the
  256th turn brought forward for the creature -- and each item says what was
  staged.

Every run is checked against a model of the turn worked out from the code
(turn_waves): for each record, in the order the main loop updates them, the
waves its update routine makes given the state the turn began with -- a
footstep, a bump, a throw, a knight appearing, a monster appearing, the
creature's blip, a villain's hum, a puff -- then the sound effect's note;
and every wave's measured half-wave count B against that list. The on
half-wave CLICK makes is 13B + 18 T-states whatever the caller, and the off
half-wave 13B plus a constant for each loop that calls it (the constants
below, from the instruction timings). The tunes are checked against the note
table and PLAY_NOTE's timing, as Alien 8's and Pentagram's are. The machine
is uncontended, so everything is a little faster, and higher, than on a real
Spectrum, where the ULA holds up the OUTs; the loops run above $8000, in
uncontended memory, so the difference is small.

The other games' snapshots (Pentagram's, Alien 8's, Knight Lore's, written
by their own builds) are read, if they are there, to compare the shared
routines byte for byte.
"""
from __future__ import annotations

import html
import re
from pathlib import Path

import build_nightshade as bn

TSTATES_PER_SECOND = 3_500_000
CALL_STACK = 0x5D00         # in the game's own stack space, below $5E00
STOP = 0x5B00               # the return address: the run stops there (the printer buffer)
CALL_LIMIT = 90 * TSTATES_PER_SECOND
TURN_LIMIT = 20 * TSTATES_PER_SECOND    # a turn with a tune in it is long
SKOOL = bn.OUT_DIR / "nightshade.skool"

# The sound code (see the entries).
BLIP_BY_TURN = 0xC332
BLIP_FROM_TABLE = 0xC335    # BLIP_BY_TURN's second entry: BC the table
BLIP_PITCHES = 0xC34D       # the creature's sixteen
VILLAIN_PITCHES = 0xC35D    # the villains' four sixteens, never read
ENDING_BEEP = 0xC39D
BUMP_SOUND = 0xC3AA
EFFECT_NOTE = 0xC3BD
EFFECT_TABLE = 0xC3D8
FIRE_SOUND = 0xC3F4
FOOTSTEP = 0xC400
PUFF_SOUND = 0xC435
APPEAR_SOUND = 0xC455
ARRIVE_SOUND = 0xC463
BEEP = 0xC46A
CLICK = 0xC471
PLAY_TUNE_ONCE = 0xC63D
PLAY_TUNE = 0xC656
PLAY_NOTE = 0xC661
NOTES = 0xC6B9
NOTE_ROWS = 61
TUNE_MENU, TUNE_CONTROL, TUNE_START = 0xC770, 0xC7F4, 0xC7F8
TUNE_OVER, TUNE_ENDING, TUNE_NEW_LIFE = 0xC803, 0xC81A, 0xC839
VILLAIN_UPDATE = 0xD94F

# The variables and records (see the annotations).
RANDOM = 0xBBAA
TURNS = 0xBBB2
TUNE_PLAYED = 0xBBC1
THROW_WAIT = 0xBBC8
LIVES = bn.LIVES
HITS = bn.HITS
SPEED_TIME = 0xBBF5
LAST_CELL = 0xBBF6
FOOTSTEPS = 0xBBF8
EFFECT_TIME = 0xBBF9
EFFECT = 0xBBFA
ENDING = bn.ENDING
ARRIVING = bn.ARRIVING
CARRIED = bn.CARRIED
KNIGHT, KNIGHT_TOP = bn.KNIGHT, bn.KNIGHT_TOP
ANTIBODIES, FINDS, BONUS = bn.ANTIBODIES, bn.FINDS, bn.BONUS
OBJECTS, VILLAINS, MONSTERS = bn.OBJECTS, bn.VILLAINS, bn.MONSTERS
RECORDS_END = bn.RECORDS_END
RECORD_SIZE = 16
MONSTER_TEMPLATE = 0xCE79   # the record #R$CDE8 copies into a new monster's
STATE_START, STATE_END = 0xBB00, RECORDS_END   # what a Frame keeps
HERE = 0x70                 # ARRIVING once he is here
AFTER_RECORDS = 0xBE91      # the main loop, past the last record's update
BEFORE_MONSTERS = 0xBE9E    # the main loop's call of #R$CDE8
MENU_LOOP = bn.MENU_LOOP
MAIN_LOOP = bn.MAIN_LOOP

# The other games' snapshots, to compare with (their builds write them).
GAMES = bn.PROJECT_ROOT / "game_disassembly"
PENTAGRAM = GAMES / "pentagram" / "pentagram.z80"
ALIEN_8 = GAMES / "alien8" / "alien8.z80"
KNIGHT_LORE = GAMES / "knightlore" / "knightlore.sna"

# Half-waves, in T-states, from the instructions of the loops that make them.
# CLICK ($C471) turns the speaker on (OUT) and waits B turns of DJNZ (13
# T-states each, 8 for the last), then LD B,A, XOR A and the OUT that turns it
# off: every on half-wave any effect makes is 13B + 18 (B = 0 counts 256). Its
# off half-wave is its second DJNZ with the same B, then LD B,A and RET, then
# whatever the caller does before it calls CLICK again, and CLICK's LD A,$10
# and OUT: 13B plus a constant for each loop --
CLICK_ON = 18
# BEEP's DEC C, JR NZ and CALL: C waves at one pitch.
BEEP_OFF = 64
# BUMP_SOUND's DEC C, JR NZ, LD A,C, XOR, ADD, LD B,A and CALL.
BUMP_OFF = 83
# FIRE_SOUND's DEC C, JR NZ, LD A,C, SUB B, LD B,A and CALL.
FIRE_OFF = 76
# PUFF_SOUND calls BEEP for one wave at a time: BEEP's DEC C and JR NZ falling
# through, its RET, then PUFF's DEC E, JR NZ, LD A,(HL), INC HL, AND, LD B,A,
# LD C,1, CALL BEEP and BEEP's CALL CLICK.
PUFF_OFF = 133
LOOP_CONSTANTS = {BEEP_OFF: "BEEP's", BUMP_OFF: "#R$C3AA's", FIRE_OFF: "#R$C3F4's",
                  PUFF_OFF: "#R$C435's"}
# An off half-wave longer than 13B plus this is a silence between two sounds,
# not part of one.
IN_A_SOUND = 200
# PLAY_NOTE ($C661), Knight Lore's, Alien 8's and Pentagram's routine but for
# two addresses, times each half with a DJNZ loop run C times over (the first
# pass B turns, the rest 256), which with its DEC C and JR NZ comes to
# D = 13B + 3339C - 3333; then off is D + 39 (POP, PUSH, LD, OUT) and on is
# D + 62 (POP, DEC HL, LD, OR, JR, PUSH, XOR, OUT).
NOTE_OFF, NOTE_ON = 39, 62

NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


def _esc(text: str) -> str:
    return html.escape(text, quote=False)


def _hz(tstates: float) -> float:
    return TSTATES_PER_SECOND / tstates


def _count(value: int) -> int:
    """A DJNZ or DEC counter's value as a number of turns: 0 is 256."""
    return value or 256


def _rrc(value: int, bits: int) -> int:
    value &= 0xFF
    return ((value >> bits) | (value << (8 - bits))) & 0xFF


def _rlc(value: int, bits: int) -> int:
    value &= 0xFF
    return ((value << bits) | (value >> (8 - bits))) & 0xFF


def note_name(row: int) -> str:
    """The note table's scale, as Pentagram's and Alien 8's pages work it
    out: row 1 is G#1 and row 38 A4."""
    midi = row + 31
    return f"{NAMES[midi % 12]}{midi // 12 - 1}"


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
# Recording.
# --------------------------------------------------------------------------

def _tracer_class():
    from skoolkit.kbtracer import KEY_BITS
    from skoolkit.simutils import T
    from skoolkit.trace import Tracer

    class SoundTracer(Tracer):
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

    return SoundTracer


def _base(snapshot: Path) -> list:
    from skoolkit import read_bin_file

    memory = list(bn.game_memory(snapshot))
    memory[:0x4000] = read_bin_file(str(bn.ROM))
    return memory


def call(base, address: int, registers=None, pokes=None):
    """Call the routine at `address` on a fresh machine: its speaker edges,
    in T-states from the call, and how long it ran until it returned."""
    from skoolkit import CSimulator
    from skoolkit.simulator import Simulator
    from skoolkit.simutils import PC, SP, T
    import skoolkit.simutils as su

    memory = list(base)
    for where, value in (pokes or {}).items():
        memory[where] = value
    memory[CALL_STACK:CALL_STACK + 2] = [STOP & 0xFF, STOP >> 8]
    simulator = (CSimulator or Simulator)(memory, state={"iff": 0, "im": 1, "tstates": 0})
    tracer = _tracer_class()(simulator)
    simulator.set_tracer(tracer)
    for name, value in (registers or {}).items():
        if name in ("IX", "DE", "HL", "BC"):
            high, low = {"IX": ("IXh", "IXl")}.get(name, (name[0], name[1]))
            simulator.registers[getattr(su, high)] = value >> 8
            simulator.registers[getattr(su, low)] = value & 0xFF
        else:
            simulator.registers[getattr(su, name)] = value
    simulator.registers[SP] = CALL_STACK
    simulator.trace(address, STOP, 0, CALL_LIMIT, False, None, None, None, None, None)
    if simulator.registers[PC] != STOP:
        raise RuntimeError(f"the call to ${address:04X} did not return")
    return list(tracer.edges), simulator.registers[T]


def in_a_row(calls, gap: int):
    """Several calls' recordings end to end, `gap` T-states of silence
    after each."""
    edges, now = [], 0
    for call_edges, length in calls:
        edges += [now + t for t in call_edges]
        now += length + gap
    return edges, now - gap


def from_turns(frames: list) -> tuple[list[int], int]:
    """The edges of a run of turns, from the start of the first."""
    t0 = frames[0].start
    edges = [frame.start - t0 + t for frame in frames for t in frame.edges]
    return edges, frames[-1].end - t0


def halves(edges: list[int]) -> tuple[list[int], list[int]]:
    """The on and off half-waves: the speaker starts off, so edges go on,
    off, on... An off half-wave is measured to the next on edge."""
    on = [edges[i + 1] - edges[i] for i in range(0, len(edges) - 1, 2)]
    off = [edges[i + 1] - edges[i] for i in range(1, len(edges) - 1, 2)]
    return on, off


def clicks(edges: list[int]) -> list[int]:
    """The B of every wave CLICK made, from its on half-wave (the negative
    of the half-wave, where it is not 13B + 18 for any B: a tune's)."""
    on, _ = halves(edges)
    return [(t - CLICK_ON) // 13 if (t - CLICK_ON) % 13 == 0 and 0 < t - CLICK_ON <= 13 * 256
            else -t for t in on]


def _write_wav(path: Path, edges: list[int], length: int) -> None:
    """Render the speaker edges to a WAV. SkoolKit's writer takes the gaps
    between flips, starting from the speaker off; a recording that ends with
    the speaker on (every tune does: #R$C661 ends each wave on) is turned off
    where it ends."""
    from skoolkit.audio import BeeperOptions
    from skoolkit.components import get_audio_writer

    edges = list(edges)
    if len(edges) % 2:
        edges.append(max(length, edges[-1] + 1))
    delays = [edges[0]] + [b - a for a, b in zip(edges, edges[1:])]
    if length > edges[-1]:
        delays.append(length - edges[-1])
    delays = [max(d, 1) for d in delays]
    with open(path, "wb") as f:
        get_audio_writer().write_audio(f, delays, BeeperOptions(100, False, False, 0, False))


# --------------------------------------------------------------------------
# The game, running.
# --------------------------------------------------------------------------

class Frame:
    """What one turn left: the variables and records, how long it took, and
    the speaker edges made in it (in T-states from its start)."""

    def __init__(self, memory, start: int, end: int, edges: list[int], keys=()):
        self.state = bytes(memory[STATE_START:STATE_END])
        self.start, self.end = start, end
        self.tstates = end - start
        self.edges = edges
        self.keys = frozenset(keys)
        self.speaker = 0
        self.begin = None       # the state the turn began with, if staging changed it

    def m(self, address: int) -> int:
        return self.state[address - STATE_START]

    def record(self, address: int) -> bytes:
        return self.state[address - STATE_START:address - STATE_START + RECORD_SIZE]


class Game:
    """Nightshade on a simulated 48K Spectrum: build_nightshade's Machine,
    with a tracer that also logs the speaker, run a turn at a time."""

    def __init__(self, snapshot: Path):
        self.machine = bn.Machine(snapshot)
        self.sim = self.machine.simulator
        self.tracer = _tracer_class()(self.sim)
        self.machine.tracer = self.tracer
        self.sim.set_tracer(self.tracer)
        self.memory = self.sim.memory
        # Called with the memory at the start of every turn: the staging a
        # run keeps up (the monsters cleared away, a villain held in place).
        self.each_turn = []

    @property
    def now(self) -> int:
        from skoolkit.simutils import T
        return self.sim.registers[T]

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

    def start(self, choice: str = "1") -> None:
        """From the snapshot through the menu into the town, as the build's
        sessions start a game (keyboard by default), and on to a turn's
        start."""
        self.machine.play(bn._start(choice), "sounds")
        self.hold()
        self.run_to(MAIN_LOOP)

    def turn(self, at=None, stop: int = MAIN_LOOP) -> Frame:
        """One turn, from MAIN_LOOP to MAIN_LOOP (or to `stop`, for the turn
        that leaves the main loop). With `at` = (address, poke), the turn is
        stopped at the address on the way and poke(memory) applied there."""
        if self.machine.pc != MAIN_LOOP:
            self.run_to(MAIN_LOOP)
        for poke in self.each_turn:
            poke(self.memory)
        # The state the turn begins with, after the staging: what the model
        # of the turn starts from.
        begin = Frame(self.memory, self.now, self.now, [])
        start = self.now
        first = len(self.tracer.edges)
        speaker = self.tracer.speaker
        if at is not None:
            self.run_to(at[0])
            at[1](self.memory)
        self.run_to(stop)
        edges = [t - start for t in self.tracer.edges[first:]]
        frame = Frame(self.memory, start, self.now, edges, self.tracer.keys)
        frame.speaker = speaker
        frame.begin = begin
        return frame

    def turns(self, count: int) -> list[Frame]:
        return [self.turn() for _ in range(count)]

    def frame(self) -> Frame:
        """The state as it is, as a turn of no length: the start of a run."""
        return Frame(self.memory, self.now, self.now, [], self.tracer.keys)


def _clear_monsters(keep=()):
    """Empty the monster records (but those in `keep`) at every turn's start:
    they appear every fourth turn and would add their sounds to a run about
    something else."""
    def poke(memory):
        for index in range(6):
            record = MONSTERS + RECORD_SIZE * index
            if record not in keep:
                memory[record:record + RECORD_SIZE] = bytes(RECORD_SIZE)
    return poke


def _hush_villains(keep=()):
    """Clear the villains' drawn flags at every turn's start (but those in
    `keep`), so that one wandering onto the screen does not hum over a run
    about something else. They are drawn as usual."""
    def poke(memory):
        for index in range(4):
            record = VILLAINS + RECORD_SIZE * index
            if record not in keep:
                memory[record + 7] &= 0xFD
    return poke


# --------------------------------------------------------------------------
# What the code says a turn should sound like.
# --------------------------------------------------------------------------

# A placeholder for a puff's sixteen waves, whose pitches come from the ROM
# at an address made of the random number as it is at that moment: checked
# against the ROM rather than predicted.
PUFF = "puff"
PUFF_WAVES = 16

WALKING = set(range(16, 22)) | set(range(24, 30))      # the legs' #R$DA7A graphics
VANISHING = range(12, 16)
VILLAIN_GRAPHICS = range(96, 112)
APPEARING = range(128, 132)
CREATURE = range(136, 140)
ENDING_VILLAINS = range(144, 152)
ARMS_OUT = (22, 30)         # the top meeting a wall (#R$D9EB); 38, 39, 46 and 47 are poses


def records():
    """The 23 object records, in the order the main loop updates them."""
    return [KNIGHT + RECORD_SIZE * n for n in range(23)]


def appear_pitch(graphic: int) -> int:
    """#R$C455: the complement of the graphic turned right three bits, the
    top three kept."""
    return _rrc(~graphic, 3) & 0xE0


def villain_offset(graphic: int) -> int:
    """#R$D94F's BC: the graphic turned left two bits, AND $F0."""
    return _rlc(graphic, 2) & 0xF0


def fire_waves(first: int) -> list[int]:
    """#R$C3F4: for C = 32 down to 1, one wave at C less the last count."""
    out, b = [], first
    for c in range(32, 0, -1):
        b = (c - b) & 0xFF
        out.append(b)
    return out


BUMP = [((c ^ 0xA5) + c) & 0xFF for c in range(16, 0, -1)]      # #R$C3AA


def footstep_waves(count: int, speed: int) -> list[int]:
    """#R$C400, with FOOTSTEPS counted on to `count`: walking, every fourth
    step four waves at 64 or 96 by bit 2; at a speed of 12 or more, every
    second, by bit 1."""
    if speed < 12:
        if count & 3:
            return []
        return [0x40 if count & 4 else 0x60] * 4
    if count & 1:
        return []
    return [0x40 if count & 2 else 0x60] * 4


def effect_address(base, effect: int) -> int:
    return base[EFFECT_TABLE + 2 * effect] + 256 * base[EFFECT_TABLE + 2 * effect + 1]


def effect_pitches(base, effect: int, count: int) -> list[int]:
    """The notes #R$C3BD plays for an effect of `count` notes, in the order
    they are played: the byte `count` after the effect's address first."""
    address = effect_address(base, effect)
    return [base[address + n] for n in range(count, 0, -1)]


def turn_waves(base, before: Frame, now: Frame) -> list:
    """The waves the code makes in a turn that began as `before` left things
    and ended as `now`: every record's update in turn, then the effect's
    note -- a list of half-wave counts, with PUFF standing for a puff's
    sixteen waves from the ROM. Only what the turns recorded here involve:
    the monsters that walk about (and bump) are kept out of the runs."""
    waves = []
    turns = before.m(TURNS)
    ending = before.m(ENDING)
    effect_time = before.m(EFFECT_TIME)
    for address in records():
        record, after = before.record(address), now.record(address)
        graphic, drawn = record[0], record[7] & 2
        if address == KNIGHT and graphic in WALKING:
            arriving = before.m(ARRIVING)
            if arriving != HERE:
                level = (arriving + 2) & 0xFF
                if level < 0x4C:
                    waves += [~level & 0xFF] * 8               # #R$C463
                continue
            if now.m(FOOTSTEPS) != before.m(FOOTSTEPS):
                waves += footstep_waves(now.m(FOOTSTEPS), after[5])
            if before.m(THROW_WAIT) == 0 and now.m(THROW_WAIT) == 2:
                gone = [n for n in range(11) if before.m(CARRIED + n) and not now.m(CARRIED + n)]
                waves += fire_waves(11 - gone[0])
        elif address == KNIGHT_TOP and 32 <= graphic < 48:
            if after[0] in ARMS_OUT and before.record(KNIGHT)[7] & 2:
                waves += BUMP
        elif graphic in VANISHING:
            if graphic & 3 == 3 and drawn:
                waves.append(PUFF)
        elif graphic in APPEARING:
            if drawn:
                waves += [appear_pitch(graphic)] * 6
        elif graphic in CREATURE:
            if drawn:
                waves += [base[BLIP_PITCHES + (turns & 15)]] * 12
        elif graphic in VILLAIN_GRAPHICS:
            if drawn:
                waves += [base[villain_offset(graphic) + (turns & 15)]] * 12
        elif graphic in ENDING_VILLAINS:
            previous = now.record(address - RECORD_SIZE)[0]
            if previous not in ENDING_VILLAINS:
                effect_time = (effect_time + 1) & 0xFF
                waves += [(effect_time + 0x40) & 0xFF] * 12   # #R$C39D
                if after[0] == 0:
                    effect_time = 0
    if not ending and (before.m(EFFECT_TIME) or now.m(EFFECT_TIME)):
        count = now.m(EFFECT_TIME) + 1
        waves += [base[effect_address(base, now.m(EFFECT)) + count]] * 12
    return waves


# --------------------------------------------------------------------------
# The tunes.
# --------------------------------------------------------------------------

def note_rows(memory) -> list[tuple[int, int, int]]:
    """Each row of the note table: the B and C that time a half-wave, and the
    waves in a unit."""
    return [tuple(memory[NOTES + 3 * row:NOTES + 3 * row + 3]) for row in range(NOTE_ROWS)]


def note_d(b: int, c: int) -> int:
    return 13 * _count(b) + 3339 * _count(c) - 3333


def note_hz(b: int, c: int) -> float:
    return _hz(2 * note_d(b, c) + NOTE_OFF + NOTE_ON)


def tune_notes(memory, address: int) -> list[tuple[int, int]]:
    """(row, units) for each note byte up to the $FF."""
    notes = []
    while memory[address] != 0xFF:
        notes.append((memory[address] & 0x3F, (memory[address] >> 6) + 1))
        address += 1
    return notes


def tune_bytes(memory, address: int) -> bytes:
    end = address
    while memory[end] != 0xFF:
        end += 1
    return bytes(memory[address:end + 1])


def check_tune(edges: list[int], notes, rows) -> tuple[bool, str]:
    """Waves and half-waves against the note table and PLAY_NOTE's timing:
    whether they all agree, and the sentence that says so. The edges begin
    with the tune's first rising edge (its first OUT turns off a speaker
    already off, and is no edge)."""
    on, off = halves(edges)
    waves = sum(rows[row][2] * units for row, units in notes)
    expected_off, expected_on = [], []
    for row, units in notes:
        b, c, per_unit = rows[row]
        d = note_d(b, c)
        count = per_unit * units
        expected_off += [d + NOTE_OFF] * count
        # A note's last on half-wave runs on into the next note's set-up.
        expected_on += [d + NOTE_ON] * (count - 1) + [None]
    ok_edges = len(edges) == 2 * waves - 1
    off_ok = off == expected_off[1:len(off) + 1]
    on_ok = all(e is None or m == e for m, e in zip(on, expected_on))
    text = (f"The table's wave counts make {waves:,} waves, so {2 * waves - 1:,} edges (the "
            "first OUT turns off a speaker already off); the recording has "
            f"{len(edges):,}" + (" -- the same" if ok_edges else " -- NOT the same")
            + ". Every off half-wave " + ("was" if off_ok else "was NOT always")
            + " D + 39 T-states and every on half-wave inside a note "
            + ("was" if on_ok else "was NOT always")
            + " D + 62, D being 13B + 3339C - 3333 for the note's B and C, as #R$C661's "
            "loops imply")
    return ok_edges and off_ok and on_ok, text


def _tune_summary(notes, rows) -> str:
    units = sum(u for _, u in notes)
    rests = sum(1 for row, _ in notes if row == 0)
    lowest = min(row for row, _ in notes)
    highest = max(row for row, _ in notes)
    return (f"{len(notes)} notes, {units} units"
            + (f" (with {rests} rests)" if rests else ", no rests")
            + f", from row {lowest} ({note_name(lowest)}, {note_hz(*rows[lowest][:2]):.0f} Hz) "
            f"to row {highest} ({note_name(highest)}, {note_hz(*rows[highest][:2]):.0f} Hz)")


TUNES = [
    ("tune_menu", TUNE_MENU, PLAY_TUNE_ONCE, "The menu",
     "TUNE_MENU, played by #R$C63D from the menu's loop (#R$C8CA) the first time round "
     "after the game is loaded or a game ends (TUNE_PLAYED); any key stops it between two "
     "notes. The longest of the six: 131 notes, a slow climb of broken chords and back "
     "down."),
    ("tune_control", TUNE_CONTROL, PLAY_TUNE, "A control method chosen",
     "TUNE_CONTROL_CHOSEN, three notes played through by #R$C656 from the menu (#R$C8CA) "
     "whenever a pass round its loop leaves CONTROL changed -- a key 1 to 4 choosing a "
     "control method, or 5 turning directional control on or off. Alien 8's menu beeps "
     "there instead."),
    ("tune_start", TUNE_START, PLAY_TUNE, "A game starting",
     "TUNE_GAME_START, played through by #R$BE0F once 0 has been pressed on the menu, "
     "before the play screen is drawn: the game stands still while it plays."),
    ("tune_new_life", TUNE_NEW_LIFE, PLAY_TUNE, "A new life",
     "TUNE_NEW_LIFE, five falling notes, played by #R$CBAC when a life has ended and "
     "there is another to come -- not for the first life of a game, and not when none are "
     "left (below, <a href=\"#life\">a life lost</a>, where it is heard in its place)."),
    ("tune_over", TUNE_OVER, PLAY_TUNE, "Game over",
     "TUNE_GAME_OVER, played by #R$CC56 once the percentage and the score are on the "
     "screen -- after the last life, and after the last villain too: the ending comes "
     "after it (below, <a href=\"#ending\">the ending</a>)."),
    ("tune_ending", TUNE_ENDING, PLAY_TUNE, "The end of the ending",
     "TUNE_ENDING, played by #R$CD10 when the last of the four villains has sunk into the "
     "pit; then the menu."),
]


def _tunes(base, rows) -> list[dict]:
    out = []
    for name, tune, player, title, what in TUNES:
        pokes = {TUNE_PLAYED: 0} if player == PLAY_TUNE_ONCE else None
        edges, length = call(base, player, {"DE": tune}, pokes)
        notes = tune_notes(base, tune)
        how = f"#R${player:04X} called with DE = ${tune:04X}"
        if player == PLAY_TUNE_ONCE:
            how += (", TUNE_PLAYED clear and no key down, so that it plays to the end, as it "
                    "does for a player who waits")
        ok, text = check_tune(edges, notes, rows)
        out.append({"name": name, "entry": tune, "title": title, "what": what,
                    "how": how + ".", "edges": edges, "length": length, "tune": notes,
                    "ok": ok, "check": _tune_summary(notes, rows) + ". " + text})
    return out


# --------------------------------------------------------------------------
# Checking a run against the model.
# --------------------------------------------------------------------------

def _puff_in_rom(base, waves: list[int]) -> bool:
    """Sixteen ROM bytes in a row, less their top bits, from the first 8K
    (#R$C435's address is the random number, its high byte cut to five
    bits; a byte of 0 is a count of 256)."""
    if len(waves) != PUFF_WAVES:
        return False
    rom = [_count(b & 0x7F) for b in base[:0x2000 + PUFF_WAVES]]
    return any(rom[start:start + PUFF_WAVES] == waves for start in range(0x2000))


def _expand(base, expected: list, measured: list[int]) -> tuple[list[int], int, bool]:
    """The expected B of each wave, each PUFF replaced by the measured waves
    in its place once they have been found in the ROM."""
    flat, puffs, ok = [], 0, True
    for item in expected:
        if item == PUFF:
            chunk = measured[len(flat):len(flat) + PUFF_WAVES]
            ok &= _puff_in_rom(base, chunk)
            puffs += 1
            flat += chunk
        else:
            flat.append(_count(item))
    return flat, puffs, ok


def _loop_offs(edges: list[int]) -> tuple[set, int]:
    """The loop constants the off half-waves inside a sound came to, and how
    many came to none of them."""
    _, offs = halves(edges)
    constants, strange = set(), 0
    for off, b in zip(offs, clicks(edges)):
        if b < 0:
            continue
        extra = off - 13 * b
        if extra in LOOP_CONSTANTS:
            constants.add(extra)
        elif extra < IN_A_SOUND:
            strange += 1
    return constants, strange


def check_run(base, frames: list, rows=None, tunes=(), model=None,
              what: str = "waves") -> tuple[bool, str]:
    """Each turn of a run after the first against the model: every CLICK
    wave's B, every off half-wave inside a sound, and any tune's waves
    against the note table. A turn that begins with the speaker on (a tune's
    last wave) has lost its first wave's rising edge: that wave is left out."""
    model = model or turn_waves
    measured, flat = [], []
    constants, strange = set(), 0
    puffs, puffs_ok = 0, True
    tunes = list(tunes)
    tune_texts, tunes_ok, skipped, cleared = [], True, 0, 0
    for before, now in zip(frames, frames[1:]):
        edges = list(now.edges)
        expected = model(base, now.begin or before, now)
        if now.speaker and edges:
            edges = edges[1:]
            if expected:
                expected = expected[1:]
                skipped += 1
        b = clicks(edges)
        tune_at = next((n for n, value in enumerate(b) if value < 0), None)
        if tune_at is not None:
            tune_edges = edges[2 * tune_at:]
            edges = edges[:2 * tune_at]
            b = b[:tune_at]
            if len(tune_edges) % 2 == 0:
                # A tune ends with the speaker on; an even count means the
                # next OUT to the port (a screen cleared, the border set
                # black) turned it off in the same turn.
                tune_edges = tune_edges[:-1]
                cleared += 1
            if not tunes:
                tunes_ok = False
                tune_texts.append("waves that were neither CLICK's nor a tune's")
            else:
                ok, text = check_tune(tune_edges, tune_notes(base, tunes[0]), rows)
                tunes_ok &= ok
                tune_texts.append(f"the tune at ${tunes.pop(0):04X}: "
                                  + text[0].lower() + text[1:])
        turn_flat, turn_puffs, turn_ok = _expand(base, expected, b)
        puffs += turn_puffs
        puffs_ok &= turn_ok
        measured += b
        flat += turn_flat
        found, odd = _loop_offs(edges)
        constants |= found
        strange += odd
    if tunes:
        tunes_ok = False
        tune_texts.append("a tune the model expected was NOT heard")
    matched = measured == flat
    text = (f"{len(measured):,} {what} from CLICK (the code implies {len(flat):,}); every on "
            "half-wave " + ("was" if matched else "was NOT")
            + " 13B + 18 T-states for the B the code gives it")
    if not matched:
        where = next((n for n, (x, y) in enumerate(zip(measured, flat)) if x != y),
                     min(len(measured), len(flat)))
        text += (f" (first difference at wave {where}: measured "
                 f"{measured[where:where + 6]}, expected {flat[where:where + 6]})")
    if skipped:
        text += (" (the first wave after a tune left out: the tune leaves the speaker on, so "
                 "that wave's rising edge is no edge)")
    if puffs:
        text += (("; the puff's pitches " if puffs == 1 else f"; the {puffs} puffs' pitches ")
                 + ("were" if puffs_ok else "were NOT")
                 + " sixteen bytes in a row of the ROM's first 8K, less their top bits, as "
                 "#R$C435 reads them")
    text += ("; every off half-wave inside a sound was 13B plus "
             + (", ".join(f"{k} ({LOOP_CONSTANTS[k]})" for k in sorted(constants))
                if constants else "nothing")
             + (", the loops' own timing" if not strange else
                f", but {strange} were NOT one of the loops' constants"))
    if tune_texts:
        text += "; and " + "; ".join(tune_texts)
        if cleared:
            text += (" (the edge after a tune's last wave, where the next OUT to the port -- "
                     "the screen cleared, the border set black -- turned the speaker off, "
                     "left out)")
    return matched and puffs_ok and not strange and tunes_ok, text


def check_calls(base, edges: list[int], expected: list[int], what: str = "waves"
                ) -> tuple[bool, str]:
    """A recording made of calls against the waves the code gives."""
    measured = clicks(edges)
    flat = [_count(b) for b in expected]
    matched = measured == flat
    constants, strange = _loop_offs(edges)
    text = (f"{len(measured):,} {what} (the code implies {len(flat):,}); every on half-wave "
            + ("was" if matched else "was NOT")
            + " 13B + 18 T-states for the B the code gives it; every off half-wave inside a "
            "sound was 13B plus "
            + (", ".join(f"{k} ({LOOP_CONSTANTS[k]})" for k in sorted(constants))
               if constants else "nothing")
            + (", the loops' own timing" if not strange else
               f", but {strange} were NOT one of the loops' constants"))
    return matched and not strange, text


def _pitch(edges: list[int]) -> str:
    """The range of the CLICK waves' pitches, each wave measured from its on
    edge to the next wave's, inside a sound."""
    on, off = halves(edges)
    tones = []
    for a, b, c in zip(on, off, clicks(edges)):
        if c >= 0 and b < 13 * 256 + IN_A_SOUND:
            tones.append(_hz(a + b))
    if not tones:
        return "single waves"
    low, high = min(tones), max(tones)
    return f"{low:.0f} Hz" if round(low) == round(high) else f"{low:.0f} to {high:.0f} Hz"


def _recording(base, frames: list, rows=None, tunes=(), **fields) -> dict:
    """A recording of the turns after the first of `frames` (which gives the
    state they began in), checked against the model."""
    turns = frames[1:]
    edges, length = from_turns(turns)
    if turns[0].speaker:
        raise RuntimeError(f"{fields.get('name')}: the speaker was on as the recording began")
    ok, text = check_run(base, frames, rows, tunes)
    fields.update({"edges": edges, "length": length, "turns": len(turns), "ok": ok,
                   "check": text, "pitch": _pitch(edges)})
    return fields


# --------------------------------------------------------------------------
# The runs.
# --------------------------------------------------------------------------

def _keep_lives(memory) -> None:
    memory[LIVES] = 5


def _game(snapshot: Path, keep=()) -> Game:
    """A game started and kept to what a run is about: the monsters cleared
    away and the villains hushed at every turn's start (but the records in
    `keep`), and five lives. The knight's hits are left alone."""
    game = Game(snapshot)
    game.start()
    game.each_turn = [_clear_monsters(keep), _hush_villains(keep), _keep_lives]
    return game


def _go(game: Game, u: int, v: int) -> None:
    """Into cell (u, v) by the game's own restart (build_nightshade._go), and
    on to the start of a turn once he stands there."""
    game.machine.play(bn._go(u, v), "sounds")
    game.hold()
    game.run_to(MAIN_LOOP)


def _cell(base, u: int, v: int) -> int:
    from nightshade_data import cell

    return cell(base, u, v)


def _quiet_turn(snapshot: Path) -> int:
    """The median length of a turn standing still, nothing else about."""
    game = _game(snapshot)
    lengths = sorted(f.tstates for f in game.turns(12))
    return lengths[len(lengths) // 2]


def _walk_until(game: Game, test, limit: int, keys=("a",)) -> list[Frame]:
    """Walk (A) from standing until test(frame) or `limit` turns."""
    frames = [game.frame()]
    game.hold(keys)
    for _ in range(limit):
        frames.append(game.turn())
        if test(frames[-1]):
            break
    return frames


def _new_building_cell(snapshot: Path, base):
    """The first open cell (row by row) from whose middle a walk along +U
    enters a cell with a building within 24 turns: a game in it, and the
    walk's turns."""
    for v in range(32):
        for u in range(31):
            if _cell(base, u, v) != 0 or _cell(base, u + 1, v) <= 2:
                continue
            game = _game(snapshot)
            _go(game, u, v)
            frames = _walk_until(game, lambda f: f.m(EFFECT_TIME) != 0, 24)
            if frames[-1].m(EFFECT_TIME) and frames[-1].m(EFFECT) == 0:
                return (u, v), game, frames
    raise RuntimeError("no walk into a new cell with a building")


def _open_walk(base):
    """The first open cell with open cells after it along +U: 24 turns of
    walking from its middle stay on open ground."""
    for v in range(32):
        for u in range(30):
            if all(_cell(base, u + n, v) == 0 for n in range(3)):
                return u, v
    raise RuntimeError("no open ground")


def _effects(snapshot: Path, base, rows) -> list[dict]:
    out = []

    # Effect 0: walking into a new cell with a building.
    (u, v), game, frames = _new_building_cell(snapshot, base)
    frames += game.turns(4)
    game.hold()
    frames += game.turns(2)
    out.append(_recording(
        base, frames, rows, name="effect0", entry=EFFECT_TABLE,
        title="Effect 0: a new cell with a building",
        what="#R$BF48, as the knight's walk takes him into a cell he has not been in "
             "before that has something built on it, sets EFFECT_TIME to four notes of "
             "effect 0; #R$C3BD plays one a turn at the end of the turn, twelve waves each, "
             "from the last of the effect's bytes back. Open ground (type 0) is marked "
             "visited without a sound, and a cell is only new once a game: VISITED is what "
             "the percentage at the end counts. His footsteps are heard under it.",
        how=f"the game running: a life started in open cell ({u}, {v}) by the game's own "
            f"restart, the first open cell with a building next along +U, and walk held "
            f"along +U from its middle until he crossed into ({u + 1}, {v}); recorded from "
            "the first step to two turns after the last note."))

    # Effects 1 and 2: the bonuses, laid where he stands (the build's own
    # session does the same, #R$D76C putting them about the town in play).
    for effect, graphic, name, title, what in (
            (1, bn.BONUS_SPEED, "effect1", "Effect 1: the faster walk",
             "#R$D727, as the knight touches the bonus of graphic 2: 255 turns of a top "
             "speed of 18 and sound effect 1, five notes, one a turn (#R$C3BD). The bonus "
             "becomes a puff (graphic 12, #R$D7D8), whose four frames end with its crackle "
             "(#R$C435) if it was on the screen."),
            (2, bn.BONUS_CURE, "effect2", "Effect 2: the hits given back",
             "#R$D74C, as he touches the bonus of graphic 3 (a flask): all three hits of "
             "the life back, and sound effect 2, seven notes, one a turn; then the bonus's "
             "crackle, as for the other.")):
        game = _game(snapshot)
        if effect == 2:
            game.memory[HITS] = 1
        frames = [game.frame()]
        game.each_turn.append(bn._beside_knight(BONUS, graphic))
        frames.append(game.turn())
        game.each_turn.pop()
        frames += game.turns(8)
        out.append(_recording(
            base, frames, rows, name=name, entry=EFFECT_TABLE, title=title, what=what,
            how=f"the game running, the knight standing in the cell a new game gave him: "
                f"a bonus of graphic {graphic} laid where he stands at the start of a turn "
                "(build_nightshade's _beside_knight, as its sessions lay them)"
                + (", his hits first set to one" if effect == 2 else "")
                + "; nine turns from that one."))

    # Effect 3: an object taken up.
    game = _game(snapshot)
    frames = [game.frame()]
    game.each_turn.append(bn._beside_knight(OBJECTS, bn.OBJECT_GRAPHIC + 3))
    frames.append(game.turn())
    game.each_turn.pop()
    frames += game.turns(5)
    first = effect_address(base, 3) + 4
    out.append(_recording(
        base, frames, rows, name="effect3", entry=EFFECT_TABLE,
        title="Effect 3: an object taken up",
        what="#R$D942, as the knight touches one of the four objects lying in the town: "
             "sound effect 3, four notes, and the object taken up (#R$C489). Effect 3's "
             "address is the table's last and its notes run past the table's end: the first "
             "one played, the fourth byte after the address, is the first byte of "
             f"#R$C3F4's code, ${base[first]:02X} (LD C,$20), a half-wave count of "
             f"{base[first]} where the rest of the table's are 48 to 128 -- a squeak "
             "three times the pitch of anything else in the table, before three ordinary "
             "notes. Pentagram has the same table and the same squeak, but never "
             "starts effect 3 (<a href=\"../pentagram/Sounds.html#effect3\">Pentagram's "
             "sounds</a>).",
        how="the game running, the knight standing where a new game put him: the object "
            f"of graphic {bn.OBJECT_GRAPHIC + 3} (the first object record's) laid where he "
            "stands at the start of a turn, as the build's sessions lay it; six turns from "
            "that one."))
    return out


def _knight(snapshot: Path, base, rows) -> list[dict]:
    out = []

    # Walking: on open ground, from standing.
    u, v = _open_walk(base)
    game = _game(snapshot)
    _go(game, u, v)
    frames = _walk_until(game, lambda f: False, 24)
    game.hold()
    frames += game.turns(2)
    out.append(_recording(
        base, frames, rows, name="footsteps", entry=FOOTSTEP, title="Walking",
        what="#R$C400, called by #R$DCA8 for every step of the walk: FOOTSTEPS counts them, "
             "and at a walking speed (under 12) every fourth step plays four waves, at a "
             "half-wave count of 64 and 96 by turns (bit 2 of the count): a tick and a tock, "
             "a step a turn, so one every four turns. From standing his speed goes 4, 6, "
             "8 over three turns and stays at 8. Pentagram's footstep, with "
             "four waves where Pentagram's plays two.",
        how=f"the game running: a life started in open cell ({u}, {v}), with open ground "
            "for two cells along +U; walk held for 24 turns, and two turns after."))

    # The faster walk: the speed bonus taken, then walking.
    game = _game(snapshot)
    _go(game, u, v)
    game.each_turn.append(bn._beside_knight(BONUS, bn.BONUS_SPEED))
    game.turn()
    game.each_turn.pop()
    game.turns(8)
    frames = _walk_until(game, lambda f: False, 24)
    game.hold()
    frames += game.turns(2)
    out.append(_recording(
        base, frames, rows, name="footsteps_fast", entry=FOOTSTEP,
        title="Walking faster, with the bonus",
        what="#R$C400 at a speed of 12 or more, which only the speed bonus gives (#R$D727, "
             "a top speed of 18 for 255 turns): a footstep every second step, pitched by bit "
             "1 of the count, so the ticks come twice as often and he covers ground faster "
             "between them. Pentagram's footstep has no faster half.",
        how=f"the game running in open cell ({u}, {v}): the speed bonus laid where he "
            "stood and taken, nine turns for its sound and its puff to finish, then walk "
            "held for 24 turns, and two after."))

    # A bump: walking into a wall, from where a new game put him.
    game = _game(snapshot)
    frames = _walk_until(game, lambda f: f.m(KNIGHT_TOP) in ARMS_OUT, 40)
    if frames[-1].m(KNIGHT_TOP) not in ARMS_OUT:
        raise RuntimeError("the knight never met a wall")
    frames += game.turns(4)
    game.hold()
    frames += game.turns(2)
    frames = frames[-13:]
    out.append(_recording(
        base, frames, rows, name="bump", entry=BUMP_SOUND,
        title="Walking into a wall",
        what="#R$D9EB, the knight's top, when the legs' move met a wall this turn: his arms "
             "thrown out (graphic 22 or 30) and #R$C3AA, sixteen single waves at a "
             "half-wave count of (C XOR $A5) + C for C = 16 down to 1, so the pitch jumps "
             "about -- Pentagram's jump sound, with a test in front that keeps it quiet for "
             "anything not on the screen. Once his arms are out it does not sound again "
             "while he walks on into the wall; his feet go on ticking. The monsters of "
             "graphics 112-127 make the same sound at a wall (#R$C083).",
        how="the game running from where a new game put him: walk held along +U until he "
            "met a wall, four turns on into it, and two after; the last dozen turns "
            "kept."))

    # A throw, and the antibody's puff at the wall.
    game = _game(snapshot)
    game.memory[CARRIED] = 5
    game.memory[CARRIED + 1] = 6
    frames = [game.frame()]
    for keys in (["q"], [], [], [], ["q"]):
        game.hold(keys)
        frames.append(game.turn())
    game.hold()
    for _ in range(40):
        frames.append(game.turn())
        if not any(frames[-1].m(a) for a in (ANTIBODIES, ANTIBODIES + RECORD_SIZE)):
            break
    frames += game.turns(1)
    out.append(_recording(
        base, frames, rows, name="throw", entry=FIRE_SOUND,
        title="Two throws, and their puffs",
        what="#R$C3F4, from #R$DAB7 as an antibody (or an object) leaves his hand: 32 "
             "single waves, each half-wave count the step count less the one before. The "
             "count it starts from is the B #R$DAB7 set to redraw the emptied place on the "
             "panel, 11 less the place's index (the first place, at the bottom, is 0), which "
             "the drawing leaves in B. From the second place (B = 10) the counts go "
             + ", ".join(str(b) for b in fire_waves(10)[:6]) + " ... "
             + ", ".join(str(b) for b in fire_waves(10)[-4:])
             + ": two sequences interleaved, each a step shorter every other wave, so two "
             "rising notes at once, the second running down through 1 to 0 -- 256, the "
             "lowest count there is -- and on from 255, so that half-way through it drops to "
             "the bottom and climbs again. Each place throws with a slightly different "
             "sound. Each antibody flies on until it meets a wall, becomes a puff "
             "(#R$D7D8), and as the puff ends crackles (#R$C435): sixteen single waves at "
             "pitches read from the ROM, from an address made of the random number, so no "
             "two puffs sound alike. Pentagram's bolt and its puff, sixteen waves long here "
             "where Pentagram's is four.",
        how="the game running where a new game put him, facing the wall along +U: "
            "antibodies (things 5 and 6) put in the first two carried places, fire (Q) "
            "pressed for a turn, three turns off, pressed for another -- the second place "
            "throws first, then the first -- and on until both puffs had gone."))

    # A life lost, the new-life tune, and appearing.
    game = _game(snapshot)
    frames = [game.frame()]
    game.each_turn.append(bn._kill)
    frames.append(game.turn())
    game.each_turn.pop()
    for _ in range(40):
        frames.append(game.turn())
        if frames[-1].m(ARRIVING) == HERE and frames[-2].m(ARRIVING) != HERE:
            break
    frames += game.turns(2)
    out.append(_recording(
        base, frames, rows, tunes=[TUNE_NEW_LIFE], name="life", entry=ARRIVE_SOUND,
        title="A life lost, and the next begun",
        what="His end, as KNIGHT_KILLED ($CEC4, in #R$CE89) makes it: both his records "
             "become puffs (graphic 12, "
             "#R$D7D8), and after their four frames each crackles in turn (#R$C435, sixteen "
             "waves from the ROM, legs then top). With a life to come, #R$CBAC plays the "
             "new-life tune and puts him back in the cell he died in (KNIGHT_KILLED copies "
             "it into the start records); then for "
             "seventeen turns, while ARRIVING climbs from 40 by two a turn, #R$C463 plays "
             "eight waves a turn at its complement -- 213 down to 181 -- a note that rises "
             "as he appears. The first life of a game appears the same way, without the "
             "tune.",
        how="the game running where a new game put him: his end begun at the start of a "
            "turn the way KNIGHT_KILLED ends a life (build_nightshade's _kill: both records "
            "to the "
            "puff graphic), five lives; recorded to two turns after he stood there again."))
    return out


def _town(snapshot: Path, base, rows) -> list[dict]:
    out = []

    # A monster appearing: put where #R$CDE8 puts one, at the point it does.
    keep = (MONSTERS,)
    game = _game(snapshot, keep)

    def appear(memory):
        record = MONSTERS
        memory[record:record + RECORD_SIZE] = memory[MONSTER_TEMPLATE:MONSTER_TEMPLATE
                                                     + RECORD_SIZE]
        u = memory[KNIGHT + 1]
        memory[record + 1] = (u + 48) & 0xFF if u < 0x80 else (u - 48) & 0xFF
        memory[record + 2] = memory[KNIGHT + 2]
        memory[record + 3] = memory[KNIGHT + 3]
        memory[record + 4] = memory[KNIGHT + 4]

    frames = [game.frame(), game.turn(at=(BEFORE_MONSTERS, appear))]
    for _ in range(6):
        frames.append(game.turn())
        if frames[-1].record(MONSTERS)[0] not in APPEARING:
            break
    out.append(_recording(
        base, frames, rows, name="appear", entry=APPEAR_SOUND, title="A monster appearing",
        what="#R$C164: a new monster spends four turns appearing, graphics 128 to 131, and "
             "on each, if it was on the screen the turn before, #R$C455 plays six waves at "
             "the complement of its graphic turned right three bits, the top three kept: "
             "224, 192, 160 and 128 -- four notes rising. Then it is a monster of the kind "
             "of the villain nearest it. #R$CDE8 starts one every fourth turn in the knight's "
             "cell or one next to it, so in play this is heard whenever one appears in "
             "sight. The same bytes are Pentagram's, left over as data there "
             "(<a href=\"../pentagram/Sounds.html#beeps\">Pentagram's sounds</a>).",
        how="the game running where a new game put him: at the point in a turn where "
            "#R$CDE8 starts a monster, one started as it does -- its record copied from "
            "the template it copies, put in the knight's cell -- 48 units from him along U; "
            "recorded until it had become a monster."))

    # The creature: the 256th turn brought forward.
    game = _game(snapshot, keep)
    game.each_turn[2:] = []            # his hits and lives as they come

    def turn_255(memory):
        memory[TURNS] = 0xFF

    frames = [game.frame()]
    game.each_turn.append(turn_255)
    frames.append(game.turn())
    game.each_turn.pop()
    seen = False
    for _ in range(200):
        frames.append(game.turn())
        graphic = frames[-1].record(MONSTERS)[0]
        seen |= graphic in CREATURE
        if seen and graphic not in CREATURE and graphic not in VANISHING:
            break
    if not seen:
        raise RuntimeError("the creature did not come")
    hits = (frames[0].m(HITS), frames[-1].m(HITS))
    out.append(_recording(
        base, frames, rows, name="creature", entry=BLIP_BY_TURN, title="The creature",
        what="Every 256th turn #R$BF95 puts the creature (graphics 136-139) at a random "
             "place in the knight's cell, and it makes for him, two units a turn each way "
             "(#R$BFF1). Every turn it was on the screen the turn before, #R$C332 blips: "
             "twelve waves at one of the sixteen pitches of #R$C34D, picked by the turn "
             "counter's low four bits -- counts of 32, 32, 48, 64, 80 over and over, a "
             "figure falling in pitch (sixteen is not a multiple of five, so where the "
             "counter comes round the top note is held three turns). When it touches him it "
             "bursts and takes one of his hits (#R$CE89), and its puff crackles as it ends "
             "(#R$C435). Pentagram has the routine and all five tables, the same bytes, and "
             "never reaches them "
             "(<a href=\"../pentagram/Sounds.html#blip\">Pentagram's sounds</a>).",
        how="the game running, the knight standing where a new game put him: the turn "
            "counter set to 255 at the start of a turn, so that the turn's count made it "
            "the 256th and #R$BF95 did its work; recorded until the creature had burst "
            f"and its puff had gone. His hits went from {hits[0]} to {hits[1]}."))
    return out


PAUSE = 0xE32C               # the pause, at the end of every turn
PAUSE_END = 0xE353


def _pause(snapshot: Path) -> str:
    """A pause and its going on in the running game: SPACE held into the end
    of a turn, let go, pressed again and let go, the machine checked to be
    waiting in #R$E32C at each step. The sentence that says what was heard."""
    from skoolkit.simutils import PC

    game = _game(snapshot)
    game.turn()
    first = len(game.tracer.edges)
    waiting = True
    game.hold(["SPACE"])
    game.run_to(0xE337)                  # past the test: the pause has begun
    for keys, seconds in ((["SPACE"], 0.3), ([], 0.5), (["SPACE"], 0.3)):
        game.hold(keys)
        game.sim.trace(game.machine.pc, 0, 0, game.now + int(seconds * TSTATES_PER_SECOND),
                       True, None, None, None, None, None)
        game.machine.pc = game.sim.registers[PC]
        waiting &= PAUSE <= game.machine.pc < PAUSE_END
    game.hold()
    game.run_to(MAIN_LOOP)
    edges = len(game.tracer.edges) - first
    return ("a pause in the running game -- SPACE held into the end of a turn for 0.3 s, "
            "let go 0.5 s, held 0.3 s and let go -- "
            + ("the game waiting in #R$E32C all the while, " if waiting else
               "the game NOT always waiting in #R$E32C, ")
            + ("made no edge at all" if not edges else f"made {edges} edges"))


def _villain_runs(snapshot: Path, base, rows) -> list[dict]:
    """Each villain held in the knight's cell for seventeen turns: what the
    hum actually plays."""
    out = []
    for index in range(4):
        record = VILLAINS + RECORD_SIZE * index
        game = _game(snapshot, (record,))
        graphic = game.memory[record]

        def hold(memory, record=record):
            u = memory[KNIGHT + 1]
            memory[record + 1] = (u + 64) & 0xFF if u < 0x80 else (u - 64) & 0xFF
            memory[record + 2] = memory[KNIGHT + 2]
            memory[record + 3] = memory[KNIGHT + 3]
            memory[record + 4] = memory[KNIGHT + 4]

        game.each_turn.append(hold)
        frames = [game.frame()] + game.turns(17)
        kind = (graphic - 96) >> 2
        offset = villain_offset(graphic)
        item = _recording(
            base, frames, rows, name=f"hum{(graphic - 96) >> 2}", entry=VILLAIN_UPDATE,
            title=f"Villain {graphic & 0xFC}-{(graphic & 0xFC) + 3}: what it hums",
            what="", how="")
        item.update({"graphic": graphic, "kind": kind, "offset": offset,
                     "how": "the game running, the knight standing where a new game put "
                            f"him: the villain of record ${record:04X} (graphic {graphic} "
                            "when the run began) put in his cell 64 units from him along U at "
                            "the start of every turn, so that it stayed in sight and out of "
                            "his reach; seventeen turns, the first silent (it had not been "
                            "drawn the turn before)."})
        out.append(item)
    return out


def _villain_intended(base, quiet_turn: int) -> list[dict]:
    """What each villain's own table would have played: #R$C335 given the
    table's address in BC, as #R$D94F meant it to be."""
    out = []
    scratch = 0x5B10                    # a record in the printer buffer, below the game
    for kind in range(4):
        table = VILLAIN_PITCHES + 16 * kind
        calls, expected = [], []
        for turn in range(16):
            calls.append(call(base, BLIP_FROM_TABLE, {"IX": scratch, "BC": table},
                              {scratch + 7: 0x02, TURNS: turn, TURNS + 1: 0}))
            expected += [base[table + turn]] * 12
        edges, length = in_a_row(calls, quiet_turn)
        ok, text = check_calls(base, edges, expected)
        out.append({"name": f"meant{kind}", "entry": BLIP_PITCHES, "kind": kind,
                    "table": table, "edges": edges, "length": length, "ok": ok,
                    "check": text, "pitch": _pitch(edges), "never": True})
    return out


def _ending(snapshot: Path, base, rows) -> dict:
    """The villains gone: the game-over tune, the ending's pictures with
    their notes, and the ending's tune."""
    game = _game(snapshot)

    def all_gone(memory):
        for index in range(4):
            record = VILLAINS + RECORD_SIZE * index
            memory[record:record + RECORD_SIZE] = bytes(RECORD_SIZE)

    frames = [game.frame()]
    game.each_turn.append(all_gone)
    frames.append(game.turn())
    game.each_turn = []
    if not game.memory[ENDING]:
        raise RuntimeError("the ending did not start")
    from skoolkit.simutils import PC
    for _ in range(600):
        start = game.now
        first = len(game.tracer.edges)
        speaker = game.tracer.speaker
        game.sim.trace(game.machine.pc, MAIN_LOOP, 0, start + TSTATES_PER_SECOND, True,
                       None, None, None, None, None)
        game.machine.pc = game.sim.registers[PC]
        final = game.machine.pc != MAIN_LOOP
        if final:
            # Part way through the ending's tune: on to the new game's start.
            game.run_to(0xBE0F)
        frame = Frame(game.memory, start, game.now,
                      [t - start for t in game.tracer.edges[first:]])
        frame.speaker = speaker
        frames.append(frame)
        if final:
            break
    else:
        raise RuntimeError("the ending did not end")
    return _recording(
        base, frames, rows, tunes=[TUNE_OVER, TUNE_ENDING], name="ending",
        entry=ENDING_BEEP, title="The villains gone: game over, and the ending",
        what="When the last villain's sparkles have gone, #R$D865 goes to #R$CC56 -- the "
             "same game-over screen and tune as when the lives run out -- and only then, "
             "finding no villain alive, does #R$CC56 set up the ending. Its four villain "
             "pictures (#R$CD58) come across one at a time and sink into the pit, and every "
             "turn one moves, #R$C39D plays twelve waves at 64 plus EFFECT_TIME, counted up "
             "one each time -- a slowly falling note -- which is reset as each picture sinks "
             "out of sight, so each one's note starts again from the top. When the last has "
             "gone, #R$CD10 plays the ending's tune, and it is the menu. The note is "
             "Pentagram's pause beep, put to another use "
             "(<a href=\"../pentagram/Sounds.html#pause\">Pentagram's sounds</a>); "
             "Nightshade's pause (#R$E32C) makes no sound at all.",
        how="the game running where a new game put him: the four villain records emptied "
            "at the start of a turn, which is how #R$D865 finds them once the fourth "
            "villain has been destroyed and its sparkles have gone; recorded from that turn "
            "to the start of the new game.")


# --------------------------------------------------------------------------
# The shared code, byte for byte.
# --------------------------------------------------------------------------

# Each shared routine or table: its name, where it starts here, how many
# bytes are compared, and for each game that has it, where it starts there
# and which bytes (offsets from the start) may differ without it being a
# different routine -- addresses of variables, tables and routines, which the
# games keep in different places, and anything else named.
SHARED = [
    ("CLICK", CLICK, 16, "one wave", {
        "Pentagram": (0xD682, {}), "Alien 8": (0xB702, {}), "Knight Lore": (0xB4ED, {})}),
    ("BEEP", BEEP, 7, "C waves", {
        "Pentagram": (0xD67B, {1: "a", 2: "a"}), "Alien 8": (0xB6FB, {1: "a", 2: "a"}),
        "Knight Lore": (0xB4E6, {1: "a", 2: "a"})}),
    ("PLAY_NOTE", PLAY_NOTE, 88, "the tune player's note", {
        g: (a, {9: "a", 10: "a", 12: "a", 13: "a"}) for g, a in
        (("Pentagram", 0xD6C0), ("Alien 8", 0xB4C5), ("Knight Lore", 0xB2DA))}),
    ("NOTES", NOTES, 183, "the note table", {
        "Pentagram": (0xD718, {}), "Alien 8": (0xB51D, {}), "Knight Lore": (0xB332, {})}),
    ("PLAY_TUNE", PLAY_TUNE, 11, "a tune through", {
        g: (a, {6: "a", 7: "a"}) for g, a in
        (("Pentagram", 0xD6B5), ("Alien 8", 0xB4BA), ("Knight Lore", 0xB2CF))}),
    ("PLAY_TUNE_ONCE", PLAY_TUNE_ONCE, 25, "the menu's tune, once", {
        g: (a, {1: "a", 2: "a", 10: "a", 11: "a", 21: "a", 22: "a"}) for g, a in
        (("Pentagram", 0xD69C), ("Alien 8", 0xB4A1), ("Knight Lore", 0xB2B6))}),
    ("BLIP_BY_TURN", BLIP_BY_TURN, 27, "the creature's blip", {
        "Pentagram": (0xD56C, {1: "a", 2: "a", 13: "a", 14: "a", 25: "a", 26: "a"})}),
    ("BLIP_PITCHES", BLIP_PITCHES, 80, "the five sixteens of pitches", {
        "Pentagram": (0xD587, {})}),
    ("ENDING_BEEP", ENDING_BEEP, 13, "the ending's note (Pentagram's pause beep)", {
        "Pentagram": (0xD5D7, {1: "a", 2: "a", 11: "a", 12: "a"})}),
    ("BUMP_SOUND", BUMP_SOUND + 5, 14, "the bump after its test (Pentagram's jump)", {
        "Pentagram": (0xD5E4, {8: "a", 9: "a"})}),
    ("EFFECT_NOTE", EFFECT_NOTE, 27, "an effect's note a turn", {
        "Pentagram": (0xD5F2, {1: "a", 2: "a", 11: "a", 12: "a", 14: "a", 15: "a", 25: "a",
                               26: "a"})}),
    ("EFFECT_TABLE", EFFECT_TABLE, 28, "the four effects", {
        "Pentagram": (0xD60D, {n: "a" for n in range(8)})}),
    ("FIRE_SOUND", FIRE_SOUND, 12, "a throw (Pentagram's bolt)", {
        "Pentagram": (0xD629, {6: "a", 7: "a"})}),
    ("FOOTSTEP", FOOTSTEP + 11, 21, "the walking half of a footstep", {
        "Pentagram": (0xD639, {9: "the waves", 12: "a jump", 17: "the waves",
                               20: "a jump"})}),
    ("PUFF_SOUND", PUFF_SOUND + 9, 23, "a puff after its test", {
        "Pentagram": (0xD64E, {1: "a", 2: "a", 8: "the waves", 17: "a", 18: "a"})}),
    ("APPEAR_SOUND", APPEAR_SOUND, 13, "a monster appearing", {
        "Pentagram": (0xD665, {})}),
    ("ARRIVE_SOUND", ARRIVE_SOUND, 7, "the knight appearing", {
        "Pentagram": (0xD674, {1: "a", 2: "a"})}),
]
SHARED_NOTES = {
    "BUMP_SOUND": "Nightshade's has five bytes in front, the test of the drawn flag.",
    "FOOTSTEP": "Four waves where Pentagram's are two; Nightshade's has the count and the "
                "test of the speed in front, and the faster half after.",
    "PUFF_SOUND": "Sixteen waves where Pentagram's are four; Nightshade's has the test and "
                  "clearing of the drawn flag in front.",
    "APPEAR_SOUND": "Pentagram's bytes are never reached, and are followed by a data byte "
                    "before its BEEP; Nightshade's jump to BEEP is one shorter.",
    "ARRIVE_SOUND": "Pentagram's reads a spare byte nothing writes; Nightshade's reads "
                    "ARRIVING.",
    "BLIP_BY_TURN": "Never reached in Pentagram.",
    "EFFECT_TABLE": "The same twenty notes; Pentagram starts effects 0 and 1 only.",
}
SNAPSHOTS = {"Pentagram": PENTAGRAM, "Alien 8": ALIEN_8, "Knight Lore": KNIGHT_LORE}
PAGES = {"Pentagram": "../pentagram/Sounds.html", "Alien 8": "../alien8/Sounds.html",
         "Knight Lore": "../knightlore/Sounds.html"}


def _other_memory(path: Path):
    if not path.exists():
        return None
    from skoolkit.snapshot import Snapshot

    return Snapshot.get(str(path)).memory[0:0x10000]


def comparisons(memory) -> tuple[list[list[str]], list[str]]:
    """Each shared routine against the other games' snapshots, if their
    builds have written them: the table's rows, and the games that were not
    there to compare with."""
    others = {game: _other_memory(path) for game, path in SNAPSHOTS.items()}
    rows, missing = [], [game for game, other in others.items() if other is None]
    for name, address, length, what, games in SHARED:
        cells = []
        for game in ("Pentagram", "Alien 8", "Knight Lore"):
            if game not in games or others[game] is None:
                cells.append("" if game not in games else "(not built)")
                continue
            there, allowed = games[game]
            other = others[game]
            differ = [n for n in range(length) if other[there + n] != memory[address + n]]
            if not differ:
                verdict = "identical"
            elif all(n in allowed for n in differ):
                kinds = {allowed[n] for n in differ}
                named = sorted(k for k in kinds if k != "a")
                verdict = (f"{len(differ)} bytes differ: "
                           + ", ".join((["addresses"] if "a" in kinds else []) + named))
            else:
                verdict = f"{len(differ)} bytes differ, NOT only those expected"
            cells.append(f"${there:04X}: {verdict}")
        rows.append([f"#R${address:04X}", f"{name}, {what}", str(length)] + cells
                    + [SHARED_NOTES.get(name, "")])
    return rows, missing


def tune_matches(memory) -> dict:
    """Any of the six tunes found byte for byte in another game's snapshot."""
    found = {}
    for game, path in SNAPSHOTS.items():
        other = _other_memory(path)
        if other is None:
            continue
        data = bytes(other)
        for name, tune, *_ in TUNES:
            if data.find(tune_bytes(memory, tune)) >= 0:
                found.setdefault(name, []).append(game)
    return found


# --------------------------------------------------------------------------
# Writing the page.
# --------------------------------------------------------------------------

def _length(tstates: int) -> str:
    seconds = tstates / TSTATES_PER_SECOND
    return f"{seconds * 1000:.0f} ms" if seconds < 1 else f"{seconds:.2f} s"


def _tune_pitch(sound, rows) -> str:
    notes = sound["tune"]
    lowest = min(row for row, _ in notes)
    highest = max(row for row, _ in notes)
    return (f"{note_hz(*rows[lowest][:2]):.0f} to {note_hz(*rows[highest][:2]):.0f} Hz "
            f"({note_name(lowest)} to {note_name(highest)})")


def _item(sound: dict, rows, entries: set) -> list[str]:
    file = f"audio/{sound['name']}.wav"
    stats = f"{_length(sound['length'])}, {len(sound['edges']):,} edges"
    if sound.get("turns"):
        turns = sound["turns"]
        stats += f", {turns} turn{'s' if turns != 1 else ''}"
    stats += ", " + (_tune_pitch(sound, rows) if sound.get("tune") else sound["pitch"])
    paragraphs = [sound["what"], f"Recorded: {sound['how']}", f"Checked: {sound['check']}."]
    lines = [f'<div class="kl-item" id="{sound["name"]}">',
             f"<h4>{_esc(sound['title'])}</h4>"]
    lines += [f"<p>{link(p, entries)}</p>" for p in paragraphs if p]
    lines += [f"<p>{stats}.</p>",
              f'<audio controls preload="none" src="{file}"><a href="{file}">'
              f"{sound['name']}.wav</a></audio>",
              "</div>"]
    return lines


def _table(header: list[str], rows: list[list[str]]) -> list[str]:
    lines = ['<table class="kl-table">',
             "<tr>" + "".join(f"<th>{h}</th>" for h in header) + "</tr>"]
    for row in rows:
        lines.append("<tr>" + "".join(f"<td>{cell}</td>" for cell in row) + "</tr>")
    lines.append("</table>")
    return lines


def _notes_table(rows, tunes) -> list[str]:
    used = {}
    for sound in tunes:
        for row, _ in sound["tune"]:
            used.setdefault(row, []).append(sound["title"])
    table = []
    for row in sorted(used):
        b, c, per_unit = rows[row]
        period = 2 * note_d(b, c) + NOTE_OFF + NOTE_ON
        titles = []
        for title in used[row]:
            if title not in titles:
                titles.append(title)
        table.append([str(row), note_name(row), str(b), str(c), str(per_unit),
                      f"{_hz(period):.1f}&nbsp;Hz",
                      f"{per_unit * period / TSTATES_PER_SECOND:.3f}&nbsp;s",
                      _esc(", ".join(titles))])
    return _table(["Row", "Note", "B", "C", "Waves a unit", "Pitch", "A unit", "Played in"],
                  table)


def _beep_hz(b: int) -> float:
    """A wave of BEEP's: on 13B + 18, off 13B + 64."""
    return _hz(26 * _count(b) + CLICK_ON + BEEP_OFF)


EFFECT_STARTS = ["#R$BF48: a new cell with a building", "#R$D727: the speed bonus",
                 "#R$D74C: the cure", "#R$D942: an object taken up"]
EFFECT_COUNTS = [4, 5, 7, 4]         # as each starter sets EFFECT_TIME


def _effects_table(base) -> list[str]:
    rows = []
    for effect, (start, count) in enumerate(zip(EFFECT_STARTS, EFFECT_COUNTS)):
        address = effect_address(base, effect)
        pitches = effect_pitches(base, effect, count)
        rows.append([str(effect), f"${address:04X}", str(count),
                     ", ".join(str(p) for p in pitches),
                     ", ".join(f"{_beep_hz(p):.0f}" for p in pitches), start])
    return _table(["Effect", "Its address", "Notes", "Half-wave counts, as played",
                   "Pitches (Hz)", "Started by"], rows)


TOKENS = 0x0095             # the ROM's table of BASIC keywords starts here


def _rom_text(base, start: int) -> str:
    """What of sixteen ROM bytes from `start` is the keyword table, as the
    letters (bit 7, the end of a keyword, dropped)."""
    if start + 16 <= TOKENS:
        return "(ROM code)"
    first = max(start, TOKENS)
    letters = "".join(chr(base[a] & 0x7F) for a in range(first, start + 16))
    return f"(from ${first:04X}, the keywords' letters {_esc(letters)})"


VILLAIN_SHAPES = ["counts climbing from 32 to 144, each twice: a scale falling",
                  "the same back down: a scale rising",
                  "counts in a zigzag from 144 down to 32: a zigzag rising",
                  "a figure of eight counts between 48 and 80, twice"]


def _villains_section(base, hums, meant, entries, rows) -> list[str]:
    lines = [
        "<h3>The villains' hum: a bug</h3>",
        "<p>A villain on the screen hums: every turn it was drawn the turn before, "
        "#R$D94F enters the creature's blip routine at BLIP_FROM_TABLE ($C335) for twelve "
        "waves at a pitch picked by the turn counter's low four bits. It was meant, by "
        "every sign, to give each villain its own sixteen pitches (an inference, but a "
        "safe one): #R$C34D holds five tables of "
        "sixteen, the creature's and then four more, VILLAIN_PITCHES ($C35D), and #R$D94F "
        "loads that address into HL and an offset by the villain's kind into BC before the "
        "call. Both halves are wrong. BLIP_FROM_TABLE builds its address as the turn's "
        "four bits in HL plus BC -- it overwrites HL, so the table's address is lost and "
        "BC alone is the base; and the offset, the graphic turned left two bits and ANDed "
        "with $F0, keeps the graphic's bit 5, which every villain (96-111) has set, in "
        "bit 7: it comes to $80, $90, $A0 or $B0, not 0, 16, 32 or 48 (AND $30 would have "
        "been right). So each villain hums sixteen bytes of the ROM, from $0080 to $00BF, "
        "and the four tables are never read. That part of the ROM is the end of a routine "
        "and, from $0095, the table of BASIC keywords, so three of the four villains hum "
        "mostly the spelling of keywords. (The mistakes read from the code; the pitches "
        "heard in the runs below, whose every wave matched the ROM's bytes.)</p>",
    ]
    table = []
    hums = sorted(hums, key=lambda hum: hum["graphic"])
    meant_by_kind = {want["kind"]: want for want in meant}
    for hum in hums:
        graphic, offset = hum["graphic"], hum["offset"]
        kind = hum["kind"]
        want = meant_by_kind[kind]
        actual = [base[offset + t] for t in range(16)]
        intended = [base[want["table"] + t] for t in range(16)]
        table.append([f"{graphic & 0xFC}-{(graphic & 0xFC) + 3}", f"${offset:02X}",
                      f"$00{offset:02X}-$00{offset + 15:02X}: {' '.join(map(str, actual))} "
                      + _rom_text(base, offset),
                      f"${want['table']:04X}: {' '.join(map(str, intended))} "
                      f"({VILLAIN_SHAPES[kind]})"])
    lines += _table(["Villain graphics", "BC as #R$D94F makes it", "What it hums (ROM)",
                     "Its own table, never read"], table)
    lines.append("<h4>What they hum</h4>")
    for hum in hums:
        hum = dict(hum)
        offset = hum["offset"]
        hum["what"] = (f"The villain of graphics {hum['graphic'] & 0xFC} to "
                       f"{(hum['graphic'] & 0xFC) + 3}: BC comes to ${offset:02X}, so its "
                       f"twelve waves a turn are pitched by the ROM's bytes ${offset:04X} to "
                       f"${offset + 15:04X}, one for each turn of sixteen.")
        lines += _item(hum, rows, entries)
    lines.append("<h4>What their tables would have played</h4>")
    lines.append("<p>Recorded by calling BLIP_FROM_TABLE ($C335) sixteen times for each, "
                 "with BC the table's address (VILLAIN_PITCHES plus 16 for each kind, which "
                 "is what the two mistakes stop #R$D94F from giving it), IX on a record "
                 "whose drawn flag is set, and the turn counter 0 to 15, a quiet turn apart: "
                 "the villain in sight for sixteen turns, as the runs above have it. None of "
                 "this is ever heard in the game.</p>")
    for want in meant:
        want = dict(want)
        kind = want["kind"]
        first = 96 + 4 * kind
        want["title"] = f"Villain {first}-{first + 3}, as meant"
        want["what"] = (f"The {'second third fourth fifth'.split()[kind]} of the five "
                        f"sixteens in #R$C34D, ${want['table']:04X}: {VILLAIN_SHAPES[kind]}.")
        want["how"] = ("sixteen calls of BLIP_FROM_TABLE ($C335) with BC = "
                       f"${want['table']:04X}, the turn counter 0 to 15, a quiet turn apart.")
        lines += _item(want, rows, entries)
    return lines


GROUPS = [
    ("The knight", ["footsteps", "footsteps_fast", "bump", "throw", "life"]),
    ("In the town", ["appear", "creature"]),
]


def _section(base, rows, tunes, effects, sounds, hums, meant, ending, quiet_turn, pause,
             entries) -> str:
    by_name = {sound["name"]: sound for sound in sounds}
    matches = tune_matches(base)
    shared, missing = comparisons(base)
    lines = [
        '<div class="kl-list">',
        "<p>A 48K Spectrum has one bit of sound hardware, bit 4 of port $FE, and "
        "Nightshade makes every sound by setting and clearing it with the processor "
        "counting in between, the border kept black. While a sound plays nothing else "
        "happens: the game stands still for a tune, and every beep lengthens the turn it "
        "is in. There are two players. The tunes go through #R$C661, a note at a time, "
        "from a table of notes; everything else is waves from #R$C471, which turns the "
        "speaker on for B turns of a 13 T-state loop and off for as long, most of them "
        "through BEEP ($C46A, the end of #R$C463), which repeats it C times. Almost all of "
        "it is code Pentagram has too, a few bytes apart -- Nightshade came first, so "
        "Pentagram's unused sound routines are Nightshade's, left behind -- and the tune "
        "player and its notes are Knight Lore's and Alien 8's as well (the table at the "
        'foot of the page). The pause, which in Pentagram and Alien 8 beeps, is silent '
        f"here: {pause}.</p>",
        "<p>Every recording here is the game's own code running in SkoolKit's simulator, "
        "each change of the speaker bit logged to the T-state and rendered at 44100 Hz; "
        "nothing is synthesised. What is heard in play was recorded from the game playing, "
        "a turn at a time, with whatever else sounded in those turns; to keep each "
        "recording to its subject the monsters were cleared away and the villains' drawn "
        "flags cleared at the start of every turn, except where they are the subject. "
        "Each recording is checked wave by wave against a model of the turn worked out "
        "from the code -- which records' routines sound, and at what half-wave count, "
        "given the state the turn began in -- and every off half-wave against the "
        "instruction timings of the loop that made it. The simulator has no memory "
        "contention, so all of this runs a touch faster, and a touch higher, than on a "
        "real Spectrum. "
        f"A quiet turn (the knight standing, nothing else about) lasts {quiet_turn:,} "
        f"T-states, {quiet_turn / TSTATES_PER_SECOND * 1000:.0f} ms; the calls that stand "
        "for a sound made over several turns are spaced by that.</p>",
        "<h3>Tunes</h3>",
        "<p>A tune is a string of note bytes ended by $FF: the low six bits index #R$C6B9, "
        "five octaves of semitones from G#1 to G6 with 0 a rest (no tune has one), and the "
        "top two bits are the length less one, one to four units of about 0.155 s. "
        "#R$C656 plays a tune through; #R$C63D plays the menu's once, stopping at a key. "
        "Six tunes, none of them another Ultimate game's"
        + (" (" + ", ".join(sorted({g for games in matches.values() for g in games}))
           + " share some: see each)" if matches else "")
        + " (compared at this build with "
        + ", ".join(g for g in SNAPSHOTS if g not in missing) + ").</p>",
    ]
    for sound in tunes:
        if matches.get(sound["name"]):
            sound = dict(sound)
            sound["what"] += (" The same notes as " + " and ".join(matches[sound["name"]])
                              + "'s (compared at this build).")
        lines += _item(sound, rows, entries)
    lines.append("<p>The notes the tunes use, worked out from #R$C6B9 and #R$C661's "
                 "timing: B and C time each half-wave, and a unit is that many waves. "
                 "The table has 61 rows; these are the ones any of the six tunes plays.</p>")
    lines += _notes_table(rows, tunes)

    lines += [
        "<h3>The sound effects</h3>",
        "<p>Four short effects are played a note a turn: whatever starts one sets "
        "EFFECT_TIME to its length and EFFECT to which, and at the end of every turn "
        "#R$C3BD plays twelve waves (#R$C463's BEEP) at the note EFFECT_TIME points to in "
        "#R$C3D8, then counts it down. The notes run backwards, from the byte the count "
        "points to down to the one after the effect's address, so the byte at each "
        "address is never played by its own effect -- it is the previous effect's first "
        "note. A new effect simply replaces one under way. The table's notes are "
        "Pentagram's too, twenty bytes the same, but Pentagram only ever starts the first "
        "two.</p>",
    ]
    lines += _effects_table(base)
    for sound in effects:
        lines += _item(sound, rows, entries)
    for heading, names in GROUPS:
        lines.append(f"<h3>{_esc(heading)}</h3>")
        for name in names:
            lines += _item(by_name[name], rows, entries)
    lines += _villains_section(base, hums, meant, entries, rows)
    lines.append("<h3>The ending</h3>")
    lines += _item(ending, rows, entries)
    lines += [
        "<h3>Shared with Pentagram, Alien 8 and Knight Lore</h3>",
        "<p>Each routine and table compared byte for byte, at this build, with the other "
        "games' snapshots (their own builds write them), at the place each has it. "
        "&quot;Addresses&quot; means the only bytes that differ are the operands naming "
        "variables, tables and routines, which each game keeps in its own places. The "
        "sounds pages: "
        + ", ".join(f'<a href="{PAGES[g]}">{g}</a>' for g in SNAPSHOTS)
        + (". Not built at this build, so not compared: " + ", ".join(missing)
           if missing else "")
        + ".</p>",
    ]
    lines += _table(["Here", "What", "Bytes", "Pentagram", "Alien 8", "Knight Lore",
                     "Note"], shared)
    lines.append("</div>")
    body = "\n".join(link(line, entries) for line in lines)
    for line in body.splitlines():
        if line.startswith((";", "[")):
            raise RuntimeError(f"a section line starts with {line[0]!r}: {line[:40]}")
    return body


def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    """Record every tune and effect into html_dir/audio, and return the
    Sounds section."""
    audio = html_dir / "audio"
    audio.mkdir(parents=True, exist_ok=True)
    base = _base(snapshot)
    rows = note_rows(base)
    log("Recording Nightshade's sounds...")
    quiet_turn = _quiet_turn(snapshot)
    tunes = _tunes(base, rows)
    effects = _effects(snapshot, base, rows)
    sounds = _knight(snapshot, base, rows) + _town(snapshot, base, rows)
    hums = _villain_runs(snapshot, base, rows)
    meant = _villain_intended(base, quiet_turn)
    ending = _ending(snapshot, base, rows)
    pause = _pause(snapshot)
    everything = tunes + effects + sounds + hums + meant + [ending]
    for sound in everything:
        if not sound["edges"]:
            raise RuntimeError(f"{sound['name']}: no sound was made")
        _write_wav(audio / f"{sound['name']}.wav", sound["edges"], sound["length"])
    failed = [sound["name"] for sound in everything if not sound.get("ok")]
    if failed:
        log(f"  WARNING: recordings that did not match the code: {', '.join(failed)}")
    log(f"  {len(everything)} sounds written to {audio}")
    return {"Sounds": _section(base, rows, tunes, effects, sounds, hums, meant, ending,
                               quiet_turn, pause, skool_entries())}
