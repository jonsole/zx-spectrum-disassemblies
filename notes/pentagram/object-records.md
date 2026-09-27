# The object record

**Question this answers:** what the 54 object records are for, and what each
of a record's 32 bytes holds.

**Short answer:** everything in a room is a 32-byte record at `OBJECTS`
($A76F): the player's legs and body, two bolts, two things from the sky, and
48 for the room's scenery, objects and quest things. The first 14 bytes and
the last 8 are the engine's, laid out as in Knight Lore; +$0E to +$17 are
steering, the quest link, the drawing nudge and each kind's own scratch.

## How it works

| Record | Address | Label | Holds |
|---|---|---|---|
| 0 | $A76F | `OBJECTS` | the player's legs -- his whole collision box (graphics 32-39) |
| 1 | $A78F | `PLAYER_BODY` | his body, which copies the legs every turn (graphics 40-47) |
| 2, 3 | $A7AF, $A7CF | `BOLTS`, `BOLT_SECOND` | the bolts he fires |
| 4, 5 | $A7EF, $A80F | `FLYERS`, `FLYER_SECOND` | things fallen from the sky |
| 6-53 | $A82F-$AE0F | `ROOM_OBJECTS` ... `ROOM_SECOND` ($ADEF), `ROOM_FIRST` ($AE0F) | the room: the builder fills them from the top down, the quest things go in the lowest free ones |

The legs' own fields have labels: `PLAYER_U` $A770, `PLAYER_V` $A771,
`PLAYER_FLAGS` $A776, `PLAYER_ROOM` $A777, `PLAYER_BUMPED` $A77B (+$0C) and
`PLAYER_STATE` $A77C (+$0D).

| Offset | Field | Evidence |
|---|---|---|
| +$00 | graphic: picks the update routine (`UPDATES` $AE2F) and the sprite (`GRAPHICS` $6DD7); 0 an empty record, 1 one to be rubbed out and emptied when next drawn (`DRAW_OBJECT` $B3D3) | *read* |
| +$01-$03 | U, V, Z: U and V the centre of the box, Z its base | *read* ($B2C5, $B8A2-$B8CC) |
| +$04-$06 | half-sizes in U and V; the whole height in Z | *read* (`DO_OBJS_INTERSECT_ON_Z` $B8CC) |
| +$07 | flags, below | |
| +$08 | the room -- except scenery, where it is the scenery entry's second byte: for a doorway the room it leads to, otherwise 0 | *read* ($C92C); *measured* in room 100 (doorway pieces held 99, 101, 110; walls 0) |
| +$09-$0B | the step in U, V, Z this turn; an arch's first pillar keeps the arch's middle here instead | *read* ($B6ED, $C7AD) |
| +$0C | bits 0-2 the move was stopped in U, V, Z (bit 2: standing on something); bit 3 jumping; bits 4-7 turns of walking on by himself after a doorway | *read* ($B6ED, $C56C, $C854) |
| +$0D | bit 7 kills what it moves into; bit 5 kills what touches it; bit 6 killed; bit 3 something met it in Z this turn; bit 0 set on a thing put down (nothing reads it); bits 0-2 the legs' pause between turns; bit 2 a bobber's rising; bits 0-3 the body's graphic hold (never set) | *read* |
| +$0E, +$0F | an extra step in U, V, added into the next move and cleared; an arch steers the player with it | *read* ($C66A, $C907, $C91A) |
| +$10, +$11 | a quest thing's link to its record at `QUEST_RECORDS` ($D432); other kinds' counters: a homer's frame count (+$10), a pacer's direction (bit 0 of +$10) | *read* ($B097, $CC4B, $CEA0) |
| +$12, +$13 | the drawing nudge, X and Y, signed and in practice always negative | *read* ($B2C5); *measured* in room 100 |
| +$14-$16 | each kind's own: a homer's speeds in sixteenths, a bolt's step, the well's count and the bucket's "has a target" (+$14), a target U and V (+$15, +$16, bucket and collectables), a quest item's "the bucket is here" (bit 0 of +$16) | *read* |
| +$17 | bit 7 set when the player's legs or block 91 land on it, or on the mover when the player's legs are what it meets (`MARK_STOOD_ON` $B890, `ADJ_DZ_FOR_OBJ_INTERSECT` $B7E0); bits 0 and 1 the lift's moving and going down | *read*; *measured* on the lift and the crumbling block |
| +$18, +$19 | the sprite's width in bytes and height in rows as last drawn | *read* ($B3D3, $B938) |
| +$1A, +$1B | its pixel x, and pixel y counted up from the bottom of the screen | *read* ($B2C5) |
| +$1C-+$1F | +$18-+$1B as they were before this turn's update | *read* (`NEXT_OBJECT` $AFE1) |

