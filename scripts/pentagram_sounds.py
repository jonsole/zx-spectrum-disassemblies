"""Pentagram's sounds, recorded from the game's own code at build time.

build_pentagram.py --html calls build(), which writes a WAV of every tune
and sound effect into the HTML directory's audio/ folder and returns the
Sounds section. Nothing here is committed output: the sounds are the game's.

A 48K Spectrum has one bit of sound hardware, bit 4 of port $FE, and every
noise Pentagram makes is its code setting and clearing that bit with the
processor counting in between. So a sound is recorded by running the code
that makes it in SkoolKit's simulator with a tracer that notes the T-state of
every OUT to port $FE that changes bit 4 (pentagram_animations' GameTracer);
the gaps between those edges are the waveform, which SkoolKit's audio writer
renders to a WAV at 44100 Hz. Nothing is synthesised: every edge in every
file is an OUT the game executed.

Two kinds of recording:

- A call. The routine that makes the sound, called on a machine of its own
  built from the snapshot with the ROM in place, the registers and variables
  it reads set to the values given, and a return address the run stops at.
  A fresh machine for each call, so that nothing is inherited from the last.
  Effects the game plays a turn at a time are several calls in a row with a
  quiet turn's silence between them.
- A turn-by-turn run. The game itself, started and put into a room the way
  pentagram_animations stages its scenes (the player template and the
  game's own restart), run a turn at a time, the edges kept with the real
  turns between them. The room-entry and pick-up sequences, the footsteps,
  a bolt's firing and its puff, and a pause are recorded this way.

Each recording is checked against what the code says it should be: the
number of waves, and the length of every half-wave from the instruction
timings of the loop that made it (see _check and the constants below). The
machine is uncontended, so everything is a little faster, and higher, than
on a real Spectrum, where the ULA holds up the OUTs; the loops themselves run
above $8000, in uncontended memory, so the difference is small.
"""
from __future__ import annotations

import html
from pathlib import Path

import build_pentagram as bp
import pentagram_animations as pa

TSTATES_PER_SECOND = 3_500_000
CALL_STACK = 0x5D00         # below the game's own stack at $5E00
STOP = 0x5E00               # the return address: the run stops there
CALL_LIMIT = 60 * TSTATES_PER_SECOND

# The sound code (see the entries).
BLIP_BY_TURN = 0xD56C
BLIP_PITCHES = 0xD587
PAUSE_BEEP = 0xD5D7
JUMP_SOUND = 0xD5E4
EFFECT_NOTE = 0xD5F2
EFFECTS = 0xD60D
FIRE_SOUND = 0xD629
FOOTSTEP = 0xD635
PUFF_SOUND = 0xD64E
BEEP_BY_GRAPHIC = 0xD665
BEEP_BY_SPARE = 0xD674      # BEEP_BY_GRAPHIC's second entry, after its data byte
SPARE_PITCH = 0xD673
BEEP = 0xD67B
CLICK = 0xD682
PLAY_TUNE_ONCE = 0xD69C
PLAY_TUNE = 0xD6B5
PLAY_NOTE = 0xD6C0
NOTES = 0xD718
NOTE_ROWS = 61
TUNE_MENU, TUNE_UNUSED, TUNE_START = 0xD7CF, 0xD824, 0xD833
TUNE_QUEST, TUNE_OVER, TUNE_WON = 0xD847, 0xD853, 0xD86F

TUNE_HEARD = 0xA747
SOUND_COUNT = 0xA749        # notes left, then which effect
TURNS = 0xA715
RANDOM = 0xA70D

# Knight Lore's note player and note table, to compare with (build_knightlore
# writes its snapshot here).
KNIGHT_LORE = bp.PROJECT_ROOT / "game_disassembly" / "knightlore" / "knightlore.sna"
KL_PLAY_NOTE, KL_NOTES = 0xB2DA, 0xB332
PLAY_NOTE_LENGTH = NOTES - PLAY_NOTE            # 88 bytes
PLAY_NOTE_ADDRESSES = (0xD6C9, 0xD6CC)          # CALL ADD_HL_A and LD BC,NOTES

