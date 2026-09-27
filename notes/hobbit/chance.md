# Chance: the random numbers and what each game chooses

**Question this answers:** where the game's randomness comes from, how even
it is, and what is decided by it.

**Short answer:** `RANDOM` mixes its last result, seeded from the R register
when the title key is pressed, with bytes read from a pointer that walks
through the whole of memory, ROM included, one byte a call. It is not
even: the ends of a range come up about half as often as the middle. Each
new game uses it to shut one of five roads and pick Gollum's riddle; after
that it decides where the characters wander, how many orders they take,
every blow in a fight, and a dozen smaller things.

## How it works

**`RANDOM` ($9CA8)**, a number from -A to A (*read*):

1. B = 2A (or $FF).
2. Step `RANDOM_POINTER` ($B712) on -- a 16-bit address that starts at $0000
   on the tape. `INC (IX+1)` with IX = $B712 is its *high* byte, so it steps
   256 bytes a call, and the low byte moves on only when the high one wraps:
   it sweeps the whole of memory a page at a time -- ROM, screen and game --
   256 calls to go round once (*read*; corrected 2026-09-27, it said "by one").
3. A = `RANDOM_LAST` ($B70E) + the byte at the pointer (with whatever carry
   is left), XOR the byte one past pointer + DE -- DE being whatever the
   caller had in it.
4. The same as last time? Go back to 2. Otherwise keep it as `RANDOM_LAST`.
5. Halve it until it is no more than B, and take A off.

`RANDOM_POSITIVE` ($9C9F) drops the sign: 0 to A. *Measured* (2026-09-23,
3000 calls each): every value comes up, but for A = 4 the two ends about half
as often as the middle three, and for A = 9 the top three are short.

**The seed** (*read*): `NEW_GAME` loads `RANDOM_LAST` from R after the
title key, and R counts instructions, so the seed depends on how long the
title screen waited. `RANDOM_POINTER` is outside the blocks a new game
restores, so it goes on walking from game to game. A script that presses the
title key at the same instruction every time gets the same game every time
-- which is why driving by breakpoint repeats the same shut road
([`driving.md`](driving.md)).

**What each game chooses** (`NEW_GAME_CHOICES` $97AD; *read*):

- **The hidden road**: `RANDOM_POSITIVE` 4 picks one of the five
  `HIDDEN_ROADS`, the first and last half as often as the other three; its
  exit is zeroed until Elrond reads the map ([`hidden-roads.md`](hidden-roads.md)).
- **Gollum's riddle**: `RANDOM_POSITIVE` 3 picks one of four `RIDDLES`
  entries -- two riddles, each in the table twice, so the ends' shortfall
  evens out and each riddle is about equally likely. Kept in `RIDDLE`
  ($B6EE), which SAVE keeps.

**What else is left to chance** (*read*, the 18 calls):

| What | Where | Range |
|---|---|---|
| A move in the dark | `MOVE` | direction 1-10 |
| RUN | `DO_RUN` | a random start direction, then the first way out round from it |
| Which script a wanderer switches to | `SCRIPT_RANDOM` | its first n scripts |
| How many orders a character takes | `DO_TALK` | 0 to its limit (0: "no") |
| Every blow and every guard | `JOSTLE` | meant +/-10; in practice +0 to +10, and 0 about one time in 25 ([`bugs.md`](bugs.md)) |
| Breaking a thing | `DO_STRIKE` | 0-21 added to the blow |
| A shot by anyone but Bard | `DO_SHOOT` | a miss when 0-8 comes up under 3 |
| The dragon | `DRAGON_HUNTS` | seen under 80 of 0-100, burns otherwise |
| The ring's invisibility | `WEAR_RING` | 2-10 turns |
| The rope and the boat | `HALF_THE_TIME` | half and half |
| What Gandalf, Thorin and the others say | `GANDALF_CHATTER`, `THORIN_CHATTER`, `GIVEN_SOMETHING` | which line, or none |

## How this was found

`RANDOM` read line by line and measured by calling it 3000 times through
`RANDOM_POSITIVE` for several limits (2026-09-23, `41a8c90`); the choices
read from `NEW_GAME_CHOICES`; the call sites listed for these notes by
searching for calls of $9CA8 and $9C9F.

## Confidence

*Read*, with the unevenness *measured*. The per-call odds in the table are
the code's thresholds, not measured frequencies.

## Open questions

- How much the caller's DE really varies between calls, and so how
  predictable a sequence is from a known seed, was not measured.
