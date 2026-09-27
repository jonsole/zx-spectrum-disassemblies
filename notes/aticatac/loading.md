# Loading

**Question this answers:** how the tape gets the game into memory and
running, what protects it, and how the build gets past the protection.

**Short answer:** a BASIC loader loads five CODE blocks -- the loading
screen, the game (encrypted), and three tiny ones -- then runs an 18-byte
decryptor it has put in the printer buffer. The decryptor drags one nibble
through the whole game with RRD, so the plaintext exists only in RAM, and
jumps to `ENTRY` ($6000). Two of the tiny blocks are locks: one pokes the
frame counter, which `ENTRY` checks; the other is a single `JP (HL)` byte
in the system variables that every dispatch in the game jumps through. The
build simply runs the tape: `tap2sna --start $6000` simulates the real LOAD
and the decryptor and stops at `ENTRY`.

## How it works

**The tape** (*read*, SkoolKit's `tapinfo` on
`C:/Users/jonso/Downloads/Atic Atac (1983)(Ultimate).tap`, 2026-09-27): a
program header "AticAtac1" auto-running line 10 (78 bytes of BASIC), then
five headed CODE blocks, "AticAtac2" to "AticAtac6", in the order below.

**The loader** (*read*, the build's docstring and the Loading page): one
BASIC line that sets a black border, CLEARs to 24574, loads
`"AticAtac"+STR$ q` CODE for q = 2 to 6, and ends `PRINT USR 23424`. The five
blocks, in tape order:

| Name | Loads to | Length | What |
|---|---|---|---|
| AticAtac2 | $4000 | 6912 | the loading screen, shown while the rest loads -- the only picture in the game no game code draws |
| AticAtac3 | $5FFF | 30209 | the game, encrypted; the byte at $5FFF itself is not part of it |
| AticAtac4 | $5B80 | 18 | the decryptor, in the printer buffer |
| AticAtac5 | $5CB0 | 1 | a `JP (HL)` opcode, in spare system-variable space |
| AticAtac6 | $5C78 | 2 | $255E, over FRAMES |

**The decryptor** at $5B80 (*read*): HL = $5FFF, a count of 124 x 256 =
31744, A = 0, then RRD / INC HL round the whole block and `JP $6000`. RRD
rotates A's low nibble into the top of (HL) and (HL)'s low nibble out into
A, so one nibble travels through every byte and each byte depends on all
before it. There is no offline shortcut short of doing the same thing;
running it is simplest. It runs with interrupts on (BASIC called it), so
FRAMES keeps counting while it works.

**The FRAMES lock** (*read*, `ENTRY` $6000): DI, SP = $5E00, then
`LD A,(FRAMES+1)` / `CP $25` / `RET NZ` -- a loader that skipped the two-byte
block, or took long enough for the low byte to carry (about three seconds),
returns quietly to BASIC. Only the high byte is checked. Then `JP TITLE_SCREEN`
($7C19).

**The dispatch lock** (*read*, `DISPATCH_ACTOR` $7E7E): every handler the game
dispatches -- creatures, doors, sounds, the player, and the sixteen sprite
drawers -- is reached by `JP $5CB0`, where the one-byte block put `JP (HL)`.
A loader that skips it leaves the game jumping into whatever byte was there.

**Interrupts stay off until play** (*read*): `ENTRY` disables them and
nothing on the title screen enables them; the first `EI` is at the top of
`MAIN_LOOP` ($7DC6). So FRAMES does not move on the title screen, and the
game's first random choices are made from a frozen frame counter -- see
below.

**The first game after loading is always the same** (*read*, then *measured*
in the simulator, 2026-09-27). `START_GAME` ($7D9A) clears the variables,
including `TICKS` ($5E12), and then chooses the rooms of the A.C.G. key's
pieces (`PLACE_ACG_KEY` $94B6), the green, red and cyan keys and the mummy
(`PLACE_KEYS` $98D2), and which doors will open and shut by themselves
(`CHOOSE_TIMED_DOORS` $94F5), all from FRAMES and TICKS. With TICKS zero and FRAMES
frozen since `ENTRY`, those choices depend only on how many frames the
loader and decryptor took. The build's snapshot has FRAMES = $256F (seventeen
frames after the poke), and starting a game from it put the pieces in rooms
$17, $10 and $2B, the green key in $22, the red key and the mummy in $85, the
cyan key in $91 -- every time, whatever was pressed on the menu and when
(*watched* live as well, 2026-09-27: FRAMES read $256F on the title screen
and still did after 300 turns of its loop; a game as the knight and another
after a different control option and the serf both had those rooms).

