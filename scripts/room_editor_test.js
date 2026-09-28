// Tests for room_editor.js: Knight Lore against the Python it follows, and each
// game against its own original.
//
//   node scripts/room_editor_test.js
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
const kl = require('./room_editor.js');

const ROOT = path.resolve(__dirname, '..');
const CASTLE = path.join(ROOT, 'game_disassembly', 'knightlore', 'rooms');
const REMAKE = path.resolve(ROOT, '..', 'examples', 'filmation', 'knightlore');

let failed = 0;
// Each game's tests need that game's snapshot, which is never committed; the
// ones without it say so and are skipped, and the rest still run.
let skipping = null;
function test(name, fn) {
  if (skipping) {
    console.log('skip ' + name + ' (' + skipping + ')');
    return;
  }
  try {
    fn();
    console.log('ok   ' + name);
  } catch (err) {
    failed++;
    console.log('FAIL ' + name + '\n' + (err.stack || err));
  }
}

const snaPath = path.join(CASTLE, 'original.sna');
const read = function (dir, leaf) { return JSON.parse(fs.readFileSync(path.join(dir, leaf), 'utf8')); };
let original = null;
let graphics = null;
let sheet = null;
if (!fs.existsSync(snaPath) || !fs.existsSync(REMAKE)) {
  skipping = 'no ' + snaPath + ' -- run knightlore_rooms.py extract -- or no ' + REMAKE;
} else {
  original = kl.readSnapshot(fs.readFileSync(snaPath), 'original.sna');
  graphics = read(REMAKE, 'graphics.json');
  sheet = read(REMAKE, 'sprites.json');
}

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

// --- Pentagram -----------------------------------------------------------
//
// Against the snapshot build_pentagram.py leaves, and the Filmation remake's
// carried castle, sprites.json, graphics.json and sprites.png, which were made
// from the same original.

const PG_SNA = path.join(ROOT, 'game_disassembly', 'pentagram', 'pentagram.z80');
const PG_REMAKE = path.resolve(ROOT, '..', 'examples', 'filmation', 'pentagram');
skipping = fs.existsSync(PG_SNA) && fs.existsSync(PG_REMAKE) ? null
  : 'no ' + PG_SNA + ' -- run build_pentagram.py -- or no ' + PG_REMAKE;
const pg = skipping ? null : {
  sna: kl.readSnapshot(fs.readFileSync(PG_SNA), 'pentagram.z80'),
  graphics: read(PG_REMAKE, 'graphics.json'),
  sheet: read(PG_REMAKE, 'sprites.json')
};
const PG = kl.PENTAGRAM;
function pgBuild(atlas) {
  const packed = kl.packCastle(pg.sna, atlas, null, pg.graphics, PG);
  return Object.assign(kl.applyWrites(pg.sna, packed.writes), { report: packed.report });
}

test('Pentagram: the snapshot is told apart from Knight Lore’s, and the other way round', function () {
  assert.strictEqual(kl.identify(pg.sna).id, 'pentagram');
  if (original) assert.strictEqual(kl.identify(original).id, 'knightlore');
  assert.throws(function () { kl.checkOriginal(pg.sna, kl.KNIGHT_LORE); }, /not look like the original Knight Lore/);
});

test('Pentagram: decoding gives the remake’s castle, but for the four unused scenery slots', function () {
  const castle = kl.decodeCastle(pg.sna, pg.graphics, PG);
  const rooms = read(PG_REMAKE, 'rooms.json');
  const templates = read(PG_REMAKE, 'templates.json');
  assert.deepStrictEqual(castle.rooms.rooms, rooms.rooms);
  assert.deepStrictEqual(castle.rooms.roomDimensions, rooms.roomDimensions);
  assert.deepStrictEqual(castle.rooms.startRooms, [51, 92, 100, 12]);
  assert.deepStrictEqual(Object.keys(castle.templates.sceneryTemplates), Object.keys(templates.sceneryTemplates));
  assert.deepStrictEqual(castle.templates.objectTemplates, templates.objectTemplates);
  // Slots 18, 19, 22 and 23 point at the scenery table itself: the remake
  // reads the table's own bytes as their pieces; here they are empty.
  for (const name of Object.keys(templates.sceneryTemplates)) {
    const unused = ['scenery_18', 'scenery_19', 'scenery_22', 'scenery_23'].indexOf(name) >= 0;
    assert.deepStrictEqual(castle.templates.sceneryTemplates[name], unused ? [] : templates.sceneryTemplates[name], name);
  }
  assert.strictEqual(castle.specials, null);
});