# Half-waves, in T-states, from the instructions of the loops that make them.
# CLICK ($D682) turns the speaker on and waits B turns of DJNZ (13 T-states
# each, 8 for the last), then LD B,A, XOR A and the OUT that turns it off:
# every on half-wave any effect makes is 13B + 18 (B = 0 counts 256).
CLICK_ON = 18
# The off half-wave depends on where CLICK returns to: its own DJNZ and
# LD B,A and RET, then the caller's loop, then CLICK's LD A,$10 and OUT --
# BEEP's DEC C, JR NZ and CALL make it 13B + 64 between the waves of a beep.
BEEP_OFF = 64
# JUMP_SOUND's loop (DEC C, JR NZ, LD A,C, XOR, ADD, LD B,A, CALL) makes it
# 13B + 83, and FIRE_SOUND's (the same with SUB B for XOR and ADD) 13B + 76.
JUMP_OFF, FIRE_OFF = 83, 76
# PLAY_NOTE ($D6C0) times each half with a DJNZ loop run C times over (the
# first pass B turns, the rest 256), which with its DEC C and JR NZ comes to
# D = 13B + 3339C - 3333; then off is D + 39 (POP, PUSH, LD, OUT) and on is
# D + 62 (POP, DEC HL, LD, OR, JR, PUSH, XOR, OUT).
NOTE_OFF, NOTE_ON = 39, 62
NOTE_UNIT_SECONDS = 0.155

NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


def _esc(text: str) -> str:
    return html.escape(text, quote=False)


def _hz(tstates: float) -> float:
    return TSTATES_PER_SECOND / tstates


def _count(value: int) -> int:
    """A DJNZ or DEC counter's value as a number of turns: 0 is 256."""
    return value or 256


def note_name(row: int) -> str:
    """The note table's scale: row 1 is G#1 and row 38 A4."""
    midi = row + 31
    return f"{NAMES[midi % 12]}{midi // 12 - 1}"


# --------------------------------------------------------------------------
# Recording.
# --------------------------------------------------------------------------

def _base(snapshot: Path) -> list:
    from skoolkit import read_bin_file

    memory = list(bp.game_memory(snapshot))
    memory[:0x4000] = read_bin_file(str(bp.ROM))
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
    tracer = pa._tracer_class()(simulator)
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
    """The B of every wave CLICK made, from its on half-wave."""
    on, _ = halves(edges)
    return [(t - CLICK_ON) // 13 if (t - CLICK_ON) % 13 == 0 else -t for t in on]


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


TUNES = [
    ("tune_start", TUNE_START, PLAY_TUNE, "The start of a game",
     "Played in full by #R$AF87 once 0 has been pressed at the menu, before the "
     "quest is set out and the first room is built."),
    ("tune_menu", TUNE_MENU, PLAY_TUNE_ONCE, "The menu",
     "Played by #R$D69C under the menu (#R$BB74), the first time the menu is shown "
     "after the game is loaded or a game ends; any key stops it between two notes, "
     "and it does not play again until the next game is over (TUNE_HEARD)."),
    ("tune_quest", TUNE_QUEST, PLAY_TUNE, "A quest item done",
     "Played in full by #R$D0AC when the bucket has flown over a quest item: the "
     "game stands still while it plays, and then the bucket turns into a puff and "
     "the item into its finished form (#R$CF68)."),
    ("tune_won", TUNE_WON, PLAY_TUNE, "The quest complete",
     "Played in full by #R$C302 under the congratulations, when the fifth "
     "collectable reaches its place on the pentagram."),
    ("tune_over", TUNE_OVER, PLAY_TUNE, "Game over",
     "Played in full by GAME_OVER (in #R$C302) under the percentage, after the "
     "last life is lost and after the win; then about four seconds' wait, and the "
     "menu."),
    ("tune_unused", TUNE_UNUSED, PLAY_TUNE, "A tune nothing plays",
     "At #R$D824, in the tunes' format among the others, and no code or table "
     "refers to its address: never played in the game. Recorded by handing it to "
     "the tune player all the same."),
]


def _tunes(base) -> list[dict]:
    rows = note_rows(base)
    out = []
    for name, tune, player, title, what in TUNES:
        pokes = {TUNE_HEARD: 0} if player == PLAY_TUNE_ONCE else None
        edges, length = call(base, player, {"DE": tune}, pokes)
        notes = tune_notes(base, tune)
        how = (f"#R${player:04X} called with DE = #R${tune:04X}"
               + (", TUNE_HEARD clear and no key down, so it plays to the end, as it "
                  "does for a player who waits" if player == PLAY_TUNE_ONCE else "")
               + ".")
        out.append({"name": name, "entry": tune, "title": title, "what": what,
                    "how": how, "edges": edges, "length": length, "tune": notes,
                    "check": _tune_check(edges, notes, rows), "never": tune == TUNE_UNUSED})
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
    # The first wave's off half-wave has no edge to start it (the speaker was
    # off already), so the off half-waves measured are the second wave's on.
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
            "#R$D6C0's loops imply")


