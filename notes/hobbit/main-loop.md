# The main loop: a turn

**Question this answers:** what happens between one prompt and the next, in
what order, and what counts as a turn.

**Short answer:** `MAIN_LOOP` ($6D13) reads a line, tokenises all of it, then
parses and obeys it one command at a time. Each command that is carried out
is followed by the rest of the world's turn (`END_OF_TURN`): the win test,
every other character's action, the timers. A command that is refused, or
not understood, takes no time at all -- the world does not move.

## How it works

```
MAIN_LOOP $6D13      MORE_COMMANDS = 1; NO_PAUSE_LINES = 9
  READ_LINE $6DD6      prompt, keys into INPUT_LINE (Z: @, run the last line again)
  TOKENISE $6E97 x n   every word to a 2-byte token in TOKENS ($709C)
                        unknown word: "i do not know the word ..." and back to the prompt
                        quotes: an opening one starts an order, a closing one ends it
  loop:
    PARSE_COMMAND $7585  the next command's frame(s), from TOKEN_POINTER
    OBEY $7960           for each frame:
      PARSE_ACTION $79B6   pattern -> action code; which objects the names mean;
                           each tried as a test until one would work
      (refused?  say why, next frame, no turn)
      NARRATE_ACTION $712B "you open the door."
      DO_ACTION $950F      do it
      END_OF_TURN $96B3    CHECK_WON, CHARACTERS_ACT, the timers
    while MORE_COMMANDS
  back to MAIN_LOOP
```

(*read*; the call order from `OBEY`'s and `MAIN_LOOP`'s code.)

**The first turn** is not typed: `NEW_GAME` prints "> LOOK", copies LOOK into
`INPUT_LINE` from `LOOK_COMMAND` ($6FF4) and jumps to $6D22, past the call of
`READ_LINE` ([`loading.md`](loading.md)). `scripts/hobbit_drive.py` puts
commands in the same way ([`driving.md`](driving.md)).

**A turn is a command, not a line.** TAKE THE MAP AND DROP IT is two
commands, and the world has a turn after each (*read*: `OBEY` calls the
action and `END_OF_TURN` per frame). Commands that fail -- "i cannot do
that.", "you cannot go north.", "i do not see the ... here" -- are said in
the input window and cost nothing: *measured* on 2026-09-27, PUT MAP ON
CHEST, CUT MAP, THROW MAP and TAKE MAP FROM CHEST each answered with the
refusal and nothing else, no character moving; so did every blocked move.
The refusal is printed by `SAY_WHY_NOT` ($7DF5), which does the action for
real so that its own handler says why, and jumps back to `OBEY_NEXT`
($798E) -- past the call of `END_OF_TURN` (*read*). The one failure that
does cost a turn is a sentence that fits no action pattern at all: "you ... .
time passes..." from `MATCH_PATTERN`, which jumps to `TURN_OVER` ($798B),
the call of `END_OF_TURN` (*read*). A refusal about a named object also
throws away the rest of the line; see [`parser.md`](parser.md).

**Time passes without the player too.** If nothing is typed for about 23
seconds `GET_KEY` types WAIT itself and presses ENTER, and that WAIT is a
turn like any other. See [`time-and-timers.md`](time-and-timers.md).

**`END_OF_TURN` ($96B3)** in order (*read*):

1. `CHECK_WON` ($A9D6): the treasure ($23) held by the wooden chest ($25)
   ends the game ([`fighting-and-dying.md`](fighting-and-dying.md) has the
   other endings).
2. `CHARACTERS_ACT` ($980E): each of the 17 character slots in turn
   ([`characters.md`](characters.md)). Before them, `NOTE_LIGHT` records
   where the player is and whether it is dark there, which decides what of
   their doings the player is told.
3. The ten `TIMERS`: count down, warn, fire at most one
   ([`time-and-timers.md`](time-and-timers.md)).

So after the player's own action the world moves in a fixed order: the
characters in slot order (Gandalf first, the goblins last), then the timers.
A character therefore always sees the result of the player's command, and a
timer the result of everybody's.

**Printing during a turn.** Nothing the characters do is printed unless the
player can see them (see [`characters.md`](characters.md)); the story window
scrolls without pausing for the first nine lines of a turn and then waits
about 0.6 s a line ([`screen-and-printer.md`](screen-and-printer.md)).
A turn in which a lot happens therefore visibly slows down.

**Pictures stop everything.** Arriving somewhere new draws its picture
inside `MOVE`'s call of `DESCRIBE_ROOM`, then waits in `WAIT_FOR_ANY_KEY`
for a key before the rest of the turn -- the characters and the timers --
runs ([`pictures.md`](pictures.md)).

## How this was found

Read from `MAIN_LOOP`, `OBEY` and `END_OF_TURN`. The refusals costing no
turn were checked on 2026-09-27 with a scratch harness around
`hobbit_drive.Hobbit` that captures what is printed (at $858F, past
`PRINT_GATE`; see [`driving.md`](driving.md)).

## Confidence

The order is *read*; every part of it runs in the build's playthrough. The
no-turn refusals are *measured* for the cases above, and follow from the
code for all of them (`OBEY` skips to the next frame on a refusal).

## Disassembly corrections

- `END_OF_TURN`'s description and its comment at $96BA say the two calls
  before the timers are "the rest of the world's turn, not yet worked out".
  They are `CHECK_WON` and `CHARACTERS_ACT`, both named and described.
  Corrected in the annotations 2026-09-27.
- `OBEY`'s comments at $7985 and $798B ("Not yet worked out") are the calls
  of `NARRATE_ACTION` and `END_OF_TURN`: the action is told, then done, then
  the world has its turn. Corrected in the annotations 2026-09-27.

## Open questions

- `OBEY`'s "go round the same frame again" flag (`ALL_ACTION`, $B71C) is
  how ALL repeats a command per object; the exact interplay with EXCEPT's
  frames was not traced for these notes (see [`parser.md`](parser.md)).
