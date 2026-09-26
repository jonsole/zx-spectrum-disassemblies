# The hidden road, and Elrond reading the map

**Question this answers:** what having Elrond read the map does.

**Short answer:** every new game one of five roads is shut at random by
zeroing its exit. When Elrond examines the curious map, he writes that exit
back and tells the player the way along it. Without him reading it, that road
does not exist in that game.

## How it works

```
START -> NEW_GAME_CHOICES ($97AD)
           IY = one of HIDDEN_ROADS at random
           store IY in the operand of ELROND_READS_MAP's LD IY ($A7D1)
           zero the three bytes of that road's exit in its room record

EXAMINE MAP, by Elrond -> ELROND_READS_MAP ($A7C4)
           not Elrond: the ordinary EXAMINE
           IY = the road (from its own operand, $A7D1)
           $B6F1 zero? (always) -> copy the saved three bytes back into the exit
           "go <direction> from the <place> to get to the <place>"
```

`HIDDEN_ROADS` ($C80E) holds five six-byte records: the location, the address
of the exit in the room records, and the exit's three bytes (direction, the
object it goes through, destination) -- the copy the road is put back from.

| Record | Road | Exit |
|---|---|---|
| $C80E | beorns house (22) north to great river (49) | $BD12 |
| $C814 | forest gate (24) east to bewitched gloomy place (25) | $BD26 |
| $C81A | treeless opening (21) west to outside goblins gate (20) | $BCF8 |
| $C820 | long lake (34) east to lake town (35) | $BDE2 |
| $C826 | misty mountain (10) east to narrow place (11) | $BB0A |

The choice is `RANDOM_POSITIVE` given 4 (per the annotations, the first and
last records come up half as often as the other three).

The player cannot do this; the map's own EXAMINE handler checks the actor is
Elrond ($41). Elrond acts on "read the map" on his own turn, after the
player's next command -- so SAY TO ELROND "READ MAP" is followed by the
reading one turn later.

To detect it in a running game: read the word at $A7D1 (this game's record),
the exit address at record+1, and put a write watchpoint on those three bytes;
or a breakpoint or logpoint at $A7E0, which runs only when the road is put back.

## How this was found

*Played* on the original v1.2: from Bag End, OPEN DOOR, E, then waited while
Gandalf held the map (he took it in the Lonelands and gave it back three
turns later), E, SE past the trolls to Rivendell, GIVE MAP TO ELROND,
SAY TO ELROND "READ MAP", WAIT. *Watched* with a watchpoint on $BCF8 (3
bytes) and logpoints at $97D3 and $A7E0:

- during the load: NEW_GAME_CHOICES zeroed $BCF8 (the treeless opening's
  west exit, record $C81A);
- on the WAIT: ELROND_READS_MAP wrote it back ($A7E5), 00 -> 04 and 00 -> 14;
- `run_back_to_write` on $BCF8 then landed on the same instruction.

Breakpoint-driven input made every restart choose the same road, $C81A.

## Confidence

The mechanism is read and watched. That every restart chose $C81A is only
true of identical input; a game typed by hand gets a different road.

## Disassembly corrections

- **$B6F1** was described as "Elrond has read the map and the shut road is
  open again". Nothing ever sets it: NEW_GAME_CHOICES clears it and no other
  instruction writes it (the only other `F1 B6` in memory is `POP AF`,
  `OR (HL)` in the picture code). So the "already put back?" test never
  passes, and the road is rewritten, to the same bytes, every time Elrond
  reads the map. Watched: still 0 after he read it. The descriptions of
  $B6F1, `NEW_GAME_CHOICES` and `ELROND_READS_MAP` now say so.

## Open questions

- Your Sinclair #5 (quoted in ZXDB) says the first release could not go east
  from the town in the middle of the long lake, blaming "the routine where
  you must ask Elrond to read the map". The nearest record here is long lake
  (34) east to lake town (35), which is not quite that exit. v1.0's
  `NEW_GAME_CHOICES`, `ELROND_READS_MAP` and `HIDDEN_ROADS` have not yet been
  compared with v1.2's to see what was fixed.
