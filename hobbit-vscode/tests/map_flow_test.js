'use strict';
// map_flow.js from plain Node:
//
//   node hobbit-vscode/tests/map_flow_test.js
//
// A made-up map for the rules, then -- when build_hobbit.py has written the
// snapshot -- the game's own, on its fixed layout, from every one of its places.

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
const cells = (entries) => new Map(entries.map(([l, x, y]) => [l, [x, y]]));

test('exits already on their own sides leave the map as it was', () => {
  const rooms = [room(1, [['E', 2]]), room(2, [['W', 1]])];
  const base = cells([[1, 0, 0], [2, 1, 0]]);
  assert.deepStrictEqual([...flow.adjust(rooms, base, 1)], [...base]);
});

test('a place on the wrong side moves next door, and nothing else does', () => {
  // 2 is north of 1 on the map but 1's exit to it says east.
  const rooms = [room(1, [['E', 2]]), room(2, []), room(3, [])];
  const base = cells([[1, 0, 0], [2, 0, -1], [3, 5, 5]]);
  const at = flow.adjust(rooms, base, 1);
  assert.deepStrictEqual(at.get(1), [0, 0]);
  assert.deepStrictEqual(at.get(2), [1, 0]);
  assert.deepStrictEqual(at.get(3), [5, 5]);
});

test('whatever was in the cell steps aside to the nearest free one', () => {
  const rooms = [room(1, [['E', 2]]), room(2, []), room(3, [])];
  const base = cells([[1, 0, 0], [2, 0, 3], [3, 1, 0]]);
  const at = flow.adjust(rooms, base, 1);
  assert.deepStrictEqual(at.get(2), [1, 0]);
  // 3 was at [1,0]; the nearest free cell to it that is not [1,0] itself.
  const [x, y] = at.get(3);
  assert.strictEqual(Math.max(Math.abs(x - 1), Math.abs(y)), 1);
  assert.notDeepStrictEqual([x, y], [0, 0]);
  const distinct = new Set([...at.values()].map((c) => c.join(',')));
  assert.strictEqual(distinct.size, 3);
});

test('up goes north after the compass exits, further along if north is taken', () => {
  const rooms = [room(1, [['U', 3], ['N', 2]]), room(2, []), room(3, [])];
  const base = cells([[1, 0, 0], [2, 4, 4], [3, 6, 6]]);
  const at = flow.adjust(rooms, base, 1);
  assert.deepStrictEqual(at.get(2), [0, -1]);
  assert.deepStrictEqual(at.get(3), [0, -2]);
});

test('the base layout is not changed', () => {
  const rooms = [room(1, [['E', 2]]), room(2, [])];
  const base = cells([[1, 0, 0], [2, 0, -1]]);
  flow.adjust(rooms, base, 1);
  assert.deepStrictEqual(base.get(2), [0, -1]);
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
  const layout = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'map_layout.json'), 'utf8')).cells;
  const base = new Map(Object.entries(layout).map(([l, c]) => [Number(l), c]));

  test('from every place, its own exits point their own way', () => {
    const wrong = [];
    for (const focus of rooms) {
      const at = flow.adjust(rooms, base, focus.location);
      assert.strictEqual(new Set([...at.values()].map((c) => c.join(','))).size, rooms.length);
      // A place reached in two directions can be on only one side.
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
        if (!flow.pointsItsWay(at, focus.location, e.to, e.direction)) {
          wrong.push(focus.location + ' ' + e.direction + ' ' + e.to);
        }
      }
    }
    assert.deepStrictEqual(wrong, []);
  });

  test('and the rest of the map stays where it was', () => {
    let most = 0;
    let total = 0;
    for (const focus of rooms) {
      const at = flow.adjust(rooms, base, focus.location);
      let moved = 0;
      for (const [l, [x, y]] of at) {
        const [bx, by] = base.get(l);
        if (x !== bx || y !== by) {
          moved++;
        }
      }
      // Each exit can move its own place and one it displaces.
      assert.ok(moved <= 2 * focus.exits.length, focus.location + ' moved ' + moved);
      most = Math.max(most, moved);
      total += moved;
    }
    console.log('      at most ' + most + ' places move, ' + (total / rooms.length).toFixed(1) + ' on average');
  });
}

if (failures) {
  console.log(failures + ' failed');
  process.exit(1);
}
console.log('all passed');