def knight_lore_comparison(memory) -> str:
    """The note player and table against Knight Lore's, if its snapshot has
    been built alongside."""
    if not KNIGHT_LORE.exists():
        return ("Compared with Knight Lore's snapshot when this disassembly was made: "
                "#R$D6C0 is Knight Lore's play_note byte for byte except for the two "
                "addresses in it, and #R$D718 is its note table exactly.")
    from skoolkit.snapshot import Snapshot

    kl = Snapshot.get(str(KNIGHT_LORE)).memory
    player = [PLAY_NOTE + i for i in range(PLAY_NOTE_LENGTH)
              if kl[KL_PLAY_NOTE + i] != memory[PLAY_NOTE + i]]
    table = kl[KL_NOTES:KL_NOTES + 3 * NOTE_ROWS] == list(memory[NOTES:NOTES + 3 * NOTE_ROWS])
    operands = {a for a in PLAY_NOTE_ADDRESSES} | {a + 1 for a in PLAY_NOTE_ADDRESSES}
    return (f"Checked at this build against Knight Lore's snapshot: of the "
            f"{PLAY_NOTE_LENGTH} bytes of #R$D6C0, the {len(player)} that differ from "
            f"Knight Lore's play_note ($B2DA) are "
            + ("exactly the two addresses in it, the CALL to #R$B519 and the LD of "
               "#R$D718" if set(player) == operands else "NOT only its two addresses")
            + "; and the 183 bytes of #R$D718 are Knight Lore's note table ($B332) "
            + ("exactly." if table else "-- NOT exactly."))


# --------------------------------------------------------------------------
# The effects.
# --------------------------------------------------------------------------

def effect_notes(memory, effect: int, count: int) -> list[int]:
    """The half-wave counts EFFECT_NOTE plays for `count` notes of an
    effect: the byte at the effect's address plus the count, the count
    going down."""
    address = memory[EFFECTS + 2 * effect] | memory[EFFECTS + 2 * effect + 1] << 8
    return [memory[address + n] for n in range(count, 0, -1)]


# Effects 2 and 3 are never started, so nothing says how many notes each
# has. Each effect's address is the last byte of the one before's notes (0's
# last byte, $D619, is 1's address; 1's last, $D61E, is 2's): so 2 would run
# to 3's address, seven notes, and 3 to the code at #R$D629, three.
UNSTARTED = {2: 7, 3: 3}


# An off half-wave longer than this is a silence between bursts (a turn, or
# the next call), not part of a burst.
IN_A_BURST = 13 * 256 + 200


def _check_clicks(edges, expected: list[int], off: int | None = BEEP_OFF,
                  what: str = "waves") -> str:
    """Every on half-wave against CLICK's 13B + 18, for the B's expected; and
    every off half-wave inside a burst against 13B + `off`, the loop that
    called CLICK."""
    expected = [_count(b) for b in expected]
    measured = clicks(edges)
    ok = measured == expected
    text = (f"{len(measured)} {what}, {len(edges)} edges (the code implies "
            f"{len(expected)} and {2 * len(expected)}); every on half-wave "
            + ("was" if ok else "was NOT")
            + " 13B + 18 T-states for the B the code gives it")
    if not ok:
        text += f" (measured {measured[:24]}..., expected {expected[:24]}...)"
    if off is not None:
        _, gaps = halves(edges)
        inside = [(gap, b) for gap, b in zip(gaps, measured) if gap < IN_A_BURST]
        good = all(gap == 13 * b + off for gap, b in inside)
        text += (", and every off half-wave between two waves of a burst "
                 + ("was" if good else "was NOT") + f" 13B + {off}")
    return text


def _pitches(values: list[int]) -> str:
    """Half-wave counts as the tones #R$D67B plays them (26B + 82 a wave)."""
    tones = sorted({_hz(26 * _count(b) + CLICK_ON + BEEP_OFF) for b in values})
    if len(tones) == 1:
        return f"{tones[0]:.0f} Hz"
    return f"{tones[0]:.0f} to {tones[-1]:.0f} Hz"


