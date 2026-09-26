# Scoring

**Question this answers:** where the score comes from, whether any action
scores, and whether 100% can be reached.

**Short answer:** only arriving somewhere scores. ARRIVE adds a place's entry
in `VISIT_SCORES` the first time the player gets there; fourteen places are
listed, worth 750 tenths of a per cent between them, so the most anyone can
score is 75%. No action -- taking an object, putting the treasure in the
chest, winning -- touches the score. The same is true of v1.0.

## How it works

`SCORE` ($B6F7) is a word in tenths of a per cent. Everything that touches it:

| Where | What |
|---|---|
| $6CCA, in START's set-up | `LD (SCORE),HL` with HL = 0: a new game scores nothing |
| $8401, `SHOW_SCORE` | read to print "you have mastered ... %" -- hundreds only if not zero, tens, a point, units |
| $8E61-$8E65, ARRIVE+40 | `LD HL,(SCORE)` / `ADD HL,DE` / `LD (SCORE),HL`: the **only** increase |
| START $6C14 / NEW_GAME $6C52 | block copies of the variables $B6EB-$B707, which include it, to $5F00 and back |
| DO_SAVE $84E8 / DO_LOAD $8457 | the same block to and from tape, so a loaded game keeps its score |

```
MOVE -> ARRIVE
          first visit? (bit 6 of the room record's byte 0, which MOVE sets)
          FIND_RECORD in VISIT_SCORES by location
          found: SCORE += its word            ($8E61-$8E65)
```

`SHOW_SCORE` is reached from `DO_SCORE` (the SCORE command), `DO_QUIT` and
`PLAYER_DIES`.

`VISIT_SCORES` ($8D6E) is `[location, score word]` records ending at $FF:

| Location | Points |
|---|---|
| 41 lower halls | 200 (20%) |
| 34 long lake | 100 (10%) |
| 13 goblins dungeon | 75 (7.5%) |
| 7 trolls cave, 65 a dark stuffy passage, 31 dark dungeon, 43 smooth straight passage | 50 each |
| 4 lonelands, 11 narrow place, 22 beorns house, 27 smothering forest, 28 levelled elvish clearing, 38 dale valley, 42 sidedoor | 25 each |

Total 750. Winning (`CHECK_WON`, the treasure held by the chest) goes through
`WAIT_AND_RESTART` into NEW_GAME, which sets the score back to 0 -- it does
not add anything first.

## How this was found

1. *Read:* the score routines, named while annotating.
2. *Watched*, on the original v1.2 snapshot, with a write watchpoint on
   `SCORE` (2 bytes, stop on change), driving the game by breakpoint (see
   [`driving.md`](driving.md)):
   - OPEN DOOR, E: stop at ARRIVE+44 ($8E65), 0 -> 25. Entering the Lonelands.
   - Treasure put in the inventory by memory, W, OPEN CHEST, PUT TREASURE IN
     CHEST: no write; the game is won and stops at `WAIT_AND_RESTART`.
   - Teleported to the dragon's halls (41), TAKE TREASURE, back to Bag End,
     into the chest: no write (the teleports skip ARRIVE, so the score stayed 0).
   - Every object the game lets the player take, one at a time from the same
     saved start -- golden key, map, rope, treasure, sword, ring, the three
     other keys, bow, arrow, food, barrel: no write for any.
   - *Played* properly to Rivendell with the map, gave it to Elrond and had
     him read it: the SCORE command said 2.5% before and after.
3. *Read,* exhaustively: the snapshot searched for every `F7 B6` (the address
   as the Z80 stores it). Exactly four, all in the table above. No `F8 B6`
   (the high byte on its own), no `LD H,$B6` or `LD L,$F7` building the
   address, and the only pointers to its neighbours ($B6F5, $B6F6) are used
   for one `CP (HL)` each.
4. *Read,* v1.0: found by the same instruction pattern
   (`2A nn nn 19 22 nn nn`) -- its score is at $B5E8, touched in the same
   three places, and its visit table is identical. See
   [`versions.md`](versions.md).

## Confidence

Confirmed. The code has one increase and it is reached only from ARRIVE; that
is read, watched and searched for independently, in two versions.

## Disassembly corrections

- `VISIT_SCORES` used to be fourteen `DEFB` triples. It is now generated from
  the game's own data by the build: each location a byte, written in the
  source as a constant named after the room (`LOC_LONELANDS`), each score a
  `DEFW`.

## Open questions

- Whether 750 was meant to be 1000 -- a place or two left out of the table,
  or points meant for actions -- cannot be told from the code. Claims that the
  golden key or the treasure score have been tested and are wrong for v1.0 and
  v1.2; other releases (other machines) are untested.
