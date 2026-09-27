# Keys and locked doors

**Question this answers:** which keys there are, where they are, how a locked
door decides to open, and what happens to it afterwards.

**Short answer:** four keys, one picture ($81) in four colours -- red, green,
cyan, yellow. The yellow key is always in room $66; the other three are put
in one of eight rooms each when a game starts, and the mummy goes with the
red one. A locked door's colour is the low two bits of its type; it stands
open whenever a key of its colour is in the inventory, and once walked
through it turns into a plain door for the rest of the game -- the key is
not used up.

## How it works

**The keys** (*read*): records $EAC0 (green, $44), $EAC8 (red, $42), $EAD0
(cyan, $45), $EAD8 (yellow, $46); a key's colour is the attribute in its
+$05, which `REMEMBER_CARRIED` copies into the inventory slot.

**Where they go** (`PLACE_KEYS` $98D2, *read*): before the template is copied,
the green key's room is `RANDOM_ROOMS_ONE` ($990C) indexed by FRAMES AND 7;
the red key's -- and the mummy's -- is `RANDOM_ROOMS_TWO` ($9914) by
(FRAMES + TICKS) AND 7; the cyan key's is `RANDOM_ROOMS_THREE` ($991C) by
(FRAMES' high byte + TICKS' high byte) AND 7. TICKS is always 0 here
(`CLEAR_VARIABLES` has just run), so green and red use the same index and
move together: eight green/red pairings times eight cyan rooms, and in the
first game after loading always the same one -- green $22, red $85, cyan $91
([`loading.md`](loading.md); *measured*).

**The doors** (*read*): types $08-$0B are doors and $0C-$0E cave doors
(a yellow cave door, $0F, has a handler but no record), with
`DOOR_COLOURS` ($925C) giving red, green, cyan, yellow for the low two bits.
All four colours share one graphic and differ by colour table
([`drawing.md`](drawing.md)). Counted by record halves in the template:
roughly 9 red, 11 green, 10 cyan and 11 yellow doors, 3 red, 3 green and 2
cyan cave doors (*measured*; halves of one door normally agree).

`DOOR_NEEDS_KEY` ($9222), each pass the door is in the player's room:
`FIND_CARRIED` looks through the three slots for sprite $81 in the door's
colour.

- Not carried: `SHUT_DOOR` sets bit 3 of +$05 on both halves -- the walk test
  now ignores its doorway ([`collision.md`](collision.md)) -- and it is drawn.
- Carried: `OPEN_DOOR` clears bit 3 on both halves, and `PLAYER_AT_DOOR`
  decides whether the player is in it. If so, `DOOR_LOCKED_A` sets both
  halves' type to $02 (a plain door; `DOOR_LOCKED_B` to $01, a plain cave
  door) and calls `ENTER_ROOM`.

So a locked door opens as soon as the right key is carried -- and shuts again
if it is dropped -- until the player goes through it; from then on it is an
ordinary door, open to anyone, key or no key. Nothing takes the key away.

**The mummy and the red key** (*read*): the mummy patrols while the red key
is in its room, and hunts the player for good once it is not
([`monsters.md`](monsters.md)).

## How this was found

Read the two locked-door handlers, `DOOR_NEEDS_KEY`, `FIND_CARRIED`,
`OPEN_DOOR`/`SHUT_DOOR`, `SET_BOTH_HALVES` and `PLACE_KEYS`. The first-game
rooms were read from the simulator's memory after `START_GAME`.

## Confidence

*Read*; the room choices *measured* for the first game only. Walking through
a locked door was not staged.

## Disassembly corrections

All applied to the annotations, the ref and the build on 2026-09-27 (the old names are used below), except where marked.

- `DOOR_LOCKED_A`/`DOOR_LOCKED_B`: "sets the sprite on both halves to $02 ...
  The same as DOOR_LOCKED_A but setting $01 rather than $02, so the two look
  different once open". $02 and $01 are the plain door and plain cave door
  types: the door becomes an ordinary one permanently, which the notes do not
  say.
- `PLACE_KEYS`: "chosen by the frame counter mixed with the running values at
  $5E12 and $5E13" -- those running values have just been cleared, so they
  mix nothing in.

## Open questions

- None about the mechanism. The eight candidate rooms per key are the three
  tables in the listing; the map does not yet show them as a layer.
