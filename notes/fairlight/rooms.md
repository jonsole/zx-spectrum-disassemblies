# Drawing a room

**Question this answers:** how a room is found and drawn -- what each code
in a room's record does, from the points and lines to the parts, the clean
copy and the list of objects.

**Short answer:** a room is not a picture but a little program. `DRAW_CURRENT_ROOM`
($E55B) finds room `ROOM` in the table at $68B0, resets twenty drawing
variables from `ROOM_DEFAULTS` ($E582), clears the screen black on black so
nothing shows yet, keeps the room's colour byte and runs its commands
through `DO_ROOM_COMMAND` ($E5E8) until $E5: points (row, column), a second
point, lines between them, mode bits that change how points and lines
behave, textured fills, repeats, parts (56 shared sequences), a copy of the
screen into the clean copy that bounds the fills, and, after `$E4 $04`, the
room's objects. The colours go on all at once after the main loop's first
pass.

## How it works

```
DRAW_CURRENT_ROOM $E55B   RES 0,(IY+$3C) (OBJECTS_PLACED); walk ROOM1.. by length;
                          LDIR ROOM_DEFAULTS -> IY+$5F..$72
DRAW_ROOM_RECORD  $E597   IY+$68 := 0; CLEAR_ROOM_SCREEN $E5BA; ROOM_COLOUR := first byte
RUN_ROOM_COMMANDS $E5A6   loop: A = (IX); $E5 -> return; D = MODE; DO_ROOM_COMMAND; IX++
DO_ROOM_COMMAND   $E5E8   object mode (MODE bit 7): < $E4 an object (PLACE_OBJECT $EB1A),
                          $E4 nothing, $E6 up a patch (PATCH_RECORDS $E605)
                          otherwise: $00-$BF point; $C0 second point; $CF, $D0; $D6;
                          $E6-$FF fill (FILL_SEED $E73D); the rest -> MORE_ROOM_COMMANDS $E89B
```

The rooms: 81 records at `ROOM1` ($68B0) to `ROOM81` ($7588), each a length
word, a colour byte and commands to $E5. The parts: 56 at `PART1` ($758C,
also `PARTS_TABLE`) to `PART56` ($7CBC), the same without the colour byte.
Both tables are walked by length from the first every time. Room 79 is the
title's picture, room 1 GAME OVER's backdrop, room 81 the end of the quest
([`game-cycle.md`](game-cycle.md), [`quest.md`](quest.md)). Each record is
laid out command by command in the listing, generated from the game's bytes
at every build (`fairlight_data.room_commands()`).

The screen's rows are counted **up from the bottom** everywhere in the game
(0 the bottom line, 191 the top), and rows wrap modulo 192.

