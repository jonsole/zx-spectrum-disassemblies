# Sounds

**Question this answers:** what sounds the game makes, what makes them,
and how they were recorded.

**Short answer:** only one: the loading tune, which plays over the loading
screen until a key is pressed. The game itself is silent -- no footsteps,
no effects, not even a border colour change. The only writes to the port
are the three `OUT ($FE),A` in the tune's player. The loader has a sound of
its own, a warble from its failure routine, which is never heard on a good
load.

## How it works

**No in-game sound.** The only `OUT` to port $FE in the program are the
three in `TUNE_PLAY_NOTE` ($C087, $C093, $C0A5) (*searched*: a byte scan
finds that opcode nowhere else), and the only ROM routines it calls are
KEY-SCAN (from $C00F) and PIXEL-ADD (from $E423), neither of which makes a
sound. *Measured*: the build's nine sessions re-run with every `OUT`
logged found none after the tune. Release 1 is the same.

**The loading tune** ([`loading-tune.md`](loading-tune.md) has the player).
52.59 seconds; 415 notes are heard. Each voice has 418 note bytes, but the
last three are rests in both voices, and a note in which both voices rest
returns at once, so they take no time. The two voices take turns 48
T-states apart in a 96-T-state loop, each with its own copy of the port
byte (A' and A) and its own countdown (E and L). A note of period P sounds
at 3500000 / (192 x P) Hz, and every note is 18 passes of 256 turns,
0.1267 seconds. A resting voice still toggles, at 18.2 kHz, above hearing.
Voice one has 88 rests and voice two 25; notes 99-125 are repeated as
355-381. The period table sits 30 to 61 cents sharp of A440 in the
uncontended simulator; on a real Spectrum, contention would flatten it by
an amount not measured (the emulator does not contend either). ZXDB
credits the music to Mark Alexander.

**The loader's warble.** The Alkatraz failure routine (`LOADER_FAILURE`,
$DCC9) calls the ROM's BEEPER in 233 pairs, at 261.7 Hz and 413.3 Hz: 7.68
seconds of warbling before it resets the machine. It runs only when the
load's checksum fails ([`loading.md`](loading.md)).

## How this was found

The sounds page agent of stage 3: a byte scan for the `OUT (n),A` opcode and for calls
into the ROM; the build's sessions re-run with a tracer logging every
`OUT`; the tune and the warble recorded from the game's own code in the
simulator (the pages carry the WAVs, built at each build), and every
recording checked edge by edge against a model worked out from the
instruction timings.

## Confidence

No in-game sound: *searched* and *measured*. The tune's length, pitches and
note counts: *measured*, and matched to the model from the timings. The
warble: *measured* from its code in the simulator. The tuning on real
hardware: not measured.

## Krumlinde

His snapshot was taken mid-game, with the clean copy of the room over
$C000, so the tune and its player are not in his listing; his analysis has
no sound, and the game has none to find.

## Open questions

- How flat a real, contended Spectrum plays the tune.
