# Versions

**Question this answers:** which releases exist, which tape is which, and what
differs between them.

**Short answer:** two releases on tape: the first, archived as **v1.0** (its
authors called it v1.1), and the bug-fixed **v1.2**, which puts the
programmers' names on the loading screen. The Sinclair Research re-release is
v1.0. The disassembly is of v1.2.

## What exists

| Tape | Is | Where |
|---|---|---|
| `HobbitV1.2.tzx` | v1.2, the one disassembled | `tapes/`, ZXDB |
| `HobbitV1.0.tzx` | the first release ("v1.1") | `tapes/`, ZXDB |
| Sinclair Research re-release | v1.0 | ZXDB (`HobbitThe(SinclairResearchLtd).tzx`) |
| v1.2 text only | not examined | ZXDB |

No tape labelled v1.1 is archived anywhere looked (ZXDB, Spectrum Computing,
World of Spectrum). Wilderland's README explains why: the initial release was
"called V 1.1 for 'vanity' reasons", and it supports "V 1.0 (1.1)" and v1.2.
It also mentions a "V OWN", its author's own copy, which is neither and is
not archived.

## What differs

*Measured*, loading each tape with `tap2sna` and comparing $6000-$FFFF:

- **v1.0 against v1.2:** 16328 of 40960 bytes the same. The code has moved
  about, so compare by pattern, not address.
- **Sinclair against v1.0:** 40946 of 40960 the same, and the 14 that differ
  are not the game -- one byte of the FRAMES system variable, and leftovers of
  the loader's stack at $5FD4-$5FDF and $FF38-$FF45.

Found in both, by the score-add pattern `2A nn nn 19 22 nn nn`:

| | v1.0 | v1.2 |
|---|---|---|
| `SCORE` | $B5E8 | $B6F7 |
| set to 0 in START | $6CC2 | $6CCA |
| read by SHOW_SCORE | $81BA | $8401 |
| the visit-score add | $8E10 | $8E61 |
| `VISIT_SCORES` | $8CEA, identical | $8D6E |

## Open questions

- What v1.2 fixed. ZXDB's note (from Your Sinclair #5) says the first release
  could not be finished because a road near the long lake never opened; see
  [`hidden-roads.md`](hidden-roads.md). A routine-by-routine comparison of
  the two versions has not been done.

## Sources

- [Wilderland README](https://github.com/efa/Wilderland/blob/master/README.txt)
- [The Hobbit at Spectrum Computing / ZXDB](https://spectrumcomputing.co.uk/entry/6440/ZX-Spectrum/The_Hobbit)