test('Pentagram: the castle as decoded packs back but for two headers the rooms cut short', function () {
  const castle = kl.decodeCastle(pg.sna, pg.graphics, PG);
  const built = pgBuild(merged(castle));
  // Rooms 13 and 108 end partway through their last group: the header asks
  // for three and the record holds two. The game builds the two; a header
  // written from the castle asks for two. Nothing else moves.
  const moved = [];
  for (let i = 27; i < built.sna.length; i++) if (built.sna[i] !== pg.sna[i]) moved.push(i - 27 + 0x4000);
  assert.deepStrictEqual(moved, [0x5F67, 0x66D3]);
  assert.strictEqual(built.sna[27 + 0x5F67 - 0x4000], pg.sna[27 + 0x5F67 - 0x4000] - 1);
  assert.strictEqual(built.report.free, 0);
  assert.deepStrictEqual(built.report.fullest, [43, 87]);
  assert.deepStrictEqual(kl.decodeCastle(built.sna, pg.graphics, PG).rooms.rooms, castle.rooms.rooms);
});

test('Pentagram: the sheet painted from the snapshot is sprites.png, sprite for sprite', function () {
  const painted = kl.sheetPixels(pg.sna, pg.sheet, pg.graphics, PG);
  const png = readPng(path.join(PG_REMAKE, 'sprites.png'));
  const drawn = new Set(Object.values(pg.graphics.graphics).map(function (e) { return e.sprite; }));
  let checked = 0;
  (function walk(node, trail) {
    for (const key of Object.keys(node.sprites || {})) {
      const s = node.sprites[key];
      if (!drawn.has(trail.concat([key]).join('.'))) continue;
      for (let y = s.y; y < s.y + s.h; y++) {
        for (let x = s.x; x < s.x + s.w; x++) {
          for (let k = 0; k < 4; k++) {
            if (png.pixels[(y * png.width + x) * 4 + k] !== painted.pixels[(y * painted.width + x) * 4 + k]) {
              assert.fail(trail.concat([key]).join('.') + ' differs at ' + x + ',' + y);
            }
          }
        }
      }
      checked++;
    }
    for (const g of Object.keys(node.group || {})) walk(node.group[g], trail.concat([g]));
  })(pg.sheet, []);
  assert.ok(checked > 80, checked + ' sprites');
});

