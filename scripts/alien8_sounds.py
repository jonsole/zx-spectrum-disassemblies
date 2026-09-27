"""Alien 8's sounds, recorded from the game's own code at build time.

build_alien8.py --html calls build(), which writes a WAV of every tune and
sound effect into the HTML directory's audio/ folder and returns the Sounds
section. Nothing here is committed output: the sounds are the game's.

A 48K Spectrum has one bit of sound hardware, bit 4 of port $FE, and every
noise Alien 8 makes is its code setting and clearing that bit with the
processor counting in between. So a sound is recorded by running the code
that makes it in SkoolKit's simulator with a tracer that notes the T-state of
every OUT to port $FE that changes bit 4 (alien8_animations' GameTracer); the
gaps between those edges are the waveform, which SkoolKit's audio writer
renders to a WAV at 44100 Hz. Nothing is synthesised: every edge in every
file is an OUT the game executed.

Two kinds of recording:

- A call. The routine that makes the sound, called on a machine of its own
  built from the snapshot with the ROM in place, the registers and variables
  it reads set to the values given, and a return address the run stops at.
  A fresh machine for each call, so that nothing is inherited from the last.
  The tunes are recorded this way, and the sounds the game never plays.
- A run of turns. The game itself, started and put into a room the way
  alien8_animations stages its scenes, run a turn at a time, the edges kept
  with the real turns between them. Most effects are recorded this way, from
  the very runs the Animations page is made of: each is part of a scene the
  reader can watch there.

Each recording is checked against what the code says it should be: the
half-wave count B of every wave, worked out from the code and the objects'
records turn by turn, against the length of every on half-wave, which
#R$B702 makes 13B + 18 T-states; and, where one loop made all of it, the off
half-waves too, from the instruction timings of that loop (the constants
below). The machine is uncontended, so everything is a little faster, and
higher, than on a real Spectrum, where the ULA holds up the OUTs; the loops
themselves run above $8000, in uncontended memory, so the difference is
small.
"""
from __future__ import annotations

import html
from pathlib import Path

import alien8_animations as aa
import build_alien8 as ba

TSTATES_PER_SECOND = 3_500_000
CALL_STACK = 0xF000         # in the game's own stack space ($EA00-$F0FF)
STOP = 0x5B00               # the return address: the run stops there (the variables)
CALL_LIMIT = 90 * TSTATES_PER_SECOND

# The sound code (see the entries).
TUNE_START, TUNE_WON, TUNE_OVER = 0xB3C5, 0xB3D7, 0xB3F7
TUNE_ARRIVAL, TUNE_MENU = 0xB437, 0xB451
PLAY_TUNE_ONCE = 0xB4A1
PLAY_TUNE_TILL_KEY = 0xB4A9    # PLAY_TUNE_ONCE's second entry
PLAY_TUNE = 0xB4BA
PLAY_NOTE = 0xB4C5
NOTES = 0xB51D
NOTE_ROWS = 61
FRAGMENT = 0xB5D4              # unreached code at the end of the note table
FRAGMENT_PITCHES = 0xB5E6
SPARKLE_SOUND = 0xB5EE
MATERIALISE_SOUND = 0xB604
THUD_SOUND = 0xB619
JUMP_SOUND = 0xB62C
BEEP_BY_Z = 0xB63C
BEEP_BY_A = 0xB63F
BEEP_BY_U, BEEP_BY_V, BEEP_BY_UVZ = 0xB64A, 0xB64F, 0xB654
TRANSFORM_SOUND = 0xB65F
CRASH_SOUND = 0xB676
WARBLE_SOUND = 0xB690
WARBLE_COUNTS = 0xB6A9
PLAIN_BEEP, PAUSE_BEEP, HIGH_BEEP = 0xB6B1, 0xB6B6, 0xB6BB
LOWER_HALF_STEP = 0xB6C0
LOWER_HALF_PAST_TEST = 0xB6C6  # its code after the test that is never passed
FOOTSTEP = 0xB6CE
FOOTSTEP_NOW = 0xB6D4
BEEP = 0xB6FB
CLICK = 0xB702

TUNE_HEARD = 0x5B31
TURNS = 0x5B02
RANDOM = 0x5B05
SPARKLE_PITCHES = 0x1234       # #R$B5EE reads the ROM from here

# Knight Lore's and Pentagram's players and tables, to compare with (their
# builds write their snapshots here).
KNIGHT_LORE = ba.PROJECT_ROOT / "game_disassembly" / "knightlore" / "knightlore.sna"
KL_PLAY_NOTE, KL_NOTES, KL_TRANSFORM = 0xB2DA, 0xB332, 0xB472
KL_TUNES = {"the start of a game": 0xB20E, "game over": 0xB218,
            "the game completed": 0xB239, "the menu": 0xB253}
PENTAGRAM = ba.PROJECT_ROOT / "game_disassembly" / "pentagram" / "pentagram.z80"
PG_PLAY_NOTE, PG_NOTES = 0xD6C0, 0xD718
PG_TUNES = {"the menu": 0xD7CF, "a tune nothing plays": 0xD824, "the start of a game": 0xD833,
            "a quest item done": 0xD847, "game over": 0xD853, "the quest complete": 0xD86F}
PLAY_NOTE_LENGTH = NOTES - PLAY_NOTE                 # 88 bytes
PLAY_NOTE_OPERANDS = {0xB4CE, 0xB4CF, 0xB4D1, 0xB4D2}  # CALL ADD_HL_A and LD BC,NOTES
TRANSFORM_LENGTH = CRASH_SOUND - TRANSFORM_SOUND     # 23 bytes
TRANSFORM_OPERANDS = {0xB670, 0xB671}                # its CALL CLICK
# The fragment after the notes against Knight Lore's blip for its movable
# block (type 62), the code and its eight pitches: 26 bytes, of which the
# three addresses (the turn counter for Knight Lore's frame counter, the
# table, BEEP) may differ.
KL_BLIP = 0xB3E9
FRAGMENT_LENGTH = SPARKLE_SOUND - FRAGMENT           # 26 bytes
FRAGMENT_OPERANDS = {0xB5D5, 0xB5D6, 0xB5DD, 0xB5DE, 0xB5E4, 0xB5E5}

# Half-waves, in T-states, from the instructions of the loops that make them.
# CLICK ($B702) turns the speaker on (OUT) and waits B turns of DJNZ (13
# T-states each, 8 for the last), then LD A,B... LD B,A, XOR A and the OUT that
# turns it off: every on half-wave any effect makes is 13B + 18 (B = 0 counts
# 256). Its off half-wave is its second DJNZ with the same B, then LD B,A and
# RET, then whatever the caller does before it calls CLICK again and CLICK's
# LD A,$10 and OUT: 13B plus a constant per loop --
CLICK_ON = 18
# BEEP's DEC C, JR NZ and CALL: C waves of one pitch.
BEEP_OFF = 64
# JUMP_SOUND's DEC C, JR NZ, LD A,C, five RRCAs, LD B,A and CALL.
JUMP_OFF = 92
# MATERIALISE_SOUND's DEC C, JR NZ, LD A,C, two RLCAs, LD B,A and CALL.
MATERIALISE_OFF = 80
# TRANSFORM_SOUND's DEC C, JR NZ, LD A,C, XOR, ADD, LD B,A and CALL.
TRANSFORM_OFF = 83
# WARBLE_SOUND's DEC C, JR NZ, LD A,(TURNS), XOR C, AND, OR, LD B,A and CALL.
WARBLE_OFF = 99
# Between the blips of the effects made of several BEEPs: CLICK's tail,
# BEEP's DEC C, JR NZ falling through (7) and RET, the caller's DEC E and JR
# NZ, its set-up of the next blip, BEEP's CALL and CALL of CLICK, and CLICK's
# LD and OUT. SPARKLE_SOUND sets up with LD A,(HL), INC HL, LD B,A and LD C,2:
# 126. CRASH_SOUND adds an AND $7F: 133. THUD_SOUND loads LD C,3 first and
# ORs in $C0 instead of the AND: 133 too.
SPARKLE_GAP, CRASH_GAP, THUD_GAP = 126, 133, 133
# PLAY_NOTE ($B4C5), Knight Lore's and Pentagram's routine byte for byte but
# for two addresses, times each half with a DJNZ loop run C times over (the
# first pass B turns, the rest 256), which with its DEC C and JR NZ comes to
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


