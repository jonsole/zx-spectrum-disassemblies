# Actions: from a command frame to something done

**Question this answers:** how a parsed sentence becomes an action, how the
game decides which objects the names mean, and who carries the action out.

**Short answer:** an action is a place in `ACTION_PATTERNS`: 59 sentence
shapes (TAKE, TAKE OFF, TAKE OUT OF, PUT IN...), and the action code is the
shape's number. The names are not resolved up front: every object that fits
is *tried*, by running the real handler with a "test only" flag down, until
one would work. `DO_ACTION` then runs it for real -- first asking the
objects whether they carry a handler of their own, and only then the
ordinary one in `ACTION_TABLE`. The player and every other character go
through exactly this code.

## How it works

```
PARSE_ACTION $79B6
  MATCH_PATTERN $7B9E    probe = verb + particle + preposition from the frame;
                         search ACTION_PATTERNS with NAME_MATCHES
                         no pattern: "you ... . time passes..." (a turn)
  action code = pattern number, into ACTION ($B6E7)
  PATTERN_OPTIONS $7B78  light needed? is an object a place?
  ASSIGN_PHRASES $7C23   which phrase is the target, which the instrument
  MATCH_AND_TRY $7A14    for each object fitting the target's name,
                           for each fitting the instrument's:
                             try it (DOING_IT = 0: only a test)
                         stop at the first that would work
  nothing worked: TARGET_TROUBLE  say why (and drop the rest of the line)
OBEY
  NARRATE_ACTION $712B   "you take the curious map."
  DO_ACTION $950F        for real
```

(*read*; the parts named on 2026-09-23.)

**Patterns** (`ACTION_PATTERNS` $AB53, *read*): eight bytes each -- a verb, a
particle and a preposition as word references, and a fourth word; the list
ends at a zero word. Codes 1-10 are the directions, each with GO as its
fourth word, so NORTH and GO NORTH are one action and all ten go to `MOVE`.
The top nibbles of the four references are the pattern's flags, gathered by
`PATTERN_FLAGS` into `FLAGS_FIRST_WORDS` ($B71D) and `FLAGS_LAST_WORDS`
($B71E): whether there is a target and an instrument to find, what kind of
object each may be (things, characters or either -- `FIND_MODE`), whether
the action is narrated at all (not for LOOK and INVENTORY), whether it needs
light (TAKE, OPEN, EXAMINE, LOOK, INVENTORY and the other hands-on ones), and
whether the target is a place rather than an object (ENTER, GO INTO). The
full list, with each code's handlers, is the generated Actions page.

**Which phrase is which** (`ASSIGN_PHRASES`) is decided by the prepositions,
not the order typed: the phrase carrying the preposition the pattern wants
is its instrument, wherever it came. The target's name is kept in
`IT_NAME` for IT.

**Test, then do.** `DOING_IT` ($B6FA) clear means "only a test". Every
handler makes its checks and then calls `FOR_REAL` ($9D44): in a test that
sets `SUCCEEDED` ($B6FB) and leaves the handler, so nothing changes and
nothing is printed (`PRINT_GATE` also needs `DOING_IT`). One copy of each
rule decides and does. `MATCH_AND_TRY` counts what fitted and what failed
(`TARGETS_FOUND`, `TARGETS_FAILED`...), so that when only one thing fitted,
the refusal the player hears is that thing's own ("the door is locked.");
several fitting and none working asks "which ... ?"; none fitting says the
thing is not here.

**`DO_ACTION` ($950F)** (*read*):

1. `SENSIBLE`: nothing done to itself, or an object to itself.
2. In the dark only what the actor carries can be used, and an action that
   needs light is refused outright ("i see nothing here."; see
   [`light-and-dark.md`](light-and-dark.md)).
3. **The objects first.** `FIND_OBJECT_HANDLER` looks in the object's own
   record for a handler keyed by the action code. For DROP IN, PUT IN,
   PUT ON, TAKE OUT OF and THROW THROUGH (`SECOND_FIRST` $A20B) the second
   object is asked, since the container or the gap decides; otherwise the
   first.
