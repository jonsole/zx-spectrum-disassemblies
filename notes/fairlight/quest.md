# The quest and how a game ends

**Question this answers:** what the game asks of the player, as the code
decides it: how the quest is won or failed, and the other ways a game ends.

**Short answer:** a game starts in room 29 with LIFE 99. It is won by
walking into room 81 carrying thing 5 of the object table (type 15, which
lies in room 33) in any of the five places; entering room 81 without it
fails the quest. Either way the verdict is printed, then two lines saying
the quest continues in the sequel, and after a key, GAME OVER. A game also
ends when LIFE reaches 00, or on SYMBOL SHIFT and 0. On the way, 21 doors
need a key -- things 1-8 of the object table -- and room 61's door needs
the kind-11 thing lying in the room.

## How it works

- **The end** (`ROOMST`, $FD20, room 81): room 81 drawn and coloured; the
  five places searched for a record whose +19 is 5 -- success if one is,
  failure if not (an empty place reads a record at address 0, whose +19 is
  a ROM byte, $FF, and never matches); the verdict printed; `MESS2`
  ($DFF2) prints its two lines; `JP WAIT`; and `ROOMST` returns to
  `TITLE_SCREEN` for GAME OVER ([`game-cycle.md`](game-cycle.md)). Which
  doors lead into room 81 is in the object table
  ([`doors.md`](doors.md)).
- **LIFE** is two digits, 99 at the start. It goes down 10 for a touch of
  something that hurts, 1 for running into a fighter, 3 a pass for a
  winged creature's strike, 1 a pass for each pass of a fall over 20, and to
  00 at once for a pit's floor ([`meeting.md`](meeting.md),
  [`object-states.md`](object-states.md), [`knight.md`](knight.md)). It goes
  up by using things of kind 4 (+10) and 6 (to 99)
  ([`main-loop.md`](main-loop.md)).
- **Keys** ([`doors.md`](doors.md)): six things of type 14 (1-4, 6 and 8),
  thing 5 (the quest's) and thing 7 (type 50, kind 11) each open at least
  one door.
- **Room 61**: its figure (state 15) stays still until thing 7 (kind 11)
  lies in the room, and then becomes a wraith for good; its one door, a
  hole down to room 60, works only while thing 7 lies there. The door up
  into it from room 60 needs thing 7 as its key.
- **Things lost**: a thing the ghost takes, a decoy a guard takes, and a
  wraith destroyed with the thing that did it are moved to room $FE in the
  object table: gone for the rest of the game. Things used are gone too.

## How this was found

Read (stage 2, ranges 4 and 5), and *measured* in the build's sessions:
"the end of the quest" (room 81 entered: failed) and "the quest done" (thing
5 fetched from room 33 and carried into room 81: succeeded). The keys by
walking the object table (stage 3).

## Confidence

The verdict's test: *read* and *measured* both ways. What the things are
called is not in the game: the object table has no names.

## Open questions

- What the story on the inlay calls thing 5 (whose picture has a spiked,
  crown-like top) and thing 7 (a book, by its picture). The README's
  "Book of Light" is the story's; which thing the game treats as it is not
  settled by the code alone.
