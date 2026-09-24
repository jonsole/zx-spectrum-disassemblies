'use strict';
// hobbit_model.js from plain Node:
//
//   node hobbit-vscode/tests/hobbit_model_test.js
//
// The log's assembly is tested with made-up reports. Reading the game is
// tested against the snapshot build_hobbit.py writes, when it is there --
// game_disassembly/ is not committed, so without a build this part says so
// and skips. What it expects are facts the disassembly worked out, not
// numbers copied from this code's own output.

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const model = require('../hobbit_model');

let failures = 0;
function test(name, fn) {
  try {
    fn();
    console.log('  ok  ' + name);
  } catch (e) {
    failures++;
    console.log('FAIL  ' + name + '\n      ' + (e && e.message));
  }
}

test('flags read highest bit first, a letter per bit set', () => {
  // The sword starts as $94: visible, gives light, full.
  assert.strictEqual(model.flagLetters(0x94), 'v..*.f..');
  assert.strictEqual(model.flagLetters(0x00), '........');
  assert.ok(model.flagWords(0x41).includes('a character'));
  assert.ok(model.flagWords(0x41).includes('locked'));
});

test('the log makes lines, each with who it was about', () => {
  const log = new model.LogAssembler();
  const report = (c, actor, input) =>
    '0x' + c.toString(16) + ' 0x' + actor.toString(16) + ' 0x' + (input ? '1' : '0');
  const finished = log.push([
    report(0x48, 0, false), report(0x49, 0, false), report(0x0D, 0, false),
    // Thorin's line, with a character typed in the input window in the middle
    // of it, which is not part of the story.
    report(0x54, 0x3F, false), report(0x58, 0, true), report(0x57, 0x3F, false),
    report(0x0D, 0x3F, false),
    // Unfinished: not a line yet.
    report(0x47, 0x3E, false),
  ]);
  assert.deepStrictEqual(finished, [{ actor: 0, kind: 'shown', text: 'HI' }, { actor: 0x3F, kind: 'shown', text: 'TW' }]);
  assert.strictEqual(log.lines.length, 2);
  // The rest arrives later and finishes it.
  const later = log.push([report(0x4F, 0x3E, false), report(0x0D, 0x3E, false)]);
  assert.deepStrictEqual(later, [{ actor: 0x3E, kind: 'shown', text: 'GO' }]);
});

test('each line says whether it was shown, done unseen, or only considered', () => {
  const log = new model.LogAssembler();
  // Character, actor, input window, DOING_IT, PRINTING_ON.
  const r = (c, doing, printing) => '0x' + c.toString(16) + ' 0x43 0x0 0x' + doing + ' 0x' + printing;
  const finished = log.push([r(0x41, 1, 1), r(0x0D, 1, 1), r(0x42, 1, 0), r(0x0D, 1, 0),
                             r(0x43, 0, 0), r(0x0D, 0, 0)]);
  assert.deepStrictEqual(finished.map((l) => l.kind), ['shown', 'unseen', 'considered']);
});

test('words get their spaces back, and a wrap on the screen is not a line end', () => {
  const log = new model.LogAssembler();
  const r = (c) => '0x' + c.toString(16) + ' 0x0 0x0 0x1 0x0';
  const letters = (w) => [...w].map((ch) => r(ch.charCodeAt(0)));
  const finished = log.push([
    // Unseen text comes without the space before each word; the markers where
    // words start put them back.
    'word', ...letters('the'), 'word', ...letters('troll'), r(0x2E),
    // Where a word would not fit the screen's line, the game starts a new one:
    // the wrap marker says that line end is not the sentence's.
    'word', ...letters('waits'), 'wrap', r(0x0D), 'word', ...letters('here'), r(0x0D),
  ]);
  assert.deepStrictEqual(finished.map((l) => l.text), ['the troll. waits here']);
});

test('a new game starts a line of its own, cutting off what was being said', () => {
  const log = new model.LogAssembler();
  const finished = log.push(['0x48 0x0 0x0 0x1 0x1', 'newgame', '0x49 0x0 0x0 0x1 0x1', '0x0d 0x0 0x0 0x1 0x1']);
  assert.deepStrictEqual(finished.map((l) => l.kind), ['shown', 'newgame', 'shown']);
  assert.strictEqual(finished[1].actor, null);
});

test('byte 4 in words: how things are placed, and the sides', () => {
  assert.strictEqual(model.placedWords(0x00), 'in');
  assert.strictEqual(model.placedWords(0x04), 'tied to');
  // Elrond is on two sides, 1 and 4: $50.
  assert.strictEqual(model.placedWords(0x51), 'on, side 1+4');
});