4. No handler of the object's own: the ordinary one from `ACTION_TABLE`
   ($C730).
5. Any records keyed 0 straight after the handler that ran are run too --
   the wine's DRINK is followed by `WINE_DRUNK`, the web's STRIKE WITH by
   `WEB_BROKEN`, the trap door's THROW THROUGH by `BARREL_THROWN`. They use
   `ONLY_IF_DONE` to act only when the handler really worked.
6. Each object that is a living character reacts (`REACT_TO_ACTION` ->
   `REACT`, [`characters.md`](characters.md)).

**Who handles what** (*read*, from `ACTION_TABLE` and the 61 object records;
the build decodes both):

| | Actions |
|---|---|
| **Ordinary handler** in `ACTION_TABLE` | the ten directions (`MOVE`), TAKE and CARRY (`DO_TAKE`), DROP, ATTACK WITH, LOOK, INVENTORY, EXAMINE, GIVE TO, ENTER and GO INTO (`DO_ENTER`), RUN, FOLLOW, THROW AT, CAPTURE (then `NOTE_LIGHT`), UNTIE, TIE TO, BURN, TALK TO, SHOOT, CLIMB OUT OF |
| **Only objects' own handlers** | STRIKE WITH, OPEN, CLOSE, LOCK WITH, UNLOCK WITH, GO THROUGH, LOOK THROUGH, THROW THROUGH (doors and the like); PUT IN, DROP IN, TAKE OUT OF, CLIMB INTO, EMPTY, FILL WITH, JUMP ONTO (containers); DRINK (the liquids); EAT (food, lunch -- and the player); LOOK ACROSS, SWIM (the rivers); WEAR, TAKE OFF (the ring); THROW ACROSS, PULL (the rope); DIG (the sand) |
| **No handler anywhere** | PUT ON, TAKE FROM, THROW, CUT, CLIMB |

So opening something is only possible if it carries OPEN: a door that does
not is not a door. And the five with no handler at all can never be done:
*measured* 2026-09-27, PUT MAP ON CHEST, TAKE MAP FROM CHEST, THROW MAP and
CUT MAP each got "i cannot do that." (`DO_PUT_IN` has a branch for PUT ON,
letting a thing be put *on* a closed container, which nothing can reach.)

**The player's own record** carries EAT, with `PLAYER_DIES` after it under
key 0: that is how the trolls eat the player (`TROLLS_EAT` has the troll EAT
the player) -- `DO_EAT` then the death. The wall carries PUT IN with a
handler of $0000, which `RUN_ROUTINE` treats as nothing to run (*read*).

**Narration.** `NARRATE_ACTION` builds the sentence from the pattern -- who,
"cannot" if refused, the verb (or GO and the direction; GO SOMEWHERE in the
dark), the first object after its particle, the second after its
preposition -- so the player's actions and everybody else's are told by one
routine from the same patterns ([`messages.md`](messages.md)).

## How this was found

`ACTION_TABLE` was the first dispatch found (2026-09-18, by watching `MOVE`
run 21 times in one turn for nine characters); `ACTION_PATTERNS` gave the
codes their meanings, and the object records' grammar -- a 16-byte head, the
places, then a `FIND_RECORD` table of handlers -- was stated by
`FIND_OBJECT_HANDLER` itself and proved by every record ending where the next
begins (2026-09-23). The table above was computed from both for these notes,
and the five handler-less actions tried in the simulator.

## Confidence

*Read* and, for the dispatch, *played* (29 of 31 `ACTION_TABLE` handlers ran
in the build's playthrough). The handler-less actions are *measured* for
four of the five; CLIMB alone asks what to climb before it gets that far.

## Open questions

- `WOULD_WORK`, `WANTS_INSTRUMENT` (renamed from `WANTS_TARGET`: it asks about the instrument, bit 2 of $B71D) and `SEARCH_START` have parts still marked
  "not yet worked out" in the annotations: the order of `MATCH_AND_TRY`'s
  fall-backs is not fully traced.
- `PATTERN_OPTION` ($B70F), set for TAKE OFF, FOLLOW and JUMP ONTO, changes
  how the objects are matched; exactly how is not worked out.