test('Pentagram: an edited castle packs, moves its tables, and decodes back as edited', function () {
  const castle = kl.decodeCastle(pg.sna, pg.graphics, PG);
  const atlas = merged(castle);
  const by = new Map(atlas.rooms.map(function (r) { return [r.number, r]; }));
  // A fourth shape for room 100, paid for by room 87's objects; the first
  // room with its middle clear in room 12's starting slot; and an object
  // template made taller.
  by.get(87).objects = [];
  atlas.roomDimensions.small = { u: 48, v: 48, z: 128 };
  by.get(100).dimensions = 'small';
  let clear = null;
  for (const room of atlas.rooms) {
    if ([51, 92, 100, 12].indexOf(room.number) >= 0) continue;
    atlas.startRooms = [51, 92, 100, room.number];
    try { pgBuild(atlas); clear = room.number; break; } catch (err) { if (!/starting room/.test(err.message)) throw err; }
  }
  assert.ok(clear !== null, 'some room has its middle clear');
  const first = Object.keys(atlas.objectTemplates)[0];
  // A box of its own, which is all three sizes or none.
  Object.assign(atlas.objectTemplates[first][0], { sizeU: 7, sizeV: 7, sizeZ: 30 });
  const built = pgBuild(atlas);
  assert.strictEqual(kl.word(built.sna, PG.operands.rooms[0]), 0x5E10 + 3);
  for (const table of ['sceneryTable', 'objectTable']) {
    for (const addr of PG.operands[table]) assert.strictEqual(kl.word(built.sna, addr), built.report[table]);
  }
  const back = kl.decodeCastle(built.sna, pg.graphics, PG);
  const renamed = JSON.parse(JSON.stringify(atlas));
  renamed.roomDimensions = { square: atlas.roomDimensions.square, narrowU: atlas.roomDimensions.narrowU,
                             narrowV: atlas.roomDimensions.narrowV, shape_3: atlas.roomDimensions.small };
  renamed.rooms.find(function (r) { return r.number === 100; }).dimensions = 'shape_3';
  assert.deepStrictEqual(back.rooms.rooms, renamed.rooms);
  assert.deepStrictEqual(back.rooms.startRooms, [51, 92, 100, clear]);
  assert.deepStrictEqual(back.templates.objectTemplates[first], atlas.objectTemplates[first]);
  assert.deepStrictEqual(back.templates.sceneryTemplates, castle.templates.sceneryTemplates);
});

test('Pentagram: what the original cannot hold is refused, saying why', function () {
  const refused = function (edit, pattern) {
    const atlas = merged(kl.decodeCastle(pg.sna, pg.graphics, PG));
    edit(atlas, new Map(atlas.rooms.map(function (r) { return [r.number, r]; })));
    assert.throws(function () { pgBuild(atlas); },
                  function (err) { return err instanceof kl.CastleError && pattern.test(err.message); });
  };
  // A doorway to a room that is not there: the walk would run on.
  refused(function (a, by) {
    const door = by.get(0).scenery.find(function (s) { return /^door_/.test(s.template); });
    door.destination = 200;
  }, /leads to room 200, which there is not; the game would look for it through the rest of memory/);
  // Room 87 is at 43 of 48; six more blocks is 49.
  refused(function (a, by) {
    by.get(87).objects.push({ template: 'object_00',
      positions: [0, 1, 2, 3, 4, 5].map(function (i) { return { u: i, v: 0, z: 3 }; }) });
  }, /room \$57 \(87\) fills 49 object records; the game has 48 for a room, and one more runs down over the bolts/);
  // An unused slot placed in a room, and a nudge Pentagram has no byte for.
  refused(function (a, by) { by.get(0).scenery.push({ template: 'scenery_18', destination: 0 }); },
          /places scenery_18, which has no pieces/);
  refused(function (a) { a.objectTemplates.object_00[0].offsets.halfU = true; }, /placement nudge/);
});

// --- Alien 8 -------------------------------------------------------------
//
// Against the snapshot build_alien8.py leaves, and the sprite layout and
// graphic table room_editor_art.py writes. Alien 8 has no remake to compare
// the decoded castle with, so the checks are the round trip, the game's own
// counts from notes/alien8/room-building.md, and edits that decode back.

const A8_SNA = path.join(ROOT, 'game_disassembly', 'alien8', 'alien8.z80');
const A8_ART = path.join(ROOT, 'scripts', 'room_editor_art', 'alien8');
skipping = fs.existsSync(A8_SNA) ? null : 'no ' + A8_SNA + ' -- run build_alien8.py';
const a8 = skipping ? null : {
  sna: kl.readSnapshot(fs.readFileSync(A8_SNA), 'alien8.z80'),
  graphics: read(A8_ART, 'graphics.json'),
  sheet: read(A8_ART, 'sprites.json')
};
const A8 = kl.ALIEN8;
function a8Build(atlas, specials) {
  const packed = kl.packCastle(a8.sna, atlas, specials, a8.graphics, A8);
  return Object.assign(kl.applyWrites(a8.sna, packed.writes), { report: packed.report });
}

