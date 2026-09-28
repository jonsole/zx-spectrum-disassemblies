# Bugs and pokes

**Question this answers:** what is wrong in the game's code, how each fault
shows, and which pokes change the game -- each checked, not just read.

**Short answer:** twelve faults, from a hum that plays bytes of the ROM and a
hundred per cent printed in the wrong font to a stack that leaks two bytes a
game and crashes the 157th; seven pokes, among them an infinite-lives poke
that gets past the game's own check on the obvious one. The pages are
`reference/bugs.html`, `pokes.html` and `facts.html`, written by
`scripts/nightshade_reference.py`, which re-runs four of the checks at every
build (the 100% screen with and without its poke, the lives-poke reset, the
157 games, the hum's addresses with and without its poke).

## The bugs

| Bug | Where | What shows | Evidence |
|---|---|---|---|
| The villains hum the ROM | `VILLAIN_WANDER` $D94F, `BLIP_FROM_TABLE` $C335 | pitches from ROM $0080-$00BF (code and the keyword table), 1 to 254; `VILLAIN_PITCHES` never read | read; measured (at every build): bases $00B0/$00A0/$0090/$0080 for 108/104/100/96; searched: the LD HL at $D959 is the only reference |
| 100% prints three wrong characters | `PRINT_PERCENTAGE` $BF36 -> `PRINT_BCD_LOW` $C327 | FONT_BASE left at the text font's code 0 ($6B5E, bytes of building 47's definition) | measured (every build, picture); watched: the live screen's 6912 bytes equal the simulator's |
| The 157th game crashes | `GAME_OVER` $CC56 jumped to; only `START` sets SP | SP 2 lower at the menu per game over, 4 per ending; NMIADD changes at the 156th menu; game 157 hangs at $5ED8, panel drawn, play area empty | measured (every build: fails at 157); watched live, identical (199 s uncapped) |
| Only the first antibody can strike | `ANTIBODY_STRIKE` $C538 | DE = 16 never added to IY; the second antibody passes through | measured: two thrown with the game's throw, the second flew through a monster of 112 to a wall; one alone struck it (2500) |
| A split overwrites the first monster | `HIT_SPLITS` $C101 | the struck monster copied over monster record 0 (the copies back to back, $40 each way); record 0's occupant gone, 1500 only | measured: record 3 = 120 struck by antibody 80, record 0 = 64 (and, again, 136) two cells off: replaced |
| The bonus is looked for outside the town | `PLACE_BONUS` $D76C, TOWN_CELL $E051 | rows -4..-1 read $7Dxx (sprites), rows 32-34 read DRAW_ORDER; the bonus lands in the wrapped row, far, often solid, gone at its first update | measured: 300 tries each at (1,1): 74 outside, all placed, all gone; at (26,30): 105, all gone |
| A monster that may not appear appears in the corner | `SPAWN_MONSTER` $CDE8 | template copied before the solid test: graphic 128 at (0,0). Mid-town: emptied after 5 turns. Near the top-left corner (knight in (1,1)): it lives, walks off to column/row 255, which NEAR_KNIGHT's byte subtraction counts as 2 cells away | measured: 1500 turns at (1,1): 3-4 of 6 records off the map in 1463 turns, every one born at (0,0) (5270 record-turns); none at (2,2) or (16,16) |
| The knight never reaches his top speed | `WALK_ON` $DCA8 | (speed + (top - speed)/2) AND $FE: 4, 6, 8, 8 / 8, 12, 14, 16, 16 | measured |
| A 16th thing in a cell would overwrite TURN_CELL | `LIST_THINGS_IN_CELL` $CFAF, `DRAW_LIST` $D15D | the end word lands on $D17D-$D17E: LD A,($BBBA) becomes NOP NOP CP E | staged: 16 in his cell -> $D17D = 00 00 after one turn, and it stays; 15 untouched. Latent |
| A wall's colour runs past the attribute buffer | `COLOUR_STRIP` $C889 -> `ATTR_SPILL` $F194 | written in 269 of 1000 turns, wall colours $44-$47; $F195-$F1FF never changed | measured |
| A stray OUT pages a 128K | `READ_KEYS` $E239 | the tune's key test (A = 0) pages ROM 0; the pause's $7E at the end of the first turn pages bank 6, screen 7, locked; the machine ends in the BASIC ROM over a blank screen | watched on the emulator's 128K |
| The pick-up sound starts with a byte of code | `EFFECT_NOTE` $C3BD, effect 3 | notes read from $C3F4 ($0E, FIRE_SOUND's first byte), $C3F3, $C3F2, $C3F1 | measured. Pentagram never starts its effect 3 |

## The pokes

| Poke | Bytes | Tested |
|---|---|---|
| Infinite lives | $CBDB,$CBDC = 2,0: LD HL,$0002 -- DEC (HL) on the ROM ($11 -> $10, positive) | villain on him each life: without, 5..0 then game over at the 6th death; with, 12 deaths and LIVES 5. The NOP over $CBDD resets at the first death (picture) |
| Nothing can kill him | $CEC2 = RET (MONSTER_HITS_KNIGHT's DEC), $D974 = RET (VILLAIN_WANDER's RET NC) | 300 turns, villain on him every turn: 13 lives lost / none; monster 112 on him: 29 hits, 9 lives / none |
| Top speeds as written | $BE4C = 12, $DA96 = 12, $D741 = 20 | 6, 8, 10, 10; with the bonus 10, 14, 16, 18, 18; still rests on the 8-unit grid |
| No monsters, no creature | $CDE8 = RET, $BF95 = RET | 1000 turns: 5833 record-turns busy and 52 creature turns / none |
| 100% printed as 100 | 11 bytes at $F195 (PUSH HL, LD HL,$6CDE, LD ($BBAC),HL, POP HL, JP $C327), $BF41-$BF42 = $F195 | at every build: FONT_BASE the digits', screen 100 (picture) |
| The villains hum their own tables | $D955-$D95B: AND $30, ADD A,$5D, LD C,A, LD B,$C3, NOP | at every build: bases $C38D/$C37D/$C36D/$C35D |
| 128K in 128 mode | $E239,$E23A = 0,0 | live 128K: without, crash at the end of the first turn; with, 300 turns, $7FFD stays $10 |

## Facts worth keeping

- **The menu deals the town.** `MENU` calls `NEXT_TURN` at every pass
  ($C93C), about 42 passes a second (20 passes in 0.47 s of emulated time),
  so the turn counter and the random number at the first turn depend on how
  long the menu ran: 1 to 6 passes gave six start cells and six villain
  placements (measured).
- **The first creature** comes when `TURNS`' low byte reaches 0; with the
  build's usual menu timing, turn 174 of every game (measured) -- but that
  depends on the menu time, as above.
- **SCORE_ZEROS** ($BBCC): no instruction addresses it (searched); scores
  are hundreds.
- **Shared code**, from `matches.txt` and byte searches: READ_KEYS all three
  games (1.0); the tune player Alien 8's and Pentagram's (1.0, instruction
  patterns); the note table (183 bytes) is at Knight Lore $B332, Alien 8
  $B51D, Pentagram $D718, byte for byte; the 80 bytes of blip pitches
  ($C34D) are at Pentagram $D587.

## How this was found

Stage 2's candidates, each re-run in SkoolKit's simulator with the build's
`Machine` (scratch scripts `ns3_reference_e1.py` to `e17.py`), pokes only
at `MAIN_LOOP`. Live checks on a private `zx_server` (ports
14711/18000/18500, `--no-audio --no-advertise --uncapped`), killed by PID
afterwards: the 128K trials (`--rom roms/128.rom --machine 128`, a 128K
`.z80` made with SkoolKit's `Z80(ram=banks, machine="128K")`, `7ffd=16`,
R and the registers from `nightshade.z80`; the server restarted between
trials because a locked paging survives a snapshot load), the 100% screen,
and 157 game overs driven by breakpoints at `MENU_LOOP` and `MAIN_LOOP`.

## Confidence

Every row above is measured or watched as its Evidence column says; the
causes are read. Inferred: that the hum tables were meant for the villains
(their size and place), that the split meant to find an empty record. Not
seen in play: the sixteen-thing list (latent).

## Open questions

- The villains' and objects' names: nothing in the game names them; not
  checked against the inlay.
- Whether a real 128K (not the emulator) ends in the same place after the
  paging write -- the lock and the bank are certain from the port value.