def _calls(base, quiet_turn: int) -> list[dict]:
    out = []

    # The jump: sixteen single waves, B = (C XOR $A5) + C for C = 16 down.
    edges, length = call(base, JUMP_SOUND)
    expected = [((c ^ 0xA5) + c) & 0xFF for c in range(16, 0, -1)]
    out.append({"name": "jump", "entry": JUMP_SOUND, "title": "A jump",
                "what": "#R$D5E4, from #R$C56C as he leaves the ground: sixteen single "
                        "waves at a half-wave count of (C XOR $A5) + C for C = 16 down to "
                        "1, so the pitch jumps about rather than sweeping -- Knight Lore's "
                        "werewolf warble with $A5 in place of $55.",
                "how": "one call; it sets its own pitches.",
                "edges": edges, "length": length,
                "check": _check_clicks(edges, expected, JUMP_OFF),
                "pitch": _single_waves(expected, JUMP_OFF)})

    # A bolt fired: 32 single waves from B = 0, which FIRE's LDIR leaves.
    edges, length = call(base, FIRE_SOUND, {"B": 0})
    expected, b = [], 0
    for c in range(32, 0, -1):
        b = (c - b) & 0xFF
        expected.append(b)
    out.append({"name": "fire", "entry": FIRE_SOUND, "title": "A bolt fired",
                "what": "#R$D629, from #R$C126 when a bolt sets off: 32 single waves, "
                        "each half-wave count the step count less the one before. "
                        "#R$C126 comes straight from an LDIR that leaves B at 0, so the "
                        "counts go 32, 255, 31, 254 ... a high note and a low one "
                        "interleaved, both falling.",
                "how": "one call with B = 0, as the LDIR leaves it.",
                "edges": edges, "length": length,
                "check": _check_clicks(edges, expected, FIRE_OFF),
                "pitch": _single_waves(expected, FIRE_OFF)})

    # The unstarted effects 2 and 3, a note a quiet turn apart.
    for effect, count in UNSTARTED.items():
        calls = [call(base, EFFECT_NOTE, pokes={SOUND_COUNT: n, SOUND_COUNT + 1: effect})
                 for n in range(count, 0, -1)]
        edges, length = in_a_row(calls, quiet_turn)
        expected = [b for b in effect_notes(base, effect, count) for _ in range(12)]
        out.append({"name": f"effect{effect}", "entry": EFFECT_NOTE,
                    "title": f"Effect {effect}, never started",
                    "what": f"The notes #R$D5F2 would play for effect {effect}, whose "
                            "address is in #R$D60D and whose notes are there after "
                            "effect 1's; but the only code that starts an effect sets 0 "
                            "(#R$B00C) or 1 (#R$BF79). How many notes it has is not "
                            f"written anywhere; {count} is what fits before "
                            + ("effect 3's address" if effect == 2 else "the code at #R$D629")
                            + ", as each effect's address is the last note of the one "
                            "before.",
                    "how": f"{count} calls of #R$D5F2 with SOUND_COUNT set to {count}, "
                           f"{count - 1} ... 1 and effect {effect}, as the game would "
                           f"leave it turn by turn, a quiet turn apart ({quiet_turn:,} "
                           "T-states, measured below).",
                    "edges": edges, "length": length, "never": True,
                    "check": _check_clicks(edges, expected),
                    "pitch": _pitches(expected)})

    # Never reached: the blip by the turn counter, sixteen turns of it.
    pitches = [base[BLIP_PITCHES + t] for t in range(16)]
    calls = [call(base, BLIP_BY_TURN, {"IX": pa.PLAYER},
                  {pa.PLAYER + 7: 0x02, TURNS: t, TURNS + 1: 0}) for t in range(16)]
    edges, length = in_a_row(calls, quiet_turn)
    out.append({"name": "blip", "entry": BLIP_BY_TURN, "title": "A blip, never reached",
                "what": "#R$D56C: twelve waves at one of sixteen pitches from #R$D587, "
                        "picked by the turn counter, if bit 1 of the object's flags was "
                        "set. No code or table holds its address; it is Knight Lore's "
                        "movable-block buzz, gated on a flag, left behind.",
                "how": "16 calls with IX on a record whose flags have bit 1 set and the "
                       "turn counter 0 to 15, a quiet turn apart: what one object calling "
                       "it every turn would make.",
                "edges": edges, "length": length, "never": True,
                "check": _check_clicks(edges, [b for b in pitches for _ in range(12)]),
                "pitch": _pitches(pitches)})

    # Never reached: the two beeps at $D665.
    calls, expected = [], []
    for graphic in range(8):
        calls.append(call(base, BEEP_BY_GRAPHIC, {"IX": pa.PLAYER}, {pa.PLAYER: graphic}))
        expected += [((~graphic & 7) << 5)] * 6
    calls.append(call(base, BEEP_BY_SPARE))
    expected += [~base[SPARE_PITCH] & 0xFF] * 8
    edges, length = in_a_row(calls, quiet_turn)
    out.append({"name": "beeps", "entry": BEEP_BY_GRAPHIC, "title": "Two beeps, never reached",
                "what": "The code at #R$D665, which nothing reaches (the listing keeps it "
                        "as data): six waves pitched by the low three bits of the object's "
                        "graphic (its complement, moved to the top three bits), and, "
                        "entered after its data byte, eight waves pitched by the complement "
                        "of that byte, which is 0 on the tape and written by nothing.",
                "how": "the first part called with IX on a record of graphic 0, 1 ... 7 "
                       "-- the eight pitches it can make -- then the second part once, a "
                       "quiet turn apart.",
                "edges": edges, "length": length, "never": True,
                "check": _check_clicks(edges, expected),
                "pitch": _pitches(expected)})
    return out


