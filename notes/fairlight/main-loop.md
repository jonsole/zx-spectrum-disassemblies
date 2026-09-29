# The main loop

**Question this answers:** what one pass of the game does, which keys are
read outside the knight's own update, and what using a thing does.

**Short answer:** `MAIN_LOOP` ($FE47): the joystick switch (9), the room's
colours on its first pass, then pause, quit, use (6, 7) and choose (1-5);
then LIFE if it changed, the message line, and each record from the
knight's to the last, updated by `CHE3D` ($F1E0). Nothing waits for the
frame, so a pass takes as long as it takes. It returns from `ROOMST`, ending
the game, when LIFE is 00 or on SYMBOL SHIFT and 0. Using a thing by its
kind: 9 carries the knight off to room 30, 6 makes LIFE 99, 5 freezes the
creatures, 4 adds 10 to LIFE; each is then used up.

## How it works

In order (the author's labels from his source text; [`symbols.md`](symbols.md)):

1. **9** flips bit 3 of `OPTIONS` (the Kempston joystick) and waits for all
   keys up.
2. **The room's first pass** (bit 2 of `GAME_FLAGS`): `ATTRI` colours the
   room -- it was drawn black on black, so it appears all at once -- and the
   thing in use is shown again.
3. **`PASS_KEYS`** ($FE71): if the joystick is on and pushed, straight to the
   pass. SPACE and SYMBOL SHIFT together pause (`WAIT`); SYMBOL SHIFT and 0
   together: `RET`, the game over. 6 or 7 (STAR2, $FE8F): use the thing in
   the place in use. 1-5 (ST20, $FEF1; ST4, ST5): choose a place, and
   `SHOW_IN_USE` ($FF0E, STE3) shows what is in it
   ([`printing.md`](printing.md)).
4. **`START_PASS`** ($FF21, ST3): LIFE printed at x 55, y 12 if bit 0 of
   `GAME_FLAGS` asks for it.
5. **The message line** ($FF42, ST9: `SHOW_MESSAGE`).
6. LIFE 00: `RET`. Otherwise **each record** from the knight's (7) to the
   last in use (`OBJECT_COUNT`), counted in `THIS_RECORD`: `CHE3D`
   ([`object-states.md`](object-states.md)). Then round again.

**Using a thing** (USE6, USE5, USE4 in the author's text), by the kind in
its +12:

| Kind | Effect |
|---|---|
| 9 | `ROOM` = 30; EEN saves the room; the return to the new game's code dropped, and `JP TELE`: he is put where a new game starts him, in room 30 |
| 6 | LIFE 99 |
| 5 | The freeze: bit 7 of `GAME_FLAGS`; every creature only falls until the next room ([`object-states.md`](object-states.md)) |
| 4 | LIFE's tens up one; at 9 tens already, LIFE 99 (ST21) -- so +10, at most 99 |
| other | Nothing |

A used thing's place is emptied (ST22) and LIFE printed again; its record
stays among the room's, hidden, and its table entry keeps room $FE, so it
is gone for good. An empty place reads a record at 0, whose +12 is a ROM
byte of kind 15, and nothing happens.

## How this was found

Read (stage 2, range 5); the author's source text at $D694 covers
$FE89-$FF3F line by line. *Measured*: holding SYMBOL SHIFT and 0 at $FF21
reached $F0AF, the return from `ROOMST`; the freeze in room 24.

## Confidence

*Read*; the quit key and the freeze *measured*.

## Disassembly corrections

- Stage 1's `driving.md` said a thing of kind 4 "adds to LIFE only below
  90". At 90-99 it makes LIFE 99 ($FEDF); it adds 10 below that.

## Krumlinde

- He calls 0 the use key and SPACE with SYMBOL SHIFT an alternate chord for
  it. Use is 6 or 7 (bits 3 and 2 after one `RRA`); SPACE with SYMBOL SHIFT
  pauses; 0 with SYMBOL SHIFT quits (*measured*).
- Kind 4 is "+1 capped near 10" in his reading: it adds 1 to the tens
  digit, 10 LIFE, to at most 99. Kind 5 "not confirmed": it freezes the
  creatures.
- Kind 9 to room 30, kind 6 to 99, things used up, and 1-5 choosing: agreed.
- At $FECC his `DB $18` and a label at $FECD are `JR $FEE3`, the author's
  `JR ST22`.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `MAIN_LOOP` | `SUBFE47` | $FE47 | The loop |
| `PASS_KEYS` | (entry) | $FE71 | Pause, quit, use, choose |
| `SHOW_IN_USE` | (inside) | $FF0E | The author's STE3 |
| `START_PASS` | (inside) | $FF21 | The author's ST3 |
| `MESSAGE`, `MESSAGE_TIMER` | `VARFF87`, (none) | $FF87, $FF88 | The message line |
| `GAME_FLAGS` | `VARFF97` | $FF97 | 0 LIFE to print, 1 sword, 2 first pass, 3 fidget, 4 still drawing, 6 message up, 7 frozen |

## Open questions

- None of the pass is paced; how slow a busy room runs was not measured.
