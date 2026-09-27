# Fighting, dying and winning

**Question this answers:** how a fight is decided, who can kill whom, every
way the player can die, and what winning is.

**Short answer:** a blow is the attacker's strength plus the weapon's
against the target's defence, each jostled -- meant as give or take ten, but
in practice plus 0 to 10, and about one time in 25 zero instead: no stronger
is wasted, more than 16 stronger kills (so a guard of 0 loses to any blow over
16), anything between wounds and wears the target down -- erratically,
because the wear is halved with a rotate where a shift was meant. There are a dozen ways to die, several of them traps that
kill on arrival or a few turns later. The game is won at the end of any
turn in which the treasure is in the wooden chest, and either way it starts
again without reloading.

## How it works

### A blow

`DO_ATTACK` ($9171; ATTACK WITH, and STRIKE WITH through THROW AT) (*read*,
line by line):

1. `SAME_SIDE`: the attacker and target share a side bit (bits 4-6 of byte
   4) -- refused. Except that the player attacking a friend first takes the
   friend off the player's side (bit 4), so the attack goes ahead and the
   friend is an enemy for the rest of the game.
2. The weapon's noun, or FIST, for the messages. A weapon in more than one
   place (a door, a river) cannot kill.
3. Blow = attacker's strength (byte 5) + weapon's strength, at most 255,
   then `JOSTLE`: plus `RANDOM` -10 to +10, meant to be kept to 0-255 --
   but see **the jostle** below: in practice plus 0 to 10, or 0.
4. The test ends here (`FOR_REAL`): up to this point a character's attack
   is only being considered.
5. Guard = target's defence (byte 6), jostled the same way.
6. Guard >= blow: wasted -- the message says the defence was too strong.
7. Blow > guard + 16: a kill, one well-placed blow, `KILL`.
8. Otherwise the margin (1-16) picks a message from `WOUNDS` ($9226) and
   wears down the target's strength and defence.

**The jostle is broken** (*read*, *measured* and *watched*, 2026-09-27).
`JOSTLE` ($9213) adds the random number with `ADD A,B` and takes a carry as
going past 255 -- 0 if the number was negative, 255 if not. But a negative
number is a byte of 246-255, which carries whenever the true result is fine,
so every downward jostle of a value of 10 or more returns **0**; below 10 an
underflow does not carry and wraps to 246 or more. And `RANDOM` halves its
byte until it is no more than 20, which leaves every byte from 21 up in the
top half: only a byte under 10 gives a negative, about one call in 25
([`chance.md`](chance.md)). So a blow or a guard goes up by 0 to 10, and
about one time in 25 is 0. A blow of 0 is wasted; a guard of 0 loses to any
blow over 16, a kill. *Measured* in the simulator: 2000 jostles of 104 gave
104-114, or 0 (71 times), never 94-103. *Watched* live (private zx_server,
a logpoint at $91C1 on the blow and guard): the vicious warg (55), kept
beside the player (64), struck 55-62 against guards of 65-73 -- a true
jostle could never let it kill -- until its twelfth blow met a guard of 0 and
killed the player; Thorin's 104 once came out 0. See [`bugs.md`](bugs.md).

**The wear is broken** (*read*, and *measured*). The margin is doubled for
the table index (`RLCA`), then halved twice with `RRCA` -- which rotates
bit 0 into bit 7 instead of dropping it -- and each result is taken off
strength and defence with `CPL` and `ADD`, written back only if it does not
go below zero. So an even margin takes about half of it off the strength,
while an odd one takes 129 or more -- which a weak target survives untouched
and a strong one loses most of its strength to; the defence goes the same
way a step further down. *Measured* 2026-09-27, the player attacking Thorin
(104/120) with the sword, a different number of WAITs first to vary the
dice: margin 8 left him 99/117, margin 10 98/120, margin 11 untouched, and
margin 13 104/52. Against the trolls (160/160) an odd margin would cut
strength to about 30 (computed from the instructions). See
[`bugs.md`](bugs.md).

**`WOUNDS` is read one entry late** (*read*): the index is twice the margin,
1-16, so the table's sixteen entries are read from its second, and a margin
of exactly 16 reads the word after the table -- the first two bytes of
`ONE_PLACE`'s code, $2ADD, an address in the ROM. Its first entry, the
"seem tired, stagger" message, is never used. *Measured*: `RUN_MESSAGE` on
$2ADD prints a few garbled dictionary words. A blow exactly 16 stronger was
not produced in a real fight.

