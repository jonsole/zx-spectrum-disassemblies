# The main loop and timing

**Question this answers:** what the game does in a pass of its loop, what is
tied to the 50 Hz frame and what is not, and how long a pass takes.

**Short answer:** there are two rates. `MAIN_LOOP` ($7DC3) runs flat out: it
dispatches the objects in the player's room, every monster wherever it is,
and every door and piece of furniture in the room, then does the per-pass
housekeeping. Between records it checks the ROM's FRAMES counter, and each
time it has moved it calls `FRAME_TICK` ($7EB2), which updates the player,
the weapon and the sound slot and ticks the clock. So the player moves once
a frame whatever else is happening, while monsters move once a pass -- and a
pass in the starting room takes about 1.7 frames.

## How it works

```
ENTRY $6000 -> TITLE_SCREEN $7C19 -> (key 0) START_GAME $7D9A -> ARRIVE_IN_ROOM $9147 -> MAIN_LOOP

MAIN_LOOP $7DC3        SP = $5E00, EI, ACTORS_HERE = 0
  (first pass in a room: skip the next two walks)
  $EAA8-$EE5F, 8 bytes  each record in the player's room -> DISPATCH_ACTOR
                        between records: FRAMES moved? -> FRAME_TICK
  MAIN_LOOP_MONSTERS    $EE60-$EEDF, 16 bytes, every record -> DISPATCH_ACTOR
                        (the same frame check between them)
  ROOM_LIST_PASS $7E23  each entry of the room's list -> DISPATCH_FROM_LIST
  then                  TICKS + 1
                        first pass: DRAW_ROOM_CONTENTS, mark the room drawn
                        RUNNING_SUM += FRAMES + TICKS
                        READ_PICKUP_KEY (the pick-up key), PAUSE (pause),
                        REGROW_FOOD (food regrowth)
                        player in room $8E? -> SHOW_END_SCREEN
                        JP MAIN_LOOP

FRAME_TICK $7EB2       DI; $EA90 player, $EA98 weapon, $EAA0 sound slot -> dispatch
                       TICK_CLOCK; LAST_FRAME = FRAMES; EI
```

(*read*.) The dispatch is a jump, not a call: the loop leaves its return
address in HL and `DISPATCH_ACTOR` pushes it ([`records.md`](records.md)).
Because the stack is reset at the top of every pass, a handler may abandon
its caller -- `LOSE_FOOD_SIXTEEN` and `LOSE_FOOD_EIGHT` pop a return address and jump
to `LOSE_LIFE` (*read*).

**Two rates** (*read*; *measured*):

| Runs | What | Rate |
|---|---|---|
| once a frame | the player (movement, fire, spawning, the life-force drain), the weapon, the sound slot, the clock | 50 Hz; 500 `FRAME_TICK`s took 510 TV frames in the starting room -- the room-list walk and the end-of-pass work check FRAMES nowhere, so a frame that passes entirely inside them is missed (*read*) |
| once a pass | objects and creatures in the room, the five big monsters everywhere, doors and furniture in the room, TICKS | about 23 passes a second in room $00 at the start (233 passes in 510 frames) |

So a crowded room slows the monsters, not the player; and anything counted
in TICKS -- the life-force drain's gate, trapdoors, timed doors, the food
regrowth, animation phases -- runs at the pass rate, not in seconds.

**What a pass costs** (*measured*, 2026-09-27, three passes in room $00 with
no creatures, the player standing, stepped instruction by instruction in the
Python simulator): 116,000 T-states on average (100k-162k over forty
passes), 1.66 frames. The largest shares: the loop's own walk over the 119
eight-byte records with a FRAMES check between each, 20%; `INERT_SPRITE`'s
deliberate delay in the three empty monster slots ($C0 turns of a
DEC/test loop each), 14%; the player's walk test against the room's
doorways (`TEST_ROOM_BOXES`, twice a frame), 11%; the doors' and furniture's
colours, redrawn every pass, about 15% across the eight colour drawers.
`FRAME_TICK` itself costs 21-24k T-states with the player standing.

**The first pass in a room** (*read*): `DRAW_ROOM` clears `ROOM_DRAWN`
($5E14). While it is clear, the loop skips objects and monsters, dispatches
the room list (whose handlers draw the doors and furniture in full) and then
`DRAW_ROOM_CONTENTS` draws every object and monster in the room once; after
that the furniture's handlers repaint only their colours
([`drawing.md`](drawing.md)).

