# Lives, starting and dying

**Question this answers:** where a game and a life start, how many lives
there are, how he dies, and what a death costs.

**Short answer:** five lives, shown as 04: the one in play and four in hand.
A game starts in one of four rooms (51, 92, 100, 12) picked at random. Every
life starts from `PLAYER_TEMPLATE` ($C3FF), which the doorways rewrite as he
enters each room, so a life lost restarts at the doorway he came in by. He
dies by being marked killed (bit 6 of +$0D), becomes a puff, and when the
puff is over the game takes a life; after the fifth death, the game-over
screen.

## How it works

- **A new game** (`START` $AF87): `LIVES` = 5; after the menu and the start
  tune, `NEW_QUEST` ($D16F, [`quest.md`](quest.md)) and `CHOOSE_START`
  ($C2CE): the 16 bytes of `PLAYER_START` ($C3EF) over the start of the
  template -- graphic 32, U, V and Z 128, half-sizes 5, 5 and 23, flags $5C --
  and the room from `START_ROOMS` ($C2E8) by bits 0-1 of `RANDOM`. Only the
  legs' first half is reset; the room byte in `PLAYER_START` (98) is replaced
  at once and never used (*read*).
- **A life** (`RESTART_PLAYER` $C2EC, from `RESTART` $AFC5): copy the 64-byte
  template over both his records and take a life; below zero, `GAME_OVER`
  ($C323). It runs at the start of every game too, so the five lives show as
  04 and the fifth death ends the game (*read*; 04 *measured* at a game's
  start in room 100). `START_ROOM` ($C407) is the template's room byte, the
  place to poke to restart in a given room ([`driving.md`](driving.md)).
- **The template** is rewritten at every doorway (`EXIT_SCREEN` $C854) with
  his records as he enters the new room, U or V still holding the arrival
  marker, so a restart goes through the arrival placement again and he
  appears in the doorway he came in by, with the three turns' walk in
  ([`doorways-and-rooms.md`](doorways-and-rooms.md)) (*read*; the template's
  room and marker *measured* after an exit).
- **Dying.** Anything with bit 7 of +$0D that moves into him, or bit 5 that
  he touches, sets bit 6 of his +$0D (`PLAYER_STATE`, $A77C)
  ([`collision.md`](collision.md)). `MAKE_DEADLY` ($C291) sets both bits on
  the deadly things. Next turn `PLAYER_LEGS` marks the body killed too and
  turns the legs into a puff (`START_PUFF` $C107); the body does the same. The
  puff runs graphics 64-71 and ends as graphic 1, then 0 (`END_PUFF` $C11D).
  When both records are empty, the main loop goes to `RESTART` (*read*; the
  puff's frames *measured* on a bolt, which uses the same routine).
- **Extra lives**: one for each quest item done (`QUEST_ITEM` $CF68), up to
  four ([`quest.md`](quest.md)). `DRAW_LIVES` ($C29A) redraws the number.
- **BCD without DAA.** `LIVES` is printed as BCD, but `RESTART_PLAYER` takes
  one with DEC and `QUEST_ITEM` adds one with INC. It never passes 9 (four in
  hand after the first restart, plus at most four), so the two agree (*read*).
- **What a death keeps.** The room is rebuilt from the directory, so movers
  go back to their places and the well's count is lost; the quest things keep
  where they were (the room being left is filed back first, even on a death:
  `RESTART` runs on into `GAME_LOOP`) ([`quest-records.md`](quest-records.md)).
  What he carries is kept (*read*).
- **Game over** (`GAME_OVER`, in `WON` $C302): the game-over screen with the
  percentage, the tune, a wait, and back to the menu
  ([`menu-and-panel.md`](menu-and-panel.md), [`percentage.md`](percentage.md)).

## How this was found

Read, with Knight Lore's `lose_life`, `init_start_location` and
`player_controls` beside it (stage 2, range 3); the start of a game in the
simulator showed 04 lives in room 100. The build's "game over" session sets
`LIVES` to 0 and the killed bit and runs the game over and the menu
([`driving.md`](driving.md)).

## Confidence

*Read*; the lives shown and a start room *measured* in the simulator, and the
restart path run by every session that changes room.

## Knight Lore

Knight Lore keeps its saved records at its $D161 and corrects them for day
and night; Pentagram has no transformation. Knight Lore's
`init_start_location` fills both saved records; Pentagram resets only the
legs' first 16 bytes. Knight Lore's respawn is a materialising sparkle;
Pentagram's copies the records as they are
([`../knightlore/lives-and-starting.md`](../knightlore/lives-and-starting.md)).

## Disassembly corrections

- `CHOOSE_START` copies 16 bytes, not a record: the first half of the legs'.
- `PLAYER_START`'s room byte is never used.
- `PLAYER_TEMPLATE` is rewritten at every doorway (see
  [`doorways-and-rooms.md`](doorways-and-rooms.md)).

## Open questions

- The body's record in the template has room 1, which nothing is seen to
  read.
- Whether a quest item's extra life shows at once: `DRAW_LIVES` draws into
  the buffer, and the main loop copies the whole buffer only on a new room.
  Not checked.
