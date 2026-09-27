# Bolts, things from the sky, and the score

**Question this answers:** what Sabreman can shoot, what falls from the sky
and when, and where the score comes from.

**Short answer:** fire copies his legs into a free bolt record (graphic 150),
16 units ahead and 4 up, flying 8 units a turn the way he faces at a height of
132. A bolt can hit only the two things from the sky; it shoots them down for
points made from the thing's graphic number -- the only way to score -- and
a bolt that bumps anything else goes up in a puff (it also counts towards
the well, [`quest.md`](quest.md)). In a room without the well, a quest item or
a piece of the pentagram, something may fall from the sky once `DROP_TIMER`
runs out; a bug makes that timer 80 turns until the first quest item is done
and 8 after.

## How it works

**Firing** (`FIRE` $C126, from the legs' routine): a new press of fire (bit
6 of `INPUT`, latched by `FIRE_HELD` $A743); the first of `BOLTS` ($A7AF) and
`BOLT_SECOND` ($A7CF) with graphic 0; a copy of his legs, graphic 150, flags
$14, half-height 8, 16 units ahead and 4 higher, its step from `BOLT_STEPS`
($C1BD, -8 or +8 in U or V by his facing from `GET_SPRITE_DIR`) kept in +$14
and +$15. If the start is outside the walls -- he stands in a doorway, or
faces a wall close up -- the bolt is taken back; otherwise `FIRE_SOUND`
($D629). So at most two bolts are in flight (*read*).

**A bolt** (`BOLT` $C1C5): its nudge; `DEC_DZ_AND_UPDATE_UVZ` (gravity, the
move cut short by the collision code); its graphic round 151, 150, 149; held
at Z 132 or more, so one fired from the floor flies level and one fired from
higher drops to that height. Then `BOLT_HIT` ($C206) against `FLYERS` and
`FLYER_SECOND` through `HIT_TEST` ($C216): on each axis, a distance no more
than the half-sizes' sum plus 2, and the target's graphic 8 or more and not a
puff (64-71). A hit goes to `SHOOT_DOWN` ($C264); a move cut in U or V (bits
0, 1 of +$0C) to `START_PUFF` ($C107); otherwise the step is reset from +$14,
+$15 and the bolt redrawn.