**The clock** (`TICK_CLOCK` $95DA, *read*): whenever FRAMES is 50 or more, 50
is subtracted from it and the seconds go up, so the game rewrites the ROM's
own counter and FRAMES stays below 50 during play. Seconds and minutes are
BCD, hours one digit.

**Pause** (`PAUSE` $9489, *read*, then *measured*): once a pass, with
interrupts off, SPACE on its own (not with B, N, M or SYMBOL SHIFT) waits for
SPACE to be released, pressed again and released. FRAMES does not move, so
the clock stops too. In the simulator, a tap of SPACE left the game in the
loop at $94A1 with the clock unchanged three seconds later; a second tap
carried on.

**Game over and the end** (*read*; *measured*): `GAME_OVER` ($8C35) and
`SHOW_END_SCREEN` ($96EC) both end in `END_DELAY` ($8C4A), twenty times round
a 65536-count loop, and then `TITLE_AGAIN` ($7C29). From `GAME_OVER` to the
title took 9.8 seconds of emulated time (twenty times 65536 x 26 T-states is
9.7 s). The interrupts are off during that delay only when the last life went
inside `FRAME_TICK`, which starts with DI -- a death by hunger -- and
during the end screen, which follows `PAUSE`'s DI in the same pass. A death
in the main loop's own dispatch -- a creature's touch, a big monster, a
mushroom -- reaches `GAME_OVER` with interrupts on, and FRAMES counts through
the delay and the title screen that follows (*measured* live, 2026-09-27:
iff1 on at `GAME_OVER` after a devil's touch, FRAMES $2531 there and $2726 at
the title; iff1 off and FRAMES unmoved after a hunger death and after a win).
That decides whether the next game's cyan key can move: see "Fewer castles
than it seems" on the Bugs page and [`loading.md`](loading.md).

## How this was found

Read `MAIN_LOOP`, `FRAME_TICK` and the routines they call. Measured with the
harness in the scratchpad (`aticatac_sim.py`): passes counted from TICKS
across 500 stops at `FRAME_TICK`, pass lengths from successive stops at
$7DC3, and a per-routine T-state histogram by stepping SkoolKit's Python
simulator and charging each instruction to the labelled entry containing it.

## Confidence

The structure is *read*; the rates and costs *measured*, in one room at one
moment -- a room with more furniture, or with creatures, has longer passes.

## Renamed routines

Applied to the annotations on 2026-09-27; the build verified byte for byte.

| New name | Old name | Address | Role |
|---|---|---|---|
| `PAUSE` | `CHECK_KEY_HELD` | $9489 | SPACE pauses |
| `REGROW_FOOD` | `ADVANCE_CURSOR` | $9924 | food regrowth, once in 512 passes |
| `READ_PICKUP_KEY` | `READ_FIRE_ROW` | $938B | the pick-up key |

## Disassembly corrections

All applied to the annotations, the ref and the build on 2026-09-27 (the old names are used below), except where marked.

- The annotation at `MAIN_LOOP` and the ref's "One loop, three tables" say the
  doors are a third table "from $EEE0 up, eight bytes again", dispatched if
  in the player's room. The loop never walks $EEE0 upwards: doors and
  furniture are sixteen-byte records reached only through the room's list
  (`ROOM_LIST_PASS`), and on the first pass in a room the loop jumps straight
  there. `LD IX,$EEE0` at $7DD6 is dead weight: IX is reloaded from the list.
- `GAME_OVER`'s annotation: "About four seconds in all" -- it is about ten
  (9.7 s by the arithmetic, 9.8 s measured). Its first line, "Reached from
  UPDATE_KNIGHT when the player's last life goes", is also wrong: it is
  reached from `LOSE_LIFE` ($8EA4), whatever took the last life.
- `CHECK_KEY_HELD` ("Look at a key with interrupts off") is the pause.
- The comment at $8C4F said the delay runs "with interrupts off because the
  death happened inside FRAME_TICK". True only of a hunger death; corrected
  on 2026-09-27 (above).

## Open questions

- Pass lengths in the busiest rooms (three creatures, a big monster, many
  doors) have not been measured; the player's speed does not change, but the
  monsters' does.
