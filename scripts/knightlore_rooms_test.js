// Tests for knightlore_rooms.js, against the Python it follows.
//
//   node scripts/knightlore_rooms_test.js
//
// Needs a snapshot of the game, which is never committed: the castle
// knightlore_rooms.py extract leaves in game_disassembly/knightlore/rooms/.
// Without one it says so and skips. It also reads the remake's carried
// graphics.json, sprites.json and sprites.png from the emulator repository
// this one is a submodule of -- the files the standalone editor carries.
'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const kl = require('./knightlore_rooms.js');

const ROOT = path.resolve(__dirname, '..');
const CASTLE = path.join(ROOT, 'game_disassembly', 'knightlore', 'rooms');
const REMAKE = path.resolve(ROOT, '..', 'examples', 'filmation', 'knightlore');

let failed = 0;
function test(name, fn) {
  try {
    fn();
    console.log('ok   ' + name);
  } catch (err) {
    failed++;
    console.log('FAIL ' + name + '\n' + (err.stack || err));
  }
}

const snaPath = path.join(CASTLE, 'original.sna');
if (!fs.existsSync(snaPath) || !fs.existsSync(REMAKE)) {
  console.log('skipped: no ' + snaPath + ' (run knightlore_rooms.py extract) or no ' + REMAKE);
  process.exit(0);
}
const original = kl.readSnapshot(fs.readFileSync(snaPath), 'original.sna');
const read = function (dir, leaf) { return JSON.parse(fs.readFileSync(path.join(dir, leaf), 'utf8')); };
const graphics = read(REMAKE, 'graphics.json');
const sheet = read(REMAKE, 'sprites.json');

function merged(castle) {
  const atlas = JSON.parse(JSON.stringify(castle.rooms));
  atlas.sceneryTemplates = JSON.parse(JSON.stringify(castle.templates.sceneryTemplates));
  atlas.objectTemplates = JSON.parse(JSON.stringify(castle.templates.objectTemplates));
  return atlas;
}

function build(atlas, specials) {
  const packed = kl.packCastle(original, atlas, specials, graphics);
  return Object.assign(kl.applyWrites(original, packed.writes), { report: packed.report });
}

test('the snapshot is the original, with its tables where the disassembly says', function () {
  kl.checkOriginal(original);
});

test('decoding gives what knightlore_rooms.py extract wrote, but for meta', function () {
  const castle = kl.decodeCastle(original, graphics);
  const rooms = read(CASTLE, 'rooms.json');
  const templates = read(CASTLE, 'templates.json');
  const specials = read(CASTLE, 'specials.json');
  assert.deepStrictEqual(castle.rooms.rooms, rooms.rooms);
  assert.deepStrictEqual(castle.rooms.roomDimensions, rooms.roomDimensions);
  assert.deepStrictEqual(castle.rooms.meta.rules, rooms.meta.rules);
  // The four start_locations at $D1E2, from the disassembly.
  assert.deepStrictEqual(castle.rooms.startRooms, [0x2F, 0x44, 0xB3, 0x8F]);
  if (rooms.startRooms !== undefined) assert.deepStrictEqual(castle.rooms.startRooms, rooms.startRooms);
  assert.deepStrictEqual(castle.templates.sceneryTemplates, templates.sceneryTemplates);
  assert.deepStrictEqual(castle.templates.objectTemplates, templates.objectTemplates);
  assert.deepStrictEqual(castle.specials.collectables, specials.collectables);
  assert.deepStrictEqual(castle.specials.wanted, specials.wanted);
});

test('the castle as decoded packs back into the original byte for byte', function () {
  const castle = kl.decodeCastle(original, graphics);
  const built = build(merged(castle), castle.specials);
  assert.strictEqual(built.changed, 0);
  assert.strictEqual(built.report.free, 0);
  // The busiest room as shipped is the one that fills the table.
  assert.deepStrictEqual(built.report.fullest, [36, 0xF0]);
});