**Scoring** (`SHOOT_DOWN`): the points are three BCD digits made of the
thing's graphic number -- the hundreds from bits 5-7, the tens from bits 2-4,
the units from bits 6, 7 and 0 -- so no digit passes 7 and the sum stays BCD.
`ADD_SCORE` ($BB29) adds them to `SCORE` ($A744, six BCD digits) and prints
them into the buffer, and `SHOW_SCORE` ($B145) copies them to the screen at
once. The thing becomes a puff (graphic 64, out of collisions) and the bolt
vanishes (`VANISH` $C120, graphic 1). The five kinds that fall start as
graphics 164, 160, 48, 80 and 168, which score 512, 502, 140, 241 and 522 if
hit in that frame; a homer's graphic moves through its four frames and an
animated one scores by the frame it is in (*read*; the arithmetic checked
against the code's rotations).

**The puff** (`START_PUFF` $C107): graphic 64 and bit 1 of +$07 (out of
collisions); `PUFF` ($C111) steps one frame a turn with a burst of noise
(`PUFF_SOUND` $D64E); `END_PUFF` ($C11D) at 71 makes it graphic 1, which the
drawing code rubs out and empties. The player's death, a bolt's bump, a thing
shot down and the bucket's arrival all use it.

**Things from the sky:**

- `BAN_DROPS` ($CB89, at every room start): `DROP_BAN` ($A742) = 1 if any room
  record is the well (120), a quest item (112-119) or a pentagram piece
  (128-135).
- `RESET_DROP_TIMER` ($CC31, at every room start and after each drop):
  written to count the quest items still to do and set `DROP_TIMER` ($A73D)
  to 4 x (2 + that): 8 to 24 turns. But DE holds the record length and is
  never added to HL, so it tests the first quest record eighteen times: 80
  turns while the first quest item (room 122's) is to do, 8 once it is done,
  whatever the other three are (*read*; *measured*).
- `SKY_DROP` ($CBAB, every turn before the updates): banned, nothing;
  otherwise `DROP_TIMER` less one; at 0 it stays at 1 and each turn has a
  one-in-four chance (two bits of `RANDOM`). A drop resets the timer, takes a
  free one of `FLYERS` and `FLYER_SECOND` (none free: nothing), copies
  `FLYER_TEMPLATE` ($CC11: Z 216, half-sizes 8, flags $10) into it, and gives it
  U and V of 104 + (a random number AND $2F) -- 104-119 or 136-151, never
  within 8 of the room's middle lines -- and one of the eight graphics at
  `DROP_GRAPHICS` ($CC09): 164, 160, 48, 80, 168, 160, 48, 80. If it overlaps
  anything already there it is taken away again (*read*).
- What falls: homers (48, 160, 164; five of the eight entries), which fly at
  the player; and deadly creatures (80, the `SKY_ROAMER`, twice; 168, the
  `SKY_WALKER`), which fall and then run about ([`movers.md`](movers.md)).
  Homers are not deadly: nothing in `HOMER` sets the kill bits (*read*).
- A room's first drop is always at least the timer away, since it is reset on
  entry.

**Deadly things that never move** (`STILL_DEADLY` $C285, graphics 23, 30, 74,
75): `MAKE_DEADLY` ($C291) sets bits 7 and 5 of +$0D, and they are not redrawn.

## How this was found

Read (stage 2, ranges 3 and 4). A bolt was fired in the simulator (keyboard,
room 100, W held for three hundredths of a second) and its record watched turn
by turn: graphic 150, then 149, 151, 150; U 112 on the turn it was fired (the
player at 128, facing lower U), then 8 less a turn; Z 132; flags $14 (bit 5
toggling as it was redrawn); half-height 8; at U 70 it bumped the wall (+$0C
bit 0) and went through graphics 64 to 71, then 1 and 0, one a turn.
`RESET_DROP_TIMER` was run with the quest records copied from `QUEST_START`
and graphics raised by 4 for "done": 80 with none done, 80 with items 1-3
done, 80 with item 1 done, 8 with item 0 done, 8 with all done; agent 1
measured the same independently. The build's "things from the sky" session
(room 30, `DROP_TIMER` poked to 1, firing) runs the drops and the shooting.

## Confidence

*Measured*: the bolt's flight, the puff, the timer. *Read*: the scoring, the
drop's placement, the ban. Not checked: that each kind that falls moves as
its routine says in play, and the example scores (they assume a hit in the
first frame).

## Knight Lore

Knight Lore has no firing and no score: `FIRE`, `BOLT`, `BOLT_HIT`,
`SHOOT_DOWN`, `SKY_DROP` and `HOMER` have no match above 0.40. The puff is
Knight Lore's sparkle (`init_death_sparkles`); `MAKE_DEADLY` is its
`set_both_deadly_flags`.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `START_PUFF` | `SUBC107` | $C107 | make an object a puff |
| `PUFF_DRAW` | (entry point) | $C11A | the puff's redraw |
| `END_PUFF` (and `VANISH` $C120) | `SUBC11D` | $C11D | the puff's last frame |
| `BOLT_STEPS` | `DATAC1BD` | $C1BD | a bolt's step by facing |
| `BOLT_HIT` (and `HIT_TEST`, `HIT_TEST_Z`) | `SUBC206` | $C206 | has a bolt hit a thing from the sky? |
| `SHOOT_DOWN` | `SUBC264` | $C264 | score it, puff it, lose the bolt |
| `DEADLY_AND_DRAW` | `DATAC28B` | $C28B | an update routine nothing reaches |
| `HOMER` | `SUBCC4B` | $CC4B | a homer |
| `SET_WIPE_AND_DRAW_FLAGS` | (entry point) | $CCDE | the common end of the movers |

## Disassembly corrections

- `RESET_DROP_TIMER`'s title said "by the quest items still to do"; it now
  says what the code does.
- The remake's memory note has the timer "starting 0 -> 255 turns" and
  "resetting to (2 + quest items left) x 4": it is set at every room start,
  and to 80 or 8.

## Also found for the stage 3 pages (2026-09-27)

- Standing still, nothing falls: in room 30 with the drop timer run out, the random number's change was even on every turn for 150 turns, so it stayed odd and the one-in-four test never passed (*measured* in the simulator by two agents at several spots; that real hardware does the same is *inferred*). Homers are harmless: their routine never calls `MAKE_DEADLY` (*read*; *measured* -- all three sets came down on his head). A homer shot down scored 516.

## Open questions

- Why graphic 60, a panel piece, has `BOLT` as its update routine.
- Whether a remake should keep the 80/8 timer: it is what players of the
  original got.
