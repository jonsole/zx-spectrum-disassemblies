# The dictionary and word matching

**Question this answers:** how the game stores its words, how a typed word is
found, and how the same store serves the text the game prints.

**Short answer:** words are packed a letter to a byte, five bits of letter
and three of class and flags, in two lists within the 4 KB from $6000: 355
words the parser reads (indexed by initial letter, 29 of them synonyms that
stand for another), and 207 more that only the messages print. Everything
else in the game names a word by a two-byte *word reference*: a 12-bit
offset from $6000 and four bits of flags. A typed word may be shortened
freely and lengthened a little.

## How it works

**The format** (*read*, and proved by the build: every bucket and every
synonym link lands on an entry's first byte):

| Byte | Bits 0-4 | Bits 5-6 | Bit 7 |
|---|---|---|---|
| 0 | letter (A=1 ... Z=26) | high half of the class | -- |
| 1 | letter | low half of the class | the word can take an ending |
| 2 on | letter | (on the last: bit 6 = a synonym link follows) | last letter |

A synonym's last letter is followed by a two-byte offset from $6000 to the
word it stands for. Because A is 1 -- the low five bits of ASCII "A" -- the
game gets a letter's code from a typed character with a single `AND $1F`.

**`WORD_INDEX`** ($6000): 26 offsets, one per initial letter (X and Z have
none). **`WORD_LIST`** ($6040-$67AA): the 355 words, grouped by initial but
not sorted within a group (BLOW comes before BLOOD), so a lookup is a linear
scan of the bucket, which ends when an entry's initial stops matching. The
classes, which become a token's top nibble (*read*; counts from the build's
decode):

| Class | Words | Class | Words |
|---|---|---|---|
| $0 adverb | 13 | $6 adjective | 96 |
| $1 IN, INTO | 2 | $7 preposition | 16 |
| $2 direction | 19 | $8 article and the like | 11 |
| $3 verb | 59 | $9 quantifier, pronoun, game command | 14 |
| $4 GO, RUN | 2 | $A AND | 1 |
| $5 noun | 121 | $B THEN | 1 |

**`SECOND_LIST`** ($67AB-$6BEE, zeros to $6BFF): 207 words packed the same
way, 44 of them able to take an ending, reached by no index and no pointer:
a message names each by its own offset. The parser's list is what you type
into; this one is what the story is written from ([`messages.md`](messages.md)).
Found with a read watchpoint over the range, which stays untouched until a
sentence about an object is composed.

**Synonyms** are resolved in the tokeniser, so nothing downstream ever sees
them (*read*; the pairs from the build's decode). Some matter to a player:

| Typed | Is | Consequence |
|---|---|---|
| READ | EXAMINE | READ MAP is EXAMINE MAP -- which is what Elrond does ([`hidden-roads.md`](hidden-roads.md)) |
| SAY | TALK | SAY TO THORIN "..." is TALK TO |
| CAPTURE | ATTACK | the player cannot capture anyone: CAPTURE THORIN attacks him |
| KILL, HIT, SLASH, SLICE | ATTACK | |
| BREAK, SMASH | STRIKE | |
| GET, LIFT, STEAL | TAKE | PICK is CARRY |
| EVERYTHING, BUT | ALL, EXCEPT | |
| ME | YOU | |
| I; L, LO | INVENTORY; LOOK | N, S, E, W, NE, NW, SE, SW, U, D are the directions |

*Measured* 2026-09-27: READ MAP answered as EXAMINE MAP, and CAPTURE THORIN
was narrated as an attack on Thorin -- who killed the player with one blow in
reply ([`fighting-and-dying.md`](fighting-and-dying.md)).

**Matching a typed word** (`TOKENISE` $6E97, `MATCH_WORD` $6F47,
`LETTERS_AGREE` $6FBA; *read*): the typed word is copied as letter codes up
to the first character below $40, and each entry in its bucket unpacked
beside it. They must agree over the shorter length. A typed word no longer
than the entry is an abbreviation and is taken; a longer one only if the
entry has at least four letters and the next candidate does not also agree.
*Measured*: INV is INVENTORY and EXAM is EXAMINE; MAPS is not a word (MAP
has three letters) and neither is EXAMINING (its seventh letter disagrees);
the annotation's tests add SWORDS for SWORD and INT for INTO. An unknown word
stops the line with "i do not know the word" and the word echoed.

**The word reference** is the currency of the whole game: tokens, command
frames, object and room names (a noun and two adjectives), action patterns
and messages all hold words this way. The low 12 bits are the offset; the
top four are flags whose meaning depends on the reader:

- in a message, `RUN_MESSAGE` reads 2, 3 and 6 as "end the message here"
  ([`messages.md`](messages.md));
- in a name, `ARTICLE` reads bit 7 as a proper name and bits 4-6 as which of
  THE, A, AN, SOME it takes;
- `PRINT_WORD` reads $40 as always inflect, $50 never, $10 agree with the
  target, anything else with the actor; $70 also sets the next letter
  capital;
- in an action pattern, they are the pattern's options
  ([`actions.md`](actions.md)).

**Endings.** A word that can take one (bit 7 of byte 1) names it in bits 5-7
of its third byte, from `ENDINGS` ($B71F): s, es, ies, d, ing, and a
backspace followed by ies, which is how CARRY becomes CARRIES. The ending is
added when the sentence is about someone other than the player, so verbs
agree with their subject ([`messages.md`](messages.md)).

## How this was found

The dictionary was the first thing decoded (2026-09-17): the synonym links
landing exactly on entries proved the format. Reading on past the index into
the second list gave 133 words the wrong class, which is how the boundary
at $67AB was noticed; the watchpoint then showed what reads it (2026-09-18).
The class nibble was first read as three bits, which made verbs look unlike
everything else, and corrected by watching tokens from real sentences
(2026-09-23).

## Confidence

The format is *read* and proved by the build's all-or-nothing checks. The
matching rule is *read* and *measured* on the words above. The class names
come from the words in each class; seven of the twelve were also seen as
tokens in real sentences.

## Open questions

- What the eleven entries of class $8 ("article and the like") beyond the
  articles are for has not been gone through word by word here.