// A PNG's pixels, for the one sprites.png sheet.py writes: 8-bit RGBA, not
// interlaced. Enough of the format to compare against, not a general reader.
function readPng(file) {
  const raw = fs.readFileSync(file);
  let at = 8;
  let width = 0;
  let height = 0;
  const idat = [];
  while (at < raw.length) {
    const length = raw.readUInt32BE(at);
    const type = raw.toString('ascii', at + 4, at + 8);
    const body = raw.subarray(at + 8, at + 8 + length);
    if (type === 'IHDR') {
      width = body.readUInt32BE(0);
      height = body.readUInt32BE(4);
      assert.strictEqual(body[8], 8);
      assert.strictEqual(body[9], 6);
      assert.strictEqual(body[12], 0);
    } else if (type === 'IDAT') {
      idat.push(body);
    }
    at += 12 + length;
  }
  const data = zlib.inflateSync(Buffer.concat(idat));
  const stride = width * 4;
  const out = new Uint8Array(width * height * 4);
  for (let y = 0; y < height; y++) {
    const filter = data[y * (stride + 1)];
    for (let x = 0; x < stride; x++) {
      const v = data[y * (stride + 1) + 1 + x];
      const a = x >= 4 ? out[y * stride + x - 4] : 0;
      const b = y ? out[(y - 1) * stride + x] : 0;
      const c = x >= 4 && y ? out[(y - 1) * stride + x - 4] : 0;
      let p;
      if (filter === 0) p = 0;
      else if (filter === 1) p = a;
      else if (filter === 2) p = b;
      else if (filter === 3) p = (a + b) >> 1;
      else {
        const e = a + b - c;
        const pa = Math.abs(e - a);
        const pb = Math.abs(e - b);
        const pc = Math.abs(e - c);
        p = pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
      }
      out[y * stride + x] = (v + p) & 0xFF;
    }
  }
  return { width: width, height: height, pixels: out };
}

test('the sheet painted from the snapshot is sprites.png, sprite for sprite', function () {
  const painted = kl.sheetPixels(original, sheet, graphics);
  const png = readPng(path.join(REMAKE, 'sprites.png'));
  let checked = 0;
  (function walk(node, trail) {
    for (const key of Object.keys(node.sprites || {})) {
      const s = node.sprites[key];
      for (let y = s.y; y < s.y + s.h; y++) {
        for (let x = s.x; x < s.x + s.w; x++) {
          for (let k = 0; k < 4; k++) {
            const want = png.pixels[(y * png.width + x) * 4 + k];
            const got = painted.pixels[(y * painted.width + x) * 4 + k];
            if (want !== got) {
              assert.fail(trail.concat([key]).join('.') + ' differs at ' + x + ',' + y);
            }
          }
        }
      }
      checked++;
    }
    for (const g of Object.keys(node.group || {})) walk(node.group[g], trail.concat([g]));
  })(sheet, []);
  assert.strictEqual(checked, 103);
});

