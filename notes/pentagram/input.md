# Input: the controls and the pause

**Question this answers:** which keys and joystick inputs the game reads, into
what, and how the pause works.

**Short answer:** `READ_CONTROLS` ($BDF8) builds one byte, `INPUT` ($A737),
every turn from the player's routine: bit 0 turn left, 1 turn right, 2 walk,
3 jump, 4 pick up or put down, 6 fire. The keyboard is read by half-rows, so
every key of a row does the same (except the top letter row, shared between
jump and fire key by key). The joysticks are Kempston, cursor and Interface
II, and with any of them the bottom keyboard row picks up. SPACE or CAPS SHIFT
alone pauses. Control is rotational: the menu offers no directional mode.

## How it works

- **The method**: bits 1-2 of `CONTROL` ($A709), set by the menu's keys 1-4:
  0 keyboard, 1 Kempston, 2 cursor, 3 Interface II
  ([`menu-and-panel.md`](menu-and-panel.md)).
- **A half-row** (`READ_KEYS` $B952): `IN A,($FE)` with the half-rows in A,
  complemented so a set bit is a key down; two half-rows at once where the
  port's high byte has two bits clear ($BD, $E7, $7E). Knight Lore's routine
  byte for byte, including a stray `OUT ($FD),A` before the read (below).
- **The keyboard** (`READ_KEYBOARD` $BE91): Z, C, M, B turn left; X, V,
  SYMBOL SHIFT, N turn right; the whole A-G and H-ENTER rows walk; Q, E, T, U,
  O jump; W, R, Y, I, P fire; any number key picks up or puts down. SPACE and
  CAPS SHIFT do nothing here.
- **Kempston** (`READ_KEMPSTON` $BE40): port 31, bit 0 right, 1 left, 2 down,
  3 up, 4 fire.
- **Cursor** (`READ_CURSOR` $BE65): 5 left, 8 right, 7 up, 6 down, 0 fire.
- **Interface II** ($BE07): keys 1-5 are read, their bit order reversed, and
  ORed with keys 6-0, so the two sticks act as one.
- **Every joystick**: up walks, down jumps, fire fires, left and right turn,
  and any bottom-row key but CAPS SHIFT and SPACE picks up
  (`READ_BOTTOM_ROW` $BEFD).
- **Pick-up** (`CHK_PICKUP_DROP` $BF66) is bit 4 of `INPUT` -- or bit 5 with a
  joystick and bit 3 of `CONTROL` set, as in Knight Lore. `READ_CONTROLS`
  never sets bit 5 (nor bit 7).
- **Directional mode**: bit 3 of `CONTROL` makes a joystick steer by
  direction ([`player.md`](player.md)); no menu choice sets it (only a poke
  reaches it), and in it nothing could be picked up or put down, since bit 5
  is never set.
- **One action per press**: `TAKE_HELD` ($A740) and `FIRE_HELD` ($A743) latch
  the pick-up and fire keys until they are let go.
- **The pause** (`PAUSE` $B4E0, once a turn from `OBJECT_DONE`): half-rows $7F
  and $FE read together; bit 0 is SPACE or CAPS SHIFT, bits 1-4 the other
  eight keys of the two rows, and the pause needs bit 0 and none of the others,
  so no key that plays the game can start one. It beeps (`PAUSE_BEEP` $D5D7),
  waits for the key to be let go, sets IY to the ROM's system variables and
  enables interrupts -- the only place the game does -- waits for a press and a
  release, disables them and beeps again. The beep also adds one to the effect
  count, so a resumed game replays a note or two of the last sound effect
  ([`sound.md`](sound.md)).

**The stray OUT.** `READ_KEYS` writes A to port A x 256 + $FD before the IN.
Nothing on a 48K Spectrum answers it. A 128K machine's paging port ($7FFD,
decoded on A15 and A1 low) would, whenever A has bit 7 clear: of the
half-rows the game reads, only $7F and $7E. The first such write in a game
comes from the player's first update: with the keyboard, the SYMBOL SHIFT row
at $BEA2, value $7F -- RAM 7 at $C000, the shadow screen shown, paging locked;
with a joystick, the bottom row at $BEFD, value $7E -- RAM 6, the same
otherwise; and `PAUSE` writes $7E at the end of every turn. Either way the
code above $C000 is paged out, so the game should crash at its first turn on
a 128K in 128 mode (*inferred* from the port's documented bits; not tried).
The menu's reads (keys 1-5 and 6-0, $F7 and $EF) have bit 7 set and are
harmless.

## How this was found

Read, bit by bit, against the port layout of each device (stage 2, range 3);
the keys agree with the build's sessions, which play every method
([`driving.md`](driving.md)), and with the remake's driving notes, which found
them by pressing keys. The paging values were worked out for these notes from
the order of the calls to `READ_KEYS`.

## Confidence

*Read*; the keyboard and joystick mappings also *measured* by the build's
sessions. The 128K crash is *inferred*.

## Knight Lore

- `READ_KEYS` and `CHK_PICKUP_DROP` are Knight Lore's; `READ_CONTROLS` has
  no close match (none above 0.40). Knight Lore's joysticks also had a
  direction-control option with pick-up moved to bit 5; Pentagram offers
  neither, but kept the code for both
  ([`../knightlore/input.md`](../knightlore/input.md)).
- Knight Lore has the same stray OUT, so the same would hold for it.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `READ_KEMPSTON`, `READ_CURSOR`, `READ_KEYBOARD`, `READ_BOTTOM_ROW` | (entry points) | $BE40, $BE65, $BE91, $BEFD | the methods inside `READ_CONTROLS` |
| `CHK_PICKUP_DROP` | `SUBBF66` | $BF66 | is pick-up pressed? |

## Disassembly corrections

- Two stage 2 drafts disagreed on what the stray OUT would page: one said $7E
  and RAM 6 (from `PAUSE`), the other $7F and RAM 7 (from the keyboard).
  Both happen; which comes first depends on the control method (above). The
  listing's description of `READ_KEYS` names only `PAUSE`'s $7E -- to tidy.

## Open questions

- Does Pentagram in fact crash on a 128K in 128 mode at the first turn? An
  emulator run with `--machine 128` would show it.
- `LD B,A` at $BECD and `LD E,A` at $BED7 keep values nothing uses.