def _single_waves(values: list[int], off: int) -> str:
    """The pitches of waves made one CLICK at a time by a loop whose off
    half-wave is 13B + `off`."""
    tones = sorted(_hz(26 * _count(b) + CLICK_ON + off) for b in values)
    return f"{tones[0]:.0f} to {tones[-1]:.0f} Hz"


# --------------------------------------------------------------------------
# The game, running.
# --------------------------------------------------------------------------

QUIET_TURNS = 12                 # standing still in the empty room
PICK_UP = 4                      # a collectable's quest record (#R$D432)
# In V from where he stands: more than his half-size and its (5 + 8), so that
# #R$B097 does not lift it onto him, and less than that with the 4 #R$BF79
# adds to his, so that it is in reach.
PICK_UP_DISTANCE = 15


def _runs(snapshot: Path, base) -> tuple[list[dict], int]:
    out = []
    game = pa.started(snapshot)

    # Arriving: the restart into the empty room, the four notes of effect 0.
    frames = game.enter(pa.EMPTY_ROOM, 128, 128, facing=3, settle=6)
    arrival = next(i for i, f in enumerate(frames) if f.record(pa.LEGS)[0] in range(32, 40))
    run = frames[arrival + 1:arrival + 6]
    edges, length = from_turns(run)
    expected = [b for b in effect_notes(base, 0, 4) for _ in range(12)]
    out.append({"name": "arrive", "entry": EFFECT_NOTE, "title": "Entering a room",
                "what": "Effect 0: on the first turn in a room #R$B00C sets SOUND_COUNT to "
                        "four notes of effect 0, and #R$D5F2 plays one a turn, twelve "
                        "waves each, from the last byte of the effect's notes back "
                        "(#R$D60D). Every room, whether he came through a doorway or "
                        "started a life there.",
                "how": f"the game running: a life started in room {pa.EMPTY_ROOM}, which "
                       "has nothing in it that makes a sound, and five turns from the "
                       "room's first.",
                "edges": edges, "length": length, "turns": len(run),
                "check": _check_clicks(edges, expected) + "; one note a turn",
                "pitch": _pitches(expected[::12])})

    quiet = sorted(f.tstates for f in game.turns(QUIET_TURNS))
    quiet_turn = quiet[len(quiet) // 2]

    # Walking: footsteps, every fourth step of the legs.
    game.hold([pa.WALK_KEY])
    before = game.peek(0xA748)
    run = game.turns(16)
    game.hold()
    edges, length = from_turns(run)
    steps = [(before + n) & 0xFF for n in range(1, 17)]
    expected = []
    for count in steps:
        if count & 3 == 0:
            expected += [64 if count & 4 else 96] * 2
    out.append({"name": "footsteps", "entry": FOOTSTEP, "title": "Walking",
                "what": "#R$D635, called by #R$C58D for every step of his legs: STEP_SOUND "
                        "counts them, and every fourth plays two waves, at a half-wave "
                        "count of 64 and 96 by turns -- a step of the legs is a turn, so "
                        "a tick every four turns, the pitch alternating.",
                "how": f"the game running in room {pa.EMPTY_ROOM}: walk held for 16 turns.",
                "edges": edges, "length": length, "turns": len(run),
                "check": _check_clicks(edges, expected)
                         + f", the step counter going from {before} to {steps[-1]}",
                "pitch": _pitches([64, 96])})

    # A bolt, and its puff at the wall.
    game.enter(pa.EMPTY_ROOM, 150, 128, facing=0, settle=6)
    game.hold([pa.FIRE_KEY])
    run = [game.turn()]
    game.hold()
    for _ in range(40):
        run.append(game.turn())
        if run[-1].record(pa.BOLT)[0] == 0:
            break
    edges, length = from_turns(run)
    fired = [b for b in _fire_expected()]
    bursts = [f for f in run[1:] if f.edges]
    found = _in_rom(base, [clicks(f.edges) for f in bursts])
    out.append({"name": "bolt", "entry": PUFF_SOUND, "title": "A bolt and its puff",
                "what": "#R$D629 as the bolt is fired, and then, when it bumps into the "
                        "wall and turns into a puff, #R$D64E on each of the puff's turns "
                        "(#R$C111): four single waves at pitches read from the ROM, from "
                        "an address made of the random number and the byte after it, so "
                        "no two puffs sound alike. Every puff makes it: a bolt's, the "
                        "player's own when he dies, the bucket's, a thing shot down.",
                "how": f"the game running in room {pa.EMPTY_ROOM}, fire pressed for a "
                       "turn with him facing the wall at U 150, until the puff has gone.",
                "edges": edges, "length": length, "turns": len(run),
                "check": _check_clicks(run[0].edges, fired, FIRE_OFF, "waves fired")
                         + f"; then {len(bursts)} bursts of "
                         + "/".join(sorted({str(len(clicks(f.edges))) for f in bursts}))
                         + " waves, one a turn, every off half-wave inside a burst "
                         + ("13B + 133" if all(_puff_offs(f.edges) for f in bursts)
                            else "NOT always 13B + 133")
                         + " for its B (#R$D64E's loop round #R$D67B), and "
                         + ("each burst's four pitches four bytes in a row of the ROM's "
                            "first 512, less their top bits, as #R$D64E reads them"
                            if found else "NOT all found in the ROM's first 512 bytes"),
                "pitch": "noise"})

    # The pause: SPACE, let go, SPACE again, let go.
    count_before = game.peek(SOUND_COUNT)
    game.enter(pa.EMPTY_ROOM, 128, 128, facing=3, settle=6)
    count_before, effect = game.peek(SOUND_COUNT), game.peek(SOUND_COUNT + 1)
    start = game.now
    first = len(game.tracer.edges)
    for keys, seconds in ((["SPACE"], 0.3), ([], 0.5), (["SPACE"], 0.3), ([], 0.1)):
        game.hold(keys)
        game.sample(int(seconds * TSTATES_PER_SECOND))
    game.hold()
    game.to_turn()
    tail = game.turns(3)
    edges = [t - start for t in game.tracer.edges[first:]]
    length = tail[-1].end - start
    extra = effect_notes(base, effect, count_before + 2)
    expected = ([64 + count_before + 1] * 12 + [64 + count_before + 2] * 12
                + [b for b in extra for _ in range(12)])
    out.append({"name": "pause", "entry": PAUSE_BEEP, "title": "Pausing, and going on",
                "what": "#R$D5D7, played by #R$B4E0 as SPACE (or CAPS SHIFT) alone pauses "
                        "the game and again as it lets it go on: twelve waves at 64 plus "
                        "SOUND_COUNT's first byte, after adding one to it. So each beep is "
                        "a little lower than the last, and the two added to the count make "
                        "#R$D5F2 play the last effect's last two notes again on the turns "
                        "after.",
                "how": f"the game running in room {pa.EMPTY_ROOM}, nothing under way "
                       f"(SOUND_COUNT {count_before}, effect {effect}): SPACE held 0.3 s, "
                       "let go 0.5 s, held 0.3 s, let go; recorded on to three turns "
                       "later. The silence in the middle is the pause, as long as it was "
                       "held.",
                "edges": edges, "length": length,
                "check": _check_clicks(edges, expected),
                "pitch": _pitches(expected[::12])})

    # Picking up: a collectable put where he stands, and 1 pressed.
    record = pa.QUEST_RECORDS + pa.QUEST_SIZE * PICK_UP
    graphic = game.peek(record)
    game.poke(record + 1, [128, 128 - PICK_UP_DISTANCE, 128])
    game.poke(record + 8, pa.EMPTY_ROOM)
    game.enter(pa.EMPTY_ROOM, 128, 128, facing=3, settle=6)
    game.hold([pa.TAKE_KEY])
    run = [game.turn()]
    game.hold()
    run += game.turns(6)
    taken = game.peek(record) == 0          # a carried thing's record has graphic 0
    edges, length = from_turns(run)
    expected = [b for b in effect_notes(base, 1, 5) for _ in range(12)]
    out.append({"name": "pickup", "entry": EFFECT_NOTE, "title": "Picking up and putting down",
                "what": "Effect 1: every press of the pick-up key that #R$BF79 acts on sets "
                        "SOUND_COUNT to five notes of effect 1, which #R$D5F2 plays one a "
                        "turn, falling -- whether he picks something up, puts something "
                        "down, or only moves what he carries along a place.",
                "how": f"the game running in room {pa.EMPTY_ROOM}: collectable record "
                       f"{PICK_UP} (graphic {graphic}) moved into the room "
                       f"{PICK_UP_DISTANCE} units in front of him, and 1 pressed for a "
                       "turn; recorded from that turn for seven."
                       + (" He picked it up: its quest record's graphic went to 0, as "
                          "#R$BF79 marks a thing carried." if taken else
                          " He did NOT pick it up."),
                "edges": edges, "length": length, "turns": len(run),
                "check": _check_clicks(edges, expected) + "; one note a turn",
                "pitch": _pitches(expected[::12])})
    return out, quiet_turn


# PUFF_SOUND calls BEEP for one wave at a time: CLICK's return, BEEP's DEC C
# and JR NZ falling through, its RET, then PUFF's DEC E, JR NZ, LD A,(HL),
# INC HL, AND, LD B,A, LD C, CALL BEEP and BEEP's CALL CLICK.
PUFF_OFF = 133


def _puff_offs(edges) -> bool:
    measured = clicks(edges)
    _, gaps = halves(edges)
    return all(gap == 13 * _count(b) + PUFF_OFF for gap, b in zip(gaps, measured))


def _fire_expected() -> list[int]:
    expected, b = [], 0
    for c in range(32, 0, -1):
        b = (c - b) & 0xFF
        expected.append(b)
    return expected


def _in_rom(base, bursts: list[list[int]]) -> bool:
    """Whether each burst's pitches are consecutive ROM bytes, less their top
    bit, from the first 512 (#R$D64E's address is RANDOM's word AND $1FFF,
    and the byte after RANDOM is 0 or 1)."""
    rom = [b & 0x7F for b in base[:0x200 + 4]]
    for burst in bursts:
        if not any(rom[a:a + len(burst)] == burst for a in range(0x200)):
            return False
    return True


# --------------------------------------------------------------------------
# Measuring and writing.
# --------------------------------------------------------------------------

def _length(tstates: int) -> str:
    seconds = tstates / TSTATES_PER_SECOND
    return f"{seconds * 1000:.0f} ms" if seconds < 1 else f"{seconds:.2f} s"


def _write_wav(path: Path, edges: list[int], length: int) -> None:
    """Render the speaker edges to a WAV. SkoolKit's writer takes the gaps
    between flips, starting from the speaker off; a recording that ends with
    the speaker on (every tune does: #R$D6C0 ends each wave on) is turned off
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
        stats += f", {sound['turns']} turns"
    stats += ", " + (_tune_pitch(sound, rows) if sound.get("tune") else sound["pitch"])
    paragraphs = [sound["what"], f"Recorded: {sound['how']}", f"Checked: {sound['check']}."]
    lines = [f'<div class="kl-item" id="{sound["name"]}">',
             f"<h4>{_esc(sound['title'])}</h4>"]
    lines += [f"<p>{pa.link(p, entries)}</p>" for p in paragraphs]
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


def _section(tunes, effects, runs, quiet_turn, rows, comparison, entries) -> str:
    lines = [
        '<div class="kl-list">',
        "<p>A 48K Spectrum has one bit of sound hardware, bit 4 of port $FE, and "
        "Pentagram makes every sound by setting and clearing it with the processor "
        "counting in between, the border kept black. While a sound plays nothing else "
        "happens, which is why the game stands still for a tune. There are two players. "
        "The tunes go through #R$D6C0, a note at a time; everything else is a burst of "
        "waves from #R$D682, which turns the speaker on for B turns of a 13 T-state loop "
        "and off for as long, and #R$D67B, which repeats it C times.</p>",
        "<p>The tune player and its note table are Knight Lore's (see "
        "<a href=\"../knightlore/Sounds.html\">Knight Lore's sounds</a>). A tune is a "
        "string of note bytes ended by $FF: the low six bits index #R$D718, five octaves "
        "of semitones from G#1 to G6 with 0 a rest, and the top two bits are the length "
        "less one, one to four units of about 0.155 s. " + comparison + " The six tunes "
        "themselves are Pentagram's own: none of them is in Knight Lore.</p>",
        "<p>The effects are Pentagram's. Most in-game sounds are a single burst -- a "
        "jump, a bolt, a footstep, a puff. Two are sequences, played a note a turn by "
        "#R$D5F2 from the end of the main loop's turn (#R$B00C): SOUND_COUNT holds how "
        "many notes are left and which of the four effects in #R$D60D, and each turn one "
        "note of twelve waves is played, from the last byte of the effect's notes back. "
        "Only effects 0 (entering a room) and 1 (picking up or putting down) are ever "
        "started; 2 and 3 have their notes and their addresses, and nothing sets them. "
        "About a hundred bytes of other sound code and pitch tables, from #R$D56C to "
        "#R$D5D2 and at #R$D665, are never reached at all.</p>",
        "<p>Every recording here is the game's own code running in SkoolKit's "
        "simulator, each change of the speaker bit logged to the T-state and rendered "
        "at 44100 Hz; nothing is synthesised. Each says how it was recorded and how it "
        "was checked against what the code implies: the number of waves, and every "
        "half-wave's length in T-states from the instructions of the loop that timed "
        "it. The simulator has no memory contention, so all of this runs a touch faster, "
        "and a touch higher, than on a real Spectrum, where the ULA holds up the OUTs. "
        f"A quiet turn (room {pa.EMPTY_ROOM}, nothing moving) lasts {quiet_turn:,} "
        f"T-states, {quiet_turn / TSTATES_PER_SECOND * 1000:.0f} ms; the calls that "
        "stand for an effect played over several turns are spaced by that.</p>",
        "<h3>Tunes</h3>",
    ]
    for sound in tunes:
        lines += _item(sound, rows, entries)
    lines.append("<p>The notes the tunes use, worked out from #R$D718 and #R$D6C0's "
                 "timing: B and C time each half-wave, and a unit is that many waves. "
                 "The table has 61 rows; these are the ones any of the six tunes plays.</p>")
    lines += _notes_table(rows, tunes + [e for e in effects if e.get("tune")])
    lines.append("<h3>Effects in play</h3>")
    for sound in runs + [e for e in effects if not e.get("never")]:
        lines += _item(sound, rows, entries)
    lines.append("<h3>Never heard in the game</h3>")
    lines.append("<p>Code and data that the game has but never plays, recorded by "
                 "calling it to hear what it would have made.</p>")
    for sound in [e for e in effects if e.get("never")]:
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
    log("Recording Pentagram's sounds...")
    runs, quiet_turn = _runs(snapshot, base)
    every_tune = _tunes(base)
    tunes = [t for t in every_tune if not t.get("never")]
    effects = _calls(base, quiet_turn) + [t for t in every_tune if t.get("never")]
    for sound in tunes + runs + effects:
        if not sound["edges"]:
            raise RuntimeError(f"{sound['name']}: no sound was made")
        _write_wav(audio / f"{sound['name']}.wav", sound["edges"], sound["length"])
    log(f"  {len(tunes) + len(runs) + len(effects)} sounds written to {audio}")
    return {"Sounds": _section(tunes, effects, runs, quiet_turn, rows,
                               knight_lore_comparison(base), pa.skool_entries())}
