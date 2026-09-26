# The Hobbit -- overview

A tour of the most interesting findings. Each section is a summary; follow the
link for the full account, the addresses and what is still open.

## The score is only ever for arriving somewhere

`SCORE` ($B6F7), in tenths of a per cent, is raised by one instruction in the
whole game: ARRIVE's `LD (SCORE),HL` at $8E65, which adds a place's entry in
`VISIT_SCORES` the first time the player gets there. Fourteen places are
listed, worth 750 between them -- so 75% is the most anyone can score, and
nothing the player does (taking the golden key, putting the treasure in the
chest, having Elrond read the map) adds anything. Confirmed by watchpoint in
live play, by searching the binary for every reference, and in the v1.0 tape
as well. [`scoring.md`](scoring.md)

## One road is shut at random, and Elrond opens it

Each new game `NEW_GAME_CHOICES` picks one of five roads from `HIDDEN_ROADS`
and zeroes its exit, so a different way is closed each game -- this game's
choice is kept in the operand of an instruction inside `ELROND_READS_MAP`.
When Elrond examines the map, that routine writes the exit back and he tells
the player the way. The flag meant to stop it being done twice, $B6F1, is
never set by anything. Watched happening in a real playthrough.
[`hidden-roads.md`](hidden-roads.md)

## Other characters act by the same code as the player

Each character's script is a list of actions tried as if the character had
typed them -- the action code and its objects go where the parser puts the
player's -- and `CHARACTERS_ACT` runs them through the same `ACTION_TABLE`.
Gandalf's scripts cycle through running about, taking things, giving and
dropping them, which is why he takes the map back in the Lonelands and returns
it a few turns later. [`driving.md`](driving.md) has what that means for a
playthrough.

## Versions

The tape archived as v1.0 is the first release, which its authors called
v1.1; v1.2 is the fix, laid out differently (40% of the bytes match) but with
the same scoring. The Sinclair Research re-release is v1.0.
[`versions.md`](versions.md)