test('an edited castle packs, moves the tables, and decodes back as edited', function () {
  const castle = kl.decodeCastle(original, graphics);
  const atlas = merged(castle);
  const by = new Map(atlas.rooms.map(function (r) { return [r.number, r]; }));
  // Room $F0's objects pay for the rest: a new 30th template, a copy of the
  // chest, placed in the four start rooms, which are also recoloured.
  by.get(0xF0).objects = [];
  by.get(0xBF).objects = [];
  atlas.objectTemplates.object_chest_copy = JSON.parse(JSON.stringify(atlas.objectTemplates.object_chest));
  for (const n of [0x2F, 0x44, 0xB3, 0x8F]) {
    by.get(n).ink = 2;
    by.get(n).objects.push({ template: 'object_chest_copy', positions: [
      { u: 2, v: 5, z: 0 }, { u: 3, v: 5, z: 0 }, { u: 4, v: 5, z: 0 }] });
  }
  const specials = JSON.parse(JSON.stringify(castle.specials));
  specials.collectables[0] = { room: 0xB3, u: 100, v: 110, z: 128 };
  atlas.startRooms = [0xB3, 0xB3, 0x2F, 0x00];
  const built = build(atlas, specials);
  assert.ok(built.report.blockTypeTbl < kl.BLOCK_TYPE_TBL);
  for (const addr of kl.BLOCK_TYPE_OPERANDS) assert.strictEqual(kl.word(built.sna, addr), built.report.blockTypeTbl);
  for (const addr of kl.BACKGROUND_TYPE_OPERANDS) assert.strictEqual(kl.word(built.sna, addr), built.report.backgroundTypeTbl);
  // The copy costs a pointer and no body: it shares the chest's.
  const tbl = built.report.blockTypeTbl;
  assert.strictEqual(kl.word(built.sna, tbl + 2 * 29), kl.word(built.sna, tbl + 2 * 6));

  const back = kl.decodeCastle(built.sna, graphics);
  // The decoder has no name for a template the game never had, so it calls it
  // by its index; everything else comes back by the names it went in with.
  const renamed = JSON.parse(JSON.stringify(atlas));
  delete renamed.objectTemplates.object_chest_copy;
  renamed.objectTemplates.object_extra_29 = atlas.objectTemplates.object_chest_copy;
  for (const room of renamed.rooms) {
    for (const g of room.objects) if (g.template === 'object_chest_copy') g.template = 'object_extra_29';
  }
  assert.deepStrictEqual(back.rooms.rooms, renamed.rooms);
  assert.deepStrictEqual(back.rooms.startRooms, [0xB3, 0xB3, 0x2F, 0x00]);
  assert.deepStrictEqual(back.templates.objectTemplates, renamed.objectTemplates);
  assert.deepStrictEqual(back.templates.sceneryTemplates, renamed.sceneryTemplates);
  assert.deepStrictEqual(back.specials.collectables, specials.collectables);
});

test('what the original cannot hold is refused, saying why', function () {
  const refused = function (edit, pattern) {
    const castle = kl.decodeCastle(original, graphics);
    const atlas = merged(castle);
    edit(atlas, new Map(atlas.rooms.map(function (r) { return [r.number, r]; })));
    assert.throws(function () { build(atlas, castle.specials); },
                  function (err) { return err instanceof kl.CastleError && pattern.test(err.message); });
  };
  // A 37th record in the fullest room.
  refused(function (a, by) {
    by.get(0xF0).objects.push({ template: 'object_block', positions: [{ u: 0, v: 0, z: 3 }] });
  }, /room \$F0 \(240\) fills 37 object records/);
  // Two bytes more than there are: a copy of walls_0 is a new body.
  refused(function (a) {
    a.sceneryTemplates.scenery_big = JSON.parse(JSON.stringify(a.sceneryTemplates.scenery_walls_0));
    a.sceneryTemplates.scenery_big[0].u += 1;
  }, /needs \d+ bytes and the original has 3498/);
  // A start in a room that is not there, and too few of them.
  refused(function (a) { a.startRooms = [0x2F, 0x44, 0xB3, 0x16]; }, /start in room 22, which is not a room/);
  refused(function (a) { a.startRooms = [0x2F]; }, /one of four starting rooms/);
  // A room with nothing in it.
  refused(function (a, by) { by.get(0).scenery = []; by.get(0).objects = []; }, /has nothing in it/);
  // Nine in a group.
  refused(function (a, by) {
    const spots = [];
    for (let i = 0; i < 9; i++) spots.push({ u: i % 8, v: 0, z: 0 });
    by.get(0x2F).objects.push({ template: 'object_block', positions: spots });
  }, /a group holds one to eight/);
});