| Code | What |
|---|---|
| $00-$BF r c | A point: the byte is the row, the next the column. Mode bit 4 adds them to the point instead (a sum that carries or reaches 192 gets +64); bit 6 mirrors the column (255 less it, or negated when added); bit 3 moves the second point by as much; bit 5 draws a line from the second point to the new point; bit 2 then makes the new point the second point too, so lines join |
| $C0 r c | The second point, set, or moved under bit 4 |
| $C1/$C2 | Mode bit 4 on/off: points relative to the one before |
| $C3/$C4 | Bit 2: the second point follows each point |
| $C5/$C6 | Bit 3: the second point moves with the first |
| $C7/$C8 | Bit 5: a line from the second point to each new point |
| $C9/$CA | Bit 6: mirror the columns |
| $CB/$CC | Bit 0: lines clear pixels (with bit 1 off: OR then XOR, i.e. paper) |
| $CD/$CE | Bit 1: lines flip pixels (XOR) |
| $CF | The second point to the point |
| $D0 | The two points swapped |
| $D2 | A line from the second point to the first, both ends included (`DRAW_LINE`, $E8A0) |
| $D5 n | Repeat what follows, to the $D6, n times (`REPEATS`, `REPEAT_FROM`; one level) |
| $D6 | End of the repeat |
| $E0 n | Draw part n, then go on (the part may change the drawing's state) |
| $E1 n | Draw part n keeping the state: both points, the origin, the mode, the repeat |
| $E2 | Copy the screen's pixels into the clean copy at $C000 |
| $E4 $00 | Clear the clean copy, and send lines into it (`LINE_PAGE` = $80) |
| $E4 $01 | Lines onto the screen again |
| $E4 $04 | Object mode on: place the object table's things (once per drawing), then the room's own objects follow |
| $E4 $05 x y z | Place the table's things (once), then set `ORIGIN` ($FFDF-$FFE1), relative under bit 4 |
| $E5 | The end |
| $E6-$FF | A flood fill from the point with texture code - $E6 ([`textured-fill.md`](textured-fill.md)) |

$D1, $D3, $D4, $D7-$DF and $E3 match nothing in the cascade at $E89B and do
nothing. $E0 and $E1 both end object mode with the part (`RES 7` after it).

**The pen** (`PLOT_LINE_START` $E87D for the first pixel, the loop from
$E92B for the rest): set, clear (bit 0) or flip (bit 1); onto the screen,
or into the clean copy while `LINE_PAGE` is $80. The line is Bresenham's:
steps the longer distance, the error starting at half of it, the screen
address stepped a line or a pixel at a time.

**Invisible outlines.** Room 2 and part 16 use `$E4 $00 ... $E4 $01`: clear
the clean copy, draw an outline only there, fill inside it, then lines on
the screen again. In room 2 this lays a second texture over part of a brick
wall -- a fill that could not work against the ordinary clean copy, where
the wall's own bricks would stop it at once.

**The origin.** `$E4 $05` moves the origin that object mode adds to every
object it places ([`object-table.md`](object-table.md)). Room 17 repeats
four times { part 51 (two objects of type 18); `$E4 $05` 14,10,0 } with bit
4 on: four pairs in a row. Room 13 draws part 54 twice, 60 apart. Because
`$E4 $04` and `$E4 $05` both place the table's things before anything else
(`PLACE_OBJECTS_ONCE`, $EA84, guarded by bit 0 of `OBJECTS_PLACED`), and
the origin starts at 0, the table's things always go at their own places.

**Clearing the screen** (`CLEAR_ROOM_SCREEN`, $E5BA): the attributes are
filled with the byte at IY+$68 (`WORK_SPRITE`; always 0 here, set just
before) and the pixels with zeros, by pushing with SP borrowed (saved at
`FOUND_RECORD`, $FFF8). Black on black: the room is drawn unseen, and
`ATTRI` ($F0FB) colours it after the first pass
([`main-loop.md`](main-loop.md)).

**`ROOM_DEFAULTS`**, into IY+$5F-$72: the origin 0,0,0; a word 0
(`AWAY_FRAMES`, used elsewhere); the point 50,50; the second point 50,50;
$38 (IY+$68, which is set to 0 before it is read: dead); 0; `LINE_PAGE` 0;
`MODE` 0; `REPEATS` 0; 0; `REPEAT_FROM` 0; IY+$70, +$71 0; IY+$72 $80. The
21st byte ($E596) is not copied and nothing reads it.

## How this was found

Read (stage 2, ranges 1 and 2), $E55B-$EACB; the operand lengths in stage 1,
checked by parsing all 137 streams to exactly their lengths. *Measured*:
every room drawn in the simulator with a stop at `RUN_ROOM_COMMANDS`' fetch
($E5A6) -- 2348 command addresses, every one a command start in the parse,
the 55 commands never fetched those of the five parts no room draws (9, 11,
12, 33, 52). Every room and part counted by code: $D2 12 times, $E0 136,
$E1 116, $E2 48, $D5 17, `$E4 $04` 56, `$E4 $05` 34, `$E4 $00`/`$01` twice
each, $CD once (room 26), $CE never. Two experiments (the knight sent into
the room as a new game enters, stopped at $FDEF once it is drawn):

- room 26 with its $CD made the no-op $D1: 36 pixels differ, all along its
  last line, where it crosses an already-textured wall;
- room 2 with its `$E4 $00` and `$E4 $01` made `$E4 $02` (a no-op): the
  patterned panel on the wall disappears (676 pixels differ) -- the clean
  copy is not cleared, the fill finds its first point set and does nothing.

## Confidence

Codes and bits: *read*. Counts and the two experiments: *measured*. That
room 26 flips so its line shows over both ink and paper of the texture:
*inferred* from where the 36 pixels are. Two branches never ran: $E68B (a
row wrap after an absolute point, which cannot be needed) and $E6C7 (an
absolute second point mirrored: no room uses it).

## Krumlinde

His names and roles agree for `RTN_Enter_Room` ($E55B), `RTN_Draw_Room`
($E597), `RTN_Clear_Room_Screen` ($E5BA), the dispatch, the cascade, the
operand lengths, the line (second point to first) and the part table's
format. Where his `room_format.md` differs:

- Codes $00-$BF are points, not tiles: the opcode is a row and the operand
  a column (stage 1's finding).
- The codes $C1-$CE set and clear bits of $FFEB, which he says nothing
  reads: $FFEB is IY+$6B, the mode byte read before every command.
- $D5's count at $FFEC and $D6's IY+$6C are one byte, not two variables.
- **$E0 is not a tail call.** It calls $E5A6 and comes back to the room's
  commands; the only difference from $E1 is that the state is not kept
  (room 17 goes on after part 51).
- `$E4 $05`'s bytes are not orphaned writes: they are the origin
  `PLACE_OBJECT` adds, and rooms 13 and 17 move parts' objects with it.
- The guard bit (bit 0 of IY+$3C) is reset by $E55B at each drawing; it
  stops a room with several `$E4 $04`/`$05` (room 17 has five) placing the
  table's things more than once.
- The pen's bit 0 is not a second XOR: with bit 1 off it draws paper.
- `Room_PatchObjectTemplates` does not patch "a shared byte across six
  object-table records": it writes six different bytes, one in each of the
  six fixed records at $BC18 -- the room's floor, ceiling and walls
  ([`object-records.md`](object-records.md)).
- $FFE8 as "the byte the attributes are cleared with" (stage 1 took this
  from him): true, but it is always 0 when read, and the $38 in
  `ROOM_DEFAULTS` is dead.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `DRAW_CURRENT_ROOM` | `DRAW_ROOM_NUMBER` | $E55B | Stage 1's name read as if it drew a number |
| `DRAW_ROOM_RECORD` | `SUBE597` | $E597 | Clear, colour byte, run the commands |
| `RUN_ROOM_COMMANDS` | (entry) | $E5A6 | The command loop, also used for parts |
| `CLEAR_ROOM_SCREEN` | `SUBE5BA` | $E5BA | Krumlinde's name |
| `DO_ROOM_COMMAND` | `SUBE5E8` | $E5E8 | One command |
| `PATCH_RECORDS` | (entry) | $E605 | A patch code into the fixed records |
| `PLOT_LINE_START` | `SUBE87D` | $E87D | A line's first pixel, with the pen |
| `MORE_ROOM_COMMANDS` | `SUBE89B` | $E89B | Codes $C1-$E4 but $CF, $D0, $D6 |
| `DRAW_LINE` | (entry) | $E8A0 | $D2, and bit 5's lines |
| `ROOM_MODE_CODES` | (entry) | $E941 | $C1-$CE |
| `DRAW_PART` | (entry) | $EA1D | Find part n and run it |
| `PLACE_OBJECTS_ONCE` | (entry) | $EA84 | The once-per-drawing call of $EACC |

## Open questions

- What a fill does in a room that has neither cleared the clean copy
  (`$E4 $00`) nor copied the screen there (`$E2`) first: it would be
  bounded by the previous room's clean copy. Whether every room does one
  first has not been checked with the parser.
- Whether a part drawn inside a repeat has a repeat of its own (it would
  overwrite the count); not looked for.
