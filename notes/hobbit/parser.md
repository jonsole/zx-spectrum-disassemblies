# The parser: sentences into command frames

**Question this answers:** what sentences the game understands, how a line
becomes one or more commands, and what the special words (ALL, EXCEPT, IT,
quotes, SAVE, HELP...) do.

**Short answer:** the tokens of a line are read by a state machine that
dispatches on each word's class and fills 24-byte *command frames*: a verb,
an adverb or direction, and two noun phrases of prepositions, noun and
adjectives. THEN, a full stop, and AND before a verb start a new command;
AND and a comma otherwise join noun phrases. Thirteen special words are
handled on the spot, among them the game's own commands and the quote mark
that turns what follows into orders for a character.

## How it works

**Tokens** (`TOKENISE`, [`dictionary.md`](dictionary.md)): two bytes each in
`TOKENS` ($709C), the class in the top nibble, the word's 12-bit offset
below; $C0 ends the line. A full stop is a token of class $B (the same as
THEN), a comma $A (AND), a quote $9 with no word (*read*, `PUNCTUATION_TOKEN`
$6F30) -- so TAKE THE MAP. GO EAST and TAKE THE MAP, THE KEY parse exactly as
their spelled-out forms.

**The state machine** (`PARSE_COMMAND` $7585; *read*): `NEXT_TOKEN` takes a
token and `CLASS_DISPATCH` ($75C1) jumps through `PARSER_CLASSES` ($75D2) by
its class. Register E carries what may come next (a verb, an adverb, an
article, which noun phrase is free); a word where it is not allowed gets
"what ?" and the command is dropped (`NOT_ALLOWED_HERE`) -- except inside
quotes, where it is passed over, so orders are parsed more forgivingly.

| Class | Handler | What it does |
|---|---|---|
| $0 adverb | `PARSE_ADVERB` | offset 2 of the frame; one only |
| $1 IN, INTO | `PARSE_IN` | a verb at the start of a command (IN = go in), else a preposition |
| $2 direction | `PARSE_DIRECTION` | where a verb could go, the direction *is* the verb (NORTHEAST); else like an adverb (GO NORTHEAST) |
| $3 verb | `PARSE_VERB` | the verb; looks ahead past adverbs for a direction (RUN QUICKLY WEST) |
| $4 GO, RUN | `PARSE_GO` | as a verb |
| $5 noun | `PARSE_NOUN` | completes a noun phrase and files it |
| $6 adjective | `PARSE_ADJECTIVE` | up to two per phrase |
| $7 preposition | `PARSE_PREPOSITION` | up to two per phrase |
| $8 article | `PARSE_ARTICLE` | noted and dropped |
| $9 special | `PARSE_SPECIAL` | see below |
| $A AND | `PARSE_AND` | joins phrases -- or, before a verb, commands |
| $B THEN | `PARSE_THEN` | ends a command |
| $C end | `PARSE_END` | ends the line |

**The frame** (`COMMAND_FRAME` $B9C8, then `FRAMES` downwards from $B9B0;
room for twenty) (*read*, and *watched* at `OBEY` after real sentences):

| Offset | Field |
|---|---|
| 0-1 | the verb (bit 7 of byte 1: ALL; bit 6: the frame is an EXCEPT phrase, skipped) |
| 2-3 | an adverb, or a direction |
| 4-13 | the first noun phrase: two prepositions, the noun, two adjectives |
| 14-23 | the second noun phrase, the same |

Every word is a word reference, low byte first; articles are dropped. The
noun and adjectives are laid out exactly as an object's name is in its
record, so deciding what a phrase means is a byte comparison
(`NAME_MATCHES`; see [`actions.md`](actions.md)). VICIOUSLY ATTACK THE TROLL
WITH THE SWORD leaves ATTACK and VICIOUSLY, TROLL, and WITH SWORD.

**Joining and splitting** (*read*, and *measured* 2026-09-27):

- **THEN** and a **full stop** end a command; the rest of the line is parsed
  after it has been obeyed. DROP MAP THEN TAKE IT did both.
- **AND** or a **comma** between noun phrases repeat the verb: TAKE THE MAP
  AND THE KEY is two frames, the second borrowing the first's verb (and, for
  PUT ... IN, its second phrase). `PARSE_AND` saves a checkpoint
  (`AND_TOKENS` $7574); if a verb follows, `PARSE_VERB` goes back to it and
  ends the command there, as THEN would. DROP MAP AND TAKE IT and EAST AND
  WEST each did both.
