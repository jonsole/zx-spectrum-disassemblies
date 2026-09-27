# The characters and how they act on their own

**Question this answers:** who the other characters are, how each decides
what to do every turn, how they react, and how the player's orders reach
them.

**Short answer:** each of the 17 characters is an ordinary object record
plus a 7-byte slot in `CHARACTERS` pointing into a small script. Every turn,
after the player, each slot runs its script: a step is an action the
character tries exactly as if it had typed it -- through the same parser
tables and the same `DO_ACTION` -- or a routine of its own. Refused steps
fall through to the next (or to a fallback); the first that works ends the
character's turn. Being given something, attacked or captured switches a
character to a reaction script; orders said in quotes replace its next step.
Almost nothing they do is scripted to happen in a particular room -- which is
why no two games play alike.

## How it works

### The slots

`CHARACTERS` ($CACB): 17 slots of 7 bytes, ending at $FF (*read*):

| Offset | Field |
|---|---|
| 0 | the character, or 0 for an empty slot |
| 1 | how many of its ordinary scripts `SCRIPT_RANDOM` may choose among |
| 2-3 | the step its script has got to |
| 4-5 | its script table: a `FIND_RECORD` table, key 0 for ordinary scripts, an action code for a reaction |
| 6 | how many of the player's orders it takes at once |

The cast, in slot order, as the tape has them (*read*, from the slots and the
object records; strength/defence and sides are the fight's, see
[`fighting-and-dying.md`](fighting-and-dying.md)):

| Slot | Character | Starts at | Str/def | Carries | Side | Orders |
|---|---|---|---|---|---|---|
| $CACB | Gandalf ($3E) | Bag End | 112/136 | 96 | player's | 5 |
| $CAD2 | Thorin ($3F) | Bag End | 104/120 | 80 | player's | 6 |
| $CAD9 | the wood elf ($40) | levelled elvish clearing | 64/48 | 255 | elves' | 1 |
| $CAE0 | the vicious warg ($43) | treeless opening | 55/55 | 48 | none | 0 |
| $CAE7 | the butler ($42) | elvenking's cellar | 32/112 | 48 | elves' | 1 |
| $CAEE | Elrond ($41) | Rivendell | 64/64 | 48 | player's and elves' | 5 |
| $CAF5 | Gollum ($44) | deep dark lake | 32/64 | 5 | goblins' | 3 |
| $CAFC | Bard ($46) | lake town | 96/96 | 16 | player's | 3 |
| $CB03 | the dragon ($3C) | lower halls | 192/192 | 96 | none | 0 |
| $CB0A, $CB11 | the hideous and vicious trolls ($47, $48) | trolls' clearing | 160/160 | 144 | none | 1 |
| $CB18-$CB3B | six goblins ($3D, $45, $4B, $49, $4A, $4C) | the goblins' tunnels | 72/96 | 48 | goblins' | 0 |

(The player is 64/64, carries 64, on the player's side.) The butler's,
Bard's and the dragon's slots are **empty on the tape**: their characters
enter the story when the player arrives at Beorn's house (the butler, made
visible too) or in the elvenking's cellar (the dragon and Bard), through
`ARRIVAL_HOOKS` writing their numbers in (*read*). Until then they are
objects that do nothing.

### A character's turn

`CHARACTERS_ACT` ($980E), for each slot in order (*read*):

1. Make the sentence about this character (`ACTING`, `ACTOR`, `ACTOR_AT`)
   and turn printing off.
2. If the player can see it (`ACTOR_IN_REACH`, the reach test the other way
   round), turn printing on -- unless the player is in the dark, when the
   first thing anyone does is reported as "you hear a noise." and nothing is
   printed ([`light-and-dark.md`](light-and-dark.md)).
3. Held by something (`CAPTIVE`): by a character, or by something broken,
   carry on; by something closed, do nothing; otherwise try CLIMB OUT OF it.
4. Note whether an order is waiting (`ORDER_WAITING`).
5. Run steps from where its script has got to until one succeeds, a pause
   or jump ends the turn, or six have been refused (`STEPS_REFUSED`).

So what a character does is decided and done whether or not anyone sees it;
the player is only told what happens in sight. The Inspector
(`hobbit-vscode/`) logs the rest -- a logpoint on `PRINT_CHAR` before its
gate sees even the sentences composed while testing, which is how it shows
what a character "only considered".

### Steps

A step's first byte: its low four bits are the opcode; bit 4 means a
two-byte fallback address follows, bit 5 that the step is used up once it
works, bit 6 that an order cannot interrupt it (*read*; `script_step` in the
build decodes every step, and the Characters page lists them):

