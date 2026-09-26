# Status panel, menu and text

**Question this answers:** How are the panel's numbers drawn, how does the
control menu work, and how is text encoded?

**Short answer:** Text is one byte per character, the index of a glyph in an
8x8 font (digits 0-9, letters $0A-$23, full stop $24, copyright $25, space
$26, percent $27), with bit 7 set on the last character; a string either
starts with an attribute byte or takes its colour from a parallel list.
Numbers are BCD, printed a nibble at a time as glyph indices. The menu reads
keys 1-5 and 0 from the port, keeps the choice in $5BA4, and shows it with the
FLASH bit.

## How it works

**Text encoding.**
- Characters: glyph index into the font at $5BC7 (normally the status font at
  $6108; `display_day` points it at its own four-glyph font at $BCEC).
- End: bit 7 set on the last character (printed with the bit masked off).
- Colour: `print_text` ($BE4C) expects the string's first byte to be the
  attribute for all its cells (the ratings and the day label use this).
  `print_text_single_colour` ($BE31) takes the colour from $5BB6 instead; that
  is what `display_text_list` ($BEBF) uses, with three parallel lists --
  colours (DE'), (x, y) pairs (HL), and the strings back to back (DE).
- Position: pixels, (x, y) with y counting up from the bottom of the screen
  and giving the top row of the characters. `calc_vidbuf_addr` makes it
  $D8F3 + 32y + x/8 in the screen buffer (which is stored bottom row first);
  `calc_attrib_addr` makes the attribute address. Glyphs go into the buffer,
  attributes straight into attribute memory.
- `print_8x8` ($BE7F) returns HL one cell to the right by adding $0101 after
  eight rows of -32: -256 + 257 = +1.

**Numbers.** `print_BCD_number` ($BCAE): B bytes from DE, high nibble first,
each nibble printed as a glyph (digits are glyphs 0-9). Entering at
`print_BCD_lsd` ($BCC0) skips the first high nibble -- used for the 1 of 100.
Numbers take a buffer address, not a position, and set no colours.

**The panel.**

| What | Routine | Where (buffer y, column) | Colour |
|---|---|---|---|
| Days, 2 BCD digits from $5BB9 | print_days $BC66 | y=7, col 15 | $5AEF-$5AF0 bright white |
| Day label, 4 glyphs | display_day $BCCA | x=$70, y=$0F | ink (1 - room ink) mod 8, bright, from $5BAD |
| Lives icon, sprite $8C | print_lives_gfx $BC7A | x=16, y=32 | six cells from $5A42/$5A62 bright white |
| Lives, 2 BCD digits from $5BBA | print_lives $BCA3 | y=39, col 4 | set by print_lives_gfx |
| Carried charms | display_objects $BF4E | x=16/40/64, y=0 | object_attributes $BFD3 |

Lives are counted in binary (start 5) but printed as BCD, so 10 or more would
show a letter; it is not known whether the game allows that many.

**The menu** (`do_menu_selection`, $BD0C):

    do_menu_selection   $5BB8 = 0, clear FLASH on all 8 colours
      clear_menu_flash  draw menu (shown, since $5BB8 = 0), flash_menu
      menu_loop ($BD23) redraw (attributes only take effect), tune once,
                        keys 1-4 set $5BA4 bits 1-2, key 5 toggles bit 3
                        (latched by $5BD2 bit 0)
      check_for_start_game ($BD6C)
                        click if $5BA4 differs from $5BA6; key 0 -> return
                        else $5BA0 += 1, flash_menu, loop

- $5BA4: bits 1-2 control method (0 keyboard, 1 Kempston, 2 cursor,
  3 Interface II), bit 3 directional control.
- The tune (`play_audio_wait_key`, $B2B6) plays only when $5BD1 is clear and
  sets it; it blocks until the tune ends or a key is pressed, so the menu does
  not react until then. The previous annotation said it plays "underneath";
  corrected.
- The seed at $5BA0 is bumped once per menu pass, so how long the player
  lingers on the menu changes the start room and the order of charms.
- `flash_menu` ($BD89): FLASH on the chosen method's line (colours from $BDA3),
  off on the other three; FLASH on the directional line if bit 3 is set.
- `display_text_list` shows the screen (border + buffer copy) only the first
  time after $5BB8 is cleared; later redraws only change the attributes on
  screen, which is all the flashing needs.

## How this was found

Read the print routines and followed the register sets across the EXX pairs;
worked out the coordinate system from `calc_vidbuf_addr`, `calc_attrib_addr`
and `update_screen` (which copies the buffer from the bottom line, $57E0, up).
Buffer addresses of the numbers were converted to (y, column) by subtracting
$D8F3. The glyph meanings of $24, $25 and $27 were checked by rendering those
three glyphs of the font; the day font was rendered too.

## Confidence

Read. The day label's glyphs render as a hand-lettered word; which word was not
settled from the bitmap alone.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| print_BCD_byte | loc_BCB6 | $BCB6 | Prints both digits of a BCD byte |
| clear_menu_flash | loc_BD15 | $BD15 | Clears FLASH on the menu colours, first draw |
| text_attr_addr | loc_BE56 | $BE56 | Works out a string's attribute address in the alternate set |
| print_text_char | loc_BE5F | $BE5F | Prints one character and colours it |
| print_text_last | loc_BE72 | $BE72 | Prints the last character |
| print_8x8_row | loc_BE91 | $BE91 | One glyph row |
| flash_this_one | loc_BEA6 | $BEA6 | Sets FLASH on the chosen colour |
| flash_next_one | loc_BEAA | $BEAA | Counts down to the chosen colour |
| unflash_this_one | loc_BEAD | $BEAD | Clears FLASH |
| flash_list_step | loc_BEAF | $BEAF | Next colour |
| sparkle_sound_and_draw | loc_BF31 | $BF31 | Sparkle noise and redraw (the transient-object handlers in this range) |

## Open questions

- The transient handlers that sit in this range: types 120-126 ($BEFE) are the
  player's appearing effect, set by `exit_screen` ($CAE8 writes $78) and
  restored by type 127 ($BF11) from the type saved at +$10; 112-118 are the
  vanishing sparkle; 184/185/187 vanish and clear the special-object table
  entry. What type 143 (which becomes 184) is, and what bit 6 of +$0D (cleared
  by type 127) means, are not worked out.