**Who fights whom** (*read*, object records): sides are the player's (the
player, Gandalf, Thorin, Bard), the goblins' (the goblins, Gollum), the
elves' (the wood elf, the butler), and Elrond on both the player's and the
elves'. The dragon, the warg and the trolls are on no side, so everyone may
fight them and they may fight anyone. With bare hands the player's blow is
64-74, which cannot beat a goblin's guard of 96-106 -- except the one time in
about 25 that the guard comes out 0, when any blow over 16 kills; with the
sword (strength 64) it is 128-138, enough for goblins and Thorin, and short
of the trolls' 160-170 and the dragon's 192-202 by the same exception. The
guard-0 kill makes even the dragon mortal to a bare-handed player one blow in
25 (*read* from the code, not tried; the guard-0 kill itself was watched, on
the player). *Measured*: CAPTURE THORIN (a synonym for ATTACK) was
wasted on his defence, and Thorin, now an enemy, killed the player in one
blow in the same turn.

**Other ways to hurt** (*read*): `DO_SHOOT` needs the bow in hand; Bard
never misses, anyone else misses the dragon always and anything else
roughly one time in three; a hit kills a living character outright.
`DO_BURN` is the dragon's alone and kills. `DO_STRIKE` breaks things
(defence against the blow; the weapon can break too). `KILL` ($977F): the
player's death is `PLAYER_DIES`; anyone else is marked dead (flag bit 3),
renamed DEAD, drops everything, loses its orders and its `CHARACTERS` slot --
except a goblin, whose record brings it straight back (`GOBLIN_RETURNS`),
and Thorin, whose death shatters the small curious key (`THORIN_KILLED`),
which leaves the side door locked for good.

### Ways to die

| Cause | Where | Code | How known |
|---|---|---|---|
| Falling seven times in the dark | any dark room | `MOVE` | *measured* |
| The eyes: leaving the forest, or staying four turns | forest road, forest (2, 3) | timer 8 | *measured* ([`time-and-timers.md`](time-and-timers.md)) |
| Sinking in the bog, at the end of the turn of arrival | deep bog (29) | timer 4, `SINKING_IN_BOG` | *measured*: in through a broken web, dead that turn |
| Smothered by the web, five turns after arriving | spider threads place (26) | timer 2 | *read* |
| Swept against the portcullis, if not in the barrel | forest river (33) | `AT_FOREST_RIVER` | *read* |
| Eaten by a troll | trolls' clearing, any of the four turns after entering | `TROLLS_EAT` | *read* (and avoided in play) |
| Strangled: no answer, or the wrong one, to the riddle | wherever Gollum asked | `GOLLUM_HEARS_ANSWER` | *read* |
| Burnt by the dragon | anywhere lit once the treasure has gone; the mountain's rooms | `DRAGON_HUNTS`, `DO_BURN` | *read* |
| Asleep for ever: swimming in, or drinking from, the black river | west and east banks, the bewitched gloomy place | `SWIM_BLACK_RIVER`, `DRINK_BLACK_WATER` | *read* |
| Carried off down a river that leads nowhere | the rivers | `INTO_THE_RIVER` | *read* |
| Gluttony: eating when strength would reach 128 | anywhere | `DO_EAT` | *read* |
| Killed in a fight | anywhere | `DO_ATTACK`, `DO_SHOOT` | *measured* (Thorin) |

**Death** (`PLAYER_DIES` $90D2): "you are dead.", the score
(`SHOW_SCORE`), a wait for any key (`WAIT_AND_RESTART`), then `NEW_GAME`
([`loading.md`](loading.md)).

**Winning** (`CHECK_WON` $A9D6, first thing in `END_OF_TURN`): the valuable
treasure ($23) held by the wooden chest ($25) -- put there by anyone, in any
turn. A cheering crowd carries the player off; then the same wait and new
game as a death, without even showing the score ([`scoring.md`](scoring.md)).
The chest weighs 255 -- nobody can lift it -- so it stays in Bag End and the
treasure has to be brought home.

## How this was found

`DO_ATTACK` and its helpers were read line by line; the odd wear only showed
when the arithmetic was worked through for these notes, and was then checked
in four real fights in the simulator (the player given the sword and put
beside Thorin, `ATTACK THORIN WITH SWORD`, breakpoints at $91C1 for the
blow and guard and $91FB for the result). The deaths were collected from the
callers of `PLAYER_DIES` and `KILL`; the falls, the eyes, the bog and the
fight were run.

## Confidence

The fight's order and formula are *read*; the erratic wear is *read* and
*measured* in four fights. The margin-16 table overrun is *read*, and what it
prints *measured* by running the message; the blow itself was not produced.
The deaths are as tagged.

## Open questions

- Whether the designers knew the wear was erratic: fights against the
  trolls and the dragon would be decided by one lucky odd margin -- or, with
  the jostle bug, by one guard of 0.
- Whether a margin of exactly 16 happens in play often enough to have been
  seen: with two jostles of 0 to +10 each (or 0), it needs a guard 16 under
  the blow, which depends on the pair.
