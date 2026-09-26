# Portcullises

**Question this answers:** When does a portcullis rise and fall, and why is a
falling one deadly?

**Short answer:** A portcullis is type 8 at rest and type 9 while moving, and
only one in a room moves at a time. Below the top it waits for a 1-in-32 chance
each frame to rise, climbing one unit a frame to 32 above the floor; at the top
it drops straight away for its first four falls in a room and then on a 1-in-32
chance. It falls with double gravity, carries the "deadly when it moves into
something" bit, and lands with a burst of noise.

## How it works

```
upd_8 ($C65E)            at rest
   $5BAF != 0 -> return  (another is moving)
   z <= floor + 31 -> init_portcullis_up ($C6AD): 1 in 32; type 9; dz = +1; $5BAF++
   else ($5BB0 < 4 or 1 in 32) -> init_portcullis_down ($C685): $5BB0++; type 9; dz = -1; $5BAF++
upd_9 ($C6BD)            moving
   +$0D bit 7 (deadly to what it moves into)
   player's +$0C top nibble non-zero (settling into the room) -> return
   dz >= 0 -> move_portcullis_up ($C6EA): dz = 2, sound, gravity+move (net +1);
                                          z > floor + 31 -> stop_portcullis
   dz <  0 -> dz--, gravity+move (net -2 per frame more each frame)
             landed (+$0C bit 2) -> audio_B489 (16 bytes of the ROM as noise)
                                   -> stop_portcullis ($C6E0): $5BAF = 0, type 8
```

The floor height is $5BAE, the third byte of the room's size entry
(found_screen). $5BAF and $5BB0 are cleared at every room build (loc_D1EF). The
first-four-falls count is stored as $81 once the random path has been taken
(OR $80 then INC); any value of 4 or more behaves the same.

The block types table ($6BD1) has two portcullis entries, `gate_ud_1` and
`gate_ud_2`, both type 8, one 12 by 1 and one 1 by 12 in plan.

## How this was found

Read $C65E-$C721, found_screen for $5BAE, loc_D1EF for the resets, audio_B489
for the landing sound, the collision code for bit 7 of +$0D.

## Confidence

Read. "A falling portcullis kills" is the reading of bit 7 of +$0D; the
same bit is set whether it is rising or falling.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| count_moving_portcullis | loc_C691 | $C691 | $5BAF++ |

## Open questions

- Whether a rising portcullis can hurt (bit 7 is set in both directions, but
  moving up into the player may be prevented by the collision code first).