**The flags, +$07:**

| Bit | Meaning | Set by / read by |
|---|---|---|
| 0 | may cross the line of the walls this turn: in a doorway | set by `HANDLE_EXIT_SCREEN` $C802, cleared by `PLAYER_LEGS` $C440; read by the wall tests $B8E2, $B90D |
| 1 | out of the collision tests | set by `ADJ_FOR_OUT_OF_BOUNDS` $B6ED on the mover for the duration, by `DO_ANY_OBJS_INTERSECT` $BF1B on IX, and kept on the body and on puffs |
| 2 | mobile: as an obstacle in U or V it takes the mover's whole intended step (it can be pushed); as a mover in Z it gives its step to what it lands on and, where its own U or V step is zero, rides with that thing's. Set in the player's flags and in five object templates, those of graphics 28, 63, 72, 73 and 79 (*read* from the templates); the well's bucket gets it too | `ADJ_DU_FOR_OBJ_INTERSECT` $B742, `ADJ_DV_FOR_OBJ_INTERSECT` $B791, `ADJ_DZ_FOR_OBJ_INTERSECT` $B7E0 |
| 3 | may use doorways (the player's legs) | `HANDLE_EXIT_SCREEN` |
| 4 | to be drawn this turn | set by `SET_DRAW_OBJS_OVERLAPPED` $B9A7, and in every piece of every scenery and object template (*read* from the templates), so a room's first turn draws everything; listed by `LIST_DRAWN` $B531, cleared by `DRAW_OBJECT` |
| 5 | moved: wipe its old and new rectangle and copy it to the screen | set with bit 4 at the tail of `HOMER` ($CC4B, `SET_WIPE_AND_DRAW_FLAGS`); cleared by `RENDER_DYNAMIC_OBJECTS` $B19E and, for all, by `CLEAR_COPY_BITS` $BF0D |
| 6 | mirrored | `FIND_SPRITE` $B2EE; with bit 2 of the graphic, the facing (`GET_SPRITE_DIR` $C5BD) |
| 7 | upside down | `FIND_SPRITE` |

The player's starting flags (`PLAYER_START` $C3EF) are $5C: bits 2, 3, 4 and
6 -- mobile, may use doorways, drawn, mirrored (*read*).

## How this was found

Every IX and IY offset in the listing was grepped from the skool file and
read where it is used, by the five describing agents of stage 2, each for its
own range; the lead gathered their field notes into the annotations' header.
A simulator dump of all 54 records in room 100 confirmed +$08 on doorway
pieces and walls and the sign of the nudges (range 1). The lift, the
crumbling block, the conveyor push and the carrying in Z were run in staged
scenes (ranges 2 and 5; see [`movers.md`](movers.md), [`collision.md`](collision.md)).

## Confidence

*Read* for every field, with +$08, +$12/+$13, +$17 and bit 2 of +$07 also
*measured*. The meanings of +$14-+$16 are per routine and described with each.

## Knight Lore

The same layout for +$00-+$0D, +$12, +$13 and +$18-+$1F, and the same flag
bits ([`../knightlore/memory-map.md`](../knightlore/memory-map.md)); Knight
Lore also borrows +$09-+$0B for an arch's middle. Pentagram has 54 records to
Knight Lore's 40, and six fixed ones (the bolts and the things from the sky
are its own) to Knight Lore's four. +$17's "stood on" bit and the quest link
at +$10 are Pentagram's.

## Disassembly corrections

- Stage 1 had +$08 as "the room" for every record: for scenery it is the
  scenery entry's second byte, a doorway's destination.
- The stage 1 header called +$0C "what it bumped into" and left bits 0-3 of
  +$07 and +$0E, +$0F, +$17 undescribed; all are described now. The header's
  own line for bit 2 of +$07 ("passes its Z step to what it lands on") gives
  only one of its three effects: it also makes a thing pushable in U and V,
  and makes it ride what it stands on (*read*, $B775, $B7C4, $B832).

## Open questions

- Bit 0 of +$0D, set on a thing put down (`FILL_PUT_DOWN` $C061) as Knight
  Lore sets it on its charms: nothing in Pentagram was found to read it.
