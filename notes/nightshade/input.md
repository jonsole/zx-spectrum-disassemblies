# Controls and the pause

**Question this answers:** which keys and joysticks do what, how the game
pauses, and what the stray `OUT` in the key reader would do on a 128K.

**Short answer:** `READ_CONTROLS` ($E241) reads one of four methods into
`CONTROLS` ($BC01): bit 0 left, 1 right, 2 up (walk), 3 fire, 4 down, 5 turn
the town round. SPACE or CAPS SHIFT on its own pauses (`PAUSE`, $E32C),
silently. `READ_KEYS` writes to port $xxFD before every read, which a 128K
would take as a paging command.

## How it works

| Method (`CONTROL` bits 1-2) | Left | Right | Up | Fire | Down |
|---|---|---|---|---|---|
| 0 keyboard | X V B M | C N | A-G, H-ENTER | Q-T, Y-P | any number |
| 1 Kempston (port 31) | left | right | up | fire | down |
| 2 cursor | 5 | 8 | 7 | 0 | 6 |
| 3 Interface II | 6, 1 | 7, 2 | 9, 4 | 0, 5 | 8, 3 |

- With every method, Z or SYMBOL SHIFT sets bit 5 (half-rows $7F and $FE
  read together). The keyboard's bottom row is not Pentagram's alternating
  left/right: Z and SYMBOL SHIFT became the view key, and of the rest X, V,
  B, M turn one way and C and N the other. Bits 6 and 7 are never set.
- The menu picks the method (keys 1-4) and directional control (key 5)
  ([`menu-and-panel.md`](menu-and-panel.md)); what each bit does in play is
  the knight's ([`knight.md`](knight.md)): "down" matters only with a stick
  and directional control.
- `PAUSE`: half-rows $7F and $FE together; needs bit 0 (SPACE or CAPS SHIFT)
  and none of the others, so no key that plays starts one; waits for
  release, press, release. No beeps; interrupts stay off.
- **The stray OUT.** `READ_KEYS` ($E239) does `OUT ($FD),A` before
  `IN A,($FE)`. Nothing on a 48K answers. A 128K's paging port decodes it
  whenever A has bit 7 clear, and the game sends $7F (keyboard) and $7E
  (every turn, all methods, and the pause): in 128 mode that would page
  RAM 7 or 6 over the top 16K -- where the code from $C000 and all the
  tables live -- show the other screen and lock the paging.

## How this was found

Read, then *measured* (stage 2, range 5): `READ_CONTROLS` run in the
simulator with each key held alone under methods 0, 2 and 3, and each
Kempston bit under method 1; the ports written were logged.

## Confidence

The mapping *measured*; the 128K consequence *read* (not tried on a 128K;
Pentagram's identical `READ_KEYS` was tried there and reset the machine at
the first turn of play).

## Filmation (Knight Lore, Alien 8, Pentagram)

`READ_KEYS` is byte for byte the earlier games'. `READ_CONTROLS` is Alien
8's (0.86) and Pentagram's (0.77) shape with Nightshade's bit layout and
the view key. `PAUSE` is Alien 8's `HANDLE_PAUSE` (0.91) less the beeps
and the `EI`.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `READ_KEYS` | `SUBE239` | $E239 | a half-row (the earlier games' name) |
| `READ_CONTROLS` | `SUBE241` | $E241 | the controls |
| `PAUSE` | `SUBE32C` | $E32C | the pause |

## Open questions

- Whether the 128K lock-up happens on a real 128K in 128 mode: stage 3 may
  try it live (`--machine 128`), as was done for Pentagram.
