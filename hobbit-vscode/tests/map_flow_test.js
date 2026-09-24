'use strict';
// map_flow.js from plain Node:
//
//   node hobbit-vscode/tests/map_flow_test.js
//
// A made-up map for the rules, then -- when build_hobbit.py has written the
// snapshot -- the game's own, from every one of its places.

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const flow = require('../map_flow');
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

const room = (location, exits) => ({
  location,
  exits: exits.map(([direction, to]) => ({ direction, via: 0, to })),
});

test('the focus is in the middle and its exits are on their own sides', () => {
  const rooms = [
    room(1, [['N', 2], ['E', 3], ['SW', 4], ['U', 5]]),
    room(2, [['S', 1]]),
    room(3, [['W', 1]]),
    room(4, [['NE', 1]]),
    room(5, [['D', 1]]),
  ];
  const cells = flow.flow(rooms, 1);
  assert.deepStrictEqual(cells.get(1), [0, 0]);
  assert.deepStrictEqual(cells.get(2), [0, -1]);
  assert.deepStrictEqual(cells.get(3), [1, 0]);
  assert.deepStrictEqual(cells.get(4), [-1, 1]);
  // Up goes north, but north was taken first: further along the same line.
  assert.deepStrictEqual(cells.get(5), [0, -2]);
});

test('another focus flows the same places the other way round', () => {
  const rooms = [room(1, [['E', 2]]), room(2, [['W', 1], ['E', 3]]), room(3, [['W', 2]])];
  const cells = flow.flow(rooms, 3);
  assert.deepStrictEqual(cells.get(3), [0, 0]);
  assert.deepStrictEqual(cells.get(2), [-1, 0]);
  assert.deepStrictEqual(cells.get(1), [-2, 0]);
});

test('a one-way exit still keeps its two places together', () => {
  // 2 leads to 1, but 1 has no way back: from 1, 2 is where 2's exit says.
  const rooms = [room(1, []), room(2, [['N', 1]])];
  const cells = flow.flow(rooms, 1);
  assert.deepStrictEqual(cells.get(2), [0, 1]);
});

test('places not reached from the focus are laid out below, none overlapping', () => {
  const rooms = [room(1, [['E', 2]]), room(2, [['W', 1]]), room(3, [['E', 4]]), room(4, [])];
  const cells = flow.flow(rooms, 1);
  assert.strictEqual(cells.size, 4);
  assert.ok(cells.get(3)[1] > 0);
  const distinct = new Set([...cells.values()].map((c) => c.join(',')));
  assert.strictEqual(distinct.size, 4);
});

// ---- the game's own map ------------------------------------------------------

const SNAPSHOT = path.join(__dirname, '..', '..', 'game_disassembly', 'hobbit', 'hobbit.sna');
if (!fs.existsSync(SNAPSHOT)) {
  console.log('skip  the game itself: no ' + SNAPSHOT + ' -- run build_hobbit.py first');
} else {
  const sna = fs.readFileSync(SNAPSHOT);
  const mem = new Uint8Array(0x10000);
  mem.set(sna.subarray(27, 27 + 0xC000), 0x4000);
  const rooms = model.readRooms(mem);

  test('from every place, its own exits point their own way', () => {
    const wrong = [];
    for (const focus of rooms) {
      const cells = flow.flow(rooms, focus.location);
      assert.strictEqual(new Set([...cells.values()].map((c) => c.join(','))).size, rooms.length);
      // A place reached in two directions can be on only one side: the game
      // gives the lonelands' east and north both to the trolls' clearing.
      const directionsTo = new Map();
      for (const e of focus.exits) {
        if (e.to && e.to !== focus.location) {
          directionsTo.set(e.to, (directionsTo.get(e.to) || 0) + 1);
        }
      }
      for (const e of focus.exits) {
        if (!e.to || e.to === focus.location || directionsTo.get(e.to) > 1) {
          continue;
        }
        if (!flow.pointsItsWay(cells, focus.location, e.to, e.direction)) {
          wrong.push(focus.location + ' ' + e.direction + ' ' + e.to);
        }
      }
    }
    assert.deepStrictEqual(wrong, []);
  });

  test('one step further out, nearly every exit points its own way too', () => {
    let right = 0;
    let all = 0;
    for (const focus of rooms) {
      const cells = flow.flow(rooms, focus.location);
      const near = new Set(focus.exits.map((e) => e.to));
      for (const r of rooms) {
        if (!near.has(r.location)) {
          continue;
        }
        for (const e of r.exits) {
          if (!e.to || e.to === r.location || !flow.COMPASS.includes(e.direction)) {
            continue;
          }
          all++;
          right += flow.pointsItsWay(cells, r.location, e.to, e.direction) ? 1 : 0;
        }
      }
    }
    console.log('      ' + right + ' of ' + all + ' (' + Math.round((100 * right) / all) + '%)');
    assert.ok(right / all > 0.75);
  });
}

if (failures) {
  console.log(failures + ' failed');
  process.exit(1);
}
console.log('all passed');
