# Records and dispatch

**Question this answers:** how the game represents everything in the castle,
and how a thing's behaviour is found.

**Short answer:** everything is a record whose first byte is a sprite code,
and that code is also its type: `DISPATCH_ACTOR` ($7E7E) indexes
`ACTOR_HANDLERS` ($7EE6) by it and jumps through the `JP (HL)` the tape put at
$5CB0. The whole castle -- player, weapon, sound, objects, monsters, doors,
furniture -- is a 5488-byte template at `INITIAL_STATE` ($600D) that
`LOAD_INITIAL_STATE` copies to $EA90 with one LDIR at the start of a game.
Even the sound effects and the drop key are records.

## How it works

**The eight-byte header** (*read*; the layout the annotations give, checked
against the handlers):

| Offset | Field |
|---|---|
| +$00 | sprite code = type; 0 is an empty slot |
| +$01 | room (for the sound slot: frames left) |
| +$02 | flags; for the player the low nibble is a countdown ([`player.md`](player.md)) |
| +$03, +$04 | x and y of the point the sprite stands on (sprites are drawn upwards) |
| +$05 | for a creature or object: its attribute; for a door or furniture: orientation (bits 7-5), shut (bit 3), solid (bit 2), how it combines with the screen (bits 1-0) |
| +$06, +$07 | for the player, the heading (signed); for doors and furniture, the walk box ([`collision.md`](collision.md)) |

A monster's record is sixteen bytes: velocities at +$08/+$09, a target at
+$0B/+$0C, counters at +$0A, +$0D, +$0E, +$0F. The player's record is sixteen
bytes too, and its second half, at $EA98, is the weapon, dispatched as a
record of its own ([`player.md`](player.md)).

**The runtime areas** (*read*; runtime = template + $8A83):