test('the log keeps only its limit', () => {
  const log = new model.LogAssembler(2);
  for (let i = 0; i < 5; i++) {
    log.push(['0x41 0x0 0x0', '0x0d 0x0 0x0']);
  }
  assert.strictEqual(log.lines.length, 2);
});

// ---- the game itself, from a built snapshot --------------------------------

const SNAPSHOT = path.join(__dirname, '..', '..', 'game_disassembly', 'hobbit', 'hobbit.sna');

function snapshotMemory() {
  const sna = fs.readFileSync(SNAPSHOT);
  // A 48K .sna: 27 bytes of registers, then RAM from $4000.
  const mem = new Uint8Array(0x10000);
  mem.set(sna.subarray(27, 27 + 0xC000), 0x4000);
  return mem;
}


if (!fs.existsSync(SNAPSHOT)) {
  console.log('skip  the game itself: no ' + SNAPSHOT + ' -- run build_hobbit.py first');
} else {
  const mem = snapshotMemory();
  const state = model.readState(mem);

  test('it is recognised as The Hobbit v1.2', () => {
    assert.ok(model.isHobbit(mem));
    assert.ok(state);
    assert.ok(!model.readState(new Uint8Array(0x10000)), 'empty memory is not the game');
  });

  test('79 locations, each named and with its exits', () => {
    assert.strictEqual(state.rooms.length, 79);
    const bagEnd = state.rooms.find((r) => r.location === 1);
    assert.strictEqual(bagEnd.name, 'tunnel like hall');
    // Bag End's one exit: east, through the round green door, to the lonelands.
    assert.deepStrictEqual(bagEnd.exits, [{ direction: 'E', via: 5, to: 4 }]);
    const lonelands = state.rooms.find((r) => r.location === 4);
    assert.strictEqual(lonelands.name, 'lonelands');
    assert.strictEqual(lonelands.exits.length, 4);
  });

  test('61 objects, the door in two places and the sword glowing', () => {
    assert.strictEqual(state.objects.length, 61);
    const door = state.objects.find((o) => o.number === 5);
    assert.strictEqual(door.name, 'round green door');
    assert.deepStrictEqual(door.locations, [1, 4]);
    const sword = state.objects.find((o) => o.number === 0x0E);
    assert.strictEqual(sword.name, 'short strong sword');
    assert.strictEqual(sword.flags, 0x94);
  });

  test('seventeen characters besides the player, who is at Bag End with no score', () => {
    const characters = state.objects.filter((o) => o.number !== 0 && (o.flags & 0x40));
    assert.strictEqual(characters.length, 17);
    assert.deepStrictEqual(characters.map((o) => o.number), [...Array(17).keys()].map((i) => 0x3C + i));
    assert.strictEqual(state.playerAt, 1);
    assert.strictEqual(state.score, 0);
  });

  test('seventeen character slots, three of them waiting for the story to bring their owner in', () => {
    assert.strictEqual(state.characters.length, 17);
    const waiting = state.characters.filter((c) => !c.inStory);
    // The butler, Bard and the dragon: ARRIVAL_HOOKS fill these slots in.
    assert.deepStrictEqual(waiting.map((c) => c.slot), [0xCAE7, 0xCAFC, 0xCB03]);
    assert.deepStrictEqual(waiting.map((c) => c.number), [0x42, 0x46, 0x3C]);
    for (const c of state.characters.filter((c) => c.inStory)) {
      assert.ok(c.next && c.next.text, 'a next step for character ' + c.number);
    }
  });

  test('action codes read as sentences, the directions with their direction', () => {
    // Codes 1-10 are the directions, 1 north (the disassembly's DIRECTIONS).
    assert.ok(model.actionSentence(mem, 1).includes('north'));
    assert.ok(model.actionSentence(mem, 3).includes('east'));
  });

  test('Gandalf starts out carrying the curious map', () => {
    const gandalf = state.characters.find((c) => c.number === 0x3E);
    assert.deepStrictEqual(gandalf.carrying, ['curious map']);
  });

  test('ten timers, none running before the game starts', () => {
    assert.strictEqual(state.timers.length, 10);
    assert.ok(state.timers.every((t) => t.left === 0));
    assert.ok(state.timers.every((t) => t.routine > 0x6000));
  });
}

if (failures) {
  console.log(failures + ' failed');
  process.exit(1);
}
console.log('all passed');
