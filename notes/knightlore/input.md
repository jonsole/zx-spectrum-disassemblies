# Input: the control methods and the input byte

**Question this answers:** How are the controls read, and what does each bit
of the input byte mean?

**Short answer:** `check_user_input` (`$D022`) reads one of four methods,
chosen in the menu, into a common byte at `$5BB5` (also returned in C). Bits
0-4 are left, right, forward, jump and pick up/drop; bit 5 is "any key other
than the number keys, Caps Shift and Space", which becomes the pick-up key for
a joystick in directional mode.

## How it works

```
upd_player_bottom ($C82B)
  check_user_input ($D022)          C = 0; if $5BC3 or $5BC4: skip to finished_input
    method = ($5BA4 >> 1) AND 3
      0 keyboard ($D0C8) | 1 kempston ($D077) | 2 cursor ($D09C) | 3 interface_ii ($D03E)
    finished_input ($D111)          bit 5; store at $5BB5
  handle_pickup_drop / handle_left_right / handle_jump / handle_forward
```

`$5BA4`, set by the menu: bits 1-2 the method (0 keyboard, 1 Kempston,
2 cursor, 3 Interface II), bit 3 directional control.

| Bit of $5BB5 | Meaning (rotational) | Joystick in directional mode |
|---|---|---|
| 0 | turn left | stick left |
| 1 | turn right | stick right |
| 2 | walk forward | stick up |
| 3 | jump | fire (jump) |
| 4 | pick up / drop | stick down |
| 5 | any key except numbers, Caps Shift, Space | pick up / drop |

`chk_pickup_drop` (`$BFFB`) reads bit 4, or bit 5 when the method is a
joystick and bit 3 of `$5BA4` is set; `handle_left_right` (`$C89F`) likewise
treats bits 0, 1, 2 and 4 as directions only for a joystick method. The
directional option does nothing with the keyboard.

| Method | Left | Right | Forward | Jump | Bit 4 |
|---|---|---|---|---|---|
| Keyboard | Z, C, B, M | X, V, N, Symbol Shift | A-G, H-Enter | Q-T, Y-P | 1-0 |
| Kempston (port $1F, active high) | bit 1 | bit 0 | bit 3 (up) | bit 4 (fire) | bit 2 (down) |
| Cursor | 5 | 8 | 7 | 0 | 6 |
| Interface II | 1 or 6 | 2 or 7 | 4 or 9 | 5 or 0 | 3 or 8 |

The keyboard reads pairs of half-rows at once by putting a port high byte
with two zero bits on the bus through `read_port` (`$B5F7`): `$BD` for A-G
with H-Enter, `$DB` for Q-T with Y-P, `$E7` for the two number half-rows,
`$7E` for the two bottom half-rows, and `$99` for the four letter half-rows.
Interface II reads both joysticks and ORs them; the 1-5 half-row's bits come
in the opposite order to 6-0's, so they are reversed first (`$D046`).

Caps Shift and Space are not controls; they are the pause keys
(`handle_pause`, `$D50E`).

When `$5BC3` (game won) or `$5BC4` (an object is falling into the cauldron)
is non-zero, C is forced to 0 but bit 5 is still computed.

## How this was found

Read `$D022`-`$D129`, `read_port`, the menu's use of `$5BA4` (`$BD2C`-`$BD99`),
and the consumers `chk_pickup_drop`, `handle_left_right`, `handle_jump`,
`handle_forward`. Half-row addresses decoded from the port high bytes.

## Confidence

*Watched* in the emulator on the keyboard method, holding each key for two
frames and reading `$5BB5` at the frame breakpoint: Z, C, B and M set bit 0;
X and N bit 1; A bit 2; Q bit 3; 1 bit 4 alone; every letter also sets bit 5.
Caps Shift held stops the frames in `debounce_space_press`, the pause. V and
Symbol Shift were not tried.

Read. The Kempston bit assignments (bit 0 right ... bit 4 fire) are the
interface's standard ones, confirmed by how the code maps them onto the same
bits as the cursor and Interface II directions.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| reverse_if2_bits | loc_D046 | $D046 | reverse the 1-5 half-row's bits |
| if2_up | loc_D05C | $D05C | Interface II up |
| if2_down | loc_D062 | $D062 | Interface II down |
| if2_right | loc_D068 | $D068 | Interface II right |
| if2_left | loc_D06E | $D06E | Interface II left |
| if2_done | loc_D074 | $D074 | Interface II done |
| kempston_left | loc_D081 | $D081 | Kempston left |
| kempston_down | loc_D087 | $D087 | Kempston down |
| kempston_up | loc_D08D | $D08D | Kempston up |
| kempston_fire | loc_D093 | $D093 | Kempston fire |
| kempston_done | loc_D099 | $D099 | Kempston done |
| cursor_second_row | loc_D0A9 | $D0A9 | cursor: the 6-0 half-row, 0 = fire |
| cursor_up | loc_D0B4 | $D0B4 | cursor 7 |
| cursor_right | loc_D0BA | $D0BA | cursor 8 |
| cursor_down | loc_D0C0 | $D0C0 | cursor 6 |
| keyboard_m | loc_D0E4 | $D0E4 | M: left |
| keyboard_n | loc_D0EA | $D0EA | N: right |
| keyboard_b | loc_D0F0 | $D0F0 | B: left |
| keyboard_forward | loc_D0F6 | $D0F6 | A-G, H-Enter |
| keyboard_jump | loc_D0FF | $D0FF | Q-T, Y-P |
| keyboard_pickup | loc_D108 | $D108 | number keys |
| store_input | loc_D125 | $D125 | store $5BB5 |

## Open questions

- None about the reading itself. Which Interface II socket is 1-5 and which
  is 6-0 is a hardware fact not visible in the code.
