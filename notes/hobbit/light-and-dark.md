# Light and dark

**Question this answers:** what decides whether the player can see, what
lights a dark place, and what the dark does.

**Short answer:** 26 rooms are dark. Only the player is ever in the dark,
and the one light is the short strong sword: within reach and unbroken, it
lights anywhere -- lying on the floor will do. In the dark, moves go in a
random direction and a missing way out is a fall (the seventh kills), most
actions are refused, the picture is blacked out and the other characters are
heard, not seen. Shut inside a closed container, the player is in the dark
even in a lit room -- and cannot open it again.

## How it works

**`TOO_DARK` ($95ED)** returns carry for "cannot see" (*read*):

1. Anyone but the player (`ACTING` not 0) can see. Characters have no light
   problem at all.
2. If the player is shut inside something (`SHUT_IN` not $FF), skip the
   room: only the sword can help.
3. Otherwise a lit room (bit 7 of its byte 0) is enough.
4. The sword, object $0E, must be in reach (`IN_REACH`) and its flags, with
   `XOR $F7` and `AND $1C`, must come out 0: bit 2 set, bit 3 clear, bit 4
   set. It starts as $94, glowing.

So the torch, whose flags are the same, lights nothing: only the sword's
record is tested. A sword broken by `DO_STRIKE` (bit 3) no longer glows.

**The dark rooms** (*read*, bit 7 clear in 26 records): the trolls' cave (7),
the goblins' dungeon (13), the large dry cave (14), the big goblins' cavern
(16), the deep dark lake (17), the dark winding passage (18), inside the
goblins' gate (19), the elvenking's great halls, dark dungeon and cellar
(30-32), the smooth straight passage into the mountain (43), and the fifteen
dark stuffy passages (15, 52-65).

**What the dark does** (*read*, and *measured* where said):

- **`MOVE`** throws the direction away for `RANDOM_POSITIVE` 1-10, and
  narrates it as "you go somewhere". If there is no way that way the player
  falls: byte 5 (strength) is halved; while anything is left, "but fall and
  hit your head"; when it reaches 0, "but fall and smash your skull" and
  `PLAYER_DIES`. *Measured* 2026-09-27: with the sword moved out of the
  trolls' cave, seven NORTHs there took the player's strength 64, 32, 16, 8,
  4, 2, 1 and then killed. On arriving somewhere dark there is no
  description, no score and no picture: `MOVE` stops after the arrival hook.
- **`DO_ACTION`**: an action whose pattern needs light (`NEEDS_LIGHT`: TAKE,
  OPEN, EXAMINE, LOOK, INVENTORY and the other hands-on ones) is refused
  with "i see nothing here."; the others can only use what the actor
  carries. *Measured*: LOOK in the dark cave gave that refusal and "it is
  dark."
- **`CLEAR_CANVAS`**: the picture's border and colours are forced to black
  and the stream is not run, though the key wait after it still comes
  ([`pictures.md`](pictures.md)).
- **`CHARACTERS_ACT`**: `NOTE_LIGHT` sets `PLAYER_IN_DARK` ($980C) at the
  start of the characters' turn; then the first character doing anything the
  player could otherwise see is reported as "you hear a noise." and nothing
  more is printed that turn ([`characters.md`](characters.md)).

**The sword on the floor lights the room.** `IN_REACH` asks only whether the
sword is where the player is, not whether it is carried. *Measured*: in the
trolls' cave, where the sword lies on the tape, the player could see (LOOK
described the cave and the sword); moved out, the cave was dark.

**Shut in the barrel.** *Measured* 2026-09-27 with the barrel placed in Bag
End (lit): OPEN BARREL, CLIMB INTO BARREL and LOOK worked ("you are in the
barrel"); after CLOSE BARREL the player was in the dark, and OPEN BARREL,
LOOK and everything else got "i see nothing here." -- OPEN needs light and
the barrel is not something the player carries. Without the sword, a player
who closes the barrel over themselves stays shut in until something else
opens it (the butler's script opens the barrel in the cellar), or the barrel
is thrown through the trap door and its ride down the river ends two turns
later with the player thrown out onto the bank of the long lake
(`BARREL_REACHES_LAKE`; *measured*, see [`time-and-timers.md`](time-and-timers.md)).

## How this was found

`TOO_DARK` and its callers read on 2026-09-23, with the v1.0 disassembly's
remark that the sword is the only lamp as the lead. The falls, the sword on
the floor and the closed barrel were tried in the simulator for these notes,
the barrel because the annotation said the opposite of the code.

## Confidence

*Read*, and *measured* for the falls, the lit-by-the-floor sword and the
barrel. That the only ways out of the closed barrel are the butler and the
river is *read* from the scripts and `BARREL_REACHES_LAKE`, not tried.

## Disassembly corrections

- `TOO_DARK`'s description says "The player can see if inside something, or
  if the room is lit", and its comment at $95F5 "The player shut inside
  something can see". The code does the opposite: `SHUT_IN` returning a
  holder jumps past the lit-room test to the sword test, so a player shut in
  is in the dark unless the sword is in reach. *Measured* as above; corrected
  2026-09-27.
- The same description lists "fourteen identical stuffy dark passages" and
  leaves out the large dry cave, the dark winding passage and inside the
  goblins' gate. Fifteen rooms carry that name (15 and 52-65), and the 26 are
  as listed above. Corrected in the annotations 2026-09-27.

## Open questions

- Whether the closed-barrel trap was intended: in the book Bilbo is never
  inside a barrel with its lid on.