**Later games differ less than they seem** (*read*, then *watched* live,
2026-09-27; the Bugs page's "Fewer castles than it seems"). Only FRAMES' low
byte runs in play, and `TICK_CLOCK` ($95DA) takes 50 off it every second, so
it never carries into the middle byte ($5C79). `PLACE_KEYS` chooses the cyan
key from that middle byte, so the cyan key stays in $91 game after game. The
middle byte moves only while interrupts are on outside play: after a game
over caused in the main loop (a creature, a big monster, a mushroom), whose
ten-second delay and following title screen run with interrupts on
([`main-loop.md`](main-loop.md)). A hunger death or a win leaves FRAMES
frozen until the next game. And because `TICKS` has just been cleared, the
green key, the red key with the mummy and the set of rooms for the A.C.G.
pieces all come from one index, FRAMES AND 7 -- eight arrangements, each
with the same partners -- while the timed doors come from FRAMES AND 15.
Watched: after six games over by hunger the cyan key was in $91 every time
and the rest followed FRAMES AND 7; after six by the devil, FRAMES' middle
byte reached $26-$28 and the cyan key went to $4C and $53.

On a real Spectrum the
count after the last block is also fixed, so the first game should be the
same on every load (*assumed*: it depends on the BASIC and the decryptor
taking the same number of frames there as in the simulated load).

## How this was found

The loader and decryptor were read off the tape when the build was written
(2026-08-28; the docstring of `scripts/build_aticatac.py` quotes them). The
build's `make_snapshot` runs `tap2sna --start $6000` with the tape as a
`file:` URI, so the snapshot is the machine as the decryptor leaves it. The
frozen FRAMES was noticed on 2026-09-27 while checking which rooms
`PLACE_KEYS` could pick: a harness printed FRAMES and IFF1 at the snapshot,
after three seconds of title screen, and at `START_GAME`, and it had not
moved.

## Confidence

The loader, the decryptor and the two locks are *read* and run in every build
(*played*). The fixed first game is *measured* in the simulator; that a real
load gives the same FRAMES is *assumed*.

## Renamed routines

Applied to the annotations on 2026-09-27; the build verified byte for byte.

| New name | Old name | Address | Role |
|---|---|---|---|
| `PLACE_ACG_KEY` | `ROTATING_INDEX` | $94B6 | hides the A.C.G. pieces |
| `CHOOSE_TIMED_DOORS` | `SCAN_DOORS` | $94F5 | makes timed doors |

## Disassembly corrections

All applied to the annotations, the ref and the build on 2026-09-27 (the old names are used below), except where marked.

- None about the loader. (`ROTATING_INDEX`, one of the three choosers, was
  misnamed and is now `PLACE_ACG_KEY`: see [`acg-key-and-winning.md`](acg-key-and-winning.md).)
- This note said "Later games differ, because FRAMES runs during play". Only
  the low byte runs: the cyan key stays put unless a main-loop death's game
  over lets the middle byte move, and the other keys and the pieces share
  one index (above; corrected 2026-09-27).

## Open questions

- Whether the first-game layout on real hardware matches the simulator's
  FRAMES $256F exactly, or is a frame or two different (which would change the
  low three bits and so the rooms).