test('Alien 8: the snapshot is told apart from the other two', function () {
  assert.strictEqual(kl.identify(a8.sna).id, 'alien8');
  if (pg) assert.strictEqual(kl.identify(pg.sna).id, 'pentagram');
});

test('Alien 8: the castle decodes to what its notes count', function () {
  const castle = kl.decodeCastle(a8.sna, a8.graphics, A8);
  assert.strictEqual(castle.rooms.rooms.length, 128);
  assert.deepStrictEqual(castle.rooms.startRooms, [0x13, 0x4E, 0x88, 0xD7]);
  // Three sizes, floors at 64.
  assert.deepStrictEqual(Object.values(castle.rooms.roomDimensions),
                         [{ u: 64, v: 64, z: 64 }, { u: 32, v: 64, z: 64 }, { u: 64, v: 32, z: 64 }]);
  // Fourteen backgrounds, six of them doorways; thirty object templates on
  // the first page and seven on the second, their slots 1-30 and 33-39.
  assert.strictEqual(Object.keys(castle.templates.sceneryTemplates).length, 14);
  assert.deepStrictEqual(castle.templates.meta.doorways,
    { door_n: 'n', door_e: 'e', door_s: 's', door_w: 'w', door_high_e: 'e', door_high_s: 's' });
  const objects = Object.keys(castle.templates.objectTemplates);
  assert.strictEqual(objects.length, 37);
  assert.strictEqual(objects[0], 'object_01');
  assert.strictEqual(objects[29], 'object_30');
  assert.strictEqual(objects[30], 'object_33');
  // Forty-one nudge headers set $30 and one sets 0: the groups after them.
  const nudged = [];
  for (const room of castle.rooms.rooms) for (const g of room.objects) if (g.nudge) nudged.push(g.nudge);
  assert.ok(nudged.length >= 41 && nudged.every(function (n) { return n === 0x30; }), nudged.length + ' nudged');
  // The inks are bits 3-5: 3 to 6, 32, 28, 34 and 34 rooms.
  const inks = {};
  for (const room of castle.rooms.rooms) inks[room.ink] = (inks[room.ink] || 0) + 1;
  assert.deepStrictEqual(inks, { 3: 32, 4: 28, 5: 34, 6: 34 });
  assert.strictEqual(castle.specials.collectables.length, 36);
  assert.strictEqual(castle.specials.wanted, undefined);
  assert.deepStrictEqual(castle.rooms.meta.rules, { poolLimit: 52, shapeLimit: 4, objectTemplateLimit: 60,
    yOrigin: 232, startSpot: { u: 128, v: 128, z: 64, sizeU: 7, sizeV: 7, sizeZ: 23 }, groupNudge: true });
});

test('Alien 8: the castle as decoded packs back into the original byte for byte', function () {
  const castle = kl.decodeCastle(a8.sna, a8.graphics, A8);
  const built = a8Build(merged(castle), castle.specials);
  assert.strictEqual(built.changed, 0);
  assert.strictEqual(built.report.free, 0);
  assert.deepStrictEqual(built.report.fullest, [49, 0x74]);
});

test('Alien 8: the sheet paints every sprite the graphic table reaches', function () {
  const painted = kl.sheetPixels(a8.sna, a8.sheet, a8.graphics, A8);
  let empty = [];
  (function walk(node, trail) {
    for (const key of Object.keys(node.sprites || {})) {
      const s = node.sprites[key];
      let ink = 0;
      for (let y = s.y; y < s.y + s.h; y++) {
        for (let x = s.x; x < s.x + s.w; x++) ink += painted.pixels[(y * painted.width + x) * 4 + 3] ? 1 : 0;
      }
      if (!ink) empty.push(trail.concat([key]).join('.'));
    }
    for (const g of Object.keys(node.group || {})) walk(node.group[g], trail.concat([g]));
  })(a8.sheet, []);
  assert.deepStrictEqual(empty, []);
});

