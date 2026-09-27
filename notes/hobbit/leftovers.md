# Leftovers: what is in the game but never used

**Question this answers:** what code and data the game carries that nothing
reaches, reads or needs.

**Short answer:** six stretches of code nothing calls; a flag nothing sets;
a start-up test that can never fail; a wound message never chosen; a room
nobody can enter; two waters only FILL could fetch; an ending slot and a
placing word nothing uses; and a few unused bytes. None of it costs the game
anything but space.

## The list

**Code nothing reaches** (*read*; the disassembly marks only what there is
evidence runs as code, and leaves these as data with what they would do):

| Address | Label | Would do |
|---|---|---|
| $78FB | `UNREACHED_COPY_SIX` | a third way into `COPY_FRAME_PHRASE`, for six bytes |
| $9030 | `UNREACHED_LET_GO` | let something go (holder := nothing) |
| $92E8 | `UNREACHED_SAY_BROKEN` | "the ... is broken." |
| $A1AE | `UNREACHED_WALK_HELD` | find the first object held by another |
| $A536 | `UNREACHED_ELF_OPEN` | an OPEN for the wood elf alone -- no object carries it |
| $A70A | `UNREACHED_WIPE_EXIT` | wipe the exit through an object, as a hidden road is wiped |

A seventh was on this list until it turned out to be the quote mark's
handler (`SPECIAL_QUOTE`), which the fast-draw patch had built over; see
[`pictures.md`](pictures.md) and the journal.

**Data and branches that never matter** (*read*):

- **`ROAD_OPEN` ($B6F1)**: cleared by `NEW_GAME_CHOICES`, tested by
  `ELROND_READS_MAP`, set by nothing ([`hidden-roads.md`](hidden-roads.md)).
- **`NEW_GAME`'s test at $6CF1**: skips the new game's choices and its
  opening LOOK unless `COMMAND_FRAMES` ($B706) is $FF. It always is there:
  it is $FF on the tape, `START` copies it into the saved variables, and
  every new game copies it back just before the test. The branch to
  `MAIN_LOOP` at $6CF5 is never taken (read).
- **`WOUNDS`' first entry** ($9226), a wound message the off-by-one index
  never selects ([`fighting-and-dying.md`](fighting-and-dying.md)).
- **The empty place, location 47**, and the stone that fills it: nobody can
  enter it ([`locations.md`](locations.md)).
- **The fresh water and black water, objects $15 and $16**, kept at location
  0 for FILL to fetch -- and FILL can never succeed
  ([`bugs.md`](bugs.md)), so they never appear.
- **The torch's light bits**: it has the sword's flags, but `TOO_DARK` tests
  only the sword ([`light-and-dark.md`](light-and-dark.md)).
- **"On"**: `PLACED_WORD`'s second phrase and `DO_PUT_IN`'s PUT ON branch --
  nothing on the tape is placed on anything, and no object handles PUT ON.
- **`ENDINGS` slots 4 and 5** (and 6 and 7, which would run into
  `ORDER_COUNT` and `ORDERS`): no word asks for them.
- **Two $FF bytes after `RIDDLES`** ($C80C): no instruction names them.
- **Shift and SPACE** gives $02 in `KEY_MAP_SHIFTED`, which the line reader
  ignores ([`input.md`](input.md)).
- **Bard's order step on the tape**, TAKE THE WOODEN CHEST: a placeholder
  his first order overwrites ([`characters.md`](characters.md)).
- **`TYPED_WORD`'s first byte** ($7079): not used.

**Unused bytes**: $6BEF-$6BFF (zeros after the second word list),
$CB43-$CBFF (189 zeros after the `CHARACTERS` end marker, inside its entry
in the listing, up to `PICTURE_TABLE`; no instruction names an address in
them, though `START`'s copy of `TIMERS` and `CHARACTERS` runs to $CB42 only)
and $F35B-$F3FF (165 zeros after the last picture, which the fast-draw patch
uses). $F400 on is not spare: `START` copies the world there
([`memory-map.md`](memory-map.md)).

## How this was found

The unreached code by the build's method -- a code map from playing the game
in the simulator, extended by following branches and the dispatch tables --
and then checked by searching for any call, jump or table entry naming each
(2026-09-23). The rest were collected while writing the other notes.

## Confidence

*Read*. "Nothing reaches" is as strong as the searches: direct operands and
the known dispatch tables. The game does rewrite some of its own code --
the condition of the JRs at $7E92 and $7EA1, the SET/RES at $9488, the field
offset at $9F40 and the hidden road's operand at $A7D1, all labelled in the
listing -- but none of those writes makes a jump address. The $6CF1 test is
*read* from the copies, not watched.

## Open questions

- Whether `UNREACHED_ELF_OPEN` and `UNREACHED_WIPE_EXIT` were meant for the
  elvenking's gate and a road the game shuts later, as their shapes suggest.