- **A refusal about a named object drops the rest of the line; any other
  refusal does not.** TAKE MAP. DROP MAP, with the map already held, gave
  only the refusal; so did OPEN DOOR THEN EAST THEN WEST with the door open,
  and PUT MAP ON CHEST. INVENTORY. But NORTH. INVENTORY, and NORTH AND SOUTH
  AND INVENTORY, in Bag End, refused each move and then did the inventory
  (*measured*). In the code (*read*, in outline): a refused action with no
  objects fails `OBEY`'s test at $797A and goes through `SAY_WHY_NOT`
  ($7DF5), which prints the refusal and jumps back to `OBEY_NEXT` and on to
  the next frame. A sentence with objects is tried inside `PARSE_ACTION`
  itself (`MATCH_AND_TRY`), and when nothing works `PARSE_ACTION` jumps
  (not calls) to `TARGET_TROUBLE` to say why. `TARGET_TROUBLE` returns Z to
  `OBEY`'s call of `PARSE_ACTION`, which reads that as "nothing left on the
  line" and clears `MORE_COMMANDS` at $7976. *Measured* with breakpoints:
  for TAKE MAP. DROP MAP the run stopped at $7DBC with $7973 as the return
  address, then at $7976.

**The special words** (`PARSE_SPECIAL` $8251 looks the token up among the
thirteen in `SPECIAL_WORDS` $8271 and jumps to the matching handler, 26
bytes on; *read*):

| Slot | Word | Handler | Does |
|---|---|---|---|
| 0 | (no word) | `SPECIAL_QUOTE` $8315 | a quote mark: the opening one begins an order (`ORDER_BEGINS`), the closing one files it |
| 1 | ALL | `WORD_ALL` | `ALL_EXCEPT` = 1; the verb is done to every object that fits |
| 2 | EXCEPT | `WORD_EXCEPT` | only after ALL: its phrases go in frames of their own, marked skipped |
| 3 | IT | `WORD_IT` | the last target's name (`IT_NAME` $B6E0) as if typed |
| 4 | ONE | -- | ignored |
| 5, 6 | PRINT, NOPRINT | `PRINTER_ON`, `WORD_NOPRINT` | copy the story to a ZX Printer, if one answers on port $FB |
| 7, 8 | LOAD, SAVE | `DO_LOAD`, `DO_SAVE` | [`save-load.md`](save-load.md) |
| 9 | QUIT | `DO_QUIT` | the score, then a new game on a key |
| 10 | HELP | `DO_HELP` | a hint for eleven places (`HELP_HINTS`), elsewhere a general one; only for the player |
| 11 | SCORE | `DO_SCORE` | [`scoring.md`](scoring.md) |
| 12 | PAUSE | `DO_PAUSE` | green border until a key |

None of these is an action: they cost no turn and pass no time. PRINT,
NOPRINT, LOAD, SAVE and PAUSE go back to the parser for the next word, so
they can sit in the middle of a sentence.

**Orders: words in quotes.** `MAIN_LOOP` watches for quote tokens as it
tokenises. SAY TO THORIN "GO EAST" parses TALK TO THORIN, and the words in
quotes are parsed as commands of their own in fresh frames marked
`IS_ORDER`; the closing quote files each of them into a free slot of
`ORDERS` ($B738, eight slots of 25 bytes: the character, then the frame).
`DO_TALK` then decides how many the character accepts, and the character
carries them out on its own turns ([`characters.md`](characters.md)). A
closing quote gets a full-stop token put before it, so what is said ends as
a sentence; a line that ends inside quotes gets "what ?".

**Questions.** When a name fits several objects and none will do,
`ASK_WHICH` says "which ... ?" and `KEEP_QUESTION` copies the unfinished
frame up to `COMMAND_FRAME` with `QUESTION_WAITING` set: the next line's
words are fitted into it rather than parsed as a new command (the start of
`PARSE_COMMAND`, and `PARSE_THEN`'s comparison of the new noun with the old).

## How this was found

The parser's shape -- a state machine over classes filling frames -- was
first learned from bluespikey's annotated v1.0 disassembly (credited in the
build and on the Credits page); the handlers, the frame layout and every
address here are v1.2's own, read line by line on 2026-09-23 and confirmed
by stopping at `OBEY` after real sentences and reading the frames. The
multi-command and refusal behaviour was checked for these notes with the
scratch capture harness (see [`driving.md`](driving.md)).

## Confidence

*Read* for the machine and the special words; the frame layout *watched*;
the splitting rules and the dropped rest of the line *measured* on the
sentences named. ALL ... EXCEPT is *read* only: the build's playthrough typed
DROP ALL EXCEPT THE SWORD, so the code runs, but its result was not checked
here.

## Disassembly corrections

- `COPY_VERB_ON`'s description says when it moves a frame's phrase to second
  place "is not yet worked out", and `PARSE_NOUN`'s and `PARSE_ADVERB`'s
  comments have lines still marked so; not settled here either.

## Open questions

- Whether dropping the rest of the line after a refused object was meant
  (it saves the player from commands built on one that failed) or is a side
  effect of `TARGET_TROUBLE` sharing `PARSE_ACTION`'s "line done" return.
- Whether HELP's hints are the same set in v1.0.
