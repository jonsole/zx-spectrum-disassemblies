# Turning sprites round

**Question this answers:** how one set of sprites faces four ways, and what
the game must do because of how it does it.

**Short answer:** two views (bit 6 of +14: facing the viewer or away) and a
mirror (bit 5): the sprites are mirrored *in place in memory* when an object
turns to or from a mirrored direction. The author's MIRROR family does it:
`MIMAN` for the knight (all 14 of his frames), `MIWRAI` for the wraith (2
frames), `MITRO` for the troll (6). Because the frames are shared, the game
must turn a troll's or wraith's frames back before the next room's troll or
wraith uses them: `SAVE_OBJECT_POSITIONS` (the author's EEN) does, on every
way out of a room; and `TELE` keeps the knight's +14 through a new game.

## How it works

View 0 is walking away from the viewer (+x or +z), view 1 towards; the
frames facing away lie `AWAY_FRAMES` bytes beyond those facing the viewer.

| Direction bit | Keys (stick) | View (bit 6) | Mirrored (bit 5) |
|---|---|---|---|
| $08 (+x) | Y-P (right) | 0 | no |
| $40 (+z) | Q-T (up) | 0 | yes |
| $80 (-z) | A-G (down) | 1 | no |
| $04 (-x) | H-ENTER (left) | 1 | yes |

`MIRROR` ($F12D, inside `MITRO`) makes the facing bits in E from the
direction in C and stores E in IY+$72 (`WORK_BEHAVIOUR`, `CHE3D`'s copy of
+14); `MW` ($F157) mirrors the planes only if bit 5 of the record's +14
differs from E's: each row's bytes reversed and each byte's bits reversed,
using the stack. `FACING` ($F199) is the inverse, used to pick the knight's
pose for stooping and fighting, adding `AWAY_FRAMES` (IY+$62: 186 for
stooping, 372 for fighting) to reach the view facing away.

The record's bit 5 is the truth about the shared data only while one object
of the kind is about. The census: no room has two trolls or two wraiths.
`SAVE_OBJECT_POSITIONS` ($F906), run on every way out of a room (a door,
$F900; the kind-9 thing, $FEB0; the end of a game, $F0AF), turns a mirrored
troll's or wraith's frames back (asking for +x, C = 8) before the next
room's record, fresh from its template with bit 5 clear, is used. For the
same reason `TELE` resets the knight's record from the master copy all but
+14 (`KNIGHT_FLAGS`, $BC9E).

## How this was found

Read (stage 2, range 3); the plane counts matched to the sprites (the
knight's 14 frames of 24 by 31 from $9110, 186 bytes each; 2 of 16 by 32 at
$5E88; 6 of 24 by 38 at $8BB8). *Measured*: in room 5 the troll's sprite
bytes changed when its +14 went to $67 (mirrored) and back when it turned
again.

A caution for anyone driving the game: the build's sessions enter a room by
jumping to `TELE` ($F09B), which skips EEN, so a session can carry a
mirrored troll's or wraith's frames into the next room (*measured*: room 5
left mirrored, room 22's creature then walked with its record saying
unmirrored and the data mirrored). The game itself never does that
([`driving.md`](driving.md)).

## Confidence

*Read* and *measured* as above.

## Krumlinde

He names $F117, $F11F, $F127 and $F157 `Sub_...` and asks what $F11F and
$F127 do; this answers it. He reads $F906 as copying from the table into
the records; it is the reverse ([`entering-rooms.md`](entering-rooms.md)).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `MIMAN` | `SUBF117` | $F117 | Mirror the knight's 28 planes |
| `MIWRAI` | `SUBF11F` | $F11F | Mirror the wraith's 4 planes |
| `MITRO` | `SUBF127` | $F127 | Mirror the troll's 12; `MIRROR`, `MW1`, `MW2` inside |
| `MW` | `SUBF157` | $F157 | Mirror the planes if they face the other way; `MW0`, `MIR0`-`MIR3` inside |
| `FACING` | `SUBF199` | $F199 | Facing bits to a direction and a view's sprite; `FA0` inside |
| `AWAY_FRAMES` | `VARFFE2` | $FFE2 | The offset from a facing-the-viewer frame to its facing-away one |

## Open questions

- None known.
