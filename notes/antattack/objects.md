# Objects

**Question this answers:** what the 16-byte object record holds, which
objects use which fields, and how one record drives the player, the person to
be rescued, the grenade and the ants alike.

**Short answer:** eight records of 16 bytes at `PLAYER` ($B480): the player,
the person to be rescued ($B490), the grenade ($B4A0) and five ants ($B4B0,
$B4C0, $B4D0, $B4E0, $B4F0). All are moved by the same `MOVE_OR_RESPAWN` /
`MOVE_OBJECT` code and drawn by the same projection; what differs is a few
flag bits, the first sprite frame, and which routine sets their keys (the
keyboard for the player, a chase for an ant, a follow for the rescued
person, a throw for the grenade). BASIC fills them from DATA at the start of
every attempt ([`basic-and-levels.md`](basic-and-levels.md)).

## How it works

| Offset | Field | Who uses it |
|---|---|---|
| +$00, +$01, +$02 | x, y, height (0 on the ground, blocks at 0-5, 6 on top of the tallest) | all; cells, no finer position |
| +$03 | first sprite frame: boy $DC, girl $6C, grenade $68, ants $F8 | `PROJECT_SPRITES` |
| +$04 | facing, low two bits: 0 y up, 1 x up, 2 y down, 3 x down | all; the keys turn the player, `MOVE_ANT` and `FOLLOW_PLAYER` set theirs, `COPY_POSITION` gives the grenade the player's |
| +$05 | frames spent falling | `MOVE_OBJECT`, `FALL`, `LANDED`, `STUNNED`, `SHARE_CELL`, `CHOOSE_FRAME`, `SCROLL_VIEW` |
| +$06 | frames left stunned; $FF on an ant is paralysed | `MOVE_OBJECT`, `STUNNED`, `READ_CONTROLS` (no turning), `FOLLOW_PLAYER`, `BLAST_ANT`, `PARALYSE_ANT`, `ANT_TURN` |
| +$07 | flags: bit 0 may stand on the object IY points at; 1 jump; 2 move forward; 3 never falls (set by nothing); 4 steps up a one-block rise | `READ_CONTROLS` writes the player's 1 and 2; `FOLLOW_PLAYER` the rescued person's 2; `THROW_GRENADE` the grenade's 2 |
| +$08 | animation frame 0-4, or with bit 7 set a sprite frame outright | `CHOOSE_FRAME` (people), `MOVE_ANT` (ants 0/1), `BLAST_FRAME`, `THROW_GRENADE` |
| +$09 | explosion countdown: while non-zero the object does not move and is drawn as the blast; at zero it goes home | `MOVE_OR_RESPAWN`, `CHOOSE_FRAME`, `BLAST_FRAME`, `THROW_GRENADE`, `BLAST_ANT` |
| +$0A, +$0B, +$0C | home x, y, height | `MOVE_OR_RESPAWN` |
| +$0D | ants: speed. The rescued person: 0 waiting, 1 following, 2 out of the city (BASIC's `w`) | `ANT_TURN`; `MOVE_RESCUEE`, `CHECK_RESCUED` |
| +$0E | ants: the speed count. The rescued person: last frame's distance to the player, for the scanner | `ANT_TURN`; `MOVE_RESCUEE` |
| +$0F | event: 1 a step (or a short landing), 2 a bad fall, 4 bitten, 8 blown up | written for everything; read only for the two people, by `HANDLE_EVENTS` |

(*read*, from every access in the listing; the annotations' header in
`scripts/antattack_annotations.ctl` has the same table.)

**Per object** (*read*, from BASIC's DATA and the routines that call the
movers):

| Record | Flags from BASIC | Keys set by | IY (the "other") | Home |
|---|---|---|---|---|
| player $B480 | bit 0 | `READ_CONTROLS` (V move, C jump, SYMBOL SHIFT and M turn) | the rescued person | the city gate, outside the walls |
| rescued person $B490 | bits 0, 4 | `FOLLOW_PLAYER` sets and clears bit 2 | the player | x 0, y 0, height 0 (from DATA) |
| grenade $B4A0 | bit 4 | `THROW_GRENADE` sets bit 2 in flight | the player | x 0, y $40, height 0 |
| ants $B4B0-$B4F0 | bit 2 (always moving) | `MOVE_ANT` turns them | the player | five cells on row y $A8 |

So the player and the rescued person may stand on each other (bit 0, via
`TEST_BELOW`), the rescued person and the grenade step up one-block rises by
themselves (bit 4, `STEP_UP`), and the player can only climb by jumping
([`movement-and-collision.md`](movement-and-collision.md)).

**The explosion countdown doubles as a respawn.** BASIC sets +$09 to 1 in
every record but the rescued person's, so the first frame sends each object
home: the player to the gate, the ants to their row, the grenade out of the
way. A blown-up ant or grenade shows the blast for five frames and then goes
home the same way. A blown-up person would go home too -- the rescued person's
home is (0, 0, 0), outside the walls -- but blowing someone up empties their
energy, so the attempt ends four frames later and BASIC puts everyone back
anyway (*read*).

**The sprite frame** (`PROJECT_SPRITES`, *read*): with +$08 bit 7 set, +$08
itself (the blast $F4-$F7, the grenade in flight $F4); otherwise
+$03 + 4 x (+$08) + ((+$04 + the view) AND 3). So each person has five poses
of four facings -- standing, walking, arms out (stunned briefly, or
throwing), lying down (stunned for longer), arms up (falling) -- and the
facing drawn is relative to the view. The ants use poses 0 and 1 only.

**Events for everything, read for two.** `MOVE_OBJECT` writes +$0F on every
step and landing, for ants and the grenade as well, but only `HANDLE_EVENTS`
reads it, and only for the player and the rescued person, clearing them; an
ant's event byte is simply overwritten (*read*).

**What is not in the record.** Energy, grenades and time are variables at
$B42F-$B437 ([`memory-map.md`](memory-map.md)). There is no velocity and no
sub-cell position: everything moves a whole cell, or a whole block of
height, in a frame.

## How this was found

Every `(IX+n)` and `(IY+n)` in the listing was matched to its field, and the
DATA in BASIC lines 110-180 read against them. Which record is IY for each
mover comes from `MOVE_PLAYER`, `MOVE_RESCUEE`, `MOVE_GRENADE` and
`MOVE_ANTS`.

## Confidence

*Read* throughout; the fields' uses are confirmed by the staged scenes in the
build, which set x, y, height, facing, stun and +$0D and got the behaviour
the code predicts (*played*). Flag bit 3 is set by nothing -- not the DATA,
not the code -- so its "never falls" meaning is only the branch in `FALL`.

## Open questions

- Why the rescued person's DATA gives animation frame 3 (lying down) as well as
  a stun: the waiting person is never moved or animated, so they are drawn
  lying down until found ([`rescue-and-scoring.md`](rescue-and-scoring.md));
  whether that was the intended look has not been checked against a real
  playthrough.