test('a starting room has to have the middle of its floor clear', function () {
  const castle = kl.decodeCastle(original, graphics);
  const atlas = merged(castle);
  // The designer's own test, to hold the two to agreeing on every room.
  const model = require(path.resolve(ROOT, '..', 'examples', 'filmation', 'vscode', 'room_model.js'));
  const sheetModel = require(path.resolve(ROOT, '..', 'examples', 'filmation', 'vscode', 'sheet_model.js'));
  const numbers = model.graphicNumbers(sheet, graphics);
  const sizes = model.graphicBoxes(sheet, graphics);
  const withTemplates = model.withTemplates(JSON.parse(JSON.stringify(castle.rooms)), castle.templates);
  const known = new Map();
  for (const name of Object.keys(graphics.graphics)) {
    if (graphics.graphics[name].sprite) known.set(graphics.graphics[name].number, name);
  }
  let blocked = 0;
  for (const room of atlas.rooms) {
    const here = kl.startBlocker(atlas, room, known, sheetModel.graphicSizes(sheet, graphics));
    const there = model.startBlockers(withTemplates, withTemplates.rooms.find((r) => r.number === room.number),
                                      numbers, sizes);
    assert.strictEqual(Boolean(here), there.length > 0, 'room ' + room.number + ': ' + here);
    if (here) blocked++;
  }
  // The game's own four are clear, and some rooms are not -- so the test
  // tells them apart rather than passing everything.
  for (const n of castle.rooms.startRooms) {
    assert.strictEqual(kl.startBlocker(atlas, atlas.rooms.find((r) => r.number === n), known,
                                       sheetModel.graphicSizes(sheet, graphics)), null);
  }
  assert.ok(blocked > 0 && blocked < atlas.rooms.length, blocked + ' rooms blocked');

  // A block put in the middle of a starting room stops the build. Room $F0's
  // objects pay for its bytes, so it is the start that is refused.
  atlas.rooms.find((r) => r.number === 0xF0).objects = [];
  const b3 = atlas.rooms.find((r) => r.number === 0xB3);
  b3.objects.push({ template: 'object_block', positions: [{ u: 3, v: 3, z: 0 }] });
  assert.throws(function () { build(atlas, castle.specials); },
                /room \$B3 is a starting room, and object_block at 3,3,0 stands in the middle/);
  // ...and one up where he is not, does not.
  b3.objects[b3.objects.length - 1].positions = [{ u: 3, v: 3, z: 3 }];
  build(atlas, castle.specials);
});

test('a castle can have more floor shapes, and the rooms move down to make room', function () {
  const castle = kl.decodeCastle(original, graphics);
  assert.deepStrictEqual(Object.keys(castle.rooms.roomDimensions), ['square', 'narrowU', 'narrowV']);
  assert.strictEqual(kl.word(original, kl.LOCATION_OPERAND), 0x6251);
  const atlas = merged(castle);
  // A fourth shape, a smaller square, for room $B3; room $F0's objects pay
  // for its three bytes.
  atlas.roomDimensions.small = { u: 48, v: 48, z: 128 };
  atlas.rooms.find((r) => r.number === 0xB3).dimensions = 'small';
  atlas.rooms.find((r) => r.number === 0xF0).objects = [];
  const built = build(atlas, castle.specials);
  assert.strictEqual(built.report.shapes, 4);
  // Twelve bytes of sizes where there were nine: the rooms start three on.
  assert.strictEqual(kl.word(built.sna, kl.LOCATION_OPERAND), 0x6254);
  const back = kl.decodeCastle(built.sna, graphics);
  assert.deepStrictEqual(Object.values(back.rooms.roomDimensions), Object.values(atlas.roomDimensions));
  assert.strictEqual(back.rooms.rooms.find((r) => r.number === 0xB3).dimensions, 'shape_3');
  assert.strictEqual(back.rooms.rooms.find((r) => r.number === 0x2F).dimensions,
                     atlas.rooms.find((r) => r.number === 0x2F).dimensions);

  // A half-size that would put a wall outside the byte, and one shape too many.
  atlas.roomDimensions.small.u = 128;
  assert.throws(function () { build(atlas, castle.specials); }, /the shape small: u is 1 to 127/);
  atlas.roomDimensions.small.u = 48;
  for (let n = 4; n < 33; n++) atlas.roomDimensions['s' + n] = { u: 8, v: 8, z: 128 };
  assert.throws(function () { build(atlas, castle.specials); }, /33 floor shapes; a room names one in five bits, so 1 to 32/);
});

