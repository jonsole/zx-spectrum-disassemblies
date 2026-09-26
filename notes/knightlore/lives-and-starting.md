# Lives and starting: lives, start locations, death

**Question this answers:** How many lives are there, where does the player
start, and what happens on death?

**Short answer:** Five lives: `$5BBA` starts at 5 and the first life already
takes one. The player starts in one of four rooms chosen by the random seed,
in the centre of the room. On death he re-materialises in the room he last
entered, at the spot he entered it, as knight or werewolf according to the
time of day.

## How it works

```
main ($AF88)            $5BBA = 5; $D16D = 0
  init_start_location ($D1B1)
                        copy $D1A1 -> $D161 and $D181 (8 bytes each)
                        +$10 = 18 (knight legs) / 34 (knight head)
                        +$08 = start_locations[$5BA0 AND 3]
player_dies ($AFB7)
  lose_life ($D12A)     64 bytes $D161.. -> $5C08.. (records 0 and 1)
                        $5BB1 = 0; $5BBA -= 1, below 0 -> game_over ($BA22)
                        +$10 of each: creature bit from the time of day
game_loop ($AFBA)
  build_screen_objects ($D1E6)
```

`$D161`-`$D1A0` is two full 32-byte object records (legs, head) kept outside
the object table. The room exit (`exit_screen`, `$CABA`) copies the live
records there each time the player leaves a room -- after setting the new
room number and the exit coordinate -- with each type moved to +$10 and
replaced by 120, the first frame of materialising (types 120-127,
`upd_120_to_126`/`upd_127`, turn into the +$10 type at the end). So death
brings back the state at the last room entry; the same copy is what lets the
new room's code place him in the doorway.

Start of game record (`$D1A1`): type 120; X, Y = $80, $80 (room centre); Z
$80 for the legs and $8C for the head; half-sizes 5 and 5; height 23 for the
legs and 0 for the head; flags $1C and $1E.

Start rooms (`$D1E2`): $2F, $44, $B3, $8F -- high nibble the room's Y in the
castle grid, low nibble its X (the exits add or subtract 1 and 16).

Time of day in `lose_life`: bit 0 of the sun/moon type at `$C44D` (0 sun,
1 moon) becomes +32 on the types. Knight legs are 16-31 and heads 32-47;
werewolf legs 48-63 and heads 64-79. So after a death the legs' +$10 is
(old AND $1F) + 32*night and the head's (old AND $0F) + 32 + 32*night,
keeping frame and facing. A pending day/night transformation (`$5BB1`) is
cancelled since the new body already matches.

Death itself starts in the legs' handler (`$C82B`): a set bit 6 of +$0D
(the kill flag) makes the legs a death sparkle (`$BF21`) and sets the head's
kill flag, which `upd_player_top` (`$CDE2`) turns into a sparkle next.
Neither happens once the game is won (`$5BC3`). `end_of_frame` sends the
game to `player_dies` when both records 0 and 1 are empty.

Lives can also go up: `upd_103` (`$C1AB`) increments `$5BBA` when the player
touches an object of type 103, which then removes itself from the special
object table and vanishes -- an extra life.

### Building a room and coming in

`build_screen_objects` (`$D1E6`): write the collectables in records 2 and 3
back to the special object table (not on the first build of a game, `$5BB2`
clear); clear the screen buffer; build the room into records 4 on
(`retrieve_screen`); load the room's collectables into records 2-3; place the
player (`adjust_plyr_xyz_for_room_size`, `$D320`); zero `$5BAF`, `$5BB0`,
`$5BBD`, `$5BBF`; set `$5BB7` (draw everything); `$5BC0` = room AND 1; mark
the room visited in the bitmap at `$5BE8` (`flag_room_visited`, which patches
its own SET instruction's bit number).

Arriving: X = 0 means he left westwards and enters by the east arch, X = $FF
the west arch, Y = 0 the north arch, Y = $FF the south (+X is east and +Y
north in the arch data's naming). The coordinate becomes
$80 +/- (room half-size - 2) +/- his half-size, and his Z comes from the
arch's first pillar, found among records 4, 6, 8 and 10 by its X+Y ($51 N,
$37 E, $C8 S, $AE W).

## How this was found

Read `$D12A`-`$D1E5`, `$D1E6`-`$D236`, `$D320`-`$D3B4`, and the callers and
consumers: `main`, `player_dies`, `end_of_frame`, `exit_screen` and the four
screen exits, `upd_120_to_126`/`upd_127`, `upd_player_bottom`,
`toggle_day_night` and `colour_sun_moon` (for which bit value is night), the
arch records at `$6D12` on, `calc_and_display_percent` (the visited bitmap's
reader).

## Confidence

*Watched:* at the first frame of a game started from the menu, the player's
room ($5C10) was $8F, one of the four start rooms, and the panel showed four
lives -- the fifth is the one being played.

Read, except: "legs types 16-31 are the knight's" and the head/werewolf
ranges are from the handler table's grouping plus the +16/+32 arithmetic here,
not from looking at the sprites.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| plyr_spr_1_tail | byte_D171 | $D171 | saved legs record, bytes 16-31 (+$10 = type after materialising) |
| plyr_spr_2_tail | byte_D191 | $D191 | saved head record, bytes 16-31 |
| build_room | loc_D1EF | $D1EF | body of build_screen_objects |
| fill_sun_moon_colour | loc_D317 | $D317 | colour the sun/moon window's inside |
| check_next_arch | loc_D395 | $D395 | arch search loop |

## Open questions

- `init_start_location` sets only bytes 0-8 and +$10 of the saved records,
  and `main` clears +$0C; the other bytes (+$09 to +$0B, +$0D, +$11 up) carry
  over from the previous game's last room exit. Whether any of them matter
  on a new game has not been checked.
- Flag bits 2 and 3 of +$07 are set in both start records; bit 2 lets an
  object be pushed along by what bumps it (`$CBCD`), bit 3 is not worked out.
- What the two idle head frames (6 and 7 of the head types) look like.