| Runtime | Template | What | Dispatched by |
|---|---|---|---|
| $EA90 | $600D | the player (16 bytes, the weapon in its second half) | `FRAME_TICK`, once a frame |
| $EA98 | $6015 | the weapon | `FRAME_TICK` |
| $EAA0 | $601D | the sound slot | `FRAME_TICK` |
| $EAA8 | $6025 | the three A.C.G. pieces | `MAIN_LOOP`, if in the player's room |
| $EAC0 | $603D | the green, red, cyan and yellow keys | the same |
| $EAE0 | $605D | object $80 (the mummy's lure) | the same |
| $EAE8 | $6065 | four empty slots for gravestones | the same |
| $EB08 | $6085 | the crucifix and the spanner | the same |
| $EB18 | $6095 | eight more collectables, $82-$89 | the same |
| $EB58 | $60D5 | 80 pieces of food, ten each of $50-$57 | the same |
| $EDD8 | $6355 | sixteen mushrooms | the same |
| $EE58 | $63D5 | the drop controller, sprite $31 | the same -- it is always in the player's room |
| $EE60 | $63DD | eight monster slots, 16 bytes: three for spawned creatures, then the mummy, Dracula, the devil, Frankenstein's monster, the humpback | `MAIN_LOOP_MONSTERS`, every pass |
| $EEE0 | $645D | 274 sixteen-byte door and furniture records, one half per room | the room lists only |

**The type is the sprite** (*read*). `ACTOR_HANDLERS` has 202 entries, in runs
because the low bits of a code are the animation frame or the heading: $01-$10
the knight, $11-$20 the wizard, $21-$30 the serf (sixteen each, four
headings of four frames); $31 the drop controller; $32-$33 and $48-$4B the
title screen's pictures; $34-$47 the three weapons; $4C-$4F, $5C-$63,
$68-$6B and $90-$9F the small creatures; $50-$57 food; $58-$5B a creature arriving;
$64, $65 and $A0 sounds; $66 and $67 the player rising and sinking; $6C-$6F a
burst; $70-$7F the four big monsters; $80-$8E collectables; $8F a gravestone;
$A1 a mushroom. Codes nothing uses point at `INERT_SPRITE` ($807A). So "is
the player in play" is one compare: the player's sprite is $01-$30 (*read*).

**Door and furniture types** (*read*). A room list names a sixteen-byte
record by the address of its half in that room. `DISPATCH_FROM_LIST` ($7E93)
takes the bias off, picks the half whose room is the player's, and dispatches
it from `ACTOR_HANDLERS + $144` ($802A), so a room record of type t runs
entry $A2 + t, while it is *drawn* as furniture graphic t (which is
`SPRITE_TABLE` code $A1 + t). The types and their handlers are tabled in
[`doors.md`](doors.md).

**Sounds are records** (*read*): `PLAY_SOUND_CAUGHT` ($A3E5) writes a type and a
frame count into the sound slot, and its handler beeps once a frame until
the count runs out and zeroes the type ([`sounds.md`](sounds.md)).

**The drop controller** (*read*, then *measured*): the record at $EE58 has
sprite $31, a blank picture whose handler is `PUT_DOWN` ($93E3).
`MOVE_PLAYER` copies the player's room into its +$01 ($EE59, `DROP_CONTROL_ROOM`)
every frame, so `MAIN_LOOP` -- which only dispatches first-table records in
the player's room -- runs `PUT_DOWN` on every pass. Breaking at $93E3 in the
simulator stopped with IX = $EE58 each time.

**Empty monster slots burn time** (*read*): `INERT_SPRITE` spends a counted
delay when IX is one of the first three monster slots, so an empty slot
costs about what a creature would -- measured at 14% of a pass in an empty
room ([`main-loop.md`](main-loop.md)).

## How this was found

Read `DISPATCH_ACTOR`, `DISPATCH_FROM_LIST`, the handler table and the
template's regions; the runtime addresses are the build's equates. The template
was listed by type in the simulator's memory (2026-09-27) to get the counts;
the drop controller was found by breaking at `PUT_DOWN`, which the code map
said had run although nothing visibly calls it.

## Confidence

*Read*, with the counts *measured* from the snapshot's template.

## Renamed routines

Applied to the annotations on 2026-09-27; the build verified byte for byte.

| New name | Old name | Address | Role |
|---|---|---|---|
| `DROP_CONTROL_ROOM` (equate) | `MOVE_ROOM` | $EE59 | the drop controller's room byte |
| `WEAPON_LIFE` (equate) | `SOUND_SLOT+7` | $EAA7 | the weapon's lifetime |
| `PLAY_SOUND_CAUGHT, PLAY_SOUND_NEW_ROOM, PLAY_SOUND_EATING` | `PLAY_SOUND, PLAY_SOUND_65, PLAY_SOUND_A0` | $A3E5, $A403, $A485 | start the three slot sounds |

## Disassembly corrections

All applied to the annotations, the ref and the build on 2026-09-27 (the old names are used below), except where marked.

- `INITIAL_STATE`'s annotation and the Data page say the objects include
  "ten each of the six kinds of food". There are eight kinds, $50-$57, ten of
  each: 80 records from $60D5 (counted in the template).
- The Data page calls the last region "274 doors"; the annotation's own
  later note is right: 205 doors and 69 pairs of furniture.
- The ref's Architecture page says doors, like the title pictures, are "eight
  bytes only". Each door is a sixteen-byte record, one eight-byte half per
  room; only the halves are eight bytes.
- The Fact "A sprite that is entirely zero: $31 ... is what a blank frame in
  an animation looks like" -- $31 is no animation frame: it is what
  `DRAW_LIST` draws for an empty inventory slot, and the type of the drop
  controller at $EE58.
- The isub at $8181 names the byte `FIRE_WEAPON` writes as `SOUND_SLOT+7`.
  It is the weapon's lifetime, +$0F of the weapon's record at $EA98, which
  happens to lie in the sound slot's unused tail.
- `MOVE_PLAYER`'s comment at $8D77 ("Remember which room this is happening
  in") -- it is keeping the drop controller in the player's room.

## Open questions

- None about the layout. What +$02 means for creatures is used differently by
  almost every mover ([`monsters.md`](monsters.md)).