test('Alien 8: an edited castle packs, with its pages and nudges, and decodes back as edited', function () {
  const castle = kl.decodeCastle(a8.sna, a8.graphics, A8);
  const atlas = merged(castle);
  const by = new Map(atlas.rooms.map(function (r) { return [r.number, r]; }));
  // Room $74, the fullest, gives up its objects; room $4E gets a second-page
  // template with a raise, then a first-page one without -- which the build
  // writes back in page order -- a fourth shape, and red; one valve moves.
  by.get(0x74).objects = [];
  by.get(0x4E).objects.push({ template: 'object_35', nudge: 0x30, positions: [{ u: 6, v: 6, z: 0 }] });
  by.get(0x4E).objects.push({ template: 'object_02', positions: [{ u: 1, v: 6, z: 0 }] });
  atlas.roomDimensions.small = { u: 48, v: 48, z: 64 };
  by.get(0x4E).dimensions = 'small';
  by.get(0x4E).ink = 2;
  const specials = JSON.parse(JSON.stringify(castle.specials));
  specials.collectables[0] = { room: 0x4E, u: 100, v: 110, z: 64 };
  const built = a8Build(atlas, specials);
  for (const table of ['rooms', 'objectTable', 'sceneryTable']) {
    const want = table === 'rooms' ? built.report.roomsAt : built.report[table];
    for (const addr of A8.operands[table]) assert.strictEqual(kl.word(built.sna, addr), want, table);
  }
  assert.strictEqual(built.report.roomsAt, 0x6469 + 3);
  const back = kl.decodeCastle(built.sna, a8.graphics, A8);
  const room = back.rooms.rooms.find(function (r) { return r.number === 0x4E; });
  assert.strictEqual(room.dimensions, 'shape_3');
  assert.strictEqual(room.ink, 2);
  const tail = room.objects.slice(-2);
  assert.deepStrictEqual(tail, [
    { template: 'object_02', positions: [{ u: 1, v: 6, z: 0 }] },
    { template: 'object_35', nudge: 0x30, positions: [{ u: 6, v: 6, z: 0 }] }]);
  assert.deepStrictEqual(back.specials.collectables[0], { room: 0x4E, u: 100, v: 110, z: 64 });
  assert.deepStrictEqual(back.templates.objectTemplates, castle.templates.objectTemplates);
});

test('Alien 8: what the original cannot hold is refused, saying why', function () {
  const refused = function (edit, pattern) {
    const castle = kl.decodeCastle(a8.sna, a8.graphics, A8);
    const atlas = merged(castle);
    edit(atlas, new Map(atlas.rooms.map(function (r) { return [r.number, r]; })));
    assert.throws(function () { a8Build(atlas, castle.specials); },
                  function (err) { return err instanceof kl.CastleError && pattern.test(err.message); });
  };
  refused(function (a) {
    a.roomDimensions.a = { u: 8, v: 8, z: 64 };
    a.roomDimensions.b = { u: 8, v: 8, z: 64 };
  }, /5 floor shapes; a room names one in two bits, so 1 to 4/);
  refused(function (a, by) {
    by.get(0x74).objects.push({ template: 'object_01', positions: [0, 1, 2, 3].map(function (i) { return { u: i, v: 7, z: 3 }; }) });
  }, /room \$74 \(116\) fills 53 object records; the game has 52 for a room/);
  // And a group nudge where a game has no header for one.
  if (original) {
    const castle = kl.decodeCastle(original, graphics);
    const atlas = merged(castle);
    atlas.rooms[0].objects[0].nudge = 0x30;
    assert.throws(function () { build(atlas, castle.specials); }, /has a nudge of its own/);
  }
});

console.log(failed ? failed + ' failed' : 'all passed');
process.exit(failed ? 1 : 0);
