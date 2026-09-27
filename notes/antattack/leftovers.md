# Leftovers

**Question this answers:** what is in the game but unused, unreachable or
redundant -- and what each suggests about how it was written.

**Short answer:** the author's signature three times in the filler; a
script nothing runs (and that could not run as it stands); sprite frames
nothing draws; a flag nothing sets; five NOPs where code was taken out and
one byte no path reaches; five variables BASIC sets and nothing reads, with a
page of filler that reads one of them; a note nothing plays; a decrement
straight away overwritten; and a random number handed to BASIC that BASIC
throws away.

## How it works

| What | Where | Status |
|---|---|---|
| The author's name and the year, run together, twice with a fragment of a third | `PLAY_PAD` $8034-$805F | never read (*read*) |
| The same signature once more | `READ_VIEW_KEYS_PAD` $8448-$845F | never read (*read*) |
| A script-like string spelling a short cry of pain | `NOISE_PAD` $8B60-$8B7F | never run; no stream byte and an end marker after its third letter, so as it stands it could not print the whole word (*read*; *watched* live: given a stream it prints three letters) |
| `TONES` entry 15 | $8BCF | never played: note $0F means noise to `RUN_SCRIPT` (*read*) |
| Sprite frames $F0-$F3 (drawn on the Sprites page as an ant on its back) | $BC00-$BCFF | no code produces those frame numbers (*read*; *watched*: nothing writes them) |
| Sprite frames $68-$6B, the grenade's own | $9A00-$9AFF | drawn only when the player is near the grenade's home far outside the walls (*measured*, *watched*; [`grenades.md`](grenades.md)) |
| Flag bit 3, "never falls" | tested in `FALL` $8880 | set by nothing -- not BASIC's DATA, not the code -- so its three instructions are the only ones in the code map never run (*read*, *played*) |
| NOPs where something was removed | `SHARE_CELL` $84F6-$84F8, `ON_TOP` $88C6, `THROW_GRENADE` $8D4A | run, doing nothing (*read*) |
| A NOP after `JP (IY)` | `DRAW_SCENE` $852A | unreachable: nothing jumps to it, and it is not in the code map (*read*) |
| `LD DE,31` in front of each block drawer | $8200, $8700 | each drawer's first instruction by the look of it, but both are entered three bytes later because `DRAW_SCENE` has set DE (*read*) |
| Five bytes BASIC sets to 1 | $B423-$B427 | no machine-code instruction reads them (*read*) |
| A page of filler: LD C,0 / LD A,($B425) repeated, ending in RET | `PARALYSE_ANT_PAD` $8BFF-$8CFF | never run; it reads one of the five unused variables above (*read*) |
| A decrement overwritten by the next three instructions | `COUNT_DOWN_TIME` $8DDF | runs, redundant (*read*) |
| The random byte copied to SEED "for BASIC's RND" | `PLAY` $802C | overwritten at once by the RANDOMIZE that called `PLAY`, and the BASIC has no RND (*read*) |
| A second copy of the interrupt set-up | `LOADED_PAD`, before $9797 | never run (*read*) |
| A rendered frame, the gathered cells and the planes | `RENDER_BUFFER`, `VIEW_CELLS`, `PLANES` on the tape | whatever the author's machine held when the tape was saved; cleared or overwritten by the first frame (*read*) |
| The rescued person's home, (0, 0, 0) | $B49A-$B49C | only used if they are blown up, which ends the attempt four frames later anyway (*read*) |

**What they suggest** (*assumed*, each a guess from the shape of the
leftover):

- The NOPs in `SHARE_CELL`, `ON_TOP` and `THROW_GRENADE` are patches made in
  the binary rather than reassembled: instructions blanked in place.
- The block drawers were once called at their `LD DE,31`, before
  `DRAW_SCENE` took over setting DE for the whole scan.
- The unused script is from an earlier script format, or two fragments of
  scripts; nothing decides between these.
- The five variables at $B423-$B427, and the filler that reads one of them,
  belonged to something removed before release.
- Frames $F0-$F3 were meant for paralysed ants, which keep their last walking
  frame instead.

## How this was found

The build's code map (what ran in the playthrough) was compared with the
listing; every filler block was read byte by byte when it was labelled; the
NOPs and the redundant decrement were noticed while commenting; the variables
were checked by searching the code for their addresses; `$852A` and the SEED
write were found for these notes (2026-09-27), the first by checking the
executed map, the second by reading the ROM's RANDOMIZE.

## Confidence

All *read*, some confirmed by runs as marked. The interpretations are
guesses.

## Disassembly corrections

- The How-it-works page's leftovers say "five NOPs"; there is also the
  unreachable one at $852A, which the listing shows as an instruction inside
  `DRAW_SCENE`. Reported to the lead.

## Open questions

- Whether other releases of the game differ in any of these (only the one
  tape has been looked at).
