# Messages: how the text is compressed and printed

**Question this answers:** how 177 messages, 80 room names and 61 object
names fit in a few kilobytes, and how one message can serve every character.

**Short answer:** nothing is stored as plain text. A message is a small
bytecode run by `RUN_MESSAGE`: a two-byte reference to a dictionary word, a
one-byte code for one of 32 common words, a literal character, or a control
code that prints something chosen at run time -- the actor's name or YOU,
IS or ARE, HIS or YOUR, the target, the instrument. Verbs take their -s when
the subject is not the player, articles are chosen by the noun, and
sentences about actions are not stored at all but built from the action's
pattern.

## How it works

**The bytecode** (`RUN_MESSAGE` $72D3; entry with HL at $72DD, which nearly
every caller uses; *read*, and *measured* against the screen):

| Byte | Meaning |
|---|---|
| bit 7 set | the first of a two-byte word reference, high byte first: 12 bits of dictionary offset and a flag nibble; flags 2, 3 and 6 also end the message (plainly, with a full stop and a new line, or with a new line: `WORD_AND_END`) |
| $60-$7F | one of the 32 `COMMON_WORDS` ($AD3D): a, and, are, at, the, you and the like, a byte each |
| $20-$5F | a literal character -- punctuation, and words the dictionary lacks, spelled out |
| $00-$13 | a control code: call its handler from `CONTROL_CODES` ($7295) and carry on |
| $14-$16 | a control code that ends the message: new line, full stop and new line, or nothing |

The control codes (*read*; those marked were run through `RUN_MESSAGE`
with the output captured at `PRINT_CHAR`):

| Code | Handler | Prints |
|---|---|---|
| $00 | `MC_PUSHED_OBJECT` | an object whose record the caller pushed |
| $01, $04 | `MC_PUSHED_WORD`, `MC_PUSHED_WITH_ARTICLE` | a word the caller pushed (with an article) |
| $02 | `MC_JUMP` | jump by the signed byte after it -- location 66's description uses it to skip the other bank (*measured*) |
| $03, $09 | `MC_INSTRUMENT_NOUN`, `MC_INSTRUMENT` | the instrument |
| $06 | `MC_ACTOR` | the actor's name, or YOU (*measured*) |
| $07 | `MC_TARGET` | the target, with its article |
| $08 | `MC_BACKSPACE` | a backspace: joins the next word to the last |
| $0B | `MC_SUBMESSAGE` | run the message the signed byte after it points at |
| $0C, $0E | `MC_ACTOR_HIS`, `MC_TARGET_HIS` | HIS, or YOUR for the player (*measured*) |
| $0D | `PRINT_LITERAL` | a new line |
| $10, $11, $13 | `MC_ACTOR_IS`, `MC_TARGET_IS`, `MC_PUSHED_IS` | the name and IS, or YOU ARE (*measured*: YOU ARE, GANDALF IS, THORIN IS from one message) |
| $05, $0A, $0F, $12 | `MC_NOTHING` | nothing |

**How much it saves** (*measured* from the 177 messages, $AD7D-$B6D9, for
these notes): 2397 bytes hold 611 word references (3560 characters with
their spaces), 413 common-word bytes (1559 characters), 526 literals and 227
control codes -- about 5600 characters of fixed text, 2.4 to 1, before the
control codes print any names. Room and object names cost 6 bytes each (three
references) however long the words. Six places inside messages are entered
directly: five at an element boundary, sharing the rest of the message as a
tail -- the east bank's description is the end of the west bank's -- and one
on the second byte of a word reference, which it reads as a control code
(`MESSAGE_TAILS` in the build).

**Printing a word** (`PRINT_WORD` $74BA; *read*, and *measured* by calling
it with each flag value): expands the entry into `WORD_BUFFER` as lower-case
letters, by the rule that bit 7 on the first two bytes is class, not an end
([`dictionary.md`](dictionary.md)); adds an ending from `ENDINGS` when the
flags and the word allow; puts a space before it; and starts a new line
first if it would not fit on this one -- the story window wraps whole words.

**Agreement.** `ACTING` ($B6EA) is who the sentence is about, 0 for the
player. With the usual flags a word that can take an ending gets it when
`ACTING` is not 0: YOU TAKE, THORIN TAKES; YOU CARRY, GANDALF CARRIES (the
backspace-and-ies ending). *Watched*: while the game narrates the player no
verb inflects, while it narrates anyone else the inflectable verbs take their
-s. Flag $10 agrees with the target instead, $40 always inflects and $50
never does.

**Articles** (`ARTICLE` $743F; *read*): a noun reference's bit 7 marks a
proper name (Gandalf, Thorin), printed with no article and a capital -- except
YOU, which stays lower case. Otherwise bits 4-6 pick THE, A, AN or SOME from
`ARTICLES` ($AD2D); in the input window and while an action is being
narrated the second set is used, THE for everything but SOME ("you take the
curious map", not "a curious map").

**Sentences about actions** are not messages at all: `NARRATE_ACTION`
($712B) builds them from the action's pattern -- the actor, "cannot" if
refused, the verb or GO and a direction, the first object after its particle,
the second after its preposition, a full stop ([`actions.md`](actions.md)).
That is why what the other characters do reads so uniformly: Gandalf opening the green door and the warg going north-west come
out of the same template.

**When nothing is printed.** `PRINT_CHAR` ($858B) asks `PRINT_GATE` first:
only while `DOING_IT` (for real, not a test) and `PRINTING_ON` are both set.
Tests of an action, the characters out of sight, and the timers' quiet
housekeeping all run the same message code with the gate shut (*read*). A
capture at $858B therefore sees text never shown; capture past the gate, at
$858F ([`driving.md`](driving.md)).

**The wine.** While `DRUNK` ($B700) is set, `PRINT_CHAR` follows every S with
an H (*measured*, per the annotation: the Lonelands' description after
DRINK THE WINE). Five turns later timer 7 sobers the player up.

## How this was found

The bytecode was learned from the v1.0 disassembly's description (credited)
and read in v1.2's `RUN_MESSAGE`; Bag End's and location 4's descriptions
decoded to exactly what the game printed on arriving. The control codes were
run one by one with the output captured, and `PRINT_WORD` called with each
of the sixteen flag values (2026-09-18 and 2026-09-23). The compression
figures were counted for these notes with the build's own decoder.

## Confidence

*Read*, and *measured* for the codes and words marked. The build decodes
every message and checks that every pointer into the messages lands on a
start or a known way in.

## Disassembly corrections

- `RUN_MESSAGE`'s description counts "four at an element boundary" among the
  messages entered part-way through; the build's `MESSAGE_TAILS` has five
  (and its own comment says three, then a fourth). Corrected in the annotations 2026-09-27.

## Open questions

- `ENDINGS` gives EMPTY plain "ies", which would print EMPTYIES if it were
  ever inflected; not checked.
- Codes $00, $01, $04 and $13 take something the caller pushed; which
  callers use them was not listed here.