def _rotl(value: int, bits: int) -> int:
    value &= 0xFF
    return ((value << bits) | (value >> (8 - bits))) & 0xFF


def note_name(row: int) -> str:
    """The note table's scale, as Pentagram's pages work it out: row 1 is
    G#1 and row 38 A4."""
    midi = row + 31
    return f"{NAMES[midi % 12]}{midi // 12 - 1}"


# --------------------------------------------------------------------------
# Recording.
# --------------------------------------------------------------------------

def _base(snapshot: Path) -> list:
    from skoolkit import read_bin_file

    memory = list(ba.game_memory(snapshot))
    memory[:0x4000] = read_bin_file(str(ba.ROM))
    return memory


def call(base, address: int, registers=None, pokes=None, keys=()):
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
    tracer = aa._tracer_class()(simulator)
    tracer.keys = set(keys)
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
    of the half-wave, where it is not 13B + 18 for any B)."""
    on, _ = halves(edges)
    return [(t - CLICK_ON) // 13 if (t - CLICK_ON) % 13 == 0 and t > CLICK_ON else -t
            for t in on]


def _write_wav(path: Path, edges: list[int], length: int) -> None:
    """Render the speaker edges to a WAV. SkoolKit's writer takes the gaps
    between flips, starting from the speaker off; a recording that ends with
    the speaker on (every tune does: #R$B4C5 ends each wave on) is turned off
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


def tune_bytes(memory, address: int) -> list[int]:
    out = []
    while memory[address] != 0xFF:
        out.append(memory[address])
        address += 1
    return out


TUNES = [
    ("tune_start", TUNE_START, PLAY_TUNE, "The start of a game",
     "Played to its end by #R$A647 once 0 has been pressed at the menu, before the "
     "robot is put in his start room: the game stands still while it plays."),
    ("tune_menu", TUNE_MENU, PLAY_TUNE_ONCE, "The menu",
     "TUNE_MENU ($B451, in #R$B436), played by #R$B4A1 from the menu's loop (#R$BA7E) "
     "the first time the menu is shown after the game is loaded or a game ends "
     "(TUNE_HEARD); any key stops it between two notes."),
    ("tune_over", TUNE_OVER, PLAY_TUNE_TILL_KEY, "Game over",
     "Played by #R$B761 under the summary after every game, won or lost, through "
     "#R$B4A1's second entry, which stops it at a key but does not mark it heard; then "
     "about fourteen seconds' wait for a key (#R$B899), and the scene after the game."),
    ("tune_arrival", TUNE_ARRIVAL, PLAY_TUNE, "The station arrives",
     "TUNE_ARRIVAL ($B437, in #R$B436), played to its end by #R$B8A9 under the arrival "
     "screen when the twenty-fourth chamber has been activated, before the summary."),
    ("tune_won", TUNE_WON, PLAY_TUNE, "The end of the winning scene",
     "Played to its end by #R$A971 when the robot has been lowered into the can of oil "
     "and raised again, gleaming, at the end of the scene after a won game; then the "
     "menu. It begins with the whole of the start tune."),
]


def _tunes(base) -> list[dict]:
    rows = note_rows(base)
    out = []
    for name, tune, player, title, what in TUNES:
        pokes = {TUNE_HEARD: 0} if player == PLAY_TUNE_ONCE else None
        edges, length = call(base, player, {"DE": tune}, pokes)
        notes = tune_notes(base, tune)
        how = f"#R${player:04X} called with DE = ${tune:04X}"
        if player == PLAY_TUNE_ONCE:
            how += (", TUNE_HEARD clear and no key down, so that it plays to the end, as it "
                    "does for a player who waits")
        elif player == PLAY_TUNE_TILL_KEY:
            how = ("#R$B4A1's second entry, PLAY_TUNE_TILL_KEY ($B4A9), called with DE = "
                   f"${tune:04X} and no key down, so that it plays to the end")
        out.append({"name": name, "entry": tune, "title": title, "what": what,
                    "how": how + ".", "edges": edges, "length": length, "tune": notes,
                    "check": _tune_check(edges, notes, rows)})
    return out


def _tune_check(edges, notes, rows) -> str:
    """Waves and half-waves against the note table and PLAY_NOTE's timing."""
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
    # The first OUT turns the speaker off, which it already is: no edge.
    ok_edges = len(edges) == 2 * waves - 1
    off_ok = off == expected_off[1:len(off) + 1]
    on_ok = all(e is None or m == e for m, e in zip(on, expected_on))
    rests = sum(1 for row, _ in notes if row == 0)
    units = sum(u for _, u in notes)
    lowest = min(row for row, _ in notes)
    highest = max(row for row, _ in notes)
    return (f"{len(notes)} notes, {units} units"
            + (f" (with {rests} rests)" if rests else ", no rests")
            + f", from row {lowest} ({note_name(lowest)}, "
            f"{note_hz(*rows[lowest][:2]):.0f} Hz) to row {highest} ({note_name(highest)}, "
            f"{note_hz(*rows[highest][:2]):.0f} Hz). The table's wave counts make that "
            f"{waves:,} waves, so {2 * waves - 1:,} edges (the first OUT turns off a "
            "speaker already off); the recording has "
            f"{len(edges):,}" + (" -- the same" if ok_edges else " -- NOT the same")
            + ". Every off half-wave "
            + ("was" if off_ok else "was NOT always")
            + " D + 39 T-states and every on half-wave inside a note "
            + ("was" if on_ok else "was NOT always")
            + " D + 62, D being 13B + 3339C - 3333 for the note's B and C, as "
            "#R$B4C5's loops imply")


def _other_memory(path: Path):
    if not path.exists():
        return None
    from skoolkit.snapshot import Snapshot

    return Snapshot.get(str(path)).memory


def comparisons(memory) -> tuple[str, dict]:
    """The note player and table against Knight Lore's and Pentagram's, and
    each tune against theirs, if their snapshots have been built alongside.
    Returns the sentences for the page and, per tune, what it matches."""
    parts, matches = [], {}
    for game, path, player, table, tunes in (
            ("Knight Lore", KNIGHT_LORE, KL_PLAY_NOTE, KL_NOTES, KL_TUNES),
            ("Pentagram", PENTAGRAM, PG_PLAY_NOTE, PG_NOTES, PG_TUNES)):
        other = _other_memory(path)
        if other is None:
            parts.append(f"{game}'s snapshot was not there to compare with at this build.")
            continue
        differ = {PLAY_NOTE + i for i in range(PLAY_NOTE_LENGTH)
                  if other[player + i] != memory[PLAY_NOTE + i]}
        same_table = list(other[table:table + 3 * NOTE_ROWS]) == list(
            memory[NOTES:NOTES + 3 * NOTE_ROWS])
        parts.append(
            f"Against {game}'s snapshot at this build: of the {PLAY_NOTE_LENGTH} bytes of "
            f"#R$B4C5, the {len(differ)} that differ from {game}'s player (${player:04X}) "
            + ("are exactly the two addresses in it, the CALL to #R$CE06 and the LD of "
               "#R$B51D" if differ == PLAY_NOTE_OPERANDS else "are NOT only its two "
               "addresses")
            + f"; and the 183 bytes of #R$B51D are its note table (${table:04X}) "
            + ("exactly." if same_table else "-- NOT exactly."))
        for name, address, *_ in TUNES:
            mine = tune_bytes(memory, address)
            for title, theirs in tunes.items():
                if tune_bytes(other, theirs) == mine:
                    matches.setdefault(name, []).append(f"{game}'s tune for {title}")
    return " ".join(parts), matches


def fragment_comparison(memory) -> tuple[bool, str]:
    """Whether the fragment at $B5D4 is Knight Lore's movable-block blip
    but for its addresses, and the sentence that says how that was found."""
    other = _other_memory(KNIGHT_LORE)
    if other is None:
        return False, ""
    differ = {FRAGMENT + i for i in range(FRAGMENT_LENGTH)
              if other[KL_BLIP + i] != memory[FRAGMENT + i]}
    same = differ <= FRAGMENT_OPERANDS
    return same, (f" Compared at this build with Knight Lore's snapshot: of its "
                  f"{FRAGMENT_LENGTH} bytes, code and pitch table, the {len(differ)} that "
                  f"differ from Knight Lore's routine at ${KL_BLIP:04X} and the table after "
                  f"it are "
                  + ("only the three addresses in it (the turn counter for Knight Lore's "
                     "frame counter, the table, BEEP); the eight pitches are the same."
                     if same else "NOT only its three addresses."))


def transform_comparison(memory) -> str:
    other = _other_memory(KNIGHT_LORE)
    if other is None:
        return ""
    differ = {TRANSFORM_SOUND + i for i in range(TRANSFORM_LENGTH)
              if other[KL_TRANSFORM + i] != memory[TRANSFORM_SOUND + i]}
    return (f" Checked at this build against Knight Lore's snapshot: of its "
            f"{TRANSFORM_LENGTH} bytes, the {len(differ)} that differ from Knight Lore's "
            f"sound_transform (${KL_TRANSFORM:04X}) are "
            + ("exactly the address in its CALL of #R$B702." if differ == TRANSFORM_OPERANDS
               else "NOT only the address in its CALL."))


# --------------------------------------------------------------------------
# What the code says each wave should be: the B (the half-wave count) of
# every wave each sound routine makes, from its arguments.
# --------------------------------------------------------------------------

def beep_a(value: int) -> list[int]:
    """#R$B63F: six waves at the complement of 64 more than the value, turned
    left twice (#R$B63C for Z, #R$B64A for U, #R$B64F for V, #R$B654 for
    U + V + Z)."""
    return [_rotl(~(value + 0x40), 2)] * 6


PLAIN = [0x80] * 16            # #R$B6B1
PAUSE = [0x50] * 24            # #R$B6B6
HIGH = [0x30] * 32             # #R$B6BB


def jump_waves() -> list[int]:
    """#R$B62C: one wave a step for C = 32 down to 1, at C turned right five
    times -- 1 for 32, then 8C."""
    return [_rotl(c, 3) for c in range(32, 0, -1)]


def materialise_waves(graphic: int) -> list[int]:
    """#R$B604: one wave a step from 4 * (graphic AND 7) + 3 down to 1, at
    four times the step."""
    return [4 * c for c in range(4 * (graphic & 7) + 3, 0, -1)]


def sparkle_waves(base, graphic: int) -> list[int]:
    """#R$B5EE: two waves at each ROM byte from $1234 on, as many blips as
    the complement of the graphic's low five bits."""
    return [base[SPARKLE_PITCHES + n] for n in range(~graphic & 0x1F) for _ in (0, 1)]


def thud_waves(base) -> list[int]:
    """#R$B619: three waves at each of the ROM's first four bytes, OR $C0."""
    return [base[n] | 0xC0 for n in range(4) for _ in range(3)]


def footstep_waves(record: bytes, turns: int, pitch: int = 0x60) -> list[int]:
    """#R$B6CE past its test (FOOTSTEP_NOW): `pitch` (96), or on alternate
    pairs of turns (bit 1 of the turn counter) a pitch from the height; as
    many waves as (U/2 + (256-V)/2)/16."""
    u, v, z = record[1], record[2], record[3]
    b = pitch if not turns & 2 else (~(z + 0x40) & 0xFF) >> 1
    count = (((u >> 1) + (((-v) & 0xFF) >> 1)) & 0xFF) >> 4
    return [b] * _count(count)


def warble_waves(base, table: int, turns: int) -> list[int]:
    """#R$B690: C from the table by the turn counter's low two bits, then one
    wave for each C down to 1, at 64 + ((turns XOR C) AND 31)."""
    count = base[table + (turns & 3)]
    return [0x40 | ((turns ^ c) & 0x1F) for c in range(count, 0, -1)]


# A placeholder for #R$B676's sixteen blips, whose pitches come from an
# address made of the random number as it is at that moment: checked against
# the ROM rather than predicted.
CRASH = "crash"
CRASH_WAVES = 32


def _signed(value: int) -> int:
    return value - 256 if value > 127 else value


def fall_waves(before: bytes, jump_started: bool, jump_held: bool) -> list[int]:
    """#R$C296's falling note for the robot: gravity takes one off his Z step
    while he is rising or level with jump held and two otherwise, and a new
    step of -3 or less sounds #R$B63C at his height as the turn began."""
    step = 8 if jump_started else _signed(before[0x0B])
    step -= 1 if step >= 0 and jump_held else 2
    return beep_a(before[3]) if step + 2 < 0 else []


# --------------------------------------------------------------------------
# Checking a recording against those.
# --------------------------------------------------------------------------

# An off half-wave longer than 13B plus this is a silence between two sounds,
# not part of one.
IN_A_SOUND = 200
LOOP_CONSTANTS = {BEEP_OFF: "BEEP's, in #R$B6CE", JUMP_OFF: "#R$B62C's",
                  MATERIALISE_OFF: "#R$B604's", TRANSFORM_OFF: "#R$B65F's",
                  WARBLE_OFF: "#R$B690's", SPARKLE_GAP: "#R$B5EE's between blips",
                  CRASH_GAP: "#R$B676's and #R$B619's between blips"}


def _crash_in_rom(base, waves: list[int]) -> bool:
    """Sixteen blips of two waves at ROM bytes in a row, less their top
    bits, from the first 8K (#R$B676's address is the random number and the
    turn counter's low five bits)."""
    if len(waves) != CRASH_WAVES or any(waves[i] != waves[i + 1] for i in range(0, 32, 2)):
        return False
    wanted = waves[::2]
    rom = [b & 0x7F for b in base[:0x2000 + 16]]
    for start in range(0x2000):
        if rom[start:start + 16] == [w & 0xFF for w in wanted]:
            return True
    return False


def _check(base, edges: list[int], expected: list, what: str = "waves") -> str:
    """Every wave's B against the code's (a crash placeholder against the
    ROM), and every off half-wave inside a sound against 13B plus the
    constant of one of the loops that make them."""
    measured = clicks(edges)
    flat, crashes = [], 0
    position, matched, crash_ok = 0, True, True
    for item in expected:
        if item == CRASH:
            chunk = measured[position:position + CRASH_WAVES]
            crash_ok &= _crash_in_rom(base, [256 if b == 256 else b for b in chunk])
            crashes += 1
            flat += chunk
            position += CRASH_WAVES
        else:
            flat.append(_count(item))
            position += 1
    matched = measured == flat
    _, offs = halves(edges)
    constants, strange = set(), 0
    for off, b in zip(offs, measured):
        if b < 0:
            continue
        extra = off - 13 * b
        if extra in LOOP_CONSTANTS:
            constants.add(extra)
        elif extra < IN_A_SOUND:
            strange += 1
    text = (f"{len(measured):,} {what}, {len(edges):,} edges (the code implies "
            f"{len(flat):,} and {2 * len(flat):,}); every on half-wave "
            + ("was" if matched else "was NOT")
            + " 13B + 18 T-states for the B the code gives it")
    if not matched:
        where = next((n for n, (a, b) in enumerate(zip(measured, flat)) if a != b),
                     min(len(measured), len(flat)))
        text += (f" (first difference at wave {where}: measured "
                 f"{measured[where:where + 6]}, expected {flat[where:where + 6]})")
    if crashes:
        text += (f"; the {crashes} crash{'es' if crashes > 1 else ''}' pitches "
                 + ("were" if crash_ok else "were NOT")
                 + " sixteen ROM bytes in a row, less their top bits, as #R$B676 reads them")
    text += ("; and every off half-wave inside a sound was 13B plus "
             + (", ".join(f"{k} ({LOOP_CONSTANTS[k]})" for k in sorted(constants))
                if constants else "nothing")
             + (" -- the loops' own timing" if not strange else
                f", but {strange} were NOT one of the loops' constants"))
    return text


def _pitch(edges: list[int]) -> str:
    """The range of the waves' pitches, each wave measured from its on edge
    to the next wave's, inside a sound."""
    on, off = halves(edges)
    tones = []
    for a, b in zip(on, off):
        if b < 13 * 256 + IN_A_SOUND:
            tones.append(_hz(a + b))
    if not tones:
        return "single waves"
    low, high = min(tones), max(tones)
    return f"{low:.0f} Hz" if round(low) == round(high) else f"{low:.0f} to {high:.0f} Hz"


# --------------------------------------------------------------------------
# The game, running: what each turn of a run should sound like.
# --------------------------------------------------------------------------

LEGS, TOP = aa.LEGS, aa.TOP
VALVE = 2                     # the first of the records for what lies in the room


def _pairs(frames: list):
    """(before, now) for each turn after the first: the state a turn began
    with is the one the turn before left."""
    return list(zip(frames, frames[1:]))


def _legs_waves(before, now, jump: bool = False) -> list[int]:
    """What the robot's legs sound in a turn in which he stands or walks: a
    beep for an accepted press of the pick-up key (#R$BD6B), the jump
    (#R$C23D), a footstep on leaving a stride (#R$C25E), and the falling note
    (#R$C296). Only for the legs walking about (graphics 16-23)."""
    legs = before.record(LEGS)
    if legs[0] not in ba.LEGS:
        return []
    waves = []
    if aa.TAKE_KEY in now.keys and aa.TAKE_KEY not in before.keys:
        waves += PLAIN
    held = aa.JUMP_KEY in now.keys
    started = held and not legs[0x0C] & 0x08 and now.record(LEGS)[0x0C] & 0x08
    if started:
        waves += jump_waves()
    jumping = started or legs[0x0C] & 0x08
    if (jumping or aa.WALK_KEY in now.keys) and not legs[0] & 1:
        waves += footstep_waves(legs, before.turn)
    return waves + fall_waves(legs, bool(started), held)


def _vanished(before, now, index: int) -> bool:
    """The record's graphic went to 1 (and so to 0) this turn."""
    return before.record(index)[0] > 1 and now.record(index)[0] in (0, 1)


def _uvz(record: bytes) -> int:
    return record[1] + record[2] + record[3]


def _facing(record: bytes) -> tuple[int, int]:
    return record[0] & 1, record[7] & aa.MIRRORED


def _window(frames: list, first: int, last: int) -> list:
    """frames[first..last], and the one before for the state it began in."""
    return frames[max(0, first - 1):last + 1]


def _recording(frames: list, expected: list, base, **fields) -> dict:
    """A recording of the turns after the first of `frames` (which gives the
    state they began in), checked against `expected`."""
    turns = frames[1:]
    if turns[0].speaker:
        raise RuntimeError(f"{fields.get('name')}: the speaker was on as the recording began")
    edges, length = from_turns(turns)
    fields.update({"edges": edges, "length": length, "turns": len(turns),
                   "check": _check(base, edges, expected), "pitch": _pitch(edges)})
    return fields


def _quiet_turn(snapshot: Path) -> int:
    """The median length of a turn standing still in the empty room."""
    game = aa.started(snapshot)
    game.enter(aa.EMPTY_ROOM, 128, 128, facing=1)
    lengths = sorted(f.tstates for f in game.turns(12))
    return lengths[len(lengths) // 2]


def _robot(snapshot: Path, base) -> list[dict]:
    out = []

    # Walking: an own run, walk held for 16 turns from standing.
    game = aa.started(snapshot)
    game.enter(aa.EMPTY_ROOM, 128, 96, facing=2)
    frames = [game.turn()]
    game.hold([aa.WALK_KEY])
    frames += game.turns(16)
    game.hold()
    frames += game.turns(2)
    expected = [w for b, n in _pairs(frames) for w in _legs_waves(b, n)]
    out.append(_recording(
        frames, expected, base, name="footsteps", entry=FOOTSTEP, title="Walking",
        what="#R$B6CE, from #R$C25E each time the legs leave a stride (frames 0 and 2 of "
             "four): a footstep every other turn, its pitch a fixed half-wave count of 96 "
             "or, on alternate pairs of turns (bit 1 of the turn counter), one from his "
             "height -- a tick and a tock -- and its length, (U/2 + (256-V)/2)/16 waves, "
             "longer towards plus U and shorter towards plus V. Knight Lore's footstep.",
        how=f"the game running in the empty room (${aa.EMPTY_ROOM:02X}): walk held for 16 "
            "turns from standing, facing plus V, and two turns after."))

    # Turning round: the turning animation's run.
    frames = aa.run(snapshot, aa.turning)["turns"]
    expected = []
    for before, now in _pairs(frames):
        if 24 <= before.record(LEGS)[0] <= 27 and now.record(LEGS)[0] in ba.LEGS:
            expected += footstep_waves(before.record(LEGS), before.turn)
    out.append(_recording(
        frames, expected, base, name="turn", entry=FOOTSTEP_NOW, title="Turning",
        what="The turn's sound: #R$C1E2, as a part-way view ends and the legs take the "
             "new facing, calls #R$B6CE past its test on the frame (FOOTSTEP_NOW, $B6D4): "
             "a footstep, whatever the legs' frame. So a quarter turn ends in a tick. "
             "#R$C1E2 does not keep BC round the call, and the footstep's loop leaves C, "
             "the controls, at zero: on that turn he takes no step and gravity ignores a "
             "held jump.",
        how="the game running: the turning animation's run -- right turn held from "
            "standing for a whole circle, four quarter turns."))

    # The jump: the jumping animation's run.
    frames = aa.run(snapshot, aa.jumping)["turns"]
    expected = [w for b, n in _pairs(frames) for w in _legs_waves(b, n)]
    out.append(_recording(
        frames, expected, base, name="jump", entry=JUMP_SOUND, title="A jump",
        what="#R$B62C, from #R$C23D as the jump starts: 32 single waves at half-wave "
             "counts of 8C for C = 31 down to 1 (the first, 32, rotates round to 1) -- a "
             "rising sweep; Knight Lore's jump. Then the legs step all through the jump, "
             "with their footsteps, and once he is falling faster than two units a turn "
             "#R$C296 plays #R$B63C, six waves pitched by his height, every turn until he "
             "lands -- and one turn after, as the step the landing left is taken as a "
             "fall again.",
        how="the game running: the jumping animation's run -- jump held from standing "
            "until he landed, and two turns after."))

    # Picking up and putting down: the carrying animation's run.
    frames = aa.run(snapshot, aa.carrying)["turns"]
    expected = []
    for before, now in _pairs(frames):
        expected += _legs_waves(before, now)
        valve = now.record(VALVE)
        if before.record(VALVE)[0] == 0 and valve[0] in range(96, 100):
            expected += beep_a(_uvz(valve))
    out.append(_recording(
        frames, expected, base, name="pickup", entry=PLAIN_BEEP,
        title="Picking up and putting down",
        what="#R$B6B1, sixteen waves at 128, for every press of the pick-up key that "
             "#R$BD6B acts on -- picking up, moving the slots along, putting down. The "
             "valve put down makes a note of its own on the same turn (#R$AF79 sees bit "
             "0 of +D and plays #R$B654, pitched by U + V + Z). The same beep is the "
             "menu's (below), the extra life's and the sparks' in the scene after a lost "
             "game.",
        how="the game running: the carrying animation's run -- a valve (staged) in "
            "front of him, four presses of 1, four turns apart."))

    # The pause: an own run.
    game = aa.started(snapshot)
    game.enter(aa.EMPTY_ROOM, 128, 128, facing=1)
    start = game.now
    first = len(game.tracer.edges)
    for keys, seconds in ((["SPACE"], 0.3), ([], 0.5), (["SPACE"], 0.3), ([], 0.1)):
        game.hold(keys)
        game.sample(int(seconds * TSTATES_PER_SECOND))
    game.hold()
    game.to_turn()
    game.turns(2)
    edges = [t - start for t in game.tracer.edges[first:]]
    out.append({"name": "pause", "entry": PAUSE_BEEP, "title": "Pausing, and going on",
                "what": "#R$B6B6, 24 waves at a half-wave count of 80, played by #R$CE22 "
                        "at the end of a turn as SPACE (or CAPS SHIFT) alone pauses the "
                        "game, and again as the next press lets it go on. Knight Lore's "
                        "pause beep. Interrupts stay off throughout.",
                "how": "the game running in the empty room: SPACE held 0.3 s, let go 0.5 "
                       "s, held 0.3 s, let go; recorded on to two turns later. The silence "
                       "in the middle is the pause, as long as it was held.",
                "edges": edges, "length": game.now - start,
                "check": _check(base, edges, PAUSE + PAUSE), "pitch": _pitch(edges)})

    # Dying, and appearing: the dying animation's run.
    frames = aa.run(snapshot, aa.dying)["turns"]
    kill = next(n for n, f in enumerate(frames) if f.record(LEGS)[0] in aa.DYING)
    end = next(n for n in range(kill, len(frames)) if frames[n].record(LEGS)[0] >= 56)
    window = _window(frames, kill, end)
    expected = []
    for before, now in _pairs(window):
        for index in (LEGS, TOP):
            graphic = now.record(index)[0]
            if graphic in range(48, 56) and graphic != before.record(index)[0]:
                expected += sparkle_waves(base, graphic)
            elif before.record(index)[0] == 55:
                expected += beep_a(_uvz(before.record(index)))
    out.append(_recording(
        window, expected, base, name="death", entry=SPARKLE_SOUND, title="Dying",
        what="#R$B5EE for each of his two records, every turn of the sparkle they "
             "become (#R$B39A, #R$B3A4): blips of two waves at pitches read from the "
             "ROM, from $1234 on, as many as the complement of the graphic's low five "
             "bits -- 15 at graphic 48, one fewer each turn, 8 at 55. Then, as graphic "
             "55 goes, a note for each record pitched by its U + V + Z (#R$B3B0 into "
             "#R$B654). Knight Lore's death sparkle.",
        how="the game running: the dying animation's run -- he walked into a spike; from "
            "the turn he was killed to the turn the records emptied."))
    last = next(n for n in range(end, len(frames)) if frames[n].record(LEGS)[0] in ba.LEGS)
    window = _window(frames, end + 1, last)
    expected = []
    for before, now in _pairs(window):
        for index in (LEGS, TOP):
            graphic = now.record(index)[0]
            if graphic in range(57, 64) and graphic == before.record(index)[0] + 1:
                expected += materialise_waves(graphic)
    out.append(_recording(
        window, expected, base, name="appear", entry=MATERIALISE_SOUND,
        title="Appearing, a life begun",
        what="#R$B604, for each of his two records, every other turn as #R$BC70 steps "
             "them through graphics 57 to 63: single waves stepping from 4 x (graphic "
             "AND 7) + 3 down to 1, the half-wave count four times the step -- a sweep "
             "that rises, longer at each frame, 7 waves at 57 to 31 at 63. Knight Lore's "
             "materialising sound. At the start of every life, and after every doorway.",
        how="the game running: the dying animation's run, from the turn after the "
            "records emptied to the turn he stood again."))
    return out


def _valves(snapshot: Path, base) -> list[dict]:
    out = []
    seating, activating = aa.run(snapshot, aa.chamber)
    frames = seating["before"]
    press = next(n for n, f in enumerate(frames) if aa.TAKE_KEY in f.keys)
    window = _window(frames, press, len(frames) - 1)
    expected = []
    for before, now in _pairs(window):
        expected += _legs_waves(before, now)
        valve = now.record(VALVE)
        if valve[0] in range(96, 100) and (before.record(VALVE)[0] == 0
                                           or valve[1:4] != before.record(VALVE)[1:4]):
            expected += beep_a(_uvz(valve))
        for index in range(VALVE + 2, aa.RECORD_COUNT):
            if before.record(index)[0] in range(104, 112) and _vanished(before, now, index):
                expected += beep_a(_uvz(before.record(index)))
    out.append(_recording(
        window, expected, base, name="valve", entry=0xAF79, title="A valve on its way",
        what="#R$AF79: every turn a valve moves -- and on the turn it is put down -- a "
             "note of six waves pitched by U + V + Z (#R$B654), so a valve steering itself "
             "a unit a turn towards its socket sounds a slowly falling scale. On the turn "
             "it was put down the beep of the press comes first, and the socket's sparkle "
             "vanishing with a note of its own (#R$AE33 into #R$B3BB); as the valve slid "
             "out from under him his own falling note joins in (#R$C296).",
        how="the game running: the valve seating animation's run -- from the press that "
            "put the valve down to the turn it came to rest on the socket."))

    passes = activating["passes"]
    valve = passes[-1].record(VALVE)
    expected = beep_a(_uvz(valve)) + sparkle_waves(base, valve[0]) * aa.ACTIVATE_PASSES
    edges, length = from_turns(passes)
    out.append({"name": "chamber", "entry": 0xAF79, "title": "A chamber activated",
                "what": "#R$AF79, as the valve sits on its socket: a note pitched by its "
                        "U + V + Z as it becomes a seated valve, then for each of the "
                        "sixteen passes over the colours #R$B5EE with the seated valve's "
                        f"graphic ({valve[0]}: {~valve[0] & 0x1F} blips of two waves from "
                        "the ROM at $1234) and a pause; the silences between are the "
                        "passes over the 768 attribute cells. The same sound for all 24 "
                        "chambers.",
                "how": "the game running: the chamber animation's run -- the turn the "
                       "valve activated the chamber, from its start to its end.",
                "edges": edges, "length": length, "turns": 1,
                "check": _check(base, edges, expected), "pitch": _pitch(edges)})

    # The extra life: an own run, one lying in his way.
    game = aa.started(snapshot)
    ba._put(1, ba.EXTRA_LIFE, aa.EMPTY_ROOM, 128, 150, aa.FLOOR)(game.memory)
    game.enter(aa.EMPTY_ROOM, 128, 110, facing=2)
    frames = [game.turn()]
    game.hold([aa.WALK_KEY])
    for _ in range(20):
        frames.append(game.turn())
        if frames[-1].record(VALVE)[0] == 64:
            break
    else:
        raise RuntimeError("the extra life was not taken")
    game.hold()
    frames += game.turns(3)
    expected = []
    for before, now in _pairs(frames):
        expected += _legs_waves(before, now)
        life_before, life = before.record(VALVE)[0], now.record(VALVE)[0]
        moved = before.record(VALVE)[1:4] != now.record(VALVE)[1:4]
        if life_before == ba.EXTRA_LIFE:
            # Touched: the beep; and either way, if he has pushed it, the note
            # of a thing that moves (#R$BEE0's fall into #R$B3BF).
            expected += (PLAIN if life == 64 else []) + (beep_a(_uvz(now.record(VALVE)))
                                                          if moved else [])
        elif life_before == 64 and life == 65:
            expected += sparkle_waves(base, 65)
        elif life_before == 65:
            expected += beep_a(_uvz(before.record(VALVE)))
    out.append(_recording(
        frames, expected, base, name="life", entry=0xBEE0, title="An extra life",
        what="#R$BEE0, as he touches it: #R$B6B1's beep, and the life becomes graphic 64, "
             "the start of a two-frame vanish: the next turn #R$B3A4 steps it to 65 with "
             "#R$B5EE's blips (30 of them, for graphic 65), and the turn after #R$B3B0 "
             "empties its place for good with a note pitched by its position. Walking "
             "into it he also pushed it, and a thing that moves makes a note of its own "
             "(#R$B3BF, pitched by U + V + Z) on that turn, after the beep.",
        how="the game running in the empty room: an extra life staged 40 units in front "
            "of him (as the build's session puts one, in place 1), walk held until he "
            "touched it, and three turns after."))
    return out


def _things(snapshot: Path, base) -> list[dict]:
    """The sounds of the things in the rooms, from the Animations page's runs."""
    out = []

    def graphic_records(frame, graphics) -> list[int]:
        return [i for i in range(TOP + 1, aa.RECORD_COUNT) if frame.record(i)[0] in graphics]

    # The lift: every turn it moves, a note by its Z before the move.
    frames = aa.run(snapshot, aa.lift)["turns"]
    lift = graphic_records(frames[0], {47})[0]
    expected = []
    for before, now in _pairs(frames):
        # The lift's routine plays its note on every turn it runs its move
        # (LIFT_MOVE): when he has landed on it that turn, or its last move was
        # stopped. So: every turn it moves, and every turn he comes down onto
        # it -- going into the turn not rising, and ending it standing on its
        # top. The turn after it passes the top he is still rising from the
        # lift's push, lands on nothing, and it is silent.
        record, legs = now.record(lift), now.record(LEGS)
        landed = (_signed(before.record(LEGS)[0x0B]) <= 0 and legs[3] == record[3] + record[6])
        moved = before.record(lift)[3] != record[3] or landed
        expected += _legs_waves(before, now) + (beep_a(before.record(lift)[3]) if moved else [])
    out.append(_recording(
        frames, expected, base, name="lift", entry=0xB31F, title="A lift ridden",
        what="#R$B31F: every turn it moves, #R$B63C pitched by its height as the turn "
             "began -- higher as it rises -- and a turn's silence at the top, where it "
             "turns round. On the way down he is falling onto it every "
             "turn, faster than two units a turn once gravity has had its way, and his own "
             "falling note (#R$C296) sounds before the lift's: two notes a turn, his "
             "falling as the lift's does.",
        how="the game running: the lift animation's run in room $23 -- up with him on it "
            "and down again."))

    # The ring of conveyors: a beep every turn something stands on one.
    frames = aa.run(snapshot, aa.conveyor)["turns"][1:12]
    expected = []
    for before, now in _pairs(frames):
        expected += _legs_waves(before, now) + HIGH
    out.append(_recording(
        frames, expected, base, name="conveyor", entry=0xB267, title="Riding a conveyor",
        what="#R$B6BB, 32 waves at 48, from the conveyor's routine (#R$B267) every turn "
             "something has landed on it -- and something standing on it lands on it "
             "every turn, gravity pulling it down and the conveyor stopping it -- so a "
             "ride is a steady buzz, a beep a turn. The clockwork mice use the same beep "
             "as they turn.",
        how="the game running: the conveyor animation's run in room $0D, ten turns of "
            "the ride."))

    # The dropping block: his falling note, and its grinding note.
    frames = aa.run(snapshot, aa.dropping)["turns"]
    block = next(i for i in graphic_records(frames[0], {44})
                 if frames[0].record(i)[3] != frames[-1].record(i)[3])
    expected = []
    for before, now in _pairs(frames):
        expected += _legs_waves(before, now)
        if now.record(block)[3] < before.record(block)[3]:
            expected += beep_a(now.record(block)[3])
    out.append(_recording(
        frames, expected, base, name="dropping", entry=0xB2B6,
        title="A dropping block ridden down",
        what="#R$B2B6: every turn it sinks, #R$B63C pitched by its new height; and with "
             "him on it, falling after it a unit a turn, his own falling note first "
             "(#R$C296) -- two notes a turn, falling together.",
        how="the game running: the dropping block animation's run in room $12, until "
            "the block had stopped."))

    # The collapsing block.
    frames = aa.run(snapshot, aa.collapsing)["turns"]
    block = graphic_records(frames[0], {45})
    block = next(i for i in block if frames[-1].record(i)[0] == 0)
    expected = []
    for before, now in _pairs(frames):
        expected += _legs_waves(before, now)
        if before.record(block)[0] == 45 and now.record(block)[0] == 65:
            expected += sparkle_waves(base, 65)
        elif before.record(block)[0] == 65:
            expected += beep_a(_uvz(before.record(block)))
    out.append(_recording(
        frames, expected, base, name="collapsing", entry=0xB28C,
        title="A collapsing block",
        what="#R$B28C: landed on, it becomes 64 and at once 65 with #R$B3A4's sparkle "
             "sound (#R$B5EE, 30 blips for graphic 65); the next turn #R$B3B0 makes it "
             "vanish with a note pitched by U + V + Z; and he falls, with his falling "
             "notes.",
        how="the game running: the collapsing block animation's run in room $15."))

    # The shuttling blocks: a note each, every turn.
    frames = aa.run(snapshot, aa.shuttles)["turns"]
    blocks = graphic_records(frames[0], (66, 67))
    expected = []
    for before, now in _pairs(frames):
        expected += _legs_waves(before, now)
        for block in blocks:
            record = before.record(block)
            expected += beep_a(record[1] if record[0] == 66 else record[2])
    out.append(_recording(
        frames, expected, base, name="shuttles", entry=0xB224, title="Shuttling blocks",
        what="#R$B224 (graphic 66) plays #R$B64A, pitched by its U, and #R$B21C (graphic "
             "67) #R$B64F, pitched by its V, every turn before it moves: with the two in "
             "room $61 out of step, two scales passing each other.",
        how="the game running: the shuttling blocks animation's run in room $61."))

    # The remote-controlled robot, and the fragile thing it breaks.
    anim = aa.run(snapshot, aa.remote)
    frames = anim["turns"][1:]
    robot, target, _ = anim["records"]
    expected = []
    for before, now in _pairs(frames):
        expected += _legs_waves(before, now) + warble_waves(base, WARBLE_COUNTS, before.turn)
        if before.record(target)[0] == 54:
            expected += sparkle_waves(base, 55)
        elif before.record(target)[0] == 55:
            expected += beep_a(_uvz(before.record(target)))
    out.append(_recording(
        frames, expected, base, name="remote", entry=WARBLE_SOUND,
        title="A remote-controlled robot at work",
        what="#R$B690 from #R$A9C7 every turn the robot in control has an order: single "
             "waves, as many as #R$B6A9 gives for the turn counter's low two bits (12, "
             "16, 20, 8 in turn), each at 64 plus the turn counter XOR the step count, "
             "AND 31 -- a warble that never repeats exactly. The fragile thing it breaks "
             "(#R$A9B1) goes with the death sparkle's last frame, 55 (#R$B5EE, 8 blips), "
             "and a note as it vanishes.",
        how="the game running: the remote-control animation's run in room $D9, him on a "
            "button, until the fragile thing was gone."))

    # The homing thing: the same warble from further along the table.
    frames = aa.run(snapshot, aa.slow_chaser)["turns"]
    dies = next(n for n, f in enumerate(frames) if f.record(LEGS)[0] in aa.DYING)
    frames = frames[:dies]
    expected = []
    for before, now in _pairs(frames):
        expected += _legs_waves(before, now) + warble_waves(base, WARBLE_COUNTS + 4,
                                                            before.turn)
    out.append(_recording(
        frames, expected, base, name="homing", entry=0xAA89, title="A homing thing",
        what="#R$AA89 plays #R$B690 every turn with the table four bytes on (#R$B6A9's "
             "last four: 24, 20, 16, 12 waves by the turn counter), so it warbles as the "
             "robots do but longer.",
        how="the game running: the homing thing animation's run in room $5E, until the "
            "turn before it reached him."))

    # The chaser: a note by its position every turn.
    frames = aa.run(snapshot, aa.chaser)["turns"]
    chaser = graphic_records(frames[0], range(76, 80))[0]
    expected = []
    for before, now in _pairs(frames):
        expected += _legs_waves(before, now) + beep_a(_uvz(now.record(chaser)))
    out.append(_recording(
        frames, expected, base, name="chaser", entry=0xB19C, title="A chaser",
        what="#R$B19C ends every turn in #R$B3BF: a note pitched by U + V + Z after its "
             "move, so its pitch follows it about and holds steady (or flickers between "
             "two) when it is stuck against him.",
        how="the game running: the chaser animation's run in room $9C."))

    # The clockwork mice: a beep as each turns.
    frames = aa.run(snapshot, aa.mice)["turns"]
    mice = graphic_records(frames[0], range(116, 120))
    expected = []
    for before, now in _pairs(frames):
        expected += _legs_waves(before, now)
        for mouse in mice:
            if before.record(mouse)[7] & aa.MIRRORED != now.record(mouse)[7] & aa.MIRRORED:
                expected += HIGH
    out.append(_recording(
        frames, expected, base, name="mice", entry=0xAAA1, title="Clockwork mice",
        what="#R$AAA1 plays #R$B6BB, 32 waves at 48, each time a mouse turns -- when it "
             "is stopped, blocked or has run its count -- and nothing while it runs.",
        how="the game running: the clockwork mice animation's run in room $4D."))

    # The two-part creatures: a thud as they turn.
    for key, make, graphics, title, what in (
            ("wanderer", aa.wanderer, (94, 95), "A wanderer turning",
             "#R$B06B plays #R$B619 each time it is stopped and turns a quarter: three "
             "waves at each of the ROM's first four bytes with the top two bits set -- "
             "low, dull notes, a thud. Knight Lore's thud."),
            ("pacer", aa.pacer, (86, 87), "A pacer turning round",
             "#R$B110 plays the same thud (#R$B619) each time it is stopped and turns "
             "round.")):
        frames = aa.run(snapshot, make)["turns"]
        upper = graphic_records(frames[0], graphics)[0]
        expected = []
        for before, now in _pairs(frames):
            expected += _legs_waves(before, now)
            if _facing(before.record(upper)) != _facing(now.record(upper)):
                expected += thud_waves(base)
        out.append(_recording(
            frames, expected, base, name=key, entry=THUD_SOUND, title=title, what=what,
            how=f"the game running: the {key} animation's run."))

    # The leapers: a note by the height of each in the air.
    frames = aa.run(snapshot, aa.leapers)["turns"]
    leapers = graphic_records(frames[0], {130})
    expected = []
    for before, now in _pairs(frames):
        expected += _legs_waves(before, now)
        for leaper in leapers:
            if before.record(leaper)[0x10] & 1 or now.record(leaper)[0x10] & 1:
                expected += beep_a(now.record(leaper)[3])
    out.append(_recording(
        frames, expected, base, name="leapers", entry=0xA8F9, title="Leapers",
        what="#R$A8F9: every turn a leaper is in the air -- and the turn it lands -- "
             "#R$B63C pitched by its height after the move: up and down the scale, one "
             "leaper at a time.",
        how="the game running: the leapers animation's run in room $97."))

    # Things from the ceiling: falling notes and a crash.
    frames = aa.run(snapshot, aa.ceiling)["turns"]
    things = graphic_records(frames[0], {73})
    expected = []
    for before, now in _pairs(frames):
        expected += _legs_waves(before, now)
        for thing in things:
            if before.record(thing)[0x0D] & 0x04:
                if now.record(thing)[0x0C] & 0x04:
                    expected.append(CRASH)
                else:
                    expected += beep_a(now.record(thing)[3])
    out.append(_recording(
        frames, expected, base, name="ceiling", entry=0xAD13,
        title="A thing dropping from the ceiling",
        what="#R$AD13: every turn it falls, #R$B63C pitched by its height, lower and "
             "lower; and as it lands #R$AD54 plays #R$B676, sixteen blips of two waves at "
             "pitches read from the ROM at an address made of the random number and the "
             "turn counter -- a crash no two landings share. Knight Lore's crash.",
        how="the game running: the ceiling animation's run in room $58, two of them "
            "falling one after the other."))
    return out


def _screens(snapshot: Path, base) -> list[dict]:
    """The menu's beep and the scenes after a game."""
    out = []

    # The menu: a beep each time the control method changes. The tune the
    # menu plays first leaves the speaker on, and the first key (2) stops it,
    # so that key's beep is left out: from the second key on.
    frames = aa.run(snapshot, aa.menu)["turns"]
    second = next(n for n, f in enumerate(frames) if f.keys == {aa.MENU_KEYS[1]})
    window = frames[second - 1:]
    changes = sum(1 for before, now in _pairs(window)
                  if before.variable(aa.CONTROL) != now.variable(aa.CONTROL))
    expected = PLAIN * changes
    out.append(_recording(
        window, expected, base, name="menu", entry=PLAIN_BEEP,
        title="Choosing on the menu",
        what="#R$BA7E plays #R$B6B1 whenever a pass round its loop leaves CONTROL changed "
             "-- a control method chosen, or directional control turned on or off with "
             "5.",
        how="the game running: the menu animation's run, from the second key (3) on: "
            "3, 4, 5 and 1 pressed in turn. (The first key, 2, stops the menu tune, "
            "which leaves the speaker on, so its beep's first wave cannot be told from "
            "the tune's last.)"))

    # The scene after a lost game.
    anim = aa.run(snapshot, aa.game_over)
    scene = [f for f in anim["turns"] if getattr(f, "phase", "") == "the scene"
             and not f.left]
    start = next(n for n, f in enumerate(scene) if f.edges and not f.speaker and n > 0
                 and any(g.edges for g in scene[:n]))
    window = scene[start - 1:]
    expected = []
    for before, now in _pairs(window):
        for index in range(aa.RECORD_COUNT):
            graphic = before.record(index)[0]
            if graphic in (81, 82, 83):
                if not before.record(index)[0x11] & 1 and now.record(index)[0x11] & 1:
                    expected += thud_waves(base)
                if not before.record(index)[0x11] & 0x80 and now.record(index)[0x11] & 0x80:
                    expected.append(CRASH)
            elif graphic == 80 and not before.turn & 7:
                expected += PLAIN
    out.append(_recording(
        window, expected, base, name="scene_lost", entry=0xAB61,
        title="Re-programming",
        what="The scene after a lost game: the sparks over the robot's head (#R$ABF5) "
             "beep (#R$B6B1) every eighth turn as they flash, sixteen times; then each "
             "tool (#R$AB61) thuds (#R$B619) as it starts its swing and crashes (#R$B676) "
             "as it strikes, fifteen swings in all.",
        how="the game running: the game-over animation's run, the scene from its "
            "second sound (the game-over tune before it leaves the speaker on) to the "
            "last turn before the menu. The scene has no wait between turns, so the "
            "sounds come closer together than they would in play."))

    # The oiled robot.
    anim = aa.run(snapshot, aa.win)
    scene = [f for f in anim["turns"] if getattr(f, "phase", "") == "the scene"
             and not f.left]
    moving = [n for n, f in enumerate(scene) if f.edges]
    window = scene[moving[1] - 1:moving[-1] + 1]
    expected = []
    for before, now in _pairs(window):
        robot = next((i for i in range(aa.RECORD_COUNT) if now.record(i)[0] == 92), None)
        if robot is not None and now.record(robot)[0x1B] != before.record(robot)[0x1B]:
            expected += beep_a(now.record(robot)[0x1B])
    out.append(_recording(
        window, expected, base, name="scene_won", entry=0xA971, title="The robot oiled",
        what="#R$A971, the scene after a won game: every turn the robot moves, down into "
             "the can of oil and up out of it, #R$B63F pitched by its height on the screen "
             "(+1B, in pixels): falling, a pause at the bottom, rising.",
        how="the game running: the win animation's run, the scene from the robot's "
            "second move (the tunes before it leave the speaker on) to its last."))
    return out


def _never(base, quiet_turn: int) -> list[dict]:
    """Sound code the game never runs, called to hear what it would have made."""
    out = []
    record = 0x6000                  # a scratch record, in the game's unused space
    calls, expected = [], []
    for graphic in range(4):
        calls.append(call(base, TRANSFORM_SOUND, {"IX": record}, {record: graphic}))
        count = ((_rotl(graphic, 3) & 0x18) + 0x10)
        expected += [((c ^ 0x55) + c) & 0xFF for c in range(count, 0, -1)]
    edges, length = in_a_row(calls, 4 * quiet_turn)
    out.append({"name": "transform", "entry": TRANSFORM_SOUND,
                "title": "Knight Lore's werewolf, never played",
                "what": "#R$B65F, which nothing calls: Knight Lore's sound for Sabreman "
                        "changing into the werewolf and back (<a href=\"../knightlore/"
                        "Sounds.html#transform\">Knight Lore's sounds</a>), left in: 16, "
                        "24, 32 or 40 single waves by the low two bits of the graphic, each "
                        "at (C XOR $55) + C for C counting down -- a warble. Pentagram's "
                        "jump is the same routine with $A5.",
                "how": "four calls with IX on a record of graphic 0, 1, 2 and 3 -- the "
                       "four lengths -- four quiet turns apart, as Knight Lore played it "
                       "every fourth frame.",
                "edges": edges, "length": length, "never": True,
                "check": _check(base, edges, expected), "pitch": _pitch(edges)})

    calls, expected = [], []
    for turns in range(8):
        calls.append(call(base, FRAGMENT, pokes={TURNS: turns, TURNS + 1: 0}))
        expected += [base[FRAGMENT_PITCHES + turns]] * 4
    edges, length = in_a_row(calls, quiet_turn)
    same, comparison = fragment_comparison(base)
    out.append({"name": "fragment", "entry": NOTES,
                "title": ("Knight Lore's movable-block blip, never played" if same
                          else "A fragment after the notes, never played"),
                "what": "The 18 bytes of code at $B5D4, after the last row of #R$B51D, "
                        "which no instruction or table reaches: four waves (BEEP) at one "
                        "of the eight half-wave counts after it, picked by the turn "
                        "counter's low three bits. "
                        + ("It is Knight Lore's blip for its movable block, which that "
                           "game's block plays every frame, a quiet buzz under everything "
                           "(<a href=\"../knightlore/Sounds.html#movable_block\">Knight "
                           "Lore's sounds</a>); Pentagram keeps a variant of it, gated on a "
                           "flag and also never reached "
                           "(<a href=\"../pentagram/Sounds.html#blip\">Pentagram's sounds</a>)."
                           if same else "")
                        + comparison,
                "how": "eight calls of $B5D4 with the turn counter 0 to 7, a quiet turn "
                       "apart: what one object calling it every turn would make.",
                "edges": edges, "length": length, "never": True,
                "check": _check(base, edges, expected), "pitch": _pitch(edges)})

    calls, expected = [], []
    for turns in range(8):
        pokes = {record: 11, record + 1: 128, record + 2: 128, record + 3: 64,
                 TURNS: turns, TURNS + 1: 0}
        calls.append(call(base, LOWER_HALF_PAST_TEST, {"IX": record}, pokes))
        expected += footstep_waves(bytes([11, 128, 128, 64]), ~turns & 0xFF, 0x80)
    edges, length = in_a_row(calls, quiet_turn)
    out.append({"name": "lower_half", "entry": LOWER_HALF_STEP,
                "title": "A creature's footstep, never heard",
                "what": "#R$B6C0, which the lower half of a two-part creature calls every "
                        "turn (#R$B055): it plays only for an even graphic, and the lower "
                        "half is always graphic 11, so it never sounds. Past the test it "
                        "is the robot's footstep (#R$B6CE) at a pitch of 128, the turn "
                        "counter complemented: Knight Lore's footstep for its guards and "
                        "wizard, whose graphics change as they walk.",
                "how": "eight calls of $B6C6, the code after the test, with IX on a record "
                       "at U 128, V 128, Z 64 and the turn counter 0 to 7, a quiet turn "
                       "apart.",
                "edges": edges, "length": length, "never": True,
                "check": _check(base, edges, expected), "pitch": _pitch(edges)})
    return out


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
    lines += [f"<p>{aa.link(p, entries)}</p>" for p in paragraphs]
    lines += [f"<p>{stats}.</p>",
              f'<audio controls preload="none" src="{file}"><a href="{file}">'
              f"{sound['name']}.wav</a></audio>",
              "</div>"]
    return lines


def _notes_table(rows, tunes) -> list[str]:
    used = {}
    for sound in tunes:
        for row, _ in sound["tune"]:
            used.setdefault(row, set()).add(sound["title"])
    lines = ['<table class="kl-table">',
             "<tr><th>Row</th><th>Note</th><th>B</th><th>C</th><th>Waves a unit</th>"
             "<th>Pitch</th><th>A unit</th><th>Played in</th></tr>"]
    for row in sorted(used):
        b, c, per_unit = rows[row]
        period = 2 * note_d(b, c) + NOTE_OFF + NOTE_ON
        lines.append(f"<tr><td>{row}</td><td>{note_name(row)}</td><td>{b}</td><td>{c}</td>"
                     f"<td>{per_unit}</td><td>{_hz(period):.1f}&nbsp;Hz</td>"
                     f"<td>{per_unit * period / TSTATES_PER_SECOND:.3f}&nbsp;s</td>"
                     f"<td>{_esc(', '.join(sorted(used[row])))}</td></tr>")
    lines.append("</table>")
    return lines


GROUPS = [
    ("The robot", ["footsteps", "turn", "jump", "pickup", "pause", "death", "appear"]),
    ("Valves and chambers", ["valve", "chamber", "life"]),
    ("Things in the rooms", ["lift", "conveyor", "dropping", "collapsing", "shuttles",
                             "remote", "homing", "chaser", "mice", "wanderer", "pacer",
                             "leapers", "ceiling"]),
    ("The menu and the scenes after a game", ["menu", "scene_lost", "scene_won"]),
]


def _section(tunes, sounds, never, quiet_turn, rows, comparison, matches, transform,
             entries) -> str:
    by_name = {sound["name"]: sound for sound in sounds}
    lines = [
        '<div class="kl-list">',
        "<p>A 48K Spectrum has one bit of sound hardware, bit 4 of port $FE, and Alien 8 "
        "makes every sound by setting and clearing it with the processor counting in "
        "between, the border kept black. While a sound plays nothing else happens: the "
        "game stands still for a tune, and every beep lengthens the turn it is in. There "
        "are two players. The tunes go through #R$B4C5, a note at a time; everything else "
        "is waves from #R$B702, which turns the speaker on for B turns of a 13 T-state "
        "loop and off for as long, and BEEP ($B6FB, the end of #R$B6CE), which repeats "
        "it C times. Most of the "
        "effects are Knight Lore's routines, some of them with new callers; a few are "
        "Alien 8's own (the robots' warble, #R$B690).</p>",
        "<p>The tune player and its note table are Knight Lore's, and Pentagram's (see "
        '<a href="../knightlore/Sounds.html">Knight Lore\'s sounds</a> and '
        '<a href="../pentagram/Sounds.html">Pentagram\'s</a>). A tune is a string of '
        "note bytes ended by $FF: the low six bits index #R$B51D, five octaves of "
        "semitones from G#1 to G6 with 0 a rest, and the top two bits are the length less "
        "one, one to four units of about 0.155 s. " + comparison + "</p>",
        "<p>Every recording here is the game's own code running in SkoolKit's simulator, "
        "each change of the speaker bit logged to the T-state and rendered at 44100 Hz; "
        "nothing is synthesised. Most effects were recorded from the game playing -- the "
        "very runs the Animations page shows -- so each is heard as it is in the game, "
        "with whatever else sounded in those turns, and each is checked wave by wave "
        "against what the code and the objects' records say it should be: every wave's "
        "half-wave count, and every off half-wave inside a sound against the instruction "
        "timings of the loop that timed it. The simulator has no memory contention, so "
        "all of this runs a touch faster, and a touch higher, than on a real Spectrum, "
        "where the ULA holds up the OUTs. "
        f"A quiet turn (the empty room, ${aa.EMPTY_ROOM:02X}, nothing moving) lasts "
        f"{quiet_turn:,} T-states, {quiet_turn / TSTATES_PER_SECOND * 1000:.0f} ms; the "
        "calls that stand for a sound made over several turns are spaced by that.</p>",
        "<h3>Tunes</h3>",
    ]
    for sound in tunes:
        if matches.get(sound["name"]):
            sound = dict(sound)
            sound["what"] += (" The same notes as " + " and ".join(matches[sound["name"]])
                              + " (compared at this build).")
        lines += _item(sound, rows, entries)
    lines.append("<p>The notes the tunes use, worked out from #R$B51D and #R$B4C5's "
                 "timing: B and C time each half-wave, and a unit is that many waves. "
                 "The table has 61 rows; these are the ones any of the five tunes plays.</p>")
    lines += _notes_table(rows, tunes)
    for heading, names in GROUPS:
        lines.append(f"<h3>{_esc(heading)}</h3>")
        for name in names:
            lines += _item(by_name[name], rows, entries)
    lines.append("<h3>Never heard in the game</h3>")
    lines.append("<p>Sound code the game has but never runs, recorded by calling it to "
                 "hear what it would have made." + transform + "</p>")
    for sound in never:
        lines += _item(sound, rows, entries)
    lines.append("</div>")
    body = "\n".join(lines)
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
    log("Recording Alien 8's sounds...")
    quiet_turn = _quiet_turn(snapshot)
    tunes = _tunes(base)
    sounds = _robot(snapshot, base) + _valves(snapshot, base) + _things(snapshot, base)
    sounds += _screens(snapshot, base)
    never = _never(base, quiet_turn)
    for sound in tunes + sounds + never:
        if not sound["edges"]:
            raise RuntimeError(f"{sound['name']}: no sound was made")
        _write_wav(audio / f"{sound['name']}.wav", sound["edges"], sound["length"])
    log(f"  {len(tunes) + len(sounds) + len(never)} sounds written to {audio}")
    comparison, matches = comparisons(base)
    return {"Sounds": _section(tunes, sounds, never, quiet_turn, rows, comparison, matches,
                               transform_comparison(base), aa.skool_entries())}
