# The A.C.G. key and winning

**Question this answers:** how the game is won: where the three pieces of the
key are, what the great door wants, and what happens after.

**Short answer:** the key is three collectables, $8C, $8D and $8E, hidden at
the start of each game in one of eight sets of three rooms. The A.C.G. door is
in room $00, the room the game starts in, on its east wall. It opens only when
the three inventory slots hold the pieces in order -- $8C newest, $8E oldest,
so $8E must be picked up first -- and leads to room $8E; the main loop ends the
game the moment the player is in room $8E, with the misspelt CONGRATULATIONT.

## How it works

**Hiding the pieces** (`PLACE_ACG_KEY` $94B6, *read*): at `START_GAME`, before
the template is copied, (FRAMES + TICKS) AND 7 picks one of the eight
three-byte sets in `KEY_ROOM_SETS` ($94DD), which are written into the room
bytes of the three pieces' template records (`ACG_KEY_PARTS`, $6025). Every
set puts the third piece in one of the same two rooms, $2B or $7C,
alternately. TICKS is zero at that point and FRAMES is the same one
`PLACE_KEYS` uses a moment later, so the set's number is the same as the
index that places the green and red keys: sixty-four games' worth of
arrangements at most, and in the first game after loading always set 7 --
rooms $17, $10 and $2B (*measured*, [`loading.md`](loading.md)).

**The door** (*read*, then *measured*): one sixteen-byte record (template
$754D, runtime $FFD0/$FFD8) of type $24, one half in room $00 at x $98, y
$7F and one in room $8E. `ACG_DOOR` ($961B) reads the sprite byte of each
inventory slot in turn and wants $8C, $8D, $8E. With them, `OPEN_DOOR` and a
doorway 16 x 48 (it is in a side wall); without, `SHUT_DOOR` and it is only
drawn. Staged in the simulator: slots holding $8C, $8D, $8E opened it (bit 3
of +$05 clear) and putting the player in the doorway took him to room $8E
and `SHOW_END_SCREEN`; the same three in the opposite order left it shut.
Since new pickups go in at the front, the player must collect $8E, then $8D,
then $8C -- or pick them up in any order and use the drop key and the queue
to rearrange them ([`objects-and-inventory.md`](objects-and-inventory.md)).

**Room $8E** (*read*): a white passage (shape $0B, the only room of that
shape). `ENTER_ROOM` draws it and returns to `MAIN_LOOP`, whose first pass in
a new room dispatches only the room list and then, at its end, finds the
player's room is $8E and jumps to `SHOW_END_SCREEN` ($96EC). So the passage
is seen for one pass.

**The end** (*read*): `SHOW_END_SCREEN` draws the player, prints two lines --
the first `END_MESSAGES` ($9710), whose last character is $D4, "T" with the
end marker, where "S" ($D3) was meant, so it reads CONGRATULATIONT -- and
the same three-line summary as the game over screen (time, score, percentage
of the castle seen; [`status-panel.md`](status-panel.md)), waits about ten
seconds and returns to the title. Winning adds nothing to the score. The
ref's poke, POKE 38687,211, puts the S back.

## How this was found

Read `PLACE_ACG_KEY` against its table, `ACG_DOOR`, and the end of
`MAIN_LOOP`; found the door's record by searching the template for type $24.
Measured with `aticatac_t11.py` (both orders) and `aticatac_t15.py` (the
first game's rooms).

## Confidence

*Measured* for the door and the first game; *read* for the rest. The typo is
confirmed by the build, which draws the screen from the game's own routine
both as shipped and with the byte fixed.

## Renamed routines

Applied to the annotations on 2026-09-27; the build verified byte for byte.

| New name | Old name | Address | Role |
|---|---|---|---|
| `PLACE_ACG_KEY` | `ROTATING_INDEX` | $94B6 | hides the three pieces |
| `PERCENT_LABEL` | `TIME_LABEL` | $969F | the summary's percentage line |
## Disassembly corrections

All applied to the annotations, the ref and the build on 2026-09-27 (the old names are used below), except where marked.

- `ROTATING_INDEX` "A number that changes every frame ... callers get a value
  that walks 0 to 7 over time without anyone having to keep a counter". It is
  called once, by `START_GAME`, and copies a set of three rooms from
  `KEY_ROOM_SETS` into the A.C.G. pieces' records. (`KEY_ROOM_SETS`' own
  description, "The routine above picks a set", is right.)
- `ACG_DOOR`: "wants $8C, $8D and $8E in them, in that order". True of the
  slots; it means collecting them in the reverse order.
- The ref's Data page: "Three routines edit this template before it is
  copied". Two do: `ROTATING_INDEX` and `PLACE_KEYS`. `SCAN_DOORS` works on
  the runtime copy.

## Open questions

- Whether the drop key's queue was the intended way to rearrange pieces, or
  whether the designers expected them to be collected in order.
