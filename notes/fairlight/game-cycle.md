# The title, a game and GAME OVER

**Question this answers:** what runs between games -- the title, the start
of a game, its end -- and the small routines that read the keys and the
joystick and colour and copy the screen.

**Short answer:** `TITLE_SCREEN` ($F065) is a loop that is never left:
the title (room 79 with the title page), a key, the master copies restored
(`NEW_GAME`, $F089), the knight's record reset and the start room entered
(`TELE`, $F09B, then `ROOMST`); when the game ends `ROOMST` returns, EEN
saves the room's things, GAME OVER is shown over room 1, a key, and round
again. A game ends when LIFE reaches 00, on SYMBOL SHIFT and 0, or after
the end of the quest in room 81.

## How it works

```
TITLE_SCREEN $F065   ROOM saved; ROOM = 79; DRAW_CURRENT_ROOM; ROOM restored;
                     ATTRI; TITLE_PAGE_TEXT $B686; "9-JOY" (Release 2); PAUS
NEW_GAME     $F089   the master object table (1200 bytes) and variables (61) back
TELE         $F09B   the master knight's record back, all but +14; ROOMST $FD20
                     (returns at LIFE 00, on SYMBOL SHIFT and 0, or after room 81)
             $F0AF   EEN $F906; ROOM = 1 drawn; GAME OVER; ATTRI; WAIT; round again
```

Restoring `ROOM` round the title's drawing is redundant: the master
variables set it a moment later (to 29, where every game starts). `TELE` is
also where the thing of kind 9 sends the knight, after writing room 30 to
`ROOM` ([`main-loop.md`](main-loop.md)); the author's name for it is in his
symbol table. The routine's own name is lost but for its last letter, G
([`symbols.md`](symbols.md)).

The small routines, all the author's names:

| Routine | What |
|---|---|
| `WAIT` $F0D2 | Until no key, then (`PAUS`, $F0D8) until a key; A = 0 reads every half-row |
| `INPUT` $F0DF | `IN A,($FE)` with A the half-rows to read; a bit per key held, Z if none |
| `IN31` $F0E6 | Nothing unless bit 3 of `OPTIONS` ($FF86); else three reads of port $1F ORed: right, left, down, up, fire (Release 1's is `XOR A : RET`) |
| `ATTRI` $F0FB | All 768 attributes set to `ROOM_COLOUR` |
| `RESTOR` $F10B | The 6144 bytes of the screen's bitmap to the clean copy at $C000 |

## How this was found

Read (stage 2, range 3); Release 1's routine compared by aligning its bytes
with Release 2's (the matching runs found by search in its snapshot).
*Measured* in the build's sessions: GAME OVER and the title again, and the
end of the quest failed and succeeded; SYMBOL SHIFT and 0 reached $F0AF.

## Confidence

*Read*, and *measured* as above.

## Krumlinde

His `RTN_Title_Screen_Loop` for $F065 is right as a loop; his
`RTN_Reset_And_Enter_Room1` for $F09B is not: it enters the room in `ROOM`
(29 for a new game, 30 for the kind-9 thing), and room 1 is drawn after the
game as GAME OVER's backdrop. His open question -- where the first launch
into the main loop comes from -- is answered here: `TELE` calls `ROOMST`,
inside which the main loop runs. The interrupt he describes as active is
off ([`start-up.md`](start-up.md)).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `TITLE_SCREEN` | `SUBF065` | $F065 | The title, a game, GAME OVER; `NEW_GAME` and `TELE` inside |
| `WAIT` | `SUBF0D2` | $F0D2 | The author's; `PAUS` inside |
| `INPUT` | `SUBF0DF` | $F0DF | The author's |
| `IN31` | `SUBF0E6` | $F0E6 | The author's: the Kempston port |
| `ATTRI` | `SUBF0FB` | $F0FB | The author's |
| `RESTOR` | `SUBF10B` | $F10B | The author's |

## Open questions

- Why `IN31` reads the port three times.
- The title routine's own name, of which only the final G survives.