test('a snapshot that is not the original is refused', function () {
  const patched = original.slice();
  patched[27 + 0xD3CA - 0x4000] ^= 1;
  assert.throws(function () { kl.checkOriginal(patched); }, /does not look like the original/);
  assert.throws(function () { kl.readSnapshot(new Uint8Array(100), 'x.sna'); }, /48K one is 49179/);
  assert.throws(function () { kl.readSnapshot(new Uint8Array(100), 'x.tap'); }, /not a snapshot/);
});

// A version-1 .z80 of the same machine, uncompressed and compressed, both
// come back as the .sna they were made from.
test('a .z80 is read as the .sna it holds', function () {
  const h = new Uint8Array(30);
  const sna = original;
  const sp = (sna[23] | (sna[24] << 8));
  const pc = sna[27 + sp - 0x4000] | (sna[27 + sp - 0x4000 + 1] << 8);
  const ram = sna.slice(27);
  h[0] = sna[22]; h[1] = sna[21];                 // A, F
  h[2] = sna[13]; h[3] = sna[14];                 // BC
  h[4] = sna[9]; h[5] = sna[10];                  // HL
  h[6] = pc & 0xFF; h[7] = pc >> 8;
  h[8] = (sp + 2) & 0xFF; h[9] = (sp + 2) >> 8;
  h[10] = sna[0];
  h[11] = sna[20] & 0x7F;
  h[12] = ((sna[20] >> 7) & 1) | ((sna[26] & 7) << 1);
  h[13] = sna[11]; h[14] = sna[12];               // DE
  h[15] = sna[5]; h[16] = sna[6];                 // BC'
  h[17] = sna[3]; h[18] = sna[4];                 // DE'
  h[19] = sna[1]; h[20] = sna[2];                 // HL'
  h[21] = sna[8]; h[22] = sna[7];                 // A', F'
  h[23] = sna[15]; h[24] = sna[16];               // IY
  h[25] = sna[17]; h[26] = sna[18];               // IX
  h[27] = h[28] = sna[19] & 4 ? 1 : 0;
  h[29] = sna[25] & 3;
  const plain = new Uint8Array(30 + ram.length);
  plain.set(h);
  plain.set(ram, 30);
  assert.deepStrictEqual(kl.readSnapshot(plain, 'k.z80'), original);

  // Runs of five or more, and every ED ED, as ED ED count byte.
  const packed = [];
  for (let i = 0; i < ram.length;) {
    let run = 1;
    while (i + run < ram.length && ram[i + run] === ram[i] && run < 255) run++;
    if (run >= 5 || (ram[i] === 0xED && run >= 2)) {
      packed.push(0xED, 0xED, run, ram[i]);
      i += run;
    } else if (ram[i] === 0xED) {
      // An ED on its own is copied with the byte after it, so it cannot pair.
      packed.push(0xED, ram[i + 1]);
      i += 2;
    } else {
      packed.push(ram[i]);
      i += 1;
    }
  }
  packed.push(0, 0xED, 0xED, 0);
  const squeezed = new Uint8Array(30 + packed.length);
  h[12] |= 0x20;
  squeezed.set(h);
  squeezed.set(packed, 30);
  assert.deepStrictEqual(kl.readSnapshot(squeezed, 'k.z80'), original);
});

console.log(failed ? failed + ' failed' : 'all passed');
process.exit(failed ? 1 : 0);