| Opcode | Bytes | Does |
|---|---|---|
| 0, 2 | 4 | an action and its two objects, tried as the character's own sentence (`SCRIPT_DO`) -- $FF for an object means "whatever fits" |
| 1, 3 | 4 | a routine (bytes 1-2): run once as a test with printing off, and again for real only if it set `SUCCEEDED` |
| 4 | 2 | an action with no objects -- RUN, CAPTURE, ATTACK WITH: acts on whatever fits (`SCRIPT_BARE`); action $FF is a pause |
| $0E | 3 | go to the address that follows, and carry on |
| $0C | 2 | switch to its reaction script for the action that follows |
| $0F | 2 | switch to one of its ordinary scripts at random (the lesser of the operand and slot byte 1) |
| anything else | 1 | back to its first script; the turn is over |

A step that is **tried** goes through `ACTOR_TRIES` ($99C6): `WOULD_WORK`
tests it, then `DO_ACTION` does it -- the same checks as the player's
commands, the same handlers, the same narration (*read*). "... enters." and
"... appears." are printed when someone comes into the player's view.

**Bit 5 spends the step, not the character.** `SCRIPT_DO` at $996E writes 0
over the first byte of the step it has just run, so it no longer calls its
routine: as opcode 0 it reads as an action made of the routine's address
bytes, which names no real object (what trying it would do was not
followed; Thorin's script only reaches it again if he takes the key again).
Only one step has the bit:
Thorin's remark about the small curious key. *Measured* 2026-09-27: the key
put in Bag End, Thorin took it, said his line once the turn after, and went
on following and chatting; his slot kept his number, and the byte at $C8FB
went from $23 to $00. The scripts are not part of what a new game restores,
so a spent step stays spent until the game is loaded again (*measured*: after
QUIT and a new game, $C8FB was still 0 while the key was back in the
goblins' cache).

### Reactions

`REACT_TO_ACTION` ($95DF), from `DO_ACTION`: when something is done to a
living character, `REACT` looks the action up in its script table and, if
there is an entry, moves its script there (*read*). The tables have
reactions to ATTACK WITH ($0F), GIVE TO ($1D) and, for Gandalf, CAPTURE
($30). Hitting Thorin, for instance, sends him to the shared attack script.

### Orders

SAY TO X "..." (TALK TO) files each quoted command in `ORDERS`
([`parser.md`](parser.md)). `DO_TALK` ($9034) decides how many X accepts
(*read*): none if X has no slot (dead, or not yet in the story); exactly one
for Gollum while he waits for his riddle's answer; none, silently, if slot
byte 6 is 0; otherwise `RANDOM_POSITIVE` up to byte 6 -- and if that comes
out 0, X says no. `ASSIGN_ORDERS` gives it that many and throws the rest
away. On X's turn, an order waiting and a step without bit 6 means the
order is parsed (`TAKE_ORDER`) and done instead of the step. So Thorin, with
6, usually does what he is told, but sometimes refuses outright, and never
while on an uninterruptible step.

**Bard** handles orders differently (*read*): his ordinary script is
`BARD_TAKES_ORDER` and one step at $C9E2, both uninterruptible. The routine
parses a waiting order and writes its action and objects into that step,
which he then tries every turn until it works -- so SAY TO BARD "SHOOT THE
DRAGON" is carried out as soon as it can be. On the tape the step is TAKE
THE WOODEN CHEST. Because it is rewritten, SAVE and LOAD carry its three
bytes in the variables block; a new game does not restore it, so Bard starts
the next game with the last order he was given (*read*).

### Who does what

The scripts in outline (*read*, from the build's decode):

- **Gandalf** starts by giving the player the curious map and opening the
  round green door, then wanders: run somewhere, take whatever he can (and
  ask "what's this ?" about it), close something, give something away, drop
  something, chatter, open something, and pick one of these again at random.
  That is why he takes the map back in the Lonelands and gives it back later.
- **Thorin** follows the player. When he cannot (they are already together),
  he tries to take the small curious key, then, if the player is invisible,
  asks where the thief is, and otherwise chats, waits or sings about gold.
- **The trolls** say their lines at the end of the turn the player enters
  their clearing. On each of the next four turns each troll tries to eat
  the player if the player is still there (`TROLLS_EAT` $A94E: the troll's
  EAT is narrated and done by calling `DO_EAT` itself, and the routine then
  jumps to `PLAYER_DIES` -- the player's own EAT handlers, `DO_EAT` then
  `PLAYER_DIES`, are not used; *read*, corrected 2026-09-27); a failed try
  falls through to a pause, so each try is a turn. The fourth failed try
  falls through to `TROLLS_TURN_TO_STONE` in the same turn: "day dawns", and
  both are killed, hidden and drop what they hold (the large key), and the
  clearing gets its daytime description and picture colours. *Measured*
  2026-09-27: into the clearing, out south-east at once, then WAITs: dawn
  came at the end of the fourth turn after the one that entered.
- **Elrond** says hello when the player is with him, then gives the player
  lunch, then waits two turns and starts again. Attacked, he fights back
  until refused. He reads the map for the player
  ([`hidden-roads.md`](hidden-roads.md)).
- **Gollum** asks his riddle when the player is with him and can be seen,
  expects the answer as an order the next turn (`GOLLUM_HEARS_ANSWER`: the
  answer word anywhere in it, or he strangles the player), and otherwise
  wanders north and south-west around his lake, taking and dropping the ring
  and asking what the player has in its pockets. Attacked, he puts the ring
  on and runs.
- **The wood elf** captures whatever it can and runs; its captives go to the
  elvenking's dark dungeon (31).
- **The butler** unlocks, opens, closes and locks the red door with the red
  key; when he cannot, he captures, and when he cannot do that either he
  works through the barrels: opens the barrel, drinks the wine, closes it,
  opens the trap door, throws the barrel through, closes the trap door.
- **The vicious warg** attacks whatever it can; failing that follows someone
  and howls, or runs, or waits.
- **The goblins** patrol their tunnels (up, down, north, south through the
  small crack) capturing anyone they meet into the goblins' dungeon (13);
  three of them just run, attack and capture. A goblin killed "falls down a
  hole" and comes back to life in its own place (`GOBLIN_RETURNS`, from
  `GOBLIN_HOMES`) -- there are always six.
- **The dragon**, once in the story, first tries `DRAGON_HUNTS`: once the
  treasure has left the lower halls, wherever the player is in a lit place
  it is seen flying after them four times in five, and otherwise burns them
  to a crisp. While the treasure is still in its hall (or the player is in
  the dark) that step is refused, and the fallback takes over: if the player
  is at the front gate, in the lower halls or on the lonely mountain, the
  dragon follows them there, threatens, and burns; anywhere else it runs.
  Only Bard's arrows hit it, and a hit kills; in a plain fight its defence of
  192 is beyond the player even with the sword
  ([`fighting-and-dying.md`](fighting-and-dying.md)).
- **Bard**: see Orders above.

## How this was found

The slots and the step format were read from `CHARACTERS_ACT`, `SCRIPT_DO`,
`SCRIPT_BARE` and the build's decode of every step, which the build proves
by requiring every byte from $C82D to `TIMERS` to be a table or a step
(2026-09-23). `MOVE` running 21 times for nine characters in one INVENTORY
turn was the first sight of the cast acting (2026-09-18). For these notes the
step decode was dumped with each step's fallback, and Thorin's one-shot, the
trolls' dawn and Elrond's lunch were run in the simulator.

## Confidence

The mechanism is *read*, and every character's first steps were *played* in
the build's walkthrough and in the 2026-09-25 playthrough to Rivendell.
Thorin's spent step and the trolls' dawn are *measured*. The per-character
summaries are *read* from the decoded scripts; the dragon's and Gollum's
were not run.

## Disassembly corrections

- `SCRIPT_DO`'s description ("A step that succeeds with bit 5 set takes the
  character out of the story: its slot is emptied and it never acts again")
  and its comment at $9967, `CHARACTERS`' description ("a character whose
  part is over ... empties its own"), the ref's "Leaving the story" paragraph,
  and the build's step text "(then its part in the story is over)" and
  script preamble ("$20 that the character's part is over once it works")
  are all wrong: `LD (IX+$00),$00` at $996E clears the step's own first
  byte, IX being the step. The character goes on. *Measured*; all corrected 2026-09-27.
- `KILL`'s comment at $97A0, "Not yet worked out", is the calls of
  `BROKEN_OR_DEAD` (named DEAD) and `CANCEL_ORDERS`. `REACT_TO_ACTION`'s
  "bit 3, which is not yet worked out" is dead or broken. Corrected 2026-09-27.
- The order limits in `CHARACTERS`' description leave out Bard (3), the
  butler (1) and the dragon (0). Corrected 2026-09-27.
- Not corrected: `hobbit-vscode/hobbit_model.js` still labels a bit-5 step
  "then its part in the story is over" (and the Inspector's README says the
  same); that extension was outside what this pass could edit.

## Also found for the animations page (2026-09-27)

- Fifty turns of WAIT from the start (the Animations page's roaming map): on turn 14 the nasty goblin captured Gandalf into the goblins' dungeon (13), where he stayed; on turn 35 the warg attacked the wood elf (57 against 57, wasted); on turn 36 the wood elf captured the warg into the dark dungeon (31) (*measured*, replays stopped at $A41D and $91C1).
- A troll that eats the player dies of gluttony: 160 + 10 reaches 128, and its dead flag was seen set (*measured*).

## Open questions

- What makes a step "whatever fits" choose among several objects: the order
  of the object index, by `MATCH_AND_TRY`, is *assumed*.
- `GOLLUM_POCKETS`' choice between its two lines, and `ACTOR_TRIES`' 77 bytes
  at $99E5 marked "not yet worked out" (two ways into `NARRATE_ACTION`).
